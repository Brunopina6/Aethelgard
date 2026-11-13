# e01 · Peón de Linde (V12, bestiario de producción, 13/11/2026, especialista de enemigos «bestiario»). Piloto del lote.
# Hostigador común de Pastos Verdes y los caminos. Concepto del encargo (Aethelgard_Bestiario_Produccion.pdf, págs. 3-4):
# barro seco, máscara de MOJÓN, chaqueta de fibras salvia, dos ESTACAS de agrimensor, silueta triangular con manos
# grandes (mitones) y una franja blanca vertical en el pecho; faldón de cuatro placas ligado a la pelvis y los muslos.
# Lectura propia: el antiguo peón que clavaba las lindes de los caminos; la corrupción le ha dejado la máscara de piedra
# del mojón (con la cruz de deslinde tallada y la coronilla pintada de ocre y blanco, como los hitos del camino), el
# cuerpo de barro agrietado y las estacas, que ahora clava en la gente. Lleva otras dos estacas cruzadas a la espalda:
# de ahí saca la que lanza («la réplica reaparece al recuperar»: la mano va a la espalda y la saca).
#
#   blender -b --factory-startup -P crear_peon_linde.py -- <raíz aethelgard> <carpeta de láminas> [sin_laminas] [solo_malla]
#
# Escribe enemigos/peon_linde/peon_linde.glb (sin imágenes), peon_linde.webp (1024, alto), peon_linde_bajo.webp (512) y
# peon_linde_clips.json; en la carpeta de láminas, la lámina (frente, perfil, espalda y Kael), la hoja de poses, el atlas
# y el .blend (fuera de Git). Misma semilla, mismo resultado.
#
# Ejes (Blender): mira a -Y, Z arriba, su izquierda es +X. En Godot mira a +Z.
# Esqueleto: el rig base del bestiario (enemigos/bestiario_comun/fuente/bestiario_rig.py): raiz + 22 deformantes, más
# arma.R y arma.L (las estacas, deforman como accesorio rígido), pecho_fx y luz (no deforman).
# Superficies: «peon_linde_atlas» (atlas × oclusión del color de vértice) y «peon_linde_brillo» (los ojos).
import bpy, bmesh, sys, os, math, random
from mathutils import Vector, Euler, Quaternion, Matrix
from mathutils.bvhtree import BVHTree

argv = sys.argv[sys.argv.index("--") + 1:]
RAIZ, LAMINAS = argv[0], argv[1]
CON_LAMINAS = "sin_laminas" not in argv
SOLO_MALLA = "solo_malla" in argv
SOLO_LAMINA = "solo_lamina" in argv          # solo la lámina con Kael, Lya y Garon (no escribe GLB, texturas ni JSON)
# V2 (13/11, segunda pasada de arte): proporciones compactas y formas redondeadas (malla_peon_v2.py). Escribe
# peon_linde_v2.glb, _v2.webp, _v2_bajo.webp, _v2_normal.webp y _v2_clips.json al lado de la v1, que no cambia.
V2 = "v2" in argv
SUFIJO = "_v2" if V2 else ""
PROP = {"piernas": 0.70, "cabeza": 1.35, "brazos": 0.86} if V2 else {}
FP = PROP.get("piernas", 1.0)
sys.path.insert(0, os.path.join(RAIZ, "personajes", "desierto", "fuentes_blender"))
sys.path.insert(0, os.path.join(RAIZ, "enemigos", "v12_comun", "fuente"))
sys.path.insert(0, os.path.join(RAIZ, "enemigos", "bestiario_comun", "fuente"))
import desierto_comun as C
import enemigos_v12_blender as E
import bestiario_rig as B
import numpy as np

SALIDA = os.path.join(RAIZ, "enemigos", "peon_linde")
NOMBRE = "peon_linde"
ID = "e01"
ALTO = 1.65
os.makedirs(LAMINAS, exist_ok=True)
random.seed(101)
esc = C.escena_vacia()
col = esc.collection

# ================================================================== atlas (1024, 4×4 celdas de 256)

A = E.AtlasV12(1024, 4, semilla=101)


def malla_xy(h):
    yy, xx = np.mgrid[0:h, 0:h]
    return (xx + 0.5) / h, (yy + 0.5) / h


def pinta_barro(h, rng, base=(0.56, 0.43, 0.31), grietas=1.0):
    """Barro seco: costra con craquelado (celdas de Voronoi), bordes de cada placa algo levantados y claros."""
    f = E.fbm(h, rng, 4, 5)
    f1, f2 = E.celdas_voronoi(h, rng, 26)
    img = E.color(base) * (0.80 + 0.35 * f[..., None])
    borde = np.clip((0.05 - (f2 - f1)) * 18, 0, 1)
    img = E.mezclar(img, (0.70, 0.58, 0.44), np.clip(borde * 1.5 - 0.6, 0, 0.5) * grietas)    # labio claro
    img = E.mezclar(img, (0.24, 0.17, 0.11), np.clip((0.012 - (f2 - f1)) * 70, 0, 0.9) * grietas)   # la grieta
    motas = rng.random((h, h)) < 0.01
    img[motas] = img[motas] * 0.75
    return img


def pinta_barro_oscuro(h, rng):
    return pinta_barro(h, rng, (0.38, 0.29, 0.21), 0.7)


def pinta_fibra(h, rng, base=(0.53, 0.61, 0.46)):
    """Tejido de fibras salvia: trama y urdimbre gruesas (esteras de junco), hebras sueltas oscuras y claras."""
    X, Y = malla_xy(h)
    n = 18
    u = np.sin(X * math.pi * 2 * n)
    v = np.sin(Y * math.pi * 2 * n)
    cuadro = (np.floor(X * n) + np.floor(Y * n)) % 2
    trama = np.where(cuadro > 0, 0.5 + 0.5 * np.abs(u), 0.5 + 0.5 * np.abs(v))
    f = E.fbm(h, rng, 3, 4)
    img = E.color(base) * (0.70 + 0.28 * trama[..., None]) * (0.85 + 0.25 * f[..., None])
    for k in range(70):
        y0, x0 = rng.uniform(0, 1), rng.uniform(0, 1)
        l, a = rng.uniform(0.05, 0.18), rng.uniform(-0.4, 0.4)
        d = np.abs((Y - y0) * math.cos(a) - (X - x0) * math.sin(a))
        dentro = (np.abs((X - x0) * math.cos(a) + (Y - y0) * math.sin(a)) < l) & (d < 0.003)
        img[dentro] = img[dentro] * (0.6 if k % 2 else 1.25)
    return img


def pinta_fibra_oscura(h, rng):
    return pinta_fibra(h, rng, (0.36, 0.43, 0.32))


