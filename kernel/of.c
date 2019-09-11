#define pr_fmt(fmt)     __MODULE__ ": " fmt
#include <asm/page.h>
#include <sys/init.h>
#include <sys/memblock.h>
#include <sys/of.h>
#include "libfdt/libfdt.h"

#define OF_ROOT_NODE_ADDR_CELLS_DEFAULT 2
#define OF_ROOT_NODE_SIZE_CELLS_DEFAULT 1

static int dt_root_addr_cells;
static int dt_root_size_cells;

void *initial_boot_params;

static int __offset(const struct device_node *np)
{
        return (int)(uintptr_t)np;
}

static struct device_node *__node(int offset)
{
        if (offset <= 0)
                return NULL;
        return (void *)(uintptr_t)offset;
}

struct device_node *__of_find_all_nodes(struct device_node *prev)
{
        int r;

        r = fdt_next_node(initial_boot_params, __offset(prev), NULL);
        return __node(r);
}

struct device_node *of_find_node_by_path(const char *path)
{
        int r;

        r = fdt_path_offset(initial_boot_params, path);
        return __node(r);
}

struct device_node *of_find_compatible_node(struct device_node *from, const char *type, const char *compat)
{
        struct device_node *np;

        for_each_of_allnodes_from(from, np) {
                const char *prop = of_get_property(np, "compatible", NULL);

                if (prop && !strcmp(prop, compat))
                        break;
        }

        return np;
}

const void *of_get_property(const struct device_node *node, const char *name, int *lenp)
{
        return fdt_getprop(initial_boot_params, __offset(node), name, lenp);
}

int of_property_read_u32(const struct device_node *np, const char *propname, uint32_t *out_value)
{
        int r;
        const fdt32_t *data;

        data = of_get_property(np, propname, &r);
        if (!data)
                return r;

        *out_value = fdt32_to_cpu(*data);
        return 0;
}

int of_device_is_compatible(const struct device_node *node, const char *compat)
{
        return fdt_node_check_compatible(initial_boot_params, __offset(node), compat) == 0;
}

static struct device_node *get_parent(struct device_node *np)
{
        int r;

        r = fdt_parent_offset(initial_boot_params, __offset(np));
        return __node(r);
}

int of_n_addr_cells(struct device_node *np)
{
        uint32_t cells;
        struct device_node *parent;

        do {
                parent = get_parent(np);
                if (parent)
                        np = parent;
                if (!of_property_read_u32(np, "#address-cells", &cells))
                        return cells;
        } while (parent);

        /* No #address-cells property for the root node */
        return OF_ROOT_NODE_ADDR_CELLS_DEFAULT;
}

int of_n_size_cells(struct device_node *np)
{
        uint32_t cells;
        struct device_node *parent;

        do {
                parent = get_parent(np);
                if (parent)
                        np = parent;
                if (!of_property_read_u32(np, "#size-cells", &cells))
                        return cells;
        } while (parent);

        /* No #size-cells property for the root node */
        return OF_ROOT_NODE_SIZE_CELLS_DEFAULT;
}

/**
 * of_scan_flat_dt - scan flattened tree blob and call callback on each.
 * @it: callback function
 * @data: context data pointer
 *
 * This function is used to scan the flattened device-tree, it is
 * used to extract the memory information at boot before we can
 * unflatten the tree
 */
int of_scan_flat_dt(int (*it)(unsigned long node,
                              const char *uname, int depth,
                              void *data),
                    void *data)
{
        const void *blob = initial_boot_params;
        const char *pathp;
        int offset, rc = 0, depth = -1;

        if (!blob)
                return 0;

        for (offset = fdt_next_node(blob, -1, &depth);
             offset >= 0 && depth >= 0 && !rc;
             offset = fdt_next_node(blob, offset, &depth)) {

                pathp = fdt_get_name(blob, offset, NULL);
                if (*pathp == '/')
                        pathp = kbasename(pathp);
                rc = it(offset, pathp, depth, data);
        }
        return rc;
}

bool early_init_dt_verify(void *params)
{
        if (!params)
                return false;

        /* check device tree validity */
        if (fdt_check_header(params))
                return false;

        /* Setup flat device-tree pointer */
        initial_boot_params = params;
        return true;
}

