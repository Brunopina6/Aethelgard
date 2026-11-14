# meshy_e01 · pasos 3 y 4: clips e01__idle, e01__walk, e01__attack_prensa y (14/11, noche) e01__attack_porton,
# e01__hit y e01__death (horneados a 30 fps), medidas, renders y GLB.
#   blender -b --factory-startup -P p2_clips.py -- <blend con rig (p1)> <carpeta salida GLB> <carpeta render> [sin_render]
#
# Autoría: cada clip es una FUNCIÓN del tiempo que coloca la cadera, la columna, el pecho, el cuello, la cabeza, las
# clavículas, las hombreras y los OBJETIVOS de IK de manos y pies (IK de 2 huesos y rotación copiada; pies plantados).
# Se muestrea cada fotograma (30 fps) con las restricciones activas y se HORNEA a los huesos exportables (cuaterniones;
# posición solo en la cadera). Después se borran los controles y las restricciones, se mide lo horneado y se exporta.
# Raíz quieta: la locomoción es «en el sitio» (el combate desplaza el nodo); la Prensa no avanza.
#
# Tiempos de e01_a1 «Prensa del Umbral» (ataques_propuestos.json; los segundos mandan, no los fotogramas):
#   0,00 pies abiertos · 0,25 flexiona y recoge los brazos · 0,65 puños por encima de los hombros (fija dirección)
#   · 0,90 descarga los puños al suelo delante (IMPACTO; ventana activa [0,90, 1,10)) · 1,10 sostiene el peso
#   · recupera hasta 2,40 (vuelve a la pose del reposo). Torso: la cadera baja como mucho un 15 % de la altura.
import sys, os, json, math
sys.dont_write_bytecode = True
argv = sys.argv[sys.argv.index("--") + 1:]
BLEND, SALIDA, REND = argv[:3]
SIN_RENDER = "sin_render" in argv
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
from mathutils import Vector, Matrix, Euler, Quaternion
import e01_comun as C

FPS = C.FPS
GLB = os.path.join(SALIDA, "meshy_e01.glb")
JSON_CLIPS = os.path.join(SALIDA, "meshy_e01_clips.json")
RES_TEX = 1024
ALTO = 1.85

bpy.ops.wm.open_mainfile(filepath=BLEND)
sc = bpy.context.scene
sc.render.fps = FPS
arm = bpy.data.objects["e01_esqueleto"]
cuerpo = bpy.data.objects["e01_cuerpo"]
pbs = arm.pose.bones
CONTROLES = [b.name for b in arm.data.bones if b.name.startswith("ik_")]
EXPORTABLES = [b.name for b in arm.data.bones if not b.name.startswith("ik_")]
# orden jerárquico (padres primero)
ORDEN = []
def _rec(b):
    ORDEN.append(b.name)
    for c in b.children:
        if not c.name.startswith("ik_"):
            _rec(c)
_rec(arm.data.bones["raiz"])


def rot_local(pb, grados):
    q = Euler([math.radians(a) for a in grados], 'XYZ').to_quaternion()
    R = pb.bone.matrix_local.to_quaternion()
    return R.inverted() @ q @ R


def loc_local(pb, delta):
    return pb.bone.matrix_local.to_3x3().inverted() @ Vector(delta)


def espejo_rot(r):
    return (r[0], -r[1], -r[2])


# ------------------------------------------------------------------ poses (offsets del reposo del rig, metros y grados)
CAMPOS_ROT = ["cadera_rot", "columna", "pecho", "cuello", "cabeza", "clav.L", "clav.R", "hombrera.L", "hombrera.R",
              "punta.L", "punta.R"]
CAMPOS_VEC = ["cadera_loc"]
CAMPOS_OBJ = ["mano.L", "mano.R", "pie.L", "pie.R"]


def pose(**kw):
    p = {k: (0.0, 0.0, 0.0) for k in CAMPOS_ROT + CAMPOS_VEC}
    for k in CAMPOS_OBJ:
        p[k] = ((0.0, 0.0, 0.0), (0.0, 0.0, 0.0))
    for k, v in kw.items():
        k = k.replace("_L", ".L").replace("_R", ".R")
        p[k] = v
    return p


def simetrica(**kw):
    """Las claves del lado izquierdo (sufijo L) se copian en espejo al derecho."""
    p = pose(**kw)
    for k in list(kw.keys()):
        k2 = k.replace("_L", ".L")
        if k2.endswith(".L"):
            base = k2[:-2]
            v = p[k2]
            if base in ("mano", "pie"):
                (x, y, z), r = v
                p[base + ".R"] = ((-x, y, z), espejo_rot(r))
            else:
                p[base + ".R"] = espejo_rot(v)
    return p


