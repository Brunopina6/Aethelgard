# Blender (fondo, 19/11, C-9 / PC-5): la máscara de emisión de la «llave iluminada» del Custodio (meshy_e01_3d.gd). Elige
# las caras de la llave del pecho (zona 3D del pecho, de frente, y TODAS sus muestras de la textura de color naranjas: la
# llave es parte de la malla soldada, sin material propio), rasteriza sus triángulos UV a «tam» px con «dil» px de margen
# y borra (con 1 px más, por el filtrado bilineal) lo que caiga en caras lejos del pecho (otras islas UV). Escribe
# mascara_<tam>.png y llave_caras.json. Se hizo con: ... -- meshy_e01.glb meshy_e01_e01_color_1024.webp <salida> 512 2
# (50 caras; comprobado con p3_comprobar_mascara.py: 0 fugas lejos, 97 % de la llave cubierta). Si el GLB cambia, rehacer.
# Uso: blender -b --factory-startup -P p3_mascara_llave.py -- <glb> <webp color> <salida> <tam> [dil]
import bpy, sys, os, json, colorsys

args = sys.argv[sys.argv.index("--") + 1:]
glb, webp, salida, tam = args[0], args[1], args[2], int(args[3])
DIL = int(args[4]) if len(args) > 4 else 1
os.makedirs(salida, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
tex = bpy.data.images.load(webp)
W, H = tex.size
px = list(tex.pixels[:])                     # RGBA lineal por filas desde abajo


def color(u, v):
    x = min(W - 1, max(0, int(u * W)))
    y = min(H - 1, max(0, int(v * H)))
    i = (y * W + x) * 4
    return px[i], px[i + 1], px[i + 2]


bpy.ops.import_scene.gltf(filepath=glb)
o = bpy.data.objects["e01_cuerpo"]
me = o.data
mw = o.matrix_world
uv = me.uv_layers.active.data
caras = []
for p in me.polygons:
    c = mw @ p.center
    n = (mw.to_3x3() @ p.normal).normalized()
    if not (-0.05 < c.x < 0.06 and 1.24 < c.z < 1.50 and c.y < -0.10 and n.y < -0.2):
        continue
    # color de la cara: muestras en el centro UV y a medio camino de cada esquina; todas tienen que ser naranjas
    us = [uv[li].uv.copy() for li in p.loop_indices]
    cu = sum((q.x for q in us)) / len(us)
    cv = sum((q.y for q in us)) / len(us)
    muestras = [color(cu, cv)] + [color((cu + q.x) / 2, (cv + q.y) / 2) for q in us]
    def es_naranja(m):
        h, s, val = colorsys.rgb_to_hsv(*m)
        return 0.03 < h < 0.13 and s > 0.45 and val > 0.25
    h, s, val = colorsys.rgb_to_hsv(*muestras[0])
    naranja = all(es_naranja(m) for m in muestras)
    if naranja:
        caras.append({"i": p.index, "c": [c.x, c.y, c.z], "uv": [[q.x, q.y] for q in us], "hsv": [h, s, val]})

# máscara: rasteriza los triángulos UV de esas caras a tam × tam
mask = [0.0] * (tam * tam)


def tri(a, b, c, dest=None):
    dest = mask if dest is None else dest
    xs = [a[0], b[0], c[0]]
    ys = [a[1], b[1], c[1]]
    x0, x1 = int(min(xs)) - 2, int(max(xs)) + 3
    y0, y1 = int(min(ys)) - 2, int(max(ys)) + 3
    def lado(p, q, r):
        return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
    area = lado(a, b, c)
    for y in range(max(0, y0), min(tam, y1)):
        for x in range(max(0, x0), min(tam, x1)):
            q = (x + 0.5, y + 0.5)
            dentro = False
            if abs(area) > 1e-9:
                w0, w1, w2 = lado(b, c, q), lado(c, a, q), lado(a, b, q)
                dentro = (w0 >= 0 and w1 >= 0 and w2 >= 0) or (w0 <= 0 and w1 <= 0 and w2 <= 0)
            if dentro:
                dest[y * tam + x] = 1.0


for f in caras:
    ps = [(q[0] * tam, q[1] * tam) for q in f["uv"]]
    for k in range(1, len(ps) - 1):
        tri(ps[0], ps[k], ps[k + 1])
# margen de «dil» px (dilatación) para que el filtrado no deje un borde oscuro
for _ in range(DIL):
    nueva = mask[:]
    for y in range(tam):
        for x in range(tam):
            if mask[y * tam + x] > 0.0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                xx, yy = x + dx, y + dy
                if 0 <= xx < tam and 0 <= yy < tam and mask[yy * tam + xx] > 0.0:
                    nueva[y * tam + x] = 1.0
                    break
    mask = nueva

# fugas: las caras LEJOS de la llave (otras islas UV que comparten téxeles con ella) se borran de la máscara, con 1 px de
# margen (el filtrado bilineal lee el téxel vecino)
borrar = [0.0] * (tam * tam)
lejos = 0
for p in me.polygons:
    c = mw @ p.center
    if abs(c.x) < 0.07 and c.y < -0.12 and 1.2 < c.z < 1.52:
        continue
    lejos += 1
    ps = [(uv[li].uv.x * tam, uv[li].uv.y * tam) for li in p.loop_indices]
    for k in range(1, len(ps) - 1):
        tri(ps[0], ps[k], ps[k + 1], borrar)
antes = sum(1 for v in mask if v > 0.0)
for y in range(tam):
    for x in range(tam):
        if borrar[y * tam + x] > 0.0:
            for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
                xx, yy = x + dx, y + dy
                if 0 <= xx < tam and 0 <= yy < tam:
                    mask[yy * tam + xx] = 0.0
print("BORRADO", antes, "->", sum(1 for v in mask if v > 0.0), "caras lejos", lejos)

img = bpy.data.images.new("mascara", tam, tam, alpha=False, float_buffer=False)
img.colorspace_settings.name = "Non-Color"
datos = []
for v in mask:
    datos += [v, v, v, 1.0]
img.pixels[:] = datos
img.filepath_raw = os.path.join(salida, "mascara_%d.png" % tam)
img.file_format = "PNG"
img.save()
with open(os.path.join(salida, "llave_caras.json"), "w", encoding="utf-8") as fh:
    json.dump({"caras": [f["i"] for f in caras], "detalle": caras,
               "pixeles_mascara": sum(1 for v in mask if v > 0.0), "tam": tam}, fh, indent=1)
print("HECHO caras", len(caras), "pixeles", sum(1 for v in mask if v > 0.0))
