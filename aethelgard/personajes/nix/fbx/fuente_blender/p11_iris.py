# Dónde están los iris de Nix en el atlas del cuerpo (14/11, tarde): solo MIDE (no cambia nada). De aquí salen los dos
# rectángulos «iris_a» e «iris_b» de nix_fbx_cuerpo.gdshader (en UV de Godot: v hacia abajo) con 3 texeles de margen.
#   blender -b --factory-startup -P p11_iris.py -- <blend con cuerpo_nix y su textura nix_color>
# Método: islas conexas de texeles violetas saturados (azul y rojo por encima del verde) del atlas; se quedan las dos
# grandes, que son los iris (comprobado a la vista con el recorte ampliado: iris rosa-violeta con su degradado; la
# pupila azul oscura, la esclerótica gris, las pestañas y la piel quedan fuera). Medido el 14/11: 445 y 309 texeles,
# x 476-497 / y 625-656 y x 325-345 / y 744-767 (filas de abajo arriba, como Blender), en una textura de 1024.
import bpy, sys
import numpy as np
a = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.open_mainfile(filepath=a[0])
tex = bpy.data.images["nix_color"]; TW, TH = tex.size
px = np.array(tex.pixels[:], np.float32).reshape(TH, TW, 4)[..., :3]
r, g, b = px[..., 0], px[..., 1], px[..., 2]
viol = (b - g > 0.10) & (r - g > 0.03) & (px.max(-1) - px.min(-1) > 0.15)
lab = np.full((TH, TW), -1, np.int32); n = 0
for y0, x0 in zip(*np.nonzero(viol)):
    if lab[y0, x0] >= 0:
        continue
    pila = [(y0, x0)]; lab[y0, x0] = n
    while pila:
        y, x = pila.pop()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            yy, xx = y + dy, x + dx
            if 0 <= yy < TH and 0 <= xx < TW and viol[yy, xx] and lab[yy, xx] < 0:
                lab[yy, xx] = n; pila.append((yy, xx))
    n += 1
islas = sorted(((int((lab == k).sum()), k) for k in range(n)), reverse=True)[:2]
M = 3
for c, k in islas:
    ys, xs = np.nonzero(lab == k)
    u0, u1 = (xs.min() - M) / TW, (xs.max() + 1 + M) / TW
    v0, v1 = 1.0 - (ys.max() + 1 + M) / TH, 1.0 - (ys.min() - M) / TH
    print("IRIS %d texeles  atlas x %d-%d y %d-%d  ->  vec4(%.4f, %.4f, %.4f, %.4f)" % (
        c, xs.min(), xs.max(), ys.min(), ys.max(), u0, v0, u1, v1))
