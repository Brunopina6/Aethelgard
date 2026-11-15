# MUESTRA GRÁFICA de una calle de Oakhaven (V12, 15/11, EN PRUEBAS: solo desde el banco de pruebas de Auditoría).
# Hecho desde cero con este guion: geometría procedural propia, texturas pintadas por código (numpy) y luz horneada con
# Cycles. Ningún recurso descargado, de pago ni de la nube (obra propia del proyecto). Misma semilla, mismo resultado.
#
#   blender -b --factory-startup -P crear_calle.py -- <carpeta zonas3d/muestra_calle> [opciones]
#     --fase blockout|arquitectura|completa   hasta dónde se construye (las pasadas del encargo; por defecto completa)
#     --sin-horneado                          sin luz horneada (pasadas de composición, arquitectura y materiales)
#     --sin-recorte                           sin quitar las caras que la cámara nunca ve (para comparar)
#     --muestras N                            muestras de Cycles del horneado (por defecto 256)
#     --res N                                 lado del mapa de luz grande (por defecto 2048; el pequeño es la mitad)
#
# Escribe (en <carpeta>):
#   modelos/calle.glb         la calle montada en sus coordenadas (x al este, y arriba, z al sur; Kael anda por z ≈ 0-3)
#     objeto «calle»           lo fijo: una superficie por material, UV0 = textura que se repite, UV1 = mapa de luz,
#                              COLOR_0 = tinte (lineal)
#     objeto «piezas»          losas del empedrado y objetos sueltos (barriles, cajones, macetas, carretilla, faroles de
#                              pie, leña…): COLOR_0 = tinte × luz horneada en los vértices / ESCALA (son miles de islas
#                              pequeñas: en el mapa de luz se comían el sitio de las fachadas)
#     objeto «vegetacion»      matas, hojas y flores: COLOR_0 = tinte × luz horneada en los vértices / ESCALA, alfa =
#                              cuánto lo mueve el viento (0 en la base, 1 en la punta)
#     (objeto «oculto»         lo que ninguna cámara ve: solo existe en Blender para el horneado —tapa y rebota luz— y no
#                              se exporta)
#     vacíos «choque_*»        cajas de choque (escala = medio tamaño)
#     vacíos «ancla_*»         sitios con nombre (faroles, humo de las chimeneas, la puerta, la esquina)
#   modelos/calle_luz_<res>.png y calle_luz_<res/2>.png   mapa de luz (luz / ESCALA, codificada con gamma 2,2)
#   modelos/calle_luz.json     ESCALA, el sol y el cielo del horneado (para iluminar igual a Kael) y las sondas: en una
#                              rejilla de 0,25 m a 1 m del suelo, cuánto sol y cuánto cielo llega (Kael en la sombra)
#   texturas/*.png             las texturas que se repiten (512², sin color: el color lo pone el tinte)
#
# Materiales (zonas3d/muestra_calle/muestra_calle.gd los sustituye por los suyos, por nombre):
#   piedra tierra revoque madera tejas sillar hierro tela barro  → sombreado «estático» (textura × tinte × mapa de luz)
#   hoja                                                         → vegetación (textura × color con luz, viento)
#   brillo                                                       → lo que da luz (cristales de faroles, ventanas)
#
# Cámara: la de la muestra (muestra_calle.gd, OFFSET_CAMARA / INCLINACION): 10,8 m sobre los pies de Kael, 14,2 m al
# sur, 25° hacia abajo y 38° de campo. Nunca gira: por eso solo se ven las fachadas que dan al sur y al oeste-este, y
# el recorte quita lo que ninguna de las cámaras posibles ve (las caras del norte, los bajos, lo que queda dentro).
import bpy, bmesh, sys, os, math, random, json, time
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree
import numpy as np

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
CARPETA = argv[0] if argv and not argv[0].startswith("--") else ""
FASE = "completa"
HORNEAR = True
RECORTE = True
MUESTRAS = 256
RES = 2048
i = 0
while i < len(argv):
    a = argv[i]
    if a == "--fase":
        FASE = argv[i + 1]; i += 1
    elif a == "--sin-horneado":
        HORNEAR = False
    elif a == "--sin-recorte":
        RECORTE = False
    elif a == "--muestras":
        MUESTRAS = int(argv[i + 1]); i += 1
    elif a == "--res":
        RES = int(argv[i + 1]); i += 1
    i += 1
BLOCKOUT = FASE == "blockout"
DETALLE = FASE in ("arquitectura", "completa")
DECORADO = FASE == "completa"
T0 = time.time()


def nota(t):
    print("[calle %5.1f s] %s" % (time.time() - T0, t), flush=True)


RND = random.Random(1511)
NP = np.random.default_rng(1511)

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


# ---------------------------------------------------------------- cámaras (para recortar lo que nunca se ve)
CAM_ALTO, CAM_SUR, CAM_INCL, CAM_FOV, CAM_ASPECTO = 10.8, 14.2, 25.0, 38.0, 1600.0 / 720.0   # (16:9 hoy; 20:9 por si)
KAEL_Z = 0.9                                # muestra_calle.gd, SITIO_FOTO / la z de la calle
CAM_X = (-3.5, 3.5)                         # muestra_calle.gd, CAMARA_X: la cámara sigue a Kael en x entre estos


def camaras():
    """[(posición, adelante, arriba, derecha, fov vertical, aspecto)] de todas las cámaras posibles (Godot)."""
    r = []
    for x in (CAM_X[0], 0.0, CAM_X[1]):
        for kz, ky in ((KAEL_Z, 0.0), (-5.6, 0.85), (2.8, 0.0)):
            cz = KAEL_Z + CAM_SUR + min(0.0, kz - KAEL_Z) * 0.55     # muestra_calle.gd, _colocar_camara
            p = Vector((x, CAM_ALTO + ky, cz))
            a = math.radians(CAM_INCL)
            ad = Vector((0.0, -math.sin(a), -math.cos(a)))
            r.append((p, ad))
    # la cámara de juego de Oakhaven (52°, 18 m, ojo a 0,9 m) con Kael en el sitio de la foto: la comparación
    ojo = Vector((-1.0, 0.95, KAEL_Z))
    a = math.radians(52.0)
    p = ojo + Vector((0.0, math.sin(a), math.cos(a))) * 18.0
    r.append((p, (ojo - p).normalized()))
    # las vistas fijas (muestra_calle.gd, VISTAS)
    for _n, p, mira, _f in VISTAS:
        r.append((Vector(p), (Vector(mira) - Vector(p)).normalized()))
    out = []
    for p, ad in r:
        der = ad.cross(Vector((0, 1, 0))).normalized()
        arr = der.cross(ad).normalized()
        out.append((p, ad, arr, der))
    return out


VISTAS = [  # [nombre, posición, punto al que mira, fov] — iguales en muestra_calle.gd
    ["vista_puerta", (-6.2, 3.4, 5.6), (-6.4, 1.6, -2.4), 38.0],
    ["vista_esquina", (11.2, 4.6, 6.4), (8.6, 3.0, -2.0), 38.0],
    ["vista_callejon", (0.4, 3.0, 6.0), (0.0, 1.6, -5.0), 38.0],
]

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
TEJA = ((0.80, 0.44, 0.30), (0.84, 0.48, 0.33), (0.76, 0.41, 0.29), (0.82, 0.50, 0.36))
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


# ---------------------------------------------------------------- suelo: tierra y losas irregulares

def altura_suelo(x, z):
    """La altura de lo que se pisa (el callejón sube por sus escalones). Igual en muestra_calle.gd (los choques)."""
    if -1.75 < x < 1.75 and z < -3.4:
        return min(0.85, max(0.0, (-3.4 - z) / 0.4 * 0.17 + 0.17)) if z > -5.4 else 0.85
    return 0.0


def ruido2(x, z, f=1.0):
    return (math.sin(x * 1.7 * f + 1.3) * math.cos(z * 1.3 * f - 0.7) + math.sin(x * 0.53 * f - z * 0.91 * f + 2.1)) * 0.5


def suelo(M):
    """Tierra pisada en una rejilla de 0,5 m con algo de relieve (más baja bajo las losas, que asoman)."""
    x0, x1, z0, z1, paso = -26.0, 26.0, -12.0, 8.0, 0.5
    nx, nz = int((x1 - x0) / paso), int((z1 - z0) / paso)
    def y(x, z):
        if -1.8 < x < 1.8 and z < -5.4:
            return 0.85 - 0.01
        en_calle = -2.3 < z < 2.6
        return 0.012 * ruido2(x, z, 2.2) + (-0.02 if en_calle else 0.0) + 0.02 * max(0.0, z - 3.2) * 0.3
    for i in range(nx):
        for j in range(nz):
            xa, za = x0 + i * paso, z0 + j * paso
            if -1.8 < xa + paso * 0.5 < 1.8 and -5.4 < za + paso * 0.5 < -2.6:
                continue                                  # los escalones del callejón
            pts = [Vector((xa, y(xa, za), za)), Vector((xa, y(xa, za + paso), za + paso)),
                   Vector((xa + paso, y(xa + paso, za + paso), za + paso)), Vector((xa + paso, y(xa + paso, za), za))]
            cx, cz = xa + paso * 0.5, za + paso * 0.5
            t = 0.5 + 0.5 * ruido2(cx * 0.7, cz * 0.7, 1.0)
            c = mezcla(TIERRA, (0.70, 0.62, 0.50), t)
            if abs(cz - 0.2) > 2.6:                       # la orilla, con algo de verde
                c = mezcla(c, (0.62, 0.62, 0.42), 0.35 * max(0.0, ruido2(cx, cz, 0.8)))
            M.cara(pts, "tierra", jit(c, 0.008), suave=True)


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


