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

| Task | Command | What it does |
|------|---------|-------------|
| checks | `uv run poe checks` | ruff format + lint |
| notebook | `uv run poe notebook` | execute theory.ipynb |
| build | `uv run poe build` | CadQuery → STEP |
| sim | `uv run poe sim` | pygccx + pytest |
| inspect | `uv run poe inspect` | open STEP in FreeCAD |
| export | `uv run poe export` | CadQuery SVG drawings → spec/ |
| validate | `uv run poe validate` | mesh convergence checks |
