# SPDX-License-Identifier: GPL-2.0
#
# Makefile for the Linux kernel device drivers.
#

obj-y				+= pci/

obj-y				+= video/

# IPMI must come before ACPI in order to provide IPMI opregion support
obj-y				+= char/ipmi/

obj-$(CONFIG_ACPI)		+= acpi/

# PnP must come after ACPI since it will eventually need to check if acpi
# was used and do nothing if so
obj-$(CONFIG_PNP)		+= pnp/

# Many drivers will want to use DMA so this has to be made available
# really early.
obj-$(CONFIG_DMADEVICES)	+= dma/


obj-y				+= virtio/

# tty/ comes before char/ so that the VT console is the boot-time
# default.
obj-y				+= tty/
obj-y				+= char/

# iommu/ comes before gpu as gpu are using iommu controllers
obj-y				+= iommu/

# gpu/ comes after char for AGP vs DRM startup and after iommu
obj-y				+= gpu/

# i810fb and intelfb depend on char/agp/
obj-$(CONFIG_FB_I810)           += video/fbdev/i810/
obj-$(CONFIG_FB_INTEL)          += video/fbdev/intelfb/

obj-y				+= base/ block/
obj-$(CONFIG_DMA_SHARED_BUFFER) += dma-buf/
obj-y				+= scsi/
obj-$(CONFIG_ATA)		+= ata/
obj-y				+= firewire/
obj-y				+= cdrom/
obj-$(CONFIG_PCCARD)		+= pcmcia/
obj-$(CONFIG_USB_PHY)		+= usb/
obj-$(CONFIG_USB)		+= usb/
obj-$(CONFIG_USB_SUPPORT)	+= usb/
obj-$(CONFIG_PCI)		+= usb/
obj-$(CONFIG_USB_GADGET)	+= usb/
obj-$(CONFIG_OF)		+= usb/
obj-$(CONFIG_SERIO)		+= input/serio/
obj-$(CONFIG_GAMEPORT)		+= input/gameport/
obj-$(CONFIG_INPUT)		+= input/
obj-$(CONFIG_RTC_LIB)		+= rtc/
obj-y				+= i2c/
obj-y				+= power/
obj-$(CONFIG_THERMAL)		+= thermal/
obj-$(CONFIG_MD)		+= md/
obj-$(CONFIG_CPU_FREQ)		+= cpufreq/
obj-$(CONFIG_CPU_IDLE)		+= cpuidle/
obj-y				+= firmware/
obj-y				+= clocksource/
obj-$(CONFIG_HID)		+= hid/
obj-y				+= platform/

obj-$(CONFIG_MAILBOX)		+= mailbox/

obj-$(CONFIG_NVMEM)		+= nvmem/
