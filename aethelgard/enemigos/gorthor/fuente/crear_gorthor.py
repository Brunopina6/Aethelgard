# Gorthor el Devorador (V12, fase C, 12/11/2026, especialista de animaciones): el jefe de la Garganta del Diablo.
# Sustituye en el combate al Grimfang ×1,2 teñido de rojo (goblin.fbx y la imagen 2D siguen de respaldo).
# Lo que hace en el combate (combate.gd, sin cambiar sus reglas): golpe normal (tajo de cuchilla), golpe devastador
# avisado (carga y descarga a dos manos), al 50 % la «Furia del Abismo» (fase 2) y aprende Devorar (muerde al más débil
# y se cura), y en su último aliento cae de rodillas: Kael le perdona (se arrastra hacia el abismo) o acaba con él.
#
#   blender -b --factory-startup -P crear_gorthor.py -- <raíz aethelgard> <carpeta de láminas> [sin_laminas]
#
# Escribe enemigos/gorthor/gorthor.glb (sin imágenes), gorthor.webp (1024), gorthor_bajo.webp (512) y
# gorthor_clips.json; en la carpeta de láminas, la lámina, la hoja de poses, el atlas y el .blend.
#
# Concepto: el caudillo del clan de los Grimfang crecido hasta monstruo (3 m encorvado). Hombros y panza enormes,
# piernas cortas y arqueadas, brazos que casi tocan el suelo; orejas largas de goblin con argollas; una mandíbula
# inferior ENORME que sobresale (prognatismo) con dos colmillos hacia arriba: la boca del Devorador, articulada y
# cerrada de verdad en reposo (el labio de abajo monta por fuera, sin rendija; la lección de Bramavidrio). Corona de
# hueso con cuernos, estandartes rojos del clan a la espalda (los de su arena) y una cuchilla de hierro con el filo
# al rojo. Piel oliva oscura con VETAS DE BRASA en brazos y pecho: el fuego del braserío le corre por dentro (resiste
# el Fuego, débil al Hielo, como la tabla de afinidades de la magia negra); en la fase 2 se encienden del todo.
# No copia diseños de otros juegos: es la familia del Grimfang del proyecto, a lo grande.
#
# Ejes (Blender): mira a -Y, Z arriba, su izquierda es +X. En Godot mira a +Z.
# Esqueleto (26 huesos): raiz, cadera, columna, pecho, cuello, cabeza, mandibula (bisagra; +X abre), capa
# (estandartes), hombro/brazo/antebrazo/mano y muslo/pierna/pie (.L y .R), arma (la cuchilla, hija de mano.R),
# escombros (las lascas del golpe fuerte, escondidas a escala 0,01) y luz (sin malla: su escala X es el brillo de
# ojos, vetas y filo en cada fotograma; gorthor_3d.gd lo multiplica en la fase 2).
# Superficies: «gorthor_atlas» y «gorthor_brillo».
import bpy, sys, os, math, json, random
from mathutils import Vector, Euler, Quaternion, Matrix

argv = sys.argv[sys.argv.index("--") + 1:]
RAIZ, LAMINAS = argv[0], argv[1]
CON_LAMINAS = "sin_laminas" not in argv
sys.path.insert(0, os.path.join(RAIZ, "personajes", "desierto", "fuentes_blender"))
sys.path.insert(0, os.path.join(RAIZ, "enemigos", "v12_comun", "fuente"))
import desierto_comun as C
import enemigos_v12_blender as E
import numpy as np

SALIDA = os.path.join(RAIZ, "enemigos", "gorthor")
NOMBRE = "gorthor"
os.makedirs(LAMINAS, exist_ok=True)
random.seed(29)
esc = C.escena_vacia()
col = esc.collection

# ================================================================== atlas

A = E.AtlasV12(1024, 4, semilla=29)


def xy(h):
    yy, xx = np.mgrid[0:h, 0:h]
    return (xx + 0.5) / h, (yy + 0.5) / h


def pinta_piel(h, rng, base=(0.34, 0.40, 0.25)):
    f = E.fbm(h, rng, 4, 5)
    img = E.color(base) * (0.78 + 0.4 * f[..., None])
    n2 = E.fbm(h, rng, 2, 3)
    img = E.mezclar(img, (0.45, 0.38, 0.26), np.clip((n2 - 0.55) * 2.5, 0, 0.55))     # zonas cálidas, curtidas
    f1, f2 = E.celdas_voronoi(h, rng, 40)
    img = E.mezclar(img, (0.22, 0.27, 0.15), np.clip((0.015 - (f2 - f1)) * 40, 0, 0.22))  # arrugas
    X, Y = xy(h)
    for k in range(5):                                                                 # cicatrices claras
        x0, y0, a = rng.uniform(0.1, 0.9), rng.uniform(0.1, 0.9), rng.uniform(0, 3.14)
        d = np.abs((X - x0) * math.sin(a) - (Y - y0) * math.cos(a))
        largo = np.abs((X - x0) * math.cos(a) + (Y - y0) * math.sin(a)) < 0.12
        img = E.mezclar(img, (0.58, 0.55, 0.40), np.clip((0.006 - d) * 300, 0, 0.8) * largo)
    return img


def pinta_vientre(h, rng):
    return pinta_piel(h, rng, (0.50, 0.50, 0.33))


def pinta_cuero(h, rng):
    X, Y = xy(h)
    img = E.color((0.40, 0.26, 0.16)) * (0.75 + 0.45 * E.fbm(h, rng, 5, 4)[..., None])
    puntadas = ((np.abs(Y - 0.1) < 0.008) | (np.abs(Y - 0.9) < 0.008)) & (((X * 30) % 1) < 0.5)
    return E.mezclar(img, (0.78, 0.70, 0.52), puntadas * 1.0)


def pinta_tela(h, rng):
    """Rojo del clan, gastado, con su emblema: unas fauces (mandíbula y colmillos) en granate oscuro."""
    X, Y = xy(h)
    pliegue = 0.5 + 0.5 * np.sin(X * 28 + E.fbm(h, rng, 3, 2) * 4)
    img = E.color((0.62, 0.11, 0.09)) * (0.72 + 0.25 * pliegue[..., None] + 0.15 * E.fbm(h, rng, 6, 3)[..., None])
    cx, cy = 0.5, 0.55
    u = (X - cx) / 0.30
    v = (Y - cy) / 0.30
    arco = (np.abs(np.sqrt(u * u + (v * 1.3) ** 2) - 0.75) < 0.12) & (v < 0.2)
    emblema = arco.astype(np.float32)
    for k in (-1, 1):
        for j, (ox, alto) in enumerate(((0.42, 0.55), (0.18, 0.3))):
            dx = np.abs(X - (cx + k * ox * 0.30))
            t = (Y - (cy - 0.03)) / (alto * 0.30)
            emblema = np.maximum(emblema, ((dx < 0.035 * (1 - t)) & (t > 0) & (t < 1)).astype(np.float32))
    img = E.mezclar(img, (0.20, 0.03, 0.03), emblema * 0.9)
    deshilado = (Y < 0.06) & (rng.random((h, h)) < 0.5)
    return E.mezclar(img, (0.30, 0.05, 0.04), deshilado * 0.8)


