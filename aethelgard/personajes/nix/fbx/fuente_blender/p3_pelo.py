# Nix piloto FBX: localiza el pelo por el color horneado (claro y poco saturado) y describe los mechones delanteros y el
# superior para situar sus huesos.
#   blender -b --factory-startup -P p3_pelo.py -- <blend paso 2> <png color>
import sys, bpy
import numpy as np
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.open_mainfile(filepath=argv[0])
o = bpy.data.objects["nix_baja"]
me = o.data
im = bpy.data.images.load(argv[1])
W, H = im.size
px = np.array(im.pixels[:], dtype=np.float32).reshape(H, W, 4)
uv = me.uv_layers.active.data
acc = {}
for p in me.polygons:
    for li in p.loop_indices:
        vi = me.loops[li].vertex_index
        u, v = uv[li].uv
        c = px[min(H - 1, max(0, int(v * H))), min(W - 1, max(0, int(u * W))), :3]
        acc.setdefault(vi, []).append(c)
pelo = set()
for vi, cs in acc.items():
    c = np.mean(cs, axis=0)
    lum = c.mean(); sat = c.max() - c.min()
    if lum > 0.5 and sat < 0.10:
        pelo.add(vi)
print("PELO vértices", len(pelo), "de", len(me.vertices))
V = me.vertices
for lado, s in [("izq", 1), ("der", -1)]:
    q = [V[i].co for i in pelo if V[i].co.z < 1.62 and V[i].co.x * s > 0.03 and V[i].co.y < 0.08]
    if not q:
        print("MECHON", lado, "nada"); continue
    print("MECHON %s n %d z %.3f..%.3f" % (lado, len(q), min(p.z for p in q), max(p.z for p in q)))
    for z in np.arange(1.62, min(p.z for p in q) - 0.02, -0.03):
        b = [p for p in q if abs(p.z - z) < 0.015]
        if b:
            c = sum(b, Vector()) / len(b)
            print("   z %.2f n %3d centro x %.3f y %.3f  x %.3f..%.3f y %.3f..%.3f" % (z, len(b), c.x, c.y, min(p.x for p in b),
                  max(p.x for p in b), min(p.y for p in b), max(p.y for p in b)))
q = [V[i].co for i in pelo if V[i].co.z > 1.78]
print("ARRIBA n %d zmax %.3f" % (len(q), max(p.z for p in q)))
for z in np.arange(1.78, max(p.z for p in q) + 0.01, 0.02):
    b = [p for p in q if abs(p.z - z) < 0.01]
    if b:
        c = sum(b, Vector()) / len(b)
        print("   z %.2f n %3d centro x %.3f y %.3f  x %.3f..%.3f y %.3f..%.3f" % (z, len(b), c.x, c.y, min(p.x for p in b),
              max(p.x for p in b), min(p.y for p in b), max(p.y for p in b)))
# piel de la cara: el resto del cráneo (no pelo) por encima del cuello
q = [V[i].co for i in range(len(V)) if i not in pelo and V[i].co.z > 1.58]
print("NO_PELO cabeza n %d z %.3f..%.3f" % (len(q), min(p.z for p in q), max(p.z for p in q)))
