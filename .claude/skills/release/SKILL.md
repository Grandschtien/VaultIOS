---
name: release
description: Ships a new Vault store version from the current main through fastlane lanes: unit tests, Maestro regression, version bump, tag, TestFlight upload and App Store Connect preparation, and writes What's New from the diff. Never submits for review. Run with /release, /release 2.0 or /release phased.
disable-model-invocation: true
---

# Vault release

Runs only on `main` in sync with `origin/main`. Without a version argument the next minor is used. The build is always 1. The archive uses the `Vylok_release` scheme.

Arguments, in any order: a marketing version (`2.0`) and `phased` to turn phased release on. Phased release is off by default.

The lanes do all the work. Only run them and write the texts: do not bump the version, run git commands that change anything, call xcodebuild or edit project files yourself.

Stop at the first failure and report it; never skip tests or work around it. Run long lanes in the background and wait for them.

**Never submit the version for review or release it. That stays with the user.**

## Setup (only when `doctor` reports missing credentials)

Stop and tell the user to:
1. Create a Team Key with the App Manager role in App Store Connect → Users and Access → Integrations.
2. Save the `.p8` into `~/.appstoreconnect/private_keys/`.
3. Create `~/.appstoreconnect/vault.env` with `ASC_KEY_ID`, `ASC_ISSUER_ID` and `ASC_KEY_PATH`.

Never read or print these files.

## Steps

1. `fastlane ios doctor` and `scripts/qa/doctor.sh`. If `fastlane/metadata` has no locale folders, run `fastlane ios pull_metadata`, show the result and stop: the user commits it first.
2. `fastlane ios plan_release [version:<version>]`. Use the printed version and build below.
3. `fastlane ios changes`, then read `build/release/changes.txt`. Read a diff with `git show <hash>` when a commit title does not explain what the user gets.
4. Write the TestFlight text into `build/release/testflight.txt`.
5. `fastlane ios release [version:<version>] notes:build/release/testflight.txt`, with the version from step 2. It bumps on `main`, runs unit tests and the regression, commits, builds, uploads, tags `v<version>` and pushes.
6. Write `fastlane/metadata/<locale>/release_notes.txt` for every locale folder.
7. `fastlane ios prepare version:<version> build:<build>`, adding `phased:true` only for `phased`. It commits and pushes the notes, sends them, and attaches the build.

## Texts

- TestFlight text covers the TestFlight range, is in English and tells testers what to check.
- What's New covers the store range and describes only what a user notices: 1 to 5 short lines about features, improvements and fixes. Leave out refactors, tests, tooling, analytics, QA and version bumps. If nothing is noticeable, write a general line about stability and performance.
- Write each locale natively, not word for word. No uppercase words, no internal names, no promises the code does not back up.

## Report

Reply with the version and build, the tag, phased release on or off, What's New per locale, the TestFlight text, and what is left: review the version in App Store Connect and submit it for review. If `changes.txt` says the range is a guess, mention it.
