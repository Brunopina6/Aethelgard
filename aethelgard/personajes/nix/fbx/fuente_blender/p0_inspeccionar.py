# Nix piloto FBX, paso 0: inspección del FBX copiado (sin modificarlo).
#   blender -b --factory-startup -P p0_inspeccionar.py -- <fbx>
import sys, bpy, bmesh
from collections import Counter
argv = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=argv[0])
for o in bpy.data.objects:
    print("OBJ", o.name, o.type, tuple(round(v, 3) for v in o.dimensions), "rot", tuple(round(v, 3) for v in o.rotation_euler),
          "esc", tuple(round(v, 4) for v in o.scale))
o = [o for o in bpy.data.objects if o.type == 'MESH'][0]
me = o.data
print("UV capas", [u.name for u in me.uv_layers], "materiales", [m.name for m in me.materials])
mw = o.matrix_world
zs = [(mw @ v.co).z for v in me.vertices]
print("z min %.3f max %.3f" % (min(zs), max(zs)))
# triángulos por franja de altura (10 cm)
c = Counter()
for p in me.polygons:
    z = (mw @ p.center).z
    c[int(z * 10)] += len(p.vertices) - 2
for k in sorted(c):
    print("FRANJA %.1f-%.1f m  %6d tri" % (k / 10, (k + 1) / 10, c[k]))
# islas UV y piezas sueltas
bm = bmesh.new(); bm.from_mesh(me)
bm.verts.ensure_lookup_table()
# piezas conectadas
vistos = set(); piezas = []
for v in bm.verts:
    if v.index in vistos:
        continue
    pila = [v]; n = 0; zz = []
    vistos.add(v.index)
    while pila:
        a = pila.pop(); n += 1; zz.append((mw @ a.co))
        for e in a.link_edges:
            b = e.other_vert(a)
            if b.index not in vistos:
                vistos.add(b.index); pila.append(b)
    zmin = min(p.z for p in zz); zmax = max(p.z for p in zz)
    xm = sum(p.x for p in zz) / n; ym = sum(p.y for p in zz) / n
    piezas.append((n, zmin, zmax, xm, ym))
piezas.sort(reverse=True)
print("PIEZAS conectadas", len(piezas))
for p in piezas[:25]:
    print("  PIEZA verts %6d z %.3f-%.3f centro x %.3f y %.3f" % p)
# islas UV (aprox.: aristas de costura UV)
uv = bm.loops.layers.uv.active
cost = 0
for e in bm.edges:
    if len(e.link_loops) == 2:
        l1, l2 = e.link_loops
        a1 = l1[uv].uv; b1 = l1.link_loop_next[uv].uv
        a2 = l2[uv].uv; b2 = l2.link_loop_next[uv].uv
        if (a1 - b2).length > 1e-5 or (b1 - a2).length > 1e-5:
            cost += 1
print("ARISTAS de costura UV", cost, "de", len(bm.edges), "bordes abiertos", sum(1 for e in bm.edges if len(e.link_faces) == 1))
for m in me.materials:
    if m.use_nodes:
        for n in m.node_tree.nodes:
            if n.type == 'TEX_IMAGE' and n.image:
                print("TEX", n.image.name, n.image.size[:], n.image.colorspace_settings.name)
