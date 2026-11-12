# Hojas de comparación de Bramavidrio v4 frente a la lámina de referencia del usuario (V12, 12/11). Sin instalar nada:
# Blender por guion (numpy). Cada celda es una foto o un recorte de la lámina, encajado (sin deformar) en la celda.
#   blender -b --factory-startup -P hoja_referencia_bramavidrio4.py -- <salida.png> <lámina.png> <columnas> <ancho> <alto>
#           <elemento> <elemento> …
#   <elemento>: la ruta de una foto, «ref:x0:y0:x1:y1» (un recorte de la lámina en píxeles, origen arriba a la
#   izquierda) o «-» (una celda vacía). Las celdas van de izquierda a derecha y de arriba abajo.
# Una franja ocre bajo cada recorte de la lámina y una gris bajo cada foto del modelo distinguen las dos filas.
import bpy, sys
import numpy as np

args = sys.argv[sys.argv.index("--") + 1:]
salida, lamina, cols, CW, CH = args[0], args[1], int(args[2]), int(args[3]), int(args[4])
elementos = args[5:]


def cargar(ruta):
    im = bpy.data.images.load(ruta)
    w, h = im.size
    px = np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]       # de arriba abajo
    bpy.data.images.remove(im)
    return px


def encajar(px, w, h):
    """Escala (vecino más cercano con promedio 2×2) para que quepa en w × h, centrada sobre fondo oscuro."""
    ph, pw = px.shape[:2]
    k = min(w / pw, h / ph)
    nw, nh = max(1, int(pw * k)), max(1, int(ph * k))
    ys = np.clip((np.arange(nh) + 0.5) / k, 0, ph - 1).astype(int)
    xs = np.clip((np.arange(nw) + 0.5) / k, 0, pw - 1).astype(int)
    r = px[ys][:, xs]
    lienzo = np.zeros((h, w, 4), np.float32) + np.array([0.12, 0.11, 0.1, 1.0], np.float32)
    y0, x0 = (h - nh) // 2, (w - nw) // 2
    lienzo[y0:y0 + nh, x0:x0 + nw] = r
    lienzo[..., 3] = 1.0
    return lienzo


ref = cargar(lamina)
celdas = []
for e in elementos:
    if e == "-":
        c = np.zeros((CH, CW, 4), np.float32) + np.array([0.12, 0.11, 0.1, 1.0], np.float32)
    elif e.startswith("ref:"):
        x0, y0, x1, y1 = [int(v) for v in e[4:].split(":")]
        c = encajar(ref[y0:y1, x0:x1], CW, CH)
        c[-6:] = np.array([0.85, 0.6, 0.2, 1.0], np.float32)
    else:
        c = encajar(cargar(e), CW, CH)
        c[-6:] = np.array([0.5, 0.5, 0.55, 1.0], np.float32)
    c[:, -2:] = 0.0
    c[-2:, :] = 0.0
    c[..., 3] = 1.0
    celdas.append(c)
while len(celdas) % cols:
    celdas.append(np.zeros((CH, CW, 4), np.float32) + np.array([0.12, 0.11, 0.1, 1.0], np.float32))
filas = [np.concatenate(celdas[i:i + cols], axis=1) for i in range(0, len(celdas), cols)]
hoja = np.ascontiguousarray(np.concatenate(filas, axis=0)[::-1])
H, W = hoja.shape[:2]
out = bpy.data.images.new("hoja", W, H, alpha=True)
out.pixels.foreach_set(hoja.ravel())
out.filepath_raw = salida
out.file_format = "PNG"
out.save()
print("HOJA", salida, W, H)
