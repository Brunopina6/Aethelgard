# Invocación cinematográfica de Érebo (V12, 14/11/2026) — docs/v12/EREBO_CINEMATICA_V12.md
#   blender -b --factory-startup -P cinematica_erebo.py -- <proyecto aethelgard> <salida> [version=completa|abreviada]
#           [etapa=mano|fotos|planos|video] [desde=s] [hasta=s] [res=1280x720] [muestras=n] [cada=n]
# Construye TODA la escena desde los archivos del juego (sin .blend hechos a mano): Érebo (erebo_idle.fbx y sus clips de
# Mixamo), orbe, runas, suelo, niebla, luces, cámaras y partículas. La pose y las partículas las calcula este script en
# cada fotograma (manejador frame_change_pre): es determinista y se puede repetir.
# NADA del acto III: el orbe no lleva nada dentro y la gema del pecho no late con él.
import sys, os, math, random
sys.dont_write_bytecode = True
import bpy, bmesh
from mathutils import Vector, Matrix, Quaternion, Euler

a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
P = a[0] if a else "D:/Aethelgard_v12/aethelgard"
SALIDA = a[1] if len(a) > 1 else "C:/tmp/erebo_cine"
OPC = {k: v for k, v in (x.split("=", 1) for x in a[2:] if "=" in x)}
VERSION = OPC.get("version", "completa")
ETAPA = OPC.get("etapa", "fotos")
FPS = 30
RES = tuple(int(x) for x in OPC.get("res", "1280x720").split("x"))

# ------------------------------------------------------------------ tiempos (segundos) de cada versión (doc §2 y §3)
if VERSION == "abreviada":
    T = dict(fin=6.8, P1=0.0, P2=0.8, P3=1.8, P4=3.0, P5=4.2, P6=6.3,
             luz_orbe=0.0, runas=0.15, latidos=[0.1, 0.55], vibra=0.5,
             sombra=None, manos=None, alzarse=None, cara=0.8, cara_fin=1.8,
             alcanza=1.8, cierra=2.25, agarre=2.6, congela=0.15, venas=2.75,
             absorbe=3.0, sacude=[3.5], orbe_muerto=4.1,
             comprime=4.2, quieto=4.9, libera=5.15, haz=6.3, destello=6.55)
else:
    T = dict(fin=20.0, P1=0.0, P2=3.8, P3=8.0, P4=11.6, P5=15.4, P6=19.0,
             luz_orbe=0.6, runas=2.0, latidos=[0.3, 1.4, 2.4, 3.1, 3.6], vibra=3.0,
             sombra=3.8, manos=3.8, alzarse=5.4, cara=6.8, cara_fin=8.0,
             alcanza=8.0, cierra=9.2, agarre=9.85, congela=0.25, venas=10.1,
             absorbe=11.6, sacude=[12.5, 13.8], orbe_muerto=15.0,
             comprime=15.4, quieto=16.4, libera=17.0, haz=19.0, destello=19.7)


def fr(s):
    return int(round(s * FPS)) + 1


def suave(x):
    x = min(max(x, 0.0), 1.0)
    return x * x * (3 - 2 * x)


def suave2(x):                      # más lento al llegar (frenada de cine)
    x = min(max(x, 0.0), 1.0)
    return 1 - (1 - x) ** 3


def tramo(t, t0, t1):
    return 0.0 if t1 <= t0 else min(max((t - t0) / (t1 - t0), 0.0), 1.0)


bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.fps = FPS
sc.frame_start = 1
sc.frame_end = fr(T["fin"]) - 1

# ------------------------------------------------------------------ Érebo
ALTO = 1.6


def importar(fbx):
    antes = set(bpy.data.objects)
    acts = set(bpy.data.actions)
    bpy.ops.import_scene.fbx(filepath=os.path.join(P, fbx))
    nuevos = [o for o in bpy.data.objects if o not in antes]
    arm = [o for o in nuevos if o.type == 'ARMATURE'][0]
    act = [x for x in bpy.data.actions if x not in acts]
    return arm, [o for o in nuevos if o.type == 'MESH'], nuevos, act


ere, ere_m, _, _ = importar("erebo_idle.fbx")
cuerpo = ere_m[0]
bpy.context.view_layer.update()
zs = [(ere.matrix_world @ b.head_local).z for b in ere.data.bones]
ere.scale = ere.scale * (ALTO / (max(zs) - min(zs)))
bpy.context.view_layer.update()
zs = [(ere.matrix_world @ b.head_local).z for b in ere.data.bones]
ere.location.z -= min(zs)
bpy.context.view_layer.update()
HUESOS = [b.name for b in ere.data.bones]
for pb in ere.pose.bones:
    pb.rotation_mode = 'QUATERNION'


# Clips: se muestrean una vez (rotación local de cada hueso y posición de las caderas por fotograma).
def muestrear(arm, act):
    arm.animation_data.action = act
    if hasattr(arm.animation_data, "action_slot") and act.slots:
        arm.animation_data.action_slot = act.slots[0]
    f0, f1 = int(act.frame_range[0]), int(act.frame_range[1])
    datos = []
    for i in range(f0, f1 + 1):
        sc.frame_set(i)
        datos.append({pb.name: (pb.rotation_quaternion.copy(), pb.location.copy()) for pb in arm.pose.bones})
    return datos


CLIP = {}
CLIP["reposo"] = muestrear(ere, ere.animation_data.action)
for nombre, fbx in (("coger", "erebo_coger.fbx"), ("salir", "erebo_salir.fbx"), ("conjuro", "erebo_conjuro.fbx")):
    arm2, mallas2, nuevos2, acts2 = importar(fbx)
    CLIP[nombre] = muestrear(arm2, arm2.animation_data.action)
    for o in nuevos2:
        bpy.data.objects.remove(o, do_unlink=True)
ere.animation_data.action = None
for pb in ere.pose.bones:
    pb.rotation_quaternion = Quaternion()
    pb.location = Vector()
print("CLIPS", {k: len(v) for k, v in CLIP.items()})


def clip(nombre, s):
    """Pose del clip en el segundo s (interpolada entre fotogramas; se queda en el último)."""
    d = CLIP[nombre]
    x = min(max(s * FPS, 0.0), len(d) - 1.0)
    i = int(x); j = min(i + 1, len(d) - 1); k = x - i
    if k < 1e-4:
        return d[i]
    return {h: (d[i][h][0].slerp(d[j][h][0], k), d[i][h][1].lerp(d[j][h][1], k)) for h in d[i]}


def mezcla(p1, p2, k):
    if k <= 0.0:
        return p1
    if k >= 1.0:
        return p2
    return {h: (p1[h][0].slerp(p2[h][0], k), p1[h][1].lerp(p2[h][1], k)) for h in p1}


DEDOS = {d: ["mixamorig:RightHand%s%d" % (d, i) for i in (1, 2, 3)] for d in ("Thumb", "Index", "Middle", "Ring", "Pinky")}
MANO = "mixamorig:RightHand"


def potencia(q, t):
    """q^t (t puede ser > 1 o < 0: más cerrado o más abierto que el clip)."""
    eje, ang = q.to_axis_angle()
    return Quaternion(eje, ang * t)


# Dedos abiertos y cerrados del clip «coger» (lo usa la mano derecha); cada dedo tiene su propio cierre t.
ABIERTA = clip("coger", 0.5)
CERRADA = clip("coger", 1.25)
DELTA = {h: ABIERTA[h][0].inverted() @ CERRADA[h][0] for d in DEDOS.values() for h in d}


def dedos(pose, cierre):
    for d, hs in DEDOS.items():
        t = cierre.get(d, 0.0)
        for h in hs:
            pose[h] = (ABIERTA[h][0] @ potencia(DELTA[h], t), pose[h][1])
    return pose


def girar(pose, hueso, eje, grados):
    q, l = pose[hueso]
    pose[hueso] = (q @ Quaternion(Vector(eje), math.radians(grados)), l)


PIES = ["mixamorig:LeftFoot", "mixamorig:RightFoot", "mixamorig:LeftToeBase", "mixamorig:RightToeBase"]
bpy.context.view_layer.update()
Z_PIES = min((ere.matrix_world @ ere.pose.bones[h].head).z for h in PIES)   # en reposo (pose de descanso)
Z_ERE = ere.location.z


def aplicar(pose, suelo=True):
    """Pone la pose (rotaciones de los clips; las caderas solo se mueven en horizontal) y apoya los pies en el suelo."""
    for pb in ere.pose.bones:
        q, l = pose[pb.name]
        pb.rotation_quaternion = q
    if suelo:
        ere.location.z = Z_ERE
        bpy.context.view_layer.update()
        z = min((ere.matrix_world @ ere.pose.bones[h].head).z for h in PIES)
        ere.location.z += Z_PIES - z


# ------------------------------------------------------------------ geometría de la mano (medida, no a ojo)
def vgrupo_vertices(nombres, minimo=0.5):
    idx = {cuerpo.vertex_groups[n].index for n in nombres if n in cuerpo.vertex_groups}
    r = []
    for v in cuerpo.data.vertices:
        s = sum(g.weight for g in v.groups if g.group in idx)
        if s >= minimo:
            r.append(v.index)
    return r


VERT_DEDO = {d: vgrupo_vertices(hs + [hs[-1][:-1] + "4"]) for d, hs in DEDOS.items()}
VERT_PALMA = vgrupo_vertices([MANO], 0.6)


def malla_eval():
    dg = bpy.context.evaluated_depsgraph_get()
    ob = cuerpo.evaluated_get(dg)
    me = ob.to_mesh()
    mw = ob.matrix_world.copy()
    co = [mw @ v.co for v in me.vertices]
    ob.to_mesh_clear()
    return co


def hueso_mundo(h):
    return ere.matrix_world @ ere.pose.bones[h].matrix


# Pose de referencia: reposo con los dedos abiertos del clip; se mide la mano en su propio espacio.
pose_ref = dedos(dict(clip("reposo", 0.0)), {})
aplicar(pose_ref)
bpy.context.view_layer.update()
co = malla_eval()
Mh = hueso_mundo(MANO)
Mh_inv = Mh.inverted()
punta = sum((co[i] for i in VERT_DEDO["Middle"]), Vector()) / max(1, len(VERT_DEDO["Middle"]))
largo_mano = (punta - Mh.translation).length
# Normal de la palma (en el espacio del hueso): hacia donde se desplazan las puntas al cerrar el clip.
aplicar(dedos(dict(pose_ref), {d: 1.0 for d in DEDOS}))
bpy.context.view_layer.update()
co2 = malla_eval()
mov = Vector()
for d in ("Index", "Middle", "Ring", "Pinky"):
    for i in VERT_DEDO[d]:
        mov += co2[i] - co[i]
nl = (Mh_inv.to_3x3() @ mov)
nl.y = 0.0
nl.normalize()
pal = [Mh_inv @ co[i] for i in VERT_PALMA]
proy = sorted(p.dot(nl) for p in pal)
m1_local = Mh_inv @ (ere.matrix_world @ ere.pose.bones["mixamorig:RightHandMiddle1"].head)
palma_local = m1_local * 0.7                                            # hacia los nudillos (el hueco de la palma)
palma_local = palma_local + nl * (proy[int(len(proy) * 0.92)] - palma_local.dot(nl))    # sobre la piel de la palma
ESC = ere.matrix_world.to_scale().x * ere.pose.bones[MANO].matrix.to_scale().x
R_ORBE = float(OPC.get("radio", "0.55")) * largo_mano      # (largo_mano en metros del mundo)
print("MANO largo %.3f m  normal local %s  palma local %s  radio orbe %.3f m" % (largo_mano, tuple(round(x, 2) for x in nl),
      tuple(round(x, 3) for x in palma_local), R_ORBE))

# ------------------------------------------------------------------ dónde está el orbe y cómo llega la mano
hombro = hueso_mundo("mixamorig:RightArm").translation
codo = hueso_mundo("mixamorig:RightForeArm").translation
largo_brazo = (codo - hombro).length + (Mh.translation - codo).length
FRENTE = Vector((0, -1, 0))       # Érebo mira a -Y
DERECHA = Vector((-1, 0, 0))      # su derecha
ARRIBA = Vector((0, 0, 1))
O = hombro + (FRENTE * 0.80 + DERECHA * 0.10 + ARRIBA * 0.05).normalized() * (largo_brazo * 0.80 + largo_mano * 0.45)
O_INICIO = O.copy()
print("ORBE en %s (hombro %s, brazo %.3f m)" % (tuple(round(x, 3) for x in O), tuple(round(x, 3) for x in hombro), largo_brazo))


def base_mano(dir_dedos, normal):
    """Rotación del hueso de la mano (mundo) con los dedos hacia dir_dedos y la palma hacia normal."""
    e1 = Vector((0, 1, 0)); e2 = (nl - e1 * nl.dot(e1)).normalized(); e3 = e1.cross(e2)
    E1 = dir_dedos.normalized(); E2 = (normal - E1 * normal.dot(E1)).normalized(); E3 = E1.cross(E2)
    return Matrix((E1, E2, E3)).transposed() @ Matrix((e1, e2, e3))


HUECO = 0.004
# Agarre: palma hacia el orbe, desde arriba y por detrás (la cámara del P3 ve los dedos envolverlo).
N_AGARRE = (FRENTE * 0.55 - ARRIBA * 0.75 + DERECHA * 0.15).normalized()
D_AGARRE = (FRENTE * 0.75 + ARRIBA * 0.45 - DERECHA * 0.2).normalized()
ROT_AGARRE = base_mano(D_AGARRE, N_AGARRE)


