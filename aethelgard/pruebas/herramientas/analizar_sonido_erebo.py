# V12, Érebo híbrida (15/11): análisis del SONIDO de una grabación del Movie Maker (pruebas/grabar_erebo_hibrida.gd),
# ya convertida a MP4. Sin dependencias: ffmpeg (ruta en FFMPEG) + Python estándar.
#   py -3.10 -I analizar_sonido_erebo.py <video.mp4> <registro_de_la_grabacion.log> [salida.txt]
# Del registro toma «GRAB inicio», «GRAB fase <nombre> <s>» y «GRAB vuelta» (segundos del MP4).
# Da, por tramos (combate antes, tiempo real, ritual en vídeo, vuelta), la media y el pico (dBFS, ffmpeg volumedetect)
# y la SINCRONÍA: los destellos de la imagen (saltos de brillo medio, ffmpeg signalstats) frente al golpe de sonido
# más cercano (subida de energía en ventanas de 10 ms).
import io, os, re, struct, subprocess, sys, wave

FFMPEG = r"C:\Users\G513\Downloads\Hunyuan3D2_WinPortable\python_standalone\Scripts\ffmpeg.exe"
mp4, log = sys.argv[1], sys.argv[2]
salida = sys.argv[3] if len(sys.argv) > 3 else None
txt = io.open(log, encoding="utf-8", errors="replace").read()
ini = float(re.search(r"GRAB inicio ([\d.]+)", txt).group(1))
vuelta = float(re.search(r"GRAB vuelta ([\d.]+)", txt).group(1))
fases = {m.group(1): float(m.group(2)) for m in re.finditer(r"GRAB fase (\S+) ([\d.]+)", txt)}
musica = re.search(r"GRAB vuelta .*", txt).group(0)
out = []


def pr(s):
    print(s)
    out.append(s)


def volumen(t0, t1):
    r = subprocess.run([FFMPEG, "-hide_banner", "-ss", "%.3f" % t0, "-t", "%.3f" % max(0.05, t1 - t0), "-i", mp4,
                        "-vn", "-af", "volumedetect", "-f", "null", "-"], capture_output=True, text=True)
    m = re.search(r"mean_volume: ([-\d.]+)", r.stderr)
    p = re.search(r"max_volume: ([-\d.]+)", r.stderr)
    return (float(m.group(1)) if m else None, float(p.group(1)) if p else None)


r_ini = fases.get("video_arranca", None)
r_fin = fases.get("video_fin", None)
tramos = [("combate, antes de invocar", max(0.0, ini - 2.5), ini)]
if r_ini is not None:
    tramos += [("tiempo real (señal → orbe)", ini, r_ini - 0.3), ("ritual en vídeo", r_ini, r_fin or vuelta)]
else:
    tramos += [("tiempo real (toda la invocación)", ini, vuelta)]
tramos += [("combate, al volver (4 s)", vuelta + 0.5, vuelta + 3.9)]
pr("== %s" % os.path.basename(mp4))
pr("fases (s del MP4): " + ", ".join("%s %.2f" % (k, v) for k, v in fases.items()))
pr(musica)
for n, a, b in tramos:
    m, p = volumen(a, b)
    pr("VOLUMEN %-28s %6.2f-%6.2f s: media %s dB, pico %s dB" % (n, a, b, m, p))

# energía por ventanas de 10 ms (mono 16 bits)
wav = os.path.splitext(salida or mp4)[0] + "_tmp.wav"
subprocess.run([FFMPEG, "-loglevel", "error", "-y", "-i", mp4, "-vn", "-ac", "1", "-ar", "16000", wav], check=True)
w = wave.open(wav, "rb")
n = w.getnframes()
data = struct.unpack("<%dh" % n, w.readframes(n))
w.close()
os.remove(wav)
VEN = 160
ener = []
for i in range(0, n - VEN, VEN):
    s = sum(x * x for x in data[i:i + VEN]) / VEN
    ener.append(s)


def golpe_cerca(t, ventana=0.5):
    """El instante (s) de mayor subida de energía a ±ventana de t."""
    i0 = max(1, int((t - ventana) * 100))
    i1 = min(len(ener) - 1, int((t + ventana) * 100))
    mejor, ti = 0.0, None
    for i in range(i0, i1):
        sube = ener[i] - ener[i - 1]
        if sube > mejor:
            mejor, ti = sube, i / 100.0
    return ti


# brillo medio por fotograma
r = subprocess.run([FFMPEG, "-hide_banner", "-i", mp4, "-vf", "signalstats,metadata=print:key=lavfi.signalstats.YAVG",
                    "-an", "-f", "null", "-"], capture_output=True, text=True)
yavg = [float(x) for x in re.findall(r"lavfi\.signalstats\.YAVG=([\d.]+)", r.stderr)]
destellos = []
for i in range(1, len(yavg)):
    if yavg[i] - yavg[i - 1] > 25.0 and (not destellos or i / 30.0 - destellos[-1] > 0.5):
        destellos.append(i / 30.0)
pr("DESTELLOS de la imagen (subida de brillo medio > 25 en un fotograma): " + ", ".join("%.2f" % d for d in destellos))
for d in destellos:
    g = golpe_cerca(d)
    pr("SINCRONÍA destello %.2f s → golpe de sonido más cercano %s (desfase %s ms)" % (
        d, "%.2f s" % g if g is not None else "ninguno", "%+d" % round((g - d) * 1000) if g is not None else "—"))
if salida:
    io.open(salida, "w", encoding="utf-8").write("\n".join(out) + "\n")
