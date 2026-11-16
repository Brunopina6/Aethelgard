# KIT del barrio experimental de Oakhaven (V12, 16/11, agente A; EN PRUEBAS: solo desde el banco de Auditoría).
# COPIA REFACTORIZADA del kit de zonas3d/muestra_calle/fuente/crear_calle.py (la muestra aprobada), que NO se toca: aquel
# guion llama a main() al final sin guarda y no se puede importar. Cada bloque de abajo dice de qué líneas sale; el
# acabado (arquitectura, colores, texturas, luz horneada, sol y cielo) es EXACTAMENTE el de la muestra.
#
# Lo que cambia respecto a la muestra (para hornear un barrio por sectores):
#   - Sector{nombre, semilla, rnd, anclas, choques}: el azar es POR SECTOR (usar(sector)); rehacer un tramo no mueve las
#     losas, tejas ni matas de los demás. Las anclas y los choques también son del sector (con prefijo).
#   - marco(origen, giro): un marco local para construir una fachada que mira al este o al oeste con las mismas piezas
#     que miran al sur (las de la muestra solo miraban al sur o de lado): las caras, las anclas y los choques se giran.
#   - hiedra(…, y0): la base ya no es el suelo 0 (el barrio sube de 0 a 1,4 m).
#   - recortar(M, otra, cams): las cámaras se pasan (las del barrio salen de sus zonas de cámara, crear_barrio.py).
#   - sondas(bvh, rect, altura): un rectángulo y la altura del suelo por parámetro; se guardan en PNG (R = sol, G = cielo).
#   - preparar_cycles(anclas): las luces de los faroles salen de las anclas de TODOS los sectores (se hornea cada sector
#     con los demás en la escena: sus faroles también alumbran el borde).
#   - hornear(ob, objs_vertice): un objeto fijo por sector, en la imagen activa de los materiales (nodo «LUZ»).
#   - escala_y_guardar(img, carpeta, objs, escala, nombre): la ESCALA de la luz es COMÚN (la de la muestra, fija): sin
#     saltos de brillo entre sectores ni con la calle aprobada.
#   - cargar_texturas(carpeta): las MISMAS texturas de la muestra (zonas3d/muestra_calle/texturas), sin repintarlas.
import bpy, bmesh, sys, os, math, random, json, time, zlib, struct
from contextlib import contextmanager
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree
import numpy as np

T0 = time.time()
MUESTRAS = 256


def nota(t):
    print("[barrio %6.1f s] %s" % (time.time() - T0, t), flush=True)


# ---------------------------------------------------------------- contexto: el sector en obra (azar, anclas, choques)

class Sector:
    def __init__(self, nombre, semilla):
        self.nombre = nombre
        self.semilla = semilla
        self.rnd = random.Random(semilla)
        self.anclas = {}          # nombre → (x, y, z) Godot
        self.choques = []         # (centro, tamaño, giro en grados, nombre)


RND = random.Random(0)
ANCLAS = {}
CHOQUES = []
SECTOR = None
XF = None                         # (origen Vector, giro Matrix 3×3) del marco local en uso, o None


def usar(sector):
    """Todo lo que se construya a partir de aquí es de «sector»: su azar, sus anclas y sus choques."""
    global RND, ANCLAS, CHOQUES, SECTOR
    SECTOR = sector
    RND = sector.rnd
    ANCLAS = sector.anclas
    CHOQUES = sector.choques


class MallaMarco:
    """Una malla vista desde un marco local: las caras se giran y se trasladan al mundo al añadirlas."""
    def __init__(self, base, o, r):
        self.base, self.o, self.r = base, o, r

    def cara(self, pts, mat, col, uvs=None, suave=False):
        self.base.cara([self.o + self.r @ Vector(p) for p in pts], mat, col, uvs, suave)


@contextmanager
def marco(origen, giro):
    """with marco((x, y, z), 90) as F: casa(F(M), …) — construye en un marco local cuyo +z (el «sur» de las piezas de la
    muestra) mira hacia el giro (0 = sur, 90 = este, −90 = oeste, 180 = norte). Las anclas y los choques también se
    giran."""
    global XF
    antes = XF
    o, r = Vector(origen), Matrix.Rotation(math.radians(giro), 3, 'Y')
    XF = (o, r, giro)
    try:
        yield lambda M: MallaMarco(M, o, r)
    finally:
        XF = antes


def al_mundo(p):
    return tuple(XF[0] + XF[1] @ Vector(p)) if XF is not None else tuple(p)


# ======== (de crear_calle.py, l. 77-90: luz)
# ---------------------------------------------------------------- luz (la del horneado; Kael se ilumina igual)
SOL_ELEVACION = 24.0                        # grados: la última luz de la tarde
SOL_RUMBO = 252.0                           # desde el oeste-suroeste (0 = norte, 90 = este)
SOL_COLOR = (1.0, 0.80, 0.58)               # lineal
SOL_FUERZA = 6.5
SOL_ANGULO = 1.2                            # grados: el borde de las sombras
CIELO_COLOR = (0.48, 0.58, 0.86)            # lineal: la sombra, fría
CIELO_FUERZA = 0.6


def hacia_sol():
    e, r = math.radians(SOL_ELEVACION), math.radians(SOL_RUMBO)
    return Vector((math.sin(r) * math.cos(e), math.sin(e), -math.cos(r) * math.cos(e))).normalized()



# ======== (de crear_calle.py, l. 130-178: colores)
# ---------------------------------------------------------------- colores (sRGB; se pasan a lineal al guardar)
REVOQUE_A = (0.96, 0.88, 0.72)      # casa de la puerta: crema cálida
REVOQUE_B = (0.93, 0.78, 0.62)      # casa de la esquina: ocre rosado
REVOQUE_C = (0.86, 0.84, 0.76)
MADERA_OSC = (0.42, 0.28, 0.20)
MADERA = (0.58, 0.42, 0.30)
MADERA_GRIS = (0.62, 0.58, 0.52)
VERDE_PUERTA = (0.26, 0.46, 0.38)
AZUL_POSTIGO = (0.30, 0.52, 0.62)
ROJO_POSTIGO = (0.66, 0.30, 0.22)
TEJA = ((0.76, 0.43, 0.31), (0.79, 0.46, 0.33), (0.73, 0.41, 0.30), (0.77, 0.47, 0.35))
PIZARRA = ((0.42, 0.46, 0.56), (0.50, 0.54, 0.62), (0.38, 0.42, 0.52))
MUSGO = (0.48, 0.56, 0.30)
PIEDRA = ((0.66, 0.63, 0.58), (0.60, 0.58, 0.55), (0.71, 0.67, 0.61), (0.56, 0.53, 0.50))
SILLAR = (0.88, 0.82, 0.72)
TIERRA = (0.66, 0.56, 0.44)
HIERRO = (0.20, 0.19, 0.20)
LATON = (0.86, 0.66, 0.34)
BARRO = (0.86, 0.52, 0.36)
CRISTAL = (0.16, 0.20, 0.26)
LUZ_FAROL = (1.0, 0.72, 0.36)
LUZ_VENTANA = (1.0, 0.80, 0.56)
HOJA = ((0.34, 0.52, 0.22), (0.42, 0.60, 0.26), (0.28, 0.44, 0.20), (0.50, 0.64, 0.30))
HIERBA = ((0.48, 0.62, 0.26), (0.56, 0.68, 0.30), (0.42, 0.56, 0.24), (0.64, 0.70, 0.36))
FLORES = [(0.94, 0.30, 0.30), (0.98, 0.84, 0.36), (0.96, 0.94, 0.90), (0.72, 0.52, 0.90), (0.98, 0.56, 0.70)]
TELAS = [(0.92, 0.90, 0.84), (0.52, 0.66, 0.80), (0.86, 0.42, 0.34), (0.94, 0.82, 0.52), (0.62, 0.74, 0.56)]


def lin(c, a=1.0):
    f = lambda x: x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4
    return (f(c[0]), f(c[1]), f(c[2]), a)


def jit(c, a=0.07):
    k = 1 + RND.uniform(-a, a)
    return tuple(max(0.0, min(1.0, x * k * (1 + RND.uniform(-a, a) * 0.3))) for x in c)


def mezcla(a, b, t):
    return tuple(a[k] * (1 - t) + b[k] * t for k in range(3))


def elige(p):
    return p[RND.randrange(len(p))]


MATS = ["piedra", "tierra", "revoque", "madera", "tejas", "sillar", "hierro", "tela", "barro", "hoja", "brillo"]
ESCALA_UV = {"piedra": 0.9, "tierra": 2.4, "revoque": 2.2, "madera": 1.3, "tejas": 1.0, "sillar": 1.6, "hierro": 1.0,
             "tela": 0.7, "barro": 0.8, "hoja": 0.45, "brillo": 1.0}


# ======== (de crear_calle.py, l. 181-334: malla)
# ---------------------------------------------------------------- constructor de mallas (coordenadas de Godot)

class Malla:
    def __init__(self):
        self.caras = []      # [puntos (Vector Godot), material, colores RGBA lineales, uvs o None, suave]

    def cara(self, pts, mat, col, uvs=None, suave=False):
        cols = col if isinstance(col, list) else [col] * len(pts)
        cols = [c if len(c) == 4 else lin(c) for c in cols]
        self.caras.append([[Vector(p) for p in pts], mat, cols, uvs, suave])

    def tris(self):
        return sum(len(c[0]) - 2 for c in self.caras)


def R(y=0.0, x=0.0, z=0.0):
    return Matrix.Rotation(math.radians(y), 3, 'Y') @ Matrix.Rotation(math.radians(x), 3, 'X') @ \
        Matrix.Rotation(math.radians(z), 3, 'Z')


