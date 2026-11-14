# Nix piloto FBX: utilidades comunes de los guiones de Blender (render de comprobación, importación, recuento).
# Ejes tras importar el FBX de Meshy: el personaje mira a -Y, su izquierda es +X y arriba es +Z.
import bpy, math, os
from mathutils import Vector


def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


def importar_fbx(ruta, vaciar=True):
    if vaciar:
        bpy.ops.wm.read_factory_settings(use_empty=True)
    antes = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=ruta)
    return [o for o in bpy.data.objects if o not in antes]


def config_render(res_x, res_y, muestras=24):
    sc = bpy.context.scene
    sc.render.engine = 'BLENDER_EEVEE'
    sc.render.film_transparent = False
    sc.view_settings.view_transform = 'Standard'
    sc.view_settings.look = 'None'
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGB'
    sc.render.resolution_x = res_x
    sc.render.resolution_y = res_y
    sc.render.resolution_percentage = 100
    try:
        sc.eevee.taa_render_samples = muestras
    except Exception:
        pass
    return sc


def _limpiar():
    for o in list(bpy.data.objects):
        if o.type in ('LIGHT', 'CAMERA'):
            bpy.data.objects.remove(o, do_unlink=True)


def escena_luz():
    sc = bpy.context.scene
    w = sc.world or bpy.data.worlds.new("mundo")
    sc.world = w
    w.use_nodes = True
    bg = w.node_tree.nodes.get('Background')
    bg.inputs['Color'].default_value = (0.62, 0.62, 0.64, 1)
    bg.inputs['Strength'].default_value = 0.9
    for nombre, energia, rot in [("clave", 3.0, (math.radians(50), 0, math.radians(-35))),
                                 ("relleno", 1.0, (math.radians(60), 0, math.radians(140)))]:
        ld = bpy.data.lights.new(nombre, 'SUN'); ld.energy = energia; ld.angle = math.radians(3)
        s = bpy.data.objects.new(nombre, ld); sc.collection.objects.link(s)
        s.rotation_euler = rot


def camara(centro, yaw, pitch, escala):
    """yaw 0: de frente (la cámara en -Y mirando a +Y); 90: desde la izquierda del personaje (+X); 180: espalda."""
    sc = bpy.context.scene
    cd = bpy.data.cameras.new("cam"); cd.type = 'ORTHO'; cd.ortho_scale = escala
    cam = bpy.data.objects.new("cam", cd); sc.collection.objects.link(cam); sc.camera = cam
    d = Vector((math.sin(math.radians(yaw)) * math.cos(math.radians(pitch)),
                -math.cos(math.radians(yaw)) * math.cos(math.radians(pitch)),
                math.sin(math.radians(pitch))))
    cam.location = centro + d * 8
    cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
    cd.clip_start = 0.1; cd.clip_end = 30
    return cam


def render_vistas(prefijo, alto=1.9, centro_x=0.0, res=900, cara=None, vistas=None, extra_esc=1.12):
    """Frente, perfil (izquierda), espalda y tres cuartos de cuerpo entero; y un primer plano de la cara si se da su
    centro (Vector) en «cara». Devuelve las rutas."""
    rutas = []
    vistas = vistas or [("frente", 0, 0), ("perfil", 90, 0), ("espalda", 180, 0), ("tres_cuartos", 35, 6)]
    for nombre, yaw, pitch in vistas:
        _limpiar(); config_render(res, res); escena_luz()
        camara(Vector((centro_x, 0, alto * 0.5)), yaw, pitch, alto * extra_esc)
        r = prefijo + "_" + nombre + ".png"
        bpy.context.scene.render.filepath = r
        bpy.ops.render.render(write_still=True)
        rutas.append(r)
    if cara is not None:
        for nombre, yaw in [("cara", 0), ("cara_34", 35), ("cara_perfil", 90)]:
            _limpiar(); config_render(600, 600, 32); escena_luz()
            camara(cara, yaw, 0, 0.42)
            r = prefijo + "_" + nombre + ".png"
            bpy.context.scene.render.filepath = r
            bpy.ops.render.render(write_still=True)
            rutas.append(r)
    return rutas
