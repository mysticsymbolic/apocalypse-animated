This is an attempt to make Nina Paley's [Apocalypse Animated](https://apocalypseanimated.com) into a mobile app.

## Quick start

Open `ios/apocalypse-animated.xcodeproj` in XCode.

## Downloading content

A scraper downloads content from the Apocalypse Animated website and parses it into data used by the mobile app. Whenever it changes, you may need to re-run the scraper:

```
rm -rf .cache   # Obliterate any previously downloaded data.
npm run build   # Or `npm run watch` if you want to iterate on the scraper.
node scrape.js
```

### Converting videos

Note that if the scraper encounters any animated GIFs that aren't already in `content/video`, it will try to convert them to mp4 via `ffmpeg` (which you need to install manually).

Optionally, you can use raw 4k videos instead of animated GIFs, but you will have to obtain those separately and put them in a folder called `4k`.  This folder should contain subfolders that start with `Rev` (for each revelation), each of which contain `.mov` files.  The scraper will automatically detect if the `4k` folder exists and use that instead of converting animated GIFs as needed.

If you want to re-convert an existing video, you will need to remove it from `content/video` in order for the scraper to re-convert it.
