{ lib, stdenv, fetchFromGitHub, kernel }:

stdenv.mkDerivation {
  pname = "snd-rane-sl3";
  version = "unstable-2024-01-01";

  src = fetchFromGitHub {
    owner = "nvgeele";
    repo = "snd-rane-sl3";
    rev = "01099892261b55ec5ee814292d840eeb664c1904";
    hash = "sha256-kW7b8HWmlo5YaDjo8XIxj0CcVT5L8v/ngyiu2otVSsg=";
  };

  sourceRoot = "source/snd-rane-sl3";

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  installPhase = ''
    install -D snd-rane-sl3.ko $out/lib/modules/${kernel.modDirVersion}/kernel/sound/usb/snd-rane-sl3.ko
  '';

  meta = {
    description = "Kernel module for Rane/Serato SL3 USB audio interface";
    homepage = "https://github.com/nvgeele/snd-rane-sl3";
    license = lib.licenses.gpl2Only;
    maintainers = [];
  };
}
