# Vidracrán, el escorpión de vidrio del Mar de Cristal — PROTOTIPO V12 (12/11/2026, especialista de animaciones).
# Nombre y papel: docs/v12/NARRATIVA_DESIERTO.md §4 (propuesta, sin aprobar). Duerme bajo la arena con la cola fuera,
# que brilla como un trozo de botella; se entierra un turno (no se le puede apuntar) y sale con el aguijón; avisa con
# un brillo. Geometría, atlas, esqueleto y clips hechos desde cero con este guion (obra propia del proyecto).
#
#   blender -b --factory-startup -P crear_vidracran.py -- <raíz aethelgard> <carpeta de láminas>
#
# Escribe enemigos/vidracran/vidracran.glb (atlas 512 dentro) y vidracran_clips.json, y en la carpeta de láminas
# vidracran_lamina.png y una pose por clip.
#
# Silueta (lo que lo distingue de Zarzalín, Cencerrante y Bramavidrio): bajo y ancho, de placas facetadas de vidrio
# ámbar esmerilado con arena dentro (no basalto, no corteza), patas finas de vidrio ahumado, pinzas planas como
# esquirlas y una cola alta enroscada que termina en un bulbo de vidrio de botella verde que brilla (el cebo).
# Ejes (Blender): mira a -Y, Z arriba, su izquierda es +X. En Godot mira a +Z.
#
# Esqueleto (31 huesos): raiz; cuerpo (lleva todo lo demás, se hunde al enterrarse); cola1…cola5 y aguijon;
# pinza_brazo / pinza_ante / pinza / pinza_dedo (.L y .R); pata1a…pata4b (.L y .R); ojos (dato para el brillo);
# monticulo (hijo de raiz: el montón de arena del agujero; escondido con escala 0,01).
# Superficies (las pone Godot por nombre, enemigos/vidracran/vidracran_3d.gd): «caparazon» (atlas: vidrio ámbar,
# humo, vientre oscuro, arena) y «brillo» (bulbo y ojos: verde botella que el script hace latir).
#
# Clips (30 fps; el fotograma 1 es el segundo 0; en bucle: reposo, enterrado, correr):
#   reposo (2 s)            el cebo de la cola se mece, las pinzas tantean, las patas cambian de apoyo
#   pinzas (1,03 s)         levanta y abre las pinzas (aviso), se lanza 0,25 m y las cierra: IMPACTO 0,467 s (f15)
#   enterrarse (1,4 s)      cabecea, escarba, se hunde 0,5 m; el montón de arena crece; queda con la cola fuera
#   enterrado (2 s)         solo la cola fuera, meciéndose (no se le puede apuntar)
#   aviso_aguijon (0,8 s)   el bulbo late dos veces y el montón tiembla: el aviso de que va a salir
#   emerger_aguijon (1,33 s) revienta la arena, sale en vilo con la cola armada y pica hacia abajo: IMPACTO 0,5 s (f16);
#                           aterriza y vuelve al reposo (el combate lo coloca bajo el objetivo mientras está enterrado)
#   recibir_golpe (0,5 s), derrota (1,6 s: se encabrita, se derrumba, la cola cae), entrada (1,2 s: sale de la arena),
#   correr (0,63 s: trípode alterno de las ocho patas)
import bpy, sys, os, math, json
from mathutils import Vector, Euler

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(AQUI, "..", "..", "..", "personajes", "desierto", "fuentes_blender"))
import desierto_comun as C

argv = sys.argv[sys.argv.index("--") + 1:]
RAIZ, LAMINAS = argv[0], argv[1]
SALIDA = os.path.join(RAIZ, "enemigos", "vidracran")

COLA = [Vector(p) for p in ((0, 0.40, 0.32), (0, 0.54, 0.43), (0, 0.63, 0.60), (0, 0.62, 0.78), (0, 0.51, 0.92),
                            (0, 0.35, 0.99))]
