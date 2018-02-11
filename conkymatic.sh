#!/usr/bin/env bash
#----------------------------------------------------------------------------------------
#
# conkymatic.sh
#
VERSION="1.0.0"
#
# Conky automatic color generator based on currrent wallpaper.
#
# by Rick Ellis
# https://github.com/rickellis
#
# License: MIT
#
# Generates a .conkyrc file that gets colorized based on the predominant colors
# in the current wallpaper.
#
# Dependencies
#   1. Curl
#   2. ImageMagick (required). Used to generate color palettes.
#   3. Inkscape (optional). If installed, will use it to render SVG to PNG.
#
# Usage: 
#
#   cd /path/to/ConkyMatic/
#
#   ./conkymatic.sh
#
#----------------------------------------------------------------------------------------
# USER CONFIGURATION VARIABLES
#----------------------------------------------------------------------------------------

# Your city for weather data
YOUR_CITY="laramie"

# Your state
YOUR_STATE="wy"

# Template to base the .conkyrc file one
TEMPLATE_FILENAME="default.conky"

# URL to the Yahoo weather JSON file. 
# If you entered your city and state above, the URL below should work by default.
# Note: If you live outside of the U.S. you'll likely need to update the URL.
# Go to: https://developer.yahoo.com/weather/
WEATHER_API_URL="https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20weather.forecast%20where%20woeid%20in%20(select%20woeid%20from%20geo.places(1)%20where%20text%3D%22${YOUR_CITY}%2C%20${YOUR_STATE}%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys"

# Path to the current wallpaper.
# If you are running a different desktop than XFCE you'll have to figure
# out how to query your system to get the current wallpaper.
WALLPAPER_PATH=$(xfconf-query -c xfce4-desktop -p $xfce_desktop_prop_prefix/backdrop/screen0/monitor0/image-path)

# Basepath to the directory containing the various assets.
# Do not change this unless you need a different directory structure.
#BASEPATH="${PWD}"
BASEPATH=$(dirname -- $(readlink -fn -- "$0"))

# Name of the JSON cache file
JSON_CACHE_FILE="weather.json"

# Template directory path
TEMPLATE_DIRECTORY="${BASEPATH}/Templates"

# Location of cache directory.
CACHE_DIRECTORY="${BASEPATH}/Cache"

# Full path to the SVG icons
WEATHER_ICONS_SVG_DIRECTORY="${BASEPATH}/Weather-Icons-SVG/Yahoo"

# Full path to the PNG icon folder
WEATHER_ICONS_PNG_DIRECTORY="${BASEPATH}/Weather-Icons-PNG"

# Size that the PNG icons should be converted to.
# Note: In the .conkyrc file you can set the size of each image.
# Just make the size here larger than what you anticipate using.
ICON_SIZE="64"

# Name of the color palette image
COLOR_PALETTE_IMG="colorpalette.png"

# Desired width of color palette image
COLOR_PALETTE_WIDTH="224"

#
# END OF USER CONFIGURATION VARIABLES
#

echo ""
echo "-----------------------------------------------------------------------"
echo " Welcome to ConkyMatic Version ${VERSION}"
echo "-----------------------------------------------------------------------"


# DO THE VARIOUS DIRECTORIES SPECIFIED ABOVE EXIST?

# Remove the trailing slash from the cache directory path
if [[ ${CACHE_DIRECTORY} =~ .*/$ ]]; then
    CACHE_DIRECTORY="${CACHE_DIRECTORY:0:-1}"
fi

# Does the cache directory exist?
if  ! [[ -d ${CACHE_DIRECTORY} ]]; then
    echo " The cache directory path does not exist. Aborting..."
    exit 1
fi

# Remove the trailing slash from the template directory path
if [[ ${TEMPLATE_DIRECTORY} =~ .*/$ ]]; then
    TEMPLATE_DIRECTORY="${TEMPLATE_DIRECTORY:0:-1}"
fi

