#!/usr/bin/env bash
# matrix_rain.sh — Cascata suave | reset cirúrgico sem loop de limpeza

cleanup() {
    printf '\e[?25h'
    printf '\e[?1049l'
    exit 0
}
trap cleanup INT TERM EXIT

printf '\e[?1049h'
printf '\e[?25l'
printf '\e[2J'

COLS=$(tput cols)
LINES=$(tput lines)

declare -a head_pos trail_len

for ((c = 0; c < COLS; c++)); do
    trail_len[$c]=$(( RANDOM % 10 + 6 ))
    head_pos[$c]=$(( -(RANDOM % 30) ))
done

move()     { printf "\e[%d;%dH" "$(($1+1))" "$(($2+1))"; }
HEAD()     { printf '\e[1;97m'; }
MID()      { printf '\e[0;37m'; }
DIM()      { printf '\e[2;37m'; }
RESET()    { printf '\e[0m'; }
rand_bit() { printf '%d' $(( RANDOM % 2 )); }

while true; do

    for ((c = 0; c < COLS; c++)); do

        h=${head_pos[$c]}
        tl=${trail_len[$c]}

        # Cabeça
        if (( h >= 0 && h < LINES )); then
            move $h $c; HEAD; rand_bit
        fi

        # Rastro
        for ((t = 1; t <= tl; t++)); do
            r=$(( h - t ))
            (( r < 0 || r >= LINES )) && continue
            move $r $c
            if (( t <= 2 )); then MID; else DIM; fi
            rand_bit
        done

        # ── Apagamento cirúrgico ─────────────────────────────────────────────
        # Apenas a célula exata que o rastro acabou de abandonar
        erase=$(( h - tl - 1 ))
        if (( erase >= 0 && erase < LINES )); then
            move $erase $c; RESET; printf ' '
        fi

        # Avança
        head_pos[$c]=$(( h + 1 ))

        # apagamento natural (célula por célula) limpar o que sobrou
        if (( head_pos[c] > LINES + tl )); then
            trail_len[$c]=$(( RANDOM % 10 + 6 ))
            head_pos[$c]=$(( -(RANDOM % 20) ))
        fi

    done

    RESET
    sleep 0.025

done