def pinta_mojon(h, rng):
    """Piedra arenisca clara del mojón: grano, golpes de cincel y vetas suaves."""
    f = E.fbm(h, rng, 5, 5)
    img = E.color((0.76, 0.72, 0.63)) * (0.82 + 0.3 * f[..., None])
    g = E.grietas(h, rng, 16, 0.004)
    img = E.mezclar(img, (0.48, 0.44, 0.38), g * 0.45)
    cincel = E.ruido(h, 60, rng)
    img = E.mezclar(img, (0.86, 0.83, 0.75), np.clip((cincel - 0.72) * 4, 0, 0.6))
    return img


def pinta_madera(h, rng):
    """Madera de las estacas: veta a lo largo (v), nudos y desgaste."""
    X, Y = malla_xy(h)
    veta = E.ruido(h, 40, rng)[0][None, :] * np.ones((h, 1))
    f = E.fbm(h, rng, 3, 4)
    img = E.color((0.70, 0.55, 0.36)) * (0.72 + 0.4 * veta[..., None] * (0.7 + 0.3 * f[..., None]))
    return E.mezclar(img, (0.40, 0.28, 0.16), E.grietas(h, rng, 10, 0.004) * 0.5)


def pinta_banda(h, rng):
    """Bandas de agrimensor (a lo largo de v): ocre rojizo y blanco, pintura gastada."""
    X, Y = malla_xy(h)
    franja = (np.floor(Y * 4) % 2) > 0
    f = E.fbm(h, rng, 6, 4)
    img = np.where(franja[..., None], E.color((0.93, 0.91, 0.84)), E.color((0.74, 0.31, 0.15)))
    img = img * (0.85 + 0.2 * f[..., None])
    gastado = np.clip((E.fbm(h, rng, 8, 3) - 0.62) * 5, 0, 1)
    return E.mezclar(img, (0.66, 0.52, 0.34), gastado * 0.8)


def pinta_franja(h, rng):
    """La franja blanca del pecho: cal sobre fibra, con el tejido asomando."""
    tejido = pinta_fibra(h, rng, (0.80, 0.82, 0.74))
    f = E.fbm(h, rng, 6, 4)
    img = E.mezclar(tejido, (0.94, 0.93, 0.88), np.clip(0.55 + (f - 0.5) * 2.5, 0, 0.92))
    return img


def pinta_placa(h, rng):
    """Placas del faldón: arcilla cocida con incisiones horizontales (las marcas de las lindes) y bordes oscuros."""
    X, Y = malla_xy(h)
    f = E.fbm(h, rng, 4, 4)
    img = E.color((0.60, 0.45, 0.34)) * (0.82 + 0.3 * f[..., None])
    for y0 in (0.25, 0.5, 0.75):
        img = E.mezclar(img, (0.36, 0.24, 0.16), np.clip((0.008 - np.abs(Y - y0)) * 150, 0, 0.8))
    muescas = (np.abs(((X * 6) % 1.0) - 0.5) < 0.04) & (np.abs(Y - 0.5) < 0.1)
    img[muescas] = img[muescas] * 0.55
    return E.mezclar(img, (0.32, 0.22, 0.15), E.grietas(h, rng, 12, 0.005) * 0.4)


for nombre, f in (("barro", pinta_barro), ("barro_oscuro", pinta_barro_oscuro), ("fibra", pinta_fibra),
                  ("fibra_oscura", pinta_fibra_oscura), ("mojon", pinta_mojon), ("madera", pinta_madera),
                  ("banda", pinta_banda), ("franja", pinta_franja), ("placa", pinta_placa)):
    A.celda(nombre, f)

BRILLO = (1.0, 0.70, 0.32)            # ocre encendido de los ojos (peon_linde_3d.gd, COLOR_BRILLO)

# ================================================================== esqueleto (rig base del bestiario)

# Puño: dónde agarra el mitón (un poco antes de la cola de la mano). Las estacas pasan por él.
_hs = {n: (Vector(a), Vector(b)) for n, a, b, p in B.huesos(ALTO, 1.08 if V2 else 1.0, 0.95 if V2 else 1.0, **PROP)}
PUNO = {s: _hs["mano" + s][0].lerp(_hs["mano" + s][1], 0.5) for s in (".L", ".R")}
# Dirección de cada estaca en reposo: hacia delante y abajo, algo hacia fuera (como quien va a clavar una linde)
DIR_ESTACA = {".L": Vector((0.10, -0.74, -0.66)).normalized(), ".R": Vector((-0.10, -0.74, -0.66)).normalized()}
SOCKETS = {
    "arma.R": (PUNO[".R"], PUNO[".R"] + DIR_ESTACA[".R"] * 0.3, "mano.R", True),
    "arma.L": (PUNO[".L"], PUNO[".L"] + DIR_ESTACA[".L"] * 0.3, "mano.L", True),
    "pecho_fx": ((0, -0.16, 1.24 - 0.9 * (1 - FP)), (0, -0.28, 1.24 - 0.9 * (1 - FP)), "pecho", False),
    "luz": ((0, 0.1, 0.0), (0, 0.1, 0.15), "raiz", False),
}
arm, HUESOS = B.crear(NOMBRE, col, ALTO, 1.08 if V2 else 1.0, 0.95 if V2 else 1.0, sockets=SOCKETS, **PROP)
print("huesos deformantes:", B.contar_deformantes(arm), "de", len(HUESOS))

if V2:                                  # la v2 (13/11): malla_peon_v2.py, con su atlas y su mapa de normales
    exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "malla_peon_v2.py"), encoding="utf-8").read())
