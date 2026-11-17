param(
  [Parameter(Mandatory = $true)]
  [string] $EncryptedFile
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Add-Type -AssemblyName System.Security

# The token is protected for the Windows user who created the backup. It is
# copied only when the operator explicitly runs this command; never print it.
$bytes = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $EncryptedFile).Path)
$plain = [Security.Cryptography.ProtectedData]::Unprotect(
  $bytes, $null, [Security.Cryptography.DataProtectionScope]::CurrentUser
)
try {
  $secret = [Text.Encoding]::UTF8.GetString($plain)
  Set-Clipboard -Value $secret
  Write-Output 'Token copied. Paste it into the admin dashboard, then clear the clipboard.'
} finally {
  [Array]::Clear($plain, 0, $plain.Length)
}
