# Utilidades de síntesis y proceso (numpy). Todo determinista.
import hashlib
import numpy as np
import wavio

SR = 44100
RAIZ = "D:/qtorrent/sound effect/"
LIC_SONNISS = ("Sonniss #GameAudioGDC Bundle Licensing Agreement; PDF de licencia en la raiz del paquete "
               "(SHA-256 d5da822dce9462890c4cc84663e7bb461f8cff434850a4b8144e9b89cb3b516c, identico en 2016-2023), "
               "leido el 2026-11-14: uso sin atribucion en proyectos personales y comerciales, sincronizacion con "
               "juegos, editar como parte de la produccion; prohibido vender los sonidos tal cual o atribuirse su autoria")

PROCEDENCIA = []
_hash = {}
_cache = {}


def sha(ruta):
    if ruta not in _hash:
        h = hashlib.sha256()
        with open(ruta, "rb") as f:
            for b in iter(lambda: f.read(1 << 20), b""):
                h.update(b)
        _hash[ruta] = h.hexdigest()
    return _hash[ruta]


def cargar(rel, desde=0.0, hasta=None, capa="", uso="", version=""):
    """Tramo [desde, hasta) del original, en estéreo a 44,1 kHz. Registra la procedencia."""
    ruta = RAIZ + rel
    if ruta not in _cache:
        _cache[ruta] = wavio.leer(ruta)
    x, sr = _cache[ruta]
    a = int(desde * sr)
    b = len(x) if hasta is None else min(len(x), int(hasta * sr))
    seg = wavio.a_estereo_44k(x[a:b].copy(), sr)
    PROCEDENCIA.append(dict(version=version, capa=capa, uso=uso, ruta=rel, desde=desde,
                            hasta=(len(x) / sr if hasta is None else min(hasta, len(x) / sr)),
                            sha256=sha(ruta), sr=sr, canales=x.shape[1]))
    return seg


def db(v):
    return 10.0 ** (v / 20.0)


def tiempo(n):
    return np.arange(n) / SR


def env(t, puntos):
    """Envolvente en dB por puntos (s, dB); <= -100 dB es silencio."""
    ts = [p[0] for p in puntos]
    ds = [p[1] for p in puntos]
    v = np.interp(t, ts, ds)
    g = 10.0 ** (v / 20.0)
    g[v <= -100] = 0.0
    return g


def estereo(m):
    m = np.asarray(m, dtype=np.float64)
    return np.stack([m, m], axis=1) if m.ndim == 1 else m


def paneo(x, p):
    """p en -1..1 (escalar o array por muestra), potencia constante."""
    x = estereo(x)
    p = np.clip(p, -1, 1)
    ang = (p + 1) * np.pi / 4
    gl = np.cos(ang) * np.sqrt(2)
    gr = np.sin(ang) * np.sqrt(2)
    y = x.copy()
    y[:, 0] *= gl
    y[:, 1] *= gr
    return y


def pico_inicio(x, umbral_db=-20.0):
    """Índice de la primera muestra que supera (pico + umbral)."""
    m = np.abs(x).max(axis=1)
    lim = m.max() * db(umbral_db)
    return int(np.argmax(m >= lim))


def colocar(pista, x, t, ganancia_db=0.0, alinear_inicio=False, fade_in=0.002, fade_out=0.01, pan=None):
    """Suma x en pista empezando en t (s). Si alinear_inicio, el ataque de x cae en t."""
    x = estereo(x).copy()
    if pan is not None:
        x = paneo(x, pan)
    off = pico_inicio(x) if alinear_inicio else 0
    n = len(x)
    fi = max(1, int(fade_in * SR))
    fo = max(1, int(fade_out * SR))
    if alinear_inicio and off > 0:
        # recorte hasta poco antes del ataque, con fundido muy corto
        pre = min(off, int(0.004 * SR))
        x = x[off - pre:]
        off = pre
        n = len(x)
        fi = max(1, pre)
    w = np.ones(n)
    w[:fi] = np.linspace(0, 1, fi) if fi < n else w[:fi]
    w[-fo:] *= np.linspace(1, 0, fo)
    x *= w[:, None] * db(ganancia_db)
    i0 = int(round(t * SR)) - off
    a = max(0, i0)
    b = min(len(pista), i0 + n)
    if b > a:
        pista[a:b] += x[a - i0:b - i0]


