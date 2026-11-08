# Structured data

Use this file only when writing or auditing markup. Eligibility for a rich result is separate from ordinary ranking. A manual action on structured data removes rich-result eligibility and does not, by itself, remove the page from web results ([general guidelines](https://developers.google.com/search/docs/appearance/structured-data/sd-policies), updated 2026-07-10).

## Rules

- Mark up content readers can see. Hidden or off-page facts do not belong in JSON-LD.
- The markup is a true representation of that visible content. Do not invent a phone number, address, credential, or review.
- `sameAs` is only a URL you opened that identifies the same entity: the organization's own profile, not a short link and not a guessed Wikidata or Wikipedia URL. Wikidata is optional.
- Google accepts several items on one page, nested or as separate blocks. Link related items with `@id`. One `@graph` is allowed. It is not required.
- There is no special schema.org type for AI Overviews or AI Mode ([AI features](https://developers.google.com/search/docs/appearance/ai-features); [AI optimization guide](https://developers.google.com/search/docs/fundamentals/ai-optimization-guide), updated 2026-07-10).

## FAQPage

FAQ rich results stopped appearing in Google Search on 7 May 2026. The 8 May 2026 changelog announced that date. The 15 June 2026 updates log removes the FAQ rich-result documentation because the feature is no longer shown ([search updates](https://developers.google.com/search/updates)).

`FAQPage` markup is not a visibility shortcut. Keep a question only when that question and its answer are visible on the same page. Prefer rendering the answer over keeping an invisible node.

## Reviews

Do not mark testimonials written by the business, or star ratings the business awarded itself, as `Review` or `AggregateRating`. The structured-data guidelines treat ratings that are not from actual users as a cause of manual action.

## Pattern

This is a shape, not a live business. Two blocks, linked by `@id`, are enough.

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "@id": "https://example.com/#organization",
  "name": "Example Advisory",
  "url": "https://example.com/"
}
</script>
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "WebPage",
  "@id": "https://example.com/page/#webpage",
  "url": "https://example.com/page/",
  "name": "Page title that matches the visible H1",
  "isPartOf": { "@id": "https://example.com/#website" },
  "about": { "@id": "https://example.com/#organization" }
}
</script>
```

Add `sameAs`, `address`, or `telephone` only after you have seen each value on the page and, for `sameAs`, opened the URL. A worked pass is in `example-acrenkey.md`.
