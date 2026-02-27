---
name: i18n-dict-text
description: Guidelines for naming and structuring i18n dictionary text keys in domain/i18n/dict/text.cljc - focus on user value over technical implementation
---

# i18n Dictionary Text Naming Guidelines

## Core Principle: Value Over Implementation

i18n dictionary keys should describe **what the user experiences**, not **what the code does technically**.

❌ **Bad**: Technical, implementation-focused
- `:download-progress-finalizing` — describes code state
- `:download-progress-pdf` — describes technical process
- `:worker-processing` — exposes internal architecture

✅ **Good**: User-facing, value-focused
- `:preparing-download` — describes what user sees
- `:creating-pdf-document` — clear user action
- `:generating-qr-codes` — describes valuable outcome

## Naming Rules

### 1. Use Action-Oriented Language
Describe actions from the user's perspective:
- `:generating-qr-codes` (not `:qr-generation-progress`)
- `:creating-pdf-document` (not `:pdf-creation-in-progress`)
- `:packaging-files` (not `:zip-archive-creation`)

### 2. Avoid Technical Jargon
Don't expose implementation details:
- ❌ `:worker-ready`, `:batch-processing`, `:finalizing`
- ✅ `:preparing-download`, `:processing-request`, `:almost-ready`

### 3. Be Specific and Clear
Generic keys make translation and maintenance harder:
- ❌ `:progress`, `:status`, `:processing`
- ✅ `:upload-progress`, `:connection-status`, `:validating-data`

### 4. Group Related Keys
Use consistent prefixes for related functionality:
```clojure
;; QR Code generation
:generating-qr-codes "Generating %1 of %2 qr codes..."
:creating-pdf-document "Generating PDF document..."
:packaging-files "Creating ZIP archive..."
:preparing-download "Finalizing..."

;; Form validation
:error-no-qr-values "Please enter at least one QR code value"
:error-pdf-cols-invalid "Columns must be a positive integer"
:error-pdf-rows-invalid "Rows must be a positive integer"
```

## File Structure

Dictionary lives in: `src/cljc/mateuszmazurczak/domain/i18n/dict/text.cljc`

```clojure
(def dict
  {:en {:key-name "English text"
        :key-with-params "Text with %1 and %2 params"}
   :pl {:key-name "Polski tekst"
        :key-with-params "Tekst z %1 i %2 parametrami"}})
```

## Usage Flow

1. **Define** in `domain/i18n/dict/text.cljc`
2. **Reference** in `application/*/page_data.cljs` as i18n markers:
   ```clojure
   {:text {:title [:i18n :qr-code-generator]
           :generating [:i18n :generating-qr-codes {:1 current :2 total}]}}
   ```
3. **Use** in events `adapters/events/reframe/*`:
   ```clojure
   (case format
     :pdf :creating-pdf-document
     :zip :packaging-files
     :preparing-download)
   ```
4. **Display** in UI `ui/*` (automatically translated by page-data layer)

## Special Cases

### Progress Messages
Show what's happening, not technical state:
- `:generating-qr-codes "Generating %1 of %2 qr codes..."`
- `:uploading-files "Uploading %1 of %2 files..."`
- `:saving-changes "Saving your changes..."`

### Error Messages
Describe the problem and solution:
- `:error-no-qr-values "Please enter at least one QR code value"`
- `:error-invalid-url "Please enter a valid URL (must start with http:// or https://)"`

### Status Indicators
Use present continuous for active states:
- `:loading-solutions "Loading solutions..."`
- `:submitting "Submitting..."`
- `:preparing-download "Preparing download..."`

## Review Checklist

When adding or reviewing i18n keys, ask:

1. ✅ Does the key name describe **user value** not **code behavior**?
2. ✅ Would a non-technical user understand the key name?
3. ✅ Is it grouped logically with related keys?
4. ✅ Does it avoid exposing architecture (workers, batches, adapters)?
5. ✅ Is the text clear and actionable?

## Translation Tips

- Keep parameter placeholders `%1`, `%2` consistent across languages
- Polish has complex plural forms — use functions for dynamic plurals:
  ```clojure
  :qr-codes-will-be-generated 
  (fn [[n]] (str n " " (plural-form n)))
  ```
- Test both languages to ensure natural phrasing

## Common Patterns

### Buttons/Actions
```clojure
:download "Download"
:generate-preview "Generate Preview"
:submit-solution "Submit Solution"
:show-more "Show more"
```

### Labels/Headers
```clojure
:qr-code-generator "QR Code Generator"
:output-format "Output Format"
:pdf-layout "PDF Layout"
```

### Descriptions
```clojure
:show-label-description "Display QR code value below each code"
:format-pdf-description "Choose a layout preset or custom grid in centimeters"
```

### Notifications
```clojure
:solution-submitted-successfully "Solution submitted successfully!"
:failed-to-submit-solution "Failed to submit solution"
:upload-limit-reached "Upload limit reached"
```
