# Sourced at the end of ~/.zshrc (install/zsh.sh adds the line).
# Plugins live in ~/.local/share/zsh, fetched by install/zsh.sh and
# install/git-aliases.sh; anything missing is skipped.

# Prompt: one line, path + short branch, replacing the one from
# ~/.zshrc. Inside a repo the path starts at the repo root
# (hunter/internal/cmd), elsewhere it is the last two parts. Issue
# branches (113-long-slug) show as #113, other long names are
# truncated. ❯ turns red after a failed command.
autoload -Uz vcs_info add-zsh-hook
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' max-exports 3
zstyle ':vcs_info:git:*' formats '%b' '%r' '%S'
zstyle ':vcs_info:git:*' actionformats '%b|%a' '%r' '%S'

_prompt_git() {
    vcs_info
    local b=$vcs_info_msg_0_
    if [[ $b =~ '^([0-9]+)-' ]]; then
        b="#$match[1]"
    elif (( ${#b} > 24 )); then
        b="${b[1,23]}…"
    fi
    _prompt_git_info=${b:+" %F{242}${b//\%/%%}%f"}

    if [[ -n $b ]]; then
        local p=$vcs_info_msg_1_
        [[ $vcs_info_msg_2_ != . ]] && p+=/$vcs_info_msg_2_
        _prompt_dir=${p//\%/%%}
    else
        _prompt_dir='%2~'
    fi
}
add-zsh-hook precmd _prompt_git

bindkey -e
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^H' backward-kill-word
bindkey '^[[3;5~' kill-word

() {
    local -i h=0
    local c
    for c in ${(s::)HOST%%.*}; do
        (( h = (h * 31 + #c) % 1000003 ))
    done
    local -a colors=(37 72 108 114 139 172 178 180 209 214)
    _prompt_host="%F{${colors[h % $#colors + 1]}}%m%f "
}

setopt prompt_subst
PROMPT='${_prompt_host}%F{blue}${_prompt_dir}%f${_prompt_git_info} %(?.%F{magenta}.%F{red})❯%f '

# dtree [-n depth] [-f] [-p] [tree options] [dir...]: the directory
# layout, hidden entries included, without VCS, dependency, virtualenv,
# build output and cache directories or anything .gitignore excludes,
# then a list of the directories it skipped. Depth defaults to 3.
# -f lists files too, -p prints full paths.
_dtree_ignore='.git|node_modules|.pnpm-store|bower_components|.venv|venv|__pycache__|*.egg-info|.mypy_cache|.pytest_cache|.ruff_cache|.tox|.nox|.cache|dist|build|target|.next|.nuxt|.svelte-kit|.turbo|.parcel-cache|coverage|.terraform|vendor|.idea|.gradle|*.pyc|.DS_Store'
dtree() {
    local -a n f p opts
    zparseopts -D -E -- n:=n f=f p=p || return
    local depth=${n[-1]:-3}
    if (( $#f )); then
        opts=(-F)    # with files: mark directories with a /
    else
        opts=(-d)
    fi
    (( $#p )) && opts+=(-f)
    tree $opts -a --gitignore -L $depth -I "$_dtree_ignore" "$@" || return
    _dtree_skipped $depth ${@:#-*}
}

# _dtree_skipped <depth> [dir...]: print the outermost directories,
# down to <depth>, that dtree hid by name or because git ignores them.
# .git itself is not listed.
_dtree_skipped() {
    local depth=$1; shift
    local -a names found kept parts
    local pat d base prefix entry rel k
    for pat in ${(s:|:)_dtree_ignore}; do
        [[ $pat == .git ]] || names+=(-o -name $pat)
    done
    for d in ${@:-.}; do
        [[ -d $d ]] || continue
        base=${d%/}/
        [[ $base == ./ ]] && base=
        found+=(${(f)"$(find $d -mindepth 1 -maxdepth $depth -name .git -prune \
            -o -type d \( ${names[2,-1]} \) -print -prune 2>/dev/null)"})
        # Directories an ignore rule matches; paths come relative to
        # the repo root, so strip the prefix of $d within it.
        prefix=$(git -C $d rev-parse --show-prefix 2>/dev/null) || continue
        for entry in ${(0)"$(git -C $d status -z --porcelain \
                --ignored=matching --untracked-files=normal -- . 2>/dev/null)"}; do
            [[ $entry == '!! '*/ ]] || continue
            rel=${${entry#'!! '}%/}
            rel=${rel#${(b)prefix}}
            parts=(${(s:/:)rel})
            (( $#parts <= depth )) && found+=($base$rel)
        done
    done
    found=(${(ou)found#./})
    for d in $found; do
        for k in $kept; do
            [[ $d == $k/* ]] && continue 2
        done
        kept+=($d)
    done
    (( $#kept )) || return 0
    print "\nskipped:"
    print -l -- "  "${^kept}
}

() {
    local d="$HOME/.local/share/zsh"

    # Completion: extra definitions, arrow-key menu, ls colours.
    if [[ -d $d/zsh-completions/src ]]; then
        fpath=("$d/zsh-completions/src" $fpath)
        autoload -Uz compinit && compinit -i
    fi
    zstyle ':completion:*' menu select
    [[ -z $LS_COLORS ]] && (( $+commands[dircolors] )) && eval "$(dircolors -b)"
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

    # Git aliases from oh-my-zsh (gst, gco, gcmsg, gp, ...).
    if [[ -f $d/omz-git/git.plugin.zsh ]]; then
        autoload -Uz is-at-least
        source "$d/omz-git/git.zsh"
        source "$d/omz-git/git.plugin.zsh"
    fi

    # fzf: Ctrl-R fuzzy history, Ctrl-T insert a file path, Alt-C cd
    # into a directory. Lists with fd (honours .gitignore), previews
    # files with bat.
    if (( $+commands[fzf] )); then
        if (( $+commands[fd] )); then
            export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
            export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
            export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
        fi
        (( $+commands[bat] )) &&
            export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {}'"
        source <(fzf --zsh)
    fi

    # zoxide: `z <part of a path>` jumps to the best match among
    # directories you have visited, `zi` picks one with fzf.
    (( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

    # Grey history suggestion as you type; → accepts it.
    [[ -f $d/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
        source "$d/zsh-autosuggestions/zsh-autosuggestions.zsh"

    # Must be sourced last: it wraps the widgets defined above.
    [[ -f $d/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
        source "$d/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
}
