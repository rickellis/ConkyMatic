# ConkyMatic

<img src="https://i.imgur.com/5C8xmwo.png" />

## ConkyMatic is a shell script that:

* Creates a 16 color palette image from the current wallpaper (look at the bottom of the Conky in the screenshots)

* Extracts the hex color value of each of the 16 images in the color palette.

* Generates a .conkyrc file using colors randomly selected from that palette. 

* Exports a set of colorized weather icons.

* Copies the new .conkyrc file to the home folder and relaunches the Conky application.

The entire sequence takes the script about 10 seconds, making it very fast and easy to build a fresh conky every time you change your wallpaper. And since the colors are randomly selected, running the script multiple times with the same wallpaper will yield different results.

### [YouTube Video](https://youtu.be/1oh5d-5QJ0U)

<img src="https://i.imgur.com/Za81gmK.png" />

## Requirements
* A __Linux__ installation with __Conky__ installed.

* __ImageMagick__ to generate the color palette PNG and weather icons. You can install ImageMagick using your preferred package manager. __Note:__ If you have __Inkscape__ is installed, ConkyMatic will use it for the weather icon rendering since it has better SVG handling. However, ImageMagick is still necessary for the palette generation.

* __Curl__ to download JSON weather data. You can install Curl using your preferred package manager.

* __XFCE Desktop__. The script should work regardless of the desktop environment you use. However, you'll have to update the __WALLPAPER_PATH__ config variable near the top of the __conkymatic.sh__ script with a query that retrieves the wallpaper on your system.

* __Roboto Font__. The default Conky template uses [Roboto](https://www.dafont.com/roboto.font).

## Installation and Usage.
Just clone the package, update the config variables at the top of __conkymatic.sh__, and run the script.

__Important:__ Before running ConkyMatic make a backup copy of your .conkyrc file since it will get overwritten. 


## Customization
In the __Templates__ directory you'll find the __default.conky__ template. This is a normal .conkyrc file, except it contains some pseudo-variables that get replaced by the script with random color values. A list of available variables can be found below.

Additional templates can be created and added to the __Templates__ folder. If more than one template is in the folder, when you run the __conkymatic.sh__ script via your terminal you'll be given a choice of templates. Hitting __ENTER__ in the terminal will auto-select the template named __default.conky__, or you can type the name of the one you prefer to run.

__IMPORTANT:__ all templates must be named with the __.conky__ file extension: Example: foobar.conky

## ConkyMatic Terminal Alias
To make running the script faster you can add the following alias to your __.bashrc__ file, and then just enter __conkymatic__ from your terminal.

    function conkymatic() {
        $HOME/path/to/ConkyMatic/conkymatic.sh
    }

__Note:__ Make sure you change the path in the function to reflect your particular path.

## Template Variables
The template variables are just text placeholders which get replaced when the script gets run. The following variables are available for use. The colors will be assigned automatically from your wallpaper colors.

    

    _VAR:COLOR_TIME_
    _VAR:COLOR_DATE_
    _VAR:COLOR_WEATHER_
    _VAR:COLOR_HEADING_
    _VAR:COLOR_SUBHEADING_
    _VAR:COLOR_TEXT_
    _VAR:COLOR_DATA_
    _VAR:COLOR_HR_
    _VAR:COLOR_BARS_NORM_
    _VAR:COLOR_BARS_WARN_
    _VAR:COLOR_BORDER_
    _VAR:COLOR_BACKGROUND_

In addition, the following path variables are available:

    _VAR:JSON_FILEPATH_
    _VAR:CACHE_DIRECTORY_
    _VAR:WEATHER_ICONS_PNG_DIRECTORY_
    _VAR:COLOR_PALETTE_FILEPATH_


## License

MIT License

https://opensource.org/licenses/MIT

You may use the source code in any manner you choose, as long as appropriate credit is given.


<img src="https://i.imgur.com/Z6UPjym.png" />

<img src="https://i.imgur.com/lKZKCx3.png" />

<img src="https://i.imgur.com/rsVC1AX.png" />

<img src="https://i.imgur.com/udb0bqo.png" />

