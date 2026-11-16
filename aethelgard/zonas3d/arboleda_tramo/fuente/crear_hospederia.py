# Arboleda Mítica, tramo «La escalera de la Hospedería» (EXPERIMENTAL, 16/11): el INTERIOR de la Hospedería del
# Peregrino [P] (docs/diseno/ciudades_y_lugares.md §2.3), para la técnica 2D pintada de la isla: este guion hace el
# modelo y le hornea la luz a la textura; después pruebas/herramientas/render_isla.gd lo renderiza con la MISMA cámara
# ortográfica a 38° y la MISMA luz que el fondo de Meshy, y preparar_isla.gd saca paso, suelo y tapa.
#
# Blender 5.2.3 en segundo plano, Cycles. Obra propia: ningún recurso descargado, de pago ni de la nube; sin Meshy ni
# Hunyuan3D. Determinista (semilla fija). Uso:
#   blender -b --factory-startup -P crear_hospederia.py -- <carpeta de salida> [--muestras N] [--res 2048]
# Salida: hospederia.glb (una sola malla, una textura con el color y la luz horneados) y hospederia_anclas.json.
#
# Coordenadas: las de Blender (x a la derecha, y hacia el FONDO de la sala, z arriba). En Godot (glTF, y arriba):
# X = x, Y = z, Z = -y. La cámara del render mira desde el frente (y negativa) y desde arriba.
# Escala: 84 px por metro en el render de 1536 px (Kael, de 100 px, cabe con muebles de tamaño normal).
#
# Qué hay (tres escalas, como la muestra de Oakhaven):
#   masa      suelo de tablas, muro del fondo con zócalo, pies derechos y viga, muros laterales cortados en diorama,
#             la escalera que sube a las camas de arriba (solo el arranque), camas con colchas de lino, mesa larga
#   elementos mostrador de Yedra con el libro de huéspedes, cántaro, faroles de peregrino, macetas, alfombra, arcones,
#             cortinas de lino recogidas, estante de tarros, bancos
#   menudo    pan de higo en la tabla, llaves colgadas, campanillas en la entrada, tazas, la escarpia del dibujo de Lumi
# Paleta (§2.3 :474-477): lima #A8D63A / #5FA82E, crema #E8DDBF con oro #E0A93A, cian #5FE0F0, cielo #8ED6FF, madera
# de miel. Mañana eterna: el sol entra por las ventanas del fondo.

import bpy
import bmesh
import json
import math
import os
import random
import sys

import numpy as np
from mathutils import Vector

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SALIDA = ARGS[0] if ARGS else os.path.join(os.path.dirname(__file__), "modelos")
MUESTRAS = int(ARGS[ARGS.index("--muestras") + 1]) if "--muestras" in ARGS else 160
RES = int(ARGS[ARGS.index("--res") + 1]) if "--res" in ARGS else 2048
random.seed(1609)

F = -0.127                     # el suelo, a la altura de las calles de la isla (render_isla.gd: SUELO_MIN..SUELO_MAX)
X0, X1 = -8.5, 8.5             # el interior
Y0, Y1 = -4.5, 4.5
ALTO = 3.6
GRUESO = 0.3


def hexc(h):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)


def nota(t):
    print("[hospederia] " + t, flush=True)


# ---------------------------------------------------------------- malla acumulada (una sola al final)

