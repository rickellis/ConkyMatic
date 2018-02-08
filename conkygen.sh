#!/usr/bin/env bash


# URL to the Yahoo weather JSON file
APIURL="https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20weather.forecast%20where%20woeid%20in%20(select%20woeid%20from%20geo.places(1)%20where%20text%3D%22laramie%2C%20wy%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys"

# Path to the current wallpaper.
# Since I use XFCE desktop I'm running a query to get the path.
# If you are running a different desktop this will have to be changed.
WALLPAPERPATH=$(xfconf-query -c xfce4-desktop -p $xfce_desktop_prop_prefix/backdrop/screen0/monitor0/image-path)

# Base URL to the directory containing the various assets
BASEURL="${PWD}"

# Template to use to create the .conkyrc file
TEMPLFILE="default.conky"

# Template directory path
TEMPLDIR="${BASEURL}/Templates"

# Name of the JSON cache file
JSON_CACHEFILE="weather.json"

# Location of cache directory.
CACHEDIR="${BASEURL}/Cache"

# Folder with the SVG master images
SVGICONS="Weather-Icons-SVG/Yahoo"

# Folder where the PNG images will be copied to
PNGICONS="Weather-Icons-PNG"

# Size that the PNG icons should be converted to
ICONSIZE="64"

# Name of the color palette image
COLORPIMG="colorpalette.png"

# Desired width of color palette image
COLORPWIDTH="224"

# Number of colors in the palette image
COLORPN="16"

# Default background color
COLOR_BG="#000000"

# Default border color
COLOR_BORDER="#ffffff"

# Default weather icon color
COLOR_ICON="#d5a70c"

# Default primary text color
COLOR_PRIMARY="#ffffff"

# Default data text color
COLOR_DATA="#6edd78"

# Default accent text color
COLOR_ACCENT="#d570ac"

# Default HR color
COLOR_HR="#ffffff"

# Battery bar color
COLOR_BAT_FULL="#86D45A"

# Battery bar near empty color
COLOR_BAT_EMPT="#fc1b0f"

# Background transparency. Value between 0-255
BG_TRANS="230"


#
# END OF USER CONFIGURATION VARIABLES ---------------------------------------------------
#

VERSION="1.0"


# DO THE VARIOUS DIRECTORIES EXIST? -----------------------------------------------------

# Remove the trailing slash from the cache directory path
if [[ ${CACHEDIR} =~ .*/$ ]]; then
    CACHEDIR="${CACHEDIR:0:-1}"
fi

# Does the cache directory exist?
if  ! [[ -d ${CACHEDIR} ]]; then
    echo "The cache directory path does not exist. Aborting..."
    exit 1
fi

# Remove the trailing slash from the template directory path
if [[ ${TEMPLDIR} =~ .*/$ ]]; then
    TEMPLDIR="${TEMPLDIR:0:-1}"
fi

# Does the template directory exist?
if  ! [[ -d ${TEMPLDIR} ]]; then
    echo "The template directory path does not exist. Aborting..."
    exit 1
fi

# DEPENDENCY CHECKS ---------------------------------------------------------------------

# Is Curl installed?
if ! [[ $(type curl) ]]; then
    echo "Curl does not appear to be installed. Aborting..."
    exit 1;
fi

# Is ImageMagick installed?
if ! [[ $(type command) ]]; then
    echo "ImageMagick does not appear to be installed. Aborting..."
    exit 1;
fi

# WELCOME MESSAGE ---------------------------------------------------------------------

echo ""
echo "Welcome to ConkyMatic Version ${VERSION}"


# WEATHER ICON COLOR --------------------------------------------------------------------

echo ""
echo "Enter the weather icon color value (in hex) or hit ENTER to apply default color:"
read R_COLOR_ICON

