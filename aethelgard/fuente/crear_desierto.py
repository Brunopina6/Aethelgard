# Arte del Mar de Cristal (V12, primer sector «La Orilla de Vidrio»): ruinas medio enterradas, restos de la caravana,
# campamento, oasis, rocas del cañón con el cobijo, los huesos de la arena que tiembla y el esqueleto del nicho.
# Hecho desde cero con este guion (geometría procedural propia, ningún recurso descargado: obra propia del proyecto), con
# el método del distrito de Oakhaven (zonas3d/oakhaven/fuente/crear_distrito.py): colores de vértice, caras planas y
# un puñado de materiales compartidos que Godot sustituye (zonas3d/mar_cristal/materiales_arte.gd).
#
#   blender -b --factory-startup -P crear_desierto.py -- <carpeta de salida> [pieza1,pieza2,...]
#
# Escribe <carpeta>/<pieza>.glb (perfil alto) y, cuando ahorra al menos un 20 % de triángulos, <pieza>_ligero.glb
# (perfiles medio y bajo: las mismas formas con menos lados, menos estratos y menos hojas). Misma semilla, mismo resultado.
#
# Cada pieza va en metros, con el origen en su base (y = 0 es el suelo; lo que queda por debajo está enterrado y sirve
# para hundirla más) y mirando al sur (+z: hacia la cámara del juego, que mira al norte desde arriba y no gira).
#
# Materiales (los sustituye materiales_arte.gd; aquí solo separan las superficies):
#   base     colores de vértice en sRGB (como el distrito: se usan tal cual)
#   brillo   lo que da luz propia (brasas, farolillo): sin sombreado
#   vidrio   el vidrio del Mar de Cristal (incrustaciones, cristales): brillo frío y reflejo
#   arena    montones de arena pegados a las piezas: el mismo sombreado que el suelo (ondas, viento), para que se fundan
#   tela     telas que se mueven con el viento (shaders/desierto/tela.gdshader); el alfa del color es cuánto se mueven
#   hojas    palmas y juncos que se mecen (shaders/desierto/planta.gdshader); el alfa del color es cuánto se mueven
# Vacíos:
#   caja_<i>_<ancho cm>_<fondo cm>_<alto cm>   hijo de su objeto: un choque de caja con la base en esa posición
#   ancla_<nombre>                             posiciones con nombre (fuego, nota, cobijo, bisagra…)
#
# Ejes: se trabaja en coordenadas de Godot (x al este, y arriba, z al sur) y se pasan a Blender (x, -z, y) al crear cada
# vértice; el exportador glTF (y arriba) las devuelve tal cual.
import bpy, bmesh, sys, os, math, random
from mathutils import Vector, Matrix, noise
from mathutils.geometry import tessellate_polygon

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
CARPETA = argv[0] if argv else ""
SOLO = [s for s in argv[1].split(",") if s] if len(argv) > 1 else []

MATERIALES = ["base", "brillo", "vidrio", "arena", "tela", "hojas"]
BASE, BRILLO, VIDRIO, ARENA, TELA, HOJAS = range(6)
Q = 1.0                       # calidad: 1 en el GLB alto, menos en el ligero
RND = random.Random(11)

# ---------------------------------------------------------------- colores (sRGB)

ARENA_C = (0.88, 0.71, 0.48)
ARENA_NEUTRA = (1.0, 1.0, 1.0)          # el material de arena pone el color; el vértice solo oscurece (oclusión)
ARENISCA = ((0.64, 0.49, 0.35), (0.76, 0.60, 0.43), (0.86, 0.71, 0.52))
ARENISCA_OSC = (0.42, 0.31, 0.23)
ROCA_CANON = ((0.55, 0.30, 0.20), (0.67, 0.39, 0.25), (0.79, 0.52, 0.34), (0.87, 0.66, 0.46))
ROCA_SOMBRA = (0.38, 0.21, 0.16)
HUESO = ((0.70, 0.62, 0.48), (0.80, 0.73, 0.58), (0.88, 0.82, 0.68))
HUESO_OSC = (0.46, 0.39, 0.30)
MADERA_SECA = (0.56, 0.43, 0.30)
MADERA_GRIS = (0.66, 0.60, 0.51)        # blanqueada por el sol
MADERA_OSC = (0.33, 0.23, 0.16)
HIERRO = (0.22, 0.20, 0.20)
OXIDO = (0.45, 0.25, 0.15)
CUERO = (0.45, 0.28, 0.16)
CUERDA = (0.72, 0.61, 0.43)
SACO = (0.74, 0.64, 0.46)
BARRO = (0.70, 0.42, 0.26)
CREMA = (0.93, 0.86, 0.69)
PAPEL = (0.90, 0.84, 0.68)
TELA_ROJA = (0.74, 0.27, 0.19)
TELA_CREMA = (0.93, 0.85, 0.67)
TELA_ANIL = (0.22, 0.29, 0.52)
TELA_OCRE = (0.86, 0.58, 0.24)
TELA_TURQUESA = (0.18, 0.54, 0.56)
CENIZA = (0.30, 0.28, 0.27)
PIEDRA_FUEGO = ((0.42, 0.38, 0.35), (0.55, 0.50, 0.45), (0.66, 0.60, 0.53))
PALMA_TRONCO = ((0.38, 0.28, 0.19), (0.50, 0.38, 0.26), (0.62, 0.50, 0.35))
HOJA_PALMA = ((0.17, 0.36, 0.16), (0.27, 0.49, 0.20), (0.50, 0.63, 0.25))
HOJA_SECA = ((0.55, 0.40, 0.22), (0.68, 0.53, 0.30))
DATIL = (0.62, 0.30, 0.12)
JUNCO = ((0.22, 0.38, 0.16), (0.40, 0.56, 0.24), (0.70, 0.70, 0.38))
ESPADANA = (0.40, 0.23, 0.13)
VIDRIO_C = (0.62, 0.93, 0.95)           # el vidrio del desierto (turquesa pálido)
VIDRIO_AMBAR = (0.98, 0.78, 0.45)
BRASA = ((0.85, 0.20, 0.06), (1.0, 0.48, 0.12), (1.0, 0.80, 0.36))
LUZ_FAROL = (1.0, 0.76, 0.40)
OSCURO = (0.08, 0.06, 0.05)


