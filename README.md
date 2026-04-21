# PowerShell Bootstrap

Opinionated scaffolding for PowerShell 7+ script projects. Stamps out a complete project structure with testing, linting, CI/CD, and AI agent instructions in one command.

## What this does

Transforms an empty folder into a production-ready PowerShell project with:

- **Quality tooling** — PSScriptAnalyzer for linting, Pester for testing
- **CI/CD ready** — GitHub Actions workflow that runs checks on every push
- **AI agent friendly** — `AGENTS.md` with project rules and conventions
- **Secrets management** — Integration with Azure Key Vault via `SecretManagement`
- **Green-before-done discipline** — Nothing is "done" until linters and tests pass

This is a [Claude Code](https://code.claude.com) skill, but the templates work standalone too.

## Quick start

### As a Claude skill

If you have this installed as a skill in Claude Code:

```
"scaffold a new PowerShell project called DeviceInventory"
```

Claude will ask for:
- Project description
- First script name (verb-noun format, e.g., `Get-DeviceInventory`)
- Author name

### Manual usage

1. Copy `templates/*` into your empty project folder
2. Remove `.template` extensions from all files
3. Replace placeholders:
   - `{{PROJECT_NAME}}` — your project folder name
   - `{{PROJECT_DESCRIPTION}}` — one-line description
   - `{{FIRST_SCRIPT}}` — initial script name (e.g., `Get-DeviceInventory`)
   - `{{AUTHOR_NAME}}` — your name
4. Initialize git and commit

## What you get

```
YourProject/
├── .github/
│   ├── copilot-instructions.md
│   └── workflows/
│       └── lint-and-test.yml        # CI workflow
├── .vscode/
│   ├── extensions.json              # recommended extensions
│   └── settings.json                # PowerShell formatting rules
├── data/
│   ├── .gitignore                   # ignores real data
│   └── devices.sample.csv           # sample input
├── docs/
│   └── RUNBOOK.md                   # operational guide
├── output/
│   └── .gitignore                   # ignores all output
├── scripts/
│   └── YourScript.ps1               # your first script
├── tests/
│   └── YourScript.Tests.ps1         # Pester tests
├── .gitignore
├── AGENTS.md                        # AI agent instructions
├── CHANGELOG.md
├── PSScriptAnalyzerSettings.psd1    # linting rules
├── README.md
└── requirements.psd1                # dependency declaration
```

## Opinions baked in

These are non-negotiable (by design):

### PowerShell 7.4+

Target modern PowerShell. Every script has `#Requires -Version 7.0` at the top. No Windows PowerShell 5.1 fallbacks.

### PSResourceGet for dependencies

Use `Install-PSResource`, not the legacy `Install-Module`. Declare dependencies in `requirements.psd1`.

### Green-before-done

A task is complete only when:

```powershell
Invoke-ScriptAnalyzer -Path ./scripts -Settings ./PSScriptAnalyzerSettings.psd1 -Recurse
Invoke-Pester ./tests -Output Detailed
git status  # clean or staged
```

All three report green. No exceptions.

### Secrets from Azure Key Vault

Credentials come from `Microsoft.PowerShell.SecretManagement` bound to Azure Key Vault. Never hardcoded, never from environment variables, never pasted from password managers.

See [`references/secrets-management.md`](references/secrets-management.md).

### Output discipline

- `Write-Verbose` and `Write-Information` for structured output
- `Write-Host` only for interactive prompts (never in library functions)
- All script output goes to `output/` (fully ignored by git)
- Sample data in `data/` with `.sample.csv` extension
- Real customer data ignored via `data/.gitignore`

### Function discipline

Every advanced function has:

- `[CmdletBinding()]`
- Typed `param()` with `[Parameter(Mandatory)]` where needed
- Validation attributes (`[ValidateNotNullOrEmpty()]`, etc.)
- Comment-based help with `.SYNOPSIS` and `.EXAMPLE`

### Script discipline

Every executable script starts with:

```powershell
#Requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
```

## When to use this

- Starting a fresh PowerShell automation project
- Promoting a loose `.ps1` script into a proper project
- Need a scaffold that's ready for team ownership and CI

## When NOT to use this

- Building a PowerShell module (`.psm1` with manifest) — modules need different structure
- Working with Windows PowerShell 5.1 requirements
- Project already has a scaffold in place

## Reference documentation

Located in [`references/`](references/):

- [`powershell-idioms.md`](references/powershell-idioms.md) — common patterns and best practices
- [`secrets-management.md`](references/secrets-management.md) — Azure Key Vault integration
- [`testing-with-pester.md`](references/testing-with-pester.md) — writing effective tests
- [`level-2-boost.md`](references/level-2-boost.md) — promoting to team ownership with branch protection
- [`windows-setup.md`](references/windows-setup.md) — installing PowerShell 7 and VS Code

## Anti-patterns this prevents

- `.ps1` scripts living on your desktop
- Hardcoded paths (`C:\Users\you\Desktop\data.csv`)
- `Write-Host` in library functions (breaks piping)
- Credentials in script files
- Unvalidated parameters (fails 20 lines in instead of immediately)
- `Install-Module ... -Force -SkipPublisherCheck` in committed code
- Mixing PowerShell 5.1 and 7.x syntax
- "It works on my machine" as the definition of done

## Extending this skill

Add new references in `references/` for domain-specific patterns:

- Active Directory automation
- Exchange Online management
- Microsoft Graph API integration
- Azure resource management

Keep each reference single-purpose and load on-demand.

## Author

Rajeev Cyrus
