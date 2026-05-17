# Ford Lightning Home Assistant Dashboard

Home Assistant dashboard and package templates for a Ford F-150 Lightning using the FordPass integration.

This project includes:

- Ford Lightning dashboard YAML template
- Remote climate control buttons and helper scripts
- Tire pressure sensors and dashboard cards
- VIN placeholders so the config can be reused by other Lightning owners

## Important

These files are templates. Before using them, replace the VIN placeholders with your own FordPass entity VIN.

Placeholders used:

```text
{{VIN_LOWER}}
{{VIN_UPPER}}



Example:


{{VIN_LOWER}} = 1ft6w1ev2pwg46084
{{VIN_UPPER}} = 1FT6W1EV2PWG46084



Files included
packages/
  ford_lightning_climate_buttons.yaml.template
  ford_lightning_tires.yaml.template

dashboards/
  lightning_clean.yaml.template



Requirements:
Fordpass custom integration by marq24
Mushroom cards
button cards
apexchart card
any other custom cards referenced in the dashbaord YAML

Basic Install:

Copy the package templates into your Home Assistant /config/packages/ folder.
Rename the files to remove .template.
Replace {{VIN_LOWER}} and {{VIN_UPPER}} with your FordPass VIN/entity suffix.
Copy the dashboard template into your dashboards folder.
Update your Home Assistant dashboard configuration as needed.
Restart Home Assistant or reload YAML.


Find your FordPass Entity VIN


in home assistent Developer Tools, Look for entities like:


sensor.fordpass_YOURVIN_odometer
switch.fordpass_YOURVIN_ignition
select.fordpass_YOURVIN_rcctemperature
sensor.fordpass_YOURVIN_tirepressure


user the lowercase VIN/entity suffice for {{VIN_LOWER}}.

Use the uppercase VIN for {{VIN_UPPER}} only where required.


Tire Pressure Sensors

This dashboard can expose individual tire PSI values from the FordPass tire pressure sensor attributes.

Example source entity:
sensor.fordpass_{{VIN_LOWER}}_tirepressure



Expected Attributes:

frontLeft
frontRight
rearLeft
rearRight
frontLeft_state
frontRight_state
rearLeft_state
rearRight_state
systemState

The template sensors convert the pressure values from bar to psi


Remote Climate:
The climate section includes controls for:

Start remote climate
Stop remote climate
Extend remote climate
Temperature setpoint slider
Front defrost
Rear defrost
Heated steering wheel
Seat climate controls where supported

The remote temperature helper converts Fahrenheit slider values into the Celsius-based FordPass RCC options.


Notes

This was built around a 2023 Ford F-150 Lightning Lariat, but it may work with other FordPass-supported vehicles if the same entities are available.

Use at your own risk. FordPass entities and service behavior can change when the integration or Ford APIs change.

Security Reminder

Do not upload files that contain your actual VIN, Home Assistant token, GitHub token, FordPass credentials, or other private information.

Before publishing, search the export folder for your VIN or secrets.


