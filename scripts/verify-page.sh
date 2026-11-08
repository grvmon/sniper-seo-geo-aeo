#!/usr/bin/env bash
# Fetch one URL and print indexation evidence. Each line is a fact or "nt".
# Exit 0 after a response is saved. Exit 2 on usage or network failure.
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -ne 1 ]]; then
  echo "usage: verify-page.sh URL" >&2
  exit 2
fi

URL="$1"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
UA="verify-page/1.0 (+https://github.com/grvmon/sniper-seo-geo-aeo)"

if ! curl -sS -L --max-redirs 5 --max-time 30 -A "$UA" \
  -D "$TMP/headers" -o "$TMP/body" \
  -w '%{url_effective}\n%{http_code}\n%{num_redirects}\n' \
  "$URL" > "$TMP/meta"; then
  echo "fetch_error: curl failed for $URL" >&2
  exit 2
fi

python3 - "$URL" "$TMP" "$UA" << 'PY'
import json, re, sys, html, subprocess
from html.parser import HTMLParser
from urllib.parse import urljoin, urlparse

page_url, tmp, ua = sys.argv[1], sys.argv[2], sys.argv[3]
meta = open(f"{tmp}/meta", encoding="utf-8").read().splitlines()
final_url, status, redirects = meta[0], meta[1], meta[2]
body = open(f"{tmp}/body", encoding="utf-8", errors="replace").read()
raw_headers = open(f"{tmp}/headers", encoding="utf-8", errors="replace").read()

def curl_split(url):
    """Return (status, headers_text, body). status is the last hop, or error:reason."""
    import os, tempfile
    hd = tempfile.NamedTemporaryFile(delete=False)
    bd = tempfile.NamedTemporaryFile(delete=False)
    hd.close(); bd.close()
    try:
        p = subprocess.run(
            ["curl", "-sS", "-L", "--max-redirs", "5", "--max-time", "30", "-A", ua,
             "-D", hd.name, "-o", bd.name, "-w", "%{http_code}", url],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
        )
        headers = open(hd.name, encoding="utf-8", errors="replace").read()
        data = open(bd.name, encoding="utf-8", errors="replace").read()
        if p.returncode != 0:
            err = (p.stderr or "curl failed").strip().replace("\n", " ")[:180]
            return f"error: {err}", "", ""
        return p.stdout.strip(), headers, data
    finally:
        os.unlink(hd.name); os.unlink(bd.name)

blocks = raw_headers.split("\r\n\r\n")
hop_statuses = []
xrobots = []
for block in blocks:
    lines = [ln for ln in block.splitlines() if ln.strip()]
    if not lines:
        continue
    if lines[0].startswith("HTTP/"):
        parts = lines[0].split()
        hop_statuses.append(parts[1] if len(parts) > 1 else lines[0])
        for ln in lines[1:]:
            if ln.lower().startswith("x-robots-tag:"):
                xrobots.append(ln.split(":", 1)[1].strip())

