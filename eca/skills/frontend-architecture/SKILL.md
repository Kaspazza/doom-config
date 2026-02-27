---
name: frontend-architecture
description: Clojure/ClojureScript frontend architecture patterns for re-frame applications. Use when working on UI components, pages, or frontend features.
---

# Frontend Architecture Skill (Re-frame + Hexagonal)

## Architecture Overview

The frontend follows a strict layered architecture:

1. **Domain** (domain/pages/*.cljc): Pure data transformations, i18n markers, dispatch markers
2. **Application** (application/*/page_data.cljs): Orchestrates marker transformations  
3. **Router** (application/router.cljs): Loads page data automatically via `state/watch`
4. **Pages multimethod** (application/pages.cljs): Receives data and passes to UI
5. **UI** (ui/pages/*.cljs): Pure presentation components

**Key insight:** UI components are pure functions that receive all data as props. They DO NOT use subscriptions/watches directly. Data flows through router → pages multimethod → UI components.

## Critical Rules (Must Follow)

### 1. **UI Layer - Pure Presentation Only**

**NEVER in UI components:**
- ❌ Hardcoded text strings (use i18n from data)
- ❌ Direct event dispatches (`events/dispatch!`)
- ❌ Subscriptions/watches (`@(state/watch ...)`) - data comes via props
- ❌ Data transformations (format conversions, mapping, filtering, sorting)
- ❌ Business logic (disabled conditions, validation)
- ❌ Helper functions that do logic
- ❌ Comments explaining architecture ("pure presentation layer", "Sub-components")

**ALWAYS in UI components:**
- ✅ Receive ALL data from props (passed by pages multimethod)
- ✅ Call handlers from data: `(:on-click handlers)`
- ✅ Use translated text from data: `(:title text)`
- ✅ Render what you're given, no decisions
- ✅ Pass data down to child components

**Example (CORRECT):**
```clojure
(defn my-component [{:keys [text handlers items disabled?]}]
  [:div
   [:h1 (:title text)]
   [:button {:disabled disabled?
             :on-click (:on-save handlers)}
    (:save-button text)]
   (for [item items]
     ^{:key (:id item)} [item-card item])])
```

**Example (WRONG):**
```clojure
(defn my-component [{:keys [items]}]
  (let [page-data @(state/watch [:pages/my-page])]  ; ❌ NO watches in UI!
    [:div
     [:h1 "My Title"]  ; ❌ Hardcoded text
     [:button {:disabled (empty? items)  ; ❌ Business logic in UI
               :on-click #(events/dispatch! [:save])}  ; ❌ Direct dispatch
      "Save"]
     (for [item (sort-by :name items)]  ; ❌ Data transformation
       ^{:key (:id item)} [item-card item])]))
```

### 2. **Domain Layer - Data Transformations & Logic**

**Domain provides:**
- ✅ Pure data transformation functions
- ✅ Dispatch markers: `[:dispatch [:event/name]]` or `[:dispatch [:event/name arg]]`
- ✅ i18n markers: `[:i18n :key]` or `[:i18n :key {:param value}]`
- ✅ Computed boolean flags: `{:disabled? (not (valid? data))}`
- ✅ All business logic

**Dispatch markers pattern:**
```clojure
;; Single action
{:on-click [:dispatch [:my-page/save]]}

;; Action that takes arguments from UI
{:on-update-field [:dispatch [:my-page/update-field]]}
;; UI calls: ((:on-update-field handlers) :name "value")
;; Becomes: (events/dispatch! [:my-page/update-field :name "value"])

;; Navigation with params
{:on-click [:dispatch [:nav/navigate :route/name {:id 123}]]}
```

**Example (domain/pages/my_page.cljc):**
```clojure
(defn prepare-ui-data [raw-data]
  (let [items (parse-items (:input raw-data))
        valid? (validate-items items)]
    {:items (sort-items items)  ; ← Transform HERE, not in UI
     :disabled? (not valid?)    ; ← Logic HERE, not in UI
     :handlers {:on-save [:dispatch [:my-page/save]]
                :on-cancel [:dispatch [:my-page/cancel]]
                :on-update-field [:dispatch [:my-page/update-field]]}
     :text {:title [:i18n :my-page-title]
            :save-button [:i18n :save]
            :cancel-button [:i18n :cancel]}}))
```

### 3. **Application Layer - Marker Transformation**

**Application layer orchestrates transformations:**
- ✅ Calls domain `prepare-ui-data`
- ✅ Transforms i18n markers: `fi18n/i18n-markers->translation`
- ✅ Transforms dispatch markers: `events/dispatch-markers->handlers`
- ✅ Validates result

**Pattern (application/*/page_data.cljs):**
```clojure
(ns mateuszmazurczak.application.my-page.page-data
  (:require
   [mateuszmazurczak.domain.pages.my-page :as domain]
   [mateuszmazurczak.frontend-i18n        :as fi18n]
   [mateuszmazurczak.ports.events         :as events]))

(defn prepare-ui-data [raw-data]
  (let [processed-data (-> raw-data
                           fi18n/i18n-markers->translation
                           events/dispatch-markers->handlers)
        valid? (domain/valid-page-data? processed-data)]
    (if valid?
      {:data processed-data
       :valid? true}
      {:data processed-data
       :valid? false
       :error {:id ::translation-failed
               :data (domain/explain-page-data processed-data)}})))
```

