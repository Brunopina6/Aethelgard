# Naira, «la Astrónoma del Eclipse» (nombre provisional): TRES CONCEPTOS 3D (forma y color, no finales).
# 12/11/2026, especialista de animaciones. Obra propia por guion (Blender 5.2.3), sin recursos externos.
#
#   blender -b --factory-startup -P naira_conceptos.py -- <raíz aethelgard> <carpeta de láminas> <A|B|C|comparativa>
#
#   A «La Viajera del Eclipse»: capa corta con capucha y forro de mapa estelar, faldones de tres largos, bufanda de
#     lino, botas de camino y un ASTROLABIO de latón a la cadera que flota y se abre al lanzar.
#   B «La Archivista de Constelaciones»: abrigo largo de erudita con forro violeta y mangas acampanadas, gafas
#     redondas, trenza sobre el hombro, cinturones con estuches, un tomo encadenado y un BASTÓN-CATALEJO.
#   C «La Portadora del Eclipse»: media capa sujeta a un hombro (larga a un lado), tabardo bordado de constelaciones,
#     pelo largo liso, ojos de eclipse y un PLANETARIO de aros que flota a su espalda.
#
# Las tres comparten cuerpo, cara, pelo oscuro con reflejos azules y esqueleto (naira_comun.py).
import bpy, sys, os, math
from mathutils import Vector, Euler

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import naira_comun as N   # noqa: E402
from naira_comun import C, esp   # noqa: E402

argv = sys.argv[sys.argv.index("--") + 1:]
RAIZ, LAMINAS, QUE = argv[0], argv[1], argv[2]
os.makedirs(LAMINAS, exist_ok=True)

NOMBRES = {"A": "A · La Viajera del Eclipse", "B": "B · La Archivista de Constelaciones",
           "C": "C · La Portadora del Eclipse"}
PI = math.pi

# ------------------------------------------------------------------ paletas

PIEL = (0.96, 0.84, 0.77)
PELO = [(0.030, 0.033, 0.065), (0.040, 0.045, 0.090), (0.075, 0.105, 0.230), (0.110, 0.165, 0.340),
        (0.060, 0.075, 0.160), (0.045, 0.052, 0.110)]


def paleta(A, c):
    P = {"piel": PIEL, "rubor": (0.96, 0.56, 0.58), "pestanas": (0.05, 0.05, 0.11), "cejas": (0.08, 0.09, 0.18),
         "labios": (0.62, 0.30, 0.34), "estrella_ojo": (1.0, 0.97, 0.85)}
    A.muestra("piel_plana", PIEL, plano=True)
    A.muestra("piel_cuerpo", PIEL, oscuro=0.92, claro=1.02, grano=0)
    N.dibujar_parpado(A, "parpado", PIEL, (0.05, 0.05, 0.11))
    N.muestra_bandas(A, "pelo", PELO)
    A.muestra("pelo_casquete", (0.036, 0.040, 0.080), oscuro=0.9, claro=1.25, grano=0.02)
    A.muestra("suela", (0.14, 0.11, 0.10))
    A.muestra("laton", (0.86, 0.67, 0.34), oscuro=0.75, claro=1.12, grano=0.0)
    A.muestra("laton_osc", (0.55, 0.40, 0.20), oscuro=0.85, claro=1.05, grano=0.0)
    if c == "A":
        P.update(iris_arriba=(0.42, 0.20, 0.05), iris_abajo=(1.0, 0.78, 0.30))
        A.muestra("tunica", (0.22, 0.15, 0.25), oscuro=0.8)
        A.muestra("manga", (0.20, 0.14, 0.23), oscuro=0.85)
        A.muestra("medias", (0.10, 0.10, 0.15), oscuro=0.8)
        A.muestra("guante", (0.24, 0.16, 0.12))
        A.muestra("botas", (0.38, 0.23, 0.14), oscuro=0.7)
        A.muestra("cuero", (0.30, 0.19, 0.12))
        A.muestra("bufanda", (0.90, 0.86, 0.76), oscuro=0.86)
        N.muestra_corte(A, "abrigo", (0.13, 0.15, 0.33), (0.78, 0.60, 0.30), 0.95)
        N.muestra_corte(A, "falda", (0.32, 0.18, 0.31), (0.12, 0.13, 0.28), 0.93)
        N.muestra_corte(A, "capa", (0.12, 0.14, 0.31), (0.78, 0.60, 0.30), 0.92)
        N.dibujar_estrellas(A, "detalle", (0.10, 0.12, 0.30), (0.05, 0.06, 0.16), semilla=5)
    elif c == "B":
        P.update(iris_arriba=(0.24, 0.10, 0.40), iris_abajo=(0.80, 0.60, 1.0))
        A.muestra("tunica", (0.26, 0.28, 0.34), oscuro=0.8)          # chaleco pizarra
        A.muestra("manga", (0.07, 0.13, 0.18), oscuro=0.9)           # el brazo bajo la manga, del color del abrigo
        A.muestra("medias", (0.13, 0.12, 0.17), oscuro=0.85)
        A.muestra("guante", (0.90, 0.86, 0.76))
        A.muestra("botas", (0.20, 0.14, 0.12), oscuro=0.7)
        A.muestra("cuero", (0.42, 0.26, 0.15))
        A.muestra("lino", (0.92, 0.88, 0.78), oscuro=0.9)
        A.muestra("tomo", (0.30, 0.18, 0.13), oscuro=0.75)
        A.muestra("paginas", (0.93, 0.88, 0.74), oscuro=0.9)
        A.muestra("madera", (0.22, 0.14, 0.10), oscuro=0.8)
        N.muestra_corte(A, "abrigo", (0.07, 0.13, 0.18), (0.40, 0.25, 0.56), 0.95)
        N.muestra_corte(A, "violeta", (0.38, 0.23, 0.55), (0.38, 0.23, 0.55), 0.99)
        N.dibujar_estrellas(A, "detalle", (0.30, 0.20, 0.46), (0.18, 0.10, 0.30), semilla=8, lineas=True)
    else:
        P.update(iris_arriba=(0.45, 0.22, 0.05), iris_abajo=(1.0, 0.80, 0.35), eclipse=True,
                 corona=(1.0, 0.86, 0.48))
        A.muestra("tunica", (0.27, 0.15, 0.30), oscuro=0.8)          # corpiño ciruela
        A.muestra("manga", (0.12, 0.09, 0.17), oscuro=0.85)
        A.muestra("medias", (0.08, 0.08, 0.12), oscuro=0.85)
        A.muestra("guante", (0.12, 0.09, 0.17))
        A.muestra("botas", (0.14, 0.11, 0.17), oscuro=0.7)
        A.muestra("cuero", (0.20, 0.13, 0.17))
        A.muestra("oro", (0.90, 0.82, 0.60), oscuro=0.8, claro=1.1, grano=0)
        A.muestra("tomo", (0.18, 0.11, 0.24), oscuro=0.75)
        A.muestra("paginas", (0.93, 0.88, 0.74), oscuro=0.9)
        N.muestra_corte(A, "capa", (0.10, 0.07, 0.15), (0.90, 0.82, 0.60), 0.96)
        N.muestra_corte(A, "pantalon", (0.13, 0.10, 0.20), (0.90, 0.82, 0.60), 0.95)
        N.muestra_corte(A, "faja", (0.20, 0.12, 0.26), (0.90, 0.82, 0.60), 0.80)
        N.dibujar_estrellas(A, "detalle", (0.20, 0.12, 0.34), (0.08, 0.05, 0.16), semilla=13)
    for k in list(A.muestras):
        P.setdefault(k, k)
    return P


