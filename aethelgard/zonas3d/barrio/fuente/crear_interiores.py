# BARRIO EXPERIMENTAL de Oakhaven (V12, 16/11, EN PRUEBAS: solo desde el banco de pruebas de Auditoría): LOS TRES
# INTERIORES (agente B). Geometría procedural propia, texturas de la muestra de la calle (las mismas, sin copiar) y luz
# horneada con Cycles, como zonas3d/muestra_calle/fuente/crear_calle.py (que NO se toca ni se importa: llama a main() sin
# guarda). Cuando exista el kit común del agente A (fuente/kit_barrio.py), las funciones de la sección «kit» de aquí se
# pueden cambiar por las suyas sin tocar los tres interiores. Ningún recurso descargado, de pago ni de la nube.
#
#   blender -b --factory-startup -P crear_interiores.py -- <carpeta zonas3d/barrio> [opciones]
#     --solo horno|taller|vivienda    solo ese interior (por defecto los tres)
#     --sin-horneado                  sin luz (para ver la composición deprisa: el mapa sale gris)
#     --muestras N                    muestras de Cycles del horneado (por defecto 768)
#
# Cada interior es una «casa de muñecas»: sin techo ni muro sur a la vista (la cámara de interior mira al norte desde
# arriba y nunca gira), con un murete bajo al sur y su puerta. El techo y el muro sur SÍ están en el horneado (objeto
# «oculto», que no se exporta): tapan el cielo y dejan entrar la luz solo por las ventanas y la puerta, así que dentro
# hay luz de interior (rincones oscuros, el sol de la tarde en el suelo, el resplandor del horno y del hogar).
#
# Escribe (en <carpeta>):
#   modelos/int_<id>.glb            el interior en coordenadas LOCALES (x al este, y arriba, z al sur; la esquina
#                                    noroeste del suelo en 0): interiores.gd lo pone en su ORIGEN.
#     objeto «fijo»                  muros, suelos y muebles grandes: una superficie por material, UV0 textura, UV1 mapa
#                                    de luz, COLOR_0 tinte (lineal)
#     objeto «piezas»                lo pequeño (panes, herramientas, cacharros, virutas): COLOR_0 = tinte × luz en los
#                                    vértices / ESCALA (como las piezas de la calle)
#     objeto «hoja_trastienda»       (taller) la puerta de la trastienda, con su origen en la bisagra (gira en Godot)
#   modelos/int_<id>_luz_1024.png   mapa de luz (luz / ESCALA, gamma 2,2)
#   interiores/<id>.json            lo que usa interiores.gd: tamaño, suelo, bloqueos, pasos internos, alturas, choques,
#                                    anclas «int_<id>_*», objetos (examinable / ofrecido / privado), fuegos, sondas, la
#                                    escala de la luz y los triángulos.
import bpy, bmesh, sys, os, math, random, json, time
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree
import numpy as np

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
CARPETA = argv[0] if argv and not argv[0].startswith("--") else ""
SOLO = ""
HORNEAR = True
MUESTRAS = 768
RES = 1024
i = 0
while i < len(argv):
    a = argv[i]
    if a == "--solo":
        SOLO = argv[i + 1]; i += 1
    elif a == "--sin-horneado":
        HORNEAR = False
    elif a == "--muestras":
        MUESTRAS = int(argv[i + 1]); i += 1
    i += 1
T0 = time.time()


def nota(t):
    print("[interiores %6.1f s] %s" % (time.time() - T0, t), flush=True)


RND = random.Random(1611)

# ---------------------------------------------------------------- luz (el mismo sol de la tarde que la calle)
SOL_ELEVACION = 24.0
SOL_RUMBO = 252.0                           # desde el oeste-suroeste
SOL_COLOR = (1.0, 0.80, 0.58)
SOL_FUERZA = 6.5
SOL_ANGULO = 1.2
CIELO_COLOR = (0.48, 0.58, 0.86)
CIELO_FUERZA = 0.6
FUEGO = (1.0, 0.52, 0.22)
VELA = (1.0, 0.66, 0.34)


def hacia_sol():
    e, r = math.radians(SOL_ELEVACION), math.radians(SOL_RUMBO)
    return Vector((math.sin(r) * math.cos(e), math.sin(e), -math.cos(r) * math.cos(e))).normalized()


# ---------------------------------------------------------------- cámara de interior (= interiores.gd)
CAM_ALTO, CAM_SUR, CAM_FOV = 6.2, 7.2, 44.0
CAM_INCL = math.degrees(math.atan2(CAM_ALTO, CAM_SUR))
CAM_ASPECTO = 1600.0 / 720.0

# ---------------------------------------------------------------- colores (sRGB; se pasan a lineal al guardar)
MADERA_OSC = (0.40, 0.27, 0.19)
MADERA = (0.58, 0.42, 0.30)
MADERA_CLARA = (0.74, 0.60, 0.44)
MADERA_GRIS = (0.60, 0.56, 0.50)
FRESNO = (0.84, 0.74, 0.58)
HIERRO = (0.20, 0.19, 0.20)
LATON = (0.80, 0.62, 0.32)
AZUL_POSTIGO = (0.30, 0.50, 0.60)
VERDE_POSTIGO = (0.30, 0.46, 0.36)
PAN = ((0.70, 0.44, 0.22), (0.76, 0.50, 0.26), (0.64, 0.38, 0.19), (0.80, 0.56, 0.30))
MIMBRE = (0.74, 0.58, 0.36)
SACO = (0.93, 0.88, 0.76)
HARINA = (0.96, 0.94, 0.88)
BARRO_COCIDO = ((0.70, 0.47, 0.37), (0.66, 0.44, 0.35), (0.74, 0.51, 0.39), (0.63, 0.42, 0.34))
LADRILLO = ((0.68, 0.36, 0.25), (0.62, 0.32, 0.22), (0.72, 0.40, 0.28))
PIEDRA = ((0.66, 0.63, 0.58), (0.60, 0.58, 0.55), (0.71, 0.67, 0.61), (0.56, 0.53, 0.50))
TELAS = [(0.92, 0.90, 0.84), (0.52, 0.66, 0.80), (0.86, 0.42, 0.34), (0.94, 0.82, 0.52), (0.62, 0.74, 0.56)]
TIZNE = (0.16, 0.13, 0.11)
PINTURA = (0.50, 0.24, 0.16)                # la silueta pintada (almagre) de las herramientas en la pared del taller


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


