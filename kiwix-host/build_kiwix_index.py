#!/usr/bin/env python3
"""Build a grouped index + A-Z appendix page for a kiwix-serve library.

Groups books by the NAS folder they live in (medicine, survival, ...),
using library.xml for paths/sizes and the server's OPDS catalog for
titles, summaries, and content links. Output is a single static HTML
file meant for `kiwix-serve --customIndex`.

Usage:
  python3 build_kiwix_index.py --library ~/kiwix/library.xml \
      --server http://localhost:8090 --out ~/kiwix/index.html
"""

import argparse
import html
import urllib.request
import xml.etree.ElementTree as ET
from datetime import date
from pathlib import Path

ATOM = "{http://www.w3.org/2005/Atom}"

# Folder -> (section title, order). Unknown folders sort last under their own name.
SECTIONS = {
    "medicine": ("Medicine", 1),
    "survival": ("Survival", 2),
    "homesteading": ("Homesteading", 3),
    "agriculture": ("Food & Agriculture", 4),
    "energy": ("Energy", 5),
    "diy": ("DIY & Repair", 6),
    "computing": ("Computing & Electronics", 7),
    "education": ("Education", 8),
    "wikipedia": ("Reference", 9),
}


def load_library(path):
    """Return {book_id: {folder, size_bytes}} from library.xml."""
    books = {}
    for book in ET.parse(path).getroot().iter("book"):
        rel = book.get("path", "")
        parts = Path(rel).parts
        folder = parts[-2] if len(parts) >= 2 else "other"
        books[book.get("id")] = {
            "folder": folder,
            "size": int(book.get("size", "0")) * 1024,  # library.xml stores KB
        }
    return books


def load_catalog(server):
    url = server.rstrip("/") + "/catalog/v2/entries?count=-1"
    with urllib.request.urlopen(url, timeout=60) as r:
        root = ET.fromstring(r.read())
    entries = []
    for e in root.iter(ATOM + "entry"):
        content = icon = ""
        for link in e.iter(ATOM + "link"):
            if link.get("type") == "text/html":
                content = link.get("href", "")
            elif link.get("rel", "").endswith("thumbnail"):
                icon = link.get("href", "")
        entries.append({
            "id": e.findtext(ATOM + "id", "").removeprefix("urn:uuid:"),
            "title": e.findtext(ATOM + "title", "").strip(),
            "summary": e.findtext(ATOM + "summary", "").strip(),
            "articles": int(e.findtext(ATOM + "articleCount", "0") or 0),
            "updated": e.findtext(ATOM + "updated", "")[:7],
            "content": content,
            "icon": icon,
        })
    return entries


def human_size(n):
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if n < 1024 or unit == "TB":
            return f"{n:.0f} {unit}" if unit in ("B", "KB") else f"{n:.1f} {unit}"
        n /= 1024


def esc(s):
    return html.escape(s, quote=True)


def book_card(b):
    icon = f'<img src="{esc(b["icon"])}" alt="" width="40" height="40" loading="lazy">' if b["icon"] else '<span class="noicon"></span>'
    return f"""<li class="book">
  <a href="{esc(b['content'])}">{icon}<span class="t">{esc(b['title'])}</span></a>
  <p>{esc(b['summary'])}</p>
  <span class="meta">{b['articles']:,} articles · {human_size(b['size'])} · {esc(b['updated'])}</span>
</li>"""


def render(books):
    groups = {}
    for b in books:
        groups.setdefault(b["folder"], []).append(b)
    order = sorted(groups, key=lambda f: (SECTIONS.get(f, (f, 99))[1], f))

    toc, sections = [], []
    for f in order:
        name = SECTIONS.get(f, (f.title(), 99))[0]
        items = sorted(groups[f], key=lambda b: b["title"].lower())
        total = sum(b["size"] for b in items)
        toc.append(f'<a href="#{esc(f)}">{esc(name)} <span>{len(items)}</span></a>')
        sections.append(
            f'<section id="{esc(f)}"><h2>{esc(name)} <span>{len(items)} book{'s' if len(items) != 1 else ''} · {human_size(total)}</span></h2>'
            f'<ul class="books">{"".join(book_card(b) for b in items)}</ul></section>'
        )

    rows = "".join(
        f'<tr><td><a href="{esc(b["content"])}">{esc(b["title"])}</a></td>'
        f'<td><a href="#{esc(b["folder"])}">{esc(SECTIONS.get(b["folder"], (b["folder"].title(),))[0])}</a></td>'
        f'<td class="n">{b["articles"]:,}</td><td class="n">{human_size(b["size"])}</td><td>{esc(b["updated"])}</td></tr>'
        for b in sorted(books, key=lambda b: b["title"].lower())
    )
    total = human_size(sum(b["size"] for b in books))

    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>NOMAD Library</title>