def cabeza_mano(rot, centro, hueco):
    """Dónde va el hueso de la mano para que la piel de la palma quede a «hueco» de la esfera del orbe."""
    palma_rel = rot @ (palma_local * ESC_H)
    n_w = rot @ nl
    return centro - n_w * (R_ORBE + hueco) - palma_rel


ESC_H = ere.matrix_world.to_scale().x * ere.pose.bones[MANO].matrix.to_scale().x
OBJ_AGARRE = cabeza_mano(ROT_AGARRE, O, HUECO)

# objetivos del IK (vacíos) y restricciones
obj_mano = bpy.data.objects.new("objetivo_mano", None)
polo = bpy.data.objects.new("polo_codo", None)
for o in (obj_mano, polo):
    sc.collection.objects.link(o)
ik = ere.pose.bones["mixamorig:RightForeArm"].constraints.new('IK')
ik.target = obj_mano
ik.pole_target = polo
ik.pole_angle = math.radians(-90)
ik.chain_count = 2
ik.use_tail = True
cr = ere.pose.bones[MANO].constraints.new('COPY_ROTATION')
cr.target = obj_mano
polo.location = hombro + DERECHA * 0.6 - ARRIBA * 0.5 + FRENTE * 0.1

# ------------------------------------------------------------------ dedos que se cierran SIN atravesar el orbe
ORDEN = ["Pinky", "Ring", "Middle", "Index", "Thumb"]
CIERRE_MAX = {}


def holgura(dedo, co):
    return min((co[i] - O).length for i in VERT_DEDO[dedo]) - R_ORBE


def poner_mano(rot, cabeza):
    obj_mano.matrix_world = Matrix.Translation(cabeza) @ rot.to_4x4()


ik.influence = 1.0; cr.influence = 1.0
INICIO_DEDO = {d: (-0.6 if d == "Thumb" else -0.2) for d in DEDOS}


def resolver(rot, along, hueco, paso=0.1, lado=0.0):
    """Cierra cada dedo hasta tocar (3 mm). Devuelve (cierres, holguras finales, válida)."""
    eje_x = rot @ Vector((0, 1, 0)).cross(nl).normalized()
    cab = cabeza_mano(rot, O, hueco) - (rot @ Vector((0, 1, 0))) * along - eje_x * lado
    poner_mano(rot, cab)
    cierre = dict(INICIO_DEDO)
    aplicar(dedos(dict(pose_ref), cierre), suelo=False)
    bpy.context.view_layer.update()
    co = malla_eval()
    if min(holgura(d, co) for d in DEDOS) < 0.004 or min((co[i] - O).length for i in VERT_PALMA) - R_ORBE < 0.002:
        return None
    for d in ORDEN:
        t = cierre[d]
        while t < 2.3:
            cierre[d] = t + paso
            aplicar(dedos(dict(pose_ref), cierre), suelo=False)
            bpy.context.view_layer.update()
            if holgura(d, malla_eval()) < 0.003:
                break
            t += paso
        cierre[d] = t
    aplicar(dedos(dict(pose_ref), cierre), suelo=False)
    bpy.context.view_layer.update()
    co = malla_eval()
    return cierre, {d: holgura(d, co) for d in DEDOS}, cab


aplicar(pose_ref)                       # (los pies en el suelo; luego el IK no mueve el cuerpo)
mejor = None
for roll in (-30, -15, 0, 15, 30):
    for along in (0.0, 0.01, 0.02, 0.03):
        for lado in (-0.012, -0.006, 0.0, 0.006, 0.012):
            hueco = 0.004
            rot = ROT_AGARRE @ Matrix.Rotation(math.radians(roll), 3, 'Y')
            r = resolver(rot, along, hueco, 0.15, lado)
            if r is None:
                continue
            nota = sum(min(max(h, 0.0), 0.03) for h in r[1].values())
            if mejor is None or nota < mejor[0]:
                mejor = (nota, roll, along, hueco, rot, lado)
print("BUSQUEDA mejor", None if mejor is None else (round(mejor[0], 4), mejor[1], mejor[2], mejor[3], mejor[5]))
ROT_AGARRE = mejor[4]
CIERRE_MAX, _h, OBJ_AGARRE = resolver(ROT_AGARRE, mejor[2], mejor[3], 0.05, mejor[5])
poner_mano(ROT_AGARRE, OBJ_AGARRE)
aplicar(dedos(dict(pose_ref), CIERRE_MAX), suelo=False)
bpy.context.view_layer.update()
co3 = malla_eval()
err_ik = (hueso_mundo(MANO).translation - OBJ_AGARRE).length
print("CIERRE por dedo", {d: round(v, 2) for d, v in CIERRE_MAX.items()})
print("HOLGURA final (m)", {d: round(holgura(d, co3), 4) for d in DEDOS},
      "palma %.4f" % (min((co3[i] - O).length for i in VERT_PALMA) - R_ORBE), "error IK %.4f m" % err_ik)


# ------------------------------------------------------------------ material del orbe (provisional para la prueba)
def mat_emisivo(nombre, color, fuerza, alfa=1.0):
    m = bpy.data.materials.new(nombre)
    bs = m.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value = (*color, 1)
    bs.inputs["Emission Color"].default_value = (*color, 1)
    bs.inputs["Emission Strength"].default_value = fuerza
    bs.inputs["Alpha"].default_value = alfa
    return m


# ================================================================== a partir de aquí, la escena
ik.influence = 0.0; cr.influence = 0.0
ROT_PREVIA = ROT_AGARRE @ Matrix.Rotation(math.radians(-25), 3, 'X')
OBJ_PREVIO = OBJ_AGARRE + (ROT_AGARRE @ nl) * (-0.07) + ARRIBA * 0.03 - FRENTE * 0.02     # mano alzada antes de tender
poner_mano(ROT_AGARRE, OBJ_AGARRE)
aplicar(dedos(dict(pose_ref), CIERRE_MAX), suelo=False)
ik.influence = 1.0; cr.influence = 1.0
bpy.context.view_layer.update()
M_ORBE_EN_MANO = hueso_mundo(MANO).inverted() @ Matrix.Translation(O)
ik.influence = 0.0; cr.influence = 0.0
APERTURA = {d: (-0.6 if d == "Thumb" else -0.35) for d in DEDOS}
aplicar(pose_ref)
bpy.context.view_layer.update()
_pecho0 = hueso_mundo("mixamorig:Spine2").translation.copy()
OBJ_PUNO_C = _pecho0 + FRENTE * 0.13 + DERECHA * 0.03 + ARRIBA * 0.02          # el puño ante el pecho
ROT_PUNO = base_mano((ARRIBA * 0.7 - DERECHA * 0.5).normalized(), -FRENTE)
OBJ_PUNO = OBJ_PUNO_C - ROT_PUNO @ (palma_local * ESC_H) - (ROT_PUNO @ nl) * 0.01
ROT_LIBERA = base_mano((ARRIBA * 0.85 + FRENTE * 0.25).normalized(), FRENTE)      # la palma hacia el enemigo
OBJ_LIBERA = hombro + FRENTE * (largo_brazo * 0.92) + ARRIBA * 0.04 + DERECHA * 0.02
PUNO = {d: (0.5 if d == "Thumb" else 1.55) for d in DEDOS}
RETRASO = {"Pinky": 0.0, "Ring": 0.08, "Middle": 0.16, "Index": 0.24, "Thumb": 0.30}


def f_salir(t):
    """Segundo del clip «salir» (fotograma 1 = 0 s) para el tiempo t de la cinemática."""
    if VERSION == "abreviada":
        return (184 + 26 * tramo(t, T["P2"], T["cara_fin"])) / FPS
    if t < T["P2"]:
        return (1 + 59 * t / T["P2"]) / FPS
    return (95 + 115 * tramo(t, T["P2"], T["P3"])) / FPS


def f_conjuro(t):
    if t < T["quieto"]:
        k = suave(tramo(t, T["comprime"], T["quieto"]))
        return (38 + 22 * k) / FPS
    if t < T["libera"]:
        return (60 + 2 * tramo(t, T["quieto"], T["libera"])) / FPS
    k = suave2(tramo(t, T["libera"], T["libera"] + 0.55))
    return (62 + 23 * k + 4 * tramo(t, T["libera"] + 0.55, T["fin"])) / FPS


def cierre_dedos(t):
    """Cierre de los dedos de la mano derecha (por dedo) en el tiempo t."""
    if t < T["alcanza"]:
        return None                                   # los del clip
    if t < T["cierra"]:
        k = suave(tramo(t, T["alcanza"], T["alcanza"] + 0.6))
        return {d: APERTURA[d] * k for d in DEDOS}
    if t < T["comprime"] + 0.3:
        r = {}
        dur = (T["agarre"] - T["cierra"]) - RETRASO["Thumb"]
        for d in DEDOS:
            k = suave2(tramo(t, T["cierra"] + RETRASO[d], T["cierra"] + RETRASO[d] + dur))
            v = APERTURA[d] + (CIERRE_MAX[d] - APERTURA[d]) * k
            if t > T["venas"]:                       # la energía hace temblar los dedos (solo abriendo: nunca atraviesan)
                v -= 0.035 * abs(math.sin(t * 37.0 + ORDEN.index(d) * 1.7))
            r[d] = v
        return r
    if t < T["libera"]:
        k = suave(tramo(t, T["comprime"] + 0.3, T["comprime"] + 0.7))
        return {d: CIERRE_MAX[d] + (PUNO[d] - CIERRE_MAX[d]) * k for d in DEDOS}
    k = suave2(tramo(t, T["libera"], T["libera"] + 0.18))
    return {d: PUNO[d] + (APERTURA[d] * 1.3 - PUNO[d]) * k for d in DEDOS}


# V12, Érebo híbrida (15/11): «cabeza=firme» (petición del usuario: «la cabeza tiene que estar de una forma imponente y
# segura de lo que hace»). Por defecto («original») todo es como el render del 14/11. Con «firme»:
#   · el cuello y la cabeza dejan de seguir el balanceo del clip de reposo («Thriller Idle», de zombi: la cabeza se
#     mece y cae a los lados) y quedan erguidos, con la barbilla algo alta;
#   · sin la inclinación «curiosa» de la cabeza al descubrir el orbe, sin agachar la cabeza sobre el puño al comprimir
#     (el pecho se cierra sobre el puño, la cabeza no), sin el tirón de cuello de las sacudidas (la espalda sí se
#     arquea, a la mitad) y sin el temblor de la quietud;
#   · mira el orbe con un leve gesto de barbilla hacia abajo mientras lo agarra (8°, sin ladear) y sube al absorber.
FIRME = OPC.get("cabeza", "original") == "firme"


def _pose_firme(t, pose):
    cuello, cab = "mixamorig:Neck", "mixamorig:Head"
    r = suave(tramo(t, T["cara"] - 0.4, T["cara"]))         # entra en 0,4 s, antes de que la cámara suba a la máscara
    for h in (cuello, cab):                                  # erguidos: casi la pose de descanso
        q, l = pose[h]
        pose[h] = (q.slerp(Quaternion(), 0.9 * r), l)
    alto = r
    if t >= T["comprime"]:                                   # comprime: el pecho sobre el puño, la cabeza alta
        enc = suave(tramo(t, T["comprime"], T["quieto"])) * (1 - suave2(tramo(t, T["libera"], T["libera"] + 0.15)))
        lib = suave2(tramo(t, T["libera"], T["libera"] + 0.15)) * (1 - 0.6 * suave(tramo(t, T["libera"] + 0.6, T["fin"])))
        girar(pose, "mixamorig:Spine1", (1, 0, 0), 4.0 * enc - 8.0 * lib)
        girar(pose, "mixamorig:Spine2", (1, 0, 0), 3.0 * enc - 6.0 * lib)
        girar(pose, cuello, (1, 0, 0), -4.0 * enc - 4.0 * lib)       # compensa: la mirada al frente
    sac = 0.0
    for ts in T["sacude"]:
        if t >= ts:
            x = t - ts
            sac += (x / 0.12 if x < 0.12 else math.exp(-(x - 0.12) / 0.5))
    if T["absorbe"] <= t < T["comprime"] + 0.5:              # se crece mientras absorbe (la espalda, no el cuello)
        lento = suave(tramo(t, T["absorbe"], T["orbe_muerto"]))
        girar(pose, "mixamorig:Spine1", (1, 0, 0), -3.0 * sac - 4.0 * lento)
        girar(pose, "mixamorig:Spine2", (1, 0, 0), -2.5 * sac - 3.0 * lento)
    if T["cara"] is not None:                                # mira el orbe al agarrarlo: barbilla abajo, sin ladear
        k = suave(tramo(t, T["alcanza"], T["agarre"])) * (1 - suave(tramo(t, T["absorbe"], T["absorbe"] + 0.8)))
        girar(pose, cab, (1, 0, 0), 8.0 * k)
        alto = r * (1.0 - k)
    girar(pose, cuello, (1, 0, 0), -5.0 * alto)               # la barbilla alta
    girar(pose, cab, (1, 0, 0), -3.0 * alto)
    c = cierre_dedos(t)
    if c is not None:
        pose = dedos(pose, c)
    return pose


