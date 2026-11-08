# House rules: acre&key (site-specific)

These are acre&key's own editorial and template choices. They are **not** generic SEO, GEO, or AEO rules and are not Google requirements. Apply them only when auditing or editing acrenkey.com or answers.acrenkey.com, and only with the owner's approval.

## Answer pages

- The standalone answer sits in `<p id="direct-answer">` under the title or byline and leads with a styled eyebrow `<strong>In Short</strong>`, not a plain `Direct answer:` label.
- House CSS for the eyebrow:

```css
#direct-answer strong:first-child {
  color: var(--text-copper-aaa);
  text-transform: uppercase;
  font-size: 0.75rem;
  letter-spacing: 0.08em;
  display: block;
  margin-bottom: 4px;
}
```

- `acceptedAnswer.text` in JSON-LD omits the `In Short` eyebrow and any label.
- Each informational answer page links to one relevant calculator by its full canonical URL, `https://acrenkey.com/calculators/<tool-slug>/`, for example inside `<ul class="related-ak">` or just before the References heading. Pick a calculator that fits the question; do not add an unrelated one to hit coverage.

## Navigation and titles

- Header order: Decision Framework, Methodology, Calculators, Blogs, Team. Clientele is not in the navigation.
- `<title>` ends with ` | acre&key`, lowercase, with the ampersand encoded as `&amp;` in HTML source.

## Wording

- Describe the service with checkable terms such as "evidence-based due diligence", not "unbiased".

## Statutory references (Real Estate (Regulation and Development) Act, 2016)

Checked against the Act text on 2026-11-09. Quote the section, do not paraphrase it into something stronger.

- **Section 13(1):** a promoter shall not accept more than ten per cent of the cost of the apartment, plot, or building as an advance or application fee without first entering into a written agreement for sale and registering it.
- **Section 17(1):** the promoter shall execute a registered conveyance deed in favour of the allottee, along with the undivided proportionate title in the common areas to the association of allottees or the competent authority, and hand over possession, within the period in local law. If there is no local law, the conveyance deed is to be executed within three months from the occupancy certificate. Note: the Act's "undivided proportionate title in the common areas" goes to the association or competent authority; do not describe it as the allottee's UDS unless the deed says so.
- Legal points need a qualified reviewer or a "not legal advice" line (see SKILL.md section 3).

## Organization schema

- acre&key publishes the Karnataka RERA agent registration `PRM/KA/RERA/1251/446/AG/260814/007659` on acrenkey.com (seen 2026-11-09). Put it in Organization schema only where the same number is visible on the page, and confirm it on the Karnataka RERA portal (rera.karnataka.gov.in) before each audit. This skill has not verified it on the portal.
