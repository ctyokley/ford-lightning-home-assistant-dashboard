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

SLIDER_JS_NAME="lightning-temp-slider-card.js"
SLIDER_JS_URL="/local/${SLIDER_JS_NAME}"
SLIDER_JS_VERSION="$(date +%Y%m%d%H%M%S)"
SLIDER_JS_URL_VERSIONED="${SLIDER_JS_URL}?v=${SLIDER_JS_VERSION}"

HA_API_BASE="http://supervisor/core/api"

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

install_lovelace_resource() {
  echo
  echo "===== Configuring Lovelace frontend resource ====="

  if [ -z "${SUPERVISOR_TOKEN:-}" ]; then
    echo "WARNING: SUPERVISOR_TOKEN is not available."
    echo "Cannot automatically add Lovelace resource."
    echo
    echo "Add this manually:"
    echo "  URL: ${SLIDER_JS_URL_VERSIONED}"
    echo "  Type: JavaScript module"
    return 0
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "WARNING: jq is not installed. Cannot automatically inspect/update Lovelace resources."
    echo
    echo "Add this manually:"
    echo "  URL: ${SLIDER_JS_URL_VERSIONED}"
    echo "  Type: JavaScript module"
    return 0
  fi

  local resources_json
  resources_json="$(curl -s \
    -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
    -H "Content-Type: application/json" \
    "${HA_API_BASE}/config/lovelace/resources" || true)"

  if ! echo "$resources_json" | jq . >/dev/null 2>&1; then
    echo "WARNING: Could not read Lovelace resources from Home Assistant API."
    echo
    echo "Response was:"
    echo "$resources_json"
    echo
    echo "Add this manually:"
    echo "  URL: ${SLIDER_JS_URL_VERSIONED}"
    echo "  Type: JavaScript module"
    return 0
  fi

  local existing_id
  existing_id="$(echo "$resources_json" | jq -r \
    --arg base "$SLIDER_JS_URL" \
    '.[] | select((.url | split("?")[0]) == $base) | .id' | head -n 1)"

  if [ -n "$existing_id" ] && [ "$existing_id" != "null" ]; then
    echo "Existing Lovelace resource found. Updating cache-busted URL..."
    curl -s -X PUT \
      -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"res_type\":\"module\",\"url\":\"${SLIDER_JS_URL_VERSIONED}\"}" \
      "${HA_API_BASE}/config/lovelace/resources/${existing_id}" >/dev/null

    echo "Updated Lovelace resource:"
    echo "  ${SLIDER_JS_URL_VERSIONED}"
  else
    echo "No existing Lovelace resource found. Creating it..."
    curl -s -X POST \
      -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"res_type\":\"module\",\"url\":\"${SLIDER_JS_URL_VERSIONED}\"}" \
      "${HA_API_BASE}/config/lovelace/resources" >/dev/null

    echo "Added Lovelace resource:"
    echo "  ${SLIDER_JS_URL_VERSIONED}"
  fi
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

install_lovelace_resource

echo
echo "===== Checking Home Assistant YAML config ====="

if curl -s \
  -H "Authorization: Bearer ${SUPERVISOR_TOKEN:-}" \
  -H "Content-Type: application/json" \
  -X POST \
  "${HA_API_BASE}/config/core/check_config" >/dev/null 2>&1; then
  echo "Home Assistant config check requested."
else
  echo "Could not request config check automatically."
fi

echo
echo "============================================"
echo " Install complete"
echo "============================================"
echo
echo "Next steps:"
echo
echo "1. Make sure this exists in /config/configuration.yaml:"
echo
echo "   homeassistant:"
echo "     packages: !include_dir_named packages"
echo
echo "2. Restart Home Assistant."
echo
echo "3. Hard refresh the browser or fully close/reopen the mobile app."
echo
echo "4. If the custom slider still does not load, verify this resource exists:"
echo
echo "   Settings > Dashboards > Three-dot menu > Resources"
echo
echo "   ${SLIDER_JS_URL_VERSIONED}"
echo
