# nixos-flake-example

**NOTE**: nixflk is a better example repo for a full NixOS config layout, this repo
is mostly to provide more context+examples around flakes, and to show that you can produce
the same EXACT system with flakes as with nix-build, if you know what to do.

This readme starts out with an attempt to explain and justify flakes. It also contains
some examples of `nix` cli flakes syntax and tips for adopting flakes in your project.

Finally, [at the end of the readme](#example-nixos-config-with-optional-flake-support)
is an example NixOS config with a supporting `flake.nix`,
and instructions to build it with *and without* flakes support at the same time.

- [Overview of Flakes (and why you want it)](#overview-of-flakes-and-why-you-want-it)
- [Important Related Reading](#important-related-reading)
- [Nix CLI - Flakes Usage](#nix-cli---flakes-usage)
  - [Useful Commands and Examples](#useful-commands-and-examples)
    - [nixos-rebuild](#nixos-rebuild)
    - [nix build](#nix-build)
    - [nix flake](#nix-flake)
  - [Auto-coercion examples](#auto-coercion-examples)
- [Tips for Porting to Flakes](#tips-for-porting-to-flakes)
- [Example NixOS Config with optional Flake support](#example-nixos-config-with-optional-flake-support)

## Overview of Flakes (and why you want it)

Flakes is a few things:
* `flake.nix`: a Nix file, with a specific structure to describe inputs and outputs for a Nix project
  * See [NixOS Wiki - Flakes - Input Schema](https://nixos.wiki/wiki/Flakes#Input_schema) for flake input examples
  * See [NixOS Wiki - Flakes - Output Schema](https://nixos.wiki/wiki/Flakes#Input_schema) for flake output examples
* `flake.lock`: a manifest that "locks" inputs and records the exact versions in use
* CLI support for flake-related features
* pure (by default) evaluations

This ultimately enables:
* properly hermetic builds
* fully reproducable and portable Nix projects
* faster Nix operations due to evaluation caching enabled by pure evaluations)

This removes the need for:
* using `niv` or other tooling to lock dependencies
* manually documenting or scripting to ensure `NIX_PATH` is set consistently for your team
* the need for the *"the impure eval tree of sorrow"* that comes with all of today's Nix impurities

## Important Related Reading

* [NixOS Wiki - Flakes](https://nixos.wiki/wiki/Flakes)
  * a somewhat haphazard collection of factoids/snippets related to flakes
  * particularly look at: **[Flake Schema](https://nixos.wiki/wiki/Flakes#Flake_schema)**, and it's two sections: **[Input Schema](https://nixos.wiki/wiki/Flakes#Input_schema)**, **[Output Schema](https://nixos.wiki/wiki/Flakes#Output_schema)**
* [Tweag - NixOS flakes](https://www.tweag.io/blog/2020-07-31-nixos-flakes/)
  * this article describes how to enable flake support in `nix` and `nix-daemon`
  * reading this article is a **pre-requisite**
  * this README.md assumes you've enabled flakes system-wide
  * omit using `boot.isContainer = true;` on `configuration.nix` (as the article suggests) if you want to use `nixos-rebuild` rather than `nixos-container` 

## Nix CLI - Flakes Usage

Nix is in flakes mode when:
* `--flake` is used with the `nixos-rebuild` command
* or, when `nix build` is used with an argument like `'.#something'`  (the hash symbol separates the flake source from the attribute to build)

When in this mode:
* Nix flake commands will implicitly take a directory path, it expects a `flake.nix` inside
* when you see: `nix build '.#something'`, the `.` means current directory, and `#something` means to build the `something` output attribute

### Useful Commands and Examples
#### nixos-rebuild
* `nixos-rebuild build --flake '.#'`
  * looks for `flake.nix` in `.` (current dir)
  * since it's `nixos-rebuild`, it automatically tries to build:
    * `#nixosConfigurations.{hostname}.config.system.build.toplevel`
* `nixos-rebuild build --flake '/code/nixos-config#mysystem'`
  * looks for `flake.nix` in `/code/nixos-config`
  * since it's `nixos-rebuild`, it automatically tries to build:
    * `#nixosConfigurations.mysystem.config.system.build.toplevel`
    * (note that this time we specifically asked, and got to build the `mysystem` config)
#### nix build
* `nix build 'github:colemickens/nixpkgs-wayland#obs-studio'`
  * looks for `flake.nix`  in (a checkout of `github.com/colemickens/nixpkgs-wayland`)
  * builds and run the first attribute found:
    * `#obs-studio`
    * `#packages.{currentSystem}.obs-studio`
    * TODO: finish fleshing out this list
#### nix flake
* `nix flake update --recreate-lock-file`
  * updates all inputs and recreating `flake.lock`
* `nix flake update --update-input nixpkgs`
  * updates a single input to latest and recording it in `flake.lock`

### Auto-coercion examples

Nix CLI will try to be ... smart and auto-coerce some output attribute paths for you.

* `nix build '/some/path#obs-studio'`:
  * builds and run the first attribute found:
    * `/some/path#obs-studio`
    * `/some/path#packages.x86_64-linux.obs-studio`
    * `/some/path#legacyPackages.x86_64-linux.obs-studio`
    * TODO: finish fleshing out this list
    * TODO: not sure about search order, presumably the bare one would be priority

## Tips for Porting to Flakes

**Remove Impurities** - Since nix flakes does a 'pure' build by default,
  * `NIX_PATH` is ignored
  * `<nixpkgs>` imports do not work, and explicitly error
  * local user nixpkgs config (`~/.config/{nix,nixpkgs}`) are ignore
  * unpinned imports (aka, `fetchTarball` without a pinned `rev`+`sha256`) are forbidden

To fix these:
  * specify all remote imports in `flake.nix` instead of using `fetchTarball`
    * the config in this repo shows an example of using the overlay from
      `nixpkgs-wayland`.
    * TODO: investigate `getFlake` vs  passing `inputs` in `specialArgs`

## Example NixOS Config with optional Flake support

Consider the nixos configuration in this repo:
* [./configuration.nix](./configuration.nix)
* [./hardware-configuration.nix](./hardware-configuration.nix)

These represent an example, minimal NixOS system configuration.

The easiest way to build it, without cloning this repo:
```
nix build 'github:colemickens/nixos-flake-example#nixosConfigurations.mysystem.config.system.build.toplevel'
```

Let's prove that we can build this config, with and without flakes:

* Using `nixos-rebuild`:
    ```shell
    # with flakes
    unset NIX_PATH
    nixos-rebuild build --flake '.#mysystem'
    readlink -f ./result
    /nix/store/gg1jhmzqndqa0rfnwfdbnzrn8f74ckr6-nixos-system-mysystem-21.03pre-git

    # !! for this next step, match the git SHA1 to what the flake.lock uses
    #    otherwise you'll have a hash mismatch due to different nixpkgs

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

# Flake Feedback/Ponderings

- Is the hash tag syntax really worth it?
  - For example, is:
    - `nix build 'github:colemickens/nixpkgs-wayland#obs-studio'`
  - really better than:
    - `nix build --flake 'github:colemickens/nixpkgs-wayland' 'obs-studio'` ?

- Are the auto-coercion rules for attribute paths worth it?
  They definitely add some mental overhead...

- 
