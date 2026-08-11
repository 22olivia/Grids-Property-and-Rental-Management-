# Translation catalogues

## Rules

1. **No hard-coded user-facing strings in components.** Every visible string
   is a key here. `npm run lint:i18n` fails the build if `en.json` and
   `ar.json` diverge, so Arabic cannot silently degrade screen by screen —
   which is exactly how it degrades if nothing enforces it.

2. **Interpolate, never concatenate.** Arabic word order differs from English;
   building a sentence from fragments produces broken grammar in one language
   or both.
   - Correct: `"greeting": "Welcome, {name}"`
   - Wrong: `t('welcome') + ', ' + name`

3. **Use ICU plural forms.** Arabic has **six** plural categories (zero, one,
   two, few, many, other) against English's two. Any `count === 1 ? x : y` in
   a component is a bug that is invisible until an Arabic reviewer sees it.
   ```json
   "unitCount": "{count, plural, =0 {No units} one {# unit} other {# units}}"
   ```

4. **Namespaces mirror features**, so no route loads the whole catalogue.

## Status of the Arabic content

The Arabic strings here cover **foundation UI only** — navigation, states,
errors, the login form. They are placeholders in the sense that they have not
been reviewed by a native speaker.

**No business terminology has been translated, because none has been
authored.** Property, lease and accounting vocabulary is specialist, and for a
financial product machine translation is not adequate. Native review by
someone with domain knowledge is a Definition-of-Done item for every
content-bearing screen (SRS AC-09).
