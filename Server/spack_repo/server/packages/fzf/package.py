from spack_repo.builtin.packages.fzf.package import Fzf as BuiltinFzf


class Fzf(BuiltinFzf):
    """fzf built without Git metadata from the source archive."""

    @property
    def ldflags(self):
        """Embed release metadata without querying a Git checkout."""
        # Spack's Go builder bypasses the Makefile that normally supplies these values.
        return [
            f"-X main.version={self.spec.version}",
            "-X main.revision=tarball",
        ]

    def setup_build_environment(self, env):
        """Disable VCS stamping because Spack builds a release archive."""
        super().setup_build_environment(env)
        # The archive has no Git metadata for Go to embed in the executable.
        env.set("GOFLAGS", "-buildvcs=false")
