# Nix (V12, cuarta heroína, maga negra; PROTOTIPO APAGADO tras «nix_v12»): construye su modelo con Blender por guion.
#
#   blender -b --factory-startup -P fuente/crear_nix.py -- <raíz aethelgard> <carpeta de evidencias> [opciones]
#     modelo       solo el modelo (color por vértice) y sus vistas, junto a Kael, Lya y Garon (para iterar el diseño)
#     sin_render   sin hojas de contacto de los clips
#     sin_glb      sin exportar
#
# Pasos:
#   1. Esqueleto: el FBX de Lya SOLO por su esqueleto (el rig común de los héroes v2: mismos nombres, jerarquía y
#      orientaciones) y sus clips de captura de andar y correr; su malla y sus texturas se BORRAN. El esqueleto se
#      re-proporciona (ajustar_esqueleto): piernas ×0,78 y brazos ×0,9 con la cadera más baja, sin girar ningún hueso,
#      así que valen la biblioteca de clips de los v2 (rig_comun.py, por IK), los de combate v12 y los de captura.
#   2. Piezas del diseño (crear_nix_diseno.py) en la pose en T, pesos por distancia a sus huesos, y la cara propia
#      (atlas dibujado por código y malla «cara_nix» con formas clave de cejas: cara_v3.py con la mirada «almendra»).
#   3. UV y texturas horneadas (crear_nix_texturas.py): un atlas de 1024 (color pintado con oclusión, metal/rugosidad
#      y relieve horneado de una versión subdividida), para el material de los héroes v2 (heroe_v2.gdshader).
#   4. LOD: «cuerpo_nix» (LOD0) y dos versiones simplificadas en el mismo GLB (cuerpo_nix_lod1 / _lod2).
#   5. Huesos «arma_d» (el bastón, rígido), «sombrero_punta» y «capa_1/2» (secundarios horneados) y los clips
#      (crear_nix_clips.py). Exporta personajes/nix/nix.glb, nix_clips.json y las hojas.
import sys, os, json, math
sys.dont_write_bytecode = True
try:
    sys.stdout.reconfigure(line_buffering=True)      # si Blender se cae, lo impreso hasta entonces queda en el registro
except Exception:
    pass
argv = sys.argv[sys.argv.index("--") + 1:]
RAIZ = argv[0]
EVID = argv[1]
SOLO_MODELO = "modelo" in argv
SIN_RENDER = "sin_render" in argv
SIN_GLB = "sin_glb" in argv
AQUI = os.path.dirname(os.path.abspath(__file__))
V2 = os.path.join(RAIZ, "personajes", "heroes_v2", "fuentes_blender")
V3 = os.path.join(RAIZ, "personajes", "heroes_v3", "fuentes_blender")
sys.path.insert(0, AQUI)
sys.path.insert(1, V3)
sys.path.insert(2, V2)
sys.path.insert(3, os.path.join(RAIZ, "dialogos", "retratos", "fuentes_blender"))
import bpy
from mathutils import Vector, Matrix
import rig_comun as RC
import geometria_v3 as G
import crear_nix_diseno as D

FBX_ESQUELETO = "Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx"
CAPTURA = {"Walking": "andar", "Running": "correr"}
F_PIERNA = 0.78
F_BRAZO = 0.90
CARPETA = os.path.join(RAIZ, "personajes", "nix")
os.makedirs(CARPETA, exist_ok=True)
os.makedirs(EVID, exist_ok=True)


# ------------------------------------------------------------------ 1. esqueleto
def ajustar_esqueleto(arm):
    """Cambia los largos (no las orientaciones) de piernas y brazos y baja la cadera para que los pies sigan en el
    suelo. Devuelve cuánto baja la cadera (m)."""
    factores = {}
    for lado in ("Left", "Right"):
        for n in ("UpLeg", "Leg"):
            factores[RC.P + lado + n] = F_PIERNA
        for n in ("Arm", "ForeArm"):
            factores[RC.P + lado + n] = F_BRAZO
    for n in ("Bone_008", "Bone_007", "Bone_006", "Bone_005"):     # la cadena de detrás (faldón): más corta
        factores[n] = F_PIERNA
    bpy.context.view_layer.objects.active = arm
    for o in bpy.context.selected_objects:
        o.select_set(False)
    arm.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    eb = arm.data.edit_bones
    viejo = {b.name: (b.head.copy(), b.tail.copy(), b.roll) for b in eb}
    mw3 = arm.matrix_world.to_3x3()                              # (el FBX trae la armadura girada: se mide en el mundo)
    pierna = mw3 @ (viejo[RC.P + "LeftUpLeg"][1] - viejo[RC.P + "LeftUpLeg"][0])
    pierna2 = mw3 @ (viejo[RC.P + "LeftLeg"][1] - viejo[RC.P + "LeftLeg"][0])
    baja = -(pierna.z + pierna2.z) * (1 - F_PIERNA)             # cuánto se acorta la pierna (m, positivo)
    mwi3 = mw3.inverted()
    delta_raiz = mwi3 @ Vector((0, 0, -baja))
    for b in eb:
        b.use_connect = False
    nuevo = {}

    def poner(b):
        h0, t0, r0 = viejo[b.name]
        p = b.parent
        if p is None:
            h = h0 + delta_raiz
        else:
            ph0, pt0, _ = viejo[p.name]
            fp = factores.get(p.name, 1.0)
            off = h0 - ph0
            if fp != 1.0:
                eje = (pt0 - ph0)
                L2 = eje.length_squared
                comp = eje * (off.dot(eje) / L2) if L2 > 1e-12 else Vector()
                off = comp * fp + (off - comp)
            h = nuevo[p.name][0] + off
        t = h + (t0 - h0) * factores.get(b.name, 1.0)
        nuevo[b.name] = (h, t)
        b.head = h
        b.tail = t
        b.roll = r0
        for c in b.children:
            poner(c)

    for b in [b for b in eb if b.parent is None]:
        poner(b)
    bpy.ops.object.mode_set(mode='OBJECT')
    return baja


