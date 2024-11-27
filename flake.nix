{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
    }:
    let
      forAllSystems =
        function: nixpkgs.lib.genAttrs (import systems) (system: function nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            zola
            lightningcss
            sass
          ];
        };
      });

      packages = forAllSystems (pkgs: {
        default = pkgs.stdenv.mkDerivation {
          name = "site-0.0.1";
          src = ./.;
          buildInputs = with pkgs; [
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

            # File paths
            
            input="$out/style.css"
            output="temp_output.css"
            
            lightningcss --bundle -m -t '>= 0.25%' $input > $output

            # Get file sizes in bytes
            size1=$(stat --format=%s "$input")
            size2=$(stat --format=%s "$output")

            # Convert sizes to kibibytes
            size1_kib=$(awk "BEGIN {printf \"%.2f\", $size1 / 1000}")
            size2_kib=$(awk "BEGIN {printf \"%.2f\", $size2 / 1000}")

            # Calculate the difference (signed) in bytes
            difference=$(( size2 - size1 ))

            # Calculate signed percentage difference (relative to the original size)
            percentage_difference=$(awk "BEGIN {printf \"%+ .2f\", ($difference / $size1) * 100}")

            echo "$size1_kib KiB$percentage_difference% = $size2_kib KiB"

            # Overwrite the original file with the processed output
            mv "$output" "$input"
          '';
        };
      });
    };
}
