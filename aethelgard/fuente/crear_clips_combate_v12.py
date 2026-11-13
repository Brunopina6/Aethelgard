# Combate V12 (animación de combate, 12/11/2026): construye la biblioteca de clips NUEVOS de combate de un héroe v2.
#
#   blender -b --factory-startup -P fuente/crear_clips_combate_v12.py -- <héroe> <raíz aethelgard> <evidencias> [sin_render]
#
# Pasos (como personajes/heroes_v2/fuentes_blender/construir_heroe.py, del que copia el método):
#   1. importa el FBX ORIGINAL del héroe (no se toca) y quita sus clips;
#   2. añade los huesos de arma (arma_d, arma_i) en el mismo sitio que el GLB v2;
#   3. crea los clips de fuente/clips_combate_v12.py (prefijo «c12_»);
#   4. hojas de contacto de cada clip (8 instantes, vista de la cámara del combate) en <evidencias>, con el arma;
#   5. exporta personajes/heroes_v2/<héroe>/<héroe>_v2_combate_v12.glb SOLO con el esqueleto y una malla mínima de un
#      triángulo (el glTF necesita una piel para que Godot haga un Skeleton3D): Godot la importa como biblioteca de
#      animación («animation_library», .import al lado), así que en el juego no entra ninguna malla ni textura;
#      y <héroe>_v2_combate_v12.json con duraciones, bucles e instantes.
# Los clips v2 de siempre (<héroe>_v2.glb) NO se tocan: esta biblioteca va aparte y solo la usa combate_anim_v12.gd.
import sys, os, json
sys.dont_write_bytecode = True
AQUI = os.path.dirname(os.path.abspath(__file__))
argv = sys.argv[sys.argv.index("--") + 1:]
HEROE = argv[0]
RAIZ = argv[1]
EVID = argv[2]
SIN_RENDER = "sin_render" in argv
sys.path.insert(0, os.path.join(RAIZ, "personajes", "heroes_v2", "fuentes_blender"))
sys.path.insert(0, AQUI)
import bpy
from mathutils import Matrix
import rig_comun as RC
import biblioteca_clips as BC
import clips_combate_v12 as CC

FUENTES = {
    "Kael": "kael.fbx",
    "Lya": "Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx",
    "Garon": "garon.fbx",
}
ARMAS = {   # como construir_heroe.py
    "Kael": [("arma_d", "sable", 1.45, 0.0)],
    "Lya": [("arma_d", "vara", 1.05, 0.0)],
    "Garon": [("arma_d", "hoja_infernal", 1.1, 0.12), ("arma_i", "hoja_infernal", 1.1, 0.12)],
}

carpeta = os.path.join(RAIZ, "personajes", "heroes_v2", HEROE.lower())
os.makedirs(EVID, exist_ok=True)

arm, mallas = RC.importar_fbx(os.path.join(RAIZ, FUENTES[HEROE]))
sc = bpy.context.scene
sc.render.fps = BC.FPS
for act in list(bpy.data.actions):
    bpy.data.actions.remove(act)
for hueso, *_ in ARMAS[HEROE]:
    RC.crear_hueso_arma(arm, "Right" if hueso == "arma_d" else "Left", hueso)
rig = RC.Rig(arm)
print("HEROE", HEROE, "altura %.3f" % rig.altura)

info = {}
clips = CC.clips_de(HEROE)
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
    print("CLIP", c["nombre"], "%.2f s" % c["dur"], len(c["claves"]), "claves", c["eventos"])
arm.animation_data.action = None
rig.reset()

# hojas de contacto con el arma puesta (como construir_heroe.py)
if not SIN_RENDER:
    armas_obj = []
    for hueso, modelo, largo, agarre in ARMAS[HEROE]:
        antes = set(bpy.data.objects)
        bpy.ops.wm.obj_import(filepath=os.path.join(RAIZ, modelo + ".obj"), forward_axis='Y', up_axis='Z')
        for o in [o for o in bpy.data.objects if o not in antes]:
            tex = os.path.join(RAIZ, modelo + "_color.jpg")
            if os.path.exists(tex):
                mat = bpy.data.materials.new(modelo + "_mat"); mat.use_nodes = True
                nt = mat.node_tree; bs = nt.nodes["Principled BSDF"]
                ti = nt.nodes.new("ShaderNodeTexImage"); ti.image = bpy.data.images.load(tex)
                nt.links.new(ti.outputs["Color"], bs.inputs["Base Color"])
                o.data.materials.clear(); o.data.materials.append(mat)
            o.parent = arm
            o.parent_type = 'BONE'
            o.parent_bone = hueso
            L = arm.data.bones[hueso].length
            e = largo * rig.altura / 1.65
            o.matrix_parent_inverse = Matrix.Translation((0, -L, 0))
            o.matrix_basis = Matrix.Translation((0, -agarre * e, 0)) @ Matrix.Diagonal((e, e, e, 1))
            armas_obj.append(o)
    import render_comun as RR
    RR.preparar(300)
    RR.camara_vista(rig, 40, 12)
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
            RR.E.render(r)
            rutas.append(r)
        RR.hoja(rutas, os.path.join(EVID, "%s_%s.png" % (HEROE.lower(), c["nombre"])), 8)
        for r in rutas:
            os.remove(r)
        print("HOJA", c["nombre"])
    arm.animation_data.action = None
    for o in armas_obj:
        bpy.data.objects.remove(o, do_unlink=True)

# malla mínima con piel (un triángulo pesado a la cadera) en lugar de la del personaje
for m in mallas:
    bpy.data.objects.remove(m, do_unlink=True)
me = bpy.data.meshes.new("c12_piel")
me.from_pydata([(0, 0, 0), (0.01, 0, 0), (0, 0, 0.01)], [], [(0, 1, 2)])
ob = bpy.data.objects.new("c12_piel", me)
sc.collection.objects.link(ob)
ob.parent = arm
vg = ob.vertex_groups.new(name=RC.P + "Hips")
vg.add([0, 1, 2], 1.0, 'REPLACE')
mod = ob.modifiers.new("Armature", 'ARMATURE')
mod.object = arm

json.dump({"heroe": HEROE, "fps": BC.FPS, "clips": info},
          open(os.path.join(carpeta, "%s_v2_combate_v12.json" % HEROE.lower()), "w", encoding="utf-8"),
          ensure_ascii=False, indent=1)
for o in bpy.data.objects:
    o.select_set(o.type in ('ARMATURE', 'MESH'))
ruta = os.path.join(carpeta, "%s_v2_combate_v12.glb" % HEROE.lower())
props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
op = dict(filepath=ruta, export_format='GLB', use_selection=True, export_animations=True,
          export_animation_mode='ACTIONS', export_force_sampling=True, export_apply=False)
if "export_materials" in props:
    op["export_materials"] = 'NONE'
if "export_frame_range" in props:
    op["export_frame_range"] = False
if "export_anim_slide_to_zero" in props:
    op["export_anim_slide_to_zero"] = True
bpy.ops.export_scene.gltf(**op)
print("GLB", ruta, os.path.getsize(ruta))