def normal_de(pts):
    n = Vector((0, 0, 0))
    for k in range(len(pts)):
        a, b = pts[k], pts[(k + 1) % len(pts)]
        n.x += (a.y - b.y) * (a.z + b.z)
        n.y += (a.z - b.z) * (a.x + b.x)
        n.z += (a.x - b.x) * (a.y + b.y)
    return n.normalized() if n.length > 1e-9 else Vector((0, 1, 0))


def uv_mundo(pts, mat, desfase=(0.0, 0.0)):
    n = normal_de(pts)
    e = ESCALA_UV.get(mat, 1.0)
    ax, ay, az = abs(n.x), abs(n.y), abs(n.z)
    r = []
    for p in pts:
        if ay >= ax and ay >= az:
            u, v = p.x, p.z
        elif ax >= az:
            u, v = p.z, -p.y
        else:
            u, v = p.x, -p.y
        r.append(((u + desfase[0]) / e, (v + desfase[1]) / e))
    return r


CARAS_CAJA = {  # (normal local, esquinas en ±1)
    "e": ((1, 0, 0), [(1, -1, -1), (1, 1, -1), (1, 1, 1), (1, -1, 1)]),
    "o": ((-1, 0, 0), [(-1, -1, -1), (-1, -1, 1), (-1, 1, 1), (-1, 1, -1)]),
    "a": ((0, 1, 0), [(-1, 1, -1), (-1, 1, 1), (1, 1, 1), (1, 1, -1)]),
    "b": ((0, -1, 0), [(-1, -1, -1), (1, -1, -1), (1, -1, 1), (-1, -1, 1)]),
    "s": ((0, 0, 1), [(-1, -1, 1), (1, -1, 1), (1, 1, 1), (-1, 1, 1)]),
    "n": ((0, 0, -1), [(-1, -1, -1), (-1, 1, -1), (1, 1, -1), (1, -1, -1)]),
}


def caja(M, c, s, mat, col, rot=None, veta=None, jit_v=0.0, caras="eoasnb", suave=False):
    """Caja de centro c y tamaño s (Godot), girada por rot (Matrix 3×3). veta: 'larga' = la dimensión más larga de cada
    cara va en V (la veta de la madera); 'u_x' = el eje x local va en U (filas de tejas)."""
    c = Vector(c)
    h = Vector(s) * 0.5
    rot = rot or Matrix.Identity(3)
    e = ESCALA_UV.get(mat, 1.0)
    off = (RND.random() * 3.0, RND.random() * 3.0)
    js = {}
    for cl in caras:
        n, esq = CARAS_CAJA[cl]
        loc = [Vector((q[0] * h.x, q[1] * h.y, q[2] * h.z)) for q in esq]
        pts = []
        for q, l in zip(esq, loc):
            if jit_v > 0:
                if q not in js:
                    js[q] = Vector((RND.uniform(-1, 1), RND.uniform(-1, 1), RND.uniform(-1, 1))) * jit_v
                l = l + js[q]
            pts.append(c + rot @ l)
        uvs = None
        if veta is not None:
            ejes = [k for k in range(3) if n[k] == 0]
            if veta == "u_x":
                eu, ev = (0, ejes[1] if ejes[0] == 0 else ejes[0]) if 0 in ejes else (ejes[0], ejes[1])
            else:
                eu, ev = (ejes[0], ejes[1]) if s[ejes[1]] >= s[ejes[0]] else (ejes[1], ejes[0])
            uvs = [((l[eu] + off[0]) / e, (l[ev] + off[1]) / e) for l in loc]
        M.cara(pts, mat, col, uvs, suave)


def caja_mm(M, a, b, mat, col, **k):
    """Caja de a (mínimo) a b (máximo)."""
    a, b = Vector(a), Vector(b)
    caja(M, (a + b) * 0.5, b - a, mat, col, **k)


def placa(M, pts2, origen, eu, ev, grosor, mat, col, frente=True, lados=True, atras=False, suave=False):
    """Un polígono 2D (en los ejes eu, ev desde origen) extruido «grosor» hacia eu × ev (el frente)."""
    o, eu, ev = Vector(origen), Vector(eu), Vector(ev)
    n = eu.cross(ev).normalized()
    fr = [o + eu * p[0] + ev * p[1] + n * grosor for p in pts2]
    at = [o + eu * p[0] + ev * p[1] for p in pts2]
    e = ESCALA_UV.get(mat, 1.0)
    if frente:
        M.cara(fr, mat, col, [(p[0] / e, -p[1] / e) for p in pts2], suave)
    if atras:
        M.cara(list(reversed(at)), mat, col, None, suave)
    if lados:
        for k in range(len(pts2)):
            a0, a1 = at[k], at[(k + 1) % len(pts2)]
            f0, f1 = fr[k], fr[(k + 1) % len(pts2)]
            M.cara([a0, a1, f1, f0], mat, col, None, suave)


def cilindro(M, base, perfil, n, mat, col, rot=None, tapa_arriba=True, tapa_abajo=False, suave=True, fase=0.0, veta=True):
    """Sólido de revolución: perfil = [(y, radio)] de abajo arriba, n lados, eje y local girado por rot."""
    base = Vector(base)
    rot = rot or Matrix.Identity(3)
    e = ESCALA_UV.get(mat, 1.0)
    anillos = []
    for y, r in perfil:
        anillos.append([base + rot @ Vector((math.cos(fase + k * math.tau / n) * r, y, math.sin(fase + k * math.tau / n) * r))
                        for k in range(n)])
    for j in range(len(perfil) - 1):
        r0 = perfil[j][1]
        circ = math.tau * max(r0, perfil[j + 1][1])
        for k in range(n):
            k1 = (k + 1) % n
            pts = [anillos[j][k], anillos[j][k1], anillos[j + 1][k1], anillos[j + 1][k]]
            uvs = [(k / n * circ / e, -perfil[j][0] / e), ((k + 1) / n * circ / e, -perfil[j][0] / e),
                   ((k + 1) / n * circ / e, -perfil[j + 1][0] / e), (k / n * circ / e, -perfil[j + 1][0] / e)] if veta else None
            M.cara(list(reversed(pts)), mat, col, list(reversed(uvs)) if uvs else None, suave)
    if tapa_arriba and perfil[-1][1] > 0.001:
        M.cara(list(reversed(anillos[-1])), mat, col, None, False)
    if tapa_abajo and perfil[0][1] > 0.001:
        M.cara(anillos[0], mat, col, None, False)


def cono(M, base, r, h, n, mat, col, rot=None, suave=False):
    base = Vector(base)
    rot = rot or Matrix.Identity(3)
    cima = base + rot @ Vector((0, h, 0))
    pts = [base + rot @ Vector((math.cos(k * math.tau / n) * r, 0, math.sin(k * math.tau / n) * r)) for k in range(n)]
    for k in range(n):
        M.cara([pts[(k + 1) % n], pts[k], cima], mat, col, None, suave)


def viga(M, a, b, grueso, mat, col, alto=None, jit_v=0.0):
    """Una viga de sección grueso×alto de a a b (Godot)."""
    a, b = Vector(a), Vector(b)
    d = b - a
    largo = d.length
    ez = d.normalized()
    ref = Vector((0, 1, 0)) if abs(ez.y) < 0.95 else Vector((1, 0, 0))
    ex = ref.cross(ez).normalized()
    ey = ez.cross(ex).normalized()
    rot = Matrix((ex, ey, ez)).transposed()
    caja(M, (a + b) * 0.5, (grueso, alto or grueso, largo), mat, col, rot=rot, veta="larga", jit_v=jit_v)


# ======== (de crear_calle.py, l. 346-348: ruido)
def ruido2(x, z, f=1.0):
    return (math.sin(x * 1.7 * f + 1.3) * math.cos(z * 1.3 * f - 0.7) + math.sin(x * 0.53 * f - z * 0.91 * f + 2.1)) * 0.5



# ======== (de crear_calle.py, l. 374-434: voronoi)
def voronoi(semillas, rect, junta):
    """Celdas de Voronoi recortadas (Sutherland-Hodgman) y encogidas «junta/2» por cada lado: las losas."""
    from collections import defaultdict
    celda = 0.9
    rejilla = defaultdict(list)
    for k, s in enumerate(semillas):
        rejilla[(int(math.floor(s[0] / celda)), int(math.floor(s[1] / celda)))].append(k)
    out = []
    for k, s in enumerate(semillas):
        poly = [(s[0] - 0.8, s[1] - 0.8), (s[0] + 0.8, s[1] - 0.8), (s[0] + 0.8, s[1] + 0.8), (s[0] - 0.8, s[1] + 0.8)]
        gx, gz = int(math.floor(s[0] / celda)), int(math.floor(s[1] / celda))
        for dx in (-1, 0, 1):
            for dz in (-1, 0, 1):
                for m in rejilla.get((gx + dx, gz + dz), []):
                    if m == k:
                        continue
                    t = semillas[m]
                    d = (t[0] - s[0], t[1] - s[1])
                    L = math.hypot(*d)
                    if L < 1e-6:
                        continue
                    u = (d[0] / L, d[1] / L)
                    lim = L * 0.5 - junta * 0.5
                    nuevo = []
                    for q in range(len(poly)):
                        p0, p1 = poly[q], poly[(q + 1) % len(poly)]
                        v0 = (p0[0] - s[0]) * u[0] + (p0[1] - s[1]) * u[1] - lim
                        v1 = (p1[0] - s[0]) * u[0] + (p1[1] - s[1]) * u[1] - lim
                        if v0 <= 0:
                            nuevo.append(p0)
                        if (v0 <= 0) != (v1 <= 0):
                            f = v0 / (v0 - v1)
                            nuevo.append((p0[0] + (p1[0] - p0[0]) * f, p0[1] + (p1[1] - p0[1]) * f))
                    poly = nuevo
                    if len(poly) < 3:
                        break
        if len(poly) >= 3:
            out.append((s, poly))
    return out