def pose_en(t):
    salir = clip("salir", f_salir(t))
    if VERSION == "completa" and t < T["P3"]:
        pose = dict(salir)
    else:
        t0 = T["P3"] if VERSION == "completa" else T["cara_fin"]
        rep = clip("reposo", ((t - t0) % (130 / FPS)))
        pose = mezcla(salir, rep, suave(tramo(t, t0, t0 + 0.5)))
    if FIRME and t >= T["cara"] - 0.4:                   # (antes, mientras se levanta, la pose del clip «salir»)
        return _pose_firme(t, pose)
    if t >= T["comprime"]:                                # se encorva sobre el puño; al liberar, se yergue de golpe
        enc = suave(tramo(t, T["comprime"], T["quieto"])) * (1 - suave2(tramo(t, T["libera"], T["libera"] + 0.15)))
        lib = suave2(tramo(t, T["libera"], T["libera"] + 0.15)) * (1 - 0.6 * suave(tramo(t, T["libera"] + 0.6, T["fin"])))
        girar(pose, "mixamorig:Spine1", (1, 0, 0), 9.0 * enc - 8.0 * lib)
        girar(pose, "mixamorig:Spine2", (1, 0, 0), 7.0 * enc - 6.0 * lib)
        girar(pose, "mixamorig:Neck", (1, 0, 0), 12.0 * enc - 6.0 * lib)
    # sacudidas al absorber: la espalda se arquea, la cabeza sube y vuelve
    sac = 0.0
    for ts in T["sacude"]:
        if t >= ts:
            x = t - ts
            sac += (x / 0.08 if x < 0.08 else math.exp(-(x - 0.08) / 0.45))
    if T["absorbe"] <= t < T["comprime"] + 0.5:
        lento = suave(tramo(t, T["absorbe"], T["orbe_muerto"]))          # se crece mientras absorbe
        girar(pose, "mixamorig:Spine1", (1, 0, 0), -6.0 * sac - 4.0 * lento)
        girar(pose, "mixamorig:Spine2", (1, 0, 0), -5.0 * sac - 3.0 * lento)
        girar(pose, "mixamorig:Neck", (1, 0, 0), -7.0 * sac - 5.0 * lento)
    # la cabeza: se inclina con curiosidad al descubrir el orbe y lo mira
    if T["cara"] is not None:
        k = suave(tramo(t, T["cara"] + 0.2, T["cara_fin"])) * (1 - suave(tramo(t, T["agarre"], T["agarre"] + 0.6)))
        girar(pose, "mixamorig:Head", (0, 0, 1), 9.0 * k)
        girar(pose, "mixamorig:Head", (1, 0, 0), 8.0 * suave(tramo(t, T["alcanza"], T["agarre"])) * (1 - suave(tramo(t, T["absorbe"], T["absorbe"] + 0.8))))
    # quietud: apenas un temblor
    if T["quieto"] <= t < T["libera"]:
        girar(pose, "mixamorig:Spine2", (0, 0, 1), 0.4 * math.sin(t * 61.0))
    c = cierre_dedos(t)
    if c is not None:
        pose = dedos(pose, c)
    return pose


def mano_en(t):
    """(influencia del IK, rotación y posición del objetivo de la mano derecha)."""
    if t < T["alcanza"]:
        return 0.0, ROT_PREVIA, OBJ_PREVIO
    inf = suave(tramo(t, T["alcanza"], T["alcanza"] + 0.55))
    k = suave2(tramo(t, T["alcanza"] + 0.35, T["agarre"] - 0.05))
    rot = ROT_PREVIA.to_quaternion().slerp(ROT_AGARRE.to_quaternion(), k).to_matrix()
    pos = OBJ_PREVIO.lerp(OBJ_AGARRE, k)
    if t >= T["agarre"]:                                 # empujón del agarre y, al absorber, la mano se acerca al pecho
        x = t - T["agarre"]
        pos = pos + (ROT_AGARRE @ nl) * 0.006 * math.exp(-x / 0.12) * min(1.0, x / 0.03)
        lleva = suave(tramo(t, T["absorbe"], T["orbe_muerto"]))
        pos = pos - FRENTE * 0.05 * lleva + ARRIBA * 0.03 * lleva
        for ts in T["sacude"]:
            if t >= ts:
                y = t - ts
                pos = pos + ARRIBA * 0.012 * (y / 0.06 if y < 0.06 else math.exp(-(y - 0.06) / 0.3))
    if t >= T["comprime"]:
        k = suave(tramo(t, T["comprime"], T["comprime"] + 0.6))
        rot = rot.to_quaternion().slerp(ROT_PUNO.to_quaternion(), k).to_matrix()
        pos = pos.lerp(OBJ_PUNO, k)
        if T["quieto"] <= t < T["libera"]:
            pos = pos + Vector((math.sin(t * 83), math.sin(t * 71), math.sin(t * 97))) * 0.0008
    if t >= T["libera"]:
        k = suave2(tramo(t, T["libera"], T["libera"] + 0.13))
        rot = rot.to_quaternion().slerp(ROT_LIBERA.to_quaternion(), k).to_matrix()
        pos = pos.lerp(OBJ_LIBERA, k) - FRENTE * 0.03 * suave(tramo(t, T["libera"] + 0.3, T["fin"]))
    return inf, rot, pos


def posar(t):
    aplicar(pose_en(t))
    inf, rot, pos = mano_en(t)
    ik.influence = inf
    cr.influence = inf
    poner_mano(rot, pos)
    bpy.context.view_layer.update()


def punto_palma():
    Mw = hueso_mundo(MANO)
    return Mw @ (palma_local) + (Mw.to_3x3().normalized() @ nl) * 0.012


# ------------------------------------------------------------------ materiales
def nodo(nt, tipo, x=0, y=0, **kw):
    n = nt.nodes.new(tipo)
    n.location = (x, y)
    for k, v in kw.items():
        n.inputs[k].default_value = v
    return n


def mat_brillo(nombre, color, fuerza, blend=True):
    """Emisión pura con transparencia aditiva (runas, destellos). Devuelve (material, nodo de emisión)."""
    m = bpy.data.materials.new(nombre)
    nt = m.node_tree
    nt.nodes.clear()
    out = nodo(nt, "ShaderNodeOutputMaterial", 600, 0)
    em = nodo(nt, "ShaderNodeEmission", 200, 100, Color=(*color, 1), Strength=fuerza)
    tr = nodo(nt, "ShaderNodeBsdfTransparent", 200, -100)
    ad = nodo(nt, "ShaderNodeAddShader", 400, 0)
    nt.links.new(em.outputs[0], ad.inputs[0]); nt.links.new(tr.outputs[0], ad.inputs[1])
    nt.links.new(ad.outputs[0], out.inputs[0])
    if blend:
        m.surface_render_method = 'BLENDED'
    m.use_backface_culling = False
    return m, em


# --- el orbe: energía que se arremolina, borde luminoso (Fresnel), grietas y estado «muerto»
bpy.ops.mesh.primitive_uv_sphere_add(radius=R_ORBE, segments=64, ring_count=32, location=O)
orbe = bpy.context.object
orbe.name = "orbe"
bpy.ops.object.shade_smooth()
m_orbe = bpy.data.materials.new("orbe")
nt = m_orbe.node_tree
nt.nodes.clear()
out = nodo(nt, "ShaderNodeOutputMaterial", 1400, 0)
tc = nodo(nt, "ShaderNodeTexCoord", -900, 0)
V_TIEMPO = nodo(nt, "ShaderNodeValue", -900, 300)
V_LUZ = nodo(nt, "ShaderNodeValue", -900, 400)
V_GRIETA = nodo(nt, "ShaderNodeValue", -900, 500)
V_MAG = nodo(nt, "ShaderNodeValue", -900, 700)
ruido = nodo(nt, "ShaderNodeTexNoise", -600, 0, Scale=3.5, Detail=6.0, Roughness=0.62, Distortion=1.6)
ruido.noise_dimensions = '4D'
nt.links.new(tc.outputs["Generated"], ruido.inputs["Vector"])        # (coordenadas 0-1: el remolino se ve a cualquier tamaño)
nt.links.new(V_TIEMPO.outputs[0], ruido.inputs["W"])
rampa = nodo(nt, "ShaderNodeValToRGB", -350, 0)
rampa.color_ramp.elements[0].position = 0.35; rampa.color_ramp.elements[0].color = (0.05, 0.0, 0.12, 1)
rampa.color_ramp.elements[1].position = 0.75; rampa.color_ramp.elements[1].color = (0.62, 0.28, 1.0, 1)
e = rampa.color_ramp.elements.new(0.55); e.color = (0.25, 0.05, 0.55, 1)
nt.links.new(ruido.outputs["Fac"], rampa.inputs[0])
mezc = nodo(nt, "ShaderNodeMix", -100, 0); mezc.data_type = 'RGBA'; mezc.blend_type = 'HUE'
mezc.inputs[7].default_value = (1.0, 0.16, 0.45, 1)
nt.links.new(V_MAG.outputs[0], mezc.inputs[0]); nt.links.new(rampa.outputs[0], mezc.inputs[6])
fres = nodo(nt, "ShaderNodeLayerWeight", -350, -250, Blend=0.35)
borde = nodo(nt, "ShaderNodeMath", -100, -250); borde.operation = 'POWER'; borde.inputs[1].default_value = 1.6
nt.links.new(fres.outputs["Facing"], borde.inputs[0])
f_em = nodo(nt, "ShaderNodeMath", 150, -250); f_em.operation = 'MULTIPLY_ADD'
f_em.inputs[1].default_value = 4.0; f_em.inputs[2].default_value = 0.7
nt.links.new(borde.outputs[0], f_em.inputs[0])
f_luz = nodo(nt, "ShaderNodeMath", 350, -250); f_luz.operation = 'MULTIPLY'
nt.links.new(f_em.outputs[0], f_luz.inputs[0]); nt.links.new(V_LUZ.outputs[0], f_luz.inputs[1])
em_orbe = nodo(nt, "ShaderNodeEmission", 600, 0)
nt.links.new(mezc.outputs[2], em_orbe.inputs["Color"]); nt.links.new(f_luz.outputs[0], em_orbe.inputs["Strength"])
vor = nodo(nt, "ShaderNodeTexVoronoi", -600, -550, Scale=6.5, Randomness=0.85)
vor.feature = 'DISTANCE_TO_EDGE'
nt.links.new(tc.outputs["Generated"], vor.inputs["Vector"])
lin0 = nodo(nt, "ShaderNodeMath", -350, -550); lin0.operation = 'LESS_THAN'; lin0.inputs[1].default_value = 0.035
nt.links.new(vor.outputs["Distance"], lin0.inputs[0])
avance = nodo(nt, "ShaderNodeTexNoise", -600, -800, Scale=2.2, Detail=2.0)
nt.links.new(tc.outputs["Generated"], avance.inputs["Vector"])
av_m = nodo(nt, "ShaderNodeMath", -350, -800); av_m.operation = 'MULTIPLY'; av_m.inputs[1].default_value = 0.85
nt.links.new(V_GRIETA.outputs[0], av_m.inputs[0])
av_lt = nodo(nt, "ShaderNodeMath", -200, -800); av_lt.operation = 'LESS_THAN'
nt.links.new(avance.outputs["Fac"], av_lt.inputs[0]); nt.links.new(av_m.outputs[0], av_lt.inputs[1])
lin = nodo(nt, "ShaderNodeMath", -100, -550); lin.operation = 'MULTIPLY'
nt.links.new(lin0.outputs[0], lin.inputs[0]); nt.links.new(av_lt.outputs[0], lin.inputs[1])
em_gr = nodo(nt, "ShaderNodeEmission", 600, -550, Color=(1.0, 0.55, 0.85, 1), Strength=12.0)
gr_mul = nodo(nt, "ShaderNodeMath", 350, -650); gr_mul.operation = 'MULTIPLY'
nt.links.new(lin.outputs[0], gr_mul.inputs[0]); nt.links.new(V_LUZ.outputs[0], gr_mul.inputs[1])
gr_min = nodo(nt, "ShaderNodeMath", 480, -650); gr_min.operation = 'MINIMUM'; gr_min.inputs[1].default_value = 1.0
nt.links.new(gr_mul.outputs[0], gr_min.inputs[0])
mix_gr = nodo(nt, "ShaderNodeMixShader", 850, -200)
nt.links.new(gr_min.outputs[0], mix_gr.inputs[0]); nt.links.new(em_orbe.outputs[0], mix_gr.inputs[1]); nt.links.new(em_gr.outputs[0], mix_gr.inputs[2])
vidrio = nodo(nt, "ShaderNodeBsdfPrincipled", 850, 250)
vidrio.inputs["Base Color"].default_value = (0.02, 0.01, 0.04, 1)
vidrio.inputs["Roughness"].default_value = 0.08
vidrio.inputs["Coat Weight"].default_value = 1.0
suma = nodo(nt, "ShaderNodeAddShader", 1100, 0)
nt.links.new(vidrio.outputs[0], suma.inputs[0]); nt.links.new(mix_gr.outputs[0], suma.inputs[1])
nt.links.new(suma.outputs[0], out.inputs[0])
orbe.data.materials.append(m_orbe)

luz_orbe_d = bpy.data.lights.new("luz_orbe", 'POINT')
luz_orbe_d.shadow_soft_size = R_ORBE * 0.9
luz_orbe = bpy.data.objects.new("luz_orbe", luz_orbe_d); sc.collection.objects.link(luz_orbe)

