# Testing with Pester

Reference for writing Pester tests in a bootstrapped project. Load when adding a test, debugging a failing test, or promoting a project from L1 to L2.

## Scope at Level 1

At Rung 1 on the runtime ladder, test coverage is a nice-to-have. A personal script that only runs on the author's laptop does not earn its cost back from extensive tests. The scaffold ships one example test so the surface exists and the habit is easy to start.

At Rung 3 and above, tests are a hard requirement. The GitHub Actions workflow runs `Invoke-Pester` on every PR. A red test blocks merge. That is the pivot from L1 to L2.

## File layout

```
tests/
├── Get-DeviceInventory.Tests.ps1     # one test file per script or function
└── _PSScriptAnalyzer.Tests.ps1       # meta-test: scaffold itself passes the linter
```

Each `*.Tests.ps1` file is auto-discovered by `Invoke-Pester tests/`. Do not configure discovery manually.

## Minimal test file

```powershell
BeforeAll {
    . "$PSScriptRoot/../scripts/Get-DeviceInventory.ps1"
}

Describe 'Get-DeviceInventory' {

    Context 'parameter validation' {
        It 'rejects an unknown region' {
            { Get-DeviceInventory -Region 'antarctica' } | Should -Throw
        }

        It 'accepts the four known regions' {
            foreach ($r in 'us-east', 'us-west', 'emea', 'apac') {
                { Get-DeviceInventory -Region $r -WhatIf } | Should -Not -Throw
            }
        }
    }

    Context 'output shape' {
        BeforeAll {
            Mock Invoke-RestMethod {
                @(
                    [PSCustomObject]@{ hostname = 'edge-01'; ip = '10.0.0.1'; status = 'up' }
                    [PSCustomObject]@{ hostname = 'edge-02'; ip = '10.0.0.2'; status = 'down' }
                )
            }
        }

        It 'returns one object per device' {
            $result = Get-DeviceInventory -Region us-east
            $result.Count | Should -Be 2
        }

        It 'preserves hostname casing' {
            $result = Get-DeviceInventory -Region us-east
            $result[0].Hostname | Should -Be 'edge-01'
        }
    }
}
```

## Idioms that actually test something

The anti-pattern is a test that asserts tautologies. Pester gives you `Should -Not -BeNullOrEmpty`, and the temptation is to call that a test. It is not.

| Test shape | What it verifies | Verdict |
|---|---|---|
| `$result | Should -Not -BeNullOrEmpty` | The function returned anything at all | Weak. Any non-crash passes. |
| `$result.Count | Should -BeGreaterThan 0` | Same thing with a counting operator | Weak. |
| `$result.Count | Should -Be 2` against a two-row mock | Mock setup matches assertion | Real. |
| `$result[0].Hostname | Should -Be 'edge-01'` | Output shape is stable | Real. |
| `{ Get-X -BadParam } | Should -Throw` | Validation attribute fires | Real. |
| `Should -Invoke Invoke-RestMethod -ParameterFilter { ... }` | The HTTP call had the expected headers | Real. |

Prefer the "real" column. If you cannot write one, do not ship the test.

## Mocks

Mock external calls. Do not mock the thing you are actually testing.

- `Invoke-RestMethod`, `Invoke-WebRequest` — mock. Network calls fail in CI for reasons that have nothing to do with your code.
- `Get-Secret` — mock. Tests should not require a real vault binding.
- `New-SSHSession`, `Invoke-SSHCommand` — mock. CI has no target devices.
- `Get-Date` — mock when your test depends on time. Leave alone otherwise.
- `Import-Csv` — do not mock. Point at a fixture CSV in `tests/fixtures/` instead.

## Fixtures

Put sample input in `tests/fixtures/`. Name the file after what it represents, not the test.

```
tests/
├── fixtures/
│   ├── devices.two-rows.csv
│   ├── devices.mixed-status.csv
│   └── devices.malformed.csv
└── Get-DeviceInventory.Tests.ps1
```

Tests reference fixtures with `"$PSScriptRoot/fixtures/devices.two-rows.csv"`.

## Running Pester

Local, interactive:

```powershell
Invoke-Pester ./tests -Output Detailed
```

Local, single file while iterating:

```powershell
Invoke-Pester ./tests/Get-DeviceInventory.Tests.ps1 -Output Detailed
```

CI, the way the scaffold's workflow runs it:

```powershell
Invoke-Pester ./tests -Output Detailed -CI
```

`-CI` makes Pester emit JUnit-compatible output and exit with a non-zero code on any failure. The GitHub Actions workflow relies on the non-zero exit.

## Coverage

Pester can produce coverage reports. At L1 this is noise. At L2+ it is useful as a trend indicator, not as a gate.

```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = './scripts'
$config.CodeCoverage.OutputFormat = 'JaCoCo'
$config.CodeCoverage.OutputPath = './output/coverage.xml'
Invoke-Pester -Configuration $config
```

Do not block merges on a coverage percentage. Do note when coverage drops significantly in a PR.

## What to keep out of tests

- Tests that require a specific machine, IP, or credential.
- Tests that hit production services for "real" validation.
- `Start-Sleep` to wait for eventual consistency — use a Pester retry helper instead.
- Assertions on values your mock just set. That tests the mock, not the code.