def losa(M, poly, y0, alto, col, inclina=(0.0, 0.0)):
    """Una losa: tapa algo abombada con canto biselado y costados hasta y0."""
    n = len(poly)
    cx = sum(p[0] for p in poly) / n
    cz = sum(p[1] for p in poly) / n
    def yy(x, z, h):
        return y0 + h + (x - cx) * inclina[0] + (z - cz) * inclina[1]
    bis = 0.025
    interior = [(cx + (p[0] - cx) * (1 - bis / max(0.05, math.hypot(p[0] - cx, p[1] - cz))),
                 cz + (p[1] - cz) * (1 - bis / max(0.05, math.hypot(p[0] - cx, p[1] - cz)))) for p in poly]
    top = Vector((cx, yy(cx, cz, alto + 0.008), cz))
    ins = [Vector((p[0], yy(p[0], p[1], alto), p[1])) for p in interior]
    bor = [Vector((p[0], yy(p[0], p[1], alto - 0.018), p[1])) for p in poly]
    pie = [Vector((p[0], y0 - 0.03, p[1])) for p in poly]
    tono = col
    for k in range(n):
        k1 = (k + 1) % n
        M.cara([top, ins[k1], ins[k]], "piedra", tono)              # (tapa, vista desde arriba: antihorario)
        M.cara([ins[k], ins[k1], bor[k1], bor[k]], "piedra", tono)
        M.cara([bor[k], bor[k1], pie[k1], pie[k]], "piedra", mezcla(tono, (0.5, 0.48, 0.45), 0.25))


# ======== (de crear_calle.py, l. 487-620: arquitectura)
def ventana(M, cx, y0, z, ancho, alto, postigo, luz=False, jardinera=False, eje="z", sig=1.0):
    """Ventana en una fachada: eje «z» = mira al sur (cx es x, z el plano del muro); eje «x» = mira al este (sig 1) o
    al oeste (sig −1) (cx es entonces la z y «z» la x del plano del muro). Cristal al fondo, marco, alféizar y postigos
    abiertos."""
    if eje == "z":
        N, T, base = Vector((0, 0, 1)), Vector((1, 0, 0)), Vector((cx, 0, z))
    else:
        N = Vector((sig, 0, 0))
        T = Vector((0, 1, 0)).cross(N)
        base = Vector((z, 0, cx))
    UP = Vector((0, 1, 0))
    rot = Matrix((T, UP, N)).transposed()
    def P(u, y, d):
        return base + T * u + UP * y + N * d
    def caja_l(u, y, d, su, sy, sd, mat, col, veta="larga"):
        caja(M, P(u, y, d), (su, sy, sd), mat, col, rot=rot, veta=veta)
    caja_l(0, y0 + alto * 0.5, 0.01, ancho, alto, 0.02, "brillo" if luz else "hierro", LUZ_VENTANA if luz else CRISTAL)
    caja_l(0, y0 + alto * 0.5, 0.035, 0.05, alto, 0.03, "madera", MADERA_OSC)          # parteluz
    caja_l(0, y0 + alto * 0.62, 0.035, ancho, 0.04, 0.03, "madera", MADERA_OSC)        # travesaño
    m = 0.08
    caja_l(-ancho * 0.5 - m * 0.5, y0 + alto * 0.5, 0.05, m, alto + m * 2, 0.08, "madera", MADERA_OSC)
    caja_l(ancho * 0.5 + m * 0.5, y0 + alto * 0.5, 0.05, m, alto + m * 2, 0.08, "madera", MADERA_OSC)
    caja_l(0, y0 + alto + m * 0.5, 0.06, ancho + m * 2.6, m * 1.2, 0.1, "madera", MADERA_OSC)   # dintel
    caja_l(0, y0 - m * 0.5, 0.08, ancho + m * 3, m, 0.14, "sillar", SILLAR, veta=None)          # alféizar
    if postigo is not None:                         # postigos de tablas, abiertos hacia fuera (90-125°)
        ancho_p = ancho * 0.5
        col = jit(postigo, 0.05)
        for lado in (-1, 1):
            gozne = P(lado * (ancho * 0.5 + m), y0 + alto * 0.5, 0.07)
            al = math.radians(RND.uniform(95, 128))
            d = -T * (lado * math.cos(al)) + N * math.sin(al)
            ez = d.cross(UP).normalized()
            giro = Matrix((d, UP, ez)).transposed()
            for t in range(3):
                caja(M, gozne + d * ((t + 0.5) * ancho_p / 3.0), (ancho_p / 3.0 - 0.012, alto + 0.04, 0.03), "madera",
                     jit(col, 0.03), rot=giro, veta="larga")
            for yy in (-0.3, 0.3):
                for s in (-1, 1):
                    caja(M, gozne + d * (ancho_p * 0.5) + UP * (alto * yy) + ez * (0.025 * s), (ancho_p * 0.92, 0.07, 0.02),
                         "madera", mezcla(col, (0.2, 0.2, 0.2), 0.2), rot=giro, veta="larga")
    if jardinera:
        caja_l(0, y0 - 0.16, 0.2, ancho + 0.1, 0.2, 0.22, "madera", jit(MADERA, 0.05))
    return P(0, y0 - 0.04, 0.2)                       # el sitio de la jardinera (para las flores)


def entramado(M, x0, x1, y0, y1, z, postes, col_rev, col_mad, eje="z", cruces=()):
    """Muro de entramado: el revoque al fondo y las vigas 4 cm por delante (fachada al sur; eje x: al este/oeste)."""
    def P(u, y, d):
        return Vector((u, y, z + d)) if eje == "z" else Vector((z + d, y, u))
    rot = Matrix.Identity(3) if eje == "z" else R(90)
    ancho = x1 - x0
    caja(M, P((x0 + x1) * 0.5, (y0 + y1) * 0.5, -0.06), (ancho, y1 - y0, 0.12), "revoque", col_rev, rot=rot)
    g = 0.16
    viga(M, P(x0, y0 + g * 0.5, 0.02), P(x1, y0 + g * 0.5, 0.02), 0.14, "madera", col_mad, alto=g, jit_v=0.008)
    viga(M, P(x0, y1 - g * 0.5, 0.02), P(x1, y1 - g * 0.5, 0.02), 0.14, "madera", col_mad, alto=g, jit_v=0.008)
    xs = [x0 + g * 0.5] + list(postes) + [x1 - g * 0.5]
    for u in xs:
        viga(M, P(u, y0 + g, 0.025), P(u, y1 - g, 0.025), 0.15, "madera", jit(col_mad, 0.04), jit_v=0.006)
    if cruces:                                     # jabalcones en los vanos sin ventana (índices de vano)
        for k in range(len(xs) - 1):
            a, b = xs[k], xs[k + 1]
            if k not in cruces:
                continue
            if k % 2 == 0:
                viga(M, P(a + 0.08, y0 + g, 0.015), P(min(b, a + (y1 - y0) * 0.75) - 0.08, y1 - g, 0.015), 0.12,
                     "madera", jit(col_mad, 0.04), alto=0.13)
            else:
                viga(M, P(b - 0.08, y0 + g, 0.015), P(max(a, b - (y1 - y0) * 0.75) + 0.08, y1 - g, 0.015), 0.12,
                     "madera", jit(col_mad, 0.04), alto=0.13)


def faldon(M, a_izq, a_der, sube, filas_col, grueso=0.05, solape=0.32, alero_col=MADERA_OSC, musgo=0.25, mat="tejas"):
    """Un faldón de tejado: de la línea del alero (a_izq → a_der) hacia arriba por «sube» (vector hasta la cumbrera),
    en filas de tejas (cajas finas que se solapan), partidas en tramos de color, con su tablero debajo."""
    a_izq, a_der, sube = Vector(a_izq), Vector(a_der), Vector(sube)
    eu = (a_der - a_izq).normalized()
    largo_u = (a_der - a_izq).length
    largo_v = sube.length
    ev = sube.normalized()
    en = eu.cross(ev).normalized()
    if en.y < 0:                                       # (sin espejar: se recorre el alero al revés)
        a_izq, a_der = a_der, a_izq
        eu, en = -eu, -en
    rot = Matrix((eu, en, -ev)).transposed()            # x = eu, y = normal, z = bajando por el faldón
    caja(M, a_izq + eu * largo_u * 0.5 + ev * largo_v * 0.5 - en * 0.06, (largo_u, 0.06, largo_v), "madera",
         MADERA_OSC, rot=rot, veta="larga", caras="ab")
    filas = max(2, int(largo_v / solape))
    for f in range(filas):
        v = (f + 0.5) * largo_v / filas
        u = -0.05
        while u < largo_u:
            tramo = min(largo_u + 0.05 - u, RND.uniform(0.7, 1.7))
            col = jit(filas_col[(f * 3 + int(u * 2.3)) % len(filas_col)], 0.035)
            if RND.random() < musgo * 0.55 * (1.0 - f / filas * 0.7):
                col = mezcla(col, MUSGO, RND.uniform(0.12, 0.32))
            hund = RND.uniform(-0.012, 0.012)
            c = a_izq + eu * (u + tramo * 0.5) + ev * v + en * (0.02 + hund + 0.015 * (f % 2))
            gir = Matrix.Rotation(math.radians(RND.uniform(-1.2, 1.2)), 3, eu) @ rot
            caja(M, c, (tramo, grueso, largo_v / filas + 0.12), mat, col, rot=gir, veta="u_x",
                 caras="asneo" if f == 0 else "aseo")
            u += tramo
    # la tabla del alero y las cabezas de los cabios debajo
    caja(M, a_izq + eu * largo_u * 0.5 - en * 0.08 + ev * 0.02, (largo_u + 0.04, 0.18, 0.05), "madera", alero_col,
         rot=rot, veta="larga")


