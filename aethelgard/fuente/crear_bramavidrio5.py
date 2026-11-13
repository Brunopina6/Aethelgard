# Bramavidrio, versión 5, «la v4 resuelta» (V12, 12/11, noche). Orden del usuario: «Bramavidrio debe seguir teniendo
# prioridad artística hasta resolver satisfactoriamente su cabeza, mandíbula y movimientos». Parte de
# fuente/crear_bramavidrio4.py (la v4, «el Ancestral», que no se toca) y escribe en enemigos/bramavidrio/v5/ con nombres
# nuevos. Lo propio de la v5 está marcado «v5»; lo marcado «v4» sigue igual que en la v4.
# Referencia visual (SOLO referencia; no se copia ni entra en el juego): la lámina facilitada por el usuario
# («Concepto del gusano de arena ancestral.png»; copia en D:\REBELUM_diagnostico\v12\referencias\
# bramavidrio_v4_referencia_usuario.png, SHA-256 3a6044c0…a904c5d18; licencia sin registrar: referencia facilitada por el
# usuario). Geometría, textura, normales, esqueleto y clips: procedurales, de este guion.
#
# LO QUE CAMBIA RESPECTO DE LA V4 (informe docs/memory/agents/animaciones_v12_bramavidrio5.md):
#   - la BOCA: cuatro MANDÍBULAS acorazadas (arriba, abajo y los dos lados) con bisagra en el collar y COLMILLOS QUE SE
#     DESPLIEGAN; cerradas forman un hocico acorazado (los colmillos se cruzan en el centro) y abiertas dejan ver la boca
#     circular de la lámina; detrás siguen el esfínter de labios, cuatro filas de dientes en espiral y una GARGANTA más
#     honda, con anillos y una espiral de luz mineral en vez de un disco encendido;
#   - la CORONA: cuernos más gruesos y curvos y la cresta central de la lámina;
#   - los MOVIMIENTOS: la columna se mueve con RETRASO entre tramos (la base empuja y la cabeza llega después en los
#     ataques; el golpe recibido baja de la cabeza a la cola), anticipación, peso al caer, respiración, la cabeza que busca
#     a su objetivo, y las mandíbulas y colmillos con su propio retraso;
#   - el ENCUADRE: la Fractura y la descarga del Aliento se quedan por debajo del borde de arriba de la pantalla;
#   - los MATERIALES: normales horneadas de las alturas que pinta la textura (placas, grietas, runas, estrías).
#
#   blender -b --factory-startup -P crear_bramavidrio5.py -- <carpeta> [alto,medio,bajo] [<salida.blend>|-] [<fotos>]
#       <fotos>: si se da, una carpeta donde deja las fotos de Blender de cada etapa (silueta, cabeza y boca,
#       materiales, rig y deformaciones, animaciones, vídeos de la boca y del Aliento)
#
# LO QUE CONSERVA DE LA REFERENCIA: cuerpo largo, grueso y continuo que se estrecha hasta una punta cónica; placas de
# armadura superpuestas como tejas (arena, piedra y bronce) con la carne rojiza estriada entre ellas; grandes crestas
# dorsales curvadas hacia atrás con una vela de carne rojiza; cabeza acorazada con una corona de cuernos y el núcleo
# ámbar en la frente; boca circular enorme con varias filas de dientes curvos, labios de carne rojiza y una garganta
# profunda con luz mineral cálida; runas doradas que brillan, desgaste y cicatrices rojas de zarpazo; sin brazos ni patas.
#
# LA BOCA (v4): circular, sin mandíbula. La lámina solo la enseña abierta; para cerrarla sin cambiar la forma de la
# cabeza (ni un pico de pétalos que sobresalga ni una flor más ancha que ella) es un ESFÍNTER:
#   - el collar acorazado de la boca, los cuernos, el marco de placas en punta y los dientes del collar y de la
#     garganta son fijos (hueso «cabeza»);
#   - los labios (de carne) y la boca de la garganta son un tejido flexible pesado entre «cabeza» y «esfinter»: el hueso
#     esfinter escala en su plano (radial) y avanza; cada punto se acerca al eje según su peso, así que el labio se frunce
#     hacia el centro sin pliegues ni cruces (la contracción es radial y monótona: se comprueba);
#   - doce SECTORES articulados (labio_01 … labio_12) llevan los colmillos grandes: cada uno gira y se desplaza de modo que
#     la base de su colmillo sigue exactamente al labio (sin piezas sueltas: se mide) y, al cerrar, se inclina hacia
#     delante y se cruza sobre los labios fruncidos como una trampa;
#   - abierta (pose de enlace) es la de la lámina: labios en embudo, tres coronas de dientes y el fondo encendido.
# El chorro del Aliento nace en la GARGANTA: el hueso «garganta_ancla» (dentro, al fondo del embudo) sigue la animación,
# la orientación y la escala; el chorro 3D interior sale de él y el guion de Godot da su posición (origen_chorro()).
#
# Ejes (Blender): mira a −Y, Z arriba, su izquierda es +X. En Godot mira a +Z. Pose de enlace: tendido a lo largo de +Y
# con la nuca en el origen; los clips lo colocan respecto del AGUJERO (el origen; en Godot, y = 0 es la arena).
import bpy, sys, os, math, random, json
import numpy as np
from mathutils import Vector, Matrix, noise
from mathutils.bvhtree import BVHTree

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
CARPETA = argv[0] if argv else ""
MODO = argv[1] if len(argv) > 1 else "alto,medio,bajo"
PERFILES = [p for p in MODO.split(",") if p in ("alto", "medio", "bajo")]
SALIDA_BLEND = argv[2] if len(argv) > 2 and argv[2] not in ("", "-") else ""
CARPETA_FOTOS = argv[3] if len(argv) > 3 and argv[3] not in ("", "-") else ""
SOLO_ETAPAS = argv[4].split(",") if len(argv) > 4 and argv[4] else []
VARIANTES = ["ancestral"]
VARIANTE = "ancestral"
FPS = 30
CONCEPTO = False
PREFIJO = "bramavidrio5"

# ---------------------------------------------------------------- medidas

NSEG = 18
L_CUERPO = 22.0
LSEG = L_CUERPO / NSEG                     # 1,222 m por hueso de la columna
S_INI = 0.35                               # el tubo empieza dentro de la cabeza, DETRÁS del fondo de la garganta
ALETAS = range(2, NSEG)                    # huesos placa_kk (crestas y armadura del lomo: se erizan)
CALIDAD = {
    "alto": dict(lados=24, paso=0.5, pl_u=5, pl_v=3, cr_lados=6, cr_paso=10, cab_u=32, cab_l=9, boca_u=48, boca_r=9,
                 embudo=5, dientes=1.0, d_lados=5, cuerno_lados=7, mont=22, chorro=12, succion=10, losas=6, tex=2048,
                 crestas=1.0, cab_placas=1.0, membrana=6, nudillo=(5, 6), colm_max=4, mand_uv=None, garg=9, cuerno_seg=5, dientes_borde=5, union=2, filas_embudo=4, cejas=True),
    "medio": dict(lados=16, paso=0.85, pl_u=3, pl_v=2, cr_lados=4, cr_paso=6, cab_u=24, cab_l=6, boca_u=36, boca_r=5,
                  embudo=3, dientes=0.6, d_lados=4, cuerno_lados=5, mont=14, chorro=8, succion=7, losas=5, tex=1024,
                  crestas=1.0, cab_placas=0.6, membrana=4, nudillo=(3, 3), colm_max=4, mand_uv=(4, 4), garg=5, cuerno_seg=4, dientes_borde=2, union=1, filas_embudo=2, cejas=True),
    "bajo": dict(lados=10, paso=1.3, pl_u=2, pl_v=1, cr_lados=3, cr_paso=4, cab_u=16, cab_l=4, boca_u=20, boca_r=3,
                 embudo=2, dientes=0.34, d_lados=3, cuerno_lados=4, mont=9, chorro=6, succion=4, losas=4, tex=512,
                 crestas=0.5, cab_placas=0.3, membrana=2, nudillo=(2, 2), colm_max=2, mand_uv=(2, 3), garg=2, cuerno_seg=3, dientes_borde=1, union=1, filas_embudo=0, cejas=False),
}
Q = CALIDAD["alto"]

PIEL, VIDRIO, GARGANTA, ARENA, CHORRO, POLVO = range(6)
MATERIALES = ["piel", "vidrio", "garganta", "arena", "chorro", "polvo"]

# Atlas de la textura (u a la derecha, v hacia arriba, como en Blender)
AT_TUBO = (0.0, 0.5, 0.0, 1.0)             # la carne del cuerpo bajo las placas y el vientre
AT_PLACA = (0.5, 1.0, 0.5, 1.0)            # 4 × 4 losetas de placa de armadura (runas, cicatrices, desgaste)
AT_CABEZA = (0.5, 0.75, 0.22, 0.5)         # hueso y piedra: la cáscara de la cabeza, cuernos y crestas
AT_CARNE = (0.75, 1.0, 0.22, 0.5)          # labios, embudo y garganta
AT_MEMBRANA = (0.5, 0.75, 0.0, 0.22)       # las velas rojizas de las crestas
AT_ARENA = (0.75, 0.9, 0.0, 0.22)
AT_ROCA = (0.9, 1.0, 0.1, 0.22)
AT_NEUTRO = (0.9, 1.0, 0.0, 0.1)

# ---------------------------------------------------------------- colores (sRGB), tomados de la lámina

ARMADURA = (0.86, 0.76, 0.62)              # placas: arena y piedra clara
ARMADURA_OSC = (0.56, 0.45, 0.33)
BRONCE = (0.76, 0.58, 0.34)                # cantos y engastes
CARNE = (0.60, 0.26, 0.24)                 # entre placas, labios, velas
CARNE_OSC = (0.30, 0.09, 0.08)
ENCIA = (0.74, 0.38, 0.36)
MEMBRANA = (0.74, 0.36, 0.31)
AMBAR = (1.0, 0.70, 0.22)                  # el núcleo de la frente, las runas y la garganta
AMBAR_HONDO = (0.66, 0.26, 0.04)
VIDRIO_C = AMBAR
VIDRIO_HONDO = AMBAR_HONDO
VIDRIO_MEMBRANA = (0.40, 0.14, 0.04)
DIENTE = (0.94, 0.89, 0.77)
HUESO_DIENTE = ((0.95, 0.90, 0.78), (0.88, 0.82, 0.68), (0.97, 0.94, 0.86))
BASALTO = (0.40, 0.33, 0.26)               # (nombres de la v3: las losas del suelo de la Fractura)
BASALTO_CLARO = (0.66, 0.56, 0.44)
ARENA_C = (0.80, 0.64, 0.44)
VIENTRE = (0.72, 0.50, 0.42)

# El cuerpo: radio a lo largo (desde la nuca). Grueso y continuo; se estrecha en el último tercio hasta la punta.
RADIOS = {"ancestral": [(-1.0, 1.82), (0.0, 1.84), (2.0, 1.9), (5.0, 1.95), (8.0, 1.94), (11.0, 1.84), (13.5, 1.66),
                        (16.0, 1.38), (18.0, 1.08), (19.6, 0.78), (20.8, 0.5), (21.6, 0.28), (22.0, 0.16)]}

# La cabeza (v4): una cáscara redonda de la nuca (YN) al collar de la boca (YF); la boca en su frente, centrada en el eje.
YN = 1.1
YF = -2.45                                 # el plano de la boca (frente del collar)
R_CAB = [(1.1, 2.0), (0.3, 2.3), (-0.6, 2.6), (-1.5, 2.72), (-2.1, 2.66), (-2.45, 2.6)]   # (lámina: la
#                                            cabeza, 1,35 veces más ancha que el cuerpo)
R_LABIO = 2.3                              # el borde de fuera de los labios (pegado al collar)
R_BOCA = 0.9                               # el borde de dentro de los labios: la entrada del embudo
PEND = math.tan(math.radians(38.0))        # los labios bajan en embudo hacia dentro (38°)
BULTO, R_BULTO = 0.22, R_LABIO - 0.32      # el rodete del labio: avanza junto al collar (la lámina: labios gruesos)
FONDO_EMBUDO = 2.45                        # del plano de la boca al fondo del embudo
R_GARG = 0.44                              # la garganta al fondo del embudo
ANCLA_Y = YF + 2.3                         # el anclaje del chorro, dentro de la garganta
N_SECTORES = 12
R_COLMILLO = 1.55                          # la corona de colmillos de los sectores
S_MIN = 0.02                               # la escala del esfínter cerrado (no 0: el hueso se puede invertir)
T_CIERRE = 0.55                            # v5 (v4: 0,85): cuánto avanza el centro de los labios al cerrar; menos,
#                                            para que el frunce quede detrás de las mandíbulas cerradas
BOCA_ABIERTA = 60.0                        # «boca» en grados nominales: 0 cerrada, 60 la pose de enlace, hasta 67
K_LABIO = R_LABIO / (R_LABIO - R_BOCA)
CHORRO_LARGO = 12.0

# v5: las MANDÍBULAS. Cuatro placas acorazadas con bisagra RECTA (un eje tangente al collar, delante de él): al girar
# sobre su bisagra la base no se mueve (no se mete en el collar). Abiertas (la pose de enlace) apuntan hacia delante y
# algo hacia fuera (BETA_ABIERTA) y enmarcan la boca circular; cerradas (BETA_CERRADA) se inclinan hacia dentro y forman
# un hocico acorazado en punta roma, con los colmillos cruzados delante del esfínter. Cada una lleva su fila de
# COLMILLOS en un hueso propio (colm_*), que se pliegan contra la cara de dentro (0) o se despliegan hacia el eje (1).
# (nombre, ángulo de su centro: 0 arriba y 90 su izquierda (+X), semiancho en la bisagra, semiancho en la punta, largo,
#  colmillos, largo de los colmillos)
MANDIBULAS = [("arriba", 0.0, 1.38, 0.5, 1.85, 4, 0.78), ("izq", 90.0, 1.0, 0.42, 1.55, 3, 0.68),
              ("abajo", 180.0, 1.22, 0.5, 1.8, 4, 0.74), ("der", 270.0, 1.0, 0.42, 1.55, 3, 0.68)]
R_BISAGRA = 2.5                            # del eje de la boca a la bisagra
Y_BISAGRA = YF - 0.28                      # pegada al rodete del collar (que llega a YF − 0,24): sin hueco
BETA_ABIERTA = 22.0                        # grados hacia fuera (abierta, la pose de enlace): enmarcan la boca
BETA_CERRADA = -58.0                       # grados hacia dentro (cerrada)
BETA_DE_MAS = 10.0                         # lo que se abre de más al rugir (apertura 1,12)
G_MAND = 0.5                               # grosor de la mandíbula en la bisagra (en la punta, un 30 %): una cuña
#                                            maciza, no una tabla (la v5 primera se leía como tablas de perfil)
QUILLA = 0.14                              # la arista del lomo de la mandíbula (sobre el grosor, en el centro)
V_COLM = 0.74                              # dónde nace la fila de colmillos (de la bisagra, 0, a la punta, 1)
PLIEGUE = 42.0                             # grados que se pliegan los colmillos (de desplegados, 1, a plegados, 0):
#                                            plegados se tumban hacia la garganta (con la boca cerrada quedan dentro,
#                                            detrás de las placas) y desplegados apuntan al eje y hacia delante
ALTO_PIVOTE = 0.1                          # el eje del pliegue, algo por encima de la encía
BASE_COLM = 0.05                           # la base del colmillo, algo levantada de la encía (su raíz sigue dentro)
DIR_COLM = lambda n, d: (n * 0.88 + d * 0.42).normalized()   # desplegados: hacia el eje y algo hacia delante


def CAB():
    return {"yn": YN, "yh": YF, "yc": YF + 0.5, "K": 1.0}


def K_CAB():
    return 1.0


# ---------------------------------------------------------------- constructor de la malla (v4: con etiquetas por cara,
# para las comprobaciones de intersecciones)

class Malla:
    def __init__(self):
        self.v, self.col, self.uv, self.pesos, self.caras, self.mats, self.etq = [], [], [], [], [], [], []
        self.etiqueta = "otro"

    def vert(self, p, c, uv, pesos):
        self.v.append(Vector(p))
        self.col.append(tuple(c) + ((0.0,) if len(c) == 3 else ()))   # el alfa: cuánto «mineral» es (armadura)
        self.uv.append(tuple(uv))
        self.pesos.append(dict(pesos) if isinstance(pesos, dict) else {pesos: 1.0})
        return len(self.v) - 1

    def cara(self, idx, mat=PIEL, fuera=None, hacia=None):
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
        self.etq.append(self.etiqueta)

    def copia_de(self, i, color):
        """v5: un vértice nuevo en el mismo sitio, con los mismos pesos, pero otro color (cantos con su color)."""
        return self.vert(self.v[i], color, self.uv[i], self.pesos[i])

    def copia(self, i):
        if not hasattr(self, "_copias"):
            self._copias = {}
        if i not in self._copias:
            self._copias[i] = self.vert(self.v[i], self.col[i], self.uv[i], self.pesos[i])
        return self._copias[i]

    def doble(self, idx, mat):
        self.caras.append(tuple(idx))
        self.mats.append(mat)
        self.etq.append(self.etiqueta)
        self.caras.append(tuple(self.copia(i) for i in idx[::-1]))
        self.mats.append(mat)
        self.etq.append(self.etiqueta)


# ---------------------------------------------------------------- (copia literal de crear_bramavidrio3.py)

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


# ---------------------------------------------------------------- v4: el cuerpo (la piel continua bajo las placas)

def filas_tubo():
    paso = Q["paso"]
    fin = L_CUERPO - 0.12
    n = int(math.ceil(fin / paso))
    return [S_INI] + [fin * i / n for i in range(n + 1) if fin * i / n > S_INI + 0.1]


def crear_tubo(M):
    """La piel del cuerpo: carne rojiza estriada (la que se ve entre las placas) y, abajo, el vientre de anillos
    (la textura los pinta). Una sola piel continua de la nuca a la punta de la cola."""
    M.etiqueta = "cuerpo"
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
            ao = 0.72 + 0.28 * suave(-0.9, 0.3, math.cos(alfa))
            uv = en_atlas(AT_TUBO, j / lados, (s - S_INI) / (L_CUERPO - S_INI))
            cola = suave(20.6, 21.6, s)                                  # la punta de la cola, acorazada
            fila.append(M.vert((x, s, z), C(mezcla(CARNE, (1.35, 1.25, 1.1), cola), ao, cola), uv, peso_tubo(s)))
        filas.append(fila)
    rejilla(M, filas, PIEL, fuera=EJE)
    punta = M.vert((0, L_CUERPO + 0.4, 0.06), C(ARMADURA, 0.85, 1.0), en_atlas(AT_TUBO, 0.5, 1.0), {col_nombre(NSEG): 1.0})
    ult = filas[-1]
    for j in range(lados):
        M.cara((ult[j], ult[j + 1], punta), PIEL, fuera=lambda c: (0, L_CUERPO - 1.0, 0))


def uv_loseta(tile):
    """Una loseta de las 4 × 4 de placa del atlas: (u, v) de la placa (0..1) a su sitio, con un margen."""
    col, fila = tile % 4, tile // 4

    def f(u, v):
        return en_atlas(AT_PLACA, (col + 0.04 + 0.92 * max(0.0, min(1.0, u))) / 4, (fila + 0.04 + 0.92 * max(0.0, min(1.0, v))) / 4)
    return f


def escudo(M, sup, a0, a1, s0, s1, nu, nv, grosor, lev0, lev1, punta, punta_u, pesos, uvf, color=ARMADURA, eje=None,
           estrecha=None, punta_a=0.0):
    """v4: una placa de armadura sobre la superficie sup(a, s) → (punto, normal): de a0 a a1 alrededor y de s0 (delante)
    a s1 (detrás), con un pico de «punta» metros hacia atrás en punta_u (el chevrón de la lámina). Su cara de arriba va a
    grosor + lev(v) de la piel (lev0 delante, lev1 detrás: el canto de atrás se levanta sobre la siguiente, como una
    teja) y se abomba de lado a lado; los cantos bajan hasta dentro de la piel (crece de ella, no flota)."""
    eje = eje or EJE
    top, par_ = [], []
    for j in range(nv + 1):
        v = j / nv
        fila, pf = [], []
        for i in range(nu + 1):
            u = i / nu
            a = a0 + (a1 - a0) * u
            if estrecha is not None:
                a = 0.5 * (a0 + a1) + (a - 0.5 * (a0 + a1)) * estrecha(v)
            if punta_a:                                        # pico hacia abajo en el canto de abajo (laterales)
                borde_ = u if punta_a > 0 else 1 - u
                a += punta_a * borde_ ** 4 * math.sin(math.pi * v) ** 1.5
            ancho = max(punta_u, 1 - punta_u, 1e-6)
            pic = punta * max(0.0, 1.0 - abs(u - punta_u) / ancho) ** 1.6
            s = s0 + (s1 - s0) * v + pic * v ** 2
            p, n = sup(a, s)
            off = grosor * (1.0 + 0.75 * math.sin(math.pi * u)) + lev0 * (1 - v) + lev1 * v
            fila.append(M.vert(p + n * off, C(color, 0.96, 1.0), uvf(u, v), pesos(a, s)))
            pf.append((a, s, u, v))
        top.append(fila)
        par_.append(pf)
    rejilla(M, top, PIEL, fuera=eje)
    borde = [(0, i) for i in range(nu + 1)] + [(j, nu) for j in range(1, nv + 1)] + \
            [(nv, i) for i in range(nu - 1, -1, -1)] + [(j, 0) for j in range(nv - 1, 0, -1)]
    pies = []
    for (j, i) in borde:
        a, s, u, v = par_[j][i]
        p, n = sup(a, s)
        pies.append(M.vert(p - n * 0.05, C(mezcla(color, CARNE_OSC, 0.5), 0.55, 1.0), uvf(u, v), pesos(a, s)))
    nb = len(borde)
    for q in range(nb):
        j0, i0 = borde[q]
        j1, i1 = borde[(q + 1) % nb]
        M.cara((top[j0][i0], top[j1][i1], pies[(q + 1) % nb], pies[q]), PIEL, fuera=eje)
    return top


def crear_armadura_cuerpo(M):
    """Placas de la lámina: en cada anillo una dorsal ancha con chevrón atrás (se monta sobre la siguiente) y dos
    laterales más cortas que dejan ver la carne rojiza entre anillos; más pequeñas hacia la cola."""
    M.etiqueta = "armadura"
    rnd = random.Random(404)
    A_D, A_L = math.radians(50), math.radians(118)
    nu, nv = Q["pl_u"], Q["pl_v"]
    s = 0.25
    while s < 21.3:
        r = radio(s)
        L = 1.42 * (0.52 + 0.48 * suave(22.0, 13.5, s))
        g = 0.06 + 0.05 * r / 1.9
        sm = s + 0.5 * L
        hv = hueso_vela(sm)

        def pes_d(a, ss, s0=s, L_=L, hv_=hv):
            w = 0.3 * suave(s0 + 0.55 * L_, s0 + L_, ss)
            d = {k_: w_ * (1 - w) for k_, w_ in peso_tubo(ss).items()}
            if w > 0.01 and hv_.startswith("placa"):
                d[hv_] = d.get(hv_, 0.0) + w
            return d
        pes = lambda a, ss: peso_tubo(ss)
        escudo(M, sup_cuerpo, -A_D, A_D, s, s + L + 0.24, nu + 1, nv, g, 0.03, 0.2, 0.6 * L, 0.5, pes_d,
               uv_loseta(rnd.randrange(15)))
        for lado in (1, -1):
            a0, a1 = (A_D - 0.14, A_L) if lado > 0 else (-A_L, -(A_D - 0.14))
            escudo(M, sup_cuerpo, a0, a1, s + 0.1, s + L - 0.12, nu, nv, g * 0.85, 0.02, 0.1, 0.22 * L,
                   0.85 if lado > 0 else 0.15, pes, uv_loseta(rnd.randrange(15)), punta_a=0.32 * lado)
        s += L


