# Bramavidrio, versión 3 (V12, noche del 11 al 12/11; encargo del usuario: la v2, «la Sierpe de la Vela», todavía no le
# convence y su boca parece partida, siempre entreabierta). Modelo, textura, esqueleto y clips hechos desde cero con este
# guion (geometría procedural propia y textura pintada por código: obra propia del proyecto, ningún recurso de fuera).
# La v1 (fuente/crear_bramavidrio.py) y la v2 (fuente/crear_bramavidrio2.py) no se tocan: esta escribe en
# enemigos/bramavidrio/v3/ con nombres nuevos. Los bloques genéricos (constructor de la malla, la «spline IK» de la
# columna, el pintor de la textura, los materiales y la exportación) son copia literal de crear_bramavidrio2.py.
#
#   blender -b --factory-startup -P crear_bramavidrio3.py -- <carpeta> [alto,medio,bajo] [<salida.blend>|-] [<variante>]
#   blender -b --factory-startup -P crear_bramavidrio3.py -- <carpeta> variantes [-] [garras,geoda,columnas]
#       (cada variante: su GLB alto con los 10 clips y su textura en <carpeta>/<variante>/, y las fotos de Blender de
#       frente, de perfil, boca cerrada, boca abierta y la vista del combate con tres muñecos de los héroes)
#
# LA BOCA. Por qué la de la v2 parecía rota (demostrado leyendo crear_bramavidrio2.py):
#   1) pose_reposo abría la mandíbula de 5 a 9° en todo el bucle (p.boca = 5 + 4·…), y Pose() la dejaba en 4° por
#      defecto: en ningún clip llegaba a cerrar;
#   2) aun a 0°, el labio del cráneo (z = −0,33 … −0,37) y el borde de la mandíbula (ZB_MAND = −0,43) no se tocaban:
#      una rendija de 6 a 10 cm a escala 1 (8 a 13 cm en el modelo) por la que se veía la carne roja;
#   3) cráneo y mandíbula eran dos cáscaras sueltas (el paladar colgaba del labio y la mandíbula era una canoa), unidas
#      solo por una membrana corta: al abrir se veían como dos piezas desplazadas.
# En la v3 la cabeza es UNA piel continua con la boca cortada como una ranura desde el hocico hasta la comisura:
#   - detrás de la comisura el anillo es uno solo; delante, el borde de arriba (labio) y el de abajo (mandíbula) son
#     vértices distintos que en reposo cierran CON SOLAPE: el labio baja por fuera del borde de la mandíbula
#     (sobremordida), así que la línea de cierre es limpia, sin rendija; el solape se desvanece en la comisura, donde
#     los dos bordes son el mismo vértice;
#   - la bisagra está en la comisura; paladar, encías, suelo con lengua y garganta son superficies que se cierran en un
#     tubo hacia el cuello; las mejillas son una piel doble que se estira al abrir;
#   - los dientes de arriba cuelgan por fuera de la mandíbula y los de abajo caben bajo el paladar: no se cruzan;
#   - boca = 0 en el reposo y nunca negativa; comprobar_boca() mide el cierre en cada fotograma y un árbol BVH comprueba
#     que cráneo y mandíbula no se atraviesan (en reposo y en los clips).
#
# TRES VARIANTES (todas con la misma cabeza articulada; cambian proporciones, armadura y adornos):
#   «garras»    el Excavador: dos brazos de basalto con garras de cristal apoyados en el borde del agujero (con IK:
#               las garras no patinan), cabeza ancha y pesada con cuernos cortos, placas grandes y cristales en racimo
#   «geoda»     la Corona de Geoda: sin brazos; la frente y el lomo se abren en geodas de cristal (grietas de las que
#               brotan racimos grandes); cabeza más larga
#   «columnas»  la Calzada: sin brazos; una cresta de columnas de basalto hexagonales de alturas escalonadas en la
#               cabeza y a lo largo del lomo, con cristal encendido entre ellas
# La elegida (la que exporta por defecto) es VARIANTE_FINAL.
#
# Ejes (Blender): mira a −Y, Z arriba, su izquierda es +X. En Godot mira a +Z. Pose de enlace: tendido a lo largo de +Y
# con la nuca en el origen; los clips lo colocan respecto del AGUJERO (el origen; en Godot, y = 0 es la arena).
#
# Esqueleto: raiz; col_01 (nuca) … col_18 (cola); cabeza; mandibula (bisagra en la comisura); ceja_izq / ceja_der (las
# placas de las cejas: el gesto); placa_02 … placa_17 (la armadura y los cristales del lomo: se erizan); los de datos
# brillo, garganta, chorro, succion, monticulo; losa_1 … losa_6 (las placas del suelo de la Fractura); y en «garras»
# hombro_izq / codo_izq / mano_izq y hombro_der / codo_der / mano_der.
# Animación: la «spline IK» de la v1/v2 (una curva de columna por fotograma, integrada desde el agujero) y una IK de dos
# huesos para los brazos (ancla en el mundo: garras apoyadas; o en el cuerpo: brazos que se mueven con él), horneadas a
# claves en cada fotograma. Mismos clips, duraciones e instantes que la v1/v2 (el contrato de combate_bramavidrio.gd).
#
# Materiales (los pone Godot, enemigos/bramavidrio/v3/bramavidrio3_3d.gd, por nombre de superficie): piel, vidrio,
# garganta, arena, chorro y polvo, como en la v2.
import bpy, sys, os, math, random, json
import numpy as np
from mathutils import Vector, Matrix, noise
from mathutils.bvhtree import BVHTree

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
CARPETA = argv[0] if argv else ""
MODO = argv[1] if len(argv) > 1 else "alto,medio,bajo"
PERFILES = [p for p in MODO.split(",") if p in ("alto", "medio", "bajo")]
SALIDA_BLEND = argv[2] if len(argv) > 2 and argv[2] not in ("", "-") else ""
VARIANTES = ["garras", "geoda", "columnas"]
VARIANTE_FINAL = "garras"
VARIANTE = argv[3] if len(argv) > 3 and argv[3] in VARIANTES else VARIANTE_FINAL
LISTA_VARIANTES = [v for v in (argv[3].split(",") if len(argv) > 3 and argv[3] else VARIANTES) if v in VARIANTES]
FPS = 30
CONCEPTO = False
PREFIJO = "bramavidrio3"

# ---------------------------------------------------------------- medidas

NSEG = 18
L_CUERPO = 22.0
LSEG = L_CUERPO / NSEG                     # 1,222 m por hueso de la columna
S_INI = -0.15                              # el tubo empieza dentro de la cabeza, DETRÁS de la garganta (v3: en la v2
#                                            empezaba en −0,8 y su punta cruzaba la boca; con la mandíbula abierta se veía)
ALETAS = range(2, NSEG)                    # huesos placa_kk (la armadura y los cristales del lomo: se erizan)
CALIDAD = {
    "alto": dict(lados=24, paso=0.46, cab_u=16, cab_l=12, cab_tras=4, cab_del=12, paladar=8, dientes=1.0, placas=1.0,
                 cr=6, mont=22, chorro=12, succion=10, losas=6, cuerno_lados=7, tex=2048, brazo_lados=9, racimo=1.0,
                 bisel=True),
    "medio": dict(lados=15, paso=0.78, cab_u=11, cab_l=8, cab_tras=3, cab_del=8, paladar=5, dientes=0.6, placas=0.5,
                  cr=5, mont=14, chorro=8, succion=7, losas=5, cuerno_lados=5, tex=1024, brazo_lados=6, racimo=0.6,
                  bisel=False),
    "bajo": dict(lados=10, paso=1.25, cab_u=8, cab_l=6, cab_tras=2, cab_del=6, paladar=3, dientes=0.34, placas=0.22,
                 cr=4, mont=9, chorro=6, succion=4, losas=4, cuerno_lados=4, tex=512, brazo_lados=5, racimo=0.3,
                 bisel=False),
}
Q = CALIDAD["alto"]

PIEL, VIDRIO, GARGANTA, ARENA, CHORRO, POLVO = range(6)
MATERIALES = ["piel", "vidrio", "garganta", "arena", "chorro", "polvo"]

# Atlas de la textura (u a la derecha, v hacia arriba, como en Blender): los mismos sitios que la v2
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
ENCIA = (0.58, 0.28, 0.26)
HUESO_DIENTE = ((0.86, 0.82, 0.72), (0.74, 0.70, 0.62), (0.92, 0.90, 0.84))

# Cuerpo de cada variante: radio a lo largo (desde la nuca). Más grueso y pesado que la v2.
RADIOS = {
    "garras": [(-1.0, 1.25), (0.0, 1.25), (1.5, 1.32), (3.0, 1.5), (5.0, 1.72), (7.5, 1.92), (9.5, 2.0), (12.0, 1.86),
               (15.0, 1.52), (17.5, 1.16), (19.5, 0.82), (21.0, 0.5), (21.8, 0.26), (22.0, 0.14)],
    "geoda": [(-1.0, 1.18), (0.0, 1.18), (1.5, 1.26), (3.0, 1.42), (6.0, 1.66), (10.0, 1.78), (14.0, 1.58),
              (17.0, 1.24), (19.5, 0.85), (21.0, 0.5), (21.8, 0.26), (22.0, 0.14)],
    "columnas": [(-1.0, 1.12), (0.0, 1.12), (1.5, 1.2), (3.0, 1.36), (6.0, 1.58), (10.0, 1.68), (14.0, 1.52),
                 (17.0, 1.2), (19.5, 0.84), (21.0, 0.5), (21.8, 0.26), (22.0, 0.14)],
}

# La cabeza (escala 1; se agranda K). Tablas (y, valor), de la nuca (y +) al hocico (y −):
#   W semiancho en la línea de la boca · H alto del cráneo sobre ella · P forma del arco de arriba (< 1: cuadrado) ·
#   D hondo de la mandíbula (y de la garganta, detrás) bajo ella · Z altura de la línea de la boca.
#   yn la nuca (atrás) · yh el hocico · yc la comisura (la bisagra) · ojo = (y, ángulo desde arriba, semiejes)
CABEZAS = {
    "garras": dict(yn=1.0, yh=-3.5, yc=-0.65, K=1.42,
                   W=[(1.0, 1.42), (0.4, 1.48), (-0.2, 1.52), (-0.8, 1.5), (-1.5, 1.38), (-2.2, 1.18), (-2.8, 0.96),
                      (-3.2, 0.74), (-3.5, 0.5)],
                   H=[(1.0, 1.02), (0.4, 1.18), (-0.2, 1.2), (-0.8, 1.08), (-1.5, 0.88), (-2.2, 0.7), (-2.8, 0.55),
                      (-3.2, 0.42), (-3.5, 0.28)],
                   P=[(1.0, 0.62), (-1.0, 0.66), (-2.6, 0.8), (-3.5, 0.95)],
                   D=[(1.0, 1.32), (0.4, 1.24), (-0.2, 1.1), (-0.8, 0.98), (-1.6, 0.82), (-2.4, 0.64), (-3.0, 0.5),
                      (-3.5, 0.36)],
                   Z=[(1.0, -0.1), (-0.65, -0.2), (-1.8, -0.27), (-2.8, -0.27), (-3.5, -0.2)],
                   ojo=(-1.35, 1.0, 0.37, 0.22)),
    "geoda": dict(yn=1.0, yh=-3.7, yc=-0.7, K=1.38,
                  W=[(1.0, 1.32), (0.4, 1.38), (-0.3, 1.42), (-1.0, 1.36), (-1.8, 1.16), (-2.6, 0.92), (-3.2, 0.7),
                     (-3.7, 0.42)],
                  H=[(1.0, 1.0), (0.4, 1.14), (-0.3, 1.14), (-1.0, 0.98), (-1.8, 0.76), (-2.6, 0.58), (-3.2, 0.44),
                     (-3.7, 0.26)],
                  P=[(1.0, 0.7), (-1.0, 0.72), (-2.6, 0.85), (-3.7, 1.0)],
                  D=[(1.0, 1.2), (0.4, 1.1), (-0.3, 0.98), (-1.0, 0.86), (-1.8, 0.7), (-2.6, 0.54), (-3.2, 0.42),
                     (-3.7, 0.3)],
                  Z=[(1.0, -0.08), (-0.7, -0.18), (-2.0, -0.24), (-3.0, -0.22), (-3.7, -0.14)],
                  ojo=(-1.42, 0.95, 0.35, 0.2)),
    "columnas": dict(yn=1.0, yh=-3.4, yc=-0.6, K=1.4,
                     W=[(1.0, 1.36), (0.4, 1.42), (-0.2, 1.46), (-0.9, 1.44), (-1.6, 1.3), (-2.3, 1.1), (-2.9, 0.86),
                        (-3.4, 0.56)],
                     H=[(1.0, 1.0), (0.4, 1.12), (-0.2, 1.12), (-0.9, 1.0), (-1.6, 0.84), (-2.3, 0.66), (-2.9, 0.5),
                        (-3.4, 0.3)],
                     P=[(1.0, 0.5), (-1.0, 0.55), (-2.6, 0.7), (-3.4, 0.9)],
                     D=[(1.0, 1.26), (0.4, 1.18), (-0.2, 1.06), (-0.9, 0.94), (-1.6, 0.78), (-2.3, 0.62), (-2.9, 0.48),
                        (-3.4, 0.36)],
                     Z=[(1.0, -0.1), (-0.6, -0.2), (-1.8, -0.28), (-2.9, -0.28), (-3.4, -0.22)],
                     ojo=(-1.3, 1.0, 0.34, 0.2)),
}
# La boca: sobremordida y grosores (escala 1; delante; se desvanecen en la comisura)
OV = 0.07          # el labio de arriba baja por debajo de la línea de la boca
TH_LABIO = 0.12    # grosor del labio de arriba (su cara de abajo)
INSET = 0.2        # la mandíbula queda por dentro del labio
UP = 0.05          # el borde de la mandíbula sube por encima de la línea (dentro del labio)
TH_LABIO_INF = 0.1
PAL_E, PAL_C = 0.3, 0.44        # el paladar: altura de su pared y de su centro sobre la línea de la boca
SUELO_E, SUELO_C = 0.2, 0.36    # el suelo de la boca: bajo la línea
L_MEJILLA = 1.1    # la piel de la mejilla cubre la ranura desde la comisura hasta aquí por delante
FONDO = 0.45       # la boca sigue por detrás de la comisura hasta la garganta
R_GARGANTA = 0.55
CHORRO_LARGO = 12.0


def CAB():
    return CABEZAS[VARIANTE]


def K_CAB():
    return CAB()["K"]


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
    return [S_INI] + [fin * i / n for i in range(n + 1) if fin * i / n > S_INI + 0.1]


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

def D(rgb, ao=1.0, mineral=0.0):
    """Color de vértice ENTERO (para lo que va sobre la zona neutra del atlas, que es casi blanca: columnas, cuellos de
    roca, palmas, párpados). Con C() en el modelo solo llevarían la oclusión y saldrían blancos."""
    return tuple(x * ao for x in rgb) + (mineral,)


def tab(nombre, y):
    return catmull([(-a, b) for (a, b) in CAB()[nombre]], -y)


def ranura(y):
    """1 en la boca (delante) y 0 en la comisura y detrás: la sobremordida se desvanece en la comisura."""
    c = CAB()
    return suave(c["yc"], c["yc"] - 0.7, y)


def ov(y):
    c = CAB()
    return OV * ranura(y) + 0.06 * suave(c["yh"] + 0.55, c["yh"], y)        # el pico del labio, delante


def y_mand(y):
    """La mandíbula es algo más corta que el hocico: el labio de arriba asoma delante como un pico."""
    c = CAB()
    if y >= c["yc"]:
        return y
    return c["yc"] + (y - c["yc"]) * (c["yc"] - (c["yh"] + 0.28)) / (c["yc"] - c["yh"])