def cumbrera(M, a, b, col=None):
    a, b = Vector(a), Vector(b)
    d = (b - a)
    largo = d.length
    eu = d.normalized()
    u = 0.0
    while u < largo:
        t = min(largo - u, 0.42)
        c = a + eu * (u + t * 0.5)
        ref = Vector((0, 1, 0))
        ex = eu
        ey = ref - ex * ref.dot(ex)
        ey.normalize()
        ez = ex.cross(ey)
        rot = Matrix((ex, ey, ez)).transposed() @ Matrix.Rotation(math.radians(45), 3, 'X')
        caja(M, c + Vector((0, 0.04, 0)), (t - 0.02, 0.16, 0.16), "tejas", jit(col or elige(TEJA), 0.06), rot=rot,
             veta="u_x")
        u += t


def chimenea(M, x, z, y0, y1, ancho=0.7, fondo=0.55):
    caja_mm(M, (x - ancho / 2, y0, z - fondo / 2), (x + ancho / 2, y1, z + fondo / 2), "sillar", jit(SILLAR, 0.05),
            jit_v=0.01)
    caja_mm(M, (x - ancho / 2 - 0.06, y1, z - fondo / 2 - 0.06), (x + ancho / 2 + 0.06, y1 + 0.12, z + fondo / 2 + 0.06),
            "sillar", jit(SILLAR, 0.05))
    for k, dx in enumerate((-0.15, 0.17)):                 # dos cañones de barro
        cilindro(M, (x + dx, y1 + 0.12, z), [(0, 0.1), (0.26, 0.09), (0.3, 0.11)], 8, "barro", jit(BARRO, 0.06))
    ancla_p("humo_%d" % len([k for k in ANCLAS if k.startswith("humo_")]), (x, y1 + 0.5, z))


# ======== (de crear_calle.py, l. 623-658: anclas; ahora del sector en obra y giradas por el marco)

def ancla_p(nombre, p):
    ANCLAS[nombre] = al_mundo(p)


def choque(c, s, yaw=0.0, nombre=""):
    """Una caja de choque (centro, tamaño, giro en grados). En el barrio, solo para lo que queda en lo andable."""
    if XF is not None:
        c = al_mundo(c)
        yaw = yaw + XF[2]
    CHOQUES.append((tuple(c), tuple(s), yaw, nombre))


def farol_pared(M, base, hacia, alto_brazo=0.0):
    """Farol en un brazo de hierro que sale de la pared en la dirección «hacia» (Vector horizontal)."""
    base, hacia = Vector(base), Vector(hacia).normalized()
    punta = base + hacia * 0.55
    viga(M, base, punta + Vector((0, 0.02, 0)), 0.035, "hierro", HIERRO)
    viga(M, base - Vector((0, 0.35, 0)), base + hacia * 0.35, 0.03, "hierro", HIERRO)      # tornapuntas
    cuelga = punta - Vector((0, 0.12, 0))
    viga(M, punta, cuelga, 0.015, "hierro", HIERRO)
    farol(M, cuelga - Vector((0, 0.36, 0)))
    return cuelga - Vector((0, 0.2, 0))


def farol(M, base, escala=1.0):
    """Farol de cuatro cristales con su tejadillo: el cristal da luz (material brillo)."""
    b = Vector(base)
    e = escala
    caja(M, b + Vector((0, 0.03 * e, 0)), (0.22 * e, 0.06 * e, 0.22 * e), "hierro", HIERRO)
    caja(M, b + Vector((0, 0.19 * e, 0)), (0.16 * e, 0.26 * e, 0.16 * e), "brillo", LUZ_FAROL)
    for dx in (-1, 1):
        for dz in (-1, 1):
            caja(M, b + Vector((dx * 0.09 * e, 0.19 * e, dz * 0.09 * e)), (0.025 * e, 0.3 * e, 0.025 * e), "hierro", HIERRO)
    cono(M, b + Vector((0, 0.32 * e, 0)), 0.17 * e, 0.16 * e, 4, "hierro", HIERRO, rot=R(45))
    caja(M, b + Vector((0, 0.5 * e, 0)), (0.04 * e, 0.06 * e, 0.04 * e), "hierro", HIERRO)
    ancla_p("farol_%d" % len([k for k in ANCLAS if k.startswith("farol_")]), b + Vector((0, 0.19 * e, 0)))


def farol_debil(M, base, escala=1.0):
    """(barrio) Un farol apagado de día o una vela: igual que farol(), pero su ancla es «candil_»: luz pequeña."""
    farol(M, base, escala)
    k = max(int(n.split("_")[1]) for n in ANCLAS if n.startswith("farol_"))
    ANCLAS["candil_%d" % k] = ANCLAS.pop("farol_%d" % k)


# ======== (de crear_calle.py, l. 810-830: letrero)
def letrero(M, base, hacia):
    """Letrero de la botica: brazo de hierro con voluta que sale de la fachada y, colgada de dos cadenas, una tabla
    PARALELA a la fachada (de frente a la cámara, que nunca gira) con un mortero de latón en relieve."""
    base = Vector(base)
    h = Vector(hacia).normalized()
    punta = base + h * 1.05
    viga(M, base, punta, 0.045, "hierro", HIERRO)
    viga(M, base - Vector((0, 0.45, 0)), base + h * 0.55, 0.035, "hierro", HIERRO)
    cilindro(M, base + h * 0.3 + Vector((0, -0.12, 0)), [(0, 0.12), (0.025, 0.12), (0.025, 0.1), (0, 0.1)], 10, "hierro",
             HIERRO, rot=R(0, 0, 90), tapa_arriba=False)                 # voluta del brazo: un aro
    c = punta - h * 0.12 - Vector((0, 0.55, 0))
    for d in (-0.34, 0.34):
        viga(M, punta - h * 0.12 + Vector((d * 0.5, 0, 0)), c + Vector((d, 0.32, 0)), 0.012, "hierro", HIERRO)
    viga(M, punta - h * 0.12 + Vector((-0.2, 0, 0)), punta - h * 0.12 + Vector((0.2, 0, 0)), 0.03, "hierro", HIERRO)
    caja(M, c, (0.9, 0.64, 0.06), "madera", (0.36, 0.26, 0.20), veta="larga")
    caja(M, c + Vector((0, 0, 0.01)), (0.8, 0.54, 0.06), "madera", (0.80, 0.66, 0.46), veta="larga")
    cilindro(M, c + Vector((0, -0.04, 0.04)), [(0, 0.17), (0.025, 0.17), (0.04, 0.12)], 12, "barro", LATON, rot=R(0, 90))
    caja(M, c + Vector((0.08, 0.1, 0.08)), (0.05, 0.36, 0.04), "madera", MADERA_OSC, rot=R(0, 0, -28))
    caja(M, c + Vector((-0.24, 0.17, 0.06)), (0.12, 0.05, 0.03), "madera", (0.36, 0.56, 0.26), rot=R(0, 0, 35))
    caja(M, c + Vector((-0.3, 0.06, 0.06)), (0.11, 0.05, 0.03), "madera", (0.36, 0.56, 0.26), rot=R(0, 0, -30))



# ======== (de crear_calle.py, l. 1105-1178: atrezo)
def barril(M, c, r=0.32, h=0.85, tumbado=False, yaw=0.0):
    c = Vector(c)
    rot = R(yaw) @ (R(0, 0, 90) if tumbado else Matrix.Identity(3))
    base = c + (rot @ Vector((0, -h / 2, 0)) if tumbado else Vector((0, 0, 0)))
    perfil = [(0, r * 0.86), (h * 0.25, r * 0.97), (h * 0.5, r), (h * 0.75, r * 0.97), (h, r * 0.86)]
    cilindro(M, base, perfil, 14, "madera", jit(MADERA, 0.06), rot=rot, tapa_arriba=True, tapa_abajo=tumbado)
    for f in (0.12, 0.88, 0.38, 0.62):
        rr = r * (0.9 if f in (0.12, 0.88) else 0.995) + 0.008
        cilindro(M, base + rot @ Vector((0, h * f - 0.025, 0)), [(0, rr), (0.05, rr)], 14, "hierro", HIERRO, rot=rot,
                 tapa_arriba=False)
    if tumbado:
        choque(c, (h, 2 * r, 2 * r), yaw + 90)
    else:
        choque(c + Vector((0, h / 2, 0)), (2 * r, h, 2 * r))


def cajon(M, c, s=(0.6, 0.5, 0.5), yaw=0.0, col=None):
    c = Vector(c)
    rot = R(yaw)
    col = col or jit(MADERA_GRIS, 0.06)
    caja(M, c + Vector((0, s[1] / 2, 0)), (s[0] - 0.04, s[1] - 0.02, s[2] - 0.04), "madera", mezcla(col, (0.3, 0.25, 0.2), 0.3), rot=rot)
    for k in range(3):
        y = (k + 0.5) * s[1] / 3
        for zz in (-1, 1):
            caja(M, c + rot @ Vector((0, y, zz * s[2] / 2)), (s[0], s[1] / 3 - 0.02, 0.03), "madera", jit(col, 0.03),
                 rot=rot, veta="larga")
        for xx in (-1, 1):
            caja(M, c + rot @ Vector((xx * s[0] / 2, y, 0)), (0.03, s[1] / 3 - 0.02, s[2]), "madera", jit(col, 0.03),
                 rot=rot, veta="larga")
    for xx in (-1, 1):
        for zz in (-1, 1):
            caja(M, c + rot @ Vector((xx * (s[0] / 2 - 0.02), s[1] / 2, zz * (s[2] / 2 + 0.005))), (0.05, s[1], 0.035),
                 "madera", mezcla(col, (0.3, 0.25, 0.2), 0.25), rot=rot, veta="larga")
    choque(c + Vector((0, s[1] / 2, 0)), s, yaw)


