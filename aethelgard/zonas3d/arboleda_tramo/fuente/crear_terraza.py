# Arboleda Mítica, tramo «La escalera de la Hospedería» (EXPERIMENTAL, 16/11): el ATREZO de la terraza de la Hospedería
# (lino tendido, farol de peregrino en su poste, macetas, banco y cántaro con su cesto). Cada pieza es un GLB de UNA
# malla con colores planos por material; pruebas/herramientas/render_isla.gd la renderiza con la misma cámara a 38° y la
# misma luz que la isla (solo la pasada de color), y preparar_tramo.gd la recorta y la suaviza como el fondo de Meshy.
# En el juego, cada pieza se tapa con lo que la isla tenga delante (isla_tapa) y Kael pasa por delante o por detrás
# según sus pies (arboleda_tramo.gd, SHADER_PIEZA).
#
# Blender 5.2.3 en segundo plano. Obra propia (sin descargas, sin Meshy ni Hunyuan3D). Determinista. Uso:
#   blender -b --factory-startup -P crear_terraza.py -- <carpeta de salida>
# Salida: terraza_<pieza>.glb y terraza_piezas.json (para cada pieza, el ancho en píxeles del render: 84 px por metro,
# la misma escala que el interior, para que guarde la proporción con Kael).

import bpy
import json
import math
import os
import random
import sys

from mathutils import Vector

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SALIDA = ARGS[0] if ARGS else os.path.join(os.path.dirname(__file__), "modelos")
PX_M = 84.0
random.seed(1610)


def hexc(h):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)


# (16/11, 2.ª pasada) más apagados que la paleta de diseño: render_isla.gd los ilumina con sol 1,25 + ambiente 0,55 y
# salían más saturados y nítidos que el fondo de Meshy (lámina terraza_v2).
COLORES = {"madera": "#9C7650", "madera_osc": "#4E3624", "lino": "#D9D0B6", "lino_lima": "#B4C27A",
           "lino_oro": "#D2B67E", "cuerda": "#A8956A", "laton": "#B8924A", "cristal": "#B9DCDC", "vela": "#E2DAC2",
           "barro": "#A86A44", "barro_claro": "#C4A07A", "tierra": "#4A3628", "lima": "#93B83E", "verde": "#5A9030",
           "oro": "#C89A42", "flor": "#C990AE", "piedra": "#8E8E6E", "mimbre": "#A88454", "cian": "#6CC2CC"}


