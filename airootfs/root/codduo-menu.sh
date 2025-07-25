#!/bin/bash

# CODDUO-OS - Sistema operacional


# Configurações
CODDUO_HOME="/opt/codduo"
APPS_DIR="$CODDUO_HOME/apps"
CONFIG_DIR="$CODDUO_HOME/config"
DATA_DIR="$CODDUO_HOME/data"
LOG_FILE="$CODDUO_HOME/logs/system.log"

# Cores para interface
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Função para logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Função pro menu
get_key() {
    local key
    IFS= read -rsn1 key 2>/dev/null
    
    # Verificar se é Enter (LF ou CR) [ENTER NÃO FUNCIONANDO]
    if [[ $key = $'\x0a' ]] || [[ $key = $'\x0d' ]]; then
        echo enter
        return 0
    fi
    
    
    if [[ $key = $'\x1b' ]]; then
       
        local key2
        if IFS= read -rsn1 -t 0.001 key2 2>/dev/null; then
            if [[ $key2 = '[' ]]; then
               
                local key3
                if IFS= read -rsn1 -t 0.001 key3 2>/dev/null; then
                    case $key3 in
                        'A') echo up ;;
                        'B') echo down ;;
                        'C') echo right ;;
                        'D') echo left ;;
                        *) echo esc ;;
                    esac
                else
                    echo esc
                fi
            else
                echo esc
            fi
        else
            
            echo esc
        fi
        return 0
    fi
    
    # Outras teclas
    echo "$key"
}


interactive_menu() {
    local title="$1"
    local -n options_ref=$2
    local -n descriptions_ref=$3
    local selected=0
    local num_options=${#options_ref[@]}
    
    # Ocultar cursor
    echo -ne "\033[?25l"
    
    while true; do
        # Limpar tela e mostrar logo
        clear_screen
        show_logo
        
        # Mostrar título
        echo -e "${YELLOW}$title${NC}"
        echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo
        

        for i in "${!options_ref[@]}"; do
            local prefix="  "
            local suffix=""
            local color="${NC}"
            
            if [[ $i -eq $selected ]]; then
                prefix="${PURPLE}▶ ${NC}"
                suffix="${PURPLE} ◀${NC}"
                color="${BOLD}${CYAN}"
            fi
            
            echo -e "${prefix}${color}${options_ref[$i]} - ${descriptions_ref[$i]}${NC}${suffix}"
        done
        
        echo
        echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}Use ↑/↓ para navegar, Enter/Espaço para selecionar, Esc para sair${NC}"
        
     
        local key
        key=$(get_key)
        
        case $key in
            up)
                ((selected--))
                if [[ $selected -lt 0 ]]; then
                    selected=$((num_options - 1))
                fi
                ;;
            down)
                ((selected++))
                if [[ $selected -ge $num_options ]]; then
                    selected=0
                fi
                ;;
            enter|' ')
                # Mostrar cursor novamente
                echo -ne "\033[?25h"
                return $selected
                ;;
            esc)
               
                echo -ne "\033[?25h"
                return 255
                ;;
        esac
    done
}


clear_screen() {
    clear
    echo
}