def maceta(M, V, c, r=0.22, h=0.3, flores=True):
    c = Vector(c)
    cilindro(M, c, [(0, r * 0.7), (h * 0.8, r), (h, r * 1.08), (h, r * 0.95)], 10, "barro", jit(BARRO, 0.07))
    caja(M, c + Vector((0, h - 0.03, 0)), (r * 1.4, 0.02, r * 1.4), "tierra", (0.40, 0.32, 0.26), rot=R(RND.uniform(0, 90)),
         caras="a")
    if flores:
        mata_flores(V, c + Vector((0, h - 0.02, 0)), r * 1.1, RND.choice(FLORES), n=10, alto=0.32)


def carretilla(M, V, c, yaw):
    c = Vector(c)
    rot = R(yaw)
    def P(x, y, z):
        return c + rot @ Vector((x, y, z))
    # la caja (tablas)
    caja(M, P(0.0, 0.42, 0.0), (0.95, 0.05, 0.62), "madera", jit(MADERA, 0.05), rot=rot, veta="larga")
    for s in (-1, 1):
        caja(M, P(0.0, 0.6, s * 0.33), (1.0, 0.32, 0.04), "madera", jit(MADERA, 0.05), rot=rot @ R(0, s * 12), veta="larga")
    caja(M, P(0.5, 0.6, 0.0), (0.04, 0.32, 0.7), "madera", jit(MADERA, 0.05), rot=rot @ R(0, 0, -15), veta="larga")
    caja(M, P(-0.48, 0.6, 0.0), (0.04, 0.3, 0.66), "madera", jit(MADERA, 0.05), rot=rot, veta="larga")
    # varas y patas
    for s in (-1, 1):
        viga(M, P(0.62, 0.32, s * 0.24), P(-1.25, 0.62, s * 0.3), 0.05, "madera", MADERA_OSC)
        viga(M, P(-0.35, 0.4, s * 0.24), P(-0.42, 0.0, s * 0.26), 0.045, "madera", MADERA_OSC)
    # la rueda (radios y llanta)
    cilindro(M, P(0.62, 0.26, -0.04), [(0, 0.26), (0.08, 0.26), (0.08, 0.2), (0, 0.2)], 14, "madera", MADERA_OSC,
             rot=rot @ R(0, 90), tapa_arriba=False)
    cilindro(M, P(0.62, 0.26, -0.04), [(0, 0.272), (0.06, 0.272)], 14, "hierro", HIERRO, rot=rot @ R(0, 90),
             tapa_arriba=False)
    for k in range(6):
        a = k * math.pi / 3
        viga(M, P(0.62, 0.26, 0.0), P(0.62 + math.cos(a) * 0.21, 0.26 + math.sin(a) * 0.21, 0.0), 0.025, "madera", MADERA_OSC)
    # sacos de tela
    for k, (x, z) in enumerate(((-0.15, -0.12), (0.18, 0.1))):
        cilindro(M, P(x, 0.44, z), [(0, 0.17), (0.12, 0.22), (0.3, 0.2), (0.38, 0.1), (0.42, 0.03)], 9, "tela",
                 jit((0.86, 0.76, 0.58), 0.05), rot=rot @ R(0, 0, 70 + k * 30))
    choque(P(-0.2, 0.4, 0.0), (1.9, 0.8, 0.8), yaw)



# ======== (de crear_calle.py, l. 1243-1312: vegetacion)
def mata(V, p, radio, n, alto, cols=HIERBA, ladeo=0.35):
    """Una mata de hojas de hierba (cada hoja, un triángulo estirado): alfa 0 en la base y 1 en la punta."""
    p = Vector(p)
    for k in range(n):
        a = RND.uniform(0, math.tau)
        d = RND.uniform(0, radio)
        b = p + Vector((math.cos(a) * d, 0, math.sin(a) * d))
        h = alto * RND.uniform(0.55, 1.15)
        ang = RND.uniform(0, math.tau)
        lad = Vector((math.cos(a), 0, math.sin(a))) * h * RND.uniform(0.1, ladeo)
        w = 0.04 + 0.03 * RND.random()
        e = Vector((math.cos(ang), 0, math.sin(ang))) * w
        cima = b + Vector((0, h, 0)) + lad
        medio = b + Vector((0, h * 0.5, 0)) + lad * 0.35
        col = jit(elige(cols), 0.08)
        base_c = mezcla(col, (0.18, 0.22, 0.10), 0.45)
        V.cara([b - e, b + e, medio + e * 0.6, medio - e * 0.6], "hoja", [lin(base_c, 0.0), lin(base_c, 0.0), lin(col, 0.5),
                                                                         lin(col, 0.5)])
        V.cara([medio - e * 0.6, medio + e * 0.6, cima], "hoja", [lin(col, 0.5), lin(col, 0.5), lin(mezcla(col, (0.9, 0.9, 0.6), 0.2), 1.0)])


def mata_flores(V, p, radio, color, n=8, alto=0.3):
    p = Vector(p)
    mata(V, p, radio, int(n * 1.4), alto * 0.8, HOJA)
    for k in range(n):
        a = RND.uniform(0, math.tau)
        d = RND.uniform(0, radio)
        c = p + Vector((math.cos(a) * d, alto * RND.uniform(0.6, 1.1), math.sin(a) * d))
        r = 0.06 + 0.03 * RND.random()
        col = jit(color, 0.06)
        pts = [c + Vector((math.cos(j * math.tau / 5) * r, 0.01 * (j % 2), math.sin(j * math.tau / 5) * r)) for j in range(5)]
        V.cara(pts, "hoja", [lin(col, 0.9)] * 5)
        V.cara([c + Vector((0, 0.012, 0)) + (pts[j] - c) * 0.35 for j in range(5)], "hoja", [lin((0.98, 0.86, 0.3), 0.9)] * 5)


def hojas(V, centro, radio, n, cols=HOJA, tam=0.09, flex=0.4, aplastar=1.0, hacia=None):
    """Un racimo de hojas (rombos) dentro de una esfera achatada: arbustos, hiedra, la copa del árbol."""
    centro = Vector(centro)
    for k in range(n):
        while True:
            d = Vector((RND.uniform(-1, 1), RND.uniform(-1, 1), RND.uniform(-1, 1)))
            if d.length <= 1:
                break
        p = centro + Vector((d.x * radio, d.y * radio * aplastar, d.z * radio))
        if hacia is not None:
            nrm = (Vector(hacia) + d * 0.6).normalized()
        else:
            nrm = (d + Vector((0, 0.6, 0))).normalized()
        t1 = nrm.cross(Vector((0.3, 1, 0.2))).normalized()
        t2 = nrm.cross(t1).normalized()
        s = tam * RND.uniform(0.7, 1.3)
        col = jit(elige(cols), 0.1)
        if d.y < 0:
            col = mezcla(col, (0.14, 0.2, 0.1), -d.y * 0.4)
        f = flex * (0.5 + 0.5 * (d.y + 1) * 0.5)
        V.cara([p - t1 * s, p - t2 * s * 0.45, p + t1 * s, p + t2 * s * 0.45], "hoja", [lin(col, f)] * 4)


def hiedra(V, x, z_pared, y_max, eje="z", hacia=(0, 0, 1), y0=0.0):
    """Hiedra que trepa por una pared: tallos al azar hacia arriba con racimos de hojas planos contra el muro.
    (barrio) y0: la cota del pie de la pared; y_max se mide desde ahí."""
    for tallo in range(4):
        p = Vector((x + RND.uniform(-0.3, 0.3), y0 + 0.05, z_pared + 0.06)) if eje == "z" else \
            Vector((z_pared + 0.06, y0 + 0.05, x + RND.uniform(-0.3, 0.3)))
        y_fin = y0 + y_max * RND.uniform(0.6, 1.0)
        while p.y < y_fin:
            hojas(V, p, 0.22, 7, HOJA, 0.075, flex=0.15 + (p.y - y0) / y_max * 0.2, aplastar=1.0, hacia=hacia)
            paso = Vector((RND.uniform(-0.25, 0.25), RND.uniform(0.15, 0.3), 0))
            if eje != "z":
                paso = Vector((0, paso.y, paso.x))
            p += paso


# ======== (de crear_calle.py, l. 1447-1563: texturas)
def _ruido(n, cx, cy, rng):
    g = rng.random((cy, cx)).astype(np.float32)
    def ejes(celdas):
        x = np.arange(n, dtype=np.float32) * celdas / n
        i0 = np.floor(x).astype(np.int32)
        f = x - i0
        s = f * f * (3 - 2 * f)
        return i0 % celdas, (i0 + 1) % celdas, s
    xi0, xi1, sx = ejes(cx)
    yi0, yi1, sy = ejes(cy)
    a = g[np.ix_(yi0, xi0)]; b = g[np.ix_(yi0, xi1)]; c = g[np.ix_(yi1, xi0)]; d = g[np.ix_(yi1, xi1)]
    sx = sx[None, :]; sy = sy[:, None]
    return (a * (1 - sx) + b * sx) * (1 - sy) + (c * (1 - sx) + d * sx) * sy


