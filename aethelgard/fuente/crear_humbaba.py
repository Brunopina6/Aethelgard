# Humbaba, el Corazón del Bosque Muerto (V12, 12/11/2026, especialista de animaciones). Encargo del usuario
# (docs/v12/ENCARGO_HUMBABA.md) a partir de su lámina de referencia (D:\REBELUM_diagnostico\v12\referencias\
# humbaba_referencia_usuario.webp, SHA-256 8b6c183a…881a; la aportó el usuario y su licencia no está registrada: NO se
# copia al juego ni se usa como textura). Geometría, textura, esqueleto, controles (IK) y clips generados por este guion:
# obra propia, procedural, sin recursos de fuera. Método y bloques genéricos aprendidos de fuente/crear_bramavidrio4.py
# (constructor de mallas, ruido de la textura, WebP con alfa mínimo, materiales para las fotos y exportación).
#
#   blender -b --factory-startup -P crear_humbaba.py -- <carpeta> [alto,medio,bajo] [<salida.blend>|-] [<fotos>|-] [<etapas>]
#     <carpeta>  donde deja humbaba*.glb, humbaba_madera*.webp y humbaba_clips.json
#     <fotos>    carpeta para las fotos de Blender de cada etapa (vistas frente a la lámina, rig, deformaciones, clips)
#     <etapas>   «todo» (por defecto), «blockout» (solo formas grises y fotos, sin exportar) o «rig» (sin clips)
#
# EJES (Blender): mira a −Y, Z arriba, su izquierda es +X. En Godot mira a +Z (exportación Y arriba). Medidas en metros:
# 13,3 m hasta la punta de la corona (la cabeza a 12,2 m, con las piernas estiradas: estirar()). El bastón, 12 m.
#
# LO QUE CONSERVA DE LA LÁMINA: coloso de raíces retorcidas y troncos petrificados (cada miembro es un haz de raíces que
# se enroscan sobre un núcleo de tronco); cabeza-tronco con corona de ramas secas y un único gran ojo turquesa en la
# frente bajo una placa de corteza en punta; boca oscura con dientes de madera que se abre (mandíbula con hueso); núcleo
# turquesa en el pecho dentro de un marco de raíces en forma de corazón, con vetas que irradian; brazos largos, gruesos y
# ASIMÉTRICOS (el izquierdo, el de la garra, más largo y grueso) con manos enormes de tres dedos y pulgar acabados en
# garras de madera clara; piernas de raíces entrelazadas que se abren en raíces sobre el suelo, con garras en los pies;
# musgo en lo alto de hombros, brazos y cabeza, lianas y raíces colgantes; hombreras de corteza con espirales talladas;
# el bastón ancestral aparte (fuste retorcido, cabeza de ramas, gemas turquesa, cuerdas y amuletos colgantes).
# Paleta: madera oscura gris-parda, verdes desaturados y magia turquesa.
#
# ESQUELETO (71 huesos que se exportan, todos «deformantes»; los controles no se exportan): raíz, pelvis, 3 de columna,
# pecho, 2 de cuello, cabeza, mandíbula, ojo, núcleo, «luz» (sin pesos: su escala X es la intensidad del brillo que lee
# Godot); por brazo hombro, brazo, antebrazo, muñeca, palma y 4 dedos de 2 tramos (3 dedos y pulgar); por pierna muslo,
# pierna, tobillo, pie y punta (las raíces delanteras del pie); corona en 3 conjuntos de 2 huesos; 5 cadenas de raíces
# colgantes de 3 tramos; y «baston» (hijo de la palma derecha: el anclaje del arma). Controles de Blender (no se
# exportan, los clips se muestrean con ellos): IK de las piernas (pie y rodilla), IK/FK de los brazos (mano y codo, con
# la influencia animada: 0 = FK), mira del ojo (Damped Track) y mira del bastón (Damped Track desde la mano).

import bpy, math, os, sys, json
import numpy as np
from mathutils import Vector, Matrix, Quaternion, Euler

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
CARPETA = argv[0] if argv else ""
MODO = argv[1] if len(argv) > 1 else "alto,medio,bajo"
PERFILES = [p for p in MODO.split(",") if p in ("alto", "medio", "bajo")]
SALIDA_BLEND = argv[2] if len(argv) > 2 and argv[2] not in ("", "-") else ""
CARPETA_FOTOS = argv[3] if len(argv) > 3 and argv[3] not in ("", "-") else ""
ETAPAS = argv[4] if len(argv) > 4 and argv[4] else "todo"
FPS = 30
PREFIJO = "humbaba"
TEX = 2048
ALFA_MIN = 0.04

CALIDAD = {
    "alto": dict(lados=12, paso=0.32, hebra_lados=6, hebras=1.0, rama_prof=3, rama_lados=6, musgo=1.0, dedo_lados=8,
                 garra_lados=7, colgantes=3, tex=2048),
    "medio": dict(lados=9, paso=0.5, hebra_lados=5, hebras=0.6, rama_prof=2, rama_lados=5, musgo=0.5, dedo_lados=6,
                  garra_lados=5, colgantes=2, tex=1024),
    "bajo": dict(lados=7, paso=0.8, hebra_lados=4, hebras=0.34, rama_prof=1, rama_lados=4, musgo=0.25, dedo_lados=5,
                 garra_lados=4, colgantes=1, tex=512),
}
Q = CALIDAD["alto"]
MATERIALES = ["madera", "brillo"]
MADERA, BRILLO = 0, 1

# ---------------------------------------------------------------- colores (sRGB), tomados de la lámina
MADERA_C = (0.35, 0.325, 0.29)            # corteza gris-parda (la lámina: gris verdoso, poco pardo)
MADERA_OSC = (0.19, 0.155, 0.125)          # los huecos entre raíces
MADERA_CLARA = (0.56, 0.53, 0.47)          # lo petrificado, cantos y hebras al sol
PETREA = (0.47, 0.47, 0.43)
MUSGO = (0.42, 0.53, 0.19)
MUSGO_OSC = (0.25, 0.32, 0.13)
GARRA = (0.70, 0.62, 0.50)                 # garras y dientes: madera clara como hueso
GARRA_PUNTA = (0.42, 0.34, 0.26)
BOCA = (0.035, 0.03, 0.03)
CUERDA = (0.60, 0.49, 0.34)
TURQUESA = (0.30, 0.98, 0.86)
TURQUESA_HONDO = (0.05, 0.55, 0.52)
BLANCO_OJO = (0.88, 1.0, 0.97)


