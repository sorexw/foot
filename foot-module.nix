{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.foot;

  settingsFormat = pkgs.formats.ini {
    listsAsDuplicateKeys = true;
    mkKeyValue =
      with lib.generators;
      mkKeyValueDefault {
        mkValueString =
          v:
          mkValueStringDefault { } (
            if v == true then "yes"
            else if v == false then "no"
            else if v == null then "none"
            else v
          );
      } "=";
  };
in
{
  options.programs.foot = {
    enable = lib.mkEnableOption "foot terminal emulator";
    package = lib.mkPackageOption pkgs "foot" { };

    settings = lib.mkOption {
      inherit (settingsFormat) type;
      default = { };
      description = "Configuration for foot terminal emulator.";
    };

    xdg = {
      serverAutostart = lib.mkEnableOption "starting the foot server via xdg-autostart";
    };

    theme = {
      name = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = "Name of the theme to apply.";
        example = "kanagawa-wave";
      };

      repository = lib.mkOption {
        type = with lib.types; either path package;
        default = ./themes;
        description = "Path or derivation containing the themes.";
      };
    };

    enableBashIntegration = lib.mkEnableOption "foot bash integration" // { default = true; };
    enableFishIntegration = lib.mkEnableOption "foot fish integration" // { default = true; };
    enableZshIntegration = lib.mkEnableOption "foot zsh integration" // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    environment = lib.mkMerge [
      {
        systemPackages = [ cfg.package ];
        etc."xdg/foot/foot.ini".source = settingsFormat.generate "foot.ini" cfg.settings;
      }
      (lib.mkIf cfg.xdg.serverAutostart {
        etc."xdg/autostart/foot-server.desktop".source =
          "${cfg.package}/share/applications/foot-server.desktop";
      })
    ];

    programs = {
      foot.settings.main.include = lib.optionals (cfg.theme.name != null) [
        "${cfg.theme.repository}/${cfg.theme.name}"
      ];

      bash.interactiveShellInit = lib.mkIf cfg.enableBashIntegration ". ${./bashrc} # enable shell integration";
      fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration "source ${./config.fish} # enable shell integration";
      zsh.interactiveShellInit = lib.mkIf cfg.enableZshIntegration ". ${./zshrc} # enable shell integration";
    };
  };
}
