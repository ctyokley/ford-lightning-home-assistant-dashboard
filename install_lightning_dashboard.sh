#!/usr/bin/env bash
set -euo pipefail

echo "Ford Lightning Dashboard Installer"
echo "----------------------------------"
echo

read -rp "Enter your FordPass VIN: " VIN_INPUT

VIN_LOWER="$(echo "$VIN_INPUT" | tr '[:upper:]' '[:lower:]')"
VIN_UPPER="$(echo "$VIN_INPUT" | tr '[:lower:]' '[:upper:]')"

if [ -z "$VIN_LOWER" ]; then
  echo "VIN cannot be blank."
  exit 1
fi

echo
echo "Using:"
echo "  VIN lower: $VIN_LOWER"
echo "  VIN upper: $VIN_UPPER"
echo

mkdir -p /config/packages
mkdir -p /config/dashboards

copy_template() {
  SRC="$1"
  DEST="$2"

  if [ ! -f "$SRC" ]; then
    echo "Skipping missing template: $SRC"
    return
  fi

  cp "$SRC" "$DEST"

  sed -i "s/{{VIN_LOWER}}/$VIN_LOWER/g" "$DEST"
  sed -i "s/{{VIN_UPPER}}/$VIN_UPPER/g" "$DEST"

  echo "Created: $DEST"
}

copy_template "/config/lightning_export/packages/ford_lightning_climate_buttons.yaml.template" \
              "/config/packages/ford_lightning_climate_buttons.yaml"

copy_template "/config/lightning_export/packages/ford_lightning_tires.yaml.template" \
              "/config/packages/ford_lightning_tires.yaml"

copy_template "/config/lightning_export/dashboards/lightning_clean.yaml.template" \
              "/config/dashboards/lightning_clean.yaml"

echo
echo "Install complete."
echo
echo "Next steps:"
echo "1. Go to Home Assistant > Developer Tools > YAML."
echo "2. Check configuration."
echo "3. Restart Home Assistant if the check passes."
echo "4. Add /config/dashboards/lightning_clean.yaml as a YAML dashboard if needed."
