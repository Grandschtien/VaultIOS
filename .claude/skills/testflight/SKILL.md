---
name: testflight
description: Uploads the next build of the last Vault release to TestFlight from the current branch through fastlane lanes: unit tests, Maestro regression, build bump, tag and upload. The version stays the same. Run with /testflight.
disable-model-invocation: true
---

# Vault TestFlight build

The version comes from the last release tag, the build is the last uploaded one plus 1. The archive uses the `Vylok_release` scheme.

The lanes do all the work. Only run them and write the text: do not bump the version, run git commands that change anything, call xcodebuild or edit project files yourself.

Stop at the first failure and report it; never skip tests or work around it. Run long lanes in the background and wait for them.

If `doctor` reports missing credentials, follow the setup in the `release` skill.

## Steps

1. `fastlane ios doctor` and `scripts/qa/doctor.sh`.
2. `fastlane ios plan_beta`. If the version is already approved, stop: a new version goes through `/release`.
3. `fastlane ios changes`, then read the TestFlight range in `build/release/changes.txt`. Read a diff with `git show <hash>` when a commit title does not explain what changed.
4. Write the text into `build/release/testflight.txt`: in English, covering the TestFlight range, telling testers what to check.
5. `fastlane ios beta notes:build/release/testflight.txt`. It bumps the build, runs unit tests and the regression, commits, builds, uploads, tags `v<version>-<build>` and pushes the current branch.

## Report

Reply with the version and build, the branch and tag, and the TestFlight text. If `changes.txt` says the range is a guess, mention it.