# --- runas: anillo que orbita el orbe y círculo en el suelo (glifos rúnicos de Segoe UI Historic)
FUENTE = bpy.data.fonts.load("C:/Windows/Fonts/seguihis.ttf")
GLIFOS = "ᚠᚢᚦᚨᚱᚲᚷᚹᚺᚾᛁᛃᛇᛈᛉᛊᛏᛒᛖᛗᛚᛜᛞᛟ"


def glifo(ch, tam, mat):
    cu = bpy.data.curves.new("runa", 'FONT')
    cu.body = ch; cu.font = FUENTE; cu.size = tam; cu.align_x = 'CENTER'; cu.align_y = 'CENTER'
    ob = bpy.data.objects.new("runa", cu); sc.collection.objects.link(ob)
    cu.materials.append(mat)
    return ob


RUNAS = []
for i in range(12):
    m_i, em_i = mat_brillo("runa_%d" % i, (0.72, 0.42, 1.0), 0.0)
    ob = glifo(GLIFOS[i * 2 % len(GLIFOS)], R_ORBE * 0.9, m_i)
    RUNAS.append((ob, em_i, i))
m_circ, em_circ = mat_brillo("circulo", (0.55, 0.3, 1.0), 0.0)
R_CIRC = 0.75
for i in range(28):
    ang = i / 28 * math.tau
    ob = glifo(GLIFOS[i % len(GLIFOS)], 0.085, m_circ)
    ob.location = (O.x + math.cos(ang) * R_CIRC, O.y + math.sin(ang) * R_CIRC, 0.004)
    ob.rotation_euler = (0, 0, ang - math.pi / 2)
for rr in (R_CIRC - 0.09, R_CIRC + 0.09, 0.34):
    bpy.ops.mesh.primitive_torus_add(major_radius=rr, minor_radius=0.004, major_segments=128, minor_segments=6,
                                     location=(O.x, O.y, 0.003))
    t_ob = bpy.context.object
    t_ob.scale.z = 0.2
    t_ob.data.materials.append(m_circ)

# --- suelo: obsidiana mojada; sombras que se extienden como raíces (P4)
bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
suelo = bpy.context.object
m_suelo = bpy.data.materials.new("suelo")
nt = m_suelo.node_tree
bs = nt.nodes.get("Principled BSDF")
bs.inputs["Base Color"].default_value = (0.012, 0.010, 0.018, 1)
bs.inputs["Specular IOR Level"].default_value = 0.6
tc = nodo(nt, "ShaderNodeTexCoord", -1200, 0)
rug = nodo(nt, "ShaderNodeTexNoise", -900, 200, Scale=6.0, Detail=8.0, Roughness=0.6)
nt.links.new(tc.outputs["Object"], rug.inputs["Vector"])
rr_ = nodo(nt, "ShaderNodeMapRange", -650, 200)
rr_.inputs["To Min"].default_value = 0.06; rr_.inputs["To Max"].default_value = 0.4
nt.links.new(rug.outputs["Fac"], rr_.inputs["Value"]); nt.links.new(rr_.outputs["Result"], bs.inputs["Roughness"])
V_SOMBRA = nodo(nt, "ShaderNodeValue", -1200, -400)
sep = nodo(nt, "ShaderNodeSeparateXYZ", -900, -200)
nt.links.new(tc.outputs["Object"], sep.inputs[0])
cmb = nodo(nt, "ShaderNodeCombineXYZ", -700, -200)
nt.links.new(sep.outputs[0], cmb.inputs[0]); nt.links.new(sep.outputs[1], cmb.inputs[1])
largo = nodo(nt, "ShaderNodeVectorMath", -500, -200); largo.operation = 'LENGTH'
nt.links.new(cmb.outputs[0], largo.inputs[0])
raiz = nodo(nt, "ShaderNodeTexNoise", -700, -450, Scale=2.2, Detail=4.0, Roughness=0.7, Distortion=0.6)
nt.links.new(tc.outputs["Object"], raiz.inputs["Vector"])
rmul = nodo(nt, "ShaderNodeMath", -450, -450); rmul.operation = 'MULTIPLY'; rmul.inputs[1].default_value = 1.6
nt.links.new(raiz.outputs["Fac"], rmul.inputs[0])
dist = nodo(nt, "ShaderNodeMath", -250, -300); dist.operation = 'ADD'
nt.links.new(largo.outputs["Value"], dist.inputs[0]); nt.links.new(rmul.outputs[0], dist.inputs[1])
frente_s = nodo(nt, "ShaderNodeMath", -50, -300); frente_s.operation = 'SUBTRACT'
nt.links.new(V_SOMBRA.outputs[0], frente_s.inputs[0]); nt.links.new(dist.outputs[0], frente_s.inputs[1])
masc = nodo(nt, "ShaderNodeMapRange", 150, -300)
masc.inputs["From Min"].default_value = -0.05; masc.inputs["From Max"].default_value = 0.35
nt.links.new(frente_s.outputs[0], masc.inputs["Value"])
oscuro = nodo(nt, "ShaderNodeMix", 400, -100); oscuro.data_type = 'RGBA'
oscuro.inputs[6].default_value = (0.012, 0.010, 0.018, 1); oscuro.inputs[7].default_value = (0.0005, 0.0, 0.001, 1)
nt.links.new(masc.outputs["Result"], oscuro.inputs[0]); nt.links.new(oscuro.outputs[2], bs.inputs["Base Color"])
filo = nodo(nt, "ShaderNodeMapRange", 150, -550)
filo.inputs["From Min"].default_value = 0.0; filo.inputs["From Max"].default_value = 0.06
filo.inputs["To Min"].default_value = 1.0; filo.inputs["To Max"].default_value = 0.0
abs_ = nodo(nt, "ShaderNodeMath", -50, -550); abs_.operation = 'ABSOLUTE'
nt.links.new(frente_s.outputs[0], abs_.inputs[0]); nt.links.new(abs_.outputs[0], filo.inputs["Value"])
fil_on = nodo(nt, "ShaderNodeMath", 350, -550); fil_on.operation = 'MULTIPLY'
V_FILO = nodo(nt, "ShaderNodeValue", 150, -750)
nt.links.new(filo.outputs["Result"], fil_on.inputs[0]); nt.links.new(V_FILO.outputs[0], fil_on.inputs[1])
bs.inputs["Emission Color"].default_value = (0.5, 0.12, 1.0, 1)
nt.links.new(fil_on.outputs[0], bs.inputs["Emission Strength"])
suelo.data.materials.append(m_suelo)

# --- la oscuridad que se mueve detrás del orbe (volumen con ruido 4D)
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.35, 0.9))
humo = bpy.context.object
humo.scale = (3.2, 1.8, 1.8)
m_humo = bpy.data.materials.new("humo")
nt = m_humo.node_tree
nt.nodes.clear()
outv = nodo(nt, "ShaderNodeOutputMaterial", 600, 0)
pv = nodo(nt, "ShaderNodeVolumePrincipled", 300, 0)
pv.inputs["Color"].default_value = (0.02, 0.012, 0.035, 1)
pv.inputs["Anisotropy"].default_value = 0.2
tcv = nodo(nt, "ShaderNodeTexCoord", -800, 0)
V_HUMO_T = nodo(nt, "ShaderNodeValue", -800, 250)
V_HUMO = nodo(nt, "ShaderNodeValue", -800, 350)
nv = nodo(nt, "ShaderNodeTexNoise", -500, 0, Scale=1.6, Detail=5.0, Roughness=0.65, Distortion=0.9)
nv.noise_dimensions = '4D'
nt.links.new(tcv.outputs["Object"], nv.inputs["Vector"]); nt.links.new(V_HUMO_T.outputs[0], nv.inputs["W"])
gr = nodo(nt, "ShaderNodeTexGradient", -500, -250); gr.gradient_type = 'SPHERICAL'
nt.links.new(tcv.outputs["Object"], gr.inputs["Vector"])
mr = nodo(nt, "ShaderNodeMapRange", -250, 0)
mr.inputs["From Min"].default_value = 0.45; mr.inputs["From Max"].default_value = 0.75
nt.links.new(nv.outputs["Fac"], mr.inputs["Value"])
d1 = nodo(nt, "ShaderNodeMath", 0, 0); d1.operation = 'MULTIPLY'
nt.links.new(mr.outputs["Result"], d1.inputs[0]); nt.links.new(gr.outputs["Fac"], d1.inputs[1])
d2 = nodo(nt, "ShaderNodeMath", 150, 0); d2.operation = 'MULTIPLY'
nt.links.new(d1.outputs[0], d2.inputs[0]); nt.links.new(V_HUMO.outputs[0], d2.inputs[1])
nt.links.new(d2.outputs[0], pv.inputs["Density"])
nt.links.new(pv.outputs[0], outv.inputs["Volume"])
humo.data.materials.append(m_humo)
humo.hide_render = OPC.get("humo", "si") == "no"

# --- venas de energía por la mano y el brazo (atributo «vena»: 0 en la mano → 1 en el hombro)
idx_brazo = {cuerpo.vertex_groups[n].index for n in
             ["mixamorig:RightArm", "mixamorig:RightForeArm", MANO] + [h for hs in DEDOS.values() for h in hs]
             if n in cuerpo.vertex_groups}
cab_mano = ere.data.bones[MANO].head_local
cab_hombro = ere.data.bones["mixamorig:RightArm"].head_local
eje_v = (cab_hombro - cab_mano)
largo_v = eje_v.length
eje_v.normalize()
at = cuerpo.data.attributes.new("vena", 'FLOAT', 'POINT')
vals = []
# (los vértices están en el espacio de la malla; la malla es hija del esqueleto con su misma escala de importación)
inv_m = ere.matrix_world.inverted() @ cuerpo.matrix_world
for v in cuerpo.data.vertices:
    s_ = sum(g.weight for g in v.groups if g.group in idx_brazo)
    if s_ < 0.35:
        vals.append(-1.0)
    else:
        p_ = inv_m @ v.co
        vals.append(min(1.2, max(0.0, (p_ - cab_mano).dot(eje_v) / largo_v)))
