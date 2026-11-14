# Nix piloto FBX, paso 3: esqueleto compatible con los héroes v2, pesos, clips y exportación GLB.
#   blender -b -P p4_rig.py -- <blend paso 2> <fbx de Lya> <raíz aethelgard> <carpeta render> <blend salida> <glb salida>
#                               <json clips salida> <res textura GLB> [sin_render] [sin_clips]
#
# 1. El esqueleto de Lya (FBX del juego, solo su armadura: mismos nombres «mixamorig:», jerarquía y orientaciones) se
#    re-sitúa sobre las articulaciones MEDIDAS en la malla de Nix (p3_medir.py, 14/11) conservando el giro de cada hueso
#    (align_roll con su eje Z de antes). Se quitan sus huesos propios (pelo de detrás, faldón, «headfront», puntas de la
#    mano) y se añaden los de Nix: «mechon_i_1/2» y «mechon_d_1/2» (los dos mechones delanteros) y «mechon_sup_1/2»
#    (el mechón superior), y el socket «arma_d» (no deforma: ahí va el cetro). 36 huesos deforman.
# 2. Pesos: calor de Blender (ARMATURE_AUTO) en el cuerpo con los huesos que deforman; el pelo (detectado por el color
#    horneado: claro y poco saturado) va entero a la cabeza, salvo los mechones (degradado raíz → punta, raíz anclada a
#    la cabeza) y el mechón superior. Máximo 4 pesos por vértice, normalizados.
# 3. Clips: andar y correr de captura (los de Lya, con el recorrido de la cadera escalado a las piernas de Nix) y los de
#    Nix por IK (fuente/crear_nix_clips.py con la biblioteca común; no se tocan esos archivos). Nuevo: «canalizar» (los
#    mechones se elevan con retraso y el superior responde) y el mismo viento en el bucle «magia_concentrar».
# 4. GLB con texturas WebP (color, normal y rugosidad) a la resolución pedida y el JSON de clips (contrato de nix_3d.gd).
import sys, os, json, math
sys.dont_write_bytecode = True
argv = sys.argv[sys.argv.index("--") + 1:]
BLEND2, FBX_LYA, RAIZ, REND, BLEND3, GLB, JSON_CLIPS, RES_GLB = argv[:8]
RES_GLB = int(RES_GLB)
SIN_RENDER = "sin_render" in argv
SIN_CLIPS = "sin_clips" in argv
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
sys.path.insert(1, os.path.join(RAIZ, "fuente"))
sys.path.insert(2, os.path.join(RAIZ, "personajes", "heroes_v2", "fuentes_blender"))
import bpy, bmesh
import numpy as np
from mathutils import Vector, Matrix, Quaternion
import nix_comun as C
import rig_comun as RC
os.makedirs(REND, exist_ok=True)

P = "mixamorig:"
bpy.ops.wm.open_mainfile(filepath=BLEND2)
alta = bpy.data.objects.get("nix_alta")
if alta is not None:
    me_a = alta.data
    bpy.data.objects.remove(alta, do_unlink=True)
    bpy.data.meshes.remove(me_a)
cuerpo = bpy.data.objects["nix_baja"]
cuerpo.name = "cuerpo_nix"
cuerpo.data.name = "cuerpo_nix"
mat_nix = cuerpo.data.materials[0]
for g in list(cuerpo.vertex_groups):          # el grupo «detalle» de la reducción (paso 1) no es un hueso
    cuerpo.vertex_groups.remove(g)
imgs_nix = set(bpy.data.images)

# ------------------------------------------------------------------ 1. esqueleto de Lya
antes = set(bpy.data.objects); mats0 = set(bpy.data.materials); acts0 = set(bpy.data.actions)
bpy.ops.import_scene.fbx(filepath=FBX_LYA)
nuevos = [o for o in bpy.data.objects if o not in antes]
arm = [o for o in nuevos if o.type == 'ARMATURE'][0]
arm.name = "nix_esqueleto"
for o in nuevos:
    if o.type == 'MESH':
        me = o.data
        bpy.data.objects.remove(o, do_unlink=True)
        bpy.data.meshes.remove(me)
