# Héroes v3 (V12): construye el GLB de un protagonista con GEOMETRÍA PROPIA sobre el esqueleto común de los v2.
#
#   blender -b --factory-startup -P fuente/crear_heroes_v3.py -- <Héroe> <raíz aethelgard> <carpeta de evidencias>
#           [modelo]      solo el modelo en reposo y sus vistas (para iterar el diseño), sin clips ni GLB
#           [sin_render]  sin hojas de contacto
#           [sin_glb]     sin exportar
#
# Pasos:
#   1. Importa el FBX original SOLO por su esqueleto y sus clips de captura (andar, correr…); sus mallas de Meshy se
#      BORRAN de la escena: no pasa nada de su geometría ni de sus texturas al v3. El esqueleto (nombres, jerarquía y
#      reposo) es el mismo de los v2, así que valen sus clips y los del especialista de combate.
#   2. Construye las piezas del diseño (personajes/heroes_v3/fuentes_blender/<héroe>_v3.py) en la pose en T, les da
#      pesos por distancia a sus huesos, calcula la oclusión con rayos y pasa los materiales a color por vértice; las une
#      en «cuerpo_v3» (un material, un dibujo).
#   3. La cara: atlas propio y malla «cara_v3» con formas clave de cejas (cara_v3.py).
#   4. Huesos de arma y los clips de la biblioteca común de los v2 (rig_comun.py y biblioteca_clips.py, sin tocarlos).
#   5. Exporta personajes/heroes_v3/<héroe>/<héroe>_v3.glb y <héroe>_v3_clips.json, y hojas de contacto.
import sys, os, json, math
sys.dont_write_bytecode = True
argv = sys.argv[sys.argv.index("--") + 1:]
HEROE = argv[0]
RAIZ = argv[1]
EVID = argv[2]
SOLO_MODELO = "modelo" in argv
SIN_RENDER = "sin_render" in argv
SIN_GLB = "sin_glb" in argv
V2 = os.path.join(RAIZ, "personajes", "heroes_v2", "fuentes_blender")
V3 = os.path.join(RAIZ, "personajes", "heroes_v3", "fuentes_blender")
sys.path.insert(0, V3)
sys.path.insert(1, V2)
import bpy
from mathutils import Vector, Matrix
import rig_comun as RC
import biblioteca_clips as BC
import geometria_v3 as G
import cara_v3 as CV
import detalle_v3 as DV
import importlib
DISENO = importlib.import_module(HEROE.lower() + "_v3")

FUENTES = {
    "Kael": "kael.fbx",
    "Lya": "Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx",
    "Garon": "garon.fbx",
}
ORIGINALES = {      # clips de captura que se conservan (los mismos que en los v2)
    "Kael": {"Walking": "andar", "Running": "correr", "_01a19ba8": "andar_pesado", "_01a19b86": "reposo_original",
             "Face_Punch": "golpe_original", "dying_backwards": "derribo_original", "mage_soell": "magia_original"},
    "Lya": {"Walking": "andar", "Running": "correr", "_01a19663": "reposo_original"},
    "Garon": {"|Walking|": "andar", "Running": "correr", "Thoughtful_Walk": "paseo", "Sword_Judgment": "juicio",
              "Double_Blade_Spin": "giro", "Shot_in_the_Back": "morir_original"},
}
ARMAS = {
    "Kael": [("arma_d", "sable", 1.45, 0.0)],
    "Lya": [("arma_d", "vara", 1.05, 0.0)],
    "Garon": [("arma_d", "hoja_infernal", 1.1, 0.12), ("arma_i", "hoja_infernal", 1.1, 0.12)],
}
carpeta = os.path.join(RAIZ, "personajes", "heroes_v3", HEROE.lower())
os.makedirs(carpeta, exist_ok=True)
os.makedirs(EVID, exist_ok=True)

# ------------------------------------------------------------------ 1. esqueleto y clips de captura
arm, mallas_meshy = RC.importar_fbx(os.path.join(RAIZ, FUENTES[HEROE]))
for o in mallas_meshy:
    me = o.data
    bpy.data.objects.remove(o, do_unlink=True)
    bpy.data.meshes.remove(me)
for img in list(bpy.data.images):          # sus texturas tampoco
    bpy.data.images.remove(img)
for m in list(bpy.data.materials):
    bpy.data.materials.remove(m)
