#!/usr/bin/env python3
"""
Resize splash_logo.png to 50% of its current size.
Usage: python3 tool/resize_splash.py
"""
import subprocess
import os
import struct
import zlib

LOGO_PATH = os.path.join(os.path.dirname(__file__), '..', 'assets', 'images', 'splash_logo.png')
LOGO_PATH = os.path.abspath(LOGO_PATH)
BACKUP_PATH = LOGO_PATH.replace('.png', '_original.png')


def get_png_size(filepath):
    """Read PNG dimensions from header without PIL."""
    with open(filepath, 'rb') as f:
        f.read(8)  # PNG signature
        f.read(4)  # chunk length
        f.read(4)  # IHDR
        width = struct.unpack('>I', f.read(4))[0]
        height = struct.unpack('>I', f.read(4))[0]
    return width, height


def main():
    w, h = get_png_size(LOGO_PATH)
    print(f'Current size: {w}x{h}')

    new_w = w // 2
    new_h = h // 2
    print(f'Target size: {new_w}x{new_h}')

    # Backup
    import shutil
    shutil.copy2(LOGO_PATH, BACKUP_PATH)
    print(f'Backed up to: {BACKUP_PATH}')

    # Try sips (macOS built-in)
    result = subprocess.run(
        ['sips', '-z', str(new_h), str(new_w), LOGO_PATH, '--out', LOGO_PATH],
        capture_output=True, text=True
    )
    if result.returncode == 0:
        w2, h2 = get_png_size(LOGO_PATH)
        print(f'Done! New size: {w2}x{h2}')
    else:
        print('sips failed:', result.stderr)
        # Restore backup
        shutil.copy2(BACKUP_PATH, LOGO_PATH)


if __name__ == '__main__':
    main()

