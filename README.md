# Win10-VFIO
Collection of scripts and tweaks for making a Windows 10 virtual machine run with QEMU/KVM/libvirt with GPU passthrough.

System details at time of writing:
* Intel i7 8700k @ 4.8GHz
* 32 GB RAM

Runs fast enough for demanding VR titles :)

# Additional information
* Q35, PCIe configuration, physical SATA SSD given to the guest via SCSI passthrough (virtio)
* Network "winbr0" created using nmcli on the host
* Kernel parameters: `intel_iommu=on iommu=pt transparent_hugepage=never nmi_watchdog=0 intremap=no_x2apic_optout rcu_nocbs=1-5,7-11 nohz_full=1-5,7-11 clocksource=tsc clock=tsc force_tsc_stable=1 vfio-pci.ids=10de:1b06,10de:10ef,8086:3e92 vfio-pci.disable_vga=1 module_blacklist=i915,nouveau pcie_acs_override=downstream efifb=off video=efifb:off`
* Using a custom-built mainline linux (latest rc, if available) with `CONFIG_PREEMPT_VOLUNTARY=y` (fixes long boot time with UEFI guests), default tickrate, ZFS, WireGuard and some ClearLinux patches
* Latest Arch Linux qemu-headless
* Host is using an AMD RX 550, the guest an NVIDIA 2080 Ti
* USB via passed through USB3 on-board controller, the alternative "3.1" controller on my mainboard is left for the host (switching mouse/keyboard via physical USB switch, although I've had successes with evdev as well)
* Audio works via [Scream](https://github.com/duncanthrax/scream) (using IVSHMEM for best latency)
