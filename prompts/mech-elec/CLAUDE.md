## Core Directive

Push back, expose my ideas weak spots, don't tell me I'm right unless I'm objectively right.

## Methodologies

### Implementation Methodology
When presented with a request YOU MUST:
1. Use context7 mcp server or websearch tool to get the latest related documentation. Understand the API deeply and all of its nuances and options
2. Use TDD Approach: Derive the expected value in `theory.ipynb` first, then write the sim assertion in `run.py` that fails, then build the model until it passes
3. Start with the simplest hand calc — back-of-envelope before simulation
4. See the assertion fail against the notebook's expected value
5. Make the smallest change to the model
6. Check if `uv run poe checks` and `uv run poe cover` pass
7. Repeat steps 5-6 until the assertion passes
8. You MUST NOT move on until assertions pass

### Debugging Methodology

#### Phase I: Information Gathering
1. Understand the error
2. Read the relevant source code: try local `.venv`
3. Look at any relevant github issues for the library

#### Phase II: Testing Hypothesis
4. Develop a hypothesis that resolves the root cause of the problem. Must only chase root cause possible solutions. Think hard to decide if its root cause or NOT.
5. Add debug logs to determine hypothesis
6. If not successful, YOU MUST clean up any artifact or code attempts in this debug cycle. Then repeat steps 1-5

#### Phase III: Weigh Tradeoffs
7. If successful and fix is straightforward. Apply fix
8. If not straightforward, weigh the tradeoffs and provide a recommendation


## Units & Dimensional Analysis — Non-Negotiable

Bare floats are the `Any` of engineering. Every physical value MUST have a pint unit.

- **No bare floats for physical quantities.** `velocity = 3.5` is NEVER ALLOWED. `velocity = 3.5 * ureg.m / ureg.s` is correct.
- **No manual unit conversions.** Let pint `.to()` handle all conversions. Manual conversion factors are the equivalent of `# type: ignore` — they bypass the guardrail.
- **No `float` annotations for physical quantities.** Use `pint.Quantity` in type hints.
  - NOT: `def calc_force(mass: float, accel: float) -> float:`
  - CORRECT: `def calc_force(mass: Quantity, accel: Quantity) -> Quantity:`
- **Use domain-conventional units, not SI base units everywhere.** kA not A for fault current, bar not Pa for hydraulic pressure, AWG not m² for wire gauge. Let pint handle the conversion to SI when computation requires it.


## Uncertainty & Precision

- **No results without uncertainty.** If you can't state the error band, the result is incomplete. Use the `uncertainties` library to propagate error through calculations.
- **No false precision.** If your input is +/-5%, your output cannot have 7 significant figures. Report results to the number of significant figures justified by your inputs.
- **Never round intermediate results.** Carry full precision through the calculation chain. Round only in the final reporting cell.


## Constants & Physical Parameters

Every constant needs a name, a unit, and a source. A magic `0.85` in engineering could be a safety factor, a derating, an efficiency, or a power factor — getting it wrong can mean a fire.

- **All physical constants at module level in SCREAMING_SNAKE_CASE** with `Final` annotation, pint unit, and source comment
  ```python
  FUSE_DERATING: Final = 0.80 * ureg.dimensionless  # UL 248 Table 1
  GRAVITY: Final = 9.80665 * ureg.m / ureg.s**2  # ISO 80000-3
  ```
- **No inline physical constants.** Never write `force = mass * 9.81`. Define it once, name it, source it.
- **Standards references must include edition, table, and clause.** "Per IEEE 1547" is meaningless. "Per IEEE 1547-2018 Table 1, Category III" is a reference.


## Assumptions

AI silently assumes ideal conditions — zero wire resistance, no temperature derating, negligible contact resistance, lossless transmission. Every one of these is an engineering `Any`.

- **Every assumption must be stated explicitly** in the notebook's assumptions cell before any derivation
- **If you can't name the assumption, you can't validate the result**
- **When the sim disagrees with theory, the first place to look is the assumptions cell** — did an assumption break, or did the sim break?
- **No idealized defaults.** Real systems have parasitics, losses, and tolerances. State which you are neglecting and why.


## Notebook Discipline

`theory.ipynb` is a calculation document, not a tutorial.

