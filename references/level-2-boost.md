# Level-2 Boost — From L1 to L2 in One Workflow File

Reference for promoting a scaffolded L1 project to L2. Load when the user says "I want my team to own this" or when moving a project from a personal repo into a team-shared repo.

## What "L2" means in concrete terms

On the maturity ladder, L2 is the Tribe: version control, peer review, shared scripts, team ownership. In this scaffold, L2 has three observable properties:

1. The `main` branch cannot be committed to directly. Every change goes through a pull request.
2. Every pull request runs `PSScriptAnalyzer` and `Pester` on a fresh runner. A red check blocks merge.
3. Every pull request needs at least one human review from someone on the owning team.

The scaffold ships the workflow file that gives you property 2. The other two are GitHub branch-protection settings configured once when the repo is promoted.

## The workflow file the scaffold ships

`.github/workflows/lint-and-test.yml`:

```yaml
name: Lint and test

on:
  pull_request:
  push:
    branches: [main]

jobs:
  quality:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install modules
        shell: pwsh
        run: |
          $ErrorActionPreference = 'Stop'
          Install-PSResource -Name PSScriptAnalyzer -Scope CurrentUser -TrustRepository
          Install-PSResource -Name Pester -Scope CurrentUser -TrustRepository
          if (Test-Path ./requirements.psd1) {
              $manifest = Import-PowerShellDataFile ./requirements.psd1
              foreach ($module in $manifest.RequiredModules) {
                  Install-PSResource -Name $module.ModuleName -Version $module.ModuleVersion -Scope CurrentUser -TrustRepository
              }
          }

      - name: Run PSScriptAnalyzer
        shell: pwsh
        run: |
          $issues = Invoke-ScriptAnalyzer -Path ./scripts `
              -Settings ./PSScriptAnalyzerSettings.psd1 `
              -Recurse
          if ($issues) {
              $issues | Format-Table -AutoSize
              throw "$($issues.Count) PSScriptAnalyzer finding(s)."
          }

      - name: Run Pester
        shell: pwsh
        run: |
          $config = New-PesterConfiguration
          $config.Run.Path = './tests'
          $config.Run.Exit = $true
          $config.Output.Verbosity = 'Detailed'
          $config.TestResult.Enabled = $true
          $config.TestResult.OutputPath = './output/testResults.xml'
          Invoke-Pester -Configuration $config

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: ./output/testResults.xml
```

Three jobs in one workflow. Checkout, install, lint, test, upload. No parallelism needed at this size.

## Branch protection settings

When the repo is promoted to team ownership, configure these once on the `main` branch in GitHub → Settings → Branches → Add rule:

- **Require a pull request before merging.** Blocks direct commits to `main`.
- **Require status checks to pass before merging.** Name the required check `quality` (the job name in the workflow). The PR cannot merge until that check is green.
- **Require branches to be up to date before merging.** Prevents merging a PR that passed against an older base.
- **Require at least 1 approving review.** Peer review becomes a merge gate, not a favor.
- **Dismiss stale reviews when new commits are pushed.** Reviewer has to re-approve after changes.
- **Do not allow force pushes.** History stays intact.

Optional additions once the team has more than a handful of contributors:

- **Require review from code owners.** Set up a `CODEOWNERS` file to route reviews by file path.
- **Require signed commits.** For environments where commit provenance matters.

## Promotion from personal to team repo

The path a script takes from Rung 1–2 to Rung 3 when it is promoted, as a concrete GitHub workflow.

### Step 1: the script lives in a personal repo

```
github.com/cencora-{username}/Get-DeviceInventory      # personal
```

The script runs on the author's laptop. Workflow file is present but running in a personal repo has no team-review value yet.

### Step 2: a team repo is created

The platform or owning team creates the team-shared repo. Same scaffold applied.

```
github.com/cencora-team/network-automation              # team
```

The team repo is empty or carries its own conventions file (an `AGENTS.md` at the team level, which individual scripts inherit).

### Step 3: cross-repo PR

The author opens a PR from the personal repo's `main` branch against the team repo's `main`. GitHub supports cross-fork PRs natively as long as both repos are in the same enterprise.

- The team repo's workflow runs against the PR's contents.
- PSScriptAnalyzer runs against the combined tree.
- Pester runs against the combined tree.
- Team review happens on the team repo's PR page.
- On merge, the script becomes part of the team repo. Author's commits are preserved. Co-author attribution optional.

### Step 4: personal repo stays

The author does not delete the personal copy. Personal repo is where experimentation continues. Team repo is authoritative. When the team makes changes, the author can pull them back into their personal fork for local edits.

### Step 5: the script reaches Rung 3

Once in the team repo, the team configures AWX or GitHub Actions to run the script on a schedule, a webhook, or a ticket trigger. The script is now on Rung 3. The author is no longer the trigger.

## What to change in the script when it reaches Rung 3

The L1 script has `Write-Host` prompts and a `Read-Host` pause. That does not work when AWX runs the script at 2 AM.

- Remove every `Read-Host`. Replace with a `-Force` switch that must be set by the caller, or with a `-WhatIf` / `-Confirm` pattern via `$PSCmdlet.ShouldProcess()`.
- Remove every `Write-Host` unless the output is genuinely diagnostic and will not run inside a non-terminal runner.
- Confirm every log line is structured (`Write-Verbose`, `Write-Information`) so the job runner captures it cleanly.
- Confirm every credential comes from `Get-Secret`, not from a user prompt.
- Confirm every error path throws rather than prints. The runner must see a non-zero exit to mark the job failed.

The Pester tests already covered these before the promotion. If not, adding them is the first PR in the team repo.

## What the team gains

| Before (L1) | After (L2) |
|---|---|
| "Works on my machine" as the bar for done | Passes team lint and tests on a fresh runner |
| Review happens over Teams chat if at all | Review happens on the PR, tied to the exact diff |
| One person knows the conventions | Conventions are in `AGENTS.md` and `PSScriptAnalyzerSettings.psd1` |
| Rollback is git checkout on the author's laptop | Rollback is a revert PR, reviewed and merged |
| Rob Osborne: "GitHub — just words to us" | The team practices on every change |

Rob's quote from the 2026-04-08 office hours is the before state. The L2 boost is what makes the words mean something.
