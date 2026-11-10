# Claro del Guardián (V9, hitos 6 y 10: «sector 3D ampliado» y «arena de jefe»): el kit de piezas del claro del noreste
# de Pastos Verdes 3D, hecho desde cero con este guion (geometría procedural propia: ningún recurso descargado; obra
# propia del proyecto).
#
#   blender -b --factory-startup -P crear_claro.py -- <carpeta de salida>
#
# Escribe <carpeta>/claro_guardian.glb (perfil alto) y <carpeta>/claro_guardian_ligero.glb (medio y bajo: las mismas
# piezas con menos lados, anillos y hojas). Misma semilla, mismo resultado.
#
# El GLB es un KIT, no el claro montado: cada pieza es un objeto en el origen, con el suelo en z = 0 y la base hundida
# unos 0,4 m (el terreno de la región no es llano). zonas3d/bosque/claro_guardian.gd las coloca en el terreno, las junta
# en pocas mallas (una llamada de dibujo por material) y les pone las colisiones.
#
# Ejes (Blender): Z arriba; el FRENTE de cada pieza mira a -Y, hacia el centro del claro (en Godot, +Z local). Las piezas
# del anillo (menhires y arcos de raíz) se curvan con el anillo de radio R_ANILLO.
#
# Materiales (los sustituye claro_guardian.gd; aquí solo separan las superficies):
#   base   colores de vértice (piedra, corteza, musgo, setas, flores, cintas). Se guardan en sRGB, como el Guardián
#          (crear_guardian.py): el renderizador Compatibility usa los colores de vértice tal cual.
#   runa   las runas pálidas, el ojo tallado y la yema del brote (en Godot: sin sombreado, color según el estado).
#   agua   el agua del manantial (solo la pieza «manantial»).
#
# Colisiones: objetos vacíos hijos de cada pieza, llamados «choque_<radio cm>_<alto cm>»: un cilindro vertical en esa
# posición (su base en el suelo). claro_guardian.gd los lee del GLB.
import bpy, bmesh, sys, os, math, random
from mathutils import Vector, noise
from mathutils.bvhtree import BVHTree

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
CARPETA = argv[0] if argv else ""

R_ANILLO = 5.0          # radio nominal del anillo (los arcos se curvan con él)
HUNDIDO = 0.4           # lo que se hunde cada base bajo z = 0

# ---------------------------------------------------------------- colores (sRGB)

PIEDRA = ((0.30, 0.32, 0.35), (0.48, 0.50, 0.52), (0.66, 0.67, 0.66))   # gris frío: contrasta con hierba y corteza
LIQUEN = (0.78, 0.80, 0.60)
TIERRA = (0.24, 0.20, 0.15)
# Raíces viejas: más oscuras y frías que la corteza del Guardián (crear_guardian.py), para que él destaque sobre ellas
CORTEZA = ((0.10, 0.08, 0.06), (0.24, 0.19, 0.14), (0.42, 0.36, 0.27))
SECA = ((0.30, 0.28, 0.26), (0.52, 0.50, 0.47), (0.70, 0.68, 0.64))
MADERA = ((0.55, 0.40, 0.25), (0.72, 0.56, 0.36))                         # anillos del corte del tocón
MUSGO = (0.33, 0.50, 0.14)
MUSGO_CLARO = (0.56, 0.70, 0.22)
MUSGO_OSCURO = (0.20, 0.34, 0.11)
SETA = ((0.86, 0.80, 0.64), (0.70, 0.52, 0.32))
CINTAS = [(0.80, 0.28, 0.22), (0.36, 0.54, 0.82), (0.94, 0.88, 0.62), (0.64, 0.46, 0.78)]
HOJAS = [(0.36, 0.64, 0.20), (0.48, 0.72, 0.24), (0.58, 0.78, 0.30)]
FLORES = [(0.97, 0.95, 0.86), (0.99, 0.86, 0.40), (0.95, 0.68, 0.76), (0.66, 0.70, 0.98)]
BLANCO = (1.0, 1.0, 1.0)

BASE, RUNA, AGUA = 0, 1, 2


