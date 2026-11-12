# Guardián de piedra, «el Centinela del Anillo» (V12, fase C, 12/11/2026, especialista de animaciones).
# Sustituye en el combate a la imagen 2D enemigos/guardian.png (que se conserva de respaldo). Personalidad «jefe»:
# golpe devastador avisado un turno antes. Sale al azar (GRUPOS[4], con un Grimfang).
#
#   blender -b --factory-startup -P crear_guardian_piedra.py -- <raíz aethelgard> <carpeta de láminas> [sin_laminas]
#
# Escribe enemigos/guardian_piedra/guardian_piedra.glb (sin imágenes dentro), guardian_piedra.webp (1024, alto),
# guardian_piedra_bajo.webp (512, bajo) y guardian_piedra_clips.json; en la carpeta de láminas, la lámina de concepto,
# la hoja de poses, el atlas y el .blend (fuera de Git, D-075). Misma semilla, mismo resultado.
#
# Concepto (lo que lo distingue): una ESTATUA de templo que despierta, no un montón de rocas. Caliza clara y tallada
# (relieves de greca en hombreras, peto y faldón), yelmo cerrado con cresta y una rendija en T que brilla verde agua,
# musgo en los hombros y los pies, y un ANILLO de piedra que flota detrás de la cabeza y gira (su seña en la silueta).
# Empuña un mandoble de granito con una runa que se enciende al cargar. Erguido y simétrico, de 2,55 m: frente al
# Coloso de la Falla (gris violáceo, encorvado, runas ámbar), el Gólem de ámbar (ancho, translúcido) y Gorthor.
# Su luz es verde agua (la del anillo y la rendija); nada de ámbar.
#
# Ejes (Blender): mira a -Y, Z arriba, su izquierda es +X. En Godot mira a +Z.
# Esqueleto (24 huesos): raiz, cadera, columna, pecho, cuello, cabeza, aureola (el anillo; gira sobre su eje),
# hombro/brazo/antebrazo/mano y muslo/pierna/pie (.L y .R), arma (el mandoble, hijo de mano.R), escombros (las lascas
# del golpe fuerte, escondidas a escala 0,01) y luz (sin malla: su escala X es el brillo de la rendija, la runa y el
# anillo en cada fotograma; lo lee guardian_piedra_3d.gd).
# Superficies: «guardian_piedra_atlas» (atlas + oclusión en el color de vértice) y «guardian_piedra_brillo».
import bpy, sys, os, math, json, random
from mathutils import Vector, Euler, Quaternion, Matrix

AQUI = os.path.dirname(os.path.abspath(__file__))
argv = sys.argv[sys.argv.index("--") + 1:]
RAIZ, LAMINAS = argv[0], argv[1]
CON_LAMINAS = "sin_laminas" not in argv
sys.path.insert(0, os.path.join(RAIZ, "personajes", "desierto", "fuentes_blender"))
sys.path.insert(0, os.path.join(RAIZ, "enemigos", "v12_comun", "fuente"))
import desierto_comun as C
import enemigos_v12_blender as E
import numpy as np

SALIDA = os.path.join(RAIZ, "enemigos", "guardian_piedra")
NOMBRE = "guardian_piedra"
os.makedirs(LAMINAS, exist_ok=True)
random.seed(11)
esc = C.escena_vacia()
col = esc.collection

# ================================================================== atlas (caliza, greca, pizarra, musgo, granito)

A = E.AtlasV12(1024, 4, semilla=11)
CALIZA = (0.80, 0.77, 0.69)


def pinta_caliza(h, rng, base=CALIZA, vetas=0.0):
    f = E.fbm(h, rng, 3, 5)
    img = E.color(base) * (0.84 + 0.30 * f[..., None])
    n2 = E.fbm(h, rng, 2, 3)
    img = E.mezclar(img, (0.70, 0.72, 0.74), np.clip((n2 - 0.55) * 3, 0, 0.5))      # manchas frías
    img = E.mezclar(img, (0.86, 0.80, 0.66), np.clip((0.42 - n2) * 3, 0, 0.4))      # y cálidas
    poros = rng.random((h, h)) < 0.012
    img[poros] *= 0.72
    if vetas:
        col_v = E.ruido(h, 40, rng)[0][None, :] * np.ones((h, 1))                      # churretes de lluvia
        caida = E.fbm(h, rng, 6, 2)
        img = E.mezclar(img, (0.52, 0.50, 0.46), np.clip((col_v - 0.62) * 4 * caida, 0, vetas))
    return img * (1 + rng.normal(0, 0.02, (h, h, 1)))


def pinta_vieja(h, rng):
    img = pinta_caliza(h, rng, (0.74, 0.72, 0.65), vetas=0.55)
    f1, _ = E.celdas_voronoi(h, rng, 26)
    liq = E.fbm(h, rng, 5, 3)
    img = E.mezclar(img, (0.80, 0.68, 0.34), np.clip((0.045 - f1) * 40, 0, 1) * (liq > 0.45))   # liquen ocre
    img = E.mezclar(img, (0.62, 0.70, 0.52), np.clip((0.035 - f1) * 40, 0, 1) * (liq <= 0.45))  # y verde pálido
    return img


