# Utilidades de imagen con numpy dentro de Blender (sin instalar nada): cargar, guardar, recortar y reescalar por área.
import os
import bpy
import numpy as np

def cargar(path):
    im = bpy.data.images.load(os.path.abspath(path), check_existing=False)   # Blender no lee rutas relativas
    im.colorspace_settings.name = 'Non-Color'   # sin conversiones: los valores tal cual están en el PNG
    w, h = im.size
    px = np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1].copy()
    bpy.data.images.remove(im)
    return px

def guardar(px, path):
    h, w = px.shape[:2]
    im = bpy.data.images.new("tmp_guardar", w, h, alpha=True)
    im.colorspace_settings.name = 'Non-Color'
    im.pixels[:] = np.clip(px[::-1], 0, 1).astype(np.float32).ravel()
    im.filepath_raw = os.path.abspath(path)
    im.file_format = 'PNG'
    im.save()
    bpy.data.images.remove(im)

def bbox(px, umbral=0.02):
    ys, xs = np.nonzero(px[:, :, 3] > umbral)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1

def _matriz_area(n_in, n_out):
    # pesos de área: cada píxel de salida promedia la parte de la entrada que cubre
    A = np.zeros((n_out, n_in), dtype=np.float64)
    f = n_in / n_out
    for o in range(n_out):
        a, b = o * f, (o + 1) * f
        i0, i1 = int(np.floor(a)), int(np.ceil(b))
        for i in range(i0, min(i1, n_in)):
            peso = min(b, i + 1) - max(a, i)
            if peso > 0:
                A[o, i] = peso
        A[o] /= A[o].sum()
    return A

def reescalar(px, w_out, h_out):
    # reescalado por área con alfa premultiplicado (sin halos en los bordes)
    pre = px.copy().astype(np.float64)
    pre[:, :, :3] *= pre[:, :, 3:4]
    Ay = _matriz_area(px.shape[0], h_out)
    Ax = _matriz_area(px.shape[1], w_out)
    out = np.einsum('oi,ijc->ojc', Ay, pre)
    out = np.einsum('pj,ojc->opc', Ax, out)
    a = out[:, :, 3:4]
    out[:, :, :3] = np.where(a > 1e-6, out[:, :, :3] / np.maximum(a, 1e-6), 0)
    return out.astype(np.float32)

def lienzo(w, h):
    return np.zeros((h, w, 4), dtype=np.float32)

def pegar(fondo, img, x, y):
    # «over» con alfa (no premultiplicado en la entrada)
    h, w = img.shape[:2]
    reg = fondo[y:y+h, x:x+w]
    a = img[:, :, 3:4]
    ao = reg[:, :, 3:4]
    a_out = a + ao * (1 - a)
    c = np.where(a_out > 1e-6, (img[:, :, :3] * a + reg[:, :, :3] * ao * (1 - a)) / np.maximum(a_out, 1e-6), 0)
    fondo[y:y+h, x:x+w, :3] = c
    fondo[y:y+h, x:x+w, 3:4] = a_out
    return fondo
