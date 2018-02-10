#!/usr/bin/env bash
VERSION="1.0.0"
#----------------------------------------------------------------------------------------
#
# conkymatic.sh
#
# Version 1.0.0
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
#   1. ImageMagic (required). Used to generate color palettes.
#   2. Inkscape (optional). If installed, will use it to render SVG to PNG.
#
# Usage: 
#
#   cd /path/to/ConkyMatic/
#
#   ./conkymatic.sh
#
#----------------------------------------------------------------------------------------
# DO NOT JUST RUN THIS SCRIPT. EXAMINE THE CODE. UNDERSTAND IT. RUN IT AT YOUR OWN RISK.
#----------------------------------------------------------------------------------------


#
# USER CONFIGURATION VARIABLES ----------------------------------------------------------
#
# Most of the vraiables below do not need to be changed unless you have specific needs.

# Your city for weather data
YOUR_CITY="laramie"

# Your state
YOUR_STATE="wy"

# URL to the Yahoo weather JSON file. 
# If you entered your city and state above the URL below should work by default.
# Note: If you live outside of the U.S. you'll likely need to update the URL. Go to:
# https://developer.yahoo.com/weather/
APIURL="https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20weather.forecast%20where%20woeid%20in%20(select%20woeid%20from%20geo.places(1)%20where%20text%3D%22${YOUR_CITY}%2C%20${YOUR_STATE}%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys"

# Path to the current wallpaper.
# Since I use XFCE desktop I'm running a query to get the path.
# If you are running a different desktop you'll have to figure out how to query
# your system to get the current wallpaper.
WALLPAPERPATH=$(xfconf-query -c xfce4-desktop -p $xfce_desktop_prop_prefix/backdrop/screen0/monitor0/image-path)

# Base URL to the directory containing the various assets.
# Do not change this unless you need a different directory structure.
#BASEPATH="${PWD}"
BASEPATH=$(dirname -- $(readlink -fn -- "$0"))

# Template to use to create the .conkyrc file
TEMPLFILE="default.conky"

# Template directory path
TEMPLDIR="${BASEPATH}/Templates"

# Name of the JSON cache file
JSON_CACHEFILE="weather.json"

# Location of cache directory.
CACHEDIR="${BASEPATH}/Cache"

# Folder with the SVG master images
SVGICONS="Weather-Icons-SVG/Yahoo"

# Folder where the PNG images will be copied to
PNGICONS="Weather-Icons-PNG"

# Size that the PNG icons should be converted to
ICONSIZE="64"

# Name of the color palette imagepath/to/mufir
COLORPIMG="colorpalette.png"

# Desired width of color palette image
COLORPWIDTH="224"

# Default background color
COLOR_BG="#000000"

# Default border color
COLOR_BORDER="#ffffff"

# Default weather icon color
COLOR_ICON="#d5a70c"

# Default HR color
COLOR_HR="#ffffff"

# Monitoring bar color
COLOR_BARS_NORM="#86D45A"

# Monitoring bar, warning color
COLOR_BARS_WARN="#fc1b0f"

# Time color
COLOR_TIME="$ffffff"

# Date color
COLOR_DATE="$ffffff"

# Weather data color
COLOR_WEATHER="$ffffff"

# Headings
COLOR_HEADINGS="#d570ac"

# Subheadings
COLOR_SUBHEADINGS="#d570ac"

# Data values
COLOR_DATA="#6edd78"

# Color extra
COLOR_EXTRA="#d570ac"

# Background transparency. Value between 0-255
BG_TRANS="230"

#
# END OF USER CONFIGURATION VARIABLES ---------------------------------------------------
#


# WELCOME MESSAGE ---------------------------------------------------------------------

echo ""
echo "-----------------------------------------------------------------------"
echo " Welcome to ConkyMatic Version ${VERSION}"
echo "-----------------------------------------------------------------------"



