with import <nixpkgs> {};
let
  desktopItem = makeDesktopItem {
    type = "Application";
    name = "Notion";
    desktopName = "Notion";
    exec = "notion-desktop";
    icon = "notion-app";
    mimeType = "x-scheme-handler/notion";
    categories = "Office;Utility;";
    startupNotify = true;
    comment = "The all-in-one workspace for your notes and tasks";
  };
in
stdenv.mkDerivation {
  pname = "notion-desktop";
  version = "2.0.15";
  src = ./build/build-2.0.15-0-x64/notion-desktop-linux-x64/resources;
  nativeBuildInputs = [ makeWrapper ];
  patches = [ ./arpr.patch ];
  installPhase = ''
    mkdir -p $out/{bin,lib}
    cp -r ./app/ $out/lib
    makeWrapper ${electron_11}/bin/electron $out/bin/notion-desktop --add-flags $out/lib/app/
    install -Dm644 \
      ${desktopItem}/share/applications/Notion.desktop \
      $out/share/applications/Notion.desktop
    install -Dm644 app/icon.png $out/share/pixmaps/notion-app.png
  '';
  meta = with lib; {
    homepage = "https://notion.so/";
    downloadPage = "https://www.notion.so/desktop";
    description = "The all-in-one workspace for your notes and tasks";
    license = licenses.unfree;
    maintainers = with maintainers; [ yorickvp ];
    platforms = platforms.linux;
  };
}
