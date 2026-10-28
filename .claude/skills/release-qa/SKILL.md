---
name: release-qa
description: Pre-release QA run of the Vault iOS app on a simulator against a local backend. Use when the user asks to run release QA, smoke-test the app before release, or runs /release-qa [scenario ids…]. Starts the backend, creates disposable accounts, grants or buys subscriptions through RevenueCat and drives the app with Xcode MCP.
model: sonnet
---

# Release QA

Runs scenarios from `QA/scenarios/*.md` on the simulator. Each scenario runs in a `qa-runner` subagent; you orchestrate and write the report.

Arguments: scenario ids (file names without `.md`). No arguments means all scenarios in file-name order.

## Rules

- Only `scripts/qa/*` touch the backend, the database and RevenueCat. Never call production `moneyvaultapp.com`, never edit `Vault_backend/.env`, never print secrets.
- QA accounts are `qa-<run>-<scenario>@example.com`. Scripts refuse other emails.
- A failed scenario does not stop the run. A failed setup marks the scenario `BLOCKED`.
- Always run the teardown (step 5), even after failures.

## 1. Prepare

```bash
scripts/qa/doctor.sh          # stop and report if it fails
scripts/qa/backend-down.sh
scripts/qa/backend-up.sh      # starts Postgres, creates vault_qa if needed
scripts/qa/backend-down.sh
scripts/qa/reset-db.sh        # clean vault_qa
scripts/qa/backend-up.sh
scripts/qa/app-env.sh         # JSON for environmentVariables below
```

Run id: `date +%m%d%H%M`. Report file: `QA/reports/<YYYY-MM-DD-HHMM>.md`.

## 2. Launch the app

1. `XcodeListWorkspaces` → the workspace whose path ends with `VaultiOS/Vault.xcodeproj`.
2. `DeviceInteractionStartWorkspaceSession` with `deviceIdentifier: "iPhone 17 Pro"`, `sessionIdentifier: "Release QA"`. Keep its `deviceUUID`.
3. `DeviceInteractionInstallAndRun` with `environmentVariables` from `app-env.sh`.
4. If the build fails, read `GetBuildLog` (severity error), report it and go to teardown.

## 3. For each scenario

1. Read the scenario front matter: `id`, `setup`, `login`, `cleanup`.
2. Set `EMAIL=qa-<run>-<id>@example.com` (lowercase, only `a-z0-9-`).
3. Run each `setup` step with `scripts/qa/`, substituting `$EMAIL`:
   - `create-user` → `create-user.sh $EMAIL`
   - `seed <fixture>` → `seed.sh $EMAIL <fixture>`
   - `rc-grant [entitlement] [duration]` → `rc-grant.sh $EMAIL …` then `wait-subscription.sh $EMAIL PREMIUM`
   - `rc-revoke [entitlement]` → `rc-revoke.sh $EMAIL …` then `wait-subscription.sh $EMAIL REGULAR`
4. Start a `qa-runner` agent with: the scenario ids with their `EMAIL`s and a note that setup is done, `QA_PASSWORD` and `QA_DEV_CODE` (`source scripts/qa/env.sh && echo "$QA_PASSWORD $QA_DEV_CODE"` — test-only values), the interaction session key, `deviceUUID` and `workspaceIdentifier`. One runner may take several scenarios: do the setup of all of them first. The runner reinstalls and relaunches the app before each scenario (with `VAULT_QA_SESSION` for `login: api`).
5. Wait for the runner's result.
6. Run each `cleanup` step (`delete-user` → `delete-user.sh $EMAIL`). Ignore a cleanup failure for an account the scenario deleted itself.
7. Append the runner's result to the report.

## 4. Report

```markdown
# Release QA — <date>
Build: <git rev-parse --short HEAD>, backend <git -C ../Vault_backend rev-parse --short HEAD>

| Scenario | Result | Notes |
|---|---|---|
| 02-login-logout | PASS | |

## <scenario id> — FAIL
- Step: …
- Expected: … / Actual: …
- Screenshot: <path>
- App log: …
- Backend log: `grep -iE 'error|panic' QA/.run/backend.log | tail`
```

## 5. Teardown

```bash
scripts/qa/rc-cleanup.sh
scripts/qa/backend-down.sh
```

Then `DeviceInteractionEndSession`. Tell the user the summary table and the report path.
