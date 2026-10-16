{ inputs, pkgs, ... }: {

  programs.vscode = {
    enable = true;

    profiles.default = {

      # colours and fonts come from Stylix (theme "Stylix")
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        pkief.material-icon-theme
      ];

      userSettings = {
        "editor.fontLigatures" = true;
        "workbench.iconTheme" = "material-icon-theme";
        "editor.tabSize" = 2;
        "telemetry.telemetryLevel" = "off";
        "files.autoSave" = "afterDelay";
        "files.autoSaveDelay" = 1000;
        "editor.mouseWheelZoom" = true;
        "security.workspace.trust.enabled" = false;
        "workbench.layoutControl" = true;
        "window.dialogStyle" = "modern";
        "workbench.activityBar.location" = "side";
        "workbench.experimental.modernUIEditorTabStyle" = "modern";
        "workbench.editor.showTabs" = "multiple";
        "window.titleBarStyle" = "custom";
        "window.menuBarVisibility" = "toggle";
        "mutableExtensionsDir" = false;
        "settingsSync.keybindings" = false;
      };
    };
  };

}