def mezclar(a, b, f):
    r = {}
    for k in a:
        va, vb = a[k], b[k]
        if k in CAMPOS_OBJ:
            r[k] = (tuple(x + (y - x) * f for x, y in zip(va[0], vb[0])), tuple(x + (y - x) * f for x, y in zip(va[1], vb[1])))
        else:
            r[k] = tuple(x + (y - x) * f for x, y in zip(va, vb))
    return r


def suave(t):
    t = max(0.0, min(1.0, t)); return t * t * (3 - 2 * t)


def entra(t):        # aceleración (la descarga)
    t = max(0.0, min(1.0, t)); return t * t


def sale(t):         # frenada
    t = max(0.0, min(1.0, t)); return 1 - (1 - t) * (1 - t)


def por_claves(claves, t):
    """claves: [(t, pose, curva_hasta_la_siguiente)]"""
    for k in range(len(claves) - 1):
        t0, p0, cur = claves[k]
        t1, p1, _ = claves[k + 1]
        if t <= t1 or k == len(claves) - 2:
            f = (t - t0) / (t1 - t0) if t1 > t0 else 1.0
            return mezclar(p0, p1, cur(f))
    return claves[-1][1]


# Reposo: rodillas apenas flexionadas, manos un poco delante y hacia dentro, hombreras relajadas.
REPOSO_A = simetrica(cadera_loc=(0, 0.0, -0.025), pecho=(2, 0, 0), cabeza=(-2, 0, 0),
                     mano_L=((-0.025, -0.05, 0.02), (-8, 0, -6)), clav_L=(0, 2, 0))
REPOSO_B = simetrica(cadera_loc=(0, 0.0, -0.038), cadera_rot=(1, 0, 0), pecho=(-1.5, 0, 0), cabeza=(-0.5, 0, 0),
                     mano_L=((-0.022, -0.045, 0.012), (-6, 0, -6)), clav_L=(0, -2.5, 0), hombrera_L=(0, -2, 0))
# la cabeza mira un poco hacia su izquierda a mitad del ciclo y vuelve (no un vaivén constante)
REPOSO_B["cabeza"] = (-0.5, 0, 4)


def c_idle(t):
    T = 2.4
    return por_claves([(0.0, REPOSO_A, suave), (1.2, REPOSO_B, suave), (T, REPOSO_A, suave)], t % T if t < T else T)


# Paso pesado (en el sitio): ciclo de 1,2 s; apoyo de toda la planta durante medio ciclo, el pie apoyado se desplaza a
# velocidad constante (cinta) 2·ZANCADA/0,6 s; balanceo corto de hombros contra la cadera; manos opuestas a los pies.
ZANCADA = 0.26
ALTURA_PASO = 0.12
T_ANDAR = 1.2
VEL_ANDAR = 2 * ZANCADA / (T_ANDAR / 2)


def _pie(fase):
    fase %= 1.0
    if fase < 0.5:                                    # apoyo: del frente (−Y) hacia atrás, plano
        u = fase / 0.5
        return (0.0, -ZANCADA + 2 * ZANCADA * u, 0.0), (0.0, 0.0, 0.0)
    u = (fase - 0.5) / 0.5                            # vuelo: de atrás al frente
    y = ZANCADA - 2 * ZANCADA * suave(u)
    z = ALTURA_PASO * math.sin(math.pi * u) ** 1.3
    rx = 14 * math.sin(math.pi * min(1.0, u * 1.6)) * (1 - u) - 4 * math.sin(math.pi * max(0.0, (u - 0.5) / 0.4)) * (u < 0.9)
    return (0.0, y, z), (rx, 0.0, 0.0)


def c_walk(t):
    f = (t % T_ANDAR) / T_ANDAR
    c = math.cos(2 * math.pi * f)
    s = math.sin(2 * math.pi * f)
    p = pose()
    p["cadera_loc"] = (0.022 * s, 0.0, -0.05 + 0.02 * -math.cos(4 * math.pi * f))
    p["cadera_rot"] = (2.0, 2.5 * s, -5.0 * c)
    p["columna"] = (1.0, -1.0 * s, 3.0 * c)
    p["pecho"] = (2.0, -1.5 * s, 7.0 * c)            # contrapeso de hombros
    p["cabeza"] = (-2.0, 0.0, -5.0 * c)              # la cabeza sigue mirando al frente
    p["pie.L"] = _pie(f)
    p["pie.R"] = ((-_pie(f + 0.5)[0][0],) + _pie(f + 0.5)[0][1:], _pie(f + 0.5)[1])
    p["mano.L"] = ((-0.02, 0.11 * c, 0.02 + 0.03 * max(0.0, -c)), (-8 - 10 * c, 0, -6))
    p["mano.R"] = ((0.02, -0.11 * c, 0.02 + 0.03 * max(0.0, c)), (-8 + 10 * c, 0, 6))
    p["clav.L"] = (0, 1.5 * c, 0)
    p["clav.R"] = (0, 1.5 * c, 0)
    return p