def en_camino(x, z):
    """¿Va una losa aquí? El empedrado de la calle con la orilla deshecha, el del callejón y el de las puertas."""
    borde_n = -2.15 + 0.18 * ruido2(x * 1.3, 0.0, 1.0)
    borde_s = 2.25 + 0.32 * ruido2(x * 0.9, 3.0, 1.0)
    if -1.7 < x < 1.7 and -3.4 < z < -2.0:
        return 1.0                                        # la boca del callejón
    if -1.7 < x < 1.7 and -9.0 < z < -5.5:
        return 0.45                                       # el rellano de arriba
    if z < borde_n or z > borde_s or abs(x) > 15.5:
        return 0.0
    dentro = min(z - borde_n, borde_s - z, 15.5 - abs(x))
    return min(1.0, dentro / 0.7)


def empedrado(M, V):
    semillas = []
    paso = 0.42
    x = -16.0
    while x < 16.0:
        z = -9.2
        while z < 3.0:
            semillas.append((x + RND.uniform(-0.17, 0.17), z + RND.uniform(-0.17, 0.17)))
            z += paso
        x += paso
    juntas = []                                           # sitios de las juntas (para la hierba de las grietas)
    for s, poly in voronoi(semillas, None, 0.045):
        p = en_camino(s[0], s[1])
        if p <= 0.0:
            continue
        if RND.random() > p * 0.97 + (0.03 if p >= 1.0 else 0.0):
            juntas.append(s)                              # losa que falta: tierra (y a veces hierba)
            continue
        if RND.random() < 0.05 and p < 1.0:
            juntas.append(s)
            continue
        y0 = altura_suelo(s[0], s[1])
        col = jit(elige(PIEDRA), 0.08)
        if RND.random() < 0.12:
            col = mezcla(col, MUSGO, RND.uniform(0.1, 0.3))
        if RND.random() < 0.08:
            col = mezcla(col, (0.55, 0.52, 0.50), 0.5)
        alto = RND.uniform(0.035, 0.065) if p >= 0.6 else RND.uniform(0.02, 0.05)
        losa(M, poly, y0 - 0.005, alto, col, (RND.uniform(-0.03, 0.03), RND.uniform(-0.03, 0.03)))
        if p < 0.9 or RND.random() < 0.08:
            juntas.append(poly[RND.randrange(len(poly))])
    return juntas


# ---------------------------------------------------------------- arquitectura

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
            col = jit(elige(filas_col), 0.06)
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
    ancla_p("humo_%d_%d" % (int(x * 10), int(z * 10)), (x, y1 + 0.5, z))


ANCLAS = {}
CHOQUES = []


def ancla_p(nombre, p):
    ANCLAS[nombre] = tuple(p)


def choque(c, s, yaw=0.0):
    CHOQUES.append((tuple(c), tuple(s), yaw))


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


# ------------------------------------------------------------- la casa de la puerta (A): larga, alero a la calle

A_X0, A_X1 = -12.4, -1.8          # fachada
A_Z = -2.6                        # muro de la planta baja (al sur)
A_FONDO = 6.2
A_PB = 3.1                        # alto de la planta baja
A_VUELO = 0.55                    # el piso sobresale
A_P1 = 2.55
PUERTA_X = -6.6


def casa_a(M, V):
    zf = A_Z
    z1 = A_Z + A_VUELO
    yb, y1 = A_PB, A_PB + A_P1
    # zócalo de sillería y planta baja de revoque
    caja_mm(M, (A_X0, 0.0, zf - A_FONDO), (A_X1, 0.62, zf + 0.05), "sillar", jit(SILLAR, 0.03), jit_v=0.0)
    caja_mm(M, (A_X0 + 0.02, 0.62, zf - A_FONDO), (A_X1 - 0.02, yb, zf), "revoque", REVOQUE_A)
    # esquinas de sillar (piedras alternas)
    for xe, sig in ((A_X0, 1), (A_X1, -1)):
        y = 0.62
        k = 0
        while y < yb - 0.1:
            h = RND.uniform(0.32, 0.4)
            w = 0.42 if k % 2 == 0 else 0.28
            caja_mm(M, (xe if sig > 0 else xe - w, y, zf - (0.28 if k % 2 else 0.42)),
                    (xe + w if sig > 0 else xe, y + h - 0.02, zf + 0.04), "sillar", jit(SILLAR, 0.06), jit_v=0.01)
            y += h
            k += 1
    choque(((A_X0 + A_X1) / 2, 1.5, zf - A_FONDO / 2), (A_X1 - A_X0, 3.0, A_FONDO + 0.12))
    if BLOCKOUT:
        caja_mm(M, (A_X0, yb, z1 - A_FONDO - A_VUELO), (A_X1, y1, z1), "revoque", REVOQUE_A)
        faldon(M, (A_X0 - 0.4, y1, z1 + 0.6), (A_X1 + 0.4, y1, z1 + 0.6), (0, 2.9, -3.6), [TEJA[0]], musgo=0)
        return
    # vigas del vuelo: cabezas de las viguetas bajo el piso y ménsulas
    viga(M, (A_X0, yb - 0.08, z1 - 0.1), (A_X1, yb - 0.08, z1 - 0.1), 0.2, "madera", MADERA_OSC, alto=0.18, jit_v=0.01)
    x = A_X0 + 0.25
    while x < A_X1 - 0.1:
        caja(M, (x, yb - 0.24, zf + A_VUELO * 0.5 - 0.05), (0.13, 0.15, A_VUELO + 0.1), "madera", jit(MADERA_OSC, 0.05),
             veta="larga", jit_v=0.008)
        x += 0.48
    for xm in (A_X0 + 0.3, -8.75, PUERTA_X - 1.15, PUERTA_X + 1.15, -4.75, -2.45):
        viga(M, (xm, yb - 0.95, zf + 0.04), (xm, yb - 0.3, zf + 0.42), 0.13, "madera", MADERA_OSC, alto=0.13)
        caja(M, (xm, yb - 1.02, zf + 0.06), (0.16, 0.16, 0.1), "madera", MADERA_OSC)
    # el piso: entramado al sur (jabalcones en los vanos sin ventana) y revoque a los lados
    entramado(M, A_X0, A_X1, yb, y1, z1, [-11.2, -10.0, -8.7, -7.4, -5.9, -4.6, -3.2], REVOQUE_A, MADERA_OSC,
              cruces=(0, 3, 5, 7))
    caja_mm(M, (A_X0, yb, z1 - A_FONDO - A_VUELO), (A_X0 + 0.12, y1, z1 - 0.12), "revoque", REVOQUE_A)
    caja_mm(M, (A_X1 - 0.12, yb, z1 - A_FONDO - A_VUELO), (A_X1, y1, z1 - 0.12), "revoque", REVOQUE_A)
    # muro este (al callejón): entramado sencillo
    entramado(M, z1 - A_FONDO - A_VUELO + 0.2, z1 - 0.1, yb, y1, A_X1, [-6.0, -4.6], REVOQUE_A, MADERA_OSC, eje="x")
    # ventanas
    flores = []
    flores.append(ventana(M, -10.0, 1.05, zf, 0.9, 1.15, AZUL_POSTIGO, jardinera=True))
    flores.append(ventana(M, -3.6, 1.05, zf, 0.9, 1.15, AZUL_POSTIGO, jardinera=True))
    for xv, luz in ((-10.6, False), (-8.05, True), (-5.25, False), (-2.5, False)):
        flores.append(ventana(M, xv, yb + 0.75, z1 + 0.04, 0.72, 0.95, AZUL_POSTIGO, luz=luz, jardinera=not luz))
    ventana(M, -4.0, yb + 0.7, A_X1, 0.6, 0.85, AZUL_POSTIGO, eje="x", sig=1.0)     # al callejón (z = −4)
    # el tejado: aleros hondos, cumbrera paralela a la calle
    yr = y1 + 2.65
    zr = z1 - 3.0
    faldon(M, (A_X0 - 0.45, y1 - 0.05, z1 + 0.62), (A_X1 + 0.45, y1 - 0.05, z1 + 0.62), (0, yr - y1 + 0.05, zr - z1 - 0.62),
           TEJA, musgo=0.3)
    faldon(M, (A_X1 + 0.45, y1 - 0.05, zr - 3.6), (A_X0 - 0.45, y1 - 0.05, zr - 3.6), (0, yr - y1 + 0.05, 3.6),
           TEJA, musgo=0.1)
    cumbrera(M, (A_X0 - 0.45, yr + 0.02, zr), (A_X1 + 0.45, yr + 0.02, zr))
    # hastiales (triángulos de revoque) y tablas de borde
    for xh, s in ((A_X0, -1), (A_X1, 1)):
        pts = [Vector((xh, y1, z1 - 0.1)), Vector((xh, yr - 0.05, zr)), Vector((xh, y1, zr - 3.5))]
        M.cara(list(reversed(pts)) if s > 0 else pts, "revoque", REVOQUE_A)
        viga(M, (xh + s * 0.48, y1 - 0.08, z1 + 0.62), (xh + s * 0.48, yr + 0.06, zr), 0.06, "madera", MADERA_OSC, alto=0.22)
    # buhardilla con su tejadillo (cumbrera norte-sur)
    bx, bz = -8.6, z1 - 1.35
    by = y1 + 0.9
    caja_mm(M, (bx - 0.75, y1 + 0.2, bz - 1.2), (bx + 0.75, by + 0.95, bz), "revoque", REVOQUE_A)
    M.cara([Vector((bx - 0.75, by + 0.95, bz)), Vector((bx + 0.75, by + 0.95, bz)), Vector((bx, by + 1.5, bz))],
           "revoque", REVOQUE_A)
    ventana(M, bx, by, bz, 0.55, 0.65, None, luz=False)
    faldon(M, (bx - 0.95, by + 0.9, bz + 0.3), (bx - 0.95, by + 0.9, bz - 1.4), (0.95, 0.62, 0), TEJA, musgo=0.2, solape=0.3)
    faldon(M, (bx + 0.95, by + 0.9, bz - 1.4), (bx + 0.95, by + 0.9, bz + 0.3), (-0.95, 0.62, 0), TEJA, musgo=0.2, solape=0.3)
    # chimenea en el faldón delantero
    chimenea(M, -11.0, z1 - 1.6, y1 + 0.6, yr + 0.15)
    # LA PUERTA: arco de dovelas, puerta verde de tablas con herrajes, escalones gastados y tejadillo
    puerta(M, V, PUERTA_X, zf)
    # letrero colgado (la botica de hierbas): brazo de hierro, cadenas y tabla con un mortero en relieve
    letrero(M, (-4.45, yb - 0.42, zf), (0, 0, 1))
    return flores


