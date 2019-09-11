#include <asm/entry.h>

        .section .text

# JITsynth jitk filters

ENTRY(jitsynth_jitk_qemu)
        .incbin "jitsynth/jitk/qemu.rv.bin"
END(jitsynth_jitk_qemu)

ENTRY(jitsynth_jitk_chrome)
        .incbin "jitsynth/jitk/chrome.rv.bin"
END(jitsynth_jitk_chrome)

ENTRY(jitsynth_jitk_firefox)
        .incbin "jitsynth/jitk/firefox.rv.bin"
END(jitsynth_jitk_firefox)

ENTRY(jitsynth_jitk_openssh)
        .incbin "jitsynth/jitk/openssh.rv.bin"
END(jitsynth_jitk_openssh)

ENTRY(jitsynth_jitk_tor)
        .incbin "jitsynth/jitk/tor.rv.bin"
END(jitsynth_jitk_tor)

ENTRY(jitsynth_jitk_vsftpd)
        .incbin "jitsynth/jitk/vsftpd.rv.bin"
END(jitsynth_jitk_vsftpd)

ENTRY(jitsynth_jitk_nacl)
        .incbin "jitsynth/jitk/nacl.rv.bin"
END(jitsynth_jitk_nacl)

# Linux JITK filters

ENTRY(linux_jitk_qemu)
        .incbin "linux/jitk/qemu.rv.bin"
END(linux_jitk_qemu)

ENTRY(linux_jitk_chrome)
        .incbin "linux/jitk/chrome.rv.bin"
END(linux_jitk_chrome)

ENTRY(linux_jitk_firefox)
        .incbin "linux/jitk/firefox.rv.bin"
END(linux_jitk_firefox)

ENTRY(linux_jitk_openssh)
        .incbin "linux/jitk/openssh.rv.bin"
END(linux_jitk_openssh)

ENTRY(linux_jitk_tor)
        .incbin "linux/jitk/tor.rv.bin"
END(linux_jitk_tor)

ENTRY(linux_jitk_vsftpd)
        .incbin "linux/jitk/vsftpd.rv.bin"
END(linux_jitk_vsftpd)

ENTRY(linux_jitk_nacl)
        .incbin "linux/jitk/nacl.rv.bin"
END(linux_jitk_nacl)