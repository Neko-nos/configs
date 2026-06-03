# shellcheck shell=bash

git_prompt_path="${HOME}/git-prompt.sh"

if [[ ! -f "${git_prompt_path}" ]]; then
    if command -v wget >/dev/null 2>&1; then
        wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -O "${git_prompt_path}"
    else
        printf "prompt.sh: wget is unavailable; cannot download git-prompt.sh.\n" >&2
    fi
fi

if [[ -f "${git_prompt_path}" ]]; then
    # shellcheck source=/dev/null
    source "${git_prompt_path}"

    # unstaged: *
    # staged: +
    export GIT_PS1_SHOWDIRTYSTATE=1

    # untracked: %
    export GIT_PS1_SHOWUNTRACKEDFILES=1

    # stash: $
    export GIT_PS1_SHOWSTASHSTATE=1

    # upstream difference: < > <> =
    export GIT_PS1_SHOWUPSTREAM="auto"

    PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]$(__git_ps1 " \[\e[1;32m\](%s)\[\e[0m\]")\$ '
fi

unset -v git_prompt_path