def pinta_hierro(h, rng):
    X, Y = xy(h)
    img = E.color((0.30, 0.30, 0.33)) * (0.75 + 0.4 * E.fbm(h, rng, 5, 4)[..., None])
    for k in range(40):
        x0, y0, a = rng.uniform(0, 1), rng.uniform(0, 1), rng.uniform(0, 3.14)
        d = np.abs((X - x0) * math.sin(a) - (Y - y0) * math.cos(a))
        largo = np.abs((X - x0) * math.cos(a) + (Y - y0) * math.sin(a)) < rng.uniform(0.03, 0.12)
        img = E.mezclar(img, (0.58, 0.58, 0.60), np.clip((0.003 - d) * 400, 0, 0.6) * largo)
    oxido = E.fbm(h, rng, 6, 4)
    return E.mezclar(img, (0.45, 0.24, 0.11), np.clip((oxido - 0.6) * 3, 0, 0.7))


def pinta_hueso(h, rng):
    img = E.color((0.86, 0.80, 0.66)) * (0.82 + 0.25 * E.fbm(h, rng, 4, 4)[..., None])
    g = E.grietas(h, rng, 20, 0.006)
    img = E.mezclar(img, (0.45, 0.38, 0.28), g * 0.7)
    return E.mezclar(img, (0.55, 0.45, 0.30), np.clip((E.fbm(h, rng, 3, 2) - 0.6) * 3, 0, 0.5))


def pinta_boca(h, rng):
    return E.color((0.36, 0.07, 0.07)) * (0.7 + 0.5 * E.fbm(h, rng, 5, 3)[..., None])


def pinta_diente(h, rng):
    return E.color((0.93, 0.87, 0.67)) * (0.85 + 0.2 * E.fbm(h, rng, 4, 3)[..., None])


for nombre, f in (("piel", pinta_piel), ("vientre", pinta_vientre), ("cuero", pinta_cuero), ("tela", pinta_tela),
                  ("hierro", pinta_hierro), ("hueso", pinta_hueso), ("boca", pinta_boca), ("diente", pinta_diente)):
    A.celda(nombre, f)

BRILLO = (1.0, 0.42, 0.10)            # brasa (gorthor_3d.gd, COLOR_BRILLO)

# ================================================================== esqueleto

HUESOS = [
    ("raiz", (0, 0, 0), (0, 0, 0.3), None),
    ("cadera", (0, 0, 1.05), (0, 0, 1.25), "raiz"),
    ("columna", (0, 0, 1.25), (0, 0.02, 1.62), "cadera"),
    ("pecho", (0, 0.02, 1.62), (0, 0.0, 2.10), "columna"),
    ("cuello", (0, -0.05, 2.10), (0, -0.30, 2.30), "pecho"),
    ("cabeza", (0, -0.30, 2.30), (0, -0.40, 2.62), "cuello"),
    ("mandibula", (0, -0.36, 2.27), (0, -0.80, 2.18), "cabeza"),
    ("capa", (0, 0.42, 2.02), (0, 0.50, 1.62), "pecho"),
    ("escombros", (0, -1.95, 0.0), (0, -1.95, 0.2), "raiz"),
    ("luz", (0, 0.1, 0.0), (0, 0.1, 0.15), "raiz"),
]
for s, l in ((".L", 1), (".R", -1)):
    HUESOS += [
        ("hombro" + s, (0.25 * l, 0, 2.00), (0.78 * l, 0, 2.02), "pecho"),
        ("brazo" + s, (0.82 * l, 0, 2.00), (1.05 * l, 0.05, 1.45), "hombro" + s),
        ("antebrazo" + s, (1.05 * l, 0.05, 1.45), (1.12 * l, -0.05, 0.95), "brazo" + s),
        ("mano" + s, (1.12 * l, -0.05, 0.95), (1.14 * l, -0.08, 0.75), "antebrazo" + s),
        ("muslo" + s, (0.32 * l, 0, 1.05), (0.46 * l, -0.06, 0.62), "cadera"),
        ("pierna" + s, (0.46 * l, -0.06, 0.62), (0.42 * l, 0.02, 0.18), "muslo" + s),
        ("pie" + s, (0.42 * l, 0.02, 0.18), (0.42 * l, -0.30, 0.08), "pierna" + s),
    ]
EMP = Vector((-1.13, -0.065, 0.85))
HUESOS.append(("arma", tuple(EMP), tuple(EMP + Vector((0, -0.5, 0))), "mano.R"))
arm = C.crear_armadura(NOMBRE, HUESOS, col)

# ================================================================== malla

m = C.Malla(None, ("atlas", "brillo"))
CR = E.caja_redonda


def pt(vs, celda, pesos, escala=0.9, liso=True):
    return E.proyectar(m, A, vs, celda, escala, pesos, 0, liso)


def brillo(vs, pesos):
    for f in {f for v in vs for f in v.link_faces}:
        f.material_index = 1
        f.smooth = False
        for lp in f.loops:
            lp[m.uv].uv = (0.5, 0.5)
    m.pesar(vs, pesos)
    return vs


def tronco(co):
    return C.por_altura(co.z, [(1.15, "cadera"), (1.45, "columna"), (1.75, "pecho")])


def giro(ax=0, ay=0, az=0):
    return Euler((math.radians(ax), math.radians(ay), math.radians(az)), 'XYZ')


# tronco: panza, pecho, joroba de los trapecios
pt(m.esfera((0, -0.14, 1.30), (0.60, 0.54, 0.50), (20, 12)), "vientre", tronco)
pt(m.esfera((0, 0.0, 1.86), (0.80, 0.56, 0.48), (20, 12)), "piel", tronco)
pt(m.esfera((0, 0.16, 2.10), (0.56, 0.36, 0.26), (16, 8)), "piel", "pecho")
pt(m.esfera((0, -0.08, 1.10), (0.50, 0.42, 0.22), (16, 8)), "piel", "cadera")
# cinturón ancho con hebilla de cráneo, taparrabos y estandartes del clan
pts = [(math.cos(a) * 0.60, -0.10 + math.sin(a) * 0.52, 1.13) for a in np.linspace(0, 2 * math.pi, 17)]
pt(m.tubo(pts, [(0.07, 0.035)] * 17, 6, ref=Vector((0, 0, 1))), "cuero", "cadera", 0.6)
pt(m.esfera((0, -0.64, 1.13), (0.11, 0.07, 0.10), (10, 6)), "hueso", "cadera", 0.4)
for l in (1, -1):
    brillo(m.esfera((0.04 * l, -0.705, 1.15), (0.02, 0.01, 0.02), (6, 4)), "cadera")