sc = bpy.context.scene
sc.render.fps = BC.FPS
for act in list(bpy.data.actions):
    nuevo = None
    for pista, n in ORIGINALES[HEROE].items():
        if pista in act.name:
            nuevo = n
    if nuevo is None:
        bpy.data.actions.remove(act)
    else:
        act.name = nuevo
        act.use_fake_user = True
if arm.animation_data is not None:
    arm.animation_data.action = None
for pb in arm.pose.bones:
    pb.matrix_basis = Matrix.Identity(4)
bpy.context.view_layer.update()
H = G.Huesos(arm)

# textura de detalle común (si no está ya)
ruta_det = os.path.join(RAIZ, "personajes", "heroes_v3", "heroe_v3_detalle.png")
if not os.path.exists(ruta_det) or "detalle" in argv:
    DV.guardar(ruta_det)

# ------------------------------------------------------------------ 2. piezas, pesos, oclusión y color
col = bpy.data.collections.new("v3")
sc.collection.children.link(col)
paleta = DISENO.PALETA
mats = {}
for n in paleta:
    m = bpy.data.materials.new("pal_" + n)
    mats[n] = m
piezas = DISENO.construir(H)
obs = [G.a_objeto(pz, col, mats) for pz in piezas]
for ob in obs:
    G.pesar(ob, H)
print("PIEZAS", len(obs), sum(len(o.data.polygons) for o in obs), "caras")
ao = G.oclusion(obs, rayos=int(getattr(DISENO, "RAYOS_AO", 24)))
for ob in obs:
    G.colorear(ob, paleta, ao[ob.name])
# Influencia chibi: la cabeza (y lo que va en ella) se agranda desde la base del cráneo, sin tocar el esqueleto
# (los colores, como el rubor, ya están puestos; la cara se proyecta después, con sus medidas escaladas igual).
ESC = float(getattr(DISENO, "ESCALA_CABEZA", 1.0))
CARA_D = getattr(DISENO, "CARA", None)
if ESC != 1.0:
    import copy
    piv = H.c("Head")
    for ob in obs:
        if any(ob.name.endswith(s) for s in ("_cabeza", "_pelo", "_flores", "_visera", "_penacho")):
            for v in ob.data.vertices:
                v.co = piv + (v.co - piv) * ESC
    if CARA_D:
        CARA_D = copy.deepcopy(CARA_D)
        for k in ("ojo", "boca", "ceja", "marca"):
            d = CARA_D.get(k)
            if d is None:
                continue
            if "x" in d:
                d["x"] *= ESC
            d["z"] = piv.z + (d["z"] - piv.z) * ESC
            for m in ("ancho", "alto", "largo", "grueso"):
                if m in d:
                    d[m] *= ESC
    print("ESCALA_CABEZA", ESC)
cabeza = [o for o in obs if o.name.endswith("_cabeza")][0]
if CARA_D and CARA_D.get("sobre"):
    cabeza = [o for o in obs if o.name == CARA_D["sobre"]][0]      # Garon: la mirada va en la visera

# la cara se proyecta sobre la cabeza antes de unir
cara = None
if CARA_D:
    img, _ = CV.atlas(CARA_D, os.path.join(EVID, "%s_v3_cara_atlas.png" % HEROE.lower()))
    cara = CV.crear(CARA_D, cabeza, arm)
    mc = bpy.data.materials.new("v3_cara")
    mc.use_nodes = True
    nt = mc.node_tree
    bs = nt.nodes["Principled BSDF"]
    ti = nt.nodes.new("ShaderNodeTexImage")
    ti.image = img
    ti.interpolation = 'Linear'
    nt.links.new(ti.outputs["Color"], bs.inputs["Base Color"])
    nt.links.new(ti.outputs["Alpha"], bs.inputs["Alpha"])
    bs.inputs["Roughness"].default_value = 0.8
    try:
        mc.surface_render_method = 'BLENDED'
    except Exception:
        mc.blend_method = 'BLEND'
    cara.data.materials.append(mc)
    cara.parent = arm
    cara.matrix_parent_inverse = arm.matrix_world.inverted()     # se construyó en coordenadas del mundo
    g = cara.vertex_groups.new(name=G.P + "Head")
    g.add(list(range(len(cara.data.vertices))), 1.0, 'REPLACE')
    md = cara.modifiers.new("Armature", 'ARMATURE')
    md.object = arm

# unir el cuerpo en una malla con un material (el color va por vértice)
for o in bpy.context.selected_objects:
    o.select_set(False)
for o in obs:
    o.select_set(True)