# Las crestas dorsales (s, alto): grandes delante, menores hacia la cola (lámina: unas diez)
CRESTAS = [(1.5, 2.45), (3.6, 2.7), (5.7, 2.6), (7.8, 2.4), (9.9, 2.15), (11.9, 1.85), (13.8, 1.5), (15.6, 1.15),
           (17.3, 0.85), (18.9, 0.6), (20.2, 0.4)]


def cresta(M, s_c, h):
    """Una cresta de la lámina: una cuchilla de hueso curvada hacia atrás, de canto delantero afilado, con una vela de
    carne rojiza entre su borde de atrás y el lomo (la vela se estira si la cresta se eriza: pesos repartidos)."""
    hueso = hueso_vela(s_c)
    p0, n0 = sup_cuerpo(0.0, s_c)
    base = p0 + n0 * 0.06
    nl, ns = Q["cr_lados"], Q["cr_paso"]
    arriba, atras, X = Vector((0.0, 0.0, 1.0)), Vector((0.0, 1.0, 0.0)), Vector((1.0, 0.0, 0.0))
    centro = lambda t: base + arriba * (h * t) + atras * (h * 1.05 * max(0.0, t) ** 1.7)

    def tang(t):
        return (centro(t + 0.01) - centro(t - 0.01)).normalized()
    cuerda = lambda t: (0.55 * h ** 0.75 + 0.15) * (1 - t) ** 1.15 + 0.02
    grueso = lambda t: (0.17 + 0.05 * h) * (1 - t) ** 0.9 + 0.012
    M.etiqueta = "cresta"
    anillos, bordes = [], []
    ts = [-0.12] + [0.94 * q / ns for q in range(1, ns + 1)]
    for t in ts:
        T = tang(max(t, 0.0))
        Cd = X.cross(T).normalized()                     # hacia delante (la cabeza)
        fila = []
        for i in range(nl):
            ph = 2 * math.pi * i / nl
            c = math.cos(ph)
            ext = cuerda(t) * (0.32 if c > 0 else 0.68)
            q = centro(t) + Cd * c * ext + X * math.sin(ph) * grueso(t)
            tono = mezcla(BRONCE, ARMADURA, suave(0.0, 0.35, t))
            fila.append(M.vert(q, C(tono, 0.8 + 0.2 * t, 1.0), en_atlas(AT_CABEZA, i / nl, 0.1 + 0.85 * max(0.0, t)), hueso))
        anillos.append(fila)
        bordes.append(centro(t) - Cd * cuerda(t) * 0.68)
    rejilla(M, anillos, PIEL, cerrar_u=True, fuera=lambda c: min((centro(t) for t in ts), key=lambda z: (z - c).length))
    tip = M.vert(centro(1.0), C(mezcla(ARMADURA, (1, 1, 1), 0.3), 1.0, 1.0), en_atlas(AT_CABEZA, 0.5, 0.98), hueso)
    for i in range(nl):
        M.cara((anillos[-1][i], anillos[-1][(i + 1) % nl], tip), PIEL, fuera=lambda c: centro(0.9))
    # la vela: del borde de atrás de la cuchilla al lomo, por las dos caras
    M.etiqueta = "vela"
    nm = Q["membrana"]
    filas = []
    for q in range(nm + 1):
        t = 0.06 + 0.76 * q / nm
        T = tang(t)
        e = centro(t) - X.cross(T).normalized() * cuerda(t) * 0.6
        sb = e.y
        pb, nb = sup_cuerpo(0.0, sb)
        b = pb + nb * (0.12 + 0.05 * (1 - q / nm))
        w = 1.0 - 0.15 * (1 - q / nm)
        pe = {hueso: w}
        for k_, w_ in peso_tubo(sb).items():
            pe[k_] = pe.get(k_, 0.0) + (1 - w) * w_
        filas.append((M.vert(e, C(MEMBRANA, 1.0, 0.0), en_atlas(AT_MEMBRANA, q / nm, 0.95), pe),
                      M.vert(b, C(MEMBRANA, 0.7, 0.0), en_atlas(AT_MEMBRANA, q / nm, 0.05), peso_tubo(sb))))
    for q in range(nm):
        M.doble((filas[q][0], filas[q + 1][0], filas[q + 1][1], filas[q][1]), PIEL)


def crear_crestas(M):
    lista = CRESTAS if Q["crestas"] >= 1.0 else CRESTAS[::2]
    for (s, h) in lista:
        cresta(M, s, h)


# ---------------------------------------------------------------- v4: la cabeza

def r_cab(y):
    return catmull([(-a, b) for (a, b) in R_CAB], -y)


def sup_cabeza(a, y):
    """La cáscara de la cabeza: redonda (la boca está en su frente, centrada en el eje), algo más plana por abajo."""
    r = r_cab(y)
    c = math.cos(a)
    plano = 1.0 - 0.05 * max(0.0, -c) ** 1.2
    p = Vector((r * math.sin(a), y, r * c * plano))
    dr = (r_cab(y + 0.01) - r_cab(y - 0.01)) / 0.02
    n = Vector((math.sin(a), -dr, c)).normalized()
    return p, n


def peso_cabeza(y):
    """La cabeza es rígida (hueso «cabeza») salvo la nuca, que se reparte con el cuello."""
    f = 0.5 * suave(0.2, YN + 0.35, y)
    if f < 0.01:
        return {"cabeza": 1.0}
    d = {k_: w_ * f for k_, w_ in peso_tubo(y).items()}
    d["cabeza"] = d.get("cabeza", 0.0) + 1 - f
    return d


def labio_punto(r, a):
    """Un punto de los labios (abiertos, la pose de enlace) a radio r y ángulo a (0 arriba)."""
    d = (R_LABIO - r) * PEND - BULTO * math.exp(-((r - R_BULTO) / 0.3) ** 2) * suave(R_LABIO, R_LABIO - 0.12, r)
    return Vector((r * math.sin(a), YF + d, r * math.cos(a)))


def peso_labio(r):
    """Peso del esfínter en los labios: con él cerrado, el punto de radio r va a (r − R_BOCA)·K_LABIO (la entrada del
    embudo al centro, el borde de fuera quieto): contracción radial y monótona, sin pliegues."""
    if r >= R_LABIO:
        return 0.0
    if r <= R_BOCA:
        return 1.0
    return max(0.0, min(1.0, (1.0 - (r - R_BOCA) * K_LABIO / r) / (1.0 - S_MIN)))


D_ENTRADA = (R_LABIO - R_BOCA) * PEND       # lo hondo de la entrada del embudo (el rodete ya no llega aquí)


def perfil_embudo(t):
    """El embudo de la garganta (t de 0, su entrada, a 1, el fondo): radio y hondura desde el plano de la boca."""
    r = R_BOCA + (R_GARG - R_BOCA) * (1 - (1 - t) ** 1.6)
    d = D_ENTRADA + (FONDO_EMBUDO - D_ENTRADA) * t
    return r, d


def peso_embudo(d):
    return suave(D_ENTRADA + 0.25, D_ENTRADA, d)


def pesos_esf(w):
    if w > 0.999:
        return {"esfinter": 1.0}
    if w < 0.001:
        return {"cabeza": 1.0}
    return {"esfinter": w, "cabeza": 1 - w}


def crear_cabeza(M):
    """La cáscara, el cierre con el cuello, el collar de la boca, los labios (tejido flexible del esfínter), el embudo
    y la garganta encendida al fondo: una sola superficie del collar a la garganta (sin huecos que dejen ver a través)."""
    nU = Q["cab_u"]
    ys = [YN + (YF - YN) * i / Q["cab_l"] for i in range(Q["cab_l"] + 1)]
    M.etiqueta = "craneo"
    filas = []
    for y in ys:
        fila = []
        for j in range(nU + 1):
            a = -math.pi + 2 * math.pi * j / nU
            p, n = sup_cabeza(a, y)
            ao = 0.75 + 0.25 * suave(-0.8, 0.4, math.cos(a))
            fila.append(M.vert(p, C(ARMADURA_OSC, ao, 1.0), en_atlas(AT_CABEZA, j / nU, (YN - y) / (YN - YF)), peso_cabeza(y)))
        filas.append(fila)
    rejilla(M, filas, PIEL, fuera=lambda q: (0.0, q.y, 0.0))
    # el cierre con el cuello (la cáscara se ciñe al cuerpo detrás de la nuca)
    yq = YN + 0.4
    rq = radio(yq) * 0.97
    cu = [M.vert((rq * math.sin(-math.pi + 2 * math.pi * j / nU), yq, rq * math.cos(-math.pi + 2 * math.pi * j / nU)),
                 C(ARMADURA_OSC, 0.6, 1.0), en_atlas(AT_CABEZA, j / nU, 0.0), peso_tubo(yq)) for j in range(nU + 1)]
    rejilla(M, [cu, filas[0]], PIEL, fuera=lambda q: (0.0, q.y - 0.6, 0.0))
    # el collar: del borde de la cáscara al de los labios, con un reborde que avanza (el canto de bronce)
    nb = Q["boca_u"]
    M.etiqueta = "collar"
    ang = [-math.pi + 2 * math.pi * j / nb for j in range(nb + 1)]
    anillos = []
    for (rr, dy, tono, ao, mn, v_) in ((None, 0.0, ARMADURA_OSC, 0.85, 1.0, None), (R_LABIO + 0.24, -0.1, BRONCE, 1.0, 1.0, None),
                                       (R_LABIO + 0.17, -0.05, CARNE, 0.55, 0.0, 0.995),
                                       (R_LABIO + 0.12, -0.24, CARNE, 1.0, 0.0, 0.99),
                                       (R_LABIO + 0.03, -0.12, CARNE, 0.9, 0.0, 0.985)):
        fila = []
        for j, a in enumerate(ang):
            if rr is None:
                p, _ = sup_cabeza(a, YF)
            else:
                p = Vector((rr * math.sin(a), YF + dy, rr * math.cos(a)))
            uv_ = en_atlas(AT_CABEZA, j / nb, 0.99) if v_ is None else en_atlas(AT_CARNE, j / nb, v_)
            fila.append(M.vert(p, C(tono, ao, mn), uv_, "cabeza"))
        anillos.append(fila)
    # los labios: del collar a la entrada del embudo
    lab = []
    nr = Q["boca_r"]
    for i in range(nr + 1):
        r = R_LABIO - (R_LABIO - R_BOCA) * i / nr
        w = peso_labio(r)
        fila = []
        for j, a in enumerate(ang):
            ao = 1.0 - 0.45 * (i / nr) ** 1.3
            fila.append(M.vert(labio_punto(r, a), C(CARNE, ao, 0.0), en_atlas(AT_CARNE, j / nb, 0.98 - 0.5 * i / nr), pesos_esf(w)))
        lab.append(fila)
    rejilla(M, anillos + [lab[0]], PIEL, fuera=lambda q: (0.0, q.y + 1.0, 0.0))
    M.etiqueta = "labio"
    rejilla(M, lab, PIEL, hacia=lambda q: (0.0, q.y - 1.5, 0.0))
    # el embudo: de la entrada al fondo (sus primeros anillos aún se fruncen con el esfínter)
    emb = [lab[-1]]
    ne = Q["embudo"]
    for e in range(1, ne + 1):
        t = e / ne
        r, d = perfil_embudo(t)
        w = peso_embudo(d)
        fila = [M.vert(Vector((r * math.sin(a), YF + d, r * math.cos(a))), C(mezcla(CARNE, CARNE_OSC, t), 1.0 - 0.45 * t, 0.0),
                       en_atlas(AT_CARNE, j / nb, 0.48 - 0.4 * t), pesos_esf(w)) for j, a in enumerate(ang)]
        emb.append(fila)
    rejilla(M, emb, PIEL, hacia=lambda q: (0.0, q.y - 0.2, 0.0))
    # v5: la garganta, más honda y con anillos (relieve que da profundidad: crestas claras y surcos oscuros) y una
    # ESPIRAL de luz mineral que baja hacia el fondo (la lámina), en vez del disco encendido de la v4. El fondo es
    # oscuro con un núcleo pequeño: la luz sale de las vetas, no de un círculo plano.
    M.etiqueta = "garganta"
    r0, d0 = perfil_embudo(1.0)
    gar = []
    anillos_g = [(r0, d0, 0.0), (0.38, d0 + 0.2, 0.12), (0.43, d0 + 0.38, 0.22), (0.33, d0 + 0.6, 0.34), (0.38, d0 + 0.8, 0.45),
                 (0.27, d0 + 1.02, 0.58), (0.3, d0 + 1.22, 0.7), (0.19, d0 + 1.45, 0.84), (0.1, d0 + 1.65, 0.95)]
    anillos_g = [anillos_g[round(i * (len(anillos_g) - 1) / (Q["garg"] - 1))] for i in range(Q["garg"])]
    for q, (rr, dd, h) in enumerate(anillos_g):
        cresta_ = q % 2 == 0                                         # los anillos de la cresta, más claros
        fila = []
        for a in ang:
            espiral = max(0.0, math.sin(3.0 * a + 7.5 * h)) ** 3          # tres brazos que se enroscan hacia el fondo
            luz = (0.10 + 0.22 * h) * (1.0 if cresta_ else 0.55) + espiral * (0.35 + 0.6 * h)
            fila.append(M.vert(Vector((rr * math.sin(a), YF + dd, rr * math.cos(a))), (luz, luz * 0.6, luz * 0.2), (0.5, 0.5),
                               "cabeza"))
        gar.append(fila)
    rejilla(M, gar, GARGANTA, hacia=lambda q: (0.0, q.y, 0.0))
    fondo = M.vert(Vector((0.0, YF + anillos_g[-1][1] + 0.12, 0.0)), (1.0, 0.78, 0.4), (0.5, 0.5), "cabeza")
    for j in range(nb):
        M.cara((gar[-1][j], gar[-1][j + 1], fondo), GARGANTA, hacia=lambda q: (0.0, q.y - 1.0, 0.0))
    CABEZA_INFO.update(lab=lab, emb=emb, ang=ang)


CABEZA_INFO = {}


def diente(M, base, dir_, curva, largo, grueso, lados, hueso, color=None, rnd=None, mineral=0.6, etiqueta="diente", t1=0.2):
    """v4: un diente curvo de hueso con la base metida en la carne (los caras de la base llevan la etiqueta
    «<etiqueta>_base», que las comprobaciones no cuentan: esa parte está dentro a propósito)."""
    dir_ = dir_.normalized()
    centro = lambda t: base + dir_ * largo * t + curva * largo * 0.38 * t * t
    ref = Vector((1.0, 0.0, 0.0)) if abs(dir_.x) < 0.8 else Vector((0.0, 1.0, 0.0))
    u = dir_.cross(ref).normalized()
    w = dir_.cross(u).normalized()
    if color is None:
        color = (rnd or random).choice(HUESO_DIENTE)
    anillos = []
    for t, f, c in ((-0.14, 1.0, mezcla(color, ENCIA, 0.6)), (t1, 0.9, mezcla(color, (0.6, 0.5, 0.4), 0.35)),
                    (0.5 + 0.4 * t1, 0.62, color)):
        anillos.append([M.vert(centro(t) + (u * math.cos(2 * math.pi * i / lados) + w * math.sin(2 * math.pi * i / lados))
                               * grueso * f, c + (mineral,), neutro(), hueso) for i in range(lados)])
    eje = lambda c: centro(max(-0.14, min(1.0, (c - base).dot(dir_) / largo)))
    M.etiqueta = etiqueta + "_base"
    rejilla(M, anillos[:2], PIEL, cerrar_u=True, fuera=eje)
    M.etiqueta = etiqueta
    rejilla(M, anillos[1:], PIEL, cerrar_u=True, fuera=eje)
    punta = M.vert(centro(1.0), mezcla(color, (1, 1, 1), 0.4) + (mineral,), neutro(), hueso)
    for i in range(lados):
        M.cara((anillos[2][i], anillos[2][(i + 1) % lados], punta), PIEL, fuera=lambda c: centro(0.6))


def e_r(a):
    return Vector((math.sin(a), 0.0, math.cos(a)))


ADELANTE = Vector((0.0, -1.0, 0.0))
ATRAS = Vector((0.0, 1.0, 0.0))
def diente_curvo(M, base, dir_, curva, largo, grueso, lados, hueso, n_seg=4, color=None, rnd=None, mineral=0.6,
                 etiqueta="diente", hundido=0.14, punta_clara=0.4):
    """v5: un diente, colmillo o cuerno CURVO de verdad: n_seg anillos a lo largo de una curva (el eje se dobla hacia
    «curva»), grueso en la base y afilado en la punta, con la base metida «hundido» en la carne (esas caras llevan la
    etiqueta «<etiqueta>_base», que las comprobaciones no cuentan). La v4 tenía tres anillos y se leía recto."""
    dir_ = dir_.normalized()
    centro = lambda t: base + dir_ * largo * t + curva * largo * 0.55 * t * t
    if color is None:
        color = (rnd or random).choice(HUESO_DIENTE)
    anillos = []
    ts = [-hundido] + [(k + 1) / (n_seg + 1) * 0.92 for k in range(n_seg)]
    for k, t in enumerate(ts):
        tg = (centro(min(1.0, t + 0.02)) - centro(max(-hundido, t - 0.02))).normalized()
        ref = Vector((1.0, 0.0, 0.0)) if abs(tg.x) < 0.8 else Vector((0.0, 1.0, 0.0))
        u = tg.cross(ref).normalized()
        w = tg.cross(u).normalized()
        f = 1.0 if t <= 0 else (1.0 - 0.82 * t ** 1.15)
        c = mezcla(color, ENCIA, 0.6) if t < 0 else mezcla(mezcla(color, (0.55, 0.45, 0.36), 0.35), color, min(1.0, t * 2.5))
        anillos.append([M.vert(centro(t) + (u * math.cos(2 * math.pi * i / lados) + w * math.sin(2 * math.pi * i / lados))
                               * grueso * f, c + (mineral,), neutro(), hueso) for i in range(lados)])
    pts_eje = [centro(t) for t in ts]
    eje = lambda c: min(pts_eje, key=lambda z: (z - c).length)
    M.etiqueta = etiqueta + "_base"
    rejilla(M, anillos[:2], PIEL, cerrar_u=True, fuera=eje)
    M.etiqueta = etiqueta
    rejilla(M, anillos[1:], PIEL, cerrar_u=True, fuera=eje)
    punta = M.vert(centro(1.0), mezcla(color, (1, 1, 1), punta_clara) + (mineral,), neutro(), hueso)
    for i in range(lados):
        M.cara((anillos[-1][i], anillos[-1][(i + 1) % lados], punta), PIEL, fuera=lambda c: pts_eje[-1] + (pts_eje[-2] - pts_eje[-1]))
    return centro


def crear_dientes(M):
    """v5: los dientes FIJOS de la boca. Los grandes colmillos van ahora en las mandíbulas (crear_mandibulas); aquí:
    1) en el collar, solo en los cuatro huecos entre mandíbulas (en la v4 daban la vuelta entera: ahora las mandíbulas
       pasan por ahí al cerrar);
    2) cuatro filas en el embudo, en ESPIRAL (cada fila girada respecto de la anterior) y curvadas hacia la garganta,
       más pequeñas cuanto más hondas: el túnel de dientes de la lámina."""
    rnd = random.Random(77)
    f = Q["dientes"]
    lados = Q["d_lados"]
    n_hueco = 0                      # v5, 2.ª vuelta: los huecos entre mandíbulas los cubren ahora las mejillas de carne
    for diag in (45.0, 135.0, 225.0, 315.0):
        for q in range(n_hueco):
            a = math.radians(diag + (q - 0.5 * (n_hueco - 1)) * 13.0)
            base = Vector(((R_LABIO + 0.06) * math.sin(a), YF - 0.2, (R_LABIO + 0.06) * math.cos(a)))
            d = -e_r(a) * math.cos(math.radians(28)) + ADELANTE * math.sin(math.radians(28))
            diente_curvo(M, base, d, -e_r(a) * 0.15 + ATRAS * 0.5, rnd.uniform(0.5, 0.6), rnd.uniform(0.09, 0.105), lados,
                         "cabeza", n_seg=3, rnd=rnd, etiqueta="diente_fijo")
    filas_emb = ((0.34, 20, 0.44, 0.08, -8), (0.52, 18, 0.38, 0.07, 2), (0.7, 16, 0.31, 0.058, 10), (0.86, 13, 0.24, 0.046, 16))
    for fi, (t, n, largo, grueso, incl) in enumerate(filas_emb[:Q["filas_embudo"]]):
        r, d = perfil_embudo(t)
        n = max(6, int(round(n * max(f, 0.5))))
        giro = 0.55 * fi                                         # la espiral: cada fila, girada
        for i in range(n):
            a = 2 * math.pi * i / n + giro
            base = Vector((r * math.sin(a), YF + d, r * math.cos(a)))
            dd = -e_r(a) * math.cos(math.radians(incl)) + ADELANTE * math.sin(math.radians(incl))
            tang = Vector((math.cos(a), 0.0, -math.sin(a)))      # se tuercen un poco a lo largo de la espiral
            diente_curvo(M, base, dd, ATRAS * 0.55 + tang * 0.18, largo * rnd.uniform(0.9, 1.1), grueso, max(3, lados - 1),
                         "cabeza", n_seg=3 if f >= 1.0 else 2, rnd=rnd, etiqueta="diente_fijo", hundido=0.12)


def marco_mandibula(k):
    """v5: el marco de la mandíbula k en la pose de enlace (abierta): bisagra H, eje de la bisagra t, dirección d (de la
    bisagra a la punta) y normal de dentro n (hacia el eje de la boca). t = n × d: un giro POSITIVO sobre t lleva n hacia
    d y d hacia −n (abre); para cerrar, negativo."""
    nombre, ang, w0, w1, largo, n_col, l_col = MANDIBULAS[k]
    a = math.radians(ang)
    er = e_r(a)
    b = math.radians(BETA_ABIERTA)
    H = er * R_BISAGRA + Vector((0.0, Y_BISAGRA, 0.0))
    d = (ADELANTE * math.cos(b) + er * math.sin(b)).normalized()
    n = (-er * math.cos(b) + ADELANTE * math.sin(b)).normalized()
    t = n.cross(d).normalized()
    return H, t, d, n


GANCHO = 0.3                                 # v5: cuánto se curva hacia dentro la punta de la mandíbula (m)
ABOMBADO = 0.22                              # v5: lo que se abomba de lado a lado (el lomo hacia fuera)


