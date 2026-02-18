# General Instructions

## Conversation
- Respond to me in Japanese
- After writing code, tell me the reasons behind your implementation (not as comments in the code)

## Coding
- Write docstrings, comments and documents in English
- Use modern syntax and librarires.
- Avoid excessive comments; focus on explaining "why", not "what".
- Write and run test codes to check your codes before finishing the conversation turn.

## Shell usage
- Ask me whenever you use deletion commands (e.g. `rm`)
- Do not use `rm` or similar commands with force options (i.e. `-f`)

# GitHub usage
- Do not do any tasks under `main` branches.
- Do not open Pull Requests or commit yourself; I will review your codes and open PRs or commit.

# Python-specific Instructions

## Environment
- Use `uv` as the package manager instead of `pip`
- Use `uv add` instead of `uv pip install`
- Use `uv run <hoge.py>` instead of `python <hoge.py>`

## Coding style
- The script must not start with a shebang unless explicitly requrested by me.
- Keep `try`/`except` blocks to the minimum necessary
  - Do not use blind except or try to hide them with `noqa: BLE001`; Always specify errors. If you can't, you usually are going to add unnecessary `try`/`except` blocks.
- Do not add excessive logging or print statements.
- When using `typing` module, do not use the deprecated classes/methods (e.g. `typing.List` -> `list`)
- Write docstring with the following style (Google Style):
  ```py
  """
  (brief explanation)

  Args:
      param (type): explanation
      ...
  Returns:
      retrun value (type): explanation
      ...
  ... (`Example` etc.)
  """
  ```
- Use `jaxtyping` for array/tensor annotations (See details for https://docs.kidger.site/jaxtyping/api/array/)

## Coding Rule
- After writing codes, always use `Ruff` as both linter and formatter
  - run `ruff check <hoge.py> --fix && ruff check <hoge.py> --fix --select I && ruff format <hoge.py>`
  - If the environment does not have `pyproject.toml`, use `uvx ruff` instead of `ruff`. Do not install `ruff` using `uv add`.

# Shell script Instructions

## Environment
- You can use `~/.zprofile` and `common/zsh/.zshrc` for a test environment, but do not modify them.
  - If you encounter issues with plugins, you are allowed to simply replicate environment variables, functions and aliases.
- If the script is not specific to `zsh`, you should make it as portable as possible.

## Coding style
- Executables (excluding dotfiles) must start with a shebang (`#!/bin/bash` or `#!/usr/bin/env zsh`)
- Use `set` with useful options (e.g., `set -euo pipefail`) at the beginning of a script
- Indent: 4 space, no tabs
- Declare function-specific variables with `local`
- Write a function comments (similar to Python docstrings) with the following style (Google Style)
  - The comment should describe the intended behaviour using:
    - Description of the function
    - Globals: List of global variables used and modified
    - Arguments: Arguments taken
    - Outputs: Output to STDOUT or STDERR
    - Returns: Returned values other than the default exit status of the last command run
  - Example:
    ```shell
    #######################################
    # Cleanup files from the backup directory.
    # Globals:
    #   BACKUP_DIR
    #   ORACLE_SID
    # Arguments:
    #   None
    #######################################
    function cleanup() {
        ...
    }

    #######################################
    # Get configuration directory.
    # Globals:
    #   SOMEDIR
    # Arguments:
    #   None
    # Outputs:
    #   Writes location to stdout
    #######################################
    function get_dir() {
        echo "${SOMEDIR}"
    }

    #######################################
    # Delete a file in a sophisticated manner.
    # Arguments:
    #   File to delete, a path.
    # Returns:
    #   0 if thing was deleted, non-zero on error.
    #######################################
    function del_thing() {
        rm "$1"
    }
    ```
