# Sunken City 3D · «La Quilla, de la costilla 44 a la rampa» (V12, 16/11, EXPERIMENTAL: solo con el interruptor
# «sunken_quilla_v12», en Auditoría o en el editor). Plan: docs/v12/SUNKEN_QUILLA.md (y el apartado 2 del plan
# SUNKEN_ARBOLEDA_PLAN.md). Obra propia: geometría procedural, texturas pintadas por código (numpy) y luz horneada con
# Cycles. Nada descargado, de pago ni de la nube. Misma semilla, mismo resultado.
#
#   blender -b --factory-startup -P crear_quilla.py -- <carpeta zonas3d/sunken/quilla> [opciones]
#     --fase composicion|arquitectura|materiales|iluminacion|completa   hasta dónde se construye (pasadas; por defecto
#                                                                       completa)
#     --muestras N     muestras de Cycles (por defecto 160)
#     --res N          lado del mapa de luz grande (por defecto 2048; el pequeño, la mitad)
#
# QUÉ HACE
#   1. Construye el sector ENTERO con el guion de siempre (zonas3d/sunken/fuente/crear_sunken.py), que se ejecuta aquí
#      SIN tocarlo (se lee y se quita su llamada final, como hace él con crear_distrito.py), con la misma semilla y en el
#      mismo orden: fuera de la Quilla, la geometría es idéntica a la de sunken.glb.
#   2. Quita los grupos de la Quilla (costillas 44, 38 y 32; casas colgadas 1-6 y sus bajos; tendederos) y pone el kit
#      nuevo: cuadernas dobles con baos, cartelas, flejes y pernos, verdín y percebes en el agua; casas colgadas hechas
#      con restos del barco (tracas pintadas, portas de cañón por ventanas, escotillas por puertas, toldos de vela
#      remendada, estufas de hojalata, escalas de gato, motones y cabos con comba), pasarelas a cada puerta, faroles de
#      barco, el empalme con abrazaderas de la costilla 32 rota, la cabria de la choza del este y el banco de la
#      carpintera.
#   3. Hornea la luz de TODO el sector (para que no haya costura con la popa ni con la Cubierta Mayor): el mismo sol y
#      el mismo cielo que zonas3d/sunken_3d.gd (_crear_ambiente), la laguna como rebote turquesa y los faroles (menos
#      el de la costilla 38, que no existe: la costilla que no alumbra).
#
# ESCRIBE (en <carpeta>):
#   modelos/quilla.glb
#     «fijo»          lo grande: una superficie por material, UV0 = textura que se repite, UV1 = mapa de luz,
#                     COLOR_0 = tinte (lineal). Choques «caja_*» de las casas como hijos.
#     «piezas»        lo pequeño (barandillas, cabos, faroles, atrezo): COLOR_0 = tinte × luz en los vértices / ESCALA
#     «corona_<dm>»   lo alto de cada costilla (por encima de 3 m): luz en los vértices; zonas3d/sunken/quilla/quilla.gd
#                     la OCULTA (visible = false) mientras queda entre la cámara y Kael (sin transparencias)
#     «edif_popa», «edif_palo», «bandera»   lo que puede tapar a Kael fuera de la Quilla: luz en los vértices y un
#                     material estándar sin luz (el de los cristales de siempre), para que la cámara los siga volviendo
#                     medio transparentes como antes (prototipos/vista3d.gd); con sus choques «caja_*»
#     vacíos «ancla_*»  los mismos nombres que sunken.glb (farol_44, farol_32, tabla, popa_nombre…), sin farol_38
#   luz/quilla_luz_<res>.png y quilla_luz_<res/2>.png   mapa de luz (luz / ESCALA, gamma 2,2)
#   luz/quilla_luz.json   fase, ESCALA, el sol y las sondas (rejilla de 0,5 m a 1 m del suelo: cuánto sol y cielo)
#   texturas/*.png         512², sin color (lo pone el tinte): tablazon, blanqueada, lona, hierro, cabo, liso
#
# Coordenadas: las de la escena (zonas3d/sunken/trazado.gd: x al este, z al sur, y arriba). LAS MEDIDAS del trazado son
# las de trazado.gd y crear_sunken.py: este guion no las cambia y no pone nada sólido dentro de lo andable.
import bpy, bmesh, os, sys, math, random, json, time
import numpy as np
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
CARPETA = argv[0] if argv and not argv[0].startswith("--") else ""
FASE = "completa"
MUESTRAS = 160
RES = 2048
_i = 1
while _i < len(argv):
    if argv[_i] == "--fase":
        FASE = argv[_i + 1]; _i += 1
    elif argv[_i] == "--muestras":
        MUESTRAS = int(argv[_i + 1]); _i += 1
    elif argv[_i] == "--res":
        RES = int(argv[_i + 1]); _i += 1
    _i += 1
FASES = ["composicion", "arquitectura", "materiales", "iluminacion", "completa"]
NIVEL = FASES.index(FASE)
BLOCKOUT = NIVEL == 0
TEXTURAS = NIVEL >= 2
HORNEAR = NIVEL >= 3
ATREZO = NIVEL >= 4
AQUI = os.path.dirname(os.path.abspath(__file__))
SUNKEN_PY = os.path.normpath(os.path.join(AQUI, "..", "..", "fuente", "crear_sunken.py"))
T0 = time.time()


def nota(t):
    print("[quilla %6.1f s] %s" % (time.time() - T0, t), flush=True)


RND = random.Random(4402)

# ---------------------------------------------------------------- medidas (las de trazado.gd; no se cambian)
ALTO_CUBIERTA = 1.2
NIVEL_AGUA = -0.85
QUILLA = (38.4, 31.2, 41.6, 44.4)
RAMPA = (38.4, 28.8, 41.6, 31.2)
ANDABLE = [(38.6, 52.6, 41.4, 60.6), (33.6, 44.2, 46.4, 53.2), (46.4, 44.6, 49.8, 46.6), (49.6, 42.0, 55.8, 47.8),
           QUILLA, RAMPA, (30.0, 18.6, 50.0, 28.8), (50.0, 21.0, 54.6, 25.6)]
COSTILLAS_QUILLA = (44.0, 38.0, 32.0)
COSTILLA_OSCURA = 38.0

# ---------------------------------------------------------------- la luz: la de sunken_3d.gd (_crear_ambiente)
# DirectionalLight3D rotation_degrees (-32, -68, 0): la luz viaja hacia (0,786; -0,530; -0,318) → el sol está al
# oeste-suroeste, a 32° de altura. Color (1,0; 0,84; 0,64) sRGB y energía ≈ 1,05; ambiente (0,50; 0,62; 0,68) × 0,72.
_rx, _ry = math.radians(-32.0), math.radians(-68.0)
_d = Vector((0.0, math.sin(_rx), -math.cos(_rx)))
LUZ_VIAJA = Vector((_d.z * math.sin(_ry), _d.y, _d.z * math.cos(_ry))).normalized()
HACIA_SOL = -LUZ_VIAJA


def lin1(x):
    return x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4


def lin(c, a=1.0):
    return (lin1(c[0]), lin1(c[1]), lin1(c[2]), a)


SOL_COLOR = lin((1.0, 0.84, 0.64))[:3]
SOL_GODOT = 1.05                     # la energía del sol de la escena (perfil sin cambios de «luz_sol»)
CIELO_COLOR = lin((0.50, 0.62, 0.68))[:3]
CIELO_GODOT = 0.72
SOL_EXTRA = 1.12                     # el horneado lleva rebotes; el sol, un punto más fuerte para que la tarde se lea
CIELO_EXTRA = 1.3                   # (sin la luz ambiente plana de antes, la sombra con oclusión quedaba negra)
LUZ_FAROL = (1.0, 0.62, 0.30)
AGUA_ALBEDO = (0.03, 0.22, 0.24)     # la laguna (lineal) para el rebote turquesa en el intradós y bajo los toldos

# ---------------------------------------------------------------- paleta (diseño §2.2: ciudades_y_lugares.md; sRGB)
BLANQUEADA = ((0.66, 0.63, 0.57), (0.76, 0.73, 0.66), (0.86, 0.83, 0.76))   # (los de crear_sunken.py)
MOJADA = (0.22, 0.27, 0.25)
VERDIN = (0.31, 0.61, 0.54)                    # cobre con verdín #4E9C8A
OXIDO = (0.54, 0.29, 0.16)                     # hierro oxidado #8A4B2A
LONA = (0.72, 0.68, 0.60)                      # (al sol de la tarde la lona clara se quemaba)
REMIENDO = (0.66, 0.44, 0.20)                  # remiendos ocre
REMIENDO2 = (0.62, 0.42, 0.30)
BREA = (0.13, 0.10, 0.08)
CABO = (0.62, 0.53, 0.38)
TABLA = ((0.30, 0.22, 0.16), (0.38, 0.28, 0.20), (0.46, 0.35, 0.25))   # (los de crear_sunken.py)
PINTURAS = [(0.36, 0.54, 0.50), (0.60, 0.33, 0.24), (0.70, 0.66, 0.58), (0.32, 0.42, 0.54), (0.56, 0.46, 0.30)]
ROPA = [(0.76, 0.30, 0.24), (0.30, 0.46, 0.64), (0.92, 0.88, 0.70), (0.42, 0.58, 0.38), (0.86, 0.60, 0.30),
        (0.90, 0.90, 0.86)]
LATON = (0.80, 0.62, 0.32)
CRISTAL_FAROL = (1.0, 0.78, 0.44)
VENTANA = (0.95, 0.70, 0.40)


def jit(c, a=0.06):
    k = 1 + RND.uniform(-a, a)
    return tuple(max(0.0, min(1.0, x * k * (1 + RND.uniform(-a, a) * 0.3))) for x in c)


def mezcla(a, b, t):
    return tuple(a[k] * (1 - t) + b[k] * t for k in range(3))


# ---------------------------------------------------------------- materiales y texturas
MATS = ["tablazon", "blanqueada", "lona", "hierro", "cabo", "liso", "brillo"]
ESCALA_UV = {"tablazon": 1.4, "blanqueada": 1.8, "lona": 1.8, "hierro": 0.8, "cabo": 0.3, "liso": 2.0, "brillo": 1.0}
CON_VETA = {"tablazon", "blanqueada", "lona", "cabo"}      # la veta (o la costura) a lo largo de la cara


class Malla:
    """Caras en coordenadas de Godot: [puntos, material, colores RGBA lineales, uvs o None, suave, destino]."""

    def __init__(self):
        self.caras = []

    def cara(self, pts, mat, col, uvs=None, suave=False, destino=None):
        cols = col if isinstance(col, list) else [col] * len(pts)
        cols = [tuple(c) if len(c) == 4 else (c[0], c[1], c[2], 1.0) for c in cols]   # (los colores de Sunken van tal cual: el juego los trata como lineales desde la V12; así se conserva su tono)
        self.caras.append([[Vector(p) for p in pts], mat, cols, uvs, suave, destino])

    def tris(self):
        return sum(len(c[0]) - 2 for c in self.caras)