AGUIJON_F = Vector((0, 0.10, 0.86))
BULBO = Vector((0, 0.24, 0.96))
PATAS_Y = [-0.15, -0.03, 0.09, 0.21]
PATAS_D = [-0.12, -0.04, 0.05, 0.13]


def pinza_pts(l):
    return (Vector((0.13 * l, -0.22, 0.28)), Vector((0.30 * l, -0.36, 0.27)), Vector((0.28 * l, -0.55, 0.26)),
            Vector((0.22 * l, -0.82, 0.24)))


def pata_pts(i, l):
    y, d = PATAS_Y[i], PATAS_D[i]
    return Vector((0.15 * l, y, 0.27)), Vector((0.37 * l, y + d, 0.42)), Vector((0.52 * l, y + 1.7 * d, 0.0))


def huesos():
    h = [("raiz", (0, 0, 0), (0, 0, 0.1), None),
         ("monticulo", (0, 0, 0.0), (0, 0, 0.12), "raiz"),
         ("cuerpo", (0, 0.30, 0.30), (0, -0.30, 0.30), "raiz"),
         ("ojos", (0, -0.25, 0.36), (0, -0.30, 0.36), "cuerpo")]
    padre = "cuerpo"
    for k in range(5):
        h.append(("cola%d" % (k + 1), COLA[k], COLA[k + 1], padre))
        padre = "cola%d" % (k + 1)
    h.append(("aguijon", COLA[5], AGUIJON_F, "cola5"))
    for s, l in (("L", 1), ("R", -1)):
        H, Cd, W, T = pinza_pts(l)
        h += [("pinza_brazo." + s, H, Cd, "cuerpo"), ("pinza_ante." + s, Cd, W, "pinza_brazo." + s),
              ("pinza." + s, W, T, "pinza_ante." + s),
              ("pinza_dedo." + s, W + Vector((-0.03 * l, -0.06, 0)), T + Vector((-0.05 * l, 0.0, 0)), "pinza." + s)]
        for i in range(4):
            A, K, F = pata_pts(i, l)
            h += [("pata%da.%s" % (i + 1, s), A, K, "cuerpo"), ("pata%db.%s" % (i + 1, s), K, F, "pata%da.%s" % (i + 1, s))]
    return h


def paleta(A):
    A.muestra("ambar", (0.90, 0.72, 0.44), oscuro=0.70, claro=1.10, grano=0.05)
    A.muestra("ambar_claro", (0.97, 0.88, 0.66), oscuro=0.85, claro=1.08, grano=0.04)
    A.muestra("humo", (0.40, 0.34, 0.30), oscuro=0.7, claro=1.25)
    A.muestra("vientre", (0.20, 0.17, 0.16), oscuro=0.8, claro=1.2)
    A.muestra("verde", (0.36, 0.86, 0.46), oscuro=0.75, claro=1.15, grano=0.02)
    A.muestra("verde_osc", (0.10, 0.32, 0.18), oscuro=0.7, claro=1.3)
    A.muestra("arena", (0.86, 0.74, 0.52), oscuro=0.8, claro=1.05, grano=0.06)
    # puntitos de arena atrapada dentro del vidrio ámbar
    x0, y0, c = A.muestras["ambar"]
    px, py, pc = int(x0 * A.tam), int(y0 * A.tam), int(c * A.tam)
    sub = A.img[py:py + pc, px:px + pc, :3]
    mask = A.rng.random((pc, pc)) > 0.93
    sub[mask] = sub[mask] * 0.78


