---
name: domain-application-separation
description: Guide for separating domain (pure business logic) from application layer (framework-specific orchestration) in ClojureScript re-frame applications. Use when refactoring features, reviewing architecture, or adding new pages.
---

# Domain vs Application Layer Separation

## Core Principle

Domain layer contains **pure business logic** that could work in any environment (web, mobile, CLI, tests).
Application layer contains **framework-specific orchestration** that prepares data for specific UI frameworks.

**The Rich Hickey Test**: "Can this function work without knowing about re-frame, React, or any specific UI framework?"
- Yes → Domain
- No → Application

## Domain Layer (src/cljc/mateuszmazurczak/domain/*)

### What Belongs Here

**1. Business Constants** (not UI display data)
```clojure
;; ✅ Domain - business values
(def valid-sizes [100 200 300 400 500])
(def valid-formats #{:zip :pdf})

;; ❌ NOT domain - UI presentation
(def size-options [{:value 100 :label "100px"}])
```

**2. State Transformations** (db → db)
```clojure
;; ✅ Domain - pure state update
(defn update-page-size [page-data size]
  (assoc page-data :size size))
```

**3. Business Calculations**
```clojure
;; ✅ Domain - pure calculation
(defn calculate-derived-state [page-data]
  (let [input-count (parse-input-count (:input page-data))
        can-download? (and (pos? input-count) 
                          (empty? (:errors page-data)))]
    {:input-count input-count
     :can-download? can-download?}))
```

**4. Domain Schemas** (raw data shape)
```clojure
;; ✅ Domain - validates business data structure
(def QrCodesPageData
  [:map
   [:input :string]
   [:size :int]
   [:format [:enum :zip :pdf]]
   [:errors [:vector :string]]])
```

**5. Data Validation & Business Rules**
- What values are valid?
- What state transitions are allowed?
- How to calculate derived business values?

### What Does NOT Belong Here

**❌ Event dispatch markers**
```clojure
;; WRONG - knows about re-frame events
(defn build-handlers []
  {:on-click [:dispatch [:page/action]]})
```

**❌ i18n markers**
```clojure
;; WRONG - presentation concern
(defn build-hint [count]
  [:i18n :hint-text {:count count}])
```

**❌ UI-specific derived state**
```clojure
;; WRONG - "showing?" is UI concern
(defn prepare-for-ui [data]
  (assoc data :showing-preview? (pos? (:preview-count data))))
```

**❌ Framework-specific transformations**
- Anything that calls `fi18n/i18n-markers->translation`
- Anything that calls `events/dispatch-markers->handlers`

## Application Layer (src/cljs/mateuszmazurczak/application/*)

### What Belongs Here

**1. UI Option Builders** (domain values → display format)
```clojure
;; ✅ Application - builds UI dropdown options
(defn- build-size-options []
  (mapv (fn [size]
          {:value size
           :label (str size "px")})
        qr-domain/valid-sizes))
```

**2. Event Handler Builders** (framework wiring)
```clojure
;; ✅ Application - re-frame specific
(defn- build-handlers []
  {:on-update-input [:dispatch [:qr-codes/update-input]]
   :on-download [:dispatch [:qr-codes/download]]})
```

**3. i18n Marker Builders** (text preparation)
```clojure
;; ✅ Application - prepares i18n markers
(defn- build-text-markers [preview-count input-count]
  {:title [:i18n :qr-code-generator]
   :showing-count [:i18n :showing {:1 preview-count :2 input-count}]})
```

**4. UI Data Enrichment** (domain data → UI-ready data)
```clojure
;; ✅ Application - orchestrates domain + UI concerns
(defn- enrich-with-ui-data [page-data]
  (let [derived (qr-domain/calculate-derived-state page-data)]
    (merge page-data
           derived
           {:size-options (build-size-options)
            :handlers (build-handlers)
            :text (build-text-markers (:preview-count derived) 
                                     (:input-count derived))})))
```

