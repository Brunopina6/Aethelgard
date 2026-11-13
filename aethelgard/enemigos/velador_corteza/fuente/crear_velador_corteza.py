# e02 · Velador de Corteza (V12, bestiario de producción, 13/11/2026, especialista de enemigos «bestiario»).
# Defensor común del Gran Bosque Verde y los santuarios de raíz. Ficha del encargo (Aethelgard_Bestiario_Produccion.pdf,
# págs. 5-6): cuerpo leñoso, máscara oval de CORCHO, escudo de ANILLOS fijo al antebrazo izquierdo y MAZA de poda en la
# derecha; musgo turquesa en las grietas; hombro en forma de ALERO; placas de corteza separadas en codos y rodillas.
# Lectura propia: el guarda que podaba los lindes del bosque; la corteza le ha crecido encima, lleva por escudo la
# rodaja de un tronco viejo (con sus anillos) y una maza de poda con la hoja curva de la podadera en el canto.
# Familia «pesada» del documento: el mismo rig base que el Peón (bestiario_rig.py), más alto (1,95 m) y ancho.
#
#   blender -b --factory-startup -P crear_velador_corteza.py -- <raíz aethelgard> <carpeta de láminas> [sin_laminas] [solo_malla]
#
# Escribe enemigos/velador_corteza/velador_corteza.glb, velador_corteza.webp (1024), velador_corteza_bajo.webp (512) y
# velador_corteza_clips.json; en la carpeta de láminas, la lámina, la hoja de poses, el atlas y el .blend (fuera de Git).
# Ejes (Blender): mira a -Y, Z arriba, su izquierda es +X. En Godot mira a +Z.
import bpy, sys, os, math, random
from mathutils import Vector, Euler, Quaternion, Matrix

argv = sys.argv[sys.argv.index("--") + 1:]
RAIZ, LAMINAS = argv[0], argv[1]
CON_LAMINAS = "sin_laminas" not in argv
SOLO_MALLA = "solo_malla" in argv
SOLO_LAMINA = "solo_lamina" in argv          # solo la lámina con Kael, Lya y Garon (no escribe nada del juego)
# V2 (13/11, segunda pasada de arte): proporciones compactas y formas redondeadas (malla_velador_v2.py). Escribe los
# archivos con «_v2» al lado de la v1, que no cambia.
V2 = "v2" in argv
SUFIJO = "_v2" if V2 else ""
PROP = {"piernas": 0.66, "cabeza": 1.25, "brazos": 0.88} if V2 else {}
FP = PROP.get("piernas", 1.0)
sys.path.insert(0, os.path.join(RAIZ, "personajes", "desierto", "fuentes_blender"))
sys.path.insert(0, os.path.join(RAIZ, "enemigos", "v12_comun", "fuente"))
sys.path.insert(0, os.path.join(RAIZ, "enemigos", "bestiario_comun", "fuente"))
import desierto_comun as C
import enemigos_v12_blender as E
import bestiario_rig as B
import numpy as np

SALIDA = os.path.join(RAIZ, "enemigos", "velador_corteza")
NOMBRE = "velador_corteza"
ID = "e02"
ALTO = 1.95
ANCHO, HOMBROS = 1.22, 1.28
os.makedirs(SALIDA, exist_ok=True)
os.makedirs(LAMINAS, exist_ok=True)
random.seed(202)
esc = C.escena_vacia()
col = esc.collection

# ================================================================== atlas

A = E.AtlasV12(1024, 4, semilla=202)


def malla_xy(h):
    yy, xx = np.mgrid[0:h, 0:h]
    return (xx + 0.5) / h, (yy + 0.5) / h


def pinta_corteza(h, rng, base=(0.36, 0.27, 0.20), musgo=0.35):
    """Corteza de surcos verticales (a lo largo de v), crestas claras, grietas profundas con musgo turquesa."""
    X, Y = malla_xy(h)
    surco = E.ruido(h, 18, rng)[0][None, :] * np.ones((h, 1))
    torcido = E.fbm(h, rng, 3, 4)
    onda = np.abs(np.sin((X * 5 + 1.1 * torcido + 0.25 * E.fbm(h, rng, 8, 3)) * math.pi))
    placas = E.grietas(h, rng, 12, 0.012)                                                      # placas de corteza
    f = E.fbm(h, rng, 4, 5)
    img = E.color(base) * (0.65 + 0.45 * onda[..., None] * (0.7 + 0.4 * f[..., None]))
    img = E.mezclar(img, (0.55, 0.45, 0.34), np.clip((onda - 0.85) * 5, 0, 0.6))            # crestas
    profundo = np.maximum(np.clip((0.18 - onda) * 6, 0, 1), placas * 0.8)
    img = E.mezclar(img, (0.12, 0.09, 0.07), profundo * 0.8)
    m = np.clip((E.fbm(h, rng, 6, 4) - (1.0 - musgo)) * 6, 0, 1) * profundo
    img = E.mezclar(img, (0.22, 0.62, 0.56), m)                                              # musgo turquesa
    _ = surco
    return img


def pinta_corteza_clara(h, rng):
    return pinta_corteza(h, rng, (0.50, 0.40, 0.30), 0.2)