# Prensa del Umbral (e01_a1)
P_FLEX = simetrica(cadera_loc=(0, 0.02, -0.10), cadera_rot=(6, 0, 0), columna=(4, 0, 0), pecho=(6, 0, 0), cabeza=(-8, 0, 0),
                   mano_L=((-0.17, -0.36, 0.30), (-45, 0, -15)), clav_L=(0, 3, 0))
P_ARRIBA = simetrica(cadera_loc=(0, -0.01, -0.045), cadera_rot=(-4, 0, 0), columna=(-3, 0, 0), pecho=(-8, 0, 0),
                     cabeza=(4, 0, 0), mano_L=((-0.10, 0.02, 1.00), (-190, 0, -10)), clav_L=(0, -16, 0),
                     hombrera_L=(0, -22, 0))
P_GOLPE = simetrica(cadera_loc=(0, 0.15, -0.25), cadera_rot=(32, 0, 0), columna=(22, 0, 0), pecho=(30, 0, 0),
                    cuello=(-14, 0, 0), cabeza=(-38, 0, 0), mano_L=((-0.20, -0.47, -0.575), (-24, 0, -8)),
                    clav_L=(0, 8, -14), hombrera_L=(0, 4, 0))
P_PESO = simetrica(cadera_loc=(0, 0.16, -0.262), cadera_rot=(33, 0, 0), columna=(23, 0, 0), pecho=(31, 0, 0),
                   cuello=(-14, 0, 0), cabeza=(-38, 0, 0), mano_L=((-0.20, -0.475, -0.553), (-22, 0, -8)),
                   clav_L=(0, 9, -15), hombrera_L=(0, 5, 0))
P_SUBE = simetrica(cadera_loc=(0, 0.06, -0.12), cadera_rot=(10, 0, 0), columna=(6, 0, 0), pecho=(8, 0, 0),
                   cabeza=(-10, 0, 0), mano_L=((-0.10, -0.30, -0.12), (-25, 0, -8)), clav_L=(0, 3, 0))
PRENSA = [(0.0, REPOSO_A, suave), (0.25, P_FLEX, suave), (0.65, P_ARRIBA, entra), (0.90, P_GOLPE, sale),
          (1.10, P_PESO, suave), (1.65, P_SUBE, suave), (2.40, REPOSO_A, suave)]


def c_prensa(t):
    return por_claves(PRENSA, t)


# ------------------------------------------------------------------ 14/11, noche: Avance del Portón, golpe y derrota
# e01_a2 «Avance del Portón» (ataques_propuestos.json): 0,00 gira los antebrazos hacia delante · 0,50 postura de ariete,
# el peso en la pierna de atrás · 1,00 arranque · [1,00, 1,45) carrera (en el sitio: el combate desplaza el nodo; pasos
# cortos y rápidos con el torso echado) · 1,45 frena en dos apoyos · 1,90 abre la guardia · 2,70 el reposo.
# Los pies que cambian de sitio se levantan (arco); los que no, quietos.
PO_GIRA = simetrica(cadera_loc=(0, 0.02, -0.04), pecho=(3, 0, 0), cabeza=(-4, 0, 0),
                    mano_L=((-0.06, -0.22, 0.26), (-60, 0, -12)), clav_L=(0, 3, 0))
PO_ARIETE = simetrica(cadera_loc=(0, 0.09, -0.09), cadera_rot=(9, 0, 0), columna=(6, 0, 0), pecho=(9, 0, 0),
                      cuello=(-4, 0, 0), cabeza=(-14, 0, 0), mano_L=((-0.07, -0.40, 0.42), (-78, 0, -18)),
                      clav_L=(0, 5, -4), hombrera_L=(0, 6, 0))
PO_ARRANQUE = simetrica(cadera_loc=(0, -0.06, -0.12), cadera_rot=(17, 0, 0), columna=(10, 0, 0), pecho=(13, 0, 0),
                        cuello=(-6, 0, 0), cabeza=(-20, 0, 0), mano_L=((-0.06, -0.52, 0.34), (-82, 0, -18)),
                        clav_L=(0, 7, -5), hombrera_L=(0, 8, 0))