def mandibula_punto(k, u, v, cara):
    """v5: un punto de la placa k (u de −1 a 1 a lo ancho, v de 0 en la bisagra a 1 en la punta); cara 1 la de fuera
    (coraza), 0 la de dentro (encía). La cara de dentro pasa EXACTAMENTE por el eje de la bisagra (v = 0): al girar, la
    base no barre nada."""
    nombre, ang, w0, w1, largo, n_col, l_col = MANDIBULAS[k]
    H, t, d, n = marco_mandibula(k)
    w = w0 + (w1 - w0) * v ** 0.9
    medio = H + t * (u * w) + d * (largo * v) + n * (GANCHO * v * v)
    nace = suave(0.0, 0.45, v)                    # crece despacio desde la bisagra (antes, un tallo fino y una placa gorda)
    # abombada como una concha alrededor de la boca: el lomo (u = 0) en el plano de la bisagra y los cantos curvados
    # HACIA DENTRO (hacia el eje); así la placa no se separa de la cabeza (antes el lomo se iba 0,4 m hacia fuera)
    curva_ = ABOMBADO * (1.0 - 0.45 * v) * u * u * nace
    encia = 0.04 * math.exp(-((v - V_COLM) / 0.09) ** 2) * (1.0 - 0.5 * u * u)
    g = G_MAND * (1.0 - 0.7 * v) * (0.3 + 0.7 * nace) + QUILLA * (1.0 - abs(u)) * (1.0 - 0.5 * v) * nace
    if cara == 1:
        return medio + n * curva_ - n * g
    return medio + n * curva_ + n * encia


def crear_mandibulas(M):
    """v5: las cuatro mandíbulas acorazadas (hueso mand_<nombre>) con su fila de colmillos (hueso colm_<nombre>). La
    cara de fuera es coraza (losetas de placa con canto de bronce: mineral), la de dentro encía y carne (sin mineral), y
    el borde de la punta va dentado. Los colmillos nacen de la encía (su base, metida en ella)."""
    rnd = random.Random(505)
    lados = Q["d_lados"] + 1
    nu, nv = Q["mand_uv"] or (max(3, Q["pl_u"] + 2), max(3, Q["pl_v"] + 3))
    for k, (nombre, ang, w0, w1, largo, n_col, l_col) in enumerate(MANDIBULAS):
        hueso = "mand_" + nombre
        H, t, d, n = marco_mandibula(k)
        uvf = uv_loseta([3, 9, 6, 12][k])
        M.etiqueta = "mand_" + nombre
        caras = {}
        for cara in (1, 0):
            filas = []
            for j in range(nv + 1):
                v = j / nv
                fila = []
                for i in range(nu + 1):
                    u = -1.0 + 2.0 * i / nu
                    vv = v
                    if j == nv:                                       # el borde dentado de la punta
                        vv = 1.0 + (0.08 if i % 2 == 1 else -0.02)
                    p = mandibula_punto(k, u, vv, cara)
                    if cara == 1:
                        col = C(mezcla(ARMADURA, BRONCE, 0.25 * v), 0.78 + 0.22 * (1 - abs(u)), 1.0)
                        uv_ = uvf(0.5 + 0.5 * u, 1.0 - v)
                    else:
                        col = C(mezcla(CARNE, ENCIA, math.exp(-((v - V_COLM) / 0.12) ** 2)), 0.55 + 0.45 * v, 0.0)
                        uv_ = en_atlas(AT_CARNE, 0.5 + 0.45 * u, 0.55 + 0.4 * v)
                    fila.append(M.vert(p, col, uv_, hueso))
                filas.append(fila)
            caras[cara] = filas
        # v5, 2.ª vuelta: los vértices de la bisagra (para medir que la mandíbula no se separa de la cabeza)
        if not hasattr(M, "bisagras"):
            M.bisagras = {}
        M.bisagras[nombre] = list(caras[0][0])
        # orientación: la de fuera mira lejos del eje de la boca (−n); la de dentro, hacia él (+n)
        rejilla(M, caras[1], PIEL)
        _orientar_ultimas(M, nu * nv, -n)
        rejilla(M, caras[0], PIEL)
        _orientar_ultimas(M, nu * nv, n)
        # los cantos: los dos lados, la punta y la base (cierran la placa)
        bordes = [[(j, 0) for j in range(nv + 1)], [(j, nu) for j in range(nv + 1)], [(nv, i) for i in range(nu + 1)],
                  [(0, i) for i in range(nu + 1)]]
        for borde, hacia_fuera in zip(bordes, (-t, t, d, -d)):
            a_ = [caras[1][j][i] for (j, i) in borde]
            b_ = [M.copia_de(caras[0][j][i], C(BRONCE, 0.8, 1.0)) for (j, i) in borde]
            a_ = [M.copia_de(x, C(BRONCE, 0.9, 1.0)) for x in a_]
            for q in range(len(borde) - 1):
                M.cara((a_[q], a_[q + 1], b_[q + 1], b_[q]), PIEL)
            _orientar_ultimas(M, len(borde) - 1, hacia_fuera)
        # la base (en el eje de la bisagra): no cuenta en las comprobaciones (va dentro del nudillo)
        M.etq[-nu:] = ["mand_%s_base" % nombre] * nu
        # el NUDILLO de la bisagra (fijo, de la cabeza): medio cilindro de carne y bronce alrededor del eje, por detrás
        # (hacia el collar), que une la mandíbula con el collar sin hueco. La placa gira siempre por delante de él
        # (de +32° a −58° desde delante; el nudillo ocupa ±45° alrededor de atrás).
        M.etiqueta = "collar"
        r_n = 0.2
        atras_ = ATRAS
        lado_ = (atras_ - t * atras_.dot(t)).normalized()
        otro = t.cross(lado_).normalized()
        aros = []
        n_s, n_ph = Q["nudillo"]
        for s_ in np.linspace(-1.0, 1.0, n_s):
            aro = []
            for q in range(n_ph + 1):
                ph = math.radians(-45.0 + 90.0 * q / n_ph)
                p = H + t * (s_ * w0 * 1.04) + (lado_ * math.cos(ph) + otro * math.sin(ph)) * r_n
                aro.append(M.vert(p, C(mezcla(CARNE, BRONCE, 0.4), 0.7, 0.5), en_atlas(AT_CARNE, 0.5 + 0.4 * s_, 0.9), "cabeza"))
            aros.append(aro)
        for q in range(len(aros) - 1):
            for i in range(n_ph):
                M.cara((aros[q][i], aros[q][i + 1], aros[q + 1][i + 1], aros[q + 1][i]), PIEL,
                       fuera=lambda c, H_=H, t_=t: H_ + t_ * (c - H_).dot(t_))
        M.etiqueta = "mand_" + nombre
        # v5, 2.ª vuelta: DIENTES EN EL BORDE de la mandíbula (una fila en la punta, hacia el eje y adelante) y una fila
        # más pequeña cerca de la bisagra: los anillos de dientes del borde de la boca de la lámina. Van con la mandíbula.
        n_borde = Q["dientes_borde"] + (1 if nombre == "arriba" else 0)
        for (v_, n_, largo_, grueso_, dir_n, dir_d) in ((0.95, n_borde, 0.32, 0.065, 0.75, 0.6),
                                                       (0.38, max(1 if Q["dientes"] < 0.5 else 2, n_borde - 1), 0.26, 0.06, 0.9, 0.3)):
            for q in range(n_):
                u = -0.78 + 1.56 * (q + 0.5) / n_
                base = mandibula_punto(k, u, v_, 0) + n * 0.02
                diente_curvo(M, base, (n * dir_n + d * dir_d).normalized(), ATRAS * 0.35, largo_ * rnd.uniform(0.9, 1.1),
                             grueso_, max(3, lados - 2), hueso, n_seg=2, rnd=rnd, etiqueta="mand_" + nombre, hundido=0.1)
        # v5, 2.ª vuelta: la PIEL que une la mandíbula con la boca (por fuera, el belfo desde el canto de bronce; por
        # dentro, la encía desde el anillo de la boca): de la cabeza a la mandíbula, con los pesos repartidos, se estira
        # al abrir y se recoge al cerrar. Así ninguna mandíbula se ve despegada desde ninguna cámara.
        _union_mandibula(M, k)
        M.etiqueta = "mand_" + nombre
        # los colmillos (se despliegan con su hueso)
        n_col = min(n_col, Q["colm_max"])
        for q in range(n_col):
            u = -0.72 + 1.44 * q / max(1, n_col - 1)
            base = mandibula_punto(k, u, V_COLM, 0) + n * BASE_COLM
            dirc = DIR_COLM(n, d)
            curva = ATRAS * 0.4 - t * u * 0.12
            diente_curvo(M, base, dirc, curva, l_col * rnd.uniform(0.94, 1.06), 0.15 * (l_col / 0.78), lados,
                         "colm_" + nombre, n_seg=4 if Q["dientes"] >= 1 else 2, rnd=rnd, etiqueta="colm_" + nombre,
                         hundido=0.16, punta_clara=0.45)


def _anillo_cabeza(a, cual):
    """v5, 2.ª vuelta: un punto del borde de la boca, fijo a la cabeza, al ángulo a: «fuera», sobre la cáscara, detrás
    del collar (el belfo envuelve el canto y llega a la coraza de la mandíbula: de cualquier lado se ve unida);
    «dentro», el último rodete del collar antes de los labios; «hueco», el canto del collar entre dos mandíbulas."""
    if cual == "fuera":
        p, n_ = sup_cabeza(a, YF + 0.22)
        return p + n_ * 0.06
    if cual == "hueco":
        return Vector(((R_LABIO + 0.15) * math.sin(a), YF - 0.17, (R_LABIO + 0.15) * math.cos(a)))
    return Vector(((R_LABIO + 0.06) * math.sin(a), YF - 0.14, (R_LABIO + 0.06) * math.cos(a)))


def _apuntar_union(M, i, j):
    if not hasattr(M, "aristas_union"):
        M.aristas_union = []
    M.aristas_union.append((i, j))


def _tira_union(M, borde_cabeza, borde_mand, pesos_cabeza, pesos_mand, filas, hinchar, col_a, col_b, uv_v, hacia, ancla=None):
    """Una tira de piel entre dos bordes (listas de puntos del mismo largo): «filas» filas intermedias, cada una con los
    pesos repartidos entre los de un borde y los del otro, e hinchada «hinchar» (vector por columna) en medio."""
    n_c = len(borde_cabeza)
    rejas = []
    for s_i in range(filas + 2):
        s = s_i / (filas + 1)
        fila = []
        for c in range(n_c):
            p = borde_cabeza[c].lerp(borde_mand[c], s) + hinchar[c] * math.sin(math.pi * s)
            pe = {}
            for h, w_ in pesos_cabeza[c].items():
                pe[h] = pe.get(h, 0.0) + w_ * (1.0 - s)
            for h, w_ in pesos_mand[c].items():
                pe[h] = pe.get(h, 0.0) + w_ * s
            if ancla is not None and ancla[c] > 0.0:          # entre dos mandíbulas: el medio, sujeto también a la cabeza
                k_ = ancla[c] * math.sin(math.pi * s)
                pe = {h: w_ * (1.0 - k_) for h, w_ in pe.items()}
                pe["cabeza"] = pe.get("cabeza", 0.0) + k_
            pe = {h: w_ for h, w_ in pe.items() if w_ > 1e-4}
            fila.append(M.vert(p, C(mezcla(col_a, col_b, s), 0.75 + 0.25 * math.sin(math.pi * s), 0.15 * (1 - s)),
                               en_atlas(AT_CARNE, c / max(1, n_c - 1), uv_v + 0.25 * s), pe))
        rejas.append(fila)
    for s_i in range(len(rejas) - 1):
        for c in range(n_c):
            _apuntar_union(M, rejas[s_i][c], rejas[s_i + 1][c])
    antes = len(M.caras)
    rejilla(M, rejas, PIEL)
    for q in range(antes, len(M.caras)):                       # cada cara mirando hacia fuera de la boca
        idx = M.caras[q]
        pts = [M.v[i] for i in idx]
        nrm = (pts[1] - pts[0]).cross(pts[2] - pts[0])
        cen = sum(pts, Vector()) / len(pts)
        if nrm.dot(hacia(cen)) < 0:
            M.caras[q] = tuple(idx[::-1])
    # por las dos caras (se ve desde dentro de la boca y desde fuera): la de atrás con vértices propios, para que la
    # normal suave no se anule (la primera prueba, de una cara, se veía hueca desde dentro con el descarte de caras)
    copias = {}
    for q in range(antes, len(M.caras)):
        idx = M.caras[q]
        nuevo = []
        for i in idx[::-1]:
            if i not in copias:
                copias[i] = M.vert(M.v[i], tuple(x * 0.8 for x in M.col[i][:3]) + tuple(M.col[i][3:]), M.uv[i], M.pesos[i])
            nuevo.append(copias[i])
        M.caras.append(tuple(nuevo))
        M.mats.append(PIEL)
        M.etq.append(M.etiqueta)
    return rejas


V_UNION = 0.3                                   # v5, 2.ª vuelta: hasta dónde llega la piel sobre la mandíbula


def _union_mandibula(M, k):
    """v5, 2.ª vuelta: el BELFO (por fuera, carne y bronce, del canto del collar a la coraza de la mandíbula) y la
    ENCÍA (por dentro, del rodete de la boca a la encía de la mandíbula) de la mandíbula k."""
    nombre = MANDIBULAS[k][0]
    hueso = "mand_" + nombre
    H, t, d, n = marco_mandibula(k)
    nu = (Q["mand_uv"] or (max(3, Q["pl_u"] + 2), 0))[0]
    us = [-1.0 + 2.0 * i / nu for i in range(nu + 1)]
    for (cual, cara, col_a, col_b, uv_v) in (("fuera", 1, mezcla(CARNE, BRONCE, 0.35), CARNE, 0.55),
                                             ("dentro", 0, ENCIA, mezcla(ENCIA, CARNE, 0.4), 0.3)):
        M.etiqueta = "union_" + nombre
        b_mand = [mandibula_punto(k, u, V_UNION, cara) for u in us]
        b_cab = []
        for u in us:
            p0 = mandibula_punto(k, u, 0.0, 1)
            b_cab.append(_anillo_cabeza(math.atan2(p0.x, p0.z), cual))
        sentido = -1.0 if cual == "fuera" else 1.0
        hinchar = [(Vector((p.x, 0.0, p.z)).normalized() * (0.14 if cual == "fuera" else 0.07) * (-sentido) + ADELANTE * 0.05)
                   for p in b_mand]
        _tira_union(M, b_cab, b_mand, [{"cabeza": 1.0}] * len(us), [{hueso: 1.0}] * len(us), Q["union"], hinchar,
                    col_a, col_b, uv_v, (lambda c: -n) if cual == "fuera" else (lambda c: n))
    if not hasattr(M, "uniones_de"):
        M.uniones_de = {}
    M.uniones_de["union_" + nombre] = {hueso}


def crear_mejillas(M):
    """v5, 2.ª vuelta: las MEJILLAS de carne entre cada par de mandíbulas vecinas (de los cantos de una a los de la otra,
    con los pesos repartidos entre las dos) y, detrás, la piel que las cose al canto del collar. La boca es una sola
    piel continua: abiertas, la carne se estira entre las mandíbulas como en la lámina; cerradas, se recoge."""
    if not hasattr(M, "uniones_de"):
        M.uniones_de = {}
    nk = len(MANDIBULAS)
    filas_v = max(2, Q["union"] + 1)
    vs = [0.62 * i / filas_v for i in range(filas_v + 1)]

    def lado(kk, objetivo):                       # el canto de la mandíbula kk que mira hacia el ángulo «objetivo»
        mejor = None
        for s in (-1.0, 1.0):
            p = mandibula_punto(kk, s, 0.0, 1)
            a = math.atan2(p.x, p.z)
            dif = abs(math.atan2(math.sin(a - objetivo), math.cos(a - objetivo)))
            if mejor is None or dif < mejor[0]:
                mejor = (dif, s)
        return mejor[1]
    for k in range(nk):
        k2 = (k + 1) % nk
        a1, a2 = MANDIBULAS[k][0], MANDIBULAS[k2][0]
        s1 = lado(k, math.radians(MANDIBULAS[k2][1]))
        s2 = lado(k2, math.radians(MANDIBULAS[k][1]))
        etq = "mejilla_%s_%s" % (a1, a2)
        M.etiqueta = etq
        borde1 = [mandibula_punto(k, s1, v, 1) for v in vs]
        borde2 = [mandibula_punto(k2, s2, v, 1) for v in vs]
        medio_a = math.atan2((borde1[0] + borde2[0]).x, (borde1[0] + borde2[0]).z)
        fuera_ = Vector((math.sin(medio_a), 0.0, math.cos(medio_a)))
        _tira_union(M, borde1, borde2, [{"mand_" + a1: 1.0}] * len(vs), [{"mand_" + a2: 1.0}] * len(vs),
                    max(1, Q["union"]), [fuera_ * 0.3] * len(vs), CARNE, CARNE, 0.6, lambda c, f_=fuera_: f_,
                    ancla=[0.95 * (1.0 - v / 0.62) ** 1.2 for v in vs])
        # detrás: del canto de bronce del collar (de una bisagra a la otra) a la primera fila de la mejilla
        n_c = max(2, Q["union"] + 1)
        p_a = mandibula_punto(k, s1, 0.0, 1)
        p_b = mandibula_punto(k2, s2, 0.0, 1)
        fila_mej = [p_a.lerp(p_b, c / n_c) + fuera_ * 0.16 * math.sin(math.pi * c / n_c) * 0.0 for c in range(n_c + 1)]
        a_a, a_b = math.atan2(p_a.x, p_a.z), math.atan2(p_b.x, p_b.z)
        if a_b < a_a - math.pi:
            a_b += 2 * math.pi
        if a_b > a_a + math.pi:
            a_b -= 2 * math.pi
        fila_cab = [_anillo_cabeza(a_a + (a_b - a_a) * c / n_c, "hueco") for c in range(n_c + 1)]
        pes_m = []
        for c in range(n_c + 1):                     # el medio de la fila, sujeto también a la cabeza
            k_ = math.sin(math.pi * c / n_c) ** 0.5
            pes_m.append({"mand_" + a1: (1.0 - c / n_c) * (1 - k_), "mand_" + a2: (c / n_c) * (1 - k_), "cabeza": k_})
        _tira_union(M, fila_cab, fila_mej, [{"cabeza": 1.0}] * (n_c + 1), pes_m, 1, [fuera_ * 0.05] * (n_c + 1),
                    mezcla(CARNE, BRONCE, 0.35), CARNE, 0.5, lambda c, f_=fuera_: f_)
        M.uniones_de[etq] = {"mand_" + a1, "mand_" + a2}


def crear_cejas(M):
    """v5, 2.ª vuelta: las CEJAS óseas de la lámina: dos arcos de hueso gruesos sobre la boca, de encima de la mandíbula
    de arriba hacia los lados, que suben hasta la base de los cuernos (los cuernos nacen de ellas). Fijas (cabeza)."""
    if not Q["cejas"]:                            # (el bajo, sin ellas: presupuesto; de lejos no se distinguen)
        return
    M.etiqueta = "craneo"
    nl = max(4, Q["cuerno_lados"])
    pasos = 7 if Q["cab_placas"] >= 1 else 4
    for sx in (-1, 1):
        cen = []
        for q in range(pasos + 1):
            s = q / pasos
            a = sx * (0.16 + 1.05 * s)
            y = (YF + 0.62) + ((-0.95) - (YF + 0.62)) * s ** 0.8     # (empieza detrás del belfo de arriba)
            p, nrm = sup_cabeza(a, y)
            cen.append((p + nrm * (0.1 + 0.16 * math.sin(math.pi * s)), nrm, 0.3 * (1.0 - 0.45 * s) + 0.06))
        anillos = []
        for q, (c, nrm, r) in enumerate(cen):
            tg = (cen[min(q + 1, pasos)][0] - cen[max(q - 1, 0)][0]).normalized()
            u = tg.cross(nrm).normalized()
            w = tg.cross(u).normalized()
            fila = []
            for i in range(nl):
                ph = 2 * math.pi * i / nl
                fila.append(M.vert(c + (u * math.cos(ph) * 0.8 + w * math.sin(ph)) * r,
                                   C(mezcla(ARMADURA_OSC, BRONCE, 0.35 * (i % 2)), 0.85, 1.0),
                                   en_atlas(AT_CABEZA, i / nl, 0.2 + 0.6 * q / pasos), "cabeza"))
            anillos.append(fila)
        ejes = [c for (c, _, _) in cen]
        rejilla(M, anillos, PIEL, cerrar_u=True, fuera=lambda c, e=ejes: min(e, key=lambda z: (z - c).length))
        for (fila, c, otro) in ((anillos[0], ejes[0], ejes[1]), (anillos[-1], ejes[-1], ejes[-2])):
            tapa = M.vert(c + (c - otro).normalized() * 0.12, C(BRONCE, 0.9, 1.0), en_atlas(AT_CABEZA, 0.5, 0.5), "cabeza")
            antes = len(M.caras)
            for i in range(nl):
                M.cara((fila[i], fila[(i + 1) % nl], tapa), PIEL)
            _orientar_ultimas(M, len(M.caras) - antes, c - otro)


def _orientar_ultimas(M, cuantas, hacia):
    """Da la vuelta a las últimas «cuantas» caras cuya normal no mira hacia «hacia» (un vector)."""
    for q in range(len(M.caras) - cuantas, len(M.caras)):
        idx = M.caras[q]
        pts = [M.v[i] for i in idx]
        nrm = (pts[1] - pts[0]).cross(pts[2] - pts[0])
        if len(pts) == 4 and nrm.length < 1e-9:
            nrm = (pts[2] - pts[0]).cross(pts[3] - pts[0])
        if nrm.dot(hacia) < 0:
            M.caras[q] = tuple(idx[::-1])


def placas_cabeza(M):
    """Placas de la cabeza, como tejas hacia el collar: dos anillos (dorsal y laterales) y las mejillas."""
    rnd = random.Random(808)
    nu, nv = Q["pl_u"], Q["pl_v"]
    pes = lambda a, s: peso_cabeza(-s)                    # (s = −y: ver sup)
    sup = lambda a, s: sup_cabeza(a, -s)                  # (escudo avanza en s hacia atrás: aquí, hacia la nuca)
    M.etiqueta = "craneo"
    for (y0, y1) in ((1.05, 0.0), (0.15, -1.25)):
        escudo(M, sup, -0.8, 0.8, -y0, -y1 + 0.2, nu + 1, nv, 0.09, 0.03, 0.14, 0.35, 0.5, pes, uv_loseta(rnd.randrange(15)),
               eje=lambda q: (0.0, q.y, 0.0))
        if Q["cab_placas"] >= 0.5:
            for lado in (1, -1):
                a0, a1 = (0.72, 2.0) if lado > 0 else (-2.0, -0.72)
                escudo(M, sup, a0, a1, -y0 + 0.05, -y1 + 0.05, nu, nv, 0.08, 0.02, 0.1, 0.3, 0.8 if lado > 0 else 0.2,
                       pes, uv_loseta(rnd.randrange(15)), eje=lambda q: (0.0, q.y, 0.0))
    # la testera: la placa en rombo de la frente, con el núcleo ámbar (loseta 15: runas que nacen de él)
    escudo(M, sup, -0.68, 0.68, 0.0, 1.6, nu + 1, nv + 1, 0.26, 0.0, 0.08, 0.4, 0.5, pes, uv_loseta(15),   # v5: acaba antes de la boca
           eje=lambda q: (0.0, q.y, 0.0), estrecha=lambda v: 0.3 + 0.7 * math.sin(math.pi * min(1.0, v * 0.85 + 0.12)) ** 0.7)


