#!/bin/bash

# CODDUO OS - Script de Instalação
# Cores para interface
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' 


show_banner() {
    clear
    echo -e "${PURPLE}"
    echo "  ██████╗ ██████╗ ██████╗ ██████╗ ██╗   ██╗ ██████╗ "
    echo " ██╔════╝██╔═══██╗██╔══██╗██╔══██╗██║   ██║██╔═══██╗"
    echo " ██║     ██║   ██║██║  ██║██║  ██║██║   ██║██║   ██║"
    echo " ██║     ██║   ██║██║  ██║██║  ██║██║   ██║██║   ██║"
    echo " ╚██████╗╚██████╔╝██████╔╝██████╔╝╚██████╔╝╚██████╔╝"
    echo "  ╚═════╝ ╚═════╝ ╚═════╝ ╚═════╝  ╚═════╝  ╚═════╝ "
    echo -e "${NC}"
    echo -e "${CYAN}        Sistema Minimalista para Baixo Consumo${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}


log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCESSO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

# Função para pausar e aguardar input
pause() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Pressione Enter para continuar..."
}

# Verificação se está rodando como root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Este script deve ser executado como root"
        exit 1
    fi
}

# Função para listar discos disponíveis
list_disks() {
    log_info "Discos disponíveis:"
    echo ""
    lsblk -d -o NAME,SIZE,TYPE,MODEL | grep -E "disk"
    echo ""
}

# Função para selecionar disco de instalação
select_disk() {
    while true; do
        list_disks
        echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        read -p "Digite o nome do disco (ex: sda, nvme0n1): " DISK
        
        if [ -b "/dev/$DISK" ]; then
            DISK_PATH="/dev/$DISK"
            log_success "Disco selecionado: $DISK_PATH"
            
            # Mostrar informações do disco
            echo ""
            log_info "Informações do disco:"
            lsblk "$DISK_PATH"
            echo ""
            
            read -p "Confirma a instalação neste disco? (s/N): " confirm
            if [[ $confirm == [sS] ]]; then
                break
            fi
        else
            log_error "Disco não encontrado: /dev/$DISK"
        fi
    done
}

# Função para criar usuário
create_user() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log_info "Configuração do usuário padrão"
    
    while true; do
        read -p "Nome do usuário (padrão: codduo): " USERNAME
        USERNAME=${USERNAME:-codduo}
        
        if [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
            break
        else
            log_error "Nome de usuário inválido. Use apenas letras minúsculas, números e _-"
        fi
    done
    
    while true; do
        read -s -p "Senha para o usuário $USERNAME: " USER_PASSWORD
        echo ""
        read -s -p "Confirme a senha: " USER_PASSWORD_CONFIRM
        echo ""
        
        if [ "$USER_PASSWORD" = "$USER_PASSWORD_CONFIRM" ]; then
            break
        else
            log_error "Senhas não coincidem. Tente novamente."
        fi
    done
    
    while true; do
        read -s -p "Senha para o usuário root: " ROOT_PASSWORD
        echo ""
        read -s -p "Confirme a senha do root: " ROOT_PASSWORD_CONFIRM
        echo ""
        
        if [ "$ROOT_PASSWORD" = "$ROOT_PASSWORD_CONFIRM" ]; then
            break
        else
            log_error "Senhas não coincidem. Tente novamente."
        fi
    done
}

# Função para detectar nomenclatura de partições
get_partition_name() {
    local disk="$1"
    local partition_num="$2"
    
    if [[ "$disk" == *"nvme"* ]] || [[ "$disk" == *"mmc"* ]]; then
        echo "${disk}p${partition_num}"
    else
        echo "${disk}${partition_num}"
    fi
}

