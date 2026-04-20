# PowerShell Idioms — Use and Avoid

Reference for authoring or reviewing PowerShell 7+ code in a bootstrapped project. Load when writing functions, debugging Copilot suggestions, or reviewing a PR.

## Function skeleton

Every advanced function in a script uses this shape. Copilot should produce this by default when `AGENTS.md` references it.

```powershell
function Get-DeviceInventory {
    <#
    .SYNOPSIS
        Query the device inventory API and return structured objects.
    .DESCRIPTION
        Calls the upstream inventory service and emits one PSCustomObject per device.
    .PARAMETER Region
        Region code. Constrained to 'us-east', 'us-west', 'emea', 'apac'.
    .EXAMPLE
        Get-DeviceInventory -Region us-east | Where-Object { $_.Status -eq 'offline' }
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('us-east', 'us-west', 'emea', 'apac')]
        [string]$Region,

        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$PageSize = 25
    )

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'
    }

    process {
        Write-Verbose "Fetching inventory for region '$Region'"
        # logic
    }

    end {
        # cleanup
    }
}
```

## Idiom table

| Use | Avoid | Why |
|---|---|---|
| `[CmdletBinding()]` on every function | Plain `function foo { ... }` | `CmdletBinding` gives you `-Verbose`, `-Debug`, `-ErrorAction`, `-WhatIf` for free. |
| Typed `param()` with validation | Untyped params, runtime type checks | Invalid input fails at parse time, not 20 lines in. |
| `[ValidateSet(...)]`, `[ValidateRange(...)]`, `[ValidateScript(...)]` | Manual `if ($x -in $allowed)` | Validation attributes render in `Get-Help` and `-WhatIf`. |
| `Write-Verbose` / `Write-Information` | `Write-Host` in logic | `Write-Host` always prints. Breaks automation and piping. |
| `$PSCmdlet.ShouldProcess()` | Unguarded destructive commands | Gives every advanced function a free `-WhatIf` and `-Confirm`. |
| `Join-Path $root 'subdir' 'file.csv'` | `"$root\subdir\file.csv"` | Cross-platform safe. No doubled backslashes. |
| `Import-Csv` / `Export-Csv` | Manual string splitting | CSV parser handles quoted fields, embedded commas, encoding. |
| `ConvertFrom-Json` / `ConvertTo-Json -Depth N` | Regex on JSON text | `-Depth` default is 2. Always set it explicitly for nested objects. |
| `Invoke-RestMethod` | `Invoke-WebRequest` when you want parsed objects | `Invoke-RestMethod` deserializes JSON/XML automatically. |
| Splatting with `@params` | Long one-liners with 8+ parameters | Readable. Git diffs show single-line changes when one parameter flips. |
| `[PSCustomObject]@{ ... }` | `New-Object PSObject -Property @{ ... }` | Shorter, faster, preserves key order. |
| `-ErrorAction Stop` on risky calls | Default `Continue` everywhere | Exceptions become catchable. Silent failures become loud. |
| `try { } catch { } finally { }` | Bare `try / catch` with swallowed exception | Always log the caught exception. Re-throw unless handled. |
| `-Depth N` on `ConvertTo-Json` | Default depth of 2 | Default drops nested data silently. |
| `$PSNativeCommandArgumentPassing = 'Standard'` at script top | Hoping that external command args work | In PS 7.3+, fixes long-standing bugs around passing arguments to native commands. |
| Pipeline-friendly output (one object per row) | Pre-formatted strings | Downstream `Where-Object` / `Select-Object` works on objects, not text. |

## Patterns for common tasks

**Read a CSV, loop rows, emit objects.**

```powershell
Import-Csv $Path | ForEach-Object {
    [PSCustomObject]@{
        Hostname = $_.Hostname.Trim()
        Ip       = $_.IpAddress
        Status   = Get-DeviceStatus -Hostname $_.Hostname
    }
}
```

**Call a REST API, handle failure.**

```powershell
$params = @{
    Uri         = "https://api.example.internal/v1/devices"
    Method      = 'GET'
    Headers     = @{ Authorization = "Bearer $Token" }
    ErrorAction = 'Stop'
}

try {
    $response = Invoke-RestMethod @params
}
catch {
    Write-Error "Inventory API call failed: $_"
    throw
}
```

**SSH to a device and run a command.** Use `Posh-SSH`.

```powershell
$creds = Get-Secret -Name 'device-readonly-credential'
$session = New-SSHSession -ComputerName $device.Hostname -Credential $creds -AcceptKey

try {
    $result = Invoke-SSHCommand -SessionId $session.SessionId -Command 'show version'
    $result.Output
}
finally {
    Remove-SSHSession -SessionId $session.SessionId | Out-Null
}
```

**Judgment pause in a script (Session 3 callback).**

```powershell
Write-Host "About to modify $($targets.Count) devices. Review above, press Enter to continue, Ctrl-C to abort."
Read-Host | Out-Null
```

## What to avoid in reviews

- Aliases in committed scripts. `ls` means `Get-ChildItem`, `?` means `Where-Object`, `%` means `ForEach-Object`. Readable code uses the full name.
- `Get-WmiObject`. Deprecated. Use `Get-CimInstance`.
- `Invoke-Expression` on user input. Same anti-pattern as `eval` in any language.
- `$null -eq $x` is correct. `$x -eq $null` triggers a PSScriptAnalyzer warning because of how `-eq` handles collection operands.
- `catch { }` with no body. Silently swallows exceptions. If the exception is genuinely expected, name it and explain why.
- `Start-Sleep` as a synchronization primitive. Poll a condition instead.
- `Write-Output` in a function that already emits objects. Redundant and confuses pipeline semantics.
- Reassignment of `$_` inside a pipeline. Shadows the automatic variable.

## Useful `$PSStyle` settings (PS 7.2+)

```powershell
$PSStyle.OutputRendering = 'Host'           # render colors in interactive shell
$PSStyle.Progress.View = 'Minimal'          # less screen-grabbing progress UI
```

Good for local work. Do not rely on them inside AWX or Actions runners — those have no terminal.
