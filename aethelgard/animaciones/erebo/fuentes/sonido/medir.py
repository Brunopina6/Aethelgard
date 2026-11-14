# Verificación independiente de los WAV entregados (los relee del disco). Escribe verificacion.txt y PNG.
import sys, os, struct, zlib, wave
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
import dsp, wavio
from dsp import SR

D = sys.argv[sys.argv.index("--") + 1]
MARCAS = {
    "completa": dict(dur=20.0, eventos=[("latido", 0.30), ("latido", 1.40), ("latido", 2.40), ("latido", 3.10), ("latido", 3.60),
                                        ("motivo re", 5.40), ("la b", 6.10), ("sol", 6.80), ("acorde+destello", 7.40),
                                        ("AGARRE", 9.85), ("reanuda", 10.10), ("sacudida", 12.50), ("sacudida", 13.80),
                                        ("orbe muerto", 15.00), ("latido pausa", 16.70), ("LIBERACION", 17.00), ("destello", 19.70)],
                     silencios=[("congelado", 9.96, 10.095), ("pausa sin latido", 16.45, 16.69)]),
    "abreviada": dict(dur=6.8, eventos=[("latido", 0.06), ("latido", 0.55), ("motivo re", 0.80), ("acorde+destello", 1.45),
                                        ("AGARRE", 2.60), ("reanuda", 2.75), ("sacudida", 3.60), ("latido pausa", 4.99),
                                        ("LIBERACION", 5.15), ("destello", 6.65)],
                      silencios=[("congelado", 2.68, 2.745), ("pausa sin latido", 4.93, 4.985)]),
}


def png(ruta, img):
    h, w, _ = img.shape
    raw = b"".join(b"\x00" + img[y].astype(np.uint8).tobytes() for y in range(h))
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    with open(ruta, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def salto_grave(y, t, rango=0.04, grave=True):
    """Momento (ventanas de 0,5 ms) de mayor subida de nivel (en graves <200 Hz, o de banda completa) cerca de t."""
    g = dsp.fft_filtro(y, dsp.pb(200, 4)) if grave else y
    a = int((t - rango - 0.03) * SR)
    b = int((t + rango) * SR)
    win = int(0.0005 * SR)
    m = np.abs(g[a:b]).max(axis=1)
    e = 20 * np.log10(np.array([m[i:i + win].max() for i in range(0, len(m) - win, win)]) + 1e-9)
    prev = int(0.03 / 0.0005)
    sub = [e[i] - e[i - prev:i].max() for i in range(prev, len(e))]
    k = int(np.argmax(sub))
    return (a + (k + prev) * win) / SR, sub[k]


lineas = []
for nombre, m in MARCAS.items():
    ruta = os.path.join(D, "erebo_cine_%s.wav" % nombre)
    with wave.open(ruta) as w:
        cab = (w.getnchannels(), w.getframerate(), w.getsampwidth() * 8, w.getnframes())
    y, sr = wavio.leer(ruta)
    integ, stmax = dsp.lufs(y)
    lineas.append("== %s: canales=%d frecuencia=%d bits=%d muestras=%d duracion=%.4f s" % (nombre, *cab, cab[3] / cab[1]))
    lineas.append("   pico muestra %.2f dBFS | pico real x4 %.2f dBTP | RMS %.2f dBFS | sonoridad integrada %.2f LUFS | corto plazo max %.2f LUFS"
                  % (20 * np.log10(np.abs(y).max()), dsp.pico_real(y), dsp.rms_db(y), integ, stmax))
    lineas.append("   primera/ultima muestra: %s / %s (en unidades de 16 bits)" % (np.round(y[0] * 32768).astype(int).tolist(), np.round(y[-1] * 32768).astype(int).tolist()))
    ult = y[-int(0.25 * SR):-int(0.05 * SR)]
    lineas.append("   200 ms antes del fundido final: pico %.1f dBFS, RMS %.1f dBFS (debe sonar: rafaga que se aleja)" % (20 * np.log10(np.abs(ult).max()), dsp.rms_db(ult)))
    for et, a, b in m["silencios"]:
        seg = y[int(a * SR):int(b * SR)]
        pk = np.abs(seg).max()
        lineas.append("   silencio '%s' %.3f-%.3f s: pico %s, RMS %.1f dBFS" % (et, a, b, "%.1f dBFS" % (20 * np.log10(pk)) if pk > 0 else "0 (silencio digital)", dsp.rms_db(seg)))
    for et, t in m["eventos"]:
        if et in ("AGARRE", "LIBERACION", "reanuda", "latido pausa", "sacudida"):
            ts, sube = salto_grave(y, t)
            tb, sb = salto_grave(y, t, grave=False)
            lineas.append("   %-16s previsto %.3f s -> mayor subida: graves %.4f s (%+.1f ms, +%.1f dB); banda completa %.4f s (%+.1f ms, +%.1f dB)" % (et, t, ts, (ts - t) * 1000, sube, tb, (tb - t) * 1000, sb))
    # imagen: forma de onda (máx/mín por columna) con marcas
    W, H = 1600, 360
    img = np.full((H, W, 3), (7, 5, 12), dtype=np.int32)
    mono = np.abs(y).max(axis=1)
    n = len(mono)
    for x in range(W):
        s = mono[x * n // W:(x + 1) * n // W]
        v = s.max() if len(s) else 0
        r = np.sqrt(np.mean(s ** 2)) if len(s) else 0
        hv = int(v * (H / 2 - 10))
        hr = int(r * (H / 2 - 10))
        img[H // 2 - hv:H // 2 + hv + 1, x] = (138, 60, 255)
        img[H // 2 - hr:H // 2 + hr + 1, x] = (255, 42, 109)
    for db_ in (-1.0,):
        hy = int(dsp.db(db_) * (H / 2 - 10))
        img[H // 2 - hy, :, :] = (90, 90, 90)
        img[H // 2 + hy, :, :] = (90, 90, 90)
    for et, t in m["eventos"]:
        x = int(t / m["dur"] * (W - 1))
        col = (255, 255, 255) if et.isupper() else (207, 214, 255)
        img[::3 if not et.isupper() else 1, x] = col
    png(os.path.join(D, "forma_onda_%s.png" % nombre), img)
open(os.path.join(D, "verificacion.txt"), "w", encoding="utf-8").write("\n".join(lineas) + "\n")
print("\n".join(lineas))