# Does the template directory exist?
if  ! [[ -d ${TEMPLATE_DIRECTORY} ]]; then
    echo " The template directory path does not exist. Aborting..."
    exit 1
fi

# Remove the trailing slash from the SVG directory path
if [[ ${WEATHER_ICONS_SVG_DIRECTORY} =~ .*/$ ]]; then
    WEATHER_ICONS_SVG_DIRECTORY="${WEATHER_ICONS_SVG_DIRECTORY:0:-1}"
fi

# Does the SVG directory exist?
if  ! [[ -d ${WEATHER_ICONS_SVG_DIRECTORY} ]]; then
    echo " The SVG directory path does not exist. Aborting..."
    exit 1
fi

# Remove the trailing slash from the PNG directory path
if [[ ${WEATHER_ICONS_PNG_DIRECTORY} =~ .*/$ ]]; then
    WEATHER_ICONS_PNG_DIRECTORY="${WEATHER_ICONS_PNG_DIRECTORY:0:-1}"
fi

# Does the PNG directory exist?
if  ! [[ -d ${WEATHER_ICONS_PNG_DIRECTORY} ]]; then
    echo " The PNG directory path does not exist. Aborting..."
    exit 1
fi

# DEPENDENCY CHECKS ---------------------------------------------------------------------

# Is Curl installed?
if ! [[ $(type curl) ]]; then
    echo " Curl does not appear to be installed. Aborting..."
    exit 1;
fi

# Is ImageMagick installed?
if ! [[ $(type command) ]]; then
    echo " ImageMagick does not appear to be installed. Aborting..."
    exit 1;
fi

# Is Inkscape installed? The SVG to PNG converter is better in Inkscape.
# If it's installed we'll use it for that part of the process
converter="ImageMagick"
if [ "$(command -v inkscape)" >/dev/null 2>&1 ]; then
    converter="Inkscape"
fi

# CONSENT -------------------------------------------------------------------------------

echo ""
echo " Hit ENTER to begin, or any other key to abort"
read CONSENT

# Validate mode.
if ! [[ -z ${CONSENT} ]]; then
    echo ""
    echo " Goodbye..."
    echo ""
    exit 1
fi

echo " Here we go!"

# DOWNLOAD THE WEATHER JSON FILE --------------------------------------------------------

echo ""
echo " Downloading Yahoo weather JSON data"

# Curl argumnets:
#   -f = fail silently. Will issue error code 22
#   -k = Non-strict SSL connection
#   -s = Silent. No error message.
#   -S = Show simple error if -s is set.
CURLARGS="-f -s -S -k"

# Execute the Curl command and cache the json file
# $(curl ${CURLARGS} ${WEATHER_API_URL} -o ${CACHE_DIRECTORY}/${JSON_CACHE_FILE})
CURL=$(curl ${CURLARGS} ${WEATHER_API_URL})
echo "${CURL}" > ${CACHE_DIRECTORY}/${JSON_CACHE_FILE}


# GENERATE COLOR PALETTE PNG ------------------------------------------------------------

echo ""
echo " Exporting color palette PNG based on the wallpaper's 16 most common colors"

# Use ImageMagick to create a color palette image based on the current wallpaper
convert ${WALLPAPER_PATH} \
+dither \
-colors 16 \
-unique-colors \
-filter box \
-geometry ${COLOR_PALETTE_WIDTH} \
${CACHE_DIRECTORY}/${COLOR_PALETTE_IMG}


# GENERATE AUTOMATIC COLORS -------------------------------------------------------------

echo ""
echo " Extracting hex color values from color palette image"

# Create a micro version of the color palette PNG: 1px x 16px 
# so we can gather the color value using x/y coordinates
MICROIMG="${CACHE_DIRECTORY}/micropalette.png"

convert ${CACHE_DIRECTORY}/${COLOR_PALETTE_IMG} \
-colors 16 \
-unique-colors \
-depth 8 \
-size 1x16 \
-geometry 16 \
${MICROIMG}


