#!/usr/bin/env bash
#-----------------------------------------------------------------------------------
#    ___          _        __  __      _   _    
#   / __|___ _ _ | |___  _|  \/  |__ _| |_(_)__ 
#  | (__/ _ \ ' \| / / || | |\/| / _` |  _| / _|
#   \___\___/_||_|_\_\\_, |_|  |_\__,_|\__|_\__|
#                     |__/ Automatic color generator
#
#-----------------------------------------------------------------------------------
VERSION="1.0.0"
#-----------------------------------------------------------------------------------
#
#  ConkyMatic does the following:
#
#    * Creates a 16 color palette image from the current wallpaper.
#    * Extracts the hex color value of each of the color palette images.
#    * Generates a .conkyrc file using colors randomly selected from the palette.
#    * Exports a set of colorized weather icons.
#    * Copies the new .conkyrc file to the home folder.
#    * Relaunches the Conky application.
#
#-----------------------------------------------------------------------------------
# Author:   Rick Ellis
# URL:      https://github.com/rickellis
# License:  MIT
#-----------------------------------------------------------------------------------


# USER CONFIGURATION VARIABLES

# Your city for weather data
YOUR_CITY="laramie"

# Your state
YOUR_STATE="wy"

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
# This allows the basepath to be correct if this script gets aliased in .bashrc
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
# Note: In the .conkyrc file you can set the display size of each image.
# Just make the size here larger than what you anticipate using.
ICON_SIZE="64"

# Name of the color palette image
COLOR_PALETTE_IMG="colorpalette.png"

# Desired width of color palette image. If you change the dimensions of
# your conky template you might need to change this.
COLOR_PALETTE_WIDTH="224"

#
# END OF USER CONFIGURATION VARIABLES
#

echo ""
echo "-----------------------------------------------------------------------"
echo " Welcome to ConkyMatic Version ${VERSION}"
echo "-----------------------------------------------------------------------"
echo ""

# DO THE VARIOUS DIRECTORIES SPECIFIED ABOVE EXIST?

# Remove the trailing slash from the cache directory path
if [[ ${CACHE_DIRECTORY} =~ .*/$ ]]; then
    CACHE_DIRECTORY="${CACHE_DIRECTORY:0:-1}"
fi

# Does the cache directory exist?
if  ! [[ -d ${CACHE_DIRECTORY} ]]; then
    echo " The cache directory path does not exist. Aborting..."
    echo ""
    exit 1
fi

# Remove the trailing slash from the template directory path
if [[ ${TEMPLATE_DIRECTORY} =~ .*/$ ]]; then
    TEMPLATE_DIRECTORY="${TEMPLATE_DIRECTORY:0:-1}"
fi

# Does the template directory exist?
if  ! [[ -d ${TEMPLATE_DIRECTORY} ]]; then
    echo " The template directory path does not exist. Aborting..."
    echo ""
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
    echo ""
    exit 1
fi

# DEPENDENCY CHECKS ---------------------------------------------------------------------

# Is Curl installed?
if ! [[ $(type curl) ]]; then
    echo " Curl does not appear to be installed. Aborting..."
    echo ""
    exit 1;
fi

# Is ImageMagick installed?
if ! [[ $(type command) ]]; then
    echo " ImageMagick does not appear to be installed. Aborting..."
    echo ""
    exit 1;
fi

# Is Inkscape installed? The SVG to PNG converter is better in Inkscape.
# If it's installed we'll use it for that part of the process
converter="ImageMagick"
if [ "$(command -v inkscape)" >/dev/null 2>&1 ]; then
    converter="Inkscape"
fi

# TEMPLATE VALIDATION -------------------------------------------------------------------

