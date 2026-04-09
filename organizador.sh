#!/bin/bash

#Definir a pasta que queres organizar
DIRETORIO="$HOME/Downloads"

#Entrar na pasta
cd "$DIRETORIO" || exit

echo "A organizar os ficheiros em $DIRETORIO..."
#Inicia o loop para cada ficheiro na pasta
for ficheiro in *; do
    #verificar se é um ficheiro
    if [ -f "$ficheiro" ]; then

	## Extrai a extensão e converte para minúsculas
	extensao="${ficheiro##*.}"
	extensao=$(echo "$extensao" | tr '[:upper:]' '[:lower:]')
	
	case "$extensao" in
	    jpg|jpeg|png)
                PASTA="Imagens Salvas"
                ;;
		pdf|docx|txt|xlsx|pptx|odt)
                PASTA="Trabalhos"
                ;;
		sh|zip|rar|7z|tar|gz)
                PASTA="Compactados e Scripts"
                ;;
		html|js|ts|py|cpp|c|exe|pkt)
                PASTA="Outros Scripts"
                ;;
            *)
	esac 

	#cria a pasta e move o ficheiro
	mkdir -p "$PASTA"
	mv "$ficheiro" "$PASTA/"
	echo "Movido: $ficheiro -> $PASTA/"
    fi
done

echo "Concluído! Senhor"
