# Win10-VFIO
Collection of scripts and tweaks for making a Windows 10 virtual machine run with QEMU/KVM/libvirt with GPU passthrough.

# Additional information
* Q35, PCIe configuration, physical SATA SSD given to the guest via SCSI passthrough
* Network "winbr0" created using nmcli on the host
* Kernel parameters: `intel_iommu=on iommu=pt transparent_hugepage=never nmi_watchdog=0 intremap=no_x2apic_optout rcu_nocbs=1-5,7-11 nohz_full=1-5,7-11 clocksource=tsc clock=tsc force_tsc_stable=1 vfio-pci.ids=10de:1b06,10de:10ef,8086:3e92 vfio-pci.disable_vga=1 module_blacklist=i915,nouveau pcie_acs_override=downstream efifb=off video=efifb:off`
* Using a custom version of [linux-vfio](https://aur.archlinux.org/packages/linux-vfio/) with `CONFIG_PREEMPT_VOLUNTARY=y` (fixes long boot time with UEFI guests) and the default 300 Hz tickrate
* [QEMU-Patched](https://aur.archlinux.org/packages/qemu-patched/) with PCIe bandwidth fix (see `pcie-enhanced-link-speed-and-width.patch` - NOTE: This is not the original one, this version only activates x8 mode, not x16, since that matches my physical topology; YMMV)
* Host is using an AMD RX 550, the guest an NVIDIA 1080 Ti
