{ pkgs, ... }:

{

  cachix.enable = false;

  android = {
    enable = true;
    flutter.enable = true;
  };

  packages = [
    pkgs.firebase-tools
  ];

}
