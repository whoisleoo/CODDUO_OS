#!/bin/bash

# SCRIPT DE INSTALAÇÃO DO CODDUO OS

echo "🔧 Corrigindo arquivo GRUB antes da instalação..."

cp grub/grub.cfg grub/grub.cfg.backup

# arruma o grub
cat > grub/grub.cfg << 'EOF'
# Load partition table and file system modules
insmod part_gpt
insmod part_msdos
insmod fat
insmod iso9660
insmod ntfs
insmod ntfscomp
insmod exfat
insmod udf

# Use graphics-mode output
if loadfont "${prefix}/fonts/unicode.pf2" ; then
    insmod all_video
    set gfxmode="auto"
    terminal_input console
    terminal_output console
fi

# Enable serial console
insmod serial
insmod usbserial_common
insmod usbserial_ftdi
insmod usbserial_pl2303
insmod usbserial_usbdebug
if serial --unit=0 --speed=115200; then
    terminal_input --append serial
    terminal_output --append serial
fi

# Get a human readable platform identifier
if [ "${grub_platform}" == 'efi' ]; then
    archiso_platform='UEFI'
    if [ "${grub_cpu}" == 'x86_64' ]; then
        archiso_platform="x64 ${archiso_platform}"
    elif [ "${grub_cpu}" == 'i386' ]; then
        archiso_platform="IA32 ${archiso_platform}"
    else
        archiso_platform="${grub_cpu} ${archiso_platform}"
    fi
elif [ "${grub_platform}" == 'pc' ]; then
    archiso_platform='BIOS'
else
    archiso_platform="${grub_cpu} ${grub_platform}"
fi

# Set default menu entry
default=codduo
timeout=15
timeout_style=menu


# Menu entries

menuentry "CODDUO OS install medium (%ARCH%, ${archiso_platform})" --class arch --class gnu-linux --class gnu --class os --id 'codduo' {
    set gfxpayload=keep
    linux /%INSTALL_DIR%/boot/%ARCH%/vmlinuz-linux archisobasedir=%INSTALL_DIR% archisolabel=%ARCHISO_LABEL% cow_spacesize=1G
    initrd /%INSTALL_DIR%/boot/%ARCH%/initramfs-linux.img
}

menuentry "CODDUO OS install medium with speakup screen reader (%ARCH%, ${archiso_platform})" --hotkey s --class arch --class gnu-linux --class gnu --class os --id 'codduo-accessibility' {
    set gfxpayload=keep
    linux /%INSTALL_DIR%/boot/%ARCH%/vmlinuz-linux archisobasedir=%INSTALL_DIR% archisolabel=%ARCHISO_LABEL% cow_spacesize=1G accessibility=on
    initrd /%INSTALL_DIR%/boot/%ARCH%/initramfs-linux.img
}

menuentry "CODDUO OS debug mode (%ARCH%, ${archiso_platform})" --hotkey d --class arch --class gnu-linux --class gnu --class os --id 'codduo-debug' {
    set gfxpayload=keep
    linux /%INSTALL_DIR%/boot/%ARCH%/vmlinuz-linux archisobasedir=%INSTALL_DIR% archisolabel=%ARCHISO_LABEL% cow_spacesize=1G debug loglevel=7 init=/usr/lib/systemd/systemd
    initrd /%INSTALL_DIR%/boot/%ARCH%/initramfs-linux.img
}


if [ "${grub_platform}" == 'efi' -a "${grub_cpu}" == 'x86_64' -a -f '/boot/memtest86+/memtest.efi' ]; then
    menuentry 'Run Memtest86+ (RAM test)' --class memtest86 --class memtest --class gnu --class tool {
        set gfxpayload=800x600,1024x768
        linux /boot/memtest86+/memtest.efi
    }
fi
if [ "${grub_platform}" == 'pc' -a -f '/boot/memtest86+/memtest' ]; then
    menuentry 'Run Memtest86+ (RAM test)' --class memtest86 --class memtest --class gnu --class tool {
        set gfxpayload=800x600,1024x768
        linux /boot/memtest86+/memtest
    }
fi
if [ "${grub_platform}" == 'efi' ]; then
    if [ "${grub_cpu}" == 'x86_64' -a -f '/shellx64.efi' ]; then
        menuentry 'UEFI Shell' --class efi {
            chainloader /shellx64.efi
        }
    elif [ "${grub_cpu}" == "i386" -a -f '/shellia32.efi' ]; then
        menuentry 'UEFI Shell' --class efi {
            chainloader /shellia32.efi
        }
    fi

    menuentry 'UEFI Firmware Settings' --id 'uefi-firmware' {
        fwsetup
    }
fi

menuentry 'System shutdown' --class shutdown --class poweroff {
    echo 'System shutting down...'
    halt
}

menuentry 'System restart' --class reboot --class restart {
    echo 'System rebooting...'
    reboot
}


# GRUB init tune for accessibility
play 600 988 1 1319 4
EOF

echo "✅ Arquivo GRUB corrigido! prosseguindo para instalação..."


echo "Gerando ISO... (Processo pode demorar até 25+ minutos)"
sudo mkarchiso -v -w /tmp/archiso-tmp -o out/ ./
