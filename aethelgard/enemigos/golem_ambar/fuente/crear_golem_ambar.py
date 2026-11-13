# Gólem de ámbar, «el Guardián del Nido» (V12, fase C, 12/11/2026, especialista de animaciones).
# Sustituye en el combate a la imagen del Guardián de piedra que usaba (enemigos/guardian.png se conserva). Personalidad
# «bruto»: levanta los puños un turno y da un Pisotón a todo el grupo (se puede interrumpir: queda aturdido).
# El combate fijo «garganta_nido» (GRUPOS[6], con un Grimfang). Premio: la Lágrima de ámbar («dentro hay un insecto
# que nadie ha visto vivo»).
#
#   blender -b --factory-startup -P crear_golem_ambar.py -- <raíz aethelgard> <carpeta de láminas> [sin_laminas]
#
# Escribe enemigos/golem_ambar/golem_ambar.glb (sin imágenes), golem_ambar.webp (1024), golem_ambar_bajo.webp (512)
# y golem_ambar_clips.json; en la carpeta de láminas, la lámina, la hoja de poses, el atlas y el .blend.
#
# Concepto (lo que lo distingue): ancho y bajo como un huevo, hecho de terrones FACETADOS de ámbar (resina fósil,
# translúcida, aislante: encaja con la inmunidad al Rayo de la tabla de afinidades) con insectos atrapados dentro,
# atado con ramas petrificadas oscuras y con EL NIDO a la espalda (ramas trenzadas y tres huevos). Cabeza pequeña
# hundida bajo una ceja de ramas, ojos de miel encendidos; brazos largos con puños enormes que casi tocan el suelo y
# pies redondos de pisar. Nada de piedra gris ni de figura humana erguida (Guardián de piedra), ni de basalto (Coloso).
#
# Ejes (Blender): mira a -Y, Z arriba, su izquierda es +X. En Godot mira a +Z.
# Esqueleto (22 huesos): raiz, cadera, columna, pecho, cabeza, nido (el nido de la espalda; se mece aparte),
# hombro/brazo/antebrazo/mano y muslo/pierna/pie (.L y .R), onda (el anillo de polvo del Pisotón; escondido a escala
# 0,01) y luz (sin malla: su escala X es el brillo de los ojos y del corazón en cada fotograma).
# Superficies: «golem_ambar_atlas» (ramas, nido y huevos: mate), «golem_ambar_brillo» (ojos, corazón y la onda) y
# «golem_ambar_ambar» (el mismo atlas, brillante y con algo de luz propia: la resina).
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

SALIDA = os.path.join(RAIZ, "enemigos", "golem_ambar")
NOMBRE = "golem_ambar"
os.makedirs(LAMINAS, exist_ok=True)
random.seed(17)
esc = C.escena_vacia()
col = esc.collection

# ================================================================== atlas

A = E.AtlasV12(1024, 4, semilla=17)


def malla_xy(h):
    yy, xx = np.mgrid[0:h, 0:h]
    return (xx + 0.5) / h, (yy + 0.5) / h


def elipse(X, Y, cx, cy, rx, ry, giro=0.0):
    c, s = math.cos(giro), math.sin(giro)
    u = ((X - cx) * c + (Y - cy) * s) / rx
    v = (-(X - cx) * s + (Y - cy) * c) / ry
    return np.clip((1 - np.sqrt(u * u + v * v)) * 6, 0, 1)


def segmento(X, Y, a, b, g):
    (ax, ay), (bx, by) = a, b
    vx, vy = bx - ax, by - ay
    t = np.clip(((X - ax) * vx + (Y - ay) * vy) / (vx * vx + vy * vy + 1e-9), 0, 1)
    d = np.sqrt((X - ax - t * vx) ** 2 + (Y - ay - t * vy) ** 2)
    return np.clip((g - d) / g * 3, 0, 1)


def insecto(X, Y, cx, cy, tam, giro, alas):
    """Silueta de un insecto (cuerpo, cabeza, seis patas y, si «alas», dos alas): propia, sin referencia."""
    c, s = math.cos(giro), math.sin(giro)

    def P(u, v):
        return (cx + (u * c - v * s) * tam, cy + (u * s + v * c) * tam)
    m = elipse(X, Y, *P(0, 0), 0.30 * tam, 0.55 * tam, giro)
    m = np.maximum(m, elipse(X, Y, *P(0, 0.62), 0.18 * tam, 0.18 * tam))
    for k in (-1, 1):
        for j, (v0, v1) in enumerate(((0.25, 0.55), (0.0, 0.05), (-0.25, -0.55))):
            m = np.maximum(m, segmento(X, Y, P(0.25 * k, v0), P(0.75 * k, v1), 0.035 * tam))
        m = np.maximum(m, segmento(X, Y, P(0.08 * k, 0.75), P(0.35 * k, 1.05), 0.025 * tam))
    w = np.zeros_like(X)
    if alas:
        for k in (-1, 1):
            w = np.maximum(w, elipse(X, Y, *P(0.55 * k, 0.15), 0.55 * tam, 0.2 * tam, giro + 0.5 * k))
    return m, w