def crear_nucleo(M):
    """El núcleo ámbar de la frente: una gema facetada en un engaste de bronce (brilla con «brillo»)."""
    M.etiqueta = "craneo"
    y0 = -1.55
    p, n = sup_cabeza(0.0, y0)
    c = p + n * 0.52
    t1 = Vector((1.0, 0.0, 0.0))
    t2 = n.cross(t1).normalized()
    m = 10 if Q["dientes"] >= 1 else 6
    engaste = [M.vert(c + (t1 * math.cos(2 * math.pi * i / m) + t2 * math.sin(2 * math.pi * i / m) * 1.25) * 0.52 - n * 0.1,
                      C(BRONCE, 0.85, 1.0), en_atlas(AT_CABEZA, i / m, 0.5), "cabeza") for i in range(m)]
    borde = [M.vert(c + (t1 * math.cos(2 * math.pi * i / m) + t2 * math.sin(2 * math.pi * i / m) * 1.25) * 0.42 + n * 0.08,
                    C(BRONCE, 1.0, 1.0), en_atlas(AT_CABEZA, i / m, 0.55), "cabeza") for i in range(m)]
    gema = [M.vert(c + (t1 * math.cos(2 * math.pi * (i + 0.5) / m) + t2 * math.sin(2 * math.pi * (i + 0.5) / m) * 1.25) * 0.36 + n * 0.14,
                   mezcla(AMBAR_HONDO, AMBAR, 0.7), neutro(), "cabeza") for i in range(m)]
    cima = M.vert(c + n * 0.4, mezcla(AMBAR, (1.0, 0.95, 0.8), 0.6), neutro(), "cabeza")
    dentro = lambda q: c - n * 0.6
    for i in range(m):
        M.cara((engaste[i], engaste[(i + 1) % m], borde[(i + 1) % m], borde[i]), PIEL, fuera=dentro)
        M.cara((borde[i], borde[(i + 1) % m], gema[i]), VIDRIO, fuera=dentro)
    for i in range(m):
        M.cara((borde[(i + 1) % m], gema[(i + 1) % m], gema[i]), VIDRIO, fuera=dentro)
        M.cara((gema[i], gema[(i + 1) % m], cima), VIDRIO, fuera=dentro)


def cuerno(M, base, dir_, curva, largo, grueso, lados, rnd, n_seg=None):
    """v5: un cuerno de la corona, CURVO (cinco anillos a lo largo de la curva; la v4 tenía tres y se leía recto):
    hueso claro con la base de bronce."""
    n_seg = Q["cuerno_seg"] if n_seg is None else min(n_seg, Q["cuerno_seg"])
    return diente_curvo(M, base, dir_, curva, largo, grueso, lados, "cabeza", n_seg=n_seg,
                        color=mezcla(ARMADURA, BRONCE, 0.3), rnd=rnd, mineral=1.0, etiqueta="cuerno", hundido=0.18,
                        punta_clara=0.3)


# v5: los extremos de la corona en la pose de enlace (Blender), para el encuadre (que no se salgan de la pantalla): las
# puntas de los cuernos y lo alto de la cresta. Se rellenan al construir el alto y van al JSON (en el sistema de Godot).
PUNTAS_CORONA = []


def crear_corona(M):
    """La corona de la lámina (v5: más gruesa y curvada, con la cresta central): dos cuernos grandes arriba que se
    abren y se curvan hacia atrás, dos medianos a los lados, dos pequeños atrás, y entre los grandes una CRESTA en punta
    sobre el núcleo; y el marco de placas en punta en los cuatro huecos entre las mandíbulas (fijas)."""
    rnd = random.Random(5)
    nl = Q["cuerno_lados"]
    guardar = not PUNTAS_CORONA
    for sx in (-1, 1):
        p, n = sup_cabeza(sx * 0.62, -0.75)
        f_ = cuerno(M, p - n * 0.2, Vector((sx * 0.7, 0.05, 1.0)), Vector((sx * 0.35, 1.0, -0.45)), 3.0, 0.6, nl + 1, rnd)
        if guardar:
            PUNTAS_CORONA.append(f_(1.0))
        p, n = sup_cabeza(sx * 1.3, -1.1)
        f_ = cuerno(M, p - n * 0.12, Vector((sx * 1.0, 0.0, 0.55)), Vector((sx * 0.05, 0.8, 0.6)), 2.2, 0.44, nl, rnd)
        if guardar:
            PUNTAS_CORONA.append(f_(1.0))
        p, n = sup_cabeza(sx * 0.3, 0.45)
        cuerno(M, p - n * 0.05, Vector((sx * 0.25, 0.9, 0.75)), Vector((0.0, 0.6, -0.3)), 1.0, 0.2, max(4, nl - 2), rnd, n_seg=3)
        if Q["cab_placas"] >= 0.5:
            p, n = sup_cabeza(sx * 1.95, -1.3)
            cuerno(M, p - n * 0.05, Vector((sx * 1.0, 0.35, -0.5)), Vector((0.0, 0.9, 0.1)), 1.1, 0.2, max(4, nl - 2), rnd, n_seg=3)
    # la cresta central: una hoja de hueso en punta, de canto, sobre el núcleo (la lámina, vista de frente)
    p, n = sup_cabeza(0.0, -0.55)
    f_ = cuerno(M, p - n * 0.15, Vector((0.0, -0.35, 1.0)), Vector((0.0, 1.1, -0.2)), 1.7, 0.42, 4, rnd, n_seg=4)
    if guardar:
        PUNTAS_CORONA.append(f_(1.0))
    # el marco: placas en punta en los huecos entre mandíbulas, que apuntan afuera y adelante (lámina, vista de frente)
    M.etiqueta = "marco"
    for (ang, largo) in (((45, 1.15), (135, 1.0), (-135, 1.0), (-45, 1.15)) if Q["cab_placas"] >= 0.5 else ()):
        a = math.radians(ang)
        marco(M, a, largo)


def marco(M, a, largo):
    """Una placa del marco de la boca: una hoja gruesa y curvada sobre la cáscara, del costado de la cabeza hacia el
    collar, que acaba en punta hacia fuera y adelante (más allá del plano de la boca, sin tocar los labios). v5: más
    estrecha (va entre dos mandíbulas)."""
    nv = 4 if Q["dientes"] >= 1 else 2
    ancho = 0.85
    uvf = uv_loseta(int(abs(math.degrees(a))) % 15)
    secciones = []
    for q in range(nv + 1):
        v = q / nv
        y = -1.45 + (YF + 0.5 - (-1.45)) * v            # v5, 2.ª vuelta: acaba antes del collar (delante van las mejillas)
        p, n = sup_cabeza(a, max(y, YF))
        rr = r_cab(max(y, YF)) + 0.05 + 0.6 * largo * v ** 2
        cen = Vector((rr * math.sin(a), y, rr * math.cos(a)))
        lat = Vector((math.cos(a), 0.0, -math.sin(a)))
        w = ancho * (1 - v) ** 0.9 + 0.03
        g = 0.22 * (1 - v) + 0.04
        tono = (1.0, 1.0, 1.0)
        secciones.append([M.vert(cen + lat * w - e_r(a) * 0.02, C(tono, 0.8, 1.0), uvf(0.0, v), "cabeza"),
                          M.vert(cen + e_r(a) * g, C(tono, 1.0, 1.0), uvf(0.5, v), "cabeza"),
                          M.vert(cen - lat * w - e_r(a) * 0.02, C(tono, 0.8, 1.0), uvf(1.0, v), "cabeza"),
                          M.vert(cen - e_r(a) * (g + 0.08), C(tono, 0.5, 1.0), uvf(0.5, v), "cabeza")])
    centros = [sum((M.v[i] for i in s_), Vector()) / 4 for s_ in secciones]
    rejilla(M, secciones, PIEL, cerrar_u=True, fuera=lambda c: min(centros, key=lambda z: (z - c).length))
    tip = M.vert(sum((M.v[i] for i in secciones[-1]), Vector()) / 4 + Vector((math.sin(a), -0.6, math.cos(a))) * 0.25,
                 C(BRONCE, 1.0, 1.0), en_atlas(AT_CABEZA, 0.5, 1.0), "cabeza")
    for i in range(4):
        M.cara((secciones[-1][i], secciones[-1][(i + 1) % 4], tip), PIEL,
               fuera=lambda c: sum((M.v[j] for j in secciones[-2]), Vector()) / 4)
    M.cara(tuple(secciones[0][::-1]), PIEL, fuera=lambda c: sum((M.v[j] for j in secciones[1]), Vector()) / 4)


# ---------------------------------------------------------------- (copia literal de crear_bramavidrio3.py)

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

# ---------------------------------------------------------------- v4: el chorro (desde la garganta) y la succión

def P_ANCLA():
    return Vector((0.0, ANCLA_Y, 0.0))


def crear_chorro(M):
    """El chorro 3D del Aliento NACE EN LA GARGANTA: un haz que sale del anclaje (al fondo del embudo), atraviesa el
    embudo por el eje (más estrecho que él: no cruza dientes ni labios) y se abre al salir por la boca. Va con el hueso
    «chorro» (cabeza en el anclaje: al escalarlo crece desde la garganta). Lo de fuera hacia los héroes lo dibuja el
    combate (combate_bramavidrio.gd) desde la proyección de ese mismo anclaje."""
    M.etiqueta = "chorro"
    n = Q["chorro"]
    base = P_ANCLA()
    for capa, pasos, giro in ((0, [(0.0, 0.12, 0.9), (0.35, 0.2, 1.0), (0.75, 0.32, 1.0), (1.0, 0.6, 0.85), (1.25, 1.05, 0.0)], 0.0),
                              (1, [(0.0, 0.06, 1.0), (0.5, 0.12, 1.0), (1.0, 0.3, 0.6), (1.2, 0.5, 0.0)], 0.3)):
        anillos = []
        for (t, r, al) in pasos:
            fila = []
            for i in range(n + 1):
                ang = 2 * math.pi * i / n + giro
                p = base + Vector((math.sin(ang) * r, -t * (ANCLA_Y - YF), math.cos(ang) * r))
                fila.append(M.vert(p, (1.0, 0.82, 0.5, al) if capa == 0 else (1.0, 0.95, 0.78, al), (i / n, t), "chorro"))
            anillos.append(fila)
        rejilla(M, anillos, CHORRO, fuera=lambda c: (0.0, c.y, 0.0))


def crear_succion(M):
    """La arena que aspira: cintas que nacen anchas y separadas por delante y abajo y se juntan DENTRO de la boca, en la
    entrada del embudo (hueso «succion»; escondidas con escala 0,01). El alfa del color de vértice es su fuerza."""
    M.etiqueta = "succion"
    n = Q["succion"]
    boca = Vector((0.0, YF + D_ENTRADA + 0.2, 0.0))
    rnd = random.Random(13)
    for k in range(n):
        a = 2 * math.pi * k / n + rnd.uniform(-0.2, 0.2)
        lejos = boca + Vector((math.sin(a) * rnd.uniform(3.0, 4.6), -rnd.uniform(5.5, 8.5), -rnd.uniform(3.5, 6.0) + math.cos(a) * 1.5))
        pts = [lejos.lerp(boca, j / 4) + Vector((math.sin(a + 1.5) * 0.8, 0.0, 0.0)) * math.sin(math.pi * j / 4) for j in range(5)]
        filas = []
        for j, p in enumerate(pts):
            t = j / 4
            ancho = 0.42 * (1 - t) + 0.06
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
    crear_armadura_cuerpo(M)
    crear_crestas(M)
    crear_cabeza(M)
    placas_cabeza(M)
    crear_nucleo(M)
    crear_corona(M)
    crear_dientes(M)
    crear_mandibulas(M)
    crear_mejillas(M)                   # v5, 2.ª vuelta: la piel entre mandíbulas
    crear_cejas(M)                      # v5, 2.ª vuelta: las cejas óseas
    M.etiqueta = "suelo"
    crear_monticulo(M)
    crear_losas(M)
    crear_chorro(M)
    crear_succion(M)
    return M


# ---------------------------------------------------------------- esqueleto (v4: esfínter, 12 sectores y el anclaje)

C_ESF = Vector((0.0, YF + D_ENTRADA, 0.0))       # la cabeza del hueso esfinter: el centro de la entrada del embudo


def huesos():
    hs = [("raiz", (0, 0, 0), (0, 0, 1.0), None)]
    for i in range(NSEG, 0, -1):
        hs.append((col_nombre(i), (0, i * LSEG, 0), (0, (i - 1) * LSEG, 0), "raiz" if i == NSEG else col_nombre(i + 1)))
    hs += [("cabeza", (0, 0, 0), (0, YF * 0.75, 0), "col_01"),
           ("esfinter", tuple(C_ESF), tuple(C_ESF + ADELANTE), "cabeza"),
           ("garganta", (0, ANCLA_Y + 0.4, 0), (0, ANCLA_Y - 0.1, 0), "cabeza"),
           ("garganta_ancla", tuple(P_ANCLA()), tuple(P_ANCLA() + ADELANTE), "cabeza"),
           ("chorro", tuple(P_ANCLA()), tuple(P_ANCLA() + ADELANTE), "cabeza"),
           ("succion", (0, YF + D_ENTRADA + 0.2, 0), (0, YF + D_ENTRADA - 0.8, 0), "cabeza"),
           ("brillo", (0, 0, -1.0), (0, 0, -0.5), "raiz"),
           ("monticulo", (0, 0, 0), (0, 0, 0.4), "raiz")]
    for k, m in enumerate(MANDIBULAS):                   # v5: las mandíbulas y, hijas suyas, sus filas de colmillos
        H, t, d, n = marco_mandibula(k)
        hs.append(("mand_" + m[0], tuple(H), tuple(H + d * 0.8), "cabeza"))
        b = base_colm(k)
        hs.append(("colm_" + m[0], tuple(b), tuple(b + DIR_COLM(n, d) * 0.5), "mand_" + m[0]))
    for i in ALETAS:
        sm = (i - 0.5) * LSEG
        rt = radio(sm) * 0.95
        hs.append((placa_nombre(i), (0, sm, rt), (0, sm, rt + 0.6), col_nombre(i)))
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


# ---------------------------------------------------------------- (copia literal de crear_bramavidrio3.py)

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
                 ceja=4.0, ancla=(1.0, 1.0), mm=PLANTA, ml=SIN_DESVIO, garra=GARRA_SUELO, colm=None):
        self.colm = colm                       # v5: colmillos (0 plegados, 1 desplegados, 1,15 erizados); None: según la boca
        self.mand_k = {}                       # v5: grados de más (o de menos) de cada mandíbula (0..3): retraso y temblor
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
                 self.losas, self.ceja, self.ancla.copy(), self.mm.copy(), self.ml.copy(), self.garra.copy(), self.colm)
        p.losas_k = dict(self.losas_k)
        p.mand_k = dict(self.mand_k)
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
    ks = set(a.mand_k) | set(b.mand_k)
    p.mand_k = {k: a.mand_k.get(k, 0.0) * (1 - t) + b.mand_k.get(k, 0.0) * t for k in ks}
    p.colm = colmillos_de(a) * (1 - t) + colmillos_de(b) * t
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

# ---------------------------------------------------------------- v4: la boca (esfínter y sectores)

def apertura(boca):
    """«boca» (grados nominales, como la mandíbula de las versiones anteriores) → apertura a: 0 cerrada, 1 la pose de
    enlace (abierta como en la lámina), hasta 1,12 (rugido: se abre de más)."""
    return max(0.0, min(1.12, boca / BOCA_ABIERTA))


def esfinter_estado(a):
    """La escala radial del esfínter y cuánto avanza (m) para la apertura a."""
    if a >= 1.0:
        return a, -0.15 * min(1.0, (a - 1.0) / 0.12)
    return max(S_MIN, a), T_CIERRE * (1.0 - a)


def M_esfinter(a):
    """Su transformación en el espacio de la cabeza en reposo (escala en el plano de la boca alrededor de su eje y avance)."""
    s, t = esfinter_estado(a)
    return Matrix.Translation(C_ESF + ADELANTE * t) @ Matrix.Diagonal((s, 1.0, s, 1.0)) @ Matrix.Translation(-C_ESF)


def labio_en(p, w, a):
    """Dónde va un punto de los labios (en reposo p, peso del esfínter w) con la apertura a (mezcla lineal de la piel)."""
    return p * (1.0 - w) + (M_esfinter(a) @ p) * w


def beta_mandibula(a):
    """v5: hacia dónde apunta la mandíbula (grados desde delante; + hacia fuera) para la apertura a."""
    if a >= 1.0:
        return BETA_ABIERTA + BETA_DE_MAS * min(1.0, (a - 1.0) / 0.12)
    return BETA_CERRADA + (BETA_ABIERTA - BETA_CERRADA) * a


def colmillos_de(p):
    """v5: los colmillos de la pose (si no se dicen, se despliegan al abrir la boca: plegados con ella cerrada)."""
    if p.colm is not None:
        return float(p.colm)
    return ease(apertura(p.boca) / 0.6)


def M_mandibula(k, a, extra=0.0):
    """v5: la mandíbula k en el espacio de la cabeza en reposo: gira sobre su bisagra (el eje t por H) de la pose de
    enlace (abierta) a la de la apertura a; «extra», grados de más hacia fuera."""
    H, t, d, n = marco_mandibula(k)
    giro = math.radians(BETA_ABIERTA - beta_mandibula(a) - extra)      # > 0: cierra (d hacia n: giro negativo sobre t)
    return Matrix.Translation(H) @ Matrix.Rotation(-giro, 4, t) @ Matrix.Translation(-H)


def base_colm(k):
    return mandibula_punto(k, 0.0, V_COLM, 0) + marco_mandibula(k)[3] * BASE_COLM


def M_colmillos(k, c):
    """v5: la fila de colmillos de la mandíbula k (relativa a ella, en reposo): desplegados (c = 1, la pose de enlace)
    apuntan al eje de la boca; plegados (c = 0) se tumban PLIEGUE grados hacia la punta de la mandíbula; erizados
    (c > 1) se abren de más."""
    H, t, d, n = marco_mandibula(k)
    b = base_colm(k) + n * ALTO_PIVOTE
    giro = -math.radians(PLIEGUE * (1.0 - c))                           # < 0: d hacia n (se tumban hacia la garganta)
    return Matrix.Translation(b) @ Matrix.Rotation(giro, 4, t) @ Matrix.Translation(-b)


def _local(b, M_rest):
    """Una transformación del espacio de la armadura en reposo, como pose del hueso b (relativa a su padre «cabeza»)."""
    return b.matrix_local.inverted() @ M_rest @ b.matrix_local


def bases(arm, p):
    G, P = matrices_globales(arm, p)
    bones = arm.data.bones
    a = apertura(p.boca)
    B = {}
    for b in bones:
        n = b.name
        if n in G:
            par_ = b.parent
            gp = G.get(par_.name, par_.matrix_local) if par_ else Matrix.Identity(4)
            resto = (par_.matrix_local.inverted() @ b.matrix_local) if par_ else b.matrix_local
            B[n] = resto.inverted() @ gp.inverted() @ G[n]
        elif n == "esfinter":
            B[n] = _local(b, M_esfinter(a))
        elif n.startswith("mand_"):                       # v5: las mandíbulas (hijas de la cabeza)
            k = [m[0] for m in MANDIBULAS].index(n[5:])
            B[n] = _local(b, M_mandibula(k, a, p.mand_k.get(k, 0.0)))
        elif n.startswith("colm_"):                       # v5: los colmillos (hijos de su mandíbula)
            k = [m[0] for m in MANDIBULAS].index(n[5:])
            B[n] = _local(b, M_colmillos(k, colmillos_de(p)))
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
            B[n] = Matrix.Identity(4)                         # garganta_ancla: va con la cabeza
    return B, G, P


def medir_signos(arm):
    """Qué signo eriza las crestas (hacia la cabeza)."""
    b = arm.data.bones[placa_nombre(ALETAS[0])]
    punta = (b.matrix_local @ Matrix.Rotation(0.3, 4, 'X')) @ Vector((0, b.length, 0))
    SIGNO["placa"] = 1.0 if punta.y < b.tail_local.y else -1.0
    print("SIGNOS", SIGNO)


def poner_pose(arm, p):
    B, G, P = bases(arm, p)
    for pb in arm.pose.bones:
        loc, rot, esc = B[pb.name].decompose()
        pb.location, pb.rotation_quaternion, pb.scale = loc, rot, esc
    return G, P


# Puntos de la cabeza en la pose de enlace (Blender)
def P_HOCICO():
    return Vector((0.0, YF - 0.85, 0.0))                 # v5: lo de más delante: la punta del hocico que forman las
#                                                          mandíbulas cerradas (v4: YF − 0,2, los labios)


def P_BARBILLA():
    return Vector((0.0, YF - 0.05, -(R_LABIO + 0.12)))    # lo de abajo del collar, delante


def P_MAND_BAJO():
    return Vector((0.0, -1.3, -r_cab(-1.3) * 0.95))       # el vientre de la cabeza


def P_BOCA():
    return Vector((0.0, YF, 0.0))                         # el centro de la boca, en su plano


def P_GARGANTA():
    return P_ANCLA()


def a_godot(v):
    return [round(v.x, 3), round(v.z, 3), round(-v.y, 3)]


def mundo_de(arm, G, B, hueso, p_reposo):
    b = arm.data.bones[hueso]
    return G[hueso] @ (b.matrix_local.inverted() @ p_reposo)


def mundo_cabeza(arm, G, M_rest, p):
    """Un punto de la cabeza transformado en reposo por M_rest (esfínter o sector) y luego por la pose de la cabeza."""
    b = arm.data.bones["cabeza"]
    return G["cabeza"] @ (b.matrix_local.inverted() @ (M_rest @ p))


# ---------------------------------------------------------------- (copia literal de crear_bramavidrio3.py)

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


def ondas(p, t, T, amp=3.0, largo=8.0):
    for k in ALETAS:
        p.placas_k[k] = p.placas_k.get(k, 0.0) + amp * math.sin(2 * math.pi * (k * LSEG / largo - t / T))

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

# ---------------------------------------------------------------- v5: movimiento orgánico (herramientas)
#
# SEGUIMIENTO Y SUPERPOSICIÓN. Cada clip se describe con poses clave (tramos) más sus modulaciones (temblores, ondas),
# como una función del tiempo; retardar() evalúa la COLUMNA con un adelanto distinto en cada tramo: con adelanto > 0 la
# base (junto al agujero) va por delante en el tiempo y la cabeza llega después, con la inercia de un látigo (la
# embestida, la emersión, la caída de la Fractura); con < 0 el movimiento nace en la cabeza y baja hacia la cola (el
# golpe recibido, el rebote tras un impacto). La cabeza siempre va a su hora (adelanto 0 en la nuca): los instantes del
# contrato (impacto, caída…) no se mueven. Las crestas van un poco más tarde que su tramo (superposición).


def perfil_base(u_ancla):
    """Cuánto pesa el adelanto en cada punto de la columna: 0 en la nuca, 1 en el agujero (y lo enterrado)."""
    return np.clip(np.maximum(U, 0.0) / max(u_ancla, 1.0), 0.0, 1.0) ** 0.85


