#include <sys/console.h>
#include <sys/errno.h>
#include <sys/printk.h>
#include <sys/list.h>
#include <sys/spinlock.h>

#define LOG_LINE_MAX            1024

#define for_each_console(con)   \
        list_for_each_entry(con, &console_drivers, list)

static LIST_HEAD(console_drivers);
static int loglevel = LOGLEVEL_DEFAULT;
static int curlevel = LOGLEVEL_DEFAULT;

static DEFINE_SPINLOCK(console_lock);

void register_console(struct console *newcon)
{
        list_add_tail(&newcon->list, &console_drivers);
}

int console_getchar(void)
{
        struct console *con;

        for_each_console(con) {
                int r;

                if (!con->getchar)
                        continue;

                r = con->getchar(con);
                if (r >= 0)
                        return r;
        }

        return -EAGAIN;
}

void console_putchar(char c)
{
        struct console *con;

        for_each_console(con) {
                if (con->putchar) {
                        if (c == '\n')
                                con->putchar(con, '\r');
                        con->putchar(con, c);
                }
        }
}

void console_write(const char *s, size_t n)
{
        size_t i;

        for (i = 0; i < n; ++i)
                console_putchar(s[i]);
}

__weak size_t pr_timestamp(char *buf, size_t size)
{
        return 0;
}

__weak size_t pr_prefix(char *buf, size_t size)
{
        return 0;
}

__weak size_t pr_suffix(char *buf, size_t size)
{
        return 0;
}

int vprintk(int level, const char *fmt, va_list args)
{
        static char buf[LOG_LINE_MAX];
        int thislevel;
        size_t len = 0;

        thislevel = (level == LOGLEVEL_CONT) ? curlevel : level;
        curlevel = thislevel;

        if (thislevel > loglevel)
                goto done;

        len += pr_prefix(buf + len, sizeof(buf) - len);
        if (level != LOGLEVEL_CONT)
                len += pr_timestamp(buf + len, sizeof(buf) - len);
        len += vscnprintf(buf + len, sizeof(buf) - len, fmt, args);
        len += pr_suffix(buf + len, sizeof(buf) - len);

        console_write(buf, len);

done:
        return len;
}

int printk(int level, const char *fmt, ...)
{
        va_list args;
        int r;

        spin_lock(&console_lock);

        va_start(args, fmt);
        r = vprintk(level, fmt, args);
        va_end(args);

        spin_unlock(&console_lock);

        return r;
}
