from spack.package import version
from spack_repo.builtin.packages.nano.package import Nano as BuiltinNano


class Nano(BuiltinNano):
    """GNU nano with the required major version."""

    # SHA-256 of https://www.nano-editor.org/dist/v9/nano-9.2.tar.xz
    version(
        "9.2",
        sha256="05ecb99247b782e8a5b3a25ed4101dd034b0236902f7449bc9795b717642f7e9",
    )