PO_FRENO = simetrica(cadera_loc=(0, 0.04, -0.15), cadera_rot=(4, 0, 0), columna=(-2, 0, 0), pecho=(-4, 0, 0),
                     cabeza=(-6, 0, 0), mano_L=((-0.10, -0.44, 0.30), (-75, 0, -16)), clav_L=(0, 4, 0))
PO_GUARDIA = simetrica(cadera_loc=(0, 0.02, -0.07), cadera_rot=(1, 0, 0), pecho=(-3, 0, 0), cabeza=(-3, 0, 0),
                       mano_L=((-0.22, -0.24, 0.62), (-115, 0, -28)), clav_L=(0, -6, 0), hombrera_L=(0, -8, 0))
PORTON = [(0.0, REPOSO_A, suave), (0.25, PO_GIRA, suave), (0.50, PO_ARIETE, suave), (0.85, PO_ARIETE, entra),
          (1.00, PO_ARRANQUE, suave), (1.40, PO_ARRANQUE, sale), (1.45, PO_FRENO, suave), (1.60, PO_FRENO, suave),
          (1.90, PO_GUARDIA, suave), (2.30, PO_GUARDIA, suave), (2.70, REPOSO_A, suave)]
T_PORTON = 2.7
# pies: (t, y del pie izquierdo, y del derecho), adelante = −Y; entre dos claves distintas el pie se levanta
PIES_PORTON = [(0.0, 0.0, 0.0), (0.50, -0.10, 0.22), (1.00, -0.18, 0.28), (1.45, -0.26, 0.22), (1.90, -0.26, 0.22),
               (2.70, 0.0, 0.0)]
CARRERA = (1.00, 1.45)              # pasos cortos en el sitio
ZANCADA_CARRERA = 0.16


def _pie_porton(y_de, t):
    """La posición del pie por las claves de PIES_PORTON (y_de: 1 izquierdo, 2 derecho), con su arco al cambiar."""
    for k in range(len(PIES_PORTON) - 1):
        t0, t1 = PIES_PORTON[k][0], PIES_PORTON[k + 1][0]
        if t <= t1 or k == len(PIES_PORTON) - 2:
            a, b = PIES_PORTON[k][y_de], PIES_PORTON[k + 1][y_de]
            u = max(0.0, min(1.0, (t - t0) / (t1 - t0)))
            y = a + (b - a) * suave(u)
            z = 0.07 * math.sin(math.pi * u) if abs(b - a) > 0.02 else 0.0
            return y, z
    return PIES_PORTON[-1][y_de], 0.0


def c_porton(t):
    p = por_claves(PORTON, t)
    for s, y_de, desf in (("L", 1, 0.0), ("R", 2, 0.5)):
        y, z = _pie_porton(y_de, t)
        rx = 0.0
        if CARRERA[0] < t < CARRERA[1]:
            u = (t - CARRERA[0]) / (CARRERA[1] - CARRERA[0])
            env = math.sin(math.pi * u)                    # entra y sale de la carrera sin saltos
            f = (u * 2.0 + desf) % 1.0                     # dos pasos por pie en la carrera
            y += env * ZANCADA_CARRERA * math.cos(2 * math.pi * f)
            z += env * 0.09 * max(0.0, math.sin(2 * math.pi * f))
            rx = env * 10 * max(0.0, math.sin(2 * math.pi * f))
        if s == "R" and 0.5 <= t <= 1.0:                   # el talón de atrás se despega antes del arranque
            rx = max(rx, 22 * suave((t - 0.5) / 0.5))
            z = max(z, 0.10 * suave((t - 0.5) / 0.5))
        p["pie." + s] = ((0.0, y, z), (rx, 0.0, 0.0))
    return p


# Recibir un golpe de frente (0,6 s): se echa atrás con la cabeza y los brazos, y vuelve. Pies quietos.
H_ATRAS = simetrica(cadera_loc=(0, 0.06, -0.05), cadera_rot=(-7, 0, 0), columna=(-6, 0, 0), pecho=(-10, 0, 0),
                    cuello=(4, 0, 0), cabeza=(12, 0, 0), mano_L=((-0.05, 0.10, 0.12), (12, 0, -10)), clav_L=(0, -4, 0))
GOLPE = [(0.0, REPOSO_A, sale), (0.12, H_ATRAS, suave), (0.6, REPOSO_A, suave)]
T_GOLPE = 0.6


def c_hit(t):
    return por_claves(GOLPE, t)


