function gwt --description "cd to a git worktree by branch name or path"
    # --list mode: emit "path\t<colored branch/author/hash/subject>" lines for the
    # fzf picker. Used both for the initial launch and for fzf's reload after a delete.
    set -l list_mode
    if test "$argv[1]" = --list
        set list_mode 1
        set -e argv[1]
    end

    # --delete mode: remove the worktree at $argv[1], print a success/failure
    # message, then pause so it's readable before fzf reloads the list. Invoked
    # from the fzf ctrl-d binding via `fish -c` so the syntax is always fish.
    if test "$argv[1]" = --delete
        set -e argv[1]
        set -l p $argv[1]
        if git worktree remove $p
            set_color green
            printf '✓ removed worktree: %s\n' $p
            set_color normal
        else
            set_color red
            printf '✗ could not remove worktree: %s\n' $p
            set_color normal
        end
        read -P 'Press enter to continue… ' -l _pause
        return
    end

    # Gather worktrees as "path\tbranch" lines
    set -l worktrees
    set -l cur_path
    for line in (git worktree list --porcelain 2>/dev/null)
        switch $line
            case 'worktree *'
                set cur_path (string replace 'worktree ' '' -- $line)
            case 'branch *'
                set -l branch (string replace 'branch refs/heads/' '' -- $line)
                set -a worktrees "$cur_path"\t"$branch"
            case detached
                set -a worktrees "$cur_path"\t"(detached)"
        end
    end

    if test (count $worktrees) -eq 0
        echo "gwt: not in a git repo with worktrees" >&2
        return 1
    end

    if set -q list_mode[1]
        set -l c_branch (set_color green)
        set -l c_auth (set_color brblack)
        set -l c_hash (set_color yellow)
        set -l c_reset (set_color normal)
        for wt in $worktrees
            set -l p (string split -f1 \t -- $wt)
            set -l b (string split -f2 \t -- $wt)
            set -l info (git -C $p log -1 --format='%h%x09%s%x09%an' 2>/dev/null)
            set -l hash (string split -f1 \t -- $info)
            set -l subj (string split -f2 \t -- $info)
            set -l auth (string split -f3 \t -- $info)
            set -l branch_p (string pad -r -w 28 -- (string sub -l 28 -- $b))
            set -l auth_p (string pad -r -w 18 -- (string sub -l 18 -- $auth))
            set -l hash_p (string pad -r -w 9 -- $hash)
            printf '%s\n' "$p"\t"$c_branch$branch_p$c_reset $c_auth$auth_p$c_reset $c_hash$hash_p$c_reset $subj"
        end
        return
    end

    if test (count $argv) -eq 0
        if type -q fzf
            # Ignore the user's global fzf config for this picker (local + exported)
            set -lx FZF_DEFAULT_OPTS ''
            set -lx FZF_DEFAULT_OPTS_FILE ''
            # ctrl-d: remove the highlighted worktree (path is the hidden field 1).
            # fzf runs execute() under $SHELL, so we delegate to `gwt --delete`,
            # which prints success/failure and pauses; then reload the list. The
            # path is passed as a separate argv to avoid fzf's {1} auto-quoting
            # clashing with the surrounding single quotes.
            set -l del_bind "ctrl-d:execute(fish -c 'gwt --delete \$argv[1]' {1})+reload-sync(fish -c 'gwt --list')"
            set -l choice (gwt --list | fzf --ansi --height 40% --reverse --delimiter \t --with-nth 2 \
                --header 'enter: cd   ctrl-d: delete worktree' \
                --bind $del_bind)
            test -z "$choice"; and return 0 # user pressed Esc
            cd (string split -f1 \t -- $choice)
            return
        else
            echo "Worktrees:" >&2
            printf '%s\n' $worktrees | column -t -s \t >&2
            return 1
        end
    end

    set -l target $argv[1]

    # Match: exact branch, then branch substring, then path basename
    set -l match
    for wt in $worktrees
        set -l p (string split -f1 \t -- $wt)
        set -l b (string split -f2 \t -- $wt)
        if test "$b" = "$target"; or string match -q "*$target*" -- $b; or test (basename $p) = "$target"; or string match -q "*$target*" -- (basename $p)
            set -a match $p
        end
    end

    if test (count $match) -eq 0
        echo "gwt: no worktree matching '$target'" >&2
        return 1
    else if test (count $match) -gt 1
        echo "gwt: ambiguous '$target', matches:" >&2
        printf '  %s\n' $match >&2
        return 1
    end

    cd $match[1]
end
