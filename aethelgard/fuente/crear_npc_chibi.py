# Familia de NPC chibi de REBELUM (V12, especialista de mundo 3D y NPC, 12/11/2026). Obra propia, sin recursos
# descargados: geometría por partes, atlas pintado por código, esqueleto común y clips con claves.
#
#   blender -b --factory-startup -P fuente/crear_npc_chibi.py -- <raíz aethelgard> <carpeta de láminas> [oficio,oficio…]
#
# Reutiliza la biblioteca de los NPC del desierto (personajes/desierto/fuentes_blender/desierto_comun.py: Atlas, Lienzo,
# Malla, esqueleto, clips y exportación) SIN tocarla: se importa tal cual.
#
# Escribe, por oficio, personajes/npc_v12/<oficio>/<oficio>.glb (malla con su atlas de la primera persona, esqueleto
# común y clips) y un atlas por cada persona de ese oficio (<persona>.png: la misma disposición, otros colores y otra
# cara), que Godot pone encima (personajes/npc_v12/npc_chibi.gd). Una persona = oficio + paleta + cara.
#
# ESQUELETO COMÚN (los mismos nombres que Ismena y Oren): raiz, cadera, columna, pecho, cuello, cabeza, parpado.L/R,
# hombro.L/R, brazo.L/R, antebrazo.L/R, mano.L/R, muslo.L/R, pierna.L/R, pie.L/R. Las proporciones cambian por oficio
# (Figura: altura del cuerpo, anchura, barriga y cabeza), pero los clips son giros: la misma biblioteca sirve a todos.
#
# CLIPS (30 fps; todos parten y acaban en el reposo de su oficio; en bucle: reposo, caminar, correr, tarea):
#   reposo (4 s)  caminar (1 s, en el sitio; Godot mueve el nodo)  correr (0,6 s, solo niños)  hablar (2,5 s)
#   saludar (1,6 s)  tarea (la de su oficio: martillar, pregonar, remover, vigilar, cavar, recoger, estirar, echar_grano,
#   jugar, ajustar, barrer)
#
# Ejes de Blender: el personaje mira a -Y, Z arriba, su izquierda es +X. En Godot mira a +Z.
import bpy, sys, os, math, json
from mathutils import Vector, Euler, Matrix

argv = sys.argv[sys.argv.index("--") + 1:]
RAIZ = argv[0]
LAMINAS = argv[1]
SOLO = argv[2].split(",") if len(argv) > 2 and argv[2] else []
sys.dont_write_bytecode = True          # sin __pycache__ en la carpeta de otra área
sys.path.insert(0, os.path.join(RAIZ, "personajes", "desierto", "fuentes_blender"))
import desierto_comun as C

# 4.º argumento opcional: otra carpeta de salida (para sacar el atlas de una persona nueva sin rehacer los GLB del
# proyecto; luego se copia solo ese .png).
SALIDA = argv[3] if len(argv) > 3 and argv[3] else os.path.join(RAIZ, "personajes", "npc_v12")
# V2 (pulido, 13/11): sombreado suave, manos y botas redondeadas, pelo por mechones con volumen, telas con pliegues y
# ribetes, y caras más expresivas en una loseta mayor (384 px en vez de 256 dentro del mismo atlas de 512). La v1 queda
# en personajes/npc_v12/v1/ (con .gdignore) y su guion en v1/crear_npc_chibi_v1.py.
PRESUPUESTO_TRIS = 6000          # por NPC (Ismena, el prototipo del desierto, 5 706); lo comprueba prueba_mundo_vivo
SOMBRERO = {"mercader", "guardia", "campesino", "campesina", "viajero", "barrendero"}
_oficio_actual = ""


