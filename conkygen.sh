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

# Is Inkscape installed? The SVG to PNG converter is better in Inkscape.
# If it's installed we'll use it for that part of the process
converter="ImageMagick"
if [ "$(command -v inkscape)" >/dev/null 2>&1 ]; then
    converter="Inkscape"
fi

# WELCOME MESSAGE ---------------------------------------------------------------------

echo ""
echo "--------------------------------------------------------------------"
echo "           Welcome to ConkyMatic Version ${VERSION}"
echo "--------------------------------------------------------------------"

echo ""
echo "Please select MODE:"
echo "1) Automatic. The colors will be auto-selected from the wallpaper colors."
echo "2) Manual. You will be prompted to enter each color hex value."
read MODE

# Validate mode. 
if [[ ${MODE} -ne 1 && ${MODE} -ne 2 ]]; then
    echo ""
    echo "Invalid mode. Aborting..."
    echo ""
    exit 1
fi


# Manual mode
if [[ ${MODE} -eq 2 ]]; then

    # WEATHER ICON COLOR --------------------------------------------------------------------

    echo ""
    echo "Enter the WEATHER ICON color value (in hex)"
    echo "Or hit ENTER to apply default color ${COLOR_ICON}:"
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
        if [[ ${#R_COLOR_ICON} -ne 7 ]]; then
            echo "Your hex value isn't correct. It must be 6 characters in length, or 7 if you include the # symbol."
            echo ""
            exit 1
        fi

        COLOR_ICON="${R_COLOR_ICON}"
    fi

    # PRIMARY TEXT COLOR ---------------------------------------------------------------------

    echo ""
    echo "Enter the PRIMARY text color value (in hex)"
    echo "Or hit ENTER to apply default color ${COLOR_PRIMARY}:"
    read R_COLOR_PRIMARY

    if [[ ${R_COLOR_PRIMARY} != "" ]]; then

        # Did they submit a valid HEX value?
        if ! [[ $R_COLOR_PRIMARY =~ ^[\#a-fA-F0-9]+$ ]]; then 
            echo "The color you entered does not appear to be valid. Aborting..."
            echo ""
            exit 1
        fi

        # Add the # character if they omitted it from the hex color
        if [[ ${R_COLOR_PRIMARY:0:1} != "#" ]]; then
            R_COLOR_PRIMARY="#${R_COLOR_ACCENT}"
        fi

        # The hex color should now be 7 characters. Ex: #ffffff
        if [[ ${#R_COLOR_PRIMARY} -ne 7 ]]; then
            echo "Your hex value isn't correct. It must be 6 characters in length, or 7 if you include the # symbol."
            echo ""
            exit 1
        fi

        COLOR_PRIMARY="${R_COLOR_PRIMARY}"
    fi

    # ACCENT TEXT COLOR ---------------------------------------------------------------------

    echo ""
    echo "Enter the ACCENT text color value (in hex)"
    echo "Or hit ENTER to apply default color ${COLOR_ACCENT}:"
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
        if [[ ${#R_COLOR_ACCENT} -ne 7 ]]; then
            echo "Your hex value isn't correct. It must be 6 characters in length, or 7 if you include the # symbol."
            echo ""
            exit 1
        fi

        COLOR_ACCENT="${R_COLOR_ACCENT}"
    fi

    # DATA TEXT COLOR -----------------------------------------------------------------------

    echo ""
    echo "Enter the DATA text color value (in hex)"
    echo "Or hit ENTER to apply default color ${COLOR_DATA}:"
    read R_COLOR_DATA

    if [[ ${R_COLOR_DATA} != "" ]]; then

        # Did they submit a valid HEX value?
        if ! [[ $R_COLOR_DATA =~ ^[\#a-fA-F0-9]+$ ]]; then 
            echo "The color you entered does not appear to be valid. Aborting..."
            echo ""
            exit 1
        fi

        # Add the # character if they omitted it from the hex color
        if [[ ${R_COLOR_DATA:0:1} != "#" ]]; then
            R_COLOR_DATA="#${R_COLOR_DATA}"
        fi

        # The hex color should now be 7 characters. Ex: #ffffff
        if [[ ${#R_COLOR_DATA} -ne 7 ]]; then
            echo "Your hex value isn't correct. It must be 6 characters in length, or 7 if you include the # symbol."
            echo ""
            exit 1
        fi

        COLOR_DATA="${R_COLOR_DATA}"
    fi

    # HR COLOR ------------------------------------------------------------------------------

    echo ""
    echo "Enter the HORIZONTAL RULE color value (in hex)"
    echo "Or hit ENTER to apply default color ${COLOR_HR}:"
    read R_COLOR_HR

    if [[ ${R_COLOR_HR} != "" ]]; then

        # Did they submit a valid HEX value?
        if ! [[ $R_COLOR_HR =~ ^[\#a-fA-F0-9]+$ ]]; then 
            echo "The color you entered does not appear to be valid. Aborting..."
            echo ""
            exit 1
        fi

        # Add the # character if they omitted it from the hex color
        if [[ ${R_COLOR_HR:0:1} != "#" ]]; then
            R_COLOR_HR="#${R_COLOR_HR}"
        fi

        # The hex color should now be 7 characters. Ex: #ffffff
        if [[ ${#R_COLOR_HR} -ne 7 ]]; then
            echo "Your hex value isn't correct. It must be 6 characters in length, or 7 if you include the # symbol."
            echo ""
            exit 1
        fi

        COLOR_HR="${R_COLOR_HR}"
    fi

    # BORDER COLOR --------------------------------------------------------------------------

    echo ""
    echo "Enter the WINDOW BORDER color value (in hex)"
    echo "Or hit ENTER to apply default color ${COLOR_BORDER}:"
    read R_COLOR_BORDER

    if [[ ${R_COLOR_BORDER} != "" ]]; then

        # Did they submit a valid HEX value?
        if ! [[ $R_COLOR_BORDER =~ ^[\#a-fA-F0-9]+$ ]]; then 
            echo "The color you entered does not appear to be valid. Aborting..."
            echo ""
            exit 1
        fi

        # Add the # character if they omitted it from the hex color
        if [[ ${R_COLOR_BORDER:0:1} != "#" ]]; then
            R_COLOR_BORDER="#${R_COLOR_BORDER}"
        fi

        # The hex color should now be 7 characters. Ex: #ffffff
        if [[ ${#R_COLOR_BORDER} -ne 7 ]]; then
            echo "Your hex value isn't correct. It must be 6 characters in length, or 7 if you include the # symbol."
            echo ""
            exit 1
        fi

        COLOR_BORDER="${R_COLOR_BORDER}"
    fi

    # BATTERY INDICATOR COLOR ---------------------------------------------------------------

    echo ""
    echo "Enter the BATTERY INDICATOR color value (in hex)"
    echo "Or hit ENTER to apply default color ${COLOR_BAT_FULL}:"
    read R_COLOR_BAT_FULL

    if [[ ${R_COLOR_BAT_FULL} != "" ]]; then

        # Did they submit a valid HEX value?
        if ! [[ $R_COLOR_BAT_FULL =~ ^[\#a-fA-F0-9]+$ ]]; then 
            echo "The color you entered does not appear to be valid. Aborting..."
            echo ""
            exit 1
        fi

        # Add the # character if they omitted it from the hex color
        if [[ ${R_COLOR_BAT_FULL:0:1} != "#" ]]; then
            R_COLOR_BAT_FULL="#${R_COLOR_BAT_FULL}"
        fi

        # The hex color should now be 7 characters. Ex: #ffffff
        if [[ ${#R_COLOR_BAT_FULL} -ne 7 ]]; then
            echo "Your hex value isn't correct. It must be 6 characters in length, or 7 if you include the # symbol."
            echo ""
            exit 1
        fi

        COLOR_BAT_FULL="${R_COLOR_BAT_FULL}"
    fi

    # BATTERY EMPTY COLOR -------------------------------------------------------------------

    echo ""
    echo "Enter the BATTERY EMPTY INDICATOR color value (in hex)"
    echo "Or hit ENTER to apply default color ${COLOR_BAT_EMPT}:"
    read R_COLOR_BAT_EMPT

    if [[ ${R_COLOR_BAT_EMPT} != "" ]]; then

        # Did they submit a valid HEX value?
        if ! [[ $R_COLOR_BAT_EMPT =~ ^[\#a-fA-F0-9]+$ ]]; then 
            echo "The color you entered does not appear to be valid. Aborting..."
            echo ""
            exit 1
        fi

        # Add the # character if they omitted it from the hex color
        if [[ ${R_COLOR_BAT_EMPT:0:1} != "#" ]]; then
            R_COLOR_BAT_EMPT="#${R_COLOR_BAT_EMPT}"
        fi

        # The hex color should now be 7 characters. Ex: #ffffff
        if [[ ${#R_COLOR_BAT_EMPT} -ne 7 ]]; then
            echo "Your hex value isn't correct. It must be 6 characters in length, or 7 if you include the # symbol."
            echo ""
            exit 1
        fi

        COLOR_BAT_EMPT="${R_COLOR_BAT_EMPT}"
    fi


    # BACKGROUND TRANPARENCY COLOR ----------------------------------------------------------

    echo ""
    echo "Enter the BACKGROUND TRANSPARENCY value (0-255)"
    echo "Or hit ENTER to apply default value ${BG_TRANS}:"
    read R_BG_TRANS

    if [[ ${R_BG_TRANS} != "" ]]; then

        # Is the trans value within range?
        if [[ ${R_BG_TRANS} -lt 0 || ${R_BG_TRANS} -gt 255  ]]; then
            echo "The transparency value must be between 0 and 255. Aborting..."
            echo ""
            exit 1
        fi

        BG_TRANS="${R_BG_TRANS}"
    fi

fi 


# DOWNLOAD THE WEATHER JSON FILE --------------------------------------------------------

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



# GENERATE COLORPALETTE PNG -------------------------------------------------------------

echo ""
echo "Generating colorpalette image."

# Use ImageMagick to create a color palette image based on the current wallpaper
convert ${WALLPAPERPATH} \
+dither \
-colors ${COLORPN} \
-unique-colors \
-filter box \
-geometry ${COLORPWIDTH} \
${CACHEDIR}/${COLORPIMG}

# If the user selected automatic mode we need to grab the hex values from the colorpalette PNG.
if [[ ${MODE} -eq 1 ]]; then

    palette_image="${CACHEDIR}/${COLORPIMG}"

    # Create a text file with the color values
    convert ${palette_image} -format %c -depth 8  histogram:info:/tmp/colorpalette.txt

    # Extract hex color values
    sed -r 's/.*[[:space:]](\#[a-zA-Z0-9]+)[[:space:]].*/\1/w /tmp/hexcolors.txt' /tmp/colorpalette.txt > /tmp/hexcolors.txt;

    readarray -t COLARRAY </tmp/hexcolors.txt

    # Set the variables

    # Background color
    COLOR_BG="${COLARRAY[2]}"

    # Border color
    COLOR_BORDER="${COLARRAY[11]}"

    # Weather icon color
    COLOR_ICON="${COLARRAY[13]}"

    # Primary text color
    COLOR_PRIMARY="${COLARRAY[14]}"

    # Data text color
    COLOR_DATA="${COLARRAY[13]}"

    # Accent text color
    COLOR_ACCENT="${COLARRAY[12]}"

    # HR color
    COLOR_HR="${COLARRAY[11]}"

    # Battery bar color
    COLOR_BAT_FULL="${COLARRAY[12]}"


fi 


# COPY SVG TO TMP/DIRECTORY  ------------------------------------------------------------

# Name of the temp directory that we will copy the SVGs to.
TEMPDIR="/tmp/SVGCONVERT"

# Copy the master svg images to the temp directory.
# We don't want to mess with the originals.
cp -R "${BASEURL}/${SVGICONS}" "${TEMPDIR}"


# REPLACE COLOR IN SVG FILES ------------------------------------------------------------

# We now open each SVG file in the temp directory and replace the fill color
for filepath in "${TEMPDIR}"/*.svg
    do
    # Match the pattern: fill="#hexval" and replace with the new color
    sed -i -e "s/fill=\"#[[:alnum:]]*\"/fill=\"${COLOR_ICON}\"/g" "$filepath"
done

# CONVERT SVG TO PNG  -------------------------------------------------------------------

echo ""
echo "Converting images using: $converter"
echo ""

for filepath in "${TEMPDIR}"/*.svg
    do

    # Extract the filename from the path
    filename="${filepath##*/}"

    # Remove the file extension, leaving only the name  
    name="${filename%%.*}"

    echo "Converting ${filename}"

    # Convert to PNG using either Inkscape or ImageMagick
    if [[ $converter == "inkscape" ]]
    then
        inkscape -z -e \
        "${BASEURL}/${PNGICONS}/${name}.png" \
        -w "${ICONSIZE}" \
        -h "${ICONSIZE}" \
        "$filepath" \
        >/dev/null 2>&1 || { 
                                echo "An error was encountered. Aborting...";
                                rm -R "${TEMPDIR}";
                                exit 1; 
                            }
    else
        convert \
        -background none \
        -density 1500 \
        -resize "${ICONSIZE}x${ICONSIZE}!" \
        "$filepath" \
        "${BASEURL}/${PNGICONS}/${name}.png" \
        >/dev/null 2>&1 || { 
                                echo "An error was encountered. Aborting..."; 
                                rm -R "${TEMPDIR}";
                                exit 1;
                            }
    fi

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
cp -f ${PNGICONS}/${CRWEATHERCODE}.png ${CACHEDIR}/weather.png
cp -f ${PNGICONS}/${FORECASTCODE1}.png ${CACHEDIR}/forecast1.png
cp -f ${PNGICONS}/${FORECASTCODE2}.png ${CACHEDIR}/forecast2.png
cp -f ${PNGICONS}/${FORECASTCODE3}.png ${CACHEDIR}/forecast3.png
cp -f ${PNGICONS}/${FORECASTCODE4}.png ${CACHEDIR}/forecast4.png
cp -f ${PNGICONS}/${FORECASTCODE5}.png ${CACHEDIR}/forecast5.png



# REPLACE TEMPLATE VARIABLES ------------------------------------------------------------

echo ""
echo "Building conkyrc file based on ${TEMPLFILE}"

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
echo ""
echo "Shutting down conky."
pkill conky
    
# Copy conkyrc file to its proper location
echo ""
echo "Copying new .conkyrc file to home directory."
cp ${CACHEDIR}/conkyrc ~/.conkyrc

# Remove the temp file
echo ""
echo "Deleting temporary .conkyrc file"
rm ${CACHEDIR}/conkyrc

# Launch conky
echo ""
echo "Relaunching conky."
conky 2>/dev/null

echo ""
echo "Done!"
echo ""