else:
    # ================================================================== malla

    m = C.Malla(None, ("atlas", "brillo"))
    CR = E.caja_redonda


    def pieza(vs, celda, pesos, escala=0.45, liso=True):
        return E.proyectar(m, A, vs, celda, escala, pesos, 0, liso)


    def brillo(vs, hueso):
        for f in {f for v in vs for f in v.link_faces}:
            f.material_index = 1
            f.smooth = True
            for lp in f.loops:
                lp[m.uv].uv = (0.5, 0.5)
        m.pesar(vs, hueso)
        return vs


    def giro(ax=0, ay=0, az=0):
        return Euler((math.radians(ax), math.radians(ay), math.radians(az)), 'XYZ')


    def por_z(cadena):
        return lambda co: C.por_altura(co.z, cadena)


    TRONCO = por_z([(0.95, "cadera"), (1.04, "columna_01"), (1.15, "columna_02"), (1.30, "pecho")])

    for s, l in ((".L", 1), (".R", -1)):
        pierna = B.eje(arm, [("muslo" + s, 0.0), ("muslo" + s, 0.82), ("pierna" + s, 0.12), ("pierna" + s, 1.0)])
        # pierna de barro (muslo, rodilla, pantorrilla y tobillo) en un solo tubo, pesos suaves en la rodilla
        pieza(m.tubo([(0.105 * l, 0.0, 0.95), (0.12 * l, -0.008, 0.73), (0.13 * l, -0.02, 0.50), (0.136 * l, -0.005, 0.32),
                      (0.14 * l, 0.01, 0.12)], [0.096, 0.086, 0.067, 0.064, 0.05], 10), "barro", pierna, 0.35)
        # vendas rígidas de fibra en la espinilla
        for z, r in ((0.40, 0.064), (0.26, 0.058)):
            pieza(m.tubo([(0.134 * l, -0.01, z - 0.025), (0.136 * l, -0.008, z + 0.025)], [r, r], 10), "fibra_oscura",
                  "pierna" + s, 0.25)
        # rodillera de arcilla
        pieza(CR(m, (0.132 * l, -0.072, 0.505), (0.072, 0.035, 0.08), giro(-8, 0, 0), redondez=0.7, cortes=1), "placa",
              "pierna" + s, 0.3)
        # zueco de barro grande (el talón con el pie; la puntera con los dedos)
        pie = B.mezcla(B.fijo("pie" + s), B.fijo("dedos" + s), lambda co: (-co.y - 0.07) / 0.07)
        pieza(CR(m, (0.14 * l, -0.045, 0.058), (0.13, 0.29, 0.115), redondez=0.55, cortes=2, ruido_amp=0.01,
                 semilla=3 + l), "barro_oscuro", pie, 0.3)

        # brazo: hombrera de fibra, manga hasta el codo, antebrazo de barro, brazal y mitón grande
        brazo = B.eje(arm, [("clavicula" + s, 0.5), ("brazo" + s, 0.0), ("brazo" + s, 0.85), ("antebrazo" + s, 0.15),
                            ("antebrazo" + s, 1.0)])
        pieza(CR(m, (0.165 * l, 0.012, 1.33), (0.125, 0.155, 0.10), giro(0, -22 * l, 0), redondez=0.65, cortes=2),
              "fibra", lambda co, s=s: {"clavicula" + s: 0.35, "brazo" + s: 0.65}, 0.3)
        pieza(m.tubo([(0.155 * l, 0.012, 1.35), (0.235 * l, 0.022, 1.235), (0.31 * l, 0.034, 1.115),
                      (0.33 * l, 0.03, 1.07)], [0.064, 0.060, 0.055, 0.052], 10), "fibra", brazo, 0.3)
        pieza(m.tubo([(0.30 * l, 0.034, 1.13), (0.355 * l, 0.012, 1.01), (0.40 * l, -0.01, 0.91)],
                     [0.050, 0.047, 0.043], 10), "barro", brazo, 0.3)
        pieza(m.tubo([(0.377 * l, 0.0, 0.965), (0.392 * l, -0.006, 0.93)], [0.052, 0.052], 10), "fibra_oscura",
              "antebrazo" + s, 0.25)
        P0 = PUNO[s]
        dm = (_hs["mano" + s][1] - _hs["mano" + s][0]).normalized()
        rot_mano = Vector((0, 0, -1)).rotation_difference(dm).to_euler()
        pieza(CR(m, P0 + dm * -0.005, (0.125, 0.135, 0.165), rot_mano, redondez=0.62, cortes=2, ruido_amp=0.008,
                 semilla=5 + l), "barro_oscuro", "mano" + s, 0.25)
        pieza(CR(m, P0 + Vector((-0.045 * l, -0.055, 0.02)), (0.05, 0.06, 0.075), redondez=0.6, cortes=1),
              "barro_oscuro", "mano" + s, 0.25)

        # la estaca de agrimensor (madera de sección cuadrada, punta embarrada y dos bandas ocre y blanca junto al puño)
        d = DIR_ESTACA[s]
        culata, punta = P0 - d * 0.22, P0 + d * 0.74
        hueso_a = "arma" + s
        E.plano_uv(m, A, m.tubo([culata, P0 + d * 0.60], [(0.03, 0.03), (0.028, 0.028)], 4, giro_seccion=math.pi / 4,
                                ref=Vector((1, 0, 0))), "madera", culata, Vector((1, 0, 0)), d, 0.1, 0.5, hueso_a)
        pieza(m.tubo([P0 + d * 0.60, punta], [(0.028, 0.028), (0.003, 0.003)], 4, giro_seccion=math.pi / 4),
              "barro_oscuro", hueso_a, 0.2, liso=False)
        E.plano_uv(m, A, m.tubo([culata + d * 0.01, culata + d * 0.15], [0.033, 0.033], 4, giro_seccion=math.pi / 4),
                   "banda", culata, Vector((1, 0, 0)), d, 0.1, 0.14, hueso_a)
        pieza(CR(m, culata - d * 0.01, (0.05, 0.05, 0.04), Vector((0, 0, 1)).rotation_difference(d).to_euler(),
                 redondez=0.5, cortes=1), "madera", hueso_a, 0.2)

        # faldón: dos placas por lado (delante y detrás), arriba con la cadera y abajo con el muslo
        for sy, ny in ((-1, "del"), (1, "tras")):
            fald = (lambda co, s=s: {"cadera": max(0.0, min(1.0, (co.z - 0.66) / 0.27)) * 0.6 + 0.4,
                                     "muslo" + s: 0.6 - max(0.0, min(1.0, (co.z - 0.66) / 0.26)) * 0.6})
            pieza(CR(m, (0.128 * l, 0.112 * sy, 0.795), (0.13, 0.028, 0.28), giro(12 * sy, -18 * l, 8 * l * sy),
                     redondez=0.4, cortes=2), "placa", fald, 0.3)

    # cadera y faja
    pieza(CR(m, (0, 0.005, 0.925), (0.30, 0.215, 0.17), redondez=0.6, cortes=2), "barro", "cadera", 0.35)
    pieza(CR(m, (0, 0.012, 0.972), (0.47, 0.32, 0.06), redondez=0.6, cortes=2), "fibra_oscura",
          por_z([(0.96, "cadera"), (1.01, "columna_01")]), 0.3)
    # chaqueta de fibras salvia (trapecio: más ancha abajo; silueta triangular)
    pieza(CR(m, (0, 0.012, 1.175), (0.37, 0.25, 0.43), redondez=0.5, cortes=3, ruido_amp=0.006, semilla=21,
             afinar=lambda z: 1.24 - 0.52 * (z + 0.5)), "fibra", TRONCO, 0.3)
    # cuello alto de fibra y cuello de barro
    pieza(m.tubo([(0, 0.012, 1.345), (0, 0.008, 1.40)], [(0.125, 0.105), (0.105, 0.09)], 12), "fibra_oscura",
          por_z([(1.34, "pecho"), (1.40, "cuello")]), 0.25)
    pieza(CR(m, (0, -0.005, 1.42), (0.09, 0.09, 0.09), redondez=0.6, cortes=1), "barro", "cuello", 0.3)
    # capucha de fibra oscura detrás y alrededor de la máscara
    pieza(CR(m, (0, 0.045, 1.485), (0.225, 0.195, 0.20), redondez=0.65, cortes=3, ruido_amp=0.006, semilla=23),
          "fibra_oscura", por_z([(1.40, "cuello"), (1.46, "cabeza")]), 0.25)
    # la máscara de mojón: pilar de arenisca más estrecho arriba, coronilla redonda pintada de ocre y blanco
    pieza(CR(m, (0, -0.05, 1.53), (0.20, 0.135, 0.27), redondez=0.32, cortes=2, ruido_amp=0.004, semilla=25,
             afinar=lambda z: 1.0 - 0.16 * (z + 0.5)), "mojon", "cabeza", 0.22)
    E.plano_uv(m, A, CR(m, (0, -0.05, 1.655), (0.17, 0.12, 0.05), redondez=0.7, cortes=2), "banda",
               (0, 0, 1.632), Vector((1, 0, 0)), Vector((0, 0, 1)), 0.2, 0.10, "cabeza")
    # talla del mojón: ojos hundidos, la cruz de deslinde en la frente y la raya de la boca (oscuros) y los ojos encendidos
    for l in (1, -1):
        pieza(m.caja((0.048 * l, -0.115, 1.545), (0.045, 0.012, 0.024)), "barro_oscuro", "cabeza", 0.2)
        brillo(m.esfera((0.048 * l, -0.121, 1.545), (0.011, 0.005, 0.009), (8, 5)), "cabeza")
    pieza(m.caja((0, -0.113, 1.60), (0.07, 0.01, 0.013)), "barro_oscuro", "cabeza", 0.2)
    pieza(m.caja((0, -0.113, 1.60), (0.013, 0.01, 0.06)), "barro_oscuro", "cabeza", 0.2)
    pieza(m.caja((0, -0.116, 1.488), (0.085, 0.01, 0.010)), "barro_oscuro", "cabeza", 0.2)

    # la franja blanca vertical del pecho: una tira pegada a la chaqueta (se busca su frente con rayos)
    bm_arbol = BVHTree.FromBMesh(m.bm)
    pts, rads = [], []
    for k in range(9):
        z = 1.00 + k * 0.045
        hit = bm_arbol.ray_cast(Vector((0, -1.0, z)), Vector((0, 1, 0)), 2.0)
        y = hit[0].y if hit[0] is not None else -0.13
        pts.append((0, y - 0.004, z))
        rads.append((0.036, 0.006))
    E.plano_uv(m, A, m.tubo(pts, rads, 6, ref=Vector((1, 0, 0))), "franja", (0, 0, 1.0), Vector((1, 0, 0)),
               Vector((0, 0, 1)), 0.12, 0.4, TRONCO)

    # las dos estacas de repuesto cruzadas a la espalda, con su abrazadera (rígidas, con el pecho)
    ESPALDA = []
    for l in (1, -1):
        a, b = Vector((0.16 * l, 0.17, 1.40)), Vector((-0.13 * l, 0.15, 0.98))
        d = (b - a).normalized()
        E.plano_uv(m, A, m.tubo([a, b - d * 0.12], [0.02, 0.02], 4, giro_seccion=math.pi / 4), "madera", a,
                   Vector((1, 0, 0)), d, 0.1, 0.5, "pecho")
        pieza(m.tubo([b - d * 0.12, b], [0.02, 0.002], 4, giro_seccion=math.pi / 4), "barro_oscuro", "pecho", 0.2,
              liso=False)
        E.plano_uv(m, A, m.tubo([a + d * 0.01, a + d * 0.13], [0.023, 0.023], 4, giro_seccion=math.pi / 4), "banda", a,
                   Vector((1, 0, 0)), d, 0.1, 0.12, "pecho")
        ESPALDA.append((a, b))
    pieza(CR(m, (0, 0.165, 1.21), (0.11, 0.05, 0.09), redondez=0.5, cortes=1), "fibra_oscura", "pecho", 0.25)