E.plano_uv(m, A, CR(m, (0, -0.60, 0.80), (0.46, 0.04, 0.58), giro(-8, 0, 0), redondez=0.2, cortes=2),
           "tela", (-0.23, -0.6, 0.51), (1, 0, 0), (0, 0, 1), 0.46, 0.58,
           lambda co: C.por_altura(co.z, [(0.6, "cadera"), (1.0, "cadera")]))
E.plano_uv(m, A, CR(m, (0, 0.42, 0.82), (0.52, 0.04, 0.56), giro(8, 0, 0), redondez=0.2, cortes=2),
           "tela", (-0.26, 0.42, 0.54), (1, 0, 0), (0, 0, 1), 0.52, 0.56, "cadera")
for l in (1, -1):
    E.plano_uv(m, A, CR(m, (0.30 * l, 0.56, 1.42), (0.42, 0.04, 1.15), giro(-6, 0, 4 * l), redondez=0.15, cortes=2),
               "tela", (0.30 * l - 0.21, 0.56, 0.85), (1, 0, 0), (0, 0, 1), 0.42, 1.15, "capa")
    pt(m.tubo([(0.30 * l - 0.25, 0.52, 2.0), (0.30 * l + 0.25, 0.52, 2.0)], [0.03, 0.03], 6), "hueso", "capa", 0.5)
# vetas de brasa en el pecho y la panza: grietas quebradas con ramas, pegadas a la piel (tubos finos sobre el
# elipsoide del pecho o de la panza, el que esté más delante)
def sobre_piel(x, z):
    ys = []
    for (cy, cz, rx, ry, rz) in ((0.0, 1.86, 0.80, 0.56, 0.48), (-0.14, 1.30, 0.60, 0.54, 0.50)):
        t = 1 - (x / rx) ** 2 - ((z - cz) / rz) ** 2
        if t > 0:
            ys.append(cy - ry * math.sqrt(t))
    return Vector((x, min(ys) - 0.008 if ys else -0.5, z))


rnd_v = random.Random(31)
for (x0, z0), a0 in (((-0.30, 2.02), -70), ((0.28, 2.04), -105), ((-0.05, 1.62), -80), ((0.22, 1.50), -60),
                     ((-0.28, 1.42), -110)):
    for camino in E.camino_grieta(rnd_v, (x0, z0), a0, pasos=5, paso=0.07, quiebro=34, ramas=1):
        pts = [sobre_piel(x, z) for x, z in camino]
        brillo(m.tubo(pts, [0.016] + [0.012] * (len(pts) - 2) + [0.004], 4), tronco)
# cuello y cabeza
pt(m.tubo([(0, 0.0, 2.05), (0, -0.25, 2.28)], [0.26, 0.24], 10), "piel", "cuello")
pt(m.esfera((0, -0.50, 2.42), (0.30, 0.31, 0.27), (16, 10)), "piel", "cabeza", 0.6)
pt(m.esfera((0, -0.70, 2.50), (0.28, 0.11, 0.075), (12, 6)), "piel", "cabeza", 0.6)          # ceja de hueso
pt(m.esfera((0, -0.73, 2.33), (0.22, 0.14, 0.11), (12, 8)), "piel", "cabeza", 0.6)           # hocico
pt(m.esfera((0, -0.84, 2.40), (0.08, 0.06, 0.06), (8, 6)), "piel", "cabeza", 0.5)            # nariz chata
for l in (1, -1):
    brillo(m.esfera((0.11 * l, -0.765, 2.45), (0.04, 0.02, 0.025), (8, 5)), "cabeza")       # ojos de brasa
    pt(m.tubo([(0.24 * l, -0.48, 2.46), (0.45 * l, -0.42, 2.55), (0.66 * l, -0.34, 2.66)],
              [(0.10, 0.03), (0.07, 0.02), (0.01, 0.005)], 6, ref=Vector((0, 0, 1))), "piel", "cabeza", 0.5)
    pts = [Vector((0.52 * l, -0.40, 2.58)) + Vector((0, math.cos(a) * 0.06, math.sin(a) * 0.06))
           for a in np.linspace(0, 2 * math.pi, 9)]
    pt(m.tubo(pts, [0.012] * 9, 5), "hierro", "cabeza", 0.3)
    # colmillos de la mandíbula, hacia arriba por fuera del labio
    pt(m.cono((0.19 * l, -0.86, 2.24), (0.22 * l, -0.92, 2.52), 0.055, 7), "diente", "mandibula", 0.4)
    # dientes de arriba (escondidos tras el labio de abajo con la boca cerrada)
    for k, x in enumerate((0.06, 0.13)):
        pt(m.cono((x * l, -0.79, 2.27), (x * l, -0.80, 2.17), 0.025, 5), "diente", "cabeza", 0.3)
# la mandíbula del Devorador (prognata: su labio monta por fuera; cerrada no deja rendija) y el interior de la boca
pt(CR(m, (0, -0.66, 2.19), (0.52, 0.52, 0.17), redondez=0.6, cortes=2), "piel", "mandibula", 0.6)
pt(CR(m, (0, -0.64, 2.275), (0.40, 0.40, 0.03), redondez=0.4, cortes=1), "boca", "mandibula", 0.5)
pt(CR(m, (0, -0.60, 2.31), (0.42, 0.38, 0.12), redondez=0.5, cortes=1), "boca", "cabeza", 0.5)
for k, x in enumerate((-0.09, -0.03, 0.03, 0.09)):
    pt(m.cono((x, -0.89, 2.27), (x, -0.90, 2.33), 0.022, 5), "diente", "mandibula", 0.3)
# corona de hueso: aro, púas y dos cuernos curvos
pts = [(math.cos(a) * 0.25, -0.45 + math.sin(a) * 0.26, 2.63) for a in np.linspace(0, 2 * math.pi, 13)]
pt(m.tubo(pts, [0.04] * 13, 6), "hueso", "cabeza", 0.4)
for k in range(5):
    a = math.pi * (0.15 + 0.7 * k / 4)
    p = Vector((math.cos(a) * 0.25, -0.45 - math.sin(a) * 0.26, 2.64))
    pt(m.cono(p, p + Vector((0, -0.03, 0.16 + 0.05 * (k == 2))), 0.035, 5), "hueso", "cabeza", 0.3)
