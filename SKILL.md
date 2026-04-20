---
name: powershell-bootstrap
description: Scaffold a PowerShell 7+ project with opinionated structure, quality tooling (PSScriptAnalyzer, Pester), AGENTS.md for AI agents, GitHub Actions CI, and green-before-done discipline. Apply when starting a fresh PowerShell project, when a user asks to initialize or scaffold a PS repo, or when promoting a loose .ps1 file into a proper project.
---

# PowerShell Bootstrap

Stamps an opinionated PowerShell 7+ script project into an empty folder. The result is ready for Git, ready for GitHub, ready for the AI agent that will write most of the code, and ready to promote to Level 2 with one YAML file.

## When to apply

- Target folder is empty or contains only `.git/`.
- User asks to scaffold, initialize, or set up a PowerShell project.
- User has a loose `.ps1` on their desktop and wants it moved into a real project structure.

## When NOT to apply

- Target folder already has a scaffold. Check for both `AGENTS.md` and `PSScriptAnalyzerSettings.psd1` before stamping anything.
- Project is a PowerShell module (`.psm1` with a `.psd1` manifest), not a script collection. Module scaffold is different. Ask the user before proceeding.
- User is working in Python, Bash, or another language.

## What this produces

```
{{PROJECT_NAME}}/
├── .github/
│   ├── copilot-instructions.md
│   └── workflows/
│       └── lint-and-test.yml
├── .vscode/
│   ├── extensions.json
│   └── settings.json
├── data/
│   ├── .gitignore
│   └── devices.sample.csv
├── docs/
│   └── RUNBOOK.md
├── output/
│   └── .gitignore
├── scripts/
│   └── {{FIRST_SCRIPT}}.ps1
├── tests/
│   └── {{FIRST_SCRIPT}}.Tests.ps1
├── .gitignore
├── AGENTS.md
├── CHANGELOG.md
├── PSScriptAnalyzerSettings.psd1
├── README.md
└── requirements.psd1
```

## Apply procedure

1. Confirm the target folder is empty or contains only `.git/`.
2. Gather inputs from the user. All four are required.
   - `{{PROJECT_NAME}}` — folder name. PascalCase or kebab-case acceptable.
   - `{{PROJECT_DESCRIPTION}}` — one sentence on what the project does.
   - `{{FIRST_SCRIPT}}` — the first script filename, in PowerShell verb-noun form (for example, `Get-DeviceInventory`).
   - `{{AUTHOR_NAME}}` — from `git config user.name` if available.
3. Copy every file from `templates/` into the target, preserving the directory tree. Rename each `.template` suffix off during or after the copy.
4. Substitute the four placeholders in every rendered file.
5. Initialize Git if no `.git/` exists: `git init`.
6. Stage everything, commit: `initial: scaffold via powershell-bootstrap`.
7. Print a one-screen summary: what was created, the four commands the user should run next (`Install-PSResource -Path requirements.psd1`, `./scripts/{{FIRST_SCRIPT}}.ps1 -?`, `Invoke-ScriptAnalyzer`, `Invoke-Pester`).

## Opinions this skill encodes

These are not negotiable. Changing any of them requires a skill edit, not a project-level override.

- **PowerShell version.** Target PowerShell 7.4 or higher. Pin with `#Requires -Version 7.0` at the top of every script. Do not author Windows PowerShell 5.1 fallbacks for new code.
- **Package manager.** Use `PSResourceGet` (built into PS 7.4+). Do not use `Install-Module` / `PowerShellGet v2` in this scaffold. Commands are `Install-PSResource`, `Save-PSResource`, `Find-PSResource`.
- **Quality tooling.** Every project ships with `PSScriptAnalyzer` for linting and `Pester` for testing. Both are declared in `requirements.psd1`. The GitHub Actions workflow runs both.
- **Green-before-done.** A task is complete only when PSScriptAnalyzer and Pester both report green locally. Agents and humans follow the same bar.
- **Secrets.** Come from `Microsoft.PowerShell.SecretManagement` bound to Azure Key Vault. Do not hardcode. Do not pull from environment variables. Do not copy-paste from Beyond Trust into the terminal. See `references/secrets-management.md`.
- **Output discipline.** `Write-Verbose` and `Write-Information` for structured output. `Write-Host` only for interactive prompts that will never run inside AWX or GitHub Actions. Never in library functions.
- **Function discipline.** `[CmdletBinding()]` on every advanced function. Typed `param()` with `[Parameter(Mandatory)]` and validation attributes. Comment-based help with `.SYNOPSIS` and `.EXAMPLE` at minimum.
- **Script discipline.** `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'` at the top of every executable script.
- **Data handling.** Sample input committed as `.sample.csv`. Real customer data ignored via `data/.gitignore`. Every script output goes to `output/`, which is fully ignored.
- **Two files for agents.** `AGENTS.md` at repo root is the cross-tool standard. `.github/copilot-instructions.md` points at it for Copilot specifically. Same content, different paths, one source of truth.

## Partial disclosure

Load these on demand, not eagerly. They exist so the SKILL.md above stays short and the detail is available when the agent needs it.

| File | When to load |
|---|---|
| `references/windows-setup.md` | User is on Windows and has never installed PS 7, or is missing VS Code extensions. |
| `references/powershell-idioms.md` | Reviewing or authoring PS code in the project and needing the idiom table. |
| `references/secrets-management.md` | Any time the script needs a credential. |
| `references/testing-with-pester.md` | Writing or updating Pester tests. |
| `references/level-2-boost.md` | Promoting a personal project to team ownership with CI and branch protection. |

## Green-before-done

Before declaring any task in a scaffolded project "done," run these three commands from the project root. All three must report green.

```powershell
Invoke-ScriptAnalyzer -Path ./scripts -Settings ./PSScriptAnalyzerSettings.psd1 -Recurse
Invoke-Pester ./tests -Output Detailed
git status
```

Rules that go with the commands:

- Zero PSScriptAnalyzer findings at `Error` or `Warning` severity. `Information` findings are allowed but should be explained in a `CHANGELOG.md` entry.
- Every Pester test in `tests/` passes. No skipped tests without an inline comment naming the reason.
- `git status` shows a clean tree or a set of staged changes about to be committed. No untracked files the agent forgot to commit.

If any check fails, do not report "done." Fix or surface the failure to the user.

## Anti-patterns this skill prevents

- **`.ps1` on the desktop.** A script without a scaffold cannot be version-controlled, reviewed, or promoted.
- **Hardcoded paths.** `C:\Users\rcyrus\Desktop\data.csv` in a script means the script runs on one machine.
- **`Write-Host` in library functions.** Breaks composition. Output cannot be piped.
- **Unvalidated parameters.** Script fails 20 lines in instead of at parse time.
- **Silent dependency on installed modules.** A colleague clones, runs, fails with a cryptic error. `#Requires -Modules` prevents this.
- **Credentials in the script file.** Plain text, environment variable, base64-encoded — all the same anti-pattern.
- **`Install-Module ... -Force -SkipPublisherCheck`** in committed code. Means the author was bypassing something important.
- **Mixing 5.1 and 7.x syntax.** Target one interpreter. Pin it.
- **A green local run as the definition of done.** Without the GitHub Actions workflow also green, the script only runs on your machine.

## Extending this skill

Add new references for domain-specific patterns (Active Directory scripts, Exchange Online, Graph API). Keep each reference single-purpose. Do not bloat SKILL.md itself — the top-level should stay short enough to load into every agent context without cost.
