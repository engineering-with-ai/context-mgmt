## Electrical Engineering Best Practices


### EE-Conventional Units

Use the units that appear on datasheets and schematics, not SI base units.

| Quantity | Use | Not |
|---|---|---|
| Resistance | kOhm, MOhm | Ohm (for large values) |
| Capacitance | pF, nF, uF | F |
| Inductance | nH, uH, mH | H |
| Signal current | mA, uA | A |
| Fault / bus current | kA | A |
| Wire gauge | AWG | m² |
| Frequency | kHz, MHz | Hz (for large values) |
| Time constants | us, ms | s (when sub-second) |
| PCB trace width | mil, mm | m |

Let pint `.to()` handle conversion to SI when computation requires it.


### Component Tolerance Conventions

Always state tolerance source — don't guess.

| Component | Typical Tolerance | Source |
|---|---|---|
| Thick film resistor | +/-1%, +/-5% | Datasheet series (E96, E24) |
| Thin film resistor | +/-0.1%, +/-0.5% | Datasheet |
| MLCC (C0G/NP0) | +/-5% | Datasheet, stable over temp |
| MLCC (X5R/X7R) | +/-10%, +/-20% | Datasheet — derate for DC bias and temp |
| Electrolytic | +/-20% | Datasheet — derate for ESR aging |
| Inductor | +/-10%, +/-20% | Datasheet — check saturation current |

When building `ufloat` values, the uncertainty is the tolerance from the datasheet:
```python
RESISTANCE: Final = ufloat(1.0, 0.05) * ureg.kohm   # 1.0 kOhm +/-5%, generic thick film
CAPACITANCE: Final = ufloat(10.0, 1.0) * ureg.uF     # 10 uF +/-10%, generic MLCC X7R
```


### pint + uncertainties Access Pattern

pint wraps ufloat. Strip unit first (`.magnitude`), then strip uncertainty (`.nominal_value`).

```python
TAU = (RESISTANCE * CAPACITANCE).to(ureg.ms)

TAU.magnitude                # → ufloat (e.g. 10.0+/-1.12)
TAU.magnitude.nominal_value  # → float (e.g. 10.0)
TAU.magnitude.std_dev        # → float (e.g. 1.12)
```

**WRONG:** `TAU.nominal_value.magnitude` — pint Quantity has no `.nominal_value`.


### PySpice / ngspice Conventions

#### Circuit Construction
- Use PySpice unit decorators for netlist values: `v0 @ u_V`, `r @ u_kOhm`, `c @ u_uF`
- Strip pint units and uncertainty before passing to PySpice — it needs plain floats with its own unit system
- Name nodes semantically: `"input"`, `"output"`, `"bus"`, `"fault_point"` — not `"n1"`, `"n2"`

```python
# Correct: strip pint unit, strip uncertainty, apply PySpice unit
r = RESISTANCE.magnitude.nominal_value
circuit.R(1, "input", "output", r @ u_kOhm)
```

#### Transient Simulation
- **Always use `use_initial_condition=True`** for charging/discharging circuits. Without it, SPICE computes a DC operating point first — capacitors start charged, inductors start at steady-state current. This is the #1 PySpice gotcha.
- Choose `step_time` and `end_time` relative to the circuit's time constant — 5*tau is a reasonable end time for steady state
- Justify timestep: `step_time` should be at least 100x smaller than the fastest time constant

```python
analysis = simulator.transient(
    step_time=10 @ u_us,       # Reason: tau ~10ms, step = tau/1000
    end_time=50 @ u_ms,        # Reason: 5*tau for steady state
    use_initial_condition=True, # Reason: start capacitor at 0V
)
```

#### Extracting Results
- Analysis node names match your circuit node names: `analysis["output"]`
- Time is in seconds — convert to ms for readability: `time_ms = time_s * 1e3`
- Convert to numpy arrays for assertion: `np.array([float(v) for v in analysis["output"]])`


### KiCad Workflow

- Schematics live in `cad/` directory with `.kicad_sch` extension
- Open for editing: `eeschema cad/<name>.kicad_sch`
- Export to SVG: `kicad-cli sch export svg cad/<name>.kicad_sch -o cad/drawings/`
- Export to PDF: `kicad-cli sch export pdf cad/<name>.kicad_sch -o cad/drawings/`
- Run ERC: `kicad-cli sch erc cad/<name>.kicad_sch`
- Schematic should match the netlist in `sim/model.py` — same topology, same node names, same component values

#### Export Formats
Two export targets — one for web/readme, one for documentation:
- **SVG (web/readme):** `kicad-cli sch export svg <file> -e -n -o cad/drawings/` — strips drawing sheet border and background for clean embedding
- **PDF (documentation):** `kicad-cli sch export pdf <file> -o cad/drawings/<name>.pdf` — keeps the professional drawing sheet border with title block

#### Presentable Schematics
- Center the circuit on the schematic sheet — not crammed in the upper-left corner. For A4 paper, center is approximately (148.5, 105.0) mm
- Keep the circuit compact — minimize wire lengths, align components on 2.54mm grid

#### Visual Review After Generation — Non-Negotiable
After generating or modifying a KiCad schematic, you MUST visually review it:
1. Export SVG: `kicad-cli sch export svg <file> -t engineering -e -n -o cad/drawings/`
2. Convert to PNG: `rsvg-convert -w 1600 cad/drawings/<name>.svg -o /tmp/<name>_review.png`
3. Read the PNG with the Read tool and inspect for:
   - Labels overlapping component references or values
   - Components too close together (need ~20mm between centers for horizontal chains)
   - Circuit not centered on the page
   - Wires crossing through component bodies
4. Fix any issues and re-export before proceeding


### KiCad Schematic Generation (.kicad_sch)

