#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo " Ford Lightning Home Assistant Dashboard"
echo " Installer"
echo "============================================"
echo

EXPORT_ROOT="/config/lightning_export"
PACKAGES_DIR="/config/packages"
DASHBOARDS_DIR="/config/dashboards"
WWW_DIR="/config/www"

VIN_UPPER="${VIN_UPPER:-}"
VIN_LOWER="${VIN_LOWER:-}"

if [ -z "$VIN_UPPER" ]; then
  echo "Enter your FordPass VIN in uppercase or lowercase:"
  read -r VIN_INPUT
  VIN_UPPER="$(echo "$VIN_INPUT" | tr '[:lower:]' '[:upper:]')"
  VIN_LOWER="$(echo "$VIN_INPUT" | tr '[:upper:]' '[:lower:]')"
fi

if [ -z "$VIN_LOWER" ]; then
  VIN_LOWER="$(echo "$VIN_UPPER" | tr '[:upper:]' '[:lower:]')"
fi

echo
echo "Using VIN_UPPER: $VIN_UPPER"
echo "Using VIN_LOWER: $VIN_LOWER"
echo

mkdir -p "$PACKAGES_DIR"
mkdir -p "$DASHBOARDS_DIR"
mkdir -p "$WWW_DIR"

copy_template() {
  local src="$1"
  local dst="$2"

  if [ ! -f "$src" ]; then
    echo "WARNING: Missing template: $src"
    return 0
  fi

  if [ -f "$dst" ]; then
    cp "$dst" "$dst.backup-$(date +%Y%m%d-%H%M%S)"
  fi

  cp "$src" "$dst"

  sed -i "s/{{VIN_LOWER}}/${VIN_LOWER}/g" "$dst"
  sed -i "s/{{VIN_UPPER}}/${VIN_UPPER}/g" "$dst"

  echo "Installed: $dst"
}

echo "===== Installing package files ====="

copy_template "$EXPORT_ROOT/packages/ford_lightning_climate_buttons.yaml.template" \
              "$PACKAGES_DIR/ford_lightning_climate_buttons.yaml"

copy_template "$EXPORT_ROOT/packages/ford_lightning_tires.yaml.template" \
              "$PACKAGES_DIR/ford_lightning_tires.yaml"

echo
echo "===== Installing dashboard file ====="

copy_template "$EXPORT_ROOT/dashboards/lightning_clean.yaml.template" \
              "$DASHBOARDS_DIR/lightning_clean.yaml"

echo
echo "===== Installing custom frontend assets ====="

if [ -f "$EXPORT_ROOT/www/lightning-temp-slider-card.js" ]; then
  cp "$EXPORT_ROOT/www/lightning-temp-slider-card.js" \
     "$WWW_DIR/lightning-temp-slider-card.js"
  echo "Installed: $WWW_DIR/lightning-temp-slider-card.js"
else
  echo "WARNING: Missing $EXPORT_ROOT/www/lightning-temp-slider-card.js"
fi

if [ -f "$EXPORT_ROOT/www/lightning_temp_gradient.svg" ]; then
  cp "$EXPORT_ROOT/www/lightning_temp_gradient.svg" \
     "$WWW_DIR/lightning_temp_gradient.svg"
  echo "Installed: $WWW_DIR/lightning_temp_gradient.svg"
fi

echo
echo "============================================"
echo " Install complete"
echo "============================================"
echo
echo "Next steps:"
echo
echo "1. Make sure this is in configuration.yaml:"
echo
echo "   homeassistant:"
echo "     packages: !include_dir_named packages"
echo
echo "2. Add this Lovelace resource in Home Assistant:"
echo
echo "   URL: /local/lightning-temp-slider-card.js?v=$(date +%Y%m%d%H%M%S)"
echo "   Type: JavaScript module"
echo
echo "   UI path:"
echo "   Settings > Dashboards > Three-dot menu > Resources > Add Resource"
echo
echo "3. Restart Home Assistant."
echo
echo "4. Hard refresh the browser or fully close/reopen the mobile app."
echo