def construir(M):
    # prosoma (escudo de la cabeza) y seis placas del lomo, facetadas
    M.pintar(M.tubo([(0, -0.34, 0.30), (0, -0.28, 0.32), (0, -0.16, 0.33), (0, -0.05, 0.32)],
                    [(0.09, 0.04), (0.15, 0.07), (0.19, 0.09), (0.185, 0.085)], 10), "ambar", pesos="cuerpo",
             liso=False, deform=lambda co: co + Vector((0, 0, 0.03 * max(0, co.z - 0.30) / 0.09)))
    for k in range(6):
        y0 = -0.07 + 0.078 * k
        r = 0.205 - 0.012 * k
        M.pintar(M.tubo([(0, y0, 0.30), (0, y0 + 0.04, 0.31), (0, y0 + 0.095, 0.305)],
                        [(r * 0.94, 0.092), (r, 0.10), (r * 0.9, 0.088)], 10), "ambar_claro" if k % 2 else "ambar",
                 pesos="cuerpo", liso=False)
    M.pintar(M.esfera((0, 0.07, 0.25), (0.18, 0.40, 0.06), (12, 6)), "vientre", pesos="cuerpo", liso=False)
    # ojos: dos medianos encima del escudo y tres pequeños a cada lado (superficie «brillo»)
    for x in (0.035, -0.035):
        M.pintar(M.esfera((x, -0.25, 0.375), (0.022, 0.022, 0.02), (8, 5)), "verde", pesos="ojos", mat=1)
    for l in (1, -1):
        for j in range(3):
            M.pintar(M.esfera((0.11 * l + 0.012 * j * l, -0.30 + 0.02 * j, 0.335), (0.011, 0.011, 0.01), (6, 4)),
                     "verde", pesos="ojos", mat=1)
    # cola: cinco segmentos abombados, el bulbo de botella y el aguijón
    for k in range(5):
        a, b = COLA[k], COLA[k + 1]
        r0 = 0.085 - 0.007 * k
        M.pintar(M.tubo([a.lerp(b, -0.12), a.lerp(b, 0.25), a.lerp(b, 0.7), a.lerp(b, 1.05)],
                        [r0 * 0.75, r0, r0 * 0.95, r0 * 0.7], 8, ref=Vector((1, 0, 0))),
                 "ambar_claro" if k % 2 else "ambar", pesos="cola%d" % (k + 1), liso=False)
    eje = (AGUIJON_F - COLA[5]).normalized()
    M.pintar(M.esfera(BULBO, (0.09, 0.10, 0.085), (9, 6), giro=eje.to_track_quat('Y', 'Z').to_euler()), "verde",
             pesos="aguijon", mat=1, liso=False)
    M.pintar(M.tubo([BULBO + eje * 0.07, BULBO + eje * 0.12 + Vector((0, 0, -0.02)), AGUIJON_F + Vector((0, -0.01, -0.07))],
                    [0.03, 0.02, 0.002], 6), "verde_osc", pesos="aguijon", liso=False)
    # pinzas: brazos, mano plana de esquirla y dos dedos (el de dentro se mueve), con dientes
    for s, l in (("L", 1), ("R", -1)):
        H, Cd, W, T = pinza_pts(l)
        M.pintar(M.tubo([H, Cd], [0.045, 0.04], 6), "humo", pesos="pinza_brazo." + s, liso=False)
        M.pintar(M.tubo([Cd, W], [0.042, 0.05], 6), "ambar", pesos="pinza_ante." + s, liso=False)
        d = (T - W).normalized()
        M.pintar(M.esfera(W + d * 0.09, (0.10, 0.15, 0.062), (8, 6), giro=d.to_track_quat('Y', 'Z').to_euler()),
                 "ambar_claro", pesos="pinza." + s, liso=False)
        fuera = W + d * 0.14 + Vector((0.035 * l, 0, 0))
        M.pintar(M.tubo([fuera, fuera.lerp(T, 0.5) + Vector((0.02 * l, 0, 0)), T], [(0.035, 0.022), (0.025, 0.018),
                                                                                     0.002], 6),
                 "ambar", pesos="pinza." + s, liso=False)
        dentro = W + d * 0.14 + Vector((-0.04 * l, 0, 0))
        Td = T + Vector((-0.05 * l, 0.0, 0))
        M.pintar(M.tubo([dentro, dentro.lerp(Td, 0.5) + Vector((-0.025 * l, 0, 0)), Td],
                        [(0.03, 0.02), (0.022, 0.016), 0.002], 6), "humo", pesos="pinza_dedo." + s, liso=False)
        for t in (0.3, 0.55, 0.8):
            p = fuera.lerp(T, t) + Vector((-0.02 * l, 0, 0))
            M.pintar(M.cono(p, p + Vector((-0.03 * l, -0.005, 0)), 0.008, 4), "ambar_claro", pesos="pinza." + s,
                     liso=False)
        # patas: dos tramos de vidrio ahumado, punta de esquirla
        for i in range(4):
            A_, K, F = pata_pts(i, l)
            M.pintar(M.tubo([A_, K + (K - A_).normalized() * 0.02], [0.03, 0.024], 5), "ambar",
                     pesos="pata%da.%s" % (i + 1, s), liso=False)
            M.pintar(M.tubo([K, K.lerp(F, 0.75)], [0.024, 0.016], 5), "humo", pesos="pata%db.%s" % (i + 1, s),
                     liso=False)
            M.pintar(M.cono(K.lerp(F, 0.75), F, 0.016, 5), "ambar_claro", pesos="pata%db.%s" % (i + 1, s),
                     liso=False)
    # el montón de arena del agujero (escondido: escala 0,01 en el reposo)
    M.pintar(M.esfera((0, 0.0, 0.0), (0.62, 0.58, 0.16), (16, 6)), "arena", pesos="monticulo",
             quitar=lambda co: co.z < -0.01,
             deform=lambda co: co + Vector((0, 0, 0.03 * math.sin(co.x * 13) * math.cos(co.y * 11))))


