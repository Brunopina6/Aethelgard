# Retratos finales (T-084): reduce cada render a 1/3 (por área, con alfa premultiplicado), iguala el color con el
# retrato original (ajuste por mínimos cuadrados entre el «control» y kael.png, en sus píxeles interiores) y recorta
# todos con el MISMO lienzo: el alto del original más MARGEN arriba (para el pelo de las poses que suben la cabeza),
# los pies en el borde de abajo y el centro donde estaba el centro del original. Así, al cambiar de pose en el diálogo
# nada se desplaza, y con la escala del .dch compensada (×624/620) el personaje sale del mismo tamaño que antes.
#   blender -b -P finalizar.py -- <original.png> <carpeta_crudos> <poses> <carpeta_salida> <prefijo> [pose=nombre,...]
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from numpy.lib.stride_tricks import sliding_window_view
import imgutil as U

argv = sys.argv[sys.argv.index("--") + 1:]
orig = U.cargar(argv[0]); carpeta = argv[1]; poses = argv[2].split(","); salida = argv[3]; prefijo = argv[4]
renombrar = dict(p.split("=") for p in argv[5].split(",")) if len(argv) > 5 and argv[5] else {}
MARGEN = 4
os.makedirs(salida, exist_ok=True)


def reducido(n):
    im = U.cargar(os.path.join(carpeta, "crudo_%s.png" % n))
    return U.reescalar(im, im.shape[1] // 3, im.shape[0] // 3)


ctrl = reducido("control")
x0, y0, x1, y1 = U.bbox(ctrl, 0.5)
assert (y1 - y0, x1 - x0) == orig.shape[:2], ((y1 - y0, x1 - x0), orig.shape)
c = ctrl[y0:y1, x0:x1]
m = (orig[:, :, 3] > 0.99) & (c[:, :, 3] > 0.99)
ero = sliding_window_view(np.pad(m, 2), (5, 5)).all(axis=(2, 3))     # lejos de los bordes de las siluetas
X = c[:, :, :3][ero].astype(np.float64); Y = orig[:, :, :3][ero].astype(np.float64)


def feats(X):
    return np.concatenate([X, X ** 2, np.ones((len(X), 1))], 1)


A, *_ = np.linalg.lstsq(feats(X), Y, rcond=None)
print("AJUSTE: diferencia media %.4f -> %.4f (0-1), %d píxeles" % (np.abs(X - Y).mean(), np.abs(feats(X) @ A - Y).mean(), len(X)))


def color(im):
    h, w = im.shape[:2]
    o = im.copy()
    o[:, :, :3] = np.clip((feats(im[:, :, :3].reshape(-1, 3).astype(np.float64)) @ A).reshape(h, w, 3), 0, 1)
    return o


red = {n: reducido(n) for n in poses}
cx = (x0 + x1) / 2.0
media = 0
for n, im in red.items():
    bx0, by0, bx1, by1 = U.bbox(im, 0.02)
    media = max(media, cx - bx0, bx1 - cx)
    if by0 < y0 - MARGEN or by1 > y1 + 1:
        print("AVISO: la pose %s se sale del lienzo (%d..%d frente a %d..%d)" % (n, by0, by1, y0 - MARGEN, y1))
W = int(np.ceil(media)) * 2 + 4
lx0 = int(round(cx - W / 2.0))
print("LIENZO %dx%d (el original: %dx%d)" % (W, y1 - y0 + MARGEN, x1 - x0, y1 - y0))
for n, im in red.items():
    if n == "control":
        continue
    rec = color(im[y0 - MARGEN:y1, lx0:lx0 + W])
    p = os.path.join(salida, "%s_%s.png" % (prefijo, renombrar.get(n, n)))
    U.guardar(rec, p)
    print("RETRATO", p, rec.shape[1], "x", rec.shape[0])
