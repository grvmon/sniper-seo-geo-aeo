"""Local fixture server for verify-page.sh tests. Usage: fixture_server.py MODE PORTFILE"""
import gzip
import http.server
import sys

MODE, PORTFILE = sys.argv[1], sys.argv[2]
PAGE = '<html><head><title>Fixture</title>%s</head><body><h1>H</h1><p>x</p></body></html>'


class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def send(self, code, body, ct="text/html", hdr=()):
        b = body if isinstance(body, bytes) else body.encode()
        self.send_response(code)
        for k, v in hdr:
            self.send_header(k, v)
        self.send_header("Content-Type", ct)
        self.send_header("Content-Length", str(len(b)))
        self.end_headers()
        self.wfile.write(b)

    def urlset(self, *paths):
        u = "http://%s" % self.headers["Host"]
        return "<urlset>" + "".join("<url><loc>%s%s</loc></url>" % (u, p) for p in paths) + "</urlset>"

    def do_GET(self):
        p, m = self.path, MODE
        if p == "/robots.txt":
            body = {
                "blankline": "User-agent: GPTBot\n\nDisallow: /\n",
                "multiua": "User-agent: GPTBot\nUser-agent: CCBot\n\n\nDisallow: /\n",
                "tie": "User-agent: *\nDisallow: /page\nAllow: /page\n",
                "bom": "\ufeffUser-agent: *\nDisallow: /\n",
                "twosm": "User-agent: *\nAllow: /\nSitemap: /a.xml\nSitemap: /b.xml\n",
                "gz": "User-agent: *\nAllow: /\nSitemap: /s.xml.gz\n",
                "index": "User-agent: *\nAllow: /\nSitemap: /idx.xml\n",
                "loop": "User-agent: *\nAllow: /\nSitemap: /loop1.xml\n",
            }.get(m)
            if m == "norobots" or body is None and m not in ("x",):
                return self.send(404, "nf", "text/plain")
            return self.send(200, body or "User-agent: *\nAllow: /\n", "text/plain")
        if p == "/a.xml":
            return self.send(200, self.urlset("/other"), "application/xml")
        if p == "/b.xml":
            return self.send(200, self.urlset("/page"), "application/xml")
        if p == "/s.xml.gz":
            return self.send(200, gzip.compress(self.urlset("/page").encode()), "application/gzip")
        if p == "/idx.xml":
            return self.send(200, "<sitemapindex><sitemap><loc>/b.xml</loc></sitemap></sitemapindex>", "application/xml")
        if p in ("/loop1.xml", "/loop2.xml"):
            nxt = "/loop2.xml" if p == "/loop1.xml" else "/loop1.xml"
            return self.send(200, "<sitemapindex><sitemap><loc>%s</loc></sitemap></sitemapindex>" % nxt, "application/xml")
        if p == "/hop":
            return self.send(301, "", hdr=[("Location", "/page"), ("X-Robots-Tag", "noindex")])
        if p == "/gb":
            return self.send(200, PAGE % '<meta name="googlebot" content="noindex">')
        if p == "/xrt-other":
            return self.send(200, PAGE % "", hdr=[("X-Robots-Tag", "otherbot: noindex")])
        if p == "/xrt-google":
            return self.send(200, PAGE % "", hdr=[("X-Robots-Tag", "googlebot: noindex")])
        if p == "/403":
            return self.send(403, PAGE % "")
        if p == "/dupcanon":
            return self.send(200, PAGE % '<link rel="canonical" href="/dupcanon"><link rel="canonical" href="/dupcanon">')
        if p == "/shell":
            return self.send(200, '<html><head><title>App</title></head><body><div id="root"></div><script src="/app.js"></script></body></html>')
        if p == "/404":
            return self.send(404, PAGE % "")
        if p.startswith("/canq"):
            return self.send(200, PAGE % '<link rel="canonical" href="/canq?a=1">')
        return self.send(200, PAGE % "")


srv = http.server.HTTPServer(("127.0.0.1", 0), H)
open(PORTFILE, "w").write(str(srv.server_address[1]))
srv.serve_forever()
