# Share your game with a pull request

A pull request (PR) asks to add your changes to the class project. GitHub will test your game and give you a link to play it. You can do all the student steps in a browser.

## Students: submit your game

1. Sign in to your GitHub account at https://github.com/login.
2. Open https://github.com/nittanychristian/elm-snake-curriculum and click **Fork**, then **Create fork**. This makes your own copy.
3. In your copy, open **src**, then **Game.elm**, and click the pencil to edit it.
4. Make a small change for your first try, such as changing a color. Later, paste in your customized game. Keep the module named `Game` and keep its existing exposed functions so the game tests can run. Ellie usually uses `Main`: change that module line back to `Game` when copying from Ellie.
5. Click **Commit changes**. Give the change a short description, such as “Change my eagle's colors,” and commit it to your fork's `master` branch.
6. Open **Contribute → Open pull request**. Check that the base repository is `nittanychristian/elm-snake-curriculum`, the base branch is `master`, and the head repository is your fork. Click **Create pull request**.
7. Wait for the checks. Your teacher may need to approve the first workflow run from your account.
8. When the build and publishing finish, a GitHub Actions comment will say **Your game is ready**. Click **Play your game**!

Your link looks like `https://nittanychristian.github.io/elm-snake-curriculum/previews/pr-12/`, with your own PR number. You do not need to merge the PR to play.

## Students: update your game

Edit `src/Game.elm` in the same branch of your fork and commit again. The existing PR updates automatically. When the new checks and deployment finish, the same play link shows your new game. Refresh the page if you still see the previous version.

If a check fails, open the PR's **Checks** tab and select **PR game build**. Read the first compiler or test error, fix it in your fork, and commit again. A failed build leaves your last successful preview available. If you deliberately change a game rule, update the matching tests in `tests/GameTest.elm` too, with your teacher's help.

Closing or merging the PR removes its preview. The PR comment will say that the preview was removed.

## Teacher: first-time setup

The two workflows and their helper scripts must be committed to the class repository's default branch, `master`, before students open PRs. Forks should start from this updated version.

1. Open https://github.com/nittanychristian/elm-snake-curriculum/settings/actions and enable GitHub Actions. Allow the pinned actions used by this repository. The default workflow token can stay read-only; the trusted publisher requests its own permissions.
2. Open https://github.com/nittanychristian/elm-snake-curriculum/settings/pages. Under **Build and deployment**, set **Source** to **GitHub Actions**.
3. Check https://github.com/nittanychristian/elm-snake-curriculum/settings/environments. If `github-pages` has deployment branch restrictions, allow `master`. All deployments run trusted code from that branch, including deployments of fork previews.
4. Open https://github.com/nittanychristian/elm-snake-curriculum/actions/workflows/preview-pages.yml and use **Run workflow** on `master`. This creates the preview collection and deploys its landing page.
5. Visit https://nittanychristian.github.io/elm-snake-curriculum/ to check that the landing page is available.
6. Have a student fork the updated repository and open a PR with a small `src/Game.elm` change. If GitHub asks, review the changes and approve the run in the PR's **Checks** or repository **Actions** tab.
7. Confirm **PR game build** succeeds, then **Publish game previews** succeeds and adds the play link to the PR. Open the game. Add another commit to check updating, and close the PR to check cleanup.

You do not need a personal access token, hosting account, student webserver, or permission for workflows to approve PR reviews. Keep GitHub's first-time contributor approval policy enabled.

## Teacher: how it works

`pr-game.yml` checks out the student's exact commit with a read-only token, runs the Elm and publisher tests, builds with Nix, and uploads a self-contained HTML game plus a tiny PR/commit record. SVGs embedded as data URLs work without extra asset paths.

`preview-pages.yml` runs separately with publishing permissions. It loads its scripts from `master`, validates the successful run and the PR's current commit, and treats the downloaded game as static data. It never executes student code. It stores the collection on the dedicated `game-previews` branch and deploys the entire collection with the official Pages actions. Please leave that branch to the workflow.

Each PR gets its own directory. Publications queue one at a time, preserving the other games. Build artifacts expire after seven days; already published games remain until their PR closes. Closing a PR removes that game's page from the live site; the storage branch still has Git history.

The landing page labels each game with its PR number, title, and author, for example **PR #12: My eagle game — @student**. Give PRs descriptive titles so classmates can find each other's games. Labels refresh from GitHub whenever the site is published. After updating the publisher or renaming a PR, use **Run workflow** on **Publish game previews** to refresh existing labels without rebuilding the games.

If publishing fails after a successful build, inspect **Publish game previews** in Actions and rerun its failed jobs once the problem is fixed. **Run workflow** redeploys the stored collection; it does not import an unpublished build. For an unpublished game with an expired artifact, push a new commit to its PR.

## Teacher: check changes locally

From the repository, with Nix installed:

```sh
nix develop -c just test
nix develop -c just test-previews
nix build
```

The publisher tests use Node's built-in test runner and mocked GitHub calls. They check artifact validation, outdated builds, preserving other students' previews, cleanup, and comment links without posting to GitHub.

GitHub's concurrency queue is documented at https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency. Older workflow linters may reject `queue: max` even though GitHub supports it.
