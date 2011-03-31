# Upstart jobs for libvirtd.

{ config, pkgs, ... }:

with pkgs.lib;

let 

  cfg = config.virtualisation.libvirtd; 

in

{
  ###### interface

  options = {

    virtualisation.libvirtd.enable = 
      mkOption {
        default = false;
        description =
          ''
            This option enables libvirtd, a daemon that manages
            virtual machines.  You can interact with the daemon
            (e.g. to start or stop VMs) using the
            <command>virsh</command> command line tool, among others.
          '';
      };

    virtualisation.libvirtd.enableKVM = 
      mkOption {
        default = true;
        description =
          ''
            This option enables support for QEMU/KVM in libvirtd.
          '';
      };

  };


  ###### implementation

  config = mkIf cfg.enable {

    environment.systemPackages = 
      [ pkgs.libvirt ]
       ++ optional cfg.enableKVM pkgs.qemu_kvm;

    boot.kernelModules = [ "tun" ];

    jobs.libvirtd =
      { description = "Libvirtd virtual machine management daemon";

        startOn = "stopped udevtrigger";

        path =
          [ pkgs.bridge_utils pkgs.dmidecode pkgs.dnsmasq
            pkgs.ebtables
          ] ++ optional cfg.enableKVM pkgs.qemu_kvm;

        preStart = 
          ''
            mkdir -p /var/log/libvirt/qemu -m 755
            rm -f /var/run/libvirtd.pid

            mkdir -p /var/lib/libvirt -m 700
            mkdir -p /var/lib/libvirt/dnsmasq -m 700

            # Libvirt unfortunately writes mutable state (such as
            # runtime changes to VM, network or filter configurations)
            # to /etc.  So we can't use environment.etc to make the
            # default network and filter definitions available, since
            # libvirt will then modify the originals in the Nix store.
            # So here we copy them instead.  Ugly.
            for i in $(cd ${pkgs.libvirt}/etc && echo \
                libvirt/qemu/networks/*.xml libvirt/qemu/networks/autostart/*.xml \
                libvirt/nwfilter/*.xml );
            do
                mkdir -p /etc/$(dirname $i) -m 755
                cp -fpd ${pkgs.libvirt}/etc/$i /etc/$i
            done
          ''; # */

        exec = "${pkgs.libvirt}/sbin/libvirtd --daemon --verbose";

        daemonType = "daemon";
      };

    jobs.libvirt_guests =
      { name = "libvirt-guests";
      
        description = "Job to save/restore libvirtd VMs";

        startOn = "started libvirtd";

        # We want to suspend VMs only on shutdown, but Upstart is broken.
        #stopOn = "starting shutdown and stopping libvirtd";
        stopOn = "stopping libvirtd";

        path = [ pkgs.gettext pkgs.libvirt pkgs.gawk ];

        preStart = 
          ''
            mkdir -p /var/lock/subsys -m 755
            ${pkgs.libvirt}/etc/rc.d/init.d/libvirt-guests start
          '';

        postStop = "${pkgs.libvirt}/etc/rc.d/init.d/libvirt-guests stop";
      };

  };

}
