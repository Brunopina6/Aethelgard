# Nix piloto FBX: perfiles de la malla reducida para situar las articulaciones (secciones de piernas, brazos y tronco).
#   blender -b --factory-startup -P p3_medir.py -- <blend paso 2>
import sys, bpy
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.open_mainfile(filepath=argv[0])
o = bpy.data.objects["nix_alta"]          # la alta: más puntos por sección
P = [v.co.copy() for v in o.data.vertices]


def sec(cond):
    q = [p for p in P if cond(p)]
    if not q:
        return None
    n = len(q)
    c = sum(q, Vector()) / n
    return n, c, min(p.x for p in q), max(p.x for p in q), min(p.y for p in q), max(p.y for p in q), min(p.z for p in q), max(p.z for p in q)


print("--- pierna izquierda (x>0.02), por z")
for i in range(0, 105, 3):
    z = i / 100
    s = sec(lambda p: abs(p.z - z) < 0.006 and 0.015 < p.x < 0.35)
    if s:
        n, c, x0, x1, y0, y1, *_ = s
        print("PIERNA z %.2f  n %5d  cx %.3f cy %.3f  x %.3f..%.3f (ancho %.3f)  y %.3f..%.3f (fondo %.3f)" % (z, n, c.x, c.y, x0, x1, x1 - x0, y0, y1, y1 - y0))
print("--- centro (|x|<0.012): entrepierna")
for i in range(70, 110, 1):
    z = i / 100
    s = sec(lambda p: abs(p.z - z) < 0.005 and abs(p.x) < 0.012)
    if s:
        n, c, x0, x1, y0, y1, *_ = s
        print("CENTRO z %.2f  n %4d  y %.3f..%.3f" % (z, n, y0, y1))
print("--- tronco por z (|x|<0.25)")
for i in range(95, 175, 3):
    z = i / 100
    s = sec(lambda p: abs(p.z - z) < 0.006 and abs(p.x) < 0.25)
    if s:
        n, c, x0, x1, y0, y1, *_ = s
        print("TRONCO z %.2f  n %5d  cy %.3f  x %.3f..%.3f  y %.3f..%.3f" % (z, n, c.y, x0, x1, y0, y1))
print("--- brazo izquierdo por x (z>1.05)")
for i in range(12, 86, 2):
    x = i / 100
    s = sec(lambda p: abs(p.x - x) < 0.004 and p.z > 1.05 and p.z < 1.5)
    if s:
        n, c, x0, x1, y0, y1, z0, z1 = s
        print("BRAZO x %.2f  n %5d  cy %.3f cz %.3f  y %.3f..%.3f  z %.3f..%.3f (alto %.3f)" % (x, n, c.y, c.z, y0, y1, z0, z1, z1 - z0))
print("--- brazo derecho por x")
for i in range(12, 86, 4):
    x = -i / 100
    s = sec(lambda p: abs(p.x - x) < 0.004 and p.z > 1.05 and p.z < 1.5)
    if s:
        n, c, x0, x1, y0, y1, z0, z1 = s
        print("BRAZO_D x %.2f  n %5d  cy %.3f cz %.3f  z %.3f..%.3f" % (x, n, c.y, c.z, z0, z1))
print("--- pie izquierdo")
q = [p for p in P if p.z < 0.12 and p.x > 0.0]
print("PIE y %.3f..%.3f  x %.3f..%.3f" % (min(p.y for p in q), max(p.y for p in q), min(p.x for p in q), max(p.x for p in q)))
