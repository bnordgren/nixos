{dhcp, configFile, interfaces}:

let

  stateDir = "/var/lib/dhcp"; # Don't use /var/state/dhcp; not FHS-compliant.

in
  
{
  name = "dhcpd";
  
  job = "
description \"DHCP server\"

start on network-interfaces/started
stop on network-interfaces/stop

script
    exec ${dhcp}/sbin/dhcpd -f -cf ${configFile} \\
        -lf ${stateDir}/dhcpd.leases \\
        ${toString interfaces}
end script
  ";
  
}