# DO THE VARIOUS DIRECTORIES EXIST? -----------------------------------------------------

# Remove the trailing slash from the cache directory path
if [[ ${CACHEDIR} =~ .*/$ ]]; then
    CACHEDIR="${CACHEDIR:0:-1}"
fi

# Does the cache directory exist?
if  ! [[ -d ${CACHEDIR} ]]; then
    echo " The cache directory path does not exist. Aborting..."
    exit 1
fi

# Remove the trailing slash from the template directory path
if [[ ${TEMPLDIR} =~ .*/$ ]]; then
    TEMPLDIR="${TEMPLDIR:0:-1}"
fi

# Does the template directory exist?
if  ! [[ -d ${TEMPLDIR} ]]; then
    echo " The template directory path does not exist. Aborting..."
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
echo " Hit ENTER to begin, or any other key to abort."
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
echo " Downloading Yahoo weather data"

# Curl argumnets:
#   -f = fail silently. Will issue error code 22
#   -k = Non-strict SSL connection
#   -s = Silent. No error message.
#   -S = Show simple error if -s is set.
CURLARGS="-f -s -S -k"

# Execute the Curl command and cache the json file
# $(curl ${CURLARGS} ${APIURL} -o ${CACHEDIR}/${JSON_CACHEFILE})
CURL=$(curl ${CURLARGS} ${APIURL})
echo "${CURL}" > ${CACHEDIR}/${JSON_CACHEFILE}



# GENERATE COLOR PALETTE PNG ------------------------------------------------------------

echo ""
echo " Exporting color palette based on your 16 most predominant wallpaper colors."

# Use ImageMagick to create a color palette image based on the current wallpaper
convert ${WALLPAPERPATH} \
+dither \
-colors 16 \
-unique-colors \
-filter box \
-geometry ${COLORPWIDTH} \
${CACHEDIR}/${COLORPIMG}


# GENERATE AUTOMATIC COLORS -------------------------------------------------------------

echo ""
echo " Extracting hex color values from color palette image"

# Create a micro version of the color palette PNG: 1px x 16px 
MICROIMG="${CACHEDIR}/micropalette.png"

convert ${CACHEDIR}/${COLORPIMG} \
-colors 16 \
-unique-colors \
-depth 8 \
-size 1x16 \
-geometry 16 \
${MICROIMG}


# EXTRACT COLOR VAlUES --------------------------------------------------------------

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
echo " Building randomized color map"

# All colors are randomly selected!

# Background color
RND=$(shuf -i 1-3 -n 1)
COLOR_BG="${COLARRAY[${RND}]}"

# Border color
RND=$(shuf -i 5-13 -n 1)
COLOR_BORDER="${COLARRAY[${RND}]}"

# Weather icon color
RND=$(shuf -i 11-16 -n 1)
COLOR_ICON="${COLARRAY[${RND}]}"

# HR color
RND=$(shuf -i 5-13 -n 1)
COLOR_HR="${COLARRAY[${RND}]}"

# Bars normal
RND=$(shuf -i 10-15 -n 1)
COLOR_BARS_NORM="${COLARRAY[${RND}]}"

# Bars warning
COLOR_BARS_WARN="${COLARRAY[16]}"

# Time color
RND=$(shuf -i 12-16 -n 1)
COLOR_TIME="${COLARRAY[${RND}]}"

# Date color
RND=$(shuf -i 10-16 -n 1)
COLOR_DATE="${COLARRAY[${RND}]}"

# Weather data color
RND=$(shuf -i 11-15 -n 1)
COLOR_WEATHER="${COLARRAY[${RND}]}"

# Headings
RND=$(shuf -i 8-16 -n 1)
COLOR_HEADINGS="${COLARRAY[${RND}]}"

# Subheadings
RND=$(shuf -i 8-14 -n 1)
COLOR_SUBHEADINGS="${COLARRAY[${RND}]}"

