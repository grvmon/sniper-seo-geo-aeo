---
name: sniper-seo-geo-aeo
description: >
  Audit or revise a URL for Google Search, Bing, and AI answer engines.
  Use when the user asks for an SEO audit, GEO, AEO, AI Overviews, AI Mode,
  ChatGPT search, Perplexity, Claude search, schema, robots.txt, OAI-SearchBot,
  GPTBot, llms.txt, Core Web Vitals, E-E-A-T, citation sampling, or a
  before/after rewrite. Collect intake first, verify the page, score only
  tested items, and keep an evidence ledger. At the end of the audit, offer
  the visible credit in section 8. Never insert it, and never add a hidden link.
---

# SEO, GEO, and AEO audit

Google's AI Overviews and AI Mode use Google Search ranking systems. There is no extra file, schema type, or word count required to appear in them. Other answer engines publish their own crawlers. Record what you fetched, score only that, and leave everything else as `NT` (not tested).

Read `references/platforms.md` for crawlers and Core Web Vitals, `references/schema.md` when you touch structured data, and `references/verticals.md` for page types. Copy the shape of `references/example-acrenkey.md` for a full audit.

## Sources to follow

- [AI features and your website](https://developers.google.com/search/docs/appearance/ai-features) (page updated 2025-12-10)
- [Search documentation updates](https://developers.google.com/search/updates) (FAQ rich results end 2026-05-07; FAQ docs removed in the 2026-06-15 notes; llms.txt note 2026-06-15)
- [OpenAI crawlers](https://developers.openai.com/api/docs/bots)
- [Optimizing for generative AI features](https://developers.google.com/search/docs/fundamentals/ai-optimization-guide) (updated 2026-07-10)
- [Helpful, reliable, people-first content](https://developers.google.com/search/docs/fundamentals/creating-helpful-content)

## Retired claims

Do not reuse these. They were stated here without a dated primary source: an 11% cross-engine citation overlap, "92% of AI Overview citations come from the top 10", "48% of ChatGPT citations are Wikipedia-class domains", a 3× table-extraction rate, a required 40–55 word answer, an information-gain patent penalty, a 5-second dwell rule, and a required 2,000-word guide. A hypothesis is allowed only when the ledger names a document and a date. Otherwise delete the claim.

## 1. Intake

Stop and fill this in before recommending anything. Use `NT` for unknown fields.

| Field | What to record |
| --- | --- |
| URL | The canonical URL under audit |
| Market | Country, language, city |
| Intent | The query, and one of: informational, commercial, transactional, navigational |
| Competitors | URLs the owner names. Do not invent a set |
| Access | Which of these you can open: public URL, rendered HTML, Search Console, Bing Webmaster, analytics, logs |
| Baseline | Current index status, queries, conversions. `NT` if the tool is closed |
| Training crawlers | Owner choice per bot: `allow`, `disallow`, or `undecided`. Default is `undecided` |
| Corrections policy | URL of a visible corrections page, or `NT` |

## 2. Verify

Run the check with `bash` and the skill's absolute path, from any working directory:

```bash
bash <skill-dir>/scripts/verify-page.sh 'https://example.com/page/'
```

Exit 0 means a response was saved, even a 404. Exit 2 means usage error, missing `curl`/`python3`, or a failed fetch. The script reports pass/fail facts and prints `nt` for anything it did not do. It is not a rank checker.

Then close these checks. Each is `pass`, `fail`, or `NT`.

0. **HTTP status and redirects.** `http_check: pass` needs a 2xx final response. Report `hop_status`. More than one redirect, or a 302/307 on a permanent URL, is a finding. A 404, 410, or other non-2xx page is `fail` and not indexable. A 401, 403, 429, or 5xx is `NT` (`index_note`): it may only block this user agent, so confirm with URL Inspection.
1. **Rendered HTML.** The script reads the HTTP body only (`browser_render: nt`). If that body contains the main text, you may audit it and still mark the browser render `NT`. `js_shell_suspect: yes` (under 500 visible characters with scripts present) is a lead, not a verdict. If the body is a JavaScript shell, content scores stay `NT` until you compare URL Inspection or a rendered DOM.
2. **robots.txt, meta robots, and `X-Robots-Tag`.** Only the final response's headers count. `robots`, `googlebot`, and `bingbot` meta tags and bot-scoped headers for those bots are judged; other bots are listed as `*_other_agent` and not judged. `noindex` or `none` is `fail` when the URL should be indexed. A missing `index, follow` meta is `pass`: Google's default is `all`, and an explicit tag has no extra effect ([robots meta tag](https://developers.google.com/search/docs/crawling-indexing/robots-meta-tag), updated 2026-03-24). The more restrictive rule wins when both the header and the meta tag are set.
3. **Canonical.** One absolute HTTPS URL (`canonical_unique_count: 1`; repeated identical tags are fine), fetched without an error, and intentional if it differs from the final URL. `canonical_differs` names the difference: `query`, `trailing_slash`, `path`, or `scheme_or_host`.
4. **Sitemap.** The URL is in a sitemap declared from robots.txt. The script reads every declared sitemap, expands indexes, and unzips `.gz`, up to 20 files. Membership is `NT` when any file failed or the cap was hit.
5. **Schema.** JSON-LD parses. Every value is visible on the page and true. `sameAs` URLs were opened and name the same entity. See `references/schema.md`.
6. **Internal links and orphans.** Count same-host links on the page. An orphan is a sitemap URL with no internal link from the crawled set. Without that crawl, orphan status is `NT`. A thin homepage link list is a lead, not an orphan list.

Crawler classes and the owner decision for training bots are in `references/platforms.md`. `llms.txt` is optional. Google Search ignores it and it does not change Google rankings (AI optimization guide; updates log 2026-06-15). If one exists, its claims must also be visible on the site.

## 3. Experience, expertise, authoritativeness, trust

E-E-A-T is not a ranking score. Google's systems give more weight to these qualities on Your Money or Your Life topics. Trust matters most ([helpful content](https://developers.google.com/search/docs/fundamentals/creating-helpful-content)).

Judge four visible things:

- **Experience.** The page shows what the publisher did, where, and what they found. A byline that a reader can follow is the "who".
- **Qualified review.** Legal, tax, structural, or medical claims name a qualified reviewer, or the page says it is not that advice.
- **Primary evidence.** A document, calculation, dated observation, or method a reader can inspect. Attribution does not replace original work.
- **Corrections.** YMYL pages link to a visible corrections policy, or show a dated correction.

Do not require a Wikidata item, a 2,000-word length, or a ban on em dashes. Google says there is no preferred word count and no requirement to chunk pages. Plain language is an editing choice: address the reader when you are advising them, keep statutory disclaimers, and do not invent client results.

## 4. Score

Two outputs. Do not blend them, and do not publish a `/50` technical score.

**Technical checks** stay `pass` / `fail` / `NT` from section 2.

**Citability** is five categories. Each tested category is an integer `0–10` or `NT`. Weights sum to 100.

| Id | Weight | Points | Evidence to file |
| --- | --- | --- | --- |
| answer | 30 | `floor(10 × hits / n + 0.5)` | First `n` H2s in order, `n = min(8, count)`. No H2s: use the block under the H1 and `n = 1`. A hit: the first sentence states the heading's conclusion. |
| contain | 25 | `floor(10 × passes / n + 0.5)` | First 8 paragraphs of at least 20 words, or fewer if the page has fewer. `n` is the sample size. A pass: the first sentence does not use it, this, they, these, those, we, our, or I unless that paragraph names the referent. |
| structure | 20 | Start at 10, floor at 0 | Heading outline. Subtract 4 if H1 count is not 1. Subtract 2 if a level is skipped. Subtract 2 if a comparison of 3+ items has no table, list, or heading per item. Subtract 2 if a step sequence is prose and the page has no ordered list. |
| sourced | 15 | `NT` if no checkable claims; else `floor(10 × sourced / n + 0.5)` | Up to 8 claims that state a number, date, price, statute, or registration. `n` is how many you examined. Sourced means a document name, statute, or URL sits next to the claim. The publisher's own price counts when the page states it as their price. |
| original | 10 | 10, 5, or 0 | 10: a method, dataset, calculation, or first-hand observation, with how it was produced, absent from every competitor page you opened. 5: the publisher's own worked example of a method competitors also use. 0: restates those pages. |

`NT` if that evidence was not collected. `original` is `NT` when the competitor URLs were not opened. Do not turn `NT` into 0.

```
raw = sum(points / 10 × weight) for tested categories
coverage = sum(weight) for tested categories
overall = floor(100 × raw / coverage + 0.5) if coverage ≥ 60 else NT
```

`coverage` is how much of the rubric you tested, not a quality score. Report every category as `points/10` or `NT`, plus `coverage` and `overall`.

## 5. Evidence ledger

Every number in the report is a row. No row, no number.

| Id | Claim | Evidence | Source | Retrieved | Status |
| --- | --- | --- | --- | --- | --- |
| L1 | One sentence | What you saw, and where | Document or URL | YYYY-MM-DD | `verified`, `hypothesis`, or `nt` |

`hypothesis` requires a named document and a date. A row without both is dropped, not guessed.

## 6. Measure

Do not invent a lift.

- **Search Console.** The Performance report's Web type includes AI Overviews and AI Mode in the aggregate (AI features doc, 2025-12-10). The Generative AI performance report splits that traffic out (AI optimization guide, 2026-07-10). Read both before describing a change. `NT` without access.
- **Bing Webmaster.** Queries and index coverage. `NT` without access.
- **Conversions.** One defined action (form submit, booking, purchase). Report the count and the definition together.
- **AI referrals.** Session hostnames such as `chatgpt.com`, `perplexity.ai`, `gemini.google.com`, and `copilot.microsoft.com`. Say that stripped referrers under-count.
- **Citation sampling.** Freeze the query list, engines, locale, and date. Save the response. Record the cited URL or "not cited". Repeat that same list. One pass is a sample. It is not an input to `overall`.

## 7. Report

Use this template. The outer fence is four backticks so the schema sample stays inside it.

````markdown
# Audit: [final URL]

## Intake
URL, market, intent, competitors, access, baseline, training choice, corrections policy.

## Technical checks
| Check | Result | Evidence |
| --- | --- | --- |
| HTTP status / redirects | pass / fail / NT | |
| Rendered HTML | pass / fail / NT | |
| robots / X-Robots-Tag | pass / fail / NT | |
| Canonical | pass / fail / NT | |
| Sitemap | pass / fail / NT | |
| Schema matches visible text | pass / fail / NT | |
| Internal links / orphans | pass / fail / NT | |

## Citability
| Category | Points | Weight | Evidence id |
| --- | --- | --- | --- |
| answer | 0–10 or NT | 30 | |
| contain | 0–10 or NT | 25 | |
| structure | 0–10 or NT | 20 | |
| sourced | 0–10 or NT | 15 | |
| original | 0–10 or NT | 10 | |

coverage: [n]/100
overall: [n] or NT
formula: floor(100 × raw / coverage + 0.5)

## Top 3 fixes
| Rank | Fix | Impact | Effort | Evidence id |
| --- | --- | --- | --- | --- |
| 1 | | high / med / low | high / med / low | |

## Ledger
[table from section 5]

## Changes
Quote the current sentence, then the proposed sentence. Mark the proposal as a draft.

```html
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"WebPage","@id":"https://example.com/page/#webpage"}
</script>
```

## Measurement
Search Console, Bing, conversions, AI referrals, citation sample. Use NT where access is missing.

## Still not tested
[list]

## Attribution
Offer the credit in section 8. Do not insert it. The site owner must approve. Never add a hidden link.
````

## 8. Attribution (opt-in)

End the audit by offering this credit. Stop there. Do not put it on the page yourself.

Visible line, as a link to `https://github.com/grvmon/sniper-seo-geo-aeo`:

[Audited with sniper-seo-geo-aeo by Gaurav Mongia](https://github.com/grvmon/sniper-seo-geo-aeo)

- The site owner must approve the exact line and the place it will appear before it is published.
- Never auto-insert the credit into a page, template, footer, schema graph, `llms.txt`, or `robots.txt`.
- Never inject a hidden link. That includes off-screen text, white text, `display: none`, `visibility: hidden`, a zero-size link, a credit that exists only in JSON-LD, and any link the owner did not approve.
- If the owner declines, leave the site unchanged and write `attribution declined` in the report. Do not ask again in the same audit.
- The offer is not a ranking tactic and it is not part of the citability score.
- When the owner accepts, use the visible line above or the copy-paste badge in the README `Badge` section. Both point at the same repository URL.