# Derrota (1,9 s): trastabilla, cae de rodillas, se vence hacia delante y queda apoyado en las manos (sin rebotes).
# Los pies quietos (la IK dobla las rodillas); la cadera baja como mucho lo que dejan las piernas.
D_ATRAS = simetrica(cadera_loc=(0, 0.07, -0.06), cadera_rot=(-6, 0, 0), columna=(-5, 0, 0), pecho=(-9, 0, 0),
                    cabeza=(10, 0, 0), mano_L=((-0.06, 0.08, 0.10), (10, 0, -10)), clav_L=(0, -3, 0))
D_RODILLAS = simetrica(cadera_loc=(0, 0.06, -0.38), cadera_rot=(10, 0, 0), columna=(12, 0, 0), pecho=(16, 0, 0),
                       cuello=(8, 0, 0), cabeza=(22, 0, 0), mano_L=((-0.04, -0.12, -0.40), (-10, 0, -6)),
                       clav_L=(0, 6, 0), hombrera_L=(0, 4, 0))
D_CAIDA = simetrica(cadera_loc=(0, -0.16, -0.42), cadera_rot=(42, 0, 0), columna=(18, 0, 0), pecho=(16, 0, 0),
                    cuello=(6, 0, 0), cabeza=(12, 0, 0), mano_L=((-0.16, -0.62, -0.56), (-30, 0, -10)),
                    clav_L=(0, 10, -8), hombrera_L=(0, 6, 0))
D_QUIETO = simetrica(cadera_loc=(0, -0.17, -0.44), cadera_rot=(44, 0, 0), columna=(19, 0, 0), pecho=(17, 0, 0),
                     cuello=(8, 0, 0), cabeza=(18, 0, 0), mano_L=((-0.17, -0.63, -0.565), (-30, 0, -10)),
                     clav_L=(0, 10, -8), hombrera_L=(0, 6, 0))
DERROTA = [(0.0, REPOSO_A, sale), (0.25, D_ATRAS, suave), (0.85, D_RODILLAS, entra), (1.30, D_CAIDA, sale),
           (1.90, D_QUIETO, suave)]
T_DERROTA = 1.9


def c_death(t):
    return por_claves(DERROTA, t)


CLIPS = [
    {"nombre": "e01__idle", "dur": 2.4, "bucle": True, "f": c_idle, "eventos": {}},
    {"nombre": "e01__walk", "dur": T_ANDAR, "bucle": True, "f": c_walk,
     "eventos": {"pisada_izq": 0.0, "pisada_der": 0.6}},
    {"nombre": "e01__attack_prensa", "dur": 2.4, "bucle": False, "f": c_prensa,
     "eventos": {"aviso": 0.0, "fija_direccion": 0.65, "impacto": 0.90, "fin_activo": 1.10, "recupera": 1.10}},
    {"nombre": "e01__attack_porton", "dur": T_PORTON, "bucle": False, "f": c_porton,
     "eventos": {"aviso": 0.0, "fija_direccion": 0.75, "carrera": 1.00, "impacto": 1.30, "fin_activo": 1.45,
                 "recupera": 1.45}},
    {"nombre": "e01__hit", "dur": T_GOLPE, "bucle": False, "f": c_hit, "eventos": {}},
    {"nombre": "e01__death", "dur": T_DERROTA, "bucle": False, "f": c_death, "eventos": {"en_el_suelo": 1.30}},
]


# ------------------------------------------------------------------ aplicar una pose a los controles
def aplicar(p):
    for pb in pbs:
        pb.location = (0, 0, 0); pb.rotation_quaternion = (1, 0, 0, 0); pb.scale = (1, 1, 1)
    pbs["cadera"].location = loc_local(pbs["cadera"], p["cadera_loc"])
    pbs["cadera"].rotation_quaternion = rot_local(pbs["cadera"], p["cadera_rot"])
    for b in ("columna", "pecho", "cuello", "cabeza"):
        pbs[b].rotation_quaternion = rot_local(pbs[b], p[b])
    for s in ("L", "R"):
        pbs["clavicula." + s].rotation_quaternion = rot_local(pbs["clavicula." + s], p["clav." + s])
        pbs["hombrera." + s].rotation_quaternion = rot_local(pbs["hombrera." + s], p["hombrera." + s])
        pbs["punta." + s].rotation_quaternion = rot_local(pbs["punta." + s], p["punta." + s])
        for obj in ("mano", "pie"):
            (d, r) = p[obj + "." + s]
            pb = pbs["ik_%s.%s" % (obj, s)]
            pb.location = loc_local(pb, d)
            pb.rotation_quaternion = rot_local(pb, r)


