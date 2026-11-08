# Page types

Open this file when the URL is a comparison, a calculator, a local advisory page, or a product page. Length is not a requirement. Match the layout to the job the query asks the page to do.

## Comparison

State which option fits which reader in the first sentences. Put the 3+ dimensions in a table or a list. Name the date the prices or features were checked. Schema follows the visible page (`WebPage`, plus `Product` only when a product and its offer are on the page). `FAQPage` is optional and is not a rich-result tactic after 7 May 2026.

## Calculator

Show the formula, one worked example with units, the jurisdiction, and the date the rates were taken. Put the inputs where a phone user can reach them. Tell the reader it is an estimate and name the professional who must confirm a tax or legal result (`Verify with your CA` or `Verify with your lawyer` when that is the right profession). Use `WebApplication` or `SoftwareApplication` only when the tool itself is visible.

## Local advisory

The visible page carries the name, address, and phone you put in `LocalBusiness`, `RealEstateAgent`, or `ProfessionalService`. Service area text matches `areaServed`. Profiles in `sameAs` must be the same entity. A buyer-side advisory page should say who pays the firm and what the fee is, including any developer or channel-partner compensation. Property, health, and finance pages need the experience, review, evidence, and corrections checks in `SKILL.md`. The acre&key pass is `example-acrenkey.md`.

## Product

`Product` and `Offer` use the price, currency, availability, and condition printed on the page. Shipping and returns match the policy linked from the page. Canonicalize faceted filter URLs that repeat the same product. Merchant Center or a Google Business Profile is a data feed, not a substitute for the on-page facts.
