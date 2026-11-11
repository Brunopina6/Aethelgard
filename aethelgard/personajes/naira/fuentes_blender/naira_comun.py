# Naira, «la Astrónoma del Eclipse» (nombre provisional): base común de los conceptos y del modelo PROVISIONAL
# (12/11/2026, especialista de animaciones). Cuerpo, cara pintada, mechones de pelo, telas de dos caras, aros,
# estrellas y esqueleto. Geometría propia por guion: ningún recurso descargado (obra propia del proyecto).
#
# Reutiliza las utilidades de los prototipos del desierto (personajes/desierto/fuentes_blender/desierto_comun.py):
# atlas pintado, malla por partes, armadura, poses, clips, exportación y render.
#
# Ejes (Blender): mira a -Y, Z arriba, su izquierda es +X. En Godot mira a +Z.
# Medidas: 1,55 m (Kael y Garon 1,70; Lya 1,52, como en grupo_3d.gd ESCALA 0,6/0,67). Unas 4,2 cabezas: entre Kael
# (4) y Lya (4,8).
import bpy, bmesh, sys, os, math
import numpy as np
from mathutils import Vector, Matrix, Euler, Quaternion

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.normpath(os.path.join(AQUI, "..", "..", "desierto", "fuentes_blender")))
import desierto_comun as C   # noqa: E402

ALTO = 1.55
CAB_C = Vector((0, 0.0, 1.335))
CAB_R = (0.168, 0.158, 0.172)
HOMBRO = Vector((0.118, 0.0, 1.065))
CODO = Vector((0.160, 0.012, 0.855))
MUNECA = Vector((0.190, -0.004, 0.665))
MANO_F = Vector((0.200, -0.012, 0.582))
CADERA_L = Vector((0.068, 0.0, 0.745))
RODILLA = Vector((0.072, -0.006, 0.42))
TOBILLO = Vector((0.072, 0.012, 0.085))
PUNTA = Vector((0.072, -0.095, 0.02))
OJO = (0.168, 0.425, 0.092, 0.108)     # loseta de la cara: separación, altura, radios


def esp(v, lado):
    return Vector((v.x * lado, v.y, v.z))


# ================================================================== esqueleto

def huesos(extra=()):
    h = [("raiz", (0, 0, 0), (0, 0, 0.1), None),
         ("cadera", (0, 0, 0.745), (0, 0, 0.82), "raiz"),
         ("columna", (0, 0, 0.82), (0, 0, 0.93), "cadera"),
         ("pecho", (0, 0, 0.93), (0, 0, 1.07), "columna"),
         ("cuello", (0, 0, 1.07), (0, 0, 1.17), "pecho"),
         ("cabeza", (0, 0, 1.17), (0, 0, 1.50), "cuello")]
    for s, l in (("L", 1), ("R", -1)):
        ojo_top = ojo_mundo(l, arriba=True)
        h += [("parpado." + s, ojo_top, ojo_top + Vector((0, 0, -0.04)), "cabeza"),
              ("hombro." + s, (0.03 * l, 0, 1.055), esp(HOMBRO, l), "pecho"),
              ("brazo." + s, esp(HOMBRO, l), esp(CODO, l), "hombro." + s),
              ("antebrazo." + s, esp(CODO, l), esp(MUNECA, l), "brazo." + s),
              ("mano." + s, esp(MUNECA, l), esp(MANO_F, l), "antebrazo." + s),
              ("muslo." + s, esp(CADERA_L, l), esp(RODILLA, l), "cadera"),
              ("pierna." + s, esp(RODILLA, l), esp(TOBILLO, l), "muslo." + s),
              ("pie." + s, esp(TOBILLO, l), esp(PUNTA, l), "pierna." + s)]
    return h + list(extra)


ABIERTOS = {"parpado.L@esc": (1, 0.04, 1), "parpado.R@esc": (1, 0.04, 1)}
CERRADOS = {"parpado.L@esc": (1, 1, 1), "parpado.R@esc": (1, 1, 1)}


def con_ojos(p, cerrados=False):
    return C.sumar(p, CERRADOS if cerrados else ABIERTOS)


# ================================================================== cara

def cara_uv(co):
    return (co.x - CAB_C.x) / (2 * CAB_R[0]) + 0.5, (co.z - CAB_C.z) / (2 * CAB_R[2]) + 0.5


def barbilla_k(z):
    d = (CAB_C.z - z) / CAB_R[2]
    return 1.0 - 0.26 * max(d, 0) ** 2


def deform_cabeza(co):
    k = barbilla_k(co.z)
    # mejillas algo llenas y mentón pequeño (rostro joven)
    return Vector((co.x * k, co.y * k, co.z))


def ojo_mundo(lado, arriba=False):
    sep, alto, rx, ry = OJO
    u = 0.5 + sep * lado
    v = alto + (ry * 1.12 if arriba else 0.0)
    x = (u - 0.5) * 2 * CAB_R[0]
    z = (v - 0.5) * 2 * CAB_R[2] + CAB_C.z
    nx, nz = x / CAB_R[0], (z - CAB_C.z) / CAB_R[2]
    ny = -math.sqrt(max(1 - nx * nx - nz * nz, 0.01))
    return Vector((x, ny * CAB_R[1] * barbilla_k(z), z))


