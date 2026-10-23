# Plan

Use the current checkout and unnumbered spec naming established in this repository; no new branch or worktree is needed.

1. Add a pull_request build workflow that installs Nix, runs just test, builds the exact PR head, and uploads only index.html and identifying metadata.
2. Add a trusted default-branch publisher triggered by successful build completion and PR closure. Validate GitHub run/PR/artifact identity before using data. Read PR code only in the unprivileged build workflow.
3. Preserve preview files in a dedicated storage branch and deploy the entire assembled directory with the official Pages artifact/deployment actions. Deploy explicitly; do not rely on pushes made with GITHUB_TOKEN triggering Pages builds. Serialize all publisher jobs, and recheck the PR head before publishing.
4. Use small CommonJS helpers with actions/github-script for GitHub-native orchestration and node:test for their policy/filesystem behavior; this is project CI integration, not recurring agent tooling. Pin Actions to verified release commit SHAs.
5. Keep credentials out of checkouts where not needed. Keep trusted code separate from artifact/storage directories; never execute downloaded games or stored preview files. Disable Nix cache writes from untrusted PR builds.
6. Document setup and the student PR walkthrough. Validate workflow YAML with actionlint, run helper and Elm tests, and build the game through Nix.
7. Inspect repository admin access and existing Pages settings. Configure Actions-based Pages after implementation is reviewable when access permits. Workflows must be on the default branch before workflow_run and closure handling can operate. Report any remaining deployment step precisely; a real fork PR supplies final end-to-end evidence.