# ------------------------------------------------------------------ poses

ESCONDIDO = {"monticulo@esc": (0.01, 0.01, 0.01)}


def lev(l, g):          # levanta la pata (el pie hacia arriba)
    return (0, -g * l, 0)


def adelante(l, g):     # lleva el pie hacia delante
    return (0, 0, -g * l)


def base():
    p = dict(ESCONDIDO)
    for s, l in (("L", 1), ("R", -1)):
        p["pinza_brazo." + s] = (-6, -4 * l, 0)
        p["pinza_dedo." + s] = (0, 0, -6 * l)
    return p


def con(p, **extra):
    q = dict(p)
    q.update(extra)
    return q


def enterrado(f=0.0):
    p = C.sumar(base(), {"cuerpo@loc": (0, 0, -0.50), "cuerpo": (10, 0, 0), "cola1": (-14, 0, 0), "cola2": (-8, 0, 0),
                         "cola3": (0, 0, 6 * math.sin(f)), "cola4": (0, 0, 8 * math.sin(f + 0.8)),
                         "cola5": (6 * math.sin(f * 0.5), 0, 6 * math.sin(f + 1.6))})
    for s, l in (("L", 1), ("R", -1)):
        p = C.sumar(p, {"pinza_brazo." + s: (25, 20 * l, 0), "pinza_ante." + s: (0, 30 * l, 0)})
        for i in range(4):
            p = C.sumar(p, {"pata%da.%s" % (i + 1, s): lev(l, 35)})
    p["monticulo@esc"] = (1, 1, 1)
    return p