print("vértices sin pesos rellenados:", B.rellenar_pesos(m))
ob = m.objeto(NOMBRE, col)
E.materiales(ob, [NOMBRE + "_atlas", NOMBRE + "_brillo"])
C.enlazar(ob, arm)
TRIS = C.triangulos(ob)
E.oclusion(ob, rayos=24, dist=0.35, minimo=0.45)
print("triángulos:", TRIS)


def vista_rapida():
    """Solo para revisar la malla: frente, perfil y espalda (sin clips)."""
    A.guardar(os.path.join(LAMINAS, NOMBRE + "_atlas.png"), [(os.path.join(SALIDA, NOMBRE + ".webp"), 1024)])
    img = bpy.data.images.load(os.path.join(SALIDA, NOMBRE + ".webp"))
    E.material_vista(bpy.data.materials[NOMBRE + "_atlas"], img)
    E.material_vista(bpy.data.materials[NOMBRE + "_brillo"], None, emision=(*BRILLO, 2.0))
    B.lamina(esc, arm, ob, RAIZ, os.path.join(LAMINAS, NOMBRE + "_malla.png"), "Peón de Linde (e01) — malla en reposo",
             clip="")


if SOLO_MALLA:
    vista_rapida()
    print("hecho (solo malla)")
    raise SystemExit

# ================================================================== poses y clips
# 20 clips: los 18 del documento (con los nombres del juego; equivalencia en B.MAPA_CLIPS_BASE y en el JSON) y, por la
# adaptación al ATB, «carga» y «carga_espera» (el aviso de la Zancada pasa a ser un turno de preparación).
rig = E.Rig(arm, polo_codo={".L": Vector((0.7, 0.6, -0.3)), ".R": Vector((-0.7, 0.6, -0.3))})
TOB = {s: tuple(rig.tobillo[s]) for s in (".L", ".R")}
# en las poses se escribe la altura de la v1 (TOBP); clip() la lleva a la v2 (con FP = 1, nada cambia)
TOBP = {s: (TOB[s][0], TOB[s][1] / FP, TOB[s][2] / FP) for s in (".L", ".R")}
BAJA = 0.90 * (1 - FP)


def a_v2(pose):
    """Una pose escrita para las proporciones de la v1, llevada a las de la v2 (piernas cortas, tronco más bajo)."""
    if not V2:
        return pose
    out = dict(pose)
    for k, v in pose.items():
        if k == "raiz@loc" or (k.startswith("pie.") and k.endswith("@ik")):
            out[k] = (v[0], v[1] * FP, v[2] * FP)
        elif k.startswith("mano.") and k.endswith("@ik"):
            out[k] = (v[0], v[1], v[2] - BAJA)
    return out
CLIPS = {}
L, R, sim = E.L, E.R, E.sim
SLOT = [None]                         # dónde se guarda la estaca lanzada mientras «vuela»: bajo tierra (invisible), en ejes de la raíz


