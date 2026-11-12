# Héroes v3 (V12): cara PROPIA de los protagonistas: atlas de ojos y bocas dibujado por código (numpy, sin imágenes
# de nadie) y una malla «cara_v3» proyectada sobre la cabeza nueva (ojos, boca, cejas y marca).
#
# Atlas de 1024 × 768 (la fila de abajo, fija):
#   - ojos: 8 losetas de 256 × 256 (2 filas de 4) en el orden de heroe_v2_ayudante.gd EXPRESIONES:
#     normal, cerrados, sonrisa, dolor, grito, sorpresa, entrecerrados, decidido. Se dibuja el ojo DERECHO del personaje
#     (rabillo a la izquierda de la loseta); el izquierdo usa la misma loseta en espejo.
#   - bocas: 8 losetas de 128 × 128 en la fila y = 512..640, mismo orden.
#   - fila fija y = 640..768: la marca de la mejilla (x 0..128), el color de las cejas (128..256).
# La malla lleva en el color por vértice qué es cada parte (R = ojo, G = boca, B = fijo); el sombreador del juego
# (heroe_v3_cara.gdshader) desplaza las UV de ojos y bocas a la loseta de la expresión. Las cejas son geometría con
# formas clave (arriba, enfado, triste) que el juego mezcla.
import math, os
import numpy as np
import bpy, bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree

W, H_AT = 1024, 768
T_OJO = 256
T_BOCA = 128
FILA_BOCA = 512
FILA_FIJA = 640
EXPRESIONES = ["normal", "cerrados", "sonrisa", "dolor", "grito", "sorpresa", "entrecerrados", "decidido"]


# ------------------------------------------------------------------ dibujo (coordenadas -1..1, Y hacia arriba)
def _rejilla(n):
    c = (np.arange(n) + 0.5) / n * 2 - 1
    X, Y = np.meshgrid(c, -c)
    return X, Y


def _paso(d, px):
    """Cobertura suave de un borde con distancia con signo d (negativo dentro), px = ancho de un píxel."""
    return np.clip(0.5 - d / px, 0.0, 1.0)


def _sobre(lienzo, color, alfa):
    a = alfa[..., None]
    lienzo[..., :3] = lienzo[..., :3] * (1 - a) + np.array(color, dtype=np.float32) * a
    lienzo[..., 3:4] = lienzo[..., 3:4] * (1 - a) + a


def _dist_polilinea(X, Y, pts):
    d = np.full(X.shape, 1e9, dtype=np.float32)
    for (x0, y0), (x1, y1) in zip(pts[:-1], pts[1:]):
        dx, dy = x1 - x0, y1 - y0
        L2 = dx * dx + dy * dy + 1e-12
        t = np.clip(((X - x0) * dx + (Y - y0) * dy) / L2, 0, 1)
        d = np.minimum(d, np.hypot(X - (x0 + t * dx), Y - (y0 + t * dy)))
    return d


def _trazo(lienzo, X, Y, pts, grosor, color, px, alfa=1.0, afilar=True):
    """Trazo de pincel: más grueso en el centro y afilado en los extremos."""
    pts = list(pts)
    d = np.full(X.shape, 1e9, dtype=np.float32)
    n = len(pts)
    for k, ((x0, y0), (x1, y1)) in enumerate(zip(pts[:-1], pts[1:])):
        dx, dy = x1 - x0, y1 - y0
        L2 = dx * dx + dy * dy + 1e-12
        t = np.clip(((X - x0) * dx + (Y - y0) * dy) / L2, 0, 1)
        s = (k + t) / (n - 1)
        g = grosor * (np.sin(np.pi * np.clip(s, 0, 1)) ** 0.45 if afilar else 1.0) * 0.5
        dist = np.hypot(X - (x0 + t * dx), Y - (y0 + t * dy)) - g
        d = np.minimum(d, dist)
    _sobre(lienzo, color, _paso(d, px) * alfa)


def _curva(f, x0, x1, n=40):
    return [(x0 + (x1 - x0) * k / (n - 1), f(x0 + (x1 - x0) * k / (n - 1))) for k in range(n)]