class Malla:
    def __init__(self):
        self.v, self.f, self.m, self.mats = [], [], [], []

    def mat(self, n):
        if n not in self.mats:
            self.mats.append(n)
        return self.mats.index(n)

    def cara(self, pts, mat):
        b = len(self.v)
        self.v.extend(pts)
        self.f.append(list(range(b, b + len(pts))))
        self.m.append(self.mat(mat))

    def cajamm(self, a, b, mat):
        x0, y0, z0 = a
        x1, y1, z1 = b
        p = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0), (x0, y0, z1), (x1, y0, z1), (x1, y1, z1),
             (x0, y1, z1)]
        for q in ((0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (2, 3, 7, 6), (3, 0, 4, 7), (1, 2, 6, 5)):
            self.cara([p[i] for i in q], mat)

    def perfil(self, base, radios, mat, n=12):
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

    def cilindro(self, base, r, h, mat, n=8):
        self.perfil(base, [(r, 0.0), (r, h)], mat, n)

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

    def tela(self, x0, x1, z_arriba, largo, mat, y=0.0, filas=6, cols=6, vuelo=0.06, fase=0.0):
        """Una tela colgada de la cuerda: rejilla con pliegues y algo de vuelo (cara doble)."""
        b = len(self.v)
        for r in range(filas + 1):
            t = r / filas
            for c in range(cols + 1):
                s = c / cols
                x = x0 + (x1 - x0) * s
                pl = math.sin(s * math.pi * 3 + fase) * 0.025 * (0.4 + t)
                self.v.append((x, y + pl + vuelo * t * t, z_arriba - largo * t))
        mi = self.mat(mat)
        for r in range(filas):
            for c in range(cols):
                i = b + r * (cols + 1) + c
                q = [i, i + 1, i + cols + 2, i + cols + 1]
                self.f.append(q)
                self.m.append(mi)
                self.f.append(list(reversed(q)))
                self.m.append(mi)


def lino(M):
    """Dos postes, la cuerda con comba y tres paños de lino (uno con franja lima, otro dorado), con pinzas."""
    for x in (-1.0, 1.0):
        M.cajamm((x - 0.05, -0.05, 0.0), (x + 0.05, 0.05, 1.85), "madera_osc")
        M.cajamm((x - 0.09, -0.09, 0.0), (x + 0.09, 0.09, 0.08), "piedra")
        M.cajamm((x - 0.12, -0.03, 1.72), (x + 0.12, 0.03, 1.76), "madera_osc")
    n = 16
    prev = None
    for k in range(n + 1):
        t = k / n
        x = -1.0 + 2.0 * t
        z = 1.74 - 0.12 * math.sin(math.pi * t)
        if prev:
            M.cajamm((prev[0], -0.008, min(prev[1], z) - 0.008), (x, 0.008, max(prev[1], z) + 0.008), "cuerda")
        prev = (x, z)

    def zc(x):
        return 1.74 - 0.12 * math.sin(math.pi * (x + 1.0) / 2.0)
    for (a, b, mat, largo, fase) in ((-0.85, -0.35, "lino", 0.78, 0.0), (-0.28, 0.28, "lino_lima", 0.9, 1.3),
                                     (0.36, 0.86, "lino_oro", 0.7, 2.1)):
        M.tela(a, b, zc((a + b) / 2) - 0.01, largo, mat, fase=fase)
        for x in (a + 0.06, b - 0.06):
            M.cajamm((x - 0.012, -0.02, zc(x) - 0.05), (x + 0.012, 0.02, zc(x) + 0.02), "madera")
    # la franja lima del paño central
    M.tela(-0.28, 0.28, zc(0.0) - 0.5, 0.08, "lima", y=-0.004, fase=1.3)


def farol(M):
    """Farol de peregrino en su poste, con el brazo y una cinta: cuidado, apagado (es de día)."""
    M.cajamm((-0.16, -0.16, 0.0), (0.16, 0.16, 0.12), "piedra")
    M.cajamm((-0.055, -0.055, 0.12), (0.055, 0.055, 1.6), "madera_osc")
    M.cajamm((-0.055, -0.03, 1.5), (0.45, 0.03, 1.56), "madera_osc")
    M.cilindro((0.38, 0.0, 1.32), 0.008, 0.2, "laton", n=4)
    x, y, z = 0.38, 0.0, 0.98
    M.cajamm((x - 0.11, y - 0.11, z), (x + 0.11, y + 0.11, z + 0.04), "laton")
    for dx in (-0.09, 0.09):
        for dy in (-0.09, 0.09):
            M.cajamm((x + dx - 0.012, y + dy - 0.012, z + 0.04), (x + dx + 0.012, y + dy + 0.012, z + 0.3), "laton")
    M.cajamm((x - 0.085, y - 0.085, z + 0.04), (x + 0.085, y + 0.085, z + 0.3), "cristal")
    M.cilindro((x, y, z + 0.06), 0.025, 0.1, "vela", n=6)
    M.perfil((x, y, z + 0.3), [(0.14, 0.0), (0.11, 0.03), (0.02, 0.13)], "laton", n=4)
    M.tela(-0.05, 0.05, 1.45, 0.35, "lima", y=0.06, filas=3, cols=1, vuelo=0.02)       # cinta del peregrino


def macetas(M):
    """Tres macetas de barro con plantas de la isla (lima y verde) y flores de oro y rosa."""
    for (x, y, r, h, fl) in ((-0.32, 0.05, 0.22, 0.34, "oro"), (0.12, -0.12, 0.17, 0.26, "flor"),
                             (0.4, 0.14, 0.13, 0.2, "oro")):
        M.perfil((x, y, 0.0), [(r * 0.72, 0.0), (r, h * 0.9), (r * 1.1, h), (r * 1.02, h * 1.06)],
                 "barro" if r > 0.15 else "barro_claro", n=12)
        M.cilindro((x, y, h * 0.92), r * 0.95, 0.02, "tierra", n=12)
        for k in range(9):
            a = k * 2.4
            rr = r * (0.3 + 0.5 * ((k * 37) % 10) / 10)
            M.bola((x + rr * math.cos(a), y + rr * math.sin(a), h + 0.1 + 0.05 * (k % 3)), r * 0.45,
                   "lima" if k % 2 else "verde", n=6)
        for k in range(5):
            a = k * 1.3 + 0.4
            M.bola((x + r * 0.55 * math.cos(a), y + r * 0.55 * math.sin(a), h + 0.26), r * 0.14, fl, n=6)


def banco(M):
    """Banco de madera con respaldo, un cojín de lino y una manta doblada."""
    M.cajamm((-0.8, -0.2, 0.42), (0.8, 0.2, 0.48), "madera")
    for x in (-0.68, 0.68):
        M.cajamm((x - 0.05, -0.16, 0.0), (x + 0.05, 0.16, 0.42), "madera_osc")
        M.cajamm((x - 0.04, 0.16, 0.42), (x + 0.04, 0.22, 0.95), "madera_osc")
    M.cajamm((-0.8, 0.18, 0.72), (0.8, 0.24, 0.9), "madera")
    M.cajamm((-0.6, -0.15, 0.48), (-0.1, 0.15, 0.56), "lino")
    M.cajamm((0.25, -0.14, 0.48), (0.65, 0.14, 0.53), "lino_lima")
    M.cajamm((0.27, -0.12, 0.53), (0.63, 0.12, 0.58), "lino_oro")


def cantaro(M):
    """Cántaro de barro, un cuenco y un cesto de mimbre con pan de higo envuelto en lino."""
    M.perfil((-0.15, 0.0, 0.0), [(0.11, 0.0), (0.2, 0.16), (0.21, 0.3), (0.12, 0.48), (0.08, 0.56),
                                  (0.11, 0.6)], "barro", n=14)
    M.cajamm((0.03, -0.02, 0.32), (0.07, 0.02, 0.5), "barro")
    M.perfil((0.32, 0.1, 0.0), [(0.16, 0.0), (0.2, 0.18), (0.22, 0.22)], "mimbre", n=12)
    M.bola((0.32, 0.1, 0.2), 0.16, "lino", n=8, aplastar=0.5)
    for (dx, dy) in ((-0.05, 0.0), (0.06, 0.05)):
        M.bola((0.32 + dx, 0.1 + dy, 0.26), 0.07, "barro_claro", n=8, aplastar=0.7)
    M.perfil((0.12, -0.22, 0.0), [(0.07, 0.0), (0.11, 0.06), (0.12, 0.08)], "cian", n=12)


PIEZAS = {"lino": lino, "farol": farol, "macetas": macetas, "banco": banco, "cantaro": cantaro}


def a_blender(nombre, M):
    me = bpy.data.meshes.new(nombre)
    me.from_pydata([Vector(v) for v in M.v], [], M.f)
    me.update()
    for n in M.mats:
        mt = bpy.data.materials.get(n)
        if mt is None:
            mt = bpy.data.materials.new(n)
            mt.use_nodes = True
            bs = mt.node_tree.nodes.get("Principled BSDF")
            bs.inputs["Base Color"].default_value = (*hexc(COLORES[n]), 1.0)
            bs.inputs["Roughness"].default_value = 0.9
        me.materials.append(mt)
    me.polygons.foreach_set("material_index", M.m)
    ob = bpy.data.objects.new(nombre, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def main():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    os.makedirs(SALIDA, exist_ok=True)
    datos = {}
    for nombre, fn in PIEZAS.items():
        M = Malla()
        fn(M)
        ob = a_blender("terraza_" + nombre, M)
        bpy.ops.object.select_all(action='DESELECT')
        ob.select_set(True)
        bpy.context.view_layer.objects.active = ob
        ruta = os.path.join(SALIDA, "terraza_%s.glb" % nombre)
        bpy.ops.export_scene.gltf(filepath=ruta, export_format='GLB', use_selection=True, export_animations=False,
                                  export_yup=True, export_cameras=False, export_lights=False, export_apply=True,
                                  export_normals=True, export_materials='EXPORT')
        xs = [v[0] for v in M.v]
        ancho_m = max(xs) - min(xs)
        datos[nombre] = {"ancho_px": int(round(ancho_m * 1.04 * PX_M)), "caras": len(M.f)}
        bpy.data.objects.remove(ob)
        print("[terraza] %s: %d caras, %.2f m de ancho → %d px" % (nombre, len(M.f), ancho_m, datos[nombre]["ancho_px"]))
    with open(os.path.join(SALIDA, "terraza_piezas.json"), "w", encoding="utf-8") as f:
        json.dump(datos, f, indent=1)


main()