# Build an array with all the templates
i=0
declare -A TMPL_ARRAY
for file in ${TEMPLATE_DIRECTORY}/*.conky; do
    if [ -f "$file" ]; then
        TMPL_ARRAY[${i}]="$file"
        ((i++))
    fi
done

# How many templates are in the directory?
TMPLN="${#TMPL_ARRAY[@]}"

# If template directory is empty admonish them harshly
if [[ ${TMPLN} == 0 ]]; then
    echo "There are no conky templates in the Templates directory. Aborting..."
    echo ""
    exit 1
fi

# CONSENT -------------------------------------------------------------------------------

echo " Hit ENTER to begin, or any other key to abort"
read CONSENT

# Validate consent
if ! [[ -z ${CONSENT} ]]; then
    echo ""
    echo " Goodbye..."
    echo ""
    exit 1
fi

# SELECT A TEMPLATE ---------------------------------------------------------------------

# If there is only one template we auto-select it
if [[ ${TMPLN} == 1 ]]; then
        
    # Set the template
    TEMPLATE_SELECTION="${TMPL_ARRAY[0]}"

else  # Multiple templates in the Templates folder

    echo ""
    echo " Please select the template NUMBER you would like to use."
    echo " Or hit ENTER to select default.conky:"

    i=1
    # Display a list of templates
    for tmpl in ${TMPL_ARRAY[@]}; do
        filename="${tmpl##*/}"
        echo " [${i}] $filename"
        ((i++))
    done

    read CHOICE

    # If they hit enter we use default.conky
    if [[ -z ${CHOICE} ]]; then

        TEMPLATE_SELECTION="${TEMPLATE_DIRECTORY}/default.conky"

        # Does the default exist?
        if ! [ -e ${TEMPLATE_SELECTION} ]; then
            echo ""
            echo " Unable to find the default template"
            echo " The quick selection feature requires Templates/default.conky"
            echo " Aborting..."
            echo ""
            exit 1
        fi
    else  # The user chose a specific template

        # Did they enter an integer?
        if [[ $CHOICE =~ ^?[0-9]+$ ]]; then
            echo ""
            echo " You did not select a valid template number. Aborting..."
            echo ""
            exit 1
        fi

        # Subtract 1 from the choice since our array is indexed starting at zero
        CHOICE=$(( CHOICE-1 ))

        TEMPLATE_SELECTION="${TMPL_ARRAY[${CHOICE}]}"

        # Does the choice exist?
        if ! [ -e ${TEMPLATE_SELECTION} ]; then
            echo ""
            echo " The choice you entered does not correlate to a template. Aborting..."
            echo " Aborting..."
            exit 1
        fi
    fi
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
echo " Generating color palette based on the wallpaper's 16 most common colors"

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

# Although ImageMagick allows you to extract all the image colors in one action, 
# the colors are sorted alphabetically, not from dark to light as they are when
# the color palette image is created. I ended up having to extract each color value 
# based on the x/y coordinates of the micropalette image. At some point I'd like to
# revisit this code to see if I can find a more graceful way to accomplish this.
# Also, some images have alpha tranparencies, so we end up with 9 character hex
# values. We truncate all color values at 7.

