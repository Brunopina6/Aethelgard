# Capturas de comprobación de Bramavidrio: renderiza clips en varios instantes con luz y cámara fijas y compone una
# hoja (PNG) por llamada. La emisión de aletas, ocelos, garganta y aliento sigue a la escala de sus huesos (drivers del
# .blend de crear_bramavidrio.py), como hace bramavidrio_3d.gd en Godot.
#
#   blender -b <bramavidrio.blend> -P capturas_bramavidrio.py -- <salida.png> <vista> <clip:segundo> [<clip:segundo> …]
#
# Vistas: «frente» (3/4 por delante, la del combate), «perfil» (de lado), «cerca» (la cabeza), «alto» (desde arriba,
# para el surco). Columnas de la hoja: una por instante pedido.
import bpy, sys, math, os
import numpy as np
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
SALIDA, VISTA, PEDIDOS = args[0], args[1], args[2:]
sc = bpy.context.scene
arm = bpy.data.objects["Bramavidrio"]
ad = arm.animation_data
for t in ad.nla_tracks:
    t.mute = True

motores = [i.identifier for i in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
sc.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in motores else "BLENDER_EEVEE_NEXT"
ANCHO, ALTO = (520, 560) if VISTA != "cerca" else (520, 420)
sc.render.resolution_x, sc.render.resolution_y = ANCHO, ALTO
sc.render.resolution_percentage = 100
sc.render.image_settings.file_format = "PNG"
mundo = bpy.data.worlds.new("cielo")
sc.world = mundo
mundo.use_nodes = True
fondo = mundo.node_tree.nodes.get("Background")
fondo.inputs["Color"].default_value = (0.42, 0.55, 0.75, 1)         # cielo del desierto
fondo.inputs["Strength"].default_value = 0.55
try:
    sc.view_settings.view_transform = "Standard"
except Exception:
    pass

bpy.ops.mesh.primitive_plane_add(size=600, location=(0, 0, 0))
suelo = bpy.context.active_object
ms = bpy.data.materials.new("suelo_arena")
ms.use_nodes = True
ms.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.62, 0.44, 0.26, 1)
ms.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 1.0
suelo.data.materials.append(ms)
if VISTA == "alto":
    suelo.location.z = 0.0


def sol(nombre, color, energia, rot):
    l = bpy.data.lights.new(nombre, "SUN")
    l.color = color
    l.energy = energia
    o = bpy.data.objects.new(nombre, l)
    o.rotation_euler = [math.radians(a) for a in rot]
    sc.collection.objects.link(o)


sol("sol", (1.0, 0.90, 0.74), 3.2, (52, 0, -40))
sol("cielo", (0.55, 0.65, 0.95), 0.9, (65, 0, 150))

cam_d = bpy.data.cameras.new("cam")
cam_d.type = 'ORTHO'
cam = bpy.data.objects.new("cam", cam_d)
sc.collection.objects.link(cam)
sc.camera = cam
VISTAS = {
    "frente": ((17.0, -27.0, 9.5), (0.0, -4.5, 6.0), 24.0),
    "perfil": ((34.0, -5.0, 7.0), (0.0, -5.0, 7.0), 26.0),
    "cerca": ((7.5, -16.0, 9.5), (0.0, -6.5, 7.5), 9.5),
    "alto": ((12.0, -14.0, 22.0), (0.0, 8.0, 0.0), 30.0),
    "lejos": ((26.0, -44.0, 12.0), (0.0, -6.0, 8.0), 40.0),
}
pos, mira, escala = VISTAS[VISTA]
cam.location = Vector(mira) + (Vector(pos) - Vector(mira)).normalized() * 90.0
cam.rotation_euler = (Vector(mira) - cam.location).to_track_quat('-Z', 'Y').to_euler()
cam_d.ortho_scale = escala
cam_d.clip_end = 300

imagenes = []
os.makedirs(os.path.dirname(SALIDA) or ".", exist_ok=True)
for i, pedido in enumerate(PEDIDOS):
    clip, seg = pedido.split(":")
    ad.action = bpy.data.actions[clip]
    sc.frame_set(int(round(float(seg) * 30)) + 1)
    ruta = SALIDA + "_%02d.png" % i
    sc.render.filepath = ruta
    bpy.ops.render.render(write_still=True)
    imagenes.append(ruta)

hoja = None
for ruta in imagenes:
    im = bpy.data.images.load(ruta)
    w, h = im.size
    px = np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4)
    hoja = px if hoja is None else np.concatenate([hoja, px], axis=1)
    bpy.data.images.remove(im)
    os.remove(ruta)
h, w = hoja.shape[:2]
out = bpy.data.images.new("hoja", w, h, alpha=True)
out.pixels.foreach_set(hoja.ravel())
out.filepath_raw = SALIDA
out.file_format = "PNG"
out.save()
print("HOJA", SALIDA, w, h)
