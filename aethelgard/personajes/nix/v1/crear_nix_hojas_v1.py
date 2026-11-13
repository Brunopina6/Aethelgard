# Nix (V12): hojas de comprobación con Blender (vistas del modelo, lámina junto a la referencia del usuario, Nix al
# lado de Kael, Lya y Garon a la escala del combate, y hojas de contacto de los clips). Lo usa crear_nix.py.
# Cámara ortográfica y luz de los retratos (dialogos/retratos/fuentes_blender/escena.py), como los héroes v2 y v3.
import os, sys, math
import bpy
from mathutils import Vector, Matrix
import escena as E
import imgutil as U
import numpy as np

# Escala del combate (combate.gd, MODELOS): cada modelo se normaliza a 1,7 m por sus huesos (maga_3d.gd _medidas:
# de la punta del pie a la cabeza ×1,03) y luego se multiplica por «esc».
ESC_COMBATE = {"Kael": 0.67, "Lya": 0.6, "Garon": 0.67}


def material_vertice(obs):
    """Borrador: el color por vértice (sRGB) a un material de Blender."""
    mb = bpy.data.materials.get("borrador") or bpy.data.materials.new("borrador")
    mb.use_nodes = True
    nt = mb.node_tree
    bs = nt.nodes["Principled BSDF"]
    if not any(n.type == 'VERTEX_COLOR' for n in nt.nodes):
        ca = nt.nodes.new("ShaderNodeVertexColor")
        ca.layer_name = "Col"
        ga = nt.nodes.new("ShaderNodeGamma")
        ga.inputs["Gamma"].default_value = 2.2
        nt.links.new(ca.outputs["Color"], ga.inputs["Color"])
        nt.links.new(ga.outputs["Color"], bs.inputs["Base Color"])
    bs.inputs["Roughness"].default_value = 0.7
    for o in obs:
        o.data.materials.clear()
        o.data.materials.append(mb)


def altura_huesos(arm):
    mw = arm.matrix_world
    bajo = min((mw @ b.head_local).z for b in arm.data.bones if "Toe" in b.name)
    alto = max((mw @ b.head_local).z for b in arm.data.bones if "HeadTop" in b.name or b.name.endswith("Head"))
    return (alto - bajo) * 1.03, bajo


def _limpiar_camaras():
    for o in list(bpy.data.objects):
        if o.type in ('LIGHT', 'CAMERA'):
            bpy.data.objects.remove(o, do_unlink=True)


def _render(centro, yaw, pitch, escala, ruta, res=(560, 560)):
    _limpiar_camaras()
    sc = E.config_render(*res)
    try:
        sc.eevee.taa_render_samples = 16
    except Exception:
        pass
    cam = E.camara(centro, yaw, pitch, escala)
    E.luces(cam)
    E.render(ruta)
    return ruta


