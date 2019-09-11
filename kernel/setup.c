#include <asm/pgtable.h>
#include <sys/init.h>
#include <sys/sections.h>

unsigned long va_pa_offset;

pgd_t kernel_pgd[PTRS_PER_PGD] __aligned(PAGE_SIZE);

static pmd_t kernel_pmd[PTRS_PER_PMD * (KERNEL_VIRTUAL_SIZE / PGD_SIZE)] __aligned(PAGE_SIZE);

static pmd_t head_pmd[PTRS_PER_PMD] __aligned(PAGE_SIZE);
static pte_t head_pte[PTRS_PER_PTE] __aligned(PAGE_SIZE);

char boot_command_line[COMMAND_LINE_SIZE];

void setup_vm(void)
{
        size_t i;
        phys_addr_t pa = (phys_addr_t)_start;
        pgprot_t prot = PAGE_KERNEL_EXEC;

        BUILD_BUG_ON(KERNEL_VIRTUAL_START % PGD_SIZE);
        BUG_ON(pa % PMD_SIZE);

        va_pa_offset = KERNEL_VIRTUAL_START - pa;

        /* Identity mapping of 4k at kernel _start */
        kernel_pgd[pgd_index(pa)] = pfn_pgd(PFN_DOWN((phys_addr_t) head_pmd), __pgprot(_PAGE_TABLE));
        head_pmd[pmd_index(pa)] = pfn_pmd(PFN_DOWN((phys_addr_t) head_pte), __pgprot(_PAGE_TABLE));
        head_pte[pte_index(pa)] = pfn_pte(PFN_DOWN((phys_addr_t) pa), prot);

        for (i = 0; i < KERNEL_VIRTUAL_SIZE / PGD_SIZE; ++i) {
                kernel_pgd[pgd_index(KERNEL_VIRTUAL_START) + i] = pfn_pgd(
                        PFN_DOWN((phys_addr_t)kernel_pmd) + i,
                        __pgprot(_PAGE_TABLE));
        }
        for (i = 0; i < ARRAY_SIZE(kernel_pmd); i++)
                kernel_pmd[i] = pfn_pmd(PFN_DOWN(pa + i * PMD_SIZE), prot);
}
