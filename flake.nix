# {
#   # 1. Defined a "systems" inputs that maps to only ["x86_64-linux"]

#   inputs = {
#     flake-utils.url = "github:numtide/flake-utils";
#     unstable.url = "github:nixos/nixpkgs-channels/nixos-unstable";
#     nixpkgs.url = "github:nixos/nixpkgs/23.05";
#     nuenv.url = "github:DeterminateSystems/nuenv"; # 2. Override the flake-utils default to your version
#   };

#   outputs = { self, nixpkgs, unstable, nuenv, flake-utils, ... }:
#     # Now eachDefaultSystem is only using ["x86_64-linux"], but this list can also
#     # further be changed by users of your flake.
#     flake-utils.lib.eachDefaultSystem (system:
#       let
#         overlays = [ nuenv.overlays.default ];
#         pkgs = import nixpkgs {
#           inherit system overlays;
#         };
#         fatto = ''
#           ./build.nu
#           # touch culo
#           # echo hi
#           # mkdir $env.out/bin 
#           # touch $out/bin/no
#           # if ("build" | path exists)
#           # {
#             # make
#             # mv ./main $out/bin/main
#           # }else {
#             # echo no
#           # }
#         '';

#       in
#       {
#         devShells. default = pkgs.mkShell {
#           # buildInputs = myDevTools;
#           buildInputs = [
#             (pkgs.haskellPackages.ghcWithPackages
#               (h: [ h.monomer ]))
#             pkgs.haskellPackages.haskell-language-server
#             pkgs.haskellPackages.ghcide
#             pkgs.haskellPackages.hoogle

#           ];
#           shellHook = ''
#             ghc-pkg list
#           '';

#         };

#         packages. default = pkgs.nuenv.mkDerivation
#           {
#             name = "man";
#             src = ./.;
#             packages = [
#               (pkgs.haskellPackages.ghcWithPackages
#                 (h: [ h.monomer ]))
#             ];
#             build = ''
#               hello --greeting $"($env.MESSAGE)" | save hello.txt
#               let out = $"($env.out)/bin"
#               mkdir $out
#               cp hello $out            '';
#           };
#       }
#     );
# }

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nuenv.url = "github:DeterminateSystems/nuenv";
  };

  outputs = { self, nixpkgs, nuenv }:
    let
      overlays = [ nuenv.overlays.default ];
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        inherit system;
        pkgs = import nixpkgs { inherit overlays system; };
      });
    in
    {

      devShells = forAllSystems
        ({ pkgs, system }: {

          default = pkgs.mkShell {
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

          };
        });
      defaultTemplate = {
        path = ./.;
        description = "ciao";

      };


      packages = forAllSystems ({ pkgs, system }: {


        default = pkgs.nuenv.mkDerivation
          rec {
            name = "due";
            src = ./.;
            inherit system;
            packages = [
              (pkgs.haskellPackages.ghcWithPackages
                (h: [ h.monomer ]))
              pkgs.hello
            ];
            build = builtins.readFile ./build.nu;
            # ''
            # exec $"($env.src)/build.nu"
            # hello --greeting $"($env.MESSAGE)" | save hello.txt
            # let out = $"($env.out)/share"
            # mkdir $out
            # echo "ciao" | save $"($out)/uno"
            # cp hello.txt $out
            # '';

            MESSAGE = "My custom Nuenv derivation!";
          };





      });
    };
}