def pinta_anillos(h, rng):
    """La rodaja del escudo: anillos de crecimiento, médula, grietas radiales y el borde de corteza."""
    X, Y = malla_xy(h)
    cx, cy = 0.5 + rng.uniform(-0.04, 0.04), 0.5 + rng.uniform(-0.04, 0.04)
    r = np.sqrt((X - cx) ** 2 + (Y - cy) ** 2)
    ang = np.arctan2(Y - cy, X - cx)
    dist = r * (1 + 0.04 * np.sin(ang * 5) + 0.05 * (E.fbm(h, rng, 4, 3) - 0.5))
    anillo = 0.5 + 0.5 * np.sin(dist * 2 * math.pi * 22)
    img = E.color((0.74, 0.58, 0.40)) * (0.80 + 0.22 * anillo[..., None])
    img = E.mezclar(img, (0.50, 0.34, 0.22), np.clip((anillo - 0.85) * 6, 0, 0.7))
    for k in range(5):
        a0 = rng.uniform(-math.pi, math.pi)
        d = np.abs(((ang - a0 + math.pi) % (2 * math.pi)) - math.pi)
        img = E.mezclar(img, (0.20, 0.14, 0.10), np.clip((0.02 - d * r) * 120, 0, 1) * (r > 0.08) * (r < 0.40))
    img = E.mezclar(img, (0.30, 0.22, 0.16), np.clip((r - 0.44) * 30, 0, 1))                 # borde de corteza
    return E.mezclar(img, (0.42, 0.30, 0.18), np.clip((0.03 - r) * 40, 0, 1))                # médula


def pinta_corcho(h, rng):
    """Corcho: marrón claro con poros y lenticelas oscuras."""
    f = E.fbm(h, rng, 6, 5)
    img = E.color((0.76, 0.58, 0.40)) * (0.82 + 0.3 * f[..., None])
    poros = rng.random((h, h)) < 0.03
    img[poros] = img[poros] * 0.5
    f1, f2 = E.celdas_voronoi(h, rng, 40)
    return E.mezclar(img, (0.48, 0.34, 0.22), np.clip((0.02 - (f2 - f1)) * 40, 0, 0.6))


def pinta_musgo(h, rng):
    f = E.fbm(h, rng, 8, 5)
    img = E.color((0.16, 0.44, 0.38)) * (0.60 + 0.60 * f[..., None])
    motas = rng.random((h, h)) < 0.05
    img[motas] = img[motas] * 1.3
    return img


def pinta_madera(h, rng):
    X, Y = malla_xy(h)
    veta = E.ruido(h, 36, rng)[0][None, :] * np.ones((h, 1))
    img = E.color((0.56, 0.42, 0.28)) * (0.72 + 0.4 * veta[..., None])
    return E.mezclar(img, (0.30, 0.20, 0.13), E.grietas(h, rng, 10, 0.004) * 0.5)


def pinta_nudo(h, rng):
    """Cabeza de la maza: madera de raíz nudosa, oscura, con vetas en remolino."""
    X, Y = malla_xy(h)
    f = E.fbm(h, rng, 3, 5)
    rem = np.sin((X * 6 + f * 4) * math.pi) * np.cos((Y * 5 + f * 3) * math.pi)
    img = E.color((0.30, 0.21, 0.15)) * (0.75 + 0.35 * (0.5 + 0.5 * rem)[..., None])
    return E.mezclar(img, (0.16, 0.11, 0.08), E.grietas(h, rng, 14, 0.006) * 0.6)


def pinta_hierro(h, rng):
    """La hoja de podadera del canto de la maza: hierro viejo, oscuro, con el filo claro."""
    X, Y = malla_xy(h)
    f = E.fbm(h, rng, 6, 4)
    img = E.color((0.30, 0.31, 0.32)) * (0.75 + 0.4 * f[..., None])
    img = E.mezclar(img, (0.48, 0.30, 0.18), np.clip((E.fbm(h, rng, 5, 3) - 0.6) * 4, 0, 0.7))   # óxido
    return E.mezclar(img, (0.70, 0.71, 0.70), np.clip((Y - 0.85) * 8, 0, 0.8))


for nombre, f in (("corteza", pinta_corteza), ("corteza_clara", pinta_corteza_clara), ("anillos", pinta_anillos),
                  ("corcho", pinta_corcho), ("musgo", pinta_musgo), ("madera", pinta_madera), ("nudo", pinta_nudo),
                  ("hierro", pinta_hierro)):
    A.celda(nombre, f)

BRILLO = (0.40, 0.95, 0.85)            # turquesa del musgo encendido (velador_corteza_3d.gd, COLOR_BRILLO)

# ================================================================== esqueleto (rig base del bestiario, más grande)

_hs = {n: (Vector(a), Vector(b)) for n, a, b, p in B.huesos(ALTO, ANCHO, HOMBROS, **PROP)}
PUNO_R = _hs["mano.R"][0].lerp(_hs["mano.R"][1], 0.5)
ESCUDO_C = _hs["antebrazo.L"][0].lerp(_hs["antebrazo.L"][1], 0.55) + Vector((0.07, -0.05, 0))   # por fuera del antebrazo
DIR_MAZA = Vector((0.0, -0.55, -0.83)).normalized()            # en reposo, la maza cuelga hacia delante y abajo
SOCKETS = {
    "arma.R": (PUNO_R, PUNO_R + DIR_MAZA * 0.3, "mano.R", True),
    "arma.L": (ESCUDO_C, ESCUDO_C + Vector((0.3, 0, 0)), "antebrazo.L", True),
    "pecho_fx": ((0, -0.24, 1.48 - 0.9 * ALTO / 1.65 * (1 - FP)), (0, -0.40, 1.48 - 0.9 * ALTO / 1.65 * (1 - FP)), "pecho", False),
    "luz": ((0, 0.1, 0.0), (0, 0.1, 0.15), "raiz", False),
}
arm, HUESOS = B.crear(NOMBRE, col, ALTO, ANCHO, HOMBROS, sockets=SOCKETS, **PROP)
print("huesos deformantes:", B.contar_deformantes(arm), "de", len(HUESOS))

