#!/usr/bin/env python3


import os
import sys
import argparse
import getpass
from pathlib import Path
 
try:
    from cryptography.hazmat.primitives.ciphers.aead import AESGCM
    from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
    from cryptography.hazmat.primitives import hashes
except ImportError:
    print("[ERROR] Missing dependency. Run: pip install cryptography")
    sys.exit(1)
 
# --- Constants ---
SALT_SIZE    = 16   # bytes
NONCE_SIZE   = 12   # bytes — AES-GCM standard
KEY_SIZE     = 32   # bytes — AES-256
ITERATIONS   = 600_000
ENC_SUFFIX   = ".enc"
 
 
def derive_key(password: str, salt: bytes) -> bytes:
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=KEY_SIZE,
        salt=salt,
        iterations=ITERATIONS,
    )
    return kdf.derive(password.encode())
 
 
def encrypt_file(path: Path, password: str) -> Path:
    if path.suffix == ENC_SUFFIX:
        print(f"[SKIP] Already encrypted: {path}")
        return path
 
    salt  = os.urandom(SALT_SIZE)
    nonce = os.urandom(NONCE_SIZE)
    key   = derive_key(password, salt)
    aesgcm = AESGCM(key)
 
    plaintext  = path.read_bytes()
    ciphertext = aesgcm.encrypt(nonce, plaintext, None)
 
    out_path = path.with_suffix(path.suffix + ENC_SUFFIX)
    # Format: [salt 16B][nonce 12B][ciphertext + 16B GCM tag]
    out_path.write_bytes(salt + nonce + ciphertext)
 
    path.unlink()
    print(f"[OK] Encrypted: {path} -> {out_path} (original deleted)")
    return out_path
 
 
def decrypt_file(path: Path, password: str) -> Path:
    if path.suffix != ENC_SUFFIX:
        print(f"[SKIP] Not an .enc file: {path}")
        return path
 
    data  = path.read_bytes()
    salt  = data[:SALT_SIZE]
    nonce = data[SALT_SIZE:SALT_SIZE + NONCE_SIZE]
    ciphertext = data[SALT_SIZE + NONCE_SIZE:]
 
    key    = derive_key(password, salt)
    aesgcm = AESGCM(key)
 
    try:
        plaintext = aesgcm.decrypt(nonce, ciphertext, None)
    except Exception:
        print(f"[ERROR] Wrong password or corrupted file: {path}")
        sys.exit(1)
 
    # Restore original extension: file.txt.enc -> file.txt
    out_path = path.with_suffix("")
    out_path.write_bytes(plaintext)
 
    path.unlink()
    print(f"[OK] Decrypted: {path} -> {out_path} (encrypted file deleted)")
    return out_path
 
 
def process_target(target: Path, password: str, mode: str, recursive: bool):
    if target.is_file():
        if mode == "encrypt":
            encrypt_file(target, password)
        else:
            decrypt_file(target, password)
 
    elif target.is_dir():
        pattern = "**/*" if recursive else "*"
        for f in sorted(target.glob(pattern)):
            if not f.is_file():
                continue
            if mode == "encrypt":
                encrypt_file(f, password)
            else:
                decrypt_file(f, password)
    else:
        print(f"[ERROR] Path not found: {target}")
        sys.exit(1)
 
 
def main():
    parser = argparse.ArgumentParser(
        description="AES-256-GCM file encryptor/decryptor",
        formatter_class=argparse.RawTextHelpFormatter,
        epilog=(
            "Examples:\n"
            "  python encrypt.py encrypt secret.pdf\n"
            "  python encrypt.py decrypt secret.pdf.enc\n"
            "  python encrypt.py encrypt ./documents --recursive\n"
            "  python encrypt.py decrypt ./documents --recursive\n"
        )
    )
    parser.add_argument("mode",   choices=["encrypt", "decrypt"], help="Operation mode")
    parser.add_argument("target", help="File or directory path")
    parser.add_argument("-r", "--recursive", action="store_true",
                        help="Process subdirectories recursively (only for directories)")
 
    args = parser.parse_args()
 
    password = getpass.getpass("Password: ")
    if args.mode == "encrypt":
        confirm = getpass.getpass("Confirm password: ")
        if password != confirm:
            print("[ERROR] Passwords do not match.")
            sys.exit(1)
 
    process_target(Path(args.target), password, args.mode, args.recursive)
 
 
if __name__ == "__main__":
    main()
 
