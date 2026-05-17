{ pkgs, ... }:

{

  cachix.enable = false;

  android = {
    enable = true;
    platformTools.version = "36.0.0";
    systemImages.enable = false;
    flutter = {
      enable = true;
      package = pkgs.flutter335;
    };
  };

  packages = [
    pkgs.firebase-tools
    pkgs.chromium
    pkgs.chromedriver
  ];

  enterShell = ''
    export CHROME_EXECUTABLE=${pkgs.chromium}/bin/chromium
    export PATH=$PATH:$HOME/.pub-cache/bin
  '';

}
