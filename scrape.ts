import path from 'path';
import fs from 'fs';
import child_process from 'child_process';
import { fileURLToPath } from 'url';
import * as cheerio from 'cheerio';
import fetch, {Response} from "node-fetch";

type ChapterItem = {
    type: "verse",
    number: number|null,
    text: string
} | {
    type: "animation",
    basename: string,
    width: number,
    height: number
};

type Chapter = {
    title: string;
    description: string;
    items: ChapterItem[];
};

const ROOT_DIR = path.dirname(fileURLToPath(import.meta.url));

const BASE_URL = "https://apocalypseanimated.com/";

const CACHE_DIR = path.join(ROOT_DIR, '.cache');

const CONTENT_DIR = path.join(ROOT_DIR, 'content');

const CONTENT_VIDEO_DIR = path.join(CONTENT_DIR, 'video');

const RAW_4K_VIDEO_DIR = path.join(ROOT_DIR, '4k');

const HAS_RAW_4K_VIDEO_DIR = fs.existsSync(RAW_4K_VIDEO_DIR);

const RAW_4K_DOWNSAMPLE_HEIGHT = 720;

const GET_DIMENSIONS_FROM_MP4 = true;

function parseVerseNumber(el: cheerio.Cheerio<cheerio.Element>): number|null {
    if (el.length === 1) {
        const text = el.text().trim();
        const verseNumber = parseInt(text);
        if (isNaN(verseNumber) || verseNumber <= 0) {
            console.log(`WARNING: Invalid verse number: "${text}"`);
        } else {
            return verseNumber;
        }
    } else if (el.length > 1) {
        console.log(`WARNING: Found ${el.length} potential verse numbers.`);
    }

    return null;
}

// https://www.30secondsofcode.org/js/s/levenshtein-distance
const levenshteinDistance = (s: string, t: string): number => {
  if (!s.length) return t.length;
  if (!t.length) return s.length;
  const arr = [];
  for (let i = 0; i <= t.length; i++) {
    arr[i] = [i];
    for (let j = 1; j <= s.length; j++) {
      arr[i][j] =
        i === 0
          ? j
          : Math.min(
              arr[i - 1][j] + 1,
              arr[i][j - 1] + 1,
              arr[i - 1][j - 1] + (s[j - 1] === t[i - 1] ? 0 : 1)
            );
    }
  }
  return arr[t.length][s.length];
};

function ensureDirExistsForFile(filename: string) {
    const dirname = path.dirname(filename);
    if (!fs.existsSync(dirname)) {
        fs.mkdirSync(dirname, { recursive: true });
    }
}

function writeTextFile(filename: string, value: string) {
    ensureDirExistsForFile(filename);
    fs.writeFileSync(filename, value, {encoding: 'utf-8'});
}

function readTextFile(filename: string): string {
    return fs.readFileSync(filename, {encoding: 'utf-8'});
}

function rootRelativePosixPath(absPath: string): string {
    return path.relative(ROOT_DIR, absPath).replace(/\\/g, path.posix.sep);
}

function getRaw4kVideoFiles(): Map<string, string> {
    const files = new Map<string, string>();

    for (const dirname of fs.readdirSync(RAW_4K_VIDEO_DIR)) {
        const absDirname = path.join(RAW_4K_VIDEO_DIR, dirname);
        if (dirname.startsWith('Rev') && fs.statSync(absDirname).isDirectory()) {
            for (const movname of fs.readdirSync(absDirname)) {
                const absMovname = path.join(absDirname, movname);
                const ext = path.extname(movname);
                if (ext === '.mov') {
                    const stem = path.basename(movname, ext).toLowerCase();
                    if (files.has(stem)) {
                        throw new Error(`Multiple entries for 4k movie "${stem}"!`);
                    }
                    files.set(stem, absMovname);
                }
            }
        }
    }

    return files;
}

function findClosestString(source: string, candidates: IterableIterator<string>): string {
    let bestCandidate: string|undefined;
    let bestDistance = Infinity;

    for (const candidate of candidates) {
        const distance = levenshteinDistance(source, candidate);
        if (distance < bestDistance) {
            bestCandidate = candidate;
            bestDistance = distance;
        }
    }

    if (bestCandidate === undefined) {
        throw new Error(`Must have at least one candidate!`);
    }

    return bestCandidate;
}

