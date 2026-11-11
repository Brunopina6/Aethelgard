# Bramavidrio, versión 2 (V12, rediseño pedido por el usuario el 11/11: «no pega del todo con el estilo del juego y
# parece un gusano genérico / larva por segmentos»). Modelo, textura, esqueleto y clips hechos desde cero con este guion
# (geometría procedural propia, textura pintada por código, ningún recurso descargado: obra propia del proyecto). La
# versión 1 (fuente/crear_bramavidrio.py y enemigos/bramavidrio/bramavidrio*.glb) no se toca: esta escribe en
# enemigos/bramavidrio/v2/ con nombres nuevos.
#
#   blender -b --factory-startup -P crear_bramavidrio2.py -- <carpeta> [alto,medio,bajo] [<salida.blend>] [<variante>]
#   blender -b --factory-startup -P crear_bramavidrio2.py -- <carpeta> conceptos    (las tres propuestas: renders)
#
# Escribe en la carpeta:
#   bramavidrio2.glb / bramavidrio2_medio.glb / bramavidrio2_bajo.glb   las tres versiones (mismos huesos y clips)
#   bramavidrio2_piel.webp (2048) / _piel_medio.webp (1024) / _piel_bajo.webp (512)   la textura (RGB: color; A: 0,04 +
#                                     0,96 × brillo de las vetas de cristal), la misma distribución en las tres
#   bramavidrio2_clips.json          duración, bucle e instantes de cada clip: los MISMOS clips e instantes que la v1
#                                     (el contrato de bramavidrio_3d.gd) y algunos nuevos (placas del suelo, succión…)
#
# TRES CONCEPTOS (docs/memory/agents/animaciones_v12_bramavidrio2.md; renders en D:\REBELUM_diagnostico):
#   «sierpe»    la Sierpe de la Vela: cuerpo de sierpe que se afina, con escamas de basalto escalonadas (no anillos),
#               una vela de espinas de cristal unidas por membrana de vidrio a lo largo del lomo, aletas de vidrio a los
#               lados del cuello, cabeza de dragón de basalto con cuernos hacia atrás y abanicos en las mejillas
#   «tragador»  el Gran Tragador: cabeza enorme de boca ancha con un peine de láminas de cristal (filtra la arena),
#               colmillos que suben de la mandíbula, un arrecife de cristal en el lomo y aletas de remo
#   «capuchon»  la Cobra Vitral: capucha de basalto que se abre con paneles de vidrio de colores por delante, cabeza en
#               punta de flecha y dos colmillos de cristal que suben de la mandíbula
# La elegida (la que exporta por defecto) es VARIANTE_FINAL.
#
# Ejes (Blender): mira a -Y, Z arriba, su izquierda es +X. En Godot mira a +Z. Pose de enlace: tendido a lo largo de +Y
# con la nuca en el origen; los clips lo colocan respecto del AGUJERO (el origen; en Godot, y = 0 es la arena).
#
# Esqueleto (52 huesos): los 43 de la v1 con los mismos nombres (raiz; col_01 nuca … col_18 cola; cabeza, mandibula,
# mandibula_izq y mandibula_der; placa_02 … placa_17; y los de datos brillo, garganta, chorro, monticulo) y nueve
# nuevos: aleta_izq / aleta_der (las aletas del cuello), succion (la arena que aspira: dato por su escala, con malla) y
# losa_1 … losa_6 (las placas del suelo que levanta la Fractura; escondidas con escala 0,01).
# Animación: la «spline IK» de la v1 (una curva de columna por fotograma, integrada desde el agujero y ajustada por
# longitud de arco), horneada a claves en cada fotograma.
#
# Materiales (los pone Godot, enemigos/bramavidrio/v2/bramavidrio2_3d.gd, por nombre de superficie):
#   piel     textura × color de vértice (el alfa del color: cuánto «mineral» es: brillo y borde de la piedra)
#   vidrio   espinas, membranas, ojos y cristales: brillo frío que sigue al hueso «brillo»
#   garganta la luz del fondo de la boca: sigue al hueso «garganta»
#   arena    el montículo del agujero y la cara de arriba de las losas
#   chorro   el aliento (aditivo; el alfa del color de vértice es su fuerza a lo largo)
#   polvo    la arena que sube a la boca al aspirar (mezcla; alfa del color de vértice)
import bpy, sys, os, math, random, json
import numpy as np
from mathutils import Vector, Matrix, noise

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
CARPETA = argv[0] if argv else ""
MODO = argv[1] if len(argv) > 1 else "alto,medio,bajo"
PERFILES = [p for p in MODO.split(",") if p in ("alto", "medio", "bajo")]
SALIDA_BLEND = argv[2] if len(argv) > 2 else ""
VARIANTE_FINAL = "sierpe"
VARIANTE = argv[3] if len(argv) > 3 and argv[3] else VARIANTE_FINAL
FPS = 30
CONCEPTO = False                 # True: colores de vértice con el color entero (renders de concepto, sin textura)

# ---------------------------------------------------------------- medidas

NSEG = 18
L_CUERPO = 22.0
LSEG = L_CUERPO / NSEG                     # 1,222 m por hueso de la columna
S_INI = -0.8                               # el tubo empieza dentro de la cabeza
ALETAS = range(2, NSEG)                    # huesos placa_kk (la vela: se eriza y ondula)
CALIDAD = {
    "alto": dict(lados=28, paso=0.36, cab_sec=19, cab_lados=20, esp_lados=6, mem=3, escamas=[(0.0, 0), (0.62, 1),
                 (1.12, 0)], esc_paso=0.95, bisel=True, linea=2, dientes=1.0, rayos=5, cr=5, mont=24, chorro=12,
                 succion=10, losas=6, cuerno_lados=7, tex=2048, menton=5),
    "medio": dict(lados=18, paso=0.62, cab_sec=13, cab_lados=13, esp_lados=5, mem=2, escamas=[(0.5, 0), (1.05, 1)],
                  esc_paso=1.2, bisel=False, linea=1, dientes=0.62, rayos=4, cr=3, mont=16, chorro=8, succion=7,
                  losas=5, cuerno_lados=5, tex=1024, menton=3),
    "bajo": dict(lados=12, paso=1.05, cab_sec=9, cab_lados=9, esp_lados=4, mem=1, escamas=[], esc_paso=1.4,
                 bisel=False, linea=0, dientes=0.38, rayos=3, cr=1, mont=10, chorro=6, succion=5, losas=4,
                 cuerno_lados=4, tex=512, menton=0),
}
Q = CALIDAD["alto"]

PIEL, VIDRIO, GARGANTA, ARENA, CHORRO, POLVO = range(6)
MATERIALES = ["piel", "vidrio", "garganta", "arena", "chorro", "polvo"]

# Atlas de la textura (u a la derecha, v hacia arriba, como en Blender)
AT_TUBO = (0.0, 0.5, 0.0, 1.0)
AT_CRANEO = (0.5, 1.0, 0.5, 1.0)
AT_MANDIBULA = (0.5, 0.82, 0.22, 0.5)
AT_CARNE = (0.82, 1.0, 0.22, 0.5)
AT_ESCAMA = (0.5, 0.75, 0.0, 0.22)
AT_NEUTRO = (0.9, 1.0, 0.0, 0.1)
AT_ARENA = (0.75, 0.9, 0.0, 0.22)
AT_ROCA = (0.9, 1.0, 0.1, 0.22)

# ---------------------------------------------------------------- colores (sRGB)

VIDRIO_C = (0.50, 0.94, 1.0)
VIDRIO_HONDO = (0.10, 0.36, 0.50)
VIDRIO_MEMBRANA = (0.07, 0.27, 0.36)
DIENTE = (0.90, 0.86, 0.74)
DIENTE_OSC = (0.60, 0.55, 0.46)
BASALTO = (0.13, 0.14, 0.18)
BASALTO_CLARO = (0.36, 0.37, 0.42)
ARENA_C = (0.70, 0.56, 0.38)
VIENTRE = (0.62, 0.52, 0.38)
CARNE = (0.42, 0.16, 0.14)
HUESO_DIENTE = ((0.86, 0.82, 0.72), (0.74, 0.70, 0.62), (0.92, 0.90, 0.84))

# Cuerpo de cada variante: radio a lo largo (desde la nuca)
RADIOS = {
    "sierpe": [(-1.0, 1.0), (0.0, 1.0), (1.5, 1.06), (3.0, 1.22), (6.0, 1.48), (10.0, 1.58), (14.0, 1.46),
               (17.0, 1.2), (19.5, 0.86), (21.0, 0.5), (21.8, 0.26), (22.0, 0.14)],
    "tragador": [(-1.0, 1.85), (0.0, 1.85), (1.5, 2.0), (4.0, 2.1), (8.0, 2.0), (12.0, 1.78), (15.0, 1.4),
                 (18.0, 0.95), (20.5, 0.5), (22.0, 0.18)],
    "capuchon": [(-1.0, 1.08), (0.0, 1.08), (1.5, 1.18), (4.0, 1.42), (8.0, 1.52), (12.0, 1.48), (16.0, 1.24),
                 (19.0, 0.85), (21.0, 0.45), (22.0, 0.15)],
}
# Cabeza: secciones del cráneo (y, semiancho, línea de la boca, alto, forma: <1 cuadrada). La nuca en y > 0; el hocico
# a -Y. Se modela a escala 1 y se agranda K_CAB.
CRANEOS = {
    "sierpe": [(0.85, 1.02, -0.26, 1.10, 0.72), (0.4, 1.16, -0.30, 1.16, 0.70), (-0.1, 1.27, -0.33, 1.12, 0.70),
               (-0.6, 1.34, -0.36, 1.03, 0.72), (-1.1, 1.30, -0.37, 0.93, 0.75), (-1.6, 1.12, -0.37, 0.80, 0.80),
               (-2.1, 0.96, -0.36, 0.68, 0.85), (-2.6, 0.83, -0.35, 0.56, 0.90), (-3.0, 0.70, -0.34, 0.44, 0.95),
               (-3.32, 0.52, -0.33, 0.28, 1.0)],
    "tragador": [(0.9, 1.62, -0.20, 1.45, 0.55), (0.3, 1.82, -0.24, 1.6, 0.55), (-0.4, 1.92, -0.28, 1.58, 0.55),
                 (-1.2, 1.92, -0.30, 1.45, 0.56), (-2.0, 1.84, -0.31, 1.22, 0.6), (-2.7, 1.70, -0.31, 0.92, 0.65),
                 (-3.1, 1.52, -0.31, 0.64, 0.75), (-3.32, 1.24, -0.31, 0.32, 0.9)],
    "capuchon": [(0.8, 0.98, -0.20, 0.86, 0.8), (0.2, 1.12, -0.25, 0.92, 0.8), (-0.5, 1.34, -0.28, 0.88, 0.85),
                 (-1.0, 1.40, -0.30, 0.78, 0.9), (-1.6, 1.10, -0.30, 0.66, 0.95), (-2.3, 0.76, -0.30, 0.50, 1.0),
                 (-2.9, 0.42, -0.30, 0.34, 1.0), (-3.15, 0.22, -0.30, 0.2, 1.0)],
}
# Mandíbula: (y, semiancho, profundidad)
MANDS = {
    "sierpe": [(0.15, 1.10, 0.50), (-0.5, 1.24, 0.80), (-1.3, 1.18, 0.90), (-2.1, 0.98, 0.86), (-2.8, 0.78, 0.76),
               (-3.28, 0.56, 0.58)],
    "tragador": [(0.2, 1.55, 0.7), (-0.5, 1.85, 1.1), (-1.4, 1.98, 1.25), (-2.3, 1.95, 1.22), (-3.0, 1.82, 1.05),
                 (-3.62, 1.55, 0.7)],
    "capuchon": [(0.1, 1.0, 0.42), (-0.5, 1.22, 0.62), (-1.2, 1.18, 0.66), (-1.9, 0.86, 0.6), (-2.6, 0.5, 0.46),
                 (-3.05, 0.24, 0.3)],
}
ZB_MAND = -0.43
BISAGRA = Vector((0.0, -0.15, -0.44))
K_CABS = {"sierpe": 1.3, "tragador": 1.18, "capuchon": 1.25}
CHORRO_LARGO = 12.0


def K_CAB():
    return K_CABS[VARIANTE]


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


def radio(s):
    return catmull(RADIOS[VARIANTE], s)


def seccion(alfa, r):
    """Sección del cuerpo: alfa = 0 arriba (lomo), +90° a su izquierda (+X), 180° el vientre (más plano)."""
    c, s = math.cos(alfa), math.sin(alfa)
    plano = 1.0 - 0.22 * max(0.0, -c) ** 0.8
    return r * 1.04 * s, r * c * plano


def C(rgb, ao=1.0, mineral=None):
    """Color de vértice de lo que lleva la textura: en el modelo, la oclusión (la textura pone el color); en los
    conceptos, el color entero."""
    c = tuple(x * ao for x in rgb) if CONCEPTO else (ao, ao, ao)
    return c + ((mineral,) if mineral is not None else ())


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

    def copia(self, i):
        """Otro vértice igual (la cara de atrás de una membrana: una cara con los mismos vértices al revés sería una
        cara repetida y la malla no sería válida)."""
        if not hasattr(self, "_copias"):
            self._copias = {}
        if i not in self._copias:
            self._copias[i] = self.vert(self.v[i], self.col[i], self.uv[i], self.pesos[i])
        return self._copias[i]

    def doble(self, idx, mat):
        """Una cara por los dos lados (membranas finas: el material descarta la cara de atrás)."""
        self.caras.append(tuple(idx))
        self.mats.append(mat)
        self.caras.append(tuple(self.copia(i) for i in idx[::-1]))
        self.mats.append(mat)


def en_atlas(region, u, v):
    u0, u1, v0, v1 = region
    return (u0 + (u1 - u0) * max(0.0, min(1.0, u)), v0 + (v1 - v0) * max(0.0, min(1.0, v)))


NEUTRO = None


def neutro():
    return en_atlas(AT_NEUTRO, 0.5, 0.5)


def col_nombre(k):
    return "col_%02d" % k


def placa_nombre(k):
    return "placa_%02d" % k


def peso_tubo(s):
    """Pesos de un punto del cuerpo según su distancia desde la nuca: mezcla lineal entre los centros de dos huesos de
    la columna (sin anillos: el cuerpo se dobla de forma continua). Dentro de la cabeza, la cabeza."""
    m0 = -0.2
    if s <= m0:
        return {"cabeza": 1.0}
    centros = [m0] + [(k - 0.5) * LSEG for k in range(1, NSEG + 1)]
    nombres = ["cabeza"] + [col_nombre(k) for k in range(1, NSEG + 1)]
    if s >= centros[-1]:
        return {nombres[-1]: 1.0}
    i = max(j for j in range(len(centros) - 1) if centros[j] <= s)
    t = (s - centros[i]) / (centros[i + 1] - centros[i])
    t = t * t * (3 - 2 * t) * 0.35 + t * 0.65
    w = {}
    if 1 - t > 0.002:
        w[nombres[i]] = 1 - t
    if t > 0.002:
        w[nombres[i + 1]] = t
    return w