at.data.foreach_set("value", vals)
m_cuerpo = cuerpo.data.materials[0]
nt = m_cuerpo.node_tree
bsc = [n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'][0]
atr = nodo(nt, "ShaderNodeAttribute", -900, -600); atr.attribute_name = "vena"
V_VENA = nodo(nt, "ShaderNodeValue", -900, -800)
V_VENA_F = nodo(nt, "ShaderNodeValue", -900, -900)
dentro = nodo(nt, "ShaderNodeMath", -650, -600); dentro.operation = 'LESS_THAN'
nt.links.new(atr.outputs["Fac"], dentro.inputs[0]); nt.links.new(V_VENA.outputs[0], dentro.inputs[1])
pos_ = nodo(nt, "ShaderNodeMath", -650, -750); pos_.operation = 'GREATER_THAN'; pos_.inputs[1].default_value = -0.5
nt.links.new(atr.outputs["Fac"], pos_.inputs[0])
tcb = nodo(nt, "ShaderNodeTexCoord", -900, -1050)
vb = nodo(nt, "ShaderNodeTexVoronoi", -650, -1000, Scale=45.0); vb.feature = 'DISTANCE_TO_EDGE'
nt.links.new(tcb.outputs["Object"], vb.inputs["Vector"])
lv = nodo(nt, "ShaderNodeMath", -450, -1000); lv.operation = 'LESS_THAN'; lv.inputs[1].default_value = 0.018
nt.links.new(vb.outputs["Distance"], lv.inputs[0])
rv = nodo(nt, "ShaderNodeTexNoise", -650, -1200, Scale=18.0, Detail=3.0)
nt.links.new(tcb.outputs["Object"], rv.inputs["Vector"])
rcorte = nodo(nt, "ShaderNodeMath", -450, -1200); rcorte.operation = 'GREATER_THAN'; rcorte.inputs[1].default_value = 0.58
nt.links.new(rv.outputs["Fac"], rcorte.inputs[0])
lv2 = nodo(nt, "ShaderNodeMath", -300, -1100); lv2.operation = 'MULTIPLY'
nt.links.new(lv.outputs[0], lv2.inputs[0]); nt.links.new(rcorte.outputs[0], lv2.inputs[1])
m1 = nodo(nt, "ShaderNodeMath", -250, -700); m1.operation = 'MULTIPLY'
nt.links.new(dentro.outputs[0], m1.inputs[0]); nt.links.new(pos_.outputs[0], m1.inputs[1])
m2 = nodo(nt, "ShaderNodeMath", -100, -800); m2.operation = 'MULTIPLY'
nt.links.new(m1.outputs[0], m2.inputs[0]); nt.links.new(lv2.outputs[0], m2.inputs[1])
m3 = nodo(nt, "ShaderNodeMath", 50, -800); m3.operation = 'MULTIPLY'
nt.links.new(m2.outputs[0], m3.inputs[0]); nt.links.new(V_VENA_F.outputs[0], m3.inputs[1])
bsc.inputs["Emission Color"].default_value = (1.0, 0.2, 0.75, 1)
nt.links.new(m3.outputs[0], bsc.inputs["Emission Strength"])

# ------------------------------------------------------------------ partículas (malla de quads que mueve el script)
N_LUZ, N_NEGRA = 420, 160


def malla_quads(nombre, n, mat):
    me = bpy.data.meshes.new(nombre)
    vs = [(0, 0, 0)] * (4 * n)
    fs = [(4 * i, 4 * i + 1, 4 * i + 2, 4 * i + 3) for i in range(n)]
    me.from_pydata(vs, [], fs)
    me.attributes.new("col", 'FLOAT_COLOR', 'POINT')
    uv = me.uv_layers.new(name="UVMap")
    uv.data.foreach_set("uv", [c for i in range(n) for q in ((0, 0), (1, 0), (1, 1), (0, 1)) for c in q])
    ob = bpy.data.objects.new(nombre, me); sc.collection.objects.link(ob)
    me.materials.append(mat)
    return ob


def mat_mota(nombre, oscura):
    m = bpy.data.materials.new(nombre)
    nt = m.node_tree
    nt.nodes.clear()
    out = nodo(nt, "ShaderNodeOutputMaterial", 800, 0)
    uvn = nodo(nt, "ShaderNodeUVMap", -700, 0)
    sub = nodo(nt, "ShaderNodeVectorMath", -500, 0); sub.operation = 'SUBTRACT'; sub.inputs[1].default_value = (0.5, 0.5, 0)
    nt.links.new(uvn.outputs[0], sub.inputs[0])
    ln = nodo(nt, "ShaderNodeVectorMath", -300, 0); ln.operation = 'LENGTH'
    nt.links.new(sub.outputs[0], ln.inputs[0])
    caida = nodo(nt, "ShaderNodeMapRange", -100, 0)
    caida.inputs["From Min"].default_value = 0.5; caida.inputs["From Max"].default_value = 0.0
    caida.interpolation_type = 'SMOOTHSTEP'
    nt.links.new(ln.outputs["Value"], caida.inputs["Value"])
    col = nodo(nt, "ShaderNodeAttribute", -100, 250); col.attribute_name = "col"
    alfa = nodo(nt, "ShaderNodeMath", 150, 0); alfa.operation = 'MULTIPLY'
    nt.links.new(caida.outputs["Result"], alfa.inputs[0]); nt.links.new(col.outputs["Alpha"], alfa.inputs[1])
    tr = nodo(nt, "ShaderNodeBsdfTransparent", 300, -150)
    if oscura:
        sh = nodo(nt, "ShaderNodeBsdfDiffuse", 300, 150)
        nt.links.new(col.outputs["Color"], sh.inputs["Color"])
        mx = nodo(nt, "ShaderNodeMixShader", 550, 0)
        nt.links.new(alfa.outputs[0], mx.inputs[0]); nt.links.new(tr.outputs[0], mx.inputs[1]); nt.links.new(sh.outputs[0], mx.inputs[2])
        nt.links.new(mx.outputs[0], out.inputs[0])
    else:
        em = nodo(nt, "ShaderNodeEmission", 300, 150)
        nt.links.new(col.outputs["Color"], em.inputs["Color"])
        nt.links.new(alfa.outputs[0], em.inputs["Strength"])
        ad = nodo(nt, "ShaderNodeAddShader", 550, 0)
        nt.links.new(em.outputs[0], ad.inputs[0]); nt.links.new(tr.outputs[0], ad.inputs[1])
        nt.links.new(ad.outputs[0], out.inputs[0])
    m.surface_render_method = 'BLENDED'
    m.use_backface_culling = False
    return m


motas = malla_quads("motas", N_LUZ, mat_mota("mota", False))
negras = malla_quads("motas_negras", N_NEGRA, mat_mota("mota_negra", True))


def azar_unidad(r):
    z = r.uniform(-1, 1); a_ = r.uniform(0, math.tau); s_ = math.sqrt(1 - z * z)
    return Vector((s_ * math.cos(a_), s_ * math.sin(a_), z))


PART = []
for i in range(N_LUZ + N_NEGRA):
    r = random.Random(7000 + i)
    clase = "negra" if i >= N_LUZ else r.choices(["violeta", "plata", "magenta"], [0.58, 0.27, 0.15])[0]
    PART.append(dict(u=r.random(), dirv=azar_unidad(r), r0=r.uniform(0.10, 0.7), tam=r.uniform(0.5, 1.4),
                     vel=r.uniform(0.7, 1.3), fase=r.uniform(0, math.tau), clase=clase,
                     sal=(azar_unidad(r) + Vector((0, -1.3, 0.15))).normalized(), rapidez=r.uniform(2.5, 9.0)))
COLOR = {"violeta": (0.62, 0.3, 1.0), "plata": (0.82, 0.86, 1.0), "magenta": (1.0, 0.22, 0.55), "negra": (0.004, 0.002, 0.006)}


def t_particulas(t):
    """Tiempo de las partículas: se detiene durante el congelado del agarre."""
    if t < T["agarre"]:
        return t
    if t < T["agarre"] + T["congela"]:
        return T["agarre"]
    return t - T["congela"]


def tray_atraccion(p, tp):
    s = (tp * 0.30 * p["vel"] + p["u"]) % 1.0
    ang = 2.2 * s + p["fase"]
    d = Quaternion(Vector((0, 0, 1)), ang) @ p["dirv"]
    d.z *= 0.55
    pos = O + d * p["r0"] * (1 - s) ** 1.4
    return pos, math.sin(math.pi * s) ** 0.7, d * (-0.35 * p["vel"] * p["r0"])


def tray_absorcion(p, tp, palma, codo_, ab):
    s = (tp * (1.1 if p["clase"] != "negra" else 0.55) * p["vel"] + p["u"]) % 1.0
    if s < 0.6:
        k = s / 0.6
        base = (O + p["dirv"] * R_ORBE * 1.7).lerp(palma, k ** 1.4)
        eje = (palma - O).normalized()
    else:
        k = (s - 0.6) / 0.4
        base = palma.lerp(codo_, k)
        eje = (codo_ - palma).normalized()
    radio = (0.045 if p["clase"] != "negra" else 0.11 * p["tam"]) * (1 - 0.6 * s) * (0.5 + ab)
    perp = eje.cross(Vector((0, 0, 1)))
    if perp.length < 1e-4:
        perp = Vector((1, 0, 0))
    perp.normalize()
    q = Quaternion(eje, 11.0 * s + p["fase"])
    return base + (q @ perp) * radio, math.sin(math.pi * s) ** 0.6, eje


def actualizar_particulas(t, palma, codo_, puno):
    tp = t_particulas(t)
    cam_p = CAM.matrix_world.translation
    vis_luz = suave(tramo(t, T["luz_orbe"], T["luz_orbe"] + 1.2))
    ab = suave(tramo(t, T["absorbe"], T["absorbe"] + 0.6))
    co_luz, col_luz, co_neg, col_neg = [], [], [], []
    for i, p in enumerate(PART):
        brillo = 1.0
        if t < T["absorbe"]:
            pos, a_, vel = tray_atraccion(p, tp)
            if p["clase"] == "negra":
                a_ = 0.0
        elif t < T["comprime"]:
            pa, aa, va = tray_atraccion(p, tp)
            pb, a_b, vb_ = tray_absorcion(p, tp, palma, codo_, ab)
            pos = pa.lerp(pb, ab); a_ = aa * (1 - ab) + a_b * ab; vel = va.lerp(vb_, ab)
            if p["clase"] == "negra":
                a_ = a_b * ab * 0.85
            a_ *= 1 - suave(tramo(t, T["orbe_muerto"] - 0.3, T["comprime"]))
        elif t < T["libera"]:
            lento = 0.1 if t >= T["quieto"] else 1.0
            ang = (tp * 9.0 * lento + p["fase"] * 3)
            d = Quaternion(p["dirv"].orthogonal().normalized(), ang) @ p["dirv"]
            pos = puno + d * (0.028 + 0.03 * p["u"]); vel = d.cross(p["dirv"])
            a_ = 0.55 * suave(tramo(t, T["comprime"], T["comprime"] + 0.4)) * (0 if p["clase"] == "negra" else 1)
        else:
            x = t - T["libera"]
            k_ = 1.6 if p["clase"] != "negra" else 2.4
            v = p["sal"] * p["rapidez"] * (0.6 if p["clase"] == "negra" else 1.0)
            pos = puno + v * (1 - math.exp(-k_ * x)) / k_
            vel = v * math.exp(-k_ * x)
            a_ = math.exp(-x / (0.9 if p["clase"] != "negra" else 1.6))
            brillo = 1.5 * math.exp(-x / 0.25) + 0.8
        a_ *= vis_luz
        # quad orientado a la cámara, alargado según la velocidad (estela en lugar de desenfoque de movimiento)
        hacia = (cam_p - pos).normalized()
        lado = hacia.cross(Vector((0, 0, 1))).normalized() if abs(hacia.z) < 0.99 else Vector((1, 0, 0))
        arriba = lado.cross(hacia).normalized()
        tam = (0.0035 if p["clase"] != "negra" else 0.012) * p["tam"]
        dc = (cam_p - pos).length
        tam *= min(max(dc / 1.6, 0.3), 1.4)                # en los primeros planos, motas más finas
        a_ *= suave(tramo(dc, 0.3, 0.6))                    # ninguna mota pegada al objetivo
        if t >= T["libera"]:
            tam *= 1.6
        vproj = vel - hacia * vel.dot(hacia)
        estela = min(vproj.length * (1 / FPS) * 1.2, 0.4)
        if vproj.length > 1e-4:
            ej = vproj.normalized()
            perp = hacia.cross(ej).normalized()
        else:
            ej, perp = arriba, lado
        largo_e = tam + estela
        esq = [pos - ej * largo_e - perp * tam, pos - ej * largo_e + perp * tam, pos + ej * tam + perp * tam, pos + ej * tam - perp * tam]
        c = COLOR[p["clase"]]
        if p["clase"] == "negra":
            co_neg.extend(esq); col_neg.extend([(c[0], c[1], c[2], a_)] * 4)
        else:
            f_ = 2.4 * brillo
            co_luz.extend(esq); col_luz.extend([(c[0] * f_, c[1] * f_, c[2] * f_, min(1.0, a_))] * 4)
    for ob, co, cl in ((motas, co_luz, col_luz), (negras, co_neg, col_neg)):
        me = ob.data
        me.vertices.foreach_set("co", [x for v in co for x in v])
        me.attributes["col"].data.foreach_set("color", [x for c in cl for x in c])
        me.update()


# ------------------------------------------------------------------ estallido: ondas y fragmentos de cristal
def anillo(nombre, color):
    bpy.ops.mesh.primitive_circle_add(vertices=96, radius=1.0, fill_type='NGON')
    ob = bpy.context.object; ob.name = nombre
    m = bpy.data.materials.new(nombre)
    nt = m.node_tree; nt.nodes.clear()
    out = nodo(nt, "ShaderNodeOutputMaterial", 800, 0)
    tcx = nodo(nt, "ShaderNodeTexCoord", -700, 0)
    ln = nodo(nt, "ShaderNodeVectorMath", -500, 0); ln.operation = 'LENGTH'
    nt.links.new(tcx.outputs["Object"], ln.inputs[0])
    banda = nodo(nt, "ShaderNodeMapRange", -300, 0); banda.interpolation_type = 'SMOOTHSTEP'
    banda.inputs["From Min"].default_value = 0.78; banda.inputs["From Max"].default_value = 1.0
    nt.links.new(ln.outputs["Value"], banda.inputs["Value"])
    corte = nodo(nt, "ShaderNodeMath", -300, -200); corte.operation = 'LESS_THAN'; corte.inputs[1].default_value = 1.0
    nt.links.new(ln.outputs["Value"], corte.inputs[0])
    b2 = nodo(nt, "ShaderNodeMath", -100, 0); b2.operation = 'MULTIPLY'
    nt.links.new(banda.outputs["Result"], b2.inputs[0]); nt.links.new(corte.outputs[0], b2.inputs[1])
    b3 = nodo(nt, "ShaderNodeMath", 50, 0); b3.operation = 'POWER'; b3.inputs[1].default_value = 3.0
    nt.links.new(b2.outputs[0], b3.inputs[0])
    vf = nodo(nt, "ShaderNodeValue", -100, 250)
    b4 = nodo(nt, "ShaderNodeMath", 200, 0); b4.operation = 'MULTIPLY'
    nt.links.new(b3.outputs[0], b4.inputs[0]); nt.links.new(vf.outputs[0], b4.inputs[1])
    em = nodo(nt, "ShaderNodeEmission", 400, 100, Color=(*color, 1))
    nt.links.new(b4.outputs[0], em.inputs["Strength"])
    tr = nodo(nt, "ShaderNodeBsdfTransparent", 400, -100)
    ad = nodo(nt, "ShaderNodeAddShader", 600, 0)
    nt.links.new(em.outputs[0], ad.inputs[0]); nt.links.new(tr.outputs[0], ad.inputs[1]); nt.links.new(ad.outputs[0], out.inputs[0])
    m.surface_render_method = 'BLENDED'; m.use_backface_culling = False
    ob.data.materials.append(m)
    ob.hide_render = True
    return ob, vf


ONDAS = [anillo("onda_suelo", (0.6, 0.3, 1.0)), anillo("onda_aire", (0.85, 0.6, 1.0)), anillo("onda_aire2", (1.0, 0.3, 0.6))]
m_frag = bpy.data.materials.new("fragmento")
nt = m_frag.node_tree
bsf = nt.nodes.get("Principled BSDF")
bsf.inputs["Base Color"].default_value = (0.03, 0.01, 0.06, 1)
bsf.inputs["Roughness"].default_value = 0.05
bsf.inputs["Transmission Weight"].default_value = 0.6
bsf.inputs["Emission Color"].default_value = (0.7, 0.3, 1.0, 1)
lw = nodo(nt, "ShaderNodeLayerWeight", -500, -300, Blend=0.2)
fm = nodo(nt, "ShaderNodeMath", -250, -300); fm.operation = 'MULTIPLY'; fm.inputs[1].default_value = 8.0
nt.links.new(lw.outputs["Fresnel"], fm.inputs[0]); nt.links.new(fm.outputs[0], bsf.inputs["Emission Strength"])
FRAG = []
for i in range(40):
    r = random.Random(500 + i)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=1.0)
    fo = bpy.context.object
    for v in fo.data.vertices:
        v.co = Vector((v.co.x * r.uniform(0.4, 1.0), v.co.y * r.uniform(0.2, 0.6), v.co.z * r.uniform(0.9, 2.2)))
    tam = r.uniform(0.008, 0.03)
    fo.data.materials.append(m_frag)
    fo.hide_render = True
    FRAG.append((fo, tam, (azar_unidad(r) * 0.6 + Vector((0, -1.0, 0.35))).normalized() * r.uniform(1.5, 6.0),
                 Vector((r.uniform(-1, 1), r.uniform(-1, 1), r.uniform(-1, 1))) * r.uniform(6, 20)))