if V2:                                  # la v2 (13/11): malla_velador_v2.py, con su atlas y su mapa de normales
    exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "malla_velador_v2.py"), encoding="utf-8").read())
else:
    # ================================================================== malla

    m = C.Malla(None, ("atlas", "brillo"))
    CR = E.caja_redonda


    def pieza(vs, celda, pesos, escala=0.5, liso=True):
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


    k = ALTO / 1.65
    TRONCO = por_z([(1.10, "cadera"), (1.22, "columna_01"), (1.36, "columna_02"), (1.54, "pecho")])

    for s, l in ((".L", 1), (".R", -1)):
        pierna = B.eje(arm, [("muslo" + s, 0.0), ("muslo" + s, 0.82), ("pierna" + s, 0.12), ("pierna" + s, 1.0)])
        hx = _hs["muslo" + s][0].x
        kx = _hs["pierna" + s][0].x
        ax = _hs["pie" + s][0].x
        # piernas: troncos gruesos de corteza, más anchos abajo (raíces)
        pieza(m.tubo([(hx, 0.0, 1.10), (hx * 1.05, -0.01, 0.86), (kx, -0.02, 0.60), (ax * 0.98, 0.0, 0.36),
                      (ax, 0.01, 0.16)], [0.12, 0.11, 0.09, 0.095, 0.10], 10), "corteza", pierna, 0.4)
        # pies de raíz: un tocón ancho con tres raíces delante
        pie = B.mezcla(B.fijo("pie" + s), B.fijo("dedos" + s), lambda co: (-co.y - 0.10) / 0.10)
        pieza(CR(m, (ax, -0.05, 0.075), (0.21, 0.34, 0.15), redondez=0.5, cortes=2, ruido_amp=0.015, semilla=3 + l),
              "corteza_clara", pie, 0.35)
        for j, dx in enumerate((-0.06, 0.0, 0.06)):
            pieza(m.tubo([(ax + dx, -0.15, 0.08), (ax + dx * 1.6, -0.26, 0.04)], [0.035, 0.012], 5), "corteza", pie, 0.3)
        # placas de corteza en las rodillas (separadas: no se deforman)
        pieza(CR(m, (kx, -0.10, 0.61), (0.15, 0.06, 0.16), giro(-10, 0, 0), redondez=0.5, cortes=1, ruido_amp=0.01,
                 semilla=5 + l), "corteza_clara", "pierna" + s, 0.3)
        # brazos: troncos con placa en el codo
        brazo = B.eje(arm, [("clavicula" + s, 0.5), ("brazo" + s, 0.0), ("brazo" + s, 0.85), ("antebrazo" + s, 0.15),
                            ("antebrazo" + s, 1.0)])
        b0, b1 = _hs["brazo" + s]
        a0, a1 = _hs["antebrazo" + s]
        pieza(m.tubo([b0 + Vector((0, 0, 0.02)), b0.lerp(b1, 0.5), b1, a0.lerp(a1, 0.5), a1],
                     [0.095, 0.085, 0.075, 0.072, 0.066], 10), "corteza", brazo, 0.4)
        pieza(CR(m, b1 + Vector((0, 0.07, 0)), (0.14, 0.07, 0.15), redondez=0.5, cortes=1, ruido_amp=0.01, semilla=7 + l),
              "corteza_clara", "antebrazo" + s, 0.3)
        # manos: puños de madera grandes
        mano0, mano1 = _hs["mano" + s]
        dm = (mano1 - mano0).normalized()
        pieza(CR(m, mano0.lerp(mano1, 0.5), (0.15, 0.15, 0.18), Vector((0, 0, -1)).rotation_difference(dm).to_euler(),
                 redondez=0.6, cortes=2, ruido_amp=0.01, semilla=9 + l), "corteza_clara", "mano" + s, 0.3)

    # cadera y tronco: un barril de corteza, más ancho en el pecho (defensor), con grietas de musgo
    pieza(CR(m, (0, 0.0, 1.10), (0.46, 0.32, 0.26), redondez=0.55, cortes=2, ruido_amp=0.01, semilla=11), "corteza",
          por_z([(1.08, "cadera"), (1.22, "columna_01")]), 0.45)
    pieza(CR(m, (0, 0.01, 1.42), (0.58, 0.40, 0.56), redondez=0.55, cortes=3, ruido_amp=0.015, semilla=13,
             afinar=lambda z: 0.86 + 0.24 * (z + 0.5)), "corteza", TRONCO, 0.45)
    # faldón de corteza (tiras rígidas por delante y detrás, con la cadera y los muslos)
    for sy in (-1, 1):
        for l in (1, -1):
            s = ".L" if l == 1 else ".R"
            pieza(CR(m, (0.12 * l, 0.15 * sy, 0.94), (0.17, 0.05, 0.30), giro(10 * sy, -10 * l, 0), redondez=0.4, cortes=1,
                     ruido_amp=0.01, semilla=15 + l + sy),
                  "corteza_clara", lambda co, s=s: {"cadera": 0.6, "muslo" + s: 0.4}, 0.3)
    # musgo en los hombros y el pecho
    for p0, r0 in (((0.20, -0.18, 1.62), 0.08), ((-0.14, -0.20, 1.30), 0.06), ((0.28, 0.12, 1.68), 0.09)):
        pieza(E.roca(m, p0, r0, int(p0[2] * 100), 2, 0.35, (1.6, 0.22, 1.1)), "musgo", TRONCO, 0.15)
    # el ALERO del hombro derecho: dos tablas de corteza en pico, como el alero de un tejado
    for j, (dx, rz) in enumerate(((-0.04, 34), (-0.15, 2))):
        pieza(CR(m, (-0.30 + dx, 0.0, 1.70 - j * 0.05), (0.22, 0.40, 0.045), giro(0, rz, 0), redondez=0.35, cortes=1),
              "corteza_clara", lambda co: {"clavicula.R": 0.5, "brazo.R": 0.5}, 0.35)
    pieza(CR(m, (0.31, 0.0, 1.66), (0.22, 0.30, 0.10), giro(0, -20, 0), redondez=0.6, cortes=2), "corteza_clara",
          lambda co: {"clavicula.L": 0.5, "brazo.L": 0.5}, 0.35)
    # cuello y cabeza: tocón con la máscara OVAL de corcho delante; ramas cortadas encima (sin ramas móviles)
    pieza(CR(m, (0, 0.0, 1.70), (0.20, 0.20, 0.12), redondez=0.6, cortes=1), "corteza", "cuello", 0.3)
    pieza(CR(m, (0, 0.02, 1.84), (0.27, 0.26, 0.30), redondez=0.6, cortes=2, ruido_amp=0.01, semilla=19), "corteza",
          por_z([(1.72, "cuello"), (1.80, "cabeza")]), 0.35)
    pieza(E.roca(m, (0, -0.115, 1.84), 0.13, 21, 2, 0.04, (0.95, 0.35, 1.25)), "corcho", "cabeza", 0.25)
    for l in (1, -1):
        pieza(m.esfera((0.045 * l, -0.155, 1.87), (0.028, 0.012, 0.036), (8, 6)), "nudo", "cabeza", 0.2)
        brillo(m.esfera((0.045 * l, -0.165, 1.87), (0.012, 0.005, 0.016), (6, 4)), "cabeza")
    pieza(m.tubo([(0, -0.16, 1.785), (0.0, -0.165, 1.79)], [(0.04, 0.008), (0.04, 0.008)], 6), "nudo", "cabeza", 0.2)
    for l, h in ((1, 0.12), (-1, 0.08)):
        pieza(m.tubo([(0.06 * l, 0.02, 1.97), (0.10 * l, 0.04, 1.97 + h)], [0.03, 0.022], 6), "corteza_clara", "cabeza", 0.3)

    # el escudo de anillos: la rodaja de un tronco, fijo por fuera del antebrazo izquierdo (deforma con arma.L)
    EN = Vector((1, 0, 0))                                 # la cara del escudo mira hacia fuera (+X) en reposo
    disco = m.tubo([ESCUDO_C - EN * 0.03, ESCUDO_C + EN * 0.05], [(0.30, 0.30), (0.29, 0.29)], 16, ref=Vector((0, 0, 1)))
    cara = [v for v in disco if (v.co - ESCUDO_C).dot(EN) > 0.04]
    E.plano_uv(m, A, disco, "anillos", ESCUDO_C - Vector((0, 0.30, 0.30)), Vector((0, 1, 0)), Vector((0, 0, 1)), 0.60, 0.60,
               "arma.L")
    pieza(m.tubo([ESCUDO_C + EN * 0.0, ESCUDO_C + EN * 0.06], [(0.31, 0.31), (0.31, 0.31)], 16, tapas=(False, False),
                 ref=Vector((0, 0, 1))), "corteza", "arma.L", 0.3)
    pieza(E.roca(m, ESCUDO_C + EN * 0.06 + Vector((0, -0.12, 0.14)), 0.05, 31, 1, 0.3, (0.5, 1.0, 1.0)), "musgo", "arma.L", 0.2)

    # la maza de poda: mango de madera, cabeza de raíz nudosa y la hoja curva de la podadera en el canto
    mango0 = PUNO_R - DIR_MAZA * 0.12
    mango1 = PUNO_R + DIR_MAZA * 0.52
    E.plano_uv(m, A, m.tubo([mango0, mango1], [0.026, 0.024], 6), "madera", mango0, Vector((1, 0, 0)), DIR_MAZA, 0.1, 0.6,
               "arma.R")
    cab = PUNO_R + DIR_MAZA * 0.66
    pieza(E.roca(m, cab, 0.14, 41, 2, 0.18, (1.0, 1.0, 1.35), Vector((0, 0, 1)).rotation_difference(DIR_MAZA).to_euler()),
          "nudo", "arma.R", 0.3)
    lado = DIR_MAZA.cross(Vector((1, 0, 0))).normalized()
    hoja = [cab + lado * 0.10 + DIR_MAZA * (-0.10 + 0.22 * t) + lado * 0.10 * math.sin(math.pi * t) for t in (0, 0.33, 0.66, 1)]
    pieza(m.tubo(hoja, [(0.05, 0.008), (0.06, 0.007), (0.05, 0.006), (0.01, 0.004)], 4, ref=Vector((1, 0, 0))), "hierro",
          "arma.R", 0.2, liso=False)

