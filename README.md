# Scripts
> Terminal scripts forged on Arch Linux — visual effects, system utilities
> and automation tools built for any graphical environment.
> 
> Scripts are actively developed. Future versions may include ports for
> PowerShell (Windows), Zsh and Fish — or users may adapt them to their shell of choice.
---
## scripts
| script | description |
|--------|-------------|
| [`matrix_bin.sh`](#matrix_binsh) | cmatrix-style binary cascade — 0s and 1s falling top to bottom |
| [`encrypt.py`](#encryptpy) | AES-256-GCM file encryptor/decryptor — any extension, single files or directories |
---
## matrix_bin.sh
![matrix_bin preview](preview.png)
Pure Bash implementation of a matrix rain effect. No dependencies, no external binaries — just ANSI escape sequences written directly to stdout for smooth, consistent rendering.
**Features**
- Real top-to-bottom cascade — every column starts at row 0 and falls to the bottom
- Brightness gradient: `bold white → normal white → dim white`
- Surgical single-cell erase — no frame spikes, no lag on column reset
- Randomized trail length and column delay for natural desync
- Zero subprocesses per frame — all rendering via direct ANSI strings
- Clean exit: restores terminal state on `Ctrl+C`
- Active development — new features and improvements ongoing
**Colors**
The colors are hardcoded in the script. To change them, edit the ANSI color functions directly:
```bash
HEAD()  { printf '\e[1;97m'; }   # bold white  — head of the drop
MID()   { printf '\e[0;37m'; }   # normal white — mid trail
DIM()   { printf '\e[2;37m'; }   # dim white   — tail of the drop
```
Replace the color codes to match your preference. Examples:
| color | code |
|-------|------|
| green | `\e[1;92m` / `\e[0;32m` / `\e[2;32m` |
| red   | `\e[1;91m` / `\e[0;31m` / `\e[2;31m` |
| cyan  | `\e[1;96m` / `\e[0;36m` / `\e[2;36m` |
| white | `\e[1;97m` / `\e[0;37m` / `\e[2;37m` |
**Usage**
```bash
chmod +x matrix_bin.sh
./matrix_bin.sh
```
**Quick launch**
```bash
echo "alias matrix='bash ~/Scripts/matrix_bin.sh'" >> ~/.bashrc
source ~/.bashrc
matrix
```
**Exit:** `Ctrl+C` — terminal is fully restored.
**Requirements:** `bash 4+`, ANSI-capable terminal (Kitty, Alacritty, Foot, etc.)

---
## encrypt.py
AES-256-GCM file encryptor/decryptor. Encrypts any file extension — single files or entire directories. Deletes the original after encrypting and the `.enc` file after decrypting.

**Dependencies**

Arch Linux:
```bash
sudo pacman -S python-cryptography
```
Other:
```bash
pip install cryptography
```

**Usage**
```bash
python encrypt.py <mode> <target> [--recursive]
```

| argument | description |
|---|---|
| `mode` | `encrypt` or `decrypt` |
| `target` | file or directory path |
| `-r, --recursive` | process subdirectories recursively |

**Examples**
```bash
# single file
python encrypt.py encrypt report.pdf
python encrypt.py decrypt report.pdf.enc

# entire directory
python encrypt.py encrypt ./docs --recursive
python encrypt.py decrypt ./docs --recursive
```

**Behavior**
- encrypts → saves `file.ext.enc` → deletes original
- decrypts → restores `file.ext` → deletes `.enc` file
- wrong password or corrupted file → aborts with error, nothing is lost

**Technical details**

| property | value |
|---|---|
| cipher | AES-256-GCM |
| key derivation | PBKDF2-SHA256 |
| iterations | 600,000 |
| salt | 16 bytes, random per file |
| nonce | 12 bytes, random per file |

**Requirements:** `python 3.8+`, `python-cryptography`

---
## zsh utilities

Native Zsh scripts for system automation and desktop workflow. No bashisms,
no external dependencies beyond the tools they wrap.

| script | description |
|--------|-------------|
| [`pgcreate`](#pgcreate) | PostgreSQL database provisioner — creates databases, roles and applies schemas |
| [`setwall`](#setwall) | Wallpaper switcher via swww — resolves names without extension, supports fzf |

---
## pgcreate

PostgreSQL database provisioner. Creates a database and its dedicated role in a
single command, hardens public schema permissions and optionally applies an SQL
schema file. Supports dropping existing databases with active connection handling.

**Usage**
```zsh
chmod +x pgcreate
./pgcreate --db <name> [options]
```

**Options**
| flag | description |
|------|-------------|
| `--db <name>` | database name (required) |
| `--user <name>` | role name — defaults to the database name |
| `--schema <file.sql>` | SQL file to execute after creation |
| `--no-user` | skip role creation, database owned by superuser |
| `--superuser <role>` | superuser used to run commands (default: `postgres`) |
| `--host / --port` | connection target (defaults: `localhost` / `5432`) |
| `--drop` | drop the database — terminates active connections first |
| `--drop-role` | drop the associated role (use with `--drop`) |
| `--dry-run` | print SQL commands without executing |

**Examples**
```zsh
# minimal — creates database + role with the same name
pgcreate --db myapp

# with a dedicated role
pgcreate --db myapp --user myuser

# apply schema on creation
pgcreate --db myapp --schema ./schema.sql

# drop database and its role
pgcreate --drop --drop-role --db myapp

# inspect without executing
pgcreate --db myapp --dry-run
```

**Behavior**
- checks for an existing database before creating — aborts with a clear message if found
- creates the role with `LOGIN` (no password — compatible with `peer`/`trust` auth)
- revokes default `PUBLIC` access on both the database and `public` schema
- prints a ready-to-use connection string and `DATABASE_URL` on completion

**Requirements:** `zsh 5+`, `psql` (PostgreSQL client)

---
## setwall

Wallpaper switcher built around `swww`. Resolves wallpaper names without requiring
the file extension — partial and case-insensitive matching included. Falls back to
an interactive `fzf` list when invoked with no arguments.

**Usage**
```zsh
chmod +x setwall
./setwall <name>
```

**Examples**
```zsh
setwall Wave          # matches Wave.jpg
setwall wave          # case-insensitive
setwall wa            # partial match — applies if result is unambiguous
setwall               # interactive fzf picker (fallback: plain list)
```

**Behavior**
- resolution order: exact match → name without extension → partial match
- if a partial query matches multiple files, lists candidates and aborts
- wallpaper directory defaults to `~/dotfiles/wallpapers` — override via env:

```zsh
export WALLPAPER_DIR="$HOME/path/to/wallpapers"
```

**Requirements:** `zsh 5+`, `swww`, `fzf` (optional — for interactive picker)