# ------------------------------------------------------------------ pelo

def pelo_A(M, P):
    """Media melena a la mandíbula con las puntas hacia dentro, flequillo de lado y un mechón largo a su izquierda
    con una horquilla de luna creciente."""
    N.casquete(M, P["pelo_casquete"])
    for i, ph in enumerate([-0.86, -0.69, -0.52, -0.35, -0.18, 0.0, 0.18, 0.35, 0.52, 0.69, 0.86]):
        th1 = 1.30 + (0.07 if i % 2 else 0.0) - 0.04 * abs(ph)
        N.mechon(M, N.camino_mechon(ph, 0.22, th1, None, vol=0.12, barrido=-0.22, n1=8), 0.050, 0.014, ph,
                 P["pelo"])
    for ph in (1.0, 1.25, -1.0, -1.25):
        N.mechon(M, N.camino_mechon(ph, 0.35, 1.50, 1.205, vol=0.12, flare=0.01, rizo=0.018), 0.05, 0.015, ph,
                 P["pelo"])
    for ph in [1.5, 1.8, 2.1, 2.4, 2.7, 2.95, PI, -1.5, -1.8, -2.1, -2.4, -2.7, -2.95]:
        z = 1.205 + 0.03 * (abs(ph) - 1.5) / 1.6
        N.mechon(M, N.camino_mechon(ph, 0.25, 1.55, z, vol=0.13, flare=0.018, rizo=0.022), 0.058, 0.016, ph,
                 P["pelo"])
    # el mechón largo (su izquierda), por delante de la capa
    pts = [N.punto_cab(0.55, 0.95, 1.10), N.punto_cab(1.1, 1.0, 1.14), N.punto_cab(1.5, 1.0, 1.16),
           Vector((0.15, -0.12, 1.19)), Vector((0.168, -0.168, 1.09)), Vector((0.168, -0.19, 1.0)),
           Vector((0.16, -0.185, 0.93))]
    N.mechon(M, pts, 0.036, 0.013, 1.0, P["pelo"], pesos=N.pesos_pelo_largo, lados=6)
    # horquilla de luna creciente con una estrellita
    c = N.punto_cab(0.95, 1.18, 1.16)
    n = (c - N.CAB_C).normalized()
    M.pintar(N.aro(M, c, n, 0.024, 0.0045, 6, 18, arco=(40, 290)), P["laton"], mat=2, pesos="cabeza")
    M.pintar(N.estrella(M, c + n * 0.006, n, 0.012, 0.003), P["laton"], mat=1, pesos="cabeza")


def pelo_B(M, P):
    """Flequillo barrido a su izquierda, lo demás recogido en una trenza gruesa sobre el hombro derecho."""
    N.casquete(M, P["pelo_casquete"], nuca=-0.12)
    for i, ph in enumerate([-0.75, -0.52, -0.30, -0.08, 0.14, 0.36, 0.58, 0.80]):
        th1 = 1.28 + (0.06 if i % 2 else 0.0)
        N.mechon(M, N.camino_mechon(ph, 0.25, th1, None, vol=0.11, barrido=0.30, n1=8), 0.046, 0.013, ph,
                 P["pelo"])
    for ph in (1.05, -1.05):     # mechones que enmarcan la cara hasta la barbilla
        N.mechon(M, N.camino_mechon(ph, 0.4, 1.5, 1.17, vol=0.11, flare=0.0, rizo=0.0), 0.034, 0.012, ph, P["pelo"])
    for ph in [1.4, 1.75, 2.1, 2.45, 2.8, PI, -1.4, -1.75, -2.1, -2.45, -2.8]:
        # todo hacia la nuca, donde nace la trenza (un poco a su derecha)
        hacia_atras = math.copysign(PI - abs(ph), ph) * 0.55 - 0.18
        N.mechon(M, N.camino_mechon(ph, 0.25, 1.95, None, vol=0.07, barrido=hacia_atras, n1=8), 0.06, 0.014, ph,
                 P["pelo"])
    camino = [Vector((-0.07, 0.12, 1.21)), Vector((-0.14, 0.06, 1.15)), Vector((-0.172, -0.04, 1.09)),
              Vector((-0.168, -0.115, 1.0)), Vector((-0.155, -0.135, 0.90)), Vector((-0.148, -0.13, 0.82))]
    # trenza: eslabones inclinados a uno y otro lado
    pts = []
    for a, b in zip(camino, camino[1:]):
        for k in range(3):
            pts.append(a + (b - a) * (k / 3))
    pts.append(camino[-1])
    for i, (p, q) in enumerate(zip(pts, pts[1:])):
        d = (q - p)
        r = 0.031 - 0.010 * i / len(pts)
        giro = d.to_track_quat('Z', 'Y') @ Euler((0, 0.5 if i % 2 else -0.5, 0)).to_quaternion()
        M.pintar(M.esfera((p + q) / 2, (r, r * 0.8, d.length * 0.75), (10, 6), giro=giro), P["pelo"],
                 pesos=N.pesos_pelo_largo)
    fin = camino[-1]
    M.pintar(N.aro(M, fin + Vector((0, 0, 0.012)), (0, 0, 1), 0.02, 0.005, 6, 16), P["laton"], mat=2,
             pesos=N.pesos_pelo_largo)
    N.mechon(M, [fin, fin + Vector((-0.004, -0.004, -0.05)), fin + Vector((-0.006, -0.002, -0.09))], 0.024, 0.016,
             -1.2, P["pelo"], pesos=N.pesos_pelo_largo)