def mezcla(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(a[i] * (1 - t) + b[i] * t for i in range(len(a)))


def suave(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def lineal(c):
    return tuple(x ** 2.2 for x in c[:3])


def V(*a):
    return Vector(a)


# 12/11, tras la hoja frente a la lámina: las piernas de la lámina son más largas. Todo se construye con las medidas de
# abajo y, al crear cada vértice y cada hueso, se estira en vertical lo que queda bajo la cadera (suave: los pies no
# cambian y la cadera empalma sin pliegue); lo de encima sube ESTIRA_PIERNAS metros (13,3 m en total).
ESTIRA_PIERNAS = 1.0
ALTO_CADERA = 5.6


def estirar(p):
    p = Vector(p)
    t = max(0.0, min(1.0, p.z / ALTO_CADERA))
    return Vector((p.x, p.y, p.z + ESTIRA_PIERNAS * t * t * (3 - 2 * t)))


# ---------------------------------------------------------------- el esqueleto (pose de enlace: postura A, encorvado)
# (nombre, cabeza, cola, padre); izquierda «_i» (+X), derecha «_d» (−X). Los de la derecha se escriben con su X.

def _brazo(l, s, largo):
    """Brazo de un lado: s = +1 izquierda, −1 derecha; largo > 1 alarga antebrazo y mano (la garra izquierda)."""
    x = lambda v: s * v
    h = [("hombro" + l, (x(0.75), -0.6, 8.55), (x(2.25), -0.55, 8.48), "pecho"),
         ("brazo" + l, (x(2.25), -0.55, 8.48), (x(3.0), -0.72, 6.2), "hombro" + l)]
    codo = Vector((x(3.0), -0.72, 6.2))
    mun = codo + Vector((x(0.38), -0.42, -2.4 * largo))
    pal = mun + Vector((x(0.08), -0.12, -0.5))
    fin = pal + Vector((x(0.05), -0.12, -0.62 * largo))
    h += [("antebrazo" + l, tuple(codo), tuple(mun), "brazo" + l),
          ("muneca" + l, tuple(mun), tuple(pal), "antebrazo" + l),
          ("palma" + l, tuple(pal), tuple(fin), "muneca" + l)]
    # dedos: la palma mira hacia el cuerpo; los dedos se abren de delante (índice) a atrás, el pulgar por dentro
    lf = 0.85 * largo
    for nombre, dy, dx, giro in (("dedo1", -0.34, 0.06, -0.18), ("dedo2", -0.02, 0.1, 0.0), ("dedo3", 0.3, 0.06, 0.16)):
        b0 = fin + Vector((x(dx), dy, 0.12))
        d = Vector((x(0.06), -0.3 + giro, -1.0)).normalized()
        b1 = b0 + d * 0.62 * lf
        d2 = Vector((x(0.02), -0.55 + giro, -0.85)).normalized()
        b2 = b1 + d2 * 0.55 * lf
        h += [(nombre + "_a" + l, tuple(b0), tuple(b1), "palma" + l), (nombre + "_b" + l, tuple(b1), tuple(b2), nombre + "_a" + l)]
    p0 = pal + Vector((x(-0.32), -0.28, -0.05))
    p1 = p0 + Vector((x(-0.28), -0.42, -0.5)) * lf
    p2 = p1 + Vector((x(-0.12), -0.5, -0.38)) * lf
    h += [("pulgar_a" + l, tuple(p0), tuple(p1), "palma" + l), ("pulgar_b" + l, tuple(p1), tuple(p2), "pulgar_a" + l)]
    return h


def _pierna(l, s):
    x = lambda v: s * v
    return [("muslo" + l, (x(1.3), 0.15, 5.2), (x(1.72), -0.28, 3.1), "pelvis"),
            ("pierna" + l, (x(1.72), -0.28, 3.1), (x(1.78), 0.1, 1.0), "muslo" + l),
            ("tobillo" + l, (x(1.78), 0.1, 1.0), (x(1.8), -0.25, 0.45), "pierna" + l),
            ("pie" + l, (x(1.8), -0.25, 0.45), (x(1.86), -1.35, 0.16), "tobillo" + l),
            ("punta" + l, (x(1.86), -1.35, 0.16), (x(1.92), -2.15, 0.05), "pie" + l)]


COLGANTES = [  # (sufijo, ancla, dirección de caída): raíces que cuelgan de la cintura y la espalda (cadenas de 3)
    ("1", (1.05, -1.05, 5.55), (0.18, -0.25, -1.0)),
    ("2", (-1.05, -1.05, 5.55), (-0.18, -0.25, -1.0)),
    ("3", (1.25, 0.75, 5.7), (0.25, 0.35, -1.0)),
    ("4", (-1.25, 0.75, 5.7), (-0.25, 0.35, -1.0)),
    ("5", (0.0, 1.05, 6.4), (0.0, 0.3, -1.0)),
]
LARGO_COLGANTE = [1.0, 0.95, 0.85]


def lista_huesos():
    h = [("raiz", (0, 0, 0), (0, 0, 1.2), None),
         ("pelvis", (0, 0.2, 5.0), (0, 0.15, 5.8), "raiz"),
         ("columna_1", (0, 0.15, 5.8), (0, 0.05, 6.6), "pelvis"),
         ("columna_2", (0, 0.05, 6.6), (0, -0.12, 7.4), "columna_1"),
         ("columna_3", (0, -0.12, 7.4), (0, -0.38, 8.15), "columna_2"),
         ("pecho", (0, -0.38, 8.15), (0, -0.72, 8.95), "columna_3"),
         ("cuello_1", (0, -0.72, 8.95), (0, -1.0, 9.45), "pecho"),
         ("cuello_2", (0, -1.0, 9.45), (0, -1.2, 9.9), "cuello_1"),
         ("cabeza", (0, -1.2, 9.9), (0, -1.3, 11.2), "cuello_2"),
         ("mandibula", (0, -1.3, 10.12), (0, -2.12, 9.82), "cabeza"),
         ("ojo", (0, -1.86, 10.74), (0, -2.36, 10.74), "cabeza"),
         ("nucleo", (0, -1.8, 7.95), (0, -2.3, 7.95), "columna_3"),
         ("luz", (0, 0, -1.0), (0, 0, -0.5), "raiz")]
    for g, base, d in (("c", (0, -1.28, 11.05), (0.0, 0.12, 1.0)), ("i", (0.45, -1.25, 10.95), (1.0, 0.1, 0.62)),
                       ("d", (-0.45, -1.25, 10.95), (-1.0, 0.1, 0.62))):
        b = Vector(base)
        dd = Vector(d).normalized()
        m = b + dd * 1.05
        dd2 = (dd + Vector((0, 0, 0.35))).normalized()
        t = m + dd2 * 1.0
        h += [("corona_%s1" % g, tuple(b), tuple(m), "cabeza"), ("corona_%s2" % g, tuple(m), tuple(t), "corona_%s1" % g)]
    h += _brazo("_i", 1, 1.02)
    h += _brazo("_d", -1, 0.9)
    h += _pierna("_i", 1)
    h += _pierna("_d", -1)
    a_ = [x for x in h if x[0] == "antebrazo_i"][0]          # la guadaña de raíces que brota del antebrazo izquierdo
    g0 = Vector(a_[1]).lerp(Vector(a_[2]), 0.45) + Vector((0.5, 0.05, 0.0))
    h.append(("guadana", tuple(g0), tuple(g0 + Vector((0.6, 0.2, 0.2))), "antebrazo_i"))
    for suf, ancla, d in COLGANTES:
        p = Vector(ancla)
        dd = Vector(d).normalized()
        padre = "pelvis" if ancla[2] < 6.0 else "columna_1"
        for k, letra in enumerate("abc"):
            q = p + dd * LARGO_COLGANTE[k]
            h.append(("colgante%s_%s" % (suf, letra), tuple(p), tuple(q), padre))
            p, padre = q, "colgante%s_%s" % (suf, letra)
    # el bastón: su origen en el puño derecho y apuntando arriba (su eje Y es el del fuste)
    pal_d = [x for x in h if x[0] == "palma_d"][0]
    agarre = (Vector(pal_d[1]) + Vector(pal_d[2])) * 0.5 + Vector((0.0, -0.05, 0.0))
    h.append(("baston", tuple(agarre), tuple(agarre + Vector((0, 0, 1.0))), "palma_d"))
    return h


# Controles (no se exportan: no deforman). (nombre, cabeza, cola, padre)
def lista_controles(H):
    d = {n: (Vector(a), Vector(b)) for (n, a, b, p) in H}
    c = []
    for l in ("_i", "_d"):
        a, b = d["tobillo" + l]
        c.append(("ctrl_pie" + l, tuple(a), tuple(b), "raiz"))
        rod = d["pierna" + l][0]
        c.append(("polo_rodilla" + l, tuple(rod + V(0, -4.0, 0)), tuple(rod + V(0, -4.0, 0.5)), "raiz"))
        mun = d["muneca" + l][0]
        c.append(("ctrl_mano" + l, tuple(mun), tuple(mun + V(0, 0, -0.6)), "raiz"))
        codo = d["antebrazo" + l][0]
        c.append(("polo_codo" + l, tuple(codo + V(0, 4.0, 0)), tuple(codo + V(0, 4.0, 0.5)), "raiz"))
    o = d["ojo"][0]
    c.append(("ctrl_ojo", tuple(o + V(0, -8.0, 0)), tuple(o + V(0, -8.0, 0.5)), "cabeza"))
    ag = d["baston"][0]
    c.append(("ctrl_baston", tuple(ag + V(0, -0.6, 6.0)), tuple(ag + V(0, -0.6, 6.5)), "raiz"))
    return c


HUESOS = lista_huesos()
CONTROLES = lista_controles(HUESOS)
NOMBRES = [h[0] for h in HUESOS]
POS = {h[0]: (Vector(h[1]), Vector(h[2])) for h in HUESOS + CONTROLES}
PADRE = {h[0]: h[3] for h in HUESOS + CONTROLES}


def cabeza_h(n):
    return POS[n][0].copy()


def cola_h(n):
    return POS[n][1].copy()


# ---------------------------------------------------------------- pesos

def proyectar(p, n):
    a, b = POS[n]
    ab = b - a
    L2 = max(ab.length_squared, 1e-9)
    t = (p - a).dot(ab) / L2
    tc = max(0.0, min(1.0, t))
    return t, (a + ab * tc - p).length, math.sqrt(L2)


def pesos_cadena(p, cadena, mezcla_m=0.35):
    """Pesos de un punto (el centro de un anillo) a lo largo de una cadena de huesos: el hueso más cercano y, cerca de
    cada articulación, una mezcla suave (½ y ½ justo en la articulación)."""
    mejor, k_m, t_m, L_m = 1e9, 0, 0.0, 1.0
    for k, n in enumerate(cadena):
        t, d, L = proyectar(p, n)
        if t < 0 and k > 0:
            d += 0.15
        if t > 1 and k < len(cadena) - 1:
            d += 0.15
        if d < mejor:
            mejor, k_m, t_m, L_m = d, k, t, L
    w = {}
    x = t_m * L_m
    m = min(mezcla_m, 0.45 * L_m)
    if k_m < len(cadena) - 1 and x > L_m - m:
        f = 0.5 * suave(0.0, 1.0, (x - (L_m - m)) / m)
        w[cadena[k_m + 1]] = f
        w[cadena[k_m]] = 1 - f
    elif k_m > 0 and x < m:
        f = 0.5 * (1 - suave(0.0, 1.0, x / m))
        w[cadena[k_m - 1]] = f
        w[cadena[k_m]] = 1 - f
    else:
        w[cadena[k_m]] = 1.0
    return w


def mezclar_pesos(a, b, t):
    w = {}
    for k, v in a.items():
        w[k] = w.get(k, 0) + v * (1 - t)
    for k, v in b.items():
        w[k] = w.get(k, 0) + v * t
    return {k: v for k, v in w.items() if v > 1e-4}


TRONCO = ["pelvis", "columna_1", "columna_2", "columna_3", "pecho", "cuello_1", "cuello_2", "cabeza"]


def pesos_tronco(p):
    w = pesos_cadena(p, TRONCO, 0.45)
    for l, s in (("_i", 1), ("_d", -1)):                 # el hombro: lo de fuera del pecho sigue al hueso del hombro
        f = suave(1.15, 1.9, s * p.x) * suave(7.6, 8.2, p.z)
        if f > 0:
            w = mezclar_pesos(w, {"hombro" + l: 1.0}, 0.85 * f)
        g = suave(0.7, 1.35, s * p.x) * (1 - suave(4.9, 5.6, p.z))   # la cadera: lo de abajo y fuera, al muslo
        if g > 0:
            w = mezclar_pesos(w, {"muslo" + l: 1.0}, 0.7 * g)
    return w


# ---------------------------------------------------------------- constructor de mallas

class Malla:
    def __init__(self):
        self.v, self.col, self.uv, self.pesos, self.caras, self.mats = [], [], [], [], [], []
        self.etq = []
        self.etiqueta = "cuerpo"

    def vert(self, p, c, uv, pesos):
        p = estirar(p)
        self.v.append(Vector(p))
        self.col.append(tuple(c) + ((0.0,) if len(c) == 3 else ()))
        self.uv.append(tuple(uv))
        self.pesos.append(dict(pesos))
        return len(self.v) - 1

    def cara(self, idx, mat=MADERA):
        if len(set(idx)) < 3:
            return
        self.caras.append(tuple(idx))
        self.mats.append(mat)
        self.etq.append(self.etiqueta)

    def triangulos(self):
        return sum(len(f) - 2 for f in self.caras)


def marcos(pts, ref=None):
    """Marcos por transporte paralelo a lo largo de una polilínea: (tangente, normal, binormal) en cada punto."""
    n = len(pts)
    T = []
    for i in range(n):
        a = pts[max(i - 1, 0)]
        b = pts[min(i + 1, n - 1)]
        t = (b - a)
        T.append(t.normalized() if t.length > 1e-9 else Vector((0, 0, 1)))
    r = Vector(ref) if ref is not None else Vector((0, -1, 0))
    if abs(r.normalized().dot(T[0])) > 0.95:
        r = Vector((1, 0, 0)) if abs(T[0].x) < 0.9 else Vector((0, 1, 0))
    N = (r - T[0] * r.dot(T[0])).normalized()
    out = []
    for i in range(n):
        if i > 0:
            ax = T[i - 1].cross(T[i])
            if ax.length > 1e-9:
                ang = T[i - 1].angle(T[i])
                N = Matrix.Rotation(ang, 3, ax.normalized()) @ N
            N = (N - T[i] * N.dot(T[i])).normalized()
        out.append((T[i], N, T[i].cross(N)))
    return out


def remuestrear(pts, paso):
    """Polilínea suave (Catmull-Rom) por los puntos dados, con un punto cada «paso» metros (al menos 2 tramos)."""
    pts = [Vector(p) for p in pts]
    if len(pts) == 2:
        pts = [pts[0], pts[0].lerp(pts[1], 0.5), pts[1]]
    fino = []
    for i in range(len(pts) - 1):
        p0, p1, p2, p3 = pts[max(i - 1, 0)], pts[i], pts[i + 1], pts[min(i + 2, len(pts) - 1)]
        for k in range(12):
            t = k / 12
            fino.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t +
                               (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3))
    fino.append(pts[-1])
    largos = [0.0]
    for a, b in zip(fino[:-1], fino[1:]):
        largos.append(largos[-1] + (b - a).length)
    total = largos[-1]
    n = max(2, int(math.ceil(total / paso)))
    out, j = [], 0
    for k in range(n + 1):
        s = total * k / n
        while j < len(largos) - 2 and largos[j + 1] < s:
            j += 1
        f = (s - largos[j]) / max(largos[j + 1] - largos[j], 1e-9)
        out.append(fino[j].lerp(fino[j + 1], f))
    return out, total


def ruido_anillo(a, s, semilla, rug):
    """Relieve de corteza: crestas que se enroscan a lo largo (fibras) y nudos suaves."""
    return 1.0 + rug * (0.55 * math.sin(3 * a + s * 1.9 + semilla) + 0.3 * math.sin(7 * a - s * 3.1 + semilla * 1.7) +
                        0.15 * math.sin(13 * a + s * 5.3 + semilla * 0.3))


def tubo(M, pts, radios, lados, pesos_fn, color_fn, mat=MADERA, punta=True, tapa_ini=False, rug=0.1, semilla=0.0,
         uv_esc=2.2, achatado=(1.0, 1.0), ref=None, giro=0.0, paso=None, vena=0.0, pesos_fijos=None):
    """Un tubo por una polilínea. radios: función de f (0..1 a lo largo) o lista. color_fn(p, n, f) → rgba (sRGB; a = vena
    turquesa). pesos_fn(c, f) → dict (por anillo) o pesos_fijos (un dict para todo). Devuelve los centros."""
    if paso is not None:
        pts, total = remuestrear(pts, paso)
    else:
        pts = [Vector(p) for p in pts]
        total = sum((b - a).length for a, b in zip(pts[:-1], pts[1:]))
    F = marcos(pts, ref)
    n = len(pts)
    rf = radios if callable(radios) else (lambda f: radios[0] + (radios[1] - radios[0]) * f)
    r_med = rf(0.3)
    ntu = max(1, round(2 * math.pi * r_med / uv_esc))
    anillos = []
    acum = 0.0
    for i in range(n):
        if i > 0:
            acum += (pts[i] - pts[i - 1]).length
        f = acum / max(total, 1e-9)
        T, N, B = F[i]
        r = rf(f)
        if punta and i == n - 1:
            r = 0.0
        w = pesos_fijos if pesos_fijos is not None else pesos_fn(pts[i], f)
        fila = []
        for j in range(lados + 1):
            a = 2 * math.pi * j / lados + giro * f
            rr = r * ruido_anillo(a, acum, semilla, rug)
            d = N * math.cos(a) * achatado[0] + B * math.sin(a) * achatado[1]
            p = pts[i] + d * rr
            c = color_fn(p, d.normalized(), f)
            fila.append(M.vert(p, c, (ntu * j / lados, acum / uv_esc), w))
        anillos.append(fila)
    for i in range(n - 1):
        for j in range(lados):
            a, b, c, d = anillos[i][j], anillos[i][j + 1], anillos[i + 1][j + 1], anillos[i + 1][j]
            M.cara((a, b, c, d), mat)
    if tapa_ini:
        w = pesos_fijos if pesos_fijos is not None else pesos_fn(pts[0], 0.0)
        cc = M.vert(pts[0] - F[0][0] * rf(0.0) * 0.3, color_fn(pts[0], -F[0][0], 0.0), (0.5, 0.0), w)
        for j in range(lados):
            M.cara((cc, anillos[0][j + 1], anillos[0][j]), mat)
    return pts


# ---------------------------------------------------------------- color

_RNG_COLOR = np.random.default_rng(7)


def ruido3(p, k=1.0, s=0.0):
    return 0.5 + 0.5 * math.sin(p.x * 1.7 * k + s) * math.sin(p.y * 2.3 * k + 1.3 + s) * math.sin(p.z * 1.9 * k + 0.7 + s * 0.5)


def color_corteza(base=MADERA_C, musgo=0.55, vena=0.0, claro=0.0, oscuro=0.0):
    """Color de corteza con musgo en lo que mira arriba (y algo de ruido) y vetas turquesa donde «vena» > 0."""
    def f(p, n, t):
        c = base
        r = ruido3(p, 1.3, 2.0)
        c = mezcla(c, MADERA_CLARA, claro * (0.4 + 0.6 * r))
        c = mezcla(c, MADERA_OSC, oscuro)
        m = musgo * suave(0.15, 0.7, n.z) * suave(0.35, 0.65, ruido3(p, 2.1, 5.0) * 0.6 + 0.4 * r)
        c = mezcla(c, mezcla(MUSGO_OSC, MUSGO, r), m)
        return c + (vena * (1 - m),)
    return f


def color_plano(c, a=0.0):
    return lambda p, n, t: tuple(c) + (a,)


# ---------------------------------------------------------------- piezas del cuerpo

def eje_de(cadena, desde=0.0, hasta=1.0, extra_ini=None, extra_fin=None):
    pts = []
    if extra_ini is not None:
        pts.append(Vector(extra_ini))
    for n in cadena:
        pts.append(cabeza_h(n))
    pts.append(cola_h(cadena[-1]))
    if extra_fin is not None:
        pts.append(Vector(extra_fin))
    return pts


def hebras(M, eje, radio_eje, n, lados, pesos_fn, rng, color, vueltas=(0.6, 1.4), r_hebra=(0.12, 0.26), fuera=1.0,
           paso=0.35, desde=0.0, hasta=1.0, rug=0.15, vena=0.0):
    """Raíces que se enroscan alrededor de un eje (el haz de raíces de un miembro)."""
    pts, total = remuestrear(eje, paso)
    F = marcos(pts)
    cuantos = len(pts)
    for k in range(n):
        th0 = 2 * math.pi * k / n + rng.uniform(-0.3, 0.3)
        vu = rng.uniform(*vueltas) * (1 if rng.random() < 0.6 else -1)
        rh = rng.uniform(*r_hebra)
        i0 = int(desde * (cuantos - 1) + rng.uniform(0, 0.08) * cuantos)
        i1 = int(hasta * (cuantos - 1) - rng.uniform(0, 0.1) * cuantos)
        if i1 - i0 < 3:
            continue
        camino = []
        for i in range(i0, i1 + 1):
            f = i / (cuantos - 1)
            T, N, B = F[i]
            th = th0 + vu * 2 * math.pi * f
            R = radio_eje(f) * fuera
            camino.append(pts[i] + (N * math.cos(th) + B * math.sin(th)) * R)
        rr = lambda f, rh=rh: rh * (0.75 + 0.5 * math.sin(math.pi * min(1.0, f * 1.2))) * (1 - 0.6 * f ** 3)
        tubo(M, camino, rr, lados, pesos_fn, color, rug=rug, semilla=rng.uniform(0, 10), uv_esc=1.6, paso=None, vena=vena)


TRONCO_TABLA = [(0.0, 1.0), (0.12, 1.12), (0.35, 1.18), (0.55, 1.4), (0.68, 1.48), (0.78, 1.25), (0.88, 0.88), (1.0, 0.76)]
TRONCO_ACH = (1.08, 0.92)                  # (12/11, tras la hoja frente a la lámina: más estrecho)


def radio_tronco(f):
    for (a, ra), (b, rb) in zip(TRONCO_TABLA[:-1], TRONCO_TABLA[1:]):
        if a <= f <= b:
            return ra + (rb - ra) * suave(a, b, f)
    return TRONCO_TABLA[-1][1]


def eje_tronco():
    return [V(0, 0.25, 4.55)] + eje_de(TRONCO[:-1]) + [V(0, -1.22, 9.98)]


_SUP = None


def frente_tronco(x, z, extra=0.0):
    """La y de la cara delantera del tronco en (x, z) (con su haz de raíces): para pegar cosas al pecho."""
    global _SUP
    if _SUP is None:
        pts, total = remuestrear(eje_tronco(), 0.05)
        acum, lista = 0.0, []
        for i, p in enumerate(pts):
            if i:
                acum += (p - pts[i - 1]).length
            lista.append((p, radio_tronco(acum / total)))
        _SUP = lista
    p, r = min(_SUP, key=lambda e: abs(e[0].z - z))
    rx, ry = r * TRONCO_ACH[0] * 1.06, r * TRONCO_ACH[1] * 1.06 + extra
    return p.y - ry * math.sqrt(max(0.0, 1.0 - (x / rx) ** 2))


def crear_tronco(M, rng):
    M.etiqueta = "tronco"
    eje = eje_tronco()
    lados = Q["lados"] + 4
    tubo(M, eje, radio_tronco, lados, lambda c, f: pesos_tronco(c), color_corteza(MADERA_C, musgo=0.85, oscuro=0.3),
         rug=0.1, semilla=1.0, achatado=TRONCO_ACH, paso=Q["paso"], ref=(0, -1, 0), punta=False, tapa_ini=True)
    # haz de raíces sobre el tronco (se enroscan del vientre a los hombros; la lámina no deja ver tronco liso)
    n = max(4, int(round(15 * Q["hebras"])))
    hebras(M, eje, lambda f: radio_tronco(f) * 1.06, n, Q["hebra_lados"], lambda c, f: pesos_tronco(c), rng,
           color_corteza(MADERA_C, musgo=0.75, claro=0.35, vena=0.25), vueltas=(0.2, 0.6), r_hebra=(0.17, 0.32),
           paso=Q["paso"], desde=0.0, hasta=0.86)


def crear_cuello_cabeza(M, rng):
    M.etiqueta = "cabeza"
    pcab = {"cabeza": 1.0}
    # la cabeza-tronco: de encima de la boca a lo alto (la boca y la garganta van debajo, por delante del cuello)
    eje = [V(0, -1.2, 10.22), V(0, -1.27, 10.8), V(0, -1.3, 11.42)]
    rad = lambda f: 0.96 + 0.06 * math.sin(math.pi * min(1, f * 1.3)) - 0.22 * suave(0.72, 1.0, f)
    tubo(M, eje, rad, Q["lados"] + 2, None, color_corteza(MADERA_C, musgo=0.9, oscuro=0.12), pesos_fijos=pcab,
         rug=0.12, semilla=3.0, achatado=(0.95, 1.0), paso=Q["paso"] * 0.7, punta=False, tapa_ini=True)
    # la placa de corteza en punta de la frente (sobre el ojo), con dos espirales talladas
    M.etiqueta = "frente"
    placa = [V(0, -2.36, 11.9), V(0.58, -2.25, 11.15), V(0.64, -2.2, 10.99), V(0.31, -2.4, 10.99), V(0.0, -2.47, 11.04),
             V(-0.31, -2.4, 10.99), V(-0.64, -2.2, 10.99), V(-0.58, -2.25, 11.15)]
    c0 = sum(placa, Vector()) / len(placa)
    fr, at = [], []
    for p in placa:
        fr.append(M.vert(p, MADERA_CLARA + (0.0,), (p.x, p.z), pcab))
        at.append(M.vert(p + V(0, 0.4, 0), MADERA_C + (0.0,), (p.x, p.z), pcab))
    cf = M.vert(c0 + V(0, -0.08, 0), PETREA + (0.0,), (c0.x, c0.z), pcab)
    for i in range(len(placa)):
        j = (i + 1) % len(placa)
        M.cara((cf, fr[j], fr[i]))
        M.cara((fr[i], fr[j], at[j], at[i]))
    for s in (1, -1):                               # espirales talladas (oscuras, con un hilo turquesa)
        cen = V(0.26 * s, -2.44, 11.24)
        sp = [cen + V(math.cos(t) * 0.022 * t * s, -0.015 * (1 - t / 8), math.sin(t) * 0.022 * t) for t in np.linspace(0.6, 8.0, 16)]
        tubo(M, sp, (0.022, 0.02), 4, None, color_plano(MADERA_OSC, 0.5), pesos_fijos=pcab, rug=0.0, punta=False)
    # cejas: dos nudos de corteza a los lados del ojo
    for s in (1, -1):
        tubo(M, [V(0.66 * s, -1.95, 10.98), V(0.46 * s, -2.22, 10.9), V(0.22 * s, -2.32, 10.95)], lambda f: 0.15 * (1 - 0.5 * f),
             6, None, color_corteza(MADERA_C, musgo=0.4, claro=0.3), pesos_fijos=pcab, rug=0.15, paso=0.1)
    # la cuenca del ojo: un anillo de corteza oscura alrededor
    M.etiqueta = "ojo"
    oc = V(0, -2.12, 10.74)
    anillo = [oc + V(math.cos(t) * 0.46, -0.04 - 0.04 * math.sin(t), math.sin(t) * 0.4) for t in np.linspace(0, 2 * math.pi, 17)]
    tubo(M, anillo, (0.12, 0.12), 6, None, color_corteza(MADERA_OSC, musgo=0.0, claro=0.25), pesos_fijos=pcab, rug=0.12,
         punta=False)
    # el ojo (hueso «ojo»): una esfera turquesa con el centro casi blanco
    esfera(M, oc + V(0, 0.08, 0), 0.36, Q["lados"] + 2, lambda p, n: ojo_color(p, n, oc), {"ojo": 1.0}, BRILLO,
           escala=(1.0, 0.72, 0.9))
    # la boca, bajo el ojo: la garganta negra (cabeza), el labio de arriba con colmillos y la mandíbula (hueso propio)
    M.etiqueta = "boca"
    esfera(M, V(0, -1.62, 9.98), 0.66, 10, lambda p, n: BOCA + (0.0,), pcab, MADERA, escala=(1.0, 0.9, 0.62))
    arco = [V(math.sin(t) * 0.98, -1.27 - math.cos(t) * 0.98, 10.36 - 0.05 * math.cos(t)) for t in np.linspace(-1.3, 1.3, 11)]
    tubo(M, arco, lambda f: 0.12 + 0.08 * math.sin(math.pi * f), 7, None, color_corteza(MADERA_C, musgo=0.3, claro=0.2), pesos_fijos=pcab, rug=0.2,
         punta=False, paso=0.15)
    for k, t in enumerate(np.linspace(-1.05, 1.05, 7)):
        base = V(math.sin(t) * 0.93, -1.27 - math.cos(t) * 0.93, 10.28)
        largo = 0.44 if k in (1, 5) else 0.3
        garra(M, base, V(0, -0.15, -1.0), V(0, -1, 0), largo, 0.08, 5, pcab, curva=0.15, color=GARRA)
    pm = {"mandibula": 1.0}
    herr = [V(math.sin(t) * 0.92, -1.25 - math.cos(t) * 0.9, 9.6 + 0.08 * abs(t)) for t in np.linspace(-1.45, 1.45, 11)]
    tubo(M, herr, lambda f: 0.22 + 0.07 * math.sin(math.pi * f), 7, None, color_corteza(MADERA_C, musgo=0.3, claro=0.15),
         pesos_fijos=pm, rug=0.12, punta=False, paso=0.12)
    for k, t in enumerate(np.linspace(-1.0, 1.0, 6)):
        base = V(math.sin(t) * 0.86, -1.25 - math.cos(t) * 0.84, 9.76)
        garra(M, base, V(0, -0.1, 1.0), V(0, -1, 0), 0.32 if k in (1, 4) else 0.22, 0.07, 5, pm, curva=-0.1, color=GARRA)
    for k in range(int(round(6 * Q["musgo"])) + 2):        # barba de raíces y musgo bajo la barbilla
        t = rng.uniform(-1.2, 1.2)
        base = V(math.sin(t) * 0.9, -1.25 - math.cos(t) * 0.86, 9.5)
        largo = rng.uniform(0.6, 1.6)
        pts = [base + V(rng.uniform(-0.1, 0.1), rng.uniform(-0.15, 0.05), -largo * u) for u in (0, 0.33, 0.66, 1.0)]
        tubo(M, pts, (0.07, 0.01), 4, None, color_plano(mezcla(MUSGO_OSC, MADERA_C, rng.random() * 0.6)), pesos_fijos=pm,
             rug=0.2, semilla=k)




def ojo_color(p, n, oc):
    d = (p - oc)
    r = math.hypot(d.x, d.z) / 0.36
    c = mezcla(BLANCO_OJO, TURQUESA, suave(0.12, 0.45, r))
    c = mezcla(c, TURQUESA_HONDO, suave(0.6, 1.0, r))
    return c + (1.0,)


def esfera(M, centro, radio, lados, color_fn, pesos, mat, escala=(1, 1, 1), anillos=None):
    an = anillos or max(4, lados // 2)
    filas = []
    for i in range(an + 1):
        th = math.pi * i / an
        fila = []
        for j in range(lados + 1):
            ph = 2 * math.pi * j / lados
            n = V(math.sin(th) * math.cos(ph), -math.cos(th), math.sin(th) * math.sin(ph))   # el polo mira a −Y (fuera)
            p = centro + V(n.x * escala[0], n.y * escala[1], n.z * escala[2]) * radio
            fila.append(M.vert(p, color_fn(p, n), (j / lados, i / an), pesos))
        filas.append(fila)
    for i in range(an):
        for j in range(lados):
            M.cara((filas[i][j], filas[i + 1][j], filas[i + 1][j + 1], filas[i][j + 1]), mat)


def garra(M, base, dir_, ref, largo, grueso, lados, pesos, curva=0.3, color=GARRA, mat=MADERA):
    """Garra o diente curvo de madera clara: un cono que se curva hacia «ref» (curva > 0) o al revés."""
    d = Vector(dir_).normalized()
    r = Vector(ref).normalized()
    r = (r - d * r.dot(d)).normalized() if abs(r.dot(d)) < 0.99 else Vector((1, 0, 0))
    pts = []
    for k in range(6):
        t = k / 5
        pts.append(base + d * largo * t + r * largo * curva * t * t)
    tubo(M, pts, lambda f: grueso * (1 - 0.92 * f ** 0.9), lados, None,
         lambda p, n, f: mezcla(color, GARRA_PUNTA, 0.6 * f) + (0.0,) if f > 0.0 else color + (0.0,),
         pesos_fijos=pesos, rug=0.02, punta=True, mat=mat)


NUCLEO_Z = 7.95


def centro_nucleo():
    return V(0, frente_tronco(0.0, NUCLEO_Z) - 0.06, NUCLEO_Z)


def crear_nucleo(M, rng):
    """El núcleo turquesa del pecho (hueso «nucleo»), engastado en la cara del pecho, su marco de raíces en forma de
    corazón y las vetas turquesa que irradian por el pecho."""
    M.etiqueta = "nucleo"
    i0 = len(M.v)
    ligero = Q["lados"] < 9                      # (perfil bajo: menos lados y menos vetas)
    nc = centro_nucleo()
    esfera(M, nc, 0.55, Q["lados"] + 4, lambda p, n: nucleo_color(p, n, nc), {"nucleo": 1.0}, BRILLO, escala=(1.0, 0.75, 1.1))
    pw = lambda c, f: pesos_cadena(c, ["columna_3", "pecho"], 0.3)
    for esc, grosor, col in ((1.0, 0.15, MADERA_C), (1.35, 0.2, MADERA_OSC)):
        corazon = []
        for t in np.linspace(0, 2 * math.pi, 17 if ligero else 29):
            x = 16 * math.sin(t) ** 3
            z = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
            px, pz = x * 0.052 * esc, NUCLEO_Z + z * 0.052 * esc + 0.1
            corazon.append(V(px, frente_tronco(px, pz) - 0.08 * esc, pz))
        tubo(M, corazon, (grosor, grosor), 4 if ligero else 6, pw, color_corteza(col, musgo=0.5, claro=0.35, vena=0.3), rug=0.18,
             semilla=esc * 4, punta=False)
    # vetas turquesa que salen del corazón y corren pegadas al pecho
    nv = 6 if ligero else 11
    for k in range(nv):
        a = 2 * math.pi * k / nv + rng.uniform(-0.2, 0.2)
        x, z = math.cos(a) * 0.75, NUCLEO_Z + math.sin(a) * 0.8
        camino = []
        d = V(math.cos(a), 0, math.sin(a))
        for s in range(6):
            camino.append(V(x, frente_tronco(x, z) + 0.02, z))
            x += d.x * 0.28 + rng.uniform(-0.07, 0.07)
            z += d.z * 0.28 + rng.uniform(-0.07, 0.07)
        tubo(M, camino, (0.05, 0.015), 3 if ligero else 4, pw, color_plano(TURQUESA, 1.0), rug=0.0, mat=BRILLO)
    for i in range(i0, len(M.v)):                # la marca del núcleo (UV.x ≥ 5) para humbaba_brillo.gdshader
        M.uv[i] = (M.uv[i][0] + 10.0, M.uv[i][1])


def nucleo_color(p, n, nc):
    d = (p - nc)
    r = math.hypot(d.x, d.z) / 0.52
    c = mezcla(BLANCO_OJO, TURQUESA, suave(0.0, 0.55, r))
    c = mezcla(c, TURQUESA_HONDO, suave(0.65, 1.0, r) * 0.7)
    return c + (1.0,)


def crear_brazo(M, rng, l, s, grueso):
    M.etiqueta = "brazo" + l
    cadena = ["hombro" + l, "brazo" + l, "antebrazo" + l, "muneca" + l, "palma" + l]
    pw = lambda c, f: mezclar_pesos(pesos_cadena(c, cadena, 0.45), {"pecho": 1.0}, 0.7 * (1 - suave(0.0, 0.12, f)))
    eje = [cabeza_h("hombro" + l) + V(-0.3 * s, 0, -0.1), cola_h("hombro" + l), cola_h("brazo" + l),
           cola_h("antebrazo" + l), cola_h("muneca" + l) + V(0, 0, -0.05)]
    def rad(f):     # hombro ancho, bíceps, codo, antebrazo grueso (de raíces), muñeca
        tabla = [(0.0, 0.85), (0.18, 0.8), (0.35, 0.62), (0.52, 0.55), (0.66, 0.64), (0.88, 0.46), (1.0, 0.33)]
        for (a, ra), (b, rb) in zip(tabla[:-1], tabla[1:]):
            if a <= f <= b:
                return (ra + (rb - ra) * suave(a, b, f)) * grueso
        return tabla[-1][1] * grueso
    tubo(M, eje, rad, Q["lados"], pw, color_corteza(MADERA_C, musgo=0.7, oscuro=0.3), rug=0.1, semilla=5 + s,
         paso=Q["paso"], punta=False, tapa_ini=False, ref=(0, -1, 0))
    n = max(2, int(round(7 * Q["hebras"])))
    hebras(M, eje, lambda f: rad(f) * 0.98, n, Q["hebra_lados"], pw, rng,
           color_corteza(MADERA_C, musgo=0.65, claro=0.4, vena=0.2), vueltas=(0.5, 1.3), r_hebra=(0.13, 0.24) if grueso > 1 else (0.11, 0.2),
           paso=Q["paso"], desde=0.05, hasta=0.97)
    # la mano: palma (un bloque de raíces) y dedos con garras
    M.etiqueta = "mano" + l
    pp = {"palma" + l: 1.0}
    a, b = POS["palma" + l]
    tubo(M, [a + (a - b) * 0.15, a, b, b + (b - a) * 0.1], lambda f: (0.42 + 0.06 * math.sin(math.pi * f)) * grueso, Q["dedo_lados"] + 2,
         None, color_corteza(MADERA_C, musgo=0.4, claro=0.25), pesos_fijos=pp, rug=0.14, semilla=s * 2, achatado=(0.62, 1.15),
         punta=False, tapa_ini=True)
    for dedo in ("dedo1", "dedo2", "dedo3", "pulgar"):
        da, db = dedo + "_a" + l, dedo + "_b" + l
        p0, p1, p2 = cabeza_h(da), cola_h(da), cola_h(db)
        g = (0.17 if dedo != "pulgar" else 0.2) * grueso
        pd = lambda c, f, da=da, db=db: pesos_cadena(c, [da, db], 0.12)
        tubo(M, [p0 + (p0 - p1) * 0.35, p0, p1, p2], lambda f, g=g: g * (1.0 + 0.18 * math.sin(math.pi * f * 2) - 0.25 * f),
             Q["dedo_lados"], pd, color_corteza(MADERA_C, musgo=0.2, claro=0.3), rug=0.12, semilla=hash(da) % 7, punta=False,
             paso=0.12)
        # la garra: sale de la punta del dedo y se curva hacia la palma (hacia el cuerpo y adelante)
        d = (p2 - p1).normalized()
        largo = (1.05 if dedo != "pulgar" else 0.7) * grueso * (1.15 if l == "_i" else 0.9)
        garra(M, p2 - d * 0.05, d, V(-s, -0.6, 0), largo, g * 0.85, Q["garra_lados"], {db: 1.0}, curva=0.32)


def casquete(M, c, eje, radio, ang, pesos, color_fn, n_u=10, n_v=5, achatado=1.0):
    """Un casquete de esfera (placa curva) centrado en «c», mirando a «eje», de «ang» grados de abertura, con canto."""
    n = Vector(eje).normalized()
    e1 = n.cross(V(0, 0, 1)) if abs(n.z) < 0.95 else n.cross(V(1, 0, 0))
    e1.normalize()
    e2 = n.cross(e1).normalized()
    filas = []
    crudo = {}                                   # (las posiciones sin estirar: para el canto, que pasa otra vez por vert)
    for i in range(n_v + 1):
        th = math.radians(ang) * i / n_v
        fila = []
        for j in range(n_u + 1):
            ph = 2 * math.pi * j / n_u
            d = n * math.cos(th) + (e1 * math.cos(ph) + e2 * math.sin(ph) * achatado) * math.sin(th)
            p = c + d * radio
            fila.append(M.vert(p, color_fn(p, d, i / n_v), (j / n_u * 2, i / n_v), pesos))
            crudo[fila[-1]] = p
        filas.append(fila)
    for i in range(n_v):
        for j in range(n_u):
            a, b, cc, d = filas[i][j], filas[i][j + 1], filas[i + 1][j + 1], filas[i + 1][j]
            q = [M.v[x] for x in (a, b, cc)]
            nrm = (q[1] - q[0]).cross(q[2] - q[0])
            cara = (a, b, cc, d) if nrm.dot((q[0] + q[2]) * 0.5 - estirar(c)) > 0 else (a, d, cc, b)
            M.cara(cara)
    borde = [crudo[filas[n_v][j]] for j in range(n_u + 1)]
    tubo(M, borde, (radio * 0.07, radio * 0.07), 5, None, color_corteza(MADERA_OSC, musgo=0.0, claro=0.25), pesos_fijos=pesos,
         rug=0.1, punta=False)


def espiral(M, cen, nrm, radio, pesos, vueltas=2.5, grosor=0.04, color=MADERA_OSC, vena=0.6):
    nrm = Vector(nrm).normalized()
    e1 = nrm.cross(V(0, 0, 1)) if abs(nrm.z) < 0.95 else nrm.cross(V(1, 0, 0))
    e1.normalize()
    e2 = nrm.cross(e1).normalized()
    tmax = vueltas * 2 * math.pi
    sp = [cen + nrm * 0.02 + (e1 * math.cos(t) + e2 * math.sin(t)) * radio * t / tmax for t in np.linspace(0.5, tmax, int(vueltas * 10))]
    tubo(M, sp, (grosor, grosor * 0.8), 4, None, color_plano(color, vena), pesos_fijos=pesos, rug=0.0, punta=False)


def crear_hombreras(M, rng):
    """ARMADURA (en la fase 3 se rompe): hombreras de corteza petrificada con espiral tallada, brazales de corteza en
    los antebrazos (como el detalle de la lámina) y la gorguera de placas sobre el pecho."""
    col = lambda p, d, f: mezcla(mezcla(MADERA_CLARA, PETREA, ruido3(p, 2.0)), MUSGO, 0.6 * suave(0.6, 0.9, d.z) * ruido3(p, 3.0, 2.0)) + (0.12,)
    for l, s in (("_i", 1), ("_d", -1)):
        M.etiqueta = "hombrera" + l
        c = cola_h("hombro" + l) + V(-0.1 * s, 0.0, 0.12)    # (por encima del tubo del hombro: si no, solo asoma el canto)
        eje = V(0.55 * s, -0.12, 0.85)
        pw = {"hombro" + l: 0.8, "brazo" + l: 0.2}
        grande = 0.98 if l == "_i" else 0.88
        casquete(M, c, eje, 1.28 * grande, 62, pw, col, n_u=11, n_v=5, achatado=0.95)
        n = eje.normalized()
        espiral(M, c + n.lerp(V(0.2 * s, -1, 0.2), 0.42).normalized() * 1.28 * grande, n.lerp(V(0.2 * s, -1, 0.2), 0.42),
                0.32, pw, vueltas=2.6, grosor=0.04)
        # brazal: un medio tubo de corteza por fuera del antebrazo
        M.etiqueta = "brazal" + l
        a, b = POS["antebrazo" + l]
        pts = [a.lerp(b, 0.25), a.lerp(b, 0.55), a.lerp(b, 0.85)]
        cad = ["antebrazo" + l]
        rr = 0.62 * (1.0 if l == "_i" else 0.86)
        parche(M, pts, rr, -0.25 * math.pi, 0.95 * math.pi, {"antebrazo" + l: 1.0}, col, s)
        espiral(M, a.lerp(b, 0.55) + V(rr * s, -0.15, 0), V(s, -0.35, 0), 0.2, {"antebrazo" + l: 1.0}, vueltas=2.0, grosor=0.03)


def parche(M, pts, radio, a0, a1, pesos, color_fn, s, lados=8):
    """Medio tubo (placa curva) alrededor de un eje, del ángulo a0 al a1 (0 = afuera), con canto."""
    pts = [Vector(p) for p in pts]
    F = marcos(pts, ref=(s, 0, 0))
    filas = []
    crudo = {}
    for i, p in enumerate(pts):
        T, N, B = F[i]
        fila = []
        for j in range(lados + 1):
            a = a0 + (a1 - a0) * j / lados
            d = N * math.cos(a) + B * math.sin(a)
            q = p + d * radio * (1.0 + 0.04 * math.sin(3 * a + i))
            fila.append(M.vert(q, color_fn(q, d, i / max(1, len(pts) - 1)), (j / lados, i / 2), pesos))
            crudo[fila[-1]] = q
        filas.append(fila)
    for i in range(len(pts) - 1):
        for j in range(lados):
            a, b, c, d = filas[i][j], filas[i][j + 1], filas[i + 1][j + 1], filas[i + 1][j]
            q = [M.v[x] for x in (a, b, c)]
            nrm = (q[1] - q[0]).cross(q[2] - q[0])
            M.cara((a, b, c, d) if nrm.dot(q[0] - estirar(pts[i])) > 0 else (a, d, c, b))
    for borde in ([crudo[f[0]] for f in filas], [crudo[f[-1]] for f in filas], [crudo[x] for x in filas[0]], [crudo[x] for x in filas[-1]]):
        tubo(M, borde, (0.06, 0.06), 4, None, color_corteza(MADERA_OSC, musgo=0.0, claro=0.25), pesos_fijos=pesos, rug=0.05,
             punta=False)


def crear_pierna(M, rng, l, s):
    M.etiqueta = "pierna" + l
    cadena = ["muslo" + l, "pierna" + l, "tobillo" + l]
    pw = lambda c, f: mezclar_pesos(pesos_cadena(c, cadena, 0.45), {"pelvis": 1.0}, 0.6 * (1 - suave(0.0, 0.12, f)))
    eje = [cabeza_h("muslo" + l) + V(-0.2 * s, 0, 0.35), cola_h("muslo" + l), cola_h("pierna" + l), cola_h("tobillo" + l)]
    def rad(f):
        tabla = [(0.0, 0.62), (0.12, 0.92), (0.25, 0.85), (0.45, 0.7), (0.6, 0.72), (0.85, 0.66), (1.0, 0.7)]
        for (a, ra), (b, rb) in zip(tabla[:-1], tabla[1:]):
            if a <= f <= b:
                return ra + (rb - ra) * suave(a, b, f)
        return tabla[-1][1]
    tubo(M, eje, rad, Q["lados"], pw, color_corteza(MADERA_C, musgo=0.35, oscuro=0.35), rug=0.12, semilla=11 + s,
         paso=Q["paso"], punta=False)
    n = max(3, int(round(8 * Q["hebras"])))
    hebras(M, eje, lambda f: rad(f) * 1.0, n, Q["hebra_lados"], pw, rng, color_corteza(MADERA_C, musgo=0.4, claro=0.4, vena=0.15),
           vueltas=(0.4, 1.1), r_hebra=(0.15, 0.28), paso=Q["paso"], desde=0.02, hasta=1.0)
    # el pie: raíces que se abren sobre el suelo (las de delante siguen a «pie» y «punta»; las de atrás, al tobillo)
    M.etiqueta = "pie" + l
    tob = cola_h("tobillo" + l) + V(0, 0.1, 0.35)
    cad_pie = ["tobillo" + l, "pie" + l, "punta" + l]
    n_raices = max(4, int(round(7 * (0.5 + 0.5 * Q["hebras"]))))
    for k in range(n_raices):
        a = math.radians(-150 + 300 * k / (n_raices - 1)) if k < n_raices - 1 else math.radians(90)
        a += rng.uniform(-0.12, 0.12)
        d = V(math.sin(a) * s if abs(math.sin(a)) > 0 else 0, -math.cos(a), 0)
        d = V(math.sin(a) * (1 if s > 0 else -1), -math.cos(a), 0)
        largo = rng.uniform(1.4, 2.2) * (1.15 if abs(a) < 0.8 else 1.0)
        pts = [tob, tob + d * 0.4 + V(0, 0, -0.45), tob + d * largo * 0.6 + V(0, 0, -1.08), tob + d * largo + V(0, 0, -1.2),
               tob + d * largo * 1.25 + V(0, 0, -1.25)]
        delante = d.y < -0.3
        pfn = (lambda c, f: pesos_cadena(c, cad_pie, 0.3)) if delante else (lambda c, f: {"tobillo" + l: 1.0})
        tubo(M, pts, lambda f: 0.3 * (1 - 0.85 * f) + 0.03, Q["hebra_lados"] + 1, pfn,
             color_corteza(MADERA_C, musgo=0.5, claro=0.3), rug=0.18, semilla=k * 1.3 + s, paso=Q["paso"] * 0.8)
    # garras de los pies (tres, delante)
    for k, dx in enumerate((-0.42, 0.0, 0.42)):
        base = cabeza_h("punta" + l) + V(dx * s, -0.05, 0.12)
        garra(M, base, V(dx * 0.4 * s, -1.0, -0.25), V(0, 0, -1), 0.75 if k == 1 else 0.6, 0.17, Q["garra_lados"], {"punta" + l: 1.0},
              curva=0.35)


def rama(M, rng, base, d, largo, r0, prof, prof_max, pesos_fn, lados, color, puntas, hacia_arriba=0.25):
    """Rama seca que se divide (2-3 hijas); devuelve las puntas en «puntas»."""
    pts = [base]
    p = base.copy()
    dd = d.normalized()
    n = 4 if prof < prof_max else 3
    for k in range(n):
        dd = (dd + V(rng.uniform(-0.25, 0.25), rng.uniform(-0.25, 0.25), rng.uniform(-0.1, 0.2) + hacia_arriba * 0.3)).normalized()
        p = p + dd * largo / n
        pts.append(p.copy())
    tubo(M, pts, lambda f: r0 * (1 - 0.55 * f), max(3, lados - prof), pesos_fn, color, rug=0.15, semilla=rng.uniform(0, 9),
         punta=(prof >= prof_max), paso=None)
    if prof >= prof_max:
        puntas.append((pts[-1], dd))
        return
    hijas = 2 if rng.random() < 0.55 else 3
    for h in range(hijas):
        eje = dd.cross(V(0, 0, 1))
        if eje.length < 1e-3:
            eje = V(1, 0, 0)
        ang = rng.uniform(0.35, 0.75) * (1 if h % 2 == 0 else -1)
        rot = Matrix.Rotation(ang, 3, (eje.normalized() + V(0, 0, rng.uniform(-0.5, 0.5))).normalized())
        rot2 = Matrix.Rotation(rng.uniform(-1.2, 1.2), 3, dd)
        nd = rot2 @ (rot @ dd)
        inicio = pts[-1] if h == 0 else pts[-2].lerp(pts[-1], rng.uniform(0.3, 0.9))
        rama(M, rng, inicio, nd, largo * rng.uniform(0.6, 0.78), r0 * 0.55, prof + 1, prof_max, pesos_fn, lados, color, puntas,
             hacia_arriba)


def crear_corona(M, rng):
    M.etiqueta = "corona"
    puntas = []
    col = color_corteza(MADERA_C, musgo=0.35, claro=0.45, oscuro=0.1)
    for g, largo, r0 in (("c", 2.2, 0.3), ("i", 2.3, 0.27), ("d", 2.3, 0.27)):
        cad = ["corona_%s1" % g, "corona_%s2" % g]
        pw = lambda c, f, cad=cad: pesos_cadena(c, cad, 0.3)
        a, b = POS[cad[0]]
        base = a + V(0, 0, -0.25)
        rama(M, rng, base, (b - a), largo * 1.2, r0, 0, Q["rama_prof"], pw, Q["rama_lados"] + 1, col, puntas)
        # ramas menores del mismo conjunto: hacia delante, atrás y afuera (la copa ancha de la lámina)
        for k in range(3):
            d = (b - a).normalized() + V(rng.uniform(-0.8, 0.8), (-0.7, 0.7, 0.0)[k] + rng.uniform(-0.2, 0.2), 0.05)
            rama(M, rng, a.lerp(b, rng.uniform(0.2, 0.7)), d, largo * 0.7, r0 * 0.55, 1, Q["rama_prof"], pw,
                 Q["rama_lados"], col, puntas)
    # ramitas fijas alrededor de la cabeza (sin hueso propio)
    for k in range(int(round(6 * Q["hebras"])) + 2):
        a = rng.uniform(0, 2 * math.pi)
        base = V(math.cos(a) * 0.75, -1.28 + math.sin(a) * 0.7, 11.1 + rng.uniform(-0.1, 0.15))
        d = V(math.cos(a) * 0.8, math.sin(a) * 0.6, 0.9)
        rama(M, rng, base, d, rng.uniform(0.7, 1.1), 0.1, 2, Q["rama_prof"], lambda c, f: {"cabeza": 1.0}, Q["rama_lados"],
             col, puntas)
    return puntas


def amuleto(M, rng, anclaje, pesos, escala=1.0):
    """Amuleto colgante (aro con red y una pluma de madera en punta), como los de la lámina."""
    p0 = anclaje
    largo = 0.5 * escala
    cuerda = [p0, p0 + V(0, 0, -largo)]
    tubo(M, cuerda, (0.02, 0.02), 3, None, color_plano(CUERDA), pesos_fijos=pesos, rug=0.0, punta=False)
    c = p0 + V(0, 0, -largo - 0.22 * escala)
    aro = [c + V(math.cos(t) * 0.22 * escala, 0, math.sin(t) * 0.22 * escala) for t in np.linspace(0, 2 * math.pi, 13)]
    tubo(M, aro, (0.03, 0.03), 4, None, color_plano(CUERDA, 0.2), pesos_fijos=pesos, rug=0.0, punta=False)
    tubo(M, [c + V(0, 0, -0.22 * escala), c + V(0, 0, -0.6 * escala)], (0.015, 0.015), 3, None, color_plano(CUERDA),
         pesos_fijos=pesos, rug=0.0, punta=False)
    garra(M, c + V(0, 0, -0.6 * escala), V(0, 0, -1), V(0, -1, 0), 0.35 * escala, 0.06 * escala, 4, pesos, curva=0.0,
          color=MADERA_C)


def crear_colgantes(M, rng):
    """Las 5 raíces colgantes con hueso (de la cintura y la espalda) y musgo y lianas fijos por todo el cuerpo."""
    M.etiqueta = "colgantes"
    for suf, ancla, d in COLGANTES:
        cad = ["colgante%s_%s" % (suf, x) for x in "abc"]
        pw = lambda c, f, cad=cad: pesos_cadena(c, cad, 0.2)
        for k in range(Q["colgantes"]):
            off = V(rng.uniform(-0.18, 0.18), rng.uniform(-0.12, 0.12), 0)
            pts = [cabeza_h(cad[0]) + off] + [cola_h(n) + off * (1 - 0.3 * i) for i, n in enumerate(cad)]
            tubo(M, pts, lambda f: 0.14 * (1 - 0.8 * f) + 0.02, Q["hebra_lados"], pw,
                 color_corteza(MADERA_C, musgo=0.6, claro=0.2), rug=0.2, semilla=k + float(suf), paso=Q["paso"] * 0.8)
    # musgo colgante (hebras finas de verde) de lo alto de hombros, brazos, pecho y cabeza
    M.etiqueta = "musgo"
    sitios = []
    for l, s in (("_i", 1), ("_d", -1)):
        for k in range(10):
            f = rng.uniform(0.0, 1.0)
            if f < 0.3:
                p = cabeza_h("hombro" + l).lerp(cola_h("hombro" + l), 0.4 + f * 2) + V(0, rng.uniform(-0.5, 0.5), 0.55)
                hb = "hombro" + l
            elif f < 0.75:
                p = cabeza_h("brazo" + l).lerp(cola_h("brazo" + l), rng.uniform(0.0, 1.0)) + V(0.2 * s, rng.uniform(-0.5, 0.3), 0.3)
                hb = "brazo" + l
            else:
                p = cabeza_h("antebrazo" + l).lerp(cola_h("antebrazo" + l), rng.uniform(0.0, 0.8)) + V(0.15 * s, -0.3, 0.2)
                hb = "antebrazo" + l
            sitios.append((p, hb, rng.uniform(0.6, 2.2)))
    for k in range(10):
        a = rng.uniform(-1.3, 1.3)
        p = V(math.sin(a) * 1.4, -0.6 - math.cos(a) * 1.15, rng.uniform(8.0, 8.9))
        sitios.append((p, "pecho", rng.uniform(0.8, 2.6)))
    for k in range(6):
        a = rng.uniform(-1.6, 1.6)
        p = V(math.sin(a) * 0.9, -1.25 - math.cos(a) * 0.85, rng.uniform(10.4, 11.0))
        sitios.append((p, "cabeza", rng.uniform(0.5, 1.5)))
    for k in range(8):                               # la espalda encorvada, cubierta de musgo (vista de espalda de la lámina)
        a = rng.uniform(-1.2, 1.2)
        p = V(math.sin(a) * 1.5, 0.15 + math.cos(a) * 1.1, rng.uniform(7.6, 8.7))
        sitios.append((p, "pecho" if p.z > 8.15 else "columna_3", rng.uniform(0.9, 2.4)))
    n = max(6, int(round(len(sitios) * Q["musgo"])))
    sitios = sitios + [(p + V(rng.uniform(-0.3, 0.3), rng.uniform(-0.3, 0.3), 0), hb, l_ * 1.3) for (p, hb, l_) in sitios]   # (la lámina: el doble de musgo colgante)
    n = int(n * 1.8)
    for (p, hb, largo) in sitios[:: max(1, len(sitios) // n)][:n]:
        pts = [p]
        q = p.copy()
        for u in range(4):
            q = q + V(rng.uniform(-0.06, 0.06), rng.uniform(-0.06, 0.06), -largo / 4)
            pts.append(q.copy())
        col = mezcla(MUSGO_OSC, MUSGO, rng.random())
        tubo(M, pts, lambda f: 0.09 * (1 - 0.7 * f) + 0.02, 3, None, color_plano(col), pesos_fijos={hb: 1.0}, rug=0.25,
             semilla=rng.uniform(0, 5))
    # amuletos de la corona (dos, como en la lámina)
    for g, f in (("i", 0.55), ("d", 0.45)):
        a, b = POS["corona_%s1" % g]
        amuleto(M, rng, a.lerp(b, f) + V(0, -0.1, -0.05), {"corona_%s1" % g: 1.0}, 0.8)


def crear_baston(M, rng):
    """El bastón ancestral (hueso «baston», anclado en el puño derecho): fuste retorcido de 12 m, cabeza de ramas con
    gemas turquesa, cuerdas y amuletos. Va en un objeto aparte («Humbaba_baston»)."""
    M.etiqueta = "baston"
    pb = {"baston": 1.0}
    ag = cabeza_h("baston")
    ABAJO, ARRIBA = 4.1, 7.6                 # metros del puño a cada punta
    eje = [ag + V(0, 0, -ABAJO) + V(0, 0, 0.0), ag + V(0.05, 0, -1.5), ag, ag + V(-0.08, 0.04, 3.5), ag + V(0.05, -0.05, ARRIBA - 0.6)]
    tubo(M, eje, lambda f: 0.16 + 0.05 * f, Q["lados"] - 2, None, color_corteza(MADERA_C, musgo=0.25, claro=0.3, vena=0.25),
         pesos_fijos=pb, rug=0.12, semilla=2.0, paso=Q["paso"], punta=False, tapa_ini=True)
    hebras(M, eje, lambda f: 0.17 + 0.05 * f, max(2, int(round(3 * Q["hebras"]))) + 1, Q["hebra_lados"],
           lambda c, f: pb, rng, color_corteza(MADERA_C, musgo=0.3, claro=0.45, vena=0.35), vueltas=(2.0, 3.0),
           r_hebra=(0.07, 0.1), paso=Q["paso"] * 0.6, desde=0.0, hasta=1.0)
    # punta de abajo (hincable) y cuerdas
    garra(M, ag + V(0, 0, -ABAJO + 0.05), V(0, 0, -1), V(0, -1, 0), 0.5, 0.15, 6, pb, curva=0.0, color=MADERA_C)
    for zc in (-0.55, 0.65, 2.3, 5.9):
        cuerda = [ag + V(math.cos(t) * 0.23, math.sin(t) * 0.23, zc + 0.04 * t) for t in np.linspace(0, 4 * math.pi, 20)]
        tubo(M, cuerda, (0.04, 0.04), 4, None, color_plano(CUERDA), pesos_fijos=pb, rug=0.0, punta=False)
    # cabeza: ramas que se abren, con gemas turquesa
    puntas = []
    top = ag + V(0.05, -0.05, ARRIBA - 0.6)
    col = color_corteza(MADERA_C, musgo=0.3, claro=0.45, vena=0.2)
    for k, d in enumerate((V(0.6, 0, 1), V(-0.7, 0.1, 0.9), V(0.1, -0.6, 1), V(0.0, 0.6, 1.0))):
        rama(M, rng, top + V(0, 0, -0.3), d, 1.4, 0.13, 1, max(2, Q["rama_prof"] - 1), lambda c, f: pb, Q["rama_lados"], col, puntas)
    esfera(M, top + V(0, -0.12, -0.15), 0.2, 8, lambda p, n: TURQUESA + (1.0,), pb, BRILLO, escala=(1, 0.8, 1.3))
    esfera(M, ag + V(0, -0.18, 3.5), 0.11, 6, lambda p, n: TURQUESA + (1.0,), pb, BRILLO)
    amuleto(M, rng, top + V(0.45, -0.05, 0.25), pb, 1.0)
    amuleto(M, rng, top + V(-0.5, 0.05, 0.1), pb, 0.85)
    tubo(M, [top + V(0.45, -0.05, 0.25), top + V(0.0, -0.1, -0.15), top + V(-0.5, 0.05, 0.1)], (0.025, 0.025), 3, None,
         color_plano(CUERDA), pesos_fijos=pb, rug=0.0, punta=False, paso=0.15)


def construir(perfil):
    """Las tres mallas (cuerpo, armadura, bastón) de un perfil. La misma semilla en los tres: lo que queda en el bajo es
    lo mismo que en el alto, con menos lados y menos piezas."""
    global Q
    Q = CALIDAD[perfil]
    cuerpo, armadura, baston = Malla(), Malla(), Malla()
    rng = np.random.default_rng(1234)
    crear_tronco(cuerpo, rng)
    crear_cuello_cabeza(cuerpo, np.random.default_rng(55))
    crear_nucleo(cuerpo, np.random.default_rng(66))
    crear_brazo(cuerpo, np.random.default_rng(77), "_i", 1, 1.0)
    crear_brazo(cuerpo, np.random.default_rng(78), "_d", -1, 0.86)
    crear_pierna(cuerpo, np.random.default_rng(88), "_i", 1)
    crear_pierna(cuerpo, np.random.default_rng(89), "_d", -1)
    crear_corona(cuerpo, np.random.default_rng(99))
    crear_colgantes(cuerpo, np.random.default_rng(111))
    crear_guadana(cuerpo)
    crear_hombreras(armadura, np.random.default_rng(122))
    crear_baston(baston, np.random.default_rng(133))
    return cuerpo, armadura, baston


# ---------------------------------------------------------------- la textura de corteza (repetible en los dos ejes)

def ruido_per(n, cy, cx, semilla):
    rng = np.random.default_rng(semilla)
    g = rng.random((cy, cx))
    ys = np.arange(n) * cy / n
    xs = np.arange(n) * cx / n
    y0, x0 = np.floor(ys).astype(int), np.floor(xs).astype(int)
    ty, tx = ys - y0, xs - x0
    ty, tx = ty * ty * (3 - 2 * ty), tx * tx * (3 - 2 * tx)
    y1, x1 = (y0 + 1) % cy, (x0 + 1) % cx
    y0, x0 = y0 % cy, x0 % cx
    a, b = g[np.ix_(y0, x0)], g[np.ix_(y0, x1)]
    c, d = g[np.ix_(y1, x0)], g[np.ix_(y1, x1)]
    tx, ty = tx[None, :], ty[:, None]
    return (a * (1 - tx) + b * tx) * (1 - ty) + (c * (1 - tx) + d * tx) * ty


def fbm_per(n, cy, cx, semilla, octavas=4):
    r, amp, tot = np.zeros((n, n)), 1.0, 0.0
    for o in range(octavas):
        r += amp * ruido_per(n, cy * 2 ** o, cx * 2 ** o, semilla + 17 * o)
        tot += amp
        amp *= 0.5
    return r / tot


def trazos_per(n, lineas, grosor):
    """Distancia a unas polilíneas en un lienzo que se repite (cada línea se dibuja también desplazada ±n)."""
    d = np.full((n, n), 1e9)
    for pts in lineas:
        for (x0, y0), (x1, y1) in zip(pts[:-1], pts[1:]):
            for ox in (-n, 0, n):
                for oy in (-n, 0, n):
                    ax, ay, bx, by = x0 + ox, y0 + oy, x1 + ox, y1 + oy
                    mx0, mx1 = int(max(0, min(ax, bx) - grosor - 2)), int(min(n, max(ax, bx) + grosor + 3))
                    my0, my1 = int(max(0, min(ay, by) - grosor - 2)), int(min(n, max(ay, by) + grosor + 3))
                    if mx1 <= mx0 or my1 <= my0:
                        continue
                    yy, xx = np.mgrid[my0:my1, mx0:mx1]
                    vx, vy = bx - ax, by - ay
                    l2 = vx * vx + vy * vy + 1e-9
                    t = np.clip(((xx - ax) * vx + (yy - ay) * vy) / l2, 0, 1)
                    dd = np.hypot(xx - (ax + t * vx), yy - (ay + t * vy))
                    d[my0:my1, mx0:mx1] = np.minimum(d[my0:my1, mx0:mx1], dd)
    return d


def pintar_textura(n):
    """Corteza gris de detalle (el color lo pone el color de vértice) con surcos verticales que serpentean, fibras,
    grietas y, en el alfa, vetas turquesa que corren por los surcos. Repetible: u alrededor del miembro, v a lo largo."""
    k = n / 2048.0
    warp = fbm_per(n, 3, 3, 4, 3) * 2 - 1
    baja = fbm_per(n, 2, 6, 9, 3)
    xs = np.arange(n)[None, :] / n
    surco = np.abs(np.sin(np.pi * (xs * 9 + warp * 0.9 + baja * 0.8)))      # 9 surcos por vuelta de textura
    hondo = (1 - surco) ** 4
    fibras = fbm_per(n, 5, 120, 21, 3)
    manchas = fbm_per(n, 4, 4, 31, 4)
    lum = 0.9 - 0.62 * hondo + 0.22 * (fibras - 0.5) + 0.16 * (manchas - 0.5)
    lum = lum * (0.92 + 0.08 * surco)
    rng = np.random.default_rng(5)
    grietas = []
    for i in range(60):
        x, y = rng.uniform(0, n), rng.uniform(0, n)
        pts = [(x, y)]
        for s in range(4):
            x += rng.uniform(8, 22) * k * (1 if rng.random() < 0.5 else -1)
            y += rng.uniform(-6, 6) * k
            pts.append((x, y))
        grietas.append(pts)
    dg = trazos_per(n, grietas, 3 * k + 1)
    lum = lum * (1 - 0.45 * np.clip(1.5 - dg / (1.2 * k + 0.5), 0, 1))
    rgb = np.stack([lum * 1.0, lum * 0.97, lum * 0.92], axis=2)
    liquen = np.clip((fbm_per(n, 8, 8, 41, 3) - 0.62) * 6, 0, 1) * surco
    rgb = rgb * (1 - 0.25 * liquen[..., None]) + np.array([0.6, 0.72, 0.45])[None, None, :] * 0.25 * liquen[..., None] * lum[..., None]
    venas = []
    for i in range(14):
        x, y = rng.uniform(0, n), rng.uniform(0, n)
        pts = [(x, y)]
        for s in range(18):
            y += rng.uniform(14, 30) * k
            x += rng.uniform(-9, 9) * k
            pts.append((x, y))
            if rng.random() < 0.15:
                xb, yb = x, y
                rama_ = [(xb, yb)]
                for t in range(4):
                    xb += rng.uniform(-14, 14) * k
                    yb += rng.uniform(5, 15) * k
                    rama_.append((xb, yb))
                venas.append(rama_)
        venas.append(pts)
    dv = trazos_per(n, venas, 4 * k + 1)
    brillo = np.clip(1.25 - dv / (1.6 * k + 0.6), 0, 1)
    halo = np.clip(1.0 - dv / (7 * k + 1), 0, 1) * 0.35
    rgb = rgb * (1 - 0.3 * halo[..., None])
    rgb = np.clip(rgb, 0, 1)
    return rgb[::-1].copy(), np.maximum(brillo, halo * 0.5)[::-1].copy()    # (Blender: la fila 0 es la de abajo)


def guardar_textura(ruta, rgb, a):
    n = rgb.shape[0]
    im = bpy.data.images.new(os.path.basename(ruta), n, n, alpha=True)
    px = np.concatenate([rgb, (ALFA_MIN + (1 - ALFA_MIN) * a)[..., None]], axis=2).astype(np.float32)
    im.pixels.foreach_set(px.ravel())
    im.filepath_raw = ruta
    im.file_format = "WEBP"
    im.save(quality=90)
    bpy.data.images.remove(im)


def reducir(rgb, a, f):
    n = rgb.shape[0] // f
    return rgb.reshape(n, f, n, f, 3).mean(axis=(1, 3)), a.reshape(n, f, n, f).mean(axis=(1, 3))


# ---------------------------------------------------------------- materiales (para las fotos; en Godot los pone humbaba_3d.gd)

def material(nombre, ruta_tex=None, gris=False):
    m = bpy.data.materials.new(nombre)
    m.use_backface_culling = True
    if hasattr(m, "use_nodes"):
        m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    vc = nt.nodes.new("ShaderNodeVertexColor")
    vc.layer_name = "Color"
    gam = nt.nodes.new("ShaderNodeGamma")
    gam.inputs["Gamma"].default_value = 2.2
    nt.links.new(vc.outputs["Color"], gam.inputs["Color"])
    bsdf.inputs["Roughness"].default_value = 0.85
    if gris:
        bsdf.inputs["Base Color"].default_value = (0.5, 0.5, 0.5, 1)
        return m
    if nombre == "madera" and ruta_tex:
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
        ma = nt.nodes.new("ShaderNodeMath")
        ma.operation = 'MULTIPLY'
        nt.links.new(rango.outputs["Result"], ma.inputs[0])
        nt.links.new(vc.outputs["Alpha"], ma.inputs[1])
        em = nt.nodes.new("ShaderNodeVectorMath")
        em.operation = 'SCALE'
        em.inputs[0].default_value = lineal(TURQUESA)
        nt.links.new(ma.outputs["Value"], em.inputs["Scale"])
        nt.links.new(em.outputs["Vector"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = 2.0
    else:
        nt.links.new(gam.outputs["Color"], bsdf.inputs["Base Color"])
        if nombre == "brillo":
            nt.links.new(gam.outputs["Color"], bsdf.inputs["Emission Color"])
            bsdf.inputs["Emission Strength"].default_value = 3.0
            bsdf.inputs["Roughness"].default_value = 0.2
    return m


def conducir(arm, m, fuerza):
    """La fuerza de la emisión sigue a la escala X del hueso «luz» (como hace humbaba_3d.gd en Godot)."""
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    fc = bsdf.inputs["Emission Strength"].driver_add("default_value")
    v = fc.driver.variables.new()
    v.name = "e"
    v.type = 'TRANSFORMS'
    v.targets[0].id = arm
    v.targets[0].bone_target = "luz"
    v.targets[0].transform_type = 'SCALE_X'
    v.targets[0].transform_space = 'LOCAL_SPACE'
    fc.driver.expression = "%.2f * e" % fuerza


def crear_objeto_malla(M, arm, nombre, ruta_tex, gris=False):
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
    me.set_sharp_from_angle(angle=math.radians(50))
    obj = bpy.data.objects.new(nombre, me)
    bpy.context.scene.collection.objects.link(obj)
    if arm is not None:
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
        clave = nm + ("_gris" if gris else "")
        if clave in bpy.data.materials:
            me.materials.append(bpy.data.materials[clave])
            continue
        m = material(nm, ruta_tex, gris)
        m.name = clave
        me.materials.append(m)
        if arm is not None and not gris:
            conducir(arm, m, 2.0 if nm == "madera" else 3.0)
    return obj


# ---------------------------------------------------------------- el esqueleto y los controles

ARM = None


def preparar_escena():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.fps = FPS
    return sc


def crear_esqueleto(sc):
    arm_data = bpy.data.armatures.new("Humbaba_esqueleto")
    arm = bpy.data.objects.new("Humbaba", arm_data)
    sc.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    arm.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    for (n, h, t, p) in HUESOS + CONTROLES:
        eb = arm_data.edit_bones.new(n)
        eb.head, eb.tail = estirar(h), estirar(t)
        eb.roll = 0.0
        eb.use_connect = False
        eb.use_deform = n in NOMBRES
    for (n, h, t, p) in HUESOS + CONTROLES:
        if p:
            arm_data.edit_bones[n].parent = arm_data.edit_bones[p]
    bpy.ops.object.mode_set(mode='OBJECT')
    for pb in arm.pose.bones:
        pb.rotation_mode = 'QUATERNION'
    pbs = arm.pose.bones
    for l in ("_i", "_d"):
        c = pbs["pierna" + l].constraints.new('IK')
        c.name = "IK"
        c.target, c.subtarget = arm, "ctrl_pie" + l
        c.pole_target, c.pole_subtarget = arm, "polo_rodilla" + l
        c.chain_count = 2
        c = pbs["tobillo" + l].constraints.new('COPY_ROTATION')
        c.name = "Pie"
        c.target, c.subtarget = arm, "ctrl_pie" + l
        c.owner_space = c.target_space = 'WORLD'
        c = pbs["antebrazo" + l].constraints.new('IK')
        c.name = "IK"
        c.target, c.subtarget = arm, "ctrl_mano" + l
        c.pole_target, c.pole_subtarget = arm, "polo_codo" + l
        c.chain_count = 2
        c.influence = 0.0
    c = pbs["ojo"].constraints.new('DAMPED_TRACK')
    c.name = "Mirada"
    c.target, c.subtarget = arm, "ctrl_ojo"
    c.track_axis = 'TRACK_Y'
    c = pbs["baston"].constraints.new('DAMPED_TRACK')
    c.name = "Mira"
    c.target, c.subtarget = arm, "ctrl_baston"
    c.track_axis = 'TRACK_Y'
    arm.animation_data_create()
    return arm


def ajustar_polos(arm):
    """El ángulo de cada polo que deja la cadena como en la pose de enlace con el control en su sitio (búsqueda)."""
    res = {}
    for l in ("_i", "_d"):
        for hueso, primero in (("pierna" + l, "muslo" + l), ("antebrazo" + l, "brazo" + l)):
            c = arm.pose.bones[hueso].constraints["IK"]
            inf = c.influence
            c.influence = 1.0
            rest = arm.data.bones[primero].matrix_local.to_quaternion()
            def err(ang):
                c.pole_angle = math.radians(ang)
                bpy.context.view_layer.update()
                q = arm.pose.bones[primero].matrix.to_quaternion()
                return rest.rotation_difference(q).angle
            mejor = min(range(-180, 180, 3), key=err)
            fino = min([mejor + x * 0.25 for x in range(-12, 13)], key=err)
            c.pole_angle = math.radians(fino)
            bpy.context.view_layer.update()
            punta = arm.pose.bones[hueso].tail
            obj = arm.pose.bones[c.subtarget].head
            res[hueso] = {"polo": round(fino, 2), "error_grados": round(math.degrees(err(fino)), 3),
                          "punta_a_control_m": round((punta - obj).length, 4)}
            c.influence = inf
    bpy.context.view_layer.update()
    return res


# ---------------------------------------------------------------- poses
# Una pose es un diccionario: hueso → (rx, ry, rz) en grados, giros alrededor de los ejes del esqueleto aplicados en la
# orientación de enlace del hueso (+rx inclina adelante lo que apunta arriba y atrás lo que apunta abajo; los del lado
# derecho, con lado() o espejo(), se escriben como los del izquierdo); «loc:hueso» → desplazamiento (x, y, z) en metros en
# ejes del esqueleto; «ik:_i»/«ik:_d» → influencia del IK del brazo (0 FK, 1 IK); «luz» → intensidad del brillo;
# «nucleo_esc» → la escala del núcleo (late).

def q_local(nombre, r):
    b = ARM.data.bones[nombre]
    R = b.matrix_local.to_quaternion()
    q = Euler((math.radians(r[0]), math.radians(r[1]), math.radians(r[2])), 'XYZ').to_quaternion()
    return R.inverted() @ q @ R


def loc_local(nombre, d):
    b = ARM.data.bones[nombre]
    return b.matrix_local.to_3x3().inverted() @ Vector(d)


def espejo(pose, nombre, r):
    pose[nombre + "_i"] = tuple(r)
    pose[nombre + "_d"] = (r[0], -r[1], -r[2])
    return pose


def lado(l, r):
    return tuple(r) if l == "_i" else (r[0], -r[1], -r[2])


def lado_loc(l, d):
    return tuple(d) if l == "_i" else (-d[0], d[1], d[2])



# ---------------------------------------------------------------- fotos

def motor_eevee(sc):
    motores = [i.identifier for i in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    sc.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in motores else "BLENDER_EEVEE_NEXT"
    try:
        sc.view_settings.view_transform = "Standard"
    except Exception:
        pass
    try:
        sc.eevee.use_shadows = True
    except Exception:
        pass


def escena_fotos(sc, fondo=(0.70, 0.76, 0.74)):
    motor_eevee(sc)
    mundo = bpy.data.worlds.new("cielo")
    sc.world = mundo
    mundo.use_nodes = True
    bg = mundo.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = tuple(fondo) + (1,)
    bg.inputs["Strength"].default_value = 0.7
    me = bpy.data.meshes.new("suelo")
    me.from_pydata([(-300, -300, 0), (300, -300, 0), (300, 300, 0), (-300, 300, 0)], [], [(0, 1, 2, 3)])
    suelo = bpy.data.objects.new("suelo", me)
    sc.collection.objects.link(suelo)
    ms = bpy.data.materials.new("suelo")
    ms.use_nodes = True
    ms.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.32, 0.36, 0.3, 1)
    ms.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 1.0
    me.materials.append(ms)
    for nombre, color, energia, rot in (("sol", (1.0, 0.95, 0.88), 3.2, (50, 0, -35)), ("relleno", (0.6, 0.85, 0.85), 1.1, (70, 0, 150))):
        l = bpy.data.lights.new(nombre, "SUN")
        l.color = color
        l.energy = energia
        o = bpy.data.objects.new(nombre, l)
        o.rotation_euler = [math.radians(a) for a in rot]
        sc.collection.objects.link(o)
    return suelo


def heroe_escala(sc, pos, alto=1.75):
    """Una figura humana gris de 1,75 m para comparar (como la silueta de la lámina)."""
    M = Malla()
    p = Vector(pos)
    tubo(M, [p + V(0, 0, 0.0), p + V(0, 0, 0.9), p + V(0, 0, 1.45)], lambda f: 0.17 if f < 0.95 else 0.12, 10, None,
         color_plano((0.45, 0.45, 0.48)), pesos_fijos={"raiz": 1.0}, rug=0.0, punta=False, tapa_ini=True)
    esfera(M, p + V(0, 0, 1.6), 0.13, 10, lambda q, n: (0.45, 0.45, 0.48, 0.0), {"raiz": 1.0}, MADERA)
    return crear_objeto_malla(M, None, "heroe", None, gris=True)


def camara(sc, pos, mira, escala, ancho, alto):
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam_d.ortho_scale = escala
    cam_d.clip_end = 500
    cam = bpy.data.objects.new("cam", cam_d)
    sc.collection.objects.link(cam)
    sc.camera = cam
    cam.location = Vector(mira) + (Vector(pos) - Vector(mira)).normalized() * 150.0
    cam.rotation_euler = (Vector(mira) - cam.location).to_track_quat('-Z', 'Y').to_euler()
    sc.render.resolution_x, sc.render.resolution_y = ancho, alto
    sc.render.resolution_percentage = 100
    return cam


def poner_clip(clip, seg):
    ad = ARM.animation_data
    for t in ad.nla_tracks:
        t.mute = True
    ad.action = bpy.data.actions[clip]
    try:
        if ad.action_slot is None and len(ad.action.slots):
            ad.action_slot = ad.action.slots[0]
    except Exception:
        pass
    bpy.context.scene.frame_set(int(round(seg * FPS)) + 1)


def foto(sc, ruta, pose=None, clip=None, seg=0.0, pos=(0, -60, 8), mira=(0, 0, 6.2), escala=15.0, ancho=640, alto=640):
    if clip:
        poner_clip(clip, seg)
    else:
        ARM.animation_data.action = None
        poner_pose(pose or {})
        sc.frame_set(1)
    cam = camara(sc, pos, mira, escala, ancho, alto)
    sc.render.filepath = ruta
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam)
    return ruta


def guardar_png(ruta, px):
    h, w = px.shape[:2]
    out = bpy.data.images.new(os.path.basename(ruta), w, h, alpha=True)
    out.pixels.foreach_set(px.ravel())
    out.filepath_raw = ruta
    out.file_format = "PNG"
    out.save()
    bpy.data.images.remove(out)


def hoja(rutas, salida, columnas):
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
    print("HOJA", salida)


def exportar(ruta, objetos):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objetos:
        o.select_set(True)
    bpy.ops.export_scene.gltf(
        filepath=ruta, export_format='GLB', use_selection=True,
        export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=True,
        export_anim_slide_to_zero=True, export_def_bones=True, export_reset_pose_bones=True,
        export_optimize_animation_size=True, export_skins=True, export_yup=True, export_influence_nb=4,
        export_vertex_color='ACTIVE', export_cameras=False, export_lights=False, export_image_format='NONE',
        export_materials='EXPORT')
    print("EXPORTADO", ruta, os.path.getsize(ruta))


# ---------------------------------------------------------------- etapas y principal

VISTAS = {  # (posición de la cámara, mira, escala): como la hoja de la lámina (frente, perfil, espalda) y la del combate
    "frente": ((0, -60, 6.5), (0, 0, 6.3), 15.5),
    "perfil": ((60, 0, 6.5), (0, -0.5, 6.3), 15.5),
    "espalda": ((0, 60, 6.5), (0, 0, 6.3), 15.5),
    "tres_cuartos": ((-36, -48, 13), (0, -0.5, 6.0), 15.5),
}


def fotos_vistas(sc, carpeta, prefijo, pose):
    rutas = []
    for nombre, (pos, mira, esc) in VISTAS.items():
        rutas.append(foto(sc, os.path.join(carpeta, "%s_%s.png" % (prefijo, nombre)), pose=pose, pos=pos, mira=mira,
                          escala=esc, ancho=560, alto=700))
    return rutas


def pesos_color(objs):
    """Colores de vértice según el hueso que más pesa (para ver los pesos en una foto)."""
    rng = np.random.default_rng(3)
    paleta = {n: tuple(rng.uniform(0.15, 1.0, 3)) for n in NOMBRES}
    for o in objs:
        me = o.data
        attr = me.color_attributes["Color"]
        cols = []
        for v in me.vertices:
            mejor, h = 0, None
            for g in v.groups:
                if g.weight > mejor:
                    mejor, h = g.weight, o.vertex_groups[g.group].name
            c = paleta.get(h, (1, 1, 1))
            cols += [c[0], c[1], c[2], 0.0]
        attr.data.foreach_set("color", cols)


def principal():
    global ARM, Q
    os.makedirs(CARPETA, exist_ok=True)
    if CARPETA_FOTOS:
        os.makedirs(CARPETA_FOTOS, exist_ok=True)
    resumen = {"fps": FPS, "huesos": NOMBRES, "huesos_deformantes": len(NOMBRES), "controles": [c[0] for c in CONTROLES],
               "triangulos": {}, "triangulos_por_parte": {}, "texturas": {}, "clips": {}}
    rgb, a = pintar_textura(TEX)
    rutas_tex = {}
    for perfil, f, suf in (("alto", 1, ""), ("medio", 2, "_medio"), ("bajo", 4, "_bajo")):
        r, al = (rgb, a) if f == 1 else reducir(rgb, a, f)
        ruta = os.path.join(CARPETA, "%s_madera%s.webp" % (PREFIJO, suf))
        guardar_textura(ruta, r, al)
        rutas_tex[perfil] = ruta
        resumen["texturas"][perfil] = {"archivo": os.path.basename(ruta), "lado": r.shape[0], "bytes": os.path.getsize(ruta)}
    sc = preparar_escena()
    ARM = crear_esqueleto(sc)
    resumen["polos"] = ajustar_polos(ARM)
    print("POLOS", resumen["polos"])
    print("NUCLEO", tuple(round(x, 3) for x in centro_nucleo()))
    if ETAPAS == "blockout":
        escena_fotos(sc)
        cu, ar, ba = construir("bajo")
        objs = [crear_objeto_malla(m, ARM, "Humbaba_" + n, None, gris=True) for m, n in ((cu, "cuerpo"), (ar, "armadura"), (ba, "baston"))]
        heroe_escala(sc, (3.4, -4.5, 0))
        rutas = fotos_vistas(sc, CARPETA_FOTOS, "01_blockout", {})
        hoja(rutas, os.path.join(CARPETA_FOTOS, "01_blockout_hoja.png"), 4)
        return
    clips = {}
    if ETAPAS == "todo":
        clips = crear_clips(ARM, resumen)
    objetos_alto = None
    for perfil in PERFILES:
        cu, ar, ba = construir(perfil)
        objs = [crear_objeto_malla(cu, ARM, "Humbaba_cuerpo", rutas_tex["alto"]),
                crear_objeto_malla(ar, ARM, "Humbaba_armadura", rutas_tex["alto"]),
                crear_objeto_malla(ba, ARM, "Humbaba_baston", rutas_tex["alto"])]
        tris = cu.triangulos() + ar.triangulos() + ba.triangulos()
        resumen["triangulos"][perfil] = tris
        cuenta = {}
        for M_ in (cu, ar, ba):
            for f_, e in zip(M_.caras, M_.etq):
                cuenta[e] = cuenta.get(e, 0) + len(f_) - 2
        resumen["triangulos_por_parte"][perfil] = cuenta
        resumen.setdefault("vertices", {})[perfil] = len(cu.v) + len(ar.v) + len(ba.v)
        print("MALLA", perfil, "triángulos", tris, cuenta)
        suf = "" if perfil == "alto" else "_" + perfil
        if ETAPAS == "todo":
            exportar(os.path.join(CARPETA, "%s%s.glb" % (PREFIJO, suf)), [ARM] + objs)
        if perfil == "alto":
            objetos_alto = objs
            if SALIDA_BLEND:
                bpy.ops.wm.save_as_mainfile(filepath=SALIDA_BLEND)
                print("GUARDADO", SALIDA_BLEND)
            continue
        for o in objs:
            me = o.data
            bpy.data.objects.remove(o)
            bpy.data.meshes.remove(me)
    if ETAPAS == "todo":
        with open(os.path.join(CARPETA, "%s_clips.json" % PREFIJO), "w", encoding="utf-8", newline="\n") as fh:
            json.dump(resumen, fh, ensure_ascii=False, indent=1)
    print("RESUMEN", json.dumps(resumen["triangulos"]), "huesos", len(NOMBRES))
    if CARPETA_FOTOS and objetos_alto:
        etapas_fotos(sc, objetos_alto, resumen)




# ---------------------------------------------------------------- fotos de cada etapa (frente a la lámina)

def etapas_fotos(sc, objs, resumen):
    c = CARPETA_FOTOS
    escena_fotos(sc)
    heroe = heroe_escala(sc, (3.6, -4.6, 0))
    reposo = POSES_FOTO.get("reposo", {}) if "POSES_FOTO" in globals() else {}
    # 02: el modelo con color (pose de enlace y en reposo), de frente, perfil, espalda y tres cuartos
    r1 = fotos_vistas(sc, c, "02_modelo_enlace", {})
    hoja(r1, os.path.join(c, "02_modelo_enlace_hoja.png"), 4)
    if reposo:
        r2 = fotos_vistas(sc, c, "02_modelo_reposo", reposo)
        hoja(r2, os.path.join(c, "02_modelo_reposo_hoja.png"), 4)
    # detalles: cabeza y ojo, núcleo, mano izquierda, pie, bastón
    det = [foto(sc, os.path.join(c, "02_det_cabeza.png"), pose=reposo, pos=(-10, -60, 14), mira=tuple(estirar((0, -1.6, 10.9))), escala=4.8, ancho=480, alto=480),
           foto(sc, os.path.join(c, "02_det_nucleo.png"), pose=reposo, pos=(-6, -60, 8), mira=tuple(estirar((0, -1.5, 8.0))), escala=4.2, ancho=480, alto=480),
           foto(sc, os.path.join(c, "02_det_mano.png"), pose=reposo, pos=(30, -50, 6), mira=tuple(estirar((3.6, -1.7, 2.2))), escala=4.5, ancho=480, alto=480),
           foto(sc, os.path.join(c, "02_det_pie.png"), pose=reposo, pos=(-20, -60, 10), mira=tuple(estirar((1.8, -1.0, 0.6))), escala=4.5, ancho=480, alto=480),
           foto(sc, os.path.join(c, "02_det_baston.png"), pose=reposo, pos=(-40, -50, 12), mira=tuple(estirar((-3.3, -1.6, 10.0))), escala=6.0, ancho=480, alto=480)]
    hoja(det, os.path.join(c, "02_detalles_hoja.png"), 5)
    # 04: deformaciones en poses extremas; 05: los clips (con «solo=clip1,clip2» en SOLO_FOTOS, solo esos)
    foto_deformaciones(sc, objs)
    if resumen.get("clips"):
        fotos_clips(sc, resumen)
    # 03 (al final: cambia los colores de vértice): el rig, pesos por hueso (cada color, el hueso que más pesa)
    pesos_color(objs)
    r3 = fotos_vistas(sc, c, "03_pesos", {})
    hoja(r3, os.path.join(c, "03_pesos_hoja.png"), 4)




def crear_guadana(M):
    """La Guadaña de Raíces: una hoja curva de raíz petrificada con filo turquesa que brota del antebrazo izquierdo
    (hueso «guadana», con escala casi 0 fuera de su ataque: escondida dentro del brazo)."""
    M.etiqueta = "guadana"
    g0 = cabeza_h("guadana")
    a, b = POS["antebrazo_i"]
    largo_ = (b - a).normalized()                       # a lo largo del antebrazo, más allá de la garra
    fuera = Vector((1, 0, 0))
    pts = [g0 - largo_ * 0.4 + largo_ * 4.6 * t + fuera * (1.5 * t * t - 0.2) + Vector((0, -0.6 * t * t, 0))
           for t in np.linspace(0, 1, 7)]
    tubo(M, pts, lambda f: 0.36 * (1 - 0.9 * f) + 0.02, 7, None, color_corteza(MADERA_CLARA, musgo=0.0, claro=0.5, vena=0.9),
         pesos_fijos={"guadana": 1.0}, rug=0.12, achatado=(1.0, 0.3), paso=0.2, ref=(0, -1, 0))
    hebras(M, pts, lambda f: 0.25 * (1 - 0.8 * f), 2, 4, lambda c, f: {"guadana": 1.0}, np.random.default_rng(9),
           color_corteza(MADERA_C, musgo=0.0, claro=0.3), vueltas=(1.0, 1.5), r_hebra=(0.06, 0.09), paso=0.18)


# ---------------------------------------------------------------- poses y clips
# poner_pose: además de lo de arriba, «esc:guadana» (por defecto 0,01: escondida), «loc:raiz», «rot:ctrl_pie_i»…

ESCONDIDA = 0.01
PREVIO = {}


def poner_pose(pose, continuar=False):
    """Pone «pose» (lo que no dice, en la de enlace). Con continuar, los cuaterniones siguen el hemisferio del anterior
    (para que las claves se interpolen por el camino corto)."""
    for pb in ARM.pose.bones:
        pb.rotation_quaternion = Quaternion()
        pb.location = Vector()
        pb.scale = Vector((1, 1, 1))
    ARM.pose.bones["guadana"].scale = Vector((ESCONDIDA,) * 3)
    for l in ("_i", "_d"):
        ARM.pose.bones["antebrazo" + l].constraints["IK"].influence = 0.0
    for k, v in pose.items():
        if k.startswith("loc:"):
            ARM.pose.bones[k[4:]].location = loc_local(k[4:], v)
        elif k.startswith("ik:"):
            ARM.pose.bones["antebrazo" + k[3:]].constraints["IK"].influence = v
        elif k.startswith("esc:"):
            ARM.pose.bones[k[4:]].scale = Vector((v, v, v))
        elif k == "luz":
            ARM.pose.bones["luz"].scale = Vector((v, v, v))
        elif k == "nucleo_esc":
            ARM.pose.bones["nucleo"].scale = Vector((v, v, v))
        elif k in ("eventos",):
            continue
        else:
            q = q_local(k, v)
            if continuar and k in PREVIO and PREVIO[k].dot(q) < 0:
                q.negate()
            ARM.pose.bones[k].rotation_quaternion = q
            PREVIO[k] = q.copy()
    bpy.context.view_layer.update()


def mez(*poses, **kw):
    r = {}
    for p in poses:
        r.update(p)
    r.update(kw)
    return r


def L(**kw):
    """Atajo: claves «loc_hueso» → «loc:hueso», «ik_i» → «ik:_i», «esc_hueso» → «esc:hueso»."""
    r = {}
    for k, v in kw.items():
        if k.startswith("loc_"):
            r["loc:" + k[4:]] = v
        elif k.startswith("ik_"):
            r["ik:_" + k[3:]] = v
        elif k.startswith("esc_"):
            r["esc:" + k[4:]] = v
        else:
            r[k] = v
    return r


def ambos(nombre, r):
    return {nombre + "_i": tuple(r), nombre + "_d": (r[0], -r[1], -r[2])}


def dedos(l, a, b=None, pulgar=None, abrir=0.0):
    """Los dedos de una mano: «a» (tramo de la palma) y «b» (el de la garra) curvan hacia la palma (+); abrir separa."""
    b = a * 1.2 if b is None else b
    p = pulgar if pulgar is not None else a * 0.8
    r = {}
    for k, dedo in enumerate(("dedo1", "dedo2", "dedo3")):
        sep = (-1, 0, 1)[k] * abrir
        r[dedo + "_a" + l] = lado(l, (-a * 0.35 + sep, a, 0))
        r[dedo + "_b" + l] = lado(l, (-b * 0.3, b, 0))
    r["pulgar_a" + l] = lado(l, (-p * 0.2, -p * 0.6, 0))
    r["pulgar_b" + l] = lado(l, (0, -p * 0.7, 0))
    return r


def tronco(c1=0, c2=0, c3=0, pe=0, n1=0, n2=0, ca=0, giro=0.0, lat=0.0):
    """Columna, cuello y cabeza: inclinación adelante (+), giro (rz, + hacia su izquierda) y lado (ry)."""
    return {"columna_1": (c1, lat * 0.3, giro * 0.2), "columna_2": (c2, lat * 0.3, giro * 0.25),
            "columna_3": (c3, lat * 0.2, giro * 0.25), "pecho": (pe, lat * 0.2, giro * 0.3),
            "cuello_1": (n1, 0, -giro * 0.15), "cuello_2": (n2, 0, -giro * 0.15), "cabeza": (ca, 0, 0)}


# El reposo: encorvado, rodillas algo dobladas, la garra izquierda colgando con los dedos medio cerrados y el bastón en
# la derecha, plantado a su lado; el ojo al frente.
BRAZO_BASTON = {"hombro_d": lado("_d", (0, 0, -2)), "brazo_d": lado("_d", (-14, 6, 0)), "antebrazo_d": lado("_d", (-42, 0, 6)),
                "muneca_d": lado("_d", (8, 0, 0)), **dedos("_d", 55, 65, 50)}
REPOSO = mez(L(loc_pelvis=(0, 0.05, -0.18)), tronco(4, 5, 6, 6, -8, -6, -5),
             {"hombro_i": (0, 0, -3), "brazo_i": (-6, 4, 0), "antebrazo_i": (-16, 0, -4), "muneca_i": (-6, 0, 0)},
             dedos("_i", 14, 18, 10, abrir=4), BRAZO_BASTON,
             L(loc_ctrl_baston=(-0.35, -0.9, 0.0)), {"mandibula": (4, 0, 0), "luz": 1.0, "nucleo_esc": 1.0})


def respira(p, k, amp=1.0):
    """Una fase de la respiración (k de 0 a 1 = de vacío a lleno)."""
    r = dict(p)
    for b, d in (("columna_3", -1.4), ("pecho", -2.2), ("cuello_1", 0.8)):
        x = r.get(b, (0, 0, 0))
        r[b] = (x[0] + d * k * amp, x[1], x[2])
    for l in ("_i", "_d"):
        x = r.get("hombro" + l, (0, 0, 0))
        r["hombro" + l] = (x[0], x[1], x[2] + lado(l, (0, 0, 2.0 * k * amp))[2])
    r["nucleo_esc"] = r.get("nucleo_esc", 1.0) * (1.0 + 0.05 * k * amp)
    r["luz"] = r.get("luz", 1.0) * (1.0 + 0.15 * k * amp)
    return r


ENFADO = mez(REPOSO, L(loc_pelvis=(0, 0.1, -0.42)), tronco(6, 7, 9, 9, -10, -8, 2),
             {"hombro_i": (0, 0, -6), "brazo_i": (-14, -18, 0), "antebrazo_i": (-30, 0, -6), "muneca_i": (-12, 0, 0)},
             dedos("_i", 4, 8, 0, abrir=12), {"brazo_d": lado("_d", (-18, -6, 0)), "mandibula": (12, 0, 0), "luz": 1.45,
                                            "nucleo_esc": 1.05},
             L(loc_ctrl_pie_i=(0.15, -0.35, 0), loc_ctrl_pie_d=(-0.15, 0.3, 0)))


class Clip:
    def __init__(self, nombre, dur, bucle=False, temblor=0.0, viento=1.0):
        self.nombre, self.dur, self.bucle = nombre, dur, bucle
        self.claves = []
        self.eventos = {}
        self.temblor = temblor
        self.viento = viento

    def k(self, t, pose, golpe=False):
        self.claves.append((t, pose, golpe))
        return self

    def ev(self, nombre, t):
        self.eventos[nombre] = round(t, 4)
        return self


def curvas(act):
    try:
        return list(act.fcurves)
    except AttributeError:
        out = []
        for capa in act.layers:
            for tira in capa.strips:
                for cb in tira.channelbags:
                    out += list(cb.fcurves)
        return out


CANAL_LOC = ["raiz", "pelvis", "ctrl_pie_i", "ctrl_pie_d", "ctrl_mano_i", "ctrl_mano_d", "ctrl_ojo", "ctrl_baston"]
CANAL_ESC = ["luz", "nucleo", "guadana"]
SECUNDARIOS = {}      # cadena → (padre, rigidez Hz, amortiguación, gravedad, peso del viento)


def cadenas_secundarias():
    c = {}
    for g in "cid":
        c[("corona_%s1" % g, "corona_%s2" % g)] = ("cabeza", 1.6, 0.22, 0.0, 0.6)
    for suf, ancla, d in COLGANTES:
        cad = tuple("colgante%s_%s" % (suf, x) for x in "abc")
        c[cad] = ("pelvis" if ancla[2] < 6.0 else "columna_1", 0.75, 0.3, 0.55, 1.0)
    return c


def canales_rot():
    sec = set(b for cad in cadenas_secundarias() for b in cad)
    return [n for n in NOMBRES if n not in sec and n not in ("luz",)] + ["ctrl_pie_i", "ctrl_pie_d"]


def hornear(clip):
    """Crea la acción de un clip: claves de la pose (Bézier; «golpe»: entra acelerando en la clave siguiente), bucles con
    Cycles, y la parte secundaria (corona y raíces colgantes) simulada con muelles y horneada fotograma a fotograma."""
    act = bpy.data.actions.new(clip.nombre)
    act.use_fake_user = True
    ad = ARM.animation_data
    ad.action = act
    PREVIO.clear()
    rot = canales_rot()
    golpes = []
    for (t, pose, golpe) in sorted(clip.claves, key=lambda x: x[0]):
        f = 1 + t * FPS
        poner_pose(pose, continuar=True)
        for b in rot:
            ARM.pose.bones[b].keyframe_insert("rotation_quaternion", frame=f, group=b)
        for b in CANAL_LOC:
            ARM.pose.bones[b].keyframe_insert("location", frame=f, group=b)
        for b in CANAL_ESC:
            ARM.pose.bones[b].keyframe_insert("scale", frame=f, group=b)
        for l in ("_i", "_d"):
            ARM.pose.bones["antebrazo" + l].constraints["IK"].keyframe_insert("influence", frame=f)
        if golpe:
            golpes.append(f)
    for fc in curvas(act):
        for kp in fc.keyframe_points:
            if any(abs(kp.co.x - g) < 0.01 for g in golpes):
                kp.interpolation = 'CUBIC'
                kp.easing = 'EASE_IN'
        if clip.bucle:
            fc.modifiers.new('CYCLES')
        fc.update()
    hornear_secundario(clip, act)
    ad.action = None
    pista = ad.nla_tracks.new()
    pista.name = clip.nombre
    pista.strips.new(clip.nombre, 1, act)
    pista.mute = True
    return act


def hornear_secundario(clip, act):
    sc = bpy.context.scene
    n = int(round(clip.dur * FPS)) + 1
    vueltas = 3 if clip.bucle else 1
    dt = 1.0 / FPS
    cads = cadenas_secundarias()
    datos = {b: np.zeros((n, 4)) for cad in cads for b in cad}
    estado = {cad: [Vector(), Vector()] for cad in cads}
    rng = np.random.default_rng(len(clip.nombre))
    fase = {cad: rng.uniform(0, 6.28) for cad in cads}
    hist = {cad: [] for cad in cads}
    rest = {}
    for cad, (padre, hz, zeta, grav, vto) in cads.items():
        b0 = ARM.data.bones[cad[0]]
        rest[cad] = [(ARM.data.bones[b].parent.matrix_local.inverted() @ ARM.data.bones[b].matrix_local).to_quaternion() for b in cad]
    total = (n - 1) * vueltas + 1
    previo = None
    for paso in range(-2, total):
        fr = paso % (n - 1) if clip.bucle else max(0, min(paso, n - 1))
        sc.frame_set(1 + fr)
        mats = {padre: ARM.pose.bones[padre].matrix.copy() for (padre, *_r) in cads.values()}
        for cad, (padre, hz, zeta, grav, vto) in cads.items():
            Mp = mats[padre]
            b0 = ARM.data.bones[cad[0]]
            raiz_w = Mp @ (ARM.data.bones[padre].matrix_local.inverted() @ b0.matrix_local)
            P = raiz_w.translation.copy()
            h = hist[cad]
            h.append(P)
            if len(h) > 3:
                h.pop(0)
            d, v = estado[cad]
            dir0 = (raiz_w.to_3x3() @ Vector((0, 1, 0))).normalized()
            largo = sum(ARM.data.bones[b].length for b in cad)
            if len(h) == 3:
                acc = (h[2] - 2 * h[1] + h[0]) / (dt * dt)
            else:
                acc = Vector()
            acc_p = acc - dir0 * acc.dot(dir0)
            w = 2 * math.pi * hz
            meta = Vector()
            if grav > 0:                                   # cuelgan: tienden a la vertical (en parte; son rígidas)
                abajo = Vector((0, 0, -1))
                meta = (abajo - dir0 * abajo.dot(dir0)) * largo * grav
            t = (paso if paso >= 0 else 0) * dt
            viento = Vector((math.sin(t * 1.3 + fase[cad]), math.cos(t * 0.9 + fase[cad] * 1.7), 0)) * 0.06 * largo * vto * clip.viento
            if clip.temblor > 0:
                viento += Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), 0)) * clip.temblor * largo
            fuerza = -w * w * (d - meta - viento) - 2 * zeta * w * v - acc_p * 0.9
            v = v + fuerza * dt
            d = d + v * dt
            d = d - dir0 * d.dot(dir0)
            if d.length > largo * 0.9:
                d = d.normalized() * largo * 0.9
            estado[cad] = [d, v]
            if paso < total - n or paso < 0:
                continue
            idx = fr if clip.bucle else paso
            # reparto del giro por la cadena (más en la base) y paso a giros locales
            ang = d.length / max(largo, 1e-6)
            eje = dir0.cross(d).normalized() if d.length > 1e-6 else Vector((1, 0, 0))
            W_padre = raiz_w.to_quaternion() @ rest[cad][0].inverted()
            pesos = (0.5, 0.3, 0.2) if len(cad) == 3 else (0.6, 0.4)
            for i, b in enumerate(cad):
                W = W_padre @ rest[cad][i]
                delta = Quaternion(eje, ang * pesos[i])
                base = W.inverted() @ delta @ W
                datos[b][idx] = (base.w, base.x, base.y, base.z)
                W_padre = delta @ W
    if clip.bucle:                                       # fundido de los últimos 8 fotogramas con el primero
        for b, arr in datos.items():
            for i in range(8):
                f = (i + 1) / 9.0
                j = n - 9 + i
                arr[j] = arr[j] * (1 - f) + arr[0] * f
            arr[n - 1] = arr[0]
    marcos = np.arange(n, dtype=float) + 1.0
    for b, arr in datos.items():
        for i in range(1, n):
            if np.dot(arr[i], arr[i - 1]) < 0:
                arr[i] = -arr[i]
        dp = 'pose.bones["%s"].rotation_quaternion' % b
        for c in range(4):
            fc = act.fcurve_ensure_for_datablock(ARM, dp, index=c, group_name=b)
            fc.keyframe_points.add(n)
            co = np.empty(2 * n)
            co[0::2] = marcos
            co[1::2] = arr[:, c]
            fc.keyframe_points.foreach_set("co", co)
            fc.keyframe_points.foreach_set("interpolation", [1] * n)
            fc.update()


# ---------------------------------------------------------------- medidas de cada clip

def mundo(b, cola=False):
    pb = ARM.pose.bones[b]
    return (pb.tail if cola else pb.head).copy()


def a_godot(v):
    return [round(v.x, 3), round(v.z, 3), round(-v.y, 3)]


def medir_clip(clip):
    """Lo que el juego necesita saber de cada clip, medido fotograma a fotograma: dónde están el ojo, el núcleo, la boca,
    las manos y la punta del bastón en cada evento (en ejes de Godot), el punto más bajo del puño, cuánto se mueven los
    pies y lo alto que queda la punta del bastón."""
    sc = bpy.context.scene
    poner_clip(clip.nombre, 0.0)
    n = int(round(clip.dur * FPS)) + 1
    m = {"pies_max_m": 0.0, "punta_baston_min_z": 99.0, "puno_min_z": 99.0, "puno_min_t": 0.0, "garra_d_min_z": 99.0}
    p0 = {l: None for l in ("_i", "_d")}
    for i in range(n):
        sc.frame_set(1 + i)
        for l in ("_i", "_d"):
            p = mundo("tobillo" + l)
            if p0[l] is None:
                p0[l] = p
            m["pies_max_m"] = max(m["pies_max_m"], (p - p0[l]).length)
        pb = ARM.pose.bones["baston"]
        punta = (pb.matrix @ Matrix.Translation((0, -4.1, 0))).translation
        m["punta_baston_min_z"] = min(m["punta_baston_min_z"], punta.z)
        z = mundo("palma_i", True).z
        if z < m["puno_min_z"]:
            m["puno_min_z"], m["puno_min_t"] = z, i / FPS
    for k in m:
        m[k] = round(m[k], 3)
    puntos = {}
    for ev, t in clip.eventos.items():
        sc.frame_set(1 + int(round(t * FPS)))
        puntos[ev] = {"ojo": a_godot(mundo("ojo", True)), "nucleo": a_godot(mundo("nucleo")),
                      "boca": a_godot(mundo("mandibula", True)), "mano_i": a_godot(mundo("palma_i", True)),
                      "mano_d": a_godot(mundo("palma_d", True)),
                      "baston_punta": a_godot((ARM.pose.bones["baston"].matrix @ Matrix.Translation((0, -4.1, 0))).translation),
                      "baston_cabeza": a_godot((ARM.pose.bones["baston"].matrix @ Matrix.Translation((0, 7.2, 0))).translation)}
    m["puntos"] = puntos
    return m


# ---------------------------------------------------------------- los clips
# Cada ataque: anticipación clara (pose de aviso que se sostiene), golpe (la clave anterior con «golpe»: entra
# acelerando) y recuperación hasta el reposo. Los instantes de los eventos («impacto», «aviso»…) los usa el juego como
# anclas del daño, el sonido y los efectos (humbaba_clips.json); el daño no depende de lo que dure el clip.
# El brazo derecho lleva el bastón con IK (la mano queda en su sitio aunque el tronco se mueva y la punta del bastón,
# apoyada en el suelo); el izquierdo es FK salvo cuando tiene que llegar a un sitio (el suelo, un héroe, el pecho).

PUNO_I = dedos("_i", 70, 95, 65)                       # la garra cerrada en puño
GARRA_ABIERTA_I = dedos("_i", -8, -6, -10, abrir=18)
GARRA_CLAVADA_I = dedos("_i", -4, 6, -6, abrir=8)      # las garras rectas, clavadas en la tierra
MANO_I_REPOSO = cola_h("antebrazo_i")                  # dónde está el control de cada mano (la muñeca)
MANO_D_REPOSO = cola_h("antebrazo_d")
MANO_D_IDLE = Vector((-3.25, -2.55, 4.25))             # la muñeca derecha en reposo (se ajusta: la punta del bastón al suelo)


def mano(l, destino):
    """Desplazamiento del control de una mano para que la muñeca vaya a «destino» (metros, ejes de Blender)."""
    base = MANO_I_REPOSO if l == "_i" else MANO_D_REPOSO
    return {"loc:ctrl_mano" + l: tuple(estirar(destino) - estirar(base))}


def baston_hacia(mano_w, dx=-0.2, dy=-0.3, dz=7.0):
    """La mira del bastón (a dónde apunta su cabeza) respecto de la muñeca derecha."""
    return {"loc:ctrl_baston": tuple(estirar(mano_w) + Vector((dx, dy, dz)) - estirar(cabeza_h("ctrl_baston")))}


def mano_baston(destino, dx=-0.2, dy=-0.3, dz=7.0):
    return mez({"ik:_d": 1.0}, mano("_d", destino), baston_hacia(destino, dx, dy, dz))


def ojo_mira(dx=0.0, dz=0.0):
    return {"loc:ctrl_ojo": (dx, 0.0, dz)}


def ajustar_baston():
    """Sube o baja la mano del reposo para que la punta del bastón quede apoyada (8 cm dentro de la tierra)."""
    for _ in range(8):
        REPOSO.update(mano_baston(MANO_D_IDLE))
        poner_pose(REPOSO)
        pb = ARM.pose.bones["baston"]
        z = (pb.matrix @ Matrix.Translation((0, -4.1, 0))).translation.z
        MANO_D_IDLE.z -= z + 0.08
    REPOSO.update(mano_baston(MANO_D_IDLE))
    ENFADO.update(mano_baston(MANO_D_IDLE))
    return round(MANO_D_IDLE.z, 3)


def c_idle():
    c = Clip("idle", 4.0, bucle=True)
    mira = [(0, 0), (0, 0), (1.6, -0.4), (1.6, -0.4), (-0.9, 0.2), (0, 0)]
    for i, (t, k) in enumerate(((0.0, 0.0), (1.0, 0.55), (1.7, 1.0), (2.6, 0.7), (3.3, 0.3), (4.0, 0.0))):
        p = respira(REPOSO, k)
        p.update(ojo_mira(*mira[i]))
        cab = p["cabeza"]
        p["cabeza"] = (cab[0], cab[1], cab[2] + mira[i][0] * 2.0)
        if i == 2:
            p.update(dedos("_i", 22, 26, 14, abrir=2))
        c.k(t, p)
    return c


def c_idle_angry():
    c = Clip("idle_angry", 2.0, bucle=True, viento=1.4)
    for t, k in ((0.0, 0.0), (0.7, 1.0), (1.4, 0.4), (2.0, 0.0)):
        p = respira(ENFADO, k, 1.8)
        if t == 0.7:
            p.update(dedos("_i", 10, 14, 4, abrir=14))
            p["mandibula"] = (16, 0, 0)
        c.k(t, p)
    return c


def pose_ruge(base=None):
    return mez(base or REPOSO, L(loc_pelvis=(0, 0.0, -0.08)), tronco(-2, -4, -7, -11, -14, -12, -18),
               {"hombro_i": (0, 0, 6), "brazo_i": (14, -50, 0), "antebrazo_i": (-24, 0, -12), "muneca_i": (10, 0, 0),
                "mandibula": (38, 0, 0), "luz": 2.4, "nucleo_esc": 1.16},
               GARRA_ABIERTA_I, mano_baston(MANO_D_IDLE + Vector((-0.5, -0.3, 1.2)), dx=-1.6, dy=-0.6))


def c_roar():
    c = Clip("roar", 3.0, temblor=0.05)
    agacha = mez(REPOSO, L(loc_pelvis=(0, 0.1, -0.5)), tronco(10, 10, 12, 14, 4, 6, 10),
                 {"brazo_i": (-12, 10, 0), "antebrazo_i": (-38, 0, -6)}, dedos("_i", 40, 50, 30), {"luz": 1.3, "mandibula": (2, 0, 0)})
    ruge = pose_ruge()
    c.k(0.0, REPOSO).k(0.45, agacha).k(0.85, agacha, golpe=True).k(1.05, ruge)
    for i, t in enumerate((1.25, 1.45, 1.65, 1.85, 2.05)):
        p = dict(ruge)
        s = 1 if i % 2 == 0 else -1
        p["cabeza"] = (ruge["cabeza"][0] + 1.5 * s, 0, 2.5 * s)
        p["mandibula"] = (36 + 3 * s, 0, 0)
        c.k(t, p)
    baja = mez(ruge, tronco(0, 0, -2, -4, -6, -6, -6), {"mandibula": (20, 0, 0), "luz": 1.6})
    c.k(2.35, baja).k(3.0, REPOSO)
    c.ev("rugido", 1.05).ev("fin_rugido", 2.35)
    return c


def c_atk_puno():
    """1 · Puño del Bosque Primordial: alza la garra cerrada (aviso que se sostiene) y la estrella contra el suelo
    delante (IK: la muñeca llega a un punto fijo del suelo)."""
    c = Clip("atk_puno", 2.6)
    sube = mez(REPOSO, tronco(2, 2, 2, 0, -6, -6, -4, giro=10), {"brazo_i": (-70, -22, 0), "antebrazo_i": (-60, 0, 0)}, PUNO_I,
               {"luz": 1.3})
    arriba = mez(REPOSO, L(loc_pelvis=(0, 0.2, -0.32)), tronco(-2, -4, -6, -9, -10, -8, -4, giro=16),
                 {"hombro_i": (0, 0, 8), "brazo_i": (-160, -14, 10), "antebrazo_i": (-48, 0, 0), "muneca_i": (-12, 0, 0)},
                 PUNO_I, {"luz": 1.7, "mandibula": (14, 0, 0)}, ojo_mira(0.6, -2.0))
    tope = mez(arriba, {"brazo_i": (-168, -14, 12)}, tronco(-3, -5, -7, -11, -12, -9, -5, giro=18), {"luz": 1.9})
    golpe = mez(REPOSO, L(loc_pelvis=(0, -0.45, -1.05), ik_i=1.0), tronco(14, 14, 14, 12, -6, -6, 2, giro=-10),
                {"brazo_i": (-55, -5, 0), "antebrazo_i": (-20, 0, 0), "muneca_i": (-35, 0, 0)}, PUNO_I,
                mano("_i", (2.3, -4.6, 2.0)), {"luz": 2.2, "mandibula": (26, 0, 0)}, ojo_mira(0.4, -3.0),
                L(loc_ctrl_pie_i=(0.0, -0.5, 0.0)))
    rebote = mez(golpe, L(loc_pelvis=(0, -0.4, -0.95)), mano("_i", (2.3, -4.55, 2.15)), {"luz": 1.8})
    vuelve = mez(REPOSO, L(loc_pelvis=(0, -0.1, -0.45), ik_i=0.35), tronco(8, 8, 8, 8, -6, -6, -2),
                 {"brazo_i": (-30, -6, 0), "antebrazo_i": (-30, 0, 0)}, mano("_i", (2.6, -3.6, 3.0)), dedos("_i", 30, 40, 20),
                 L(loc_ctrl_pie_i=(0.0, -0.25, 0.0)))
    c.k(0.0, REPOSO).k(0.4, sube).k(0.9, arriba).k(1.25, tope, golpe=True).k(1.5, golpe).k(1.72, rebote).k(2.15, vuelve)
    c.k(2.6, REPOSO)
    c.ev("aviso", 0.9).ev("impacto", 1.5)
    return c


# ---------------------------------------------------------------- andar y girar

ZANCADA = 2.0           # metros por paso (el juego desplaza al modelo a ZANCADA / medio ciclo)
CICLO_ANDAR = 2.4


def c_walk():
    c = Clip("walk", CICLO_ANDAR, bucle=True)
    for i in range(13):
        t = i * CICLO_ANDAR / 12
        p_ = (t / CICLO_ANDAR) % 1.0
        pose = dict(REPOSO)
        for l, desfase in (("_i", 0.0), ("_d", 0.5)):
            q = (p_ + desfase) % 1.0
            if q < 0.5:                                     # apoyado: el pie va hacia atrás bajo el cuerpo
                y, z, pitch = -ZANCADA / 2 + ZANCADA * (q / 0.5), 0.0, 0.0
            else:                                           # en el aire: se alza y vuelve adelante
                u = (q - 0.5) / 0.5
                e = u * u * (3 - 2 * u)
                y, z, pitch = ZANCADA / 2 - ZANCADA * e, 0.75 * math.sin(math.pi * u), 18 * math.sin(math.pi * u)
            pose["loc:ctrl_pie" + l] = (0.0, y, z)
            pose["ctrl_pie" + l] = (-pitch if z > 0 else 0.0, 0, 0)
        bote = abs(math.sin(2 * math.pi * p_))
        pose["loc:pelvis"] = (0.2 * math.sin(2 * math.pi * p_), 0.05, -0.42 + 0.26 * bote)
        pose.update(tronco(7, 6, 6, 6, -8, -6, -6 - 3 * bote, giro=6 * math.cos(2 * math.pi * p_)))
        pose["brazo_i"] = (-6 + 14 * math.cos(2 * math.pi * p_), 4, 0)
        pose["antebrazo_i"] = (-18 - 8 * max(0.0, -math.cos(2 * math.pi * p_)), 0, -4)
        man = MANO_D_IDLE + Vector((0.0, -0.55 * math.cos(2 * math.pi * p_), 0.3 * max(0.0, math.cos(2 * math.pi * p_))))
        pose.update(mano_baston(man, dy=-0.3 - 0.5 * math.cos(2 * math.pi * p_)))
        c.k(t, pose)
    c.ev("paso_d", 0.0).ev("paso_i", CICLO_ANDAR / 2)
    return c


def c_turn(nombre, s):
    """Giro en el sitio de 45° (s = +1 a su izquierda, −1 a la derecha) en dos pasos: primero el pie del lado del giro y
    luego el otro; los pies apoyados no patinan (se calcula su sitio en el mundo mientras la raíz gira). El juego suma
    los 45° al nodo al acabar (el clip termina en el reposo girado)."""
    c = Clip(nombre, 1.6)
    ang = math.radians(45.0 * s)
    primero, segundo = ("_i", "_d") if s > 0 else ("_d", "_i")
    fases = {primero: (0.2, 0.75), segundo: (0.7, 1.25)}
    rot = lambda a: Matrix.Rotation(a, 3, 'Z')
    for i in range(17):
        t = i * 0.1
        u = suave(0.15, 1.35, t)
        th = ang * u
        pose = dict(REPOSO)
        pose["raiz"] = (0, 0, math.degrees(th))
        lift = 0.0
        for l in ("_i", "_d"):
            rest = cabeza_h("ctrl_pie" + l)
            off0 = Vector(REPOSO.get("loc:ctrl_pie" + l, (0, 0, 0)))
            ini = rest + off0
            fin = rot(ang) @ (rest + off0)
            a, b = fases[l]
            if t <= a:
                w, yaw, h = ini, 0.0, 0.0
            elif t >= b:
                w, yaw, h = fin, ang, 0.0
            else:
                k = (t - a) / (b - a)
                k = k * k * (3 - 2 * k)
                w, yaw, h = ini.lerp(fin, k), ang * k, 0.6 * math.sin(math.pi * k)
                lift = max(lift, h)
            off = rot(-th) @ (w + Vector((0, 0, h))) - rest
            pose["loc:ctrl_pie" + l] = tuple(off)
            pose["ctrl_pie" + l] = (0, 0, math.degrees(yaw - th))
        pose["loc:pelvis"] = (0, 0.05, -0.18 - 0.25 * lift)
        pose.update(tronco(4, 5, 6, 6, -8, -6, -5, giro=14 * s * math.sin(math.pi * min(1.0, t / 1.2))))
        c.k(t, pose)
    c.ev("paso_1", 0.75).ev("paso_2", 1.25)
    return c


# ---------------------------------------------------------------- recibir golpes

def c_hit_light():
    c = Clip("hit_light", 0.7)
    golpe = mez(REPOSO, L(loc_pelvis=(0, 0.18, -0.22)), tronco(1, 0, -2, -5, -6, -6, -14), {"mandibula": (16, 0, 0), "luz": 1.5},
                {"brazo_i": (4, -10, 0)}, dedos("_i", 4, 6, 0, abrir=10))
    c.k(0.0, REPOSO, golpe=True).k(0.12, golpe).k(0.3, mez(golpe, tronco(3, 3, 3, 2, -6, -6, -6))).k(0.7, REPOSO)
    c.ev("golpe", 0.04)
    return c


def c_hit_heavy():
    c = Clip("hit_heavy", 1.3, temblor=0.03)
    atras = mez(REPOSO, L(loc_pelvis=(0, 0.55, -0.35)), tronco(-6, -7, -8, -10, -8, -8, -18),
                {"brazo_i": (10, -38, 0), "antebrazo_i": (-30, 0, 0), "mandibula": (26, 0, 0), "luz": 1.9}, GARRA_ABIERTA_I,
                L(loc_ctrl_pie_d=(0, 0.45, 0.45)))
    planta = mez(atras, L(loc_pelvis=(0, 0.45, -0.5), loc_ctrl_pie_d=(0, 0.9, 0.0)), tronco(2, 2, 2, 0, -6, -6, -8),
                 {"mandibula": (12, 0, 0), "luz": 1.4})
    vuelve = mez(REPOSO, L(loc_pelvis=(0, 0.2, -0.32), loc_ctrl_pie_d=(0, 0.45, 0.4)))
    c.k(0.0, REPOSO, golpe=True).k(0.15, atras).k(0.5, planta).k(0.72, planta).k(0.9, vuelve).k(1.3, REPOSO)
    c.ev("golpe", 0.04).ev("pisada", 0.5)
    return c


def c_stagger():
    c = Clip("stagger", 2.4, temblor=0.06)
    atras = mez(REPOSO, L(loc_pelvis=(0, 0.4, -0.3)), tronco(-4, -5, -6, -8, -8, -8, -14), {"mandibula": (20, 0, 0)})
    hunde = mez(REPOSO, L(loc_pelvis=(0, -0.15, -1.45), ik_i=1.0), tronco(16, 14, 12, 10, 6, 6, 10),
                mano("_i", (2.7, -3.0, 1.35)), GARRA_CLAVADA_I, {"muneca_i": (-30, 0, 0), "mandibula": (10, 0, 0), "luz": 0.6,
                                                               "nucleo_esc": 0.95})
    tiembla = mez(hunde, L(loc_pelvis=(0, -0.1, -1.35)), {"luz": 1.2})
    sube = mez(REPOSO, L(loc_pelvis=(0, 0.0, -0.7), ik_i=0.4), tronco(10, 8, 8, 6, -6, -6, -4), mano("_i", (2.9, -2.4, 2.4)))
    c.k(0.0, REPOSO, golpe=True).k(0.2, atras).k(0.6, hunde, golpe=False).k(0.9, hunde).k(1.15, tiembla).k(1.4, hunde)
    c.k(1.85, sube).k(2.4, REPOSO)
    c.ev("golpe", 0.04).ev("apoyo", 0.75)
    return c


# ---------------------------------------------------------------- fases y muerte

def c_phase_transition():
    c = Clip("phase_transition", 3.6, temblor=0.06)
    nc = centro_nucleo()
    agarra = mez(REPOSO, L(loc_pelvis=(0, 0.1, -0.65), ik_i=1.0), tronco(12, 12, 12, 10, 4, 6, 14),
                 mano("_i", nc + Vector((0.55, -1.2, 0.6))), dedos("_i", 40, 55, 30), {"muneca_i": (-40, 30, 0), "luz": 0.5,
                                                                                   "mandibula": (12, 0, 0)})
    c.k(0.0, REPOSO).k(0.5, agarra)
    for t, luz, ne in ((0.8, 2.6, 1.15), (1.05, 0.4, 0.95), (1.3, 3.0, 1.25), (1.55, 0.6, 1.0)):
        c.k(t, mez(agarra, {"luz": luz, "nucleo_esc": ne}, L(loc_pelvis=(0, 0.1, -0.65 - 0.25 * (t - 0.5)))))
    hondo = mez(agarra, L(loc_pelvis=(0, 0.15, -1.0)), tronco(16, 16, 14, 12, 6, 8, 18), {"luz": 2.0, "nucleo_esc": 1.2})
    c.k(1.8, hondo, golpe=True)
    ruge = mez(pose_ruge(ENFADO), {"luz": 3.0, "nucleo_esc": 1.3})
    c.k(2.05, ruge)
    for i, t in enumerate((2.25, 2.45, 2.65, 2.85)):
        p = dict(ruge)
        s_ = 1 if i % 2 == 0 else -1
        p["cabeza"] = (ruge["cabeza"][0] + 1.5 * s_, 0, 2.5 * s_)
        c.k(t, p)
    c.k(3.6, ENFADO)
    c.ev("agarra", 0.5).ev("cambio", 2.05).ev("rugido", 2.1)
    return c


def c_death():
    c = Clip("death", 4.6, temblor=0.04)
    atras = mez(REPOSO, L(loc_pelvis=(0, 0.35, -0.3)), tronco(-4, -5, -6, -8, -8, -8, -14), {"mandibula": (22, 0, 0)})
    grito = mez(REPOSO, L(loc_pelvis=(0, 0.1, -0.5)), tronco(-2, -3, -5, -8, -12, -10, -22),
                {"mandibula": (34, 0, 0), "luz": 2.0, "brazo_i": (6, -30, 0), "antebrazo_i": (-30, 0, 0)}, GARRA_ABIERTA_I)
    suelta = {"ik:_d": 0.0, "brazo_d": lado("_d", (-10, -8, 0)), "antebrazo_d": lado("_d", (-20, 0, 0)), **dedos("_d", 10, 10, 10),
              "loc:ctrl_baston": tuple(Vector((-9.0, -2.0, 1.0)) - cabeza_h("ctrl_baston"))}
    rodillas = mez(REPOSO, L(loc_pelvis=(0, -0.1, -2.35)), tronco(10, 8, 6, 6, 8, 8, 12),
                   {"brazo_i": (-8, 6, 0), "antebrazo_i": (-10, 0, 0), "mandibula": (14, 0, 0), "luz": 1.0, "nucleo_esc": 0.95},
                   dedos("_i", 20, 20, 10), suelta)
    cae = mez(rodillas, L(loc_pelvis=(0, -1.2, -3.0)), {"pelvis": (40, 0, 0)}, tronco(16, 14, 10, 6, -10, -10, -14),
              {"brazo_i": (-120, -25, 0), "antebrazo_i": (-10, 0, 0), "brazo_d": lado("_d", (-110, -30, 0)),
               "luz": 0.35, "nucleo_esc": 0.9}, GARRA_ABIERTA_I)
    suelo = mez(cae, L(loc_pelvis=(0, -1.6, -3.25)), {"pelvis": (52, 0, 0)}, tronco(18, 16, 12, 6, -12, -12, -16),
                {"brazo_i": (-150, -30, 0), "brazo_d": lado("_d", (-140, -35, 0)), "luz": 0.0, "nucleo_esc": 0.85,
                 "mandibula": (20, 0, 0)})
    c.k(0.0, REPOSO, golpe=True).k(0.3, atras).k(0.9, grito).k(1.5, rodillas).k(2.4, rodillas).k(3.3, cae, golpe=True)
    c.k(3.75, suelo).k(4.0, mez(suelo, L(loc_pelvis=(0, -1.55, -3.15)))).k(4.6, suelo)
    c.ev("golpe", 0.04).ev("grito", 0.9).ev("rodillas", 1.5).ev("caida", 3.75)
    return c


# ---------------------------------------------------------------- los ataques

def c_atk_raices():
    """2 · Raíces Devoradoras: alza la garra y la clava en la tierra; las raíces corren bajo el suelo y brotan bajo los
    objetivos («impacto», cuando ya llevan un rato bajo tierra); la garra se retuerce dentro y la arranca."""
    c = Clip("atk_raices", 2.8, temblor=0.02)
    alza = mez(REPOSO, L(loc_pelvis=(0, 0.15, -0.3)), tronco(-2, -3, -5, -8, -10, -8, -8),
               {"brazo_i": (-125, -24, 0), "antebrazo_i": (-35, 0, 0), "luz": 1.6}, GARRA_ABIERTA_I, ojo_mira(0, -2.0))
    clava = mez(REPOSO, L(loc_pelvis=(0, -0.35, -1.15), ik_i=1.0), tronco(16, 15, 14, 12, -6, -6, 4),
                mano("_i", (2.1, -4.2, 0.8)), GARRA_CLAVADA_I, {"muneca_i": (-20, 0, 0), "luz": 2.2, "mandibula": (20, 0, 0)},
                ojo_mira(0, -3.0), L(loc_ctrl_pie_i=(0.0, -0.4, 0.0)))
    retuerce = mez(clava, {"muneca_i": (-20, 0, 14), "luz": 2.6}, mano("_i", (2.15, -4.15, 0.7)))
    arranca = mez(REPOSO, L(loc_pelvis=(0, -0.1, -0.5), ik_i=0.3), tronco(6, 6, 6, 6, -6, -6, -4),
                  mano("_i", (2.8, -3.0, 2.6)), dedos("_i", 30, 40, 20))
    c.k(0.0, REPOSO).k(0.6, alza).k(1.05, alza, golpe=True).k(1.35, clava).k(1.6, retuerce).k(1.85, clava).k(2.1, retuerce)
    c.k(2.35, arranca).k(2.8, REPOSO)
    c.ev("aviso", 0.6).ev("hundir", 1.35).ev("impacto", 1.85)
    return c


def c_atk_aliento():
    """3 · Aliento de la Putrefacción: toma aire (el pecho se hincha, el núcleo brilla), se inclina y echa el cono de
    esporas por la boca abierta («aliento_inicio» → «aliento_fin»; el daño, en «impacto»)."""
    c = Clip("atk_aliento", 3.4, temblor=0.02)
    aire = mez(REPOSO, L(loc_pelvis=(0, 0.25, -0.2)), tronco(-2, -3, -6, -10, -10, -8, -14),
               {"brazo_i": (8, -20, 0), "antebrazo_i": (-26, 0, 0), "mandibula": (6, 0, 0), "luz": 1.7, "nucleo_esc": 1.15},
               dedos("_i", 30, 40, 20))
    echa = mez(REPOSO, L(loc_pelvis=(0, -0.2, -0.45)), tronco(10, 10, 12, 12, 10, 8, 16),
               {"brazo_i": (16, -32, 0), "antebrazo_i": (-30, 0, 0), "mandibula": (42, 0, 0), "luz": 2.0, "nucleo_esc": 1.05},
               GARRA_ABIERTA_I, ojo_mira(0, -3.0))
    c.k(0.0, REPOSO).k(0.9, aire).k(1.2, aire, golpe=True).k(1.45, echa)
    for i, t in enumerate((1.7, 1.95, 2.2, 2.45)):
        p = dict(echa)
        s_ = 1 if i % 2 == 0 else -1
        p["cabeza"] = (echa["cabeza"][0], 0, 4 * s_)
        p["mandibula"] = (42 + 2 * s_, 0, 0)
        c.k(t, p)
    c.k(2.7, echa).k(3.0, mez(echa, {"mandibula": (12, 0, 0), "luz": 1.3})).k(3.4, REPOSO)
    c.ev("aviso", 0.9).ev("aliento_inicio", 1.45).ev("impacto", 1.8).ev("aliento_fin", 2.7)
    return c


def c_atk_guadana():
    """4 · Guadaña de Raíces: le brota una hoja curva del antebrazo izquierdo (el hueso «guadana» crece), se carga
    girando y barre en horizontal de su izquierda a su derecha; la hoja vuelve a meterse en el brazo."""
    c = Clip("atk_guadana", 2.4)
    carga = mez(REPOSO, L(loc_pelvis=(0, 0.1, -0.5), esc_guadana=1.0), tronco(2, 2, 2, 0, -8, -6, -4, giro=28),
                {"hombro_i": (0, 0, 6), "brazo_i": (14, -72, 0), "antebrazo_i": (-22, 0, 0), "luz": 1.6}, PUNO_I,
                L(loc_ctrl_pie_i=(0.1, 0.35, 0.0)))
    medio = mez(REPOSO, L(loc_pelvis=(0, -0.25, -0.7), esc_guadana=1.0), tronco(8, 8, 8, 6, -8, -6, 0, giro=0),
                {"brazo_i": (-84, -14, 0), "antebrazo_i": (-8, 0, 0), "luz": 2.2, "mandibula": (20, 0, 0)}, PUNO_I,
                L(loc_ctrl_pie_i=(0.0, -0.3, 0.0)))
    sigue = mez(REPOSO, L(loc_pelvis=(0, -0.2, -0.65), esc_guadana=1.0), tronco(8, 8, 8, 6, -8, -6, 0, giro=-30),
                {"brazo_i": (-80, 44, 0), "antebrazo_i": (-14, 0, 0), "luz": 1.8}, PUNO_I, L(loc_ctrl_pie_i=(0.0, -0.3, 0.0)))
    c.k(0.0, REPOSO).k(0.2, mez(REPOSO, L(esc_guadana=0.01))).k(0.55, carga).k(0.85, carga, golpe=True).k(1.05, medio)
    c.k(1.3, sigue).k(1.65, sigue).k(1.95, mez(REPOSO, L(esc_guadana=0.3, loc_pelvis=(0, -0.1, -0.35)), tronco(5, 5, 5, 5, -8, -6, -5, giro=-10)))
    c.k(2.1, mez(REPOSO, L(esc_guadana=0.01))).k(2.4, REPOSO)
    c.ev("crece", 0.2).ev("aviso", 0.55).ev("impacto", 1.05).ev("recoge", 1.95)
    return c


def c_atk_ojo():
    """5 · El Ojo del Juicio: se yergue, el ojo se carga (la luz sube despacio: preparación visible) y baja la cabeza
    hacia el objetivo para lanzar el rayo desde el ojo («rayo_inicio» → «rayo_fin»; el daño, en «impacto»)."""
    c = Clip("atk_ojo", 3.4, temblor=0.015)
    erguido = mez(REPOSO, L(loc_pelvis=(0, 0.1, -0.02)), tronco(-2, -3, -4, -6, -10, -8, -12),
                  {"brazo_i": (5, -30, 0), "antebrazo_i": (-24, 0, 0), "luz": 1.5}, GARRA_ABIERTA_I, ojo_mira(0, 1.0))
    carga = mez(erguido, {"luz": 3.2, "mandibula": (8, 0, 0)}, tronco(-2, -3, -5, -8, -12, -10, -16))
    apunta = mez(erguido, tronco(4, 4, 4, 4, 4, 6, 14), {"luz": 3.4}, ojo_mira(0, -3.2))
    c.k(0.0, REPOSO).k(0.6, erguido).k(1.2, mez(erguido, {"luz": 2.0})).k(1.75, carga).k(2.0, apunta)
    for i, t in enumerate((2.2, 2.4, 2.6, 2.8)):
        p = dict(apunta)
        p["cabeza"] = (apunta["cabeza"][0] + (1.5 if i % 2 else -1.0), 0, 0)
        c.k(t, p)
    c.k(3.0, mez(erguido, {"luz": 1.2})).k(3.4, REPOSO)
    c.ev("aviso", 0.6).ev("carga", 1.2).ev("rayo_inicio", 2.0).ev("impacto", 2.2).ev("rayo_fin", 2.8)
    return c


def c_atk_llamada():
    """6 · Llamada de los Condenados: alza el bastón con la derecha y lo clava en la tierra («impacto»); en «invocar»
    salen los condenados (el combate los añade, con tope)."""
    c = Clip("atk_llamada", 3.0)
    alto = MANO_D_IDLE + Vector((0.6, -0.5, 4.0))
    clav = MANO_D_IDLE + Vector((0.8, -1.0, -0.1))
    alza = mez(REPOSO, L(loc_pelvis=(0, 0.15, -0.15)), tronco(-3, -4, -6, -8, -10, -8, -14), mano_baston(alto, dx=0.1, dy=-0.2),
               {"luz": 1.8, "mandibula": (16, 0, 0), "brazo_i": (6, -30, 0)}, GARRA_ABIERTA_I)
    clava = mez(REPOSO, L(loc_pelvis=(0, -0.3, -0.85)), tronco(10, 10, 10, 8, -4, -4, 8), mano_baston(clav, dx=0.0, dy=0.0),
                {"luz": 2.4, "mandibula": (24, 0, 0), "brazo_i": (-6, -14, 0)}, dedos("_i", 30, 40, 20))
    c.k(0.0, REPOSO).k(0.7, alza).k(1.15, mez(alza, mano_baston(alto + Vector((0, 0, 0.3)), dx=0.1, dy=-0.2)), golpe=True)
    c.k(1.45, clava).k(1.6, mez(clava, L(loc_pelvis=(0, -0.3, -0.9)))).k(2.3, clava).k(3.0, REPOSO)
    c.ev("aviso", 0.7).ev("impacto", 1.45).ev("invocar", 1.8)
    return c


def c_atk_abrazo():
    """7 · Abrazo de la Muerte: alarga la garra, agarra («agarre»), alza a la presa ante su cara, aprieta dos veces
    («apretar_1», «apretar_2»: entre una y otra puede soltarse) y la arroja («soltar»)."""
    c = Clip("atk_abrazo", 3.8, temblor=0.015)
    atras = mez(REPOSO, L(loc_pelvis=(0, 0.2, -0.3)), tronco(-2, -2, -4, -4, -8, -6, -6, giro=12),
                {"brazo_i": (24, -42, 0), "antebrazo_i": (-30, 0, 0), "luz": 1.5}, GARRA_ABIERTA_I, ojo_mira(0.5, -2.5))
    agarra = mez(REPOSO, L(loc_pelvis=(0, -0.6, -0.9), ik_i=1.0), tronco(14, 14, 12, 10, -4, -4, 6, giro=-8),
                 mano("_i", (1.2, -5.5, 3.0)), GARRA_ABIERTA_I, {"muneca_i": (-20, 0, 0), "luz": 1.8, "mandibula": (18, 0, 0)},
                 ojo_mira(0, -3.0), L(loc_ctrl_pie_i=(0, -0.45, 0)))
    cierra = mez(agarra, dedos("_i", 58, 72, 52))
    alza = mez(REPOSO, L(loc_pelvis=(0, -0.2, -0.35), ik_i=1.0), tronco(2, 2, 2, 0, -6, -6, 2), mano("_i", (1.0, -4.3, 6.3)),
               dedos("_i", 58, 72, 52), {"muneca_i": (-60, 0, 0), "luz": 1.6, "mandibula": (12, 0, 0)}, ojo_mira(0.3, -0.5))
    cara = mez(alza, mano("_i", (0.8, -3.7, 7.1)), tronco(2, 2, 2, 0, 0, 2, 10), {"mandibula": (24, 0, 0)}, ojo_mira(0.2, -1.5))
    aprieta = mez(cara, dedos("_i", 80, 100, 72), {"luz": 2.2, "mandibula": (30, 0, 0)}, L(loc_pelvis=(0, -0.2, -0.45)))
    afloja = mez(cara, dedos("_i", 62, 78, 56))
    lanza = mez(REPOSO, L(loc_pelvis=(0, -0.3, -0.5), ik_i=1.0), tronco(8, 8, 8, 6, -6, -6, 2, giro=14), mano("_i", (3.2, -4.2, 4.0)),
                GARRA_ABIERTA_I, {"luz": 1.6})
    c.k(0.0, REPOSO).k(0.5, atras).k(0.75, atras, golpe=True).k(1.1, agarra).k(1.2, cierra).k(1.6, alza).k(1.95, cara)
    c.k(2.2, aprieta).k(2.45, afloja).k(2.8, aprieta).k(3.0, afloja).k(3.15, lanza).k(3.8, REPOSO)
    c.ev("aviso", 0.75).ev("agarre", 1.15).ev("apretar_1", 2.2).ev("apretar_2", 2.8).ev("soltar", 3.15)
    return c


# ---------------------------------------------------------------- el Réquiem del Bosque Eterno (fase 3) y la ventana

def pose_carga_requiem():
    return mez(REPOSO, L(loc_pelvis=(0, -0.1, -1.85), ik_i=1.0), tronco(18, 16, 14, 10, -6, -6, 6),
               mano("_i", (2.25, -3.7, -0.5)), GARRA_CLAVADA_I, mano_baston(Vector((-2.3, -3.7, 2.6)), dx=-0.1, dy=-0.2),
               {"muneca_i": (-20, 0, 0), "luz": 2.6, "nucleo_esc": 1.2, "mandibula": (14, 0, 0)}, ojo_mira(0, -1.5))


def pose_vulnerable():
    return mez(REPOSO, L(loc_pelvis=(0, 0.15, -2.05), ik_i=1.0), tronco(3, 2, 0, -2, 6, 8, 14),
               mano("_i", (3.0, -1.9, 1.25)), dedos("_i", 10, 14, 6), {"muneca_i": (-30, 0, 0)},
               mano_baston(Vector((-2.7, -2.8, 2.1)), dx=-6.0, dy=1.0, dz=-1.0),
               {"luz": 0.55, "nucleo_esc": 0.97, "mandibula": (18, 0, 0)}, ojo_mira(0, -2.0))


def c_requiem_inicio():
    c = Clip("requiem_inicio", 2.4, temblor=0.03)
    ruge = mez(pose_ruge(ENFADO), {"luz": 2.0})
    alza = mez(ENFADO, L(loc_pelvis=(0, 0.1, -0.2)), tronco(-3, -4, -6, -10, -12, -10, -16),
               {"brazo_i": (-150, -22, 0), "antebrazo_i": (-30, 0, 0), "luz": 2.4, "mandibula": (30, 0, 0)}, GARRA_ABIERTA_I,
               mano_baston(MANO_D_IDLE + Vector((0.6, -0.4, 3.6)), dx=0.1, dy=-0.2))
    c.k(0.0, ENFADO).k(0.5, ruge).k(1.05, alza).k(1.45, alza, golpe=True).k(1.8, pose_carga_requiem())
    c.k(2.4, pose_carga_requiem())
    c.ev("aviso", 0.5).ev("hundir", 1.8).ev("raices_arena", 2.0)
    return c


def c_requiem_carga():
    c = Clip("requiem_carga", 2.0, bucle=True, temblor=0.025)
    base = pose_carga_requiem()
    for t, luz, ne, dz in ((0.0, 2.6, 1.2, 0.0), (0.5, 3.5, 1.32, 0.12), (1.0, 2.6, 1.2, 0.0), (1.5, 3.5, 1.32, 0.12), (2.0, 2.6, 1.2, 0.0)):
        c.k(t, mez(base, {"luz": luz, "nucleo_esc": ne}, L(loc_pelvis=(0, -0.1, -1.85 + dz))))
    c.ev("latido_1", 0.5).ev("latido_2", 1.5)
    return c


def c_requiem_golpe():
    c = Clip("requiem_golpe", 3.0, temblor=0.06)
    base = pose_carga_requiem()
    tensa = mez(base, L(loc_pelvis=(0, -0.1, -2.05)), {"luz": 3.8, "nucleo_esc": 1.38})
    estalla = mez(pose_ruge(ENFADO), {"brazo_i": (20, -62, 0), "luz": 4.0, "nucleo_esc": 1.4, "mandibula": (45, 0, 0)},
                  mano_baston(MANO_D_IDLE + Vector((-0.8, -0.4, 2.2)), dx=-2.2, dy=-0.4))
    c.k(0.0, base).k(0.35, tensa).k(0.45, tensa, golpe=True).k(0.65, estalla).k(0.85, estalla).k(1.2, mez(estalla, {"luz": 3.0}))
    c.k(1.45, mez(estalla, {"luz": 2.0, "mandibula": (30, 0, 0)}))
    c.k(2.0, mez(pose_vulnerable(), {"luz": 0.9}), golpe=True).k(2.25, mez(pose_vulnerable(), L(loc_pelvis=(0, 0.1, -2.15))))
    c.k(3.0, pose_vulnerable())
    c.ev("troncos", 0.6).ev("impacto", 0.85).ev("agotado", 2.0)
    return c


def c_vulnerable():
    c = Clip("vulnerable", 2.0, bucle=True, viento=0.6)
    v = pose_vulnerable()
    for t, dz, luz in ((0.0, 0.0, 0.55), (0.8, 0.12, 0.85), (1.3, 0.06, 0.4), (2.0, 0.0, 0.55)):
        c.k(t, mez(v, L(loc_pelvis=(0, 0.1, -2.05 + dz)), {"luz": luz}))
    return c


def c_vulnerable_fin():
    c = Clip("vulnerable_fin", 1.6)
    v = pose_vulnerable()
    empuja = mez(ENFADO, L(loc_pelvis=(0, 0.0, -1.1), ik_i=0.6), tronco(12, 10, 10, 8, -6, -6, 0), mano("_i", (2.9, -2.6, 2.2)),
                 {"luz": 1.0})
    c.k(0.0, v).k(0.7, empuja).k(1.6, ENFADO)
    c.ev("en_pie", 1.2)
    return c


def lista_clips():
    return [c_idle(), c_idle_angry(), c_walk(), c_turn("turn_left", 1), c_turn("turn_right", -1), c_roar(), c_hit_light(),
            c_hit_heavy(), c_stagger(), c_phase_transition(), c_death(), c_atk_puno(), c_atk_raices(), c_atk_aliento(),
            c_atk_guadana(), c_atk_ojo(), c_atk_llamada(), c_atk_abrazo(), c_requiem_inicio(), c_requiem_carga(),
            c_requiem_golpe(), c_vulnerable(), c_vulnerable_fin()]


BUCLES = []
POSES_FOTO = {}


def crear_clips(arm, resumen):
    global BUCLES
    resumen["mano_d_reposo_z"] = ajustar_baston()
    resumen["zancada_m"] = ZANCADA
    resumen["ciclo_andar_s"] = CICLO_ANDAR
    resumen["velocidad_andar_m_s"] = round(ZANCADA / (CICLO_ANDAR / 2), 4)
    resumen["giro_grados"] = 45.0
    solo = [x for x in os.environ.get("HUMBABA_CLIPS", "").split(",") if x]
    clips = [c for c in lista_clips() if not solo or c.nombre in solo]
    BUCLES = [c.nombre for c in clips if c.bucle]
    for c in clips:
        hornear(c)
    for c in clips:
        m = medir_clip(c)
        resumen["clips"][c.nombre] = {"duracion": round(c.dur, 4), "bucle": c.bucle, "eventos": c.eventos, "medidas": m}
        print("CLIP", c.nombre, c.dur, c.eventos, {k: v for k, v in m.items() if k != "puntos"})
    POSES_FOTO["reposo"] = REPOSO
    ARM.animation_data.action = None
    for t in ARM.animation_data.nla_tracks:
        t.mute = True
    return clips


def foto_deformaciones(sc, objs):
    """Poses extremas (frente y tres cuartos): brazos arriba y cruzados, rodillas muy dobladas, giro de tronco, boca
    abierta, puño cerrado y garra abierta: para ver codos, rodillas, hombros, cuello y manos."""
    c = CARPETA_FOTOS
    extremas = {
        "brazos_arriba": mez(REPOSO, {"brazo_i": (-170, -20, 0), "antebrazo_i": (-40, 0, 0)}, PUNO_I,
                             mano_baston(MANO_D_IDLE + Vector((0.6, -0.5, 4.0)), dx=0.1, dy=-0.2)),
        "agachado": mez(REPOSO, L(loc_pelvis=(0, 0.3, -2.0)), tronco(20, 18, 12, 8, -10, -10, -10)),
        "giro_y_boca": mez(REPOSO, tronco(4, 5, 6, 6, -8, -6, -15, giro=35), {"mandibula": (40, 0, 0), "brazo_i": (-80, 40, 0),
                                                                               "antebrazo_i": (-100, 0, 0)}, GARRA_ABIERTA_I),
        "zancada": mez(REPOSO, L(loc_pelvis=(0, 0.0, -0.8), loc_ctrl_pie_i=(0, -2.2, 0.0), loc_ctrl_pie_d=(0, 1.8, 0.0)),
                       tronco(10, 8, 6, 4, -8, -6, -5)),
    }
    rutas = []
    for nombre, pose in extremas.items():
        for vista, (pos, mira, esc) in (("frente", VISTAS["frente"]), ("tres_cuartos", VISTAS["tres_cuartos"])):
            rutas.append(foto(sc, os.path.join(c, "04_deform_%s_%s.png" % (nombre, vista)), pose=pose, pos=pos, mira=mira,
                              escala=esc, ancho=420, alto=520))
    hoja(rutas, os.path.join(c, "04_deformaciones_hoja.png"), 4)


def fotos_clips(sc, resumen):
    """Una hoja por clip: el principio, cada evento y el final, desde tres cuartos (la dirección de la cámara del
    combate) y la misma escala que las vistas."""
    c = CARPETA_FOTOS
    solo = [x for x in os.environ.get("HUMBABA_FOTOS", "").split(",") if x]
    for nombre, info in resumen["clips"].items():
        if solo and nombre not in solo:
            continue
        ts = [0.0] + sorted(set(info["eventos"].values())) + [info["duracion"]]
        extra = [info["duracion"] * f for f in (0.25, 0.5, 0.75)]
        ts = sorted(set(round(t, 3) for t in ts + extra))[:8]
        rutas = []
        for t in ts:
            rutas.append(foto(sc, os.path.join(c, "05_%s_%05.2f.png" % (nombre, t)), clip=nombre, seg=t,
                              pos=VISTAS["tres_cuartos"][0], mira=VISTAS["tres_cuartos"][1], escala=16.0, ancho=360, alto=440))
        hoja(rutas, os.path.join(c, "05_clip_%s.png" % nombre), 4)




principal()
