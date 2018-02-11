# ConkyMatic

<img src="https://i.imgur.com/5C8xmwo.png" />

## ConkyMatic is a shell script that:

* Creates a 16 color palette image from the current wallpaper (see the bottom of the Conky in the images).

* Extracts the hex color value of each of the 16 images in the color palette.

* Generates a .conkyrc file using colors randomly selected from that palette. 

* Exports a set of colorized weather icons.

* Copies the new .conkyrc file to the home folder and relaunches the Conky application.

The entires sequence takes the script about 10 seconds, making it very fast and easy to build a fresh conky every time the wallpaper is changed. And since the colors are randomly selected, running the script multiple times with the same wallpaper will yield different results.

### [YouTube Video](https://youtu.be/sq9HvFkPffM)

## Requirements
* A __Linux__ installation with __Conky__ installed.

* __ImageMagick__ to generate the color palette PNG and weather icons. You can install ImageMagick using your preferred package manager. __Note:__ If you have __Inkscape__ is installed, ConkyMatic will use it for the weather icon rendering since it has better SVG handling. However, ImageMagick is still necessary for the palette generation.

* __XFCE Desktop__. The script should work regardless of the desktop environment you use. However, you'll have to update the __WALLPAPERPATH__ config variable near the top of the conkymatic.sh script with a query that retrieves the wallpaper on your system.

## Installation and Usage.
Just clone the package, update the config variables at the top of __conkymatic.sh__, and run the script.

__Important:__ Before running ConkyMatic make a backup copy of your .conkyrc file since it will get overwritten. 

<img src="https://i.imgur.com/Za81gmK.png" />

<img src="https://i.imgur.com/Z6UPjym.png" />

## Customization
In the __templates__ directory you'll find the __default.conky__ template. This is a normal .conkyrc file, except it contains some variables that get replaced with the color values from the script. A list of available variables can be found below.

Additional templates can be added to the __Templates__ folder. If more than one template is in the folder, when you run the __conkymatic.sh__ script via your terminal you'll be given a choice of templates

## ConkyMatic Terminal Alias
To make running the script faster you can add the following alias to your __.bashrc__ file:

    function conkymatic() {
        $HOME/path/to/ConkyMatic/conkymatic.sh
    }

Then just enter __conkymatic__ from your terminal.

__Note:__ Make sure you change the path in the function to reflect your particular path.

## Template Variables
The template variables are just text placeholders which get replaced when the script gets run. The following variables are available for use.

    

    _VAR:COLOR_TIME_
    _VAR:COLOR_DATE_
    _VAR:COLOR_WEATHER_
    _VAR:COLOR_HEADINGS_
    _VAR:COLOR_SUBHEADINGS_
    _VAR:COLOR_TEXT_
    _VAR:COLOR_DATA_
    _VAR:COLOR_HR_
    _VAR:COLOR_BARS_NORM_
    _VAR:COLOR_BARS_WARN_
    _VAR:COLOR_BORDER_
    _VAR:COLOR_BG_

Or, if you prefer you can use numbered values which are mapped to the respective ${colorX} variables.

    _VAR:COLOR_0_
    _VAR:COLOR_1_
    _VAR:COLOR_2_
    _VAR:COLOR_3_
    _VAR:COLOR_4_
    _VAR:COLOR_5_
    _VAR:COLOR_6_
    _VAR:COLOR_7_
    _VAR:COLOR_8_
    _VAR:COLOR_9_




<img src="https://i.imgur.com/lKZKCx3.png" />

<img src="https://i.imgur.com/rsVC1AX.png" />




<img src="https://i.imgur.com/udb0bqo.png" />



<img src="https://i.imgur.com/YBHxfg1.png" />

<img src="https://i.imgur.com/mBXnK3t.png" />