def pelo_C(M, P):
    """Pelo largo y liso hasta la cintura, flequillo recto y mechones de corte princesa hasta el pecho; un broche de
    eclipse en la sien."""
    N.casquete(M, P["pelo_casquete"])
    for ph in [-0.78, -0.56, -0.34, -0.12, 0.12, 0.34, 0.56, 0.78]:
        N.mechon(M, N.camino_mechon(ph, 0.24, 1.34, None, vol=0.12, n1=8), 0.05, 0.014, ph, P["pelo"], punta=0.5)
    for ph in (1.02, -1.02):
        pts = N.camino_mechon(ph, 0.4, 1.5, None, vol=0.12)
        p = pts[-1]
        pts += [Vector((p.x * 1.05, -0.13, 1.16)), Vector((p.x * 1.0, -0.155, 1.06)),
                Vector((p.x * 0.95, -0.15, 0.98))]
        N.mechon(M, pts, 0.042, 0.012, ph, P["pelo"], pesos=N.pesos_pelo_largo, punta=0.6)
    largos = [0.84, 0.79, 0.82, 0.76, 0.80, 0.74, 0.77, 0.85, 0.80, 0.83, 0.75, 0.81, 0.73]
    for k, ph in enumerate([1.45, 1.75, 2.05, 2.35, 2.65, 2.9, PI, -1.45, -1.75, -2.05, -2.35, -2.65, -2.9]):
        N.mechon(M, N.camino_mechon(ph, 0.25, 1.75, largos[k], vol=0.13, flare=0.07, rizo=0.03,
                                    n1=6, n2=8),
                 0.066, 0.016, ph, P["pelo"], pesos=N.pesos_pelo_largo, punta=0.35)
    c = N.punto_cab(1.02, -1.25, 1.15)
    n = (c - N.CAB_C).normalized()
    M.pintar(N.disco(M, c, n, 0.016, 0.008, 16), P["tomo"], mat=3, pesos="cabeza")
    M.pintar(N.aro(M, c + n * 0.003, n, 0.021, 0.004, 6, 20), P["oro"], mat=1, pesos="cabeza")


# ------------------------------------------------------------------ conceptos

