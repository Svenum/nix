{ nvram_path, pkgs }:

{
  type = "kvm";
  # VM Infos
  name = "MacOS Nix";
  uuid = "2aca0dd6-cec9-4717-9ab2-0b7b13d111c3";
  description = "A MacOS vm define in nix";

  # CPU and RAM
  vcpu = { count = 4; placement = "static"; };
  memory = { count = 8; unit = "GiB"; };
  cputune = {
    vcpupin = [
      {vcpu = 0; cpuset = "4";}
      {vcpu = 1; cpuset = "5";}
      {vcpu = 2; cpuset = "6";}
      {vcpu = 3; cpuset = "7";}
    ];
  };

  # OS
  os = {
    type = "hvm";
    arch = "x86_64";
    machine = "pc-q35-8.2";
    loader = {
      readonly = true;
      type = "pflash";
      path = "${pkgs.OVMFFull.fd}/FV/OVMF_CODE.ms.fd";
    };
    nvram = {
      template = "${pkgs.OVMFFull.fd}/FV/OVMF_VARS.ms.fd";
      path = "${nvram_path}/macos.nvram";
    };
  };

  features = {
    acpi = {};
    apic = {};
  };
  
  clock = {
    offset = "localtime";
    timer = [
      { name = "rtc"; tickpolicy = "catchup"; }
      { name = "pit"; tickpolicy = "delay"; }
      { name = "hpet"; present = false; }
    ];
  };

  # Devices
  devices = {
    emulator = "${pkgs.qemu}/bin/qemu-system-x86_64";

    # Network
    interface = {
      type = "network";
      mac.address = "52:54:00:04:63:98";
      source.network = "default";
      model.type = "vmxnet3";
    };

    # Video + Audio
    graphics = {
      type = "spice";
      autoport = true;
      listen = { type = "address"; };
      image = { compression = false; };
    };

    video = {
      model = {
        type = "vga";
        vram = 65536;
        heads  = 1;
        primary = true;
      };
    };

    # Interfaces 
    controller = [
      { type = "sata"; index = 0; }
      { type = "pci"; index = 0; model = "pcie-root"; }
      { type = "virtio-serial"; index = 0; }
      { type = "usb"; index = 0; model = "ich9-uhci1"; ports = 15; }
    ];

    serial = [
      {
        type = "pty";
        target = { type = "isa-serial"; port = 0; model.name = "isa-serial"; };
      }
    ];

    console = [
      {
        type = "pty";
        target = { type = "serial"; port = 0; };
      }
    ];

    channel = [
      {
        type = "unix";
        target = {
          type = "virtio";
          name = "org.qemu.guest_agent.0"
        };
      }
    ];

    # Other
    memballoon.model = "none";
  };

  qemu-commandline = {
    arg = [
      { value = "-device" }
      { value = "isa-applesmc,osk=ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" }
      { value = "-smbios" }
      { value = "type=2" }
      { value = "-usb" }
      { value = "-device" }
      { value = "usb-tablet" }
      { value = "-device" }
      { value = "usb-kbd" }
      { value = "-cpu" }
      { value = "Penryn,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,+ssse3,+sse4.2,+popcnt,+avx,+aes,+xsave,+xsaveopt,check" }
    ];
  };
}
