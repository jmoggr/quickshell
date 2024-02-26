{ pkgs ? import <nixpkgs> {} }: let
  tidyfox = import (pkgs.fetchFromGitea {
    domain = "git.outfoxxed.me";
    owner = "outfoxxed";
    repo = "tidyfox";
    rev = "1f062cc198d1112d13e5128fa1f2ee3dbffe613b";
    sha256 = "kbt0Zc1qHE5fhqBkKz8iue+B+ZANjF1AR/RdgmX1r0I=";
  }) {};
in pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    just
    clang-tools_17
    parallel
    cmake

    pkg-config
    wayland-scanner

    qt6.wrapQtAppsHook
    makeWrapper
  ];

  buildInputs = with pkgs; [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtwayland
    wayland
    wayland-protocols
  ];

  QTWAYLANDSCANNER = "${pkgs.qt6.qtwayland}/libexec/qtwaylandscanner";
  TIDYFOX = "${tidyfox}/lib/libtidyfox.so";

  shellHook = ''
    export CMAKE_BUILD_PARALLEL_LEVEL=$(nproc)

    # Add Qt-related environment variables.
    # https://discourse.nixos.org/t/qt-development-environment-on-a-flake-system/23707/5
    setQtEnvironment=$(mktemp)
    random=$(openssl rand -base64 20 | sed "s/[^a-zA-Z0-9]//g")
    makeWrapper "$(type -p sh)" "$setQtEnvironment" "''${qtWrapperArgs[@]}" --argv0 "$random"
    sed "/$random/d" -i "$setQtEnvironment"
    source "$setQtEnvironment"

    # qmlls does not account for the import path and bases its search off qtbase's path.
    # The actual imports come from qtdeclarative. This directs qmlls to the correct imports.
    export QMLLS_BUILD_DIRS=$(pwd)/build:$QML2_IMPORT_PATH
  '';
}