def retardar(fn, t, D, adelanto, retraso_crestas=0.07, ua_cabeza=False):
    """v5: la pose del instante t con la columna retrasada o adelantada tramo a tramo. fn(t) da la pose «clave» (con t
    entre 0 y D); adelanto, un array (segundos por punto de U, 0 en la nuca)."""
    cab = fn(min(D, max(0.0, t)))
    a_min, a_max = float(adelanto.min()), float(adelanto.max())
    if a_max - a_min < 1e-4:
        return cab
    offs = np.linspace(a_min, a_max, 7)
    ps = [fn(min(D, max(0.0, t + o))) for o in offs]
    idx = np.clip(np.searchsorted(offs, adelanto) - 1, 0, len(offs) - 2)
    w = (adelanto - offs[idx]) / (offs[idx + 1] - offs[idx])
    filas = np.arange(NU)
    for campo in ("th", "ps", "ro"):
        pila = np.stack([getattr(q, campo) for q in ps])
        setattr(cab, campo, pila[idx, filas] * (1 - w) + pila[idx + 1, filas] * w)
    # el anclaje (cuánto cuerpo asoma) va con la base (o, con ua_cabeza, a la hora de la cabeza: el cuerpo sale del
    # agujero a la vez que la cabeza avanza; la base solo adelanta la curva)
    if not ua_cabeza:
        q_base = fn(min(D, max(0.0, t + float(np.interp(cab.ua, U, adelanto)))))
        cab.ua = q_base.ua
        cab.ap = q_base.ap.copy()
    # las crestas, con el adelanto de su tramo y algo más tarde (superposición)
    for k in ALETAS:
        o = float(np.interp(k * LSEG, U, adelanto)) - retraso_crestas
        q = fn(min(D, max(0.0, t + o)))
        cab.placas_k[k] = q.placas_k.get(k, 0.0) + (q.placas - cab.placas)
    return cab


def resorte(x, w=2 * math.pi * 1.4, z=0.55, dt=1.0 / FPS, x0=None):
    """v5: un muelle amortiguado que sigue a la serie x (por fotogramas): llega con algo de retraso, se pasa un poco y
    se asienta (el peso de la cabeza al girar o al parar). x: array (n,) o (n, k)."""
    x = np.asarray(x, dtype=float)
    y = np.zeros_like(x)
    pos = x[0].copy() if x0 is None else np.array(x0, dtype=float)
    vel = np.zeros_like(pos)
    for i in range(len(x)):
        acc = w * w * (x[i] - pos) - 2.0 * z * w * vel
        vel = vel + acc * dt
        pos = pos + vel * dt
        y[i] = pos
    return y


# La mirada: a quién busca la cabeza (Blender, coordenadas del modelo: mira a −Y; z = 0 la arena). Los héroes del
# combate quedan delante y abajo, repartidos a lo ancho (Kael, Lya y Garon, a escala 1 del gusano).
OBJETIVOS = {"centro": Vector((0.0, -12.5, 1.2)), "izq": Vector((3.2, -12.0, 1.2)), "der": Vector((-3.0, -13.0, 1.2))}


def mirada(p, objetivo):
    """v5: (cabeceo, giro) de la cabeza, en los grados de p.cab, para que la boca apunte a «objetivo» desde la pose p
    (el resto de la columna como está)."""
    P = resolver(p)
    R = marco_en(p, 0.0)
    d = (Vector(objetivo) - punto(P, 0.0)).normalized()
    l = R.transposed() @ d
    cabeceo = math.degrees(math.asin(max(-1.0, min(1.0, l.z))))
    giro = math.degrees(math.atan2(l.x, -l.y))
    return np.array((cabeceo, giro))


def buscar(poses, objetivos, pesos, w=2 * math.pi * 1.5, z=0.5, muelle=True):
    """v5: la cabeza que BUSCA a su objetivo: en cada fotograma, mezcla la cabeza de la pose con la que mira a
    objetivos[i] (peso pesos[i]) y pasa el resultado por un muelle (llega, se pasa un poco y se asienta)."""
    # se filtra la CORRECCIÓN (no la cabeza entera): donde el peso es 0 la cabeza vuelve a la de la pose, y los
    # principios y finales de los clips siguen siendo los del reposo
    delta = []
    for p, o, pe in zip(poses, objetivos, pesos):
        delta.append((mirada(p, o) - p.cab[:2]) * pe if pe > 0.0 else np.zeros(2))
    filtrado = resorte(np.array(delta), w, z, x0=np.zeros(2)) if muelle else np.array(delta)
    for p, f in zip(poses, filtrado):
        p.cab = p.cab + np.array((f[0], f[1], 0.0))
    return poses


# ---------------------------------------------------------------- v5: el reposo (6 s en bucle)

T_REPOSO = 6.0
_REPOSO = []


def _reposo_crudo(t):
    """El reposo sin la mirada: respira (dos respiraciones en el bucle) y la respiración BAJA por el cuello con retraso;
    se mece despacio de lado a lado con una onda que viaja hacia el agujero; las crestas ondulan con retraso; el núcleo
    y la garganta laten con la respiración. Boca cerrada: las mandíbulas apenas se separan al inspirar (≤ 2°) y los
    colmillos van plegados."""
    T = T_REPOSO
    r = 2 * math.pi * t / (T / 2)                 # la respiración (3 s)
    w = 2 * math.pi * t / T                       # el vaivén (6 s)
    p = Pose(TH_REPOSO, ua=UA_REPOSO, cab=(-4, 0, 0), boca=0.0, colm=0.0)
    p.th = p.th + math.radians(2.6) * np.sin(r - U * 0.16) * campana(1.0, 9.0, 2.0)
    p.ps = p.ps + math.radians(2.6) * np.sin(w - U * 0.32) * campana(0, 11, 2)
    p.ro = p.ro + math.radians(1.6) * np.sin(w + 1.1 - U * 0.28) * campana(0, 9, 2)
    p.cab = np.array((-4 + 1.4 * math.sin(r + 0.5), 0.0, 3.0 * math.sin(w + 0.9)))
    inspira = 0.5 + 0.5 * math.sin(r)
    p.placas = 2.5 * inspira
    for k in ALETAS:
        p.placas_k[k] = 2.2 * math.sin(r - k * 0.45) + 1.6 * math.sin(w - k * 0.3)
    for k in range(4):
        p.mand_k[k] = 1.6 * inspira * (1.0 if k != 2 else 1.3)
    p.brillo = 1.0 + 0.16 * math.sin(r + 0.4)
    p.garganta = 0.3 + 0.09 * math.sin(r)
    return p


# la mirada del reposo: vigila al grupo y pasa de un héroe a otro (cada 2 s), con el muelle de la cabeza
MIRADA_REPOSO = [(0.0, "centro"), (1.7, "izq"), (3.6, "der"), (5.3, "centro")]


def _calcular_reposo():
    n = int(T_REPOSO * FPS)
    # dos vueltas: el muelle se asienta en la primera y se guarda la segunda (así el bucle no salta)
    poses = [_reposo_crudo((i % n) / FPS) for i in range(2 * n + 1)]
    objetivos = []
    for i in range(2 * n + 1):
        s = (i % n) / FPS
        o = [x for x in MIRADA_REPOSO if x[0] <= s][-1][1]
        objetivos.append(OBJETIVOS[o])
    buscar(poses, objetivos, [0.7] * len(poses), w=2 * math.pi * 1.2, z=0.45)
    return poses[n:]


def pose_reposo(t=0.0, T=None):
    """v5: el reposo en el instante t (en bucle de T_REPOSO s), con la mirada ya filtrada."""
    global _REPOSO
    if not _REPOSO:
        _REPOSO = _calcular_reposo()
    n = len(_REPOSO) - 1
    x = (t % T_REPOSO) / T_REPOSO * n
    i = int(math.floor(x))
    if i >= n:
        return _REPOSO[n].copia()
    return mezclar(_REPOSO[i], _REPOSO[i + 1], x - i)


def clip_reposo():
    return [pose_reposo(i / FPS) for i in range(int(T_REPOSO * FPS) + 1)], {}

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

# ---------------------------------------------------------------- (v5: los clips, más abajo)
# ---------------------------------------------------------------- v5: clips (mismo contrato que la v1-v4)

TH_REPOSO = [(-6, -14), (0, -12), (2.5, 0), (4.5, 30), (6.5, 64), (9, 84), (11.5, 86), (12.5, 82), (14.5, 62),
             (17, 30), (22, 12)]
UA_REPOSO = 12.5
AJUSTE = {"emerger_ua": -6.2, "emerger_alto": 0.85, "derrota_dz": 0.0, "sismico_dz": 0.0}


def adelanto_en(t, tramos_a, u_ancla=UA_REPOSO):
    """v5: el adelanto de la columna en el instante t: tramos_a = [(t, A)], A interpolado suave entre claves (s; + la
    base va por delante, − la cabeza)."""
    xs = [x[0] for x in tramos_a]
    if t <= xs[0]:
        A = tramos_a[0][1]
    elif t >= xs[-1]:
        A = tramos_a[-1][1]
    else:
        i = max(j for j in range(len(xs) - 1) if xs[j] <= t)
        A = tramos_a[i][1] + (tramos_a[i + 1][1] - tramos_a[i][1]) * ease((t - xs[i]) / (xs[i + 1] - xs[i]))
    return A * perfil_base(u_ancla)


def hornear(fn, D, tramos_a, mirar=None, w_mirar=2 * math.pi * 1.5, z_mirar=0.5, muelle=True, tope=None, ua_cabeza=False):
    """v5: los fotogramas del clip: la columna con su adelanto (retardar) y la cabeza que busca a su objetivo
    (mirar(t) → (objetivo, peso))."""
    n = int(round(D * FPS))
    # tope: un instante (el impacto) que la base no pasa antes que la cabeza: llega antes y ESPERA allí (el látigo)
    poses = []
    for i in range(n + 1):
        a_ = adelanto_en(i / FPS, tramos_a)
        if tope is not None and i / FPS <= tope + 1e-6:
            a_ = np.minimum(a_, tope - i / FPS)
        poses.append(retardar(fn, i / FPS, D, a_, ua_cabeza=ua_cabeza))
    if mirar is not None:
        objs, pesos = zip(*[mirar(i / FPS) for i in range(n + 1)])
        buscar(poses, objs, pesos, w_mirar, z_mirar, muelle)
    return poses


def temblor_mand(p, t, fuerza, f=11.0):
    """v5: las mandíbulas tiemblan cada una a su ritmo (solo hacia fuera: nunca se cierran «de más»)."""
    for k in range(4):
        p.mand_k[k] = p.mand_k.get(k, 0.0) + fuerza * (0.5 + 0.5 * math.sin(2 * math.pi * f * t + k * 1.9))
    return p


def clip_emerger():
    """La arena se abomba y tiembla; revienta el hocico (las mandíbulas cerradas, en punta) y la columna sube EMPUJADA
    DESDE ABAJO (la base va por delante y la cabeza llega después); arriba abre las mandíbulas, despliega los colmillos
    y ruge; la cabeza cae por su peso, rebota dos veces y se asienta justo en el reposo."""
    D = 2.8
    abajo = pose_columna(AJUSTE["emerger_ua"], -8.0, 0.0).con(monticulo=0.01, brillo=1.2, colm=0.0)
    abomba = abajo.con(monticulo=0.6, ua=AJUSTE["emerger_ua"] + 0.3)
    alto = pose_columna(13.2, -6.0, 22.0).con(placas=-6.0, brillo=1.7, monticulo=1.18, colm=0.5)
    cuelga = mezclar(pose_columna(13.5, 10.0, 54.0), R0, 0.35).con(ua=13.4, placas=24.0, brillo=1.9, monticulo=1.05, colm=1.08)
    cae = mezclar(R0, cuelga, -0.2).con(ua=10.4, boca=8.0, colm=0.6, placas=10.0, cab=R0.cab + np.array((-14.0, 0, 0)))
    rebota = mezclar(R0, cae, -0.45).con(boca=0.0, colm=0.2)
    asienta = mezclar(R0, cae, 0.15).con(boca=0.0, colm=0.0)
    claves = [(0.0, abajo, ease), (0.2, abomba, ease_in), (AJUSTE["emerger_alto"], alto, ease_out), (1.2, cuelga, ease),
              (1.6, cae, ease_in), (1.88, rebota, ease), (2.15, asienta, ease), (2.45, R0, ease), (2.8, R0, ease)]

    def fn(t):
        p = tramos(t, claves)
        if t < 0.24:
            for k in ALETAS:
                p.placas_k[k] = 6.0 * vibracion(t, 7.5, k)
        if 0.85 <= t < 1.7:
            for k in ALETAS:
                p.placas_k[k] = 7.0 * (1 - (t - 0.85) / 0.85) * vibracion(t, 6.0, k)
        if 1.05 <= t < 1.5:
            f = 0.6 * math.sin(math.pi * (t - 1.05) / 0.45)
            p = sacudir(p, t, f)
            temblor_mand(p, t, 5.0 * f)
        return p
    poses = hornear(fn, D, [(0.0, 0.0), (0.15, 0.1), (1.0, 0.1), (1.4, -0.06), (2.1, 0.0)])
    for i, p in enumerate(poses):
        t = i / FPS
        if t >= 2.45:
            q = pose_reposo(t - D + T_REPOSO)
            poses[i] = mezclar(p, q, ease((t - 2.45) / 0.3)) if t < 2.75 else q
    return poses, {}


def clip_rugido():
    """Toma aire con las mandíbulas apretadas, se enrosca hacia atrás (anticipación), lanza la cabeza (0,8: el pico;
    la base empuja primero) y ruge con las mandíbulas abiertas de más y los colmillos ERIZADOS, las crestas erizadas y
    la garganta encendida; las mandíbulas tiemblan cada una a su ritmo; las cierra de golpe (2,18), los colmillos se
    pliegan después, y la cabeza rebota y se asienta."""
    D = 2.6
    inhala = desde_reposo(math.radians(-4) * campana(0, 4, 2.0), cab=(6, 0, 0), boca=0.0, colm=0.0, placas=-6.0)
    toma = desde_reposo(math.radians(8) * campana(0, 5, 2.0), ua=UA_REPOSO - 1.2, cab=(-20, 0, 0), boca=0.0, colm=0.2,
                        placas=-16.0, brillo=0.9)
    pasa = desde_reposo(math.radians(-11) * campana(0, 4.5, 2.0), ua=UA_REPOSO + 0.4, cab=(14, -10, 0), boca=67.0,
                        colm=1.08, placas=32.0, brillo=2.0, garganta=1.8)
    ruge = desde_reposo(math.radians(-6) * campana(0, 4.5, 2.0), ua=UA_REPOSO + 0.25, cab=(10, -10, 0), boca=64.0,
                        colm=1.08, placas=28.0, brillo=1.8, garganta=1.6)
    cierra = desde_reposo(math.radians(6) * campana(0, 4, 2.0), ua=UA_REPOSO - 0.2, cab=(-12, 0, 0), boca=0.0, colm=0.6,
                          placas=-4.0)
    rebote = mezclar(R0, cierra, -0.25).con(colm=0.0)
    claves = [(0.0, R0, ease), (0.18, inhala, ease), (0.55, toma, ease), (0.8, pasa, ease_out), (0.98, ruge, ease),
              (1.9, ruge, ease), (2.18, cierra, ease_in), (2.4, rebote, ease), (2.6, R0, ease)]

    def fn(t):
        p = tramos(t, claves)
        if 0.78 <= t <= 2.0:
            f = ease((t - 0.78) / 0.15) * (1 - ease((t - 1.8) / 0.2))
            p = sacudir(p, t, f)
            p.boca = p.boca + 2.5 * math.sin(2 * math.pi * 6.0 * t) * f
            temblor_mand(p, t, 6.0 * f, 9.0)
        return p
    poses = hornear(fn, D, [(0.0, 0.0), (0.3, 0.07), (0.85, 0.07), (1.1, -0.05), (2.0, -0.04), (2.45, 0.0)])
    return poses, {"inicio_rugido": 0.55, "pico_rugido": 0.8, "fin_rugido": 1.9}


TH_RETRAE = [(-6, 6), (0, 6), (1.5, 30), (3, 72), (5, 96), (7, 98), (9.2, 84), (12, 60), (16, 30), (22, 12)]
TH_EMBISTE = [(-6, -28), (0, -28), (2.5, -12), (5, 6), (8.5, 40), (11.5, 70), (14.5, 82), (17, 60), (22, 20)]
UA_EMBISTE = 14.2


def clip_ataque():
    """La Embestida del Abismo. ANTICIPACIÓN (0,12 a 0,55): se recoge hacia atrás y abajo en S, la base primero, con
    las mandíbulas apretadas. FIJA (0,55 a 0,8): el cuello tiembla pero la CABEZA SE QUEDA CLAVADA en su objetivo; las
    mandíbulas castañetean y los colmillos empiezan a salir. SE LANZA como un látigo (la base va por delante y la cabeza
    llega la última y más deprisa), abre las mandíbulas a mitad de camino con los colmillos erizados y MUERDE: las
    cierra de golpe en el impacto (1,0) con los colmillos fuera (se cruzan delante de la boca). Sacude a la presa dos
    veces (el cuerpo sigue por la inercia y llega después), pliega los colmillos y vuelve."""
    D = 2.3
    retrae = Pose(TH_RETRAE, ua=9.1, cab=(-20, 0, 0), boca=0.0, colm=0.0, placas=-16.0, brillo=1.3)
    embiste = Pose(TH_EMBISTE, ua=UA_EMBISTE, cab=(2, 0, 0), boca=0.0, colm=1.0, placas=16.0, brillo=1.6, garganta=0.6)
    rebote = mezclar(embiste, R0, 0.28).con(placas=22.0, cab=(-12.0, 0.0, 0.0), colm=1.0)
    medio = mezclar(embiste, R0, 0.7).con(colm=0.3)
    muerde = mezclar(embiste, rebote, 0.04)              # el mordisco aguanta un instante (la base llega antes)
    claves = [(0.0, R0, ease), (0.12, R0, ease), (0.55, retrae, ease), (0.8, retrae, ease), (1.0, embiste, ease_in3),
              (1.08, muerde, ease), (1.26, rebote, ease_out), (1.6, medio, ease), (2.15, R0, ease), (2.3, R0, ease)]

    def fn(t):
        p = tramos(t, claves)
        if 0.55 <= t < 0.8:
            p.th = p.th + math.radians(0.9) * np.sin(2 * math.pi * 9 * t + U * 2.0) * campana(0, 9, 2)
            for k in ALETAS:
                p.placas_k[k] = 4.0 * vibracion(t, 9.0, k)
            temblor_mand(p, t, 3.0, 12.0)
            p.colm = 0.35 * ease((t - 0.62) / 0.18)
        if 0.8 <= t < 1.0:                               # el arco del salto, más bajo (los cuernos no asoman por arriba)
            s_ = (t - 0.8) / 0.2
            p.th = p.th - math.radians(12.0) * math.sin(math.pi * s_) * campana(0, 7, 2)
            p.cab = p.cab + np.array((8.0 * math.sin(math.pi * s_), 0.0, 0.0))
        if 0.8 <= t < 1.0:                               # abre tarde, ya bajando hacia la presa (la mandíbula de
            a = math.sin(math.pi * ease((t - 0.84) / 0.135)) if 0.84 <= t < 0.975 else 0.0   # arriba no asoma por arriba)
            p.boca = 62.0 * a
            p.colm = 0.35 + 0.73 * ease((t - 0.8) / 0.08)
        if 1.08 <= t < 1.62:
            f = ease((t - 1.08) / 0.08) * (1 - ease((t - 1.08) / 0.55))
            p.cab = p.cab + np.array((4.0 * math.sin(2 * math.pi * 3.5 * (t - 1.08)), 16.0 * math.sin(2 * math.pi * 3.5 * (t - 1.08)),
                                      10.0 * math.sin(2 * math.pi * 3.5 * (t - 1.08) + 0.6))) * f
            for k in ALETAS:
                p.placas_k[k] = p.placas_k.get(k, 0.0) + 7.0 * f * vibracion(t, 7.5, k)
            p.colm = 1.0 - 0.7 * ease((t - 1.36) / 0.25)
        return p

    def mirar(t):                                         # clavada mientras fija; la suelta al lanzarse
        peso = ease((t - 0.45) / 0.15) * (1 - ease((t - 0.78) / 0.1))
        return OBJETIVOS["centro"], peso
    # el adelanto de la base: se recoge primero (0,15 a 0,5), se queda quieta mientras fija (la cabeza clavada), y en el
    # salto llega a su sitio 0,08 s antes que la cabeza (látigo); tras el mordisco el cuerpo llega tarde (inercia)
    # (el adelanto vuelve a 0 justo en el mordisco: la base frena mientras la cabeza sigue acelerando, el latigazo, y lo
    # más lejos sigue siendo el fotograma del impacto, 1,0 s, como pide el contrato)
    poses = hornear(fn, D, [(0.0, 0.0), (0.15, 0.05), (0.5, 0.05), (0.62, 0.0), (0.78, 0.0), (0.88, 0.08), (1.0, 0.08),
                            (1.06, 0.0), (1.3, -0.06), (1.7, -0.04), (2.05, 0.0)], mirar, muelle=False, tope=1.0,
                    ua_cabeza=True)
    # en los últimos fotogramas del salto la cabeza ya no cabecea: va clavada en la dirección del mordisco (el cuerpo la
    # empuja; así lo más lejos es el fotograma del impacto)
    p30 = poses[int(round(1.0 * FPS))]
    R = marco_en(p30, 0.0) @ rot_z(math.radians(p30.cab[1])) @ rot_x(-math.radians(p30.cab[0])) @ rot_y(-math.radians(p30.cab[2]))
    meta = punto(resolver(p30), 0.0) + (R @ Vector((0.0, -1.0, 0.0))) * 40.0
    tramo = [i for i in range(len(poses)) if 0.84 <= i / FPS <= 1.16]
    buscar([poses[i] for i in tramo], [meta] * len(tramo),
           [ease((i / FPS - 0.84) / 0.06) * (1 - ease((i / FPS - 1.04) / 0.12)) for i in tramo], muelle=False)
    return poses, {"anticipacion": 0.2, "fijado": 0.55, "impacto": None}


# v5: la Fractura, MÁS BAJA que la v4 en el aviso (en la v4 lo alto de la cabeza y los cuernos rozaban el borde de
# arriba de la pantalla): erguido con la cabeza inclinada hacia los héroes (los cuernos hacia atrás, no hacia arriba).
TH_ERGUIDO = [(-6, 10), (0, 12), (2, 42), (4, 74), (9, 88), (12, 76), (16, 56), (22, 40)]
TH_ATRAS = [(-6, 22), (0, 22), (2, 48), (4, 80), (9, 90), (12, 78), (16, 58), (22, 40)]
TH_CAIDO = [(-6, -8), (0, -8), (3, 0), (6, 6), (8.0, 18), (9.0, 40), (11.0, 62), (22, 40)]
UA_ERGUIDO = 8.5
UA_CAIDO = 9.2
CAB_AVISO = (-16.0, -6.0, 0.0)                # la cabeza mira abajo, a los héroes, mientras ruge


