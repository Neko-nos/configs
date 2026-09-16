from spack.package import version
from spack_repo.builtin.packages.tmux.package import Tmux as BuiltinTmux


class Tmux(BuiltinTmux):
    """tmux with support for forwarding application clipboard requests."""

    # SHA-256 of https://github.com/tmux/tmux/releases/download/3.7c/tmux-3.7c.tar.gz
    version(
        "3.7c",
        sha256="7c60cae9a0e25288e2e24750aafc9e8800fc7fd4555e447e1b29ee4201cfb3bf",
    )