# destello (plano delante de la cámara) y haz de la descarga (cono hacia la cámara)
destello_m, destello_em = mat_brillo("destello", (0.92, 0.85, 1.0), 0.0)
bpy.ops.mesh.primitive_plane_add(size=1)
destello = bpy.context.object
destello.data.materials.append(destello_m)
destello.hide_render = True
haz_m, haz_em = mat_brillo("haz", (0.55, 0.2, 1.0), 0.0)
bpy.ops.mesh.primitive_cone_add(vertices=48, radius1=0.015, radius2=0.12, depth=1.0)
haz = bpy.context.object
haz.data.materials.append(haz_m)
haz.hide_render = True

# ------------------------------------------------------------------ luces y mundo
w = bpy.data.worlds.new("mundo"); sc.world = w
w.node_tree.nodes["Background"].inputs[0].default_value = (0.0025, 0.0018, 0.005, 1)
vol = w.node_tree.nodes.new("ShaderNodeVolumePrincipled")
vol.inputs["Density"].default_value = float(OPC.get("niebla", "0.035"))
vol.inputs["Color"].default_value = (0.75, 0.7, 0.95, 1)
vol.inputs["Anisotropy"].default_value = 0.35
w.node_tree.links.new(vol.outputs[0], w.node_tree.nodes["World Output"].inputs["Volume"])


def luz(nombre, tipo, color, radio=0.05):
    d = bpy.data.lights.new(nombre, tipo); d.color = color; d.shadow_soft_size = radio
    o_ = bpy.data.objects.new(nombre, d); sc.collection.objects.link(o_)
    return o_, d


contra, contra_d = luz("contraluz", 'SPOT', (0.5, 0.56, 1.0), 0.3)
contra.location = Vector((0.9, 2.2, 2.4))
contra_d.spot_size = math.radians(50); contra_d.spot_blend = 0.6
contra.rotation_euler = (Vector((0, 0, 1.0)) - contra.location).to_track_quat('-Z', 'Y').to_euler()
luz_mano, luz_mano_d = luz("luz_mano", 'POINT', (1.0, 0.2, 0.55), 0.02)
luz_explo, luz_explo_d = luz("luz_estallido", 'POINT', (0.75, 0.5, 1.0), 0.15)
luz_explo_d.volume_factor = 0.12
relleno, relleno_d = luz("relleno_frio", 'AREA', (0.4, 0.45, 0.9), 2.0)
relleno.location = (-2.5, -3.0, 1.5)
relleno.rotation_euler = (Vector((0, 0, 0.8)) - relleno.location).to_track_quat('-Z', 'Y').to_euler()
relleno_d.size = 3.0
charco, charco_d = luz("charco_orbe", 'SPOT', (0.62, 0.3, 1.0), 0.04)       # la luz del orbe sobre el suelo
charco.location = O + ARRIBA * 0.02
charco_d.spot_size = math.radians(80); charco_d.spot_blend = 0.8
charco_d.volume_factor = 0.0
charco.rotation_euler = (Vector((O.x * 0.5, O.y - 0.05, 0.0)) - charco.location).to_track_quat('-Z', 'Y').to_euler()
realce, realce_d = luz("realce_mano", 'SPOT', (0.6, 0.66, 1.0), 0.15)         # contraluz frío que dibuja las garras
realce.location = O + DERECHA * 0.45 + ARRIBA * 0.75 + FRENTE * (-0.55)
realce_d.spot_size = math.radians(40); realce_d.spot_blend = 0.7
realce_d.volume_factor = 0.0
realce.rotation_euler = (O - realce.location).to_track_quat('-Z', 'Y').to_euler()

# ------------------------------------------------------------------ cámara (un plano por tramo; cortes secos)
cam_d = bpy.data.cameras.new("cam"); cam_d.sensor_width = 36; cam_d.clip_start = 0.01; cam_d.clip_end = 100
CAM = bpy.data.objects.new("cam", cam_d); sc.collection.objects.link(CAM); sc.camera = CAM
cam_d.dof.use_dof = True
CABEZA = "mixamorig:Head"


def evaluar(t, f_):
    posar(t)
    return f_()


def cara_pt():
    return hueso_mundo(CABEZA).translation + ARRIBA * 0.17 + FRENTE * 0.12


def pecho_pt():
    return hueso_mundo("mixamorig:Spine2").translation.copy()


def manos_pt():
    return (hueso_mundo(MANO).translation + hueso_mundo("mixamorig:LeftHand").translation) * 0.5


def diag4(v):
    return Matrix.Diagonal(Vector(v))


def dir_(x, y, z):
    return (DERECHA * x + FRENTE * y + ARRIBA * z)


def distancia_libre(punto, direccion, t, margen=0.3):
    """Distancia desde «punto» hacia «direccion» a la que la cámara queda fuera de la malla de Érebo en t."""
    posar(t)
    d = direccion.normalized()
    co = malla_eval()
    m = 0.0
    for c in co:
        v = c - punto
        pr = v.dot(d)
        if pr > 0 and (v - d * pr).length < 0.3:
            m = max(m, pr)
    return m + margen


PUNTOS = {}
if VERSION == "completa":
    PUNTOS["manos"] = evaluar(4.7, manos_pt)
    DIR_P2A = dir_(0.5, 0.85, 0.16).normalized()
    D_P2A = max(0.9, max(distancia_libre(PUNTOS["manos"], DIR_P2A, tt) for tt in (3.8, 4.6, 5.3)))
    print("P2a distancia libre %.2f m" % D_P2A)
    PUNTOS["pecho_bajo"] = evaluar(5.6, pecho_pt)
PUNTOS["pecho"] = evaluar(T["cara"], pecho_pt)
PUNTOS["cara"] = evaluar(T["cara_fin"] - 0.2, cara_pt)
PUNTOS["pecho_fin"] = evaluar(T["P4"] + 1.0, pecho_pt)
PUNTOS["cara_comp"] = evaluar(T["quieto"], cara_pt)
PUNTOS["puno_comp"] = evaluar(T["quieto"], punto_palma)
PUNTOS["puno_lib"] = evaluar(T["libera"] + 0.3, punto_palma)
print("PUNTOS", {k: tuple(round(x, 2) for x in v) for k, v in PUNTOS.items()})




PL_COMUNES = [
    ("P3", T["P3"], T["P4"], lambda k: O + dir_(0.6 + 0.15 * k, -0.55 + 0.05 * k, 0.6 - 0.2 * k).normalized() * (0.56 - 0.04 * k), lambda k: O + DERECHA * 0.012, 85, 85, 11.0),
    ("P4", T["P4"], T["P5"], lambda k: PUNTOS["pecho_fin"] + Quaternion(Vector((0, 0, 1)), math.radians(-35 + 25 * suave(k))) @ dir_(0, 1.6, 0.15), lambda k: PUNTOS["pecho_fin"].lerp(O, 0.4), 50, 50, 4.0),
    ("P5a", T["P5"], T["libera"], lambda k: (PUNTOS["cara_comp"] + PUNTOS["puno_comp"]) * 0.5 + dir_(0.35, 1.75 - 0.25 * suave(k), 0.12), lambda k: (PUNTOS["cara_comp"] + PUNTOS["puno_comp"]) * 0.5 + ARRIBA * 0.04, 50, 50, 4.0),
    ("P5b", T["libera"], T["P6"], lambda k: PUNTOS["pecho_fin"] + dir_(0.6, 3.2, -0.25), lambda k: PUNTOS["pecho_fin"], 28, 28, 5.6),
    ("P6", T["P6"], T["fin"] + 0.1, lambda k: PUNTOS["pecho_fin"] + dir_(0.3, 2.6 - 0.6 * suave(k), -0.2), lambda k: PUNTOS["puno_lib"], 28, 32, 5.6),
]
if VERSION == "completa":
    PLANOS = [
        ("P1", T["P1"], T["P2"], lambda k: O + dir_(-0.25, 0.92, -0.12).normalized() * (3.2 - 1.7 * suave2(k)), lambda k: O, 85, 85, 6.0),
        ("P2a", T["P2"], T["alzarse"], lambda k: PUNTOS["manos"] + DIR_P2A * (D_P2A + 0.6 - 0.15 * k) + ARRIBA * 0.12, lambda k: PUNTOS["manos"].lerp(O, 0.35), 45, 45, 8.0),
        ("P2b", T["alzarse"], T["cara"], lambda k: PUNTOS["pecho_bajo"] + dir_(-0.45, 2.2, -0.45 + 0.1 * k), lambda k: PUNTOS["pecho_bajo"].lerp(PUNTOS["pecho"], suave(k)) + ARRIBA * 0.1, 35, 35, 4.0),
        ("P2c", T["cara"], T["P3"], lambda k: PUNTOS["pecho"].lerp(PUNTOS["cara"], suave(k)) + dir_(0.25, 1.7, -0.15 + 0.08 * k), lambda k: PUNTOS["pecho"].lerp(PUNTOS["cara"], suave(k)), 50, 50, 3.2),
    ] + PL_COMUNES
else:
    PLANOS = [
        ("P1", T["P1"], T["P2"], lambda k: O + dir_(-0.25, 0.92, -0.12).normalized() * (2.0 - 0.6 * suave2(k)), lambda k: O, 85, 85, 2.2),
        ("P2c", T["P2"], T["P3"], lambda k: PUNTOS["pecho"].lerp(PUNTOS["cara"], suave(k)) + dir_(0.25, 1.7, -0.1), lambda k: PUNTOS["pecho"].lerp(PUNTOS["cara"], suave(k)), 50, 50, 3.2),
    ] + PL_COMUNES


def plano_en(t):
    for pl in PLANOS:
        if pl[1] <= t < pl[2]:
            return pl
    return PLANOS[-1]


def temblor(t):
    a_ = 0.0
    if t >= T["agarre"]:
        a_ += 0.004 * math.exp(-(t - T["agarre"]) / 0.25)
    for ts in T["sacude"]:
        if t >= ts:
            a_ += 0.006 * math.exp(-(t - ts) / 0.2)
    if t >= T["libera"]:
        a_ += 0.05 * math.exp(-(t - T["libera"]) / 0.35)
    return Vector((math.sin(t * 71.3) + math.sin(t * 37.1), math.sin(t * 53.7 + 1.3), math.sin(t * 61.9 + 2.1))) * a_


def poner_camara(t):
    nombre, t0, t1, fpos, fmira, l0, l1, fst = plano_en(t)
    k = tramo(t, t0, t1)
    p_ = fpos(k) + temblor(t)
    m_ = fmira(k)
    CAM.matrix_world = Matrix.Translation(p_) @ (m_ - p_).to_track_quat('-Z', 'Y').to_matrix().to_4x4()
    cam_d.lens = l0 + (l1 - l0) * k
    cam_d.dof.focus_distance = (m_ - p_).length
    cam_d.dof.aperture_fstop = fst
    return nombre


# ------------------------------------------------------------------ V12 (15/11): versión MEJORADA («mejora=si»)
# Petición del usuario: «la cinemática de antes mejorada, que se vea de puta madre, con efectos». Por defecto («no») el
# script hace exactamente lo del 14/11. Con «mejora=si», encima de la misma escena, los mismos planos y tiempos:
#   · luz: contraluz de borde plateado y violeta detrás de Érebo (dibuja la capucha y los hombros) que late con el orbe;
#   · polvo en el aire: motas finas que flotan, iluminadas por el orbe, que la absorción arrastra en remolino;
#   · el AGARRE (9,85 s) se lee con más fuerza: onda de choque alrededor del orbe, chispas con estela, destello breve de
#     toda la imagen, golpe de zoom y más temblor;
#   · el APLASTAMIENTO: el puño se carga (halo que late y crece en la quietud) y al liberar estalla un halo esférico,
#     más chispas, más luz y más destello, con aberración cromática un instante;
#   · compositor: bloom más rico y estrellas suaves en los brillos fuertes (la corrección de color y la viñeta se hacen
#     al codificar, con ffmpeg: ver docs/v12/EREBO_CINEMATICA_V12.md §10).
MEJORA = OPC.get("mejora", "no") == "si"