# EXTRACT COLOR VAlUES --------------------------------------------------------------

# Although ImageMagick allows you to extract all the image colors in one acction, 
# the colors are sorted alphabetically, not from dark to light as they are when
# the color palette image is created. I ended up having to extract each color value 
# based on the x/y coordinates of the micropalette image. At some point I'd like to
# revisit this code and see if I can find a more graceful way to accomplish this.

COLOR1=$(convert ${MICROIMG} -crop '1x1+0+0' txt:-)
# Remove newlines 
COLOR1=${COLOR1//$'\n'/}
# Extract the hex color value
COLARRAY[1]=$(echo "$COLOR1" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')

COLOR2=$(convert ${MICROIMG} -crop '1x1+1+0' txt:-)
# Remove newlines 
COLOR2=${COLOR2//$'\n'/}
# Extract the hex color value
COLARRAY[2]=$(echo "$COLOR2" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')

COLOR3=$(convert ${MICROIMG} -crop '1x1+2+0' txt:-)
# Remove newlines 
COLOR3=${COLOR3//$'\n'/}
# Extract the hex color value
COLARRAY[3]=$(echo "$COLOR3" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')

COLOR4=$(convert ${MICROIMG} -crop '1x1+3+0' txt:-)
# Remove newlines 
COLOR4=${COLOR4//$'\n'/}
# Extract the hex color value
COLARRAY[4]=$(echo "$COLOR4" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')

COLOR5=$(convert ${MICROIMG} -crop '1x1+4+0' txt:-)
# Remove newlines 
COLOR5=${COLOR5//$'\n'/}
# Extract the hex color value
COLARRAY[5]=$(echo "$COLOR5" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')

COLOR6=$(convert ${MICROIMG} -crop '1x1+5+0' txt:-)
# Remove newlines 
COLOR6=${COLOR6//$'\n'/}
# Extract the hex color value
COLARRAY[6]=$(echo "$COLOR6" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')

COLOR7=$(convert ${MICROIMG} -crop '1x1+6+0' txt:-)
# Remove newlines 
COLOR7=${COLOR7//$'\n'/}
# Extract the hex color value
COLARRAY[7]=$(echo "$COLOR7" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')

COLOR8=$(convert ${MICROIMG} -crop '1x1+7+0' txt:-)
# Remove newlines 
COLOR8=${COLOR8//$'\n'/}
# Extract the hex color value
COLARRAY[8]=$(echo "$COLOR8" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')

COLOR9=$(convert ${MICROIMG} -crop '1x1+8+0' txt:-)
# Remove newlines 
COLOR9=${COLOR9//$'\n'/}
# Extract the hex color value
COLARRAY[9]=$(echo "$COLOR9" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')

COLOR10=$(convert ${MICROIMG} -crop '1x1+9+0' txt:-)
# Remove newlines 
COLOR10=${COLOR10//$'\n'/}
# Extract the hex color value
COLARRAY[10]=$(echo "$COLOR10" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')

COLOR11=$(convert ${MICROIMG} -crop '1x1+10+0' txt:-)
# Remove newlines 
COLOR11=${COLOR11//$'\n'/}
# Extract the hex color value
COLARRAY[11]=$(echo "$COLOR11" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')

COLOR12=$(convert ${MICROIMG} -crop '1x1+11+0' txt:-)
# Remove newlines 
COLOR12=${COLOR12//$'\n'/}
# Extract the hex color value
COLARRAY[12]=$(echo "$COLOR12" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')

COLOR13=$(convert ${MICROIMG} -crop '1x1+12+0' txt:-)
# Remove newlines 
COLOR13=${COLOR13//$'\n'/}
# Extract the hex color value
COLARRAY[13]=$(echo "$COLOR13" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')

COLOR14=$(convert ${MICROIMG} -crop '1x1+13+0' txt:-)
# Remove newlines 
COLOR14=${COLOR14//$'\n'/}
# Extract the hex color value
COLARRAY[14]=$(echo "$COLOR14" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')

COLOR15=$(convert ${MICROIMG} -crop '1x1+14+0' txt:-)
# Remove newlines 
COLOR15=${COLOR15//$'\n'/}
# Extract the hex color value
COLARRAY[15]=$(echo "$COLOR15" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')

COLOR16=$(convert ${MICROIMG} -crop '1x1+15+0' txt:-)
# Remove newlines 
COLOR16=${COLOR16//$'\n'/}
# Extract the hex color value
COLARRAY[16]=$(echo "$COLOR16" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')


# Delete micro image
rm ${MICROIMG}

# SET COLOR VARIABLES ---------------------------------------------------------------

echo ""
echo " Building a randomized color map"

# All colors are randomly selected!

# Background color
RND=$(shuf -i 1-3 -n 1)
COLOR_BACKGROUND="${COLARRAY[${RND}]}"

# Border color
RND=$(shuf -i 5-13 -n 1)
COLOR_BORDER="${COLARRAY[${RND}]}"

# Weather icon color
RND=$(shuf -i 12-16 -n 1)
COLOR_ICON="${COLARRAY[${RND}]}"

# HR color
RND=$(shuf -i 7-13 -n 1)
COLOR_HR="${COLARRAY[${RND}]}"

# Bars normal
RND=$(shuf -i 10-16 -n 1)
COLOR_BARS_NORM="${COLARRAY[${RND}]}"

# Bars warning
# COLOR_BARS_WARN="${COLARRAY[16]}"
# Make this red since it's only used for a depleted battery.
COLOR_BARS_WARN="#fc1b0f"

# Time color
RND=$(shuf -i 12-16 -n 1)
COLOR_TIME="${COLARRAY[${RND}]}"

# Date color
RND=$(shuf -i 11-16 -n 1)
COLOR_DATE="${COLARRAY[${RND}]}"

# Weather data color
RND=$(shuf -i 12-16 -n 1)
COLOR_WEATHER="${COLARRAY[${RND}]}"

# Headings
RND=$(shuf -i 9-16 -n 1)
COLOR_HEADING="${COLARRAY[${RND}]}"

# Subheadings
RND=$(shuf -i 9-13 -n 1)
COLOR_SUBHEADING="${COLARRAY[${RND}]}"

# Data values
RND=$(shuf -i 8-16 -n 1)
COLOR_DATA="${COLARRAY[${RND}]}"

# Color extra
RND=$(shuf -i 4-16 -n 1)
COLOR_TEXT="${COLARRAY[${RND}]}"


# COPY SVG TO TMP/DIRECTORY  ------------------------------------------------------------
# We do this because we need to open each SVG and replace the color value. 
# No reason to mess with the originals.

# Name of the directory that we will copy the SVGs to.
TEMPDIR="/tmp/SVGCONVERT"

# Copy the master SVG images to the temp directory.
cp -R "${WEATHER_ICONS_SVG_DIRECTORY}" "${TEMPDIR}"


# REPLACE COLOR IN SVG FILES ------------------------------------------------------------

# We now open each SVG file in the temp directory and replace the fill color
for filepath in "${TEMPDIR}"/*.svg
    do
    # Match the pattern: fill="#hexval" and replace with the new color
    sed -i -e "s/fill=\"#[[:alnum:]]*\"/fill=\"${COLOR_ICON}\"/g" "$filepath"
done

# CONVERT SVG TO PNG  -------------------------------------------------------------------

echo ""
echo " Exporting weather icons using $converter"
echo ""

# We now run either ImageMagick or Inkscape to turn the SVG
# images into PNGs with the auto-selected color value.
str="."
i=1
for filepath in "${TEMPDIR}"/*.svg
    do

    # Extract the filename from the path
    filename="${filepath##*/}"

    # Remove the file extension, leaving only the name  
    name="${filename%%.*}"

    # Convert to PNG using either Inkscape or ImageMagick
    if [[ $converter == "Inkscape" ]]
    then
        inkscape -z -e \
        "${WEATHER_ICONS_PNG_DIRECTORY}/${name}.png" \
        -w "${ICON_SIZE}" \
        -h "${ICON_SIZE}" \
        "$filepath" \
        >/dev/null 2>&1 || { 
                                echo " An error was encountered. Aborting...";
                                rm -R "${TEMPDIR}";
                                exit 1; 
                            }
    else
        convert \
        -background none \
        -density 1500 \
        -resize "${ICON_SIZE}x${ICON_SIZE}!" \
        "$filepath" \
        "${WEATHER_ICONS_PNG_DIRECTORY}/${name}.png" \
        >/dev/null 2>&1 || { 
                                echo " An error was encountered. Aborting..."; 
                                rm -R "${TEMPDIR}";
                                exit 1;
                            }
    fi

    # Increment the progress bar with each iteration
    echo -ne " (Exporting image ${i}) ${str}\r"
    ((i++))
    str="${str}."
done

# Delete the temporary directory.
rm -R "${TEMPDIR}"


# CACHE THE CURRENT WEATHER & FORECAST ICONS --------------------------------------------
# These are the icons that get displayed in the conky. They get regenerated
# every five minutes via code in the conky itself

# Fetch the weather and forecast codes from the JSON file.
# These will get matchedd to a PNG image with the same name below.
CRWEATHERCODE=$(jq .query.results.channel.item.condition.code ${CACHE_DIRECTORY}/${JSON_CACHE_FILE} | grep -oP '"\K[^"\047]+(?=["\047])')
FORECASTCODE1=$(jq .query.results.channel.item.forecast[1].code ${CACHE_DIRECTORY}/${JSON_CACHE_FILE} | grep -oP '"\K[^"\047]+(?=["\047])')
FORECASTCODE2=$(jq .query.results.channel.item.forecast[2].code ${CACHE_DIRECTORY}/${JSON_CACHE_FILE} | grep -oP '"\K[^"\047]+(?=["\047])')
FORECASTCODE3=$(jq .query.results.channel.item.forecast[3].code ${CACHE_DIRECTORY}/${JSON_CACHE_FILE} | grep -oP '"\K[^"\047]+(?=["\047])')
FORECASTCODE4=$(jq .query.results.channel.item.forecast[4].code ${CACHE_DIRECTORY}/${JSON_CACHE_FILE} | grep -oP '"\K[^"\047]+(?=["\047])')
FORECASTCODE5=$(jq .query.results.channel.item.forecast[5].code ${CACHE_DIRECTORY}/${JSON_CACHE_FILE} | grep -oP '"\K[^"\047]+(?=["\047])')

# Copy the PNG image with the matching weather/forecast code number to the cache folder
cp -f ${PNGWEATHER_ICONS_PNG_DIRECTORYDIR}/${CRWEATHERCODE}.png ${CACHE_DIRECTORY}/weather.png
cp -f ${WEATHER_ICONS_PNG_DIRECTORY}/${FORECASTCODE1}.png ${CACHE_DIRECTORY}/forecast1.png
cp -f ${WEATHER_ICONS_PNG_DIRECTORY}/${FORECASTCODE2}.png ${CACHE_DIRECTORY}/forecast2.png
cp -f ${WEATHER_ICONS_PNG_DIRECTORY}/${FORECASTCODE3}.png ${CACHE_DIRECTORY}/forecast3.png
cp -f ${WEATHER_ICONS_PNG_DIRECTORY}/${FORECASTCODE4}.png ${CACHE_DIRECTORY}/forecast4.png
cp -f ${WEATHER_ICONS_PNG_DIRECTORY}/${FORECASTCODE5}.png ${CACHE_DIRECTORY}/forecast5.png


# KILL CONKY IF IT'S RUNNING ------------------------------------------------------------

echo ""
echo ""
echo " Shutting down Conky"
pkill conky


# REPLACE TEMPLATE VARIABLES ------------------------------------------------------------
# Now it's time to insert the randomly gathered color values into the template

echo ""
echo " Inserting color values into the conky template"

# Before replacing vars make a copy of the template
cp ${TEMPLATE_DIRECTORY}/${TEMPLATE_FILENAME} ${CACHE_DIRECTORY}/conkyrc

# API URL
# Escape ampersands before running sed
WEATHER_API_URL=${WEATHER_API_URL//&/\\&}
sed -i -e "s|_VAR:API_URL|${WEATHER_API_URL}|g" "${CACHE_DIRECTORY}/conkyrc"

# Path to JSON file; /path/to/Cache/weather.json
sed -i -e "s|_VAR:JSON_WEATHER_FILEPATH_|${CACHE_DIRECTORY}/${JSON_CACHE_FILE}|g" "${CACHE_DIRECTORY}/conkyrc"

# Full path to cache directory - no trailing slash
sed -i -e "s|_VAR:CACHE_DIRECTORY_|${CACHE_DIRECTORY}|g" "${CACHE_DIRECTORY}/conkyrc"

# Path to PNG-Weather-Icons folder - no trailing slash
sed -i -e "s|_VAR:WEATHER_ICONS_DIRECTORY_|${WEATHER_ICONS_PNG_DIRECTORY}|g" "${CACHE_DIRECTORY}/conkyrc"

# Full /path/to/colorpalette.png
sed -i -e "s|_VAR:COLOR_PALETTE_FILEPATH_|${CACHE_DIRECTORY}/${COLOR_PALETTE_IMG}|g" "${CACHE_DIRECTORY}/conkyrc"

# Colors
sed -i -e "s|_VAR:COLOR_BACKGROUND_|${COLOR_BACKGROUND}|g" "${CACHE_DIRECTORY}/conkyrc"
sed -i -e "s|_VAR:COLOR_HR_|${COLOR_HR}|g" "${CACHE_DIRECTORY}/conkyrc"
sed -i -e "s|_VAR:COLOR_BARS_NORM_|${COLOR_BARS_NORM}|g" "${CACHE_DIRECTORY}/conkyrc"
sed -i -e "s|_VAR:COLOR_BARS_WARN_|${COLOR_BARS_WARN}|g" "${CACHE_DIRECTORY}/conkyrc"
sed -i -e "s|_VAR:COLOR_BORDER_|${COLOR_BORDER}|g" "${CACHE_DIRECTORY}/conkyrc"
sed -i -e "s|_VAR:COLOR_TIME_|${COLOR_TIME}|g" "${CACHE_DIRECTORY}/conkyrc"
sed -i -e "s|_VAR:COLOR_DATE_|${COLOR_DATE}|g" "${CACHE_DIRECTORY}/conkyrc"
sed -i -e "s|_VAR:COLOR_WEATHER_|${COLOR_WEATHER}|g" "${CACHE_DIRECTORY}/conkyrc"
sed -i -e "s|_VAR:COLOR_HEADING_|${COLOR_HEADING}|g" "${CACHE_DIRECTORY}/conkyrc"
sed -i -e "s|_VAR:COLOR_SUBHEADING_|${COLOR_SUBHEADING}|g" "${CACHE_DIRECTORY}/conkyrc"
sed -i -e "s|_VAR:COLOR_DATA_|${COLOR_DATA}|g" "${CACHE_DIRECTORY}/conkyrc"
sed -i -e "s|_VAR:COLOR_TEXT_|${COLOR_TEXT}|g" "${CACHE_DIRECTORY}/conkyrc"


# CLEANUP -------------------------------------------------------------------------------

echo ""
echo " Exporting new .conkyrc file"

# Copy conkyrc file to its proper location
cp ${CACHE_DIRECTORY}/conkyrc ~/.conkyrc

# Remove the temp file
rm ${CACHE_DIRECTORY}/conkyrc

# Launch conky
echo ""
echo " Relaunching Conky"
conky 2>/dev/null

echo ""
echo " Done!"
echo ""