# Browser Video Capture Compatibility

QT Desk Web v3 can render normal desktop, browser, photo, and non-protected video frames through the RustDesk stream. Some browser video failures happen before Web v3 receives a frame, usually because Windows or the browser presents video through a hardware overlay path.

## Best Compatibility Steps

1. In Web v3, keep `Direct YUV` off unless you are testing rendering performance.
2. In Web v3, enable `Video mode`.
3. On the remote Windows computer, run the copied `Copy color fix` command, or run this repo script:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\windows-browser-capture-compat.ps1 -KillBrowsers
```

4. If browser colors are still wrong, or browser video is still black/frozen, run PowerShell as Administrator and use:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\windows-browser-capture-compat.ps1 -DisableMpo -KillBrowsers
```

5. Reopen the browser, then reconnect Web v3.
6. For Firefox, disable hardware acceleration in Settings > General > Performance.

## What This Fixes

- Hardware-accelerated browser video that appears black in remote capture.
- Browser-only color corruption caused by Chrome/Edge/Brave GPU composition paths.
- Some Windows DWM multi-plane overlay capture issues.
- Frozen video frames caused by overlay presentation.
- Low Web v3 frame rate/quality during non-protected video playback.

## Hard Limit

DRM/HDCP protected playback can intentionally block screen capture. If the remote operating system or browser refuses to expose those pixels, Web v3 cannot legally or reliably reconstruct them from the remote stream.

## Undo

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\windows-browser-capture-compat.ps1 -Undo
```