def normal_de(pts):
    n = Vector((0, 0, 0))
    for k in range(len(pts)):
        a, b = pts[k], pts[(k + 1) % len(pts)]
        n.x += (a.y - b.y) * (a.z + b.z)
        n.y += (a.z - b.z) * (a.x + b.x)
        n.z += (a.x - b.x) * (a.y + b.y)
    return n.normalized() if n.length > 1e-9 else Vector((0, 1, 0))


def area_de(pts):
    a = Vector((0, 0, 0))
    for k in range(1, len(pts) - 1):
        a += (pts[k] - pts[0]).cross(pts[k + 1] - pts[0])
    return a.length * 0.5


def uv_cara(pts, mat):
    """UV que se repite: con veta, V a lo largo del lado más largo de la cara; si no, proyección por el eje dominante."""
    e = ESCALA_UV.get(mat, 1.0)
    n = normal_de(pts)
    if mat in CON_VETA:
        largo, t = 0.0, None
        for k in range(len(pts)):
            d = pts[(k + 1) % len(pts)] - pts[k]
            d = d - n * d.dot(n)
            if d.length > largo:
                largo, t = d.length, d
        if t is not None and largo > 1e-6:
            t.normalize()
            b = n.cross(t).normalized()
            return [(p.dot(b) / e, p.dot(t) / e) for p in pts]
    ax, ay, az = abs(n.x), abs(n.y), abs(n.z)
    r = []
    for p in pts:
        if ay >= ax and ay >= az:
            u, v = p.x, p.z
        elif ax >= az:
            u, v = p.z, -p.y
        else:
            u, v = p.x, -p.y
        r.append((u / e, v / e))
    return r


CARAS_CAJA = {  # (normal local, esquinas en ±1)
    "e": ((1, 0, 0), [(1, -1, -1), (1, 1, -1), (1, 1, 1), (1, -1, 1)]),
    "o": ((-1, 0, 0), [(-1, -1, -1), (-1, -1, 1), (-1, 1, 1), (-1, 1, -1)]),
    "a": ((0, 1, 0), [(-1, 1, -1), (-1, 1, 1), (1, 1, 1), (1, 1, -1)]),
    "b": ((0, -1, 0), [(-1, -1, -1), (1, -1, -1), (1, -1, 1), (-1, -1, 1)]),
    "s": ((0, 0, 1), [(-1, -1, 1), (1, -1, 1), (1, 1, 1), (-1, 1, 1)]),
    "n": ((0, 0, -1), [(-1, -1, -1), (-1, 1, -1), (1, 1, -1), (1, -1, -1)]),
}


def caja(M, c, s, mat, col, rot=None, caras="eoasn", oscuro_lados=0.08, destino=None):
    """Caja de centro c y tamaño s, girada por rot (Matrix 3×3). Los lados, un punto más oscuros (se lee el volumen
    también en las pasadas sin hornear)."""
    c = Vector(c)
    h = Vector(s) * 0.5
    for k in caras:
        nl, esq = CARAS_CAJA[k]
        pts = []
        for e in esq:
            p = Vector((e[0] * h.x, e[1] * h.y, e[2] * h.z))
            pts.append(c + (rot @ p if rot is not None else p))
        cc = col if k == "a" else mezcla(col, (0, 0, 0), oscuro_lados)
        M.cara(pts, mat, cc, destino=destino)


def caja_mm(M, a, b, mat, col, **k):
    a, b = Vector(a), Vector(b)
    caja(M, (a + b) * 0.5, b - a, mat, col, **k)


def eje_rot(d, arriba=Vector((0, 1, 0))):
    """Matriz cuyo eje Y local apunta a d (para tubos y vigas)."""
    d = Vector(d).normalized()
    if abs(d.dot(arriba)) > 0.98:
        arriba = Vector((1, 0, 0))
    x = arriba.cross(d).normalized()
    z = x.cross(d).normalized()
    return Matrix((x, d, z)).transposed()


def viga(M, a, b, ancho, alto, mat, col, giro=0.0, caras="eoasnb", destino=None):
    """Una pieza recta de a a b con sección ancho × alto."""
    a, b = Vector(a), Vector(b)
    d = b - a
    r = eje_rot(d)
    if giro:
        r = r @ Matrix.Rotation(giro, 3, 'Y')
    caja(M, (a + b) * 0.5, (ancho, d.length, alto), mat, col, rot=r, caras=caras, destino=destino)


def tubo(M, a, b, ra, rb, n, mat, col, tapa_a=True, tapa_b=True, destino=None, suave=True):
    a, b = Vector(a), Vector(b)
    d = (b - a)
    if d.length < 1e-6:
        return
    r = eje_rot(d)
    x, z = r.col[0], r.col[2]
    anillo = lambda o, rr: [o + (x * math.cos(2 * math.pi * k / n) + z * math.sin(2 * math.pi * k / n)) * rr
                            for k in range(n)]
    A, B = anillo(a, ra), anillo(b, rb)
    for k in range(n):
        k2 = (k + 1) % n
        M.cara([A[k], A[k2], B[k2], B[k]], mat, col, suave=suave, destino=destino)
    if tapa_b:
        M.cara(list(B), mat, col, destino=destino)
    if tapa_a:
        M.cara(list(reversed(A)), mat, col, destino=destino)


def cabo(M, a, b, r=0.022, comba=0.0, n=6, col=None, destino=None):
    a, b = Vector(a), Vector(b)
    col = col or mezcla(CABO, BREA, 0.3)
    pts = [a.lerp(b, i / n) - Vector((0, comba * math.sin(math.pi * i / n), 0)) for i in range(n + 1)]
    for p, q in zip(pts, pts[1:]):
        tubo(M, p, q, r, r, 4, "cabo", col, tapa_a=False, tapa_b=False, destino=destino)
    return pts


def lona_curva(M, p00, p10, p01, p11, nu, nv, comba, col_fn, destino=None, grueso=0.0):
    """Una lona de cuatro esquinas, dividida en nu × nv, que se combá hacia abajo en el centro."""
    P = lambda u, v: (Vector(p00) * (1 - u) * (1 - v) + Vector(p10) * u * (1 - v) + Vector(p01) * (1 - u) * v
                      + Vector(p11) * u * v - Vector((0, comba * math.sin(math.pi * u) * math.sin(math.pi * v), 0)))
    for i in range(nu):
        for j in range(nv):
            u0, u1, v0, v1 = i / nu, (i + 1) / nu, j / nv, (j + 1) / nv
            pts = [P(u0, v0), P(u1, v0), P(u1, v1), P(u0, v1)]
            if normal_de(pts).y < 0:
                pts.reverse()
            M.cara(pts, "lona", col_fn(i, j), suave=True, destino=destino)
    return P


# ================================================================= 1. el sector de siempre (crear_sunken.py, sin tocarlo)

def cargar_sunken():
    src = open(SUNKEN_PY, encoding="utf-8").read()
    corte = src.rfind("\nconstruir_sunken(1.0")
    if corte < 0:
        raise RuntimeError("crear_sunken.py ha cambiado: no se encuentra su llamada final")
    ns = {"__file__": SUNKEN_PY, "__name__": "crear_sunken_base"}
    exec(compile(src[:corte], SUNKEN_PY, "exec"), ns)
    return ns


QUILLA_GRUPOS = ["costilla_440", "costilla_380", "costilla_320", "bajo_tendederos"] + \
    ["edif_casa_%d" % n for n in range(1, 7)] + ["bajo_casa_%d" % n for n in range(1, 7)]
FANTASMAS = ["edif_popa", "edif_palo", "bandera"]      # (siguen volviéndose transparentes si tapan a Kael)


def sector_de_siempre(S, M):
    """Construye el sector como construir_sunken (calidad 1, semilla 11, mismo orden) y pasa a M lo que no es de la
    Quilla. Devuelve los choques ([destino, x, y0, z, ancho, fondo, alto]) y las anclas."""
    S["Q"] = 1.0
    S["RND"].seed(11)
    S["ANCLAS"].clear()
    G = {}
    for f in ("costillas", "casco", "popa", "suelos", "casas", "archivo", "cubierta", "proa", "dique"):
        S[f](G)
    choques = []
    BASE, BRILLO, MADERA_M, TELA_M = 0, 1, 2, 3
    for nombre, G_ in G.items():
        if nombre in QUILLA_GRUPOS:
            continue
        es_costilla = nombre.startswith("costilla_")
        destino = nombre if nombre in FANTASMAS else ("corona_" + nombre[9:] if es_costilla else None)
        for idx, mi in zip(G_.caras, G_.mats):
            pts = [Vector((G_.v[i].x, G_.v[i].z, -G_.v[i].y)) for i in idx]
            cols = [G_.col[i] for i in idx]
            c0 = cols[0]
            if mi == BRILLO:
                mat = "brillo"
            elif mi == TELA_M:
                mat = "lona"
            elif mi == MADERA_M:
                mat = "blanqueada" if es_costilla or nombre in ("edif_palo", "edif_mascaron") else "tablazon"
            else:
                rojo = c0[0] > 0.35 and c0[0] > 1.5 * c0[2] and c0[1] < 0.45
                mat = "hierro" if rojo else "liso"
                if es_costilla:
                    mat = "blanqueada"
            d = destino
            if es_costilla:
                cy = sum(p.y for p in pts) / len(pts)
                d = destino if cy > 3.0 else None
            M.cara(pts, mat, [tuple(c) for c in cols], destino=d)
        for (x, y0, z, w, dd, h) in getattr(G_, "cajas_y", []):
            if es_costilla:
                continue                                 # (las coronas se ocultan; no hace falta su choque)
            choques.append([destino or "fijo", x, y0, z, w, dd, h])
    anclas = dict(S["ANCLAS"])
    for k in ("farol_44", "farol_38", "farol_32"):     # las de la Quilla las pone el kit
        anclas.pop(k, None)
    return choques, anclas


# ================================================================= 2. el kit de la Quilla

CHOQUES = []
ANCLAS = {}


def ancla(n, p):
    ANCLAS[n] = tuple(p)


def punto_costilla(t, semi, alto, y0=-1.6, cx=40.0):
    a = math.pi * t
    c, s = math.cos(a), math.sin(a)
    return cx - semi * math.copysign(abs(c) ** 0.72, c), y0 + (alto - y0) * (s ** 0.55)


def color_cuaderna(y, k):
    if y < NIVEL_AGUA + 0.15:
        return mezcla(MOJADA, VERDIN, 0.30 + 0.25 * k)
    if y < 0.7:
        return mezcla(mezcla(MOJADA, VERDIN, 0.2), BLANQUEADA[0], (y - NIVEL_AGUA) / 1.55)
    return jit(mezcla(BLANQUEADA[1], BLANQUEADA[2], k), 0.035)


