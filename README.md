# ConkyMatic

## Conky generator based on the wallpaper colors.

<img src="https://i.imgur.com/5C8xmwo.png" />

ConkyMatic is a shell script written in Bash that:

* Creates a 16 color palette image from the current wallpaper.

* Generates a .conkyrc file using colors randomly selected from that palette. 

* Exports a set of colorized weather icons.

* Copies the new .conkyrc file to the user's home folder and relaunches the Conky application.

The entires sequence takes the script about 10 seconds, making it very fast and easy to build a fresh conky every time the wallpaper is changed. And since the colors are randomly selected, running the script multiple times with the same wallpaper will yield different results.

[YouTube Video](https://youtu.be/sq9HvFkPffM)



<img src="https://i.imgur.com/Za81gmK.png" />

<img src="https://i.imgur.com/Z6UPjym.png" />

<img src="https://i.imgur.com/lKZKCx3.png" />

<img src="https://i.imgur.com/rsVC1AX.png" />

## Requirements
* A Linux installation with Conky installed.

* ImageMagick to generate the color palette PNG and weather icons. Note: If Inkscape is installed ConkyMatic will use it for the weather icon rendering since it has better SVG handling than ImageMagic.






<img src="https://i.imgur.com/YBHxfg1.png" />

<img src="https://i.imgur.com/mBXnK3t.png" />
