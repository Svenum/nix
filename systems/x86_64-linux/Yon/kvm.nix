{ pkgs, inputs, ... }:

let
  inherit (inputs) nixVirt;
  nixvirt.lib = nixVirt.lib;
  toggle_gpu = pkgs.writeShellScriptBin "toggle_gpu" ''
    if [[ $1 == "Windows GPU Nix" ]]; then
      if [[ $2 == "prepare" ]]; then
        /run/current-system/sw/bin/toggle-amd-gpu vfio
      elif [[ $2 == "release" ]]; then
        ${pkgs.busybox}/bin/sleep 10
        /run/current-system/sw/bin/toggle-amd-gpu amd
      fi
    fi
  '';

  # Paths
  nvram_path = "/home/sven/.local/share/libvirt/qemu";
  disk_path = "/home/sven/.local/share/libvirt/images";

  # Windows VMs
  win10_config = import ./vms/win10.nix { inherit nvram_path; inherit pkgs; uuid = "c08333dc-33f9-4117-969a-ac46e19ba81f"; };
  win10gpu_config = import ./vms/win10gpu.nix { inherit nvram_path; inherit pkgs; uuid = "3af8cded-1545-4ff2-87d6-d647119aa0e3"; };

  # Kubernetes Nodes
  node1_config = import ./vms/node.nix { inherit pkgs; uuid = "7fdb457d-0417-4156-95fa-92b9187219ac"; nodeID = "1"; inherit disk_path; };
  node2_config = import ./vms/node.nix { inherit pkgs; uuid = "8b302b1d-2055-4d60-8b98-24f375de218f"; nodeID = "2"; inherit disk_path; };
  node3_config = import ./vms/node.nix { inherit pkgs; uuid = "47847aa8-231c-4e52-9aae-fc7f4178d736"; nodeID = "3"; inherit disk_path; };
in
{
  virtualisation.libvirtd.hooks.qemu = {
    "toggle_gpu" = "${toggle_gpu}/bin/toggle_gpu";
  };

  virtualisation.libvirt.enable = true;
  virtualisation.libvirt.connections."qemu:///system" = {
    # Add pools
    pools = [
      {
        definition = nixvirt.lib.pool.writeXML {
          name = "default";
          uuid = "689ba4f2-da57-43e4-9723-a0551e871c8a";
          type = "dir";
          target = {
            path = "/var/lib/libvirt/images";
          };
        };
      }
      {
        definition = nixvirt.lib.pool.writeXML {
          name = "images";
          uuid = "464a4f52-bbf4-479e-9b2b-ed27116aab7b";
          type = "dir";
          target = {
            path = "${disk_path}";
          };
        };
        volumes = [
          {
            definition = nixvirt.lib.volume.writeXML {
              name = "node_1.qcow2";
              capacity = { count = 150; unit = "GiB"; };
              target = {
                format = { type = "qcow2"; };
              };
            };
          }
          {
            definition = nixvirt.lib.volume.writeXML {
              name = "node_2.qcow2";
              capacity = { count = 150; unit = "GiB"; };
              target = {
                format = { type = "qcow2"; };
              };
            };
          }
          {
            definition = nixvirt.lib.volume.writeXML {
              name = "node_3.qcow2";
              capacity = { count = 150; unit = "GiB"; };
              target = {
                format = { type = "qcow2"; };
              };
            };
          }
        ];
        active = true;
      }
      {
        definition = nixvirt.lib.pool.writeXML {
          name = "isos";
          uuid = "5217ddb8-29c2-4a4d-b976-73b9dde59e43";
          type = "dir";
          target = {
            path = "/home/sven/.local/share/libvirt/isos";
          };
        };
        active = true;
      }
    ];

    # Add windows Domain
    domains = [
      { definition = nixvirt.lib.domain.writeXML win10gpu_config; }
      { definition = nixvirt.lib.domain.writeXML win10_config; }
      { definition = nixvirt.lib.domain.writeXML node1_config; }
      { definition = nixvirt.lib.domain.writeXML node2_config; }
      { definition = nixvirt.lib.domain.writeXML node3_config; }
    ];
  };
}
