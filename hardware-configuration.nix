# these args are passed into every nixos module (or file that is in included in a nixos module imports=[...])
{
    modulesPath, # this variable, in particular, gives us the nixos modules path for our system config
    ...
}:

{
    imports = [
        # note: this format can't be used with flakes, because it pulls from
        # NIX_PATH, which is impure, and dis-allowed with flakes.
        # Use the format shown in the line below it.

        #<nixpkgs/nixos/modules/installer/scan/not-detected.nix>

        "${modulesPath}/installer/scan/not-detected.nix"

    ];
    boot.loader.systemd-boot.enable = true; # (for UEFI systems only)
    fileSystems."/".device = "/dev/disk/by-label/nixos";
}