def dibujar_cara(A, P):
    """Ojos grandes de anime como los de Kael y Lya, pero con el párpado algo caído (reservada) y una media sonrisa
    torcida (irónica). En el iris, un destello en forma de estrella de cuatro puntas: su firma."""
    L = C.Lienzo(A, "cara")
    L.fondo(P["piel"])
    sep, alto, rx, ry = OJO
    for s in (-1, 1):
        L.elipse(0.5 + s * 0.215, 0.30, 0.06, 0.028, P["rubor"], 0.28)
    L.linea([(0.497, 0.355), (0.503, 0.343)], 0.006, [c * 0.80 for c in P["piel"]], 0.8)
    for s in (-1, 1):
        cx, cy = 0.5 + s * sep, alto
        # blanco del ojo, algo cuadrado por arriba
        L.elipse(cx, cy, rx, ry * 0.98, (0.97, 0.97, 0.98))
        # iris (degradado: oscuro arriba, luz abajo) y su aro
        L.degradado_elipse(cx, cy - 0.008, rx * 0.84, ry * 0.90, P["iris_arriba"], P["iris_abajo"])
        L.arco(cx, cy - 0.008, rx * 0.84, ry * 0.90, 0, 360, 0.008, [c * 0.45 for c in P["iris_arriba"]], 0.9,
               n=48)
        if P.get("eclipse"):
            # pupila de eclipse: disco oscuro con corona clara
            L.elipse(cx, cy - 0.006, rx * 0.50, ry * 0.56, P["corona"])
            L.elipse(cx, cy - 0.006, rx * 0.38, ry * 0.44, (0.05, 0.03, 0.08))
        else:
            L.elipse(cx, cy - 0.004, rx * 0.36, ry * 0.44, [c * 0.30 for c in P["iris_arriba"]])
        # brillos: uno grande, uno pequeño y la estrella de cuatro puntas
        L.elipse(cx - s * 0.028 - 0.004, cy + 0.036, 0.022, 0.026, (1, 1, 1))
        L.elipse(cx + s * 0.022, cy - 0.044, 0.010, 0.010, (1, 1, 1), 0.85)
        ex, ey = cx + 0.024 * s, cy + 0.006
        L.linea([(ex - 0.022, ey), (ex + 0.022, ey)], 0.004, P["estrella_ojo"], 0.95)
        L.linea([(ex, ey - 0.026), (ex, ey + 0.026)], 0.004, P["estrella_ojo"], 0.95)
        L.elipse(ex, ey, 0.006, 0.006, (1, 1, 1))
        # párpado algo caído: tapa la parte de arriba del iris (mirada tranquila, reservada)
        L.rect(cx - rx * 1.3, cy + ry * 0.70, cx + rx * 1.3, cy + ry * 1.4, P["piel"])
        L.arco(cx, cy + ry * 0.10, rx * 1.14, ry * 0.62, 6, 174, 0.020, P["pestanas"])
        # rabillo hacia fuera (pestañas)
        fx = cx + s * rx * 1.10
        L.linea([(fx, cy + ry * 0.52), (fx + s * 0.03, cy + ry * 0.72)], 0.014, P["pestanas"], grosor_fin=0.003)
        L.linea([(fx - s * 0.01, cy + ry * 0.62), (fx + s * 0.018, cy + ry * 0.95)], 0.008, P["pestanas"],
                grosor_fin=0.002)
        # pliegue del párpado y pestaña de abajo
        L.arco(cx, cy + ry * 0.30, rx * 1.02, ry * 0.62, 30, 150, 0.005, [c * 0.78 for c in P["piel"]], 0.7)
        L.arco(cx, cy + ry * 0.12, rx * 0.92, ry * 1.02, 238, 302, 0.005, P["pestanas"], 0.6)
        # cejas finas; la izquierda (la suya) algo más alta: la ironía
        alza = 0.018 if s > 0 else 0.0
        L.arco(cx + s * 0.008, alto + 0.150 + alza, 0.078, 0.022, 18 if s > 0 else 30, 150 if s > 0 else 162,
               0.009, P["cejas"])
    # media sonrisa torcida
    L.linea([(0.462, 0.262), (0.497, 0.256), (0.527, 0.262), (0.545, 0.276)], 0.008, P["labios"])
    L.linea([(0.545, 0.276), (0.552, 0.283)], 0.005, P["labios"], 0.7)
    return L


def dibujar_parpado(A, nombre, piel, pestanas):
    A.muestra(nombre, piel, plano=True)
    x0, y0, c = A.muestras[nombre]
    px, py, pc = int(x0 * A.tam), int(y0 * A.tam), int(c * A.tam)
    A.img[py:py + int(pc * 0.30), px:px + pc, :3] = pestanas


