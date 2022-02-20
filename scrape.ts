import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import * as cheerio from 'cheerio';
import fetch, {Response} from "node-fetch";

type ChapterItem = {
    type: "verse",
    number: number,
    text: string
} | {
    type: "animation",
    basename: string,
    width: number,
    height: number
};

type Chapter = {
    title: String;
    items: ChapterItem[];
};

const ROOT_DIR = path.dirname(fileURLToPath(import.meta.url));

const BASE_URL = "https://apocalypseanimated.com/";

const CACHE_DIR = path.join(ROOT_DIR, '.cache');

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

    let verseNumber = 0;

    for (let item of items) {
        if (item.name === 'p') {
            verseNumber += 1;
            $('sup, strong', item).remove();
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
            const filename = path.posix.basename(pathname);
            const ext = path.posix.extname(filename);
            const stem = path.posix.basename(filename, ext);

            await cacheBinaryFile(src, filename);
            console.log(`TODO: Convert ${filename} to mp4.`);
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
        const chapter: Chapter = {
            title,
            items: []
        };
        const filename = `${title.replace(/\s/g, '-').toLowerCase()}.html`;
        const chapterHtml = await fetchTextFile(url, filename);
        chapters.push(await scrapeChapter(chapter, chapterHtml));
    }
    // console.log(JSON.stringify(chapters, null, 4));
    console.log(`TODO: Write ${chapters.length} chapters.`);
}

main().catch(e => {
    console.log(e);
    process.exit(1);
});