print("vértices sin pesos rellenados:", B.rellenar_pesos(m))
ob = m.objeto(NOMBRE, col)
E.materiales(ob, [NOMBRE + "_atlas", NOMBRE + "_brillo"])
C.enlazar(ob, arm)
TRIS = C.triangulos(ob)
E.oclusion(ob, rayos=24, dist=0.45, minimo=0.45)
print("triángulos:", TRIS)

if SOLO_MALLA:
    A.guardar(os.path.join(LAMINAS, NOMBRE + "_atlas.png"), [(os.path.join(SALIDA, NOMBRE + ".webp"), 1024)])
    img = bpy.data.images.load(os.path.join(SALIDA, NOMBRE + ".webp"))
    E.material_vista(bpy.data.materials[NOMBRE + "_atlas"], img)
    E.material_vista(bpy.data.materials[NOMBRE + "_brillo"], None, emision=(*BRILLO, 2.0))
    B.lamina(esc, arm, ob, RAIZ, os.path.join(LAMINAS, NOMBRE + "_malla.png"), "Velador de Corteza (e02) — malla",
             clip="", sep=1.5, orto=7.2, alto_cam=1.05)
    print("hecho (solo malla)")
    raise SystemExit

# ================================================================== poses y clips
# 20 clips: los 18 del documento con los nombres del juego (equivalencia en el JSON; el propio, guard_loop →
# «guardia_espera») y, del ATB, «carga» y «carga_espera» (el aviso de la Raíz de umbral es un turno de preparación).
rig = E.Rig(arm, polo_codo={".L": Vector((0.7, 0.6, -0.3)), ".R": Vector((-0.7, 0.6, -0.3))})
TOB = {s: tuple(rig.tobillo[s]) for s in (".L", ".R")}
TOBP = {s: (TOB[s][0], TOB[s][1] / FP, TOB[s][2] / FP) for s in (".L", ".R")}