for l in (1, -1):
    pt(m.tubo([(0.20 * l, -0.40, 2.64), (0.36 * l, -0.35, 2.80), (0.50 * l, -0.32, 3.00), (0.47 * l, -0.40, 3.14)],
              [0.075, 0.06, 0.04, 0.008], 7), "hueso", "cabeza", 0.5)
# brazos (piel con brazales de hierro, vetas de brasa) y puños
for s, l in ((".L", 1), (".R", -1)):
    H, K, W = Vector((0.82 * l, 0, 2.0)), Vector((1.05 * l, 0.05, 1.45)), Vector((1.12 * l, -0.05, 0.95))
    pt(m.esfera(H + Vector((-0.04 * l, 0, 0.02)), (0.30, 0.30, 0.26), (14, 8)), "piel", "hombro" + s)
    pt(m.tubo([H, (H + K) / 2, K], [0.22, 0.21, 0.17], 12),
       "piel", C.por_eje(H, K, [(0.85, "brazo" + s), (1.05, "antebrazo" + s)]))
    pt(m.tubo([K, K.lerp(W, 0.4), W], [0.17, 0.21, 0.15], 12),
       "piel", C.por_eje(K, W, [(-0.1, "brazo" + s), (0.12, "antebrazo" + s)]))
    for z in (0.0, 0.25):
        pts = [W.lerp(K, 0.15 + z) + Vector((math.cos(a) * 0.19, math.sin(a) * 0.19, 0)) for a in np.linspace(0, 6.28, 11)]
        pt(m.tubo(pts, [0.035] * 11, 5), "hierro", "antebrazo" + s, 0.4)
    for j in range(2):
        a = K.lerp(W, 0.45 + 0.1 * j) + Vector((0.12 * l, -0.12, 0.02 * j))
        b = K.lerp(W, 0.75 + 0.1 * j) + Vector((0.10 * l, -0.14, 0))
        brillo(m.tubo([a, b], [0.015, 0.01], 4), "antebrazo" + s)
    pt(m.esfera(W + Vector((0.01 * l, -0.03, -0.12)), (0.17, 0.18, 0.16), (12, 8)), "piel", "mano" + s, 0.5)
    pt(m.cono(W + Vector((-0.08 * l, -0.12, -0.05)), W + Vector((-0.12 * l, -0.20, -0.14)), 0.05, 6), "piel",
       "mano" + s, 0.5)
# hombrera de hierro con púas (izquierda)
pt(CR(m, (0.86, 0.0, 2.20), (0.48, 0.52, 0.18), giro(0, -24, 0), redondez=0.6, cortes=2), "hierro", "hombro.L", 0.6)
for k in range(3):
    p = Vector((0.80 + 0.12 * k, -0.15 + 0.15 * k, 2.29 - 0.05 * k))
    pt(m.cono(p, p + Vector((0.08, 0, 0.20)), 0.045, 5), "hueso", "hombro.L", 0.3)
# piernas arqueadas y pies con garras
for s, l in ((".L", 1), (".R", -1)):
    Hh, Kk, Aa = Vector((0.32 * l, 0, 1.05)), Vector((0.46 * l, -0.06, 0.62)), Vector((0.42 * l, 0.02, 0.18))
    pt(m.tubo([Hh, Kk], [0.26, 0.19], 12), "piel",
       C.por_eje(Hh, Kk, [(0.8, "muslo" + s), (1.05, "pierna" + s)]))
    pt(m.tubo([Kk, Aa], [0.18, 0.13], 12), "piel", C.por_eje(Kk, Aa, [(-0.1, "muslo" + s), (0.15, "pierna" + s)]))
    pt(m.esfera(Kk + Vector((0, -0.06, 0)), (0.16, 0.14, 0.13), (10, 6)), "cuero", "pierna" + s, 0.4)
    pt(CR(m, (0.43 * l, -0.12, 0.09), (0.30, 0.44, 0.17), redondez=0.6, cortes=2), "piel", "pie" + s, 0.5)
    for k in (-1, 0, 1):
        p = Vector((0.43 * l + 0.09 * k, -0.33, 0.07))
        pt(m.cono(p, p + Vector((0.02 * k, -0.12, -0.04)), 0.04, 5), "hueso", "pie" + s, 0.3)
# la cuchilla (hija de mano.R; en reposo hacia delante, la hoja colgando bajo el mango) con el filo al rojo
pt(m.tubo([EMP + Vector((0, 0.18, 0)), EMP + Vector((0, -1.0, 0))], [0.045, 0.04], 8), "cuero", "arma", 0.5)
pt(m.esfera(EMP + Vector((0, 0.21, 0)), (0.07, 0.07, 0.07), (8, 6)), "hueso", "arma", 0.4)
pt(CR(m, EMP + Vector((0, -0.80, -0.20)), (0.06, 0.64, 0.46), redondez=0.25, cortes=2), "hierro", "arma", 0.8)
pt(m.cono(EMP + Vector((0, -1.10, 0.0)), EMP + Vector((0, -1.24, 0.14)), 0.05, 5), "hierro", "arma", 0.4)
brillo(m.caja(EMP + Vector((0, -0.80, -0.435)), (0.07, 0.62, 0.02)), "arma")
# lascas del golpe fuerte
ESC0 = Vector((0, -1.95, 0))
for k in range(7):
    a = 2 * math.pi * k / 7 + 0.4
    r = 0.30 + 0.12 * (k % 2)
    pt(E.roca(m, ESC0 + Vector((math.cos(a) * r, math.sin(a) * r, 0.12)), 0.12, 40 + k, 0, 0.35, (0.8, 0.8, 1.9),
              Euler((math.cos(a) * 0.5, -math.sin(a) * 0.5, a))), "hierro", "escombros", 0.5, liso=False)

ob = m.objeto(NOMBRE, col)
E.materiales(ob, [NOMBRE + "_atlas", NOMBRE + "_brillo"])
C.enlazar(ob, arm)
TRIS = C.triangulos(ob)
E.oclusion(ob, rayos=24, dist=0.5, minimo=0.42)
print("triángulos:", TRIS)

# ================================================================== poses y clips

rig = E.Rig(arm, polo_codo={".L": Vector((0.7, 0.6, -0.2)), ".R": Vector((-0.7, 0.6, -0.2))})
rig.poner_arma("arma", atras=0.20)
rig.defecto = {"escombros@esc": (0.01, 0.01, 0.01), "escombros@loc": (0, 0, -0.3),
               "mano.L@ik": (0.6, -0.6, 1.2), "mano.L@ikw": 0.0, "mano.R@ik": (-0.6, -0.6, 1.2), "mano.R@ikw": 0.0}
CLIPS = {}
L, R, sim = E.L, E.R, E.sim


def P(*ds):
    out = {}
    for d in ds:
        out.update(d)
    return out