# Data values
RND=$(shuf -i 7-16 -n 1)
COLOR_DATA="${COLARRAY[${RND}]}"

# Color extra
RND=$(shuf -i 10-16 -n 1)
COLOR_EXTRA="${COLARRAY[${RND}]}"



# COPY SVG TO TMP/DIRECTORY  ------------------------------------------------------------

# Name of the temp directory that we will copy the SVGs to.
TEMPDIR="/tmp/SVGCONVERT"

# Copy the master svg images to the temp directory.
# We don't want to mess with the originals.
cp -R "${BASEPATH}/${SVGICONS}" "${TEMPDIR}"


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


str="."
i=1
for filepath in "${TEMPDIR}"/*.svg
    do

    # Extract the filename from the path
    filename="${filepath##*/}"

    # Remove the file extension, leaving only the name  
    name="${filename%%.*}"

   # echo "Converting ${filename}"

    # Convert to PNG using either Inkscape or ImageMagick
    if [[ $converter == "inkscape" ]]
    then
        inkscape -z -e \
        "${BASEPATH}/${PNGICONS}/${name}.png" \
        -w "${ICONSIZE}" \
        -h "${ICONSIZE}" \
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
        -resize "${ICONSIZE}x${ICONSIZE}!" \
        "$filepath" \
        "${BASEPATH}/${PNGICONS}/${name}.png" \
        >/dev/null 2>&1 || { 
                                echo " An error was encountered. Aborting..."; 
                                rm -R "${TEMPDIR}";
                                exit 1;
                            }
    fi

    echo -ne "(Exporting image ${i}) ${str}\r"
    ((i++))
    str="${str}."
done

# Delete the temporary directory
rm -R "${TEMPDIR}"

# COPY PNG IMAGES TO THE CACHE DIR FOR CURRENT WEATHER & FORECAST -----------------------

# Fetch the weather and forecast codes from the JSON file.
# These will get matchedd to a PNG image with the same name below.
CRWEATHERCODE=$(jq .query.results.channel.item.condition.code ${CACHEDIR}/${JSON_CACHEFILE} | grep -oP '"\K[^"\047]+(?=["\047])')
FORECASTCODE1=$(jq .query.results.channel.item.forecast[1].code ${CACHEDIR}/${JSON_CACHEFILE} | grep -oP '"\K[^"\047]+(?=["\047])')
FORECASTCODE2=$(jq .query.results.channel.item.forecast[2].code ${CACHEDIR}/${JSON_CACHEFILE} | grep -oP '"\K[^"\047]+(?=["\047])')
FORECASTCODE3=$(jq .query.results.channel.item.forecast[3].code ${CACHEDIR}/${JSON_CACHEFILE} | grep -oP '"\K[^"\047]+(?=["\047])')
FORECASTCODE4=$(jq .query.results.channel.item.forecast[4].code ${CACHEDIR}/${JSON_CACHEFILE} | grep -oP '"\K[^"\047]+(?=["\047])')
FORECASTCODE5=$(jq .query.results.channel.item.forecast[5].code ${CACHEDIR}/${JSON_CACHEFILE} | grep -oP '"\K[^"\047]+(?=["\047])')

# Copy the PNG image with the matching weather/forecast code number to the cache folder
cp -f ${BASEPATH}/${PNGICONS}/${CRWEATHERCODE}.png ${CACHEDIR}/weather.png
cp -f ${BASEPATH}/${PNGICONS}/${FORECASTCODE1}.png ${CACHEDIR}/forecast1.png
cp -f ${BASEPATH}/${PNGICONS}/${FORECASTCODE2}.png ${CACHEDIR}/forecast2.png
cp -f ${BASEPATH}/${PNGICONS}/${FORECASTCODE3}.png ${CACHEDIR}/forecast3.png
cp -f ${BASEPATH}/${PNGICONS}/${FORECASTCODE4}.png ${CACHEDIR}/forecast4.png
cp -f ${BASEPATH}/${PNGICONS}/${FORECASTCODE5}.png ${CACHEDIR}/forecast5.png



