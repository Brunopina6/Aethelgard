# Banda sonora de la invocación cinematográfica de Érebo (completa 20,0 s y abreviada 6,8 s).
# Uso: blender -b --factory-startup -P componer.py -- <carpeta_salida>
import sys, os, csv, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
import dsp
import wavio
from dsp import SR, db, env, colocar, cargar, tiempo, paneo, fft_filtro, pb, pa, banda, remuestrear

SALIDA = sys.argv[sys.argv.index("--") + 1]
os.makedirs(os.path.join(SALIDA, "stems"), exist_ok=True)

G16 = "Sonniss.com - GDC 2016- Game Audio Bundle/"
G17 = "Sonniss.com - GDC 2017 - Game Audio Bundle/"
G18 = "Sonniss.com - GDC 2018 - Game Audio Bundle/"
G19 = "Sonniss.com - GDC 2019 - Game Audio Bundle/"
G20 = "Sonniss.com - GDC 2020 - Game Audio Bundle/"
G23 = "Sonniss.com - GDC 2023 - Game Audio Bundle/"

F = dict(
    latido=G18 + "Airborne Sound - Human/Heartbeat,Sound Design,Pulse,Throb,Steady,Accelerate,Panic,Fear.wav",
    boom091=G19 + "Federico Soler Fernández - Effective Trailer Booms/Boom 091.wav",
    boom005=G19 + "Federico Soler Fernández - Effective Trailer Booms/Boom 005.wav",
    boom036=G19 + "Federico Soler Fernández - Effective Trailer Booms/Boom 036.wav",
    boom040=G19 + "Federico Soler Fernández - Effective Trailer Booms/Boom 040.wav",
    smash=G19 + "Federico Soler Fernández - Effective Trailer Hits & Impacts/Smash B.wav",
    braam=G20 + "Federico Soler Fernandez - Effective Trailer Braams/Braam 004 (D).wav",
    riser078=G20 + "Federico Soler Fernandez - Effective Trailer Risers/Riser 078.wav",
    riser088=G20 + "Federico Soler Fernandez - Effective Trailer Risers/Riser 088.wav",
    arco=G20 + "Sound Spark LLC - Electric Arcs and Energy/Electric_Arc_Reverberant_Shock_Long_05.wav",
    carga=G20 + "Sound Spark LLC - Electric Arcs and Energy/Electric_Energy_Ambient_Warble_Powerup_03.wav",
    grieta=G17 + "Chris Skyes - Shards Broken Glass/Window,Small,Crack,Medium Impact,Bright.wav",
    astillas=G17 + "Chris Skyes - Shards Broken Glass/Glass,Shards,Smash,Medium Impact,Lots of Large Shards.wav",
    iceberg=G17 + "Mattia Cellotto - Glacier Ice/Iceberg,Designed,Impact,Crack,Shatter,Huge_08.wav",
    bloque=G17 + "Mattia Cellotto - Glacier Ice/Ice,Block,Crack,Distant,Medium_03.wav",
    crujido=G17 + "Mindful Audio - Elements - Ice/thin ice cracks crunchy 06.wav",
    restos19=G17 + "Double Trouble Audio - Shards/SHARDS [MS Stereo] 19 - Drop, Glass, Table, Metal, Debree.wav",
    goteo24=G17 + "Double Trouble Audio - Shards/SHARDS [LD Mono] 24 - Trickle, Glass, Metal, Debree.wav",
    cristal23=G23 + "BluezoneCorp - Broken Glass/Bluezone_BC0274_glass_impact_break_falling_debris_004.wav",
    cuero=G17 + "Double Trouble Audio - Medieval Armor and Impacts/LeatherArmor_Rustle_03.wav",
    ropa=G16 + "3maze -  The Closet/shake_clothing_001.wav",
    capa=G16 + "SoundBits -  Just Whoosh 3 _ Whoosh Essentials/Whoosh_Cloth_Leather_Fight_174.wav",
    vocal=G16 + "Bottle Rocket Fx - Impact Collection/Whoosh_Twisted Vocal_04.wav",
    remolino=G16 + "Bottle Rocket Fx - The Drone Collection/Drone_Horror_Swirling Wind_01.wav",
    mazmorra=G16 + "Bottle Rocket Fx - The Drone Collection/Drone_DungeonRumble_01.wav",
    temblor=G17 + "Articulated Sounds - Ghosts/GHOSTS Tremor Disturbed Aura.LR.wav",
    impacto012=G17 + "Bluezone Corporation - Cinematic Trailer Sound Effects/Bluezone-BC0226-whoosh-impact-012.wav",
    doppler=G17 + "Glitchedtones - Whooshes & Transitions/Whoosh Transition Doppler FX 002.wav",
    voces=G18 + "Phil Michalski - IN MOTION/PM_InMotion_Voices_Ghosts.wav",
    cueva=G19 + "Articulated Sounds - Ghosts Return/ATMO EERIE Cave, Water Drips, Emptyness, Howling Interior Wind, Oppressive, LOOP.wav",
)

# Notas (Hz). Motivo: re - la bemol - sol.
D1, G1, AB1 = 36.71, 49.00, 51.91
D2, G2, AB2, D3 = 73.42, 98.00, 103.83, 146.83
CAMPANAS = [1174.66, 830.61, 783.99, 587.33, 1661.22, 1567.98, 1174.66]