def muestra_bandas(A, nombre, colores):
    """Muestra con un degradado a lo largo de t (0 abajo, 1 arriba) por varios colores: para el pelo (raíz → punta)."""
    i = len(A.muestras)
    col, fila = i % 8, i // 8
    assert fila < 4, "atlas lleno"
    c = A.celda
    x0, y0 = col * c, A.tam - (fila + 1) * c
    t = np.linspace(0, 1, c)
    cs = np.array(colores, dtype=np.float32)
    k = np.linspace(0, 1, len(colores))
    rgb = np.stack([np.interp(t, k, cs[:, j]) for j in range(3)], axis=1)
    A.img[y0:y0 + c, x0:x0 + c, :3] = rgb[:, None, :]
    A.muestras[nombre] = (x0 / A.tam, y0 / A.tam, c / A.tam)
    return nombre


def dibujar_estrellas(A, cual, fondo_arriba, fondo_abajo, semilla=5, lineas=True):
    """Loseta de mapa estelar (forro de capas, bordados): fondo de noche, puntos de luz y constelaciones."""
    L = C.Lienzo(A, cual)
    sub = A.img[L.y0:L.y0 + L.h, L.x0:L.x0 + L.h, :3]
    t = L.Y[..., None]
    sub[...] = np.array(fondo_abajo, np.float32) * (1 - t) + np.array(fondo_arriba, np.float32) * t
    rng = np.random.default_rng(semilla)
    pts = rng.random((170, 2))
    for (x, y) in pts:
        r = 0.002 + rng.random() ** 3 * 0.006
        L.elipse(x, y, r, r, (0.95, 0.88, 0.70) if rng.random() < 0.6 else (0.78, 0.82, 1.0), 0.9)
    if lineas:
        for _ in range(7):
            i0 = rng.integers(0, len(pts))
            cad = [tuple(pts[i0])]
            for _ in range(3):
                d = np.linalg.norm(pts - np.array(cad[-1]), axis=1)
                d[d < 1e-6] = 9
                orden = np.argsort(d)
                cad.append(tuple(pts[orden[rng.integers(0, 3)]]))
            L.linea(cad, 0.0025, (0.85, 0.80, 0.62), 0.45)
            for p in cad:
                L.elipse(p[0], p[1], 0.006, 0.006, (1.0, 0.92, 0.70))
    return L


# ================================================================== pesos

def pesos_brazo(l, s):
    a, b = esp(HOMBRO, l), esp(MANO_F, l)
    te = (esp(CODO, l) - a).length / (b - a).length
    tm = (esp(MUNECA, l) - a).length / (b - a).length
    return C.por_eje(a, b, [(-0.06, "pecho"), (0.06, "hombro." + s), (0.14, "brazo." + s), (te - 0.07, "brazo." + s),
                            (te + 0.07, "antebrazo." + s), (tm - 0.04, "antebrazo." + s), (tm + 0.03, "mano." + s)])


def pesos_pierna(s):
    return [(0.03, "pie." + s), (0.10, "pierna." + s), (0.36, "pierna." + s), (0.46, "muslo." + s),
            (0.66, "muslo." + s), (0.78, "cadera")]


def por_altura(z, cadena):
    """Como desierto_comun.por_altura, pero suma los pesos cuando dos tramos seguidos son del mismo hueso: allí
    {ha: 1 - t, hb: t} con ha == hb se quedaba en {hb: t} y, justo en el borde (t ~ 0), el vértice quedaba sin peso
    (el exportador glTF creaba entonces un «neutral_bone»)."""
    if z <= cadena[0][0]:
        return {cadena[0][1]: 1.0}
    for (za, ha), (zb, hb) in zip(cadena, cadena[1:]):
        if z <= zb:
            t = (z - za) / max(zb - za, 1e-6)
            t = t * t * (3 - 2 * t)
            w = {ha: 1 - t}
            w[hb] = w.get(hb, 0.0) + t
            return w
    return {cadena[-1][1]: 1.0}


def pesos_tronco(co):
    return por_altura(co.z, [(0.76, "cadera"), (0.84, "columna"), (0.92, "columna"), (1.00, "pecho"),
                               (1.09, "pecho"), (1.13, "cuello")])


def pesos_falda(rigidez=1.0):
    """Faldones: la cadera arriba; abajo, una parte de cada muslo según el lado (atrás, menos: no siguen al paso)."""
    def f(co):
        if co.z > 0.80:
            return pesos_tronco(co)
        k = min(max((0.80 - co.z) / 0.42, 0.0), 1.0) * 0.8 * rigidez
        if co.y > 0.05:
            k *= 0.45
        lado = max(min(co.x / 0.07, 1.0), -1.0)
        return {"cadera": 1 - k, "muslo.L": k * (0.5 + 0.5 * lado), "muslo.R": k * (0.5 - 0.5 * lado)}
    return f


def pesos_capa(co):
    w = pesos_tronco(co) if co.z > 0.9 else {"pecho": 0.6, "columna": 0.4}
    ax = abs(co.x)
    if ax > 0.08 and co.z > 0.86:
        s = "L" if co.x > 0 else "R"
        w = dict(w)
        w["hombro." + s] = min((ax - 0.08) / 0.10, 1.0) * 0.55
    return w


# ================================================================== geometría

