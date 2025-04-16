## scripts/client/generate-config.sh
#!/bin/sh
# Get the server hostname from environment or use default
SERVER_HOST="${SERVER_HOST:-app}"
SERVER_PORT="${SERVER_PORT:-43594}"
JS5_PORT="${JS5_PORT:-43593}"
WL_PORT="${WL_PORT:-5555}"
WORLD="${WORLD:-1}"

# Create the config directory if it does not exist
mkdir -p /home/${USER_NAME}/.config/09launcher

# Generate the config.json file with the correct server address
cat > /home/${USER_NAME}/.config/09launcher/config.json << EOF
{
  "ip_address": "$SERVER_HOST",
  "ip_management": "$SERVER_HOST",
  "server_port": $SERVER_PORT,
  "wl_port": $WL_PORT,
  "js5_port": $JS5_PORT,
  "world": $WORLD,
  "customization": {
    "login_theme": "scape main",
    "right_click_menu": {
      "background": {
        "color": "#5D5447",
        "opacity": "255"
      },
      "title_bar": {
        "color": "#000000",
        "opacity": "255",
        "font_color": "#FFFFFF"
      },
      "border": {
        "color": "#FFFFFF",
        "opacity": "255"
      },
      "styles": {
        "Presets provide default customizations.": "rs3, classic, or custom. custom allows you to define your own values above. Classic is standard 2009.",
        "presets": "custom",
        "rs3border": false
      }
    },
    "xpdrops": {
      "enabled": true,
      "drop_mode": 0,
      "track_mode": 0
    },
    "slayer": {
      "enabled": true,
      "color": "#635a38",
      "opacity": "180"
    },
    "rendering_options": {
      "technical": {
        "render_distance_increase": true
      },
      "skybox": {
        "skybox_color": "Coming in a future update..."
      }
    }
  },
  "debug": {
    "item_debug": false,
    "object_debug": false,
    "npc_debug": false,
    "hd_login_region_debug": false,
    "hd_login_region_debug_verbose": false,
    "cache_debug": false,
    "world_map_debug": false
  }
}
EOF

# Ensure correct ownership of the config file
chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/.config

echo "Generated config.json with server address: $SERVER_HOST:$SERVER_PORT"