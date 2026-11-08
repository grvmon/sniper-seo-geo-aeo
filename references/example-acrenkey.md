# Worked example: acre&key

[acre&key](https://acrenkey.com/) is a buyer-side property advisory in Bengaluru. This is one pass of the workflow, fetched 2026-11-08 with `scripts/verify-page.sh` and a read of the HTTP body. It is a draft for the owner, not a traffic result. Re-run the script before treating the snapshot as current. Browser render, Search Console, Bing, analytics, and competitor pages were not opened.

## Intake

| Field | Value |
| --- | --- |
| URL | https://acrenkey.com/ |
| Market | India, English, Bengaluru. Residential buyers. |
| Intent | Commercial. Query: "property consultant in Bangalore". The page should explain buyer-side advisory and how to start. |
| Competitors | NT. None were named, so none were invented. |
| Access | Public URL and the HTTP body. Rendered DOM, Search Console, Bing Webmaster, analytics, and logs: NT. |
| Baseline | NT. |
| Training crawlers | `undecided`. The live robots.txt already allows several training tokens. That is a file fact, not an instruction from this skill. |
| Corrections policy | Not in the homepage body. Other URLs were not opened. Sitewide: NT. |

## Technical checks

| Check | Result | Evidence |
| --- | --- | --- |
| Rendered HTML | NT | `browser_render: nt`. The HTTP body has `initial_html_text_chars: 34109`, so the scores below use that text. |
| robots / X-Robots-Tag | pass | `http_status: 200`. `x_robots_tag: (none)`. Meta robots is `index, follow, max-snippet:-1, max-image-preview:large, max-video-preview:-1`. The explicit `index, follow` is optional. No `noindex`. |
| Canonical | pass | `canonical_1: https://acrenkey.com/`, `canonical_fetch_status: 200`, `canonical_matches_final: yes`. |
| Sitemap | pass | `sitemap.xml` status 200, `sitemap_url_count: 159`, `in_sitemap: yes`. |
| Schema matches visible text | fail | One JSON-LD `@graph` parses (`RealEstateAgent`/`Organization`, `WebSite`, `WebPage`, `Service`, `FAQPage`, `OfferCatalog`). The `@graph` shape is fine. FAQ and telephone do not match the visible body. See the ledger. |
| Internal links / orphans | NT | `internal_outlinks: 9`. Orphan check is NT without a site crawl. `https://acrenkey.com/property-consultant-bengaluru/` is in the sitemap and is not one of those nine homepage links. That is a gap to test, not an orphan finding. |

`llms_txt_status: 200`. The file is optional. Google Search ignores it. A "75+" calculator claim in that file was not counted. NT.

Crawlers for `/`, from the script:

| Token | Job | Group | Robots.txt result |
| --- | --- | --- | --- |
| Googlebot, Bingbot | Search | `*` | allow |
| OAI-SearchBot, Claude-SearchBot, PerplexityBot, Applebot | Search | own group | allow |
| ChatGPT-User | User | own group | allow. OpenAI says robots.txt may not apply. |
| Claude-User, Perplexity-User | User | `*` | no group of their own. Perplexity-User generally ignores robots.txt. |
| GPTBot, Google-Extended, ClaudeBot, CCBot | Training | own group | allow. Owner choice still `undecided`. |
| Applebot-Extended | Training | `*` | implicit allow via `*`, not an explicit group. |

## Citability

Sample is the first eight H2s and the first eight paragraphs of at least 20 words.

| Category | Points | Weight | Why |
| --- | --- | --- | --- |
| answer | 6/10 | 30 | 5 hits / 8. `floor(10 × 5 / 8 + 0.5) = 6`. |
| contain | 5/10 | 25 | 4 passes / 8. `floor(10 × 4 / 8 + 0.5) = 5`. |
| structure | 8/10 | 20 | H1 count is 1. No skipped level in the 36-heading outline. Four lenses are separate H3s. `ol_count: 0`, and the advisory steps are prose, so −2. |
| sourced | 3/10 | 15 | 2 sourced / 8 examined. `floor(10 × 2 / 8 + 0.5) = 3`. |
| original | NT | 10 | Competitor URLs were not opened. Not scored as 0. |

```
raw = 6/10×30 + 5/10×25 + 8/10×20 + 3/10×15 = 18 + 12.5 + 16 + 4.5 = 51
coverage = 90
overall = floor(100 × 51 / 90 + 0.5) = floor(57.166) = 57
```

Answer sample (hit means the first sentence states the heading's conclusion):

| H2 | Hit | First words |
| --- | --- | --- |
| The Questions Nobody Is Asking On Your Behalf | yes | "Five questions your broker won't ask, but we do." |
| For Buyers Who Don't Want to Regret the Decision | no | "We've seen what expensive mistakes look like." |
| Why a Great Property Can Still Be the Wrong Purchase | no | "Four lenses that separate a sound purchase from an expensive mistake." |
| Our Advisory Framework | yes | "Find - Inspect - Negotiate - Decide" (the words are run together in the HTML text) |
| Meet Your Bangalore Property Advisors | yes | "Three former corporate leaders and a seasoned investor." |
| Trusted by Leaders. Proven by Outcomes. | no | "How corporate leaders and seasoned investors bought with clarity." |
| Property Consultant in Bangalore | yes | "acre&key is a buyer-first residential property advisory practice..." |
| Frequently Asked Questions About Property Consultants in Bangalore | yes | "32 key questions answered on buyer-side advisory..." |

Contain sample: pass on the advisors intro, the "acre&key is a buyer-first..." paragraph, the Bangalore market paragraph, and the "acre&key provides buyer-first..." paragraph. Fail on the quote that starts "We do more...", "Our assessment considers...", "We begin by understanding...", and "We identify relevant properties...", because those first sentences use we/our and the paragraph does not name acre&key.

Sourced sample: the ₹0 buyer fee (the page states its own price, with the disclosure quoted below) and the Karnataka RERA number in the footer. The other six are on the page without a document, statute, or URL next to them: "69" checks, "40+ years", "32" FAQs, and three testimonials (a 36-month capital claim, a rupee saving, and "40+ listings").

Core Web Vitals: NT. No field p75 was pulled. Official good tier, if measured later: LCP ≤ 2.5s, INP ≤ 200ms, CLS ≤ 0.1 at the 75th percentile. No internal target was set.

## Ledger

| Id | Claim | Evidence | Source | Retrieved | Status |
| --- | --- | --- | --- | --- | --- |
| L1 | Homepage returns 200 with a self-canonical and is in the sitemap | Script lines quoted above | `scripts/verify-page.sh` on https://acrenkey.com/ | 2026-11-08 | verified |
| L2 | Citability overall is 57 with coverage 90 | Arithmetic in the score section | This pass | 2026-11-08 | verified |
| L3 | 3 of 6 `FAQPage` questions, and the first 120 characters of 1 of 6 answers, appear in the visible text | JSON-LD `mainEntity` compared with the body after scripts were removed | Homepage HTTP body | 2026-11-08 | verified |
| L4 | `telephone` is `+91-9071693393` in JSON-LD and those digits are not in the visible text | Organization node vs body text | Homepage HTTP body | 2026-11-08 | verified |
| L5 | `sameAs` includes `https://share.google/GuvhJWg5a66VuIaUT` | Organization node. A `share.google` link is not an identity profile | Homepage HTTP body | 2026-11-08 | verified |
| L6 | LinkedIn, Instagram, YouTube, X, and Facebook `sameAs` URLs were not opened | URLs present in JSON-LD. Nitin Gupta's LinkedIn href is also in the founder card | Homepage HTTP body | 2026-11-08 | nt |
| L7 | Footer shows legal name Acrenkey Realty LLP, the Brigade Metropolis address, and RERA agent number `PRM/KA/RERA/1251/446/AG/260814/007659` | Visible footer | Homepage HTTP body. The K-RERA register was not opened | 2026-11-08 | verified on-page; register nt |
| L8 | The page says it does not charge buyers an advisory fee, and that developer or channel-partner compensation should be disclosed | Two visible sentences, quoted below | Homepage HTTP body | 2026-11-08 | verified |
| L9 | robots.txt allows GPTBot, Google-Extended, ClaudeBot, and CCBot, and `*` allows other agents | Script `robots_agent` lines | https://acrenkey.com/robots.txt | 2026-11-08 | verified |
| L10 | FAQ rich results are not a Google visibility shortcut | Changelog: feature ends 2026-05-07; documentation removed in the 2026-06-15 notes | https://developers.google.com/search/updates | 2026-11-08 | verified |
| L11 | Field Core Web Vitals for this URL | Not pulled | Search Console / CrUX | 2026-11-08 | nt |

## Changes

Drafts, not published copy.

**Micro-markets.** Current opening: "A locality is not evaluated solely by its current popularity." The decision sentence is last: "A popular locality is not automatically the right locality for every buyer."

Draft, using only those sentences and the eight factor names already in the section:

> A popular locality is not automatically the right locality for every buyer. acre&key keeps a Bengaluru micro-market on a shortlist only when connectivity, employment, infrastructure, supply, demand, pricing, livability, and liquidity fit that buyer's brief.

**Fee.** The hero says "₹0 Buyer Advisory Fee". Lower down, the page says: "acre&key does not charge buyers an advisory fee for its home-buying service. Where applicable, any commercial relationship or compensation involving a developer, channel partner or other transaction participant should be disclosed to the buyer."

Draft: use that full pair in the hero. Do not shorten it to "free".

**Schema.** Keep the visible RERA identifier, legal name, and address. Delete the telephone until the number is visible. Delete the `share.google` URL. Open each remaining `sameAs` profile and keep it only if it is that person or Acrenkey Realty LLP. For `FAQPage`, render each answer that is missing from the visible text, or delete that node. One `@graph` can stay; a second block linked with `@id` is also valid. Do not add `Review` markup for the testimonials. Wikidata is optional and was not added.

**Trust.** Add a visible corrections link on this URL. The homepage gives property guidance and is a Your Money or Your Life page. Publish the 69-check list next to the number "69", or remove the number until the list is on the page. Keep outcome testimonials only with a primary record a reader can inspect, or delete the specific figures.

**Crawlers.** Ask the owner to set `allow` or `disallow` for GPTBot, Google-Extended, ClaudeBot, CCBot, and for the implicit `*` allow that covers Applebot-Extended. Leave search tokens allowed if the owner wants the firm findable in those products. `OAI-SearchBot` is the ChatGPT search control. `GPTBot` is not.

**Links.** From the homepage, link the sitemap URLs that should be found by a buyer, including `/property-consultant-bengaluru/`. Re-check orphans only after a crawl.

## Measurement

| Source | Result |
| --- | --- |
| Search Console Web totals and the Generative AI performance report | NT |
| Bing Webmaster | NT |
| Conversion: "Request Advisory Call" submits | NT. Definition is the form on the homepage. No analytics access. |
| AI referral hostnames | NT |
| Citation sample | Not run. Freeze "property consultant in Bangalore" plus the owner's other queries, the engines, locale `en-IN`, and the date. Save each response. One pass is not a score. |

## Still not tested

Browser render versus the HTTP body. K-RERA register lookup. Social profiles. Competitor pages. Field Core Web Vitals. Search Console, Bing, and analytics. Orphans. Whether `/rera-disclaimer/` is a corrections policy. The calculator count in `llms.txt`.