def extra(arm_, pose, f):
    # «arma.R@esp» = 1: la estaca de la derecha ya salió (el combate la vuela en 2D); el modelo la esconde bajo el suelo
    # hasta que la mano la «saca» del haz de la espalda («recoge»: la réplica reaparece en la mano, tras el hombro)
    if pose.get("arma.R@esp", (0, 0, 0))[0] > 0.5 and SLOT[0] is not None:
        bpy.context.view_layer.update()
        # (v2: bajo el suelo de verdad, 1,5 m bajo los pies; la v1, como estaba: lejos y fuera de la ventana)
        arm_.pose.bones["arma.R"].matrix = (Matrix.Translation((0, 0, -1.5)) @ arm_.data.bones["arma.R"].matrix_local) if V2 \
            else arm_.pose.bones["raiz"].matrix @ SLOT[0]


rig.extra = extra
# los objetivos de la IK de las manos van en todas las claves (con peso 0 donde no se usan): mezcla sin saltos
rig.defecto = {"mano.L@ik": (-0.05, -0.30, 1.44), "mano.R@ik": (0.05, -0.32, 1.38), "mano.L@ikw": 0.0, "mano.R@ikw": 0.0}
if V2:                                  # (el cruce del Piquete, a la altura de la cara de la v2)
    rig.defecto = a_v2(rig.defecto)


def P(*ds):
    out = {}
    for d in ds:
        out.update(d)
    return out


def luz(v):
    return {"luz@esc": (v, v, v)}


def esp(v):
    return {"arma.R@esp": (v, 0, 0)}


def clip(nombre, claves, bucle=False, proc=None, eventos=None):
    claves = [(c[0], a_v2(c[1])) + tuple(c[2:]) for c in claves]
    act, dur = rig.clip(nombre, claves, bucle, proc=proc)
    CLIPS[nombre] = {"duracion": round(dur, 4), "bucle": bucle, "eventos": eventos or {}}


def M(base, **cambios):
    """Variante de una pose: claves con «__» por «.» y «_AT_» por «@» (brazo__L=..., raiz_AT_loc=...)."""
    out = dict(base)
    for k, v in cambios.items():
        out[k.replace("__", ".").replace("_AT_", "@")] = v
    return out


# la guardia: agachado, el pie derecho atrás, las dos estacas hacia delante y abajo (la derecha más alta)
GUARDIA = P({"raiz@loc": (0, 0.0, -0.045), "cadera": (0, 0, -6), "columna_01": (4, 0, 2), "columna_02": (4, 0, 2),
             "pecho": (6, 0, 4), "cuello": (-4, 0, 0), "cabeza": (-8, 0, -4),
             "pie.L@ik": (0.17, -0.06, TOBP[".L"][2]), "pie.R@ik": (-0.16, 0.08, TOBP[".R"][2]), "pie.R@rot": (0, 0, 10)},
            L(brazo=(-18, -8, 0), antebrazo=(-42, 0, 0), mano=(-8, 0, 0)),
            R(brazo=(-30, 10, 0), antebrazo=(-58, 0, 0), mano=(-14, 0, 0)), esp(0), luz(1.0))

clip("reposo", [(0, GUARDIA),
                (0.5, M(GUARDIA, pecho=(8, 0, 4), cabeza=(-8, 0, 6), raiz_AT_loc=(0.008, 0, -0.06))),
                (1.0, M(GUARDIA, raiz_AT_loc=(0.012, 0, -0.045))),
                (1.5, M(GUARDIA, pecho=(8, 0, 2), cabeza=(-6, 0, -12), raiz_AT_loc=(0.004, 0, -0.06))),
                (2.0, GUARDIA)], bucle=True)

AGACHA = P(M(GUARDIA, raiz_AT_loc=(0, 0.02, -0.11), pecho=(16, 0, 4), cabeza=(-2, 0, 0)),
           L(brazo=(-8, -10, 0)), R(brazo=(-16, 12, 0)))
ALERTA = P(M(GUARDIA, raiz_AT_loc=(0, 0.0, 0.0), pecho=(-4, 0, 0), cabeza=(-18, 0, 0)),
           L(brazo=(-42, -6, 0), antebrazo=(-76, 0, 0)), R(brazo=(-52, 8, 0), antebrazo=(-84, 0, 0)), luz(1.8))
clip("alerta", [(0, GUARDIA), (0.12, AGACHA, "fren"), (0.28, ALERTA, "fren"), (0.6, GUARDIA)], eventos={"alerta": 0.12})

# entrada (spawn, 1,0 s): agazapado con las estacas clavadas delante y los ojos apagados; se encienden (0,3), las
# arranca y se planta en guardia de un pisotón (0,6)
CUCLILLAS = P({"raiz@loc": (0, 0.06, -0.40), "cadera": (0, 0, 0), "columna_01": (14, 0, 0), "columna_02": (14, 0, 0),
               "pecho": (22, 0, 0), "cuello": (6, 0, 0), "cabeza": (14, 0, 0),
               "pie.L@ik": (0.18, -0.04, TOBP[".L"][2]), "pie.R@ik": (-0.17, 0.04, TOBP[".R"][2])},
              L(brazo=(-22, -10, 0), antebrazo=(-6, 0, 0), mano=(18, 0, 0)),
              R(brazo=(-22, 10, 0), antebrazo=(-6, 0, 0), mano=(18, 0, 0)), esp(0), luz(0.0))
clip("entrada", [(0, CUCLILLAS), (0.3, P(CUCLILLAS, luz(0.4))), (0.45, P(M(CUCLILLAS, cabeza=(-6, 0, 0)), luz(1.6))),
                 (0.6, M(GUARDIA, raiz_AT_loc=(0, 0.0, -0.09)), "acel"), (1.0, GUARDIA)],
     eventos={"despierta": 0.3, "golpe_suelo": 0.6})

# locomoción en el sitio (el combate o el mapa mueven al actor)
clip("caminar", [(0, GUARDIA), (1.0, GUARDIA)], bucle=True,
     proc=B.pasos(rig, 1.0, 0.40 * FP, 0.10 * FP, 0.025, TOB[".L"], base=GUARDIA, brazos=10, inclina=4))
clip("correr", [(0, GUARDIA), (0.7, GUARDIA)], bucle=True,
     proc=B.pasos(rig, 0.7, 0.62 * FP, 0.16 * FP, 0.05, TOB[".L"], base=GUARDIA, brazos=24, inclina=14))
clip("lateral_izq", [(0, GUARDIA), (1.0, GUARDIA)], bucle=True,
     proc=B.pasos(rig, 1.0, 0.30 * FP, 0.08 * FP, 0.02, TOB[".L"], base=GUARDIA, brazos=4, lateral=1))
clip("lateral_der", [(0, GUARDIA), (1.0, GUARDIA)], bucle=True,
     proc=B.pasos(rig, 1.0, 0.30 * FP, 0.08 * FP, 0.02, TOB[".L"], base=GUARDIA, brazos=4, lateral=-1))