def _forma_ojo(estilo):
    """Párpado de arriba U(x) y de abajo L(x) del ojo abierto, y sus extremos (rabillo a la izquierda)."""
    if estilo == "dulce":
        xa, xb, xm, w = -0.84, 0.78, -0.03, 0.84
        top0, top_h, incl, bot0, bot_h = 0.02, 0.66, -0.03, -0.04, 0.62
    else:     # «viva» (Kael): más baja y afilada, el párpado recto y caído hacia el lagrimal: mirada seria
        xa, xb, xm, w = -0.84, 0.74, -0.10, 0.84
        top0, top_h, incl, bot0, bot_h = 0.06, 0.46, -0.16, -0.10, 0.50

    def e(x):
        return np.clip(1 - ((x - xm) / w) ** 2, 0, 1)

    U = lambda x: top0 + top_h * e(x) ** 0.55 + incl * x
    L = lambda x: bot0 - bot_h * e(x) ** 0.85 + 0.04 * x
    return xa, xb, U, L


MARGEN_OJO = 1.14          # el dibujo ocupa 1/1,14 de la loseta: el rabillo no se corta en el borde


def _ojo_yelmo(nombre, cara, n):
    """Garon: dos brillos en la sombra de la visera; la forma cambia con la expresión (el yelmo sigue cerrado)."""
    X, Y = _rejilla(n)
    px = 2.0 / n
    lz = np.zeros((n, n, 4), dtype=np.float32)
    c0, c1 = cara["iris"]
    if nombre == "cerrados":
        return lz
    def halo(d, ancho):
        return np.clip(1 - d / ancho, 0, 1) ** 2 * 0.45
    if nombre in ("sonrisa", "dolor", "entrecerrados"):
        if nombre == "sonrisa":
            pts = _curva(lambda x: -0.10 + 0.22 * np.clip(1 - (x / 0.6) ** 2, 0, 1), -0.6, 0.6)
        elif nombre == "dolor":
            pts = [(-0.55, 0.25), (0.35, 0.0), (-0.55, -0.25)]
        else:
            pts = [(-0.55, -0.02), (0.55, -0.06)]
        d = _dist_polilinea(X, Y, pts)
        _sobre(lz, c0, halo(d, 0.45))
        _sobre(lz, c1, _paso(d - 0.07, px))
        return lz
    rx, ry, incl = 0.55, 0.20, 0.0
    if nombre == "decidido":
        ry, incl = 0.15, -0.18
    elif nombre == "grito":
        ry, incl = 0.16, -0.40
    elif nombre == "sorpresa":
        rx, ry = 0.30, 0.30
    Yr = Y - incl * X
    d = np.hypot(X / rx, Yr / ry) - 1.0
    _sobre(lz, c0, halo(np.maximum(d, 0) * ry * 2.5, 0.5))
    _sobre(lz, c1, _paso(d * min(rx, ry), px))
    _sobre(lz, (1, 1, 1), _paso((np.hypot((X + 0.12) / (rx * 0.35), (Yr - 0.04) / (ry * 0.45)) - 1) * 0.05, px) * 0.8)
    return lz