if [[ ${R_COLOR_ICON} != "" ]]; then

    # Did they submit a valid HEX value?
    if ! [[ $R_COLOR_ICON =~ ^[\#a-fA-F0-9]+$ ]]; then 
        echo "The color you entered does not appear to be valid. Aborting..."
        echo ""
        exit 1
    fi

    # Add the # character if they omitted it from the hex color
    if [[ ${R_COLOR_ICON:0:1} != "#" ]]; then
        R_COLOR_ICON="#${R_COLOR_ICON}"
    fi

    # The hex color should now be 7 characters. Ex: #ffffff
    if [[ ${R_COLOR_ICON} -ne 7 ]]; then
        echo "Your hex value isn't correct. It must be 6 characters in length, or 7 if you include the # symbol."
        echo ""
        exit 1
    fi

    COLOR_ICON="${R_COLOR_ICON}"
fi


# ACCENT TEXT COLOR ---------------------------------------------------------------------

echo ""
echo "Enter the accent text color value (in hex) or hit ENTER to apply default color:"
read R_COLOR_ACCENT

if [[ ${R_COLOR_ACCENT} != "" ]]; then

    # Did they submit a valid HEX value?
    if ! [[ $R_COLOR_ACCENT =~ ^[\#a-fA-F0-9]+$ ]]; then 
        echo "The color you entered does not appear to be valid. Aborting..."
        echo ""
        exit 1
    fi

    # Add the # character if they omitted it from the hex color
    if [[ ${R_COLOR_ACCENT:0:1} != "#" ]]; then
        R_COLOR_ACCENT="#${R_COLOR_ACCENT}"
    fi

    # The hex color should now be 7 characters. Ex: #ffffff
    if [[ ${R_COLOR_ACCENT} -ne 7 ]]; then
        echo "Your hex value isn't correct. It must be 6 characters in length, or 7 if you include the # symbol."
        echo ""
        exit 1
    fi

    COLOR_ACCENT="${R_COLOR_ACCENT}"
fi

# DOWNLOAD THE WEATHER JSON FILE --------------------------------------------------------

# Curl argumnets:
#   -f = fail silently. Will issue error code 22
#   -k = Non-strict SSL connection
#   -s = Silent. No error message.
#   -S = Show simple error if -s is set.
CURLARGS="-f -s -S -k"

# Execute the Curl command and cache the json file
$(curl ${CURLARGS} ${APIURL} -o ${CACHEDIR}/${JSON_CACHEFILE})


# GENERATE PNG IMAGES FOR CURRENT WEATHER & FORECAST ------------------------------------

# Fetch the weather and forecast codes from the JSON file.
# These will get matchedd to a PNG image with the same name below.
CRWEATHERCODE=$(jq .query.results.channel.item.condition.code ${CACHEDIR}/${JSON_CACHEFILE} | grep -oP '"\K[^"\047]+(?=["\047])')
FORECASTCODE1=$(jq .query.results.channel.item.forecast[1].code ${CACHEDIR}/${JSON_CACHEFILE} | grep -oP '"\K[^"\047]+(?=["\047])')
FORECASTCODE2=$(jq .query.results.channel.item.forecast[2].code ${CACHEDIR}/${JSON_CACHEFILE} | grep -oP '"\K[^"\047]+(?=["\047])')
FORECASTCODE3=$(jq .query.results.channel.item.forecast[3].code ${CACHEDIR}/${JSON_CACHEFILE} | grep -oP '"\K[^"\047]+(?=["\047])')
FORECASTCODE4=$(jq .query.results.channel.item.forecast[4].code ${CACHEDIR}/${JSON_CACHEFILE} | grep -oP '"\K[^"\047]+(?=["\047])')
FORECASTCODE5=$(jq .query.results.channel.item.forecast[5].code ${CACHEDIR}/${JSON_CACHEFILE} | grep -oP '"\K[^"\047]+(?=["\047])')


# Copy the PNG image with the matching weather/forecast code number to the cache folder
cp -f ${PNGICONS}/${CRWEATHERCODE}.png ${CACHEDIR}/weather.png
cp -f ${PNGICONS}/${FORECASTCODE1}.png ${CACHEDIR}/forecast1.png
cp -f ${PNGICONS}/${FORECASTCODE2}.png ${CACHEDIR}/forecast2.png
cp -f ${PNGICONS}/${FORECASTCODE3}.png ${CACHEDIR}/forecast3.png
cp -f ${PNGICONS}/${FORECASTCODE4}.png ${CACHEDIR}/forecast4.png
cp -f ${PNGICONS}/${FORECASTCODE5}.png ${CACHEDIR}/forecast5.png


# GENERATE COLORPALETTE PNG -------------------------------------------------------------

# Use ImageMagick to create a color palette image based on the current wallpaper
convert ${WALLPAPERPATH} \
+dither \
-colors ${COLORPN} \
-unique-colors \
-filter box \
-geometry ${COLORPWIDTH} \
${CACHEDIR}/${COLORPIMG}


# REPLACE TEMPLATE VARIABLES ------------------------------------------------------------

# First we make a copy of the template

cp ${TEMPLDIR}/${TEMPLFILE} ${CACHEDIR}/conkyrc


# VARIABLE REPLACEMENT ------------------------------------------------------------------

# API URL
# We need to excape ampersands before running sed
APIURL=${APIURL/&/\\&}
sed -i -e "s|_VAR:API_URL|${APIURL}|g" "${CACHEDIR}/conkyrc"

# Path to JSON file; /path/to/Cache/weather.json
sed -i -e "s|_VAR:JSON_FILEPATH_|${CACHEDIR}/${JSON_CACHEFILE}|g" "${CACHEDIR}/conkyrc"

# Full path to cache directory - no trailing slash
sed -i -e "s|_VAR:CACHE_DIR_|${CACHEDIR}|g" "${CACHEDIR}/conkyrc"

# Path to PNG-Weather-Icons folder - no trailing slash
sed -i -e "s|_VAR:WEATHER_ICONS_|${BASEURL}/${PNGICONS}|g" "${CACHEDIR}/conkyrc"

# Full /path/to/colorpalette.png
sed -i -e "s|_VAR:COLOR_PALETTE_FILEPATH_|${CACHEDIR}/${COLORPIMG}|g" "${CACHEDIR}/conkyrc"

# Transparency value
sed -i -e "s|_VAR:BG_TRANS_|${BG_TRANS}|g" "${CACHEDIR}/conkyrc"

# Colors
sed -i -e "s|_VAR:COLOR_BG_|${COLOR_BG}|g" "${CACHEDIR}/conkyrc"
sed -i -e "s|_VAR:COLOR_PRIMARY_|${COLOR_PRIMARY}|g" "${CACHEDIR}/conkyrc"
sed -i -e "s|_VAR:COLOR_DATA_|${COLOR_DATA}|g" "${CACHEDIR}/conkyrc"
sed -i -e "s|_VAR:COLOR_ACCENT_|${COLOR_ACCENT}|g" "${CACHEDIR}/conkyrc"
sed -i -e "s|_VAR:COLOR_HR_|${COLOR_HR}|g" "${CACHEDIR}/conkyrc"
sed -i -e "s|_VAR:COLOR_BAT_FULL_|${COLOR_BAT_FULL}|g" "${CACHEDIR}/conkyrc"
sed -i -e "s|_VAR:COLOR_BAT_EMPT_|${COLOR_BAT_EMPT}|g" "${CACHEDIR}/conkyrc"
sed -i -e "s|_VAR:COLOR_BORDER_|${COLOR_BORDER}|g" "${CACHEDIR}/conkyrc"


# CLEANUP -------------------------------------------------------------------------------

# Kill conky
pkill conky
    
# Copy conkyrc file to its proper location
cp ${CACHEDIR}/conkyrc ~/.conkyrc

# Remove the temp file
rm ${CACHEDIR}/conkyrc

# Launch conky
conky 2>/dev/null