# Héroes v3 (V12): hoja comparativa de los protagonistas con las MISMAS cámaras y la misma luz.
#
#   blender -b --factory-startup -P personajes/heroes_v3/fuentes_blender/hoja_comparativa.py -- <raíz aethelgard>
#           <carpeta de salida> <Héroe> [versiones: original,v2,v3]
#
# Por versión, una fila: frente, tres cuartos, perfil, silueta en negro (de frente y de perfil), el tamaño del combate
# (unos 200 px de alto, como en una captura de 1280 × 720, vista 3/4 desde arriba) y un primer plano de la cabeza.
# Luz: la de los retratos (sol cálido FFE2B0 desde arriba a la izquierda respecto a la cámara y ambiente blanco), sin
# metal (Blender no tiene el reflejo del sombreador del juego); así se comparan forma, color y lectura, no el material.
import sys, os, math
sys.dont_write_bytecode = True
import bpy
import numpy as np
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
RAIZ, SALIDA, HEROE = argv[0], argv[1], argv[2]
VERSIONES = argv[3].split(",") if len(argv) > 3 else ["original", "v2", "v3"]
sys.path.insert(0, os.path.join(RAIZ, "dialogos", "retratos", "fuentes_blender"))
import escena as E
import imgutil as U

FBX = {"Kael": "kael.fbx", "Lya": "Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx",
       "Garon": "garon.fbx"}
REPOSO_FBX = {"Kael": "_01a19b86", "Lya": "_01a19663", "Garon": "Sword_Judgment"}   # Garon no trae reposo
ALTO = 520                     # alto de cada vista de cuerpo entero
COMBATE = 200                  # alto del personaje en el combate (captura de 1280 × 720)
os.makedirs(SALIDA, exist_ok=True)


def ruta_version(v):
    if v == "original":
        return os.path.join(RAIZ, FBX[HEROE])
    return os.path.join(RAIZ, "personajes", "heroes_%s" % v, HEROE.lower(), "%s_%s.glb" % (HEROE.lower(), v))


def _materiales_v3(mallas):
    """Los v3 llevan el color por vértice en sRGB (el juego lo pasa a lineal) y la cara usa solo el atlas (su color por
    vértice dice qué parte es, no es color). Así se ven en Blender como en el juego, sin la luz pintada ni el contorno
    (son del sombreador de Godot)."""
    for o in mallas:
        if o.name.startswith("cuerpo_v3"):
            m = bpy.data.materials.new("v3_hoja"); m.use_nodes = True
            nt = m.node_tree; bs = nt.nodes["Principled BSDF"]
            ca = nt.nodes.new("ShaderNodeVertexColor"); ca.layer_name = o.data.color_attributes[0].name
            ga = nt.nodes.new("ShaderNodeGamma"); ga.inputs["Gamma"].default_value = 2.2
            nt.links.new(ca.outputs["Color"], ga.inputs["Color"])
            nt.links.new(ga.outputs["Color"], bs.inputs["Base Color"])
            bs.inputs["Roughness"].default_value = 0.8
            o.data.materials.clear(); o.data.materials.append(m)
        elif o.name.startswith("cara_v3"):
            img = [n.image for n in o.data.materials[0].node_tree.nodes if n.type == 'TEX_IMAGE'][0]
            m = bpy.data.materials.new("v3_cara_hoja"); m.use_nodes = True
            nt = m.node_tree; bs = nt.nodes["Principled BSDF"]
            ti = nt.nodes.new("ShaderNodeTexImage"); ti.image = img
            nt.links.new(ti.outputs["Color"], bs.inputs["Base Color"])
            nt.links.new(ti.outputs["Alpha"], bs.inputs["Alpha"])
            try:
                m.surface_render_method = 'BLENDED'
            except Exception:
                pass
            o.data.materials.clear(); o.data.materials.append(m)


def cargar(v):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    r = ruta_version(v)
    if r.endswith(".fbx"):
        bpy.ops.import_scene.fbx(filepath=r)
    else:
        bpy.ops.import_scene.gltf(filepath=r)
    arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
    # solo las mallas del personaje (el importador de glTF añade una «Icosphere» para dibujar los huesos)
    mallas = [o for o in bpy.data.objects if o.type == 'MESH' and o.parent is not None]
    for o in bpy.data.objects:
        if o.type == 'MESH' and o.parent is None:
            o.hide_render = True
    for o in mallas:
        if o.name.startswith("cara_v2"):
            o.hide_render = True                  # «normal»: en el juego la malla de la cara v2 está oculta
    E.sin_metal([o for o in mallas if not o.hide_render])
    if v == "v3":
        _materiales_v3(mallas)
    # pose de reposo de cada versión
    clip = None
    if v == "original":
        p = REPOSO_FBX[HEROE]
        if p:
            clip = [a for a in bpy.data.actions if p in a.name]
    else:
        clip = [a for a in bpy.data.actions if a.name.split("|")[-1] == "reposo" or a.name == "reposo"]
    if arm.animation_data is None:
        arm.animation_data_create()
    if clip:
        act = clip[0]
        arm.animation_data.action = act
        try:
            arm.animation_data.action_slot = act.slots[0]
        except Exception:
            pass
        bpy.context.scene.frame_set(int(act.frame_range[0]))
    else:
        arm.animation_data.action = None
    bpy.context.view_layer.update()
    return arm, [o for o in mallas if not o.hide_render]


