# Nix piloto FBX, paso 1: reducción de la malla del Silver Sentinel (copia) a presupuesto móvil.
#   blender -b --factory-startup -P p1_reducir.py -- <fbx copia> <carpeta render> <blend salida> <objetivo_tri> [sin_antes]
# Deja los pies en z = 0, mide la cara, renderiza el original (antes), reduce con «Decimate» (colapso) y renderiza el
# resultado con la textura original (UV conservadas).
# Protección de la cara (NIX_FACTOR > 0): grupo «detalle» con peso 1 en todo y NIX_PESO_CARA en la cara (delante de la cabeza) y el cuello. Probado
# el 14/11: los vértices SIN peso no se reducen nunca (con solo la cara en el grupo se queda en 418.196).
import sys, os, bpy, bmesh
from mathutils import Vector
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nix_comun as C

argv = sys.argv[sys.argv.index("--") + 1:]
FBX, REND, BLEND, OBJ = argv[0], argv[1], argv[2], int(argv[3])
SIN_ANTES = "sin_antes" in argv
FACTOR = float(os.environ.get("NIX_FACTOR", "0"))
os.makedirs(REND, exist_ok=True)

nuevos = C.importar_fbx(FBX)
alta = [o for o in nuevos if o.type == 'MESH'][0]
alta.name = "nix_alta"
me = alta.data
zmin = min(v.co.z for v in me.vertices)
for v in me.vertices:
    v.co.z -= zmin
me.update()
ALTO = max(v.co.z for v in me.vertices)
print("ALTO %.3f" % ALTO)

franja = [v.co for v in me.vertices if 1.60 < v.co.z < 1.72 and abs(v.co.x) < 0.03]
ymin = min(p.y for p in franja); ymax = max(p.y for p in franja)
nariz = min(franja, key=lambda p: p.y)
print("NARIZ %.3f %.3f %.3f  cabeza y %.3f..%.3f" % (nariz.x, nariz.y, nariz.z, ymin, ymax))
CARA = Vector((0.0, nariz.y, nariz.z + 0.02))

if not SIN_ANTES:
    C.render_vistas(os.path.join(REND, "antes"), ALTO, cara=CARA)
    print("RENDER antes")

baja = alta.copy(); baja.data = alta.data.copy(); baja.name = "nix_baja"
bpy.context.scene.collection.objects.link(baja)
md = baja.modifiers.new("reducir", 'DECIMATE')
md.decimate_type = 'COLLAPSE'
md.use_collapse_triangulate = True
if FACTOR > 0:
    g = baja.vertex_groups.new(name="detalle")
    for v in baja.data.vertices:
        p = v.co
        # la cara: delante del plano de las sienes, entre la barbilla y la frente; y el cuello de delante
        if 1.56 < p.z < 1.76 and p.y < nariz.y + 0.075 and abs(p.x) < 0.075:
            g.add([v.index], float(os.environ.get("NIX_PESO_CARA", "0.15")), 'REPLACE')
        else:
            g.add([v.index], 1.0, 'REPLACE')
    md.vertex_group = "detalle"
    md.vertex_group_factor = FACTOR
lo, hi = 0.002, 0.08
for i in range(10):
    r = (lo + hi) * 0.5
    md.ratio = r
    bpy.context.view_layer.update()
    ev = baja.evaluated_get(bpy.context.evaluated_depsgraph_get())
    t = sum(len(p.vertices) - 2 for p in ev.data.polygons)
    print("PRUEBA ratio %.5f -> %d tri" % (r, t))
    if t > OBJ:
        hi = r
    else:
        lo = r
md.ratio = lo
bpy.context.view_layer.objects.active = baja
for o in bpy.context.selected_objects:
    o.select_set(False)
baja.select_set(True)
bpy.ops.object.modifier_apply(modifier="reducir")
print("BAJA tri", C.tris(baja), "verts", len(baja.data.vertices))
bm = bmesh.new(); bm.from_mesh(baja.data)
print("BAJA bordes abiertos", sum(1 for e in bm.edges if len(e.link_faces) == 1),
      "no variedad", sum(1 for e in bm.edges if len(e.link_faces) > 2))
cara_tri = sum(1 for f in bm.faces if 1.56 < f.calc_center_median().z < 1.76 and f.calc_center_median().y < nariz.y + 0.075
               and abs(f.calc_center_median().x) < 0.075)
print("BAJA tri en la cara", cara_tri)
bm.free()
for p in baja.data.polygons:
    p.use_smooth = True

alta.hide_render = True
C.render_vistas(os.path.join(REND, "reducida_tex_original"), ALTO, cara=CARA)
alta.hide_render = False
bpy.ops.wm.save_as_mainfile(filepath=BLEND)
print("FIN", BLEND)