**What `events/dispatch-markers->handlers` does:**
```clojure
;; Input:
{:on-click [:dispatch [:nav/navigate :route]]}

;; Output:
{:on-click (fn [& args] (events/dispatch! (into [:nav/navigate :route] args)))}

;; UI can call with args: ((:on-click handlers) extra-param)
;; Becomes: (events/dispatch! [:nav/navigate :route extra-param])
```

### 4. **Router & State - Automatic Data Loading**

**How data flows to UI:**

1. **Router** (application/router.cljs) watches current route
2. Fetches page data via `@(state/watch [page-id])`
3. Passes to **pages multimethod** (application/pages.cljs)
4. Pages multimethod passes data to UI components

**UI components never use `state/watch` directly!**

```clojure
;; router-component does the watching:
(defn router-component []
  (let [current-route @(state/watch [:nav/current-route])
        page-id (:page-id current-route)
        page-data (when (and page-id 
                            (contains? (set (keys state/watch-reg)) page-id))
                    @(state/watch [page-id]))]  ; ← Router watches
    [mm-nav-pages/pages current-route page-data]))

;; pages multimethod receives data:
(defmethod pages :pages/my-page
  [_ page-data]
  (let [{:keys [valid? data]} page-data]
    [structure/page-wrapper
     (if valid?
       [my-page-ui data]  ; ← Passes to UI as props
       [error-ui])]))

;; UI just receives data:
(defn my-page-ui [data]  ; ← Pure function, data as prop
  (let [{:keys [text handlers items]} data]
    [:div ...]))
```

### 5. **State Registration**

**Register page subscription in adapter:**
```clojure
;; adapters/state/reframe/my_page.cljs
(rf/reg-sub :pages/my-page
  :<- [:my-page/raw-data]
  (fn [raw-data _]
    (page-data/prepare-ui-data raw-data)))  ; ← Calls application layer

;; Export for registration
(def watch "My page subscriptions" #{:my-page/raw-data :pages/my-page})
```

**Router automatically creates watch** based on `state/watch-reg`.

### 6. **i18n - Always Use, Never Hardcode**

**Every displayed text must:**
1. Be defined in `domain/i18n/dict/text.cljc` (both `:en` and `:pl`)
2. Passed as i18n marker from domain: `[:i18n :key]` or `[:i18n :key {:param value}]`
3. Translated in application layer via `fi18n/i18n-markers->translation`
4. Used in UI from data

**Example flow:**
```clojure
;; 1. Dictionary (domain/i18n/dict/text.cljc)
(def dict
  {:en {:save-count "Save {count} item{plural}"}
   :pl {:save-count "Zapisz {count} element{plural}"}})

;; 2. Domain (domain/pages/my_page.cljc)
(defn prepare-ui-data [data]
  {:text {:save-button [:i18n :save-count {:count 5 :plural "s"}]}})

;; 3. Application layer translates (application/my_page/page_data.cljs)
(fi18n/i18n-markers->translation processed-data)

;; 4. UI uses (ui/pages/my_page.cljs)
[:button (:save-button text)]
```

### 7. **Feature Change Checklist**

When adding/modifying frontend features:

1. **Domain (domain/pages/<page>.cljc)**:
   - Add pure transformation functions FIRST
   - Update `prepare-ui-data` with:
     - Computed flags (`:disabled?`, `:loading?`, etc.)
     - Dispatch markers (`:handlers` map with `[:dispatch ...]`)
     - i18n markers (`:text` map with `[:i18n ...]`)
   - Update initial-data if needed

2. **Dictionary (domain/i18n/dict/text.cljc)**:
   - Add translation keys for `:en` AND `:pl`

3. **Event Registry (domain/events/registry.cljc)**:
   - Add event definition (if new handler)

4. **Event Handlers (adapters/events/reframe/pages/<page>.cljs)**:
   - Implement handler: orchestrate by calling domain functions
   - NO helper functions here - move to domain

5. **Application Layer (application/<page>/page_data.cljs)**:
   - Usually no changes needed (just passes through transformations)
   - Add only if special transformation logic required

6. **State Subscription (adapters/state/reframe/<page>.cljs)**:
   - Add new subscription if needed
   - Update `watch` set to export subscription

7. **Pages Multimethod (application/pages.cljs)**:
   - Update if page structure changes
   - Usually just passes `data` to UI

8. **UI (ui/pages/<page>.cljs)**:
   - Update component to use new data/handlers from props
   - Pure presentation only

### 8. **Common Mistakes to Avoid**

