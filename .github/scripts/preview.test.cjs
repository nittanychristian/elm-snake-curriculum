const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const previews = require('./preview.cjs');

const sha = 'a'.repeat(40);
const repository = { id: 1, default_branch: 'master' };
const context = { eventName: 'workflow_run', repo: { owner: 'school', repo: 'games' },
  payload: { repository, workflow_run: { id: 17 } } };
const validRun = { repository, event: 'pull_request', status: 'completed', conclusion: 'success',
  path: '.github/workflows/pr-game.yml', head_sha: sha };
const validPull = { number: 7, state: 'open', base: { repo: repository, ref: 'master' }, head: { sha } };
const artifact = { id: 23, name: 'game-preview', expired: false, size_in_bytes: 100 };
const storedGame = number => ({ path: `previews/pr-${number}/index.html`, type: 'blob', mode: '100644', sha: 'b'.repeat(40) });

function mock({ run = validRun, pr = validPull, artifacts = [artifact], existing = [], comments = [], newBranch = false, truncated = false } = {}) {
  const calls = [];
  const record = (method, result) => async args => { calls.push({ method, args }); return { data: result }; };
  const github = { rest: {
    actions: { getWorkflowRun: record('getWorkflowRun', run), listWorkflowRunArtifacts: () => {} },
    pulls: { get: record('getPull', pr) },
    git: {
      getRef: newBranch ? async () => { throw Object.assign(new Error('not found'), { status: 404 }); } : record('getRef', { object: { sha: 'old-commit' } }),
      getCommit: record('getCommit', { tree: { sha: 'old-tree' } }),
      getTree: record('getTree', { tree: existing, truncated }),
      createTree: record('createTree', { sha: 'new-tree' }),
      createCommit: record('createCommit', { sha: 'new-commit' }),
      createRef: record('createRef', {}), updateRef: record('updateRef', {})
    },
    issues: { listComments: () => {}, createComment: record('createComment', {}), updateComment: record('updateComment', {}) }
  } };
  github.paginate = async method => method === github.rest.actions.listWorkflowRunArtifacts ? artifacts : comments;
  const core = { summary: { addRaw: text => { calls.push({ method: 'summary', text }); return { write: async () => {} }; } } };
  return { github, core, calls };
}

async function gameDirectory(t, metadata = { pr: 7, sha }) {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), 'eagle-preview-'));
  t.after(() => fs.rm(directory, { recursive: true, force: true }));
  await fs.writeFile(path.join(directory, 'index.html'), '<!doctype html><html>student game</html>');
  await fs.writeFile(path.join(directory, 'preview.json'), JSON.stringify(metadata));
  return directory;
}

test('only positive integer PR numbers can become preview paths', () => {
  assert.equal(previews.prNumber(7), 7);
  for (const value of [0, -1, 1.5, '7', '../../other', NaN, Number.MAX_SAFE_INTEGER + 1]) {
    assert.throws(() => previews.prNumber(value));
  }
});

test('only a successful PR run from the expected repository and workflow qualifies', () => {
  assert.equal(previews.eligibleRun(validRun, 1), true);
  for (const change of [{ repository: { id: 2 } }, { event: 'push' }, { status: 'in_progress' },
    { conclusion: 'failure' }, { conclusion: 'cancelled' }, { path: '.github/workflows/other.yml' }, { head_sha: '../../' }]) {
    assert.equal(previews.eligibleRun({ ...validRun, ...change }, 1), false);
  }
});

test('closed, stale, foreign-base, and wrong-branch PRs cannot be published', () => {
  assert.equal(previews.currentPull(validPull, sha, context), true);
  assert.equal(previews.currentPull({ ...validPull, state: 'closed' }, sha, context), false);
  assert.equal(previews.currentPull(validPull, 'c'.repeat(40), context), false);
  assert.equal(previews.currentPull({ ...validPull, base: { repo: { id: 2 }, ref: 'master' } }, sha, context), false);
  assert.equal(previews.currentPull({ ...validPull, base: { repo: repository, ref: 'other' } }, sha, context), false);
});

test('selection resolves an artifact through the trusted workflow run API', async () => {
  const { github, calls } = mock();
  assert.deepEqual(await previews.select({ github, context }), { mode: 'build', runId: 17, artifactId: 23, sha });
  assert.equal(calls[0].args.run_id, 17);
});

