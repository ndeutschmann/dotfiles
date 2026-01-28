if status is-interactive
    # Commands to run in interactive sessions can go here

    # Settings
    fish_add_path -m ~/.local/bin
    export EDITOR="hx"

    # Aliases
    alias hux="uv run hx"
    alias eza="eza --icons --git  --header -L 2  --group-directories-first -s accessed"
    alias zj="zellij"

    # fzf config
    export FZF_DEFAULT_COMMAND="rg --files" # use rigrep (respect gitignore)
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND" # also do that for ctrl-t pop-up
    export FZF_DEFAULT_OPTS="--bind 'ctrl-a:reload:rg --files --no-ignore' --bind 'ctrl-i:reload:rg --files' --header 'CTRL-A: no-ignore / CTRL-I: respect ignores'" # toggle gitignore respect
    export FZF_CTRL_T_OPTS="$FZF_DEFAULT_OPTS"

    # Tool setup
    source ~/.local/share/yazi/y.fish
    mise activate fish | source
    starship init fish | source
    fzf --fish | source

    function fish_greeting
        fastfetch
    end

    eval "$(zoxide init fish)" # needs to be last
end
