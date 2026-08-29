#!/usr/bin/env zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"

source "${script_dir}/utils.sh"

common_screenrc="${script_dir}/../screen/.screenrc"
common_tmux_conf="${script_dir}/../tmux/tmux.conf"

__install_repo_path "${common_screenrc}" ~/.screenrc '.screenrc' link
__install_repo_path "${common_tmux_conf}" ~/.tmux.conf '.tmux.conf' link

unset -v script_dir
unset -v common_screenrc
unset -v common_tmux_conf

echo 'Finished terminal multiplexer configuration!'
