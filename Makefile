MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# 先删除后复制，防止目标是软链接
define rmcp
	@rm -f $(2)
	@cp $(1) $(2)
endef

define mount_rootfs
	@mount -o bind /sys $(MAKEFILE_DIR)/rootfs/sys
	@mount -o bind /dev $(MAKEFILE_DIR)/rootfs/dev
	@mount -o bind /proc $(MAKEFILE_DIR)/rootfs/proc
	@mount --bind -o ro $(MAKEFILE_DIR)/gem5-base $(MAKEFILE_DIR)/rootfs/gem5  # Readonly mount
	@mount -o bind $(MAKEFILE_DIR)/workloads $(MAKEFILE_DIR)/rootfs/root
endef

define umount_rootfs
	-umount -l $(MAKEFILE_DIR)/rootfs/sys
	-umount -l $(MAKEFILE_DIR)/rootfs/proc
	-umount -l $(MAKEFILE_DIR)/rootfs/dev
	-umount -l $(MAKEFILE_DIR)/rootfs/gem5
	-umount -l $(MAKEFILE_DIR)/rootfs/root
endef

workload-dir:
	@mkdir -p $(MAKEFILE_DIR)/workloads

image: new-empty-img workload-dir
	$(call apply_rootfs_config)
	@mkdir -p $(MAKEFILE_DIR)/out
	@mkdir -p /tmp/fstoy-rootfs
	@rm -rf /tmp/fstoy-rootfs/*
	@$(MAKEFILE_DIR)/gem5-base/util/gem5img.py mount $(MAKEFILE_DIR)/out/rootfs.img /tmp/fstoy-rootfs
	@rm -rf /tmp/fstoy-rootfs/*
	@rsync -ar --info=progress2 --info=name0 $(MAKEFILE_DIR)/rootfs/ /tmp/fstoy-rootfs
	@rsync -ar --info=progress2 --info=name0 $(MAKEFILE_DIR)/gem5-base/ /tmp/fstoy-rootfs/gem5
	@rsync -ar --info=progress2 --info=name0 $(MAKEFILE_DIR)/workloads/ /tmp/fstoy-rootfs/root
	@echo "files copied"
	@$(MAKEFILE_DIR)/gem5-base/util/gem5img.py umount /tmp/fstoy-rootfs
	
new-empty-img:
	@rm -f $(MAKEFILE_DIR)/out/rootfs.img
	@mkdir -p out
	$(eval ROOTFS_SIZE := $(shell du -sc -BM rootfs workloads | tail -n 1 | cut -f1 -d'M'))
	$(eval IMAGE_SIZE := $(shell expr $(ROOTFS_SIZE) + 256))
	@echo "Image size: $(IMAGE_SIZE)M"
	$(MAKEFILE_DIR)/gem5-base/util/gem5img.py init $(MAKEFILE_DIR)/out/rootfs.img $(IMAGE_SIZE);

clean:
	@rm -rf out
	@echo "Images cleaned"

chroot: workload-dir
	$(call apply_rootfs_config)
	$(call mount_rootfs)
	-@SHELL=/bin/bash chroot $(MAKEFILE_DIR)/rootfs /bin/bash
	$(call umount_rootfs)

download-ubuntu22:
	@wget http://cdimage.ubuntu.com/ubuntu-base/releases/jammy/release/ubuntu-base-22.04-base-amd64.tar.gz -O /tmp/fstoy-ubuntu-base.tar.gz
download-ubuntu20:
	@wget http://cdimage.ubuntu.com/ubuntu-base/releases/focal/release/ubuntu-base-20.04.5-base-amd64.tar.gz -O /tmp/fstoy-ubuntu-base.tar.gz
download-ubuntu18:
	@wget http://cdimage.ubuntu.com/ubuntu-base/releases/bionic/release/ubuntu-base-18.04.5-base-amd64.tar.gz -O /tmp/fstoy-ubuntu-base.tar.gz
download-ubuntu16:
	@wget http://cdimage.ubuntu.com/ubuntu-base/releases/xenial/release/ubuntu-base-16.04.6-base-amd64.tar.gz -O /tmp/fstoy-ubuntu-base.tar.gz

define apply_rootfs_config
	$(call rmcp,/etc/resolv.conf,$(MAKEFILE_DIR)/rootfs/etc/resolv.conf)				# dns config
	$(call rmcp,$(MAKEFILE_DIR)/rootfs-config/hosts,$(MAKEFILE_DIR)/rootfs/etc/hosts)	# hosts
	$(call rmcp,$(MAKEFILE_DIR)/rootfs-config/fstab,$(MAKEFILE_DIR)/rootfs/etc/fstab) 	# fstab
	@ln -sf /gem5/util/m5/build/x86/out/m5 $(MAKEFILE_DIR)/rootfs/sbin/m5				# m5
	@mkdir -p $(MAKEFILE_DIR)/rootfs/gem5												# gem5 library
	$(call rmcp,$(MAKEFILE_DIR)/rootfs-config/init,$(MAKEFILE_DIR)/rootfs/sbin/init)	# init script
endef

init-ubuntu%: download-ubuntu% workload-dir
	@rm -rf $(MAKEFILE_DIR)/rootfs/*
	@mkdir -p $(MAKEFILE_DIR)/rootfs
	@tar -xzf /tmp/fstoy-ubuntu-base.tar.gz -C $(MAKEFILE_DIR)/rootfs
	@rm -f /tmp/fstoy-ubuntu-base.tar.gz
	$(call apply_rootfs_config)

download-kernel:
	@mkdir -p $(MAKEFILE_DIR)/kernels
	@wget http://dist.gem5.org/dist/v22-1/kernels/x86/static/vmlinux-5.4.49 -O $(MAKEFILE_DIR)/kernels/x86-vmlinux-5.4.49

env:
	@echo "export FSTOY_HOME=$(MAKEFILE_DIR)"

# 由于出错导致有残留的挂载点时，可以使用以下命令卸载
umount:
	$(call umount_rootfs)
	-$(MAKEFILE_DIR)/gem5-base/util/gem5img.py umount /tmp/fstoy-rootfs	# 针对 make image 的额外卸载

.PHONY: chroot clean image new-empty-img download-kernel init-ubuntu% env