def luz(v):
    return {"luz@esc": (v, v, v)}


def hacia(v, roll=0.0):
    q = Vector((0, -1, 0)).rotation_difference(Vector(v).normalized())
    if roll:
        q = Quaternion(Vector(v).normalized(), math.radians(roll)) @ q
    return tuple(math.degrees(a) for a in q.to_euler('XYZ'))


def boca(g):
    return {"mandibula": (g, 0, 0)}


def clip(nombre, claves, bucle=False, proc=None, eventos=None):
    act, dur = rig.clip(nombre, claves, bucle, proc=proc)
    CLIPS[nombre] = {"duracion": round(dur, 4), "bucle": bucle, "eventos": eventos or {}}


ENCORVADO = {"pecho": (12, 0, 0), "cuello": (-8, 0, 0), "cabeza": (-6, 0, 0)}
# en reposo: la cuchilla al hombro derecho, el brazo izquierdo colgando, la boca cerrada
REPOSO = P(ENCORVADO, {"arma@pos": (-0.70, -0.44, 1.72), "arma@dir": hacia((0.15, 0.55, 0.82)), "arma@roll": 90,
                       "codo.R@polo": (-0.8, 0.2, -0.6)}, L(brazo=(-8, -6, 0), antebrazo=(-16, 0, 0)), boca(0), luz(1.0))
GUARDIA = P(ENCORVADO, {"arma@pos": (-0.98, -0.30, 1.05), "arma@dir": hacia((-0.05, -0.75, -0.35)),
                        "pecho": (18, 0, 0)}, L(brazo=(-20, -10, 0), antebrazo=(-30, 0, 0)), boca(0), luz(1.0))
clip("reposo", [(0, REPOSO), (0.8, P(REPOSO, {"pecho": (9, 0, 2), "cabeza": (-9, 0, 6), "raiz@loc": (0, 0, 0.015)})),
                (1.3, P(REPOSO, boca(7))), (1.5, P(REPOSO, boca(0))),
                (2.0, P(REPOSO, {"pecho": (13, 0, -2), "cabeza": (-4, 0, -6)})), (2.6, REPOSO)], bucle=True)


def pasos(dur, paso, alto, bote, ancho=0.42, inclina=0.0, brazo_libre=18):
    def f(seg):
        out = {}
        for s, desfase, l in ((".L", 0.0, 1), (".R", 0.5, -1)):
            fa = (seg / dur + desfase) % 1.0
            if fa < 0.5:
                y, z, rx = -paso / 2 + paso * (fa / 0.5), 0.18, 0.0
            else:
                t = (fa - 0.5) / 0.5
                y = paso / 2 - paso * (0.5 - 0.5 * math.cos(math.pi * t))
                z = 0.18 + alto * math.sin(math.pi * t)
                rx = -20 * math.sin(math.pi * t)
            out["pie" + s + "@ik"] = (ancho * l, y + 0.02, z)
            out["pie" + s + "@rot"] = (rx, 0, 0)
        fase = 2 * math.pi * seg / dur
        out["raiz@loc"] = (0.04 * math.sin(fase), 0, -bote * (0.5 + 0.5 * math.cos(2 * fase)))
        out["pecho"] = (14 + inclina, -5 * math.sin(fase), -8 * math.sin(fase))
        out["cadera"] = (0, 4 * math.sin(fase), 7 * math.sin(fase))
        out["brazo.L"] = (-10 - brazo_libre * math.sin(fase), -8, 0)
        out["capa"] = (-6 - 4 * math.cos(2 * fase), 0, 0)
        return out
    return f


clip("caminar", [(0, REPOSO), (1.4, REPOSO)], bucle=True, proc=pasos(1.4, 0.55, 0.16, 0.04))
clip("correr", [(0, GUARDIA), (0.8, GUARDIA)], bucle=True, proc=pasos(0.8, 0.9, 0.24, 0.08, inclina=12, brazo_libre=34))

# entrada (2,4 s): agazapado, se yergue, se golpea el pecho dos veces y ruge con las fauces abiertas
AGAZAPADO = P(REPOSO, {"raiz@loc": (0, 0.05, -0.25), "pecho": (35, 0, 0), "cuello": (10, 0, 0), "cabeza": (10, 0, 0),
                       "arma@pos": (-0.85, -0.55, 1.05), "arma@dir": hacia((0, -0.85, -0.53)), "arma@roll": 0},
              luz(0.4))
PECHO = P(REPOSO, {"mano.L@ik": (0.22, -0.62, 1.92), "mano.L@ikw": 1.0, "pecho": (0, 0, 0), "cabeza": (-14, 0, 0)},
          boca(10), luz(1.4))
RUGIDO = P(REPOSO, {"pecho": (-14, 0, 0), "cuello": (-24, 0, 0), "cabeza": (-20, 0, 0),
                    "arma@pos": (-1.0, -0.20, 2.45), "arma@dir": hacia((-0.2, 0.2, 0.96)), "arma@roll": 0},
           L(brazo=(-40, -70, 0), antebrazo=(-30, 0, 0)), boca(58), luz(2.2))
clip("entrada", [(0, AGAZAPADO), (0.35, AGAZAPADO), (0.75, P(REPOSO, {"pecho": (2, 0, 0)}, luz(1.2))),
                 (0.9, PECHO, "acel"), (1.02, P(PECHO, {"mano.L@ik": (0.35, -0.85, 1.85)})), (1.15, PECHO, "acel"),
                 (1.4, RUGIDO, "fren"), (1.9, P(RUGIDO, {"cabeza": (-24, 0, 4)}, boca(62))),
                 (2.4, REPOSO)], eventos={"pecho": 0.9, "pecho2": 1.15, "rugido": 1.4})

# ataque (1,4 s; atacar_hacha): la cuchilla atrás a su derecha y un tajo horizontal hacia su izquierda: IMPACTO 0,75 s
ATRAS = P(REPOSO, {"arma@pos": (-1.0, 0.30, 1.55), "arma@dir": hacia((-0.45, 0.88, 0.15)), "arma@roll": 0,
                   "pecho": (8, 0, -32), "cadera": (0, 0, -12), "cabeza": (-6, 0, 22)}, boca(14), luz(1.3))
TAJO = P(REPOSO, {"arma@pos": (0.15, -0.80, 1.22), "arma@dir": hacia((0.78, -0.6, -0.12)), "arma@roll": 0,
                  "pecho": (20, 0, 26), "cadera": (0, 0, 10), "cabeza": (-14, 0, -16), "raiz@loc": (0, -0.25, -0.08),
                  "pie.L@ik": (0.46, -0.35, 0.18)}, boca(22), luz(1.6))