def mezcla(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(a[i] * (1 - t) + b[i] * t for i in range(3))


def suave(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def ruido(p, f=1.0, s=0.0):
    return noise.noise(Vector(p) * f + Vector((s, s * 0.61, s * 0.37)))


def color_musgo(p, n=None):
    mm = ruido(p, 6.0, 3.3) * 0.5 + 0.5
    return mezcla(MUSGO_OSCURO, MUSGO_CLARO, mm * 1.2 + (n.z * 0.25 if n is not None else 0.0))


# ---------------------------------------------------------------- constructor de mallas

class Malla:
    def __init__(self):
        self.v, self.col, self.caras, self.mats = [], [], [], []
        self.choques = []          # (x, y, radio, alto)

    def vert(self, p, c):
        self.v.append(Vector(p))
        self.col.append(c)
        return len(self.v) - 1

    def cara(self, idx, mat=BASE):
        self.caras.append(tuple(idx))
        self.mats.append(mat)

    def choque(self, x, y, radio, alto):
        self.choques.append((x, y, radio, alto))

    def triangulos(self):
        return sum(len(f) - 2 for f in self.caras)


Q = 1.0                         # calidad: 1 en el GLB alto, menos en el ligero


def nq(n, minimo=3):
    return max(minimo, int(round(n * Q)))


def nq3(n):
    """Lados de un tubo con costillas de corteza: múltiplo de 3 (una costilla cada tres vértices), 6 como poco."""
    return max(6, int(round(n * Q / 3.0)) * 3)


def marcos(pts):
    """Tangentes y normales por transporte paralelo (sin torsión a lo largo del tubo)."""
    n = len(pts)
    T = [(pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized() for i in range(n)]
    r0 = Vector((0, 0, 1))
    N = r0 - T[0] * r0.dot(T[0])
    if N.length < 1e-3:
        N = Vector((1, 0, 0)) - T[0] * T[0].x
    N.normalize()
    Ns = [N]
    for i in range(1, n):
        N = Ns[-1] - T[i] * Ns[-1].dot(T[i])
        N.normalize()
        Ns.append(N)
    return T, Ns, [T[i].cross(Ns[i]) for i in range(n)]


def color_corteza(pal, surco, ru, normal, musgo, pos):
    oscuro, medio, claro = pal
    c = mezcla(oscuro, medio, surco * 1.4)
    if surco > 0.72:
        c = mezcla(c, claro, (surco - 0.72) * 2.2)
    c = mezcla(c, oscuro, max(0.0, -ru) * 0.3)
    if pos.z < 0.35:                                   # tierra y sombra donde sale del suelo
        c = mezcla(c, TIERRA, 0.85 * suave(0.35, -0.12, pos.z))
    if musgo > 0:
        mm = ruido(pos, 4.0, 5.1) * 0.5 + 0.5
        f = suave(0.25, 0.7, normal.z + (mm - 0.5) * 0.6) * musgo
        if f > 0:
            c = mezcla(c, mezcla(MUSGO_OSCURO, MUSGO_CLARO, mm * 1.3), f)
    return c


def tubo(M, pts, radios, lados=8, amp=0.08, surcos=6, pal=CORTEZA, musgo=0.5, semilla=0.0, giro=0.5,
         tapa0=True, punta=True):
    """Tubo de corteza por una polilínea; devuelve los anillos (para colgar cosas de él)."""
    pts = [Vector(p) for p in pts]
    T, N, B = marcos(pts)
    anillos = []
    for i, p in enumerate(pts):
        anillo = []
        for k in range(lados):
            a = 2 * math.pi * k / lados
            radial = N[i] * math.cos(a) + B[i] * math.sin(a)
            q = p + radial * radios[i]
            surco = (0.05, 0.75, 0.95)[(k + i // 2) % 3] if lados % 3 == 0 else abs(math.sin(a * surcos * 0.5 + i * giro + semilla))
            ru = noise.noise(q * 3.0 + Vector((semilla, 0.0, 0.0)))
            d = amp * (0.6 * (surco * 2 - 1) + 0.4 * ru)
            pos = p + radial * radios[i] * (1 + d)
            anillo.append(M.vert(pos, color_corteza(pal, surco, ru, radial, musgo, pos)))
        anillos.append(anillo)
    for i in range(len(anillos) - 1):
        a0, a1 = anillos[i], anillos[i + 1]
        for k in range(lados):
            k2 = (k + 1) % lados
            M.cara([a0[k], a0[k2], a1[k2], a1[k]])
    if tapa0:
        c = M.vert(pts[0] - T[0] * radios[0] * 0.35, M.col[anillos[0][0]])
        for k in range(lados):
            M.cara([c, anillos[0][(k + 1) % lados], anillos[0][k]])
    fin = pts[-1] + T[-1] * radios[-1] * (2.0 if punta else 0.35)
    c = M.vert(fin, M.col[anillos[-1][0]])
    for k in range(lados):
        M.cara([anillos[-1][k], anillos[-1][(k + 1) % lados], c])
    return pts, anillos


def bulto(M, centro, radio, escala=(1, 1, 1), subdiv=1, amp=0.2, color=None, semilla=0.0, z_min=None, mat=BASE):
    """Icosfera deformada (musgo, piedras sueltas, sombreros)."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=1.0)
    idx = {}
    for v in bm.verts:
        d = v.co.normalized()
        r = radio * (1 + amp * noise.noise(d * 2.2 + Vector((semilla, semilla * 0.37, 1.3))))
        p = Vector(centro) + Vector((d.x * escala[0], d.y * escala[1], d.z * escala[2])) * r
        if z_min is not None:
            p.z = max(p.z, z_min)
        idx[v.index] = M.vert(p, color(d, p) if color else PIEDRA[1])
    for f in bm.faces:
        M.cara([idx[v.index] for v in f.verts], mat)
    bm.free()


def hoja(M, base, direccion, normal, largo, ancho, color):
    """Hoja de dos caras (rombo)."""
    d = Vector(direccion).normalized()
    n = Vector(normal).normalized()
    lado = d.cross(n).normalized()
    b = Vector(base)
    ps = [b, b + d * largo * 0.45 + lado * ancho * 0.5, b + d * largo, b + d * largo * 0.45 - lado * ancho * 0.5]
    i = [M.vert(p, mezcla(color, (0.15, 0.25, 0.08), 0.35) if k == 0 else color) for k, p in enumerate(ps)]
    M.cara([i[0], i[1], i[2], i[3]])
    M.cara([i[3], i[2], i[1], i[0]])


def tira(M, pts, ancho, color, normal=(0, -1, 0)):
    """Cinta de dos caras por una polilínea (cintas de ofrenda, tallos)."""
    n = Vector(normal)
    izq, der = [], []
    for i, p in enumerate(pts):
        t = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        lado = t.cross(n).normalized() * ancho * 0.5
        c = mezcla(color, (0.0, 0.0, 0.0), 0.15 * i / max(1, len(pts) - 1))
        izq.append(M.vert(p - lado, c))
        der.append(M.vert(p + lado, c))
    for i in range(len(pts) - 1):
        M.cara([izq[i], der[i], der[i + 1], izq[i + 1]])
        M.cara([izq[i + 1], der[i + 1], der[i], izq[i]])


# Runas: trazos finos pegados a la superficie (se buscan con un rayo desde el frente, -Y).
GLIFOS = [
    [((0, -1), (0, 1)), ((0, 0.4), (0.6, 1)), ((0, -0.2), (0.6, 0.4))],          # dos ramas
    [((0, -1), (0, 1)), ((-0.6, 0.6), (0.6, -0.2))],                                # vara cruzada
    [((-0.5, -1), (-0.5, 1)), ((0.5, -1), (0.5, 1)), ((-0.5, 0.6), (0.5, 0.0))],   # puerta
    [((0, -1), (0, 1)), ((0, 1), (0.6, 0.4)), ((0, 1), (-0.6, 0.4))],             # flecha (árbol)
    [((-0.6, -1), (0.6, 1)), ((0.6, -1), (-0.6, 1)), ((-0.6, 0), (0.6, 0))],      # estrella
    [((0, -1), (0, 0.4)), ((0, 0.4), (0.6, 1)), ((0, 0.4), (-0.6, 1)), ((-0.4, -0.4), (0.4, -0.4))],
]


def superficie(bvh, x, z, desde=-6.0):
    hit = bvh.ray_cast(Vector((x, desde, z)), Vector((0, 1, 0)), 12.0)
    if hit[0] is None:
        return None
    return hit[0], hit[1]


def trazo(M, bvh, a, b, grosor=0.035, mat=RUNA):
    """Un trazo de runa de a a b (coordenadas x, z del frente), pegado a la superficie."""
    pa, pb = superficie(bvh, *a), superficie(bvh, *b)
    if pa is None or pb is None:
        return
    d = (pb[0] - pa[0])
    if d.length < 1e-4:
        return
    nrm = (pa[1] + pb[1]).normalized()
    lado = d.normalized().cross(nrm).normalized() * grosor * 0.5
    sale = nrm * 0.014
    q = [pa[0] - lado + sale, pa[0] + lado + sale, pb[0] + lado + sale, pb[0] - lado + sale]
    i = [M.vert(p, BLANCO) for p in q]
    if (q[1] - q[0]).cross(q[2] - q[0]).dot(nrm) < 0:
        i.reverse()
    M.cara(i, mat)


def glifo(M, bvh, cx, cz, tam, k):
    for (a, b) in GLIFOS[k % len(GLIFOS)]:
        trazo(M, bvh, (cx + a[0] * tam * 0.5, cz + a[1] * tam * 0.5), (cx + b[0] * tam * 0.5, cz + b[1] * tam * 0.5))


def bvh_de(M, desde=0):
    caras = [f for f in M.caras[desde:]]
    return BVHTree.FromPolygons([tuple(v) for v in M.v], caras, all_triangles=False)


# ---------------------------------------------------------------- piezas

def piedra(M, alto, ancho, fondo, semilla, inclina=0.08, runas=3, liquen=0.5, curva=0.0):
    """Menhir: sección de rectángulo redondeado que se estrecha, deformada con ruido; corte de arriba inclinado y
    desconchado. Musgo arriba y en la cara de atrás, liquen a manchas, tierra al pie. Runas en el frente."""
    lados = nq(16, 8)
    anillos = nq(13, 6)
    primero = len(M.caras)
    filas = []
    z0 = -HUNDIDO
    for i in range(anillos + 1):
        t = i / anillos
        z = z0 + (alto - z0) * t
        estrecha = 1.0 - 0.28 * t + 0.08 * math.sin(t * math.pi)
        fila = []
        for k in range(lados):
            a = 2 * math.pi * k / lados
            ca, sa = math.cos(a), math.sin(a)
            # rectángulo redondeado (superelipse de exponente 4)
            ex = abs(ca) ** 0.5 * (1 if ca >= 0 else -1)
            ey = abs(sa) ** 0.5 * (1 if sa >= 0 else -1)
            x = ex * ancho * 0.5 * estrecha
            y = ey * fondo * 0.5 * estrecha
            p = Vector((x + inclina * max(0.0, z) ** 1.3, y + inclina * 0.6 * max(0.0, z), z))
            dirn = Vector((ca, sa, 0.0))
            p += dirn * (0.09 * ruido(p, 1.2, semilla) + 0.025 * ruido(p, 4.5, semilla + 3))
            if i == anillos:                                  # corte de arriba inclinado y algo roto
                p.z = alto + 0.22 * (x / max(ancho, 0.01)) - 0.12 * max(0.0, ruido(p, 3.0, semilla + 7))
            fila.append(p)
        filas.append(fila)
    idx = []
    for i, fila in enumerate(filas):
        r = []
        for k, p in enumerate(fila):
            a = 2 * math.pi * k / lados
            n = Vector((math.cos(a), math.sin(a), 0.25 if i == anillos else 0.0)).normalized()
            g = ruido(p, 1.6, semilla + 11) * 0.5 + 0.5
            c = mezcla(PIEDRA[0], PIEDRA[2], g * 1.1)
            c = mezcla(c, PIEDRA[1], 0.35)
            regueros = ruido((p.x * 3.0, p.y * 3.0, p.z * 0.35), 1.0, semilla + 13)   # churretes de lluvia
            c = mezcla(c, PIEDRA[0], 0.5 * max(0.0, regueros))
            if ruido(p, 3.2, semilla + 21) > 0.35 and liquen > 0:   # liquen a manchas
                c = mezcla(c, LIQUEN, 0.55 * liquen)
            atras = max(0.0, n.y)                                      # la cara de atrás (+Y), con más musgo
            fm = suave(0.55, 1.0, p.z / alto + 0.35 * atras + 0.25 * ruido(p, 2.5, semilla + 5)) if alto > 0 else 0
            if i == anillos:
                fm = max(fm, 0.75)
            c = mezcla(c, color_musgo(p, n), fm)
            c = mezcla(c, TIERRA, 0.85 * suave(0.45, -0.1, p.z))
            r.append(M.vert(p, c))
        idx.append(r)
    for i in range(anillos):
        for k in range(lados):
            k2 = (k + 1) % lados
            M.cara([idx[i][k], idx[i][k2], idx[i + 1][k2], idx[i + 1][k]])
    top = sum((filas[-1][k] for k in range(lados)), Vector()) / lados
    top.z += 0.04
    c = M.vert(top, color_musgo(top))
    for k in range(lados):
        M.cara([idx[-1][k], idx[-1][(k + 1) % lados], c])
    # runas en el frente, en columna
    bvh = bvh_de(M, primero)
    if runas > 0:
        alto_util = alto * 0.62
        paso = alto_util / runas
        tam = min(0.3, paso * 0.72, ancho * 0.42)
        for j in range(runas):
            cz = alto * 0.3 + paso * (j + 0.5)
            cx = inclina * max(0.0, cz) ** 1.3
            glifo(M, bvh, cx, cz, tam, int(semilla * 7 + j * 5))


def arco_raiz(M, largo_ang, alto, radio, semilla, cintas=0, raicillas=2):
    """Raíz enorme que sale del suelo, se arquea y vuelve a hundirse, curvada con el anillo."""
    n = nq(20, 9)
    pts, rads = [], []
    for i in range(n + 1):
        t = i / n
        phi = (t - 0.5) * largo_ang
        x = R_ANILLO * math.sin(phi)
        y = -R_ANILLO * (1 - math.cos(phi))
        h = alto * math.sin(math.pi * (0.06 + t * 0.88)) ** 0.8 - HUNDIDO * 0.9
        h += 0.12 * ruido((x, y, 0), 0.7, semilla)
        y += 0.25 * ruido((x, 0, h), 0.5, semilla + 2)
        pts.append(Vector((x, y, h)))
        rads.append(radio * (1.0 - 0.45 * t) * (1 + 0.12 * math.sin(t * 11 + semilla)))
    pts, anillos = tubo(M, pts, rads, lados=nq3(12), amp=0.1, surcos=7, musgo=0.75, semilla=semilla, giro=0.45)
    # raicillas que bajan del arco al suelo
    rnd = random.Random(int(semilla * 100))
    for j in range(raicillas):
        t = 0.3 + 0.4 * (j + rnd.random() * 0.5) / max(1, raicillas)
        i = int(t * n)
        p = pts[i]
        lado = 1 if j % 2 == 0 else -1
        fin = p + Vector((rnd.uniform(-0.4, 0.4), lado * rnd.uniform(0.6, 1.0), 0))
        fin.z = -0.25
        medio = (p + fin) * 0.5 + Vector((0, lado * 0.25, 0.15))
        sub = [p, p.lerp(medio, 0.5), medio, medio.lerp(fin, 0.5), fin]
        r0 = rads[i] * 0.42
        tubo(M, sub, [r0, r0 * 0.85, r0 * 0.7, r0 * 0.5, r0 * 0.35], lados=nq(6, 4), amp=0.08, musgo=0.4,
             semilla=semilla + j, tapa0=False)
    # cintas de ofrenda atadas bajo el arco (alguien viene a velar aquí)
    for j in range(cintas):
        t = 0.38 + 0.08 * j
        i = int(t * n)
        p = pts[i] - Vector((0, 0, rads[i] * 0.9))
        largo = 0.55 + 0.18 * ((j * 7) % 3)
        cola = [p + Vector((0.05 * math.sin(s * 1.7 + j), -0.04 * s, -largo * s / 4)) for s in range(5)]
        tira(M, cola, 0.11, CINTAS[j % len(CINTAS)])
    # colisión: cilindros a lo largo de lo que asoma
    for i in range(0, n + 1, 2):
        if pts[i].z > 0.15:
            M.choque(pts[i].x, pts[i].y, rads[i] + 0.12, max(0.6, pts[i].z + rads[i]))


def raiz_baja(M, largo, radio, semilla, curva=0.6):
    """Raíz que repta medio enterrada, con una rama."""
    n = nq(10, 5)
    pts, rads = [], []
    for i in range(n + 1):
        t = i / n
        x = (t - 0.5) * largo
        y = curva * math.sin(t * math.pi * 1.3 + semilla) * 0.5
        z = -0.08 + 0.14 * math.sin(t * math.pi * 2.2 + semilla) + 0.05
        pts.append(Vector((x, y, z)))
        rads.append(radio * (1.0 - 0.6 * t))
    pts, _ = tubo(M, pts, rads, lados=nq3(9), amp=0.1, surcos=5, musgo=0.55, semilla=semilla, tapa0=True)
    i = n // 2
    fin = pts[i] + Vector((largo * 0.25, 0.6, -0.1))
    sub = [pts[i], pts[i].lerp(fin, 0.5) + Vector((0, 0, 0.08)), fin]
    tubo(M, sub, [rads[i] * 0.6, rads[i] * 0.45, rads[i] * 0.3], lados=nq(6, 4), musgo=0.5, semilla=semilla + 1,
         tapa0=False)


def tocon(M):
    """Tocón-trono: corte roto, más alto detrás (respaldo), raíces de contrafuerte y un ojo tallado en el frente."""
    lados = 36 if Q >= 1.0 else 18           # múltiplo de 3: una costilla de corteza cada tres vértices
    perfil = [(-HUNDIDO, 1.22), (0.0, 1.16), (0.22, 0.96), (0.55, 0.86), (0.9, 0.82), (1.15, 0.8)]
    primero = len(M.caras)
    filas = []

    def rim(a, k):
        atras = max(0.0, math.sin(a))          # +Y: lejos del centro del claro
        astilla = 0.28 * (ruido((k * 0.7, 0, 0), 1.0, 6.0) * 0.5 + 0.5) if k % 2 else 0.0   # borde roto, en astillas
        return 1.1 + 0.75 * atras ** 1.5 + 0.15 * ruido((math.cos(a) * 3, math.sin(a) * 3, 0), 1.0, 4.0) + astilla

    perfil_n = perfil if Q >= 1.0 else [perfil[0], perfil[1], perfil[3], perfil[5]]
    for (z, r) in perfil_n + [(None, 0.8)]:
        fila = []
        for k in range(lados):
            a = 2 * math.pi * k / lados
            zz = rim(a, k) if z is None else z
            # costillas de corteza: cada tercer vértice, un surco hondo y oscuro que serpentea al subir
            fase = (k + int(round((zz + 0.4) * 1.3))) % 3
            surco = 0.05 if fase == 0 else (0.75 if fase == 1 else 0.95)
            rr = r * (1 + 0.1 * (surco * 2 - 1) + 0.04 * ruido((math.cos(a), math.sin(a), zz), 2.0, 9))
            p = Vector((math.cos(a) * rr, math.sin(a) * rr, zz))
            n = Vector((math.cos(a), math.sin(a), 0.2))
            c = color_corteza(CORTEZA, surco, ruido(p, 3.0, 2), n, 0.0, p)
            mm = ruido(p, 2.2, 12.0) * 0.5 + 0.5                     # musgo que trepa por el lado de atrás
            c = mezcla(c, color_musgo(p), suave(0.55, 0.9, mm + 0.35 * max(0.0, math.sin(a)) + 0.15 * zz) * 0.85)
            if z is None:
                c = mezcla(c, color_musgo(p), 0.6)
            fila.append((p, c))
        filas.append(fila)
    idx = [[M.vert(p, c) for (p, c) in fila] for fila in filas]
    for i in range(len(idx) - 1):
        for k in range(lados):
            k2 = (k + 1) % lados
            M.cara([idx[i][k], idx[i][k2], idx[i + 1][k2], idx[i + 1][k]])
    # corte de arriba: un cuenco poco hondo con anillos de crecimiento
    interior = []
    for k in range(lados):
        a = 2 * math.pi * k / lados
        p = Vector((math.cos(a) * 0.6, math.sin(a) * 0.6, rim(a, 0) * 0.35 + 1.0 * 0.65 - 0.05))
        interior.append(M.vert(p, mezcla(MADERA[0], MADERA[1], 0.5 + 0.5 * math.sin(0.72 * 14))))
    for k in range(lados):
        k2 = (k + 1) % lados
        M.cara([idx[-1][k], idx[-1][k2], interior[k2], interior[k]])
    centro = M.vert((0, 0, 0.98), MADERA[0])
    for k in range(lados):
        M.cara([interior[k], interior[(k + 1) % lados], centro])
    bvh = bvh_de(M, primero)
    # el ojo tallado (el que vela): almendra y pupila, en el frente
    cz = 0.78
    pts_sup = [(-0.36 + 0.72 * s / 6, cz + 0.17 * math.sin(math.pi * s / 6)) for s in range(7)]
    pts_inf = [(-0.36 + 0.72 * s / 6, cz - 0.15 * math.sin(math.pi * s / 6)) for s in range(7)]
    for linea in (pts_sup, pts_inf):
        for s in range(6):
            trazo(M, bvh, linea[s], linea[s + 1], grosor=0.045)
    for (a, b) in [((-0.07, cz), (0.0, cz + 0.09)), ((0.0, cz + 0.09), (0.07, cz)), ((0.07, cz), (0.0, cz - 0.09)),
                   ((0.0, cz - 0.09), (-0.07, cz))]:
        trazo(M, bvh, a, b, grosor=0.06)
    trazo(M, bvh, (0.0, cz + 0.32), (0.0, cz + 0.22), grosor=0.04)          # pestañas: tres rayas sobre el ojo
    trazo(M, bvh, (-0.22, cz + 0.27), (-0.17, cz + 0.18), grosor=0.04)
    trazo(M, bvh, (0.22, cz + 0.27), (0.17, cz + 0.18), grosor=0.04)
    # contrafuertes: raíces que bajan del tocón al suelo (ninguna por delante: ahí se arrodilla el Guardián)
    angs = [-30, 25, 70, 115, 160, 205] if Q >= 1.0 else [-30, 70, 160, 205]
    for j, g in enumerate(angs):
        a = math.radians(g)
        d = Vector((math.cos(a), math.sin(a), 0))
        p0 = d * 0.75 + Vector((0, 0, 0.75))
        p3 = d * 1.85 + Vector((0, 0, -0.3))
        p1 = d * 1.0 + Vector((0, 0, 0.5))
        p2 = d * 1.45 + Vector((0, 0, 0.1))
        tubo(M, [p0, p1, p2, p3], [0.27, 0.21, 0.15, 0.09], lados=nq3(9), amp=0.1, musgo=0.6, semilla=j * 1.7,
             tapa0=False)
    M.choque(0.0, 0.0, 0.95, 1.8)


def lecho(M):
    """El lecho del Guardián: raíces bajas que se enroscan en corro, abierto por delante (-Y), con musgo dentro."""
    tramos = [(-150, -50, 1.7), (-80, 20, 1.95), (0, 105, 1.6), (85, 145, 1.85)]   # 0 = detrás; abierto de 145 a 210
    if Q < 1.0:
        tramos = tramos[:3]
    for j, (g0, g1, r) in enumerate(tramos):
        n = nq(9, 5)
        pts, rads = [], []
        for i in range(n + 1):
            t = i / n
            a = math.radians(g0 + (g1 - g0) * t + 90)            # g = 0: detrás (+Y); g = 180: delante (-Y)
            rr = r + 0.25 * math.sin(t * math.pi * 2 + j)
            z = -0.22 + 0.5 * math.sin(math.pi * t) ** 0.7
            pts.append(Vector((math.cos(a) * rr, math.sin(a) * rr, z)))
            rads.append(0.24 - 0.08 * abs(t - 0.5) * 2)
        tubo(M, pts, rads, lados=nq3(9), amp=0.1, musgo=0.7, semilla=j * 2.3, giro=0.6)
    for j in range(nq(5, 3)):                                     # cama de musgo bajo las rodillas
        a = j * 2.4
        c = (math.cos(a) * 0.55 * (j % 3) * 0.6, math.sin(a) * 0.55 * (j % 3) * 0.6 + 0.2, -0.06)
        bulto(M, c, 0.55, escala=(1.2, 1.0, 0.22), subdiv=2, amp=0.25, color=lambda d, p: color_musgo(p, d),
              semilla=j * 1.3, z_min=-0.1)


def musgo(M, radio, semilla):
    bulto(M, (0, 0, -0.05), radio, escala=(1.25, 1.0, 0.38), subdiv=2, amp=0.3,
          color=lambda d, p: color_musgo(p, d), semilla=semilla, z_min=-0.12)


def setas(M, semilla):
    rnd = random.Random(int(semilla * 31))
    for j in range(nq(5, 3)):
        a = rnd.uniform(0, math.tau)
        base = Vector((math.cos(a) * rnd.uniform(0.05, 0.3), math.sin(a) * rnd.uniform(0.05, 0.3), -0.05))
        alto = rnd.uniform(0.12, 0.3)
        r = rnd.uniform(0.06, 0.13)
        lados = nq(7, 5)
        pie = [M.vert(base + Vector((math.cos(2 * math.pi * k / lados) * r * 0.3,
                                     math.sin(2 * math.pi * k / lados) * r * 0.3, 0)), SETA[0]) for k in range(lados)]
        cuello = [M.vert(base + Vector((math.cos(2 * math.pi * k / lados) * r * 0.25,
                                        math.sin(2 * math.pi * k / lados) * r * 0.25, alto)), SETA[0]) for k in range(lados)]
        for k in range(lados):
            k2 = (k + 1) % lados
            M.cara([pie[k], pie[k2], cuello[k2], cuello[k]])
        borde = [M.vert(base + Vector((math.cos(2 * math.pi * k / lados) * r, math.sin(2 * math.pi * k / lados) * r,
                                       alto - r * 0.15)), SETA[1]) for k in range(lados)]
        medio = [M.vert(base + Vector((math.cos(2 * math.pi * k / lados) * r * 0.7, math.sin(2 * math.pi * k / lados) * r * 0.7,
                                       alto + r * 0.35)), mezcla(SETA[1], SETA[0], 0.5)) for k in range(lados)]
        cima = M.vert(base + Vector((0, 0, alto + r * 0.55)), SETA[0])
        for k in range(lados):
            k2 = (k + 1) % lados
            M.cara([borde[k], borde[k2], medio[k2], medio[k]])
            M.cara([medio[k], medio[k2], cima])
            M.cara([cuello[k], cuello[k2], borde[k2], borde[k]])


def mojon(M, semilla):
    """Mojón de piedras apiladas (ofrenda de quien pasa)."""
    z = -0.1
    for j, r in enumerate([0.36, 0.27, 0.2, 0.13][:nq(4, 3)]):
        alto = r * 0.55
        bulto(M, (0.03 * math.sin(j * 2 + semilla), 0.03 * math.cos(j * 3), z + alto), r, escala=(1.15, 1.0, 0.55),
              subdiv=2, amp=0.18, semilla=semilla + j,
              color=lambda d, p: mezcla(mezcla(PIEDRA[0], PIEDRA[2], ruido(p, 3, 8) * 0.5 + 0.5),
                                        color_musgo(p), 0.5 * max(0.0, d.z) * (j == 0)))
        z += alto * 1.6
    M.choque(0.0, 0.0, 0.35, 0.8)


def ofrenda(M):
    """Cuenco de piedra al pie del tocón con bellotas y un ramillete seco."""
    lados = nq(10, 6)
    anillos = [(0.0, 0.26), (0.1, 0.3), (0.16, 0.28), (0.1, 0.22), (0.06, 0.0)]
    filas = []
    for (z, r) in anillos:
        filas.append([M.vert((math.cos(2 * math.pi * k / lados) * r, math.sin(2 * math.pi * k / lados) * r, z - 0.04),
                             mezcla(PIEDRA[1], PIEDRA[2], 0.3 + 0.4 * (z > 0.12))) for k in range(lados)])
    for i in range(len(filas) - 1):
        for k in range(lados):
            k2 = (k + 1) % lados
            M.cara([filas[i][k], filas[i][k2], filas[i + 1][k2], filas[i + 1][k]])
    for j in range(3):
        a = j * 2.1
        bulto(M, (math.cos(a) * 0.09, math.sin(a) * 0.09, 0.1), 0.045, escala=(1, 1, 1.25), subdiv=1, amp=0.05,
              color=lambda d, p: (0.45, 0.30, 0.16) if d.z < 0.4 else (0.30, 0.22, 0.12), semilla=j)
    for j in range(3):                                            # ramillete seco apoyado en el borde
        a = 0.6 + j * 0.25
        base = Vector((0.1, 0.05 * j, 0.12))
        tira(M, [base, base + Vector((0.18, 0.05, 0.22)), base + Vector((0.3, 0.08, 0.3))], 0.03, (0.62, 0.55, 0.40))


def brote(M):
    """El bosque recuerda: un árbol joven brota del corte del tocón, con hojas nuevas y una yema que brilla."""
    pts = [Vector((0.0, 0.05, 1.0)), Vector((0.06, 0.0, 1.75)), Vector((-0.05, -0.05, 2.45)), Vector((0.02, -0.02, 3.1))]
    pts, _ = tubo(M, pts, [0.12, 0.09, 0.06, 0.035], lados=nq(7, 5), amp=0.05, pal=((0.28, 0.24, 0.12), (0.42, 0.40, 0.18),
                  (0.55, 0.55, 0.25)), musgo=0.0, semilla=3.0)
    rnd = random.Random(5)
    ramas = [(1, 0.6, 1), (2, 2.4, -1), (2, 4.2, 1), (1, 3.6, -1)]
    puntas = [pts[-1]]
    for (i, ang, s) in ramas:
        d = Vector((math.cos(ang), math.sin(ang), 0.9)).normalized()
        fin = pts[i] + d * 0.5
        tubo(M, [pts[i], pts[i].lerp(fin, 0.5), fin], [0.035, 0.025, 0.015], lados=nq(5, 4), amp=0.03,
             pal=((0.28, 0.24, 0.12), (0.42, 0.40, 0.18), (0.55, 0.55, 0.25)), musgo=0.0, tapa0=False)
        puntas.append(fin)
    for j in range(nq(30, 14)):
        p = puntas[j % len(puntas)]
        a = rnd.uniform(0, math.tau)
        d = Vector((math.cos(a), math.sin(a), rnd.uniform(0.1, 0.8))).normalized()
        base = p + Vector((rnd.uniform(-0.15, 0.15), rnd.uniform(-0.15, 0.15), -rnd.uniform(0.0, 0.35)))
        hoja(M, base, d, Vector((0, 0, 1)) - d * 0.3, rnd.uniform(0.28, 0.4), rnd.uniform(0.14, 0.2), HOJAS[j % len(HOJAS)])
    bulto(M, pts[-1] + Vector((0, 0, 0.05)), 0.07, escala=(1, 1, 1.5), subdiv=1, amp=0.05, mat=RUNA)


def flores(M, semilla):
    rnd = random.Random(int(semilla * 13))
    for j in range(nq(11, 6)):
        a = rnd.uniform(0, math.tau)
        base = Vector((math.cos(a) * rnd.uniform(0, 0.4), math.sin(a) * rnd.uniform(0, 0.4), -0.03))
        alto = rnd.uniform(0.18, 0.34)
        cab = base + Vector((rnd.uniform(-0.04, 0.04), rnd.uniform(-0.04, 0.04), alto))
        tira(M, [base, base.lerp(cab, 0.5), cab], 0.018, (0.30, 0.52, 0.18), normal=(math.cos(a), math.sin(a), 0))
        color = FLORES[(j + int(semilla)) % len(FLORES)]
        r = rnd.uniform(0.075, 0.115)
        petalos = 5
        c = M.vert(cab + Vector((0, 0, 0.01)), (0.98, 0.85, 0.35))
        borde = []
        for k in range(petalos * 2):
            aa = math.pi * k / petalos + a
            rr = r if k % 2 == 0 else r * 0.45
            borde.append(M.vert(cab + Vector((math.cos(aa) * rr, math.sin(aa) * rr, 0.012 * (k % 2))), color))
        for k in range(petalos * 2):
            M.cara([c, borde[k], borde[(k + 1) % (petalos * 2)]])


def manantial(M):
    """Manantial nuevo entre las raíces: corro de piedras con musgo, un cuenco de tierra mojada y el agua."""
    piedras = nq(8, 5)
    for j in range(piedras):
        a = 2 * math.pi * j / piedras + 0.3
        r = 0.72 + 0.06 * math.sin(j * 3)
        bulto(M, (math.cos(a) * r, math.sin(a) * r, 0.1), 0.2 + 0.05 * (j % 3), escala=(1.2, 0.9, 0.6), subdiv=2, amp=0.2,
              semilla=j * 1.9, color=lambda d, p: mezcla(mezcla(PIEDRA[0], PIEDRA[2], ruido(p, 3, 4) * 0.5 + 0.5),
                                                          color_musgo(p), 0.6 * max(0.0, d.z)))
    lados = nq(14, 8)
    borde = [M.vert((math.cos(2 * math.pi * k / lados) * 0.75, math.sin(2 * math.pi * k / lados) * 0.75, 0.13),
                    (0.26, 0.22, 0.16)) for k in range(lados)]
    fondo = [M.vert((math.cos(2 * math.pi * k / lados) * 0.45, math.sin(2 * math.pi * k / lados) * 0.45, 0.02),
                    (0.18, 0.16, 0.12)) for k in range(lados)]
    for k in range(lados):
        k2 = (k + 1) % lados
        M.cara([borde[k], borde[k2], fondo[k2], fondo[k]])
    cf = M.vert((0, 0, 0.0), (0.16, 0.14, 0.11))
    for k in range(lados):
        M.cara([fondo[k], fondo[(k + 1) % lados], cf])
    agua = [M.vert((math.cos(2 * math.pi * k / lados) * 0.68, math.sin(2 * math.pi * k / lados) * 0.68, 0.11), BLANCO)
            for k in range(lados)]
    ca = M.vert((0, 0, 0.11), BLANCO)
    for k in range(lados):
        M.cara([agua[k], agua[(k + 1) % lados], ca], AGUA)


def raiz_seca(M, semilla):
    """Raíz partida y seca (tras derrotar al Guardián): corteza gris y la punta astillada."""
    rnd = random.Random(int(semilla * 17))
    pts = [Vector((-0.6, 0, -0.3)), Vector((-0.2, 0.05, 0.25)), Vector((0.15, -0.05, 0.6)), Vector((0.35, 0.0, 0.85))]
    tubo(M, pts, [0.22, 0.19, 0.16, 0.14], lados=nq3(9), amp=0.14, surcos=9, pal=SECA, musgo=0.0, semilla=semilla,
         punta=False)
    # astillas
    p = pts[-1]
    for j in range(nq(5, 3)):
        a = 2 * math.pi * j / 5 + rnd.uniform(-0.3, 0.3)
        b = p + Vector((math.cos(a) * 0.1, math.sin(a) * 0.1, 0))
        tip = b + Vector((math.cos(a) * 0.05, math.sin(a) * 0.05, rnd.uniform(0.12, 0.3)))
        i0 = M.vert(b + Vector((-math.sin(a) * 0.05, math.cos(a) * 0.05, 0)), SECA[1])
        i1 = M.vert(b + Vector((math.sin(a) * 0.05, -math.cos(a) * 0.05, 0)), SECA[1])
        i2 = M.vert(tip, SECA[2])
        M.cara([i0, i1, i2])
        M.cara([i2, i1, i0])
    M.choque(0.0, 0.0, 0.3, 0.9)


# ---------------------------------------------------------------- el kit

def kit():
    """Nombre de la pieza -> función que la construye."""
    return {
        "menhir_alto": lambda M: (piedra(M, 3.1, 0.95, 0.62, 1.0, inclina=0.07, runas=4), M.choque(0.1, 0.0, 0.55, 3.0)),
        "menhir_ancho": lambda M: (piedra(M, 2.4, 1.35, 0.7, 2.0, inclina=-0.05, runas=3, liquen=0.8),
                                   M.choque(0.0, 0.0, 0.72, 2.4)),
        "menhir_puerta": lambda M: (piedra(M, 1.55, 0.72, 0.5, 3.0, inclina=0.04, runas=2), M.choque(0.0, 0.0, 0.45, 1.6)),
        "raiz_arco_grande": lambda M: arco_raiz(M, 1.05, 2.0, 0.46, 4.0, cintas=5, raicillas=3),
        "raiz_arco": lambda M: arco_raiz(M, 0.8, 1.3, 0.34, 5.0, cintas=0, raicillas=2),
        "raiz_baja": lambda M: raiz_baja(M, 3.2, 0.22, 6.0),
        "tocon": tocon,
        "lecho": lecho,
        "musgo": lambda M: musgo(M, 0.5, 7.0),
        "setas": lambda M: setas(M, 8.0),
        "mojon": lambda M: mojon(M, 9.0),
        "ofrenda": ofrenda,
        "brote": brote,
        "flores": lambda M: flores(M, 10.0),
        "manantial": manantial,
        "raiz_seca": lambda M: raiz_seca(M, 11.0),
    }


def material(nombre):
    m = bpy.data.materials.get(nombre)
    if m is not None:
        return m
    m = bpy.data.materials.new(nombre)
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    if nombre == "base":
        ca = m.node_tree.nodes.new("ShaderNodeVertexColor")
        ca.layer_name = "Color"
        gam = m.node_tree.nodes.new("ShaderNodeGamma")      # solo para verlo bien en Blender (el atributo va en sRGB)
        gam.inputs["Gamma"].default_value = 2.2
        m.node_tree.links.new(ca.outputs["Color"], gam.inputs["Color"])
        m.node_tree.links.new(gam.outputs["Color"], bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.9
    elif nombre == "runa":
        bsdf.inputs["Base Color"].default_value = (0.7, 0.85, 0.95, 1)
        bsdf.inputs["Emission Color"].default_value = (0.7, 0.85, 0.95, 1)
        bsdf.inputs["Emission Strength"].default_value = 1.0
    else:
        bsdf.inputs["Base Color"].default_value = (0.25, 0.5, 0.65, 1)
        bsdf.inputs["Roughness"].default_value = 0.05
    return m


def objeto(nombre, M, x_desfase):
    me = bpy.data.meshes.new(nombre)
    me.from_pydata([tuple(v) for v in M.v], [], M.caras)
    me.update()
    me.polygons.foreach_set("material_index", M.mats)
    attr = me.color_attributes.new("Color", 'FLOAT_COLOR', 'POINT')
    cols = []
    for c in M.col:
        cols += list(c) + [1.0]       # en sRGB, sin pasar a lineal (ver la cabecera)
    attr.data.foreach_set("color", cols)
    me.color_attributes.active_color = attr
    me.validate(clean_customdata=False)   # quita caras degeneradas, si las hay, sin descolocar colores ni materiales
    for nm in ("base", "runa", "agua"):
        me.materials.append(material(nm))
    me.shade_smooth()
    if nombre.startswith("menhir") or nombre in ("mojon", "manantial", "ofrenda"):
        me.set_sharp_from_angle(angle=math.radians(48))      # piedra: aristas marcadas, caras suaves
    ob = bpy.data.objects.new(nombre, me)
    bpy.context.scene.collection.objects.link(ob)
    for j, (x, y, r, h) in enumerate(M.choques):
        e = bpy.data.objects.new("choque_%d_%d" % (round(r * 100), round(h * 100)), None)
        e.empty_display_type = 'CIRCLE'
        e.location = (x, y, 0.0)
        e.scale = (r, r, h)
        e.parent = ob
        bpy.context.scene.collection.objects.link(e)
    return ob


def construir(calidad, ruta):
    global Q
    Q = calidad
    bpy.ops.wm.read_factory_settings(use_empty=True)
    total = 0
    for nombre, f in kit().items():
        M = Malla()
        f(M)
        objeto(nombre, M, 0.0)
        tri = M.triangulos()
        total += tri
        print("PIEZA %-18s triángulos %5d  choques %d" % (nombre, tri, len(M.choques)))
    print("KIT (calidad %.2f) triángulos de una pieza de cada: %d" % (calidad, total))
    if ruta:
        bpy.ops.export_scene.gltf(filepath=ruta, export_format='GLB', use_selection=False, export_animations=False,
                                  export_yup=True, export_vertex_color='ACTIVE', export_cameras=False,
                                  export_lights=False, export_apply=True)
        print("EXPORTADO", ruta)


construir(1.0, os.path.join(CARPETA, "claro_guardian.glb") if CARPETA else "")
construir(0.55, os.path.join(CARPETA, "claro_guardian_ligero.glb") if CARPETA else "")
