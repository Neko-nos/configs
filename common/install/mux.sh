#!/usr/bin/env zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"

source "${script_dir}/utils.sh"

common_screenrc="${script_dir}/../screen/.screenrc"
common_tmux_conf="${script_dir}/../tmux/tmux.conf"
user_bin_dir="${HOME}/.local/bin"

mkdir -p "${user_bin_dir}"
__install_repo_path "${script_dir}/../bin/clipboard-copy" "${user_bin_dir}/clipboard-copy" 'clipboard-copy' link
__install_repo_path "${common_screenrc}" ~/.screenrc '.screenrc' link
__install_repo_path "${common_tmux_conf}" ~/.tmux.conf '.tmux.conf' link

unset -v script_dir
unset -v common_screenrc
unset -v common_tmux_conf
unset -v user_bin_dir

echo 'Finished terminal multiplexer configuration!'
