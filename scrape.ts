import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import * as cheerio from 'cheerio';
import fetch from "node-fetch";

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

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const BASE_URL = "https://apocalypseanimated.com/";

const CACHE_DIR = path.join(__dirname, '.cache');

function writeTextFile(filename: string, value: string) {
    const dirname = path.dirname(filename);
    if (!fs.existsSync(dirname)) {
        fs.mkdirSync(dirname, { recursive: true });
    }
    fs.writeFileSync(filename, value, {encoding: 'utf-8'});
}

function readTextFile(filename: string) {
    return fs.readFileSync(filename, {encoding: 'utf-8'});
}

async function fetchTextFile(url: string, cachedFilename: string): Promise<string> {
    const abspath = path.join(CACHE_DIR, cachedFilename);
    if (!fs.existsSync(abspath)) {
        console.log(`Retrieving ${url} and caching it at ${cachedFilename}.`);
        const req = await fetch(url);
        if (!req.ok) {
            throw new Error(`Got HTTP ${req.status} when retrieving ${url}`);
        }
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
            const basename = path.posix.basename(pathname, '.gif');

            console.log(`TODO: Download ${basename} image at ${src} and convert it to mp4.`);
            chapter.items.push({
                type: "animation",
                basename,
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