SIGUE = P(TAJO, {"arma@pos": (0.55, -0.42, 1.18), "arma@dir": hacia((0.95, 0.2, -0.15)), "pecho": (22, 0, 34)})
clip("ataque", [(0, REPOSO), (0.4, ATRAS), (0.52, P(ATRAS, {"pie.L@ik": (0.45, -0.15, 0.32)})), (0.75, TAJO, "acel"),
                (0.92, SIGUE, "fren"), (1.1, P(SIGUE, {"pie.L@ik": (0.45, -0.15, 0.28)})), (1.4, REPOSO)],
     eventos={"impacto": 0.75})

# carga (1 s) y su espera (1,4 s, bucle): la cuchilla en alto con las dos manos, gruñe con la boca entreabierta
ALTO = P(REPOSO, {"arma@pos": (-0.05, -0.12, 2.62), "arma@dir": hacia((0, 0.55, 0.83)), "arma@roll": 0,
                  "mano.L@agarre": 1.0, "codo.L@polo": (0.8, -0.2, 0.2), "codo.R@polo": (-0.8, -0.2, 0.2),
                  "pecho": (-6, 0, 0), "cuello": (-14, 0, 0), "cabeza": (-10, 0, 0)}, boca(24), luz(2.4))
clip("carga", [(0, REPOSO), (0.5, P(ALTO, {"pecho": (4, 0, 0)}, boca(10), luz(1.8))), (1.0, ALTO)],
     eventos={"en_alto": 1.0})
clip("carga_espera", [(0, ALTO), (0.35, P(ALTO, {"pecho": (-8, 0, 2), "raiz@loc": (0, 0, 0.02)}, boca(30), luz(3.0))),
                      (0.7, ALTO), (1.05, P(ALTO, {"pecho": (-8, 0, -2), "raiz@loc": (0, 0, 0.02)}, boca(30), luz(3.0))),
                      (1.4, ALTO)], bucle=True)

# golpe fuerte (1,8 s): sube la cuchilla (0-0,5 s; desde la carga empieza en 0,5), se echa atrás y la descarga a dos
# manos contra el suelo: IMPACTO 0,95 s, las lascas brotan; la arranca y vuelve
ALTO2 = P(ALTO, {"arma@pos": (-0.05, 0.05, 2.72), "arma@dir": hacia((0, 0.8, 0.6)), "pecho": (-14, 0, 0),
                 "raiz@loc": (0, 0.05, 0.03), "pie.R@ik": (-0.42, -0.10, 0.32)}, boca(40), luz(3.2))
FONDO = P(REPOSO, {"arma@pos": (0.0, -0.85, 1.18), "arma@dir": hacia((0, -0.45, -0.89)), "arma@roll": 0,
                   "mano.L@agarre": 1.0, "codo.L@polo": (0.8, 0.4, -0.2), "codo.R@polo": (-0.8, 0.4, -0.2),
                   "raiz@loc": (0, -0.35, -0.20), "pecho": (40, 0, 0), "columna": (10, 0, 0), "cuello": (-20, 0, 0),
                   "cabeza": (-14, 0, 0), "pie.R@ik": (-0.44, -0.45, 0.18), "pie.L@ik": (0.42, 0.25, 0.18),
                   "pie.L@rot": (-18, 0, 0)}, boca(46), luz(4.0))
ESC_OFF = {"escombros@esc": (0.01, 0.01, 0.01), "escombros@loc": (0, 0, -0.3)}
ESC_ON = {"escombros@esc": (1, 1, 1), "escombros@loc": (0, 0, 0)}
clip("golpe_fuerte", [(0, REPOSO), (0.5, ALTO), (0.68, ALTO2), (0.949, P(FONDO, ESC_OFF), "acel"),
                      (0.95, P(FONDO, ESC_ON), "corte"), (1.25, P(FONDO, {"pecho": (36, 0, 0)}, ESC_ON, boca(20), luz(2.0))),
                      (1.45, P(FONDO, {"arma@pos": (-0.1, -0.80, 1.35), "pecho": (28, 0, 0)}, boca(10), luz(1.5),
                               {"escombros@esc": (1, 1, 1), "escombros@loc": (0, 0, -0.06)})),
                      (1.6, P(REPOSO, {"pie.R@ik": (-0.42, -0.2, 0.28)}, {"escombros@esc": (0.6, 0.6, 0.6),
                                                                           "escombros@loc": (0, 0, -0.22)})),
                      (1.8, REPOSO)], eventos={"impacto": 0.95, "carga": 0.5})

# devorar (1,9 s): se lanza encorvado con la zarpa izquierda por delante y las fauces abiertas (0,6 s), MUERDE (cierra
# de golpe: IMPACTO 0,9 s), sacude la presa, la suelta y traga (1,5 s)
LANZA = P(REPOSO, {"raiz@loc": (0, -0.55, -0.15), "pecho": (40, 0, 0), "columna": (10, 0, 0), "cuello": (6, 0, 0),
                   "cabeza": (-34, 0, 0), "mano.L@ik": (0.35, -1.45, 1.25), "mano.L@ikw": 1.0,
                   "arma@pos": (-0.95, -0.45, 0.95), "arma@dir": hacia((-0.1, -0.5, -0.86)), "arma@roll": 0,
                   "pie.L@ik": (0.44, -0.45, 0.18)}, boca(56), luz(1.8))
MUERDE = P(LANZA, {"cabeza": (-18, 0, 0), "cuello": (12, 0, 0), "mano.L@ik": (0.20, -1.25, 1.55)}, boca(0), luz(2.4))
clip("devorar", [(0, REPOSO), (0.35, P(REPOSO, {"pecho": (2, 0, 0), "cabeza": (-20, 0, 0)}, boca(20))),
                 (0.6, LANZA, "fren"), (0.9, MUERDE, "acel"),
                 (1.05, P(MUERDE, {"cabeza": (-18, 0, 18)})), (1.2, P(MUERDE, {"cabeza": (-18, 0, -18)})),
                 (1.32, P(MUERDE, {"cabeza": (-18, 0, 10)})),
                 (1.5, P(REPOSO, {"cuello": (-28, 0, 0), "cabeza": (-24, 0, 0), "pecho": (2, 0, 0)}, boca(8))),
                 (1.62, P(REPOSO, {"cuello": (-22, 0, 0), "cabeza": (-18, 0, 0)}, boca(0))), (1.9, REPOSO)],
     eventos={"abre": 0.6, "impacto": 0.9, "trago": 1.5})

# fase 2 (2,2 s): «¡Furia del Abismo!»: pisotón (0,5 s), ruge al cielo con los brazos abiertos y las vetas se encienden
FURIA = P(RUGIDO, {"pecho": (-22, 0, 0), "cuello": (-28, 0, 0), "cabeza": (-24, 0, 0)},
          L(brazo=(-30, -80, 0), antebrazo=(-20, 0, 0)), boca(64), luz(3.6))
