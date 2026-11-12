# Hojas de comparación de Humbaba frente a la lámina de referencia del usuario (V12, 12/11). Sin instalar nada: Blender
# por guion (numpy). Cada celda es una foto o un recorte de la lámina, encajado (sin deformar) en la celda. La lámina no
# se copia al juego: solo se lee para la hoja, que va a D:\REBELUM_diagnostico (fuera del repositorio).
#   blender -b --factory-startup -P hoja_referencia_humbaba.py -- <salida.png> <lámina> <columnas> <ancho> <alto>
#           <elemento> <elemento> …
#   <elemento>: la ruta de una foto, «ref:x0:y0:x1:y1» (recorte de la lámina en fracciones 0-1, origen arriba a la
#   izquierda) o «-» (celda vacía). Franja ocre bajo cada recorte de la lámina y gris bajo cada foto del modelo.
import bpy, sys
import numpy as np

args = sys.argv[sys.argv.index("--") + 1:]
salida, lamina, cols, CW, CH = args[0], args[1], int(args[2]), int(args[3]), int(args[4])
elementos = args[5:]
FONDO = np.array([0.12, 0.11, 0.1, 1.0], np.float32)


def cargar(ruta):
    im = bpy.data.images.load(ruta)
    w, h = im.size
    px = np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]
    bpy.data.images.remove(im)
    return px


def encajar(px, w, h):
    ph, pw = px.shape[:2]
    k = min(w / pw, h / ph)
    nw, nh = max(1, int(pw * k)), max(1, int(ph * k))
    ys = np.clip((np.arange(nh) + 0.5) / k, 0, ph - 1).astype(int)
    xs = np.clip((np.arange(nw) + 0.5) / k, 0, pw - 1).astype(int)
    lienzo = np.zeros((h, w, 4), np.float32) + FONDO
    y0, x0 = (h - nh) // 2, (w - nw) // 2
    lienzo[y0:y0 + nh, x0:x0 + nw] = px[ys][:, xs]
    lienzo[..., 3] = 1.0
    return lienzo


ref = cargar(lamina)
RH, RW = ref.shape[:2]
print("LAMINA", RW, RH)
celdas = []
for e in elementos:
    if e == "-":
        c = np.zeros((CH, CW, 4), np.float32) + FONDO
    elif e.startswith("ref:"):
        x0, y0, x1, y1 = [float(v) for v in e[4:].split(":")]
        c = encajar(ref[int(y0 * RH):int(y1 * RH), int(x0 * RW):int(x1 * RW)], CW, CH)
        c[-6:] = np.array([0.85, 0.6, 0.2, 1.0], np.float32)
    else:
        c = encajar(cargar(e), CW, CH)
        c[-6:] = np.array([0.5, 0.5, 0.55, 1.0], np.float32)
    c[:, -2:] = 0.0
    c[-2:, :] = 0.0
    c[..., 3] = 1.0
    celdas.append(c)
while len(celdas) % cols:
    celdas.append(np.zeros((CH, CW, 4), np.float32) + FONDO)
filas = [np.concatenate(celdas[i:i + cols], axis=1) for i in range(0, len(celdas), cols)]
hoja = np.ascontiguousarray(np.concatenate(filas, axis=0)[::-1])
H, W = hoja.shape[:2]
out = bpy.data.images.new("hoja", W, H, alpha=True)
out.pixels.foreach_set(hoja.ravel())
out.filepath_raw = salida
out.file_format = "PNG"
out.save()
print("HOJA", salida, W, H)