def a_v2(pose):
    """Una pose escrita para la v1, llevada a las piernas cortas de la v2 (raíz y pies)."""
    if not V2:
        return pose
    out = dict(pose)
    for k_, v in pose.items():
        if k_ == "raiz@loc" or (k_.startswith("pie.") and k_.endswith("@ik")):
            out[k_] = (v[0], v[1] * FP, v[2] * FP)
    return out
CLIPS = {}
L, R, sim = E.L, E.R, E.sim


def P(*ds):
    out = {}
    for d in ds:
        out.update(d)
    return out


def M(base, **cambios):
    out = dict(base)
    for k_, v in cambios.items():
        out[k_.replace("__", ".").replace("_AT_", "@")] = v
    return out


def luz(v):
    return {"luz@esc": (v, v, v)}


def clip(nombre, claves, bucle=False, proc=None, eventos=None):
    claves = [(c[0], a_v2(c[1])) + tuple(c[2:]) for c in claves]
    act, dur = rig.clip(nombre, claves, bucle, proc=proc)
    CLIPS[nombre] = {"duracion": round(dur, 4), "bucle": bucle, "eventos": eventos or {}}


# en pie y pesado: el escudo a medio alzar delante del costado, la maza colgando delante
REPOSO = P({"raiz@loc": (0, 0.0, -0.03), "pecho": (4, 0, 0), "columna_02": (2, 0, 0), "cabeza": (-4, 0, 0),
            "pie.L@ik": (TOB[".L"][0] + 0.02, -0.05, TOBP[".L"][2]), "pie.R@ik": (TOB[".R"][0] - 0.02, 0.06, TOBP[".R"][2])},
           L(brazo=(-26, 8, 0), antebrazo=(-58, 0, 30), mano=(0, 0, 0)),
           R(brazo=(-14, 6, 0), antebrazo=(-24, 0, 0), mano=(-10, 0, 0)), luz(1.0))
# guardia: el escudo de anillos delante del pecho, agachado tras él, la maza atrás
GUARDIA = P(M(REPOSO, raiz_AT_loc=(0, 0.03, -0.09), pecho=(10, 0, -8), columna_02=(4, 0, -4), cabeza=(-10, 0, 6)),
            L(brazo=(-62, 34, 0), antebrazo=(-84, 0, 62), mano=(0, 0, 0)),
            R(brazo=(-6, 14, 0), antebrazo=(-40, 0, 0)), luz(1.4))

clip("reposo", [(0, REPOSO), (0.6, M(REPOSO, pecho=(6, 0, 2), raiz_AT_loc=(0, 0, -0.045))),
                (1.2, M(REPOSO, cabeza=(-4, 0, 8))), (1.6, M(REPOSO, pecho=(5, 0, -2), raiz_AT_loc=(0, 0, -0.04))),
                (2.0, REPOSO)], bucle=True)
clip("guardia_espera", [(0, GUARDIA), (0.6, P(M(GUARDIA, raiz_AT_loc=(0, 0.03, -0.11), pecho=(12, 0, -8)), luz(1.7))),
                        (1.2, GUARDIA)], bucle=True)
ALERTA = P(M(REPOSO, cabeza=(-14, 0, 0), pecho=(-2, 0, 0), raiz_AT_loc=(0, 0, 0.0)), L(brazo=(-50, 26, 0)), luz(1.8))
clip("alerta", [(0, REPOSO), (0.15, M(REPOSO, raiz_AT_loc=(0, 0.02, -0.08), pecho=(12, 0, 0)), "fren"),
                (0.3, ALERTA, "fren"), (0.6, REPOSO)], eventos={"alerta": 0.15})
