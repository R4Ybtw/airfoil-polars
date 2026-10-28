
import cadquery as cq

DEPTH = 10.0  # mm


def load(path):
    pts = []
    with open(path) as f:
        for line in f:
            x, y, _ = (float(v) for v in line.split())
            pts.append((x, y))
    return pts


for tag in ("naca0012", "naca4412"):
    up = load(f"{tag}_upper_mm.txt")   # LE -> TE
    lo = load(f"{tag}_lower_mm.txt")   # LE -> TE
    # one closed loop: TE -> upper (reversed) -> LE -> lower -> TE
    upper = cq.Edge.makeSpline([cq.Vector(x, y, 0) for x, y in reversed(up)])
    lower = cq.Edge.makeSpline([cq.Vector(x, y, 0) for x, y in lo])
    wire = cq.Wire.assembleEdges([upper, lower])
    face = cq.Face.makeFromWires(wire)
    body = cq.Workplane("XY").add(cq.Solid.extrudeLinear(face, cq.Vector(0, 0, DEPTH)))
    solid = body.val()
    bb = solid.BoundingBox()
    cq.exporters.export(body, f"{tag}_2d.step")
    print(f"{tag}: chord {bb.xlen:.2f} mm, x {bb.xmin:.2f}..{bb.xmax:.2f}, "
          f"thickness {bb.ylen:.2f} mm, depth {bb.zlen:.1f} mm, valid={solid.isValid()}")