# Tiempos de cada versión (s), sacados de docs/v12/EREBO_CINEMATICA_V12.md §2 y §3.
V = {
    "completa": dict(
        dur=20.0,
        latidos=[(0.30, -9, "d"), (1.40, -8, "d"), (2.40, -7, "d"), (3.10, -6, "d"), (3.60, -5, "d"),
                 (8.45, -12, "d"), (9.00, -10, "d"), (9.45, -8, "s"), (16.70, -11, "s")],
        runas=[2.00, 2.24, 2.46, 2.66, 2.84, 3.00, 3.14],
        zumbido=[(0.6, -50), (1.4, -30), (3.0, -22), (3.8, -19), (8.0, -17), (9.85, -10),
                 (10.1, -9), (11.6, -11), (13.0, -16), (15.0, -22)],
        zumbido_fin=15.0, vibra=3.0,
        bordon=[(3.8, -70), (4.7, -21), (8.0, -19), (9.85, -14), (10.1, -13), (11.6, -14), (15.0, -14),
                (15.4, -16), (16.4, -14)],
        temblor=(3.0, 3.8, 5.4),
        sombra=3.8, ropa=[(3.95, "cuero", -8, 1.0), (4.70, "cuero", -11, 0.9), (5.45, "ropa", -6, 0.8),
                          (6.05, "capa", -8, 0.85), (6.90, "cuero", -12, 0.8), (8.02, "capa", -13, 0.7)],
        garras=[4.40, 4.75, 5.05], dedos=[9.25, 9.38, 9.51, 9.64, 9.78],
        motivo=[(5.40, D3, 0.95), (6.10, AB2, 0.95), (6.80, G2, 2.3)], acorde_mascara=7.40,
        voces1=(4.5, 9.85), voces2=(11.6, 15.4),
        riser1=(0.0, 1.94), agarre=9.85, congelado=10.1, grietas_fin=11.6,
        vortice=(11.6, 15.4), sacudidas=[12.5, 13.8], muerto=15.0,
        presion=(15.4, 16.4), riser2=(0.0, 1.98), pausa=(16.4, 17.0), libera=17.0,
        restos=[(17.6, "restos19", 2.2, 5.0, -12), (18.0, "goteo24", 12.0, 14.5, -15)],
        rafaga=(18.95, 19.0), destello=19.7, fin_fade=0.05, golpe_s=0.09,
        cueva=(10.0, 30.5),
    ),
    "abreviada": dict(
        dur=6.8,
        latidos=[(0.06, -8, "d"), (0.55, -7, "d"), (1.95, -10, "s"), (2.25, -8, "s"), (4.99, -11, "s")],
        runas=[0.12, 0.22, 0.31, 0.39, 0.46, 0.52],
        zumbido=[(0.0, -45), (0.35, -27), (0.8, -23), (2.6, -13), (2.75, -9), (3.0, -11), (3.8, -19), (4.0, -22)],
        zumbido_fin=4.0, vibra=0.4,
        bordon=[(0.8, -60), (1.15, -21), (2.6, -14), (2.75, -13), (4.2, -15), (4.9, -13)],
        temblor=(0.45, 0.8, 1.3),
        sombra=0.80, ropa=[(0.82, "capa", -8, 0.85), (1.05, "ropa", -10, 0.8), (1.62, "capa", -13, 0.7)],
        garras=[], dedos=[2.25, 2.33, 2.41, 2.49, 2.56],
        motivo=[(0.80, D3, 0.40), (1.05, AB2, 0.40), (1.30, G2, 1.2)], acorde_mascara=1.45,
        voces1=(0.9, 2.6), voces2=(3.0, 4.2),
        riser1=(1.14, 1.94), agarre=2.60, congelado=2.75, grietas_fin=3.0,
        vortice=(3.0, 4.2), sacudidas=[3.6], muerto=4.0,
        presion=(4.2, 4.9), riser2=(1.28, 1.98), pausa=(4.9, 5.15), libera=5.15,
        restos=[(5.55, "restos19", 2.2, 3.4, -13)],
        rafaga=(6.22, 6.3), destello=6.65, fin_fade=0.04, golpe_s=0.06,
        cueva=(40.0, 47.0),
    ),
}


def tono_motivo(f0, dur, ganancia_db, brillo=1.0, semilla=1):
    """Una nota del motivo: metal grave oscuro (armónicos con filtro que se abre y se cierra) y suboctava."""
    n = int(dur * SR)
    t = tiempo(n)
    ataque, caida = 0.07, min(0.6, dur * 0.4)
    amp = np.clip(t / ataque, 0, 1) * np.clip((dur - t) / caida, 0, 1) ** 1.5
    corte = (260 + 900 * brillo * np.exp(-t / 0.5) + 250 * brillo) * np.ones(n)
    vib = 1 + 0.0025 * np.sin(2 * np.pi * 4.6 * t) * np.clip((t - 0.3) / 0.5, 0, 1)
    y = dsp.aditivo(f0 * vib, amp, corte, n_arm=40, voces=(-7.0, 0.0, 7.5), pendiente=1.0, semilla=semilla)
    sub = np.sin(dsp.fase(f0 * 0.5 * vib)) * amp * 0.5
    y += dsp.estereo(sub)
    return y * db(ganancia_db)