def pinta_greca(h, rng):
    img = pinta_caliza(h, rng, (0.78, 0.75, 0.67))
    yy, xx = np.mgrid[0:h, 0:h]
    X, Y = (xx + 0.5) / h, (yy + 0.5) / h
    d = np.maximum(np.abs(X - 0.5), np.abs(Y - 0.5))
    surco = np.zeros((h, h))
    for r in (0.12, 0.24, 0.36, 0.46):
        surco = np.maximum(surco, np.clip(1 - np.abs(d - r) / 0.012, 0, 1))
    # dientes de greca entre el segundo y el tercer marco
    paso = 0.08
    dientes = (np.abs(((X + Y) / paso) % 1 - 0.5) < 0.12) & (d > 0.25) & (d < 0.35)
    surco = np.maximum(surco, dientes * 0.9)
    luz = np.roll(surco, -3, axis=0)                                                   # filo claro bajo el surco
    img = E.mezclar(img, (0.92, 0.90, 0.84), luz * 0.5)
    img = E.mezclar(img, (0.42, 0.40, 0.37), surco * 0.85)
    return img


def pinta_pizarra(h, rng):
    f = E.fbm(h, rng, 4, 5)
    img = E.color((0.40, 0.42, 0.47)) * (0.78 + 0.38 * f[..., None])
    g = E.grietas(h, rng, 30, 0.008)
    return E.mezclar(img, (0.22, 0.23, 0.27), g * 0.8)


def pinta_musgo(h, rng):
    f = E.fbm(h, rng, 6, 5)
    img = E.mezclar(E.color((0.27, 0.40, 0.15)) * np.ones((h, h, 1)), (0.47, 0.60, 0.22), np.clip((f - 0.45) * 3, 0, 1))
    img = E.mezclar(img, (0.16, 0.26, 0.10), np.clip((0.40 - f) * 4, 0, 1))
    motas = rng.random((h, h)) < 0.03
    img[motas] = img[motas] * 1.35
    return img


def pinta_granito(h, rng):
    f = E.fbm(h, rng, 5, 4)
    img = E.color((0.50, 0.53, 0.58)) * (0.82 + 0.3 * f[..., None])
    r = rng.random((h, h))
    img[r < 0.05] *= 0.45
    img[r > 0.975] = img[r > 0.975] * 0.4 + 0.55
    return img


for nombre, f in (("caliza", pinta_caliza), ("vieja", pinta_vieja), ("greca", pinta_greca),
                  ("pizarra", pinta_pizarra), ("musgo", pinta_musgo), ("granito", pinta_granito)):
    A.celda(nombre, f)

BRILLO = (0.30, 0.95, 0.85)          # verde agua (en Godot: guardian_piedra_3d.gd, COLOR_BRILLO)

# ================================================================== esqueleto

HUESOS = [
    ("raiz", (0, 0, 0), (0, 0, 0.25), None),
    ("cadera", (0, 0, 1.02), (0, 0, 1.18), "raiz"),
    ("columna", (0, 0, 1.18), (0, 0, 1.42), "cadera"),
    ("pecho", (0, 0, 1.42), (0, 0, 1.84), "columna"),
    ("cuello", (0, 0, 1.84), (0, 0, 1.97), "pecho"),
    ("cabeza", (0, 0, 1.97), (0, 0, 2.30), "cuello"),
    ("aureola", (0, 0.32, 2.12), (0, 0.46, 2.12), "pecho"),
    ("escombros", (0, -1.62, 0.0), (0, -1.62, 0.2), "raiz"),
    ("luz", (0, 0.1, 0.0), (0, 0.1, 0.15), "raiz"),
]
for s, l in ((".L", 1), (".R", -1)):
    HUESOS += [
        ("hombro" + s, (0.12 * l, 0, 1.76), (0.44 * l, 0, 1.76), "pecho"),
        ("brazo" + s, (0.46 * l, 0, 1.74), (0.54 * l, 0.02, 1.32), "hombro" + s),
        ("antebrazo" + s, (0.54 * l, 0.02, 1.32), (0.60 * l, -0.02, 0.92), "brazo" + s),
        ("mano" + s, (0.60 * l, -0.02, 0.92), (0.61 * l, -0.04, 0.76), "antebrazo" + s),
        ("muslo" + s, (0.20 * l, 0, 1.02), (0.24 * l, -0.02, 0.60), "cadera"),
        ("pierna" + s, (0.24 * l, -0.02, 0.60), (0.26 * l, 0.02, 0.14), "muslo" + s),
        ("pie" + s, (0.26 * l, 0.02, 0.14), (0.26 * l, -0.26, 0.06), "pierna" + s),
    ]
EMPUNADURA = Vector((-0.605, -0.03, 0.84))
HUESOS.append(("arma", tuple(EMPUNADURA), tuple(EMPUNADURA + Vector((0, -0.5, 0))), "mano.R"))
HOJA = 1.45                           # de la empuñadura a la punta (eje Y del hueso «arma»)

