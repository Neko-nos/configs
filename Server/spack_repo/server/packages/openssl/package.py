from pathlib import Path

from spack.package import find_libraries
from spack_repo.builtin.packages.openssl.package import Openssl as BuiltinOpenssl


class Openssl(BuiltinOpenssl):
    """OpenSSL with external detection requiring development files."""

    @classmethod
    def filter_detected_exes(cls, prefix: str, exes_in_prefix: set[str]) -> set[str]:
        """Reject OpenSSL installations missing headers or linkable libraries.

        Args:
            prefix (str): Directory containing the detected executables.
            exes_in_prefix (set[str]): Paths to the detected executables.

        Returns:
            set[str]: Executables whose installation has development files.
        """
        root = Path(prefix).parent
        # Ubuntu can put headers in an architecture-specific include directory.
        if not all(
            any((root / "include").glob(f"**/openssl/{header}.h"))
            for header in ("ssl", "crypto")
        ):
            return set()
        # Both linker libraries are required; versioned runtime files are insufficient.
        libraries = find_libraries(
            ["libssl", "libcrypto"], str(root), recursive=True, runtime=False
        )
        if not {"ssl", "crypto"}.issubset(libraries.names):
            return set()
        return exes_in_prefix