**5. Orchestration Pipeline** (coordinate transformations)
```clojure
;; ✅ Application - coordinates domain + framework concerns
(defn prepare-ui-data [raw-data]
  (let [data (or raw-data qr-domain/initial-page-data)
        ui-data (-> data
                    enrich-with-ui-data
                    fi18n/i18n-markers->translation
                    events/dispatch-markers->handlers)]
    {:data ui-data :valid? true}))
```

**6. UI Data Schemas** (after enrichment)
```clojure
;; ✅ Application - validates enriched UI data
(def QrCodesPageUIData
  [:map
   [:input :string]
   [:size :int]
   [:handlers [:map-of :keyword fn?]]
   [:text [:map-of :keyword :string]]])
```

## Pattern: Data Flow

```
Raw DB Data (domain shape)
    ↓
Domain Layer: Calculate derived business state
    ↓
Application Layer: Enrich with UI concerns (options, handlers, text markers)
    ↓
Application Layer: Transform markers (i18n, events)
    ↓
Application Layer: Validate UI data shape
    ↓
UI Component (receives fully prepared data)
```

## Refactoring Checklist

When you see these in domain layer, move them to application:

- [ ] Functions that return `[:dispatch ...]` or `[:i18n ...]`
- [ ] Functions that build UI dropdown/select options
- [ ] Functions named `prepare-ui-data` or `build-handlers`
- [ ] Schemas with `:handlers` or `:text` keys
- [ ] Any function that imports `ports/events` or `frontend-i18n`

## Common Violations & Fixes

### Violation 1: UI Options in Domain

```clojure
;; ❌ BEFORE (domain/pages/foo.cljc)
(def size-options
  [{:value 100 :label "100px"}
   {:value 200 :label "200px"}])

;; ✅ AFTER

;; domain/pages/foo.cljc
(def valid-sizes [100 200 300])

;; application/foo/page_data.cljs
(defn- build-size-options []
  (mapv (fn [size] {:value size :label (str size "px")})
        foo-domain/valid-sizes))
```

### Violation 2: Event Handlers in Domain

```clojure
;; ❌ BEFORE (domain/pages/foo.cljc)
(defn prepare-ui-data [data]
  (assoc data :handlers {:on-click [:dispatch [:foo/click]]}))

;; ✅ AFTER

;; domain/pages/foo.cljc
(defn calculate-derived-state [data]
  {:can-click? (some-business-rule data)})

;; application/foo/page_data.cljs
(defn- build-handlers []
  {:on-click [:dispatch [:foo/click]]})

(defn- enrich-with-ui-data [data]
  (merge data
         (foo-domain/calculate-derived-state data)
         {:handlers (build-handlers)}))
```

### Violation 3: i18n Markers in Domain

```clojure
;; ❌ BEFORE (domain/pages/foo.cljc)
(defn build-hint [count]
  (if (pos? count)
    [:i18n :has-items {:count count}]
    [:i18n :no-items]))

;; ✅ AFTER

;; domain/pages/foo.cljc
;; (remove this function - it's presentation logic)

;; application/foo/page_data.cljs
(defn- build-hint [count]
  (if (pos? count)
    [:i18n :has-items {:count count}]
    [:i18n :no-items]))

(defn- build-text-markers [derived-state]
  {:hint (build-hint (:count derived-state))
   :title [:i18n :page-title]})
```

## Architecture Decision: When to Add Domain Function

Ask these questions:

1. **Could this work in a CLI tool?** → Domain
2. **Could this work in a mobile app?** → Domain  
3. **Does it depend on React/re-frame?** → Application
4. **Is it about data transformation vs presentation?** → Domain vs Application

## Complete Example: Proper Separation