clip("girar_izq", [(0, GUARDIA), (0.5, GUARDIA)], proc=B.girar(rig, "izq", TOB[".L"], GUARDIA))
clip("girar_der", [(0, GUARDIA), (0.5, GUARDIA)], proc=B.girar(rig, "der", TOB[".L"], GUARDIA))

# reacciones
SACUDIDA = P(M(GUARDIA, pecho=(-16, 0, 10), cabeza=(-22, 0, 8), raiz_AT_loc=(0, 0.07, -0.03)),
             L(brazo=(-6, -26, 0), antebrazo=(-30, 0, 0)), R(brazo=(-12, 26, 0), antebrazo=(-40, 0, 0)), luz(0.35))
clip("recibir_golpe", [(0, GUARDIA), (0.08, SACUDIDA, "fren"), (0.35, GUARDIA)], eventos={"golpe": 0.0})
SACUDIDA_E = P(M(GUARDIA, pecho=(24, 0, -6), cabeza=(18, 0, 0), columna_02=(10, 0, 0), raiz_AT_loc=(0, -0.07, -0.03)),
               L(brazo=(20, -14, 0)), R(brazo=(18, 14, 0)), luz(0.35))
clip("recibir_golpe_espalda", [(0, GUARDIA), (0.08, SACUDIDA_E, "fren"), (0.35, GUARDIA)], eventos={"golpe": 0.0})
FLOJO = P(M(GUARDIA, raiz_AT_loc=(0, 0.02, -0.07), pecho=(14, 0, 0)),
          L(brazo=(4, -10, 0), antebrazo=(-12, 0, 0), mano=(10, 0, 0)),
          R(brazo=(2, 10, 0), antebrazo=(-16, 0, 0), mano=(10, 0, 0)))
clip("aturdido", [(0, FLOJO), (0.8, FLOJO)], bucle=True, proc=B.aturdido_proc(FLOJO, 0.8))

# derrota (1,4 s): sacudida, cae de rodillas (0,45) soltando los brazos y se desploma de bruces (1,05); los ojos se apagan
RODILLAS = P({"raiz@loc": (0, 0.10, -0.46), "cadera": (0, 0, 0), "columna_01": (10, 0, 0), "columna_02": (8, 0, 0),
              "pecho": (14, 0, -6), "cuello": (8, 0, 0), "cabeza": (22, 0, 8),
              "pie.L@ik": (0.17, 0.36, 0.07), "pie.R@ik": (-0.16, 0.38, 0.07), "pie.L@rot": (-75, 0, 0),
              "pie.R@rot": (-75, 0, 0)},
             L(brazo=(8, -14, 0), antebrazo=(-10, 0, 0), mano=(14, 0, 0)),
             R(brazo=(6, 14, 0), antebrazo=(-12, 0, 0), mano=(14, 0, 0)), esp(0), luz(0.6))
BRUCES = P(RODILLAS, {"raiz": (72, 0, 0), "raiz@loc": (0, 0.42, -0.30), "pecho": (10, 0, -8), "cabeza": (-20, 0, 25),
                      "columna_01": (4, 0, 0), "columna_02": (4, 0, 0),
                      "pie.L@ik": (0.18, 0.62, 0.10), "pie.R@ik": (-0.16, 0.66, 0.09), "pie.L@rot": (-95, 0, 0),
                      "pie.R@rot": (-95, 0, 0)},
           L(brazo=(-150, -30, 0), antebrazo=(-10, 0, 0)), R(brazo=(-130, 40, 0), antebrazo=(-20, 0, 0)), luz(0.0))
clip("derrota", [(0, GUARDIA), (0.12, SACUDIDA, "fren"), (0.45, RODILLAS, "acel"),
                 (0.62, M(RODILLAS, pecho=(24, 0, -6))), (1.05, BRUCES, "acel"),
                 (1.2, M(BRUCES, raiz_AT_loc=(0, 0.42, -0.27))), (1.4, BRUCES)],
     eventos={"rodillas": 0.45, "suelo": 1.05})
clip("desaparecer", [(0, BRUCES), (0.15, M(BRUCES, raiz_AT_loc=(0, 0.42, -0.33))),
                     (0.6, P(M(BRUCES, raiz_AT_loc=(0, 0.42, -0.95)), {"pie.L@ik": (0.18, 0.62, -0.55), "pie.R@ik": (-0.16, 0.66, -0.56)}), "acel")], eventos={"hundido": 0.6})

# A1 · Piquete cruzado (ataque, 1,25 s): cruza las estacas ante la máscara (aviso 0-0,55) y las abre en diagonal hacia
# abajo con un paso (IMPACTO 0,62; activo 0,55-0,70); recupera hasta T
CRUZ = P(M(GUARDIA, raiz_AT_loc=(0, 0.04, -0.07), pecho=(-6, 0, 0), columna_02=(0, 0, 0), cabeza=(-6, 0, 0)),
         L(brazo=(-70, 52, 0), antebrazo=(-112, 0, 0), mano=(0, 60, -60)),
         R(brazo=(-74, -52, 0), antebrazo=(-112, 0, 0), mano=(0, -60, 60)),
         {"mano.L@ik": (-0.05, -0.30, 1.44), "mano.L@ikw": 1.0, "mano.R@ik": (0.05, -0.32, 1.38), "mano.R@ikw": 1.0},
         luz(1.6))
CRUZ2 = P(M(CRUZ, pecho=(-12, 0, 0), raiz_AT_loc=(0, 0.06, -0.06)),
          {"mano.L@ik": (-0.05, -0.28, 1.50), "mano.R@ik": (0.05, -0.30, 1.45)},
          luz(2.2))
ABRE = P(M(GUARDIA, raiz_AT_loc=(0, -0.16, -0.10), pecho=(18, 0, 0), columna_02=(8, 0, 0), cabeza=(-14, 0, 0)),
         {"pie.R@ik": (-0.16, -0.22, TOBP[".R"][2]), "pie.R@rot": (0, 0, 0), "pie.L@ik": (0.17, 0.02, TOBP[".L"][2])},
         L(brazo=(-52, -58, 0), antebrazo=(-14, 0, 0), mano=(-10, 0, 0)),
         R(brazo=(-56, 60, 0), antebrazo=(-14, 0, 0), mano=(-10, 0, 0)), luz(2.0))
SIGUE = P(M(ABRE, pecho=(22, 0, 0)), L(brazo=(-30, -70, 0)), R(brazo=(-32, 72, 0)))
T_PIQUETE = 0.62
clip("ataque", [(0, GUARDIA), (0.15, AGACHA), (0.42, CRUZ, "fren"), (0.55, CRUZ2, "lin"), (T_PIQUETE, ABRE, "acel"),
                (0.75, SIGUE, "fren"), (0.95, M(SIGUE, pecho=(14, 0, 0))), (1.25, GUARDIA)],
     eventos={"aviso": 0.0, "impacto": T_PIQUETE})

