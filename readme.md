# Intro
用于便捷地构建全系统镜像。

# Quick start
```bash
make init-ubuntu22
make download-kernel
```

* `rootfs` 是系统目录。
* `/sbin/init` 是初始化脚本
* `workload` 可以把 workload 放到这里。在 chroot 或构建镜像时，此目录会被映射到 `/root`
* `gem5-base` 放置了 m5op 相关的文件。其中，libm5 是支持 PIC 的。在 chroot 或构建镜像时，此目录会被映射到 `/gem5`

# 构建镜像
使用 `sudo make image` 构建镜像，镜像会输出到 `out/rootfs.img`

# 运行 gem5
然后使用 gem5 运行全系统，例如

```
build/X86/gem5.opt configs/fs-kvm.py --cmd="/root/hello" --disk-image $FSTOY_HOME/out/rootfs.img --kernel $FSTOY_HOME/kernels/x86-vmlinux-5.4.49
```

可以使用 `eval $(make env)` 来设置环境变量。

# m5ops
如果要调用 m5_mmap，可以直接使用下面头文件的 `with_m5_mmap` 宏。(chroot 后在系统内部编译)
```c++
#include "/gem5/util/m5/src/m5_mmap.h"
```

例如：
```c++
#include "/gem5/util/m5/src/m5_mmap.h"
#include "/gem5/include/gem5/m5ops.h"
using namespace std;

int main() {
	with_m5_mmap({    m5_switch_cpu_addr(); while(m5_iskvm_addr());   });
	m5_reset_stats(0, 0);

	for (int i=0; i<10000; ++i) {
		asm volatile("nop");
	}
	m5_exit(0);
	return 0;

}
```
```bash
g++ test.cpp -o test -L /gem5/util/m5/build/x86/out -lm5
```
在 `CMakeLists.txt` 里添加 `m5` 库：

```cmakelists
add_library(m5 STATIC IMPORTED)
set_target_properties(m5 PROPERTIES IMPORTED_LOCATION "/gem5/util/m5/build/x86/out/libm5.a")
target_link_libraries(Executable m5)
```



# 其它
使用 `sudo make chroot` 可以切换到 `rootfs`。

## QEMU
目前没有支持 QEMU。但是仍可以使用 out/rootfs.img 作为 QEMU 的启动镜像。一个例子：
```bash
qemu-system-x86_64 \
  -kernel /boot/vmlinuz \
  -append "root=/dev/sda1 rw console=ttyS0" \
  -drive file=out/rootfs.img,format=raw \
  -nographic \
  -enable-kvm
```