def caja(mallas):
    # con los vértices ya deformados por el esqueleto (la caja de la malla sin evaluar no vale con el GLB)
    deps = bpy.context.evaluated_depsgraph_get()
    pts = []
    for o in mallas:
        oe = o.evaluated_get(deps)
        me = oe.to_mesh()
        pts += [oe.matrix_world @ v.co for v in me.vertices]
        oe.to_mesh_clear()
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return mn, mx


def limpiar_luces():
    for o in list(bpy.data.objects):
        if o.type in ('LIGHT', 'CAMERA'):
            bpy.data.objects.remove(o, do_unlink=True)


def vista(centro, yaw, pitch, escala, w, h, ruta):
    limpiar_luces()
    sc = E.config_render(w, h)
    cam = E.camara(centro, yaw, pitch, escala)
    E.luces(cam)
    E.render(ruta)
    return U.cargar(ruta)


def fila(v):
    arm, mallas = cargar(v)
    mn, mx = caja(mallas)
    alto = mx.z - mn.z
    centro = Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z + alto / 2))
    esc = alto * 1.12
    W = int(ALTO * 0.62)
    tmp = os.path.join(SALIDA, "_tmp.png")
    ims = []
    for yaw in (0, 35, 90):
        ims.append(vista(centro, yaw, 4, esc, W, ALTO, tmp))
    for yaw in (0, 90):
        s = vista(centro, yaw, 4, esc, W, ALTO, tmp)
        sil = np.ones_like(s)
        sil[:, :, :3] = 1.0 - s[:, :, 3:4]                       # negro donde hay personaje, blanco el resto
        sil[:, :, :3] = np.clip(sil[:, :, :3], 0, 1)
        sil[:, :, 3] = 1.0
        ims.append(sil)
    # tamaño del combate: 3/4 desde arriba (la cámara de combate.gd ve a los héroes de lado y algo desde arriba)
    grande = vista(centro, 40, 14, esc, 4 * W, 4 * ALTO, tmp)
    peq = U.reescalar(grande, int(4 * W * COMBATE / (ALTO * 4 / 1.12) / 1.0) // 1 if False else int(W * COMBATE / (ALTO / 1.12)),
                      int(COMBATE * 1.12))
    # se amplía ×2 sin suavizar para verlo, y se centra en una loseta como las demás
    amp = np.repeat(np.repeat(peq, 2, axis=0), 2, axis=1)
    lz = np.zeros((ALTO, W, 4), dtype=np.float32)
    hh, ww = min(amp.shape[0], ALTO), min(amp.shape[1], W)
    y0, x0 = (ALTO - hh) // 2, (W - ww) // 2
    U.pegar(lz, amp[:hh, :ww], x0, y0)
    ims.append(lz)
    # primer plano: cabeza y hombros, 3/4
    cab = arm.matrix_world @ arm.data.bones["mixamorig:Head"].head_local
    cc = Vector((centro.x, centro.y, cab.z + alto * 0.12))
    ims.append(vista(cc, 25, 4, alto * 0.42, W, ALTO, tmp))
    os.remove(tmp)
    return ims


def componer(filas, ruta):
    W = filas[0][1][0].shape[1]
    n = len(filas[0][1])
    margen = 6
    lz = np.ones((len(filas) * (ALTO + margen) + margen, n * (W + margen) + margen, 4), dtype=np.float32)
    lz[:, :, :3] = 0.80
    for i, (v, ims) in enumerate(filas):
        for j, im in enumerate(ims):
            y, x = margen + i * (ALTO + margen), margen + j * (W + margen)
            fondo = np.ones((ALTO, W, 4), dtype=np.float32)
            fondo[:, :, :3] = 0.88 if j != 5 else 0.62          # el tamaño del combate, sobre gris medio
            U.pegar(fondo, im, 0, 0)
            lz[y:y + ALTO, x:x + W] = fondo
    lz[:, :, 3] = 1.0
    U.guardar(lz, ruta)


filas = []
for v in VERSIONES:
    if not os.path.exists(ruta_version(v)):
        print("FALTA", v, ruta_version(v))
        continue
    ims = fila(v)
    for j, nombre in enumerate(["frente", "tres_cuartos", "perfil", "silueta_frente", "silueta_perfil", "combate",
                                "primer_plano"]):
        U.guardar(ims[j], os.path.join(SALIDA, "%s_%s_%s.png" % (HEROE.lower(), v, nombre)))
    filas.append((v, ims))
    print("FILA", HEROE, v)
componer(filas, os.path.join(SALIDA, "hoja_%s_%s.png" % (HEROE.lower(), "_".join(v for v, _ in filas))))
print("HOJA_OK")
