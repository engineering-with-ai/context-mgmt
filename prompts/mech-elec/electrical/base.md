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


### SKiDL — Circuit Definition in Python

Circuits are defined in `cad/model.py` using SKiDL. This is the electrical equivalent of CadQuery — the circuit lives in code, not in a GUI file.

```python
import os
os.environ["KICAD_SYMBOL_DIR"] = "/usr/share/kicad/symbols"

from skidl import *

vin, vout, gnd = Net("VIN"), Net("VOUT"), Net("GND")
r1 = Part("Device", "R", value="1K", footprint="Resistor_SMD:R_0805_2012Metric")
vin += r1[1]
vout += r1[2]

generate_netlist(file_="cad/circuit.net", tool=KICAD8)
```

**Key rules:**
- Set `KICAD_SYMBOL_DIR` env var before importing skidl — it needs KiCad symbol libraries
- Component values come from `sim/constants.py` — strip pint units and uncertainty before passing
- Footprints must be specified for PCB layout: `footprint="Capacitor_SMD:C_0805_2012Metric"`
- Net names should match `sim/model.py` node names for traceability
- `generate_netlist(tool=KICAD8)` outputs KiCad-compatible netlist

**Gotcha:** SKiDL's `isinstance(nid, int)` check fails on numpy int64. Cast to `int()` when passing numeric IDs.


### KiCad Workflow

Deliverables export to `output/` via poe tasks — do NOT run raw `kicad-cli` export commands:
- `uv run poe generate-model` — schematic SVG + PDF to `output/drawings/`
- `uv run poe generate-asm` — gerbers + drill + STEP to `output/gerbers/` and `output/`
- `uv run poe validate-model` — ERC (schematic)
- `uv run poe validate-asm` — DRC (PCB)

**PCB layout is manual** — open in pcbnew (`uv run poe inspect-asm`), place components, route traces, commit the `.kicad_pcb` file. Automation handles everything else.


### kicad-sch-api — Schematic Generation

**Coordinate system — use grid units for EVERYTHING except no_connects:**
- Call `ksa.use_grid_units(True)` once at the start. All `components.add()`, `add_wire()`, and `add_label()` use grid units (1 grid unit = 1.27mm)
- `no_connects.add()` does NOT respect `use_grid_units()` — pass mm coordinates directly (multiply grid × 1.27)
- **NEVER** use `auto_route_pins()`, `connect_pins_with_wire()`, or `add_wire_to_pin()` — these have coordinate bugs in grid-unit mode that produce off-grid wires and broken connections
- **ALWAYS** use `add_wire(start, end)` with explicit grid-unit positions. Calculate pin positions from known offsets.

**Pin offsets (grid units) from component position:**

| Symbol | Pin | Offset |
|---|---|---|
| Device:Q_PMOS | Gate (G) | (-4, 0) |
| Device:Q_PMOS | Drain (D) | (+2, -4) |
| Device:Q_PMOS | Source (S) | (+2, +4) |
| Device:Q_NMOS | Gate | (-4, 0) |
| Device:Q_NMOS | Drain | (+2, -4) |
| Device:Q_NMOS | Source | (+2, +4) |
| Device:D_Schottky | K (cathode) | (-3, 0) |
| Device:D_Schottky | A (anode) | (+3, 0) |
| Device:C | Pin 1 | (0, -3) |
| Device:C | Pin 2 | (0, +3) |
| Device:Polyfuse | Pin 1 | (0, -3) |
| Device:Polyfuse | Pin 2 | (0, +3) |
| Device:R | Pin 1 | (0, +3) |
| Device:R | Pin 2 | (0, -3) |
| Device:R (rot 90) | Pin 1 | (+3, 0) |
| Device:R (rot 90) | Pin 2 | (-3, 0) |
| Device:L | Pin 1 | (0, -3) |
| Device:L | Pin 2 | (0, +3) |
| Device:L (rot 90) | Pin 1 | (-3, 0) |
| Device:L (rot 90) | Pin 2 | (+3, 0) |
| power:+5V / power:+3V3 | Pin 1 | (0, 0) |
| power:GND | Pin 1 | (0, 0) |
| power:PWR_FLAG | Pin 1 | (0, 0) |
| power:PWR_FLAG (rot 180) | Pin 1 | (0, 0) |
| Connector_Generic:Conn_01x0N | Pin K | (-4, 2 - (K-1)*2) |
| Connector_Generic:Conn_02x20_Odd_Even | Odd pin K | (-4, -19 + (K-1)) |
| Connector_Generic:Conn_02x20_Odd_Even | Even pin K | (+6, -19 + (K/2-1)*2) |

