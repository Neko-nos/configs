#!/usr/bin/env zsh

# Stop running this script if any error occurs
set -euo pipefail

script_dir="${${(%):-%N}:A:h}"
repo_karabiner_dir="${script_dir}/../karabiner_elements"
repo_karabiner_dir="${repo_karabiner_dir:A}"

source "${script_dir}/utils.sh"

karabiner_source_file=''
while [[ -z "${karabiner_source_file}" ]]; do
    printf 'Which keyboard type do you use? [jis/us]: '
    read -r keyboard_type
    case "${keyboard_type:l}" in
        jis)
            karabiner_source_file="${repo_karabiner_dir}/karabiner.json"
            ;;
        us)
            karabiner_source_file="${repo_karabiner_dir}/karabiner_us2jis.json"
            ;;
        *)
            echo 'Please answer jis or us.'
            ;;
    esac
done

if command -v brew >/dev/null 2>&1; then
    __install_formula karabiner-elements '/Applications/Karabiner-Elements.app'
else
    echo 'Homebrew is required to install Karabiner-Elements from this script.'
    echo 'Skipping Karabiner-Elements installation.'
fi

mkdir -p "${HOME}/.config/karabiner"
__install_repo_path \
    "${karabiner_source_file}" \
    "${HOME}/.config/karabiner/karabiner.json" \
    'Karabiner-Elements karabiner.json' \
    link

__open_application_for_setup Karabiner-Elements '/Applications/Karabiner-Elements.app'

echo 'Finished Karabiner-Elements configuration!'
echo ''