def concepto_A(M, P):
    N.cuerpo(M, P, botas=lambda M, P, s, l: N.bota(M, P, s, l, 0.37, True, "botas", "laton"))
    # cuello alto de la túnica
    M.pintar(M.tubo([(0, 0.008, 1.075), (0, 0.008, 1.14)], [(0.049, 0.045), (0.045, 0.042)], 14), P["tunica"],
             pesos=[(1.08, "pecho"), (1.13, "cuello")])
    # faldón corto (ciruela) y abrigo de faldones largos detrás, abierto delante
    pf = [(0, 0.875, 0.100, 0.076, 0.0), (1, 0.62, 0.150, 0.125, 0.004)]
    v, f = N.envoltura(M, N.con_pliegues(N.anillo_elipse(pf), 11, 0.008), 0, 2 * PI, 28, [0, .3, .6, .88, .95, 1],
                       cerrado=True, doble=0.005)
    N.pintar_largo(M, v, P["falda"], N.pesos_falda())
    N.pintar_largo(M, f, P["medias"], N.pesos_falda())
    pa = [(0, 0.885, 0.108, 0.084, 0.0), (0.35, 0.68, 0.165, 0.138, 0.012), (1, 0.24, 0.235, 0.205, 0.035)]

    def bajo(phi):
        atras = (1 - math.cos(phi)) / 2
        z = 0.575 - (0.575 - 0.26) * atras ** 1.5 - 0.035 * math.sin(phi) * atras
        return N.t_de_z(pa, z)
    v, f = N.envoltura(M, N.con_pliegues(N.anillo_elipse(pa), 9, 0.010, 0.3), 0.40, 2 * PI - 0.40, 30,
                       [0, .15, .3, .45, .6, .75, .88, .945, .955, 1], t_fin=bajo, doble=0.006, cy0=0.01)
    N.pintar_largo(M, v, P["abrigo"], N.pesos_falda(0.8))
    N.pintar_loseta(M, f, "detalle", N.pesos_falda(0.8))
    # cinturón con hebilla, bolsa y cadena del astrolabio
    N.banda(M, 0.885, 0.0, 0.116, 0.091, 0.04, P["cuero"], N.pesos_tronco)
    M.pintar(M.caja((0, -0.094, 0.866), (0.04, 0.012, 0.034)), P["laton"], mat=2, pesos="cadera")
    M.pintar(M.caja((-0.14, 0.05, 0.79), (0.055, 0.11, 0.10), giro=Euler((0, 0, 0.35))), P["cuero"],
             pesos="cadera")
    M.pintar(M.caja((-0.15, 0.03, 0.835), (0.06, 0.12, 0.03), giro=Euler((0, 0.12, 0.35))), P["cuero"],
             pesos="cadera")
    M.pintar(M.tubo([(0.11, -0.03, 0.85), (0.15, -0.03, 0.80), (0.185, -0.03, 0.775)], [0.004] * 3, 5),
             P["laton_osc"], mat=2, pesos="cadera")
    # astrolabio (hueso propio: cuelga a la cadera y vuela al lanzar)
    c, n = Vector((0.19, -0.03, 0.70)), Vector((1, 0, 0))
    astro = []
    astro += M.pintar(N.aro(M, c, n, 0.075, 0.0065, 8, 40), P["laton"], mat=2)
    astro += M.pintar(N.disco(M, c, n, 0.069, 0.007, 32), P["laton_osc"], mat=2)
    astro += M.pintar(N.aro(M, c + n * 0.005, n, 0.052, 0.003, 6, 36), P["laton"], mat=2)
    astro += M.pintar(N.aro(M, c + n * 0.006, n, 0.036, 0.0035, 6, 32), P["laton"], mat=1)
    astro += M.pintar(N.disco(M, c + n * 0.006, n, 0.029, 0.006, 24), P["laton"], mat=3)
    astro += M.pintar(M.caja(c + n * 0.009, (0.004, 0.006, 0.13), giro=Euler((0.6, 0, 0))), P["laton"], mat=2)
    astro += M.pintar(N.aro(M, c + Vector((0, 0, 0.083)), (0, 1, 0), 0.011, 0.003, 5, 14), P["laton"], mat=2)
    for k in range(4):
        a = k * PI / 2 + PI / 4
        astro += M.pintar(N.estrella(M, c + n * 0.006 + Vector((0, math.cos(a), math.sin(a))) * 0.062, n, 0.010,
                                     0.002), P["laton"], mat=1)
    M.pesar(astro, "astrolabio")
    # capa corta con la capucha bajada: forro de mapa estelar
    pc = [(0, 1.14, 0.054, 0.048, 0.008), (0.22, 1.09, 0.135, 0.105, 0.012), (0.55, 1.02, 0.205, 0.158, 0.016),
          (1, 0.915, 0.238, 0.185, 0.024)]
    v, f = N.envoltura(M, N.con_pliegues(N.anillo_elipse(pc), 8, 0.008, 0.4), 0.22, 2 * PI - 0.22, 32,
                       [0, .2, .4, .6, .8, .92, .935, 1], t_fin=lambda ph: 1.0 + 0.0 * ph, doble=0.006, cy0=0.012)
    N.pintar_largo(M, v, P["capa"], N.pesos_capa)
    N.pintar_loseta(M, f, "detalle", N.pesos_capa)
    M.pintar(M.esfera((0, 0.115, 1.115), (0.125, 0.07, 0.075), (16, 10)), P["capa"], pesos="pecho")
    for k in (-1, 1):   # estrellas bordadas que brillan en el borde
        M.pintar(N.estrella(M, Vector((0.17 * k, -0.115, 0.945)), Vector((0.6 * k, -1, 0)), 0.014, 0.003),
                 P["laton"], mat=1, pesos=N.pesos_capa)
    # broche de luna creciente
    M.pintar(N.aro(M, (0, -0.108, 1.075), (0, -1, 0), 0.018, 0.005, 6, 18, arco=(-60, 200)), P["laton"], mat=2,
             pesos="pecho")
    # bufanda de lino: vuelta al cuello, una punta delante y otra por la espalda
    M.pintar(N.aro(M, (0, 0.01, 1.152), (0, 0.08, 1), 0.052, 0.020, 10, 28), P["bufanda"], pesos="cuello")
    N.mechon(M, [Vector((-0.035, -0.062, 1.14)), Vector((-0.06, -0.15, 1.05)), Vector((-0.07, -0.168, 0.94)),
                 Vector((-0.075, -0.158, 0.84)), Vector((-0.08, -0.15, 0.76))], 0.036, 0.009, 0.0,
             P["bufanda"], pesos=N.pesos_capa, punta=0.9)
    N.mechon(M, [Vector((0.04, 0.06, 1.15)), Vector((0.09, 0.17, 1.07)), Vector((0.11, 0.215, 0.95)),
                 Vector((0.115, 0.225, 0.83)), Vector((0.12, 0.215, 0.72))], 0.034, 0.009, PI / 2,
             P["bufanda"], pesos=N.pesos_capa, punta=0.9)
    # puños vueltos con forro de estrellas
    for s, l in (("L", 1), ("R", -1)):
        w, e = esp(N.MUNECA, l), esp(N.CODO, l)
        d = (w - e).normalized()
        N.manga_doble(M, [w - d * 0.07, w + d * 0.005], [0.033, 0.042], P["capa"], None, N.pesos_brazo(l, s),
                      cual_forro="detalle")
    pelo_A(M, P)