def dibujar_ojo(nombre, cara, n=T_OJO):
    if cara.get("mirada") == "yelmo":
        return _ojo_yelmo(nombre, cara, n)
    X, Y = _rejilla(n)
    X *= MARGEN_OJO
    Y *= MARGEN_OJO
    px = 2.0 * MARGEN_OJO / n
    lz = np.zeros((n, n, 4), dtype=np.float32)
    linea = cara["linea"]
    c_osc, c_cla = cara["iris"]
    xa, xb, U, L = _forma_ojo(cara.get("mirada", "viva"))
    # tamaño del iris y párpado según la expresión
    iris_r = (0.40, 0.55)
    pupila = (0.16, 0.25)
    tapa = None                         # recorte del párpado de arriba: función x -> y
    sube_abajo = 0.0
    if nombre == "decidido":
        tapa = lambda x: 0.30 - 0.16 * x
    elif nombre == "entrecerrados":
        tapa = lambda x: 0.04 - 0.06 * x
        sube_abajo = 0.08
    elif nombre == "grito":
        tapa = lambda x: 0.36 - 0.42 * x
        sube_abajo = 0.05
        pupila = (0.11, 0.17)
    elif nombre == "sorpresa":
        U0, L0 = U, L
        U = lambda x: U0(x) * 1.12 + 0.04
        L = lambda x: L0(x) * 1.08
        iris_r = (0.28, 0.38)
        pupila = (0.10, 0.14)
    if nombre in ("cerrados", "sonrisa", "dolor"):
        if nombre == "cerrados":
            pts = _curva(lambda x: -0.10 - 0.16 * np.clip(1 - ((x + 0.04) / 0.85) ** 2, 0, 1) ** 0.6 - 0.04 * x,
                         xa + 0.06, xb - 0.04)
            _trazo(lz, X, Y, pts, 0.11, linea, px)
            _trazo(lz, X, Y, [(xa + 0.08, -0.08), (xa - 0.10, 0.04)], 0.06, linea, px)     # pestaña del rabillo
        elif nombre == "sonrisa":
            pts = _curva(lambda x: -0.18 + 0.36 * np.clip(1 - ((x + 0.02) / 0.80) ** 2, 0, 1) ** 0.75, xa + 0.1, xb - 0.06)
            _trazo(lz, X, Y, pts, 0.12, linea, px)
        else:                            # dolor: «>» (en espejo, «<»), los ojos apretados
            _trazo(lz, X, Y, [(-0.62, 0.38), (0.0, 0.10), (0.44, -0.02)], 0.11, linea, px)
            _trazo(lz, X, Y, [(-0.62, -0.36), (0.0, -0.12), (0.44, -0.02)], 0.10, linea, px)
        return lz
    Ux = lambda x: np.minimum(U(x), tapa(x)) if tapa else U(x)
    Lx = lambda x: L(x) + sube_abajo * np.clip(1 - (x / 0.8) ** 2, 0, 1)
    dentro_x = np.clip(np.minimum(X - xa, xb - X) / 0.02, 0, 1)
    d_arr = Y - Ux(X)
    d_aba = Lx(X) - Y
    blanco = _paso(np.maximum(d_arr, d_aba), px) * dentro_x
    # esclerótica con la sombra del párpado (azulada)
    sombra = np.clip(1 - (-d_arr) / 0.32, 0, 1) ** 1.5
    esc = np.zeros_like(lz)
    _sobre(esc, (0.97, 0.97, 1.0), np.ones(X.shape, dtype=np.float32))
    _sobre(esc, (0.70, 0.74, 0.90), sombra * 0.8)
    # iris: degradado de arriba (oscuro) a abajo (claro), aro oscuro, media luna clara abajo y pupila
    ix, iy = 0.02, -0.06
    r = np.hypot((X - ix) / iris_r[0], (Y - iy) / iris_r[1])
    iris = _paso((r - 1.0) * iris_r[0], px)
    t = np.clip((Y - (iy - iris_r[1])) / (2 * iris_r[1]), 0, 1)
    col = np.array(c_cla)[None, None, :] * (1 - t[..., None]) + np.array(c_osc)[None, None, :] * t[..., None]
    col = col * (0.62 + 0.38 * np.clip(1 - r, 0, 1)[..., None] ** 0.3)
    _sobre(esc, (0, 0, 0), np.zeros(X.shape, dtype=np.float32))
    a_iris = iris
    esc[..., :3] = esc[..., :3] * (1 - a_iris[..., None]) + col * a_iris[..., None]
    luna = _paso((np.hypot((X - ix) / (iris_r[0] * 0.78), (Y - (iy - iris_r[1] * 0.42)) / (iris_r[1] * 0.42)) - 1) * 0.2, px)
    _sobre(esc, tuple(min(1.0, c * 1.25 + 0.12) for c in c_cla), luna * iris * 0.55)
    aro = _paso(np.abs(r - 0.95) * iris_r[0] - 0.035, px) * iris
    _sobre(esc, tuple(c * 0.45 for c in c_osc), aro * 0.9)
    pr = np.hypot((X - ix) / pupila[0], (Y - (iy + 0.02)) / pupila[1])
    _sobre(esc, tuple(c * 0.25 for c in c_osc), _paso((pr - 1) * pupila[0], px) * iris)
    # el párpado también sombrea el iris
    _sobre(esc, (0.10, 0.12, 0.25), sombra * iris * 0.45)
    # brillos
    _sobre(esc, (1, 1, 1), _paso((np.hypot((X + 0.14) / 0.14, (Y - 0.16) / 0.17) - 1) * 0.14, px) * iris)
    _sobre(esc, (1, 1, 1), _paso((np.hypot(X - 0.20, Y + 0.30) - 0.065), px) * iris * 0.85)
    _sobre(esc, (1, 1, 1), _paso((np.hypot(X - 0.22, Y - 0.10) - 0.03), px) * iris * 0.7)
    esc[..., 3] = 1.0
    lz[..., :3] = esc[..., :3]
    lz[..., 3] = blanco
    # pestañas: arriba, gruesas y con el rabillo hacia fuera; abajo, una línea fina solo en el rabillo
    grueso = lambda x: 0.075 + 0.11 * np.clip((0.3 - x) / 1.2, 0, 1)
    pts = _curva(lambda x: Ux(x) + 0.02, xa - 0.02, xb + 0.02, 60)
    d = _dist_polilinea(X, Y, pts)
    lado = Y - Ux(X)
    g = grueso(X) * np.clip((xb + 0.04 - X) / 0.25, 0.25, 1)
    pest = _paso(np.maximum(-lado - 0.015, lado - g), px) * np.clip((X - (xa - 0.16)) / 0.05, 0, 1) * \
        np.clip((xb + 0.04 - X) / 0.03, 0, 1)
    _sobre(lz, linea, pest)
    _trazo(lz, X, Y, [(xa + 0.05, Ux(xa + 0.05) + 0.05), (xa - 0.20, Ux(xa) + 0.20)], 0.07, linea, px)   # rabillo
    pts_b = _curva(lambda x: Lx(x) - 0.01, xa + 0.02, 0.15, 30)
    _trazo(lz, X, Y, pts_b, 0.045, tuple(min(1, c * 1.6 + 0.15) for c in linea), px, alfa=0.85)
    if cara.get("mirada") == "dulce":       # pliegue del párpado (Lya)
        pts_p = _curva(lambda x: U(x) + 0.17, -0.55, 0.35, 30)
        _trazo(lz, X, Y, pts_p, 0.03, linea, px, alfa=0.5)
    return lz


