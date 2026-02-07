{ pkgs, lib, config, ... }: {
  services.greetd = {
    enable = true;
    settings.default_session =
      # Auto-Login für VM (proxmox-vm), manueller Login für andere Hosts
      if config.networking.hostName == "proxmox-vm" then {
        # WLR_BACKENDS=headless MUSS vor Hyprland-Start gesetzt sein!
        # Hyprland wählt das Backend beim Init, nicht aus der Config.
        command = "WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 Hyprland";
        user = "preto";
      } else {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
  };
}