class AtlasNPC(C.Atlas):
    """El atlas de 512 con otra disposición: la cara en una loseta de 384 (abajo a la izquierda), el emblema en una de
    128 (arriba a la derecha) y las muestras de color en celdas de 32 (la franja de arriba y la columna derecha)."""

    def __init__(self, tam=512, semilla=3):
        super().__init__(tam, semilla)
        self.celda = 32

    def _celda(self, i):
        if i < 48:                                   # franja de arriba: 12 × 4 (x 0-384, y 384-512)
            return (i % 12) * 32, 512 - (i // 12 + 1) * 32
        i -= 48                                      # columna derecha: 4 × 12 (x 384-512, y 0-384)
        return 384 + (i % 4) * 32, 384 - (i // 4 + 1) * 32

    def muestra(self, nombre, rgb, oscuro=0.80, claro=1.06, grano=0.025, plano=False):
        import numpy as np
        x0, y0 = self._celda(len(self.muestras))
        c = 32
        t = np.linspace(0, 1, c)[:, None]
        f = np.ones((c, 1)) if plano else (oscuro + (claro - oscuro) * t)
        bloque = np.array(rgb, dtype=np.float32)[None, None, :] * f[:, :, None]
        if grano > 0 and not plano:
            bloque = bloque * (1.0 + self.rng.normal(0, grano, (c, c, 1)))
        self.img[y0:y0 + c, x0:x0 + c, :3] = np.clip(bloque, 0, 1)
        self.muestras[nombre] = (x0 / self.tam, y0 / self.tam, c / self.tam)
        return nombre

    def loseta(self, cual):
        return (0, 0, 384) if cual == "cara" else (384, 384, 128)

# ================================================================== proporciones

# Medidas de la figura base (las de Ismena y Oren, en metros): el cuerpo hasta el cuello y la cabeza aparte.
B_CAB_C = Vector((0, 0, 1.24))
B_CAB_R = (0.265, 0.245, 0.25)
B_HOMBRO = Vector((0.15, 0.0, 0.885))
B_CODO = Vector((0.215, 0.0, 0.705))
B_MUNECA = Vector((0.255, -0.012, 0.545))
B_MANO_F = Vector((0.268, -0.018, 0.46))
B_CADERA_L = Vector((0.085, 0.0, 0.54))
B_RODILLA = Vector((0.09, 0.0, 0.28))
B_TOBILLO = Vector((0.09, 0.012, 0.085))
B_PUNTA = Vector((0.09, -0.11, 0.02))
CUELLO_Z = 1.0


class Figura:
    """sb: altura del cuerpo; sx: anchura de brazos y piernas; st: anchura del tronco (barriga); sh: tamaño de cabeza."""

    def __init__(self, sb=1.0, sx=1.0, st=1.0, sh=1.0, ojo=(0.17, 0.44, 0.092, 0.114)):
        self.sb, self.sx, self.st, self.sh = sb, sx, st, sh
        self.ojo = ojo
        self.cab_c = self.h(B_CAB_C)
        self.cab_r = tuple(r * sh for r in B_CAB_R)
        self.hombro = self.b(B_HOMBRO, tronco=True)
        self.codo = self.b(B_CODO, tronco=True)
        self.muneca = self.b(B_MUNECA, tronco=True)
        self.mano_f = self.b(B_MANO_F, tronco=True)
        self.cadera_l = self.b(B_CADERA_L)
        self.rodilla = self.b(B_RODILLA)
        self.tobillo = self.b(B_TOBILLO)
        self.punta = self.b(B_PUNTA)

    def b(self, v, tronco=False):
        """Un punto del cuerpo de la figura base → esta figura (los brazos salen del tronco: más anchos con barriga)."""
        v = Vector(v)
        k = self.sx * ((1 + (self.st - 1) * 0.55) if tronco else 1)
        return Vector((v.x * k, v.y * k, v.z * self.sb))

    def t(self, v):
        """Un punto del tronco (con la barriga)."""
        v = Vector(v)
        k = self.sx * self.st
        return Vector((v.x * k, v.y * k, v.z * self.sb))

    def h(self, v):
        """Un punto de la cabeza (relativo al cuello de la figura base)."""
        v = Vector(v)
        return Vector((v.x * self.sh, v.y * self.sh, CUELLO_Z * self.sb + (v.z - CUELLO_Z) * self.sh))

    def z(self, z):
        return z * self.sb

    def zh(self, z):
        return CUELLO_Z * self.sb + (z - CUELLO_Z) * self.sh

    def cadena(self, pares):
        c = [(self.z(z), n) for z, n in pares]
        return lambda co: por_altura(co.z, c)


def por_altura(z, cadena):
    """Como desierto_comun.por_altura, pero SUMA los pesos cuando dos puntos seguidos son del mismo hueso (allí un
    diccionario {h: 1 - t, h: t} se quedaba con t, y en el borde exacto el vértice salía sin peso)."""
    if z <= cadena[0][0]:
        return {cadena[0][1]: 1.0}
    for (za, ha), (zb, hb) in zip(cadena, cadena[1:]):
        if z <= zb:
            t = (z - za) / max(zb - za, 1e-6)
            t = t * t * (3 - 2 * t)
            w = {ha: 1 - t}
            w[hb] = w.get(hb, 0.0) + t
            return w
    return {cadena[-1][1]: 1.0}


def por_eje(a, b, cadena):
    a, b = Vector(a), Vector(b)
    eje = b - a
    l2 = eje.length_squared
    return lambda co: por_altura((co - a).dot(eje) / l2, cadena)


def esp(v, lado):
    return Vector((v.x * lado, v.y, v.z))


def huesos(F):
    h = [("raiz", (0, 0, 0), (0, 0, 0.12), None),
         ("cadera", (0, 0, F.z(0.54)), (0, 0, F.z(0.62)), "raiz"),
         ("columna", (0, 0, F.z(0.62)), (0, 0, F.z(0.74)), "cadera"),
         ("pecho", (0, 0, F.z(0.74)), (0, 0, F.z(0.92)), "columna"),
         ("cuello", (0, 0, F.z(0.92)), (0, 0, F.z(1.0)), "pecho"),
         ("cabeza", (0, 0, F.z(1.0)), (0, 0, F.zh(1.46)), "cuello")]
    for s, l in (("L", 1), ("R", -1)):
        ojo_top = ojo_mundo(F, l, arriba=True)
        h += [("parpado." + s, ojo_top, ojo_top + Vector((0, 0, -0.05)), "cabeza"),
              ("hombro." + s, (0.04 * l, 0, F.z(0.875)), esp(F.hombro, l), "pecho"),
              ("brazo." + s, esp(F.hombro, l), esp(F.codo, l), "hombro." + s),
              ("antebrazo." + s, esp(F.codo, l), esp(F.muneca, l), "brazo." + s),
              ("mano." + s, esp(F.muneca, l), esp(F.mano_f, l), "antebrazo." + s),
              ("muslo." + s, esp(F.cadera_l, l), esp(F.rodilla, l), "cadera"),
              ("pierna." + s, esp(F.rodilla, l), esp(F.tobillo, l), "muslo." + s),
              ("pie." + s, esp(F.tobillo, l), esp(F.punta, l), "pierna." + s)]
    return h


# ================================================================== la cara

def cara_uv(F, co):
    return ((co.x - F.cab_c.x) / (2 * F.cab_r[0]) + 0.5, (co.z - F.cab_c.z) / (2 * F.cab_r[2]) + 0.5)


def barbilla_k(F, z):
    d = (F.cab_c.z - z) / F.cab_r[2]
    return 1.0 - 0.22 * max(d, 0) ** 2


def deform_cabeza(F):
    def f(co):
        k = barbilla_k(F, co.z)
        return Vector((co.x * k, co.y * k, co.z))
    return f


def ojo_mundo(F, lado, arriba=False):
    sep, alto, rx, ry = F.ojo
    u = 0.5 + sep * lado
    v = alto + (ry * 1.18 if arriba else 0.0)
    x = (u - 0.5) * 2 * F.cab_r[0]
    z = (v - 0.5) * 2 * F.cab_r[2] + F.cab_c.z
    nx, nz = x / F.cab_r[0], (z - F.cab_c.z) / F.cab_r[2]
    ny = -math.sqrt(max(1 - nx * nx - nz * nz, 0.01))
    return Vector((x, ny * F.cab_r[1] * barbilla_k(F, z), z))


def oscuro(c, k):
    return tuple(x * k for x in c)


def dibujar_cara(A, F, P):
    """V2: la cara con más acabado (como los protagonistas, en pequeño): ojo con contorno del iris, degradado, reflejo
    bajo y dos brillos, párpado grueso con rabillo, pliegue del párpado y pestaña de abajo; cejas con forma; rubor con
    rayitas; nariz con brillo; boca con color dentro. Mismos estilos que la v1."""
    L = C.Lienzo(A, "cara")
    L.fondo(P["piel"])
    sep, alto, rx, ry = F.ojo
    estilo = P.get("ojos", "normal")
    piel = P["piel"]
    pest = P["pestanas"]
    # rubor y sus rayitas
    for s in (-1, 1):
        L.elipse(0.5 + s * 0.205, 0.325, 0.065, 0.034, P["rubor"], 0.30 if not P.get("arrugas") else 0.16)
        if not P.get("arrugas"):
            for k in range(3):
                x = 0.5 + s * (0.18 + 0.022 * k)
                L.linea([(x - 0.006, 0.312), (x + 0.008, 0.336)], 0.0035, oscuro(P["rubor"], 0.85), 0.55)
    # nariz: sombra pequeña y un brillo
    L.elipse(0.505, 0.36, 0.011, 0.007, oscuro(piel, 0.78), 0.7)
    L.elipse(0.497, 0.368, 0.005, 0.004, (1, 1, 1), 0.35)
    if P.get("pecas"):
        for (x, y) in ((0.30, 0.37), (0.33, 0.35), (0.28, 0.345), (0.70, 0.37), (0.67, 0.35), (0.72, 0.345),
                       (0.315, 0.335), (0.685, 0.335)):
            L.elipse(x, y, 0.0055, 0.0045, oscuro(piel, 0.68), 0.75)
    if P.get("arrugas"):
        for s in (-1, 1):
            L.arco(0.5 + s * 0.12, 0.30, 0.06, 0.05, 200 if s < 0 else 280, 260 if s < 0 else 340, 0.005,
                   oscuro(piel, 0.76), 0.8)
            for k in range(2):
                L.linea([(0.5 + s * (sep + rx * 1.05), alto - 0.005 - 0.02 * k),
                         (0.5 + s * (sep + rx * 1.4), alto - 0.025 - 0.025 * k)], 0.0035, oscuro(piel, 0.76), 0.8)
            L.arco(0.5 + s * sep, alto + ry + 0.06, 0.06, 0.02, 30, 150, 0.004, oscuro(piel, 0.8), 0.6)
    for s in (-1, 1):
        cx, cy = 0.5 + s * sep, alto
        if estilo == "alegre":            # ojos cerrados de risa: arco grueso con rabillo
            L.arco(cx, cy - ry * 0.35, rx * 0.98, ry * 0.8, 15, 165, 0.022, pest)
            L.linea([(cx + s * rx * 0.95, cy - ry * 0.1), (cx + s * rx * 1.25, cy + ry * 0.1)], 0.01, pest,
                    grosor_fin=0.003)
        else:
            iris_c = (cx, cy - ry * 0.06)
            L.elipse(cx, cy, rx, ry * 0.97, (0.98, 0.97, 0.95))
            L.elipse(cx, cy + ry * 0.5, rx * 0.95, ry * 0.45, oscuro((0.98, 0.97, 0.95), 0.86), 0.5)   # sombra del párpado
            L.elipse(iris_c[0], iris_c[1], rx * 0.84, ry * 0.9, oscuro(P["iris_arriba"], 0.55))          # contorno
            L.degradado_elipse(iris_c[0], iris_c[1], rx * 0.76, ry * 0.82, P["iris_arriba"], P["iris_abajo"])
            L.arco(iris_c[0], iris_c[1] - ry * 0.1, rx * 0.55, ry * 0.5, 200, 340, 0.012,
                   tuple(min(1.0, c * 1.25 + 0.12) for c in P["iris_abajo"]), 0.6)                         # reflejo bajo
            L.elipse(iris_c[0], iris_c[1] + ry * 0.04, rx * 0.34, ry * 0.42, oscuro(P["iris_arriba"], 0.3))  # pupila
            L.elipse(cx - rx * 0.32, cy + ry * 0.34, rx * 0.26, ry * 0.22, (1, 1, 1))                     # brillos
            L.elipse(cx + rx * 0.28, cy - ry * 0.34, rx * 0.12, rx * 0.12, (1, 1, 1), 0.9)
            L.elipse(cx + rx * 0.05, cy + ry * 0.05, rx * 0.06, rx * 0.06, (1, 1, 1), 0.6)
            if estilo in ("cansada", "mayor"):
                L.rect(cx - rx * 1.3, cy + ry * 0.40, cx + rx * 1.3, cy + ry * 1.3, piel)
                L.arco(cx, cy + ry * 0.05, rx * 1.12, ry * 0.40, 8, 172, 0.02, pest)
            elif estilo == "seria":
                L.rect(cx - rx * 1.3, cy + ry * 0.62, cx + rx * 1.3, cy + ry * 1.3, piel)
                L.linea([(cx - rx * 1.12, cy + ry * 0.52), (cx + rx * 1.12, cy + ry * 0.64)], 0.022, pest)
            else:
                L.arco(cx, cy - ry * 0.08, rx * 1.12, ry * 1.04, 10, 170, 0.024, pest, grosor_fin=0.012)
                L.arco(cx, cy + ry * 0.05, rx * 1.05, ry * 1.18, 40, 140, 0.0045, oscuro(piel, 0.8), 0.7)   # pliegue
            fx = cx + s * rx * 1.06                                                    # rabillo y pestaña de abajo
            L.linea([(fx, cy + ry * 0.25), (fx + s * 0.022, cy + ry * 0.58)], 0.014, pest, grosor_fin=0.003)
            L.arco(cx, cy + ry * 0.1, rx * 0.98, ry * 1.06, 235 if s > 0 else 275, 265 if s > 0 else 305, 0.006, pest,
                   0.8)
        cej = P["cejas"]                     # cejas con forma (gruesas al centro, finas hacia fuera)
        if estilo == "seria":
            L.linea([(cx - s * 0.065, alto + ry + 0.03), (cx + s * 0.075, alto + ry + 0.065)], 0.02, cej,
                    grosor_fin=0.008)
        elif estilo == "mayor":
            L.arco(cx, alto + ry + 0.03, 0.08, 0.03, 20, 160, 0.024, cej)
        else:
            L.arco(cx, alto + ry + 0.035, 0.075, 0.038, 25, 155, 0.015, cej, grosor_fin=0.008)
        if P.get("gafas"):
            L.arco(cx, cy, rx * 1.45, ry * 1.25, 0, 360, 0.011, (0.45, 0.33, 0.16), n=48)
            L.arco(cx, cy, rx * 1.38, ry * 1.18, 120, 160, 0.006, (1, 1, 1), 0.5)
    if P.get("gafas"):
        L.linea([(0.5 - sep + rx * 1.45, alto + 0.01), (0.5 + sep - rx * 1.45, alto + 0.01)], 0.010, (0.45, 0.33, 0.16))
    boca = P.get("boca", "sonrisa")
    labios = P["labios"]
    interior = (0.50, 0.14, 0.16)
    if boca == "sonrisa":
        L.arco(0.5, 0.292, 0.048, 0.032, 200, 340, 0.011, labios)
        L.linea([(0.448, 0.284), (0.443, 0.292)], 0.006, labios, 0.7)
        L.linea([(0.552, 0.284), (0.557, 0.292)], 0.006, labios, 0.7)
    elif boca == "media_sonrisa":
        L.linea([(0.455, 0.268), (0.50, 0.262), (0.535, 0.272), (0.552, 0.288)], 0.01, labios)
    elif boca == "plana":
        L.linea([(0.46, 0.272), (0.54, 0.268)], 0.01, labios)
        L.linea([(0.48, 0.255), (0.52, 0.255)], 0.005, oscuro(piel, 0.85), 0.6)
    elif boca in ("risa", "abierta"):
        g = boca == "risa"
        L.elipse(0.5, 0.272, 0.052 if g else 0.034, 0.042 if g else 0.032, interior)
        L.rect(0.43, 0.272, 0.57, 0.34, piel)
        L.elipse(0.5, 0.243, 0.026 if g else 0.018, 0.013, (0.90, 0.46, 0.46))                 # lengua
        L.rect(0.462 if g else 0.475, 0.262, 0.538 if g else 0.525, 0.272, (0.98, 0.97, 0.94))  # dientes
    elif boca == "o":
        L.elipse(0.5, 0.268, 0.02, 0.025, interior)
        L.elipse(0.5, 0.258, 0.012, 0.008, (0.90, 0.46, 0.46))
    return L


def dibujar_cara_v1(A, F, P):
    """La cara de una persona sobre la loseta «cara» (ojos grandes de anime, rubor, boca; gafas, pecas, arrugas)."""
    L = C.Lienzo(A, "cara")
    L.fondo(P["piel"])
    sep, alto, rx, ry = F.ojo
    estilo = P.get("ojos", "normal")
    for s in (-1, 1):
        L.elipse(0.5 + s * 0.2, 0.33, 0.06, 0.032, P["rubor"], 0.32 if not P.get("arrugas") else 0.18)
    L.elipse(0.5, 0.362, 0.010, 0.007, oscuro(P["piel"], 0.8), 0.8)
    if P.get("pecas"):
        for (x, y) in ((0.30, 0.37), (0.33, 0.35), (0.28, 0.345), (0.70, 0.37), (0.67, 0.35), (0.72, 0.345)):
            L.elipse(x, y, 0.006, 0.005, oscuro(P["piel"], 0.7), 0.7)
    if P.get("arrugas"):
        for s in (-1, 1):
            L.arco(0.5 + s * 0.12, 0.30, 0.06, 0.05, 200 if s < 0 else 280, 260 if s < 0 else 340, 0.005,
                   oscuro(P["piel"], 0.78), 0.8)
            L.linea([(0.5 + s * (sep + rx * 1.05), alto - 0.01), (0.5 + s * (sep + rx * 1.35), alto - 0.035)], 0.004,
                    oscuro(P["piel"], 0.78), 0.8)
    for s in (-1, 1):
        cx, cy = 0.5 + s * sep, alto
        if estilo == "alegre":            # ojos cerrados en arco, de risa
            L.arco(cx, cy - ry * 0.35, rx * 0.95, ry * 0.75, 20, 160, 0.02, P["pestanas"])
        else:
            L.elipse(cx, cy, rx, ry * 0.96, (0.97, 0.96, 0.93))
            L.degradado_elipse(cx, cy - 0.006, rx * 0.80, ry * 0.86, P["iris_arriba"], P["iris_abajo"])
            L.elipse(cx, cy - 0.002, rx * 0.36, ry * 0.46, oscuro(P["iris_arriba"], 0.35))
            L.elipse(cx - rx * 0.30, cy + ry * 0.30, rx * 0.24, ry * 0.21, (1, 1, 1))
            L.elipse(cx + rx * 0.25, cy - ry * 0.32, rx * 0.11, rx * 0.11, (1, 1, 1), 0.85)
            if estilo in ("cansada", "mayor"):
                L.rect(cx - rx * 1.3, cy + ry * 0.40, cx + rx * 1.3, cy + ry * 1.3, P["piel"])
                L.arco(cx, cy + ry * 0.05, rx * 1.12, ry * 0.40, 8, 172, 0.016, P["pestanas"])
            elif estilo == "seria":
                L.rect(cx - rx * 1.3, cy + ry * 0.62, cx + rx * 1.3, cy + ry * 1.3, P["piel"])
                L.linea([(cx - rx * 1.1, cy + ry * 0.55), (cx + rx * 1.1, cy + ry * 0.62)], 0.018, P["pestanas"])
            else:
                L.arco(cx, cy - ry * 0.08, rx * 1.10, ry * 1.02, 12, 168, 0.019, P["pestanas"])
            fx = cx + s * rx * 1.06
            L.linea([(fx, cy + ry * 0.25), (fx + s * 0.018, cy + ry * 0.55)], 0.012, P["pestanas"], grosor_fin=0.003)
        # cejas
        cej = P["cejas"]
        if estilo == "seria":
            L.linea([(cx - s * 0.06, alto + ry + 0.035), (cx + s * 0.07, alto + ry + 0.06)], 0.016, cej)
        elif estilo == "mayor":
            L.arco(cx, alto + ry + 0.03, 0.075, 0.03, 20, 160, 0.02, cej)
        else:
            L.arco(cx, alto + ry + 0.035, 0.07, 0.035, 25, 155, 0.011, cej)
        if P.get("gafas"):
            L.arco(cx, cy, rx * 1.45, ry * 1.25, 0, 360, 0.010, (0.45, 0.33, 0.16), n=40)
    if P.get("gafas"):
        L.linea([(0.5 - sep + rx * 1.45, alto + 0.01), (0.5 + sep - rx * 1.45, alto + 0.01)], 0.010, (0.45, 0.33, 0.16))
    boca = P.get("boca", "sonrisa")
    labios = P["labios"]
    if boca == "sonrisa":
        L.arco(0.5, 0.29, 0.045, 0.03, 200, 340, 0.010, labios)
    elif boca == "media_sonrisa":
        L.linea([(0.455, 0.268), (0.50, 0.262), (0.535, 0.272), (0.548, 0.286)], 0.009, labios)
    elif boca == "plana":
        L.linea([(0.46, 0.272), (0.54, 0.268)], 0.009, labios)
    elif boca in ("risa", "abierta"):
        L.elipse(0.5, 0.272, 0.05 if boca == "risa" else 0.032, 0.04 if boca == "risa" else 0.03, (0.45, 0.12, 0.12))
        L.rect(0.43, 0.272, 0.57, 0.34, P["piel"])
        L.elipse(0.5, 0.245, 0.024, 0.012, (0.86, 0.42, 0.42))
    elif boca == "o":
        L.elipse(0.5, 0.268, 0.018, 0.022, (0.45, 0.12, 0.12))
    return L


def dibujar_parpado(A, nombre, piel, pestanas):
    A.muestra(nombre, piel, plano=True)
    x0, y0, c = A.muestras[nombre]
    px, py, pc = int(x0 * A.tam), int(y0 * A.tam), int(c * A.tam)
    A.img[py:py + int(pc * 0.30), px:px + pc, :3] = pestanas


def dibujar_detalle(A, P):
    """La loseta «detalle»: el emblema de Oakhaven (el roble con el farol) para el tabardo de la guardia y un fondo de
    tela con la trama de la ropa para quien no lo lleve."""
    L = C.Lienzo(A, "detalle")
    L.fondo(P.get("tabardo", (0.22, 0.30, 0.52)), grano=0.03)
    oro = (0.86, 0.70, 0.32)
    L.rect(0.0, 0.0, 1.0, 0.05, oro)
    L.rect(0.0, 0.95, 1.0, 1.0, oro)
    L.linea([(0.5, 0.22), (0.5, 0.55)], 0.07, oro, grosor_fin=0.04)
    for (x, y, r) in ((0.5, 0.66, 0.16), (0.36, 0.6, 0.11), (0.64, 0.6, 0.11), (0.42, 0.74, 0.1), (0.58, 0.74, 0.1)):
        L.elipse(x, y, r, r * 0.85, oro)
    L.elipse(0.5, 0.36, 0.05, 0.06, (1.0, 0.92, 0.6))
    L.linea([(0.40, 0.22), (0.60, 0.22)], 0.03, oro)


# ================================================================== paletas (una por persona)

NOMBRES_MUESTRAS = ["piel_plana", "piel_cuerpo", "parpado", "pelo", "ropa", "ropa2", "acento", "tela", "cuero",
                    "cuero_osc", "botas", "suela", "metal", "madera", "sombrero", "extra", "cristal", "pantalon"]


def paleta(A, P):
    """Pone las muestras SIEMPRE en el mismo orden: así todos los atlas de un oficio comparten las UV."""
    piel = P["piel"]
    A.muestra("piel_plana", piel, plano=True)
    A.muestra("piel_cuerpo", piel, oscuro=0.9, claro=1.02, grano=0)
    dibujar_parpado(A, "parpado", piel, P["pestanas"])
    A.muestra("pelo", P["pelo"], oscuro=0.72, claro=1.15, grano=0.03)
    A.muestra("ropa", P["ropa"], oscuro=0.72)
    A.muestra("ropa2", P["ropa2"], oscuro=0.75)
    A.muestra("acento", P["acento"], oscuro=0.85, claro=1.05)
    A.muestra("tela", P.get("tela", (0.88, 0.84, 0.74)))
    A.muestra("cuero", P.get("cuero", (0.42, 0.27, 0.16)))
    A.muestra("cuero_osc", P.get("cuero_osc", (0.28, 0.18, 0.11)))
    A.muestra("botas", P.get("botas", (0.38, 0.25, 0.16)), oscuro=0.7)
    A.muestra("suela", (0.2, 0.15, 0.1))
    A.muestra("metal", P.get("metal", (0.66, 0.68, 0.72)), oscuro=0.6, claro=1.2)
    A.muestra("madera", P.get("madera", (0.55, 0.38, 0.22)), oscuro=0.75)
    A.muestra("sombrero", P.get("sombrero", (0.82, 0.66, 0.36)), oscuro=0.75, claro=1.08)
    A.muestra("extra", P.get("extra", (0.80, 0.24, 0.20)))
    A.muestra("cristal", P.get("cristal", (0.45, 0.85, 0.65)), oscuro=0.85, claro=1.25, grano=0)
    A.muestra("pantalon", P.get("pantalon", (0.42, 0.36, 0.30)), oscuro=0.7)
    assert list(A.muestras) == NOMBRES_MUESTRAS


def base_cara(**k):
    P = {"rubor": (0.95, 0.52, 0.48), "pestanas": (0.16, 0.08, 0.06), "labios": (0.55, 0.25, 0.22),
         "iris_arriba": (0.22, 0.32, 0.18), "iris_abajo": (0.55, 0.72, 0.38)}
    P.update(k)
    P.setdefault("cejas", oscuro(P["pelo"], 0.8))
    return P


PIELES = {"clara": (0.96, 0.80, 0.68), "media": (0.88, 0.66, 0.52), "morena": (0.70, 0.48, 0.34),
          "oscura": (0.48, 0.32, 0.22)}
OJOS = {"verde": ((0.20, 0.32, 0.16), (0.55, 0.75, 0.38)), "azul": ((0.16, 0.26, 0.48), (0.45, 0.70, 0.92)),
        "ambar": ((0.30, 0.20, 0.10), (0.85, 0.62, 0.26)), "pardo": ((0.20, 0.12, 0.08), (0.55, 0.36, 0.20)),
        "gris": ((0.25, 0.28, 0.32), (0.62, 0.68, 0.74)), "violeta": ((0.26, 0.16, 0.38), (0.62, 0.48, 0.82))}


def ojos(nombre):
    a, b = OJOS[nombre]
    return {"iris_arriba": a, "iris_abajo": b}


# ================================================================== el cuerpo común

def pesos_brazo(F, l, s):
    a, b = esp(F.hombro, l), esp(F.mano_f, l)
    te = (esp(F.codo, l) - a).length / (b - a).length
    tm = (esp(F.muneca, l) - a).length / (b - a).length
    return por_eje(a, b, [(-0.06, "pecho"), (0.06, "hombro." + s), (0.14, "brazo." + s), (te - 0.07, "brazo." + s),
                            (te + 0.07, "antebrazo." + s), (tm - 0.04, "antebrazo." + s), (tm + 0.03, "mano." + s)])


def pesos_pierna(F, s):
    return F.cadena([(0.03, "pie." + s), (0.10, "pierna." + s), (0.25, "pierna." + s), (0.31, "muslo." + s),
                     (0.50, "muslo." + s), (0.60, "cadera")])


def tronco_pesos(F):
    return F.cadena([(0.6, "cadera"), (0.68, "columna"), (0.76, "columna"), (0.82, "pecho")])


def cuerpo(M, F, D):
    """Piernas, botas, brazos, manos, cadera, tronco, cuello, cabeza con la cara, orejas y párpados. D: opciones del
    oficio (manga: «larga» o «corta»; botas: «altas» o «zapato»)."""
    for s, l in (("L", 1), ("R", -1)):
        rod = esp(F.rodilla, l)
        M.pintar(M.tubo([esp(F.cadera_l, l) + Vector((0, 0, 0.03)), (esp(F.cadera_l, l) + rod) * 0.5, rod,
                         esp(F.tobillo, l)], [0.074 * F.sx, 0.066 * F.sx, 0.054 * F.sx, 0.046 * F.sx], 10), "pantalon",
                 pesos=pesos_pierna(F, s))
        alta = D.get("botas", "altas") == "altas"
        tob = esp(F.tobillo, l)
        tope = rod + Vector((0, 0, -0.08 * F.sb)) if alta else tob + Vector((0, 0, 0.05))
        # V2: caña de la bota que se ensancha arriba, con su vuelta de cuero
        M.pintar(M.tubo([tob + Vector((0, 0, -0.06 * F.sb)), tob + Vector((0, 0, 0.04)), (tob + tope) * 0.5 + Vector((0, 0, 0.02)),
                         tope], [0.057 * F.sx, 0.055 * F.sx, 0.058 * F.sx, 0.062 * F.sx], 12), "botas",
                 pesos=pesos_pierna(F, s))
        M.pintar(M.tubo([tope + Vector((0, 0, -0.035)), tope + Vector((0, 0, 0.004))], [0.069 * F.sx, 0.068 * F.sx], 12),
                 "cuero_osc", pesos=pesos_pierna(F, s))
        # V2: pie redondo (puntera abombada, empeine, talón) sobre una suela con canto
        pie_c = esp(Vector((F.tobillo.x, -0.05 * F.sx, 0.044 * F.sb)), l)
        M.pintar(M.esfera(pie_c, (0.06 * F.sx, 0.108 * F.sx, 0.052 * F.sb), (14, 9)), "botas",
                 pesos=lambda co, s=s: {"pie." + s: 1.0} if co.y < -0.02 else {"pie." + s: 0.6, "pierna." + s: 0.4},
                 deform=lambda co, c=pie_c: Vector((co.x, co.y, max(co.z - 0.012 * max(0.0, -(co.y - c.y)) / 0.1, 0.006)))
                 if co.y < c.y else Vector((co.x, co.y, max(co.z, 0.006))))
        M.pintar(M.tubo([pie_c + Vector((0, 0, -0.044 * F.sb)), pie_c + Vector((0, 0, -0.028 * F.sb))],
                        [(0.064 * F.sx, 0.112 * F.sx), (0.062 * F.sx, 0.11 * F.sx)], 16, ref=Vector((1, 0, 0))), "suela",
                 pesos="pie." + s)
        a, e, w, f = esp(F.hombro, l), esp(F.codo, l), esp(F.muneca, l), esp(F.mano_f, l)
        M.pintar(M.tubo([a + Vector((-0.03 * l, 0, 0)), a, (a + e) * 0.5, e, w],
                        [0.04 * F.sx, 0.042 * F.sx, 0.04 * F.sx, 0.036 * F.sx, 0.03 * F.sx], 10), "piel_cuerpo",
                 pesos=pesos_brazo(F, l, s))
        # V2: mano de manopla redonda (palma, dedos juntos con un surco y pulgar), no un tubo aplastado
        eje = (f - w).normalized()
        palma = w + (f - w) * 0.45
        giro_m = eje.to_track_quat('Z', 'Y').to_euler()
        M.pintar(M.esfera(palma, (0.024 * F.sx, 0.034 * F.sx, 0.044 * F.sx), (12, 8), giro=giro_m), "piel_cuerpo",
                 pesos="mano." + s)
        M.pintar(M.esfera(f + eje * 0.004 + Vector((0, -0.002, 0)), (0.021 * F.sx, 0.031 * F.sx, 0.028 * F.sx), (10, 7),
                          giro=giro_m), "piel_cuerpo", pesos="mano." + s)
        M.pintar(M.tubo([w + (f - w) * 0.3 + Vector((-0.012 * l, -0.026, 0)), w + (f - w) * 0.62 + Vector((-0.022 * l, -0.036, 0)),
                         w + (f - w) * 0.86 + Vector((-0.02 * l, -0.03, 0))], [0.012 * F.sx, 0.011 * F.sx, 0.008 * F.sx], 7),
                 "piel_cuerpo", pesos="mano." + s)
        # mangas
        manga = D.get("manga", "larga")
        color = D.get("color_manga", "tela")
        hasta = w + (e - w) * 0.25 if manga == "larga" else e + (a - e) * 0.15
        M.pintar(M.tubo([a + Vector((-0.04 * l, 0, 0.01)), a + Vector((0.01 * l, 0, 0.005)), (a + hasta) * 0.5, hasta],
                        [0.06 * F.sx, 0.062 * F.sx, 0.058 * F.sx, 0.057 * F.sx], 12), color, pesos=pesos_brazo(F, l, s))
        if manga == "larga" and D.get("puno"):
            M.pintar(M.tubo([w + (e - w) * 0.3, w + (e - w) * 0.12], [0.062 * F.sx, 0.06 * F.sx], 10), D["puno"],
                     pesos=pesos_brazo(F, l, s))
    # cadera y tronco (la camisa; la ropa del oficio va encima)
    M.pintar(M.esfera(F.t((0, 0, 0.58)), (0.15 * F.sx * F.st, 0.11 * F.sx * F.st, 0.10 * F.sb), (16, 8)), "pantalon",
             pesos=F.cadena([(0.5, "cadera"), (0.62, "cadera"), (0.70, "columna")]))
    M.pintar(M.tubo([F.t((0, 0, 0.56)), F.t((0, 0, 0.70)), F.t((0, 0, 0.84)), F.t((0, 0, 0.92)), F.t((0, 0.005, 0.95))],
                    [(0.14 * F.sx * F.st, 0.10 * F.sx * F.st), (0.13 * F.sx * F.st ** 1.3, 0.10 * F.sx * F.st ** 1.6),
                     (0.145 * F.sx * F.st, 0.10 * F.sx * F.st), (0.12 * F.sx * F.st, 0.09 * F.sx * F.st),
                     (0.06 * F.sx, 0.05 * F.sx)], 16),
             D.get("camisa", "tela"), pesos=tronco_pesos(F))
    M.pintar(M.tubo([Vector((0, 0.01, F.z(0.9))), Vector((0, 0.0, F.z(1.0) + 0.05 * F.sh))], [0.048 * F.sx, 0.044 * F.sx],
                    8), "piel_cuerpo", pesos=[(F.z(0.92), "pecho"), (F.z(0.95), "cuello"), (F.z(1.02), "cabeza")])

    def uv_cabeza(co, fc):
        rel = fc - F.cab_c
        if rel.y < -0.10 * F.sh and abs(rel.x) < 0.24 * F.sh and rel.z > -0.25 * F.sh:
            return M.atlas.uv_loseta("cara", *cara_uv(F, co))
        return M.atlas.uv_muestra("piel_plana", 0.5)
    M.pintar(M.esfera(F.cab_c, F.cab_r, (28, 18)), uvf=uv_cabeza, pesos="cabeza", deform=deform_cabeza(F))
    if D.get("orejas", True):
        for l in (1, -1):
            M.pintar(M.esfera(F.h((0.245 * l, 0.02, 1.20)), (0.03 * F.sh, 0.045 * F.sh, 0.06 * F.sh), (8, 6)),
                     "piel_plana", pesos="cabeza")
    sep, alto, rx, ry = F.ojo
    for s, l in (("L", 1), ("R", -1)):
        cu = 0.5 + sep * l

        def fuera(co, cu=cu):
            u, v = cara_uv(F, co)
            return co.y > 0 or ((u - cu) / (rx * 1.35)) ** 2 + ((v - alto) / (ry * 1.25)) ** 2 > 1.0
        M.pintar(M.esfera(F.cab_c, [r * 1.012 for r in F.cab_r], (40, 28)), "parpado", pesos="parpado." + s,
                 deform=deform_cabeza(F), quitar=fuera)


def giro_alrededor(co, centro, euler):
    return Vector(centro) + euler.to_matrix() @ (Vector(co) - Vector(centro))


# ================================================================== piezas de ropa, pelo, sombreros y objetos

def pliegues(F, n=7, amp=0.07, z_ini=0.56, z_fin=0.2, fase=0.0):
    """V2: pliegues verticales de una tela que cuelga: el radio ondula (n ondas) cada vez más hacia el bajo."""
    def f(co):
        t = min(max((F.z(z_ini) - co.z) / max(F.z(z_ini) - F.z(z_fin), 1e-4), 0.0), 1.0)
        if t <= 0.0:
            return co
        k = 1.0 + amp * t * math.sin(n * math.atan2(co.y, co.x) + fase)
        return Vector((co.x * k, co.y * k, co.z + 0.006 * t * math.cos(n * math.atan2(co.y, co.x) + fase)))
    return f


def ribete_anillo(M, F, centro_z, ra, rb, color, pesos, deform=None, y=0.0, lados=24):
    """V2: el borde de una tela (bajo, cuello, puño): un canto que da forma a la silueta."""
    M.pintar(M.tubo([Vector((0, y, centro_z - 0.012)), Vector((0, y, centro_z + 0.012))], [(ra, rb), (ra * 0.995, rb * 0.995)],
                    lados, tapas=(False, False)), color, pesos=pesos, deform=deform)


def tunica(M, F, color, hasta=0.30, vuelo=1.0, abierta=False, cinturon="cuero", ribete="acento"):
    pts = [F.t((0, 0.005, 0.95)), F.t((0, 0, 0.90)), F.t((0, 0, 0.80)), F.t((0, 0, 0.66)), F.t((0, 0, 0.56))]
    rad = [(0.075, 0.06), (0.135, 0.10), (0.155, 0.112), (0.138, 0.102), (0.17, 0.125)]
    if hasta < 0.5:
        pts += [F.t((0, 0.01, 0.42)), F.t((0, 0.015, hasta))]
        rad += [(0.19 * vuelo, 0.145 * vuelo), (0.215 * vuelo, 0.165 * vuelo)]
    else:
        pts += [F.t((0, 0.01, hasta))]
        rad += [(0.18, 0.135)]
    k = F.sx * F.st
    rad = [(a * k * (F.st ** 0.3 if 0 < i < 4 else 1), b * k * (F.st ** 0.6 if 0 < i < 4 else 1)) for i, (a, b) in
           enumerate(rad)]
    pz = F.cadena([(0.30, "cadera"), (0.56, "cadera"), (0.66, "columna"), (0.76, "columna"), (0.84, "pecho"),
                   (0.93, "pecho"), (0.96, "cuello")])
    dobla = pliegues(F, 7, 0.07 * vuelo, 0.56, hasta) if hasta < 0.5 else None
    if ribete and hasta < 0.5:
        ribete_anillo(M, F, F.z(hasta) + 0.012, rad[-1][0] * 1.02, rad[-1][1] * 1.02, ribete, pz, dobla, y=0.015 * F.sx * F.st)
    M.pintar(M.tubo(pts, rad, 22, tapas=(False, False)), color, pesos=pz, deform=dobla,
             quitar=(lambda co: co.z < F.z(0.45) and co.y < -0.10 * k and abs(co.x) < 0.035 * k) if abierta else None)
    if cinturon:
        M.pintar(M.tubo([F.t((0, 0, 0.635)), F.t((0, 0, 0.675))], [(0.149 * k * F.st ** 0.3, 0.11 * k * F.st ** 0.6)] * 2,
                        14), cinturon, pesos=F.cadena([(0.62, "cadera"), (0.68, "columna")]))
        M.pintar(M.caja(F.t((0.0, -0.11 * F.st ** 0.6, 0.655)), (0.045, 0.02, 0.04)), "metal", pesos="columna", liso=False)


def falda(M, F, color, hasta=0.24, vuelo=1.0):
    k = F.sx * F.st
    M.pintar(M.tubo([F.t((0, 0, 0.66)), F.t((0, 0.005, 0.56)), F.t((0, 0.01, 0.40)), F.t((0, 0.015, hasta))],
                    [(0.15 * k, 0.11 * k), (0.18 * k, 0.135 * k), (0.215 * k * vuelo, 0.17 * k * vuelo),
                     (0.25 * k * vuelo, 0.2 * k * vuelo)], 21, tapas=(False, False)), color,
             pesos=F.cadena([(0.30, "cadera"), (0.56, "cadera"), (0.66, "columna")]), deform=pliegues(F, 7, 0.09, 0.56, hasta))
    ribete_anillo(M, F, F.z(hasta) + 0.012, 0.25 * k * vuelo * 1.02, 0.2 * k * vuelo * 1.02, "acento",
                  F.cadena([(0.30, "cadera"), (0.56, "cadera")]), pliegues(F, 7, 0.09, 0.56, hasta), y=0.015 * k, lados=21)


def delantal(M, F, color, desde=0.84, hasta=0.36, ancho=0.22, ribete="cuero_osc"):
    k = F.sx * F.st
    pts = sorted({z for z in (desde, (desde + 0.66) / 2, 0.66, 0.56, (0.56 + hasta) / 2, hasta) if hasta <= z <= desde},
                 reverse=True)
    caras = []
    for z in pts:
        y = -(0.115 * F.st ** 0.6 if z > 0.6 else 0.13 + (0.56 - z) * 0.18) * k - 0.012
        caras.append((z, y))
    vs = []
    filas = []
    for z, y in caras:
        fila = []
        hondo = min(max((0.6 - z) / 0.3, 0.0), 1.0)          # V2: pliegues que se abren hacia el bajo
        for i in range(9):
            x = (i / 8 - 0.5) * ancho * k * (1.0 if z < 0.7 else 0.8) * (1.0 + 0.08 * hondo)
            curva = (abs(i / 8 - 0.5) * 2) ** 2 * 0.03 * k - 0.01 * hondo * math.sin(i * math.pi / 2.0)
            fila.append(M.bm.verts.new((x, y + curva, F.z(z))))
        filas.append(fila)
    for a, b in zip(filas, filas[1:]):
        for i in range(8):
            M.bm.faces.new((a[i], b[i], b[i + 1], a[i + 1]))
    vs = [v for f in filas for v in f] + doble(M, filas)          # doble cara (se ve por detrás al andar)
    pd = F.cadena([(0.40, "cadera"), (0.6, "cadera"), (0.70, "columna"), (0.82, "pecho")])
    M.pintar(vs, color, pesos=pd, liso=True)
    if ribete:                                                     # V2: el dobladillo del bajo
        bajo = [v.co.copy() + Vector((0, -0.002, 0.008)) for v in filas[-1]]
        M.pintar(M.tubo(bajo, [(0.006, 0.011)] * len(bajo), 5, ref=Vector((0, 1, 0))), ribete, pesos=pd)
    # cinta al cuello y a la cintura
    k2 = F.sx * F.st
    M.pintar(M.tubo([F.t((0, 0, 0.635)), F.t((0, 0, 0.66))], [(0.152 * k2 * F.st ** 0.3, 0.113 * k2 * F.st ** 0.6)] * 2,
                    12), color, pesos="columna")


def doble(M, filas, al_reves=False):
    """La cara de atrás de un paño (vértices propios, normales hacia el otro lado)."""
    copia = [[M.bm.verts.new(v.co.copy()) for v in f] for f in filas]
    for a, b in zip(copia, copia[1:]):
        for i in range(len(a) - 1):
            M.bm.faces.new((a[i + 1], b[i + 1], b[i], a[i]) if not al_reves else (a[i], b[i], b[i + 1], a[i + 1]))
    return [v for f in copia for v in f]


def chaleco(M, F, color):
    k = F.sx * F.st
    M.pintar(M.tubo([F.t((0, 0, 0.60)), F.t((0, 0, 0.72)), F.t((0, 0, 0.84)), F.t((0, 0.005, 0.915))],
                    [(0.152 * k, 0.112 * k), (0.137 * k * F.st ** 0.3, 0.104 * k * F.st ** 0.6),
                     (0.157 * k, 0.112 * k), (0.13 * k, 0.10 * k)], 12, tapas=(False, False)), color,
             pesos=tronco_pesos(F), quitar=lambda co: co.y < -0.06 * k and abs(co.x) < 0.04 * k)


def tabardo(M, F, A):
    """El tabardo de la guardia con el emblema (loseta «detalle») por delante y por detrás."""
    k = F.sx * F.st
    for lado in (-1, 1):
        filas = []
        for z in (0.92, 0.80, 0.66, 0.50, 0.36):
            y = lado * ((0.112 if z > 0.6 else 0.13 + (0.56 - z) * 0.15) * k + 0.014)
            fila = []
            for i in range(4):
                x = (i / 3 - 0.5) * 0.22 * k
                fila.append(M.bm.verts.new((x, y, F.z(z))))
            filas.append(fila)
        caras = []
        for a, b in zip(filas, filas[1:]):
            for i in range(3):
                q = (a[i], b[i], b[i + 1], a[i + 1]) if lado < 0 else (a[i + 1], b[i + 1], b[i], a[i])
                caras.append(M.bm.faces.new(q))
        vs = [v for f in filas for v in f]
        z0, z1 = F.z(0.36), F.z(0.92)

        def uvf(co, fc, lado=lado):
            u = 0.5 + co.x / (0.24 * k) * (-lado)
            v = (co.z - z0) / (z1 - z0)
            return A.uv_loseta("detalle", min(max(u, 0.02), 0.98), min(max(v, 0.02), 0.98))
        M.pintar(vs, uvf=uvf, pesos=F.cadena([(0.40, "cadera"), (0.6, "cadera"), (0.70, "columna"), (0.82, "pecho")]),
                 liso=False)
    for l in (1, -1):        # hombreras
        M.pintar(M.esfera(esp(F.hombro, l) + Vector((0.0, 0, 0.025)), (0.075 * F.sx, 0.075 * F.sx, 0.05 * F.sb), (10, 6)),
                 "metal", pesos="hombro." + ("L" if l > 0 else "R"))


def capa(M, F, color, hasta=0.32):
    k = F.sx * F.st
    filas = []
    for z in (0.93, 0.80, 0.62, 0.45, hasta):
        r = (0.17 + (0.93 - z) * 0.14) * k
        fila = []
        hondo = min(max((0.8 - z) / 0.45, 0.0), 1.0)          # V2: pliegues de la capa, más hondos abajo
        for i in range(13):
            ang = math.radians(-100 + i * 200 / 12)
            rr = r * (1.0 + 0.07 * hondo * math.sin(i * math.pi / 2.0))
            fila.append(M.bm.verts.new((math.sin(ang) * rr, math.cos(ang) * rr * 0.85 + 0.02, F.z(z))))
        filas.append(fila)
    for a, b in zip(filas, filas[1:]):
        for i in range(12):
            M.bm.faces.new((a[i + 1], b[i + 1], b[i], a[i]))
    vs = [v for f in filas for v in f] + doble(M, filas, True)
    pcapa = F.cadena([(0.4, "cadera"), (0.6, "columna"), (0.80, "pecho"), (0.9, "pecho")])
    M.pintar(vs, color, pesos=pcapa, liso=True)
    bajo = [v.co.copy() + Vector((0, 0, 0.008)) for v in filas[-1]]                 # V2: el ribete del bajo
    M.pintar(M.tubo(bajo, [0.009] * len(bajo), 5), "cuero_osc", pesos=pcapa)
    anillo = [(0.12 * k * math.cos(a), 0.10 * k * math.sin(a) + 0.005, F.z(0.935) + 0.012 * math.sin(a))
              for a in [math.radians(d) for d in range(-90, 300, 30)]]
    M.pintar(M.tubo(anillo, [0.035] * len(anillo), 6), color, pesos=[(F.z(0.9), "pecho"), (F.z(0.97), "cuello")])


def panuelo_cuello(M, F, color):
    k = F.sx
    anillo = [(0.12 * k * math.cos(a), 0.10 * k * math.sin(a) + 0.005, F.z(0.93) + 0.012 * math.sin(a))
              for a in [math.radians(d) for d in range(-90, 300, 30)]]
    M.pintar(M.tubo(anillo, [0.04] * len(anillo), 6), color, pesos=[(F.z(0.9), "pecho"), (F.z(0.97), "cuello")])


def chal(M, F, color):
    k = F.sx * F.st
    anillo = [(0.15 * k * math.cos(a), 0.12 * k * math.sin(a) + 0.01, F.z(0.9) + 0.02 * math.sin(a))
              for a in [math.radians(d) for d in range(-90, 300, 30)]]
    M.pintar(M.tubo(anillo, [0.05] * len(anillo), 6), color, pesos=[(F.z(0.85), "pecho"), (F.z(0.97), "cuello")])
    M.pintar(M.cono(F.t((0, 0.12, 0.88)), F.t((0, 0.15, 0.62)), 0.12 * k, 4), color, pesos="pecho",
             deform=lambda co: Vector((co.x, max(co.y, 0.08), co.z)))


def mechones_volumen(M, F, estilo, hc, rr, color):
    """V2: el pelo por mechones con volumen y silueta: sobre el casquete, mechones anchos y planos que nacen en la
    cabeza, se separan de ella y caen hacia atrás y los lados afinándose en punta. Con sombrero, solo los de los lados y
    la nuca (los de arriba quedarían debajo o lo atravesarían)."""
    con_sombrero = _oficio_actual in SOMBRERO
    if estilo == "mono":
        return                                               # el moño recogido: sin mechones sueltos
    largo = {"largo": 0.30, "coleta": 0.16, "trenzas": 0.16, "mono": 0.12, "punta": 0.12}.get(estilo, 0.13) * F.sh
    abajo = Vector((0, 0, -1))
    # (azimut desde la nuca, elevación) en grados: 0 = nuca (+Y), ±90 = sienes; la cara (±180) queda para el flequillo
    sitios = [(az, el) for el in (50, 20) for az in range(-120, 121, 40 if el > 30 else 30)]
    for i, (az, el) in enumerate(sitios):
        if abs(az) > 125:
            continue                                         # delante: la cara y el flequillo
        if con_sombrero and el > 30:
            continue
        a, e = math.radians(az), math.radians(el)
        d = Vector((math.sin(a) * math.cos(e), math.cos(a) * math.cos(e), math.sin(e)))
        base = hc + Vector((d.x * rr[0], d.y * rr[1], d.z * rr[2])) * 0.96
        fuera = Vector((d.x, d.y, 0.0)).normalized()
        lg = largo * (0.75 + 0.5 * ((i * 37) % 10) / 10.0) * (1.0 if el < 50 else 0.7)
        p1 = base + d * 0.016 * F.sh                       # pegado a la cabeza: volumen, no púas
        p2 = p1 + fuera * 0.02 * F.sh + abajo * lg * 0.5
        p3 = p2 + fuera * 0.004 * F.sh + abajo * lg * 0.5 + Vector((math.sin(i * 1.7) * 0.01, 0, 0))
        tang = Vector((math.cos(a), -math.sin(a), 0.0))      # el ancho del mechón, tangente a la cabeza
        M.pintar(M.tubo([base, p1, p2, p3], [(0.07 * F.sh, 0.016 * F.sh), (0.075 * F.sh, 0.022 * F.sh),
                                             (0.055 * F.sh, 0.016 * F.sh), (0.008, 0.004)], 6, ref=tang),
                 color, pesos="cabeza")
    if estilo == "punta" and not con_sombrero:
        for k, (x, y) in enumerate(((-0.08, 0.02), (0.04, -0.02), (0.12, 0.06), (-0.02, 0.12))):
            b = hc + Vector((x * F.sh, y * F.sh, rr[2] * 0.92))
            M.pintar(M.tubo([b, b + Vector((x * 0.6, y * 0.6 + 0.02, 0.07)) * F.sh,
                             b + Vector((x * 1.4, y + 0.06, 0.1)) * F.sh],
                            [(0.04 * F.sh, 0.018 * F.sh), (0.03 * F.sh, 0.013 * F.sh), (0.004, 0.003)], 5,
                            ref=Vector((1, 0, 0))), color, pesos="cabeza")


def pelo(M, F, estilo, color="pelo"):
    if estilo == "calvo":
        # corona de pelo corto por los lados y detrás
        hc = F.cab_c
        M.pintar(M.esfera(hc + Vector((0, 0.01 * F.sh, -0.01 * F.sh)), [r * 1.035 for r in F.cab_r], (18, 12)), color,
                 pesos="cabeza", deform=deform_cabeza(F),
                 quitar=lambda co: (co - hc).y < -0.05 * F.sh or (co - hc).z > 0.06 * F.sh or (co - hc).z < -0.16 * F.sh)
        return
    hc = F.cab_c + Vector((0, 0.012 * F.sh, 0.02 * F.sh))
    rr = (0.282 * F.sh, 0.262 * F.sh, 0.262 * F.sh)

    def sin_frente(co):
        r = co - hc
        largo = estilo in ("largo", "trenzas", "coleta")
        return (r.y < -0.05 * F.sh and r.z < 0.13 * F.sh) or r.z < (-0.24 if largo else -0.18) * F.sh or \
            (r.y < 0.10 * F.sh and r.z < -0.02 * F.sh)
    M.pintar(M.esfera(hc, rr, (20, 12)), color, pesos="cabeza", deform=deform_cabeza(F), quitar=sin_frente)
    mechones_volumen(M, F, estilo, hc, rr, color)
    # flequillo de mechones (como Ismena), más o menos revuelto
    mechones = ((-0.17, 1.40, -0.21, -0.22, 1.19, 0.05), (-0.09, 1.43, -0.13, -0.25, 1.28, 0.055),
                (0.0, 1.44, 0.02, -0.255, 1.31, 0.055), (0.09, 1.43, 0.13, -0.25, 1.30, 0.05),
                (0.18, 1.40, 0.24, -0.20, 1.22, 0.045))
    if estilo == "punta":
        mechones += ((-0.1, 1.48, -0.16, 0.0, 1.58, 0.05), (0.05, 1.49, 0.06, 0.05, 1.6, 0.05),
                     (0.15, 1.45, 0.24, 0.08, 1.52, 0.045), (-0.18, 1.44, -0.28, 0.1, 1.48, 0.045))
    for (bx, bz, tx, ty, tz, r) in mechones:
        base = F.h((bx, -0.13 if ty < 0 else 0.0, bz))
        punta = F.h((tx, ty, tz))
        # V2: mechones más gruesos y curvos (la v1 eran hojas planas y rectas), con una curva hacia fuera y la punta fina
        medio = base.lerp(punta, 0.45) + Vector((0, -0.034 * F.sh if ty < 0 else 0, 0.012))
        cuarto = base.lerp(punta, 0.78) + Vector((0, -0.02 * F.sh if ty < 0 else 0, 0.004))
        M.pintar(M.tubo([base, medio, cuarto, punta],
                        [(r * 1.2 * F.sh, r * 0.62 * F.sh), (r * 1.05 * F.sh, r * 0.55 * F.sh),
                         (r * 0.6 * F.sh, r * 0.34 * F.sh), (0.006, 0.004)], 7,
                        ref=Vector((1, 0, 0))), color, pesos="cabeza")
    for l in (1, -1):
        M.pintar(M.tubo([F.h((0.24 * l, -0.12, 1.36)), F.h((0.265 * l, -0.13, 1.20)), F.h((0.245 * l, -0.115, 1.10))],
                        [(0.05 * F.sh, 0.038 * F.sh), (0.044 * F.sh, 0.034 * F.sh), (0.012, 0.009)], 7), color,
                 pesos="cabeza")
    if estilo == "coleta":
        pts = [F.h((0, 0.24, 1.32)), F.h((0, 0.30, 1.22)), F.h((0, 0.31, 1.08)), F.h((0, 0.27, 0.98))]
        M.pintar(M.tubo(pts, [0.06 * F.sh, 0.065 * F.sh, 0.05 * F.sh, 0.012], 7), color,
                 pesos=lambda co: {"cabeza": 1.0})
        M.pintar(M.esfera(F.h((0, 0.255, 1.33)), (0.035 * F.sh, 0.03 * F.sh, 0.035 * F.sh), (7, 5)), "extra",
                 pesos="cabeza")
    elif estilo == "trenzas":
        for l in (1, -1):
            pts = [F.h((0.22 * l, 0.1, 1.14)), F.h((0.25 * l, 0.06, 1.02)), F.h((0.22 * l, -0.02, 0.9))]
            for i in range(len(pts) - 1):
                for kk in range(2):
                    p = pts[i].lerp(pts[i + 1], 0.25 + 0.5 * kk)
                    M.pintar(M.esfera(p, (0.04 * F.sh, 0.036 * F.sh, 0.05 * F.sh), (6, 5)), color, pesos="cabeza")
            M.pintar(M.esfera(pts[-1] + Vector((0, 0, -0.03)), (0.03, 0.03, 0.02), (7, 4)), "extra", pesos="cabeza")
    elif estilo == "mono":
        M.pintar(M.esfera(F.h((0, 0.17, 1.47)), (0.11 * F.sh, 0.10 * F.sh, 0.10 * F.sh), (10, 7)), color, pesos="cabeza")
    elif estilo == "largo":
        M.pintar(M.tubo([F.h((0, 0.18, 1.34)), F.h((0, 0.24, 1.12)), F.h((0, 0.22, 0.98))],
                        [(0.22 * F.sh, 0.08 * F.sh), (0.22 * F.sh, 0.07 * F.sh), (0.18 * F.sh, 0.04 * F.sh)], 8),
                 color, pesos="cabeza")


def barba(M, F, color="pelo", larga=False):
    hc = F.cab_c
    # barba de mentón: rodea la barbilla y sube por las mejillas solo por los lados (la boca queda a la vista)
    def fuera(co):
        r = co - hc
        if r.y > -0.02 * F.sh:
            return True
        if abs(r.x) < 0.12 * F.sh:
            return r.z > -0.135 * F.sh
        return r.z > -0.075 * F.sh or abs(r.x) > 0.21 * F.sh       # V2: menos mejilla (no parece una máscara)
    M.pintar(M.esfera(hc + Vector((0, -0.012 * F.sh, -0.075 * F.sh)), (0.255 * F.sh, 0.245 * F.sh, 0.2 * F.sh), (14, 9)),
             color, pesos="cabeza", deform=deform_cabeza(F), quitar=fuera)
    if larga:
        M.pintar(M.cono(F.h((0, -0.2, 1.06)), F.h((0, -0.22, 0.86)), 0.12 * F.sh, 7), color, pesos="cabeza")
    # bigote
    for l in (1, -1):
        M.pintar(M.tubo([F.h((0.01 * l, -0.25, 1.165)), F.h((0.07 * l, -0.24, 1.15)), F.h((0.11 * l, -0.21, 1.12))],
                        [(0.022 * F.sh, 0.012), (0.02 * F.sh, 0.012), (0.008, 0.006)], 5), color, pesos="cabeza")


def sombrero(M, F, tipo, color="sombrero"):
    sc = F.h((0, 0.02, 1.47))
    if tipo == "paja":
        giro = Euler((math.radians(-6), 0, 0))
        ala = M.tubo([sc + Vector((0, 0, -0.008)), sc + Vector((0, 0, 0.008))], [0.42 * F.sh, 0.42 * F.sh], 20)
        M.pintar(ala, color, pesos="cabeza", deform=lambda co: giro_alrededor(co, sc, giro))
        copa = M.tubo([sc, sc + Vector((0, 0, 0.09 * F.sh)), sc + Vector((0, 0, 0.13 * F.sh))],
                      [(0.21 * F.sh, 0.20 * F.sh), (0.19 * F.sh, 0.18 * F.sh), (0.12 * F.sh, 0.11 * F.sh)], 14)
        M.pintar(copa, color, pesos="cabeza", deform=lambda co: giro_alrededor(co, sc, giro))
        M.pintar(M.tubo([sc + Vector((0, 0, 0.012)), sc + Vector((0, 0, 0.04))], [(0.213 * F.sh, 0.203 * F.sh)] * 2, 14),
                 "extra", pesos="cabeza", deform=lambda co: giro_alrededor(co, sc, giro))
    elif tipo == "gorro":         # gorro blando caído a un lado
        c = F.h((0.02, 0.03, 1.43))
        M.pintar(M.esfera(c, (0.29 * F.sh, 0.27 * F.sh, 0.17 * F.sh), (16, 9)), color, pesos="cabeza",
                 quitar=lambda co: co.z < c.z - 0.02,
                 deform=lambda co: co + Vector((0.05 * F.sh * max(co.z - c.z, 0) / (0.17 * F.sh), 0, 0)))
        M.pintar(M.tubo([c + Vector((0, 0, -0.02)), c + Vector((0, 0, 0.02))], [(0.29 * F.sh, 0.27 * F.sh)] * 2, 16),
                 "acento", pesos="cabeza")
    elif tipo == "casco":         # casco de ala (de la guardia)
        c = F.h((0, 0.01, 1.36))
        M.pintar(M.esfera(c, (0.30 * F.sh, 0.29 * F.sh, 0.25 * F.sh), (16, 9)), "metal", pesos="cabeza",
                 quitar=lambda co: co.z < c.z - 0.01)
        M.pintar(M.tubo([c + Vector((0, 0, -0.01)), c + Vector((0, 0, 0.012))], [(0.40 * F.sh, 0.39 * F.sh)] * 2, 18),
                 "metal", pesos="cabeza", deform=lambda co: co + Vector((0, 0, -0.04 * max(math.hypot(co.x, co.y - c.y)
                                                                                         - 0.3 * F.sh, 0) / 0.1)))
        M.pintar(M.tubo([c + Vector((0, 0, 0.2 * F.sh)), c + Vector((0, 0, 0.27 * F.sh))], [0.03, 0.01], 6), "metal",
                 pesos="cabeza")
    elif tipo == "capucha":
        c = F.cab_c + Vector((0, 0.03 * F.sh, 0.03 * F.sh))
        M.pintar(M.esfera(c, (0.32 * F.sh, 0.31 * F.sh, 0.31 * F.sh), (16, 11)), color, pesos="cabeza",
                 deform=deform_cabeza(F),
                 quitar=lambda co: ((co - c).y < -0.12 * F.sh and (co - c).z < 0.16 * F.sh) or (co - c).z < -0.24 * F.sh)
        M.pintar(M.cono(c + Vector((0, 0.26 * F.sh, 0.1 * F.sh)), c + Vector((0, 0.42 * F.sh, -0.15 * F.sh)),
                        0.1 * F.sh, 6), color, pesos="cabeza")
    elif tipo == "panuelo":       # pañuelo atado a la cabeza
        bc = F.cab_c + Vector((0, 0.015 * F.sh, 0.06 * F.sh))
        M.pintar(M.esfera(bc, (0.292 * F.sh, 0.272 * F.sh, 0.262 * F.sh), (18, 10)), color, pesos="cabeza",
                 deform=deform_cabeza(F),
                 quitar=lambda co: (co - bc).z < 0.05 * F.sh + 0.07 * F.sh * max(0.0, -(co - bc).y) / (0.27 * F.sh))
        nudo = F.h((0.0, 0.27, 1.32))
        M.pintar(M.esfera(nudo, (0.045, 0.035, 0.04), (7, 5)), color, pesos="cabeza")
        for l in (1, -1):
            M.pintar(M.tubo([nudo, nudo + Vector((0.06 * l, 0.06, -0.08)), nudo + Vector((0.08 * l, 0.07, -0.17))],
                            [(0.04, 0.008), (0.035, 0.008), (0.02, 0.006)], 5), color, pesos="cabeza")


# --- objetos: se escriben en la pose de REPOSO del oficio y se llevan a la de descanso con la inversa del hueso -------

class EnPose:
    """Convierte puntos escritos «como se ven en el reposo del oficio» a la pose de descanso del esqueleto, para lo que
    va pegado a un hueso (una lanza vertical en la mano aunque el brazo esté doblado)."""

    def __init__(self, arm, pose):
        C.poner_pose(arm, pose)
        bpy.context.view_layer.update()
        self.d = {}
        for pb in arm.pose.bones:
            self.d[pb.name] = pb.matrix @ arm.data.bones[pb.name].matrix_local.inverted()
        self.arm = arm
        C.poner_pose(arm, {})
        bpy.context.view_layer.update()

    def punto(self, hueso, nombre_punto):
        """Dónde queda un punto del hueso en el reposo (p. ej. la mano)."""
        return self.d[hueso] @ arm_punto(self.arm, hueso, nombre_punto)

    def deform(self, hueso):
        inv = self.d[hueso].inverted()
        return lambda co: inv @ Vector(co)


def arm_punto(arm, hueso, cual):
    b = arm.data.bones[hueso]
    return b.head_local.copy() if cual == "cabeza" else b.tail_local.copy() if cual == "cola" else \
        b.head_local.lerp(b.tail_local, 0.5)


def agarre(E, lado="R"):
    """El centro de la mano cerrada en el reposo del oficio."""
    return E.punto("mano." + lado, "medio")


def palo(M, E, a, b, r, color, hueso, lados=6):
    M.pintar(M.tubo([a, b], [r, r], lados), color, pesos=hueso, deform=E.deform(hueso))


def martillo(M, E):
    g = agarre(E, "R")
    abajo = Vector((0, -0.25, -1)).normalized()
    a, b = g - abajo * 0.05, g + abajo * 0.30
    palo(M, E, a, b, 0.017, "madera", "mano.R")
    M.pintar(M.caja(b, (0.15, 0.075, 0.075)), "metal", pesos="mano.R", liso=False, deform=E.deform("mano.R"))


def lanza(M, E, F):
    g = agarre(E, "R")
    a, b = Vector((g.x, g.y, 0.02)), Vector((g.x, g.y, F.z(1.95)))
    palo(M, E, a, b, 0.016, "madera", "mano.R")
    M.pintar(M.cono(b, b + Vector((0, 0, 0.2)), 0.04, 4), "metal", pesos="mano.R", deform=E.deform("mano.R"))
    M.pintar(M.tubo([b + Vector((0, 0, -0.05)), b + Vector((0, 0, 0.0))], [0.024, 0.024], 6), "acento", pesos="mano.R",
             deform=E.deform("mano.R"))


def baston(M, E, curvo=True, alto=None):
    g = agarre(E, "R")
    pie = Vector((g.x - 0.02, g.y - 0.06, 0.01))
    tope = g + Vector((0, 0, 0.05 if alto is None else alto))
    palo(M, E, pie, tope, 0.015, "madera", "mano.R")
    if curvo:
        M.pintar(M.tubo([tope, tope + Vector((0, -0.03, 0.04)), tope + Vector((0, -0.08, 0.03)),
                         tope + Vector((0, -0.09, -0.02))], [0.015] * 4, 6), "madera", pesos="mano.R",
                 deform=E.deform("mano.R"))


def escoba(M, E):
    g = agarre(E, "R")
    eje = Vector((0.05, -0.3, -1)).normalized()
    a, b = g - eje * 0.45, g + eje * 0.42
    palo(M, E, a, b, 0.013, "madera", "mano.R")
    M.pintar(M.cono(b - eje * 0.02, b + eje * 0.2, 0.08, 7, r_punta=0.11), "sombrero", pesos="mano.R",
             deform=E.deform("mano.R"))
    M.pintar(M.tubo([b - eje * 0.03, b + eje * 0.02], [0.05, 0.05], 7), "cuero", pesos="mano.R",
             deform=E.deform("mano.R"))


def azada(M, E):
    g = agarre(E, "R")
    eje = Vector((0.0, -0.2, -1)).normalized()
    a, b = g - eje * 0.5, g + eje * 0.42
    palo(M, E, a, b, 0.013, "madera", "mano.R")
    M.pintar(M.caja(b + Vector((0, -0.06, 0.0)), (0.10, 0.12, 0.02), Euler((0.4, 0, 0))), "metal", pesos="mano.R",
             liso=False, deform=E.deform("mano.R"))


def cesta(M, E, lado="L", llena="extra"):
    b = E.punto("antebrazo." + lado, "medio") + Vector((0.03 if lado == "L" else -0.03, -0.02, -0.12))
    M.pintar(M.tubo([b + Vector((0, 0, -0.07)), b + Vector((0, 0, -0.03)), b + Vector((0, 0, 0.04))],
                    [0.07, 0.10, 0.11], 10, tapas=(True, False)), "sombrero", pesos="antebrazo." + lado,
             deform=E.deform("antebrazo." + lado))
    M.pintar(M.esfera(b + Vector((0, 0, 0.035)), (0.095, 0.095, 0.035), (8, 4)), llena, pesos="antebrazo." + lado,
             deform=E.deform("antebrazo." + lado))
    asa = [b + Vector((0.1 * math.cos(math.radians(a)), 0, 0.04 + 0.11 * math.sin(math.radians(a)))) for a in range(0, 181, 30)]
    M.pintar(M.tubo(asa, [0.008] * len(asa), 4), "madera", pesos="antebrazo." + lado, deform=E.deform("antebrazo." + lado))


def matraz(M, E):
    g = agarre(E, "R") + Vector((0, -0.03, 0.06))
    M.pintar(M.esfera(g, (0.05, 0.05, 0.05), (10, 7)), "cristal", pesos="mano.R", deform=E.deform("mano.R"))
    M.pintar(M.tubo([g + Vector((0, 0, 0.04)), g + Vector((0, 0, 0.1))], [0.016, 0.014], 6), "cristal", pesos="mano.R",
             deform=E.deform("mano.R"))
    M.pintar(M.tubo([g + Vector((0, 0, 0.1)), g + Vector((0, 0, 0.125))], [0.017, 0.017], 6), "corcho" if False else
             "madera", pesos="mano.R", deform=E.deform("mano.R"))


def espada_madera(M, E):
    g = agarre(E, "R")
    eje = Vector((0, -0.6, -1)).normalized()
    palo(M, E, g - eje * 0.04, g + eje * 0.05, 0.012, "cuero", "mano.R")
    M.pintar(M.caja(g + eje * 0.06, (0.09, 0.02, 0.02)), "madera", pesos="mano.R", liso=False, deform=E.deform("mano.R"))
    M.pintar(M.tubo([g + eje * 0.07, g + eje * 0.32], [(0.022, 0.006), (0.016, 0.005)], 4), "madera", pesos="mano.R",
             deform=E.deform("mano.R"))


def bolsa(M, F, x, color="cuero", hueso="cadera"):
    M.pintar(M.esfera(F.t((x, -0.06, 0.55)), (0.05, 0.04, 0.06), (8, 6)), color, pesos=hueso)
    M.pintar(M.tubo([F.t((x, -0.06, 0.6)), F.t((x, -0.06, 0.625))], [0.02, 0.015], 5), "acento", pesos=hueso)


def mochila(M, F):
    k = F.sx * F.st
    M.pintar(M.caja(F.t((0, 0.2, 0.74)), (0.26 * k, 0.12, 0.28 * F.sb)), "cuero", pesos="pecho", liso=False)
    M.pintar(M.caja(F.t((0, 0.27, 0.66)), (0.18 * k, 0.04, 0.10 * F.sb)), "cuero_osc", pesos="pecho", liso=False)
    M.pintar(M.tubo([F.t((-0.17, 0.2, 0.92)), F.t((0.17, 0.2, 0.92))], [0.06, 0.06], 8), "ropa2", pesos="pecho")
    for l in (1, -1):
        correa = [F.t((0.09 * l, 0.14, 0.86)), F.t((0.10 * l, -0.06, 0.92)), F.t((0.10 * l, -0.12, 0.78)),
                  F.t((0.11 * l, -0.12, 0.66))]
        M.pintar(M.tubo(correa, [(0.012, 0.022)] * len(correa), 4, ref=Vector((0, 1, 0))), "cuero_osc",
                 pesos=F.cadena([(0.62, "columna"), (0.8, "pecho")]))


def gafas_geo(M, F):
    """Montura fina por encima de la cara (las lentes van pintadas)."""
    sep, alto, rx, ry = F.ojo
    for l in (1, -1):
        c = ojo_mundo(F, l) + Vector((0, -0.012, 0))
        aro = [c + Vector((rx * 1.4 * 2 * F.cab_r[0] * math.cos(math.radians(a)) * 0.5, 0,
                           ry * 1.2 * 2 * F.cab_r[2] * math.sin(math.radians(a)) * 0.5)) for a in range(0, 361, 45)]
        M.pintar(M.tubo(aro, [0.005] * len(aro), 4), "acento", pesos="cabeza")


# ================================================================== los oficios

# Cada oficio: su figura (proporciones y ojos), sus opciones del cuerpo, cómo se viste y qué lleva, su reposo, su tarea
# y sus personas (paletas). «agarra»: lado que lleva un objeto (el balanceo de ese brazo al andar es menor).
def P_(piel, pelo, ojos_, **k):
    return base_cara(piel=PIELES[piel], pelo=pelo, **ojos(ojos_), **k)


OFICIOS = {}


def oficio(nombre, **k):
    OFICIOS[nombre] = k


# --- herrero: ancho, barriga de fragua, delantal de cuero, calvo con barba, martillo ---------------------------------
def vestir_herrero(M, F, A, E, P):
    delantal(M, F, "cuero", desde=0.88, hasta=0.30, ancho=0.26)
    pelo(M, F, "calvo")
    barba(M, F)
    martillo(M, E)
    M.pintar(M.tubo([esp(F.muneca, 1) + (esp(F.codo, 1) - esp(F.muneca, 1)) * 0.25,
                     esp(F.muneca, 1) + (esp(F.codo, 1) - esp(F.muneca, 1)) * 0.05], [0.04 * F.sx, 0.038 * F.sx], 8),
             "cuero_osc", pesos=pesos_brazo(F, 1, "L"))


oficio("herrero", figura=Figura(sb=1.04, sx=1.18, st=1.22, sh=0.98, ojo=(0.17, 0.44, 0.085, 0.09)),
       cuerpo=dict(manga="corta", color_manga="tela", camisa="tela", botas="altas"),
       vestir=vestir_herrero, agarra="R",
       reposo={"cadera": (0, 2, 0), "pecho": (-3, 0, 0), "cabeza": (2, 0, 0),
               "brazo.L": (-6, -10, 0), "antebrazo.L": (-30, 0, 10), "brazo.R": (-4, 6, 0), "antebrazo.R": (-25, 0, 0),
               "muslo.L": (-3, -4, 4), "muslo.R": (2, 4, -4)},
       tarea="martillar",
       personas={"herrero_aprendiz": P_("media", (0.18, 0.12, 0.08), "pardo", ojos="seria", boca="plana",
                                        tela=(0.80, 0.74, 0.62), ropa=(0.5, 0.3, 0.2), ropa2=(0.40, 0.33, 0.26),
                                        acento=(0.75, 0.55, 0.25), pantalon=(0.30, 0.27, 0.25), cuero=(0.40, 0.25, 0.14)),
                 "ferro": P_("morena", (0.24, 0.17, 0.12), "ambar", ojos="seria", boca="plana", tela=(0.80, 0.74, 0.62),
                             ropa=(0.5, 0.3, 0.2), ropa2=(0.40, 0.33, 0.26), acento=(0.85, 0.65, 0.3),
                             pantalon=(0.28, 0.24, 0.22), cuero=(0.46, 0.30, 0.18)),
                 # 14/11 (PROPUESTA del cantero, ciudades/oakhaven_propuestas.gd): el aprendiz del cantero, con polvo de
                 # piedra en la ropa (grises y azul pizarra). Mismo cuerpo que el herrero: martillo y delantal.
                 "cantero_aprendiz": P_("clara", (0.36, 0.26, 0.17), "gris", ojos="normal", boca="media_sonrisa",
                                        tela=(0.78, 0.77, 0.74), ropa=(0.36, 0.42, 0.50), ropa2=(0.52, 0.51, 0.49),
                                        acento=(0.70, 0.66, 0.56), pantalon=(0.34, 0.33, 0.34),
                                        cuero=(0.42, 0.36, 0.30)),
                 # 16/11 (PROPUESTA, la cuadrilla de la Quilla de Sunken City 3D, zonas3d/sunken/quilla/obreros.gd): el
                 # calafate, con el delantal negro de brea, camisa de lona y pañuelo rojo.
                 "calafate": P_("morena", (0.34, 0.32, 0.30), "gris", ojos="seria", boca="media_sonrisa",
                                tela=(0.74, 0.70, 0.60), ropa=(0.22, 0.30, 0.40), ropa2=(0.30, 0.27, 0.24),
                                acento=(0.66, 0.20, 0.17), pantalon=(0.26, 0.28, 0.32), cuero=(0.16, 0.13, 0.11))})


# --- mercader: barriga, chaleco y delantal corto, gorro blando, bolsa de monedas ---------------------------------------
def vestir_mercader(M, F, A, E, P):
    chaleco(M, F, "ropa")
    delantal(M, F, "tela", desde=0.62, hasta=0.36, ancho=0.24, ribete="acento")
    pelo(M, F, "corto")
    sombrero(M, F, "gorro", "ropa2")
    bolsa(M, F, 0.14, "cuero")
    bolsa(M, F, -0.15, "acento")


oficio("mercader", figura=Figura(sb=0.98, sx=1.08, st=1.38, sh=1.0, ojo=(0.17, 0.44, 0.088, 0.1)),
       cuerpo=dict(manga="larga", color_manga="tela", camisa="tela", botas="zapato", puno="acento"),
       vestir=vestir_mercader, agarra="",
       reposo={"pecho": (-4, 0, 0), "cabeza": (-2, 0, 0), "brazo.L": (-14, -6, 0), "antebrazo.L": (-60, 0, -40),
               "brazo.R": (-14, 6, 0), "antebrazo.R": (-60, 0, 40), "muslo.L": (-2, -4, 6), "muslo.R": (0, 4, -6)},
       tarea="pregonar",
       personas={"mercader_manzanas": P_("clara", (0.55, 0.32, 0.16), "verde", ojos="alegre", boca="risa", pecas=True,
                                         ropa=(0.30, 0.46, 0.26), ropa2=(0.72, 0.22, 0.18), acento=(0.85, 0.66, 0.3),
                                         tela=(0.92, 0.88, 0.78), pantalon=(0.40, 0.32, 0.25))})


# --- alquimista: túnica larga, gafas, pelo largo recogido, matraz --------------------------------------------------------
def vestir_alquimista(M, F, A, E, P):
    tunica(M, F, "ropa", hasta=0.16, vuelo=1.05, cinturon="ropa2")
    pelo(M, F, "coleta")
    gafas_geo(M, F)
    matraz(M, E)
    bolsa(M, F, -0.15, "cuero")
    M.pintar(M.tubo([F.t((0.13, -0.08, 0.6)), F.t((0.13, -0.08, 0.66))], [0.022, 0.022], 6), "cristal", pesos="cadera")


oficio("alquimista", figura=Figura(sb=1.0, sx=0.95, st=0.95, sh=1.0, ojo=(0.17, 0.44, 0.092, 0.11)),
       cuerpo=dict(manga="larga", color_manga="ropa", camisa="ropa", botas="zapato", puno="acento"),
       vestir=vestir_alquimista, agarra="R",
       reposo={"cabeza": (6, 0, 4), "brazo.R": (-18, 4, 6), "antebrazo.R": (-85, 0, 12), "mano.R": (6, 0, 0),
               "brazo.L": (-4, -6, 0), "antebrazo.L": (-20, 0, 0), "muslo.L": (-3, -2, 4)},
       tarea="remover",
       personas={"alquimista_aprendiz": P_("clara", (0.30, 0.20, 0.36), "violeta", gafas=True, boca="sonrisa",
                                           ropa=(0.36, 0.30, 0.55), ropa2=(0.72, 0.62, 0.34), acento=(0.82, 0.72, 0.42),
                                           extra=(0.85, 0.75, 0.40), cristal=(0.40, 0.90, 0.70)),
                 "mirta": P_("media", (0.82, 0.80, 0.76), "verde", gafas=True, boca="media_sonrisa", arrugas=True,
                             ropa=(0.30, 0.46, 0.33), ropa2=(0.40, 0.28, 0.20), acento=(0.72, 0.62, 0.40),
                             extra=(0.60, 0.40, 0.70), cristal=(0.95, 0.55, 0.35)),
                 # 15/11 (PROPUESTA de Sunken City 3D, ciudades/sunken.gd): la contramaestre Ulla, archivera del Águila.
                 # Túnica azul de marino, latón en los ribetes y el «matraz» hace de tintero (tinta azul oscura).
                 "ulla": P_("clara", (0.46, 0.40, 0.36), "gris", gafas=True, ojos="seria", boca="plana",
                            ropa=(0.20, 0.28, 0.38), ropa2=(0.52, 0.40, 0.26), acento=(0.80, 0.66, 0.36),
                            extra=(0.62, 0.48, 0.30), cristal=(0.16, 0.20, 0.36))})


# --- guardia de Oakhaven: tabardo con el roble, casco de ala, lanza ----------------------------------------------------
def vestir_guardia(M, F, A, E, P):
    tunica(M, F, "ropa2", hasta=0.36, cinturon="cuero")
    tabardo(M, F, A)
    pelo(M, F, "corto")
    sombrero(M, F, "casco")
    lanza(M, E, F)


oficio("guardia", figura=Figura(sb=1.06, sx=1.08, st=1.05, sh=0.96, ojo=(0.17, 0.44, 0.088, 0.095)),
       cuerpo=dict(manga="larga", color_manga="ropa2", camisa="ropa2", botas="altas", puno="cuero"),
       vestir=vestir_guardia, agarra="R",
       reposo={"brazo.R": (-12, 4, 0), "antebrazo.R": (-48, 0, 0), "mano.R": (0, 0, 0),
               "brazo.L": (-2, -4, 0), "antebrazo.L": (-12, 0, 0), "pecho": (-2, 0, 0)},
       tarea="vigilar",
       personas={"guardia_puerta": P_("media", (0.22, 0.14, 0.09), "pardo", ojos="seria", boca="plana",
                                      ropa2=(0.42, 0.40, 0.44), ropa=(0.22, 0.30, 0.52), acento=(0.85, 0.70, 0.32),
                                      tabardo=(0.20, 0.28, 0.52), metal=(0.62, 0.65, 0.70)),
                 "guardia_ronda": P_("oscura", (0.10, 0.08, 0.07), "ambar", ojos="normal", boca="media_sonrisa",
                                     ropa2=(0.42, 0.40, 0.44), ropa=(0.22, 0.30, 0.52), acento=(0.85, 0.70, 0.32),
                                     tabardo=(0.20, 0.28, 0.52), metal=(0.62, 0.65, 0.70)),
                 "aldric": P_("clara", (0.72, 0.56, 0.30), "azul", ojos="normal", boca="media_sonrisa",
                              ropa2=(0.62, 0.64, 0.70), ropa=(0.70, 0.72, 0.78), acento=(0.85, 0.70, 0.32),
                              tabardo=(0.55, 0.14, 0.14), metal=(0.80, 0.82, 0.86))})


# --- campesino: sombrero de paja, camisa remangada, azada --------------------------------------------------------------
def vestir_campesino(M, F, A, E, P):
    chaleco(M, F, "ropa")
    pelo(M, F, "corto")
    sombrero(M, F, "paja")
    panuelo_cuello(M, F, "extra")
    azada(M, E)


oficio("campesino", figura=Figura(sb=1.0, sx=1.02, st=1.0, sh=1.0, ojo=(0.17, 0.44, 0.09, 0.105)),
       cuerpo=dict(manga="corta", color_manga="tela", camisa="tela", botas="altas"),
       vestir=vestir_campesino, agarra="R",
       reposo={"brazo.R": (-10, 4, 0), "antebrazo.R": (-40, 0, 0), "brazo.L": (-4, -4, 0), "antebrazo.L": (-14, 0, 0),
               "cadera": (0, -2, 3), "muslo.R": (-3, 3, -4)},
       tarea="cavar",
       personas={"campesino_huerto": P_("morena", (0.30, 0.20, 0.12), "pardo", ojos="normal", boca="sonrisa",
                                        ropa=(0.55, 0.42, 0.25), ropa2=(0.42, 0.36, 0.28), acento=(0.7, 0.55, 0.3),
                                        tela=(0.90, 0.86, 0.74), pantalon=(0.36, 0.38, 0.30), extra=(0.75, 0.25, 0.20)),
                 # 16/11 (PROPUESTA, la cuadrilla de la Quilla de Sunken City 3D): la carpintera de ribera; la azada
                 # del campesino se lee como su azuela. Chaleco de lona, pañuelo verde y sombrero de paja.
                 "carpintera": P_("clara", (0.52, 0.26, 0.12), "verde", ojos="normal", boca="media_sonrisa", pecas=True,
                                  ropa=(0.72, 0.66, 0.54), ropa2=(0.40, 0.34, 0.28), acento=(0.80, 0.62, 0.32),
                                  tela=(0.86, 0.82, 0.72), pantalon=(0.30, 0.34, 0.40), extra=(0.30, 0.52, 0.44))})


# --- campesina: falda, pañuelo en la cabeza, cesta al brazo ---------------------------------------------------------------
def vestir_campesina(M, F, A, E, P):
    falda(M, F, "ropa2", hasta=0.20)
    delantal(M, F, "tela", desde=0.62, hasta=0.30, ancho=0.22, ribete="acento")
    chaleco(M, F, "ropa")
    pelo(M, F, "trenzas")
    sombrero(M, F, "panuelo", "acento")
    cesta(M, E, "L")


oficio("campesina", figura=Figura(sb=0.97, sx=0.96, st=0.98, sh=1.02, ojo=(0.17, 0.44, 0.095, 0.118)),
       cuerpo=dict(manga="larga", color_manga="tela", camisa="tela", botas="zapato"),
       vestir=vestir_campesina, agarra="L",
       reposo={"brazo.L": (-8, -12, 0), "antebrazo.L": (-78, 0, 0), "mano.L": (0, 0, -10),
               "brazo.R": (-2, 6, 0), "antebrazo.R": (-16, 0, 0), "cabeza": (0, 4, -4), "cadera": (0, 2, -3)},
       tarea="recoger",
       personas={"vendedora_fruta": P_("clara", (0.62, 0.30, 0.14), "verde", ojos="normal", boca="sonrisa", pecas=True,
                                       ropa=(0.62, 0.22, 0.20), ropa2=(0.30, 0.38, 0.55), acento=(0.92, 0.80, 0.42),
                                       tela=(0.94, 0.92, 0.86), extra=(0.85, 0.25, 0.18)),
                 "rosa": P_("clara", (0.86, 0.66, 0.36), "azul", ojos="normal", boca="risa",
                            ropa=(0.86, 0.62, 0.70), ropa2=(0.45, 0.58, 0.36), acento=(0.98, 0.95, 0.88),
                            tela=(0.96, 0.94, 0.90), extra=(0.95, 0.55, 0.75))})


# --- anciano: encorvado, calvo con barba larga, bastón ----------------------------------------------------------------------
def vestir_anciano(M, F, A, E, P):
    tunica(M, F, "ropa", hasta=0.22, cinturon="cuero")
    pelo(M, F, "calvo")
    barba(M, F, larga=True)
    baston(M, E)


oficio("anciano", figura=Figura(sb=0.94, sx=0.98, st=1.05, sh=1.0, ojo=(0.17, 0.45, 0.075, 0.07)),
       cuerpo=dict(manga="larga", color_manga="ropa", camisa="ropa", botas="zapato", orejas=True),
       vestir=vestir_anciano, agarra="R",
       reposo={"columna": (8, 0, 0), "pecho": (10, 0, 0), "cuello": (-10, 0, 0), "cabeza": (-6, 0, 0),
               "brazo.R": (-24, 6, 0), "antebrazo.R": (-36, 0, 0), "brazo.L": (8, -4, 0), "antebrazo.L": (-55, 0, -30),
               "muslo.L": (-6, 0, 0), "muslo.R": (-6, 0, 0), "pierna.L": (10, 0, 0), "pierna.R": (10, 0, 0)},
       tarea="estirar",
       personas={"albar": P_("media", (0.85, 0.84, 0.82), "gris", ojos="mayor", boca="plana", arrugas=True,
                             ropa=(0.36, 0.34, 0.38), ropa2=(0.28, 0.26, 0.30), acento=(0.6, 0.55, 0.45)),
                 "abuelo_fuente": P_("morena", (0.92, 0.92, 0.90), "pardo", ojos="mayor", boca="sonrisa", arrugas=True,
                                     ropa=(0.52, 0.40, 0.30), ropa2=(0.36, 0.30, 0.24), acento=(0.75, 0.6, 0.4))})


# --- anciana: chal, moño, bolsa de grano para las palomas -----------------------------------------------------------------
def vestir_anciana(M, F, A, E, P):
    falda(M, F, "ropa2", hasta=0.12, vuelo=1.05)
    tunica(M, F, "ropa", hasta=0.5, cinturon=None)
    chal(M, F, "acento")
    pelo(M, F, "mono")
    M.pintar(M.esfera(agarre(E, "L") + Vector((0, -0.02, -0.04)), (0.05, 0.045, 0.06), (8, 6)), "tela",
             pesos="mano.L", deform=E.deform("mano.L"))


oficio("anciana", figura=Figura(sb=0.92, sx=0.97, st=1.08, sh=1.0, ojo=(0.17, 0.45, 0.078, 0.075)),
       cuerpo=dict(manga="larga", color_manga="ropa", camisa="ropa", botas="zapato"),
       vestir=vestir_anciana, agarra="L",
       reposo={"columna": (6, 0, 0), "pecho": (8, 0, 0), "cuello": (-8, 0, 0),
               "brazo.L": (-12, -4, 0), "antebrazo.L": (-70, 0, -25), "brazo.R": (-10, 4, 0), "antebrazo.R": (-65, 0, 30)},
       tarea="echar_grano",
       personas={"encina": P_("clara", (0.90, 0.90, 0.92), "verde", ojos="mayor", boca="sonrisa", arrugas=True,
                              ropa=(0.30, 0.40, 0.30), ropa2=(0.40, 0.30, 0.22), acento=(0.70, 0.55, 0.60)),
                 "abuela_palomas": P_("morena", (0.80, 0.78, 0.76), "pardo", ojos="mayor", boca="sonrisa",
                                      arrugas=True, ropa=(0.55, 0.30, 0.30), ropa2=(0.30, 0.28, 0.36),
                                      acento=(0.85, 0.80, 0.62))})


# --- niño: cabeza grande, gorra, espada de madera ----------------------------------------------------------------------------
def vestir_nino(M, F, A, E, P):
    tunica(M, F, "ropa", hasta=0.44, cinturon="cuero")
    pelo(M, F, "punta")
    panuelo_cuello(M, F, "extra")
    espada_madera(M, E)


oficio("nino", figura=Figura(sb=0.70, sx=0.80, st=0.92, sh=0.86, ojo=(0.17, 0.43, 0.1, 0.13)),
       cuerpo=dict(manga="corta", color_manga="ropa", camisa="ropa", botas="zapato"),
       vestir=vestir_nino, agarra="R", nino=True,
       reposo={"brazo.R": (-10, 6, 0), "antebrazo.R": (-35, 0, 0), "brazo.L": (-4, -10, 0), "antebrazo.L": (-15, 0, 0),
               "cabeza": (-4, 0, 0), "muslo.L": (-2, -5, 6), "muslo.R": (0, 5, -6)},
       tarea="jugar",
       personas={"bastian": P_("clara", (0.62, 0.40, 0.18), "azul", ojos="grande", boca="risa", pecas=True,
                               ropa=(0.30, 0.50, 0.70), ropa2=(0.40, 0.34, 0.28), acento=(0.9, 0.8, 0.4),
                               extra=(0.85, 0.30, 0.20), pantalon=(0.42, 0.36, 0.28)),
                 "nino_plaza": P_("oscura", (0.10, 0.08, 0.06), "ambar", ojos="grande", boca="abierta",
                                  ropa=(0.80, 0.55, 0.22), ropa2=(0.36, 0.30, 0.26), acento=(0.9, 0.85, 0.7),
                                  extra=(0.25, 0.55, 0.35), pantalon=(0.30, 0.34, 0.42))})


# --- niña: trenzas o coleta, vestido ------------------------------------------------------------------------------------------
def vestir_nina(M, F, A, E, P):
    falda(M, F, "ropa", hasta=0.28, vuelo=1.1)
    delantal(M, F, "tela", desde=0.84, hasta=0.36, ancho=0.2, ribete="acento")
    pelo(M, F, "coleta")


oficio("nina", figura=Figura(sb=0.68, sx=0.78, st=0.9, sh=0.86, ojo=(0.17, 0.43, 0.102, 0.135)),
       cuerpo=dict(manga="corta", color_manga="ropa", camisa="ropa", botas="zapato"),
       vestir=vestir_nina, agarra="", nino=True,
       reposo={"brazo.L": (-6, -12, 0), "antebrazo.L": (-20, 0, 0), "brazo.R": (-6, 12, 0), "antebrazo.R": (-20, 0, 0),
               "cabeza": (-2, 6, 0), "cadera": (0, 2, 0)},
       tarea="jugar",
       personas={"nina_plaza": P_("media", (0.30, 0.18, 0.10), "verde", ojos="grande", boca="risa",
                                  ropa=(0.82, 0.40, 0.48), ropa2=(0.4, 0.3, 0.2), acento=(0.95, 0.9, 0.7),
                                  extra=(0.95, 0.85, 0.30)),
                 "nina_lazo": P_("clara", (0.90, 0.78, 0.45), "azul", ojos="grande", boca="sonrisa", pecas=True,
                                 ropa=(0.40, 0.62, 0.78), ropa2=(0.4, 0.3, 0.2), acento=(0.98, 0.95, 0.88),
                                 extra=(0.85, 0.25, 0.35))})


# --- viajero: capa, capucha, mochila con manta, bastón de camino -----------------------------------------------------------
def vestir_viajero(M, F, A, E, P):
    tunica(M, F, "ropa2", hasta=0.36, cinturon="cuero")
    pelo(M, F, "corto")
    capa(M, F, "ropa", hasta=0.34)
    sombrero(M, F, "capucha", "ropa")
    mochila(M, F)
    baston(M, E, curvo=False, alto=0.42)


oficio("viajero", figura=Figura(sb=1.02, sx=1.0, st=1.0, sh=0.98, ojo=(0.17, 0.44, 0.09, 0.1)),
       cuerpo=dict(manga="larga", color_manga="ropa2", camisa="ropa2", botas="altas", puno="cuero"),
       vestir=vestir_viajero, agarra="R",
       reposo={"brazo.R": (-16, 6, 0), "antebrazo.R": (-46, 0, 0), "brazo.L": (-4, -6, 0), "antebrazo.L": (-40, 0, -20),
               "cabeza": (-4, 0, 0)},
       tarea="ajustar",
       personas={"viajero_camino": P_("morena", (0.20, 0.14, 0.10), "ambar", ojos="cansada", boca="media_sonrisa",
                                      ropa=(0.36, 0.42, 0.30), ropa2=(0.55, 0.45, 0.32), acento=(0.75, 0.6, 0.35),
                                      cuero=(0.45, 0.30, 0.18)),
                 # 15/11 (PROPUESTA de Sunken City 3D, ciudades/sunken.gd): la capitana Brea, de la Compañía del Águila.
                 # Capa y capucha carmesí (el color de la bandera del Águila), casaca azul de marino y ribetes de oro.
                 "brea": P_("morena", (0.70, 0.30, 0.12), "ambar", ojos="alegre", boca="risa", pecas=True,
                            ropa=(0.62, 0.17, 0.17), ropa2=(0.20, 0.26, 0.42), acento=(0.92, 0.74, 0.36),
                            cuero=(0.42, 0.28, 0.16)),
                 # 16/11 (PROPUESTA, la cuadrilla de la Quilla de Sunken City 3D): dos marineros de la Compañía; el
                 # bastón del viajero se lee como su bichero. Azul de marino y lona, sin el carmesí de la capitana.
                 "marinero_1": P_("media", (0.18, 0.13, 0.10), "pardo", ojos="normal", boca="sonrisa",
                                  ropa=(0.24, 0.32, 0.46), ropa2=(0.80, 0.76, 0.66), acento=(0.62, 0.52, 0.34),
                                  cuero=(0.36, 0.26, 0.16)),
                 "marinero_2": P_("morena", (0.10, 0.08, 0.07), "ambar", ojos="alegre", boca="risa",
                                  ropa=(0.70, 0.64, 0.50), ropa2=(0.26, 0.36, 0.42), acento=(0.30, 0.50, 0.46),
                                  cuero=(0.40, 0.28, 0.18))})


# --- barrendero: delantal largo, pañuelo, escoba --------------------------------------------------------------------------------
def vestir_barrendero(M, F, A, E, P):
    tunica(M, F, "ropa", hasta=0.36, cinturon=None)
    delantal(M, F, "ropa2", desde=0.86, hasta=0.30, ancho=0.24)
    pelo(M, F, "corto")
    sombrero(M, F, "gorro", "acento")
    escoba(M, E)


oficio("barrendero", figura=Figura(sb=0.98, sx=0.95, st=0.95, sh=1.0, ojo=(0.17, 0.44, 0.09, 0.105)),
       cuerpo=dict(manga="larga", color_manga="ropa", camisa="ropa", botas="zapato", puno="tela"),
       vestir=vestir_barrendero, agarra="R",
       reposo={"brazo.R": (-14, 4, 0), "antebrazo.R": (-50, 0, 0), "brazo.L": (-4, -4, 0), "antebrazo.L": (-14, 0, 0),
               "cadera": (0, 2, -2)},
       tarea="barrer",
       personas={"barrendera": P_("media", (0.40, 0.24, 0.14), "pardo", ojos="normal", boca="media_sonrisa",
                                  ropa=(0.50, 0.55, 0.62), ropa2=(0.62, 0.50, 0.34), acento=(0.80, 0.40, 0.30),
                                  sombrero=(0.75, 0.62, 0.35))})


# ================================================================== barrio experimental de Oakhaven (16/11, agente C)
# SOLO SE AÑADE: tres oficios nuevos SIN herramienta horneada (los objetos que llevan cambian de sitio y cuelgan de un
# BoneAttachment3D en Godot: zonas3d/barrio/utensilios.gd), con los clips de llevar y de su trabajo («barrio»: ver
# clips()), y tres personas nuevas de oficios que ya existen (solo su atlas: el GLB de esos oficios no se rehace; se
# saca con el 4.º argumento a otra carpeta y se copia solo el .png). PROPUESTA del barrio (ciudades/oakhaven_barrio.gd).

# --- panadera: falda, delantal enharinado, pañuelo en la cabeza, mangas cortas; manos libres --------------------------
def vestir_panadera(M, F, A, E, P):
    falda(M, F, "ropa2", hasta=0.22)
    delantal(M, F, "tela", desde=0.86, hasta=0.28, ancho=0.25, ribete="acento")
    pelo(M, F, "trenzas")
    sombrero(M, F, "panuelo", "acento")


oficio("panadera", figura=Figura(sb=0.98, sx=1.02, st=1.12, sh=1.0, ojo=(0.17, 0.44, 0.094, 0.116)),
       cuerpo=dict(manga="corta", color_manga="tela", camisa="tela", botas="zapato"),
       vestir=vestir_panadera, agarra="", barrio=True,
       reposo={"brazo.L": (-6, -10, 0), "antebrazo.L": (-24, 0, 0), "brazo.R": (-6, 10, 0), "antebrazo.R": (-24, 0, 0),
               "cabeza": (0, 0, -3)},
       tarea="recoger",
       personas={"maela": P_("clara", (0.55, 0.30, 0.14), "verde", ojos="alegre", boca="sonrisa", pecas=True,
                             ropa=(0.70, 0.52, 0.36), ropa2=(0.48, 0.30, 0.22), acento=(0.92, 0.86, 0.74),
                             tela=(0.97, 0.95, 0.91), extra=(0.85, 0.40, 0.30))})


# --- porteador: ancho, chaleco, pañuelo al cuello, barba corta y bolsa al cinto; manos libres -------------------------
def vestir_porteador(M, F, A, E, P):
    chaleco(M, F, "ropa")
    pelo(M, F, "corto")
    barba(M, F)
    panuelo_cuello(M, F, "extra")
    bolsa(M, F, 0.14, "cuero")


oficio("porteador", figura=Figura(sb=1.03, sx=1.14, st=1.12, sh=0.98, ojo=(0.17, 0.44, 0.088, 0.1)),
       cuerpo=dict(manga="corta", color_manga="tela", camisa="tela", botas="altas"),
       vestir=vestir_porteador, agarra="", barrio=True,
       reposo={"brazo.L": (-4, -8, 0), "antebrazo.L": (-16, 0, 0), "brazo.R": (-4, 8, 0), "antebrazo.R": (-16, 0, 0),
               "pecho": (-2, 0, 0)},
       tarea="ajustar",
       personas={"tobias": P_("morena", (0.18, 0.12, 0.08), "pardo", ojos="normal", boca="media_sonrisa",
                              ropa=(0.34, 0.40, 0.52), ropa2=(0.40, 0.33, 0.26), acento=(0.70, 0.55, 0.30),
                              tela=(0.86, 0.80, 0.68), pantalon=(0.36, 0.32, 0.28), extra=(0.75, 0.30, 0.20),
                              cuero=(0.42, 0.28, 0.16))})


# --- encargada del establo: túnica corta, chaleco de cuero, coleta, botas altas; manos libres ---------------------------
def vestir_encargada(M, F, A, E, P):
    tunica(M, F, "ropa", hasta=0.40, cinturon="cuero")
    chaleco(M, F, "ropa2")
    pelo(M, F, "coleta")
    panuelo_cuello(M, F, "extra")


oficio("encargada_establo", figura=Figura(sb=1.0, sx=1.0, st=1.0, sh=1.0, ojo=(0.17, 0.44, 0.094, 0.114)),
       cuerpo=dict(manga="larga", color_manga="ropa", camisa="ropa", botas="altas", puno="cuero"),
       vestir=vestir_encargada, agarra="", barrio=True,
       reposo={"brazo.L": (-6, -8, 0), "antebrazo.L": (-20, 0, 0), "brazo.R": (-6, 8, 0), "antebrazo.R": (-20, 0, 0),
               "cadera": (0, 2, -2)},
       tarea="echar_grano",
       personas={"brena": P_("media", (0.62, 0.36, 0.16), "ambar", ojos="normal", boca="sonrisa", pecas=True,
                             ropa=(0.40, 0.52, 0.32), ropa2=(0.46, 0.34, 0.22), acento=(0.85, 0.70, 0.40),
                             extra=(0.86, 0.70, 0.30), cuero=(0.40, 0.26, 0.16))})
SOMBRERO.add("panadera")

# Personas nuevas de oficios que ya existen (se añaden al final: la primera de cada oficio, la del GLB, no cambia).
OFICIOS["herrero"]["personas"]["damian"] = P_("media", (0.30, 0.20, 0.12), "pardo", ojos="normal", boca="media_sonrisa",
                                              tela=(0.84, 0.78, 0.64), ropa=(0.46, 0.36, 0.24), ropa2=(0.52, 0.40, 0.26),
                                              acento=(0.80, 0.62, 0.34), pantalon=(0.32, 0.30, 0.26),
                                              cuero=(0.50, 0.34, 0.20))
OFICIOS["campesina"]["personas"]["odila"] = P_("media", (0.30, 0.18, 0.12), "pardo", ojos="normal", boca="sonrisa",
                                               ropa=(0.62, 0.30, 0.36), ropa2=(0.36, 0.32, 0.46), acento=(0.94, 0.88, 0.76),
                                               tela=(0.94, 0.92, 0.86), extra=(0.70, 0.42, 0.52))
OFICIOS["nina"]["personas"]["nela"] = P_("media", (0.30, 0.18, 0.10), "pardo", ojos="grande", boca="risa", pecas=True,
                                         ropa=(0.86, 0.66, 0.30), ropa2=(0.4, 0.3, 0.2), acento=(0.98, 0.95, 0.88),
                                         extra=(0.40, 0.62, 0.40))


# ================================================================== clips

ABIERTOS = {"parpado.L@esc": (1, 0.04, 1), "parpado.R@esc": (1, 0.04, 1)}
CERRADOS = {"parpado.L@esc": (1, 1, 1), "parpado.R@esc": (1, 1, 1)}


def ojos_(p, cerrados=False):
    return C.sumar(p, CERRADOS if cerrados else ABIERTOS)


def espejo(p):
    """La misma pose del otro lado (izquierda ↔ derecha)."""
    out = {}
    for k, v in p.items():
        base, suf = (k.split("@") + [""])[:2]
        suf = "@" + suf if suf else ""
        if base.endswith(".L"):
            nb = base[:-2] + ".R"
        elif base.endswith(".R"):
            nb = base[:-2] + ".L"
        else:
            nb = base
        if suf == "@esc":
            out[nb + suf] = v
        elif suf == "@loc":
            out[nb + suf] = (-v[0], v[1], v[2])
        else:
            out[nb + suf] = (v[0], -v[1], -v[2])
    return out


def escalar(p, k):
    return {kk: (tuple(x * k for x in v) if not kk.endswith("@esc") else v) for kk, v in p.items()}


def solo(p, quitar):
    return {k: v for k, v in p.items() if not any(k.startswith(q) for q in quitar)}


def clips(arm, nombre, D):
    F = D["figura"]
    R = D["reposo"]
    nino = D.get("nino", False)
    agarra = D.get("agarra", "")
    fps = 30
    # --- reposo: respiración, cambio de peso y dos parpadeos (4 s)
    resp = {"pecho": (-1.5, 0, 0), "cabeza": (1.5, 0, 0), "hombro.L": (0, 0, 2), "hombro.R": (0, 0, -2)}
    mov = C.sumar(R, {"cadera": (0, -1.5, -1.5), "raiz@loc": (-0.006, 0, 0), "cabeza": (0, 2, -5)})
    C.crear_clip(arm, "reposo", [
        (1, ojos_(R)), (30, ojos_(C.sumar(R, resp))), (44, ojos_(C.sumar(R, resp), True)),
        (47, ojos_(C.sumar(R, resp))), (61, ojos_(mov)), (90, ojos_(C.sumar(mov, resp))),
        (106, ojos_(C.sumar(mov, resp), True)), (109, ojos_(C.sumar(mov, resp))), (121, ojos_(R))])

    # --- caminar (1 s, dos pasos; en el sitio). El brazo que lleva algo apenas se balancea.
    def paso(muslo, rodilla, brazo, alto=1.0):
        bR = 0.25 if agarra == "R" else 1.0
        bL = 0.25 if agarra == "L" else 1.0
        contacto = {"muslo.L": (-muslo, 0, 0), "pierna.L": (6, 0, 0), "pie.L": (-12, 0, 0),
                    "muslo.R": (muslo * 0.75, 0, 0), "pierna.R": (14, 0, 0), "pie.R": (16, 0, 0),
                    "brazo.L": (brazo * bL, 0, 0), "antebrazo.L": (-8 * bL, 0, 0),
                    "brazo.R": (-brazo * bR, 0, 0), "antebrazo.R": (-22 * bR, 0, 0),
                    "cadera": (0, 0, -5), "pecho": (2, 0, 6), "raiz@loc": (0, 0, -0.014 * F.sb * alto)}
        paso_ = {"muslo.L": (2, 0, 0), "pierna.L": (4, 0, 0), "muslo.R": (-12, 0, 0), "pierna.R": (rodilla, 0, 0),
                 "pie.R": (-6, 0, 0), "brazo.L": (2, 0, 0), "brazo.R": (-2, 0, 0), "pecho": (2, 0, 0),
                 "raiz@loc": (0, 0, 0.012 * F.sb * alto)}
        return contacto, paso_
    marcha = D.get("marcha", 1.0)
    A1, P1 = paso(26 * marcha, 46, 18 * marcha)
    base_andar = solo(R, ["muslo", "pierna", "pie", "cadera", "raiz"])
    if agarra != "R":
        base_andar = solo(base_andar, ["brazo.R", "antebrazo.R"])
    if agarra != "L":
        base_andar = solo(base_andar, ["brazo.L", "antebrazo.L"])
    C.crear_clip(arm, "caminar", [
        (1, ojos_(C.sumar(base_andar, A1))), (8, ojos_(C.sumar(base_andar, P1))),
        (16, ojos_(C.sumar(base_andar, espejo(A1)))), (23, ojos_(C.sumar(base_andar, espejo(P1)))),
        (31, ojos_(C.sumar(base_andar, A1)))])
    if nino:
        # --- correr (0,6 s): zancada larga, brazos doblados, el cuerpo hacia delante
        A2, P2 = paso(40, 80, 34, alto=2.2)
        A2 = C.sumar(A2, {"antebrazo.L": (-60, 0, 0), "antebrazo.R": (-60, 0, 0), "columna": (8, 0, 0)})
        P2 = C.sumar(P2, {"antebrazo.L": (-60, 0, 0), "antebrazo.R": (-60, 0, 0), "columna": (8, 0, 0)})
        bc = solo(R, ["muslo", "pierna", "pie", "cadera", "raiz", "brazo", "antebrazo"])
        C.crear_clip(arm, "correr", [(1, ojos_(C.sumar(bc, A2))), (5, ojos_(C.sumar(bc, P2))),
                                     (10, ojos_(C.sumar(bc, espejo(A2)))), (14, ojos_(C.sumar(bc, espejo(P2)))),
                                     (19, ojos_(C.sumar(bc, A2)))])
    # --- hablar (2,5 s): la mano libre se abre hacia quien escucha, asiente
    libre = "L" if agarra == "R" else "R"
    sgn = 1 if libre == "L" else -1
    abre = C.sumar(R, {"brazo." + libre: (-50, -14 * sgn, 0), "antebrazo." + libre: (-30, 0, 20 * sgn),
                       "mano." + libre: (0, -40 * sgn, 0), "cabeza": (-4, 0, -6 * sgn), "pecho": (-3, 0, -4 * sgn)})
    golpe = C.sumar(abre, {"antebrazo." + libre: (-12, 0, 0), "cabeza": (8, 0, 0)})
    C.crear_clip(arm, "hablar", [(1, ojos_(R)), (12, ojos_(abre)), (22, ojos_(golpe)), (32, ojos_(abre)),
                                 (40, ojos_(golpe, True)), (43, ojos_(golpe)), (56, ojos_(abre)), (76, ojos_(R))])
    # --- saludar (1,6 s): la mano libre arriba y dos vaivenes
    arriba = C.sumar(R, {"brazo." + libre: (-150, -10 * sgn, 0), "antebrazo." + libre: (-20, 0, 0),
                         "mano." + libre: (0, 0, 0), "cabeza": (-6, 0, 0), "pecho": (-3, 0, 0)})
    C.crear_clip(arm, "saludar", [(1, ojos_(R)), (10, ojos_(arriba)),
                                  (17, ojos_(C.sumar(arriba, {"antebrazo." + libre: (0, 0, 28 * sgn)}))),
                                  (24, ojos_(C.sumar(arriba, {"antebrazo." + libre: (0, 0, -24 * sgn)}))),
                                  (31, ojos_(C.sumar(arriba, {"antebrazo." + libre: (0, 0, 28 * sgn)}), True)),
                                  (36, ojos_(arriba)), (49, ojos_(R))])
    # --- la tarea de su oficio (en bucle)
    t = D["tarea"]
    if t == "martillar":
        alto_ = C.sumar(R, {"brazo.R": (-140, 8, 0), "antebrazo.R": (-50, 0, 0), "mano.R": (-20, 0, 0),
                            "brazo.L": (-40, -6, 0), "antebrazo.L": (-50, 0, 10), "pecho": (-6, 0, 6),
                            "cabeza": (14, 0, 0)})
        golpe = C.sumar(R, {"brazo.R": (-48, 4, 0), "antebrazo.R": (-30, 0, 0), "mano.R": (20, 0, 0),
                            "brazo.L": (-40, -6, 0), "antebrazo.L": (-50, 0, 10), "pecho": (10, 0, -2),
                            "columna": (6, 0, 0), "cabeza": (18, 0, 0)})
        C.crear_clip(arm, "tarea", [(1, ojos_(golpe)), (14, ojos_(alto_)), (20, ojos_(alto_)), (25, ojos_(golpe)),
                                    (30, ojos_(C.sumar(golpe, {"pecho": (2, 0, 0)}))), (37, ojos_(golpe))])
    elif t == "pregonar":
        a = C.sumar(R, {"brazo.R": (-120, 20, 0), "antebrazo.R": (-30, 0, 0), "mano.R": (0, 0, 0),
                        "brazo.L": (-60, -24, 0), "antebrazo.L": (-10, 0, 30), "mano.L": (0, -40, 0),
                        "pecho": (-8, 0, 0), "cabeza": (-10, 0, 8), "raiz@loc": (0, 0, 0.01)})
        b = C.sumar(a, {"brazo.R": (10, 0, 0), "antebrazo.R": (0, 0, -25), "cabeza": (4, 0, -14), "pecho": (0, 0, -6),
                        "raiz@loc": (0, 0, -0.012)})
        C.crear_clip(arm, "tarea", [(1, ojos_(R)), (14, ojos_(a)), (26, ojos_(b)), (38, ojos_(a)), (50, ojos_(b)),
                                    (60, ojos_(b, True)), (63, ojos_(b)), (80, ojos_(R))])
    elif t == "remover":
        k = [(1, ojos_(R))]
        for i, f in enumerate(range(8, 61, 6)):
            ang = i * 90
            k.append((f, ojos_(C.sumar(R, {"antebrazo.R": (6 * math.sin(math.radians(ang)), 0,
                                                            14 * math.cos(math.radians(ang))),
                                           "mano.R": (10 * math.cos(math.radians(ang)), 0, 0),
                                           "cabeza": (10, 0, 4 * math.sin(math.radians(ang)))}), i == 6)))
        k.append((72, ojos_(C.sumar(R, {"brazo.R": (-30, 0, 0), "antebrazo.R": (-10, 0, 0), "cabeza": (-6, 0, 0)}))))
        k.append((90, ojos_(R)))
        C.crear_clip(arm, "tarea", k)
    elif t == "vigilar":
        izq = C.sumar(R, {"cabeza": (0, 0, 32), "cuello": (0, 0, 10), "pecho": (0, 0, 6)})
        der = C.sumar(R, {"cabeza": (0, 0, -32), "cuello": (0, 0, -10), "pecho": (0, 0, -6)})
        C.crear_clip(arm, "tarea", [(1, ojos_(R)), (20, ojos_(izq)), (45, ojos_(izq)), (48, ojos_(izq, True)),
                                    (51, ojos_(izq)), (75, ojos_(der)), (100, ojos_(der)), (121, ojos_(R))])
    elif t in ("cavar", "recoger"):
        if t == "cavar":
            arriba = C.sumar(R, {"brazo.R": (-120, 6, 0), "antebrazo.R": (-50, 0, 0), "brazo.L": (-90, -6, 0),
                                 "antebrazo.L": (-40, 0, 10), "pecho": (-6, 0, 0), "columna": (-2, 0, 0)})
            abajo = C.sumar(R, {"brazo.R": (-40, 6, 0), "antebrazo.R": (-20, 0, 0), "brazo.L": (-50, -6, 0),
                                "antebrazo.L": (-30, 0, 10), "pecho": (16, 0, 0), "columna": (14, 0, 0),
                                "cabeza": (10, 0, 0), "muslo.L": (-10, 0, 0), "muslo.R": (-10, 0, 0),
                                "pierna.L": (16, 0, 0), "pierna.R": (16, 0, 0), "raiz@loc": (0, 0, -0.03 * F.sb)})
            C.crear_clip(arm, "tarea", [(1, ojos_(R)), (14, ojos_(arriba)), (22, ojos_(abajo)), (34, ojos_(abajo)),
                                        (46, ojos_(arriba)), (54, ojos_(abajo)), (66, ojos_(abajo, True)),
                                        (69, ojos_(abajo)), (90, ojos_(R))])
        else:
            agacha = C.sumar(R, {"columna": (20, 0, 0), "pecho": (22, 0, 0), "cabeza": (10, 0, 0),
                                 "brazo.R": (-70, 6, 0), "antebrazo.R": (-10, 0, 0), "muslo.L": (-16, 0, 0),
                                 "muslo.R": (-16, 0, 0), "pierna.L": (26, 0, 0), "pierna.R": (26, 0, 0),
                                 "pie.L": (-10, 0, 0), "pie.R": (-10, 0, 0), "raiz@loc": (0, 0, -0.05 * F.sb)})
            echa = C.sumar(R, {"brazo.R": (-60, -30, 0), "antebrazo.R": (-60, 0, -30), "cabeza": (8, 0, 14),
                               "pecho": (0, 0, 10)})
            C.crear_clip(arm, "tarea", [(1, ojos_(R)), (18, ojos_(agacha)), (30, ojos_(agacha)), (44, ojos_(echa)),
                                        (52, ojos_(echa, True)), (55, ojos_(echa)), (72, ojos_(R))])
    elif t == "estirar":
        espalda = C.sumar(R, {"brazo.L": (40, -10, 0), "antebrazo.L": (-70, 0, 30), "columna": (-10, 0, 0),
                              "pecho": (-14, 0, 0), "cuello": (6, 0, 0), "cabeza": (-12, 0, 0)})
        C.crear_clip(arm, "tarea", [(1, ojos_(R)), (24, ojos_(espalda)), (50, ojos_(espalda, True)),
                                    (60, ojos_(espalda, True)), (66, ojos_(espalda)),
                                    (90, ojos_(C.sumar(R, {"cabeza": (0, 0, 20)}))), (120, ojos_(R))])
    elif t == "echar_grano":
        echa = C.sumar(R, {"brazo.R": (-60, 30, 0), "antebrazo.R": (-20, 0, -20), "mano.R": (20, -40, 0),
                           "pecho": (8, 0, -8), "cabeza": (14, 0, -10)})
        coge = C.sumar(R, {"brazo.R": (-20, -6, 0), "antebrazo.R": (-90, 0, 40), "pecho": (4, 0, 0),
                           "cabeza": (10, 0, 0)})
        C.crear_clip(arm, "tarea", [(1, ojos_(R)), (14, ojos_(coge)), (26, ojos_(echa)), (40, ojos_(coge)),
                                    (52, ojos_(C.sumar(echa, {"brazo.R": (0, 10, 0)}))), (60, ojos_(echa, True)),
                                    (63, ojos_(echa)), (84, ojos_(R))])
    elif t == "jugar":
        # saltitos con los brazos arriba (pillar, la comba): 1,2 s en bucle
        agach = C.sumar(R, {"muslo.L": (-24, 0, 0), "muslo.R": (-24, 0, 0), "pierna.L": (40, 0, 0),
                            "pierna.R": (40, 0, 0), "pie.L": (-14, 0, 0), "pie.R": (-14, 0, 0),
                            "columna": (10, 0, 0), "raiz@loc": (0, 0, -0.05 * F.sb),
                            "brazo.L": (20, -10, 0), "brazo.R": (20, 10, 0)})
        aire = C.sumar(R, {"raiz@loc": (0, 0, 0.13 * F.sb), "brazo.L": (-150, -20, 0), "brazo.R": (-150, 20, 0),
                           "pie.L": (20, 0, 0), "pie.R": (20, 0, 0), "cabeza": (-12, 0, 0), "muslo.L": (-8, 0, 0)})
        C.crear_clip(arm, "tarea", [(1, ojos_(R)), (8, ojos_(agach)), (16, ojos_(aire)), (24, ojos_(agach)),
                                    (32, ojos_(C.sumar(aire, {"cabeza": (0, 0, 15)}), True)), (40, ojos_(agach)),
                                    (49, ojos_(R))])
    elif t == "ajustar":
        tira = C.sumar(R, {"brazo.L": (-30, -6, 0), "antebrazo.L": (-100, 0, -30), "brazo.R": (-18, 6, 0),
                           "pecho": (-6, 0, 0), "cabeza": (-14, 0, 10), "raiz@loc": (0, 0, 0.012)})
        mira = C.sumar(R, {"cabeza": (-10, 0, -26), "cuello": (-4, 0, -8), "pecho": (0, 0, -8)})
        C.crear_clip(arm, "tarea", [(1, ojos_(R)), (14, ojos_(tira)), (22, ojos_(C.sumar(tira, {"raiz@loc": (0, 0, -0.012)}))),
                                    (30, ojos_(tira)), (46, ojos_(R)), (66, ojos_(mira)), (80, ojos_(mira, True)),
                                    (83, ojos_(mira)), (105, ojos_(R))])
    elif t == "barrer":
        a = C.sumar(R, {"brazo.R": (-34, 20, 0), "antebrazo.R": (-40, 0, 26), "brazo.L": (-56, -10, 0),
                        "antebrazo.L": (-50, 0, 30), "pecho": (12, 0, 14), "columna": (6, 0, 6), "cabeza": (10, 0, 6)})
        b = C.sumar(R, {"brazo.R": (-34, -10, 0), "antebrazo.R": (-40, 0, -20), "brazo.L": (-56, 10, 0),
                        "antebrazo.L": (-50, 0, -10), "pecho": (12, 0, -14), "columna": (6, 0, -6), "cabeza": (10, 0, -6)})
        C.crear_clip(arm, "tarea", [(1, ojos_(R)), (12, ojos_(a)), (26, ojos_(b)), (40, ojos_(a)), (54, ojos_(b)),
                                    (62, ojos_(b, True)), (65, ojos_(b)), (80, ojos_(R))])
    # --- (16/11) barrio experimental de Oakhaven: llevar con las dos manos y los trabajos del barrio. SOLO los oficios con
    # «barrio» (los demás no cambian). Todos parten y acaban en una pose fija (bucles cerrados).
    if D.get("barrio"):
        sin_brazos = ["brazo", "antebrazo", "mano"]
        lleva = {"brazo.L": (-48, -4, 0), "antebrazo.L": (-62, 0, -22), "brazo.R": (-48, 4, 0),
                 "antebrazo.R": (-62, 0, 22), "pecho": (-3, 0, 0), "cabeza": (-3, 0, 0)}
        quieto = C.sumar(solo(R, sin_brazos), lleva)
        C.crear_clip(arm, "llevar_quieto", [(1, ojos_(quieto)), (30, ojos_(C.sumar(quieto, resp))),
                                            (44, ojos_(C.sumar(quieto, resp), True)), (47, ojos_(C.sumar(quieto, resp))),
                                            (61, ojos_(quieto))])
        pA, pP = solo(A1, ["brazo", "antebrazo"]), solo(P1, ["brazo", "antebrazo"])
        andar_l = C.sumar(solo(base_andar, sin_brazos), lleva)
        C.crear_clip(arm, "caminar_llevar", [(1, ojos_(C.sumar(andar_l, pA))), (8, ojos_(C.sumar(andar_l, pP))),
                                             (16, ojos_(C.sumar(andar_l, espejo(pA)))),
                                             (23, ojos_(C.sumar(andar_l, espejo(pP)))), (31, ojos_(C.sumar(andar_l, pA)))])
        agacha = C.sumar(R, {"columna": (18, 0, 0), "pecho": (16, 0, 0), "cabeza": (8, 0, 0),
                             "brazo.L": (-60, -4, 0), "antebrazo.L": (-20, 0, -15), "brazo.R": (-60, 4, 0),
                             "antebrazo.R": (-20, 0, 15), "muslo.L": (-22, 0, 0), "muslo.R": (-22, 0, 0),
                             "pierna.L": (36, 0, 0), "pierna.R": (36, 0, 0), "pie.L": (-14, 0, 0), "pie.R": (-14, 0, 0),
                             "raiz@loc": (0, 0, -0.07 * F.sb)})
        C.crear_clip(arm, "coger", [(1, ojos_(R)), (10, ojos_(agacha)), (14, ojos_(agacha)), (25, ojos_(quieto))])
        C.crear_clip(arm, "dejar", [(1, ojos_(quieto)), (11, ojos_(agacha)), (15, ojos_(agacha)), (25, ojos_(R))])
        base_l = solo(R, sin_brazos)
        recoge = C.sumar(base_l, {"brazo.L": (-55, -4, 0), "antebrazo.L": (-50, 0, -14), "brazo.R": (-55, 4, 0),
                                  "antebrazo.R": (-50, 0, 14), "pecho": (-2, 0, 0)})
        empuja = C.sumar(base_l, {"brazo.L": (-82, -4, 0), "antebrazo.L": (-12, 0, -10), "brazo.R": (-82, 4, 0),
                                  "antebrazo.R": (-12, 0, 10), "pecho": (8, 0, 0), "columna": (6, 0, 0)})
        C.crear_clip(arm, "hornear", [(1, ojos_(recoge)), (20, ojos_(empuja)), (32, ojos_(empuja)), (48, ojos_(recoge, True)),
                                      (51, ojos_(recoge)), (61, ojos_(recoge))])
        presiona = C.sumar(base_l, {"columna": (12, 0, 0), "pecho": (10, 0, 0), "cabeza": (10, 0, 0),
                                    "brazo.L": (-40, -2, 0), "antebrazo.L": (-40, 0, -18), "mano.L": (20, 0, 0),
                                    "brazo.R": (-40, 2, 0), "antebrazo.R": (-40, 0, 18), "mano.R": (20, 0, 0)})
        estira = C.sumar(presiona, {"brazo.L": (-14, 0, 0), "brazo.R": (-14, 0, 0), "antebrazo.L": (24, 0, 0),
                                    "antebrazo.R": (24, 0, 0), "pecho": (6, 0, 0), "raiz@loc": (0, 0, -0.01)})
        C.crear_clip(arm, "amasar", [(1, ojos_(presiona)), (12, ojos_(estira)), (20, ojos_(presiona)),
                                     (28, ojos_(C.sumar(estira, {"cabeza": (0, 0, 6)}), True)), (31, ojos_(estira)),
                                     (37, ojos_(presiona))])
        cep = C.sumar(R, {"brazo.R": (-75, 10, 0), "antebrazo.R": (-25, 0, 0), "brazo.L": (-30, -10, 0),
                          "antebrazo.L": (-40, 0, 0), "pecho": (4, 0, -6), "cabeza": (4, 0, -6)})
        izq = C.sumar(cep, {"brazo.R": (0, -22, 0), "antebrazo.R": (0, 0, -18), "pecho": (0, 0, 4)})
        der = C.sumar(cep, {"brazo.R": (6, 18, 0), "antebrazo.R": (0, 0, 14), "pecho": (0, 0, -4)})
        C.crear_clip(arm, "cepillar", [(1, ojos_(cep)), (8, ojos_(izq)), (16, ojos_(der)), (24, ojos_(izq, True)),
                                       (27, ojos_(izq)), (31, ojos_(cep))])
        alza = C.sumar(R, {"brazo.R": (-70, 6, 0), "antebrazo.R": (-30, 0, 10), "brazo.L": (-60, -6, 0),
                           "antebrazo.L": (-30, 0, -20), "pecho": (6, 0, 0)})
        vuelca = C.sumar(alza, {"mano.R": (0, 0, 45), "antebrazo.R": (0, 30, 0), "pecho": (6, 0, 0)})
        C.crear_clip(arm, "verter", [(1, ojos_(alza)), (14, ojos_(vuelca)), (32, ojos_(vuelca)), (46, ojos_(alza))])
    # velocidad al andar (m/s) para que los pies no patinen: lo que avanza el pie apoyado en medio ciclo
    pierna_l = (F.cadera_l - F.tobillo).length + 0.05 * F.sb
    a1, a2 = 26 * marcha, 26 * marcha * 0.75
    v = pierna_l * (math.sin(math.radians(a1)) + math.sin(math.radians(a2))) / 0.5
    vr = 0.0
    if nino:
        vr = pierna_l * (math.sin(math.radians(40)) + math.sin(math.radians(30))) / 0.3
    return {"velocidad": round(v, 3), "velocidad_correr": round(vr, 3)}


# ================================================================== construir, exportar y renderizar

def construir(nombre):
    global _oficio_actual
    _oficio_actual = nombre
    D = OFICIOS[nombre]
    F = D["figura"]
    esc = C.escena_vacia()
    personas = D["personas"]
    primera = list(personas)[0]
    carpeta = os.path.join(SALIDA, nombre)
    os.makedirs(carpeta, exist_ok=True)
    # un atlas por persona (misma disposición); el primero va dentro del GLB
    imagenes = {}
    for i, (pid, P) in enumerate(personas.items()):
        A = AtlasNPC(512, semilla=sum(ord(c) for c in pid))
        paleta(A, P)
        dibujar_cara(A, F, P)
        dibujar_detalle(A, P)
        img = A.guardar(os.path.join(carpeta, pid + ".png"), pid)
        imagenes[pid] = (A, img)
    A, img = imagenes[primera]
    arm = C.crear_armadura(nombre, huesos(F), esc.collection)
    E = EnPose(arm, D["reposo"])
    M = C.Malla(A)
    cuerpo(M, F, D["cuerpo"])
    D["vestir"](M, F, A, E, personas[primera])
    ob = M.objeto(nombre + "_malla", esc.collection)
    sueltos = [v.co for v in ob.data.vertices if not any(g.weight > 1e-4 for g in v.groups)]
    if sueltos:      # un vértice sin hueso hace que el exportador añada «neutral_bone» (el esqueleto deja de ser común)
        print("SIN PESO", nombre, len(sueltos), [tuple(round(c, 3) for c in s) for s in sueltos[:6]])
    ob.data.materials.append(C.material_atlas("npc_" + nombre, img, rugoso=0.85))
    C.enlazar(ob, arm)
    datos = clips(arm, nombre, D)
    tris = C.triangulos(ob)
    if tris > PRESUPUESTO_TRIS:
        print("FUERA DE PRESUPUESTO", nombre, tris, ">", PRESUPUESTO_TRIS)
    datos.update({"triangulos": tris, "vertices": len(ob.data.vertices), "huesos": len(arm.data.bones),
                  "personas": list(personas), "tarea": D["tarea"], "agarra": D.get("agarra", ""),
                  "nino": bool(D.get("nino", False)), "alto": round(F.zh(1.52), 3)})
    print("NPC", nombre, json.dumps(datos))
    C.exportar_glb(os.path.join(carpeta, nombre + ".glb"))
    with open(os.path.join(carpeta, nombre + ".json"), "w", encoding="utf-8") as f:
        json.dump(datos, f, ensure_ascii=False, indent=1)
    return datos


resumen = {}
for nombre in (SOLO or list(OFICIOS)):
    resumen[nombre] = construir(nombre)
with open(os.path.join(LAMINAS, "resumen_npc.json"), "w", encoding="utf-8") as f:
    json.dump(resumen, f, ensure_ascii=False, indent=1)
print("HECHO", len(resumen))
