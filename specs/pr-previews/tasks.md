# Tasks

- [x] P001 Implement the read-only PR test/build artifact workflow.
- [x] P002 Implement and test trusted preview validation, persistent storage, Pages deployment, and PR comments.
- [x] P003 Add closed-PR cleanup and verify serialization/stale-run behavior.
- [x] P004 Add teacher setup and student PR tutorial, with README links.
- [x] P005 Run workflow lint, helper tests, Elm tests, and Nix build.
- [ ] P006 Configure available repository settings and prepare the first fork-PR test; distinguish local validation from actual deployment evidence.
- [x] P007 Show current PR title and author in landing-page game labels, document refreshing existing labels, and verify metadata handling and HTML escaping with publisher tests. All 22 publisher tests pass; diff whitespace check passes.
- [x] P008 Build and publish a playable master game on default-branch pushes/manual runs, link it from the landing page, preserve it during PR updates/cleanup, and update tests and documentation. All 28 publisher tests and 44 Elm tests pass; Nix build and workflow lint pass (with the existing queue-key compatibility filter). Deployment awaits pushing these changes.

## Validation

- `nix develop -c just test`: 44 Elm tests pass.
- `nix develop -c just test-previews`: 19 publisher tests pass.
- `nix build path:. --no-link`: game builds successfully.
- actionlint 1.7.12: passes with only its unsupported `concurrency.queue` key diagnostic filtered. `queue: max` was verified against the current official GitHub workflow syntax documentation.
- Repository is public, Actions is enabled, and the current account has admin access. Pages initially disabled. The installed GitHub command wrapper refuses the settings write; teacher was given the Pages settings URL to select GitHub Actions manually.
- An actual student fork PR remains the acceptance test for building, publishing, commenting, updating, and cleanup on GitHub.