arm = C.crear_armadura(NOMBRE, HUESOS, col)

# ================================================================== malla

m = C.Malla(None, ("atlas", "brillo"))
CR = E.caja_redonda


def piedra(vs, celda="caliza", hueso=None, escala=0.9, liso=True):
    return E.proyectar(m, A, vs, celda, escala, hueso, 0, liso)


def brillo(vs, hueso):
    for f in {f for v in vs for f in v.link_faces}:
        f.material_index = 1
        f.smooth = False
        for lp in f.loops:
            lp[m.uv].uv = (0.5, 0.5)
    m.pesar(vs, hueso)
    return vs


def giro(ax=0, ay=0, az=0):
    return Euler((math.radians(ax), math.radians(ay), math.radians(az)), 'XYZ')


for s, l in ((".L", 1), (".R", -1)):
    # pies (escarpes con puntera) y espinilleras
    piedra(CR(m, (0.26 * l, -0.07, 0.09), (0.27, 0.46, 0.19), redondez=0.45, ruido_amp=0.03, semilla=1 + l),
           "vieja", "pie" + s)
    piedra(CR(m, (0.26 * l, -0.27, 0.07), (0.22, 0.14, 0.13), redondez=0.6, cortes=1), "pizarra", "pie" + s)
    piedra(CR(m, (0.255 * l, 0.0, 0.38), (0.25, 0.27, 0.50), redondez=0.6, cortes=3, ruido_amp=0.02, semilla=3 + l,
              afinar=lambda z: 0.86 + 0.28 * (z + 0.5)), "caliza", "pierna" + s)
    piedra(CR(m, (0.25 * l, -0.12, 0.62), (0.22, 0.13, 0.20), redondez=0.55), "greca", "pierna" + s)
    piedra(CR(m, (0.225 * l, 0.0, 0.83), (0.28, 0.29, 0.42), redondez=0.6, cortes=3, ruido_amp=0.02, semilla=5 + l),
           "caliza", "muslo" + s)
    # faldón: paneles laterales y delanteros (con la pierna), con greca
    piedra(CR(m, (0.35 * l, 0.02, 0.88), (0.07, 0.32, 0.42), giro(0, -10 * l, 0), redondez=0.3, cortes=1),
           "greca", "muslo" + s)
    piedra(CR(m, (0.25 * l, -0.19, 0.87), (0.20, 0.07, 0.42), giro(-8, 0, 25 * l), redondez=0.3, cortes=1),
           "greca", "muslo" + s)
    # hombreras dobles (con relieve) y su musgo
    piedra(CR(m, (0.47 * l, 0.0, 1.87), (0.40, 0.46, 0.17), giro(0, -20 * l, 0), redondez=0.55, cortes=3,
              ruido_amp=0.015, semilla=7 + l), "greca", "hombro" + s, 0.7)
    piedra(CR(m, (0.55 * l, 0.0, 1.75), (0.30, 0.40, 0.13), giro(0, -35 * l, 0), redondez=0.5), "vieja",
           "hombro" + s)
    piedra(E.roca(m, (0.44 * l, 0.06, 1.96), 0.13, 3 + l, 1, 0.3, (1.3, 1.5, 0.45)), "musgo", "hombro" + s, 0.6)
    # brazos: brazo, codera, brazal y puño
    piedra(CR(m, (0.50 * l, 0.01, 1.53), (0.19, 0.21, 0.42), redondez=0.65, cortes=3), "caliza", "brazo" + s)
    piedra(CR(m, (0.55 * l, 0.06, 1.32), (0.17, 0.15, 0.15), redondez=0.6, cortes=1), "pizarra", "antebrazo" + s)
    piedra(CR(m, (0.575 * l, 0.0, 1.11), (0.22, 0.24, 0.36), redondez=0.6, cortes=3, ruido_amp=0.015, semilla=9 + l,
              afinar=lambda z: 0.85 + 0.3 * (z + 0.5)), "greca", "antebrazo" + s, 0.6)
    piedra(CR(m, (0.605 * l, -0.03, 0.84), (0.16, 0.19, 0.18), redondez=0.6), "caliza", "mano" + s)
    # musgo en los pies
    piedra(E.roca(m, (0.30 * l, 0.12, 0.17), 0.09, 5 + l, 1, 0.3, (1.4, 1.2, 0.5)), "musgo", "pie" + s, 0.6)

# cadera, cinturón, faldón delantero y trasero
piedra(CR(m, (0, 0, 1.03), (0.50, 0.34, 0.28), redondez=0.5), "pizarra", "cadera")
piedra(CR(m, (0, 0, 1.13), (0.58, 0.40, 0.10), redondez=0.6), "pizarra", "cadera")
piedra(CR(m, (0, -0.21, 0.86), (0.30, 0.07, 0.46), giro(-6, 0, 0), redondez=0.3, cortes=1), "greca", "cadera")
piedra(CR(m, (0, 0.21, 0.88), (0.42, 0.07, 0.42), giro(8, 0, 0), redondez=0.3, cortes=1), "greca", "cadera")
# tronco: abdomen, pecho en V, peto, gorjal
piedra(CR(m, (0, 0, 1.28), (0.44, 0.31, 0.28), redondez=0.5), "caliza", "columna")
piedra(CR(m, (0, 0.0, 1.62), (0.76, 0.46, 0.50), redondez=0.5, cortes=3, ruido_amp=0.015, semilla=13,
          afinar=lambda z: 0.72 + 0.4 * (z + 0.5)), "caliza", "pecho")
