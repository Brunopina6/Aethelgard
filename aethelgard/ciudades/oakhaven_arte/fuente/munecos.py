# Muñecos del mundo 2D de los vecinos nuevos de Oakhaven (T-089), a partir de los de siempre (personajes/npc/):
# no un tinte de toda la figura, sino otra ropa: cada color se cambia por zonas de tono (la piel, el pelo y el
# dibujo se conservan). Mismo tamaño, mismo estilo y la misma silueta que su figura de partida.
#   posadera  ← aldeana: vestido color vino y corpiño oscuro; en la cesta, panecillos en vez de flores
#   bastian   ← pícaro:  pañuelo y chaleco azules, calzas pardas (narrativa lo dibuja a 0,8: es un niño)
#   encina    ← maga:    túnica y sombrero verde musgo, adornos de bronce, piedra del bastón verde (pelo blanco: anciana)
#   albar     ← caballero: sobreveste y escudo gris ceniza, adornos y pelo de plata (sereno y frío, como su crematorio)
# Uso: blender -b --factory-startup -P munecos.py -- <carpeta personajes/npc> <carpeta de salida>
import sys, os, colorsys
sys.dont_write_bytecode = True          # sin __pycache__ en la carpeta del proyecto
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import numpy as np
import util_img as U

args = sys.argv[sys.argv.index("--") + 1:]
ORIGEN = args[0]
SALIDA = args[1]
os.makedirs(SALIDA, exist_ok=True)


def hsv(px):
    r, g, b = px[:, :, 0], px[:, :, 1], px[:, :, 2]
    mx = np.max(px[:, :, :3], axis=2)
    mn = np.min(px[:, :, :3], axis=2)
    d = mx - mn
    h = np.zeros_like(mx)
    m = d > 1e-6
    rr = m & (mx == r)
    gg = m & (mx == g) & ~rr
    bb = m & ~rr & ~gg
    h[rr] = ((g[rr] - b[rr]) / d[rr]) % 6.0
    h[gg] = (b[gg] - r[gg]) / d[gg] + 2.0
    h[bb] = (r[bb] - g[bb]) / d[bb] + 4.0
    h = h * 60.0
    s = np.where(mx > 1e-6, d / np.maximum(mx, 1e-6), 0.0)
    return h, s, mx


def rgb(h, s, v):
    h = (h % 360.0) / 60.0
    i = np.floor(h).astype(int) % 6
    f = h - np.floor(h)
    p = v * (1 - s)
    q = v * (1 - s * f)
    t = v * (1 - s * (1 - f))
    out = np.zeros(h.shape + (3,), np.float32)
    for k, (a, b, c) in enumerate(((v, t, p), (q, v, p), (p, v, t), (p, q, v), (t, p, v), (v, p, q))):
        sel = i == k
        out[sel, 0] = a[sel]
        out[sel, 1] = b[sel]
        out[sel, 2] = c[sel]
    return out


def cambiar(px, reglas, zona=None):
    """reglas: (tono_min, tono_max, sat_min, val_min, tono_nuevo | None, × saturación, × valor). zona: (x0, y0, x1, y1)
    en fracciones de la imagen (la regla solo vale ahí)."""
    h, s, v = hsv(px)
    H, W = h.shape
    yy, xx = np.mgrid[0:H, 0:W]
    out_h, out_s, out_v = h.copy(), s.copy(), v.copy()
    for regla in reglas:
        h0, h1, smin, vmin, hn, fs, fv = regla[:7]
        z = regla[7] if len(regla) > 7 else None
        if h0 <= h1:
            sel = (h >= h0) & (h <= h1)
        else:
            sel = (h >= h0) | (h <= h1)
        sel &= (s >= smin) & (v >= vmin) & (px[:, :, 3] > 0.01)
        if z is not None:
            sel &= (xx >= z[0] * W) & (xx < z[2] * W) & (yy >= z[1] * H) & (yy < z[3] * H)
        if hn is not None:
            out_h[sel] = hn
        out_s[sel] = np.clip(s[sel] * fs, 0, 1)
        out_v[sel] = np.clip(v[sel] * fv, 0, 1)
    res = px.copy()
    res[:, :, :3] = rgb(out_h, out_s, out_v)
    return res


RECETAS = {
    # vestido verde → vino; las flores de la cesta (amarillas, rosas y blancas, abajo en el centro) → panecillos
    "posadera": ("aldeana.png", [
        (70, 170, 0.18, 0.05, 352, 1.05, 0.82),
        (40, 69, 0.35, 0.3, 30, 0.75, 0.78, (0.25, 0.62, 0.75, 0.9)),
        (300, 359, 0.15, 0.3, 28, 0.7, 0.72, (0.25, 0.62, 0.75, 0.9)),
        (0, 25, 0.15, 0.55, 30, 0.75, 0.75, (0.25, 0.62, 0.75, 0.9)),
    ]),
    # pañuelo y chaleco rojos → azules; pantalón verde oscuro → pardo
    "bastian": ("picaro.png", [
        (340, 18, 0.35, 0.12, 214, 0.85, 0.95),
        (60, 170, 0.12, 0.05, 30, 0.7, 0.85),
    ]),
    # azules → verde musgo; dorados → bronce; la piedra del bastón → verde
    "encina": ("maga.png", [
        (190, 265, 0.15, 0.05, 98, 0.62, 0.86),
        (35, 62, 0.35, 0.3, 32, 0.6, 0.82),
    ]),
    # azules → gris ceniza (casi sin color, algo más claro); dorados y el pelo rubio → plata vieja
    "albar": ("caballero.png", [
        (190, 265, 0.12, 0.05, 220, 0.12, 1.3),
        (12, 62, 0.45, 0.25, 40, 0.08, 1.05),
    ]),
}

for nombre, (origen, reglas) in RECETAS.items():
    px = U.cargar(os.path.join(ORIGEN, origen))
    nuevo = cambiar(px, reglas)
    nuevo[:, :, 3] = px[:, :, 3]
    U.guardar(nuevo, os.path.join(SALIDA, nombre + ".png"))
    print("MUÑECO %s ← %s (%d×%d)" % (nombre, origen, px.shape[1], px.shape[0]))