❌ **Using watches in UI:**
```clojure
;; WRONG - UI component using watch
(defn my-component []
  (let [data @(state/watch [:pages/my-page])]  ; ❌ NO!
    [:div ...]))

;; RIGHT - data comes as prop
(defn my-component [data]  ; ✅ Prop from pages multimethod
  [:div ...])
```

❌ **Manual handler wiring in subscriptions:**
```clojure
;; WRONG - manually wrapping each handler
(rf/reg-sub :pages/my-page
  (fn [data _]
    (update data :handlers
            (fn [handlers]
              (into {}
                    (map (fn [[k v]]
                           [k (fn [& args] 
                                (events/dispatch! (into v args)))])
                         handlers))))))  ; ❌ Use events/dispatch-markers->handlers!

;; RIGHT - use helper function in application layer
;; Application layer (application/my_page/page_data.cljs):
(defn prepare-ui-data [raw-data]
  (-> raw-data
      fi18n/i18n-markers->translation
      events/dispatch-markers->handlers))  ; ✅ Transforms all markers
```

❌ **Name shadowing:**
```clojure
;; WRONG - :conversation-selector in data shadows component name
{:keys [conversation-selector]}  ; data key
[conversation-selector ...]  ; ← calls DATA map, not function!

;; RIGHT - suffix data keys with -data, -config, etc.
{:keys [conversation-selector-data]}
[conversation-selector conversation-selector-data]
```

❌ **Helper functions in event namespaces:**
```clojure
;; WRONG - logic in adapters/events
(defn format-data [x] ...)  ; ← Move to domain!

;; RIGHT - call domain functions
(rf/reg-event-db :my/event
  (fn [db _]
    (assoc db :data (domain/format-data ...))))
```

❌ **Inline transformations in application layer:**
```clojure
;; WRONG
(defn prepare-ui-data [raw-data]
  (-> raw-data
      (update :items #(sort-by :name %))  ; ← Move to domain!
      fi18n/i18n-markers->translation
      events/dispatch-markers->handlers))

;; RIGHT - domain does transformations
(defn prepare-ui-data [raw-data]
  (-> (domain/prepare-ui-data raw-data)  ; ← Domain sorts
      fi18n/i18n-markers->translation
      events/dispatch-markers->handlers))
```

## Quick Reference

### Data Flow Diagram

```
Event → Handler → Update app-db
                       ↓
                  Raw page data
                       ↓
    Domain: prepare-ui-data (add markers, flags, transform)
                       ↓
    Application: translate markers (i18n + dispatch)
                       ↓
    Subscription: expose to router
                       ↓
    Router: @(state/watch [page-id])
                       ↓
    Pages multimethod: receive data
                       ↓
    UI: render (pure, no watches)
```

### Handler Pattern

```clojure
;; Domain provides:
{:on-save [:dispatch [:my-page/save]]
 :on-update [:dispatch [:my-page/update]]
 :on-navigate [:dispatch [:nav/navigate :route {:id 1}]]}

;; Application transforms (automatically):
{:on-save (fn [] (events/dispatch! [:my-page/save]))
 :on-update (fn [field val] (events/dispatch! [:my-page/update field val]))
 :on-navigate (fn [] (events/dispatch! [:nav/navigate :route {:id 1}]))}

;; UI calls:
((:on-save handlers))
((:on-update handlers) :name "value")
((:on-navigate handlers))
```

### What Goes Where

**Domain (domain/pages/<page>.cljc):**
- [ ] Data transformation functions (sort, filter, map, parse)
- [ ] Computed flags (`:disabled?`, `:can-submit?`)
- [ ] Dispatch markers (`:handlers` with `[:dispatch ...]`)
- [ ] i18n markers (`:text` with `[:i18n ...]`)
- [ ] Validation, business rules

**Application (application/<page>/page_data.cljs):**
- [ ] Call domain `prepare-ui-data`
- [ ] Transform i18n markers
- [ ] Transform dispatch markers
- [ ] Validate result
- [ ] NO inline logic

**Subscription (adapters/state/reframe/<page>.cljs):**
- [ ] Call application layer `prepare-ui-data`
- [ ] Export in `watch` set
- [ ] NO inline logic

**Pages Multimethod (application/pages.cljs):**
- [ ] Receive data from router
- [ ] Handle validation errors
- [ ] Pass data to UI component
- [ ] Wrap in page structure

**UI (ui/pages/<page>.cljs):**
- [ ] No hardcoded strings
- [ ] No `events/dispatch!`
- [ ] No `@(state/watch ...)`
- [ ] No data transformations
- [ ] No business logic
- [ ] Just render props

### Performance Note

Only use `@(state/watch ...)` in UI components when absolutely necessary for performance optimization. Default: data comes via props from pages multimethod. The router component is the single point that watches page data and passes it down.

---

**Remember:** 
- UI components are pure functions receiving props
- Router does the watching, pages multimethod passes data
- Domain provides markers, application layer transforms them
- If it's not about pixels on screen, it doesn't belong in UI
