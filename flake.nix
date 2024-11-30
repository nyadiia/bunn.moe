{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    mkPnpmPackage.url = "github:nzbr/pnpm2nix-nzbr";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      mkPnpmPackage,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells = with pkgs; {
          default = mkShell {
            buildInputs = [
              zola
              lightningcss
              sass
              woff2
            ];
          };
        };

        packages = with pkgs; {
          default = stdenv.mkDerivation {
            name = "site-${self.shortRev or self.dirtyShortRev}";
            src = ./.;
            buildInputs = [
              zola
              lightningcss
            ];
            phases = [
              "unpackPhase"
              "buildPhase"
            ];

            buildPhase = ''
              SHORT_HASH=${self.shortRev or self.dirtyShortRev}
              HASH=${self.rev or self.dirtyRev}
              echo "revision: $SHORT_HASH"
              if [[ "$HASH" == *"-dirty"* ]]; then
                echo "Repository is dirty! Not modifying hash!"
              else
                echo "<a href=\"{{ config.extra.repo | safe }}/tree/$HASH\">$SHORT_HASH</a>" > templates/partials/commit.html
              fi

              zola build -o $out

              input="$out/style.css"
              output="temp_output.css"

              lightningcss --bundle -m -t ">= 0.25%" $input > $output

              # Completely optional logging
              size1=$(stat --format=%s "$input")
              size2=$(stat --format=%s "$output")

              size1_kib=$(awk "BEGIN {printf \"%.2f\", $size1 / 1000}")
              size2_kib=$(awk "BEGIN {printf \"%.2f\", $size2 / 1000}")

              difference=$(( size2 - size1 ))
              percentage_difference=$(awk "BEGIN {printf \"%+ .2f\", ($difference / $size1) * 100}")

              echo "$size1_kib KiB → $size2_kib KiB ($percentage_difference%)"

              mv "$output" "$input"
            '';
          };
        };
      }
    );
}