bpy.context.view_layer.objects.active = obs[0]
bpy.ops.object.join()
cuerpo = bpy.context.view_layer.objects.active
cuerpo.name = "cuerpo_v3"
cuerpo.data.name = "cuerpo_v3"
cuerpo.data.materials.clear()
mb = bpy.data.materials.new("v3_cuerpo")
mb.use_nodes = True
nt = mb.node_tree
bs = nt.nodes["Principled BSDF"]
ca = nt.nodes.new("ShaderNodeVertexColor")
ca.layer_name = "Col"
ga = nt.nodes.new("ShaderNodeGamma")            # el color va en sRGB (como lo lee el juego): a lineal para Blender
ga.inputs["Gamma"].default_value = 2.2
nt.links.new(ca.outputs["Color"], ga.inputs["Color"])
nt.links.new(ga.outputs["Color"], bs.inputs["Base Color"])
bs.inputs["Roughness"].default_value = 0.75
cuerpo.data.materials.append(mb)
for p in cuerpo.data.polygons:
    p.material_index = 0
cuerpo.parent = arm
cuerpo.matrix_parent_inverse = arm.matrix_world.inverted()
md = cuerpo.modifiers.new("Armature", 'ARMATURE')
md.object = arm
# un poco de ángulo para que las aristas duras de las gemas y hebillas no se suavicen
print("CUERPO", len(cuerpo.data.vertices), "vértices", sum(len(p.vertices) - 2 for p in cuerpo.data.polygons),
      "triángulos")
if cara is not None:
    print("CARA", len(cara.data.vertices), "vértices", sum(len(p.vertices) - 2 for p in cara.data.polygons),
          "triángulos")

# ------------------------------------------------------------------ vistas del modelo (iterar el diseño)
def vistas(sufijo, expr=None):
    import render_comun as RR
    sys.path.insert(0, os.path.join(RAIZ, "dialogos", "retratos", "fuentes_blender"))
    import escena as E
    import imgutil as U
    rig0 = RC.Rig(arm)
    RR.preparar(560)
    rutas = []
    for yaw, pitch, esc in ((0, 4, 1.25), (35, 6, 1.25), (90, 4, 1.25), (180, 4, 1.25)):
        for o in list(bpy.data.objects):
            if o.type in ('LIGHT', 'CAMERA'):
                bpy.data.objects.remove(o, do_unlink=True)
        cam = RR.camara_vista(rig0, yaw, pitch, esc)
        E.luces(cam)
        r = os.path.join(EVID, "tmp_v_%d.png" % yaw)
        E.render(r)
        rutas.append(r)
    # primer plano de la cara
    for o in list(bpy.data.objects):
        if o.type in ('LIGHT', 'CAMERA'):
            bpy.data.objects.remove(o, do_unlink=True)
    cam = E.camara(Vector((0.01, -0.02, 1.33)), 20, 4, 0.55)
    E.luces(cam)
    r = os.path.join(EVID, "tmp_v_cara.png")
    E.render(r)
    rutas.append(r)
    RR.hoja(rutas, os.path.join(EVID, "%s_v3_%s.png" % (HEROE.lower(), sufijo)), 5)
    for r in rutas:
        os.remove(r)


if SOLO_MODELO:
    vistas("modelo")
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(EVID, "%s_v3_modelo.blend" % HEROE.lower()))
    print("MODELO_OK")
    sys.exit(0)

# ------------------------------------------------------------------ 4. huesos de arma y clips
for hueso, *_ in ARMAS[HEROE]:
    RC.crear_hueso_arma(arm, "Right" if hueso == "arma_d" else "Left", hueso)
rig = RC.Rig(arm)
print("HEROE", HEROE, "altura %.3f" % rig.altura)
info = {}
clips = BC.clips_de(HEROE)
if arm.animation_data is None:
    arm.animation_data_create()
for c in clips:
    act = bpy.data.actions.new(c["nombre"])
    act.use_fake_user = True
    arm.animation_data.action = act
    previo = {}
    for t, d in c["claves"]:
        rig.aplicar(d)
        for pb in rig.pb:
            q = pb.rotation_quaternion.copy()
            if pb.name in previo and q.dot(previo[pb.name]) < 0:
                pb.rotation_quaternion = -q
            previo[pb.name] = pb.rotation_quaternion.copy()
        rig.clave(t * BC.FPS)
    info[c["nombre"]] = {"duracion": round(c["dur"], 4), "bucle": c["bucle"],
                         "eventos": {k: round(v, 4) for k, v in c["eventos"].items()}}