# Função para particionar disco
partition_disk() {
    log_info "Particionando disco $DISK_PATH..."
    
    # Detectar se o sistema suporta UEFI
    if [ -d "/sys/firmware/efi/efivars" ]; then
        UEFI_MODE=true
        log_info "Sistema UEFI detectado"
    else
        UEFI_MODE=false
        log_info "Sistema BIOS detectado"
    fi
    
    # Limpar disco completamente
    log_info "Limpando disco..."
    wipefs -a "$DISK_PATH"
    sgdisk --zap-all "$DISK_PATH" 2>/dev/null || true
    
    if [ "$UEFI_MODE" = true ]; then
        # Particionamento UEFI com GPT
        log_info "Criando tabela de partições GPT..."
        parted -s "$DISK_PATH" mklabel gpt
        
        # Partição EFI (1GB para compatibilidade)
        log_info "Criando partição EFI..."
        parted -s "$DISK_PATH" mkpart primary fat32 1MiB 1025MiB
        parted -s "$DISK_PATH" set 1 esp on
        
        # Partição Swap (4GB)
        log_info "Criando partição Swap..."
        parted -s "$DISK_PATH" mkpart primary linux-swap 1025MiB 5GiB
        
        # Partição Root (resto do disco)
        log_info "Criando partição Root..."
        parted -s "$DISK_PATH" mkpart primary ext4 5GiB 100%
        
        # Definir nomes das partições
        EFI_PARTITION=$(get_partition_name "$DISK_PATH" 1)
        SWAP_PARTITION=$(get_partition_name "$DISK_PATH" 2)
        ROOT_PARTITION=$(get_partition_name "$DISK_PATH" 3)
    else
        # Particionamento BIOS com MBR
        log_info "Criando tabela de partições MBR..."
        parted -s "$DISK_PATH" mklabel msdos
        
        # Partição Swap (4GB)
        log_info "Criando partição Swap..."
        parted -s "$DISK_PATH" mkpart primary linux-swap 1MiB 4GiB
        
        # Partição Root (resto do disco)
        log_info "Criando partição Root..."
        parted -s "$DISK_PATH" mkpart primary ext4 4GiB 100%
        parted -s "$DISK_PATH" set 2 boot on
        
        # Definir nomes das partições
        SWAP_PARTITION=$(get_partition_name "$DISK_PATH" 1)
        ROOT_PARTITION=$(get_partition_name "$DISK_PATH" 2)
    fi
    
    # Aguardar sincronização das partições
    log_info "Sincronizando partições..."
    sleep 3
    partprobe "$DISK_PATH"
    sleep 3
    
    # Verificar se as partições foram criadas
    if [ "$UEFI_MODE" = true ]; then
        if [ ! -b "$EFI_PARTITION" ] || [ ! -b "$SWAP_PARTITION" ] || [ ! -b "$ROOT_PARTITION" ]; then
            log_error "Falha ao criar partições. Verifique o disco."
            exit 1
        fi
        log_success "Partições criadas: EFI=$EFI_PARTITION, SWAP=$SWAP_PARTITION, ROOT=$ROOT_PARTITION"
    else
        if [ ! -b "$SWAP_PARTITION" ] || [ ! -b "$ROOT_PARTITION" ]; then
            log_error "Falha ao criar partições. Verifique o disco."
            exit 1
        fi
        log_success "Partições criadas: SWAP=$SWAP_PARTITION, ROOT=$ROOT_PARTITION"
    fi
}

# Função para formatar partições
format_partitions() {
    log_info "Formatando partições..."
    
    # Formatar partição swap
    log_info "Formatando partição swap: $SWAP_PARTITION"
    mkswap "$SWAP_PARTITION"
    if [ $? -ne 0 ]; then
        log_error "Falha ao formatar partição swap"
        exit 1
    fi
    swapon "$SWAP_PARTITION"
    
    # Formatar partição root
    log_info "Formatando partição root: $ROOT_PARTITION"
    mkfs.ext4 -F "$ROOT_PARTITION"
    if [ $? -ne 0 ]; then
        log_error "Falha ao formatar partição root"
        exit 1
    fi
    
    if [ "$UEFI_MODE" = true ]; then
        # Formatar partição EFI
        log_info "Formatando partição EFI: $EFI_PARTITION"
        mkfs.fat -F32 "$EFI_PARTITION"
        if [ $? -ne 0 ]; then
            log_error "Falha ao formatar partição EFI"
            exit 1
        fi
    fi
    
    log_success "Partições formatadas com sucesso"
}

