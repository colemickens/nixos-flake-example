# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, modulesPath, inputs, ... }:

{

  imports = [
    ./hardware-configuration.nix
  ];

  services.sshd.enable = true;

  programs.sway.enable = true;

  networking.hostName = "mysystem";

  nixpkgs.overlays = [ inputs.nur.overlay ];

  environment.systemPackages = with pkgs; [
    pkgs.nur.repos.mic92.hello-nur
  ];
}

