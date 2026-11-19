# Blender (fondo, 19/11): comprueba la máscara de la llave del Custodio (p3_mascara_llave.py). Cuenta las caras que NO son
# de la llave y tocan la máscara (muestreo denso de su triángulo UV, con filtrado bilineal como en Godot): «LEJOS» son las
# de fuera del pecho (deben ser 0: brillarían en otro sitio); las de alrededor de la llave son sus bordes. «CUBRE»: qué
# parte de la llave (muestras de sus caras) queda con la máscara ≥ 0,5.
# Uso: blender -b --factory-startup -P p3_comprobar_mascara.py -- <glb> <mascara png> <llave_caras.json>
import bpy, sys, json

args = sys.argv[sys.argv.index("--") + 1:]
glb, mascara, caras_json = args[0], args[1], args[2]
llave = set(json.load(open(caras_json, encoding="utf-8"))["caras"])
bpy.ops.wm.read_factory_settings(use_empty=True)
img = bpy.data.images.load(mascara)
W, H = img.size
px = list(img.pixels[:])


def m(u, v):                                     # bilineal
    x = u * W - 0.5
    y = v * H - 0.5
    x0, y0 = int(x // 1), int(y // 1)
    fx, fy = x - x0, y - y0
    def p(xx, yy):
        xx = min(W - 1, max(0, xx)); yy = min(H - 1, max(0, yy))
        return px[(yy * W + xx) * 4]
    return (p(x0, y0) * (1 - fx) + p(x0 + 1, y0) * fx) * (1 - fy) + (p(x0, y0 + 1) * (1 - fx) + p(x0 + 1, y0 + 1) * fx) * fy


bpy.ops.import_scene.gltf(filepath=glb)
o = bpy.data.objects["e01_cuerpo"]
me = o.data
uv = me.uv_layers.active.data
fugas = []
dentro = 0
total = 0
for p in me.polygons:
    if p.index in llave:
        us = [uv[li].uv for li in p.loop_indices]
        for k in range(1, len(us) - 1):
            a, b, c = us[0], us[k], us[k + 1]
            for i in range(7):
                for j in range(7 - i):
                    w1, w2 = i / 6, j / 6
                    w0 = 1 - w1 - w2
                    total += 1
                    dentro += m(a.x * w0 + b.x * w1 + c.x * w2, a.y * w0 + b.y * w1 + c.y * w2) >= 0.5
        continue
    us = [uv[li].uv for li in p.loop_indices]
    mx = 0.0
    N = 6
    for k in range(1, len(us) - 1):
        a, b, c = us[0], us[k], us[k + 1]
        for i in range(N + 1):
            for j in range(N + 1 - i):
                w1, w2 = i / N, j / N
                w0 = 1 - w1 - w2
                mx = max(mx, m(a.x * w0 + b.x * w1 + c.x * w2, a.y * w0 + b.y * w1 + c.y * w2))
    if mx > 0.02:
        c3 = o.matrix_world @ p.center
        fugas.append((round(mx, 3), p.index, [round(c3.x, 3), round(c3.y, 3), round(c3.z, 3)]))
fugas.sort(reverse=True)
print("FUGAS", len(fugas))
lejos = [f for f in fugas if not (abs(f[2][0]) < 0.06 and f[2][1] < -0.15 and 1.22 < f[2][2] < 1.5)]
print("LEJOS", len(lejos))
print("CUBRE %.1f %% de la llave (%d de %d muestras)" % (100.0 * dentro / max(1, total), dentro, total))
for f in lejos:
    print("FUGA", f)