def envoltura(M, anillo, phi0, phi1, lados, pasos, t_fin=None, cerrado=False, doble=0.0, cy0=0.0):
    """Superficie de tela: anillo(t, phi) → posición, con t de 0 (arriba) a t_fin(phi) (el bajo, que puede variar con
    el ángulo: faldones de largos distintos). phi = 0 delante (-Y), crece hacia su izquierda (+X). Con «doble», una
    segunda cara hacia dentro (forro) a esa distancia. Devuelve (exterior, forro)."""
    nphi = lados if cerrado else lados + 1
    fr = list(pasos) if isinstance(pasos, (list, tuple)) else [i / pasos for i in range(pasos + 1)]
    pasos = len(fr) - 1

    def rejilla(off):
        g = []
        for k in range(nphi):
            phi = phi0 + (phi1 - phi0) * k / lados
            te = t_fin(phi) if t_fin else 1.0
            col = []
            for i in range(pasos + 1):
                p = anillo(te * fr[i], phi)
                if off:
                    d = Vector((p.x, p.y - cy0, 0.0))
                    if d.length > 1e-5:
                        p = p - d.normalized() * off
                v = M.bm.verts.new(p)
                M.uv_tubo[v] = (k / lados, fr[i])      # u alrededor, v del cuello (0) al bajo (1)
                col.append(v)
            g.append(col)
        return g

    def caras(g, hacia_fuera):
        for k in range(lados):
            k2 = (k + 1) % nphi if cerrado else k + 1
            for i in range(pasos):
                q = (g[k][i], g[k][i + 1], g[k2][i + 1], g[k2][i])
                M.bm.faces.new(q if hacia_fuera else tuple(reversed(q)))
    ext = rejilla(0.0)
    caras(ext, True)
    vext = [v for c in ext for v in c]
    if doble <= 0:
        return vext, []
    inn = rejilla(doble)
    caras(inn, False)
    return vext, [v for c in inn for v in c]


def anillo_elipse(perfil):
    """perfil: [(t, z, rx, ry, cy)] → función anillo(t, phi) con interpolación suave."""
    ts = [p[0] for p in perfil]

    def f(t, phi):
        for a, b in zip(perfil, perfil[1:]):
            if t <= b[0]:
                u = (t - a[0]) / max(b[0] - a[0], 1e-6)
                break
        else:
            a, b, u = perfil[-2], perfil[-1], 1.0
        u2 = u * u * (3 - 2 * u)
        z = a[1] + (b[1] - a[1]) * u
        rx = a[2] + (b[2] - a[2]) * u2
        ry = a[3] + (b[3] - a[3]) * u2
        cy = a[4] + (b[4] - a[4]) * u2
        return Vector((rx * math.sin(phi), cy - ry * math.cos(phi), z))
    return f


def con_pliegues(anillo, n=7, amp=0.012, desde=0.25):
    """Pliegues verticales que crecen hacia el bajo."""
    def f(t, phi):
        p = anillo(t, phi)
        k = max(t - desde, 0) / (1 - desde)
        r = 1 + amp * k * math.sin(n * phi) / max(Vector((p.x, p.y, 0)).length, 0.05)
        return Vector((p.x * r, p.y * r, p.z))
    return f


def aro(M, centro, normal, radio, grosor, lados=8, n=32, arco=(0, 360)):
    centro, normal = Vector(centro), Vector(normal).normalized()
    a = normal.orthogonal().normalized()
    b = normal.cross(a)
    pts = []
    cerrado = arco[1] - arco[0] >= 360
    for i in range(n + 1):
        ang = math.radians(arco[0] + (arco[1] - arco[0]) * i / n)
        pts.append(centro + (a * math.cos(ang) + b * math.sin(ang)) * radio)
    return M.tubo(pts, [grosor] * len(pts), lados, tapas=(not cerrado, not cerrado), ref=normal)


def disco(M, centro, normal, radio, grueso, lados=24):
    centro, normal = Vector(centro), Vector(normal).normalized()
    return M.tubo([centro - normal * grueso / 2, centro + normal * grueso / 2], [radio, radio], lados,
                  tapas=(True, True), ref=normal.orthogonal())


def estrella(M, centro, normal, radio, grueso=0.006, puntas=4, interior=0.32):
    """Estrella plana de N puntas (bordado o broche), con relieve por las dos caras."""
    centro, normal = Vector(centro), Vector(normal).normalized()
    a = normal.orthogonal().normalized()
    b = normal.cross(a)
    borde = []
    for i in range(puntas * 2):
        ang = math.pi * i / puntas + math.pi / 2
        r = radio if i % 2 == 0 else radio * interior
        borde.append(M.bm.verts.new(centro + (a * math.cos(ang) + b * math.sin(ang)) * r))
    f = M.bm.verts.new(centro + normal * grueso)
    t = M.bm.verts.new(centro - normal * grueso)
    n = len(borde)
    for i in range(n):
        M.bm.faces.new((borde[i], borde[(i + 1) % n], f))
        M.bm.faces.new((borde[(i + 1) % n], borde[i], t))
    return borde + [f, t]


