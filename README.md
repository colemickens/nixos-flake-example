# nixos-flake-example

This shows how to build the same config, with and without flakes.

It also shows that `flake.nix` is basically just some syntax.

## flake fundamentals

Nix is in flakes mode when:
1. `nixos-rebuild <cmd> --flake '.#'` is used
2. `nix build '.#something'` the hash-tag syntax is used

**This automatically loads from a `flake.nix` in the specified dir.**

If the flake.nix were located elsewhere you could do this too:

* `nix build '/home/cole/code/nixos-flake-example#nixosConfigufations`

    (loads from `/home/cole/code/nixos-flake-example'`)
* `nix build 'github.com:colemickens/nixos-flake-example#something'`

    (loads from `flake.nix` in the root of that repo checkout)

Those are just examples of syntax. Again, 


## more tips

1. `nixos-rebuild build --flake '.#'` will automatically try to find and build the attribute: `.#nixosConfigurations.your_hostname` (assuming your machines hostname is `your_hostname`)


## overview

Note that these produce the same output:

1. with flakes:

    ```shell
    nix build '.#nixosConfigurations.mysystem.config.system.build.toplevel'
    readlink -f result
    /nix/store/0imi716z1qd04pfh4zdw6mb0gnxmakjs-nixos-system-nixos-21.03.20201020.007126e

    nixos-rebuild build --flake '.#mysystem'
    readlink -f result
    /nix/store/0imi716z1qd04pfh4zdw6mb0gnxmakjs-nixos-system-nixos-21.03.20201020.007126e
    ```

    Note, nixos-rebuild is basically just some magic to build the right derivation
    and then set it as a system profile, and activate it.

2. without flakes:

    ```shell
    export NIX_PATH=nixos-config=$(pwd)/configuration.nix:nixpkgs=https://github.com/nixos/nixpkgs/archive/nixos-unstable.tar.gz


    /nix/store/zidq625i13hvbbs8alkklj8k6a191xix-nixos-system-nixos-21.03pre-git
    ```

    **Note**, ~~same path~~ same inner system, just much slower due to no eval cache.
    (they should be identical, but the flake version suffix is slightly different)

They build the same thing, the flake.nix just moves the redirection from the NixOS channel system
into the flake instead.

Note, if you come back and run this later, you may need to tell nix to update the `nixpkgs` that it
has pinned in `flake.lock` by running `nix flake update --update-input nixpkgs`. The non-flake example
is going to re-download the nixos-unstable build when the cache expires. This could cause any hash differences
if they're on different revs. (again, another reason to have control of it via flakes, and can lock it directly in the source.)

