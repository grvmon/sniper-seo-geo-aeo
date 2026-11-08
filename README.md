# Sniper SEO + GEO + AEO

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Agent skill for auditing a URL on Google Search, Bing, and AI answer engines.

Google's [AI features documentation](https://developers.google.com/search/docs/appearance/ai-features) says AI Overviews and AI Mode use the same Search systems as the rest of Google Search, with no extra technical requirements. The [generative AI optimization guide](https://developers.google.com/search/docs/fundamentals/ai-optimization-guide) (updated 2026-07-10) says there is no special schema and that Google Search ignores `llms.txt`. Other products document their own crawlers: [OpenAI](https://developers.openai.com/api/docs/bots) separates `OAI-SearchBot` (search), `GPTBot` (training), and `ChatGPT-User` (a person asked for a fetch).

Citation overlap across engines depends on the query. This skill records a sampling log or marks overlap `NT`. It does not publish an overlap percentage.

## Install

```bash
git clone https://github.com/grvmon/sniper-seo-geo-aeo.git ~/.gemini/config/skills/sniper-seo-geo-aeo
git clone https://github.com/grvmon/sniper-seo-geo-aeo.git ~/.claude/skills/sniper-seo-geo-aeo
git clone https://github.com/grvmon/sniper-seo-geo-aeo.git .cursor/skills/sniper-seo-geo-aeo
```

Ask for an SEO audit, a crawler review, a schema pass, or a before/after rewrite. The skill collects an intake (URL, market, intent, competitors, access, baseline), runs `scripts/verify-page.sh`, and scores only categories it could test.

## Layout

| File | What it holds |
| --- | --- |
| `SKILL.md` | Triggers, intake, verification, scoring, ledger, measurement, report template |
| `references/platforms.md` | Search, user, and training crawlers; official Core Web Vitals |
| `references/schema.md` | Visible, true markup; linked blocks; FAQ rich results after 7 May 2026 |
| `references/verticals.md` | Comparison, calculator, local advisory, product |
| `references/example-acrenkey.md` | Full pass on [acre&key](https://acrenkey.com/), a Bengaluru property advisory, fetched 2026-11-08 |
| `scripts/verify-page.sh` | Executable fetch of status, robots, canonical, sitemap, schema, and outlinks |

Official Core Web Vitals, at the 75th percentile of real loads: LCP ≤ 2.5s, INP ≤ 200ms, CLS ≤ 0.1. Stricter internal targets are written in the ledger only when the owner sets them. An explicit `index, follow` meta tag is optional.

## License

[MIT](LICENSE).