- **Notebook structure:** Assumptions cell -> Derivation cells -> Expected value cell
- **The expected value cell is your type signature.** It defines what correct looks like before you simulate: `# Peak fault current: 4.2kA +/- 10%`
- **No tutorial-style prose between cells.** Brief `# Reason:` comments for non-obvious steps. The derivation speaks for itself.
- **Every notebook must be re-runnable.** No cells that depend on manual execution order.


## Simulation Validation

Never trust simulation output. Validate it.

### Order-of-Magnitude First
- Before running any sim, the notebook must have a hand calc that gets you within 2-5x of the answer
- If the sim is 10x off from the hand calc, one of them is wrong — figure out which before proceeding
- This is the engineering "see the test fail" step

### Conservation Law Checks
- Energy in = energy out + losses
- Mass flow in = mass flow out
- Current into a node = current out
- If conservation doesn't hold, the model is wrong — not the physics

### Convergence is Not Optional
- **Mesh convergence for FEM** — refine until the result stops changing within tolerance
- **Timestep convergence for transient sims** — halve the timestep and verify the result holds
- **Solver tolerance must be justified, not defaulted.** "It ran without errors" is not validation.


## Derating & Safety Factors

- **Components have temperature derating, altitude derating, aging factors.** These are not optional.
- **Safety factors must be explicit and sourced** — never assumed or buried in a calculation
- **Worst-case analysis is the default.** Nominal-case results are supplementary, not primary.


## Code Structure & Modularity

- **Write the most minimal code to get the job done**
- **Get to root of the problem.** Never write hacky workarounds. You are done when the assertions pass.
- **Never create a file longer than 200 lines of code.** If a file approaches this limit, refactor by splitting it into modules.


## Testing & Reliability

- **Fail fast, fail early.** Detect errors as early as possible and halt execution. Rely on the runtime to handle the error and provide a stack trace. You MUST NOT write random error handling for no good reason.
- **Use AAA (Arrange, Act, Assert) pattern for tests:**
  - **Arrange**: Set up the necessary context and inputs
  - **Act**: Execute the simulation or calculation
  - **Assert**: Verify the outcome matches the notebook's expected value within tolerance
- **Use `pytest.approx` with `rel` tolerance for physical quantity assertions**
  ```python
  assert actual_current.magnitude == pytest.approx(expected_current.magnitude, rel=0.10)
  ```


## Style

- **Constants in code:** Write top level declarations in SCREAMING_SNAKE_CASE with `Final` annotation
- **Use explicit type hints ALWAYS.** No `Any`. No bare `float` for physical quantities.
- **Prefer Pydantic models over dicts for structured data**
- **Use proper logging, not print() debugging**
- **Write concise Google Style Docstrings for an LLM to consume**

## Documentation
 - **Write comments in a terse and casual tone**
- **Comment non-obvious code.** Everything should be understandable to a mid-level d
eveloper.
- **Add an inline `# Reason:` comment** for complex logic — explain the why, not the what.


## AI Behavior Rules

- **Never declare an API broken without research and confirmation.** If something doesn't work as expected, the first assumption is that you're using it wrong. Before concluding "bug": (1) search docs, forums, and GitHub issues, (2) read the library source, (3) write an isolated probe that eliminates your own usage errors. Only after all three confirm the behavior, label it a bug.


## Anti-Bias Rules

| AI Bias | Correct Practice |
|---|---|
| Declares an API broken after one failed attempt | Research docs + forums + issues first. Write an isolated test. Your usage is wrong until proven otherwise |
| Uses ideal/textbook models by default | Real systems have parasitics, losses, tolerances — state which you're neglecting and why |
| Writes tutorial-style notebooks with markdown explanations between every cell | Notebook is a calculation document — derivation, numbers, expected value. Not a teaching tool |
| Presents single-point results as definitive | Every result has a tolerance band. If you can't state the band, you don't understand the result |
| Defaults to SI base units everywhere | Use domain-conventional units — kA for fault current, bar for hydraulic pressure, AWG for wire gauge |
| Rounds intermediate results | Never round until final reporting. Carry full precision through the calculation chain |
| Skips derating and safety factors | Components have temperature derating, altitude derating, aging factors. These are not optional |
| Cites standards without edition/table/clause | "Per IEEE 1547" is meaningless — "Per IEEE 1547-2018 Table 1, Category III" is a reference |
| Uses default solver settings without justification | Timestep, mesh density, tolerance — all must be explicit choices with stated rationale |
| Trusts simulation output without sanity checks | Conservation law check and order-of-magnitude hand calc before accepting any result |
