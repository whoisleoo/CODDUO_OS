#!/bin/bash

# Script de verificação do sistema CODDUO-OS

echo "🔍 Verificando sistema CODDUO-OS..."

# Verificar se todos os arquivos necessários existem
files_to_check=(
    "codduo-menu.sh"
    "codduo-launcher.sh"
    "README-CODDUO.md"
    "install.sh"
)

echo "📁 Verificando arquivos necessários..."
for file in "${files_to_check[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file - OK"
    else
        echo "❌ $file - ERRO: Arquivo não encontrado"
        exit 1
    fi
done

# Verificar permissões
echo "🔐 Verificando permissões..."
if [ -x "codduo-menu.sh" ]; then
    echo "✅ codduo-menu.sh - Executável"
else
    echo "❌ codduo-menu.sh - ERRO: Não é executável"
    exit 1
fi

if [ -x "codduo-launcher.sh" ]; then
    echo "✅ codduo-launcher.sh - Executável"
else
    echo "❌ codduo-launcher.sh - ERRO: Não é executável"
    exit 1
fi

if [ -x "install.sh" ]; then
    echo "✅ install.sh - Executável"
else
    echo "❌ install.sh - ERRO: Não é executável"
    exit 1
fi

# Verificar sintaxe bash
echo "🔧 Verificando sintaxe dos scripts..."
if bash -n codduo-menu.sh; then
    echo "✅ codduo-menu.sh - Sintaxe OK"
else
    echo "❌ codduo-menu.sh - ERRO: Sintaxe incorreta"
    exit 1
fi

if bash -n codduo-launcher.sh; then
    echo "✅ codduo-launcher.sh - Sintaxe OK"
else
    echo "❌ codduo-launcher.sh - ERRO: Sintaxe incorreta"
    exit 1
fi

if bash -n install.sh; then
    echo "✅ install.sh - Sintaxe OK"
else
    echo "❌ install.sh - ERRO: Sintaxe incorreta"
    exit 1
fi

echo ""
echo "🎉 Todos os arquivos do sistema CODDUO-OS estão corretos!"
echo "📋 Arquivos verificados:"
echo "   - Menu principal: codduo-menu.sh"
echo "   - Launcher: codduo-launcher.sh"
echo "   - Documentação: README-CODDUO.md"
echo "   - Instalador: install.sh"
echo ""
echo "🚀 Sistema pronto para gerar a ISO!"