def pinta_ambar(h, rng, base=(0.93, 0.56, 0.13), insectos=4):
    X, Y = malla_xy(h)
    f = E.fbm(h, rng, 3, 5)
    f1, f2 = E.celdas_voronoi(h, rng, 14)
    img = E.color(base) * (0.75 + 0.45 * f[..., None])
    img = E.mezclar(img, (1.0, 0.86, 0.42), np.clip(0.55 - f1 * 3.0, 0, 0.75))          # el corazón claro de cada terrón
    img = E.mezclar(img, (0.55, 0.24, 0.04), np.clip((0.06 - (f2 - f1)) * 12, 0, 0.6))  # vetas entre terrones
    burb = rng.random((h, h)) < 0.004
    img[burb] = img[burb] * 0.6 + 0.4
    for k in range(insectos):
        m, w = insecto(X, Y, rng.uniform(0.15, 0.85), rng.uniform(0.15, 0.85), rng.uniform(0.05, 0.09),
                       rng.uniform(0, 6.28), k % 2 == 0)
        img = E.mezclar(img, (0.98, 0.80, 0.45), w * 0.45)
        img = E.mezclar(img, (0.24, 0.11, 0.03), m * 0.85)
    return img


def pinta_ambar_oscuro(h, rng):
    return pinta_ambar(h, rng, (0.70, 0.33, 0.07), 2)


def pinta_rama(h, rng):
    X, Y = malla_xy(h)
    fibra = E.ruido(h, 48, rng)[0][None, :] * np.ones((h, 1))
    f = E.fbm(h, rng, 4, 4)
    img = E.color((0.32, 0.26, 0.20)) * (0.7 + 0.5 * fibra[..., None] * (0.6 + 0.4 * f[..., None]))
    nudos = E.grietas(h, rng, 18, 0.006)
    img = E.mezclar(img, (0.16, 0.12, 0.09), nudos * 0.6)
    return E.mezclar(img, (0.46, 0.42, 0.36), np.clip((f - 0.62) * 4, 0, 0.5))           # partes petrificadas, grises


def pinta_nido(h, rng):
    X, Y = malla_xy(h)
    img = E.color((0.50, 0.40, 0.26)) * (0.8 + 0.3 * E.fbm(h, rng, 6, 3)[..., None])
    for k in range(60):
        a = rng.uniform(0, 6.28)
        cx, cy, l = rng.uniform(0, 1), rng.uniform(0, 1), rng.uniform(0.15, 0.4)
        p0 = (cx - math.cos(a) * l / 2, cy - math.sin(a) * l / 2)
        p1 = (cx + math.cos(a) * l / 2, cy + math.sin(a) * l / 2)
        tono = (0.66, 0.55, 0.36) if k % 3 else (0.30, 0.24, 0.16)
        img = E.mezclar(img, tono, segmento(X, Y, p0, p1, 0.006) * 0.8)
    return img


def pinta_huevo(h, rng):
    img = E.color((0.90, 0.86, 0.74)) * (0.92 + 0.12 * E.fbm(h, rng, 4, 3)[..., None])
    f1, _ = E.celdas_voronoi(h, rng, 60)
    return E.mezclar(img, (0.45, 0.30, 0.18), np.clip((0.018 - f1) * 60, 0, 1))


for nombre, f in (("ambar", pinta_ambar), ("ambar_oscuro", pinta_ambar_oscuro), ("rama", pinta_rama),
                  ("nido", pinta_nido), ("huevo", pinta_huevo)):
    A.celda(nombre, f)

BRILLO = (1.0, 0.72, 0.22)            # miel encendida (golem_ambar_3d.gd, COLOR_BRILLO)

# ================================================================== esqueleto

HUESOS = [
    ("raiz", (0, 0, 0), (0, 0, 0.25), None),
    ("cadera", (0, 0, 0.80), (0, 0, 1.00), "raiz"),
    ("columna", (0, 0, 1.00), (0, 0, 1.30), "cadera"),
    ("pecho", (0, 0, 1.30), (0, 0, 1.75), "columna"),
    ("cabeza", (0, -0.42, 1.80), (0, -0.48, 2.10), "pecho"),
    ("nido", (0, 0.40, 1.80), (0, 0.40, 2.10), "pecho"),
    ("onda", (0, -0.5, 0.02), (0, -0.5, 0.22), "raiz"),
    ("luz", (0, 0.1, 0.0), (0, 0.1, 0.15), "raiz"),
]
for s, l in ((".L", 1), (".R", -1)):
    HUESOS += [
        ("hombro" + s, (0.30 * l, 0, 1.62), (0.76 * l, 0, 1.62), "pecho"),
        ("brazo" + s, (0.80 * l, 0, 1.60), (0.98 * l, 0.05, 1.08), "hombro" + s),
        ("antebrazo" + s, (0.98 * l, 0.05, 1.08), (1.02 * l, -0.05, 0.62), "brazo" + s),
        ("mano" + s, (1.02 * l, -0.05, 0.62), (1.03 * l, -0.08, 0.38), "antebrazo" + s),
        ("muslo" + s, (0.32 * l, 0, 0.80), (0.36 * l, -0.03, 0.46), "cadera"),
        ("pierna" + s, (0.36 * l, -0.03, 0.46), (0.38 * l, 0.02, 0.17), "muslo" + s),
        ("pie" + s, (0.38 * l, 0.02, 0.17), (0.38 * l, -0.28, 0.08), "pierna" + s),
    ]
