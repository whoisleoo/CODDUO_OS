# CODDUO OS - Sistema operacional

![CODDUO OS](https://img.shields.io/badge/CODDUO%20OS-Sistema%20Minimalista-purple)
![Arch Linux](https://img.shields.io/badge/Base-Arch%20Linux-blue)

## 📋 Descrição do projeto

*CODDUO_OS* é um sistema operacional baseado em Arch Linux cuja o principal objetivo é rodar aplicações sem o uso de window manager e 

##  Características

- **Sistema Minimalista**: Apenas pacotes essenciais para máxima eficiência e menos uso da GPU.
- **Instalação**: A instalação é feita via script totalmente automatica.
- **Boot Dual**: Suporte completo para UEFI e BIOS
- **Configuração Brasileira**: Teclado ABNT2, fuso horário e locale pt_BR
- **Baixo Consumo**: Otimizado para sistemas com recursos limitados
  

## Pré-requisitos

Para gerar a ISO, você precisa de:

- **Arch Linux** (ou sistema compatível)
- **archiso** instalado
- **Conexão com internet** para download dos pacotes (De preferencia via ethernet)
- **Pelo menos 2GB de RAM** para o processo de build
- **5GB de espaço livre** em disco

### Instalação dos Pré-requisitos

```bash
sudo pacman -S archiso

archiso -h
```

## Como gerar a ISO

```bash
# Clonar/baixar o projeto
git clone https://github.com/Codduo/CODDUO_OS.git
cd CODDUO_OS

# Gerar a ISO
sudo fixgrub.sh
```




---

## Processo de Instalação

### 1. Inserir pendrive bootavel e desativar o secure-boot

Após o boot, você verá:

```
  ██████╗ ██████╗ ██████╗ ██████╗ ██╗   ██╗ ██████╗ 
 ██╔════╝██╔═══██╗██╔══██╗██╔══██╗██║   ██║██╔═══██╗
 ██║     ██║   ██║██║  ██║██║  ██║██║   ██║██║   ██║
 ██║     ██║   ██║██║  ██║██║  ██║██║   ██║██║   ██║
 ╚██████╗╚██████╔╝██████╔╝██████╔╝╚██████╔╝╚██████╔╝
  ╚═════╝ ╚═════╝ ╚═════╝ ╚═════╝  ╚═════╝  ╚═════╝ 

        Sistema Minimalista para Baixo Consumo
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Para instalar o CODDUO OS execute o comando:
sudo /root/install.sh
```

### 2. Executar Instalação

```bash
sudo /root/install.sh
```

### 4. Processo de instalação

O instalador guiará você através de:

1. **Seleção do Disco**: Escolha o disco de instalação (Ex: nvme01) PS. Ao selecionar o disco, ele será formato por completo.
2. **Configuração do Usuário**: Defina usuário e senhas
3. **Particionamento**: Automático (UEFI/BIOS)
4. **Instalação**: Download e instalação dos pacotes
5. **Configuração**: Sistema, rede e bootloader
6. **Finalização**: reinicialização do sistema

---



## 🔧 Customização da ISO

### Adicionar Pacotes

Edite o arquivo `packages.x86_64`:

```bash
# Adicionar novo pacote
echo "nome-do-pacote" >> packages.x86_64
```


## Solução de Problemas

### Caso seu problema não esteja nessa lista, é recomendado que envie um email a *codduo.dev@gmail.com* com as especificações do problema.


### 1. ISO Não Boota

- Verifique se a ISO foi gravada corretamente no pendrive.
- Formate seu pendrive antes de transforma-lo em bootavel.
- Teste criar o pendrive bootavel com BalenaEthcer ou Rufus.
- Verifique se escolheu corretamente entre UEFI ou BIOS para instalação.
- Verifique se a ISO foi gerada corretamente atraves das logs.

### Instalação Falha

- Verifique conexão com internet. (iwctl ou cabo de rede)
- Confirme integridade do disco
- Verifique se escolheu corretamente seu disco para parcionamento.
- Verifique logs: `/var/log/archiso.log`

### Problemas de Rede

```bash
# Verificar interfaces do seu sistema
ip link show

# Configurar manualmente
sudo systemctl start NetworkManager
sudo nmcli device wifi connect "SSID" password "senha"

# Conectar via iwd
iwctl
device list
station [device_name] scan
station [device_name] get-networks
station [device_name] connect [network_name]
```

## Recursos Adicionais

### Documentação
- [Arch Linux Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
- [Archiso Documentation](https://wiki.archlinux.org/title/Archiso)
- [GRUB Configuration](https://wiki.archlinux.org/title/GRUB)

### Ferramentas Úteis
- [Ventoy](https://www.ventoy.net/) - Multi-boot USB
- [Rufus](https://rufus.ie/) - Criador de USB bootável
- [Balena Etcher](https://www.balena.io/etcher/) - Gravador de imagem

### Comunidade
- [Arch Linux Forums](https://bbs.archlinux.org/)
- [Arch Linux Reddit](https://www.reddit.com/r/archlinux/)
- [Arch Linux Wiki](https://wiki.archlinux.org/)

## Contribuições ao projeto

1. Fork o projeto
2. Crie uma branch para sua feature
3. Faça commit das mudanças
4. Push para a branch
5. Abra um Pull Request


## Colaboradores

- whoisleoo
- DuRendeer


---

**CODDUO OS**