def fft_filtro(x, resp):
    """Filtro de fase cero: resp(f) -> ganancia."""
    x = estereo(x)
    n = len(x)
    nfft = 1 << int(np.ceil(np.log2(n + 4096)))
    f = np.fft.rfftfreq(nfft, 1 / SR)
    g = resp(f)
    y = np.fft.irfft(np.fft.rfft(x, nfft, axis=0) * g[:, None], nfft, axis=0)[:n]
    return y


def pb(fc, orden=2):
    return lambda f: 1.0 / np.sqrt(1.0 + (f / fc) ** (2 * orden))


def pa(fc, orden=2):
    return lambda f: 1.0 / np.sqrt(1.0 + (fc / np.maximum(f, 1e-3)) ** (2 * orden))


def banda(fl, fh, orden=2):
    a, b = pa(fl, orden), pb(fh, orden)
    return lambda f: a(f) * b(f)


def stft_filtro(x, fn, nfft=2048, hop=512):
    """Filtro variable en el tiempo: fn(tc[F], f[B]) -> ganancia [F, B]."""
    x = estereo(x)
    n = len(x)
    pad = nfft
    xp = np.zeros((n + 2 * pad, 2))
    xp[pad:pad + n] = x
    win = np.sqrt(np.hanning(nfft + 1)[:-1])
    nfr = (len(xp) - nfft) // hop + 1
    f = np.fft.rfftfreq(nfft, 1 / SR)
    tc = (np.arange(nfr) * hop + nfft / 2 - pad) / SR
    g = fn(tc, f)
    y = np.zeros_like(xp)
    for c in range(2):
        fr = np.lib.stride_tricks.sliding_window_view(xp[:, c], nfft)[::hop][:nfr] * win
        sp = np.fft.rfft(fr, axis=1) * g
        out = np.fft.irfft(sp, nfft, axis=1) * win
        for i in range(nfr):
            y[i * hop:i * hop + nfft, c] += out[i]
    y /= (nfft / hop) / 2.0
    return y[pad:pad + n]


def remuestrear(x, factor):
    """factor > 1 sube el tono (más corto); < 1 lo baja (más largo)."""
    x = estereo(x)
    if factor > 1:
        x = fft_filtro(x, pb(0.45 * SR / factor, 8))
    pos = np.arange(0, len(x) - 1, factor)
    return np.stack([np.interp(pos, np.arange(len(x)), x[:, c]) for c in range(2)], axis=1)


_rng_ruido = {}


def ruido(n, semilla, estereo_dec=True):
    rng = np.random.default_rng(semilla)
    if estereo_dec:
        return rng.standard_normal((n, 2))
    m = rng.standard_normal(n)
    return np.stack([m, m], axis=1)


def ir_sala(rt60=2.6, predelay=0.025, semilla=7, oscuro=3500.0):
    """Respuesta al impulso sintética, estéreo decorrelada, con los agudos que mueren antes."""
    n = int((rt60 * 1.2 + predelay) * SR)
    t = tiempo(n)
    r = ruido(n, semilla)
    graves = fft_filtro(r, pb(oscuro, 2)) * (10 ** (-3 * t / rt60))[:, None]
    agudos = fft_filtro(r, pa(oscuro, 2)) * (10 ** (-3 * t / (rt60 * 0.35)))[:, None]
    ir = (graves + 0.5 * agudos)
    # ataque suave y predelay
    ir *= np.clip(t / 0.03, 0, 1)[:, None]
    p = int(predelay * SR)
    ir = np.vstack([np.zeros((p, 2)), ir[:n - p]])
    ir /= np.sqrt((ir ** 2).sum(axis=0, keepdims=True))
    return ir


def reverb(x, ir, mezcla_db=-8.0, seco=1.0):
    x = estereo(x)
    n = len(x)
    m = n + len(ir)
    nfft = 1 << int(np.ceil(np.log2(m)))
    X = np.fft.rfft(x, nfft, axis=0)
    H = np.fft.rfft(ir, nfft, axis=0)
    # cada canal de la entrada alimenta su IR (L->L, R->R) y una parte cruzada
    yl = np.fft.irfft(X[:, 0] * H[:, 0] + 0.35 * X[:, 1] * H[:, 1], nfft)[:n]
    yr = np.fft.irfft(X[:, 1] * H[:, 1] + 0.35 * X[:, 0] * H[:, 0], nfft)[:n]
    return seco * x + db(mezcla_db) * np.stack([yl, yr], axis=1)


