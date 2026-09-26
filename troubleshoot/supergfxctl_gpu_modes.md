# Troubleshooting: ASUS ROG Laptop GPU Modes (`supergfxctl`)

## GPU Modes Overview
- **Integrated**: NVIDIA dGPU is fully powered off and disconnected from the PCIe bus. `nvidia-smi` showing no device is expected behavior.
- **Hybrid**: Dynamic runtime power management (Optimus). dGPU sleeps until invoked with `prime-run`.
- **Dedicated / AsusMuxDgpu**: Direct display connection to the NVIDIA GPU (requires reboot).
- **Vfio**: Dedicated for VM PCI-passthrough.

## Commands
```bash
# Check current GPU mode
supergfxctl -g

# Switch GPU mode (supported modes: Integrated, Hybrid, Dedicated, Vfio)
supergfxctl -m Hybrid

# Power Profiles Daemon cycling
# power-saver -> balanced -> performance
powerprofilesctl get
powerprofilesctl set performance
```