TOCON = P({"raiz@loc": (0, 0.05, -0.55), "columna_01": (20, 0, 0), "columna_02": (18, 0, 0), "pecho": (24, 0, 0),
           "cabeza": (20, 0, 0)}, L(brazo=(-10, 10, 0), antebrazo=(-20, 0, 30)), R(brazo=(-10, -10, 0), antebrazo=(-10, 0, 0)),
          luz(0.0))
clip("entrada", [(0, TOCON), (0.3, P(TOCON, luz(0.5))), (0.7, M(REPOSO, raiz_AT_loc=(0, 0.0, -0.10)), "acel"),
                 (1.0, REPOSO)], eventos={"despierta": 0.3, "golpe_suelo": 0.7})
clip("caminar", [(0, REPOSO), (1.0, REPOSO)], bucle=True,
     proc=B.pasos(rig, 1.0, 0.36 * FP, 0.08 * FP, 0.035, TOB[".L"], base=REPOSO, brazos=6, inclina=4))
clip("correr", [(0, REPOSO), (0.7, REPOSO)], bucle=True,
     proc=B.pasos(rig, 0.7, 0.54 * FP, 0.13 * FP, 0.06, TOB[".L"], base=REPOSO, brazos=14, inclina=12))
clip("lateral_izq", [(0, GUARDIA), (1.0, GUARDIA)], bucle=True,
     proc=B.pasos(rig, 1.0, 0.26 * FP, 0.07 * FP, 0.025, TOB[".L"], base=GUARDIA, brazos=2, lateral=1))
clip("lateral_der", [(0, GUARDIA), (1.0, GUARDIA)], bucle=True,
     proc=B.pasos(rig, 1.0, 0.26 * FP, 0.07 * FP, 0.025, TOB[".L"], base=GUARDIA, brazos=2, lateral=-1))
clip("girar_izq", [(0, REPOSO), (0.5, REPOSO)], proc=B.girar(rig, "izq", TOB[".L"], REPOSO))
clip("girar_der", [(0, REPOSO), (0.5, REPOSO)], proc=B.girar(rig, "der", TOB[".L"], REPOSO))
SACUDIDA = P(M(REPOSO, pecho=(-12, 0, 8), cabeza=(-16, 0, 6), raiz_AT_loc=(0, 0.06, -0.03)),
             L(brazo=(-14, 20, 0)), R(brazo=(-4, 20, 0)), luz(0.4))
clip("recibir_golpe", [(0, REPOSO), (0.08, SACUDIDA, "fren"), (0.35, REPOSO)], eventos={"golpe": 0.0})
SACUDIDA_E = P(M(REPOSO, pecho=(18, 0, -4), cabeza=(14, 0, 0), raiz_AT_loc=(0, -0.06, -0.03)), luz(0.4))
clip("recibir_golpe_espalda", [(0, REPOSO), (0.08, SACUDIDA_E, "fren"), (0.35, REPOSO)], eventos={"golpe": 0.0})
FLOJO = P(M(REPOSO, raiz_AT_loc=(0, 0.02, -0.08), pecho=(16, 0, 0)), L(brazo=(0, 10, 0), antebrazo=(-20, 0, 20)),
          R(brazo=(0, 10, 0), antebrazo=(-10, 0, 0)))
clip("aturdido", [(0, FLOJO), (0.8, FLOJO)], bucle=True, proc=B.aturdido_proc(FLOJO, 0.8, 0.8))
# derrota (1,4 s): cruje, se tambalea y cae de espaldas como un árbol talado (suelo 1,05)
TALADO = P(M(REPOSO, raiz=(-80, 0, 0), raiz_AT_loc=(0, 0.25, -0.05), pecho=(-6, 0, 0), cabeza=(-10, 0, 10)),
           {"pie.L@ik": (TOB[".L"][0], -0.30, 0.25), "pie.R@ik": (TOB[".R"][0], -0.25, 0.30)},
           L(brazo=(-150, 30, 0), antebrazo=(-10, 0, 30)), R(brazo=(-140, -40, 0), antebrazo=(-10, 0, 0)), luz(0.0))
clip("derrota", [(0, REPOSO), (0.12, SACUDIDA, "fren"),
                 (0.4, P(M(REPOSO, pecho=(-14, 0, 0), raiz_AT_loc=(0, 0.08, -0.06)), luz(0.5))),
                 (1.05, TALADO, "acel"), (1.2, M(TALADO, raiz_AT_loc=(0, 0.25, -0.02))), (1.4, TALADO)],
     eventos={"cruje": 0.4, "suelo": 1.05})
clip("desaparecer", [(0, TALADO), (0.6, P(M(TALADO, raiz_AT_loc=(0, 0.25, -0.70)),
                                          {"pie.L@ik": (TOB[".L"][0], -0.30, -0.45),
                                           "pie.R@ik": (TOB[".R"][0], -0.25, -0.4)}), "acel")],
     eventos={"hundido": 0.6})

# A1 · Mazazo de poda (ataque, 1,80 s): alza la maza sobre el hombro (aviso 0-0,90) y la deja caer en diagonal
# (IMPACTO 0,95; activo 0,90-1,08)
ALZA = P(M(REPOSO, pecho=(-10, 0, -18), columna_02=(-4, 0, -8), cabeza=(-6, 0, 10), raiz_AT_loc=(0, 0.06, -0.02)),
         R(brazo=(-168, 22, 0), antebrazo=(-58, 0, 0), mano=(-10, 0, 0)), L(brazo=(-50, 26, 0), antebrazo=(-70, 0, 40)),
         luz(1.6))