test('failed builds are ignored and ambiguous or expired artifacts are rejected', async () => {
  assert.deepEqual(await previews.select({ github: mock({ run: { ...validRun, conclusion: 'failure' } }).github, context }), { mode: 'skip' });
  for (const artifacts of [[], [artifact, artifact], [{ ...artifact, expired: true }], [{ ...artifact, size_in_bytes: 11 * 1024 * 1024 }]]) {
    await assert.rejects(previews.select({ github: mock({ artifacts }).github, context }), /artifact/);
  }
});

test('closure handling rechecks the PR and ignores a PR that was reopened while queued', async () => {
  const closedContext = { ...context, eventName: 'pull_request_target', payload: { repository, action: 'closed', pull_request: { number: 7 } } };
  assert.deepEqual(await previews.select({ github: mock().github, context: closedContext }), { mode: 'skip' });
  assert.deepEqual(await previews.select({ github: mock({ pr: { ...validPull, state: 'closed' } }).github, context: closedContext }), { mode: 'cleanup', pr: 7 });
});

test('only an exact two-file game artifact with matching commit is accepted', async t => {
  const directory = await gameDirectory(t);
  assert.equal((await previews.readGame(directory, sha)).pr, 7);
  await assert.rejects(previews.readGame(directory, 'c'.repeat(40)), /source commit/);
  await fs.writeFile(path.join(directory, 'extra.js'), 'unexpected');
  await assert.rejects(previews.readGame(directory, sha), /only regular/);
});

test('symlinks, directories, traversal metadata, and oversized HTML are rejected', async t => {
  const symlinks = await gameDirectory(t);
  await fs.rename(path.join(symlinks, 'index.html'), path.join(symlinks, 'other.html'));
  await fs.symlink('other.html', path.join(symlinks, 'index.html'));
  await assert.rejects(previews.readGame(symlinks, sha), /only regular/);
  const directories = await gameDirectory(t);
  await fs.rm(path.join(directories, 'index.html'));
  await fs.mkdir(path.join(directories, 'index.html'));
  await assert.rejects(previews.readGame(directories, sha), /only regular/);
  await assert.rejects(previews.readGame(await gameDirectory(t, { pr: '../../main', sha }), sha), /PR number/);
  const oversized = await gameDirectory(t);
  await fs.truncate(path.join(oversized, 'index.html'), 6 * 1024 * 1024);
  await assert.rejects(previews.readGame(oversized, sha), /size limit/);
});

