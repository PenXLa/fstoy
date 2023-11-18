MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

image: new-empty-img
	@mkdir -p $(MAKEFILE_DIR)/out
	@mkdir -p /tmp/fstoy-rootfs
	@rm -rf /tmp/fstoy-rootfs/*
	@$(MAKEFILE_DIR)/gem5-base/util/gem5img.py mount $(MAKEFILE_DIR)/out/rootfs.img /tmp/fstoy-rootfs
	@rm -rf /tmp/fstoy-rootfs/*
	@cp -r $(MAKEFILE_DIR)/rootfs/* /tmp/fstoy-rootfs
	@cp -r $(MAKEFILE_DIR)/gem5-base/* /tmp/fstoy-rootfs/gem5
	@cp -r $(MAKEFILE_DIR)/workloads/* /tmp/fstoy-rootfs/root
# init script
	@cp $(MAKEFILE_DIR)/rootfs-config/init /tmp/fstoy-rootfs/sbin/init
	@echo "files copied"
	@$(MAKEFILE_DIR)/gem5-base/util/gem5img.py umount /tmp/fstoy-rootfs
	
new-empty-img:
	@rm -f $(MAKEFILE_DIR)/out/rootfs.img
	@mkdir -p out
	$(eval ROOTFS_SIZE := $(shell du -sc -BM rootfs workloads | tail -n 1 | cut -f1 -d'M'))
	@if [ $(ROOTFS_SIZE) -lt 512 ]; then \
		$(MAKEFILE_DIR)/gem5-base/util/gem5img.py init $(MAKEFILE_DIR)/out/rootfs.img 1024; \
	elif [ $(ROOTFS_SIZE) -ge 512 ] && [ $(ROOTFS_SIZE) -lt 1800 ]; then \
		$(MAKEFILE_DIR)/gem5-base/util/gem5img.py init $(MAKEFILE_DIR)/out/rootfs.img 2048; \
	elif [ $(ROOTFS_SIZE) -ge 1800 ] && [ $(ROOTFS_SIZE) -lt 3800 ]; then \
		$(MAKEFILE_DIR)/gem5-base/util/gem5img.py init $(MAKEFILE_DIR)/out/rootfs.img 4096; \
	elif [ $(ROOTFS_SIZE) -ge 3800 ] && [ $(ROOTFS_SIZE) -lt 7800 ]; then \
		$(MAKEFILE_DIR)/gem5-base/util/gem5img.py init $(MAKEFILE_DIR)/out/rootfs.img 8192; \
	elif [ $(ROOTFS_SIZE) -ge 7800 ] && [ $(ROOTFS_SIZE) -lt 16000 ]; then \
		$(MAKEFILE_DIR)/gem5-base/util/gem5img.py init $(MAKEFILE_DIR)/out/rootfs.img 16384; \
	elif [ $(ROOTFS_SIZE) -ge 16000 ] && [ $(ROOTFS_SIZE) -lt 32000 ]; then \
		$(MAKEFILE_DIR)/gem5-base/util/gem5img.py init $(MAKEFILE_DIR)/out/rootfs.img 32768; \
	elif [ $(ROOTFS_SIZE) -ge 32000 ] && [ $(ROOTFS_SIZE) -lt 64000 ]; then \
		$(MAKEFILE_DIR)/gem5-base/util/gem5img.py init $(MAKEFILE_DIR)/out/rootfs.img 65536; \
	else \
		echo "Rootfs size exceeds 64G"; \
	fi

clean:
	@rm -rf out
	@echo "Images cleaned"

chroot:
	@mount -o bind /sys $(MAKEFILE_DIR)/rootfs/sys
	@mount -o bind /dev $(MAKEFILE_DIR)/rootfs/dev
	@mount -o bind /proc $(MAKEFILE_DIR)/rootfs/proc
	@mount --bind -o ro $(MAKEFILE_DIR)/gem5-base $(MAKEFILE_DIR)/rootfs/gem5  # Readonly mount
	@mount -o bind $(MAKEFILE_DIR)/workloads $(MAKEFILE_DIR)/rootfs/root
	-SHELL=/bin/bash chroot $(MAKEFILE_DIR)/rootfs /bin/bash
	-umount -l $(MAKEFILE_DIR)/rootfs/sys
	-umount -l $(MAKEFILE_DIR)/rootfs/proc
	-umount -l $(MAKEFILE_DIR)/rootfs/dev
	-umount -l $(MAKEFILE_DIR)/rootfs/gem5
	-umount -l $(MAKEFILE_DIR)/rootfs/root

init-ubuntu22:
# Download ubuntu 22.04 base image
	@rm -rf $(MAKEFILE_DIR)/rootfs/*
	@wget http://cdimage.ubuntu.com/ubuntu-base/releases/jammy/release/ubuntu-base-22.04-base-amd64.tar.gz -O /tmp/fstoy-ubuntu-base-22.04-base-amd64.tar.gz
	@mkdir -p $(MAKEFILE_DIR)/rootfs
	@tar -xzf /tmp/fstoy-ubuntu-base-22.04-base-amd64.tar.gz -C $(MAKEFILE_DIR)/rootfs
	@rm -f /tmp/fstoy-ubuntu-base-22.04-base-amd64.tar.gz
# dns config
	@cp /etc/resolv.conf $(MAKEFILE_DIR)/rootfs/etc/resolv.conf
# hosts
	@cp $(MAKEFILE_DIR)/rootfs-config/hosts $(MAKEFILE_DIR)/rootfs/etc/hosts
# fstab
	@cp $(MAKEFILE_DIR)/rootfs-config/fstab $(MAKEFILE_DIR)/rootfs/etc/fstab
# m5
	@ln -s /gem5/util/m5/build/x86/out/m5 $(MAKEFILE_DIR)/rootfs/sbin/m5
# gem5 library
	@mkdir -p $(MAKEFILE_DIR)/rootfs/gem5

download-kernel:
	@mkdir -p $(MAKEFILE_DIR)/kernels
	@wget http://dist.gem5.org/dist/v22-1/kernels/x86/static/vmlinux-5.4.49 -O $(MAKEFILE_DIR)/kernels/x86-vmlinux-5.4.49

env:
	@echo "export FSTOY_HOME=$(MAKEFILE_DIR)"

# 由于出错导致有残留的挂载点时，可以使用以下命令卸载
umount:
	-umount -l $(MAKEFILE_DIR)/rootfs/sys
	-umount -l $(MAKEFILE_DIR)/rootfs/proc
	-umount -l $(MAKEFILE_DIR)/rootfs/dev
	-umount -l $(MAKEFILE_DIR)/rootfs/gem5
	-umount -l $(MAKEFILE_DIR)/rootfs/root
	-$(MAKEFILE_DIR)/gem5-base/util/gem5img.py umount /tmp/fstoy-rootfs

.PHONY: chroot clean image new-empty-img download-kernel init-ubuntu22 env