```clojure
;; ═══════════════════════════════════════════════════════════════
;; domain/pages/qr_codes.cljc
;; ═══════════════════════════════════════════════════════════════

(def valid-sizes [100 200 300 400 500])
(def valid-formats #{:zip :pdf})

(defn calculate-derived-state [page-data]
  (let [input-count (parse-input-count (:input page-data))
        can-download? (and (pos? input-count) 
                          (empty? (:errors page-data)))]
    {:input-count input-count
     :can-download? can-download?}))

(def QrCodesPageData
  [:map
   [:input :string]
   [:size :int]
   [:format [:enum :zip :pdf]]])

;; ═══════════════════════════════════════════════════════════════
;; application/qr_codes/page_data.cljs
;; ═══════════════════════════════════════════════════════════════

(defn- build-size-options []
  (mapv (fn [size] {:value size :label (str size "px")})
        qr-domain/valid-sizes))

(defn- build-handlers []
  {:on-update-input [:dispatch [:qr-codes/update-input]]
   :on-download [:dispatch [:qr-codes/download]]})

(defn- build-text-markers [input-count]
  {:title [:i18n :qr-code-generator]
   :hint (if (pos? input-count)
           [:i18n :will-generate {:count input-count}]
           [:i18n :enter-values])})

(defn- enrich-with-ui-data [page-data]
  (let [derived (qr-domain/calculate-derived-state page-data)]
    (merge page-data
           derived
           {:size-options (build-size-options)
            :handlers (build-handlers)
            :text (build-text-markers (:input-count derived))})))

(defn prepare-ui-data [raw-data]
  (-> (or raw-data qr-domain/initial-page-data)
      enrich-with-ui-data
      fi18n/i18n-markers->translation
      events/dispatch-markers->handlers))

(def QrCodesPageUIData
  [:map
   [:input :string]
   [:size :int]
   [:input-count :int]
   [:can-download? :boolean]
   [:size-options [:vector :any]]
   [:handlers [:map-of :keyword fn?]]
   [:text [:map-of :keyword :string]]])
```

## Benefits of Proper Separation

1. **Testability**: Domain functions testable without UI framework
2. **Reusability**: Domain logic works in CLJ backend, CLJS frontend, CLI tools
3. **Clarity**: Clear boundary between "what" (domain) and "how to show" (application)
4. **Maintainability**: Business changes → domain, UI changes → application
5. **Performance**: Domain functions can be optimized/memoized independently

## Common Anti-Patterns from Real Refactoring

### Anti-Pattern 1: The "Orchestration" File in Domain

**Symptom**: A file named `domain/*/orchestration.cljc` that coordinates multiple operations.

**Why It's Wrong**: Orchestration is inherently about coordinating framework-specific concerns. If the file contains functions like:
- `reset-form` (forms are web UI concepts)
- `resolve-modal-*` (modals are UI widgets)
- `update-form-field` (form management is web-specific)
- `build-external-form-data` (form state is UI state)

These are ALL application-layer concerns, not domain logic.

**The Fix**: Move entire orchestration file to `application/*/use_cases.cljs` and inline the logic there.

```clojure
;; ❌ WRONG: domain/aoc/orchestration.cljc
(defn reset-form [year challenge]
  {:author-name ""
   :github-username ""
   :content-type :code-snippet
   :year year
   :challenge challenge})

(defn resolve-modal-open [{:keys [playground-url form-year page-year]}]
  (let [year (if playground-url form-year page-year)]
    {:year year
     :challenges-options (selection/build-challenges-options year)}))

;; ✅ CORRECT: application/aoc/use_cases.cljs
(defn- reset-form [year challenge]
  {:author-name ""
   :github-username ""
   :content-type :code-snippet
   :year year
   :challenge challenge})

(defn handle-modal-open
  "Handle modal opening (public API for event handlers)."
  [context]
  (let [year (if (:playground-url context) 
               (:form-year context) 
               (:page-year context))]
    {:state-updates {:modal-open? true
                     :form-year year
                     :challenges-options (selection/build-challenges-options year)}}))
```

**Key Insight**: The word "orchestration" itself is a hint—it's about coordinating different concerns, which is what application layer does.

### Anti-Pattern 2: UI Concept Names in Domain

**Symptom**: Function names contain `form`, `modal`, `page`, `panel`, or other UI widget names.

