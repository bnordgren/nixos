{ path, thisConfig, config, lib, pkgs, upstartHelpers } : with upstartHelpers; {
  options = {
    description = "synergy client lets you use a shared keyboard, mouse and clipboard";

    configuration = mkOption {
      description = "
        The synergy server configuration file
      ";
    };
    screenName = mkOption {
      default = "";
      description = " 
        use screen-name instead the hostname to identify
        this screen in the configuration.
        ";
      apply = x: "-n '${x}'";
    };
    address = mkOption {
      default = "";
      description = "listen for clients on the given address";
      apply = x: "-a '${x}'";
    };
  };

  jobs =
    [ ( rec {
      name = "synergys";

      extraEtc = [ (autoGeneratedEtcFile { name = name + ".conf"; content = thisConfig.configuration; }) ];

      # TODO start only when X Server has started as well
  job = "
description \"${name}\"

start on network-interfaces/started and xserver/started
stop on network-interfaces/stop or xserver/stop

exec ${pkgs.synergy}/bin/synergys -c /etc/${name}.conf -f ${configV "address"} ${configV "screenName"}
  ";
  
} ) ];
}

/* Example configuration

section: screens
  laptop:
  dm:
  win:
end
section: aliases
    laptop: 
      192.168.5.5
    dm:
      192.168.5.78
    win:
      192.168.5.54
end
section: links
   laptop:
       left = dm
   dm:
       right = laptop
       left = win
  win:
      right = dm
end

*/