piedra(CR(m, (0, -0.205, 1.63), (0.48, 0.10, 0.36), giro(-6, 0, 0), redondez=0.45, cortes=2), "greca", "pecho", 0.6)
piedra(CR(m, (0, 0.0, 1.87), (0.38, 0.32, 0.10), redondez=0.6), "pizarra", "pecho")
# yelmo cerrado: casco, cresta, carrilleras y rendija en T que brilla
piedra(CR(m, (0, -0.02, 2.12), (0.33, 0.37, 0.38), redondez=0.6, cortes=3), "caliza", "cabeza", 0.6)
piedra(CR(m, (0, 0.03, 2.33), (0.07, 0.46, 0.22), giro(-12, 0, 0), redondez=0.4), "greca", "cabeza", 0.6)
piedra(CR(m, (0, 0.24, 2.17), (0.06, 0.12, 0.30), giro(25, 0, 0), redondez=0.4, cortes=1), "greca", "cabeza", 0.6)
for l in (1, -1):
    piedra(CR(m, (0.145 * l, -0.11, 2.03), (0.07, 0.17, 0.19), redondez=0.4, cortes=1), "vieja", "cabeza")
piedra(E.roca(m, (0.05, 0.05, 2.30), 0.08, 9, 1, 0.3, (1.2, 1.4, 0.4)), "musgo", "cabeza", 0.6)
brillo(m.caja((0, -0.196, 2.13), (0.23, 0.02, 0.035)), "cabeza")
brillo(m.caja((0, -0.196, 2.065), (0.035, 0.02, 0.10)), "cabeza")
# grietas que brillan en el peto: quebradas, con una rama (la magia que lo mueve se ve por dentro)
rnd_g = random.Random(13)
for (x0, z0), a0 in (((-0.17, 1.80), -75), ((0.16, 1.47), 70)):
    for camino in E.camino_grieta(rnd_g, (x0, z0), a0, pasos=5, paso=0.05, quiebro=40, ramas=1):
        pts = [Vector((x, -0.262 - (z - 1.63) * 0.105, z)) for x, z in camino]
        brillo(m.tubo(pts, [0.010] + [0.008] * (len(pts) - 2) + [0.003], 4), "pecho")

# el anillo (aureola): 10 sillares de piedra en un círculo del plano XZ, con 5 gemas que brillan
CENTRO_AUR = Vector((0, 0.32, 2.12))
for k in range(10):
    a = 2 * math.pi * k / 10
    p = CENTRO_AUR + Vector((math.cos(a) * 0.46, 0, math.sin(a) * 0.46))
    piedra(CR(m, p, (0.22, 0.07, 0.10), giro(0, -math.degrees(a) - 90, 0), redondez=0.4, cortes=1), "vieja",
           "aureola", 0.6)
    if k % 2 == 0:
        pg = CENTRO_AUR + Vector((math.cos(a + 0.31) * 0.46, -0.04, math.sin(a + 0.31) * 0.46))
        brillo(E.roca(m, pg, 0.04, k, 0, 0.1), "aureola")

# el mandoble (hijo de mano.R; en reposo, horizontal hacia delante: la hoja a lo largo de -Y, el filo en Z)
E0 = EMPUNADURA
piedra(m.esfera(E0 + Vector((0, 0.23, 0)), (0.06, 0.06, 0.06), (8, 6)), "granito", "arma", 0.4)
piedra(m.tubo([E0 + Vector((0, 0.19, 0)), E0 + Vector((0, -0.10, 0))], [0.036, 0.034], 8), "pizarra", "arma", 0.4)
piedra(CR(m, E0 + Vector((0, -0.13, 0)), (0.10, 0.08, 0.46), redondez=0.45), "greca", "arma", 0.5)
hoja_pts = [E0 + Vector((0, -0.16 - t * (HOJA - 0.16), 0)) for t in (0, 0.25, 0.5, 0.75, 0.92, 1.0)]
hoja_r = [(0.11, 0.032), (0.105, 0.03), (0.10, 0.028), (0.09, 0.025), (0.06, 0.02), (0.005, 0.004)]
piedra(m.tubo(hoja_pts, hoja_r, 4, ref=Vector((0, 0, 1))), "granito", "arma", 0.5, liso=False)
for l in (1, -1):
    brillo(m.caja(E0 + Vector((0.029 * l, -0.72, 0)), (0.006, 0.95, 0.022)), "arma")