class Malla:
    def __init__(self):
        self.v = []
        self.f = []
        self.m = []
        self.mats = []

    def mat(self, nombre):
        if nombre not in self.mats:
            self.mats.append(nombre)
        return self.mats.index(nombre)

    def cara(self, pts, mat):
        b = len(self.v)
        self.v.extend(pts)
        self.f.append(list(range(b, b + len(pts))))
        self.m.append(self.mat(mat))

    def caja(self, c, s, mat, rz=0.0, caras="todas"):
        cx, cy, cz = c
        sx, sy, sz = s[0] / 2, s[1] / 2, s[2] / 2
        cs, sn = math.cos(rz), math.sin(rz)

        def P(x, y, z):
            return (cx + x * cs - y * sn, cy + x * sn + y * cs, cz + z)
        p = [P(-sx, -sy, -sz), P(sx, -sy, -sz), P(sx, sy, -sz), P(-sx, sy, -sz),
             P(-sx, -sy, sz), P(sx, -sy, sz), P(sx, sy, sz), P(-sx, sy, sz)]
        quads = {"abajo": (0, 3, 2, 1), "arriba": (4, 5, 6, 7), "frente": (0, 1, 5, 4), "fondo": (2, 3, 7, 6),
                 "izq": (3, 0, 4, 7), "der": (1, 2, 6, 5)}
        for k, q in quads.items():
            if caras != "todas" and k not in caras:
                continue
            self.cara([p[i] for i in q], mat)

    def cajamm(self, a, b, mat, **k):
        self.caja(((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, (a[2] + b[2]) / 2),
                  (abs(b[0] - a[0]), abs(b[1] - a[1]), abs(b[2] - a[2])), mat, **k)

    def cilindro(self, base, r, h, mat, n=10, r2=None, tapa=True):
        r2 = r if r2 is None else r2
        bx, by, bz = base
        b = len(self.v)
        for i in range(n):
            a = 2 * math.pi * i / n
            self.v.append((bx + r * math.cos(a), by + r * math.sin(a), bz))
        for i in range(n):
            a = 2 * math.pi * i / n
            self.v.append((bx + r2 * math.cos(a), by + r2 * math.sin(a), bz + h))
        mi = self.mat(mat)
        for i in range(n):
            j = (i + 1) % n
            self.f.append([b + i, b + j, b + n + j, b + n + i])
            self.m.append(mi)
        if tapa:
            self.f.append([b + n + i for i in range(n)])
            self.m.append(mi)

    def perfil(self, base, radios, mat, n=12):
        """Sólido de revolución: radios = [(r, z), ...] de abajo arriba (cántaros, tarros, macetas)."""
        bx, by, bz = base
        b = len(self.v)
        for r, z in radios:
            for i in range(n):
                a = 2 * math.pi * i / n
                self.v.append((bx + r * math.cos(a), by + r * math.sin(a), bz + z))
        mi = self.mat(mat)
        for k in range(len(radios) - 1):
            for i in range(n):
                j = (i + 1) % n
                self.f.append([b + k * n + i, b + k * n + j, b + (k + 1) * n + j, b + (k + 1) * n + i])
                self.m.append(mi)
        self.f.append([b + (len(radios) - 1) * n + i for i in range(n)])
        self.m.append(mi)

    def bola(self, c, r, mat, n=8, aplastar=1.0):
        cx, cy, cz = c
        b = len(self.v)
        filas = n // 2
        for k in range(filas + 1):
            th = math.pi * k / filas
            for i in range(n):
                a = 2 * math.pi * i / n
                self.v.append((cx + r * math.sin(th) * math.cos(a), cy + r * math.sin(th) * math.sin(a),
                               cz + r * math.cos(th) * aplastar))
        mi = self.mat(mat)
        for k in range(filas):
            for i in range(n):
                j = (i + 1) % n
                self.f.append([b + k * n + i, b + (k + 1) * n + i, b + (k + 1) * n + j, b + k * n + j])
                self.m.append(mi)


# ---------------------------------------------------------------- la sala

ANCLAS = {}


def ancla(nombre, p):
    """En coordenadas de GODOT (X, Y, Z) para el juego."""
    ANCLAS[nombre] = [round(p[0], 3), round(p[2], 3), round(-p[1], 3)]


def suelo(M):
    M.cajamm((X0 - GRUESO, Y0 - GRUESO, F - 0.18), (X1 + GRUESO, Y1 + GRUESO, F), "tablas")
    # umbral de piedra en la entrada y losas bajo el mostrador
    M.cajamm((-3.3, Y0 - GRUESO, F), (-1.9, Y0 + 0.05, F + 0.012), "piedra")


def ventana_hueco(M, x, ancho, z0, z1, y_muro):
    """Marco, alféizar, cruz y cortinas recogidas de una ventana abierta (el hueco lo deja el muro)."""
    t = 0.09
    M.cajamm((x - ancho / 2 - t, y_muro - 0.04, z0), (x - ancho / 2, y_muro + GRUESO, z1), "madera_osc")
    M.cajamm((x + ancho / 2, y_muro - 0.04, z0), (x + ancho / 2 + t, y_muro + GRUESO, z1), "madera_osc")
    M.cajamm((x - ancho / 2 - t, y_muro - 0.04, z1), (x + ancho / 2 + t, y_muro + GRUESO, z1 + t), "madera_osc")
    M.cajamm((x - ancho / 2 - 0.16, y_muro - 0.16, z0 - 0.07), (x + ancho / 2 + 0.16, y_muro + GRUESO, z0), "piedra")
    M.cajamm((x - 0.025, y_muro + 0.10, z0), (x + 0.025, y_muro + 0.15, z1), "madera_osc")       # parteluz
    M.cajamm((x - ancho / 2, y_muro + 0.10, (z0 + z1) / 2 + 0.2), (x + ancho / 2, y_muro + 0.15,
             (z0 + z1) / 2 + 0.25), "madera_osc")
    for s in (-1, 1):                                                       # cortinas de lino recogidas
        cx = x + s * (ancho / 2 + 0.18)
        M.perfil((cx, y_muro - 0.12, z0 - 0.05), [(0.11, 0.0), (0.14, 0.35), (0.06, 0.62), (0.13, 0.9),
                                                    (0.16, z1 - z0 - 0.1), (0.12, z1 - z0 + 0.12)], "lino", n=8)
        M.cilindro((cx, y_muro - 0.12, z0 + 0.6), 0.075, 0.05, "lima", n=8)      # cinta lima
    M.cajamm((x - ancho / 2 - 0.4, y_muro - 0.16, z1 + 0.14), (x + ancho / 2 + 0.4, y_muro - 0.1, z1 + 0.18),
             "madera_osc")                                                       # barra
    return [(x, y_muro + GRUESO / 2, (z0 + z1) / 2)]


def muro_fondo(M, ventanas):
    y = Y1
    zt = F + ALTO
    huecos = sorted(ventanas)
    xs = [X0 - GRUESO]
    for (x, an, z0, z1) in huecos:
        xs += [x - an / 2, x + an / 2]
    xs.append(X1 + GRUESO)
    for i in range(0, len(xs), 2):                   # paños llenos entre huecos
        M.cajamm((xs[i], y, F), (xs[i + 1], y + GRUESO, zt), "yeso")
    for (x, an, z0, z1) in huecos:                   # bajo y sobre cada hueco
        M.cajamm((x - an / 2, y, F), (x + an / 2, y + GRUESO, z0), "yeso")
        M.cajamm((x - an / 2, y, z1), (x + an / 2, y + GRUESO, zt), "yeso")
    # zócalo de madera, pies derechos y viga alta
    M.cajamm((X0, y - 0.04, F), (X1, y, F + 0.95), "madera_clara", caras=("frente", "arriba"))
    M.cajamm((X0, y - 0.07, F + 0.93), (X1, y, F + 1.0), "madera_osc", caras=("frente", "arriba", "abajo"))
    for x in (-7.2, -2.0, 1.95, 4.75, 7.6):
        M.cajamm((x - 0.13, y - 0.12, F), (x + 0.13, y, zt), "madera_osc", caras=("frente", "izq", "der"))
    M.cajamm((X0, y - 0.2, zt - 0.32), (X1, y, zt - 0.06), "madera_osc", caras=("frente", "abajo", "arriba"))


def muros_lados(M):
    # izquierdo: entero junto al fondo y cortado en escalones hacia el frente (diorama: no tapa la sala)
    for (ya, yb, h) in ((0.2, Y1, ALTO), (-2.2, 0.2, 1.6), (Y0, -2.2, 0.55)):
        M.cajamm((X0 - GRUESO, ya, F), (X0, yb, F + h), "yeso")
        M.cajamm((X0 - GRUESO - 0.02, ya, F + h - 0.02), (X0 + 0.04, yb, F + h + 0.1), "madera_osc")
    for (ya, yb, h) in ((0.2, Y1, ALTO), (-2.2, 0.2, 1.6), (Y0, -2.2, 0.55)):
        M.cajamm((X1, ya, F), (X1 + GRUESO, yb, F + h), "yeso")
        M.cajamm((X1 - 0.04, ya, F + h - 0.02), (X1 + GRUESO + 0.02, yb, F + h + 0.1), "madera_osc")
    # zócalo
    M.cajamm((X0, 0.2, F), (X0 + 0.04, Y1, F + 0.95), "madera_clara", caras=("der", "arriba"))
    M.cajamm((X1 - 0.04, 0.2, F), (X1, Y1, F + 0.95), "madera_clara", caras=("izq", "arriba"))


def muro_frente(M):
    """Murete bajo del frente (cortado) con el hueco de la puerta y sus dos postes con las campanillas."""
    y = Y0 - GRUESO
    h = 0.5
    M.cajamm((X0 - GRUESO, y, F), (-3.3, Y0, F + h), "yeso")
    M.cajamm((-1.9, y, F), (X1 + GRUESO, Y0, F + h), "yeso")
    M.cajamm((X0 - GRUESO - 0.02, y - 0.02, F + h), (-3.3, Y0 + 0.02, F + h + 0.08), "madera_osc")
    M.cajamm((-1.9, y - 0.02, F + h), (X1 + GRUESO + 0.02, Y0 + 0.02, F + h + 0.08), "madera_osc")
    for x in (-3.42, -1.78):
        M.cajamm((x - 0.12, y, F), (x + 0.12, Y0, F + 1.25), "madera_osc")
    # campanillas en un brazo del poste derecho
    M.cajamm((-1.78, Y0 - 0.15, F + 1.18), (-1.3, Y0 - 0.1, F + 1.23), "madera_osc")
    for k, dx in enumerate((-1.62, -1.5, -1.38)):
        largo = 0.18 + 0.06 * k
        M.cilindro((dx, Y0 - 0.125, F + 1.18 - largo), 0.012, largo, "laton", n=4, tapa=False)
        M.perfil((dx, Y0 - 0.125, F + 1.18 - largo - 0.06), [(0.035, 0.0), (0.03, 0.03), (0.012, 0.06)], "laton",
                 n=8)
    # felpudo de esparto
    M.cajamm((-3.1, Y0 + 0.1, F), (-2.1, Y0 + 0.8, F + 0.015), "esparto")
    ancla("puerta", (-2.6, Y0 - 0.05, F))
    ancla("entrada", (-2.6, Y0 + 0.75, F))


def escalera(M):
    """El arranque de la escalera a las camas de arriba, pegada al muro izquierdo y subiendo hacia el fondo."""
    xa, xb = X0, X0 + 1.15
    n = 14
    y_ini = -0.6
    paso = (Y1 - y_ini) / n
    sube = 2.9 / n
    for k in range(n):
        ya = y_ini + k * paso
        M.cajamm((xa, ya, F), (xb, ya + paso, F + (k + 1) * sube), "madera_clara")
        M.cajamm((xa, ya - 0.02, F + (k + 1) * sube - 0.03), (xb + 0.03, ya + 0.06, F + (k + 1) * sube + 0.01),
                 "madera_osc")
    # zanca y pasamanos con balaustres
    M.cajamm((xb, y_ini, F), (xb + 0.08, Y1, F + 0.12), "madera_osc")
    for k in range(0, n, 2):
        yb = y_ini + (k + 0.5) * paso
        zb = F + (k + 1) * sube
        M.cajamm((xb + 0.02, yb - 0.025, zb), (xb + 0.07, yb + 0.025, zb + 0.85), "madera_osc")
    largo = math.hypot(Y1 - y_ini, 2.9)
    ang = math.atan2(2.9, Y1 - y_ini)
    me = M
    # pasamanos inclinado (caja girada en el plano yz): a mano
    c = (xb + 0.045, (y_ini + Y1) / 2, F + 0.85 + 1.45 + sube / 2)
    sx, sy, sz = 0.07, largo, 0.07
    ca, sa = math.cos(ang), math.sin(ang)
    pts = []
    for dx in (-sx / 2, sx / 2):
        for dy in (-sy / 2, sy / 2):
            for dz in (-sz / 2, sz / 2):
                pts.append((c[0] + dx, c[1] + dy * ca - dz * sa, c[2] + dy * sa + dz * ca))
    idx = [(0, 2, 6, 4), (1, 5, 7, 3), (0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6)]
    for q in idx:
        me.cara([pts[i] for i in q], "madera_osc")
    # poste de arranque con su bola
    M.cajamm((xb - 0.02, y_ini - 0.12, F), (xb + 0.14, y_ini + 0.04, F + 1.05), "madera_osc")
    M.bola((xb + 0.06, y_ini - 0.04, F + 1.12), 0.09, "laton", n=8)


def cama(M, x, y_cab, largo=2.05, ancho=1.05, giro=False, franja="lima"):
    """Cama con cabecero, colchón, colcha de lino con franja, almohada y arcón a los pies."""
    if not giro:
        ya, yb = y_cab - largo, y_cab
        xa, xb = x - ancho / 2, x + ancho / 2
        M.cajamm((xa, ya, F + 0.12), (xb, yb, F + 0.32), "madera_clara")            # bastidor
        for px in (xa + 0.05, xb - 0.05):
            for py in (ya + 0.05, yb - 0.05):
                M.cajamm((px - 0.05, py - 0.05, F), (px + 0.05, py + 0.05, F + 0.12), "madera_osc")
        M.cajamm((xa - 0.04, yb - 0.08, F), (xb + 0.04, yb, F + 1.05), "madera_osc")    # cabecero
        M.cajamm((xa + 0.1, yb - 0.09, F + 0.75), (xb - 0.1, yb - 0.07, F + 0.95), "oro")
        M.cajamm((xa - 0.03, ya, F), (xb + 0.03, ya + 0.07, F + 0.62), "madera_osc")   # pie
        M.cajamm((xa + 0.02, ya + 0.08, F + 0.32), (xb - 0.02, yb - 0.1, F + 0.47), "colchon")
        M.cajamm((xa - 0.04, ya + 0.06, F + 0.24), (xb + 0.04, yb - 0.55, F + 0.52), "lino")   # colcha que cae
        M.cajamm((xa - 0.045, ya + 0.35, F + 0.26), (xb + 0.045, ya + 0.55, F + 0.525), franja)
        M.cajamm((xa + 0.1, yb - 0.5, F + 0.47), (xb - 0.1, yb - 0.14, F + 0.62), "almohada")
        M.cajamm((xa + 0.1, ya - 0.62, F), (xb - 0.1, ya - 0.08, F + 0.42), "madera_clara")   # arcón
        M.cajamm((xa + 0.08, ya - 0.64, F + 0.42), (xb - 0.08, ya - 0.06, F + 0.47), "madera_osc")
        M.cajamm((x - 0.08, ya - 0.66, F + 0.28), (x + 0.08, ya - 0.62, F + 0.38), "laton")
    else:
        # cabecero contra el muro derecho; la cama mira a la izquierda
        xa, xb = x - largo, x
        ya, yb = y_cab - ancho / 2, y_cab + ancho / 2
        M.cajamm((xa, ya, F + 0.12), (xb, yb, F + 0.32), "madera_clara")
        for px in (xa + 0.05, xb - 0.05):
            for py in (ya + 0.05, yb - 0.05):
                M.cajamm((px - 0.05, py - 0.05, F), (px + 0.05, py + 0.05, F + 0.12), "madera_osc")
        M.cajamm((xb - 0.08, ya - 0.04, F), (xb, yb + 0.04, F + 1.05), "madera_osc")
        M.cajamm((xb - 0.09, ya + 0.1, F + 0.75), (xb - 0.07, yb - 0.1, F + 0.95), "oro")
        M.cajamm((xa, ya - 0.03, F), (xa + 0.07, yb + 0.03, F + 0.62), "madera_osc")
        M.cajamm((xa + 0.08, ya + 0.02, F + 0.32), (xb - 0.1, yb - 0.02, F + 0.47), "colchon")
        M.cajamm((xa + 0.06, ya - 0.04, F + 0.24), (xb - 0.55, yb + 0.04, F + 0.52), "lino")
        M.cajamm((xa + 0.35, ya - 0.045, F + 0.26), (xa + 0.55, yb + 0.045, F + 0.525), franja)
        M.cajamm((xb - 0.5, ya + 0.1, F + 0.47), (xb - 0.14, yb - 0.1, F + 0.62), "almohada")


def mesa(M):
    xa, xb, ya, yb = -3.4, -0.2, -1.75, -0.8
    h = 0.78
    M.cajamm((xa, ya, F + h - 0.07), (xb, yb, F + h), "madera_clara")
    for px in (xa + 0.12, xb - 0.12):
        for py in (ya + 0.1, yb - 0.1):
            M.cajamm((px - 0.06, py - 0.06, F), (px + 0.06, py + 0.06, F + h - 0.07), "madera_osc")
    M.cajamm((xa + 0.1, (ya + yb) / 2 - 0.03, F + 0.18), (xb - 0.1, (ya + yb) / 2 + 0.03, F + 0.24), "madera_osc")
    for (y0, y1) in ((ya - 0.55, ya - 0.2), (yb + 0.2, yb + 0.55)):                 # bancos
        M.cajamm((xa + 0.15, y0, F + 0.4), (xb - 0.15, y1, F + 0.46), "madera_clara")
        for px in (xa + 0.3, xb - 0.3):
            M.cajamm((px - 0.04, y0 + 0.04, F), (px + 0.04, y1 - 0.04, F + 0.4), "madera_osc")
    top = F + h
    # camino de mesa de lino con franja lima
    M.cajamm((xa + 0.3, ya + 0.3, top), (xb - 0.3, yb - 0.3, top + 0.006), "lino")
    # tabla con pan de higo (hogazas redondas) y un cuchillo
    M.cilindro((-2.6, -1.25, top), 0.26, 0.03, "madera_osc", n=14)
    for (dx, dy, r) in ((-2.68, -1.3, 0.11), (-2.5, -1.18, 0.09), (-2.55, -1.36, 0.07)):
        M.bola((dx, dy, top + 0.03), r, "pan", n=10, aplastar=0.6)
        M.cilindro((dx, dy, top + 0.03 + r * 0.55), r * 0.35, 0.012, "higo", n=8)
    M.cajamm((-2.3, -1.42, top + 0.03), (-2.05, -1.39, top + 0.04), "laton")
    # cántaro y tazas
    M.perfil((-1.35, -1.2, top), [(0.08, 0.0), (0.14, 0.12), (0.15, 0.22), (0.09, 0.36), (0.06, 0.42),
                                  (0.08, 0.46)], "barro", n=14)
    M.cajamm((-1.2, -1.22, top + 0.22), (-1.17, -1.18, top + 0.34), "barro")
    for (dx, dy) in ((-1.0, -1.45), (-0.8, -1.05), (-1.65, -0.98)):
        M.perfil((dx, dy, top), [(0.04, 0.0), (0.05, 0.08), (0.052, 0.1)], "barro_claro", n=10)
    # jarrita con flores de la isla
    M.perfil((-0.6, -1.3, top), [(0.05, 0.0), (0.07, 0.08), (0.04, 0.15), (0.05, 0.18)], "cian", n=10)
    for k in range(7):
        a = k * 0.9
        M.bola((-0.6 + 0.08 * math.cos(a), -1.3 + 0.08 * math.sin(a), top + 0.27 + 0.03 * (k % 3)), 0.035,
               "oro" if k % 2 else "flor", n=6)
        M.cilindro((-0.6 + 0.04 * math.cos(a), -1.3 + 0.04 * math.sin(a), top + 0.15), 0.006, 0.12, "verde", n=4,
                   tapa=False)


def mostrador(M):
    """Mostrador de Yedra junto a la entrada: libro de huéspedes casi vacío, campanilla, farol y llaves colgadas."""
    xa, xb, ya, yb = -6.6, -4.0, 0.55, 1.2
    h = 1.02
    M.cajamm((xa, ya, F), (xb, yb, F + h - 0.06), "madera_clara")
    M.cajamm((xa - 0.06, ya - 0.08, F + h - 0.06), (xb + 0.06, yb + 0.04, F + h), "madera_osc")
    for k in range(5):                                         # tablas del frente
        x = xa + 0.1 + k * (xb - xa - 0.2) / 4
        M.cajamm((x - 0.015, ya - 0.012, F + 0.05), (x + 0.015, ya, F + h - 0.1), "madera_osc")
    M.cajamm((xa, ya - 0.02, F), (xb, ya, F + 0.1), "madera_osc")
    top = F + h
    # libro abierto (tapa y dos hojas)
    M.cajamm((-5.7, 0.68, top), (-5.1, 1.05, top + 0.025), "libro")
    M.cajamm((-5.68, 0.7, top + 0.025), (-5.41, 1.03, top + 0.05), "papel")
    M.cajamm((-5.39, 0.7, top + 0.025), (-5.12, 1.03, top + 0.045), "papel")
    M.cajamm((-5.33, 0.78, top + 0.046), (-5.17, 0.8, top + 0.049), "tinta")        # una sola firma
    M.cilindro((-4.95, 0.95, top), 0.025, 0.08, "tinta", n=6)                      # tintero y pluma
    M.cajamm((-4.94, 0.94, top + 0.08), (-4.9, 0.96, top + 0.26), "lino")
    # campanilla de mesa
    M.perfil((-4.4, 0.8, top), [(0.06, 0.0), (0.05, 0.03), (0.035, 0.07), (0.01, 0.1), (0.012, 0.13)], "laton",
             n=10)
    # farol de peregrino (apagado: es de día) sobre el mostrador
    farol(M, (-6.25, 0.9, top), 0.85)
    # estante y llavero en el muro del fondo, detrás de Yedra
    y = Y1 - 0.02
    M.cajamm((-6.9, y - 0.32, F + 1.75), (-4.2, y, F + 1.8), "madera_osc")
    for k, x in enumerate((-6.7, -6.35, -6.0, -5.6, -5.2, -4.8, -4.45)):
        hh = 0.16 + 0.06 * (k % 3)
        M.perfil((x, y - 0.17, F + 1.8), [(0.07, 0.0), (0.08, hh * 0.7), (0.05, hh), (0.055, hh + 0.03)],
                 ("barro" if k % 2 else "cian"), n=10)
    M.cajamm((-6.6, y - 0.06, F + 1.35), (-4.5, y, F + 1.45), "madera_osc")              # llavero
    for k in range(9):
        x = -6.45 + k * 0.23
        M.cilindro((x, y - 0.08, F + 1.35), 0.01, 0.02, "laton", n=4)
        if k % 3 != 1:                                                               # llaves colgadas
            M.cajamm((x - 0.008, y - 0.09, F + 1.17), (x + 0.008, y - 0.07, F + 1.33), "laton")
            M.cilindro((x, y - 0.08, F + 1.13), 0.03, 0.01, "laton", n=8)
            M.cajamm((x - 0.03, y - 0.085, F + 1.05), (x + 0.03, y - 0.075, F + 1.1), "lino")    # etiqueta
    ancla("yedra", (-5.25, 2.05, F))
    ancla("mostrador", (-5.25, -0.15, F))


def farol(M, base, esc=1.0):
    """Farol de peregrino: base de latón, cristal cian claro, tejadillo y asa."""
    x, y, z = base
    s = esc
    M.cajamm((x - 0.12 * s, y - 0.12 * s, z), (x + 0.12 * s, y + 0.12 * s, z + 0.04 * s), "laton")
    for dx in (-0.1, 0.1):
        for dy in (-0.1, 0.1):
            M.cajamm((x + dx * s - 0.012, y + dy * s - 0.012, z + 0.04 * s), (x + dx * s + 0.012, y + dy * s + 0.012,
                     z + 0.3 * s), "laton")
    M.cajamm((x - 0.09 * s, y - 0.09 * s, z + 0.04 * s), (x + 0.09 * s, y + 0.09 * s, z + 0.3 * s), "cristal")
    M.cilindro((x, y, z + 0.06 * s), 0.025 * s, 0.1 * s, "papel", n=6)                     # vela
    M.perfil((x, y, z + 0.3 * s), [(0.15 * s, 0.0), (0.12 * s, 0.03 * s), (0.02 * s, 0.13 * s)], "laton", n=4)
    M.cilindro((x, y, z + 0.43 * s), 0.03 * s, 0.05 * s, "laton", n=6)


def maceta(M, c, r=0.2, h=0.3, flores="oro"):
    x, y, z = c
    M.perfil((x, y, z), [(r * 0.75, 0.0), (r, h * 0.9), (r * 1.08, h)], "barro", n=12)
    M.cilindro((x, y, z + h * 0.9), r * 0.95, 0.01, "tierra", n=12)
    for k in range(9):
        a = k * 2.4
        rr = r * (0.3 + 0.5 * ((k * 37) % 10) / 10)
        M.bola((x + rr * math.cos(a), y + rr * math.sin(a), z + h + 0.12 + 0.05 * (k % 3)), r * 0.42, "lima"
               if k % 2 else "verde", n=6)
    for k in range(5):
        a = k * 1.3 + 0.4
        M.bola((x + r * 0.55 * math.cos(a), y + r * 0.55 * math.sin(a), z + h + 0.26), r * 0.13, flores, n=6)


def alfombra(M):
    xa, xb, ya, yb = -0.4, 7.2, 1.0, 1.9
    M.cajamm((xa, ya, F), (xb, yb, F + 0.012), "alfombra")
    for k, (y0, y1) in enumerate(((ya + 0.1, ya + 0.18), (yb - 0.18, yb - 0.1))):
        M.cajamm((xa + 0.1, y0, F + 0.012), (xb - 0.1, y1, F + 0.016), "oro")
    for k in range(int((xb - xa) / 0.12)):                    # flecos
        x = xa + 0.06 + k * 0.12
        M.cajamm((x - 0.015, ya - 0.08, F), (x + 0.015, ya, F + 0.008), "lino")


def faroles_pared(M):
    """Faroles de peregrino colgados de los pies derechos (cuidados, apagados por la mañana)."""
    y = Y1 - 0.14
    for x in (-2.0, 4.75):
        M.cajamm((x - 0.03, y - 0.42, F + 2.38), (x + 0.03, y, F + 2.44), "hierro")
        M.cilindro((x, y - 0.4, F + 2.12), 0.008, 0.26, "hierro", n=4, tapa=False)
        farol(M, (x, y - 0.4, F + 1.72), 0.9)


def rincones(M):
    # macetas en los rincones y en los alféizares, y un arcón grande con mantas dobladas
    maceta(M, (X1 - 0.45, Y1 - 0.45, F), 0.3, 0.45, "flor")
    maceta(M, (-3.1, Y1 - 0.45, F), 0.24, 0.36, "oro")
    maceta(M, (X1 - 0.5, -2.8, F), 0.26, 0.38, "oro")
    for x in (0.6, 3.35, 6.15):
        maceta(M, (x - 0.45, Y1 - 0.08, F + 1.02), 0.11, 0.14, "flor" if x > 3 else "oro")
    # mantas dobladas en un arcón junto a la escalera
    M.cajamm((-6.85, 3.1, F), (-5.95, 4.3, F + 0.5), "madera_clara")
    for k in range(3):
        M.cajamm((-6.8, 3.2, F + 0.5 + k * 0.09), (-6.0, 4.15, F + 0.59 + k * 0.09), "lino" if k != 1 else "lima")
    # escarpia del dibujo de Lumi (el dibujo es una pieza aparte del juego: aparece al entregar la flor)
    xd, zd = -0.95, F + 1.72
    M.cilindro((xd, Y1 - 0.02, zd), 0.012, 0.02, "laton", n=6)
    ancla("dibujo", (xd, Y1 - 0.03, zd - 0.24))
    # perchero de la entrada con una capa de peregrino y un bordón
    M.cajamm((-4.1, -4.38, F + 1.5), (-3.6, -4.3, F + 1.56), "madera_osc")
    M.cajamm((-4.0, -4.36, F + 0.5), (-3.7, -4.28, F + 1.5), "capa")
    M.cilindro((-3.55, -4.3, F), 0.025, 1.65, "madera_osc", n=6)
    M.bola((-3.55, -4.3, F + 1.68), 0.04, "laton", n=6)


def cielo_raso(B):
    """Solo para el horneado: techo y muro del frente enteros (que la luz entre por las ventanas, no desde arriba)."""
    B.cajamm((X0 - GRUESO, Y0 - GRUESO, F + ALTO), (X1 + GRUESO, Y1 + GRUESO, F + ALTO + 0.2), "yeso")
    B.cajamm((X0 - GRUESO, Y0 - GRUESO, F + 0.5), (X1 + GRUESO, Y0, F + ALTO), "yeso")
    for (x0, x1) in ((X0 - GRUESO, X0), (X1, X1 + GRUESO)):
        B.cajamm((x0, Y0, F + 0.55), (x1, 0.2, F + ALTO), "yeso")


# ---------------------------------------------------------------- materiales (procedurales, solo para el horneado)

COLORES = {
    "tablas": ("#C38E52", "#9C6A38"), "madera_clara": ("#C9A06A", "#A87F4E"), "madera_osc": ("#7A5236", "#5C3C26"),
    "yeso": ("#EDE3C6", "#D9CCA8"), "piedra": ("#DCD2B4", "#BDB291"), "lino": ("#F1E9D6", "#E1D6BC"),
    "colchon": ("#E9E0CA", "#DCD1B6"), "almohada": ("#F6F0E2", "#E9E0CC"), "lima": ("#A8D63A", "#8FBF2C"),
    "verde": ("#5FA82E", "#4A8C24"), "oro": ("#E0A93A", "#C98F2A"), "flor": ("#E7A2C8", "#C97FAA"),
    "cian": ("#5FE0F0", "#3FB8CC"), "cristal": ("#BFEFF4", "#9ADDE6"), "laton": ("#D4A848", "#A88232"),
    "hierro": ("#4A4440", "#3A3532"), "barro": ("#C77A48", "#A65F36"), "barro_claro": ("#E2B88A", "#C99A6C"),
    "pan": ("#C88A48", "#A86A30"), "higo": ("#7A3E5A", "#5E2E46"), "libro": ("#7A3B2E", "#5E2C22"),
    "papel": ("#F3EBD6", "#E6DCC2"), "tinta": ("#2E2A30", "#2E2A30"), "esparto": ("#C9B27A", "#A8915E"),
    "alfombra": ("#9DC24A", "#7FA63A"), "tierra": ("#5A4030", "#4A3426"), "capa": ("#8E7A5A", "#74624A"),
}


def material(nombre):
    a, b = COLORES[nombre]
    mt = bpy.data.materials.new(nombre)
    mt.use_nodes = True
    nt = mt.node_tree
    bs = nt.nodes.get("Principled BSDF")
    bs.inputs["Roughness"].default_value = 0.9
    tc = nt.nodes.new("ShaderNodeTexCoord")
    rampa = nt.nodes.new("ShaderNodeValToRGB")
    rampa.color_ramp.elements[0].color = (*hexc(b), 1.0)
    rampa.color_ramp.elements[1].color = (*hexc(a), 1.0)
    if nombre == "tablas":                                    # tablas de 0,2 m con juntas y veta
        br = nt.nodes.new("ShaderNodeTexBrick")
        br.inputs["Scale"].default_value = 1.0
        br.inputs["Brick Width"].default_value = 1.6
        br.inputs["Row Height"].default_value = 0.2
        br.inputs["Mortar Size"].default_value = 0.012
        br.inputs["Mortar"].default_value = (*hexc("#6E4A2A"), 1.0)
        br.offset = 0.5
        rampa2 = nt.nodes.new("ShaderNodeTexNoise")
        rampa2.inputs["Scale"].default_value = 3.0
        rampa2.inputs["Detail"].default_value = 6.0
        mix = nt.nodes.new("ShaderNodeMix")
        mix.data_type = 'RGBA'
        mix.blend_type = 'MULTIPLY'
        mix.inputs[0].default_value = 0.35
        nt.links.new(tc.outputs["Object"], br.inputs["Vector"])
        nt.links.new(tc.outputs["Object"], rampa2.inputs["Vector"])
        br.inputs["Color1"].default_value = (*hexc(a), 1.0)
        br.inputs["Color2"].default_value = (*hexc(b), 1.0)
        nt.links.new(br.outputs["Color"], mix.inputs[6])
        nt.links.new(rampa2.outputs["Color"], mix.inputs[7])
        nt.links.new(mix.outputs[2], bs.inputs["Base Color"])
        return mt
    ru = nt.nodes.new("ShaderNodeTexNoise")
    ru.inputs["Scale"].default_value = {"yeso": 2.5, "piedra": 6.0, "madera_clara": 9.0, "madera_osc": 9.0,
                                        "lino": 14.0}.get(nombre, 5.0)
    ru.inputs["Detail"].default_value = 5.0
    nt.links.new(tc.outputs["Object"], ru.inputs["Vector"])
    nt.links.new(ru.outputs["Fac"], rampa.inputs["Fac"])
    nt.links.new(rampa.outputs["Color"], bs.inputs["Base Color"])
    return mt


# ---------------------------------------------------------------- construcción, horneado y exportación

def a_blender(nombre, M):
    me = bpy.data.meshes.new(nombre)
    me.from_pydata([Vector(v) for v in M.v], [], M.f)
    me.update()
    for n in M.mats:
        me.materials.append(bpy.data.materials.get(n) or material(n))
    me.polygons.foreach_set("material_index", M.m)
    ob = bpy.data.objects.new(nombre, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def preparar_cycles():
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    pr = bpy.context.preferences.addons['cycles'].preferences
    for t in ('OPTIX', 'CUDA'):
        try:
            pr.compute_device_type = t
            pr.get_devices()
            hay = False
            for d in pr.devices:
                d.use = d.type == t
                hay = hay or d.use
            if hay:
                sc.cycles.device = 'GPU'
                nota("Cycles con %s" % t)
                break
        except Exception as e:
            nota("sin %s: %s" % (t, e))
    sc.cycles.samples = MUESTRAS
    sc.cycles.use_denoising = False
    sc.cycles.max_bounces = 5
    sc.cycles.diffuse_bounces = 4
    sc.cycles.glossy_bounces = 0
    sc.cycles.sample_clamp_indirect = 8.0
    w = sc.world or bpy.data.worlds.new("Mundo")
    sc.world = w
    w.use_nodes = True
    bg = w.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (*hexc("#BFE0FF"), 1.0)      # el cielo de la mañana eterna
    bg.inputs["Strength"].default_value = 1.6
    sd = bpy.data.lights.new("Sol", 'SUN')                        # entra por las ventanas del fondo
    sd.energy = 5.5
    sd.color = hexc("#FFE6BC")
    sd.angle = math.radians(3.0)
    so = bpy.data.objects.new("Sol", sd)
    hacia = Vector((-0.3, 0.72, 0.62)).normalized()               # del suelo al sol: detrás y algo a la izquierda
    so.rotation_euler = hacia.to_track_quat('Z', 'Y').to_euler()
    sc.collection.objects.link(so)


def hornear(ob):
    sc = bpy.context.scene
    me = ob.data
    uv = me.uv_layers.new(name="UVMap")
    me.uv_layers.active = uv
    bpy.ops.object.select_all(action='DESELECT')
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.003, area_weight=0.0, correct_aspect=True,
                             scale_to_bounds=False)
    try:
        bpy.ops.uv.pack_islands(rotate=True, margin=0.003)
    except Exception as e:
        nota("pack_islands: %s" % e)
    bpy.ops.object.mode_set(mode='OBJECT')
    imgs = {}
    for k in ("color", "luz"):
        imgs[k] = bpy.data.images.new("hosp_" + k, RES, RES, alpha=False, float_buffer=True)
    nodos = []
    for mt in me.materials:
        tn = mt.node_tree.nodes.new("ShaderNodeTexImage")
        mt.node_tree.nodes.active = tn
        nodos.append(tn)
    sc.render.bake.margin = 8
    sc.render.bake.margin_type = 'EXTEND'
    for k, filtro in (("color", {'COLOR'}), ("luz", {'DIRECT', 'INDIRECT'})):
        for tn in nodos:
            tn.image = imgs[k]
        bpy.ops.object.bake(type='DIFFUSE', pass_filter=filtro, margin=8, target='IMAGE_TEXTURES', use_clear=True)
        nota("horneado %s" % k)
    return imgs


def componer(imgs):
    """color × luz: la luz, normalizada para que la mayor parte quede entre 0,35 y 1,3 (no se quema: después
    render_isla.gd la vuelve a iluminar con la luz de la isla). Se conserva el tinte de la luz (rebote cálido)."""
    c = np.array(imgs["color"].pixels[:], np.float32).reshape(RES, RES, 4)[..., :3]
    l = np.array(imgs["luz"].pixels[:], np.float32).reshape(RES, RES, 4)[..., :3]
    # suavizado ligero del ruido (3 × 3)
    lp = np.pad(l, ((1, 1), (1, 1), (0, 0)), mode="edge")
    l = sum(lp[1 + dy:RES + 1 + dy, 1 + dx:RES + 1 + dx] for dy in (-1, 0, 1) for dx in (-1, 0, 1)) / 9.0
    lum = l.max(-1)
    validos = lum[lum > 0.002]
    ref = float(np.percentile(validos, 80)) if validos.size else 1.0
    f = np.clip(l / ref, 0.0, 1.45)
    fin = np.clip(c * (0.32 + 0.68 * f), 0.0, 1.0)
    # a sRGB
    fin = np.where(fin <= 0.0031308, fin * 12.92, 1.055 * np.power(fin, 1 / 2.4) - 0.055)
    out = bpy.data.images.new("hospederia_tex", RES, RES, alpha=False)
    a = np.ones((RES, RES, 4), np.float32)
    a[..., :3] = fin
    out.pixels.foreach_set(a.ravel())
    nota("luz: referencia %.3f (percentil 80)" % ref)
    return out


def main():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    os.makedirs(SALIDA, exist_ok=True)
    M = Malla()
    B = Malla()
    suelo(M)
    ventanas = [(0.6, 1.25, F + 1.15, F + 2.75), (3.35, 1.25, F + 1.15, F + 2.75), (6.15, 1.25, F + 1.15, F + 2.75)]
    muro_fondo(M, ventanas)
    for (x, an, z0, z1) in ventanas:
        ventana_hueco(M, x, an, z0, z1, Y1)
        ancla("ventana_%d" % len([k for k in ANCLAS if k.startswith("ventana")]), (x, Y1 + 0.2, (z0 + z1) / 2))
    muros_lados(M)
    muro_frente(M)
    escalera(M)
    for k, x in enumerate((0.6, 3.35, 6.15)):
        cama(M, x, Y1 - 0.02, franja=("lima", "oro", "cian")[k])
    cama(M, X1 - 0.02, -0.35, giro=True, franja="lima")
    ancla("cama", (3.35, 0.55, F))
    mesa(M)
    mostrador(M)
    alfombra(M)
    faroles_pared(M)
    rincones(M)
    cielo_raso(B)
    nota("construido: %d caras, %d materiales" % (len(M.f), len(M.mats)))
    ob = a_blender("hospederia", M)
    ob_b = a_blender("solo_horneado", B)
    preparar_cycles()
    imgs = hornear(ob)
    tex = componer(imgs)
    bpy.data.objects.remove(ob_b)
    # un solo material con la textura horneada (render_isla.gd lee el albedo del material 0)
    ruta_tex = os.path.join(SALIDA, "hospederia_tex.png")
    tex.filepath_raw = ruta_tex
    tex.file_format = 'PNG'
    tex.save()
    mt = bpy.data.materials.new("hospederia")
    mt.use_nodes = True
    nt = mt.node_tree
    bs = nt.nodes.get("Principled BSDF")
    bs.inputs["Roughness"].default_value = 1.0
    tn = nt.nodes.new("ShaderNodeTexImage")
    tn.image = tex
    nt.links.new(tn.outputs["Color"], bs.inputs["Base Color"])
    me = ob.data
    me.materials.clear()
    me.materials.append(mt)
    me.polygons.foreach_set("material_index", [0] * len(me.polygons))
    bpy.ops.object.select_all(action='DESELECT')
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    ruta = os.path.join(SALIDA, "hospederia.glb")
    bpy.ops.export_scene.gltf(filepath=ruta, export_format='GLB', use_selection=True, export_animations=False,
                              export_yup=True, export_cameras=False, export_lights=False, export_apply=True,
                              export_texcoords=True, export_normals=True, export_image_format='JPEG',
                              export_materials='EXPORT')
    os.remove(ruta_tex)
    xs = [v[0] for v in M.v]
    ys = [v[1] for v in M.v]
    zs = [v[2] for v in M.v]
    datos = {"anclas": ANCLAS, "caja_godot": {"x": [min(xs), max(xs)], "y": [min(zs), max(zs)],
                                               "z": [-max(ys), -min(ys)]}, "caras": len(M.f), "muestras": MUESTRAS,
             "res": RES}
    with open(os.path.join(SALIDA, "hospederia_anclas.json"), "w", encoding="utf-8") as f:
        json.dump(datos, f, indent=1)
    nota("EXPORTADO %s (%d caras)" % (ruta, len(M.f)))


main()
