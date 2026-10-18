#!/usr/bin/env python3
import sys, os, re, glob

DEFAULT_PATH = os.path.expanduser("~/.config/cava/colors")

path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_PATH
grad_path = sys.argv[3] if len(sys.argv) > 3 else ""

# Find latest grad file if not provided
if not grad_path:
    grad_files = glob.glob('/run/user/1000/serpantinum/music/covers/*_grad.txt')
    if grad_files:
        grad_path = sorted(grad_files, key=os.path.getmtime, reverse=True)[0]

grad_content = ""
if grad_path and os.path.exists(grad_path):
    with open(grad_path) as f:
        grad_content = f.read().strip()

colors = re.findall(r"#[0-9a-fA-F]{6}", grad_content)
fg = colors[0].lower() if colors else "#000000"

color_block = f"""[color]
gradient = 0
background = '#000000'
foreground = '{fg}'
"""

with open(path, "w") as f:
    f.write(color_block)

print(f"Updated {path} with foreground={fg} (from {grad_path})")
