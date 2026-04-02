# Scripts
> Terminal scripts forged on Arch Linux — visual effects, system utilities
> and automation tools built for any graphical environment.

---

## scripts

| script | description |
|--------|-------------|
| [`matrix_rain.sh`](#matrix_rainsh) | cmatrix-style binary cascade — 0s and 1s falling top to bottom |

---

## matrix_rain.sh

![matrix_rain preview](preview.png)

Pure Bash implementation of a matrix rain effect. No dependencies, no external binaries — just ANSI escape sequences written directly to stdout for smooth, consistent rendering.

**Features**

- Real top-to-bottom cascade — every column starts at row 0 and falls to the bottom
- Brightness gradient: `bold white → normal white → dim white`
- Surgical single-cell erase — no frame spikes, no lag on column reset
- Randomized trail length and column delay for natural desync
- Zero subprocesses per frame — all rendering via direct ANSI strings
- Clean exit: restores terminal state on `Ctrl+C`

**Usage**
```bash
chmod +x matrix_rain.sh
./matrix_rain.sh
```

**Run as a command**
```bash
echo "alias matrix='bash ~/Scripts/matrix_rain.sh'" >> ~/.bashrc
source ~/.bashrc
```

**Exit:** `Ctrl+C` — terminal is fully restored.

**Requirements:** `bash 4+`, ANSI-capable terminal (Kitty, Alacritty, Foot, etc.)

---

## Development Environment

| | |
|---|---|
| OS | Arch Linux |
| WM | Hyprland |
| Terminal | Kitty |
| Shell | Bash |

---