def punto_cab(th, ph, k=1.0):
    """Punto sobre la cabeza: th desde la coronilla (0) hacia abajo, ph = 0 delante, creciente hacia +X."""
    return CAB_C + Vector((CAB_R[0] * math.sin(th) * math.sin(ph), -CAB_R[1] * math.sin(th) * math.cos(ph),
                           CAB_R[2] * math.cos(th))) * k


def camino_mechon(ph, th0, th1, z_fin=None, vol=0.10, flare=0.02, rizo=0.0, barrido=0.0, n1=6, n2=6,
                  hacia_fuera=0.0):
    """Polilínea de un mechón: sigue la cabeza desde th0 hasta th1 (y gira «barrido» radianes: flequillo de lado) y
    luego cae recto hasta z_fin, con vuelo (flare) y la punta hacia dentro (rizo) o hacia fuera (rizo < 0)."""
    pts = []
    for i in range(n1 + 1):
        u = i / n1
        th = th0 + (th1 - th0) * u
        k = 1 + vol * (0.35 + 0.65 * u) + hacia_fuera * u * u
        pts.append(punto_cab(th, ph + barrido * u, k))
    if z_fin is not None and z_fin < pts[-1].z - 0.01:
        p = pts[-1]
        d = Vector((p.x - CAB_C.x, p.y - CAB_C.y, 0))
        rr = d.length
        d.normalize()
        for j in range(1, n2 + 1):
            u = j / n2
            z = p.z + (z_fin - p.z) * u
            r = rr + flare * u - rizo * max(0.0, (u - 0.65) / 0.35) ** 2
            pts.append(Vector((CAB_C.x + d.x * r, CAB_C.y + d.y * r, z)))
    return pts


def mechon(M, pts, ancho, grueso, ph, muestra, pesos="cabeza", lados=6, mat=0, punta=0.08):
    """Mechón aplanado que se afila hacia la punta, con el degradado del pelo a lo largo (raíz → punta)."""
    n = len(pts)
    radios = []
    for i in range(n):
        s = i / (n - 1)
        w = ancho * (1 - (1 - punta) * s ** 1.6) * (0.85 + 0.15 * math.sin(math.pi * min(s * 1.6, 1)))
        radios.append((w, max(grueso * (1 - 0.8 * s), 0.002)))
    vs = M.tubo(pts, radios, lados, ref=Vector((math.cos(ph), math.sin(ph), 0)), costura=True)
    pintar_largo(M, vs, muestra, pesos, mat)
    return vs


def pintar_largo(M, vs, muestra, pesos, mat=0):
    vs = [v for v in vs if v.is_valid]
    caras = {f for v in vs for f in v.link_faces}
    for f in caras:
        f.smooth = True
        f.material_index = mat
        for lp in f.loops:
            t = M.uv_tubo.get(lp.vert, (0.0, 0.0))[1]
            lp[M.uv].uv = M.atlas.uv_muestra(muestra, t)
    M.pesar(vs, pesos)
    return vs


def pesos_pelo_largo(co):
    """Pelo que cae por debajo de la cabeza: la cabeza arriba y el pecho abajo (no atraviesa los hombros al girar)."""
    return C.por_altura(co.z, [(1.02, "pecho"), (1.14, "cuello"), (1.22, "cabeza")])


# ================================================================== cuerpo base