def preparar_esqueleto():
    arm, mallas = RC.importar_fbx(os.path.join(RAIZ, FBX_ESQUELETO))
    for o in mallas:
        me = o.data
        bpy.data.objects.remove(o, do_unlink=True)
        bpy.data.meshes.remove(me)
    for img in list(bpy.data.images):
        bpy.data.images.remove(img)
    for m in list(bpy.data.materials):
        bpy.data.materials.remove(m)
    for act in list(bpy.data.actions):
        nuevo = None
        for pista, n in CAPTURA.items():
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
    baja = ajustar_esqueleto(arm)
    # la cadera de los clips de captura sube y baja menos (piernas más cortas)
    for act in bpy.data.actions:
        for fc in _fcurvas(act):
            if fc.data_path == 'pose.bones["%sHips"].location' % RC.P:
                for k in fc.keyframe_points:
                    k.co.y *= F_PIERNA
                    k.handle_left.y *= F_PIERNA
                    k.handle_right.y *= F_PIERNA
    bpy.context.view_layer.update()
    print("ESQUELETO cadera %.3f m más baja" % baja)
    return arm


def _fcurvas(act):
    """Las curvas de una acción (Blender 5: por capas y ranuras; antes, act.fcurves)."""
    try:
        return list(act.fcurves)
    except Exception:
        pass
    r = []
    for capa in act.layers:
        for tira in capa.strips:
            for cb in tira.channelbags:
                r += list(cb.fcurves)
    return r


arm = preparar_esqueleto()
sc = bpy.context.scene
sc.render.fps = 30
RC.crear_hueso_arma(arm, "Right", "arma_d")
arm.data.bones["arma_d"].use_deform = True       # el bastón va pesado a él (rígido); en el GLB es un hueso más
H = G.Huesos(arm)

# ------------------------------------------------------------------ 2. piezas
col = bpy.data.collections.new("nix")
sc.collection.children.link(col)
mats = {n: bpy.data.materials.new("pal_" + n) for n in D.MATERIALES}
piezas = D.construir(H)
# el bastón, en el hueso arma_d (su eje Y es la «hoja»: el asta hacia arriba; su X, el «filo»)
ba = arm.data.bones["arma_d"]
mba = arm.matrix_world @ ba.matrix_local
piezas.append(D.baston(mba.to_translation(), mba.to_3x3().col[1], mba.to_3x3().col[0],
                       G.Huesos(arm).c("HeadTop_End").z))
obs = [G.a_objeto(pz, col, mats) for pz in piezas]
for ob in obs:
    G.pesar(ob, H)
    ob.parent = arm
    ob.matrix_parent_inverse = arm.matrix_world.inverted()
    md = ob.modifiers.new("Armature", 'ARMATURE')
    md.object = arm
tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in obs)
print("PIEZAS", len(obs), "triangulos", tris)
for o in obs:
    print("  PIEZA %-24s %6d tri" % (o.name, sum(len(p.vertices) - 2 for p in o.data.polygons)))
# el sombrero: caras planas en la copa (facetado) y la banda
for o in obs:
    if o.name == "nix_sombrero":
        nombres = [m.name.replace("pal_", "") for m in o.data.materials]
        for p in o.data.polygons:
            if nombres[p.material_index] in ("sombrero", "cobre", "negro"):
                p.use_smooth = False

if SOLO_MODELO:
    import crear_nix_hojas as HJ
    ao = G.oclusion(obs, rayos=16)
    for ob in obs:
        G.colorear(ob, D.PALETA_VERTICE(), ao[ob.name])
    import crear_nix_clips as NC
    HJ.material_vertice(obs)
    rig = RC.Rig(arm)
    HJ.vistas_modelo(arm, obs, EVID, "nix_modelo_T")
    pose = lambda: rig.aplicar(NC.reposo_pose())
    HJ.vistas_modelo(arm, obs, EVID, "nix_modelo_reposo", pose)
    HJ.junto_al_grupo(arm, obs, RAIZ, EVID, "nix_modelo_grupo", float(os.environ.get("NIX_ESC", "0.56")), pose)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(EVID, "nix_modelo.blend"))
    print("MODELO_OK")
    sys.exit(0)

# ------------------------------------------------------------------ 2b-7: cara, texturas, LOD, clips, hojas y GLB
import crear_nix_final as FIN
FIN.ejecutar({"arm": arm, "obs": obs, "D": D, "RAIZ": RAIZ, "EVID": EVID, "CARPETA": CARPETA,
              "SIN_RENDER": SIN_RENDER, "SIN_GLB": SIN_GLB})