def fase(f):
    return 2 * np.pi * np.cumsum(f) / SR


def aditivo(f0, amp, corte, n_arm=48, voces=(-6.0, 0.0, 6.5), pendiente=1.0, semilla=1, impares=1.0):
    """Tono rico: suma de armónicos (1/n^pendiente) con pasabajos por armónico variable en el tiempo.
    f0, amp, corte: arrays por muestra. Devuelve estéreo (voces repartidas)."""
    n = len(f0)
    rng = np.random.default_rng(semilla)
    y = np.zeros((n, 2))
    for k, cents in enumerate(voces):
        fv = f0 * 2 ** (cents / 1200.0)
        ph = fase(fv) + rng.uniform(0, 2 * np.pi)
        v = np.zeros(n)
        for h in range(1, n_arm + 1):
            fh = fv * h
            if fh.min() > 9000:
                break
            a = (1.0 / h ** pendiente) / np.sqrt(1 + (fh / corte) ** 4)
            if h % 2 == 0:
                a = a * impares
            a = np.where(fh < 9000, a, 0.0)
            v += a * np.sin(h * ph)
        p = 0.0 if len(voces) == 1 else -0.6 + 1.2 * k / (len(voces) - 1)
        y += paneo(v, p)
    return y * (amp / len(voces))[:, None]


def golpe_sub(dur, f0=58.0, f1=31.0, tau=0.09, decay=0.6):
    t = tiempo(int(dur * SR))
    f = f1 + (f0 - f1) * np.exp(-t / tau)
    s = np.sin(fase(f)) * np.exp(-t / decay)
    s += 0.25 * np.sin(2 * fase(f)) * np.exp(-t / (decay * 0.5))
    s *= np.clip(t / 0.002, 0, 1)
    return estereo(s)


def campana(f, dur=2.2, semilla=3, brillo=1.0):
    """Campanilla inarmónica (tipo vidrio/metal), original."""
    t = tiempo(int(dur * SR))
    rng = np.random.default_rng(semilla)
    parc = [(1.0, 1.0, 1.6), (2.0, 0.18, 0.9), (2.76, 0.45 * brillo, 0.8), (5.40, 0.22 * brillo, 0.45),
            (8.93, 0.10 * brillo, 0.25), (13.34, 0.05 * brillo, 0.15)]
    s = np.zeros((len(t), 2))
    for r, a, d in parc:
        fr = f * r
        if fr > 15000:
            continue
        bat = rng.uniform(0.2, 0.9)
        for c, sg in enumerate((-1, 1)):
            s[:, c] += a * np.sin(2 * np.pi * (fr + sg * bat / 2) * t + rng.uniform(0, 6.28)) * np.exp(-t / (d * dur / 2.2))
    s *= np.clip(t / 0.0015, 0, 1)[:, None]
    return s


def destello_metal(dur=1.6, f=1480.0, semilla=11):
    t = tiempo(int(dur * SR))
    rng = np.random.default_rng(semilla)
    rat = [1.0, 1.47, 2.09, 2.56, 3.39, 4.11, 5.23]
    s = np.zeros((len(t), 2))
    for i, r in enumerate(rat):
        d = 0.9 / (1 + 0.35 * i)
        for c in range(2):
            fr = f * r * (1 + rng.uniform(-0.002, 0.002))
            s[:, c] += (0.8 ** i) * np.sin(2 * np.pi * fr * t + rng.uniform(0, 6.28)) * np.exp(-t / d)
    clic = ruido(len(t), semilla) * np.exp(-t / 0.004)[:, None] * 0.6
    s += fft_filtro(clic, pa(3000))
    s *= np.clip(t / 0.001, 0, 1)[:, None]
    return s


def soplido(dur, centro, ancho_oct, amp, semilla, pan=None):
    """Ráfaga de ruido con banda variable. centro, amp: funciones de t -> array."""
    n = int(dur * SR)
    r = ruido(n, semilla)

    def fn(tc, f):
        c = centro(tc)[:, None]
        lf = np.log2(np.maximum(f, 1.0))[None, :]
        return np.exp(-0.5 * ((lf - np.log2(c)) / (ancho_oct / 2.0)) ** 2)

    y = stft_filtro(r, fn)
    y *= amp(tiempo(n))[:, None]
    if pan is not None:
        y = paneo(y, pan(tiempo(n)))
    return y


