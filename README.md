# ConkyMatic
The ConkyMatic is a shell script that creates a 16 color palette image from the current wallpaper, then generates a Conky using colors randomly selected from that palette, and exports a set of colorized weather icons. 

The new .conkyrc file then gets copied to the user's home folder, replacing the current one, and the Conky application is relaunched.

The entires sequence takes the script about 10 seconds, making it very fast and easy to build a fresh conky every time the wallpaper is changed. You can also run the script repeatedly with the same wallpaper choice, and each time the selected colors will be slightly different.
