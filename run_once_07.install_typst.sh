#!/bin/sh
# 
export TYPST_INSTALL="${HOME}/.local"
curl -fsSL https://typst.community/typst-install/install.sh | sh -s -- 0.13.1
curl --proto '=https' --tlsv1.2 -LsSf https://github.com/Myriad-Dreamin/tinymist/releases/download/v0.13.10/tinymist-installer.sh | sh