def dibujar_boca(nombre, cara, n=T_BOCA):
    X, Y = _rejilla(n)
    px = 2.0 / n
    lz = np.zeros((n, n, 4), dtype=np.float32)
    linea = (0.42, 0.18, 0.17)
    dentro = (0.40, 0.10, 0.13)
    lengua = (0.92, 0.50, 0.52)
    if nombre in ("normal", "cerrados"):
        _trazo(lz, X, Y, _curva(lambda x: -0.02 + 0.10 * (x / 0.34) ** 2 - 0.08 * (1 - (x / 0.34) ** 2) * 0.3,
                                -0.34, 0.34), 0.09, linea, px)
    elif nombre == "decidido":
        _trazo(lz, X, Y, _curva(lambda x: 0.0 - 0.06 * (x / 0.30) ** 4, -0.30, 0.30), 0.10, linea, px)
    elif nombre == "entrecerrados":
        _trazo(lz, X, Y, _curva(lambda x: -0.04 + 0.035 * np.sin(x * 9.0), -0.24, 0.24), 0.08, linea, px)
    elif nombre == "sorpresa":
        r = np.hypot(X / 0.17, (Y + 0.02) / 0.23)
        _sobre(lz, dentro, _paso((r - 1) * 0.17, px))
        _sobre(lz, linea, _paso(np.abs(r - 1) * 0.17 - 0.035, px))
    else:
        if nombre == "sonrisa":
            arr = lambda x: 0.14 - 0.10 * (x / 0.48) ** 2
            aba = lambda x: 0.14 - 0.56 * np.clip(1 - (x / 0.48) ** 2, 0, 1) ** 0.7
            xr = 0.48
        elif nombre == "grito":
            arr = lambda x: 0.26 - 0.10 * (x / 0.40) ** 2 - 0.06 * np.abs(x)
            aba = lambda x: 0.10 - 0.66 * np.clip(1 - (x / 0.40) ** 2, 0, 1) ** 0.6
            xr = 0.40
        else:   # dolor: dientes apretados
            arr = lambda x: 0.16 - 0.10 * np.abs(x) + 0.03 * np.sin(x * 14)
            aba = lambda x: -0.20 + 0.06 * np.abs(x) + 0.03 * np.sin(x * 14 + 1)
            xr = 0.50
        dd = np.maximum(Y - arr(X), aba(X) - Y)
        dd = np.maximum(dd, np.abs(X) - xr)
        boca = _paso(dd, px)
        if nombre == "dolor":
            _sobre(lz, (0.98, 0.97, 0.95), boca)
            _trazo(lz, X, Y, _curva(lambda x: -0.02 + 0.02 * np.sin(x * 14 + 0.5), -0.46, 0.46), 0.04,
                   (0.55, 0.45, 0.45), px, afilar=False)
            for xd in (-0.25, 0.0, 0.25):
                _trazo(lz, X, Y, [(xd, arr(xd) - 0.02), (xd, aba(xd) + 0.02)], 0.03, (0.65, 0.55, 0.55), px, alfa=0.8,
                       afilar=False)
        else:
            _sobre(lz, dentro, boca)
            ln = _paso(np.hypot(X / 0.30, (Y - (aba(0) + 0.10)) / 0.20) - 1, px) * boca
            _sobre(lz, lengua, ln)
            if nombre == "sonrisa":            # dientes de arriba
                _sobre(lz, (0.98, 0.97, 0.95), _paso(np.maximum(Y - arr(X) + 0.0, arr(X) - 0.10 - Y), px) * boca)
        borde = _paso(np.abs(dd) - 0.03, px)
        _sobre(lz, linea, borde * 0.95)
    return lz


