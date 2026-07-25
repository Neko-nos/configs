#!/bin/bash

set -euo pipefail

script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "${script_dir}/utils.sh"

BUILD_JOBS=8
CACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/server-install"
INSTALL_PREFIX="${HOME}/.local"
export PATH="${INSTALL_PREFIX}/bin:${PATH}"

#######################################
# Download and extract a source archive into the build cache.
# Arguments:
#   Package name without archive extension.
#   Archive URL.
#   Archive extension.
# Outputs:
#   Writes downloader and tar output to stdout and stderr.
# Returns:
#   0 if the source archive is extracted, non-zero otherwise.
#######################################
function __fetch_source() {
    local package_name="${1}"
    local url="${2}"
    local extension="${3}"
    local archive_path="${CACHE_DIR}/${package_name}.${extension}"

    mkdir -p "${CACHE_DIR}"
    if [[ ! -d "${CACHE_DIR}/${package_name}" ]]; then
        wget "${url}" -O "${archive_path}"
        tar -xf "${archive_path}" -C "${CACHE_DIR}"
        rm "${archive_path}"
    fi
    return 0
}

#######################################
# Build and install ncurses without root privileges when system ncurses is missing.
# Arguments:
#   None
# Outputs:
#   Writes build output to stdout and stderr.
# Returns:
#   0 if ncurses is available, non-zero otherwise.
#######################################
function install_ncurses() {
    # ref: https://ftp.gnu.org/gnu/ncurses/
    local index_url="https://ftp.gnu.org/gnu/ncurses/"
    local extension="tar.gz"
    local ncurses_version
    local package_name
    local source_dir

    if command -v ncursesw6-config >/dev/null 2>&1; then
        echo "You already installed ncurses."
        return 0
    fi

    ncurses_version="$(__latest_archive_version "${index_url}" "ncurses" "${extension}")"
    package_name="ncurses-${ncurses_version}"
    source_dir="${CACHE_DIR}/${package_name}"

    __fetch_source "${package_name}" "${index_url}${package_name}.${extension}" "${extension}"
    (
        cd "${source_dir}"
        ./configure --prefix="${INSTALL_PREFIX}" --with-shared --enable-widec --without-debug --without-ada
        make -j"${BUILD_JOBS}"
        make install
    )
    return 0
}

#######################################
# Build and install GNU nano without root privileges.
# Arguments:
#   None
# Outputs:
#   Writes build output to stdout and stderr.
# Returns:
#   0 if nano is installed, non-zero otherwise.
#######################################
function install_nano() {
    local index_url="https://www.nano-editor.org/dist/latest/"
    local extension="tar.xz"
    local nano_major_version
    local nano_version
    local package_name
    local source_dir

    if command -v nano >/dev/null 2>&1; then
        nano_major_version="$(nano --version | sed -n 's/^ GNU nano, version \([0-9][0-9]*\).*/\1/p' | head -n 1)"
        if [[ -n "${nano_major_version}" && "${nano_major_version}" -ge 9 ]]; then
            echo "You have already installed a compatible nano version."
            return 0
        fi

        echo "Your nano version does not meet the requirement. You have nano ${nano_major_version}, but nano>=9 is required for our custom nano settings."
        if ! __confirm "Do you want to build the latest nano under ${INSTALL_PREFIX}? [y/N]: "; then
            return 0
        fi
    fi

    nano_version="$(__latest_archive_version "${index_url}" "nano" "${extension}")"
    package_name="nano-${nano_version}"
    source_dir="${CACHE_DIR}/${package_name}"

    # ref: https://www.nano-editor.org/dist/latest/INSTALL
    __fetch_source "${package_name}" "${index_url}${package_name}.${extension}" "${extension}"

    (
        cd "${source_dir}"
        if [[ -x "${INSTALL_PREFIX}/bin/ncursesw6-config" || -x "${INSTALL_PREFIX}/bin/ncursesw5-config" ]]; then
            CPPFLAGS="-I${INSTALL_PREFIX}/include -I${INSTALL_PREFIX}/include/ncursesw ${CPPFLAGS:-}" \
            LDFLAGS="-L${INSTALL_PREFIX}/lib -L${INSTALL_PREFIX}/lib64 -Wl,-rpath,${INSTALL_PREFIX}/lib -Wl,-rpath,${INSTALL_PREFIX}/lib64 ${LDFLAGS:-}" \
            ./configure --prefix="${INSTALL_PREFIX}" --disable-libmagic --enable-utf8
        else
            ./configure --prefix="${INSTALL_PREFIX}" --disable-libmagic --enable-utf8
        fi

        make -j"${BUILD_JOBS}"
        make check
        make install
    )
    return 0
}