**Wiring rules — ERC zero requires ALL of these:**
1. Wire endpoints must land exactly on pin positions — spatial overlap alone does not create a connection
2. Every wire is `sch.add_wire(start=p(x1,y1), end=p(x2,y2))` with manually calculated grid positions
3. All coordinates must be integer grid units — floating point causes off-grid ERC errors
4. Labels work on wire stubs: label at one end, pin at the other end, both on exact grid points. The wire must use `add_wire` (not helper functions)
5. T-junctions: split the long wire into segments sharing an endpoint at the junction — mid-wire taps don't connect
6. Power symbols (`#PWR01`, `#FLG01`) must use explicit `#` prefixed refs — never auto-assigned refs
7. `PWR_FLAG` on VIN and GND nets satisfies ERC "power pin not driven" for connector-fed designs
8. `PWR_FLAG` must be wired to the power net via `add_wire` — placing it nearby is NOT enough
9. Unused pins get `no_connects.add(position=(grid_x * 1.27, grid_y * 1.27))`

**Proven pattern (buck converter achieved 0 ERC):**
```python
ksa.use_grid_units(True)
sch = ksa.create_schematic("Name")

def p(dx, dy):
    return (ORIGIN_X + dx, ORIGIN_Y + dy)

# 1. Power symbols with explicit refs
sch.components.add("power:+5V", "#PWR01", "+5V", position=p(0, 0))
sch.components.add("power:GND", "#PWR02", "GND", position=p(0, 16))
sch.components.add("power:PWR_FLAG", "#FLG01", "PWR_FLAG", position=p(-2, 2))
sch.components.add("power:PWR_FLAG", "#FLG02", "PWR_FLAG", position=p(-2, 16), rotation=180)

# 2. Components
c = sch.components.add("Device:C", "C1", "100nF", position=p(10, 10))
c.footprint = "Capacitor_SMD:C_0402_1005Metric"

# 3. Manual wires using known pin offsets
sch.add_wire(start=p(0, 0), end=p(0, 2))    # +5V to junction
sch.add_wire(start=p(-2, 2), end=p(0, 2))   # PWR_FLAG to junction
sch.add_wire(start=p(0, 2), end=p(10, 2))   # junction to component area
sch.add_wire(start=p(10, 7), end=p(10, 2))  # C1 pin 1 (offset 0,-3 from pos 10,10)

# 4. Labels on connected wires only
sch.add_label("NET_NAME", position=p(5, 2))  # sits on wire between two pins

# 5. No-connects in mm
nc_grid = p(20, 5)
sch.no_connects.add(position=(nc_grid[0] * 1.27, nc_grid[1] * 1.27))
```


### Poe Tasks (standardized across all templates)

| Task | What it does |
|------|-------------|
| checks | ruff format + lint |
| notebook | execute theory.ipynb |
| build | generate code-driven artifacts (netlist+schematic) |
| sim | simulation + pytest assertions |
| validate-model | ERC (schematic) |
| validate-asm | DRC (PCB) |
| inspect-model | open schematic in eeschema |
| inspect-asm | open PCB project in pcbnew |
| generate-model | schematic SVG + PDF to output/drawings/ |
| generate-asm | gerbers + drill + STEP to output/ |
| cover | pytest + coverage |
| review | AI code review |
| commit | full pipeline → push |


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
