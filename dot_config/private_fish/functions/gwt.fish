function gwt --description "cd to a git worktree by branch name or path"
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

    if test (count $argv) -eq 0
        if type -q fzf
            # Build "path\t<branch> <author> <hash> <subject>"; path is hidden in fzf
            set -l c_branch (set_color green)
            set -l c_auth (set_color brblack)
            set -l c_hash (set_color yellow)
            set -l c_reset (set_color normal)
            set -l lines
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
                set -a lines "$p"\t"$c_branch$branch_p$c_reset $c_auth$auth_p$c_reset $c_hash$hash_p$c_reset $subj"
            end
            # Ignore the user's global fzf config for this picker (local + exported)
            set -lx FZF_DEFAULT_OPTS ''
            set -lx FZF_DEFAULT_OPTS_FILE ''
            set -l choice (printf '%s\n' $lines | fzf --ansi --height 40% --reverse --delimiter \t --with-nth 2)
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