let cachedRaw4kVideoFiles: Map<string, string>|undefined;

function convert4kToMp4(stem: string, absMp4Path: string) {
    if (!cachedRaw4kVideoFiles) {
        cachedRaw4kVideoFiles = getRaw4kVideoFiles();
    }

    let absMovPath = cachedRaw4kVideoFiles.get(stem);
    if (!absMovPath) {
        const closestMatch = findClosestString(stem, cachedRaw4kVideoFiles.keys());
        console.log(`No exact 4k video match found for movie "${stem}", using "${closestMatch}".`);
        absMovPath = cachedRaw4kVideoFiles.get(closestMatch);
        if (!absMovPath) {
            throw new Error(`Assertion failure, closest match must have an entry!`);
        }
    }

    const relMovPath = rootRelativePosixPath(absMovPath);
    const relMp4Path = rootRelativePosixPath(absMp4Path);
    const ffmpegCmdline = `ffmpeg -i '${relMovPath}' -movflags faststart -pix_fmt yuv420p -vf scale=-2:${RAW_4K_DOWNSAMPLE_HEIGHT} ${relMp4Path}`
    console.log(`Converting ${relMovPath} -> ${relMp4Path}.`);
    // Running this through bash to support running a WSL2-based ffmpeg on Windows.
    child_process.execSync(`bash -c "${ffmpegCmdline}"`);
}

function convertGifToMp4(absGifPath: string, absMp4Path: string) {
    const relGifPath = rootRelativePosixPath(absGifPath);
    const relMp4Path = rootRelativePosixPath(absMp4Path);
    const ffmpegCmdline = `ffmpeg -i ${relGifPath} -movflags faststart -pix_fmt yuv420p -vf 'scale=trunc(iw/2)*2:trunc(ih/2)*2' ${relMp4Path}`
    console.log(`Converting ${relGifPath} -> ${relMp4Path}.`);
    // Running this through bash to support running a WSL2-based ffmpeg on Windows.
    child_process.execSync(`bash -c "${ffmpegCmdline}"`);
}

function getMp4Dimensions(absMp4Path: string): {width: number, height: number} {
    const cached = path.join(CACHE_DIR, `${path.basename(absMp4Path)}.dimensions.json`);
    const isCachedValid = fs.existsSync(cached) && fs.statSync(cached).mtime >= fs.statSync(absMp4Path).mtime
    if (!isCachedValid) {
        const relMp4Path = rootRelativePosixPath(absMp4Path);
        const ffmpegCmdline = `ffprobe -v error -select_streams v -show_entries stream=width,height -of json ${relMp4Path}`
        // Running this through bash to support running a WSL2-based ffmpeg on Windows.
        console.log(`Getting dimensions of ${relMp4Path}.`);
        const output = JSON.parse(child_process.execSync(`bash -c "${ffmpegCmdline}"`).toString('ascii'));
        fs.writeFileSync(cached, JSON.stringify(output.streams[0]), {encoding: 'utf-8'});
    }
    return JSON.parse(fs.readFileSync(cached, {encoding: 'utf-8'}));
}

function writeBinaryFile(filename: string, value: Buffer) {
    ensureDirExistsForFile(filename);
    fs.writeFileSync(filename, value);
}

async function fetchAndCheck(url: string): Promise<Response> {
    const req = await fetch(url);
    if (!req.ok) {
        throw new Error(`Got HTTP ${req.status} when retrieving ${url}`);
    }
    return req;
}

async function cacheBinaryFile(url: string, cachedFilename: string): Promise<string> {
    const abspath = path.join(CACHE_DIR, cachedFilename);
    if (!fs.existsSync(abspath)) {
        console.log(`Retrieving ${url} and caching it at ${cachedFilename}.`);
        const req = await fetchAndCheck(url);
        const arrayBuffer = await req.arrayBuffer();
        const view = new Uint8Array(arrayBuffer);
        writeBinaryFile(abspath, Buffer.from(view));
    } else {
        console.log(`Using cached content of ${url} at ${cachedFilename}.`);
    }
    return abspath;
}

