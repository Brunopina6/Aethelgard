# Arreglo de Nix 14/11 (p10_*.py): utilidades de cámara, luz y normalización IGUALES a la revisión visual del 14/11.
import bpy, math, os
import numpy as np
from mathutils import Vector

ALTO = 1.9


def mallas():
    return [o for o in bpy.context.scene.objects if o.type == 'MESH']


def caja(objs):
    dg = bpy.context.evaluated_depsgraph_get()
    mn = Vector((1e9, 1e9, 1e9)); mx = Vector((-1e9, -1e9, -1e9))
    for o in objs:
        ev = o.evaluated_get(dg)
        m = ev.to_mesh()
        for v in m.vertices:
            p = ev.matrix_world @ v.co
            mn = Vector((min(mn.x, p.x), min(mn.y, p.y), min(mn.z, p.z)))
            mx = Vector((max(mx.x, p.x), max(mx.y, p.y), max(mx.z, p.z)))
        ev.to_mesh_clear()
    return mn, mx


def normalizar(objs=None):
    objs = objs or mallas()
    mn, mx = caja(objs)
    s = ALTO / (mx.z - mn.z)
    raices = [o for o in bpy.context.scene.objects if o.parent is None]
    piv = Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z))
    for r in raices:
        r.location = (r.location - piv) * s
        r.scale = r.scale * s
    bpy.context.view_layer.update()
    return caja(objs)


def luz_y_mundo():
    sc = bpy.context.scene
    w = bpy.data.worlds.new("mundo"); sc.world = w; w.use_nodes = True
    bg = w.node_tree.nodes.get('Background')
    bg.inputs['Color'].default_value = (0.62, 0.62, 0.64, 1)
    bg.inputs['Strength'].default_value = 0.9
    for nombre, energia, rot in [("clave", 3.0, (math.radians(50), 0, math.radians(-35))),
                                 ("relleno", 1.0, (math.radians(60), 0, math.radians(140)))]:
        ld = bpy.data.lights.new(nombre, 'SUN'); ld.energy = energia; ld.angle = math.radians(3)
        s = bpy.data.objects.new(nombre, ld); sc.collection.objects.link(s); s.rotation_euler = rot
    sc.render.engine = 'BLENDER_EEVEE'
    sc.view_settings.view_transform = 'Standard'
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGB'
    try:
        sc.eevee.taa_render_samples = 32
    except Exception:
        pass


def camara(centro, yaw, pitch, escala):
    sc = bpy.context.scene
    for o in list(sc.objects):
        if o.type == 'CAMERA':
            bpy.data.objects.remove(o, do_unlink=True)
    cd = bpy.data.cameras.new("cam"); cd.type = 'ORTHO'; cd.ortho_scale = escala
    cam = bpy.data.objects.new("cam", cd); sc.collection.objects.link(cam); sc.camera = cam
    d = Vector((math.sin(math.radians(yaw)) * math.cos(math.radians(pitch)),
                -math.cos(math.radians(yaw)) * math.cos(math.radians(pitch)),
                math.sin(math.radians(pitch))))
    cam.location = centro + d * 8
    cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
    cd.clip_start = 0.1; cd.clip_end = 30


def render(ruta, res_x, res_y):
    sc = bpy.context.scene
    sc.render.resolution_x = res_x; sc.render.resolution_y = res_y; sc.render.resolution_percentage = 100
    sc.render.filepath = ruta
    bpy.ops.render.render(write_still=True)


def centro_cara(objs, mx):
    dg = bpy.context.evaluated_depsgraph_get()
    z0 = mx.z - 0.20; z1 = mx.z - 0.08
    ymin = 1e9
    for o in objs:
        ev = o.evaluated_get(dg); m = ev.to_mesh()
        for v in m.vertices:
            p = ev.matrix_world @ v.co
            if z0 < p.z < z1 and abs(p.x) < 0.06:
                ymin = min(ymin, p.y)
        ev.to_mesh_clear()
    return Vector((0, ymin + 0.08, mx.z - 0.25))


CARAS = [("cara", 0), ("cara_34", 35), ("cara_perfil", 90)]


def caras(prefijo, cc, salida, vistas=CARAS):
    for nombre, yaw in vistas:
        camara(cc, yaw, 0, 0.40)
        render(os.path.join(salida, "%s_%s.png" % (prefijo, nombre)), 700, 700)


def leer_img(ruta):
    im = bpy.data.images.load(ruta, check_existing=False)
    im.colorspace_settings.name = 'Non-Color'
    w, h = im.size
    a = np.array(im.pixels[:], np.float32).reshape(h, w, im.channels)
    bpy.data.images.remove(im)
    if a.shape[2] == 3:
        a = np.concatenate([a, np.ones((h, w, 1), np.float32)], 2)
    return a


def guardar_img(arr, ruta):
    h, w = arr.shape[:2]
    rgba = np.ones((h, w, 4), np.float32)
    rgba[..., :arr.shape[2] if arr.ndim == 3 else 1] = np.clip(arr if arr.ndim == 3 else arr[..., None], 0, 1)[..., :4]
    im = bpy.data.images.new("tmp_guardar", w, h, alpha=True)
    im.colorspace_settings.name = 'Non-Color'
    im.pixels.foreach_set(rgba.ravel())
    im.filepath_raw = ruta
    im.file_format = 'PNG'
    im.save()
    bpy.data.images.remove(im)
