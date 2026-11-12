# Polígono convexo (k-DOP) que contiene todo lo opaco (alfa >= umbral) de cada celda del atlas de matas, con margen
# (rend2, 12/11). Da MATAS_CASCO de zonas3d/gran_bosque/escenario.gd. Necesita Pillow y numpy (en un entorno virtual):
#   python casco_matas.py [umbral 0-255 = 100] [margen en la celda = 0.03]
import sys, math
import numpy as np
from PIL import Image
im = np.asarray(Image.open(r"D:\Aethelgard_v12_rend2\aethelgard\modelos\hojas\matas.png").convert("RGBA"))
H, W = im.shape[0] // 2, im.shape[1] // 2
def dop(mask, k, margen):
    ys, xs = np.nonzero(mask)
    pts = np.stack([(xs + 0.5) / W, (ys + 0.5) / H], 1)
    planos = []
    for i in range(k):
        a = 2 * math.pi * i / k
        d = np.array([math.cos(a), math.sin(a)])
        planos.append((d, (pts @ d).max() + margen))
    # vértices: intersección de planos consecutivos, recortados al cuadrado [0,1]
    vs = []
    for i in range(k):
        d1, o1 = planos[i]; d2, o2 = planos[(i + 1) % k]
        A = np.array([d1, d2]); v = np.linalg.solve(A, [o1, o2]); vs.append(v)
    poly = np.array(vs)
    # recorte con el cuadrado unidad (Sutherland-Hodgman)
    def recorta(poly, n, c):
        out = []
        for i in range(len(poly)):
            p, q = poly[i], poly[(i + 1) % len(poly)]
            dp, dq = p @ n - c, q @ n - c
            if dp <= 0: out.append(p)
            if dp * dq < 0: out.append(p + (q - p) * (dp / (dp - dq)))
        return np.array(out)
    for n, c in [((1, 0), 1), ((-1, 0), 0), ((0, 1), 1), ((0, -1), 0)]:
        poly = recorta(poly, np.array(n, float), c)
    area = 0.5 * abs(sum(poly[i][0] * poly[(i + 1) % len(poly)][1] - poly[(i + 1) % len(poly)][0] * poly[i][1] for i in range(len(poly))))
    return poly, area
umbral = int(sys.argv[1]) if len(sys.argv) > 1 else 100
margen = float(sys.argv[2]) if len(sys.argv) > 2 else 0.03
for k in [8, 12, 16]:                      # área de cada celda con 8, 12 y 16 lados (8 basta)
    tot = []
    for c in range(4):
        a = im[(c // 2) * H:(c // 2 + 1) * H, (c % 2) * W:(c % 2 + 1) * W, 3]
        poly, area = dop(a >= umbral, k, margen)
        tot.append((len(poly), round(area, 3), round((a >= 128).mean(), 3)))
    print(k, tot)

# salida en GDScript (8 direcciones)
print("const MATAS_CASCO := [")
for c in range(4):
    a = im[(c // 2) * H:(c // 2 + 1) * H, (c % 2) * W:(c % 2 + 1) * W, 3]
    poly, area = dop(a >= umbral, 8, margen)
    print("\t[" + ", ".join("Vector2(%.4f, %.4f)" % (p[0], p[1]) for p in poly) + "],   # celda %d: %.0f %% del cuadro" % (c, area * 100))
print("]")
