# Hoja de comparación: une imágenes PNG en una fila (o en filas de N columnas) con Blender y numpy.
#   blender -b --factory-startup -P hoja.py -- <salida.png> <columnas> <img1> <img2> ...
import sys, bpy
import numpy as np
argv = sys.argv[sys.argv.index("--") + 1:]
salida, cols, rutas = argv[0], int(argv[1]), argv[2:]
ims = []
for r in rutas:
    im = bpy.data.images.load(r)
    w, h = im.size
    a = np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4)
    ims.append(a)
H = max(a.shape[0] for a in ims); W = max(a.shape[1] for a in ims)
filas = (len(ims) + cols - 1) // cols
lz = np.full((filas * H, cols * W, 4), 0.8, dtype=np.float32); lz[:, :, 3] = 1
for i, a in enumerate(ims):
    f, c = i // cols, i % cols
    y0 = (filas - 1 - f) * H          # las filas de Blender van de abajo arriba
    lz[y0:y0 + a.shape[0], c * W:c * W + a.shape[1], :3] = a[:, :, :3]
out = bpy.data.images.new("hoja", cols * W, filas * H)
out.pixels[:] = lz.ravel()
out.filepath_raw = salida
out.file_format = 'PNG'
out.save()
print("HOJA", salida)
