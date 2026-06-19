#requires -Version 5.1
<#
.SYNOPSIS
    Certificate Expiry Monitoring Toolkit.
.DESCRIPTION
    Read-only local certificate inventory and expiry reporter.
#>
[CmdletBinding()]
param([int]$WarningDays=30,[string]$OutputPath)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
if([string]::IsNullOrWhiteSpace($OutputPath)){$OutputPath=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Certificate_Expiry_Reports'}
New-Item -Path $OutputPath -ItemType Directory -Force|Out-Null
$stores='Cert:\LocalMachine\My','Cert:\LocalMachine\WebHosting','Cert:\CurrentUser\My'
$rows=@()
foreach($store in $stores){if(Test-Path $store){$rows+=Get-ChildItem $store -ErrorAction SilentlyContinue|ForEach-Object{[PSCustomObject]@{Store=$store;Subject=$_.Subject;Issuer=$_.Issuer;Thumbprint=$_.Thumbprint;NotBefore=$_.NotBefore;NotAfter=$_.NotAfter;DaysRemaining=[math]::Floor(($_.NotAfter-(Get-Date)).TotalDays);HasPrivateKey=$_.HasPrivateKey;Status=$(if($_.NotAfter -lt (Get-Date)){'Expired'}elseif($_.NotAfter -lt (Get-Date).AddDays($WarningDays)){'Warning'}else{'OK'})}}}}
$rows=$rows|Sort-Object DaysRemaining
$rows|Export-Csv (Join-Path $OutputPath "certificate_inventory_$stamp.csv") -NoTypeInformation -Encoding UTF8
$rows|ConvertTo-Json -Depth 5|Set-Content (Join-Path $OutputPath "certificate_inventory_$stamp.json") -Encoding UTF8
$summary=[PSCustomObject]@{Computer=$env:COMPUTERNAME;CertificateCount=@($rows).Count;Expired=@($rows|Where-Object Status -eq 'Expired').Count;Warning=@($rows|Where-Object Status -eq 'Warning').Count;ThresholdDays=$WarningDays;Generated=Get-Date}
$html="<h1>Certificate Expiry - $env:COMPUTERNAME</h1><p>Generated $(Get-Date)</p><h2>Summary</h2>$(@($summary)|ConvertTo-Html -Fragment)<h2>Certificates</h2>$($rows|ConvertTo-Html -Fragment)"
$html|ConvertTo-Html -Title 'Certificate Expiry'|Set-Content (Join-Path $OutputPath "certificate_expiry_$stamp.html") -Encoding UTF8
$summary|Format-List
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