/**
 * of_get_flat_dt_prop - Given a node in the flat blob, return the property ptr
 *
 * This function can be used within scan_flattened_dt callback to get
 * access to properties
 */
static const void *of_get_flat_dt_prop(unsigned long node, const char *name, int *size)
{
        return fdt_getprop(initial_boot_params, node, name, size);
}

int early_init_dt_scan_chosen(unsigned long node, const char *uname,
                              int depth, void *data)
{
        int l;
        const char *p;

        if (depth != 1 || !data ||
            (strcmp(uname, "chosen") != 0 && strcmp(uname, "chosen@0") != 0))
                return 0;

        /* retrieve command line */
        p = of_get_flat_dt_prop(node, "bootargs", &l);
        if (p && l > 0)
                strscpy(data, p, min((int)l, COMMAND_LINE_SIZE));

        /* break now */
        return 1;
}

/**
 * early_init_dt_scan_root - fetch the top level address and size cells
 */
static int early_init_dt_scan_root(unsigned long node, const char *uname,
                                   int depth, void *data)
{
        const be32_t *prop;

        if (depth != 0)
                return 0;

        dt_root_size_cells = OF_ROOT_NODE_SIZE_CELLS_DEFAULT;
        dt_root_addr_cells = OF_ROOT_NODE_ADDR_CELLS_DEFAULT;

        prop = of_get_flat_dt_prop(node, "#size-cells", NULL);
        if (prop)
                dt_root_size_cells = be32_to_cpup(prop);

        prop = of_get_flat_dt_prop(node, "#address-cells", NULL);
        if (prop)
                dt_root_addr_cells = be32_to_cpup(prop);

        /* break now */
        return 1;
}

static uint64_t dt_mem_next_cell(int s, const be32_t **cellp)
{
        const be32_t *p = *cellp;

        *cellp = p + s;
        return of_read_number(p, s);
}

/**
 * early_init_dt_scan_memory - Look for and parse memory nodes
 */
static int early_init_dt_scan_memory(unsigned long node, const char *uname,
                                     int depth, void *data)
{
        const char *type = of_get_flat_dt_prop(node, "device_type", NULL);
        const be32_t *reg, *endp;
        int l;

        /* We are scanning "memory" nodes only */
        if (!type || strcmp(type, "memory"))
                return 0;

        reg = of_get_flat_dt_prop(node, "linux,usable-memory", &l);
        if (reg == NULL)
                reg = of_get_flat_dt_prop(node, "reg", &l);
        if (reg == NULL)
                return 0;

        endp = reg + (l / sizeof(be32_t));

        pr_debug("memory scan node %s, reg size %d,\n", uname, l);

        while ((endp - reg) >= (dt_root_addr_cells + dt_root_size_cells)) {
                uint64_t base, size;

                base = dt_mem_next_cell(dt_root_addr_cells, &reg);
                size = dt_mem_next_cell(dt_root_size_cells, &reg);

                if (size == 0)
                        continue;
                pr_debug(" - %llx ,  %llx\n", (unsigned long long)base, (unsigned long long)size);

                memblock_add(base, size);
        }

        return 0;
}

void early_init_dt_scan_nodes(void)
{
        /* Retrieve various information from the /chosen node */
        of_scan_flat_dt(early_init_dt_scan_chosen, boot_command_line);

        /* Initialize {size,address}-cells info */
        of_scan_flat_dt(early_init_dt_scan_root, NULL);

        /* Setup memory */
        of_scan_flat_dt(early_init_dt_scan_memory, NULL);
}

bool early_init_dt_scan(void *params)
{
        bool status;

        status = early_init_dt_verify(params);
        if (!status)
                return false;

        early_init_dt_scan_nodes();
        return true;
}

void early_init_fdt_reserve_self(void)
{
        memblock_reserve(__pa(initial_boot_params), of_get_flat_dt_size());
}

int of_get_flat_dt_size(void)
{
        return fdt_totalsize(initial_boot_params);
}

void of_dt_move(void *buf, size_t size)
{
        int r;

        r = fdt_move(initial_boot_params, buf, size);
        if (r)
                panic("%s: %s\n", __FUNCTION__, fdt_strerror(r));
}
