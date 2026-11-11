# Compone una hoja PNG con varias fotos (rejilla), reducidas a la mitad o a lo que se pida. Sin instalar nada: Blender
# por guion (numpy). Para comparar las variantes de Bramavidrio v3 (fuente/crear_bramavidrio3.py) en el combate real.
#   blender -b --factory-startup -P hoja_fotos.py -- <salida.png> <columnas> <reducción 1|2|3> <foto1.png> <foto2.png> …
# Las fotos van de izquierda a derecha y de arriba abajo; todas del mismo tamaño.
import bpy, sys
import numpy as np

args = sys.argv[sys.argv.index("--") + 1:]
salida, cols, red, fotos = args[0], int(args[1]), int(args[2]), args[3:]
ims = []
for r in fotos:
    im = bpy.data.images.load(r)
    w, h = im.size
    px = np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]      # de arriba abajo
    bpy.data.images.remove(im)
    if red > 1:
        px = px[:h - h % red, :w - w % red].reshape(h // red, red, w // red, red, 4).mean(axis=(1, 3))
    ims.append(px)
h, w = ims[0].shape[:2]
while len(ims) % cols:
    ims.append(np.zeros((h, w, 4), np.float32) + np.array([0.1, 0.1, 0.12, 1.0], np.float32))
filas = [np.concatenate(ims[i:i + cols], axis=1) for i in range(0, len(ims), cols)]
hoja = np.concatenate(filas, axis=0)[::-1]
H, W = hoja.shape[:2]
out = bpy.data.images.new("hoja", W, H, alpha=True)
out.pixels.foreach_set(np.ascontiguousarray(hoja).ravel())
out.filepath_raw = salida
out.file_format = "PNG"
out.save()
print("HOJA", salida, W, H)
