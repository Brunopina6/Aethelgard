# Guardián del Bosque Olvidado (fase 3, jefe de «El bosque que no recuerda»): modelo, esqueleto y clips, hechos
# desde cero con este guion (geometría procedural propia: ningún recurso descargado; obra propia del proyecto).
#
#   blender -b --factory-startup -P crear_guardian.py -- <salida.glb> [<salida.blend>]
#
# Regenera el GLB entero: misma semilla, mismo resultado. El .blend (opcional) sirve para renderizar las capturas
# (capturas_guardian.py) y no se versiona: se regenera con este guion.
#
# Ejes (Blender): el Guardián mira a -Y, Z arriba, su izquierda es +X (huesos .L). En Godot mira a +Z.
# Giros de las poses: alrededor de los ejes del esqueleto en reposo (girar): X (+) inclina hacia delante lo que
# apunta arriba y lleva hacia atrás lo que cuelga; Z (+) gira hacia su izquierda; Y (+) lleva lo de arriba hacia +X.
# En los huesos .R, los giros en Y y Z se reflejan (par()).
#
# Presupuesto móvil: una malla, 2 materiales (corteza con colores de vértice y luz emisiva), 28 huesos, < 12 000
# triángulos. Las piezas que solo salen en un clip (coraza de la fase 2, musgo del sueño y raíces del suelo) van
# en la misma malla, pesadas a su propio hueso, y se esconden con escala 0,01 dentro del cuerpo o a ras de suelo:
#   coraza, coraza.L, coraza.R  escala 1 en todos los clips salvo dormido (0,01) y fase2 (crece de 0,01 a 1).
#                               En la fase 1 del combate las esconde guardian_bosque_3d.gd.
#   musgo, musgo_cabeza, musgo_suelo  escala 1 solo en dormido.
#   raices_suelo                      escala 1 solo en golpe_fuerte (brotan y se retiran).
# La altura de la raíz de cada pose se calcula para que lo más bajo de las piernas toque el suelo; en las poses de
# rodillas, además, el giro del brazo se ajusta para que las manos se apoyen en el suelo (pose.manos).
# Colores de vértice: se guardan en sRGB (no en lineal, como pediría glTF). El renderizador Compatibility no convierte
# los colores de vértice (vertex_color_is_srgb no actúa en él) y los usa tal cual: en lineal saldrían oscuros (se vio
# el 10/11 en un combate). En Godot los materiales son corteza.tres (vertex_color_is_srgb = true: correcto también en
# Forward+ y Mobile) y luz.tres, puestos como materiales externos en el .import. En Blender, un nodo Gamma 2,2 los
# muestra bien en los renders de comprobación.
import bpy, bmesh, sys, math, random
import numpy as np
from mathutils import Vector, Quaternion, noise

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SALIDA_GLB = argv[0] if argv else ""
SALIDA_BLEND = argv[1] if len(argv) > 1 else ""

random.seed(7)
FPS = 30

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.fps = FPS


# ---------------------------------------------------------------- colores (sRGB; se pasan a lineal al escribirlos)

C_OSCURO = (0.20, 0.13, 0.08)
C_CORTEZA = (0.40, 0.27, 0.16)
C_CLARO = (0.62, 0.46, 0.29)
CORTEZA = (C_OSCURO, C_CORTEZA, C_CLARO)
CORAZA = ((0.17, 0.10, 0.07), (0.34, 0.20, 0.12), (0.55, 0.36, 0.22))      # más rojiza y oscura
RAIZ_NUEVA = ((0.30, 0.20, 0.12), (0.52, 0.37, 0.23), (0.72, 0.57, 0.38))  # raíces del suelo, más claras
MUSGO = (0.33, 0.50, 0.14)
MUSGO_CLARO = (0.56, 0.70, 0.22)
MUSGO_OSCURO = (0.20, 0.34, 0.11)
HOJAS = [(0.40, 0.62, 0.17), (0.55, 0.70, 0.20), (0.66, 0.72, 0.22), (0.82, 0.58, 0.18)]
FLORES = [(0.96, 0.93, 0.78), (0.99, 0.83, 0.36), (0.93, 0.70, 0.62)]
SETA = [(0.86, 0.55, 0.22), (0.95, 0.82, 0.60)]
LUZ = (0.80, 1.00, 0.45)       # verde dorado: corazón, ojos y venas (material emisivo)
GRIETA = (0.07, 0.05, 0.04)