def acorde(dur, ganancia_db, notas=(D3, AB2, G2), brillo=1.0, semilla=5):
    y = 0
    for k, f in enumerate(notas):
        y = y + tono_motivo(f, dur, 0.0, brillo, semilla + k)
    return y * db(ganancia_db) / np.sqrt(len(notas))


def latido(tipo, semilla):
    """Latido grave: el «lub» (y el «dub») de Airborne filtrado y un golpe de tambor sintético muy filtrado."""
    # dos tomas distintas para no repetir: 6,55 s y 9,73 s del original
    t0 = 6.53 if semilla % 2 == 0 else 9.71
    largo = 0.62 if tipo == "d" else 0.30
    x = cargar(F["latido"], t0, t0 + largo, capa="latidos", uso="latido %s" % ("doble" if tipo == "d" else "simple"),
               version=VERSION)
    x = fft_filtro(x, pb(160, 2))
    sub = dsp.golpe_sub(0.35, f0=62, f1=40, tau=0.04, decay=0.11) * 0.55
    y = np.zeros((max(len(x), len(sub)), 2))
    y[:len(x)] += x
    i = dsp.pico_inicio(x)
    y[i:i + len(sub)] += sub[:len(y) - i]
    if tipo == "d":
        j = i + int(0.36 * SR)
        y[j:j + len(sub)] += 0.6 * sub[:max(0, len(y) - j)]
    return y