KiCad schematics are s-expression files. You can generate them programmatically.

**File structure:**
```
(kicad_sch
  (version 20230121)
  (generator "claude")
  (uuid "<sheet-uuid>")
  (paper "A4")
  (lib_symbols ...)     ← embedded copies of symbols used
  (wire ...)            ← wires connecting pins
  (label ...)           ← net labels (must match sim/model.py node names)
  (symbol ...)          ← placed component instances
  (sheet_instances ...)
)
```

**Symbol libraries — where to find them:**
- Standard symbols: `/usr/share/kicad/symbols/`
- Passive components (R, C, L): `Device.kicad_sym` → lib_id `"Device:R"`, `"Device:C"`, `"Device:L"`
- SPICE sources and ground: `Simulation_SPICE.kicad_sym` → lib_id `"Simulation_SPICE:VDC"`, `"Simulation_SPICE:0"`
- Power symbols (VCC, GND): `power.kicad_sym` → lib_id `"power:GND"`, `"power:VCC"`

**Extracting symbol definitions for lib_symbols:**
Each schematic must embed copies of the symbols it uses. Extract them from the `.kicad_sym` files by parsing the s-expression — find the top-level `(symbol "NAME" ...)` block, prefix with library name for `lib_symbols`.

**Placing a component instance:**
```
(symbol (lib_id "Device:R") (at 144.78 55.88 90) (unit 1)
  (in_bom yes) (on_board yes) (dnp no)
  (uuid "<component-uuid>")
  (property "Reference" "R1" (at 144.78 52.07 90)
    (effects (font (size 1.27 1.27)))
  )
  (property "Value" "1k" (at 144.78 54.13 90)
    (effects (font (size 1.27 1.27)))
  )
  (property "Footprint" "" (at ...) (effects (font (size 1.27 1.27)) hide))
  (property "Datasheet" "~" (at ...) (effects (font (size 1.27 1.27)) hide))
  (pin "1" (uuid "<pin-uuid>"))
  (pin "2" (uuid "<pin-uuid>"))
  (instances
    (project "<project-name>"
      (path "/<sheet-uuid>" (reference "R1") (unit 1))
    )
  )
)
```

**Key rules:**
- All coordinates on 2.54mm grid
- Rotation: 0 = default orientation, 90 = rotated (e.g. horizontal resistor)
- Every element needs a unique UUID (use `uuid.uuid4()`)
- Wire endpoints must land exactly on pin positions
- `(label "node_name" ...)` creates named nets — use these to match `sim/model.py` node names
- Validate with: `kicad-cli sch export svg <file> -o /tmp/` — if it exports, the format is valid

**Pin offsets from component origin (at default rotation 0):**

| Symbol | Pin 1 offset | Pin 2 offset |
|---|---|---|
| Device:R | (0, -3.81) top | (0, +3.81) bottom |
| Device:C | (0, -3.81) top | (0, +3.81) bottom |
| Device:L | (0, -3.81) top | (0, +3.81) bottom |
| Simulation_SPICE:VDC | (0, -5.08) positive | (0, +5.08) negative |
| Simulation_SPICE:0 | (0, 0) single pin | — |
| power:PWR_FLAG | (0, 0) single pin | — |

When rotated 90 degrees, swap x/y offsets. When rotated 180, negate offsets.

**Power symbol connection rule:** Wire endpoints must land exactly on power symbol pin positions. Split long wires into segments that pass through each power pin location — spatial overlap alone does not create a connection.

**PWR_FLAG rule:** Every net with a `power_in` pin (like `Simulation_SPICE:0`) needs a `power:PWR_FLAG` on the same net to satisfy ERC. Place it on the same wire, rotated 180 so it points down toward the wire.


### schemdraw for Documentation

Use schemdraw for quick circuit diagrams in notebooks and readmes when a full KiCad schematic is overkill:
```python
import schemdraw
import schemdraw.elements as elm

with schemdraw.Drawing() as d:
    d += elm.SourceV().label("V_s")
    d += elm.Resistor().right().label("R")
    d += elm.Capacitor().down().label("C")
    d += elm.Line().left()
```


### SPICE Gotchas

| Gotcha | Symptom | Fix |
|---|---|---|
| Missing `use_initial_condition=True` | Capacitor starts charged, inductor has steady-state current | Add `use_initial_condition=True` to `.transient()` |
| Floating node | Simulation fails or gives nonsense | Every node must have a DC path to ground |
| Timestep too large | Waveform looks jagged or misses transients | `step_time` should be 100-1000x smaller than fastest tau |
| Node name mismatch | `KeyError` when extracting results | Use exact node name string from circuit definition |
| Convergence failure | ngspice reports `no convergence` | Add `.options(reltol=0.01)` or check for unrealistic component values |


### EE Anti-Bias Rules

| AI Bias | Correct Practice |
|---|---|
| Ignores ESR on capacitors | Electrolytic ESR matters for ripple current and loop stability — state if neglected and why |
| Assumes ideal op-amps | Real op-amps have offset voltage, bias current, slew rate, GBW — state which limits apply |
| Skips decoupling capacitors | Every IC power pin needs local decoupling — not optional in real designs |
| Uses unrealistic component values | Check that values exist in standard series (E24, E96). 1.37 kOhm is not a real resistor |
| Ignores temperature coefficients | MLCC X7R loses 50%+ capacitance at rated voltage and high temp — derate or use C0G |
| Treats wire as zero impedance | At high frequency or high current, wire/trace impedance matters — state when neglected |
| Assumes instantaneous switching | Real switches have rise/fall time, dead time, ringing — matters for EMI and loss calculations |
| Defaults to DC analysis | Most real circuits have AC behavior that matters — check if transient or frequency analysis is needed |
