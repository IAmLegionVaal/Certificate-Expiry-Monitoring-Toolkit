#requires -Version 5.1
<#
.SYNOPSIS
  Guarded local certificate-services repair companion.
.DESCRIPTION
  Created by Dewald Pretorius. Captures certificate evidence, starts required
  cryptographic services, or refreshes Windows root certificates into an SST
  file. It never deletes, renews, replaces, or exports private certificates.
#>
[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]
param(
    [ValidateSet('Diagnose','StartCryptographicServices','RefreshRootCertificateList')]
    [string]$Action='Diagnose',
    [string]$OutputPath=(Join-Path ([Environment]::GetFolderPath('Desktop')) 'Certificate_Expiry_Repair')
)
$ErrorActionPreference='Stop'
$ExitPrerequisite=3;$ExitActionFailure=5;$ExitVerificationFailure=6
function Test-Administrator {$principal=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent());$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}
New-Item -ItemType Directory -Path $OutputPath -Force|Out-Null
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss';$logPath=Join-Path $OutputPath "Repair_$stamp.log"
function Log([string]$Message){$line='{0:u} {1}' -f (Get-Date),$Message;Write-Host $line;Add-Content -LiteralPath $logPath -Value $line}
$before=[ordered]@{
    Action=$Action
    CryptSvc=(Get-Service CryptSvc -ErrorAction SilentlyContinue|Select-Object Name,Status,StartType)
    Certificates=@(Get-ChildItem Cert:\LocalMachine\My,Cert:\LocalMachine\WebHosting,Cert:\CurrentUser\My -ErrorAction SilentlyContinue|Select-Object Subject,Issuer,Thumbprint,NotBefore,NotAfter,HasPrivateKey)
}
$before|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $OutputPath "PreRepair_$stamp.json") -Encoding UTF8
if($Action -eq 'Diagnose'){Log '[COMPLETE] Read-only certificate evidence saved.';exit 0}
if(-not(Test-Administrator)){Log '[FAILED] Run from an elevated PowerShell session.';exit $ExitPrerequisite}
try{
    if($Action -eq 'StartCryptographicServices' -and $PSCmdlet.ShouldProcess('Cryptographic Services','Start and verify')){
        $service=Get-Service CryptSvc
        if($service.Status -ne 'Running'){Start-Service CryptSvc}
    }
    elseif($Action -eq 'RefreshRootCertificateList' -and $PSCmdlet.ShouldProcess('Windows Update root certificate list','Download a current SST inventory')){
        $sstPath=Join-Path $OutputPath "WindowsRoots_$stamp.sst"
        $process=Start-Process -FilePath (Join-Path $env:WINDIR 'System32\certutil.exe') -ArgumentList @('-generateSSTFromWU',"`"$sstPath`"") -Wait -PassThru -NoNewWindow
        if($process.ExitCode -ne 0 -or -not(Test-Path -LiteralPath $sstPath)){throw "Root certificate refresh failed with code $($process.ExitCode)."}
        Log "[OUTPUT] Root certificate list saved to $sstPath"
    }
}catch{Log "[FAILED] $($_.Exception.Message)";exit $ExitActionFailure}
Start-Sleep -Seconds 2
if($Action -eq 'StartCryptographicServices' -and (Get-Service CryptSvc).Status -ne 'Running'){Log '[VERIFY-FAILED] Cryptographic Services is not running.';exit $ExitVerificationFailure}
Log '[COMPLETE] Certificate-services repair completed. Personal certificates were not changed.'
exit 0
