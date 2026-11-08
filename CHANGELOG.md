# Changelog

All notable changes to this skill are documented here. The package version follows [Semantic Versioning](https://semver.org/).

## Unreleased

- Answer blocks: standalone answer under the title, no plain-text label prefixes; clean `acceptedAnswer.text`. Script reports `first_p_label_prefix`, `schema_answer_texts`, and `schema_answer_label_prefix`.
- E-E-A-T: prefer verifiable self-description over vague superlatives.
- New `references/house-rules-acrenkey.md`: acre&key house style only, not generic rules.

- verify-page.sh runs on Python 3.9+ (no backslash in f-string expressions).
- robots.txt parsing follows RFC 9309: blank lines do not end a group, matching groups merge, BOM stripped, 4xx means allow all, sitemap URLs resolved.
- Only the final hop's `X-Robots-Tag` counts; `googlebot`/`bingbot` meta and scoped headers are judged; other bots reported only.
- New `http_check`, `canonical_differs`, `title_chars`, and `meta_description_*` lines; non-2xx pages are not indexable.
- Reads all declared sitemaps, expands indexes with loop protection, unzips `.gz`, up to 20 files; `nt` when incomplete.
- curl is limited to http/https; exits 2 when curl or python3 is missing.
- 401/403/429/5xx give `indexability: nt` with an `index_note` instead of `fail`.
- Identical repeated canonical tags count as one (`canonical_unique_count`).
- New `script_tags` and `js_shell_suspect` lines (under 500 visible characters with scripts).
- Added `tests/run.sh` fixture suite.
- Docs: `WebSite` node in the schema example, Gemini CLI path `~/.gemini/skills/`, `bash <skill-dir>/scripts/verify-page.sh`, HTTP status check, `sourced` is `NT` with no claims, Top 3 fixes in the report.

- README release, license, and topics badges use shields.io URLs that return an SVG.
- Wiki guides: Home, Installation, Usage, Supported Engines, FAQ, and Contributing.

## 1.0.0 - 2026-11-08

- First packaged release of the Sniper SEO, GEO, and AEO agent skill.
- Publish `@grvmon/sniper-seo-geo-aeo` to GitHub Packages when a GitHub Release is published, and on manual workflow dispatch.
- Repository docs: install, usage, supported engines, contributing, security, and code of conduct.
- Opt-in attribution. The audit offers a visible credit line and does not insert it. Hidden links are forbidden. The site owner must approve.
