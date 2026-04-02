# Scripts

> Scripts de terminal forjados no Arch Linux — efeitos visuais, utilitários de sistema
> e ferramentas de automação construídas para qualquer ambiente gráfico. 

---

## scripts

| script | descrição |
|--------|-----------|
| [`matrix_rain.sh`](#matrix_rainsh) | cascata binária estilo cmatrix — 0s e 1s a cair do topo ao fundo |

---

## matrix_rain.sh

![matrix_rain preview](preview.png)

Implementação em Bash puro de um efeito de chuva matricial. Sem dependências, sem binários externos — apenas sequências ANSI escritas directamente no stdout para uma renderização suave e consistente.

**Funcionalidades**

- Cascata real do topo ao fundo — cada coluna começa na linha 0 e cai até ao fim
- Gradiente de brilho: `branco brilhante → branco normal → branco escuro`
- Apagamento cirúrgico célula a célula — sem spikes de frame, sem lag no reinício de coluna
- Comprimento de rastro e delay por coluna aleatórios para dessincronização natural
- Zero subprocessos por frame — toda a renderização via strings ANSI directas
- Saída limpa: restaura o estado do terminal no `Ctrl+C`

**Utilização**

```bash
chmod +x matrix_rain.sh
./matrix_rain.sh
```

**Sair:** `Ctrl+C` — o terminal é totalmente restaurado.

**Requisitos:** `bash 4+`, terminal com suporte ANSI (Kitty, Alacritty, Foot, etc.)

---

## ambiente

| | |
|---|---|
| SO | Arch Linux |
| WM | Hyprland |
| Terminal | Kitty |
| Shell | Bash |

---
