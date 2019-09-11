#include <asm/setup.h>
#include <io/elf.h>
#include "user.h"

/* elf_table stores 32-bit offsets of files to the elf table */
extern uint32_t elf_table[NR_ELF_FILES];
extern char _start[];

noreturn void *load_elf(unsigned long fileid, void *start, uintptr_t stack_size)
{
        struct elf64_hdr *hdr;
        struct elf64_phdr *phdr;
        size_t i, n, quota;
        void *addr = start + stack_size, *end, *mid = addr;
        __attribute__((__noreturn__)) void (*func)(void *, void *, void *);

        printf("loading file %lu to %p...\n", fileid, addr);
        hdr = (void *)elf_table + elf_table[fileid];
        assert(!memcmp(hdr->e_ident, ELFMAG, SELFMAG));

        quota = sys_get_quota();
        end = start + quota * SZ_4K;

        phdr = (void *)hdr + hdr->e_phoff;
        n = hdr->e_phnum;
        for (i = 0; i < n; ++i, ++phdr) {
                uintptr_t va;
                size_t filesz, memsz;
                void *src, *dst;

                if (phdr->p_type != PT_LOAD)
                        continue;
                va = phdr->p_vaddr;
                filesz = phdr->p_filesz;
                memsz = phdr->p_memsz;
                assert(filesz <= memsz);
                assert(va + memsz >= va);

                src = (void *)hdr + phdr->p_offset;
                dst = addr + (va - KERNEL_VIRTUAL_START);
                assert(dst + filesz <= end);
                memcpy(dst, src, filesz);
                /* Don't clear bss - will allocate on-demand once paging is on. */
                if (dst + filesz > mid)
                        mid = dst + filesz;
        }

        func = addr + (hdr->e_entry - KERNEL_VIRTUAL_START);
        func(start, mid, end);
}