class Page(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.title = []
        self.in_title = False
        self.skip = 0
        self.canonical = []
        self.robots = []
        self.hreflang = 0
        self.headings = []  # (level, text)
        self.h_level = 0
        self.h_buf = []
        self.after = []  # text chunks collected under current h2 until next heading
        self.capture_after = False
        self.h2_seen = 0
        self.h2_follow = []  # list of text after each of first 8 h2
        self.cur_follow = []
        self.paras = []
        self.in_p = False
        self.p_buf = []
        self.links = set()
        self.ld = []
        self.in_ld = False
        self.ld_buf = []

    def handle_starttag(self, tag, attrs):
        a = {k.lower(): (v or "") for k, v in attrs}
        if tag in ("script", "style"):
            self.skip += 1
            if tag == "script" and a.get("type", "").lower() == "application/ld+json":
                self.in_ld = True
                self.ld_buf = []
            return
        if self.skip:
            return
        if tag == "title":
            self.in_title = True
        if tag == "p":
            self.in_p = True
            self.p_buf = []
        if tag in ("h1", "h2", "h3", "h4"):
            if self.capture_after and self.h2_seen <= 8:
                self.h2_follow.append(re.sub(r"\s+", " ", "".join(self.cur_follow)).strip())
                self.capture_after = False
            self.h_level = int(tag[1])
            self.h_buf = []
        if tag == "link" and "canonical" in a.get("rel", "").lower():
            self.canonical.append(a.get("href", ""))
        if tag == "link" and "alternate" in a.get("rel", "").lower() and a.get("hreflang"):
            self.hreflang += 1
        if tag == "meta" and a.get("name", "").lower() == "robots":
            self.robots.append(a.get("content", ""))
        if tag == "a" and a.get("href"):
            self.links.add(a["href"])

    def handle_endtag(self, tag):
        if tag in ("script", "style"):
            if tag == "script" and self.in_ld:
                self.ld.append("".join(self.ld_buf))
                self.in_ld = False
            if self.skip:
                self.skip -= 1
            return
        if self.skip:
            return
        if tag == "title":
            self.in_title = False
        if tag == "p" and self.in_p:
            text = re.sub(r"\s+", " ", "".join(self.p_buf)).strip()
            if len(text.split()) >= 20:
                self.paras.append(text)
            self.in_p = False
        if tag in ("h1", "h2", "h3", "h4") and self.h_level:
            text = re.sub(r"\s+", " ", "".join(self.h_buf)).strip()
            self.headings.append((self.h_level, text))
            if tag == "h2":
                self.h2_seen += 1
                if self.h2_seen <= 8:
                    self.capture_after = True
                    self.cur_follow = []
            self.h_level = 0

    def handle_data(self, data):
        if self.in_ld:
            self.ld_buf.append(data)
            return
        if self.skip:
            return
        if self.in_title:
            self.title.append(data)
        if self.h_level:
            self.h_buf.append(data)
        if self.in_p:
            self.p_buf.append(data)
        if self.capture_after:
            self.cur_follow.append(data)

    def close(self):
        super().close()
        if self.capture_after:
            self.h2_follow.append(re.sub(r"\s+", " ", "".join(self.cur_follow)).strip())

page = Page()
page.feed(body)
page.close()

def visible_text(raw):
    t = re.sub(r"(?is)<script[\s\S]*?</script>", " ", raw)
    t = re.sub(r"(?is)<style[\s\S]*?</style>", " ", t)
    t = re.sub(r"(?s)<[^>]+>", " ", t)
    t = html.unescape(t)
    return re.sub(r"\s+", " ", t).strip()

text = visible_text(body)
host = urlparse(final_url).netloc.lower()

def same_host(href):
    absu = urljoin(final_url, href)
    p = urlparse(absu)
    if p.scheme not in ("http", "https"):
        return None
    if p.netloc.lower() != host:
        return None
    return absu.split("#")[0]

internal = sorted({u for u in (same_host(h) for h in page.links) if u})

def norm(u):
    p = urlparse(u)
    path = p.path or "/"
    if path != "/" and path.endswith("/"):
        path = path[:-1]
    return f"{p.scheme.lower()}://{p.netloc.lower()}{path}"

print(f"requested_url: {page_url}")
print(f"final_url: {final_url}")
print(f"http_status: {status}")
print(f"redirects: {redirects}")
print("hop_status: " + (" ".join(hop_statuses) if hop_statuses else "nt"))
print("x_robots_tag: " + (" | ".join(xrobots) if xrobots else "(none)"))
print("meta_robots: " + (" | ".join(page.robots) if page.robots else "(none)"))

rules = " ".join(xrobots + page.robots).lower()
if "noindex" in rules or re.search(r"\bnone\b", rules):
    indexability = "fail"
elif not xrobots and not page.robots:
    indexability = "pass"
    print("index_follow_meta: absent; Google default is index,follow (explicit tag is optional)")
else:
    indexability = "pass"
    if any(re.search(r"\bindex\b", r, re.I) for r in page.robots):
        print("index_follow_meta: present; explicit index,follow is optional")
print(f"indexability: {indexability}")

print(f"canonical_count: {len(page.canonical)}")
for i, c in enumerate(page.canonical, 1):
    abs_c = urljoin(final_url, c)
    print(f"canonical_{i}: {abs_c}")
if len(page.canonical) == 1:
    abs_c = urljoin(final_url, page.canonical[0])
    c_status, _, _ = curl_split(abs_c)
    print(f"canonical_fetch_status: {c_status}")
    print(f"canonical_matches_final: {'yes' if norm(abs_c) == norm(final_url) else 'no'}")
elif len(page.canonical) == 0:
    print("canonical_fetch_status: nt")
    print("canonical_matches_final: nt")

print(f"title: {re.sub(r'\s+', ' ', ''.join(page.title)).strip()}")
h1s = [t for lvl, t in page.headings if lvl == 1]
print(f"h1_count: {len(h1s)}")
for t in h1s[:3]:
    print(f"h1: {t}")
print(f"hreflang_count: {page.hreflang}")
print(f"initial_html_text_chars: {len(text)}")
print("browser_render: nt")
print("rendered_html: nt")

print(f"jsonld_blocks: {len(page.ld)}")
for i, raw in enumerate(page.ld, 1):
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        print(f"jsonld_{i}: parse_fail {e}")
        continue
    nodes = data.get("@graph") if isinstance(data, dict) and isinstance(data.get("@graph"), list) else None
    shape = "@graph" if nodes is not None else ("array" if isinstance(data, list) else "single")
    print(f"jsonld_{i}_shape: {shape}")
    items = nodes if nodes is not None else (data if isinstance(data, list) else [data])
    types = []
    for n in items:
        if isinstance(n, dict):
            types.append(str(n.get("@type")))
    print(f"jsonld_{i}_types: {', '.join(types)}")

print(f"internal_outlinks: {len(internal)}")
for u in internal[:30]:
    print(f"internal_link: {u}")
if len(internal) > 30:
    print(f"internal_link_truncated: {len(internal) - 30}")

low = body.lower()
print(f"table_count: {low.count('<table')}")
print(f"ol_count: {low.count('<ol')}")
print(f"ul_count: {low.count('<ul')}")
print(f"heading_count: {len(page.headings)}")
for lvl, t in page.headings[:40]:
    print(f"h{lvl}: {t}")
for i, follow in enumerate(page.h2_follow, 1):
    snippet = follow[:240]
    print(f"h2_follow_{i}: {snippet}")

for i, para in enumerate(page.paras[:8], 1):
    words = para.split()
    print(f"p{i}: {' '.join(words[:40])}")

# robots.txt
origin = f"{urlparse(final_url).scheme}://{urlparse(final_url).netloc}"
robots_status, _, robots_body = curl_split(urljoin(origin, "/robots.txt"))
print(f"robots_txt_status: {robots_status}")

class Group:
    def __init__(self):
        self.agents = []
        self.rules = []  # (allow, pattern)

groups = []
sitemaps = []
if robots_status == "200":
    g = None
    for raw_line in robots_body.splitlines():
        if not raw_line.strip():
            if g and (g.agents or g.rules):
                groups.append(g)
            g = None
            continue
        line = raw_line.split("#", 1)[0].strip()
        if not line or ":" not in line:
            continue
        key, val = line.split(":", 1)
        key, val = key.strip().lower(), val.strip()
        if key == "user-agent":
            if g is None or g.rules:
                if g and (g.agents or g.rules):
                    groups.append(g)
                g = Group()
            g.agents.append(val)
        elif key in ("allow", "disallow") and g is not None:
            g.rules.append((key == "allow", val))
        elif key == "sitemap":
            sitemaps.append(val)
    if g and (g.agents or g.rules):
        groups.append(g)

def path_of(url):
    p = urlparse(url).path or "/"
    return p if p.startswith("/") else "/" + p

def matches(pattern, path):
    if pattern == "":
        return False
    end = pattern.endswith("$")
    pat = pattern[:-1] if end else pattern
    rx = "^" + re.escape(pat).replace(r"\*", ".*")
    if end:
        rx += "$"
    return re.search(rx, path) is not None

def decision(token, path):
    chosen = [g for g in groups if any(a.lower() == token.lower() for a in g.agents)]
    used = token if chosen else "*"
    if not chosen:
        chosen = [g for g in groups if any(a == "*" for a in g.agents)]
    best = None  # (length, allow)
    for g in chosen:
        for allow, pattern in g.rules:
            if pattern == "" and not allow:
                continue
            if pattern == "" and allow:
                continue
            if matches(pattern, path):
                cand = (len(pattern), allow)
                if best is None or cand[0] > best[0] or (cand[0] == best[0] and allow):
                    best = cand
    if best is None:
        return used, "allow", "no matching rule"
    return used, "allow" if best[1] else "disallow", f"longest pattern length {best[0]}"

agents = [
    ("Googlebot", "search"),
    ("Bingbot", "search"),
    ("OAI-SearchBot", "search"),
    ("Claude-SearchBot", "search"),
    ("PerplexityBot", "search"),
    ("Applebot", "search"),
    ("ChatGPT-User", "user"),
    ("Claude-User", "user"),
    ("Perplexity-User", "user"),
    ("GPTBot", "training"),
    ("Google-Extended", "training"),
    ("ClaudeBot", "training"),
    ("Applebot-Extended", "training"),
    ("CCBot", "training"),
    ("OAI-AdsBot", "ads"),
]
path = path_of(final_url)
print(f"robots_path: {path}")
notes = {
    "ChatGPT-User": "OpenAI: robots.txt may not apply to this user-triggered agent",
    "Perplexity-User": "Perplexity: this user-triggered agent generally ignores robots.txt",
    "Google-Extended": "token only; not a separate HTTP user agent; does not control Google Search",
}
for token, kind in agents:
    if robots_status != "200":
        print(f"robots_agent: {token}\t{kind}\tnt")
        continue
    used, result, why = decision(token, path)
    extra = notes.get(token, "")
    print(f"robots_agent: {token}\t{kind}\tgroup={used}\t{result}\t{why}\t{extra}".rstrip())

for s in sitemaps:
    print(f"sitemap_declared: {s}")
if not sitemaps:
    print("sitemap_declared: (none)")
    print("in_sitemap: nt")
else:
    sm_status, _, sm_body = curl_split(sitemaps[0])
    print(f"sitemap_fetch: {sitemaps[0]} status={sm_status} bytes={len(sm_body)}")
    if "<sitemapindex" in sm_body.lower():
        print("in_sitemap: nt")
        print("sitemap_note: sitemap index; child sitemaps were not expanded")
    elif sm_status != "200":
        print("in_sitemap: nt")
    else:
        locs = re.findall(r"(?i)<loc>\s*([^<]+)\s*</loc>", sm_body)
        locs_n = {norm(html.unescape(u.strip())) for u in locs}
        print(f"sitemap_url_count: {len(locs)}")
        print(f"in_sitemap: {'yes' if norm(final_url) in locs_n else 'no'}")

print("orphan_check: nt")
llms_status, _, _ = curl_split(urljoin(origin, "/llms.txt"))
print(f"llms_txt_status: {llms_status}")
print("llms_txt: optional")
PY
