# Distrito de los oficios de Oakhaven 3D (V10, hitos 2 y 10): la herrería de Maese Ferro, el taller de armaduras de
# Hilda, dos puestos de mercado, dos casas con patio, el frente de la botica (Mirta) y el rincón del pozo viejo, junto a la
# plaza. Hecho desde cero con este guion (geometría procedural propia: ningún recurso descargado; obra propia del
# proyecto), con el método del Claro del Guardián (zonas3d/bosque/fuente/crear_claro.py).
#
#   blender -b --factory-startup -P crear_distrito.py -- <carpeta de salida>
#
# Escribe <carpeta>/distrito.glb (perfil alto) y <carpeta>/distrito_ligero.glb (medio y bajo: las mismas piezas con
# menos lados, menos tejas y menos atrezo). Misma semilla, mismo resultado.
#
# A diferencia del claro, el GLB es el distrito YA MONTADO en su sitio de la ciudad (coordenadas de Oakhaven 3D: una
# casilla es un metro; x al este, z al sur, y arriba). zonas3d/oakhaven/distrito.gd lo carga, junta cada grupo en una malla
# por material y pone choques, encargados, fuego, humo y puntos de servicio.
#
# Objetos (nombre → qué hace con él distrito.gd):
#   edif_<nombre>    un edificio que puede tapar a Kael: su malla va colgada de su choque y se vuelve medio transparente
#   bajo             todo lo bajo (puestos, atrezo, carteles, pozo, frente de la botica): una malla por material
#   pnj_<nombre>     un encargado (figura sencilla, origen en los pies, mirando al sur); pnj_ferro_brazo, el brazo del
#                    martillo (origen en el hombro: distrito.gd lo hace golpear el yunque)
# Materiales (los sustituye distrito.gd; aquí solo separan las superficies):
#   base     colores de vértice (en sRGB, como el claro y la ciudad: mat.sillar() los usa tal cual)
#   brillo   lo que da luz propia (brasas, ventanas, farolillos, la cara iluminada de los carteles): sin sombreado
# Vacíos:
#   caja_<i>_<ancho cm>_<fondo cm>_<alto cm>   hijo de su objeto: un choque de caja con la base en esa posición
#   ancla_<nombre>                             posiciones con nombre (encargados, puntos de servicio, fuego, humo, pozo)
#
# Ejes: aquí se trabaja en coordenadas de Godot (x, y arriba, z al sur) y se pasan a Blender (x, -z, y) al crear cada
# vértice; el exportador glTF (y arriba) las devuelve tal cual. La cámara del juego mira al norte desde arriba (52°): lo
# que se ve son los tejados, las fachadas que dan al sur y lo que queda delante de los aleros. Por eso los oficios
# trabajan al aire libre, delante de su taller, y los carteles cuelgan donde ningún alero los tapa.
import bpy, bmesh, sys, os, math, random
from mathutils import Vector, noise
from mathutils.geometry import tessellate_polygon

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
CARPETA = argv[0] if argv else ""

BASE, BRILLO = 0, 1
Q = 1.0                       # calidad: 1 en el GLB alto, menos en el ligero
RND = random.Random(7)

# ---------------------------------------------------------------- colores (sRGB)

PIEDRA = ((0.44, 0.42, 0.42), (0.56, 0.53, 0.50), (0.68, 0.64, 0.58))
PIEDRA_FRIA = ((0.40, 0.41, 0.45), (0.52, 0.53, 0.56), (0.62, 0.62, 0.64))
MORTERO = (0.27, 0.25, 0.25)
REVOQUE = (0.88, 0.80, 0.66)
REVOQUE_ROSA = (0.88, 0.74, 0.66)
MADERA_OSC = (0.30, 0.20, 0.13)
MADERA = (0.48, 0.33, 0.21)
MADERA_CLARA = (0.64, 0.48, 0.31)
TEJA = ((0.52, 0.19, 0.14), (0.62, 0.25, 0.18), (0.72, 0.33, 0.22))
PIZARRA = ((0.24, 0.28, 0.40), (0.31, 0.36, 0.50), (0.39, 0.44, 0.58))
HIERRO = (0.19, 0.19, 0.22)
ACERO = (0.60, 0.62, 0.67)
ACERO_CLARO = (0.78, 0.80, 0.84)
ORO = (0.86, 0.66, 0.28)
CUERO = (0.42, 0.26, 0.15)
ROJO = (0.70, 0.19, 0.17)
CREMA = (0.93, 0.87, 0.71)
VERDE = (0.27, 0.50, 0.30)
AZUL = (0.21, 0.33, 0.60)
HOJA = ((0.17, 0.30, 0.13), (0.24, 0.40, 0.17), (0.34, 0.50, 0.21))
FLORES = [(0.92, 0.40, 0.48), (0.96, 0.84, 0.40), (0.70, 0.52, 0.86), (0.96, 0.95, 0.88)]
PIEL = (0.88, 0.68, 0.54)
# brillo (sin sombreado: el color es la luz)
LUZ_VENTANA = (1.0, 0.76, 0.40)
LUZ_CARTEL = (0.84, 0.73, 0.52)
BRASA = ((0.85, 0.20, 0.06), (1.0, 0.48, 0.12), (1.0, 0.80, 0.36))


def mezcla(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(a[i] * (1 - t) + b[i] * t for i in range(3))


def jit(c, a=0.06):
    k = 1 + RND.uniform(-a, a)
    return tuple(max(0.0, min(1.0, x * k)) for x in c)


def elige(pal):
    return pal[RND.randrange(len(pal))]


def nq(n, minimo=3):
    return max(minimo, int(round(n * Q)))


# ---------------------------------------------------------------- constructor de mallas (coordenadas de Godot)

class Malla:
    def __init__(self):
        self.v, self.col, self.caras, self.mats = [], [], [], []
        self.cajas = []            # (x centro, z centro, ancho x, fondo z, alto)

    def vert(self, p, c):
        self.v.append(Vector((p[0], -p[2], p[1])))       # Godot (x, y, z) → Blender (x, -z, y)
        self.col.append(tuple(c))
        return len(self.v) - 1

    def cara(self, idx, mat=BASE):
        self.caras.append(tuple(idx))
        self.mats.append(mat)

    def caja_choque(self, x0, z0, x1, z1, alto):
        self.cajas.append(((x0 + x1) * 0.5, (z0 + z1) * 0.5, abs(x1 - x0), abs(z1 - z0), alto))

    def triangulos(self):
        return sum(len(f) - 2 for f in self.caras)


ANCLAS = {}


def ancla(nombre, p):
    ANCLAS[nombre] = tuple(p)


def V(*a):
    return Vector(a[0]) if len(a) == 1 else Vector(a)


def cara(M, pts, c, hacia=None, mat=BASE):
    """Una cara plana (de 3 o más puntos), con sus propios vértices: color plano. «hacia»: hacia dónde mira."""
    pts = [V(p) for p in pts]
    cols = list(c) if isinstance(c, list) else [c] * len(pts)
    if hacia is not None:
        n = (pts[1] - pts[0]).cross(pts[2] - pts[0])
        if n.dot(V(hacia)) < 0:
            pts.reverse()
            cols.reverse()
    M.cara([M.vert(p, cols[i]) for i, p in enumerate(pts)], mat)


def caja(M, a, b, c, mat=BASE, abajo=False, jitter=0.05, caras="nseoa"):
    """Caja alineada de a (mín) a b (máx). caras: n(orte) s(ur) e(ste) o(este) a(rriba); abajo aparte."""
    x0, y0, z0 = a
    x1, y1, z1 = b
    if "a" in caras:
        cara(M, [(x0, y1, z0), (x1, y1, z0), (x1, y1, z1), (x0, y1, z1)], jit(mezcla(c, (1, 1, 1), 0.06), jitter), (0, 1, 0), mat)
    if "s" in caras:
        cara(M, [(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)], jit(c, jitter), (0, 0, 1), mat)
    if "n" in caras:
        cara(M, [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0)], jit(c, jitter), (0, 0, -1), mat)
    if "e" in caras:
        cara(M, [(x1, y0, z0), (x1, y0, z1), (x1, y1, z1), (x1, y1, z0)], jit(mezcla(c, (0, 0, 0), 0.06), jitter), (1, 0, 0), mat)
    if "o" in caras:
        cara(M, [(x0, y0, z0), (x0, y0, z1), (x0, y1, z1), (x0, y1, z0)], jit(mezcla(c, (0, 0, 0), 0.06), jitter), (-1, 0, 0), mat)
    if abajo:
        cara(M, [(x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1)], c, (0, -1, 0), mat)


def caja_t(M, centro, tam, ux, uy, c, mat=BASE, jitter=0.05):
    """Caja orientada: centro, tamaño (a lo largo de ux, uy y su normal) y dos ejes."""
    ux, uy = V(ux).normalized(), V(uy).normalized()
    uz = ux.cross(uy).normalized()
    uy = uz.cross(ux).normalized()
    o = V(centro)
    hx, hy, hz = ux * tam[0] * 0.5, uy * tam[1] * 0.5, uz * tam[2] * 0.5
    for d, e1, e2 in ((hx, hy, hz), (-hx, hy, hz), (hy, hx, hz), (-hy, hx, hz), (hz, hx, hy), (-hz, hx, hy)):
        p = o + d
        cara(M, [p - e1 - e2, p + e1 - e2, p + e1 + e2, p - e1 + e2], jit(c, jitter), d, mat)


def marco(d):
    d = V(d).normalized()
    ref = V(0, 1, 0) if abs(d.y) < 0.9 else V(1, 0, 0)
    u = d.cross(ref).normalized()
    return u, d.cross(u).normalized()


def tubo(M, a, b, ra, rb, lados, c, tapa_a=True, tapa_b=True, mat=BASE, plano=False, dentro=False):
    """Cilindro o cono de a a b. Con «plano», cada cara con su color (duelas, facetas); con «dentro», las caras miran
    hacia el eje (el interior del pozo)."""
    sentido = -1 if dentro else 1
    a, b = V(a), V(b)
    d = (b - a).normalized()
    u, w = marco(d)
    ra_, rb_ = [], []
    for k in range(lados):
        t = 2 * math.pi * k / lados
        r = u * math.cos(t) + w * math.sin(t)
        ra_.append(a + r * ra)
        rb_.append(b + r * rb)
    cols = c if isinstance(c, list) else None
    if plano:
        for k in range(lados):
            k2 = (k + 1) % lados
            cc = cols[k % len(cols)] if cols else jit(c, 0.04)
            medio = (ra_[k] + ra_[k2]) * 0.5 - a
            cara(M, [ra_[k], ra_[k2], rb_[k2], rb_[k]], cc, medio * sentido, mat)
    else:
        cc = cols[0] if cols else c
        ia = [M.vert(p, cc) for p in ra_]
        ib = [M.vert(p, cc) for p in rb_]
        for k in range(lados):
            k2 = (k + 1) % lados
            q = [ia[k], ia[k2], ib[k2], ib[k]]
            n = (M.v[q[1]] - M.v[q[0]]).cross(M.v[q[2]] - M.v[q[0]])
            rad = Vector((((ra_[k] + ra_[k2]) * 0.5 - a)[0], -((ra_[k] + ra_[k2]) * 0.5 - a)[2], ((ra_[k] + ra_[k2]) * 0.5 - a)[1]))
            if n.dot(rad) * sentido < 0:
                q.reverse()
            M.cara(q, mat)
    cc = cols[0] if cols else c
    if tapa_a and ra > 0.001:
        cara(M, ra_, mezcla(cc, (0, 0, 0), 0.1), -d, mat)
    if tapa_b and rb > 0.001:
        cara(M, rb_, mezcla(cc, (1, 1, 1), 0.08), d, mat)