def cuerpo(M, P, botas=None, manos=True, piernas=True):
    for s, l in (("L", 1), ("R", -1)):
        if piernas:
            M.pintar(M.tubo([esp(CADERA_L, l) + Vector((0, 0, 0.03)), esp(CADERA_L, l) + Vector((0, -0.004, -0.12)),
                             esp(RODILLA, l), esp(TOBILLO, l) + Vector((0, 0, 0.02))],
                            [0.066, 0.060, 0.045, 0.033], 12), P["medias"], pesos=pesos_pierna(s))
        if botas:
            botas(M, P, s, l)
        a, e, w, f = esp(HOMBRO, l), esp(CODO, l), esp(MUNECA, l), esp(MANO_F, l)
        M.pintar(M.tubo([a + Vector((-0.03 * l, 0, 0)), a, e, w], [0.036, 0.037, 0.031, 0.026], 12),
                 P["manga"], pesos=pesos_brazo(l, s))
        if manos:
            M.pintar(M.tubo([w, w + (f - w) * 0.35, f + (f - w) * 0.12], [(0.024, 0.017), (0.029, 0.019),
                                                                          (0.017, 0.012)], 10,
                            ref=Vector((0, 1, 0))), P["guante"], pesos="mano." + s)
            M.pintar(M.esfera(w + (f - w) * 0.30 + Vector((-0.019 * l, -0.017, 0)), (0.011, 0.011, 0.026), (8, 6),
                              giro=Euler((0.3, 0.4 * l, 0))), P["guante"], pesos="mano." + s)
    # cadera y tronco (la prenda de dentro)
    M.pintar(M.esfera((0, 0.0, 0.765), (0.118, 0.088, 0.075), (18, 10)), P["medias"],
             pesos=[(0.70, "cadera"), (0.80, "cadera"), (0.86, "columna")])
    M.pintar(M.tubo([(0, 0, 0.74), (0, 0, 0.80), (0, 0, 0.87), (0, -0.004, 0.97), (0, 0, 1.04), (0, 0.004, 1.075),
                     (0, 0.008, 1.10)],
                    [(0.118, 0.086), (0.106, 0.078), (0.092, 0.070), (0.108, 0.084), (0.114, 0.080),
                     (0.090, 0.066), (0.046, 0.040)], 16),
             P["tunica"], pesos=pesos_tronco)
    M.pintar(M.tubo([(0, 0.008, 1.06), (0, 0.008, 1.21)], [0.033, 0.031], 10), P["piel_cuerpo"],
             pesos=[(1.07, "pecho"), (1.12, "cuello"), (1.19, "cabeza")])

    def uv_cabeza(co, fc):
        rel = fc - CAB_C
        if rel.y < -0.06 and abs(rel.x) < 0.155 and rel.z > -0.2:
            return M.atlas.uv_loseta("cara", *cara_uv(co))
        if rel.z < -0.07 and rel.y < 0.03:          # mandíbula y lados del cuello: piel
            return M.atlas.uv_muestra("piel_plana", 0.5)
        # el resto de la cabeza, del color del pelo (entre mechones no asoma la piel)
        return M.atlas.uv_muestra("pelo_casquete" if "pelo_casquete" in M.atlas.muestras else "piel_plana", 0.5)
    M.pintar(M.esfera(CAB_C, CAB_R, (32, 22)), uvf=uv_cabeza, pesos="cabeza", deform=deform_cabeza)
    sep, alto, rx, ry = OJO
    for s, l in (("L", 1), ("R", -1)):
        cu = 0.5 + sep * l

        def fuera(co, cu=cu):
            u, v = cara_uv(co)
            return co.y > 0 or ((u - cu) / (rx * 1.32)) ** 2 + ((v - alto) / (ry * 1.18)) ** 2 > 1.0
        M.pintar(M.esfera(CAB_C, [r * 1.012 for r in CAB_R], (48, 32)), "parpado", pesos="parpado." + s,
                 deform=deform_cabeza, quitar=fuera)


def casquete(M, muestra, quitar_frente=True, nuca=-0.10):
    """Casquete de pelo (bajo los mechones): sin la cara y sin el cuello."""
    def fuera(co):
        rel = co - CAB_C
        if rel.z < nuca * CAB_R[2] / 0.172 and rel.y < 0.08:
            return True
        if rel.z < -0.13:
            return True
        return quitar_frente and rel.y < -0.02 and rel.z < 0.075 and abs(rel.x) < 0.15
    vs = M.esfera(CAB_C + Vector((0, 0.006, 0.006)), [r * 1.045 for r in CAB_R], (28, 18))
    return M.pintar(vs, muestra, pesos="cabeza", quitar=fuera)


# ================================================================== héroes del juego (muñecos a escala)

HEROES = [("Kael", "kael.fbx", "01a19b86", 1.70),
          ("Lya", "Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx", None, 1.52),
          ("Garon", "garon.fbx", "Sword_Judgment", 1.70)]


def importar_heroe(raiz, archivo, accion, alto, pos, giro_z=0.0, fotograma=1):
    """Importa el FBX del juego y lo deja a su altura relativa (Kael y Garon 1,7 m; Lya 0,6/0,67 de Kael, como en
    grupo_3d.gd). Lya no trae reposo (su clip de reposo es la pose en T): se le bajan los brazos a mano."""
    antes = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=os.path.join(raiz, archivo))
    nuevos = [o for o in bpy.data.objects if o not in antes]
    arm = next((o for o in nuevos if o.type == 'ARMATURE'), None)
    if arm and arm.animation_data:
        cands = [a for a in bpy.data.actions if accion and accion in a.name and a.name.startswith(arm.name + "|")]
        arm.animation_data.action = cands[0] if cands else None
    bpy.context.scene.frame_set(fotograma)
    bpy.context.view_layer.update()
    if arm and accion is None:
        for pb in arm.pose.bones:          # sin clip: de vuelta a la pose de reposo del FBX (en T)
            pb.rotation_quaternion = Quaternion()
            pb.rotation_euler = (0, 0, 0)
            pb.location = (0, 0, 0)
            pb.scale = (1, 1, 1)
        bpy.context.view_layer.update()
        bajar_brazos(arm)
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []
    for o in nuevos:
        if o.type == 'MESH':
            ev = o.evaluated_get(dg)
            me = ev.to_mesh()
            pts += [o.matrix_world @ v.co for v in me.vertices]
            ev.to_mesh_clear()
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    s = alto / (hi.z - lo.z)
    vac = bpy.data.objects.new("heroe_" + archivo[:5], None)
    bpy.context.scene.collection.objects.link(vac)
    for o in nuevos:
        if o.parent is None:
            o.parent = vac
            o.matrix_parent_inverse = Matrix.Translation(-Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z)))
    vac.scale = (s, s, s)
    vac.location = pos
    vac.rotation_euler = (0, 0, math.radians(giro_z))
    return vac, nuevos