clip("fase2", [(0, REPOSO), (0.32, P(REPOSO, {"raiz@loc": (0, 0, -0.12), "pecho": (30, 0, 0),
                                              "pie.R@ik": (-0.42, -0.08, 0.42)}, luz(1.2))),
               (0.5, P(REPOSO, {"raiz@loc": (0, 0, -0.16), "pecho": (34, 0, 0)}, luz(1.6)), "acel"),
               (0.9, FURIA, "fren"), (1.3, P(FURIA, {"raiz@loc": (0, 0, 0.02)}, luz(4.0))),
               (1.7, P(FURIA, {"cabeza": (-20, 0, 6)}, boca(58), luz(3.4))), (2.2, P(REPOSO, luz(1.6)))],
     eventos={"pisoton": 0.5, "rugido": 0.9})

# recibir golpe (0,7 s)
DOLOR = P(REPOSO, {"pecho": (0, 0, 10), "cuello": (-20, 0, 8), "cabeza": (-20, 0, 12), "raiz@loc": (0, 0.12, 0)},
          L(brazo=(12, -24, 0)), boca(26), luz(0.5))
clip("recibir_golpe", [(0, REPOSO), (0.12, DOLOR, "fren"), (0.32, P(DOLOR, boca(10), luz(1.2))), (0.7, REPOSO)],
     eventos={"golpe": 0.0})

# rendirse (1,5 s): se tambalea, se le escurre la cuchilla, cae de rodillas (0,8 s) con una mano en el suelo y la
# cabeza gacha; «rendido» (2,4 s, bucle) es esa espera; «arrastrarse» (1,2 s, bucle), si le perdonan: a gatas,
# arrastrando la cuchilla
SUELO_ARMA = {"arma@pos": (-0.80, -0.30, 0.07), "arma@dir": hacia((0.15, -0.95, 0.0)), "arma@roll": 90,
              "mano.R@suelta": 1.0}
RODILLAS = P(REPOSO, SUELO_ARMA, {"raiz@loc": (0, 0.10, -0.52), "pecho": (34, 0, 0), "cuello": (16, 0, 0),
                                  "cabeza": (18, 0, 0), "mano.L@ik": (0.62, -0.60, 0.10), "mano.L@ikw": 1.0,
                                  "mano.R@ik": (-0.52, -0.45, 0.62), "mano.R@ikw": 1.0,
                                  "pie.L@ik": (0.42, 0.62, 0.12), "pie.R@ik": (-0.42, 0.62, 0.12),
                                  "pie.L@rot": (70, 0, 0), "pie.R@rot": (70, 0, 0)}, boca(6), luz(0.35))
clip("rendirse", [(0, REPOSO), (0.28, P(DOLOR, {"raiz@loc": (0, 0.16, -0.04)})),
                  (0.55, P(DOLOR, SUELO_ARMA, {"raiz@loc": (0, 0.14, -0.2), "mano.R@ik": (-0.9, -0.3, 0.9),
                                               "mano.R@ikw": 1.0}, boca(12), luz(0.6))),
                  (0.8, RODILLAS, "acel"), (1.0, P(RODILLAS, {"pecho": (38, 0, 0)})), (1.5, RODILLAS)],
     eventos={"suelta_arma": 0.55, "rodillas": 0.8})
clip("rendido", [(0, RODILLAS), (0.8, P(RODILLAS, {"pecho": (31, 0, 0), "raiz@loc": (0, 0.10, -0.50)})),
                 (1.2, P(RODILLAS, {"cuello": (2, 0, 0), "cabeza": (-6, 0, 0)}, boca(4))),
                 (1.7, P(RODILLAS, {"pecho": (36, 0, 0)})), (2.4, RODILLAS)], bucle=True,
     eventos={"mira": 1.2})


def gatas(seg):
    dur = 1.2
    out = {}
    for s, desfase, l in ((".L", 0.0, 1), (".R", 0.5, -1)):
        fa = (seg / dur + desfase) % 1.0
        if fa < 0.6:
            y, z = -0.95 + 0.55 * (fa / 0.6), 0.10
        else:
            t = (fa - 0.6) / 0.4
            y, z = -0.40 - 0.55 * (0.5 - 0.5 * math.cos(math.pi * t)), 0.10 + 0.18 * math.sin(math.pi * t)
        if s == ".L":
            out["mano.L@ik"] = (0.62, y, z)
        else:
            out["arma@pos"] = (-0.62, y - 0.05, z)
        fb = (seg / dur + desfase + 0.25) % 1.0
        out["pie" + s + "@ik"] = (0.42 * l, 0.55 + (0.14 * (fb / 0.6) if fb < 0.6 else 0.14 * (1 - (fb - 0.6) / 0.4)),
                                  0.12 + (0.06 * math.sin(math.pi * (fb - 0.6) / 0.4) if fb >= 0.6 else 0.0))
    fase = 2 * math.pi * seg / dur
    out["raiz@loc"] = (0.03 * math.sin(fase), 0.05, -0.58 + 0.025 * math.cos(2 * fase))
    out["pecho"] = (52, 5 * math.sin(fase), -6 * math.sin(fase))
    out["cabeza"] = (-26, 0, 4 * math.sin(fase))
    return out


GATAS = P(RODILLAS, {"arma@pos": (-0.62, -0.7, 0.1), "arma@dir": hacia((0.05, 1.0, -0.02)), "arma@roll": 90,
                     "mano.R@suelta": 0.0, "mano.R@ikw": 0.0, "cuello": (-30, 0, 0), "columna": (14, 0, 0)}, boca(10))
clip("arrastrarse", [(0, GATAS), (1.2, GATAS)], bucle=True, proc=gatas)

# victoria (2 s): se ríe con la panza (la mandíbula abre y cierra) y alza la cuchilla
RISA = P(REPOSO, {"arma@pos": (-0.95, -0.25, 2.62), "arma@dir": hacia((-0.15, 0.1, 0.98)), "arma@roll": 0,
                  "pecho": (-8, 0, 0), "cuello": (-20, 0, 0), "cabeza": (-18, 0, 0),
                  "mano.L@ik": (0.45, -0.62, 1.30), "mano.L@ikw": 1.0}, luz(1.8))
clip("victoria", [(0, REPOSO), (0.4, P(RISA, boca(30))), (0.6, P(RISA, boca(6), {"raiz@loc": (0, 0, -0.03)})),
                  (0.8, P(RISA, boca(32))), (1.0, P(RISA, boca(6), {"raiz@loc": (0, 0, -0.03)})),
                  (1.2, P(RISA, boca(34))), (1.45, P(RISA, boca(4))), (2.0, P(RISA, boca(0), luz(1.4)))],
     eventos={"risa": 0.4})

