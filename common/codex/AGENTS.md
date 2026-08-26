# Agent Instructions

## General Instructions

### Persona

- Do not stick to your one-sided belief and prejudice.
- Do not act on your own assumptions; investigate the actual behavior and knowledge.

### Conversation

- When I ask a question, it is not a rejection or a request for changes. Answer the question appropriately without modifying the code.
- When citing code, make sure to indicate the line numbers.
  - For GitHub links, you can indicate the line by adding `#L<int>` to the end of the URL.

### Documents

- Answer my questions in the chat space, not in documents of code comments.
- Write a document for end-users, not an internal reference for developers like me.

### Coding

- Do not unnecessarily modify existing comments unless they are within the specified scope.
- Do not include tests or redundant code solely to clarify intent explicitly.
- Keep the implementation as simple as possible within the specified scope, avoiding over-engineering.
- Avoid global variables, except for compiled regex patterns.
  - Regarding magic numbers, do not replace them with variables or global constants. Write a comment to tell readers the intent, not a variable name.
- when writing a comment, focus on explaining "why", not "what".
  - If there is something (e.g., "why") you cannot infer from the code, you should write it as a comment.
- Don't worry about backward compatibility.
- Create and use dummy data/placeholders for test cases instead of real data. Never include real data, even partially.

### Tests

- Use actual modules instead of fakes or mocks. If a GPU is required, configure it to run exclusively in a GPU environment. Should an unavoidable situation arise where the use of fakes or mocks is strictly necessary, you must explicitly state this and its reason at the end of the turn.
  - Avoid smoke tests as well
- Do not add tests intended to verify that old behaviors no longer occur.

### Shell usage

- Ask me whenever you use deletion commands (e.g. `rm`)
- Do not use `rm` or similar commands with force options (i.e. `-f`)

#### Zsh History

- Do not modify `$HOME/.zsh_history` directly or indirectly. You only have read-only access; writing to it via Python scripts or any other means is strictly prohibited.
- When setting `HISTSIZE` or `SAVEHIST`, keep both values at least `10000`

### GitHub usage

- Do not open Pull Requests or commit yourself; I will review your code and open PRs or commit.

## Python-specific Instructions

### Environment

- Run `uv sync` and `uv add` outside the sandbox because they may need to update the uv cache and project environment across filesystems.
- Use `uv` as the package manager instead of `pip`
- Use `uv add` instead of `uv pip install`
- Use `uv run <hoge.py>` instead of `python <hoge.py>` or `uv run python <hoge.py>`

### Coding style

- The script must not start with a shebang.
- Keep `try`/`except` blocks to the minimum necessary
- Do not use unncessary `get*` (do not use it when you know the return value/type)
- Do not write guards for args or file contents.
- Avoid lazy imports; place all imports at the top of the file.
- When using `typing` module, do not use the deprecated classes/methods (e.g. `typing.List` -> `list`)
  - Do not append `from __future__ import annotations` when unnecessary.
- Write docstring with the following style (Google Style):

  ```py
  """
  (brief explanation)

  Args:
      param (type): explanation
      ...

  Returns:
      value (type): explanation
      ...

  Raises:
      HogeError: explanation
      ...

  ... (`Example` etc.)
  """
  ```

### jaxtyping

Use `jaxtyping` for array/tensor type annotations. See <https://docs.kidger.site/jaxtyping/api/array/> for the full reference.

- Annotation form: `Dtype[ArrayType, "shape"]` (e.g., `Float[torch.Tensor, "batch channels height width"]`).
- `ArrayType` is the array class to constrain: `jax.Array`, `np.ndarray`, `torch.Tensor`, `tf.Tensor`, or `mx.array`.
- Single-axis shape strings need a leading space (`Float[arr, " dim"]`) to avoid a Ruff F821 false positive on the axis name. The bug is tracked at [astral-sh/ruff#17386](https://github.com/astral-sh/ruff/issues/17386); the leading space is jaxtyping's documented workaround and does not change semantics. Multi-axis strings such as `"batch dim"` are unaffected.
- Example:

    ```py
    from jaxtyping import Float, Int
    import numpy as np

    def gather_logits(
        logits: Float[np.ndarray, "*batch num_classes"],   # `*axis` matches zero or more leading axes
        indices: Int[np.ndarray, "*batch n"],              # named axis `n`; `*batch` must match the logits' batch
        weights: Float[np.ndarray, "#num_classes"],        # `#axis` allows broadcasting (size num_classes or 1)
        scratch: Float[np.ndarray, "..."],                 # `...` matches any shape (dtype-only check)
        bias: Float[np.ndarray, " num_classes"],           # leading space for a single-axis shape
        scale: Float[np.ndarray, ""],                      # `""` denotes a 0-d (scalar) array
        anchors: Int[np.ndarray, "n 4"],                   # fixed-size axis next to a named axis
    ) -> Float[np.ndarray, "*batch num_classes-1"]:        # symbolic expression in the return shape
        ...
    ```

### Coding Rules

- After writing code, always use `Ruff` as both linter and formatter
  - run `ruff check <hoge.py> --fix && ruff check <hoge.py> --fix --select I && ruff format <hoge.py>`
  - If the environment does not have `pyproject.toml`, use `uvx ruff` instead of `ruff`. Do not install `ruff` using `uv add`.
- After writing code, use `pytest` (not `unittest`) for test code
  - If the environment does not have `pyproject.toml`, use `uvx pytest` instead of `pytest`. Do not install `pytest` using `uv add`
  - If the environment has `pyproject.toml` but `pytest` is not installed, you may install `pytest` via `uv add` after asking me.

## Shell Script Instructions

### Environment

- You are allowed to load `~/.zprofile` and `common/zsh/.zshrc` for a test environment, but do not modify them.
- Do not inspect profile files in `$HOME`; use the corresponding templates in `~/configs` instead.

### Coding style

- Executables (excluding dotfiles) must start with a shebang (e.g.,  `#!/usr/bin/env zsh`)
- Use `set` with useful options (e.g., `set -euo pipefail`) at the beginning of a script
- Indent: 4 spaces, no tabs
- Declare function-specific variables with `local`
- Write function comments (similar to Python docstrings) with the following style (Google Style)
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

### Coding Rules

- use `shellcheck` as a linter for non-zsh scripts
- No tests are required for shell scripts.

## Machine learning Instructions

### Rules

- use GPUs when they are available. you can use them outside of a sandbox, so do not use cpus to train/evaluate models.
- Never enable memory optimizations that may change quality or numerical behavior without explicit permission; exact quality-neutral optimizations such as FlashAttention are allowed.
- do not touch other users' jobs
