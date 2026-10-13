{ pkgs, ... }:

let
  userData = pkgs.writeText "fedora-user-data" (
    "#cloud-config\n"
    + builtins.toJSON {
      hostname = "nate";
      ssh_deletekeys = false;
      users = [
        {
          name = "armbordy";
          groups = [ "wheel" ];
          shell = "/bin/bash";
          sudo = "ALL=(ALL) NOPASSWD:ALL";
          lock_passwd = true;
          ssh_authorized_keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICaC4wtRMqCAI1T+tFahIwDWM8AWlgLDsHV0yEPUb7nK armbordy@armbordy-Inspiron-14-5430"
            "cert-authority,principals=\"t:human,h:nate\" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuc4HCdyEMu4uiYhlokSXmu+68hkm7j6CqVwjDkCeSj grace.pink"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINySDE+jaYpuAWUdPQf/JcAWETeHgmh+T5Y4GUa7MfeM grace@turing"
          ];
        }
      ];
    }
  );
  metadata = pkgs.writeText "fedora-meta-data" ''
    instance-id: fedora-nate-v1
    local-hostname: nate
  '';
  network = pkgs.writeText "default-network.xml" ''
    <network>
      <name>default</name>
      <forward mode='nat'/>
      <bridge name='virbr0' stp='on' delay='0'/>
      <ip address='192.168.122.1' netmask='255.255.255.0'>
        <dhcp><range start='192.168.122.2' end='192.168.122.254'/></dhcp>
      </ip>
    </network>
  '';
  domain = pkgs.writeText "fedora.xml" ''
    <domain type='kvm'>
      <name>fedora</name>
      <uuid>8ffbe0a2-839d-4f5b-8c9a-feb18edf9043</uuid>
      <memory unit='MiB'>4096</memory>
      <vcpu>4</vcpu>
      <os><type arch='x86_64' machine='q35'>hvm</type><boot dev='hd'/></os>
      <features><acpi/><apic/></features>
      <cpu mode='host-passthrough'/>
      <on_reboot>restart</on_reboot>
      <devices>
        <emulator>/run/libvirt/nix-emulators/qemu-system-x86_64</emulator>
        <disk type='file' device='disk'>
          <driver name='qemu' type='qcow2'/>
          <source file='/var/lib/libvirt/images/fedora.qcow2'/>
          <target dev='vda' bus='virtio'/>
        </disk>
        <disk type='file' device='cdrom'>
          <driver name='qemu' type='raw'/>
          <source file='/var/lib/libvirt/boot/fedora-cloud-init.iso'/>
          <target dev='sda' bus='sata'/><readonly/>
        </disk>
        <interface type='network'>
          <mac address='52:54:00:06:fa:d8'/>
          <source network='default'/><model type='virtio'/>
        </interface>
        <serial type='pty'><target port='0'/></serial>
        <console type='pty'><target type='serial' port='0'/></console>
        <channel type='unix'><target type='virtio' name='org.qemu.guest_agent.0'/></channel>
        <graphics type='spice' autoport='yes'><listen type='address' address='127.0.0.1'/></graphics>
        <video><model type='virtio'/></video>
        <rng model='virtio'><backend model='random'>/dev/urandom</backend></rng>
      </devices>
    </domain>
  '';
in
{
  systemd.tmpfiles.rules = [
    "d /var/lib/libvirt/images 0755 root root -"
    "d /var/lib/libvirt/boot 0755 root root -"
  ];

  systemd.services.fedora-vm = {
    description = "Declare and start the Fedora VM";
    wantedBy = [ "multi-user.target" ];
    requires = [ "libvirtd.service" ];
    after = [ "libvirtd.service" ];
    restartTriggers = [
      domain
      userData
      metadata
    ];
    unitConfig.ConditionPathExists = "/var/lib/libvirt/images/fedora.qcow2";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [
      pkgs.libvirt
      pkgs.cdrkit
      pkgs.coreutils
      pkgs.gnugrep
    ];
    script = ''
      set -eu
      virsh() { command virsh --connect qemu:///system "$@"; }
      if ! virsh net-info default >/dev/null 2>&1; then
        virsh net-define ${network}
      fi
      virsh net-autostart default
      if ! virsh net-info default | grep -q 'Active:.*yes'; then
        virsh net-start default
      fi
      seed=$(mktemp -d)
      trap 'rm -rf "$seed"' EXIT
      cp ${userData} "$seed/user-data"
      cp ${metadata} "$seed/meta-data"
      genisoimage -quiet -output /var/lib/libvirt/boot/fedora-cloud-init.iso.new \
        -volid cidata -joliet -rock "$seed/user-data" "$seed/meta-data"
      mv /var/lib/libvirt/boot/fedora-cloud-init.iso.new /var/lib/libvirt/boot/fedora-cloud-init.iso
      virsh define ${domain}
      virsh autostart fedora
      if ! virsh list --name | grep -qx fedora; then
        virsh start fedora
      fi
    '';
  };
}