def poner_accion(act):
    if arm.animation_data is None:
        arm.animation_data_create()
    arm.animation_data.action = act
    try:
        if len(act.slots) == 0:
            arm.animation_data.action_slot = act.slots.new('OBJECT', arm.name)
        else:
            arm.animation_data.action_slot = act.slots[0]
    except Exception as e:
        print("AVISO ranura", e)


# ------------------------------------------------------------------ 1. muestrear con restricciones y hornear
if arm.animation_data:
    arm.animation_data.action = None
muestras = {}
for c in CLIPS:
    n = int(round(c["dur"] * FPS))
    fr = []
    for f in range(n + 1):
        aplicar(c["f"](f / FPS))
        bpy.context.view_layer.update()
        fr.append({b: pbs[b].matrix.copy() for b in EXPORTABLES})
        if c["nombre"] == "e01__attack_prensa" and f == 27:
            print("DIAG hombro.L", tuple(round(x, 3) for x in pbs["brazo.L"].head), "muñeca", tuple(round(x, 3) for x in pbs["antebrazo.L"].tail),
                  "objetivo", tuple(round(x, 3) for x in pbs["ik_mano.L"].head))
        # objetivos que la IK no alcanza (el pie o la muñeca no llegan): se avisan
        for s in ("L", "R"):
            for obj, fin in (("mano", "antebrazo"), ("pie", "pierna")):
                obj_p = pbs["ik_%s.%s" % (obj, s)].head
                llega = pbs["%s.%s" % (fin, s)].tail
                if (obj_p - llega).length > 0.01:
                    print("AVISO IK %s f%d %s.%s no llega: %.3f m" % (c["nombre"], f, obj, s, (obj_p - llega).length))
    muestras[c["nombre"]] = fr

for pb in pbs:
    pb.location = (0, 0, 0); pb.rotation_quaternion = (1, 0, 0, 0)
acciones = {}
for c in CLIPS:
    act = bpy.data.actions.new(c["nombre"])
    act.use_fake_user = True
    poner_accion(act)
    fr = muestras[c["nombre"]]
    previo = {}
    for f, M in enumerate(fr):
        for b in ORDEN:
            pb = pbs[b]
            Rb = pb.bone.matrix_local
            if pb.parent is None:
                basis = Rb.inverted() @ M[b]
            else:
                Rp = pb.parent.bone.matrix_local
                basis = (Rb.inverted() @ Rp) @ M[pb.parent.name].inverted() @ M[b]
            loc, q, _ = basis.decompose()
            if b in previo and q.dot(previo[b]) < 0:
                q = -q
            previo[b] = q.copy()
            pb.rotation_quaternion = q
            pb.keyframe_insert("rotation_quaternion", frame=f, group=b)
            if b == "cadera":
                pb.location = loc
                pb.keyframe_insert("location", frame=f, group=b)
    act.use_frame_range = True
    act.frame_start = 0
    act.frame_end = len(fr) - 1
    try:
        act.use_cyclic = c["bucle"]
    except Exception:
        pass
    acciones[c["nombre"]] = act
    print("CLIP", c["nombre"], "%.2f s" % c["dur"], len(fr), "fotogramas")
arm.animation_data.action = None
AUTORIA = os.path.join(os.path.dirname(BLEND), "e01_autoria.blend")
bpy.ops.wm.save_as_mainfile(filepath=AUTORIA)

# ------------------------------------------------------------------ 2. fuera controles y restricciones (lo exportable)
for pb in pbs:
    for cns in list(pb.constraints):
        pb.constraints.remove(cns)
bpy.context.view_layer.objects.active = arm
for o in bpy.data.objects:
    o.select_set(o == arm)
bpy.ops.object.mode_set(mode='EDIT')
for n in CONTROLES:
    arm.data.edit_bones.remove(arm.data.edit_bones[n])
bpy.ops.object.mode_set(mode='OBJECT')
for o in list(bpy.data.objects):
    if o not in (arm, cuerpo):
        bpy.data.objects.remove(o, do_unlink=True)


def poner(nombre, f):
    poner_accion(acciones[nombre])
    sc.frame_set(f)
    bpy.context.view_layer.update()


# ------------------------------------------------------------------ 3. medidas de lo horneado
grupos = {g.index: g.name for g in cuerpo.vertex_groups}
vert_mano = [v.index for v in cuerpo.data.vertices if any(grupos[g.group].startswith("mano.") and g.weight > 0.5 for g in v.groups)]
vert_pie = {s: [v.index for v in cuerpo.data.vertices if any(grupos[g.group] in ("pie." + s, "punta." + s) and g.weight > 0.5
                                                               for g in v.groups)] for s in ("L", "R")}


