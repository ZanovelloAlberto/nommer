#!/usr/bin/env nu

let name = $"($env.out)/bin"
mkdir $name
ghc src/Main.hs -outputdir $"($name)/.." -o $"($name)/main"

