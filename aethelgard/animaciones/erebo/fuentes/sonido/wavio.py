# Lectura y escritura de WAV con numpy (PCM 8/16/24/32, float 32/64, WAVE_FORMAT_EXTENSIBLE).
import struct
import numpy as np


def leer(ruta):
    """Devuelve (datos float64 [n, canales], frecuencia)."""
    with open(ruta, "rb") as f:
        b = f.read()
    if b[:4] != b"RIFF" or b[8:12] != b"WAVE":
        raise ValueError("no es WAV: %s" % ruta)
    pos = 12
    fmt = None
    datos = None
    while pos + 8 <= len(b):
        cid = b[pos:pos + 4]
        tam = struct.unpack("<I", b[pos + 4:pos + 8])[0]
        cuerpo = b[pos + 8:pos + 8 + tam]
        if cid == b"fmt ":
            tag, ch, sr, _, _, bits = struct.unpack("<HHIIHH", cuerpo[:16])
            if tag == 0xFFFE and len(cuerpo) >= 26:
                tag = struct.unpack("<H", cuerpo[24:26])[0]
            fmt = (tag, ch, sr, bits)
        elif cid == b"data":
            datos = cuerpo
        pos += 8 + tam + (tam & 1)
    tag, ch, sr, bits = fmt
    if tag == 3:
        x = np.frombuffer(datos[:len(datos) // (bits // 8) * (bits // 8)],
                          dtype="<f4" if bits == 32 else "<f8").astype(np.float64)
    elif bits == 16:
        x = np.frombuffer(datos[:len(datos) // 2 * 2], dtype="<i2") / 32768.0
    elif bits == 24:
        n = len(datos) // 3
        a = np.frombuffer(datos[:n * 3], dtype=np.uint8).reshape(-1, 3).astype(np.int32)
        v = a[:, 0] | (a[:, 1] << 8) | (a[:, 2] << 16)
        v = np.where(v >= 1 << 23, v - (1 << 24), v)
        x = v / float(1 << 23)
    elif bits == 32:
        x = np.frombuffer(datos[:len(datos) // 4 * 4], dtype="<i4") / 2147483648.0
    elif bits == 8:
        x = (np.frombuffer(datos, dtype=np.uint8).astype(np.float64) - 128) / 128.0
    else:
        raise ValueError("formato no soportado %s" % (fmt,))
    n = len(x) // ch
    return x[:n * ch].reshape(n, ch), sr


def escribir(ruta, x, sr=44100):
    """x float [n, 2] en -1..1 -> PCM 16 bits con tramado TPDF."""
    x = np.asarray(x, dtype=np.float64)
    if x.ndim == 1:
        x = x[:, None]
    rng = np.random.default_rng(12345)
    d = (rng.random(x.shape) - rng.random(x.shape)) / 32768.0
    v = np.clip(np.round((x + d) * 32767.0), -32768, 32767).astype("<i2")
    datos = v.tobytes()
    ch = x.shape[1]
    cab = b"RIFF" + struct.pack("<I", 36 + len(datos)) + b"WAVE"
    cab += b"fmt " + struct.pack("<IHHIIHH", 16, 1, ch, sr, sr * ch * 2, ch * 2, 16)
    cab += b"data" + struct.pack("<I", len(datos))
    with open(ruta, "wb") as f:
        f.write(cab + datos)


def a_estereo_44k(x, sr):
    """Convierte a estéreo y remuestrea a 44 100 Hz (interpolación por bloques con filtro previo)."""
    if x.shape[1] == 1:
        x = np.repeat(x, 2, axis=1)
    elif x.shape[1] > 2:
        x = x[:, :2]
    if sr != 44100:
        n2 = int(round(len(x) * 44100 / sr))
        # filtro antialias simple (sinc enventanado) si se baja de frecuencia
        if sr > 44100:
            fc = 0.5 * 44100 / sr * 0.95
            m = 63
            t = np.arange(m) - (m - 1) / 2
            h = 2 * fc * np.sinc(2 * fc * t) * np.blackman(m)
            h /= h.sum()
            x = np.stack([np.convolve(x[:, c], h, mode="same") for c in range(2)], axis=1)
        ti = np.arange(n2) * (sr / 44100.0)
        x = np.stack([np.interp(ti, np.arange(len(x)), x[:, c]) for c in range(2)], axis=1)
    return x