def suave(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


MATS = ["piedra", "tierra", "revoque", "madera", "sillar", "tela", "barro", "hierro", "brillo"]
ESCALA_UV = {"piedra": 0.9, "tierra": 2.4, "revoque": 2.2, "madera": 1.3, "sillar": 1.6, "tela": 0.7, "barro": 0.8,
             "hierro": 1.0, "brillo": 1.0}
TEX_DE = {"piedra": "piedra", "tierra": "tierra", "revoque": "revoque", "madera": "madera", "sillar": "sillar",
          "tela": "tela", "barro": "revoque", "hierro": "piedra", "brillo": None}


# ================================================================ kit (cambiable por fuente/kit_barrio.py de A)

class Malla:
    def __init__(self):
        self.caras = []      # [puntos (Vector Godot), material, colores RGBA lineales, uvs o None, suave]

    def cara(self, pts, mat, col, uvs=None, suave=False):
        if callable(col):
            cols = [col(Vector(p)) for p in pts]
        else:
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


CARAS_CAJA = {
    "e": ((1, 0, 0), [(1, -1, -1), (1, 1, -1), (1, 1, 1), (1, -1, 1)]),
    "o": ((-1, 0, 0), [(-1, -1, -1), (-1, -1, 1), (-1, 1, 1), (-1, 1, -1)]),
    "a": ((0, 1, 0), [(-1, 1, -1), (-1, 1, 1), (1, 1, 1), (1, 1, -1)]),
    "b": ((0, -1, 0), [(-1, -1, -1), (1, -1, -1), (1, -1, 1), (-1, -1, 1)]),
    "s": ((0, 0, 1), [(-1, -1, 1), (1, -1, 1), (1, 1, 1), (-1, 1, 1)]),
    "n": ((0, 0, -1), [(-1, -1, -1), (-1, 1, -1), (1, 1, -1), (1, -1, -1)]),
}


def caja(M, c, s, mat, col, rot=None, veta=None, jit_v=0.0, caras="eoasnb", suave=False):
    """Caja de centro c y tamaño s (Godot), girada por rot. col: color o función punto → color."""
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
            eu, ev = (ejes[0], ejes[1]) if s[ejes[1]] >= s[ejes[0]] else (ejes[1], ejes[0])
            uvs = [((l[eu] + off[0]) / e, (l[ev] + off[1]) / e) for l in loc]
        M.cara(pts, mat, col, uvs, suave)


def caja_mm(M, a, b, mat, col, **k):
    a, b = Vector(a), Vector(b)
    caja(M, (a + b) * 0.5, b - a, mat, col, **k)


def placa(M, pts2, origen, eu, ev, grosor, mat, col, frente=True, lados=True, atras=False):
    """Un polígono 2D (en los ejes eu, ev desde origen) extruido «grosor» hacia eu × ev (el frente)."""
    o, eu, ev = Vector(origen), Vector(eu), Vector(ev)
    n = eu.cross(ev).normalized()
    fr = [o + eu * p[0] + ev * p[1] + n * grosor for p in pts2]
    at = [o + eu * p[0] + ev * p[1] for p in pts2]
    e = ESCALA_UV.get(mat, 1.0)
    if frente:
        M.cara(fr, mat, col, [(p[0] / e, -p[1] / e) for p in pts2])
    if atras:
        M.cara(list(reversed(at)), mat, col, None)
    if lados:
        for k in range(len(pts2)):
            a0, a1 = at[k], at[(k + 1) % len(pts2)]
            f0, f1 = fr[k], fr[(k + 1) % len(pts2)]
            M.cara([a0, a1, f1, f0], mat, col, None)


def cilindro(M, base, perfil, n, mat, col, rot=None, tapa_arriba=True, tapa_abajo=False, suave=True, fase=0.0):
    """Sólido de revolución: perfil = [(y, radio)] de abajo arriba, n lados, eje y local girado por rot."""
    base = Vector(base)
    rot = rot or Matrix.Identity(3)
    e = ESCALA_UV.get(mat, 1.0)
    anillos = []
    for y, r in perfil:
        anillos.append([base + rot @ Vector((math.cos(fase + k * math.tau / n) * r, y, math.sin(fase + k * math.tau / n) * r))
                        for k in range(n)])
    for j in range(len(perfil) - 1):
        circ = math.tau * max(perfil[j][1], perfil[j + 1][1])
        for k in range(n):
            k1 = (k + 1) % n
            pts = [anillos[j][k], anillos[j][k1], anillos[j + 1][k1], anillos[j + 1][k]]
            uvs = [(k / n * circ / e, -perfil[j][0] / e), ((k + 1) / n * circ / e, -perfil[j][0] / e),
                   ((k + 1) / n * circ / e, -perfil[j + 1][0] / e), (k / n * circ / e, -perfil[j + 1][0] / e)]
            M.cara(list(reversed(pts)), mat, col, list(reversed(uvs)), suave)
    if tapa_arriba and perfil[-1][1] > 0.001:
        M.cara(list(reversed(anillos[-1])), mat, col, None, False)
    if tapa_abajo and perfil[0][1] > 0.001:
        M.cara(anillos[0], mat, col, None, False)


def viga(M, a, b, grueso, mat, col, alto=None, jit_v=0.0):
    a, b = Vector(a), Vector(b)
    d = b - a
    largo = d.length
    ez = d.normalized()
    ref = Vector((0, 1, 0)) if abs(ez.y) < 0.95 else Vector((1, 0, 0))
    ex = ref.cross(ez).normalized()
    ey = ez.cross(ex).normalized()
    rot = Matrix((ex, ey, ez)).transposed()
    caja(M, (a + b) * 0.5, (grueso, alto or grueso, largo), mat, col, rot=rot, veta="larga", jit_v=jit_v)


def rot_eje(eje):
    """La rotación que lleva el eje y local al eje dado ('x', 'z' o 'y')."""
    return {"x": R(z=-90), "z": R(x=90), "y": Matrix.Identity(3)}[eje]


# ---------------------------------------------------------------- suelos (una sola isla de luz: rejilla soldada)

def rejilla(M, x0, z0, x1, z1, y, paso_x, paso_z, junta, mat, col_pieza, col_junta, desfase=(0.0, 0.0)):
    """Baldosas o tablas en el plano y: piezas de paso_x × paso_z con juntas de «junta», todo coplanario y soldado (el
    mapa de luz lo ve como una sola isla). col_pieza(ix, iz, centro) → color."""
    def cortes(a0, a1, paso, d):
        """[(inicio, fin, es_junta, índice de pieza)] a lo largo de un eje."""
        segs = []
        pos = a0
        k = math.floor((a0 - d) / paso) + 1
        while pos < a1 - 1e-6:
            borde = d + k * paso
            j0, j1 = borde - junta * 0.5, borde + junta * 0.5
            fin = min(j0, a1) if junta > 0 else min(borde, a1)
            if fin > pos + 1e-6:
                segs.append((pos, fin, False, k - 1))
            if junta > 0 and j0 < a1 - 1e-6:
                s0, s1 = max(j0, pos), min(j1, a1)
                if s1 > s0 + 1e-6:
                    segs.append((s0, s1, True, k))
            pos = max(pos, j1 if junta > 0 else borde)
            k += 1
        return segs
    for ax, bx, jx, ix in cortes(x0, x1, paso_x, desfase[0]):
        for az, bz, jz, iz in cortes(z0, z1, paso_z, desfase[1]):
            pts = [Vector((ax, y, az)), Vector((ax, y, bz)), Vector((bx, y, bz)), Vector((bx, y, az))]
            if jx or jz:
                M.cara(pts, mat, col_junta)
            else:
                M.cara(pts, mat, col_pieza(ix, iz, Vector(((ax + bx) * 0.5, y, (az + bz) * 0.5))))


# ---------------------------------------------------------------- muros con huecos

def tramo_muro(M, lado, a0, a1, y0, y1, huecos, mat, col, W, D, grueso=0.3):
    """El muro del lado ('n', 'o', 'e', 's') entre a0 y a1 (x en n/s, z en o/e) y entre y0 e y1, con los huecos
    [(a0, a1, y0, y1)] que caen dentro. El muro va POR FUERA de la sala (su cara de dentro está en el borde)."""
    cortes = {a0, a1}
    for h in huecos:
        for v in (h[0], h[1]):
            if a0 < v < a1:
                cortes.add(v)
    cortes = sorted(cortes)
    for k in range(len(cortes) - 1):
        c0, c1 = cortes[k], cortes[k + 1]
        m = (c0 + c1) * 0.5
        tramos = [(y0, y1)]
        for h in huecos:
            if h[0] <= m <= h[1]:
                nuevos = []
                for (ya, yb) in tramos:
                    if h[3] <= ya or h[2] >= yb:
                        nuevos.append((ya, yb))
                        continue
                    if h[2] > ya:
                        nuevos.append((ya, h[2]))
                    if h[3] < yb:
                        nuevos.append((h[3], yb))
                tramos = nuevos
        for ya, yb in tramos:
            if yb - ya < 0.005:
                continue
            if lado == "n":
                caja_mm(M, (c0, ya, -grueso), (c1, yb, 0.0), mat, col)
            elif lado == "s":
                caja_mm(M, (c0, ya, D), (c1, yb, D + grueso), mat, col)
            elif lado == "o":
                caja_mm(M, (-grueso, ya, c0), (0.0, yb, c1), mat, col)
            else:
                caja_mm(M, (W, ya, c0), (W + grueso, yb, c1), mat, col)


def tono_muro(base, alto, sucio=0.14, humo=0.10, zona_humo=None):
    """Color de muro que se oscurece al pie (roce, polvo) y arriba (humo), con humo más fuerte cerca de zona_humo."""
    def f(p):
        k = 1.0 - sucio * (1.0 - suave(0.0, 0.45, p.y)) - humo * suave(alto - 1.4, alto, p.y)
        if zona_humo is not None:
            d = Vector((p.x - zona_humo[0], p.z - zona_humo[1])).length
            k -= zona_humo[2] * (1.0 - suave(0.0, zona_humo[3], d)) * suave(1.2, 2.6, p.y)
        return tuple(max(0.0, c * k) for c in base)
    return f


# ================================================================ la sala (lo común de los tres interiores)

class Sala:
    def __init__(self, id, W, D, H):
        self.id, self.W, self.D, self.H = id, W, D, H
        self.M, self.P, self.O = Malla(), Malla(), Malla()     # fijo (mapa de luz), piezas (vértices), oculto
        self.extra = {}                                         # objetos aparte: nombre → (Malla, origen)
        self.huecos = {"n": [], "o": [], "e": [], "s": []}
        self.anclas = {}
        self.bloqueos = []
        self.suelo = [[0.3, 0.3, W - 0.6, D - 0.45]]
        self.pasos = {}
        self.niveles = []                                       # [x, z, w, h, y]: el suelo a otra altura
        self.choques = [[W * 0.5, -0.1, D * 0.5, W + 1.0, 0.2, D + 1.0]]
        self.luces = []                                         # [x, y, z, vatios, color, radio]
        self.fuegos = []                                        # [x, y, z, fuerza] (para las sondas)
        self.objetos = []
        self.camara = {}
        self.techos = [[0.0, 0.0, W, D, H]]
        self.sitios = {}                                        # utensilios de sitio (copias que pone Godot)

    def ancla(self, nombre, x, y, z):
        self.anclas["int_%s_%s" % (self.id, nombre)] = [round(x, 3), round(y, 3), round(z, 3)]

    def bloqueo(self, x0, z0, x1, z1, m=0.25):
        self.bloqueos.append([round(x0 - m, 3), round(z0 - m, 3), round(x1 - x0 + 2 * m, 3), round(z1 - z0 + 2 * m, 3)])

    def objeto(self, nombre, clase, que):
        self.objetos.append({"ancla": "int_%s_%s" % (self.id, nombre), "clase": clase, "que": que})

    def hueco(self, lado, a0, a1, y0, y1):
        self.huecos[lado].append((a0, a1, y0, y1))

    def luz(self, x, y, z, w, color=FUEGO, radio=0.12, fuego=0.0):
        self.luces.append([x, y, z, w, color, radio])
        if fuego > 0:
            self.fuegos.append([x, y, z, fuego])


def pared(S, lado, a0, a1, alto, zocalo, mat_z, col_z, mat_r, col_r, desde=0.0):
    tramo_muro(S.M, lado, a0, a1, desde, zocalo, S.huecos[lado], mat_z, col_z, S.W, S.D)
    tramo_muro(S.M, lado, a0, a1, zocalo, alto, S.huecos[lado], mat_r, col_r, S.W, S.D)


def murete_sur(S, alto, puerta, mat, col):
    """El murete de la casa de muñecas (lo que se ve del muro sur) con la puerta, y el resto del muro sur y el techo
    para el horneado (oculto)."""
    hueco = [(puerta[0], puerta[1], -1.0, 9.0)] if puerta else []
    base = col if callable(col) else (lambda p, c=col: c)
    corte = lambda p: tuple(c * 0.5 for c in base(p)) if p.z > S.D + 0.2 else base(p)
    tramo_muro(S.M, "s", -0.3, S.W + 0.3, 0.0, alto, hueco, mat, corte, S.W, S.D)
    tramos = [(-0.32, puerta[0]), (puerta[1], S.W + 0.32)] if puerta else [(-0.32, S.W + 0.32)]
    for a, b in tramos:                                                  # la albardilla (sin cruzar la puerta)
        caja_mm(S.M, (a, alto, S.D - 0.02), (b, alto + 0.06, S.D + 0.32), "sillar", (0.64, 0.59, 0.52))
    if puerta:
        caja_mm(S.M, (puerta[0], 0.0, S.D - 0.05), (puerta[1], 0.035, S.D + 0.3), "sillar", (0.74, 0.70, 0.62))   # umbral
    tramo_muro(S.O, "s", -0.3, S.W + 0.3, alto + 0.06, S.H + 0.3, S.huecos["s"], "revoque", (0.8, 0.75, 0.66), S.W, S.D)
    for x0, z0, x1, z1, y in S.techos:
        caja_mm(S.O, (x0 - 0.3, y, z0 - 0.3), (x1 + 0.3, y + 0.25, z1 + 0.3), "madera", MADERA_OSC)
    caja_mm(S.O, (-25.0, -0.25, -25.0), (S.W + 25.0, -0.02, S.D + 25.0), "tierra", (0.66, 0.56, 0.44))   # la calle


def ventana(S, lado, a0, a1, y0, y1, postigo=AZUL_POSTIGO, rejas=True):
    """Un hueco con su marco, su alféizar, una cruz de madera y los postigos abiertos contra el muro (por dentro)."""
    S.hueco(lado, a0, a1, y0, y1)
    M = S.M
    W, D = S.W, S.D
    am = (a0 + a1) * 0.5
    ancho = a1 - a0

    def P(a, y, d):            # a lo largo del muro, altura, hacia dentro (d > 0 entra en la sala)
        if lado == "n":
            return Vector((a, y, d))
        if lado == "s":
            return Vector((a, y, D - d))
        if lado == "o":
            return Vector((d, y, a))
        return Vector((W - d, y, a))

    def caja_m(a_0, a_1, y_0, y_1, d_0, d_1, mat, col):
        p, q = P(a_0, y_0, d_0), P(a_1, y_1, d_1)
        caja_mm(M, (min(p.x, q.x), min(p.y, q.y), min(p.z, q.z)), (max(p.x, q.x), max(p.y, q.y), max(p.z, q.z)), mat, col,
                veta="larga")
    m = 0.07
    caja_m(a0 - m, a0, y0 - m, y1 + m, -0.3, 0.04, "madera", MADERA_OSC)
    caja_m(a1, a1 + m, y0 - m, y1 + m, -0.3, 0.04, "madera", MADERA_OSC)
    caja_m(a0, a1, y1, y1 + m, -0.3, 0.04, "madera", MADERA_OSC)
    caja_m(a0 - 0.1, a1 + 0.1, y0 - 0.06, y0, -0.3, 0.12, "madera", MADERA)              # alféizar
    if rejas:
        caja_m(am - 0.025, am + 0.025, y0, y1, -0.18, -0.13, "madera", MADERA_OSC)
        caja_m(a0, a1, (y0 + y1) * 0.5 - 0.025, (y0 + y1) * 0.5 + 0.025, -0.18, -0.13, "madera", MADERA_OSC)
    if postigo is not None:
        h = ancho * 0.5
        for lado_p in (-1, 1):
            b0 = a0 - m - h if lado_p < 0 else a1 + m
            caja_m(b0, b0 + h, y0, y1, 0.0, 0.035, "madera", jit(postigo, 0.04))
            caja_m(b0 + 0.04, b0 + h - 0.04, y0 + 0.08, y0 + 0.13, 0.035, 0.05, "madera", jit(postigo, 0.06))
            caja_m(b0 + 0.04, b0 + h - 0.04, y1 - 0.13, y1 - 0.08, 0.035, 0.05, "madera", jit(postigo, 0.06))


# ---------------------------------------------------------------- muebles y cosas

def mesa(M, x0, z0, x1, z1, alto, col=MADERA, grueso=0.06):
    caja_mm(M, (x0, alto - grueso, z0), (x1, alto, z1), "madera", jit(col), veta="larga")
    for x, z in ((x0 + 0.08, z0 + 0.08), (x1 - 0.08, z0 + 0.08), (x0 + 0.08, z1 - 0.08), (x1 - 0.08, z1 - 0.08)):
        caja(M, (x, (alto - grueso) * 0.5, z), (0.07, alto - grueso, 0.07), "madera", jit(mezcla(col, MADERA_OSC, 0.3)), veta="larga")
    caja_mm(M, (x0 + 0.05, alto - grueso - 0.1, z0 + 0.06), (x1 - 0.05, alto - grueso, z0 + 0.09), "madera", jit(col), veta="larga")
    caja_mm(M, (x0 + 0.05, alto - grueso - 0.1, z1 - 0.09), (x1 - 0.05, alto - grueso, z1 - 0.06), "madera", jit(col), veta="larga")


def banco(M, x0, z0, x1, z1, alto=0.45, col=MADERA):
    caja_mm(M, (x0, alto - 0.05, z0), (x1, alto, z1), "madera", jit(col), veta="larga")
    for x in (x0 + 0.1, x1 - 0.1):
        caja(M, (x, (alto - 0.05) * 0.5, (z0 + z1) * 0.5), (0.06, alto - 0.05, (z1 - z0) * 0.8), "madera",
             jit(mezcla(col, MADERA_OSC, 0.3)), veta="larga")


def taburete(M, c, alto=0.45, r=0.18, col=MADERA):
    c = Vector(c)
    cilindro(M, c + Vector((0, alto - 0.05, 0)), [(0, r), (0.05, r)], 8, "madera", jit(col))
    for k in range(3):
        a = k * math.tau / 3
        viga(M, c + Vector((math.cos(a) * r * 0.6, alto - 0.05, math.sin(a) * r * 0.6)),
             c + Vector((math.cos(a) * r * 0.95, 0.0, math.sin(a) * r * 0.95)), 0.035, "madera", jit(MADERA_OSC))


def hogaza(M, c, r=0.11, h=0.09, col=None, n=7):
    col = col or jit(elige(PAN), 0.05)
    claro = mezcla(col, (0.95, 0.80, 0.55), 0.35)
    cilindro(M, c, [(0.0, r * 0.82), (h * 0.35, r), (h * 0.75, r * 0.8), (h, r * 0.25)], n,
             "barro", col, fase=RND.random())
    M.caras[-1][2] = [lin(claro)] * len(M.caras[-1][0])     # la tapa de arriba, más dorada


def barra(M, c, largo=0.42, r=0.05, yaw=0.0, col=None):
    col = col or jit(elige(PAN), 0.05)
    c = Vector(c)
    rot = R(y=yaw) @ rot_eje("x")
    cilindro(M, c, [(-largo * 0.5, 0.0), (-largo * 0.45, r * 0.8), (-largo * 0.3, r), (largo * 0.3, r), (largo * 0.45, r * 0.8),
                    (largo * 0.5, 0.0)], 6, "barro", col, rot=rot)


def cesta(M, c, r=0.22, h=0.18, col=MIMBRE, asa=True):
    c = Vector(c)
    cilindro(M, c, [(0.0, r * 0.82), (h, r), (h + 0.02, r * 1.04)], 10, "tela", jit(col), tapa_arriba=False, tapa_abajo=True)
    cilindro(M, c + Vector((0, h - 0.01, 0)), [(0.0, r * 0.98), (0.0, 0.0)], 10, "tela", jit(mezcla(col, (0.2, 0.15, 0.1), 0.5)),
             tapa_arriba=False)
    if asa:
        for k in range(6):
            a0, a1 = math.pi * k / 6, math.pi * (k + 1) / 6
            viga(M, c + Vector((math.cos(a0) * r * 0.9, h + math.sin(a0) * r * 0.9, 0)),
                 c + Vector((math.cos(a1) * r * 0.9, h + math.sin(a1) * r * 0.9, 0)), 0.025, "tela", jit(col))


def cantaro(M, c, alto=0.5, r=0.17, col=(0.80, 0.50, 0.34)):
    c = Vector(c)
    cilindro(M, c, [(0.0, r * 0.55), (alto * 0.15, r * 0.85), (alto * 0.45, r), (alto * 0.75, r * 0.7), (alto * 0.88, r * 0.32),
                    (alto * 0.97, r * 0.38), (alto, r * 0.36)], 10, "barro", jit(col, 0.05), tapa_abajo=True)


def tarro(M, c, alto=0.2, r=0.08, col=(0.78, 0.66, 0.50)):
    c = Vector(c)
    cilindro(M, c, [(0.0, r * 0.8), (alto * 0.2, r), (alto * 0.8, r), (alto * 0.9, r * 0.7), (alto, r * 0.72)], 8, "barro",
             jit(col, 0.06))


def saco(M, c, r=0.24, alto=0.62, col=SACO, yaw=0.0):
    c = Vector(c)
    cilindro(M, c, [(0.0, r * 0.85), (0.08, r), (alto * 0.55, r * 1.04), (alto * 0.82, r * 0.78), (alto * 0.9, r * 0.25),
                    (alto, r * 0.33)], 9, "tela", jit(col, 0.05), fase=yaw)
    cilindro(M, c + Vector((0, alto * 0.86, 0)), [(0, r * 0.3), (0.04, r * 0.3)], 8, "tela", (0.52, 0.40, 0.26), tapa_arriba=False)


def lena(M, x0, z0, x1, y0, filas, r=0.07, eje="z", largo=0.5):
    for f in range(filas):
        x = x0 + r
        while x < x1 - r:
            yy = y0 + r + f * r * 1.8
            c = Vector((x + RND.uniform(-0.01, 0.01), yy, z0 + largo * 0.5)) if eje == "z" else \
                Vector((z0 + largo * 0.5, yy, x))
            cilindro(M, c, [(-largo * 0.5, r * RND.uniform(0.8, 1.0)), (largo * 0.5, r * RND.uniform(0.8, 1.0))], 6,
                     "madera", jit(mezcla(MADERA, (0.55, 0.48, 0.38), RND.random() * 0.6)), rot=rot_eje(eje),
                     tapa_arriba=True, tapa_abajo=True, suave=False, fase=RND.random())
            x += r * 2.05


def rueda(M, centro, radio, radios=12, eje="z", col=MADERA, puestos=None, pinas=None, llanta=True):
    """Una rueda de carro: cubo, radios y pinas (las piezas del aro), todo en proporción al radio (0,68 m = la de un
    carro). puestos: cuántos radios hay (los demás faltan); pinas: índices de las pinas que hay (None = todas)."""
    centro = Vector(centro)
    k_r = radio / 0.68
    rot = rot_eje(eje)
    n_pinas = max(3, radios // 2)
    cubo_r, cubo_l = 0.13 * k_r, 0.18 * k_r
    seg = 10 if radio > 0.3 else 6
    cilindro(M, centro, [(-cubo_l, cubo_r * 0.8), (-cubo_l * 0.55, cubo_r), (cubo_l * 0.55, cubo_r), (cubo_l, cubo_r * 0.8)], seg,
             "madera", jit(col), rot=rot, tapa_abajo=True)
    puestos = radios if puestos is None else puestos
    eu = rot @ Vector((1, 0, 0))
    ev = rot @ Vector((0, 0, 1))
    for k in range(puestos):
        a = k * math.tau / radios
        d = eu * math.cos(a) + ev * math.sin(a)
        viga(M, centro + d * cubo_r * 0.9, centro + d * (radio - 0.05 * k_r), 0.04 * k_r, "madera",
             jit(mezcla(col, FRESNO, 0.3)), alto=0.05 * k_r)
    hay = range(n_pinas) if pinas is None else pinas
    for k in hay:
        for s in range(3 if radio > 0.3 else 2):
            n_s = 3 if radio > 0.3 else 2
            a0 = (k + s / n_s) * math.tau / n_pinas
            a1 = (k + (s + 1) / n_s) * math.tau / n_pinas
            p0 = centro + (eu * math.cos(a0) + ev * math.sin(a0)) * (radio - 0.03 * k_r)
            p1 = centro + (eu * math.cos(a1) + ev * math.sin(a1)) * (radio - 0.03 * k_r)
            viga(M, p0, p1, 0.08 * k_r, "madera", jit(col, 0.04), alto=0.08 * k_r)
    if pinas is None and llanta:
        for k in range(24 if radio > 0.3 else 12):
            n_l = 24 if radio > 0.3 else 12
            a0, a1 = k * math.tau / n_l, (k + 1) * math.tau / n_l
            p0 = centro + (eu * math.cos(a0) + ev * math.sin(a0)) * (radio + 0.012 * k_r)
            p1 = centro + (eu * math.cos(a1) + ev * math.sin(a1)) * (radio + 0.012 * k_r)
            viga(M, p0, p1, 0.09 * k_r, "hierro", HIERRO, alto=0.02 * k_r)


def galga_2d():
    """La silueta de la galga del carretero (en metros, x a lo largo, y hacia arriba): una regla de 0,36 m con los
    escalones de medir en una punta y el agujero de colgar en la otra. La misma en utensilios.glb y en la pintura del
    taller (la pista)."""
    return [(0.0, 0.0), (0.36, 0.0), (0.36, 0.035), (0.31, 0.035), (0.31, 0.055), (0.27, 0.055), (0.27, 0.075),
            (0.23, 0.075), (0.23, 0.09), (0.05, 0.09), (0.0, 0.07)]


def herramienta_colgada(S, x, y, z_pared, forma, col, silueta=True, presente=True, mat="hierro"):
    """Una herramienta colgada en la pared norte con su silueta pintada detrás (pintura un poco mayor)."""
    if silueta:
        pts = [(px * 1.08 - 0.01, py * 1.08 - 0.01) for px, py in forma]
        placa(S.M, pts, (x, y, z_pared + 0.004), (1, 0, 0), (0, 1, 0), 0.003, "revoque", PINTURA, lados=False)
    caja(S.P, (x + 0.03, y + 0.05, z_pared + 0.025), (0.014, 0.014, 0.05), "hierro", HIERRO)       # el clavo
    if presente:
        placa(S.P, forma, (x, y, z_pared + 0.012), (1, 0, 0), (0, 1, 0), 0.02, mat, col)


# ================================================================ HORNO DE MAELA (10 × 7, en L)

def horno():
    W, D, H = 10.0, 7.0, 3.4
    S = Sala("horno", W, D, H)
    S.camara = {"x": [4.2, 5.8], "z": [2.6, 4.2]}
    ocre = (0.86, 0.72, 0.54)
    zoc = (0.70, 0.62, 0.52)
    # --- huecos y ventanas: al oeste (el sol de la tarde cae sobre la artesa), la tienda al sur, la escalera al este
    ventana(S, "o", 2.3, 3.2, 1.35, 2.25, postigo=VERDE_POSTIGO)
    ventana(S, "e", 5.0, 5.8, 1.3, 2.1, postigo=VERDE_POSTIGO)
    S.hueco("s", 4.3, 5.5, 0.0, 2.25)                                   # la puerta de la calle (abierta)
    S.hueco("s", 6.3, 9.7, 0.95, 2.2)                                   # la ventana de la tienda (sobre el mostrador)
    S.hueco("s", 1.0, 2.1, 1.25, 2.1)
    # --- suelos: baldosa de barro en el obrador y la tienda, tablas en la zona de Maela
    def baldosa(ix, iz, c):
        col = jit(elige(BARRO_COCIDO), 0.05)
        harina = (1.0 - suave(0.4, 1.7, (c - Vector((3.75, 0, 3.05))).length)) * 0.55        # harina junto a la artesa
        harina = max(harina, (1.0 - suave(0.3, 1.1, (c - Vector((1.2, 0, 4.9))).length)) * 0.35)
        hollin = (1.0 - suave(0.4, 1.6, (c - Vector((2.0, 0, 2.0))).length)) * 0.35          # ceniza ante la boca
        col = mezcla(col, HARINA, harina)
        return mezcla(col, (0.30, 0.26, 0.22), hollin)
    rejilla(S.M, 0.0, 0.0, 6.0, D, 0.0, 0.33, 0.33, 0.02, "barro", baldosa, (0.42, 0.36, 0.30))
    rejilla(S.M, 6.0, 4.5, W, D, 0.0, 0.33, 0.33, 0.02, "barro", baldosa, (0.42, 0.36, 0.30))
    rejilla(S.M, 6.0, 0.0, W, 4.5, 0.0, 4.0, 0.21, 0.012, "madera",
            lambda ix, iz, c: jit(mezcla(MADERA, MADERA_CLARA, RND.random() * 0.4), 0.04), (0.22, 0.16, 0.12))
    # --- muros
    humo = (2.0, 0.2, 0.35, 2.4)
    for lado, a0, a1 in (("n", -0.3, W + 0.3), ("o", 0.0, D), ("e", 0.0, D)):
        pared(S, lado, a0, a1, H, 0.9, "sillar", tono_muro(zoc, 0.9, 0.18, 0.0), "revoque",
              tono_muro(ocre, H, 0.08, 0.14, humo))
    for x in (0.0, 4.4, 6.0, 8.0, W):                                    # postes del muro del fondo y la viga de arriba
        caja_mm(S.M, (x - 0.1, 0.9, 0.0), (x + 0.1, H, 0.12), "madera", jit(MADERA_OSC), veta="larga")
    caja_mm(S.M, (0.0, H - 0.25, 0.0), (W, H, 0.16), "madera", jit(MADERA_OSC), veta="larga")
    # --- el tabique de la zona de Maela (al este, con la cortina) y el murete de la tienda
    tabique = [(1.5, 3.1, 0.0, 2.2)]
    tramo_muro(S.M, "e", 0.0, 4.6, 0.0, H, tabique, "revoque", tono_muro((0.90, 0.80, 0.64), H, 0.1, 0.1), 5.85, D, grueso=0.3)
    for z in (1.42, 3.18):
        caja_mm(S.M, (5.8, 0.0, z - 0.08), (6.2, 2.3, z + 0.08), "madera", jit(MADERA_OSC), veta="larga")
    caja_mm(S.M, (5.8, 2.2, 1.34), (6.2, 2.38, 3.26), "madera", jit(MADERA_OSC), veta="larga")
    S.bloqueo(5.85, 0.0, 6.15, 1.5)
    S.bloqueo(5.85, 3.1, 6.15, 4.6)
    # la cortina recogida al norte del paso (paso interno «cortina_horno», siempre abierto)
    caja_mm(S.M, (5.95, 2.24, 1.45), (6.05, 2.28, 3.15), "madera", MADERA_OSC)
    pliegues = []
    for k in range(7):
        z = 1.5 + k * 0.06
        pliegues.append((z, 0.06 if k % 2 == 0 else -0.06))
    for k in range(len(pliegues) - 1):
        (z0, d0), (z1, d1) = pliegues[k], pliegues[k + 1]
        S.M.cara([Vector((6.0 + d0, 0.06, z0)), Vector((6.0 + d1, 0.06, z1)), Vector((6.0 + d1, 2.24, z1)), Vector((6.0 + d0, 2.24, z0))],
                 "tela", (0.60, 0.22, 0.17))
        S.M.cara([Vector((6.0 + d0, 2.24, z0)), Vector((6.0 + d1, 2.24, z1)), Vector((6.0 + d1, 0.06, z1)), Vector((6.0 + d0, 0.06, z0))],
                 "tela", (0.60, 0.22, 0.17))
    S.bloqueo(5.8, 1.45, 6.2, 1.85)
    S.pasos["cortina_horno"] = {"rect": [5.55, 1.95, 0.9, 0.95], "siempre": True}
    S.ancla("cortina", 6.0, 0.0, 2.45)
    # murete entre la tienda y la zona de Maela, con tarros encima
    caja_mm(S.M, (6.15, 0.0, 4.4), (W, 1.05, 4.6), "revoque", tono_muro((0.90, 0.80, 0.64), 1.05, 0.18, 0.0))
    caja_mm(S.M, (6.1, 1.05, 4.36), (W, 1.1, 4.66), "madera", jit(MADERA), veta="larga")
    for k in range(5):
        tarro(S.P, (6.6 + k * 0.7 + RND.uniform(-0.1, 0.1), 1.1, 4.5), RND.uniform(0.14, 0.24), 0.07)
    S.bloqueo(6.15, 4.4, W, 4.6)
    # --- EL HORNO DE BÓVEDA (pared norte): base de piedra, bóveda de ladrillo, la boca con las brasas, la campana
    caja_mm(S.M, (0.6, 0.0, 0.0), (3.4, 0.95, 1.8), "sillar", jit((0.70, 0.64, 0.56)))
    for k in range(16):                                                  # la bóveda: anillos de ladrillo
        a0, a1 = k / 16 * math.pi * 0.5, (k + 1) / 16 * math.pi * 0.5
        r0, r1 = math.cos(a0), math.cos(a1)
        y0, y1 = 0.95 + math.sin(a0) * 0.95, 0.95 + math.sin(a1) * 0.95
        col = jit(elige(LADRILLO), 0.06)
        fondo = 1.8 * (0.55 + 0.45 * r0)
        xl0, xr0, xl1, xr1 = 0.6 + 1.4 * (1 - r0), 3.4 - 1.4 * (1 - r0), 0.6 + 1.4 * (1 - r1), 3.4 - 1.4 * (1 - r1)

        def cf(p, c=col):
            if 1.25 < p.z < 1.79 and abs(p.x - 2.0) < 0.41 and p.y < 1.47:      # dentro de la boca: negro de hollín
                return (0.09, 0.06, 0.05)
            return mezcla(c, TIZNE, 0.5 * suave(1.3, 1.9, p.y) * (1.0 - suave(0.5, 1.2, abs(p.x - 2.0))))
        if y1 <= 1.46:                                                   # la boca: el centro, hundido (1,3 m de fondo)
            placa(S.M, [(xl0, y0), (1.6, y0), (1.6, y1), (xl1, y1)], (0, 0, 0), (1, 0, 0), (0, 1, 0), fondo, "barro", cf)
            placa(S.M, [(2.4, y0), (xr0, y0), (xr1, y1), (2.4, y1)], (0, 0, 0), (1, 0, 0), (0, 1, 0), fondo, "barro", cf)
            placa(S.M, [(1.6, y0), (2.4, y0), (2.4, y1), (1.6, y1)], (0, 0, 0), (1, 0, 0), (0, 1, 0), 1.3, "barro", cf)
        else:
            placa(S.M, [(xl0, y0), (xr0, y0), (xr1, y1), (xl1, y1)], (0, 0, 0), (1, 0, 0), (0, 1, 0), fondo, "barro", cf)
    # la boca: arco de dovelas, solera de piedra y las brasas (brillo) sobre el suelo del horno
    for k in range(7):
        a0, a1 = math.pi * k / 7, math.pi * (k + 1) / 7
        p0 = Vector((2.0 + math.cos(a0) * 0.46, 1.3 + math.sin(a0) * 0.25, 1.86))
        p1 = Vector((2.0 + math.cos(a1) * 0.46, 1.3 + math.sin(a1) * 0.25, 1.86))
        viga(S.M, p0, p1, 0.12, "barro", jit(elige(LADRILLO), 0.08), alto=0.1)
    for x in (1.5, 2.5):
        caja_mm(S.M, (x - 0.08, 0.95, 1.8), (x + 0.08, 1.32, 1.92), "barro", jit(elige(LADRILLO), 0.08))
    caja_mm(S.M, (1.45, 0.88, 1.8), (2.55, 0.97, 2.08), "sillar", (0.62, 0.58, 0.52))
    for k in range(11):
        cx, cz = 1.72 + RND.random() * 0.56, 1.38 + RND.random() * 0.36
        caja(S.M, (cx, 0.975, cz), (0.1, 0.04, 0.07), "brillo", jit((1.0, 0.42 + RND.random() * 0.22, 0.12), 0.1),
             rot=R(y=RND.uniform(0, 90)))
    S.luz(2.0, 1.15, 1.95, 240.0, FUEGO, 0.18, fuego=1.0)
    S.luz(2.0, 1.05, 1.55, 60.0, FUEGO, 0.1)
    # la campana de humos y su chimenea, tiznadas
    caja_mm(S.M, (1.15, 1.95, 0.0), (2.85, 2.25, 0.95), "sillar", lambda p: mezcla((0.66, 0.60, 0.52), TIZNE, 0.45))
    caja_mm(S.M, (1.45, 2.25, 0.0), (2.55, H, 0.65), "revoque", lambda p: mezcla((0.80, 0.70, 0.56), TIZNE, 0.35 + 0.2 * (p.y - 2.2)))
    S.bloqueo(0.6, 0.0, 3.4, 1.8)
    S.ancla("boca", 2.0, 0.0, 2.45)
    S.objeto("boca", "examinable", "la boca del horno con las brasas")
    # la pala de hornear y el hurgón apoyados en la bóveda
    viga(S.P, (3.62, 0.0, 1.95), (3.3, 2.3, 1.15), 0.035, "madera", MADERA_CLARA)
    caja(S.P, (3.66, 0.18, 2.02), (0.26, 0.34, 0.02), "madera", MADERA_CLARA, rot=R(y=-8, x=-18))
    viga(S.P, (0.52, 0.0, 1.92), (0.62, 1.9, 1.5), 0.025, "hierro", HIERRO)
    # la leña contra el muro oeste
    lena(S.P, 0.04, 1.95, 0.56, 0.0, 6, r=0.065, eje="z", largo=1.3)
    S.bloqueo(0.0, 1.95, 0.6, 3.25)
    # --- LA ARTESA (el centro del obrador): artesa en patas con la masa, el tablero con harina, el rasero
    ax0, ax1, az0, az1 = 2.9, 4.6, 2.7, 3.35
    for x, z in ((ax0 + 0.1, az0 + 0.08), (ax1 - 0.1, az0 + 0.08), (ax0 + 0.1, az1 - 0.08), (ax1 - 0.1, az1 - 0.08)):
        viga(S.M, (x, 0.0, z), (x, 0.56, z), 0.07, "madera", jit(MADERA_OSC))
    caja_mm(S.M, (ax0, 0.56, az0), (ax1, 0.62, az1), "madera", jit(MADERA), veta="larga")
    for (a, b) in (((ax0, 0.62, az0), (ax1, 0.88, az0 + 0.05)), ((ax0, 0.62, az1 - 0.05), (ax1, 0.88, az1)),
                   ((ax0, 0.62, az0), (ax0 + 0.05, 0.88, az1)), ((ax1 - 0.05, 0.62, az0), (ax1, 0.88, az1))):
        caja_mm(S.M, a, b, "madera", jit(MADERA), veta="larga")
    for k in range(3):                                                   # la masa en montones
        cilindro(S.M, (ax0 + 0.35 + k * 0.5, 0.62, (az0 + az1) * 0.5),
                 [(0, 0.24), (0.1, 0.22), (0.18, 0.14), (0.21, 0.0)], 10, "tela", jit((0.95, 0.90, 0.78), 0.03))
    caja_mm(S.M, (ax0 - 0.05, 0.88, az0 - 0.02), (ax1 + 0.05, 0.9, az0 + 0.12), "madera", jit(MADERA_CLARA))
    caja(S.P, (ax1 - 0.25, 0.92, az1 - 0.2), (0.24, 0.02, 0.1), "hierro", (0.55, 0.55, 0.55), rot=R(y=20))
    saco(S.P, (ax0 - 0.3, 0.0, az1 - 0.05), 0.2, 0.48, SACO)             # el saco abierto, al extremo oeste
    caja_mm(S.P, (ax0 - 0.48, 0.48, az1 - 0.23), (ax0 - 0.12, 0.5, az1 + 0.13), "tela", HARINA)
    S.bloqueo(ax0, az0, ax1, az1)
    S.bloqueo(ax0 - 0.5, az1 - 0.25, ax0, az1 + 0.15)
    S.ancla("artesa", 4.05, 0.0, 4.0)
    S.ancla("maela", 3.75, 0.0, 2.3)
    S.objeto("artesa", "examinable", "la artesa con la masa reposando")
    # --- LOS ESTANTES DE ENFRIAR (muro oeste): dos bastidores de listones, llenos de hogazas y barras
    for z0, z1 in ((3.65, 4.8), (4.9, 6.05)):
        for x, z in ((0.06, z0), (0.6, z0), (0.06, z1), (0.6, z1)):
            caja(S.M, (x, 1.05, z), (0.05, 2.1, 0.05), "madera", jit(MADERA_OSC), veta="larga")
        for y in (0.35, 0.75, 1.15, 1.55, 1.95):
            for k in range(4):
                xx = 0.1 + k * 0.14
                caja_mm(S.M, (xx, y - 0.025, z0), (xx + 0.08, y, z1), "madera", jit(MADERA_CLARA, 0.05), veta="larga")
            zz = z0 + 0.12
            while zz < z1 - 0.12:
                if RND.random() < 0.82:
                    if RND.random() < 0.6:
                        hogaza(S.P, (0.33 + RND.uniform(-0.04, 0.04), y, zz + 0.02), RND.uniform(0.09, 0.12), 0.09)
                    else:
                        barra(S.P, (0.33, y + 0.045, zz), RND.uniform(0.38, 0.46), 0.045, yaw=RND.uniform(-12, 12))
                zz += 0.25
    S.bloqueo(0.0, 3.6, 0.65, 6.1)
    S.ancla("estante", 1.2, 0.0, 5.0)
    S.objeto("estante", "examinable", "los estantes de enfriar, con el pan de la tarde")
    # --- los sacos de harina (rincón noreste del obrador)
    for k, (x, z) in enumerate(((4.65, 0.4), (5.15, 0.38), (5.55, 0.45), (4.9, 0.85), (5.4, 0.9))):
        saco(S.P, (x, 0.0, z), 0.23, 0.6 if k < 3 else 0.52, jit(SACO, 0.04), yaw=RND.random())
    saco(S.P, (5.0, 0.6, 0.6), 0.22, 0.42, jit(SACO, 0.04))
    S.bloqueo(4.4, 0.1, 5.8, 1.15)
    # --- LA TIENDA: el mostrador al sur (da a la calle), cestas con pan, la balanza; estante en el murete
    mz0, mz1 = 5.95, 6.5
    caja_mm(S.M, (6.55, 0.0, mz0 + 0.05), (9.65, 0.9, mz1), "madera", jit(MADERA), veta="larga")
    for x in np.arange(6.6, 9.6, 0.3):
        caja_mm(S.M, (x, 0.05, mz0 + 0.02), (x + 0.26, 0.85, mz0 + 0.05), "madera", jit(MADERA, 0.06), veta="larga")
    caja_mm(S.M, (6.5, 0.9, mz0 - 0.05), (9.7, 0.96, mz1 + 0.04), "madera", jit(MADERA_CLARA), veta="larga")
    for k, x in enumerate((6.95, 7.75, 8.6)):
        cesta(S.P, (x, 0.96, 6.22), 0.24, 0.14)
        for j in range(4):
            hogaza(S.P, (x + RND.uniform(-0.1, 0.1), 1.0 + j * 0.03, 6.22 + RND.uniform(-0.1, 0.1)), 0.08, 0.07)
    caja(S.P, (9.3, 1.0, 6.2), (0.32, 0.03, 0.18), "hierro", LATON)                        # la balanza
    viga(S.P, (9.3, 0.96, 6.2), (9.3, 1.3, 6.2), 0.02, "hierro", HIERRO)
    viga(S.P, (9.12, 1.28, 6.2), (9.48, 1.28, 6.2), 0.015, "hierro", LATON)
    S.bloqueo(6.5, mz0 - 0.05, 9.7, mz1)
    S.ancla("mostrador", 8.8, 0.0, 5.25)
    S.objeto("mostrador", "ofrecido", "el pan del mostrador (lo da Maela, no se coge)")
    # --- LA ZONA DE MAELA (tras la cortina): hogar pequeño, alacena, mesa con su tazón, escalera a la alcoba
    caja_mm(S.M, (6.5, 0.0, 0.0), (7.8, 0.35, 0.7), "sillar", jit((0.66, 0.62, 0.56)))
    caja_mm(S.M, (6.5, 0.35, 0.0), (6.68, 1.15, 0.7), "sillar", jit((0.62, 0.58, 0.52)))
    caja_mm(S.M, (7.62, 0.35, 0.0), (7.8, 1.15, 0.7), "sillar", jit((0.62, 0.58, 0.52)))
    caja_mm(S.M, (6.45, 1.15, 0.0), (7.85, 1.27, 0.78), "madera", jit(MADERA_OSC), veta="larga")     # la repisa del hogar
    caja_mm(S.M, (6.68, 0.35, 0.0), (7.62, 1.15, 0.12), "hierro", (0.08, 0.06, 0.05))
    caja_mm(S.M, (6.6, 1.27, 0.0), (7.7, H, 0.5), "revoque", lambda p: mezcla((0.86, 0.76, 0.60), TIZNE, 0.25 + 0.15 * (p.y - 1.2)))
    for k in range(5):
        caja(S.M, (6.95 + k * 0.1, 0.38, 0.3 + RND.uniform(-0.05, 0.05)), (0.18, 0.05, 0.06), "brillo",
             jit((1.0, 0.5, 0.15), 0.1), rot=R(y=RND.uniform(-40, 40)))
    cilindro(S.P, (7.15, 0.5, 0.35), [(0, 0.12), (0.18, 0.16), (0.24, 0.15)], 9, "hierro", HIERRO, tapa_abajo=True)
    S.luz(7.15, 0.55, 0.55, 70.0, FUEGO, 0.12, fuego=0.5)
    tarro(S.P, (6.7, 1.27, 0.35), 0.18, 0.06)
    tarro(S.P, (7.55, 1.27, 0.32), 0.14, 0.06, (0.58, 0.62, 0.66))
    S.bloqueo(6.45, 0.0, 7.85, 0.8)
    # la alacena (de Maela: privada)
    caja_mm(S.M, (6.3, 0.0, 3.95), (7.5, 1.75, 4.4), "madera", jit(MADERA_OSC), veta="larga")
    for x0 in (6.36, 6.92):
        caja_mm(S.M, (x0, 0.08, 3.92), (x0 + 0.52, 0.85, 3.95), "madera", jit(AZUL_POSTIGO, 0.05), veta="larga")
    for y in (1.05, 1.42):
        caja_mm(S.M, (6.35, y, 3.98), (7.45, y + 0.03, 4.38), "madera", jit(MADERA))
    for k in range(4):
        cilindro(S.P, (6.5 + k * 0.27, 1.08, 4.15), [(0, 0.05), (0.08, 0.1), (0.1, 0.11)], 8, "barro",
                 jit((0.88, 0.84, 0.74), 0.04), tapa_abajo=True)
        tarro(S.P, (6.5 + k * 0.27, 1.45, 4.17), RND.uniform(0.14, 0.22), 0.06, jit((0.70, 0.56, 0.40), 0.08))
    S.bloqueo(6.3, 3.95, 7.5, 4.4)
    S.ancla("alacena", 6.75, 0.0, 3.35)
    S.objeto("alacena", "privado", "la alacena de Maela")
    # la mesa con el tazón, el pan empezado y la vela; dos taburetes
    mesa(S.M, 8.0, 2.3, 9.2, 3.0, 0.76, MADERA)
    taburete(S.M, (8.3, 0.0, 3.3))
    taburete(S.M, (8.95, 0.0, 2.0))
    cilindro(S.P, (8.4, 0.76, 2.6), [(0, 0.06), (0.07, 0.11), (0.09, 0.12)], 9, "barro", (0.86, 0.80, 0.70), tapa_abajo=True)
    hogaza(S.P, (8.8, 0.76, 2.7), 0.1, 0.08)
    cilindro(S.P, (9.0, 0.76, 2.45), [(0, 0.04), (0.02, 0.04), (0.02, 0.018), (0.13, 0.018)], 7, "tela", (0.95, 0.92, 0.82))
    caja(S.M, (9.0, 0.92, 2.45), (0.025, 0.05, 0.025), "brillo", VELA)
    S.luz(9.0, 0.98, 2.45, 3.0, VELA, 0.02)
    S.bloqueo(8.0, 2.3, 9.2, 3.0)
    S.ancla("mesa", 8.7, 0.0, 1.65)
    S.objeto("mesa", "privado", "la mesa de Maela")
    # la escalera a la alcoba (decorado): sube pegada al muro este hacia el norte
    for k in range(10):
        z = 4.2 - k * 0.32
        y = 0.3 + k * 0.3
        caja_mm(S.M, (9.35, y - 0.05, z - 0.3), (W - 0.02, y, z), "madera", jit(MADERA), veta="larga")
    viga(S.M, (9.33, 0.0, 4.3), (9.33, 3.25, 1.05), 0.07, "madera", MADERA_OSC, alto=0.22)
    viga(S.M, (9.3, 1.0, 4.25), (9.3, 4.1, 1.15), 0.05, "madera", MADERA_OSC)
    for k in range(3):
        viga(S.M, (9.3, 0.3 + k * 0.9, 4.0 - k * 0.95), (9.3, 1.25 + k * 0.9, 4.0 - k * 0.95), 0.04, "madera", MADERA_OSC)
    S.bloqueo(9.3, 0.95, W, 4.4)
    # hierbas secándose colgadas de la viga de la zona de Maela
    for k in range(5):
        x = 7.0 + k * 0.45
        viga(S.P, (x, H - 0.25, 1.4), (x, 2.55, 1.4), 0.01, "tela", (0.5, 0.4, 0.3))
        cilindro(S.P, (x, 2.3, 1.4), [(0, 0.02), (0.15, 0.07), (0.25, 0.03)], 6, "tela", jit((0.46, 0.54, 0.30), 0.1))
    # --- puerta y anclas de entrar y salir
    murete_sur(S, 0.75, (4.3, 5.5), "sillar", tono_muro(zoc, 0.75, 0.2, 0.0))
    S.ancla("entrada", 4.9, 0.0, 5.35)
    S.ancla("salida", 4.9, 0.0, 6.75)
    return S


# ================================================================ TALLER DE DAMIÁN (nave 9 × 7 alta + trastienda 4 × 7)

def taller():
    W, D, H = 13.0, 7.0, 4.6
    HT = 3.2                                                            # la trastienda es más baja
    S = Sala("taller", W, D, H)
    S.techos = [[0.0, 0.0, 3.85, D, HT], [3.85, 0.0, W, D, H]]
    S.camara = {"x": [5.6, 8.6], "z": [2.6, 4.2]}
    gris = (0.80, 0.76, 0.68)
    zoc = (0.62, 0.58, 0.54)
    # --- huecos: el portón al este (abierto), ventanas altas al oeste de la nave (sobre el tejado de la trastienda),
    #     una ventana en la trastienda, las del sur (horneado)
    S.hueco("e", 1.2, 3.0, 0.0, 3.0)
    ventana(S, "o", 2.0, 3.0, 1.2, 2.1, postigo=None)
    S.hueco("s", 1.2, 2.4, 1.2, 2.0)
    S.hueco("s", 5.4, 7.0, 2.4, 3.6)
    S.hueco("s", 9.2, 10.8, 2.4, 3.6)
    S.hueco("s", 11.6, 12.4, 0.0, 2.0)
    # --- suelos: tierra apisonada en la nave, tablas en la trastienda
    def tierra_en(p):
        n = 0.5 + 0.25 * math.sin(p.x * 1.7 + 0.6 * math.sin(p.z * 2.3)) + 0.25 * math.sin(p.z * 1.3 + p.x * 0.4)
        col = mezcla((0.58, 0.49, 0.38), (0.66, 0.56, 0.43), n)
        viruta = (1.0 - suave(0.3, 1.6, (p - Vector((8.4, 0, 3.6))).length)) * 0.45
        viruta = max(viruta, (1.0 - suave(0.3, 1.4, (p - Vector((10.9, 0, 1.0))).length)) * 0.5)
        paso = (1.0 - suave(0.2, 0.9, abs(p.z - 2.1))) * suave(9.0, 12.0, p.x) * 0.25          # el camino del portón
        return mezcla(mezcla(col, FRESNO, viruta), (0.50, 0.42, 0.33), paso)

    def tierra(ix, iz, c):
        return tierra_en
    rejilla(S.M, 4.0, 0.0, W, D, 0.0, 0.5, 0.5, 0.0, "tierra", tierra, (0.5, 0.42, 0.32))
    rejilla(S.M, 0.0, 0.0, 4.0, D, 0.0, 0.22, 8.0, 0.012, "madera",
            lambda ix, iz, c: jit(mezcla(MADERA_GRIS, MADERA, RND.random() * 0.5), 0.04), (0.2, 0.16, 0.12),
            desfase=(0.0, 0.35))
    # --- muros: zócalo de piedra alto y entramado de madera sobre revoque gris (otro oficio, otro aire)
    for lado, a0, a1, alto in (("n", -0.3, 3.85, HT), ("n", 3.85, W + 0.3, H), ("o", 0.0, D, HT), ("e", 0.0, D, H)):
        pared(S, lado, a0, a1, alto, 1.2, "sillar", tono_muro(zoc, 1.2, 0.18, 0.0), "revoque", tono_muro(gris, alto, 0.06, 0.08))
    for x in (4.15, 6.4, 8.8, 11.2, W):                                   # entramado del muro norte de la nave
        caja_mm(S.M, (x - 0.11, 1.2, 0.0), (x + 0.11, H, 0.13), "madera", jit(MADERA_OSC), veta="larga")
    caja_mm(S.M, (4.0, 2.9, 0.0), (W, 3.08, 0.14), "madera", jit(MADERA_OSC), veta="larga")
    caja_mm(S.M, (4.0, H - 0.22, 0.0), (W, H, 0.15), "madera", jit(MADERA_OSC), veta="larga")
    for xa, xb in ((6.4, 8.8), (8.8, 11.2)):
        viga(S.M, (xa + 0.1, 3.08, 0.07), (xb - 0.1, H - 0.22, 0.07), 0.12, "madera", MADERA_OSC, alto=0.1)
    for z in (0.0, 3.6, D):                                               # postes del muro este
        caja_mm(S.M, (W - 0.13, 1.2, z - 0.11), (W, H, z + 0.11), "madera", jit(MADERA_OSC), veta="larga")
    # el portón: marco y las dos hojas abiertas contra el muro (por dentro)
    caja_mm(S.M, (W - 0.15, 0.0, 1.08), (W + 0.05, 3.15, 1.2), "madera", MADERA_OSC, veta="larga")
    caja_mm(S.M, (W - 0.15, 0.0, 3.0), (W + 0.05, 3.15, 3.12), "madera", MADERA_OSC, veta="larga")
    caja_mm(S.M, (W - 0.15, 3.0, 1.08), (W + 0.05, 3.15, 3.12), "madera", MADERA_OSC, veta="larga")
    for z0, z1 in ((0.15, 1.05), (3.15, 4.05)):
        for k in range(4):
            caja_mm(S.M, (W - 0.06, 0.05, z0 + k * 0.225), (W - 0.01, 2.95, z0 + (k + 1) * 0.225 - 0.01), "madera",
                    jit(MADERA_GRIS, 0.05), veta="larga")
        caja_mm(S.M, (W - 0.1, 0.4, z0), (W - 0.06, 0.55, z1), "madera", MADERA_OSC)
        caja_mm(S.M, (W - 0.1, 2.4, z0), (W - 0.06, 2.55, z1), "madera", MADERA_OSC)
    # --- el tabique entre la nave y la trastienda: ventanas altas (por encima del tejado de la trastienda) y la puerta
    tab = [(4.3, 5.5, 0.0, 2.15), (1.0, 2.2, HT + 0.25, H - 0.35), (3.6, 4.0, HT + 0.25, H - 0.35), (5.6, 6.4, HT + 0.25, H - 0.35)]
    tramo_muro(S.M, "e", 0.0, D, 0.0, H, tab, "revoque", tono_muro(gris, H, 0.12, 0.06), 3.85, D, grueso=0.3)
    for z in (4.22, 5.58):
        caja_mm(S.M, (3.8, 0.0, z - 0.08), (4.2, 2.25, z + 0.08), "madera", jit(MADERA_OSC), veta="larga")
    caja_mm(S.M, (3.8, 2.15, 4.14), (4.2, 2.32, 5.66), "madera", jit(MADERA_OSC), veta="larga")
    caja_mm(S.M, (3.8, HT - 0.1, -0.1), (4.2, HT + 0.08, D + 0.1), "madera", jit(MADERA_OSC), veta="larga")
    S.bloqueo(3.85, 0.0, 4.15, 4.3)
    S.bloqueo(3.85, 5.5, 4.15, D)
    # la hoja de la puerta (aparte: gira en Godot), con la tranca; su origen es la bisagra (al norte del hueco)
    hoja = Malla()
    for k in range(5):
        caja_mm(hoja, (-0.04, 0.02, k * 0.236 + 0.005), (0.04, 2.1, (k + 1) * 0.236), "madera", jit(MADERA_GRIS, 0.05), veta="larga")
    for y in (0.35, 1.75):
        caja_mm(hoja, (0.04, y, 0.06), (0.08, y + 0.14, 1.12), "madera", MADERA_OSC)
    viga(hoja, (0.08, 0.5, 0.15), (0.08, 1.7, 1.05), 0.05, "madera", MADERA_OSC, alto=0.1)
    caja_mm(hoja, (0.05, 1.05, 0.95), (0.1, 1.15, 1.12), "hierro", HIERRO)
    S.extra["hoja_trastienda"] = (hoja, Vector((4.0, 0.0, 4.32)))
    S.pasos["trastienda"] = {"rect": [-0.5, -0.5, 4.9, D + 1.0], "siempre": False, "hoja": "hoja_trastienda",
                             "abierta_grados": -90.0}
    S.ancla("paso_trastienda", 4.75, 0.0, 4.9)
    S.objeto("paso_trastienda", "privado", "la puerta de la trastienda (cerrada hasta que Damián lo diga)")
    # --- EL POTRO con la rueda a medio hacer (en el centro de la nave)
    px0, px1, pz0, pz1 = 7.6, 9.2, 3.25, 3.95
    caja_mm(S.M, (px0, 0.36, pz0), (px1, 0.48, pz1), "madera", jit(MADERA_OSC), veta="larga")
    for x in (px0 + 0.12, px1 - 0.12):
        for z in (pz0 + 0.1, pz1 - 0.1):
            viga(S.M, (x + (0.08 if x > 8.4 else -0.08), 0.0, z), (x, 0.36, z), 0.09, "madera", MADERA_OSC)
    caja_mm(S.M, (8.32, 0.48, 3.5), (8.48, 0.95, 3.7), "madera", MADERA_OSC, veta="larga")
    rueda(S.M, (8.4, 1.12, 3.6), 0.68, 12, eje="z", col=FRESNO, puestos=8, pinas=[0, 1, 2])
    for k in range(4):                                                    # los radios que faltan, sobre el potro
        viga(S.P, (px0 + 0.15, 0.5, pz0 + 0.1 + k * 0.1), (px0 + 0.75, 0.5, pz0 + 0.12 + k * 0.1), 0.04, "madera", FRESNO, alto=0.05)
    caja(S.P, (px1 - 0.2, 0.5, pz1 - 0.15), (0.3, 0.04, 0.06), "madera", MADERA_OSC, rot=R(y=25))          # el mazo
    cilindro(S.P, (px1 - 0.05, 0.5, pz1 - 0.12), [(0, 0.06), (0.16, 0.06)], 8, "madera", MADERA_OSC, rot=R(y=25) @ rot_eje("x"))
    S.bloqueo(px0, pz0 - 0.1, px1, pz1)
    S.ancla("potro", 8.4, 0.0, 4.85)
    S.ancla("damian", 8.4, 0.0, 2.45)
    S.objeto("potro", "examinable", "la rueda a medio hacer en el potro")
    # --- EL BANCO DE LAS GUBIAS (muro norte) y LA PARED DE LAS HERRAMIENTAS, con el CLAVO VACÍO de la galga
    mesa(S.M, 4.6, 0.05, 7.4, 0.8, 0.86, MADERA)
    caja_mm(S.M, (4.6, 0.86, 0.05), (7.4, 0.94, 0.8), "madera", jit(MADERA_OSC), veta="larga")
    caja_mm(S.M, (4.62, 0.12, 0.1), (7.38, 0.16, 0.75), "madera", jit(MADERA))
    caja_mm(S.M, (7.2, 0.7, 0.75), (7.42, 1.0, 0.88), "madera", MADERA_OSC)                       # el tornillo de banco
    viga(S.P, (7.31, 0.96, 0.95), (7.31, 0.96, 0.6), 0.025, "madera", MADERA_CLARA)
    caja_mm(S.M, (4.7, 1.25, 0.02), (6.4, 1.32, 0.14), "madera", jit(MADERA))                      # el listón de las gubias
    for k in range(11):
        x = 4.8 + k * 0.145
        viga(S.P, (x, 1.32, 0.09), (x, 1.62, 0.09), 0.022, "madera", jit(MADERA_CLARA))
        viga(S.P, (x, 1.32, 0.09), (x, 1.12, 0.09), 0.012, "hierro", (0.55, 0.55, 0.56))
    # herramientas colgadas con su silueta pintada (la sierra, la escuadra, el compás y la galga que FALTA)
    sierra = [(0.0, 0.0), (0.62, 0.02), (0.62, 0.12), (0.5, 0.16), (0.5, 0.26), (0.38, 0.26), (0.36, 0.12), (0.0, 0.08)]
    herramienta_colgada(S, 4.75, 1.85, 0.0, sierra, (0.62, 0.62, 0.64))
    escuadra = [(0.0, 0.0), (0.4, 0.0), (0.4, 0.05), (0.05, 0.05), (0.05, 0.3), (0.0, 0.3)]
    herramienta_colgada(S, 5.6, 1.75, 0.0, escuadra, MADERA_CLARA, mat="madera")
    compas = [(0.0, 0.3), (0.02, 0.3), (0.12, 0.0), (0.1, 0.0), (0.03, 0.22), (-0.04, 0.0), (-0.06, 0.0), (0.0, 0.3)]
    herramienta_colgada(S, 6.25, 1.72, 0.0, compas, HIERRO)
    herramienta_colgada(S, 6.6, 1.62, 0.0, galga_2d(), MADERA_CLARA, presente=False, mat="madera")     # LA PISTA
    caja(S.M, (6.79, 1.86, 0.03), (0.06, 0.06, 0.03), "hierro", (0.30, 0.22, 0.16))               # un poco de óxido
    S.bloqueo(4.6, 0.0, 7.45, 0.9)
    S.ancla("clavo", 6.8, 0.0, 1.3)
    S.objeto("clavo", "examinable", "un clavo vacío con la silueta pintada de una galga")
    # --- EL TORNO de pértiga (muro norte, al este)
    for x in (9.75, 11.95):
        viga(S.M, (x - 0.25, 0.0, 0.35), (x, 0.95, 0.4), 0.09, "madera", MADERA_OSC)
        viga(S.M, (x + 0.25, 0.0, 0.35), (x, 0.95, 0.4), 0.09, "madera", MADERA_OSC)
    caja_mm(S.M, (9.6, 0.92, 0.28), (12.1, 1.04, 0.52), "madera", jit(MADERA_OSC), veta="larga")
    for x in (10.3, 11.5):
        caja_mm(S.M, (x - 0.07, 1.04, 0.3), (x + 0.07, 1.42, 0.5), "madera", MADERA)
    cilindro(S.P, (10.37, 1.3, 0.4), [(0, 0.035), (0.25, 0.05), (0.45, 0.04), (0.7, 0.055), (1.06, 0.035)], 8, "madera",
             FRESNO, rot=rot_eje("x"))
    viga(S.M, (12.25, 0.0, 0.25), (9.9, 4.2, 0.35), 0.07, "madera", MADERA_CLARA)                  # la pértiga
    viga(S.P, (10.8, 4.0, 0.33), (10.8, 1.32, 0.4), 0.008, "tela", (0.8, 0.74, 0.6))
    caja_mm(S.M, (10.4, 0.05, 0.6), (11.2, 0.1, 1.0), "madera", MADERA)                           # el pedal
    S.bloqueo(9.5, 0.0, 12.2, 1.0)
    S.ancla("torno", 10.9, 0.0, 1.55)
    S.objeto("torno", "examinable", "el torno de pértiga")
    # virutas en el suelo (alrededor del potro y del torno)
    for centro, n in (((8.4, 3.6), 40), ((10.9, 0.9), 34), ((5.8, 1.1), 18)):
        for k in range(n):
            a = RND.random() * math.tau
            r = RND.random() ** 0.5 * 1.1
            c = Vector((centro[0] + math.cos(a) * r, 0.005, centro[1] + math.sin(a) * r * 0.8))
            yaw = RND.random() * math.tau
            d1 = Vector((math.cos(yaw), 0, math.sin(yaw))) * 0.05
            d2 = Vector((-math.sin(yaw), 0, math.cos(yaw))) * 0.025
            S.P.cara([c - d1 - d2, c - d1 + d2 + Vector((0, 0.02, 0)), c + d1 + d2, c + d1 - d2], "madera",
                     jit(mezcla(FRESNO, (0.95, 0.88, 0.70), RND.random()), 0.04))
    # --- las ruedas acabadas apoyadas en el tabique y una colgada en lo alto
    for k, z in enumerate((1.35, 2.25, 3.15)):
        rueda(S.M, (4.32 + k * 0.06, 0.72, z), 0.68, 12, eje="x", col=jit(MADERA, 0.06))
    rueda(S.M, (8.0, 3.7, 0.22), 0.55, 10, eje="z", col=MADERA)
    S.bloqueo(4.15, 0.6, 4.6, 3.9)
    # un haz de radios y una pila de pinas
    for k in range(7):
        viga(S.P, (5.3 + k * 0.05, 0.0, 6.55), (5.3 + k * 0.05 + 0.15, 0.95, 6.75), 0.04, "madera", jit(FRESNO))
    for k in range(4):
        a0 = k * 0.15
        viga(S.P, (6.0, 0.05 + k * 0.08, 6.4), (6.6, 0.05 + k * 0.08, 6.55 + RND.uniform(-0.05, 0.05)), 0.08, "madera",
             jit(MADERA), alto=0.08)
    # el barreño de remojar madera (suroeste de la nave)
    cilindro(S.M, (4.9, 0.0, 6.3), [(0, 0.32), (0.55, 0.36), (0.6, 0.37)], 12, "madera", jit(MADERA_OSC), tapa_arriba=False)
    cilindro(S.M, (4.9, 0.5, 6.3), [(0, 0.34), (0, 0.0)], 12, "hierro", (0.16, 0.20, 0.22), tapa_arriba=False)
    for y in (0.12, 0.45):
        cilindro(S.M, (4.9, y, 6.3), [(0, 0.345), (0.04, 0.35)], 12, "hierro", HIERRO, tapa_arriba=False)
    S.bloqueo(4.55, 5.95, 5.25, 6.65)
    # la piedra de afilar (sureste)
    for x in (11.4, 12.2):
        caja_mm(S.M, (x - 0.05, 0.0, 5.6), (x + 0.05, 0.7, 5.75), "madera", MADERA_OSC)
    cilindro(S.M, (11.45, 0.82, 5.68), [(0, 0.36), (0.13, 0.36)], 14, "piedra", (0.62, 0.60, 0.56), rot=rot_eje("x"),
             tapa_abajo=True)
    caja_mm(S.M, (11.5, 0.28, 5.45), (12.1, 0.5, 5.9), "madera", MADERA)
    S.bloqueo(11.3, 5.3, 12.3, 6.1)
    # el banco junto al portón con el cántaro y el vaso (lo ofrece Damián)
    banco(S.M, 12.3, 3.6, 12.9, 4.4, 0.5, MADERA)
    cantaro(S.M, (12.55, 0.5, 3.85), 0.42, 0.14)
    cilindro(S.P, (12.62, 0.5, 4.2), [(0, 0.04), (0.1, 0.045)], 8, "barro", (0.70, 0.50, 0.36), tapa_abajo=True)
    S.bloqueo(12.3, 3.6, W, 4.4)
    S.ancla("cantaro", 11.6, 0.0, 4.0)
    S.objeto("cantaro", "ofrecido", "el agua del cántaro (la ofrece Damián)")
    # el estante sobre el torno (cajas, tarros de cola y de sebo), pinas colgadas en el tabique y un rollo de cuerda
    caja_mm(S.M, (9.6, 2.15, 0.0), (12.2, 2.21, 0.36), "madera", jit(MADERA_OSC), veta="larga")
    for x in (9.8, 12.0):
        viga(S.M, (x, 2.15, 0.02), (x, 1.85, 0.02), 0.05, "madera", MADERA_OSC)
    caja_mm(S.P, (9.75, 2.21, 0.05), (10.25, 2.45, 0.32), "madera", jit(MADERA_GRIS))
    caja_mm(S.P, (10.3, 2.21, 0.06), (10.6, 2.36, 0.3), "madera", jit(MADERA))
    for k in range(4):
        tarro(S.P, (10.9 + k * 0.3, 2.21, 0.18), RND.uniform(0.14, 0.22), 0.07, jit((0.62, 0.50, 0.36), 0.08))
    for k in range(3):                                                    # pinas colgadas (las piezas del aro)
        c = Vector((4.18, 2.75, 1.2 + k * 0.9))
        for s_ in range(4):
            a0, a1 = math.pi * (0.15 + s_ * 0.175), math.pi * (0.15 + (s_ + 1) * 0.175)
            viga(S.P, c + Vector((0.04, math.sin(a0) * 0.55 - 0.45, math.cos(a0) * 0.55)),
                 c + Vector((0.04, math.sin(a1) * 0.55 - 0.45, math.cos(a1) * 0.55)), 0.07, "madera", jit(FRESNO), alto=0.08)
        caja(S.P, (4.17, 2.8, c.z), (0.03, 0.03, 0.03), "hierro", HIERRO)
    for k in range(6):                                                    # el rollo de cuerda en su clavija
        a0, a1 = k * math.tau / 6, (k + 1) * math.tau / 6
        viga(S.P, (12.88, 1.7 + math.sin(a0) * 0.2, 5.3 + math.cos(a0) * 0.2), (12.88, 1.7 + math.sin(a1) * 0.2, 5.3 + math.cos(a1) * 0.2),
             0.05, "tela", (0.76, 0.66, 0.48))
    # un candil colgado sobre el banco (luz cálida de trabajo) y el polipasto de las ruedas
    viga(S.P, (6.0, H - 0.2, 0.9), (6.0, 2.55, 0.9), 0.01, "hierro", HIERRO)
    cilindro(S.M, (6.0, 2.35, 0.9), [(0, 0.05), (0.12, 0.08), (0.2, 0.03)], 8, "hierro", LATON)
    caja(S.M, (6.0, 2.43, 0.9), (0.04, 0.05, 0.04), "brillo", VELA)
    S.luz(6.0, 2.42, 0.95, 18.0, VELA, 0.04, fuego=0.3)
    viga(S.P, (10.0, H - 0.1, 2.8), (10.0, 2.8, 2.8), 0.012, "tela", (0.74, 0.66, 0.52))
    cilindro(S.P, (10.0, 3.4, 2.8), [(0, 0.08), (0.06, 0.08)], 10, "madera", MADERA_OSC, rot=rot_eje("z"), tapa_abajo=True)
    # --- LA TRASTIENDA: el fresno apilado, el banco de cortar con los pasadores en bruto, retales
    for k in range(4):                                                    # pilas de tablas con sus separadores
        z0 = 0.3 + k * 1.35
        for f in range(6):
            y = f * 0.17
            caja_mm(S.M, (0.1, y + 0.03, z0), (1.05, y + 0.12, z0 + 1.2), "madera", jit(FRESNO, 0.05), veta="larga")
            for zz in (z0 + 0.1, z0 + 1.05):
                caja_mm(S.M, (0.12, y, zz), (1.03, y + 0.03, zz + 0.05), "madera", MADERA_OSC)
    S.bloqueo(0.0, 0.25, 1.1, 5.7)
    bx0, bx1, bz0, bz1 = 2.0, 3.2, 1.65, 2.25
    for x in (bx0 + 0.15, bx1 - 0.15):
        viga(S.M, (x - 0.2, 0.0, (bz0 + bz1) * 0.5), (x, 0.72, (bz0 + bz1) * 0.5), 0.07, "madera", MADERA_OSC)
        viga(S.M, (x + 0.2, 0.0, (bz0 + bz1) * 0.5), (x, 0.72, (bz0 + bz1) * 0.5), 0.07, "madera", MADERA_OSC)
    caja_mm(S.M, (bx0, 0.72, bz0), (bx1, 0.8, bz1), "madera", jit(MADERA), veta="larga")
    for k in range(6):                                                    # los pasadores en bruto
        x = bx0 + 0.2 + k * 0.15
        cilindro(S.P, (x, 0.83, bz0 + 0.3), [(-0.11, 0.02), (0.07, 0.028), (0.1, 0.04), (0.12, 0.04)], 6, "madera",
                 jit(FRESNO), rot=rot_eje("z"), tapa_abajo=True)
    caja(S.P, (bx1 - 0.25, 0.83, bz1 - 0.12), (0.5, 0.02, 0.12), "hierro", (0.6, 0.6, 0.62), rot=R(y=8))     # la sierra
    cilindro(S.M, (1.75, 0.0, 4.5), [(0, 0.28), (0.5, 0.3), (0.52, 0.28)], 10, "madera", jit(MADERA_CLARA))  # el tajo
    caja(S.P, (1.8, 0.56, 4.45), (0.04, 0.04, 0.32), "madera", MADERA_OSC, rot=R(y=30, x=-25))               # el hacha
    caja(S.P, (1.77, 0.66, 4.32), (0.12, 0.08, 0.02), "hierro", HIERRO, rot=R(y=30))
    S.bloqueo(bx0 - 0.2, bz0, bx1 + 0.2, bz1)
    S.bloqueo(1.45, 4.2, 2.05, 4.8)
    cesta(S.P, (1.6, 0.0, 6.3), 0.3, 0.32, MIMBRE, asa=False)
    for k in range(6):
        caja(S.P, (1.6 + RND.uniform(-0.15, 0.15), 0.34, 6.3 + RND.uniform(-0.15, 0.15)), (0.3, 0.05, 0.06), "madera",
             jit(FRESNO), rot=R(y=RND.uniform(0, 180)))
    S.bloqueo(1.3, 6.0, 1.9, 6.6)
    S.ancla("banco_corte", 2.6, 0.0, 3.0)
    S.objeto("banco_corte", "privado", "el banco de cortar con los pasadores en bruto (de Damián)")
    # --- puerta y anclas
    murete_sur(S, 0.75, None, "sillar", tono_muro(zoc, 0.75, 0.2, 0.0))
    S.suelo = [[0.3, 0.3, W - 0.45, D - 0.6], [W - 0.4, 1.35, 0.35, 1.5]]      # (hasta el umbral del portón)
    S.ancla("entrada", 11.2, 0.0, 2.1)
    S.ancla("salida", 12.6, 0.0, 2.1)
    return S


# ================================================================ VIVIENDA DE ODILA Y NELA (8 × 8, en profundidad)

def vivienda():
    W, D, H = 8.0, 8.0, 3.2
    YA = 0.35                                                           # la alcoba, dos escalones más arriba
    S = Sala("vivienda", W, D, H)
    S.camara = {"x": [3.6, 4.4], "z": [2.0, 4.6]}
    cal = (0.94, 0.91, 0.84)
    rodapie = (0.64, 0.43, 0.33)                                        # zócalo pintado de almagre
    # --- huecos: ventana de la alcoba al oeste (el sol de la tarde en el suelo), la de Odila al este, las del sur
    ventana(S, "o", 1.95, 2.75, YA + 1.05, YA + 1.85, postigo=AZUL_POSTIGO)
    ventana(S, "e", 3.95, 4.95, 1.05, 2.0, postigo=AZUL_POSTIGO)
    ventana(S, "e", 0.9, 1.5, YA + 1.25, YA + 1.85, postigo=AZUL_POSTIGO)
    S.hueco("s", 3.4, 4.6, 0.0, 2.2)
    S.hueco("s", 5.6, 6.8, 1.0, 2.0)
    S.hueco("s", 1.0, 2.0, 1.0, 1.9)
    # --- suelos: losas en la cocina, tablas anchas en la alcoba; la tarima y los dos escalones
    rejilla(S.M, 0.0, 3.0, W, D, 0.0, 0.55, 0.55, 0.02, "piedra",
            lambda ix, iz, c: mezcla(jit(elige(PIEDRA), 0.05), (0.42, 0.36, 0.30),
                                     0.3 * (1.0 - suave(0.3, 1.4, (c - Vector((1.1, 0, 4.7))).length))),
            (0.40, 0.37, 0.34), desfase=(0.12, 0.0))
    rejilla(S.M, 0.0, 0.0, W, 3.0, YA, 9.0, 0.24, 0.012, "madera",
            lambda ix, iz, c: jit(mezcla(MADERA, MADERA_CLARA, RND.random() * 0.5), 0.04), (0.24, 0.17, 0.12))
    caja_mm(S.M, (0.0, 0.0, 2.98), (W, YA, 3.02), "madera", jit(MADERA_OSC))                          # el canto de la tarima
    caja_mm(S.M, (3.2, 0.0, 3.0), (4.8, YA * 0.5, 3.35), "madera", jit(MADERA), veta="larga")         # los escalones
    caja_mm(S.M, (3.2, YA * 0.5 - 0.03, 3.33), (4.8, YA * 0.5, 3.38), "madera", MADERA_OSC)
    caja_mm(S.M, (3.2, YA - 0.03, 2.97), (4.8, YA, 3.03), "madera", MADERA_OSC)
    S.niveles = [[0.0, 0.0, W, 3.0, YA], [3.2, 3.0, 1.6, 0.35, YA * 0.5]]
    S.choques.append([W * 0.5, YA * 0.5, 1.5, W, YA, 3.0])
    S.choques.append([4.0, YA * 0.25, 3.175, 1.6, YA * 0.5, 0.35])
    # la baranda baja de la alcoba (deja ver dentro desde arriba), con sus postes al pie de la escalera
    for xa, xb in ((0.0, 3.2), (4.8, W)):
        caja_mm(S.M, (xa, YA + 0.5, 2.88), (xb, YA + 0.56, 2.98), "madera", jit(MADERA_OSC), veta="larga")
        x = xa + 0.05
        while x < xb:
            caja_mm(S.M, (x, YA, 2.9), (x + 0.05, YA + 0.5, 2.96), "madera", jit(MADERA_OSC))
            x += 0.28
    for x in (3.15, 4.85):
        caja(S.M, (x, (YA + 0.75) * 0.5, 2.93), (0.12, YA + 0.75, 0.12), "madera", MADERA_OSC, veta="larga")
    S.bloqueo(0.0, 2.85, 3.2, 3.0)
    S.bloqueo(4.8, 2.85, W, 3.0)
    S.pasos["alcoba"] = {"rect": [-0.5, -0.5, W + 1.0, 3.85], "siempre": True}
    S.ancla("alcoba", 4.0, YA, 2.45)
    # --- muros: encalados, con el zócalo de almagre (otra casa, otro color)
    for lado, a0, a1 in (("n", -0.3, W + 0.3), ("o", 0.0, D), ("e", 0.0, D)):
        pared(S, lado, a0, a1, H, 0.95, "revoque", tono_muro(rodapie, 0.95, 0.12, 0.0), "revoque",
              tono_muro(cal, H, 0.05, 0.12, (0.4, 4.7, 0.18, 2.2)))
    for x in (0.0, 2.6, 5.4, W):
        caja_mm(S.M, (x - 0.09, 0.0, 0.0), (x + 0.09, H, 0.11), "madera", jit(MADERA_OSC), veta="larga")
    caja_mm(S.M, (0.0, H - 0.2, 0.0), (W, H, 0.14), "madera", jit(MADERA_OSC), veta="larga")
    # --- EL HOGAR con la REPISA (muro oeste de la cocina): la GALGA está encima (copia de utensilios.glb, la pone Godot)
    caja_mm(S.M, (0.0, 0.0, 3.9), (0.9, 0.12, 5.5), "sillar", jit((0.66, 0.62, 0.56)))
    caja_mm(S.M, (0.0, 0.12, 3.9), (0.9, 0.95, 4.12), "sillar", jit((0.62, 0.58, 0.52)))
    caja_mm(S.M, (0.0, 0.12, 5.28), (0.9, 0.95, 5.5), "sillar", jit((0.62, 0.58, 0.52)))
    caja_mm(S.M, (0.0, 0.12, 4.12), (0.15, 0.95, 5.28), "hierro", (0.08, 0.06, 0.05))
    caja_mm(S.M, (0.0, 0.95, 3.85), (0.98, 1.42, 5.55), "sillar", lambda p: mezcla((0.70, 0.64, 0.56), TIZNE, 0.3))
    caja_mm(S.M, (0.0, 1.42, 3.82), (1.18, 1.5, 5.58), "madera", jit(MADERA_OSC), veta="larga")       # LA REPISA
    caja_mm(S.M, (0.0, 1.5, 4.0), (0.7, H, 5.4), "revoque", lambda p: mezcla(cal, TIZNE, 0.12 + 0.1 * (p.y - 1.5)))
    caja_mm(S.M, (0.9, 0.0, 4.1), (1.45, 0.025, 5.3), "sillar", (0.58, 0.54, 0.50))                  # la piedra del hogar
    for k in range(7):
        caja(S.M, (0.4 + RND.uniform(-0.1, 0.1), 0.16, 4.7 + RND.uniform(-0.3, 0.3)), (0.28, 0.07, 0.08), "brillo",
             jit((1.0, 0.48, 0.14), 0.1), rot=R(y=RND.uniform(-60, 60)))
    lena(S.P, 4.45, 0.15, 4.95, 0.12, 2, r=0.05, eje="x", largo=0.45)
    viga(S.P, (0.45, 0.95, 4.7), (0.45, 0.62, 4.7), 0.012, "hierro", HIERRO)
    cilindro(S.P, (0.45, 0.4, 4.7), [(0, 0.1), (0.08, 0.17), (0.22, 0.16), (0.24, 0.15)], 10, "hierro", HIERRO, tapa_abajo=True)
    S.luz(0.6, 0.55, 4.7, 130.0, FUEGO, 0.12, fuego=0.8)
    # en la repisa: la vela, dos tarros y la caja de los hilos (la galga va en el sitio «galga»)
    cilindro(S.P, (0.6, 1.5, 5.3), [(0, 0.035), (0.14, 0.03)], 7, "tela", (0.95, 0.92, 0.82))
    caja(S.M, (0.6, 1.67, 5.3), (0.025, 0.05, 0.025), "brillo", VELA)
    S.luz(0.62, 1.73, 5.3, 4.0, VELA, 0.02)
    tarro(S.P, (0.55, 1.5, 4.05), 0.2, 0.07, (0.66, 0.70, 0.74))
    tarro(S.P, (0.5, 1.5, 5.05), 0.16, 0.06)
    caja(S.P, (0.6, 1.56, 4.35), (0.22, 0.12, 0.16), "madera", MADERA_OSC)
    S.sitios["galga"] = {"pos": [0.98, 1.508, 4.9], "yaw": 0.0, "giro": 90.0, "luz": 1.0}   # tumbada, a lo largo
    S.bloqueo(0.0, 3.85, 1.2, 5.55)
    S.ancla("repisa", 1.65, 0.0, 4.6)
    S.objeto("repisa", "examinable", "la repisa del hogar, con la galga del carretero encima")
    # --- LA MESA FAMILIAR con sus bancos, el cántaro, la vajilla
    mesa(S.M, 5.0, 5.3, 6.8, 6.2, 0.76, MADERA)
    banco(S.M, 5.1, 4.95, 6.7, 5.2, 0.45)
    banco(S.M, 5.1, 6.3, 6.7, 6.55, 0.45)
    for k in range(3):
        cilindro(S.P, (5.35 + k * 0.6, 0.76, 5.55 + (k % 2) * 0.3), [(0, 0.05), (0.04, 0.1), (0.05, 0.11)], 9, "barro",
                 jit((0.88, 0.84, 0.74), 0.04), tapa_abajo=True)
    hogaza(S.P, (6.3, 0.76, 5.75), 0.1, 0.08)
    cantaro(S.M, (5.75, 0.76, 5.95), 0.32, 0.1, (0.82, 0.56, 0.38))
    S.bloqueo(5.0, 4.95, 6.8, 6.55)
    S.ancla("mesa", 5.9, 0.0, 7.15)
    S.objeto("mesa", "examinable", "la mesa de la familia")
    # el cántaro grande del agua en su pie (suroeste)
    caja_mm(S.M, (0.3, 0.0, 6.7), (0.95, 0.42, 7.35), "madera", jit(MADERA_OSC))
    cantaro(S.M, (0.62, 0.42, 7.02), 0.55, 0.18, (0.80, 0.52, 0.36))
    cilindro(S.P, (0.88, 0.42, 6.8), [(0, 0.04), (0.1, 0.045)], 8, "barro", (0.70, 0.50, 0.36), tapa_abajo=True)
    S.bloqueo(0.3, 6.7, 0.95, 7.35)
    S.ancla("cantaro", 1.5, 0.0, 7.25)
    S.objeto("cantaro", "ofrecido", "el agua del cántaro (la ofrece Odila)")
    # el vasar con los platos (muro este) y el rincón de Odila: silla, cesto de costura junto a la ventana
    caja_mm(S.M, (7.55, 0.0, 5.3), (W, 0.85, 6.7), "madera", jit(MADERA))
    for y in (1.3, 1.75):
        caja_mm(S.M, (7.7, y, 5.3), (W, y + 0.04, 6.7), "madera", jit(MADERA_OSC))
        for k in range(4):
            cilindro(S.P, (7.86, y + 0.04 + 0.13, 5.5 + k * 0.33), [(0, 0.0), (0.0, 0.13), (0.02, 0.13)], 10, "barro",
                     jit((0.88, 0.82, 0.70), 0.05), rot=rot_eje("x"), tapa_abajo=False)
    S.bloqueo(7.55, 5.3, W, 6.7)
    caja_mm(S.M, (7.05, 0.42, 3.9), (7.5, 0.47, 4.35), "madera", jit(MADERA))                           # la silla
    for x, z in ((7.08, 3.93), (7.47, 3.93), (7.08, 4.32), (7.47, 4.32)):
        caja(S.M, (x, 0.21, z), (0.04, 0.42, 0.04), "madera", MADERA_OSC)
    caja_mm(S.M, (7.44, 0.47, 3.9), (7.5, 1.0, 4.35), "madera", MADERA_OSC)
    cesta(S.P, (6.75, 0.0, 4.55), 0.18, 0.16, MIMBRE, asa=False)
    for k, col in enumerate(TELAS[:3]):
        caja(S.P, (6.75 + (k - 1) * 0.08, 0.18, 4.55), (0.1, 0.05, 0.14), "tela", col, rot=R(y=k * 30))
    S.ancla("odila", 7.25, 0.0, 4.1)
    # --- LA ALCOBA (+0,35): la cama grande, el arcón, la cama de Nela y su rincón con la RUEDA DE JUGUETE
    def cama(x0, z0, x1, z1, colcha, cab=0.95):
        caja_mm(S.M, (x0, YA, z0), (x1, YA + 0.32, z1), "madera", jit(MADERA_OSC), veta="larga")
        caja_mm(S.M, (x0 + 0.04, YA + 0.32, z0 + 0.04), (x1 - 0.04, YA + 0.5, z1 - 0.04), "tela", jit((0.92, 0.88, 0.80), 0.02))
        caja_mm(S.M, (x0 + 0.02, YA + 0.5, z0 + 0.45), (x1 - 0.02, YA + 0.56, z1 + 0.02), "tela", jit(colcha, 0.03))
        caja_mm(S.M, (x0 - 0.01, YA + 0.36, z0 + 0.45), (x0 + 0.03, YA + 0.53, z1 + 0.02), "tela", jit(colcha, 0.03))
        caja_mm(S.M, (x1 - 0.03, YA + 0.36, z0 + 0.45), (x1 + 0.01, YA + 0.53, z1 + 0.02), "tela", jit(colcha, 0.03))
        cilindro(S.M, ((x0 + x1) * 0.5, YA + 0.6, z0 + 0.22), [(-(x1 - x0) * 0.42, 0.06), (-(x1 - x0) * 0.38, 0.1),
                                                               ((x1 - x0) * 0.38, 0.1), ((x1 - x0) * 0.42, 0.06)],
                 8, "tela", (0.95, 0.93, 0.88), rot=rot_eje("x"))
        caja_mm(S.M, (x0, YA, z0 - 0.06), (x1, YA + cab, z0 + 0.02), "madera", jit(MADERA), veta="larga")
    cama(0.15, 0.12, 1.95, 2.1, (0.42, 0.56, 0.58))
    S.bloqueo(0.0, 0.0, 2.05, 2.2)
    cama(6.6, 0.12, 7.85, 1.5, (0.78, 0.38, 0.30), cab=0.7)
    for k in range(5):                                                    # retales en la colcha de Nela
        caja_mm(S.M, (6.7 + (k % 3) * 0.35, YA + 0.561, 0.7 + (k // 3) * 0.35), (6.95 + (k % 3) * 0.35, YA + 0.565,
                0.95 + (k // 3) * 0.35), "tela", TELAS[k % len(TELAS)])
    S.bloqueo(6.55, 0.0, W, 1.55)
    # el arcón (privado): tapa curva, herrajes
    caja_mm(S.M, (2.35, YA, 0.12), (3.35, YA + 0.48, 0.68), "madera", jit(MADERA_OSC), veta="larga")
    cilindro(S.M, (2.85, YA + 0.48, 0.4), [(-0.5, 0.0), (-0.5, 0.27), (0.5, 0.27), (0.5, 0.0)], 8, "madera",
             jit(MADERA_OSC), rot=rot_eje("x"))
    for x in (2.5, 3.2):
        caja_mm(S.M, (x - 0.025, YA, 0.1), (x + 0.025, YA + 0.62, 0.7), "hierro", HIERRO)
    caja(S.M, (2.85, YA + 0.4, 0.69), (0.08, 0.1, 0.02), "hierro", LATON)
    S.bloqueo(2.35, 0.1, 3.35, 0.7)
    S.ancla("arcon", 2.85, YA, 1.35)
    S.objeto("arcon", "privado", "el arcón de Odila")
    # la percha con la ropa (muro norte) y un candil en la pared
    caja_mm(S.M, (3.6, YA + 1.5, 0.0), (5.6, YA + 1.58, 0.06), "madera", MADERA_OSC)
    for k, col in enumerate(((0.52, 0.66, 0.80), (0.86, 0.42, 0.34), (0.92, 0.90, 0.84))):
        x = 3.85 + k * 0.6
        placa(S.M, [(-0.2, 0.0), (0.2, 0.0), (0.26, -0.75), (-0.26, -0.75)], (x, YA + 1.5, 0.07), (1, 0, 0), (0, 1, 0), 0.04,
              "tela", jit(col, 0.03))
    caja(S.M, (6.1, YA + 1.7, 0.05), (0.06, 0.12, 0.1), "hierro", LATON)
    caja(S.M, (6.1, YA + 1.79, 0.1), (0.025, 0.04, 0.025), "brillo", VELA)
    S.luz(6.1, YA + 1.85, 0.16, 6.0, VELA, 0.02)
    # EL RINCÓN DE NELA: la alfombra de tiras, la rueda de juguete (eco del taller), la muñeca, los tacos
    for k in range(6):
        col = mezcla(TELAS[(k * 2) % len(TELAS)], (0.55, 0.42, 0.32), 0.3)
        caja_mm(S.M, (4.6, YA + 0.005, 0.45 + k * 0.22), (6.3, YA + 0.018, 0.45 + (k + 1) * 0.22 - 0.01), "tela", jit(col, 0.04))
    rueda(S.P, (5.35, YA + 0.13, 1.15), 0.12, 6, eje="x", col=FRESNO, llanta=False)
    viga(S.P, (5.35, YA + 0.13, 1.15), (5.75, YA + 0.02, 1.62), 0.02, "madera", MADERA_CLARA)
    cilindro(S.P, (5.95, YA + 0.02, 0.9), [(0, 0.07), (0.16, 0.06), (0.2, 0.0)], 7, "tela", (0.86, 0.42, 0.34))   # la muñeca
    cilindro(S.P, (5.95, YA + 0.2, 0.9), [(0, 0.045), (0.05, 0.05), (0.09, 0.0)], 7, "tela", (0.95, 0.85, 0.72))
    for k in range(5):
        caja(S.P, (4.85 + RND.uniform(0, 0.4), YA + 0.03, 0.75 + RND.uniform(0, 0.5)), (0.06, 0.06, 0.06), "madera",
             jit(TELAS[k % len(TELAS)], 0.05), rot=R(y=RND.uniform(0, 90)))
    S.ancla("rincon", 5.4, YA, 2.35)
    S.ancla("nela", 5.5, YA, 1.0)
    S.objeto("rincon", "examinable", "el rincón de Nela, con una rueda de juguete tallada")
    # --- puerta y anclas
    murete_sur(S, 0.75, (3.4, 4.6), "revoque", tono_muro(rodapie, 0.75, 0.15, 0.0))
    S.ancla("entrada", 4.0, 0.0, 6.4)
    S.ancla("salida", 4.0, 0.0, 7.75)
    return S


# ================================================================ de las listas a Blender, horneado y salida

def texturas():
    carpeta = os.path.join(os.path.dirname(os.path.abspath(CARPETA)) if CARPETA else "", "muestra_calle", "texturas")
    imgs = {}
    for m, t in TEX_DE.items():
        if t is None or t in imgs:
            continue
        ruta = os.path.join(carpeta, t + ".png")
        imgs[t] = bpy.data.images.load(ruta, check_existing=True) if os.path.exists(ruta) else None
    return imgs


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
            bsdf.inputs["Emission Strength"].default_value = 3.0
        else:
            img = imgs.get(TEX_DE[m])
            if img is not None:
                tex = nt.nodes.new("ShaderNodeTexImage")
                tex.image = img
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
            else:
                nt.links.new(vc.outputs["Color"], bsdf.inputs["Base Color"])
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


def a_blender(nombre, M, mats, con_luz_uv, origen=None):
    verts, polys, cols, uvs, suaves, mi = [], [], [], [], [], []
    o = origen if origen is not None else Vector((0, 0, 0))
    for pts, mat, cs, uv, suave in M.caras:
        base = len(verts)
        for p in pts:
            verts.append((p.x, -p.z, p.y))                 # Godot (x, y, z) → Blender (x, -z, y)
        polys.append(list(range(base, base + len(pts))))
        cols.extend(cs)
        uvs.extend(uv if uv is not None else uv_mundo(pts, mat))
        suaves.append(suave)
        mi.append(MATS.index(mat))
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
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    if origen is not None:                                  # el origen del objeto en «origen» (la bisagra)
        bmesh.ops.translate(bm, verts=bm.verts, vec=Vector((-o.x, o.z, -o.y)))
    bm.to_mesh(me)
    bm.free()
    if origen is not None:
        ob.location = (o.x, -o.z, o.y)
    me.color_attributes.active_color = me.color_attributes["Col"]
    return ob


def camaras(S):
    out = []
    xs, zs = S.camara["x"], S.camara["z"]
    a = math.radians(CAM_INCL)
    ad = Vector((0.0, -math.sin(a), -math.cos(a)))
    for k in range(3):
        for j in range(3):
            fx = xs[0] + (xs[1] - xs[0]) * k / 2
            fz = zs[0] + (zs[1] - zs[0]) * j / 2
            p = Vector((fx, CAM_ALTO, fz + CAM_SUR))
            der = ad.cross(Vector((0, 1, 0))).normalized()
            arr = der.cross(ad).normalized()
            out.append((p, ad, arr, der))
    return out


def recortar(S, M, otra=None):
    """Separa lo que ve alguna cámara de interior de lo que no (eso solo sirve para el horneado)."""
    verts, polys = [], []
    for pts, *_ in M.caras + (otra.caras if otra is not None else []):
        b = len(verts)
        verts.extend([Vector((p.x, p.y, p.z)) for p in pts])
        polys.append(list(range(b, b + len(pts))))
    bvh = BVHTree.FromPolygons(verts, polys, all_triangles=False, epsilon=0.0)
    cams = camaras(S)
    tf = math.tan(math.radians(CAM_FOV) * 0.5) * 1.1
    vis, ocu = Malla(), Malla()
    for idx, cara in enumerate(M.caras):
        pts = cara[0]
        n = normal_de(pts)
        c = sum(pts, Vector((0, 0, 0))) / len(pts)
        muestras = [c] + [c.lerp(p, 0.9) for p in pts]
        doble = cara[1] in ("tela",)
        visto = False
        for cp, ad, arr, der in cams:
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
                    break
            if visto:
                break
        (vis if visto else ocu).caras.append(cara)
    return vis, ocu


def limpiar():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    for coleccion in (bpy.data.meshes, bpy.data.materials, bpy.data.lights):
        for x in list(coleccion):
            coleccion.remove(x)
    for img in list(bpy.data.images):
        if img.name.startswith("int_") or img.name.startswith("cal_"):
            bpy.data.images.remove(img)


def preparar_cycles(S):
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
                break
        except Exception as e:
            nota("sin %s: %s" % (t, e))
    sc.cycles.samples = MUESTRAS
    sc.cycles.use_denoising = False
    sc.cycles.max_bounces = 5
    sc.cycles.diffuse_bounces = 4
    sc.cycles.glossy_bounces = 0
    sc.cycles.transparent_max_bounces = 2
    sc.cycles.sample_clamp_indirect = 4.0
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
    # el relleno: lo que rebota del techo y de las paredes encaladas (un panel tenue y cálido bajo cada techo). Sin él,
    # con solo las ventanas y el fuego, la sala queda negra salvo las manchas de sol y el resplandor (contraste 1:300).
    for k, (x0, z0, x1, z1, y) in enumerate(S.techos):
        ld = bpy.data.lights.new("relleno_%d" % k, 'AREA')
        ld.shape = 'RECTANGLE'
        ld.size = x1 - x0
        ld.size_y = z1 - z0
        ld.energy = RELLENO.get(S.id, 1.0) * (x1 - x0) * (z1 - z0)
        ld.color = (1.0, 0.86, 0.72)
        lo = bpy.data.objects.new("relleno_%d" % k, ld)
        lo.location = ((x0 + x1) * 0.5, -(z0 + z1) * 0.5, y - 0.06)
        sc.collection.objects.link(lo)
    for k, (x, y, z, w_, col, r) in enumerate(S.luces):
        ld = bpy.data.lights.new("luz_%d" % k, 'POINT')
        ld.energy = w_
        ld.color = col
        ld.shadow_soft_size = r
        lo = bpy.data.objects.new("luz_%d" % k, ld)
        lo.location = (x, -z, y)
        sc.collection.objects.link(lo)


def hornear(ob_fijo, objs_vertice, img):
    sc = bpy.context.scene
    me = ob_fijo.data
    me.uv_layers.active = me.uv_layers["luz"]
    bpy.ops.object.select_all(action='DESELECT')
    ob_fijo.select_set(True)
    bpy.context.view_layer.objects.active = ob_fijo
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.004, area_weight=0.0, correct_aspect=True,
                             scale_to_bounds=False)
    try:
        bpy.ops.uv.pack_islands(udim_source='CLOSEST_UDIM', rotate=True, margin=0.004)
    except Exception as e:
        nota("pack_islands: %s" % e)
    bpy.ops.object.mode_set(mode='OBJECT')
    if not HORNEAR:
        return
    sc.render.bake.margin = 4
    sc.render.bake.margin_type = 'EXTEND'
    bpy.ops.object.bake(type='DIFFUSE', pass_filter={'DIRECT', 'INDIRECT'}, margin=4, target='IMAGE_TEXTURES',
                        use_clear=True)
    nota("mapa de luz horneado (%d muestras)" % MUESTRAS)
    bpy.ops.object.select_all(action='DESELECT')
    for ob in objs_vertice:
        vm = ob.data
        luzc = vm.color_attributes.new("LuzV", 'FLOAT_COLOR', 'CORNER')
        vm.color_attributes.active_color = luzc
        ob.select_set(True)
        bpy.context.view_layer.objects.active = ob
    bpy.ops.object.bake(type='DIFFUSE', pass_filter={'DIRECT', 'INDIRECT'}, target='VERTEX_COLORS', use_clear=True)
    nota("piezas horneadas a los vértices")


OBJETIVO = {"horno": 0.95, "taller": 0.9, "vivienda": 0.85}      # la luz del percentil 70 de lo fijo, en Godot
REFERENCIA = 70                                                  # (la mediana la hunden los bajos y los cantos)
V_ESCALA = 3.0                                                   # piezas: COLOR_0 = tinte × luz × k / V_ESCALA
RELLENO = {"horno": 0.9, "taller": 1.1, "vivienda": 0.9}         # vatios por m² de techo
COMPRESION = 4.0                                                 # lo más brillante queda en ≈ 5 × la mediana


def comprimir(rgb, m):
    """Las luces altas, suavizadas (Reinhard sobre la mediana m, conservando el tono): x = L/m → x/(1 + x/c)·(1 + 1/c).
    La mediana no cambia; el fuego y las manchas de sol quedan a unas 5 veces la mediana en vez de 300 (no se queman)."""
    lum = np.maximum(rgb.max(-1), 1e-6)
    x = lum / m
    k = (x / (1.0 + x / COMPRESION) * (1.0 + 1.0 / COMPRESION)) / x
    return rgb * k[..., None]


def escala_y_guardar(S, img, carpeta, objs_vertice):
    w, h = img.size
    px = np.array(img.pixels[:], np.float32).reshape(h, w, 4)
    lum = px[..., :3].max(-1)
    validos = lum[lum > 0.0005]
    mediana = float(np.percentile(validos, REFERENCIA)) if validos.size else 1.0
    k = OBJETIVO.get(S.id, 1.0) / max(mediana, 1e-4)
    px[..., :3] = np.where((lum > 0.0005)[..., None], comprimir(px[..., :3], mediana), px[..., :3])
    lum = px[..., :3].max(-1)
    validos = lum[lum > 0.0005]
    escala = float(np.percentile(validos, 99.7)) / 0.97 if validos.size else 1.0
    nombre = "int_%s_luz_1024" % S.id
    q = np.clip(px[..., :3] / escala, 0, 1) ** (1 / 2.2)
    im2 = bpy.data.images.new(nombre, w, h, alpha=False)
    a = np.ones((h, w, 4), np.float32)
    a[..., :3] = q
    im2.pixels.foreach_set(a.ravel())
    if w != 1024:
        im2.scale(1024, 1024)
    im2.filepath_raw = os.path.join(carpeta, nombre + ".png")
    im2.file_format = 'PNG'
    im2.save()
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
        idx_brillo = [i for i, mt in enumerate(vm.materials) if mt is not None and mt.name == "brillo"]
        if idx_brillo:
            mat_pol = np.zeros(len(vm.polygons), np.int32)
            vm.polygons.foreach_get("material_index", mat_pol)
            mat_esq = np.zeros(len(vm.loops), np.int32)
            for p in vm.polygons:
                mat_esq[p.loop_start:p.loop_start + p.loop_total] = mat_pol[p.index]
        l[:, :3] = comprimir(np.maximum(l[:, :3], 0.0), mediana)
        l[:, :3] *= k / V_ESCALA                         # (con la exposición ya puesta: valores medios, sin perderse en 8 bits)
        if idx_brillo:
            l[np.isin(mat_esq, idx_brillo), :3] = 1.0
        c[:, :3] = np.clip(c[:, :3] * l[:, :3], 0, 1)
        col.data.foreach_set("color", c.ravel())
        vm.color_attributes.remove(luz)
        vm.color_attributes.active_color = vm.color_attributes["Col"]
    # exposición de interior: el percentil 70 de la luz de lo fijo queda en OBJETIVO (la relación entre el fuego, la
    # ventana y los rincones no cambia; solo cuánta luz hay en conjunto). Godot multiplica lo fijo por «escala»
    # (= escala_mapa × k) y las piezas por «escala_vertice» (= V_ESCALA).
    return escala, mediana, k


def sondas(S, bvh):
    """Rejilla de 0,5 m a 1 m del suelo: «sol» = cuánto sol directo llega (por las ventanas); «cielo» = la luz de
    relleno: cielo que entra por los huecos más el resplandor de los fuegos (aproximado, 0-1)."""
    paso = 0.5
    nx, nz = int(S.W / paso) + 1, int(S.D / paso) + 1
    hs = hacia_sol()
    t1 = hs.cross(Vector((0, 1, 0))).normalized()
    t2 = hs.cross(t1).normalized()
    rad = math.tan(math.radians(SOL_ANGULO) * 0.5)
    dirs_sol = [(hs + t1 * rad * math.cos(k * 1.3) * (k / 7) + t2 * rad * math.sin(k * 1.3) * (k / 7)).normalized()
                for k in range(8)]
    dirs_cielo = []
    for k in range(32):
        u, v = (k + 0.5) / 32, (k * 0.618034) % 1.0
        r = math.sqrt(u)
        a = math.tau * v
        dirs_cielo.append(Vector((r * math.cos(a), math.sqrt(1 - u), r * math.sin(a))))
    sol, cielo = [], []
    for j in range(nz):
        for i in range(nx):
            x, z = i * paso, j * paso
            y = 1.0
            for nv in S.niveles:
                if nv[0] <= x <= nv[0] + nv[2] and nv[1] <= z <= nv[1] + nv[3]:
                    y = max(y, nv[4] + 1.0)
            pb = Vector((x, -z, y))
            s = sum(1 for d in dirs_sol if bvh.ray_cast(pb, Vector((d.x, -d.z, d.y)), 200.0)[0] is None)
            c = sum(1 for d in dirs_cielo if bvh.ray_cast(pb, Vector((d.x, -d.z, d.y)), 60.0)[0] is None)
            f = 0.0
            for fx, fy, fz, fuerza in S.fuegos:
                q = Vector((fx, -fz, fy))
                d = q - pb
                L = d.length
                if L < 0.05 or bvh.ray_cast(pb, d / L, L - 0.05)[0] is None:
                    f += fuerza / (1.0 + 0.25 * L * L)
            sol.append(round(s / len(dirs_sol), 3))
            cielo.append(round(min(1.0, 0.25 + 2.5 * c / len(dirs_cielo) + 0.5 * f), 3))
    return {"origen": [0.0, 0.0], "paso": paso, "nx": nx, "nz": nz, "altura": 1.0, "sol": sol, "cielo": cielo}


def exportar(objs, ruta):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=ruta, export_format='GLB', use_selection=True, export_animations=False,
                              export_yup=True, export_vertex_color='ACTIVE', export_all_vertex_colors=False,
                              export_cameras=False, export_lights=False, export_apply=True, export_texcoords=True,
                              export_normals=True, export_image_format='NONE', export_materials='EXPORT')
    nota("EXPORTADO %s" % ruta)


def hacer(constructor):
    limpiar()
    S = constructor()
    carpeta_mod = os.path.join(CARPETA, "modelos")
    carpeta_int = os.path.join(CARPETA, "interiores")
    for c in (carpeta_mod, carpeta_int):
        os.makedirs(c, exist_ok=True)
    nota("%s: %d triángulos fijos, %d de piezas, %d ocultos, %d luces" % (S.id, S.M.tris(), S.P.tris(), S.O.tris(), len(S.luces)))
    vis, ocu = recortar(S, S.M, S.P)
    pvis, pocu = recortar(S, S.P, S.M)
    ocu.caras += pocu.caras + S.O.caras
    nota("%s: recorte: %d + %d a la vista, %d solo para el horneado" % (S.id, vis.tris(), pvis.tris(), ocu.tris()))
    img_luz = bpy.data.images.new("int_luz_" + S.id, RES, RES, alpha=False, float_buffer=True)
    imgs = texturas()
    mats = materiales(imgs, img_luz)
    ob_fijo = a_blender("fijo", vis, mats, True)
    if not pvis.caras:
        pvis.cara([Vector((0, -5, 0)), Vector((0.01, -5, 0)), Vector((0, -5, 0.01))], "madera", (0.5, 0.4, 0.3))
    ob_pie = a_blender("piezas", pvis, mats, False)
    ob_ocu = a_blender("oculto", ocu, mats, False) if ocu.caras else None
    extras = [a_blender(n, m, mats, False, origen) for n, (m, origen) in S.extra.items()]
    datos = {"id": S.id, "tam": [S.W, S.D], "alto": S.H, "suelo": S.suelo, "bloqueos": S.bloqueos, "pasos": S.pasos,
             "niveles": S.niveles, "choques": [[round(v, 4) for v in c] for c in S.choques], "anclas": S.anclas,
             "objetos": S.objetos, "sitios": S.sitios, "fuegos": S.fuegos, "camara": S.camara,
             "tris": {"fijo": vis.tris(), "piezas": pvis.tris(), "extra": sum(m.tris() for m, _ in S.extra.values()),
                      "oculto": ocu.tris()},
             "horneado": HORNEAR, "muestras": MUESTRAS}
    preparar_cycles(S)
    hornear(ob_fijo, [ob_pie] + extras, img_luz)
    if HORNEAR:
        escala, mediana, k = escala_y_guardar(S, img_luz, carpeta_mod, [ob_pie] + extras)
        datos.update({"escala_mapa": escala, "mediana": mediana, "k_exposicion": k, "escala": escala * k,
                      "escala_vertice": V_ESCALA})
    else:
        datos.update({"escala_mapa": 1.0, "mediana": 1.0, "k_exposicion": 1.0, "escala": 1.0, "escala_vertice": 1.0})
    objs = [o for o in (ob_fijo, ob_pie, ob_ocu) if o is not None] + extras
    dg = bpy.context.evaluated_depsgraph_get()
    vs, ps = [], []
    for o in objs:
        m = o.evaluated_get(dg).data
        b = len(vs)
        vs.extend([o.matrix_world @ v.co for v in m.vertices])
        ps.extend([[b + i for i in p.vertices] for p in m.polygons])
    datos["sondas"] = sondas(S, BVHTree.FromPolygons(vs, ps))
    exportar([ob_fijo, ob_pie] + extras, os.path.join(carpeta_mod, "int_%s.glb" % S.id))
    with open(os.path.join(carpeta_int, "%s.json" % S.id), "w", encoding="utf-8") as f:
        json.dump(datos, f, ensure_ascii=False, indent=1)
    nota("HECHO %s: %s" % (S.id, json.dumps({k: v for k, v in datos.items() if k in ("tris", "escala", "mediana", "k_exposicion")})))


def main():
    for nombre, f in (("horno", horno), ("taller", taller), ("vivienda", vivienda)):
        if SOLO and SOLO != nombre:
            continue
        hacer(f)
    nota("FIN")


if __name__ == "__main__":                                      # (crear_utensilios_barrio.py importa el kit)
    main()
