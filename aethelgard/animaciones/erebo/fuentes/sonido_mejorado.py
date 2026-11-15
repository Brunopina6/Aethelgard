# V12 (15/11): sonido de la cinemática MEJORADA de Érebo (docs/v12/EREBO_CINEMATICA_V12.md §10).
#   blender -b --factory-startup --python sonido_mejorado.py -- <mezcla_14_11.wav> <salida.wav> <version>
# Parte de la mezcla del 14/11 (del especialista de sonido, −16 LUFS; no se toca el original) y añade, sincronizados al
# fotograma con la imagen mejorada:
#   · el DESTELLO FINAL (19,7 s / 6,65 s): en la mezcla de siempre lo más fuerte cerca era la ráfaga que se aleja, que
#     llega 0,3-0,4 s antes de la luz; ahora un golpe sordo y un brillo metálico caen en el mismo fotograma del destello;
#   · la ONDA DEL AGARRE (9,85 s / 2,6 s): un siseo brillante muy corto encima del golpe que ya había (la onda de choque
#     y las chispas nuevas);
#   · la CARGA DEL PUÑO (16,4-17,0 s / 4,9-5,15 s): un zumbido grave que crece bajo la pausa (sin romper el silencio:
#     −30 dB) y se corta en seco en el estallido.
# Todo sintetizado (sin muestras ajenas), determinista; al final un limitador suave deja el pico ≤ −1 dBFS.
import sys, wave, math
import numpy as np

a = sys.argv[sys.argv.index("--") + 1:]
ent, sal, version = a[0], a[1], a[2]
T = {"completa": dict(agarre=9.85, quieto=16.4, libera=17.0, destello=19.7),
     "abreviada": dict(agarre=2.6, quieto=4.9, libera=5.15, destello=6.55)}[version]
w = wave.open(ent, "rb")
sr, n, ch = w.getframerate(), w.getnframes(), w.getnchannels()
x = np.frombuffer(w.readframes(n), dtype=np.int16).reshape(-1, ch).astype(np.float64) / 32768.0
w.close()
rng = np.random.default_rng(1915)


def env(dur, ataque, caida):
    t = np.arange(int(dur * sr)) / sr
    return np.minimum(t / max(ataque, 1e-4), 1.0) * np.exp(-t / caida), t


def suma(pos_s, y, gan_db, pan=0.0):
    i0 = int(round(pos_s * sr))
    y = y * 10 ** (gan_db / 20)
    i1 = min(len(x), i0 + len(y))
    if i1 <= i0:
        return
    l = math.cos((pan + 1) * math.pi / 4); r = math.sin((pan + 1) * math.pi / 4)
    x[i0:i1, 0] += y[:i1 - i0] * l * 1.414
    x[i0:i1, 1] += y[:i1 - i0] * r * 1.414


def golpe_sordo(dur=0.5):
    e, t = env(dur, 0.004, 0.14)
    f = 70 * np.exp(-t * 6) + 30
    return np.sin(2 * np.pi * np.cumsum(f) / sr) * e


def brillo_metalico(dur=1.4):
    e, t = env(dur, 0.006, 0.38)
    y = np.zeros_like(t)
    for k, f in enumerate((1760, 2349, 2794, 3520, 4186, 5274)):        # parciales inarmónicos, la/re/fa...
        y += np.sin(2 * np.pi * f * (1 + 0.0007 * k) * t + k) * (0.9 ** k)
    return y / 4 * e * (1 + 0.15 * np.sin(2 * np.pi * 7 * t))


def siseo(dur=0.35):
    e, t = env(dur, 0.002, 0.06)
    r = rng.standard_normal(len(t))
    r = r - np.convolve(r, np.ones(6) / 6, mode="same")                    # paso alto sencillo: brillante
    return r * e * 0.6


def zumbido_carga(dur):
    t = np.arange(int(dur * sr)) / sr
    sube = (t / dur) ** 2
    f = 46 + 20 * sube
    return np.sin(2 * np.pi * np.cumsum(f) / sr) * sube * (1 + 0.3 * np.sin(2 * np.pi * (3 + 14 * sube) * t))


suma(T["destello"] - 0.004, golpe_sordo(), -11.0)
suma(T["destello"], brillo_metalico(), -17.0, 0.2)
suma(T["destello"] + 0.01, brillo_metalico(), -20.0, -0.3)
suma(T["agarre"], siseo(), -16.0)
carga = zumbido_carga(T["libera"] - T["quieto"])
suma(T["quieto"], carga, -30.0)
# limitador suave: pico ≤ −1 dBFS
pico = np.max(np.abs(x))
techo = 10 ** (-1.0 / 20)
if pico > techo:
    x = np.tanh(x / techo) * techo
# fundido final igual que la mezcla (50 ms) para acabar en 0
nf = int(0.05 * sr)
x[-nf:] *= np.linspace(1, 0, nf)[:, None]
y = np.clip(x * 32767, -32768, 32767).astype(np.int16)
w = wave.open(sal, "wb")
w.setnchannels(ch); w.setsampwidth(2); w.setframerate(sr)
w.writeframes(y.tobytes())
w.close()
print("SONIDO %s: pico %.2f dBFS, RMS %.2f dBFS" % (version, 20 * math.log10(np.max(np.abs(y)) / 32768 + 1e-9),
                                                 20 * math.log10(np.sqrt(np.mean((y / 32768.0) ** 2)) + 1e-9)))
