# Windows Setup for PowerShell 7 and VS Code

Reference for first-time setup on a Windows machine. Load this when the user is installing PowerShell 7, configuring VS Code, or hitting execution-policy errors.

## Install PowerShell 7

PowerShell 7 is separate from the Windows PowerShell 5.1 that ships with the OS. Install it via winget.

```powershell
winget install --id Microsoft.PowerShell --source winget
```

After install, the command is `pwsh` (not `powershell`). Verify:

```powershell
pwsh -NoProfile -Command '$PSVersionTable.PSVersion'
```

Expected output: `7.4.x` or newer.

## Make PowerShell 7 the default terminal shell

In Windows Terminal, open Settings → Startup → Default profile → select "PowerShell" (the one with the black icon, not "Windows PowerShell" with the blue icon).

In VS Code, set `terminal.integrated.defaultProfile.windows` to `PowerShell`. The scaffold already includes this in `.vscode/settings.json`.

## Execution policy

PowerShell 7 ships with execution policy `RemoteSigned` on Windows by default. If the user is hitting "scripts are disabled" errors, check and set:

```powershell
Get-ExecutionPolicy -Scope CurrentUser
# If not RemoteSigned or Unrestricted:
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Do not recommend `Unrestricted` or `Bypass` as durable settings. `RemoteSigned` is the correct default for local work.

## Required VS Code extensions

The scaffold declares these in `.vscode/extensions.json`. When the user opens the project, VS Code prompts to install any that are missing.

| Extension ID | Purpose |
|---|---|
| `ms-vscode.powershell` | Official PowerShell extension. Includes PSScriptAnalyzer integration, debugger, Pester test discovery, IntelliSense. |
| `github.copilot` | GitHub Copilot code suggestions. Requires a Cencora-provisioned enterprise license. |
| `github.copilot-chat` | Copilot Chat pane and agent mode. |
| `redhat.vscode-yaml` | YAML syntax and schema validation for GitHub Actions workflows and `PSScriptAnalyzerSettings.psd1` alternatives. |

## Copilot enterprise provisioning gotcha

If the user signs into VS Code with their GitHub account but Copilot throws "no permission for enterprise model," the account has not been provisioned at the Cencora GitHub Enterprise tenant. This is an admin configuration issue, not a user error. Steps:

1. Open a scratch folder with a junk file — do not attempt this in a real project.
2. Open the Copilot pane. Screenshot any "finish setup" banners or provisioning errors.
3. Send the screenshot to the Cencora GitHub Enterprise admin.
4. Once provisioning lands, sign out of VS Code's GitHub account, close VS Code, sign back in.

Reference: the 2026-04-15 office hours walked Ashish Karpe through this exact path.

## Recommended VS Code settings beyond the scaffold

The scaffold's `.vscode/settings.json` covers the baseline. Additional settings a user may want:

```json
{
  "powershell.codeFormatting.preset": "Stroustrup",
  "powershell.integratedConsole.showOnStartup": false,
  "powershell.promptToUpdatePowerShell": false,
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": "explicit"
  }
}
```

## Starting configuration for new Copilot users

These are the first-session defaults Rajeev recommends for engineers new to Copilot. They reduce the chance of accidental mutation while the user is learning.

- **Default model:** Sonnet 4.6. Opus is overkill for L0/L1 scripting and burns 3x the quota.
- **Default mode:** Plan mode. Copilot acts as a planner rather than an executor until the user approves each step.
- **Default approvals:** ON. Copilot asks before running commands, editing files, or installing packages.

Revisit these after a week of use. Engineers comfortable with the tool usually relax approvals for read-only actions.

## Known first-time friction

| Symptom | Cause | Fix |
|---|---|---|
| `pwsh` not found in terminal | PS 7 installed but PATH not refreshed | Close and reopen the terminal, or restart VS Code. |
| "cannot be loaded because running scripts is disabled" | Execution policy | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`. |
| "no permission for enterprise model" in Copilot | Enterprise provisioning not complete | Screenshot to GitHub Enterprise admin. |
| Copilot suggesting `Write-Host` everywhere | AGENTS.md missing or not read by Copilot | Confirm `.github/copilot-instructions.md` exists and points at AGENTS.md. |
| PSScriptAnalyzer findings on every save | Settings file missing | Confirm `PSScriptAnalyzerSettings.psd1` at repo root. |
