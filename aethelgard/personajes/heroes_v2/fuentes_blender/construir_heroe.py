# Héroes v2 (fase B, V12): construye el GLB de un héroe con la biblioteca común de clips.
#
#   blender -b --factory-startup -P personajes/heroes_v2/fuentes_blender/construir_heroe.py -- <héroe> <raíz aethelgard>
#           <carpeta de evidencias> [sin_render] [sin_glb]
#
# Pasos: importa el FBX ORIGINAL del juego (no se toca), renombra sus clips de captura (andar, correr…), añade los
# huesos de arma, crea los clips de biblioteca_clips.py, la cara expresiva (cara_expresiva.py, si el héroe tiene cara),
# exporta personajes/heroes_v2/<héroe>/<héroe>_v2.glb (texturas WebP) y <héroe>_v2_clips.json (duraciones, bucles e
# instantes), y renderiza hojas de contacto de cada clip en la carpeta de evidencias.
import sys, os, json, math
sys.dont_write_bytecode = True                  # sin __pycache__ en el proyecto
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
from mathutils import Vector, Matrix
import rig_comun as RC
import biblioteca_clips as BC

argv = sys.argv[sys.argv.index("--") + 1:]
HEROE = argv[0]
RAIZ = argv[1]
EVID = argv[2]
SIN_RENDER = "sin_render" in argv
SIN_GLB = "sin_glb" in argv

FUENTES = {
    "Kael": "kael.fbx",
    "Lya": "Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx",
    "Garon": "garon.fbx",
}
# clips de captura de Meshy que se conservan, con su nombre del contrato
ORIGINALES = {
    "Kael": {"Walking": "andar", "Running": "correr", "_01a19ba8": "andar_pesado", "_01a19b86": "reposo_original",
             "Face_Punch": "golpe_original", "dying_backwards": "derribo_original", "mage_soell": "magia_original"},
    "Lya": {"Walking": "andar", "Running": "correr", "_01a19663": "reposo_original"},
    "Garon": {"|Walking|": "andar", "Running": "correr", "Thoughtful_Walk": "paseo", "Sword_Judgment": "juicio",
              "Double_Blade_Spin": "giro", "Shot_in_the_Back": "morir_original"},
}
ARMAS = {   # (modelo, largo en m para 1,65 m de esqueleto, agarre 0..1 desde la empuñadura) — como inventario.gd
    "Kael": [("arma_d", "sable", 1.45, 0.0)],
    "Lya": [("arma_d", "vara", 1.05, 0.0)],
    "Garon": [("arma_d", "hoja_infernal", 1.1, 0.12), ("arma_i", "hoja_infernal", 1.1, 0.12)],
}

carpeta = os.path.join(RAIZ, "personajes", "heroes_v2", HEROE.lower())
os.makedirs(carpeta, exist_ok=True)
os.makedirs(EVID, exist_ok=True)

arm, mallas = RC.importar_fbx(os.path.join(RAIZ, FUENTES[HEROE]))
sc = bpy.context.scene
sc.render.fps = BC.FPS

# 1. clips originales: nombre del contrato; los que no se conservan, fuera
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

# 2. huesos de arma
for hueso, *_ in ARMAS[HEROE]:
    RC.crear_hueso_arma(arm, "Right" if hueso == "arma_d" else "Left", hueso)

rig = RC.Rig(arm)
print("HEROE", HEROE, "altura %.3f" % rig.altura, "brazo %.3f" % rig.largo_brazo["Right"])

# 3. clips de la biblioteca
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
        for pb in rig.pb:                        # continuidad de los cuaterniones (sin vueltas largas)
            q = pb.rotation_quaternion.copy()
            if pb.name in previo and q.dot(previo[pb.name]) < 0:
                pb.rotation_quaternion = -q
            previo[pb.name] = pb.rotation_quaternion.copy()
        rig.clave(t * BC.FPS)
    info[c["nombre"]] = {"duracion": round(c["dur"], 4), "bucle": c["bucle"],
                         "eventos": {k: round(v, 4) for k, v in c["eventos"].items()}}
    print("CLIP", c["nombre"], "%.2f s" % c["dur"], len(c["claves"]), "claves", c["eventos"])
arm.animation_data.action = None
rig.reset()

# los originales también al json (duración real)
for act in bpy.data.actions:
    if act.name not in info:
        f0, f1 = act.frame_range
        info[act.name] = {"duracion": round((f1 - f0) / BC.FPS, 4), "bucle": act.name in ("andar", "correr", "andar_pesado",
                          "reposo_original", "paseo"), "eventos": {}, "captura": True}