def bajar_brazos(arm, grados=68):
    mw = arm.matrix_world.to_3x3()
    for nombre, signo in (("mixamorig:LeftArm", 1), ("mixamorig:RightArm", -1)):
        pb = arm.pose.bones.get(nombre)
        if not pb:
            continue
        mano = arm.pose.bones[nombre.replace("Arm", "Hand")]
        mejor = None
        for sg in (1, -1):
            eje = (mw.inverted() @ Vector((0, sg, 0))).normalized()
            R = Quaternion(eje, math.radians(grados)).to_matrix().to_4x4()
            h = pb.matrix.to_translation()
            orig = pb.matrix.copy()
            pb.matrix = Matrix.Translation(h) @ R @ Matrix.Translation(-h) @ orig
            bpy.context.view_layer.update()
            z = (arm.matrix_world @ mano.matrix.to_translation()).z
            if mejor is None or z < mejor[0]:
                mejor = (z, pb.matrix.copy())
            pb.matrix = orig
            bpy.context.view_layer.update()
        pb.matrix = mejor[1]
        bpy.context.view_layer.update()


# ================================================================== render

def preparar(esc, ancho, alto, fondo=(0.94, 0.92, 0.88)):
    w = C.preparar_render(esc, ancho, alto, fondo=fondo, muestras=48)
    try:
        esc.view_settings.look = 'AgX - Base Contrast'
    except Exception:
        pass
    return w


def luces_estudio(esc):
    """Luz de estudio neutra para las láminas: llave cálida a 3/4, relleno frío y contraluz azulado."""
    hechas = []
    for nom, energia, rot, color in (("llave", 3.0, (52, 6, 28), (1.0, 0.95, 0.88)),
                                     ("relleno", 1.3, (68, 0, -125), (0.80, 0.86, 1.0)),
                                     ("contra", 2.6, (118, 0, 195), (0.85, 0.88, 1.0))):
        l = bpy.data.lights.new(nom, 'SUN')
        l.energy = energia
        l.color = color
        try:
            l.angle = math.radians(5)
        except Exception:
            pass
        o = bpy.data.objects.new(nom, l)
        esc.collection.objects.link(o)
        o.rotation_euler = [math.radians(a) for a in rot]
        hechas.append(o)
    return hechas


def copia_posada(esc, arm, ob, pose, x, giro, silueta=False, extra_objs=()):
    a2 = arm.copy()
    a2.data = arm.data
    esc.collection.objects.link(a2)
    if a2.animation_data:
        a2.animation_data_clear()
    m2 = C.silueta_de(ob, esc) if silueta else ob.copy()
    if not silueta:
        esc.collection.objects.link(m2)
    m2.parent = a2
    m2.modifiers["esqueleto"].object = a2
    a2.location = (x, 0, 0)
    a2.rotation_euler = (0, 0, math.radians(giro))
    poner(a2, pose)
    return a2, m2


def poner(arm, pose):
    """Pone la pose; las claves «X@sobre_mano.S» colocan el hueso X (hijo de la raíz) delante de esa mano."""
    normal = {k: v for k, v in pose.items() if "@sobre_" not in k}
    C.poner_pose(arm, normal)
    bpy.context.view_layer.update()
    for k, v in pose.items():
        if "@sobre_" in k:
            h, mano = k.split("@sobre_")
            pm = arm.pose.bones[mano]
            fin = pm.tail.copy()                  # en espacio de armadura, con la pose
            dest = fin + Vector(v)
            rb = arm.data.bones[h]
            delta = dest - arm.pose.bones[h].head     # el hueso cuelga de la raíz (sin giro): basta trasladarlo
            R = rb.matrix_local.to_3x3()
            arm.pose.bones[h].location = R.inverted() @ delta
    bpy.context.view_layer.update()


# ================================================================== más ayudas de tela

def muestra_corte(A, nombre, arriba, ribete, corte=0.94, abajo_osc=0.82):
    """Muestra para telas pintadas por su v (0 cuello, 1 bajo): el color con un leve oscurecido hacia el bajo y, a
    partir de «corte», el ribete con borde nítido."""
    i = len(A.muestras)
    col, fila = i % 8, i // 8
    assert fila < 4, "atlas lleno"
    c = A.celda
    x0, y0 = col * c, A.tam - (fila + 1) * c
    t = np.linspace(0, 1, c)[:, None]
    base = np.array(arriba, np.float32)[None, :] * (1.04 - (1.04 - abajo_osc) * t)
    rib = np.array(ribete, np.float32)[None, :] * np.ones_like(t)
    m = (t >= corte).astype(np.float32)
    rgb = base * (1 - m) + rib * m
    A.img[y0:y0 + c, x0:x0 + c, :3] = rgb[:, None, :]
    A.muestras[nombre] = (x0 / A.tam, y0 / A.tam, c / A.tam)
    return nombre


def pintar_loseta(M, vs, cual, pesos, mat=0, escala=(1.0, 1.0)):
    """UV de la loseta («detalle»…) según la u/v propia de la tela (envoltura o tubo con costura)."""
    vs = [v for v in vs if v.is_valid]
    caras = {f for v in vs for f in v.link_faces}
    for f in caras:
        f.smooth = True
        f.material_index = mat
        for lp in f.loops:
            u, v = M.uv_tubo.get(lp.vert, (0.0, 0.0))
            lp[M.uv].uv = M.atlas.uv_loseta(cual, min(max(u * escala[0], 0), 1), min(max(1 - v * escala[1], 0), 1))
    M.pesar(vs, pesos)
    return vs