def clip_ataque_sismico():
    """La Fractura del Mar de Cristal. Se ALZA desenroscándose desde la base (0 a 1,0), con las crestas erizadas y la
    cabeza baja, mirando a los héroes; RUGE arriba con las mandíbulas abiertas y los colmillos erizados y se sacude
    (1,15 a 1,9: el tramo que se repite mientras avisa); se ECHA ATRÁS (anticipación, 1,9 a 2,1) y se DESPLOMA como una
    torre, acelerando, con la cabeza la última (látigo) y las mandíbulas cerradas, hasta dar contra la arena delante de
    los héroes (2,5333). El golpe sube por el cuerpo hacia la cola, rebota con peso dos veces, se asienta y vuelve."""
    D = 3.8
    dz = AJUSTE["sismico_dz"]
    erguido = Pose(TH_ERGUIDO, ua=UA_ERGUIDO, cab=CAB_AVISO, boca=26.0, colm=0.8, placas=24.0, brillo=1.6, garganta=0.8)
    ruge = erguido.con(cab=(CAB_AVISO[0] + 6.0, CAB_AVISO[1] - 4.0, 0.0), boca=54.0, colm=1.08, placas=32.0, garganta=1.6,
                       brillo=1.9)
    atras = Pose(TH_ATRAS, ua=UA_ERGUIDO - 0.3, cab=(-4, 0, 0), boca=10.0, colm=0.5, placas=34.0, brillo=2.0, garganta=1.0)
    caido = Pose(TH_CAIDO, ua=UA_CAIDO, ap=(0, 0, dz), cab=(-4, 0, 0), boca=0.0, colm=0.2, placas=-8.0, brillo=1.7,
                 garganta=0.6)
    golpe = caido.con(losas=1.0)
    bote = golpe.copia()
    bote.th = bote.th + math.radians(6) * campana(-6, 8, 3)
    bote.placas = 18.0
    bote2 = golpe.copia()
    bote2.th = bote2.th + math.radians(2) * campana(-6, 8, 3)
    asentado = caido.con(losas=0.62)
    levanta = mezclar(asentado, R0, 0.55).con(losas=0.0, colm=0.0)
    claves = [(0.0, R0, ease), (0.1, R0, ease), (1.0, erguido, ease), (1.2, ruge, ease_out), (1.85, ruge, ease),
              (2.05, atras, ease), (2.5333, caido, ease_in3), (2.66, bote, ease_out), (2.8, golpe, ease_in),
              (2.9, bote2, ease_out), (3.0, golpe, ease_in), (3.12, asentado, ease), (3.45, levanta, ease),
              (3.68, R0, ease), (3.8, R0, ease)]

    def fn(t):
        p = tramos(t, claves)
        if 1.15 <= t <= 1.98:
            fz = ease((t - 1.15) / 0.15) * (1 - ease((t - 1.85) / 0.12))
            p = sacudir(p, t, fz, f=4.2857)               # 3 vueltas en el tramo de espera (1,3 a 2,0): sin salto
            temblor_mand(p, t, 5.0 * fz, 8.5714)
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
            for k in range(4):
                p.mand_k[k] = p.mand_k.get(k, 0.0) + 4.0 * amort * (0.5 + 0.5 * math.sin(2 * math.pi * 7 * dt + k))
        return p

    def mirar(t):
        peso = ease((t - 0.6) / 0.3) * (1 - ease((t - 1.85) / 0.12))
        return OBJETIVOS["centro"], 0.55 * peso
    poses = hornear(fn, D, [(0.0, 0.0), (0.12, 0.12), (0.9, 0.1), (1.15, 0.0), (1.9, 0.0), (2.05, 0.06), (2.45, 0.09),
                            (2.5333, 0.0), (2.6, -0.1), (3.2, -0.06), (3.6, 0.0)], mirar)
    return poses, {"erguido": 1.0, "rugido": 1.15, "caida": 2.1, "impacto": None, "placas_suelo": 2.5333,
                   "placas_asientan": 3.1, "placas_fin": 3.65}


# v5: en la descarga la cabeza gira hacia la cámara del combate (como la v4) para que el chorro salga, a la vista, del
# fondo de la garganta; pero con la boca abierta lo justo (la v4 se pasaba: 66) y sin subir (la cabeza a la vista).
GIRO_DESCARGA = -48.0
CABECEO_DESCARGA = -2.0


def clip_ataque_aliento():
    """El Aliento del Desierto Eterno. Abre las mandíbulas despacio y despliega los colmillos (0 a 0,4); ASPIRA (0,45 a
    1,6): la arena sube en cintas hasta dentro de la boca, la garganta se enciende y el cuello se echa atrás tragando
    (la base primero); las mandíbulas tiemblan con la succión. Se RECOGE (1,6 a 1,78: la anticipación del soplo, las
    mandíbulas a medio cerrar); en la DESCARGA (1,85) lanza la cabeza vuelta hacia la cámara con las mandíbulas
    abiertas (sin pasarse) y el chorro sale del fondo de la garganta; barre hasta 2,6; cierra, pliega y vuelve."""
    D = 3.6
    abre = desde_reposo(math.radians(-6) * campana(0, 4.5, 2.0), cab=(-10, -12, 0), boca=46.0, colm=0.7, placas=10.0,
                        brillo=1.2, garganta=0.8)
    aspira = desde_reposo(math.radians(10) * campana(0, 4.5, 2.0), ua=UA_REPOSO - 0.4, cab=(-6, -18, 0), boca=60.0, colm=1.0,
                          placas=26.0, brillo=2.4, garganta=3.0)
    aspira.succion = 1.0
    abre.succion = 0.35
    recoge = desde_reposo(math.radians(6) * campana(0, 4.5, 2.0), ua=UA_REPOSO - 1.0, cab=(-6, -22, 0), boca=30.0, colm=0.8,
                          placas=30.0, brillo=2.5, garganta=3.4)
    escupe = desde_reposo(math.radians(-6) * campana(0, 4.5, 2.0), ua=UA_REPOSO + 0.2,
                          cab=(CABECEO_DESCARGA, GIRO_DESCARGA, 0), boca=58.0, colm=1.1, placas=-10.0, brillo=2.1,
                          garganta=2.8)
    barre = escupe.con(cab=(CABECEO_DESCARGA + 1.0, GIRO_DESCARGA + 10.0, 0.0), garganta=1.6, brillo=1.6, boca=56.0)
    claves = [(0.0, R0, ease), (0.4, abre, ease), (1.6, aspira, ease), (1.78, recoge, ease_out), (1.85, escupe, ease_out),
              (2.6, barre, ease), (3.0, mezclar(barre, R0, 0.6).con(colm=0.3), ease), (3.45, R0, ease), (3.6, R0, ease)]

    def fn(t):
        p = tramos(t, claves)
        if t < 0.45:
            p.succion = 0.01
        elif t < 1.6:
            p.succion = max(0.01, ease((t - 0.45) / 0.25))
        else:
            p.succion = max(0.01, 1.0 - ease((t - 1.6) / 0.1))
        if 0.45 <= t < 1.85:
            fz = 0.45 * ease((t - 0.45) / 1.15)
            p = sacudir(p, t, fz, f=6.0)
            temblor_mand(p, t, 4.0 * fz / 0.45 * ease((t - 0.45) / 0.3), 13.0)
        if 1.85 <= t < 2.7:
            p.chorro = ease((t - 1.85) / 0.1) * (1 - ease((t - 2.6) / 0.1)) * (1.0 + 0.04 * math.sin(2 * math.pi * 9 * t))
            p.cab = p.cab + np.array((1.5 * math.sin(2 * math.pi * 7 * t), 1.0 * math.sin(2 * math.pi * 5 * t), 0))
            for k in ALETAS:
                p.placas_k[k] = p.placas_k.get(k, 0.0) + 5.0 * vibracion(t, 8.0, k)
            temblor_mand(p, t, 3.0, 15.0)
        return p
    poses = hornear(fn, D, [(0.0, 0.0), (0.3, 0.05), (1.6, 0.05), (1.8, 0.08), (1.86, 0.0), (1.95, -0.06), (2.6, -0.04),
                            (3.2, 0.0)])
    return poses, {"apertura": 0.3, "inicio_succion": 0.45, "carga_max": 1.6, "fin_succion": 1.7, "descarga": 1.85,
                   "fin_descarga": 2.6}


def clip_herida():
    """Recibe el golpe EN LA CABEZA: la cabeza salta hacia atrás y se aparta (0,1) y el golpe BAJA por el cuello hacia
    la cola (la cabeza primero, el resto con retraso); las mandíbulas se sueltan un poco y los colmillos asoman (un
    gruñido), las crestas se encogen y tiemblan, la luz parpadea; se rehace con un pequeño rebote."""
    D = 1.0
    golpe = desde_reposo(math.radians(8) * campana(0, 5, 2.0), ua=UA_REPOSO - 0.4, cab=(2, -14, 3), boca=14.0, colm=0.45,
                         brillo=0.5, placas=-12.0)
    vuelve = mezclar(golpe, R0, 0.72).con(boca=0.0, colm=0.1)
    pasa = mezclar(golpe, R0, 1.12).con(boca=0.0, colm=0.0)
    claves = [(0.0, R0, ease), (0.1, golpe, ease_out), (0.36, vuelve, ease), (0.6, pasa, ease), (0.84, R0, ease),
              (1.0, R0, ease)]

    def fn(t):
        p = tramos(t, claves)
        if 0.08 <= t < 0.95:
            for k in ALETAS:
                p.placas_k[k] = p.placas_k.get(k, 0.0) + 9.0 * max(0.0, 1 - (t - 0.08) / 0.6) * vibracion(t, 7.5, k)
        if 0.08 <= t < 0.5:
            p.brillo = p.brillo * (0.7 + 0.3 * math.cos(2 * math.pi * 9 * t))
            temblor_mand(p, t, 4.0 * (1 - ease((t - 0.08) / 0.4)), 14.0)
        return p
    poses = hornear(fn, D, [(0.0, 0.0), (0.06, -0.12), (0.6, -0.1), (0.8, 0.0)])
    return poses, {"golpe": 0.1}


TH_DERRIBADO = [(-6, -18), (0, -18), (3, -6), (6, 2), (9, 10), (10.5, 30), (12, 55), (22, 30)]
DERROTA_UA = 10.5


def clip_derrota():
    """Se retuerce de dolor (las mandíbulas abiertas, los colmillos erizados, la luz parpadeando), se queda un instante
    sin fuerzas y se DESPLOMA de lado como una torre (la base cede primero y la cabeza cae la última, acelerando): da con
    la cabeza contra la arena (caida), rebota con peso dos veces, cada vez menos, y el golpe recorre el cuerpo hasta la
    cola; se hunde a medias apagándose, con las mandíbulas FLOJAS (la de abajo cuelga más, la de arriba apenas) y los
    colmillos caídos."""
    D = 3.4
    dz = AJUSTE["derrota_dz"]
    dolor = desde_reposo(math.radians(0) * campana(0, 5, 2.0), cab=(3, 0, 0), boca=48.0, colm=1.08, placas=12.0, brillo=1.4)
    flojo = desde_reposo(math.radians(-3) * campana(0, 5, 2.0), cab=(-8, 4, 0), boca=30.0, colm=0.6, placas=4.0, brillo=1.0)
    caido = Pose(TH_DERRIBADO, ps=[(-6, 30), (9, 30), (11, 10), (14, 0)], ro=[(-6, 50), (9, 50), (11.5, 10), (14, 0)],
                 ua=DERROTA_UA, ap=(0, 0, dz), cab=(-10, 0, 35), boca=20.0, colm=0.3, placas=-18.0, brillo=0.5, garganta=0.3)
    bote = caido.copia()
    bote.th = bote.th + math.radians(5) * campana(-6, 7, 3)
    bote2 = caido.copia()
    bote2.th = bote2.th + math.radians(1.6) * campana(-6, 7, 3)
    hundido = caido.con(ua=DERROTA_UA - 1.7, boca=28.0, colm=0.0, placas=-22.0, brillo=0.08, garganta=0.05)
    claves = [(0.0, R0, ease), (0.5, dolor, ease_out), (0.66, flojo, ease), (1.6, caido, ease_in3), (1.76, bote, ease_out),
              (1.92, caido, ease_in), (2.04, bote2, ease_out), (2.16, caido, ease_in), (3.4, hundido, ease)]

    def fn(t):
        p = tramos(t, claves)
        if t < 0.65:
            p = sacudir(p, t, ease(t / 0.2) * 0.8)
            p.brillo = p.brillo * (0.6 + 0.4 * (0.5 + 0.5 * math.sin(2 * math.pi * 6 * t)))
            temblor_mand(p, t, 6.0 * ease(t / 0.2), 10.0)
        if 1.0 <= t < 2.2:
            for k in ALETAS:
                p.placas_k[k] = p.placas_k.get(k, 0.0) - 10.0 * ease((t - 1.0 - 0.03 * k) / 0.5)
        if t >= 2.2:
            for k in ALETAS:
                p.placas_k[k] = p.placas_k.get(k, 0.0) - 10.0
        if t < 1.6:                                       # se tumba de lado al final de la caída (antes, al
            p.ro = p.ro * ease((t - 1.2) / 0.4)          # rodar con la cabeza aún alta, un cuerno subía de más)
        if t >= 1.6:
            flojas = ease((t - 1.6) / 0.6)                      # la gravedad: la de abajo cuelga, la de arriba apenas
            p.mand_k[2] = p.mand_k.get(2, 0.0) + 14.0 * flojas
            p.mand_k[0] = p.mand_k.get(0, 0.0) - 6.0 * flojas
            p.mand_k[1] = p.mand_k.get(1, 0.0) + 5.0 * flojas
        return p
    poses = hornear(fn, D, [(0.0, 0.0), (0.6, 0.0), (0.8, 0.08), (1.15, 0.05), (1.45, 0.0), (1.62, 0.0), (1.7, -0.14),
                            (2.6, -0.1), (3.2, 0.0)])
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
    a = apertura(p.boca)
    s, t = esfinter_estado(a)
    return {"hocico": mundo_de(ARM, G, B, "cabeza", P_HOCICO()), "barbilla": mundo_de(ARM, G, B, "cabeza", P_BARBILLA()),
            "bajo": mundo_de(ARM, G, B, "cabeza", P_MAND_BAJO()), "nuca": punto(P, 0.0),
            "cierre": R_BOCA * s, "boca": max(0.0, p.boca), "G": G,
            "corona": max([mundo_de(ARM, G, B, "cabeza", q).z for q in PUNTAS_CORONA] +
                          [mundo_cabeza(ARM, G, M_mandibula(k, a, p.mand_k.get(k, 0.0)), mandibula_punto(k, 0.0, 1.0, 1)).z
                           for k in range(len(MANDIBULAS))] or [0.0])}


def ajustar_instantes():
    """Mueve un poco las poses clave para que los instantes que se miden en el clip caigan en el mismo fotograma que el
    contrato de la v1/v2/v3."""
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
    for ta in [0.85, 0.86, 0.84, 0.87, 0.83, 0.88, 0.82, 0.89, 0.9]:
        AJUSTE["emerger_alto"] = ta
        ps, _ = clip_emerger()
        al = [max(medir(ps[j])["hocico"].z, medir(ps[j])["nuca"].z + 1.5) for j in range(18, 40)]
        if 18 + int(np.argmax(al)) == 26:
            break
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
        AJUSTE["derrota_dz"] = 0.0
        ps, _ = clip_derrota()
        print("  derrota (dz 0): alto de la cabeza por fotograma",
              [(j, round(min(medir(ps[j])["bajo"].z, medir(ps[j])["barbilla"].z), 2)) for j in range(30, 70, 2)])
    AJUSTE["sismico_dz"] = 0.0
    caido = Pose(TH_CAIDO, ua=UA_CAIDO, cab=(-4, 0, 0))
    m = medir(caido)
    print("FRACTURA sin ajuste: nuca", tuple(round(x, 2) for x in m["nuca"]), "hocico", tuple(round(x, 2) for x in m["hocico"]),
          "barbilla", tuple(round(x, 2) for x in m["barbilla"]), "bajo", tuple(round(x, 2) for x in m["bajo"]))
    AJUSTE["sismico_dz"] = round(0.25 - min(m["bajo"].z, m["barbilla"].z), 3)
    print("AJUSTE", AJUSTE)


# ---------------------------------------------------------------- (copia literal de crear_bramavidrio3.py)

def _primera(poses, desde, cond):
    for j in range(desde, len(poses)):
        if cond(medir(poses[j])):
            return j
    return None


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
        if DEPURAR or i != int(round(1.0 * FPS)):
            print("  embestida, barbilla (y) por fotograma:", [(j, round(medidas[j]["barbilla"].y, 3), round(medidas[j]["barbilla"].z, 2))
                                                              for j in range(i0, i1 + 1)])
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

# ---------------------------------------------------------------- v5: comprobaciones de la boca (numéricas)

ROCES = ("craneo", "collar", "marco", "cuerno")
DEPURAR = os.environ.get("BRAMA_DEPURAR", "") == "1"       # imprime dónde se tocan las piezas (depuración)
PASO_ROCES = float(os.environ.get("BRAMA_PASO_ROCES", "0.1"))   # v5: cada cuánto se comprueban los roces (s)


def grupos_caras(M):
    g = {}
    for f, mat, e in zip(M.caras, M.mats, M.etq):
        if mat not in (PIEL, VIDRIO) or e.endswith("_base"):
            continue
        g.setdefault(e, []).append(tuple(f))
    return g


UNIONES_DE = {}
ESTIRA_PIEL = {}
SEPARA_BISAGRA = {}


def comprobar_intersecciones(arm, obj, M, pedidos):
    """v5: pares de triángulos que se atraviesan (árbol BVH sobre la malla YA deformada por el esqueleto), por clip y
    segundo: mandíbulas entre sí y con la cabeza (cráneo, collar y nudillos, marco, cuernos), los labios y los dientes
    fijos; colmillos entre sí y con todo lo anterior (también con su propia mandíbula); dientes fijos con labios. No
    cuentan las bases (de los dientes y de las mandíbulas: metidas a propósito en la carne o en el nudillo)."""
    g = grupos_caras(M)
    mands = sorted(k for k in g if k.startswith("mand_"))
    colms = sorted(k for k in g if k.startswith("colm_"))
    rigido = sum((g.get(k, []) for k in ROCES), [])
    uniones = sorted(k for k in g if k.startswith("union_") or k.startswith("mejilla_"))
    aristas = getattr(M, "aristas_union", [])
    estira = [0.0, 1e9]
    separa = {}
    UNIONES_DE.clear()
    UNIONES_DE.update(getattr(M, "uniones_de", {}))
    for k_ in list(UNIONES_DE):
        UNIONES_DE[k_] = {"mand_" + x[5:] if x.startswith("mand_") else x for x in UNIONES_DE[k_]}
    print("CARAS: mandíbulas %d, colmillos %d, labio %d, dientes fijos %d, cabeza %d" % (
        sum(len(g[k]) for k in mands), sum(len(g[k]) for k in colms), len(g.get("labio", [])),
        len(g.get("diente_fijo", [])), len(rigido)))
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
            arbol = lambda caras: BVHTree.FromPolygons(vs, caras)
            t_lab = arbol(g.get("labio", []))
            t_fij = arbol(g.get("diente_fijo", []))
            t_rig = arbol(rigido)
            tm = {k: arbol(g[k]) for k in mands}
            tc = {k: arbol(g[k]) for k in colms}
            c = {"mandibulas_entre_si": 0, "mandibula_cabeza": 0, "mandibula_labio": 0, "mandibula_dientes": 0,
                 "colmillos_entre_si": 0, "colmillo_mandibula": 0, "colmillo_cabeza": 0, "colmillo_labio": 0,
                 "colmillo_dientes": 0, "dientes_labio": len(t_fij.overlap(t_lab))}
            detalle = []
            for i, a in enumerate(mands):
                for b in mands[i + 1:]:
                    n_ = len(tm[a].overlap(tm[b]))
                    c["mandibulas_entre_si"] += n_
                    if n_:
                        detalle.append((a, b, n_))
                for nombre_, t2 in (("mandibula_cabeza", t_rig), ("mandibula_labio", t_lab), ("mandibula_dientes", t_fij)):
                    n_ = len(tm[a].overlap(t2))
                    c[nombre_] += n_
                    if n_:
                        detalle.append((a, nombre_, n_))
                        if DEPURAR and nombre_ == "mandibula_cabeza":
                            for parte in ROCES:
                                n2 = len(tm[a].overlap(arbol(g[parte]))) if g.get(parte) else 0
                                if n2:
                                    detalle.append((a, parte, n2))
            for i, a in enumerate(colms):
                for b in colms[i + 1:]:
                    n_ = len(tc[a].overlap(tc[b]))
                    c["colmillos_entre_si"] += n_
                    if n_:
                        detalle.append((a, b, n_))
                for b in mands:
                    n_ = len(tc[a].overlap(tm[b]))
                    c["colmillo_mandibula"] += n_
                    if n_:
                        detalle.append((a, b, n_))
                for nombre_, t2 in (("colmillo_cabeza", t_rig), ("colmillo_labio", t_lab), ("colmillo_dientes", t_fij)):
                    n_ = len(tc[a].overlap(t2))
                    c[nombre_] += n_
                    if n_:
                        detalle.append((a, nombre_, n_))
            # v5, 2.ª vuelta: la piel de la boca (belfos, encías y mejillas) con los colmillos, los dientes, los labios,
            # el cráneo y las mandíbulas a las que NO va cosida
            c["piel_boca"] = 0
            caras_dura = sum((g.get(k_, []) for k_ in ("craneo", "marco", "cuerno")), [])
            t_dura = arbol(caras_dura)
            for a in uniones:
                tu = arbol(g[a])
                otros = [(b, tm[b]) for b in mands if b not in UNIONES_DE.get(a, set())] + list(tc.items()) + \
                    [("diente_fijo", t_fij), ("labio", t_lab), ("cabeza", t_dura)]
                for b, t2 in otros:
                    n_ = len(tu.overlap(t2))
                    c["piel_boca"] += n_
                    if n_:
                        detalle.append((a, b, n_))
                        if DEPURAR:
                            par = tu.overlap(t2)[0]
                            cen_ = sum((vs[j_] for j_ in g[a][par[0]]), Vector()) / len(g[a][par[0]])
                            Mh = arm.data.bones["cabeza"].matrix_local @ arm.pose.bones["cabeza"].matrix.inverted()
                            q_ = Mh @ cen_
                            detalle.append(("   en la cabeza: r %.2f, y−YF %.2f, ángulo %.0f" % (math.hypot(q_.x, q_.z), q_.y - YF, math.degrees(math.atan2(q_.x, q_.z))),))
                            if b == "cabeza":
                                verts_ = [Mh @ vs[j_] for j_ in g[a][par[0]]]
                                detalle.append(("   vértices: " + str([(round(math.hypot(q.x, q.z), 2), round(q.y - YF, 2), round(math.degrees(math.atan2(q.x, q.z)))) for q in verts_]),))
                                for parte in ("craneo", "marco", "cuerno"):
                                    if g.get(parte) and tu.overlap(arbol(g[parte])):
                                        detalle.append(("   parte: " + parte,))
                                q2 = Mh @ (sum((vs[j_] for j_ in caras_dura[par[1]]), Vector()) / len(caras_dura[par[1]]))
                                detalle.append(("   la otra: r %.2f, y−YF %.2f, ángulo %.0f" % (math.hypot(q2.x, q2.z), q2.y - YF, math.degrees(math.atan2(q2.x, q2.z))),))
            # v5, 2.ª vuelta: que ninguna mandíbula se separe de la cabeza: la bisagra deformada frente a donde la lleva
            # la cabeza (la distancia de la mandíbula a su sitio en el collar)
            Mcab = arm.pose.bones["cabeza"].matrix @ arm.data.bones["cabeza"].matrix_local.inverted()
            for nombre_m, idxs in getattr(M, "bisagras", {}).items():
                dmax = max((vs[i] - Mcab @ M.v[i]).length for i in idxs)
                separa[nombre_m] = max(separa.get(nombre_m, 0.0), dmax)
            # y cuánto se estira (longitud deformada / en reposo de cada tramo de la piel)
            if aristas:
                r_ = [(vs[i] - vs[j]).length / max(1e-6, (M.v[i] - M.v[j]).length) for i, j in aristas]
                estira[0] = max(estira[0], max(r_))
                estira[1] = min(estira[1], min(r_))
            if detalle and DEPURAR:
                print("  ROCE", clip, s, detalle)
            c["s"] = s
            c["total"] = sum(v for k, v in c.items() if k != "s")
            if detalle:
                c["detalle"] = [list(x) for x in detalle]
            filas.append(c)
        res[clip] = filas
        ESTIRA_PIEL[clip] = [round(estira[0], 3), round(estira[1], 3)]   # v5: la piel de la boca, máx. y mín.
        SEPARA_BISAGRA[clip] = {k_: round(v_, 4) for k_, v_ in separa.items()}
        separa = {}
        estira[0], estira[1] = 0.0, 1e9
        print("INTERSECCIONES", clip, [(f["s"], {k: v for k, v in f.items() if v and k not in ("s",)}) for f in filas])
    ad.action = None
    for t, m in estado:
        t.mute = m
    return res