def hueso_vela(s):
    k = int(s // LSEG) + 1
    if 2 <= k <= NSEG - 1:
        return placa_nombre(k)
    return col_nombre(max(1, min(NSEG, k)))


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
    paso = Q["paso"]
    fin = L_CUERPO - 0.12
    n = int(math.ceil(fin / paso))
    return [S_INI, -0.35] + [fin * i / n for i in range(n + 1)]


def color_tubo(alfa, s):
    """El cuerpo en los conceptos: basalto arriba, arena erosionada en el vientre (contrasombra) y la línea lateral."""
    c = math.cos(alfa)
    vientre = suave(-0.15, -0.75, c)
    base = mezcla(mezcla(BASALTO, (0.24, 0.22, 0.22), suave(0.7, 0.0, c)), VIENTRE, vientre)
    if VARIANTE == "tragador":
        base = mezcla(base, ARENA_C, 0.25 * suave(0.5, -0.2, c))
    return base


def crear_tubo(M):
    lados = Q["lados"]
    filas = []
    for s in filas_tubo():
        fila = []
        for j in range(lados + 1):
            alfa = -math.pi + 2 * math.pi * j / lados
            r = radio(s)
            x, z = seccion(alfa, r)
            ruido = noise.noise(Vector((x * 0.9, s * 0.7, z * 0.9))) * 0.02
            x, z = x * (1 + ruido), z * (1 + ruido)
            ao = 0.85 + 0.15 * suave(-0.9, 0.3, math.cos(alfa))
            mineral = suave(-0.35, 0.2, math.cos(alfa))
            uv = en_atlas(AT_TUBO, j / lados, (s - S_INI) / (L_CUERPO - S_INI))
            fila.append(M.vert((x, s, z), C(color_tubo(alfa, s), ao, mineral), uv, peso_tubo(s)))
        filas.append(fila)
    rejilla(M, filas, PIEL, fuera=EJE)
    punta = M.vert((0, L_CUERPO + 0.18, 0.02), C(BASALTO, 0.8, 0.5), en_atlas(AT_TUBO, 0.5, 1.0), {col_nombre(NSEG): 1.0})
    ult = filas[-1]
    for j in range(lados):
        M.cara((ult[j], ult[j + 1], punta), PIEL, fuera=lambda c: (0, L_CUERPO - 1.0, 0))


def sup_cuerpo(alfa, s):
    r = radio(s)
    x, z = seccion(alfa, r)
    return Vector((x, s, z)), Vector((x, 0.0, z)).normalized()


def escama(M, sup, a0, a1, s0, s1, grosor, alza, punta, uvf, dentro, tinte=1.0, profundo=0.25):
    """Una escama de basalto sobre el cuerpo (sup(alfa, s) -> (punto, normal)), con pesos del tubo (se dobla con él).
    El borde de atrás se levanta (alza) y acaba en punta en el centro (punta, en metros); monta sobre la siguiente. Con
    bisel, el canto baja y se aclara (gastado por la arena). Los cantos bajan hacia dentro con la arena de las juntas."""
    bisel = Q["bisel"]
    nu, nv = (2, 1) if bisel else (1, 1)

    def muestras(a, b, n):
        if not bisel:
            return [a + (b - a) * i / n for i in range(n + 1)]
        e = (b - a) * 0.14
        return [a] + [a + e + (b - a - 2 * e) * i / n for i in range(n + 1)] + [b]
    us, vs = muestras(a0, a1, nu), muestras(s0, s1, nv)
    um = (a0 + a1) / 2
    filas, params = [], {}
    for j, v in enumerate(vs):
        fila = []
        for i, u in enumerate(us):
            ve = v + (punta * max(0.0, 1 - abs(2 * (u - um) / (a1 - a0))) if j == len(vs) - 1 else 0.0)
            borde = bisel and (i in (0, len(us) - 1) or j in (0, len(vs) - 1))
            h = grosor * (0.45 if borde else 1.0) + alza * ((v - s0) / (s1 - s0)) ** 1.5
            p, n = sup(u, ve)
            c = tinte * (1.0 if borde else 0.78)
            vid = M.vert(p + n * h, C(mezcla(BASALTO, BASALTO_CLARO, 0.35 if borde else 0.0), c, 1.0), uvf(u, ve),
                         peso_tubo(ve))
            params[vid] = (u, ve)
            fila.append(vid)
        filas.append(fila)
    rejilla(M, filas, PIEL, fuera=dentro)
    per = filas[0][:] + [filas[j][-1] for j in range(1, len(vs))] + filas[-1][::-1][1:] + \
        [filas[j][0] for j in range(len(vs) - 2, 0, -1)]
    pm, nm = sup(um, (s0 + s1) / 2)
    centro = pm - nm * profundo * 0.5
    canto = []
    for idx, vid in enumerate(per):
        u, ve = params[vid]
        p, n = sup(u, ve)
        arriba = M.vert(M.v[vid], C(ARENA_C, 0.95, 0.0), en_atlas(AT_ARENA, idx / len(per), 0.85), peso_tubo(ve))
        abajo = M.vert(p - n * profundo, C(ARENA_C, 0.42, 0.0), en_atlas(AT_ARENA, idx / len(per), 0.2), peso_tubo(ve))
        canto.append((arriba, abajo))
    for idx in range(len(per)):
        a1_, b1 = canto[idx]
        a2_, b2 = canto[(idx + 1) % len(per)]
        M.cara((a1_, a2_, b2, b1), PIEL, fuera=lambda c: centro)


def uv_escama(a0, a1, s0, s1, sem):
    """Cada escama toma una losa de la zona de escamas del atlas (cuatro columnas, ocho filas; según su semilla)."""
    col, fila = sem % 4, (sem // 4) % 8

    def f(alfa, s):
        u = (alfa - a0) / (a1 - a0)
        v = (s - s0) / (s1 - s0 + 1e-6)
        return en_atlas(AT_ESCAMA, (col + 0.06 + 0.88 * max(0, min(1, u))) / 4, (fila + 0.06 + 0.88 * max(0, min(1, v))) / 8)
    return f


def crear_escamas(M):
    """Escamas de basalto escalonadas en filas a lo largo del cuerpo (cada fila desplazada media escama: no forman
    anillos), más grandes en el tronco y pequeñas hacia la cola. En el vientre no hay: allí la piel es de arena (la
    textura pinta las placas del vientre)."""
    rnd = random.Random(53)
    sem = 0
    for (ac, desfase) in Q["escamas"]:
        for lado in ((-1, 1) if ac > 0 else (1,)):
            s = 0.6 + desfase * Q["esc_paso"] * 0.5
            while s < 19.8:
                largo = Q["esc_paso"] * (1.15 if s < 15 else 0.95)
                ancho = 0.5 * (1.0 if s < 16 else 0.85)
                a0, a1 = ac * lado - ancho / 2 + rnd.uniform(-0.03, 0.03), ac * lado + ancho / 2 + rnd.uniform(-0.03, 0.03)
                if ac == 0:
                    a0, a1 = -0.23, 0.23
                s0 = s + rnd.uniform(-0.04, 0.04)
                s1 = s0 + largo
                rm = radio(s0)
                escama(M, sup_cuerpo, a0, a1, s0, s1, rm * 0.06, rm * 0.05, largo * 0.18, uv_escama(a0, a1, s0, s1, sem),
                       EJE, tinte=rnd.uniform(0.9, 1.08), profundo=rm * 0.16)
                sem += 1
                s += Q["esc_paso"]


def cristal(M, base, eje, ancho, alto, lados, hueso, giro, color=VIDRIO_C, raiz=-0.3):
    """Un cristal de vidrio fundido: prisma que se afila en punta (la terminación de un cristal)."""
    eje = eje.normalized()
    ref = Vector((0.0, 1.0, 0.0)) if abs(eje.y) < 0.9 else Vector((1.0, 0.0, 0.0))
    u = eje.cross(ref).normalized()
    w = eje.cross(u).normalized()
    anillos = []
    for h, f, c in ((raiz, 1.0, VIDRIO_HONDO), (0.66, 0.9, mezcla(VIDRIO_HONDO, color, 0.7))):
        anillos.append([M.vert(base + eje * (h * alto) + (u * math.cos(giro + 2 * math.pi * i / lados) +
                                                           w * math.sin(giro + 2 * math.pi * i / lados)) * ancho * f,
                               c, neutro(), hueso) for i in range(lados)])
    centro = base + eje * alto * 0.3
    rejilla(M, anillos, VIDRIO, cerrar_u=True, fuera=lambda c: centro)
    punta = M.vert(base + eje * alto, mezcla(color, (1, 1, 1), 0.55), neutro(), hueso)
    for i in range(lados):
        M.cara((anillos[1][i], anillos[1][(i + 1) % lados], punta), VIDRIO, fuera=lambda c: centro)


def membrana(M, rayos, pesos, color_base=VIDRIO_MEMBRANA, color_borde=VIDRIO_C, festón=0.28):
    """Membrana de vidrio entre «rayos» (listas de puntos de la base a la punta, todas del mismo largo): una tira por
    cada par, con el borde de fuera en festón (entre dos rayos baja «festón» de su alto). pesos(i, t) da los pesos de
    cada punto (i, rayo; t, de 0 en la base a 1 en la punta). Por las dos caras."""
    n = len(rayos[0])
    for i in range(len(rayos) - 1):
        a, b = rayos[i], rayos[i + 1]
        cols = []
        for j in range(n):
            t = j / (n - 1)
            pa, pb = a[j], b[j]
            m = (pa + pb) * 0.5
            base_m = (a[0] + b[0]) * 0.5
            m = base_m + (m - base_m) * (1.0 - festón * t ** 1.5)
            c = mezcla(color_base, color_borde, t ** 1.4 * 0.85)
            fila = [M.vert(pa, c, neutro(), pesos(i, t)), M.vert(m, c, neutro(), pesos(i + 0.5, t)),
                    M.vert(pb, c, neutro(), pesos(i + 1, t))]
            cols.append(fila)
        for j in range(n - 1):
            for k in range(2):
                M.doble((cols[j][k], cols[j][k + 1], cols[j + 1][k + 1], cols[j + 1][k]), VIDRIO)


def rayo(M, base, puntas, grueso, lados, hueso, color=BASALTO, punta_vidrio=True):
    """Un rayo (espina de aleta o de vela) de basalto que se afila; si punta_vidrio, acaba en un cristal."""
    pts = [base] + puntas
    anillos = []
    for k, p in enumerate(pts[:-1]):
        d = (pts[k + 1] - p).normalized()
        ref = Vector((1.0, 0.0, 0.0)) if abs(d.x) < 0.8 else Vector((0.0, 1.0, 0.0))
        u = d.cross(ref).normalized()
        w = d.cross(u).normalized()
        g = grueso * (1 - 0.75 * k / max(1, len(pts) - 1))
        c = mezcla(color, BASALTO_CLARO, 0.4 * k / max(1, len(pts) - 1))
        anillos.append([M.vert(p + (u * math.cos(2 * math.pi * i / lados) + w * math.sin(2 * math.pi * i / lados)) * g,
                               c + (1.0,), neutro(), hueso if isinstance(hueso, (str, dict)) else hueso(k / (len(pts) - 1)))
                        for i in range(lados)])
    eje = lambda c: min(pts, key=lambda q: (q - c).length)
    rejilla(M, anillos, PIEL, cerrar_u=True, fuera=eje)
    tip = M.vert(pts[-1], mezcla(color, (0.85, 0.85, 0.9), 0.5) + (1.0,), neutro(),
                 hueso if isinstance(hueso, (str, dict)) else hueso(1.0))
    for i in range(lados):
        M.cara((anillos[-1][i], anillos[-1][(i + 1) % lados], tip), PIEL, fuera=lambda c: pts[-2])


# ---------------------------------------------------------------- la vela (sierpe)

def alto_vela(s):
    return catmull([(0.0, 1.2), (1.2, 2.9), (3.2, 3.9), (6.0, 3.7), (9.0, 3.0), (12.0, 2.2), (15.0, 1.4),
                    (17.6, 0.8), (19.0, 0.4)], s)


def espinas_vela():
    """Las espinas de la vela: [(s, base, punta)] a lo largo del lomo, inclinadas hacia la cola."""
    lista = []
    rnd = random.Random(19)
    s = 0.55
    while s <= 18.6:
        h = alto_vela(s) * rnd.uniform(0.9, 1.08)
        inc = math.radians(24 + 16 * suave(0, 14, s))
        base = Vector((0.0, s, radio(s) * 0.95))
        punta = base + Vector((0.0, math.sin(inc), math.cos(inc))) * h
        lista.append((s, base, punta))
        s += 0.78 if s < 12 else 0.9
    return lista


def crear_vela(M):
    """La vela del lomo: espinas de cristal unidas por una membrana de vidrio con el borde en festón. Las espinas y lo
    alto de la membrana siguen a su hueso placa_kk (se eriza y ondula); la base, al cuerpo."""
    esp = espinas_vela()
    n = Q["mem"] + 1
    rayos = []
    for (s, base, punta) in esp:
        hueso = hueso_vela(s)
        ancho = 0.07 + 0.05 * (punta - base).length ** 0.5
        cristal(M, base, punta - base, ancho, (punta - base).length, Q["esp_lados"], hueso, s * 2.3,
                color=mezcla(VIDRIO_C, (0.75, 0.98, 1.0), 0.3), raiz=-0.2)
        rayos.append([base.lerp(punta, 0.9 * j / (n - 1)) + Vector((0.0, 0.0, -0.1 if j == 0 else 0.0)) for j in range(n)])

    def pesos(i, t):
        s = esp[min(len(esp) - 1, int(i))][0] if i == int(i) else (esp[int(i)][0] + esp[int(i) + 1][0]) / 2
        if t < 0.05:
            return peso_tubo(s)
        return {hueso_vela(s): min(1.0, t * 1.6), **({k: v * (1 - min(1.0, t * 1.6)) for k, v in peso_tubo(s).items()}
                                                   if t * 1.6 < 1 else {})}
    membrana(M, rayos, pesos)


def crear_linea_lateral(M):
    """La línea lateral: a cada costado, una hilera de cristales cortos que brotan entre las escamas (como una costura
    de vidrio a lo largo del cuerpo) y se apagan hacia la cola."""
    if Q["linea"] <= 0:
        return
    rnd = random.Random(7)
    s = 0.9
    while s < 19.0:
        for lado in (-1, 1):
            alfa = lado * math.radians(96)
            r = radio(s)
            x, z = seccion(alfa, r)
            base = Vector((x, s, z))
            n = Vector((x, 0.0, z)).normalized()
            eje = (n + Vector((0, 0.9, 0.25))).normalized()
            h = r * rnd.uniform(0.28, 0.42) * (1.0 - 0.5 * suave(12, 19, s))
            cristal(M, base, eje, h * 0.2, h, 4, peso_tubo(s), rnd.uniform(0, 6), raiz=-0.4)
            if Q["linea"] > 1 and rnd.random() < 0.5:
                cristal(M, base + Vector((0, 0.25, -0.08)), (eje + Vector((0, 0.3, -0.3))).normalized(), h * 0.12,
                        h * 0.55, 4, peso_tubo(s + 0.25), rnd.uniform(0, 6), color=(0.35, 0.8, 0.92), raiz=-0.4)
        s += 0.72 if Q["linea"] > 1 else 1.1


def abanico(M, raiz, dirs, largos, hueso, grueso=0.09, lados=4, color=BASALTO, festón=0.3):
    """Aleta en abanico: rayos de basalto que salen de «raiz» (dirs, largos) unidos por membrana de vidrio."""
    n = Q["mem"] + 1
    rayos = []
    for d, l in zip(dirs, largos):
        d = d.normalized()
        pts = [raiz + d * l * (j / (n - 1)) for j in range(n)]
        rayos.append(pts)
        curva = [raiz + d * l * f for f in (0.5, 1.0)]
        rayo(M, raiz, curva, grueso, lados, hueso, color)
    membrana(M, rayos, lambda i, t: hueso if isinstance(hueso, dict) else {hueso: 1.0}, festón=festón)


S_ALETA = 4.3                                  # dónde nacen las aletas del cuello (hueso col_04)


def crear_aletas(M):
    """Dos aletas a los lados del cuello: cinco rayos hacia atrás y abajo, abiertas como remos para la arena."""
    nr = Q["rayos"]
    for lado in (-1, 1):
        raiz = Vector((lado * radio(S_ALETA) * 0.98, S_ALETA, -0.25))
        dirs, largos = [], []
        for i in range(nr):
            t = i / max(1, nr - 1)
            a = math.radians(-30 + 62 * t)                 # de atrás-arriba a atrás-abajo
            dirs.append(Vector((lado * (0.55 - 0.15 * t), 0.75 + 0.1 * t, math.sin(a) * 0.9)))
            largos.append(3.3 - 1.4 * abs(t - 0.25) ** 1.2)
        abanico(M, raiz, dirs, largos, "aleta_izq" if lado > 0 else "aleta_der", grueso=0.1)


# ---------------------------------------------------------------- tragador: arrecife y remos

def crear_arrecife(M):
    """El arrecife de cristal del lomo: racimos grandes y apretados en los primeros anillos, menores hacia la cola."""
    rnd = random.Random(23)
    for (sc_, tam, n) in ((2.4, 1.5, 14), (6.6, 1.15, 11), (10.8, 0.8, 8), (14.2, 0.5, 5)):   # tres macizos y uno menor
        for i in range(n):
            s = sc_ + rnd.gauss(0.0, 0.7 * tam)
            r = radio(s)
            hueso = hueso_vela(s)
            alfa = rnd.gauss(0.0, 0.5)
            x, z = seccion(alfa, r * 0.98)
            base = Vector((x, s, z))
            nrm = Vector((x, 0.0, z)).normalized()
            eje = (nrm + Vector((rnd.uniform(-0.4, 0.4), rnd.uniform(-0.2, 0.5), 0.0))).normalized()
            h = r * rnd.uniform(0.5, 1.5) * tam * (1.0 - 0.6 * abs(s - sc_) / (1.6 * tam))
            cristal(M, base, eje, h * rnd.uniform(0.16, 0.26), max(0.3, h), 5, hueso, rnd.uniform(0, 6),
                    color=rnd.choice([VIDRIO_C, (0.42, 0.88, 0.95), (0.7, 0.97, 1.0), (0.3, 0.75, 0.9)]))
    # bultos de basalto en los costados (percebes de piedra)
    for k in range(60):
        s = rnd.uniform(1, 18)
        alfa = rnd.choice((-1, 1)) * rnd.uniform(1.0, 1.9)
        x, z = seccion(alfa, radio(s))
        base = Vector((x, s, z))
        nrm = Vector((x, 0.0, z)).normalized()
        rayo(M, base - nrm * 0.1, [base + nrm * 0.25], radio(s) * 0.12, 5, peso_tubo(s), BASALTO, False)


def crear_remos(M):
    for lado in (-1, 1):
        raiz = Vector((lado * radio(S_ALETA) * 0.95, S_ALETA, -0.6))
        dirs = [Vector((lado * 0.8, 0.5, -0.1)), Vector((lado * 0.8, 0.65, -0.35)), Vector((lado * 0.7, 0.75, -0.6))]
        abanico(M, raiz, dirs, [3.2, 3.0, 2.5], "aleta_izq" if lado > 0 else "aleta_der", grueso=0.22, lados=5,
                festón=0.12)


# ---------------------------------------------------------------- capuchón (cobra vitral)

S_CAPUCHA = (4.6, 11.4)                        # la capucha va en el tramo erguido del cuello (el vientre mira a los héroes)


def ancho_capucha(s):
    a, b = S_CAPUCHA
    t = (s - a) / (b - a)
    return catmull([(0.0, 0.0), (0.1, 1.5), (0.3, 2.9), (0.5, 3.3), (0.72, 2.7), (0.9, 1.1), (1.0, 0.0)], t)


def crear_capucha(M):
    """La capucha: dos alas a los lados del cuello (del hueso col_01 al col_05) que se curvan hacia delante (el vientre,
    que mira a los héroes). Por delante, paneles de vidrio de colores entre un emplomado oscuro; por detrás, basalto con
    costillas. Lo de fuera sigue a las aletas (se abre al amenazar)."""
    rnd = random.Random(31)
    ns = 9 if Q["mem"] >= 3 else 6
    nt = 5 if Q["mem"] >= 3 else 3
    paleta = [(0.25, 0.85, 0.92), (0.10, 0.55, 0.75), (0.45, 0.95, 1.0), (0.12, 0.35, 0.62), (0.70, 0.95, 0.85),
              (0.95, 0.75, 0.35)]
    for lado in (-1, 1):
        hueso_ala = "aleta_izq" if lado > 0 else "aleta_der"

        def punto(s, t, off=0.0):
            r = radio(s)
            x0, z0 = seccion(lado * math.radians(72), r * 0.95)
            w = ancho_capucha(s)
            p = Vector((x0 + lado * w * t, s, z0 - 1.3 * (w * t) ** 1.5 / 3.0))
            return p + Vector((0, 0, off))

        def pesos(s, t):
            return peso_tubo(s)
        ss = [S_CAPUCHA[0] + (S_CAPUCHA[1] - S_CAPUCHA[0]) * i / (ns - 1) for i in range(ns)]
        ts = [i / (nt - 1) for i in range(nt)]
        # el dorso: basalto
        filas = [[M.vert(punto(s, t, 0.08), C(BASALTO, 0.9, 1.0), en_atlas(AT_TUBO, 0.5 + lado * 0.1 * t, (s - S_INI) / (L_CUERPO - S_INI)),
                         pesos(s, t)) for t in ts] for s in ss]
        rejilla(M, filas, PIEL, hacia=lambda c, l=lado: (c.x + l * 0.0, c.y, c.z + 5.0))
        # el emplomado (oscuro) y los paneles de vidrio, por delante
        filas = [[M.vert(punto(s, t, -0.04), (0.04, 0.05, 0.07), neutro(), pesos(s, t)) for t in ts] for s in ss]
        rejilla(M, filas, PIEL, hacia=lambda c: (c.x, c.y, c.z - 5.0))
        for i in range(ns - 1):
            for j in range(nt - 1):
                col = rnd.choice(paleta)
                q = [punto(ss[i + a], ts[j + b], -0.07) for a, b in ((0, 0), (0, 1), (1, 1), (1, 0))]
                c = sum(q, Vector()) / 4
                q = [c + (p - c) * 0.84 for p in q]
                ids = [M.vert(p, mezcla(col, (1, 1, 1), 0.15 * k), neutro(),
                              pesos((ss[i] + ss[i + 1]) / 2, (ts[j] + ts[j + 1]) / 2)) for k, p in enumerate(q)]
                M.cara(ids, VIDRIO, hacia=lambda c: (c.x, c.y, c.z - 5.0))
        # costillas por detrás
        for s in ss[1:-1:2]:
            pts = [punto(s, t, 0.14) for t in (0.0, 0.5, 1.0)]
            rayo(M, pts[0], pts[1:], 0.08, 4, pesos(s, 0.6), BASALTO, False)
        # el canto de fuera
        borde = [M.vert(punto(s, 1.0, 0.0) + Vector((lado * 0.08, 0, 0)), (0.5, 0.92, 1.0), neutro(), pesos(s, 1.0)) for s in ss]
        for i in range(ns - 1):
            a, b = filas[i][-1], filas[i + 1][-1]
            M.doble((a, b, borde[i + 1], borde[i]), VIDRIO)


# ---------------------------------------------------------------- la cabeza

def craneo_param(y):
    tabla = lambda i: [(-c[0], c[i]) for c in CRANEOS[VARIANTE]]
    return tuple(catmull(tabla(i), -y) for i in (1, 2, 3, 4))


def mand_param(y):
    tabla = lambda i: [(-c[0], c[i]) for c in MANDS[VARIANTE]]
    return catmull(tabla(1), -y), catmull(tabla(2), -y)


def Y_NUCA():
    return CRANEOS[VARIANTE][0][0]


def Y_HOCICO():
    return CRANEOS[VARIANTE][-1][0]


def dist_poli(x, y, poli):
    d = 1e9
    for (x0, y0), (x1, y1) in zip(poli[:-1], poli[1:]):
        vx, vy = x1 - x0, y1 - y0
        t = max(0.0, min(1.0, ((x - x0) * vx + (y - y0) * vy) / (vx * vx + vy * vy + 1e-9)))
        d = min(d, math.hypot(x - (x0 + t * vx), y - (y0 + t * vy)))
    return d


CEJA = [(0.36, -2.75), (0.78, -1.75), (1.06, -1.15), (1.06, -0.5), (0.9, 0.25)]   # el arco de la ceja (sierpe)


def punto_craneo(fi, y):
    w, zb, h, pw = craneo_param(y)
    x = w * math.sin(fi)
    c = max(0.0, math.cos(fi))
    z = zb + h * c ** pw
    if VARIANTE == "sierpe":
        z += 0.07 * math.exp(-(x / 0.16) ** 2) * suave(-1.2, -2.0, y) * c ** 0.5          # quilla del hocico
        d = dist_poli(abs(x), y, CEJA)
        z += 0.24 * math.exp(-(d / 0.17) ** 2) * c ** 0.25                                   # la ceja
        z -= 0.10 * math.exp(-((abs(x) - 1.12) / 0.2) ** 2 - ((y + 1.2) / 0.35) ** 2)       # la cuenca del ojo
    elif VARIANTE == "tragador":
        z += 0.26 * math.exp(-((abs(x) - 1.45) / 0.3) ** 2 - ((y + 1.5) / 0.7) ** 2) * c ** 0.3
        z += 0.12 * math.exp(-(x / 0.5) ** 2 - ((y - 0.1) / 0.9) ** 2)
    else:
        z += 0.12 * math.exp(-(x / 0.14) ** 2) * c ** 0.5
        z += 0.1 * math.exp(-((abs(x) - 0.9) / 0.15) ** 2 - ((y + 1.2) / 0.6) ** 2)
    z += 0.03 * noise.noise(Vector((x * 1.7, y * 1.7, 3.3)))
    return Vector((x, y, z))


def crear_craneo(M):
    nsec, nl = Q["cab_sec"], Q["cab_lados"]
    yn, yh = Y_NUCA(), Y_HOCICO()
    dentro = lambda c: (0.0, c.y, -0.15)
    filas = []
    for i in range(nsec):
        y = yn + (yh - yn) * i / (nsec - 1)
        fila = []
        for j in range(nl + 1):
            fi = -math.pi / 2 + math.pi * j / nl
            p = punto_craneo(fi, y)
            ao = 1.0 - 0.25 * suave(yn - 0.15, yn, y) - 0.2 * suave(0.6, 1.0, abs(math.sin(fi)))
            uv = en_atlas(AT_CRANEO, j / nl, (yn - y) / (yn - yh))
            fila.append(M.vert(p, C(BASALTO, ao, 0.9), uv, "cabeza"))
        filas.append(fila)
    rejilla(M, filas, PIEL, fuera=dentro)
    w, zb, h, pw = craneo_param(yh)
    labio = []
    for j in range(nl + 1):
        fi = -math.pi / 2 + math.pi * j / nl
        p = Vector((w * 0.95 * math.sin(fi), yh - 0.12, zb - 0.1 + 0.08 * math.cos(fi)))
        labio.append(M.vert(p, C(BASALTO_CLARO, 0.7, 0.9), en_atlas(AT_CRANEO, j / nl, 0.99), "cabeza"))
    rejilla(M, [filas[-1], labio], PIEL, fuera=lambda c: (0.0, c.y + 0.6, -0.1))
    paladar = []
    for y in [yh + 0.12, yh * 0.75, yh * 0.52, yh * 0.3, -0.62]:
        w, zb, h, pw = craneo_param(y)
        fila = []
        for j in range(nl + 1):
            fi = -math.pi / 2 + math.pi * j / nl
            prof = suave(yh * 0.85, -0.6, y)
            c = mezcla((0.55, 0.3, 0.28), (0.16, 0.1, 0.1), prof)
            fila.append(M.vert(((w - 0.08) * math.sin(fi), y, zb - 0.02 - 0.06 * math.cos(fi)), C(c, 1.0, 0.0) if CONCEPTO else (mezcla((1, 1, 1), (0.35, 0.35, 0.35), prof) + (0.0,)),
                               en_atlas(AT_CARNE, j / nl, 0.5 + 0.5 * (1 - prof)), "cabeza"))
        paladar.append(fila)
    rejilla(M, [labio] + paladar, PIEL, hacia=lambda c: (0.0, c.y, -1.5))
    for col in (0, nl):
        canto = [filas[i][col] for i in range(nsec)]
        lado = -1 if col == 0 else 1
        pts = []
        for i in range(nsec):
            y = yn + (yh - yn) * i / (nsec - 1)
            w, zb, h, pw = craneo_param(y)
            pts.append(M.vert((lado * (w - 0.1), y, zb - 0.06), C(BASALTO, 0.4, 0.5), M.uv[canto[i]], "cabeza"))
        for i in range(nsec - 1):
            M.cara((canto[i], canto[i + 1], pts[i + 1], pts[i]), PIEL, fuera=lambda c: (0.0, c.y, 0.4))


OJOS = {
    # (fi, y, semieje, alto, giro): el ojo grande de la sierpe; los cuatro de la cobra; los seis pequeños del tragador
    "sierpe": [(1.08, -1.18, 0.30, 0.16, -0.35)],
    "tragador": [(1.22, -1.95, 0.11, 0.09, 0.0), (1.27, -1.55, 0.10, 0.08, 0.0), (1.30, -1.15, 0.09, 0.07, 0.0)],
    "capuchon": [(1.05, -1.25, 0.24, 0.12, -0.25), (1.2, -0.75, 0.14, 0.08, -0.2)],
}


def crear_ojos(M):
    """Ojos de vidrio encendido: almendra con el iris turquesa y una pupila de rendija oscura (dos vértices oscuros en el
    centro, en vertical)."""
    for (fi, y, a, b, giro) in OJOS[VARIANTE]:
        for lado in (-1, 1):
            p = punto_craneo(lado * fi, y)
            n = (p - Vector((0, y, -0.1))).normalized()
            lado_v = Vector((0, -1, 0)) - n * n.y
            lado_v.normalize()
            arr = n.cross(lado_v).normalized() * (1 if lado > 0 else -1)
            rot = lambda u, v: lado_v * (u * math.cos(giro) - v * math.sin(giro)) + arr * (u * math.sin(giro) + v * math.cos(giro))
            m = 10
            borde = [M.vert(p + rot(a * math.cos(2 * math.pi * i / m), b * math.sin(2 * math.pi * i / m) *
                                    (1.0 if math.sin(2 * math.pi * i / m) > 0 else 0.7)) + n * 0.01,
                            (0.08, 0.3, 0.32), neutro(), "cabeza") for i in range(m)]
            iris = [M.vert(p + rot(a * 0.62 * math.cos(2 * math.pi * i / m), b * 0.62 * math.sin(2 * math.pi * i / m)) + n * 0.05,
                           (0.55, 1.0, 0.85), neutro(), "cabeza") for i in range(m)]
            pup = [M.vert(p + rot(0, s * b * 0.45) + n * 0.06, (0.02, 0.05, 0.05), neutro(), "cabeza") for s in (-1, 1)]
            for i in range(m):
                M.cara((borde[i], borde[(i + 1) % m], iris[(i + 1) % m], iris[i]), VIDRIO, fuera=lambda c, q=p - n: q)
            for i in range(m):
                j = pup[1] if math.sin(2 * math.pi * (i + 0.5) / m) > 0 else pup[0]
                M.cara((iris[i], iris[(i + 1) % m], j), VIDRIO, fuera=lambda c, q=p - n: q)
            M.cara((pup[0], iris[0], pup[1]), VIDRIO, fuera=lambda c, q=p - n: q)
            M.cara((pup[1], iris[m // 2], pup[0]), VIDRIO, fuera=lambda c, q=p - n: q)


def crear_mandibula(M):
    nsec, nl = max(5, Q["cab_sec"] - 4), Q["cab_lados"]
    tab = MANDS[VARIANTE]
    y0, y1 = tab[0][0], tab[-1][0]
    exterior, interior = [], []
    for i in range(nsec):
        y = y0 + (y1 - y0) * i / (nsec - 1)
        w, hp = mand_param(y)
        fe, fi_ = [], []
        for j in range(nl + 1):
            fi = -math.pi / 2 + math.pi * j / nl
            x = w * math.sin(fi) + 0.03 * noise.noise(Vector((fi, y, 7.1)))
            z = ZB_MAND - hp * max(0.0, math.cos(fi)) ** 0.8
            if VARIANTE == "sierpe":
                z -= 0.12 * math.exp(-((y - y1 - 0.25) / 0.3) ** 2) * math.cos(fi) ** 2       # la barbilla
            ao = 1.0 - 0.3 * suave(0.0, 0.12, y)
            fe.append(M.vert((x, y, z), C(BASALTO, ao, 0.85), en_atlas(AT_MANDIBULA, j / nl, (y0 - y) / (y0 - y1)), "mandibula"))
            xi = (w - 0.15) * math.sin(fi)
            zi = ZB_MAND - 0.1 - max(0.05, hp - 0.34) * max(0.0, math.cos(fi)) ** 0.9
            prof = suave(y1 * 0.9, -0.4, y)
            c = mezcla((0.6, 0.34, 0.3), (0.2, 0.12, 0.12), prof)
            fi_.append(M.vert((xi, y, zi), C(c, 1.0, 0.0) if CONCEPTO else (mezcla((1, 1, 1), (0.35, 0.35, 0.35), prof) + (0.0,)),
                              en_atlas(AT_CARNE, j / nl, 0.1 + 0.4 * (1 - prof)), "mandibula"))
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
    c = M.vert((0, y0 + 0.05, ZB_MAND - 0.3), C(BASALTO, 0.3, 0.5), en_atlas(AT_CARNE, 0.5, 0.1), "mandibula")
    for j in range(nl):
        M.cara((exterior[0][j + 1], exterior[0][j], c), PIEL, hacia=lambda q: (0.0, y0 + 2.0, ZB_MAND - 0.3))


def colmillo(M, base, dir_, curva, largo, grueso, lados, hueso, vidrio=False, color=None, rnd=None, mineral=0.5):
    """Un colmillo curvo que se afila (de hueso o de cristal): el eje se dobla hacia «curva»."""
    dir_ = dir_.normalized()
    centro = lambda t: base + dir_ * largo * t + curva * largo * 0.38 * t * t
    ref = Vector((1.0, 0.0, 0.0)) if abs(dir_.x) < 0.8 else Vector((0.0, 1.0, 0.0))
    u = dir_.cross(ref).normalized()
    w = dir_.cross(u).normalized()
    if color is None:
        color = (rnd or random).choice(HUESO_DIENTE)
    mat = VIDRIO if vidrio else PIEL
    c_base = VIDRIO_HONDO if vidrio else mezcla(color, (0.35, 0.3, 0.26), 0.55)
    c_med = mezcla(VIDRIO_HONDO, VIDRIO_C, 0.6) if vidrio else color
    anillos = []
    for t, f, c in ((-0.12, 1.0, c_base), (0.45, 0.62, c_med)):
        anillos.append([M.vert(centro(t) + (u * math.cos(2 * math.pi * i / lados) + w * math.sin(2 * math.pi * i / lados))
                               * grueso * f, c + ((mineral,) if not vidrio else ()), neutro(), hueso) for i in range(lados)])
    eje = lambda c: centro(max(-0.12, min(1.0, (c - base).dot(dir_) / largo)))
    rejilla(M, anillos, mat, cerrar_u=True, fuera=eje)
    punta = M.vert(centro(1.0), (mezcla(VIDRIO_C, (1, 1, 1), 0.6) if vidrio else mezcla(color, (1, 1, 1), 0.3)) +
                   ((mineral,) if not vidrio else ()), neutro(), hueso)
    for i in range(lados):
        M.cara((anillos[1][i], anillos[1][(i + 1) % lados], punta), mat, fuera=lambda c: centro(0.6))


def crear_dientes(M):
    """Dientes: arriba, una fila de colmillos de hueso que cuelgan por fuera de la mandíbula y, delante, dos grandes
    colmillos de cristal; abajo, una fila menor hacia arriba. Variante a variante cambian las proporciones."""
    rnd = random.Random(77)
    f = Q["dientes"]
    lados = 5 if f >= 1 else (4 if f > 0.5 else 3)
    yh = Y_HOCICO()
    n_arr = max(2, int(round(7 * f)))
    n_aba = max(2, int(round(6 * f)))
    for sx in (-1, 1):
        for i in range(n_arr):
            y = -0.75 + (yh + 0.55 + 0.75) * (i + rnd.uniform(-0.2, 0.2)) / max(1, n_arr - 1)
            w, zb, h, pw = craneo_param(y)
            colmillo(M, Vector((sx * (w - 0.05), y, zb - 0.02)), Vector((sx * 0.1, 0.05, -1.0)),
                     Vector((-sx * 0.4, 0.6, 0.0)), rnd.uniform(0.22, 0.42) * (1.3 if VARIANTE == "tragador" else 1.0),
                     rnd.uniform(0.05, 0.08), lados, "cabeza", vidrio=rnd.random() < 0.2, rnd=rnd)
        for i in range(n_aba):
            y = -0.9 + (yh + 0.5 + 0.9) * (i + rnd.uniform(-0.2, 0.2)) / max(1, n_aba - 1)
            wj, hp = mand_param(y)
            colmillo(M, Vector((sx * (wj - 0.1), y, ZB_MAND - 0.03)), Vector((sx * 0.08, 0.0, 1.0)),
                     Vector((-sx * 0.4, 0.6, 0.0)), rnd.uniform(0.18, 0.34), rnd.uniform(0.05, 0.07), lados,
                     "mandibula", vidrio=rnd.random() < 0.3, rnd=rnd)
    if VARIANTE == "sierpe":
        for sx in (-1, 1):                     # los dos grandes colmillos de cristal: cuelgan por fuera de la barbilla
            y = yh + 0.62
            w, zb, h, pw = craneo_param(y)
            colmillo(M, Vector((sx * (w - 0.12), y, zb - 0.02)), Vector((sx * 0.05, -0.12, -1.0)),
                     Vector((-sx * 0.15, 0.55, 0.0)), 1.0, 0.13, lados + 1, "cabeza", vidrio=True, rnd=rnd)
            wj, hp = mand_param(y + 0.9)
            colmillo(M, Vector((sx * (wj - 0.18), y + 0.9, ZB_MAND - 0.02)), Vector((sx * 0.1, -0.2, 1.0)),
                     Vector((-sx * 0.2, 0.6, 0.0)), 0.55, 0.1, lados, "mandibula", rnd=rnd)
    elif VARIANTE == "tragador":
        for sx in (-1, 1):                     # colmillos que suben de la mandíbula (por fuera del labio)
            wj, hp = mand_param(-3.2)
            colmillo(M, Vector((sx * (wj - 0.25), -3.2, ZB_MAND - 0.05)), Vector((sx * 0.35, -0.2, 1.0)),
                     Vector((sx * 0.4, 0.5, 0.2)), 1.7, 0.24, lados + 2, "mandibula", rnd=rnd, color=HUESO_DIENTE[2])
    else:
        for sx in (-1, 1):                     # colmillos de cristal que suben de la mandíbula
            wj, hp = mand_param(-1.9)
            colmillo(M, Vector((sx * (wj + 0.02), -1.9, ZB_MAND - 0.15)), Vector((sx * 0.45, -0.6, 0.8)),
                     Vector((sx * 0.3, 0.6, 0.4)), 1.5, 0.15, lados + 1, "mandibula", vidrio=True, rnd=rnd)


def crear_cuernos(M):
    """Sierpe: dos cuernos grandes que nacen detrás de la ceja y barren hacia atrás, por encima del cuello (no hacia
    arriba: no es una corona), con la punta de cristal; dos menores debajo; púas en el pómulo."""
    lados = Q["cuerno_lados"]
    rnd = random.Random(5)
    for sx in (-1, 1):
        base = Vector((sx * 0.86, 0.45, 0.62))
        colmillo(M, base, Vector((sx * 0.32, 1.0, 0.18)), Vector((sx * 0.25, 0.0, 0.85)), 2.5, 0.27, lados, "cabeza",
                 color=(0.24, 0.24, 0.29), mineral=1.0, rnd=rnd)
        d = Vector((sx * 0.32, 1.0, 0.18)).normalized()
        tip = base + d * 2.5 + Vector((sx * 0.25, 0.0, 0.85)) * 2.5 * 0.38
        cristal(M, tip - d * 0.15, (d + Vector((0, 0, 0.6))).normalized(), 0.08, 0.5, 4, "cabeza", 0.3)
        colmillo(M, Vector((sx * 1.15, 0.2, 0.05)), Vector((sx * 0.5, 1.0, -0.15)), Vector((sx * 0.2, 0.0, 0.5)), 1.3,
                 0.16, max(4, lados - 2), "cabeza", color=(0.22, 0.22, 0.27), mineral=1.0, rnd=rnd)
        for k in range(3 if Q["dientes"] >= 1 else 1):         # púas del pómulo
            y = -0.25 - 0.32 * k
            w, zb, h, pw = craneo_param(y)
            colmillo(M, Vector((sx * (w - 0.04), y, zb + 0.22)), Vector((sx * 1.0, 0.55, -0.1)), Vector((0, 0.6, 0)),
                     0.42 - 0.08 * k, 0.07, 4, "cabeza", color=(0.26, 0.26, 0.3), mineral=1.0, rnd=rnd)
    # la barbilla: una hilera de púas cortas por debajo
    for k in range(Q["menton"]):
        t = k / max(1, Q["menton"] - 1)
        y = MANDS["sierpe"][-1][0] + 0.25 + 1.3 * t
        wj, hp = mand_param(y)
        colmillo(M, Vector((0.0, y, ZB_MAND - hp - 0.1)), Vector((0.0, 0.6, -1.0)), Vector((0, 0.5, 0)),
                 0.35 - 0.12 * t, 0.07, 4, "mandibula", color=(0.25, 0.25, 0.29), mineral=1.0, rnd=rnd)


def crear_peine(M):
    """Tragador: el peine de láminas de cristal que cuelga dentro del labio de arriba (filtra la arena)."""
    nl = max(6, int(14 * Q["dientes"]))
    for sx in (-1, 1):
        for i in range(nl):
            y = -0.4 - 2.6 * i / (nl - 1)
            w, zb, h, pw = craneo_param(y)
            x = sx * (w - 0.32)
            a = M.vert((x, y - 0.08, zb + 0.02), VIDRIO_HONDO, neutro(), "cabeza")
            b = M.vert((x, y + 0.08, zb + 0.02), VIDRIO_HONDO, neutro(), "cabeza")
            c = M.vert((x - sx * 0.05, y + 0.05, zb - 0.75), mezcla(VIDRIO_C, (1, 1, 1), 0.3), neutro(), "cabeza")
            d = M.vert((x - sx * 0.05, y - 0.05, zb - 0.7), VIDRIO_C, neutro(), "cabeza")
            M.doble((a, b, c, d), VIDRIO)


def abanicos_mejilla(M):
    """Sierpe: un abanico a cada lado, detrás de la bisagra de la mandíbula (mandibula_izq / mandibula_der): plegado
    contra el cuello en reposo, se abre hacia fuera al rugir y al aspirar."""
    nr = max(3, Q["rayos"] - 1)
    for sx in (-1, 1):
        raiz = Vector((sx * 1.18, 0.35, -0.42))
        dirs = []
        for i in range(nr):
            t = i / max(1, nr - 1)
            dirs.append(Vector((sx * (0.5 + 0.2 * t), 1.0, 0.55 - 1.15 * t)))
        largos = [1.5 - 0.35 * abs(t - 0.35) for t in (i / max(1, nr - 1) for i in range(nr))]
        abanico(M, raiz, dirs, largos, "mandibula_izq" if sx > 0 else "mandibula_der", grueso=0.06, festón=0.3)


def crear_garganta(M):
    """La pared del fondo de la boca con el agujero de la garganta, el túnel oscuro y la luz al fondo."""
    centro = Vector((0, -0.62, -0.6))
    n_ang = max(8, Q["cab_lados"])
    w0, zb0, h0, _ = craneo_param(-0.62)
    rin = 0.5
    ancho = w0 - 0.1
    pared_in, pared_out = [], []
    for i in range(n_ang):
        a = 2 * math.pi * i / n_ang
        dx, dz = math.sin(a), math.cos(a)
        abajo = suave(0.1, -0.9, dz)
        w = {"cabeza": 1 - abajo, "mandibula": abajo} if abajo > 0.01 else {"cabeza": 1.0}
        pared_in.append(M.vert(centro + Vector((dx * rin, 0, dz * rin)), (0.1, 0.07, 0.07), en_atlas(AT_CARNE, i / n_ang, 0.05), w))
        pared_out.append(M.vert(centro + Vector((dx * ancho, 0.02, dz * (0.24 if dz > 0 else 0.9))), (0.32, 0.24, 0.23),
                                en_atlas(AT_CARNE, i / n_ang, 0.15), w))
    delante = lambda c: (c.x, c.y - 1.0, c.z)
    for i in range(n_ang):
        i2 = (i + 1) % n_ang
        M.cara((pared_out[i], pared_out[i2], pared_in[i2], pared_in[i]), PIEL, hacia=delante)
    borde_luz = [M.vert(M.v[pared_in[i]], (0.06, 0.08, 0.09), (0.5, 0.5), M.pesos[pared_in[i]]) for i in range(n_ang)]
    anillos = [borde_luz]
    pasos = [(0.4, 0.46, -0.5, 0.25), (1.1, 0.42, -0.38, 0.55), (1.8, 0.4, -0.25, 0.85)]
    for (y, r, z, c) in pasos:
        anillos.append([M.vert((math.sin(2 * math.pi * i / n_ang) * r, y, z + math.cos(2 * math.pi * i / n_ang) * r),
                               (c * 0.8, c, c), (0.5, 0.5), peso_tubo(y / K_CAB())) for i in range(n_ang)])
    eje = lambda c: (0.0, c.y, -0.6 + (c.y + 0.62) * 0.15)
    rejilla(M, anillos, GARGANTA, cerrar_u=True, hacia=eje)
    y, r, z, _ = pasos[-1]
    luz_c = M.vert((0, y + 0.05, z), (1.0, 1.0, 1.0), (0.5, 0.5), peso_tubo(y / K_CAB()))
    for i in range(n_ang):
        M.cara((anillos[-1][i], anillos[-1][(i + 1) % n_ang], luz_c), GARGANTA, hacia=delante)


def crear_membranas(M):
    """Piel de las comisuras, entre el canto del cráneo y el de la mandíbula: se estira al abrir la boca."""
    ys = [-0.2, -0.55, -0.9, -1.25, -1.55]
    for lado in (-1, 1):
        filas = []
        for k, peso in enumerate((0.0, 0.5, 1.0)):
            fila = []
            for y in ys:
                w, zb, h, pw = craneo_param(y)
                wj, hp = mand_param(y)
                x = lado * ((w - 0.12) * (1 - peso) + (wj - 0.08) * peso) * (0.97 if k == 1 else 1.0)
                z = (zb - 0.02) * (1 - peso) + (ZB_MAND - 0.02) * peso
                if y < -1.3:
                    pesos = {"cabeza": 1.0} if peso < 0.5 else {"mandibula": 1.0}
                elif 0 < peso < 1:
                    pesos = {"cabeza": 1 - peso, "mandibula": peso}
                else:
                    pesos = {"cabeza" if peso == 0 else "mandibula": 1.0}
                fila.append(M.vert((x, y, z), C(CARNE, 0.8, 0.0) if CONCEPTO else (0.8, 0.8, 0.8, 0.0),
                                   en_atlas(AT_CARNE, 0.2 + 0.6 * peso, 0.3 + 0.4 * suave(-1.55, -0.2, y)), pesos))
            filas.append(fila)
        rejilla(M, filas, PIEL, fuera=lambda c: (0.0, c.y, c.z))
        rejilla(M, [[M.copia(i) for i in f] for f in filas], PIEL, hacia=lambda c: (0.0, c.y, c.z))


# ---------------------------------------------------------------- arena: montículo, losas, chorro y succión

def crear_monticulo(M):
    n = Q["mont"]
    radios = [1.1, 1.55, 2.2, 3.0, 4.1]
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


# las placas del suelo que levanta la Fractura: (centro x, y en Blender; radio; lados; inclinación en grados; alza)
LOSAS_CENTRO = Vector((0.0, -15.4, 0.0))
LOSAS = [(-3.0, -1.4, 1.75, 6, 28, 1.0), (2.9, -1.8, 1.6, 5, 32, 1.1), (-1.4, -4.0, 1.4, 6, 24, 0.8),
         (1.7, -4.3, 1.45, 5, 36, 0.95), (-4.0, 1.3, 1.25, 5, 20, 0.7), (3.8, 1.1, 1.3, 6, 26, 0.75)]


def crear_losas(M):
    rnd = random.Random(61)
    for i, (dx, dy, r, lados, inc, alza) in enumerate(LOSAS[:Q["losas"]]):
        hueso = "losa_%d" % (i + 1)
        c = LOSAS_CENTRO + Vector((dx, dy, 0))
        arriba, abajo = [], []
        for k in range(lados):
            a = 2 * math.pi * k / lados + rnd.uniform(-0.2, 0.2)
            rr = r * rnd.uniform(0.8, 1.1)
            p = c + Vector((math.cos(a) * rr, math.sin(a) * rr, 0.0))
            arriba.append(M.vert(p + Vector((0, 0, 0.05)), (0.95, 0.9, 0.84), en_atlas(AT_ARENA, 0.5 + 0.4 * math.cos(a), 0.5 + 0.4 * math.sin(a)), hueso))
            abajo.append(M.vert(p * 1.0 + (p - c) * 0.08 + Vector((0, 0, -0.7)), C(BASALTO, 0.6, 0.6),
                                en_atlas(AT_ROCA, k / lados, 0.2), hueso))
        tapa = M.vert(c + Vector((0, 0, 0.12)), (1.0, 0.95, 0.9), en_atlas(AT_ARENA, 0.5, 0.5), hueso)
        for k in range(lados):
            M.cara((arriba[k], arriba[(k + 1) % lados], tapa), ARENA, hacia=lambda q: (q.x, q.y, q.z + 5))
            lado_a = M.vert(M.v[arriba[k]], C(BASALTO_CLARO, 0.9, 0.8), en_atlas(AT_ROCA, k / lados, 0.9), hueso)
            lado_b = M.vert(M.v[arriba[(k + 1) % lados]], C(BASALTO_CLARO, 0.9, 0.8), en_atlas(AT_ROCA, (k + 1) / lados, 0.9), hueso)
            M.cara((lado_a, lado_b, abajo[(k + 1) % lados], abajo[k]), PIEL, fuera=lambda q, cc=c: (cc.x, cc.y, q.z))


def crear_chorro(M):
    """El aliento: un chorro de arena y polvo de vidrio (cono doble) que sale de la boca."""
    n = Q["chorro"]
    base = Vector((0, -2.4, -0.62)) * K_CAB()
    for capa, pasos, giro in ((0, [(0.0, 0.3, 1.0), (0.1, 0.7, 1.0), (0.3, 1.3, 0.95), (0.6, 2.0, 0.7), (1.0, 2.8, 0.0)], 0.0),
                              (1, [(0.0, 0.15, 1.0), (0.45, 0.6, 1.0), (0.9, 1.0, 0.0)], 0.3)):
        anillos = []
        for (t, r, a) in pasos:
            fila = []
            for i in range(n + 1):
                ang = 2 * math.pi * i / n + giro
                p = base + Vector((math.sin(ang) * r, -t * CHORRO_LARGO, math.cos(ang) * r * 0.85))
                fila.append(M.vert(p, (0.95, 0.85, 0.65, a) if capa == 0 else (0.75, 0.97, 1.0, a), (i / n, t), "chorro"))
            anillos.append(fila)
        rejilla(M, anillos, CHORRO, fuera=lambda c: (0.0, c.y, base.z))


def crear_succion(M):
    """La arena que sube a la boca al aspirar: cintas que nacen anchas y separadas por delante y se juntan en la boca
    (hueso «succion», hijo de la cabeza; escondidas con escala 0,01). El alfa del color de vértice es su fuerza (0 en
    el suelo, 1 en la boca)."""
    n = Q["succion"]
    boca = Vector((0, -2.6, -0.62)) * K_CAB()
    rnd = random.Random(13)
    for k in range(n):
        a = 2 * math.pi * k / n + rnd.uniform(-0.2, 0.2)
        lejos = boca + Vector((math.sin(a) * rnd.uniform(3.0, 4.6), -rnd.uniform(4.5, 7.5), -rnd.uniform(3.5, 6.0) + math.cos(a) * 1.5))
        pts = []
        for j in range(5):
            t = j / 4
            p = lejos.lerp(boca, t) + Vector((math.sin(a + 1.5) * 0.8, 0.0, 0.0)) * math.sin(math.pi * t)
            pts.append(p)
        filas = []
        for j, p in enumerate(pts):
            t = j / 4
            ancho = 0.42 * (1 - t) + 0.08
            d = (pts[min(4, j + 1)] - pts[max(0, j - 1)]).normalized()
            lado = d.cross(Vector((0, 0, 1))).normalized()
            if lado.length < 0.1:
                lado = Vector((1, 0, 0))
            al = suave(0.0, 0.35, t) * (1.0 - 0.3 * suave(0.85, 1.0, t))
            filas.append([M.vert(p + lado * ancho * s, (0.93, 0.8, 0.6, al), (0.5 + 0.5 * s, t), "succion") for s in (-1, 1)])
        for j in range(4):
            M.doble((filas[j][0], filas[j][1], filas[j + 1][1], filas[j + 1][0]), POLVO)


# ---------------------------------------------------------------- construcción

def construir(nombre_q):
    global Q
    Q = CALIDAD[nombre_q]
    M = Malla()
    crear_tubo(M)
    if VARIANTE == "sierpe":
        crear_escamas(M)
        crear_vela(M)
        crear_linea_lateral(M)
        crear_aletas(M)
    elif VARIANTE == "tragador":
        crear_arrecife(M)
        crear_remos(M)
    else:
        crear_escamas(M)
        crear_capucha(M)
        crear_linea_lateral(M)
    i0 = len(M.v)
    crear_craneo(M)
    crear_ojos(M)
    crear_mandibula(M)
    crear_dientes(M)
    if VARIANTE == "sierpe":
        crear_cuernos(M)
        abanicos_mejilla(M)
    elif VARIANTE == "tragador":
        crear_peine(M)
    crear_garganta(M)
    crear_membranas(M)
    for i in range(i0, len(M.v)):                                     # la cabeza se modela a escala 1 y se agranda
        M.v[i] = M.v[i] * K_CAB()
    crear_monticulo(M)
    crear_losas(M)
    crear_chorro(M)
    crear_succion(M)
    return M


# ---------------------------------------------------------------- esqueleto

def huesos():
    k = K_CAB()
    hs = [("raiz", (0, 0, 0), (0, 0, 1.0), None)]
    for i in range(NSEG, 0, -1):
        hs.append((col_nombre(i), (0, i * LSEG, 0), (0, (i - 1) * LSEG, 0), "raiz" if i == NSEG else col_nombre(i + 1)))
    hs += [("cabeza", (0, 0, 0), (0, -2.6 * k, 0), "col_01"),
           ("mandibula", tuple(BISAGRA * k), tuple(Vector((0, -3.0, -0.5)) * k), "cabeza"),
           ("garganta", (0, 1.0 * k, -0.3 * k), (0, 0.5 * k, -0.3 * k), "cabeza"),
           ("chorro", tuple(Vector((0, -2.4, -0.62)) * k), tuple(Vector((0, -3.4, -0.62)) * k), "cabeza"),
           ("succion", tuple(Vector((0, -2.6, -0.62)) * k), tuple(Vector((0, -3.6, -0.62)) * k), "cabeza"),
           ("mandibula_izq", tuple(Vector((1.18, 0.35, -0.42)) * k), tuple(Vector((1.6, 1.6, -0.5)) * k), "mandibula"),
           ("mandibula_der", tuple(Vector((-1.18, 0.35, -0.42)) * k), tuple(Vector((-1.6, 1.6, -0.5)) * k), "mandibula"),
           ("brillo", (0, 0, -1.0), (0, 0, -0.5), "raiz"),
           ("monticulo", (0, 0, 0), (0, 0, 0.4), "raiz")]
    r, s = radio(S_ALETA), S_ALETA
    hs += [("aleta_izq", (r * 0.98, s, -0.25), (r * 0.98 + 0.8, s + 1.0, -0.4), "col_04"),
           ("aleta_der", (-r * 0.98, s, -0.25), (-r * 0.98 - 0.8, s + 1.0, -0.4), "col_04")]
    for i in ALETAS:
        sm = (i - 0.5) * LSEG
        rt = radio(sm) * 0.95
        hs.append((placa_nombre(i), (0, sm, rt), (0, sm, rt + 0.6), col_nombre(i)))
    for i, (dx, dy, *_rest) in enumerate(LOSAS):
        c = LOSAS_CENTRO + Vector((dx, dy, 0))
        hs.append(("losa_%d" % (i + 1), tuple(c), tuple(c + Vector((0, 0, 1.0))), "raiz"))
    return hs


def crear_esqueleto(sc):
    global HUESOS, NOMBRES
    HUESOS = huesos()
    NOMBRES = [h[0] for h in HUESOS]
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


HUESOS, NOMBRES = [], []

# ---------------------------------------------------------------- poses: curva de columna

DU = 0.1
U = np.arange(-6.0, L_CUERPO + 1e-6, DU)
NU = len(U)
SIGMA = 5


def suavizar(x, sigma=SIGMA):
    k = np.exp(-0.5 * (np.arange(-3 * sigma, 3 * sigma + 1) / sigma) ** 2)
    k /= k.sum()
    pad = np.pad(x, 3 * sigma, mode="edge")
    return np.convolve(pad, k, mode="valid")


def curva(nudos):
    xs = [n[0] for n in nudos]
    ys = [math.radians(n[1]) for n in nudos]
    return suavizar(np.interp(U, xs, ys))


def campana(u0, u1, ancho=1.0):
    return np.clip((U - (u0 - ancho)) / ancho, 0, 1) * np.clip(((u1 + ancho) - U) / ancho, 0, 1)


ATRIBUTOS = ("boca", "placas", "brillo", "garganta", "chorro", "monticulo", "lat", "aleta", "succion", "losas")


class Pose:
    def __init__(self, th, ps=None, ro=None, ua=11.0, ap=(0, 0, 0), cab=(0, 0, 0), boca=4.0, placas=0.0,
                 brillo=1.0, garganta=0.35, chorro=0.01, monticulo=1.0, placas_k=None, lat=4.0, aleta=0.0,
                 succion=0.01, losas=0.0):
        self.th = th if isinstance(th, np.ndarray) else curva(th)
        self.ps = ps if isinstance(ps, np.ndarray) else (curva(ps) if ps else np.zeros(NU))
        self.ro = ro if isinstance(ro, np.ndarray) else (curva(ro) if ro else np.zeros(NU))
        self.ua, self.ap = ua, np.array(ap, dtype=float)
        self.cab = np.array(cab, dtype=float)
        self.boca, self.placas = boca, placas
        self.placas_k = placas_k if placas_k is not None else {}
        self.brillo, self.garganta, self.chorro, self.monticulo = brillo, garganta, chorro, monticulo
        self.lat = lat                      # grados que se abren los abanicos de las mejillas
        self.aleta = aleta                  # grados que se abren las aletas del cuello
        self.succion = succion              # la arena que aspira (escala: 0,01 escondida, 1 entera)
        self.losas = losas                  # las placas del suelo (0 escondidas, 1 levantadas del todo)
        self.losas_k = {}                   # vaivén propio de cada losa (grados)

    def copia(self):
        p = Pose(self.th.copy(), self.ps.copy(), self.ro.copy(), self.ua, self.ap.copy(), self.cab.copy(), self.boca,
                 self.placas, self.brillo, self.garganta, self.chorro, self.monticulo, dict(self.placas_k), self.lat,
                 self.aleta, self.succion, self.losas)
        p.losas_k = dict(self.losas_k)
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
    for c in ATRIBUTOS:
        setattr(p, c, getattr(a, c) * (1 - t) + getattr(b, c) * t)
    ks = set(a.placas_k) | set(b.placas_k)
    p.placas_k = {k: a.placas_k.get(k, 0.0) * (1 - t) + b.placas_k.get(k, 0.0) * t for k in ks}
    ks = set(a.losas_k) | set(b.losas_k)
    p.losas_k = {k: a.losas_k.get(k, 0.0) * (1 - t) + b.losas_k.get(k, 0.0) * t for k in ks}
    return p


def rot_x(a):
    return Matrix.Rotation(a, 3, 'X')


def rot_y(a):
    return Matrix.Rotation(a, 3, 'Y')


def rot_z(a):
    return Matrix.Rotation(a, 3, 'Z')


def resolver(p):
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


SIGNO = {"mandibula": 1.0, "placa": 1.0, "lat_eje": 'Z', "mandibula_izq": 1.0, "mandibula_der": 1.0,
         "aleta_eje": 'Z', "aleta_izq": 1.0, "aleta_der": 1.0}


def matrices_globales(arm, p):
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
    R0_ = marco_en(p, 0.0)
    E = rot_z(math.radians(p.cab[1])) @ rot_x(-math.radians(p.cab[0])) @ rot_y(-math.radians(p.cab[2]))
    G["cabeza"] = Matrix.Translation(punto(P, 0.0)) @ (R0_ @ E @ bones["cabeza"].matrix_local.to_3x3()).to_4x4()
    return G, P


def bases(arm, p):
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
        elif n in ("aleta_izq", "aleta_der"):
            B[n] = Matrix.Rotation(math.radians(p.aleta) * SIGNO[n], 4, SIGNO["aleta_eje"])
        elif n.startswith("placa_"):
            k = int(n[6:])
            B[n] = Matrix.Rotation(math.radians(p.placas + p.placas_k.get(k, 0.0)) * SIGNO["placa"], 4, 'X')
        elif n.startswith("losa_"):
            i = int(n[5:]) - 1
            dx, dy, r, lados, inc, alza = LOSAS[i]
            f = p.losas
            if f < 0.02:
                B[n] = Matrix.Diagonal((0.01, 0.01, 0.01, 1.0))
            else:
                ang = math.radians(inc * f + p.losas_k.get(i, 0.0))
                eje = 'X' if abs(dx) < abs(dy) else 'Z'
                sig = 1.0 if (dx + dy) > 0 else -1.0
                B[n] = Matrix.Translation((0.0, alza * f - 0.25 * (1 - f), 0.0)) @ Matrix.Rotation(ang * sig, 4, eje)
        elif n in ("brillo", "garganta", "chorro", "monticulo", "succion"):
            e = max(0.01, getattr(p, n))
            B[n] = Matrix.Diagonal((e, e, e, 1.0))
        else:
            B[n] = Matrix.Identity(4)
    return B, G, P


def medir_signos(arm):
    b = arm.data.bones["mandibula"]
    m = b.matrix_local @ Matrix.Rotation(0.5, 4, 'X')
    punta = m @ Vector((0, b.length, 0))
    SIGNO["mandibula"] = 1.0 if punta.z < b.tail_local.z else -1.0
    b = arm.data.bones[placa_nombre(ALETAS[0])]
    m = b.matrix_local @ Matrix.Rotation(0.3, 4, 'X')
    punta = m @ Vector((0, b.length, 0))
    SIGNO["placa"] = 1.0 if punta.y < b.tail_local.y else -1.0      # positivo: la vela se inclina hacia la cabeza
    for pre, izq, der, clave in (("lat", "mandibula_izq", "mandibula_der", "lat_eje"), ("aleta", "aleta_izq", "aleta_der", "aleta_eje")):
        mejor = (0.0, 'Z')
        for eje in ('X', 'Z'):
            b = arm.data.bones[izq]
            punta = (b.matrix_local @ Matrix.Rotation(0.4, 4, eje)) @ Vector((0, b.length, 0))
            if abs(punta.x - b.tail_local.x) > abs(mejor[0]):
                mejor = (punta.x - b.tail_local.x, eje)
        SIGNO[clave] = mejor[1]
        for nombre in (izq, der):
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


def P_HOCICO():
    return Vector((0, Y_HOCICO() - 0.1, -0.38)) * K_CAB()


def P_BARBILLA():
    return Vector((0, MANDS[VARIANTE][-1][0] + 0.1, ZB_MAND - 0.5)) * K_CAB()


def P_MAND_BAJO():
    return Vector((0, -1.6, ZB_MAND - 1.0)) * K_CAB()


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


def ease_in3(t):
    t = max(0.0, min(1.0, t))
    return t * t * t


def ease_out(t):
    t = max(0.0, min(1.0, t))
    return 1 - (1 - t) * (1 - t)


def tramos(t, claves):
    if t <= claves[0][0]:
        return claves[0][1].copia()
    for (t0, p0, _), (t1, p1, f) in zip(claves[:-1], claves[1:]):
        if t <= t1:
            return mezclar(p0, p1, f((t - t0) / (t1 - t0)))
    return claves[-1][1].copia()


TH_REPOSO = [(-6, -14), (0, -14), (1.5, 0), (3, 30), (5, 64), (7.5, 84), (10, 86), (11, 82), (13, 62), (16, 30),
             (22, 12)]


def ondas_vela(p, t, T, amp=4.0, largo=7.0):
    for k in ALETAS:
        p.placas_k[k] = p.placas_k.get(k, 0.0) + amp * math.sin(2 * math.pi * (k * LSEG / largo - t / T))


def pose_reposo(t=0.0, T=3.0):
    w = 2 * math.pi * t / T
    p = Pose(TH_REPOSO, ua=11.0, cab=(-6, 0, 0), boca=5.0, aleta=6.0, lat=4.0)
    p.th = p.th + math.radians(2.5) * math.sin(w) * campana(1.5, 8.0, 2.0)
    p.ps = p.ps + math.radians(3.5) * np.sin(w + U * 0.35) * campana(0, 11, 2)
    p.cab = np.array((-6 + 2.0 * math.sin(w + 0.6), 5.0 * math.sin(w), 2.5 * math.sin(w + 1.3)))
    p.boca = 5.0 + 4.0 * (0.5 + 0.5 * math.sin(w - 0.8))
    p.placas = 2.0 * (0.5 + 0.5 * math.sin(w))
    ondas_vela(p, t, T, 3.0, 9.0)
    p.brillo = 1.0 + 0.15 * math.sin(2 * w)
    p.garganta = 0.35 + 0.1 * math.sin(w)
    p.lat = 4.0 + 4.0 * (0.5 + 0.5 * math.sin(w + 0.4))
    p.aleta = 6.0 + 7.0 * math.sin(w + 0.9)
    return p


R0 = None


def pose_desde_reposo(dth=None, **kw):
    p = R0.copia()
    if dth is not None:
        p.th = p.th + dth
    for k, v in kw.items():
        setattr(p, k, np.array(v, dtype=float) if k in ("cab", "ap") else v)
    return p


def vibracion(t, f=7.5, k=0):
    return math.sin(2 * math.pi * f * t + k * 1.7) * math.cos(2 * math.pi * f * 0.37 * t + k)


def sacudir(p, t, fuerza, f=4.5):
    p.cab = p.cab + np.array((1.5, 6.0, 4.0)) * fuerza * np.array((vibracion(t, f, 1), math.sin(2 * math.pi * f * t),
                                                                    math.sin(2 * math.pi * f * t + 1.0)))
    for k in ALETAS:
        p.placas_k[k] = p.placas_k.get(k, 0.0) + 6.0 * fuerza * vibracion(t, 7.5, k)
    p.th = p.th + math.radians(1.2) * fuerza * np.sin(2 * math.pi * 6.0 * t + U * 1.9) * campana(0, 11, 2)
    p.aleta = p.aleta + 6.0 * fuerza * math.sin(2 * math.pi * 6.5 * t)
    return p


def clip_reposo():
    """Respira despacio: el cuello se mece en S, la cabeza mira de un lado a otro (vigila a los héroes), la vela ondula
    de la nuca a la cola, las aletas reman y los abanicos de las mejillas laten. Todo cierra en 3 s."""
    T = 3.0
    return [pose_reposo(i / FPS, T) for i in range(int(T * FPS) + 1)], {}


def ola_subterranea(t, T=2.0, amp_v=7.0, amp_h=6.0):
    env = np.clip(U / 4.0, 0, 1) * (1 - 0.5 * np.clip((U - 14) / 8, 0, 1))
    th = math.radians(amp_v) * np.sin(2 * math.pi * (U / 8.0 - t / T)) * env
    ps = math.radians(amp_h) * np.sin(2 * math.pi * (U / 11.0 - t / T)) * env
    return th, ps


def pose_subterranea(t=0.0, T=2.0):
    """Bajo la arena: solo asoma la vela, plegada hacia atrás, cortando la arena como una aleta."""
    th, ps = ola_subterranea(t, T)
    p = Pose([(-6, 0), (22, 0)], ua=0.0, ap=(0, 0, -2.75), cab=(0, 0, 0), boca=0.0, placas=-16.0, brillo=0.8,
             garganta=0.2, monticulo=0.01, lat=0.0, aleta=-12.0)
    p.th = p.th + th
    p.ps = p.ps + ps
    p.cab = np.array((1.5 * math.sin(2 * math.pi * t / T), 3 * math.sin(2 * math.pi * t / T + 1), 0))
    for k in ALETAS:
        p.placas_k[k] = 5.0 * math.sin(2 * math.pi * (k * LSEG / 8.0 - t / T))
    p.aleta = -12.0 + 10.0 * math.sin(2 * math.pi * t / T)
    return p


def clip_subterraneo():
    T = 2.0
    return [pose_subterranea(i / FPS, T) for i in range(int(T * FPS) + 1)], {}


def clip_aviso():
    """Bajo la arena, la vela se yergue y vibra y la luz sube (el temblor del aviso); vuelve a como iba."""
    D = 1.6
    base = pose_subterranea(0.0)
    arriba = base.copia()
    arriba.ap = np.array((0, 0, -2.3))
    arriba.cab = np.array((7, 0, 0))
    arriba.placas = 14.0
    arriba.brillo = 2.0
    arriba.aleta = 10.0
    poses = []
    for i in range(int(D * FPS) + 1):
        t = i / FPS
        f = ease(t / 0.3) * (1 - ease((t - 1.1) / 0.5))
        p = mezclar(base, arriba, f)
        tiembla = f * (0.4 + 0.6 * ease(t / 0.15))
        p.th = p.th + math.radians(2.0) * tiembla * np.sin(2 * math.pi * 7.5 * t + U * 2.3)
        for k in ALETAS:
            p.placas_k[k] = base.placas_k.get(k, 0.0) + 8.0 * tiembla * vibracion(t, 7.5, k)
        p.cab = p.cab + np.array((2.5, 3.0, 0)) * tiembla * vibracion(t, 6.0, 3)
        poses.append(p)
    return poses, {"vibracion": 0.1, "fin_vibracion": 1.2}


def pose_columna(ua, cab_pitch=0.0, boca=0.0):
    return Pose([(-6, 88), (6, 88), (13, 86), (16, 80), (22, 60)], ua=ua, cab=(cab_pitch, 0, 0), boca=boca,
                placas=-14.0, brillo=1.4, garganta=0.5, lat=0.0, aleta=-14.0)


EMERGER_UA = -5.75             # dónde empieza la cabeza bajo la arena (se ajusta para romperla a 0,2333 s)


def clip_emerger():
    """La arena se abomba y tiembla; revienta la cabeza y sube en columna hasta 13 m con la vela plegada (corta el
    aire); arriba abre de golpe la vela, las aletas y los abanicos (se presenta), la cabeza cae por su peso por debajo
    del reposo con un temblor, rebota y se asienta en dos vaivenes."""
    D = 2.8
    abajo = pose_columna(EMERGER_UA, -8.0, 0.0)
    abajo.monticulo = 0.01
    abajo.brillo = 1.2
    abomba = abajo.copia()
    abomba.monticulo = 0.6
    abomba.ua = EMERGER_UA + 0.3
    alto = pose_columna(13.2, -6.0, 32.0)
    alto.placas, alto.brillo, alto.monticulo, alto.lat, alto.aleta = -6.0, 1.7, 1.18, 30.0, 10.0
    cuelga = mezclar(pose_columna(13.5, 14.0, 44.0), R0, 0.35)
    cuelga.ua = 13.4
    cuelga.placas, cuelga.brillo, cuelga.monticulo, cuelga.lat, cuelga.aleta = 26.0, 1.9, 1.05, 55.0, 45.0
    cae = mezclar(R0, cuelga, -0.2)
    cae.ua, cae.boca, cae.lat, cae.aleta, cae.placas = 10.4, 10.0, 14.0, 4.0, 10.0
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
                p.placas_k[k] = 7.0 * (1 - (t - 0.85) / 0.85) * vibracion(t, 6.0, k)
        if 1.55 <= t < 1.75:
            for k in ALETAS:
                p.placas_k[k] = p.placas_k.get(k, 0.0) + 9.0 * (1 - (t - 1.55) / 0.2) * vibracion(t, 7.5, k)
        if t >= 2.45:                                                 # ya respira: acaba justo donde empieza el reposo
            q = pose_reposo(t - D + 3.0)
            p = mezclar(p, q, ease((t - 2.45) / 0.3)) if t < 2.75 else q
        poses.append(p)
    return poses, {}


def clip_rugido():
    """Toma aire (la cabeza sube, la vela y los abanicos se pliegan), se enrosca hacia atrás y abajo (anticipación
    honda), lanza la cabeza hacia delante pasándose (0,8: el pico) y ruge con la boca, los abanicos, las aletas y la vela
    abiertos del todo, sacudiendo la cabeza; cierra pasándose hacia abajo y rebota al reposo."""
    D = 2.6
    inhala = pose_desde_reposo(math.radians(-4) * campana(0, 4, 2.0), cab=(6, 0, 0), boca=2.0, lat=0.0, aleta=-8.0,
                               placas=-6.0)
    toma = pose_desde_reposo(math.radians(28) * campana(0, 5, 2.0), ua=10.1, cab=(-8, 0, 0), boca=0.0, placas=-16.0,
                             lat=0.0, aleta=-14.0, brillo=0.9)
    pasa = pose_desde_reposo(math.radians(-11) * campana(0, 4.5, 2.0), ua=11.7, cab=(28, 0, 0), boca=74.0, placas=32.0,
                             brillo=2.0, garganta=1.6, lat=62.0, aleta=55.0)
    ruge = pose_desde_reposo(math.radians(-6) * campana(0, 4.5, 2.0), ua=11.45, cab=(22, 0, 0), boca=68.0, placas=28.0,
                             brillo=1.8, garganta=1.4, lat=56.0, aleta=48.0)
    cierra = pose_desde_reposo(math.radians(6) * campana(0, 4, 2.0), ua=10.8, cab=(-12, 0, 0), boca=3.0, placas=-4.0,
                               lat=2.0, aleta=0.0)
    rebote = mezclar(R0, cierra, -0.25)
    claves = [(0.0, R0, ease), (0.18, inhala, ease), (0.55, toma, ease), (0.8, pasa, ease_out), (0.98, ruge, ease),
              (1.9, ruge, ease), (2.18, cierra, ease_in), (2.4, rebote, ease), (2.6, R0, ease)]
    poses = []
    for i in range(int(D * FPS) + 1):
        t = i / FPS
        p = tramos(t, claves)
        if 0.78 <= t <= 2.0:
            f = ease((t - 0.78) / 0.15) * (1 - ease((t - 1.8) / 0.2))
            p = sacudir(p, t, f)
            p.lat = p.lat + 5.0 * math.sin(2 * math.pi * 6.0 * t) * f
        poses.append(p)
    return poses, {"inicio_rugido": 0.55, "pico_rugido": 0.8, "fin_rugido": 1.9}


TH_RETRAE = [(-6, 10), (0, 10), (1.5, 34), (3, 76), (5, 100), (7, 104), (9.2, 86), (12, 60), (16, 30), (22, 12)]
TH_EMBISTE = [(-6, -40), (0, -40), (2, -24), (4.5, 2), (8, 40), (11, 70), (14.5, 82), (17, 60), (22, 20)]


def clip_ataque():
    """La Embestida del Abismo: se recoge hacia atrás y abajo, con la vela pegada y la boca cerrada (0 a 0,55: la
    anticipación); tiembla fijando al objetivo (0,55 a 0,8); se lanza acelerando, abre las fauces a mitad de camino y
    las cierra de golpe en el impacto (1,0: el mordisco, lo más lejos); la inercia echa la vela hacia delante; sacude la
    cabeza dos veces (desgarra) y vuelve."""
    D = 2.3
    retrae = Pose(TH_RETRAE, ua=9.1, cab=(-20, 0, 0), boca=0.0, placas=-16.0, brillo=1.3, lat=0.0, aleta=-16.0)
    embiste = Pose(TH_EMBISTE, ua=14.5, cab=(-10, 0, 0), boca=0.0, placas=16.0, brillo=1.6, garganta=0.6, lat=0.0,
                   aleta=30.0)
    rebote = mezclar(embiste, R0, 0.28)
    rebote.boca, rebote.placas = 14.0, 22.0
    medio = mezclar(embiste, R0, 0.7)
    claves = [(0.0, R0, ease), (0.55, retrae, ease), (0.8, retrae, ease), (1.0, embiste, ease_in3), (1.18, rebote, ease_out),
              (1.55, medio, ease), (2.3, R0, ease)]
    poses = []
    for i in range(int(D * FPS) + 1):
        t = i / FPS
        p = tramos(t, claves)
        if 0.55 <= t < 0.8:
            p.th = p.th + math.radians(0.9) * np.sin(2 * math.pi * 9 * t + U * 2.0) * campana(0, 9, 2)
            for k in ALETAS:
                p.placas_k[k] = 4.0 * vibracion(t, 9.0, k)
        if 0.8 <= t < 1.0:
            a = math.sin(math.pi * ease((t - 0.8) / 0.17)) if t < 0.97 else 0.0
            p.boca, p.lat = 58.0 * a, 40.0 * a
        if 1.0 <= t < 1.55:                                           # desgarra: dos sacudidas de la cabeza
            f = 1 - ease((t - 1.0) / 0.55)
            p.cab = p.cab + np.array((4.0 * math.sin(2 * math.pi * 3.5 * (t - 1.0)), 16.0 * math.sin(2 * math.pi * 3.5 * (t - 1.0)),
                                      10.0 * math.sin(2 * math.pi * 3.5 * (t - 1.0) + 0.6))) * f
            for k in ALETAS:
                p.placas_k[k] = p.placas_k.get(k, 0.0) + 7.0 * f * vibracion(t, 7.5, k)
        poses.append(p)
    return poses, {"anticipacion": 0.2, "fijado": 0.55, "impacto": None}


TH_ERGUIDO = [(-6, 40), (0, 40), (2, 66), (4, 86), (17, 89), (19, 72), (22, 45)]
TH_ATRAS = [(-6, 58), (0, 58), (2, 80), (4, 96), (12, 96), (17, 90), (19, 72), (22, 45)]
TH_CAIDO = [(-6, -22), (0, -22), (3, -8), (8, 0), (12.5, 8), (13.6, 36), (15.5, 62), (22, 40)]


def clip_ataque_sismico():
    """La Fractura del Mar de Cristal: se alza hasta lo más alto con la vela erizada y las aletas abiertas (0 a 1,0),
    ruge arriba sacudiéndose (1,15 a 2,0), se echa un poco hacia atrás (2,0 a 2,1: la anticipación de la caída) y se
    desploma a lo largo como una torre, acelerando, hasta dar con la cabeza delante de los héroes (2,5333). En el golpe
    las placas del suelo se levantan alrededor de la cabeza, chocan y tiemblan, y el cuerpo entero vibra; después las
    placas se asientan, la cabeza se levanta del suelo y vuelve al reposo."""
    D = 3.8
    erguido = Pose(TH_ERGUIDO, ua=17.0, cab=(18, 0, 0), boca=20.0, placas=24.0, brillo=1.6, garganta=0.8, lat=20.0,
                   aleta=40.0)
    ruge = erguido.copia()
    ruge.cab, ruge.boca, ruge.placas, ruge.garganta, ruge.brillo = np.array((30.0, 0, 0)), 68.0, 32.0, 1.4, 1.9
    ruge.lat, ruge.aleta = 58.0, 52.0
    atras = Pose(TH_ATRAS, ua=17.0, cab=(26, 0, 0), boca=30.0, placas=34.0, brillo=2.0, garganta=1.0, lat=40.0, aleta=50.0)
    caido = Pose(TH_CAIDO, ua=13.6, cab=(-14, 0, 0), boca=0.0, placas=-8.0, brillo=1.7, garganta=0.6, lat=0.0, aleta=-6.0)
    golpe = caido.copia()
    golpe.losas = 1.0
    bote = golpe.copia()
    bote.th = bote.th + math.radians(7) * campana(-6, 8, 3)
    bote.placas = 18.0
    asentado = caido.copia()
    asentado.losas = 0.62
    claves = [(0.0, R0, ease), (1.0, erguido, ease), (1.2, ruge, ease_out), (2.0, ruge, ease), (2.1, atras, ease),
              (2.5333, caido, ease_in3), (2.68, bote, ease_out), (2.9, golpe, ease_in), (3.1, asentado, ease),
              (3.8, R0, ease)]
    poses = []
    for i in range(int(D * FPS) + 1):
        t = i / FPS
        p = tramos(t, claves)
        if 1.15 <= t <= 2.05:
            p = sacudir(p, t, ease((t - 1.15) / 0.15) * (1 - ease((t - 1.9) / 0.15)))
        if t >= 2.5333 - 1e-6:                                       # el golpe: las placas del suelo y el temblor
            dt = t - 2.5333
            sube = ease_out(dt / 0.12)
            baja = ease((t - 3.1) / 0.55)
            p.losas = max(0.0, sube * (1.0 - 0.38 * ease((t - 2.75) / 0.35)) * (1 - baja))
            for k in range(len(LOSAS)):
                p.losas_k[k] = 9.0 * math.exp(-dt / 0.35) * math.sin(2 * math.pi * (5.5 + k * 0.7) * dt + k)
            amort = math.exp(-dt / 0.45)
            for k in ALETAS:
                p.placas_k[k] = p.placas_k.get(k, 0.0) + 12.0 * amort * vibracion(t, 7.5, k)
            p.th = p.th + math.radians(2.0) * amort * np.sin(2 * math.pi * 6.0 * dt - U * 0.9) * campana(0, 14, 2)
        poses.append(p)
    return poses, {"erguido": 1.0, "rugido": 1.15, "caida": 2.1, "impacto": None, "placas_suelo": 2.5333,
                   "placas_asientan": 3.1, "placas_fin": 3.65}


def clip_ataque_aliento():
    """El Aliento del Desierto Eterno: baja la cabeza hacia la arena con las fauces y los abanicos abiertos (0 a 0,4);
    aspira (0,45 a 1,6): la arena sube en cintas hasta su boca, la garganta y la vela se encienden y el cuello se echa
    hacia atrás tragando; deja de aspirar (1,7) y se recoge un instante; en la descarga (1,85) lanza la cabeza hacia
    delante y escupe el chorro barriendo de un lado a otro (a los tres héroes) hasta 2,6; cierra y vuelve."""
    D = 3.6
    abre = pose_desde_reposo(math.radians(-6) * campana(0, 4.5, 2.0), cab=(-14, 0, 0), boca=55.0, placas=10.0, brillo=1.2,
                             garganta=0.8, lat=46.0, aleta=24.0)
    aspira = pose_desde_reposo(math.radians(14) * campana(0, 4.5, 2.0), ua=10.7, cab=(-4, 0, 0), boca=62.0, placas=26.0,
                               brillo=2.4, garganta=3.0, lat=58.0, aleta=40.0)
    aspira.succion = 1.0
    abre.succion = 0.35
    recoge = pose_desde_reposo(math.radians(22) * campana(0, 4.5, 2.0), ua=10.4, cab=(14, 0, 0), boca=30.0, placas=30.0,
                               brillo=2.5, garganta=3.0, lat=40.0, aleta=46.0)
    escupe = pose_desde_reposo(math.radians(-12) * campana(0, 4.5, 2.0), ua=11.8, cab=(-26, -16, 0), boca=76.0,
                               placas=-10.0, brillo=2.1, garganta=2.6, lat=64.0, aleta=50.0)
    barre = escupe.copia()
    barre.cab = np.array((-20.0, 16.0, 0.0))
    barre.garganta, barre.brillo, barre.lat = 1.4, 1.6, 56.0
    claves = [(0.0, R0, ease), (0.4, abre, ease), (1.6, aspira, ease), (1.78, recoge, ease_out), (1.85, escupe, ease_out),
              (2.6, barre, ease), (3.0, mezclar(barre, R0, 0.6), ease), (3.6, R0, ease)]
    poses = []
    for i in range(int(D * FPS) + 1):
        t = i / FPS
        p = tramos(t, claves)
        if t < 0.45:
            p.succion = 0.01
        elif t < 1.6:
            p.succion = max(0.01, ease((t - 0.45) / 0.25))
        else:
            p.succion = max(0.01, 1.0 - ease((t - 1.6) / 0.1))
        if 0.45 <= t < 1.85:
            p = sacudir(p, t, 0.45 * ease((t - 0.45) / 1.15), f=6.0)
        if 1.85 <= t < 2.7:
            p.chorro = ease((t - 1.85) / 0.1) * (1 - ease((t - 2.6) / 0.1)) * (1.0 + 0.04 * math.sin(2 * math.pi * 9 * t))
            p.cab = p.cab + np.array((1.5 * math.sin(2 * math.pi * 7 * t), 1.0 * math.sin(2 * math.pi * 5 * t), 0))
            for k in ALETAS:
                p.placas_k[k] = p.placas_k.get(k, 0.0) + 5.0 * vibracion(t, 8.0, k)
        poses.append(p)
    return poses, {"apertura": 0.3, "inicio_succion": 0.45, "carga_max": 1.6, "fin_succion": 1.7, "descarga": 1.85,
                   "fin_descarga": 2.6}


def clip_herida():
    """Recibe el golpe: la cabeza salta hacia atrás y se aparta, la vela se encoge y tiembla, las aletas se pliegan y
    la luz parpadea; vuelve al reposo."""
    D = 1.0
    golpe = pose_desde_reposo(math.radians(10) * campana(0, 5, 2.0), ua=10.7, cab=(12, -10, 10), boca=28.0, brillo=0.5,
                              lat=20.0, aleta=-12.0, placas=-12.0)
    vuelve = mezclar(golpe, R0, 0.65)
    claves = [(0.0, R0, ease), (0.1, golpe, ease_out), (0.4, vuelve, ease), (1.0, R0, ease)]
    poses = []
    for i in range(int(D * FPS) + 1):
        t = i / FPS
        p = tramos(t, claves)
        if 0.08 <= t < 0.95:
            for k in ALETAS:
                p.placas_k[k] = 9.0 * max(0.0, 1 - (t - 0.08) / 0.6) * vibracion(t, 7.5, k)
        if 0.08 <= t < 0.5:
            p.brillo = p.brillo * (0.7 + 0.3 * math.cos(2 * math.pi * 9 * t))
        poses.append(p)
    return poses, {"golpe": 0.1}


TH_DERRIBADO = [(-6, -18), (0, -18), (3, -6), (6, 2), (9, 10), (10.5, 30), (12, 55), (22, 30)]
DERROTA_UA = 10.5


def clip_derrota():
    """Se retuerce de dolor con la boca abierta y la luz parpadeando, la vela se desmorona, se desploma de lado y rueda
    (la cabeza da contra la arena: caida), rebota y se hunde a medias apagándose. Se queda así."""
    D = 3.4
    dolor = pose_desde_reposo(math.radians(8) * campana(0, 5, 2.0), cab=(25, 0, 0), boca=58.0, placas=12.0, brillo=1.4,
                              lat=44.0, aleta=30.0)
    caido = Pose(TH_DERRIBADO, ps=[(-6, 30), (9, 30), (11, 10), (14, 0)], ro=[(-6, 50), (9, 50), (11.5, 10), (14, 0)],
                 ua=DERROTA_UA, cab=(-10, 0, 35), boca=30.0, placas=-18.0, brillo=0.5, garganta=0.3, lat=22.0, aleta=-10.0)
    bote = caido.copia()
    bote.th = bote.th + math.radians(5) * campana(-6, 7, 3)
    hundido = caido.copia()
    hundido.ua = DERROTA_UA - 1.7
    hundido.boca, hundido.placas, hundido.brillo, hundido.garganta, hundido.lat = 34.0, -22.0, 0.08, 0.05, 30.0
    claves = [(0.0, R0, ease), (0.5, dolor, ease_out), (0.6, dolor, ease), (1.75, caido, ease_in), (1.9, bote, ease_out),
              (2.05, caido, ease_in), (3.4, hundido, ease)]
    poses = []
    for i in range(int(D * FPS) + 1):
        t = i / FPS
        p = tramos(t, claves)
        if t < 0.65:
            p = sacudir(p, t, ease(t / 0.2) * 0.8)
            p.brillo = p.brillo * (0.6 + 0.4 * (0.5 + 0.5 * math.sin(2 * math.pi * 6 * t)))
        if 1.0 <= t < 2.2:                                            # la vela se desmorona: cada espina a su ritmo
            for k in ALETAS:
                p.placas_k[k] = p.placas_k.get(k, 0.0) - 10.0 * ease((t - 1.0 - 0.03 * k) / 0.5)
        if t >= 2.2:
            for k in ALETAS:
                p.placas_k[k] = p.placas_k.get(k, 0.0) - 10.0
        poses.append(p)
    return poses, {"dolor": 0.5, "caida": None, "apagado": 3.0}


CLIPS = {"reposo": clip_reposo, "subterraneo": clip_subterraneo, "aviso": clip_aviso, "emerger": clip_emerger,
         "rugido": clip_rugido, "ataque": clip_ataque, "ataque_sismico": clip_ataque_sismico,
         "ataque_aliento": clip_ataque_aliento, "herida": clip_herida, "derrota": clip_derrota}
BUCLES = ["reposo", "subterraneo"]
# Los instantes de la v1 (el contrato de bramavidrio_3d.gd y de combate_bramavidrio.gd): los medidos en el clip deben
# caer en el mismo fotograma.
CONTRATO = {"emerger": {"rompe_arena": 0.2333, "pico": 0.8667, "erguido": 2.45}, "ataque": {"impacto": 1.0},
            "ataque_sismico": {"impacto": 2.5333}, "derrota": {"caida": 1.6}}


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
        hocico = mundo_de(arm, G, B, "cabeza", P_HOCICO())
        barbilla = mundo_de(arm, G, B, "mandibula", P_BARBILLA())
        bajo = mundo_de(arm, G, B, "mandibula", P_MAND_BAJO())
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
                fc.keyframe_points.foreach_set("interpolation", [1] * n)
                fc.update()
    arm.animation_data.action = None
    pista = arm.animation_data.nla_tracks.new()
    pista.name = nombre
    pista.strips.new(nombre, 1, act)
    pista.mute = True
    return medidas


def instantes(nombre, medidas, marcas):
    """Completa las marcas que se miden en el propio clip y las compara con el contrato de la v1."""
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
        extra["hocico_impacto"] = [round(medidas[i]["hocico"].x, 3), round(medidas[i]["hocico"].y, 3)]
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
    for k, v in CONTRATO.get(nombre, {}).items():
        if m.get(k) is None or abs(m[k] - v) > 0.5 / FPS:
            print("AVISO contrato: %s.%s medido %s, la v1 %.4f" % (nombre, k, m.get(k), v))
    return {k: v for k, v in m.items() if v is not None}, extra


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
    rgb[:] = mezclar_color(rgb, (0.85, 0.78, 0.66), np.clip(1.0 - np.abs(d - 2.2) / 0.9, 0, 1) * 0.22)
    if luz:
        dl = trazos(alto_px, ancho_px, luz, 4.0)
        brillo[:] = np.maximum(brillo, np.clip(1.4 - dl / 1.1, 0, 1))
        rgb[:] = mezclar_color(rgb, (0.55, 0.9, 0.95), np.clip(1.0 - dl / 1.0, 0, 1) * 0.6)


def pintar_textura(n_px):
    img = np.zeros((n_px, n_px, 3))
    brillo = np.zeros((n_px, n_px))
    rng = np.random.default_rng(1207)
    k = n_px / 2048.0

    def region(r):
        u0, u1, v0, v1 = r
        return int(v0 * n_px), int(v1 * n_px), int(u0 * n_px), int(u1 * n_px)

    # --- el cuerpo: escamas escalonadas (basalto) arriba, placas de arena en el vientre y la línea lateral
    y0, y1, x0, x1 = region(AT_TUBO)
    h, w = y1 - y0, x1 - x0
    uu = (np.arange(w) + 0.5) / w
    vv = (np.arange(h) + 0.5) / h
    alfa = (-math.pi + 2 * math.pi * uu)[None, :] * np.ones((h, 1))
    s = (S_INI + vv * (L_CUERPO - S_INI))[:, None] * np.ones((1, w))
    rs = np.interp(s, np.linspace(-1, 22, 200), [radio(x) for x in np.linspace(-1, 22, 200)])
    ca = np.cos(alfa)
    vientre = np.clip((-ca - 0.62) / 0.3, 0, 1)        # (11/11: las escamas bajan más; el vientre es una franja)
    vientre = vientre * vientre * (3 - 2 * vientre)
    n1 = fbm(h, w, 48, 12, 3, 4, envolver=True)
    n2 = fbm(h, w, 190, 48, 9, 3, envolver=True)
    # escamas: rejilla en metros (alrededor y a lo largo), filas desplazadas media escama
    X = alfa * rs * 1.04
    ew, eh = 0.42, 0.46
    fila = np.floor(s / eh)
    Xd = X / ew + 0.5 * np.mod(fila, 2)
    fx = np.mod(Xd, 1.0)
    fy = np.mod(s / eh, 1.0)
    frente = 0.32 * (1 - (2 * fx - 1) ** 2)                       # el borde de delante, en arco (lo tapa la anterior)
    dentro = fy - frente
    canto = np.minimum(np.minimum(fx, 1 - fx) * 2.2, np.clip(dentro / 0.12, 0, 1))
    tono_esc = (ruido_valor(h, w, int(28 / eh * 0.5) + 2, 60, 77, True) - 0.5) * 0.12
    basalto = np.ones((h, w, 3)) * np.array((0.105, 0.115, 0.15))[None, None, :]
    basalto = mezclar_color(basalto, (0.22, 0.23, 0.28), n1 * 0.9)
    basalto *= (1.0 + tono_esc)[..., None]
    basalto *= (0.62 + 0.38 * np.clip(dentro / 0.55, 0, 1))[..., None]          # sombra bajo la escama de delante
    basalto = mezclar_color(basalto, (0.40, 0.41, 0.46), np.clip((fy - 0.84) / 0.16, 0, 1) * 0.55 * (1 - vientre))   # canto de atrás gastado
    junta = np.clip(1 - canto / 0.25, 0, 1) * (dentro < 0.05)
    basalto = mezclar_color(basalto, (0.55, 0.42, 0.27), np.clip(1 - np.abs(dentro) / 0.06, 0, 1) * 0.65)   # arena en la junta
    basalto = mezclar_color(basalto, (0.06, 0.06, 0.08), np.clip(1 - np.minimum(fx, 1 - fx) / 0.04, 0, 1) * 0.6)
    lomo = np.clip(ca, 0, 1) ** 3
    basalto = mezclar_color(basalto, (0.33, 0.34, 0.40), lomo * 0.25 * n2)       # el lomo, pulido por la arena
    # vientre: placas anchas de arena erosionada, de través
    # (11/11, visto en el combate real: unas placas claras, regulares y muy marcadas se leían como los anillos de una
    # larva. Ahora son más oscuras, de arena gastada, irregulares y con la junta suave.)
    ty = np.mod(s / 0.58 + 0.25 * (n1 - 0.5) * np.cos(alfa * 3.0), 1.0)
    placa_v = np.ones((h, w, 3)) * np.array((0.50, 0.42, 0.32))[None, None, :]
    placa_v = mezclar_color(placa_v, (0.64, 0.55, 0.42), n1 * 0.6)
    placa_v *= (0.86 + 0.14 * np.clip(ty / 0.5, 0, 1))[..., None]
    placa_v = mezclar_color(placa_v, (0.30, 0.23, 0.18), np.clip(1 - ty / 0.04, 0, 1) * 0.4)
    placa_v = mezclar_color(placa_v, (0.86, 0.78, 0.62), np.clip((n2 - 0.6) * 4, 0, 1) * 0.35)
    rgb = basalto * (1 - vientre[..., None]) + placa_v * vientre[..., None]
    # la transición: piel de flanco con polvo
    flanco = np.exp(-((np.abs(alfa) - 2.05) / 0.22) ** 2)
    rgb = mezclar_color(rgb, (0.42, 0.33, 0.25), flanco * 0.55 * n1)
    rgb = mezclar_color(rgb, (0.72, 0.6, 0.44), np.clip((n2 - 0.66) * 4, 0, 1) * 0.35 * (1 - lomo))   # polvo
    rgb = mezclar_color(rgb, (0.66, 0.56, 0.42), np.clip((s - 19.5) / 2.0, 0, 1) * 0.5)
    b = np.zeros((h, w))
    # la línea lateral: una costura de vidrio con puntos encendidos
    lin = np.exp(-((np.abs(alfa) - math.radians(96)) / 0.05) ** 2) * (s > 0.5) * (s < 19.5)
    puntos = np.exp(-((np.mod(s, 0.72) - 0.36) / 0.1) ** 2) * np.exp(-((np.abs(alfa) - math.radians(96)) / 0.09) ** 2)
    rgb = mezclar_color(rgb, (0.35, 0.82, 0.9), np.clip(lin * 0.7 + puntos, 0, 1) * 0.85)
    b = np.maximum(b, np.clip(lin * 0.6 + puntos * 0.9, 0, 1) * (1 - 0.6 * np.clip((s - 14) / 6, 0, 1)))
    # vetas de cristal entre escamas, en el lomo (brillan)
    veta = np.clip(1 - np.abs(dentro) / 0.03, 0, 1) * np.clip((n2 - 0.55) * 5, 0, 1) * lomo
    b = np.maximum(b, veta * 0.7)
    rgb = mezclar_color(rgb, (0.45, 0.9, 0.95), veta * 0.6)
    pintar_grietas(rgb, b, rng, int(18), w, h, w * 0.012, 7, con_luz=0.4, zona=lambda xx, yy: True)
    img[y0:y1, x0:x1] = rgb
    brillo[y0:y1, x0:x1] = b

    # --- escamas sueltas (las de relieve): 4 × 8 losas de basalto
    y0, y1, x0, x1 = region(AT_ESCAMA)
    h, w = y1 - y0, x1 - x0
    uu = (np.arange(w) + 0.5) / w * 4
    vv = (np.arange(h) + 0.5) / h * 8
    fu = np.mod(uu, 1.0)[None, :] * np.ones((h, 1))
    fv = np.mod(vv, 1.0)[:, None] * np.ones((1, w))
    n1 = fbm(h, w, 40, 24, 21, 4)
    n2 = fbm(h, w, 160, 90, 22, 3)
    rgb = np.ones((h, w, 3)) * np.array((0.11, 0.12, 0.16))[None, None, :]
    rgb = mezclar_color(rgb, (0.26, 0.27, 0.32), n1)
    borde = np.minimum(np.minimum(fu, 1 - fu), np.minimum(fv, 1 - fv))
    rgb = mezclar_color(rgb, (0.42, 0.43, 0.48), np.clip(1 - borde / 0.08, 0, 1) * 0.5 * (0.5 + n2))
    rgb *= (0.7 + 0.3 * fv)[..., None]
    rgb = mezclar_color(rgb, (0.56, 0.57, 0.61), np.clip((n2 - 0.7) * 5, 0, 1) * 0.4)
    rgb = mezclar_color(rgb, (0.62, 0.50, 0.33), np.clip((0.3 - n2) * 5, 0, 1) * 0.5)
    b = np.zeros((h, w))
    pintar_grietas(rgb, b, rng, int(60), w, h, w * 0.03, 5, con_luz=0.55, oscuro=(0.04, 0.05, 0.07))
    img[y0:y1, x0:x1] = rgb
    brillo[y0:y1, x0:x1] = b

    # --- el cráneo
    y0, y1, x0, x1 = region(AT_CRANEO)
    h, w = y1 - y0, x1 - x0
    uu = (np.arange(w) + 0.5) / w
    vv = (np.arange(h) + 0.5) / h
    yn, yh = Y_NUCA(), Y_HOCICO()
    fi = (-math.pi / 2 + math.pi * uu)[None, :] * np.ones((h, 1))
    yy = (yn - vv * (yn - yh))[:, None] * np.ones((1, w))
    tabla_y = np.linspace(yh, yn, 64)
    tabla_w = np.array([craneo_param(y)[0] for y in tabla_y])
    xh = np.interp(yy, tabla_y, tabla_w) * np.sin(fi)
    n1 = fbm(h, w, 24, 16, 31, 4)
    n2 = fbm(h, w, 120, 80, 32, 3)
    rgb = np.ones((h, w, 3)) * np.array((0.10, 0.11, 0.15))[None, None, :]
    rgb = mezclar_color(rgb, (0.25, 0.26, 0.31), n1 * 0.9)
    dceja = np.vectorize(lambda x, y: dist_poli(abs(x), y, CEJA))(xh[::4, ::4], yy[::4, ::4])
    dceja = np.kron(dceja, np.ones((4, 4)))[:h, :w]
    rgb = mezclar_color(rgb, (0.46, 0.47, 0.52), np.exp(-(dceja / 0.09) ** 2) * 0.6)           # la ceja, gastada
    quilla = np.exp(-(xh / 0.12) ** 2) * np.clip((-yy - 1.2) / 0.8, 0, 1)
    rgb = mezclar_color(rgb, (0.42, 0.43, 0.48), quilla * 0.5)
    # escamas pequeñas en lo alto del cráneo
    ex = np.mod(xh / 0.22 + 0.5 * np.mod(np.floor(yy / 0.24), 2), 1.0)
    ey = np.mod(yy / 0.24, 1.0)
    esc = np.clip(np.minimum(np.minimum(ex, 1 - ex), np.minimum(ey, 1 - ey)) / 0.08, 0, 1)
    rgb *= (0.8 + 0.2 * esc)[..., None]
    lateral = np.clip((np.abs(fi) - 1.15) / 0.35, 0, 1)
    rgb = mezclar_color(rgb, (0.30, 0.25, 0.22), lateral * 0.45)
    b = np.zeros((h, w))
    for (fo, yo, a, bb, giro) in OJOS[VARIANTE]:                       # la cuenca del ojo, oscura, y un halo
        for lado in (-1, 1):
            cx = (lado * fo / math.pi + 0.5) * w
            cy = (yn - yo) / (yn - yh) * h
            Y, Xp = np.ogrid[0:h, 0:w]
            d = np.hypot((Xp - cx) / (w * 0.09 * a / 0.3), (Y - cy) / (h * 0.06 * a / 0.3))
            rgb[:] = mezclar_color(rgb, (0.05, 0.05, 0.07), np.clip(1.5 - d, 0, 1))
            b[:] = np.maximum(b, np.clip(1.3 - d, 0, 1) * 0.35)
    # vetas de cristal que bajan de la ceja (brillan) y una cicatriz vitrificada
    def a_px(x, y):
        wy = np.interp(y, tabla_y, tabla_w)
        f = math.asin(max(-1, min(1, x / wy)))
        return ((f / math.pi + 0.5) * w, (yn - y) / (yn - yh) * h)
    vetas = []
    for lado in (-1, 1):
        vetas.append([a_px(lado * x, y) for (x, y) in [(0.98, -0.6), (1.12, -0.85), (1.2, -0.9)]])
        vetas.append([a_px(lado * x, y) for (x, y) in [(0.7, -1.9), (0.86, -1.55), (1.0, -1.45)]])
    cic = [a_px(x, y) for (x, y) in [(-0.6, 0.6), (-0.25, 0.1), (0.1, -0.35), (0.35, -0.9)]]
    d = trazos(h, w, vetas + [cic], 10.0 * k)
    rgb = mezclar_color(rgb, (0.12, 0.1, 0.1), np.clip(1 - np.abs(d - 6 * k) / (2 * k), 0, 1) * 0.7)
    rgb = mezclar_color(rgb, (0.5, 0.9, 0.96), np.clip(1 - d / (2.6 * k), 0, 1) * 0.85)
    b = np.maximum(b, np.clip(1.6 - d / (2.2 * k), 0, 1))
    pintar_grietas(rgb, b, rng, 10, w, h, w * 0.025, 6, con_luz=0.3)
    img[y0:y1, x0:x1] = rgb
    brillo[y0:y1, x0:x1] = b

    # --- la mandíbula: basalto por los lados, arena erosionada por debajo (contrasombra) con estrías
    y0, y1, x0, x1 = region(AT_MANDIBULA)
    h, w = y1 - y0, x1 - x0
    tab = MANDS[VARIANTE]
    vv = (np.arange(h) + 0.5) / h
    ym = (tab[0][0] - vv * (tab[0][0] - tab[-1][0]))[:, None] * np.ones((1, w))
    uu = (np.arange(w) + 0.5) / w
    fi = (-math.pi / 2 + math.pi * uu)[None, :] * np.ones((h, 1))
    n1 = fbm(h, w, 16, 16, 41, 4)
    n2 = fbm(h, w, 90, 90, 42, 3)
    rgb = np.ones((h, w, 3)) * np.array((0.12, 0.12, 0.16))[None, None, :]
    rgb = mezclar_color(rgb, (0.28, 0.27, 0.30), n1 * 0.8)
    abajo = np.clip((np.cos(fi) - 0.55) / 0.3, 0, 1)
    gar = np.ones((h, w, 3)) * np.array(VIENTRE)[None, None, :]
    gar = mezclar_color(gar, (0.8, 0.7, 0.55), n1 * 0.6)
    gar *= (1 - 0.28 * (0.5 + 0.5 * np.cos(2 * math.pi * ym / 0.32)) ** 6)[..., None]
    rgb = rgb * (1 - abajo[..., None]) + gar * abajo[..., None]
    labio = np.clip((np.abs(fi) - 1.3) / 0.27, 0, 1)
    rgb = mezclar_color(rgb, (0.40, 0.40, 0.44), labio * 0.5)
    b = np.zeros((h, w))
    pintar_grietas(rgb, b, rng, 10, w, h, w * 0.025, 6, con_luz=0.3)
    img[y0:y1, x0:x1] = rgb
    brillo[y0:y1, x0:x1] = b

    # --- carne de la boca, neutro (dientes, cuernos, rayos), arena y roca
    y0, y1, x0, x1 = region(AT_CARNE)
    h, w = y1 - y0, x1 - x0
    n1 = fbm(h, w, 12, 24, 51, 4)
    rgb = np.ones((h, w, 3)) * np.array((0.34, 0.12, 0.11))[None, None, :]
    rgb = mezclar_color(rgb, (0.55, 0.22, 0.17), n1)
    rgb *= (1 - 0.25 * (0.5 + 0.5 * np.sin(np.arange(w)[None, :] / w * 60)) ** 4)[..., None]
    img[y0:y1, x0:x1] = rgb
    y0, y1, x0, x1 = region(AT_NEUTRO)
    img[y0:y1, x0:x1] = np.array((0.93, 0.91, 0.86))[None, None, :] * (0.95 + 0.05 * fbm(y1 - y0, x1 - x0, 8, 8, 61, 2))[..., None]
    y0, y1, x0, x1 = region(AT_ARENA)
    h, w = y1 - y0, x1 - x0
    n1 = fbm(h, w, 10, 30, 71, 4)
    n2 = fbm(h, w, 60, 60, 72, 3)
    rgb = np.array((0.72, 0.56, 0.36))[None, None, :] * (0.82 + 0.36 * n1)[..., None] * np.ones((h, w, 1))
    rgb = mezclar_color(rgb, (0.86, 0.76, 0.58), np.clip((n2 - 0.6) * 4, 0, 1) * 0.5)
    img[y0:y1, x0:x1] = rgb
    y0, y1, x0, x1 = region(AT_ROCA)
    h, w = y1 - y0, x1 - x0
    n1 = fbm(h, w, 10, 10, 81, 4)
    capas = (0.5 + 0.5 * np.sin((np.arange(h)[:, None] / h) * 40 + n1 * 6)) ** 3
    rgb = np.array((0.16, 0.16, 0.2))[None, None, :] * (0.8 + 0.5 * n1)[..., None] * np.ones((h, w, 1))
    rgb = mezclar_color(rgb, (0.45, 0.38, 0.3), capas * 0.4)
    img[y0:y1, x0:x1] = rgb
    return np.clip(img, 0, 1), np.clip(brillo, 0, 1)


def guardar_textura(ruta, rgb, a):
    n = rgb.shape[0]
    im = bpy.data.images.new(os.path.basename(ruta), n, n, alpha=True)
    # el alfa lleva un mínimo (ALFA_MIN): WebP con pérdida no guarda el color de los píxeles con alfa 0 (v1: error medio
    # 0,106 en ellos); el sombreador lo deshace: brillo = (a - ALFA_MIN) / (1 - ALFA_MIN)
    px = np.concatenate([rgb, (ALFA_MIN + (1 - ALFA_MIN) * a)[..., None]], axis=2).astype(np.float32)
    im.pixels.foreach_set(px.ravel())
    im.filepath_raw = ruta
    im.file_format = "WEBP"
    im.save(quality=92)
    bpy.data.images.remove(im)


def reducir(rgb, a, f):
    n = rgb.shape[0] // f
    return rgb.reshape(n, f, n, f, 3).mean(axis=(1, 3)), a.reshape(n, f, n, f).mean(axis=(1, 3))


# ---------------------------------------------------------------- materiales de Blender (para los renders)

def material(nombre, ruta_tex=None):
    m = bpy.data.materials.new(nombre)
    m.use_backface_culling = nombre not in ("chorro", "polvo")
    if hasattr(m, "use_nodes"):
        m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    vc = nt.nodes.new("ShaderNodeVertexColor")
    vc.layer_name = "Color"
    gam = nt.nodes.new("ShaderNodeGamma")
    gam.inputs["Gamma"].default_value = 2.2
    nt.links.new(vc.outputs["Color"], gam.inputs["Color"])
    bsdf.inputs["Roughness"].default_value = 0.75
    if nombre in ("piel", "arena") and ruta_tex:
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
        if nombre in ("vidrio", "garganta", "chorro", "polvo"):
            nt.links.new(gam.outputs["Color"], bsdf.inputs["Emission Color"])
            bsdf.inputs["Emission Strength"].default_value = {"vidrio": 1.6, "garganta": 4.0, "chorro": 3.0, "polvo": 1.0}[nombre]
            bsdf.inputs["Roughness"].default_value = 0.15
    return m


def conducir(arm, m, hueso, fuerza):
    """La fuerza de la emisión sigue a la escala del hueso (como hace el guion de Godot)."""
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
            conducir(arm, m, "brillo", 1.6)
        if nm == "garganta":
            conducir(arm, m, "garganta", 4.0)
        if nm == "chorro":
            conducir(arm, m, "chorro", 3.0)
        if nm == "polvo":
            conducir(arm, m, "succion", 1.0)
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


# ---------------------------------------------------------------- renders de los conceptos

def motor_eevee(sc):
    motores = [i.identifier for i in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    sc.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in motores else "BLENDER_EEVEE_NEXT"
    try:
        sc.view_settings.view_transform = "Standard"
    except Exception:
        pass


def luces_y_suelo(sc):
    mundo = bpy.data.worlds.new("cielo")
    sc.world = mundo
    mundo.use_nodes = True
    fondo = mundo.node_tree.nodes.get("Background")
    fondo.inputs["Color"].default_value = (0.42, 0.55, 0.75, 1)
    fondo.inputs["Strength"].default_value = 0.6
    me = bpy.data.meshes.new("suelo")
    me.from_pydata([(-300, -300, 0), (300, -300, 0), (300, 300, 0), (-300, 300, 0)], [], [(0, 1, 2, 3)])
    suelo = bpy.data.objects.new("suelo", me)
    sc.collection.objects.link(suelo)
    ms = bpy.data.materials.new("suelo_arena")
    ms.use_nodes = True
    ms.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.62, 0.44, 0.26, 1)
    ms.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 1.0
    me.materials.append(ms)
    for nombre, color, energia, rot in (("sol", (1.0, 0.90, 0.74), 3.4, (52, 0, -40)), ("cielo", (0.55, 0.65, 0.95), 1.0, (65, 0, 150))):
        l = bpy.data.lights.new(nombre, "SUN")
        l.color = color
        l.energy = energia
        o = bpy.data.objects.new(nombre, l)
        o.rotation_euler = [math.radians(a) for a in rot]
        sc.collection.objects.link(o)
    return suelo


def heroe_escala(sc, pos, alto):
    """Un muñeco de la escala de los héroes en el combate (chibi: cabeza grande), gris, para comparar."""
    objs = []
    for (tipo, rel, tam) in (("cabeza", (0, 0, 0.72), 0.27), ("cuerpo", (0, 0, 0.33), 0.2)):
        me = bpy.data.meshes.new(tipo)
        vs, fs = [], []
        n = 12
        for i in range(n + 1):
            th = math.pi * i / n
            for j in range(n):
                ph = 2 * math.pi * j / n
                k = (1.0, 1.0, 1.0 if tipo == "cabeza" else 1.7)
                vs.append((math.sin(th) * math.cos(ph) * tam * k[0], math.sin(th) * math.sin(ph) * tam * k[1], math.cos(th) * tam * k[2]))
        for i in range(n):
            for j in range(n):
                fs.append((i * n + j, i * n + (j + 1) % n, (i + 1) * n + (j + 1) % n, (i + 1) * n + j))
        me.from_pydata(vs, [], fs)
        me.shade_smooth()
        o = bpy.data.objects.new(tipo, me)
        o.location = Vector(pos) + Vector(rel) * alto
        o.scale = (alto, alto, alto)
        m = bpy.data.materials.new("heroe")
        m.use_nodes = True
        m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.55, 0.55, 0.6, 1)
        me.materials.append(m)
        sc.collection.objects.link(o)
        objs.append(o)
    return objs


def camara(sc, pos, mira, escala, ancho, alto):
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam_d.ortho_scale = escala
    cam_d.clip_end = 400
    cam = bpy.data.objects.new("cam", cam_d)
    sc.collection.objects.link(cam)
    sc.camera = cam
    cam.location = Vector(mira) + (Vector(pos) - Vector(mira)).normalized() * 120.0
    cam.rotation_euler = (Vector(mira) - cam.location).to_track_quat('-Z', 'Y').to_euler()
    sc.render.resolution_x, sc.render.resolution_y = ancho, alto
    sc.render.resolution_percentage = 100
    return cam


TRES_CUARTOS = (-48.0, -36.0, 12.6)            # la vista del combate: el gusano mira a los héroes, a la derecha


def pose_concepto():
    p = pose_reposo(0.0)
    p.boca, p.lat, p.aleta, p.placas = 30.0, 32.0, 22.0, 6.0
    p.cab = np.array((4.0, 10.0, 6.0))
    p.brillo = 1.2
    return p


def conceptos(carpeta):
    """Las tres propuestas, en la misma pose y con la misma luz: silueta de perfil y de tres cuartos (en negro), y a
    color (tres cuartos, como el combate, y la cabeza de cerca), con un muñeco de la escala de los héroes."""
    global VARIANTE, CONCEPTO, R0
    CONCEPTO = True
    os.makedirs(carpeta, exist_ok=True)
    for var in ("sierpe", "tragador", "capuchon"):
        VARIANTE = var
        sc = preparar_escena()
        arm = crear_esqueleto(sc)
        medir_signos(arm)
        R0 = pose_reposo(0.0)
        M = construir("alto")
        print("CONCEPTO", var, "triángulos", triangulos(M))
        obj = crear_objeto_malla(M, arm, "Concepto", None)
        bpy.context.view_layer.objects.active = arm
        bpy.ops.object.mode_set(mode='POSE')
        poner_pose(arm, pose_concepto())
        bpy.ops.object.mode_set(mode='OBJECT')
        suelo = luces_y_suelo(sc)
        heroe = heroe_escala(sc, (-1.0, -17.5, 0.0), 4.2)
        # siluetas (Workbench, plano, en negro)
        sc.render.engine = 'BLENDER_WORKBENCH'
        sc.display.shading.light = 'FLAT'
        sc.display.shading.color_type = 'OBJECT'
        sc.display.shading.background_type = 'VIEWPORT'
        sc.display.shading.background_color = (0.93, 0.88, 0.80)
        obj.color = (0.04, 0.035, 0.045, 1)
        suelo.color = (0.93, 0.88, 0.80, 1)
        for h in heroe:
            h.color = (0.55, 0.55, 0.6, 1)
        bpy.context.view_layer.objects.active = arm
        bpy.ops.object.mode_set(mode='POSE')
        p = pose_concepto()
        p.monticulo = 0.01
        poner_pose(arm, p)
        bpy.ops.object.mode_set(mode='OBJECT')
        for vista, pos, mira, esc in (("perfil", (60, -6, 7), (0, -6.5, 7.0), 24.0), ("tres_cuartos", TRES_CUARTOS, (0, -6.5, 7.0), 24.0)):
            cam = camara(sc, pos, mira, esc, 620, 640)
            sc.render.filepath = os.path.join(carpeta, "%s_silueta_%s.png" % (var, vista))
            bpy.ops.render.render(write_still=True)
            bpy.data.objects.remove(cam)
        # a color (Eevee)
        bpy.ops.object.mode_set(mode='POSE')
        poner_pose(arm, pose_concepto())
        bpy.ops.object.mode_set(mode='OBJECT')
        motor_eevee(sc)
        for vista, pos, mira, esc, an, al in (("color", TRES_CUARTOS, (-1.0, -7.5, 6.5), 22.0, 760, 640),
                                              ("cabeza", (-30, -38, 12), (0.0, -11.5, 8.0), 9.0, 620, 520),
                                              ("espalda", (30, 26, 16), (0.0, -2.0, 6.5), 22.0, 620, 640)):
            cam = camara(sc, pos, mira, esc, an, al)
            sc.render.filepath = os.path.join(carpeta, "%s_%s.png" % (var, vista))
            bpy.ops.render.render(write_still=True)
            bpy.data.objects.remove(cam)
        if SALIDA_BLEND:
            bpy.ops.wm.save_as_mainfile(filepath=os.path.join(carpeta, "concepto_%s.blend" % var))


# ---------------------------------------------------------------- principal

def principal():
    global R0
    os.makedirs(CARPETA, exist_ok=True)
    if MODO == "conceptos":
        conceptos(CARPETA)
        return
    modelo()


def modelo():
    """Las tres versiones (mismos huesos y clips), sus texturas y el JSON de clips."""
    global R0
    rgb, a = pintar_textura(TEX)
    rutas_tex = {}
    for perfil, f, suf in (("alto", 1, ""), ("medio", 2, "_medio"), ("bajo", 4, "_bajo")):
        r, al = (rgb, a) if f == 1 else reducir(rgb, a, f)
        ruta = os.path.join(CARPETA, "bramavidrio2_piel%s.webp" % suf)
        guardar_textura(ruta, r, al)
        rutas_tex[perfil] = ruta
        print("TEXTURA", ruta, r.shape[0], os.path.getsize(ruta))
    sc = preparar_escena()
    arm = crear_esqueleto(sc)
    medir_signos(arm)
    arm.animation_data_create()
    R0 = pose_reposo(0.0)
    resumen = {"fps": FPS, "variante": VARIANTE, "huesos": NOMBRES, "clips": {}, "triangulos": {}, "texturas": {}}
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
        exportar(os.path.join(CARPETA, "bramavidrio2%s.glb" % suf))
        if perfil == "alto" and SALIDA_BLEND:
            bpy.ops.wm.save_as_mainfile(filepath=SALIDA_BLEND)
            print("GUARDADO", SALIDA_BLEND)
        me = obj.data
        bpy.data.objects.remove(obj)
        bpy.data.meshes.remove(me)
    with open(os.path.join(CARPETA, "bramavidrio2_clips.json"), "w", encoding="utf-8", newline="\n") as fh:
        json.dump(resumen, fh, ensure_ascii=False, indent=1)
    print("RESUMEN", json.dumps(resumen["triangulos"]))


principal()
