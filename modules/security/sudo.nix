{pkgs, config, ...}:

with pkgs.lib;

let

  cfg = config.security.sudo;

  inherit (pkgs) sudo;

in

{

  ###### interface

  options = {

    security.sudo.enable = mkOption {
      default = true;
      description =
        ''
          Whether to enable the <command>sudo</command> command, which
          allows non-root users to execute commands as root.
        '';
    };

    security.sudo.configFile = mkOption {
      # Note: if syntax errors are detected in this file, the NixOS
      # configuration will fail to build.
      default =
        ''
          # Don't edit this file. Set the NixOS option ‘security.sudo.configFile’ instead.

          # Environment variables to keep for root and %wheel.
          Defaults:root,%wheel env_keep+=LOCALE_ARCHIVE
          Defaults:root,%wheel env_keep+=NIX_PATH
          Defaults:root,%wheel env_keep+=TERMINFO_DIRS

          # Keep SSH_AUTH_SOCK so that pam_ssh_agent_auth.so can do its magic.
          Defaults env_keep+=SSH_AUTH_SOCK

          # "root" is allowed to do anything.
          root        ALL=(ALL) SETENV: ALL

          # Users in the "wheel" group can do anything.
          %wheel      ALL=(ALL) SETENV: ALL
        '';
      description =
        ''
          This string contains the contents of the
          <filename>sudoers</filename> file.
        '';
    };
  };


  ###### implementation

  config = mkIf cfg.enable {

    security.setuidPrograms = [ "sudo" ];

    environment.systemPackages = [ sudo ];

    security.pam.services = [ { name = "sudo"; sshAgentAuth = true; } ];

    environment.etc = singleton
      { source = pkgs.writeText "sudoers-in" cfg.configFile;
          # Make sure that the sudoers file is syntactically valid.
          # (currently disabled - NIXOS-66)
          #"${pkgs.sudo}/sbin/visudo -f $src -c && cp $src $out";
        target = "sudoers";
        mode = "0440";
      };

  };

}