def quad_cam(pos, vel, tam, cam_p, estela_max=0.4):
    hacia = (cam_p - pos).normalized()
    lado = hacia.cross(Vector((0, 0, 1))).normalized() if abs(hacia.z) < 0.99 else Vector((1, 0, 0))
    arriba = lado.cross(hacia).normalized()
    vproj = vel - hacia * vel.dot(hacia)
    estela = min(vproj.length * (1 / FPS) * 1.4, estela_max)
    if vproj.length > 1e-4:
        ej = vproj.normalized(); perp = hacia.cross(ej).normalized()
    else:
        ej, perp = arriba, lado
    le = tam + estela
    return [pos - ej * le - perp * tam, pos - ej * le + perp * tam, pos + ej * tam + perp * tam, pos + ej * tam - perp * tam]


if MEJORA:
    PUNTOS["orbe_agarre"] = evaluar(T["agarre"], lambda: (hueso_mundo(MANO) @ M_ORBE_EN_MANO).translation.copy())
    rim, rim_d = luz("rim_plata", 'AREA', (0.72, 0.8, 1.0), 0.6)
    rim_d.size = 1.4
    rim.location = PUNTOS["pecho_fin"] + Vector((0.55, 1.9, 1.15))
    rim.rotation_euler = (PUNTOS["pecho_fin"] + ARRIBA * 0.25 - rim.location).to_track_quat('-Z', 'Y').to_euler()
    rim2, rim2_d = luz("rim_violeta", 'AREA', (0.62, 0.32, 1.0), 0.6)
    rim2_d.size = 1.0
    rim2.location = PUNTOS["pecho_fin"] + Vector((-1.1, 1.3, 0.6))
    rim2.rotation_euler = (PUNTOS["pecho_fin"] + ARRIBA * 0.1 - rim2.location).to_track_quat('-Z', 'Y').to_euler()
    for d_ in (rim_d, rim2_d):
        d_.volume_factor = 0.05
    N_POLVO = 300
    polvo = malla_quads("polvo", N_POLVO, mat_mota("polvo", False))
    POLVO = []
    for i in range(N_POLVO):
        r = random.Random(9100 + i)
        POLVO.append(dict(p=Vector((r.uniform(-1.6, 1.6), r.uniform(-2.4, 1.2), r.uniform(0.05, 2.4))),
                          v=Vector((r.uniform(-0.03, 0.03), r.uniform(-0.03, 0.03), r.uniform(0.005, 0.03))),
                          tam=r.uniform(0.4, 1.3), fase=r.uniform(0, math.tau),
                          c=r.choices([(0.62, 0.3, 1.0), (0.82, 0.86, 1.0), (1.0, 0.45, 0.7)], [0.55, 0.35, 0.1])[0]))
    N_CHISPA = 140
    chispas = malla_quads("chispas", N_CHISPA, mat_mota("chispa", False))
    CHISPA = []
    for i in range(N_CHISPA):
        r = random.Random(9900 + i)
        CHISPA.append(dict(d=azar_unidad(r), v=r.uniform(1.2, 4.5), vida=r.uniform(0.25, 0.7), tam=r.uniform(0.5, 1.2),
                           c=r.choices([(1.0, 0.95, 1.0), (0.8, 0.55, 1.0), (1.0, 0.35, 0.65)], [0.45, 0.4, 0.15])[0],
                           grupo=0 if i < 60 else 1))
    onda_agarre, onda_agarre_v = anillo("onda_agarre", (0.9, 0.75, 1.0))
    m_halo = bpy.data.materials.new("halo")
    nt = m_halo.node_tree
    nt.nodes.clear()
    out_h = nodo(nt, "ShaderNodeOutputMaterial", 800, 0)
    lw_h = nodo(nt, "ShaderNodeLayerWeight", -400, 0, Blend=0.35)
    pw_h = nodo(nt, "ShaderNodeMath", -200, 0); pw_h.operation = 'POWER'; pw_h.inputs[1].default_value = 2.5
    nt.links.new(lw_h.outputs["Facing"], pw_h.inputs[0])
    V_HALO = nodo(nt, "ShaderNodeValue", -200, 200)
    mu_h = nodo(nt, "ShaderNodeMath", 0, 0); mu_h.operation = 'MULTIPLY'
    nt.links.new(pw_h.outputs[0], mu_h.inputs[0]); nt.links.new(V_HALO.outputs[0], mu_h.inputs[1])
    em_h = nodo(nt, "ShaderNodeEmission", 250, 100, Color=(0.78, 0.6, 1.0, 1))
    nt.links.new(mu_h.outputs[0], em_h.inputs["Strength"])
    tr_h = nodo(nt, "ShaderNodeBsdfTransparent", 250, -100)
    ad_h = nodo(nt, "ShaderNodeAddShader", 500, 0)
    nt.links.new(em_h.outputs[0], ad_h.inputs[0]); nt.links.new(tr_h.outputs[0], ad_h.inputs[1])
    nt.links.new(ad_h.outputs[0], out_h.inputs[0])
    m_halo.surface_render_method = 'BLENDED'; m_halo.use_backface_culling = False
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=1.0)
    halo = bpy.context.object; halo.name = "halo_estallido"
    halo.data.materials.append(m_halo)
    halo.hide_render = True


def mejorar(t):
    cam_p = CAM.matrix_world.translation.copy()
    luz_v = V_LUZ.outputs[0].default_value
    pos_o = orbe.matrix_world.translation.copy()
    # --- golpes: agarre y liberación (zoom, temblor extra, destello, aberración)
    xa = t - T["agarre"]
    xl = t - T["libera"]
    golpe = (math.exp(-xa / 0.16) if xa >= 0 else 0.0) * 0.8 + (math.exp(-xl / 0.22) if xl >= 0 else 0.0)
    cam_d.lens *= 1.0 + 0.06 * golpe
    if golpe > 0.01:
        CAM.matrix_world = Matrix.Translation(temblor(t) * 0.8) @ CAM.matrix_world
    fl = destello_em.inputs["Strength"].default_value
    if 0.0 <= xa < 0.12:
        fl = max(fl, 0.3 * math.exp(-xa / 0.035))
    if 0.0 <= xl < 0.2:
        fl = max(fl, 3.0 * math.exp(-xl / 0.045))
    destello_em.inputs["Strength"].default_value = fl
    destello.hide_render = fl <= 0.001
    if xl >= 0:
        luz_explo_d.energy *= 1.3
    try:
        ld.inputs["Dispersion"].default_value = 0.012 + 0.03 * (math.exp(-xa / 0.12) if xa >= 0 else 0.0) + \
            0.06 * (math.exp(-xl / 0.18) if xl >= 0 else 0.0)
    except Exception:
        pass
    # --- contraluz de borde: entra con Érebo, late con el orbe, se enciende al estallar
    t_manos = T["manos"] if T["manos"] is not None else T["P2"]
    ent = suave(tramo(t, t_manos, t_manos + 1.0))
    rim_d.energy = (200.0 + 100.0 * min(luz_v, 2.0)) * ent + (500.0 * math.exp(-xl / 0.4) if xl >= 0 else 0.0)
    rim2_d.energy = (90.0 + 60.0 * min(luz_v, 2.0)) * ent
    # --- polvo en el aire
    co, cl = [], []
    absorbe = suave(tramo(t, T["absorbe"], T["orbe_muerto"])) * (1 - suave(tramo(t, T["comprime"], T["comprime"] + 0.5)))
    for p in POLVO:
        pos = p["p"] + p["v"] * t + Vector((math.sin(t * 0.7 + p["fase"]), math.cos(t * 0.6 + p["fase"]), 0)) * 0.02
        if absorbe > 0:
            hacia = pos_o - pos
            giro = hacia.cross(ARRIBA)
            pos = pos + (hacia * 0.25 + giro * 0.15) * absorbe
        vel = p["v"] + ((pos_o - pos) * 0.6 * absorbe)
        if xl >= 0:
            sale = pos - PUNTOS["puno_lib"]
            pos = pos + sale.normalized() * 1.2 * (1 - math.exp(-xl * 2.0)) / max(sale.length, 0.3)
            vel = vel + sale.normalized() * 3.0 * math.exp(-xl * 2.0)
        dc = (cam_p - pos).length
        tam = 0.0022 * p["tam"] * min(max(dc / 1.6, 0.3), 1.6)
        a_ = 0.55 * suave(tramo(dc, 0.25, 0.7)) * suave(tramo(t, 0.3, 1.5)) * (0.6 + 0.25 * min(luz_v, 2.0))
        co.extend(quad_cam(pos, vel, tam, cam_p, 0.06))
        c = p["c"]
        cl.extend([(c[0] * 1.6, c[1] * 1.6, c[2] * 1.6, a_)] * 4)
    me = polvo.data
    me.vertices.foreach_set("co", [x for v in co for x in v])
    me.attributes["col"].data.foreach_set("color", [x for c in cl for x in c])
    me.update()
    # --- chispas con estela: grupo 0 en el agarre (desde el orbe), grupo 1 en la liberación (desde el puño)
    co, cl = [], []
    for p in CHISPA:
        x = xa if p["grupo"] == 0 else xl
        centro = pos_o if p["grupo"] == 0 else PUNTOS["puno_lib"]
        if p["grupo"] == 0:
            centro = PUNTOS["orbe_agarre"]
        if x < 0 or x > p["vida"]:
            co.extend([centro] * 4); cl.extend([(0, 0, 0, 0)] * 4)
            continue
        esc_v = 0.35 if p["grupo"] == 0 else 1.0
        v = p["d"] * p["v"] * esc_v
        k_ = 3.0
        pos = centro + v * (1 - math.exp(-k_ * x)) / k_ + Vector((0, 0, -0.4 * x * x))
        vel = v * math.exp(-k_ * x)
        a_ = 1.0 - x / p["vida"]
        dc = (cam_p - pos).length
        tam = 0.0025 * p["tam"] * min(max(dc / 1.6, 0.3), 1.4)
        co.extend(quad_cam(pos, vel, tam, cam_p, 0.25 if p["grupo"] == 1 else 0.06))
        c = p["c"]
        f_ = 4.0 * a_
        cl.extend([(c[0] * f_, c[1] * f_, c[2] * f_, min(1.0, a_ * 1.4))] * 4)
    me = chispas.data
    me.vertices.foreach_set("co", [x for v in co for x in v])
    me.attributes["col"].data.foreach_set("color", [x for c in cl for x in c])
    me.update()
    # --- onda del agarre alrededor del orbe, de cara a la cámara
    if 0.0 <= xa < 0.6:
        r_ = 0.03 + 0.32 * (1 - math.exp(-xa * 7.0))
        onda_agarre.hide_render = False
        onda_agarre.matrix_world = Matrix.Translation(PUNTOS.get("orbe_agarre", pos_o)) @ \
            (cam_p - pos_o).to_track_quat('Z', 'Y').to_matrix().to_4x4() @ diag4((r_, r_, r_, 1.0))
        onda_agarre_v.outputs[0].default_value = 7.0 * math.exp(-xa / 0.14)
    else:
        onda_agarre.hide_render = True
    # --- el puño se carga (comprime → quieto) y el halo estalla al liberar
    if T["comprime"] + 0.3 <= t < T["libera"]:
        carga = suave(tramo(t, T["comprime"] + 0.3, T["libera"]))
        pulso = 0.5 + 0.5 * math.sin(t * (18.0 + 30.0 * carga))
        r_ = 0.045 + 0.03 * carga + 0.006 * pulso
        halo.hide_render = False
        halo.matrix_world = Matrix.Translation(PUNTOS["puno_comp"]) @ diag4((r_, r_, r_, 1.0))
        V_HALO.outputs[0].default_value = (1.5 + 5.0 * carga) * (0.7 + 0.3 * pulso)
    elif 0.0 <= xl < 1.2:
        r_ = 0.06 + 2.4 * (1 - math.exp(-xl * 3.2))
        halo.hide_render = False
        halo.matrix_world = Matrix.Translation(PUNTOS["puno_lib"]) @ diag4((r_, r_, r_, 1.0))
        V_HALO.outputs[0].default_value = 4.0 * math.exp(-xl / 0.2)
    else:
        halo.hide_render = True


def componer_mejorado():
    """Bloom más rico y estrellas suaves en los brillos más fuertes (encima del compositor de siempre)."""
    try:
        gl.inputs["Threshold"].default_value = 0.6
        gl.inputs["Strength"].default_value = 0.62
        try:
            gl.inputs["Size"].default_value = 0.8
        except Exception:
            pass
        st = ng.nodes.new("CompositorNodeGlare")
        ok = False
        for nombre_t in ("Streaks", "STREAKS"):
            try:
                st.inputs["Type"].default_value = nombre_t
                ok = True
                break
            except Exception:
                pass
        if not ok:
            print("MEJORA: sin estrellas (tipo Streaks no disponible)")
            return
        for k_, v_ in (("Threshold", 2.2), ("Strength", 0.22)):
            try:
                st.inputs[k_].default_value = v_
            except Exception:
                pass
        for k_, v_ in (("Streaks", 4), ("Streaks Angle", math.radians(25))):
            try:
                st.inputs[k_].default_value = v_
            except Exception:
                pass
        for l_ in list(gl.outputs[0].links):
            ng.links.remove(l_)
        ng.links.new(gl.outputs[0], st.inputs["Image"])
        ng.links.new(st.outputs[0], ld.inputs["Image"])
        print("MEJORA: compositor con bloom y estrellas")
    except Exception as e_:
        print("MEJORA: compositor de siempre (", e_, ")")


