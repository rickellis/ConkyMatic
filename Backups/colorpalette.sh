#!/bin/bash
#----------------------------------------------------------------------------------------
#
# wallpaper-colorpalette.sh
#
# Version 1.0
#
# This script creates a PNG image containing the 16 most common colors found
# in the current wallpaper. 
#
# Dependencies: Linux running XFCE Desktop, and ImageMagic
#
# by Rick Ellis
# https://github.com/rickellis
#
# License: MIT
#
# Usage: Open a terminal and execute this script. You'll be prompted for the rest.
#
#----------------------------------------------------------------------------------------
# DO NOT JUST RUN THIS SCRIPT. EXAMINE THE CODE. UNDERSTAND IT. RUN IT AT YOUR OWN RISK.
#----------------------------------------------------------------------------------------



# Location where the PNG image should be saved
palette_image="${HOME}/.cache/wallpaper-palette.png"

# How many colors should be rendered
palette_colors="16"

# Width of the image
palette_width="224"

# Path to the current wallpaper
wallpaper_path=$(xfconf-query -c xfce4-desktop -p $xfce_desktop_prop_prefix/backdrop/screen0/monitor0/image-path)

#----------------------------------------------------------------------------------------

# Use ImageMagick to create a color palette image based on the current wallpaper
convert ${wallpaper_path} \
+dither \
-colors ${palette_colors} \
-unique-colors \
-filter box \
-geometry ${palette_width} \
${palette_image}



#----------------------------------------------------------------------------------------

# Create a text file with the color values
#convert ${palette_image}  -format %c -depth 8  histogram:info:/tmp/colorpalette.txt

# Extract hex color values
# sed -r 's/.*[[:space:]](\#[a-zA-Z0-9]+)[[:space:]].*/\1/w /tmp/hexcolors.txt' /tmp/colorpalette.txt >/dev/null

# i=1
#while read line; do
#    declare "colorpalette${i}"="$line"
# ((i++))
#done </tmp/hexcolors.txt
