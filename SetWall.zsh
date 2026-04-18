#!/usr/bin/env zsh
# setwall.zsh — wallpaper switcher via swww
# Usage: setwall <nome>        ex: setwall Wave
#        setwall               lista interactiva (fzf se disponível)

setopt nounset pipefail

# ─── colours ──────────────────────────────────────────────────────────────────
autoload -U colors && colors
die() { print -P "%F{red}[ERROR]%f $*" >&2; exit 1 }

# ─── config ───────────────────────────────────────────────────────────────────
WALL_DIR="${WALLPAPER_DIR:-$HOME/dotfiles/wallpapers}"

[[ -d $WALL_DIR ]] || die "Pasta de wallpapers não encontrada: $WALL_DIR"

# ─── resolução do ficheiro ────────────────────────────────────────────────────
resolve_wall() {
  local query=$1
  local match=""

  # 1. correspondência exacta com extensão
  for f in "$WALL_DIR"/"$query"; do
    [[ -f $f ]] && { match=$f; break }
  done

  # 2. nome sem extensão (case-insensitive)
  if [[ -z $match ]]; then
    for f in "$WALL_DIR"/*; do
      local base=${${f:t}%.*}
      if [[ ${base:l} == ${query:l} ]]; then
        match=$f
        break
      fi
    done
  fi

  # 3. correspondência parcial (case-insensitive)
  if [[ -z $match ]]; then
    local candidates=()
    for f in "$WALL_DIR"/*; do
      [[ ${f:t:l} == *${query:l}* ]] && candidates+=($f)
    done

    if (( ${#candidates} == 1 )); then
      match=${candidates[1]}
    elif (( ${#candidates} > 1 )); then
      print -P "%F{yellow}[WARN]%f  Múltiplos resultados para '$query':"
      for c in $candidates; do print "         ${c:t}"; done
      die "Seja mais específico, Senhor."
    fi
  fi

  [[ -n $match ]] || die "Wallpaper '$query' não encontrado em $WALL_DIR"
  print "$match"
}

# ─── selecção sem argumento (fzf ou lista simples) ────────────────────────────
if (( $# == 0 )); then
  if command -v fzf &>/dev/null; then
    local selected
    selected=$(ls "$WALL_DIR" | fzf --prompt="wallpaper > " --height=40%)
    [[ -z $selected ]] && exit 0
    WALL_PATH="$WALL_DIR/$selected"
  else
    print "Wallpapers disponíveis:"
    for f in "$WALL_DIR"/*; do print "  ${f:t}"; done
    print ""
    print -n "Nome: "
    read -r query
    [[ -z $query ]] && exit 0
    WALL_PATH=$(resolve_wall "$query")
  fi
else
  WALL_PATH=$(resolve_wall "$1")
fi

# ─── aplicar ──────────────────────────────────────────────────────────────────
print -P "%F{cyan}[INFO]%f  Aplicando: ${WALL_PATH:t}"

awww img "$WALL_PATH" \
  --transition-type fade \
  --transition-duration 1

print -P "%F{green}[OK]%f    ${WALL_PATH:t} activo."