arm.animation_data.action = None
rig.reset()
for act in bpy.data.actions:
    if act.name not in info:
        f0, f1 = act.frame_range
        info[act.name] = {"duracion": round((f1 - f0) / BC.FPS, 4), "bucle": act.name in (
            "andar", "correr", "andar_pesado", "reposo_original", "paseo"), "eventos": {}, "captura": True}
print("CLIPS", len(info))

# ------------------------------------------------------------------ armas para los renders (no van en el GLB)
armas_obj = []
for hueso, modelo, largo, agarre in ARMAS[HEROE]:
    antes = set(bpy.data.objects)
    bpy.ops.wm.obj_import(filepath=os.path.join(RAIZ, modelo + ".obj"), forward_axis='Y', up_axis='Z')
    for o in [o for o in bpy.data.objects if o not in antes]:
        tex = os.path.join(RAIZ, modelo + "_color.jpg")
        if os.path.exists(tex):
            mat = bpy.data.materials.new(modelo + "_mat"); mat.use_nodes = True
            n2 = mat.node_tree; b2 = n2.nodes["Principled BSDF"]
            ti = n2.nodes.new("ShaderNodeTexImage"); ti.image = bpy.data.images.load(tex)
            n2.links.new(ti.outputs["Color"], b2.inputs["Base Color"])
            o.data.materials.clear(); o.data.materials.append(mat)
        o.parent = arm; o.parent_type = 'BONE'; o.parent_bone = hueso
        L = arm.data.bones[hueso].length
        e = largo * rig.altura / 1.65
        o.matrix_parent_inverse = Matrix.Translation((0, -L, 0))
        o.matrix_basis = Matrix.Translation((0, -agarre * e, 0)) @ Matrix.Diagonal((e, e, e, 1))
        armas_obj.append(o)

if not SIN_RENDER:
    import render_comun as RR
    sys.path.insert(0, os.path.join(RAIZ, "dialogos", "retratos", "fuentes_blender"))
    import escena as E
    RR.preparar(300)
    rig_cam = RR.camara_vista(rig, 40, 12)
    for c in clips:
        act = bpy.data.actions[c["nombre"]]
        arm.animation_data.action = act
        try:
            arm.animation_data.action_slot = act.slots[0]
        except Exception:
            pass
        rutas = []
        for i in range(8):
            t = c["dur"] * i / 7
            sc.frame_set(int(round(t * BC.FPS)))
            r = os.path.join(EVID, "tmp_%s_%d.png" % (c["nombre"], i))
            E.render(r)
            rutas.append(r)
        RR.hoja(rutas, os.path.join(EVID, "%s_v3_clip_%s.png" % (HEROE.lower(), c["nombre"])), 8)
        for r in rutas:
            os.remove(r)
    arm.animation_data.action = None

# ------------------------------------------------------------------ 5. exportar
for o in armas_obj:
    bpy.data.objects.remove(o, do_unlink=True)
json.dump({"heroe": HEROE, "fps": BC.FPS, "altura_blender": round(rig.altura, 4), "version": "v3", "clips": info},
          open(os.path.join(carpeta, "%s_v3_clips.json" % HEROE.lower()), "w", encoding="utf-8"), ensure_ascii=False,
          indent=1)
if not SIN_GLB:
    for o in bpy.data.objects:
        o.select_set(o.type in ('ARMATURE', 'MESH'))
    ruta = os.path.join(carpeta, "%s_v3.glb" % HEROE.lower())
    props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
    op = dict(filepath=ruta, export_format='GLB', use_selection=True, export_animations=True,
              export_animation_mode='ACTIONS', export_force_sampling=True, export_apply=False)
    for k, v in (("export_frame_range", False), ("export_anim_slide_to_zero", True), ("export_morph", True),
                 ("export_morph_normal", False), ("export_vertex_color", 'ACTIVE'),
                 ("export_all_vertex_colors", True), ("export_active_vertex_color_when_no_material", True),
                 ("export_image_format", 'AUTO'), ("export_skins", True)):
        if k in props:
            op[k] = v
    print("OPCIONES", {k: v for k, v in op.items() if k != "filepath"})
    bpy.ops.export_scene.gltf(**op)
    print("GLB", ruta, os.path.getsize(ruta))
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(EVID, "%s_v3.blend" % HEROE.lower()))
print("FIN_OK")
