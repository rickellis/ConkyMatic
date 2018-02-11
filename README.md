# ConkyMatic
The ConkyMatic is a shell script that:

* Creates a 16 color palette image from the current wallpaper.

* Generates a .conkyrc file using colors randomly selected from that palette. 

* Exports a set of colorized weather icons.

* Copies the new .conkyrc file to the user's home folder.

* Relaunches the Conky application.

The entires sequence takes the script about 10 seconds, making it very fast and easy to build a fresh conky every time the wallpaper is changed. Since the colors are randomly selected, running the script multiple times with the same wallpaper will yield different results.

<img src="https://i.imgur.com/YBHxfg1.png" />