def comprobar_esfinter():
    """La contracción de los labios es radial y monótona para toda apertura (sin pliegues: un punto más de fuera nunca
    queda más cerca del centro que uno de dentro). v5: y las mandíbulas cerradas no se pisan: cada punto de una placa
    (y de sus colmillos) queda en su cuadrante (|lateral| < radial, con holgura), abiertas o cerradas."""
    peor_pliegue = 1e9
    rs = np.linspace(R_BOCA, R_LABIO, 120)
    for a in np.linspace(0.0, 1.12, 29):
        s, t = esfinter_estado(a)
        rp = [r * (1.0 - peor_w * (1.0 - s)) for r, peor_w in ((r, peso_labio(r)) for r in rs)]
        peor_pliegue = min(peor_pliegue, min(rp[i + 1] - rp[i] for i in range(len(rp) - 1)))
    s0, _ = esfinter_estado(0.0)
    holgura = 1e9
    puntas = {}
    for k, m in enumerate(MANDIBULAS):
        th = math.radians(m[1])
        er, tg = e_r(th), Vector((math.cos(th), 0.0, -math.sin(th)))
        for a in (0.0, 0.5, 1.0, 1.12):
            Mm = M_mandibula(k, a)
            pts = [Mm @ mandibula_punto(k, u, v, c_) for u in np.linspace(-1, 1, 9) for v in np.linspace(0, 1, 9) for c_ in (0, 1)]
            for col in (0.0, 1.0):
                Mc = Mm @ M_colmillos(k, col)
                for u in np.linspace(-0.72, 0.72, m[5]):
                    H, t_, d, n = marco_mandibula(k)
                    b = mandibula_punto(k, u, V_COLM, 0) + n * BASE_COLM
                    pts.append(Mc @ (b + DIR_COLM(n, d) * m[6]))
            for p in pts:
                radial = p.x * er.x + p.z * er.z
                lateral = abs(p.x * tg.x + p.z * tg.z)
                holgura = min(holgura, radial - lateral)
            if a == 0.0:
                punta = Mm @ mandibula_punto(k, 0.0, 1.0, 1)
                puntas[m[0]] = [round(math.hypot(punta.x, punta.z), 3), round(YF - punta.y, 3)]
    return {"paso_radial_minimo_m": round(float(peor_pliegue), 5), "radio_abertura_cerrada_m": round(R_BOCA * s0, 4),
            "radio_abertura_abierta_m": R_BOCA, "holgura_cuadrantes_m": round(holgura, 3),
            "puntas_cerradas_radio_y_delante_m": puntas}


FRENTE_ENEMIGO_G = (0.8, 0.0, 0.6)           # bramavidrio4_3d.gd: hacia dónde mira en el combate (Godot)
CAM_ELEVACION = 12.0                         # combate.gd, _crear_rig_3d: la cámara del combate, 12° desde arriba


def a_godot_v(v):
    return Vector((v.x, v.z, -v.y))


def vista_combate(v_b):
    """Un vector de Blender (del gusano) en el mundo del combate (Godot), con el giro del pivote hacia los héroes."""
    g = a_godot_v(v_b)
    fi = math.atan2(FRENTE_ENEMIGO_G[0], FRENTE_ENEMIGO_G[2])
    return Vector((g.x * math.cos(fi) + g.z * math.sin(fi), g.y, -g.x * math.sin(fi) + g.z * math.cos(fi)))


def comprobar_garganta():
    """Desde la cámara del combate, en cada fotograma de la descarga del Aliento (1,85 a 2,6 s): ¿el anclaje de la
    garganta se ve DENTRO de la boca? Se lanza un rayo desde el anclaje hacia la cámara hasta el plano del collar y
    del borde de los labios: la proporción radio del corte / radio de la boca (< 1: dentro)."""
    poses, _ = clip_ataque_aliento()
    vista = Vector((0.0, math.sin(math.radians(CAM_ELEVACION)), math.cos(math.radians(CAM_ELEVACION))))
    filas = []
    for i in range(int(1.85 * FPS), int(2.6 * FPS) + 1):
        p = poses[i]
        B, G, P = bases(ARM, p)
        a = apertura(p.boca)
        s, t = esfinter_estado(a)
        Mc = G["cabeza"] @ ARM.data.bones["cabeza"].matrix_local.inverted()
        T = vista_combate(Mc @ P_ANCLA())
        C0 = vista_combate(Mc @ P_BOCA())
        m = (vista_combate(Mc @ (P_BOCA() + ADELANTE)) - C0).normalized()
        Ce = vista_combate(Mc @ (C_ESF + ADELANTE * t))
        res = {"s": round(i / FPS, 3), "angulo_vista": round(math.degrees(m.angle(vista)), 1)}
        for nombre, centro, radio_ in (("collar", C0, R_LABIO), ("entrada", Ce, R_BOCA * s)):
            den = vista.dot(m)
            lam = (centro - T).dot(m) / den if abs(den) > 1e-6 else 1e9
            X = T + vista * lam
            res[nombre] = round((X - centro).length / max(radio_, 1e-6), 3)
        filas.append(res)
    return {"max_collar": max(f["collar"] for f in filas), "max_entrada": max(f["entrada"] for f in filas),
            "angulo_max": max(f["angulo_vista"] for f in filas), "fotogramas": filas}


# ---------------------------------------------------------------- (copia literal de crear_bramavidrio3.py)

TEX = 2048
ALFA_MIN = 0.04
NORMAL_ALTO, NORMAL_MEDIO = 1024, 512          # v5: lado del mapa de normales por perfil (el bajo no lleva)
FUERZA_NORMAL = float(os.environ.get("BRAMA_FUERZA_NORMAL", "22"))
RUTA_NORMAL = ""

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



# ---------------------------------------------------------------- v4: la textura (pintada con numpy, colores de la lámina)

def runa(rng, x, y, alto, ancho):
    """Un trazo rúnico como los de la lámina: un eje que sube en zigzag con ramas cortas en ángulo (rayos dorados)."""
    pts = [(x, y)]
    lineas = []
    n = rng.integers(3, 6)
    for i in range(n):
        x += rng.uniform(-0.35, 0.35) * ancho
        y += alto / n
        pts.append((x, y))
        if rng.random() < 0.7:
            lado = 1 if rng.random() < 0.5 else -1
            lineas.append([(x, y), (x + lado * ancho * rng.uniform(0.4, 0.8), y - alto / n * rng.uniform(0.2, 0.6))])
    lineas.append(pts)
    return lineas


