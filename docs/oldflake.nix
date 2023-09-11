{
  # 1. Defined a "systems" inputs that maps to only ["x86_64-linux"]

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.unstable.url = "github:nixos/nixpkgs-channels/nixos-unstable";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/23.05";

  # 2. Override the flake-utils default to your version

  outputs = { self, nixpkgs, unstable, flake-utils, ... }:
    # Now eachDefaultSystem is only using ["x86_64-linux"], but this list can also
    # further be changed by users of your flake.
    flake-utils.lib.eachDefaultSystem (system:

      let
        input = with pkgs;[
          # stack
          haskellPackages.stack
          pkgs.haskellPackages.zlib
          SDL2
          libGL
          (pkgs.writeShellScriptBin "pkg-config" "${pkgconf}/bin/pkgconf $@")
          # zlib
          glew
          pkgconf
          # pkg-config
        ];
        pkgs = nixpkgs.legacyPackages.${system};
        # upkgs = unstable.legacyPackages.${system};
        # zlibu = pkgs.haskellPackages.zlib;
        hPkgs =
          pkgs.haskell.packages."ghc8107"; # need to match Stackage LTS version
        # from stack.yaml resolver

        myDevTools = [
          hPkgs.ghc # GHC compiler in the desired version (will be available on PATH)
          hPkgs.ghcid # Continuous terminal Haskell compile checker
          hPkgs.ormolu # Haskell formatter
          hPkgs.hlint # Haskell codestyle checker
          hPkgs.hoogle # Lookup Haskell documentation
          hPkgs.haskell-language-server # LSP server for editor
          hPkgs.implicit-hie # auto generate LSP hie.yaml file from cabal
          hPkgs.retrie # Haskell refactoring tool
          # hPkgs.cabal-install
          # stack-wrapped
          pkgs.zlib # External C library needed by some Haskell packages
        ];

        # Wrap Stack to work with our Nix integration. We don't want to modify
        # stack.yaml so non-Nix users don't notice anything.
        # - no-nix: We don't want Stack's way of integrating Nix.
        # --system-ghc    # Use the existing GHC on PATH (will come from this Nix file)
        # --no-install-ghc  # Don't try to install GHC if no matching GHC found on PATH
        stack-wrapped = pkgs.symlinkJoin {
          name = "stack"; # will be available as the usual `stack` in terminal
          paths = [ pkgs.stack ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/stack \
              --add-flags "\
                --no-nix \
                --system-ghc \
                --no-install-ghc \
              "
          '';
        };
      in
      {


        devShells.default = pkgs.mkShell {
          # buildInputs = myDevTools;
          buildInputs = [
            (pkgs.haskellPackages.ghcWithPackages
              (h: [ h.monomer ]))
            pkgs.haskellPackages.haskell-language-server
            pkgs.haskellPackages.ghcide
            pkgs.haskellPackages.hoogle

          ];
          shellHook = ''
            ghc-pkg list
          '';

          # Make external Nix c libraries like zlib known to GHC, like
          # pkgs.haskell.lib.buildStackProject does
          # https://github.com/NixOS/nixpkgs/blob/d64780ea0e22b5f61cd6012a456869c702a72f20/pkgs/development/haskell-modules/generic-stack-builder.nix#L38
          # LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath myDevTools;
        };

        # packages = {
        #   default = pkgs.haskell.lib.buildStackProject
        #     {
        #       name = "culo";
        #       src = ./.;
        #       buildInput = with pkgs;[
        #         # libGL
        #         # ghc
        #         haskellPackages.ghc
        #         haskellPackages.zlib
        #       ];
        #     };
        # default = pkgs.stdenv.mkDerivation
        #   {
        #     name = "luca";
        #     src = ./.;
        #     nativeBuildInput = input;
        #     shellHook = ''

        #     '';
        #     buildPhase = ''
        #       stack build --flag monomer:examples --extra-include-dirs=${pkgs.zlib}/include --extra-lib-dirs=${pkgs.libGL}/lib:${pkgs.zlib}/lib
        #     '';
        #     installPhase = ''
        #       mkdir -p $out/bin 
        #       touch $out/bin/luca
        #     '';


        #   };
        # };
      }
    );
}