arm = C.crear_armadura(NOMBRE, HUESOS, col)

# ================================================================== malla

m = C.Malla(None, ("atlas", "brillo", "ambar"))


def ambar(vs, hueso, celda="ambar", escala=1.1):
    return E.proyectar(m, A, vs, celda, escala, hueso, 2, liso=False)


def mate(vs, hueso, celda, escala=0.8, liso=True):
    return E.proyectar(m, A, vs, celda, escala, hueso, 0, liso)


def brillo(vs, hueso):
    for f in {f for v in vs for f in v.link_faces}:
        f.material_index = 1
        f.smooth = False
        for lp in f.loops:
            lp[m.uv].uv = (0.5, 0.5)
    m.pesar(vs, hueso)
    return vs


def tronco(z):
    return C.por_altura(z.z, [(0.9, "cadera"), (1.15, "columna"), (1.45, "pecho")])


rnd = random.Random(17)
# el cuerpo: un terrón grande con forma de huevo y terrones pegados alrededor
ambar(E.roca(m, (0, 0.02, 1.30), 0.70, 1, 2, 0.12, (1.05, 0.88, 0.95)), tronco)
for k in range(11):
    a = 2 * math.pi * k / 11 + 0.2
    zc = 1.05 + 0.55 * ((k * 7) % 11) / 10.0
    r = 0.62 if 1.1 < zc < 1.5 else 0.52
    p = (math.cos(a) * r * 1.05, 0.02 + math.sin(a) * r * 0.88, zc)
    ambar(E.roca(m, p, rnd.uniform(0.20, 0.30), 30 + k, 1, 0.25), tronco, "ambar_oscuro" if k % 3 == 0 else "ambar")
# el corazón: facetas que brillan en el pecho (se ve la luz a través de la resina)
for k, (x, z) in enumerate(((0.0, 1.38), (0.16, 1.26), (-0.14, 1.22), (0.05, 1.12))):
    brillo(E.roca(m, (x, -0.66, z), 0.07 - 0.01 * k, 50 + k, 0, 0.2), "pecho")
# cadera
ambar(E.roca(m, (0, 0.0, 0.85), 0.42, 3, 1, 0.15, (1.3, 0.95, 0.6)), "cadera", "ambar_oscuro")
# cabeza hundida, ceja de ramas y ojos
ambar(E.roca(m, (0, -0.48, 1.93), 0.24, 4, 1, 0.2, (1.15, 0.9, 0.85)), "cabeza")
for l in (1, -1):
    brillo(m.esfera((0.10 * l, -0.69, 1.95), (0.045, 0.03, 0.035), (8, 6)), "cabeza")
    mate(m.tubo([(0.02 * l, -0.66, 2.02), (0.15 * l, -0.66, 2.03), (0.27 * l, -0.56, 2.08)], [0.05, 0.045, 0.02], 6,
                ref=Vector((0, 0, 1))), "cabeza", "rama")
mate(m.tubo([(0, -0.62, 2.1), (0.05, -0.55, 2.2), (0.12, -0.45, 2.28)], [0.04, 0.03, 0.01], 5), "cabeza", "rama")
# ramas petrificadas que atan el cuerpo (de la espalda al pecho y a los hombros)
for k in range(7):
    a0 = 2 * math.pi * k / 7
    pts, rad = [], []
    for j in range(7):
        t = j / 6
        a = a0 + t * 1.7
        z = 0.95 + t * 0.85 + 0.08 * math.sin(t * 6 + k)
        rr = 0.72 * (1 - 0.35 * ((z - 1.3) / 0.7) ** 2)
        pts.append((math.cos(a) * rr * 1.06, 0.02 + math.sin(a) * rr * 0.9, z))
        rad.append(0.05 * (1 - 0.6 * t) + 0.012)
    mate(m.tubo(pts, rad, 6), tronco, "rama")
# el nido de la espalda: aro de ramas trenzadas y tres huevos (con su hueso, se mece)
CN = Vector((0, 0.42, 1.92))
for k in range(16):
    a0 = 2 * math.pi * k / 16
    pts = []
    for j in range(5):
        a = a0 + j * 0.42
        rr = 0.42 + 0.05 * math.sin(j * 1.7 + k)
        pts.append(CN + Vector((math.cos(a) * rr, math.sin(a) * rr * 0.75, -0.05 + 0.10 * (j % 2) + 0.03 * (k % 3))))
    mate(m.tubo(pts, [0.035, 0.04, 0.04, 0.035, 0.015], 5), "nido", "nido", 0.6)
mate(E.roca(m, CN + Vector((0, 0, -0.10)), 0.38, 8, 1, 0.1, (1.0, 0.75, 0.25)), "nido", "nido", 0.6)
for k, (x, y) in enumerate(((-0.12, 0.0), (0.12, 0.04), (0.0, -0.13))):
    mate(m.esfera(CN + Vector((x, y, 0.04)), (0.09, 0.09, 0.12), (10, 7), Euler((0.2 * k, 0.3, 0))), "nido", "huevo",
         0.4)
