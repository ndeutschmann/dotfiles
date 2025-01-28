#!/usr/bin/env bash

bindir="${HOME}/.local/bin"
runtimedir="${HOME}/.config/helix/runtime"
mkdir -p "$bindir"
mkdir -p "$runtimedir"

dir=$(mktemp -d)


case $(uname -m) in
    "x86_64"|"aarch64")
        arch=$(uname -m)
    ;;
    "arm64")
        arch="aarch64"
    ;;
    *)
        echo "Unsupported cpu arch: $(uname -m)"
        exit 2
    ;;
esac

case $(uname -s) in
    "Linux")
        sys="linux"
    ;;
    "Darwin")
        sys="macos"
    ;;
    *)
        echo "Unsupported system: $(uname -s)"
        exit 2
    ;;
esac

archive_name="helix-25.01.1-$arch-$sys"
url="https://github.com/helix-editor/helix/releases/download/25.01.1/$archive_name.tar.xz"
curl --location "$url" | tar -C "$dir" -xz
if [[ $? -ne 0 ]]
then
    echo
    echo "Extracting binary failed, cannot download helix :("
    echo "One probable cause is that a new release just happened and the binary is currently building."
    echo "Maybe try again later? :)"
    exit 1
fi

cp $dir/$archive_name/hx $bindir/hx
if test -d $runtimedir; then
    tar -czf "${HOME}/hx_runtime_backup.$(date +%s).tgz" $runtimedir
    rm -rf $runtimedir
    mv $dir/$archive_name/runtime $runtimedir
fi
rm -rf $dir

# handle completions
mkdir -p "${HOME}/.local/share/completions/"
curl https://raw.githubusercontent.com/helix-editor/helix/refs/tags/25.01.1/contrib/completion/hx.zsh > "${HOME}/.local/share/completions/hx.zsh"
exit
