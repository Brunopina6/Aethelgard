# Héroes v3 (V12): textura de DETALLE común a los tres (512 × 512, RGBA, repetible), hecha por código con numpy.
# Cada canal es un patrón en gris alrededor de 0,5 que el sombreador usa según el tipo de material:
#   R tela: trama fina y algo de irregularidad;
#   G pelo: hebras (rayas a lo largo de v, que en los mechones va de la raíz a la punta);
#   B grano: ruido de varias escalas (cuero, metal, piel muy suave);
#   A pliegues: ondas largas a lo largo de v (la caída de la tela del abrigo y las mangas).
# Las UV de la geometría van en metros (geometria_v3.py); el sombreador las escala por tipo.
import numpy as np


def _ruido(n, freq, seed):
    """Ruido de valor repetible: rejilla freq × freq interpolada (coseno)."""
    rng = np.random.default_rng(seed)
    g = rng.random((freq, freq)).astype(np.float32)
    x = np.arange(n) / n * freq
    i0 = np.floor(x).astype(int) % freq
    i1 = (i0 + 1) % freq
    t = x - np.floor(x)
    t = (1 - np.cos(t * np.pi)) * 0.5
    a = g[i0][:, i0] * (1 - t)[None, :] + g[i0][:, i1] * t[None, :]
    b = g[i1][:, i0] * (1 - t)[None, :] + g[i1][:, i1] * t[None, :]
    return a * (1 - t)[:, None] + b * t[:, None]


def _fractal(n, freqs, seed):
    r = np.zeros((n, n), dtype=np.float32)
    tot = 0.0
    for k, f in enumerate(freqs):
        w = 1.0 / (k + 1)
        r += _ruido(n, f, seed + k) * w
        tot += w
    return r / tot


def textura(n=512):
    y, x = np.mgrid[0:n, 0:n].astype(np.float32) / n
    # R tela
    trama = 0.5 + 0.5 * np.sin(2 * np.pi * 64 * x) * np.sin(2 * np.pi * 64 * y)
    R = 0.5 + (trama - 0.5) * 0.35 + (_fractal(n, [8, 16, 32], 11) - 0.5) * 0.6
    # G pelo: hebras a lo largo de y (v): rayas en x con fases y grosores al azar, algo onduladas
    rng = np.random.default_rng(5)
    G = np.zeros((n, n), dtype=np.float32)
    onda = (_ruido(n, 4, 21) - 0.5) * 0.04
    for f in (6, 11, 17, 23, 31, 42, 57):
        fase = rng.random() * 2 * np.pi
        G += np.sin(2 * np.pi * f * (x + onda) + fase) * (1.0 / np.sqrt(f))
    G = (G - G.min()) / (G.max() - G.min())
    G = 0.5 + (G - 0.5) * 0.9 + (_ruido(n, 8, 31) - 0.5) * 0.15
    # B grano
    B = _fractal(n, [16, 32, 64, 128], 41)
    B = 0.5 + (B - B.mean()) * 1.6
    # A pliegues: ondas largas en x (alrededor), casi constantes en y (a lo largo)
    A = np.zeros((n, n), dtype=np.float32)
    rng = np.random.default_rng(9)
    for f in (3, 5, 7, 11):
        A += np.sin(2 * np.pi * f * (x + (_ruido(n, 2, 50 + f) - 0.5) * 0.15) + rng.random() * 6.28) / f
    A = (A - A.min()) / (A.max() - A.min())
    img = np.stack([R, G, B, A], axis=-1)
    return np.clip(img, 0, 1).astype(np.float32)


def guardar(ruta, n=512):
    import bpy
    img = textura(n)
    im = bpy.data.images.new("heroe_v3_detalle", n, n, alpha=True)
    im.colorspace_settings.name = 'Non-Color'
    im.alpha_mode = 'CHANNEL_PACKED'
    im.pixels[:] = img[::-1].ravel()
    im.filepath_raw = ruta
    im.file_format = 'PNG'
    im.save()
    bpy.data.images.remove(im)
