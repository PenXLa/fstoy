# Intro
用于便捷地构建全系统镜像。

# Quick start
```bash
make init-ubuntu22
make download-kernel
```

* `rootfs` 是系统目录。
* `/sbin/init` 是初始化脚本
* `workload` 目录链接了 `rootfs/root` 目录，可以把 `workload` 放到这里

# 构建镜像
使用 `sudo make image` 构建镜像，镜像会输出到 `out/rootfs.img`

# 运行 gem5
然后使用 gem5 运行全系统，例如

```
build/X86/gem5.opt configs/fs-kvm.py --cmd="/root/hello" --disk-image $FSTOY_HOME/out/rootfs.img --kernel $FSTOY_HOME/kernels/x86-vmlinux-5.4.49
```

可以使用 `eval $(make env)` 来设置环境变量。

# m5ops
如果要调用 m5_mmap，可以直接使用下面头文件的 `with_m5_mmap` 宏。
```c++
#include "/.../fstoy/gem5-base/util/m5/src/m5_mmap.h"
```
如果要在 chroot 后在系统内部编译，可以
```c++
#include "/root/gem5/util/m5/src/m5_mmap.h"
```

# 其它
使用 `sudo make chroot` 可以切换到 `rootfs`。