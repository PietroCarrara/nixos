{ lib, stdenv, requireFile, dpkg, xorg, libGL, alsa-lib, pulseaudio, udev }:

stdenv.mkDerivation rec {
  pname = "dungeondraft";
  version = "1.1.0.6";

  src = requireFile {
    name = "Dungeondraft-${version}-Linux64.deb";
    url = "https://dungeondraft.net/";
    hash = "sha256-ffT2zOQWKb6W6dQGuKbfejNCl6dondo4CB6JKTReVDs=";
  };

  nativeBuildInputs = [ dpkg ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp -R usr/share opt $out/
    substituteInPlace \
      $out/share/applications/Dungeondraft.desktop \
      --replace-fail /opt/ $out/opt/
    ln -s $out/opt/Dungeondraft/Dungeondraft.x86_64 $out/bin/Dungeondraft.x86_64
    runHook postInstall
  '';
  preFixup = let
    libPath = lib.makeLibraryPath [
      xorg.libXcursor
      xorg.libXinerama
      xorg.libXrandr
      xorg.libX11
      xorg.libXi
      xorg.libXext
      xorg.libXrender
      libGL
      alsa-lib
      pulseaudio
      udev
    ];
  in ''
    patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${libPath}" \
      $out/opt/Dungeondraft/Dungeondraft.x86_64
  '';

  meta = with lib; {
    homepage = "https://dungeondraft.net/";
    description =
      "Mapmaking tool for Tabletop Roleplaying Games, designed for battle maps, dungeons, and even small hamlets";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