def fbm(n, base, octavas, rng, gan=0.5, ax=1.0):
    t = np.zeros((n, n), np.float32)
    amp, tot = 1.0, 0.0
    for o in range(octavas):
        c = int(base * 2 ** o)
        if c > n // 2:
            break
        t += _ruido(n, max(1, int(c * ax)), c, rng) * amp
        tot += amp
        amp *= gan
    return t / tot


def guardar_tex(nombre, rgb, carpeta):
    n = rgb.shape[0]
    img = bpy.data.images.get(nombre) or bpy.data.images.new(nombre, n, n, alpha=False)
    px = np.ones((n, n, 4), np.float32)
    px[..., :3] = np.clip(rgb, 0, 1)
    img.pixels.foreach_set(px.ravel())
    if carpeta:
        img.filepath_raw = os.path.join(carpeta, nombre + ".png")
        img.file_format = 'PNG'
        img.save()
    return img


def texturas(carpeta):
    n = 512
    rng = np.random.default_rng(7)
    out = {}
    def rgb(v, tinte=(1, 1, 1)):
        return np.stack([v * tinte[0], v * tinte[1], v * tinte[2]], -1)
    # revoque: manchas grandes, chorretones de lluvia y grano
    v = 0.86 + 0.10 * (fbm(n, 3, 3, rng) - 0.5) + 0.05 * (fbm(n, 24, 3, rng) - 0.5)
    chorro = _ruido(n, 40, 2, rng)
    v -= 0.07 * np.clip(chorro - 0.55, 0, 1) * 2.5
    v += 0.05 * (rng.random((n, n)) - 0.5)
    out["revoque"] = rgb(v, (1.0, 0.985, 0.955))
    # madera: veta a lo largo de V (columnas), nudos y grietas finas
    veta = fbm(n, 6, 3, rng, ax=8.0)
    v = 0.74 + 0.16 * (np.sin(veta * 40.0) * 0.5) * 0.6 + 0.1 * (fbm(n, 4, 2, rng) - 0.5)
    v -= 0.12 * (np.abs(np.sin(_ruido(n, 64, 3, rng) * 30)) < 0.05)
    out["madera"] = rgb(v + 0.03 * (rng.random((n, n)) - 0.5), (1.0, 0.97, 0.92))
    # tejas: 4 tejas por metro a lo largo de U, abombadas, cada una con su tono
    u = (np.arange(n) / n * 4.0) % 1.0
    curva = 0.82 + 0.16 * np.sin(u * math.pi) - 0.12 * (np.abs(u - 0.5) > 0.46)
    tono = np.repeat(rng.uniform(0.88, 1.08, 4), n // 4)
    v = curva[None, :] * tono[None, :] + 0.06 * (fbm(n, 8, 3, rng) - 0.5)
    filo = (np.arange(n) / n * 3.0) % 1.0
    v *= (1.0 - 0.18 * (filo[:, None] > 0.9))
    out["tejas"] = rgb(v, (1.0, 0.97, 0.94))
    # sillar: hiladas de 0,4 m con piedras de largo variable y llagas oscuras
    v = np.zeros((n, n), np.float32)
    filas = 4
    hf = n // filas
    for f in range(filas):
        x = int(rng.integers(0, n))
        cortes = []
        while len(cortes) == 0 or (cortes[-1] - cortes[0]) < n:
            cortes.append(x)
            x += int(rng.integers(int(n * 0.22), int(n * 0.46)))
        tonos = rng.uniform(0.82, 1.0, len(cortes))
        for k in range(len(cortes) - 1):
            a, b = cortes[k], cortes[k + 1]
            for xx in range(a, b):
                v[f * hf:(f + 1) * hf, xx % n] = tonos[k]
            for xx in range(a - 3, a + 3):
                v[f * hf:(f + 1) * hf, xx % n] = 0.5
        v[f * hf:f * hf + 4, :] = 0.5
    v = v * (0.92 + 0.12 * (fbm(n, 12, 3, rng) - 0.5) + 0.06 * (rng.random((n, n)) - 0.5))
    out["sillar"] = rgb(v, (1.0, 0.98, 0.95))
    # piedra (las losas): moteado, puntos claros y algún liquen
    v = 0.80 + 0.10 * (fbm(n, 6, 4, rng) - 0.5) + 0.08 * (rng.random((n, n)) - 0.5)
    lq = fbm(n, 16, 2, rng)
    t = rgb(v)
    t[lq > 0.68] = t[lq > 0.68] * np.array([1.02, 1.02, 0.86])
    out["piedra"] = t
    # tierra: moteado, guijarros
    v = 0.78 + 0.12 * (fbm(n, 5, 4, rng) - 0.5) + 0.07 * (rng.random((n, n)) - 0.5)
    yy, xx = np.mgrid[0:n, 0:n]
    for k in range(260):
        cx, cy, r = rng.integers(0, n), rng.integers(0, n), rng.uniform(2, 6)
        dx = (xx - cx + n // 2) % n - n // 2
        dy = (yy - cy + n // 2) % n - n // 2
        d = np.sqrt(dx * dx + dy * dy)
        v = np.where(d < r, 0.96 - 0.15 * d / r, np.where(d < r + 1.5, v * 0.8, v))
    out["tierra"] = rgb(v)
    # tela: trama
    u = np.arange(n)
    trama = 0.9 + 0.06 * np.sin(u[:, None] * 1.6) * np.sin(u[None, :] * 1.6)
    out["tela"] = rgb(trama + 0.06 * (fbm(n, 8, 3, rng) - 0.5))
    # hoja: moteado suave
    out["hoja"] = rgb(0.86 + 0.12 * (fbm(n, 6, 3, rng) - 0.5))
    imgs = {}
    for k, t in out.items():
        imgs[k] = guardar_tex(k, t, carpeta)
    return imgs


TEX_DE = {"piedra": "piedra", "tierra": "tierra", "revoque": "revoque", "madera": "madera", "tejas": "tejas",
          "sillar": "sillar", "hierro": "piedra", "tela": "tela", "barro": "revoque", "hoja": "hoja", "brillo": None}


def cargar_texturas(carpeta):
    """(barrio) Las MISMAS texturas de la muestra (zonas3d/muestra_calle/texturas/*.png, pintadas por texturas() con la
    semilla 7): en el horneado ponen el color de los rebotes; en Godot se usan las de la muestra sin copiarlas."""
    imgs = {}
    for k in ("revoque", "madera", "tejas", "sillar", "piedra", "tierra", "tela", "hoja"):
        imgs[k] = bpy.data.images.load(os.path.join(carpeta, k + ".png"), check_existing=True)
    return imgs


def png_gris(ruta, canales, ancho, alto):
    """(barrio) Un PNG de 8 bits sin gestión de color (lo que se escribe es lo que se lee): «canales» son listas de
    valores 0-1 por fila (de z0 a z1) y columna (de x0 a x1); el tercero va a 0. Las sondas: R = sol, G = cielo."""
    filas = []
    for j in range(alto):
        fila = bytearray([0])
        for i in range(ancho):
            k = j * ancho + i
            for c in range(3):
                v = canales[c][k] if c < len(canales) else 0.0
                fila.append(max(0, min(255, int(round(v * 255.0)))))
        filas.append(bytes(fila))
    def trozo(tipo, datos):
        return struct.pack(">I", len(datos)) + tipo + datos + struct.pack(">I", zlib.crc32(tipo + datos) & 0xffffffff)
    with open(ruta, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(trozo(b"IHDR", struct.pack(">IIBBBBB", ancho, alto, 8, 2, 0, 0, 0)))
        f.write(trozo(b"IDAT", zlib.compress(b"".join(filas), 9)))
        f.write(trozo(b"IEND", b""))


# ======== (de crear_calle.py, l. 1565-1644: blender)
# ---------------------------------------------------------------- de las listas a Blender

# (barrio) Materiales que comparten textura en la muestra (TEX_DE: hierro → piedra, barro → revoque) van en la MISMA
# superficie: el color ya lo pone el tinte del vértice y las UV ya están hechas con su escala. Dos llamadas menos por objeto.
FUSION = {"hierro": "piedra", "barro": "revoque"}


def a_blender(nombre, M, mats, con_luz_uv):
    verts, polys, cols, uvs, suaves, mi = [], [], [], [], [], []
    for pts, mat, cs, uv, suave in M.caras:
        base = len(verts)
        for p in pts:
            verts.append((p.x, -p.z, p.y))                 # Godot (x, y, z) → Blender (x, -z, y)
        polys.append(list(range(base, base + len(pts))))
        cols.extend(cs)
        uvs.extend(uv if uv is not None else uv_mundo(pts, mat))
        suaves.append(suave)
        mi.append(MATS.index(FUSION.get(mat, mat)))
    me = bpy.data.meshes.new(nombre)
    me.from_pydata(verts, [], polys)
    me.polygons.foreach_set("material_index", mi)
    me.polygons.foreach_set("use_smooth", suaves)
    uvl = me.uv_layers.new(name="UVMap")
    uvl.data.foreach_set("uv", np.array(uvs, np.float32).ravel())
    ca = me.color_attributes.new("Col", 'FLOAT_COLOR', 'CORNER')
    ca.data.foreach_set("color", np.array(cols, np.float32).ravel())
    if con_luz_uv:
        me.uv_layers.new(name="luz")
    for m in MATS:
        me.materials.append(mats[m])
    me.validate()
    ob = bpy.data.objects.new(nombre, me)
    bpy.context.scene.collection.objects.link(ob)
    # juntar vértices repetidos (sombreado suave donde toca; los atributos van por esquina)
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bm.to_mesh(me)
    bm.free()
    me.color_attributes.active_color = me.color_attributes["Col"]
    return ob


def materiales(imgs, img_luz):
    mats = {}
    for m in MATS:
        mt = bpy.data.materials.new(m)
        mt.use_nodes = True
        nt = mt.node_tree
        bsdf = nt.nodes.get("Principled BSDF")
        bsdf.inputs["Roughness"].default_value = 1.0
        if "Specular IOR Level" in bsdf.inputs:
            bsdf.inputs["Specular IOR Level"].default_value = 0.0
        vc = nt.nodes.new("ShaderNodeVertexColor")
        vc.layer_name = "Col"
        if m == "brillo":
            bsdf.inputs["Base Color"].default_value = (0, 0, 0, 1)
            nt.links.new(vc.outputs["Color"], bsdf.inputs["Emission Color"])
            bsdf.inputs["Emission Strength"].default_value = 2.5
        else:
            tex = nt.nodes.new("ShaderNodeTexImage")
            tex.image = imgs[TEX_DE[m]]
            uvn = nt.nodes.new("ShaderNodeUVMap")
            uvn.uv_map = "UVMap"
            nt.links.new(uvn.outputs["UV"], tex.inputs["Vector"])
            mul = nt.nodes.new("ShaderNodeMix")
            mul.data_type = 'RGBA'
            mul.blend_type = 'MULTIPLY'
            mul.inputs["Factor"].default_value = 1.0
            ent = {so.identifier: so for so in mul.inputs}
            sal = {so.identifier: so for so in mul.outputs}
            nt.links.new(tex.outputs["Color"], ent["A_Color"])
            nt.links.new(vc.outputs["Color"], ent["B_Color"])
            nt.links.new(sal["Result_Color"], bsdf.inputs["Base Color"])
        if img_luz is not None:
            luz = nt.nodes.new("ShaderNodeTexImage")
            luz.name = "LUZ"
            luz.image = img_luz
            uvl = nt.nodes.new("ShaderNodeUVMap")
            uvl.uv_map = "luz"
            nt.links.new(uvl.outputs["UV"], luz.inputs["Vector"])
            nt.nodes.active = luz
        mt.use_backface_culling = False
        mats[m] = mt
    return mats


# ======== (de crear_calle.py, l. 1647-1686: recorte)
# ---------------------------------------------------------------- recorte: lo que ninguna cámara ve

def bvh_de(mallas):
    """(barrio) Un BVH (coordenadas de Godot) con las caras de todas las mallas, en orden; y dónde empieza cada una."""
    verts, polys, inicio = [], [], []
    for M in mallas:
        inicio.append(len(polys))
        for pts, *_ in M.caras:
            b = len(verts)
            verts.extend([Vector((p.x, p.y, p.z)) for p in pts])
            polys.append(list(range(b, b + len(pts))))
    return BVHTree.FromPolygons(verts, polys, all_triangles=False, epsilon=0.0), inicio


CAM_FOV, CAM_ASPECTO = 38.0, 1600.0 / 720.0


def recortar(M, bvh, base_idx, cams, alcance=70.0):
    """Separa las caras que ve alguna cámara de las que no (estas solo sirven para el horneado: tapan y rebotan luz).
    (barrio) bvh: TODO lo que tapa (todos los sectores; las caras de M empiezan en base_idx); cams: [(pos, adelante,
    arriba, derecha)] de las cámaras posibles (crear_barrio.py, de las zonas de cámara); solo cuentan las que están a
    menos de «alcance» metros de la cara. Devuelve (vistas, ocultas) y, por cámara, si vio alguna cara."""
    tf = math.tan(math.radians(CAM_FOV) * 0.5) * 1.06
    vis, ocu = Malla(), Malla()
    vio = [False] * len(cams)
    for idx0, cara in enumerate(M.caras):
        idx = base_idx + idx0
        pts = cara[0]
        n = normal_de(pts)
        c = sum(pts, Vector((0, 0, 0))) / len(pts)
        muestras = [c] + [c.lerp(p, 0.85) for p in pts]
        doble = cara[1] in ("hoja", "tela")
        visto = False
        for ic, (cp, ad, arr, der) in enumerate(cams):
            if (c - cp).length > alcance:
                continue
            for q in muestras:
                d = q - cp
                if not doble and n.dot(-d) <= 0.0:
                    continue
                prof = d.dot(ad)
                if prof <= 0.1:
                    continue
                if abs(d.dot(arr)) / prof > tf or abs(d.dot(der)) / prof > tf * CAM_ASPECTO:
                    continue
                L = d.length
                hit = bvh.ray_cast(cp, d / L, L + 0.01)
                if hit[0] is None or hit[2] == idx or hit[3] >= L - 0.02:
                    visto = True
                    vio[ic] = True
                    break
            if visto:
                break
        (vis if visto else ocu).caras.append(cara)
    return vis, ocu, vio


# ======== (de crear_calle.py, l. 1689-1722: sondas)
# ---------------------------------------------------------------- sondas de luz para Kael

def sondas(bvh, hs, rect, altura_suelo, paso=0.25):
    """(barrio) rect = (x0, z0, ancho, fondo) del sector; altura_suelo(x, z) la del trazado. bvh en coordenadas de
    Blender (como en la muestra)."""
    x0, z0 = rect[0], rect[1]
    x1, z1 = rect[0] + rect[2], rect[1] + rect[3]
    nx, nz = int(round((x1 - x0) / paso)) + 1, int(round((z1 - z0) / paso)) + 1
    sol, cielo = [], []
    rng = random.Random(3)
    dirs_cielo = []
    for k in range(24):                                   # coseno sobre el hemisferio de arriba
        u, v = (k + 0.5) / 24, (k * 0.618034) % 1.0
        r = math.sqrt(u)
        a = math.tau * v
        dirs_cielo.append(Vector((r * math.cos(a), math.sqrt(1 - u), r * math.sin(a))))
    t1 = hs.cross(Vector((0, 1, 0))).normalized()
    t2 = hs.cross(t1).normalized()
    rad = math.tan(math.radians(SOL_ANGULO) * 0.5)
    dirs_sol = [(hs + t1 * rad * math.cos(k * 1.3) * (k / 7) + t2 * rad * math.sin(k * 1.3) * (k / 7)).normalized()
                for k in range(8)]
    for j in range(nz):
        for i in range(nx):
            x, z = x0 + i * paso, z0 + j * paso
            p = Vector((x, altura_suelo(x, z) + 1.0, z))
            pb = Vector((x, -z, p.y))                      # Blender
            s = 0
            for d in dirs_sol:
                if bvh.ray_cast(pb, Vector((d.x, -d.z, d.y)), 200.0)[0] is None:
                    s += 1
            c = 0
            for d in dirs_cielo:
                if bvh.ray_cast(pb, Vector((d.x, -d.z, d.y)), 60.0)[0] is None:
                    c += 1
            sol.append(round(s / len(dirs_sol), 3))
            cielo.append(round(c / len(dirs_cielo), 3))
    return {"origen": [x0, z0], "paso": paso, "nx": nx, "nz": nz, "altura": 1.0, "sol": sol, "cielo": cielo}


# ======== (de crear_calle.py, l. 1725-1813: cycles)
# ---------------------------------------------------------------- escena de horneado, horneado y exportación

def preparar_cycles(anclas):
    """(barrio) anclas: las de TODOS los sectores (nombre → (x, y, z) Godot): sus faroles alumbran el horneado de cada
    sector, también el borde del vecino."""
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    pr = bpy.context.preferences.addons['cycles'].preferences
    for t in ('OPTIX', 'CUDA'):
        try:
            pr.compute_device_type = t
            pr.get_devices()
            hay = False
            for d in pr.devices:
                d.use = d.type == t
                hay = hay or d.use
            if hay:
                sc.cycles.device = 'GPU'
                nota("Cycles con %s" % t)
                break
        except Exception as e:
            nota("sin %s: %s" % (t, e))
    sc.cycles.samples = MUESTRAS
    sc.cycles.use_denoising = False
    sc.cycles.max_bounces = 4
    sc.cycles.diffuse_bounces = 3
    sc.cycles.glossy_bounces = 0
    sc.cycles.transparent_max_bounces = 2
    sc.cycles.sample_clamp_indirect = 6.0
    w = sc.world or bpy.data.worlds.new("Mundo")
    sc.world = w
    w.use_nodes = True
    bg = w.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (*CIELO_COLOR, 1.0)
    bg.inputs["Strength"].default_value = CIELO_FUERZA
    sd = bpy.data.lights.new("Sol", 'SUN')
    sd.energy = SOL_FUERZA
    sd.color = SOL_COLOR
    sd.angle = math.radians(SOL_ANGULO)
    so = bpy.data.objects.new("Sol", sd)
    hs = hacia_sol()
    so.rotation_euler = Vector((hs.x, -hs.z, hs.y)).to_track_quat('Z', 'Y').to_euler()
    sc.collection.objects.link(so)
    for k, p in anclas.items():                            # la luz cálida de los faroles y de la hornacina
        tipo = k.split("/")[-1]
        if tipo.startswith(("farol_", "candil_", "hornacina", "brasa_")):
            ld = bpy.data.lights.new(k, 'POINT')
            ld.energy = 30.0 if tipo.startswith("farol_") else (14.0 if tipo.startswith("brasa_") else 8.0)
            ld.color = (1.0, 0.62, 0.30)
            ld.shadow_soft_size = 0.08
            lo = bpy.data.objects.new(k + "_luz", ld)
            lo.location = (p[0], -p[2], p[1])
            sc.collection.objects.link(lo)


def calibrar():
    """Cuánto vale en el mapa de luz el sol de frente (sin cielo) y el cielo en una pared vertical: dos placas lejos,
    horneadas aparte (Kael se ilumina con estos números)."""
    hs = hacia_sol()
    res = {}
    for nombre, nrm in (("frente", hs), ("espalda", Vector((-hs.x, 0.0, -hs.z)).normalized())):
        me = bpy.data.meshes.new("cal_" + nombre)
        t1 = nrm.cross(Vector((0, 1, 0)) if abs(nrm.y) < 0.9 else Vector((1, 0, 0))).normalized()
        t2 = nrm.cross(t1).normalized()
        c = Vector((400.0 + len(res) * 10, 50.0, 0.0))
        pts = [c - t1 - t2, c + t1 - t2, c + t1 + t2, c - t1 + t2]
        if (pts[1] - pts[0]).cross(pts[2] - pts[0]).dot(nrm) < 0:
            pts.reverse()
        me.from_pydata([(p.x, -p.z, p.y) for p in pts], [], [[0, 1, 2, 3]])
        me.uv_layers.new(name="UVMap")
        uv = me.uv_layers.new(name="luz")
        uv.data.foreach_set("uv", [0.1, 0.1, 0.9, 0.1, 0.9, 0.9, 0.1, 0.9])
        me.uv_layers.active = uv
        img = bpy.data.images.new("cal_" + nombre, 16, 16, float_buffer=True)
        mt = bpy.data.materials.new("cal_" + nombre)
        mt.use_nodes = True
        tn = mt.node_tree.nodes.new("ShaderNodeTexImage")
        tn.image = img
        mt.node_tree.nodes.active = tn
        me.materials.append(mt)
        ob = bpy.data.objects.new("cal_" + nombre, me)
        bpy.context.scene.collection.objects.link(ob)
        bpy.ops.object.select_all(action='DESELECT')
        ob.select_set(True)
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.bake(type='DIFFUSE', pass_filter={'DIRECT', 'INDIRECT'}, margin=0, target='IMAGE_TEXTURES',
                            use_clear=True)
        px = np.array(img.pixels[:], np.float32).reshape(16, 16, 4)
        res[nombre] = px[4:12, 4:12, :3].reshape(-1, 3).mean(0).tolist()
        bpy.data.objects.remove(ob)
    nota("calibración: de frente %s · de espalda %s" % (res["frente"], res["espalda"]))
    return res


# ======== (de crear_calle.py, l. 1816-1929: hornear)
def hornear(ob_vis, ob_veg, nombre_img):
    """(barrio) Hornea el objeto fijo de UN sector en la imagen «nombre_img» (que los materiales tienen en su nodo LUZ,
    activo) y sus piezas y vegetación a los vértices (capa «LuzV»); los demás sectores, en la escena, tapan y rebotan."""
    sc = bpy.context.scene
    # 1) UV del mapa de luz (todas las islas juntas)
    me = ob_vis.data
    me.uv_layers.active = me.uv_layers["luz"]
    bpy.ops.object.select_all(action='DESELECT')
    ob_vis.select_set(True)
    bpy.context.view_layer.objects.active = ob_vis
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.0015, area_weight=0.0, correct_aspect=True,
                             scale_to_bounds=False)
    try:
        bpy.ops.uv.pack_islands(udim_source='CLOSEST_UDIM', rotate=True, margin=0.0015)
    except Exception as e:
        nota("pack_islands: %s" % e)
    bpy.ops.object.mode_set(mode='OBJECT')
    nota("UV del mapa de luz hechas")
    # 2) horneado del mapa de luz (difusa directa + indirecta, sin el color)
    img = bpy.data.images[nombre_img]
    sc.render.bake.margin = 6
    sc.render.bake.margin_type = 'EXTEND'
    bpy.ops.object.bake(type='DIFFUSE', pass_filter={'DIRECT', 'INDIRECT'}, margin=6, target='IMAGE_TEXTURES',
                        use_clear=True)
    nota("mapa de luz horneado (%d muestras)" % MUESTRAS)
    # 3) la vegetación y las piezas (losas, barriles, cajones…), a sus vértices
    bpy.ops.object.select_all(action='DESELECT')
    for ob in ob_veg:
        vm = ob.data
        luzc = vm.color_attributes.new("LuzV", 'FLOAT_COLOR', 'CORNER')
        vm.color_attributes.active_color = luzc
        ob.select_set(True)
        bpy.context.view_layer.objects.active = ob
    bpy.ops.object.bake(type='DIFFUSE', pass_filter={'DIRECT', 'INDIRECT'}, target='VERTEX_COLORS', use_clear=True)
    nota("vegetación y piezas horneadas a los vértices")


def escala_y_guardar(img, carpeta, objs_vertice, escala, prefijo):
    """(barrio) La escala es COMÚN (la de la muestra; se pasa): el percentil del sector se devuelve solo para el registro.
    Escribe <prefijo>_luz_<res>.png y <prefijo>_luz_<res/2>.png."""
    w, h = img.size
    px = np.array(img.pixels[:], np.float32).reshape(h, w, 4)
    lum = px[..., :3].max(-1)
    validos = lum[lum > 0.0005]
    propia = float(np.percentile(validos, 99.7)) / 0.97 if validos.size else 1.0
    out = {}
    for res in (w, w // 2):
        nombre = "%s_luz_%d" % (prefijo, res)
        q = np.clip(px[..., :3] / escala, 0, 1) ** (1 / 2.2)
        im2 = bpy.data.images.new(nombre, w, h, alpha=False)
        a = np.ones((h, w, 4), np.float32)
        a[..., :3] = q
        im2.pixels.foreach_set(a.ravel())
        if res != w:
            im2.scale(res, res)
        im2.filepath_raw = os.path.join(carpeta, nombre + ".png")
        im2.file_format = 'PNG'
        im2.save()
        out[res] = nombre
    escala_vertices(objs_vertice, escala)
    return propia


def escala_vertices(objs_vertice, escala):
    """(barrio) La vegetación y las piezas: tinte × luz / escala (la parte de escala_y_guardar de la muestra)."""
    for ob in objs_vertice:
        vm = ob.data
        col = vm.color_attributes["Col"]
        luz = vm.color_attributes["LuzV"]
        n = len(col.data)
        c = np.zeros(n * 4, np.float32)
        l = np.zeros(n * 4, np.float32)
        col.data.foreach_get("color", c)
        luz.data.foreach_get("color", l)
        c = c.reshape(n, 4)
        l = l.reshape(n, 4)
        # (15/11, revisión) las esquinas de lo que da luz («brillo»: los cristales de los faroles de pie) no se
        # multiplican por la luz horneada: su Base Color es negro y el horneado las dejaba a 0 (cristales negros).
        idx_brillo = [i for i, mt in enumerate(vm.materials) if mt is not None and mt.name == "brillo"]
        if idx_brillo:
            mat_pol = np.zeros(len(vm.polygons), np.int32)
            vm.polygons.foreach_get("material_index", mat_pol)
            mat_esq = np.zeros(len(vm.loops), np.int32)
            for p in vm.polygons:
                mat_esq[p.loop_start:p.loop_start + p.loop_total] = mat_pol[p.index]
            mantener = np.isin(mat_esq, idx_brillo)
        else:
            mantener = np.zeros(n, bool)
        # (barrio) sin luciérnagas: una esquina que vio el sol por un resquicio (ruido del horneado en caras pequeñas,
        # sobre todo en sombra) se baja a 2 × la mediana de las esquinas de su cara (+0,05); el degradado de la base a la
        # punta de las matas se conserva.
        lum = l[:, :3].max(1)
        ini = np.zeros(len(vm.polygons), np.int32)
        tot = np.zeros(len(vm.polygons), np.int32)
        vm.polygons.foreach_get("loop_start", ini)
        vm.polygons.foreach_get("loop_total", tot)
        tope = np.full(n, np.inf, np.float32)
        for a, t in zip(ini, tot):
            tope[a:a + t] = 2.0 * float(np.median(lum[a:a + t])) + 0.05
        f = np.where(lum > tope, tope / np.maximum(lum, 1e-6), 1.0)
        l[:, :3] *= f[:, None]
        if mantener.any():
            l[mantener, :3] = escala
        c[:, :3] = np.clip(c[:, :3] * l[:, :3] / escala, 0, 1)
        col.data.foreach_set("color", c.ravel())
        vm.color_attributes.remove(luz)
        vm.color_attributes.active_color = vm.color_attributes["Col"]


def exportar(objs, ruta):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=ruta, export_format='GLB', use_selection=True, export_animations=False,
                              export_yup=True, export_vertex_color='ACTIVE', export_all_vertex_colors=False,
                              export_cameras=False, export_lights=False, export_apply=True, export_texcoords=True,
                              export_normals=True, export_image_format='NONE', export_materials='EXPORT')
    nota("EXPORTADO %s" % ruta)


def vacios(sector):
    """(barrio) Los vacíos de un sector: «choque_<nombre>» (escala = medio tamaño; nombre del bloque del trazado o
    «<sector>_p<n>» para las piezas sueltas en lo andable) y «ancla_<sector>_<nombre>»."""
    objs = []
    for k, (c, s, yaw, nombre) in enumerate(sector.choques):
        e = bpy.data.objects.new("choque_" + (nombre or "%s_p%03d" % (sector.nombre, k)), None)
        e.empty_display_type = 'CUBE'
        e.location = (c[0], -c[2], c[1])
        e.scale = (s[0] / 2, s[2] / 2, s[1] / 2)
        e.rotation_euler = (0, 0, math.radians(yaw))
        bpy.context.scene.collection.objects.link(e)
        objs.append(e)
    for k, p in sector.anclas.items():
        e = bpy.data.objects.new("ancla_%s_%s" % (sector.nombre, k), None)
        e.location = (p[0], -p[2], p[1])
        bpy.context.scene.collection.objects.link(e)
        objs.append(e)
    return objs
