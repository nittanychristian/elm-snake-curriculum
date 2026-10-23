const fs = require('node:fs/promises');
const path = require('node:path');

const branch = 'game-previews';
const marker = '<!-- eagle-game-preview -->';
const previewPath = /^previews\/pr-([1-9]\d*)\/index\.html$/;
const maxHtmlBytes = 5 * 1024 * 1024;

function prNumber(value) {
  if (!Number.isSafeInteger(value) || value < 1) throw new Error('Invalid PR number');
  return value;
}

function eligibleRun(run, repositoryId) {
  return run.repository?.id === repositoryId && run.event === 'pull_request' &&
    run.status === 'completed' && run.conclusion === 'success' &&
    run.path?.split('@')[0] === '.github/workflows/pr-game.yml' && /^[a-f0-9]{40}$/.test(run.head_sha);
}

function currentPull(pr, sha, context, state = 'open') {
  return pr.state === state && pr.base.repo.id === context.payload.repository.id &&
    pr.base.ref === context.payload.repository.default_branch && (!sha || pr.head.sha === sha);
}

async function pull(github, context, number) {
  return (await github.rest.pulls.get({ ...context.repo, pull_number: prNumber(number) })).data;
}

async function select({ github, context }) {
  if (context.eventName === 'workflow_dispatch') return { mode: 'refresh' };
  if (context.eventName === 'pull_request_target' && context.payload.action === 'closed') {
    const number = prNumber(context.payload.pull_request.number);
    const pr = await pull(github, context, number);
    return currentPull(pr, null, context, 'closed') ? { mode: 'cleanup', pr: number } : { mode: 'skip' };
  }
  if (context.eventName !== 'workflow_run') return { mode: 'skip' };
  const runId = context.payload.workflow_run.id;
  const run = (await github.rest.actions.getWorkflowRun({ ...context.repo, run_id: runId })).data;
  if (!eligibleRun(run, context.payload.repository.id)) return { mode: 'skip' };
  const artifacts = await github.paginate(github.rest.actions.listWorkflowRunArtifacts, {
    ...context.repo, run_id: runId, per_page: 100
  });
  const matches = artifacts.filter(artifact => artifact.name === 'game-preview');
  if (matches.length !== 1 || matches[0].expired || matches[0].size_in_bytes > 10 * 1024 * 1024) {
    throw new Error('Expected one unexpired game-preview artifact, at most 10 MiB');
  }
  return { mode: 'build', runId, artifactId: matches[0].id, sha: run.head_sha };
}

async function readGame(directory, expectedSha) {
  const entries = await fs.readdir(directory, { withFileTypes: true });
  if (entries.length !== 2 || entries.some(entry => !entry.isFile()) ||
      entries.map(entry => entry.name).sort().join(',') !== 'index.html,preview.json') {
    throw new Error('The artifact must contain only regular index.html and preview.json files');
  }
  const htmlFile = path.join(directory, 'index.html');
  const metadataFile = path.join(directory, 'preview.json');
  if ((await fs.stat(htmlFile)).size > maxHtmlBytes || (await fs.stat(metadataFile)).size > 1024) {
    throw new Error('Game or metadata exceeds its size limit');
  }
  const metadata = JSON.parse(await fs.readFile(metadataFile, 'utf8'));
  prNumber(metadata.pr);
  if (metadata.sha !== expectedSha) throw new Error('Artifact source commit does not match the build');
  const html = new TextDecoder('utf-8', { fatal: true }).decode(await fs.readFile(htmlFile));
  if (!/<html\b/i.test(html)) throw new Error('The artifact is not a complete game HTML page');
  return { pr: metadata.pr, html };
}

function previewNumbers(entries) {
  return entries.filter(entry => previewPath.test(entry.path))
    .map(entry => Number(entry.path.match(previewPath)[1])).sort((a, b) => a - b);
}

function escapeHtml(value) {
  return value.replace(/[&<>"']/g, character => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
  })[character]);
}

function siteTree(existing, change, pullRequests = new Map()) {
  const files = new Map();
  for (const entry of existing) {
    if (entry.type === 'tree') continue;
    if (entry.type !== 'blob' || entry.mode !== '100644' ||
        !['index.html', '.nojekyll'].includes(entry.path) && !previewPath.test(entry.path)) {
      throw new Error('Unexpected file in the dedicated preview storage branch');
    }
    files.set(entry.path, { path: entry.path, mode: '100644', type: 'blob', sha: entry.sha });
  }
  if (['build', 'cleanup'].includes(change.mode)) {
    const destination = `previews/pr-${prNumber(change.pr)}/index.html`;
    if (change.mode === 'build') {
      files.set(destination, { path: destination, mode: '100644', type: 'blob', content: change.html });
    } else {
      files.delete(destination);
    }
  }
  const numbers = previewNumbers([...files.values()]);
  const links = numbers.map(number => {
    const pr = pullRequests.get(number);
    const label = pr ? `PR #${number}: ${pr.title} — @${pr.user?.login ?? 'unknown'}` : `Play PR #${number}`;
    return `<li><a href="previews/pr-${number}/">${escapeHtml(label)}</a></li>`;
  }).join('\n');
  const html = `<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Student game previews</title><style>body{font:18px sans-serif;max-width:45rem;margin:3rem auto;padding:1rem;background:#0a1628;color:#fff0ce}a{color:#a8d9ff}li{margin:1rem 0}</style><h1>Student game previews</h1><p>Open a pull request with changes to src/Game.elm to add your game.</p>${numbers.length ? `<ul>${links}</ul>` : '<p>No previews yet. Your game will appear after its PR build succeeds.</p>'}</html>`;
  files.set('index.html', { path: 'index.html', mode: '100644', type: 'blob', content: html });
  files.set('.nojekyll', { path: '.nojekyll', mode: '100644', type: 'blob', content: '' });
  return [...files.values()];
}