def concepto_B(M, P):
    N.cuerpo(M, P, botas=lambda M, P, s, l: N.bota(M, P, s, l, 0.24, False, "botas"))
    # cuello alto de lino
    M.pintar(M.tubo([(0, 0.008, 1.075), (0, 0.008, 1.15)], [(0.048, 0.044), (0.047, 0.043)], 14), P["lino"],
             pesos=[(1.08, "pecho"), (1.13, "cuello")])
    # pantalón por dentro del abrigo
    for s, l in (("L", 1), ("R", -1)):
        M.pintar(M.tubo([esp(N.CADERA_L, l) + Vector((0, 0, 0.02)), esp(N.RODILLA, l), esp(N.TOBILLO, l) +
                         Vector((0, 0, 0.13))], [0.07, 0.054, 0.048], 12), P["medias"], pesos=N.pesos_pierna(s))
    # abrigo largo: cuerpo abierto delante (se ve el chaleco) y faldones hasta los tobillos
    pt = [(0, 1.125, 0.062, 0.052, 0.008), (0.12, 1.085, 0.128, 0.094, 0.006), (0.4, 1.0, 0.118, 0.092, 0.0),
          (0.7, 0.93, 0.104, 0.082, 0.0), (1, 0.87, 0.104, 0.082, 0.0)]
    v, f = N.envoltura(M, N.anillo_elipse(pt), 0.30, 2 * PI - 0.30, 30, 6, doble=0.005)
    N.pintar_largo(M, v, P["abrigo"], N.pesos_tronco)
    N.pintar_largo(M, f, P["violeta"], N.pesos_tronco)
    pa = [(0, 0.875, 0.106, 0.084, 0.0), (0.3, 0.66, 0.175, 0.145, 0.01), (1, 0.10, 0.26, 0.22, 0.03)]

    def bajo(phi):
        atras = (1 - math.cos(phi)) / 2
        return N.t_de_z(pa, 0.34 - 0.22 * atras ** 1.2)
    v, f = N.envoltura(M, N.con_pliegues(N.anillo_elipse(pa), 10, 0.012, 0.25), 0.36, 2 * PI - 0.36, 32,
                       [0, .12, .25, .4, .55, .7, .85, .945, .955, 1], t_fin=bajo, doble=0.006, cy0=0.01)
    N.pintar_largo(M, v, P["abrigo"], N.pesos_falda(0.9))
    N.pintar_largo(M, f, P["violeta"], N.pesos_falda(0.9))
    # solapas y cuello del abrigo (violeta)
    for k in (-1, 1):
        M.pintar(M.tubo([Vector((0.035 * k, -0.07, 1.10)), Vector((0.06 * k, -0.095, 1.0)),
                         Vector((0.045 * k, -0.092, 0.89))], [(0.022, 0.006), (0.03, 0.006), (0.012, 0.005)], 6,
                        ref=Vector((1, 0, 0))), P["violeta"], pesos=N.pesos_tronco)
    pcu = [(0, 1.20, 0.085, 0.075, 0.012), (1, 1.10, 0.068, 0.06, 0.01)]
    v, f = N.envoltura(M, N.anillo_elipse(pcu), 0.75, 2 * PI - 0.75, 22, 3, doble=0.004)
    N.pintar_largo(M, v, P["abrigo"], [(1.10, "pecho"), (1.18, "cuello")])
    N.pintar_largo(M, f, P["violeta"], [(1.10, "pecho"), (1.18, "cuello")])
    # mangas acampanadas con forro violeta
    for s, l in (("L", 1), ("R", -1)):
        a, e, w = esp(N.HOMBRO, l), esp(N.CODO, l), esp(N.MUNECA, l)
        d = (w - e).normalized()
        N.manga_doble(M, [a + Vector((-0.02 * l, 0, 0.01)), a + (e - a) * 0.5, e, e + (w - e) * 0.6,
                          w + d * 0.035],
                      [0.046, 0.044, 0.048, 0.072, 0.095], P["abrigo"], P["violeta"], N.pesos_brazo(l, s), 14)
    # dos cinturones cruzados con estuches de pergaminos y bolsas
    N.banda(M, 0.86, 0.18, 0.118, 0.094, 0.026, P["cuero"], N.pesos_falda())
    N.banda(M, 0.83, -0.22, 0.124, 0.10, 0.026, P["cuero"], N.pesos_falda())
    for x, z in ((-0.10, 0.80), (-0.125, 0.79)):
        M.pintar(M.tubo([(x, 0.07, z - 0.08), (x, 0.08, z + 0.10)], [0.016, 0.016], 10), P["cuero"],
                 pesos="cadera")
        M.pintar(M.tubo([(x, 0.08, z + 0.10), (x, 0.08, z + 0.12)], [0.018, 0.017], 10), P["laton"], mat=2,
                 pesos="cadera")
    M.pintar(M.caja((0.06, -0.105, 0.80), (0.05, 0.03, 0.05)), P["cuero"], pesos="cadera")
    # tomo encadenado a la cadera (hueso propio)
    tomo = []
    c = Vector((0.175, 0.0, 0.69))
    tomo += M.pintar(M.caja(c, (0.05, 0.155, 0.195)), P["tomo"])
    tomo += M.pintar(M.caja(c + Vector((0, -0.004, 0)), (0.040, 0.15, 0.185)), P["paginas"])
    for dy in (-0.07, 0.07):
        for dz in (-0.088, 0.088):
            tomo += M.pintar(M.caja(c + Vector((0.026, dy, dz)), (0.006, 0.02, 0.02)), P["laton"], mat=2)
    tomo += M.pintar(N.estrella(M, c + Vector((0.027, 0, 0)), (1, 0, 0), 0.04, 0.003, 4, 0.3), P["laton"],
                     mat=1)
    tomo += M.pintar(N.aro(M, c + Vector((0.026, 0, 0)), (1, 0, 0), 0.05, 0.003, 5, 30), P["laton"], mat=2)
    M.pesar(tomo, "tomo")
    M.pintar(M.tubo([(0.11, -0.01, 0.85), (0.16, 0.0, 0.81), (0.175, 0.0, 0.79)], [0.004] * 3, 5), P["laton_osc"],
             mat=2, pesos="cadera")
    # gafas redondas
    gafas = []
    ojos = [N.ojo_mundo(l) for l in (1, -1)]
    for o in ojos:
        gafas += M.pintar(N.aro(M, o + Vector((0, -0.03, -0.004)), (0, 1, 0), 0.043, 0.0035, 6, 32), P["laton"],
                          mat=2)
    gafas += M.pintar(M.tubo([ojos[0] + Vector((-0.043, -0.03, 0.004)), Vector((0, ojos[0].y - 0.04, ojos[0].z)),
                              ojos[1] + Vector((0.043, -0.03, 0.004))], [0.003] * 3, 5), P["laton"], mat=2)
    for o, l in zip(ojos, (1, -1)):
        gafas += M.pintar(M.tubo([o + Vector((0.043 * l, -0.03, 0)), Vector((0.165 * l, -0.03, o.z + 0.005)),
                                  Vector((0.17 * l, 0.03, o.z))], [0.003] * 3, 5), P["laton"], mat=2)
    M.pesar(gafas, "cabeza")
    # bastón-catalejo en la mano derecha (hueso propio)
    x, y = -0.207, -0.03
    bas = []
    bas += M.pintar(M.tubo([(x, y, 0.02), (x, y, 0.50)], [0.010, 0.012], 8), P["madera"])
    bas += M.pintar(M.tubo([(x, y, 0.50), (x, y, 0.95)], [0.014, 0.014], 10), P["laton_osc"], mat=2)
    bas += M.pintar(M.tubo([(x, y, 0.95), (x, y, 1.18)], [0.018, 0.018], 12), P["laton"], mat=2)
    bas += M.pintar(M.tubo([(x, y, 1.18), (x, y, 1.27)], [0.022, 0.024], 12), P["laton"], mat=2)
    for z in (0.50, 0.95, 1.18, 1.27):
        bas += M.pintar(N.aro(M, (x, y, z), (0, 0, 1), 0.02 + 0.006 * (z > 1), 0.004, 6, 18), P["laton"], mat=2)
    bas += M.pintar(N.disco(M, (x, y, 1.272), (0, 0, 1), 0.019, 0.004, 16), P["laton"], mat=1)
    cc = Vector((x, y, 1.36))
    bas += M.pintar(N.aro(M, cc, (1, 0, 0), 0.065, 0.006, 6, 30, arco=(-110, 200)), P["laton"], mat=2)
    bas += M.pintar(N.aro(M, cc, (1, 0, 0), 0.042, 0.003, 6, 30), P["laton"], mat=1)
    bas += M.pintar(M.esfera(cc, (0.026, 0.026, 0.026), (12, 8)), P["tomo"], mat=3)
    M.pesar(bas, "baston")
    pelo_B(M, P)


