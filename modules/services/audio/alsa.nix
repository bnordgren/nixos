# ALSA sound support.
{pkgs, config, ...}:

let
  inherit (pkgs.lib) mkOption singleton mkIf;

  inherit (pkgs) alsaUtils;

  soundState = "/var/lib/alsa/asound.state";

in

{

  ###### interface
  
  options = {
  
    sound = {

      enable = mkOption {
        default = true;
        description = ''
          Whether to enable ALSA sound.
        '';
        merge = pkgs.lib.mergeEnableOption;
      };

    };
    
  };


  ###### implementation
  
  config = mkIf config.sound.enable {
  
    environment.systemPackages = [alsaUtils];

    users.extraGroups = singleton
      { # Alsalib seems to require the existence of this group, even
        # if it's not used (e.g., doesn't own any devices).
        name = "audio";
        gid = config.ids.gids.audio;
      };

    jobs = singleton
      { name = "alsa";

        startOn = "udev";

        preStart =
          ''
            mkdir -m 0755 -p $(dirname ${soundState})

            # Load some additional modules.
            for mod in snd_pcm_oss; do
                ${config.system.sbin.modprobe}/sbin/modprobe $mod || true
            done

            # Restore the sound state.
            ${alsaUtils}/sbin/alsactl -f ${soundState} restore
          '';

        postStop =
          ''
            # Save the sound state.
            ${alsaUtils}/sbin/alsactl -f ${soundState} store
          '';
      };
      
  };

}