# Função para montar partições
mount_partitions() {
    log_info "Montando partições..."
    
    # Montar partição root
    log_info "Montando partição root: $ROOT_PARTITION"
    mount "$ROOT_PARTITION" /mnt
    if [ $? -ne 0 ]; then
        log_error "Falha ao montar partição root"
        exit 1
    fi
    
    if [ "$UEFI_MODE" = true ]; then
        # Criar e montar partição EFI
        log_info "Criando diretório /mnt/boot/efi"
        mkdir -p /mnt/boot/efi
        
        log_info "Montando partição EFI: $EFI_PARTITION"
        mount "$EFI_PARTITION" /mnt/boot/efi
        if [ $? -ne 0 ]; then
            log_error "Falha ao montar partição EFI"
            exit 1
        fi
        
        # Verificar se a partição EFI foi montada corretamente
        if ! mountpoint -q /mnt/boot/efi; then
            log_error "Partição EFI não foi montada corretamente"
            exit 1
        fi
    fi
    
    log_success "Partições montadas com sucesso"
}

# Função para instalar sistema base
install_base() {
    log_info "Instalando sistema base..."
    
    # Configurar mirrors
    reflector --country Brazil --age 24 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    
    # Instalar sistema base
    pacstrap /mnt base base-devel linux linux-firmware
    
    # Gerar fstab
    genfstab -U /mnt >> /mnt/etc/fstab
    
    log_success "Sistema base instalado"
}

# Função para configurar sistema
configure_system() {
    log_info "Configurando sistema..."
    
    # Configurar timezone
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
    arch-chroot /mnt hwclock --systohc
    
    # Configurar locale
    echo "pt_BR.UTF-8 UTF-8" > /mnt/etc/locale.gen
    echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen
    echo "LANG=pt_BR.UTF-8" > /mnt/etc/locale.conf
    
    # Configurar teclado
    echo "KEYMAP=br-abnt2" > /mnt/etc/vconsole.conf
    
    # Configurar hostname
    echo "codduo-os" > /mnt/etc/hostname
    
    # Configurar hosts
    cat > /mnt/etc/hosts << EOF
127.0.0.1    localhost
::1          localhost
127.0.1.1    codduo-os.localdomain codduo-os
EOF
    
    log_success "Sistema configurado"
}

# Função para instalar pacotes necessários
install_packages() {
    log_info "Instalando pacotes necessários..."
    
    arch-chroot /mnt pacman -S --noconfirm \
        networkmanager \
        wget \
        curl \
        vim \
        git \
        htop \
        sudo \
        python \
        python-pip \
        npm \
        firefox \
        grub \
        efibootmgr \
        dosfstools \
        os-prober \
        mtools \
        xorg-server \
        xorg-xinit \
        xorg-xauth \
        xorg-apps \
        xorg-xkbutils \
        xterm \
        libdrm \
        libpciaccess \
        libxshmfence \
        fastfetch
    
    log_success "Pacotes instalados"
}

# Função para configurar usuários
setup_users() {
    log_info "Configurando usuários..."
    
    # Configurar senha do root
    echo "root:$ROOT_PASSWORD" | arch-chroot /mnt chpasswd
    
    # Criar usuário
    arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$USERNAME"
    echo "$USERNAME:$USER_PASSWORD" | arch-chroot /mnt chpasswd
    
    # Configurar sudo
    echo "%wheel ALL=(ALL) ALL" >> /mnt/etc/sudoers
    
    log_success "Usuários configurados"
}

# Função para configurar serviços
setup_services() {
    log_info "Configurando serviços..."
    
    # Habilitar NetworkManager
    arch-chroot /mnt systemctl enable NetworkManager
    
    log_success "Serviços configurados"
}