def clips(arm):
    B = base()
    info = {}
    # reposo: cebo que se mece, pinzas que tantean, patas que cambian el apoyo
    claves = []
    for f in range(1, 62, 6):
        t = 2 * math.pi * (f - 1) / 60
        p = C.sumar(B, {"cola4": (2 * math.sin(t), 0, 7 * math.sin(t)), "cola5": (0, 0, 6 * math.sin(t + 0.7)),
                        "aguijon": (3 * math.sin(2 * t), 0, 0), "cuerpo@loc": (0, 0, 0.006 * math.sin(2 * t)),
                        "pinza_dedo.L": (0, 0, -8 * max(0, math.sin(2 * t))), "pinza_dedo.R": (0, 0, 8 * max(0, math.sin(2 * t + 1))),
                        "pinza_brazo.L": (-3 * math.sin(t), 0, 4 * math.sin(t)),
                        "pinza_brazo.R": (-3 * math.sin(t + 1), 0, -4 * math.sin(t + 1)),
                        "pata2a.L": lev(1, 8 * max(0, math.sin(t))), "pata3a.R": lev(-1, 8 * max(0, math.sin(t + math.pi)))})
        claves.append((f, p))
    C.crear_clip(arm, "reposo", claves)
    info["reposo"] = {"duracion": 2.0, "bucle": True}
    # pinzas: aviso (arriba y abiertas), embestida corta y cierre (impacto f15), vuelta
    arriba = dict(B)
    cierre = C.sumar(B, {"cuerpo@loc": (0, -0.25, -0.02), "cuerpo": (6, 0, 0), "cola3": (12, 0, 0), "cola4": (8, 0, 0)})
    for s, l in (("L", 1), ("R", -1)):
        arriba = C.sumar(arriba, {"pinza_brazo." + s: (-35, -20 * l, 0), "pinza_ante." + s: (-15, 10 * l, 0),
                                  "pinza_dedo." + s: (0, 0, -30 * l)})
        cierre = C.sumar(cierre, {"pinza_brazo." + s: (8, 10 * l, 0), "pinza_ante." + s: (10, -15 * l, 0),
                                  "pinza_dedo." + s: (0, 0, 8 * l)})
    arriba = C.sumar(arriba, {"cuerpo@loc": (0, 0.06, 0.02), "cuerpo": (-8, 0, 0)})
    C.crear_clip(arm, "pinzas", [(1, B), (9, arriba), (12, C.sumar(arriba, {"cuerpo@loc": (0, -0.08, 0)})),
                                 (15, cierre), (19, C.sumar(cierre, {"cuerpo@loc": (0, 0.03, 0)})), (31, B)])
    info["pinzas"] = {"duracion": 30 / 30, "impacto": 14 / 30, "alcance_m": 0.25}
    # enterrarse: cabecea y escarba (sacudidas), se hunde; el montón crece
    E = enterrado()
    claves = [(1, B)]
    for f in range(5, 37, 4):
        t = (f - 5) / 32
        p = C.mezclar_poses(C.sumar(B, {"cuerpo": (14, 0, 0)}), E, t * t)
        p = C.sumar(p, {"cuerpo": (0, 4 * (1 if (f // 4) % 2 else -1), 3 * (1 if (f // 4) % 2 else -1))})
        p["monticulo@esc"] = (min(1, 0.01 + t * 1.6),) * 3
        claves.append((f, p))
    claves.append((43, E))
    C.crear_clip(arm, "enterrarse", claves)
    info["enterrarse"] = {"duracion": 42 / 30, "oculto_desde": 30 / 30}
    C.crear_clip(arm, "enterrado", [(f, enterrado(2 * math.pi * (f - 1) / 60)) for f in range(1, 62, 6)])
    info["enterrado"] = {"duracion": 2.0, "bucle": True}
    # aviso del aguijón: el bulbo late dos veces (escala) y el montón tiembla
    claves = []
    for f, k in ((1, 0), (5, 1), (9, 0), (13, 1), (17, 0), (25, 0)):
        p = C.sumar(E, {"cola4": (-8 * k, 0, 0), "cola5": (-10 * k, 0, 0)})
        p["aguijon@esc"] = (1 + 0.3 * k,) * 3
        p["monticulo@esc"] = (1 + 0.06 * k, 1 + 0.06 * k, 1 + 0.25 * k)
        claves.append((f, p))
    C.crear_clip(arm, "aviso_aguijon", claves)
    info["aviso_aguijon"] = {"duracion": 24 / 30, "latidos": [4 / 30, 12 / 30]}
    # emerger con el aguijón: revienta la arena, en vilo con la cola armada, pica abajo (impacto f16), aterriza
    armado = C.sumar(B, {"cuerpo@loc": (0, 0.0, 0.18), "cuerpo": (-22, 0, 0), "cola2": (-14, 0, 0), "cola3": (-16, 0, 0),
                         "cola4": (-10, 0, 0), "monticulo@esc": (130, 130, 100)})
    pica = C.sumar(B, {"cuerpo@loc": (0, -0.05, 0.08), "cuerpo": (12, 0, 0), "cola2": (22, 0, 0), "cola3": (28, 0, 0),
                       "cola4": (24, 0, 0), "cola5": (20, 0, 0), "aguijon": (25, 0, 0), "monticulo@esc": (90, 90, 50)})
    for s, l in (("L", 1), ("R", -1)):
        armado = C.sumar(armado, {"pinza_brazo." + s: (-25, -25 * l, 0)})
        for i in range(4):
            armado = C.sumar(armado, {"pata%da.%s" % (i + 1, s): lev(l, -12)})
    bulto = C.sumar(E, {"monticulo@esc": (1.3, 1.3, 1.9), "cuerpo@loc": (0, 0, 0.12)})
    C.crear_clip(arm, "emerger_aguijon", [
        (1, E), (6, bulto), (11, armado), (16, pica), (20, C.sumar(pica, {"cuerpo@loc": (0, 0, -0.06)})),
        (26, C.sumar(B, {"cuerpo@loc": (0, 0, -0.03), "monticulo@esc": (40, 40, 20)})), (32, C.sumar(B, {"monticulo@esc": (1, 1, 1)})),
        (41, B)])
    info["emerger_aguijon"] = {"duracion": 40 / 30, "impacto": 15 / 30, "visible_desde": 4 / 30}
    # recibir golpe
    golpe = C.sumar(B, {"cuerpo@loc": (0, 0.07, 0.03), "cuerpo": (-8, 6, 0), "cola3": (-12, 0, 0), "cola4": (-10, 0, 0)})
    C.crear_clip(arm, "recibir_golpe", [(1, B), (4, golpe), (9, C.sumar(golpe, {"cuerpo": (4, -3, 0)})), (16, B)])
    info["recibir_golpe"] = {"duracion": 15 / 30}
    # derrota: se encabrita, se derrumba y la cola cae de lado
    encab = C.sumar(B, {"cuerpo": (-18, 0, 0), "cuerpo@loc": (0, 0.04, 0.08), "cola3": (-10, 0, 0)})
    caido = C.sumar(B, {"cuerpo@loc": (0, 0.02, -0.14), "cuerpo": (4, 8, 0), "cola1": (-30, 0, 18), "cola2": (-35, 0, 10),
                        "cola3": (-40, 0, 6), "cola4": (-30, 0, 0), "cola5": (-15, 0, 0)})
    for s, l in (("L", 1), ("R", -1)):
        encab = C.sumar(encab, {"pinza_brazo." + s: (-40, -25 * l, 0), "pinza_dedo." + s: (0, 0, -30 * l)})
        caido = C.sumar(caido, {"pinza_brazo." + s: (12, -15 * l, 0), "pinza_dedo." + s: (0, 0, -20 * l)})
        for i in range(4):
            caido = C.sumar(caido, {"pata%da.%s" % (i + 1, s): lev(l, 22), "pata%db.%s" % (i + 1, s): lev(l, -20)})
    C.crear_clip(arm, "derrota", [(1, B), (10, encab), (20, C.sumar(caido, {"cuerpo@loc": (0, 0, 0.03)})), (25, caido),
                                  (49, caido)])
    info["derrota"] = {"duracion": 48 / 30}
    # entrada: sale de la arena sacudiéndose
    claves = [(1, E)]
    for f in range(6, 25, 4):
        t = (f - 6) / 18
        p = C.mezclar_poses(E, B, t)
        p = C.sumar(p, {"cuerpo": (0, 5 * (1 if (f // 4) % 2 else -1), 0)})
        p["monticulo@esc"] = (1 + 0.2 * t,) * 3
        claves.append((f, p))
    claves += [(31, C.sumar(B, {"monticulo@esc": (40, 40, 30)})), (37, B)]
    C.crear_clip(arm, "entrada", claves)
    info["entrada"] = {"duracion": 36 / 30}
    # correr: trípode alterno
    claves = []
    for f in range(1, 21, 3):
        t = 2 * math.pi * (f - 1) / 18
        p = dict(B)
        for s, l in (("L", 1), ("R", -1)):
            for i in range(4):
                fase = t + (0 if (i + (0 if l > 0 else 1)) % 2 == 0 else math.pi)
                p = C.sumar(p, {"pata%da.%s" % (i + 1, s): C.sumar({"x": lev(l, 18 * max(0, math.sin(fase)))},
                                                                  {"x": adelante(l, 14 * math.cos(fase))})["x"]})
        p = C.sumar(p, {"cuerpo@loc": (0, 0, 0.012 * abs(math.sin(2 * t))), "cola4": (0, 0, 5 * math.sin(t))})
        claves.append((f, p))
    C.crear_clip(arm, "correr", claves)
    info["correr"] = {"duracion": 18 / 30, "bucle": True}
    return info


POSES_LAMINA = [("pinzas", 9, "pinzas: aviso"), ("pinzas", 15, "pinzas: impacto"), ("enterrado", 1, "enterrado"),
                ("aviso_aguijon", 5, "aviso: el bulbo late"), ("emerger_aguijon", 11, "emerge armado"),
                ("emerger_aguijon", 16, "aguijón: impacto"), ("derrota", 30, "derrota")]


def main():
    esc = C.escena_vacia()
    A = C.Atlas(512, semilla=5)
    paleta(A)
    os.makedirs(SALIDA, exist_ok=True)
    img = A.guardar(os.path.join(SALIDA, "vidracran_atlas.png"), "vidracran_atlas")
    M = C.Malla(A, ("caparazon", "brillo"))
    construir(M)
    ob = M.objeto("vidracran_malla", esc.collection)
    ob.data.materials.append(C.material_atlas("caparazon", img, rugoso=0.25, metal=0.1))
    ob.data.materials.append(C.material_atlas("brillo", img, rugoso=0.2, emision=(0.35, 0.95, 0.5, 1.5)))
    arm = C.crear_armadura("vidracran", huesos(), esc.collection)
    C.enlazar(ob, arm)
    info = clips(arm)
    tris = C.triangulos(ob)
    info["_modelo"] = {"triangulos": tris, "huesos": len(arm.data.bones), "atlas": 512, "superficies": ["caparazon", "brillo"]}
    print("CRIATURA vidracran triangulos", tris, "huesos", len(arm.data.bones))
    C.exportar_glb(os.path.join(SALIDA, "vidracran.glb"))
    with open(os.path.join(SALIDA, "vidracran_clips.json"), "w", encoding="utf-8") as f:
        json.dump(info, f, indent=1, ensure_ascii=False)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(LAMINAS, "vidracran.blend"))
    cam, xs = C.lamina_criatura(esc, arm, ob, RAIZ, os.path.join(LAMINAS, "vidracran_lamina.png"),
                                "Vidracrán  ·  PROTOTIPO V12  ·  %d triángulos, atlas 512, 2 superficies" % tris,
                                sep=2.0, giros=(-35, -90, 180), alto_cam=0.75, orto=10.5)
    cam.data.ortho_scale = 2.6
    esc.render.resolution_x, esc.render.resolution_y = 800, 700
    for i, (clip, f, _t) in enumerate(POSES_LAMINA):
        arm.animation_data.action = bpy.data.actions[clip]
        esc.frame_set(f)
        C.apuntar(cam, (xs[1], -0.2, 0.45), 12, -40, 18)
        esc.render.filepath = os.path.join(LAMINAS, "vidracran_pose%d_%s_f%d.png" % (i, clip, f))
        bpy.ops.render.render(write_still=True)


main()