def dibujar_marca(cara, n=T_BOCA):
    """La cicatriz en cruz de Kael (dos trazos finos, rojizos)."""
    X, Y = _rejilla(n)
    px = 2.0 / n
    lz = np.zeros((n, n, 4), dtype=np.float32)
    if cara.get("marca") is None:
        return lz
    c = (0.78, 0.36, 0.33)
    _trazo(lz, X, Y, [(-0.55, 0.50), (0.0, 0.0), (0.55, -0.50)], 0.13, c, px, alfa=0.85)
    _trazo(lz, X, Y, [(-0.45, -0.52), (0.0, 0.0), (0.45, 0.52)], 0.11, c, px, alfa=0.85)
    return lz


def atlas(cara, ruta):
    """Dibuja el atlas y lo guarda en PNG (sin pérdidas)."""
    A = np.zeros((H_AT, W, 4), dtype=np.float32)
    for i, e in enumerate(EXPRESIONES):
        x, y = (i % 4) * T_OJO, (i // 4) * T_OJO
        A[y:y + T_OJO, x:x + T_OJO] = dibujar_ojo(e, cara)
        A[FILA_BOCA:FILA_BOCA + T_BOCA, i * T_BOCA:(i + 1) * T_BOCA] = dibujar_boca(e, cara)
    A[FILA_FIJA:FILA_FIJA + T_BOCA, 0:T_BOCA] = dibujar_marca(cara)
    A[FILA_FIJA:FILA_FIJA + T_BOCA, T_BOCA:2 * T_BOCA, :3] = cara["ceja_color"]
    A[FILA_FIJA:FILA_FIJA + T_BOCA, T_BOCA:2 * T_BOCA, 3] = 1.0
    # sin bordes negros al filtrar: el color de lo transparente es el del vecino (se extiende el color)
    A = _sangrar(A)
    # de sRGB dibujado a la imagen (que Blender guarda como sRGB)
    img = bpy.data.images.new("cara_atlas", W, H_AT, alpha=True)
    img.colorspace_settings.name = 'sRGB'
    img.pixels[:] = np.clip(A[::-1], 0, 1).astype(np.float32).ravel()
    img.filepath_raw = ruta
    img.file_format = 'PNG'
    img.save()
    return img, A


def _sangrar(A, pasos=6):
    a = A[..., 3]
    col = A[..., :3] * a[..., None]
    peso = a.copy()
    c2, p2 = col.copy(), peso.copy()
    for _ in range(pasos):
        acc = np.zeros_like(c2); pa = np.zeros_like(p2)
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            acc += np.roll(np.roll(c2, dy, 0), dx, 1)
            pa += np.roll(np.roll(p2, dy, 0), dx, 1)
        vacio = p2 < 1e-4
        c2 = np.where(vacio[..., None], acc, c2)
        p2 = np.where(vacio, pa, p2)
    rgb = np.where(p2[..., None] > 1e-6, c2 / np.maximum(p2[..., None], 1e-6), 0)
    out = A.copy()
    out[..., :3] = np.where(a[..., None] > 0.02, A[..., :3], rgb)
    return out


# ------------------------------------------------------------------ malla de la cara
def _uv_loseta(x0, y0, w, h, s, t):
    """UV (Blender, origen abajo) del punto (s, t) ∈ [0,1]² de la loseta en píxeles (x0, y0 desde arriba)."""
    return ((x0 + s * w) / W, 1.0 - (y0 + (1 - t) * h) / H_AT)


def crear(cara, cabeza_ob, arm, nombre="cara_v3", centro_y=-1.0):
    """Proyecta las piezas de la cara sobre la cabeza (objeto en reposo) y devuelve el objeto «cara_v3»."""
    deps = bpy.context.evaluated_depsgraph_get()
    bvh = BVHTree.FromObject(cabeza_ob, deps)
    mw = cabeza_ob.matrix_world
    mwi = mw.inverted()
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    col = bm.loops.layers.float_color.new("Col")
    cx = cara.get("centro_x", 0.0)

    def proy(x, z, sep):
        o = mwi @ Vector((x, -1.0, z))
        d = (mwi.to_3x3() @ Vector((0, 1, 0))).normalized()
        hit = bvh.ray_cast(o, d, 3.0)
        if hit[0] is None:
            return None
        n = hit[1]
        if n.dot(d) > 0:
            n = -n
        return mw @ (hit[0] + n * sep)

    def rejilla(cx0, cz0, ancho, alto, nx, nz, uv_de, codigo, sep):
        vs = {}
        for i in range(nx + 1):
            for k in range(nz + 1):
                s, t = i / nx, k / nz
                p = proy(cx0 + (s - 0.5) * ancho, cz0 + (t - 0.5) * alto, sep)
                if p is not None:
                    vs[i, k] = (bm.verts.new(p), s, t)
        for i in range(nx):
            for k in range(nz):
                q = [(i, k), (i + 1, k), (i + 1, k + 1), (i, k + 1)]
                if not all(c in vs for c in q):
                    continue
                f = bm.faces.new([vs[c][0] for c in q])
                for lp, c in zip(f.loops, q):
                    lp[uvl].uv = uv_de(vs[c][1], vs[c][2])
                    lp[col] = codigo
        return vs

    o = cara["ojo"]
    for lado in (-1, 1):            # -1: ojo derecho del personaje (-X); +1: izquierdo (en espejo)
        ex = cx + lado * o["x"]
        if lado < 0:
            uv = lambda s, t: _uv_loseta(0, 0, T_OJO, T_OJO, s, t)
        else:
            uv = lambda s, t: _uv_loseta(0, 0, T_OJO, T_OJO, 1 - s, t)
        rejilla(ex, o["z"], o["ancho"], o["alto"], 6, 6, uv, (1, 0, 0, 1), 0.0016)
    b = cara.get("boca")
    if b is not None:
        rejilla(cx + b["x"], b["z"], b["ancho"], b["alto"], 4, 3,
                lambda s, t: _uv_loseta(0, FILA_BOCA, T_BOCA, T_BOCA, s, t), (0, 1, 0, 1), 0.0014)
    m = cara.get("marca")
    if m is not None:
        rejilla(cx + m["lado"] * m["x"], m["z"], m["ancho"], m["alto"], 3, 3,
                lambda s, t: _uv_loseta(0, FILA_FIJA, T_BOCA, T_BOCA, s, t), (0, 0, 1, 1), 0.0012)
    # cejas: tiras con grosor que se afinan hacia fuera; las formas clave se calculan proyectando cada versión
    c = cara.get("ceja")
    cejas = []
    if c is not None:
        for lado in (-1, 1):
            cejas.append(_ceja(bm, uvl, col, proy, cx + lado * o["x"], c, lado))
    me = bpy.data.meshes.new(nombre)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(nombre, me)
    bpy.context.scene.collection.objects.link(ob)
    for p in me.polygons:
        p.use_smooth = True
    me.color_attributes.active_color = me.color_attributes["Col"]
    try:
        me.color_attributes.render_color_index = me.color_attributes.active_color_index
    except Exception:
        pass
    # formas clave de las cejas
    ob.shape_key_add(name="Basis")
    for forma in ("ceja_arriba", "ceja_enfado", "ceja_triste"):
        sk = ob.shape_key_add(name=forma)
        for (idxs, info) in cejas:
            for vi, (s, lado_v, xo) in zip(idxs, info):
                dz, dx = _desplazar_ceja(forma, s, c)
                xx = xo + dx * (-lado_v)
                p = proy(xx, me.vertices[vi].co.z + dz, 0.0030)
                if p is not None:
                    sk.data[vi].co = p
    return ob


def _ceja(bm, uvl, col, proy, ex, c, lado):
    """Ceja sobre el ojo ex: n segmentos del lagrimal (s=0) al rabillo (s=1)."""
    n = 6
    largo, grueso, z0 = c["largo"], c["grueso"], c["z"]
    incl = math.radians(c.get("inclinacion", 0.0))
    arriba, abajo = [], []
    info = []
    for k in range(n + 1):
        s = k / n
        x = ex + lado * largo * (s - 0.5)                   # s = 0 en el lagrimal (hacia el centro), 1 en el rabillo
        # arco suave, más alta en el centro; inclinación > 0: el rabillo más alto que el lagrimal; la cola cae un poco
        z = z0 + 0.010 * math.sin(math.pi * s) + math.tan(incl) * largo * (s - 0.5) - 0.006 * s * s
        g = grueso * (1.0 - 0.55 * s) + 0.002
        pa = proy(x, z + g * 0.5, 0.0030)
        pb = proy(x, z - g * 0.5, 0.0030)
        if pa is None or pb is None:
            continue
        arriba.append(bm.verts.new(pa)); abajo.append(bm.verts.new(pb))
        info += [(s, lado, x), (s, lado, x)]
    caras_vs = []
    for k in range(len(arriba) - 1):
        f = bm.faces.new((abajo[k], abajo[k + 1], arriba[k + 1], arriba[k]))
        for lp in f.loops:
            lp[uvl].uv = _uv_loseta(T_BOCA, FILA_FIJA, T_BOCA, T_BOCA, 0.5, 0.5)
            lp[col] = (0, 0, 1, 1)
    bm.verts.index_update()             # to_mesh conserva este orden
    idxs = []
    for a_, b_ in zip(arriba, abajo):
        idxs += [a_.index, b_.index]
    return (idxs, info)


def _desplazar_ceja(forma, s, c):
    """(dz, dx) de un punto de la ceja (s: 0 lagrimal, 1 rabillo) para cada forma clave."""
    if forma == "ceja_arriba":
        return 0.013 + 0.004 * math.sin(math.pi * s), 0.0
    if forma == "ceja_enfado":
        return -0.013 * (1 - s) + 0.005 * s, 0.004 * (1 - s)
    if forma == "ceja_triste":
        return 0.014 * (1 - s) - 0.007 * s, 0.0
    return 0.0, 0.0