# Função para configurar X.Org
setup_xorg() {
    log_info "Configurando X.Org..."
    
    # Criar diretório de configurações do X.Org
    arch-chroot /mnt mkdir -p /etc/X11/xorg.conf.d
    
    # Configurar teclado para X.Org
    cat > /mnt/etc/X11/xorg.conf.d/10-keyboard.conf << 'EOF'
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "br"
        Option "XkbModel" "abnt2"
        Option "XkbVariant" ""
        Option "XkbOptions" "terminate:ctrl_alt_bksp"
EndSection
EOF
    
    # Configurar servidor X
    cat > /mnt/etc/X11/xorg.conf.d/00-server.conf << 'EOF'
Section "ServerFlags"
    Option "DontZap" "false"
EndSection

Section "Module"
    Load "dbe"
    Load "extmod"
    Load "glx"
EndSection
EOF
    
    # Configurar teclado ABNT2 para X11
    arch-chroot /mnt localectl set-x11-keymap br abnt2
    
    # Executar ldconfig para recarregar bibliotecas
    arch-chroot /mnt ldconfig
    
    log_success "X.Org configurado"
}

# Função para configurar sistema CODDUO-OS
setup_codduo_system() {
    log_info "Configurando sistema CODDUO-OS..."
    
    # Copiar script do menu para o sistema
    log_info "Instalando menu CODDUO-OS..."
    cp /root/codduo-menu.sh /mnt/usr/local/bin/codduo-menu
    chmod +x /mnt/usr/local/bin/codduo-menu
    
    # Copiar launcher para execução manual
    cp /root/codduo-launcher.sh /mnt/usr/local/bin/codduo
    chmod +x /mnt/usr/local/bin/codduo
    
    # Copiar documentação
    cp /root/README-CODDUO.md /mnt/home/$USERNAME/README-CODDUO.md
    arch-chroot /mnt chown $USERNAME:$USERNAME /home/$USERNAME/README-CODDUO.md
    
    # Configurar fastfetch
    arch-chroot /mnt mkdir -p /home/$USERNAME/.config/fastfetch
    cp -r /etc/skel/.config/fastfetch/* /mnt/home/$USERNAME/.config/fastfetch/
    arch-chroot /mnt chown -R $USERNAME:$USERNAME /home/$USERNAME/.config
    
    # Criar diretórios do sistema CODDUO-OS
    arch-chroot /mnt mkdir -p /opt/codduo/{apps,config,data,logs}
    
    # Configurar o menu para executar automaticamente no login
    log_info "Configurando auto-execução do menu..."
    
    # Adicionar ao .bashrc do usuário
    cat >> /mnt/home/$USERNAME/.bashrc << 'EOF'

# Auto-executar menu CODDUO-OS
if [ -n "$PS1" ] && [ -z "$CODDUO_MENU_LOADED" ]; then
    export CODDUO_MENU_LOADED=1
    clear
    echo "Iniciando CODDUO-OS..."
    sleep 1
    /usr/local/bin/codduo-menu
fi
EOF
    
    # Adicionar ao .bash_profile do usuário para garantir execução
    cat >> /mnt/home/$USERNAME/.bash_profile << 'EOF'

# Auto-executar menu CODDUO-OS
if [ -n "$PS1" ] && [ -z "$CODDUO_MENU_LOADED" ]; then
    export CODDUO_MENU_LOADED=1
    clear
    echo "Iniciando CODDUO-OS..."
    sleep 1
    /usr/local/bin/codduo-menu
fi
EOF
    
    # Configurar permissões
    arch-chroot /mnt chown -R $USERNAME:$USERNAME /opt/codduo
    arch-chroot /mnt chown $USERNAME:$USERNAME /home/$USERNAME/.bashrc
    arch-chroot /mnt chown $USERNAME:$USERNAME /home/$USERNAME/.bash_profile
    
    # Criar arquivo de identificação do sistema
    echo "CODDUO-OS v1.0" > /mnt/etc/codduo-release
    echo "Sistema instalado em: $(date)" >> /mnt/etc/codduo-release
    echo "Usuário: $USERNAME" >> /mnt/etc/codduo-release
    
    # Personalizar MOTD
    cat > /mnt/etc/motd << 'EOF'

  ██████╗ ██████╗ ██████╗ ██████╗ ██╗   ██╗ ██████╗ 
 ██╔════╝██╔═══██╗██╔══██╗██╔══██╗██║   ██║██╔═══██╗
 ██║     ██║   ██║██║  ██║██║  ██║██║   ██║██║   ██║
 ██║     ██║   ██║██║  ██║██║  ██║██║   ██║██║   ██║
 ╚██████╗╚██████╔╝██████╔╝██████╔╝╚██████╔╝╚██████╔╝
  ╚═════╝ ╚═════╝ ╚═════╝ ╚═════╝  ╚═════╝  ╚═════╝ 

        Sistema Operacional Minimalista v1.0
        Desenvolvido para máxima simplicidade e performance
        
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
    
    log_success "Sistema CODDUO-OS configurado"
}

# Função para instalar e configurar bootloader
install_bootloader() {
    log_info "Instalando bootloader..."
    
    if [ "$UEFI_MODE" = true ]; then
        # Verificar se a partição EFI está montada
        if ! mountpoint -q /mnt/boot/efi; then
            log_error "Partição EFI não está montada em /mnt/boot/efi"
            exit 1
        fi
        
        # Instalar GRUB para UEFI
        log_info "Instalando GRUB para UEFI..."
        arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=CODDUO_OS --removable
        
        # Verificar se a instalação foi bem-sucedida
        if [ $? -ne 0 ]; then
            log_error "Falha na instalação do GRUB UEFI"
            exit 1
        fi
        
        # Verificar se os arquivos EFI foram criados
        if [ ! -f "/mnt/boot/efi/EFI/BOOT/BOOTX64.EFI" ] && [ ! -f "/mnt/boot/efi/EFI/CODDUO_OS/grubx64.efi" ]; then
            log_warning "Arquivos EFI não encontrados. Tentando instalação alternativa..."
            arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=BOOT --removable --force
        fi
        
        # Verificar entradas UEFI
        log_info "Verificando entradas UEFI..."
        arch-chroot /mnt efibootmgr -v | grep -i codduo || log_warning "Entrada UEFI não encontrada"
        
    else
        # Instalar GRUB para BIOS
        log_info "Instalando GRUB para BIOS..."
        arch-chroot /mnt grub-install --target=i386-pc "$DISK_PATH"
        
        # Verificar se a instalação foi bem-sucedida
        if [ $? -ne 0 ]; then
            log_error "Falha na instalação do GRUB BIOS"
            exit 1
        fi
    fi
    
    # Configurar GRUB
    log_info "Configurando GRUB..."
    
    # Configurações do GRUB
    cat > /mnt/etc/default/grub << 'EOF'
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="CODDUO_OS"
GRUB_CMDLINE_LINUX_DEFAULT="quiet"
GRUB_CMDLINE_LINUX=""
GRUB_PRELOAD_MODULES="part_gpt part_msdos"
GRUB_DISABLE_RECOVERY="true"
GRUB_GFXMODE=auto
GRUB_GFXPAYLOAD_LINUX=keep
EOF
    
    # Gerar configuração do GRUB
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    
    # Verificar se o arquivo de configuração foi criado
    if [ ! -f "/mnt/boot/grub/grub.cfg" ]; then
        log_error "Falha ao gerar configuração do GRUB"
        exit 1
    fi
    
    log_success "Bootloader instalado e configurado"
}

# Função para verificar instalação
verify_installation() {
    log_info "Verificando instalação..."
    
    # Verificar se o kernel foi instalado
    if [ ! -f "/mnt/boot/vmlinuz-linux" ]; then
        log_error "Kernel não encontrado em /mnt/boot/vmlinuz-linux"
        return 1
    fi
    
    # Verificar se o initramfs foi gerado
    if [ ! -f "/mnt/boot/initramfs-linux.img" ]; then
        log_error "Initramfs não encontrado em /mnt/boot/initramfs-linux.img"
        return 1
    fi
    
    # Verificar se o GRUB foi instalado
    if [ ! -f "/mnt/boot/grub/grub.cfg" ]; then
        log_error "Configuração do GRUB não encontrada"
        return 1
    fi
    
    # Verificar se o usuário foi criado
    if ! arch-chroot /mnt id "$USERNAME" &>/dev/null; then
        log_error "Usuário $USERNAME não foi criado"
        return 1
    fi
    
    # Verificar fstab
    if [ ! -s "/mnt/etc/fstab" ]; then
        log_error "Arquivo fstab vazio ou não encontrado"
        return 1
    fi
    
    log_success "Verificação da instalação concluída"
    return 0
}

# Função para finalizar instalação
finalize_installation() {
    log_info "Finalizando instalação..."
    
    # Verificar instalação antes de finalizar
    if ! verify_installation; then
        log_error "Instalação não passou na verificação"
        log_info "Verificando logs para diagnóstico..."
        echo "Conteúdo de /mnt/boot:"
        ls -la /mnt/boot/ || true
        if [ "$UEFI_MODE" = true ]; then
            echo "Conteúdo de /mnt/boot/efi/EFI:"
            ls -la /mnt/boot/efi/EFI/ || true
        fi
        read -p "Deseja continuar mesmo assim? (s/N): " force_continue
        if [[ $force_continue != [sS] ]]; then
            exit 1
        fi
    fi
    
    # Desmontar partições
    log_info "Desmontando partições..."
    sync
    umount -R /mnt
    
    log_success "Instalação concluída com sucesso!"
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}CODDUO OS foi instalado com sucesso!${NC}"
    echo -e "${CYAN}Sistema: ${NC}CODDUO OS"
    echo -e "${CYAN}Usuário: ${NC}$USERNAME"
    echo -e "${CYAN}Disco: ${NC}$DISK_PATH"
    echo -e "${CYAN}Modo: ${NC}$([ "$UEFI_MODE" = true ] && echo "UEFI" || echo "BIOS")"
    if [ "$UEFI_MODE" = true ]; then
        echo -e "${CYAN}Partições: ${NC}EFI=$EFI_PARTITION, SWAP=$SWAP_PARTITION, ROOT=$ROOT_PARTITION"
    else
        echo -e "${CYAN}Partições: ${NC}SWAP=$SWAP_PARTITION, ROOT=$ROOT_PARTITION"
    fi
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}IMPORTANTE: Remova a mídia de instalação e reinicie o sistema.${NC}"
    echo -e "${YELLOW}O sistema deve inicializar diretamente no GRUB.${NC}"
    echo ""
    read -p "Deseja reiniciar agora? (s/N): " reboot_now
    if [[ $reboot_now == [sS] ]]; then
        reboot
    fi
}

# Função principal
main() {
    show_banner
    
    log_info "Iniciando instalação do CODDUO OS..."
    pause
    
    check_root
    
    # Verificar conexão de internet
    if ! ping -c 1 google.com &> /dev/null; then
        log_error "Sem conexão com a internet. Verifique sua conexão e tente novamente."
        exit 1
    fi
    
    # Etapas da instalação
    select_disk
    create_user
    pause
    
    log_info "Iniciando particionamento e instalação..."
    partition_disk
    format_partitions
    mount_partitions
    install_base
    configure_system
    install_packages
    setup_users
    setup_services
    setup_xorg
    setup_codduo_system
    install_bootloader
    finalize_installation
}

# Tratamento de erros
trap 'log_error "Erro durante a instalação. Abortando..."; exit 1' ERR

# Executar função principal
main "$@"
