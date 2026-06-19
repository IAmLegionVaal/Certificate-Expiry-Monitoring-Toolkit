# Certificate Expiry Monitoring Toolkit

A read-only PowerShell toolkit for local certificate inventory and expiry reporting.

## Features

- Local machine certificate inventory
- Expiry threshold reporting
- Certificate subject, issuer, store, and thumbprint context
- CSV, JSON, and HTML reports

## How to run

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Certificate_Expiry_Monitoring_Toolkit.ps1
```

## Safety

Diagnostic-only. It does not import, export, renew, or remove certificates.
