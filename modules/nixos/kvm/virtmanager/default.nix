{options, config, lib, pkgs, inputs, ...}:

with lib;
with lib.types;

let
  cfg = config.holynix.kvm.virtmanager;
  kvmCfg = config.holynix.kvm;
  usersCfg = config.holynix.users;

  # Add connections for users;
  mkUserConfig = name: user: {
    dconf.settings = lib.mkIf user.isKvmUser or false {
      "org/virt-manager/virt-manager/connections" = {
        autoconnect = ["qemu:///system" "qemu:///session"];
        uris = ["qemu:///system" "qemu:///session"];
      };
    };

    imports = (if user.isKvmUser or false then [ nixVirt.homeModules.default ] else []);
  };

  # Add user to needed group
  mkUser = name: user: {
    extraGroups = lib.mkIf user.isKvmUser or false [
      "kvm"
      "libvirtd"
    ];
  };
in
{
  options.holynix.kvm.virtmanager = {
    enable = mkOption {
      type = bool;
      default = kvmCfg.enable;
    };

  };

  config = mkIf cfg.enable {
    # Enable spiceUSBRedirection
    virtualisation = {
      libvirtd.enable = true;
      spiceUSBRedirection.enable = true;
    };
    programs.virt-manager.enable = true;

    # Add user to groups
    users.users = lib.mapAttrs mkUser usersCfg;

    # Connect to QEMU
    home-manager.users = lib.mapAttrs mkUserConfig usersCfg;

    # install package virtdeclare
    environment.systemPackages = with pkgs; [
      inputs.nixVirt.packages.x86_64-linux.default
    ];
  };
}
