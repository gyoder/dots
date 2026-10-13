{ pkgs, ... }:

let
  settings = pkgs.writeText "foot.ini" ''
    [main]
    font=JetBrainsMono Nerd Font:size=12
    shell=${pkgs.fish}/bin/fish --login
    pad=12x12

    [colors]
    background=191724
    foreground=e0def4
    regular0=26233a
    regular1=eb6f92
    regular2=31748f
    regular3=f6c177
    regular4=9ccfd8
    regular5=c4a7e7
    regular6=ebbcba
    regular7=e0def4
    bright0=6e6a86
    bright1=eb6f92
    bright2=31748f
    bright3=f6c177
    bright4=9ccfd8
    bright5=c4a7e7
    bright6=ebbcba
    bright7=e0def4
    selection-background=403d52
    selection-foreground=e0def4
  '';
in
{
  hardware.graphics.enable = true;
  security.polkit.enable = true;
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
  environment.etc."foot/foot.ini".source = settings;
  environment.systemPackages = [
    pkgs.cage
    pkgs.foot
    (pkgs.writeShellScriptBin "cage-foot" ''
      exec ${pkgs.cage}/bin/cage -s -- ${pkgs.foot}/bin/foot --config=/etc/foot/foot.ini
    '')
  ];
}