def mezcla(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(a[i] * (1 - t) + b[i] * t for i in range(3))


def suave(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def lineal(c):
    return tuple(x ** 2.2 for x in c)


# ---------------------------------------------------------------- constructor de la malla

class Malla:
    def __init__(self):
        self.v, self.col, self.pesos = [], [], []
        self.caras, self.mats, self.cerradas = [], [], []

    def vert(self, p, c, pesos):
        self.v.append(Vector(p))
        self.col.append(c)
        self.pesos.append(pesos if isinstance(pesos, dict) else {pesos: 1.0})
        return len(self.v) - 1

    def cara(self, idx, mat=0, cerrada=True):
        self.caras.append(tuple(idx))
        self.mats.append(mat)
        self.cerradas.append(cerrada)


M = Malla()


def marcos(pts, ref=None):
    """Tangentes y normales por transporte paralelo (sin torsión a lo largo del tubo)."""
    n = len(pts)
    T = [(pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized() for i in range(n)]
    r0 = Vector(ref) if ref is not None else Vector((1, 0, 0))
    N = r0 - T[0] * r0.dot(T[0])
    if N.length < 1e-3:
        N = Vector((0, 1, 0)) - T[0] * T[0].y
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
    if musgo > 0:
        mm = noise.noise(pos * 4.0 + Vector((5.1, 2.3, 0.7))) * 0.5 + 0.5
        f = suave(0.2, 0.65, normal.z + (mm - 0.5) * 0.6) * musgo
        if f > 0:
            c = mezcla(c, mezcla(MUSGO_OSCURO, MUSGO_CLARO, mm * 1.3), f)
    return c


def tubo(pts, radios, pesos, lados=8, amp=0.08, surcos=6, pal=CORTEZA, musgo=0.5, mat=0, elipse=None,
         tapa0=True, punta=True, ref=None, semilla=0.0, giro=0.5, color=None):
    """Tubo de corteza por una polilínea. pesos: uno por anillo (nombre de hueso o {hueso: peso})."""
    pts = [Vector(p) for p in pts]
    T, N, B = marcos(pts, ref)
    anillos = []
    for i, p in enumerate(pts):
        sx, sy = elipse[i] if elipse else (1.0, 1.0)
        w = pesos[i]
        anillo = []
        for k in range(lados):
            a = 2 * math.pi * k / lados
            radial = N[i] * math.cos(a) * sx + B[i] * math.sin(a) * sy
            normal = (N[i] * math.cos(a) * sy + B[i] * math.sin(a) * sx).normalized()
            q = p + radial * radios[i]
            surco = abs(math.sin(a * surcos * 0.5 + i * giro + semilla))
            ru = noise.noise(q * 3.0 + Vector((semilla, 0.0, 0.0)))
            d = amp * (0.6 * (surco * 2 - 1) + 0.4 * ru)
            pos = p + radial * radios[i] * (1 + d)
            c = color(pos, normal) if color else color_corteza(pal, surco, ru, normal, musgo, pos)
            anillo.append(M.vert(pos, c, w))
        anillos.append(anillo)
    for i in range(len(anillos) - 1):
        a0, a1 = anillos[i], anillos[i + 1]
        for k in range(lados):
            k2 = (k + 1) % lados
            M.cara([a0[k], a0[k2], a1[k2], a1[k]], mat)
    if tapa0:
        c = M.vert(pts[0] - T[0] * radios[0] * 0.35, M.col[anillos[0][0]], pesos[0])
        for k in range(lados):
            M.cara([c, anillos[0][(k + 1) % lados], anillos[0][k]], mat)
    fin = pts[-1] + T[-1] * radios[-1] * (2.0 if punta else 0.35)
    c = M.vert(fin, M.col[anillos[-1][0]], pesos[-1])
    for k in range(lados):
        M.cara([anillos[-1][k], anillos[-1][(k + 1) % lados], c], mat)


def bulto(centro, radio, pesos, escala=(1, 1, 1), subdiv=1, amp=0.18, color=None, mat=0, semilla=0.0, suelo=False):
    """Icosfera deformada (musgo, nudos, ojos, corazón)."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=1.0)
    idx = {}
    for v in bm.verts:
        d = v.co.normalized()
        r = radio * (1 + amp * noise.noise(d * 2.2 + Vector((semilla, semilla * 0.37, 1.3))))
        p = Vector(centro) + Vector((d.x * escala[0], d.y * escala[1], d.z * escala[2])) * r
        if suelo:                                        # aplastado contra el suelo: nada por debajo de z = 0
            p.z = max(p.z, 0.0)
        c = color(d, p) if color else C_CORTEZA
        idx[v.index] = M.vert(p, c, pesos)
    for f in bm.faces:
        M.cara([idx[v.index] for v in f.verts], mat)
    bm.free()


def color_musgo(d, p):
    mm = noise.noise(p * 6.0 + Vector((1.7, 0.2, 3.3))) * 0.5 + 0.5
    c = mezcla(MUSGO_OSCURO, MUSGO_CLARO, mm * 1.2 + d.z * 0.25)
    if d.z < -0.3:
        c = mezcla(c, C_OSCURO, 0.5)
    return c


def hoja(base, direccion, normal, largo, ancho, color, pesos):
    """Hoja de dos caras (rombo)."""
    d = Vector(direccion).normalized()
    n = Vector(normal).normalized()
    lado = d.cross(n).normalized()
    b = Vector(base)
    ps = [b, b + d * largo * 0.45 + lado * ancho * 0.5, b + d * largo, b + d * largo * 0.45 - lado * ancho * 0.5]
    if (ps[1] - ps[0]).cross(ps[2] - ps[0]).dot(n) < 0:
        ps = [ps[0], ps[3], ps[2], ps[1]]
    claro = mezcla(color, (1, 1, 0.8), 0.15)
    f = [M.vert(p, claro if i == 2 else color, pesos) for i, p in enumerate(ps)]
    M.cara(f, 0, cerrada=False)
    t = [M.vert(p - n * 0.004, mezcla(color, C_OSCURO, 0.25), pesos) for p in ps]
    M.cara([t[0], t[3], t[2], t[1]], 0, cerrada=False)


def ramillete(punta, direccion, pesos, n=3, tam=0.16):
    d = Vector(direccion).normalized()
    for i in range(n):
        a = 2 * math.pi * i / n + random.uniform(-0.4, 0.4)
        lado = d.orthogonal().normalized()
        lado.rotate(Quaternion(d, a))
        dirh = (d * 0.6 + lado * 0.8).normalized()
        nrm = dirh.cross(lado).normalized()
        if nrm.z < 0:
            nrm = -nrm
        hoja(punta, dirh, nrm + Vector((0, 0, 0.5)), tam * random.uniform(0.8, 1.2), tam * 0.55,
             random.choice(HOJAS), pesos)


def flor(centro, pesos, tam=0.05):
    c = random.choice(FLORES)
    for i in range(3):
        a = math.pi * i / 3 + random.uniform(0, 0.3)
        d = Vector((math.cos(a), math.sin(a), 0.0))
        hoja(Vector(centro) - d * tam * 0.5, d, (0, 0, 1), tam, tam * 0.7, c, pesos)


# ---------------------------------------------------------------- el cuerpo

# Tronco: (centro, radio, (escala en X, escala en Y)), de la cadera al cuello
TRONCO = [
    ((0, 0.06, 0.92), 0.36, (1.15, 0.9)),
    ((0, 0.06, 1.10), 0.50, (1.20, 0.9)),
    ((0, 0.05, 1.38), 0.47, (1.15, 0.88)),
    ((0, 0.02, 1.64), 0.50, (1.18, 0.88)),
    ((0, -0.03, 1.90), 0.58, (1.22, 0.86)),
    ((0, -0.07, 2.14), 0.64, (1.25, 0.84)),
    ((0, -0.10, 2.34), 0.58, (1.28, 0.82)),
    ((0, -0.16, 2.50), 0.40, (1.20, 0.90)),
    ((0, -0.22, 2.60), 0.26, (1.0, 1.0)),
]


def peso_tronco(z):
    if z < 1.30:
        return {"cadera": 1.0}
    if z < 1.48:
        return {"cadera": 0.5, "columna": 0.5}
    if z < 1.80:
        return {"columna": 1.0}
    if z < 1.98:
        return {"columna": 0.5, "pecho": 0.5}
    if z < 2.45:
        return {"pecho": 1.0}
    if z < 2.55:
        return {"pecho": 0.6, "cuello": 0.4}
    return {"cuello": 1.0}


def superficie(z, ang, fuera=0.0):
    """Punto de la superficie del tronco a la altura z y en el ángulo ang (grados; -90 = el frente, -Y)."""
    for i in range(len(TRONCO) - 1):
        (c0, r0, e0), (c1, r1, e1) = TRONCO[i], TRONCO[i + 1]
        if c0[2] <= z <= c1[2] or i == len(TRONCO) - 2:
            t = max(0.0, min(1.0, (z - c0[2]) / (c1[2] - c0[2])))
            c = Vector(c0).lerp(Vector(c1), t)
            r = r0 + (r1 - r0) * t
            sx = e0[0] + (e1[0] - e0[0]) * t
            sy = e0[1] + (e1[1] - e0[1]) * t
            a = math.radians(ang)
            return Vector((c.x + math.cos(a) * (r * sx * 1.06 + fuera), c.y + math.sin(a) * (r * sy * 1.06 + fuera), z))
    return Vector((0, 0, z))


def crear_cuerpo():
    # tronco
    tubo([c for c, r, e in TRONCO], [r for c, r, e in TRONCO], [peso_tronco(c[2]) for c, r, e in TRONCO],
         lados=18, amp=0.09, surcos=9, musgo=0.8, elipse=[e for c, r, e in TRONCO], semilla=0.3, giro=0.35)
    # raíces que envuelven el tronco
    for j, (a0, da, z0, z1) in enumerate([(-30, 95, 0.95, 2.3), (200, -110, 0.95, 2.35), (60, 120, 1.0, 2.2),
                                          (130, -90, 1.0, 2.28), (-150, 70, 1.05, 1.95)]):
        pts, rs, ws = [], [], []
        for i in range(9):
            t = i / 8
            z = z0 + (z1 - z0) * t
            p = superficie(z, a0 + da * t, 0.0)
            pts.append(p)
            rs.append(0.055 - 0.02 * t)
            ws.append(peso_tronco(z))
        tubo(pts, rs, ws, lados=5, amp=0.12, surcos=3, musgo=0.6, semilla=j * 1.7, tapa0=True)
    # setas de repisa (acento cálido)
    for z, ang in [(1.25, 160), (1.33, 175), (1.7, -10), (1.18, 20)]:
        p = superficie(z, ang, 0.03)
        bulto(p, 0.09, peso_tronco(z), escala=(1.1, 1.1, 0.32), subdiv=1, amp=0.1,
              color=lambda d, p: SETA[1] if d.z > 0.2 else SETA[0])
    # corazón (emisivo) y su jaula de raíces
    bulto((0, -0.6, 2.06), 0.165, "corazon", subdiv=2, amp=0.06, color=lambda d, p: LUZ, mat=1)
    for s in (-1, 1):
        for off in (0.11, 0.25):
            tubo([(s * off, -0.60, 2.34), (s * off * 0.85, -0.82, 2.2), (s * off * 0.75, -0.84, 1.98),
                  (s * off * 0.95, -0.66, 1.80)], [0.05, 0.045, 0.045, 0.04], ["pecho"] * 4, lados=6, amp=0.12,
                 surcos=3, musgo=0.3, semilla=off * 10 + s, ref=(0, 1, 0))
    # venas de luz que salen del corazón
    for s in (-1, 1):
        for (a1, z1, a2, z2) in [(-62, 2.12, -30, 2.32), (-60, 1.98, -25, 1.75), (-70, 2.22, -45, 2.42)]:
            if s < 0:
                a1, a2 = -180 - a1, -180 - a2
            pts = [superficie(z1 + (z2 - z1) * t, a1 + (a2 - a1) * t + 6 * math.sin(t * 6), 0.012)
                   for t in [i / 5 for i in range(6)]]
            tubo(pts, [0.022, 0.02, 0.018, 0.015, 0.012, 0.008], ["pecho"] * 6, lados=4, amp=0.0, mat=1,
                 color=lambda p, n: LUZ)
    # cabeza (tocón) y cara
    cab = [((0, -0.22, 2.56), 0.24), ((0, -0.32, 2.66), 0.30), ((0, -0.42, 2.80), 0.33), ((0, -0.47, 2.95), 0.32),
           ((0, -0.46, 3.08), 0.26), ((0, -0.42, 3.15), 0.14)]
    tubo([c for c, r in cab], [r for c, r in cab], [{"cuello": 0.5, "cabeza": 0.5}] + ["cabeza"] * 5, lados=14,
         amp=0.08, surcos=7, musgo=1.0, elipse=[(1.15, 0.95)] * 6, tapa0=False, punta=False, semilla=2.1)
    tubo([(-0.31, -0.62, 2.88), (-0.13, -0.80, 2.98), (0.13, -0.80, 2.98), (0.31, -0.62, 2.88)],
         [0.045, 0.09, 0.09, 0.045], ["cabeza"] * 4, lados=6, amp=0.1, surcos=3, musgo=0.8, semilla=4.0, punta=False,
         ref=(0, 0, 1))
    for s in (-1, 1):
        bulto((s * 0.13, -0.785, 2.865), 0.058, "cabeza", escala=(1.0, 0.55, 0.75), subdiv=1, amp=0.0,
              color=lambda d, p: LUZ, mat=1)
    bulto((0, -0.83, 2.79), 0.075, "cabeza", escala=(0.9, 1.0, 1.2), subdiv=1, amp=0.2, color=lambda d, p: C_CORTEZA)
    tubo([(-0.13, -0.77, 2.67), (0, -0.79, 2.655), (0.13, -0.77, 2.67)], [0.022, 0.025, 0.022], ["cabeza"] * 3,
         lados=5, amp=0.0, color=lambda p, n: GRIETA, punta=False)
    # barba de raíces
    for x in (-0.17, -0.08, 0.0, 0.08, 0.17):
        L = 0.42 - abs(x)
        tubo([(x, -0.70, 2.67), (x * 1.1, -0.76, 2.67 - L * 0.4), (x * 1.25, -0.75, 2.67 - L)],
             [0.035, 0.025, 0.012], ["cabeza"] * 3, lados=5, amp=0.15, surcos=2, musgo=0.4, semilla=x * 20)
    # copa: ramas como astas, con horquillas y hojas
    for (b, d, L) in [((0.12, -0.40, 3.10), (0.45, 0.25, 0.75), 0.85), ((-0.12, -0.40, 3.10), (-0.45, 0.25, 0.75), 0.85),
                      ((0.20, -0.30, 3.00), (0.80, 0.35, 0.40), 0.70), ((-0.20, -0.30, 3.00), (-0.80, 0.35, 0.40), 0.70),
                      ((0.0, -0.35, 3.12), (0.0, 0.50, 0.80), 0.70)]:
        b, d = Vector(b), Vector(d).normalized()
        arriba = Vector((0, 0.15, 0.12))
        pts = [b, b + d * L * 0.35, b + d * L * 0.7 + arriba, b + d * L + arriba * 1.8]
        tubo(pts, [0.07, 0.055, 0.035, 0.014], ["cabeza"] * 4, lados=6, amp=0.12, surcos=3, musgo=0.5,
             semilla=b.x * 7 + 1)
        lado = d.cross(Vector((0, 0, 1)))
        if lado.length < 0.1:
            lado = Vector((1, 0, 0))
        lado.normalize()
        p0 = b + d * L * 0.55 + arriba * 0.5
        d2 = (d + lado * 0.7 + Vector((0, 0, 0.5))).normalized()
        tubo([p0, p0 + d2 * 0.18, p0 + d2 * 0.36 + Vector((0, 0, 0.05))], [0.032, 0.022, 0.01], ["cabeza"] * 3,
             lados=5, amp=0.1, surcos=2, musgo=0.3, semilla=b.x * 3)
        ramillete(pts[-1], d + Vector((0, 0, 0.4)), "cabeza", n=6, tam=0.23)
        ramillete(pts[2], d + Vector((0, 0, 0.6)), "cabeza", n=3, tam=0.18)
        ramillete(p0 + d2 * 0.36 + Vector((0, 0, 0.05)), d2, "cabeza", n=4, tam=0.2)
    # musgo de los hombros y la espalda
    for s in (-1, 1):
        lado = ".L" if s > 0 else ".R"
        for (c, r, e, w) in [((0.38, -0.05, 2.60), 0.20, (1.2, 1.1, 0.5), "pecho"),
                             ((0.58, -0.13, 2.64), 0.22, (1.15, 1.2, 0.5), "hombro" + lado),
                             ((0.78, -0.06, 2.57), 0.18, (1.0, 1.2, 0.55), "hombro" + lado),
                             ((0.52, 0.14, 2.56), 0.19, (1.2, 1.0, 0.55), "pecho")]:
            bulto((c[0] * s, c[1], c[2]), r, w, escala=e, subdiv=1, amp=0.22, color=color_musgo, semilla=c[0] * s * 9)
        # musgo que cuelga de los hombros y los antebrazos
        for (p, L, w) in [((0.86, -0.25, 2.42), 0.38, "hombro" + lado), ((0.70, 0.08, 2.48), 0.30, "hombro" + lado),
                          ((0.97, -0.28, 1.40), 0.32, "antebrazo" + lado), ((1.02, -0.18, 1.55), 0.25, "antebrazo" + lado)]:
            x, y, z = p[0] * s, p[1], p[2]
            tubo([(x, y, z), (x + 0.02 * s, y - 0.01, z - L * 0.5), (x + 0.01 * s, y + 0.01, z - L)],
                 [0.03, 0.025, 0.012], [w] * 3, lados=4, amp=0.2, color=lambda q, n: color_musgo(n, q), punta=True)
        ramillete(Vector((0.62 * s, -0.15, 2.72)), (0.3 * s, -0.2, 1.0), "hombro" + lado, n=3, tam=0.15)
    bulto((0, 0.42, 2.25), 0.30, "pecho", escala=(1.4, 0.45, 0.95), subdiv=1, amp=0.2, color=color_musgo, semilla=3.3)
    # brazos de rama y piernas de raíz
    for s in (-1, 1):
        crear_brazo(s)
        crear_pierna(s)


def crear_brazo(s):
    L = ".L" if s > 0 else ".R"
    X = lambda p: (p[0] * s, p[1], p[2])
    # hombro: un tronco atravesado
    tubo([X((0.20, -0.10, 2.30)), X((0.45, -0.10, 2.36)), X((0.72, -0.11, 2.36)), X((0.88, -0.12, 2.30))],
         [0.26, 0.31, 0.32, 0.25], [{"pecho": 0.5, "hombro" + L: 0.5}] + ["hombro" + L] * 3, lados=12, amp=0.1,
         surcos=6, musgo=1.0, semilla=1.1 * s, punta=False, ref=(0, 0, 1))
    # brazo y antebrazo
    tubo([X((0.78, -0.12, 2.28)), X((0.86, -0.16, 1.98)), X((0.92, -0.20, 1.66)), X((0.95, -0.31, 1.34)),
          X((0.98, -0.42, 1.04)), X((0.99, -0.47, 0.90))],
         [0.26, 0.22, 0.21, 0.19, 0.21, 0.16],
         ["brazo" + L, "brazo" + L, {"brazo" + L: 0.5, "antebrazo" + L: 0.5}, "antebrazo" + L,
          {"antebrazo" + L: 0.5, "mano" + L: 0.5}, "mano" + L], lados=10, amp=0.1, surcos=5, musgo=0.5,
         semilla=2.3 * s, tapa0=False, punta=False)
    bulto(X((0.95, -0.15, 1.68)), 0.13, {"brazo" + L: 0.5, "antebrazo" + L: 0.5}, subdiv=1, amp=0.2,
          color=lambda d, p: mezcla(C_CORTEZA, C_CLARO, d.z * 0.5 + 0.3), semilla=s)
    # dedos de rama
    m = Vector(X((0.99, -0.47, 0.95)))
    for i, ofs in enumerate([[(0.10, -0.06, -0.22), (0.14, -0.12, -0.42), (0.10, -0.24, -0.56)],
                             [(0.02, -0.12, -0.24), (0.00, -0.20, -0.46), (-0.04, -0.34, -0.60)],
                             [(-0.08, -0.08, -0.22), (-0.14, -0.14, -0.42), (-0.16, -0.27, -0.53)],
                             [(-0.12, -0.12, -0.08), (-0.20, -0.22, -0.18), (-0.23, -0.34, -0.30)]]):
        pts = [m] + [m + Vector((o[0] * s, o[1], o[2])) for o in ofs]
        tubo(pts, [0.075, 0.058, 0.042, 0.02], ["mano" + L] * 4, lados=6, amp=0.12, surcos=3, musgo=0.2,
             semilla=i + s * 5)
    # ramitas con hojas en el brazo y el antebrazo
    for (b, ofs, w) in [((0.90, -0.18, 1.86), [(0.15, 0.02, 0.18), (0.24, 0.08, 0.34)], "brazo" + L),
                        ((0.97, -0.38, 1.20), [(0.20, -0.05, 0.10), (0.32, -0.02, 0.26)], "antebrazo" + L)]:
        b = Vector(X(b))
        pts = [b] + [b + Vector((o[0] * s, o[1], o[2])) for o in ofs]
        tubo(pts, [0.04, 0.025, 0.01], [w] * 3, lados=5, amp=0.1, surcos=2, musgo=0.2, semilla=b.z * 4)
        ramillete(pts[-1], pts[-1] - pts[-2], w, n=3, tam=0.15)


def crear_pierna(s):
    L = ".L" if s > 0 else ".R"
    X = lambda p: (p[0] * s, p[1], p[2])
    tubo([X((0.36, 0.05, 1.22)), X((0.42, 0.03, 0.95)), X((0.46, 0.00, 0.68)), X((0.49, 0.04, 0.42)),
          X((0.50, 0.06, 0.22)), X((0.50, 0.06, 0.12))],
         [0.30, 0.27, 0.24, 0.20, 0.21, 0.19],
         [{"cadera": 0.4, "muslo" + L: 0.6}, "muslo" + L, {"muslo" + L: 0.5, "pierna" + L: 0.5}, "pierna" + L,
          {"pierna" + L: 0.5, "pie" + L: 0.5}, "pie" + L], lados=12, amp=0.1, surcos=6, musgo=0.6,
         semilla=3.7 * s, punta=False)
    bulto(X((0.47, -0.10, 0.70)), 0.14, {"muslo" + L: 0.5, "pierna" + L: 0.5}, subdiv=1, amp=0.2,
          color=lambda d, p: mezcla(C_CORTEZA, C_CLARO, d.z * 0.5 + 0.3), semilla=2 * s)
    # pie: raíces que se abren sobre el suelo
    b = Vector(X((0.50, 0.05, 0.19)))
    for i, (ang, largo) in enumerate([(-35, 0.50), (5, 0.62), (40, 0.55), (85, 0.46), (165, 0.40)]):
        a = math.radians(ang)
        d = Vector((math.sin(a) * s, -math.cos(a), 0.0))
        pts = [b, b + d * largo * 0.22 + Vector((0, 0, -0.04)), b + d * largo * 0.62 + Vector((0, 0, -0.13)),
               b + d * largo + Vector((0, 0, -0.16))]
        tubo(pts, [0.10, 0.085, 0.06, 0.025], ["pie" + L] * 4, lados=6, amp=0.12, surcos=3, musgo=0.5,
             semilla=i * 1.3 + s)


# ---------------------------------------------------------------- piezas que se esconden

def crear_coraza():
    pal = CORAZA
    # bandas de raíz que cruzan el pecho, dejando la ventana del corazón
    for (a1, z1, a2, z2) in [(-150, 2.42, -112, 1.74), (-30, 2.42, -68, 1.74), (-165, 2.05, -125, 1.62),
                             (-15, 2.05, -55, 1.62), (-200, 2.47, 20, 2.47)]:
        n = 9
        pts = [superficie(z1 + (z2 - z1) * i / (n - 1), a1 + (a2 - a1) * i / (n - 1), 0.06) for i in range(n)]
        tubo(pts, [0.07] * n, ["coraza"] * n, lados=7, amp=0.12, surcos=3, pal=pal, musgo=0.0,
             semilla=a1 * 0.1, punta=False)
        for k in (2, 5):                                   # espinas
            p = pts[k]
            fuera = (p - Vector((0, -0.05, p.z))).normalized()
            tubo([p, p + fuera * 0.12 + Vector((0, 0, 0.05)), p + fuera * 0.22 + Vector((0, 0, 0.12))],
                 [0.05, 0.03, 0.01], ["coraza"] * 3, lados=5, amp=0.0, pal=pal, musgo=0.0,
                 color=lambda q, nn: mezcla(pal[1], pal[2], 0.6))
    # hombreras: capas de raíz que pasan sobre el hombro, de junto al cuello hacia fuera, y espinas hacia arriba
    for s in (-1, 1):
        w = "coraza.L" if s > 0 else "coraza.R"
        for k, y in enumerate((-0.34, -0.12, 0.10)):
            pts = []
            for i in range(8):
                a = math.radians(160 - 150 * i / 7)
                pts.append(((0.58 + 0.42 * math.cos(a)) * s, y + 0.04 * math.sin(a * 2), 2.34 + 0.42 * math.sin(a)))
            tubo(pts, [0.07, 0.085, 0.09, 0.09, 0.09, 0.085, 0.075, 0.06], [w] * 8, lados=7, amp=0.12, surcos=3,
                 pal=pal, musgo=0.0, semilla=k * 5 + s, punta=True, ref=(0, 1, 0))
        for (x, inc) in [(0.45, 0.25), (0.62, 0.45), (0.78, 0.7)]:
            b = Vector((x * s, -0.08, 2.72))
            d = Vector((inc * s, 0.15, 1.0)).normalized()
            tubo([b, b + d * 0.18, b + d * 0.36], [0.07, 0.04, 0.012], [w] * 3, lados=6, amp=0.0, pal=pal,
                 musgo=0.0, color=lambda q, nn: mezcla(pal[1], pal[2], 0.7))


def crear_musgo_dormido():
    random.seed(11)
    for (c, r, e) in [((0.45, 0.05, 2.62), 0.30, (1.3, 1.2, 0.55)), ((-0.45, 0.05, 2.62), 0.30, (1.3, 1.2, 0.55)),
                      ((0, 0.35, 2.38), 0.40, (1.4, 0.6, 1.0)), ((0, -0.30, 2.52), 0.24, (1.5, 1.0, 0.5)),
                      ((0.80, -0.10, 2.48), 0.24, (1.0, 1.2, 0.6)), ((-0.80, -0.10, 2.48), 0.24, (1.0, 1.2, 0.6)),
                      ((0.25, 0.38, 1.85), 0.25, (1.2, 0.5, 1.2)), ((-0.30, 0.36, 1.70), 0.24, (1.2, 0.5, 1.2))]:
        bulto(c, r, "musgo", escala=e, subdiv=1, amp=0.25, color=color_musgo, semilla=c[0] * 7 + c[2])
    for (x, y) in [(0.3, -0.05), (-0.42, 0.1), (0.62, -0.12), (-0.7, -0.12), (0.05, 0.3)]:
        flor((x, y, 2.66 + 0.04 * random.random()), "musgo", tam=0.06)
    for s in (-1, 1):                                       # musgo que cuelga del pecho y los hombros
        for (x, y, z, L) in [(0.3, -0.45, 2.45, 0.35), (0.62, -0.32, 2.48, 0.42), (0.85, -0.2, 2.4, 0.3)]:
            tubo([(x * s, y, z), (x * s, y - 0.02, z - L * 0.5), (x * s * 1.02, y, z - L)], [0.035, 0.028, 0.012],
                 ["musgo"] * 3, lados=4, amp=0.2, color=lambda q, n: color_musgo(n, q))
    bulto((0, -0.42, 3.13), 0.28, "musgo_cabeza", escala=(1.25, 1.15, 0.5), subdiv=1, amp=0.25, color=color_musgo,
          semilla=8.8)
    bulto((0.18, -0.68, 2.98), 0.13, "musgo_cabeza", escala=(1.2, 0.8, 0.5), subdiv=1, amp=0.2, color=color_musgo)
    flor((-0.1, -0.5, 3.24), "musgo_cabeza", tam=0.06)
    for (x, z, L) in [(-0.22, 2.95, 0.3), (0.25, 2.92, 0.25)]:
        tubo([(x, -0.72, z), (x, -0.76, z - L * 0.5), (x * 1.05, -0.75, z - L)], [0.03, 0.022, 0.01],
             ["musgo_cabeza"] * 3, lados=4, amp=0.2, color=lambda q, n: color_musgo(n, q))
    # el suelo alrededor, con helechos de hojas y flores
    for (x, y, r) in [(0.95, 0.25, 0.32), (-0.95, 0.25, 0.32), (0.65, -0.85, 0.26), (-0.65, -0.85, 0.26),
                      (0.0, 0.75, 0.35), (1.25, -0.35, 0.24), (-1.25, -0.35, 0.24), (0.0, -1.15, 0.22)]:
        bulto((x, y, 0.0), r, "musgo_suelo", escala=(1.6, 1.6, 0.42), subdiv=1, amp=0.25, color=color_musgo, suelo=True,
              semilla=x * 3 + y)
        flor((x + 0.08, y - 0.05, r * 0.4), "musgo_suelo", tam=0.07)
        for k in range(2):
            a = random.uniform(0, 6.28)
            d = Vector((math.cos(a), math.sin(a), 0.9))
            hoja((x, y, r * 0.3), d, (-d.y, d.x, 0.3), 0.3, 0.1, HOJAS[k], "musgo_suelo")


def crear_raices_suelo():
    random.seed(5)
    centro = Vector((0, -1.70, 0))
    for i, (dx, dy, alto) in enumerate([(-0.45, 0.10, 0.95), (-0.15, -0.25, 1.25), (0.20, 0.05, 1.05),
                                        (0.50, -0.20, 0.85), (0.00, 0.32, 0.70), (0.38, 0.35, 0.62)]):
        b = centro + Vector((dx, dy, 0.0))             # brotan del suelo: la base en z = 0
        fuera = Vector((dx, dy - 0.1, 0)).normalized() if (dx or dy) else Vector((0, -1, 0))
        pts = [b, b + Vector((0, 0, 0.15)) + fuera * 0.05, b + Vector((0, 0, alto * 0.45)) + fuera * 0.16,
               b + Vector((0, 0, alto * 0.8)) + fuera * 0.3, b + Vector((0, 0, alto)) + fuera * 0.38]
        tubo(pts, [0.15, 0.13, 0.09, 0.05, 0.015], ["raices_suelo"] * 5, lados=7, amp=0.14, surcos=3,
             pal=RAIZ_NUEVA, musgo=0.3, semilla=i * 2.1, tapa0=False)
    for (dx, dy) in [(-0.6, -0.3), (0.65, 0.15), (-0.2, 0.55), (0.3, -0.6)]:
        bulto(centro + Vector((dx, dy, 0.02)), 0.11, "raices_suelo", escala=(1.3, 1.1, 0.6), subdiv=1, amp=0.3, suelo=True,
              color=lambda d, p: mezcla((0.33, 0.24, 0.15), (0.45, 0.35, 0.22), d.z), semilla=dx)


crear_cuerpo()
crear_coraza()
crear_musgo_dormido()
crear_raices_suelo()


# ---------------------------------------------------------------- esqueleto

HUESOS = [
    ("raiz", (0, 0, 0), (0, 0, 0.4), None),
    ("cadera", (0, 0.05, 1.12), (0, 0.04, 1.42), "raiz"),
    ("columna", (0, 0.04, 1.42), (0, -0.03, 1.90), "cadera"),
    ("pecho", (0, -0.03, 1.90), (0, -0.12, 2.38), "columna"),
    ("cuello", (0, -0.14, 2.42), (0, -0.30, 2.62), "pecho"),
    ("cabeza", (0, -0.30, 2.62), (0, -0.42, 3.05), "cuello"),
    ("corazon", (0, -0.60, 2.06), (0, -0.80, 2.06), "pecho"),
    ("coraza", (0, -0.10, 2.10), (0, -0.10, 2.30), "pecho"),
    ("musgo", (0, 0.0, 2.15), (0, 0.0, 2.35), "pecho"),
    ("musgo_cabeza", (0, -0.42, 2.80), (0, -0.42, 2.95), "cabeza"),
    ("musgo_suelo", (0, 0, 0.0), (0, 0, 0.20), "raiz"),           # en el suelo: crecen desde él
    ("raices_suelo", (0, -1.70, 0.0), (0, -1.70, 0.20), "raiz"),
]
for s, L in ((1, ".L"), (-1, ".R")):
    X = lambda p: (p[0] * s, p[1], p[2])
    HUESOS += [
        ("hombro" + L, X((0.20, -0.10, 2.30)), X((0.72, -0.11, 2.34)), "pecho"),
        ("coraza" + L, X((0.55, -0.11, 2.36)), X((0.55, -0.11, 2.50)), "hombro" + L),
        ("brazo" + L, X((0.76, -0.12, 2.30)), X((0.92, -0.20, 1.66)), "hombro" + L),
        ("antebrazo" + L, X((0.92, -0.20, 1.66)), X((0.98, -0.42, 1.02)), "brazo" + L),
        ("mano" + L, X((0.98, -0.42, 1.02)), X((1.00, -0.55, 0.50)), "antebrazo" + L),
        ("muslo" + L, X((0.36, 0.05, 1.18)), X((0.46, 0.00, 0.68)), "cadera"),
        ("pierna" + L, X((0.46, 0.00, 0.68)), X((0.50, 0.06, 0.20)), "muslo" + L),
        ("pie" + L, X((0.50, 0.06, 0.20)), X((0.50, -0.25, 0.06)), "pierna" + L),
    ]
NOMBRES = [h[0] for h in HUESOS]

arm_data = bpy.data.armatures.new("Guardian_esqueleto")
arm = bpy.data.objects.new("Guardian", arm_data)
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
REPOSO_ROT = {b.name: b.matrix_local.to_quaternion() for b in arm_data.bones}

# ---------------------------------------------------------------- la malla en Blender

me = bpy.data.meshes.new("Guardian_malla")
me.from_pydata([tuple(v) for v in M.v], [], M.caras)
me.update()
bm = bmesh.new()
bm.from_mesh(me)
bm.faces.ensure_lookup_table()
bmesh.ops.recalc_face_normals(bm, faces=[bm.faces[i] for i, c in enumerate(M.cerradas) if c])
bm.to_mesh(me)
bm.free()
me.polygons.foreach_set("material_index", M.mats)
attr = me.color_attributes.new("Color", 'FLOAT_COLOR', 'POINT')
cols = []
for c in M.col:
    cols += list(c) + [1.0]          # en sRGB, sin pasar a lineal: ver la nota de los colores de vértice
attr.data.foreach_set("color", cols)
me.color_attributes.active_color = attr
me.shade_smooth()

cuerpo = bpy.data.objects.new("Cuerpo", me)
sc.collection.objects.link(cuerpo)
cuerpo.parent = arm
for n in NOMBRES:
    cuerpo.vertex_groups.new(name=n)
for i, w in enumerate(M.pesos):
    for h, p in w.items():
        cuerpo.vertex_groups[h].add([i], p, 'REPLACE')
mod = cuerpo.modifiers.new("Esqueleto", 'ARMATURE')
mod.object = arm


def material_corteza():
    m = bpy.data.materials.new("corteza")
    m.use_backface_culling = True                 # una cara: las hojas ya tienen sus dos caras en la malla
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    ca = nt.nodes.new("ShaderNodeVertexColor")
    ca.layer_name = "Color"
    gam = nt.nodes.new("ShaderNodeGamma")         # solo para ver el color bien en Blender (el atributo va en sRGB)
    gam.inputs["Gamma"].default_value = 2.2
    nt.links.new(ca.outputs["Color"], gam.inputs["Color"])
    nt.links.new(gam.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.85
    bsdf.inputs["Metallic"].default_value = 0.0
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.25
    return m


def material_luz():
    m = bpy.data.materials.new("luz")
    m.use_backface_culling = True
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*lineal((0.45, 0.62, 0.22)), 1.0)
    bsdf.inputs["Roughness"].default_value = 0.4
    bsdf.inputs["Emission Color"].default_value = (*lineal(LUZ), 1.0)
    bsdf.inputs["Emission Strength"].default_value = 1.0
    return m


me.materials.append(material_corteza())
me.materials.append(material_luz())

print("MALLA vértices", len(M.v), "caras", len(M.caras),
      "triángulos", sum(len(f) - 2 for f in M.caras), "huesos", len(NOMBRES))

# Índices de vértices por zona (para apoyar las poses en el suelo)
def indices(huesos):
    return np.array([i for i, w in enumerate(M.pesos) if max(w, key=w.get) in huesos], dtype=np.int64)


PIERNAS = indices({h + s for h in ("muslo", "pierna", "pie") for s in (".L", ".R")})
MANOS = {s: indices({h + s for h in ("brazo", "antebrazo", "mano")}) for s in (".L", ".R")}


# ---------------------------------------------------------------- poses

EJES = {"X": Vector((1, 0, 0)), "Y": Vector((0, 1, 0)), "Z": Vector((0, 0, 1))}
OCULTO = 0.01
ESCALA_BASE = {"corazon": 1.0, "coraza": 1.0, "coraza.L": 1.0, "coraza.R": 1.0, "musgo": OCULTO,
               "musgo_cabeza": OCULTO, "musgo_suelo": OCULTO, "raices_suelo": OCULTO}


class Pose:
    def __init__(self):
        self.rot = {}
        self.esc = dict(ESCALA_BASE)
        self.desp = (0.0, 0.0)
        self.alto = 0.0
        self.manos = False       # apoyar las manos en el suelo (poses de rodillas)

    def r(self, hueso, *giros):
        self.rot.setdefault(hueso, []).extend(giros)
        return self

    def par(self, hueso, *giros):
        self.r(hueso + ".L", *giros)
        self.r(hueso + ".R", *[(e, g if e == "X" else -g) for e, g in giros])
        return self

    def e(self, hueso, valor):
        self.esc[hueso] = valor
        return self

    def coraza(self, valor, lados=None):
        self.esc["coraza"] = valor
        self.esc["coraza.L"] = self.esc["coraza.R"] = valor if lados is None else lados
        return self


def cuaternion(hueso, giros):
    r = REPOSO_ROT[hueso]
    q = Quaternion()
    for e, g in giros:
        q = (r.inverted() @ Quaternion(EJES[e], math.radians(g)) @ r) @ q
    return q


def poner(pose, extra=None):
    for pb in arm.pose.bones:
        pb.rotation_mode = 'QUATERNION'
        giros = pose.rot.get(pb.name, []) + (extra or {}).get(pb.name, [])
        pb.rotation_quaternion = cuaternion(pb.name, giros)
        pb.location = (0, 0, 0)
        s = pose.esc.get(pb.name, 1.0)
        pb.scale = (s, s, s)


def coordenadas():
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    ob = cuerpo.evaluated_get(dg)
    m = ob.to_mesh()
    a = np.empty(len(m.vertices) * 3, dtype=np.float32)
    m.vertices.foreach_get("co", a)
    ob.to_mesh_clear()
    return a.reshape(-1, 3)


def resolver(pose):
    """Giros finales de la pose (con el ajuste de manos) y la posición de la raíz que apoya las piernas."""
    extra = {}
    if pose.manos:
        for s in (".L", ".R"):
            mejor = None
            for d in range(-50, 42, 2):
                g = d if s == ".L" else d
                prueba = dict(extra)
                prueba["brazo" + s] = [("X", g)]
                poner(pose, prueba)
                co = coordenadas()
                suelo = co[PIERNAS][:, 2].min()
                altura_mano = co[MANOS[s]][:, 2].min() - suelo
                err = abs(altura_mano - 0.03)
                if mejor is None or err < mejor[0]:
                    mejor = (err, g, altura_mano)
            extra["brazo" + s] = [("X", mejor[1])]
            print("   manos", s, "ajuste %+d°" % mejor[1], "altura %.3f" % mejor[2])
    poner(pose, extra)
    co = coordenadas()
    z = -float(co[PIERNAS][:, 2].min()) + pose.alto
    return extra, Vector((pose.desp[0], pose.desp[1], z))


def reposo(resp=0.0, mece=0.0):
    p = Pose()
    p.r("cadera", ("Z", 2.5 * mece), ("Y", 1.2 * mece))
    p.r("columna", ("X", 6), ("Y", 1.0 * mece))
    p.r("pecho", ("X", 7 - 3 * resp), ("Z", 1.5 * mece))
    p.r("cuello", ("X", -3))
    p.r("cabeza", ("X", -6 + 2 * resp), ("Z", -2.0 * mece))
    p.par("hombro", ("Y", -3 * resp))
    p.par("brazo", ("X", -8), ("Y", -6 - 1.5 * resp))
    p.par("antebrazo", ("X", -18 - 4 * resp))
    p.par("mano", ("X", -8 - 3 * resp))
    p.par("muslo", ("X", -10))
    p.par("pierna", ("X", 17))
    p.par("pie", ("X", -7))
    p.e("corazon", 1.0 + 0.07 * resp)
    return p


def encorvado(lat=0.0):
    """La pose de carga: encorvado, los brazos recogidos ante el pecho y el corazón latiendo."""
    p = Pose()
    p.r("cadera", ("X", 4))
    p.r("columna", ("X", 16))
    p.r("pecho", ("X", 20), ("Z", 1.2 * lat))
    p.r("cuello", ("X", -10))
    p.r("cabeza", ("X", -16 - 2 * lat))
    p.par("hombro", ("Y", -6 - 2 * lat))
    p.par("brazo", ("X", -30), ("Y", 18))
    p.par("antebrazo", ("X", -38))
    p.par("mano", ("X", -18 + 6 * lat))
    p.par("muslo", ("X", -22))
    p.par("pierna", ("X", 35))
    p.par("pie", ("X", -13))
    p.e("corazon", 1.0 + 0.3 * lat)
    return p


def rodillas(s=1.0, cabeza=0.0):
    """De rodillas: muslos casi verticales, espinillas y raíces de los pies sobre el suelo, el cuerpo vencido."""
    p = Pose()
    p.r("columna", ("X", 18 + 8 * s))
    p.r("pecho", ("X", 12 + 8 * s), ("Z", -3 * s))
    p.r("cuello", ("X", 6))
    p.r("cabeza", ("X", 10 + 6 * s + cabeza), ("Z", 8 * s))
    p.par("hombro", ("Y", 4))
    p.r("brazo.L", ("Y", -8))
    p.r("brazo.R", ("Y", 8))
    p.par("antebrazo", ("X", -30))
    p.par("mano", ("X", -12))
    p.par("muslo", ("X", -6))
    p.par("pierna", ("X", 90))
    p.par("pie", ("X", 88))
    p.manos = True
    return p


# ---------------------------------------------------------------- clips: [(fotograma, pose)]

def clip_reposo():
    return [(1, reposo(0, 0)), (19, reposo(0.5, 1)), (37, reposo(1, 0)), (55, reposo(0.5, -1)), (73, reposo(0, 0))]


def clip_ataque():
    # latigazo de rama con el brazo derecho (el que queda hacia la cámara del combate). IMPACTO: fotograma 19 (0,6 s)
    alzar = reposo().r("columna", ("X", -10)).r("pecho", ("X", -12), ("Z", -16)).r("cabeza", ("X", -4), ("Z", 10))
    alzar.rot["brazo.R"] = [("X", -170), ("Y", 14)]
    alzar.rot["antebrazo.R"] = [("X", -40)]
    alzar.rot["mano.R"] = [("X", -32)]
    alzar.rot["brazo.L"] = [("X", -24), ("Y", -10)]
    alzar.rot["muslo.R"] = [("X", -2)]
    # (el giro del brazo en el mundo es su giro en X más la inclinación del tronco: columna + pecho)
    medio = reposo().r("columna", ("X", 2)).r("pecho", ("X", 2), ("Z", 0)).r("cabeza", ("X", -8))
    medio.rot["brazo.R"] = [("X", -152), ("Y", 10)]          # arriba y adelante (-135° en el mundo)
    medio.rot["antebrazo.R"] = [("X", -45)]                  # el antebrazo y la mano se quedan atrás: el látigo
    medio.rot["mano.R"] = [("X", -40)]
    medio.rot["brazo.L"] = [("X", 0), ("Y", -10)]
    golpe = reposo().r("columna", ("X", 6), ("Z", 6)).r("pecho", ("X", 4), ("Z", 14)).r("cabeza", ("X", -10), ("Z", -8))
    golpe.rot["brazo.R"] = [("X", -93), ("Z", 10)]           # rama al frente, un poco por debajo del hombro
    golpe.rot["antebrazo.R"] = [("X", 0)]
    golpe.rot["mano.R"] = [("X", 25)]                        # la punta restalla hacia abajo
    golpe.rot["brazo.L"] = [("X", 22), ("Y", -12)]
    golpe.rot["muslo.R"] = [("X", -20)]
    golpe.e("corazon", 1.08)
    sigue = reposo().r("columna", ("X", 8), ("Z", 4)).r("pecho", ("X", 8), ("Z", 10)).r("cabeza", ("X", -12))
    sigue.rot["brazo.R"] = [("X", -89), ("Z", 10)]
    sigue.rot["antebrazo.R"] = [("X", 6)]
    sigue.rot["mano.R"] = [("X", 12)]
    sigue.rot["brazo.L"] = [("X", 15), ("Y", -10)]
    sigue.rot["muslo.R"] = [("X", -18)]
    return [(1, reposo()), (11, alzar), (16, medio), (19, golpe), (25, sigue), (42, reposo())]


def clip_carga():
    return [(1, encorvado(0)), (5, encorvado(1)), (9, encorvado(0.3)), (13, encorvado(0.8)), (21, encorvado(0)),
            (37, encorvado(0))]


def clip_golpe_fuerte():
    # sale de la pose de carga, se yergue con los brazos en alto y los descarga contra el suelo; brotan raíces.
    # IMPACTO: fotograma 21 (0,667 s)
    alto = Pose()
    alto.r("columna", ("X", -10)).r("pecho", ("X", -12)).r("cuello", ("X", -5)).r("cabeza", ("X", -20))
    alto.par("hombro", ("Y", -10)).par("brazo", ("X", -165), ("Y", -12)).par("antebrazo", ("X", -25))
    alto.par("mano", ("X", -15)).par("muslo", ("X", -6)).par("pierna", ("X", 10)).par("pie", ("X", -4))
    alto.e("corazon", 1.35)

    def abajo(k, raices):
        p = Pose()
        p.r("columna", ("X", 30 + 4 * k)).r("pecho", ("X", 24 + 3 * k)).r("cuello", ("X", -6)).r("cabeza", ("X", -10))
        p.par("hombro", ("Y", 4)).par("brazo", ("X", -58), ("Y", 8)).par("antebrazo", ("X", -6)).par("mano", ("X", 8))
        p.par("muslo", ("X", -30 - 3 * k)).par("pierna", ("X", 50 + 4 * k)).par("pie", ("X", -18))
        p.e("corazon", 1.2).e("raices_suelo", raices)
        return p
    return [(1, encorvado(0)), (12, alto), (18, abajo(0, OCULTO)), (21, abajo(1, 0.6)), (24, abajo(1, 1.15)),
            (31, abajo(0.8, 1.0)), (43, abajo(0.3, OCULTO)), (60, reposo())]


def clip_herido():
    golpe = reposo().r("columna", ("X", -10)).r("pecho", ("X", -14), ("Z", 6)).r("cuello", ("X", -6))
    golpe.r("cabeza", ("X", -16), ("Z", 10)).par("brazo", ("X", 18), ("Y", -10)).par("antebrazo", ("X", 8))
    golpe.e("corazon", 0.88)
    rebote = reposo().r("columna", ("X", -3)).r("pecho", ("X", -5), ("Z", 2)).r("cabeza", ("X", -6), ("Z", 3))
    return [(1, reposo()), (4, golpe), (10, rebote), (24, reposo())]


def clip_fase2():
    recoge = encorvado(0.5)
    recoge.rot.pop("brazo.L"); recoge.rot.pop("brazo.R"); recoge.rot.pop("antebrazo.L"); recoge.rot.pop("antebrazo.R")
    recoge.par("brazo", ("Y", 30), ("X", -70)).par("antebrazo", ("X", -70), ("Z", -25)).par("mano", ("X", -20))
    recoge.coraza(OCULTO).e("corazon", 1.2)
    tenso = encorvado(0.8)
    tenso.rot = {k: list(v) for k, v in recoge.rot.items()}
    tenso.r("pecho", ("Z", 2))
    tenso.coraza(OCULTO).e("corazon", 1.45)

    def erguido(k, coraza, lados, corazon):
        p = Pose()
        p.r("columna", ("X", -14 * k)).r("pecho", ("X", -16 * k)).r("cuello", ("X", -6 * k)).r("cabeza", ("X", -22 * k))
        p.par("hombro", ("Y", -10 * k)).par("brazo", ("Y", -75 * k), ("X", -25 * k)).par("antebrazo", ("X", -20 * k))
        p.par("mano", ("X", -20 * k)).par("muslo", ("X", -4)).par("pierna", ("X", 6)).par("pie", ("X", -2))
        p.coraza(coraza, lados).e("corazon", corazon)
        return p
    return [(1, reposo().coraza(OCULTO)), (14, recoge), (22, tenso), (32, erguido(1.0, 0.7, 0.6, 1.5)),
            (38, erguido(1.0, 1.12, 1.12, 1.35)), (46, erguido(0.6, 1.0, 1.0, 1.2)), (78, reposo())]


def clip_derrota():
    golpe = reposo().r("columna", ("X", -10)).r("pecho", ("X", -12)).r("cabeza", ("X", -18), ("Z", 6))
    golpe.par("brazo", ("X", 14), ("Y", -8)).e("corazon", 0.95)
    cede = Pose()
    cede.r("columna", ("X", 14)).r("pecho", ("X", 18)).r("cuello", ("X", 6)).r("cabeza", ("X", 25), ("Z", 5))
    cede.par("brazo", ("X", 6), ("Y", -4)).par("antebrazo", ("X", -5)).par("mano", ("X", -4))
    cede.par("muslo", ("X", -32)).par("pierna", ("X", 58)).par("pie", ("X", -22)).e("corazon", 0.85)
    cae = rodillas(0.3).e("corazon", 0.75)
    queda = rodillas(1.0).e("corazon", 0.6)
    return [(1, reposo()), (6, golpe), (20, cede), (34, cae), (50, queda), (72, rodillas(1.0).e("corazon", 0.6))]


def clip_dormido():
    def dormido(corazon):
        p = rodillas(0.6, cabeza=6)
        p.coraza(OCULTO).e("corazon", corazon)
        p.e("musgo", 1.0).e("musgo_cabeza", 1.0).e("musgo_suelo", 1.0)
        return p
    return [(1, dormido(0.8)), (46, dormido(0.87)), (91, dormido(0.8))]


CLIPS = {
    "reposo": clip_reposo(),
    "ataque": clip_ataque(),
    "carga": clip_carga(),
    "golpe_fuerte": clip_golpe_fuerte(),
    "herido": clip_herido(),
    "fase2": clip_fase2(),
    "derrota": clip_derrota(),
    "dormido": clip_dormido(),
}


# ---------------------------------------------------------------- acciones

def curvas(accion):
    res = []
    for capa in accion.layers:
        for tira in capa.strips:
            for bolsa in tira.channelbags:
                res += list(bolsa.fcurves)
    return res


arm.animation_data_create()
ad = arm.animation_data
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')


def crear_accion(nombre, claves):
    print("CLIP", nombre)
    resueltas = []
    for f, pose in claves:
        extra, raiz = resolver(pose)
        resueltas.append((f, pose, extra, raiz))
    act = bpy.data.actions.new(nombre)
    act.use_fake_user = True
    ad.action = act
    previo = {}
    for f, pose, extra, raiz in resueltas:
        poner(pose, extra)
        for pb in arm.pose.bones:
            q = pb.rotation_quaternion.copy()
            if pb.name in previo and previo[pb.name].dot(q) < 0:
                q.negate()
            previo[pb.name] = q
            pb.rotation_quaternion = q
            if pb.name == "raiz":
                pb.location = REPOSO_ROT["raiz"].inverted() @ raiz
            pb.keyframe_insert("rotation_quaternion", frame=f, group=pb.name)
            pb.keyframe_insert("location", frame=f, group=pb.name)
            pb.keyframe_insert("scale", frame=f, group=pb.name)
        print("   f%-3d raiz z %.3f" % (f, raiz.z))
    for fc in curvas(act):
        for k in fc.keyframe_points:
            k.interpolation = 'BEZIER'
            k.handle_left_type = k.handle_right_type = 'AUTO_CLAMPED'
        fc.update()
    ad.action = None
    pista = ad.nla_tracks.new()
    pista.name = nombre
    pista.strips.new(nombre, int(claves[0][0]), act)
    pista.mute = True
    return act


for nombre, claves in CLIPS.items():
    crear_accion(nombre, claves)

ad.action = None
poner(reposo())
bpy.ops.object.mode_set(mode='OBJECT')
for t in ad.nla_tracks:
    t.mute = False

if SALIDA_BLEND:
    bpy.ops.wm.save_as_mainfile(filepath=SALIDA_BLEND)
    print("GUARDADO", SALIDA_BLEND)

if SALIDA_GLB:
    bpy.ops.export_scene.gltf(
        filepath=SALIDA_GLB, export_format='GLB', use_selection=False,
        export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=True,
        export_anim_slide_to_zero=True, export_def_bones=False, export_reset_pose_bones=True,
        export_optimize_animation_size=False, export_skins=True, export_yup=True,
        export_vertex_color='ACTIVE', export_cameras=False, export_lights=False)
    print("EXPORTADO", SALIDA_GLB)