# 4. cara expresiva (Kael y Lya: Garon lleva yelmo cerrado)
cara = None
try:
    import cara_expresiva as CE
    if CE.TIENE_CARA.get(HEROE, False):
        cara = CE.crear(HEROE, arm, mallas[0], rig, carpeta, EVID)
except ImportError:
    pass

# 5. armas para los renders de comprobación (no van en el GLB: el juego pone la del inventario)
armas_obj = []
for hueso, modelo, largo, agarre in ARMAS[HEROE]:
    ruta = os.path.join(RAIZ, modelo + ".obj")
    antes = set(bpy.data.objects)
    bpy.ops.wm.obj_import(filepath=ruta, forward_axis='Y', up_axis='Z')
    nuevos = [o for o in bpy.data.objects if o not in antes]
    for o in nuevos:
        tex = os.path.join(RAIZ, modelo + "_color.jpg")
        if os.path.exists(tex):
            mat = bpy.data.materials.new(modelo + "_mat"); mat.use_nodes = True
            nt = mat.node_tree; bs = nt.nodes["Principled BSDF"]
            ti = nt.nodes.new("ShaderNodeTexImage"); ti.image = bpy.data.images.load(tex)
            nt.links.new(ti.outputs["Color"], bs.inputs["Base Color"])
            bs.inputs["Metallic"].default_value = 0.3; bs.inputs["Roughness"].default_value = 0.35
            o.data.materials.clear(); o.data.materials.append(mat)
        o.parent = arm
        o.parent_type = 'BONE'
        o.parent_bone = hueso
        L = arm.data.bones[hueso].length
        e = largo * rig.altura / 1.65
        o.matrix_parent_inverse = Matrix.Translation((0, -L, 0))
        o.matrix_basis = Matrix.Translation((0, -agarre * e, 0)) @ Matrix.Diagonal((e, e, e, 1))
        armas_obj.append(o)

# 6. hojas de contacto: cada clip en 8 instantes, desde la vista de combate (3/4) y de frente
if not SIN_RENDER:
    import render_comun as RR
    RR.preparar(300)
    rig_cam = RR.camara_vista(rig, 40, 12)        # el lado que ve la cámara de combate (su izquierda)
    for c in clips:
        act = bpy.data.actions[c["nombre"]]
        arm.animation_data.action = act
        try:
            arm.animation_data.action_slot = act.slots[0]
        except Exception:
            pass
        rutas = []
        n = 8
        for i in range(n):
            t = c["dur"] * i / (n - 1)
            sc.frame_set(int(round(t * BC.FPS)))
            if cara is not None:
                cara.expresion_para(c["nombre"], t / max(c["dur"], 0.01))
            r = os.path.join(EVID, "tmp_%s_%d.png" % (c["nombre"], i))
            RR.E.render(r)
            rutas.append(r)
        RR.hoja(rutas, os.path.join(EVID, "%s_%s.png" % (HEROE.lower(), c["nombre"])), n)
        for r in rutas:
            os.remove(r)
        print("HOJA", c["nombre"])
    arm.animation_data.action = None

# 7. exportar
for o in armas_obj:
    bpy.data.objects.remove(o, do_unlink=True)
json.dump({"heroe": HEROE, "fps": BC.FPS, "altura_blender": round(rig.altura, 4), "clips": info},
          open(os.path.join(carpeta, "%s_v2_clips.json" % HEROE.lower()), "w", encoding="utf-8"), ensure_ascii=False,
          indent=1)
if not SIN_GLB:
    for o in bpy.data.objects:
        o.select_set(o.type in ('ARMATURE', 'MESH'))
    ruta = os.path.join(carpeta, "%s_v2.glb" % HEROE.lower())
    props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
    op = dict(filepath=ruta, export_format='GLB', use_selection=True, export_animations=True,
              export_animation_mode='ACTIONS', export_force_sampling=True, export_apply=False)
    if "export_image_format" in props:
        op["export_image_format"] = 'WEBP'
    if "export_image_quality" in props:
        op["export_image_quality"] = 90
    if "export_frame_range" in props:
        op["export_frame_range"] = False
    if "export_anim_slide_to_zero" in props:
        op["export_anim_slide_to_zero"] = True
    bpy.ops.export_scene.gltf(**op)
    print("GLB", ruta, os.path.getsize(ruta))
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(EVID, "%s_v2.blend" % HEROE.lower()))
