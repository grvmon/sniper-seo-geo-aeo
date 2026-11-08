# Crawlers, page experience, and engines

Retrieved 2026-11-08. Re-check the linked page before treating a bot rule as current.

## Three jobs

Allow search crawlers when the page should be findable in that product. User-triggered fetchers run because a person asked the product to open a URL. Training crawlers are an owner decision: leave them `undecided` until the owner chooses `allow` or `disallow`. Do not copy an Allow block for training as a default.

| User-agent token | Job | What the publisher's docs say |
| --- | --- | --- |
| Googlebot | Search | robots.txt for Googlebot controls crawling for Google Search, including AI Overviews and AI Mode. `nosnippet`, `data-nosnippet`, `max-snippet`, and `noindex` limit what Search can show. [AI features](https://developers.google.com/search/docs/appearance/ai-features) (updated 2025-12-10). |
| Bingbot | Search | Bing's search crawler. Allow it when the URL should be findable in Bing. |
| OAI-SearchBot | Search | Surfaces sites in ChatGPT search. Opting out means the site is not shown in ChatGPT search answers; it can still appear as a navigational link. Independent of GPTBot. [OpenAI crawlers](https://developers.openai.com/api/docs/bots). |
| Claude-SearchBot | Search | Indexes content for Claude search. Disabling it can reduce visibility in those results. [Anthropic crawlers](https://support.claude.com/en/articles/8896518-does-anthropic-crawl-data-from-the-web-and-how-can-site-owners-block-the-crawler). |
| PerplexityBot | Search | Surfaces and links sites in Perplexity search. Not used to crawl for foundation-model training. [Perplexity crawlers](https://docs.perplexity.ai/docs/resources/perplexity-crawlers). |
| Applebot | Search | Apple's search crawler. Confirm the current token list with Apple before blocking it. |
| ChatGPT-User | User | Fetches a page when a person asks ChatGPT or a Custom GPT. Not an automatic crawl, and not the control for ChatGPT search. robots.txt may not apply. |
| Claude-User | User | Fetches pages for user-initiated Claude requests. Disabling it stops those retrievals. |
| Perplexity-User | User | Fetches a page to answer a user. Not a training crawl. Generally ignores robots.txt. |
| GPTBot | Training | Crawls content that may train OpenAI foundation models. Disallow means do not use the content for that training. Independent of OAI-SearchBot. |
| Google-Extended | Training | robots.txt token only. It is not a separate HTTP user agent. It manages use for Gemini training and for grounding in Gemini Apps and Vertex AI. It does not control inclusion or ranking in Google Search. [Google's common crawlers](https://developers.google.com/crawling/docs/crawlers-fetchers/google-common-crawlers). |
| ClaudeBot | Training | Collects content that may train Anthropic models. A group that names ClaudeBot overrides a general rule for that path. |
| Applebot-Extended | Training | Apple's training token. Confirm the current Apple documentation before setting it. |
| CCBot | Training | Common Crawl's crawler. Treat Allow or Disallow as a training decision, not a search decision. |
| OAI-AdsBot | Ads | Visits pages submitted as ChatGPT ads. OpenAI says this data is not used to train foundation models. |

A `User-agent: *` Allow also lets through any training crawler that has no group of its own. Record that as an implicit choice, not as an explicit one.

```txt
# Search
User-agent: Googlebot
User-agent: Bingbot
User-agent: OAI-SearchBot
User-agent: Claude-SearchBot
User-agent: PerplexityBot
Allow: /

# User-triggered. ChatGPT-User and Perplexity-User may ignore robots.txt.
User-agent: ChatGPT-User
User-agent: Claude-User
Allow: /

# Training. Uncomment one stance after the owner chooses.
# User-agent: GPTBot
# User-agent: Google-Extended
# User-agent: ClaudeBot
# Disallow: /
```

`llms.txt` is optional. Google Search does not use it and it does not change Google rankings ([AI optimization guide](https://developers.google.com/search/docs/fundamentals/ai-optimization-guide), updated 2026-07-10; [updates log](https://developers.google.com/search/updates), 2026-06-15). Keep one only for consumers that ask for it, and only with claims that are visible on the site.

## Core Web Vitals

Official "good" tier, at the 75th percentile of real page loads, mobile and desktop separately ([web.dev/articles/vitals](https://web.dev/articles/vitals), updated 2024-10-31; [Search Central](https://developers.google.com/search/docs/appearance/core-web-vitals)):

- LCP ≤ 2.5 seconds
- INP ≤ 200 milliseconds
- CLS ≤ 0.1

A lab run does not replace the field percentile. If the owner sets a stricter internal target, write the number and the reason in the ledger. This skill does not ship a second set of thresholds. TTFB is a diagnostic for a slow LCP, not a Core Web Vital.

## Engines

Google says optimizing for its generative AI features is SEO. Pages need to be indexed and eligible for a snippet. There is no special schema, no required chunk size, and no preferred word count. Non-commodity content is the part Google tells owners to spend time on: a first-hand point of view, not a rewrite of the current results. Measure Google with Search Console. The Web performance totals include AI Overviews and AI Mode; the Generative AI performance report separates them.

ChatGPT search is controlled with OAI-SearchBot, not with GPTBot and not with a Wikidata item. This skill does not assign ChatGPT a citation-share percentage.

Perplexity search is controlled with PerplexityBot. Perplexity's doc says PerplexityBot is not a training crawler.

Claude search, user fetches, and training are three tokens. Set them separately.

Bing indexation is Bingbot, plus the usual on-page signals. [IndexNow](https://www.indexnow.org/documentation) is an optional URL ping. It is not a ranking score.

Do not claim that the Google top result is the URL other engines cite. Overlap is query-specific. Measure it with the citation sample in `SKILL.md`, or leave it `NT`.