async function fetchTextFile(url: string, cachedFilename: string): Promise<string> {
    const abspath = path.join(CACHE_DIR, cachedFilename);
    if (!fs.existsSync(abspath)) {
        console.log(`Retrieving ${url} and caching it at ${cachedFilename}.`);
        const req = await fetchAndCheck(url);
        writeTextFile(abspath, await req.text());
    } else {
        console.log(`Using cached content of ${url} at ${cachedFilename}.`);
    }
    return readTextFile(abspath);
}

async function scrapeChapter(chapter: Chapter, html: string): Promise<Chapter> {
    const $ = cheerio.load(html);

    const items = $('figure > img, p');

    for (let item of items) {
        if (item.name === 'p') {
            const verseNumberEl = $('sup, strong', item);
            const verseNumber = parseVerseNumber(verseNumberEl);
            verseNumberEl.remove();
            const text = $(item).text().trim();
            if (!text) {
                console.log(`WARNING: Found <p> without text!`);
                continue;
            }
            chapter.items.push({
                type: "verse",
                number: verseNumber,
                text,
            });
        } else if (item.name === 'img') {
            let width = parseInt($(item).attr('width') || '');
            let height = parseInt($(item).attr('height') || '');
            if (isNaN(width) || isNaN(height)) {
                throw new Error(`Found <img> without width and/or height!`);
            }
            const src = $(item).attr('src');
            if (!src) {
                throw new Error(`Found <img> without src!`);
            }
            if (!src.endsWith('.gif')) {
                console.log(`WARNING: Expected ${src} to end with .gif! Skipping it for now.`);
                continue;
            }
            const pathname = new URL(src).pathname;
            const filename = path.posix.basename(pathname).toLowerCase();
            const ext = path.posix.extname(filename);
            const stem = path.posix.basename(filename, ext);
            const mp4Filename = `${stem}.mp4`;
            const absMp4Path = path.join(CONTENT_VIDEO_DIR, mp4Filename);

            if (!fs.existsSync(absMp4Path)) {
                if (HAS_RAW_4K_VIDEO_DIR) {
                    convert4kToMp4(stem, absMp4Path);
                } else {
                    const absGifPath = await cacheBinaryFile(src, filename);
                    convertGifToMp4(absGifPath, absMp4Path);
                }
            }

            if (GET_DIMENSIONS_FROM_MP4) {
                const d = getMp4Dimensions(absMp4Path);
                width = d.width;
                height = d.height;
            }

            chapter.items.push({
                type: "animation",
                basename: stem,
                width,
                height
            });
        } else {
            throw new Error(`Assertion failure, found <${item.name}>`);
        }
    }

    return chapter;
}

async function main() {
    const chapters: Chapter[] = [];
    const indexHtml = await fetchTextFile(BASE_URL, 'index.html');
    const $ = cheerio.load(indexHtml);
    for (let li of $('ul > li')) {
        const link = $('a', li);
        const url = link.attr('href');
        const title = link.text();
        if (!url) {
            throw new Error('<a> has no href?!');
        }
        if (!title) {
            throw new Error('<a> has no text?!');
        }
        link.remove();
        const description = $(li).text().replace(' – ', '');
        const chapter: Chapter = {
            title,
            description,
            items: []
        };
        const filename = `${title.replace(/\s/g, '-').toLowerCase()}.html`;
        const chapterHtml = await fetchTextFile(url, filename);
        chapters.push(await scrapeChapter(chapter, chapterHtml));
    }
    const absJsonPath = path.join(CONTENT_DIR, 'chapters.json');
    fs.writeFileSync(absJsonPath, JSON.stringify(chapters, null, 4), {
        encoding: 'utf-8'
    });
    console.log(`Wrote ${chapters.length} chapters to ${rootRelativePosixPath(absJsonPath)}.`);
}

main().catch(e => {
    console.log(e);
    process.exit(1);
});
