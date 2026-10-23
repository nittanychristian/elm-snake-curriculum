# Student PR game previews

Students submit changes to src/Game.elm in a fork pull request and receive a playable game URL before merging.

## Requirements

- Run the existing Elm tests and Nix build on opened, reopened, and updated PRs, using a read-only token and no publishing credentials.
- Publish successful builds at previews/pr-N/ on the repository's GitHub Pages site. Updating one PR preserves every other preview.
- Publish only artifacts from the expected build workflow and an open PR whose current head matches the successful run. Ignore obsolete, failed, cancelled, unrelated, or closed-PR builds.
- The trusted publisher must not check out or execute PR code. Treat the downloaded game as static data and restrict its files and destination.
- Serialize site mutations and deployment so concurrent student submissions preserve each other.
- Post/update one bot comment on the PR with its game URL after deployment. Expose the URL in the publishing run summary.
- Remove closed PR previews and update their comments without executing their code.
- Document Pages/Actions setup, first-time contributor approval, and a simple fork/edit/PR/play walkthrough.
- Include committed tests of publisher selection, stale-run checks, artifact validation, URL handling, and preserving/cleaning multiple previews.
- Label each game on the landing page with its PR number, descriptive PR title, and author login. Fetch current metadata from GitHub on each publication or manual refresh, including for existing previews. Escape titles and author names as HTML text.
- Include a prominent playable master game at master/ built from the default branch's src/Game.elm. Rebuild it on master pushes and manual publication, test before deployment, and preserve it during PR updates/cleanup. PR artifacts must never replace the master game. Keep the last successful game if a new build fails.

## Acceptance scenarios

- A first student fork PR compiles/tests, publishes its game, and receives a play link after any required teacher approval.
- A new commit updates that student's URL. An older build finishing later cannot overwrite it.
- Two open PRs retain separate playable games after either updates.
- Failed builds do not publish; closing a PR removes its preview.
- A fork receives no publishing permissions or repository secrets. Publisher paths and PR identity come from validated GitHub metadata.

## Requirements checklist

- [x] Fork permissions and trusted publishing are separated.
- [x] Staleness, concurrent updates, and cleanup are specified.
- [x] Student and teacher workflows are explicit.