def p_arriba(a, y):
    """Piel de arriba (el cráneo): a = 0 arriba, ±π/2 el labio (el borde de la ranura)."""
    W, H, pw, zm = tab("W", y), tab("H", y), tab("P", y), tab("Z", y)
    o = ov(y)
    x = W * math.sin(a)
    c = max(0.0, math.cos(a))
    z = zm - o + (H + o) * c ** pw
    ye, ae, sa, sb = CAB()["ojo"]
    d2 = ((abs(a) - ae) / 0.3) ** 2 + ((y - ye) / 0.48) ** 2              # la cuenca del ojo
    hund = 0.08 * math.exp(-d2)
    if abs(x) > 1e-6:
        x -= math.copysign(hund * 0.8, x)
    z -= hund * 0.4
    z += 0.06 * math.exp(-(x / 0.18) ** 2) * suave(-1.4, -2.4, y) * c ** 0.5   # la quilla del hocico
    z += 0.025 * noise.noise(Vector((x * 1.6, y * 1.6, 3.3))) * min(1.0, c * 4)
    return Vector((x, y, z))


def p_abajo(a, y):
    """Piel de abajo (mandíbula y, detrás, garganta): a = π abajo, π/2 y 3π/2 el borde de la ranura."""
    W, D, zm = tab("W", y), tab("D", y), tab("Z", y)
    f = ranura(y)
    x = (W - INSET * f) * math.sin(a)
    c = max(0.0, -math.cos(a))
    z = zm + UP * f - (D + UP * f) * c ** 0.75
    z -= 0.1 * math.exp(-((y - (CAB()["yh"] + 0.75)) / 0.4) ** 2) * c ** 2      # la barbilla
    z += 0.02 * noise.noise(Vector((x * 1.4, y * 1.4, 7.7))) * min(1.0, c * 4)
    return Vector((x, y, z))


def sup_craneo(a, y):
    p = p_arriba(a, y)
    n = (p_arriba(a + 0.01, y) - p_arriba(a - 0.01, y)).cross(p_arriba(a, y - 0.01) - p_arriba(a, y + 0.01))
    if n.dot(p - Vector((0.0, y, tab("Z", y)))) < 0:
        n = -n
    return p, n.normalized()


def peso_abajo(a, y):
    """La mandíbula sigue a «mandibula»; abajo y atrás (la garganta, junto a la bisagra) la piel se reparte con la
    cabeza para estirarse al abrir en vez de doblarse."""
    yc = CAB()["yc"]
    fondo = max(0.0, -math.cos(a))
    if y < yc:
        g = suave(0.35, 0.95, fondo) * suave(yc - 1.3, yc + 0.1, y) * 0.55
        return {"mandibula": 1 - g, "cabeza": g} if g > 0.01 else {"mandibula": 1.0}
    w = suave(0.15, 0.9, fondo) * (1.0 - suave(yc, yc + 0.9, y)) * 0.45
    return {"mandibula": w, "cabeza": 1 - w} if w > 0.01 else {"cabeza": 1.0}


def ancho_fondo(y):
    """Semiancho de la boca por detrás de la comisura (se estrecha hasta la garganta)."""
    c = CAB()
    return tab("W", c["yc"]) + (R_GARGANTA - tab("W", c["yc"])) * suave(c["yc"], c["yc"] + FONDO, y)


def pal_e(y):
    return min(PAL_E, 0.45 * tab("H", y))


def pal_c(y):
    return min(PAL_C, 0.62 * tab("H", y))


def suelo_e(y):
    return min(SUELO_E, 0.32 * tab("D", y))


def suelo_c(y):
    return min(SUELO_C, 0.58 * tab("D", y))


def lengua(y):
    c = CAB()
    return suave(c["yh"] + 0.4, c["yh"] + 1.3, y) * (1.0 - suave(c["yc"] - 0.2, c["yc"] + FONDO, y))


def doble(M, idx, mat):
    """Cara por los dos lados (piel fina), sin vértices repetidos (en la comisura los bordes coinciden)."""
    lim = []
    for i in idx:
        if not lim or lim[-1] != i:
            lim.append(i)
    if len(lim) > 1 and lim[0] == lim[-1]:
        lim.pop()
    if len(set(lim)) < 3:
        return
    M.doble(tuple(lim), mat)


def filas_y():
    c = CAB()
    tras = [c["yn"] + (c["yc"] - c["yn"]) * i / Q["cab_tras"] for i in range(Q["cab_tras"] + 1)]
    n = Q["cab_del"]
    dela = [c["yc"] + (c["yh"] - c["yc"]) * (0.5 - 0.5 * math.cos(math.pi * i / n)) for i in range(1, n + 1)]
    return tras + dela, Q["cab_tras"]


CABEZA_INFO = {}


def crear_cabeza(M):
    """La cabeza entera: piel de arriba y de abajo (una ranura de boca hasta la comisura), cierre con el cuello, labios
    y encías, paladar, suelo con lengua, mejillas, garganta y las tapas del hocico y de la barbilla."""
    c = CAB()
    yn, yh, yc = c["yn"], c["yh"], c["yc"]
    ys, ic = filas_y()
    nU, nL = Q["cab_u"], Q["cab_l"]
    U, L = [], []
    for i, y in enumerate(ys):
        fila = []
        for j in range(nU + 1):
            a = -math.pi / 2 + math.pi * j / nU
            lado = abs(math.sin(a))
            ao = 1.0 - 0.18 * suave(0.6, 1.0, lado) - 0.25 * suave(yn - 0.3, yn, y)
            fila.append(M.vert(p_arriba(a, y), C(BASALTO, ao, 0.9), en_atlas(AT_CRANEO, j / nU, (yn - y) / (yn - yh)),
                               "cabeza"))
        U.append(fila)
        yl = y_mand(y)
        fila = []
        for k in range(nL + 1):
            if i <= ic and k == 0:
                fila.append(U[i][nU])
                continue
            if i <= ic and k == nL:
                fila.append(U[i][0])
                continue
            a = math.pi / 2 + math.pi * k / nL
            ao = 1.0 - 0.15 * suave(0.6, 1.0, -math.cos(a))
            fila.append(M.vert(p_abajo(a, yl), C(BASALTO, ao, 0.85), en_atlas(AT_MANDIBULA, k / nL, (yn - yl) / (yn - yh)),
                               peso_abajo(a, yl)))
        L.append(fila)
    eje = lambda q: (0.0, q.y, tab("Z", q.y) + 0.1)
    rejilla(M, U, PIEL, fuera=eje)
    rejilla(M, L, PIEL, fuera=eje)
    # cierre con el cuello: un anillo sobre el tubo, detrás de la nuca (la piel de la cabeza se ciñe al cuello)
    yq = yn + 0.3
    rq = radio(yq * K_CAB()) / K_CAB() * 0.97
    pq = {k: v * 0.5 for k, v in peso_tubo(yq * K_CAB()).items()}
    pq["cabeza"] = pq.get("cabeza", 0.0) + 0.5
    cu = [M.vert((rq * math.sin(-math.pi / 2 + math.pi * j / nU), yq, rq * math.cos(-math.pi / 2 + math.pi * j / nU)),
                 C(BASALTO, 0.7, 0.8), en_atlas(AT_CRANEO, j / nU, 0.0), pq) for j in range(nU + 1)]
    cl = [cu[nU]] + [M.vert((rq * math.sin(math.pi / 2 + math.pi * k / nL), yq, rq * math.cos(math.pi / 2 + math.pi * k / nL)),
                            C(BASALTO, 0.7, 0.8), en_atlas(AT_MANDIBULA, k / nL, 0.0), pq) for k in range(1, nL)] + [cu[0]]
    rejilla(M, [cu, U[0]], PIEL, fuera=lambda q: (0.0, q.y - 0.5, 0.0))
    rejilla(M, [cl, L[0]], PIEL, fuera=lambda q: (0.0, q.y - 0.5, 0.0))

    # -- el interior: filas del hocico (delante) a la garganta (detrás)
    nP = Q["paladar"]
    yb = yc + FONDO
    interior = [(i, ys[i]) for i in range(len(ys) - 1, ic - 1, -1)] + [(None, yc + FONDO * 0.5), (None, yb)]
    n_int = len(interior)

    def arco(xs, zs, z_pared, z_centro, bulto=None):
        pts = [(xs, zs), (xs * 0.97, z_pared)]
        for m in range(1, nP):
            phi = math.pi / 2 - math.pi * m / nP
            x = xs * 0.97 * math.sin(phi)
            z = z_pared + (z_centro - z_pared) * math.cos(phi) ** 0.6
            if bulto:
                z += bulto * 0.14 * math.exp(-(x / 0.42) ** 2)
            pts.append((x, z))
        return pts + [(-xs * 0.97, z_pared), (-xs, zs)]

    PAL, SUE, BORDES = [], [], []          # filas del paladar y del suelo; por fila: (borde arriba, borde abajo) a cada lado
    for r, (i, y) in enumerate(interior):
        prof = r / (n_int - 1)                       # 0 delante, 1 en la garganta
        zm = tab("Z", y)
        if i is not None and i > ic:                 # en la ranura
            f = ranura(y)
            xa, za = tab("W", y) - TH_LABIO * f, zm - ov(y)
            yl = y_mand(y)
            zml = tab("Z", yl)
            xb, zb = tab("W", yl) - (INSET + TH_LABIO_INF) * f, zml + UP * f
        elif i is not None:                          # la comisura
            yl, zml = y, zm
            xa, za = tab("W", y), zm - ov(y)
            xb, zb = xa, za
        else:                                        # detrás de la comisura
            yl, zml = y, zm
            xa, za = ancho_fondo(y), zm + 0.03
            xb, zb = xa, zm - 0.03
        col_p = (mezcla((1, 1, 1), (0.35, 0.35, 0.35), prof) + (0.0,)) if not CONCEPTO else C(mezcla(ENCIA, (0.16, 0.1, 0.1), prof), 1.0, 0.0)
        pp = arco(xa, za, zm + pal_e(y), zm + pal_c(y))
        fila = [M.vert((x, y, z), col_p, en_atlas(AT_CARNE, m / (len(pp) - 1), 0.95 - 0.4 * prof), "cabeza")
                for m, (x, z) in enumerate(pp)]
        PAL.append(fila)
        wf = 1.0 if i is not None else 1.0 - 0.15 * (r - (n_int - 3))
        ps = arco(xb, zb, zml - suelo_e(yl), zml - suelo_c(yl), bulto=lengua(yl))
        fila = [M.vert((x, yl, z), col_p, en_atlas(AT_CARNE, m / (len(ps) - 1), 0.05 + 0.4 * prof),
                       {"mandibula": wf, "cabeza": 1 - wf} if wf < 0.999 else "mandibula")
                for m, (x, z) in enumerate(ps)]
        SUE.append(fila)
        BORDES.append((i, y, yl))
    rejilla(M, PAL, PIEL, hacia=lambda q: (0.0, q.y, tab("Z", q.y) - 0.3))
    rejilla(M, SUE, PIEL, hacia=lambda q: (0.0, q.y, tab("Z", q.y) + 0.3))

    # labios: la cara de abajo del labio de arriba (del borde de fuera a la encía) y la de arriba del de abajo
    for lado, jU, kL, m_p in ((1, nU, 0, 0), (-1, 0, nL, -1)):
        tira_a, tira_b = [], []
        for r, (i, y, yl) in enumerate(BORDES):
            if i is None or i < ic:
                break
            pa = M.v[U[i][jU]]
            pb = M.v[L[i][kL]]
            tira_a.append([M.vert(pa, (0.9, 0.9, 0.9, 0.0), en_atlas(AT_CARNE, 0.5, 0.985), "cabeza"), PAL[r][m_p]])
            tira_b.append([M.vert(pb, (0.9, 0.9, 0.9, 0.0), en_atlas(AT_CARNE, 0.5, 0.015), M.pesos[L[i][kL]]), SUE[r][m_p]])
        rejilla(M, tira_a, PIEL, hacia=lambda q: (q.x * 0.6, q.y, q.z - 1.0))
        rejilla(M, tira_b, PIEL, hacia=lambda q: (q.x * 0.6, q.y, q.z + 1.0))

    # mejillas: piel doble entre el labio de arriba y el borde de la mandíbula, de L_MEJILLA por delante de la comisura
    # hasta la garganta (detrás de la comisura, entre el paladar y el suelo)
    for lado, jU, kL, m_p in ((1, nU, 0, 0), (-1, 0, nL, -1)):
        filas = []
        for r, (i, y, yl) in enumerate(BORDES):
            if y < yc - L_MEJILLA:
                continue
            if i is not None and i > ic:
                arriba, abajo = PAL[r][m_p], L[i][kL]
            elif i is not None:
                arriba = abajo = U[i][jU]
            else:
                arriba, abajo = PAL[r][m_p], SUE[r][m_p]
            pa, pb = M.v[arriba], M.v[abajo]
            col_m = (0.55, 0.55, 0.55, 0.0) if not CONCEPTO else C(CARNE, 0.6, 0.0)
            if arriba == abajo:
                arriba = abajo = medio = M.vert(pa, col_m, en_atlas(AT_CARNE, 0.5, 0.5), M.pesos[arriba])
            else:
                arriba = M.vert(pa, col_m, en_atlas(AT_CARNE, 0.5, 0.47), M.pesos[arriba])
                abajo = M.vert(pb, col_m, en_atlas(AT_CARNE, 0.5, 0.53), M.pesos[abajo])
                q = (pa + pb) * 0.5
                q = Vector((q.x - lado * 0.05, q.y, q.z))
                wa, wb = M.pesos[arriba], M.pesos[abajo]
                pm = {}
                for d in (wa, wb):
                    for k, v in d.items():
                        pm[k] = pm.get(k, 0.0) + 0.5 * v
                medio = M.vert(q, (0.55, 0.55, 0.55, 0.0) if not CONCEPTO else C(CARNE, 0.6, 0.0), en_atlas(AT_CARNE, 0.5, 0.5), pm)
            filas.append((arriba, medio, abajo))
        for r in range(len(filas) - 1):
            a, b = filas[r], filas[r + 1]
            doble(M, (a[0], b[0], b[1], a[1]), PIEL)
            doble(M, (a[1], b[1], b[2], a[2]), PIEL)
        if lado == 1:
            medio_izq = filas[-1][1]
        else:
            medio_der = filas[-1][1]

    # la garganta: el anillo del fondo (paladar, mejilla, suelo, mejilla) y un túnel hacia el cuello con la luz al fondo
    anillo = PAL[-1][:] + [medio_der] + SUE[-1][::-1] + [medio_izq]
    zg = tab("Z", yb)
    c0 = Vector((0.0, yb, zg))
    anillos = [anillo]
    for (dy, s, luz, wm) in ((0.35, 0.8, 0.45, 0.5), (0.8, 0.62, 0.7, 0.25), (1.3, 0.45, 0.95, 0.0)):
        fila = []
        for idx in anillo:
            p = M.v[idx]
            q = Vector((p.x * s, yb + dy, zg + 0.05 * dy + (p.z - zg) * s))
            w = {"mandibula": wm, "cabeza": 1 - wm} if (p.z < zg and wm > 0) else "cabeza"
            fila.append(M.vert(q, (luz * 0.8, luz, luz), (0.5, 0.5), w))
        anillos.append(fila)
    rejilla(M, anillos, GARGANTA, cerrar_u=True, hacia=lambda q: (0.0, q.y, zg + 0.05 * (q.y - yb)))
    luz = M.vert((0.0, yb + 1.4, zg + 0.07), (1.0, 1.0, 1.0), (0.5, 0.5), "cabeza")
    n_a = len(anillo)
    for k in range(n_a):
        M.cara((anillos[-1][k], anillos[-1][(k + 1) % n_a], luz), GARGANTA, hacia=lambda q: (0.0, q.y - 1.0, q.z))

    # tapas: el hocico (labio de arriba) y la barbilla
    ult = len(ys) - 1
    for (borde, cierre, centro, atlas, peso) in (
            (U[ult] + PAL[0], None,
             Vector((0.0, yh - 0.1, tab("Z", yh) + 0.12)), AT_CRANEO, "cabeza"),
            (L[ult] + SUE[0][::-1], None,
             Vector((0.0, y_mand(yh) - 0.1, tab("Z", y_mand(yh)) - 0.3)), AT_MANDIBULA, "mandibula")):
        ids = []
        for q, idx in enumerate(borde):
            ids.append(M.vert(M.v[idx], C(BASALTO, 0.7, 0.8), en_atlas(atlas, q / len(borde), 0.995), M.pesos[idx]))
        cc = M.vert(centro, C(BASALTO, 0.8, 0.8), en_atlas(atlas, 0.5, 0.995), peso)
        for q in range(len(ids)):
            M.cara((ids[q], ids[(q + 1) % len(ids)], cc), PIEL, fuera=lambda p, c0_=centro: (c0_.x, c0_.y + 1.0, c0_.z))
    CABEZA_INFO.update(U=U, L=L, ys=ys, ic=ic, PAL=PAL, SUE=SUE)