def componer(nombre):
    global VERSION
    VERSION = nombre
    v = V[nombre]
    N = int(round(v["dur"] * SR))
    T = tiempo(N)
    st = {k: np.zeros((N, 2)) for k in ("latidos", "zumbido_motivo", "efectos", "ambiente")}
    lat, zm, ef, am = st["latidos"], st["zumbido_motivo"], st["efectos"], st["ambiente"]
    rng = np.random.default_rng(2026 if nombre == "completa" else 68)

    # ---------- LATIDOS ----------
    for k, (t, g, tipo) in enumerate(v["latidos"]):
        colocar(lat, latido(tipo, k), t, g, alinear_inicio=True, fade_out=0.05)

    # ---------- ZUMBIDO DEL ORBE (síntesis) ----------
    zf = v["zumbido_fin"]
    t0z = v["zumbido"][0][0]
    n = int((zf + 0.45 - t0z) * SR)
    tz = t0z + tiempo(n)
    amp = env(tz, v["zumbido"] + [(zf, v["zumbido"][-1][1]), (zf + 0.4, -100)])
    # el orbe vibra: trémolo que se acelera; tras el agarre el tono sube medio tono y luego se apaga hacia abajo
    ag, cg = v["agarre"], v["congelado"]
    semis = np.interp(tz, [t0z, ag, cg, cg + min(1.5, (zf - cg) / 2), zf], [0, 0.3, 1.0, 0.8, -0.5])
    caida = np.where(tz > zf, -12 * np.clip((tz - zf) / 0.4, 0, 1) ** 1.5, 0)
    f0 = D3 * 2 ** ((semis + caida) / 12)
    vib_rate = np.interp(tz, [t0z, v["vibra"], ag, zf], [4.0, 7.0, 12.0, 6.0])
    prof = np.interp(tz, [t0z, v["vibra"], ag, zf], [0.15, 0.45, 0.6, 0.3])
    trem = 1 - prof * (0.5 + 0.5 * np.sin(dsp.fase(vib_rate)))
    corte = np.interp(tz, [t0z, ag, cg, zf], [500, 1300, 3200, 700])
    hum = dsp.aditivo(f0, amp * trem, corte, n_arm=24, voces=(-9.0, 0.0, 10.0), pendiente=1.3, semilla=21)
    hum += 0.35 * dsp.aditivo(f0 * 2, amp * trem, corte * 1.5, n_arm=10, voces=(-4.0, 5.0), pendiente=1.5, semilla=22)
    hum += 0.12 * dsp.aditivo(f0 * 4.0, amp * (1 - 0.5 * trem), corte * 2, n_arm=4, voces=(0.0,), pendiente=2, semilla=23)
    colocar(zm, hum, t0z, 0.0, fade_in=0.05, fade_out=0.05)

    # ---------- BORDÓN (re grave) ----------
    b0 = v["bordon"][0][0]
    b1 = v["pausa"][0]
    n = int((b1 + 0.03 - b0) * SR)
    tb = b0 + tiempo(n)
    amp = env(tb, v["bordon"] + [(b1, v["bordon"][-1][1]), (b1 + 0.025, -100)])
    corte = np.interp(tb, [b0, ag, cg, v["vortice"][0], v["presion"][0], b1], [260, 700, 1300, 600, 500, 1400])
    bor = dsp.aditivo(D2 * (1 + 0.002 * np.sin(2 * np.pi * 0.13 * tb)), amp, corte, n_arm=40,
                      voces=(-5.0, 0.0, 6.0), pendiente=1.0, semilla=31)
    bor += dsp.estereo(0.5 * np.sin(dsp.fase(np.full(n, D1))) * amp)
    colocar(zm, bor, b0, 0.0, fade_in=0.05, fade_out=0.02)

    # ---------- MOTIVO: re - la bemol - sol, y el acorde en la máscara ----------
    for k, (t, f, d) in enumerate(v["motivo"]):
        colocar(zm, tono_motivo(f, d, -9.0 if nombre == "completa" else -11.0, brillo=0.8, semilla=40 + k), t, 0.0, fade_out=0.05)
    am_t = v["acorde_mascara"]
    durac = 2.0 if nombre == "completa" else 0.9
    colocar(zm, acorde(durac, -11.0 if nombre == "completa" else -13.0, brillo=1.1), am_t, 0.0, fade_out=0.08)
    colocar(ef, dsp.destello_metal(1.6, 1480.0, semilla=11), am_t, -14.0)
    colocar(ef, dsp.campana(CAMPANAS[0] * 2, 1.4, semilla=12, brillo=0.6), am_t + 0.01, -22.0)

    # ---------- RUNAS (campanillas sintetizadas, notas del motivo en agudo) ----------
    for k, t in enumerate(v["runas"]):
        f = CAMPANAS[k % len(CAMPANAS)]
        pan = 0.7 * np.sin(2 * np.pi * k / len(v["runas"]))
        colocar(ef, dsp.campana(f, 2.0, semilla=60 + k), t, -17 + 0.6 * k, pan=pan)

    # ---------- TEMBLOR ----------
    ta, tb_, tc = v["temblor"]
    tr = cargar(F["temblor"], 0.60, 0.60 + (tc - ta) + 0.3, capa="efectos", uso="temblor del orbe", version=nombre)
    tr = fft_filtro(tr, pb(2500, 2))
    tr *= env(tiempo(len(tr)) + ta, [(ta, -40), (tb_, 0), (tc, -10), (tc + 0.3, -100)])[:, None]
    colocar(ef, tr, ta, +3.0)
    n = int((tc + 0.3 - ta) * SR)
    rr = dsp.ruido(n, 77)
    rr = fft_filtro(rr, banda(30, 110, 2))
    tt = ta + tiempo(n)
    rr *= (env(tt, [(ta, -60), (tb_, -12), (tc, -24), (tc + 0.3, -100)]) * (1 - 0.6 * (0.5 + 0.5 * np.sin(2 * np.pi * 11 * tt))))[:, None]
    colocar(ef, rr, ta, -9.0)

    # ---------- LA SOMBRA SE MUEVE: ráfaga grave, humo que gira ----------
    s = v["sombra"]
    w = dsp.soplido(1.8, lambda t: 70 * 2 ** (2.0 * np.sin(np.pi * np.clip(t / 1.8, 0, 1))), 1.4,
                    lambda t: env(t, [(0, -40), (0.45, 0), (1.8, -40)]), 101, pan=lambda t: -0.4 + 0.5 * t)
    colocar(ef, w, s - 0.1, -8.0)
    va_, vb_ = (0.50, 4.50) if nombre == "completa" else (1.00, 2.40)
    vo = cargar(F["vocal"], va_, vb_, capa="efectos", uso="rafaga grave de la sombra", version=nombre)
    vo = fft_filtro(remuestrear(vo, 0.72), pb(1800, 2))
    colocar(ef, vo, s - 0.35, -12.0, fade_out=0.6)
    if nombre == "completa":
        rm = cargar(F["remolino"], 10.0, 14.6, capa="efectos", uso="humo que gira tras el orbe", version=nombre)
        rm = fft_filtro(rm, pb(1400, 2)) * env(tiempo(len(rm)), [(0, -40), (0.5, 0), (1.6, -3), (4.2, -14), (4.6, -100)])[:, None]
        colocar(ef, rm, s, -8.0)

    # ---------- TELA, CUERO Y CRUJIDOS ----------
    for t, clave, g, fac in v["ropa"]:
        rel = {"cuero": (F["cuero"], 0.0, 0.93), "ropa": (F["ropa"], 0.0, 0.61), "capa": (F["capa"], 0.0, 1.26)}[clave]
        x = cargar(rel[0], rel[1], rel[2], capa="efectos", uso="tela/cuero de Erebo", version=nombre)
        x = remuestrear(x, fac * (1 + rng.uniform(-0.03, 0.03)))
        colocar(ef, fft_filtro(x, pb(7000, 1)), t, g + 4.0, alinear_inicio=True, pan=rng.uniform(-0.3, 0.3))
    tramos_crujido = [(0.45, 0.80), (3.75, 4.05), (6.15, 6.45), (8.20, 8.50), (10.90, 11.20)]
    for k, t in enumerate(v["garras"]):
        a_, b_ = tramos_crujido[k % len(tramos_crujido)]
        x = remuestrear(cargar(F["crujido"], a_, b_, capa="efectos", uso="crujido de garras", version=nombre), 0.6)
        colocar(ef, fft_filtro(x, banda(150, 5000)), t, -7.0, alinear_inicio=True, pan=0.25)
    for k, t in enumerate(v["dedos"]):
        a_, b_ = tramos_crujido[(k + 1) % len(tramos_crujido)]
        x = remuestrear(cargar(F["crujido"], a_, b_, capa="efectos", uso="dedo que se cierra", version=nombre), 0.5)
        colocar(ef, fft_filtro(x, banda(120, 3500)), t, -14.0 + 1.5 * k, alinear_inicio=True, pan=0.15)

    # ---------- VOCES DIFUSAS (al revés, filtradas: ininteligibles) ----------
    for (va, vb), (oa, ob), semi in ((v["voces1"], (20.0, 26.0), 0), (v["voces2"], (40.0, 46.0), 1)):
        x = cargar(F["voces"], oa, ob, capa="efectos", uso="coro difuso (al reves, filtrado)", version=nombre)[::-1]
        x = fft_filtro(remuestrear(x, 0.82), banda(220, 2200, 2))
        largo = vb - va
        x = x[:int(largo * SR)]
        x *= env(tiempo(len(x)), [(0, -40), (largo * 0.35, 0), (largo * 0.9, -3), (largo, -40)])[:, None]
        if semi:
            x = paneo(x, 0.6 * np.sin(2 * np.pi * 0.7 * tiempo(len(x))))
        colocar(ef, x, va, -18.0, fade_in=0.2, fade_out=0.1)

    # ---------- TENSIÓN ANTES DEL AGARRE ----------
    ra, rb = v["riser1"]
    x = cargar(F["riser078"], ra, rb, capa="efectos", uso="tension antes del agarre", version=nombre)
    colocar(ef, fft_filtro(x, pb(6000, 1)), ag - (rb - ra), -4.0 if nombre == "completa" else -8.0, fade_in=0.05, fade_out=0.003)

    # ---------- AGARRE: golpe grave con cristal, congelado y continuación ----------
    golpe = np.zeros((int(5.0 * SR), 2))
    colocar(golpe, cargar(F["boom091"], 0.0, 4.0, capa="efectos", uso="golpe del agarre", version=nombre), 0.0, 0.0, alinear_inicio=True)
    colocar(golpe, dsp.golpe_sub(2.0, 64, 30, 0.08, 0.7), 0.0, -4.0)
    colocar(golpe, cargar(F["grieta"], 0.0, 1.10, capa="efectos", uso="crujido de cristal del agarre", version=nombre), 0.0, -4.0, alinear_inicio=True, pan=0.15)
    colocar(golpe, remuestrear(cargar(F["iceberg"], 1.84, 4.60, capa="efectos", uso="el orbe se agrieta", version=nombre), 0.85), 0.0, -7.0, alinear_inicio=True, pan=-0.2)
    colocar(golpe, remuestrear(cargar(F["bloque"], 0.55, 2.50, capa="efectos", uso="grieta grave", version=nombre), 0.8), 0.012, -8.0, alinear_inicio=True)
    corte = int(v["golpe_s"] * SR)
    pre = golpe[:corte + int(0.015 * SR)].copy()
    pre[corte:] *= np.linspace(1, 0, len(pre) - corte)[:, None]
    post = golpe[corte:].copy()
    colocar(ef, pre, ag, 0.0, fade_in=0.0005, fade_out=0.001)
    colocar(ef, post, cg, -3.0, fade_in=0.008)

    # ---------- AL REANUDAR: runas de golpe, grietas, siseo eléctrico ----------
    for k in range(7):
        colocar(ef, dsp.campana(CAMPANAS[k] * (1 if k % 2 else 2), 1.8, semilla=80 + k, brillo=1.2),
                cg + 0.004 * k, -17.0, pan=0.8 * np.sin(2 * np.pi * k / 7))
    gf = v["grietas_fin"]
    largo = gf - cg + 0.6
    cr = cargar(F["crujido"], 7.85, 7.85 + largo / 0.8 + 0.1, capa="efectos", uso="chisporroteo de grietas", version=nombre)
    cr = remuestrear(cr, 0.8)[:int(largo * SR)]
    cr *= env(tiempo(len(cr)), [(0, 0), (largo - 0.6, 0), (largo, -40)])[:, None]
    colocar(ef, fft_filtro(cr, pa(300)), cg, -9.0, fade_in=0.01)
    ar = cargar(F["arco"], 0.0, min(3.6, largo + 0.8), capa="efectos", uso="arco electrico en las grietas", version=nombre)
    ar *= env(tiempo(len(ar)), [(0, -6), (largo - 0.4, 0), (len(ar) / SR, -40)])[:, None]
    colocar(ef, ar, cg, -8.0, fade_in=0.01)
    if nombre == "completa":
        cgx = cargar(F["carga"], 0.0, 2.60, capa="efectos", uso="siseo electrico que sube", version=nombre)
        colocar(ef, cgx, cg + 0.05, -6.0)
    else:
        cgx = cargar(F["carga"], 0.75, 1.75, capa="efectos", uso="siseo electrico que sube", version=nombre)
        colocar(ef, cgx, cg, -6.0, fade_in=0.01)
    n = int((gf - cg + 0.15) * SR)
    hs = dsp.soplido(n / SR, lambda t: 2000 * 2 ** (1.8 * t / (n / SR)), 1.2,
                     lambda t: env(t, [(0, -40), (n / SR - 0.15, 0), (n / SR, -60)]), 121)
    colocar(ef, hs, cg, -16.0)

    # ---------- ABSORCIÓN: vórtice al revés, sombras, sacudidas ----------
    va, vb = v["vortice"]
    largo = vb - va
    rm = cargar(F["remolino"], 30.0, 30.0 + largo * 0.8 + 0.2, capa="efectos", uso="vortice de viento al reves", version=nombre)[::-1]
    rm = remuestrear(rm, 0.8)[:int(largo * SR)]
    rm = fft_filtro(rm, pb(2500, 2))
    tl = tiempo(len(rm))
    rm *= env(tl, [(0, -30), (largo * 0.25, -2), (largo * 0.7, 0), (largo * 0.92, -6), (largo, -40)])[:, None]
    rm = paneo(rm, 0.5 * np.sin(2 * np.pi * np.cumsum(np.interp(tl, [0, largo], [0.4, 1.4])) / SR))
    colocar(ef, rm, va, -5.0, fade_in=0.1)
    mz = cargar(F["mazmorra"], 20.0, 20.0 + largo + 0.3, capa="efectos", uso="subgrave de las sombras", version=nombre)
    mz = fft_filtro(mz, pb(220, 2)) * env(tiempo(len(mz)), [(0, -40), (0.8, 0), (largo, 0), (largo + 0.3, -60)])[:, None]
    colocar(ef, mz, va, +2.0, fade_in=0.1)
    booms = [F["boom036"], F["boom040"]]
    for k, t in enumerate(v["sacudidas"]):
        x = cargar(booms[k % 2], 0.0, 3.0, capa="efectos", uso="sacudida de Erebo", version=nombre)
        colocar(ef, x, t, -9.0, alinear_inicio=True)
        x = remuestrear(cargar(F["capa"], 0.0, 1.26, capa="efectos", uso="la capa se abre", version=nombre), 0.75)
        colocar(ef, x, t - 0.08, -10.0, pan=0.3 * (-1) ** k)
        sw = dsp.soplido(0.7, lambda tt: 300 * 2 ** (-1.5 * tt), 1.5, lambda tt: env(tt, [(0, -50), (0.68, 0), (0.7, -60)]), 130 + k)
        colocar(ef, sw, t - 0.68, -12.0)
    # el orbe queda muerto: cristal oscuro
    x = remuestrear(cargar(F["bloque"], 1.00, 2.60, capa="efectos", uso="el orbe queda muerto", version=nombre), 0.6)
    colocar(ef, fft_filtro(x, pb(1800, 2)), v["muerto"], -9.0, alinear_inicio=True)

    # ---------- PRESIÓN (clímax): gruñido que sube y corte seco ----------
    pa_, pb_ = v["presion"]
    n = int((pb_ - pa_) * SR)
    tp = tiempo(n)
    u = tp / (n / SR)
    f0 = AB1 * 2 ** ((5.0 * u ** 1.5) / 12)
    amp = env(tp, [(0, -30), (n / SR * 0.8, -8), (n / SR, -4)])
    gr = dsp.aditivo(f0, amp, 200 + 2200 * u ** 2, n_arm=60, voces=(-15.0, 0.0, 14.0), pendiente=0.9, semilla=141)
    gr *= (1 - 0.35 * (0.5 + 0.5 * np.sin(2 * np.pi * (24 + 14 * u) * tp)))[:, None]
    gr = np.tanh(2.2 * gr) / 2.2 * 1.3
    colocar(zm, gr, pa_, 0.0, fade_in=0.05, fade_out=0.006)
    ra, rb = v["riser2"]
    x = cargar(F["riser088"], ra, rb, capa="efectos", uso="presion antes de liberar", version=nombre)
    colocar(ef, x, pb_ - (rb - ra), -7.0, fade_in=0.05, fade_out=0.006)

    # ---------- PAUSA: casi muda; inspiración al revés justo antes ----------
    li = v["libera"]
    x = cargar(F["boom005"], 0.15, 0.85, capa="efectos", uso="aspiracion previa a liberar (al reves)", version=nombre)[::-1]
    x = x[-int(0.13 * SR):] * np.linspace(0, 1, int(0.13 * SR))[:, None] ** 2
    colocar(ef, x, li - 0.13, -12.0, fade_in=0.005, fade_out=0.001)

    # ---------- LIBERACIÓN ----------
    colocar(ef, cargar(F["boom005"], 0.0, 4.0, capa="efectos", uso="estallido", version=nombre), li, 0.0, alinear_inicio=True)
    colocar(ef, cargar(F["smash"], 0.0, 5.75, capa="efectos", uso="estallido (impacto)", version=nombre), li, -4.0, alinear_inicio=True)
    colocar(ef, dsp.golpe_sub(2.6, 72, 28, 0.12, 0.9), li, -3.0)
    br = cargar(F["braam"], 0.0, 9.0, capa="zumbido_motivo", uso="acorde de re de la liberacion", version=nombre)
    resto = v["dur"] - li
    br *= env(tiempo(len(br)), [(0, 0), (min(1.2, resto * 0.4), -3), (resto, -16), (9.0, -40)])[:, None]
    colocar(zm, br, li, -7.0, alinear_inicio=True)
    colocar(zm, acorde(min(3.2, resto + 0.2), -9.0, notas=(D2, AB2, G2, D3), brillo=1.6, semilla=150), li, 0.0)
    colocar(ef, cargar(F["astillas"], 0.0, 0.92, capa="efectos", uso="fragmentos de cristal", version=nombre), li + 0.015, -5.0, alinear_inicio=True, pan=0.35)
    colocar(ef, cargar(F["cristal23"], 0.0, 1.38, capa="efectos", uso="fragmentos que caen", version=nombre), li + 0.05, -7.0, alinear_inicio=True, pan=-0.45)
    colocar(ef, cargar(F["iceberg"], 2.50, 6.00, capa="efectos", uso="cristal que estalla", version=nombre), li + 0.008, -8.0, alinear_inicio=True, pan=-0.15)
    colocar(ef, cargar(F["impacto012"], 1.30, 2.98, capa="efectos", uso="onda", version=nombre), li, -7.0, alinear_inicio=True)
    on = dsp.soplido(1.4, lambda t: 160 * 2 ** (-1.4 * t), 1.6, lambda t: env(t, [(0, 0), (0.15, -2), (1.4, -50)]), 160,
                     pan=lambda t: 0.0 * t)
    colocar(ef, on, li, -6.0, fade_in=0.002)
    for t, clave, a_, b_, g in v["restos"]:
        x = cargar(F[clave], a_, b_, capa="efectos", uso="cola de restos", version=nombre)
        colocar(ef, x, t, g, pan=rng.uniform(-0.5, 0.5), fade_out=0.2)

    # ---------- RÁFAGA QUE SE ALEJA y destello final ----------
    r0, r1 = v["rafaga"]
    fin = v["dur"]
    x = cargar(F["doppler"], 0.0, 4.0, capa="efectos", uso="rafaga que se aleja", version=nombre)
    colocar(ef, x, r0, -4.0, alinear_inicio=True, fade_out=0.001)
    n = int((fin - r1) * SR) + 10
    largo = n / SR
    hz = dsp.soplido(largo, lambda t: 420 * 2 ** (-1.8 * t / largo), 1.6,
                     lambda t: env(t, [(0, -30), (largo * 0.3, -2), (largo, -12)]), 170,
                     pan=lambda t: 0.3 - 0.3 * t / largo)
    colocar(ef, hz, r1, -8.0, fade_in=0.02, fade_out=0.001)
    de = v["destello"]
    sh = 0
    for k in range(4):
        sh = sh + dsp.campana(CAMPANAS[k] * 2, 0.6, semilla=180 + k, brillo=1.4)
    sh = sh[::-1][-int(0.35 * SR):]
    colocar(ef, sh, de - 0.35, -20.0, fade_in=0.05, fade_out=0.001)
    colocar(ef, dsp.destello_metal(0.9, 1975.0, semilla=190), de, -18.0, fade_out=0.001)

    # ---------- AMBIENTE: cueva húmeda (goteo, viento interior) ----------
    ca, cb = v["cueva"]
    x = cargar(F["cueva"], ca, ca + v["dur"], capa="ambiente", uso="cueva: obsidiana mojada", version=nombre)
    x = fft_filtro(x, pa(45, 2))
    colocar(am, x[:N], 0.0, +7.0, fade_in=0.6 if nombre == "completa" else 0.15, fade_out=0.001)

    # ---------- reverberación por capa ----------
    ir = dsp.ir_sala(2.8, 0.03, 7, 3000)
    st["zumbido_motivo"] = dsp.reverb(zm, ir, -6.0)
    st["efectos"] = dsp.reverb(ef, dsp.ir_sala(2.2, 0.02, 9, 4000), -11.0)
    st["latidos"] = dsp.reverb(lat, dsp.ir_sala(1.6, 0.015, 13, 2500), -14.0)

    # ---------- congelado del agarre y pausa casi muda (después de la reverberación) ----------
    gl = v["golpe_s"] + 0.015
    gcong = env(T, [(0, 0), (ag + gl, 0), (ag + gl + 0.001, -100), (cg - 0.001, -100), (cg, 0), (v["dur"], 0)])
    p0, p1 = v["pausa"]
    gpausa = env(T, [(0, 0), (p0, 0), (p0 + 0.03, -100), (p1 - 0.135, -100), (p1 - 0.134, 0), (v["dur"], 0)])
    gamb = env(T, [(0, 0), (p0, 0), (p0 + 0.05, -14), (p1, -14), (p1 + 0.4, -4), (v["dur"], -4)])
    # «silencio antes del golpe»: 30 ms hundidos justo antes del agarre (el golpe empieza en ag y no se toca)
    gdip = env(T, [(0, 0), (ag - 0.07, 0), (ag - 0.03, -9), (ag - 0.0005, -9), (ag, 0), (v["dur"], 0)])
    st["zumbido_motivo"] *= (gcong * gpausa * gdip)[:, None]
    st["efectos"] *= (gcong * gpausa * gdip)[:, None]
    st["latidos"] *= (gcong * gdip)[:, None]
    st["ambiente"] = am * (gcong * gamb)[:, None]
    return st, N, (gcong, gpausa)


