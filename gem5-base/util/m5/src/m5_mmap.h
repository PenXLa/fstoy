#ifndef __M5_MMAP_H__
#define __M5_MMAP_H__

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdint.h>

#ifndef M5OP_ADDR
#define M5OP_ADDR 0xFFFF0000
#endif

#ifdef __cplusplus
extern "C" {
#endif

extern void *m5_mem; // 这个不能少，会被 _addr 的实现用到

#define with_m5_mmap(block) \
    do { \
        const char *m5_mmap_dev = "/dev/mem"; \
        int fd; \
        fd = open(m5_mmap_dev, O_RDWR | O_SYNC); \
        if (fd == -1) { \
            fprintf(stderr, "Can't open %s: %s\n", m5_mmap_dev, strerror(errno)); \
            exit(1); \
        } \
        m5_mem = mmap(NULL, 0x10000, PROT_READ | PROT_WRITE, MAP_SHARED, fd, M5OP_ADDR); \
        close(fd); \
        if (!m5_mem) { \
            fprintf(stderr, "Can't map %s: %s\n", m5_mmap_dev, strerror(errno)); \
            exit(1); \
        } \
        block; \
        munmap(m5_mem, 0x10000); \
        m5_mem = NULL; \
    } while (0)


#endif

#ifdef __cplusplus
}
#endif