# This Nix expression builds the script that performs the first stage
# of booting the system: it loads the modules necessary to mount the
# root file system, then calls /init in the root file system to start
# the second boot stage.  The closure of the result of this expression
# is supposed to be put into an initial RAM disk (initrd).

{genericSubstituter, shell, staticTools}:

genericSubstituter {
  src = ./boot-stage-1-init.sh;
  isExecutable = true;
  inherit shell;
  path = [
    staticTools
  ];
  makeDevices = ./make-devices.sh;
}