def medir_tramos(x, tramos):
    out = []
    for et, a, b in tramos:
        seg = x[int(a * SR):int(b * SR)]
        out.append((et, a, b, 20 * np.log10(np.abs(seg).max() + 1e-12), dsp.rms_db(seg)))
    return out


resultados = {}
for nombre in ("completa", "abreviada"):
    st, N, (gcong, gpausa) = componer(nombre)
    hpf = pa(28, 2)
    for k in st:
        # el filtro de fase cero «ensucia» los silencios: se vuelven a aplicar las puertas
        st[k] = fft_filtro(st[k], hpf) * gcong[:, None]
        if k in ("zumbido_motivo", "efectos"):
            st[k] *= gpausa[:, None]
    mezcla = sum(st.values())
    # ganancia maestra hacia -16 LUFS con el limitador a -1,3 dBFS (iterativo)
    g = 0.0
    for it in range(6):
        y, gr = dsp.limitador(mezcla * db(g), -1.3)
        integ, stmax = dsp.lufs(y)
        g += (-16.0 - integ)
        if abs(-16.0 - integ) < 0.15:
            break
    y, gr = dsp.limitador(mezcla * db(g), -1.3)
    # fundido final corto (sin clic) y de entrada
    fo = int(V[nombre]["fin_fade"] * SR)
    w = np.ones(N)
    w[-fo:] = np.cos(np.linspace(0, np.pi / 2, fo)) ** 2
    w[:int(0.004 * SR)] = np.linspace(0, 1, int(0.004 * SR))
    y *= w[:, None]
    integ, stmax = dsp.lufs(y)
    tp = dsp.pico_real(y)
    wavio.escribir(os.path.join(SALIDA, "erebo_cine_%s.wav" % nombre), y)
    for k in st:
        sk = st[k] * db(g) * w[:, None]
        wavio.escribir(os.path.join(SALIDA, "stems", "%s_%s.wav" % (nombre, k)), sk)
    v = V[nombre]
    ag, cg, li = v["agarre"], v["congelado"], v["libera"]
    p0, p1 = v["pausa"]
    tramos = [("antes del agarre", ag - 0.30, ag), ("golpe del agarre", ag, ag + 0.09),
              ("congelado (silencio)", ag + 0.12, cg - 0.005), ("reanuda", cg, cg + 0.4),
              ("pausa (casi muda)", p0 + 0.05, p1 - 0.14), ("liberacion", li, li + 0.5),
              ("ultimos 200 ms", v["dur"] - 0.25, v["dur"] - 0.05)]
    # ataques medidos: primera muestra que supera -20 dB del pico local, buscada 150 ms alrededor
    ataques = {}
    graves = fft_filtro(y, pb(200, 4))
    for et, t in (("agarre", ag), ("reanuda", cg), ("latido_pausa", 16.70 if nombre == "completa" else 4.99), ("liberacion", li)):
        a = int((t - 0.08) * SR)
        b = int((t + 0.08) * SR)
        win = int(0.0005 * SR)
        segm = np.abs(graves[a:b]).max(axis=1)
        e = 20 * np.log10(np.array([segm[i:i + win].max() for i in range(0, len(segm) - win, win)]) + 1e-9)
        pk = e.max()
        idx = int(np.argmax(e >= pk - 12))
        ataques[et] = dict(inicio_s=round((a + idx * win) / SR, 4), pico_s=round((a + int(np.argmax(e)) * win) / SR, 4),
                           nivel_previo_db=round(float(e[:max(1, idx - 2)].max() - pk), 1))
    grid = []
    for k0 in np.arange(0, v["dur"], 0.5):
        fila = [round(float(k0), 1), round(dsp.rms_db(y[int(k0 * SR):int((k0 + 0.5) * SR)]), 1)]
        for k in ("latidos", "zumbido_motivo", "efectos", "ambiente"):
            fila.append(round(dsp.rms_db(st[k][int(k0 * SR):int((k0 + 0.5) * SR)] * db(g)), 1))
        grid.append(fila)
    resultados[nombre] = dict(
        muestras=len(y), duracion=len(y) / SR, ganancia_maestra_db=round(g, 2), reduccion_limitador_db=round(gr, 2),
        lufs_integrado=round(integ, 2), lufs_corto_max=round(stmax, 2), pico_muestra_dbfs=round(20 * np.log10(np.abs(y).max()), 2),
        pico_real_dbfs=round(tp, 2), rms_dbfs=round(dsp.rms_db(y), 2),
        ultima_muestra=[int(round(y[-1, 0] * 32767)), int(round(y[-1, 1] * 32767))],
        tramos=[(et, a, b, round(p, 1), round(r, 1)) for et, a, b, p, r in medir_tramos(y, tramos)],
        ataques=ataques, rejilla_rms=grid,
        stems={k: dict(pico=round(20 * np.log10(np.abs(st[k] * db(g)).max() + 1e-12), 1), rms=round(dsp.rms_db(st[k] * db(g)), 1))
               for k in st},
    )
    print("HECHO", nombre, json.dumps(resultados[nombre], ensure_ascii=False))