# KILL CONKY ----------------------------------------------------------------------------

echo ""
echo ""
echo " Shutting down Conky"
pkill conky


# REPLACE TEMPLATE VARIABLES ------------------------------------------------------------

echo ""
echo " Exporting new .conkyrc file"

# Before replacing vars make a copy of the template
cp ${TEMPLDIR}/${TEMPLFILE} ${CACHEDIR}/conkyrc

# API URL
# We need to escape ampersands before running sed
APIURL=${APIURL//&/\\&}
sed -i -e "s|_VAR:API_URL|${APIURL}|g" "${CACHEDIR}/conkyrc"

# Path to JSON file; /path/to/Cache/weather.json
sed -i -e "s|_VAR:JSON_FILEPATH_|${CACHEDIR}/${JSON_CACHEFILE}|g" "${CACHEDIR}/conkyrc"

# Full path to cache directory - no trailing slash
sed -i -e "s|_VAR:CACHE_DIR_|${CACHEDIR}|g" "${CACHEDIR}/conkyrc"

# Path to PNG-Weather-Icons folder - no trailing slash
sed -i -e "s|_VAR:WEATHER_ICONS_|${BASEPATH}/${PNGICONS}|g" "${CACHEDIR}/conkyrc"

# Full /path/to/colorpalette.png
sed -i -e "s|_VAR:COLOR_PALETTE_FILEPATH_|${CACHEDIR}/${COLORPIMG}|g" "${CACHEDIR}/conkyrc"

# Transparency value
sed -i -e "s|_VAR:BG_TRANS_|${BG_TRANS}|g" "${CACHEDIR}/conkyrc"

# Colors
sed -i -e "s|_VAR:COLOR_BG_|${COLOR_BG}|g" "${CACHEDIR}/conkyrc"
sed -i -e "s|_VAR:COLOR_HR_|${COLOR_HR}|g" "${CACHEDIR}/conkyrc"
sed -i -e "s|_VAR:COLOR_BARS_NORM_|${COLOR_BARS_NORM}|g" "${CACHEDIR}/conkyrc"
sed -i -e "s|_VAR:COLOR_BARS_WARN_|${COLOR_BARS_WARN}|g" "${CACHEDIR}/conkyrc"
sed -i -e "s|_VAR:COLOR_BORDER_|${COLOR_BORDER}|g" "${CACHEDIR}/conkyrc"
sed -i -e "s|_VAR:COLOR_TIME_|${COLOR_TIME}|g" "${CACHEDIR}/conkyrc"
sed -i -e "s|_VAR:COLOR_DATE_|${COLOR_DATE}|g" "${CACHEDIR}/conkyrc"
sed -i -e "s|_VAR:COLOR_WEATHER_|${COLOR_WEATHER}|g" "${CACHEDIR}/conkyrc"
sed -i -e "s|_VAR:COLOR_HEADINGS_|${COLOR_HEADINGS}|g" "${CACHEDIR}/conkyrc"
sed -i -e "s|_VAR:COLOR_SUBHEADINGS_|${COLOR_SUBHEADINGS}|g" "${CACHEDIR}/conkyrc"
sed -i -e "s|_VAR:COLOR_DATA_|${COLOR_DATA}|g" "${CACHEDIR}/conkyrc"
sed -i -e "s|_VAR:COLOR_EXTRA_|${COLOR_EXTRA}|g" "${CACHEDIR}/conkyrc"


# CLEANUP -------------------------------------------------------------------------------
    
# Copy conkyrc file to its proper location
cp ${CACHEDIR}/conkyrc ~/.conkyrc

# Remove the temp file
rm ${CACHEDIR}/conkyrc

# Launch conky
echo ""
echo " Relaunching Conky"
conky 2>/dev/null

echo ""
echo " Done!"
echo ""