This is an attempt to make Nina Paley's [Apocalypse Animated](https://apocalypseanimated.com) into an iOS app.

## Converting animated GIF to mp4

This can be done via e.g.:

```
ffmpeg -i Throne2_5.gif -movflags faststart -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" throne2_5.mp4
```
