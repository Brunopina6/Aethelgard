# Nix piloto FBX, paso 2: rehorneado de texturas de la malla alta a la reducida (mismas UV de Meshy, conservadas por el
# colapso). Corrige el deslizamiento de la textura en triángulos grandes (cuello, costuras del mono) y pasa a la malla
# baja el relieve de la alta (su geometría y su mapa normal).
#   blender -b --factory-startup -P p2_hornear.py -- <blend paso 1> <carpeta texturas> <carpeta render> <blend salida> [res]
import sys, os, bpy
import numpy as np
from mathutils import Vector
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nix_comun as C

argv = sys.argv[sys.argv.index("--") + 1:]
BLEND1, TEX, REND, BLEND2 = argv[:4]
RES = int(argv[4]) if len(argv) > 4 else 2048
os.makedirs(TEX, exist_ok=True); os.makedirs(REND, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=BLEND1)
alta = bpy.data.objects["nix_alta"]; baja = bpy.data.objects["nix_baja"]
alta.hide_render = False; alta.hide_set(False)

# el metal del original: ¿es uniforme?
for im in bpy.data.images:
    if "metallic" in im.name.lower():
        a = np.array(im.pixels[:], dtype=np.float32).reshape(-1, 4)[:, 0]
        print("METAL min %.3f max %.3f media %.3f" % (a.min(), a.max(), a.mean()))

sc = bpy.context.scene
sc.render.engine = 'CYCLES'
try:
    prefs = bpy.context.preferences.addons['cycles'].preferences
    prefs.compute_device_type = 'OPTIX'
    prefs.get_devices()
    for d in prefs.devices:
        d.use = True
    sc.cycles.device = 'GPU'
    print("CYCLES GPU", [d.name for d in prefs.devices])
except Exception as e:
    print("CYCLES CPU", e)
sc.cycles.samples = 4
bk = sc.render.bake
bk.use_selected_to_active = True
bk.use_cage = False
bk.cage_extrusion = float(os.environ.get("NIX_EXTRUSION", "0.008"))
bk.max_ray_distance = float(os.environ.get("NIX_RAYO", "0.03"))
bk.margin = 8

# material nuevo de la baja con tres imágenes de destino
mat = bpy.data.materials.new("nix_cuerpo")
mat.use_nodes = True
nt = mat.node_tree
bs = nt.nodes["Principled BSDF"]
imgs = {}
for n, cs in [("color", "sRGB"), ("normal", "Non-Color"), ("rugosidad", "Non-Color")]:
    im = bpy.data.images.new("nix_" + n, RES, RES, alpha=False, float_buffer=False)
    im.colorspace_settings.name = cs
    imgs[n] = im
    tn = nt.nodes.new("ShaderNodeTexImage"); tn.image = im; tn.name = "t_" + n
baja.data.materials.clear(); baja.data.materials.append(mat)


def hornear(tipo, destino, **kw):
    for n in nt.nodes:
        n.select = False
    nodo = nt.nodes["t_" + destino]
    nodo.select = True
    nt.nodes.active = nodo
    for o in bpy.context.selected_objects:
        o.select_set(False)
    alta.select_set(True); baja.select_set(True)
    bpy.context.view_layer.objects.active = baja
    bpy.ops.object.bake(type=tipo, **kw)
    ruta = os.path.join(TEX, "nix_%s_%d.png" % (destino, RES))
    imgs[destino].filepath_raw = ruta
    imgs[destino].file_format = 'PNG'
    imgs[destino].save()
    print("HORNEADO", tipo, ruta)


hornear('DIFFUSE', "color", pass_filter={'COLOR'})
hornear('NORMAL', "normal", normal_space='TANGENT')
hornear('ROUGHNESS', "rugosidad")

# conectar el material para ver el resultado
nt.links.new(nt.nodes["t_color"].outputs["Color"], bs.inputs["Base Color"])
nt.links.new(nt.nodes["t_rugosidad"].outputs["Color"], bs.inputs["Roughness"])
nm = nt.nodes.new("ShaderNodeNormalMap")
nt.links.new(nt.nodes["t_normal"].outputs["Color"], nm.inputs["Color"])
nt.links.new(nm.outputs["Normal"], bs.inputs["Normal"])
bs.inputs["Metallic"].default_value = 0.0

alta.hide_render = True
sc.render.engine = 'BLENDER_EEVEE'
franja = [v.co for v in baja.data.vertices if 1.60 < v.co.z < 1.72 and abs(v.co.x) < 0.03]
nariz = min(franja, key=lambda p: p.y)
C.render_vistas(os.path.join(REND, "horneada_%d" % RES), 1.9, cara=Vector((0, nariz.y, nariz.z + 0.02)))
bpy.ops.wm.save_as_mainfile(filepath=BLEND2)
print("FIN", BLEND2)
