# nixos-flake-example

This readme seeks to explain and justify flakes.
It also provides an example NixOS config with a supporting `flake.nix`,
and instructions to build it with *and without* flakes support at the same time.

Later, it may contain more comprehensive tips about adopting flakes and changes you made need to make to your configuration.

- [Overview of Flakes (and why you want it)](#overview-of-flakes-and-why-you-want-it)
- [The Basics of Flakes](#the-basics-of-flakes)
- [Flake Syntax Examples](#flake-syntax-examples)
- [Tips for Porting to Flakes](#tips-for-porting-to-flakes)
- [Example NixOS Config with optional Flake support](#example-nixos-config-with-optional-flake-support)

## Overview of Flakes (and why you want it)

Flakes is a few things:
* `flake.nix`: a Nix file, with a specific structure to describe inputs and outputs for a Nix project
  * flake inputs can,
    * point at directories on disk,
    * track the tip of master of a github repository,
    * track specific branches of a generic git repos, etc
* `flake.lock`: a manifest that "locks" inputs and records the exact versions in use
* CLI support for flake-related features
  * `nix flake update --recreate-lock-file` for updating all inputs and recreating `flake.lock`
  * `nix flake update --update-input nixpkgs` to update a single input to latest and recording it in `flake.lock`
  * `nix build /some/dir#some-output` to build the `some-output` attribute in the `/some/dir` project
  * (more, see the rest of this document for examples)
* pure (by default) evaluations  
  * thus the following are disallowed/unused:
    * `NIX_PATH` and `<nixpkgs>` type constructs
    * local user nixpkgs config (`~/.config/{nix,nixpkgs}`)
    * unpinned imports (aka, `fetchTarball` without a pinned `rev`+`sha256`)

This ultimately enables:
* properly hermetic builds
* fully reproducable and portable Nix projects
* faster Nix operations due to evaluation caching enabled by pure evaluations)

This removes the need for:
* using `niv` or other tooling to lock dependencies
* manually documenting or scripting to ensure `NIX_PATH` is set consistently for your team
* the need for the *"the impure eval tree of sorrow"* that comes with all of today's Nix impurities

## The Basics of Flakes

Nix is in flakes mode when:
1. `nixos-rebuild <cmd> --flake '.#'` is used
2. `nix build '.#something'` the hash-tag syntax is used

Note:
* Nix flake commands will implicitly take a directory path, it expects a `flake.nix` inside.
* when you see: `nix build '.#something'`, the `.` means current directory, and `#something` means to build the `something` output attribute

## Flake Syntax Examples

These three examples, for me, are all the same source, but accessed in different ways:

* `nix build '.#nixosConfigurations.mysystem'`

    (loads `flake.nix` from `.` (current dir))

* `nix build '/home/cole/code/nixos-flake-example#nixosConfigurations.mysystem'`

    (loads `flake.nix` from `/home/cole/code/nixos-flake-example`)
    
* `nix build 'github.com:colemickens/nixos-flake-example#nixosConfigurations.mysystem'`

    (nix will clone my github repo, then load `flake.nix` from `flake.nix` in the root of that repo checkout)

More auto-coercion:

1. `nixos-rebuild build --flake '.#'` will automatically try to find and build the attribute: `.#nixosConfigurations.your_hostname` (assuming your machines hostname is `your_hostname`)

## Tips for Porting to Flakes

* remove sources of impurity
  * TODO: explain how to fetchTarball pin
  * TODO: explain how to use flake inputs in config instead of wild fetchTarball
  * TODO: getFlake vs inputs in specialArgs

## Example NixOS Config with optional Flake support

Consider the nixos configuration in this repo:
* [./configuration.nix](./configuration.nix)
* [./hardware-configuration.nix](./hardware-configuration.nix)

These represent an example, minimal NixOS system configuration.

Let's prove that we can build this config, with and without flakes:

* Using `nixos-rebuild`:
    ```shell
    # with flakes
    unset NIX_PATH
    nixos-rebuild build --flake '.#mysystem'
    readlink -f ./result
    /nix/store/gg1jhmzqndqa0rfnwfdbnzrn8f74ckr6-nixos-system-mysystem-21.03pre-git

    # without flakes
    export NIX_PATH=nixpkgs=https://github.com/nixos/nixpkgs/archive/007126eef72271480cb7670e19e501a1ad2c1ff2.tar.gz:nixos-config=/home/cole/code/nixos-flake-example/configuration.nix
    nixos-rebuild build
    readlink -f ./result
    /nix/store/gg1jhmzqndqa0rfnwfdbnzrn8f74ckr6-nixos-system-mysystem-21.03pre-git
    ```

* Using `nix build`:
    ```shell
    # with flakes
    unset NIX_PATH
    nix build '.#nixosConfigurations.mysystem.config.system.build.toplevel
    readlink -f ./result
    /nix/store/gg1jhmzqndqa0rfnwfdbnzrn8f74ckr6-nixos-system-mysystem-21.03pre-git

    # without flakes
    export NIX_PATH=nixpkgs=https://github.com/nixos/nixpkgs/archive/007126eef72271480cb7670e19e501a1ad2c1ff2.tar.gz:nixos-config=/home/cole/code/nixos-flake-example/configuration.nix
    nix-build '<nixos/nixpkgs>' -A config.system.build.toplevel
    readlink -f ./result
    /nix/store/gg1jhmzqndqa0rfnwfdbnzrn8f74ckr6-nixos-system-mysystem-21.03pre-git
    ```

* The `./check.sh` script automates this process:

    ```shell
    cole@slynux ~/code/nixos-flake-example master* 7s
    ❯ ./check.sh     

    :: Updating the 'nixpkgs' input in flake.nix
    + nix flake update --update-input nixpkgs
    + set +x

    :: Using 'nixos-rebuild' to build the 'mysystem' toplevel
    + nixos-rebuild build --flake '.#mysystem'
    warning: Git tree '/home/cole/code/nixos-flake-example' is dirty
    building the system configuration...
    warning: Git tree '/home/cole/code/nixos-flake-example' is dirty
    + set +x

    :: Using rev=007126eef72271480cb7670e19e501a1ad2c1ff2 for <nixpkgs> (extracted from flake.nix)

    :: Setting NIX_PATH to the same values flakes is using
    + NIX_PATH=nixpkgs=https://github.com/nixos/nixpkgs/archive/007126eef72271480cb7670e19e501a1ad2c1ff2.tar.gz:nixos-config=/home/cole/code/nixos-flake-example/configuration.nix
    + nix-build '<nixpkgs/nixos>' -A config.system.build.toplevel
    /nix/store/gg1jhmzqndqa0rfnwfdbnzrn8f74ckr6-nixos-system-mysystem-21.03pre-git
    + set +x

    flake: /nix/store/gg1jhmzqndqa0rfnwfdbnzrn8f74ckr6-nixos-system-mysystem-21.03pre-git
    clssc: /nix/store/gg1jhmzqndqa0rfnwfdbnzrn8f74ckr6-nixos-system-mysystem-21.03pre-git
    ```