for s, l in ((".L", 1), (".R", -1)):
    # hombros, brazos y puños enormes, con brazales de rama
    ambar(E.roca(m, (0.74 * l, 0.0, 1.66), 0.27, 60 + l, 1, 0.2), "hombro" + s)
    ambar(E.roca(m, (0.88 * l, 0.03, 1.33), 0.22, 62 + l, 1, 0.22, (1, 1, 1.4)), "brazo" + s)
    ambar(E.roca(m, (1.0 * l, 0.0, 0.86), 0.21, 64 + l, 1, 0.2, (1, 1, 1.35)), "antebrazo" + s, "ambar_oscuro")
    for j, z in enumerate((0.78, 0.9, 1.0)):
        mate(m.tubo([(1.0 * l + 0.24 * math.cos(a), 0.0 + 0.24 * math.sin(a), z + 0.02 * math.sin(3 * a))
                     for a in np.linspace(0, 2 * math.pi, 9)], [0.03] * 9, 5), "antebrazo" + s, "rama")
    ambar(E.roca(m, (1.03 * l, -0.07, 0.46), 0.25, 66 + l, 2, 0.12, (1.0, 1.1, 0.95)), "mano" + s)
    # piernas cortas y pies redondos
    ambar(E.roca(m, (0.34 * l, -0.01, 0.63), 0.22, 70 + l, 1, 0.2, (1, 1, 1.1)), "muslo" + s, "ambar_oscuro")
    ambar(E.roca(m, (0.37 * l, 0.0, 0.32), 0.19, 72 + l, 1, 0.2, (1, 1, 1.0)), "pierna" + s)
    ambar(E.roca(m, (0.38 * l, -0.08, 0.10), 0.22, 74 + l, 1, 0.12, (1.0, 1.3, 0.48)), "pie" + s, "ambar_oscuro")
# la onda del Pisotón: un aro plano a ras de suelo (escondido a escala 0,01)
O0 = Vector((0, -0.5, 0.03))
pts = [O0 + Vector((math.cos(a), math.sin(a), 0)) for a in np.linspace(0, 2 * math.pi, 33)]
brillo(m.tubo(pts, [(0.06, 0.02)] * 33, 4, ref=Vector((0, 0, 1))), "onda")

ob = m.objeto(NOMBRE, col)
E.materiales(ob, [NOMBRE + "_atlas", NOMBRE + "_brillo", NOMBRE + "_ambar"])
C.enlazar(ob, arm)
TRIS = C.triangulos(ob)
E.oclusion(ob, rayos=24, dist=0.5, minimo=0.45)
print("triángulos:", TRIS)

# ================================================================== poses y clips

rig = E.Rig(arm, polo_codo={".L": Vector((0.7, 0.7, 0)), ".R": Vector((-0.7, 0.7, 0))})
rig.defecto = {"onda@esc": (0.01, 0.01, 0.01)}
CLIPS = {}


def P(*ds):
    out = {}
    for d in ds:
        out.update(d)
    return out


def luz(v):
    return {"luz@esc": (v, v, v)}


L, R, sim = E.L, E.R, E.sim
REPOSO = P(sim(L(brazo=(-6, -4, 0), antebrazo=(-12, 0, 0), hombro=(0, 0, 0))),
           sim({"mano.L@ik": (0.30, -0.30, 2.30), "mano.L@ikw": 0.0}), {"pecho": (6, 0, 0),
                                                                                  "cabeza": (-4, 0, 0)}, luz(1.0))
BALANCEO_I = P(REPOSO, {"raiz@loc": (0.035, 0, 0), "cadera": (0, -3, 0), "pecho": (6, 4, 4), "cabeza": (-4, -3, 5),
                        "nido": (0, -3, 0)}, sim(L(brazo=(-4, -8, 0))), R(brazo=(-9, 2, 0)))
BALANCEO_D = P(REPOSO, {"raiz@loc": (-0.035, 0, -0.01), "cadera": (0, 3, 0), "pecho": (7, -4, -4),
                        "cabeza": (-4, 3, -5), "nido": (0, 4, 0)}, sim(L(brazo=(-9, -2, 0))), R(brazo=(-4, 8, 0)))


def clip(nombre, claves, bucle=False, proc=None, eventos=None):
    act, dur = rig.clip(nombre, claves, bucle, proc=proc)
    CLIPS[nombre] = {"duracion": round(dur, 4), "bucle": bucle, "eventos": eventos or {}}


clip("reposo", [(0, REPOSO), (0.6, BALANCEO_I), (1.2, P(REPOSO, {"pecho": (4, 0, 0)})), (1.8, BALANCEO_D),
                (2.4, REPOSO)], bucle=True)


