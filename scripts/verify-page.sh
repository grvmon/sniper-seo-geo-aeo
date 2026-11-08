#!/usr/bin/env bash
# Fetch one URL and print indexation evidence. Each line is a fact or "nt".
# Exit 0 after a response is saved. Exit 2 on usage or network failure.
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -ne 1 ]]; then
  echo "usage: verify-page.sh URL" >&2
  exit 2
fi

URL="$1"
for bin in curl python3; do
  command -v "$bin" >/dev/null 2>&1 || { echo "missing_dependency: $bin" >&2; exit 2; }
done
case "$URL" in
  http://*|https://*) ;;
  *) echo "usage: URL must start with http:// or https://" >&2; exit 2 ;;
esac
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
UA="verify-page/1.0 (+https://github.com/grvmon/sniper-seo-geo-aeo)"

if ! curl -sS -L --proto =http,https --proto-redir =http,https --max-redirs 5 --max-time 30 -A "$UA" \
  -D "$TMP/headers" -o "$TMP/body" \
  -w '%{url_effective}\n%{http_code}\n%{num_redirects}\n' \
  "$URL" > "$TMP/meta"; then
  echo "fetch_error: curl failed for $URL" >&2
  exit 2
fi

python3 - "$URL" "$TMP" "$UA" << 'PY'
import json, re, sys, html, subprocess, gzip, io
from html.parser import HTMLParser
from urllib.parse import urljoin, urlparse

page_url, tmp, ua = sys.argv[1], sys.argv[2], sys.argv[3]
meta = open(f"{tmp}/meta", encoding="utf-8").read().splitlines()
final_url, status, redirects = meta[0], meta[1], meta[2]
body = open(f"{tmp}/body", encoding="utf-8", errors="replace").read()
raw_headers = open(f"{tmp}/headers", encoding="utf-8", errors="replace").read()

def curl_split(url, binary=False):
    """Return (status, headers_text, body). status is the last hop, or error:reason."""
    import os, tempfile
    hd = tempfile.NamedTemporaryFile(delete=False)
    bd = tempfile.NamedTemporaryFile(delete=False)
    hd.close(); bd.close()
    try:
        p = subprocess.run(
            ["curl", "-sS", "-L", "--proto", "=http,https", "--proto-redir", "=http,https", "--max-redirs", "5", "--max-time", "30", "-A", ua,
             "-D", hd.name, "-o", bd.name, "-w", "%{http_code}", url],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
        )
        headers = open(hd.name, encoding="utf-8", errors="replace").read()
        data = open(bd.name, "rb").read() if binary else open(bd.name, encoding="utf-8", errors="replace").read()
        if p.returncode != 0:
            err = (p.stderr or "curl failed").strip().replace("\n", " ")[:180]
            return f"error: {err}", "", (b"" if binary else "")
        return p.stdout.strip(), headers, data
    finally:
        os.unlink(hd.name); os.unlink(bd.name)

blocks = re.split(r"\r?\n\r?\n", raw_headers)
hops = []  # (status, [header lines])
for block in blocks:
    lines = [ln for ln in block.splitlines() if ln.strip()]
    if not lines or not lines[0].startswith("HTTP/"):
        continue
    parts = lines[0].split(None, 2)
    code = parts[1] if len(parts) > 1 else lines[0]
    reason = parts[2].lower() if len(parts) > 2 else ""
    if code.startswith("1") or (code == "200" and "connection established" in reason):
        continue  # interim or proxy CONNECT response, not a hop
    hops.append((code, lines[1:]))
hop_statuses = [c for c, _ in hops]
final_headers = hops[-1][1] if hops else []
XR_DIRECTIVES = {"all", "noindex", "nofollow", "none", "nosnippet", "indexifembedded",
                 "notranslate", "noimageindex", "unavailable_after", "max-snippet",
                 "max-image-preview", "max-video-preview", "noarchive", "nocache", "index", "follow"}