def pintar_textura(n_px):
    img = np.zeros((n_px, n_px, 3))
    brillo = np.zeros((n_px, n_px))
    alt = np.zeros((n_px, n_px))                 # v5: el relieve (para las normales horneadas)
    rng = np.random.default_rng(4404)
    k = n_px / 2048.0

    def region(r):
        u0, u1, v0, v1 = r
        return int(v0 * n_px), int(v1 * n_px), int(u0 * n_px), int(u1 * n_px)

    # --- el cuerpo: carne rojiza estriada (entre las placas) y el vientre de anillos claros
    y0, y1, x0, x1 = region(AT_TUBO)
    h, w = y1 - y0, x1 - x0
    uu = (np.arange(w) + 0.5) / w
    vv = (np.arange(h) + 0.5) / h
    alfa = (-math.pi + 2 * math.pi * uu)[None, :] * np.ones((h, 1))
    s = (S_INI + vv * (L_CUERPO - S_INI))[:, None] * np.ones((1, w))
    ca = np.cos(alfa)
    n1 = fbm(h, w, 48, 12, 3, 4, envolver=True)
    n2 = fbm(h, w, 190, 48, 9, 3, envolver=True)
    estria = (0.5 + 0.5 * np.sin(s * 2 * math.pi / 0.11 + 2.0 * n1)) ** 2       # estrías finas de través
    rgb = np.ones((h, w, 3)) * np.array(CARNE)[None, None, :]
    rgb = mezclar_color(rgb, CARNE_OSC, estria * 0.45)
    rgb = mezclar_color(rgb, (0.78, 0.42, 0.36), np.clip((n1 - 0.55) * 3, 0, 1) * 0.5)
    vientre = np.clip((-ca - 0.55) / 0.3, 0, 1)
    vientre = vientre * vientre * (3 - 2 * vientre)
    anillo = np.mod(s / 0.52 + 0.15 * (n1 - 0.5), 1.0)
    vent = np.ones((h, w, 3)) * np.array((0.82, 0.63, 0.53))[None, None, :]
    vent = mezclar_color(vent, (0.90, 0.74, 0.62), n1 * 0.5)
    vent *= (0.78 + 0.22 * np.sin(math.pi * anillo))[..., None]
    vent = mezclar_color(vent, (0.46, 0.16, 0.13), np.clip(1 - anillo / 0.07, 0, 1) * 0.75)
    rgb = rgb * (1 - vientre[..., None]) + vent * vientre[..., None]
    rgb = mezclar_color(rgb, (0.80, 0.64, 0.46), np.clip((n2 - 0.62) * 4, 0, 1) * 0.35)   # polvo de arena
    img[y0:y1, x0:x1] = rgb
    # v5: las alturas (para las normales): estrías de la carne y, en el vientre, anillos abombados con surco
    alt[y0:y1, x0:x1] = (-0.5 * estria + 0.25 * n1) * (1 - vientre) + \
        (0.6 * np.sin(math.pi * anillo) - 0.9 * np.clip(1 - anillo / 0.07, 0, 1)) * vientre

    # --- las placas: 4 × 4 losetas de piedra arenisca con canto de bronce, chevrón, desgaste; runas y zarpazos
    y0, y1, x0, x1 = region(AT_PLACA)
    h, w = y1 - y0, x1 - x0
    tl = h // 4
    n1 = fbm(h, w, 40, 40, 21, 4)
    n2 = fbm(h, w, 160, 160, 22, 3)
    rgb = np.ones((h, w, 3)) * np.array(ARMADURA)[None, None, :]
    rgb = mezclar_color(rgb, ARMADURA_OSC, np.clip(n1 - 0.35, 0, 1) * 0.9)
    rgb = mezclar_color(rgb, (0.93, 0.85, 0.70), np.clip((n2 - 0.6) * 3, 0, 1) * 0.5)
    pic = np.clip((0.32 - n2) * 6, 0, 1) * 0.35                                    # picaduras
    rgb = mezclar_color(rgb, (0.42, 0.32, 0.24), pic)
    b = np.zeros((h, w))
    yy, xx = np.mgrid[0:h, 0:w]
    fu = np.mod(xx / tl, 1.0)
    fv = np.mod(yy / tl, 1.0)
    u_ = (fu - 0.04) / 0.92
    v_ = (fv - 0.04) / 0.92
    rgb *= (0.78 + 0.22 * np.clip(v_, 0, 1))[..., None]                             # delante, en la sombra de la anterior
    borde = np.minimum(np.minimum(u_, 1 - u_), np.minimum(v_ * 1.6, 1 - v_))
    rgb = mezclar_color(rgb, BRONCE, np.clip(1 - borde / 0.07, 0, 1) * 0.85)        # el canto de bronce
    rgb = mezclar_color(rgb, (0.30, 0.20, 0.12), np.clip(1 - np.abs(borde - 0.075) / 0.012, 0, 1) * 0.6)
    lomo = np.clip(1 - np.abs(u_ - 0.5) / 0.02, 0, 1) * np.clip(v_ * 2, 0, 1)
    rgb = mezclar_color(rgb, (0.96, 0.9, 0.78), lomo * 0.4)                         # la arista del centro
    pintar_grietas(rgb, b, rng, int(90), w, h, w * 0.012, 6, con_luz=0.0, oscuro=(0.28, 0.2, 0.14))
    lineas_runa, lineas_zarpa = [], []
    for tile in range(16):
        cx, cy = (tile % 4) * tl, (tile // 4) * tl
        if tile == 15:                                  # la testera: runas que nacen del núcleo
            gx, gy = cx + tl * 0.5, cy + tl * (0.04 + 0.92 * 0.72)
            for q in range(9):
                an = math.pi * (0.1 + 0.8 * q / 8) + math.pi
                pts = grieta(rng, gx + math.cos(an) * tl * 0.1, gy + math.sin(an) * tl * 0.1, tl * 0.06, 5, an, giro=0.5)
                lineas_runa.append(pts)
            continue
        if tile in (0, 3, 5, 6, 9, 12, 14):
            for q in range(rng.integers(1, 3)):
                lineas_runa += runa(rng, cx + tl * rng.uniform(0.3, 0.7), cy + tl * rng.uniform(0.2, 0.35), tl * 0.45, tl * 0.12)
        if tile in (2, 7, 10, 13):                      # tres zarpazos paralelos en diagonal
            x_, y_ = cx + tl * rng.uniform(0.25, 0.45), cy + tl * rng.uniform(0.25, 0.4)
            for q in range(3):
                lineas_zarpa.append([(x_ + q * tl * 0.09, y_ + q * tl * 0.03), (x_ + q * tl * 0.09 + tl * 0.28, y_ + q * tl * 0.03 + tl * 0.36)])
    if lineas_zarpa:
        dz = trazos(h, w, lineas_zarpa, 9.0 * k)
        rgb = mezclar_color(rgb, (0.92, 0.80, 0.66), np.clip(1 - np.abs(dz - 5.0 * k) / (1.6 * k), 0, 1) * 0.6)
        rgb = mezclar_color(rgb, (0.50, 0.08, 0.06), np.clip(1 - dz / (3.6 * k), 0, 1) * 0.95)
        rgb = mezclar_color(rgb, (0.22, 0.03, 0.02), np.clip(1 - dz / (1.4 * k), 0, 1) * 0.8)
    if lineas_runa:
        dr = trazos(h, w, lineas_runa, 7.0 * k)
        rgb = mezclar_color(rgb, (0.36, 0.22, 0.10), np.clip(1 - np.abs(dr - 3.2 * k) / (1.2 * k), 0, 1) * 0.6)
        rgb = mezclar_color(rgb, (1.0, 0.80, 0.38), np.clip(1 - dr / (2.2 * k), 0, 1) * 0.95)
        b = np.maximum(b, np.clip(1.5 - dr / (1.8 * k), 0, 1))
    img[y0:y1, x0:x1] = rgb
    brillo[y0:y1, x0:x1] = b
    # v5: el relieve de la placa: el canto biselado, la arista del centro, picaduras, runas grabadas y zarpazos hondos
    a_ = 0.9 * np.sqrt(np.clip(borde / 0.1, 0, 1)) + 0.35 * lomo - 1.2 * pic + 0.3 * n1
    if lineas_runa:
        a_ = a_ - 0.45 * np.clip(1 - dr / (2.6 * k), 0, 1)
    if lineas_zarpa:
        a_ = a_ - 1.0 * np.clip(1 - dz / (3.8 * k), 0, 1)
    alt[y0:y1, x0:x1] = a_

    # --- hueso y piedra (cáscara de la cabeza, cuernos, crestas, marco)
    y0, y1, x0, x1 = region(AT_CABEZA)
    h, w = y1 - y0, x1 - x0
    n1 = fbm(h, w, 24, 24, 31, 4)
    n2 = fbm(h, w, 120, 120, 32, 3)
    vv = ((np.arange(h) + 0.5) / h)[:, None] * np.ones((1, w))
    rgb = np.ones((h, w, 3)) * np.array((0.88, 0.78, 0.62))[None, None, :]
    rgb = mezclar_color(rgb, ARMADURA_OSC, np.clip(n1 - 0.3, 0, 1) * 0.8)
    rgb *= (0.9 + 0.1 * np.sin(vv * 2 * math.pi * 26 + n1 * 4))[..., None]          # anillos de crecimiento
    rgb = mezclar_color(rgb, (0.97, 0.92, 0.82), np.clip((n2 - 0.62) * 3, 0, 1) * 0.5)
    rgb = mezclar_color(rgb, (0.45, 0.33, 0.24), np.clip((0.3 - n2) * 5, 0, 1) * 0.35)
    b = np.zeros((h, w))
    pintar_grietas(rgb, b, rng, 26, w, h, w * 0.025, 6, con_luz=0.0, oscuro=(0.3, 0.22, 0.15))
    vetas = [grieta(rng, rng.uniform(0, w), rng.uniform(0, h), w * 0.03, 6, rng.uniform(0, 6.28), giro=0.6) for _ in range(5)]
    dv = trazos(h, w, vetas, 6.0 * k)
    rgb = mezclar_color(rgb, (1.0, 0.78, 0.36), np.clip(1 - dv / (1.8 * k), 0, 1) * 0.85)
    b = np.maximum(b, np.clip(1.3 - dv / (1.6 * k), 0, 1) * 0.8)
    img[y0:y1, x0:x1] = rgb
    brillo[y0:y1, x0:x1] = b
    alt[y0:y1, x0:x1] = 0.35 * np.sin(vv * 2 * math.pi * 26 + n1 * 4) + 0.5 * n1 - 0.4 * np.clip((0.3 - n2) * 5, 0, 1)

    # --- labios y embudo: carne roja con arrugas radiales, encía clara en el borde y luz cálida al fondo
    y0, y1, x0, x1 = region(AT_CARNE)
    h, w = y1 - y0, x1 - x0
    uu = ((np.arange(w) + 0.5) / w)[None, :] * np.ones((h, 1))
    vv = ((np.arange(h) + 0.5) / h)[:, None] * np.ones((1, w))
    n1 = fbm(h, w, 16, 32, 51, 4)
    n3 = fbm(h, w, 40, 120, 53, 3, envolver=True)
    arruga = (0.5 + 0.5 * np.sin(uu * 2 * math.pi * 36 + 6.0 * n1 + 3.0 * n3)) ** 4 * (0.4 + 0.6 * n3)
    rgb = np.ones((h, w, 3)) * np.array(CARNE)[None, None, :]
    rgb = mezclar_color(rgb, (0.80, 0.42, 0.40), arruga * 0.45 * np.clip(vv * 1.4, 0, 1))
    rgb = mezclar_color(rgb, CARNE_OSC, (1 - arruga) * 0.35)
    rgb = mezclar_color(rgb, ENCIA, np.clip((vv - 0.88) / 0.1, 0, 1) * 0.7)
    anillos_ = (0.5 + 0.5 * np.sin(vv * 2 * math.pi * 16 + 2.0 * n1)) ** 4          # pliegues concéntricos
    rgb = mezclar_color(rgb, CARNE_OSC, anillos_ * 0.45)
    rgb = mezclar_color(rgb, (0.86, 0.5, 0.46), (1 - anillos_) ** 6 * 0.25)
    rgb = mezclar_color(rgb, (0.95, 0.55, 0.22), np.clip((0.3 - vv) / 0.25, 0, 1) * 0.55)   # la luz de la garganta
    b = np.clip((0.26 - vv) / 0.2, 0, 1) * 0.55
    img[y0:y1, x0:x1] = rgb
    brillo[y0:y1, x0:x1] = b
    alt[y0:y1, x0:x1] = 0.8 * arruga - 0.7 * anillos_ + 0.2 * n1

    # --- la vela de las crestas: carne rojiza fina con venas y el borde más claro
    y0, y1, x0, x1 = region(AT_MEMBRANA)
    h, w = y1 - y0, x1 - x0
    vv = ((np.arange(h) + 0.5) / h)[:, None] * np.ones((1, w))
    n1 = fbm(h, w, 12, 30, 61, 4)
    rgb = np.ones((h, w, 3)) * np.array(MEMBRANA)[None, None, :]
    rgb = mezclar_color(rgb, CARNE_OSC, np.clip(n1 - 0.4, 0, 1) * 0.6)
    venas = [grieta(rng, rng.uniform(0, w), 0.0, h * 0.12, 7, math.pi / 2, giro=0.45) for _ in range(9)]
    dv = trazos(h, w, venas, 4.0 * k)
    rgb = mezclar_color(rgb, (0.34, 0.08, 0.07), np.clip(1 - dv / (1.5 * k), 0, 1) * 0.7)
    rgb = mezclar_color(rgb, (0.95, 0.62, 0.50), np.clip((vv - 0.8) / 0.2, 0, 1) * 0.5)
    img[y0:y1, x0:x1] = rgb
    alt[y0:y1, x0:x1] = 0.5 * np.clip(1 - dv / (1.5 * k), 0, 1) + 0.2 * n1

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
    rgb = np.array((0.46, 0.38, 0.30))[None, None, :] * (0.8 + 0.5 * n1)[..., None] * np.ones((h, w, 1))
    rgb = mezclar_color(rgb, (0.66, 0.55, 0.42), capas * 0.4)
    img[y0:y1, x0:x1] = rgb
    # v5: a las alturas de cada zona se suma el detalle fino del color (paso alto de la luminancia: las grietas y las
    # picaduras que el color ya pinta, más oscuras = más hondas)
    lum = img.mean(axis=2)
    alt = alt + 1.6 * (lum - _difuminar(lum, int(max(2, 6 * k))))
    return np.clip(img, 0, 1), np.clip(brillo, 0, 1), alt


def _difuminar(x, r):
    """v5: media por caja (separable) de radio r."""
    k_ = np.ones(2 * r + 1) / (2 * r + 1)
    y = np.apply_along_axis(lambda f: np.convolve(np.pad(f, r, mode="edge"), k_, mode="valid"), 0, x)
    return np.apply_along_axis(lambda f: np.convolve(np.pad(f, r, mode="edge"), k_, mode="valid"), 1, y)


def normales_de(alt, fuerza, n_px):
    """v5: el mapa de normales (espacio tangente, convenio OpenGL: verde hacia +v, como lo lee Godot) de las alturas,
    reducido a n_px. Las filas del array van de v = 0 (abajo) a v = 1, como la textura."""
    f = alt.shape[0] // n_px
    a = alt.reshape(n_px, f, n_px, f).mean(axis=(1, 3)) if f > 1 else alt
    dv, du = np.gradient(a)
    escala = fuerza * n_px / 1024.0
    nx, ny, nz = -du * escala, -dv * escala, np.ones_like(a)
    l = np.sqrt(nx * nx + ny * ny + nz * nz)
    return np.stack([nx / l * 0.5 + 0.5, ny / l * 0.5 + 0.5, nz / l * 0.5 + 0.5], axis=2)


def guardar_normales(ruta, rgb):
    n = rgb.shape[0]
    im = bpy.data.images.new(os.path.basename(ruta), n, n, alpha=False)
    im.colorspace_settings.name = "Non-Color"
    px = np.concatenate([rgb, np.ones((n, n, 1))], axis=2).astype(np.float32)
    im.pixels.foreach_set(px.ravel())
    im.filepath_raw = ruta
    im.file_format = "WEBP"
    im.save(quality=95)
    bpy.data.images.remove(im)


# ---------------------------------------------------------------- (copia literal de crear_bramavidrio3.py)

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
    """Los materiales de Blender (para las fotos; en Godot los pone bramavidrio4_3d.gd por nombre de superficie). v4: la
    luz es ámbar (runas, núcleo y garganta), no cian."""
    m = bpy.data.materials.new(nombre)
    m.use_backface_culling = nombre not in ("chorro", "polvo") and os.environ.get("BRAMA_SIN_CULL", "") != "1"
    if hasattr(m, "use_nodes"):
        m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    vc = nt.nodes.new("ShaderNodeVertexColor")
    vc.layer_name = "Color"
    gam = nt.nodes.new("ShaderNodeGamma")
    gam.inputs["Gamma"].default_value = 2.2
    nt.links.new(vc.outputs["Color"], gam.inputs["Color"])
    bsdf.inputs["Roughness"].default_value = 0.72
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
        em.inputs[0].default_value = lineal((1.0, 0.72, 0.3))
        nt.links.new(rango.outputs["Result"], em.inputs["Scale"])
        nt.links.new(em.outputs["Vector"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = 1.4
        if nombre == "piel" and RUTA_NORMAL:                     # v5: las normales horneadas (también en las fotos)
            tn = nt.nodes.new("ShaderNodeTexImage")
            tn.image = bpy.data.images.load(RUTA_NORMAL, check_existing=True)
            tn.image.colorspace_settings.name = "Non-Color"
            nm = nt.nodes.new("ShaderNodeNormalMap")
            nm.uv_map = "UVMap"
            nm.inputs["Strength"].default_value = 1.0
            nt.links.new(tn.outputs["Color"], nm.inputs["Color"])
            nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    else:
        nt.links.new(gam.outputs["Color"], bsdf.inputs["Base Color"])
        if nombre in ("vidrio", "garganta", "chorro", "polvo"):
            nt.links.new(gam.outputs["Color"], bsdf.inputs["Emission Color"])
            bsdf.inputs["Emission Strength"].default_value = {"vidrio": 2.0, "garganta": 4.0, "chorro": 3.0, "polvo": 1.0}[nombre]
            bsdf.inputs["Roughness"].default_value = 0.15
    if nombre in ("chorro", "polvo"):
        try:
            m.surface_render_method = 'BLENDED'
        except Exception:
            pass
    return m


# ---------------------------------------------------------------- (copia literal de crear_bramavidrio3.py)

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


def guardar_png(ruta, px):
    h, w = px.shape[:2]
    out = bpy.data.images.new(os.path.basename(ruta), w, h, alpha=True)
    out.pixels.foreach_set(px.ravel())
    out.filepath_raw = ruta
    out.file_format = "PNG"
    out.save()
    bpy.data.images.remove(out)
    print("PNG", ruta, w, h)

# ---------------------------------------------------------------- v4: fotos de Blender por etapas (frente a la lámina)

TRES_CUARTOS = (-48.0, -36.0, 12.6)            # la vista del combate (la misma dirección que la cámara de Godot)


def pose_lamina(alza=14.0, giro=0.0, boca=BOCA_ABIERTA):
    """Tendido sobre la arena como en la vista de perfil y la principal de la lámina, con la cabeza algo alzada."""
    return Pose([(-6, alza), (0, alza), (2.5, alza * 0.35), (5, 0), (22, -1)], ua=0.0, ap=(0, 0, 1.95), cab=(0, giro, 0),
                boca=boca, placas=4.0, brillo=1.2, garganta=1.2)


def pose_erguida(boca=BOCA_ABIERTA):
    """Erguido, con la cabeza inclinada hacia quien mira (las vistas de frente y de espalda de la lámina)."""
    return Pose([(-6, 4), (0, 8), (2, 30), (4, 66), (6, 86), (22, 88)], ua=11.0, boca=boca, placas=4.0, brillo=1.2,
                garganta=1.2)


def escena_fotos(sc, calida=True):
    motor_eevee(sc)
    suelo = luces_y_suelo(sc)
    if calida:                                                    # la luz de la lámina: cálida y dorada
        fondo = sc.world.node_tree.nodes.get("Background")
        fondo.inputs["Color"].default_value = (0.86, 0.66, 0.44, 1)
        fondo.inputs["Strength"].default_value = 0.85
        for o in sc.objects:
            if o.type == 'LIGHT' and o.name.startswith("sol"):
                o.data.color = (1.0, 0.86, 0.66)
                o.data.energy = 3.6
            elif o.type == 'LIGHT':
                o.data.color = (0.95, 0.78, 0.6)
                o.data.energy = 0.9
    try:
        sc.eevee.use_shadows = True
        sc.eevee.shadow_pool_size = '1024'
    except Exception:
        pass
    return suelo


def foto(sc, arm, ruta, pose=None, clip=None, seg=0.0, pos=(0, -60, 8), mira=(0, 0, 0), escala=12.0, ancho=640, alto=480):
    ad = arm.animation_data
    for t in ad.nla_tracks:
        t.mute = True
    if clip:
        ad.action = bpy.data.actions[clip]
        sc.frame_set(int(round(seg * FPS)) + 1)
    else:
        ad.action = None
        bpy.context.view_layer.objects.active = arm
        poner_pose(arm, pose)
        sc.frame_set(1)
    cam = camara(sc, pos, mira, escala, ancho, alto)
    sc.render.filepath = ruta
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam)
    ad.action = None
    return ruta


def hoja(rutas, salida, columnas):
    """Compone las fotos (todas del mismo tamaño) en una rejilla."""
    ims = []
    for r in rutas:
        im = bpy.data.images.load(r)
        ims.append(np.array(im.pixels[:], dtype=np.float32).reshape(im.size[1], im.size[0], 4)[::-1])
        bpy.data.images.remove(im)
    h, w = ims[0].shape[:2]
    while len(ims) % columnas:
        ims.append(np.ones((h, w, 4), np.float32) * np.array([0.1, 0.1, 0.12, 1.0], np.float32))
    filas = [np.concatenate(ims[i:i + columnas], axis=1) for i in range(0, len(ims), columnas)]
    guardar_png(salida, np.ascontiguousarray(np.concatenate(filas, axis=0)[::-1]))


def cabeza_mundo(arm, pose):
    G, P = matrices_globales(arm, pose)
    Mc = G["cabeza"] @ arm.data.bones["cabeza"].matrix_local.inverted()
    return Mc, Mc @ Vector((0.0, -1.0, 0.0)), Mc @ P_BOCA()


def vistas_cuerpo(arm, pose_l, pose_e):
    """Las cuatro vistas de la lámina: frente (erguido), perfil (tendido), tres cuartos (la principal) y espalda."""
    Mc, _, boca_e = cabeza_mundo(arm, pose_e)
    Ml, _, boca_l = cabeza_mundo(arm, pose_l)
    cen_e = Vector((0.0, boca_e.y + 2.5, boca_e.z - 4.5))
    return [("frente", pose_e, (cen_e + Vector((0.0, -60.0, 4.0)), cen_e, 15.5)),
            ("perfil", pose_l, (Vector((60.0, 9.0, 6.0)), Vector((0.0, 9.0, 2.6)), 31.0)),
            ("tres_cuartos", pose_l, (boca_l + Vector((-34.0, -30.0, 14.0)), boca_l + Vector((-0.5, 6.0, -0.8)), 21.0)),
            ("espalda", pose_e, (cen_e + Vector((0.0, 60.0, 9.0)), cen_e + Vector((0.0, 2.0, 0.0)), 15.5))]


def etapas(carpeta, arm, obj):
    """Las fotos de Blender de las etapas 1 a 5 (la 6 es Godot) y los dos vídeos."""
    sc = bpy.context.scene
    escena_fotos(sc)
    os.makedirs(carpeta, exist_ok=True)
    pl = pose_lamina(alza=16.0)
    pe = pose_erguida()
    munecos = []
    for pos in ((-1.0, -16.5, 0.0), (2.8, -19.0, 0.0), (-3.4, -19.6, 0.0)):
        munecos += heroe_escala(sc, pos, 4.2)
    for o in munecos:
        o.hide_render = True
    hecho = {}
    quiere = lambda e: not SOLO_ETAPAS or e in SOLO_ETAPAS
    # 1) silueta y proporciones: arcilla
    if quiere("1"):
        arcilla = bpy.data.materials.new("arcilla")
        arcilla.use_nodes = True
        arcilla.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.62, 0.55, 0.47, 1)
        bpy.context.view_layer.material_override = arcilla
        rutas = [foto(sc, arm, os.path.join(carpeta, "etapa1_%s.png" % n), pose=p, pos=v[0], mira=v[1], escala=v[2])
                 for (n, p, v) in vistas_cuerpo(arm, pl, pe)]
        bpy.context.view_layer.material_override = None
        hoja(rutas, os.path.join(carpeta, "etapa1_hoja.png"), 4)
        hecho["1"] = rutas
    # 2) cabeza, boca y garganta: abierta, a medias y cerrada, de frente y de tres cuartos, y el interior
    if quiere("2"):
        rutas = []
        pc = pose_lamina(alza=10.0)
        Mc, fwd, boca_l = cabeza_mundo(arm, pc)
        cab_c = boca_l + (Mc @ Vector((0.0, 1.0, 0.0)) - Mc @ Vector((0.0, 0.0, 0.0))) * 1.2
        for (n, b) in (("abierta", BOCA_ABIERTA), ("media", 0.5 * BOCA_ABIERTA), ("cerrada", 0.0)):
            p = pose_lamina(alza=10.0, boca=b)
            rutas.append(foto(sc, arm, os.path.join(carpeta, "etapa2_frente_%s.png" % n), pose=p,
                              pos=boca_l + Vector((0.0, -60.0, 2.0)), mira=cab_c + Vector((0.0, 0.0, 0.6)), escala=8.6))
            rutas.append(foto(sc, arm, os.path.join(carpeta, "etapa2_34_%s.png" % n), pose=p,
                              pos=boca_l + Vector((-40.0, -40.0, 14.0)), mira=cab_c + Vector((0.0, 0.0, 0.4)), escala=9.5))
            # v5: y de perfil en los tres estados (la misma cámara que «etapa2_perfil_cabeza» de la v4)
            rutas.append(foto(sc, arm, os.path.join(carpeta, "etapa2_perfil_%s.png" % n), pose=p,
                              pos=boca_l + Vector((60.0, 1.5, 3.0)), mira=cab_c + Vector((0.0, 0.8, 0.8)), escala=10.0))
        rutas.append(foto(sc, arm, os.path.join(carpeta, "etapa2_interior.png"), pose=pc,
                          pos=boca_l + Vector((-12.0, -60.0, 8.0)), mira=boca_l + Vector((0.0, 0.5, 0.0)), escala=5.2))
        rutas.append(foto(sc, arm, os.path.join(carpeta, "etapa2_perfil_cabeza.png"), pose=pose_lamina(alza=10.0, boca=0.0),
                          pos=boca_l + Vector((60.0, 1.5, 3.0)), mira=cab_c + Vector((0.0, 0.8, 0.8)), escala=10.0))
        hoja(rutas, os.path.join(carpeta, "etapa2_hoja.png"), 4)
        hecho["2"] = rutas
    # 3) materiales: las cuatro vistas con la textura, y detalles (placa con runa y zarpazo, cresta y vela, cola)
    if quiere("3"):
        rutas = [foto(sc, arm, os.path.join(carpeta, "etapa3_%s.png" % n), pose=p, pos=v[0], mira=v[1], escala=v[2])
                 for (n, p, v) in vistas_cuerpo(arm, pl, pe)]
        G, P = matrices_globales(arm, pl)
        for (n, u, off, esc) in (("detalle_placas", 6.0, Vector((-30.0, -6.0, 18.0)), 6.0),
                                 ("detalle_cresta", 4.6, Vector((-40.0, 4.0, 10.0)), 6.5),
                                 ("detalle_cola", 19.5, Vector((-30.0, 20.0, 14.0)), 6.0),
                                 ("detalle_corona", -0.5, Vector((-24.0, -30.0, 22.0)), 7.5)):
            c = punto(P, u) + Vector((0.0, 0.0, 1.6 if n != "detalle_cola" else 0.6))
            rutas.append(foto(sc, arm, os.path.join(carpeta, "etapa3_%s.png" % n), pose=pl, pos=c + off, mira=c, escala=esc))
        hoja(rutas, os.path.join(carpeta, "etapa3_hoja.png"), 4)
        hecho["3"] = rutas
    # 4) rig y deformaciones: la boca de cerrada a abierta de más (de frente), el cuerpo en S y las crestas erizadas
    if quiere("4"):
        rutas = []
        pc = pose_lamina(alza=10.0)
        Mc, fwd, boca_l = cabeza_mundo(arm, pc)
        for a in (0.0, 0.25, 0.5, 0.75, 1.0, 1.12):
            p = pose_lamina(alza=10.0, boca=a * BOCA_ABIERTA)
            rutas.append(foto(sc, arm, os.path.join(carpeta, "etapa4_boca_%03d.png" % int(round(a * 100))), pose=p,
                              pos=boca_l + Vector((-22.0, -60.0, 10.0)), mira=boca_l + Vector((0.0, 0.8, 0.3)), escala=7.0))
        s_ = Pose([(-6, 20), (0, 20), (3, 40), (6, 70), (9, 86), (22, 80)], ps=[(-6, -30), (2, -30), (6, 25), (10, 0)],
                  ua=11.0, boca=0.0, placas=26.0)
        rutas.append(foto(sc, arm, os.path.join(carpeta, "etapa4_curva_s.png"), pose=s_, pos=Vector(TRES_CUARTOS),
                          mira=Vector((-0.5, -6.0, 6.0)), escala=22.0))
        rutas.append(foto(sc, arm, os.path.join(carpeta, "etapa4_crestas_erizadas.png"), pose=pose_lamina(alza=16.0).con(placas=30.0),
                          pos=Vector((60.0, 9.0, 6.0)), mira=Vector((0.0, 9.0, 2.6)), escala=31.0))
        hoja(rutas, os.path.join(carpeta, "etapa4_hoja.png"), 4)
        hecho["4"] = rutas
    # 5) animaciones: los clips en la vista del combate, con tres muñecos de los héroes a su escala
    if quiere("5"):
        for o in munecos:
            o.hide_render = False
        rutas = []
        for (clip, seg) in (("reposo", 0.0), ("emerger", 0.87), ("rugido", 1.2), ("ataque", 0.7), ("ataque", 0.9),
                            ("ataque", 1.0), ("ataque_sismico", 1.5), ("ataque_sismico", 2.5333), ("ataque_aliento", 1.2),
                            ("ataque_aliento", 2.0), ("herida", 0.1), ("derrota", 1.6), ("derrota", 3.4)):
            rutas.append(foto(sc, arm, os.path.join(carpeta, "etapa5_%s_%.2f.png" % (clip, seg)), clip=clip, seg=seg,
                              pos=Vector(TRES_CUARTOS), mira=Vector((-0.5, -9.5, 6.0)), escala=27.0))
        hoja(rutas, os.path.join(carpeta, "etapa5_hoja.png"), 4)
        for o in munecos:
            o.hide_render = True
        hecho["5"] = rutas
    if quiere("video"):
        Mc, fwd, boca_r = cabeza_mundo(arm, R0)
        # v5: la boca de cerca (rugido y embestida) y cada clip en la vista del combate con los muñecos
        video(sc, arm, os.path.join(carpeta, "v5_boca_rugido.mp4"), "rugido", boca_r + Vector((-26.0, -60.0, 10.0)),
              boca_r + Vector((0.0, 1.0, 0.0)), 11.0)
        video(sc, arm, os.path.join(carpeta, "v5_boca_embestida.mp4"), "ataque", boca_r + Vector((-26.0, -60.0, 10.0)),
              boca_r + Vector((0.0, -3.0, -2.0)), 16.0)
        for o in munecos:
            o.hide_render = False
        for clip in ("reposo", "emerger", "rugido", "ataque", "ataque_sismico", "ataque_aliento", "herida", "derrota"):
            video(sc, arm, os.path.join(carpeta, "v5_combate_%s.mp4" % clip), clip, Vector(TRES_CUARTOS),
                  Vector((-0.5, -9.5, 6.0)), 27.0)
        for o in munecos:
            o.hide_render = True
    return hecho


def video(sc, arm, ruta, clip, pos, mira, escala, ancho=640, alto=480):
    """Un vídeo del clip a velocidad real con el FFmpeg de Blender (sin instalar nada)."""
    ad = arm.animation_data
    for t in ad.nla_tracks:
        t.mute = True
    ad.action = bpy.data.actions[clip]
    n = int(round(bpy.data.actions[clip].frame_range[1]))
    sc.frame_start, sc.frame_end = 1, n
    cam = camara(sc, pos, mira, escala, ancho, alto)
    im = sc.render.image_settings
    try:
        im.media_type = 'VIDEO'
    except Exception:
        pass
    im.file_format = 'FFMPEG'
    sc.render.ffmpeg.format = 'MPEG4'
    sc.render.ffmpeg.codec = 'H264'
    try:
        sc.render.ffmpeg.constant_rate_factor = 'HIGH'
    except Exception:
        pass
    sc.render.filepath = ruta
    bpy.ops.render.render(animation=True)
    try:
        im.media_type = 'IMAGE'
    except Exception:
        pass
    im.file_format = 'PNG'
    bpy.data.objects.remove(cam)
    ad.action = None
    print("VIDEO", ruta)


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


def modelo(carpeta, perfiles, prefijo, fotos=""):
    """Las versiones pedidas (mismos huesos y clips), sus texturas y el JSON de clips. Con fotos: las de Blender."""
    global R0
    os.makedirs(carpeta, exist_ok=True)
    global RUTA_NORMAL
    rgb, a, alt = pintar_textura(TEX)
    rutas_tex = {}
    for perfil, f, suf in (("alto", 1, ""), ("medio", 2, "_medio"), ("bajo", 4, "_bajo")):
        if perfil not in perfiles:
            continue
        r, al = (rgb, a) if f == 1 else reducir(rgb, a, f)
        ruta = os.path.join(carpeta, "%s_piel%s.webp" % (prefijo, suf))
        guardar_textura(ruta, r, al)
        rutas_tex[perfil] = ruta
        print("TEXTURA", ruta, r.shape[0], os.path.getsize(ruta))
    # v5: las normales horneadas de las alturas: 1024 en el alto y 512 en el medio (el bajo, sin ellas: en el móvil
    # modesto no compensan una lectura de textura más)
    for perfil, n_px, suf in (("alto", NORMAL_ALTO, ""), ("medio", NORMAL_MEDIO, "_medio")):
        if perfil not in perfiles:
            continue
        ruta = os.path.join(carpeta, "%s_normal%s.webp" % (prefijo, suf))
        guardar_normales(ruta, normales_de(alt, FUERZA_NORMAL, n_px))
        if perfil == "alto":
            RUTA_NORMAL = ruta
        print("NORMALES", ruta, n_px, os.path.getsize(ruta))
    sc, arm = preparar_esqueleto()
    resumen = {"fps": FPS, "variante": VARIANTE, "huesos": NOMBRES, "clips": {}, "triangulos": {}, "texturas": {},
               "ajustes": dict(AJUSTE), "losas_centro": [round(LOSAS_CENTRO.x, 3), round(LOSAS_CENTRO.y, 3)],
               "puntos": {"hocico": a_godot(P_HOCICO()), "boca": a_godot(P_BOCA()), "garganta": a_godot(P_GARGANTA()),
                          "esfinter": a_godot(C_ESF)},
               "boca_v5": {"r_labio": R_LABIO, "r_boca": R_BOCA, "s_min": S_MIN, "t_cierre": T_CIERRE,
                           "boca_abierta": BOCA_ABIERTA, "pend": round(PEND, 4),
                           "mandibulas": [{"nombre": m[0], "angulo": m[1], "largo": m[4], "colmillos": m[5]} for m in MANDIBULAS],
                           "r_bisagra": R_BISAGRA, "y_bisagra": round(Y_BISAGRA, 3), "beta_abierta": BETA_ABIERTA,
                           "beta_cerrada": BETA_CERRADA, "beta_de_mas": BETA_DE_MAS, "pliegue": PLIEGUE}}
    construir("alto")                                    # v5: solo para apuntar las puntas de la corona (encuadre)
    resumen["corona"] = [a_godot(p) for p in PUNTAS_CORONA]
    for nombre, f in CLIPS.items():
        poses, marcas = f()
        medidas = crear_accion(arm, nombre, poses)
        m, extra = instantes(nombre, medidas, marcas)
        extra["boca_max"] = round(max(x["boca"] for x in medidas), 2)
        extra["corona_max_z"] = round(max(x["corona"] for x in medidas), 3)          # v5: lo más alto de la corona
        extra["corona_max_z_s"] = round(max(range(len(medidas)), key=lambda q: medidas[q]["corona"]) / FPS, 3)
        extra["abertura_max_reposo_m"] = round(max(x["cierre"] for x, p in zip(medidas, poses) if p.boca <= 0.0), 4) \
            if any(p.boca <= 0.0 for p in poses) else None
        resumen["clips"][nombre] = {"duracion": round((len(poses) - 1) / FPS, 4), "bucle": nombre in BUCLES,
                                    "instantes": m, **extra}
        print("CLIP", nombre, resumen["clips"][nombre])
    resumen["esfinter"] = comprobar_esfinter()
    resumen["garganta_desde_camara"] = comprobar_garganta()
    print("ESFINTER", resumen["esfinter"])
    print("GARGANTA", {k: v for k, v in resumen["garganta_desde_camara"].items() if k != "fotogramas"})
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
        cuenta = {}
        for f_, e in zip(M.caras, M.etq):
            g_ = e.split("_")[0]
            cuenta[g_] = cuenta.get(g_, 0) + len(f_) - 2
        resumen.setdefault("triangulos_por_parte", {})[perfil] = cuenta
        print("MALLA", perfil, "vértices", len(M.v), "triángulos", tris, cuenta)
        suf = "" if perfil == "alto" else "_" + perfil
        exportar(os.path.join(carpeta, "%s%s.glb" % (prefijo, suf)))
        if perfil == "alto":
            if SALIDA_BLEND:
                bpy.ops.wm.save_as_mainfile(filepath=SALIDA_BLEND)
                print("GUARDADO", SALIDA_BLEND)
            # v5: TODOS los clips, cada PASO_ROCES segundos (y los instantes clave del contrato)
            pedidos = []
            for nombre_c in CLIPS:
                dur = resumen["clips"][nombre_c]["duracion"]
                segs = [round(q * PASO_ROCES, 4) for q in range(int(dur / PASO_ROCES + 1e-6) + 1)]
                segs += [float(v) for v in resumen["clips"][nombre_c]["instantes"].values() if v not in segs]
                pedidos.append((nombre_c, sorted(set(segs))))
            resumen["intersecciones"] = comprobar_intersecciones(arm, obj, M, pedidos)
            resumen["piel_boca_estiramiento"] = dict(ESTIRA_PIEL)        # v5, 2.ª vuelta
            resumen["separacion_bisagra_m"] = dict(SEPARA_BISAGRA)
            print("SEPARA_BISAGRA", SEPARA_BISAGRA)
            print("PIEL_BOCA", ESTIRA_PIEL)
            resumen["intersecciones_total"] = {c_: sum(f_["total"] for f_ in filas_)
                                               for c_, filas_ in resumen["intersecciones"].items()}
            print("INTERSECCIONES_TOTAL", resumen["intersecciones_total"])
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
        etapas(fotos, arm, obj_alto)
    return resumen


def principal():
    os.makedirs(CARPETA, exist_ok=True)
    modelo(CARPETA, PERFILES, PREFIJO, fotos=CARPETA_FOTOS)


principal()
