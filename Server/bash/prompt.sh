# shellcheck shell=bash

gitstatus_prompt_path="${XDG_DATA_HOME:-${HOME}/.local/share}/gitstatus/gitstatus.prompt.sh"

if ((BASH_VERSINFO[0] < 4)); then
    printf "prompt.sh: gitstatus requires Bash 4 or newer.\n" >&2
elif [[ -r "${gitstatus_prompt_path}" ]]; then
    # gitstatusd keeps repository state in memory instead of starting several
    # Git processes every time Bash displays the prompt.
    # shellcheck source=/dev/null
    source "${gitstatus_prompt_path}"
else
    printf "prompt.sh: gitstatus is unavailable; run the server command installer.\n" >&2
fi

# In 38;5;n and 48;5;n, 38 selects the foreground, 48 selects the
# background, 5 selects the 256-color palette, and n is the palette index.
# Use dark gray 238 as the background and white 255 for the Linux icon.
# U+F17C () is the Nerd Fonts/Font Awesome Linux logo; spaces add padding.
PS1='\[\e[48;5;238m\e[38;5;255m\]  '
# Use light gray 246 for the Powerline separator.
PS1+='\[\e[38;5;246m\] '
# 1 enables bold intensity and 39 is the blue used for the working directory.
PS1+='\[\e[1;38;5;39m\]\w'
# 22 restores normal intensity; 76 is the green used for the Git branch.
PS1+='\[\e[22;38;5;246m\]${GITSTATUS_PROMPT:+  \[\e[38;5;76m\] $GITSTATUS_PROMPT}'
# 0 resets all colors and text attributes before command input.
PS1+='\[\e[0m\] '

unset -v gitstatus_prompt_path