show_logo() {
    echo -e "${PURPLE}${BOLD}"
    echo "  ██████╗ ██████╗ ██████╗ ██████╗ ██╗   ██╗ ██████╗ "
    echo " ██╔════╝██╔═══██╗██╔══██╗██╔══██╗██║   ██║██╔═══██╗"
    echo " ██║     ██║   ██║██║  ██║██║  ██║██║   ██║██║   ██║"
    echo " ██║     ██║   ██║██║  ██║██║  ██║██║   ██║██║   ██║"
    echo " ╚██████╗╚██████╔╝██████╔╝██████╔╝╚██████╔╝╚██████╔╝"
    echo "  ╚═════╝ ╚═════╝ ╚═════╝ ╚═════╝  ╚═════╝  ╚═════╝ "
    echo -e "${NC}"
    echo
    echo -e "${CYAN}        Sistema Operacional Minimalista v1.0${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

# Função para mostrar menu
show_main_menu() {
    local main_options=("Iniciar Aplicação" "Adicionar Aplicação" "Remover Aplicação" "Terminal" "Configurações" "Sair")
    local main_descriptions=("Executar aplicação" "Baixar nova aplicação" "Remover aplicação" "Terminal do sistema" "Configurações" "Encerrar sistema")
    
    interactive_menu "Menu Principal" main_options main_descriptions
    return $?
}

# Função para listar aplicações
list_apps() {
    echo -e "${YELLOW}Aplicações Instaladas:${NC}"
    echo
    
    if [ ! -d "$APPS_DIR" ] || [ -z "$(ls -A $APPS_DIR 2>/dev/null)" ]; then
        echo -e "${RED}  Nenhuma aplicação instalada.${NC}"
        return 1
    fi
    
    local count=1
    for app in "$APPS_DIR"/*; do
        if [ -d "$app" ]; then
            app_name=$(basename "$app")
            echo -e "${CYAN}  $count - $app_name${NC}"
            ((count++))
        fi
    done
    
    echo
    echo -e "${YELLOW}  0 - Voltar${NC}"
    echo
}

# Função para detectar tipo de aplicação
detect_app_type() {
    local app_path="$1"
    
    if [ -f "$app_path/start.sh" ]; then
        echo "shell"
    elif [ -f "$app_path/main.py" ]; then
        # Verificar se é aplicação GUI (tkinter, pygame, etc.)
        if grep -q "tkinter\|pygame\|PyQt\|PySide\|wx\|kivy" "$app_path"/*.py 2>/dev/null; then
            echo "gui"
        else
            echo "cli"
        fi
    elif [ -f "$app_path/index.html" ]; then
        echo "web"
    else
        echo "unknown"
    fi
}

# Função para criar xinitrc temporário
create_xinitrc() {
    local app_path="$1"
    local xinitrc_path="/tmp/xinitrc_$$"
    
    cat > "$xinitrc_path" << EOF
#!/bin/bash
# Configurar atalho Ctrl+Q para sair
trap 'pkill -f "python.*main.py"; exit' 2 20

# Executar aplicação
cd "$app_path"
python3 main.py
EOF
    
    chmod +x "$xinitrc_path"
    echo "$xinitrc_path"
}


start_app() {
    # Verificar se há aplicações instaladas
    if [ ! -d "$APPS_DIR" ] || [ -z "$(ls -A $APPS_DIR 2>/dev/null)" ]; then
        clear_screen
        show_logo
        echo -e "${YELLOW}Iniciar Aplicação${NC}"
        echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo
        echo -e "${RED}  Nenhuma aplicação instalada.${NC}"
        echo
        echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
        read
        return
    fi
    
   
    local app_options=()
    local app_descriptions=()
    local app_paths=()
    
    # Listar aplicações
    for app in "$APPS_DIR"/*; do
        if [ -d "$app" ]; then
            app_name=$(basename "$app")
            app_type=$(detect_app_type "$app")
            app_options+=("$app_name")
            app_descriptions+=("Tipo: $app_type")
            app_paths+=("$app")
        fi
    done
    

    app_options+=("Voltar")
    app_descriptions+=("Voltar ao menu principal")
    
    while true; do
        interactive_menu "Iniciar Aplicação" app_options app_descriptions
        local choice=$?
        
        # Se ESC foi pressionado, voltar
        if [[ $choice -eq 255 ]]; then
            return
        fi
        
        # Se escolheu voltar
        if [[ $choice -eq $((${#app_options[@]} - 1)) ]]; then
            return
        fi
        
        # Executar aplicação selecionada
        local app_path="${app_paths[$choice]}"
        local app_name=$(basename "$app_path")
        local app_type=$(detect_app_type "$app_path")
        
        clear_screen
        show_logo
        echo -e "${GREEN}Iniciando aplicação: $app_name${NC}"
        log "Iniciando aplicação: $app_name (tipo: $app_type)"
        
        # Executar aplicação baseado no tipo
        case $app_type in
            "gui")
                echo -e "${BLUE}Iniciando aplicação gráfica...${NC}"
                echo -e "${YELLOW}Dica: Use Ctrl+Alt+Backspace para sair${NC}"
                sleep 2
                
                # Criar xinitrc temporário
                xinitrc_file=$(create_xinitrc "$app_path")
                
                # Executar com startx
                XINITRC="$xinitrc_file" startx
                
                # Limpar arquivo temporário
                rm -f "$xinitrc_file"
                ;;
            "cli")
                cd "$app_path"
                python3 main.py
                ;;
            "shell")
                cd "$app_path"
                ./start.sh
                ;;
            "web")
                cd "$app_path"
                firefox index.html 2>/dev/null &
                ;;
            *)
                echo -e "${RED}Erro: Não foi possível iniciar a aplicação${NC}"
                log "Erro: Não foi possível iniciar $app_name (tipo desconhecido)"
                ;;
        esac
        
        echo
        echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
        read
        return
    done
}

# Função para adicionar aplicação
add_app() {
    clear_screen
    show_logo
    
    echo -e "${YELLOW}Adicionar Nova Aplicação${NC}"
    echo
    echo -n "Digite a URL do repositório Git: "
    read git_url
    
    if [ -z "$git_url" ]; then
        echo -e "${RED}URL não pode estar vazia!${NC}"
        echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
        read
        return
    fi
    
    # Extrair nome da aplicação da URL
    app_name=$(basename "$git_url" .git)
    
    echo
    echo -e "${GREEN}Baixando aplicação: $app_name${NC}"
    echo -e "${BLUE}URL: $git_url${NC}"
    echo
    
    # Criar diretório se não existir
    mkdir -p "$APPS_DIR"
    
    # Clonar repositório
    cd "$APPS_DIR"
    if git clone "$git_url" "$app_name"; then
        echo
        echo -e "${GREEN}✓ Aplicação '$app_name' instalada com sucesso!${NC}"
        log "Aplicação instalada: $app_name ($git_url)"
    else
        echo
        echo -e "${RED}✗ Erro ao baixar aplicação!${NC}"
        log "Erro ao instalar aplicação: $app_name ($git_url)"
    fi
    
    echo
    echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
    read
}

# Função para remover aplicação
remove_app() {
    clear_screen
    show_logo
    
    if ! list_apps; then
        echo
        echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
        read
        return
    fi
    
    echo -n "Escolha uma aplicação para remover (0 para voltar): "
    read choice
    
    if [ "$choice" = "0" ]; then
        return
    fi
    
    # Converter escolha para nome da aplicação
    local count=1
    for app in "$APPS_DIR"/*; do
        if [ -d "$app" ]; then
            if [ "$count" = "$choice" ]; then
                app_name=$(basename "$app")
                echo
                echo -e "${YELLOW}Tem certeza que deseja remover '$app_name'? (s/N): ${NC}"
                read confirm
                
                if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
                    rm -rf "$app"
                    echo -e "${GREEN}✓ Aplicação '$app_name' removida com sucesso!${NC}"
                    log "Aplicação removida: $app_name"
                else
                    echo -e "${BLUE}Operação cancelada.${NC}"
                fi
                
                echo
                echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
                read
                return
            fi
            ((count++))
        fi
    done
    
    echo -e "${RED}Opção inválida!${NC}"
    echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
    read
}

# Função para configurações
show_config() {
    while true; do
        local config_options=("Aplicação Padrão" "Informações" "Logs" "Reiniciar" "Desligar" "Voltar")
        local config_descriptions=("Definir app padrão" "Informações do sistema" "Visualizar logs" "Reiniciar sistema" "Desligar sistema" "Voltar ao menu")
        
        interactive_menu "Configurações do Sistema" config_options config_descriptions
        local choice=$?
        
        # Se ESC foi pressionado, voltar
        if [[ $choice -eq 255 ]]; then
            return
        fi
        
        case $choice in
            0)  # Configurar Aplicação Padrão
                set_default_app
                ;;
            1)  # Informações do Sistema
                show_system_info
                ;;
            2)  # Logs do Sistema
                show_logs
                ;;
            3)  # Reiniciar Sistema
                restart_system
                ;;
            4)  # Desligar Sistema
                shutdown_system
                ;;
            5)  # Voltar
                return
                ;;
        esac
    done
}

# Função para configurar aplicação padrão
set_default_app() {
    clear_screen
    show_logo
    
    echo -e "${YELLOW}Configurar Aplicação Padrão${NC}"
    echo
    
    if ! list_apps; then
        echo
        echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
        read
        return
    fi
    
    echo -n "Escolha uma aplicação padrão (0 para remover padrão): "
    read choice
    
    if [ "$choice" = "0" ]; then
        rm -f "$CONFIG_DIR/default_app"
        echo -e "${GREEN}✓ Aplicação padrão removida!${NC}"
        log "Aplicação padrão removida"
    else
        # Converter escolha para nome da aplicação
        local count=1
        for app in "$APPS_DIR"/*; do
            if [ -d "$app" ]; then
                if [ "$count" = "$choice" ]; then
                    app_name=$(basename "$app")
                    mkdir -p "$CONFIG_DIR"
                    echo "$app_name" > "$CONFIG_DIR/default_app"
                    echo -e "${GREEN}✓ Aplicação '$app_name' definida como padrão!${NC}"
                    log "Aplicação padrão definida: $app_name"
                    break
                fi
                ((count++))
            fi
        done
    fi
    
    echo
    echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
    read
}

# Função para terminal integrado
open_terminal() {
    clear_screen
    show_logo
    
    echo -e "${YELLOW}Terminal Integrado CODDUO-OS${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "${CYAN}Comandos disponíveis:${NC}"
    echo -e "${GREEN}  • Digite qualquer comando do sistema${NC}"
    echo -e "${GREEN}  • Digite 'help' para ver comandos úteis${NC}"
    echo -e "${GREEN}  • Digite 'exit' ou 'quit' para voltar ao menu${NC}"
    echo -e "${GREEN}  • Use Ctrl+C para voltar ao menu${NC}"
    echo
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    log "Terminal integrado iniciado pelo usuário $(whoami)"
    
    # Configurar trap para Ctrl+C
    trap 'echo -e "\n${GREEN}Voltando ao menu principal...${NC}"; sleep 1; return' INT
    
    # Loop do terminal
    while true; do
        echo -n -e "${PURPLE}CODDUO${NC}:${CYAN}$(pwd)${NC}$ "
        read -e command
        
        # Verificar comandos especiais
        case "$command" in
            "exit"|"quit")
                echo -e "${GREEN}Voltando ao menu principal...${NC}"
                sleep 1
                # Limpar trap antes de sair
                trap - INT
                return
                ;;
            "help")
                show_terminal_help
                ;;
            "clear")
                clear_screen
                show_logo
                echo -e "${YELLOW}Terminal Integrado CODDUO-OS${NC}"
                echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo
                ;;
            "")
                # Comando vazio, apenas continuar
                ;;
            *)
                # Executar comando
                if [ ! -z "$command" ]; then
                    echo -e "${BLUE}Executando:${NC} $command"
                    log "Comando executado no terminal: $command"
                    
                    # Executar comando e capturar saída
                    eval "$command" 2>&1
                    command_exit_code=$?
                    
                    if [ $command_exit_code -eq 0 ]; then
                        echo -e "${GREEN}✓ Comando executado com sucesso${NC}"
                    else
                        echo -e "${RED}✗ Comando falhou (código de saída: $command_exit_code)${NC}"
                    fi
                    echo
                fi
                ;;
        esac
    done
    
    # Limpar trap caso saia do loop de outra forma
    trap - INT
}

# Função para mostrar ajuda do terminal
show_terminal_help() {
    echo
    echo -e "${YELLOW}Comandos Úteis do Sistema:${NC}"
    echo
    echo -e "${CYAN}Navegação:${NC}"
    echo -e "${GREEN}  ls          ${NC}- Listar arquivos e diretórios"
    echo -e "${GREEN}  cd <dir>    ${NC}- Mudar diretório"
    echo -e "${GREEN}  pwd         ${NC}- Mostrar diretório atual"
    echo -e "${GREEN}  find <nome> ${NC}- Buscar arquivos"
    echo
    echo -e "${CYAN}Sistema:${NC}"
    echo -e "${GREEN}  ps aux      ${NC}- Listar processos"
    echo -e "${GREEN}  top         ${NC}- Monitor de processos"
    echo -e "${GREEN}  free -h     ${NC}- Uso de memória"
    echo -e "${GREEN}  df -h       ${NC}- Uso de disco"
    echo -e "${GREEN}  uname -a    ${NC}- Informações do sistema"
    echo
    echo -e "${CYAN}Rede:${NC}"
    echo -e "${GREEN}  ip addr     ${NC}- Mostrar IPs"
    echo -e "${GREEN}  ping <host> ${NC}- Testar conectividade"
    echo -e "${GREEN}  wget <url>  ${NC}- Baixar arquivo"
    echo
    echo -e "${CYAN}Pacotes:${NC}"
    echo -e "${GREEN}  sudo pacman -S <pkg>  ${NC}- Instalar pacote"
    echo -e "${GREEN}  sudo pacman -R <pkg>  ${NC}- Remover pacote"
    echo -e "${GREEN}  sudo pacman -Syu      ${NC}- Atualizar sistema"
    echo
    echo -e "${CYAN}CODDUO-OS:${NC}"
    echo -e "${GREEN}  codduo-menu ${NC}- Voltar ao menu principal"
    echo -e "${GREEN}  fastfetch   ${NC}- Informações do sistema"
    echo
}

# Função para mostrar informações do sistema
show_system_info() {
    clear_screen
    
    echo -e "${YELLOW}Informações do Sistema${NC}"
    echo
    
    # Usar fastfetch se disponível, senão usar informações básicas
    if command -v fastfetch &> /dev/null; then
        fastfetch
    else
        # Fallback para informações básicas
        echo -e "${CYAN}Sistema:${NC} CODDUO-OS v1.0"
        echo -e "${CYAN}Kernel:${NC} $(uname -r)"
        echo -e "${CYAN}Arquitetura:${NC} $(uname -m)"
        echo -e "${CYAN}Memória:${NC} $(free -h | awk 'NR==2{print $2}')"
        echo -e "${CYAN}Disco:${NC} $(df -h / | awk 'NR==2{print $2}')"
        echo -e "${CYAN}Uptime:${NC} $(uptime -p)"
        echo -e "${CYAN}Aplicações instaladas:${NC} $(ls -1 $APPS_DIR 2>/dev/null | wc -l)"
        echo -e "${CYAN}Usuário atual:${NC} $(whoami)"
        echo -e "${CYAN}Hostname:${NC} $(hostname)"
    fi
    
    echo
    echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
    read
}

# Função para mostrar logs
show_logs() {
    clear_screen
    show_logo
    
    echo -e "${YELLOW}Logs do Sistema${NC}"
    echo
    
    if [ -f "$LOG_FILE" ]; then
        tail -20 "$LOG_FILE"
    else
        echo -e "${BLUE}Nenhum log encontrado.${NC}"
    fi
    
    echo
    echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
    read
}

# Função para reiniciar sistema
restart_system() {
    clear_screen
    show_logo
    
    echo -e "${YELLOW}Reiniciar Sistema${NC}"
    echo
    echo -e "${RED}Tem certeza que deseja reiniciar o sistema? (s/N): ${NC}"
    read confirm
    
    if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
        echo -e "${GREEN}Reiniciando sistema...${NC}"
        log "Sistema reiniciado pelo usuário"
        sleep 2
        sudo reboot
    else
        echo -e "${BLUE}Operação cancelada.${NC}"
        echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
        read
    fi
}

# Função para desligar sistema
shutdown_system() {
    clear_screen
    show_logo
    
    echo -e "${YELLOW}Desligar Sistema${NC}"
    echo
    echo -e "${RED}Tem certeza que deseja desligar o sistema? (s/N): ${NC}"
    read confirm
    
    if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
        echo -e "${GREEN}Desligando sistema...${NC}"
        log "Sistema desligado pelo usuário"
        sleep 2
        sudo poweroff
    else
        echo -e "${BLUE}Operação cancelada.${NC}"
        echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
        read
    fi
}

# Função para inicializar sistema
initialize_system() {
    # Criar diretórios necessários
    sudo mkdir -p "$CODDUO_HOME"
    sudo mkdir -p "$APPS_DIR"
    sudo mkdir -p "$CONFIG_DIR"
    sudo mkdir -p "$DATA_DIR"
    sudo mkdir -p "$(dirname "$LOG_FILE")"
    
    # Definir permissões
    sudo chown -R "$(whoami):$(whoami)" "$CODDUO_HOME"
    
    # Log de inicialização
    log "Sistema CODDUO-OS iniciado pelo usuário $(whoami)"
    
    # Verificar se existe aplicação padrão
    if [ -f "$CONFIG_DIR/default_app" ]; then
        default_app=$(cat "$CONFIG_DIR/default_app")
        if [ -d "$APPS_DIR/$default_app" ]; then
            clear_screen
            show_logo
            echo -e "${GREEN}Iniciando aplicação padrão: $default_app${NC}"
            echo
            sleep 2
            
            app_type=$(detect_app_type "$APPS_DIR/$default_app")
            
            case $app_type in
                "gui")
                    echo -e "${BLUE}Iniciando aplicação gráfica padrão...${NC}"
                    echo -e "${YELLOW}Dica: Use Ctrl+Alt+Backspace para sair${NC}"
                    sleep 2
                    
                    # Criar xinitrc temporário
                    xinitrc_file=$(create_xinitrc "$APPS_DIR/$default_app")
                    
                    # Executar com startx
                    XINITRC="$xinitrc_file" startx
                    
                    # Limpar arquivo temporário
                    rm -f "$xinitrc_file"
                    ;;
                "cli")
                    cd "$APPS_DIR/$default_app"
                    python3 main.py
                    ;;
                "shell")
                    cd "$APPS_DIR/$default_app"
                    ./start.sh
                    ;;
                "web")
                    cd "$APPS_DIR/$default_app"
                    firefox index.html 2>/dev/null &
                    ;;
            esac
            
            # Aguardar aplicação terminar
            echo
            echo -e "${YELLOW}Pressione Enter para voltar ao menu...${NC}"
            read
        fi
    fi
}

# Função principal
main() {
    # Inicializar sistema
    initialize_system
    
    # Loop principal
    while true; do
        # Mostrar menu principal e capturar seleção
        show_main_menu
        local choice=$?
        
        # Se ESC foi pressionado, sair
        if [[ $choice -eq 255 ]]; then
            clear_screen
            show_logo
            echo -e "${GREEN}Encerrando CODDUO-OS...${NC}"
            echo -e "${CYAN}Obrigado por usar o CODDUO-OS!${NC}"
            log "Sistema encerrado pelo usuário $(whoami)"
            sleep 2
            exit 0
        fi
        
        case $choice in
            0)  # Iniciar Aplicação
                start_app
                ;;
            1)  # Adicionar Aplicação
                add_app
                ;;
            2)  # Remover Aplicação
                remove_app
                ;;
            3)  # Terminal
                open_terminal
                ;;
            4)  # Configurações
                show_config
                ;;
            5)  # Sair
                clear_screen
                show_logo
                echo -e "${GREEN}Encerrando CODDUO-OS...${NC}"
                echo -e "${CYAN}Obrigado por usar o CODDUO-OS!${NC}"
                log "Sistema encerrado pelo usuário $(whoami)"
                sleep 2
                exit 0
                ;;
        esac
    done
}

# Executar sistema
main "$@"
