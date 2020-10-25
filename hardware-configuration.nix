{ ... }:

{
    boot.loader.systemd-boot.enable = true; # (for UEFI systems only)
    fileSystems."/".device = "/dev/disk/by-label/nixos";
}