def concepto_C(M, P):
    N.cuerpo(M, P, botas=lambda M, P, s, l: N.bota(M, P, s, l, 0.40, False, "botas"))
    M.pintar(M.tubo([(0, 0.008, 1.075), (0, 0.008, 1.13)], [(0.046, 0.043), (0.043, 0.040)], 14), P["tunica"],
             pesos=[(1.08, "pecho"), (1.13, "cuello")])
    # falda-pantalón hasta medio muslo
    pp = [(0, 0.87, 0.100, 0.078, 0.0), (1, 0.58, 0.158, 0.13, 0.004)]
    v, f = N.envoltura(M, N.con_pliegues(N.anillo_elipse(pp), 8, 0.006), 0, 2 * PI, 28, [0, .4, .8, .94, .96, 1],
                       cerrado=True, doble=0.005)
    N.pintar_largo(M, v, P["pantalon"], N.pesos_falda())
    N.pintar_largo(M, f, P["medias"], N.pesos_falda())
    # tabardo: paño delantero bordado (hasta la rodilla) y trasero más largo
    for (a0, a1, zb, dy) in ((-0.40, 0.40, 0.40, 0.0), (PI - 0.42, PI + 0.42, 0.30, 0.0)):
        pt = [(0, 0.885, 0.112, 0.090, dy), (0.4, 0.66, 0.168, 0.142, dy), (1, zb, 0.19, 0.165, dy)]
        v, f = N.envoltura(M, N.anillo_elipse(pt), a0, a1, 8, [0, .25, .5, .75, .92, 1], doble=0.004)
        N.pintar_loseta(M, v, "detalle", N.pesos_falda(0.6), escala=(1.0, 1.0))
        N.pintar_largo(M, f, P["tunica"], N.pesos_falda(0.6))
    N.banda(M, 0.905, 0.0, 0.112, 0.09, 0.055, P["faja"], N.pesos_tronco)
    # mangas oscuras hasta la mano (guantes largos)
    # media capa sujeta al hombro izquierdo: larga detrás y a su izquierda, corta a la derecha
    pc = [(0, 1.135, 0.056, 0.05, 0.01), (0.10, 1.085, 0.15, 0.115, 0.014), (0.25, 0.99, 0.212, 0.165, 0.024),
          (1, 0.20, 0.275, 0.235, 0.07)]

    def bajo(phi):
        # phi va de 0.30 (delante, a su izquierda) a 2π-1.25 (atrás a su derecha)
        u = (phi - 0.30) / (2 * PI - 1.25 - 0.30)
        z = 0.56 - 0.34 * math.sin(min(u / 0.45, 1.0) * PI / 2) if u < 0.45 else 0.22 + 0.72 * ((u - 0.45) / 0.55) ** 1.4
        return N.t_de_z(pc, z)
    v, f = N.envoltura(M, N.con_pliegues(N.anillo_elipse(pc), 9, 0.012, 0.2), 0.30, 2 * PI - 1.25, 36,
                       [0, .06, .14, .25, .4, .55, .7, .85, .955, .965, 1], t_fin=bajo, doble=0.006, cy0=0.02)
    N.pintar_largo(M, v, P["capa"], N.pesos_capa)
    N.pintar_loseta(M, f, "detalle", N.pesos_capa)
    # broche de eclipse en el hombro izquierdo
    b = Vector((0.115, -0.095, 1.06))
    M.pintar(N.disco(M, b, (0.3, -1, 0.2), 0.022, 0.01, 18), P["tomo"], mat=3, pesos="pecho")
    M.pintar(N.aro(M, b + Vector((0, -0.005, 0)), (0.3, -1, 0.2), 0.027, 0.0045, 6, 22), P["oro"], mat=1,
             pesos="pecho")
    # libro en la mano izquierda (hueso propio)
    lib = []
    c = Vector((0.222, -0.03, 0.60))
    lib += M.pintar(M.caja(c, (0.042, 0.13, 0.17)), P["tomo"])
    lib += M.pintar(M.caja(c + Vector((0, -0.004, 0)), (0.034, 0.125, 0.16)), P["paginas"])
    lib += M.pintar(N.aro(M, c + Vector((0.022, 0, 0)), (1, 0, 0), 0.04, 0.0035, 6, 26), P["oro"], mat=1)
    lib += M.pintar(N.disco(M, c + Vector((0.022, 0, 0)), (1, 0, 0), 0.03, 0.004, 18), P["tomo"], mat=3)
    M.pesar(lib, "libro")
    # planetario a la espalda (hueso propio): aros de luz, un eclipse en el centro y tres astros
    orb = []
    o = Vector((0, 0.32, 1.12))
    orb += M.pintar(N.aro(M, o, (0, 1, 0.28), 0.215, 0.0042, 6, 56), P["oro"], mat=1)
    orb += M.pintar(N.aro(M, o, (0.42, 1, -0.15), 0.19, 0.0036, 6, 52), P["oro"], mat=1)
    orb += M.pintar(N.aro(M, o, (0, 0.25, 1), 0.10, 0.003, 6, 36), P["oro"], mat=2)
    orb += M.pintar(M.esfera(o, (0.042, 0.042, 0.042), (14, 10)), P["tomo"], mat=3)
    orb += M.pintar(N.aro(M, o + Vector((0, -0.02, 0)), (0, 1, 0), 0.052, 0.006, 6, 30), P["oro"], mat=1)
    for ang, r, rr in ((40, 0.215, 0.018), (160, 0.19, 0.013), (280, 0.10, 0.011)):
        a = math.radians(ang)
        orb += M.pintar(M.esfera(o + Vector((math.cos(a) * r, 0, math.sin(a) * r)), (rr, rr, rr), (10, 6)),
                        P["oro"], mat=2)
    M.pesar(orb, "orbe")
    for i in range(5):   # estrellas que brillan en el bajo de la capa
        ph = 0.9 + i * 0.6
        p = N.con_pliegues(N.anillo_elipse(pc), 9, 0.012, 0.2)(bajo(ph) * 0.93, ph)
        nrm = Vector((p.x, p.y - 0.02, 0)).normalized()
        M.pintar(N.estrella(M, p + nrm * 0.004, nrm, 0.013, 0.002), P["oro"], mat=1, pesos=N.pesos_capa)
    pelo_C(M, P)