CAE = P(M(REPOSO, pecho=(26, 0, 14), columna_02=(8, 0, 6), cabeza=(-18, 0, -6), raiz_AT_loc=(0, -0.20, -0.12)),
        {"pie.R@ik": (TOB[".R"][0], -0.30, TOBP[".R"][2])},
        R(brazo=(-56, -12, 0), antebrazo=(-8, 0, 0), mano=(-20, 0, 0)), L(brazo=(-10, 20, 0), antebrazo=(-40, 0, 20)),
        luz(2.2))
T_MAZAZO = 0.95
clip("ataque", [(0, REPOSO), (0.6, ALZA, "fren"), (0.9, M(ALZA, pecho=(-14, 0, -20))), (T_MAZAZO, CAE, "acel"),
                (1.1, M(CAE, pecho=(28, 0, 14)), "fren"), (1.4, M(CAE, pecho=(14, 0, 6), raiz_AT_loc=(0, -0.12, -0.08))),
                (1.8, REPOSO)], eventos={"aviso": 0.0, "impacto": T_MAZAZO})

# A2 · Empuje de anillos (empuje, 1,50 s): recoge el escudo al pecho (aviso 0-0,65) y da un paso firme empujando
# con él (IMPACTO 0,70; activo 0,65-0,83)
RECOGE = P(M(GUARDIA, raiz_AT_loc=(0, 0.08, -0.10), pecho=(4, 0, -12)), L(brazo=(-50, 40, 0), antebrazo=(-110, 0, 62)),
           luz(1.6))
EMPUJA = P(M(GUARDIA, raiz_AT_loc=(0, -0.28, -0.08), pecho=(14, 0, 4), cabeza=(-14, 0, 0)),
           {"pie.L@ik": (TOB[".L"][0], -0.40, TOBP[".L"][2])},
           L(brazo=(-80, 28, 0), antebrazo=(-30, 0, 62)), luz(2.0))
T_EMPUJE = 0.70
clip("empuje", [(0, REPOSO), (0.45, RECOGE, "fren"), (0.62, M(RECOGE, raiz_AT_loc=(0, 0.10, -0.11))),
                (T_EMPUJE, EMPUJA, "acel"), (0.85, M(EMPUJA, pecho=(16, 0, 4)), "fren"),
                (1.2, P(M(REPOSO, raiz_AT_loc=(0, -0.12, -0.05)), {"pie.L@ik": (TOB[".L"][0], -0.20, 0.14)})),
                (1.5, REPOSO)], eventos={"aviso": 0.0, "impacto": T_EMPUJE, "pisada": T_EMPUJE})

# A3 · Raíz de umbral (raiz, 2,20 s): clava la maza en tierra y extiende el brazo libre (aviso 0-1,10; en el combate,
# un TURNO: «carga» y «carga_espera»); tres raíces brotan bajo el héroe (IMPACTO 1,15; activo 1,10-1,30)
CLAVA = P(M(REPOSO, raiz_AT_loc=(0, -0.05, -0.20), pecho=(22, 0, 0), columna_02=(8, 0, 0), cabeza=(-14, 0, 0)),
          {"pie.R@ik": (TOB[".R"][0], -0.22, TOBP[".R"][2])},
          R(brazo=(-40, 10, 0), antebrazo=(-6, 0, 0), mano=(30, 0, 0)), L(brazo=(-20, 30, 0), antebrazo=(-60, 0, 30)),
          luz(1.6))
EXTIENDE = P(M(CLAVA, pecho=(14, 0, -10), cabeza=(-18, 0, -8)),
             L(brazo=(-92, -10, 0), antebrazo=(-6, 0, 30), mano=(-20, 0, 0)), luz(2.2))
SUELTA = P(M(EXTIENDE, pecho=(18, 0, -12), raiz_AT_loc=(0, -0.07, -0.22)), L(brazo=(-98, -18, 0)), luz(3.0))
T_CARGA, T_RAIZ = 1.10, 1.15
EXT2 = M(EXTIENDE, pecho=(16, 0, -10))
clip("raiz", [(0, REPOSO), (0.5, CLAVA, "acel"), (0.8, EXTIENDE, "fren"), (T_CARGA, EXT2),
              (T_RAIZ, SUELTA, "acel"), (1.3, SUELTA), (1.8, M(CLAVA, pecho=(12, 0, 0))), (2.2, REPOSO)],
     eventos={"aviso": 0.0, "clava": 0.5, "carga": T_CARGA, "impacto": T_RAIZ})
clip("carga", [(0, REPOSO), (0.5, CLAVA, "acel"), (0.8, EXTIENDE, "fren"), (T_CARGA, EXT2)],
     eventos={"clava": 0.5, "arriba": T_CARGA})
clip("carga_espera", [(0, EXT2), (0.6, P(M(EXTIENDE, pecho=(18, 0, -12), raiz_AT_loc=(0, -0.05, -0.215)), luz(2.8))),
                      (1.2, EXT2)], bucle=True)


def medir():
    datos = {}
    for c_, t, h, local in (("ataque", T_MAZAZO, "arma.R", (0, 0.66, 0)), ("empuje", T_EMPUJE, "arma.L", (0, 0, 0)),
                            ("raiz", T_RAIZ, "mano.L", (0, 0.1, 0))):
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