COLOR1=$(convert ${MICROIMG} -crop '1x1+0+0' txt:-)
# Remove newlines 
COLOR1=${COLOR1//$'\n'/}
# Extract the hex color value
COLOR1=$(echo "$COLOR1" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')
# Truncate hex value at 7 characters. 
COLARRAY[1]="${COLOR1:0:7}"

COLOR2=$(convert ${MICROIMG} -crop '1x1+1+0' txt:-)
# Remove newlines 
COLOR2=${COLOR2//$'\n'/}
# Extract the hex color value
COLOR2=$(echo "$COLOR2" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')
# Truncate hex value at 7 characters. 
COLARRAY[2]="${COLOR2:0:7}"

COLOR3=$(convert ${MICROIMG} -crop '1x1+2+0' txt:-)
# Remove newlines 
COLOR3=${COLOR3//$'\n'/}
# Extract the hex color value
COLOR3=$(echo "$COLOR3" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')
# Truncate hex value at 7 characters. 
COLARRAY[3]="${COLOR3:0:7}"

COLOR4=$(convert ${MICROIMG} -crop '1x1+3+0' txt:-)
# Remove newlines 
COLOR4=${COLOR4//$'\n'/}
# Extract the hex color value
COLOR4=$(echo "$COLOR4" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')
# Truncate hex value at 7 characters. 
COLARRAY[4]="${COLOR4:0:7}"

COLOR5=$(convert ${MICROIMG} -crop '1x1+4+0' txt:-)
# Remove newlines 
COLOR5=${COLOR5//$'\n'/}
# Extract the hex color value
COLOR5=$(echo "$COLOR5" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')
# Truncate hex value at 7 characters. 
COLARRAY[5]="${COLOR5:0:7}"

COLOR6=$(convert ${MICROIMG} -crop '1x1+5+0' txt:-)
# Remove newlines 
COLOR6=${COLOR6//$'\n'/}
# Extract the hex color value
COLOR6=$(echo "$COLOR6" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')
# Truncate hex value at 7 characters. 
COLARRAY[6]="${COLOR6:0:7}"

COLOR7=$(convert ${MICROIMG} -crop '1x1+6+0' txt:-)
# Remove newlines 
COLOR7=${COLOR7//$'\n'/}
# Extract the hex color value
COLOR7=$(echo "$COLOR7" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')
# Truncate hex value at 7 characters. 
COLARRAY[7]="${COLOR7:0:7}"

COLOR8=$(convert ${MICROIMG} -crop '1x1+7+0' txt:-)
# Remove newlines 
COLOR8=${COLOR8//$'\n'/}
# Extract the hex color value
COLOR8=$(echo "$COLOR8" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')
# Truncate hex value at 7 characters. 
COLARRAY[8]="${COLOR8:0:7}"

COLOR9=$(convert ${MICROIMG} -crop '1x1+8+0' txt:-)
# Remove newlines 
COLOR9=${COLOR9//$'\n'/}
# Extract the hex color value
COLOR9=$(echo "$COLOR9" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')
# Truncate hex value at 7 characters. 
COLARRAY[9]="${COLOR9:0:7}"

COLOR10=$(convert ${MICROIMG} -crop '1x1+9+0' txt:-)
# Remove newlines 
COLOR10=${COLOR10//$'\n'/}
# Extract the hex color value
COLOR10=$(echo "$COLOR10" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')
# Truncate hex value at 7 characters. 
COLARRAY[10]="${COLOR10:0:7}"

COLOR11=$(convert ${MICROIMG} -crop '1x1+10+0' txt:-)
# Remove newlines 
COLOR11=${COLOR11//$'\n'/}
# Extract the hex color value
COLOR11=$(echo "$COLOR11" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')
# Truncate hex value at 7 characters. 
COLARRAY[11]="${COLOR11:0:7}"

COLOR12=$(convert ${MICROIMG} -crop '1x1+11+0' txt:-)
# Remove newlines 
COLOR12=${COLOR12//$'\n'/}
# Extract the hex color value
COLOR12=$(echo "$COLOR12" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')
# Truncate hex value at 7 characters. 
COLARRAY[12]="${COLOR12:0:7}"

COLOR13=$(convert ${MICROIMG} -crop '1x1+12+0' txt:-)
# Remove newlines 
COLOR13=${COLOR13//$'\n'/}
# Extract the hex color value
COLOR13=$(echo "$COLOR13" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')
# Truncate hex value at 7 characters. 
COLARRAY[13]="${COLOR13:0:7}"

COLOR14=$(convert ${MICROIMG} -crop '1x1+13+0' txt:-)
# Remove newlines 
COLOR14=${COLOR14//$'\n'/}
# Extract the hex color value
COLOR14=$(echo "$COLOR14" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')
# Truncate hex value at 7 characters. 
COLARRAY[14]="${COLOR14:0:7}"

COLOR15=$(convert ${MICROIMG} -crop '1x1+14+0' txt:-)
# Remove newlines 
COLOR15=${COLOR15//$'\n'/}
# Extract the hex color value
COLOR15=$(echo "$COLOR15" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')
# Truncate hex value at 7 characters. 
COLARRAY[15]="${COLOR15:0:7}"

COLOR16=$(convert ${MICROIMG} -crop '1x1+15+0' txt:-)
# Remove newlines 
COLOR16=${COLOR16//$'\n'/}
# Extract the hex color value
COLOR16=$(echo "$COLOR16" | sed 's/.*[[:space:]]\(#[a-zA-Z0-9]\+\)[[:space:]].*/\1/')
# Truncate hex value at 7 characters. 
COLARRAY[16]="${COLOR16:0:7}"

# Delete micro image
rm ${MICROIMG}

# SET COLOR VARIABLES ---------------------------------------------------------------

echo ""
echo " Building a randomized color map"

# All colors are randomly selected from a range. We can't have complete
# randomization otherwize the conky might be unreadable, so we make it
# random within an acceptable range. The full color range is from 1 to 16.

# Background color. We select from the darkest 3 colors.
RND=$(shuf -i 1-3 -n 1)
COLOR_BACKGROUND="${COLARRAY[${RND}]}"

# Border color. Colors 5-13
RND=$(shuf -i 5-13 -n 1)
COLOR_BORDER="${COLARRAY[${RND}]}"

# Weather icon color. Colors 12-16
RND=$(shuf -i 12-16 -n 1)
COLOR_ICON="${COLARRAY[${RND}]}"

# Horizontal rule color. Colors 5-14
RND=$(shuf -i 5-14 -n 1)
COLOR_HR="${COLARRAY[${RND}]}"

# Bars normal. Colors 9-16
RND=$(shuf -i 9-16 -n 1)
COLOR_BARS_NORM="${COLARRAY[${RND}]}"

# Bars warning
# Hard code this red
COLOR_BARS_WARN="#fc1b0f"

# Time color. Colors 12-16
RND=$(shuf -i 12-16 -n 1)
COLOR_TIME="${COLARRAY[${RND}]}"

# Date color. Colors 10-16
RND=$(shuf -i 10-16 -n 1)
COLOR_DATE="${COLARRAY[${RND}]}"

# Weather data color. Colors 12-16
RND=$(shuf -i 12-16 -n 1)
COLOR_WEATHER="${COLARRAY[${RND}]}"

# Headings. Colors 9-16
RND=$(shuf -i 9-16 -n 1)
COLOR_HEADING="${COLARRAY[${RND}]}"

# Subheadings. Colors 9-16
RND=$(shuf -i 9-16 -n 1)
COLOR_SUBHEADING="${COLARRAY[${RND}]}"

# Data values. Colors 8-16
RND=$(shuf -i 8-16 -n 1)
COLOR_DATA="${COLARRAY[${RND}]}"

# Color text. Colors 8-16
RND=$(shuf -i 8-16 -n 1)
COLOR_TEXT="${COLARRAY[${RND}]}"


# COPY SVG ICONS TO TMP/DIRECTORY  ------------------------------------------------------
# We do this because we need to open each SVG and replace the color value. 
# No reason to mess with the originals.

# Path to directory that we copy the SVGs to.
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
# These are the icons that get displayed in the conky.

echo ""
echo ""
echo " Caching the current weather and forecast icons"

# Fetch the weather and forecast codes from the JSON file.
# These will get matchedd to a PNG image with the same name below.
CRWEATHERCODE=$(jq .query.results.channel.item.condition.code ${CACHE_DIRECTORY}/${JSON_CACHE_FILE} | grep -oP '"\K[^"\047]+(?=["\047])')
FORECASTCODE1=$(jq .query.results.channel.item.forecast[1].code ${CACHE_DIRECTORY}/${JSON_CACHE_FILE} | grep -oP '"\K[^"\047]+(?=["\047])')
FORECASTCODE2=$(jq .query.results.channel.item.forecast[2].code ${CACHE_DIRECTORY}/${JSON_CACHE_FILE} | grep -oP '"\K[^"\047]+(?=["\047])')
FORECASTCODE3=$(jq .query.results.channel.item.forecast[3].code ${CACHE_DIRECTORY}/${JSON_CACHE_FILE} | grep -oP '"\K[^"\047]+(?=["\047])')
FORECASTCODE4=$(jq .query.results.channel.item.forecast[4].code ${CACHE_DIRECTORY}/${JSON_CACHE_FILE} | grep -oP '"\K[^"\047]+(?=["\047])')
FORECASTCODE5=$(jq .query.results.channel.item.forecast[5].code ${CACHE_DIRECTORY}/${JSON_CACHE_FILE} | grep -oP '"\K[^"\047]+(?=["\047])')

# Copy the PNG image with the matching weather/forecast code number to the cache folder
cp -f ${WEATHER_ICONS_PNG_DIRECTORY}/${CRWEATHERCODE}.png ${CACHE_DIRECTORY}/weather.png
cp -f ${WEATHER_ICONS_PNG_DIRECTORY}/${FORECASTCODE1}.png ${CACHE_DIRECTORY}/forecast1.png
cp -f ${WEATHER_ICONS_PNG_DIRECTORY}/${FORECASTCODE2}.png ${CACHE_DIRECTORY}/forecast2.png
cp -f ${WEATHER_ICONS_PNG_DIRECTORY}/${FORECASTCODE3}.png ${CACHE_DIRECTORY}/forecast3.png
cp -f ${WEATHER_ICONS_PNG_DIRECTORY}/${FORECASTCODE4}.png ${CACHE_DIRECTORY}/forecast4.png
cp -f ${WEATHER_ICONS_PNG_DIRECTORY}/${FORECASTCODE5}.png ${CACHE_DIRECTORY}/forecast5.png

# REPLACE TEMPLATE VARIABLES ------------------------------------------------------------
# Now it's time to insert the randomly gathered color values into the template

echo ""
echo " Inserting color values into the conky template"

# Before replacing vars make a copy of the template
cp ${TEMPLATE_SELECTION} ${CACHE_DIRECTORY}/conkyrc

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


# REPLACE CONKYRC FILE AND RELAUNCH -----------------------------------------------------

echo ""
echo " Shutting down Conky"
pkill conky

echo ""
echo " Exporting new .conkyrc file"

# Copy conkyrc file to its proper location
cp ${CACHE_DIRECTORY}/conkyrc ~/.conkyrc

# Launch conky
echo ""
echo " Relaunching Conky"
conky 2>/dev/null

# Remove the temporary template file
rm ${CACHE_DIRECTORY}/conkyrc

echo ""
echo " Done!"
echo ""
