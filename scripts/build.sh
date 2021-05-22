#!/bin/bash
set -e

# shellcheck disable=SC1091
source scripts/_variables-1.sh

usage() {
  echo "usage: $0 [ -b BUILD_ARCH ]"
  exit 1
}

while getopts "b:" options; do
  case $options in
    b)
      BUILD_ARCH=$OPTARG
      ;;
    *)
      usage
      ;;
  esac
done

# shellcheck disable=SC1091
source scripts/_variables-2.sh

check-command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo Missing command: "$1"
    exit 1
  fi
}

commands=(node npm 7z convert g++ make)

# Check for required commands
for command in "${commands[@]}"; do
  check-command "$command"
done

# Install NPM dependencies
if ! [ -d node_modules ]; then
  npm install
fi

# Setup working directories
mkdir -p "$RESOURCE_DIR"
mkdir -p "$BUILD_DIR"

# Download Notion executable
if ! [ -f "$RESOURCE_DIR/notion.exe" ]; then
  origin=https://desktop-release.notion-static.com
  wget -nv "$origin/Notion Setup $NOTION_VERSION.exe" -O "$RESOURCE_DIR/notion.exe"
fi

# Extract the Notion executable
if ! [ -f "$RESOURCE_DIR/notion-exe/\$PLUGINSDIR/app-64.7z" ]; then
  7z x "$RESOURCE_DIR/notion.exe" -o"$RESOURCE_DIR/notion-exe"
fi

# Extract the app bundle
if ! [ -d "$RESOURCE_DIR/app-bundle/resources/app" ]; then
  7z x "$RESOURCE_DIR/notion-exe/\$PLUGINSDIR/app-64.7z" -o"$RESOURCE_DIR/app-bundle"
fi

# Extract the app container
if ! [ -d "$BUILD_DIR/app-unpacked" ]; then
    if [ -d "$RESOURCE_DIR/app-bundle/resources/app" ]; then
        cp -r "$RESOURCE_DIR/app-bundle/resources/app" "$BUILD_DIR/app-unpacked"
    else
        asar extract \
"$RESOURCE_DIR/app-bundle/resources/app.asar" "$BUILD_DIR/app-unpacked"
    fi
fi

# Install NPM dependencies and apply patches
if ! [ -f "$BUILD_DIR/app-unpacked/package-lock.json" ]; then
  # Replace package name due to conflicting `notion` package
  sed -i 's/"Notion"/"notion-desktop"/' "$BUILD_DIR/app-unpacked/package.json"

  # Patch to treat the Linux app like the Windows version
  # Adds support for some missing features such as Google/Apple login
  sed -i 's/process\.platform === "win32"/process\.platform === "linux"/g' "$BUILD_DIR/app-unpacked/main/main.js"

  # Remove existing node_modules
  rm -rf "$BUILD_DIR/app-unpacked/node_modules"

  # Configure build settings
  # See https://www.electronjs.org/docs/tutorial/using-native-node-modules
  export npm_config_target=$ELECTRON_VERSION
  export npm_config_arch=$BUILD_ARCH
  export npm_config_target_arch=$BUILD_ARCH
  export npm_config_disturl=https://electronjs.org/headers
  export npm_config_runtime=electron
  export npm_config_build_from_source=true

  HOME=~/.electron-gyp npm install --prefix "$BUILD_DIR/app-unpacked"
fi

# Convert icon.ico to PNG
if ! [ -f "$BUILD_DIR/app-unpacked/icon.png" ]; then
  convert \
    "$BUILD_DIR/app-unpacked/icon.ico[0]" "$BUILD_DIR/app-unpacked/icon.png"
fi

# Create Electron package
if ! [ -d "$BUILD_DIR/notion-desktop-linux-$BUILD_ARCH" ]; then
  electron-packager "$BUILD_DIR/app-unpacked" \
    --platform linux \
    --arch "$BUILD_ARCH" \
    --out "$BUILD_DIR" \
    --electron-version "$ELECTRON_VERSION"
fi