def placa(M, sup, u0, v0, ru, rv, k, grosor, pesos, rnd, uv, color=BASALTO, alza=0.0, giro=0.0, bisel=None):
    """Una placa de armadura mineral sobre una superficie (sup(u, v) → (punto, normal)): polígono irregular de k lados,
    de tamaño y forma propios, con canto biselado y faldón hasta la piel (crece de ella; no está pegada encima). alza:
    cuánto se levanta el borde de atrás (+v), como una escama. pesos(u, v); uv(i, k, centro?)."""
    bisel = Q["bisel"] if bisel is None else bisel
    radios = [rnd.uniform(0.82, 1.15) for _ in range(k)]
    angs = [2 * math.pi * i / k + giro + rnd.uniform(-0.25, 0.25) for i in range(k)]
    pc, nc = sup(u0, v0)
    centro = M.vert(pc + nc * grosor * 1.15, C(color, 1.0, 1.0), uv(None), pesos(u0, v0))
    arriba, canto, pie = [], [], []
    for i in range(k):
        du, dv = math.cos(angs[i]) * ru * radios[i], math.sin(angs[i]) * rv * radios[i]
        lev = alza * max(0.0, math.sin(angs[i]))
        if bisel:
            p, n = sup(u0 + du * 0.78, v0 + dv * 0.78)
            arriba.append(M.vert(p + n * (grosor + lev * 0.8), C(color, 0.95, 1.0), uv((i, 0.78)), pesos(u0 + du * 0.78, v0 + dv * 0.78)))
        p, n = sup(u0 + du, v0 + dv)
        canto.append(M.vert(p + n * (grosor * 0.55 + lev), C(mezcla(color, BASALTO_CLARO, 0.45), 0.9, 1.0), uv((i, 1.0)),
                            pesos(u0 + du, v0 + dv)))
        pie.append(M.vert(p - n * 0.06, C(ARENA_C, 0.45, 0.0), uv((i, 1.05)), pesos(u0 + du, v0 + dv)))
    fuera = lambda q: pc - nc * 0.5
    top = arriba if bisel else canto
    for i in range(k):
        M.cara((top[i], top[(i + 1) % k], centro), PIEL, fuera=fuera)
        if bisel:
            M.cara((arriba[i], arriba[(i + 1) % k], canto[(i + 1) % k], canto[i]), PIEL, fuera=fuera)
        M.cara((canto[i], canto[(i + 1) % k], pie[(i + 1) % k], pie[i]), PIEL, fuera=lambda q: pc - nc * 0.3)