def hoja(rutas, salida, columnas, fondo=0.86):
    ims = [U.cargar(r) for r in rutas]
    h = max(i.shape[0] for i in ims)
    w = max(i.shape[1] for i in ims)
    filas = (len(ims) + columnas - 1) // columnas
    lz = np.ones((filas * h, columnas * w, 4), dtype=np.float32)
    lz[:, :, :3] = fondo
    for i, im in enumerate(ims):
        y, x = (i // columnas) * h, (i % columnas) * w
        U.pegar(lz, im, x, y)
    lz[:, :, 3] = 1.0
    U.guardar(lz, salida)


def vistas_modelo(arm, obs, evid, nombre, pose=None):
    """Frente, tres cuartos, perfil, espalda y primer plano de la cara (en reposo o en la pose dada)."""
    if pose is not None:
        pose()
    bpy.context.view_layer.update()
    alto, suelo = altura_huesos(arm)
    deps = bpy.context.evaluated_depsgraph_get()
    zs = []
    for o in obs:
        oe = o.evaluated_get(deps)
        zs += [(oe.matrix_world @ Vector(c)).z for c in oe.bound_box]
    top = max(zs)
    centro = Vector((0.0, -0.05, (top + 0.0) * 0.5))
    rutas = []
    for yaw in (0, 35, 90, 180):
        rutas.append(_render(centro, yaw, 4, top * 1.12, os.path.join(evid, "tmp_v_%d.png" % yaw)))
    cab = arm.matrix_world @ arm.data.bones["mixamorig:Head"].head_local
    rutas.append(_render(cab + Vector((0, 0, 0.16)), 10, 6, 0.62, os.path.join(evid, "tmp_v_cara.png")))
    rutas.append(_render(cab + Vector((0, 0, 0.16)), 40, 6, 0.62, os.path.join(evid, "tmp_v_cara2.png")))
    hoja(rutas, os.path.join(evid, nombre + ".png"), 6)
    for r in rutas:
        os.remove(r)


def importar_heroe(ruta_glb, nombre, clip="reposo", t=1.0):
    """Importa un GLB de héroe v2 y lo pone en un clip. Devuelve (armadura, mallas)."""
    antes = set(bpy.data.objects)
    acts0 = set(bpy.data.actions)
    bpy.ops.import_scene.gltf(filepath=ruta_glb)
    nuevos = [o for o in bpy.data.objects if o not in antes]
    a = [o for o in nuevos if o.type == 'ARMATURE'][0]
    mallas = [o for o in nuevos if o.type == 'MESH']
    acts = [x for x in bpy.data.actions if x not in acts0]
    print("ACCIONES", nombre, [x.name for x in acts][:30])
    act = None
    for x in acts:
        if x.name == clip or x.name.startswith(clip + "_") or x.name.split("|")[-1] == clip:
            act = x
    if act is not None:
        if a.animation_data is None:
            a.animation_data_create()
        a.animation_data.action = act
        try:
            a.animation_data.action_slot = act.slots[0]
        except Exception:
            pass
    raiz = a
    while raiz.parent is not None:
        raiz = raiz.parent
    return a, mallas, raiz, nuevos


def junto_al_grupo(arm, obs, raiz_aet, evid, nombre, esc_nix, pose=None):
    """Nix al lado de Kael, Lya y Garon (v2, en reposo) a la escala del combate; de frente y en tres cuartos."""
    if pose is not None:
        pose()
    sc = bpy.context.scene
    sc.frame_set(30)
    # lo que traigan los GLB de los demás (acciones, mallas, materiales, imágenes) se borra al acabar: no puede
    # acabar en el GLB de Nix
    antes = {k: set(getattr(bpy.data, k)) for k in ("actions", "meshes", "materials", "images", "armatures")}
    grupo = []
    x = -1.5
    for heroe, sub in (("Kael", "kael/kael_v2.glb"), ("Lya", "lya/lya_v2.glb"), ("Garon", "garon/garon_v2.glb")):
        ruta = os.path.join(raiz_aet, "personajes", "heroes_v2", sub)
        a, mallas, raiz, nuevos = importar_heroe(ruta, heroe)
        bpy.context.view_layer.update()
        h, suelo = altura_huesos(a)
        k = 1.7 * ESC_COMBATE[heroe] / h
        raiz.scale = raiz.scale * k
        raiz.location = Vector((x, 0, 0))
        grupo.append((heroe, a, mallas, raiz, nuevos))
        x += 0.75
    # Nix, a la derecha
    h, suelo = altura_huesos(arm)
    k = 1.7 * esc_nix / h
    arm.scale = (k, k, k)
    arm.location = Vector((x, 0, -suelo * k))
    bpy.context.view_layer.update()
    sc.frame_set(30)
    rutas = []
    centro = Vector((-0.375, 0, 0.62))
    for yaw in (0, 30):
        rutas.append(_render(centro, yaw, 4, 3.6, os.path.join(evid, "tmp_g_%d.png" % yaw), res=(1280, 600)))
    hoja(rutas, os.path.join(evid, nombre + ".png"), 1)
    for r in rutas:
        os.remove(r)
    # deshacer: quitar a los demás y devolver a Nix a su sitio
    for heroe, a, mallas, raiz, nuevos in grupo:
        for o in nuevos:
            if o.name in bpy.data.objects:
                bpy.data.objects.remove(o, do_unlink=True)
    for k, viejos in antes.items():
        col = getattr(bpy.data, k)
        for x in [x for x in col if x not in viejos]:
            col.remove(x)
    arm.scale = (1, 1, 1)
    arm.location = Vector((0, 0, 0))
    bpy.context.view_layer.update()


def lamina_referencia(ruta_ref_png, ruta_vistas, salida):
    """La referencia del usuario arriba y las vistas de Nix (frente, perfil, espalda) debajo, a la misma altura."""
    ref = U.cargar(ruta_ref_png)
    vis = U.cargar(ruta_vistas)
    w = max(ref.shape[1], vis.shape[1])
    ref2 = U.reescalar(ref, w, int(ref.shape[0] * w / ref.shape[1]))
    vis2 = U.reescalar(vis, w, int(vis.shape[0] * w / vis.shape[1]))
    lz = np.ones((ref2.shape[0] + vis2.shape[0], w, 4), dtype=np.float32)
    lz[:, :, :3] = 0.86
    U.pegar(lz, ref2, 0, 0)
    U.pegar(lz, vis2, 0, ref2.shape[0])
    lz[:, :, 3] = 1.0
    U.guardar(lz, salida)


def vistas_fpe(arm, obs, evid, nombre, pose=None):
    """Frente, perfil y espalda (para la lámina junto a la referencia)."""
    if pose is not None:
        pose()
    bpy.context.view_layer.update()
    deps = bpy.context.evaluated_depsgraph_get()
    zs = []
    for o in obs:
        oe = o.evaluated_get(deps)
        zs += [(oe.matrix_world @ Vector(c)).z for c in oe.bound_box]
    top = max(zs)
    centro = Vector((0.0, -0.05, top * 0.5))
    rutas = [_render(centro, yaw, 2, top * 1.08, os.path.join(evid, "tmp_f_%d.png" % yaw), res=(640, 720))
             for yaw in (0, 90, 180)]
    hoja(rutas, os.path.join(evid, nombre + ".png"), 3)
    for r in rutas:
        os.remove(r)


def lods(arm, cuerpos, cara, evid, nombre, pose=None):
    """LOD0, LOD1 y LOD2 lado a lado (de cerca) para comparar la silueta."""
    if pose is not None:
        pose()
    rutas = []
    for i, c in enumerate(cuerpos):
        for o in cuerpos:
            o.hide_render = o is not c
        cara.hide_render = i > 0
        rutas.append(_render(Vector((0, -0.05, 0.75)), 30, 6, 1.7, os.path.join(evid, "tmp_l_%d.png" % i), res=(480, 560)))
    for o in cuerpos[1:]:
        o.hide_render = True
    cuerpos[0].hide_render = False
    cara.hide_render = False
    hoja(rutas, os.path.join(evid, nombre + ".png"), len(rutas))
    for r in rutas:
        os.remove(r)


def hojas_clips(arm, obs, clips, evid, poner_clip, n=8):
    """Una hoja de contacto por clip: n instantes, en tres cuartos (como la cámara del combate)."""
    for c in clips:
        rutas = []
        for i in range(n):
            t = c["dur"] * i / (n - 1)
            poner_clip(c["nombre"], t)
            rutas.append(_render(Vector((0, -0.1, 0.88)), 40, 10, 2.2, os.path.join(evid, "tmp_c_%d.png" % i),
                                 res=(300, 330)))
        hoja(rutas, os.path.join(evid, "clip_%s.png" % c["nombre"]), n)
        for r in rutas:
            os.remove(r)
