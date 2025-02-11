#!/bin/sh
# 
export TYPST_INSTALL="${HOME}/.local"
curl -fsSL https://typst.community/typst-install/install.sh | sh -s -- 0.12.0
curl --proto '=https' --tlsv1.2 -LsSf https://github.com/Myriad-Dreamin/tinymist/releases/download/v0.12.18/tinymist-installer.sh | sh
