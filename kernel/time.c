#define pr_fmt(fmt)     __MODULE__ ": " fmt
#include <sys/of.h>
#include <sys/timex.h>

static unsigned long cpu_khz;
static cycles_t boot_cycles;

useconds_t uptime(void)
{
        if (!cpu_khz)
                return 0;

        /*
	 * Subtract boot_cycles as QEMU returns the host CPU's
	 * cycles rather than starting from 0.  Also the value
         * from cpu_khz doesn't really make sense on QEMU, but
         * it's good enough for debugging.
         */
        return (get_cycles() - boot_cycles) * 1000 / cpu_khz;
}

void time_init(void)
{
        struct device_node *cpu;
        uint32_t prop;

        boot_cycles = get_cycles();

        cpu = of_find_node_by_path("/cpus/cpu");
        if (!cpu) {
                pr_warn("no 'cpu' in DTS\n");
                return;
        }

        if (of_property_read_u32(cpu, "clock-frequency", &prop)) {
                pr_warn("no 'clock-frequency' in DTS\n");
                return;
        }

        cpu_khz = prop / 1000;
}
