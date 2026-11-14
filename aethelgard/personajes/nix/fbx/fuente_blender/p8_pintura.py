# Nix vestuario (V12, 14/11): utilidades para pintar texturas POR POSICIÓN (sin pintar a mano).
# Se rasteriza cada triángulo en su UV guardando, por texel, el triángulo y las baricéntricas; con eso se interpola
# cualquier dato por vértice (posición en reposo, normal, parámetros de construcción) y los dibujos (bordados, emblema,
# medias) se calculan en coordenadas del cuerpo (metros), así no dependen de cómo quedó el desplegado UV.
import numpy as np


def rasterizar(uv_px, S):
    """uv_px: (T, 3, 2) en píxeles (x a la derecha, y hacia ARRIBA como en UV). Devuelve tri (S,S) int32 (-1 vacío) y
    bary (S,S,3). La fila 0 del mapa es v = 0 (abajo), como bpy.Image.pixels."""
    tri = np.full((S, S), -1, np.int32)
    bary = np.zeros((S, S, 3), np.float32)
    for t in range(uv_px.shape[0]):
        a, b, c = uv_px[t]
        x0 = max(int(np.floor(min(a[0], b[0], c[0]))) - 1, 0)
        x1 = min(int(np.ceil(max(a[0], b[0], c[0]))) + 1, S - 1)
        y0 = max(int(np.floor(min(a[1], b[1], c[1]))) - 1, 0)
        y1 = min(int(np.ceil(max(a[1], b[1], c[1]))) + 1, S - 1)
        if x1 < x0 or y1 < y0:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        if abs(den) < 1e-12:
            continue
        l0 = ((b[1] - c[1]) * (xs - c[0]) + (c[0] - b[0]) * (ys - c[1])) / den
        l1 = ((c[1] - a[1]) * (xs - c[0]) + (a[0] - c[0]) * (ys - c[1])) / den
        l2 = 1.0 - l0 - l1
        e = -1e-3
        m = (l0 >= e) & (l1 >= e) & (l2 >= e)
        if not m.any():
            continue
        sub_t = tri[y0:y1 + 1, x0:x1 + 1]
        sub_b = bary[y0:y1 + 1, x0:x1 + 1]
        sub_t[m] = t
        sub_b[m] = np.stack([l0[m], l1[m], l2[m]], -1)
    return tri, bary


def interpolar(tri, bary, tri_vert, datos):
    """datos (V, k) por vértice -> (N, k) en los texeles ocupados (en el orden de np.nonzero(tri >= 0))."""
    m = tri >= 0
    t = tri[m]
    b = bary[m]
    v = tri_vert[t]                       # (N, 3)
    return (datos[v[:, 0]] * b[:, 0:1] + datos[v[:, 1]] * b[:, 1:2] + datos[v[:, 2]] * b[:, 2:3])


def dilatar(img, ocupado, pasos=8):
    """Rellena los texeles vacíos con la media de sus vecinos ocupados (márgenes de las islas: sin costuras al filtrar)."""
    img = img.copy()
    occ = ocupado.copy()
    for _ in range(pasos):
        acc = np.zeros_like(img)
        n = np.zeros(occ.shape, np.float32)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            o = np.roll(occ, (dy, dx), (0, 1))
            acc += np.roll(img, (dy, dx), (0, 1)) * o[..., None]
            n += o
        nuevo = (~occ) & (n > 0)
        img[nuevo] = acc[nuevo] / n[nuevo][:, None]
        occ = occ | nuevo
    return img


def reducir(img):
    """De 2S a S promediando 2x2 (antialias del dibujo)."""
    h, w = img.shape[:2]
    return img.reshape(h // 2, 2, w // 2, 2, -1).mean((1, 3))


# ---------------------------------------------------------------- dibujo con campos de distancia (en metros)
def d_segmentos(P, pts):
    """Distancia mínima de P (N,2) a la polilínea pts (M,2)."""
    d = np.full(P.shape[0], 1e9, np.float32)
    for i in range(len(pts) - 1):
        a = np.asarray(pts[i], np.float32)
        b = np.asarray(pts[i + 1], np.float32)
        ab = b - a
        L = float(ab @ ab)
        if L < 1e-12:
            continue
        t = np.clip(((P - a) @ ab) / L, 0.0, 1.0)
        q = a + t[:, None] * ab
        d = np.minimum(d, np.linalg.norm(P - q, axis=1))
    return d


def trazo(d, ancho, aa):
    """Cobertura (0..1) de una línea de medio ancho «ancho» a partir de la distancia, con antialias aa."""
    return np.clip((ancho + aa - d) / (2 * aa), 0.0, 1.0)


def dentro_poligono(P, poli):
    """Máscara de P (N,2) dentro del polígono (lista de puntos)."""
    x, y = P[:, 0], P[:, 1]
    dentro = np.zeros(P.shape[0], bool)
    n = len(poli)
    for i in range(n):
        x1, y1 = poli[i]
        x2, y2 = poli[(i + 1) % n]
        c = ((y1 > y) != (y2 > y)) & (x < (x2 - x1) * (y - y1) / (y2 - y1 + 1e-12) + x1)
        dentro ^= c
    return dentro


def hoja(P, centro, ang, largo, ancho):
    """Cobertura suave de una hoja (elipse apuntada) en P (N,2)."""
    c = np.asarray(centro, np.float32)
    ca, sa = np.cos(ang), np.sin(ang)
    q = P - c
    u = q[:, 0] * ca + q[:, 1] * sa
    v = -q[:, 0] * sa + q[:, 1] * ca
    a = largo * 0.5
    # más estrecha en las puntas: ancho * (1 - (u/a)^2)
    lim = ancho * 0.5 * np.clip(1.0 - (u / a) ** 2, 0.0, 1.0)
    return np.clip((lim - np.abs(v)) / 0.0012 + 0.5, 0.0, 1.0) * (np.abs(u) < a)


def ruido(P3, semilla=0, escala=1.0):
    """Ruido suave (-1..1) a partir de la posición 3D: suma de ondas con direcciones fijas."""
    rng = np.random.default_rng(semilla)
    n = np.zeros(P3.shape[0], np.float32)
    for i in range(7):
        k = rng.normal(size=3)
        k = k / np.linalg.norm(k) * (18.0 + 26.0 * i) * escala
        n += np.sin(P3 @ k + rng.uniform(0, 6.28)) / (1.0 + i * 0.6)
    return n / 2.6


def enredadera(largo, ancho_onda, paso, semilla, fase=0.0):
    """Tallo ondulado (polilínea en coordenadas (a, b): a a lo largo, b de lado) y hojas alternas."""
    a = np.linspace(0.0, largo, max(8, int(largo / 0.006)))
    b = ancho_onda * np.sin(2 * np.pi * a / paso + fase)
    tallo = np.stack([a, b], -1)
    hojas = []
    rng = np.random.default_rng(semilla)
    k = 0
    for ai in np.arange(paso * 0.25, largo - paso * 0.1, paso * 0.5):
        bi = ancho_onda * np.sin(2 * np.pi * ai / paso + fase)
        lado = 1 if k % 2 == 0 else -1
        ang = lado * (0.9 + rng.uniform(-0.15, 0.15))
        L = paso * 0.38
        cx = ai + np.cos(ang) * L * 0.45
        cy = bi + np.sin(ang) * L * 0.45
        hojas.append(((cx, cy), ang, L, L * 0.38))
        k += 1
    return tallo, hojas
