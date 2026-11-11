# Bramavidrio (V12): el gusano colosal del Mar de Cristal. Modelo, textura, esqueleto y clips hechos desde cero con
# este guion (geometría procedural propia, textura pintada por código, ningún recurso descargado: obra propia del
# proyecto). Método del Coloso de la Falla (enemigos/coloso_falla/fuente/crear_coloso.py).
#
#   blender -b --factory-startup -P crear_bramavidrio.py -- <carpeta de salida> [alto,medio,bajo] [<salida.blend>]
#   blender -b --factory-startup -P crear_bramavidrio.py -- <carpeta> siluetas      (bocetos de las tres cabezas)
#
# Escribe en la carpeta:
#   bramavidrio.glb / bramavidrio_medio.glb / bramavidrio_bajo.glb   las tres versiones (mismos huesos y clips)
#   bramavidrio_piel.webp (2048) / _piel_medio.webp (1024) / _piel_bajo.webp (512)  la textura de la piel (RGB: color;
#                                     A: 0,04 + 0,96 × brillo de las grietas minerales), la misma distribución en las tres
#   bramavidrio_clips.json           duración, bucle e instantes clave de cada clip (impacto, succión, descarga…)
# y, si se pide, el .blend del alto (para los renders; no se versiona: se regenera). Misma semilla, mismo resultado.
#
# CONCEPTO (docs/memory/agents/animaciones_v12_bramavidrio.md): un gusano larguísimo (22 m de cuerpo y 3,2 de cabeza)
# de 18 anillos acorazados. Cada anillo lleva una placa dorsal de mineral (una teja: su labio trasero monta sobre el
# siguiente) con aletas de vidrio fundido que brillan; en los surcos entre anillos, la piel deja ver un brillo mineral
# tenue. La cabeza es un «arado»: un escudo ancho y bajo que se estrecha en una cuchilla (cava la arena; nada apunta
# hacia arriba: no es una corona) y una mandíbula inferior enorme en forma de cazo con cinco dientes de cincel; dentro,
# placas planas que muelen el vidrio y una garganta profunda y oscura con una luz mineral al fondo. Seis ocelos de
# vidrio a los lados. Cicatrices viejas selladas con vidrio que brilla.
#
# Ejes (Blender): mira a -Y, Z arriba, su izquierda es +X. En Godot mira a +Z. En la pose de enlace está tendido y
# recto a lo largo de +Y con la nuca en el origen; los clips lo colocan respecto del AGUJERO: el punto del cuerpo que
# pasa por el origen (en Godot, y = 0 es la arena). Lo que queda por debajo está enterrado: en la exploración lo tapa
# el suelo y en el combate lo recorta su material (bramavidrio_3d.gd).
#
# Esqueleto (43 huesos): raiz; col_01 (nuca) … col_18 (cola), una cadena que nace en la cola; cabeza y mandibula, con
# sus dos mandíbulas laterales (mandibula_izq y mandibula_der, que se abren hacia los lados al rugir);
# placa_02 … placa_17 (las aletas de vidrio de cada anillo: se erizan y vibran); y huesos sin malla cuya ESCALA es un
# dato para Godot: brillo (luz de aletas, ocelos y grietas), garganta (luz del fondo de la boca); y con malla que se
# esconde con escala 0,01: chorro (el aliento) y monticulo (la arena revuelta del agujero).
# Animación: cada fotograma es una curva de columna (ángulos de elevación, giro y torsión a lo largo del cuerpo,
# integrados desde el agujero) y la cadena se ajusta a ella por longitud de arco: una «spline IK» resuelta aquí y
# horneada a claves en cada fotograma. Así el cuerpo se desliza por el agujero sin estirarse.
#
# Colores de vértice en sRGB (oclusión y tintes). Los materiales los pone Godot (bramavidrio_3d.gd), por nombre:
#   piel     textura × color de vértice; la A de la textura es el brillo de las grietas
#   vidrio   aletas, ocelos y cristales: brillo frío que sigue al hueso «brillo»
#   garganta la luz del fondo de la boca: sigue al hueso «garganta»
#   arena    el montículo del agujero
#   chorro   el aliento (sin sombreado, aditivo; el alfa del color de vértice es su fuerza a lo largo)
import bpy, bmesh, sys, os, math, random, json
import numpy as np
from mathutils import Vector, Matrix, Quaternion, Euler, noise

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
CARPETA = argv[0] if argv else ""
MODO = argv[1] if len(argv) > 1 else "alto,medio,bajo"
PERFILES = [p for p in MODO.split(",") if p in ("alto", "medio", "bajo")]
SALIDA_BLEND = argv[2] if len(argv) > 2 else ""
FPS = 30
noise.seed_set(5) if hasattr(noise, "seed_set") else None

# ---------------------------------------------------------------- medidas

NSEG = 18
L_CUERPO = 22.0
LSEG = L_CUERPO / NSEG                     # 1,222 m por anillo
S_INI = -0.7                               # el tubo empieza dentro de la cabeza
A_PLACA = math.radians(132.0)             # las placas dorsales cubren ±132° (queda a la vista una franja del vientre)
ALETAS = range(2, NSEG)                    # anillos con aletas de vidrio (y su hueso placa_kk)
CALIDAD = {
    "alto": dict(pl_largo=[(0.02, 0.62), (0.46, 1.14)], pl_ancho=[(-0.44, 0.44, 1), (0.34, 0.95, 0), (-0.95, -0.34, 0)],
                 pl_nu=(3, 2), pl_nv=1, bisel=True, cr=(3, 6), cr_lados=6, dientes=(6, 4, 6, 3, 8), d_lados=5,
                 lat_lados=5, lat_puas=4, anillos_g=(3, 10), mejillas=True,
                 lados=30, filas=[0.0, 0.07, 0.2, 0.38, 0.62, 0.8, 0.93], pl_lados=14, pl_filas=4, cab_sec=17,
                 cab_lados=18, flancos=True, cristales=True, ganchos=True, dientes_lado=3, muelas=3, mont=26,
                 chorro=10, tex=2048),
    "medio": dict(pl_largo=[(0.03, 1.12)], pl_ancho=[(-0.44, 0.44, 1), (0.34, 0.95, 0), (-0.95, -0.34, 0)],
                  pl_nu=(2, 1), pl_nv=1, bisel=True, cr=(2, 3), cr_lados=5, dientes=(4, 3, 4, 2, 0), d_lados=4,
                  lat_lados=4, lat_puas=2, anillos_g=(2, 8), mejillas=True,
                  lados=20, filas=[0.0, 0.15, 0.5, 0.85], pl_lados=8, pl_filas=2, cab_sec=11, cab_lados=12,
                  flancos=True, cristales=False, ganchos=True, dientes_lado=2, muelas=2, mont=16, chorro=8, tex=1024),
    "bajo": dict(pl_largo=[(0.03, 1.12)], pl_ancho=[(-0.44, 0.44, 1), (0.34, 0.95, 0), (-0.95, -0.34, 0)],
                 pl_nu=(2, 1), pl_nv=1, bisel=False, cr=(1, 3), cr_lados=4, dientes=(3, 2, 3, 2, 0), d_lados=3,
                 lat_lados=3, lat_puas=0, anillos_g=(1, 6), mejillas=True,
                 lados=12, filas=[0.0, 0.5], pl_lados=5, pl_filas=1, cab_sec=8, cab_lados=8,
                 flancos=False, cristales=False, ganchos=False, dientes_lado=0, muelas=1, mont=10, chorro=6, tex=512),
}
Q = CALIDAD["alto"]
VARIANTE = "A"

PIEL, VIDRIO, GARGANTA, ARENA, CHORRO = range(5)
MATERIALES = ["piel", "vidrio", "garganta", "arena", "chorro"]

# Atlas de la textura (u a la derecha, v hacia arriba, como en Blender)
AT_TUBO = (0.0, 0.40, 0.0, 1.0)
AT_PLACAS = (0.40, 0.66, 0.0, 1.0)
AT_CRANEO = (0.66, 1.0, 0.52, 1.0)
AT_MANDIBULA = (0.66, 1.0, 0.20, 0.52)
AT_CARNE = (0.66, 0.90, 0.0, 0.20)
AT_NEUTRO = (0.90, 1.0, 0.0, 0.10)
AT_ARENA = (0.90, 1.0, 0.10, 0.20)

# Cabeza: secciones del cráneo (y, semiancho, línea de la boca, alto del arco). La nuca en y = 0; el hocico, a -Y.
CRANEO = [(0.95, 1.50, -0.30, 1.72), (0.45, 1.58, -0.33, 1.76), (0.0, 1.66, -0.36, 1.74), (-0.6, 1.80, -0.40, 1.62),
          (-1.2, 1.80, -0.41, 1.42), (-1.8, 1.70, -0.41, 1.18), (-2.35, 1.52, -0.39, 0.92), (-2.8, 1.30, -0.37, 0.62),
          (-3.12, 1.02, -0.36, 0.30)]
Y_NUCA, Y_HOCICO = 0.95, -3.12
# Mandíbula: (y, semiancho, profundidad) con la bisagra en BISAGRA
MAND = [(0.12, 1.20, 0.55), (-0.5, 1.52, 0.92), (-1.3, 1.62, 1.06), (-2.1, 1.56, 1.00), (-2.75, 1.42, 0.80),
        (-3.18, 1.26, 0.42)]
ZB_MAND = -0.43
BISAGRA = Vector((0.0, -0.15, -0.44))
OJOS = [(1.10, -1.25, 0.15), (1.16, -1.72, 0.125), (1.21, -2.15, 0.10)]   # (fi, y, radio), a los dos lados
CHORRO_BASE = Vector((0, -2.55, -0.62))
CHORRO_LARGO = 11.0
K_CAB = 1.3                                # la cabeza se modela a escala 1 (tablas de arriba) y se agranda así

# ---------------------------------------------------------------- colores (sRGB)

VIDRIO_C = (0.55, 0.93, 1.0)
VIDRIO_HONDO = (0.16, 0.45, 0.62)
DIENTE = (0.90, 0.86, 0.74)
DIENTE_OSC = (0.60, 0.55, 0.46)
QUERATINA = (0.30, 0.23, 0.19)
MUELA = (0.62, 0.62, 0.58)
HUESO_DIENTE = ((0.86, 0.82, 0.72), (0.74, 0.70, 0.62), (0.92, 0.90, 0.84))


