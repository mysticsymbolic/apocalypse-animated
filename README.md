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