def t_de_z(perfil, z):
    for a, b in zip(perfil, perfil[1:]):
        if (a[1] - z) * (b[1] - z) <= 0:
            return a[0] + (b[0] - a[0]) * (a[1] - z) / max(a[1] - b[1], 1e-6)
    return 1.0 if z < perfil[-1][1] else 0.0


def manga_doble(M, pts, radios, ext, forro, pesos, lados=14, cual_forro=None):
    """Manga abierta (acampanada) de dos caras: fuera «ext» (muestra, por largo) y dentro el forro."""
    v1 = M.tubo(pts, radios, lados, costura=True)
    pintar_largo(M, v1, ext, pesos)
    r2 = [(r - 0.004) if isinstance(r, (int, float)) else (r[0] - 0.004, r[1] - 0.004) for r in radios]
    v2 = M.tubo(pts, r2, lados, costura=True)
    caras = list({f for v in v2 for f in v.link_faces})
    bmesh.ops.reverse_faces(M.bm, faces=caras)
    if cual_forro:
        pintar_loseta(M, v2, cual_forro, pesos)
    else:
        pintar_largo(M, v2, forro, pesos)
    return v1 + v2


def banda(M, z0, inclina, rx, ry, alto, muestra, pesos, mat=0, lados=28, cy=0.0):
    """Cinturón o faja: un anillo elíptico, inclinado por «inclina» (dz por metro en x)."""
    def an(t, phi):
        x = rx * math.sin(phi)
        return Vector((x, cy - ry * math.cos(phi), z0 + inclina * x - alto * t))
    vs, _ = envoltura(M, an, 0, 2 * math.pi, lados, 1, cerrado=True)
    return M.pintar(vs, muestra, pesos=pesos, mat=mat)


def bota(M, P, s, l, alto=0.36, puno=True, muestra="botas", hebilla=None):
    t = esp(TOBILLO, l)
    pts = [t + Vector((0, 0, -0.055)), t + Vector((0, 0, 0.05)), Vector((t.x, -0.004, (t.z + alto) / 2)),
           Vector((t.x, -0.006, alto))]
    M.pintar(M.tubo(pts, [0.044, 0.042, 0.044, 0.047], 12), P[muestra], pesos=pesos_pierna(s))
    if puno:
        M.pintar(M.tubo([Vector((t.x, -0.006, alto - 0.03)), Vector((t.x, -0.008, alto + 0.025))],
                        [0.052, 0.056], 12), P[muestra], pesos=pesos_pierna(s))
    M.pintar(M.esfera(esp(Vector((0.072, -0.035, 0.038)), l), (0.044, 0.085, 0.040), (12, 8)), P[muestra],
             pesos=lambda co, s=s: {"pie." + s: 1.0} if co.y < -0.02 else {"pie." + s: 0.6, "pierna." + s: 0.4},
             deform=lambda co: Vector((co.x, co.y, max(co.z, 0.0))))
    M.pintar(M.tubo([esp(Vector((0.072, -0.035, 0.002)), l), esp(Vector((0.072, -0.035, 0.014)), l)],
                    [(0.046, 0.088), (0.046, 0.088)], 12, ref=Vector((1, 0, 0))), P["suela"], pesos="pie." + s)
    if hebilla:
        M.pintar(aro(M, Vector((t.x, -0.006, alto * 0.62)), (0, 0, 1), 0.047, 0.006, 6, 20), P[hebilla], mat=2,
                 pesos=pesos_pierna(s))


def objeto_brillo(nombre, color, fuerza=4.0):
    return C.material_color(nombre, color, emision=(*color, fuerza))


def circulo_magico(esc, nombre, color, pos, radio=0.62):
    """Adorno de las láminas (no es parte del modelo): círculo en el suelo bajo la pose de hechizo."""
    A = None
    bm = bmesh.new()

    class _M:
        pass
    M = C.Malla.__new__(C.Malla)
    M.bm = bm
    M.uv = bm.loops.layers.uv.verify()
    M.dv = bm.verts.layers.deform.verify()
    M.atlas = A
    M.huesos = []
    M.uv_tubo = {}
    aro(M, (0, 0, 0.004), (0, 0, 1), radio, 0.006, 6, 64)
    aro(M, (0, 0, 0.004), (0, 0, 1), radio * 0.80, 0.004, 6, 64)
    for i in range(8):
        a = 2 * math.pi * i / 8
        estrella(M, (math.cos(a) * radio * 0.9, math.sin(a) * radio * 0.9, 0.006), (0, 0, 1), 0.035 if i % 2 else
                 0.05, 0.003)
    me = bpy.data.meshes.new(nombre)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(nombre, me)
    esc.collection.objects.link(ob)
    ob.data.materials.append(objeto_brillo(nombre + "_m", color, 2.2))
    ob.location = pos
    return ob
