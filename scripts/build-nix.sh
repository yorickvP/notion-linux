#!/usr/bin/env bash
nix-shell shell.nix --run "bash ./scripts/build.sh"
nix-build notion-desktop.nix
