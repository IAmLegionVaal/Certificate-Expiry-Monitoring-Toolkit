# Certificate Expiry Monitoring Toolkit

Created by **Dewald Pretorius**.

A PowerShell 5.1 toolkit for local certificate inventory, expiry reporting, and guarded certificate-service recovery.

## Files

- `Certificate_Expiry_Monitoring_Toolkit.ps1` — read-only certificate inventory and expiry reports.
- `Repair.ps1` — captures evidence, starts Cryptographic Services, or downloads the current Windows Update root-certificate list to an SST file.

```powershell
.\Repair.ps1 -Action Diagnose
.\Repair.ps1 -Action StartCryptographicServices -WhatIf
.\Repair.ps1 -Action RefreshRootCertificateList -Confirm
```

Repair actions require elevation. The workflow does not delete, renew, replace, import, or export personal certificates or private keys. Root-list refresh requires access to Windows Update and saves the resulting SST file in the output directory.

Source-reviewed for Windows PowerShell 5.1; not runtime-tested against every PKI, proxy, or Windows configuration.
