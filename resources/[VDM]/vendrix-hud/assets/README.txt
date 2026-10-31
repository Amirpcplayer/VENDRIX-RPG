VENDRIX HUD - PNG ASSET GUIDE
================================

Place PNG files directly inside:
resources/[VDM]/vendrix-hud/assets/

IMPORTANT:
- PNG only, transparent background (RGBA).
- Do not put images in subfolders; this resource loads assets/*.png.
- Filenames are case-sensitive: use exactly the names below.
- Weapon PNG filenames use GTA/MTA weapon IDs, so the correct icon changes automatically with the player's current weapon.
- Suggested sizes are source image dimensions; HUD scales them automatically.

BRANDING LOGO
logo.png            512 x 96      Your own transparent VENDRIX logo; displayed instead of text

CORE ICONS
hp.png             64 x 64       Heart / health
armor.png          64 x 64       Armor / shield
money.png          64 x 64       Cash / dollar
wanted_star.png    32 x 32       One wanted star (same PNG reused for all 6 stars)
ammo.png           32 x 32       Bullet / ammo

WEAPON ICONS
Use a separate transparent PNG per weapon ID, preferably 256 x 96 (landscape):
weapon_0.png       256 x 96      Unarmed / fists (optional)
weapon_1.png       256 x 96      Brass knuckles
weapon_2.png       256 x 96      Golf club
weapon_3.png       256 x 96      Nightstick
weapon_4.png       256 x 96      Knife
weapon_5.png       256 x 96      Baseball bat
weapon_6.png       256 x 96      Shovel
weapon_7.png       256 x 96      Pool cue
weapon_8.png       256 x 96      Katana
weapon_9.png       256 x 96      Chainsaw
weapon_10.png      256 x 96      Dildo 1
weapon_11.png      256 x 96      Dildo 2
weapon_12.png      256 x 96      Vibrator 1
weapon_13.png      256 x 96      Vibrator 2
weapon_14.png      256 x 96      Flowers
weapon_15.png      256 x 96      Cane
weapon_16.png      256 x 96      Grenade
weapon_17.png      256 x 96      Tear gas
weapon_18.png      256 x 96      Molotov
weapon_22.png      256 x 96      9mm
weapon_23.png      256 x 96      Silenced 9mm
weapon_24.png      256 x 96      Desert Eagle
weapon_25.png      256 x 96      Shotgun
weapon_26.png      256 x 96      Sawed-off
weapon_27.png      256 x 96      SPAS-12
weapon_28.png      256 x 96      Micro SMG
weapon_29.png      256 x 96      MP5
weapon_30.png      256 x 96      AK-47
weapon_31.png      256 x 96      M4
weapon_32.png      256 x 96      TEC-9
weapon_33.png      256 x 96      Rifle
weapon_34.png      256 x 96      Sniper rifle
weapon_35.png      256 x 96      Rocket launcher
weapon_36.png      256 x 96      Heat seeker
weapon_37.png      256 x 96      Flamethrower
weapon_38.png      256 x 96      Minigun
weapon_39.png      256 x 96      Satchel charge
weapon_40.png      256 x 96      Detonator
weapon_41.png      256 x 96      Spray can
weapon_42.png      256 x 96      Fire extinguisher
weapon_43.png      256 x 96      Camera
weapon_44.png      256 x 96      Night vision
weapon_45.png      256 x 96      Thermal goggles
weapon_46.png      256 x 96      Parachute

NOTES
- Add logo.png to show your own image instead of a text header. If it is missing, the header area stays blank.
- You only need to add the other icons you want to customize; missing icons use a text fallback.
- All weapon PNGs should face to the right and have empty transparent padding around the weapon.
- Do not include a background panel in the PNG; the HUD draws its own black/gold panel.
- When adding PNGs locally, run "refresh" then "restart vendrix-hud" in the MTA server console.
- This folder is already registered in meta.xml using assets/*.png.