# lascas del golpe fuerte (alrededor del hueso «escombros», escondidas a escala 0,01)
ESC0 = Vector((0, -1.62, 0))
for k in range(7):
    a = 2 * math.pi * k / 7 + 0.3
    r = 0.28 + 0.12 * (k % 2)
    p = ESC0 + Vector((math.cos(a) * r, math.sin(a) * r, 0.12))
    piedra(E.roca(m, p, 0.11, 20 + k, 0, 0.35, (0.8, 0.8, 2.0),
                  Euler((math.cos(a) * 0.5, -math.sin(a) * 0.5, a))), "vieja", "escombros", 0.5, liso=False)

ob = m.objeto(NOMBRE, col)
E.materiales(ob, [NOMBRE + "_atlas", NOMBRE + "_brillo"])
C.enlazar(ob, arm)
TRIS = C.triangulos(ob)
E.oclusion(ob, rayos=24, dist=0.5, minimo=0.42)
print("triángulos:", TRIS)

# ================================================================== poses y clips

rig = E.Rig(arm)
rig.poner_arma("arma", atras=0.16)
rig.defecto = {"escombros@esc": (0.01, 0.01, 0.01), "escombros@loc": (0, 0, -0.3)}
L, R, sim = E.L, E.R, E.sim


def P(*ds, **kw):
    out = {}
    for d in ds:
        out.update(d)
    for k, v in kw.items():
        out[k.replace("__", ".").replace("_AT_", "@")] = v
    return out


def luz(v):
    return {"luz@esc": (v, v, v)}


# estatua: las dos manos en el pomo, la punta clavada delante
REPOSO = P({"arma@pos": (0.0, -0.42, 1.18), "arma@dir": (90, 0, 0), "arma@roll": 180, "mano.L@agarre": 1.0,
            "codo.L@polo": (0.7, 0.3, -0.7), "codo.R@polo": (-0.7, 0.3, -0.7),
            "cabeza": (8, 0, 0), "pecho": (3, 0, 0)}, luz(1.0))
VIGILA_I = P(REPOSO, {"cabeza": (6, 0, 9), "pecho": (2, 0, 3)})
VIGILA_D = P(REPOSO, {"cabeza": (10, 0, -7), "pecho": (4, 0, -2), "cadera@loc": (0, 0, -0.012)})
# en guardia, con el mandoble en la derecha, hacia delante y abajo (para andar y correr)
GUARDIA = P({"arma@pos": (-0.40, -0.36, 1.00), "arma@dir": (32, 0, -8), "mano.L@agarre": 0.0,
             "brazo.L": (-12, -8, 0), "antebrazo.L": (-20, 0, 0), "cabeza": (4, 0, 0), "pecho": (6, 0, 0)}, luz(1.0))
# en alto: el mandoble sobre la cabeza con las dos manos (la carga)
ALTO = P({"arma@pos": (-0.02, -0.16, 2.44), "arma@dir": (-98, 0, 0), "mano.L@agarre": 1.0,
          "codo.L@polo": (0.8, -0.2, 0.3), "codo.R@polo": (-0.8, -0.2, 0.3),
          "pecho": (-9, 0, 0), "columna": (-3, 0, 0), "cabeza": (-12, 0, 0)}, luz(2.4))
ALTO2 = P(ALTO, {"arma@pos": (-0.02, 0.02, 2.40), "arma@dir": (-128, 0, 0), "pecho": (-17, 0, 0),
                 "columna": (-6, 0, 0), "cabeza": (-16, 0, 0), "raiz@loc": (0, 0.04, 0.03)}, luz(3.4))
# golpe fuerte: el mandoble contra el suelo delante, a fondo, con el pie derecho adelantado
FONDO = P({"arma@pos": (0.0, -0.66, 0.95), "arma@dir": (31, 0, 0), "mano.L@agarre": 1.0,
           "codo.L@polo": (0.8, 0.4, -0.2), "codo.R@polo": (-0.8, 0.4, -0.2),
           "raiz@loc": (0, -0.30, -0.20), "pecho": (30, 0, 0), "columna": (14, 0, 0), "cabeza": (-14, 0, 0),
           "pie.R@ik": (-0.30, -0.42, 0.14), "pie.L@ik": (0.28, 0.22, 0.14), "pie.L@rot": (-18, 0, 0)}, luz(4.2))


def hacia(v, roll=0.0):
    """Giro (grados XYZ) que lleva la hoja (reposo: hacia -Y) a la dirección v."""
    q = Vector((0, -1, 0)).rotation_difference(Vector(v).normalized())
    if roll:
        q = Quaternion(Vector(v).normalized(), math.radians(roll)) @ q
    return tuple(math.degrees(a) for a in q.to_euler('XYZ'))


VEL_ANILLO = {"reposo": 12.0, "caminar": 30.0, "correr": 45.0, "carga_espera": 45.0, "carga": 40.0,
              "ataque": 20.0, "golpe_fuerte": 30.0, "recibir_golpe": 10.0, "victoria": 20.0}


def anillo(arm_, pose, seg):
    """El anillo gira sobre su eje (los bucles cierran: 36° es su simetría de 10 sillares)."""
    clip = rig.clip_actual
    if clip == "entrada":
        ang = 0.0 if seg < 0.6 else 18.0 * (seg - 0.6) ** 1.6
    elif clip == "derrota":
        ang = 14.0 * seg - 3.0 * seg * seg
    else:
        ang = VEL_ANILLO.get(clip, 12.0) * seg
    pb = arm_.pose.bones["aureola"]
    pb.rotation_quaternion = pb.rotation_quaternion @ Quaternion(Vector((0, 1, 0)), math.radians(ang))