def mezcla(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(a[i] * (1 - t) + b[i] * t for i in range(3))


def jit(c, a=0.06):
    k = 1 + RND.uniform(-a, a)
    return tuple(max(0.0, min(1.0, x * k)) for x in c[:3])


def elige(pal):
    return pal[RND.randrange(len(pal))]


def nq(n, minimo=3):
    return max(minimo, int(round(n * Q)))


def V(*a):
    return Vector(a[0]) if len(a) == 1 else Vector(a)


# ---------------------------------------------------------------- constructor de mallas (coordenadas de Godot)

class Malla:
    def __init__(self):
        self.v, self.col, self.caras, self.mats = [], [], [], []
        self.cajas = []            # (x centro, z centro, ancho x, fondo z, alto)
        self.T = None              # transformación (Matrix 4x4, coordenadas de Godot) para lo que se crea después

    def vert(self, p, c, w=1.0):
        p = V(p)
        if self.T is not None:
            p = self.T @ p
        self.v.append(Vector((p[0], -p[2], p[1])))       # Godot (x, y, z) → Blender (x, -z, y)
        self.col.append((c[0], c[1], c[2], w))
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


def cara(M, pts, c, hacia=None, mat=BASE, w=1.0):
    """Una cara plana (de 3 o más puntos), con sus propios vértices: color plano. «hacia»: hacia dónde mira.
    «c» y «w» pueden ser una lista (uno por punto)."""
    pts = [V(p) for p in pts]
    cols = list(c) if isinstance(c, list) else [c] * len(pts)
    ws = list(w) if isinstance(w, (list, tuple)) else [w] * len(pts)
    if hacia is not None:
        n = (pts[1] - pts[0]).cross(pts[2] - pts[0])
        if n.dot(V(hacia)) < 0:
            pts.reverse()
            cols.reverse()
            ws.reverse()
    M.cara([M.vert(p, cols[i], ws[i]) for i, p in enumerate(pts)], mat)


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
        cara(M, [(x1, y0, z0), (x1, y0, z1), (x1, y1, z1), (x1, y1, z0)], jit(mezcla(c, (0, 0, 0), 0.08), jitter), (1, 0, 0), mat)
    if "o" in caras:
        cara(M, [(x0, y0, z0), (x0, y0, z1), (x0, y1, z1), (x0, y1, z0)], jit(mezcla(c, (0, 0, 0), 0.08), jitter), (-1, 0, 0), mat)
    if abajo:
        cara(M, [(x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1)], c, (0, -1, 0), mat)


def caja_t(M, centro, tam, ux, uy, c, mat=BASE, jitter=0.05, w=1.0):
    """Caja orientada: centro, tamaño (a lo largo de ux, uy y su normal) y dos ejes."""
    ux, uy = V(ux).normalized(), V(uy).normalized()
    uz = ux.cross(uy).normalized()
    uy = uz.cross(ux).normalized()
    o = V(centro)
    hx, hy, hz = ux * tam[0] * 0.5, uy * tam[1] * 0.5, uz * tam[2] * 0.5
    for d, e1, e2 in ((hx, hy, hz), (-hx, hy, hz), (hy, hx, hz), (-hy, hx, hz), (hz, hx, hy), (-hz, hx, hy)):
        p = o + d
        cc = jit(c, jitter)
        if d.y > 0.3 * d.length:
            cc = jit(mezcla(c, (1, 1, 1), 0.05), jitter)
        cara(M, [p - e1 - e2, p + e1 - e2, p + e1 + e2, p - e1 + e2], cc, d, mat, w)


def marco(d):
    d = V(d).normalized()
    ref = V(0, 1, 0) if abs(d.y) < 0.9 else V(1, 0, 0)
    u = d.cross(ref).normalized()
    return u, d.cross(u).normalized()


def tubo(M, a, b, ra, rb, lados, c, tapa_a=True, tapa_b=True, mat=BASE, plano=True, w=1.0):
    tubo_curvo(M, [a, b], [ra, rb], lados, c, mat=mat, tapa_ini=tapa_a, tapa_fin=tapa_b, plano=plano,
               pesos=list(w) if isinstance(w, (list, tuple)) else [w, w])


def tubo_curvo(M, pts, radios, lados, colores, mat=BASE, pesos=None, tapa_ini=False, tapa_fin=True, plano=False,
               aplastar=1.0, giro=0.0):
    """Tubo a lo largo de una polilínea (troncos, huesos, nervios), con transporte paralelo del marco. «radios» y
    «colores» pueden ir por anillo; con «plano», cada cara con su color (facetas)."""
    pts = [V(p) for p in pts]
    n = len(pts)
    rs = list(radios) if isinstance(radios, (list, tuple)) else [radios] * n
    cols = list(colores) if isinstance(colores, list) else [colores] * n
    ws = list(pesos) if pesos else [1.0] * n
    tans = []
    for i in range(n):
        a, b = pts[max(i - 1, 0)], pts[min(i + 1, n - 1)]
        tans.append((b - a).normalized())
    u, w = marco(tans[0])
    anillos = []
    for i in range(n):
        if i > 0:
            t0, t1 = tans[i - 1], tans[i]
            eje = t0.cross(t1)
            if eje.length > 1e-6:
                R = Matrix.Rotation(t0.angle(t1), 3, eje.normalized())
                u, w = (R @ u).normalized(), (R @ w).normalized()
        anillo = []
        for k in range(lados):
            t = 2 * math.pi * k / lados + giro
            anillo.append(pts[i] + (u * math.cos(t) + w * math.sin(t) * aplastar) * rs[i])
        anillos.append(anillo)
    for i in range(n - 1):
        centro = (pts[i] + pts[i + 1]) * 0.5
        if plano:
            for k in range(lados):
                k2 = (k + 1) % lados
                q = [anillos[i][k], anillos[i][k2], anillos[i + 1][k2], anillos[i + 1][k]]
                cc = cols[i]
                cc = cols[i][k % len(cols[i])] if isinstance(cc, list) else jit(cc, 0.04)
                cara(M, q, cc, (q[0] + q[2]) * 0.5 - centro, mat, [ws[i], ws[i], ws[i + 1], ws[i + 1]])
    if not plano:
        idx = [[M.vert(p, cols[i], ws[i]) for p in anillos[i]] for i in range(n)]
        for i in range(n - 1):
            centro = (pts[i] + pts[i + 1]) * 0.5
            for k in range(lados):
                k2 = (k + 1) % lados
                q = [idx[i][k], idx[i][k2], idx[i + 1][k2], idx[i + 1][k]]
                a, b, c = anillos[i][k], anillos[i][k2], anillos[i + 1][k2]
                if (b - a).cross(c - a).dot((a + c) * 0.5 - centro) < 0:
                    q.reverse()
                M.cara(q, mat)
    c0 = cols[0][0] if isinstance(cols[0], list) else cols[0]
    c1 = cols[-1][0] if isinstance(cols[-1], list) else cols[-1]
    if tapa_ini and rs[0] > 0.001:
        cara(M, anillos[0], mezcla(c0, (0, 0, 0), 0.12), -tans[0], mat, ws[0])
    if tapa_fin and rs[-1] > 0.001:
        cara(M, anillos[-1], mezcla(c1, (1, 1, 1), 0.06), tans[-1], mat, ws[-1])


def bulto(M, centro, radio, escala=(1, 1, 1), subdiv=1, amp=0.18, color=None, semilla=0.0, y_min=None, mat=BASE, w=1.0):
    """Icosfera deformada (piedras, sacos, cráneos). color: tupla o función (dirección, punto) → color."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=1.0)
    idx = {}
    for v in bm.verts:
        d = v.co.normalized()
        r = radio * (1 + amp * noise.noise(d * 2.3 + Vector((semilla, semilla * 0.37, 1.3))))
        p = V(centro) + V(d.x * escala[0], d.z * escala[1], d.y * escala[2]) * r   # (icosfera: z arriba en Blender)
        if y_min is not None:
            p.y = max(p.y, y_min)
        cc = color(V(d.x, d.z, d.y), p) if callable(color) else (color or ARENISCA[1])
        idx[v.index] = M.vert(p, cc, w)
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


def monticulo(M, centro, rx, rz, alto, giro=0.0, anillos=5, segs=14, semilla=0.0, cresta=0.35, y0=-0.07,
              oscuro=0.0, mat=ARENA):
    """Montón de arena (duna pegada a una pieza): rejilla radial con vértices compartidos (sombreado suave). La cresta
    se carga hacia +x local (sotavento); «oscuro»: cuánto se oscurece el centro (oclusión donde toca la piedra)."""
    c = V(centro)
    anillos, segs = nq(anillos, 3), nq(segs, 7)
    ca, sa = math.cos(giro), math.sin(giro)

    def punto(t, ang):
        x, z = math.cos(ang) * rx * t, math.sin(ang) * rz * t
        h = alto * max(0.0, 1 - t * t) ** 1.3
        h *= 1.0 + cresta * math.cos(ang) * t
        h *= 1.0 + 0.2 * noise.noise(Vector((x * 0.7 + semilla, z * 0.7 - semilla, semilla * 0.3)))
        return V(c.x + x * ca - z * sa, c.y + y0 + h, c.z + x * sa + z * ca)

    def col(t):
        k = 1.0 - oscuro * (1.0 - t) ** 2
        return (ARENA_NEUTRA[0] * k, ARENA_NEUTRA[1] * k, ARENA_NEUTRA[2] * k)

    i0 = M.vert(punto(0, 0), col(0))
    filas = []
    for i in range(1, anillos + 1):
        t = i / anillos
        filas.append([M.vert(punto(t, 2 * math.pi * k / segs), col(t)) for k in range(segs)])

    def orienta(q):
        a, b, cc = (Vector((M.v[j][0], M.v[j][2], -M.v[j][1])) for j in q[:3])   # de vuelta a Godot
        if (b - a).cross(cc - a).y < 0:
            q = list(reversed(q))
        return q

    for k in range(segs):
        M.cara(orienta([i0, filas[0][k], filas[0][(k + 1) % segs]]), mat)
    for i in range(anillos - 1):
        for k in range(segs):
            k2 = (k + 1) % segs
            M.cara(orienta([filas[i][k], filas[i + 1][k], filas[i + 1][k2], filas[i][k2]]), mat)


def cristales(M, base, n, alto, semilla, radio=0.35, color=VIDRIO_C, inclinacion=0.45):
    """Racimo de cristales de vidrio (prismas hexagonales con punta) que brotan de la arena vitrificada."""
    r = random.Random(semilla)
    b = V(base)
    for i in range(n):
        ang = r.uniform(0, 2 * math.pi)
        d = r.uniform(0, radio)
        p = b + V(math.cos(ang) * d, -0.05, math.sin(ang) * d)
        h = alto * r.uniform(0.45, 1.0) * (1.0 if i == 0 else 0.8)
        g = r.uniform(0.06, 0.13) * (alto / 0.8) ** 0.5
        eje = V(math.cos(ang) * inclinacion * r.uniform(0.3, 1.2), 1.0, math.sin(ang) * inclinacion * r.uniform(0.3, 1.2)).normalized()
        if i == 0:
            eje = V(0, 1, 0)
        lados = 6 if Q >= 1 else 5
        cc = jit(mezcla(color, (1, 1, 1), r.uniform(0.0, 0.3)), 0.05)
        top = p + eje * h
        tubo(M, p, top, g, g * 0.9, lados, cc, tapa_a=False, tapa_b=False, mat=VIDRIO)
        # punta
        u, w = marco(eje)
        anillo = [top + (u * math.cos(2 * math.pi * k / lados) + w * math.sin(2 * math.pi * k / lados)) * g * 0.9 for k in range(lados)]
        punta = top + eje * g * 1.8
        for k in range(lados):
            q = [anillo[k], anillo[(k + 1) % lados], punta]
            cara(M, q, mezcla(cc, (1, 1, 1), 0.25), (anillo[k] + anillo[(k + 1) % lados]) * 0.5 - top, VIDRIO)


# ================================================================= ruinas

def bloques_fila(M, x0, x1, y0, y1, z0, z1, pal, n_min=1, largo=0.9):
    """Una hilada de sillares entre x0 y x1 (con su llaga)."""
    ancho = x1 - x0
    n = max(n_min, int(round(ancho / largo)))
    xs = [x0] + sorted(x0 + ancho * (i + RND.uniform(-0.18, 0.18)) / n for i in range(1, n)) + [x1]
    for i in range(n):
        dz = RND.uniform(-0.035, 0.035)
        caja(M, (xs[i] + 0.012, y0 + 0.012, z0 + dz), (xs[i + 1] - 0.012, y1 - 0.012, z1 + dz),
             jit(mezcla(elige(pal), ARENA_C, RND.uniform(0.0, 0.2)), 0.05))


def dovela(M, cy, ri, ro, a0, a1, z0, z1, c):
    def p(r, a, z):
        return V(r * math.cos(a), cy + r * math.sin(a), z)
    am = (a0 + a1) * 0.5
    radial = V(math.cos(am), math.sin(am), 0)
    cara(M, [p(ri, a0, z1), p(ro, a0, z1), p(ro, a1, z1), p(ri, a1, z1)], jit(c, 0.04), (0, 0, 1))
    cara(M, [p(ri, a0, z0), p(ro, a0, z0), p(ro, a1, z0), p(ri, a1, z0)], jit(c, 0.04), (0, 0, -1))
    cara(M, [p(ro, a0, z0), p(ro, a1, z0), p(ro, a1, z1), p(ro, a0, z1)], jit(mezcla(c, (1, 1, 1), 0.06), 0.04), radial)
    cara(M, [p(ri, a0, z0), p(ri, a1, z0), p(ri, a1, z1), p(ri, a0, z1)], jit(mezcla(c, (0, 0, 0), 0.18), 0.04), -radial)
    for a, s in ((a0, -1), (a1, 1)):
        t = V(-math.sin(a), math.cos(a), 0) * s
        cara(M, [p(ri, a, z0), p(ro, a, z0), p(ro, a, z1), p(ri, a, z1)], mezcla(c, (0, 0, 0), 0.25), t)


def incrustacion_rombo(M, centro, U, N, alto, ancho, color=VIDRIO_C):
    """Rombo de vidrio en relieve sobre una cara (U: horizontal de la cara, N: hacia fuera)."""
    o, U, N = V(centro) + V(N) * 0.03, V(U).normalized(), V(N).normalized()
    Y = V(0, 1, 0)
    pts = [o + Y * alto * 0.5, o + U * ancho * 0.5, o - Y * alto * 0.5, o - U * ancho * 0.5]
    cima = o + N * 0.06
    for k in range(4):
        cara(M, [pts[k], pts[(k + 1) % 4], cima], jit(mezcla(color, (1, 1, 1), 0.1 * (k % 2)), 0.03),
             (pts[k] + pts[(k + 1) % 4]) * 0.5 - o + N * 0.5, VIDRIO)


def ruinas_arco(objs):
    M = nueva(objs, "ruinas_arco")
    A = nueva(objs, "ruinas_arco_arena")
    PR = ARENISCA
    zb, zf = -0.6, 0.6
    ri, ro = 1.55, 2.25
    ysp = 3.0
    xe = ro + 0.2                           # borde exterior de los pilares
    # pilares (de -2,4 m: lo enterrado sirve para hundir el arco antes de la tormenta)
    for s in (-1, 1):
        x0, x1 = sorted((s * ri, s * xe))
        y = -2.4
        while y < ysp - 0.01:
            h = min(RND.uniform(0.5, 0.62), ysp - y)
            dx = RND.uniform(-0.04, 0.04)
            caja(M, (x0 + dx + 0.015, y + 0.012, zb + 0.015), (x1 + dx - 0.015, y + h - 0.012, zf - 0.015),
                 jit(mezcla(elige(PR), ARENA_C, RND.uniform(0, 0.15)), 0.05))
            y += h
        # imposta (moldura del arranque)
        caja(M, (x0 - 0.12, ysp - 0.2, zb - 0.1), (x1 + 0.12, ysp, zf + 0.1), PR[2])
        M.caja_choque(x0 - 0.1, zb - 0.1, x1 + 0.1, zf + 0.1, ysp + 2.0)
    # dovelas y clave
    n = nq(11, 7)
    if n % 2 == 0:
        n += 1
    for k in range(n):
        a0 = math.pi * k / n + 0.008
        a1 = math.pi * (k + 1) / n - 0.008
        clave = k == n // 2
        c = PR[2] if clave else jit(mezcla(elige(PR), ARENA_C, 0.1), 0.05)
        dovela(M, ysp, ri, ro + (0.22 if clave else 0.0), a0, a1, zb - (0.06 if clave else 0.0), zf + (0.06 if clave else 0.0), c)
    # incrustación de vidrio en la clave (cara sur) y su gemela al norte
    incrustacion_rombo(M, (0, ysp + (ri + ro) * 0.5 + 0.08, zf + 0.06), (1, 0, 0), (0, 0, 1), 0.5, 0.3)
    incrustacion_rombo(M, (0, ysp + (ri + ro) * 0.5 + 0.08, zb - 0.06), (1, 0, 0), (0, 0, -1), 0.5, 0.3)
    # enjutas: hiladas de sillares hasta la cornisa; la esquina de arriba al este se ha caído
    ytop = ysp + ro + 0.5
    y = ysp
    fila = 0
    while y < ytop - 0.01:
        h = min(0.5, ytop - y)
        y1 = y + h
        if y1 <= ysp + ro:
            xa = math.sqrt(max(0.0, ro * ro - (y1 - ysp) ** 2))
            bloques_fila(M, -xe, -xa, y, y1, zb + 0.03, zf - 0.03, PR, largo=0.8)
            if not (fila >= 3):
                bloques_fila(M, xa, xe, y, y1, zb + 0.03, zf - 0.03, PR, largo=0.8)
            elif fila == 3:
                bloques_fila(M, xa, xa + 0.35, y, y1, zb + 0.03, zf - 0.03, PR, largo=0.8)
        else:
            bloques_fila(M, -xe, 0.55, y, y1, zb + 0.03, zf - 0.03, PR, largo=0.9)
        y = y1
        fila += 1
    # cornisa (solo queda la mitad oeste) con su vuelo
    caja(M, (-xe - 0.25, ytop, zb - 0.15), (0.2, ytop + 0.32, zf + 0.15), PR[2])
    caja(M, (-xe - 0.15, ytop + 0.32, zb - 0.05), (-0.3, ytop + 0.5, zf + 0.05), PR[1])
    # lo que se cayó: dos sillares de la enjuta y un trozo de cornisa, al este
    caja_t(M, (3.35, 0.2, 0.9), (0.85, 0.5, 1.1), (math.cos(0.4), 0.15, math.sin(0.4)), (0, 1, 0.1), PR[1])
    caja_t(M, (2.85, 0.12, 1.85), (0.7, 0.45, 0.9), (math.cos(-0.7), 0.0, math.sin(-0.7)), (0.3, 1, 0), PR[0])
    caja_t(M, (4.2, 0.08, -0.3), (1.5, 0.32, 1.25), (math.cos(1.2), -0.12, math.sin(1.2)), (0.1, 1, 0), PR[2])
    # cristales del Mar de Cristal al pie del pilar este
    cristales(M, (2.55, 0.0, 0.85), nq(5, 3), 0.9, 21)
    cristales(M, (-2.9, 0.0, -0.9), nq(3, 2), 0.55, 22)
    # arena: barlovento (oeste), dentro del vano y la cola de sotavento
    monticulo(A, (-2.9, 0.0, 0.2), 2.8, 2.3, 1.45, giro=0.1, semilla=1.0, oscuro=0.18)
    monticulo(A, (0.1, 0.0, 0.15), 1.6, 1.9, 0.75, giro=0.0, semilla=2.0, oscuro=0.12)
    monticulo(A, (3.1, 0.0, -0.5), 2.0, 1.3, 0.5, giro=-0.25, semilla=3.0, oscuro=0.1)
    ancla("clave", (0, ysp + ro, zf))


def tambor(M, y0, y1, r0, r1, lados, pal, giro, roto=None, semilla=0):
    """Tambor de columna estriado (caras alternas claras y oscuras); con «roto», la cara de arriba quebrada."""
    cols = [[mezcla(pal[1], (1, 1, 1), 0.05), mezcla(pal[0], (0, 0, 0), 0.05)]]
    if roto is None:
        tubo_curvo(M, [(0, y0, 0), (0, y1, 0)], [r0, r1], lados, [cols[0], cols[0]], plano=True, tapa_ini=False,
                   tapa_fin=True, giro=giro)
        return
    r = random.Random(semilla)
    abajo = [V(math.cos(2 * math.pi * k / lados + giro) * r0, y0, math.sin(2 * math.pi * k / lados + giro) * r0) for k in range(lados)]
    arriba = []
    for k in range(lados):
        a = 2 * math.pi * k / lados + giro
        hk = y1 - roto * (0.5 + 0.5 * math.sin(a * 1.7 + semilla)) * r.uniform(0.6, 1.0)
        arriba.append(V(math.cos(a) * r1, hk, math.sin(a) * r1))
    for k in range(lados):
        k2 = (k + 1) % lados
        cara(M, [abajo[k], abajo[k2], arriba[k2], arriba[k]], cols[0][k % 2], (abajo[k] + abajo[k2]) * 0.5)
    centro = sum(arriba, V(0, 0, 0)) / lados
    centro.y -= roto * 0.15
    for k in range(lados):
        cara(M, [arriba[k], arriba[(k + 1) % lados], centro], jit(mezcla(pal[2], ARENA_C, 0.3), 0.06), (0, 1, 0))


def columna_en_pie(M, alto, r, roto=None, capitel=True, semilla=0, pal=ARENISCA):
    lados = nq(12, 8)
    # plinto y basa (desde -1,5 m: enterrado)
    caja(M, (-r * 1.35, -1.5, -r * 1.35), (r * 1.35, 0.3, r * 1.35), pal[1])
    tubo(M, (0, 0.3, 0), (0, 0.48, 0), r * 1.22, r * 1.1, lados, pal[2], tapa_a=False)
    y = 0.48
    n_tambores = max(2, int(round((alto - 0.9) / 1.05)))
    paso = (alto - 0.9) / n_tambores
    for i in range(n_tambores):
        y1 = y + paso
        r0 = r * (1.0 - 0.08 * (y - 0.48) / alto)
        r1 = r * (1.0 - 0.08 * (y1 - 0.48) / alto)
        ultimo = i == n_tambores - 1
        if roto is not None and ultimo:
            tambor(M, y + 0.02, y1, r0, r1, lados, pal, i * 0.21, roto=roto, semilla=semilla)
            return y1
        tambor(M, y + 0.02, y1, r0, r1, lados, pal, i * 0.21 + RND.uniform(-0.05, 0.05))
        y = y1
    if capitel:
        tubo(M, (0, y, 0), (0, y + 0.18, 0), r * 0.94, r * 1.05, lados, pal[1], tapa_a=False)
        tubo(M, (0, y + 0.18, 0), (0, y + 0.42, 0), r * 1.05, r * 1.38, lados, pal[2], tapa_a=False)
        caja(M, (-r * 1.5, y + 0.42, -r * 1.5), (r * 1.5, y + 0.66, r * 1.5), pal[1])
        y += 0.66
    return y


def ruinas_columna_a(objs):
    """Columna entera (con capitel) y su arena."""
    M = nueva(objs, "ruinas_columna_a")
    A = nueva(objs, "ruinas_columna_a_arena")
    columna_en_pie(M, 4.8, 0.42)
    M.caja_choque(-0.6, -0.6, 0.6, 0.6, 4.0)
    monticulo(A, (-0.45, 0.0, 0.1), 1.6, 1.3, 0.75, semilla=4.0, oscuro=0.18)


def ruinas_columna_b(objs):
    """Columna rota a media altura; un tambor caído a su lado."""
    M = nueva(objs, "ruinas_columna_b")
    A = nueva(objs, "ruinas_columna_b_arena")
    columna_en_pie(M, 4.2, 0.42, roto=0.55, semilla=3)
    lados = nq(12, 8)
    # tambor caído, tumbado al este
    M.T = Matrix.Translation((1.35, 0.33, 0.55)) @ Matrix.Rotation(math.radians(84), 4, 'Z') @ Matrix.Rotation(0.5, 4, 'Y')
    tambor(M, -0.5, 0.5, 0.39, 0.38, lados, ARENISCA, 0.3)
    tubo(M, (0, -0.5, 0), (0, -0.48, 0), 0.39, 0.39, lados, ARENISCA[0], tapa_a=True, tapa_b=False)
    M.T = None
    M.caja_choque(-0.6, -0.6, 0.6, 0.6, 3.0)
    M.caja_choque(0.8, 0.1, 1.9, 1.0, 0.7)
    monticulo(A, (-0.4, 0.0, 0.0), 1.5, 1.2, 0.6, semilla=5.0, oscuro=0.18)
    monticulo(A, (1.3, 0.0, 0.7), 1.1, 0.8, 0.28, semilla=6.0)


def ruinas_columna_c(objs):
    """Columna caída: tres tambores rodados y el capitel en el suelo, medio enterrados (de oeste a este)."""
    M = nueva(objs, "ruinas_columna_c")
    A = nueva(objs, "ruinas_columna_c_arena")
    lados = nq(12, 8)
    r = 0.42
    xs = [(-2.2, 0.05, 0.10), (-1.05, 0.12, -0.06), (0.25, 0.45, 0.04)]
    for i, (x, gz, dy) in enumerate(xs):
        M.T = Matrix.Translation((x, r * 0.62 + dy, 0.0)) @ Matrix.Rotation(gz, 4, 'Y') @ Matrix.Rotation(math.radians(90), 4, 'Z')
        tambor(M, -0.52, 0.52, r, r * 0.97, lados, ARENISCA, i * 0.4)
        tubo(M, (0, -0.52, 0), (0, -0.5, 0), r, r, lados, ARENISCA[0], tapa_a=True, tapa_b=False)
        M.T = None
    # capitel volcado
    M.T = Matrix.Translation((1.75, 0.3, 0.35)) @ Matrix.Rotation(0.6, 4, 'Y') @ Matrix.Rotation(math.radians(70), 4, 'Z')
    tubo(M, (0, -0.2, 0), (0, 0.05, 0), r * 0.94, r * 1.38, lados, ARENISCA[2], tapa_a=True)
    caja(M, (-r * 1.5, 0.05, -r * 1.5), (r * 1.5, 0.3, r * 1.5), ARENISCA[1], abajo=True)
    M.T = None
    M.caja_choque(-2.8, -0.5, 2.3, 0.6, 0.8)
    monticulo(A, (-1.9, 0.0, -0.3), 1.6, 1.0, 0.42, semilla=7.0, oscuro=0.12)
    monticulo(A, (0.4, 0.0, -0.45), 1.4, 0.9, 0.36, semilla=8.0, oscuro=0.12)


def ruinas_columna_d(objs):
    """Tocón de columna vitrificado: del corte brotan cristales (el vidrio del Mar de Cristal)."""
    M = nueva(objs, "ruinas_columna_d")
    A = nueva(objs, "ruinas_columna_d_arena")
    top = columna_en_pie(M, 2.3, 0.44, roto=0.3, semilla=9)
    cristales(M, (0.0, top - 0.25, 0.0), nq(6, 4), 1.1, 31, radio=0.22, inclinacion=0.6)
    cristales(M, (0.65, 0.0, 0.45), nq(3, 2), 0.5, 32)
    M.caja_choque(-0.6, -0.6, 0.6, 0.6, 2.5)
    monticulo(A, (-0.3, 0.0, 0.2), 1.4, 1.2, 0.55, semilla=10.0, oscuro=0.18)


def trampilla(objs):
    """Trampilla sellada de piedra con incrustación de vidrio. «trampilla_tapa» tiene el origen en la bisagra (lado
    norte): para abrirla, girarla en x hacia -105°. Debajo, el hueco con tres escalones."""
    M = nueva(objs, "trampilla")
    T = nueva(objs, "trampilla_tapa", origen=(0.0, 0.06, -0.7))
    A = nueva(objs, "trampilla_arena")
    PR = ARENISCA
    hi, he = 0.7, 1.12                        # medio hueco y medio marco
    # marco: cuatro losas a ras de suelo
    for (x0, z0, x1, z1) in ((-he, -he, he, -hi), (-he, hi, he, he), (-he, -hi, -hi, hi), (hi, -hi, he, hi)):
        caja(M, (x0 + 0.01, -0.15, z0 + 0.01), (x1 - 0.01, 0.06, z1 - 0.01), jit(mezcla(PR[1], ARENA_C, 0.15), 0.04))
    # pequeñas piedras de apoyo en las esquinas, con vidrio
    for sx in (-1, 1):
        for sz in (-1, 1):
            caja(M, (sx * he - 0.14, -0.1, sz * he - 0.14), (sx * he + 0.14, 0.16, sz * he + 0.14), PR[2])
    cristales(M, (he + 0.25, 0.0, he - 0.1), nq(3, 2), 0.42, 41)
    # el hueco: paredes oscuras hacia dentro y tres escalones que bajan al norte
    hueco = mezcla(ARENISCA_OSC, OSCURO, 0.55)
    for (a, b, n) in (((-hi, -1.6, -hi), (hi, 0.0, -hi), (0, 0, 1)), ((-hi, -1.6, hi), (hi, 0.0, hi), (0, 0, -1)),
                      ((-hi, -1.6, -hi), (-hi, 0.0, hi), (1, 0, 0)), ((hi, -1.6, -hi), (hi, 0.0, hi), (-1, 0, 0))):
        if n[2] != 0:
            cara(M, [(a[0], a[1], a[2]), (b[0], a[1], a[2]), (b[0], b[1], a[2]), (a[0], b[1], a[2])], hueco, n)
        else:
            cara(M, [(a[0], a[1], a[2]), (a[0], a[1], b[2]), (a[0], b[1], b[2]), (a[0], b[1], a[2])], hueco, n)
    for i in range(3):
        y = -0.4 - i * 0.38
        z0 = 0.7 - i * 0.42
        caja(M, (-hi + 0.02, y - 0.38, z0 - 0.42), (hi - 0.02, y, z0), mezcla(ARENISCA_OSC, OSCURO, 0.3 + i * 0.15), caras="as")
    cara(M, [(-hi, -1.55, -hi), (hi, -1.55, -hi), (hi, -1.55, hi), (-hi, -1.55, hi)], OSCURO, (0, 1, 0))
    # la tapa (coordenadas del mundo; el objeto se mueve a la bisagra al exportar)
    lt = hi - 0.02
    caja(T, (-lt, -0.08, -lt), (lt, 0.06, lt), PR[1], abajo=True)
    for (x0, z0, x1, z1) in ((-lt, -lt, lt, -lt + 0.13), (-lt, lt - 0.13, lt, lt), (-lt, -lt + 0.13, -lt + 0.13, lt - 0.13),
                             (lt - 0.13, -lt + 0.13, lt, lt - 0.13)):
        caja(T, (x0, 0.06, z0), (x1, 0.11, z1), PR[2])
    # la estrella de vidrio: dos cuadrados girados y el ojo de la cerradura (lente oscura con borde de vidrio)
    for giro in (0.0, math.pi / 4):
        pts = [V(math.cos(giro + math.pi / 2 * k) * 0.42, 0.075, math.sin(giro + math.pi / 2 * k) * 0.42) for k in range(4)]
        centro = V(0, 0.1, 0)
        for k in range(4):
            cara(T, [pts[k], pts[(k + 1) % 4], centro], jit(mezcla(VIDRIO_C, (1, 1, 1), 0.15 * (k % 2)), 0.03), (0, 1, 0), VIDRIO)
    lados = nq(10, 6)
    anillo = [V(math.cos(2 * math.pi * k / lados) * 0.15, 0.11, math.sin(2 * math.pi * k / lados) * 0.09) for k in range(lados)]
    interior = [V(p.x * 0.6, 0.112, p.z * 0.45) for p in anillo]
    for k in range(lados):
        k2 = (k + 1) % lados
        cara(T, [anillo[k], anillo[k2], interior[k2], interior[k]], mezcla(VIDRIO_C, (1, 1, 1), 0.35), (0, 1, 0), VIDRIO)
    cara(T, interior, OSCURO, (0, 1, 0))
    # la argolla de hierro, al sur
    segs = nq(8, 6)
    for k in range(segs):
        a0, a1 = math.pi * k / segs, math.pi * (k + 1) / segs
        p0 = V(math.cos(a0) * 0.16, 0.115, lt - 0.06 + math.sin(a0) * 0.12)
        p1 = V(math.cos(a1) * 0.16, 0.115, lt - 0.06 + math.sin(a1) * 0.12)
        tubo(T, p0, p1, 0.025, 0.025, 4, HIERRO, tapa_a=False, tapa_b=False)
    # un poco de arena sobre el marco (oeste)
    monticulo(A, (-1.25, 0.0, 0.2), 0.9, 1.3, 0.22, semilla=11.0, oscuro=0.1)
    ancla("bisagra", (0.0, 0.06, -0.7))
    ancla("hueco", (0.0, -1.55, 0.0))


def ruinas_muro(objs):
    """Tramo de muro bajo derruido (para componer las ruinas)."""
    M = nueva(objs, "ruinas_muro")
    A = nueva(objs, "ruinas_muro_arena")
    perfil = [1.7, 1.4, 1.55, 1.1, 0.8, 0.95, 0.5, 0.35]
    x = -2.4
    for i, h in enumerate(perfil):
        y = -0.8
        fila = 0
        while y < h - 0.01:
            hh = min(0.42, h - y)
            if i % 2 == 0 or fila % 2 == 0:
                bloques_fila(M, x, x + 0.62, y, y + hh, -0.35, 0.35, ARENISCA, largo=0.62)
            else:
                bloques_fila(M, x - 0.25, x + 0.35, y, y + hh, -0.35, 0.35, ARENISCA, largo=0.6)
            y += hh
            fila += 1
        x += 0.62
    M.caja_choque(-2.4, -0.4, 2.6, 0.4, 1.7)
    caja_t(M, (3.1, 0.15, 0.6), (0.6, 0.4, 0.7), (1, 0, 0.4), (0, 1, 0), ARENISCA[1])
    monticulo(A, (-1.6, 0.0, 0.25), 1.8, 1.1, 0.8, semilla=12.0, oscuro=0.18)
    monticulo(A, (1.6, 0.0, -0.2), 1.6, 0.9, 0.35, semilla=13.0, oscuro=0.12)


# ================================================================= caravana

def rueda(M, centro, eje, radio, color, n_radios=8, ancho=0.08, rotos=()):
    c = V(centro)
    e = V(eje).normalized()
    u, w = marco(e)
    segs = nq(14, 9)
    for k in range(segs):
        if k in rotos:
            continue
        a0, a1 = 2 * math.pi * k / segs, 2 * math.pi * (k + 1) / segs
        p0 = c + (u * math.cos(a0) + w * math.sin(a0)) * radio
        p1 = c + (u * math.cos(a1) + w * math.sin(a1)) * radio
        mid = (p0 + p1) * 0.5
        caja_t(M, mid, ((p1 - p0).length + 0.02, 0.09, ancho), p1 - p0, mid - c, color)
        if k % 2 == 0:                                   # llanta de hierro
            caja_t(M, mid + (mid - c).normalized() * 0.05, ((p1 - p0).length + 0.02, 0.02, ancho * 0.8), p1 - p0, mid - c, OXIDO)
    tubo(M, c - e * 0.12, c + e * 0.12, 0.11, 0.11, 6, MADERA_OSC)
    for k in range(nq(n_radios, 6)):
        a = 2 * math.pi * (k + 0.5) / nq(n_radios, 6)
        if any(abs(a - 2 * math.pi * (r + 0.5) / segs) < 0.4 for r in rotos):
            continue
        d = u * math.cos(a) + w * math.sin(a)
        caja_t(M, c + d * radio * 0.5, (0.05, radio * 0.82, 0.05), e, d, mezcla(color, (0, 0, 0), 0.1))


def caravana_carro(objs):
    """Carro volcado de lado, medio enterrado: la caja mira al sur (se ve lo que llevaba) y las ruedas de arriba quedan
    tumbadas, una rota. Lo que fue la lona, rota, en «caravana_carro_tela»."""
    M = nueva(objs, "caravana_carro")
    Tl = nueva(objs, "caravana_carro_tela")
    A = nueva(objs, "caravana_carro_arena")
    T = Matrix.Translation((0.0, 0.62, 0.15)) @ Matrix.Rotation(math.radians(-14), 4, 'Y') @ Matrix.Rotation(math.radians(82), 4, 'X')
    M.T = T
    Tl.T = T
    L, W = 1.6, 0.72
    yf = 0.55
    # suelo de tablas
    n = nq(7, 4)
    for i in range(n):
        x0 = -L + 2 * L * i / n
        caja(M, (x0 + 0.01, yf - 0.06, -W), (x0 + 2 * L / n - 0.01, yf, W), jit(MADERA_GRIS, 0.08), abajo=True)
    # laterales y testeros
    for s in (-1, 1):
        for j in range(2):
            caja(M, (-L, yf + j * 0.24, s * W - 0.03), (L, yf + j * 0.24 + 0.22, s * W + 0.03), jit(MADERA_SECA, 0.08))
        for x in (-L + 0.05, -0.5, 0.5, L - 0.05):
            caja(M, (x - 0.05, yf - 0.1, s * W - 0.06), (x + 0.05, yf + 0.52, s * W + 0.06), MADERA_OSC)
    caja(M, (L - 0.04, yf, -W), (L + 0.04, yf + 0.5, W), MADERA_SECA)
    caja(M, (-L - 0.04, yf, -W), (-L + 0.04, yf + 0.32, W * 0.2), MADERA_SECA)             # testero trasero, roto
    # ejes y ruedas (las del lado de arriba; las de abajo, aplastadas bajo la arena)
    for x in (-1.0, 1.0):
        caja(M, (x - 0.06, yf - 0.2, -W - 0.15), (x + 0.06, yf - 0.08, W + 0.15), MADERA_OSC)
    rueda(M, (-1.0, yf - 0.14, -W - 0.2), (0, 0, 1), 0.5, MADERA_SECA)
    rueda(M, (1.0, yf - 0.14, -W - 0.2), (0, 0, 1), 0.5, MADERA_SECA, rotos=(2, 3, 4, 5) if Q >= 1 else (1, 2, 3))
    # lanza
    caja_t(M, (L + 0.9, yf - 0.1, 0.0), (1.9, 0.09, 0.09), (1, 0.08, 0.0), (0, 1, 0), MADERA_SECA)
    # aros de la lona (dos enteros y uno partido) y lo que queda de la lona
    for xi, entero in ((-1.1, True), (0.0, True), (1.1, False)):
        segs = nq(9, 6)
        pts = []
        for k in range(segs + 1):
            a = math.pi * k / segs
            if not entero and k > segs * 0.55:
                break
            pts.append(V(xi, yf + 0.5 + math.sin(a) * 0.9, math.cos(a) * W))
        for k in range(len(pts) - 1):
            tubo(M, pts[k], pts[k + 1], 0.03, 0.03, 4, MADERA_GRIS, tapa_a=False, tapa_b=False)
    # lona: un jirón colgado entre el primer y el segundo aro (el borde libre se mueve)
    nx, ny = nq(6, 4), nq(5, 3)
    rejilla = []
    for i in range(nx + 1):
        fila = []
        x = -1.1 + 1.1 * i / nx
        for j in range(ny + 1):
            t = j / ny
            a = math.pi * (0.15 + 0.5 * t)
            caida = 0.25 * math.sin(math.pi * i / nx) * t
            corte = 0.0 if (i % 3) else 0.2 * t
            fila.append((V(x, yf + 0.5 + math.sin(a) * (0.88 - caida) - corte, math.cos(a) * (W - 0.02)),
                         min(1.0, 0.15 + t * 0.9 + 0.4 * math.sin(math.pi * i / nx) * t)))
        rejilla.append(fila)
    for i in range(nx):
        for j in range(ny):
            if j == ny - 1 and i % 3 == 1:
                continue                                  # desgarros del borde
            q = [rejilla[i][j], rejilla[i + 1][j], rejilla[i + 1][j + 1], rejilla[i][j + 1]]
            c = jit(mezcla(TELA_CREMA, ARENA_C, 0.3), 0.06)
            cara(Tl, [p for p, _ in q], c, None, TELA, [wv for _, wv in q])
    # sacos que se salen de la caja
    for k, (x, z) in enumerate(((-0.8, 0.0), (0.2, 0.25), (0.9, -0.2))):
        bulto(M, (x, yf + 0.25, z), 0.32, (1.3, 0.75, 1.0), 1 if Q >= 1 else 0, 0.2, jit(SACO, 0.08), k * 3.1)
    M.T = None
    Tl.T = None
    # granos derramados (montoncito ocre) y arena
    bulto(M, (0.6, 0.0, 1.45), 0.45, (1.6, 0.25, 1.0), 1 if Q >= 1 else 0, 0.3, (0.82, 0.62, 0.30), 5.0, y_min=-0.02)
    monticulo(A, (-1.2, 0.0, -1.0), 2.4, 1.6, 0.95, giro=0.3, semilla=14.0, oscuro=0.2)
    monticulo(A, (1.4, 0.0, -0.7), 1.6, 1.2, 0.6, giro=-0.2, semilla=15.0, oscuro=0.15)
    M.caja_choque(-1.8, -1.2, 1.9, 0.9, 1.6)


def cajon_desierto(M, base, tam, giro=0.0, abierto=False, semilla=0):
    b = V(base)
    sx, sy, sz = tam
    M.T = Matrix.Translation(b) @ Matrix.Rotation(giro, 4, 'Y')
    c = jit(MADERA_SECA, 0.06)
    caras = "nseo" if abierto else "nseoa"
    caja(M, (-sx / 2, 0, -sz / 2), (sx / 2, sy, sz / 2), c, caras=caras)
    for s in (-1, 1):                                    # flejes
        caja(M, (-sx / 2 - 0.01, sy * 0.15, s * sz / 2 - 0.005), (sx / 2 + 0.01, sy * 0.25, s * sz / 2 + 0.005 * s),
             MADERA_OSC, caras="ns")
    for xx in (-sx / 2, sx / 2):
        caja(M, (xx - 0.03, 0, -sz / 2 - 0.02), (xx + 0.03, sy + 0.01, -sz / 2 + 0.04), MADERA_OSC)
        caja(M, (xx - 0.03, 0, sz / 2 - 0.04), (xx + 0.03, sy + 0.01, sz / 2 + 0.02), MADERA_OSC)
    if abierto:
        cara(M, [(-sx / 2, sy * 0.55, -sz / 2), (sx / 2, sy * 0.55, -sz / 2), (sx / 2, sy * 0.55, sz / 2), (-sx / 2, sy * 0.55, sz / 2)],
             mezcla(MADERA_OSC, OSCURO, 0.3), (0, 1, 0))
        # la tapa, caída al lado
        caja_t(M, (sx * 0.15, 0.05, sz * 0.5 + 0.35), (sx * 0.95, 0.05, sz * 0.8), (1, 0, 0.2), (0, 1, 0), c)
    M.T = None


def anfora(M, base, alto, giro_tumbada=None, color=BARRO, rota=False):
    b = V(base)
    lados = nq(9, 6)
    perfil = [(0.0, 0.10), (0.1, 0.22), (0.35, 0.30), (0.62, 0.26), (0.82, 0.12), (0.9, 0.09), (1.0, 0.11)]
    if rota:
        perfil = perfil[:4]
    pts = [V(0, alto * t, 0) for t, _ in perfil]
    rs = [alto * r for _, r in perfil]
    if giro_tumbada is not None:
        M.T = Matrix.Translation(b + V(0, alto * 0.27, 0)) @ Matrix.Rotation(giro_tumbada, 4, 'Y') @ Matrix.Rotation(math.radians(95), 4, 'Z')
    else:
        M.T = Matrix.Translation(b)
    cols = [jit(color, 0.05) if i != 2 else mezcla(color, (0.95, 0.88, 0.70), 0.5) for i in range(len(pts))]
    tubo_curvo(M, pts, rs, lados, cols, plano=True, tapa_ini=True, tapa_fin=True)
    M.T = None


def caravana_cajas(objs):
    """Cajas de la caravana (una abierta y vacía), un saco y ánforas, una rota."""
    M = nueva(objs, "caravana_cajas")
    A = nueva(objs, "caravana_cajas_arena")
    cajon_desierto(M, (-0.55, -0.12, 0.0), (0.9, 0.62, 0.65), 0.25)
    cajon_desierto(M, (-0.45, 0.5, 0.05), (0.7, 0.5, 0.55), 0.6)
    cajon_desierto(M, (0.75, -0.05, 0.35), (0.85, 0.55, 0.6), -0.4, abierto=True)
    bulto(M, (0.25, 0.22, -0.55), 0.36, (1.0, 0.7, 1.25), 1 if Q >= 1 else 0, 0.2, jit(SACO, 0.06), 2.2)
    anfora(M, (1.55, 0.0, -0.3), 0.75)
    anfora(M, (0.1, 0.0, 0.95), 0.7, giro_tumbada=0.7, rota=True)
    for k in range(nq(4, 2)):                               # tiestos
        caja_t(M, (0.4 + 0.25 * k, 0.03, 1.25 + 0.1 * (k % 2)), (0.16, 0.04, 0.11), (math.cos(k), 0, math.sin(k)), (0, 1, 0), BARRO)
    monticulo(A, (-0.8, 0.0, -0.3), 1.4, 1.0, 0.45, semilla=16.0, oscuro=0.2)
    M.caja_choque(-1.0, -0.5, 1.2, 0.8, 1.1)


def caravana_barril(objs):
    """Barril volcado, medio enterrado (y su aro suelto)."""
    M = nueva(objs, "caravana_barril")
    A = nueva(objs, "caravana_barril_arena")
    lados = nq(10, 7)
    r, h = 0.32, 0.8
    M.T = Matrix.Translation((0.0, r * 0.75, 0.0)) @ Matrix.Rotation(0.5, 4, 'Y') @ Matrix.Rotation(math.radians(90), 4, 'Z') @ Matrix.Translation((0, -h / 2, 0))
    duelas = [[jit(MADERA_SECA, 0.1), jit(MADERA_GRIS, 0.08)]]
    tubo_curvo(M, [(0, 0, 0), (0, h * 0.5, 0), (0, h, 0)], [r * 0.9, r, r * 0.9], lados, duelas * 3, plano=True,
               tapa_ini=True, tapa_fin=False)
    for t in (0.15, 0.85):
        tubo(M, (0, h * t - 0.025, 0), (0, h * t + 0.025, 0), r * 0.97 + 0.012, r * 0.97 + 0.012, lados, OXIDO, tapa_a=False, tapa_b=False)
    pts = [V(math.cos(2 * math.pi * k / lados) * r * 0.86, h - 0.03, math.sin(2 * math.pi * k / lados) * r * 0.86) for k in range(lados)]
    cara(M, pts, mezcla(MADERA_OSC, OSCURO, 0.4), (0, 1, 0))
    M.T = None
    monticulo(A, (-0.35, 0.0, -0.2), 1.0, 0.75, 0.35, semilla=17.0, oscuro=0.2)
    M.caja_choque(-0.5, -0.45, 0.5, 0.45, 0.6)


def caravana_tela(objs):
    """Estandarte roto de la caravana: una pértiga clavada en la arena y la tela desgarrada que ondea."""
    M = nueva(objs, "caravana_tela")
    T = nueva(objs, "caravana_tela_tela")
    A = nueva(objs, "caravana_tela_arena")
    base, cima = V(0.0, -0.4, 0.0), V(0.35, 2.3, -0.1)
    tubo(M, base, cima, 0.045, 0.035, 5, MADERA_SECA)
    eje = (cima - base).normalized()
    trav = cima - eje * 0.15
    caja_t(M, trav + V(0.45, 0.0, 0.0), (1.0, 0.05, 0.05), (1, 0, 0), (0, 1, 0), MADERA_SECA)
    nx, ny = nq(5, 3), nq(7, 4)
    largo = [1.4, 1.2, 0.8, 1.1, 0.6, 0.9]
    for i in range(nx):
        for j in range(ny):
            l0 = largo[i % len(largo)]
            l1 = largo[(i + 1) % len(largo)]
            t0, t1 = j / ny, (j + 1) / ny
            if t1 * 1.4 > max(l0, l1) + 0.1:
                continue
            x0, x1 = trav.x - 0.02 + 0.9 * i / nx, trav.x - 0.02 + 0.9 * (i + 1) / nx
            y0, y1 = trav.y - 0.03 - t0 * 1.4, trav.y - 0.03 - t1 * 1.4
            z = trav.z
            banda = TELA_ROJA if 0.35 < (t0 + t1) * 0.5 < 0.55 else mezcla(TELA_OCRE, TELA_CREMA, 0.25)
            q = [V(x0, y0, z), V(x1, y0, z), V(x1, y1, z), V(x0, y1, z)]
            pesos = [min(1.0, t0 * 1.3 + 0.1), min(1.0, t0 * 1.3 + 0.1), min(1.0, t1 * 1.3 + 0.1), min(1.0, t1 * 1.3 + 0.1)]
            cara(T, q, jit(banda, 0.05), (0, 0, 1), TELA, pesos)
    # un trapo enganchado en el suelo
    for k in range(3):
        a = 0.7 + k * 0.5
        p0 = V(0.6 + 0.3 * k, 0.02, 0.5)
        cara(T, [p0, p0 + V(0.35, 0.0, 0.05), p0 + V(0.3 + 0.1 * math.cos(a), 0.06, 0.4), p0 + V(0.0, 0.03, 0.35)],
             jit(TELA_CREMA, 0.05), (0, 1, 0), TELA, [0.0, 0.2, 0.7, 0.4])
    monticulo(A, (0.0, 0.0, 0.0), 0.8, 0.7, 0.3, semilla=18.0, oscuro=0.15)


# ================================================================= campamento

def tela_rejilla(T, P, nu, nv, color, peso, cara_hacia=None):
    """Tela de nu×nv celdas: P(u, v) → punto; color(u, v) → color; peso(u, v) → cuánto se mueve. Vértices propios por
    celda (color plano, rayas nítidas)."""
    for i in range(nu):
        for j in range(nv):
            uv = [(i / nu, j / nv), ((i + 1) / nu, j / nv), ((i + 1) / nu, (j + 1) / nv), (i / nu, (j + 1) / nv)]
            pts = [P(u, v) for u, v in uv]
            c = color((i + 0.5) / nu, (j + 0.5) / nv)
            h = cara_hacia(pts) if cara_hacia else None
            cara(T, pts, jit(c, 0.03), h, TELA, [peso(u, v) for u, v in uv])


def tienda_a(objs):
    """Jaima grande de rayas: cumbrera este-oeste a 2,7 m, faldones a dos aguas, el frente (sur) levantado como toldo,
    la pared del norte hasta el suelo y la del este recogida. Alfombra, cojines y farolillo a la entrada."""
    M = nueva(objs, "tienda_a")
    T = nueva(objs, "tienda_a_tela")
    LX, LZ = 2.1, 1.6
    yc, ye_s, ye_n = 2.7, 1.8, 1.45
    # postes
    for x in (-1.5, 1.5):
        tubo(M, (x, -0.2, 0), (x, yc + 0.12, 0), 0.06, 0.05, 6, MADERA_SECA)
    for x in (-LX, 0.0, LX):
        tubo(M, (x, -0.2, LZ), (x, ye_s + 0.06, LZ), 0.045, 0.04, 5, MADERA_SECA)
        tubo(M, (x, -0.2, -LZ), (x, ye_n + 0.06, -LZ), 0.045, 0.04, 5, MADERA_SECA)
    # vientos (cuerdas) y estacas
    for x in (-LX, LX):
        for z, y in ((LZ, ye_s), (-LZ, ye_n)):
            p0 = V(x, y, z)
            p1 = V(x * 1.45, 0.0, z * 1.6)
            caja_t(M, (p0 + p1) * 0.5, ((p1 - p0).length, 0.018, 0.018), p1 - p0, (0, 1, 0), CUERDA)
            caja_t(M, p1 + V(0, 0.08, 0), (0.05, 0.22, 0.05), (1, 0, 0), (0, 1, 0), MADERA_OSC)

    rayas = lambda u, v: TELA_ROJA if int(u * 10) % 2 == 0 else TELA_CREMA
    nu, nv = nq(10, 6), nq(5, 3)

    def onda(u):                                    # entre poste y poste la tela cede
        return abs(math.sin(math.pi * u * 2))

    def faldon(z_alero, y_alero):
        def P(u, v):
            x = -LX + 2 * LX * u
            yr = yc - 0.18 * onda(u) * (1 - v)       # la cumbrera se comba entre los postes
            y = yr + (y_alero - yr) * v - 0.22 * math.sin(math.pi * v) * (0.6 + 0.4 * onda(u))
            y -= 0.12 * onda(u) * v
            return V(x, y, z_alero * v)
        return P

    peso = lambda u, v: min(1.0, math.sin(math.pi * v) * (0.35 + 0.65 * onda(u)) + 0.25 * v * onda(u))
    arriba = lambda pts: (0, 1, 0)
    tela_rejilla(T, faldon(LZ, ye_s), nu, nv, rayas, peso, arriba)
    tela_rejilla(T, faldon(-LZ, ye_n), nu, nv, rayas, peso, arriba)
    # cenefa del frente (cuelga 0,35 m con flecos en dientes): borde libre, se mueve mucho
    n = nq(12, 7)
    for i in range(n):
        x0, x1 = -LX + 2 * LX * i / n, -LX + 2 * LX * (i + 1) / n
        ya0 = ye_s - 0.12 * onda(i / n)
        ya1 = ye_s - 0.12 * onda((i + 1) / n)
        diente = 0.45 if i % 2 == 0 else 0.3
        pts = [V(x0, ya0, LZ + 0.01), V(x1, ya1, LZ + 0.01), V((x0 + x1) * 0.5, (ya0 + ya1) * 0.5 - diente, LZ + 0.02)]
        cara(T, pts, jit(TELA_ANIL if i % 2 else TELA_OCRE, 0.04), (0, 0, 1), TELA, [0.3, 0.3, 1.0])
    # pared del norte (del alero al suelo)
    def pared_n(u, v):
        x = -LX + 2 * LX * u
        y = ye_n - 0.12 * onda(u) + (-0.05 - ye_n) * v
        return V(x, y, -LZ - 0.3 * v - 0.08 * math.sin(math.pi * v))
    tela_rejilla(T, pared_n, nu, nq(3, 2), lambda u, v: mezcla(TELA_CREMA, ARENA_C, 0.2) if v < 0.75 else TELA_ROJA,
                 lambda u, v: math.sin(math.pi * v) * (0.3 + 0.7 * onda(u)) * 0.8, lambda pts: (0, 0, -1))
    # pared del oeste: triángulo de la cumbrera al suelo; la del este, recogida (rollo) bajo el alero
    def pared_o(u, v):
        z = -LZ + 2 * LZ * u
        ytop = yc - (yc - (ye_s if z > 0 else ye_n)) * abs(z) / LZ
        return V(-LX - 0.25 * v, ytop + (-0.05 - ytop) * v, z * (1 + 0.12 * v))
    tela_rejilla(T, pared_o, nq(6, 4), nq(3, 2), lambda u, v: TELA_CREMA if v < 0.7 else TELA_ROJA,
                 lambda u, v: math.sin(math.pi * v) * math.sin(math.pi * u) * 0.9, lambda pts: (-1, 0, 0))
    tubo(M, (LX + 0.05, ye_s - 0.25, LZ - 0.1), (LX + 0.05, ye_n - 0.2, -LZ + 0.1), 0.11, 0.11, 6, TELA_CREMA)
    # alfombra (rombos), cojines, arcón y farolillo
    nx, nz = 6, 4
    for i in range(nx):
        for j in range(nz):
            borde = i in (0, nx - 1) or j in (0, nz - 1)
            c = TELA_OCRE if borde else (TELA_ROJA if (i + j) % 2 else TELA_ANIL)
            x0, z0 = -1.3 + 2.6 * i / nx, -0.2 + 1.9 * j / nz
            cara(M, [(x0, 0.02, z0), (x0 + 2.6 / nx, 0.02, z0), (x0 + 2.6 / nx, 0.02, z0 + 1.9 / nz), (x0, 0.02, z0 + 1.9 / nz)],
                 jit(c, 0.04), (0, 1, 0))
    for k, (x, z, c) in enumerate(((-0.9, -0.6, TELA_TURQUESA), (-0.2, -0.75, TELA_OCRE), (0.6, -0.65, TELA_ROJA))):
        bulto(M, (x, 0.16, z), 0.28, (1.2, 0.55, 0.9), 1 if Q >= 1 else 0, 0.12, jit(c, 0.05), k * 2.0)
    caja(M, (1.1, 0.0, -1.3), (1.8, 0.5, -0.85), MADERA_SECA)
    caja(M, (1.08, 0.5, -1.32), (1.82, 0.56, -0.83), MADERA_OSC)
    caja(M, (0.2, 1.42, 1.53), (0.3, ye_s - 0.1, 1.55), HIERRO)
    caja(M, (0.13, 1.18, 1.48), (0.37, 1.42, 1.62), LUZ_FAROL, BRILLO, jitter=0)
    caja(M, (0.11, 1.42, 1.46), (0.39, 1.47, 1.64), HIERRO)
    M.caja_choque(-LX, -LZ, LX, -LZ + 0.4, 1.4)
    M.caja_choque(-LX - 0.3, -LZ, -LX + 0.1, LZ, 1.4)
    ancla("farol", (0.25, 1.3, 1.55))
    ancla("entrada", (0.0, 0.0, LZ + 0.5))


def tienda_b(objs):
    """Tienda cónica pequeña (añil con franja ocre), puerta al sur con las solapas recogidas y un banderín en lo alto."""
    M = nueva(objs, "tienda_b")
    T = nueva(objs, "tienda_b_tela")
    R, H = 1.45, 2.4
    tubo(M, (0, -0.2, 0), (0, H + 0.45, 0), 0.05, 0.035, 6, MADERA_SECA)
    lados = nq(14, 9)
    anillos = nq(4, 3)
    puerta = {lados // 4 - 1, lados // 4} if lados >= 12 else {lados // 4}
    # el sur es +z: en ángulo, sin(a)=1 → a = 90° (k = lados/4)

    def P(k, j):
        a = 2 * math.pi * k / lados
        v = j / anillos
        r = R * v * (1 + 0.06 * math.sin(math.pi * v))
        y = H - (H + 0.05) * v + 0.06 * math.sin(math.pi * v)
        return V(math.cos(a) * r, y, math.sin(a) * r)

    for k in range(lados):
        if k in puerta:
            continue
        for j in range(anillos):
            q = [P(k, j), P(k + 1, j), P(k + 1, j + 1), P(k, j + 1)]
            vm = (j + 0.5) / anillos
            c = TELA_OCRE if 0.55 < vm < 0.8 else (TELA_CREMA if vm > 0.85 else TELA_ANIL)
            ws = [math.sin(math.pi * (jj / anillos)) * 0.7 for jj in (j, j, j + 1, j + 1)]
            pts = [p for p in q]
            if j == 0:
                pts = [q[0], q[2], q[3]]
                ws = [ws[0], ws[2], ws[3]]
            cara(T, pts, jit(c, 0.04), (math.cos(2 * math.pi * (k + 0.5) / lados), 0.4, math.sin(2 * math.pi * (k + 0.5) / lados)), TELA, ws)
    # solapas de la puerta, recogidas a los lados (bordes libres)
    kp0, kp1 = min(puerta), max(puerta) + 1
    for kk, s in ((kp0, -1), (kp1, 1)):
        top = P(kk, 1)
        bot = P(kk, anillos)
        afuera = V(bot.x, 0, bot.z).normalized()
        lado = V(-afuera.z, 0, afuera.x) * s
        p2 = bot + lado * 0.35 + afuera * 0.25 + V(0, 0.15, 0)
        cara(T, [top, bot, p2], jit(TELA_ANIL, 0.04), afuera, TELA, [0.1, 0.3, 1.0])
    # suelo oscuro dentro (se ve por la puerta)
    cara(M, [V(math.cos(2 * math.pi * k / 8) * R * 0.9, 0.015, math.sin(2 * math.pi * k / 8) * R * 0.9) for k in range(8)],
         mezcla(TELA_ANIL, OSCURO, 0.6), (0, 1, 0))
    # banderín
    top = V(0, H + 0.45, 0)
    n = nq(4, 3)
    for i in range(n):
        t0, t1 = i / n, (i + 1) / n
        q = [top + V(0.6 * t0, -0.03 - 0.11 * t0, 0), top + V(0.6 * t1, -0.03 - 0.11 * t1, 0),
             top + V(0.6 * t1, -0.25 + 0.11 * t1, 0), top + V(0.6 * t0, -0.25 + 0.11 * t0, 0)]
        cara(T, q, jit(TELA_ROJA, 0.04), (0, 0, 1), TELA, [t0, t1, t1, t0])
    # estacas, vientos, un hato y un odre
    for k in range(nq(6, 4)):
        a = 2 * math.pi * (k + 0.3) / nq(6, 4)
        p0 = V(math.cos(a) * R * 0.98, 0.05, math.sin(a) * R * 0.98)
        caja_t(M, p0 + V(math.cos(a), 0, math.sin(a)) * 0.12, (0.05, 0.2, 0.05), (1, 0, 0), (0, 1, 0), MADERA_OSC)
    bulto(M, (1.1, 0.14, 1.25), 0.3, (1.4, 0.45, 0.6), 0, 0.15, jit(TELA_CREMA, 0.05), 1.0)
    bulto(M, (-1.25, 0.18, 1.05), 0.22, (0.8, 1.0, 0.7), 0, 0.15, jit(CUERO, 0.05), 2.0)
    M.caja_choque(-R, -R, R, R * 0.4, 1.8)
    ancla("entrada", (0.0, 0.0, R + 0.4))


def fogata(objs):
    """Fogata del campamento: corro de piedras, ceniza, leños en pirámide, brasas y un trébede con su olla. El fuego
    (llama y humo) lo pone la región en «ancla_fuego»."""
    M = nueva(objs, "fogata")
    n = nq(10, 7)
    for k in range(n):
        a = 2 * math.pi * k / n + RND.uniform(-0.1, 0.1)
        bulto(M, (math.cos(a) * 0.62, 0.06, math.sin(a) * 0.62), 0.16, (1.2, 0.8, 1.0), 0, 0.3,
              jit(elige(PIEDRA_FUEGO), 0.08), k * 1.7)
    cara(M, [V(math.cos(2 * math.pi * k / 10) * 0.52, 0.015, math.sin(2 * math.pi * k / 10) * 0.52) for k in range(10)], CENIZA, (0, 1, 0))
    for k in range(4):
        a = 2 * math.pi * k / 4 + 0.4
        p0 = V(math.cos(a) * 0.42, 0.03, math.sin(a) * 0.42)
        tubo(M, p0, V(math.cos(a) * 0.04, 0.42, math.sin(a) * 0.04), 0.05, 0.035, 5, [mezcla(MADERA_OSC, OSCURO, 0.3)] * 2)
    for k in range(nq(6, 3)):
        a = 2 * math.pi * k / 6 + 0.2
        bulto(M, (math.cos(a) * 0.2, 0.05, math.sin(a) * 0.2), 0.08, (1.3, 0.6, 1.0), 0, 0.3, elige(BRASA), k * 0.9, mat=BRILLO)
    # trébede y olla
    cima = V(0.0, 1.15, 0.0)
    for k in range(3):
        a = 2 * math.pi * k / 3 + 0.5
        tubo(M, V(math.cos(a) * 0.75, 0.0, math.sin(a) * 0.75), cima, 0.025, 0.02, 4, MADERA_SECA, tapa_a=False)
    caja(M, (-0.008, 0.62, -0.008), (0.008, 1.15, 0.008), HIERRO, caras="seo")
    tubo_curvo(M, [(0, 0.38, 0), (0, 0.44, 0), (0, 0.58, 0), (0, 0.62, 0)], [0.12, 0.18, 0.17, 0.14], nq(8, 6),
               [HIERRO, HIERRO, OXIDO, HIERRO], plano=True, tapa_ini=True, tapa_fin=True)
    ancla("fuego", (0.0, 0.18, 0.0))


# ================================================================= oasis

def fronda(H, base, ang, largo, caida, ancho, n, pal, seca=False, semilla=0, elev=0.35):
    """Hoja de palmera: nervio que sube y cae, con foliolos en dientes de sierra a los dos lados (doble cara)."""
    r = random.Random(semilla)
    b = V(base)
    d = V(math.cos(ang), 0, math.sin(ang))
    lado = V(-d.z, 0, d.x)
    mids = []
    for i in range(n + 1):
        t = i / n
        if seca:
            p = b + d * (largo * 0.35 * t) + V(0, -largo * 0.95 * t + largo * 0.1 * t * t, 0)
        else:
            p = b + d * (largo * t) + V(0, largo * (elev * t - caida * t * t), 0)
        mids.append(p)
    for i in range(n):
        t0, t1 = i / n, (i + 1) / n
        for s in (-1, 1):
            def punta(i_, t):
                p = mids[i_]
                tang = (mids[min(i_ + 1, n)] - mids[max(i_ - 1, 0)]).normalized()
                lat = lado * s
                if seca:
                    lat = (lado * s * 0.4 + V(0, 0, 0)).normalized() if lado.length > 0 else lat
                w = ancho * (math.sin(math.pi * min(1.0, t * 1.05 + 0.04)) ** 0.7) * (0.75 if i_ % 2 else 1.0)
                return p + lat * w + tang * w * 0.45 + V(0, -w * (0.55 if not seca else 0.2), 0)
            q = [mids[i], mids[i + 1], punta(i + 1, t1), punta(i, t0)]
            c0 = mezcla(pal[0], pal[1], t0) if not seca else pal[0]
            c1 = mezcla(pal[1], pal[2], t1 * t1) if not seca else pal[1]
            cols = [c0, c1, mezcla(c1, (1, 1, 1), 0.08), mezcla(c0, (1, 1, 1), 0.06)]
            peso = lambda t: min(1.0, 0.05 + t ** 1.1)
            cara(H, q, [jit(c, 0.04) for c in cols], None, HOJAS, [peso(t0), peso(t1), peso(t1), peso(t0)])


def palmera(objs, nombre, alto, inclinacion, curva, n_hojas, n_secas, semilla, rumbo=0.0):
    M = nueva(objs, nombre)
    H = nueva(objs, nombre + "_hojas")
    A = nueva(objs, nombre + "_arena")
    r = random.Random(semilla)
    segs = nq(14, 9)
    lados = nq(7, 5)
    d = V(math.cos(rumbo), 0, math.sin(rumbo))
    pts, rs, cols = [], [], []
    for i in range(segs + 1):
        t = i / segs
        p = d * (inclinacion * alto * t ** curva) + V(0, alto * t, 0)
        pts.append(p - V(0, 0.15, 0) if i == 0 else p)
        escama = 1.07 if i % 2 else 1.0
        base = 0.34 - 0.13 * t + 0.16 * max(0.0, 1 - t * 6) ** 2
        rs.append(base * escama)
        cols.append(PALMA_TRONCO[2] if i % 2 else PALMA_TRONCO[i % 4 // 2])
    tubo_curvo(M, pts, rs, lados, cols, plano=True, tapa_ini=False, tapa_fin=True)
    cima = pts[-1]
    # copa: el nudo de donde salen las hojas y los dátiles
    bulto(M, cima + V(0, 0.08, 0), 0.26, (1.0, 0.8, 1.0), 1 if Q >= 1 else 0, 0.25, PALMA_TRONCO[1], semilla * 0.3)
    for k in range(nq(4, 2)):
        a = 2 * math.pi * k / 4 + 0.3
        bulto(M, cima + V(math.cos(a) * 0.25, -0.22, math.sin(a) * 0.25), 0.13, (1.0, 1.3, 1.0), 0, 0.3,
              jit(DATIL, 0.1), k + semilla)
    nh = nq(n_hojas, 6)
    nf = nq(12, 7)
    for k in range(nh):
        a = 2 * math.pi * k / nh + r.uniform(-0.2, 0.2) + semilla
        largo = alto * r.uniform(0.36, 0.46)
        fronda(H, cima + V(0, r.uniform(-0.05, 0.12), 0), a, largo, r.uniform(0.75, 1.0), r.uniform(0.38, 0.48), nf,
               HOJA_PALMA, semilla=semilla * 10 + k, elev=r.uniform(0.3, 0.6))
    for k in range(nq(n_secas, 0) if n_secas else 0):
        a = 2 * math.pi * (k + 0.4) / max(1, n_secas) + 0.7
        fronda(H, cima + V(0, -0.1, 0), a, alto * 0.32, 0.0, 0.25, max(4, nf // 2), HOJA_SECA, seca=True,
               semilla=semilla * 20 + k)
    # raíces y arena al pie
    for k in range(nq(5, 3)):
        a = 2 * math.pi * k / 5 + 0.3
        tubo(M, V(math.cos(a) * 0.15, 0.25, math.sin(a) * 0.15), V(math.cos(a) * 0.55, -0.05, math.sin(a) * 0.55),
             0.07, 0.03, 4, PALMA_TRONCO[0], tapa_a=False)
    monticulo(A, (0.0, 0.0, 0.0), 0.9, 0.8, 0.22, semilla=float(semilla), oscuro=0.25)
    M.caja_choque(-0.35, -0.35, 0.35, 0.35, 2.5)
    ancla("copa", tuple(cima))


def palmera_a(objs):
    palmera(objs, "palmera_a", 7.5, 0.16, 1.8, 11, 0, 3, rumbo=0.3)


def palmera_b(objs):
    palmera(objs, "palmera_b", 6.0, 0.38, 1.4, 9, 3, 7, rumbo=-2.6)


def juncos(objs):
    """Mata de juncos y espadañas de la orilla del estanque (doble cara, se mecen)."""
    H = nueva(objs, "juncos")
    r = random.Random(5)
    n = nq(26, 14)
    for i in range(n):
        a = r.uniform(0, 2 * math.pi)
        d = r.uniform(0.0, 0.6) ** 0.8
        b = V(math.cos(a) * d, -0.05, math.sin(a) * d)
        alto = r.uniform(0.8, 1.7) * (1.0 - 0.35 * d)
        inc = V(math.cos(a), 0, math.sin(a)) * r.uniform(0.15, 0.45) + V(r.uniform(-0.1, 0.1), 0, r.uniform(-0.1, 0.1))
        ancho = r.uniform(0.035, 0.06)
        giro = r.uniform(0, math.pi)
        lado = V(math.cos(giro), 0, math.sin(giro))
        niveles = 3
        izq, der, pesos = [], [], []
        for j in range(niveles + 1):
            t = j / niveles
            p = b + V(0, alto * t, 0) + inc * alto * t * t
            w = ancho * (1 - t * 0.85)
            izq.append(p - lado * w)
            der.append(p + lado * w)
            pesos.append(t ** 1.4)
        tip = b + V(0, alto * 1.12, 0) + inc * alto * 1.25
        for j in range(niveles):
            c0 = mezcla(JUNCO[0], JUNCO[1], j / niveles)
            c1 = mezcla(JUNCO[1], JUNCO[2], (j + 1) / niveles * 0.7)
            cara(H, [izq[j], der[j], der[j + 1], izq[j + 1]], [c0, c0, c1, c1], None, HOJAS,
                 [pesos[j], pesos[j], pesos[j + 1], pesos[j + 1]])
        cara(H, [izq[-1], der[-1], tip], [JUNCO[2], JUNCO[2], mezcla(JUNCO[2], (1, 1, 1), 0.1)], None, HOJAS, [pesos[-1], pesos[-1], 1.0])
    # espadañas: tallo fino y la mazorca parda
    for i in range(nq(6, 3)):
        a = r.uniform(0, 2 * math.pi)
        b = V(math.cos(a) * 0.3, -0.05, math.sin(a) * 0.3)
        alto = r.uniform(1.4, 1.9)
        cima = b + V(math.cos(a) * 0.2, alto, math.sin(a) * 0.2)
        tubo(H, b, cima, 0.012, 0.01, 3, JUNCO[1], tapa_a=False, tapa_b=False, mat=HOJAS, w=[0.0, 0.9])
        tubo(H, cima - V(0, 0.32, 0) + (cima - b).normalized() * 0.0, cima - V(0, 0.08, 0), 0.035, 0.035, nq(5, 4),
             jit(ESPADANA, 0.08), mat=HOJAS, w=[0.75, 0.9])


# ================================================================= cañón

def roca_estratos(M, centro, rx, rz, alto, capas, semilla, pal=ROCA_CANON, lados=14, perfil=None, giro=0.0,
                  y_base=-1.0, cornisa=0.08, tapa=True, abajo=False, arena_cima=0.4, rugosidad=0.45, deriva=0.09,
                  repisas=0.45):
    """Roca de arenisca en estratos. El contorno es propio de cada roca (ruido grande y mediano, y dos o tres grietas
    verticales en V); los estratos son bandas de color con el canto de abajo en sombra, y solo algunos acaban en repisa
    (con su labio de arena, lo que se ve desde la cámara del juego): el resto sigue la pared sin escalón. Cada repisa
    desplaza un poco el centro (la roca no es una pila de discos)."""
    c = V(centro)
    lados = nq(lados, 7)
    r = random.Random(semilla)
    angs = [2 * math.pi * k / lados + giro for k in range(lados)]
    grietas = [r.uniform(0, 2 * math.pi) for _ in range(r.randint(2, 3))]

    def contorno(a):
        v = 1 + rugosidad * noise.noise(Vector((math.cos(a) * 1.3 + semilla, math.sin(a) * 1.3, semilla * 0.7)))
        v += rugosidad * 0.6 * noise.noise(Vector((math.cos(a) * 3.3, math.sin(a) * 3.3, semilla + 4.0)))
        for g in grietas:
            dif = abs((a - g + math.pi) % (2 * math.pi) - math.pi)
            v -= 0.24 * max(0.0, 1 - dif / 0.26)
        return max(0.42, v)

    forma = [contorno(a) for a in angs]
    perfil = perfil or (lambda t: 1.0 - 0.28 * t)
    n = nq(capas, 3)
    grosores = [r.uniform(0.6, 1.4) for _ in range(n)]
    total = sum(grosores)
    ys = [y_base]
    for g in grosores:
        ys.append(ys[-1] + (alto - y_base) * g / total)
    tonos = [pal[min(len(pal) - 2, (semilla + i * 2) % (len(pal) - 1))] for i in range(n)]

    def anillo(y, s, o, fila):
        pts = []
        for k, a in enumerate(angs):
            j = 1 + 0.06 * noise.noise(Vector((k * 0.9, fila * 1.7, semilla * 1.3)))
            pts.append(V(c.x + o.x + math.cos(a) * rx * forma[k] * s * j, c.y + y,
                         c.z + o.z + math.sin(a) * rz * forma[k] * s * j))
        return pts

    def pared(a0, a1, col):
        for k in range(lados):
            k2 = (k + 1) % lados
            q = [a0[k], a0[k2], a1[k2], a1[k]]
            fuera = V(math.cos(angs[k] + math.pi / lados), 0, math.sin(angs[k] + math.pi / lados))
            cara(M, q, jit(col, 0.06), fuera)

    def radio_h(p):
        return math.hypot(p.x - c.x, p.z - c.z)

    o = V(0, 0, 0)
    prev_top = None
    repisa_antes = False
    primero = None
    fila = 0
    for i in range(n):
        t0, t1 = (ys[i] - y_base) / (alto - y_base), (ys[i + 1] - y_base) / (alto - y_base)
        col = tonos[i]
        if ys[i] < 0.6:
            col = mezcla(col, ROCA_SOMBRA, 0.22)
        if prev_top is None or repisa_antes:
            s0 = perfil(t0) * (r.uniform(0.95, 1.03) if prev_top is not None else 1.0)
            bajo = anillo(ys[i], s0, o, fila)
            fila += 1
        else:
            bajo = prev_top
        primero = primero or bajo
        if prev_top is not None and repisa_antes:          # la repisa: labio de arena arriba o sombra si vuela
            for k in range(lados):
                k2 = (k + 1) % lados
                q = [prev_top[k], prev_top[k2], bajo[k2], bajo[k]]
                sube = radio_h(bajo[k]) < radio_h(prev_top[k])
                cc = mezcla(col, ARENA_C, arena_cima) if sube else mezcla(col, ROCA_SOMBRA, 0.45)
                cara(M, q, jit(cc, 0.04), (0, 1 if sube else -1, 0))
        s1 = perfil(t1)
        repisa = i < n - 1 and r.random() < repisas
        medio = anillo((ys[i] + ys[i + 1]) * 0.5, perfil((t0 + t1) * 0.5) * 1.03, o, fila)
        fila += 1
        arriba = anillo(ys[i + 1], s1 * ((1 - cornisa * r.uniform(0.6, 1.4)) if repisa else 1.0), o, fila)
        fila += 1
        pared(bajo, medio, mezcla(col, ROCA_SOMBRA, 0.14))
        pared(medio, arriba, col)
        prev_top = arriba
        repisa_antes = repisa
        if repisa:
            o = o + V(r.uniform(-1, 1) * deriva * rx, 0, r.uniform(-1, 1) * deriva * rz)
    if tapa:
        centro_cima = sum(prev_top, V(0, 0, 0)) / lados
        anillo_int = []
        for k, p in enumerate(prev_top):
            q = centro_cima.lerp(p, 0.55)
            q.y += min(rx, rz) * (0.08 + 0.1 * (0.5 + 0.5 * noise.noise(Vector((k * 1.1, semilla, 2.0)))))
            anillo_int.append(q)
        cima = centro_cima + V(0, 0.2 * min(rx, rz), 0)
        polvo = mezcla(pal[-1], ARENA_C, arena_cima + 0.15)
        for k in range(lados):
            k2 = (k + 1) % lados
            cara(M, [prev_top[k], prev_top[k2], anillo_int[k2], anillo_int[k]],
                 jit(mezcla(pal[-2], ARENA_C, arena_cima), 0.05), (0, 1, 0))
            cara(M, [anillo_int[k], anillo_int[k2], cima], jit(polvo, 0.05), (0, 1, 0))
    if abajo:
        cara(M, primero, mezcla(pal[0], ROCA_SOMBRA, 0.6), (0, -1, 0))
    return ys


def pedruscos(M, centro, n, radio, semilla, tam=0.35):
    r = random.Random(semilla)
    for k in range(n):
        a = r.uniform(0, 2 * math.pi)
        d = r.uniform(0.2, 1.0) * radio
        s = tam * r.uniform(0.5, 1.2)
        bulto(M, V(centro) + V(math.cos(a) * d, s * 0.3, math.sin(a) * d), s, (1.2, 0.75, 1.0), 0, 0.3,
              jit(elige(ROCA_CANON), 0.08), semilla + k)


def roca_canon_a(objs):
    """Peñón alto (9 m) de estratos rojos: la silueta que marca la entrada del cañón."""
    M = nueva(objs, "roca_canon_a")
    A = nueva(objs, "roca_canon_a_arena")
    roca_estratos(M, (0, 0, 0), 2.6, 2.2, 9.0, 9, 1, perfil=lambda t: 1.0 - 0.35 * t ** 1.3)
    pedruscos(M, (0.3, 0, 0.6), nq(5, 3), 3.4, 3)
    monticulo(A, (-1.8, 0.0, 0.6), 2.6, 2.4, 1.1, semilla=19.0, oscuro=0.25)
    M.caja_choque(-2.6, -2.2, 2.6, 2.2, 9.0)


def roca_canon_b(objs):
    """Paño de pared del cañón (12 m de largo, 7 de alto), alargado de norte a sur: se encadena para hacer las paredes."""
    M = nueva(objs, "roca_canon_b")
    A = nueva(objs, "roca_canon_b_arena")
    roca_estratos(M, (0, 0, 0), 2.4, 6.2, 7.0, 8, 2, lados=20, perfil=lambda t: 1.0 - 0.22 * t)
    pedruscos(M, (1.8, 0, 0), nq(6, 3), 4.5, 5)
    monticulo(A, (2.0, 0.0, -2.0), 1.9, 3.2, 0.9, giro=0.0, semilla=20.0, oscuro=0.25)
    monticulo(A, (1.8, 0.0, 3.4), 1.6, 2.0, 0.6, semilla=21.0, oscuro=0.2)
    M.caja_choque(-2.4, -6.0, 2.4, 6.0, 7.0)


def roca_canon_c(objs):
    """Bloque caído y su pedregal (3 m): rompe las líneas al pie de las paredes."""
    M = nueva(objs, "roca_canon_c")
    A = nueva(objs, "roca_canon_c_arena")
    roca_estratos(M, (0, 0, 0), 1.7, 1.3, 2.8, 4, 3, lados=11, perfil=lambda t: 1.0 - 0.3 * t, giro=0.4, y_base=-0.6)
    roca_estratos(M, (2.0, 0, 0.9), 0.9, 0.7, 1.2, 3, 4, lados=9, perfil=lambda t: 1.0 - 0.35 * t, y_base=-0.4)
    pedruscos(M, (0.6, 0, 1.4), nq(6, 3), 1.6, 7, tam=0.28)
    monticulo(A, (-1.5, 0.0, 0.3), 1.6, 1.4, 0.55, semilla=22.0, oscuro=0.2)
    M.caja_choque(-1.7, -1.3, 1.7, 1.3, 2.8)
    M.caja_choque(1.2, 0.3, 2.8, 1.5, 1.2)


def roca_canon_d(objs):
    """Chimenea de hada (6 m): cuello estrecho y sombrero de roca más ancho. Silueta inconfundible desde arriba."""
    M = nueva(objs, "roca_canon_d")
    A = nueva(objs, "roca_canon_d_arena")
    roca_estratos(M, (0, 0, 0), 1.5, 1.3, 4.6, 6, 6, lados=12, perfil=lambda t: 1.0 - 0.55 * t ** 0.8, y_base=-0.8)
    roca_estratos(M, (0.15, 4.4, 0.05), 1.7, 1.45, 1.4, 2, 7, lados=12, perfil=lambda t: 1.0 - 0.15 * t, y_base=0.0,
                  abajo=True, pal=(ROCA_CANON[3], ROCA_CANON[2], ROCA_CANON[3]))
    pedruscos(M, (0, 0, 0.4), nq(4, 2), 2.2, 9, tam=0.3)
    monticulo(A, (-1.2, 0.0, 0.3), 1.8, 1.5, 0.6, semilla=23.0, oscuro=0.25)
    M.caja_choque(-1.4, -1.2, 1.4, 1.2, 5.8)


def roca_cobijo(objs):
    """Roca saliente que hace de cobijo en la tormenta. El origen es el sitio donde se resguarda Kael (bajo el saliente);
    la masa de roca queda al oeste. «roca_cobijo_techo» es el saliente (por si la región lo vuelve medio transparente
    cuando tapa a Kael)."""
    M = nueva(objs, "roca_cobijo")
    T = nueva(objs, "roca_cobijo_techo")
    A = nueva(objs, "roca_cobijo_arena")
    roca_estratos(M, (-3.3, 0, -0.4), 2.2, 3.0, 5.6, 7, 11, lados=13, perfil=lambda t: 1.0 - 0.12 * t)
    roca_estratos(T, (-0.2, 2.65, -0.5), 4.2, 2.5, 1.6, 3, 12, lados=nq(16, 10), perfil=lambda t: 1.0 - 0.2 * t,
                  y_base=0.0, abajo=True, cornisa=0.06)
    # una piedra-banco bajo el saliente y un poco de pedregal
    roca_estratos(M, (-1.0, 0, -1.3), 0.7, 0.5, 0.5, 2, 13, lados=9, perfil=lambda t: 1.0 - 0.2 * t, y_base=-0.3)
    pedruscos(M, (2.6, 0, 0.6), nq(4, 2), 1.2, 14, tam=0.3)
    monticulo(A, (-5.2, 0.0, 0.0), 2.2, 3.2, 1.2, semilla=24.0, oscuro=0.25)
    monticulo(A, (0.2, 0.0, -0.6), 2.4, 1.8, 0.2, semilla=25.0, oscuro=0.35)         # arena en sombra bajo el saliente
    M.caja_choque(-5.4, -3.2, -1.4, 2.4, 5.6)
    ancla("cobijo", (0.0, 0.0, 0.0))


# ================================================================= arena que tiembla

def huesos_costillas(objs):
    """Costillar de una criatura colosal medio enterrado (unos 16 m): espinazo serpenteante con sus vértebras, seis
    pares de costillas que salen de la arena y se curvan hacia dentro (alguna rota) y el cráneo con colmillos al este."""
    M = nueva(objs, "huesos_costillas")
    A = nueva(objs, "huesos_costillas_arena")
    lados = nq(7, 5)

    def espinazo(x):
        return V(x, 0.15 + 0.35 * math.sin(x * 0.55 + 0.6), 0.6 * math.sin(x * 0.3))

    # vértebras (las que asoman)
    x = -7.5
    while x < 6.6:
        p = espinazo(x)
        if p.y > -0.05:
            q = espinazo(x + 0.75)
            tubo(M, p - (q - p).normalized() * 0.32, p + (q - p).normalized() * 0.32, 0.42, 0.38, lados,
                 jit(elige(HUESO), 0.04))
            tubo(M, p + V(0, 0.3, 0), p + V(-0.25, 1.15, 0), 0.16, 0.05, 5, HUESO[1], tapa_a=False)
            for s in (-1, 1):
                tubo(M, p, p + V(0.05, 0.1, s * 0.75), 0.11, 0.06, 4, HUESO[0], tapa_a=False)
        x += 1.15
    # costillas
    xs = [-5.4, -3.6, -1.8, 0.0, 1.8, 3.6]
    rotas = {(-3.6, 1): 0.55, (1.8, -1): 0.45, (3.6, 1): 0.7}
    for xi, x in enumerate(xs):
        p0 = espinazo(x)
        escala = 0.75 + 0.35 * math.sin(math.pi * (xi + 0.5) / len(xs))
        for s in (-1, 1):
            n = nq(10, 7)
            pts, rs, cols = [], [], []
            corte = rotas.get((x, s), 1.0)
            for i in range(n + 1):
                t = i / n
                if t > corte + 1e-6:
                    break
                a = math.pi * 0.95 * t
                zz = s * (0.6 + 2.6 * math.sin(a * 0.9) * escala - 1.2 * t * t * escala)
                yy = -0.6 + 5.0 * escala * math.sin(a * 0.62) ** 1.2
                pts.append(V(p0.x + 0.35 * t - 0.25 * s * t * t, yy, p0.z + zz))
                rs.append(0.44 * (1 - t * 0.7))
                cols.append(mezcla(HUESO[1], HUESO[2], t) if i % 3 else HUESO[0])
            if len(pts) >= 2:
                tubo_curvo(M, pts, rs, lados, cols, plano=True, tapa_ini=False, tapa_fin=True)
            if corte < 1.0:
                # el trozo roto, caído en la arena junto a ella
                pc = pts[-1]
                tubo(M, V(pc.x + 0.6, 0.05, pc.z + s * 1.2), V(pc.x + 1.8, 0.2, pc.z + s * 1.5), 0.13, 0.08, 5, HUESO[1])
    # cráneo al este, medio hundido, con las órbitas oscuras y dos colmillos curvos
    cp = espinazo(7.4) + V(0.8, -0.2, 0)
    bulto(M, cp, 1.25, (1.6, 0.85, 1.05), 2 if Q >= 1 else 1, 0.12,
          lambda d, q: HUESO_OSC if q.y < 0.3 else (HUESO[2] if d.y > 0.4 else HUESO[1]), 3.0)
    # hocico largo y la cresta sobre las órbitas (silueta de bestia desde arriba)
    bulto(M, cp + V(1.55, -0.05, 0.0), 0.75, (1.7, 0.6, 0.85), 1, 0.15,
          lambda d, q: HUESO_OSC if q.y < 0.15 else HUESO[1], 3.7)
    for s in (-1, 1):
        caja_t(M, cp + V(0.45, 0.88, s * 0.5), (1.1, 0.22, 0.35), (1, 0.15, s * 0.3), (0, 1, 0), HUESO[2])
        bulto(M, cp + V(0.35, 0.55, s * 0.62), 0.32, (1.0, 0.7, 0.8), 0, 0.1, OSCURO, 5.0 + s)
        for k in range(nq(4, 2)):                         # dientes
            b = cp + V(1.3 + k * 0.42, -0.15, s * 0.55)
            tubo(M, b, b + V(0.05, -0.35, s * 0.05), 0.07, 0.01, 4, HUESO[2], tapa_a=False, tapa_b=False)
        pts = [cp + V(1.4, -0.1, s * 0.55), cp + V(2.2, 0.35, s * 0.85), cp + V(2.7, 1.2, s * 0.7), cp + V(2.6, 1.9, s * 0.35)]
        tubo_curvo(M, pts, [0.22, 0.17, 0.11, 0.03], 6, [HUESO[1], HUESO[2], HUESO[2], HUESO[2]], plano=True, tapa_ini=False, tapa_fin=False)
    # arena: el espinazo enterrado a trozos y montones al pie de las costillas
    for k, x in enumerate((-6.5, -3.2, 0.2, 3.0, 6.2)):
        p = espinazo(x)
        monticulo(A, (p.x, 0.0, p.z), 1.9, 1.5, 0.55, giro=0.1 * k, semilla=26.0 + k, oscuro=0.15)
    for x in xs:
        p = espinazo(x)
        for s in (-1, 1):
            monticulo(A, (p.x + 0.1, 0.0, p.z + s * 2.0), 1.0, 0.9, 0.3, anillos=3, segs=9, semilla=40.0 + x * s, oscuro=0.2)
    monticulo(A, (cp.x, 0.0, cp.z), 2.4, 1.8, 0.45, semilla=50.0, oscuro=0.2)
    M.caja_choque(-7.5, -0.6, 6.6, 0.8, 1.2)
    M.caja_choque(cp.x - 1.8, cp.z - 1.3, cp.x + 1.6, cp.z + 1.3, 1.8)


# ================================================================= nicho

def esqueleto(objs):
    """Esqueleto sentado, la espalda contra la pared del nicho (al norte, z = -0,35) y mirando al sur. En la mano
    derecha, la nota doblada («ancla_nota»); a su lado, el zurrón y un odre vacío. Escala humana (1,7 m de pie)."""
    M = nueva(objs, "esqueleto")
    h = HUESO
    lados = 5 if Q >= 1 else 4
    # pelvis y espinazo
    bulto(M, (0.0, 0.14, -0.14), 0.13, (1.3, 0.7, 0.8), 0, 0.15, h[1], 1.0)
    espina = [V(0.0, 0.18, -0.2), V(0.0, 0.35, -0.27), V(0.02, 0.52, -0.3), V(0.04, 0.68, -0.29)]
    tubo_curvo(M, espina, [0.03, 0.028, 0.026, 0.024], 4, [h[0]] * 4, plano=True)
    # costillas (arcos)
    for i in range(nq(5, 3)):
        y = 0.40 + i * 0.055
        rad = 0.13 - abs(i - 2) * 0.012
        for s in (-1, 1):
            pts = [V(0.0, y + 0.02, -0.29), V(s * rad * 0.9, y, -0.24), V(s * rad, y - 0.03, -0.14), V(s * rad * 0.5, y - 0.06, -0.08)]
            tubo_curvo(M, pts, 0.012, 3, [h[2]] * 4, plano=True, tapa_fin=False)
    # clavículas y hombros
    for s in (-1, 1):
        tubo(M, (0.03, 0.66, -0.25), (s * 0.17, 0.64, -0.24), 0.014, 0.014, 3, h[1], tapa_a=False)
    # cráneo, ladeado, y la mandíbula caída
    cr = V(0.08, 0.83, -0.23)
    bulto(M, cr, 0.11, (0.88, 1.0, 1.05), 1, 0.06, lambda d, q: h[2] if d.y > -0.2 else h[1], 2.0)
    for s in (-1, 1):
        bulto(M, cr + V(s * 0.04 + 0.01, 0.0, 0.085), 0.03, (1, 1, 0.6), 0, 0.0, OSCURO, 3.0)
    caja_t(M, cr + V(0.0, -0.1, 0.06), (0.11, 0.04, 0.08), (1, 0, 0), (0, 1, -0.3), h[1])
    # brazos: el izquierdo caído al suelo, el derecho en el regazo con la nota
    tubo_curvo(M, [V(-0.17, 0.63, -0.24), V(-0.24, 0.38, -0.15), V(-0.3, 0.12, 0.02)], 0.022, lados, [h[1]] * 3, plano=True)
    bulto(M, (-0.32, 0.03, 0.1), 0.05, (1.0, 0.4, 1.5), 0, 0.2, h[0], 4.0)
    tubo_curvo(M, [V(0.17, 0.63, -0.24), V(0.22, 0.36, -0.12), V(0.06, 0.28, 0.08)], 0.022, lados, [h[1]] * 3, plano=True)
    bulto(M, (0.02, 0.27, 0.12), 0.045, (1.2, 0.5, 1.2), 0, 0.2, h[0], 5.0)
    # la nota doblada (papel), que asoma de la mano
    caja_t(M, (0.0, 0.29, 0.17), (0.17, 0.012, 0.12), (1, 0.1, 0.2), (0, 1, 0), PAPEL, jitter=0.0)
    cara(M, [(-0.07, 0.30, 0.14), (0.07, 0.31, 0.15), (0.06, 0.34, 0.2)], mezcla(PAPEL, (1, 1, 1), 0.2), (0, 1, 0))
    # piernas: la izquierda estirada, la derecha con la rodilla arriba
    for (cad, rod, pie) in ((V(-0.1, 0.12, -0.08), V(-0.15, 0.13, 0.33), V(-0.17, 0.04, 0.72)),
                            (V(0.1, 0.12, -0.08), V(0.14, 0.38, 0.22), V(0.16, 0.04, 0.5))):
        tubo_curvo(M, [cad, rod], 0.03, lados, [h[1], h[1]], plano=True)
        tubo_curvo(M, [rod, pie], 0.024, lados, [h[1], h[1]], plano=True)
        bulto(M, pie + V(0, -0.01, 0.06), 0.06, (0.8, 0.4, 1.6), 0, 0.2, h[0], 6.0)
    # jirones de capa bajo el cuerpo, zurrón y odre
    for k in range(3):
        cara(M, [(-0.35 + 0.25 * k, 0.012, -0.32), (-0.1 + 0.25 * k, 0.012, -0.34), (-0.05 + 0.2 * k, 0.012, 0.15 + 0.1 * (k % 2)),
                 (-0.3 + 0.22 * k, 0.012, 0.05)], jit(mezcla(TELA_ANIL, OSCURO, 0.35), 0.06), (0, 1, 0))
    caja_t(M, (0.45, 0.1, -0.05), (0.26, 0.2, 0.12), (1, 0, 0.3), (0, 1, 0), CUERO)
    caja_t(M, (0.45, 0.2, 0.02), (0.27, 0.03, 0.08), (1, 0, 0.3), (0.2, 1, 0), mezcla(CUERO, OSCURO, 0.3))
    bulto(M, (-0.5, 0.06, 0.05), 0.12, (1.4, 0.45, 0.9), 0, 0.2, mezcla(CUERO, ARENA_C, 0.2), 7.0)
    ancla("nota", (0.0, 0.29, 0.17))


# ================================================================= el GLB

ORIGENES = {}


def nueva(objs, nombre, origen=(0.0, 0.0, 0.0)):
    M = Malla()
    objs[nombre] = M
    ORIGENES[nombre] = origen
    return M


def material(nombre):
    m = bpy.data.materials.get(nombre)
    if m is not None:
        return m
    m = bpy.data.materials.new(nombre)
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    ca = m.node_tree.nodes.new("ShaderNodeVertexColor")
    ca.layer_name = "Color"
    if nombre == "brillo":
        m.node_tree.links.new(ca.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = 1.0
        bsdf.inputs["Base Color"].default_value = (0, 0, 0, 1)
    else:
        gam = m.node_tree.nodes.new("ShaderNodeGamma")          # solo para verlo bien en Blender (el atributo va en sRGB)
        gam.inputs["Gamma"].default_value = 2.2
        m.node_tree.links.new(ca.outputs["Color"], gam.inputs["Color"])
        m.node_tree.links.new(gam.outputs["Color"], bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.9
    return m


def objeto(nombre, M, origen):
    o = Vector((origen[0], -origen[2], origen[1]))
    me = bpy.data.meshes.new(nombre)
    me.from_pydata([tuple(v - o) for v in M.v], [], M.caras)
    me.update()
    usados = sorted(set(M.mats))
    mapa = {m: i for i, m in enumerate(usados)}
    me.polygons.foreach_set("material_index", [mapa[m] for m in M.mats])
    attr = me.color_attributes.new("Color", 'FLOAT_COLOR', 'POINT')
    cols = []
    for c in M.col:
        cols += list(c)
    attr.data.foreach_set("color", cols)
    me.color_attributes.active_color = attr
    me.validate(clean_customdata=False)
    for m in usados:
        me.materials.append(material(MATERIALES[m]))
    me.shade_smooth()
    blandos = usados and all(m in (ARENA, TELA, HOJAS) for m in usados)
    me.set_sharp_from_angle(angle=math.radians(80 if blandos else 40))
    ob = bpy.data.objects.new(nombre, me)
    ob.location = o
    bpy.context.scene.collection.objects.link(ob)
    for i, (x, z, w, d, h) in enumerate(M.cajas):
        e = bpy.data.objects.new("caja_%d_%d_%d_%d" % (i, round(w * 100), round(d * 100), round(h * 100)), None)
        e.empty_display_type = 'CUBE'
        e.location = (x - o.x, -z - o.y, -o.z)
        e.parent = ob
        bpy.context.scene.collection.objects.link(e)
    return ob


PIEZAS = [
    ("ruinas_arco", ruinas_arco), ("ruinas_columna_a", ruinas_columna_a), ("ruinas_columna_b", ruinas_columna_b),
    ("ruinas_columna_c", ruinas_columna_c), ("ruinas_columna_d", ruinas_columna_d), ("ruinas_muro", ruinas_muro),
    ("trampilla", trampilla),
    ("caravana_carro", caravana_carro), ("caravana_cajas", caravana_cajas), ("caravana_barril", caravana_barril),
    ("caravana_tela", caravana_tela),
    ("tienda_a", tienda_a), ("tienda_b", tienda_b), ("fogata", fogata),
    ("palmera_a", palmera_a), ("palmera_b", palmera_b), ("juncos", juncos),
    ("roca_canon_a", roca_canon_a), ("roca_canon_b", roca_canon_b), ("roca_canon_c", roca_canon_c),
    ("roca_canon_d", roca_canon_d), ("roca_cobijo", roca_cobijo),
    ("huesos_costillas", huesos_costillas), ("esqueleto", esqueleto),
]


def construir(nombre, f, calidad, ruta):
    global Q
    Q = calidad
    RND.seed(sum(ord(ch) for ch in nombre) * 7 + 11)
    ANCLAS.clear()
    ORIGENES.clear()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    objs = {}
    f(objs)
    total = 0
    detalle = []
    for nom, M in objs.items():
        if not M.caras:
            continue
        objeto(nom, M, ORIGENES[nom])
        tri = M.triangulos()
        total += tri
        detalle.append("%s=%d" % (nom, tri))
    for nom, (x, y, z) in ANCLAS.items():
        e = bpy.data.objects.new("ancla_" + nom, None)
        e.location = (x, -z, y)
        bpy.context.scene.collection.objects.link(e)
    if ruta:
        bpy.ops.export_scene.gltf(filepath=ruta, export_format='GLB', use_selection=False, export_animations=False,
                                  export_yup=True, export_vertex_color='ACTIVE', export_cameras=False,
                                  export_lights=False, export_apply=True)
    return total, detalle


for nombre, f in PIEZAS:
    if SOLO and nombre not in SOLO:
        continue
    alto, det = construir(nombre, f, 1.0, os.path.join(CARPETA, nombre + ".glb") if CARPETA else "")
    ligero, det_l = construir(nombre, f, 0.6, "")
    ruta_l = os.path.join(CARPETA, nombre + "_ligero.glb") if CARPETA else ""
    if ligero <= alto * 0.8:
        construir(nombre, f, 0.6, ruta_l)
        print("PIEZA %-18s alto %5d · ligero %5d  (%s)" % (nombre, alto, ligero, ", ".join(det)))
    else:
        if ruta_l and os.path.exists(ruta_l):
            os.remove(ruta_l)
        print("PIEZA %-18s alto %5d · sin ligero (%d)  (%s)" % (nombre, alto, ligero, ", ".join(det)))