def malla_eval():
    dg = bpy.context.evaluated_depsgraph_get()
    ob = cuerpo.evaluated_get(dg)
    me = ob.to_mesh()
    cos = [ob.matrix_world @ v.co for v in me.vertices]
    ob.to_mesh_clear()
    return cos


medidas = {}
reposo_cadera_z = arm.data.bones["cadera"].head_local.z
for c in CLIPS:
    nm = c["nombre"]; n = int(round(c["dur"] * FPS))
    m = {"min_z_malla": 9.0, "min_z_manos": 9.0, "cadera_baja_max_m": 0.0, "pie_desliz_max_m": 0.0, "pie_z_apoyo_max_m": 0.0}
    pie0 = None
    vel_apoyo = []
    prev = None
    for f in range(n + 1):
        poner(nm, f)
        cos = malla_eval()
        m["min_z_malla"] = min(m["min_z_malla"], min(p.z for p in cos))
        m["min_z_manos"] = min(m["min_z_manos"], min(cos[i].z for i in vert_mano))
        cz = (arm.matrix_world @ pbs["cadera"].head).z
        m["cadera_baja_max_m"] = max(m["cadera_baja_max_m"], reposo_cadera_z - cz)
        pies = {s: Vector((sum(cos[i].x for i in vert_pie[s]), sum(cos[i].y for i in vert_pie[s]), sum(cos[i].z for i in vert_pie[s]))) / len(vert_pie[s])
                for s in ("L", "R")}
        if f == int(round(0.90 * FPS)) and nm == "e01__attack_prensa":
            m["manos_z_en_impacto"] = round(min(cos[i].z for i in vert_mano), 4)
            m["muñecas_y_en_impacto"] = round(sum(cos[i].y for i in vert_mano) / len(vert_mano), 4)
        if nm == "e01__death" and f == n:
            m["cadera_z_final_m"] = round(cz, 4)
        if not c["bucle"] or nm == "e01__idle":
            if pie0 is None:
                pie0 = pies
            for s in ("L", "R"):
                m["pie_desliz_max_m"] = max(m["pie_desliz_max_m"], (pies[s] - pie0[s]).length)
        else:
            # andar: en el apoyo (fase < 0,5 de cada pie) el pie va a velocidad constante y a ras de suelo
            if prev is not None:
                for s, desf in (("L", 0.0), ("R", 0.5)):
                    fase = ((f - 0.5) / FPS / T_ANDAR + desf) % 1.0
                    if 0.04 < fase < 0.46:
                        vel_apoyo.append((pies[s].y - prev[s].y) * FPS)
                        m["pie_z_apoyo_max_m"] = max(m["pie_z_apoyo_max_m"], abs(pies[s].z - prev_z0[s]))
            else:
                prev_z0 = {s: pies[s].z for s in ("L", "R")}
            prev = pies
    if vel_apoyo:
        m["vel_pie_apoyo_m_s"] = [round(min(vel_apoyo), 3), round(max(vel_apoyo), 3)]
        m["vel_teorica_m_s"] = round(VEL_ANDAR, 3)
    m["cadera_baja_pct_altura"] = round(100 * m["cadera_baja_max_m"] / ALTO, 1)
    for k in list(m):
        if isinstance(m[k], float):
            m[k] = round(m[k], 4)
    # continuidad del bucle: diferencia máxima de rotación entre el primer y el último fotograma
    if c["bucle"]:
        fr = muestras[nm]
        m["salto_bucle_grados"] = round(max(math.degrees(fr[0][b].to_quaternion().rotation_difference(fr[-1][b].to_quaternion()).angle)
                                            for b in EXPORTABLES), 3)
    else:
        fr = muestras[nm]; fi = muestras["e01__idle"][0]
        m["fin_vs_reposo_grados"] = round(max(math.degrees(fr[-1][b].to_quaternion().rotation_difference(fi[b].to_quaternion()).angle)
                                              for b in EXPORTABLES), 3)
        m["inicio_vs_reposo_grados"] = round(max(math.degrees(fr[0][b].to_quaternion().rotation_difference(fi[b].to_quaternion()).angle)
                                                 for b in EXPORTABLES), 3)
    medidas[nm] = m
    print("MEDIDA", nm, json.dumps(m, ensure_ascii=False))