HUESOS_EXTRA = {
    "A": [("astrolabio", (0.19, -0.03, 0.70), (0.19, -0.03, 0.78), "raiz")],
    "B": [("tomo", (0.175, 0.0, 0.69), (0.175, 0.0, 0.79), "cadera"),
          ("baston", (-0.207, -0.03, 0.62), (-0.207, -0.03, 0.72), "mano.R")],
    "C": [("libro", (0.222, -0.03, 0.60), (0.222, -0.03, 0.70), "mano.L"),
          ("orbe", (0, 0.32, 1.12), (0, 0.32, 1.22), "pecho")],
}


# ------------------------------------------------------------------ poses

def reposo(c):
    if c == "A":
        p = {"cadera": (0, -2, 4), "columna": (2, 1, -3), "pecho": (0, 0, -1), "cabeza": (5, -6, 7),
             "brazo.L": (-4, 6, 3), "antebrazo.L": (-14, 0, -6), "mano.L": (0, 0, -6),
             "brazo.R": (30, 10, 0), "antebrazo.R": (-100, 0, 40), "mano.R": (0, 0, 0),   # mano en el cinturón
             "muslo.L": (-3, -3, 5), "pierna.L": (7, 0, 0), "pie.L": (-3, 0, 6),
             "muslo.R": (1, 1, -2), "raiz@loc": (-0.008, 0, 0)}
    elif c == "B":
        p = {"cadera": (0, 2, -3), "columna": (2, -1, 3), "cabeza": (6, 4, -6),
             "brazo.R": (-6, -3, 0), "antebrazo.R": (-16, 0, 0),
             "brazo.L": (-6, 6, 2), "antebrazo.L": (-30, 0, -12), "mano.L": (0, 0, 8),
             "muslo.R": (-3, 3, -5), "pierna.R": (7, 0, 0), "pie.R": (-3, 0, -6), "muslo.L": (1, -1, 2),
             "raiz@loc": (0.008, 0, 0)}
    else:
        p = {"cadera": (0, -2, 3), "columna": (1, 1, -2), "cabeza": (4, -4, 8),
             "brazo.L": (-14, 6, 4), "antebrazo.L": (-40, 0, -14), "mano.L": (0, 0, 10),
             "brazo.R": (-2, -5, -3), "antebrazo.R": (-12, 0, 0),
             "muslo.L": (-2, -2, 4), "pierna.L": (5, 0, 0), "muslo.R": (1, 1, -2), "raiz@loc": (-0.006, 0, 0)}
    return N.con_ojos(p)


def hechizo(c):
    base = {"cadera": (0, 0, -10), "columna": (-4, 0, -6), "pecho": (-6, 0, -6), "cuello": (-4, 0, 0),
            "muslo.R": (-14, 4, -4), "pierna.R": (12, 0, 0), "pie.R": (2, 0, 0),
            "muslo.L": (14, -6, 4), "pierna.L": (14, 0, 0), "pie.L": (-12, 0, 0), "raiz@loc": (0, 0, -0.02)}
    if c == "A":
        base.update({"cabeza": (-14, 0, 8),
                     "brazo.R": (-118, 14, 0), "antebrazo.R": (-18, 0, 0), "mano.R": (-30, 0, 0),
                     "brazo.L": (16, -42, 0), "antebrazo.L": (-28, 0, 0), "mano.L": (24, 0, 0),
                     "astrolabio@sobre_mano.R": (0.0, -0.06, 0.20), "astrolabio": (0, 0, -90),
                     "astrolabio@esc": (1.8, 1.8, 1.8)})
    elif c == "B":
        base.update({"cabeza": (-12, 0, 4),
                     "brazo.R": (-135, 10, 0), "antebrazo.R": (-8, 0, 0), "mano.R": (-8, 0, 0),
                     "brazo.L": (-78, -24, 0), "antebrazo.L": (-12, 0, 0), "mano.L": (-50, 0, 0)})
    else:
        base.update({"cabeza": (-16, 0, 0), "cadera": (0, 0, 0), "pecho": (-8, 0, 0), "columna": (-4, 0, 0),
                     "brazo.R": (-150, 22, 0), "antebrazo.R": (-12, 0, 0), "mano.R": (-25, 0, 0),
                     "brazo.L": (-30, 8, 4), "antebrazo.L": (-55, 0, -16), "mano.L": (0, 0, 10),
                     "orbe@loc": (0, 0.06, 0.30), "orbe@esc": (1.3, 1.3, 1.3)})
    return N.con_ojos(base)


BRILLO = {"A": (1.0, 0.68, 0.28), "B": (0.72, 0.58, 1.0), "C": (1.0, 0.84, 0.52)}


# ------------------------------------------------------------------ construir

def construir(c, esc):
    A = C.Atlas(1024, semilla={"A": 3, "B": 9, "C": 17}[c])
    P = paleta(A, c)
    N.dibujar_cara(A, P)
    img = A.guardar(os.path.join(LAMINAS, "naira_%s_atlas.png" % c), "naira_%s_atlas" % c)
    M = C.Malla(A)
    {"A": concepto_A, "B": concepto_B, "C": concepto_C}[c](M, P)
    ob = M.objeto("naira_" + c, esc.collection)
    m0 = C.material_atlas("naira_%s_tela" % c, img, rugoso=0.82)
    m1 = N.objeto_brillo("naira_%s_brillo" % c, BRILLO[c], 4.0)
    m2 = C.material_atlas("naira_%s_metal" % c, img, metal=0.75, rugoso=0.35)
    m3 = C.material_color("naira_%s_eclipse" % c, (0.02, 0.02, 0.035), rugoso=0.18)
    for m in (m0, m1, m2, m3):
        m.use_backface_culling = True
        ob.data.materials.append(m)
    arm = C.crear_armadura("naira_%s_esq" % c, N.huesos(HUESOS_EXTRA[c]), esc.collection)
    C.enlazar(ob, arm)
    tris = C.triangulos(ob)
    print("CONCEPTO", c, "triangulos", tris, "huesos", len(arm.data.bones))
    return ob, arm, tris