for m in list(bpy.data.materials):
    if m not in mats0:
        bpy.data.materials.remove(m)
for im in list(bpy.data.images):
    if im not in imgs_nix:
        bpy.data.images.remove(im)
CAPTURA = {"Walking": "andar", "Running": "correr"}
for act in list(bpy.data.actions):
    if act in acts0:
        continue
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

# Articulaciones de Nix (m; pies en z = 0, mira a -Y, su izquierda es +X), medidas en la malla (p3_medir.py, 14/11):
# brazos horizontales a z 1,465 (hombro x 0,175, codo 0,41, muñeca en el puño 0,645, dedos hasta 0,84); entrepierna a
# z 0,975 (cadera de la pierna 1,01, x 0,095); rodilla en el estrechamiento sobre el gemelo (z 0,60); tobillo z 0,085
# (sobre la tobillera de 0,15); punta del pie y -0,16. Cuello más estrecho a z 1,55; nariz a 1,708; cráneo hasta 1,84.
J = {}


def lado(nombre, v):
    J[P + "Left" + nombre] = Vector(v)
    J[P + "Right" + nombre] = Vector((-v[0], v[1], v[2]))


J[P + "Hips"] = Vector((0.0, -0.005, 1.05))
J[P + "Spine"] = Vector((0.0, 0.0, 1.13))
J[P + "Spine1"] = Vector((0.0, 0.005, 1.23))
J[P + "Spine2"] = Vector((0.0, 0.0, 1.34))
J[P + "Neck"] = Vector((0.0, 0.005, 1.50))
J[P + "Head"] = Vector((0.0, 0.01, 1.60))
J[P + "HeadTop_End"] = Vector((0.0, 0.0, 1.84))
lado("Shoulder", (0.035, -0.005, 1.455))
lado("Arm", (0.175, 0.0, 1.465))
lado("ForeArm", (0.41, 0.008, 1.463))
lado("Hand", (0.645, 0.003, 1.462))
lado("HandMiddle1", (0.765, 0.0, 1.458))
lado("HandMiddle2", (0.792, 0.0, 1.459))
lado("HandMiddle3", (0.815, 0.0, 1.461))
lado("HandMiddle4", (0.838, 0.0, 1.462))
lado("HandThumb1", (0.685, -0.030, 1.452))
lado("HandThumb2", (0.712, -0.060, 1.452))
lado("HandThumb3", (0.735, -0.077, 1.452))
lado("HandThumb4", (0.755, -0.086, 1.452))
lado("UpLeg", (0.095, -0.01, 1.01))
lado("Leg", (0.110, -0.012, 0.60))
lado("Foot", (0.121, 0.012, 0.085))
lado("ToeBase", (0.125, -0.095, 0.028))
lado("Toe_End", (0.127, -0.160, 0.020))
# colas de los huesos sin hijo en la cadena (en el mundo)
COLA = {P + "HeadTop_End": Vector((0, 0, 2.0)), P + "LeftHandMiddle4": Vector((0.86, 0, 1.462)),
        P + "RightHandMiddle4": Vector((-0.86, 0, 1.462)), P + "LeftHandThumb4": Vector((0.772, -0.092, 1.452)),
        P + "RightHandThumb4": Vector((-0.772, -0.092, 1.452)), P + "LeftToe_End": Vector((0.127, -0.20, 0.018)),
        P + "RightToe_End": Vector((-0.127, -0.20, 0.018)), P + "LeftHand": None, P + "RightHand": None}
SIGUE = {"Hips": "Spine", "Spine": "Spine1", "Spine1": "Spine2", "Spine2": "Neck", "Neck": "Head", "Head": "HeadTop_End"}
for s in ("Left", "Right"):
    SIGUE.update({s + "Shoulder": s + "Arm", s + "Arm": s + "ForeArm", s + "ForeArm": s + "Hand",
                  s + "Hand": s + "HandMiddle1", s + "HandMiddle1": s + "HandMiddle2", s + "HandMiddle2": s + "HandMiddle3",
                  s + "HandMiddle3": s + "HandMiddle4", s + "HandThumb1": s + "HandThumb2",
                  s + "HandThumb2": s + "HandThumb3", s + "HandThumb3": s + "HandThumb4",
                  s + "UpLeg": s + "Leg", s + "Leg": s + "Foot", s + "Foot": s + "ToeBase", s + "ToeBase": s + "Toe_End"})
