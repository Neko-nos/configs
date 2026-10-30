from pathlib import Path

from spack.package import find_libraries
from spack_repo.builtin.packages.curl.package import Curl as BuiltinCurl


class Curl(BuiltinCurl):
    """curl with external detection requiring development files."""

    @classmethod
    def filter_detected_exes(cls, prefix: str, exes_in_prefix: set[str]) -> set[str]:
        """Reject curl installations missing headers or a linkable library.

        Args:
            prefix (str): Directory containing the detected executables.
            exes_in_prefix (set[str]): Paths to the detected executables.

        Returns:
            set[str]: Executables whose installation has development files.
        """
        root = Path(prefix).parent
        # Ubuntu can put headers in an architecture-specific include directory.
        if not any((root / "include").glob("**/curl/curl.h")):
            return set()
        # A versioned runtime library alone cannot satisfy the linker's -lcurl.
        if not find_libraries("libcurl", str(root), recursive=True, runtime=False):
            return set()
        return exes_in_prefix
