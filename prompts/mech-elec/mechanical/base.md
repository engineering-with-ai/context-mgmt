## Mechanical Engineering Best Practices


### ME-Conventional Units

Use the units that appear on drawings and datasheets, not SI base units.

| Quantity | Use | Not |
|---|---|---|
| Length / dimensions | mm | m |
| Force | N, kN | — |
| Stress / modulus | MPa, GPa | Pa |
| Moment of inertia | mm^4 | m^4 |
| Deflection | mm | m |
| Mass | kg | — |
| Temperature | degC | K (except for thermal calcs) |

Let pint `.to()` handle conversion when computation requires it.


### CadQuery — Parametric Geometry in Python

Geometry is defined in `cad/model.py` using CadQuery. This is the mechanical equivalent of SKiDL — the geometry lives in code, not in a GUI file.

```python
import cadquery as cq
from sim.constants import BEAM_LENGTH, BEAM_WIDTH, BEAM_HEIGHT, ureg

def build_beam() -> cq.Workplane:
    l = BEAM_LENGTH.to(ureg.mm).magnitude
    w = BEAM_WIDTH.to(ureg.mm).magnitude
    h = BEAM_HEIGHT.to(ureg.mm).magnitude
    return cq.Workplane("XY").box(l, w, h)
```

**Key rules:**
- Dimensions come from `sim/constants.py` — strip pint units before passing to CadQuery
- Export to STEP for downstream FEM: `beam.export("cad/part.step")`
- CadQuery SVG export for drawings (front, side, iso projections)
- FreeCAD for interactive inspection only — not the source of truth


### pygccx — CalculiX FEM via Python

FEM analysis uses pygccx, which handles mesh generation (gmsh), input deck writing, solving (CalculiX), and result parsing in a single API.

```python
from pygccx import model as ccx_model
from pygccx import model_keywords as mk
from pygccx import step_keywords as sk
from pygccx import enums

with ccx_model.Model(CCX_PATH, CGX_PATH, jobname="part", working_dir=wkd) as model:
    gmsh = model.get_gmsh()
    gmsh.model.occ.importShapes("cad/part.step")
    gmsh.model.occ.synchronize()
    gmsh.model.mesh.generate(3)

    gmsh.model.add_physical_group(3, [1], name="BODY")
    gmsh.model.add_physical_group(2, face_tags, name="FIX")

    model.update_mesh_from_gmsh()
    mesh = model.mesh

    mat = mk.Material("STEEL")
    el = mk.Elastic((E_mpa, nu))
    sos = mk.SolidSection(elset=mesh.get_el_set_by_name("BODY"), material=mat)
    fix_set = mesh.get_node_set_by_name("FIX")
    model.add_model_keywords(mk.Boundary(fix_set, first_dof=1, last_dof=3), mat, el, sos)

    step = sk.Step(nlgeom=False)
    step.add_step_keywords(sk.Static(), cload, sk.NodeFile([enums.ENodeFileResults.U]), sk.ElFile([enums.EElFileResults.S]))
    model.add_steps(step)

    model.solve()
    frd = model.get_frd_result()
```

**Key rules:**
- Physical groups in gmsh define node/element sets for BCs and material assignment
- `model.update_mesh_from_gmsh()` converts gmsh mesh to pygccx mesh
- Node set `.ids` returns a `set[int]` — use `list()` for iteration
- **Cast numpy int64 to `int()` before passing to Cload** — pygccx `isinstance(nid, int)` fails on numpy types
- Use `st.get_mises_stress()` from `pygccx.tools.stress_tools` for von Mises — don't hand-roll
- Results from `frd.get_result_sets_by(entity=enums.EFrdEntities.DISP)` return numpy arrays


### FEM Validation Rules

- **Mesh convergence:** Refine mesh until result changes < 2% between refinements
- **Sanity check:** FEM result must be within 10% of Euler-Bernoulli hand calc for simple geometries
- **Element quality:** gmsh reports mesh quality — no degenerate tets (quality > 0.2)


### Poe Tasks (standardized across all templates)

| Task | What it does |
|------|-------------|
| checks | ruff format + lint |
| notebook | execute theory.ipynb |
| build | generate code-driven artifacts (STEP) |
| sim | simulation + pytest assertions |
| validate-model | design rule checks (BRep+bbox) |
| inspect-model | open single model GUI (part) |
| inspect-asm | open assembly GUI (multi-body STEP) |
| drawings | export SVG/PDF to spec/drawings/ |
| cover | pytest + coverage |
| review | AI code review |
| commit | full pipeline → push |


### CadQuery Gotchas

- **Never use `.faces()` selectors for hole placement.** CadQuery's `<X`/`>X` face selectors pick faces by center coordinate, which is ambiguous on L-shapes and complex geometry. Instead, cut holes explicitly with `.cut()` using cylinders at known 3D coordinates.
- **CadQuery `.fillet()` on `edges("|Y")` fillets ALL Y-parallel edges.** Use `.filter(lambda edge: ...)` with bounding box checks to target a specific edge.
- **CadQuery `extrude()` on XZ workplane goes in -Y direction.** Account for this when computing 3D positions for downstream operations.
- **CadQuery color names are limited.** Use `cq.Color(r, g, b)` with floats 0-1 instead of named colors — many common names like `"darkgray"` are not recognized.
- **CadQuery Assembly**: `assy.add(part, loc=cq.Location((x,y,z), (rx,ry,rz)))` for positioning. Rotation is Euler angles in degrees.


### gmsh / OCC Geometry Gotchas

- **OCC splits cylindrical hole surfaces into half-cylinders.** A through-hole produces 2 cylinder faces, each with area ≈ π·d·t/2. Detect by matching half the expected area, not full.
- **Use `gmsh.model.getType(dim, tag)` to distinguish surface types.** Returns `"Cylinder"`, `"Plane"`, `"BSpline"`, etc. Filter by type before checking area or bbox to avoid false matches (e.g. fillet cylinders vs bolt hole cylinders).
- **Use `gmsh.model.occ.getMass(dim, tag)` for surface area.** This is the reliable way to get face area for identification — more robust than bbox dimensions.
- **Fillet surfaces are also cylinders in OCC.** A 90° fillet of radius r across width w has area = π·r·w/2. Distinguish from bolt holes by area magnitude.


### pygccx Reaction Force Extraction

- **Request reaction forces with `sk.NodeFile([enums.ENodeFileResults.RF])`** in the step keywords. Results appear in FRD as `enums.EFrdEntities.FORC`.
- **Split constrained nodes by coordinate to get per-feature forces.** Sum reaction vectors per group, then take magnitude for the resultant.
- **Fixing all DOFs on cylindrical hole surfaces models a rigid pin.** This over-constrains vs real bolted connections. Expect FEM bolt forces to be 15-25% lower than rigid-bracket hand calcs — the hand calc is intentionally conservative for design.


### Hand Calc vs FEM Tolerance Guidelines

| Comparison | Typical tolerance | Reason |
|---|---|---|
| Simple beam (Euler-Bernoulli vs FEM) | 5-10% | Closed-form is exact for prismatic beams |
| Bolt group (rigid assumption vs FEM) | 20-25% | Rigid bracket assumption is conservative by design |
| Stress at geometric discontinuities | 10-15% | Mesh-dependent near fillets, holes, corners |
| Global equilibrium (total reaction vs applied load) | < 1% | Must hold — if not, model is broken |