# A2 · Estaca de aviso (lanzar, 1,70 s): hinca la rodilla derecha y echa atrás la estaca (aviso 0-0,85), la lanza
# (SUELTA = «impacto» 0,85: sale la estaca; el daño, al llegar), lleva la mano a la espalda y saca otra del haz
# («recoge» 1,25: la réplica reaparece) y se levanta
RODILLA = P(M(GUARDIA, raiz_AT_loc=(0, 0.06, -0.34), cadera=(0, 0, -12), pecho=(4, 0, -22), columna_02=(2, 0, -8),
              cabeza=(-10, 0, 18)),
            {"pie.L@ik": (0.18, -0.24, TOBP[".L"][2]), "pie.R@ik": (-0.15, 0.32, 0.07), "pie.R@rot": (-62, 0, 0)},
            R(brazo=(-150, 34, 0), antebrazo=(-104, 0, 0), mano=(150, 0, 0)),
            L(brazo=(-72, -8, 0), antebrazo=(-12, 0, 0), mano=(0, 0, 0)), luz(1.6))
SUELTA = P(M(RODILLA, pecho=(18, 0, 24), columna_02=(6, 0, 8), cabeza=(-14, 0, -6)),
           R(brazo=(-96, -10, 0), antebrazo=(-8, 0, 0), mano=(-24, 0, 0)), L(brazo=(-20, -32, 0), antebrazo=(-34, 0, 0)),
           luz(2.0))
TRAS = P(M(SUELTA, pecho=(24, 0, 28)), R(brazo=(-62, -12, 0)))
RECOGE = P(M(RODILLA, pecho=(0, 0, -10), cabeza=(-6, 0, -8)),
           R(brazo=(-188, 32, 0), antebrazo=(-122, 0, 0), mano=(0, 0, 0)), L(brazo=(-40, -14, 0), antebrazo=(-30, 0, 0)),
           luz(1.2))
rig.aplicar(a_v2(P(rig.defecto, RECOGE)))
bpy.context.view_layer.update()
SLOT[0] = Matrix.Translation((0, 0, -3.0)) @ arm.data.bones["arma.R"].matrix_local
T_SUELTA, T_RECOGE = 0.85, 1.25
UN_F = 1.0 / E.FPS
clip("lanzar", [(0, GUARDIA), (0.35, RODILLA, "fren"), (0.6, M(RODILLA, pecho=(0, 0, -26))), (T_SUELTA, SUELTA, "acel"),
                (T_SUELTA + UN_F, P(SUELTA, esp(1)), "corte"), (0.98, P(TRAS, esp(1)), "fren"),
                (T_RECOGE - UN_F, P(RECOGE, esp(1))), (T_RECOGE, P(RECOGE, esp(0)), "corte"),
                (1.45, M(GUARDIA, raiz_AT_loc=(0, 0.02, -0.12))), (1.7, GUARDIA)],
     eventos={"aviso": 0.0, "impacto": T_SUELTA, "recoge": T_RECOGE})

# A3 · Zancada de lindero (zancada, 1,90 s): alza la rodilla con las estacas atrás (aviso 0-0,90; en el combate ese aviso
# es un TURNO: «carga» y «carga_espera»), y avanza de una estocada con las dos (IMPACTO 1,0; activo 0,90-1,12)
ALZA = P(M(GUARDIA, raiz_AT_loc=(0, 0.07, 0.0), pecho=(-10, 0, 6), columna_02=(-2, 0, 0), cabeza=(-6, 0, -6)),
         {"pie.L@ik": (0.15, -0.14, 0.44), "pie.L@rot": (24, 0, 0), "pie.R@ik": (-0.15, 0.06, TOBP[".R"][2]),
          "pie.R@rot": (0, 0, 6)},
         L(brazo=(26, -12, 0), antebrazo=(-74, 0, 0), mano=(-22, 0, 0)),
         R(brazo=(30, 12, 0), antebrazo=(-78, 0, 0), mano=(-22, 0, 0)), luz(1.6))
ALZA2 = P(M(ALZA, pecho=(-12, 0, 6), raiz_AT_loc=(0, 0.08, 0.012)), {"pie.L@ik": (0.15, -0.15, 0.47)}, luz(2.0))
ESTOCADA = P(M(GUARDIA, raiz_AT_loc=(0, -0.42, -0.17), pecho=(24, 0, 0), columna_01=(6, 0, 0), columna_02=(8, 0, 0),
               cabeza=(-20, 0, 0)),
             {"pie.L@ik": (0.17, -0.64, TOBP[".L"][2]), "pie.L@rot": (0, 0, 0), "pie.R@ik": (-0.16, 0.20, TOBP[".R"][2]),
              "pie.R@rot": (-14, 0, 8)},
             L(brazo=(-86, 14, 0), antebrazo=(-6, 0, 0), mano=(-30, 0, 0)),
             R(brazo=(-88, -14, 0), antebrazo=(-6, 0, 0), mano=(-30, 0, 0)), luz(2.4))
T_CARGA, T_ZANCADA = 0.9, 1.0
clip("zancada", [(0, GUARDIA), (0.6, ALZA, "fren"), (T_CARGA, ALZA2), (T_ZANCADA, ESTOCADA, "acel"),
                 (1.12, M(ESTOCADA, pecho=(27, 0, 0)), "fren"),
                 (1.5, P(M(ESTOCADA, raiz_AT_loc=(0, -0.20, -0.09), pecho=(12, 0, 0)), {"pie.L@ik": (0.17, -0.34, 0.10)})),
                 (1.7, P(M(GUARDIA, raiz_AT_loc=(0, -0.06, -0.06)), {"pie.L@ik": (0.17, -0.16, 0.19)})),
                 (1.9, GUARDIA)], eventos={"aviso": 0.0, "carga": T_CARGA, "impacto": T_ZANCADA, "pisada": T_ZANCADA})
clip("carga", [(0, GUARDIA), (0.6, ALZA, "fren"), (T_CARGA, ALZA2)], eventos={"arriba": T_CARGA})
clip("carga_espera", [(0, ALZA2), (0.6, P(M(ALZA2, pecho=(-14, 0, 8), raiz_AT_loc=(0, 0.08, 0.026)), luz(2.6))),
                      (1.2, ALZA2)], bucle=True)

# retroceso (retreat_step, 0,65 s): dos saltitos hacia atrás (en el sitio; el combate lo desplaza) tras golpear
VUELO = P(M(GUARDIA, raiz_AT_loc=(0, 0.02, 0.05), pecho=(-6, 0, 0)),
          {"pie.L@ik": (0.17, -0.02, 0.20), "pie.R@ik": (-0.16, 0.12, 0.18)},
          L(brazo=(-30, -18, 0)), R(brazo=(-40, 18, 0)))