def costilla_doble(M, z, semi=10.6, alto=8.4, rota=None, farol=None, sin_farol=False):
    """La cuaderna doble: dos costillas paralelas (ligazones) con sus pernos, unidas por un bao alto (la viga de lado a
    lado), con cartelas en las esquinas y flejes de hierro; percebes y verdín en la línea del agua. «rota»: (t0, t1)
    que falta (la 32, por el oeste): ahí, el empalme con abrazaderas a medio poner."""
    dm = int(z * 10)
    corona = "corona_%d" % dm
    n = 30 if not BLOCKOUT else 12
    for lado_z, ancho in ((-0.2, 0.26), (0.2, 0.26)):
        zz = z + lado_z
        pts = []
        for i in range(n + 1):
            t = i / n
            x, y = punto_costilla(t, semi - (0.08 if lado_z > 0 else 0.0), alto)
            pts.append((t, Vector((x, y, zz))))
        anillos = []
        for i, (t, p) in enumerate(pts):
            if rota and rota[0] < t < rota[1]:
                anillos.append(None)
                continue
            d = (pts[min(i + 1, n)][1] - pts[max(i - 1, 0)][1]).normalized()
            nrm = Vector((-d.y, d.x, 0.0))                  # hacia dentro del arco
            s = math.sin(math.pi * t)
            hondo = 0.62 - 0.22 * s
            k = 0.5 + 0.5 * math.sin(z * 1.7 + i * 0.9 + lado_z * 9)
            c = color_cuaderna(p.y, k)
            anillos.append(([p + nrm * hondo * sx + Vector((0, 0, ancho * 0.5 * sz))
                             for (sx, sz) in ((-0.5, -1), (0.5, -1), (0.5, 1), (-0.5, 1))], c, p.y))
        for a, b in zip(anillos, anillos[1:]):
            if a is None or b is None:
                continue
            for j in range(4):
                j2 = (j + 1) % 4
                q = [a[0][j], a[0][j2], b[0][j2], b[0][j]]
                centro = sum(q, Vector((0, 0, 0))) / 4
                eje = (a[0][0] + a[0][2]) * 0.5
                fuera = centro - eje
                if normal_de(q).dot(fuera) < 0:
                    q.reverse()
                cc = a[1] if j != 1 else mezcla(a[1], (0.12, 0.16, 0.18), 0.28)   # el intradós, más frío
                M.cara(q, "blanqueada", cc, suave=True, destino=corona if centro.y > 3.0 else None)
        for i, an in enumerate(anillos):                # tapas de los cortes y de los pies
            if an is None:
                continue
            falta = (i > 0 and anillos[i - 1] is None) or (i < len(anillos) - 1 and anillos[i + 1] is None)
            if i in (0, len(anillos) - 1) or falta:
                pts4 = list(an[0])
                M.cara(pts4, "blanqueada", mezcla(an[1], (0.2, 0.15, 0.1), 0.35),
                       destino=corona if an[2] > 3.0 else None)
        if BLOCKOUT:
            continue
        # pernos de hierro a lo largo de la costilla (cabezas cuadradas, a la vista desde el sur)
        for i in range(2, n - 1, 2):
            t, p = pts[i]
            if rota and rota[0] - 0.02 < t < rota[1] + 0.02:
                continue
            caja(M, (p.x, p.y, zz + (0.14 if lado_z > 0 else -0.14)), (0.07, 0.07, 0.03), "hierro",
                 jit(mezcla(OXIDO, BREA, 0.3), 0.1), destino=corona if p.y > 3.0 else None)
    if BLOCKOUT:
        return
    # flejes (abrazaderas de hierro que cogen las dos costillas)
    for t in (0.12, 0.30, 0.5, 0.70, 0.88):
        if rota and rota[0] - 0.04 < t < rota[1] + 0.04:
            continue
        x, y = punto_costilla(t, semi, alto)
        x2, y2 = punto_costilla(t + 0.01, semi, alto)
        tan = Vector((x2 - x, y2 - y, 0)).normalized()
        ex = tan.cross(Vector((0, 0, 1))).normalized()
        nr = Vector((-tan.y, tan.x, 0))
        hondo = 0.62 - 0.22 * math.sin(math.pi * t)
        c = Vector((x, y, z)) + nr * hondo * 0.0
        caja(M, c, (hondo + 0.12, 0.14, 0.8), "hierro", jit(OXIDO, 0.08),
             rot=Matrix((ex, tan, ex.cross(tan))).transposed(), destino=corona if y > 3.0 else None)
    # el bao (la viga de lado a lado a 6,2 m) con sus cartelas
    ybao = 6.2
    lados = []
    for sgn in (-1, 1):                                  # dónde corta el arco a 6,2 m (por dentro)
        lo, hi = (0.0, 0.5) if sgn < 0 else (0.5, 1.0)
        for _ in range(30):
            mid = (lo + hi) / 2
            _, y = punto_costilla(mid, semi, alto)
            if (y < ybao) == (sgn < 0):
                lo = mid
            else:
                hi = mid
        x, _ = punto_costilla((lo + hi) / 2, semi, alto)
        lados.append(x + (0.32 if sgn < 0 else -0.32))
    xa, xb = lados
    if True:
        caja_mm(M, (xa, ybao - 0.22, z - 0.24), (xb, ybao + 0.12, z + 0.24), "blanqueada",
                jit(mezcla(BLANQUEADA[1], TABLA[2], 0.3), 0.03), destino=corona)
        for x0, sg in ((xa, 1), (xb, -1)):               # cartelas (codos de madera) bajo el bao
            pts = [Vector((x0, ybao - 0.22, z + 0.14)), Vector((x0 + sg * 1.1, ybao - 0.22, z + 0.14)),
                   Vector((x0, ybao - 1.2, z + 0.14))]
            if normal_de(pts).z < 0:
                pts.reverse()
            M.cara(pts, "blanqueada", mezcla(BLANQUEADA[0], TABLA[2], 0.3), destino=corona)
            caja(M, (x0 + sg * 0.28, ybao - 0.5, z + 0.16), (0.1, 0.1, 0.04), "hierro", OXIDO, destino=corona)
        # un motón colgado del bao con su cabo (para izar: la vida de la Quilla)
        xm = 40.0 + (2.6 if (dm // 60) % 2 == 0 else -2.4)
        caja(M, (xm, ybao - 0.45, z), (0.16, 0.26, 0.12), "tablazon", TABLA[0], destino=corona)
        cabo(M, (xm, ybao - 0.2, z), (xm, ybao - 0.33, z), r=0.02, n=1, destino=corona)
        cabo(M, (xm - 0.05, ybao - 0.55, z), (xm + 0.4 * (1 if xm > 40 else -1), 3.6, z + 0.6), r=0.018,
             comba=0.15, n=4, destino=corona)
    # percebes y verdín en los pies (en el agua)
    for sx in (-1, 1):
        x, _ = punto_costilla(0.0 if sx < 0 else 1.0, semi, alto)
        for k in range(9):
            y = NIVEL_AGUA + RND.uniform(-0.3, 0.35)
            caja(M, (x + sx * RND.uniform(-0.25, 0.1), y, z + RND.uniform(-0.35, 0.35)),
                 (RND.uniform(0.08, 0.16),) * 2 + (RND.uniform(0.06, 0.12),), "liso",
                 jit(mezcla(VERDIN, (0.78, 0.76, 0.68), RND.random() * 0.6), 0.1))
    # el empalme de la costilla rota: una pieza nueva (más oscura) que salva el hueco, con dos abrazaderas puestas y
    # el sitio de las otras dos marcado (a medio poner: la carpintera de ribera trabaja en ello)
    if rota:
        ta, tb = rota[0] - 0.03, rota[1] + 0.03
        xa_, ya_ = punto_costilla(ta, semi, alto)
        xb_, yb_ = punto_costilla(tb, semi, alto)
        a, b = Vector((xa_ + 0.25, ya_, z + 0.42)), Vector((xb_ + 0.25, yb_, z + 0.42))
        viga(M, a, b, 0.24, 0.26, "tablazon", jit(mezcla(TABLA[2], BLANQUEADA[0], 0.25), 0.03), destino=None)
        for u in (0.12, 0.88):
            p = a.lerp(b, u)
            caja(M, p, (0.5, 0.12, 0.62), "hierro", jit(OXIDO, 0.06), rot=eje_rot(b - a))
        for u in (0.38, 0.62):                            # las que faltan: solo las marcas de tiza
            p = a.lerp(b, u) + Vector((0, 0, 0.14))
            caja(M, p, (0.36, 0.04, 0.01), "liso", (0.92, 0.92, 0.88), rot=eje_rot(b - a))
        ancla("empalme_32", tuple(a.lerp(b, 0.5)))
    # el farol de barco (o el cabo cortado de la costilla que no alumbra)
    if farol:
        xf = 40.9
        _, ytop = punto_costilla(0.5, semi, alto)
        if sin_farol:
            cabo(M, (xf, ybao - 0.2, z), (xf, 6.0, z), r=0.024, destino=corona)
            for k in range(4):
                ang = k * math.pi / 2
                tubo(M, (xf, 6.0, z), (xf + 0.08 * math.cos(ang), 5.78, z + 0.08 * math.sin(ang)), 0.01, 0.004, 3,
                     "cabo", CABO, destino=corona)
            ancla("cabo_cortado_%d" % int(z), (xf, 5.9, z))
        else:
            cabo(M, (xf, ybao - 0.2, z), (xf, 3.78, z), r=0.024, destino=corona)
            farol_barco(M, (xf, 3.3, z), destino=corona)
            ancla(farol, (xf, 3.3, z))


def farol_barco(M, p, destino=None):
    """Farol de barco: jaula de latón de seis lados con el cristal encendido (brillo), techo y aro de colgar."""
    p = Vector(p)
    tubo(M, p + Vector((0, -0.25, 0)), p + Vector((0, 0.25, 0)), 0.14, 0.14, 6, "brillo", CRISTAL_FAROL, destino=destino)
    tubo(M, p + Vector((0, 0.25, 0)), p + Vector((0, 0.42, 0)), 0.19, 0.05, 6, "hierro", mezcla(LATON, OXIDO, 0.4),
         destino=destino)
    tubo(M, p + Vector((0, -0.34, 0)), p + Vector((0, -0.25, 0)), 0.16, 0.19, 6, "hierro", mezcla(LATON, OXIDO, 0.4),
         destino=destino)
    for k in range(6):
        a = 2 * math.pi * (k + 0.5) / 6
        q = p + Vector((math.cos(a) * 0.155, 0, math.sin(a) * 0.155))
        tubo(M, q + Vector((0, -0.25, 0)), q + Vector((0, 0.25, 0)), 0.014, 0.014, 3, "hierro", LATON, False, False,
             destino=destino)
    tubo(M, p + Vector((0, 0.42, 0)), p + Vector((0, 0.5, 0)), 0.04, 0.04, 5, "hierro", OXIDO, destino=destino)


# ---------------------------------------------------------------- casas colgadas hechas con restos del barco

def pilotes(M, x0, z0, x1, z1, y, paso=1.9):
    for x in (x0 + 0.18, x1 - 0.18):
        z = z0 + 0.25
        while z < z1:
            tubo(M, (x, -2.0, z), (x, NIVEL_AGUA + 0.2, z), 0.12, 0.12, 6, "liso", jit(MOJADA, 0.08), tapa_b=False)
            tubo(M, (x, NIVEL_AGUA + 0.2, z), (x, y - 0.12, z), 0.12, 0.11, 6, "tablazon",
                 jit(mezcla(TABLA[1], VERDIN, 0.15), 0.08), tapa_a=False)
            z += paso


def tablas_pared(M, x0, z0, x1, z1, y0, y1, hacia, base_c, semilla):
    """Una pared de tracas verticales (tablas viejas del barco), cada una con su tono: unas pintadas, otras ya
    blanqueadas, alguna nueva más clara. «hacia»: normal hacia fuera (eje x o z)."""
    rng = random.Random(semilla)
    a, b = Vector((x0, 0, z0)), Vector((x1, 0, z1))
    largo = (b - a).length
    d = (b - a).normalized()
    nrm = Vector(hacia)
    pos = 0.0
    while pos < largo - 0.02:
        w = min(rng.uniform(0.24, 0.36), largo - pos)
        r = rng.random()
        if r < 0.62:
            c = jit(mezcla(base_c, TABLA[1], rng.uniform(0.05, 0.3)), 0.05)
        elif r < 0.9:
            c = jit(mezcla(BLANQUEADA[0], TABLA[1], rng.uniform(0.2, 0.5)), 0.05)
        else:
            c = jit(mezcla(TABLA[2], (0.9, 0.8, 0.62), 0.3), 0.04)
        top = y1 + rng.uniform(-0.06, 0.08)
        p0 = a + d * pos
        cen = p0 + d * (w * 0.5) + nrm * rng.uniform(0.0, 0.025)
        cen.y = (y0 + top) * 0.5
        rot = Matrix((Vector((0, 1, 0)).cross(nrm), Vector((0, 1, 0)), nrm)).transposed()
        caja(M, cen, (w - 0.018, top - y0, 0.05), "tablazon", c, rot=rot, caras="asn")
        pos += w
    # la junta de brea detrás (se ve entre tablas)
    p0, p1 = a + nrm * -0.03, b + nrm * -0.03
    pts = [Vector((p0.x, y0, p0.z)), Vector((p1.x, y0, p1.z)), Vector((p1.x, y1, p1.z)), Vector((p0.x, y1, p0.z))]
    if normal_de(pts).dot(nrm) < 0:
        pts.reverse()
    M.cara(pts, "tablazon", BREA)


def porta(M, c, ancho, alto, hacia, lado, abierta=True):
    """Una porta de cañón hecha ventana: marco grueso, hueco con luz dentro y la tapa levantada con un cabo."""
    c = Vector(c)
    n = Vector(hacia)
    u = Vector((0, 1, 0)).cross(n).normalized()
    rot = Matrix((u, Vector((0, 1, 0)), n)).transposed()
    M_ = M
    for du, dv, w, h in ((0, alto * 0.5 + 0.06, ancho + 0.24, 0.12), (0, -alto * 0.5 - 0.06, ancho + 0.24, 0.12),
                         (ancho * 0.5 + 0.06, 0, 0.12, alto), (-ancho * 0.5 - 0.06, 0, 0.12, alto)):
        caja(M_, c + u * du + Vector((0, dv, 0)) + n * 0.05, (w, h, 0.1), "tablazon", mezcla(TABLA[0], BREA, 0.3),
             rot=rot)
    caja(M_, c + n * 0.02, (ancho, alto, 0.02), "brillo", VENTANA, rot=rot, caras="s")
    for k in (-1, 1):                                    # dos barrotes
        caja(M_, c + u * (k * ancho * 0.18) + n * 0.035, (0.035, alto, 0.03), "hierro", OXIDO, rot=rot)
    if abierta:                                          # la tapa, levantada 55° hacia fuera, con su cabo
        ang = math.radians(55)
        bisagra = c + Vector((0, alto * 0.5 + 0.12, 0)) + n * 0.1
        dirv = (Vector((0, -1, 0)) * math.cos(ang) + n * math.sin(ang)).normalized()
        cen = bisagra + dirv * (alto * 0.5 + 0.05)
        r2 = Matrix((u, -dirv, u.cross(-dirv))).transposed()
        caja(M_, cen, (ancho + 0.2, alto + 0.1, 0.08), "tablazon", jit(PINTURAS[lado % len(PINTURAS)], 0.05), rot=r2)
        cabo(M_, bisagra + dirv * (alto + 0.08), bisagra + Vector((0, 0.7, 0)) - n * 0.05, r=0.012, n=2)


def puerta_escotilla(M, c, ancho, alto, hacia):
    """La puerta: una tapa de escotilla de enjaretado (rejilla de listones) con bandas de hierro."""
    c = Vector(c)
    n = Vector(hacia)
    u = Vector((0, 1, 0)).cross(n).normalized()
    rot = Matrix((u, Vector((0, 1, 0)), n)).transposed()
    caja(M, c + n * 0.03, (ancho + 0.16, alto + 0.08, 0.06), "tablazon", mezcla(TABLA[0], BREA, 0.35), rot=rot)
    caja(M, c + n * 0.07, (ancho, alto, 0.03), "tablazon", BREA, rot=rot, caras="s")
    k = 5
    for i in range(k):
        du = -ancho * 0.5 + ancho * (i + 0.5) / k
        caja(M, c + u * du + n * 0.09, (0.06, alto - 0.06, 0.03), "tablazon", jit(TABLA[2], 0.05), rot=rot)
    for j in range(7):
        dv = -alto * 0.5 + alto * (j + 0.5) / 7
        caja(M, c + Vector((0, dv, 0)) + n * 0.105, (ancho - 0.06, 0.05, 0.02), "tablazon", jit(TABLA[1], 0.05), rot=rot)
    for dv in (-alto * 0.3, alto * 0.3):
        caja(M, c + Vector((0, dv, 0)) + n * 0.125, (ancho + 0.1, 0.08, 0.015), "hierro", OXIDO, rot=rot)
    caja(M, c + u * (ancho * 0.36) + n * 0.14, (0.08, 0.08, 0.04), "hierro", LATON, rot=rot)


def estufa(M, x, y, z, alto=1.4):
    """La estufa de hojalata: su tubo sale por el tejado con un sombrerete y un codo."""
    tubo(M, (x, y - 0.3, z), (x, y + alto, z), 0.09, 0.09, 8, "hierro", jit(mezcla(OXIDO, (0.4, 0.4, 0.42), 0.4), 0.08))
    tubo(M, (x, y + alto, z), (x, y + alto + 0.06, z), 0.17, 0.17, 8, "hierro", mezcla(OXIDO, BREA, 0.3))
    tubo(M, (x, y + alto + 0.06, z), (x, y + alto + 0.2, z), 0.17, 0.02, 8, "hierro", mezcla(OXIDO, BREA, 0.2))
    ancla("humo_%d_%d" % (int(x * 10), int(z * 10)), (x, y + alto + 0.25, z))


def escala_gato(M, a, b, n=7):
    """Escala de gato: dos cabos y peldaños de madera."""
    a, b = Vector(a), Vector(b)
    lado = Vector((0, 0, 0.18)) if abs((b - a).z) < abs((b - a).x) + 0.01 else Vector((0.18, 0, 0))
    lado = Vector((0.18, 0, 0)) if abs(b.x - a.x) < 0.3 else lado
    for s in (-1, 1):
        cabo(M, a + lado * s, b + lado * s, r=0.015, n=2)
    for i in range(1, n):
        p = a.lerp(b, i / n)
        tubo(M, p - lado * 1.15, p + lado * 1.15, 0.025, 0.025, 5, "tablazon", jit(TABLA[2], 0.08))


def casa_barco(M, x0, x1, z0, z1, alto, hacia, semilla, techo="vela", piso=False, porche=0.0, y=0.3):
    """Una casa colgada entre dos costillas, hecha con restos del barco. hacia = +1 (puerta al este) o -1 (al oeste):
    la fachada de la puerta da a la Quilla. «porche»: metros de plataforma libre delante de la fachada."""
    rng = random.Random(semilla)
    RND.seed(semilla)
    xf = x1 if hacia > 0 else x0                          # el borde de la plataforma hacia la Quilla
    xw = xf - hacia * porche                             # la fachada
    xb = x0 if hacia > 0 else x1                          # el fondo
    # la plataforma (cubierta de tablas sobre vigas) y sus pilotes
    pilotes(M, x0, z0, x1, z1, y)
    for z in (z0 + 0.15, (z0 + z1) * 0.5, z1 - 0.15):
        caja_mm(M, (x0 - 0.15, y - 0.32, z - 0.1), (x1 + 0.15, y - 0.12, z + 0.1), "tablazon", mezcla(TABLA[0], BREA, 0.2))
    z = z0
    while z < z1 - 0.05:
        w = min(rng.uniform(0.26, 0.34), z1 - z)
        caja_mm(M, (x0 - 0.1, y - 0.12, z + 0.01), (x1 + 0.1, y, z + w - 0.01), "tablazon",
                jit(mezcla(TABLA[0], TABLA[2], rng.random()), 0.05))
        z += w
    base_c = PINTURAS[semilla % len(PINTURAS)]
    if BLOCKOUT:
        caja_mm(M, (min(xw, xb), y, z0 + 0.15), (max(xw, xb), y + alto, z1 - 0.15), "tablazon", base_c)
        ancla_choque(min(xw, xb), z0 + 0.15, max(xw, xb), z1 - 0.15, alto + 1.0, y)
        return
    zc = (z0 + z1) * 0.5
    zi, zf = z0 + 0.15, z1 - 0.15
    # paredes: la fachada (a la Quilla) y la del sur (la ve la cámara), con tracas; norte y fondo, lisas
    tablas_pared(M, xw, zi, xw, zf, y, y + alto, (hacia, 0, 0), base_c, semilla)
    tablas_pared(M, min(xw, xb), zf, max(xw, xb), zf, y, y + alto, (0, 0, 1), mezcla(base_c, (0, 0, 0), 0.06),
                 semilla + 1)
    for pts, nn in (([(xb, y, zi), (xb, y, zf), (xb, y + alto, zf), (xb, y + alto, zi)], (-hacia, 0, 0)),
                    ([(xw, y, zi), (xb, y, zi), (xb, y + alto, zi), (xw, y + alto, zi)], (0, 0, -1))):
        pts = [Vector(p) for p in pts]
        if normal_de(pts).dot(Vector(nn)) < 0:
            pts.reverse()
        M.cara(pts, "tablazon", mezcla(base_c, TABLA[0], 0.4))
    # esquineros y cinta de arriba (madera blanqueada)
    for zz in (zi, zf):
        caja_mm(M, (xw - 0.07, y, zz - 0.07), (xw + 0.07, y + alto + 0.1, zz + 0.07), "blanqueada", BLANQUEADA[0])
    caja_mm(M, (min(xw, xb) - 0.04, y + alto - 0.06, zf - 0.04), (max(xw, xb) + 0.04, y + alto + 0.06, zf + 0.08),
            "blanqueada", BLANQUEADA[0])
    # la puerta (tapa de escotilla) y las portas de cañón por ventanas
    zp = zc + (0.7 if semilla % 2 else -0.7)
    puerta_escotilla(M, (xw + hacia * 0.02, y + 0.95, zp), 0.82, 1.8, (hacia, 0, 0))
    ancla("puerta_%d" % semilla, (xw + hacia * 0.3, y, zp))
    porta(M, (xw + hacia * 0.02, y + 1.55, zp - (1.45 if semilla % 2 else -1.45)), 0.55, 0.48, (hacia, 0, 0), semilla)
    porta(M, ((xw + xb) * 0.5, y + 1.6, zf + 0.04), 0.5, 0.45, (0, 0, 1), semilla + 1, abierta=rng.random() < 0.6)
    top = y + alto
    # el techo: vela remendada sobre listones (cae hacia la Quilla) o tablas embreadas con un parche de lona
    if techo == "vela":
        alto_fondo = top + 0.95
        xa = xb - hacia * 0.25
        xv = xf + hacia * 0.45
        for zz in (zi + 0.3, zc, zf - 0.3):               # listones bajo la vela
            viga(M, (xa, alto_fondo - 0.08, zz), (xv, top - 0.1, zz), 0.08, 0.08, "blanqueada",
                 mezcla(BLANQUEADA[0], TABLA[1], 0.3))
        rem = {(rng.randrange(5), rng.randrange(3)) for _ in range(3)}

        def color(i, j):
            if (i, j) in rem:
                return jit(REMIENDO if (i + j) % 2 else REMIENDO2, 0.04)
            return jit(mezcla(LONA, (0.78, 0.74, 0.66), 0.25 * (j % 2)), 0.03)
        P = lona_curva(M, (xa, alto_fondo, z0 - 0.25), (xv, top - 0.05, z0 - 0.25),
                       (xa, alto_fondo, z1 + 0.25), (xv, top - 0.05, z1 + 0.25), 5, 3, 0.12, color)
        # el dobladillo del borde bajo y los cabos que la atan a los listones
        cabo(M, P(1.0, 0.0) + Vector((0, -0.03, 0)), P(1.0, 1.0) + Vector((0, -0.03, 0)), r=0.03, n=3,
             col=mezcla(LONA, BREA, 0.3))
        for v in (0.15, 0.5, 0.85):
            cabo(M, P(0.0, v) + Vector((0, 0.04, 0)), P(1.0, v) + Vector((0, 0.04, 0)), r=0.016, comba=-0.05, n=4)
            caja(M, P(0.5, v) + Vector((0, 0.08, 0)), (0.22, 0.12, 0.18), "lona", jit(mezcla(LONA, TABLA[1], 0.5), 0.05))
    else:
        alto_c = top + 0.75
        for lado_z, zz0, zz1 in ((1, zc, z1 + 0.25), (-1, z0 - 0.25, zc)):
            filas = 7
            for f in range(filas):
                xa_ = min(xw, xb) - 0.25 + (abs(xb - xw) + 0.5) * f / filas
                xb_ = xa_ + (abs(xb - xw) + 0.5) / filas
                c = jit(mezcla(TABLA[0], TABLA[2], rng.random() * 0.7), 0.05)
                yz0, yz1 = (alto_c, top) if lado_z > 0 else (top, alto_c)
                pts = [Vector((xa_ + 0.01, yz0 if lado_z > 0 else yz1, zc if lado_z > 0 else zc)),
                       Vector((xb_ - 0.01, yz0 if lado_z > 0 else yz1, zc)),
                       Vector((xb_ - 0.01, top, zz1 if lado_z > 0 else zz0)),
                       Vector((xa_ + 0.01, top, zz1 if lado_z > 0 else zz0))]
                if normal_de(pts).y < 0:
                    pts.reverse()
                M.cara(pts, "tablazon", c)
                # la junta embreada entre tablas
                M.cara([p + Vector((0, -0.01, 0)) for p in pts], "tablazon", BREA)
            caja_mm(M, (min(xw, xb) - 0.3, alto_c - 0.04, zc - 0.1), (max(xw, xb) + 0.3, alto_c + 0.1, zc + 0.1),
                    "blanqueada", BLANQUEADA[0])
        # el parche de lona embreada sobre el tejado del sur, sujeto con dos piedras
        pc = Vector(((xw + xb) * 0.5 + hacia * 0.3, top + 0.42, zc + 0.75))
        lona_curva(M, pc + Vector((-0.7, 0.3, -0.5)), pc + Vector((0.7, 0.3, -0.5)), pc + Vector((-0.7, -0.05, 0.6)),
                   pc + Vector((0.7, -0.05, 0.6)), 2, 2, -0.02, lambda i, j: jit(mezcla(BREA, LONA, 0.35), 0.05))
    estufa(M, xb + hacia * 0.7, top, zi + 0.6, 1.2 + rng.uniform(0, 0.5))
    ancla_choque(min(xw, xb), zi, max(xw, xb), zf, alto + 1.0, y)
    if piso:                                             # un cuarto colgado más arriba, contra la costilla
        y2 = top + 1.25
        xa_, xb_ = (xb, xb + hacia * 2.2) if hacia > 0 else (xb + hacia * 2.2, xb)
        xa_, xb_ = min(xa_, xb_), max(xa_, xb_)
        tablas_pared(M, xa_, zf - 0.5, xb_, zf - 0.5, y2, y2 + 1.9, (0, 0, 1), mezcla(base_c, BLANQUEADA[1], 0.35),
                     semilla + 7)
        caja_mm(M, (xa_, y2 - 0.12, zi + 0.4), (xb_, y2, zf - 0.4), "tablazon", mezcla(TABLA[0], BREA, 0.2))
        caja_mm(M, (xa_ - 0.15, y2 + 1.9, zi + 0.25), (xb_ + 0.15, y2 + 2.02, zf - 0.25), "lona",
                jit(mezcla(LONA, REMIENDO2, 0.35), 0.04))
        caja_mm(M, (xa_ + 0.02, y2, zi + 0.45), (xb_ - 0.02, y2 + 1.9, zf - 0.55), "tablazon",
                mezcla(base_c, BLANQUEADA[1], 0.35), caras="eoan")
        porta(M, ((xa_ + xb_) * 0.5, y2 + 1.05, zf - 0.46), 0.42, 0.4, (0, 0, 1), semilla + 3, abierta=False)
        for xx in (xa_ + 0.2, xb_ - 0.2):
            cabo(M, (xx, y2 + 2.0, zc), (xx, y2 + 5.2, zc), r=0.03, n=1)
        escala_gato(M, (xa_ + 0.4 if hacia > 0 else xb_ - 0.4, y2, zf - 0.3), (xa_ + 0.4 if hacia > 0 else xb_ - 0.4,
                                                                                top + 0.05, zf + 0.25), n=5)
        ancla_choque(xa_, zi + 0.4, xb_, zf - 0.4, 2.2, y2)


def ancla_choque(x0, z0, x1, z1, alto, y0, destino="fijo"):
    CHOQUES.append([destino, (x0 + x1) * 0.5, y0, (z0 + z1) * 0.5, abs(x1 - x0), abs(z1 - z0), alto])


def pasarela(M, xa, xb, zc, ancho=0.9, ya=0.0, yb=0.3):
    """La plancha de la Quilla a una puerta, sobre el agua (fuera de lo andable: no lleva choque), con su guardamano."""
    w = ancho * 0.5
    n = 3
    for i in range(n):
        z0 = zc - w + 2 * w * i / n + 0.01
        z1 = zc - w + 2 * w * (i + 1) / n - 0.01
        pts = [Vector((xa, ya - 0.005, z0)), Vector((xb, yb - 0.005, z0)), Vector((xb, yb - 0.005, z1)),
               Vector((xa, ya - 0.005, z1))]
        if normal_de(pts).y < 0:
            pts.reverse()
        M.cara(pts, "tablazon", jit(mezcla(TABLA[1], TABLA[2], RND.random()), 0.05))
    caja_mm(M, (min(xa, xb), min(ya, yb) - 0.16, zc - w), (max(xa, xb), min(ya, yb) - 0.04, zc - w + 0.08), "tablazon",
            TABLA[0])
    caja_mm(M, (min(xa, xb), min(ya, yb) - 0.16, zc + w - 0.08), (max(xa, xb), min(ya, yb) - 0.04, zc + w), "tablazon",
            TABLA[0])
    zr = zc + w
    tubo(M, (xb, yb, zr), (xb, yb + 0.85, zr), 0.035, 0.03, 5, "tablazon", TABLA[1])
    cabo(M, (xa, ya + 0.9, zr), (xb, yb + 0.82, zr), r=0.018, comba=0.08, n=3)


def casas():
    tramos = ((32.5, 37.5), (38.5, 43.5))
    n = 0
    datos = []
    for (za, zb) in tramos:
        for lado in (-1, 1):
            n += 1
            s = 11 + n if lado < 0 else 21 + n
            alto = 2.8 + random.Random(s).uniform(0, 0.5)
            if lado < 0:
                datos.append((33.0, 37.6, za + 0.3, zb - 0.3, alto, 1, s, "vela" if n == 1 else "tablas", n % 2 == 1,
                              0.6))
            else:
                porche = 1.05 if (za, zb) == (38.5, 43.5) else 0.6     # la del calafate, con más porche
                datos.append((42.4, 47.4, za + 0.3, zb - 0.3, alto, -1, s, "vela" if n == 4 else "tablas", n % 2 == 0,
                              porche))
    datos.append((34.0, 37.6, 28.9, 31.6, 2.5, 1, 41, "tablas", False, 0.0))     # chozas de la rampa
    datos.append((42.4, 46.0, 28.9, 31.6, 2.5, -1, 43, "tablas", False, 0.0))
    return datos


def kit_quilla(M):
    costilla_doble(M, 44.0, farol="farol_44")
    costilla_doble(M, 38.0, farol="farol_38", sin_farol=True)
    costilla_doble(M, 32.0, rota=(0.08, 0.17), farol="farol_32")
    for (x0, x1, z0, z1, alto, hacia, s, techo, piso, porche) in casas():
        casa_barco(M, x0, x1, z0, z1, alto, hacia, s, techo, piso and not BLOCKOUT, porche)
        if BLOCKOUT:
            continue
        zp = (z0 + z1) * 0.5 + (0.7 if s % 2 else -0.7)
        if hacia > 0 and x1 < 38.2:
            pasarela(M, 38.4, x1 + 0.1, zp, ya=altura_suelo(38.5, zp))
        elif hacia < 0 and x0 > 41.8:
            pasarela(M, 41.6, x0 - 0.1, zp, ya=altura_suelo(41.5, zp))
    if BLOCKOUT:
        return
    # las chozas de la rampa: la del este con su descansillo y la cabria (los marineros izan fardos de la laguna)
    caja_mm(M, (46.0, 0.18, 28.95), (47.5, 0.3, 31.55), "tablazon", TABLA[1])
    pilotes(M, 46.0, 28.95, 47.5, 31.55, 0.3, 1.3)
    ancla("cabria_pie", (46.9, 0.3, 30.2))
    pie = Vector((46.9, 0.3, 30.6))
    punta = Vector((48.3, 4.0, 30.2))
    tubo(M, pie, punta, 0.11, 0.07, 7, "blanqueada", jit(BLANQUEADA[1], 0.05))                    # la pluma
    tubo(M, Vector((46.7, 0.3, 29.4)), Vector((46.8, 4.2, 30.1)), 0.09, 0.07, 7, "blanqueada", BLANQUEADA[0])
    cabo(M, (46.8, 4.2, 30.1), punta, r=0.02, n=2)
    for zz in (29.0, 31.3):                                                                        # vientos
        cabo(M, (46.8, 4.15, 30.1), (46.2, 0.32, zz), r=0.015, n=2)
    caja(M, punta + Vector((0, -0.2, 0)), (0.14, 0.3, 0.14), "tablazon", TABLA[0])                # el motón
    ancla("cabria_punta", tuple(punta + Vector((0, -0.38, 0))))
    tubo(M, (46.4, 0.55, 29.6), (46.4, 0.55, 30.4), 0.12, 0.12, 8, "tablazon", TABLA[0])          # el torno
    for zz in (29.55, 30.45):
        caja(M, (46.4, 0.42, zz), (0.1, 0.26, 0.05), "tablazon", TABLA[1])
    caja_mm(M, (42.4, 0.18, 31.68), (47.5, 0.3, 32.3), "tablazon", jit(TABLA[1], 0.05))            # la repisa del sur
    pilotes(M, 42.4, 31.68, 47.5, 32.3, 0.3, 1.7)
    ancla("fardos", (42.85, 0.3, 31.98))                                                           # el montón
    # la barca de abajo (amarrada a los pilotes del descansillo)
    bx, bz = 48.6, 30.2
    for k in range(7):
        u = k / 6.0
        zz = bz - 1.5 + 3.0 * u
        semi = 0.55 * math.sin(math.pi * u) ** 0.6 + 0.04
        caja(M, (bx, NIVEL_AGUA + 0.12, zz), (semi * 2, 0.08, 0.46), "tablazon",
             jit(mezcla(PINTURAS[3], TABLA[1], 0.3), 0.05))
        for s_ in (-1, 1):
            caja(M, (bx + s_ * semi, NIVEL_AGUA + 0.32, zz), (0.06, 0.38, 0.47), "tablazon",
                 jit(PINTURAS[3] if k % 2 else mezcla(PINTURAS[3], (1, 1, 1), 0.2), 0.05))
    cabo(M, (bx, NIVEL_AGUA + 0.5, bz - 1.4), (47.4, 0.2, 29.2), r=0.018, comba=0.2, n=4)
    ancla("barca", (bx, NIVEL_AGUA + 0.2, bz))
    # el banco de la carpintera junto a la costilla 32 (al oeste de la pasarela, fuera de lo andable)
    caja_mm(M, (36.7, 0.18, 31.62), (38.2, 0.3, 32.9), "tablazon", TABLA[2])
    pilotes(M, 36.7, 31.62, 38.2, 32.9, 0.3, 1.2)
    for xx in (36.95, 37.95):                                                                       # caballetes
        for zz in (31.85, 32.65):
            viga(M, (xx, 0.3, zz), (xx + (0.12 if xx < 37.4 else -0.12), 1.0, zz), 0.07, 0.07, "tablazon", TABLA[0])
    caja_mm(M, (36.85, 1.0, 31.75), (38.05, 1.08, 32.75), "tablazon", jit(TABLA[2], 0.04))
    ancla("banco_carpintera", (37.45, 0.3, 32.2))
    ancla("tablones", (37.0, 0.3, 32.6))
    # tendederos de lado a lado de la Quilla, entre los pisos altos: camisas, sábanas y una vela pequeña
    for z, ya, yb in ((35.2, 4.6, 4.4), (41.0, 4.5, 4.7)):
        a, b = Vector((37.4, ya, z)), Vector((42.6, yb, z + 0.25))
        cabo(M, a, b, r=0.014, comba=0.4, n=8)
        k = 0
        t = 0.08
        while t < 0.92:
            w = RND.uniform(0.35, 0.75)
            h = RND.uniform(0.5, 0.95)
            p = a.lerp(b, t) - Vector((0, 0.4 * math.sin(math.pi * t), 0))
            c = jit(ROPA[(k + int(z)) % len(ROPA)], 0.06)
            pts = [Vector((p.x - w / 2, p.y, p.z)), Vector((p.x + w / 2, p.y, p.z)), Vector((p.x + w / 2, p.y - h, p.z + 0.03)),
                   Vector((p.x - w / 2, p.y - h, p.z + 0.03))]
            if normal_de(pts).z < 0:
                pts.reverse()
            M.cara(pts, "lona", c)
            M.cara(list(reversed([q + Vector((0, 0, -0.005)) for q in pts])), "lona", mezcla(c, (0, 0, 0), 0.15))
            for s_ in (-0.4, 0.4):
                caja(M, p + Vector((s_ * w, 0.02, 0)), (0.025, 0.07, 0.025), "tablazon", TABLA[2])
            t += (w + RND.uniform(0.1, 0.3)) / (b - a).length
            k += 1


def atrezo_quilla(M):
    """Lo cotidiano: barriles, cajones, rollos de cabo, nasas, cubos, la olla de brea del calafate, redes colgadas."""
    def barril(x, y, z, r=0.26, h=0.62):
        tubo(M, (x, y, z), (x, y + h, z), r * 0.92, r * 0.92, 9, "tablazon", jit(TABLA[1], 0.08))
        for yy in (0.12, h - 0.12):
            tubo(M, (x, y + yy - 0.03, z), (x, y + yy + 0.03, z), r * 0.96, r * 0.96, 9, "hierro", OXIDO, False, False)

    def rollo(x, y, z, r=0.3):
        for k in range(3):
            tubo(M, (x, y + 0.06 * k, z), (x, y + 0.06 * k + 0.06, z), r - 0.07 * k, r - 0.07 * k, 10, "cabo",
                 jit(mezcla(CABO, BREA, 0.25), 0.06), tapa_a=False)

    def cajon(x, y, z, s=(0.6, 0.45, 0.5)):
        caja(M, (x, y + s[1] * 0.5, z), s, "tablazon", jit(mezcla(TABLA[2], (0.8, 0.7, 0.5), 0.2), 0.06))
        for dy in (0.08, s[1] - 0.08):
            caja(M, (x, y + dy, z + s[2] * 0.5 + 0.005), (s[0] + 0.01, 0.06, 0.01), "tablazon", TABLA[0])

    def nasa(x, y, z):
        tubo(M, (x - 0.35, y + 0.22, z), (x + 0.35, y + 0.22, z), 0.2, 0.12, 8, "cabo", mezcla(CABO, BREA, 0.15))

    # casas del oeste (z 32,8-37,2 y 38,8-43,2; plataforma hasta x 37,7) y del este
    barril(37.25, 0.3, 33.3)
    rollo(37.2, 0.3, 36.8)
    cajon(37.15, 0.3, 39.3)
    nasa(37.1, 0.3, 42.7)
    rollo(42.9, 0.3, 33.4)
    barril(42.85, 0.3, 36.9, 0.24, 0.58)
    cajon(46.6, 0.3, 29.5, (0.55, 0.4, 0.45))
    # la olla de brea del calafate (porche de la casa del este 2) y la estopa
    ox, oz = 42.85, 42.75
    tubo(M, (ox, 0.3, oz), (ox, 0.62, oz), 0.22, 0.24, 10, "hierro", mezcla(BREA, OXIDO, 0.3))
    tubo(M, (ox, 0.62, oz), (ox, 0.64, oz), 0.2, 0.2, 10, "hierro", BREA, tapa_a=False)
    caja(M, (ox, 0.33, oz), (0.3, 0.06, 0.3), "liso", (0.9, 0.5, 0.2))                         # las brasas
    ancla("olla_brea", (ox, 0.3, oz))
    caja(M, (42.75, 0.36, 42.15), (0.32, 0.12, 0.24), "cabo", mezcla(CABO, (0.9, 0.85, 0.7), 0.4))
    ancla("costura", (43.0, 0.3, 40.2))
    # tablones de la carpintera
    for k in range(4):
        caja(M, (37.0, 0.36 + 0.07 * k, 32.6), (0.28, 0.06, 1.7 - 0.15 * k), "tablazon",
             jit(mezcla(TABLA[2], BLANQUEADA[0], 0.4), 0.05))
    # redes secándose en las barandillas de las pasarelas y un salabardo
    for (x, z) in ((37.9, 34.2), (42.1, 42.3)):
        for k in range(4):
            pts = [Vector((x - 0.02 * k, 0.9 - 0.05 * k, z - 0.4 + 0.2 * k)), Vector((x - 0.02 * k, 0.9 - 0.05 * k,
                                                                                      z + 0.4)),
                   Vector((x + 0.03, 0.2, z + 0.45)), Vector((x + 0.03, 0.2, z - 0.35 + 0.2 * k))]
            if normal_de(pts).x < 0:
                pts.reverse()
            M.cara(pts, "cabo", jit(mezcla(CABO, BREA, 0.45), 0.08))


# ================================================================= 3. texturas pintadas por código (512², repetibles)

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
    """Sin color propio (el color lo pone el tinte): solo dibujo. La veta y las costuras, a lo largo de V."""
    n = 512
    rng = np.random.default_rng(44)
    out = {}
    rgb = lambda v, t=(1, 1, 1): np.stack([v * t[0], v * t[1], v * t[2]], -1)
    yy, xx = np.mgrid[0:n, 0:n]
    # tablazón: madera curtida con veta, nudos, manchas de brea y cabezas de clavo (dos por tabla y metro)
    veta = fbm(n, 6, 3, rng, ax=9.0)
    v = 0.90 + 0.08 * np.sin(veta * 38.0) + 0.08 * (fbm(n, 4, 3, rng) - 0.5)
    v -= 0.16 * np.clip(fbm(n, 5, 3, rng) - 0.62, 0, 1) * 4.0                       # brea corrida
    v -= 0.10 * (np.abs(np.sin(_ruido(n, 48, 3, rng) * 26)) < 0.04)               # grietas
    for k in range(40):
        cx, cy = rng.integers(0, n), rng.integers(0, n)
        d = np.sqrt(((xx - cx + n // 2) % n - n // 2) ** 2 + ((yy - cy + n // 2) % n - n // 2) ** 2)
        v = np.where(d < 3.2, 0.42, np.where(d < 5.0, v * 0.86, v))
    out["tablazon"] = rgb(v + 0.03 * (rng.random((n, n)) - 0.5), (1.0, 0.97, 0.93))
    # blanqueada: madera lavada por la sal, veta clara abierta, costra de sal y vetas grises
    veta = fbm(n, 5, 3, rng, ax=7.0)
    v = 0.86 + 0.06 * np.sin(veta * 30.0) + 0.06 * (fbm(n, 3, 3, rng) - 0.5)
    v -= 0.12 * (np.abs(np.sin(_ruido(n, 40, 2, rng) * 22)) < 0.035)
    sal = np.clip(fbm(n, 10, 3, rng) - 0.6, 0, 1) * 2.0
    out["blanqueada"] = rgb(np.clip(v + 0.08 * sal, 0, 1), (1.0, 0.985, 0.96))
    # lona: trama, dos costuras por baldosa (cada 0,9 m) con su pespunte, y manchas de humedad
    trama = 0.92 + 0.035 * np.sin(xx * 1.9) * np.sin(yy * 1.9)
    u = (xx / n * 2.0) % 1.0
    costura = (np.abs(u - 0.5) < 0.012) * 0.16 + (np.abs(u - 0.47) < 0.004) * 0.08 + (np.abs(u - 0.53) < 0.004) * 0.08
    pespunte = ((np.abs(u - 0.5) < 0.02) & ((yy // 6) % 2 == 0)) * 0.05
    humedad = np.clip(fbm(n, 4, 3, rng) - 0.58, 0, 1) * 0.6
    out["lona"] = rgb(trama - costura - pespunte - humedad + 0.05 * (fbm(n, 12, 3, rng) - 0.5), (1.0, 0.99, 0.96))
    # hierro: óxido moteado, picaduras y chorretones
    v = 0.88 + 0.14 * (fbm(n, 6, 4, rng) - 0.5) + 0.06 * (rng.random((n, n)) - 0.5)
    pic = rng.random((n, n)) < 0.012
    v[pic] *= 0.6
    out["hierro"] = rgb(v, (1.0, 0.92, 0.84))
    # cabo: torcido (franjas en diagonal) y fibras
    v = 0.90 + 0.10 * np.sin((xx + yy * 1.2) / n * math.pi * 2 * 14) + 0.05 * (fbm(n, 16, 2, rng) - 0.5)
    out["cabo"] = rgb(v, (1.0, 0.97, 0.9))
    # liso: un grano suave (para lo que no es madera ni lona)
    out["liso"] = rgb(0.94 + 0.08 * (fbm(n, 8, 3, rng) - 0.5) + 0.03 * (rng.random((n, n)) - 0.5))
    imgs = {}
    for k, t in out.items():
        imgs[k] = guardar_tex(k, t, carpeta)
    return imgs


# ================================================================= 4. de las listas a Blender

def a_blender(nombre, caras, mats, con_luz_uv, soldar=True):
    verts, polys, cols, uvs, suaves, mi = [], [], [], [], [], []
    for pts, mat, cs, uv, suave, _d in caras:
        base = len(verts)
        for p in pts:
            verts.append((p.x, -p.z, p.y))
        polys.append(list(range(base, base + len(pts))))
        cols.extend(cs)
        uvs.extend(uv if uv is not None else uv_cara(pts, mat))
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
    if soldar:
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
            bsdf.inputs["Emission Strength"].default_value = 1.5
        elif imgs:
            tex = nt.nodes.new("ShaderNodeTexImage")
            tex.image = imgs[m]
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


# ================================================================= 5. horneado

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
    bg.inputs["Strength"].default_value = 1.0
    sd = bpy.data.lights.new("Sol", 'SUN')
    sd.energy = 1.0
    sd.color = SOL_COLOR
    sd.angle = math.radians(1.4)
    so = bpy.data.objects.new("Sol", sd)
    hs = HACIA_SOL
    so.rotation_euler = Vector((hs.x, -hs.z, hs.y)).to_track_quat('Z', 'Y').to_euler()
    sc.collection.objects.link(so)
    return bg, sd


def placa(nombre, c, nrm):
    me = bpy.data.meshes.new(nombre)
    nrm = Vector(nrm).normalized()
    t1 = nrm.cross(Vector((0, 1, 0)) if abs(nrm.y) < 0.9 else Vector((1, 0, 0))).normalized()
    t2 = nrm.cross(t1).normalized()
    c = Vector(c)
    pts = [c - t1 - t2, c + t1 - t2, c + t1 + t2, c - t1 + t2]
    if (pts[1] - pts[0]).cross(pts[2] - pts[0]).dot(nrm) < 0:
        pts.reverse()
    me.from_pydata([(p.x, -p.z, p.y) for p in pts], [], [[0, 1, 2, 3]])
    me.uv_layers.new(name="UVMap")
    uv = me.uv_layers.new(name="luz")
    uv.data.foreach_set("uv", [0.1, 0.1, 0.9, 0.1, 0.9, 0.9, 0.1, 0.9])
    me.uv_layers.active = uv
    img = bpy.data.images.new(nombre, 16, 16, float_buffer=True)
    mt = bpy.data.materials.new(nombre)
    mt.use_nodes = True
    tn = mt.node_tree.nodes.new("ShaderNodeTexImage")
    tn.image = img
    mt.node_tree.nodes.active = tn
    me.materials.append(mt)
    ob = bpy.data.objects.new(nombre, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob, img


def hornear_placa(ob, img):
    bpy.ops.object.select_all(action='DESELECT')
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.bake(type='DIFFUSE', pass_filter={'DIRECT', 'INDIRECT'}, margin=0, target='IMAGE_TEXTURES',
                        use_clear=True)
    px = np.array(img.pixels[:], np.float32).reshape(16, 16, 4)
    return px[4:12, 4:12, :3].reshape(-1, 3).mean(0)


def calibrar(bg, sd):
    """Fuerza del sol y del cielo de Cycles para que una placa horizontal reciba lo mismo que en la escena de Godot
    (sol: energía × N·L × color; ambiente: color × energía). Dos horneados de una placa lejana: solo sol y solo cielo."""
    ob, img = placa("cal_suelo", (900.0, 200.0, 0.0), (0, 1, 0))
    luces = [o for o in bpy.context.scene.objects if o.type == 'LIGHT']
    bg.inputs["Strength"].default_value = 0.0
    sd.energy = 1.0
    m_sol = hornear_placa(ob, img)
    bg.inputs["Strength"].default_value = 1.0
    sd.energy = 0.0
    m_cielo = hornear_placa(ob, img)
    bpy.data.objects.remove(ob)
    nl = max(0.05, HACIA_SOL.y)
    k_sol = float(m_sol[0]) / (SOL_COLOR[0] * nl)            # lo que da una fuerza 1 (por unidad de N·L y color)
    k_cielo = float(m_cielo[2]) / CIELO_COLOR[2]
    fuerza_sol = SOL_GODOT * SOL_EXTRA / max(k_sol, 1e-6)
    fuerza_cielo = CIELO_GODOT * CIELO_EXTRA / max(k_cielo, 1e-6)
    sd.energy = fuerza_sol
    bg.inputs["Strength"].default_value = fuerza_cielo
    nota("calibración: sol 1 → %.3f (N·L %.2f) · cielo 1 → %.3f · fuerzas: sol %.3f, cielo %.3f" % (
        m_sol[0], nl, m_cielo[2], fuerza_sol, fuerza_cielo))
    return {"k_sol": k_sol, "k_cielo": k_cielo, "fuerza_sol": fuerza_sol, "fuerza_cielo": fuerza_cielo}


def escena_horneado(anclas):
    """Lo que solo existe para el horneado: la laguna (rebote turquesa), la orilla y la luz de los faroles."""
    me = bpy.data.meshes.new("agua_horneado")
    c, sx, sz = Vector((40.0, NIVEL_AGUA, 32.0)), 130.0, 110.0
    pts = [(c.x - sx, c.y, c.z - sz), (c.x - sx, c.y, c.z + sz), (c.x + sx, c.y, c.z + sz), (c.x + sx, c.y, c.z - sz)]
    me.from_pydata([(p[0], -p[2], p[1]) for p in pts], [], [[0, 1, 2, 3]])
    mt = bpy.data.materials.new("agua_horneado")
    mt.use_nodes = True
    b = mt.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*AGUA_ALBEDO, 1.0)
    b.inputs["Roughness"].default_value = 1.0
    me.materials.append(mt)
    ob = bpy.data.objects.new("agua_horneado", me)
    bpy.context.scene.collection.objects.link(ob)
    luces = 0
    for k, p in anclas.items():
        if not (k.startswith("farol_") and k != "farol_38") and k != "farol_archivo":
            continue
        ld = bpy.data.lights.new(k, 'POINT')
        ld.energy = 55.0 if k in ("farol_44", "farol_32") else (25.0 if k == "farol_archivo" else 40.0)
        ld.color = LUZ_FAROL
        ld.shadow_soft_size = 0.1
        lo = bpy.data.objects.new(k + "_luz", ld)
        lo.location = (p[0], -p[2], p[1] - 0.05)
        bpy.context.scene.collection.objects.link(lo)
        luces += 1
    nota("escena de horneado: laguna y %d faroles (sin el de la costilla 38)" % luces)
    return ob


def uv_luz(ob, importancia):
    """UV del mapa de luz: proyección por ángulos y empaquetado. Lo de la Quilla (importancia) pesa más en el mapa
    que lo lejano (la proa, el dique)."""
    me = ob.data
    me.uv_layers.active = me.uv_layers["luz"]
    bpy.ops.object.select_all(action='DESELECT')
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(55), island_margin=0.002, area_weight=0.0, correct_aspect=True,
                             scale_to_bounds=False)
    bpy.ops.object.mode_set(mode='OBJECT')
    # escala de cada isla según dónde está (islas: caras unidas por esquinas con el mismo vértice y la misma UV)
    bm = bmesh.new()
    bm.from_mesh(me)
    capa = bm.loops.layers.uv["luz"]
    bm.faces.ensure_lookup_table()
    padre = list(range(len(bm.faces)))

    def raiz(i):
        while padre[i] != i:
            padre[i] = padre[padre[i]]
            i = padre[i]
        return i
    vistos = {}
    for f in bm.faces:
        for l in f.loops:
            k = (l.vert.index, round(l[capa].uv.x, 5), round(l[capa].uv.y, 5))
            if k in vistos:
                a, b = raiz(vistos[k]), raiz(f.index)
                if a != b:
                    padre[a] = b
            else:
                vistos[k] = f.index
    islas = {}
    for f in bm.faces:
        islas.setdefault(raiz(f.index), []).append(f)
    for isla in islas.values():
        c = sum((g.calc_center_median() for g in isla), Vector((0, 0, 0))) / len(isla)
        k = importancia(Vector((c.x, c.z, -c.y)))
        if abs(k - 1.0) < 1e-3:
            continue
        uvs = [l[capa].uv.copy() for g in isla for l in g.loops]
        m = sum(uvs, Vector((0, 0))) / len(uvs)
        for g in isla:
            for l in g.loops:
                l[capa].uv = m + (l[capa].uv - m) * k
    bm.to_mesh(me)
    bm.free()
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    try:
        bpy.ops.uv.pack_islands(udim_source='CLOSEST_UDIM', rotate=True, scale=True, margin=0.0015)
    except Exception as e:
        nota("pack_islands: %s" % e)
    bpy.ops.object.mode_set(mode='OBJECT')
    nota("UV del mapa de luz hechas")


def importancia(p):
    """Densidad del mapa de luz por zonas: la Quilla y lo que se ve desde ella, el doble; lo lejano, menos."""
    if 30.0 <= p.x <= 50.0 and 27.0 <= p.z <= 46.0:
        return 1.45
    if p.z < 17.0 or p.x > 56.0 or p.y < NIVEL_AGUA - 0.2:
        return 0.55
    return 1.0


def hornear(ob_fijo, objs_vertice, img):
    bpy.ops.object.select_all(action='DESELECT')
    ob_fijo.select_set(True)
    bpy.context.view_layer.objects.active = ob_fijo
    sc = bpy.context.scene
    sc.render.bake.margin = 6
    sc.render.bake.margin_type = 'EXTEND'
    bpy.ops.object.bake(type='DIFFUSE', pass_filter={'DIRECT', 'INDIRECT'}, margin=6, target='IMAGE_TEXTURES',
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
    nota("piezas, coronas y lo que se vuelve transparente: horneados a los vértices")


def escala_y_guardar(img, carpeta_luz, objs_vertice):
    w, h = img.size
    px = np.array(img.pixels[:], np.float32).reshape(h, w, 4)
    lum = px[..., :3].max(-1)
    validos = lum[lum > 0.0005]
    escala = float(np.percentile(validos, 99.7)) / 0.97 if validos.size else 1.0
    for res in (w, w // 2):
        nombre = "quilla_luz_%d" % res
        q = np.clip(px[..., :3] / escala, 0, 1) ** (1 / 2.2)
        im2 = bpy.data.images.new(nombre, w, h, alpha=False)
        a = np.ones((h, w, 4), np.float32)
        a[..., :3] = q
        im2.pixels.foreach_set(a.ravel())
        if res != w:
            im2.scale(res, res)
        im2.filepath_raw = os.path.join(carpeta_luz, nombre + ".png")
        im2.file_format = 'PNG'
        im2.save()
    for ob in objs_vertice:                               # tinte × luz / escala (lo que da luz, sin multiplicar)
        vm = ob.data
        col, luz = vm.color_attributes["Col"], vm.color_attributes["LuzV"]
        n = len(col.data)
        c = np.zeros(n * 4, np.float32)
        l = np.zeros(n * 4, np.float32)
        col.data.foreach_get("color", c)
        luz.data.foreach_get("color", l)
        c = c.reshape(n, 4)
        l = l.reshape(n, 4)
        idx_brillo = MATS.index("brillo")
        mat_pol = np.zeros(len(vm.polygons), np.int32)
        vm.polygons.foreach_get("material_index", mat_pol)
        mat_esq = np.zeros(len(vm.loops), np.int32)
        for p in vm.polygons:
            mat_esq[p.loop_start:p.loop_start + p.loop_total] = mat_pol[p.index]
        l[mat_esq == idx_brillo, :3] = escala
        # (los que se vuelven transparentes llevan un material estándar sin luz y sin «luz_escala»: sin dividir)
        div = 1.0 if ob.name in FANTASMAS else escala
        c[:, :3] = np.clip(c[:, :3] * l[:, :3] / div, 0, 1)
        col.data.foreach_set("color", c.ravel())
        vm.color_attributes.remove(luz)
        vm.color_attributes.active_color = vm.color_attributes["Col"]
    return escala


def altura_suelo(x, z):
    if RAMPA[0] <= x <= RAMPA[2] and RAMPA[1] <= z <= RAMPA[3]:
        return ALTO_CUBIERTA * max(0.0, min(1.0, (RAMPA[3] - z) / (RAMPA[3] - RAMPA[1])))
    if 30.0 <= x <= 50.0 and 18.6 <= z <= 28.8 or 50.0 <= x <= 54.6 and 21.0 <= z <= 25.6:
        return ALTO_CUBIERTA
    if 46.4 <= x <= 49.8 and 44.6 <= z <= 46.6:
        return 0.8 * max(0.0, min(1.0, (x - 46.4) / 2.2))
    if 49.6 <= x <= 55.8 and 42.0 <= z <= 47.8:
        return 0.8
    return 0.0


def sondas(bvh):
    """Cuánto sol y cuánto cielo llega a 1 m sobre lo que se pisa (rejilla de 0,5 m sobre todo el sector)."""
    x0, x1, z0, z1, paso = 29.5, 56.0, 18.0, 61.0, 0.5
    nx, nz = int((x1 - x0) / paso) + 1, int((z1 - z0) / paso) + 1
    hs = HACIA_SOL
    dirs_cielo = []
    for k in range(24):
        u, v = (k + 0.5) / 24, (k * 0.618034) % 1.0
        r = math.sqrt(u)
        a = math.tau * v
        dirs_cielo.append(Vector((r * math.cos(a), math.sqrt(1 - u), r * math.sin(a))))
    t1 = hs.cross(Vector((0, 1, 0))).normalized()
    t2 = hs.cross(t1).normalized()
    rad = math.tan(math.radians(1.4) * 0.5)
    dirs_sol = [(hs + t1 * rad * math.cos(k * 1.3) * (k / 7) + t2 * rad * math.sin(k * 1.3) * (k / 7)).normalized()
                for k in range(8)]
    sol, cielo = [], []
    for j in range(nz):
        for i in range(nx):
            x, z = x0 + i * paso, z0 + j * paso
            dentro = any(a <= x <= c and b <= z <= d for (a, b, c, d) in ANDABLE)
            if not dentro:
                sol.append(1.0)
                cielo.append(1.0)
                continue
            pb = Vector((x, -z, altura_suelo(x, z) + 1.0))
            s = sum(1 for d in dirs_sol if bvh.ray_cast(pb, Vector((d.x, -d.z, d.y)), 200.0)[0] is None)
            c = sum(1 for d in dirs_cielo if bvh.ray_cast(pb, Vector((d.x, -d.z, d.y)), 60.0)[0] is None)
            sol.append(round(s / len(dirs_sol), 3))
            cielo.append(round(c / len(dirs_cielo), 3))
    return {"origen": [x0, z0], "paso": paso, "nx": nx, "nz": nz, "altura": 1.0, "sol": sol, "cielo": cielo}


def vacios(choques, anclas, padres):
    objs = []
    for k, (dest, x, y0, z, w, d, h) in enumerate(choques):
        e = bpy.data.objects.new("caja_%d_%d_%d_%d_%d" % (k, round(w * 100), round(d * 100), round(h * 100),
                                                         round(y0 * 100)), None)
        e.empty_display_type = 'CUBE'
        e.location = (x, -z, y0)
        par = padres.get(dest) or padres.get("fijo")
        bpy.context.scene.collection.objects.link(e)
        e.parent = par
        objs.append(e)
    for k, p in anclas.items():
        e = bpy.data.objects.new("ancla_" + k, None)
        e.location = (p[0], -p[2], p[1])
        bpy.context.scene.collection.objects.link(e)
        objs.append(e)
    return objs


def exportar(objs, ruta):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=ruta, export_format='GLB', use_selection=True, export_animations=False,
                              export_yup=True, export_vertex_color='ACTIVE', export_all_vertex_colors=False,
                              export_cameras=False, export_lights=False, export_apply=True, export_texcoords=True,
                              export_normals=True, export_image_format='NONE', export_materials='EXPORT')
    nota("EXPORTADO %s" % ruta)


# ================================================================= main

def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    carpeta_mod = os.path.join(CARPETA, "modelos") if CARPETA else ""
    carpeta_tex = os.path.join(CARPETA, "texturas") if CARPETA else ""
    carpeta_luz = os.path.join(CARPETA, "luz") if CARPETA else ""
    for c in (carpeta_mod, carpeta_tex, carpeta_luz):
        if c:
            os.makedirs(c, exist_ok=True)
    S = cargar_sunken()
    M = Malla()
    choques, anclas = sector_de_siempre(S, M)
    nota("sector de siempre: %d triángulos fuera de la Quilla, %d choques, %d anclas" % (M.tris(), len(choques),
                                                                                        len(anclas)))
    RND.seed(4402)
    K = Malla()
    kit_quilla(K)
    if ATREZO:
        atrezo_quilla(K)
    nota("kit de la Quilla: %d triángulos, %d choques" % (K.tris(), len(CHOQUES)))
    anclas.update(ANCLAS)
    choques += CHOQUES
    # el reparto: lo grande al mapa de luz; lo pequeño, a los vértices; lo que no ve ninguna cámara (caras hacia
    # abajo o hacia el norte: la cámara siempre está al sur y por encima), solo al horneado
    fijo, piezas, oculto = [], [], []
    otros = {}
    for cara in M.caras + K.caras:
        pts, mat, _c, _u, _s, dest = cara
        n = normal_de(pts)
        if n.y < -0.55 or (n.z < -0.6 and abs(n.y) < 0.6 and mat not in ("lona",)):
            if dest is None or not dest.startswith("corona_"):
                oculto.append(cara)
                continue
        if dest is not None:
            otros.setdefault(dest, []).append(cara)
        elif mat != "brillo" and area_de(pts) >= 0.12:
            fijo.append(cara)
        else:
            piezas.append(cara)
    imgs = texturas(carpeta_tex) if TEXTURAS else None
    img_luz = bpy.data.images.new("quilla_luz", RES, RES, alpha=False, float_buffer=True) if HORNEAR else None
    mats = materiales(imgs, img_luz)
    ob_fijo = a_blender("fijo", fijo, mats, HORNEAR)
    ob_pie = a_blender("piezas", piezas, mats, False)
    ob_otros = {k: a_blender(k, v, mats, False) for k, v in sorted(otros.items())}
    ob_ocu = a_blender("oculto", oculto, mats, False) if oculto else None
    tri = lambda c: sum(len(x[0]) - 2 for x in c)
    datos = {"fase": FASE, "horneado": HORNEAR, "texturas": TEXTURAS, "tris_fijo": tri(fijo), "tris_piezas": tri(piezas),
             "tris_otros": {k: tri(v) for k, v in otros.items()}, "tris_oculto": tri(oculto)}
    nota("reparto: %s" % json.dumps(datos))
    if HORNEAR:
        bg, sd = preparar_cycles()
        cal = calibrar(bg, sd)
        agua = escena_horneado(anclas)
        uv_luz(ob_fijo, importancia)
        hornear(ob_fijo, [ob_pie] + list(ob_otros.values()), img_luz)
        escala = escala_y_guardar(img_luz, carpeta_luz, [ob_pie] + list(ob_otros.values()))
        objs = [o for o in [ob_fijo, ob_pie, ob_ocu] + list(ob_otros.values()) if o is not None]
        dg = bpy.context.evaluated_depsgraph_get()
        vs, ps = [], []
        for o in objs:
            m = o.evaluated_get(dg).data
            b = len(vs)
            vs.extend([o.matrix_world @ v.co for v in m.vertices])
            ps.extend([[b + i for i in p.vertices] for p in m.polygons])
        bvh = BVHTree.FromPolygons(vs, ps)
        datos.update({"escala": escala, "res": [RES, RES // 2], "hacia_sol": [HACIA_SOL.x, HACIA_SOL.y, HACIA_SOL.z],
                      "calibracion": cal, "muestras": MUESTRAS, "sondas": sondas(bvh)})
        nota("sondas: %d × %d" % (datos["sondas"]["nx"], datos["sondas"]["nz"]))
        bpy.data.objects.remove(agua)
    elif carpeta_luz:
        for f in os.listdir(carpeta_luz):
            if f.startswith("quilla_luz_") and f.endswith(".png"):
                os.remove(os.path.join(carpeta_luz, f))
    if carpeta_mod:
        padres = {"fijo": ob_fijo}
        padres.update(ob_otros)
        exportar([ob_fijo, ob_pie] + list(ob_otros.values()) + vacios(choques, anclas, padres),
                 os.path.join(carpeta_mod, "quilla.glb"))
        with open(os.path.join(carpeta_luz, "quilla_luz.json"), "w", encoding="utf-8") as f:
            json.dump(datos, f)
    nota("HECHO %s" % json.dumps({k: v for k, v in datos.items() if k != "sondas"}))


main()
