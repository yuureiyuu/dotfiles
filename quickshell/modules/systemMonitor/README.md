# System Monitor

Graphical btop-like monitor for Quickshell.

`SystemStatsConsumer` keeps the shared `SystemStats` service active while the monitor is open. The service samples `/proc`, `/sys`, `df`, `ps`, UPower and optional GPU tools, then exposes CPU/RAM/GPU/network/disk/battery histories plus a searchable process list.

Required extra packages: none.

Optional packages for richer GPU data:
- `pciutils`: GPU name via `lspci`.
- `nvtopPackages.nvidia` or NVIDIA driver tools: NVIDIA GPU usage and per-process VRAM via `nvidia-smi`.
- `radeontop`: fallback AMD GPU usage if sysfs is unavailable.
- `intel-gpu-tools`: fallback Intel GPU usage via `intel_gpu_top`; may need `CAP_PERFMON`.

Launch:
- Quickshell IPC: `qs ipc call systemMonitor toggle`
- Fallback command: `quickshell ipc call systemMonitor toggle`
- AppLauncher: search for `System Monitor`, `btop`, `process`, `ресурсы` or `процессы`.

Suggested Hyprland bind:

```ini
bind = SUPER SHIFT, M, exec, qs ipc call systemMonitor toggle
```
