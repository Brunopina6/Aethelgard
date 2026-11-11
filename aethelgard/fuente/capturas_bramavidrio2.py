# Capturas de comprobación de Bramavidrio v2 (fuente/crear_bramavidrio2.py): renderiza clips en varios instantes con
# luz y cámara fijas y compone una hoja (PNG) por llamada. La emisión de la vela, los ojos, la garganta, el aliento y la
# arena que aspira sigue a la escala de sus huesos (drivers del .blend), como hace bramavidrio2_3d.gd en Godot.
#
#   blender -b <bramavidrio2.blend> -P capturas_bramavidrio2.py -- <salida.png> <vista> <clip:segundo> [<clip:segundo> …]
#
# Vistas: «combate» (3/4 por delante y a su derecha: la del combate, con un muñeco de la escala de los héroes a 13 m),
# «perfil» (de lado), «cerca» (la cabeza), «alto» (desde arriba, para el surco), «lejos» (la de la exploración).
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
ANCHO, ALTO = (560, 560) if VISTA not in ("cerca",) else (560, 440)
sc.render.resolution_x, sc.render.resolution_y = ANCHO, ALTO
sc.render.resolution_percentage = 100
sc.render.image_settings.file_format = "PNG"
mundo = bpy.data.worlds.new("cielo")
sc.world = mundo
mundo.use_nodes = True
fondo = mundo.node_tree.nodes.get("Background")
fondo.inputs["Color"].default_value = (0.42, 0.55, 0.75, 1)
fondo.inputs["Strength"].default_value = 0.6
try:
    sc.view_settings.view_transform = "Standard"
except Exception:
    pass

me = bpy.data.meshes.new("suelo")
me.from_pydata([(-300, -300, 0), (300, -300, 0), (300, 300, 0), (-300, 300, 0)], [], [(0, 1, 2, 3)])
suelo = bpy.data.objects.new("suelo", me)
sc.collection.objects.link(suelo)
ms = bpy.data.materials.new("suelo_arena")
ms.use_nodes = True
ms.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.62, 0.44, 0.26, 1)
ms.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 1.0
me.materials.append(ms)


def sol(nombre, color, energia, rot):
    l = bpy.data.lights.new(nombre, "SUN")
    l.color = color
    l.energy = energia
    o = bpy.data.objects.new(nombre, l)
    o.rotation_euler = [math.radians(a) for a in rot]
    sc.collection.objects.link(o)


sol("sol", (1.0, 0.90, 0.74), 3.4, (52, 0, -40))
sol("cielo", (0.55, 0.65, 0.95), 1.0, (65, 0, 150))


def muneco(pos, alto, color):
    for (rel, tam, k) in (((0, 0, 0.72), 0.27, 1.0), ((0, 0, 0.33), 0.2, 1.7)):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, radius=tam, location=Vector(pos) + Vector(rel) * alto)
        o = bpy.context.active_object
        o.scale = (alto, alto, alto * k)
        m = bpy.data.materials.new("heroe")
        m.use_nodes = True
        m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = color
        o.data.materials.append(m)
        bpy.ops.object.shade_smooth()


if VISTA in ("combate", "lejos"):
    muneco((-1.5, -13.5, 0.0), 4.2, (0.55, 0.55, 0.6, 1))      # un héroe a la escala del combate, delante

cam_d = bpy.data.cameras.new("cam")
cam_d.type = 'ORTHO'
cam = bpy.data.objects.new("cam", cam_d)
sc.collection.objects.link(cam)
sc.camera = cam
VISTAS = {
    "combate": ((-48.0, -36.0, 12.6), (-0.5, -7.0, 7.5), 26.0),
    "perfil": ((60.0, -6.0, 7.0), (0.0, -6.5, 8.0), 28.0),
    "cerca": ((-30.0, -38.0, 12.0), (0.0, -10.0, 8.5), 10.0),
    "alto": ((12.0, -14.0, 22.0), (0.0, 8.0, 0.0), 30.0),
    "lejos": ((-26.0, -44.0, 16.0), (0.0, -6.0, 8.0), 40.0),
}
pos, mira, escala = VISTAS[VISTA]
cam.location = Vector(mira) + (Vector(pos) - Vector(mira)).normalized() * 120.0
cam.rotation_euler = (Vector(mira) - cam.location).to_track_quat('-Z', 'Y').to_euler()
cam_d.ortho_scale = escala
cam_d.clip_end = 400

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
