# Plane Geometry Property Display Audit

## 1. Scope

This audit defines geometry-property display strategy for Plane v1.1 planning.

- No Swift production code changes
- No test changes
- No UI implementation changes

Goals:

1. Audit what is currently displayed
2. Audit what is computable from current model/resolver
3. Propose row vs inspector responsibility split
4. Identify performance and readability risks

---

## 2. Current Property Display Status

Based on:

- `WorkspaceObjectRowView`
- `GeometryDependencyPresentation`
- `ObjectInspectorPanel`
- `PlaneGeometryResolver`
- `MathObject` / `GeometryDefinition`

### 2.1 Object row today

Object row currently shows:

- Primary: `name + main expression/value`
- Secondary: source/status/simplified/metadata/type (with new source/status priority for derived objects)
- No dedicated numeric geometry-property line (length/radius/slope) as a separate property system.

### 2.2 Inspector today

Object inspector currently shows:

- object basics: name/type/display/visibility/color
- style controls (color/opacity/fill opacity)
- parameter slider settings for parameter objects
- algebra analysis/rewrite/diagnostics sections when available

Inspector does **not** yet provide a structured geometry-property panel (length, slope, radius, direction, etc.).

### 2.3 Resolver capability today

`PlaneGeometryResolver` can already resolve enough primitives for many properties:

- point position
- segment endpoints
- line points
- ray points
- circle center/radius
- intersection primitives conversion inputs

So many geometry properties are technically computable without model changes.

---

## 3. Source Audit Answers

1. **point coordinate display now**  
   Coordinate may appear inside main expression/value, but not as dedicated property field.

2. **segment length now**  
   Not explicitly displayed.

3. **line slope/direction now**  
   Not explicitly displayed.

4. **ray start/direction now**  
   Not explicitly displayed.

5. **circle center/radius now**  
   Not displayed as dedicated geometry property; source relation may mention center/through or center/radius dependency.

6. **intersection now**  
   Source relation and status can be displayed; coordinates depend on main expression/value formatting.

7. **midpoint now**  
   Source relation is displayed; coordinates depend on main expression/value formatting.

8. **parallel/perpendicular now**  
   Source relation is displayed.

9. **function/parametric/piecewise now**  
   Expression-first plus simplified/metadata fallback.

10. **Inspector existing coverage**  
    Primarily object basics + style + parameter + algebra analysis; not geometry-property-focused.

11. **Resolver readiness**  
    Sufficient for low-cost geometry metrics (length, radius, direction vector, simple slope) for point/segment/line/ray/circle classes.

---

## 4. Object-Type Property Matrix

## 4.1 Point

Candidate properties:

- coordinate `(x, y)`
- derived/static marker
- source relation (for derived)

Recommendation:

- Row: keep coordinate in main value (no extra property line)
- Inspector: explicit `x`, `y` fields

## 4.2 Segment

Candidate properties:

- length
- endpoints
- midpoint
- direction angle

Recommendation:

- Row: optional `长度` (only when space allows and no status pressure)
- Inspector: full set (length/endpoints/angle)

## 4.3 Line

Candidate properties:

- slope
- direction vector
- anchor point (point-on-line)
- axis relation (horizontal/vertical)

Recommendation:

- Row: no default property expansion (avoid density increase)
- Inspector: direction vector + slope + axis relation

## 4.4 Ray

Candidate properties:

- start point
- direction vector
- direction angle

Recommendation:

- Row: no default property expansion
- Inspector: start + direction + angle

## 4.5 Circle

Candidate properties:

- center
- radius
- diameter
- area/circumference (optional)

Recommendation:

- Row: `半径` is the most valuable low-noise property candidate
- Inspector: center/radius/diameter, area/circumference as optional follow-up

## 4.6 Intersection

Candidate properties:

- source objects
- coordinate
- definition status

Recommendation:

- Row: source + status priority stays first; coordinate remains in main value
- Inspector: source IDs/names + status + coordinate

## 4.7 Dynamic derived objects (general)

Candidate properties:

- source relation
- resolved geometry snapshot
- status

Recommendation:

- Row: source + non-defined status remain mandatory
- Inspector: detailed dependency kind + resolved values

## 4.8 Function / Parametric / Piecewise

Candidate properties:

- expression summary
- domain/range (when robustly available)
- diagnostics/sampling notes

Recommendation:

- Row: expression-first only
- Inspector: optional richer semantic/sampling details later

---

## 5. Row vs Inspector Responsibility

## 5.1 Object row (conservative)

Row should keep:

1. Main expression/value
2. Dynamic source relation (if derived)
3. Non-defined status (if present)
4. At most one key low-cost metric when it does not crowd source/status

Suggested low-risk row metrics (future optional):

- segment length
- circle radius

Avoid in row by default:

- line/ray slope+direction verbose details
- multi-field coordinate tables
- function domain/range heavy summaries

## 5.2 Inspector (detail surface)

Inspector should host extended geometry properties:

- Point: x, y
- Segment: endpoints, length, angle
- Line: direction vector, slope, axis relation
- Ray: start, direction, angle
- Circle: center, radius, diameter, optional area/circumference
- Intersection: source relation, status, coordinate
- Dynamic object: dependency kind + source refs + current definition status + convert action

---

## 6. Real-time Update and Performance Considerations

## 6.1 Should properties update with recompute?

Yes for geometric primitives. Property values should reflect current resolved geometry after dependency recompute.

## 6.2 Compute-on-render vs cache

For low-cost properties:

- compute-on-render is likely acceptable for v1.1 if scoped narrowly.

For high-cost semantic properties:

- defer or move to Inspector/on-demand computation.

## 6.3 Cost profile

Low-cost:

- segment length
- circle radius
- simple vector/slope from two points

Potentially high-cost / unstable:

- function domain/range estimation
- sampling-derived global properties
- heavy symbolic metadata synthesis

## 6.4 Scrolling risk

Large object counts + per-row heavy property computation can degrade scroll smoothness.
If row properties are introduced, keep to O(1) arithmetic from already resolved endpoints/center/radius.

---

## 7. Copy Suggestions (Chinese)

Row-short labels:

- `长度 3.14`
- `半径 2.00`
- `斜率 1.25`
- `方向 45°`
- `当前无交点`
- `定义无效`

Inspector-long labels:

- `圆心 A`
- `起点 P`
- `方向向量 (dx, dy)`
- `端点 A, B`

Guideline:

- Row copy should stay compact.
- Inspector copy can be explicit and verbose.

---

## 8. Recommended Follow-up Split

1. `GeometryPropertyDisplay-1A` (highest)
   - Add only low-risk row properties (circle radius, segment length), while preserving source/status priority.

2. `GeometryInspectorProperties-1`
   - Add structured detailed property sections in Inspector.

3. `GeometryPropertyFormatting-1`
   - Standardize decimal precision, unit conventions, and angle formatting.

4. `GeometryPropertyPerformanceAudit-1`
   - Validate large-list performance with property computation enabled.

Priority rationale:

- Start with minimal value/high certainty row additions.
- Move rich detail to Inspector to avoid row density regression.
- Finalize formatting and then profile performance.

---

## 9. Deferred Items

Not recommended in immediate pass:

- broad function domain/range property display
- row-level multi-metric expansion
- icon/status ornamentation mixed with first property rollout

