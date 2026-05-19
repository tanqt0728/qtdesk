# Custom Client Packages

The admin `Custom Clients` page can generate deployment packages for managed
RustDesk-compatible clients.

Current scope:

- Generates a profile JSON file.
- Generates a RustDesk `--config` string.
- Generates a Windows PowerShell install/apply script.
- Downloads those files as a `.zip` package.
- Does not yet build a branded binary, MSI, DMG, APK, or Linux package.

## Package Contents

Downloaded packages contain:

- `README.txt`
- `profile.json`
- `rustdesk-config.txt`
- `install-windows.ps1`
- `settings-default.txt`
- `settings-override.txt`

Windows deployment:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1
```

Put a trusted `RustDesk.exe` next to `install-windows.ps1` before running it.

## Safe Rebrand Roadmap

The package generator is the first safe step. The later build-farm phase should:

1. Build from a legally compatible source fork.
2. Keep upstream notices and license obligations.
3. Replace icons, labels, and installer metadata only where allowed.
4. Generate signed Windows installers.
5. Add macOS/Linux build jobs after Windows is stable.

Do not use RustDesk trademarks or logos as your own product branding.
