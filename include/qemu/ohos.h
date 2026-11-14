/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef QEMU_OHOS_H
#define QEMU_OHOS_H

/* OHOS JIT permission switch used by harmoninux/qemu. Keep errno intact:
 * the closing prctl must not hide a failed mmap/mprotect errno.
 */
#ifdef __OHOS__
#include <sys/prctl.h>
#define QEMU_PRCTL_SET_JITFORT 0x6a6974
#endif

static inline void qemu_ohos_jit_write_protect(bool enabled)
{
#ifdef __OHOS__
    int saved_errno = errno;
    prctl(QEMU_PRCTL_SET_JITFORT, 0, enabled ? 1 : 0);
    errno = saved_errno;
#endif
}

#endif