def ocultar(objs, si=True):
    for o in objs:
        o.hide_render = si
        for h in o.children:
            h.hide_render = si


def laminas(c):
    esc = C.escena_vacia()
    ob, arm, tris = construir(c, esc)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(LAMINAS, "naira_%s.blend" % c))
    N.preparar(esc, 2800, 1250)
    N.luces_estudio(esc)
    C.suelo(esc, color=(0.86, 0.84, 0.80))
    xs = [-3.05, -2.1, -1.15, 0.05, 1.0, 1.95, 3.1]
    giros = [(0, True), (90, True), (180, True), (0, False), (-35, False), (180, False)]
    copias = []
    R = reposo(c)
    for x, (g, sil) in zip(xs, giros):
        copias.append(N.copia_posada(esc, arm, ob, R, x, g, sil))
    ch = N.copia_posada(esc, arm, ob, hechizo(c), xs[6], -28)
    circ = N.circulo_magico(esc, "circulo_" + c, BRILLO[c], (xs[6], 0, 0))
    ocultar([arm])
    ob.hide_render = True
    rot = ["silueta · frente", "silueta · perfil", "silueta · espalda", "frente", "3/4", "espalda", "lanzar hechizo"]
    textos = [C.texto(esc, t, (x, 0.0, 1.82), 0.10) for x, t in zip(xs, rot)]
    textos.append(C.texto(esc, "Naira · CONCEPTO %s  ·  %d triángulos (concepto, sin optimizar)" % (NOMBRES[c], tris),
                          (0, 0.4, 2.12), 0.13))
    cam = C.camara(esc, (0.02, 0, 0.98), 16, 0, 5, orto=7.5)
    esc.render.filepath = os.path.join(LAMINAS, "naira_%s_lamina.png" % c)
    bpy.ops.render.render(write_still=True)
    # cara en primer plano
    ocultar(textos)
    ocultar([a for a, m in copias] + [ch[0]] + [circ])
    ocultar([copias[4][0]], False)
    cam.data.type = 'PERSP'
    cam.data.lens = 90
    esc.render.resolution_x, esc.render.resolution_y = 1100, 1100
    hc = Vector((xs[4], 0, 0)) + Vector((0.02, -0.01, 1.33))
    C.apuntar(cam, hc, 2.1, -22, 4)
    esc.render.filepath = os.path.join(LAMINAS, "naira_%s_cara.png" % c)
    bpy.ops.render.render(write_still=True)
    # pose de hechizo grande (3/4)
    ocultar([copias[4][0]])
    ocultar([ch[0], circ], False)
    cam.data.type = 'ORTHO'
    cam.data.ortho_scale = 2.3
    esc.render.resolution_x, esc.render.resolution_y = 1400, 1400
    C.apuntar(cam, (xs[6], 0, 0.95), 12, -10, 10)
    esc.render.filepath = os.path.join(LAMINAS, "naira_%s_hechizo.png" % c)
    bpy.ops.render.render(write_still=True)
    # junto a Kael, Lya y Garon a escala
    ocultar([ch[0], circ])
    ocultar([copias[3][0]], False)
    copias[3][0].location = (2.1, 0, 0)
    for i, (nom, fbx, accion, alto) in enumerate(N.HEROES):
        N.importar_heroe(RAIZ, fbx, accion, alto, ((-2.1, -0.7, 0.7)[i], 0, 0))
    for x, t in ((-2.1, "Kael · 1,70"), (-0.7, "Lya · 1,52"), (0.7, "Garon · 1,70"), (2.1, "Naira %s · 1,55" % c)):
        C.texto(esc, t, (x, 0.0, 1.98), 0.11)
    C.texto(esc, "Naira, concepto %s, a escala con el grupo (alturas relativas de grupo_3d.gd)" % c,
            (0, 0.4, 2.22), 0.11)
    esc.render.resolution_x, esc.render.resolution_y = 2200, 1150
    cam.data.ortho_scale = 5.6
    C.apuntar(cam, (0, 0, 1.08), 14, 0, 4)
    esc.render.filepath = os.path.join(LAMINAS, "naira_%s_escala.png" % c)
    bpy.ops.render.render(write_still=True)


def comparativa():
    esc = C.escena_vacia()
    N.preparar(esc, 3300, 1300)
    N.luces_estudio(esc)
    C.suelo(esc, color=(0.86, 0.84, 0.80))
    xs = [-3.4, -2.1, -0.8, 0.75, 2.1, 3.45]
    for i, (nom, fbx, accion, alto) in enumerate(N.HEROES):
        N.importar_heroe(RAIZ, fbx, accion, alto, (xs[i], 0, 0), giro_z=-20)
    for k, c in enumerate("ABC"):
        ob, arm, tris = construir(c, esc)
        arm.location = (xs[3 + k], 0, 0)
        arm.rotation_euler = (0, 0, math.radians(-20))
        N.poner(arm, reposo(c))
    rot = ["Kael", "Lya", "Garon", NOMBRES["A"], NOMBRES["B"], NOMBRES["C"]]
    for x, t in zip(xs, rot):
        C.texto(esc, t, (x, 0.0, 1.92), 0.085 if len(t) > 8 else 0.11)
    C.texto(esc, "Naira, la Astrónoma del Eclipse (nombre provisional): tres conceptos junto al grupo, a escala",
            (0, 0.4, 2.2), 0.12)
    C.camara(esc, (0, 0, 1.0), 16, 0, 5, orto=8.0)
    esc.render.filepath = os.path.join(LAMINAS, "comparativa_naira.png")
    bpy.ops.render.render(write_still=True)
    # siluetas de los seis
    negro = C.material_color("negro_sil", (0.02, 0.02, 0.025), rugoso=1.0)
    for o in esc.objects:
        if o.type == 'MESH' and not o.name.startswith("txt") and o.name != "Plane":
            o.data.materials.clear()
            o.data.materials.append(negro)
            for p in o.data.polygons:
                p.material_index = 0
    esc.render.filepath = os.path.join(LAMINAS, "comparativa_naira_siluetas.png")
    bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
  if QUE == "comparativa":
    comparativa()
  else:
    for c in QUE:
        laminas(c)