def mezcla(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(a[i] * (1 - t) + b[i] * t for i in range(len(a)))


def suave(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def lineal(c):
    return tuple(x ** 2.2 for x in c[:3])


def catmull(tabla, x):
    """Interpolación suave por una tabla [(x, valor)] con x creciente (Catmull-Rom; fuera de la tabla, el extremo)."""
    xs = [p[0] for p in tabla]
    if x <= xs[0]:
        return tabla[0][1]
    if x >= xs[-1]:
        return tabla[-1][1]
    i = max(j for j in range(len(xs) - 1) if xs[j] <= x)
    p0 = tabla[max(i - 1, 0)][1]
    p1, p2 = tabla[i][1], tabla[i + 1][1]
    p3 = tabla[min(i + 2, len(tabla) - 1)][1]
    t = (x - xs[i]) / (xs[i + 1] - xs[i])
    return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3)


RADIOS = [(-1.0, 1.5), (0.0, 1.5), (1.5, 1.62), (4.0, 1.8), (9.0, 1.86), (14.0, 1.72), (17.0, 1.48), (19.5, 1.1),
          (21.0, 0.62), (21.8, 0.34), (22.0, 0.16)]


def radio(s):
    return catmull(RADIOS, s)


def perfil_anillo(t):
    """El anillo abombado: 0,87 en el surco (t = 0 y 1) y 1 en el centro."""
    return 0.87 + 0.13 * math.sin(math.pi * max(0.0, min(1.0, t))) ** 0.45


def seccion(alfa, r):
    """Sección del cuerpo: alfa = 0 arriba (lomo), +90° a su izquierda (+X), 180° el vientre (más plano)."""
    c, s = math.cos(alfa), math.sin(alfa)
    plano = 1.0 - 0.2 * max(0.0, -c) ** 0.8
    return r * 1.08 * s, r * c * plano


# ---------------------------------------------------------------- constructor de la malla

class Malla:
    def __init__(self):
        self.v, self.col, self.uv, self.pesos, self.caras, self.mats = [], [], [], [], [], []

    def vert(self, p, c, uv, pesos):
        self.v.append(Vector(p))
        self.col.append(tuple(c) + ((0.0,) if len(c) == 3 else ()))   # el alfa: cuánto «mineral» es (brillo y borde)
        self.uv.append(tuple(uv))
        self.pesos.append(dict(pesos) if isinstance(pesos, dict) else {pesos: 1.0})
        return len(self.v) - 1

    def cara(self, idx, mat=PIEL, fuera=None, hacia=None):
        """fuera(c) / hacia(c): un punto del que la cara se aleja / hacia el que mira (c = su centro)."""
        if len(set(idx)) < 3:
            return
        idx = tuple(idx)
        if fuera is not None or hacia is not None:
            pts = [self.v[i] for i in idx]
            n = Vector((0.0, 0.0, 0.0))
            for i in range(len(pts)):
                a, b = pts[i], pts[(i + 1) % len(pts)]
                n += Vector(((a.y - b.y) * (a.z + b.z), (a.z - b.z) * (a.x + b.x), (a.x - b.x) * (a.y + b.y)))
            c = sum(pts, Vector()) / len(pts)
            d = (c - Vector(fuera(c))) if fuera is not None else (Vector(hacia(c)) - c)
            if n.dot(d) < 0:
                idx = idx[::-1]
        self.caras.append(idx)
        self.mats.append(mat)


def en_atlas(region, u, v):
    u0, u1, v0, v1 = region
    return (u0 + (u1 - u0) * max(0.0, min(1.0, u)), v0 + (v1 - v0) * max(0.0, min(1.0, v)))


def col_nombre(k):
    return "col_%02d" % k


def placa_nombre(k):
    return "placa_%02d" % k


def peso_columna(s):
    """Pesos de un punto del cuerpo según su distancia desde la nuca (s): mezcla suave en cada unión de anillos."""
    x = s / LSEG
    j = int(round(x))
    d = x - j
    delta = 0.32
    if j >= NSEG:
        return {col_nombre(NSEG): 1.0}
    if abs(d) < delta and j >= 0:
        despues = suave(-delta, delta, d)
        antes = "cabeza" if j == 0 else col_nombre(j)
        w = {}
        if 1.0 - despues > 0.002:
            w[antes] = 1.0 - despues
        if despues > 0.002:
            w[col_nombre(j + 1)] = despues
        return w
    if x < 0:
        return {"cabeza": 1.0}
    return {col_nombre(min(NSEG, int(math.floor(x)) + 1)): 1.0}


def rejilla(M, filas, mat, cerrar_u=False, fuera=None, hacia=None):
    for i in range(len(filas) - 1):
        a, b = filas[i], filas[i + 1]
        n = len(a)
        for j in range(n - 1 + (1 if cerrar_u else 0)):
            j2 = (j + 1) % n
            M.cara((a[j], a[j2], b[j2], b[j]), mat, fuera, hacia)


EJE = lambda c: (0.0, c.y, 0.0)


# ---------------------------------------------------------------- el cuerpo

def filas_tubo():
    s_lista = [S_INI, -0.35]
    for k in range(NSEG):
        for t in Q["filas"]:
            s = (k + t) * LSEG
            if s < L_CUERPO - 0.12:
                s_lista.append(s)
    s_lista.append(L_CUERPO - 0.12)
    return s_lista


def crear_tubo(M):
    lados = Q["lados"]
    filas = []
    for s in filas_tubo():
        t = (s / LSEG) % 1.0 if s >= 0 else 0.5
        g = perfil_anillo(t) if s >= 0 else 1.0
        fila = []
        for j in range(lados + 1):
            alfa = -math.pi + 2 * math.pi * j / lados
            vientre = max(0.0, min(1.0, (-math.cos(alfa) - 0.3) / 0.5))
            r = radio(s) * (g + (1.0 - g) * 0.6 * vientre)              # el vientre, blando: surcos poco hondos
            x, z = seccion(alfa, r)
            ruido = noise.noise(Vector((x * 0.9, s * 0.7, z * 0.9))) * 0.025
            x, z = x * (1 + ruido), z * (1 + ruido)
            surco = 1.0 - math.exp(-(min(t, 1 - t) / 0.07) ** 2) if s >= 0 else 1.0
            bajo_placa = math.exp(-((abs(alfa) - A_PLACA - 0.06) / 0.12) ** 2)
            ao = (0.55 + 0.45 * surco) * (1.0 - 0.35 * bajo_placa)
            uv = en_atlas(AT_TUBO, j / lados, (s - S_INI) / (L_CUERPO - S_INI))
            fila.append(M.vert((x, s, z), (ao, ao, ao), uv, peso_columna(s)))
        filas.append(fila)
    rejilla(M, filas, PIEL, fuera=EJE)
    punta = M.vert((0, L_CUERPO + 0.18, 0.02), (0.8, 0.8, 0.8), en_atlas(AT_TUBO, 0.5, 1.0), {col_nombre(NSEG): 1.0})
    ult = filas[-1]
    for j in range(lados):
        M.cara((ult[j], ult[j + 1], punta), PIEL, fuera=lambda c: (0, L_CUERPO - 1.0, 0))


def placa(M, sup, u0, u1, v0, v1, nu, nv, grosor, alza, punta, hueso, uv_de, dentro, tinte=1.0, bisel=True,
          profundo=0.3, mineral=1.0):
    """Una placa de basalto sobre una superficie (sup(u, v) -> (punto, normal); v crece hacia la cola). Como una escama
    de pangolín: el borde de atrás se levanta (alza), acaba en punta en el centro (punta, en unidades de v) y monta
    sobre la placa siguiente. Con bisel, la fila y la columna de cada borde bajan y se aclaran (el canto gastado por la
    arena). Los cantos bajan hasta dentro del cuerpo (profundo) con la arena incrustada de las juntas (otra zona del
    atlas)."""
    def muestras(a, b, n):
        n = max(1, n)
        if not bisel:
            return [a + (b - a) * i / n for i in range(n + 1)]
        e = (b - a) * 0.12
        return [a] + [a + e + (b - a - 2 * e) * i / n for i in range(n + 1)] + [b]
    us, vs = muestras(u0, u1, nu), muestras(v0, v1, nv)
    um, vm = (u0 + u1) / 2, (v0 + v1) / 2
    filas, params = [], {}
    for j, v in enumerate(vs):
        fila = []
        for i, u in enumerate(us):
            ve = v + (punta * max(0.0, 1 - abs(2 * (u - um) / (u1 - u0))) if j == len(vs) - 1 else 0.0)
            borde = bisel and (i in (0, len(us) - 1) or j in (0, len(vs) - 1))
            h = grosor * (0.45 if borde else 1.0) + alza * ((v - v0) / (v1 - v0)) ** 1.5
            p, n = sup(u, ve)
            c = tinte * (0.98 if borde else 0.72)
            vid = M.vert(p + n * h, (c, c, min(1.0, c * 1.03), mineral), uv_de(u, ve), hueso)
            params[vid] = (u, ve)
            fila.append(vid)
        filas.append(fila)
    rejilla(M, filas, PIEL, fuera=dentro)
    per = filas[0][:] + [filas[j][-1] for j in range(1, len(vs))] + filas[-1][::-1][1:] + \
        [filas[j][0] for j in range(len(vs) - 2, 0, -1)]
    pm, nm = sup(um, vm)
    centro = pm - nm * profundo * 0.5
    canto = []
    for idx, vid in enumerate(per):
        u, ve = params[vid]
        p, n = sup(u, ve)
        arriba = M.vert(M.v[vid], (0.95, 0.88, 0.78, 0.0), en_atlas(AT_ARENA, idx / len(per), 0.85), hueso)
        abajo = M.vert(p - n * profundo, (0.42, 0.38, 0.34, 0.0), en_atlas(AT_ARENA, idx / len(per), 0.2), hueso)
        canto.append((arriba, abajo))
    for idx in range(len(per)):
        a1, b1 = canto[idx]
        a2, b2 = canto[(idx + 1) % len(per)]
        M.cara((a1, a2, b2, b1), PIEL, fuera=lambda c: centro)


def sup_cuerpo(k):
    rm = radio((k - 0.5) * LSEG)

    def f(alfa, s):
        r = rm * (1.0 + 0.03 * noise.noise(Vector((alfa * 2.1, s * 1.4, k * 0.37))))
        x, z = seccion(alfa, r)
        return Vector((x, s, z)), Vector((x, 0.0, z)).normalized()
    return f


def uv_cuerpo(k):
    def f(alfa, s):
        tp = max(0.0, min(1.0, (s / LSEG - (k - 1) - 0.04) / 1.06))
        return (en_atlas(AT_PLACAS, (alfa + A_PLACA) / (2 * A_PLACA), 0.0)[0], (k - 1) / NSEG + (0.04 + 0.92 * tp) / NSEG)
    return f


def crear_placas(M):
    """Cada anillo, cubierto de escamas de basalto: en el alto, dos filas de tres (dorsal y dos laterales, que la dorsal
    monta); en el medio, una fila de tres; en el bajo, una sola placa por anillo."""
    rnd = random.Random(53)
    for k in range(2, NSEG + 1):
        rm = radio((k - 0.5) * LSEG)
        hueso = col_nombre(k)
        sup, uvf = sup_cuerpo(k), uv_cuerpo(k)
        a = A_PLACA * (1.0 if k < 15 else 0.93)
        for (t0, t1) in Q["pl_largo"]:
            for (f0, f1, nivel) in Q["pl_ancho"]:
                j = rnd.uniform(-0.035, 0.035)
                s0 = (k - 1 + t0 + rnd.uniform(-0.02, 0.02)) * LSEG
                s1 = min((k - 1 + t1) * LSEG, L_CUERPO - 0.35)
                dorsal = nivel == 1
                nu = Q["pl_nu"][0] if dorsal else Q["pl_nu"][1]
                placa(M, sup, (f0 + j) * a, (f1 + j) * a, s0, s1, nu, Q["pl_nv"],
                      rm * (0.10 if dorsal else 0.075), rm * (0.07 if dorsal else 0.05),
                      LSEG * (0.16 if dorsal else 0.10), hueso, uvf, EJE, tinte=rnd.uniform(0.9, 1.08),
                      bisel=Q["bisel"], profundo=rm * 0.22)


def disposicion_racimos():
    """Dónde crecen los racimos de cristal (igual en las tres versiones y en la textura): [(anillo, alfa, t, grande,
    semilla)]. Irregulares: de uno a tres por anillo, con cinco racimos grandes a lo largo del lomo."""
    rnd = random.Random(41)
    lista = []
    for k in ALETAS:
        grande = k in (3, 6, 9, 12, 15)
        n = 1 + (1 if grande else 0) + (1 if rnd.random() < 0.35 else 0)
        for c in range(n):
            alfa = 0.0 if (grande and c == 0) else max(-1.25, min(1.25, rnd.gauss(0.0, 0.55)))
            lista.append((k, alfa, rnd.uniform(0.2, 0.8), grande and c == 0, rnd.random()))
    return lista


def cristal(M, base, eje, ancho, alto, lados, hueso, giro, color=VIDRIO_C):
    """Un cristal de vidrio fundido: prisma que se afila en punta (la terminación de un cristal)."""
    eje = eje.normalized()
    ref = Vector((0.0, 1.0, 0.0)) if abs(eje.y) < 0.9 else Vector((1.0, 0.0, 0.0))
    u = eje.cross(ref).normalized()
    w = eje.cross(u).normalized()
    neutro = en_atlas(AT_NEUTRO, 0.5, 0.5)
    anillos = []
    for h, f, c in ((-0.3, 1.0, VIDRIO_HONDO), (0.66, 0.9, mezcla(VIDRIO_HONDO, color, 0.7))):
        anillos.append([M.vert(base + eje * (h * alto) + (u * math.cos(giro + 2 * math.pi * i / lados) +
                                                           w * math.sin(giro + 2 * math.pi * i / lados)) * ancho * f,
                               c, neutro, hueso) for i in range(lados)])
    centro = base + eje * alto * 0.3
    rejilla(M, anillos, VIDRIO, cerrar_u=True, fuera=lambda c: centro)
    punta = M.vert(base + eje * alto, mezcla(color, (1, 1, 1), 0.55), neutro, hueso)
    for i in range(lados):
        M.cara((anillos[1][i], anillos[1][(i + 1) % lados], punta), VIDRIO, fuera=lambda c: centro)





def crear_racimos(M):
    """Racimos de cristal que brotan entre las placas: uno grande en el centro y otros pequeños alrededor, abiertos hacia
    fuera e inclinados hacia la cola, de tamaños y colores distintos."""
    for (k, alfa, t, principal, sem) in disposicion_racimos():
        rr = random.Random(int(sem * 1e6))
        rm = radio((k - 0.5) * LSEG)
        s = (k - 1 + 0.04 + t * 1.06) * LSEG
        x, z = seccion(alfa, rm * 1.06)
        base = Vector((x, s, z))
        n = Vector((x, 0.0, z)).normalized()
        t1 = n.cross(Vector((0.0, 1.0, 0.0))).normalized()
        t2 = Vector((0.0, 1.0, 0.0))
        eje0 = (n * math.cos(0.5) + t2 * math.sin(0.5)).normalized()
        m = Q["cr"][1] if principal else Q["cr"][0]
        for i in range(7):
            a = rr.uniform(0, 2 * math.pi)
            if i == 0:
                h = rm * (rr.uniform(1.05, 1.45) if principal else rr.uniform(0.5, 0.9))
                off = 0.0
            else:
                h = rm * rr.uniform(0.25, 0.7) * (1.25 if principal else 1.0)
                off = rm * rr.uniform(0.14, 0.4)
            ancho = h * rr.uniform(0.12, 0.2)
            lado = t1 * math.cos(a) + t2 * math.sin(a)
            eje = (eje0 + lado * rr.uniform(0.2, 0.65)).normalized()
            color = rr.choice([VIDRIO_C, (0.42, 0.88, 0.95), (0.70, 0.97, 1.0), (0.30, 0.75, 0.90)])
            giro = rr.uniform(0, 2 * math.pi)
            if i < m:
                cristal(M, base + lado * off, eje, ancho, h, Q["cr_lados"], placa_nombre(k), giro, color)


def crear_ganchos(M):
    """Espolones de queratina en los costados (empujan en la arena): ganchos cortos hacia la cola."""
    neutro = en_atlas(AT_NEUTRO, 0.5, 0.5)
    for k in range(2, NSEG):
        rm = radio((k - 0.5) * LSEG)
        for lado in (-1, 1):
            alfa = lado * math.radians(112)
            s = (k - 0.45) * LSEG
            x, z = seccion(alfa, rm * 0.98)
            base = Vector((x, s, z))
            dir1 = Vector((lado * 0.55, 0.75, -0.38)).normalized()
            dir2 = Vector((lado * 0.25, 0.92, -0.05)).normalized()
            largo, r0 = rm * 0.42, rm * 0.10
            lado_v = dir1.cross(Vector((0, 0, 1))).normalized()
            arr = lado_v.cross(dir1).normalized()
            hueso = col_nombre(k)
            anillos = []
            for (p, r, c) in ((base - dir1 * 0.1, r0, QUERATINA),
                              (base + dir1 * largo * 0.55, r0 * 0.6, mezcla(QUERATINA, DIENTE, 0.25))):
                anillos.append([M.vert(p + (lado_v * math.cos(2 * math.pi * i / 5) + arr * math.sin(2 * math.pi * i / 5)) * r,
                                       c, neutro, hueso) for i in range(5)])
            eje = lambda c, b=base, d=dir1: b + d * max(0.0, (c - b).dot(d))
            rejilla(M, anillos, PIEL, cerrar_u=True, fuera=eje)
            tip = M.vert(base + dir1 * largo * 0.55 + dir2 * largo * 0.55, mezcla(QUERATINA, DIENTE, 0.6), neutro, hueso)
            f = anillos[1]
            for i in range(5):
                M.cara((f[i], f[(i + 1) % 5], tip), PIEL, fuera=lambda c, b=base + dir1 * largo * 0.4: b)


# ---------------------------------------------------------------- la cabeza (variante A: el arado)

def craneo_param(y):
    tabla = lambda i: [(-c[0], c[i]) for c in CRANEO]
    return catmull(tabla(1), -y), catmull(tabla(2), -y), catmull(tabla(3), -y)


def punto_craneo(fi, y):
    w, zb, h = craneo_param(y)
    x = w * math.sin(fi)
    z = zb + h * max(0.0, math.cos(fi)) ** 0.75
    hacia_hocico = suave(-2.2, -3.1, y)
    z += (0.11 * math.exp(-(x / 0.3) ** 2) + 0.07 * math.exp(-((abs(x) - 0.95) / 0.2) ** 2)) * (1 - hacia_hocico) \
        * max(0.0, math.cos(fi)) ** 0.5
    z += 0.08 * math.exp(-((abs(x) - 1.3) / 0.25) ** 2 - ((y + 1.5) / 0.5) ** 2)                   # cejas de piedra
    z += 0.035 * noise.noise(Vector((x * 1.7, y * 1.7, 3.3)))
    return Vector((x, y, z))


def crear_craneo(M):
    nsec, nl = Q["cab_sec"], Q["cab_lados"]
    dentro = lambda c: (0.0, c.y, -0.15)
    filas = []
    for i in range(nsec):
        y = Y_NUCA + (Y_HOCICO - Y_NUCA) * i / (nsec - 1)
        fila = []
        for j in range(nl + 1):
            fi = -math.pi / 2 + math.pi * j / nl
            p = punto_craneo(fi, y)
            ao = 1.0 - 0.25 * suave(0.7, 0.95, y) - 0.22 * suave(0.6, 1.0, abs(math.sin(fi))) * (1 - suave(-1.0, -2.8, y))
            uv = en_atlas(AT_CRANEO, j / nl, (Y_NUCA - y) / (Y_NUCA - Y_HOCICO))
            fila.append(M.vert(p, (ao, ao, ao, 0.7), uv, "cabeza"))
        filas.append(fila)
    rejilla(M, filas, PIEL, fuera=dentro)
    # el labio de la cuchilla (cuelga algo por delante y por debajo) y el paladar
    w, zb, h = craneo_param(Y_HOCICO)
    labio = []
    for j in range(nl + 1):
        fi = -math.pi / 2 + math.pi * j / nl
        p = Vector((w * 0.99 * math.sin(fi), Y_HOCICO - 0.1, zb - 0.13 + 0.05 * math.cos(fi)))
        labio.append(M.vert(p, (0.55, 0.55, 0.58, 0.8), en_atlas(AT_CRANEO, j / nl, 0.97), "cabeza"))
    rejilla(M, [filas[-1], labio], PIEL, fuera=lambda c: (0.0, c.y + 0.6, -0.1))
    paladar = []
    for y in [Y_HOCICO + 0.12, -2.4, -1.7, -1.0, -0.62]:
        w, zb, h = craneo_param(y)
        fila = []
        for j in range(nl + 1):
            fi = -math.pi / 2 + math.pi * j / nl
            prof = suave(-2.8, -0.6, y)
            c = mezcla((0.55, 0.5, 0.5), (0.18, 0.14, 0.14), prof)
            fila.append(M.vert(((w - 0.08) * math.sin(fi), y, zb - 0.02 - 0.06 * math.cos(fi)), c,
                               en_atlas(AT_CARNE, j / nl, 0.5 + 0.5 * (1 - prof)), "cabeza"))
        paladar.append(fila)
    rejilla(M, [labio] + paladar, PIEL, hacia=lambda c: (0.0, c.y, -1.5))
    # los lados, por debajo: del canto de la boca al paladar
    for col in (0, nl):
        canto = [filas[i][col] for i in range(nsec)]
        lado = -1 if col == 0 else 1
        pts = []
        for i in range(nsec):
            y = Y_NUCA + (Y_HOCICO - Y_NUCA) * i / (nsec - 1)
            w, zb, h = craneo_param(y)
            pts.append(M.vert((lado * (w - 0.1), y, zb - 0.06), (0.4, 0.4, 0.4), M.uv[canto[i]], "cabeza"))
        for i in range(nsec - 1):
            M.cara((canto[i], canto[i + 1], pts[i + 1], pts[i]), PIEL, fuera=lambda c: (0.0, c.y, 0.4))


def crear_ojos(M):
    neutro = en_atlas(AT_NEUTRO, 0.5, 0.5)
    for (fi, y, r) in OJOS:
        for lado in (-1, 1):
            p = punto_craneo(lado * fi, y)
            n = (p - Vector((0, y, -0.2))).normalized()
            lado_v = n.cross(Vector((0, 1, 0))).normalized()
            arr = lado_v.cross(n).normalized()
            centro = M.vert(p + n * r * 0.55, mezcla(VIDRIO_C, (1, 1, 1), 0.4), neutro, "cabeza")
            anillo = [M.vert(p + (lado_v * math.cos(2 * math.pi * i / 6) + arr * math.sin(2 * math.pi * i / 6)) * r - n * 0.03,
                             VIDRIO_HONDO, neutro, "cabeza") for i in range(6)]
            for i in range(6):
                M.cara((anillo[i], anillo[(i + 1) % 6], centro), VIDRIO, fuera=lambda c, q=p - n: q)


def sup_craneo(fi, y):
    p = punto_craneo(fi, y)
    return p, (p - Vector((0.0, y, -0.25))).normalized()


def uv_craneo(fi, y):
    return en_atlas(AT_CRANEO, (fi + math.pi / 2) / math.pi, (Y_NUCA - y) / (Y_NUCA - Y_HOCICO))


def placas_cabeza(M):
    """El caparazón de la cabeza: tres placas de basalto superpuestas (la frontal, en cuña hasta la cuchilla; la
    central y la de la nuca, que se abre hacia los lados, nunca hacia arriba), dos arcos superciliares gruesos sobre los
    ocelos (que quedan hundidos entre ellos y las mejillas) y las placas de las mejillas sobre la línea de la boca."""
    dentro = lambda c: (0.0, c.y, -0.3)
    b = Q["bisel"]
    alto = Q["pl_nu"][1] > 0
    placa(M, sup_craneo, -0.92, 0.92, -3.30, -1.35, 3 if alto else 2, 2 if alto else 1, 0.13, 0.12, 0.35, "cabeza",
          uv_craneo, dentro, tinte=1.0, bisel=b, profundo=0.25)
    placa(M, sup_craneo, -1.08, 1.08, -1.78, -0.15, 3 if alto else 2, 1, 0.16, 0.14, 0.38, "cabeza", uv_craneo, dentro,
          tinte=0.94, bisel=b, profundo=0.25)
    placa(M, sup_craneo, -1.32, 1.32, -0.45, 1.25, 4 if alto else 2, 1, 0.17, 0.16, 0.42, "cabeza", uv_craneo, dentro,
          tinte=1.04, bisel=b, profundo=0.25)
    for lado in (-1, 1):
        f0, f1 = sorted((lado * 0.84, lado * 1.05))
        placa(M, sup_craneo, f0, f1, -2.5, -0.95, 1, 1 if not alto else 2, 0.26, 0.04, 0.18, "cabeza", uv_craneo,
              dentro, tinte=1.1, bisel=b, profundo=0.2)
        if Q["mejillas"]:
            f0, f1 = sorted((lado * 1.27, lado * 1.57))
            placa(M, sup_craneo, f0, f1, -2.75, -0.55, 1, 2 if alto else 1, 0.11, 0.08, 0.25, "cabeza", uv_craneo,
                  dentro, tinte=0.92, bisel=b, profundo=0.2)


def mand_param(y):
    tabla = lambda i: [(-c[0], c[i]) for c in MAND]
    return catmull(tabla(1), -y), catmull(tabla(2), -y)


def crear_mandibula(M):
    nsec, nl = max(5, Q["cab_sec"] - 3), Q["cab_lados"]
    y0, y1 = MAND[0][0], MAND[-1][0]
    exterior, interior = [], []
    for i in range(nsec):
        y = y0 + (y1 - y0) * i / (nsec - 1)
        w, hp = mand_param(y)
        fe, fi_ = [], []
        for j in range(nl + 1):
            fi = -math.pi / 2 + math.pi * j / nl
            x = w * math.sin(fi) + 0.03 * noise.noise(Vector((fi, y, 7.1)))
            z = ZB_MAND - hp * max(0.0, math.cos(fi)) ** 0.85 - 0.05 * math.exp(-((y + 1.5) / 0.8) ** 2) * math.cos(fi)
            ao = 1.0 - 0.3 * suave(0.0, 0.12, y)
            fe.append(M.vert((x, y, z), (ao, ao, ao), en_atlas(AT_MANDIBULA, j / nl, (y0 - y) / (y0 - y1)), "mandibula"))
            xi = (w - 0.17) * math.sin(fi)
            zi = ZB_MAND - 0.12 - max(0.05, hp - 0.36) * max(0.0, math.cos(fi)) ** 0.9
            prof = suave(-2.9, -0.4, y)
            c = mezcla((0.6, 0.52, 0.5), (0.2, 0.15, 0.15), prof)
            fi_.append(M.vert((xi, y, zi), c, en_atlas(AT_CARNE, j / nl, 0.1 + 0.4 * (1 - prof)), "mandibula"))
        exterior.append(fe)
        interior.append(fi_)
    rejilla(M, exterior, PIEL, fuera=lambda c: (0.0, c.y, ZB_MAND - 0.25))
    rejilla(M, interior, PIEL, hacia=lambda c: (0.0, c.y, ZB_MAND + 0.8))
    arriba = lambda c: (c.x, c.y, c.z + 1.0)
    for col in (0, nl):
        for i in range(nsec - 1):
            M.cara((exterior[i][col], exterior[i + 1][col], interior[i + 1][col], interior[i][col]), PIEL, hacia=arriba)
    fe, fi_ = exterior[-1], interior[-1]
    for j in range(nl):
        M.cara((fe[j], fe[j + 1], fi_[j + 1], fi_[j]), PIEL, hacia=lambda c: (c.x, c.y - 1.0, c.z + 0.6))
    c = M.vert((0, y0 + 0.05, ZB_MAND - 0.3), (0.3, 0.3, 0.3), en_atlas(AT_CARNE, 0.5, 0.1), "mandibula")
    for j in range(nl):
        M.cara((exterior[0][j + 1], exterior[0][j], c), PIEL, hacia=lambda q: (0.0, y0 + 2.0, ZB_MAND - 0.3))


def diente(M, base, arriba, adelante, ancho, largo, grosor, hueso, color=DIENTE):
    """Diente de cincel: una cuña plana y ancha (raspa y corta el vidrio; no un colmillo)."""
    up = arriba.normalized()
    lado = adelante.cross(up).normalized()
    adel = up.cross(lado).normalized()
    b = [base + lado * sx * ancho * 0.5 + adel * sy * grosor * 0.5 - up * 0.08 for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    filo = [base + up * largo + lado * sx * ancho * 0.42 + adel * grosor * 0.15 for sx in (-1, 1)]
    centro = base + up * largo * 0.35
    fuera = lambda c: centro
    neutro = en_atlas(AT_NEUTRO, 0.5, 0.5)
    cb = mezcla(color, DIENTE_OSC, 0.5)
    iv = [M.vert(p, cb, neutro, hueso) for p in b]
    fv = [M.vert(p, color, neutro, hueso) for p in filo]
    M.cara((iv[0], iv[1], fv[1], fv[0]), PIEL, fuera=fuera)
    M.cara((iv[2], iv[3], fv[0], fv[1]), PIEL, fuera=fuera)
    M.cara((iv[1], iv[2], fv[1]), PIEL, fuera=fuera)
    M.cara((iv[3], iv[0], fv[0]), PIEL, fuera=fuera)


def muela(M, centro, arriba, ancho, largo, alto, hueso):
    """Placa de moler: losa baja con tres crestas de través."""
    up = arriba.normalized()
    lado = Vector((1, 0, 0))
    adel = up.cross(lado).normalized()
    neutro = en_atlas(AT_NEUTRO, 0.5, 0.5)
    filas = []
    for i in range(7):
        t = i / 6
        h = 0.0 if i in (0, 6) else alto * (1.0 if i % 2 == 1 else 0.55)
        filas.append([M.vert(centro + lado * sx * ancho * 0.5 + adel * (t - 0.5) * largo + up * h,
                             mezcla(MUELA, (0.5, 0.48, 0.42), 0.0 if i % 2 else 0.4), neutro, hueso) for sx in (-1, 1)])
    rejilla(M, filas, PIEL, hacia=lambda c: c + up)


def colmillo(M, base, dir_, curva, largo, grueso, lados, hueso, vidrio=False, color=None, rnd=None):
    """Un colmillo curvo que se afila (de hueso o de cristal): el eje se dobla hacia «curva»."""
    dir_ = dir_.normalized()
    centro = lambda t: base + dir_ * largo * t + curva * largo * 0.38 * t * t
    ref = Vector((1.0, 0.0, 0.0)) if abs(dir_.x) < 0.8 else Vector((0.0, 1.0, 0.0))
    u = dir_.cross(ref).normalized()
    w = dir_.cross(u).normalized()
    neutro = en_atlas(AT_NEUTRO, 0.5, 0.5)
    if color is None:
        color = (rnd or random).choice(HUESO_DIENTE)
    mat = VIDRIO if vidrio else PIEL
    c_base = VIDRIO_HONDO if vidrio else mezcla(color, (0.35, 0.3, 0.26), 0.55)
    c_med = mezcla(VIDRIO_HONDO, VIDRIO_C, 0.6) if vidrio else color
    anillos = []
    for t, f, c in ((-0.12, 1.0, c_base), (0.45, 0.62, c_med)):
        anillos.append([M.vert(centro(t) + (u * math.cos(2 * math.pi * i / lados) + w * math.sin(2 * math.pi * i / lados))
                               * grueso * f, c + ((0.5,) if not vidrio else ()), neutro, hueso) for i in range(lados)])
    eje = lambda c: centro(max(-0.12, min(1.0, (c - base).dot(dir_) / largo)))
    rejilla(M, anillos, mat, cerrar_u=True, fuera=eje)
    punta = M.vert(centro(1.0), (mezcla(VIDRIO_C, (1, 1, 1), 0.6) if vidrio else mezcla(color, (1, 1, 1), 0.3)) +
                   ((0.5,) if not vidrio else ()), neutro, hueso)
    for i in range(lados):
        M.cara((anillos[1][i], anillos[1][(i + 1) % lados], punta), mat, fuera=lambda c: centro(0.6))


def crear_boca(M):
    """Dos filas de dientes irregulares (más una interior en el alto): colmillos de hueso y de cristal de tamaños
    distintos, curvados hacia dentro y atrás, con dos grandes colmillos en cada esquina de la boca. Los de arriba
    cuelgan por fuera de la mandíbula (se ven con la boca cerrada); los de delante, abajo, salen como defensas."""
    rnd = random.Random(77)
    lados = Q["d_lados"]
    arr_lado, arr_frente, aba_lado, aba_frente, interior = Q["dientes"]
    for sx in (-1, 1):
        for i in range(arr_lado):                                    # arriba, a los lados
            y = -1.0 - 1.75 * (i + rnd.uniform(-0.25, 0.25)) / max(1, arr_lado - 1)
            w, zb, h = craneo_param(y)
            colmillo(M, Vector((sx * (w - 0.04), y, zb - 0.02)), Vector((sx * 0.12, 0.0, -1.0)),
                     Vector((-sx * 0.45, 0.6, 0.0)), rnd.uniform(0.28, 0.55), rnd.uniform(0.06, 0.1), lados, "cabeza",
                     vidrio=rnd.random() < 0.3, rnd=rnd)
        for i in range(aba_lado):                                    # abajo, a los lados
            y = -1.05 - 1.85 * (i + rnd.uniform(-0.25, 0.25)) / max(1, aba_lado - 1)
            wj, hp = mand_param(y)
            colmillo(M, Vector((sx * (wj - 0.1), y, ZB_MAND - 0.02)), Vector((sx * 0.1, 0.0, 1.0)),
                     Vector((-sx * 0.45, 0.6, 0.0)), rnd.uniform(0.25, 0.5), rnd.uniform(0.06, 0.09), lados,
                     "mandibula", vidrio=rnd.random() < 0.35, rnd=rnd)
        w, zb, h = craneo_param(-2.75)                               # los grandes colmillos de las esquinas
        colmillo(M, Vector((sx * (w - 0.3), -2.75, zb - 0.02)), Vector((sx * 0.08, -0.15, -1.0)),
                 Vector((-sx * 0.35, 0.75, 0.0)), 0.95, 0.15, lados, "cabeza", rnd=rnd)
        wj, hp = mand_param(-2.85)
        colmillo(M, Vector((sx * (wj - 0.32), -2.85, ZB_MAND - 0.02)), Vector((sx * 0.1, -0.3, 1.0)),
                 Vector((-sx * 0.3, 0.7, 0.0)), 0.8, 0.13, lados, "mandibula", vidrio=True, rnd=rnd)
    w, zb, h = craneo_param(-3.0)
    for i in range(arr_frente):                                      # arriba, delante
        x = (i - (arr_frente - 1) / 2) * (2 * (w - 0.38)) / max(1, arr_frente - 1) + rnd.uniform(-0.05, 0.05)
        colmillo(M, Vector((x, -3.0, zb - 0.04)), Vector((0.0, -0.2, -1.0)), Vector((-x * 0.3, 0.7, 0.0)),
                 rnd.uniform(0.3, 0.55), rnd.uniform(0.06, 0.1), lados, "cabeza", vidrio=rnd.random() < 0.25, rnd=rnd)
    wj, hp = mand_param(-3.12)
    for i in range(aba_frente):                                      # abajo, delante: defensas hacia fuera
        x = (i - (aba_frente - 1) / 2) * (2 * (wj - 0.4)) / max(1, aba_frente - 1)
        colmillo(M, Vector((x, -3.12, ZB_MAND - 0.04)), Vector((0.0, -0.55, 1.0)), Vector((-x * 0.3, 0.6, 0.0)),
                 rnd.uniform(0.4, 0.62), rnd.uniform(0.08, 0.11), lados, "mandibula", vidrio=rnd.random() < 0.4, rnd=rnd)
    for i in range(interior):                                        # una fila interior, más pequeña
        y = -1.3 - 1.5 * i / max(1, interior - 1)
        sx = -1 if i % 2 else 1
        wj, hp = mand_param(y)
        colmillo(M, Vector((sx * (wj - 0.42), y, ZB_MAND - 0.2)), Vector((0.0, 0.1, 1.0)), Vector((-sx * 0.3, 0.6, 0.0)),
                 rnd.uniform(0.18, 0.32), 0.06, lados, "mandibula", vidrio=rnd.random() < 0.5, rnd=rnd)


def puntos_mandibula_lateral(lado):
    n = 6
    return [Vector((lado * (1.78 + 0.22 * math.sin(math.pi * min(1.0, t * 1.25)) - 0.8 * t ** 3), -0.4 - 2.95 * t,
                    -1.16 + 0.32 * t)) for t in (i / n for i in range(n + 1))]


def mandibula_lateral(M, lado):
    """Una mandíbula lateral (a cada lado de la de abajo): una hoja curva de basalto que corre por el costado y se
    cierra en gancho delante de la boca, con púas de cristal por dentro. Al rugir se abre hacia fuera (su hueso)."""
    hueso = "mandibula_izq" if lado > 0 else "mandibula_der"
    pts = puntos_mandibula_lateral(lado)
    lados = Q["lat_lados"]
    filas = []
    for i, p in enumerate(pts[:-1]):
        t = i / (len(pts) - 1)
        r = 0.27 * (1 - t) ** 0.75 + 0.035
        d = (pts[i + 1] - p).normalized()
        lat = (Vector((lado, 0.0, 0.0)) - d * d.x * lado).normalized()
        arr = d.cross(lat).normalized() * lado
        fila = []
        for j in range(lados):
            a = 2 * math.pi * j / lados
            c = 0.7 + 0.28 * t
            fila.append(M.vert(p + lat * math.cos(a) * r * 0.55 + arr * math.sin(a) * r, (c, c, c * 1.03, 1.0),
                               en_atlas(AT_MANDIBULA, 0.5 + 0.35 * math.cos(a), 0.15 + 0.7 * t), hueso))
        filas.append(fila)
    eje = lambda c: min(pts, key=lambda q: (q - c).length)
    rejilla(M, filas, PIEL, cerrar_u=True, fuera=eje)
    punta = M.vert(pts[-1], (0.95, 0.95, 0.98, 1.0), en_atlas(AT_MANDIBULA, 0.5, 0.95), hueso)
    for j in range(lados):
        M.cara((filas[-1][j], filas[-1][(j + 1) % lados], punta), PIEL, fuera=lambda c: pts[-2])
    c0 = M.vert(pts[0] + Vector((0, 0.15, 0)), (0.5, 0.5, 0.5, 1.0), en_atlas(AT_MANDIBULA, 0.5, 0.1), hueso)
    for j in range(lados):
        M.cara((filas[0][(j + 1) % lados], filas[0][j], c0), PIEL, fuera=lambda c: pts[1])
    n = Q["lat_puas"]
    for i in range(n):
        t = 0.3 + 0.5 * i / max(1, n - 1)
        k = t * (len(pts) - 1)
        a0 = int(k)
        p = pts[a0].lerp(pts[min(a0 + 1, len(pts) - 1)], k - a0)
        dentro = Vector((-lado, 0.1, 0.35)).normalized()
        cristal(M, p + dentro * 0.08, dentro, 0.05, 0.22 + 0.08 * (i % 2), 4, hueso, 0.3 * i)


def crear_garganta(M):
    """La pared del fondo de la boca con el agujero de la garganta, el túnel oscuro y la luz al fondo."""
    centro = Vector((0, -0.62, -0.62))
    n_ang = max(8, Q["cab_lados"])
    rin = 0.56
    pared_in, pared_out = [], []
    for i in range(n_ang):
        a = 2 * math.pi * i / n_ang
        dx, dz = math.sin(a), math.cos(a)
        abajo = suave(0.1, -0.9, dz)
        w = {"cabeza": 1 - abajo, "mandibula": abajo} if abajo > 0.01 else {"cabeza": 1.0}
        pared_in.append(M.vert(centro + Vector((dx * rin, 0, dz * rin)), (0.1, 0.07, 0.07),
                               en_atlas(AT_CARNE, i / n_ang, 0.05), w))
        pared_out.append(M.vert(centro + Vector((dx * 1.38, 0.02, dz * (0.24 if dz > 0 else 0.95))), (0.32, 0.24, 0.23),
                                en_atlas(AT_CARNE, i / n_ang, 0.15), w))
    delante = lambda c: (c.x, c.y - 1.0, c.z)
    for i in range(n_ang):
        i2 = (i + 1) % n_ang
        M.cara((pared_out[i], pared_out[i2], pared_in[i2], pared_in[i]), PIEL, hacia=delante)
    # el túnel lleva el material de la garganta con un degradado hacia dentro: casi negro en reposo (hueso «garganta»
    # a 0,35) y encendido al aspirar (2,6); así la luz se ve también desde el lado, no solo desde delante
    borde_luz = [M.vert(M.v[pared_in[i]], (0.06, 0.08, 0.09), (0.5, 0.5), M.pesos[pared_in[i]]) for i in range(n_ang)]
    anillos = [borde_luz]
    pasos = [(0.4, 0.5, -0.5, 0.25), (1.1, 0.45, -0.38, 0.55), (1.8, 0.42, -0.25, 0.85)]
    for (y, r, z, c) in pasos:
        anillos.append([M.vert((math.sin(2 * math.pi * i / n_ang) * r, y, z + math.cos(2 * math.pi * i / n_ang) * r),
                               (c * 0.8, c, c), (0.5, 0.5), peso_columna(y))
                        for i in range(n_ang)])
    eje = lambda c: (0.0, c.y, -0.62 + (c.y + 0.62) * 0.15)
    rejilla(M, anillos, GARGANTA, cerrar_u=True, hacia=eje)
    y, r, z, _ = pasos[-1]
    ult = anillos[-1]
    luz_borde = ult
    luz_c = M.vert((0, y + 0.05, z), (1.0, 1.0, 1.0), (0.5, 0.5), peso_columna(y))
    for i in range(n_ang):
        M.cara((luz_borde[i], luz_borde[(i + 1) % n_ang], luz_c), GARGANTA, hacia=delante)
    # anillos de placas que muelen hacia dentro (se encienden con la garganta: se ven al cargar el aliento)
    tabla = [(-0.62, 0.56, -0.62)] + [(p[0], p[1], p[2]) for p in pasos]
    nr, por = Q["anillos_g"]
    for a_i in range(nr):
        y = [0.15, 0.75, 1.35][a_i]
        r = float(np.interp(y, [q[0] for q in tabla], [q[1] for q in tabla]))
        z = float(np.interp(y, [q[0] for q in tabla], [q[2] for q in tabla]))
        for i in range(por):
            a = 2 * math.pi * (i + 0.5 * a_i) / por
            d1 = Vector((math.sin(a - 0.22), 0.0, math.cos(a - 0.22)))
            d2 = Vector((math.sin(a + 0.22), 0.0, math.cos(a + 0.22)))
            dm = Vector((math.sin(a), 0.0, math.cos(a)))
            cz = Vector((0.0, y, z))
            w = peso_columna(y)
            v1 = M.vert(cz + d1 * r * 0.98, (0.3, 0.42, 0.45), (0.5, 0.5), w)
            v2 = M.vert(cz + d2 * r * 0.98, (0.3, 0.42, 0.45), (0.5, 0.5), w)
            v3 = M.vert(cz + dm * r * 0.5 + Vector((0.0, -0.12, 0.0)), (0.75, 1.0, 1.0), (0.5, 0.5), w)
            v4 = M.vert(cz + dm * r * 0.98 + Vector((0.0, 0.16, 0.0)), (0.25, 0.35, 0.38), (0.5, 0.5), w)
            M.cara((v1, v2, v3), GARGANTA, hacia=lambda c: (c.x, c.y - 1.0, c.z))
            M.cara((v2, v1, v4, v3), GARGANTA, hacia=lambda c, q=cz: q)


def crear_membranas(M):
    """Piel de las mejillas, entre el canto del cráneo y el de la mandíbula: se estira al abrir la boca."""
    ys = [-0.2, -0.55, -0.9, -1.25, -1.55]
    for lado in (-1, 1):
        filas = []
        for k, peso in enumerate((0.0, 0.5, 1.0)):
            fila = []
            for y in ys:
                w, zb, h = craneo_param(y)
                wj, hp = mand_param(y)
                x = lado * ((w - 0.12) * (1 - peso) + (wj - 0.08) * peso) * (0.97 if k == 1 else 1.0)
                z = (zb - 0.02) * (1 - peso) + (ZB_MAND - 0.02) * peso
                if y < -1.3:
                    pesos = {"cabeza": 1.0} if peso < 0.5 else {"mandibula": 1.0}
                elif 0 < peso < 1:
                    pesos = {"cabeza": 1 - peso, "mandibula": peso}
                else:
                    pesos = {"cabeza" if peso == 0 else "mandibula": 1.0}
                fila.append(M.vert((x, y, z), (0.35, 0.25, 0.24),
                                   en_atlas(AT_CARNE, 0.2 + 0.6 * peso, 0.3 + 0.4 * suave(-1.55, -0.2, y)), pesos))
            filas.append(fila)
        rejilla(M, filas, PIEL, fuera=lambda c: (0.0, c.y, c.z))
        rejilla(M, filas, PIEL, hacia=lambda c: (0.0, c.y, c.z))     # por las dos caras (se ve desde dentro)


# ---------------------------------------------------------------- variantes de cabeza (solo para los bocetos)

def cabeza_maza(M):
    """Variante B, la maza: una cabeza bulbosa y acorazada con la boca por debajo (descartada)."""
    n = 16
    filas = []
    for i in range(n + 1):
        th = math.pi * i / n
        fila = []
        for j in range(n + 1):
            ph = 2 * math.pi * j / n
            fila.append(M.vert((math.sin(th) * math.cos(ph) * 2.0, -1.4 - math.cos(th) * 2.4, 0.3 + math.sin(th) * math.sin(ph) * 1.9),
                               (1, 1, 1), (0.5, 0.5), "cabeza"))
        filas.append(fila)
    rejilla(M, filas, PIEL, fuera=lambda c: (0, -1.4, 0.3))
    for j in range(5):
        diente(M, Vector(((j - 2) * 0.4, -2.6, -1.4)), Vector((0, 0, -1)), Vector((0, -1, 0)), 0.3, 0.5, 0.15, "mandibula")


def cabeza_pico(M):
    """Variante C, el pico de prensa: dos losas largas y estrechas que muerden como una tenaza (descartada)."""
    for hueso, signo in (("cabeza", 1), ("mandibula", -1)):
        filas = []
        for i in range(9):
            t = i / 8
            y = 0.6 - t * 4.6
            w = 1.3 * (1 - t * 0.75)
            h = 1.2 * (1 - t * 0.6)
            fila = []
            for j in range(9):
                fi = -math.pi / 2 + math.pi * j / 8
                z = -0.4 + signo * (0.05 + h * math.cos(fi))
                if signo > 0 and t > 0.85:
                    z -= (t - 0.85) * 4.0
                fila.append(M.vert((w * math.sin(fi), y, z), (1, 1, 1), (0.5, 0.5), hueso))
            filas.append(fila)
        rejilla(M, filas, PIEL, fuera=lambda c: (0, c.y, -0.4))


def construir(nombre_q):
    global Q
    Q = CALIDAD[nombre_q]
    M = Malla()
    crear_tubo(M)
    crear_placas(M)
    crear_racimos(M)
    if Q["ganchos"]:
        crear_ganchos(M)
    i0 = len(M.v)
    if VARIANTE == "B":
        cabeza_maza(M)
    elif VARIANTE == "C":
        cabeza_pico(M)
    else:
        crear_craneo(M)
        placas_cabeza(M)
        crear_ojos(M)
        crear_mandibula(M)
        crear_boca(M)
        for lado in (-1, 1):
            mandibula_lateral(M, lado)
        crear_garganta(M)
        crear_membranas(M)
    for i in range(i0, len(M.v)):                                     # la cabeza se modela a escala 1 y se agranda
        M.v[i] = M.v[i] * K_CAB
    if VARIANTE != "A":
        return M
    crear_monticulo(M)
    crear_chorro(M)
    return M


def crear_monticulo(M):
    n = Q["mont"]
    radios = [1.15, 1.6, 2.3, 3.1, 4.2]
    filas = []
    for i, r in enumerate(radios):
        fila = []
        for j in range(n + 1):
            a = 2 * math.pi * j / n
            g = 0.75 + 0.5 * (noise.noise(Vector((math.cos(a) * 1.6, math.sin(a) * 1.6, 0.4))) * 0.5 + 0.5)
            alto = [-0.55, 0.15, 0.62, 0.32, -0.02][i] * g
            rr = r * (0.92 + 0.16 * noise.noise(Vector((math.cos(a) * 2.2, math.sin(a) * 2.2, 1.7))))
            c = [0.42, 0.62, 0.95, 0.9, 0.85][i]
            fila.append(M.vert((math.cos(a) * rr, math.sin(a) * rr, alto), (c, c * 0.97, c * 0.94),
                               en_atlas(AT_ARENA, j / n, i / 4), "monticulo"))
        filas.append(fila)
    rejilla(M, filas, ARENA, hacia=lambda c: (c.x, c.y, c.z + 2.0))


def crear_chorro(M):
    n = Q["chorro"]
    for capa, pasos, giro in ((0, [(0.0, 0.25, 1.0), (0.12, 0.55, 1.0), (0.35, 0.95, 0.9), (0.65, 1.35, 0.6), (1.0, 1.75, 0.0)], 0.0),
                              (1, [(0.0, 0.12, 1.0), (0.5, 0.45, 1.0), (0.95, 0.7, 0.0)], 0.3)):
        anillos = []
        for (t, r, a) in pasos:
            fila = []
            for i in range(n + 1):
                ang = 2 * math.pi * i / n + giro
                p = CHORRO_BASE * K_CAB + Vector((math.sin(ang) * r, -t * CHORRO_LARGO, math.cos(ang) * r * 0.85))
                fila.append(M.vert(p, (0.75, 0.97, 1.0, a) if capa == 0 else (1.0, 1.0, 1.0, a), (i / n, t), "chorro"))
            anillos.append(fila)
        rejilla(M, anillos, CHORRO, fuera=lambda c: (0.0, c.y, CHORRO_BASE.z * K_CAB))


# ---------------------------------------------------------------- la textura (pintada con numpy)

TEX = 2048
ALFA_MIN = 0.04


def ruido_valor(alto, ancho, cy, cx, semilla, envolver=False):
    rng = np.random.default_rng(semilla)
    g = rng.random((cy + 2, cx + 2))
    if envolver:
        g[:, cx] = g[:, 0]
        g[:, cx + 1] = g[:, 1]
    ys = np.linspace(0, cy, alto, endpoint=False)
    xs = np.linspace(0, cx, ancho, endpoint=False)
    y0, x0 = np.floor(ys).astype(int), np.floor(xs).astype(int)
    ty, tx = ys - y0, xs - x0
    ty, tx = ty * ty * (3 - 2 * ty), tx * tx * (3 - 2 * tx)
    a = g[np.ix_(y0, x0)]
    b = g[np.ix_(y0, x0 + 1)]
    c = g[np.ix_(y0 + 1, x0)]
    d = g[np.ix_(y0 + 1, x0 + 1)]
    tx, ty = tx[None, :], ty[:, None]
    return (a * (1 - tx) + b * tx) * (1 - ty) + (c * (1 - tx) + d * tx) * ty


def fbm(alto, ancho, cy, cx, semilla, octavas=4, envolver=False):
    r = np.zeros((alto, ancho))
    amp, total = 1.0, 0.0
    for o in range(octavas):
        r += amp * ruido_valor(alto, ancho, cy * 2 ** o, cx * 2 ** o, semilla + o * 17, envolver)
        total += amp
        amp *= 0.5
    return r / total


def mezclar_color(base, color, peso):
    peso = np.clip(peso, 0, 1)[..., None]
    return base * (1 - peso) + np.array(color)[None, None, :] * peso


def trazos(alto, ancho, lineas, grosor):
    """Distancia (en píxeles) de cada píxel a la polilínea más cercana: lineas = [[(x, y), …], …] en píxeles."""
    d = np.full((alto, ancho), 1e9)
    for pts in lineas:
        for (x0, y0), (x1, y1) in zip(pts[:-1], pts[1:]):
            mx0, mx1 = int(max(0, min(x0, x1) - grosor - 2)), int(min(ancho, max(x0, x1) + grosor + 3))
            my0, my1 = int(max(0, min(y0, y1) - grosor - 2)), int(min(alto, max(y0, y1) + grosor + 3))
            if mx1 <= mx0 or my1 <= my0:
                continue
            yy, xx = np.mgrid[my0:my1, mx0:mx1]
            vx, vy = x1 - x0, y1 - y0
            l2 = vx * vx + vy * vy + 1e-9
            t = np.clip(((xx - x0) * vx + (yy - y0) * vy) / l2, 0, 1)
            dd = np.hypot(xx - (x0 + t * vx), yy - (y0 + t * vy))
            d[my0:my1, mx0:mx1] = np.minimum(d[my0:my1, mx0:mx1], dd)
    return d


def grieta(rng, x, y, paso, n, dir0, giro=0.5):
    pts = [(x, y)]
    a = dir0
    for i in range(n):
        a += rng.uniform(-giro, giro)
        x += math.cos(a) * paso * rng.uniform(0.6, 1.2)
        y += math.sin(a) * paso * rng.uniform(0.6, 1.2)
        pts.append((x, y))
    return pts


def pintar_grietas(rgb, brillo, rng, n, ancho_px, alto_px, paso, largo, con_luz=0.5, oscuro=(0.12, 0.1, 0.11), zona=None):
    lineas, luz = [], []
    for i in range(n):
        x, y = rng.uniform(0, ancho_px), rng.uniform(0, alto_px)
        if zona is not None and not zona(x, y):
            continue
        pts = grieta(rng, x, y, paso, largo, rng.uniform(0, 2 * math.pi))
        for r in range(rng.integers(0, 3)):
            j = rng.integers(1, len(pts))
            pts2 = grieta(rng, pts[j][0], pts[j][1], paso * 0.7, max(2, largo // 2), rng.uniform(0, 2 * math.pi))
            lineas.append(pts2)
            if rng.random() < con_luz:
                luz.append(pts2)
        lineas.append(pts)
        if rng.random() < con_luz:
            luz.append(pts)
    if not lineas:
        return
    d = trazos(alto_px, ancho_px, lineas, 3.0)
    rgb[:] = mezclar_color(rgb, oscuro, np.clip(1.6 - d / 1.2, 0, 1) * 0.9)
    rgb[:] = mezclar_color(rgb, (0.85, 0.78, 0.66), np.clip(1.0 - np.abs(d - 2.2) / 0.9, 0, 1) * 0.25)
    if luz:
        dl = trazos(alto_px, ancho_px, luz, 4.0)
        brillo[:] = np.maximum(brillo, np.clip(1.4 - dl / 1.1, 0, 1))
        rgb[:] = mezclar_color(rgb, (0.55, 0.9, 0.95), np.clip(1.0 - dl / 1.0, 0, 1) * 0.6)


# cicatrices largas que cruzan anillos (en el lomo): [(alfa, s), …]
CICATRICES = [
    [(-0.9, 3.1), (-0.5, 4.2), (-0.1, 5.4), (0.35, 6.5), (0.6, 7.3)],
    [(0.5, 9.6), (0.2, 10.4), (-0.25, 11.6), (-0.55, 12.2)],
    [(-1.4, 13.5), (-1.1, 14.6), (-0.8, 15.2)],
    [(1.2, 4.5), (1.45, 5.6), (1.7, 6.2)],
]


def pintar_textura(n_px):
    img = np.zeros((n_px, n_px, 3))
    brillo = np.zeros((n_px, n_px))
    rng = np.random.default_rng(1207)

    def region(r):
        u0, u1, v0, v1 = r
        return int(v0 * n_px), int(v1 * n_px), int(u0 * n_px), int(u1 * n_px)

    # --- el tubo (piel entre placas, flancos bajos y vientre)
    y0, y1, x0, x1 = region(AT_TUBO)
    h, w = y1 - y0, x1 - x0
    uu = (np.arange(w) + 0.5) / w
    vv = (np.arange(h) + 0.5) / h
    alfa = (-math.pi + 2 * math.pi * uu)[None, :] * np.ones((h, 1))
    s = (S_INI + vv * (L_CUERPO - S_INI))[:, None] * np.ones((1, w))
    t = np.where(s >= 0, np.mod(s / LSEG, 1.0), 0.5)
    vientre = np.clip((-np.cos(alfa) - 0.25) / 0.55, 0, 1)
    vientre = vientre * vientre * (3 - 2 * vientre)
    n1 = fbm(h, w, 40, 10, 3, 4, envolver=True)
    n2 = fbm(h, w, 160, 40, 9, 3, envolver=True)
    rgb = np.ones((h, w, 3)) * np.array((0.24, 0.19, 0.17))[None, None, :]
    rgb = mezclar_color(rgb, (0.14, 0.12, 0.13), (1 - vientre) * np.clip(np.cos(alfa) * 1.4, 0, 1))
    rgb = mezclar_color(rgb, (0.40, 0.36, 0.32), vientre)
    rgb *= (0.85 + 0.3 * n1)[..., None]
    pliegue = (0.5 + 0.5 * np.cos(2 * math.pi * t * 11)) ** 6       # el vientre, blando y estriado
    rgb *= (1 - 0.28 * pliegue * vientre)[..., None]
    surco = np.exp(-(np.minimum(t, 1 - t) / 0.05) ** 2) * (s >= 0)
    rgb = mezclar_color(rgb, (0.62, 0.49, 0.32), surco * 0.85)          # arena metida en los surcos
    brillo_t = surco * 0.6 * (1 - vientre) * np.clip((n1 - 0.35) * 2.2, 0, 1)
    rgb = mezclar_color(rgb, (0.5, 0.85, 0.9), brillo_t * 0.5)
    polvo = np.clip((n2 - 0.62) * 4, 0, 1) * (0.3 + 0.7 * vientre)
    rgb = mezclar_color(rgb, (0.86, 0.74, 0.56), polvo * 0.45)
    rgb = mezclar_color(rgb, (0.72, 0.62, 0.48), np.clip((s - 19.5) / 2.0, 0, 1) * 0.5)
    b = np.zeros((h, w))
    b[:] = brillo_t
    pintar_grietas(rgb, b, rng, 26, w, h, w * 0.012, 7, con_luz=0.4, zona=lambda x, y: True)
    img[y0:y1, x0:x1] = rgb
    brillo[y0:y1, x0:x1] = b

    # --- las placas dorsales (una banda por anillo)
    y0, y1, x0, x1 = region(AT_PLACAS)
    h, w = y1 - y0, x1 - x0
    rgb = np.zeros((h, w, 3))
    b = np.zeros((h, w))
    n1 = fbm(h, w, 60, 12, 21, 4)
    n2 = fbm(h, w, 220, 50, 22, 3)
    vetas = fbm(h, w, 18, 4, 23, 3)
    uu = (np.arange(w) + 0.5) / w
    a_n = (uu * 2 - 1)[None, :] * np.ones((h, 1))                          # -1 … 1 a lo ancho
    banda = (np.arange(h) + 0.5) / h * NSEG
    k_b = np.floor(banda)[:, None] * np.ones((1, w)) + 1
    tp = ((np.mod(banda, 1.0) - 0.04) / 0.92)[:, None] * np.ones((1, w))
    alfa_p = a_n * A_PLACA
    s_p = (k_b - 1 + 0.04 + tp * 1.06) * LSEG
    base = np.ones((h, w, 3)) * np.array((0.10, 0.11, 0.15))[None, None, :]     # basalto casi negro azulado
    base = mezclar_color(base, (0.25, 0.26, 0.31), n1)
    base = mezclar_color(base, (0.16, 0.20, 0.29), np.clip((vetas - 0.55) * 3, 0, 1) * 0.7)
    pulido = np.clip(np.cos(alfa_p), 0, 1) ** 4
    base = mezclar_color(base, (0.40, 0.41, 0.46), pulido * 0.3)
    canto = np.minimum(np.minimum(1 - np.abs(a_n), np.clip(tp, 0, 1) * 0.5), np.clip(1 - tp, 0, 1) * 0.5)
    gasto = np.clip(1 - canto / 0.05, 0, 1) * (0.55 + 0.45 * n2)
    base = mezclar_color(base, (0.42, 0.43, 0.47), gasto * 0.4)
    sombra_canto = np.exp(-((canto - 0.07) / 0.02) ** 2)
    base *= (1 - 0.25 * sombra_canto)[..., None]
    rasguno = np.clip((n2 - 0.7) * 5, 0, 1)
    base = mezclar_color(base, (0.56, 0.57, 0.61), rasguno * 0.45)
    base = mezclar_color(base, (0.62, 0.50, 0.33), np.clip((0.32 - n2) * 5, 0, 1) * 0.55)   # arena en los poros
    rgb[:] = base
    # cuencas de las aletas (vidrio fundido que se derramó) y su halo
    alto_banda = h / NSEG
    for (k, al, tq, principal, sem) in disposicion_racimos():
        tam = 1.0 if principal else 0.6
        cx = (al / A_PLACA * 0.5 + 0.5) * w
        cy = (k - 1 + 0.04 + 0.92 * tq) * alto_banda
        rx, ry = 0.07 * w * tam, 0.3 * alto_banda * tam
        yy, xx = np.ogrid[0:h, 0:w]
        d = np.sqrt(((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2)
        rgb[:] = mezclar_color(rgb, (0.06, 0.08, 0.10), np.clip(1 - np.abs(d - 1.0) / 0.35, 0, 1) * 0.8)
        b[:] = np.maximum(b, np.clip(1.5 - d, 0, 1) * 0.55)
        rgb[:] = mezclar_color(rgb, (0.30, 0.70, 0.80), np.clip(1.0 - d, 0, 1) * 0.5)
    pintar_grietas(rgb, b, rng, 110, w, h, w * 0.02, 6, con_luz=0.5, oscuro=(0.04, 0.05, 0.07))
    # cicatrices: surcos claros con bordes oscuros y vidrio que brilla dentro
    lineas = []
    for cic in CICATRICES:
        pts = []
        for (al, s) in cic:
            k = int(s // LSEG) + 1
            tq = (s / LSEG - (k - 1) - 0.04) / 1.06
            pts.append(((al / A_PLACA * 0.5 + 0.5) * w, (k - 1 + 0.04 + 0.92 * min(1, max(0, tq))) * alto_banda))
        lineas.append(pts)
    d = trazos(h, w, lineas, 9.0)
    rgb[:] = mezclar_color(rgb, (0.14, 0.11, 0.1), np.clip(1 - np.abs(d - 5.0) / 1.6, 0, 1) * 0.85)
    rgb[:] = mezclar_color(rgb, (0.78, 0.68, 0.55), np.clip(1 - d / 4.5, 0, 1) * 0.7)
    rgb[:] = mezclar_color(rgb, (0.5, 0.88, 0.95), np.clip(1 - d / 1.6, 0, 1) * 0.8)
    b[:] = np.maximum(b, np.clip(1.5 - d / 1.4, 0, 1) * 0.85)
    img[y0:y1, x0:x1] = rgb
    brillo[y0:y1, x0:x1] = b

    # --- el cráneo
    y0, y1, x0, x1 = region(AT_CRANEO)
    h, w = y1 - y0, x1 - x0
    uu = (np.arange(w) + 0.5) / w
    vv = (np.arange(h) + 0.5) / h
    fi = (-math.pi / 2 + math.pi * uu)[None, :] * np.ones((h, 1))
    yh = (Y_NUCA - vv * (Y_NUCA - Y_HOCICO))[:, None] * np.ones((1, w))
    tabla_y = np.linspace(Y_HOCICO, Y_NUCA, 64)
    tabla_w = np.array([craneo_param(y)[0] for y in tabla_y])
    xh = np.interp(yh, tabla_y, tabla_w) * np.sin(fi)
    n1 = fbm(h, w, 24, 16, 31, 4)
    n2 = fbm(h, w, 120, 80, 32, 3)
    rgb = np.ones((h, w, 3)) * np.array((0.10, 0.11, 0.15))[None, None, :]
    rgb = mezclar_color(rgb, (0.26, 0.27, 0.32), n1 * 0.9)
    cresta = np.exp(-(xh / 0.3) ** 2) + 0.8 * np.exp(-((np.abs(xh) - 0.95) / 0.18) ** 2)
    cresta *= np.clip((yh + 2.6) / 0.6, 0, 1)
    rgb = mezclar_color(rgb, (0.44, 0.45, 0.50), cresta * 0.5)
    hocico = np.clip((-yh - 2.55) / 0.45, 0, 1)
    rgb = mezclar_color(rgb, (0.38, 0.39, 0.43), hocico * (0.45 + 0.35 * n2))   # la cuchilla, gastada pero de basalto
    nuca = np.clip((yh - 0.65) / 0.3, 0, 1)
    rgb = mezclar_color(rgb, (0.40, 0.41, 0.45), nuca * 0.5)
    lateral = np.clip((np.abs(fi) - 1.15) / 0.4, 0, 1)
    rgb = mezclar_color(rgb, (0.22, 0.17, 0.16), lateral * 0.5)
    rayas = trazos(h, w, [[(rng.uniform(0, w), y), (rng.uniform(0, w), y + rng.uniform(40, 120))]
                         for y in rng.uniform(0, h, 60)], 1.5)
    rgb = mezclar_color(rgb, (0.58, 0.59, 0.63), np.clip(1 - rayas / 1.2, 0, 1) * 0.45)
    b = np.zeros((h, w))
    for (fo, yo, r) in OJOS:                                          # cuencas oscuras de los ocelos
        for lado in (-1, 1):
            cx = (lado * fo / math.pi + 0.5) * w
            cy = (Y_NUCA - yo) / (Y_NUCA - Y_HOCICO) * h
            yy, xx = np.ogrid[0:h, 0:w]
            d = np.hypot((xx - cx) / (w * 0.06 * r / 0.15), (yy - cy) / (h * 0.06 * r / 0.15))
            rgb[:] = mezclar_color(rgb, (0.08, 0.08, 0.1), np.clip(1.3 - d, 0, 1))
            b[:] = np.maximum(b, np.clip(1.2 - d, 0, 1) * 0.4)
    # la gran cicatriz vitrificada del escudo
    def a_px(x, y):
        wy = np.interp(y, tabla_y, tabla_w)
        f = math.asin(max(-1, min(1, x / wy)))
        return ((f / math.pi + 0.5) * w, (Y_NUCA - y) / (Y_NUCA - Y_HOCICO) * h)
    cic = [a_px(x, y) for (x, y) in [(-1.25, -0.15), (-0.85, -0.7), (-0.45, -1.15), (0.0, -1.55), (0.3, -2.0), (0.48, -2.55)]]
    d = trazos(h, w, [cic], 12.0)
    rgb = mezclar_color(rgb, (0.12, 0.1, 0.1), np.clip(1 - np.abs(d - 7) / 2, 0, 1) * 0.85)
    rgb = mezclar_color(rgb, (0.78, 0.69, 0.55), np.clip(1 - d / 6, 0, 1) * 0.6)
    rgb = mezclar_color(rgb, (0.5, 0.9, 0.96), np.clip(1 - d / 2.4, 0, 1) * 0.85)
    b = np.maximum(b, np.clip(1.6 - d / 2.0, 0, 1))
    pintar_grietas(rgb, b, rng, 14, w, h, w * 0.025, 6, con_luz=0.35)
    img[y0:y1, x0:x1] = rgb
    brillo[y0:y1, x0:x1] = b

    # --- la mandíbula (por fuera)
    y0, y1, x0, x1 = region(AT_MANDIBULA)
    h, w = y1 - y0, x1 - x0
    vv = (np.arange(h) + 0.5) / h
    ym = (MAND[0][0] - vv * (MAND[0][0] - MAND[-1][0]))[:, None] * np.ones((1, w))
    uu = (np.arange(w) + 0.5) / w
    fi = (-math.pi / 2 + math.pi * uu)[None, :] * np.ones((h, 1))
    n1 = fbm(h, w, 16, 16, 41, 4)
    n2 = fbm(h, w, 90, 90, 42, 3)
    rgb = np.ones((h, w, 3)) * np.array((0.12, 0.12, 0.15))[None, None, :]
    rgb = mezclar_color(rgb, (0.30, 0.29, 0.31), n1 * 0.8 + 0.2 * np.cos(fi))
    rgb *= (1 - 0.18 * (0.5 + 0.5 * np.cos(2 * math.pi * ym / 0.38)) ** 6)[..., None]
    barbilla = np.clip((-ym - 2.5) / 0.6, 0, 1) * np.cos(fi)
    rgb = mezclar_color(rgb, (0.44, 0.44, 0.47), barbilla * (0.5 + 0.4 * n2))
    canto = np.clip((np.abs(fi) - 1.3) / 0.27, 0, 1)
    rgb = mezclar_color(rgb, (0.42, 0.42, 0.45), canto * 0.5)
    b = np.zeros((h, w))
    pintar_grietas(rgb, b, rng, 12, w, h, w * 0.025, 6, con_luz=0.3)
    img[y0:y1, x0:x1] = rgb
    brillo[y0:y1, x0:x1] = b

    # --- carne de la boca, neutro (dientes, ganchos) y arena
    y0, y1, x0, x1 = region(AT_CARNE)
    h, w = y1 - y0, x1 - x0
    n1 = fbm(h, w, 12, 24, 51, 4)
    rgb = np.ones((h, w, 3)) * np.array((0.34, 0.13, 0.11))[None, None, :]
    rgb = mezclar_color(rgb, (0.55, 0.24, 0.18), n1)
    rgb *= (1 - 0.25 * (0.5 + 0.5 * np.sin(np.arange(w)[None, :] / w * 60)) ** 4)[..., None]
    img[y0:y1, x0:x1] = rgb
    y0, y1, x0, x1 = region(AT_NEUTRO)
    img[y0:y1, x0:x1] = np.array((0.93, 0.91, 0.86))[None, None, :] * (0.95 + 0.05 * fbm(y1 - y0, x1 - x0, 8, 8, 61, 2))[..., None]
    y0, y1, x0, x1 = region(AT_ARENA)
    h, w = y1 - y0, x1 - x0
    n1 = fbm(h, w, 10, 30, 71, 4)
    img[y0:y1, x0:x1] = np.array((0.70, 0.55, 0.36))[None, None, :] * (0.8 + 0.4 * n1)[..., None]
    return np.clip(img, 0, 1), np.clip(brillo, 0, 1)


def guardar_png(ruta, rgb, a):
    n = rgb.shape[0]
    im = bpy.data.images.new(os.path.basename(ruta), n, n, alpha=True)
    # el alfa lleva un mínimo (ALFA_MIN): WebP con pérdida no guarda el color de los píxeles con alfa 0 (medido: error
    # medio 0,106 en ellos, el 90 % de la textura); el sombreador lo deshace: brillo = (a - ALFA_MIN) / (1 - ALFA_MIN)
    px = np.concatenate([rgb, (ALFA_MIN + (1 - ALFA_MIN) * a)[..., None]], axis=2).astype(np.float32)
    im.pixels.foreach_set(px.ravel())
    im.filepath_raw = ruta
    im.file_format = "WEBP"                                         # calidad 92: 0,24 MB en vez de 4,2 (PNG)
    im.save(quality=92)
    bpy.data.images.remove(im)


def reducir(rgb, a, f):
    n = rgb.shape[0] // f
    return rgb.reshape(n, f, n, f, 3).mean(axis=(1, 3)), a.reshape(n, f, n, f).mean(axis=(1, 3))


# ---------------------------------------------------------------- esqueleto

def huesos():
    hs = [("raiz", (0, 0, 0), (0, 0, 1.0), None)]
    for k in range(NSEG, 0, -1):
        hs.append((col_nombre(k), (0, k * LSEG, 0), (0, (k - 1) * LSEG, 0), "raiz" if k == NSEG else col_nombre(k + 1)))
    hs += [("cabeza", (0, 0, 0), (0, -2.6 * K_CAB, 0), "col_01"),
           ("mandibula", tuple(BISAGRA * K_CAB), tuple(Vector((0, -3.0, -0.5)) * K_CAB), "cabeza"),
           ("garganta", (0, 1.0 * K_CAB, -0.3 * K_CAB), (0, 0.5 * K_CAB, -0.3 * K_CAB), "cabeza"),
           ("chorro", tuple(CHORRO_BASE * K_CAB), tuple(CHORRO_BASE * K_CAB + Vector((0, -1, 0))), "cabeza"),
           ("mandibula_izq", tuple(puntos_mandibula_lateral(1)[0] * K_CAB), tuple(puntos_mandibula_lateral(1)[-1] * K_CAB),
            "mandibula"),
           ("mandibula_der", tuple(puntos_mandibula_lateral(-1)[0] * K_CAB), tuple(puntos_mandibula_lateral(-1)[-1] * K_CAB),
            "mandibula"),
           ("brillo", (0, 0, -1.0), (0, 0, -0.5), "raiz"),
           ("monticulo", (0, 0, 0), (0, 0, 0.4), "raiz")]
    for k in ALETAS:
        sm = (k - 0.5) * LSEG
        rt = radio(sm) * 1.12
        hs.append((placa_nombre(k), (0, sm, rt), (0, sm, rt + 0.6), col_nombre(k)))
    return hs


HUESOS = huesos()
NOMBRES = [h[0] for h in HUESOS]


def crear_esqueleto(sc):
    arm_data = bpy.data.armatures.new("Bramavidrio_esqueleto")
    arm = bpy.data.objects.new("Bramavidrio", arm_data)
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
    for pb in arm.pose.bones:
        pb.rotation_mode = 'QUATERNION'
    return arm


# ---------------------------------------------------------------- poses: curva de columna

DU = 0.1
U = np.arange(-6.0, L_CUERPO + 1e-6, DU)
NU = len(U)
SIGMA = 5                                   # suavizado de las curvas: 0,5 m


def suavizar(x, sigma=SIGMA):
    k = np.exp(-0.5 * (np.arange(-3 * sigma, 3 * sigma + 1) / sigma) ** 2)
    k /= k.sum()
    pad = np.pad(x, 3 * sigma, mode="edge")
    return np.convolve(pad, k, mode="valid")


def curva(nudos):
    """[(u, grados), …] → radianes en la rejilla U, suavizado."""
    xs = [n[0] for n in nudos]
    ys = [math.radians(n[1]) for n in nudos]
    return suavizar(np.interp(U, xs, ys))


def campana(u0, u1, ancho=1.0):
    """1 entre u0 y u1, bajando suave a 0 fuera (ancho en metros)."""
    return np.clip((U - (u0 - ancho)) / ancho, 0, 1) * np.clip(((u1 + ancho) - U) / ancho, 0, 1)


class Pose:
    def __init__(self, th, ps=None, ro=None, ua=11.0, ap=(0, 0, 0), cab=(0, 0, 0), boca=4.0, placas=0.0,
                 brillo=1.0, garganta=0.35, chorro=0.01, monticulo=1.0, placas_k=None, lat=4.0):
        self.th = th if isinstance(th, np.ndarray) else curva(th)
        self.ps = ps if isinstance(ps, np.ndarray) else (curva(ps) if ps else np.zeros(NU))
        self.ro = ro if isinstance(ro, np.ndarray) else (curva(ro) if ro else np.zeros(NU))
        self.ua, self.ap = ua, np.array(ap, dtype=float)
        self.cab = np.array(cab, dtype=float)
        self.boca, self.placas = boca, placas
        self.placas_k = placas_k if placas_k is not None else {}
        self.brillo, self.garganta, self.chorro, self.monticulo = brillo, garganta, chorro, monticulo
        self.lat = lat                     # grados que se abren hacia fuera las mandíbulas laterales

    def copia(self):
        p = Pose(self.th.copy(), self.ps.copy(), self.ro.copy(), self.ua, self.ap.copy(), self.cab.copy(), self.boca,
                 self.placas, self.brillo, self.garganta, self.chorro, self.monticulo, dict(self.placas_k), self.lat)
        return p


def mezclar(a, b, t):
    t = float(t)
    p = a.copia()
    p.th = a.th * (1 - t) + b.th * t
    p.ps = a.ps * (1 - t) + b.ps * t
    p.ro = a.ro * (1 - t) + b.ro * t
    p.ua = a.ua * (1 - t) + b.ua * t
    p.ap = a.ap * (1 - t) + b.ap * t
    p.cab = a.cab * (1 - t) + b.cab * t
    for c in ("boca", "placas", "brillo", "garganta", "chorro", "monticulo", "lat"):
        setattr(p, c, getattr(a, c) * (1 - t) + getattr(b, c) * t)
    ks = set(a.placas_k) | set(b.placas_k)
    p.placas_k = {k: a.placas_k.get(k, 0.0) * (1 - t) + b.placas_k.get(k, 0.0) * t for k in ks}
    return p


def rot_x(a):
    return Matrix.Rotation(a, 3, 'X')


def rot_y(a):
    return Matrix.Rotation(a, 3, 'Y')


def rot_z(a):
    return Matrix.Rotation(a, 3, 'Z')


def resolver(p):
    """Posiciones de la columna en la rejilla U y los marcos (matrices 3x3) de cada punto pedido."""
    h = np.stack([np.sin(p.ps) * np.cos(p.th), -np.cos(p.ps) * np.cos(p.th), np.sin(p.th)], axis=1)
    dq = -(h[1:] + h[:-1]) * 0.5 * DU
    q = np.vstack([np.zeros((1, 3)), np.cumsum(dq, axis=0)])
    qa = np.array([np.interp(p.ua, U, q[:, i]) for i in range(3)])
    return p.ap + q - qa


def en(arr, u):
    return float(np.interp(u, U, arr))


def punto(P, u):
    return Vector([float(np.interp(u, U, P[:, i])) for i in range(3)])


def marco_en(p, u):
    return rot_z(en(p.ps, u)) @ rot_x(-en(p.th, u)) @ rot_y(-en(p.ro, u))


# sentido de los giros locales de mandíbula y placas (se mide una vez con el esqueleto real)
SIGNO = {"mandibula": 1.0, "placa": 1.0, "lat_eje": 'Z', "mandibula_izq": 1.0, "mandibula_der": 1.0}


def matrices_globales(arm, p):
    """Matrices (espacio del esqueleto) de los huesos de la columna y la cabeza para la pose p."""
    P = resolver(p)
    G = {}
    bones = arm.data.bones
    for k in range(1, NSEG + 1):
        cab_j, col_j = punto(P, k * LSEG), punto(P, (k - 1) * LSEG)
        cuerda = (col_j - cab_j).normalized()
        R = marco_en(p, (k - 0.5) * LSEG)
        h_mid = R @ Vector((0, -1, 0))
        corr = h_mid.rotation_difference(cuerda).to_matrix()
        Rb = corr @ R @ bones[col_nombre(k)].matrix_local.to_3x3()
        G[col_nombre(k)] = Matrix.Translation(cab_j) @ Rb.to_4x4()
    R0 = marco_en(p, 0.0)
    E = rot_z(math.radians(p.cab[1])) @ rot_x(-math.radians(p.cab[0])) @ rot_y(-math.radians(p.cab[2]))
    G["cabeza"] = Matrix.Translation(punto(P, 0.0)) @ (R0 @ E @ bones["cabeza"].matrix_local.to_3x3()).to_4x4()
    return G, P


def bases(arm, p):
    """La matriz local (pose) de cada hueso para la pose p."""
    G, P = matrices_globales(arm, p)
    bones = arm.data.bones
    B = {}
    for b in bones:
        n = b.name
        if n in G:
            par = b.parent
            gp = G.get(par.name, par.matrix_local) if par else Matrix.Identity(4)
            resto = (par.matrix_local.inverted() @ b.matrix_local) if par else b.matrix_local
            B[n] = resto.inverted() @ gp.inverted() @ G[n]
        elif n == "mandibula":
            B[n] = Matrix.Rotation(math.radians(p.boca) * SIGNO["mandibula"], 4, 'X')
        elif n in ("mandibula_izq", "mandibula_der"):
            B[n] = Matrix.Rotation(math.radians(p.lat) * SIGNO[n], 4, SIGNO["lat_eje"])
        elif n.startswith("placa_"):
            k = int(n[6:])
            B[n] = Matrix.Rotation(math.radians(p.placas + p.placas_k.get(k, 0.0)) * SIGNO["placa"], 4, 'X')
        elif n in ("brillo", "garganta", "chorro", "monticulo"):
            e = max(0.01, getattr(p, n))
            B[n] = Matrix.Diagonal((e, e, e, 1.0))
        else:
            B[n] = Matrix.Identity(4)
    return B, G, P


def medir_signos(arm):
    """Abre la mandíbula y levanta una placa con giro +X local: ¿baja la punta de la mandíbula? ¿se adelanta la placa?"""
    b = arm.data.bones["mandibula"]
    m = b.matrix_local @ Matrix.Rotation(0.5, 4, 'X')
    punta = m @ Vector((0, b.length, 0))
    SIGNO["mandibula"] = 1.0 if punta.z < b.tail_local.z else -1.0
    b = arm.data.bones[placa_nombre(ALETAS[0])]
    m = b.matrix_local @ Matrix.Rotation(0.3, 4, 'X')
    punta = m @ Vector((0, b.length, 0))
    SIGNO["placa"] = 1.0 if punta.y < b.tail_local.y else -1.0      # positivo: la aleta se inclina hacia la cabeza
    # las mandíbulas laterales: el eje local que más las abre hacia fuera (|x| de la punta) y su sentido
    mejor = (0.0, 'Z')
    for eje in ('X', 'Z'):
        b = arm.data.bones["mandibula_izq"]
        punta = (b.matrix_local @ Matrix.Rotation(0.4, 4, eje)) @ Vector((0, b.length, 0))
        if abs(punta.x - b.tail_local.x) > abs(mejor[0]):
            mejor = (punta.x - b.tail_local.x, eje)
    SIGNO["lat_eje"] = mejor[1]
    for nombre in ("mandibula_izq", "mandibula_der"):
        b = arm.data.bones[nombre]
        punta = (b.matrix_local @ Matrix.Rotation(0.4, 4, mejor[1])) @ Vector((0, b.length, 0))
        SIGNO[nombre] = 1.0 if abs(punta.x) > abs(b.tail_local.x) else -1.0
    print("SIGNOS", SIGNO)


def poner_pose(arm, p):
    B, G, P = bases(arm, p)
    for pb in arm.pose.bones:
        loc, rot, esc = B[pb.name].decompose()
        pb.location, pb.rotation_quaternion, pb.scale = loc, rot, esc
    return G, P


# puntos de la cabeza para medir (en la pose de enlace)
P_HOCICO = Vector((0, -3.22, -0.4)) * K_CAB
P_BARBILLA = Vector((0, -3.15, -0.95)) * K_CAB
P_MAND_BAJO = Vector((0, -1.6, -1.5)) * K_CAB


def mundo_de(arm, G, B, hueso, p_reposo):
    b = arm.data.bones[hueso]
    if hueso == "mandibula":
        gm = G["cabeza"] @ (b.parent.matrix_local.inverted() @ b.matrix_local) @ B["mandibula"]
    else:
        gm = G[hueso]
    return gm @ (b.matrix_local.inverted() @ p_reposo)


# ---------------------------------------------------------------- clips

def ease(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def ease_in(t):
    t = max(0.0, min(1.0, t))
    return t * t


def ease_out(t):
    t = max(0.0, min(1.0, t))
    return 1 - (1 - t) * (1 - t)


def tramos(t, claves):
    """claves = [(segundo, pose, curva)]: la pose en t (la curva es la del tramo que llega a esa clave)."""
    if t <= claves[0][0]:
        return claves[0][1].copia()
    for (t0, p0, _), (t1, p1, f) in zip(claves[:-1], claves[1:]):
        if t <= t1:
            return mezclar(p0, p1, f((t - t0) / (t1 - t0)))
    return claves[-1][1].copia()


TH_REPOSO = [(-6, -14), (0, -14), (1.5, 0), (3, 30), (5, 64), (7.5, 84), (10, 86), (11, 82), (13, 62), (16, 30),
             (22, 12)]


def pose_reposo(t=0.0, T=3.0):
    w = 2 * math.pi * t / T
    p = Pose(TH_REPOSO, ua=11.0, cab=(-6, 0, 0), boca=4.0)
    p.th = p.th + math.radians(2.5) * math.sin(w) * campana(1.5, 8.0, 2.0)
    p.ps = p.ps + math.radians(3.0) * np.sin(w + U * 0.35) * campana(0, 11, 2)
    p.cab = np.array((-6 + 1.5 * math.sin(w + 0.6), 4.0 * math.sin(w), 1.5 * math.sin(w + 1.3)))
    p.boca = 4.0 + 4.0 * (0.5 + 0.5 * math.sin(w - 0.8))
    p.placas = 3.0 * (0.5 + 0.5 * math.sin(w))
    p.brillo = 1.0 + 0.15 * math.sin(2 * w)
    p.garganta = 0.35 + 0.1 * math.sin(w)
    p.lat = 4.0 + 3.0 * (0.5 + 0.5 * math.sin(w + 0.4))
    return p


R0 = pose_reposo(0.0)


def ola_subterranea(t, T=2.0, amp_v=8.0, amp_h=5.0):
    env = np.clip(U / 4.0, 0, 1) * (1 - 0.5 * np.clip((U - 14) / 8, 0, 1))
    th = math.radians(amp_v) * np.sin(2 * math.pi * (U / 8.0 - t / T)) * env
    ps = math.radians(amp_h) * np.sin(2 * math.pi * (U / 11.0 - t / T)) * env
    return th, ps


def pose_subterranea(t=0.0, T=2.0):
    th, ps = ola_subterranea(t, T)
    p = Pose([(-6, 0), (22, 0)], ua=0.0, ap=(0, 0, -2.4), cab=(0, 0, 0), boca=0.0, placas=0.0, brillo=0.8,
             garganta=0.2, monticulo=0.01, lat=0.0)
    p.th = p.th + th
    p.ps = p.ps + ps
    p.cab = np.array((1.5 * math.sin(2 * math.pi * t / T), 3 * math.sin(2 * math.pi * t / T + 1), 0))
    for k in ALETAS:
        p.placas_k[k] = 4.0 * math.sin(2 * math.pi * (k * LSEG / 8.0 - t / T))
    return p


def vibracion(t, f=7.5, k=0):
    return math.sin(2 * math.pi * f * t + k * 1.7) * math.cos(2 * math.pi * f * 0.37 * t + k)


def clip_reposo():
    T = 3.0
    return [pose_reposo(i / FPS, T) for i in range(int(T * FPS) + 1)], {}


def clip_subterraneo():
    T = 2.0
    return [pose_subterranea(i / FPS, T) for i in range(int(T * FPS) + 1)], {}


def clip_aviso():
    D = 1.6
    base = pose_subterranea(0.0)
    arriba = base.copia()
    arriba.ap = np.array((0, 0, -2.0))
    arriba.cab = np.array((7, 0, 0))
    arriba.placas = 18.0
    arriba.brillo = 1.9
    poses = []
    for i in range(int(D * FPS) + 1):
        t = i / FPS
        f = ease(t / 0.3) * (1 - ease((t - 1.1) / 0.5))
        p = mezclar(base, arriba, f)
        tiembla = f * (0.4 + 0.6 * ease(t / 0.15))
        p.th = p.th + math.radians(2.0) * tiembla * np.sin(2 * math.pi * 7.5 * t + U * 2.3)
        for k in ALETAS:
            p.placas_k[k] = base.placas_k.get(k, 0.0) + 7.0 * tiembla * vibracion(t, 7.5, k)
        p.cab = p.cab + np.array((2.5, 3.0, 0)) * tiembla * vibracion(t, 6.0, 3)
        poses.append(p)
    return poses, {"vibracion": 0.1, "fin_vibracion": 1.2}


def pose_columna(ua, cab_pitch=0.0, boca=0.0):
    p = Pose([(-6, 88), (6, 88), (13, 86), (16, 80), (22, 60)], ua=ua, cab=(cab_pitch, 0, 0), boca=boca, placas=-6.0,
             brillo=1.4, garganta=0.5, lat=0.0)
    return p


def clip_emerger():
    """Antes de romper, la arena se abomba y tiembla (el montículo crece); revienta y sube en columna hasta 13 m con
    las mandíbulas abriéndose; se cuelga arriba, la cabeza cae por su peso por debajo del reposo, rebota y se asienta en
    dos vaivenes cada vez menores."""
    D = 2.8
    abajo = pose_columna(-5.4, -8.0, 0.0)
    abajo.monticulo = 0.01
    abajo.brillo = 1.2
    abomba = abajo.copia()
    abomba.monticulo = 0.6
    abomba.ua = -5.1
    alto = pose_columna(13.2, -6.0, 32.0)
    alto.placas, alto.brillo, alto.monticulo, alto.lat = 18.0, 1.7, 1.18, 26.0
    cuelga = mezclar(pose_columna(13.5, 14.0, 44.0), R0, 0.35)
    cuelga.ua = 13.4
    cuelga.placas, cuelga.brillo, cuelga.monticulo, cuelga.lat = 14.0, 1.5, 1.05, 30.0
    cae = mezclar(R0, cuelga, -0.2)                                   # la cabeza cae por debajo del reposo
    cae.ua, cae.boca, cae.lat = 10.4, 10.0, 12.0
    cae.cab = R0.cab + np.array((-14.0, 0, 0))
    rebota = mezclar(R0, cae, -0.45)
    asienta = mezclar(R0, cae, 0.15)
    claves = [(0.0, abajo, ease), (0.2, abomba, ease_in), (0.85, alto, ease_out), (1.2, cuelga, ease), (1.6, cae, ease_in),
              (1.88, rebota, ease), (2.15, asienta, ease), (2.45, R0, ease), (2.8, R0, ease)]
    poses = []
    for i in range(int(D * FPS) + 1):
        t = i / FPS
        p = tramos(t, claves)
        if t < 0.24:
            for k in ALETAS:
                p.placas_k[k] = 6.0 * vibracion(t, 7.5, k)
        if 0.85 <= t < 1.7:
            for k in ALETAS:
                p.placas_k[k] = 6.0 * (1 - (t - 0.85) / 0.85) * vibracion(t, 6.0, k)
        if 1.55 <= t < 1.75:                                          # el golpe al caer la cabeza: un temblor corto
            for k in ALETAS:
                p.placas_k[k] = p.placas_k.get(k, 0.0) + 8.0 * (1 - (t - 1.55) / 0.2) * vibracion(t, 7.5, k)
        poses.append(p)
    return poses, {}


def pose_desde_reposo(dth=None, **kw):
    p = R0.copia()
    if dth is not None:
        p.th = p.th + dth
    for k, v in kw.items():
        setattr(p, k, np.array(v, dtype=float) if k in ("cab", "ap") else v)
    return p


def sacudir(p, t, fuerza, f=4.5):
    p.cab = p.cab + np.array((1.5, 6.0, 4.0)) * fuerza * np.array((vibracion(t, f, 1), math.sin(2 * math.pi * f * t),
                                                                    math.sin(2 * math.pi * f * t + 1.0)))
    for k in ALETAS:
        p.placas_k[k] = p.placas_k.get(k, 0.0) + 6.0 * fuerza * vibracion(t, 7.5, k)
    p.th = p.th + math.radians(1.2) * fuerza * np.sin(2 * math.pi * 6.0 * t + U * 1.9) * campana(0, 11, 2)
    return p


def clip_rugido():
    """Toma aire un instante, se enrosca hacia atrás y abajo (anticipación honda: la barbilla recogida, las aletas
    pegadas), lanza la cabeza hacia delante y arriba pasándose un poco (sobrepaso a 0,8: el pico), se asienta, ruge con
    la boca y las mandíbulas laterales abiertas y sacudidas, cierra pasándose hacia abajo y vuelve al reposo con un
    rebote pequeño. Los instantes no cambian (0,55 · 0,8 · 1,9)."""
    D = 2.6
    inhala = pose_desde_reposo(math.radians(-4) * campana(0, 4, 2.0), cab=(2, 0, 0), boca=2.0, lat=2.0)
    toma = pose_desde_reposo(math.radians(28) * campana(0, 5, 2.0), ua=10.1, cab=(-6, 0, 0), boca=0.0, placas=-9.0,
                             lat=0.0, brillo=0.9)
    pasa = pose_desde_reposo(math.radians(-11) * campana(0, 4.5, 2.0), ua=11.7, cab=(28, 0, 0), boca=72.0, placas=32.0,
                             brillo=1.9, garganta=1.5, lat=46.0)
    ruge = pose_desde_reposo(math.radians(-6) * campana(0, 4.5, 2.0), ua=11.45, cab=(22, 0, 0), boca=67.0, placas=28.0,
                             brillo=1.75, garganta=1.4, lat=42.0)
    cierra = pose_desde_reposo(math.radians(6) * campana(0, 4, 2.0), ua=10.8, cab=(-12, 0, 0), boca=3.0, placas=-2.0,
                               lat=1.0)
    rebote = mezclar(R0, cierra, -0.25)
    claves = [(0.0, R0, ease), (0.18, inhala, ease), (0.55, toma, ease), (0.8, pasa, ease_out), (0.98, ruge, ease),
              (1.9, ruge, ease), (2.18, cierra, ease_in), (2.4, rebote, ease), (2.6, R0, ease)]
    poses = []
    for i in range(int(D * FPS) + 1):
        t = i / FPS
        p = tramos(t, claves)
        if 0.78 <= t <= 2.0:
            p = sacudir(p, t, ease((t - 0.78) / 0.15) * (1 - ease((t - 1.8) / 0.2)))
            p.lat = p.lat + 4.0 * math.sin(2 * math.pi * 6.0 * t) * (1 - ease((t - 1.8) / 0.2))
        poses.append(p)
    return poses, {"inicio_rugido": 0.55, "pico_rugido": 0.8, "fin_rugido": 1.9}


TH_RETRAE = [(-6, 8), (0, 8), (1.5, 30), (3, 72), (5, 98), (7, 102), (9.2, 86), (12, 60), (16, 30), (22, 12)]
TH_EMBISTE = [(-6, -44), (0, -44), (2, -26), (4.5, 0), (8, 40), (11, 70), (14.5, 82), (17, 60), (22, 20)]


def clip_ataque():
    D = 2.3
    retrae = Pose(TH_RETRAE, ua=9.2, cab=(-18, 0, 0), boca=0.0, placas=-10.0, brillo=1.25, lat=0.0)
    embiste = Pose(TH_EMBISTE, ua=14.5, cab=(-8, 0, 0), boca=0.0, placas=8.0, brillo=1.5, garganta=0.6, lat=0.0)
    rebote = mezclar(embiste, R0, 0.3)
    rebote.boca = 16.0
    medio = mezclar(embiste, R0, 0.7)
    claves = [(0.0, R0, ease), (0.55, retrae, ease), (0.8, retrae, ease), (1.0, embiste, ease_in), (1.15, rebote, ease_out),
              (1.5, medio, ease), (2.3, R0, ease)]
    poses = []
    for i in range(int(D * FPS) + 1):
        t = i / FPS
        p = tramos(t, claves)
        if 0.55 <= t < 0.8:
            p.th = p.th + math.radians(0.8) * np.sin(2 * math.pi * 9 * t + U * 2.0) * campana(0, 9, 2)
        if 0.8 <= t < 1.0:
            p.boca = 52.0 * math.sin(math.pi * ease((t - 0.8) / 0.17)) if t < 0.97 else 0.0
            p.lat = 34.0 * math.sin(math.pi * ease((t - 0.8) / 0.17)) if t < 0.97 else 0.0   # se cierran al morder
        poses.append(p)
    return poses, {"fijado": 0.55, "impacto": None}


TH_ERGUIDO = [(-6, 40), (0, 40), (2, 66), (4, 86), (17, 89), (19, 72), (22, 45)]
TH_CAIDO = [(-6, -22), (0, -22), (3, -8), (8, 0), (12.5, 8), (13.6, 36), (15.5, 62), (22, 40)]


def clip_ataque_sismico():
    D = 3.8
    erguido = Pose(TH_ERGUIDO, ua=17.0, cab=(18, 0, 0), boca=20.0, placas=20.0, brillo=1.5, garganta=0.8, lat=14.0)
    ruge = erguido.copia()
    ruge.cab, ruge.boca, ruge.placas, ruge.garganta, ruge.brillo = np.array((30.0, 0, 0)), 66.0, 26.0, 1.3, 1.8
    ruge.lat = 42.0
    caido = Pose(TH_CAIDO, ua=13.6, cab=(-14, 0, 0), boca=0.0, placas=-6.0, brillo=1.6, garganta=0.6, lat=0.0)
    bote = caido.copia()
    bote.th = bote.th + math.radians(7) * campana(-6, 8, 3)
    bote.placas = 14.0
    claves = [(0.0, R0, ease), (1.0, erguido, ease), (1.2, ruge, ease_out), (2.1, ruge, ease), (2.55, caido, ease_in),
              (2.72, bote, ease_out), (2.9, caido, ease_in), (3.8, R0, ease)]
    poses = []
    for i in range(int(D * FPS) + 1):
        t = i / FPS
        p = tramos(t, claves)
        if 1.15 <= t <= 2.15:
            p = sacudir(p, t, ease((t - 1.15) / 0.15) * (1 - ease((t - 2.0) / 0.15)))
        if 2.5 <= t <= 3.1:
            for k in ALETAS:
                p.placas_k[k] = p.placas_k.get(k, 0.0) + 9.0 * (1 - (t - 2.5) / 0.6) * vibracion(t, 7.5, k)
        poses.append(p)
    return poses, {"erguido": 1.0, "rugido": 1.15, "caida": 2.1, "impacto": None}


def clip_ataque_aliento():
    D = 3.6
    abre = pose_desde_reposo(None, cab=(4, 0, 0), boca=55.0, placas=4.0, brillo=1.1, garganta=0.6, lat=24.0)
    aspira = pose_desde_reposo(math.radians(16) * campana(0, 4.5, 2.0), ua=10.8, cab=(18, 0, 0), boca=60.0,
                               placas=22.0, brillo=2.3, garganta=3.0, lat=32.0)
    escupe = pose_desde_reposo(math.radians(-12) * campana(0, 4.5, 2.0), ua=11.7, cab=(-24, 0, 0), boca=72.0,
                               placas=16.0, brillo=2.0, garganta=2.6, lat=46.0)
    sigue = escupe.copia()
    sigue.cab = np.array((-17.0, 0, 0))
    sigue.garganta, sigue.brillo, sigue.lat = 1.2, 1.5, 40.0
    claves = [(0.0, R0, ease), (0.4, abre, ease), (1.6, aspira, ease), (1.85, escupe, ease_out), (2.6, sigue, ease),
              (3.0, mezclar(sigue, R0, 0.6), ease), (3.6, R0, ease)]
    poses = []
    for i in range(int(D * FPS) + 1):
        t = i / FPS
        p = tramos(t, claves)
        if 0.45 <= t < 1.85:
            p = sacudir(p, t, 0.5 * ease((t - 0.45) / 1.15), f=6.0)
        if 1.85 <= t < 2.7:
            p.chorro = ease((t - 1.85) / 0.12) * (1 - ease((t - 2.6) / 0.1)) * (1.0 + 0.04 * math.sin(2 * math.pi * 9 * t))
            p.cab = p.cab + np.array((1.5 * math.sin(2 * math.pi * 7 * t), 1.0 * math.sin(2 * math.pi * 5 * t), 0))
        poses.append(p)
    return poses, {"apertura": 0.3, "inicio_succion": 0.45, "carga_max": 1.6, "descarga": 1.85, "fin_descarga": 2.6}


def clip_herida():
    D = 1.0
    golpe = pose_desde_reposo(math.radians(10) * campana(0, 5, 2.0), ua=10.7, cab=(10, -8, 9), boca=26.0, brillo=0.55,
                              lat=16.0)
    vuelve = mezclar(golpe, R0, 0.65)
    claves = [(0.0, R0, ease), (0.1, golpe, ease_out), (0.4, vuelve, ease), (1.0, R0, ease)]
    poses = []
    for i in range(int(D * FPS) + 1):
        t = i / FPS
        p = tramos(t, claves)
        if t >= 0.08:
            for k in ALETAS:
                p.placas_k[k] = 8.0 * max(0.0, 1 - (t - 0.08) / 0.6) * vibracion(t, 7.5, k)
        poses.append(p)
    return poses, {"golpe": 0.1}


TH_DERRIBADO = [(-6, -18), (0, -18), (3, -6), (6, 2), (9, 10), (10.5, 30), (12, 55), (22, 30)]


def clip_derrota():
    D = 3.4
    dolor = pose_desde_reposo(math.radians(8) * campana(0, 5, 2.0), cab=(25, 0, 0), boca=55.0, placas=10.0, brillo=1.4,
                              lat=34.0)
    caido = Pose(TH_DERRIBADO, ps=[(-6, 30), (9, 30), (11, 10), (14, 0)], ro=[(-6, 50), (9, 50), (11.5, 10), (14, 0)],
                 ua=10.5, cab=(-10, 0, 35), boca=30.0, placas=-10.0, brillo=0.5, garganta=0.3, lat=18.0)
    bote = caido.copia()
    bote.th = bote.th + math.radians(5) * campana(-6, 7, 3)
    hundido = caido.copia()
    hundido.ua = 8.8
    hundido.boca, hundido.placas, hundido.brillo, hundido.garganta, hundido.lat = 34.0, -12.0, 0.08, 0.05, 28.0
    claves = [(0.0, R0, ease), (0.5, dolor, ease_out), (0.6, dolor, ease), (1.75, caido, ease_in), (1.9, bote, ease_out),
              (2.05, caido, ease_in), (3.4, hundido, ease)]
    poses = []
    for i in range(int(D * FPS) + 1):
        t = i / FPS
        p = tramos(t, claves)
        if t < 0.65:
            p = sacudir(p, t, ease(t / 0.2) * 0.8)
            p.brillo = p.brillo * (0.6 + 0.4 * (0.5 + 0.5 * math.sin(2 * math.pi * 6 * t)))
        poses.append(p)
    return poses, {"dolor": 0.5, "caida": None, "apagado": 3.0}


CLIPS = {"reposo": clip_reposo, "subterraneo": clip_subterraneo, "aviso": clip_aviso, "emerger": clip_emerger,
         "rugido": clip_rugido, "ataque": clip_ataque, "ataque_sismico": clip_ataque_sismico,
         "ataque_aliento": clip_ataque_aliento, "herida": clip_herida, "derrota": clip_derrota}
BUCLES = ["reposo", "subterraneo"]


# ---------------------------------------------------------------- acciones (curvas escritas directamente)

def crear_accion(arm, nombre, poses):
    act = bpy.data.actions.new(nombre)
    act.use_fake_user = True
    arm.animation_data.action = act
    n = len(poses)
    datos = {b: {"loc": np.zeros((n, 3)), "rot": np.zeros((n, 4)), "esc": np.zeros((n, 3))} for b in NOMBRES}
    medidas = []
    previo = {}
    for i, p in enumerate(poses):
        B, G, P = bases(arm, p)
        for b in NOMBRES:
            loc, rot, esc = B[b].decompose()
            if b in previo and previo[b].dot(rot) < 0:
                rot.negate()
            previo[b] = rot
            datos[b]["loc"][i] = loc
            datos[b]["rot"][i] = (rot.w, rot.x, rot.y, rot.z)
            datos[b]["esc"][i] = esc
        hocico = mundo_de(arm, G, B, "cabeza", P_HOCICO)
        barbilla = mundo_de(arm, G, B, "mandibula", P_BARBILLA)
        bajo = mundo_de(arm, G, B, "mandibula", P_MAND_BAJO)
        nuca = punto(P, 0.0)
        medidas.append({"hocico": hocico, "barbilla": barbilla, "bajo": bajo, "nuca": nuca,
                        "alto": max(hocico.z, nuca.z + 1.5)})
    marcos = np.arange(n, dtype=float) + 1.0
    for b in NOMBRES:
        for ruta, clave, nc in (("location", "loc", 3), ("rotation_quaternion", "rot", 4), ("scale", "esc", 3)):
            dp = 'pose.bones["%s"].%s' % (b, ruta)
            for c in range(nc):
                fc = act.fcurve_ensure_for_datablock(arm, dp, index=c, group_name=b)
                fc.keyframe_points.add(n)
                co = np.empty(2 * n)
                co[0::2] = marcos
                co[1::2] = datos[b][clave][:, c]
                fc.keyframe_points.foreach_set("co", co)
                fc.keyframe_points.foreach_set("interpolation", [1] * n)         # LINEAR
                fc.update()
    arm.animation_data.action = None
    pista = arm.animation_data.nla_tracks.new()
    pista.name = nombre
    pista.strips.new(nombre, 1, act)
    pista.mute = True
    return medidas


def instantes(nombre, medidas, marcas):
    """Completa las marcas que se miden en el propio clip (impacto, rotura de la arena, caída…)."""
    t = lambda i: round(i / FPS, 4)
    m = dict(marcas)
    extra = {}
    if nombre == "ataque":
        i0, i1 = int(0.8 * FPS), int(1.25 * FPS)
        i = min(range(i0, i1 + 1), key=lambda j: medidas[j]["barbilla"].y)
        m["impacto"] = t(i)
        extra["alcance"] = round(-medidas[i]["barbilla"].y, 3)
        extra["altura_impacto"] = round(medidas[i]["barbilla"].z, 3)
    if nombre == "ataque_sismico":
        i0 = int(2.1 * FPS)
        i = next((j for j in range(i0, len(medidas)) if min(medidas[j]["bajo"].z, medidas[j]["barbilla"].z) <= 0.35),
                 int(2.55 * FPS))
        m["impacto"] = t(i)
        extra["alcance"] = round(-medidas[i]["hocico"].y, 3)
        extra["altura_max"] = round(max(x["alto"] for x in medidas), 3)
    if nombre == "ataque_aliento":
        i = int(1.85 * FPS)
        extra["alcance"] = round(-medidas[i]["hocico"].y + CHORRO_LARGO * 0.8, 3)
    if nombre == "derrota":
        i0 = int(0.6 * FPS)
        i = next((j for j in range(i0, len(medidas)) if min(medidas[j]["bajo"].z, medidas[j]["barbilla"].z) <= 0.45),
                 int(1.75 * FPS))
        m["caida"] = t(i)
    if nombre == "emerger":
        i = next((j for j in range(len(medidas)) if medidas[j]["hocico"].z > 0.0), 0)
        m["rompe_arena"] = t(i)
        j = max(range(len(medidas)), key=lambda q: medidas[q]["alto"])
        m["pico"] = t(j)
        m["erguido"] = 2.45
    if nombre == "reposo":
        extra["altura"] = round(medidas[0]["alto"], 3)
        extra["cabeza_delante"] = round(-medidas[0]["hocico"].y, 3)
    return {k: v for k, v in m.items() if v is not None}, extra


# ---------------------------------------------------------------- materiales de Blender (para los renders)

def material(nombre, ruta_tex=None):
    m = bpy.data.materials.new(nombre)
    m.use_backface_culling = nombre not in ("chorro",)
    nt = m.node_tree if m.node_tree else None
    if hasattr(m, "use_nodes"):
        m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    vc = nt.nodes.new("ShaderNodeVertexColor")
    vc.layer_name = "Color"
    gam = nt.nodes.new("ShaderNodeGamma")
    gam.inputs["Gamma"].default_value = 2.2
    nt.links.new(vc.outputs["Color"], gam.inputs["Color"])
    bsdf.inputs["Roughness"].default_value = 0.8
    if nombre == "piel" and ruta_tex:
        tx = nt.nodes.new("ShaderNodeTexImage")
        tx.image = bpy.data.images.load(ruta_tex, check_existing=True)
        mul = nt.nodes.new("ShaderNodeVectorMath")
        mul.operation = 'MULTIPLY'
        nt.links.new(tx.outputs["Color"], mul.inputs[0])
        nt.links.new(gam.outputs["Color"], mul.inputs[1])
        nt.links.new(mul.outputs["Vector"], bsdf.inputs["Base Color"])
        rango = nt.nodes.new("ShaderNodeMapRange")
        rango.inputs["From Min"].default_value = ALFA_MIN
        nt.links.new(tx.outputs["Alpha"], rango.inputs["Value"])
        em = nt.nodes.new("ShaderNodeVectorMath")
        em.operation = 'SCALE'
        em.inputs[0].default_value = lineal((0.45, 0.95, 1.0))
        nt.links.new(rango.outputs["Result"], em.inputs["Scale"])
        nt.links.new(em.outputs["Vector"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = 1.0
    else:
        nt.links.new(gam.outputs["Color"], bsdf.inputs["Base Color"])
        if nombre in ("vidrio", "garganta", "chorro"):
            nt.links.new(gam.outputs["Color"], bsdf.inputs["Emission Color"])
            bsdf.inputs["Emission Strength"].default_value = {"vidrio": 2.0, "garganta": 4.0, "chorro": 5.0}[nombre]
            bsdf.inputs["Roughness"].default_value = 0.15
    return m


def conducir(arm, m, hueso, fuerza):
    """La fuerza de la emisión sigue a la escala del hueso (como hace bramavidrio_3d.gd en Godot)."""
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    fc = bsdf.inputs["Emission Strength"].driver_add("default_value")
    v = fc.driver.variables.new()
    v.name = "e"
    v.type = 'TRANSFORMS'
    v.targets[0].id = arm
    v.targets[0].bone_target = hueso
    v.targets[0].transform_type = 'SCALE_X'
    v.targets[0].transform_space = 'LOCAL_SPACE'
    fc.driver.expression = "%.2f * e" % fuerza


# ---------------------------------------------------------------- la malla en Blender y la exportación

def crear_objeto_malla(M, arm, nombre, ruta_tex):
    me = bpy.data.meshes.new(nombre + "_malla")
    me.from_pydata([tuple(v) for v in M.v], [], M.caras)
    me.update()
    me.polygons.foreach_set("material_index", M.mats)
    attr = me.color_attributes.new("Color", 'FLOAT_COLOR', 'POINT')
    cols = []
    for c in M.col:
        cols += list(c)
    attr.data.foreach_set("color", cols)
    me.color_attributes.active_color = attr
    uvl = me.uv_layers.new(name="UVMap")
    uv_bucle = []
    for poly in me.polygons:
        for li in poly.loop_indices:
            uv_bucle += list(M.uv[me.loops[li].vertex_index])
    uvl.data.foreach_set("uv", uv_bucle)
    me.shade_smooth()
    me.set_sharp_from_angle(angle=math.radians(38))
    obj = bpy.data.objects.new(nombre, me)
    bpy.context.scene.collection.objects.link(obj)
    obj.parent = arm
    for n in NOMBRES:
        obj.vertex_groups.new(name=n)
    for i, w in enumerate(M.pesos):
        tot = sum(w.values())
        for h, p in w.items():
            obj.vertex_groups[h].add([i], p / tot, 'REPLACE')
    mod = obj.modifiers.new("Esqueleto", 'ARMATURE')
    mod.object = arm
    for nm in MATERIALES:
        if nm in bpy.data.materials:                                 # los mismos en las tres versiones (sin «.001»)
            me.materials.append(bpy.data.materials[nm])
            continue
        m = material(nm, ruta_tex)
        me.materials.append(m)
        if nm == "vidrio":
            conducir(arm, m, "brillo", 2.0)
        if nm == "garganta":
            conducir(arm, m, "garganta", 4.0)
        if nm == "chorro":
            conducir(arm, m, "chorro", 5.0)
    return obj


def triangulos(M):
    return sum(len(f) - 2 for f in M.caras)


def exportar(ruta):
    bpy.ops.export_scene.gltf(
        filepath=ruta, export_format='GLB', use_selection=False,
        export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=True,
        export_anim_slide_to_zero=True, export_def_bones=False, export_reset_pose_bones=True,
        export_optimize_animation_size=False, export_skins=True, export_yup=True, export_influence_nb=4,
        export_vertex_color='ACTIVE', export_cameras=False, export_lights=False, export_image_format='NONE',
        export_materials='EXPORT')
    print("EXPORTADO", ruta, os.path.getsize(ruta))


def preparar_escena():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.fps = FPS
    return sc


# ---------------------------------------------------------------- bocetos de silueta (las tres cabezas)

def siluetas(carpeta):
    global VARIANTE
    os.makedirs(carpeta, exist_ok=True)
    imagenes = []
    for var in ("A", "B", "C"):
        VARIANTE = var
        sc = preparar_escena()
        arm = crear_esqueleto(sc)
        medir_signos(arm)
        M = construir("medio")
        obj = crear_objeto_malla(M, arm, "Boceto", None)
        bpy.context.view_layer.objects.active = arm
        bpy.ops.object.mode_set(mode='POSE')
        p = pose_reposo(0.0)
        p.boca = 38.0
        p.cab = np.array((4.0, 0, 0))
        poner_pose(arm, p)
        bpy.ops.object.mode_set(mode='OBJECT')
        sc.render.engine = 'BLENDER_WORKBENCH'
        sc.display.shading.light = 'FLAT'
        sc.display.shading.color_type = 'SINGLE'
        sc.display.shading.single_color = (0.05, 0.04, 0.05)
        sc.display.shading.background_type = 'VIEWPORT'
        sc.display.shading.background_color = (0.93, 0.88, 0.80)
        sc.render.resolution_x, sc.render.resolution_y = 520, 560
        cam_d = bpy.data.cameras.new("cam")
        cam_d.type = 'ORTHO'
        cam_d.ortho_scale = 19.0
        cam = bpy.data.objects.new("cam", cam_d)
        sc.collection.objects.link(cam)
        sc.camera = cam
        for vista, pos, rot in (("perfil", (30, -4.5, 6.0), (90, 0, 90)), ("tres_cuartos", (22, -26, 9.0), (80, 0, 40))):
            cam.location = pos
            cam.rotation_euler = [math.radians(a) for a in rot]
            ruta = os.path.join(carpeta, "silueta_%s_%s.png" % (var, vista))
            sc.render.filepath = ruta
            bpy.ops.render.render(write_still=True)
            imagenes.append(ruta)
    print("SILUETAS", imagenes)


# ---------------------------------------------------------------- principal

def principal():
    os.makedirs(CARPETA, exist_ok=True)
    if MODO == "siluetas":
        siluetas(CARPETA)
        return
    rgb, a = pintar_textura(TEX)
    rutas_tex = {}
    for perfil, f, suf in (("alto", 1, ""), ("medio", 2, "_medio"), ("bajo", 4, "_bajo")):
        r, al = (rgb, a) if f == 1 else reducir(rgb, a, f)
        ruta = os.path.join(CARPETA, "bramavidrio_piel%s.webp" % suf)
        guardar_png(ruta, r, al)
        rutas_tex[perfil] = ruta
        print("TEXTURA", ruta, r.shape[0], os.path.getsize(ruta))
    sc = preparar_escena()
    arm = crear_esqueleto(sc)
    medir_signos(arm)
    arm.animation_data_create()
    resumen = {"fps": FPS, "huesos": NOMBRES, "clips": {}, "triangulos": {}, "texturas": {}}
    for nombre, f in CLIPS.items():
        poses, marcas = f()
        medidas = crear_accion(arm, nombre, poses)
        m, extra = instantes(nombre, medidas, marcas)
        resumen["clips"][nombre] = {"duracion": round((len(poses) - 1) / FPS, 4), "bucle": nombre in BUCLES,
                                    "instantes": m, **extra}
        print("CLIP", nombre, resumen["clips"][nombre])
    for t in arm.animation_data.nla_tracks:
        t.mute = False
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode='POSE')
    poner_pose(arm, R0)
    bpy.ops.object.mode_set(mode='OBJECT')
    for perfil in PERFILES:
        M = construir(perfil)
        obj = crear_objeto_malla(M, arm, "Bramavidrio_" + perfil, rutas_tex["alto"])
        tris = triangulos(M)
        resumen["triangulos"][perfil] = tris
        resumen["texturas"][perfil] = os.path.basename(rutas_tex[perfil])
        print("MALLA", perfil, "vértices", len(M.v), "triángulos", tris)
        suf = "" if perfil == "alto" else "_" + perfil
        exportar(os.path.join(CARPETA, "bramavidrio%s.glb" % suf))
        if perfil == "alto" and SALIDA_BLEND:
            bpy.ops.wm.save_as_mainfile(filepath=SALIDA_BLEND)
            print("GUARDADO", SALIDA_BLEND)
        me = obj.data
        bpy.data.objects.remove(obj)
        bpy.data.meshes.remove(me)
    with open(os.path.join(CARPETA, "bramavidrio_clips.json"), "w", encoding="utf-8", newline="\n") as fh:
        json.dump(resumen, fh, ensure_ascii=False, indent=1)
    print("RESUMEN", json.dumps(resumen["triangulos"]))


principal()