def pasos(dur, paso, alto, bote, ancho=0.38, inclina=0.0, brazos=14):
    def f(seg):
        out = {}
        for s, desfase, l in ((".L", 0.0, 1), (".R", 0.5, -1)):
            fa = (seg / dur + desfase) % 1.0
            if fa < 0.5:
                y, z, rx = -paso / 2 + paso * (fa / 0.5), 0.17, 0.0
            else:
                t = (fa - 0.5) / 0.5
                y = paso / 2 - paso * (0.5 - 0.5 * math.cos(math.pi * t))
                z = 0.17 + alto * math.sin(math.pi * t)
                rx = -18 * math.sin(math.pi * t)
            out["pie" + s + "@ik"] = (ancho * l, y + 0.02, z)
            out["pie" + s + "@rot"] = (rx, 0, 0)
        fase = 2 * math.pi * seg / dur
        out["raiz@loc"] = (0.05 * math.sin(fase), 0, -bote * (0.5 + 0.5 * math.cos(2 * fase)))
        out["pecho"] = (8 + inclina, -7 * math.sin(fase), -5 * math.sin(fase))      # el bamboleo de lado
        out["cadera"] = (0, 4 * math.sin(fase), 6 * math.sin(fase))
        out["cabeza"] = (-6 - inclina * 0.5, 5 * math.sin(fase), 0)
        out["nido"] = (3 * math.cos(2 * fase), 4 * math.sin(fase), 0)
        out["brazo.L"] = (-6 - brazos * math.sin(fase), -6, 0)
        out["brazo.R"] = (-6 + brazos * math.sin(fase), 6, 0)
        out["antebrazo.L"] = (-14 - 8 * math.sin(fase + 0.6), 0, 0)
        out["antebrazo.R"] = (-14 + 8 * math.sin(fase + 0.6), 0, 0)
        return out
    return f


clip("caminar", [(0, REPOSO), (1.4, REPOSO)], bucle=True, proc=pasos(1.4, 0.45, 0.14, 0.03))
clip("correr", [(0, REPOSO), (0.9, REPOSO)], bucle=True, proc=pasos(0.9, 0.7, 0.22, 0.07, inclina=12, brazos=30))

# entrada (2 s): dormido como una roca (encogido, sin luz), despierta (0,5 s), se levanta y golpea el suelo con los dos
# puños (1,5 s)
ROCA = P(sim(L(brazo=(-50, 10, 0), antebrazo=(-70, 0, 0))), {"pecho": (38, 0, 0), "columna": (12, 0, 0),
                                                            "cabeza": (20, 0, 0), "raiz@loc": (0, 0.05, -0.24)}, luz(0.0))
PUNOS_SUELO = P(sim(L(brazo=(-55, -6, 0), antebrazo=(-20, 0, 0))), {"pecho": (34, 0, 0), "columna": (8, 0, 0),
                                                                     "cabeza": (-20, 0, 0), "raiz@loc": (0, 0.0, -0.12)},
                luz(2.4))
clip("entrada", [(0, ROCA), (0.45, ROCA), (0.65, P(ROCA, luz(2.0))),
                 (1.15, P(REPOSO, sim(L(brazo=(-120, -15, 0), antebrazo=(-40, 0, 0))), {"pecho": (-12, 0, 0),
                                                                                       "cabeza": (-14, 0, 0)}, luz(1.8))),
                 (1.5, PUNOS_SUELO, "acel"), (2.0, REPOSO)], eventos={"despierta": 0.5, "golpe_suelo": 1.5})

# ataque (1,3 s; atacar_hacha): alza el puño derecho por encima del hombro, gira y lo descarga hacia delante y abajo
# (IMPACTO a 0,7 s); vuelve al reposo
ALZA = P(REPOSO, R(brazo=(-165, 20, 0), antebrazo=(-55, 0, 0), hombro=(0, 0, -12)),
         {"pecho": (-10, 0, -22), "cadera": (0, 0, -8), "cabeza": (-6, 0, 12), "raiz@loc": (0, 0.06, 0)})
PUNETAZO = P(REPOSO, R(brazo=(-70, -4, 0), antebrazo=(-6, 0, 0)), L(brazo=(10, -10, 0)),
             {"pecho": (30, 0, 18), "columna": (8, 0, 6), "cadera": (0, 0, 8), "cabeza": (-24, 0, -8),
              "raiz@loc": (0, -0.24, -0.10), "pie.L@ik": (0.40, -0.30, 0.17)})
clip("ataque", [(0, REPOSO), (0.42, ALZA), (0.52, P(ALZA, {"pie.L@ik": (0.39, -0.15, 0.30)})), (0.7, PUNETAZO, "acel"),
                (0.86, P(PUNETAZO, {"pecho": (33, 0, 20)}), "fren"), (1.3, REPOSO)], eventos={"impacto": 0.7})

# carga (0,9 s) «levanta los puños» y su espera (1,4 s, bucle): los dos puños juntos sobre la cabeza, echado atrás
ARRIBA = P(sim(L(brazo=(-158, 42, 0), antebrazo=(-38, 24, 0), hombro=(0, 0, 10))),
           sim({"mano.L@ik": (0.30, -0.30, 2.30), "mano.L@ikw": 1.0, "codo.L@polo": (1.0, 0.2, 0.0)}),
           {"pecho": (-14, 0, 0), "columna": (-5, 0, 0), "cabeza": (-18, 0, 0), "raiz@loc": (0, 0.05, 0.02),
            "nido": (-6, 0, 0)}, luz(2.4))
clip("carga", [(0, REPOSO), (0.5, P(ARRIBA, {"pecho": (-6, 0, 0)}, luz(1.8))), (0.9, ARRIBA)], eventos={"arriba": 0.9})
clip("carga_espera", [(0, ARRIBA), (0.35, P(ARRIBA, {"pecho": (-16, 0, 2), "raiz@loc": (0, 0.05, 0.035)}, luz(3.2))),
                      (0.7, P(ARRIBA, luz(2.3))), (1.05, P(ARRIBA, {"pecho": (-16, 0, -2), "raiz@loc": (0, 0.05, 0.035)},
                                                             luz(3.2))), (1.4, ARRIBA)], bucle=True)

