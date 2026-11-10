# Coloso de la Falla (V9, jefe 2: jefe de la Garganta 3D): gigantesco guardián de piedra con inscripciones antiguas.
# Modelo, esqueleto y clips hechos desde cero con este guion (geometría procedural propia: ningún recurso descargado;
# obra propia del proyecto). Mismo método que el Guardián del Bosque (enemigos/guardian_bosque/fuente/crear_guardian.py).
#
#   blender -b --factory-startup -P crear_coloso.py -- <salida.glb> [<salida.blend>]
#
# Regenera el GLB entero: misma semilla, mismo resultado. El .blend (opcional) sirve para renderizar las capturas
# (capturas_coloso.py) y no se versiona: se regenera con este guion.
#
# Ejes (Blender): el Coloso mira a -Y, Z arriba, su izquierda es +X (huesos .L). En Godot mira a +Z.
# Giros de las poses: alrededor de los ejes del esqueleto en reposo (como en el Guardián): X (+) inclina hacia delante
# lo que apunta arriba y lleva hacia atrás lo que cuelga; Z (+) gira hacia su izquierda; Y (+) lleva lo de arriba hacia
# +X. En los huesos .R, los giros en Y y Z y el desplazamiento en X se reflejan (par() y parl()).
#
# Forma: bloques de piedra redondeados (cajas que tienden a la esfera) pegados cada uno a un solo hueso: la piedra no se
# estira, gira entera. Pecho y hombros enormes, cabeza hundida entre ellos, antebrazos y puños gigantes, piernas cortas
# y gruesas, tres monolitos en la espalda. Placas de pizarra en hombros y antebrazos, con runas.
#
# Presupuesto móvil: una malla, 2 materiales (piedra con colores de vértice y runas emisivas), 29 huesos, < 12 000
# triángulos, sin texturas. Las piezas que solo salen en algún clip van en la misma malla, pesadas a su propio hueso, y
# se esconden con escala 0,01 (dentro del cuerpo o a ras de suelo):
#   grietas          el brillo de las grietas del pecho y de la espalda (los puntos vulnerables). Escala 1 en todos los
#                    clips salvo dormido (0,01) y fase2 (crece de 0,01 a 1). En la fase 1 las esconde coloso_falla_3d.gd
#                    salvo que el combate las señale. Las grietas oscuras se ven siempre.
#   grietas_derrota  las grietas que se abren al ser derrotado: solo en derrota.
#   musgo            el musgo de estatua: solo en dormido.
#   rocas            las lascas que brotan donde el puño golpea el suelo: solo en golpe_fuerte.
#   proyectiles      las rocas que salen despedidas del golpe: solo en golpe_fuerte.
# Placas (placa_hombro.L/.R, placa_antebrazo.L/.R): cerradas en todos los clips salvo fase2, que las separa y las deja
# abiertas al final; en la fase 2 del combate el guion las mantiene abiertas (lee la pose final de fase2).
# Luz de las runas: el material «runas» (runas, ojos y grietas) brilla según la escala del hueso «nucleo» de cada clip
# (como el corazón del Guardián): 1 en reposo, late en la carga, se enciende en la fase 2, se apaga al ser derrotado y
# apenas respira dormido.
# La altura de la raíz de cada pose se calcula para que lo más bajo de las piernas toque el suelo; en las poses con
# apoyos (puño al suelo, de rodillas) el giro del brazo se busca para que el puño toque el suelo.
# Colores de vértice: se guardan en sRGB (no en lineal, como pediría glTF), como en el Guardián: el renderizador
# Compatibility no convierte los colores de vértice. En Godot: piedra.tres (vertex_color_is_srgb = true) y runas.tres,
# materiales externos en el .import. En Blender, un nodo Gamma 2,2 los muestra bien en los renders.
import bpy, bmesh, sys, math, random
import numpy as np
from mathutils import Vector, Quaternion, Euler, noise
from mathutils.bvhtree import BVHTree

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SALIDA_GLB = argv[0] if argv else ""
SALIDA_BLEND = argv[1] if len(argv) > 1 else ""

random.seed(23)
FPS = 30

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.fps = FPS


# ---------------------------------------------------------------- colores (sRGB)

PIEDRA = ((0.29, 0.28, 0.32), (0.47, 0.45, 0.48), (0.68, 0.65, 0.63))      # gris de la Garganta, algo violeta
PLACA = ((0.22, 0.23, 0.29), (0.36, 0.37, 0.44), (0.56, 0.57, 0.62))       # pizarra más oscura y fría
OCRE = (0.58, 0.47, 0.35)
VIOLETA = (0.40, 0.37, 0.47)
MUSGO = (0.30, 0.40, 0.18)
MUSGO_CLARO = (0.46, 0.56, 0.24)
MUSGO_OSCURO = (0.18, 0.27, 0.12)
FLORES = [(0.95, 0.90, 0.72), (0.85, 0.72, 0.95)]
HOJAS = [(0.36, 0.52, 0.18), (0.48, 0.60, 0.22)]
GRIETA = (0.09, 0.08, 0.10)
RUNA = (0.34, 0.26, 0.19)            # el material «runas»: apagadas, una incrustación oscura y cálida
AMBAR = (1.00, 0.62, 0.25)           # su luz: ámbar, la de la Falla


def mezcla(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(a[i] * (1 - t) + b[i] * t for i in range(3))


def suave(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def lineal(c):
    return tuple(x ** 2.2 for x in c)


# ---------------------------------------------------------------- constructor de la malla

class Malla:
    def __init__(self):
        self.v, self.col, self.pesos = [], [], []
        self.caras, self.mats, self.cerradas, self.grupos = [], [], [], []

    def vert(self, p, c, pesos):
        self.v.append(Vector(p))
        self.col.append(c)
        self.pesos.append(dict(pesos) if isinstance(pesos, dict) else {pesos: 1.0})
        return len(self.v) - 1

    def cara(self, idx, mat=0, cerrada=True, grupo=""):
        self.caras.append(tuple(idx))
        self.mats.append(mat)
        self.cerradas.append(cerrada)
        self.grupos.append(grupo)


M = Malla()


def color_piedra(pal, tinte, n, p, borde, musgo):
    oscuro, medio, claro = pal
    ru = noise.noise(p * 3.3 + Vector((1.3, 7.1, 0.4)))
    c = mezcla(oscuro, medio, 0.62 + 0.45 * ru)
    if tinte is not None:
        c = mezcla(c, tinte[0], tinte[1] * (0.7 + 0.3 * noise.noise(p * 1.4)))
    c = mezcla(c, claro, borde * 0.5 + max(0.0, n.z) * 0.18)          # aristas gastadas y caras de arriba, más claras
    c = mezcla(c, oscuro, max(0.0, -n.z) * 0.55)                       # por debajo, en sombra
    if musgo > 0:
        mm = noise.noise(p * 4.5 + Vector((5.1, 2.3, 0.7))) * 0.5 + 0.5
        f = suave(0.62, 0.9, n.z + (mm - 0.5) * 0.5) * musgo
        if f > 0:
            c = mezcla(c, mezcla(MUSGO_OSCURO, MUSGO_CLARO, mm * 1.2), f)
    return c


TINTES = [None, None, (OCRE, 0.32), (VIOLETA, 0.35), (OCRE, 0.18)]


def bloque(grupo, centro, medio, pesos, rot=(0, 0, 0), r=0.32, cortes=2, amp=0.034, pal=PIEDRA, tinte="azar",
           musgo=0.28, mat=0, color=None, ahusado=0.0, semilla=None):
    """Bloque de piedra: cubo subdividido que tiende a la esfera (r), deformado con ruido. medio = semiejes.
    ahusado > 0 lo ensancha por abajo (antebrazos, espinillas)."""
    if semilla is None:
        semilla = random.uniform(0, 50)
    if tinte == "azar":
        tinte = random.choice(TINTES)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=2.0)
    if cortes > 0:
        bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=cortes, use_grid_fill=True)
    R = Euler([math.radians(a) for a in rot]).to_matrix()
    C, H = Vector(centro), Vector(medio)
    idx = {}
    for v in bm.verts:
        p = v.co.copy()
        q = p * (1 - r) + p.normalized() * r
        k = 1.0 - ahusado * q.z
        loc = Vector((q.x * H.x * k, q.y * H.y * k, q.z * H.z))
        nl = Vector((q.x / H.x, q.y / H.y, q.z / H.z)).normalized()
        n = (R @ nl).normalized()
        w = C + R @ loc
        w += n * amp * noise.noise(w * 2.2 + Vector((semilla, semilla * 0.37, 1.3)))
        a = sorted([abs(p.x), abs(p.y), abs(p.z)])
        borde = suave(0.6, 1.0, a[1])
        c = color(n, w) if color else color_piedra(pal, tinte, n, w, borde, musgo)
        idx[v.index] = M.vert(w, c, pesos)
    for f in bm.faces:
        M.cara([idx[v.index] for v in f.verts], mat, True, grupo)
    bm.free()