QUITAR = ["Bone_018", "Bone_017", "headfront", "Bone_040", "Bone_041", "Bone_008", "Bone_007", "Bone_006", "Bone_005"]
# mechones (cabeza, cola) en el mundo: medidos por el color del pelo (p3_pelo.py, 14/11)
MECHONES = {
    "mechon_i_1": ((0.072, -0.065, 1.645), (0.068, -0.075, 1.515), P + "Neck"),
    "mechon_i_2": ((0.068, -0.075, 1.515), (0.110, -0.128, 1.395), "mechon_i_1"),
    "mechon_d_1": ((-0.072, -0.065, 1.645), (-0.068, -0.072, 1.515), P + "Neck"),
    "mechon_d_2": ((-0.068, -0.072, 1.515), (-0.110, -0.128, 1.395), "mechon_d_1"),
    "mechon_sup_1": ((-0.005, -0.030, 1.835), (-0.008, -0.040, 1.872), P + "Head"),
    "mechon_sup_2": ((-0.008, -0.040, 1.872), (0.010, -0.040, 1.905), "mechon_sup_1"),
}

bpy.context.view_layer.objects.active = arm
for o in bpy.context.selected_objects:
    o.select_set(False)
arm.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
eb = arm.data.edit_bones
mwi = arm.matrix_world.inverted()
for n in QUITAR:
    if n in eb:
        eb.remove(eb[n])
for b in eb:
    b.use_connect = False
eje_z = {b.name: b.z_axis.copy() for b in eb}
for b in eb:
    if b.name not in J:
        print("AVISO hueso sin articulación", b.name)
        continue
    corto = b.name[len(P):]
    h = J[b.name]
    if corto in SIGUE:
        t = J[P + SIGUE[corto]]
    else:
        t = COLA.get(b.name)
    b.head = mwi @ h
    b.tail = mwi @ t
    b.align_roll(eje_z[b.name])
for n, (h, t, padre) in MECHONES.items():
    b = eb.new(n)
    b.head = mwi @ Vector(h); b.tail = mwi @ Vector(t)
    b.parent = eb[padre]
    b.use_connect = False
    b.align_roll(mwi.to_3x3() @ Vector((0, -1, 0)))           # su eje Z hacia delante
bpy.ops.object.mode_set(mode='OBJECT')
RC.crear_hueso_arma(arm, "Right", "arma_d")
NO_DEFORMA = {P + "HeadTop_End", P + "LeftToe_End", P + "RightToe_End", "arma_d"}
for s in ("Left", "Right"):
    NO_DEFORMA |= {P + s + "HandThumb3", P + s + "HandThumb4", P + s + "HandMiddle3", P + s + "HandMiddle4"}
for b in arm.data.bones:
    b.use_deform = b.name not in NO_DEFORMA and not b.name.startswith("mechon")   # (los mechones, tras el calor)
def fcurvas(act):
    try:
        return list(act.fcurves)
    except Exception:
        return [fc for capa in act.layers for tira in capa.strips for cb in tira.channelbags for fc in cb.fcurves]


def quitar_curvas(act, cond):
    try:
        for fc in list(act.fcurves):
            if cond(fc):
                act.fcurves.remove(fc)
        return
    except Exception:
        pass
    for capa in act.layers:
        for tira in capa.strips:
            for cb in tira.channelbags:
                for fc in list(cb.fcurves):
                    if cond(fc):
                        cb.fcurves.remove(fc)