def uv_losa(sem):
    """Cada placa toma una losa de la zona de escamas del atlas (cuatro columnas, ocho filas; según su semilla)."""
    col, fila = sem % 4, (sem // 4) % 8

    def f(q):
        if q is None:
            return en_atlas(AT_ESCAMA, (col + 0.5) / 4, (fila + 0.5) / 8)
        i, r = q
        a = 2 * math.pi * i / 7.0
        return en_atlas(AT_ESCAMA, (col + 0.5 + 0.42 * min(r, 1.0) * math.cos(a)) / 4, (fila + 0.5 + 0.42 * min(r, 1.0) * math.sin(a)) / 8)
    return f


def racimo(M, base, normal, tam, n, hueso, rnd, color=VIDRIO_C, inclina=0.5, collar=True):
    """Un racimo de cristales fantásticos que brota de una grieta de la roca: prismas de punta, de tamaños distintos,
    abiertos desde la base (no bloques pegados), con un cuello de basalto roto alrededor."""
    n = max(1, int(round(n)))
    lados = Q["cr"]
    normal = normal.normalized()
    ref = Vector((1.0, 0.0, 0.0)) if abs(normal.x) < 0.8 else Vector((0.0, 1.0, 0.0))
    u = normal.cross(ref).normalized()
    w = normal.cross(u).normalized()
    for i in range(n):
        f = 1.0 if i == 0 else rnd.uniform(0.38, 0.78)
        ang = rnd.uniform(0, 2 * math.pi)
        incl = rnd.uniform(-0.12, 0.12) if i == 0 else rnd.uniform(0.35, 1.0) * inclina
        lat = u * math.cos(ang) + w * math.sin(ang)
        eje = (normal * math.cos(incl) + lat * math.sin(incl)).normalized()
        off = lat * tam * (0.0 if i == 0 else rnd.uniform(0.1, 0.22))
        alto = tam * f
        cristal(M, base + off, eje, alto * rnd.uniform(0.15, 0.2), alto, lados, hueso, rnd.uniform(0, 6),
                color=mezcla(color, (0.8, 1.0, 1.0), rnd.uniform(0.0, 0.35)), raiz=-0.32)
    if collar:
        kc = lados + 2
        dentro, fuera_ = [], []
        for i in range(kc):
            a = 2 * math.pi * i / kc
            lat = u * math.cos(a) + w * math.sin(a)
            rr = tam * 0.3 * rnd.uniform(0.85, 1.2)
            dentro.append(M.vert(base + lat * rr * 0.62 + normal * tam * rnd.uniform(0.1, 0.2), D(BASALTO_CLARO, 0.8, 1.0), neutro(), hueso))
            fuera_.append(M.vert(base + lat * rr - normal * 0.05, D(BASALTO, 0.6, 1.0), neutro(), hueso))
        for i in range(kc):
            M.cara((dentro[i], dentro[(i + 1) % kc], fuera_[(i + 1) % kc], fuera_[i]), PIEL, fuera=lambda q: base - normal * 0.6)


def columna(M, base, eje, r, alto, hueso, rnd, color=BASALTO):
    """Una columna de basalto hexagonal (como las de las coladas que se enfrían), con la cara de arriba algo inclinada y
    más clara, gastada por la arena."""
    eje = eje.normalized()
    ref = Vector((1.0, 0.0, 0.0)) if abs(eje.x) < 0.8 else Vector((0.0, 1.0, 0.0))
    u = eje.cross(ref).normalized()
    w = eje.cross(u).normalized()
    g = rnd.uniform(0, 1)
    inc = (u * rnd.uniform(-0.18, 0.18) + w * rnd.uniform(-0.18, 0.18))
    abajo, arriba = [], []
    for i in range(6):
        a = g + 2 * math.pi * i / 6
        lat = (u * math.cos(a) + w * math.sin(a)) * r * rnd.uniform(0.92, 1.06)
        abajo.append(M.vert(base + lat - eje * 0.4, D(color, 0.55, 1.0), neutro(), hueso))
        arriba.append(M.vert(base + lat + eje * (alto + lat.dot(inc)), D(mezcla(color, BASALTO_CLARO, 0.25), 0.95, 1.0), neutro(), hueso))
    eje_c = lambda q: base + eje * eje.dot(q - base)
    for i in range(6):
        M.cara((abajo[i], abajo[(i + 1) % 6], arriba[(i + 1) % 6], arriba[i]), PIEL, fuera=eje_c)
    tapa = M.vert(base + eje * (alto * 1.02), D(mezcla(color, (0.5, 0.48, 0.46), 0.55), 1.0, 1.0), neutro(), hueso)
    for i in range(6):
        M.cara((arriba[i], arriba[(i + 1) % 6], tapa), PIEL, fuera=lambda q: base)


# ---------------------------------------------------------------- la armadura del cuerpo

def crear_placas_cuerpo(M):
    """Placas de basalto de tamaños y formas distintas (más grandes en la cruz y los hombros, menores hacia la cola), en
    filas desplazadas (no anillos), sobre el lomo y los costados de arriba. El vientre es de arena (textura)."""
    rnd = random.Random(53 + VARIANTES.index(VARIANTE))
    dens = Q["placas"]
    sem = 0
    s = 0.5
    fila = 0
    while s < 19.6:
        r = radio(s)
        largo = (0.95 + 0.55 * suave(0.0, 6.0, s) * (1 - suave(10.0, 18.0, s))) * rnd.uniform(0.9, 1.12)
        if dens < 0.4:
            alfas = [0.0]
        elif dens < 0.8:
            alfas = [-0.62, 0.0, 0.62]
        else:
            n_al = 5 if r > 1.5 else 3
            paso_a = 1.25 / max(1, (n_al - 1) // 2) * 0.98
            alfas = [(m - (n_al - 1) / 2) * paso_a for m in range(n_al)]
        des = 0.5 * (fila % 2)
        for a0 in alfas:
            a = a0 + (des * (alfas[1] - alfas[0]) if len(alfas) > 1 else 0.0) * (0.5 if abs(a0) < 1.2 else 0.0)
            if abs(a) > 1.6:
                continue
            tam = rnd.uniform(0.78, 1.25) * (1.25 if abs(a) < 0.2 else 1.0)
            ru = 0.5 * largo * tam / r          # en radianes alrededor
            rv = 0.5 * largo * tam
            hueso_s = s + rnd.uniform(-0.1, 0.1)
            pes = (lambda uu, vv: peso_tubo(vv)) if abs(a) > 0.2 else (lambda uu, vv: {**{k_: w_ * 0.3 for k_, w_ in peso_tubo(vv).items()}, hueso_vela(vv): 0.7} if 2 <= int(vv // LSEG) + 1 <= NSEG - 1 else peso_tubo(vv))
            placa(M, sup_cuerpo, a, hueso_s, ru, rv, 6 if dens > 0.8 else 5, 0.07 * r ** 0.5, pes, rnd, uv_losa(sem),
                  alza=0.08 * r ** 0.5, giro=rnd.uniform(0, 1))
            sem += 1
        s += largo * 0.92
        fila += 1


def crear_racimos_lomo(M, lista):
    """Racimos de cristal que brotan entre las placas del lomo: [(s, alfa, tamaño, número)]. Siguen a su hueso placa_kk
    (se erizan y vibran con la armadura)."""
    rnd = random.Random(29 + VARIANTES.index(VARIANTE))
    for (s, alfa, tam, n) in lista:
        if Q["racimo"] < 0.5 and tam < 1.0:
            continue
        r = radio(s)
        x, z = seccion(alfa, r * 0.98)
        base = Vector((x, s, z))
        nrm = Vector((x, 0.0, z)).normalized()
        nrm = (nrm + Vector((0.0, 0.35, 0.0))).normalized()        # hacia la cola
        racimo(M, base, nrm, tam, n * Q["racimo"] + 0.4, hueso_vela(s), rnd)


def crear_columnas_lomo(M):
    """La Calzada: una cresta de columnas de basalto hexagonales a lo largo del lomo, en dos hileras al tresbolillo y de
    alturas escalonadas, con astillas de cristal encendido entre ellas."""
    rnd = random.Random(41)
    s = 0.7
    k = 0
    while s < 17.5:
        r = radio(s)
        h0 = catmull([(0.0, 0.9), (2.0, 1.6), (5.0, 1.9), (9.0, 1.5), (13.0, 1.0), (17.5, 0.45)], s)
        for lado in ((-1, 1) if Q["placas"] > 0.4 else (0,)):
            a = lado * 0.2
            x, z = seccion(a, r * 0.94)
            base = Vector((x, s + (0.3 if lado > 0 else 0.0), z))
            nrm = Vector((x * 0.3, 0.12, z)).normalized()
            h = h0 * rnd.choice((0.6, 0.8, 1.0, 1.15))
            columna(M, base, nrm, 0.26 + 0.06 * r, h, hueso_vela(s), rnd)
        if k % 2 == 0 and Q["racimo"] > 0.5:
            x, z = seccion(0.0, r)
            cristal(M, Vector((x, s + 0.15, z)), Vector((0.0, 0.25, 1.0)), 0.08, h0 * 0.75, 4, hueso_vela(s), rnd.uniform(0, 6), raiz=-0.4)
        s += 0.62 if s < 12 else 0.75
        k += 1


# ---------------------------------------------------------------- los brazos («garras»)

S_HOMBRO = 8.9
MANO = Vector((0.0, -1.0, -0.15)).normalized()   # la dirección de la mano en la pose de enlace (hacia delante)


def tiene_brazos():
    return VARIANTE == "garras"


def puntos_brazo(lado):
    """Hombro, codo y muñeca en la pose de enlace (cuerpo tendido a lo largo de +Y, el vientre a −Z)."""
    r = radio(S_HOMBRO)
    x, z = seccion(lado * 1.72, r * 0.82)
    S = Vector((x, S_HOMBRO, z))
    E = S + Vector((lado * 1.35, -0.55, -1.75))
    W = E + Vector((lado * 0.2, -1.45, -1.2))
    return S, E, W


def crear_brazos(M):
    """Dos brazos de basalto que nacen de los costados junto al agujero: hombro con hombrera y racimo de cristal,
    antebrazo con espolones y una mano ancha con tres garras de cristal y un pulgar. Pesos repartidos en el hombro, el
    codo y la muñeca (se doblan sin romperse)."""
    rnd = random.Random(91)
    nl = Q["brazo_lados"]
    for lado in (-1, 1):
        sfx = "izq" if lado > 0 else "der"
        hb, cb, mb = "hombro_" + sfx, "codo_" + sfx, "mano_" + sfx
        S, E, W = puntos_brazo(lado)
        dentro = S - Vector((lado * 0.9, 0.0, -0.15))
        pt = peso_tubo(S_HOMBRO)
        mitad = lambda a, b: {k: a.get(k, 0) * 0.5 + b.get(k, 0) * 0.5 for k in set(a) | set(b)}
        tramo = [(dentro, 0.95, pt), (S, 0.88, mitad(pt, {hb: 1.0})), (S.lerp(E, 0.5), 0.7, {hb: 1.0}),
                 (E, 0.6, {hb: 0.5, cb: 0.5}), (E.lerp(W, 0.5), 0.52, {cb: 1.0}), (W, 0.5, {cb: 0.5, mb: 0.5}),
                 (W + MANO * 0.35, 0.5, {mb: 1.0})]
        anillos = []
        for q, (p, rr, w) in enumerate(tramo):
            d = ((tramo[min(q + 1, len(tramo) - 1)][0] - tramo[max(q - 1, 0)][0])).normalized()
            ref = Vector((0.0, 0.0, 1.0)) if abs(d.z) < 0.85 else Vector((0.0, 1.0, 0.0))
            uu = d.cross(ref).normalized()
            ww = d.cross(uu).normalized()
            fila = []
            for i in range(nl):
                a = 2 * math.pi * i / nl
                ancho = 1.0 if q < 6 else 1.25
                pos = p + (uu * math.cos(a) * ancho + ww * math.sin(a) * (1.0 if q < 6 else 0.62)) * rr
                fila.append(M.vert(pos, C(BASALTO, 0.85, 0.8), en_atlas(AT_TUBO, 0.25 + 0.5 * i / nl, (S_HOMBRO - S_INI + q * 0.7) / (L_CUERPO - S_INI)), w))
            anillos.append(fila)
        eje = lambda c, T=tramo: min((p for (p, _, _) in T), key=lambda z: (z - c).length)
        rejilla(M, anillos, PIEL, cerrar_u=True, fuera=eje)
        # la palma: un bloque ancho y plano que acaba en las garras
        fin = W + MANO * 0.85
        cp = M.vert(fin, D(BASALTO, 0.8, 0.8), neutro(), mb)
        for i in range(nl):
            M.cara((anillos[-1][i], anillos[-1][(i + 1) % nl], cp), PIEL, fuera=lambda c: W)
        lateral = Vector((lado, 0.0, 0.0))
        arriba = MANO.cross(lateral).normalized()
        if arriba.z < 0:
            arriba = -arriba
        for g, (sesgo, largo) in enumerate(((-0.42, 1.0), (0.0, 1.12), (0.42, 0.95))):
            base = W + MANO * 0.6 + lateral * sesgo * 0.55 - arriba * 0.1
            d = (MANO + lateral * sesgo * 0.55 - arriba * 0.25).normalized()
            colmillo(M, base, d, -arriba * 1.2 + MANO * 0.2, largo, 0.16, max(4, nl - 3), mb, color=(0.24, 0.24, 0.29), mineral=1.0, rnd=rnd)
            punta = base + d * largo + (-arriba * 1.2 + MANO * 0.2) * largo * 0.38
            cristal(M, punta - d * 0.22, (d - arriba * 0.9).normalized(), 0.1, 0.62, 4, mb, 0.4)
        colmillo(M, W + MANO * 0.25 - lateral * 0.42, (MANO - lateral * 0.6 - arriba * 0.3).normalized(), -arriba,
                 0.62, 0.13, 4, mb, color=(0.24, 0.24, 0.29), mineral=1.0, rnd=rnd)
        # la hombrera: una placa grande y un racimo de cristal; espolones en el antebrazo
        out = (lateral + Vector((0.0, 0.0, 0.6))).normalized()
        racimo(M, S + out * 0.75 + Vector((0.0, 0.2, 0.0)), (out + Vector((0.0, 0.5, 0.3))).normalized(), 1.1,
               3 * Q["racimo"] + 0.6, hb, rnd)
        for t in ((0.35, 0.5), (0.65, 0.42)):
            p = E.lerp(W, t[0])
            d = (lateral + Vector((0.0, 0.7, 0.2))).normalized()
            colmillo(M, p + lateral * 0.38, d, Vector((0.0, 1.0, 0.0)), t[1], 0.1, 4, cb, color=(0.26, 0.26, 0.3), mineral=1.0, rnd=rnd)


# ---------------------------------------------------------------- la cara: ojos, cejas, fosetas, dientes y cuernos

def en_craneo(a0, y0, d):
    """El punto del cráneo a un desplazamiento d (en el mundo) de (a0, y0): pasa d a (ángulo, y) y vuelve a la piel
    (los ojos y las fosetas se ciñen a la curva del cráneo en vez de quedarse en un plano)."""
    p0 = p_arriba(a0, y0)
    ta = p_arriba(a0 + 0.01, y0) - p_arriba(a0 - 0.01, y0)
    da = d.dot(ta.normalized()) / (ta.length / 0.02)
    return sup_craneo(a0 + da, y0 + d.y)


def crear_ojos(M):
    """Ojos grandes de vidrio encendido (lo que más expresa): almendra inclinada (mirada de depredador), iris turquesa,
    pupila de rendija y un brillo blanco (la chispa de los JRPG); un párpado de basalto alrededor."""
    ye, ae, sa, sb = CAB()["ojo"]
    g = -0.32
    m = 12 if Q["cab_u"] >= 12 else 8
    for lado in (-1, 1):
        p, n = sup_craneo(lado * ae, ye)
        fwd = Vector((0.0, -1.0, 0.0)) - n * n.y
        fwd.normalize()
        arr = n.cross(fwd).normalized()
        if arr.z < 0:
            arr = -arr
        rot = lambda u, v: fwd * (u * math.cos(g) - v * math.sin(g)) + arr * (u * math.sin(g) + v * math.cos(g))

        def alm(t, k, alto):
            s_ = math.sin(t)
            q, nq = en_craneo(lado * ae, ye, rot(sa * k * math.cos(t), sb * k * s_ * (1.0 if s_ > 0 else 0.72)))
            return q + nq * alto
        parp = [M.vert(alm(2 * math.pi * i / m, 1.28, 0.035), D(BASALTO, 0.5, 1.0), neutro(), "cabeza") for i in range(m)]
        borde = [M.vert(alm(2 * math.pi * i / m, 1.0, 0.03), (0.05, 0.2, 0.24), neutro(), "cabeza") for i in range(m)]
        iris = [M.vert(alm(2 * math.pi * i / m, 0.64, 0.06), (0.55, 1.0, 0.86), neutro(), "cabeza") for i in range(m)]
        pc, nc = en_craneo(lado * ae, ye, Vector())
        pup = [M.vert(en_craneo(lado * ae, ye, rot(0.0, s * sb * 0.52))[0] + nc * 0.075, (0.02, 0.04, 0.05), neutro(), "cabeza")
               for s in (-1, 1)]
        dentro = lambda c, q=pc - nc: q
        for i in range(m):
            M.cara((parp[i], parp[(i + 1) % m], borde[(i + 1) % m], borde[i]), PIEL, fuera=dentro)
            M.cara((borde[i], borde[(i + 1) % m], iris[(i + 1) % m], iris[i]), VIDRIO, fuera=dentro)
        for i in range(m):
            j = pup[1] if math.sin(2 * math.pi * (i + 0.5) / m) > 0 else pup[0]
            M.cara((iris[i], iris[(i + 1) % m], j), VIDRIO, fuera=dentro)
        M.cara((pup[0], iris[0], pup[1]), VIDRIO, fuera=dentro)
        M.cara((pup[1], iris[m // 2], pup[0]), VIDRIO, fuera=dentro)
        c0 = en_craneo(lado * ae, ye, rot(-sa * 0.22, sb * 0.3))[0] + nc * 0.085
        br = [M.vert(c0 + rot(0.06 * math.cos(a), 0.06 * math.sin(a)), (1.0, 1.0, 1.0), neutro(), "cabeza")
              for a in (0.3, 2.4, 4.4)]
        M.cara(tuple(br), VIDRIO, fuera=dentro)


def crear_cejas(M):
    """Las cejas: una placa gruesa de basalto sobre cada ojo (huesos ceja_izq / ceja_der, bisagra atrás). Al bajar,
    el ceño se frunce en «V» (la furia de los ataques); al subir, la sorpresa del golpe."""
    ye, ae, sa, sb = CAB()["ojo"]
    rnd = random.Random(17)
    for lado, sfx in ((1, "izq"), (-1, "der")):
        placa(M, sup_craneo, lado * (ae - 0.42), ye + 0.08, 0.2, 0.62, 7 if Q["bisel"] else 5, 0.12,
              lambda u, v, s_=sfx: {"ceja_" + s_: 1.0}, rnd, uv_losa(3 + (lado > 0)), alza=-0.05, giro=0.2)


def crear_fosetas(M):
    """Fosetas sensoriales: tres hoyos de cristal encendido a cada lado del hocico, bajo el ojo (siente el calor y el
    temblor de la arena: la inteligencia del depredador)."""
    if Q["dientes"] < 0.5:
        return
    ye, ae, sa, sb = CAB()["ojo"]
    for lado in (-1, 1):
        for (dy, da, rr) in ((-0.62, 0.3, 0.085), (-0.98, 0.34, 0.072), (-1.3, 0.38, 0.06)):
            a, y = lado * min(1.42, ae + da), ye + dy
            p, n = sup_craneo(a, y)
            t1 = n.cross(Vector((0.0, 1.0, 0.0))).normalized()
            t2 = n.cross(t1).normalized()
            borde = [M.vert(p + (t1 * math.cos(2 * math.pi * i / 6) + t2 * math.sin(2 * math.pi * i / 6)) * rr * 1.45 + n * 0.02,
                            D(BASALTO, 0.45, 1.0), neutro(), "cabeza") for i in range(6)]
            luz = [M.vert(p + (t1 * math.cos(2 * math.pi * i / 6) + t2 * math.sin(2 * math.pi * i / 6)) * rr - n * 0.01,
                          (0.35, 0.95, 1.0), neutro(), "cabeza") for i in range(6)]
            cen = M.vert(p - n * 0.02, (0.8, 1.0, 1.0), neutro(), "cabeza")
            dentro = lambda c, q=p - n: q
            for i in range(6):
                M.cara((borde[i], borde[(i + 1) % 6], luz[(i + 1) % 6], luz[i]), PIEL, fuera=dentro)
                M.cara((luz[i], luz[(i + 1) % 6], cen), VIDRIO, fuera=dentro)


def crear_dientes(M):
    """Dientes: arriba cuelgan del labio por FUERA de la mandíbula (sobremordida: se ven con la boca cerrada), con un
    gran colmillo de cristal delante; abajo, una fila menor que cabe bajo el paladar. Ninguno atraviesa la otra
    mandíbula ni con la boca cerrada ni al abrir."""
    rnd = random.Random(77)
    c = CAB()
    yh, yc = c["yh"], c["yc"]
    f = Q["dientes"]
    lados = 5 if f >= 1 else (4 if f > 0.5 else 3)
    n_arr = max(2, int(round(8 * f)))
    n_aba = max(2, int(round(7 * f)))
    for sx in (-1, 1):
        for i in range(n_arr):
            t = (i + 0.5) / n_arr
            y = (yh + 0.3) + (yc - 0.4 - (yh + 0.3)) * t
            fr = ranura(y)
            x = sx * (tab("W", y) - TH_LABIO * fr * 0.45)
            z = tab("Z", y) - ov(y) + 0.03
            grande = i == 1
            largo = 0.62 if grande else rnd.uniform(0.2, 0.34) * (1.0 - 0.35 * t)
            grueso = 0.095 if grande else rnd.uniform(0.05, 0.068)
            colmillo(M, Vector((x, y, z)), Vector((sx * 0.13, 0.08, -1.0)), Vector((sx * 0.1, 0.55, 0.0)), largo, grueso,
                     lados + (1 if grande else 0), "cabeza", vidrio=grande, rnd=rnd)
        for i in range(n_aba):
            t = (i + 0.5) / n_aba
            y0 = y_mand(yh + 0.5)
            yl = y0 + (yc - 0.45 - y0) * t
            fr = ranura(yl)
            x = sx * (tab("W", yl) - (INSET + TH_LABIO_INF * 0.5) * fr)
            z = tab("Z", yl) + UP * fr - 0.03
            largo = min(rnd.uniform(0.13, 0.19) * (1 - 0.3 * t), pal_e(yl) - UP * fr - 0.07)    # cabe bajo el paladar
            colmillo(M, Vector((x, yl, z)), Vector((-sx * 0.1, 0.0, 1.0)), Vector((-sx * 0.1, 0.5, 0.0)),
                     largo, rnd.uniform(0.045, 0.058), lados, "mandibula",
                     vidrio=rnd.random() < 0.25, rnd=rnd)


def placas_craneo(M, lista, rnd):
    """Placas de armadura del cráneo: [(ángulo, y, radio en ángulo, radio en y)]."""
    for q, (a, y, ra, rv) in enumerate(lista):
        placa(M, sup_craneo, a, y, ra, rv, 6 if Q["bisel"] else 5, 0.08, lambda u, v: "cabeza", rnd, uv_losa(20 + q),
              alza=0.05, giro=0.5 + q)


def crear_cuernos(M):
    """Lo que da la silueta a la cabeza, según la variante."""
    lados = Q["cuerno_lados"]
    rnd = random.Random(5)
    ye, ae, sa, sb = CAB()["ojo"]
    if VARIANTE == "garras":
        for sx in (-1, 1):                    # dos cuernos cortos y gruesos hacia atrás y afuera, punta de cristal
            base = p_arriba(sx * 0.66, 0.15) - Vector((0.0, 0.0, 0.08))
            d = Vector((sx * 0.55, 1.0, 0.45)).normalized()
            curva = Vector((sx * 0.3, 0.2, 0.6))
            colmillo(M, base, d, curva, 1.85, 0.3, lados, "cabeza", color=(0.22, 0.22, 0.27), mineral=1.0, rnd=rnd)
            tip = base + d * 1.85 + curva * 1.85 * 0.38
            racimo(M, tip - d * 0.25, (d + Vector((0.0, 0.0, 0.5))).normalized(), 0.55, 2 * Q["racimo"] + 0.6, "cabeza", rnd, collar=False)
            for k in range(3 if Q["dientes"] >= 1 else 1):     # púas de la mejilla: ensanchan la cara de frente
                y = 0.5 - 0.38 * k
                p = p_arriba(sx * 1.38, y)
                colmillo(M, p, Vector((sx * 1.0, 0.65, -0.2)), Vector((0.0, 0.6, 0.0)), 0.6 - 0.12 * k, 0.11, 4, "cabeza",
                         color=(0.25, 0.25, 0.3), mineral=1.0, rnd=rnd)
        placas_craneo(M, [(0.0, -2.75, 0.3, 0.38), (0.0, -1.95, 0.32, 0.42), (0.0, -1.05, 0.34, 0.46),
                          (0.0, -0.1, 0.32, 0.42), (0.0, 0.7, 0.28, 0.32)][:5 if Q["bisel"] else 3], rnd)
    elif VARIANTE == "geoda":
        p, n = sup_craneo(0.0, -0.75)          # la frente se abre en una geoda: un racimo grande hacia atrás y arriba
        racimo(M, p, (n + Vector((0.0, 0.85, 0.2))).normalized(), 1.7, 5 * Q["racimo"] + 1, "cabeza", rnd, inclina=0.55)
        for sx in (-1, 1):
            p, n = sup_craneo(sx * 0.6, 0.0)
            racimo(M, p, (n + Vector((sx * 0.3, 1.0, 0.1))).normalized(), 1.25, 3 * Q["racimo"] + 1, "cabeza", rnd)
            for k in range(2 if Q["dientes"] >= 1 else 1):
                p = p_arriba(sx * 1.38, 0.45 - 0.4 * k)
                colmillo(M, p, Vector((sx * 1.0, 0.7, -0.1)), Vector((0.0, 0.6, 0.0)), 0.5, 0.1, 4, "cabeza",
                         color=(0.25, 0.25, 0.3), mineral=1.0, rnd=rnd)
        placas_craneo(M, [(0.0, -2.9, 0.28, 0.4), (0.0, -2.0, 0.3, 0.44), (sx * 0.0, 0.55, 0.3, 0.3)], rnd)
    else:
        a_col = 0.13
        y = -2.3
        k = 0
        while y < 0.95:                         # la cresta: columnas que crecen hacia la nuca, al tresbolillo
            for sx in ((-1, 1) if Q["bisel"] else (0,)):
                a = sx * a_col
                p, n = sup_craneo(a, y + (0.12 if sx > 0 else 0.0))
                h = 0.3 + 0.95 * suave(-2.3, 0.9, y) * rnd.choice((0.75, 0.9, 1.0))
                columna(M, p - n * 0.05, (n + Vector((0.0, 0.45, 0.0))).normalized(), 0.15, h, "cabeza", rnd)
            y += 0.33
            k += 1
        for sx in (-1, 1):                      # columnas cortas en las mejillas (la cara de frente, ancha)
            for q in range(2 if Q["dientes"] >= 1 else 1):
                p, n = sup_craneo(sx * 1.32, 0.45 - 0.42 * q)
                columna(M, p - n * 0.05, (n + Vector((0.0, 0.6, 0.0))).normalized(), 0.12, 0.55 - 0.12 * q, "cabeza", rnd)


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


def P_BOCA_L():
    y = CAB()["yh"] + 0.9
    return Vector((0.0, y, tab("Z", y)))


def crear_chorro(M):
    """El aliento: un chorro de arena y polvo de vidrio (cono doble) que sale de la boca."""
    n = Q["chorro"]
    base = P_BOCA_L() * K_CAB()
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
    (hueso «succion»; escondidas con escala 0,01). El alfa del color de vértice es su fuerza."""
    n = Q["succion"]
    boca = P_BOCA_L() * K_CAB()
    rnd = random.Random(13)
    for k in range(n):
        a = 2 * math.pi * k / n + rnd.uniform(-0.2, 0.2)
        lejos = boca + Vector((math.sin(a) * rnd.uniform(3.0, 4.6), -rnd.uniform(4.5, 7.5), -rnd.uniform(3.5, 6.0) + math.cos(a) * 1.5))
        pts = [lejos.lerp(boca, j / 4) + Vector((math.sin(a + 1.5) * 0.8, 0.0, 0.0)) * math.sin(math.pi * j / 4) for j in range(5)]
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

RACIMOS = {
    "garras": [(1.4, 0.0, 1.05, 3), (3.4, 0.6, 0.85, 3), (3.9, -0.62, 0.8, 2), (6.2, 0.0, 1.3, 4), (10.4, 0.35, 0.9, 3),
               (13.6, -0.2, 0.7, 2), (16.0, 0.1, 0.5, 2)],
    "geoda": [(1.7, 0.0, 1.5, 5), (4.6, 0.1, 1.95, 6), (7.9, -0.1, 1.65, 5), (11.2, 0.0, 1.25, 4), (14.2, 0.1, 0.85, 3),
              (16.6, 0.0, 0.55, 2)],
    "columnas": [],
}


def construir(nombre_q):
    global Q
    Q = CALIDAD[nombre_q]
    M = Malla()
    crear_tubo(M)
    crear_placas_cuerpo(M)
    if VARIANTE == "columnas":
        crear_columnas_lomo(M)
    crear_racimos_lomo(M, RACIMOS[VARIANTE])
    if tiene_brazos():
        crear_brazos(M)
    i0 = len(M.v)
    crear_cabeza(M)
    crear_ojos(M)
    crear_cejas(M)
    crear_fosetas(M)
    crear_dientes(M)
    crear_cuernos(M)
    for i in range(i0, len(M.v)):                                     # la cabeza se modela a escala 1 y se agranda
        M.v[i] = M.v[i] * K_CAB()
    crear_monticulo(M)
    crear_losas(M)
    crear_chorro(M)
    crear_succion(M)
    return M


# ---------------------------------------------------------------- esqueleto

def bisagra():
    c = CAB()
    return Vector((0.0, c["yc"] + 0.25, tab("Z", c["yc"]) - 0.12))


def huesos():
    k = K_CAB()
    c = CAB()
    hs = [("raiz", (0, 0, 0), (0, 0, 1.0), None)]
    for i in range(NSEG, 0, -1):
        hs.append((col_nombre(i), (0, i * LSEG, 0), (0, (i - 1) * LSEG, 0), "raiz" if i == NSEG else col_nombre(i + 1)))
    pb = P_BOCA_L()
    yg, zg = c["yc"] + FONDO, tab("Z", c["yc"])
    hs += [("cabeza", (0, 0, 0), (0, c["yh"] * k * 0.75, 0), "col_01"),
           ("mandibula", tuple(bisagra() * k), tuple(Vector((0.0, c["yh"] + 0.8, tab("Z", c["yh"] + 0.8) - 0.45)) * k), "cabeza"),
           ("garganta", (0, (yg + 0.6) * k, zg * k), (0, (yg + 0.1) * k, zg * k), "cabeza"),
           ("chorro", tuple(pb * k), tuple((pb + Vector((0, -1.0, 0))) * k), "cabeza"),
           ("succion", tuple((pb + Vector((0, -0.2, 0))) * k), tuple((pb + Vector((0, -1.2, 0))) * k), "cabeza"),
           ("brillo", (0, 0, -1.0), (0, 0, -0.5), "raiz"),
           ("monticulo", (0, 0, 0), (0, 0, 0.4), "raiz")]
    ye, ae, sa, sb = c["ojo"]
    for lado, sfx in ((1, "izq"), (-1, "der")):
        hs.append(("ceja_" + sfx, tuple(p_arriba(lado * (ae - 0.42), ye + 0.7) * k),
                   tuple(p_arriba(lado * (ae - 0.42), ye - 0.55) * k), "cabeza"))
    for i in ALETAS:
        sm = (i - 0.5) * LSEG
        rt = radio(sm) * 0.95
        hs.append((placa_nombre(i), (0, sm, rt), (0, sm, rt + 0.6), col_nombre(i)))
    if tiene_brazos():
        for lado, sfx in ((1, "izq"), (-1, "der")):
            S, E, W = puntos_brazo(lado)
            hs += [("hombro_" + sfx, tuple(S), tuple(E), col_nombre(int(S_HOMBRO // LSEG) + 1)),
                   ("codo_" + sfx, tuple(E), tuple(W), "hombro_" + sfx),
                   ("mano_" + sfx, tuple(W), tuple(W + MANO * 1.0), "codo_" + sfx)]
    for i, (dx, dy, *_rest) in enumerate(LOSAS):
        cc = LOSAS_CENTRO + Vector((dx, dy, 0))
        hs.append(("losa_%d" % (i + 1), tuple(cc), tuple(cc + Vector((0, 0, 1.0))), "raiz"))
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

# ---------------------------------------------------------------- poses: curva de columna (+ IK de los brazos)

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


ATRIBUTOS = ("boca", "placas", "brillo", "garganta", "chorro", "monticulo", "succion", "losas", "ceja")
ARRAYS = ("ancla", "mm", "ml", "garra")


def par(v):
    """Lo mismo a los dos lados (izq: +x; der: el espejo)."""
    return ((v[0], v[1], v[2]), (-v[0], v[1], v[2]))


PLANTA = par((2.95, -2.3, 0.42))              # las garras apoyadas junto al agujero (en el mundo: no patinan)
GARRA_SUELO = par((0.18, -1.0, -0.62))        # hacia dónde apuntan apoyadas: adelante y clavadas
SIN_DESVIO = par((0.0, 0.0, 0.0))             # la muñeca donde la pone la pose de enlace (relativa al cuerpo)
PLEGADO = par((-0.95, 2.4, 1.55))             # pegadas al costado, hacia la cola (bajo la arena)
ABIERTOS = par((1.4, -1.6, 1.4))              # abiertos y en alto (amenaza)
EN_ALTO = par((0.4, -2.6, 0.9))               # en alto, hacia delante
ALCANZA = par((0.3, -2.4, -1.0))              # hacia la presa (embestida)
COLGANDO = par((0.5, 0.9, -0.4))              # sin fuerza (derrota)


class Pose:
    def __init__(self, th, ps=None, ro=None, ua=11.0, ap=(0, 0, 0), cab=(0, 0, 0), boca=0.0, placas=0.0,
                 brillo=1.0, garganta=0.3, chorro=0.01, monticulo=1.0, placas_k=None, succion=0.01, losas=0.0,
                 ceja=4.0, ancla=(1.0, 1.0), mm=PLANTA, ml=SIN_DESVIO, garra=GARRA_SUELO):
        self.th = th if isinstance(th, np.ndarray) else curva(th)
        self.ps = ps if isinstance(ps, np.ndarray) else (curva(ps) if ps else np.zeros(NU))
        self.ro = ro if isinstance(ro, np.ndarray) else (curva(ro) if ro else np.zeros(NU))
        self.ua, self.ap = ua, np.array(ap, dtype=float)
        self.cab = np.array(cab, dtype=float)
        self.boca, self.placas = boca, placas
        self.placas_k = dict(placas_k) if placas_k is not None else {}
        self.brillo, self.garganta, self.chorro, self.monticulo = brillo, garganta, chorro, monticulo
        self.succion, self.losas, self.ceja = succion, losas, ceja
        self.losas_k = {}
        self.ancla = np.array(ancla, dtype=float)
        self.mm = np.array(mm, dtype=float)
        self.ml = np.array(ml, dtype=float)
        self.garra = np.array(garra, dtype=float)

    def copia(self):
        p = Pose(self.th.copy(), self.ps.copy(), self.ro.copy(), self.ua, self.ap.copy(), self.cab.copy(), self.boca,
                 self.placas, self.brillo, self.garganta, self.chorro, self.monticulo, self.placas_k, self.succion,
                 self.losas, self.ceja, self.ancla.copy(), self.mm.copy(), self.ml.copy(), self.garra.copy())
        p.losas_k = dict(self.losas_k)
        return p

    def con(self, **kw):
        p = self.copia()
        for k, v in kw.items():
            setattr(p, k, np.array(v, dtype=float) if k in ("cab", "ap") + ARRAYS else v)
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
    for c in ARRAYS:
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


SIGNO = {"mandibula": 1.0, "placa": 1.0, "ceja": 1.0}


def marco3(d, ref):
    d = d.normalized()
    r = ref - d * ref.dot(d)
    if r.length < 1e-6:
        r = d.orthogonal()
    r.normalize()
    return Matrix((d, r, d.cross(r))).transposed()


def g_hueso(b, cabeza_w, d_nueva, ref_enlace, ref_nueva):
    """La matriz de un hueso en el mundo (de la armadura) que apunta a d_nueva con su «arriba» hacia ref_nueva, partiendo
    de su orientación de enlace (sin giro sobre sí mismo: el brazo no se retuerce)."""
    Qm = marco3(d_nueva, ref_nueva) @ marco3(b.tail_local - b.head_local, ref_enlace).transposed()
    return Matrix.Translation(cabeza_w) @ (Qm @ b.matrix_local.to_3x3()).to_4x4()


def brazos_ik(bones, G, p):
    """IK de dos huesos por brazo. La muñeca va a mezcla(relativa al cuerpo, en el mundo; ancla): con ancla 1 la garra se
    queda clavada donde dice mm (no patina aunque el cuerpo se mueva); con 0 sigue al cuerpo (ml: su desvío desde la
    pose de enlace, en el marco del cuerpo). Codos hacia fuera y arriba."""
    nc = col_nombre(int(S_HOMBRO // LSEG) + 1)
    Mc = G[nc] @ bones[nc].matrix_local.inverted()
    Rc = Mc.to_3x3()
    for i, (lado, sfx) in enumerate(((1, "izq"), (-1, "der"))):
        S, E, W = puntos_brazo(lado)
        L1, L2 = (E - S).length, (W - E).length
        Sw = Mc @ S
        an = min(1.0, max(0.0, float(p.ancla[i])))
        T = (Mc @ (W + Vector(p.ml[i]))).lerp(Vector(p.mm[i]), an)
        d = T - Sw
        dist = max(abs(L1 - L2) + 0.05, min(d.length, (L1 + L2) * 0.985))
        dn = d.normalized()
        polo = (Rc @ Vector((lado * 1.0, -0.6, 0.3))).normalized()
        pp = polo - dn * polo.dot(dn)
        pp.normalize()
        a = (L1 * L1 - L2 * L2 + dist * dist) / (2 * dist)
        h = math.sqrt(max(0.0, L1 * L1 - a * a))
        Ew = Sw + dn * a + pp * h
        Ww = Sw + dn * dist
        hd = (Rc @ MANO).normalized().lerp(Vector(p.garra[i]).normalized(), an).normalized()
        arriba = (Rc @ Vector((0.0, 0.0, 1.0))).lerp(Vector((0.0, 0.0, 1.0)), an)
        G["hombro_" + sfx] = g_hueso(bones["hombro_" + sfx], Sw, Ew - Sw, W - S, Ww - Sw)
        G["codo_" + sfx] = g_hueso(bones["codo_" + sfx], Ew, Ww - Ew, S - E, Sw - Ew)
        G["mano_" + sfx] = g_hueso(bones["mano_" + sfx], Ww, hd, Vector((0.0, 0.0, 1.0)), arriba)


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
    if "hombro_izq" in bones:
        brazos_ik(bones, G, p)
    return G, P


def bases(arm, p):
    G, P = matrices_globales(arm, p)
    bones = arm.data.bones
    B = {}
    for b in bones:
        n = b.name
        if n in G:
            par_ = b.parent
            gp = G.get(par_.name, par_.matrix_local) if par_ else Matrix.Identity(4)
            resto = (par_.matrix_local.inverted() @ b.matrix_local) if par_ else b.matrix_local
            B[n] = resto.inverted() @ gp.inverted() @ G[n]
        elif n == "mandibula":
            B[n] = Matrix.Rotation(math.radians(max(0.0, p.boca)) * SIGNO["mandibula"], 4, 'X')   # nunca más cerrada que cerrada
        elif n.startswith("ceja_"):
            B[n] = Matrix.Rotation(math.radians(max(-14.0, min(16.0, p.ceja))) * SIGNO["ceja"], 4, 'X')
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
    """Qué signo abre la boca (la punta de la mandíbula baja), eriza la armadura (hacia la cabeza) y frunce el ceño (la
    punta de la ceja baja)."""
    b = arm.data.bones["mandibula"]
    punta = (b.matrix_local @ Matrix.Rotation(0.5, 4, 'X')) @ Vector((0, b.length, 0))
    SIGNO["mandibula"] = 1.0 if punta.z < b.tail_local.z else -1.0
    b = arm.data.bones[placa_nombre(ALETAS[0])]
    punta = (b.matrix_local @ Matrix.Rotation(0.3, 4, 'X')) @ Vector((0, b.length, 0))
    SIGNO["placa"] = 1.0 if punta.y < b.tail_local.y else -1.0
    b = arm.data.bones["ceja_izq"]
    punta = (b.matrix_local @ Matrix.Rotation(0.3, 4, 'X')) @ Vector((0, b.length, 0))
    SIGNO["ceja"] = 1.0 if punta.z < b.tail_local.z else -1.0
    print("SIGNOS", SIGNO)


def poner_pose(arm, p):
    B, G, P = bases(arm, p)
    for pb in arm.pose.bones:
        loc, rot, esc = B[pb.name].decompose()
        pb.location, pb.rotation_quaternion, pb.scale = loc, rot, esc
    return G, P


def P_HOCICO():
    c = CAB()
    return Vector((0.0, c["yh"] - 0.05, tab("Z", c["yh"]) + 0.1)) * K_CAB()


def P_BARBILLA():
    y = y_mand(CAB()["yh"]) + 0.15
    return Vector((0.0, y, tab("Z", y) - tab("D", y) * 0.9)) * K_CAB()


def P_MAND_BAJO():
    return Vector((0.0, -1.6, tab("Z", -1.6) - tab("D", -1.6))) * K_CAB()


def P_BOCA():
    return P_BOCA_L() * K_CAB()


def P_GARGANTA():
    c = CAB()
    return Vector((0.0, c["yc"] + FONDO, tab("Z", c["yc"]))) * K_CAB()


def P_CIERRE():
    """Un punto de la línea de la boca, delante, que es a la vez del labio (cabeza) y del borde de la mandíbula: con la
    boca cerrada, los dos coinciden (distancia 0)."""
    y = CAB()["yh"] + 0.7
    return Vector((0.0, y, tab("Z", y))) * K_CAB()


def a_godot(v):
    return [round(v.x, 3), round(v.z, 3), round(-v.y, 3)]


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


def ondas(p, t, T, amp=3.0, largo=8.0):
    for k in ALETAS:
        p.placas_k[k] = p.placas_k.get(k, 0.0) + amp * math.sin(2 * math.pi * (k * LSEG / largo - t / T))


def pose_reposo(t=0.0, T=3.0):
    """Respira despacio y pesa: el cuello sube y baja con el aliento y se mece; la cabeza no barre de lado a lado:
    vigila a los héroes, ladea con curiosidad y vuelve; el ceño late; la armadura ondula; las garras quietas en el
    suelo (los brazos se doblan solos con la IK). La boca, CERRADA (0°) en todo el bucle."""
    w = 2 * math.pi * t / T
    p = Pose(TH_REPOSO, ua=11.0, cab=(-6, 0, 0), boca=0.0, ceja=4.0)
    p.th = p.th + math.radians(2.2) * math.sin(w) * campana(1.5, 8.0, 2.0)
    p.ps = p.ps + math.radians(2.4) * np.sin(w + U * 0.3) * campana(0, 11, 2)
    p.cab = np.array((-6 + 1.6 * math.sin(w + 0.6), 3.5 * math.sin(w) + 1.2 * math.sin(2 * w + 0.4), 3.2 * math.sin(w + 1.3)))
    p.placas = 1.5 * (0.5 + 0.5 * math.sin(w))
    ondas(p, t, T, 2.0, 9.0)
    p.brillo = 1.0 + 0.15 * math.sin(2 * w)
    p.garganta = 0.3 + 0.08 * math.sin(w)
    p.ceja = 4.0 + 2.5 * math.sin(w + 2.0)
    return p


R0 = None


def desde_reposo(dth=None, **kw):
    p = R0.copia()
    if dth is not None:
        p.th = p.th + dth
    return p.con(**kw)


def vibracion(t, f=7.5, k=0):
    return math.sin(2 * math.pi * f * t + k * 1.7) * math.cos(2 * math.pi * f * 0.37 * t + k)


def sacudir(p, t, fuerza, f=4.5):
    p.cab = p.cab + np.array((1.5, 6.0, 4.0)) * fuerza * np.array((vibracion(t, f, 1), math.sin(2 * math.pi * f * t),
                                                                    math.sin(2 * math.pi * f * t + 1.0)))
    for k in ALETAS:
        p.placas_k[k] = p.placas_k.get(k, 0.0) + 6.0 * fuerza * vibracion(t, 7.5, k)
    p.th = p.th + math.radians(1.2) * fuerza * np.sin(2 * math.pi * 6.0 * t + U * 1.9) * campana(0, 11, 2)
    return p


def clip_reposo():
    T = 3.0
    return [pose_reposo(i / FPS, T) for i in range(int(T * FPS) + 1)], {}


def ola_subterranea(t, T=2.0, amp_v=7.0, amp_h=6.0):
    env = np.clip(U / 4.0, 0, 1) * (1 - 0.5 * np.clip((U - 14) / 8, 0, 1))
    th = math.radians(amp_v) * np.sin(2 * math.pi * (U / 8.0 - t / T)) * env
    ps = math.radians(amp_h) * np.sin(2 * math.pi * (U / 11.0 - t / T)) * env
    return th, ps


def pose_subterranea(t=0.0, T=2.0):
    """Bajo la arena: avanza ondulando; solo asoman los cristales y la cresta del lomo (cortan la arena: el aviso que se
    ve de lejos); los brazos, plegados contra los costados."""
    th, ps = ola_subterranea(t, T)
    p = Pose([(-6, 0), (22, 0)], ua=0.0, ap=(0, 0, -2.55), cab=(0, 0, 0), boca=0.0, placas=-8.0, brillo=0.8,
             garganta=0.2, monticulo=0.01, ceja=0.0, ancla=(0.0, 0.0), ml=PLEGADO)
    p.th = p.th + th
    p.ps = p.ps + ps
    p.cab = np.array((1.5 * math.sin(2 * math.pi * t / T), 3 * math.sin(2 * math.pi * t / T + 1), 0))
    for k in ALETAS:
        p.placas_k[k] = 5.0 * math.sin(2 * math.pi * (k * LSEG / 8.0 - t / T))
    return p


def clip_subterraneo():
    T = 2.0
    return [pose_subterranea(i / FPS, T) for i in range(int(T * FPS) + 1)], {}


def clip_aviso():
    """Bajo la arena, el lomo se alza, la armadura se eriza y vibra y la luz sube (el temblor del aviso); vuelve."""
    D = 1.6
    base = pose_subterranea(0.0)
    arriba = base.con(ap=(0, 0, -2.1), cab=(7, 0, 0), placas=14.0, brillo=2.0)
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
                placas=-14.0, brillo=1.4, garganta=0.5, ceja=2.0, ancla=(0.0, 0.0), ml=PLEGADO)


AJUSTE = {"emerger_ua": -6.2, "emerger_alto": 0.85, "derrota_dz": 0.0, "sismico_dz": 0.0}


def clip_emerger():
    """La arena se abomba y tiembla; revienta la cabeza y sube en columna con la boca cerrada; arriba abre los brazos y
    las fauces (se presenta) y ruge; la cabeza cae por su peso, las garras se clavan en el borde del agujero (el golpe,
    1,88), rebota y se asienta justo en el reposo."""
    D = 2.8
    abajo = pose_columna(AJUSTE["emerger_ua"], -8.0, 0.0).con(monticulo=0.01, brillo=1.2)
    abomba = abajo.con(monticulo=0.6, ua=AJUSTE["emerger_ua"] + 0.3)
    alto = pose_columna(13.2, -6.0, 18.0).con(placas=-6.0, brillo=1.7, monticulo=1.18, ceja=10.0, ml=par((0.2, -1.0, 0.6)))
    cuelga = mezclar(pose_columna(13.5, 14.0, 40.0), R0, 0.35).con(ua=13.4, placas=24.0, brillo=1.9, monticulo=1.05,
                                                                   ceja=14.0, ancla=(0.0, 0.0), ml=ABIERTOS)
    cae = mezclar(R0, cuelga, -0.2).con(ua=10.4, boca=4.0, placas=10.0, cab=R0.cab + np.array((-14.0, 0, 0)), ceja=10.0,
                                        ancla=(0.55, 0.55), mm=PLANTA, ml=EN_ALTO)
    rebota = mezclar(R0, cae, -0.45).con(ancla=(1.0, 1.0), boca=0.0)
    asienta = mezclar(R0, cae, 0.15).con(ancla=(1.0, 1.0), boca=0.0)
    claves = [(0.0, abajo, ease), (0.2, abomba, ease_in), (AJUSTE["emerger_alto"], alto, ease_out), (1.2, cuelga, ease),
              (1.6, cae, ease_in), (1.88, rebota, ease), (2.15, asienta, ease), (2.45, R0, ease), (2.8, R0, ease)]
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
        if 1.05 <= t < 1.5:                                           # ruge arriba: la cabeza tiembla
            p = sacudir(p, t, 0.6 * math.sin(math.pi * (t - 1.05) / 0.45))
        if t >= 2.45:                                                 # ya respira: acaba justo donde empieza el reposo
            q = pose_reposo(t - D + 3.0)
            p = mezclar(p, q, ease((t - 2.45) / 0.3)) if t < 2.75 else q
        poses.append(p)
    return poses, {}


def clip_rugido():
    """Toma aire con la boca cerrada (la cabeza sube), se enrosca hacia atrás clavando las garras (anticipación), lanza
    la cabeza pasándose (0,8: el pico) y ruge con las fauces abiertas del todo, el ceño fruncido, la armadura erizada y
    los brazos en alto; cierra la boca de golpe y da con las dos garras en el suelo (2,18), rebota y vuelve."""
    D = 2.6
    inhala = desde_reposo(math.radians(-4) * campana(0, 4, 2.0), cab=(6, 0, 0), boca=3.0, placas=-6.0, ceja=0.0)
    toma = desde_reposo(math.radians(26) * campana(0, 5, 2.0), ua=10.2, cab=(-8, 0, 0), boca=0.0, placas=-16.0,
                        brillo=0.9, ceja=10.0)
    pasa = desde_reposo(math.radians(-11) * campana(0, 4.5, 2.0), ua=11.7, cab=(28, 0, 0), boca=56.0, placas=32.0,
                        brillo=2.0, garganta=1.6, ceja=16.0, ancla=(0.1, 0.1), ml=ABIERTOS)
    ruge = desde_reposo(math.radians(-6) * campana(0, 4.5, 2.0), ua=11.45, cab=(22, 0, 0), boca=50.0, placas=28.0,
                        brillo=1.8, garganta=1.4, ceja=16.0, ancla=(0.1, 0.1), ml=ABIERTOS)
    cierra = desde_reposo(math.radians(6) * campana(0, 4, 2.0), ua=10.8, cab=(-12, 0, 0), boca=0.0, placas=-4.0, ceja=10.0)
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
            p.boca = p.boca + 3.0 * math.sin(2 * math.pi * 6.0 * t) * f
        poses.append(p)
    return poses, {"inicio_rugido": 0.55, "pico_rugido": 0.8, "fin_rugido": 1.9}


TH_RETRAE = [(-6, 10), (0, 10), (1.5, 34), (3, 76), (5, 100), (7, 104), (9.2, 86), (12, 60), (16, 30), (22, 12)]
TH_EMBISTE = [(-6, -40), (0, -40), (2, -24), (4.5, 2), (8, 40), (11, 70), (14.5, 82), (17, 60), (22, 20)]
UA_EMBISTE = 13.8


def clip_ataque():
    """La Embestida del Abismo: se recoge hacia atrás y abajo con la boca cerrada y las garras clavadas (0 a 0,55: la
    anticipación), tiembla fijando al objetivo con el ceño fruncido (0,55 a 0,8), se lanza acelerando con los brazos
    por delante, abre las fauces a mitad de camino y las CIERRA de golpe en el impacto (1,0: el mordisco, lo más
    lejos), sacude la cabeza dos veces con la presa (la boca cerrada) y vuelve a clavar las garras donde estaban."""
    D = 2.3
    retrae = Pose(TH_RETRAE, ua=9.1, cab=(-20, 0, 0), boca=0.0, placas=-16.0, brillo=1.3, ceja=14.0)
    embiste = Pose(TH_EMBISTE, ua=UA_EMBISTE, cab=(2, 0, 0), boca=0.0, placas=16.0, brillo=1.6, garganta=0.6, ceja=16.0,
                   ancla=(0.12, 0.12), ml=ALCANZA)
    rebote = mezclar(embiste, R0, 0.28).con(placas=22.0, ancla=(0.3, 0.3), cab=(-12.0, 0.0, 0.0))   # la cabeza tira hacia atrás
    medio = mezclar(embiste, R0, 0.7).con(ancla=(0.8, 0.8))
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
            p.boca = 50.0 * a
        if 1.0 <= t < 1.55:                                           # desgarra: dos sacudidas de la cabeza
            f = ease((t - 1.0) / 0.08) * (1 - ease((t - 1.0) / 0.55))
            p.cab = p.cab + np.array((4.0 * math.sin(2 * math.pi * 3.5 * (t - 1.0)), 16.0 * math.sin(2 * math.pi * 3.5 * (t - 1.0)),
                                      10.0 * math.sin(2 * math.pi * 3.5 * (t - 1.0) + 0.6))) * f
            for k in ALETAS:
                p.placas_k[k] = p.placas_k.get(k, 0.0) + 7.0 * f * vibracion(t, 7.5, k)
        poses.append(p)
    return poses, {"anticipacion": 0.2, "fijado": 0.55, "impacto": None}


TH_ERGUIDO = [(-6, 40), (0, 40), (2, 66), (4, 86), (17, 89), (19, 72), (22, 45)]
TH_ATRAS = [(-6, 58), (0, 58), (2, 80), (4, 96), (12, 96), (17, 90), (19, 72), (22, 45)]
TH_CAIDO = [(-6, -8), (0, -8), (3, 0), (8, 6), (12.5, 18), (13.6, 40), (15.5, 62), (22, 40)]   # (v3: la cabeza
#                       queda tendida sobre la arena; con la curva de la v2 se hundía 3,6 m bajo el suelo)


def hombros(p):
    """Dónde están los hombros (en el mundo) en una pose (para clavar las garras al caer)."""
    if not tiene_brazos():
        return [Vector((2.0, -3.0, 0.0)), Vector((-2.0, -3.0, 0.0))]
    G, P = matrices_globales(ARM, p)
    nc = col_nombre(int(S_HOMBRO // LSEG) + 1)
    Mc = G[nc] @ ARM.data.bones[nc].matrix_local.inverted()
    return [Mc @ puntos_brazo(1)[0], Mc @ puntos_brazo(-1)[0]]


def clip_ataque_sismico():
    """La Fractura del Mar de Cristal: se alza hasta lo más alto con la armadura erizada y los brazos en alto (0 a 1,0),
    ruge arriba sacudiéndose (1,15 a 2,0), se echa atrás (2,0 a 2,1: la anticipación) y se desploma como una torre,
    acelerando, hasta dar con la cabeza (la boca cerrada) delante de los héroes y las dos garras a la vez (2,5333). En
    el golpe las placas del suelo saltan alrededor de la cabeza y el cuerpo entero vibra; las placas se asientan, las
    garras empujan, la cabeza se levanta y vuelve al reposo (las garras se levantan antes de volver a su sitio)."""
    D = 3.8
    erguido = Pose(TH_ERGUIDO, ua=17.0, cab=(18, 0, 0), boca=18.0, placas=24.0, brillo=1.6, garganta=0.8, ceja=12.0,
                   ancla=(0.0, 0.0), ml=EN_ALTO)
    ruge = erguido.con(cab=(30.0, 0, 0), boca=52.0, placas=32.0, garganta=1.4, brillo=1.9, ceja=16.0, ml=ABIERTOS)
    atras = Pose(TH_ATRAS, ua=17.0, cab=(26, 0, 0), boca=20.0, placas=34.0, brillo=2.0, garganta=1.0, ceja=16.0,
                 ancla=(0.0, 0.0), ml=par((0.8, -1.8, 2.4)))
    caido = Pose(TH_CAIDO, ua=13.6, ap=(0, 0, AJUSTE["sismico_dz"]), cab=(-4, 0, 0), boca=0.0, placas=-8.0, brillo=1.7,
                 garganta=0.6, ceja=16.0, ancla=(1.0, 1.0))
    hs = hombros(caido)
    golpe_garras = ((hs[0].x + 1.7, hs[0].y - 1.5, 0.35), (hs[1].x - 1.7, hs[1].y - 1.5, 0.35))
    caido.mm = np.array(golpe_garras)
    golpe = caido.con(losas=1.0)
    bote = golpe.copia()
    bote.th = bote.th + math.radians(7) * campana(-6, 8, 3)
    bote.placas = 18.0
    asentado = caido.con(losas=0.62)
    levanta = mezclar(asentado, R0, 0.55).con(ancla=(0.35, 0.35), losas=0.0)
    claves = [(0.0, R0, ease), (1.0, erguido, ease), (1.2, ruge, ease_out), (2.0, ruge, ease), (2.1, atras, ease),
              (2.5333, caido, ease_in3), (2.68, bote, ease_out), (2.9, golpe, ease_in), (3.1, asentado, ease),
              (3.45, levanta, ease), (3.8, R0, ease)]
    poses = []
    for i in range(int(D * FPS) + 1):
        t = i / FPS
        p = tramos(t, claves)
        if 2.1 <= t < 2.5333:                                         # las garras bajan antes de soltar el agarre del aire
            p.ancla = np.array([ease_in((t - 2.1) / 0.4333)] * 2)
            p.mm = np.array(golpe_garras)
        if 1.15 <= t <= 2.05:
            p = sacudir(p, t, ease((t - 1.15) / 0.15) * (1 - ease((t - 1.9) / 0.15)))
        if t >= 2.5333 - 1e-6:
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
    """El Aliento del Desierto Eterno: abre la boca despacio y baja la cabeza (0 a 0,4) con las garras clavadas (se
    afianza); aspira (0,45 a 1,6): la arena sube en cintas hasta sus fauces, la garganta se enciende y el cuello se echa
    atrás tragando; cierra un poco y se recoge (1,7: la acumulación); en la descarga (1,85) lanza la cabeza hacia delante
    con las fauces abiertas del todo y barre de un lado a otro (a los tres héroes) hasta 2,6; cierra y vuelve."""
    D = 3.6
    abre = desde_reposo(math.radians(-6) * campana(0, 4.5, 2.0), cab=(-14, 0, 0), boca=42.0, placas=10.0, brillo=1.2,
                        garganta=0.8, ceja=10.0)
    aspira = desde_reposo(math.radians(14) * campana(0, 4.5, 2.0), ua=10.7, cab=(-4, 0, 0), boca=50.0, placas=26.0,
                          brillo=2.4, garganta=3.0, ceja=14.0)
    aspira.succion = 1.0
    abre.succion = 0.35
    recoge = desde_reposo(math.radians(22) * campana(0, 4.5, 2.0), ua=10.4, cab=(14, 0, 0), boca=22.0, placas=30.0,
                          brillo=2.5, garganta=3.0, ceja=16.0)
    escupe = desde_reposo(math.radians(-12) * campana(0, 4.5, 2.0), ua=11.8, cab=(-26, -16, 0), boca=58.0,
                          placas=-10.0, brillo=2.1, garganta=2.6, ceja=16.0)
    barre = escupe.con(cab=(-20.0, 16.0, 0.0), garganta=1.4, brillo=1.6, boca=54.0)
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
    """Recibe el golpe: la cabeza salta hacia atrás y se aparta con un gruñido (la boca se entreabre y vuelve a cerrar),
    las cejas suben (sorpresa), la armadura se encoge y tiembla, una garra pierde el apoyo y se vuelve a clavar; la luz
    parpadea."""
    D = 1.0
    golpe = desde_reposo(math.radians(10) * campana(0, 5, 2.0), ua=10.7, cab=(12, -10, 10), boca=16.0, brillo=0.5,
                         placas=-12.0, ceja=-10.0, ancla=(0.45, 1.0), ml=par((0.3, -0.6, 0.8)))
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
    """Se retuerce de dolor con las fauces abiertas y la luz parpadeando, los brazos se agitan y pierden la fuerza, se
    desploma de lado y rueda (la cabeza da contra la arena: caida), rebota y se hunde a medias apagándose, con la
    mandíbula floja. Se queda así."""
    D = 3.4
    dz = AJUSTE["derrota_dz"]
    dolor = desde_reposo(math.radians(8) * campana(0, 5, 2.0), cab=(25, 0, 0), boca=46.0, placas=12.0, brillo=1.4,
                         ceja=-8.0, ancla=(0.3, 0.3), ml=ABIERTOS)
    caido = Pose(TH_DERRIBADO, ps=[(-6, 30), (9, 30), (11, 10), (14, 0)], ro=[(-6, 50), (9, 50), (11.5, 10), (14, 0)],
                 ua=DERROTA_UA, ap=(0, 0, dz), cab=(-10, 0, 35), boca=20.0, placas=-18.0, brillo=0.5, garganta=0.3,
                 ceja=-4.0, ancla=(0.0, 0.0), ml=COLGANDO)
    bote = caido.copia()
    bote.th = bote.th + math.radians(5) * campana(-6, 7, 3)
    hundido = caido.con(ua=DERROTA_UA - 1.7, boca=24.0, placas=-22.0, brillo=0.08, garganta=0.05, ceja=-2.0)
    claves = [(0.0, R0, ease), (0.5, dolor, ease_out), (0.6, dolor, ease), (1.75, caido, ease_in), (1.9, bote, ease_out),
              (2.05, caido, ease_in), (3.4, hundido, ease)]
    poses = []
    for i in range(int(D * FPS) + 1):
        t = i / FPS
        p = tramos(t, claves)
        if t < 0.65:
            p = sacudir(p, t, ease(t / 0.2) * 0.8)
            p.brillo = p.brillo * (0.6 + 0.4 * (0.5 + 0.5 * math.sin(2 * math.pi * 6 * t)))
        if 1.0 <= t < 2.2:                                            # la armadura se desmorona: cada placa a su ritmo
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
CONTRATO = {"emerger": {"rompe_arena": 0.2333, "pico": 0.8667, "erguido": 2.45}, "ataque": {"impacto": 1.0},
            "ataque_sismico": {"impacto": 2.5333}, "derrota": {"caida": 1.6}}
ARM = None


# ---------------------------------------------------------------- medidas y ajuste de los instantes del contrato

def medir(p):
    B, G, P = bases(ARM, p)
    cab_c = mundo_de(ARM, G, B, "cabeza", P_CIERRE())
    man_c = mundo_de(ARM, G, B, "mandibula", P_CIERRE())
    return {"hocico": mundo_de(ARM, G, B, "cabeza", P_HOCICO()), "barbilla": mundo_de(ARM, G, B, "mandibula", P_BARBILLA()),
            "bajo": mundo_de(ARM, G, B, "mandibula", P_MAND_BAJO()), "nuca": punto(P, 0.0),
            "cierre": (cab_c - man_c).length, "boca": max(0.0, p.boca)}


def _primera(poses, desde, cond):
    for j in range(desde, len(poses)):
        if cond(medir(poses[j])):
            return j
    return None


def ajustar_instantes():
    """Mueve un poco las poses clave para que los instantes que se miden en el clip caigan en el mismo fotograma que el
    contrato de la v1/v2 (la cabeza es distinta, así que con las poses de la v2 cambiarían)."""
    # emerger: rompe la arena en el fotograma 7 (0,2333 s)
    previo = AJUSTE["emerger_ua"]
    validos = []
    ua = -9.0
    while ua <= -2.0:
        AJUSTE["emerger_ua"] = ua
        ps, _ = clip_emerger()
        j = _primera(ps[:12], 0, lambda m: m["hocico"].z > 0.0)
        if j == 7:
            validos.append(ua)
        ua += 0.1
    AJUSTE["emerger_ua"] = round(0.5 * (validos[0] + validos[-1]), 3) if validos else previo
    if not validos:
        print("AVISO: emerger no rompe la arena en el fotograma 7 con ningún ua")
    # emerger: lo más alto en el fotograma 26 (0,8667 s)
    for ta in [0.85, 0.86, 0.84, 0.87, 0.83, 0.88, 0.82, 0.89, 0.9]:
        AJUSTE["emerger_alto"] = ta
        ps, _ = clip_emerger()
        al = [max(medir(ps[j])["hocico"].z, medir(ps[j])["nuca"].z + 1.5) for j in range(18, 40)]
        if 18 + int(np.argmax(al)) == 26:
            break
    # derrota: la cabeza da contra el suelo en el fotograma 48 (1,6 s)
    previo = AJUSTE["derrota_dz"]
    validos = []
    dz = -2.0
    while dz <= 2.0:
        AJUSTE["derrota_dz"] = dz
        ps, _ = clip_derrota()
        j = _primera(ps, int(0.6 * FPS), lambda m: min(m["bajo"].z, m["barbilla"].z) <= 0.45)
        if j == 48:
            validos.append(dz)
        dz += 0.05
    AJUSTE["derrota_dz"] = round(0.5 * (validos[0] + validos[-1]), 3) if validos else previo
    if not validos:
        print("AVISO: la derrota no cae en el fotograma 48 con ningún desplazamiento")
    # Fractura: con la cabeza caída, la barbilla a 0,25 m del suelo (el impacto, 2,5333, se mide al bajar de 0,35)
    AJUSTE["sismico_dz"] = 0.0
    caido = Pose(TH_CAIDO, ua=13.6, cab=(-4, 0, 0))
    m = medir(caido)
    print("FRACTURA sin ajuste: nuca", tuple(round(x, 2) for x in m["nuca"]), "hocico", tuple(round(x, 2) for x in m["hocico"]),
          "barbilla", tuple(round(x, 2) for x in m["barbilla"]), "bajo", tuple(round(x, 2) for x in m["bajo"]))
    AJUSTE["sismico_dz"] = round(0.25 - min(m["bajo"].z, m["barbilla"].z), 3)
    print("AJUSTE", AJUSTE)


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
        m = medir(p)
        m["alto"] = max(m["hocico"].z, m["nuca"].z + 1.5)
        medidas.append(m)
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


# ---------------------------------------------------------------- comprobaciones de la boca

def clases_caras(M):
    """Las caras rígidas del cráneo (todo «cabeza») y de la mandíbula (todo «mandibula»), con sus dientes. Las de
    pesos repartidos (mejillas, garganta, comisura) se estiran a propósito y no entran."""
    cab, man = [], []
    for f, mat in zip(M.caras, M.mats):
        if mat not in (PIEL, VIDRIO):
            continue
        ws = [M.pesos[i] for i in f]
        dom = lambda w, h: w.get(h, 0.0) / max(1e-9, sum(w.values()))
        if all(dom(w, "cabeza") > 0.99 for w in ws):
            cab.append(tuple(f))
        elif all(dom(w, "mandibula") > 0.99 for w in ws):
            man.append(tuple(f))
    return cab, man


def comprobar_intersecciones(arm, obj, M, pedidos):
    """Cuenta los pares de triángulos del cráneo y de la mandíbula que se atraviesan (árbol BVH sobre la malla ya
    deformada por el esqueleto) en cada (clip, segundo) pedido."""
    cab, man = clases_caras(M)
    cab = [f for f in cab if max(M.v[i].y for i in f) < 1.1 * K_CAB()]        # solo la cabeza
    c_ = CAB()
    esquinas = [Vector((s_ * tab("W", c_["yc"]), c_["yc"], tab("Z", c_["yc"]))) * K_CAB() for s_ in (-1, 1)]
    junto = lambda f: any(min((M.v[i] - e).length for e in esquinas) < 0.06 * K_CAB() for i in f)
    n0 = (len(cab), len(man))
    cab = [f for f in cab if not junto(f)]
    man = [f for f in man if not junto(f)]
    print("CARAS rígidas: cráneo %d, mandíbula %d (fuera, por tocar la comisura: %d y %d)" % (len(cab), len(man), n0[0] - len(cab), n0[1] - len(man)))
    ad = arm.animation_data
    estado = [(t, t.mute) for t in ad.nla_tracks]
    for t in ad.nla_tracks:
        t.mute = True
    res = {}
    for clip, segs in pedidos:
        ad.action = bpy.data.actions[clip]
        filas = []
        for s in segs:
            bpy.context.scene.frame_set(int(round(s * FPS)) + 1)
            dg = bpy.context.evaluated_depsgraph_get()
            ev = obj.evaluated_get(dg)
            me = ev.to_mesh()
            vs = [v.co.copy() for v in me.vertices]
            ev.to_mesh_clear()
            pares = BVHTree.FromPolygons(vs, cab).overlap(BVHTree.FromPolygons(vs, man))
            ys = sorted(set(round(sum((M.v[i] for i in cab[a]), Vector()).y / len(cab[a]) / K_CAB(), 2) for a, b in pares))
            det = []
            for a_, b_ in pares[:3]:
                ca = sum((M.v[i] for i in cab[a_]), Vector()) / len(cab[a_]) / K_CAB()
                cm = sum((M.v[i] for i in man[b_]), Vector()) / len(man[b_]) / K_CAB()
                det.append(([round(x, 2) for x in ca], [round(x, 2) for x in cm], M.pesos[cab[a_][0]], len(cab[a_])))
            filas.append({"s": s, "pares": len(pares), "y": ys[:6], "detalle": det})
        res[clip] = filas
        print("INTERSECCIONES", clip, [(f["s"], f["pares"], f["detalle"][:2]) for f in filas])
    ad.action = None
    for t, m in estado:
        t.mute = m
    return res


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
    vientre = np.clip((-ca - 0.74) / 0.22, 0, 1)       # (v3: franja más estrecha; con bandas claras se leía como una larva)
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
    placa_v *= (0.95 + 0.05 * np.clip(ty / 0.5, 0, 1))[..., None]
    placa_v = mezclar_color(placa_v, (0.30, 0.23, 0.18), np.clip(1 - ty / 0.04, 0, 1) * 0.12)
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

    # --- el cráneo (v3): u = el ángulo de −π/2 a π/2 por arriba; v = de la nuca al hocico
    y0, y1, x0, x1 = region(AT_CRANEO)
    h, w = y1 - y0, x1 - x0
    cb = CAB()
    yn, yh = cb["yn"], cb["yh"]
    uu = (np.arange(w) + 0.5) / w
    vv = (np.arange(h) + 0.5) / h
    A = (-math.pi / 2 + math.pi * uu)[None, :] * np.ones((h, 1))
    YY = (yn - vv * (yn - yh))[:, None] * np.ones((1, w))
    tabla_y = np.linspace(yh, yn, 64)
    XH = np.interp(YY, tabla_y, np.array([tab("W", y) for y in tabla_y])) * np.sin(A)
    n1 = fbm(h, w, 24, 16, 31, 4)
    n2 = fbm(h, w, 120, 80, 32, 3)
    rgb = np.ones((h, w, 3)) * np.array((0.10, 0.11, 0.15))[None, None, :]
    rgb = mezclar_color(rgb, (0.25, 0.26, 0.31), n1 * 0.9)
    ex = np.mod(XH / 0.2 + 0.5 * np.mod(np.floor(YY / 0.22), 2), 1.0)          # escamas pequeñas
    ey = np.mod(YY / 0.22, 1.0)
    esc = np.clip(np.minimum(np.minimum(ex, 1 - ex), np.minimum(ey, 1 - ey)) / 0.08, 0, 1)
    rgb *= (0.8 + 0.2 * esc)[..., None]
    lado = np.abs(np.sin(A))
    rgb = mezclar_color(rgb, (0.30, 0.25, 0.22), np.clip((lado - 0.55) / 0.3, 0, 1) * 0.35 * n1)        # polvo
    labio = np.clip((lado - 0.9) / 0.07, 0, 1)                    # el labio: basalto gastado, claro (dibuja el cierre)
    rgb = mezclar_color(rgb, (0.42, 0.40, 0.41), labio * 0.7)
    rgb = mezclar_color(rgb, (0.07, 0.07, 0.09), np.clip((lado - 0.985) / 0.015, 0, 1) * 0.8)    # su canto, oscuro
    ye, ae, sa, sb = cb["ojo"]
    d = np.hypot((np.abs(A) - ae) / 0.36, (YY - ye) / 0.55)          # la cuenca del ojo y un halo
    rgb = mezclar_color(rgb, (0.05, 0.05, 0.07), np.clip(1.45 - d, 0, 1))
    b = np.clip(1.25 - d, 0, 1) * 0.3
    for sx in (-1, 1):                                                # orificios nasales
        dn = np.hypot((A - sx * 0.32) / 0.08, (YY - (yh + 0.32)) / 0.12)
        rgb = mezclar_color(rgb, (0.03, 0.03, 0.04), np.clip(1.4 - dn, 0, 1))

    def a_px(a, y):
        return ((a / math.pi + 0.5) * w, (yn - y) / (yn - yh) * h)
    vetas = []
    for sx in (-1, 1):                                                # vetas de cristal: del ojo a la nuca y al hocico
        vetas.append([a_px(sx * x, y) for (x, y) in [(ae + 0.1, ye + 0.3), (ae - 0.12, ye + 0.95), (ae - 0.32, ye + 1.6), (ae - 0.5, ye + 2.2)]])
        vetas.append([a_px(sx * x, y) for (x, y) in [(ae + 0.2, ye - 0.3), (ae + 0.32, ye - 0.85), (ae + 0.38, ye - 1.35)]])
        vetas.append([a_px(sx * x, y) for (x, y) in [(0.25, yh + 0.9), (0.42, yh + 1.5), (0.55, ye)]])
    cic = [a_px(x, y) for (x, y) in [(-0.6, 0.6), (-0.25, 0.1), (0.1, -0.35), (0.35, -0.9)]]
    dd = trazos(h, w, vetas + [cic], 10.0 * k)
    rgb = mezclar_color(rgb, (0.12, 0.1, 0.1), np.clip(1 - np.abs(dd - 6 * k) / (2 * k), 0, 1) * 0.7)
    rgb = mezclar_color(rgb, (0.5, 0.9, 0.96), np.clip(1 - dd / (2.6 * k), 0, 1) * 0.85)
    b = np.maximum(b, np.clip(1.6 - dd / (2.2 * k), 0, 1))
    pintar_grietas(rgb, b, rng, 10, w, h, w * 0.025, 6, con_luz=0.3)
    img[y0:y1, x0:x1] = rgb
    brillo[y0:y1, x0:x1] = b

    # --- la mandíbula y la garganta: basalto por los lados, arena erosionada por debajo (contrasombra), el labio claro
    y0, y1, x0, x1 = region(AT_MANDIBULA)
    h, w = y1 - y0, x1 - x0
    uu = (np.arange(w) + 0.5) / w
    vv = (np.arange(h) + 0.5) / h
    A = (math.pi / 2 + math.pi * uu)[None, :] * np.ones((h, 1))
    YL = (yn - vv * (yn - yh))[:, None] * np.ones((1, w))
    n1 = fbm(h, w, 16, 16, 41, 4)
    n2 = fbm(h, w, 90, 90, 42, 3)
    rgb = np.ones((h, w, 3)) * np.array((0.12, 0.12, 0.16))[None, None, :]
    rgb = mezclar_color(rgb, (0.28, 0.27, 0.30), n1 * 0.8)
    abajo = np.clip((-np.cos(A) - 0.5) / 0.3, 0, 1)
    gar = np.ones((h, w, 3)) * np.array(VIENTRE)[None, None, :]
    gar = mezclar_color(gar, (0.8, 0.7, 0.55), n1 * 0.6)
    gar *= (1 - 0.25 * (0.5 + 0.5 * np.cos(2 * math.pi * YL / 0.34)) ** 6)[..., None]
    rgb = rgb * (1 - abajo[..., None]) + gar * abajo[..., None]
    lado = np.abs(np.sin(A))
    rgb = mezclar_color(rgb, (0.40, 0.39, 0.41), np.clip((lado - 0.9) / 0.07, 0, 1) * 0.6)
    rgb = mezclar_color(rgb, (0.07, 0.07, 0.09), np.clip((lado - 0.985) / 0.015, 0, 1) * 0.8)
    b = np.zeros((h, w))
    vj = [[((x / math.pi - 0.5) * w + w * 0.0, (yn - y) / (yn - yh) * h) for (x, y) in pts]
          for pts in ([(math.pi / 2 + 0.25, -1.2), (math.pi / 2 + 0.35, -2.0), (math.pi / 2 + 0.3, -2.7)],
                      [(3 * math.pi / 2 - 0.25, -1.2), (3 * math.pi / 2 - 0.35, -2.0), (3 * math.pi / 2 - 0.3, -2.7)])]
    dd = trazos(h, w, vj, 10.0 * k)
    rgb = mezclar_color(rgb, (0.5, 0.9, 0.96), np.clip(1 - dd / (2.4 * k), 0, 1) * 0.8)
    b = np.maximum(b, np.clip(1.5 - dd / (2.2 * k), 0, 1) * 0.8)
    pintar_grietas(rgb, b, rng, 10, w, h, w * 0.025, 6, con_luz=0.3)
    img[y0:y1, x0:x1] = rgb
    brillo[y0:y1, x0:x1] = b

    # --- la boca por dentro: arriba el paladar con pliegues y la encía; abajo la lengua con su surco y la encía
    y0, y1, x0, x1 = region(AT_CARNE)
    h, w = y1 - y0, x1 - x0
    uu = (np.arange(w) + 0.5) / w
    vv = (np.arange(h) + 0.5) / h
    U2 = uu[None, :] * np.ones((h, 1))
    V2 = vv[:, None] * np.ones((1, w))
    n1 = fbm(h, w, 12, 24, 51, 4)
    rgb = np.ones((h, w, 3)) * np.array((0.32, 0.11, 0.10))[None, None, :]
    rgb = mezclar_color(rgb, (0.52, 0.2, 0.16), n1)
    pal = V2 > 0.5
    pliegue = (0.5 + 0.5 * np.sin(V2 * 70.0 + 3.0 * np.abs(U2 - 0.5))) ** 3 * (1 - np.abs(U2 - 0.5) * 1.6).clip(0, 1)
    rgb = mezclar_color(rgb, (0.62, 0.30, 0.28), (pliegue * 0.5) * pal)
    lengua_ = np.clip(1 - np.abs(U2 - 0.5) / 0.22, 0, 1) * (~pal)
    rgb = mezclar_color(rgb, (0.70, 0.34, 0.33), lengua_ * 0.75)
    rgb = mezclar_color(rgb, (0.30, 0.10, 0.10), np.clip(1 - np.abs(U2 - 0.5) / 0.02, 0, 1) * lengua_ * 0.8)
    encia = np.clip((np.abs(V2 - 0.5) - 0.44) / 0.04, 0, 1)
    rgb = mezclar_color(rgb, ENCIA, encia * 0.85)
    rgb = mezclar_color(rgb, (0.16, 0.06, 0.06), np.clip(1 - np.abs(V2 - 0.5) / 0.05, 0, 1) * 0.7)   # la mejilla, honda
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
    me.from_pydata([(-3000, -3000, 0), (3000, -3000, 0), (3000, 3000, 0), (-3000, 3000, 0)], [], [(0, 1, 2, 3)])
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


def renders(carpeta, arm, nombre):
    """Fotos de Blender de una variante, todas con la misma luz: de frente, de perfil, boca cerrada (reposo), boca
    abierta (rugido) de lado y de frente, y la vista del combate con tres muñecos de los héroes a su escala. Compone
    una hoja (3 × 2) con todas."""
    sc = bpy.context.scene
    motor_eevee(sc)
    luces_y_suelo(sc)
    munecos = []
    for pos in ((-1.0, -16.5, 0.0), (2.8, -19.0, 0.0), (-3.4, -19.6, 0.0)):
        munecos += heroe_escala(sc, pos, 4.2)
    ad = arm.animation_data
    for t in ad.nla_tracks:
        t.mute = True
    hc = medir(R0)["hocico"]
    cab = hc + Vector((0.0, 2.6, -0.6))
    vistas = [("frente", "reposo", 0.0, (cab + Vector((0.0, -60.0, 8.0)), cab + Vector((0.0, 0.0, -1.0)), 11.0)),
              ("boca_cerrada", "reposo", 0.0, (cab + Vector((-30.0, -30.0, 7.0)), cab, 8.5)),
              ("boca_abierta", "rugido", 1.2, (cab + Vector((-30.0, -30.0, 7.0)), cab + Vector((0.0, 0.0, 1.0)), 9.0)),
              ("perfil", "reposo", 0.0, (Vector((-60.0, -6.0, 22.0)), Vector((0.0, -6.0, 7.0)), 24.0)),
              ("abierta_frente", "ataque_aliento", 1.2, (cab + Vector((0.0, -60.0, 10.0)), cab + Vector((0.0, -1.0, -1.5)), 11.0)),
              ("combate", "reposo", 0.0, (Vector(TRES_CUARTOS), Vector((-0.5, -9.5, 6.0)), 25.0))]
    rutas = []
    for (vista, clip, seg, (pos, mira, esc)) in vistas:
        ad.action = bpy.data.actions[clip]
        sc.frame_set(int(round(seg * FPS)) + 1)
        for o in munecos:
            o.hide_render = vista != "combate"
        cam = camara(sc, pos, mira, esc, 560, 480)
        ruta = os.path.join(carpeta, "%s_%s.png" % (nombre, vista))
        sc.render.filepath = ruta
        bpy.ops.render.render(write_still=True)
        bpy.data.objects.remove(cam)
        rutas.append(ruta)
    ad.action = None
    filas = []
    for fila in (rutas[:3], rutas[3:]):
        px = []
        for r in fila:
            im = bpy.data.images.load(r)
            px.append(np.array(im.pixels[:], dtype=np.float32).reshape(im.size[1], im.size[0], 4))
            bpy.data.images.remove(im)
        filas.append(np.concatenate(px, axis=1))
    hoja = np.concatenate(filas[::-1], axis=0)                       # (las filas de las imágenes van de abajo arriba)
    guardar_png(os.path.join(carpeta, "%s_hoja.png" % nombre), hoja)
    return hoja


def guardar_png(ruta, px):
    h, w = px.shape[:2]
    out = bpy.data.images.new(os.path.basename(ruta), w, h, alpha=True)
    out.pixels.foreach_set(px.ravel())
    out.filepath_raw = ruta
    out.file_format = "PNG"
    out.save()
    bpy.data.images.remove(out)
    print("PNG", ruta, w, h)


# ---------------------------------------------------------------- el modelo entero

def preparar_esqueleto():
    """Escena y esqueleto; ajusta los instantes del contrato y pone las placas del suelo donde cae la cabeza en la
    Fractura (si caen lejos, rehace el esqueleto con ellas en su sitio)."""
    global ARM, R0, LOSAS_CENTRO, HUESOS, NOMBRES
    for vuelta in range(2):
        sc = preparar_escena()
        arm = crear_esqueleto(sc)
        ARM = arm
        medir_signos(arm)
        arm.animation_data_create()
        R0 = pose_reposo(0.0)
        if vuelta == 0:
            ajustar_instantes()
            poses, _ = clip_ataque_sismico()
            hoc = medir(poses[76])["hocico"]
            centro = Vector((hoc.x, hoc.y + 1.3, 0.0))
            if (centro - LOSAS_CENTRO).length < 0.6:
                break
            LOSAS_CENTRO = centro
            print("LOSAS_CENTRO", tuple(round(x, 2) for x in LOSAS_CENTRO))
    return sc, arm


def modelo(carpeta, perfiles, prefijo, fotos=False):
    """Las versiones pedidas (mismos huesos y clips), sus texturas y el JSON de clips. Con fotos: las de Blender."""
    global R0
    os.makedirs(carpeta, exist_ok=True)
    rgb, a = pintar_textura(TEX)
    rutas_tex = {}
    for perfil, f, suf in (("alto", 1, ""), ("medio", 2, "_medio"), ("bajo", 4, "_bajo")):
        if perfil not in perfiles:
            continue
        r, al = (rgb, a) if f == 1 else reducir(rgb, a, f)
        ruta = os.path.join(carpeta, "%s_piel%s.webp" % (prefijo, suf))
        guardar_textura(ruta, r, al)
        rutas_tex[perfil] = ruta
        print("TEXTURA", ruta, r.shape[0], os.path.getsize(ruta))
    sc, arm = preparar_esqueleto()
    resumen = {"fps": FPS, "variante": VARIANTE, "huesos": NOMBRES, "clips": {}, "triangulos": {}, "texturas": {},
               "ajustes": dict(AJUSTE), "losas_centro": [round(LOSAS_CENTRO.x, 3), round(LOSAS_CENTRO.y, 3)],
               "puntos": {"hocico": a_godot(P_HOCICO()), "boca": a_godot(P_BOCA()), "garganta": a_godot(P_GARGANTA()),
                          "cierre": a_godot(P_CIERRE())}}
    for nombre, f in CLIPS.items():
        poses, marcas = f()
        medidas = crear_accion(arm, nombre, poses)
        m, extra = instantes(nombre, medidas, marcas)
        extra["boca_max"] = round(max(x["boca"] for x in medidas), 2)
        extra["cierre_max_reposo"] = round(max(x["cierre"] for x, p in zip(medidas, poses) if p.boca <= 0.0), 4) \
            if any(p.boca <= 0.0 for p in poses) else None
        resumen["clips"][nombre] = {"duracion": round((len(poses) - 1) / FPS, 4), "bucle": nombre in BUCLES,
                                    "instantes": m, **extra}
        print("CLIP", nombre, resumen["clips"][nombre])
    for t in arm.animation_data.nla_tracks:
        t.mute = False
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode='POSE')
    poner_pose(arm, R0)
    bpy.ops.object.mode_set(mode='OBJECT')
    obj_alto = None
    for perfil in perfiles:
        M = construir(perfil)
        obj = crear_objeto_malla(M, arm, "Bramavidrio_" + perfil, rutas_tex["alto"])
        tris = triangulos(M)
        resumen["triangulos"][perfil] = tris
        resumen["texturas"][perfil] = os.path.basename(rutas_tex[perfil])
        print("MALLA", perfil, "vértices", len(M.v), "triángulos", tris)
        suf = "" if perfil == "alto" else "_" + perfil
        exportar(os.path.join(carpeta, "%s%s.glb" % (prefijo, suf)))
        if perfil == "alto":
            if SALIDA_BLEND:
                bpy.ops.wm.save_as_mainfile(filepath=SALIDA_BLEND)
                print("GUARDADO", SALIDA_BLEND)
            pedidos = [("reposo", [0.0, 0.75, 1.5, 2.25]), ("rugido", [0.5, 0.8, 1.2, 1.9, 2.2]),
                       ("ataque", [0.55, 0.9, 1.0, 1.3]), ("ataque_sismico", [1.2, 2.0, 2.5333, 3.0]),
                       ("ataque_aliento", [0.4, 1.2, 1.9, 2.4, 3.0]), ("herida", [0.1, 0.4]),
                       ("derrota", [0.5, 1.6, 3.4]), ("emerger", [0.9, 1.2, 2.0])]
            resumen["intersecciones"] = comprobar_intersecciones(arm, obj, M, pedidos)
            if fotos:
                obj_alto = obj
                continue
        me = obj.data
        bpy.data.objects.remove(obj)
        bpy.data.meshes.remove(me)
    with open(os.path.join(carpeta, "%s_clips.json" % prefijo), "w", encoding="utf-8", newline="\n") as fh:
        json.dump(resumen, fh, ensure_ascii=False, indent=1)
    print("RESUMEN", json.dumps(resumen["triangulos"]))
    if fotos and obj_alto is not None:
        renders(carpeta, arm, prefijo)
    return resumen


def variantes(carpeta):
    """Cada variante entera en el alto (GLB con los 10 clips, textura y JSON) con sus fotos, y la comparación."""
    global VARIANTE
    hojas = []
    for var in LISTA_VARIANTES:
        VARIANTE = var
        sub = os.path.join(carpeta, var)
        modelo(sub, ["alto"], "%s_%s" % (PREFIJO, var), fotos=True)
        im = bpy.data.images.load(os.path.join(sub, "%s_%s_hoja.png" % (PREFIJO, var)))
        hojas.append(np.array(im.pixels[:], dtype=np.float32).reshape(im.size[1], im.size[0], 4))
        bpy.data.images.remove(im)
    todo = np.concatenate(hojas[::-1], axis=0)
    guardar_png(os.path.join(carpeta, "comparativa_variantes.png"), todo)


def principal():
    os.makedirs(CARPETA, exist_ok=True)
    if MODO == "variantes":
        variantes(CARPETA)
        return
    modelo(CARPETA, PERFILES, PREFIJO, fotos=False)


principal()
