/*
 * legacy_log_parser_fixed.c  --  Task 3 (CSCE 465/765 HW3)
 *
 * Fixed + hardened version of legacy_log_parser.c.
 *
 * ROOT-CAUSE FIX
 *   The original copied up to MAX_READ (512) bytes into a 128-byte stack
 *   buffer with memcpy() and no length check, so an oversized file
 *   overwrote the saved return address (the ret2win bug).  Here, safe_copy()
 *   refuses any input larger than the destination buffer BEFORE copying, so
 *   the copy is only ever reached with n <= BUF_SIZE and the saved return
 *   address can never be reached by the input.  That single check is the fix.
 *
 * DEFENSE-IN-DEPTH (compiler/linker, applied in the build command)
 *   -fstack-protector-strong  stack canary
 *   -D_FORTIFY_SOURCE=3       bounds-checked libc (turns memcpy into
 *                             __memcpy_chk at -O2)
 *   -fPIE -pie                ASLR for code addresses
 *   -Wl,-z,relro,-z,now       Full RELRO
 *   -Wl,-z,noexecstack        non-executable stack
 *   -Werror                   warnings are build failures
 *
 * Build:
 *   gcc -O2 -g -fstack-protector-strong -D_FORTIFY_SOURCE=3 \
 *       -fPIE -pie -Wl,-z,relro,-z,now -Wl,-z,noexecstack \
 *       -Wall -Wextra -Werror \
 *       -o legacy_log_parser_fixed legacy_log_parser_fixed.c
 */

#define _GNU_SOURCE          /* for realpath() */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUF_SIZE 128         /* the fixed stack buffer */
#define MAX_READ 512         /* we still *read* up to this, but reject >BUF_SIZE */

/*
 * The directory the parser is allowed to read from. Override at build time
 * with -DINBOX_DIR='"..."' if your checkout lives elsewhere; the default
 * matches the layout used by the rest of this submission.
 */
#ifndef INBOX_DIR
#define INBOX_DIR "/home/ubuntu/csce465-agentsec/465_HW3/inbox/"
#endif

/*
 * win() is kept ONLY so we can demonstrate that, although the ret2win target
 * still exists in the fixed binary, the overflow can no longer reach it.
 * It is never called. (Left with external linkage so -Wunused-function does
 * not fire under -Werror.)
 */
void win(void);
void win(void)
{
    FILE *mark = fopen("markers/ret2win.txt", "w");
    if (mark) {
        fprintf(mark, "Marker created\n");
        fclose(mark);
    }
}

/*
 * The root-cause fix: reject anything that would not fit, before copying.
 * Returns 0 on success, -1 if the input was rejected.
 */
static int safe_copy(char *buf, size_t buf_size,
                     const unsigned char *input, size_t n)
{
    if (n > buf_size) {
        fprintf(stderr,
                "Rejected: input of %zu bytes exceeds the %zu-byte buffer\n",
                n, buf_size);
        return -1;
    }
    memcpy(buf, input, n);
    return 0;
}

static void parse_log(const char *path)
{
    char buf[BUF_SIZE];

    /* Resolve the path and confine it to the inbox (access-control boundary). */
    char *full_path = realpath(path, NULL);
    if (full_path == NULL) {
        perror("realpath");                 /* also covers the missing-file case */
        return;
    }
    if (strncmp(full_path, INBOX_DIR, strlen(INBOX_DIR)) != 0) {
        fprintf(stderr, "Rejected: file must be under %s\n", INBOX_DIR);
        free(full_path);
        return;
    }

    FILE *fp = fopen(full_path, "rb");
    free(full_path);
    if (fp == NULL) {
        perror("fopen");
        return;
    }

    unsigned char *heap = malloc(MAX_READ);
    if (heap == NULL) {
        perror("malloc");
        fclose(fp);
        return;
    }

    size_t n = fread(heap, 1, MAX_READ, fp);
    fclose(fp);

    if (safe_copy(buf, BUF_SIZE, heap, n) == 0) {
        /* Normal behaviour: print the beginning of the log and return. */
        int shown = (int)(n < 64 ? n : 64);
        printf("OK: read %zu byte(s). Log begins: %.*s\n", n, shown, buf);
    }

    free(heap);
}

int main(int argc, char *argv[])
{
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <path under inbox/>\n", argv[0]);
        return 1;
    }
    parse_log(argv[1]);
    return 0;
}