if SOLO_LAMINA:
    A.guardar(os.path.join(LAMINAS, NOMBRE + SUFIJO + "_atlas.png"), [])
    img = bpy.data.images.load(os.path.join(LAMINAS, NOMBRE + SUFIJO + "_atlas.png"))
    E.material_vista(bpy.data.materials[NOMBRE + "_atlas"], img)
    E.material_vista(bpy.data.materials[NOMBRE + "_brillo"], None, emision=(*BRILLO, 2.0))
    B.lamina_heroes(esc, arm, ob, RAIZ, os.path.join(LAMINAS, NOMBRE + (SUFIJO or "_v1") + "_heroes.png"),
                    "Velador de Corteza (e02) %s — junto a Kael, Lya y Garon" % ("v2" if V2 else "v1"), sep=1.25)
    print("hecho (solo lámina)")
    raise SystemExit
A.guardar(os.path.join(LAMINAS, NOMBRE + SUFIJO + "_atlas.png"),
          [(os.path.join(SALIDA, NOMBRE + SUFIJO + ".webp"), 1024), (os.path.join(SALIDA, NOMBRE + SUFIJO + "_bajo.webp"), 512)])
if V2:
    B.guardar_imagen(B.normal_desde_alturas(A.img, 2.2, A.c), os.path.join(SALIDA, NOMBRE + SUFIJO + "_normal.webp"))
E.exportar(os.path.join(SALIDA, NOMBRE + SUFIJO + ".glb"))
MAPA = dict(B.MAPA_CLIPS_BASE)
MAPA.update({"attack_01": "ataque", "attack_02": "empuje", "attack_03": "raiz", "guard_loop": "guardia_espera"})
ALTO_REAL = round(max(v.co.z for v in ob.data.vertices), 3)
E.guardar_json(os.path.join(SALIDA, NOMBRE + SUFIJO + "_clips.json"), {
    "id": ID, "modelo": NOMBRE + SUFIJO, "alto_m": ALTO_REAL, "triangulos": TRIS, "huesos": len(HUESOS),
    "deformantes": B.contar_deformantes(arm), "fps": E.FPS,
    "texturas": {"alto": NOMBRE + SUFIJO + ".webp (1024)", "bajo": NOMBRE + SUFIJO + "_bajo.webp (512)",
                 "normales": (NOMBRE + SUFIJO + "_normal.webp (1024)") if V2 else ""}, "proporciones": PROP,
    "color_brillo": BRILLO, "clips": CLIPS, "mapa_pdf": MAPA, "solo_atb": ["carga", "carga_espera"], "medidas": medidas,
    "generador": "enemigos/velador_corteza/fuente/crear_velador_corteza.py%s (Blender 5.2.3)" % (" -- ... v2" if V2 else "")})
print("clips (%d):" % len(CLIPS), {k_: v["duracion"] for k_, v in CLIPS.items()})
print("medidas:", medidas)

if CON_LAMINAS:
    img = bpy.data.images.load(os.path.join(SALIDA, NOMBRE + SUFIJO + ".webp"))
    E.material_vista(bpy.data.materials[NOMBRE + "_atlas"], img)
    E.material_vista(bpy.data.materials[NOMBRE + "_brillo"], None, emision=(*BRILLO, 2.0))
    B.lamina(esc, arm, ob, RAIZ, os.path.join(LAMINAS, NOMBRE + SUFIJO + "_lamina.png"),
             "Velador de Corteza (e02) — defensor del Gran Bosque Verde", clip="reposo", sep=1.5, orto=7.2, alto_cam=1.05)
    for o in list(esc.objects):
        if o.type == 'CAMERA':
            bpy.data.objects.remove(o)
    for o in esc.objects:
        if o.name.startswith("kael") or (o.parent and o.parent.name.startswith("kael")):
            o.hide_render = True
    arm.location = (0, 0, 0)
    arm.rotation_euler = (0, 0, 0)
    esc.render.resolution_x, esc.render.resolution_y = 700, 800
    inst = [("reposo", 0.0), ("guardia_espera", 0.0), ("alerta", 0.3), ("entrada", 0.0), ("caminar", 0.25),
            ("correr", 0.2), ("lateral_izq", 0.25),
            ("ataque", 0.6), ("ataque", T_MAZAZO), ("ataque", 1.1), ("empuje", 0.45), ("empuje", T_EMPUJE),
            ("raiz", 0.5), ("carga_espera", 0.0),
            ("raiz", T_RAIZ), ("recibir_golpe", 0.08), ("recibir_golpe_espalda", 0.08), ("aturdido", 0.2),
            ("derrota", 0.4), ("derrota", 1.4), ("girar_der", 0.25)]
    carpeta = os.path.join(LAMINAS, "poses")
    os.makedirs(carpeta, exist_ok=True)
    rutas = E.poses_render(esc, arm, inst, carpeta, NOMBRE + SUFIJO, objetivo=(0, -0.3, 1.0 * (0.88 if V2 else 1.0)),
                           azimut=-40, elev=10, orto=3.4 * (0.9 if V2 else 1.0))
    E.componer(rutas, os.path.join(LAMINAS, NOMBRE + SUFIJO + "_poses.png"), 7)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(LAMINAS, NOMBRE + SUFIJO + ".blend"))
print("hecho")