# ------------------------------------------------------------------ todo en el tiempo t
def latido(t):
    v = 0.0
    for tl in T["latidos"]:
        if t >= tl:
            x = t - tl
            v += math.exp(-x / 0.09) + (0.6 * math.exp(-(x - 0.22) / 0.08) if x > 0.22 else 0.0)
    return v


def actualizar(t):
    posar(t)
    nombre = poner_camara(t)
    palma = punto_palma()
    codo_ = hueso_mundo("mixamorig:RightForeArm").translation.copy()
    # --- orbe: suspendido; desde el agarre va en la mano; se apaga al absorber; se hunde en la palma al comprimir
    if t < T["agarre"]:
        vib = suave(tramo(t, T["vibra"], T["vibra"] + 0.6)) * 0.0025
        pos_o = O + Vector((math.sin(t * 93), math.sin(t * 87 + 1), math.sin(t * 79 + 2))) * vib + ARRIBA * 0.006 * math.sin(t * 1.3)
        Mo = Matrix.Translation(pos_o)
    else:
        Mo = hueso_mundo(MANO) @ M_ORBE_EN_MANO
        pos_o = Mo.translation.copy()
    esc = 1.0
    if t >= T["comprime"]:
        esc = 1 - suave(tramo(t, T["comprime"], T["comprime"] + 0.45))
    orbe.matrix_world = Matrix.Translation(pos_o) @ diag4((max(esc, 0.001),) * 3 + (1.0,))
    orbe.hide_render = esc < 0.02
    luz_v = suave(tramo(t, T["luz_orbe"], T["luz_orbe"] + 1.0)) * (1 + 0.35 * latido(t))
    if t >= T["agarre"]:
        x = t - T["agarre"]
        luz_v = 1.0 + 1.5 * math.exp(-x / 0.12)
    if t >= T["absorbe"]:
        luz_v *= 1 - 0.95 * suave(tramo(t, T["absorbe"], T["orbe_muerto"]))
    V_LUZ.outputs[0].default_value = luz_v
    V_TIEMPO.outputs[0].default_value = t_particulas(t) * (0.35 if t < T["absorbe"] else 1.2)
    V_GRIETA.outputs[0].default_value = 0.0 if t < T["agarre"] else 0.45 + 0.55 * suave(tramo(t, T["agarre"], T["absorbe"] + 0.6))
    V_MAG.outputs[0].default_value = suave(tramo(t, T["agarre"], T["agarre"] + 0.25))
    luz_orbe.location = pos_o
    despierta = 1.0 + 2.0 * suave(tramo(t, T["P2"], T["P2"] + 0.4)) * (1 - suave(tramo(t, T["P3"] - 0.3, T["P3"]))) if VERSION == "completa" else 1.0
    luz_orbe_d.energy = 12.0 * luz_v * esc * despierta
    luz_orbe_d.color = (0.62, 0.3, 1.0) if t < T["agarre"] else (1.0, 0.25, 0.6)
    # --- runas
    k_r = 1.0 - suave(tramo(t, T["orbe_muerto"], T["orbe_muerto"] + 0.5))
    for ob, em, i in RUNAS:
        ang = i / 12 * math.tau + t_particulas(t) * 0.35
        lp = Vector((math.cos(ang), math.sin(ang), 0)) * R_ORBE * 2.7
        lp = Quaternion(Vector((1, 0, 0)), math.radians(62)) @ lp
        lp = Quaternion(Vector((0, 0, 1)), math.radians(20)) @ lp
        ob.location = pos_o + lp
        ob.rotation_euler = (CAM.matrix_world.translation - ob.location).to_track_quat('Z', 'Y').to_euler()
        aparece = suave(tramo(t, T["runas"] + i * 0.06, T["runas"] + i * 0.06 + 0.25))
        fl = 0.0 if t < T["agarre"] else 5.0 * math.exp(-(t - T["agarre"]) / 0.2)
        em.inputs["Strength"].default_value = (2.5 + 0.6 * fl + 1.2 * latido(t)) * aparece * k_r
        em.inputs["Color"].default_value = (0.72, 0.42, 1.0, 1) if t < T["agarre"] else (1.0, 0.35, 0.7, 1)
        ob.hide_render = aparece * k_r <= 0.0
    em_circ.inputs["Strength"].default_value = (1.4 * suave(tramo(t, T["runas"], T["runas"] + 0.8)) + (0 if t < T["agarre"] else 4 * math.exp(-(t - T["agarre"]) / 0.3))) * k_r
    # --- humo, sombras, venas
    V_HUMO_T.outputs[0].default_value = t * (0.08 if T["sombra"] is None or t < T["sombra"] else 0.3)
    V_HUMO.outputs[0].default_value = 1.8 * (1 - 0.5 * suave(tramo(t, T["P3"], T["P4"])))
    V_SOMBRA.outputs[0].default_value = -1.0 + 6.0 * suave(tramo(t, T["absorbe"], T["comprime"] + 0.8))
    V_FILO.outputs[0].default_value = 3.0 * (1 - suave(tramo(t, T["libera"], T["libera"] + 1.0)))
    V_VENA.outputs[0].default_value = -0.1 if t < T["venas"] else 1.15 * suave2(tramo(t, T["venas"], T["absorbe"] + 1.2))
    V_VENA_F.outputs[0].default_value = (0 if t < T["venas"] else 5.0 * (1 + 0.4 * math.sin(t * 23))) * (1 - suave(tramo(t, T["libera"] + 0.3, T["libera"] + 1.5)))
    # --- luces
    t_manos = T["manos"] if T["manos"] is not None else T["P2"]
    contra_d.energy = 1100.0 * suave(tramo(t, t_manos, t_manos + 0.8)) + 80.0
    relleno_d.energy = 25.0 + 20.0 * suave(tramo(t, T["P2"], T["P3"]))
    charco_d.energy = 60.0 * min(luz_v, 1.6) * esc
    realce_d.energy = 900.0 * suave(tramo(t, T["P3"] - 0.4, T["P3"])) * (1 - suave(tramo(t, T["P5"], T["P5"] + 0.5)))
    luz_mano.location = palma
    lm = 0.0
    if t >= T["venas"]:
        lm = 6.0 * suave(tramo(t, T["venas"], T["orbe_muerto"]))
    if t >= T["comprime"]:
        lm = 9.0 * (1 + 0.3 * math.sin(t * 40)) * (0.6 if t >= T["quieto"] else 1.0)
    if t >= T["libera"]:
        lm *= math.exp(-(t - T["libera"]) / 0.2)
    luz_mano_d.energy = lm
    if t >= T["libera"]:
        x = t - T["libera"]
        luz_explo.location = PUNTOS["puno_lib"] + FRENTE * 0.2
        luz_explo_d.energy = 900.0 * math.exp(-x / 0.3) + 80 * math.exp(-x / 1.2)
    else:
        luz_explo_d.energy = 0.0
    # --- ondas y fragmentos
    for j, (ob, vf) in enumerate(ONDAS):
        x = t - T["libera"] - (0.0, 0.03, 0.16)[j]
        if x < 0:
            ob.hide_render = True
            continue
        ob.hide_render = False
        if j == 0:
            r_ = 0.1 + 6.5 * (1 - math.exp(-x * 1.6))
            ob.location = (PUNTOS["puno_lib"].x, PUNTOS["puno_lib"].y, 0.02); ob.rotation_euler = (0, 0, 0)
        else:
            r_ = 0.05 + (1.6 if j == 1 else 1.1) * (1 - math.exp(-x * 2.6))
            ob.location = PUNTOS["puno_lib"] + FRENTE * (0.05 + 0.6 * x)
            ob.rotation_euler = (math.radians(90), 0, 0)
        ob.scale = (r_, r_, r_)
        vf.outputs[0].default_value = 6.0 * math.exp(-x / 0.35)
    for fo, tam, v0, wv in FRAG:
        x = t - T["libera"]
        if x < 0:
            fo.hide_render = True
            continue
        fo.hide_render = False
        fo.location = PUNTOS["puno_lib"] + v0 * (1 - math.exp(-1.2 * x)) / 1.2 + Vector((0, 0, -0.6 * x * x))
        fo.rotation_euler = (wv.x * x, wv.y * x, wv.z * x)
        fo.scale = (tam, tam, tam)
    # --- haz y destello
    if t >= T["haz"]:
        x = t - T["haz"]
        haz.hide_render = False
        cp = CAM.matrix_world.translation
        dirc = (cp - PUNTOS["puno_lib"])
        largo_h = max(dirc.length * 0.8 * suave2(min(1.0, x / 0.45)), 0.01)
        haz.matrix_world = Matrix.Translation(PUNTOS["puno_lib"] + dirc.normalized() * largo_h * 0.5) @ \
            dirc.to_track_quat('-Z', 'Y').to_matrix().to_4x4() @ diag4((1.0, 1.0, largo_h, 1.0))
        haz_em.inputs["Strength"].default_value = 3.0 * suave(min(1.0, x / 0.2))
    else:
        haz.hide_render = True
    fl = 0.0
    if t >= T["destello"]:
        fl = suave(tramo(t, T["destello"], T["destello"] + 0.12)) * 60.0
    elif T["libera"] <= t < T["libera"] + 0.1:
        fl = 2.5 * (1 - (t - T["libera"]) / 0.1)
    destello_em.inputs["Strength"].default_value = fl
    destello.hide_render = fl <= 0.0
    destello.matrix_world = CAM.matrix_world @ Matrix.Translation((0, 0, -0.05)) @ diag4((0.2, 0.2, 1.0, 1.0))
    actualizar_particulas(t, palma, codo_, palma)
    motas.hide_render = negras.hide_render = OPC.get("motas", "si") == "no"
    if MEJORA:
        mejorar(t)
    return nombre


# ------------------------------------------------------------------ render
sc.render.engine = 'BLENDER_EEVEE'
ee = sc.eevee
ee.taa_render_samples = int(OPC.get("muestras", "24"))
ee.use_raytracing = True
ee.volumetric_tile_size = OPC.get("vtile", "4")
ee.volumetric_samples = 64
ee.volumetric_end = 14.0
ee.use_volumetric_shadows = True
ee.use_shadows = True
sc.render.resolution_x, sc.render.resolution_y = RES
sc.render.resolution_percentage = 100
sc.render.use_lock_interface = True
sc.view_settings.view_transform = 'AgX'
try:
    sc.view_settings.look = 'AgX - Medium High Contrast'
except Exception:
    pass

# compositor: resplandor (bloom) y ligera aberración cromática
ng = bpy.data.node_groups.new("comp_erebo", "CompositorNodeTree")
ng.interface.new_socket("Image", in_out='OUTPUT', socket_type='NodeSocketColor')
rl = ng.nodes.new("CompositorNodeRLayers")
gl = ng.nodes.new("CompositorNodeGlare")
for nombre_t in ("Bloom", "BLOOM", "Fog Glow"):
    try:
        gl.inputs["Type"].default_value = nombre_t
        break
    except Exception:
        pass
gl.inputs["Threshold"].default_value = 0.6
gl.inputs["Strength"].default_value = 0.55
try:
    gl.inputs["Size"].default_value = 0.7
except Exception:
    pass
ld = ng.nodes.new("CompositorNodeLensdist")
ld.inputs["Dispersion"].default_value = 0.012
go = ng.nodes.new("NodeGroupOutput")
ng.links.new(rl.outputs["Image"], gl.inputs["Image"])
ng.links.new(gl.outputs[0], ld.inputs["Image"])
ng.links.new(ld.outputs[0], go.inputs[0])
if OPC.get("comp", "si") != "no":
    sc.compositing_node_group = ng
if MEJORA:
    componer_mejorado()
sc.render.image_settings.file_format = 'PNG'
os.makedirs(SALIDA, exist_ok=True)


def camara_dentro(t):
    cp = CAM.matrix_world.translation
    co = malla_eval()
    cerca = sum(1 for c in co if (c - cp).length < 0.05)
    return cerca


def render_t(t, ruta):
    sc.frame_set(fr(t))
    nombre = actualizar(t)
    sc.render.filepath = ruta
    bpy.ops.render.render(write_still=True)
    return nombre


if ETAPA == "fotos":
    momentos = [float(x) for x in OPC["t"].split(",")] if "t" in OPC else \
        ([0.8, 2.6, 3.5, 4.6, 6.0, 7.6, 8.8, 9.6, 9.9, 10.8, 12.6, 14.5, 16.0, 16.7, 17.08, 17.4, 18.3, 19.4, 19.8]
         if VERSION == "completa" else [0.4, 1.4, 2.3, 2.65, 3.5, 4.6, 5.2, 5.6, 6.4, 6.7])
    for t in momentos:
        n_ = render_t(t, os.path.join(SALIDA, "%s_%05.2fs.png" % (VERSION, t)))
        print("FOTO", t, n_)
elif ETAPA == "planos":
    desde = float(OPC.get("desde", "0")); hasta = float(OPC.get("hasta", str(T["fin"])))
    cada = int(OPC.get("cada", "1"))
    os.makedirs(os.path.join(SALIDA, "fotogramas"), exist_ok=True)
    for f_ in range(fr(desde), fr(hasta), cada):
        t = (f_ - 1) / FPS
        ruta = os.path.join(SALIDA, "fotogramas", "%04d.png" % f_)
        if os.path.exists(ruta) and OPC.get("rehacer", "no") == "no":
            continue
        render_t(t, ruta)
    print("PLANOS", SALIDA)