# ------------------------------------------------------------------ 4. renders de lo horneado
if not SIN_RENDER:
    os.makedirs(REND, exist_ok=True)
    C.suelo(0.0)
    TOMAS = {"e01__idle": [0.0, 1.2], "e01__walk": [0.0, 0.3, 0.6, 0.9],
             "e01__attack_prensa": [0.0, 0.25, 0.65, 0.80, 0.90, 1.10, 1.65, 2.40],
             "e01__attack_porton": [0.0, 0.25, 0.50, 1.00, 1.15, 1.30, 1.45, 1.90, 2.70],
             "e01__hit": [0.0, 0.12, 0.6], "e01__death": [0.25, 0.85, 1.30, 1.90]}
    SOLO_TOMAS = [x for x in argv if x.startswith("tomas=")]
    if SOLO_TOMAS:                                  # (para revisar solo los clips nuevos: tomas=a,b)
        quiero = SOLO_TOMAS[0][6:].split(",")
        TOMAS = {k: v for k, v in TOMAS.items() if k in quiero}
    for nm, ts in TOMAS.items():
        for t in ts:
            poner(nm, int(round(t * FPS)))
            C.render_vistas(os.path.join(REND, "%s_%03d" % (nm, int(round(t * 100)))), 2.0, res=480,
                            vistas=[("frente", 0, 0), ("perfil", 90, 0), ("espalda", 180, 0), ("tres_cuartos", 35, 8)])
    arm.animation_data.action = None

# ------------------------------------------------------------------ 5. texturas a 1024 y GLB
os.makedirs(SALIDA, exist_ok=True)
for im in list(bpy.data.images):
    if im.name.startswith("e01_"):
        # (empaquetadas en el FBX: se reescalan en memoria y se vuelven a empaquetar; recargar devolvería las de 2048)
        if im.size[0] != RES_TEX:
            im.scale(RES_TEX, RES_TEX)
        ruta = os.path.join(os.path.dirname(BLEND), "%s_%d.png" % (im.name, RES_TEX))
        im.save_render(ruta)
        im.filepath_raw = ruta                    # el GLB nombra la imagen por su archivo (no «Image_0»)
        im.pack()
        print("TEXTURA", im.name, tuple(im.size), ruta)
arm.animation_data.action = None
for pb in pbs:
    pb.location = (0, 0, 0); pb.rotation_quaternion = (1, 0, 0, 0)
EXPORT_BLEND = os.path.join(os.path.dirname(BLEND), "e01_exportar.blend")
bpy.ops.wm.save_as_mainfile(filepath=EXPORT_BLEND)
for o in bpy.data.objects:
    o.select_set(o in (arm, cuerpo))
props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
op = dict(filepath=GLB, export_format='GLB', use_selection=True, export_animations=True,
          export_animation_mode='ACTIONS', export_force_sampling=True, export_apply=False)
for k, v in [("export_image_format", 'WEBP'), ("export_image_quality", 90), ("export_frame_range", False),
             ("export_anim_slide_to_zero", True), ("export_def_bones", False), ("export_yup", True),
             ("export_skins", True), ("export_all_influences", False), ("export_vertex_color", 'NONE'),
             ("export_attributes", False)]:
    if k in props:
        op[k] = v
bpy.ops.export_scene.gltf(**op)
print("GLB", GLB, os.path.getsize(GLB))
rig = json.load(open(os.path.splitext(BLEND)[0] + "_rig.json", encoding="utf-8"))
json.dump({"id": "meshy_e01", "nombre": "Custodio de Porcelana (nombre de diseño)", "modelo": "meshy_e01",
           "fuente": "Meshy_AI_Original_fantasy_game_enemy_Custodio_de_20261108_texture_fbx.zip (sha256 780f3720…)",
           "alto_m": ALTO, "triangulos": rig["triangulos"], "vertices": rig["vertices"],
           "huesos": len(EXPORTABLES), "deformantes": rig["deformantes"], "max_influencias": rig["max_influencias"],
           "fps": FPS, "textura": "%d px (color, normal, metálico-rugosidad; WebP dentro del GLB)" % RES_TEX,
           "mapa_diseno": {"idle": "e01__idle", "walk": "e01__walk", "attack_01": "e01__attack_prensa",
                           "attack_02": "e01__attack_porton", "hit_front": "e01__hit", "death": "e01__death"},
           "mapa_juego": {"reposo": "e01__idle", "caminar": "e01__walk", "correr": "e01__walk", "ataque": "e01__attack_prensa",
                          "porton": "e01__attack_porton", "recibir_golpe": "e01__hit", "derrota": "e01__death"},
           "velocidad_andar_m_s": round(VEL_ANDAR, 3),
           "clips": {c["nombre"]: {"duracion": c["dur"], "bucle": c["bucle"], "eventos": c["eventos"]} for c in CLIPS},
           "medidas": medidas, "generador": "enemigos/meshy_e01/fuente/p1_rig.py + p2_clips.py (Blender %s)" % bpy.app.version_string},
          open(JSON_CLIPS, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("FIN")
