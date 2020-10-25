# nixos-flake-example

This shows how to build the same config, with and without flakes. And shows that both builds produce the same output.

It also shows that `flake.nix` is basically just some syntax. In this case,
we are using flakes to bring our NixOS system config (`configuration.nix` and `hardware-configuration.nix`)
into a single repository *along with* the `nixpkgs` reference used to build the system. Without flakes,
`nixpkgs` is ... well, potentially unknowable.

The point of flakes is to:
1. remove `NIX_PATH` and all of the indirection that comes with it
2. encourages pinning by use/creation of `flake.lock` automatically with the use of `nix` commands
3. enables fully hermetic Nix projects were all dependencies are specified
4. allow pure evaluation (again, enabling hermetic projects)
5. pure evaluation allows for Nix expression caching, leading to nice UX performance gains

You can run `./check.sh` to show that this builds the same system config
with/without flakes.

## flake fundamentals

Nix is in flakes mode when:
1. `nixos-rebuild <cmd> --flake '.#'` is used
2. `nix build '.#something'` the hash-tag syntax is used

**This automatically loads from a `flake.nix` in the specified dir. See these examples:**

These three examples, for me, are all the same source, but accessed in different ways:

* `nix build '.#nixosConfigurations.mysystem'`

    (loads `flake.nix` from `.` (current dir))

* `nix build '/home/cole/code/nixos-flake-example#nixosConfigurations.mysystem'`

    (loads `flake.nix` from `/home/cole/code/nixos-flake-example`)
    
* `nix build 'github.com:colemickens/nixos-flake-example#nixosConfigurations.mysystem'`

    (nix will clone my github repo, then load `flake.nix` from `flake.nix` in the root of that repo checkout)


## more tips

1. `nixos-rebuild build --flake '.#'` will automatically try to find and build the attribute: `.#nixosConfigurations.your_hostname` (assuming your machines hostname is `your_hostname`)


## overview

Let's prove that we can build the same config with and without flakes:

* Using `nixos-rebuild`:
    ```
    # with flakes
    unset NIX_PATH
    nixos-rebuild build --flake .#mysystem
    readlink -f ./result
    /nix/store/gg1jhmzqndqa0rfnwfdbnzrn8f74ckr6-nixos-system-mysystem-21.03pre-git

    # without flakes
    export NIX_PATH=nixpkgs=https://github.com/nixos/nixpkgs/archive/007126eef72271480cb7670e19e501a1ad2c1ff2.tar.gz:nixos-config=/home/cole/code/nixos-flake-example/configuration.nix
    nixos-rebuild build
    readlink -f ./result
    /nix/store/gg1jhmzqndqa0rfnwfdbnzrn8f74ckr6-nixos-system-mysystem-21.03pre-git
    ```

* Using `nix build`:
    ```
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

    ```console
    cole@slynux ~/code/nixos-flake-example master* 7s
    ❯ ./check.sh     

    :: Updating the 'nixpkgs' input in flake.nix
    + nix flake update --update-input nixpkgs
    + set +x

    :: Using 'nixos-rebuild' to build the 'mysystem' toplevel
    + nixos-rebuild build --flake .#mysystem
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

