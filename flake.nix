{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs, ... }: let
    allSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];
    forAllSystems = fn: nixpkgs.lib.genAttrs allSystems (system: fn (import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [self.overlays.default];
    }));

  in {
    overlays.default = final: prev: {
      rozpisovnik-planner = final.stdenv.mkDerivation {
        pname = "rozpisovnik-planner";
        version = "0.1.0";
        src = ./.;

        buildInputs = [
          final.gradle
          final.jdk21_headless
          final.makeWrapper
        ];
        buildPhase = "gradlew clean build -Dquarkus.container-image.build=true";
        installPhase = ''
          mkdir -p $out/bin
          mkdir -p $out/share/java

          cp target/java/*.jar $out/share/java

          makeWrapper ${final.jdk21_headless}/bin/java $out/bin/rozpisovnik-planner \
            --add-flags "-cp \"$out/share/java/*\" com.example.nixscalaexample.Main"
        '';
      };
    };

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        buildInputs = [
          pkgs.jdk21_headless
          pkgs.gradle
          pkgs.quarkus
        ];
      };
    });
  };
}