<style>
:root {{ --bg:#fbfaf7; --fg:#1d1d1b; --muted:#6b6a65; --line:#e4e1d9; --card:#fff; --accent:#2f5d50; }}
@media (prefers-color-scheme: dark) {{ :root {{ --bg:#161614; --fg:#ecebe6; --muted:#9a988f; --line:#2c2b27; --card:#1e1e1b; --accent:#8cc2ad; }} }}
* {{ box-sizing:border-box; }}
body {{ margin:0; background:var(--bg); color:var(--fg); font:15px/1.5 system-ui,-apple-system,sans-serif; }}
main {{ max-width:1100px; margin:0 auto; padding:24px 16px 64px; }}
h1 {{ font-size:28px; margin:0 0 4px; }}
.sub {{ color:var(--muted); margin:0 0 20px; }}
.sub a {{ color:var(--accent); }}
nav {{ display:flex; flex-wrap:wrap; gap:8px; margin-bottom:28px; position:sticky; top:0; background:var(--bg); padding:10px 0; border-bottom:1px solid var(--line); z-index:1; }}
nav a {{ text-decoration:none; color:var(--fg); border:1px solid var(--line); border-radius:999px; padding:4px 12px; background:var(--card); }}
nav a span {{ color:var(--muted); font-size:13px; }}
h2 {{ font-size:20px; margin:32px 0 12px; scroll-margin-top:70px; }}
h2 span {{ color:var(--muted); font-size:14px; font-weight:400; }}
ul.books {{ list-style:none; padding:0; margin:0; display:grid; grid-template-columns:repeat(auto-fill,minmax(300px,1fr)); gap:12px; }}
.book {{ background:var(--card); border:1px solid var(--line); border-radius:8px; padding:12px 14px; }}
.book a {{ display:flex; align-items:center; gap:10px; text-decoration:none; color:var(--accent); font-weight:600; }}
.book img, .noicon {{ width:40px; height:40px; border-radius:6px; flex:none; background:var(--line); }}
.book p {{ margin:8px 0 6px; font-size:14px; }}
.meta {{ color:var(--muted); font-size:12px; }}
table {{ width:100%; border-collapse:collapse; font-size:14px; }}
th, td {{ text-align:left; padding:6px 8px; border-bottom:1px solid var(--line); }}
th {{ color:var(--muted); font-weight:500; }}
td a {{ color:var(--accent); text-decoration:none; }}
.n {{ text-align:right; font-variant-numeric:tabular-nums; }}
.tablewrap {{ overflow-x:auto; }}
</style></head>
<body><main>
<h1>NOMAD Library</h1>
<p class="sub">{len(books)} books · {total} · built {date.today().isoformat()} · <a href="#appendix">A–Z appendix</a> · <a href="/nojs">Kiwix library view</a></p>
<nav>{"".join(toc)}<a href="#appendix">A–Z</a></nav>
{"".join(sections)}
<section id="appendix"><h2>Appendix: all books A–Z <span>{len(books)}</span></h2>
<div class="tablewrap"><table><thead><tr><th>Book</th><th>Section</th><th class="n">Articles</th><th class="n">Size</th><th>Edition</th></tr></thead>
<tbody>{rows}</tbody></table></div></section>
</main></body></html>
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--library", required=True, type=Path)
    ap.add_argument("--server", default="http://localhost:8090")
    ap.add_argument("--out", required=True, type=Path)
    args = ap.parse_args()

    lib = load_library(args.library.expanduser())
    books = []
    for e in load_catalog(args.server):
        meta = lib.get(e["id"], {"folder": "other", "size": 0})
        books.append({**e, **meta})
    args.out.expanduser().write_text(render(books), encoding="utf-8")
    print(f"wrote {args.out} with {len(books)} books")


if __name__ == "__main__":
    main()
