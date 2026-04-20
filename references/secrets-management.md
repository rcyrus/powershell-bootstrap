# Secrets Management

Reference for credential handling in a bootstrapped project. Load any time a script needs a password, API token, or private key.

## The rule

Scripts in this scaffold never see raw credentials. Every credential is retrieved at runtime from a broker. The broker is `Microsoft.PowerShell.SecretManagement`, bound to Azure Key Vault (AKV), which in turn is back-filled from Beyond Trust.

Developer path: `Get-Secret` → SecretManagement → AKV vault provider → AKV → Beyond Trust (admin only).

Automation path inside Kubernetes: Flask container → external-secrets-operator → AKV → Beyond Trust.

The script never knows which path it is using. It calls `Get-Secret` and gets a `PSCredential` or a `SecureString` back.

## Anti-patterns to reject on sight

- Hardcoded password in a `.ps1` file. Never.
- Credential in an environment variable read by the script. Environment variables leak into process lists, crash logs, and AI context windows.
- `Get-Credential` prompting the user at runtime. Breaks unattended automation. Also means an AI agent running the script would pause forever.
- Reading a credential from a text file in the repo. Including one commented-out. Including one gitignored but present locally.
- A colleague pasting credentials into Teams chat "just for this one run."

Rajeev's line from the 2026-04-16 D&A office hours: "If somebody says 'I have to go get the credential from Vault or I have to go log into CyberArk and get the opened wallet for the password,' you've already lost. You're in a 1990s mode of credential management."

## Bootstrap the vault binding once per machine

A fresh developer machine needs the SecretManagement modules and the AKV vault provider registered once.

```powershell
Install-PSResource -Name Microsoft.PowerShell.SecretManagement -Scope CurrentUser
Install-PSResource -Name Az.KeyVault -Scope CurrentUser
Install-PSResource -Name SecretManagement.KeyVault -Scope CurrentUser

Register-SecretVault `
    -Name 'CencoraSecrets' `
    -ModuleName 'SecretManagement.KeyVault' `
    -VaultParameters @{ AZKVaultName = 'kv-cencora-automation-dev'; SubscriptionId = '<subscription-guid>' } `
    -DefaultVault
```

After that, the script uses the vault transparently:

```powershell
$cred = Get-Secret -Name 'device-readonly-credential'
```

`Get-Secret` returns `[PSCredential]` for entries stored as credentials, `[SecureString]` for plain secrets.

## Script-side usage

```powershell
# PSCredential for systems that take one
$sshCred = Get-Secret -Name 'network-readonly-svc'
$session = New-SSHSession -ComputerName $device -Credential $sshCred

# SecureString for API tokens — convert only at the point of use
$token = Get-Secret -Name 'inventory-api-token'
$plain = $token | ConvertFrom-SecureString -AsPlainText
try {
    $params = @{
        Uri     = 'https://api.example.internal/v1/devices'
        Headers = @{ Authorization = "Bearer $plain" }
    }
    Invoke-RestMethod @params
}
finally {
    $plain = $null  # drop the plaintext as soon as the call returns
}
```

Never log the SecureString or the plaintext. Never include it in exception messages. Never capture it with `$DebugPreference = 'Continue'`.

## Authoring a new secret

A developer needs a new service credential. Follow this path, not a shortcut:

1. Open a request with Identity & Access Management. Describe the automation, the target system, and the minimum scope.
2. IAM provisions the service principal or service account. Secret lands in Beyond Trust.
3. Beyond Trust sync writes it into AKV on the schedule (typically minutes).
4. The SecretManagement binding finds it by name automatically. No developer ever sees the raw credential.

## Running inside AWX, Actions, or Automate

On Rungs 3 and up of the runtime ladder, the script runs without a human present. Two valid bindings:

- **Inside Kubernetes (Automate itself).** The pod pulls from AKV via external-secrets-operator. The pod's service account is scoped to the specific secrets it needs. SecretManagement just works.
- **GitHub Actions.** Use the Azure login action to obtain a federated identity, then use `Az.KeyVault` inside the job. Do not store the credential in a GitHub Actions secret if AKV can provide it.

```yaml
- uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

- shell: pwsh
  run: |
    $token = Get-AzKeyVaultSecret -VaultName kv-cencora-automation-dev -Name inventory-api-token -AsPlainText
    # use $token, never log it
```

## Mini-principle pattern

The broader governance pattern Rajeev advocates: one fine-grained service principal per automation job. Each principal can do exactly what its automation needs and nothing more.

- `svc-inventory-readonly` — can call the inventory API, cannot write.
- `svc-dns-stale-reader` — can read Infoblox, cannot modify.
- `svc-firewall-ticket-create` — can create ServiceNow tickets in the firewall queue, cannot close or edit them.

If one automation misbehaves, its principal gets disabled. The others keep running. This is the Azure-side analog of AWS IAM fine-grained policies.

The scaffold expects one principal per script. Name the secret after the principal, not the script, so multiple scripts can share a principal if the scope genuinely matches.

## What to check in a code review

- `Get-Secret` appears near the top of every code path that needs credentials.
- The result is scoped to the smallest possible block (`try { } finally { }` resetting to `$null`).
- No `Write-Host`, `Write-Verbose`, or `Write-Debug` ever contains the credential.
- No exception handler catches, logs, and rethrows with the credential in the message.
- No `ConvertFrom-SecureString -AsPlainText` outside a narrow block.
- No `.env` file in the repo, period.