JUDGED = {"googlebot", "bingbot"}
xrobots, xrobots_other = [], []
for ln in final_headers:
    if not ln.lower().startswith("x-robots-tag:"):
        continue
    val = ln.split(":", 1)[1].strip()
    m = re.match(r"^\s*([A-Za-z0-9_.-]+)\s*:(.*)$", val)
    if m and m.group(1).lower() not in XR_DIRECTIVES:
        agent = m.group(1).lower()
        (xrobots if agent in JUDGED else xrobots_other).append(val)
    else:
        xrobots.append(val)

class Page(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.title = []
        self.in_title = False
        self.skip = 0
        self.canonical = []
        self.robots = []
        self.robots_other = []
        self.meta_desc = []
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
        if tag == "meta":
            name = a.get("name", "").lower()
            if name in ("robots", "googlebot", "bingbot"):
                self.robots.append(f"{name}: {a.get('content', '')}")
            elif name in ("googlebot-news", "slurp", "duckduckbot", "yandex", "baiduspider"):
                self.robots_other.append(f"{name}: {a.get('content', '')}")
            elif name == "description":
                self.meta_desc.append(a.get("content", ""))
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
    q = f"?{p.query}" if p.query else ""
    return f"{p.scheme.lower()}://{p.netloc.lower()}{path}{q}"

def canonical_diff(c, f):
    a, b = urlparse(c), urlparse(f)
    if (a.scheme.lower(), a.netloc.lower()) != (b.scheme.lower(), b.netloc.lower()):
        return "scheme_or_host"
    pa, pb = a.path or "/", b.path or "/"
    if pa != pb:
        return "trailing_slash" if pa.rstrip("/") == pb.rstrip("/") else "path"
    if a.query != b.query:
        return "query"
    return "none"

print(f"requested_url: {page_url}")
print(f"final_url: {final_url}")
print(f"http_status: {status}")
print(f"redirects: {redirects}")
print("hop_status: " + (" ".join(hop_statuses) if hop_statuses else "nt"))
print("http_check: " + ("pass" if status.startswith("2") else "fail"))
print("x_robots_tag: " + (" | ".join(xrobots) if xrobots else "(none)"))
if xrobots_other:
    print("x_robots_other_agent: " + " | ".join(xrobots_other))
print("meta_robots: " + (" | ".join(page.robots) if page.robots else "(none)"))
if page.robots_other:
    print("meta_robots_other_agent: " + " | ".join(page.robots_other))

rules = " ".join(xrobots + page.robots).lower()
status_blocked = status in ("401", "403", "429") or status.startswith("5")
if not status.startswith("2") and not status_blocked:
    rules += " noindex"  # 3xx loop, 404, 410 and other non-2xx are not indexable
if status_blocked:
    indexability = "nt"
    print(f"index_note: status {status} may be bot blocking or an outage for this user agent; confirm with URL Inspection")
elif "noindex" in rules or re.search(r"\bnone\b", rules):
    indexability = "fail"
elif not xrobots and not page.robots:
    indexability = "pass"
    print("index_follow_meta: absent; Google default is index,follow (explicit tag is optional)")
else:
    indexability = "pass"
    if any(re.search(r"\bindex\b", r, re.I) for r in page.robots):
        print("index_follow_meta: present; explicit index,follow is optional")
print(f"indexability: {indexability}")

canon_unique = list(dict.fromkeys(urljoin(final_url, c) for c in page.canonical))
print(f"canonical_count: {len(page.canonical)}")
print(f"canonical_unique_count: {len(canon_unique)}")
for i, c in enumerate(page.canonical, 1):
    abs_c = urljoin(final_url, c)
    print(f"canonical_{i}: {abs_c}")
if len(canon_unique) == 1:
    abs_c = canon_unique[0]
    c_status, _, _ = curl_split(abs_c)
    print(f"canonical_fetch_status: {c_status}")
    print(f"canonical_matches_final: {'yes' if norm(abs_c) == norm(final_url) else 'no'}")
    print(f"canonical_differs: {canonical_diff(abs_c, final_url)}")
elif len(canon_unique) == 0:
    print("canonical_fetch_status: nt")
    print("canonical_matches_final: nt")
    print("canonical_differs: nt")

title_text = re.sub(r"\s+", " ", "".join(page.title)).strip()
print(f"title: {title_text}")
print(f"title_chars: {len(title_text)}")
desc_text = re.sub(r"\s+", " ", page.meta_desc[0]).strip() if page.meta_desc else ""
print(f"meta_description_count: {len(page.meta_desc)}")
print(f"meta_description_chars: {len(desc_text)}")
h1s = [t for lvl, t in page.headings if lvl == 1]
print(f"h1_count: {len(h1s)}")
for t in h1s[:3]:
    print(f"h1: {t}")
print(f"hreflang_count: {page.hreflang}")
print(f"initial_html_text_chars: {len(text)}")
script_tags = len(re.findall(r"(?i)<script\b", body))
print(f"script_tags: {script_tags}")
print(f"js_shell_suspect: {'yes' if len(text) < 500 and script_tags > 0 else 'no'}")
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
robots_mode = "parsed" if robots_status == "200" else ("allow_all" if robots_status.startswith("4") else "nt")
if robots_mode == "allow_all":
    print("robots_txt_note: 4xx means no restrictions (RFC 9309 2.3.1.3)")
if robots_mode == "parsed":
    robots_url = urljoin(origin, "/robots.txt")
    g = None
    for raw_line in robots_body.lstrip("\ufeff").splitlines():
        line = raw_line.split("#", 1)[0].strip()
        if not line or ":" not in line:
            continue  # blank lines do not end a group (RFC 9309)
        key, val = line.split(":", 1)
        key, val = key.strip().lower(), val.strip()
        if key == "user-agent":
            if g is None or g.rules:
                g = Group()
                groups.append(g)
            g.agents.append(val)
        elif key in ("allow", "disallow") and g is not None:
            g.rules.append((key == "allow", val))
        elif key == "sitemap" and val:
            sitemaps.append(urljoin(robots_url, val))

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
    if robots_mode == "nt":
        print(f"robots_agent: {token}\t{kind}\tnt")
        continue
    if robots_mode == "allow_all":
        print(f"robots_agent: {token}\t{kind}\tgroup=none\tallow\trobots.txt {robots_status}")
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
    MAX_FILES, MAX_BYTES = 20, 50 * 1024 * 1024
    queue, seen, locs_n, incomplete, fetched = list(sitemaps), set(), set(), False, 0
    while queue:
        sm = queue.pop(0)
        if sm in seen:
            continue
        if fetched >= MAX_FILES:
            incomplete = True
            print(f"sitemap_note: stopped at {MAX_FILES} files")
            break
        seen.add(sm); fetched += 1
        sm_status, _, raw = curl_split(sm, binary=True)
        if raw[:2] == b"\x1f\x8b":
            try:
                raw = gzip.GzipFile(fileobj=io.BytesIO(raw)).read(MAX_BYTES + 1)
            except OSError:
                raw = b""; sm_status = "error: bad gzip"
            if len(raw) > MAX_BYTES:
                raw = b""; sm_status = "error: gzip over size cap"
        sm_body = raw.decode("utf-8", "replace")
        print(f"sitemap_fetch: {sm} status={sm_status} bytes={len(raw)}")
        if sm_status != "200":
            incomplete = True
            continue
        found = [html.unescape(u.strip()) for u in re.findall(r"(?i)<loc>\s*([^<]+?)\s*</loc>", sm_body)]
        if "<sitemapindex" in sm_body.lower():
            queue.extend(urljoin(sm, u) for u in found if urljoin(sm, u) not in seen)
        else:
            locs_n.update(norm(u) for u in found)
    print(f"sitemap_files_read: {fetched}")
    print(f"sitemap_url_count: {len(locs_n)}")
    if norm(final_url) in locs_n:
        print("in_sitemap: yes")
    else:
        print(f"in_sitemap: {'nt' if incomplete else 'no'}")

print("orphan_check: nt")
llms_status, _, _ = curl_split(urljoin(origin, "/llms.txt"))
print(f"llms_txt_status: {llms_status}")
print("llms_txt: optional")
PY