**Why It's Wrong**: These concepts don't exist in pure business logic:
- CLI tools don't have "forms" or "modals"
- Backend services don't have "pages"
- A business rule validator doesn't care about "panels"

**Red Flag Function Names**:
- `reset-form` ❌
- `update-page-input` ❌
- `resolve-modal-*` ❌
- `generate-page-preview` ❌
- `update-form-field` ❌
- `build-panel-data` ❌

**The CLI Test**: If you were building a CLI version of your app, would this function exist with the same name?
- "Reset form" in CLI → "Set defaults" (different concept)
- "Update page input" in CLI → "Process input" (no "page")
- "Open modal" in CLI → N/A (doesn't exist)

**The Fix**: Move to application layer OR rename to reflect the actual business operation.

```clojure
;; ❌ WRONG: domain/qr_codes/preview.cljc
(defn update-page-input [page-data input]
  (assoc page-data :input input :preview-codes [] :errors []))

(defn update-page-size [page-data size]
  (let [updated (assoc page-data :size size)]
    (if (seq (:input updated))
      (let [{:keys [codes errors]} (generate-preview-codes ...)]
        (assoc updated :preview-codes codes :errors errors))
      updated)))

;; ✅ CORRECT: Split responsibilities

;; domain/qr_codes/preview.cljc (keep only pure generation)
(defn generate-preview-codes [input size show-label?]
  (let [contents (parse-input input)
        result (generate-batch contents :size size :show-label? show-label?)]
    (if (:success result)
      {:codes (:codes result) :total (count contents) :errors []}
      {:codes [] :total 0 :errors (:errors result)})))

;; application/qr_codes/page_data.cljs (page state management)
(defn update-page-input [page-data input]
  (assoc page-data :input input :preview-codes [] :errors []))

(defn update-page-size [page-data size]
  (let [updated (assoc page-data :size size)]
    (if (seq (:input updated))
      (let [{:keys [codes errors]} (qr-preview/generate-preview-codes 
                                     (:input updated) 
                                     size 
                                     (:show-label? updated))]
        (assoc updated :preview-codes codes :errors errors))
      updated)))
```

### Anti-Pattern 3: Hardcoded UI Enrichment in Domain Functions

**Symptom**: Domain normalization/denormalization functions hardcode calls to UI enrichment functions.

**Why It's Wrong**: Creates tight coupling between domain data operations and presentation concerns. Can't reuse the domain function without dragging UI dependencies along.

**Example from Real Code**:

```clojure
;; ❌ WRONG: domain/aoc/solution.cljc
(defn denormalize-solutions [solution-ids entities]
  (into []
        (comp (map #(get entities %))
              (filter some?)
              (map enrich-solution-with-github-data)
              (map enrich-solution-with-vote-handlers))  ;; UI concern!
        solution-ids))

;; Problem: Can't denormalize without adding re-frame handlers
;; Can't use this function in backend or CLI

;; ✅ CORRECT: Keep domain pure, enrich in application layer

;; domain/aoc/solution.cljc
(defn denormalize-solutions [solution-ids entities]
  (into []
        (comp (map #(get entities %))
              (filter some?)
              (map enrich-solution-with-github-data))  ;; pure domain enrichment only
        solution-ids))

;; application/aoc/solution.cljs
(defn enrich-solution-with-vote-handlers [solution]
  (let [solution-id (:id solution)]
    (assoc solution
           :on-vote-best-practices [:dispatch [:aoc/vote solution-id :best-practices]]
           :on-vote-clever [:dispatch [:aoc/vote solution-id :clever]])))

(defn denormalize-and-enrich-solutions [solution-ids entities]
  (mapv enrich-solution-with-vote-handlers 
        (solution/denormalize-solutions solution-ids entities)))

;; application/aoc/page_data.cljs
(defn prepare-ui-data [raw-data solutions-entities ...]
  (let [solution-ids (get-in raw-data [...])
        solutions (app-solution/denormalize-and-enrich-solutions 
                   solution-ids 
                   solutions-entities)
        sorted-solutions (solution/sort-solutions-by-votes solutions)]
    ...))
```

**Key Insight**: Domain functions should compose cleanly. If you can't use a domain function without framework dependencies, it's misplaced.

### Anti-Pattern 4: "Calculate Derived State" That Calculates UI Flags

**Symptom**: A domain function named `calculate-derived-state` that returns UI-specific flags like `showing-preview?`, `can-download?`, `more-codes-count`.

**Why It's Subtle**: These FEEL like business rules, but they're actually view-model concerns. The business domain doesn't care about "showing" anything.

**How to Distinguish**:
- **Business state**: `total-count`, `error-count`, `valid?` (exists independent of UI)
- **UI state**: `showing-preview?`, `can-download?`, `has-more?` (only matters for display)

**The Fix**: Keep true business calculations in domain, move view flags to application.

```clojure
;; ❌ WRONG: domain/qr_codes/preview.cljc
(defn calculate-derived-state [page-data]
  (let [input-count (parse-input-count (:input page-data))
        preview-count (count (:preview-codes page-data))]
    {:input-count input-count
     :preview-count preview-count
     :has-input? (pos? input-count)           ;; UI flag
     :can-download? (and (pos? input-count) 
                        (empty? (:errors page-data)))  ;; UI flag
     :showing-preview? (pos? preview-count)   ;; UI flag
     :more-codes-count (- input-count preview-count)}))  ;; UI-specific calculation

;; ✅ CORRECT: Split business vs UI concerns

;; domain/qr_codes/preview.cljc
(defn parse-input-count [input]
  (count (parse-input input)))

;; Domain only provides raw data, no UI judgments
;; Business rule: You can generate QR codes if input is valid
(defn can-generate? [input errors]
  (and (pos? (parse-input-count input))
       (empty? errors)))

;; application/qr_codes/page_data.cljs
(defn- calculate-derived-state [page-data]
  (let [input-count (qr-preview/parse-input-count (:input page-data))
        preview-count (count (:preview-codes page-data))
        has-input? (pos? input-count)
        can-download? (qr-preview/can-generate? (:input page-data) 
                                                (:errors page-data))
        showing-preview? (pos? preview-count)
        more-codes-count (- input-count preview-count)]
    {:input-count input-count
     :preview-count preview-count
     :has-input? has-input?
     :can-download? can-download?
     :showing-preview? showing-preview?
     :more-codes-count more-codes-count}))
```

**Rule of Thumb**: If the calculation only matters for deciding what to render, it's application layer.

## Red Flags in Code Review

If you see these in a domain namespace, flag for refactoring:

- `require` of `ports.events`, `frontend-i18n`, or any re-frame adapter
- Function names like `build-handlers`, `prepare-ui-data`, `build-options`
- **Function names with `form`, `modal`, `page`, `panel` (UI concepts)**
- **Files named `orchestration.cljc` in domain layer**
- **Hardcoded UI enrichment in normalization/denormalization pipelines**
- Return values with `:handlers`, `:text`, `[:dispatch ...]`, `[:i18n ...]`
- Comments saying "for UI" or "presentation layer"
- Schema keys like `:handlers`, `:text` (these are application concerns)
- **Derived state calculations with flags like `showing-?`, `has-more?`, `can-download?`**

## Summary Table

| Concern | Domain | Application |
|---------|--------|-------------|
| Business rules | ✅ | ❌ |
| Pure calculations | ✅ | ❌ |
| State transformations | ✅ | ❌ |
| Valid values/formats | ✅ | ❌ |
| UI dropdown options | ❌ | ✅ |
| Event handlers | ❌ | ✅ |
| i18n markers | ❌ | ✅ |
| Orchestration pipeline | ❌ | ✅ |
| Framework transformations | ❌ | ✅ |
| UI data enrichment | ❌ | ✅ |
| Raw data schema | ✅ | ❌ |
| UI data schema | ❌ | ✅ |