async function prepare({ github, context, selection, directory }) {
  if (selection.mode === 'skip') return { publish: false };
  let change = { ...selection };
  if (selection.mode === 'build') {
    change = { ...selection, ...await readGame(directory, selection.sha) };
    const pr = await pull(github, context, change.pr);
    if (!currentPull(pr, selection.sha, context)) return { publish: false };
  } else if (selection.mode === 'cleanup') {
    const pr = await pull(github, context, selection.pr);
    if (!currentPull(pr, null, context, 'closed')) return { publish: false };
  } else if (selection.mode !== 'refresh') {
    throw new Error('Unexpected preview operation');
  }

  let previous;
  let existing = [];
  try {
    previous = (await github.rest.git.getRef({ ...context.repo, ref: `heads/${branch}` })).data.object.sha;
  } catch (error) {
    if (error.status !== 404) throw error;
  }
  if (previous) {
    const commit = (await github.rest.git.getCommit({ ...context.repo, commit_sha: previous })).data;
    const tree = (await github.rest.git.getTree({ ...context.repo, tree_sha: commit.tree.sha, recursive: 'true' })).data;
    if (tree.truncated) throw new Error('Preview tree is truncated; refusing to lose existing previews');
    existing = tree.tree;
  }
  const numbers = new Set(previewNumbers(existing));
  if (change.mode === 'build') numbers.add(change.pr);
  if (change.mode === 'cleanup') numbers.delete(change.pr);
  const pullRequests = new Map(await Promise.all([...numbers].map(async number =>
    [number, await pull(github, context, number)])));
  // Recheck after reading storage and labels, immediately before preparing a new publication.
  if (change.mode === 'build' && !currentPull(await pull(github, context, change.pr), change.sha, context)) {
    return { publish: false };
  }
  const tree = (await github.rest.git.createTree({ ...context.repo, tree: siteTree(existing, change, pullRequests) })).data;
  const commit = (await github.rest.git.createCommit({
    ...context.repo, message: `Update student previews (${change.mode}${change.pr ? ` PR #${change.pr}` : ''})`,
    tree: tree.sha, parents: previous ? [previous] : []
  })).data;
  if (previous) {
    await github.rest.git.updateRef({ ...context.repo, ref: `heads/${branch}`, sha: commit.sha, force: false });
  } else {
    await github.rest.git.createRef({ ...context.repo, ref: `refs/heads/${branch}`, sha: commit.sha });
  }
  return { publish: true, commit: commit.sha, mode: change.mode, pr: change.pr, sha: change.sha };
}

function gameUrl(baseUrl, number) {
  const base = new URL(baseUrl.endsWith('/') ? baseUrl : `${baseUrl}/`);
  if (base.protocol !== 'https:' || base.username || base.password || base.search || base.hash) {
    throw new Error('Invalid Pages URL');
  }
  return new URL(`previews/pr-${prNumber(number)}/`, base).href;
}

async function notify({ github, context, core, preview, baseUrl }) {
  if (!preview.pr) {
    await core.summary.addRaw(`Student preview site: ${baseUrl}\n`).write();
    return;
  }
  const pr = await pull(github, context, preview.pr);
  if (!currentPull(pr, preview.mode === 'build' ? preview.sha : null, context,
    preview.mode === 'build' ? 'open' : 'closed')) return;
  const url = gameUrl(baseUrl, preview.pr);
  const body = preview.mode === 'build'
    ? `${marker}\n### Your game is ready\n\n[Play your game](${url})\n\nBuilt from \`${preview.sha.slice(0, 7)}\`. Push another change to update this same link.`
    : `${marker}\nThis PR is closed, so its game preview has been removed.`;
  const comments = await github.paginate(github.rest.issues.listComments, {
    ...context.repo, issue_number: preview.pr, per_page: 100
  });
  const comment = comments.find(item => item.user?.login === 'github-actions[bot]' && item.body?.includes(marker));
  if (comment) {
    await github.rest.issues.updateComment({ ...context.repo, comment_id: comment.id, body });
  } else if (preview.mode === 'build') {
    await github.rest.issues.createComment({ ...context.repo, issue_number: preview.pr, body });
  }
  await core.summary.addRaw(preview.mode === 'build' ? `[Play PR #${preview.pr}](${url})\n` : `Removed PR #${preview.pr}'s preview.\n`).write();
}

module.exports = { branch, marker, prNumber, eligibleRun, currentPull, select, readGame, siteTree, prepare, gameUrl, notify };
