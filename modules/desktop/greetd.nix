{ pkgs, lib, config, ... }: {
  services.greetd = {
    enable = true;
    settings.default_session =
      # Auto-Login für VM (proxmox-vm), manueller Login für andere Hosts
      if config.networking.hostName == "proxmox-vm" then {
        command = "Hyprland";
        user = "preto";
      } else {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
  };
}
