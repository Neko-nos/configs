#!/usr/bin/env zsh

set -euo pipefail

#######################################
# Reinstall changed extensions in VSCode/extensions after pulling origin/main into main.
# Globals:
#   HOME: Location of locally installed VS Code extensions.
#   GIT_REFLOG_ACTION: Command that triggered the Git hook.
# Arguments:
#   None; Git's post-merge argument is ignored.
# Outputs:
#   Writes package build and installation progress to stdout and stderr.
# Returns:
#   0 when no installed extension needs updating; otherwise the build or install status.
#######################################
function main() {
    [[ "$(git branch --show-current)" == main && "${GIT_REFLOG_ACTION:-}" == 'pull origin main' ]] || return 0

    local repository_dir="$(git rev-parse --show-toplevel)"
    local extensions_dir="${HOME}/.vscode/extensions"
    local extension_dir extension_id extension_name
    local -a installed_extensions

    installed_extensions=("${(@f)$(code --extensions-dir "${extensions_dir}" --list-extensions)}")

    for extension_dir in "${repository_dir}"/VSCode/extensions/*(N/); do
        [[ -f "${extension_dir}/package.json" ]] || continue
        git diff --quiet ORIG_HEAD HEAD -- "${extension_dir}" && continue

        extension_id="$(node -p 'const p = require(process.argv[1]); `${p.publisher}.${p.name}`' "${extension_dir}/package.json")"
        extension_id="${extension_id:l}"
        ((${installed_extensions[(Ie)${extension_id}]})) || continue
        extension_name="${extension_id#*.}"

        (
            cd "${extension_dir}"
            npm ci
            npm run package -- --out "${extension_name}.vsix"
            code --extensions-dir "${extensions_dir}" --install-extension "${extension_name}.vsix" --force
        )
        echo "Updated ${extension_id}; reload VS Code to use it."
    done
}

main