def marcos(pts, ref=None):
    """Tangentes y normales por transporte paralelo (sin torsión a lo largo del tubo)."""
    n = len(pts)
    T = [(pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized() for i in range(n)]
    r0 = Vector(ref) if ref is not None else Vector((1, 0, 0))
    N = r0 - T[0] * r0.dot(T[0])
    if N.length < 1e-3:
        N = Vector((0, 1, 0)) - T[0] * T[0].y
    N.normalize()
    Ns = [N]
    for i in range(1, n):
        N = Ns[-1] - T[i] * Ns[-1].dot(T[i])
        N.normalize()
        Ns.append(N)
    return T, Ns, [T[i].cross(Ns[i]) for i in range(n)]


def tubo(pts, radios, pesos, lados=6, amp=0.1, color=None, mat=0, tapa0=True, punta=True, grupo="", semilla=0.0):
    """Tubo por una polilínea (lascas de roca, lianas). pesos: uno por anillo. color(p, normal)."""
    pts = [Vector(p) for p in pts]
    T, N, B = marcos(pts)
    anillos = []
    for i, p in enumerate(pts):
        anillo = []
        for k in range(lados):
            a = 2 * math.pi * k / lados
            normal = N[i] * math.cos(a) + B[i] * math.sin(a)
            d = amp * noise.noise(p * 3.0 + normal + Vector((semilla, 0, 0)))
            q = p + normal * radios[i] * (1 + d)
            anillo.append(M.vert(q, color(q, normal) if color else PIEDRA[1], pesos[i]))
        anillos.append(anillo)
    for i in range(len(anillos) - 1):
        a0, a1 = anillos[i], anillos[i + 1]
        for k in range(lados):
            k2 = (k + 1) % lados
            M.cara([a0[k], a0[k2], a1[k2], a1[k]], mat, True, grupo)
    if tapa0:
        c = M.vert(pts[0] - T[0] * radios[0] * 0.3, M.col[anillos[0][0]], pesos[0])
        for k in range(lados):
            M.cara([c, anillos[0][(k + 1) % lados], anillos[0][k]], mat, True, grupo)
    fin = pts[-1] + T[-1] * radios[-1] * (2.0 if punta else 0.3)
    c = M.vert(fin, M.col[anillos[-1][0]], pesos[-1])
    for k in range(lados):
        M.cara([anillos[-1][k], anillos[-1][(k + 1) % lados], c], mat, True, grupo)


def bulto(centro, radio, pesos, escala=(1, 1, 1), subdiv=1, amp=0.2, color=None, mat=0, semilla=0.0, grupo=""):
    """Icosfera deformada (musgo)."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=1.0)
    idx = {}
    for v in bm.verts:
        d = v.co.normalized()
        rr = radio * (1 + amp * noise.noise(d * 2.2 + Vector((semilla, semilla * 0.37, 1.3))))
        p = Vector(centro) + Vector((d.x * escala[0], d.y * escala[1], d.z * escala[2])) * rr
        idx[v.index] = M.vert(p, color(d, p) if color else PIEDRA[1], pesos)
    for f in bm.faces:
        M.cara([idx[v.index] for v in f.verts], mat, True, grupo)
    bm.free()


def color_musgo(d, p):
    mm = noise.noise(p * 6.0 + Vector((1.7, 0.2, 3.3))) * 0.5 + 0.5
    c = mezcla(MUSGO_OSCURO, MUSGO_CLARO, mm * 1.2 + d.z * 0.25)
    if d.z < -0.3:
        c = mezcla(c, MUSGO_OSCURO, 0.5)
    return c


def cara_hacia(idx, hacia, mat, grupo):
    a, b, c = (M.v[i] for i in idx[:3])
    if (b - a).cross(c - a).dot(hacia) < 0:
        idx = list(reversed(idx))
    M.cara(idx, mat, False, grupo)


def cinta(puntos, normales, anchos, abajo, arriba, pesos, mat, color, grupo):
    """Cinta incrustada en la superficie (trazo de runa, grieta): sale «arriba» m y se hunde «abajo» m. Sin cara de
    abajo (queda dentro de la piedra). pesos: uno para todos (dict o nombre) o una lista."""
    n = len(puntos)
    if n < 2:
        return
    filas, lados = [], []
    for i in range(n):
        p, nr = puntos[i], normales[i]
        t = (puntos[min(i + 1, n - 1)] - puntos[max(i - 1, 0)]).normalized()
        s = nr.cross(t).normalized()
        w = anchos[i] * 0.5
        if i == 0:
            p = p - t * w * 0.6
        if i == n - 1:
            p = p + t * w * 0.6
        ps = pesos[i] if isinstance(pesos, list) else pesos
        filas.append([M.vert(p - s * w - nr * abajo, color, ps), M.vert(p - s * w + nr * arriba, color, ps),
                      M.vert(p + s * w + nr * arriba, color, ps), M.vert(p + s * w - nr * abajo, color, ps)])
        lados.append((nr, s, t))
    for i in range(n - 1):
        a, b = filas[i], filas[i + 1]
        nr, s, t = lados[i]
        cara_hacia([a[1], a[2], b[2], b[1]], nr, mat, grupo)
        cara_hacia([a[0], a[1], b[1], b[0]], -s, mat, grupo)
        cara_hacia([a[2], a[3], b[3], b[2]], s, mat, grupo)
    cara_hacia(filas[0], -lados[0][2], mat, grupo)
    cara_hacia(filas[-1], lados[-1][2], mat, grupo)


# ---------------------------------------------------------------- superficie (rayos contra los bloques)

def arbol(grupos):
    caras = [i for i, g in enumerate(M.grupos) if g in grupos]
    usados = sorted({v for i in caras for v in M.caras[i]})
    remap = {v: k for k, v in enumerate(usados)}
    t = BVHTree.FromPolygons([M.v[v] for v in usados], [[remap[v] for v in M.caras[i]] for i in caras])
    return t, caras


def rayo(ar, origen, direccion):
    t, caras = ar
    d = Vector(direccion).normalized()
    loc, nor, i, dist = t.ray_cast(Vector(origen), d, 6.0)
    if loc is None:
        return None
    if nor.dot(d) > 0:
        nor = -nor
    return loc, nor, M.pesos[M.caras[caras[i]][0]]


def ejes(fuera, arriba):
    n0 = Vector(fuera).normalized()
    v = Vector(arriba)
    v = (v - n0 * v.dot(n0)).normalized()
    return n0, v.cross(n0), v


# Runas: trazos en un cuadrado de -1 a 1 (formas angulosas propias, no copiadas de ningún alfabeto).
# (Se evitan las que parecen letras latinas: en la primera prueba el cinturón se leía «FOXANY».)
GLIFOS = [
    [((0, -1), (0, 1)), ((0, 1), (0.6, 0.55)), ((-0.6, -0.15), (0, -0.6))],
    [((-0.6, 0.15), (0, 0.9)), ((0, 0.9), (0.6, 0.15)), ((-0.6, -0.65), (0, 0.05)), ((0, 0.05), (0.6, -0.65))],
    [((-0.6, -0.55), (0.6, -0.55)), ((0.6, -0.55), (0, 0.55)), ((0, 0.55), (-0.6, -0.55)), ((0, 0.55), (0, 1))],
    [((0, 1), (0.6, 0)), ((0.6, 0), (0, -1)), ((0, -1), (-0.6, 0)), ((-0.6, 0), (0, 1)), ((0, -0.35), (0, 0.35))],
    [((-0.55, 1), (0.45, 0.35)), ((0.45, 0.35), (-0.45, -0.3)), ((-0.45, -0.3), (0.55, -1))],
    [((0, -1), (0, 0.25)), ((-0.6, 0.95), (-0.6, 0.25)), ((0.6, 0.95), (0.6, 0.25)), ((-0.6, 0.25), (0.6, 0.25))],
    [((-0.65, 0), (0, 0.6)), ((0, 0.6), (0.65, 0)), ((0.65, 0), (0, -0.6)), ((0, -0.6), (-0.65, 0)), ((-0.25, 0), (0.25, 0))],
    [((-0.6, -1), (-0.6, 0.8)), ((-0.6, 0.8), (0.6, 0.8)), ((0.6, 0.8), (0.6, -0.4)), ((0.6, -0.4), (-0.1, -0.4)),
     ((-0.1, -0.4), (-0.1, 0.25))],
]
N_GLIFOS = [0]


def glifo(ar, centro, fuera, arriba, tam, forma=None, grosor=0.026, grupo="runas"):
    """Una runa: trazos de material emisivo incrustados en la superficie de los grupos de ar."""
    if forma is None:
        forma = random.randrange(len(GLIFOS))
    n0, u, v = ejes(fuera, arriba)
    hecho = False
    for (a, b) in GLIFOS[forma]:
        a, b = Vector(a), Vector(b)
        largo = (b - a).length * tam * 0.5
        n = max(2, int(largo / 0.05) + 1)
        pts, nrs, ps = [], [], []
        for k in range(n):
            q = a.lerp(b, k / (n - 1))
            obj = Vector(centro) + u * q.x * tam * 0.36 + v * q.y * tam * 0.5
            h = rayo(ar, obj + n0 * 1.2, -n0)
            if h:
                pts.append(h[0]); nrs.append(h[1]); ps.append(h[2])
        if len(pts) >= 2:
            cinta(pts, nrs, [grosor] * len(pts), 0.03, 0.012, ps[len(ps) // 2], 1, RUNA, grupo)
            hecho = True
    if hecho:
        N_GLIFOS[0] += 1


def linea(ar, puntos, fuera, grosor=0.02, grupo="runas"):
    """Línea emisiva por la superficie (los bordes de una inscripción)."""
    n0 = Vector(fuera).normalized()
    pts, nrs, ps = [], [], []
    for p in puntos:
        h = rayo(ar, Vector(p) + n0 * 1.2, -n0)
        if h:
            pts.append(h[0]); nrs.append(h[1]); ps.append(h[2])
    cinta(pts, nrs, [grosor] * len(pts), 0.03, 0.01, ps, 1, RUNA, grupo)


def grieta(ar, centro, fuera, arriba, semilla, hueso_luz, hueso_oscura=None, largo=9, ramas=2, paso=0.075,
           ancho=0.06, ang0=-90.0):
    """Grieta en zigzag: una cinta oscura (piedra) y, encima, una más estrecha de luz (runas) pesada a hueso_luz.
    La oscura va con el bloque (o con hueso_oscura). Devuelve el centro de la grieta."""
    rnd = random.Random(semilla)
    n0, u, v = ejes(fuera, arriba)

    def camino(u0, v0, ang, n):
        pts = [(u0, v0)]
        for k in range(n):
            ang += rnd.uniform(-38, 38)
            u0 += math.cos(math.radians(ang)) * paso
            v0 += math.sin(math.radians(ang)) * paso
            pts.append((u0, v0))
        return pts

    tronco = camino(0.0, paso * largo * 0.45, ang0 + rnd.uniform(-15, 15), largo)
    caminos = [tronco]
    for r in range(ramas):
        k = 2 + r * max(1, (largo - 3) // max(1, ramas))
        k = min(k, len(tronco) - 2)
        lado = 1 if r % 2 == 0 else -1
        caminos.append(camino(tronco[k][0], tronco[k][1], ang0 + lado * rnd.uniform(40, 70), max(3, largo // 2 - 1)))
    for j, cm in enumerate(caminos):
        pts, nrs, ps = [], [], []
        for (a, b) in cm:
            obj = Vector(centro) + u * a + v * b
            h = rayo(ar, obj + n0 * 1.2, -n0)
            if h:
                pts.append(h[0]); nrs.append(h[1]); ps.append(h[2])
        if len(pts) < 2:
            continue
        n = len(pts)
        fin = 0.35 if j else 0.5
        anchos = [ancho * (1.0 - (1 - fin) * i / (n - 1)) * (0.75 if j else 1.0) for i in range(n)]
        anchos[0] *= 0.6 if j == 0 else 1.0
        pesos = [hueso_oscura] * n if hueso_oscura else ps
        cinta(pts, nrs, anchos, 0.03, 0.006, pesos, 0, GRIETA, "grieta")
        cinta(pts, nrs, [a * 0.42 for a in anchos], 0.03, 0.013, hueso_luz, 1, RUNA, "grieta_luz")
    h = rayo(ar, Vector(centro) + v * paso * largo * 0.1 + n0 * 1.2, -n0)
    return h[0] if h else Vector(centro)


# ---------------------------------------------------------------- el cuerpo

def X(p, s):
    return (p[0] * s, p[1], p[2])


def crear_cuerpo():
    # tronco: cadera, cintura, pecho, pectorales, lomo y monolitos de la espalda
    bloque("cadera", (0, 0.06, 1.80), (0.70, 0.42, 0.27), "cadera", r=0.36, cortes=3, tinte=(OCRE, 0.3))
    for s in (-1, 1):
        bloque("faldon", X((0.32, -0.40, 1.56), s), (0.26, 0.08, 0.22), "cadera", rot=(-12, 0, -4 * s), cortes=1,
               pal=PLACA, tinte=None, r=0.25)
        bloque("faldon", X((0.44, 0.40, 1.58), s), (0.24, 0.08, 0.20), "cadera", rot=(12, 0, 4 * s), cortes=1,
               pal=PLACA, tinte=None, r=0.25)
    bloque("cintura", (0, 0.06, 2.18), (0.56, 0.37, 0.25), "columna", r=0.45, tinte=(VIOLETA, 0.4))
    bloque("vientre", (0, -0.28, 2.24), (0.38, 0.14, 0.17), "columna", r=0.4, cortes=1)
    bloque("pecho", (0, 0.02, 2.84), (0.86, 0.52, 0.47), "pecho", rot=(-5, 0, 0), r=0.32, cortes=3, musgo=0.5)
    bloque("lomo", (0, 0.27, 3.18), (0.72, 0.40, 0.30), "pecho", r=0.42, musgo=0.8)
    for s in (-1, 1):
        bloque("pectoral", X((0.40, -0.45, 2.99), s), (0.38, 0.14, 0.28), "pecho", rot=(-4, 0, -7 * s), r=0.35)
    bloque("monolito", (0, 0.40, 3.62), (0.17, 0.13, 0.50), "pecho", rot=(-14, 0, 0), r=0.22, musgo=0.9,
           tinte=(OCRE, 0.25))
    for s in (-1, 1):
        bloque("monolito", X((0.43, 0.35, 3.50), s), (0.13, 0.11, 0.37), "pecho", rot=(-12, 13 * s, 0), r=0.22,
               musgo=0.9)
    # cabeza hundida entre los hombros: cráneo, ceja, mandíbula, ojos (luz) y dos crestas
    bloque("cabeza", (0, -0.36, 3.43), (0.27, 0.28, 0.26), "cabeza", r=0.38, tinte=(VIOLETA, 0.2))
    bloque("ceja", (0, -0.60, 3.53), (0.31, 0.085, 0.075), "cabeza", rot=(-10, 0, 0), cortes=1, r=0.3)
    bloque("mandibula", (0, -0.53, 3.24), (0.22, 0.14, 0.10), "cabeza", cortes=1, r=0.35)
    for s in (-1, 1):
        bloque("ojo", X((0.12, -0.622, 3.425), s), (0.07, 0.03, 0.032), "cabeza", rot=(0, 0, 8 * s), cortes=0, r=0.3,
               amp=0.0, mat=1, color=lambda n, p: RUNA)
        bloque("cresta", X((0.21, -0.30, 3.72), s), (0.07, 0.17, 0.14), "cabeza", rot=(24, -22 * s, 0), cortes=1,
               r=0.3, pal=PLACA, tinte=None, musgo=0.1)
    for s in (-1, 1):
        crear_brazo(s)
        crear_pierna(s)


def crear_brazo(s):
    L = ".L" if s > 0 else ".R"
    bloque("hombro" + L, X((1.08, 0.02, 3.06), s), (0.44, 0.44, 0.40), "hombro" + L, rot=(0, 0, 0), r=0.42, cortes=3,
           musgo=0.6)
    bloque("placa_hombro" + L, X((1.13, 0.02, 3.45), s), (0.56, 0.53, 0.11), "placa_hombro" + L, rot=(0, 16 * s, 0),
           r=0.25, pal=PLACA, tinte=None, musgo=0.12)
    bloque("placa_hombro" + L, X((1.55, 0.02, 3.13), s), (0.12, 0.48, 0.28), "placa_hombro" + L, rot=(0, 12 * s, 0),
           r=0.25, cortes=1, pal=PLACA, tinte=None, musgo=0.1)
    bloque("brazo" + L, X((1.30, 0.02, 2.62), s), (0.29, 0.30, 0.42), "brazo" + L, rot=(0, 4 * s, 0), r=0.36)
    bloque("codo" + L, X((1.37, 0.13, 2.18), s), (0.25, 0.25, 0.22), "antebrazo" + L, r=0.5, cortes=1)
    bloque("antebrazo" + L, X((1.42, -0.04, 1.70), s), (0.36, 0.38, 0.48), "antebrazo" + L, rot=(0, 3 * s, 0),
           r=0.32, cortes=3, ahusado=0.16, tinte=(OCRE, 0.22))
    bloque("placa_antebrazo" + L, X((1.82, -0.05, 1.72), s), (0.10, 0.40, 0.44), "placa_antebrazo" + L,
           rot=(0, -6 * s, 0), r=0.25, pal=PLACA, tinte=None, musgo=0.1)
    bloque("mano" + L, X((1.46, -0.15, 0.95), s), (0.36, 0.37, 0.32), "mano" + L, r=0.36, cortes=3)
    for dx in (-0.22, 0.0, 0.22):                         # nudillos: abajo y delante (la cara que golpea)
        bloque("nudillo" + L, X((1.46 + dx, -0.34, 0.66), s), (0.10, 0.12, 0.09), "mano" + L, cortes=1, r=0.45)
    bloque("pulgar" + L, X((1.16, -0.38, 1.00), s), (0.09, 0.14, 0.16), "mano" + L, rot=(10, 0, 0), cortes=1, r=0.45)


def crear_pierna(s):
    L = ".L" if s > 0 else ".R"
    bloque("muslo" + L, X((0.53, 0.05, 1.36), s), (0.31, 0.31, 0.33), "muslo" + L, r=0.4)
    bloque("rodilla" + L, X((0.56, -0.17, 1.05), s), (0.22, 0.15, 0.20), "pierna" + L, r=0.45, cortes=1)
    bloque("pierna" + L, X((0.57, 0.04, 0.68), s), (0.30, 0.31, 0.37), "pierna" + L, r=0.36, ahusado=0.12)
    bloque("pie" + L, X((0.58, -0.10, 0.17), s), (0.30, 0.42, 0.17), "pie" + L, r=0.3, tinte=(OCRE, 0.2))
    for dx in (-0.19, 0.0, 0.19):
        bloque("dedo" + L, X((0.58 + dx, -0.55, 0.10), s), (0.09, 0.09, 0.10), "pie" + L, cortes=1, r=0.45)


crear_cuerpo()
N_PIEDRA = len(M.caras)

# ---------------------------------------------------------------- runas, grietas y musgo (sobre la superficie)

random.seed(31)
# cinturón: una franja de runas entre dos líneas en la cadera, de lado a lado
AR_CADERA = arbol({"cadera"})
for i, x in enumerate([-0.50, -0.30, -0.10, 0.10, 0.30, 0.50]):
    glifo(AR_CADERA, (x, -0.4, 1.83), (0, -1, 0.0), (0, 0, 1), 0.2, forma=(i * 3) % len(GLIFOS))
for z in (1.70, 1.96):
    linea(AR_CADERA, [(x / 10.0, -0.4, z) for x in range(-6, 7)], (0, -1, 0))
# frente: una runa grande
glifo(arbol({"cabeza"}), (0, -0.6, 3.66), (0, -1, 0.5), (0, 0, 1), 0.13, forma=5, grosor=0.022)
# espalda: columna de runas por el lomo y el pecho
AR_ESPALDA = arbol({"lomo", "pecho"})
for i, z in enumerate([3.24, 3.02]):
    glifo(AR_ESPALDA, (0, 0.6, z), (0, 1, 0.1), (0, 0, 1), 0.2, forma=(i * 5 + 1) % len(GLIFOS))
for s in (-1, 1):
    L = ".L" if s > 0 else ".R"
    # placas de los hombros: tres runas por encima
    ar = arbol({"placa_hombro" + L})
    for k, (x, y) in enumerate([(0.90, -0.22), (1.15, 0.02), (1.38, 0.24)]):
        glifo(ar, (x * s, y, 3.5), (0.28 * s, 0, 1), (0, 1, 0), 0.2, forma=(k * 2 + (0 if s > 0 else 3)) % len(GLIFOS))
    # placas de los antebrazos: tres runas en columna, por fuera
    ar = arbol({"placa_antebrazo" + L})
    for k, z in enumerate([2.0, 1.74, 1.48]):
        glifo(ar, (1.9 * s, -0.05, z), (s, 0, 0), (0, 0, 1), 0.19, forma=(k * 3 + (1 if s > 0 else 4)) % len(GLIFOS))
    # muslos: dos runas delante
    ar = arbol({"muslo" + L})
    for k, z in enumerate([1.50, 1.28]):
        glifo(ar, (0.53 * s, -0.3, z), (0.15 * s, -1, 0), (0, 0, 1), 0.17, forma=(k * 4 + 2) % len(GLIFOS))
    # bajo las placas (solo se ven cuando se abren): runas en lo alto del hombro y por fuera del antebrazo
    ar = arbol({"hombro" + L})
    for k, (x, y) in enumerate([(1.0, -0.15), (1.2, 0.15)]):
        glifo(ar, (x * s, y, 3.4), (0.2 * s, 0, 1), (0, 1, 0), 0.22, forma=(k + 6) % len(GLIFOS), grosor=0.032)
    ar = arbol({"antebrazo" + L})
    for k, z in enumerate([1.95, 1.60]):
        glifo(ar, (1.75 * s, -0.04, z), (s, 0, 0), (0, 0, 1), 0.24, forma=(k + 3) % len(GLIFOS), grosor=0.032)
print("RUNAS", N_GLIFOS[0], "glifos")

# grietas vulnerables: pecho (bajo los pectorales) y espalda (bajo el lomo). La oscura va con el pecho; la luz, con el
# hueso «grietas» (escondida en la fase 1).
AR_PECHO = arbol({"pecho"})
GRIETA_PECHO = grieta(AR_PECHO, (0.06, -0.6, 2.60), (0, -1, 0), (0, 0, 1), 4, "grietas", largo=8, ramas=2, ang0=-80)
GRIETA_ESPALDA = grieta(AR_PECHO, (-0.08, 0.6, 2.66), (0, 1, 0), (0, 0, 1), 9, "grietas", largo=8, ramas=2, ang0=-100)
# grietas de la derrota: por el pecho, los costados y la espalda (todas con su hueso: solo en «derrota»)
AR_TRONCO = arbol({"pecho", "lomo", "pectoral"})
for k, (c, f, ang) in enumerate([((0.45, -0.7, 2.95), (0.2, -1, 0), -60), ((-0.5, -0.7, 3.0), (-0.2, -1, 0), -120),
                                 ((0.85, 0.0, 2.8), (1, 0, 0), -95), ((-0.85, 0.1, 2.75), (-1, 0, 0), -85),
                                 ((0.35, 0.65, 3.05), (0.2, 1, 0.2), -70)]):
    grieta(AR_TRONCO, c, f, (0, 0, 1), 20 + k, "grietas_derrota", hueso_oscura="grietas_derrota", largo=6, ramas=1,
           ancho=0.055, ang0=ang)
print("GRIETAS pecho", tuple(round(x, 3) for x in GRIETA_PECHO), "espalda", tuple(round(x, 3) for x in GRIETA_ESPALDA))

# musgo de estatua (solo «dormido»): matas sobre las placas de los hombros, la cabeza, el lomo y los monolitos
random.seed(41)
AR_ARRIBA = arbol({"placa_hombro.L", "placa_hombro.R", "cabeza", "lomo", "monolito", "ceja"})
for (x, y, r) in [(0.95, -0.15, 0.20), (1.30, 0.20, 0.17), (-0.95, 0.10, 0.20), (-1.28, -0.20, 0.16), (0.05, -0.30, 0.17),
                  (0.0, 0.18, 0.24), (0.42, 0.30, 0.14), (-0.40, 0.32, 0.15), (0.02, 0.36, 0.11)]:
    h = rayo(AR_ARRIBA, (x, y, 6.0), (0, 0, -1))
    if h:
        bulto(h[0] - h[1] * r * 0.15, r, "musgo", escala=(1.3, 1.2, 0.42), subdiv=1, amp=0.25, color=color_musgo,
              semilla=x * 7 + y, grupo="musgo")
for (x, y) in [(0.75, -0.45), (1.65, -0.2), (-0.70, -0.48), (-1.62, 0.25), (0.2, -0.55)]:     # lianas que cuelgan
    h = rayo(AR_ARRIBA, (x, y, 6.0), (0, 0, -1))
    if h:
        p = h[0]
        L = 0.25 + 0.2 * random.random()
        tubo([p, p + Vector((0, -0.03, -L * 0.5)), p + Vector((0.01, -0.02, -L))], [0.035, 0.025, 0.012],
             ["musgo"] * 3, lados=4, amp=0.2, color=lambda q, n: color_musgo(n, q), grupo="musgo")
print("MUSGO listo")


# ---------------------------------------------------------------- piezas del golpe fuerte (alrededor del origen)

def color_roca(q, n):
    return color_piedra(PIEDRA, (OCRE, 0.3), n, q, suave(0.3, 0.9, q.z), 0.0)


random.seed(53)
for i, (ang, dist, alto, inc) in enumerate([(10, 0.42, 0.95, 0.35), (75, 0.48, 0.70, 0.5), (140, 0.40, 0.85, 0.4),
                                            (200, 0.50, 0.62, 0.55), (260, 0.38, 1.05, 0.3), (320, 0.52, 0.75, 0.45)]):
    a = math.radians(ang)
    fuera = Vector((math.cos(a), math.sin(a), 0))
    b = fuera * dist + Vector((0, 0, -0.06))
    pts = [b, b + Vector((0, 0, alto * 0.45)) + fuera * alto * inc * 0.4, b + Vector((0, 0, alto)) + fuera * alto * inc]
    tubo(pts, [0.17, 0.11, 0.03], ["rocas"] * 3, lados=5, amp=0.15, color=color_roca, tapa0=False, grupo="rocas",
         semilla=i)
for (dx, dy) in [(-0.75, -0.2), (0.7, 0.25), (-0.1, 0.8), (0.3, -0.75), (0.0, 0.0)]:
    bloque("escombro", (dx, dy, 0.03), (0.16, 0.13, 0.09), "rocas", rot=(0, 0, dx * 90), cortes=1, r=0.45, amp=0.03,
           tinte=(OCRE, 0.3), musgo=0.0)
for (dx, dy, dz, t) in [(0.0, 0.0, 0.0, 0.2), (0.32, -0.15, 0.18, 0.14), (-0.28, 0.1, 0.12, 0.16),
                        (0.12, 0.3, -0.1, 0.12), (-0.15, -0.3, 0.25, 0.11)]:
    bloque("proyectil", (dx, dy, dz), (t, t * 0.85, t * 0.9), "proyectiles", rot=(dx * 100, dy * 80, 30), cortes=1,
           r=0.5, amp=0.02, tinte=(OCRE, 0.25), musgo=0.0)


# ---------------------------------------------------------------- esqueleto

HUESOS = [
    ("raiz", (0, 0, 0), (0, 0, 0.4), None),
    ("cadera", (0, 0.05, 1.62), (0, 0.04, 2.0), "raiz"),
    ("columna", (0, 0.04, 2.0), (0, 0.0, 2.42), "cadera"),
    ("pecho", (0, 0.0, 2.42), (0, -0.05, 3.3), "columna"),
    ("cabeza", (0, -0.22, 3.18), (0, -0.36, 3.72), "pecho"),
    ("nucleo", (0, -0.30, 2.80), (0, -0.50, 2.80), "pecho"),          # sin malla: su escala es la luz de las runas
    ("grietas", (0, 0.0, 2.80), (0, 0.0, 3.0), "pecho"),
    ("grietas_derrota", (0, 0.0, 2.85), (0, 0.0, 3.05), "pecho"),
    ("musgo", (0, 0.05, 3.15), (0, 0.05, 3.35), "pecho"),
    ("rocas", (0, 0, 0), (0, 0, 0.3), None),                        # en el suelo, sin padre: no bajan con la raíz
    ("proyectiles", (0, 0, 0), (0, 0, 0.3), None),
]
for s, L in ((1, ".L"), (-1, ".R")):
    HUESOS += [
        ("hombro" + L, X((0.45, 0.0, 3.05), s), X((1.05, 0.0, 3.08), s), "pecho"),
        ("placa_hombro" + L, X((1.12, 0.02, 3.32), s), X((1.12, 0.02, 3.62), s), "hombro" + L),
        ("brazo" + L, X((1.22, 0.0, 2.98), s), X((1.36, 0.04, 2.18), s), "hombro" + L),
        ("antebrazo" + L, X((1.36, 0.04, 2.18), s), X((1.44, -0.10, 1.22), s), "brazo" + L),
        ("placa_antebrazo" + L, X((1.76, -0.05, 1.72), s), X((1.76, -0.05, 2.02), s), "antebrazo" + L),
        ("mano" + L, X((1.44, -0.10, 1.22), s), X((1.47, -0.22, 0.62), s), "antebrazo" + L),
        ("muslo" + L, X((0.50, 0.05, 1.66), s), X((0.56, 0.03, 1.06), s), "cadera"),
        ("pierna" + L, X((0.56, 0.03, 1.06), s), X((0.58, 0.04, 0.34), s), "muslo" + L),
        ("pie" + L, X((0.58, 0.04, 0.34), s), X((0.58, -0.40, 0.12), s), "pierna" + L),
    ]
NOMBRES = [h[0] for h in HUESOS]

arm_data = bpy.data.armatures.new("Coloso_esqueleto")
arm = bpy.data.objects.new("Coloso", arm_data)
sc.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm
arm.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for (n, h, t, p) in HUESOS:
    eb = arm_data.edit_bones.new(n)
    eb.head, eb.tail = Vector(h), Vector(t)
    eb.roll = 0.0
    eb.use_connect = False
    if p:
        eb.parent = arm_data.edit_bones[p]
    eb.use_deform = True
bpy.ops.object.mode_set(mode='OBJECT')
REPOSO_ROT = {b.name: b.matrix_local.to_quaternion() for b in arm_data.bones}

# ---------------------------------------------------------------- la malla en Blender

me = bpy.data.meshes.new("Coloso_malla")
me.from_pydata([tuple(v) for v in M.v], [], M.caras)
me.update()
bm = bmesh.new()
bm.from_mesh(me)
bm.faces.ensure_lookup_table()
bmesh.ops.recalc_face_normals(bm, faces=[bm.faces[i] for i, c in enumerate(M.cerradas) if c])
bm.to_mesh(me)
bm.free()
me.polygons.foreach_set("material_index", M.mats)
attr = me.color_attributes.new("Color", 'FLOAT_COLOR', 'POINT')
cols = []
for c in M.col:
    cols += list(c) + [1.0]          # en sRGB, sin pasar a lineal: ver la nota de los colores de vértice
attr.data.foreach_set("color", cols)
me.color_attributes.active_color = attr
me.shade_smooth()
me.set_sharp_from_angle(angle=math.radians(34))      # piedra tallada: aristas vivas, caras suaves

cuerpo = bpy.data.objects.new("Cuerpo", me)
sc.collection.objects.link(cuerpo)
cuerpo.parent = arm
for n in NOMBRES:
    cuerpo.vertex_groups.new(name=n)
for i, w in enumerate(M.pesos):
    for h, p in w.items():
        cuerpo.vertex_groups[h].add([i], p, 'REPLACE')
mod = cuerpo.modifiers.new("Esqueleto", 'ARMATURE')
mod.object = arm


def material_piedra():
    m = bpy.data.materials.new("piedra")
    m.use_backface_culling = True
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    ca = nt.nodes.new("ShaderNodeVertexColor")
    ca.layer_name = "Color"
    gam = nt.nodes.new("ShaderNodeGamma")         # solo para ver el color bien en Blender (el atributo va en sRGB)
    gam.inputs["Gamma"].default_value = 2.2
    nt.links.new(ca.outputs["Color"], gam.inputs["Color"])
    nt.links.new(gam.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.9
    bsdf.inputs["Metallic"].default_value = 0.0
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.2
    return m


def material_runas():
    m = bpy.data.materials.new("runas")
    m.use_backface_culling = True
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*lineal(RUNA), 1.0)
    bsdf.inputs["Roughness"].default_value = 0.5
    bsdf.inputs["Emission Color"].default_value = (*lineal(AMBAR), 1.0)
    bsdf.inputs["Emission Strength"].default_value = 1.0
    return m


me.materials.append(material_piedra())
me.materials.append(material_runas())

TRIS = sum(len(f) - 2 for f in M.caras)
print("MALLA vértices", len(M.v), "caras", len(M.caras), "triángulos", TRIS, "huesos", len(NOMBRES))


def indices(huesos):
    return np.array([i for i, w in enumerate(M.pesos) if max(w, key=w.get) in huesos], dtype=np.int64)


PIERNAS = indices({h + s for h in ("muslo", "pierna", "pie") for s in (".L", ".R")})
PUNOS = {s: indices({"mano" + s}) for s in (".L", ".R")}
OCULTAS = {"musgo", "rocas", "proyectiles", "grietas", "grietas_derrota"}
VISIBLE = np.array([i for i, w in enumerate(M.pesos) if not (set(w) & OCULTAS)], dtype=np.int64)


# ---------------------------------------------------------------- poses

EJES = {"X": Vector((1, 0, 0)), "Y": Vector((0, 1, 0)), "Z": Vector((0, 0, 1))}
OCULTO = 0.01
ESCALA_BASE = {"nucleo": 1.0, "grietas": 1.0, "grietas_derrota": OCULTO, "musgo": OCULTO, "rocas": OCULTO,
               "proyectiles": OCULTO}


class Pose:
    def __init__(self):
        self.rot = {}
        self.esc = dict(ESCALA_BASE)
        self.loc = {}
        self.desp = (0.0, 0.0)
        self.alto = 0.0
        self.apoyos = {}        # {".R": altura}: el giro X del brazo se busca para que el puño quede a esa altura

    def r(self, hueso, *giros):
        self.rot.setdefault(hueso, []).extend(giros)
        return self

    def par(self, hueso, *giros):
        self.r(hueso + ".L", *giros)
        self.r(hueso + ".R", *[(e, g if e == "X" else -g) for e, g in giros])
        return self

    def e(self, hueso, valor):
        self.esc[hueso] = valor
        return self

    def l(self, hueso, v):
        self.loc[hueso] = Vector(v)
        return self

    def parl(self, hueso, v):
        self.l(hueso + ".L", v)
        self.l(hueso + ".R", (-v[0], v[1], v[2]))
        return self

    def placas(self, k):
        """Placas separadas (k = 1: la pose abierta de la fase 2; 0: cerradas)."""
        if k <= 0:
            return self
        self.parl("placa_hombro", (0.14 * k, 0.0, 0.34 * k)).par("placa_hombro", ("Y", 18 * k))
        self.parl("placa_antebrazo", (0.26 * k, 0.0, 0.05 * k)).par("placa_antebrazo", ("Y", 14 * k))
        return self

    def copia(self):
        p = Pose()
        p.rot = {k: list(v) for k, v in self.rot.items()}
        p.esc = dict(self.esc)
        p.loc = dict(self.loc)
        p.desp, p.alto, p.apoyos = self.desp, self.alto, dict(self.apoyos)
        return p


def cuaternion(hueso, giros):
    r = REPOSO_ROT[hueso]
    q = Quaternion()
    for e, g in giros:
        q = (r.inverted() @ Quaternion(EJES[e], math.radians(g)) @ r) @ q
    return q


def poner(pose, extra=None):
    for pb in arm.pose.bones:
        pb.rotation_mode = 'QUATERNION'
        giros = pose.rot.get(pb.name, []) + (extra or {}).get(pb.name, [])
        pb.rotation_quaternion = cuaternion(pb.name, giros)
        v = pose.loc.get(pb.name)
        pb.location = (REPOSO_ROT[pb.name].inverted() @ v) if v is not None else Vector((0, 0, 0))
        s = pose.esc.get(pb.name, 1.0)
        pb.scale = (s, s, s)


def coordenadas():
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    ob = cuerpo.evaluated_get(dg)
    m = ob.to_mesh()
    a = np.empty(len(m.vertices) * 3, dtype=np.float32)
    m.vertices.foreach_get("co", a)
    ob.to_mesh_clear()
    return a.reshape(-1, 3)


def resolver(pose):
    """Giros finales de la pose (con el ajuste de los apoyos) y la posición de la raíz que apoya las piernas."""
    extra = {}
    for s, altura in pose.apoyos.items():
        mejor = None
        base = [g for e, g in pose.rot.get("brazo" + s, []) if e == "X"]
        for d in range(-70, 72, 2):
            prueba = dict(extra)
            prueba["brazo" + s] = [("X", d)]
            poner(pose, prueba)
            co = coordenadas()
            suelo = co[PIERNAS][:, 2].min()
            alto_p = co[PUNOS[s]][:, 2].min() - suelo
            err = abs(alto_p - altura)
            if mejor is None or err < mejor[0]:
                mejor = (err, d, alto_p)
        extra["brazo" + s] = [("X", mejor[1])]
        print("   apoyo", s, "ajuste %+d°" % mejor[1], "puño a %.3f" % mejor[2], "(giro base", base, ")")
    poner(pose, extra)
    co = coordenadas()
    z = -float(co[PIERNAS][:, 2].min()) + pose.alto
    return extra, Vector((pose.desp[0], pose.desp[1], z))


def punto_puno(pose, s=".R"):
    """Dónde toca el suelo el puño (centro de lo más bajo del puño), con la raíz ya apoyada."""
    extra, raiz = resolver(pose)
    poner(pose, extra)
    co = coordenadas() + np.array(raiz)
    p = co[PUNOS[s]]
    bajo = p[p[:, 2] < p[:, 2].min() + 0.12]
    return Vector((float(bajo[:, 0].mean()), float(bajo[:, 1].mean()), 0.0))


def reposo(resp=0.0, mece=0.0):
    p = Pose()
    p.r("cadera", ("Z", 2.0 * mece))
    p.r("columna", ("X", 5), ("Y", 1.0 * mece))
    p.r("pecho", ("X", 9 - 2.5 * resp), ("Z", 1.5 * mece))
    p.r("cabeza", ("X", -12 + 2 * resp), ("Z", -2.0 * mece))
    p.par("hombro", ("Y", -2.5 * resp))
    p.par("brazo", ("X", -6), ("Y", -3 - 1.0 * resp))
    p.par("antebrazo", ("X", -16 - 3 * resp))
    p.par("mano", ("X", -6 - 2 * resp))
    p.par("muslo", ("X", -10))
    p.par("pierna", ("X", 18))
    p.par("pie", ("X", -8))
    p.e("nucleo", 1.0 + 0.08 * resp)
    return p


def carga(lat=0.0):
    """La carga: echa el brazo derecho atrás, gira el tronco y las runas laten."""
    p = Pose()
    p.r("cadera", ("Z", -6))
    p.r("columna", ("X", 6), ("Z", -9))
    p.r("pecho", ("X", 6 + 2 * lat), ("Z", -20 - 2 * lat))
    p.r("cabeza", ("X", -14), ("Z", 24))
    p.r("hombro.R", ("Y", 8 + 2 * lat))
    p.r("brazo.R", ("X", 50 + 4 * lat), ("Y", 10))
    p.r("antebrazo.R", ("X", -34))
    p.r("mano.R", ("X", -10))
    p.r("brazo.L", ("X", -30), ("Y", 14))
    p.r("antebrazo.L", ("X", -62))
    p.r("mano.L", ("X", -12))
    p.par("muslo", ("X", -16))
    p.par("pierna", ("X", 28))
    p.par("pie", ("X", -12))
    p.e("nucleo", 1.0 + 0.4 * lat)
    return p


def rodillas(s=1.0):
    """De rodillas: muslos casi verticales, espinillas en el suelo, los puños apoyados, el cuerpo vencido."""
    p = Pose()
    p.r("columna", ("X", 14 + 8 * s))
    p.r("pecho", ("X", 16 + 10 * s), ("Z", -4 * s))
    p.r("cabeza", ("X", 16 + 10 * s), ("Z", 6 * s))
    p.par("hombro", ("Y", 4))
    p.par("brazo", ("Y", -6))
    p.par("antebrazo", ("X", -12))
    p.par("mano", ("X", -4))
    p.par("muslo", ("X", -8))
    p.par("pierna", ("X", 92))
    p.par("pie", ("X", 62))
    p.apoyos = {".R": 0.0, ".L": 0.04}
    return p


def estatua(nucleo):
    """Dormido: de pie, erguido e inmóvil como una estatua; las runas casi apagadas y musgo encima."""
    p = Pose()
    p.r("columna", ("X", 2))
    p.r("pecho", ("X", 4))
    p.par("brazo", ("X", -3), ("Y", -2))
    p.par("antebrazo", ("X", -5))
    p.par("muslo", ("X", -2))
    p.par("pierna", ("X", 3))
    p.par("pie", ("X", -1))
    p.e("nucleo", nucleo).e("grietas", OCULTO).e("musgo", 1.0)
    return p


# ---------------------------------------------------------------- clips: [(fotograma, pose)]

def clip_reposo():
    return [(1, reposo(0, 0)), (22, reposo(0.5, 1)), (43, reposo(1, 0)), (64, reposo(0.5, -1)), (85, reposo(0, 0))]


def clip_ataque():
    # puñetazo con el brazo derecho (el que queda hacia la cámara del combate), hacia abajo y delante, a la altura de
    # un héroe. IMPACTO: fotograma 19 (0,6 s)
    tira = reposo().r("columna", ("Z", -8)).r("pecho", ("X", -2), ("Z", -20)).r("cabeza", ("Z", 18))
    tira.rot["brazo.R"] = [("X", 42), ("Y", 14)]
    tira.rot["antebrazo.R"] = [("X", -60)]
    tira.rot["brazo.L"] = [("X", -30), ("Y", 10)]
    tira.rot["antebrazo.L"] = [("X", -40)]
    tira.e("nucleo", 1.12)
    medio = reposo().r("columna", ("X", 4), ("Z", 0)).r("pecho", ("X", 6), ("Z", 2)).r("cabeza", ("Z", 4))
    medio.rot["brazo.R"] = [("X", -38), ("Y", 4)]
    medio.rot["antebrazo.R"] = [("X", -58)]
    medio.rot["brazo.L"] = [("X", 0), ("Y", -4)]
    golpe = reposo().r("columna", ("X", 8), ("Z", 4)).r("pecho", ("X", 10), ("Z", 10)).r("cabeza", ("X", -4), ("Z", -12))
    golpe.rot["brazo.R"] = [("X", -66), ("Z", 4)]
    golpe.rot["antebrazo.R"] = [("X", -4)]
    golpe.rot["mano.R"] = [("X", 4)]
    golpe.rot["brazo.L"] = [("X", 28), ("Y", -10)]
    golpe.rot["antebrazo.L"] = [("X", -40)]
    golpe.par("muslo", ("X", -16)).par("pierna", ("X", 26)).par("pie", ("X", -10))
    golpe.e("nucleo", 1.15)
    sigue = reposo().r("columna", ("X", 9), ("Z", 3)).r("pecho", ("X", 11), ("Z", 8)).r("cabeza", ("X", -6), ("Z", -9))
    sigue.rot["brazo.R"] = [("X", -60), ("Z", 4)]
    sigue.rot["antebrazo.R"] = [("X", -8)]
    sigue.rot["mano.R"] = [("X", 0)]
    sigue.rot["brazo.L"] = [("X", 20), ("Y", -8)]
    sigue.rot["antebrazo.L"] = [("X", -34)]
    sigue.par("muslo", ("X", -14)).par("pierna", ("X", 24)).par("pie", ("X", -9))
    return [(1, reposo()), (11, tira), (16, medio), (19, golpe), (26, sigue), (46, reposo())]


def clip_carga():
    return [(1, carga(0)), (6, carga(1)), (11, carga(0.3)), (16, carga(0.8)), (25, carga(0)), (37, carga(0))]


def clip_golpe_fuerte():
    # desde la carga, el brazo da la vuelta por detrás y por encima de la cabeza y el puño cae al suelo delante: brotan
    # lascas y salen rocas despedidas. IMPACTO: fotograma 21 (0,667 s)
    alza = carga(0.5)
    alza.rot["brazo.R"] = [("X", 128), ("Y", 18)]
    alza.rot["antebrazo.R"] = [("X", -20)]
    alza.r("pecho", ("X", -14))
    alza.e("nucleo", 1.3)
    alto = Pose()
    alto.r("columna", ("X", -8), ("Z", -4)).r("pecho", ("X", -12), ("Z", -8)).r("cabeza", ("X", -10), ("Z", 8))
    alto.r("hombro.R", ("Y", 14))
    alto.r("brazo.R", ("X", -170), ("Y", 12)).r("antebrazo.R", ("X", -58)).r("mano.R", ("X", -16))
    alto.r("brazo.L", ("X", -42), ("Y", -8)).r("antebrazo.L", ("X", -50))
    alto.par("muslo", ("X", -6)).par("pierna", ("X", 10)).par("pie", ("X", -4))
    alto.e("nucleo", 1.45)

    INCLINA = 40

    def abajo(k, inclina, brazo=30):
        """Agachado sobre el golpe, las piernas muy dobladas: el tronco se inclina «inclina» grados y el brazo derecho
        apunta «brazo» grados por delante de la vertical (en el mundo: su giro propio descuenta la inclinación)."""
        p = Pose()
        p.r("columna", ("X", inclina * 0.4), ("Z", 4)).r("pecho", ("X", inclina * 0.6), ("Z", 10))
        p.r("cabeza", ("X", -inclina * 0.6), ("Z", -6))
        p.r("hombro.R", ("Y", -6))
        p.r("brazo.R", ("X", -brazo - inclina), ("Z", 6)).r("antebrazo.R", ("X", -4)).r("mano.R", ("X", 4))
        p.r("brazo.L", ("X", 34 - inclina * 0.3), ("Y", -20)).r("antebrazo.L", ("X", -36))
        p.par("muslo", ("X", -70 - 4 * k)).par("pierna", ("X", 100 + 4 * k)).par("pie", ("X", -30))
        p.r("muslo.L", ("X", -6)).r("pierna.L", ("X", 6))
        p.e("nucleo", 1.25 + 0.1 * k)
        return p

    # el ángulo del brazo que lleva el puño justo al suelo (búsqueda, como los apoyos)
    mejor = None
    for brazo in range(0, 72, 2):
        p = abajo(1, INCLINA, brazo)
        extra, raiz = resolver(p)
        poner(p, extra)
        co = coordenadas()
        h = co[PUNOS[".R"]][:, 2].min() - co[PIERNAS][:, 2].min()
        if mejor is None or abs(h) < mejor[0]:
            mejor = (abs(h), brazo, h)
    BRAZO = mejor[1]
    print("   golpe: brazo %d° por delante de la vertical, puño a %.3f del suelo" % (BRAZO, mejor[2]))
    baja = alto.copia()
    baja.rot["brazo.R"] = [("X", -110), ("Z", 4)]
    baja.rot["antebrazo.R"] = [("X", -20)]
    baja.r("columna", ("X", 18)).r("pecho", ("X", 22), ("Z", 14))
    impacto = abajo(1, INCLINA, BRAZO)
    P = punto_puno(impacto)
    print("   el puño toca el suelo en", tuple(round(x, 3) for x in P))
    CLIP_DATOS["rocas"] = P

    def con_rocas(p, rocas, vuelo, giro, esc_p):
        p = p.copia()
        p.l("rocas", P).e("rocas", rocas)
        p.l("proyectiles", P + Vector(vuelo)).e("proyectiles", esc_p).r("proyectiles", ("X", giro), ("Z", giro * 0.4))
        return p
    sigue = abajo(0.8, INCLINA, BRAZO)
    sigue.r("brazo.R", ("X", 1.5))
    sube = abajo(0.3, INCLINA * 0.6, 20)
    sube.par("muslo", ("X", 30)).par("pierna", ("X", -44))
    return [(1, carga(0)), (7, alza), (12, alto), (18, con_rocas(baja, OCULTO, (0, 0, 0.2), 0, OCULTO)),
            (21, con_rocas(impacto, 0.7, (0, 0, 0.25), 0, OCULTO)),
            (24, con_rocas(impacto, 1.15, (0, -0.25, 1.0), 70, 1.0)),
            (28, con_rocas(sigue, 1.0, (0, -0.65, 1.55), 150, 1.05)),
            (32, con_rocas(sigue, 1.0, (0, -1.0, 1.25), 230, 1.0)),
            (38, con_rocas(sube, 0.9, (0, -1.3, 0.2), 310, 0.8)),
            (46, con_rocas(sube, OCULTO, (0, -1.35, 0.1), 340, OCULTO)),
            (63, reposo())]


def clip_herido():
    golpe = reposo().r("columna", ("X", -8)).r("pecho", ("X", -12), ("Z", 7)).r("cabeza", ("X", -14), ("Z", 10))
    golpe.par("brazo", ("X", 16), ("Y", -10)).par("antebrazo", ("X", 6))
    golpe.e("nucleo", 0.86)
    rebote = reposo().r("columna", ("X", -2)).r("pecho", ("X", -4), ("Z", 2)).r("cabeza", ("X", -5), ("Z", 3))
    return [(1, reposo()), (4, golpe), (10, rebote), (24, reposo())]


def clip_fase2():
    def recogido(k, nucleo, temblor=0.0):
        p = Pose()
        p.r("columna", ("X", 12 + 8 * k)).r("pecho", ("X", 14 + 10 * k), ("Z", temblor)).r("cabeza", ("X", 14 + 6 * k))
        p.par("hombro", ("Y", 6 * k))
        p.par("brazo", ("X", -36 - 6 * k), ("Y", 22 + 6 * k)).par("antebrazo", ("X", -100 - 10 * k)).par("mano", ("X", -14))
        p.par("muslo", ("X", -22 - 8 * k)).par("pierna", ("X", 36 + 12 * k)).par("pie", ("X", -14 - 4 * k))
        p.e("nucleo", nucleo).e("grietas", OCULTO)
        return p

    def erguido(k, placas, nucleo, grietas=1.0):
        p = Pose()
        p.r("columna", ("X", -10 * k)).r("pecho", ("X", -14 * k)).r("cabeza", ("X", -24 * k))
        p.par("hombro", ("Y", -12 * k))
        p.par("brazo", ("Y", -16 * k), ("X", -22 * k)).par("antebrazo", ("X", -22 * k)).par("mano", ("X", -10 * k))
        p.par("muslo", ("X", -6)).par("pierna", ("X", 10)).par("pie", ("X", -4))
        p.placas(placas).e("nucleo", nucleo).e("grietas", grietas)
        return p
    return [(1, reposo().e("grietas", OCULTO)), (14, recogido(0.6, 1.25)), (24, recogido(1.0, 1.5, 2.5)),
            (28, recogido(1.0, 1.55, -2.5)), (32, erguido(1.0, 1.45, 1.65)), (38, erguido(1.0, 1.0, 1.45)),
            (46, erguido(0.6, 1.0, 1.25)), (78, reposo().placas(1.0))]


def clip_derrota():
    golpe = reposo().r("columna", ("X", -8)).r("pecho", ("X", -12)).r("cabeza", ("X", -16), ("Z", 6))
    golpe.par("brazo", ("X", 12), ("Y", -8)).e("nucleo", 1.2)
    agrieta = golpe.copia().r("pecho", ("Z", -4)).e("grietas_derrota", 1.0).e("nucleo", 1.65)
    tiembla = golpe.copia().r("pecho", ("Z", 4), ("X", 4)).e("grietas_derrota", 1.0).e("nucleo", 1.4)
    cede = Pose()
    cede.r("columna", ("X", 12)).r("pecho", ("X", 16)).r("cabeza", ("X", 20), ("Z", 5))
    cede.par("brazo", ("X", 4), ("Y", -5)).par("antebrazo", ("X", -6))
    cede.par("muslo", ("X", -34)).par("pierna", ("X", 60)).par("pie", ("X", -24))
    cede.e("grietas_derrota", 1.0).e("nucleo", 1.0)
    cae = rodillas(0.4).e("grietas_derrota", 1.0).e("nucleo", 0.8)
    queda = rodillas(1.0).e("grietas_derrota", 1.0).e("nucleo", 0.6)
    # la placa del hombro izquierdo se suelta y queda torcida
    cae.l("placa_hombro.L", (0.08, 0.0, -0.10)).r("placa_hombro.L", ("Y", 22))
    queda.l("placa_hombro.L", (0.16, -0.04, -0.26)).r("placa_hombro.L", ("Y", 38), ("X", -8))
    fin = queda.copia()
    return [(1, reposo()), (5, golpe), (10, agrieta), (18, tiembla), (28, cede), (40, cae), (56, queda), (76, fin)]


def clip_dormido():
    return [(1, estatua(0.66)), (46, estatua(0.70)), (91, estatua(0.66))]


CLIP_DATOS = {}
CLIPS = {
    "reposo": clip_reposo(),
    "ataque": clip_ataque(),
    "carga": clip_carga(),
    "golpe_fuerte": clip_golpe_fuerte(),
    "herido": clip_herido(),
    "fase2": clip_fase2(),
    "derrota": clip_derrota(),
    "dormido": clip_dormido(),
}


# ---------------------------------------------------------------- acciones

def curvas(accion):
    res = []
    for capa in accion.layers:
        for tira in capa.strips:
            for bolsa in tira.channelbags:
                res += list(bolsa.fcurves)
    return res


arm.animation_data_create()
ad = arm.animation_data
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')
MEDIDAS = {}


def crear_accion(nombre, claves):
    print("CLIP", nombre)
    resueltas = []
    for f, pose in claves:
        extra, raiz = resolver(pose)
        resueltas.append((f, pose, extra, raiz))
    act = bpy.data.actions.new(nombre)
    act.use_fake_user = True
    ad.action = act
    previo = {}
    for f, pose, extra, raiz in resueltas:
        poner(pose, extra)
        for pb in arm.pose.bones:
            q = pb.rotation_quaternion.copy()
            if pb.name in previo and previo[pb.name].dot(q) < 0:
                q.negate()
            previo[pb.name] = q
            pb.rotation_quaternion = q
            if pb.name == "raiz":
                pb.location = REPOSO_ROT["raiz"].inverted() @ raiz
            pb.keyframe_insert("rotation_quaternion", frame=f, group=pb.name)
            pb.keyframe_insert("location", frame=f, group=pb.name)
            pb.keyframe_insert("scale", frame=f, group=pb.name)
        co = coordenadas() + np.array(raiz)
        vis = co[VISIBLE]
        print("   f%-3d raiz z %.3f  alto %.2f  delante %.2f  ancho %.2f" % (
            f, raiz.z, vis[:, 2].max(), -vis[:, 1].min(), vis[:, 0].max() - vis[:, 0].min()))
        MEDIDAS[(nombre, f)] = (float(vis[:, 2].max()), float(-vis[:, 1].min()))
    for fc in curvas(act):
        for k in fc.keyframe_points:
            k.interpolation = 'BEZIER'
            k.handle_left_type = k.handle_right_type = 'AUTO_CLAMPED'
        fc.update()
    ad.action = None
    pista = ad.nla_tracks.new()
    pista.name = nombre
    pista.strips.new(nombre, int(claves[0][0]), act)
    pista.mute = True
    return act


for nombre, claves in CLIPS.items():
    crear_accion(nombre, claves)

ad.action = None
poner(reposo())
bpy.ops.object.mode_set(mode='OBJECT')
for t in ad.nla_tracks:
    t.mute = False

print("RESUMEN triángulos", TRIS, "huesos", len(NOMBRES), "glifos", N_GLIFOS[0],
      "alto en reposo %.2f" % MEDIDAS[("reposo", 1)][0], "rocas en", tuple(round(x, 3) for x in CLIP_DATOS["rocas"]))

if SALIDA_BLEND:
    bpy.ops.wm.save_as_mainfile(filepath=SALIDA_BLEND)
    print("GUARDADO", SALIDA_BLEND)

if SALIDA_GLB:
    bpy.ops.export_scene.gltf(
        filepath=SALIDA_GLB, export_format='GLB', use_selection=False,
        export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=True,
        export_anim_slide_to_zero=True, export_def_bones=False, export_reset_pose_bones=True,
        export_optimize_animation_size=False, export_skins=True, export_yup=True,
        export_vertex_color='ACTIVE', export_cameras=False, export_lights=False)
    print("EXPORTADO", SALIDA_GLB)