clip("retroceso", [(0, GUARDIA), (0.12, AGACHA, "fren"), (0.25, VUELO, "fren"),
                   (0.33, M(GUARDIA, raiz_AT_loc=(0, 0.0, -0.10)), "acel"), (0.65, GUARDIA)], eventos={"paso": 0.33})


def medir():
    datos = {}
    for c_, t, h, local in (("ataque", T_PIQUETE, "arma.R", (0, 0.74, 0)), ("ataque", T_PIQUETE, "arma.L", (0, 0.74, 0)),
                            ("lanzar", T_SUELTA, "mano.R", (0, 0.06, 0)), ("zancada", T_ZANCADA, "arma.R", (0, 0.74, 0))):
        p = E.punto_hueso(arm, rig, c_, t, h, local)
        datos["%s_%s" % (c_, h)] = [round(p.x, 3), round(p.z, 3), round(-p.y, 3)]
    p = E.punto_hueso(arm, rig, "reposo", 0.0, "cabeza", (0, 0.2, 0))
    datos["alto_reposo"] = round(p.z, 3)
    return datos


medidas = medir()
arm.animation_data.action = None
for pb in arm.pose.bones:
    pb.rotation_quaternion = Quaternion()
    pb.location = Vector()
    pb.scale = Vector((1, 1, 1))

if SOLO_LAMINA:                       # la lámina con los tres héroes, sin escribir nada del juego
    A.guardar(os.path.join(LAMINAS, NOMBRE + SUFIJO + "_atlas.png"), [])
    img = bpy.data.images.load(os.path.join(LAMINAS, NOMBRE + SUFIJO + "_atlas.png"))
    E.material_vista(bpy.data.materials[NOMBRE + "_atlas"], img)
    E.material_vista(bpy.data.materials[NOMBRE + "_brillo"], None, emision=(*BRILLO, 2.0))
    B.lamina_heroes(esc, arm, ob, RAIZ, os.path.join(LAMINAS, NOMBRE + (SUFIJO or "_v1") + "_heroes.png"),
                    "Peón de Linde (e01) %s — junto a Kael, Lya y Garon" % ("v2" if V2 else "v1"))
    print("hecho (solo lámina)")
    raise SystemExit
A.guardar(os.path.join(LAMINAS, NOMBRE + SUFIJO + "_atlas.png"),
          [(os.path.join(SALIDA, NOMBRE + SUFIJO + ".webp"), 1024), (os.path.join(SALIDA, NOMBRE + SUFIJO + "_bajo.webp"), 512)])
if V2:                                  # normales del relieve pintado (grietas, trama, cincel), por celdas
    B.guardar_imagen(B.normal_desde_alturas(A.img, 2.2, A.c), os.path.join(SALIDA, NOMBRE + SUFIJO + "_normal.webp"))
E.exportar(os.path.join(SALIDA, NOMBRE + SUFIJO + ".glb"))
MAPA = dict(B.MAPA_CLIPS_BASE)
MAPA.update({"attack_01": "ataque", "attack_02": "lanzar", "attack_03": "zancada", "retreat_step": "retroceso"})
ALTO_REAL = round(max(v.co.z for v in ob.data.vertices), 3)
E.guardar_json(os.path.join(SALIDA, NOMBRE + SUFIJO + "_clips.json"), {
    "id": ID, "modelo": NOMBRE + SUFIJO, "alto_m": ALTO_REAL, "triangulos": TRIS, "huesos": len(HUESOS),
    "deformantes": B.contar_deformantes(arm), "fps": E.FPS,
    "texturas": {"alto": NOMBRE + SUFIJO + ".webp (1024)", "bajo": NOMBRE + SUFIJO + "_bajo.webp (512)",
                 "normales": (NOMBRE + SUFIJO + "_normal.webp (1024)") if V2 else ""},
    "proporciones": PROP,
    "color_brillo": BRILLO, "clips": CLIPS, "mapa_pdf": MAPA, "solo_atb": ["carga", "carga_espera"], "medidas": medidas,
    "generador": "enemigos/peon_linde/fuente/crear_peon_linde.py%s (Blender 5.2.3)" % (" -- ... v2" if V2 else "")})
print("clips (%d):" % len(CLIPS), {k: v["duracion"] for k, v in CLIPS.items()})
print("medidas:", medidas)

if CON_LAMINAS:
    img = bpy.data.images.load(os.path.join(SALIDA, NOMBRE + SUFIJO + ".webp"))
    E.material_vista(bpy.data.materials[NOMBRE + "_atlas"], img)
    E.material_vista(bpy.data.materials[NOMBRE + "_brillo"], None, emision=(*BRILLO, 2.0))
    B.lamina(esc, arm, ob, RAIZ, os.path.join(LAMINAS, NOMBRE + SUFIJO + "_lamina.png"),
             "Peón de Linde (e01) — hostigador de Pastos Verdes y caminos", clip="reposo")
    for o in list(esc.objects):
        if o.type == 'CAMERA':
            bpy.data.objects.remove(o)
    for o in esc.objects:
        if o.name.startswith("kael") or (o.parent and o.parent.name.startswith("kael")):
            o.hide_render = True
    arm.location = (0, 0, 0)
    arm.rotation_euler = (0, 0, 0)
    esc.render.resolution_x, esc.render.resolution_y = 700, 800
    inst = [("reposo", 0.0), ("alerta", 0.28), ("entrada", 0.0), ("caminar", 0.25), ("correr", 0.2),
            ("lateral_izq", 0.25), ("girar_der", 0.25),
            ("ataque", 0.42), ("ataque", 0.55), ("ataque", T_PIQUETE), ("ataque", 0.75),
            ("lanzar", 0.35), ("lanzar", 0.6), ("lanzar", T_SUELTA), ("lanzar", 0.98), ("lanzar", T_RECOGE),
            ("lanzar", 1.45), ("carga_espera", 0.0), ("zancada", T_ZANCADA), ("zancada", 1.12), ("zancada", 1.5),
            ("retroceso", 0.25), ("recibir_golpe", 0.08), ("recibir_golpe_espalda", 0.08),
            ("aturdido", 0.2), ("derrota", 0.45), ("derrota", 1.4), ("desaparecer", 0.3)]
    carpeta = os.path.join(LAMINAS, "poses")
    os.makedirs(carpeta, exist_ok=True)
    rutas = E.poses_render(esc, arm, inst, carpeta, NOMBRE + SUFIJO, objetivo=(0, -0.3, 0.85 * (0.88 if V2 else 1.0)),
                           azimut=-40, elev=10, orto=2.9 * (0.9 if V2 else 1.0))
    E.componer(rutas, os.path.join(LAMINAS, NOMBRE + SUFIJO + "_poses.png"), 7)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(LAMINAS, NOMBRE + SUFIJO + ".blend"))
print("hecho")
