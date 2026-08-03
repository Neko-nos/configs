#!/usr/bin/env zsh

# Stop running this script if any error occurs.
set -euo pipefail

#######################################
# Install MesloLGS NF for the current macOS user.
# Globals:
#   HOME
# Arguments:
#   None
# Outputs:
#   Writes installation status to stdout.
#######################################
function install_fonts {
    local font_directory="${HOME}/Library/Fonts"
    local font_file

    mkdir -p "${font_directory}"
    for font_file in \
        'MesloLGS NF Regular.ttf' \
        'MesloLGS NF Bold.ttf' \
        'MesloLGS NF Italic.ttf' \
        'MesloLGS NF Bold Italic.ttf'
    do
        if [[ -f "${font_directory}/${font_file}" ]]; then
            echo "You have already installed ${font_file}."
            continue
        fi

        curl -fsSL \
            --remove-on-error \
            "https://github.com/romkatv/powerlevel10k-media/raw/master/${font_file// /%20}" \
            --output "${font_directory}/${font_file}"
        echo "Installed ${font_file}."
    done

    echo 'Finished MesloLGS NF installation!'
    echo
}

install_fonts
unset -f install_fonts