# golpe fuerte = el PISOTÓN (1,6 s): alza puños y pie (0-0,45 s; desde la carga empieza en 0,45), salta un palmo y
# cae con los dos pies y los dos puños a la vez (IMPACTO a 0,75 s); la onda de polvo sale de ahí y se abre; recupera
ONDA = lambda e: {"onda@esc": (e, e, e)}
SALTO = P(ARRIBA, {"raiz@loc": (0, 0.0, 0.16), "pie.R@ik": (-0.38, -0.05, 0.40), "pie.L@ik": (0.38, 0.02, 0.30),
                   "pecho": (-18, 0, 0)}, luz(3.4))
CAIDA = P(PUNOS_SUELO, sim(L(brazo=(-62, -8, 0), antebrazo=(-10, 0, 0))), {"raiz@loc": (0, -0.12, -0.20),
                                                                           "pecho": (38, 0, 0), "nido": (14, 0, 0)},
          luz(4.0))
clip("golpe_fuerte", [(0, REPOSO), (0.45, P(ARRIBA, {"pie.R@ik": (-0.38, 0.0, 0.32)})), (0.58, SALTO, "fren"),
                      (0.749, P(CAIDA, ONDA(0.01)), "acel"), (0.75, P(CAIDA, ONDA(1.0)), "corte"),
                      (0.95, P(CAIDA, {"pecho": (34, 0, 0), "nido": (-8, 0, 0)}, ONDA(2.4), luz(2.2))),
                      (1.12, P(CAIDA, {"pecho": (30, 0, 0)}, ONDA(3.2), luz(1.6))),
                      (1.13, P(CAIDA, {"pecho": (30, 0, 0)}, ONDA(0.01), luz(1.6)), "corte"),
                      (1.6, REPOSO)], eventos={"impacto": 0.75, "carga": 0.45})

# recibir golpe (0,6 s): el cuerpo se sacude hacia atrás, el nido se zarandea, la luz parpadea
SACUDIDA = P(REPOSO, {"pecho": (-12, 4, 8), "cabeza": (-18, 0, 10), "raiz@loc": (0, 0.10, 0), "nido": (-14, 8, 0)},
             sim(L(brazo=(14, -16, 0))), luz(0.4))
clip("recibir_golpe", [(0, REPOSO), (0.1, SACUDIDA, "fren"), (0.26, P(REPOSO, {"nido": (10, -6, 0)}, luz(1.3))),
                       (0.6, REPOSO)], eventos={"golpe": 0.0})

# aturdido (1,6 s, bucle): interrumpido, la cabeza da vueltas, se tambalea con los brazos colgando
def mareo(seg):
    a = 2 * math.pi * seg / 1.6
    return {"cabeza": (10 + 10 * math.sin(a), 8 * math.cos(a), 14 * math.cos(a)),
            "pecho": (12 + 4 * math.sin(a), 8 * math.cos(a), 0), "raiz@loc": (0.07 * math.cos(a), 0, -0.04),
            "brazo.L": (8 * math.sin(a), -2 + 6 * math.cos(a), 0), "brazo.R": (-8 * math.sin(a), 2 + 6 * math.cos(a), 0),
            "nido": (6 * math.sin(a), 6 * math.cos(a), 0), "luz@esc": (0.5 + 0.3 * math.sin(3 * a),) * 3}


clip("aturdido", [(0, REPOSO), (1.6, REPOSO)], bucle=True, proc=mareo)

# victoria (1,8 s): se golpea el pecho con un puño y con el otro (0,5 y 0,9 s) y da un saltito
GOLPE_PECHO = lambda s, k: P(REPOSO, (L if s == ".L" else R)(brazo=(-95, 30 * k, 0), antebrazo=(-110, 0, 0)),
                             {"pecho": (-12, 0, 0), "cabeza": (-20, 0, 0)}, luz(2.0))
clip("victoria", [(0, REPOSO), (0.35, P(GOLPE_PECHO(".L", 1), {"raiz@loc": (0, 0, 0.03)})),
                  (0.5, P(GOLPE_PECHO(".L", 1), L(brazo=(-80, 40, 0)), luz(2.8)), "acel"),
                  (0.75, GOLPE_PECHO(".R", -1)), (0.9, P(GOLPE_PECHO(".R", -1), R(brazo=(-80, -40, 0)), luz(2.8)), "acel"),
                  (1.2, P(ARRIBA, {"raiz@loc": (0, 0.05, 0.12)})), (1.45, P(ARRIBA, {"raiz@loc": (0, 0.05, -0.04)}), "acel"),
                  (1.8, P(REPOSO, luz(1.6)))], eventos={"pecho": 0.5, "pecho2": 0.9, "aterriza": 1.45})