# el recorrido de la cadera de los clips de captura, a las piernas de Nix
pierna_lya = 0.937 - 0.135
pierna_nix = 1.01 - 0.085
F = pierna_nix / pierna_lya
for act in bpy.data.actions:
    if act.name in CAPTURA.values():
        for fc in fcurvas(act):
            nombre = fc.data_path.split('"')[1] if '"' in fc.data_path else ""
            if nombre in QUITAR or nombre[len(P):] in QUITAR:
                continue
            if fc.data_path == 'pose.bones["%sHips"].location' % P:
                for k in fc.keyframe_points:
                    k.co.y *= F; k.handle_left.y *= F; k.handle_right.y *= F
        # sin curvas de huesos quitados
        quitar_curvas(act, lambda fc: any('"%s"' % q in fc.data_path for q in QUITAR))
print("ESQUELETO huesos", len(arm.data.bones), "deforman", sum(1 for b in arm.data.bones if b.use_deform) + 6,
      "cadera captura x%.3f" % F)

# ------------------------------------------------------------------ 2. pesos
# pelo por el color horneado (claro y poco saturado)
me = cuerpo.data
tex_color = bpy.data.images["nix_color"]
Wt, Ht = tex_color.size
px = np.array(tex_color.pixels[:], dtype=np.float32).reshape(Ht, Wt, 4)


def clasificar_pelo():
    uv = me.uv_layers.active.data
    acc = {}
    for p in me.polygons:
        for li in p.loop_indices:
            vi = me.loops[li].vertex_index
            u, v = uv[li].uv
            acc.setdefault(vi, []).append(px[min(Ht - 1, max(0, int(v * Ht))), min(Wt - 1, max(0, int(u * Wt))), :3])
    r = set()
    for vi, cs in acc.items():
        c = np.mean(cs, axis=0)
        if c.mean() > 0.5 and (c.max() - c.min()) < 0.10:
            r.add(vi)
    return r


# Los mechones delanteros están SOLDADOS al pecho en la malla de Meshy (una sola pieza cerrada): al levantarlos
# arrastraban el mono (visto en render el 14/11). Se separan: las caras del mechón (los tres vértices de pelo; con dos
# se llevaban aletas oscuras del mono) se despegan del mono y de la piel (split_edges); solo siguen unidas al pelo de la
# cabeza por encima de 1,60 m.
Z_CORTE = 1.585


def en_zona_mechon(c):
    return 1.37 < c.z < 1.645 and 0.03 < abs(c.x) < 0.15 and c.y < -0.005


pelo = clasificar_pelo()
bm = bmesh.new(); bm.from_mesh(me)
bm.verts.ensure_lookup_table(); bm.faces.ensure_lookup_table()
caras_mechon = set()
for f in bm.faces:
    c = f.calc_center_median()
    if en_zona_mechon(c) and all(v.index in pelo for v in f.verts):
        caras_mechon.add(f.index)


def separar(e):
    # el mechón solo sigue unido al pelo de la cabeza (caras de pelo por encima de 1,60); del mono y la piel, despegado
    fs = list(e.link_faces)
    if len(fs) != 2:
        return False
    dentro = [f for f in fs if f.index in caras_mechon]
    if len(dentro) != 1:
        return False
    otra = fs[0] if fs[1] is dentro[0] else fs[1]
    es_pelo = all(v.index in pelo for v in otra.verts)
    return (not es_pelo) or otra.calc_center_median().z < 1.60


bordes = [e for e in bm.edges if separar(e)]
print("MECHONES caras", len(caras_mechon), "aristas despegadas", len(bordes))
bmesh.ops.split_edges(bm, edges=bordes)
bm.verts.ensure_lookup_table(); bm.faces.ensure_lookup_table()
v_mechon = set()
# tras dividir, los índices de caras se conservan: los vértices de las caras del mechón son ya solo suyos
for fi in caras_mechon:
    for v in bm.faces[fi].verts:
        v_mechon.add(v.index)
bm.to_mesh(me); bm.free(); me.update()
pelo = clasificar_pelo()
print("MECHONES vértices", len(v_mechon))

for o in bpy.context.selected_objects:
    o.select_set(False)
cuerpo.select_set(True); arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.parent_set(type='ARMATURE_AUTO')
print("CALOR grupos", len(cuerpo.vertex_groups))
print("CALOR vértices sin peso", sum(1 for v in me.vertices if not any(g.weight > 1e-4 for g in v.groups)))
for b in arm.data.bones:
    if b.name.startswith("mechon"):
        b.use_deform = True