def puerta(M, V, px, zf):
    ancho, alto_r, radio = 1.2, 1.35, 0.6
    y_suelo = 0.48                                 # tres escalones
    # escalones (de abajo arriba, cada uno algo más estrecho y gastado)
    for k in range(3):
        y = k * 0.16
        prof = 0.95 - k * 0.3
        w = 2.3 - k * 0.35
        caja_mm(M, (px - w / 2 + RND.uniform(-0.03, 0.03), y, zf + 0.06), (px + w / 2, y + 0.16, zf + 0.06 + prof),
                "sillar", jit(SILLAR, 0.05), jit_v=0.012)
        choque((px, y + 0.08, zf + 0.06 + prof / 2), (w, 0.16, prof))
    ancla_p("puerta", (px, y_suelo, zf + 1.1))
    # el arco: jambas y dovelas
    for lado in (-1, 1):
        y = y_suelo
        k = 0
        while y < y_suelo + alto_r - 0.05:
            h = 0.36
            w = 0.34 if k % 2 == 0 else 0.26
            xx = px + lado * (ancho / 2 + w / 2)
            caja(M, (xx, y + h / 2, zf + 0.06), (w, h - 0.02, 0.22), "sillar", jit(SILLAR, 0.05), jit_v=0.008)
            y += h
            k += 1
    cy = y_suelo + alto_r
    n = 9
    for k in range(n):
        a0 = math.pi * k / n
        a1 = math.pi * (k + 1) / n
        r0, r1 = radio, radio + (0.36 if k % 2 == 0 else 0.3)
        pts = [(math.cos(a0) * r0, math.sin(a0) * r0), (math.cos(a0) * r1, math.sin(a0) * r1),
               (math.cos(a1) * r1, math.sin(a1) * r1), (math.cos(a1) * r0, math.sin(a1) * r0)]
        sep = 0.012
        pts = [(x * (1 - sep), y * (1 - sep)) for x, y in pts]
        placa(M, pts, (px, cy, zf - 0.05), (1, 0, 0), (0, 1, 0), 0.23 + (0.02 if k == n // 2 else 0),
              "sillar", jit(SILLAR, 0.05))
    # la hoja: tablas verdes con el borde de arriba siguiendo el arco
    tablas = 6
    for k in range(tablas):
        xa = -ancho / 2 + k * ancho / tablas
        xb = xa + ancho / tablas - 0.012
        def ya(x):
            return alto_r + math.sqrt(max(0.0, radio * radio - x * x)) - 0.02
        pts = [(xa, 0), (xb, 0), (xb, ya(xb)), (xa, ya(xa))]
        placa(M, pts, (px, y_suelo, zf - 0.02), (1, 0, 0), (0, 1, 0), 0.06, "madera", jit(VERDE_PUERTA, 0.04))
    for yy in (0.35, 1.25):                       # pernios de hierro
        caja(M, (px - 0.25, y_suelo + yy, zf + 0.05), (0.62, 0.06, 0.015), "hierro", HIERRO)
    for dx in (-0.4, -0.2, 0.0, 0.2, 0.4):        # clavos
        for yy in (0.35, 1.25):
            caja(M, (px + dx, y_suelo + yy, zf + 0.062), (0.03, 0.03, 0.02), "hierro", HIERRO)
    cilindro(M, (px + 0.28, y_suelo + 0.95, zf + 0.05), [(0, 0.075), (0.02, 0.075), (0.02, 0.055), (0, 0.055)], 10,
             "hierro", LATON, rot=R(0, 90), tapa_arriba=False)        # aldaba de anilla
    # el farol de la puerta y el banco
    farol_pared(M, (px + 1.15, y_suelo + 2.0, zf + 0.04), (0.55, 0, 0.84))
    if DECORADO:
        caja_mm(M, (px + 1.55, 0.0, zf + 0.15), (px + 1.62, 0.42, zf + 0.5), "madera", MADERA)
        caja_mm(M, (px + 2.95, 0.0, zf + 0.15), (px + 3.02, 0.42, zf + 0.5), "madera", MADERA)
        caja_mm(M, (px + 1.45, 0.42, zf + 0.1), (px + 3.12, 0.5, zf + 0.55), "madera", jit(MADERA_GRIS, 0.04), veta="larga")
        choque((px + 2.3, 0.25, zf + 0.33), (1.7, 0.5, 0.5))


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


# ------------------------------------------------------------- la casa de la esquina (B): hastial a la calle

B_X0, B_X1 = 1.8, 8.8
B_Z = -2.4
B_FONDO = 6.6
B_PB = 2.8
B_P1 = 2.35


def casa_b(M, V):
    zf = B_Z
    z1 = zf + 0.5                   # primer vuelo
    yb, y1 = B_PB, B_PB + B_P1
    choque(((B_X0 + B_X1) / 2, 1.5, zf - B_FONDO / 2), (B_X1 - B_X0, 3.0, B_FONDO + 0.12))
    # planta baja de sillería
    caja_mm(M, (B_X0, 0.0, zf - B_FONDO), (B_X1, yb, zf), "sillar", jit(SILLAR, 0.02), jit_v=0.0)
    if BLOCKOUT:
        caja_mm(M, (B_X0, yb, z1 - B_FONDO), (B_X1, y1, z1), "revoque", REVOQUE_B)
        yr = y1 + 3.2
        faldon(M, (B_X0 - 0.3, y1, z1 + 0.5), (B_X0 - 0.3, y1, z1 - B_FONDO), ((B_X1 - B_X0) / 2 + 0.3, 3.2, 0), [TEJA[1]], musgo=0)
        faldon(M, (B_X1 + 0.3, y1, z1 - B_FONDO), (B_X1 + 0.3, y1, z1 + 0.5), (-(B_X1 - B_X0) / 2 - 0.3, 3.2, 0), [TEJA[1]], musgo=0)
        pts = [Vector((B_X0, y1, z1)), Vector((B_X1, y1, z1)), Vector(((B_X0 + B_X1) / 2, yr, z1))]
        M.cara(pts, "revoque", REVOQUE_B)
        cilindro(M, (B_X1 + 0.35, yb, zf + 0.35), [(0, 0.95), (3.2, 0.95)], 10, "revoque", REVOQUE_B, suave=False)
        cono(M, (B_X1 + 0.35, yb + 3.2, zf + 0.35), 1.15, 2.6, 10, "tejas", PIZARRA[0])
        return
    # el gran arco rebajado del taller (dovelas), con su oscuridad dentro
    ax, R_A = 4.4, 1.5
    a_ini = math.acos(1.2 / R_A)                      # el arco arranca a 1,2 m del centro, a la altura y_s
    y_s = 1.6
    yc = y_s - R_A * math.sin(a_ini)
    hueco = [(-1.2, 0.0), (1.2, 0.0)]
    for k in range(9):
        a = a_ini + (math.pi - 2 * a_ini) * k / 8
        hueco.append((math.cos(a) * R_A, yc + math.sin(a) * R_A))
    placa(M, hueco, (ax, 0.0, zf), (1, 0, 0), (0, 1, 0), 0.006, "hierro", (0.08, 0.07, 0.07), lados=False)
    n = 9
    for k in range(n):
        a0 = a_ini + (math.pi - 2 * a_ini) * k / n
        a1 = a_ini + (math.pi - 2 * a_ini) * (k + 1) / n
        r0, r1 = R_A, R_A + (0.34 if k % 2 == 0 else 0.27)
        pts = [(math.cos(a0) * r0, math.sin(a0) * r0), (math.cos(a0) * r1, math.sin(a0) * r1),
               (math.cos(a1) * r1, math.sin(a1) * r1), (math.cos(a1) * r0, math.sin(a1) * r0)]
        pts = [(x * 0.995, y * 0.995) for x, y in pts]
        placa(M, pts, (ax, yc, zf), (1, 0, 0), (0, 1, 0), 0.1 if k != n // 2 else 0.14, "sillar", jit(SILLAR, 0.06))
    for s in (-1, 1):                                  # jambas del arco
        caja_mm(M, (ax + s * 1.2 - (0.3 if s > 0 else 0.0), 0.0, zf), (ax + s * 1.2 + (0.3 if s < 0 else 0.0), y_s, zf + 0.08),
                "sillar", jit(SILLAR, 0.05), jit_v=0.008)
    # piso primero (vuelo 0,5) y segundo (vuelo 0,35 más), entramado
    viga(M, (B_X0, yb - 0.06, z1 - 0.1), (B_X1, yb - 0.06, z1 - 0.1), 0.2, "madera", MADERA_OSC, alto=0.18, jit_v=0.01)
    x = B_X0 + 0.25
    while x < B_X1 - 0.1:
        caja(M, (x, yb - 0.2, zf + 0.22), (0.13, 0.15, 0.6), "madera", jit(MADERA_OSC, 0.05), veta="larga", jit_v=0.008)
        x += 0.46
    for xm in (B_X0 + 0.3, B_X1 - 0.3, 2.6, 6.3):
        viga(M, (xm, yb - 0.9, zf + 0.04), (xm, yb - 0.28, zf + 0.4), 0.13, "madera", MADERA_OSC, alto=0.13)
    entramado(M, B_X0, B_X1, yb, y1, z1, [3.45, 5.85, 6.95, 7.9], REVOQUE_B, MADERA_OSC, cruces=(3, 4))
    caja_mm(M, (B_X0, yb, z1 - B_FONDO), (B_X0 + 0.12, y1, z1 - 0.12), "revoque", REVOQUE_B)
    caja_mm(M, (B_X1 - 0.12, yb, z1 - B_FONDO), (B_X1, y1, z1 - 0.12), "revoque", REVOQUE_B)
    flores = []
    flores.append(ventana(M, 2.7, yb + 0.7, z1 + 0.04, 0.6, 0.9, ROJO_POSTIGO, jardinera=True))
    flores.append(ventana(M, 6.4, yb + 0.7, z1 + 0.04, 0.6, 0.9, ROJO_POSTIGO, luz=True))
    ventana(M, -3.7, yb + 0.75, B_X0, 0.55, 0.8, ROJO_POSTIGO, eje="x", sig=-1.0)     # al callejón
    # balconcillo de madera en el primer piso
    bx = 4.65
    caja_mm(M, (bx - 0.9, yb + 0.02, z1), (bx + 0.9, yb + 0.1, z1 + 0.6), "madera", MADERA)
    for k in range(10):
        xx = bx - 0.85 + k * 0.19
        caja_mm(M, (xx - 0.025, yb + 0.1, z1 + 0.54), (xx + 0.025, yb + 0.9, z1 + 0.59), "madera", MADERA_OSC)
    caja_mm(M, (bx - 0.92, yb + 0.88, z1 - 0.02), (bx + 0.92, yb + 0.96, z1 + 0.62), "madera", MADERA)
    for xx in (bx - 0.88, bx + 0.88):
        caja_mm(M, (xx - 0.04, yb + 0.1, z1 + 0.0), (xx + 0.04, yb + 0.9, z1 + 0.6), "madera", MADERA_OSC)
    ventana(M, bx, yb + 0.15, z1 + 0.04, 0.85, 1.55, None, luz=False)     # puerta-ventana del balcón
    ancla_p("balcon", (bx, yb + 0.1, z1 + 0.3))
    # segundo vuelo y el hastial
    z2 = z1 + 0.35
    y2 = y1 + 1.0
    viga(M, (B_X0 - 0.05, y1 - 0.06, z2 - 0.1), (B_X1 + 0.05, y1 - 0.06, z2 - 0.1), 0.2, "madera", MADERA_OSC, alto=0.18)
    entramado(M, B_X0, B_X1, y1, y2, z2, [3.4, 5.3, 7.2], REVOQUE_B, MADERA_OSC)
    caja_mm(M, (B_X0, y1, z2 - B_FONDO), (B_X0 + 0.12, y2, z2 - 0.12), "revoque", REVOQUE_B)
    caja_mm(M, (B_X1 - 0.12, y1, z2 - B_FONDO), (B_X1, y2, z2 - 0.12), "revoque", REVOQUE_B)
    yr = y2 + 2.55
    xm = (B_X0 + B_X1) / 2
    pts = [Vector((B_X0, y2, z2 - 0.06)), Vector((B_X1, y2, z2 - 0.06)), Vector((xm, yr, z2 - 0.06))]
    M.cara(pts, "revoque", REVOQUE_B)
    viga(M, (B_X0 + 0.2, y2 + 0.05, z2), (xm, yr - 0.3, z2), 0.12, "madera", MADERA_OSC, alto=0.14)
    viga(M, (B_X1 - 0.2, y2 + 0.05, z2), (xm, yr - 0.3, z2), 0.12, "madera", MADERA_OSC, alto=0.14)
    viga(M, (B_X0 + 0.9, y2 + 0.85, z2 + 0.02), (B_X1 - 0.9, y2 + 0.85, z2 + 0.02), 0.11, "madera", MADERA_OSC, alto=0.12)
    ventana(M, xm, y2 + 0.95, z2, 0.5, 0.65, ROJO_POSTIGO)
    # aleros del hastial (tablas de borde) y faldones hacia este y oeste
    vuelo = 0.55
    for s in (-1, 1):
        xa = B_X0 - vuelo if s < 0 else B_X1 + vuelo
        faldon(M, (xa, y2 - 0.35, z2 + vuelo) if s < 0 else (xa, y2 - 0.35, z2 - B_FONDO - 0.6),
               (xa, y2 - 0.35, z2 - B_FONDO - 0.6) if s < 0 else (xa, y2 - 0.35, z2 + vuelo),
               (xm - xa, yr - y2 + 0.4, 0), TEJA, musgo=0.25)
        viga(M, (xa + 0.02 * -s, y2 - 0.4, z2 + vuelo + 0.02), (xm, yr + 0.08, z2 + vuelo + 0.02), 0.06, "madera",
             MADERA_OSC, alto=0.26)
    cumbrera(M, (xm, yr + 0.02, z2 + vuelo), (xm, yr + 0.02, z2 - B_FONDO - 0.6))
    # la viga de la polea que asoma bajo la cumbrera, con su cuerda
    viga(M, (xm, yr - 0.55, z2 - 0.4), (xm, yr - 0.55, z2 + 1.2), 0.17, "madera", MADERA_OSC, alto=0.19)
    cilindro(M, (xm - 0.04, yr - 0.72, z2 + 1.05), [(0, 0.12), (0.08, 0.12)], 10, "madera", MADERA, rot=R(0, 0, 90))
    viga(M, (xm + 0.07, yr - 0.72, z2 + 1.05), (xm + 0.07, yb + 0.6, z2 + 1.05), 0.022, "tela", (0.70, 0.62, 0.48))
    chimenea(M, 3.0, z1 - 3.6, y2 + 1.0, yr + 0.2, 0.6, 0.5)
    # LA ESQUINA: torreón en voladizo sobre ménsulas, con tejado cónico de pizarra, veleta, guardacantón y hornacina
    torreon(M, V)
    return flores


def torreon(M, V):
    cx, cz = B_X1 + 0.12, B_Z + 0.62                  # sobre la esquina, asomando a la calle
    y0, y1 = B_PB + 0.15, B_PB + B_P1 + 0.9
    r = 0.95
    n = 12
    # ménsula: cono invertido de madera, con dos jabalcones que salen de las paredes
    cilindro(M, (cx, y0 - 0.85, cz), [(0, 0.22), (0.45, 0.55), (0.85, r + 0.06)], n, "madera", MADERA_OSC, suave=False)
    viga(M, (B_X1 - 0.45, y0 - 1.75, B_Z + 0.07), (cx - 0.55, y0 - 0.12, cz - 0.1), 0.12, "madera", MADERA_OSC)
    viga(M, (B_X1 + 0.07, y0 - 1.75, B_Z - 0.45), (cx + 0.1, y0 - 0.12, cz - 0.55), 0.12, "madera", MADERA_OSC)
    caja(M, (B_X1 - 0.45, y0 - 1.8, B_Z + 0.05), (0.18, 0.14, 0.1), "sillar", SILLAR)
    # el cuerpo: revoque con bandas de madera y dos ventanitas
    cilindro(M, (cx, y0, cz), [(0, r), (y1 - y0, r)], n, "revoque", REVOQUE_C, suave=True, tapa_arriba=False)
    for yy in (0.0, (y1 - y0) * 0.5, y1 - y0 - 0.12):
        cilindro(M, (cx, y0 + yy, cz), [(0, r + 0.03), (0.13, r + 0.03)], n, "madera", MADERA_OSC, suave=True,
                 tapa_arriba=False)
    for k, (ang, luz) in enumerate(((math.radians(70), True), (math.radians(150), False), (math.radians(10), False))):
        d = Vector((math.cos(ang), 0, math.sin(ang)))
        c = Vector((cx, y0 + 0.75, cz)) + d * (r + 0.02)
        rot = Matrix((d.cross(Vector((0, 1, 0))) * -1, Vector((0, 1, 0)), d)).transposed()
        caja(M, c, (0.32, 0.48, 0.04), "brillo" if luz else "hierro", LUZ_VENTANA if luz else CRISTAL, rot=rot)
        caja(M, c + d * 0.03 + Vector((0, 0.36, 0)), (0.56, 0.08, 0.08), "madera", MADERA_OSC, rot=rot)
        caja(M, c + d * 0.04 + Vector((0, -0.34, 0)), (0.56, 0.07, 0.12), "madera", MADERA_OSC, rot=rot)
    # el tejado cónico de pizarra en hiladas, con alero
    yt = y1
    hcono = 2.3
    hil = 9
    for k in range(hil):
        f0, f1 = k / hil, (k + 1) / hil
        r0 = (r + 0.32) * (1 - f0) + 0.02
        r1 = (r + 0.32) * (1 - f1) + 0.02
        col = jit(elige(PIZARRA), 0.06)
        cilindro(M, (cx, yt + f0 * hcono - 0.06, cz), [(0, r0 + 0.05), (0.07, r0 + 0.04), (hcono / hil + 0.06, r1)],
                 n + 2, "tejas", col, suave=False, tapa_arriba=(k == hil - 1), fase=k * 0.2)
    cilindro(M, (cx, yt + hcono, cz), [(0, 0.04), (0.5, 0.025)], 6, "hierro", HIERRO)
    caja(M, (cx + 0.12, yt + hcono + 0.42, cz), (0.32, 0.16, 0.015), "hierro", HIERRO, rot=R(25))   # veleta (un gallo plano)
    caja(M, (cx - 0.1, yt + hcono + 0.4, cz), (0.14, 0.05, 0.05), "hierro", HIERRO, rot=R(25))
    # guardacantón y hornacina con velas en la esquina, a ras de calle
    cilindro(M, (B_X1 + 0.05, 0.0, B_Z + 0.08), [(0, 0.28), (0.55, 0.24), (0.7, 0.12)], 8, "sillar", jit(SILLAR, 0.05),
             suave=True)
    choque((B_X1 + 0.05, 0.35, B_Z + 0.08), (0.56, 0.7, 0.56))
    hx, hz = B_X1 - 0.75, B_Z                           # hornacina en la fachada, junto a la esquina
    caja_mm(M, (hx - 0.32, 0.98, hz), (hx + 0.32, 1.72, hz + 0.01), "hierro", (0.12, 0.10, 0.10))
    caja_mm(M, (hx - 0.42, 0.9, hz), (hx + 0.42, 0.99, hz + 0.24), "sillar", SILLAR)
    placa(M, [(-0.42, 0), (0.42, 0), (0.42, 0.78), (0.0, 1.0), (-0.42, 0.78)], (hx, 0.9, hz), (1, 0, 0), (0, 1, 0), 0.12,
          "sillar", jit(SILLAR, 0.04), frente=False)
    placa(M, [(-0.32, 0.08), (0.32, 0.08), (0.32, 0.8), (0.0, 0.92), (-0.32, 0.8)], (hx, 0.9, hz), (1, 0, 0), (0, 1, 0), 0.004,
          "hierro", (0.10, 0.09, 0.09), lados=False)
    for k, dx in enumerate((-0.17, 0.02, 0.18)):
        h = (0.18, 0.26, 0.14)[k]
        cilindro(M, (hx + dx, 0.99, hz + 0.12), [(0, 0.025), (h, 0.025)], 6, "tela", (0.96, 0.92, 0.80))
        caja(M, (hx + dx, 0.99 + h + 0.03, hz + 0.12), (0.025, 0.05, 0.025), "brillo", LUZ_FAROL)
    caja(M, (hx, 1.36, hz + 0.06), (0.1, 0.26, 0.08), "sillar", (0.92, 0.90, 0.84))      # una figurilla de piedra
    ancla_p("hornacina", (hx, 1.3, hz + 0.18))
    ancla_p("esquina", (B_X1 + 0.4, 0.0, B_Z + 0.6))
    # farol en la esquina, en diagonal
    farol_pared(M, (B_X1 + 0.02, 2.35, B_Z + 0.02), (0.7, 0, 0.7))


# ------------------------------------------------------------- el callejón, los extremos y el fondo

def callejon(M, V):
    # escalones de piedra entre las dos casas
    for k in range(5):
        y = k * 0.17
        z = -3.4 - k * 0.4
        caja_mm(M, (-1.75 + RND.uniform(0, 0.05), y, z - 0.4 - 0.05), (1.75 - RND.uniform(0, 0.05), y + 0.17, z),
                "sillar", jit(SILLAR, 0.06), jit_v=0.012)
        choque((0.0, y + 0.085, z - 0.2), (3.5, 0.17, 0.4))
    choque((0.0, 0.85 / 2, -7.35), (3.5, 0.85, 3.9))
    # el fondo: un muro con un arco abierto y luz al otro lado
    zb = -9.3
    caja_mm(M, (-2.2, 0.0, zb - 0.5), (-0.85, 4.4, zb), "sillar", jit(SILLAR, 0.04))
    caja_mm(M, (0.85, 0.0, zb - 0.5), (2.2, 4.4, zb), "sillar", jit(SILLAR, 0.04))
    caja_mm(M, (-0.85, 3.0, zb - 0.5), (0.85, 4.4, zb), "sillar", jit(SILLAR, 0.04))
    for k in range(7):
        a0 = math.pi * k / 7
        a1 = math.pi * (k + 1) / 7
        pts = [(math.cos(a0) * 0.85, math.sin(a0) * 0.85), (math.cos(a0) * 1.15, math.sin(a0) * 1.15),
               (math.cos(a1) * 1.15, math.sin(a1) * 1.15), (math.cos(a1) * 0.85, math.sin(a1) * 0.85)]
        placa(M, pts, (0, 2.15, zb), (1, 0, 0), (0, 1, 0), 0.08, "sillar", jit(SILLAR, 0.06))
    choque((0, 2.2, zb - 0.25), (4.4, 4.4, 0.5))
    # al otro lado del arco: un patio soleado (fachada lejana) — el fondo que se ve por el callejón
    caja_mm(M, (-4.0, 0.85, -14.0), (4.0, 6.5, -13.6), "revoque", (0.94, 0.84, 0.66))
    ventana(M, 0.6, 2.3, -13.6, 0.7, 0.9, AZUL_POSTIGO)
    caja_mm(M, (-4.0, 0.0, -14.0), (4.0, 0.86, -9.4), "tierra", (0.70, 0.62, 0.50), caras="a")
    if DECORADO:
        # la cuerda de la ropa de lado a lado del callejón (de la ventana de A a la de B)
        a = Vector((A_X1 + 0.05, 4.4, -4.0))
        b = Vector((B_X0 - 0.05, 4.5, -3.7))
        pts = []
        for k in range(13):
            t = k / 12
            p = a.lerp(b, t) - Vector((0, 0.32 * math.sin(math.pi * t), 0))
            pts.append(p)
        for k in range(12):
            viga(M, pts[k], pts[k + 1], 0.018, "tela", (0.82, 0.76, 0.62))
        for k, t in enumerate((0.16, 0.3, 0.46, 0.62, 0.8)):
            p = a.lerp(b, t) - Vector((0, 0.32 * math.sin(math.pi * t), 0))
            ancho = RND.uniform(0.35, 0.6)
            largo = RND.uniform(0.5, 0.85)
            col = TELAS[k % len(TELAS)]
            d = (b - a).normalized()
            n = d.cross(Vector((0, 1, 0))).normalized()
            pp = []
            for j in range(4):
                for q in range(3):
                    u = (q / 2 - 0.5) * ancho
                    v = -j / 3 * largo
                    onda = 0.04 * math.sin(q * 2.1 + j * 1.3 + k)
                    pp.append(p + d * u + Vector((0, v, 0)) + n * onda)
            for j in range(3):
                for q in range(2):
                    c = [pp[j * 3 + q], pp[j * 3 + q + 1], pp[(j + 1) * 3 + q + 1], pp[(j + 1) * 3 + q]]
                    M.cara(c, "tela", jit(col, 0.03), suave=True)
                    M.cara(list(reversed(c)), "tela", jit(col, 0.03), suave=True)
            caja(M, p + Vector((0, 0.02, 0)), (0.04, 0.06, 0.03), "madera", MADERA)          # pinza


def extremos(M, V):
    # oeste: muro de huerto con portillo de madera y, detrás, el árbol
    x0 = A_X0 - 0.3
    caja_mm(M, (-20.0, 0.0, -3.0), (x0 - 1.6, 1.45, -2.55), "sillar", jit(SILLAR, 0.05), jit_v=0.01)
    caja_mm(M, (-20.0, 1.45, -3.08), (x0 - 1.6, 1.58, -2.48), "sillar", jit(SILLAR, 0.05))
    choque(((-20.0 + x0 - 1.6) / 2, 0.8, -2.78), (x0 - 1.6 + 20.0, 1.6, 0.5))
    for xx in (x0 - 1.6, x0):
        caja_mm(M, (xx - 0.18, 0.0, -3.05), (xx + 0.18, 1.85, -2.5), "sillar", jit(SILLAR, 0.05))
    for k in range(6):
        xx = x0 - 1.45 + k * 0.24
        caja_mm(M, (xx, 0.08, -2.8), (xx + 0.2, 1.35 + 0.08 * math.sin(k), -2.74), "madera", jit(MADERA_GRIS, 0.05),
                veta="larga")
    for yy in (0.35, 1.05):
        caja_mm(M, (x0 - 1.45, yy, -2.74), (x0 - 0.05, yy + 0.1, -2.7), "madera", MADERA_GRIS, veta="larga")
    choque((x0 - 0.8, 0.8, -2.78), (1.6, 1.6, 0.5))
    # este: la calleja que sube al norte (tierra) y un cobertizo con su leña
    sx0 = 12.2
    caja_mm(M, (sx0, 0.0, -6.5), (sx0 + 5.5, 2.3, -2.9), "madera", jit(MADERA_GRIS, 0.03), veta="larga")
    for k in range(int(5.5 / 0.3)):
        xx = sx0 + 0.15 + k * 0.3
        caja_mm(M, (xx - 0.01, 0.0, -2.92), (xx + 0.01, 2.3, -2.88), "hierro", (0.28, 0.24, 0.20))
    faldon(M, (sx0 - 0.4, 2.15, -2.3), (sx0 + 5.9, 2.15, -2.3), (0, 0.9, -4.6), TEJA, musgo=0.5)
    choque((sx0 + 2.75, 1.2, -4.7), (5.5, 2.4, 3.6))
    # al fondo de la calleja, otra fachada al sol (más lejos, más sencilla)
    caja_mm(M, (9.2, 0.0, -14.5), (16.0, 5.8, -13.8), "revoque", REVOQUE_C)
    ventana(M, 11.2, 1.2, -13.8, 0.7, 1.0, AZUL_POSTIGO)
    ventana(M, 13.8, 3.4, -13.8, 0.7, 1.0, AZUL_POSTIGO, luz=True)
    faldon(M, (8.8, 5.75, -13.3), (16.4, 5.75, -13.3), (0, 2.0, -2.5), TEJA, musgo=0.2)


# ---------------------------------------------------------------- objetos cotidianos

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


def montones(M, V):
    """El atrezo: barriles, cajones, macetas, carretilla, faroles de pie, cesto, escoba, leña…"""
    # junto a la casa A, a poniente: barriles y cajones (uno tumbado)
    barril(M, (-11.65, 0.0, -1.95))
    barril(M, (-10.95, 0.0, -1.75))
    barril(M, (-11.25, 0.32, -0.95), tumbado=True, yaw=20)
    cajon(M, (-9.5, 0.0, -1.85), (0.7, 0.55, 0.55), yaw=8)
    cajon(M, (-9.42, 0.55, -1.86), (0.55, 0.42, 0.45), yaw=-6)
    # cesto de manzanas sobre el cajón
    cilindro(M, (-9.4, 0.97, -1.86), [(0, 0.16), (0.16, 0.2), (0.17, 0.2)], 10, "madera", (0.80, 0.66, 0.44))
    for k in range(7):
        a = k * 0.9
        caja(M, (-9.4 + math.cos(a) * 0.09, 1.14 + (k % 3) * 0.03, -1.86 + math.sin(a) * 0.09), (0.07, 0.07, 0.07),
             "barro", RND.choice([(0.86, 0.22, 0.18), (0.92, 0.70, 0.28)]), rot=R(k * 30))
    # macetas a los lados de la puerta y en los escalones
    for (x, z, r) in ((PUERTA_X - 1.35, -2.0, 0.26), (PUERTA_X + 1.3, -2.0, 0.22), (PUERTA_X - 0.85, -1.6, 0.17)):
        maceta(M, V, (x, 0.0, z), r, r * 1.3)
        choque((x, 0.2, z), (r * 2, 0.4, r * 2))
    maceta(M, V, (-1.3, 0.17, -3.7), 0.16, 0.22)
    maceta(M, V, (1.25, 0.34, -4.15), 0.18, 0.24)
    maceta(M, V, (-1.35, 0.51, -4.6), 0.14, 0.2)
    # escoba apoyada junto a la puerta y un cubo
    viga(M, (PUERTA_X + 0.95, 0.02, -2.25), (PUERTA_X + 1.05, 1.35, -2.52), 0.035, "madera", MADERA_GRIS)
    cono(M, (PUERTA_X + 0.94, 0.0, -2.24), 0.12, 0.38, 6, "tela", (0.80, 0.68, 0.42), rot=R(0, -10))
    cilindro(M, (PUERTA_X + 3.4, 0.0, -2.15), [(0, 0.15), (0.3, 0.18)], 10, "madera", jit(MADERA_GRIS, 0.05), tapa_arriba=False)
    # casa B: barriles a la boca del taller y cajones apilados junto a la esquina
    barril(M, (3.6, 0.0, -2.0), 0.3, 0.8)
    barril(M, (5.25, 0.0, -1.95), 0.34, 0.9)
    cajon(M, (7.8, 0.0, -1.85), (0.7, 0.55, 0.6), yaw=-4)
    cajon(M, (8.05, 0.0, -1.2), (0.55, 0.45, 0.5), yaw=12)
    cajon(M, (7.85, 0.55, -1.86), (0.5, 0.45, 0.48), yaw=20)
    # primer plano, abajo a la izquierda: farol de pie con su poste, barriles y cajones (enmarcan)
    fx, fz = -7.7, 3.3
    caja_mm(M, (fx - 0.17, 0.0, fz - 0.17), (fx + 0.17, 0.35, fz + 0.17), "sillar", SILLAR)
    viga(M, (fx, 0.3, fz), (fx, 3.3, fz), 0.13, "madera", MADERA_OSC)
    viga(M, (fx, 3.2, fz), (fx + 0.62, 3.2, fz), 0.09, "madera", MADERA_OSC)
    viga(M, (fx, 2.7, fz), (fx + 0.42, 3.2, fz), 0.07, "madera", MADERA_OSC)
    viga(M, (fx + 0.55, 3.2, fz), (fx + 0.55, 3.0, fz), 0.015, "hierro", HIERRO)
    farol(M, (fx + 0.55, 2.64, fz))
    choque((fx, 1.5, fz), (0.4, 3.0, 0.4))
    barril(M, (fx - 0.85, 0.0, fz + 0.2), 0.36, 0.95)
    barril(M, (fx - 1.55, 0.0, fz + 0.05), 0.33, 0.88)
    cajon(M, (fx - 1.25, 0.0, fz - 0.55), (0.8, 0.6, 0.7), yaw=-10)
    cajon(M, (fx - 1.2, 0.6, fz - 0.55), (0.6, 0.45, 0.5), yaw=6)
    # abajo a la derecha: la carretilla con sacos y un murete con flores
    carretilla(M, V, (6.5, 0.0, 3.35), -150)
    caja_mm(M, (7.7, 0.0, 3.05), (13.5, 0.7, 3.65), "sillar", jit(SILLAR, 0.05), jit_v=0.012)
    caja_mm(M, (7.65, 0.7, 3.0), (13.55, 0.8, 3.7), "sillar", jit(SILLAR, 0.05))
    choque((10.6, 0.4, 3.35), (5.8, 0.8, 0.6))
    # leña bajo el cobertizo
    for fila in range(4):
        for k in range(9 - fila):
            x = 13.0 + k * 0.24 + fila * 0.12
            cilindro(M, (x, 0.11 + fila * 0.2, -2.6), [(0, 0.1), (0.85, 0.1)], 7, "madera", jit(MADERA, 0.1), rot=R(0, 90),
                     tapa_arriba=True, tapa_abajo=False, fase=k)
    choque((14.1, 0.45, -2.2), (2.4, 0.9, 0.9))
    # un farol de pie en la calleja del este (al fondo, que guía)
    viga(M, (10.6, 0.0, -4.6), (10.6, 2.7, -4.6), 0.1, "madera", MADERA_OSC)
    farol(M, (10.6, 2.72, -4.6))


# ---------------------------------------------------------------- vegetación (agrupada en bordes, grietas y rincones)

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


def hiedra(V, x, z_pared, y_max, eje="z", hacia=(0, 0, 1)):
    """Hiedra que trepa por una pared: tallos al azar hacia arriba con racimos de hojas planos contra el muro."""
    for tallo in range(4):
        p = Vector((x + RND.uniform(-0.3, 0.3), 0.05, z_pared + 0.06)) if eje == "z" else \
            Vector((z_pared + 0.06, 0.05, x + RND.uniform(-0.3, 0.3)))
        y_fin = y_max * RND.uniform(0.6, 1.0)
        while p.y < y_fin:
            hojas(V, p, 0.22, 7, HOJA, 0.075, flex=0.15 + p.y / y_max * 0.2, aplastar=1.0, hacia=hacia)
            paso = Vector((RND.uniform(-0.25, 0.25), RND.uniform(0.15, 0.3), 0))
            if eje != "z":
                paso = Vector((0, paso.y, paso.x))
            p += paso


def huerto(M, P, V):
    """La orilla sur (lo que queda DETRÁS de la cámara de la muestra y se ve con la de juego de Oakhaven, más alta): un
    huerto con cerca de varas trenzadas, bancales con coles, un pozo con su tejadillo, un almiar y un arbolillo. Todo bajo
    1,6 m cerca de la calle, para no tapar a Kael con la cámara baja."""
    # la cerca (postes y tres varas), con un hueco de paso
    x = -15.0
    while x < 3.0:
        if -6.0 < x < -4.9:
            x += 0.6
            continue
        viga(P, (x, 0.0, 4.5), (x + RND.uniform(-0.03, 0.03), 0.95, 4.5 + RND.uniform(-0.03, 0.03)), 0.07, "madera", MADERA_GRIS)
        x += 0.6
    for y in (0.35, 0.6, 0.85):
        for a, b in ((-15.0, -6.0), (-4.9, 3.0)):
            viga(P, (a, y, 4.5), (b, y + RND.uniform(-0.04, 0.04), 4.5), 0.035, "madera", jit(MADERA_GRIS, 0.06))
    choque((-10.5, 0.5, 4.5), (9.0, 1.0, 0.2))
    choque((-0.95, 0.5, 4.5), (7.9, 1.0, 0.2))
    # bancales de tierra oscura con coles y alguna flor
    for k, x0 in enumerate((-14.0, -11.6, -9.2, -3.8, -1.4)):
        caja_mm(M, (x0, 0.0, 5.2), (x0 + 1.8, 0.14, 8.6), "tierra", (0.46, 0.36, 0.28), caras="asneo")
        for zz in (5.6, 6.3, 7.0, 7.7, 8.3):
            for xx in (x0 + 0.45, x0 + 1.35):
                if RND.random() < 0.85:
                    hojas(V, (xx + RND.uniform(-0.08, 0.08), 0.28, zz), 0.2, 16,
                          ((0.42, 0.62, 0.36), (0.50, 0.70, 0.40), (0.36, 0.54, 0.32)), 0.11, flex=0.15, aplastar=0.6)
        if k % 2 == 0:
            mata_flores(V, (x0 + 0.9, 0.14, 8.9), 0.4, FLORES[k % len(FLORES)], 12, 0.4)
    # el pozo: brocal de piedra, dos postes, travesaño, tejadillo y cubo
    px, pz = 2.6, 6.4
    cilindro(M, (px, 0.0, pz), [(0, 0.78), (0.75, 0.74), (0.82, 0.8), (0.9, 0.8)], 14, "sillar", jit(SILLAR, 0.05),
             suave=False)
    cilindro(M, (px, 0.84, pz), [(0, 0.6), (0.02, 0.6)], 14, "hierro", (0.06, 0.06, 0.07), tapa_arriba=True)
    for s_ in (-1, 1):
        viga(M, (px + s_ * 0.72, 0.85, pz), (px + s_ * 0.72, 2.2, pz), 0.11, "madera", MADERA_OSC)
    viga(M, (px - 0.85, 2.1, pz), (px + 0.85, 2.1, pz), 0.09, "madera", MADERA_OSC)
    faldon(M, (px - 1.0, 2.15, pz + 0.75), (px + 1.0, 2.15, pz + 0.75), (0, 0.5, -0.75), TEJA, musgo=0.4, solape=0.26)
    faldon(M, (px + 1.0, 2.15, pz - 0.75), (px - 1.0, 2.15, pz - 0.75), (0, 0.5, 0.75), TEJA, musgo=0.4, solape=0.26)
    viga(M, (px + 0.1, 2.1, pz), (px + 0.1, 1.45, pz), 0.012, "tela", (0.7, 0.62, 0.48))
    cilindro(P, (px + 0.1, 1.2, pz), [(0, 0.11), (0.25, 0.13)], 9, "madera", jit(MADERA, 0.05), tapa_arriba=False)
    choque((px, 0.5, pz), (1.6, 1.0, 1.6))
    for k in range(5):
        mata(V, (px + math.cos(k * 1.3) * 0.95, 0.0, pz + math.sin(k * 1.3) * 0.95), 0.16, 12, 0.32)
    # macizo de flores al este y un almiar con su horca
    for x in (5.0, 6.4, 7.9, 9.3, 10.8):
        mata_flores(V, (x, 0.0, 4.9 + RND.uniform(-0.2, 0.2)), 0.45, RND.choice(FLORES), 14, 0.5)
        mata(V, (x + 0.6, 0.0, 5.2), 0.3, 18, 0.5)
    cilindro(P, (6.2, 0.0, 7.8), [(0, 1.0), (0.8, 1.05), (1.5, 0.8), (2.1, 0.35), (2.35, 0.05)], 12, "tela",
             (0.92, 0.78, 0.46), suave=True)
    viga(P, (7.1, 0.0, 7.2), (6.6, 1.8, 7.4), 0.04, "madera", MADERA_GRIS)
    # un arbolillo al fondo del huerto (solo lo ve la cámara alta)
    tx, tz = 11.5, 8.0
    cilindro(M, (tx, 0.0, tz), [(0, 0.24), (1.6, 0.17), (2.4, 0.13)], 8, "madera", (0.52, 0.42, 0.34))
    for c, r in (((tx, 3.1, tz), 1.3), ((tx + 0.9, 2.8, tz + 0.3), 0.9), ((tx - 0.8, 3.2, tz - 0.2), 0.95)):
        hojas(V, c, r, int(200 * r), HOJA, 0.15, flex=0.5, aplastar=0.8)


def vegetacion(M, V, flores, juntas):
    # matas al pie de las fachadas (más en las esquinas y junto a los escalones) — los bordes
    for (x0, x1, z) in ((A_X0, A_X1, A_Z + 0.12), (B_X0, B_X1, B_Z + 0.12)):
        x = x0
        while x < x1:
            esquina = min(abs(x - x0), abs(x - x1), abs(x - PUERTA_X) - 1.2 if x1 < 0 else 9)
            if RND.random() < (0.9 if esquina < 0.8 else 0.4):
                mata(V, (x, 0.0, z + RND.uniform(0, 0.18)), RND.uniform(0.14, 0.26), RND.randint(10, 20),
                     RND.uniform(0.22, 0.42))
            x += RND.uniform(0.25, 0.6)
    # en las juntas de las losas, sobre todo hacia la orilla — las grietas
    for j in juntas:
        if RND.random() < 0.8:
            y = altura_suelo(j[0], j[1])
            mata(V, (j[0], y, j[1]), 0.09, RND.randint(5, 9), RND.uniform(0.1, 0.2), ladeo=0.6)
    # la orilla sur de la calle y el primer plano: MATORRALES AGRUPADOS (con calvas de tierra entre ellos), no repartidos
    x = -19.0
    while x < 19.0:
        cx, cz = x + RND.uniform(-0.4, 0.4), 2.75 + RND.uniform(0.0, 1.0)
        for k in range(RND.randint(4, 9)):
            a, d = RND.uniform(0, math.tau), RND.uniform(0, 0.75)
            mata(V, (cx + math.cos(a) * d * 1.4, 0.0, cz + math.sin(a) * d * 0.6), RND.uniform(0.14, 0.28),
                 RND.randint(10, 20), RND.uniform(0.3, 0.6) * (1.0 - d * 0.4))
        if RND.random() < 0.6:
            mata_flores(V, (cx + RND.uniform(-0.4, 0.4), 0.0, cz + 0.1), 0.25, RND.choice(FLORES), n=12, alto=0.45)
        if RND.random() < 0.3:
            hojas(V, (cx + 0.3, 0.25, cz + 0.2), 0.42, 40, HOJA, 0.11, flex=0.35, aplastar=0.7)
        x += RND.uniform(1.6, 3.2)
    # rincones: el callejón (escalones), el pie del guardacantón, la puerta, el muro del huerto
    for k in range(5):
        y = k * 0.17 + 0.17
        z = -3.4 - k * 0.4 - 0.35
        for lado in (-1, 1):
            if RND.random() < 0.8:
                mata(V, (lado * 1.6, y, z), 0.1, RND.randint(5, 9), RND.uniform(0.15, 0.28))
    for p in ((B_X1 + 0.35, 0.0, B_Z + 0.4), (B_X1 + 0.5, 0.0, B_Z - 0.3), (PUERTA_X - 1.3, 0.0, -1.55),
              (PUERTA_X + 1.25, 0.0, -1.5), (-1.6, 0.0, -2.45), (1.55, 0.0, -2.35)):
        mata(V, p, 0.22, 14, 0.36)
    mata_flores(V, (PUERTA_X - 1.5, 0.0, -1.45), 0.25, FLORES[0], 9, 0.42)
    mata_flores(V, (B_X1 + 0.55, 0.0, B_Z + 0.75), 0.22, FLORES[1], 8, 0.38)
    # arbustos al pie del muro del huerto y del cobertizo
    for x in (-19.0, -17.4, -15.9, -14.6):
        hojas(V, (x, 0.45, -2.2), RND.uniform(0.5, 0.75), 70, HOJA, 0.12, flex=0.35, aplastar=0.75)
    for x in (17.2, 18.5):
        hojas(V, (x, 0.4, -2.4), 0.6, 60, HOJA, 0.12, flex=0.35, aplastar=0.7)
    hojas(V, (12.35, 0.45, 2.75), 0.45, 40, HOJA, 0.11, flex=0.35, aplastar=0.8)
    # las jardineras de las ventanas
    for p in flores:
        if p is None:
            continue
        for k in range(3):
            mata_flores(V, p + Vector((-0.3 + k * 0.3, 0.0, 0.0)), 0.15, RND.choice(FLORES), 8, 0.26)
        hojas(V, p + Vector((0, -0.12, 0.08)), 0.3, 22, HOJA, 0.07, flex=0.3, aplastar=0.4)   # lo que cuelga
    # hiedra en la esquina oeste de la casa A y en el fondo del callejón
    hiedra(V, A_X0 + 0.4, A_Z, 4.6)
    hiedra(V, -1.4, -9.3, 4.2)
    hiedra(V, 1.4, -9.3, 3.4)
    hojas(V, (0.0, 4.5, -9.4), 0.9, 90, HOJA, 0.11, flex=0.4, aplastar=0.5)
    # el árbol detrás del muro del huerto (oeste): tronco y copa en racimos (el fondo)
    tx, tz = -16.6, -5.2
    cilindro(M, (tx, 0.0, tz), [(0, 0.4), (0.5, 0.3), (2.6, 0.24), (3.6, 0.2)], 9, "madera", (0.52, 0.42, 0.34))
    viga(M, (tx, 2.6, tz), (tx + 1.3, 4.2, tz + 0.4), 0.16, "madera", (0.52, 0.42, 0.34))
    viga(M, (tx, 3.0, tz), (tx - 1.1, 4.4, tz - 0.3), 0.15, "madera", (0.52, 0.42, 0.34))
    for c, r in (((tx, 4.6, tz), 1.9), ((tx + 1.6, 4.4, tz + 0.6), 1.4), ((tx - 1.5, 4.8, tz - 0.2), 1.5),
                 ((tx + 0.4, 5.8, tz - 0.3), 1.3), ((tx + 2.3, 3.6, tz + 1.0), 1.0)):
        hojas(V, c, r, int(260 * r), HOJA, 0.16, flex=0.5, aplastar=0.8)
    # un rosal trepador junto a la puerta de B (acento)
    hojas(V, (B_X0 + 0.35, 1.2, B_Z + 0.12), 0.45, 45, HOJA, 0.09, flex=0.3, aplastar=1.6, hacia=(0, 0, 1))
    for k in range(10):
        c = Vector((B_X0 + 0.35 + RND.uniform(-0.35, 0.35), RND.uniform(0.6, 1.9), B_Z + 0.2))
        pts = [c + Vector((math.cos(j * math.tau / 5) * 0.05, math.sin(j * math.tau / 5) * 0.05, 0)) for j in range(5)]
        V.cara(pts, "hoja", [lin(jit(FLORES[4], 0.05), 0.3)] * 5)


# ---------------------------------------------------------------- texturas pintadas por código (512², repetibles)

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


# ---------------------------------------------------------------- de las listas a Blender

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


# ---------------------------------------------------------------- recorte: lo que ninguna cámara ve

def recortar(M, otra=None):
    """Separa las caras que ve alguna cámara de las que no (estas solo sirven para el horneado: tapan y rebotan luz).
    «otra»: otra malla que también tapa (las piezas con luz en los vértices tapan a lo fijo y al revés)."""
    verts, polys = [], []
    for pts, *_ in M.caras + (otra.caras if otra is not None else []):
        b = len(verts)
        verts.extend([Vector((p.x, p.y, p.z)) for p in pts])
        polys.append(list(range(b, b + len(pts))))
    bvh = BVHTree.FromPolygons(verts, polys, all_triangles=False, epsilon=0.0)
    cams = camaras()
    tf = math.tan(math.radians(CAM_FOV) * 0.5) * 1.06
    vis, ocu = Malla(), Malla()
    for idx, cara in enumerate(M.caras):
        pts = cara[0]
        n = normal_de(pts)
        c = sum(pts, Vector((0, 0, 0))) / len(pts)
        muestras = [c] + [c.lerp(p, 0.85) for p in pts]
        doble = cara[1] in ("hoja", "tela")
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


# ---------------------------------------------------------------- sondas de luz para Kael

def sondas(bvh, hs):
    x0, x1, z0, z1, paso = -14.0, 14.0, -7.5, 4.0, 0.25
    nx, nz = int((x1 - x0) / paso) + 1, int((z1 - z0) / paso) + 1
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


# ---------------------------------------------------------------- escena de horneado, horneado y exportación

def preparar_cycles():
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
    for k, p in ANCLAS.items():                            # la luz cálida de los faroles y de la hornacina
        if k.startswith("farol_") or k == "hornacina":
            ld = bpy.data.lights.new(k, 'POINT')
            ld.energy = 30.0 if k.startswith("farol_") else 8.0
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


def hornear(ob_vis, ob_veg, carpeta):
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
    img = bpy.data.images["calle_luz"]
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


def escala_y_guardar(img, carpeta, objs_vertice):
    w, h = img.size
    px = np.array(img.pixels[:], np.float32).reshape(h, w, 4)
    lum = px[..., :3].max(-1)
    validos = lum[lum > 0.0005]
    escala = float(np.percentile(validos, 99.7)) / 0.97 if validos.size else 1.0
    out = {}
    for res in (w, w // 2):
        nombre = "calle_luz_%d" % res
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
    # la vegetación y las piezas: tinte × luz / escala
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
        c[:, :3] = np.clip(c[:, :3] * l[:, :3] / escala, 0, 1)
        col.data.foreach_set("color", c.ravel())
        vm.color_attributes.remove(luz)
        vm.color_attributes.active_color = vm.color_attributes["Col"]
    return escala


def exportar(objs, ruta):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=ruta, export_format='GLB', use_selection=True, export_animations=False,
                              export_yup=True, export_vertex_color='ACTIVE', export_all_vertex_colors=False,
                              export_cameras=False, export_lights=False, export_apply=True, export_texcoords=True,
                              export_normals=True, export_image_format='NONE', export_materials='EXPORT')
    nota("EXPORTADO %s" % ruta)


def vacios():
    objs = []
    for k, (c, s, yaw) in enumerate(CHOQUES):
        e = bpy.data.objects.new("choque_%03d" % k, None)
        e.empty_display_type = 'CUBE'
        e.location = (c[0], -c[2], c[1])
        e.scale = (s[0] / 2, s[2] / 2, s[1] / 2)
        e.rotation_euler = (0, 0, math.radians(yaw))
        bpy.context.scene.collection.objects.link(e)
        objs.append(e)
    for k, p in ANCLAS.items():
        e = bpy.data.objects.new("ancla_" + k, None)
        e.location = (p[0], -p[2], p[1])
        bpy.context.scene.collection.objects.link(e)
        objs.append(e)
    return objs


def main():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    carpeta_mod = os.path.join(CARPETA, "modelos") if CARPETA else ""
    carpeta_tex = os.path.join(CARPETA, "texturas") if CARPETA else ""
    for c in (carpeta_mod, carpeta_tex):
        if c:
            os.makedirs(c, exist_ok=True)
    M, V, P = Malla(), Malla(), Malla()      # P: piezas con la luz en los vértices (losas y objetos)
    suelo(M)
    juntas = empedrado(P, V) if DETALLE else []
    if BLOCKOUT:
        for x in (-11.6, -9.4, 3.6, 7.8, -13.6, 11.4):
            caja_mm(M, (x - 0.35, 0, -2.2 if x > -13 and x < 10 else 3.2), (x + 0.35, 0.8, -1.5 if x > -13 and x < 10 else 3.9),
                    "madera", MADERA)
    flores_a = casa_a(M, V) or []
    flores_b = casa_b(M, V) or []
    callejon(M, V)
    extremos(M, V)
    if DECORADO:
        montones(P, V)
        huerto(M, P, V)
        vegetacion(M, V, flores_a + flores_b, juntas)
    nota("construido: %d triángulos fijos, %d de piezas, %d de vegetación, %d choques, %d anclas" % (
        M.tris(), P.tris(), V.tris(), len(CHOQUES), len(ANCLAS)))
    imgs = texturas(carpeta_tex)
    nota("texturas pintadas")
    if RECORTE and not BLOCKOUT:
        vis, ocu = recortar(M, P)
        pvis, pocu = recortar(P, M)
        ocu.caras += pocu.caras
        nota("recorte: %d + %d triángulos a la vista, %d que ninguna cámara ve" % (vis.tris(), pvis.tris(), ocu.tris()))
    else:
        vis, pvis, ocu = M, P, Malla()
    img_luz = None
    if HORNEAR:
        img_luz = bpy.data.images.new("calle_luz", RES, RES, alpha=False, float_buffer=True)
    mats = materiales(imgs, img_luz)
    ob_vis = a_blender("calle", vis, mats, HORNEAR)
    ob_ocu = a_blender("oculto", ocu, mats, False) if ocu.caras else None
    for malla in (V, pvis):
        if not malla.caras:
            malla.cara([Vector((0, -5, 0)), Vector((0.01, -5, 0)), Vector((0, -5, 0.01))], "hoja", (0.3, 0.5, 0.2))
    ob_veg = a_blender("vegetacion", V, mats, False)
    ob_pie = a_blender("piezas", pvis, mats, False)
    datos = {"fase": FASE, "horneado": HORNEAR, "tris_calle": vis.tris(), "tris_piezas": pvis.tris(),
             "tris_oculto": ocu.tris(), "tris_vegetacion": V.tris()}
    if HORNEAR:
        preparar_cycles()
        cal = calibrar()
        hornear(ob_vis, [ob_veg, ob_pie], carpeta_mod)
        escala = escala_y_guardar(img_luz, carpeta_mod, [ob_veg, ob_pie])
        # sondas con todo lo que tapa (lo visto, las piezas y lo oculto)
        objs = [o for o in (ob_vis, ob_pie, ob_ocu) if o is not None]
        dg = bpy.context.evaluated_depsgraph_get()
        vs, ps = [], []
        for o in objs:
            m = o.evaluated_get(dg).data
            b = len(vs)
            vs.extend([o.matrix_world @ v.co for v in m.vertices])
            ps.extend([[b + i for i in p.vertices] for p in m.polygons])
        bvh = BVHTree.FromPolygons(vs, ps)
        hs = hacia_sol()
        sun_frente = cal["frente"]
        cielo_esp = cal["espalda"]
        datos.update({
            "escala": escala,
            "res": [RES, RES // 2],
            "hacia_sol": [hs.x, hs.y, hs.z],
            "sol_color": list(SOL_COLOR),
            # el sol para Kael: lo que da de frente menos lo que pone el cielo (lambert de Godot: energía × N·L)
            "sol_energia": max(0.0, (sum(sun_frente) - sum(cielo_esp)) / 3.0),
            "sol_color_medido": [max(0.0, a - b) for a, b in zip(sun_frente, cielo_esp)],
            "cielo_color": cielo_esp,
            "sondas": sondas(bvh, hs),
        })
        nota("sondas de luz: %d × %d" % (datos["sondas"]["nx"], datos["sondas"]["nz"]))
    if carpeta_mod:
        exportar([ob_vis, ob_pie, ob_veg] + vacios(), os.path.join(carpeta_mod, "calle.glb"))
        with open(os.path.join(carpeta_mod, "calle_luz.json"), "w", encoding="utf-8") as f:
            json.dump(datos, f)
    nota("HECHO %s" % json.dumps({k: v for k, v in datos.items() if k != "sondas"}))


main()