rig.extra = anillo
CLIPS = {}


def clip(nombre, claves, bucle=False, proc=None, eventos=None):
    act, dur = rig.clip(nombre, claves, bucle, proc=proc)
    CLIPS[nombre] = {"duracion": round(dur, 4), "bucle": bucle, "eventos": eventos or {}}


# reposo (3 s, bucle): respira la piedra, vigila a un lado y al otro; el anillo gira despacio
clip("reposo", [(0, REPOSO), (0.9, VIGILA_I), (1.6, P(REPOSO, {"pecho": (1, 0, 0)})), (2.3, VIGILA_D), (3.0, REPOSO)],
     bucle=True)


def pasos(dur, paso, alto, bote, ancho=0.26, inclina=0.0):
    """Ciclo de pasos en el sitio: el pie apoyado retrocede a velocidad constante, el otro vuelve por el aire."""
    def f(seg):
        out = {}
        for s, desfase, l in ((".L", 0.0, 1), (".R", 0.5, -1)):
            fa = (seg / dur + desfase) % 1.0
            if fa < 0.5:
                y = -paso / 2 + paso * (fa / 0.5)
                z = 0.14
                rx = 0.0
            else:
                t = (fa - 0.5) / 0.5
                y = paso / 2 - paso * (0.5 - 0.5 * math.cos(math.pi * t))
                z = 0.14 + alto * math.sin(math.pi * t)
                rx = -25 * math.sin(math.pi * t)
            out["pie" + s + "@ik"] = (ancho * l, y + 0.02, z)
            out["pie" + s + "@rot"] = (rx, 0, 0)
        fase = 2 * math.pi * seg / dur
        out["raiz@loc"] = (0, 0, -bote * (0.5 + 0.5 * math.cos(2 * fase)))
        out["cadera"] = (0, 0, 5 * math.sin(fase))
        out["pecho"] = (6 + inclina, 0, -6 * math.sin(fase))
        out["brazo.L"] = (-12 - 14 * math.sin(fase), -8, 0)
        return out
    return f


clip("caminar", [(0, GUARDIA), (1.2, GUARDIA)], bucle=True, proc=pasos(1.2, 0.55, 0.16, 0.035))
clip("correr", [(0, P(GUARDIA, {"arma@pos": (-0.42, -0.30, 1.06), "arma@dir": (40, 0, -6)})),
                (0.8, P(GUARDIA, {"arma@pos": (-0.42, -0.30, 1.06), "arma@dir": (40, 0, -6)}))],
     bucle=True, proc=pasos(0.8, 0.85, 0.24, 0.07, inclina=8))

# entrada (2,2 s): la estatua dormida (cabeza baja, sin luz) despierta: se encienden la rendija y el anillo, alza la
# cabeza, sacude los hombros, levanta el mandoble y lo vuelve a clavar (golpe al suelo a 1,75 s)
DORMIDA = P(REPOSO, {"cabeza": (26, 0, 0), "pecho": (8, 0, 0), "cadera@loc": (0, 0, -0.02)}, luz(0.0))
clip("entrada", [(0, DORMIDA), (0.45, DORMIDA), (0.7, P(DORMIDA, luz(2.2))),
                 (1.1, P(REPOSO, {"cabeza": (-8, 0, 0), "pecho": (-6, 0, 0)}, luz(1.6))),
                 (1.35, P(REPOSO, {"arma@pos": (0.0, -0.42, 1.42), "cabeza": (-4, 0, 0), "pecho": (-4, 0, 0),
                                   "hombro.L": (0, 0, 8), "hombro.R": (0, 0, -8)}, luz(1.4))),
                 (1.75, P(REPOSO, {"arma@pos": (0.0, -0.42, 1.14)}, luz(1.8)), "acel"),
                 (2.2, REPOSO)], eventos={"despierta": 0.6, "golpe_suelo": 1.75})

# ataque (1,5 s; atacar_hacha): alza el mandoble sobre el hombro derecho, adelanta el pie izquierdo y tajo en diagonal
# hacia su izquierda: IMPACTO a 0,8 s; vuelve al reposo
SOBRE_HOMBRO = P({"arma@pos": (-0.42, 0.02, 1.98), "arma@dir": hacia((0.15, 0.55, 0.82)), "mano.L@agarre": 1.0,
                  "pecho": (-4, 0, -24), "cadera": (0, 0, -10), "columna": (0, 0, -6), "cabeza": (0, 0, 14)}, luz(1.5))
TAJO = P({"arma@pos": (0.16, -0.62, 1.00), "arma@dir": hacia((0.45, -0.78, -0.42)), "mano.L@agarre": 1.0,
          "codo.R@polo": (-0.6, 0.6, 0.2), "pecho": (16, 0, 22), "cadera": (0, 0, 8), "columna": (6, 0, 6),
          "cabeza": (-6, 0, -10), "raiz@loc": (0, -0.22, -0.08),
          "pie.L@ik": (0.30, -0.34, 0.14)}, luz(1.8))
