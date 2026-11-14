/* SPDX-License-Identifier: GPL-2.0-or-later */
#include <stdbool.h>
#include <errno.h>
#include <stdarg.h>
#include "qemu/ohos.h"

static int calls;
int __wrap_prctl(int option, ...)
{
    if (option != QEMU_PRCTL_SET_JITFORT) {
        return -1;
    }
    calls++;
    errno = EACCES;
    return -1;
}

int main(void)
{
    errno = ENOMEM;
    qemu_ohos_jit_write_protect(false);
    if (errno != ENOMEM) {
        return 1;
    }
    errno = EINVAL;
    qemu_ohos_jit_write_protect(true);
    return errno != EINVAL || calls != 2;
}
