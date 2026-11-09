# Utilidades de imagen con numpy dentro de Blender (sin instalar nada): cargar, guardar, recortar, desenfocar.
# Mismo criterio que dialogos/retratos/fuentes_blender/imgutil.py: los valores tal cual están en el archivo.
import os
import bpy
import numpy as np


def cargar(path):
    im = bpy.data.images.load(os.path.abspath(path), check_existing=False)
    im.colorspace_settings.name = 'Non-Color'
    w, h = im.size
    px = np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1].copy()
    bpy.data.images.remove(im)
    return px


def guardar(px, path, formato='PNG', calidad=92):
    h, w = px.shape[:2]
    im = bpy.data.images.new("tmp_guardar", w, h, alpha=True)
    im.colorspace_settings.name = 'Non-Color'
    im.pixels[:] = np.clip(px[::-1], 0, 1).astype(np.float32).ravel()
    im.filepath_raw = os.path.abspath(path)
    im.file_format = formato
    if formato == 'WEBP':
        im.save(filepath=os.path.abspath(path), quality=calidad)
    else:
        im.save()
    bpy.data.images.remove(im)


def bbox(alfa, umbral=1.0 / 255.0):
    ys, xs = np.nonzero(alfa > umbral)
    if len(xs) == 0:
        return None
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def desenfocar(canal, radio):
    """Desenfoque de caja separable (3 pasadas ≈ gaussiano)."""
    if radio <= 0:
        return canal
    out = canal.astype(np.float64)
    for _ in range(3):
        for eje in (0, 1):
            pad = [(0, 0), (0, 0)]
            pad[eje] = (radio, radio)
            p = np.pad(out, pad, mode='edge')
            c = np.cumsum(p, axis=eje)
            c = np.concatenate([np.zeros_like(np.take(c, [0], axis=eje)), c], axis=eje)
            n = 2 * radio + 1
            if eje == 0:
                out = (c[n:, :] - c[:-n, :]) / n
            else:
                out = (c[:, n:] - c[:, :-n]) / n
    return out.astype(np.float32)
