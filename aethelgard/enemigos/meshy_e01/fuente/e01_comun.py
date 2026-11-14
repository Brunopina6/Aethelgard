# meshy_e01 · Custodio de Porcelana: utilidades comunes de los guiones de Blender (importación, render, recuento).
# Ejes tras importar el FBX de Meshy en Blender 5.2: se comprueban en p0_inspeccionar.py (no se dan por supuestos).
import bpy, math, os, bmesh
from mathutils import Vector

FPS = 30


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


def limpiar_luces():
    for o in list(bpy.data.objects):
        if o.type in ('LIGHT', 'CAMERA'):
            bpy.data.objects.remove(o, do_unlink=True)


def escena_luz():
    sc = bpy.context.scene
    w = sc.world or bpy.data.worlds.new("mundo")
    sc.world = w
    w.use_nodes = True
    bg = w.node_tree.nodes.get('Background')
    bg.inputs['Color'].default_value = (0.42, 0.45, 0.50, 1)
    bg.inputs['Strength'].default_value = 0.9
    for nombre, energia, rot in [("clave", 3.0, (math.radians(50), 0, math.radians(-35))),
                                 ("relleno", 1.0, (math.radians(60), 0, math.radians(140)))]:
        ld = bpy.data.lights.new(nombre, 'SUN'); ld.energy = energia; ld.angle = math.radians(3)
        s = bpy.data.objects.new(nombre, ld); sc.collection.objects.link(s)
        s.rotation_euler = rot


def suelo(z=0.0, tam=6.0):
    if "suelo_ref" in bpy.data.objects:
        return bpy.data.objects["suelo_ref"]
    me = bpy.data.meshes.new("suelo_ref")
    h = tam / 2
    me.from_pydata([(-h, -h, z), (h, -h, z), (h, h, z), (-h, h, z)], [], [(0, 1, 2, 3)])
    o = bpy.data.objects.new("suelo_ref", me)
    bpy.context.scene.collection.objects.link(o)
    m = bpy.data.materials.new("suelo_ref")
    m.diffuse_color = (0.30, 0.33, 0.30, 1)
    try:
        m.use_nodes = True
        m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.30, 0.33, 0.30, 1)
    except Exception:
        pass
    me.materials.append(m)
    return o


def camara(centro, yaw, pitch, escala, frente=Vector((0, -1, 0))):
    """yaw 0: de frente (la cámara delante del personaje, que mira hacia «frente»); 90: desde su izquierda; 180: espalda."""
    sc = bpy.context.scene
    cd = bpy.data.cameras.new("cam"); cd.type = 'ORTHO'; cd.ortho_scale = escala
    cam = bpy.data.objects.new("cam", cd); sc.collection.objects.link(cam); sc.camera = cam
    base = math.atan2(frente.x, -frente.y)          # frente (0,-1,0) → 0
    a = math.radians(yaw) + base
    d = Vector((math.sin(a) * math.cos(math.radians(pitch)), -math.cos(a) * math.cos(math.radians(pitch)),
                math.sin(math.radians(pitch))))
    cam.location = centro + d * 8
    cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
    cd.clip_start = 0.1; cd.clip_end = 30
    return cam


VISTAS = [("frente", 0, 0), ("perfil", 90, 0), ("espalda", 180, 0), ("tres_cuartos", 35, 8)]


def render_vistas(prefijo, alto, vistas=None, res=800, extra_esc=1.15, centro_z=None, centro_xy=(0.0, 0.0)):
    rutas = []
    for nombre, yaw, pitch in (vistas or VISTAS):
        limpiar_luces(); config_render(res, res); escena_luz()
        cz = alto * 0.5 if centro_z is None else centro_z
        camara(Vector((centro_xy[0], centro_xy[1], cz)), yaw, pitch, alto * extra_esc)
        r = prefijo + "_" + nombre + ".png"
        bpy.context.scene.render.filepath = r
        bpy.ops.render.render(write_still=True)
        rutas.append(r)
    return rutas


def componentes(o):
    """Piezas conectadas de la malla: [(n_vertices, min, max)] (de mayor a menor)."""
    bm = bmesh.new(); bm.from_mesh(o.data)
    bm.verts.ensure_lookup_table()
    visto = set(); piezas = []
    mw = o.matrix_world
    for v in bm.verts:
        if v.index in visto:
            continue
        pila = [v]; visto.add(v.index); idx = []
        while pila:
            x = pila.pop(); idx.append(x.index)
            for e in x.link_edges:
                w = e.other_vert(x)
                if w.index not in visto:
                    visto.add(w.index); pila.append(w)
        cos = [mw @ bm.verts[i].co for i in idx]
        mn = Vector((min(c.x for c in cos), min(c.y for c in cos), min(c.z for c in cos)))
        mx = Vector((max(c.x for c in cos), max(c.y for c in cos), max(c.z for c in cos)))
        piezas.append((len(idx), mn, mx, idx))
    bm.free()
    piezas.sort(key=lambda p: -p[0])
    return piezas