test('an update preserves another student preview and builds a working index', () => {
  const tree = previews.siteTree([storedGame(1), storedGame(7)], { mode: 'build', pr: 7, html: '<html>new game</html>' });
  assert.equal(tree.find(file => file.path === 'previews/pr-1/index.html').sha, 'b'.repeat(40));
  assert.equal(tree.find(file => file.path === 'previews/pr-7/index.html').content, '<html>new game</html>');
  assert.match(tree.find(file => file.path === 'index.html').content, /previews\/pr-1\//);
  assert.match(tree.find(file => file.path === 'index.html').content, /previews\/pr-7\//);
});

test('cleanup removes only the selected PR and removes its landing-page link', () => {
  const tree = previews.siteTree([storedGame(1), storedGame(7)], { mode: 'cleanup', pr: 7 });
  assert.ok(tree.find(file => file.path === 'previews/pr-1/index.html'));
  assert.ok(!tree.find(file => file.path === 'previews/pr-7/index.html'));
  assert.doesNotMatch(tree.find(file => file.path === 'index.html').content, /pr-7/);
});

test('unexpected storage files and executable/symlink modes cannot enter the deployed site', () => {
  assert.throws(() => previews.siteTree([{ ...storedGame(1), path: '../escape' }], { mode: 'refresh' }));
  assert.throws(() => previews.siteTree([{ ...storedGame(1), mode: '120000' }], { mode: 'refresh' }));
  assert.throws(() => previews.siteTree([{ ...storedGame(1), mode: '100755' }], { mode: 'refresh' }));
});

test('a stale artifact cannot mutate storage', async t => {
  const { github, calls } = mock({ pr: { ...validPull, head: { sha: 'c'.repeat(40) } } });
  const result = await previews.prepare({ github, context, selection: { mode: 'build', sha }, directory: await gameDirectory(t) });
  assert.deepEqual(result, { publish: false });
  assert.ok(!calls.some(call => call.method === 'createTree'));
});

test('the PR head is rechecked immediately before updating the preview collection', async t => {
  const { github, calls } = mock();
  let reads = 0;
  github.rest.pulls.get = async () => ({ data: ++reads === 1 ? validPull : { ...validPull, head: { sha: 'c'.repeat(40) } } });
  assert.deepEqual(await previews.prepare({ github, context, selection: { mode: 'build', sha }, directory: await gameDirectory(t) }), { publish: false });
  assert.ok(!calls.some(call => call.method === 'createTree'));
});

test('publishing preserves previous previews and updates storage without force', async t => {
  const { github, calls } = mock({ existing: [storedGame(1)] });
  const result = await previews.prepare({ github, context, selection: { mode: 'build', sha }, directory: await gameDirectory(t) });
  assert.equal(result.commit, 'new-commit');
  assert.equal(result.publish, true);
  assert.ok(calls.find(call => call.method === 'createTree').args.tree.some(file => file.path === 'previews/pr-1/index.html'));
  assert.equal(calls.find(call => call.method === 'updateRef').args.force, false);
  assert.deepEqual(calls.find(call => call.method === 'createCommit').args.parents, ['old-commit']);
});

test('bootstrap creates only a dedicated storage branch and a landing page', async () => {
  const { github, calls } = mock({ newBranch: true });
  const result = await previews.prepare({ github, context, selection: { mode: 'refresh' } });
  assert.equal(result.publish, true);
  assert.equal(calls.find(call => call.method === 'createRef').args.ref, 'refs/heads/game-previews');
  assert.deepEqual(calls.find(call => call.method === 'createCommit').args.parents, []);
});

test('a truncated storage tree cannot wipe other student previews', async () => {
  const { github, calls } = mock({ truncated: true });
  await assert.rejects(previews.prepare({ github, context, selection: { mode: 'refresh' } }), /truncated/);
  assert.ok(!calls.some(call => call.method === 'createTree'));
});

test('URLs preserve project subpaths and custom domains, and reject unsafe bases', () => {
  assert.equal(previews.gameUrl('https://school.github.io/games', 7), 'https://school.github.io/games/previews/pr-7/');
  assert.equal(previews.gameUrl('https://games.example.com/', 7), 'https://games.example.com/previews/pr-7/');
  for (const base of ['http://example.com', 'https://user:password@example.com', 'https://example.com/?x=1', 'https://example.com/#fragment']) {
    assert.throws(() => previews.gameUrl(base, 7));
  }
});

test('the play link is posted only after deployment and updated rather than duplicated', async () => {
  const preview = { mode: 'build', pr: 7, sha };
  const first = mock();
  await previews.notify({ ...first, context, preview, baseUrl: 'https://school.github.io/games' });
  assert.match(first.calls.find(call => call.method === 'createComment').args.body, /Play your game/);
  const next = mock({ comments: [{ id: 99, user: { login: 'github-actions[bot]' }, body: previews.marker }] });
  await previews.notify({ ...next, context, preview, baseUrl: 'https://school.github.io/games' });
  assert.equal(next.calls.find(call => call.method === 'updateComment').args.comment_id, 99);
  assert.ok(!next.calls.some(call => call.method === 'createComment'));
});

test('stale deployment notifications and cleanup without an existing comment do not post links', async () => {
  const stale = mock({ pr: { ...validPull, head: { sha: 'c'.repeat(40) } } });
  await previews.notify({ ...stale, context, preview: { mode: 'build', pr: 7, sha }, baseUrl: 'https://school.github.io/games' });
  assert.ok(!stale.calls.some(call => call.method === 'createComment'));
  const closed = mock({ pr: { ...validPull, state: 'closed' } });
  await previews.notify({ ...closed, context, preview: { mode: 'cleanup', pr: 7 }, baseUrl: 'https://school.github.io/games' });
  assert.ok(!closed.calls.some(call => call.method === 'createComment'));
});