TAJO2 = P(TAJO, {"arma@pos": (0.24, -0.58, 0.88), "arma@dir": hacia((0.62, -0.62, -0.48)), "pecho": (19, 0, 28)})
clip("ataque", [(0, REPOSO), (0.3, P(SOBRE_HOMBRO, {"arma@pos": (-0.30, -0.20, 1.62), "arma@dir": hacia((0, -0.3, 0.95))})),
                (0.5, SOBRE_HOMBRO), (0.58, P(SOBRE_HOMBRO, {"pie.L@ik": (0.29, -0.15, 0.24)})),
                (0.8, TAJO, "acel"), (0.98, TAJO2, "fren"), (1.2, P(TAJO2, {"pie.L@ik": (0.28, -0.15, 0.22)})),
                (1.5, REPOSO)], eventos={"impacto": 0.8})

# carga (1 s) y su espera (1,6 s, bucle): el mandoble en alto con las dos manos; tiembla y la runa late
clip("carga", [(0, REPOSO), (0.45, P(REPOSO, {"arma@pos": (0.0, -0.40, 1.80), "arma@dir": (40, 0, 0)}, luz(1.6))),
               (1.0, ALTO)], eventos={"en_alto": 1.0})
clip("carga_espera", [(0, ALTO), (0.4, P(ALTO, {"pecho": (-11, 0, 1), "arma@pos": (-0.02, -0.15, 2.47)}, luz(3.1))),
                      (0.8, P(ALTO, luz(2.2))), (1.2, P(ALTO, {"pecho": (-10, 0, -1), "arma@pos": (-0.03, -0.16, 2.46)},
                                                       luz(3.1))), (1.6, ALTO)], bucle=True)

# golpe fuerte (1,9 s): si no estaba cargando, lo alza (0-0,5 s; desde la carga empieza en 0,5); se arquea hacia atrás
# y lo descarga contra el suelo con todo el cuerpo: IMPACTO a 0,92 s, las lascas brotan delante; recupera
ESC_OFF = {"escombros@esc": (0.01, 0.01, 0.01), "escombros@loc": (0, 0, -0.3)}
ESC_ON = {"escombros@esc": (1, 1, 1), "escombros@loc": (0, 0, 0)}
clip("golpe_fuerte", [(0, P(REPOSO, ESC_OFF)), (0.5, P(ALTO, ESC_OFF)),
                      (0.66, P(ALTO2, {"pie.R@ik": (-0.28, -0.12, 0.26)}, ESC_OFF)),
                      (0.919, P(FONDO, ESC_OFF), "acel"), (0.92, P(FONDO, ESC_ON), "corte"),
                      (1.2, P(FONDO, {"pecho": (27, 0, 0)}, ESC_ON, luz(2.0))),
                      (1.45, P(FONDO, {"pecho": (20, 0, 0), "arma@pos": (0.0, -0.62, 0.95)}, luz(1.4),
                               {"escombros@esc": (1, 1, 1), "escombros@loc": (0, 0, -0.05)})),
                      (1.6, P(REPOSO, {"pie.R@ik": (-0.28, -0.2, 0.24)}, {"escombros@esc": (0.6, 0.6, 0.6),
                                                                         "escombros@loc": (0, 0, -0.22)})),
                      (1.9, P(REPOSO, ESC_OFF))], eventos={"impacto": 0.92, "carga": 0.5})

# recibir golpe (0,7 s): retrocede la cabeza y el pecho, el mandoble se tambalea, la luz parpadea
GOLPEADO = P(REPOSO, {"pecho": (-11, 0, 6), "cabeza": (-16, 0, 9), "columna": (-4, 0, 0), "raiz@loc": (0, 0.09, 0),
                      "arma@pos": (0.03, -0.36, 1.22), "arma@dir": (82, 4, 0)}, luz(0.4))
clip("recibir_golpe", [(0, REPOSO), (0.12, GOLPEADO, "fren"), (0.3, P(GOLPEADO, luz(1.3))), (0.7, REPOSO)],
     eventos={"golpe": 0.0})

# victoria (2 s): saca el mandoble, lo alza con la punta abajo y lo clava de nuevo (0,8 s); se yergue, la luz sube
clip("victoria", [(0, REPOSO), (0.45, P(REPOSO, {"arma@pos": (0.0, -0.44, 1.75), "pecho": (-4, 0, 0)})),
                  (0.8, P(REPOSO, {"arma@pos": (0.0, -0.42, 1.12)}, luz(2.6)), "acel"),
                  (1.3, P(REPOSO, {"cabeza": (-12, 0, 0), "pecho": (-5, 0, 0)}, luz(2.0))),
                  (2.0, P(REPOSO, {"cabeza": (-10, 0, 0), "pecho": (-4, 0, 0)}, luz(1.6)))],
     eventos={"clavar": 0.8})