grupos = {g.name: g for g in cuerpo.vertex_groups}
for n in MECHONES:
    if n not in grupos:
        grupos[n] = cuerpo.vertex_groups.new(name=n)
G_HEAD = grupos[P + "Head"]


def poner(vi, pesos):
    for g in cuerpo.vertex_groups:
        g.remove([vi])
    for n, w in pesos.items():
        if w > 1e-4:
            grupos[n].add([vi], w, 'REPLACE')


def smooth(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


n_mech = {"i": 0, "d": 0, "sup": 0}; n_pelo_cabeza = 0
Z_RAIZ, Z_PUNTA = 1.645, 1.39
for vi in sorted(pelo | v_mechon):
    p = me.vertices[vi].co
    if p.z < 1.37 or (p.z < Z_CORTE and vi not in v_mechon):
        continue                                   # rayas claras del mono: no son pelo
    s = "i" if p.x > 0 else "d"
    if (vi in v_mechon) or (Z_CORTE <= p.z < 1.625 and 0.03 < abs(p.x) < 0.145 and p.y < -0.005):
        # mechón delantero: raíz anclada a la cabeza, punta libre
        t = (Z_RAIZ - p.z) / (Z_RAIZ - Z_PUNTA)
        wh = 1.0 - smooth(0.16, 0.34, t)          # hasta 1,60 m rígido con la cabeza (si no, mancha la mejilla)
        w2 = smooth(0.40, 0.62, t)
        w1 = max(0.0, 1.0 - wh - w2)
        poner(vi, {P + "Head": wh, "mechon_%s_1" % s: w1, "mechon_%s_2" % s: w2})
        n_mech[s] += 1
    elif p.z > 1.842 and abs(p.x) < 0.075 and p.y < 0.03:
        t = smooth(1.842, 1.875, p.z)
        w2 = smooth(1.872, 1.898, p.z)
        poner(vi, {P + "Head": 1.0 - t, "mechon_sup_1": max(0.0, t - w2), "mechon_sup_2": w2})
        n_mech["sup"] += 1
    elif p.z > 1.53:
        poner(vi, {P + "Head": 1.0})            # el resto del pelo, rígido con la cabeza
        n_pelo_cabeza += 1
n_cuello = 0
for v in me.vertices:
    p = v.co
    if v.index in pelo or v.index in v_mechon or p.z < 1.53 or abs(p.x) > 0.13:
        continue
    wc = smooth(1.555, 1.60, p.z)
    if wc >= 0.999:
        poner(v.index, {P + "Head": 1.0})
    else:
        poner(v.index, {P + "Head": wc, P + "Neck": 1.0 - wc})
    n_cuello += 1
print("PESOS pelo", len(pelo), "mechones", n_mech, "pelo a la cabeza", n_pelo_cabeza, "cara y cuello", n_cuello)
bpy.context.view_layer.objects.active = cuerpo
for o in bpy.context.selected_objects:
    o.select_set(False)
cuerpo.select_set(True)
bpy.ops.object.mode_set(mode='WEIGHT_PAINT')
bpy.ops.object.vertex_group_clean(group_select_mode='ALL', limit=0.01)
bpy.ops.object.vertex_group_limit_total(group_select_mode='ALL', limit=4)
bpy.ops.object.vertex_group_normalize_all(group_select_mode='ALL', lock_active=False)
bpy.ops.object.mode_set(mode='OBJECT')
for v in me.vertices:                       # (un vértice suelto se quedaba sin pesos tras limpiar)
    if not any(g.weight > 0 for g in v.groups):
        G_HEAD.add([v.index], 1.0, 'REPLACE') if v.co.z > 1.45 else grupos[P + "Hips"].add([v.index], 1.0, 'REPLACE')
mx = max(len([g for g in v.groups if g.weight > 0]) for v in me.vertices)
suma_mal = sum(1 for v in me.vertices if abs(sum(g.weight for g in v.groups) - 1.0) > 0.01)
sin = sum(1 for v in me.vertices if not v.groups)
print("PESOS máximo por vértice", mx, "suma != 1:", suma_mal, "sin peso:", sin)
usados = {cuerpo.vertex_groups[g.group].name for v in me.vertices for g in v.groups if g.weight > 0}
print("HUESOS con pesos", len(usados), sorted(n.replace(P, "") for n in usados))
# grupos vacíos fuera (de huesos que no deforman)
for g in list(cuerpo.vertex_groups):
    if g.name not in usados:
        cuerpo.vertex_groups.remove(g)

# ------------------------------------------------------------------ 3. clips
FPS = 30
bpy.context.scene.render.fps = FPS
rig = RC.Rig(arm)
print("RIG altura %.3f brazo %.3f pierna %.3f" % (rig.altura, rig.largo_brazo["Right"], rig.largo_pierna["Right"]))
info = {}
MECH = ["mechon_i_1", "mechon_i_2", "mechon_d_1", "mechon_d_2", "mechon_sup_1", "mechon_sup_2"]


def viento(rig, t, fuerza, t0=0.0, periodo=None):
    """Los mechones en el instante t (s) de la canalización: suben con retraso (la raíz antes que la punta, el superior
    después) y ondulan desfasados. fuerza 0..1."""
    mw = arm.matrix_world
    for nombre, retraso, amp, eje_lado in [("mechon_i_1", 0.10, 22, 1), ("mechon_i_2", 0.28, 20, 1),
                                           ("mechon_d_1", 0.14, 22, -1), ("mechon_d_2", 0.33, 20, -1),
                                           ("mechon_sup_1", 0.22, 14, 0), ("mechon_sup_2", 0.38, 18, 0)]:
        pb = arm.pose.bones[nombre]
        e = t - t0 - retraso
        if periodo:                               # bucle: ya arriba, ondulan y cierran el ciclo
            sube = 1.0
            onda = math.sin(t / periodo * 2 * math.pi - retraso * 9.0) * 0.18
        else:
            sube = smooth(0.0, 0.55, e) if e > 0 else 0.0
            onda = math.sin((t - t0) * 2 * math.pi * 1.1 - retraso * 9.0) * 0.18 * sube
        ang = math.radians(amp) * fuerza * (sube + onda)
        R = (mw @ pb.matrix).to_3x3().normalized()
        # hacia delante y arriba (gira sobre el eje lateral) y un poco hacia fuera
        q = Quaternion(Vector((1, 0, 0)), -ang)                 # (+X giraba hacia atrás, contra el pecho)
        if eje_lado:
            q = Quaternion(Vector((0, 1, 0)), -eje_lado * ang * 0.35) @ q
        else:
            q = Quaternion(Vector((1, 0, 0)), -ang * 0.6) @ Quaternion(Vector((0, 1, 0)), ang * 0.5)
        cab = mw @ pb.head
        pb.matrix = mw.inverted() @ (Matrix.Translation(cab) @ (q.to_matrix() @ R).to_4x4())
        bpy.context.view_layer.update()


if not SIN_CLIPS:
    import biblioteca_clips as BC
    import crear_nix_clips as NC
    # concentrarse con proporciones adultas: con la mano libre de la Nix chibi (a la altura del hombro) la palma le tapaba
    # la cara; aquí baja al pecho, delante del esternón (solo en este piloto: crear_nix_clips.py no se toca)
    def c_concentrar_adulta(e=NC.ESTILO):
        g = NC.guardia_pose(e)
        k = BC.mezclar(BC.cadera_mas(g, (0, -0.012, 0)), {"mirada": 14.0, "columna": (0, 0, -4), "cabeza": (6, 0, -4),
              "mano_d": {"pos": (0.40, -0.35, 0.42), "hoja": (0.10, 1.0, 0.35), "codo": (-0.2, -1, 0.8)},
              "mano_i": {"pos": (0.52, -0.30, -0.18), "dedos": (0.3, 0.9, 0.1), "palma": (0.1, 0, 1), "cierre": 20,
                         "pulgar": 10}})
        k2 = BC.mezclar(BC.cadera_mas(k, (0, 0.010, 0)), {"columna": (-2, 0, -4),
                        "mano_i": {"pos": (0.54, -0.26, -0.16), "cierre": 8}})
        return BC.clip("magia_concentrar", 2.2, [(0, k), (1.1, k2), (2.2, k)], bucle=True)
    NC.c_concentrar = c_concentrar_adulta
    clips = NC.clips_de()
    if arm.animation_data is None:
        arm.animation_data_create()
    # «canalizar»: entrada de la concentración (0,9 s) con los mechones subiendo con retraso
    g = NC.guardia_pose(NC.ESTILO)
    k = [c for c in clips if c["nombre"] == "magia_concentrar"][0]["claves"][0][1]
    clips.append(BC.clip("canalizar", 0.9, [(0, g), (0.45, k), (0.9, k)], eventos={"mechones_arriba": 0.75}))
    VIENTO = {"canalizar": (1.0, 0.0, False), "magia_concentrar": (1.0, -2.0, True)}   # fuerza, t0, bucle
    for c in clips:
        act = bpy.data.actions.new(c["nombre"])
        act.use_fake_user = True
        arm.animation_data.action = act
        try:
            arm.animation_data.action_slot = act.slots.new('OBJECT', arm.name) if len(act.slots) == 0 else act.slots[0]
        except Exception:
            pass
        previo = {}
        for t, d in c["claves"]:
            rig.aplicar(d)
            for pb in rig.pb:
                q = pb.rotation_quaternion.copy()
                if pb.name in previo and q.dot(previo[pb.name]) < 0:
                    pb.rotation_quaternion = -q
                previo[pb.name] = pb.rotation_quaternion.copy()
            rig.clave(t * FPS)
        if c["nombre"] in VIENTO:
            fz, t0, bucle = VIENTO[c["nombre"]]
            n = int(round(c["dur"] * FPS))
            for f in range(0, n + 1, 2):
                t = f / FPS
                for nm in MECH:
                    arm.pose.bones[nm].matrix_basis = Matrix.Identity(4)
                bpy.context.view_layer.update()
                if bucle:
                    # en el bucle ya están arriba: ondulan con un periodo que cierra el bucle (2,2 s = 2 ondas)
                    viento(rig, t, fz, 0.0, periodo=c["dur"] / 2.0)
                else:
                    viento(rig, t, fz, t0)
                for nm in MECH:
                    arm.pose.bones[nm].keyframe_insert("rotation_quaternion", frame=f, group=nm)
        info[c["nombre"]] = {"duracion": round(c["dur"], 4), "bucle": c["bucle"],
                             "eventos": {kk: round(v, 4) for kk, v in c["eventos"].items()}}
        print("CLIP", c["nombre"], "%.2f s" % c["dur"], len(c["claves"]), "claves")
    arm.animation_data.action = None
    rig.reset()
    for act in bpy.data.actions:
        if act.name not in info:
            f0, f1 = act.frame_range
            info[act.name] = {"duracion": round((f1 - f0) / FPS, 4), "bucle": act.name in ("andar", "correr"),
                              "eventos": {}, "captura": True}

# ------------------------------------------------------------------ 4. renders de comprobación
CARA = Vector((0, -0.148, 1.728))


def poner_accion(nombre, t):
    act = bpy.data.actions[nombre]
    arm.animation_data.action = act
    try:
        arm.animation_data.action_slot = act.slots[0]
    except Exception:
        pass
    bpy.context.scene.frame_set(int(round(t * FPS)))
    bpy.context.view_layer.update()


if not SIN_RENDER:
    rig.reset()
    C.render_vistas(os.path.join(REND, "rig_T"), 1.9, vistas=[("frente", 0, 0), ("perfil", 90, 0), ("espalda", 180, 0)])
    # pose de esfuerzo: brazos arriba y delante, codos doblados, sentadilla, cabeza girada y mechones levantados
    d = NC.guardia_pose(NC.ESTILO) if not SIN_CLIPS else {}
    estres = {"cadera": (0.0, -0.22, 0.0), "cadera_giro": (8, 0, 0), "columna": (10, 0, 12), "cabeza": (0, 0, 30),
              "pie_i": {"pos": (0.18, 0, 0.06)}, "pie_d": {"pos": (-0.14, 0, 0.06)},
              "mano_i": {"pos": (0.2, 0.95, 0.25), "dedos": (0, 1, 0), "palma": (1, 0, 0), "cierre": 70},
              "mano_d": {"pos": (0.55, -0.15, -0.05), "codo": (0, -1, 1), "dedos": (1, 0, 0), "palma": (0, 0, -1), "cierre": 10}}
    rig.aplicar(estres)
    viento(rig, 1.5, 1.0)
    C.render_vistas(os.path.join(REND, "rig_estres"), 1.9, vistas=[("frente", 0, 0), ("perfil", 90, 0), ("espalda", 180, 0), ("tres_cuartos", 35, 10)])
    C.render_vistas(os.path.join(REND, "rig_estres_cerca"), 1.9, vistas=[("hombro", 50, 15)], extra_esc=0.6)
    rig.reset()
    if not SIN_CLIPS:
        for nombre, ts in [("reposo", [0.0, 3.6]), ("guardia", [0.0]), ("andar", [0.0, 0.25, 0.5]), ("correr", [0.1, 0.3]),
                           ("magia_culminante", [0.85, 1.6]), ("canalizar", [0.0, 0.3, 0.6, 0.9]), ("victoria", [1.4]),
                           ("derrota", [0.0]), ("defensa", [0.0]), ("ataque", [0.3, 0.45])]:
            for t in ts:
                poner_accion(nombre, t)
                C.render_vistas(os.path.join(REND, "clip_%s_%03d" % (nombre, int(t * 100))), 1.9,
                                vistas=[("frente", 0, 0), ("perfil", 90, 0), ("tres_cuartos", 35, 6)], res=600)
        for t in [0.0, 0.3, 0.6, 0.9]:
            poner_accion("canalizar", t)
            C.render_vistas(os.path.join(REND, "canalizar_cara_%03d" % int(t * 100)), 1.9, vistas=[("cerca", 25, 5)],
                            extra_esc=0.45)
        arm.animation_data.action = None
        rig.reset()

# ------------------------------------------------------------------ 5. exportar
os.makedirs(os.path.dirname(GLB), exist_ok=True)
if not SIN_CLIPS:
    json.dump({"heroe": "Nix", "fuente": "Meshy_AI_Silver_Sentinel_20261113 (FBX del usuario, reducido)", "fps": FPS,
               "altura_blender": round(rig.altura, 4), "largo_cristal": 0.5, "clips": info},
              open(JSON_CLIPS, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
# texturas a la resolución del GLB (las de 2048 quedan en la carpeta de trabajo)
# (guardadas como PNG con su resolución en el nombre y recargadas: el GLB lleva esas, con ese nombre)
for im in list(bpy.data.images):
    if im.name.startswith("nix_"):
        if im.size[0] != RES_GLB:
            im.scale(RES_GLB, RES_GLB)
        ruta = os.path.join(os.path.dirname(GLB), "%s_%d.png" % (im.name, RES_GLB))
        im.filepath_raw = ruta
        im.file_format = 'PNG'
        im.save()
        im.reload()
        print("TEXTURA", im.name, im.size[:], ruta)
bpy.ops.wm.save_as_mainfile(filepath=BLEND3)
for o in bpy.data.objects:
    o.select_set(o in (arm, cuerpo))
props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
op = dict(filepath=GLB, export_format='GLB', use_selection=True, export_animations=True,
          export_animation_mode='ACTIONS', export_force_sampling=True, export_apply=False)
for k, v in [("export_image_format", 'WEBP'), ("export_image_quality", 90), ("export_frame_range", False),
             ("export_anim_slide_to_zero", True), ("export_def_bones", False)]:
    if k in props:
        op[k] = v
bpy.ops.export_scene.gltf(**op)
print("GLB", GLB, os.path.getsize(GLB))
print("FIN")