with open(os.path.join(SALIDA, "medidas.json"), "w", encoding="utf-8") as f:
    json.dump(resultados, f, ensure_ascii=False, indent=1)

# procedencia: una fila por fuente y tramo distintos
vistos = set()
with open(os.path.join(SALIDA, "procedencia.csv"), "w", newline="", encoding="utf-8") as f:
    wcsv = csv.writer(f, delimiter=";")
    wcsv.writerow(["version", "capa", "uso", "ruta_en_D:/qtorrent/sound effect", "desde_s", "hasta_s", "sha256_fuente",
                   "frecuencia_fuente", "canales_fuente", "licencia", "evidencia_licencia"])
    for p in dsp.PROCEDENCIA:
        clave = (p["version"], p["ruta"], round(p["desde"], 3), round(p["hasta"], 3), p["uso"])
        if clave in vistos:
            continue
        vistos.add(clave)
        paquete = p["ruta"].split("/")[0]
        lic = "Sonniss GDC Game Audio Bundle (%s)" % paquete.replace("Sonniss.com - ", "").replace(" - Game Audio Bundle", "").replace("- Game Audio Bundle", "")
        wcsv.writerow([p["version"], p["capa"], p["uso"], p["ruta"], "%.3f" % p["desde"], "%.3f" % p["hasta"], p["sha256"],
                       p["sr"], p["canales"], lic, dsp.LIC_SONNISS])
print("PROCEDENCIA", len(vistos))
