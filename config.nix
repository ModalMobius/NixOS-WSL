{ config, lib, pkgs, ... }:

{
    imports = [ <nixos-wsl/modules> ];
    wsl.enable = true;
    wsl.defaultUser = "nixos";

    system.stateVersion = "23.11";

    nix = {
        settings = {
            experimental-features = [
                "nix-command"
                "flakes"
            ];
            substituters = [
                "https://nix-community.cachix.org"
            ];
            trusted-public-keys = [
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            ];
        };
        gc = {
            automatic = true;
                dates = "weekly";
                options = "--delete-older-than 7d";
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
    environment.packages = with pkgs; [
        nixFlakes
        vscode-with-extensions
    ];
}