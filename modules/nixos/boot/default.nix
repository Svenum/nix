{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.types;
let
  cfg = config.holynix.boot;
in
{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];
  
  options.holynix.boot = {
    enable = mkOption {
      type = bool;
      default = true;
    };
    secureBoot = mkOption {
      type = bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    # Filesystems
    boot.supportedFilesystems = [ "ntfs" ];

    # Kernel
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    # Bootloader
    boot.loader = {
      systemd-boot = {
        enable = mkIf (! cfg.secureBoot) true;
        configurationLimit = 15;
      };
      efi.canTouchEfiVariables = true;
      timeout = mkDefault 1;
    };

    boot.initrd.systemd.enable = true;
    boot.kernelParams = [ "quiet" "udev.log_level=3" ];

    # Configure Plymouth
    boot.plymouth = {
      enable = true;
      theme = "catppuccin-${config.holynix.theme.flavour}";
      themePackages = with pkgs; [
        (catppuccin-plymouth.override {
          variant = config.holynix.theme.flavour;
        })
      ];
    };

    boot.lanzaboote = mkIf cfg.secureBoot {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };

    environment.systemPackages = mkIf cfg.secureBoot [
      pkgs.sbctl
    ];
  };
}