# derrota (2,2 s): se tambalea, la luz se apaga, cae sentado (0,8 s) y se vuelca de espaldas (suelo 1,5 s)
SENTADO = P(REPOSO, sim(L(brazo=(10, -25, 0), antebrazo=(-6, 0, 0))),
            {"raiz@loc": (0, 0.25, -0.45), "pecho": (-8, 0, 0), "cabeza": (16, 0, 10),
             "pie.L@ik": (0.42, -0.35, 0.15), "pie.R@ik": (-0.42, -0.30, 0.15)}, luz(0.3))
clip("derrota", [(0, REPOSO), (0.25, P(SACUDIDA, luz(0.2))), (0.45, P(SACUDIDA, {"raiz@loc": (0, 0.16, -0.05)}, luz(0.9))),
                 (0.8, SENTADO, "acel"),
                 (1.5, P(SENTADO, {"raiz": (-62, 0, 0), "raiz@loc": (0, 0.55, -0.15), "cabeza": (-20, 0, 18),
                                   "pie.L@ik": (0.45, -0.5, 0.35), "pie.R@ik": (-0.42, -0.45, 0.30)}, luz(0.05)), "acel"),
                 (2.2, P(SENTADO, {"raiz": (-66, 0, 0), "raiz@loc": (0, 0.55, -0.16), "cabeza": (-24, 0, 22),
                                   "pie.L@ik": (0.45, -0.52, 0.30), "pie.R@ik": (-0.44, -0.48, 0.26)}, luz(0.0)))],
     eventos={"sentado": 0.8, "suelo": 1.5})

# ================================================================== V2 (12/11, especialista de enemigos y combate)
# Clips nuevos para su módulo de combate (combate_golem.gd), AÑADIDOS a los de arriba (que no cambian): con «v2» en la
# línea de órdenes se escribe golem_ambar_v2.glb y golem_ambar_v2_clips.json; sin él, lo de siempre.
#   lanzar (1,5 s)                el Terrón de ámbar: se lleva la mano derecha al nido de la espalda (agarra 0,3), tensa
#                                 echado atrás (0,3-0,55) y lanza por encima del hombro (SUELTA = «impacto» 0,75; el
#                                 terrón lo vuela el combate y el daño cae al llegar); se recupera
#   recibir_golpe_fuerte (1,0 s)  un golpe grande: se echa atrás con un paso, el nido se zarandea y la luz se apaga
V2 = "v2" in argv
if V2:
    AGARRA = P(REPOSO, R(brazo=(-200, 18, 0), antebrazo=(-95, 0, 0), hombro=(0, 0, -10)),
               {"pecho": (-8, 0, -20), "cabeza": (-4, 0, 10), "nido": (0, 6, 0)}, luz(1.8))
    TENSA = P(REPOSO, R(brazo=(-170, 12, 0), antebrazo=(-75, 0, 0), hombro=(0, 0, -14)), L(brazo=(-62, -12, 0)),
              {"pecho": (-16, 0, -28), "cadera": (0, 0, -10), "columna": (-4, 0, -6), "cabeza": (-8, 0, 20),
               "raiz@loc": (0, 0.08, 0), "pie.R@ik": (-0.38, 0.14, 0.17)}, luz(2.4))
    SUELTA = P(REPOSO, R(brazo=(-100, -8, 0), antebrazo=(-12, 0, 0)), L(brazo=(14, -12, 0)),
               {"pecho": (24, 0, 20), "columna": (6, 0, 6), "cadera": (0, 0, 10), "cabeza": (-20, 0, -8),
                "raiz@loc": (0, -0.18, -0.06), "pie.L@ik": (0.40, -0.28, 0.17), "pie.R@ik": (-0.38, 0.10, 0.17)},
               luz(2.0))
    SIGUE = P(SUELTA, R(brazo=(-62, -10, 0), antebrazo=(-6, 0, 0)), {"pecho": (30, 0, 26), "raiz@loc": (0, -0.2, -0.08)})
    clip("lanzar", [(0, REPOSO), (0.3, AGARRA), (0.42, P(AGARRA, {"nido": (6, -4, 0)})), (0.55, TENSA, "fren"),
                    (0.75, SUELTA, "acel"), (0.95, SIGUE, "fren"),
                    (1.2, P(SIGUE, {"pecho": (14, 0, 12), "raiz@loc": (0, -0.10, -0.04), "pie.L@ik": (0.40, -0.16, 0.24)})),
                    (1.5, REPOSO)], eventos={"agarra": 0.3, "impacto": 0.75})

    SACUDIDA2 = P(REPOSO, {"pecho": (-22, 6, 12), "cabeza": (-26, 0, 14), "columna": (-6, 0, 0),
                           "raiz@loc": (0, 0.16, 0.02), "nido": (-24, 12, 0), "pie.R@ik": (-0.38, 0.12, 0.30)},
                  sim(L(brazo=(24, -28, 0))), luz(0.15))
    clip("recibir_golpe_fuerte", [(0, REPOSO), (0.12, SACUDIDA2, "fren"),
                                  (0.3, P(SACUDIDA2, {"pie.R@ik": (-0.38, 0.30, 0.17), "nido": (16, -8, 0)}, luz(1.2)), "acel"),
                                  (0.6, P(REPOSO, {"pecho": (10, 0, 0), "raiz@loc": (0, 0.13, -0.04),
                                                   "pie.R@ik": (-0.38, 0.30, 0.17), "nido": (-6, 3, 0)})),
                                  (0.8, P(REPOSO, {"raiz@loc": (0, 0.06, -0.02), "pie.R@ik": (-0.38, 0.14, 0.26)})),
                                  (1.0, REPOSO)], eventos={"golpe": 0.0})


