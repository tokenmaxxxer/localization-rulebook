---
status: draft
issue: issue-1
mode: parallel (4 WebSearch angles, 1 sweep stage, no deepening needed — saturated)
---

# Scout brief: localization QA / L10n methodology survey

## Angles run (parallel, stage 1)

1. MQM (Multidimensional Quality Metrics) error-categorization framework
2. ISO 17100 translation project workflow (TEP + revision + verification)
3. i18n review checklist / pseudo-localization software practice
4. Localization style guide / Linguistic Sign-Off (LSO) deliverable norms

## Must-bes (what strong exemplars all assume)

- Errors/findings are always **categorized by type before severity is
  judged** — MQM's 8 top-level dimensions (Accuracy, Fluency,
  Terminology, Locale convention, Style, Verity, Design,
  Internationalization) exist precisely so two reviewers produce
  comparable verdicts. [Localazy](https://localazy.com/dictionary/multidimensional-quality-metric-mqm)
- A translation/localization output is **never verified by the same
  person/pass that produced it** — ISO 17100 mandates revision by a
  second linguist plus final verification before delivery.
  [ISO 17100 process](https://iso17100.com/translation-process/), [Wikipedia](https://en.wikipedia.org/wiki/ISO_17100)
- Sign-off happens **only after the artifact is in its final integrated
  form** (LSO occurs after DTP/file-engineering/system reintegration,
  not on draft strings). [GTELocalize](https://gtelocalize.net/lso-meaning/)
- i18n-specific defects are checked **mechanically before linguistic
  review**, not left to human read-through: UTF-8/encoding, externalized
  strings, plural-rule coverage, per-locale key completeness, pseudo-
  localization for layout/hardcoding. [SimpleLocalize](https://simplelocalize.io/blog/posts/internationalization-guide-software-localization/), [Aqua Cloud](https://aqua-cloud.io/internationalization-testing/)

## Performance axes strong exemplars compete on

1. **Comparability across reviewers/locales** (MQM's point — a fixed
   category+severity taxonomy, not free-text impressions).
2. **Separation of the technical i18n check from the linguistic
   fitness check** (checklist/pseudo-loc catches structural defects;
   LSO/TEP catches meaning/fluency/culture defects — different
   failure classes, different people/passes).
3. **Traceable basis for pass/fail** (style guide as the standing
   reference a verdict cites, not ad hoc judgment).

## Adopt / skip

- **Adopt**: MQM's dimension taxonomy (trimmed to a project-appropriate
  subset, as MQM itself recommends) as the categorization scheme for
  this role's "string-external issue list"; TEP's "different pass, one
  role, second checkpoint" shape as the phase-1/phase-2 split already
  built into contract v3 (propose ≠ deliver, gated by a separate human
  Approve) rather than restating ISO 17100's staffing model literally
  (this role has no second linguist to delegate revision to).
- **Skip**: full ISO 17100 certification apparatus (client contracts,
  translator credentialing) — out of scope, this is a review/gate role
  over other roles' artifacts, not a translation vendor.
- **Skip**: cloning MQM's 100+ issue-type catalog verbatim — adopt the
  8-dimension top level only, per MQM's own "customized subset"
  guidance, sized to what this role can actually judge (string-external
  i18n fitness, not linguistic fluency it has no mandate to rewrite —
  that's the content-design hand-off already in the directive).

## Segment fit

This role is a **reviewer/gate**, not a translator or LSO-authority — it
judges "does the artifact hold up across locales", closer to the i18n
review-checklist + MQM-categorization segment than to the TEP
translation-production segment.

## Gap line

Field must-bes this rulebook is missing: (1) no fixed
categorization taxonomy for the "string-external issue list" the
directive already promises — MQM fills this; (2) no per-locale verdict
methodology or pass/fail basis — checklist-style mechanical checks +
style-guide-citation fills this; (3) no plugin enforcement that a
proposal/record actually contains these. Field must-bes already met:
the propose→Approve→deliver split already gives this rulebook the
"never verified by the same pass" separation ISO 17100/LSO assume — no
new phase needs to be invented for that part.

## Sources

- https://localazy.com/dictionary/multidimensional-quality-metric-mqm
- https://www.w3.org/community/mqmcg/2018/10/04/draft-2018-10-04/
- https://iso17100.com/translation-process/
- https://en.wikipedia.org/wiki/ISO_17100
- https://aqua-cloud.io/internationalization-testing/
- https://simplelocalize.io/blog/posts/internationalization-guide-software-localization/
- https://gtelocalize.net/lso-meaning/
- https://www.interproinc.com/creating-a-style-guide-for-translation/
