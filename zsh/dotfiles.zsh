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

setopt prompt_subst
PROMPT='%F{blue}${_prompt_dir}%f${_prompt_git_info} %(?.%F{magenta}.%F{red})❯%f '

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

    # Grey history suggestion as you type; → accepts it.
    [[ -f $d/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
        source "$d/zsh-autosuggestions/zsh-autosuggestions.zsh"

    # Must be sourced last: it wraps the widgets defined above.
    [[ -f $d/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
        source "$d/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
}