def medir():
    datos = {}
    for c_, t, h in (("ataque", 0.7, "mano.R"), ("golpe_fuerte", 0.75, "mano.R")) + ((("lanzar", 0.75, "mano.R"),) if V2 else ()):
        p = E.punto_hueso(arm, rig, c_, t, h, (0, 0.2, 0))
        datos[c_] = {"puno_godot": [round(p.x, 3), round(p.z, 3), round(-p.y, 3)]}
    p = E.punto_hueso(arm, rig, "reposo", 0.0, "nido", (0, 0.4, 0))
    datos["alto_reposo"] = round(p.z, 3)
    return datos


medidas = medir()
arm.animation_data.action = None
for pb in arm.pose.bones:
    pb.rotation_quaternion = Quaternion()
    pb.location = Vector()
    pb.scale = Vector((1, 1, 1))

SUFIJO = "_v2" if V2 else ""          # V2: GLB y JSON nuevos al lado; las texturas (las mismas) no se reescriben
A.guardar(os.path.join(LAMINAS, NOMBRE + "_atlas.png"),
          [] if V2 else [(os.path.join(SALIDA, NOMBRE + ".webp"), 1024), (os.path.join(SALIDA, NOMBRE + "_bajo.webp"), 512)])
E.exportar(os.path.join(SALIDA, NOMBRE + SUFIJO + ".glb"))
E.guardar_json(os.path.join(SALIDA, NOMBRE + SUFIJO + "_clips.json"), {
    "modelo": NOMBRE + SUFIJO, "triangulos": TRIS, "huesos": len(HUESOS), "fps": E.FPS,
    "texturas": {"alto": NOMBRE + ".webp (1024)", "bajo": NOMBRE + "_bajo.webp (512)"},
    "color_brillo": BRILLO, "clips": CLIPS, "medidas": medidas,
    "generador": "enemigos/golem_ambar/fuente/crear_golem_ambar.py%s (Blender 5.2.3)" % (" -- ... v2" if V2 else "")})
print("clips:", {k: v["duracion"] for k, v in CLIPS.items()})
print("medidas:", medidas)

if CON_LAMINAS:
    img = bpy.data.images.load(os.path.join(SALIDA, NOMBRE + ".webp"))
    E.material_vista(bpy.data.materials[NOMBRE + "_atlas"], img)
    E.material_vista(bpy.data.materials[NOMBRE + "_ambar"], img)
    bpy.data.materials[NOMBRE + "_ambar"].node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.3
    E.material_vista(bpy.data.materials[NOMBRE + "_brillo"], None, emision=(*BRILLO, 2.2))
    C.lamina_criatura(esc, arm, ob, RAIZ, os.path.join(LAMINAS, NOMBRE + SUFIJO + "_lamina.png"),
                      "Gólem de ámbar — el Guardián del Nido (V12, fase C)", sep=2.6, giros=(0, -40, -90),
                      alto_cam=1.3, orto=13.0)
    for o in list(esc.objects):
        if o.type == 'CAMERA':
            bpy.data.objects.remove(o)
    for o in esc.objects:
        if o.name.startswith("kael") or (o.parent and o.parent.name.startswith("kael")):
            o.hide_render = True
    arm.location = (0, 0, 0)
    arm.rotation_euler = (0, 0, 0)
    esc.render.resolution_x, esc.render.resolution_y = 800, 900
    inst = [("reposo", 0.0), ("entrada", 0.3), ("ataque", 0.42), ("ataque", 0.7), ("carga_espera", 0.35),
            ("golpe_fuerte", 0.58), ("golpe_fuerte", 0.75), ("golpe_fuerte", 0.95), ("recibir_golpe", 0.1),
            ("aturdido", 0.4), ("caminar", 0.35), ("victoria", 0.5), ("derrota", 0.8), ("derrota", 2.2)]
    if V2:                            # V2: las poses de los clips nuevos
        inst = [("lanzar", 0.0), ("lanzar", 0.3), ("lanzar", 0.55), ("lanzar", 0.75), ("lanzar", 0.95), ("lanzar", 1.2),
                ("recibir_golpe_fuerte", 0.12), ("recibir_golpe_fuerte", 0.3), ("recibir_golpe_fuerte", 0.6),
                ("recibir_golpe_fuerte", 0.8), ("carga_espera", 0.35), ("golpe_fuerte", 0.75), ("aturdido", 0.4),
                ("derrota", 1.5)]
    carpeta = os.path.join(LAMINAS, "poses")
    os.makedirs(carpeta, exist_ok=True)
    rutas = E.poses_render(esc, arm, inst, carpeta, NOMBRE + SUFIJO, objetivo=(0, -0.4, 1.2), azimut=-40, elev=12, orto=4.6)
    E.componer(rutas, os.path.join(LAMINAS, NOMBRE + SUFIJO + "_poses.png"), 7)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(LAMINAS, NOMBRE + SUFIJO + ".blend"))
print("hecho")
