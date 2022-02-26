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

function convertGifToMp4(absGifPath: string, absMp4Path: string) {
    const relGifPath = rootRelativePosixPath(absGifPath);
    const relMp4Path = rootRelativePosixPath(absMp4Path);
    const ffmpegCmdline = `ffmpeg -i ${relGifPath} -movflags faststart -pix_fmt yuv420p -vf 'scale=trunc(iw/2)*2:trunc(ih/2)*2' ${relMp4Path}`
    console.log(`Converting ${relGifPath} -> ${relMp4Path}.`);
    // Running this through bash to support running a WSL2-based ffmpeg on Windows.
    child_process.execSync(`bash -c "${ffmpegCmdline}"`);
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
            const text = $(item).text();
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
            const width = parseInt($(item).attr('width') || '');
            const height = parseInt($(item).attr('height') || '');
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
                const absGifPath = await cacheBinaryFile(src, filename);
                convertGifToMp4(absGifPath, absMp4Path);
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
