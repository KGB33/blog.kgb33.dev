{
  description = "Dagger CUE SDK.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    defaultPackage.x86_64-linux =
      with import nixpkgs { system = "x86_64-linux"; };

      stdenv.mkDerivation rec {
        name = "dagger-cue";

        src = pkgs.fetchzip {
          url = "https://dagger-io.s3.amazonaws.com/dagger-cue/releases/0.2.232/dagger-cue_v0.2.232_linux_amd64.tar.gz";
          sha256 = "MqU5c8cio7jYSgWtOR+vipRG/d13P5axYUM4gEcN0lI=";
          stripRoot = false;
        };

        installPhase = ''
          install -m755 -D dagger-cue $out/bin/dagger-cue
        '';

        meta = with lib; {
          homepage = "https://docs.dagger.io/sdk/cue/";
          description = ''
            The Dagger CUE SDK contains everything you need to develop CI/CD
            pipelines using the CUE configuration language, and run them on any
            OCI-compatible container runtime.
          '';
          platforms = platforms.linux;
        };
      };
  };
}

