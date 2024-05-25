{ config, lib, pkgs, ... }:

{
  imports = [ <nixos-wsl/modules> ];
  wsl.enable = true;
  wsl.defaultUser = "nixos";
  system.stateVersion = "23.11";
  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };
    gc = {
      automatic = true;
      dates = "daily";
      options = "-d";
    };
  };
  networking.hostName = "wsl";
  systemd = {
    services.clear-log = {
      description = "Clear 1> day-old logs";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/journalctl --vacuum-time=1d";
      };
    };
    timers.clear-log = {
      wantedBy = [ "timers.target" ];
      partOf = [ "clear-log.service" ];
      timerConfig.OnCalendar = "daily UTC";
    };
  };
  environment.systemPackages = with pkgs; [
    nixFlakes
    git
    (vscode-with-extensions.override {
       vscodeExtensions = with vscode-extensions; [
         svelte.svelte-vscode
         arcticicestudio.nord-visual-studio-code
       ]
    })
  ];
  environment.variables = {
    DONT_PROMPT_WSL_INSTALL = "1";
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
 };
}