# derrota (2,2 s; de pie): el golpe, un paso atrás y cae de espaldas (suelo 1,3 s); la cuchilla se le cae al lado
TUMBADO = P(REPOSO, SUELO_ARMA, {"raiz": (-78, 0, 0), "raiz@loc": (0, 0.55, -0.12), "pecho": (-6, 0, 0),
                                 "cuello": (-10, 0, 0), "cabeza": (-12, 0, 14), "mano.R@ik": (-1.1, 0.6, 0.15),
                                 "mano.R@ikw": 1.0, "pie.L@ik": (0.5, -0.4, 0.22), "pie.R@ik": (-0.45, -0.3, 0.2)},
            L(brazo=(20, -60, 0)), boca(30), luz(0.0))
clip("derrota", [(0, REPOSO), (0.2, P(DOLOR, luz(0.3))), (0.5, P(DOLOR, {"raiz@loc": (0, 0.25, -0.05),
                                                                        "pie.L@ik": (0.42, 0.25, 0.18)}, luz(0.4))),
                 (1.3, TUMBADO, "acel"), (1.5, P(TUMBADO, {"raiz@loc": (0, 0.55, -0.09)})), (2.2, TUMBADO)],
     eventos={"suelo": 1.3})
# derrota desde de rodillas («Acabar»): se desploma de lado
DE_LADO = P(RODILLAS, {"raiz": (0, 72, 0), "raiz@loc": (0.35, 0.10, -0.55), "pecho": (20, 0, 0), "cabeza": (10, 0, 20),
                       "mano.L@ikw": 0.0}, boca(28), luz(0.0))
clip("derrota_rendido", [(0, RODILLAS), (0.25, P(RODILLAS, {"pecho": (20, 0, 0), "cabeza": (-10, 0, 0)}, luz(0.5))),
                         (0.9, DE_LADO, "acel"), (1.1, P(DE_LADO, {"raiz@loc": (0.35, 0.10, -0.52)})), (1.6, DE_LADO)],
     eventos={"suelo": 0.9})


def medir():
    datos = {}
    for c_, t in (("ataque", 0.75), ("golpe_fuerte", 0.95)):
        p = E.punto_hueso(arm, rig, c_, t, "arma", (0, 0.80, 0.44))
        datos[c_] = {"filo_godot": [round(p.x, 3), round(p.z, 3), round(-p.y, 3)]}
    p = E.punto_hueso(arm, rig, "devorar", 0.9, "mandibula", (0, 0.5, 0))
    datos["devorar"] = {"boca_godot": [round(p.x, 3), round(p.z, 3), round(-p.y, 3)]}
    p = E.punto_hueso(arm, rig, "reposo", 0.0, "cabeza", (0, 0.5, 0))
    datos["alto_reposo"] = round(p.z, 3)
    return datos


medidas = medir()
arm.animation_data.action = None
for pb in arm.pose.bones:
    pb.rotation_quaternion = Quaternion()
    pb.location = Vector()
    pb.scale = Vector((1, 1, 1))

A.guardar(os.path.join(LAMINAS, NOMBRE + "_atlas.png"),
          [(os.path.join(SALIDA, NOMBRE + ".webp"), 1024), (os.path.join(SALIDA, NOMBRE + "_bajo.webp"), 512)])
E.exportar(os.path.join(SALIDA, NOMBRE + ".glb"))
E.guardar_json(os.path.join(SALIDA, NOMBRE + "_clips.json"), {
    "modelo": NOMBRE, "triangulos": TRIS, "huesos": len(HUESOS), "fps": E.FPS,
    "texturas": {"alto": NOMBRE + ".webp (1024)", "bajo": NOMBRE + "_bajo.webp (512)"},
    "color_brillo": BRILLO, "clips": CLIPS, "medidas": medidas,
    "generador": "enemigos/gorthor/fuente/crear_gorthor.py (Blender 5.2.3)"})
print("clips:", {k: v["duracion"] for k, v in CLIPS.items()})
print("medidas:", medidas)

if CON_LAMINAS:
    img = bpy.data.images.load(os.path.join(SALIDA, NOMBRE + ".webp"))
    E.material_vista(bpy.data.materials[NOMBRE + "_atlas"], img)
    E.material_vista(bpy.data.materials[NOMBRE + "_brillo"], None, emision=(*BRILLO, 2.4))
    C.lamina_criatura(esc, arm, ob, RAIZ, os.path.join(LAMINAS, NOMBRE + "_lamina.png"),
                      "Gorthor el Devorador (V12, fase C)", sep=2.8, giros=(0, -40, -90), alto_cam=1.6, orto=14.0)
    for o in list(esc.objects):
        if o.type == 'CAMERA':
            bpy.data.objects.remove(o)
    for o in esc.objects:
        if o.name.startswith("kael") or (o.parent and o.parent.name.startswith("kael")):
            o.hide_render = True
    arm.location = (0, 0, 0)
    arm.rotation_euler = (0, 0, 0)
    esc.render.resolution_x, esc.render.resolution_y = 800, 900
    inst = [("reposo", 0.0), ("entrada", 1.4), ("ataque", 0.4), ("ataque", 0.75), ("carga_espera", 0.35),
            ("golpe_fuerte", 0.68), ("golpe_fuerte", 0.95), ("devorar", 0.6), ("devorar", 0.9), ("fase2", 1.3),
            ("recibir_golpe", 0.12), ("rendirse", 1.5), ("arrastrarse", 0.3), ("victoria", 0.8), ("derrota", 2.2),
            ("derrota_rendido", 1.6)]
    carpeta = os.path.join(LAMINAS, "poses")
    os.makedirs(carpeta, exist_ok=True)
    rutas = E.poses_render(esc, arm, inst, carpeta, NOMBRE, objetivo=(0, -0.5, 1.5), azimut=-40, elev=12, orto=5.6)
    E.componer(rutas, os.path.join(LAMINAS, NOMBRE + "_poses.png"), 8)
    # la boca de cerca: cerrada en reposo, abierta al rugir, en el mordisco y cerrada al morder
    esc.render.resolution_x, esc.render.resolution_y = 700, 700
    rutas = E.poses_render(esc, arm, [("reposo", 0.0), ("entrada", 1.9), ("devorar", 0.6), ("devorar", 0.9)],
                           carpeta, NOMBRE + "_boca", objetivo=(0, -0.7, 2.4), azimut=-30, elev=6, orto=1.6)
    E.componer(rutas, os.path.join(LAMINAS, NOMBRE + "_boca.png"), 4)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(LAMINAS, NOMBRE + ".blend"))
print("hecho")