def rms_db(x):
    return 20 * np.log10(np.sqrt(np.mean(np.asarray(x) ** 2)) + 1e-12)


# ---------- Medidas ----------

def k_ponderacion(f):
    """Magnitud de la ponderación K (BS.1770): estante agudo +4 dB y pasaaltos ~38 Hz."""
    # estante de la norma, aproximado en magnitud
    fs_ = 1681.97
    G = 3.99984
    Q = 0.7071752
    s = 1j * f / fs_
    V = 10 ** (G / 20)
    H1 = (V * s ** 2 + np.sqrt(V) / Q * s + 1) / (s ** 2 + s / Q + 1)
    # en la norma el estante es "alto": ganancia en agudos
    H1 = (s ** 2 * V + s * np.sqrt(V) / Q + 1) / (s ** 2 + s / Q + 1)
    fh = 38.135
    s2 = 1j * f / fh
    H2 = s2 ** 2 / (s2 ** 2 + s2 / 0.5003 + 1)
    return np.abs(H1) * np.abs(H2)


def lufs(x):
    """Sonoridad integrada (BS.1770-4, puertas absoluta y relativa) y corto plazo máx (3 s)."""
    x = estereo(x)
    y = fft_filtro(x, k_ponderacion)
    p = (y ** 2).sum(axis=1)  # canales L y R con peso 1
    blk = int(0.4 * SR)
    hop = int(0.1 * SR)
    if len(p) < blk:
        return -70.0, -70.0
    cs = np.concatenate([[0], np.cumsum(p)])
    idx = np.arange(0, len(p) - blk + 1, hop)
    z = (cs[idx + blk] - cs[idx]) / blk
    l = -0.691 + 10 * np.log10(z + 1e-15)
    z1 = z[l > -70]
    if len(z1) == 0:
        return -70.0, -70.0
    rel = -0.691 + 10 * np.log10(z1.mean()) - 10
    z2 = z1[(-0.691 + 10 * np.log10(z1 + 1e-15)) > rel]
    integ = -0.691 + 10 * np.log10(z2.mean())
    b3 = int(3 * SR)
    if len(p) >= b3:
        idx3 = np.arange(0, len(p) - b3 + 1, hop)
        st = -0.691 + 10 * np.log10((cs[idx3 + b3] - cs[idx3]) / b3 + 1e-15)
        stmax = st.max()
    else:
        stmax = integ
    return integ, stmax


def pico_real(x, sobre=4):
    """Pico verdadero estimado con sobremuestreo x4 (FFT)."""
    x = estereo(x)
    n = len(x)
    X = np.fft.rfft(x, axis=0)
    Y = np.zeros((n * sobre // 2 + 1, 2), dtype=complex)
    Y[:X.shape[0]] = X
    y = np.fft.irfft(Y, n * sobre, axis=0) * sobre
    return 20 * np.log10(np.abs(y).max() + 1e-12)


def limitador(x, techo_db=-1.3, anticipo=0.005, relajacion=0.12):
    """Limitador con anticipación (bloques de 1 ms). Devuelve (y, reducción máxima en dB)."""
    x = estereo(x)
    techo = db(techo_db)
    a = np.abs(x).max(axis=1)
    blk = int(0.001 * SR)
    nb = int(np.ceil(len(a) / blk))
    ap = np.zeros(nb * blk)
    ap[:len(a)] = a
    mb = ap.reshape(nb, blk).max(axis=1)
    g_obj = np.minimum(1.0, techo / np.maximum(mb, 1e-9))
    la = int(anticipo * 1000)
    # mínimo hacia delante (anticipación)
    gmin = g_obj.copy()
    for k in range(1, la + 2):
        gmin[:-k] = np.minimum(gmin[:-k], g_obj[k:])
    g = np.empty(nb)
    cur = 1.0
    coef = np.exp(-1.0 / (relajacion * 1000))
    for i in range(nb):
        objetivo = gmin[i]
        cur = objetivo if objetivo < cur else objetivo + (cur - objetivo) * coef
        g[i] = cur
    gs = np.interp(np.arange(len(a)), np.arange(nb) * blk + blk / 2, g)
    y = x * gs[:, None]
    # seguridad final
    y = np.clip(y, -techo, techo)
    return y, -20 * np.log10(g.min())
