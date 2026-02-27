---
name: portfolio-quality-guide
description: Guide for analyzing and creating high-quality portfolio scenes and API references for UI components. Use when reviewing, improving, or creating portfolio documentation for ClojureScript/Reagent component libraries displayed via Portfolio (defscene).
---

# How to Create Good Portfolio Documentation

This skill captures the methodology for producing complete, accurate, and consumer-friendly portfolio scenes and API references for UI component libraries.

## Phase 1: Audit — Compare Source of Truth vs Documentation

Before writing anything, **always read the actual component source code** alongside the existing portfolio file. The source is the single source of truth.

### Checklist

1. **List every public component** in the source namespace. Does the API reference document all of them?
2. **List every prop** each component destructures (`:keys`, `:or` defaults, `:as` pass-through). Does the reference document all of them?
3. **Identify phantom entries** — Does the reference document private helpers, internal functions, or nonexistent components? Remove them.
4. **Check prop forwarding** — If the component does `(dissoc props :class)` or `(-> props (assoc ...) (dissoc ...))`, it forwards additional props. Document: *"All additional props are forwarded to the underlying DOM element / X component."*
5. **Check for implicit behavior** — Default CSS classes applied, ARIA attributes set, keyboard handlers, async rendering, error fallbacks. These are invisible to consumers but critical to document.

## Phase 2: Write the API Reference Scene

### Structure

```
defscene api-reference
├── Intro paragraph (what it is, what library it wraps, key capabilities)
├── External doc links (upstream library docs — Radix, Embla, Shiki, etc.)
├── Component cards (one per public component)
│   ├── component-name
│   ├── description (purpose + behavioral notes + accessibility)
│   └── props (every prop with type, required/optional, default, and behavior)
├── Important Notes callout (amber box with gotchas)
└── Usage Example (realistic composition, not an empty shell)
```

### Prop Documentation Format

Each prop entry should follow this pattern:

```
":prop-name" "type, required|optional (default value) - Behavioral description. Constraints or valid values."
```

**Examples of good prop descriptions:**

```
":code"       "string, required - The code string to highlight. If nil or empty, renders an empty code block."
":language"   "string, optional (default \"tsx\") - Language for syntax highlighting. Must match a Shiki language identifier (e.g. \"clojure\", \"javascript\")."
":orientation" "keyword, optional (default :horizontal) - :horizontal | :vertical. Controls the scroll axis. Overrides any :axis value in :opts."
":checked"    "boolean | \"indeterminate\", optional - Controlled checked state. Use true/false for checked/unchecked, or the string \"indeterminate\" for partial selection."
```

**Bad prop descriptions (avoid):**

```
":class" "string, optional - Additional Tailwind classes"  ← only acceptable if truly the only prop
":opts"  "map, optional - Options"                         ← what kind of map? what keys? what format?
```

### Component Description Guidelines

A good description answers three questions:
1. **What does it render?** (e.g., "Renders a Radix UI Checkbox.Root with a Checkbox.Indicator containing a Check icon.")
2. **What implicit behavior does it have?** (e.g., "Sets role=\"region\" and aria-roledescription=\"carousel\" for accessibility.")
3. **How does it relate to siblings?** (e.g., "Applies default spacing via negative margin (-ml-4) that pairs with carousel-item's pl-4.")

### Important Notes Callout

Add an amber-highlighted box for gotchas that will bite consumers:

```clojure
[:div {:class "border rounded-lg p-4 bg-amber-500/10 border-amber-500/30 mb-4"}
 [:h4 {:class "text-sm font-semibold mb-2"} "⚠️ Important Notes"]
 [:ul {:class "text-xs text-muted-foreground space-y-1 list-disc pl-4"}
  [:li "Note 1"]
  [:li "Note 2"]]]
```

**Common gotchas to document:**
- Required props map `{}` even when empty (if component uses `{:keys [...]}` destructuring)
- Key format mismatches (camelCase vs kebab-case for JS interop)
- Props that silently override each other
- Default spacing/styling that consumers need to know to override
- Async behavior (flash of unstyled content)
- Keyboard event capture that may interfere with parent handlers
- Security considerations (dangerouslySetInnerHTML, untrusted input)

### Usage Example

Must show a **realistic composition**, not an empty component:

```clojure
;; BAD
[:code "[code-block {}]"]

;; GOOD
[:code "[code-block {}\n  [code-block-group {:class \"px-4 py-2 border-b\"}\n    [:span \"core.cljs\"]\n    [button {:size :sm :variant :ghost} \"Copy\"]]\n  [code-block-code {:code \"(defn hello [] ...)\"\n                    :language \"clojure\"}]]"]
```

Show multiple patterns if the component supports them (controlled, uncontrolled, disabled, form integration, etc.).

### External Links Section

When the component wraps a third-party library, add links at the top:

```clojure
[:div {:class "flex flex-wrap gap-2"}
 [:a {:href "https://..."
      :target "_blank"
      :rel "noopener noreferrer"
      :class "inline-flex items-center text-sm text-primary hover:underline"}
  "Library Docs →"]]
```

## Phase 3: Identify Missing Demo Scenes

After completing the API reference, check for missing real-world usage patterns:

### Essential Scenes Checklist

For **every** interactive form component, ensure these exist:
- [ ] **Basic demo** — simplest usage with a label
- [ ] **Disabled state** — visual appearance when non-interactive
- [ ] **Invalid/error state** — `:aria-invalid true` with `field-error` messages, plus side-by-side valid/invalid comparison
- [ ] **Field integration** — inside `field` / `field-label` / `field-content` composition
- [ ] **Table integration** — inside a data table for bulk selection (if applicable: checkbox, radio, toggle)

For **layout/display** components:
- [ ] **Basic demo** — default rendering
- [ ] **Variant showcase** — all visual variants
- [ ] **Composition demo** — combined with other components (badges in tables, buttons in cards, etc.)
- [ ] **Edge cases** — empty state, overflow, long content

### Scene Docstring Format

```
"Short description of what scene demonstrates.

  Based on shadcn/ui X — URL (or: Custom example — not from shadcn/ui.)
  Library/Primitive: name

  One-line guidance on when/how to use this pattern."
```

## Phase 4: Cross-Reference Related Components

When a component delegates to another (e.g., carousel buttons use the Button component), the API reference should say:

> *"See Button component for variant visual details."*

Don't re-document another component's props — reference it.

## Anti-Patterns to Avoid

1. **Documenting private/internal functions as components** — Only document what consumers import and use.
2. **Copy-pasting `:class` as the only prop** — If that's truly all the component takes, fine. But audit the source first.
3. **Empty usage examples** — `[component {}]` teaches nothing.
4. **Describing what a component is instead of what it does** — "Checkbox component" vs "Checkbox with built-in check indicator. Renders a Radix Checkbox.Root with integrated Indicator."
5. **Ignoring accessibility** — If the component sets ARIA attributes or handles keyboard events, document it. This builds consumer confidence.
6. **Assuming consumers will read the source** — The API reference should be sufficient. If someone needs to read the source to understand behavior, the reference has failed.
