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

Deliverables export to `spec/drawings/` via CLI:
- Schematic SVG: `kicad-cli sch export svg cad/<name>.kicad_sch -e -n -o spec/drawings/`
- Schematic PDF: `kicad-cli sch export pdf cad/<name>.kicad_sch -o spec/drawings/<name>.pdf`
- PCB gerbers: `kicad-cli pcb export gerbers cad/<name>.kicad_pcb -o spec/drawings/gerbers/`
- PCB STEP: `kicad-cli pcb export step cad/<name>.kicad_pcb -o spec/drawings/<name>.step`
- ERC: `kicad-cli sch erc cad/<name>.kicad_sch`
- DRC: `kicad-cli pcb drc cad/<name>.kicad_pcb`

**PCB layout is manual** — open in pcbnew (`kicad cad/<name>.kicad_pro`), place components, route traces, commit the `.kicad_pcb` file. Automation handles everything else.


### kicad-sch-api — Schematic Generation

**Pin offsets (grid units) from component position:**

| Symbol | Pin | Offset |
|---|---|---|
| Device:Q_NMOS | Gate | (-4, 0) |
| Device:Q_NMOS | Drain | (+2, -4) |
| Device:Q_NMOS | Source | (+2, +4) |
| Device:D_Schottky | K (cathode) | (-3, 0) |
| Device:D_Schottky | A (anode) | (+3, 0) |
| Device:C | Pin 1 | (0, -3) |
| Device:C | Pin 2 | (0, +3) |
| Device:L | Pin 1 | (0, -3) |
| Device:L | Pin 2 | (0, +3) |
| Device:L (rot 90) | Pin 1 | (-3, 0) |
| Device:L (rot 90) | Pin 2 | (+3, 0) |
| power:+12V / power:GND | Pin | (0, 0) |

**Key rules:**
- Wire endpoints must land exactly on pin positions — spatial overlap alone does not create a connection
- `PWR_FLAG` on VIN and GND nets satisfies ERC "power pin not driven" for connector-fed designs
- `no_connects.add()` does NOT respect `use_grid_units()` — pass mm coordinates directly
- Use `sch.get_component_pin_position()` when available to avoid manual offset math


### Poe Tasks (standardized across all templates)

| Task | What it does |
|------|-------------|
| checks | ruff format + lint |
| notebook | execute theory.ipynb |
| build | generate code-driven artifacts (netlist+schematic) |
| sim | simulation + pytest assertions |
| validate-model | design rule checks (ERC) |
| inspect-model | open single model GUI (schematic) |
| inspect-asm | open assembly GUI (PCB when available) |
| drawings | export SVG/PDF to spec/drawings/ |
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
