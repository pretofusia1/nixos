{ config, pkgs, ... }: {
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  i18n.defaultLocale = "de_DE.UTF-8";
  console.keyMap = "de";
  services.xserver.xkb.layout = "de";
  environment.systemPackages = with pkgs; [ git gnupg htop btop wget curl unzip ripgrep fd bat eza nil ];
  fonts = {
    packages = with pkgs; [
      noto-fonts noto-fonts-cjk noto-fonts-emoji
      nerd-fonts.fira-code nerd-fonts.jetbrains-mono
    ];
    enableDefaultPackages = true;
  };
}