def bulto(M, centro, radio, escala=(1, 1, 1), subdiv=1, amp=0.18, color=None, semilla=0.0, y_min=None, mat=BASE):
    """Icosfera deformada (montones, sacos, copas, hiedra). color: tupla o función (dirección, punto) → color."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=1.0)
    idx = {}
    for v in bm.verts:
        d = v.co.normalized()
        r = radio * (1 + amp * noise.noise(d * 2.3 + Vector((semilla, semilla * 0.37, 1.3))))
        p = V(centro) + V(d.x * escala[0], d.z * escala[1], d.y * escala[2]) * r   # (icosfera: z arriba en Blender)
        if y_min is not None:
            p.y = max(p.y, y_min)
        cc = color(V(d.x, d.z, d.y), p) if callable(color) else (color or PIEDRA[1])
        idx[v.index] = M.vert(p, cc)
    for f in bm.faces:
        q = [idx[v.index] for v in f.verts]
        q.reverse()                                   # (la conversión de ejes invierte el sentido de la icosfera)
        M.cara(q, mat)
    bm.free()


def poligono(M, pts2, origen, U, Vv, c, hacia, mat=BASE):
    """Polígono plano (cóncavo vale) en el plano origen + U·u + V·v."""
    o, U, Vv = V(origen), V(U), V(Vv)
    tris = tessellate_polygon([[Vector((u, v, 0.0)) for (u, v) in pts2]])
    for t in tris:
        cara(M, [o + U * pts2[i][0] + Vv * pts2[i][1] for i in t], c, hacia, mat)


def muro_bloques(M, origen, U, largo, alto, hacia, pal, bloque=(0.44, 0.27), mortero=MORTERO, sep=0.02):
    """Cara de un muro de sillares (vista desde «hacia»): llaga oscura detrás y un bloque por pieza, a soga."""
    o, U, N = V(origen), V(U).normalized(), V(hacia).normalized()
    Y = V(0, 1, 0)
    cara(M, [o, o + U * largo, o + U * largo + Y * alto, o + Y * alto], mortero, N)
    bw, bh = bloque[0] / math.sqrt(Q), bloque[1] / math.sqrt(Q)
    y, fila = 0.0, 0
    while y < alto - 0.01:
        h = min(bh * RND.uniform(0.85, 1.15), alto - y)
        x = -bw * 0.5 * (fila % 2) * RND.uniform(0.6, 1.0)
        while x < largo - 0.01:
            w = bw * RND.uniform(0.75, 1.25)
            x0, x1 = max(0.0, x) + sep, min(largo, x + w) - sep
            if x1 - x0 > 0.05:
                c = jit(mezcla(pal[0], pal[2], RND.random()), 0.03)
                p = o + N * 0.012
                cara(M, [p + U * x0 + Y * (y + sep), p + U * x1 + Y * (y + sep), p + U * x1 + Y * (y + h - sep),
                         p + U * x0 + Y * (y + h - sep)], c, N)
            x += w
        y += h
        fila += 1


def tablas(M, origen, U, largo, alto, hacia, c, n, vertical=True):
    """Cara de tablas (puerta, tablero, frente de mostrador), cada una con su tono."""
    o, U, N = V(origen), V(U).normalized(), V(hacia).normalized()
    Y = V(0, 1, 0)
    for i in range(n):
        if vertical:
            a, b = largo * i / n, largo * (i + 1) / n
            q = [o + U * a, o + U * b, o + U * b + Y * alto, o + U * a + Y * alto]
        else:
            a, b = alto * i / n, alto * (i + 1) / n
            q = [o + Y * a, o + U * largo + Y * a, o + U * largo + Y * b, o + Y * b]
        cara(M, q, jit(c, 0.09), N)


def tejado(M, R0, R1, E0, E1, pal, filas, segs, grosor=0.07, alero=MADERA_OSC, labio=True):
    """Faldón de tejas de la cumbrera R0-R1 al alero E0-E1, en hiladas escalonadas (cada una monta sobre la de abajo)."""
    R0, R1, E0, E1 = V(R0), V(R1), V(E0), V(E1)
    fuera = (R1 - R0).cross(E0 - R0)
    if fuera.y < 0:
        fuera = -fuera
    fuera.normalize()
    filas, segs = nq(filas, 3), nq(segs, 3)
    for i in range(filas):
        t0, t1 = i / filas, (i + 1) / filas
        for j in range(segs):
            s0, s1 = j / segs, (j + 1) / segs
            p = lambda t, s: (R0.lerp(R1, s)).lerp(E0.lerp(E1, s), t)
            a, b = p(t0, s0), p(t0, s1)
            c_, d = p(t1, s1) + fuera * grosor, p(t1, s0) + fuera * grosor
            col = jit(mezcla(elige(pal), pal[1], 0.3), 0.07)
            cara(M, [a, b, c_, d], col, fuera)
            if labio and Q >= 1.0:                       # el canto de la hilada: la sombra que dibuja las tejas
                cara(M, [d, c_, p(t1, s1), p(t1, s0)], mezcla(col, (0, 0, 0), 0.35), E0 - R0)
    # canto del alero
    baja = (E1 - E0).cross(fuera).normalized()
    cara(M, [E0, E1, E1 - fuera * 0.12, E0 - fuera * 0.12], alero, E0 - R0)


def ventana(M, centro, ancho, alto, U, hacia, marco_c=MADERA_OSC, contraventanas=None, macetero=False):
    """Ventana encendida: cristal con luz, marco, cruceta, alféizar; contraventanas y macetero de flores si se piden."""
    o, U, N = V(centro), V(U).normalized(), V(hacia).normalized()
    Y = V(0, 1, 0)
    hx, hy = U * ancho * 0.5, Y * alto * 0.5
    p = o + N * 0.015
    cara(M, [p - hx - hy, p + hx - hy, p + hx + hy, p - hx + hy], LUZ_VENTANA, N, BRILLO)
    g = 0.06
    for (a, b) in [(-hx - hy, hx - hy), (-hx + hy, hx + hy)]:            # dintel y alféizar
        c_ = o + (a + b) * 0.5 + N * 0.03
        caja_t(M, c_, (ancho + 2 * g, g, 0.06), U, Y, marco_c)
    for s in (-1, 1):
        caja_t(M, o + hx * s + N * 0.03, (g, alto, 0.06), U, Y, marco_c)
    caja_t(M, o + N * 0.03, (0.035, alto, 0.04), U, Y, marco_c)             # cruceta
    caja_t(M, o + N * 0.03, (ancho, 0.035, 0.04), U, Y, marco_c)
    caja_t(M, o - hy - Y * 0.04 + N * 0.06, (ancho + 0.2, 0.05, 0.14), U, Y, MADERA_CLARA)
    if contraventanas:
        for s in (-1, 1):
            caja_t(M, o + U * (ancho * 0.5 + 0.2) * s + N * 0.04, (0.36, alto + 0.04, 0.04), U, Y, contraventanas)
    if macetero:
        caja_t(M, o - hy - Y * 0.16 + N * 0.14, (ancho + 0.1, 0.16, 0.18), U, Y, MADERA)
        if Q >= 0.7:
            for k in range(3):
                cc = FLORES[(k + int(o.x * 3)) % len(FLORES)]
                bulto(M, o - hy - Y * 0.02 + N * 0.16 + U * (ancho * (k - 1) * 0.33), 0.11, (1.3, 0.8, 0.9), 0, 0.25,
                      lambda d, q, cc=cc: cc if d.y > 0.2 else HOJA[1], k)


def puerta(M, base, ancho, alto, U, hacia, c=MADERA, n=5):
    o, U, N = V(base), V(U).normalized(), V(hacia).normalized()
    Y = V(0, 1, 0)
    tablas(M, o - U * ancho * 0.5 + N * 0.02, U, ancho, alto, N, c, nq(n, 3))
    caja_t(M, o + Y * (alto + 0.05) + N * 0.04, (ancho + 0.2, 0.1, 0.08), U, Y, MADERA_OSC)
    for s in (-1, 1):
        caja_t(M, o + U * (ancho * 0.5 + 0.04) * s + Y * alto * 0.5 + N * 0.04, (0.08, alto, 0.08), U, Y, MADERA_OSC)
    for hh in (0.25, 0.75):                                                  # bisagras
        caja_t(M, o - U * ancho * 0.3 + Y * alto * hh + N * 0.035, (ancho * 0.45, 0.04, 0.02), U, Y, HIERRO)


def farolillo(M, p, colgado=True):
    """Farolillo de hierro con su luz (la luz, en brillo)."""
    p = V(p)
    caja(M, (p.x - 0.09, p.y - 0.14, p.z - 0.09), (p.x + 0.09, p.y + 0.14, p.z + 0.09), LUZ_VENTANA, BRILLO, jitter=0)
    caja(M, (p.x - 0.11, p.y + 0.14, p.z - 0.11), (p.x + 0.11, p.y + 0.19, p.z + 0.11), HIERRO)
    caja(M, (p.x - 0.1, p.y - 0.18, p.z - 0.1), (p.x + 0.1, p.y - 0.14, p.z + 0.1), HIERRO)
    if colgado:
        caja(M, (p.x - 0.012, p.y + 0.19, p.z - 0.012), (p.x + 0.012, p.y + 0.36, p.z + 0.012), HIERRO, caras="seo")


def barril(M, base, r=0.3, h=0.72, tapa=MADERA_CLARA, agua=False):
    b = V(base)
    lados = nq(10, 6)
    duelas = [jit(MADERA, 0.1), jit(MADERA_CLARA, 0.08)]
    tubo(M, b, b + V(0, h * 0.5, 0), r * 0.92, r, lados, duelas, tapa_a=False, tapa_b=False, plano=True)
    tubo(M, b + V(0, h * 0.5, 0), b + V(0, h, 0), r, r * 0.92, lados, duelas, tapa_a=False, tapa_b=False, plano=True)
    for t in (0.18, 0.82):
        tubo(M, b + V(0, h * t - 0.025, 0), b + V(0, h * t + 0.025, 0), r * (0.97 if t < 0.5 else 0.97) + 0.012,
             r * 0.97 + 0.012, lados, HIERRO, tapa_a=False, tapa_b=False)
    pts = [b + V(math.cos(2 * math.pi * k / lados) * r * 0.9, h - 0.03, math.sin(2 * math.pi * k / lados) * r * 0.9)
           for k in range(lados)]
    cara(M, pts, (0.10, 0.17, 0.26) if agua else tapa, (0, 1, 0))


def cajon(M, base, tam, c=MADERA_CLARA, contenido=None, semilla=0):
    """Cajón de madera; «contenido»: color del montón de género que asoma (manzanas, coles, calabazas, pan)."""
    b = V(base)
    sx, sy, sz = tam
    caja(M, (b.x - sx / 2, b.y, b.z - sz / 2), (b.x + sx / 2, b.y + sy, b.z + sz / 2), c)
    caja(M, (b.x - sx / 2 - 0.01, b.y + sy * 0.45, b.z + sz / 2), (b.x + sx / 2 + 0.01, b.y + sy * 0.55, b.z + sz / 2 + 0.01),
         mezcla(c, (0, 0, 0), 0.3), caras="s")
    if contenido:
        bulto(M, (b.x, b.y + sy * 0.95, b.z), min(sx, sz) * 0.5, (sx / min(sx, sz) * 0.95, 0.45, sz / min(sx, sz) * 0.95),
              1, 0.35, lambda d, q, cc=contenido: jit(cc, 0.12) if d.y > -0.3 else mezcla(cc, (0, 0, 0), 0.4), semilla)


def emblema_yunque(M, origen, U, N, s=1.0, c=HIERRO):
    pts = [(-0.40, 0.11), (-0.30, 0.15), (-0.16, 0.17), (0.30, 0.17), (0.30, 0.05), (0.16, 0.03), (0.10, -0.07),
           (0.22, -0.16), (-0.20, -0.16), (-0.08, -0.07), (-0.13, 0.03), (-0.24, 0.05)]
    poligono(M, [(x * s, y * s) for x, y in pts], origen, U, V(0, 1, 0), c, N)


def emblema_escudo(M, origen, U, N, s=1.0):
    Y = V(0, 1, 0)
    def forma(k):
        pts = [(-0.21, 0.22), (0.21, 0.22), (0.21, 0.02)]
        for i in range(1, 6):
            a = i / 6
            pts.append((0.21 * math.cos(a * math.pi / 2), 0.02 - 0.26 * math.sin(a * math.pi / 2)))
        pts.append((0.0, -0.25))
        for i in range(5, 0, -1):
            a = i / 6
            pts.append((-0.21 * math.cos(a * math.pi / 2), 0.02 - 0.26 * math.sin(a * math.pi / 2)))
        pts.append((-0.21, 0.02))
        return [(x * s * k, y * s * k) for x, y in pts]
    o = V(origen)
    poligono(M, forma(1.14), o, U, Y, ORO, N)                                 # el reborde dorado
    poligono(M, forma(1.0), o + V(N) * 0.008, U, Y, AZUL, N)
    galon = [(-0.21, -0.02), (0.0, 0.12), (0.21, -0.02), (0.21, 0.07), (0.0, 0.21), (-0.21, 0.07)]
    poligono(M, [(x * s, y * s) for x, y in galon], o + V(N) * 0.016, U, Y, ACERO_CLARO, N)


def emblema_mortero(M, origen, U, N, s=1.0):
    Y = V(0, 1, 0)
    o = V(origen)
    cuenco = [(-0.24, 0.04), (0.24, 0.04)]
    for i in range(1, 8):
        a = math.pi * i / 8
        cuenco.append((0.24 * math.cos(a) * 1.0, 0.04 - 0.2 * math.sin(a)))
    cuenco = cuenco[:2] + list(reversed(cuenco[2:]))
    cuenco = [(-0.24, 0.04), (0.24, 0.04)] + [(0.24 * math.cos(math.pi * i / 8), 0.04 - 0.2 * math.sin(math.pi * i / 8)) for i in range(1, 8)]
    poligono(M, [(x * s, y * s) for x, y in cuenco], o, U, Y, (0.22, 0.40, 0.30), N)
    pie = [(-0.12, -0.15), (0.12, -0.15), (0.16, -0.21), (-0.16, -0.21)]
    poligono(M, [(x * s, y * s) for x, y in pie], o, U, Y, (0.22, 0.40, 0.30), N)
    mano = [(0.02, 0.0), (0.08, 0.02), (0.28, 0.24), (0.24, 0.28)]
    poligono(M, [(x * s, y * s) for x, y in mano], o + V(N) * 0.008, U, Y, MADERA_OSC, N)
    for (cx, cy, ang) in ((-0.15, 0.13, 0.9), (-0.05, 0.17, 0.3)):            # dos hojas de hierba
        hoja = []
        for i in range(8):
            a = 2 * math.pi * i / 8
            x, y = 0.09 * math.cos(a), 0.035 * math.sin(a)
            hoja.append((cx + x * math.cos(ang) - y * math.sin(ang), cy + x * math.sin(ang) + y * math.cos(ang)))
        poligono(M, [(x * s, y * s) for x, y in hoja], o + V(N) * 0.008, U, Y, (0.36, 0.62, 0.30), N)


def cartel(M, centro, ancho, alto, U, hacia, emblema, cadenas=0.0):
    """Tablero de comercio: la cara iluminada (brillo) con su emblema oscuro encima, marco de madera y, si cuelga, las
    cadenas. Se lee de lejos: silueta oscura sobre fondo claro."""
    o, U, N = V(centro), V(U).normalized(), V(hacia).normalized()
    Y = V(0, 1, 0)
    caja_t(M, o - N * 0.02, (ancho + 0.1, alto + 0.1, 0.05), U, Y, MADERA_OSC)
    hx, hy = U * ancho * 0.5, Y * alto * 0.5
    p = o + N * 0.008
    cara(M, [p - hx - hy, p + hx - hy, p + hx + hy, p - hx + hy], LUZ_CARTEL, N, BRILLO)
    emblema(M, o + N * 0.016, U, N, min(ancho / 0.9, alto / 0.6) * 1.0)
    if cadenas > 0:
        for s in (-1, 1):
            caja_t(M, o + hx * 0.8 * s + Y * (alto * 0.5 + 0.05 + cadenas * 0.5), (0.025, cadenas, 0.025), U, Y, HIERRO)


def hiedra(M, origen, U, ancho, alto, hacia, n):
    """Mancha de hiedra pegada a un muro: hojas sueltas (rombos) sobre él."""
    o, U, N = V(origen), V(U).normalized(), V(hacia).normalized()
    Y = V(0, 1, 0)
    for k in range(nq(n, 4)):
        u = RND.uniform(0, ancho)
        v = alto * (1 - RND.random() ** 1.6)
        c = o + U * u + Y * v + N * RND.uniform(0.02, 0.06)
        s = RND.uniform(0.09, 0.15)
        a = RND.uniform(0, math.tau)
        d1 = (U * math.cos(a) + Y * math.sin(a)) * s
        d2 = (U * -math.sin(a) + Y * math.cos(a)) * s * 0.6
        cara(M, [c - d1, c - d2, c + d1, c + d2], jit(elige(HOJA), 0.12), N)


# ================================================================= LA HERRERÍA (Maese Ferro)
# Un taller de piedra al fondo (x 43,6-48,2; z 31,2-33,3) con tejado de una vertiente y, al aire libre delante, la fragua
# con su chimenea, el fuelle, el yunque y la tina de templar. Ferro trabaja junto al yunque, de cara a la plaza.

FERRO = (46.70, 0.0, 33.95)
YUNQUE = (46.40, 0.0, 34.62)
PUNTO_FORJA = (46.40, 0.0, 35.30)


def herreria(E, B):
    # el taller
    x0, x1, z0, z1 = 43.6, 48.2, 31.2, 33.3
    caja(E, (x0, 0, z0), (x1, 0.12, z1 + 0.15), PIEDRA[0], caras="seoa")
    muro_bloques(E, (x0, 0, z1), (1, 0, 0), x1 - x0, 2.75, (0, 0, 1), PIEDRA)            # fachada al sur, de sillares
    caja(E, (x0, 0, z0), (x1, 2.75, z1), PIEDRA[1], caras="neo")
    muro_bloques(E, (x1, 0, z1), (0, 0, -1), z1 - z0, 2.75, (1, 0, 0), PIEDRA, bloque=(0.5, 0.3))
    # tejado de una vertiente (alto detrás) y el hastial de tablas del lado este
    tejado(E, (x0 - 0.2, 3.55, z0 - 0.25), (x1 + 0.25, 3.55, z0 - 0.25), (x0 - 0.2, 2.72, z1 + 0.35),
           (x1 + 0.25, 2.72, z1 + 0.35), TEJA, 8, 9)
    poligono(E, [(z0, 2.75), (z1, 2.75), (z0, 3.5)], (x1 + 0.001, 0, 0), (0, 0, 1), (0, 1, 0), MADERA, (1, 0, 0))
    puerta(E, (44.55, 0.12, z1 + 0.012), 0.95, 2.05, (1, 0, 0), (0, 0, 1), MADERA_OSC, 5)
    ventana(E, (47.55, 1.55, z1 + 0.012), 0.7, 0.62, (1, 0, 0), (0, 0, 1), contraventanas=(0.24, 0.36, 0.30))
    # herramientas colgadas en la fachada (bajo el alero corto: se ven)
    caja(E, (45.25, 1.92, z1), (47.05, 2.02, z1 + 0.06), MADERA_OSC)
    for k, x in enumerate((45.45, 45.8, 46.15, 46.5, 46.85)):
        if k % 2 == 0:                                       # martillo: mango y cabeza
            caja(E, (x - 0.02, 1.35, z1 + 0.02), (x + 0.02, 1.92, z1 + 0.06), MADERA_CLARA, caras="seoa")
            caja(E, (x - 0.08, 1.3, z1 + 0.02), (x + 0.08, 1.4, z1 + 0.08), HIERRO, caras="seoa")
        else:                                                # tenazas
            caja_t(E, (x - 0.03, 1.6, z1 + 0.045), (0.025, 0.6, 0.025), (math.cos(0.12), math.sin(0.12), 0), (0, 0, 1), HIERRO)
            caja_t(E, (x + 0.03, 1.6, z1 + 0.045), (0.025, 0.6, 0.025), (math.cos(-0.12), math.sin(-0.12), 0), (0, 0, 1), HIERRO)
    E.caja_choque(x0, z0, x1, z1 + 0.15, 3.0)

    # la fragua, al aire libre: el hogar de piedra con las brasas a la vista y su chimenea detrás
    fx0, fx1, fz0, fz1 = 42.15, 44.0, 32.1, 34.15
    caja(E, (fx0, 0, fz0), (fx1, 0.92, fz1), PIEDRA[1], caras="neoa" if False else "neo")
    muro_bloques(E, (fx0, 0, fz1), (1, 0, 0), fx1 - fx0, 0.92, (0, 0, 1), PIEDRA, bloque=(0.4, 0.23))
    # el canto de arriba (un reborde de losas) y el lecho de brasas
    for (a, b) in [((fx0, fz0), (fx1, fz0 + 0.28)), ((fx0, fz1 - 0.28), (fx1, fz1)), ((fx0, fz0), (fx0 + 0.28, fz1)),
                   ((fx1 - 0.28, fz0), (fx1, fz1))]:
        caja(E, (a[0] - 0.02, 0.92, a[1] - 0.02), (b[0] + 0.02, 1.02, b[1] + 0.02), PIEDRA[2])
    for k in range(nq(9, 4)):                                # brasas: montoncitos de luz, del rojo al amarillo
        cx = RND.uniform(fx0 + 0.45, fx1 - 0.45)
        cz = RND.uniform(fz0 + 0.55, fz1 - 0.4)
        bulto(E, (cx, 0.95, cz), RND.uniform(0.16, 0.24), (1.3, 0.45, 1.2), 1, 0.3,
              lambda d, q: BRASA[2] if d.y > 0.5 else (BRASA[1] if d.y > 0.0 else BRASA[0]), k, 0.9, BRILLO)
    caja(E, (fx0 + 0.3, 0.92, fz0 + 0.3), (fx1 - 0.3, 0.94, fz1 - 0.3), BRASA[0], BRILLO, caras="a", jitter=0)
    # boca del cenicero, en el frente
    poligono(E, [(-0.32, 0.05), (0.32, 0.05), (0.32, 0.38)] + [(0.32 * math.cos(math.pi * i / 6), 0.38 + 0.18 * math.sin(math.pi * i / 6)) for i in range(1, 6)] + [(-0.32, 0.38)],
             ((fx0 + fx1) * 0.5, 0, fz1 + 0.016), (1, 0, 0), (0, 1, 0), (0.55, 0.16, 0.06), (0, 0, 1), BRILLO)
    # la campana sobre la mitad de atrás del hogar, y la chimenea
    cx0, cx1, cz0, cz1 = 42.55, 43.65, 31.45, 32.45
    h0, h1 = 1.85, 2.75
    base = [(fx0 + 0.05, h0, fz0 - 0.05), (fx1 - 0.05, h0, fz0 - 0.05), (fx1 - 0.05, h0, 33.25), (fx0 + 0.05, h0, 33.25)]
    cima = [(cx0, h1, cz0), (cx1, h1, cz0), (cx1, h1, cz1), (cx0, h1, cz1)]
    for i in range(4):
        j = (i + 1) % 4
        q = [base[i], base[j], cima[j], cima[i]]
        centro = sum((V(p) for p in q), Vector()) / 4 - V((fx0 + fx1) * 0.5, 2.3, 32.6)
        hollin = (0.24, 0.22, 0.22)                                  # la campana, tiznada de hollín abajo
        cara(E, q, [hollin, hollin, PIEDRA_FRIA[1], PIEDRA_FRIA[1]], centro)
    caja(E, (fx0, h0 - 0.12, 33.15), (fx1, h0, 33.35), PIEDRA[2])                        # el reborde de la campana
    caja(E, (cx0, 0.9, cz0), (cx1, 5.7, cz1), PIEDRA[1], caras="neo")
    muro_bloques(E, (cx0, h1, cz1), (1, 0, 0), cx1 - cx0, 5.7 - h1, (0, 0, 1), PIEDRA, bloque=(0.36, 0.24))
    muro_bloques(E, (cx0, 0.0, cz0), (0, 0, 1), cz1 - cz0, 5.7, (-1, 0, 0), PIEDRA, bloque=(0.36, 0.24))
    caja(E, (cx0 - 0.12, 5.7, cz0 - 0.12), (cx1 + 0.12, 5.86, cz1 + 0.12), PIEDRA[2])
    cara(E, [(cx0 + 0.15, 5.87, cz0 + 0.15), (cx1 - 0.15, 5.87, cz0 + 0.15), (cx1 - 0.15, 5.87, cz1 - 0.15),
             (cx0 + 0.15, 5.87, cz1 - 0.15)], (0.06, 0.05, 0.05), (0, 1, 0))
    ancla("humo", ((cx0 + cx1) * 0.5, 6.0, (cz0 + cz1) * 0.5))
    ancla("fragua", ((fx0 + fx1) * 0.5, 1.0, (fz0 + fz1) * 0.5 + 0.25))
    E.caja_choque(fx0, fz0 - 0.7, fx1, fz1, 1.2)
    # el cartel: cuelga de un brazo de hierro que sale de la chimenea, encima del fuego (ningún alero lo tapa)
    caja(E, (43.0, 3.42, cz1), (43.12, 3.5, 33.55), HIERRO, caras="seoa")
    caja_t(E, (43.06, 3.25, cz1 + 0.35), (0.04, 0.5, 0.04), (0, 0.6, 0.8), (1, 0, 0), HIERRO)
    cartel(E, (43.06, 2.82, 33.42), 1.0, 0.66, (1, 0, 0), (0, 0, 1), emblema_yunque, cadenas=0.14)

    # el fuelle, al lado de la fragua (de cuero, entre dos tablas), con su palanca
    caja(B, (44.05, 0.0, 32.55), (44.15, 0.55, 32.65), MADERA_OSC, caras="seoa")
    caja(B, (44.85, 0.0, 32.55), (44.95, 0.55, 32.65), MADERA_OSC, caras="seoa")
    caja(B, (44.05, 0.0, 33.25), (44.15, 0.55, 33.35), MADERA_OSC, caras="seoa")
    caja(B, (44.85, 0.0, 33.25), (44.95, 0.55, 33.35), MADERA_OSC, caras="seoa")
    caja_t(B, (44.5, 0.6, 32.95), (0.95, 0.05, 0.62), (1, -0.1, 0), (0, 0, 1), MADERA)
    caja_t(B, (44.5, 0.92, 32.95), (0.95, 0.05, 0.62), (1, 0.18, 0), (0, 0, 1), MADERA)
    bulto(B, (44.55, 0.76, 32.95), 0.3, (1.45, 0.42, 1.0), 1, 0.12, CUERO, 3)
    caja_t(B, (44.75, 1.35, 32.95), (0.05, 0.9, 0.05), (1, 0, 0), (0.3, 1, 0), MADERA_OSC)
    B.caja_choque(44.0, 32.5, 45.0, 33.4, 1.0)

    # el yunque sobre su tocón, y la tina de templar
    yx, yz = YUNQUE[0], YUNQUE[2]
    tubo(B, (yx, 0, yz), (yx, 0.5, yz), 0.3, 0.27, nq(10, 6), [jit(MADERA, 0.08), jit(MADERA_OSC, 0.08)], tapa_a=False,
         tapa_b=False, plano=True)
    cara(B, [(yx + math.cos(a) * 0.27, 0.5, yz + math.sin(a) * 0.27) for a in [2 * math.pi * k / 10 for k in range(10)]],
         MADERA_CLARA, (0, 1, 0))
    caja(B, (yx - 0.2, 0.5, yz - 0.15), (yx + 0.2, 0.62, yz + 0.15), HIERRO)
    caja(B, (yx - 0.1, 0.62, yz - 0.09), (yx + 0.12, 0.76, yz + 0.09), HIERRO)
    caja(B, (yx - 0.22, 0.76, yz - 0.12), (yx + 0.34, 0.92, yz + 0.12), HIERRO, caras="nseo")
    caja(B, (yx - 0.22, 0.92, yz - 0.12), (yx + 0.34, 0.93, yz + 0.12), (0.62, 0.62, 0.66), caras="a")
    tubo(B, (yx - 0.22, 0.85, yz), (yx - 0.52, 0.88, yz), 0.075, 0.01, nq(8, 5), HIERRO, tapa_b=False)
    ancla("yunque", (yx + 0.05, 0.94, yz))
    B.caja_choque(yx - 0.35, yz - 0.3, yx + 0.4, yz + 0.3, 1.0)
    barril(B, (47.55, 0, 34.55), 0.3, 0.7, agua=True)
    B.caja_choque(47.25, 34.25, 47.85, 34.85, 0.8)
    # carbón y unas barras de hierro apoyadas en el taller
    bulto(B, (45.25, 0.0, 33.75), 0.42, (1.2, 0.5, 0.9), 1, 0.3, lambda d, q: (0.10, 0.09, 0.10) if d.y > 0 else (0.16, 0.14, 0.14), 5, 0.0)
    if Q >= 0.7:
        for k in range(4):
            caja_t(B, (47.9 + 0.07 * k, 0.65, 33.45), (0.04, 1.3, 0.04), (1, 0, 0), (0.06 * k - 0.1, 1, 0.35), HIERRO)
    # un expositor de espadas (en forma de A) junto al taller: la herrería también vende
    ex, ez = 48.0, 34.1
    for s in (-1, 1):
        caja_t(B, (ex + 0.0, 0.55, ez + 0.18 * s), (0.06, 1.15, 0.06), (1, 0, 0), (0, 1, -0.22 * s), MADERA)
    caja(B, (ex - 0.03, 0.7, ez - 0.2), (ex + 0.03, 0.76, ez + 0.2), MADERA_OSC)
    for k, dz in enumerate((-0.12, 0.0, 0.12)):
        h = 0.95 - 0.05 * k
        caja(B, (ex - 0.02 + 0.02 * k - 0.1, 0.05, ez + dz - 0.015), (ex + 0.02 + 0.02 * k - 0.1, h, ez + dz + 0.015), ACERO_CLARO)
        caja(B, (ex - 0.13 + 0.02 * k - 0.1, h, ez + dz - 0.02), (ex + 0.13 + 0.02 * k - 0.1, h + 0.04, ez + dz + 0.02), ORO)
        caja(B, (ex - 0.025 + 0.02 * k - 0.1, h + 0.04, ez + dz - 0.025), (ex + 0.025 + 0.02 * k - 0.1, h + 0.2, ez + dz + 0.025), CUERO)
    B.caja_choque(ex - 0.35, ez - 0.3, ex + 0.25, ez + 0.3, 1.2)


# ================================================================= EL TALLER DE ARMADURAS (Hilda)
# Un taller de entramado (x 48,6-54,4; z 32-33,4) con tejado de pizarra a dos aguas, escudos colgados en la fachada,
# el mostrador delante y, a la derecha, el maniquí con la armadura completa.

HILDA = (50.55, 0.0, 34.0)
PUNTO_ARMADURAS = (50.55, 0.0, 35.35)


def entramado(M, origen, U, largo, alto, hacia, revoque=REVOQUE, postes=None, travesanos=(), cruces=()):
    """Muro de entramado: revoque y vigas oscuras encima (postes en u, travesaños en v, cruces de San Andrés)."""
    o, U, N = V(origen), V(U).normalized(), V(hacia).normalized()
    Y = V(0, 1, 0)
    cara(M, [o, o + U * largo, o + U * largo + Y * alto, o + Y * alto], jit(revoque, 0.03), N)
    p = o + N * 0.035
    for u in (postes if postes is not None else (0.0, largo)):
        caja_t(M, p + U * u + Y * alto * 0.5, (0.16, alto, 0.07), U, Y, MADERA_OSC, jitter=0.08)
    for v in travesanos:
        caja_t(M, p + U * largo * 0.5 + Y * v, (largo, 0.14, 0.07), U, Y, MADERA_OSC, jitter=0.08)
    for (u0, v0, u1, v1) in cruces:
        a, b = p + U * u0 + Y * v0, p + U * u1 + Y * v1
        caja_t(M, (a + b) * 0.5, ((b - a).length, 0.12, 0.06), b - a, N.cross(b - a), MADERA_OSC, jitter=0.08)


def armeria(E, B):
    x0, x1, z0, z1 = 48.6, 54.4, 32.0, 33.4
    caja(E, (x0, 0, z0), (x1, 0.12, z1 + 0.12), PIEDRA[0], caras="seoa")
    caja(E, (x0, 0, z0), (x1, 2.9, z1), REVOQUE, caras="neo")
    muro_bloques(E, (x0, 0.0, z1), (1, 0, 0), x1 - x0, 0.5, (0, 0, 1), PIEDRA_FRIA, bloque=(0.42, 0.25))
    entramado(E, (x0, 0.5, z1), (1, 0, 0), x1 - x0, 2.4, (0, 0, 1), postes=(0.08, 1.55, 3.3, 4.6, x1 - x0 - 0.08),
              travesanos=(0.07, 1.5, 2.33), cruces=((3.3, 0.1, 4.6, 1.45), (4.6, 0.1, 3.3, 1.45)) if Q >= 0.7 else ())
    entramado(E, (x1, 0.0, z1), (0, 0, -1), z1 - z0, 2.9, (1, 0, 0), postes=(0.08, z1 - z0 - 0.08), travesanos=(1.0, 2.82))
    # tejado de pizarra a dos aguas (cumbrera este-oeste) con sus hastiales
    rz, ry, ey = 32.7, 4.45, 2.88
    tejado(E, (x0 - 0.3, ry, rz), (x1 + 0.3, ry, rz), (x0 - 0.3, ey, z1 + 0.3), (x1 + 0.3, ey, z1 + 0.3), PIZARRA, 6, 10)
    tejado(E, (x1 + 0.3, ry, rz), (x0 - 0.3, ry, rz), (x1 + 0.3, ey, z0 - 0.3), (x0 - 0.3, ey, z0 - 0.3), PIZARRA, 5, 8, labio=False)
    caja(E, (x0 - 0.35, ry - 0.02, rz - 0.1), (x1 + 0.35, ry + 0.14, rz + 0.1), MADERA_OSC)
    for (x, n) in ((x1 + 0.002, (1, 0, 0)), (x0 - 0.002, (-1, 0, 0))):
        poligono(E, [(z0, 2.9), (z1, 2.9), (rz, ry - 0.05)], (x, 0, 0), (0, 0, 1), (0, 1, 0), REVOQUE, n)
    # chimenea pequeña
    caja(E, (53.3, 3.4, 32.35), (53.75, 5.0, 32.8), PIEDRA[1])
    caja(E, (53.24, 5.0, 32.29), (53.81, 5.1, 32.86), PIEDRA[2])
    puerta(E, (49.25, 0.12, z1 + 0.012), 0.9, 2.0, (1, 0, 0), (0, 0, 1), (0.36, 0.26, 0.20), 5)
    ventana(E, (53.55, 1.65, z1 + 0.012), 0.68, 0.6, (1, 0, 0), (0, 0, 1), contraventanas=AZUL, macetero=True)
    # el cartel, en la fachada, sobre el mostrador (el alero es corto: se ve entero)
    cartel(E, (51.35, 2.16, z1 + 0.04), 0.95, 0.56, (1, 0, 0), (0, 0, 1), emblema_escudo)
    # escudos colgados en la fachada: redondo con umbo, rojo con banda dorada y azul con galón
    zf = z1 + 0.05
    lados = nq(12, 8)
    disco = [(51.9 + 0.3 * math.cos(2 * math.pi * k / lados), 1.45 + 0.3 * math.sin(2 * math.pi * k / lados), zf) for k in range(lados)]
    cara(E, disco, jit(MADERA_CLARA, 0.04), (0, 0, 1))
    tubo(E, (51.9, 1.45, zf), (51.9, 1.45, zf + 0.04), 0.31, 0.31, lados, HIERRO, tapa_a=False, tapa_b=False)
    bulto(E, (51.9, 1.45, zf + 0.02), 0.09, (1, 1, 0.6), 1, 0.0, ACERO, 1)
    for (cx, cy, campo, banda) in ((50.35, 1.55, ROJO, ORO), (52.75, 1.55, AZUL, ACERO_CLARO)):
        emblema = [(-0.2, 0.24), (0.2, 0.24), (0.2, 0.0)] + [(0.2 * math.cos(math.pi / 2 * i / 4), -0.28 * math.sin(math.pi / 2 * i / 4)) for i in range(1, 4)] + [(0, -0.3)] + \
                  [(-0.2 * math.cos(math.pi / 2 * i / 4), -0.28 * math.sin(math.pi / 2 * i / 4)) for i in range(3, 0, -1)] + [(-0.2, 0.0)]
        poligono(E, [(x * 1.12, y * 1.1) for x, y in emblema], (cx, cy, zf), (1, 0, 0), (0, 1, 0), MADERA_OSC, (0, 0, 1))
        poligono(E, emblema, (cx, cy, zf + 0.012), (1, 0, 0), (0, 1, 0), campo, (0, 0, 1))
        poligono(E, [(-0.2, 0.02), (0.2, 0.1), (0.2, 0.18), (-0.2, 0.1)], (cx, cy, zf + 0.02), (1, 0, 0), (0, 1, 0), banda, (0, 0, 1))
    # lanzas cruzadas entre la puerta y los escudos
    for s in (-1, 1):
        caja_t(E, (49.95, 1.6, zf + 0.03), (0.035, 1.6, 0.035), (1, 0, 0), (0.35 * s, 1, 0), MADERA)
        caja_t(E, (49.95 + 0.27 * s, 2.36, zf + 0.03), (0.07, 0.2, 0.03), (1, 0, 0), (0.35 * s, 1, 0), ACERO_CLARO)
    E.caja_choque(x0, z0, x1, z1 + 0.12, 3.2)

    # el mostrador
    mx0, mx1, mz0, mz1 = 49.25, 51.85, 34.5, 34.95
    caja(B, (mx0, 0, mz0), (mx1, 0.92, mz1), MADERA, caras="neo")
    tablas(B, (mx0, 0, mz1), (1, 0, 0), mx1 - mx0, 0.92, (0, 0, 1), MADERA, nq(6, 3))
    caja(B, (mx0 - 0.05, 0.92, mz0 - 0.04), (mx1 + 0.05, 1.0, mz1 + 0.05), MADERA_CLARA)
    bulto(B, (50.0, 1.08, 34.72), 0.14, (1, 0.75, 1), 1, 0.05, ACERO, 2)                   # un yelmo
    caja(B, (49.98, 1.0, 34.84), (50.02, 1.14, 34.86), ACERO, caras="seoa")
    caja(B, (51.1, 1.0, 34.6), (51.5, 1.06, 34.85), (0.36, 0.34, 0.36))                   # la piedra de afilar
    caja_t(B, (50.9, 1.04, 34.78), (0.32, 0.03, 0.03), (1, 0, 0.3), (0, 1, 0), MADERA_OSC)
    B.caja_choque(mx0, mz0, mx1, mz1, 1.0)
    # el maniquí con la armadura completa, sobre su tarima
    mx, mz = 53.3, 34.15
    caja(B, (mx - 0.45, 0, mz - 0.45), (mx + 0.45, 0.14, mz + 0.45), MADERA)
    tubo(B, (mx, 0.14, mz), (mx, 0.95, mz), 0.04, 0.04, 6, MADERA_OSC, tapa_a=False)
    for s in (-1, 1):                                            # grebas
        tubo(B, (mx + 0.11 * s, 0.14, mz), (mx + 0.11 * s, 0.62, mz), 0.08, 0.075, nq(8, 6), ACERO, tapa_a=False)
    tubo(B, (mx, 0.62, mz), (mx, 0.95, mz), 0.2, 0.17, nq(10, 6), ACERO)                    # faldar
    tubo(B, (mx, 0.95, mz), (mx, 1.45, mz), 0.21, 0.27, nq(10, 6), ACERO_CLARO, tapa_a=False)  # peto
    caja(B, (mx - 0.04, 1.0, mz + 0.2), (mx + 0.04, 1.42, mz + 0.27), ORO, caras="seoa")
    for s in (-1, 1):                                            # hombreras
        bulto(B, (mx + 0.3 * s, 1.43, mz), 0.15, (1.0, 0.75, 1.0), 1, 0.05, ACERO, 4 + s, mx - 0.1)
    bulto(B, (mx, 1.66, mz), 0.15, (1, 1.05, 1), 1, 0.04, ACERO, 6)                       # yelmo
    caja(B, (mx - 0.11, 1.62, mz + 0.12), (mx + 0.11, 1.65, mz + 0.16), (0.05, 0.05, 0.06), caras="sa")
    caja(B, (mx - 0.015, 1.72, mz - 0.18), (mx + 0.015, 1.92, mz + 0.06), ROJO)            # penacho
    B.caja_choque(mx - 0.45, mz - 0.45, mx + 0.45, mz + 0.45, 1.9)
    # un caballete con una cota de malla
    if Q >= 0.7:
        caja(B, (52.2, 0, 33.75), (52.26, 1.3, 33.81), MADERA_OSC, caras="seoa")
        caja(B, (52.0, 1.25, 33.75), (52.46, 1.31, 33.81), MADERA_OSC)
        caja(B, (52.03, 0.65, 33.73), (52.43, 1.25, 33.83), (0.46, 0.48, 0.52))


# ================================================================= LOS PUESTOS (dos tenderetes con toldo de rayas)

def puesto(B, x0, x1, z0, z1, rayas, genero, semilla):
    RND.seed(semilla)
    hb, hf = 2.35, 2.05                                          # el toldo baja hacia la plaza
    for (x, z, h) in ((x0, z0, hb), (x1, z0, hb), (x0, z1, hf), (x1, z1, hf)):
        caja(B, (x - 0.05, 0, z - 0.05), (x + 0.05, h, z + 0.05), MADERA_OSC, caras="seoa")
    n = nq(8, 4)
    for i in range(n):                                           # el toldo: franjas de dos colores
        a, b = x0 - 0.15 + (x1 - x0 + 0.3) * i / n, x0 - 0.15 + (x1 - x0 + 0.3) * (i + 1) / n
        c = jit(rayas[i % 2], 0.04)
        cara(B, [(a, hb + 0.05, z0 - 0.2), (b, hb + 0.05, z0 - 0.2), (b, hf + 0.05, z1 + 0.25), (a, hf + 0.05, z1 + 0.25)], c, (0, 1, 0.3))
        cara(B, [(a, hf + 0.05, z1 + 0.25), (b, hf + 0.05, z1 + 0.25), ((a + b) * 0.5, hf - 0.18, z1 + 0.27)], c, (0, 0.2, 1))
    # la mesa, el género delante (lo que el toldo no tapa) y cajones en el suelo
    caja(B, (x0 + 0.05, 0.0, z1 - 0.75), (x1 - 0.05, 0.82, z1 - 0.05), MADERA, caras="nseo")
    tablas(B, (x0 + 0.05, 0.0, z1 - 0.05), (1, 0, 0), x1 - x0 - 0.1, 0.8, (0, 0, 1), MADERA, nq(5, 3))
    caja(B, (x0, 0.82, z1 - 0.8), (x1, 0.88, z1), MADERA_CLARA)
    k = 0
    for i, g in enumerate(genero):
        cx = x0 + 0.35 + (x1 - x0 - 0.7) * i / max(1, len(genero) - 1)
        cajon(B, (cx, 0.88, z1 - 0.35), (0.5, 0.18, 0.42), MADERA_CLARA, g, semilla + i)
    if Q >= 0.7:
        for i, g in enumerate(genero[:2]):
            cajon(B, (x0 + 0.4 + i * 0.75, 0.0, z1 + 0.32), (0.55, 0.32, 0.45), MADERA, g, semilla + 10 + i)
    bulto(B, (x1 - 0.25, 0.0, z0 + 0.35), 0.3, (0.9, 1.15, 0.9), 1, 0.15, (0.72, 0.62, 0.44), semilla + 20, 0.0)   # saco
    B.caja_choque(x0 - 0.1, z0 - 0.1, x1 + 0.1, z1 + (0.6 if Q >= 0.7 else 0.05), 1.0)


def puestos(B):
    MANZANA, COL, CALABAZA, PAN, CEBOLLA = (0.78, 0.16, 0.14), (0.42, 0.62, 0.28), (0.90, 0.50, 0.14), (0.80, 0.58, 0.30), (0.86, 0.72, 0.52)
    puesto(B, 55.0, 57.25, 32.3, 34.55, (ROJO, CREMA), [MANZANA, PAN, CEBOLLA], 31)
    puesto(B, 57.65, 59.9, 32.3, 34.55, (VERDE, CREMA), [COL, CALABAZA, MANZANA], 41)
    if Q >= 0.7:                                                 # ristras de ajos y hierbas colgando del toldo
        for x in (55.5, 56.6, 58.2, 59.3):
            for k in range(3):
                bulto(B, (x + 0.08 * k, 1.85 - 0.1 * k, 34.62), 0.06, (1, 1.2, 1), 0, 0.1, (0.92, 0.88, 0.76), k)


# ================================================================= LAS CASAS (dos casas con su patio)

def casa_a(E, B):
    """Casa de hastial al sur: piedra abajo, entramado arriba con el piso volado, tejado rojo y chimenea."""
    x0, x1, z0, z1 = 60.45, 63.6, 28.8, 33.2
    cx = (x0 + x1) * 0.5
    caja(E, (x0, 0, z0), (x1, 2.6, z1), PIEDRA[1], caras="neo")
    muro_bloques(E, (x0, 0, z1), (1, 0, 0), x1 - x0, 2.6, (0, 0, 1), PIEDRA)
    muro_bloques(E, (x1, 0, z1), (0, 0, -1), z1 - z0, 2.6, (1, 0, 0), PIEDRA, bloque=(0.5, 0.3))
    v = 0.25                                                     # el piso de arriba, volado
    caja(E, (x0 - 0.05, 2.6, z0), (x1 + 0.05, 2.75, z1 + v), MADERA_OSC, caras="seo")
    caja(E, (x0, 2.75, z0), (x1, 5.0, z1 + v), REVOQUE_ROSA, caras="neo")
    entramado(E, (x0, 2.75, z1 + v), (1, 0, 0), x1 - x0, 2.25, (0, 0, 1), REVOQUE_ROSA, postes=(0.08, 1.05, 2.1, x1 - x0 - 0.08),
              travesanos=(0.07, 2.18))
    entramado(E, (x1, 2.75, z1 + v), (0, 0, -1), z1 + v - z0, 2.25, (1, 0, 0), REVOQUE_ROSA, travesanos=(0.07, 2.18))
    # hastial y tejado (cumbrera norte-sur: las dos aguas al este y al oeste)
    ry = 7.0
    poligono(E, [(-(x1 - x0) / 2 - 0.02, 5.0), ((x1 - x0) / 2 + 0.02, 5.0), (0, ry - 0.1)], (cx, 0, z1 + v + 0.001),
             (1, 0, 0), (0, 1, 0), REVOQUE_ROSA, (0, 0, 1))
    caja_t(E, (cx, 5.85, z1 + v + 0.04), (0.14, 1.75, 0.07), (1, 0, 0), (0, 1, 0), MADERA_OSC)
    for s in (-1, 1):
        a, b = V(cx + s * (x1 - x0) / 2, 5.0, z1 + v + 0.04), V(cx, ry - 0.1, z1 + v + 0.04)
        caja_t(E, (a + b) * 0.5, ((b - a).length, 0.14, 0.07), b - a, V(0, 0, 1).cross(b - a), MADERA_OSC)
    tejado(E, (cx, ry, z1 + v + 0.35), (cx, ry, z0 - 0.3), (x1 + 0.35, 4.85, z1 + v + 0.35), (x1 + 0.35, 4.85, z0 - 0.3), TEJA, 7, 7)
    tejado(E, (cx, ry, z0 - 0.3), (cx, ry, z1 + v + 0.35), (x0 - 0.35, 4.85, z0 - 0.3), (x0 - 0.35, 4.85, z1 + v + 0.35), TEJA, 7, 7)
    caja_t(E, (cx, ry + 0.05, (z0 + z1 + v) * 0.5), (0.18, 0.14, z1 + v - z0 + 0.7), (1, 0, 0), (0, 1, 0), MADERA_OSC)
    caja(E, (x1 - 0.85, 4.6, 29.6), (x1 - 0.35, 7.5, 30.1), PIEDRA[1])
    caja(E, (x1 - 0.9, 7.5, 29.55), (x1 - 0.3, 7.6, 30.15), PIEDRA[2])
    puerta(E, (cx - 0.45, 0.0, z1 + 0.012), 0.85, 1.95, (1, 0, 0), (0, 0, 1), (0.26, 0.40, 0.30), 4)
    caja(E, (cx - 1.0, 2.05, z1), (cx + 0.1, 2.12, z1 + 0.45), MADERA_OSC)               # tejadillo sobre la puerta
    ventana(E, (cx + 0.85, 1.45, z1 + 0.012), 0.6, 0.62, (1, 0, 0), (0, 0, 1), contraventanas=(0.26, 0.40, 0.30), macetero=True)
    for x in (cx - 0.75, cx + 0.75):
        ventana(E, (x, 3.85, z1 + v + 0.012), 0.6, 0.7, (1, 0, 0), (0, 0, 1), macetero=Q >= 1.0)
    ventana(E, (cx, 5.75, z1 + v + 0.012), 0.42, 0.5, (1, 0, 0), (0, 0, 1))
    E.caja_choque(x0, z0, x1, z1 + 0.05, 3.5)


def casa_b(E, B):
    """Casa estrecha de tejado de pizarra a dos aguas (aleros al sur), con su porche de tablas."""
    x0, x1, z0, z1 = 64.15, 66.85, 29.3, 33.2
    caja(E, (x0, 0, z0), (x1, 4.6, z1), REVOQUE, caras="neo")
    muro_bloques(E, (x0, 0, z1), (1, 0, 0), x1 - x0, 0.6, (0, 0, 1), PIEDRA_FRIA, bloque=(0.42, 0.25))
    entramado(E, (x0, 0.6, z1), (1, 0, 0), x1 - x0, 4.0, (0, 0, 1), postes=(0.08, 1.35, x1 - x0 - 0.08), travesanos=(0.07, 1.95, 3.95),
              cruces=((0.08, 2.05, 1.35, 3.9), (1.35, 2.05, x1 - x0 - 0.08, 3.9)) if Q >= 0.7 else ())
    entramado(E, (x1, 0.0, z1), (0, 0, -1), z1 - z0, 4.6, (1, 0, 0), postes=(0.08, z1 - z0 - 0.08), travesanos=(2.0, 4.55))
    rz, ry = (z0 + z1) * 0.5, 6.6
    tejado(E, (x0 - 0.3, ry, rz), (x1 + 0.3, ry, rz), (x0 - 0.3, 4.5, z1 + 0.35), (x1 + 0.3, 4.5, z1 + 0.35), PIZARRA, 7, 6)
    tejado(E, (x1 + 0.3, ry, rz), (x0 - 0.3, ry, rz), (x1 + 0.3, 4.5, z0 - 0.35), (x0 - 0.3, 4.5, z0 - 0.35), PIZARRA, 5, 5, labio=False)
    caja(E, (x0 - 0.35, ry - 0.02, rz - 0.1), (x1 + 0.35, ry + 0.14, rz + 0.1), MADERA_OSC)
    for (x, n) in ((x1 + 0.002, (1, 0, 0)), (x0 - 0.002, (-1, 0, 0))):
        poligono(E, [(z0, 4.6), (z1, 4.6), (rz, ry - 0.05)], (x, 0, 0), (0, 0, 1), (0, 1, 0), REVOQUE, n)
    # buhardilla en el tejado: una ventanita encendida que asoma
    caja(E, (65.05, 4.9, 32.05), (65.95, 5.85, 32.55), REVOQUE, caras="seo")
    ventana(E, (65.5, 5.35, 32.56), 0.42, 0.45, (1, 0, 0), (0, 0, 1))
    tejado(E, (65.5, 6.15, 32.0), (65.5, 6.15, 32.75), (64.95, 5.8, 32.0), (64.95, 5.8, 32.75), PIZARRA, 2, 2, labio=False)
    tejado(E, (65.5, 6.15, 32.75), (65.5, 6.15, 32.0), (66.05, 5.8, 32.75), (66.05, 5.8, 32.0), PIZARRA, 2, 2, labio=False)
    puerta(E, (65.85, 0.0, z1 + 0.012), 0.8, 1.95, (1, 0, 0), (0, 0, 1), (0.48, 0.24, 0.18), 4)
    ventana(E, (64.75, 1.5, z1 + 0.012), 0.55, 0.6, (1, 0, 0), (0, 0, 1), contraventanas=(0.62, 0.30, 0.22), macetero=True)
    for x in (64.75, 66.1):
        ventana(E, (x, 3.4, z1 + 0.012), 0.55, 0.65, (1, 0, 0), (0, 0, 1), contraventanas=(0.62, 0.30, 0.22))
    # porche: dos pies derechos y un tejadillo de tablas sobre la puerta
    for x in (65.3, 66.45):
        caja(E, (x - 0.05, 0, z1 + 0.9), (x + 0.05, 2.25, z1 + 1.0), MADERA_OSC, caras="seoa")
    tejado(E, (65.15, 2.6, z1), (66.6, 2.6, z1), (65.15, 2.25, z1 + 1.15), (66.6, 2.25, z1 + 1.15), ((0.42, 0.30, 0.20), (0.50, 0.36, 0.24), (0.58, 0.42, 0.28)), 3, 3, labio=False)
    farolillo(E, (64.9, 2.25, z1 + 0.18))
    E.caja_choque(x0, z0, x1, z1 + 0.05, 3.5)
    E.caja_choque(65.2, z1 + 0.85, 65.4, z1 + 1.05, 2.0)
    E.caja_choque(66.35, z1 + 0.85, 66.55, z1 + 1.05, 2.0)


def patios(B):
    """El murete de los dos patios (con su cancela abierta), un banco, macetas, un árbol joven y la ropa tendida."""
    zm = 35.25
    for (a, b) in ((60.3, 61.55), (62.45, 63.85), (64.05, 64.95), (65.85, 66.95)):
        caja(B, (a, 0, zm - 0.18), (b, 0.62, zm + 0.18), PIEDRA[1])
        caja(B, (a - 0.03, 0.62, zm - 0.21), (b + 0.03, 0.7, zm + 0.21), PIEDRA[2])
        B.caja_choque(a, zm - 0.18, b, zm + 0.18, 0.8)
    for (z0, z1) in ((33.25, 35.07),):                         # la valla entre los dos patios
        caja(B, (63.9, 0, z0), (64.0, 0.95, z1), MADERA, caras="seoa")
        B.caja_choque(63.85, z0, 64.05, z1, 1.0)
    for x in (61.55, 62.45):                                    # cancela abierta del patio A
        caja(B, (x - 0.06, 0, zm - 0.06), (x + 0.06, 0.9, zm + 0.06), MADERA_OSC)
    caja_t(B, (61.55 + 0.05, 0.45, zm - 0.42), (0.05, 0.7, 0.8), (1, 0, 0), (0, 1, 0), MADERA)
    # banco y macetas (patio A), árbol joven
    caja(B, (60.7, 0.42, 34.1), (61.9, 0.5, 34.45), MADERA_CLARA)
    for x in (60.8, 61.8):
        caja(B, (x - 0.05, 0, 34.12), (x + 0.05, 0.42, 34.43), MADERA_OSC, caras="seoa")
    for k, (x, z) in enumerate(((60.6, 33.55), (63.35, 33.6), (63.4, 34.85))):
        tubo(B, (x, 0, z), (x, 0.32, z), 0.15, 0.19, nq(8, 6), (0.66, 0.36, 0.24), tapa_a=False)
        bulto(B, (x, 0.42, z), 0.22, (1, 0.8, 1), 1, 0.3, lambda d, q, k=k: FLORES[k % 4] if d.y > 0.3 and (q.x * 7 + q.z * 5) % 1 > 0.5 else HOJA[1], k)
    tubo(B, (62.9, 0, 34.35), (62.95, 1.7, 34.3), 0.07, 0.05, nq(6, 5), MADERA)
    bulto(B, (62.9, 2.15, 34.3), 0.62, (1, 0.85, 1), 1, 0.25, lambda d, q: jit(HOJA[1] if d.y > -0.2 else HOJA[0], 0.1), 7)
    if Q >= 0.7:
        for k in range(5):                                       # manzanas en el árbol
            a = k * 1.3
            bulto(B, (62.9 + 0.5 * math.cos(a), 2.0 + 0.2 * math.sin(a * 2), 34.3 + 0.45 * math.sin(a)), 0.06, (1, 1, 1), 0, 0.0, (0.86, 0.22, 0.16), k)
    B.caja_choque(62.75, 34.15, 63.05, 34.45, 1.5)
    # patio B: ropa tendida entre dos postes, un barril de lluvia y leña apilada
    for x in (64.25, 66.75):
        caja(B, (x - 0.05, 0, 34.55), (x + 0.05, 1.95, 34.65), MADERA_OSC, caras="seoa")
        B.caja_choque(x - 0.08, 34.52, x + 0.08, 34.68, 2.0)
    caja(B, (64.25, 1.88, 34.59), (66.75, 1.9, 34.61), (0.78, 0.74, 0.66), caras="sa")
    ropa = [(0.92, 0.90, 0.84), (0.36, 0.48, 0.70), (0.80, 0.42, 0.40), (0.94, 0.86, 0.60)]
    for k in range(nq(4, 3)):
        a = 64.45 + 0.58 * k
        h = 0.55 + 0.15 * (k % 2)
        cara(B, [(a, 1.89 - h, 34.6), (a + 0.42, 1.89 - h, 34.6), (a + 0.42, 1.89, 34.6), (a, 1.89, 34.6)], ropa[k % 4], (0, 0, 1))
        cara(B, [(a, 1.89 - h, 34.6), (a + 0.42, 1.89 - h, 34.6), (a + 0.42, 1.89, 34.6), (a, 1.89, 34.6)], mezcla(ropa[k % 4], (0, 0, 0), 0.25), (0, 0, -1))
    barril(B, (64.45, 0, 33.65), 0.28, 0.65, agua=True)
    B.caja_choque(64.15, 33.35, 64.75, 33.95, 0.8)
    if Q >= 0.7:
        for k in range(6):
            tubo(B, (66.2, 0.12 + 0.18 * (k // 3), 33.45 + 0.17 * (k % 3) + 0.08 * (k // 3)),
                 (66.75, 0.12 + 0.18 * (k // 3), 33.45 + 0.17 * (k % 3) + 0.08 * (k // 3)), 0.08, 0.08, 6, MADERA_CLARA)
        B.caja_choque(66.15, 33.35, 66.8, 34.0, 0.5)


# ================================================================= LOS JARDINES DE LA FILA DE CASAS
# Al sur de la calle están las casas del relleno de la ciudad (ciudad.gd, tejados de 8 m). Sus jardines, cerrados, son la
# parte residencial del barrio: la valla, el seto o el murete a la calle, macizos de flores, huerto, un banco, ropa
# tendida. Son bajos (no tapan nada) y no se pisan: desde ahí, los tejados de esas casas taparían a Kael.

ZONA_JARDIN = 37.05            # la línea de las vallas (al norte, la calle; al sur, los jardines)


def valla(B, x0, x1, z, alto=0.78, c=(0.86, 0.82, 0.72)):
    """Valla de estacas encaladas con dos travesaños."""
    n = max(2, int((x1 - x0) / (0.36 / math.sqrt(Q))))
    for i in range(n + 1):
        x = x0 + (x1 - x0) * i / n
        h = alto * RND.uniform(0.94, 1.04)
        caja(B, (x - 0.035, 0, z - 0.025), (x + 0.035, h, z + 0.025), jit(c, 0.05), caras="seoa")
    for y in (0.24, 0.58):
        caja(B, (x0, y, z - 0.045), (x1, y + 0.06, z - 0.02), mezcla(c, (0, 0, 0), 0.12), caras="sa")


def seto(B, x0, x1, z, alto=0.72):
    """Seto recortado: un cuerpo verde y bultos de hojas por encima."""
    caja(B, (x0, 0, z - 0.28), (x1, alto - 0.1, z + 0.28), HOJA[0])
    n = max(2, int((x1 - x0) / 0.6 * Q))
    for i in range(n):
        x = x0 + (x1 - x0) * (i + 0.5) / n
        bulto(B, (x, alto - 0.12, z), 0.36, (1.0 / Q * 0.9 if Q < 1 else 0.95, 0.5, 0.85), 0 if Q < 1 else 1, 0.3,
              lambda d, q: jit(HOJA[1] if d.y > 0.2 else HOJA[0], 0.1), i, alto - 0.3)


def muro_bajo(B, x0, x1, z, alto=0.6):
    caja(B, (x0, 0, z - 0.17), (x1, alto, z + 0.17), PIEDRA[1], caras="neoa")
    muro_bloques(B, (x0, 0, z + 0.17), (1, 0, 0), x1 - x0, alto, (0, 0, 1), PIEDRA, bloque=(0.4, 0.22))
    caja(B, (x0 - 0.03, alto, z - 0.2), (x1 + 0.03, alto + 0.08, z + 0.2), PIEDRA[2])


def macizo(B, x0, x1, z0, z1, colores, semilla):
    """Macizo de flores: tierra y matas en flor."""
    caja(B, (x0, 0, z0), (x1, 0.07, z1), (0.30, 0.22, 0.15), caras="sa")
    rnd = random.Random(semilla)
    n = max(2, int((x1 - x0) * (z1 - z0) * 5 * Q))
    for i in range(n):
        x, z = rnd.uniform(x0 + 0.12, x1 - 0.12), rnd.uniform(z0 + 0.12, z1 - 0.12)
        cc = colores[i % len(colores)]
        bulto(B, (x, 0.12, z), rnd.uniform(0.12, 0.18), (1, 0.85, 1), 0, 0.3,
              lambda d, q, cc=cc: cc if d.y > 0.1 else HOJA[1], i)


def huerto(B, x0, x1, z0, z1, semilla):
    """Tres surcos con coles."""
    rnd = random.Random(semilla)
    filas = 3
    for f in range(filas):
        z = z0 + (z1 - z0) * (f + 0.5) / filas
        caja(B, (x0, 0, z - 0.14), (x1, 0.1, z + 0.14), (0.32, 0.23, 0.15), caras="sa")
        n = max(2, int((x1 - x0) / 0.4 * Q))
        for i in range(n):
            x = x0 + (x1 - x0) * (i + 0.5) / n
            bulto(B, (x, 0.14, z), 0.13, (1, 0.7, 1), 0, 0.25, lambda d, q: jit((0.40, 0.60, 0.28), 0.1), i + f * 7)


def banco(B, x0, x1, z, c=MADERA_CLARA):
    caja(B, (x0, 0.4, z - 0.17), (x1, 0.47, z + 0.17), c)
    for x in (x0 + 0.1, x1 - 0.1):
        caja(B, (x - 0.05, 0, z - 0.15), (x + 0.05, 0.4, z + 0.15), MADERA_OSC, caras="seoa")


def tendedero(B, x0, x1, z, colores):
    for x in (x0, x1):
        caja(B, (x - 0.04, 0, z - 0.04), (x + 0.04, 1.75, z + 0.04), MADERA_OSC, caras="seoa")
    caja(B, (x0, 1.69, z - 0.01), (x1, 1.71, z + 0.01), (0.78, 0.74, 0.66), caras="sa")
    n = max(2, int((x1 - x0) / 0.62))
    for k in range(n):
        a = x0 + 0.12 + (x1 - x0 - 0.2) * k / n
        h = 0.45 + 0.17 * (k % 2)
        c = colores[k % len(colores)]
        for (zz, cc, nn) in ((z + 0.005, c, (0, 0, 1)), (z - 0.005, mezcla(c, (0, 0, 0), 0.25), (0, 0, -1))):
            cara(B, [(a, 1.7 - h, zz), (a + 0.4, 1.7 - h, zz), (a + 0.4, 1.7, zz), (a, 1.7, zz)], cc, nn)


def jardines(B):
    z = ZONA_JARDIN
    # 1: la casa del oeste (casa_4x5, x 42-46): valla encalada, macizos y un banco
    valla(B, 41.95, 46.2, z)
    macizo(B, 42.2, 44.0, 37.5, 38.3, FLORES, 1)
    macizo(B, 44.5, 46.0, 38.6, 39.3, [FLORES[0], FLORES[2]], 2)
    banco(B, 42.4, 43.6, 39.15)
    # 2: casa_5x4 (x 50-55): murete de piedra, huerto y ropa tendida
    muro_bajo(B, 49.8, 55.2, z + 0.1)
    huerto(B, 50.2, 52.6, 37.6, 39.2, 3)
    tendedero(B, 53.0, 54.9, 38.5, [(0.92, 0.90, 0.84), (0.36, 0.48, 0.70), (0.80, 0.42, 0.40)])
    # 3: casa_6x4 (x 56-62): seto, macizos y una carretilla con leña
    seto(B, 55.8, 62.2, z + 0.1)
    macizo(B, 56.2, 58.4, 38.3, 39.25, [FLORES[1], FLORES[3], FLORES[0]], 4)
    macizo(B, 60.0, 61.9, 38.3, 39.25, [FLORES[2], FLORES[3]], 5)
    if Q >= 0.7:
        caja(B, (58.85, 0.25, 38.4), (59.65, 0.55, 38.95), MADERA)
        tubo(B, (59.75, 0.22, 38.4), (59.75, 0.22, 38.95), 0.2, 0.2, 8, MADERA_OSC)
        for k in range(4):
            tubo(B, (58.95, 0.6 + 0.1 * (k % 2), 38.48 + 0.12 * k), (59.55, 0.6 + 0.1 * (k % 2), 38.48 + 0.12 * k), 0.06, 0.06, 5, MADERA_CLARA)
    # 4: casa_4x4 (x 63-67): valla y un huerto pequeño con su espantapájaros
    valla(B, 62.75, 67.2, z, c=(0.62, 0.48, 0.34))
    huerto(B, 63.1, 65.4, 37.6, 39.2, 6)
    tubo(B, (66.2, 0, 38.4), (66.2, 1.5, 38.4), 0.035, 0.035, 5, MADERA)
    caja(B, (65.85, 1.15, 38.37), (66.55, 1.2, 38.43), MADERA, caras="seoa")
    caja(B, (66.02, 0.85, 38.3), (66.38, 1.3, 38.5), (0.62, 0.42, 0.30))
    bulto(B, (66.2, 1.45, 38.4), 0.13, (1, 1, 1), 0, 0.1, (0.86, 0.76, 0.52), 9)
    tubo(B, (66.2, 1.52, 38.4), (66.2, 1.62, 38.4), 0.24, 0.1, 7, (0.70, 0.60, 0.30))
    # los choques: cada jardín entero (la valla y lo de dentro), bajo
    for (a, b) in ((41.95, 46.2), (49.8, 55.2), (55.8, 62.2), (62.75, 67.2)):
        B.caja_choque(a, z - 0.3, b, 39.55, 0.9)


# ================================================================= EL FRENTE DE LA BOTICA (Mirta)
# La botica de Selene (botica.glb) ya está en la ciudad: aquí, el tenderete de Mirta delante de su ventana (a la izquierda
# de la puerta): un toldo corto y alto (no tapa a Mirta desde la cámara), el mostrador con frascos y el mortero, un
# estante con tarros contra la fachada, macetas de hierbas y el cartel del mortero.

MIRTA = (34.75, 0.0, 40.5)
PUNTO_BOTICA = (34.75, 0.0, 42.25)


def frasco(B, base, r, h, c, semilla):
    b = V(base)
    lados = nq(7, 5)
    tubo(B, b, b + V(0, h * 0.7, 0), r, r, lados, c, tapa_a=False, tapa_b=False)
    tubo(B, b + V(0, h * 0.7, 0), b + V(0, h * 0.85, 0), r, r * 0.45, lados, c, tapa_a=False, tapa_b=False)
    tubo(B, b + V(0, h * 0.85, 0), b + V(0, h, 0), r * 0.4, r * 0.4, lados, (0.66, 0.50, 0.34), tapa_a=False)


def botica_frente(B):
    fz = 40.03                                                  # la fachada de la botica (botica.glb)
    x0, x1 = 33.25, 35.95
    # el toldo: de la fachada (2,95 m) a 0,9 m de ella (2,62 m), a rayas verdes y crema, con su faldón
    n = nq(7, 4)
    for i in range(n):
        a, b = x0 + (x1 - x0) * i / n, x0 + (x1 - x0) * (i + 1) / n
        c = jit((VERDE, CREMA)[i % 2], 0.04)
        cara(B, [(a, 2.95, fz), (b, 2.95, fz), (b, 2.62, fz + 0.92), (a, 2.62, fz + 0.92)], c, (0, 1, 0.3))
        cara(B, [(a, 2.62, fz + 0.92), (b, 2.62, fz + 0.92), (b, 2.47, fz + 0.94), (a, 2.47, fz + 0.94)], c, (0, 0, 1))
    for x in (x0 + 0.05, x1 - 0.05):                            # escuadras de hierro
        caja_t(B, (x, 2.75, fz + 0.45), (0.03, 0.03, 1.0), (1, 0, 0), (0, 1, 0.35), HIERRO)
    # ramilletes de hierbas secándose bajo el toldo
    if Q >= 0.7:
        for k in range(5):
            x = x0 + 0.35 + 0.5 * k
            bulto(B, (x, 2.32, fz + 0.86), 0.08, (0.8, 1.6, 0.8), 0, 0.2, jit(((0.48, 0.58, 0.30), (0.62, 0.52, 0.66))[k % 2], 0.1), k)
    # estante contra la fachada, a la izquierda, con tarros
    sx0, sx1 = 33.3, 34.05
    caja(B, (sx0, 0, fz), (sx0 + 0.06, 1.9, fz + 0.32), MADERA_OSC, caras="seoa")
    caja(B, (sx1 - 0.06, 0, fz), (sx1, 1.9, fz + 0.32), MADERA_OSC, caras="seoa")
    for y in (0.35, 0.85, 1.35, 1.85):
        caja(B, (sx0, y, fz), (sx1, y + 0.05, fz + 0.32), MADERA)
    tarros = [(0.36, 0.62, 0.42), (0.72, 0.52, 0.26), (0.40, 0.48, 0.74), (0.62, 0.36, 0.56), (0.82, 0.78, 0.60)]
    for k, y in enumerate((0.4, 0.9, 1.4)):
        for j in range(nq(3, 2)):
            frasco(B, (sx0 + 0.15 + 0.22 * j, y, fz + 0.17), 0.065, 0.22 + 0.04 * ((j + k) % 2), tarros[(j + 2 * k) % 5], j)
    B.caja_choque(sx0, fz, sx1, fz + 0.35, 2.0)
    # el mostrador, con frascos de colores, el mortero y una balanza
    mx0, mx1, mz0, mz1 = 34.05, 35.9, 40.9, 41.35
    caja(B, (mx0, 0, mz0), (mx1, 0.92, mz1), MADERA, caras="neo")
    tablas(B, (mx0, 0, mz1), (1, 0, 0), mx1 - mx0, 0.92, (0, 0, 1), MADERA_CLARA, nq(5, 3))
    caja(B, (mx0 - 0.05, 0.92, mz0 - 0.04), (mx1 + 0.05, 0.99, mz1 + 0.05), MADERA_CLARA)
    for k in range(nq(6, 3)):
        frasco(B, (34.2 + 0.18 * k, 0.99, 41.18 - 0.08 * (k % 2)), 0.06, 0.2 + 0.05 * (k % 3), tarros[k % 5], k)
    tubo(B, (35.5, 0.99, 41.1), (35.5, 1.13, 41.1), 0.09, 0.12, nq(8, 6), (0.62, 0.62, 0.58))
    caja_t(B, (35.58, 1.17, 41.1), (0.03, 0.22, 0.03), (1, 0, 0), (0.5, 1, 0), MADERA_OSC)
    caja(B, (35.73, 0.99, 41.0), (35.77, 1.3, 41.04), ORO, caras="seoa")
    caja(B, (35.6, 1.28, 41.0), (35.9, 1.31, 41.04), ORO, caras="seoa")
    B.caja_choque(mx0, mz0, mx1, mz1, 1.0)
    # macetas de hierbas y un cajón de frascos en el suelo
    for k, (x, z) in enumerate(((33.4, 41.55), (36.15, 41.6))):
        tubo(B, (x, 0, z), (x, 0.3, z), 0.14, 0.18, nq(8, 6), (0.62, 0.34, 0.22), tapa_a=False)
        bulto(B, (x, 0.42, z), 0.2, (1, 1.1, 1), 1, 0.35, lambda d, q, k=k: jit((HOJA[2], (0.50, 0.62, 0.36))[k], 0.15), 11 + k)
        B.caja_choque(x - 0.2, z - 0.2, x + 0.2, z + 0.2, 0.6)
    # el cartel: cuelga de un brazo en la esquina oeste, de cara a la plaza
    caja(B, (33.08, 2.4, fz), (33.14, 2.46, fz + 0.75), HIERRO, caras="seoa")
    cartel(B, (33.1, 2.0, fz + 0.62), 0.78, 0.52, (1, 0, 0), (0, 0, 1), emblema_mortero, cadenas=0.08)


# ================================================================= EL RINCÓN DEL POZO (secreto)
# Entre dos casas del relleno (x 46,4-49,6; z 39,7-44,5), detrás de un arco cubierto de hiedra: un pozo viejo con su
# tejadillo, losas con musgo, un banco de piedra, helechos y hiedra por las paredes. Se examina el pozo.

POZO = (47.95, 0.0, 41.95)
PUNTO_POZO = (47.95, 0.0, 40.6)


def rincon_pozo(B):
    # el arco de la entrada: dos pilares de piedra y un dintel de madera comido por la hiedra
    for x in (46.45, 49.3):
        caja(B, (x, 0, 39.55), (x + 0.32, 2.35, 39.87), PIEDRA[1])
        B.caja_choque(x, 39.55, x + 0.32, 39.87, 2.4)
    caja(B, (46.35, 2.35, 39.5), (49.72, 2.6, 39.92), MADERA_OSC)
    for k in range(nq(9, 5)):
        bulto(B, (46.5 + 3.1 * k / 8 + RND.uniform(-0.1, 0.1), 2.6 + RND.uniform(0.0, 0.08), 39.7 + RND.uniform(-0.15, 0.15)),
              RND.uniform(0.2, 0.28), (1.3, 0.7, 1.0), 1, 0.35, lambda d, q: jit(elige(HOJA), 0.1), k)
    for k in range(nq(6, 3)):                                     # hiedra que cuelga del dintel
        x = 46.6 + 2.9 * RND.random()
        largo = RND.uniform(0.4, 0.9)
        cara(B, [(x - 0.05, 2.36 - largo, 39.93), (x + 0.05, 2.36 - largo, 39.93), (x + 0.07, 2.36, 39.93), (x - 0.07, 2.36, 39.93)],
             jit(HOJA[1], 0.1), (0, 0, 1))
    farolillo(B, (47.9, 2.05, 39.7))
    # el pozo: brocal de piedra, agua oscura con un brillo, dos pies, el travesaño, el tejadillo, la cuerda y el cubo
    px, pz = POZO[0], POZO[2]
    lados = nq(14, 8)
    piedras = [jit(mezcla(PIEDRA[0], PIEDRA[2], RND.random()), 0.03) for _ in range(lados)]
    tubo(B, (px, 0, pz), (px, 0.78, pz), 0.78, 0.78, lados, piedras, tapa_a=False, tapa_b=False, plano=True)
    tubo(B, (px, 0.45, pz), (px, 0.84, pz), 0.56, 0.56, lados, mezcla(PIEDRA[0], (0, 0, 0), 0.4), tapa_a=False, tapa_b=False,
         dentro=True)
    for k in range(lados):                                        # el canto de arriba: anillo de losas
        a0, a1 = 2 * math.pi * k / lados, 2 * math.pi * (k + 1) / lados
        q = [(px + math.cos(a) * r, 0.84, pz + math.sin(a) * r) for (a, r) in ((a0, 0.56), (a1, 0.56), (a1, 0.84), (a0, 0.84))]
        mus = ruido_musgo(q[0])
        cara(B, q, jit(mezcla(PIEDRA[2], HOJA[1], mus), 0.05), (0, 1, 0))
    tubo(B, (px, 0.84, pz), (px, 0.78, pz), 0.84, 0.78, lados, PIEDRA[1], tapa_a=False, tapa_b=False)
    cara(B, [(px + math.cos(2 * math.pi * k / lados) * 0.58, 0.45, pz + math.sin(2 * math.pi * k / lados) * 0.58) for k in range(lados)],
         (0.05, 0.10, 0.14), (0, 1, 0))
    for k in range(nq(5, 3)):                                     # luciérnagas posadas dentro (el secreto brilla)
        a = 2 * math.pi * k / 5 + 0.4
        caja(B, (px + math.cos(a) * 0.3 - 0.02, 0.47, pz + math.sin(a) * 0.3 - 0.02),
             (px + math.cos(a) * 0.3 + 0.02, 0.5, pz + math.sin(a) * 0.3 + 0.02), (0.80, 1.0, 0.55), BRILLO, jitter=0)
    for s in (-1, 1):
        caja(B, (px + 0.7 * s - 0.07, 0.0, pz - 0.07), (px + 0.7 * s + 0.07, 2.05, pz + 0.07), MADERA_OSC, caras="nseoa")
    tubo(B, (px - 0.75, 1.6, pz), (px + 0.75, 1.6, pz), 0.055, 0.055, 6, MADERA)
    caja(B, (px - 0.01, 0.95, pz - 0.01), (px + 0.01, 1.6, pz + 0.01), (0.66, 0.58, 0.42), caras="seo")
    barril(B, (px, 0.75, pz), 0.12, 0.2)
    farolillo(B, (px + 0.7, 1.45, pz + 0.12))                      # un farolillo colgado del pie del pozo
    tejado(B, (px - 0.95, 2.5, pz), (px + 0.95, 2.5, pz), (px - 0.95, 2.0, pz + 0.65), (px + 0.95, 2.0, pz + 0.65),
           ((0.40, 0.30, 0.22), (0.48, 0.36, 0.26), (0.56, 0.42, 0.30)), 3, 4, labio=False)
    tejado(B, (px + 0.95, 2.5, pz), (px - 0.95, 2.5, pz), (px + 0.95, 2.0, pz - 0.65), (px - 0.95, 2.0, pz - 0.65),
           ((0.40, 0.30, 0.22), (0.48, 0.36, 0.26), (0.56, 0.42, 0.30)), 2, 3, labio=False)
    for k in range(nq(4, 2)):                                     # musgo en el tejadillo
        bulto(B, (px - 0.6 + 0.4 * k, 2.32, pz + 0.3), 0.14, (1.3, 0.4, 1.0), 0, 0.3, HOJA[2], k)
    B.caja_choque(px - 0.85, pz - 0.85, px + 0.85, pz + 0.85, 1.0)
    ancla("pozo", (px, 0.6, pz))
    # el banco de piedra del fondo y helechos
    caja(B, (46.6, 0.0, 43.9), (46.85, 0.42, 44.25), PIEDRA[1])
    caja(B, (48.85, 0.0, 43.9), (49.1, 0.42, 44.25), PIEDRA[1])
    caja(B, (46.5, 0.42, 43.85), (49.2, 0.52, 44.3), PIEDRA[2])
    B.caja_choque(46.5, 43.85, 49.2, 44.3, 0.6)
    for k, (x, z) in enumerate(((46.65, 40.4), (49.35, 40.6), (46.7, 43.1), (49.3, 42.9), (48.0, 44.45))):
        if k >= nq(5, 3):
            break
        for j in range(nq(7, 4)):
            a = 2 * math.pi * j / 7 + k
            d = V(math.cos(a), 0, math.sin(a))
            base = V(x, 0.02, z)
            punta = base + d * 0.45 + V(0, 0.32, 0)
            lado = V(-d.z, 0, d.x) * 0.08
            cara(B, [base - lado * 0.4, base + d * 0.22 + lado + V(0, 0.22, 0), punta, base + d * 0.22 - lado + V(0, 0.22, 0)],
                 jit(elige(HOJA), 0.12), (0, 1, 0))
    # hiedra por las paredes de las dos casas
    hiedra(B, (46.37, 0.2, 43.9), (0, 0, -1), 3.6, 3.2, (1, 0, 0), 26)
    hiedra(B, (49.68, 0.2, 40.3), (0, 0, 1), 3.6, 2.8, (-1, 0, 0), 22)


def ruido_musgo(p):
    return max(0.0, noise.noise(V(p) * 2.5)) * 0.8


# ================================================================= LOS ENCARGADOS (figuras sencillas)
# Como Aldric y la posadera (cápsula, cabeza y pelo), algo más trabajadas y en una sola malla cada uno: origen en los
# pies, de cara al sur (+z). El brazo del martillo de Ferro va aparte, con el origen en el hombro.

HOMBRO_FERRO = (-0.39, 1.38, 0.0)


def figura(M, alto, ancho, ropa, falda=None, delantal=None, piel=PIEL, pelo=None, peinado="", barba=None, brazo_der=True):
    lados = 10
    s = alto / 1.75
    # piernas o falda
    if falda:
        tubo(M, (0, 0, 0), (0, 0.85 * s, 0), 0.30 * ancho, 0.24 * ancho, lados, falda)
    else:
        for k in (-1, 1):
            tubo(M, (0.11 * k * ancho, 0, 0), (0.11 * k * ancho, 0.8 * s, 0), 0.09 * ancho, 0.1 * ancho, 8, (0.24, 0.21, 0.24))
            caja(M, (0.11 * k * ancho - 0.08, 0, -0.06), (0.11 * k * ancho + 0.08, 0.1, 0.14), (0.20, 0.13, 0.09))
    # cuerpo
    tubo(M, (0, 0.8 * s, 0), (0, 1.12 * s, 0), 0.22 * ancho, 0.26 * ancho, lados, ropa, tapa_a=True, tapa_b=False)
    tubo(M, (0, 1.12 * s, 0), (0, 1.38 * s, 0), 0.26 * ancho, 0.2 * ancho, lados, ropa, tapa_a=False, tapa_b=True)
    caja(M, (-0.23 * ancho, 0.8 * s, -0.24 * ancho), (0.23 * ancho, 0.86 * s, 0.24 * ancho), CUERO, caras="nseo")   # cinturón
    if delantal:
        cara(M, [(-0.2 * ancho, (0.3 if falda else 0.45) * s, 0.27 * ancho), (0.2 * ancho, (0.3 if falda else 0.45) * s, 0.27 * ancho),
                 (0.17 * ancho, 1.3 * s, 0.25 * ancho), (-0.17 * ancho, 1.3 * s, 0.25 * ancho)], delantal, (0, 0, 1))
    # brazos (el derecho, -x, solo si no va aparte)
    for k in ((-1, 1) if brazo_der else (1,)):
        x = -0.31 * ancho * k * -1 if False else 0.31 * ancho * k
        tubo(M, (x, 1.36 * s, 0), (x * 1.05, 0.95 * s, 0.04), 0.075 * ancho, 0.07 * ancho, 7, ropa, tapa_a=True, tapa_b=False)
        tubo(M, (x * 1.05, 0.95 * s, 0.04), (x * 1.0, 0.72 * s, 0.08), 0.065 * ancho, 0.06 * ancho, 7, piel, tapa_a=False)
    # cuello y cabeza
    tubo(M, (0, 1.36 * s, 0), (0, 1.47 * s, 0), 0.07, 0.07, 7, piel, tapa_a=False, tapa_b=False)
    bulto(M, (0, 1.58 * s, 0.01), 0.16, (0.95, 1.08, 0.98), 1, 0.03, piel, 1)
    for x in (-0.07, 0.035):                                       # los ojos
        cara(M, [(x, 1.6 * s, 0.172), (x + 0.035, 1.6 * s, 0.172), (x + 0.035, 1.635 * s, 0.172), (x, 1.635 * s, 0.172)],
             (0.1, 0.07, 0.06), (0, 0, 1))
    if pelo:
        if peinado == "trenza":
            bulto(M, (0, 1.66 * s, -0.02), 0.165, (1.02, 0.85, 1.02), 1, 0.05, pelo, 2)
            for i in range(4):
                bulto(M, (0.08, (1.45 - 0.13 * i) * s, -0.13 - 0.02 * i), 0.065, (1, 1.2, 1), 0, 0.05, pelo, i)
        elif peinado == "mono":
            bulto(M, (0, 1.66 * s, -0.03), 0.165, (1.02, 0.8, 1.02), 1, 0.04, pelo, 2)
            bulto(M, (0, 1.7 * s, -0.15), 0.09, (1, 1, 1), 1, 0.05, pelo, 3)
        else:                                                      # calvo con cerco de pelo
            tubo(M, (0, 1.53 * s, 0.0), (0, 1.62 * s, -0.01), 0.165, 0.165, 9, pelo, tapa_a=False, tapa_b=False)
    if barba:
        bulto(M, (0, 1.47 * s, 0.09), 0.14, (1.05, 1.15, 0.8), 1, 0.12, barba, 4, None)
        caja(M, (-0.08, 1.575 * s, 0.13), (0.08, 1.6 * s, 0.17), barba)                        # bigote


def brazo_ferro(M):
    """El brazo derecho de Ferro con el martillo, desde el hombro (origen): en reposo cae hacia el yunque."""
    s = 1.0
    tubo(M, (0, 0, 0), (0.0, -0.36, 0.14), 0.085, 0.08, 7, (0.80, 0.74, 0.62))
    tubo(M, (0.0, -0.36, 0.14), (0.0, -0.5, 0.42), 0.075, 0.065, 7, PIEL, tapa_a=False)
    bulto(M, (0.0, -0.52, 0.47), 0.07, (1, 1, 1), 0, 0.0, PIEL, 1)
    caja_t(M, (0.0, -0.44, 0.62), (0.04, 0.04, 0.42), (1, 0, 0), (0, 1, 0.5), MADERA_CLARA)   # mango
    caja_t(M, (0.0, -0.33, 0.82), (0.11, 0.2, 0.11), (1, 0, 0), (0, 1, 0.5), HIERRO)            # cabeza del martillo


# ================================================================= el GLB

def material(nombre):
    m = bpy.data.materials.get(nombre)
    if m is not None:
        return m
    m = bpy.data.materials.new(nombre)
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    ca = m.node_tree.nodes.new("ShaderNodeVertexColor")
    ca.layer_name = "Color"
    if nombre == "base":
        gam = m.node_tree.nodes.new("ShaderNodeGamma")          # solo para verlo bien en Blender (el atributo va en sRGB)
        gam.inputs["Gamma"].default_value = 2.2
        m.node_tree.links.new(ca.outputs["Color"], gam.inputs["Color"])
        m.node_tree.links.new(gam.outputs["Color"], bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.9
    else:
        m.node_tree.links.new(ca.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = 1.0
        bsdf.inputs["Base Color"].default_value = (0, 0, 0, 1)
    return m


def objeto(nombre, M):
    me = bpy.data.meshes.new(nombre)
    me.from_pydata([tuple(v) for v in M.v], [], M.caras)
    me.update()
    me.polygons.foreach_set("material_index", M.mats)
    attr = me.color_attributes.new("Color", 'FLOAT_COLOR', 'POINT')
    cols = []
    for c in M.col:
        cols += list(c) + [1.0]
    attr.data.foreach_set("color", cols)
    me.color_attributes.active_color = attr
    me.validate(clean_customdata=False)
    for nm in ("base", "brillo"):
        me.materials.append(material(nm))
    me.shade_smooth()
    me.set_sharp_from_angle(angle=math.radians(40))
    ob = bpy.data.objects.new(nombre, me)
    bpy.context.scene.collection.objects.link(ob)
    for i, (x, z, w, d, h) in enumerate(M.cajas):
        e = bpy.data.objects.new("caja_%d_%d_%d_%d" % (i, round(w * 100), round(d * 100), round(h * 100)), None)
        e.empty_display_type = 'CUBE'
        e.location = (x, -z, 0.0)
        e.parent = ob
        bpy.context.scene.collection.objects.link(e)
    return ob


def construir(calidad, ruta):
    global Q
    Q = calidad
    RND.seed(7)
    ANCLAS.clear()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    grupos = {}
    B = Malla()
    grupos["bajo"] = B
    for nombre, f in (("herreria", herreria), ("armeria", armeria), ("casa_a", casa_a), ("casa_b", casa_b)):
        E = Malla()
        grupos["edif_" + nombre] = E
        f(E, B)
    puestos(B)
    patios(B)
    jardines(B)
    botica_frente(B)
    rincon_pozo(B)
    for nombre, args in (("pnj_ferro", dict(alto=1.78, ancho=1.25, ropa=(0.80, 0.74, 0.62), delantal=CUERO, pelo=(0.24, 0.17, 0.12),
                                         barba=(0.26, 0.17, 0.11), brazo_der=False)),
                         ("pnj_hilda", dict(alto=1.7, ancho=1.0, ropa=(0.32, 0.38, 0.52), delantal=(0.46, 0.30, 0.18),
                                         pelo=(0.72, 0.36, 0.18), peinado="trenza")),
                         ("pnj_mirta", dict(alto=1.6, ancho=1.0, ropa=(0.30, 0.46, 0.33), falda=(0.40, 0.28, 0.20),
                                         delantal=(0.90, 0.86, 0.76), pelo=(0.80, 0.80, 0.80), peinado="mono"))):
        M = Malla()
        figura(M, **args)
        grupos[nombre] = M
    M = Malla()
    brazo_ferro(M)
    grupos["pnj_ferro_brazo"] = M
    total = 0
    for nombre, M in grupos.items():
        objeto(nombre, M)
        tri = M.triangulos()
        total += tri
        print("GRUPO %-18s triángulos %6d  cajas %d" % (nombre, tri, len(M.cajas)))
    for nombre, (x, y, z) in list(ANCLAS.items()) + [("ferro", FERRO), ("hilda", HILDA), ("mirta", MIRTA),
                                                       ("punto_forja", PUNTO_FORJA), ("punto_armaduras", PUNTO_ARMADURAS),
                                                       ("punto_botica", PUNTO_BOTICA), ("punto_pozo", PUNTO_POZO),
                                                       ("hombro_ferro", HOMBRO_FERRO)]:
        e = bpy.data.objects.new("ancla_" + nombre, None)
        e.location = (x, -z, y)
        bpy.context.scene.collection.objects.link(e)
    print("DISTRITO (calidad %.2f) triángulos: %d" % (calidad, total))
    if ruta:
        bpy.ops.export_scene.gltf(filepath=ruta, export_format='GLB', use_selection=False, export_animations=False,
                                  export_yup=True, export_vertex_color='ACTIVE', export_cameras=False,
                                  export_lights=False, export_apply=True)
        print("EXPORTADO", ruta)


construir(1.0, os.path.join(CARPETA, "distrito.glb") if CARPETA else "")
construir(0.55, os.path.join(CARPETA, "distrito_ligero.glb") if CARPETA else "")