# derrota (2,4 s): la luz se apaga a golpes, cae de rodilla (0,7 s) apoyado en el mandoble, la cabeza se rinde, el
# anillo se desploma, y se vuelca hacia delante (suelo a 2,2 s). El combate lo funde desde 0,9 s (ver informe).
RODILLA = P({"arma@pos": (0.02, -0.62, 1.00), "arma@dir": (70, 0, 0), "arma@roll": 180, "mano.L@agarre": 1.0,
             "raiz@loc": (0, 0.06, -0.42), "pecho": (12, 0, 0), "columna": (6, 0, 0), "cabeza": (20, 0, 0),
             "pie.R@ik": (-0.26, 0.50, 0.10), "pie.R@rot": (70, 0, 0), "pie.L@ik": (0.28, -0.30, 0.14),
             "aureola@loc": (0, 0, -0.25)}, luz(0.25))
clip("derrota", [(0, REPOSO), (0.25, P(GOLPEADO, luz(0.2))), (0.4, P(GOLPEADO, luz(1.0))),
                 (0.7, RODILLA, "acel"), (1.2, P(RODILLA, {"cabeza": (38, 0, 0), "pecho": (18, 0, 0),
                                                           "aureola@loc": (0, 0, -0.9)}, luz(0.05))),
                 (1.6, P(RODILLA, {"cabeza": (38, 0, 0), "pecho": (22, 0, 0), "aureola@loc": (0, 0.1, -1.6)},
                         luz(0.0))),
                 (2.2, P(RODILLA, {"raiz": (72, 0, 0), "raiz@loc": (0, 0.30, -0.10), "cabeza": (30, 0, 0),
                                   "pecho": (20, 0, 0), "mano.L@agarre": 0.0, "aureola@loc": (0, 0.1, -1.7)},
                         luz(0.0)), "acel"),
                 (2.4, P(RODILLA, {"raiz": (70, 0, 0), "raiz@loc": (0, 0.30, -0.12), "cabeza": (32, 0, 0),
                                   "pecho": (20, 0, 0), "mano.L@agarre": 0.0, "aureola@loc": (0, 0.1, -1.7)},
                         luz(0.0)))], eventos={"rodilla": 0.7, "suelo": 2.2})

# ================================================================== medidas, exportación y JSON

def medir():
    """Alcance de la punta (en el impacto, hacia delante, respecto al cuerpo en reposo) y altura de la cabeza."""
    datos = {}
    for c_, t in (("ataque", 0.8), ("golpe_fuerte", 0.92)):
        p = E.punto_hueso(arm, rig, c_, t, "arma", (0, HOJA, 0))
        datos[c_] = {"punta_godot": [round(p.x, 3), round(p.z, 3), round(-p.y, 3)]}
    p = E.punto_hueso(arm, rig, "reposo", 0.0, "cabeza", (0, 0.33, 0))
    datos["alto_reposo"] = round(p.z + 0.05, 3)
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
    "generador": "enemigos/guardian_piedra/fuente/crear_guardian_piedra.py (Blender 5.2.3)"})
print("clips:", {k: v["duracion"] for k, v in CLIPS.items()})
print("medidas:", medidas)

# ================================================================== láminas

if CON_LAMINAS:
    img = bpy.data.images.load(os.path.join(SALIDA, NOMBRE + ".webp"))
    E.material_vista(bpy.data.materials[NOMBRE + "_atlas"], img)
    E.material_vista(bpy.data.materials[NOMBRE + "_brillo"], None, emision=(*BRILLO, 2.2))
    cam, xs = C.lamina_criatura(esc, arm, ob, RAIZ, os.path.join(LAMINAS, NOMBRE + "_lamina.png"),
                                "Guardián de piedra — el Centinela del Anillo (V12, fase C)", sep=2.5,
                                giros=(0, -40, -90), alto_cam=1.4, orto=13.0)
    for o in list(esc.objects):
        if o.type == 'CAMERA':
            bpy.data.objects.remove(o)
    for o in esc.objects:
        if o.name.startswith("kael") or (o.parent and o.parent.name.startswith("kael")):
            o.hide_render = True
    arm.location = (0, 0, 0)
    arm.rotation_euler = (0, 0, 0)
    esc.render.resolution_x, esc.render.resolution_y = 800, 900
    inst = [("reposo", 0.0), ("entrada", 0.3), ("ataque", 0.5), ("ataque", 0.8), ("carga_espera", 0.4),
            ("golpe_fuerte", 0.66), ("golpe_fuerte", 0.92), ("golpe_fuerte", 1.2), ("recibir_golpe", 0.12),
            ("caminar", 0.3), ("correr", 0.2), ("victoria", 1.3), ("derrota", 0.7), ("derrota", 2.4)]
    carpeta = os.path.join(LAMINAS, "poses")
    os.makedirs(carpeta, exist_ok=True)
    rutas = E.poses_render(esc, arm, inst, carpeta, NOMBRE, objetivo=(0, -0.5, 1.4), azimut=-40, elev=12, orto=5.0)
    E.componer(rutas, os.path.join(LAMINAS, NOMBRE + "_poses.png"), 7)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(LAMINAS, NOMBRE + ".blend"))
print("hecho")
