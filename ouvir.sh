#!/bin/bash

# --- DIAGNÓSTICO DE ELITE ---
PORTA=443

# 1. Verifica se é root (necessário para portas < 1024)
if [ "$EUID" -ne 0 ]; then 
  echo "[!] Erro Científico: Execute como SUDO para abrir a porta $PORTA."
  exit 1
fi

# 2. Verifica se a porta já está em uso (por um servidor web, por exemplo)
if lsof -Pi :$PORTA -sTCP:LISTEN -t >/dev/null ; then
    echo "[!] Alerta: A porta $PORTA já está ocupada por outro processo!"
    exit 1
fi

echo "--- RECEPTOR ATIVADO ---"
echo "[*] Aguardando conexão do alvo na porta $PORTA..."
echo "[*] IP Local do Laboratório: $(hostname -I | awk '{print $1}')"
echo "--------------------------"

# 3. O Comando Mestre em Loop Infinito
# Isso garante que se uma conexão cair, ele abre a próxima automaticamente
while true; do
    nc -lnvp $PORTA
    echo -e "\n[*] Conexão encerrada. Reiniciando escuta em 3 segundos..."
    sleep 3
done