#######################################
# Build and install GNU Screen without root privileges.
# Arguments:
#   None
# Outputs:
#   Writes build output to stdout and stderr.
# Returns:
#   0 if Screen is installed, non-zero otherwise.
#######################################
function install_screen() {
    local index_url="https://ftp.gnu.org/gnu/screen/"
    local extension="tar.gz"
    local screen_major_version
    local screen_version
    local package_name
    local source_dir

    if command -v screen >/dev/null 2>&1; then
        screen_major_version="$(screen --version | sed -n 's/^Screen version \([0-9][0-9]*\).*/\1/p' | head -n 1)"
        if [[ -n "${screen_major_version}" && "${screen_major_version}" -ge 5 ]]; then
            echo "You have already installed a compatible screen version."
            return 0
        fi

        echo "Your screen version does not meet the requirement. You have screen ${screen_major_version}, but screen>=5 is required for our custom screen settings."
        if ! __confirm "Do you want to build the latest screen under ${INSTALL_PREFIX}? [y/N]: "; then
            return 0
        fi
    fi

    install_ncurses

    screen_version="$(__latest_archive_version "${index_url}" "screen" "${extension}")"
    package_name="screen-${screen_version}"
    source_dir="${CACHE_DIR}/${package_name}"

    # ref: https://www.gnu.org/software/screen/manual/html_node/Compiling-Screen.html
    __fetch_source "${package_name}" "${index_url}${package_name}.${extension}" "${extension}"
    (
        cd "${source_dir}"
        # PAM development files commonly require administrator access and are only needed for Screen's password authentication.
        CPPFLAGS="-I${INSTALL_PREFIX}/include -I${INSTALL_PREFIX}/include/ncursesw ${CPPFLAGS:-}" \
        LDFLAGS="-L${INSTALL_PREFIX}/lib -L${INSTALL_PREFIX}/lib64 -Wl,-rpath,${INSTALL_PREFIX}/lib -Wl,-rpath,${INSTALL_PREFIX}/lib64 ${LDFLAGS:-}" \
        ./configure --prefix="${INSTALL_PREFIX}" --disable-pam
        make -j"${BUILD_JOBS}"
        make check
        make install
    )
    return 0
}

#######################################
# Build and install tree without root privileges.
# Arguments:
#   None
# Outputs:
#   Writes build output to stdout and stderr.
# Returns:
#   0 if tree is installed, non-zero otherwise.
#######################################
function install_tree() {
    local index_url="https://oldmanprogrammer.net/tar/tree/"
    local extension="tgz"
    local tree_version
    local package_name
    local source_dir

    if command -v tree >/dev/null 2>&1; then
        echo "You have already installed tree."
        return 0
    fi

    tree_version="$(__latest_archive_version "${index_url}" "tree" "${extension}")"
    package_name="tree-${tree_version}"
    source_dir="${CACHE_DIR}/${package_name}"

    # ref: https://gitlab.com/OldManProgrammer/unix-tree/-/blob/master/INSTALL
    __fetch_source "${package_name}" "${index_url}${package_name}.${extension}" "${extension}"
    (
        cd "${source_dir}"
        make -j"${BUILD_JOBS}"
        make PREFIX="${INSTALL_PREFIX}" MANDIR="${INSTALL_PREFIX}/share/man" install
    )
    return 0
}

# Keep individual installers callable when another script sources this file.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    mkdir -p "${CACHE_DIR}" "${INSTALL_PREFIX}/bin"
    install_ncurses
    install_nano
    install_screen
    install_tree

    echo "Finished source builds!"
fi
