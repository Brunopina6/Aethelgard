# Héroes v3 (V12): diseño de LYA, modelado por guion sobre su esqueleto (el común de los v2, en reposo en T).
#
# Lo que se conserva para reconocerla (dirección: docs/v12/DIRECCION_HEROES_V3.md):
#   melena rubia muy larga y ondulada con flequillo suelto; flores blancas con lazo a los lados de la cabeza; ojos
#   azul cielo grandes y dulces; vestido blanco de hombros descubiertos con degradado azul hielo, falda corta delante y
#   larga detrás (cola); mangas sueltas acampanadas; cinturón dorado con gema azul; colgante; zapatos blancos con
#   cristales. El cetro lo pone el juego (hueso arma_d).
# Su esqueleto trae huesos propios que aquí se usan: Bone_018 y Bone_017 (melena de atrás), Bone_008 → Bone_005 (la
# cola de la falda) y Bone_040 / Bone_041 (la punta de las mangas, más allá de la mano).
import math, random
from mathutils import Vector, Quaternion
import geometria_v3 as G
import kael_v3 as K          # mano, tubo con ángulos por anillo y casquete (no dependen del héroe)

P = G.P


def _vestido(co):
    # blanco arriba que pasa a azul hielo hacia el bajo
    t = G.suave(0.95, 0.25, co.z)
    return G.mezcla((0.95, 0.95, 0.97), (0.64, 0.80, 0.95), t)


def _manga(co):
    t = G.suave(0.30, 0.68, abs(co.x))
    return G.mezcla((0.95, 0.95, 0.97), (0.66, 0.82, 0.96), t)


def _piel(co):
    base = (0.99, 0.92, 0.89)
    for sx in (-1, 1):
        d = Vector((co.x - (CRANEO["c"].x + sx * 0.086), (co.y - CRANEO["c"].y + 0.14) * 0.7, co.z - 1.455)).length
        k = max(0.0, 1.0 - d / 0.040) ** 1.5 * 0.6
        if k > 0:
            base = G.mezcla(base, (0.99, 0.70, 0.70), k)
    return base


def _pelo(co):
    # rubio miel con las puntas más claras
    t = G.suave(1.50, 0.80, co.z)
    return G.mezcla((0.97, 0.88, 0.62), (1.0, 0.95, 0.80), t)


PALETA = {
    "piel": {"color": _piel, "tipo": "piel"},
    "guante": {"color": _piel, "tipo": "piel"},          # sin guantes (la mano de K.mano usa este nombre)
    "pelo": {"color": _pelo, "tipo": "pelo"},
    "vestido": {"color": _vestido, "tipo": "tela"},
    "forro": {"color": (0.74, 0.86, 0.97), "tipo": "tela"},
    "manga": {"color": _manga, "tipo": "tela"},
    "azul": {"color": (0.45, 0.65, 0.90), "tipo": "tela"},
    "azul_hielo": {"color": (0.66, 0.82, 0.96), "tipo": "tela"},
    "oro": {"color": (0.90, 0.80, 0.56), "tipo": "metal"},
    "blanco": {"color": (0.96, 0.96, 0.97), "tipo": "tela"},
    "zapato": {"color": (0.95, 0.95, 0.97), "tipo": "cuero"},
    "cristal": {"color": (0.36, 0.78, 0.98), "tipo": "cristal"},
    "flor": {"color": (0.98, 0.98, 0.96), "tipo": "tela"},
    "flor_centro": {"color": (0.98, 0.86, 0.45), "tipo": "tela"},
}

ESCALA_CABEZA = 1.12     # influencia chibi (crear_heroes_v3.py)
CRANEO = {"c": Vector((0.006, -0.050, 1.535)), "rx": 0.160, "ry": 0.150, "rz": 0.158}

CARA = {
    "ojo": {"x": 0.062, "z": 1.492, "ancho": 0.112, "alto": 0.112},
    "boca": {"x": 0.0, "z": 1.410, "ancho": 0.046, "alto": 0.040},
    "ceja": {"z": 1.553, "largo": 0.044, "grueso": 0.0075, "inclinacion": -4.0},
    "marca": None,
    "iris": ((0.12, 0.38, 0.82), (0.50, 0.86, 1.0)),
    "linea": (0.30, 0.18, 0.14),
    "ceja_color": (0.80, 0.64, 0.40),
    "mirada": "dulce",
    "centro_x": 0.006,
}


def _cabeza_deformar(u):
    x, y, z = u.x, u.y, u.z
    if z < 0:
        k = G.suave(0.0, -1.0, z)
        x *= 1.0 - 0.38 * k
        y *= 1.0 - 0.22 * k
        if y < 0:
            y -= 0.08 * k * (1.0 - abs(x) * 1.6)
        z *= 0.92
    if y < 0:
        x *= 1.0 - 0.06 * min(1.0, -y * 1.6)
    if y < -0.60:
        y = -0.60 + (y + 0.60) * 0.72
    return Vector((x, y, z))


def construir(H):
    piezas = []
    C = CRANEO["c"]
    cab = G.Pieza("lya_cabeza", ["piel"], [("Head", 1.0)])
    G.esfera(cab, C, CRANEO["rx"], CRANEO["ry"], CRANEO["rz"], segs=28, anillos=18, deformar=_cabeza_deformar)
    for sx in (-1, 1):
        G.esfera(cab, C + Vector((sx * 0.150, 0.012, -0.045)), 0.014, 0.011, 0.022, segs=8, anillos=6)
    piezas.append(cab)

    n0, n1 = H.c("Neck"), H.c("Head")
    cuello = G.Pieza("lya_cuello", ["piel"], [("Neck", 1.0), ("Head", 0.6), ("Spine2", 0.5)], p=3)
    G.tubo(cuello, [(n0 + Vector((0, 0, -0.03)), G.ADEL, 0.034, 0.038), (n0.lerp(n1, 0.6), G.ADEL, 0.028, 0.031),
                    (n1 + Vector((0, 0.004, 0.05)), G.ADEL, 0.030, 0.033)], segs=10)
    piezas.append(cuello)

    # ------------------------------------------------------------ torso: piel arriba (hombros descubiertos), cuerpo
    hip, sp, sp1, sp2, nk = H.c("Hips"), H.c("Spine"), H.c("Spine1"), H.c("Spine2"), H.c("Neck")
    tor = G.Pieza("lya_torso", ["piel"],
                  [("Hips", 1.0), ("Spine", 1.0), ("Spine1", 1.0), ("Spine2", 1.0), ("Neck", 0.3),
                   ("LeftShoulder", 0.6), ("RightShoulder", 0.6)], p=3)
    an = [(Vector((hip.x, hip.y, 0.97)), G.ADEL, 0.070, 0.098),
          (Vector((hip.x, hip.y, 1.06)), G.ADEL, 0.068, 0.092),
          (Vector((sp.x, sp.y, 1.14)), G.ADEL, 0.058, 0.076),
          (Vector((sp1.x, sp1.y, 1.22)), G.ADEL, 0.066, 0.086),
          (Vector((sp1.x, sp1.y, 1.27)), G.ADEL, 0.064, 0.098),
          (Vector((sp2.x, sp2.y, 1.31)), G.ADEL, 0.056, 0.104),
          (Vector((nk.x, nk.y, 1.345)), G.ADEL, 0.040, 0.060)]
    G.tubo(tor, an, segs=14, tapa0=True, tapa1=True, abombar=0.2)
    piezas.append(tor)
    # corpiño (blanco) con escote recto y ribete dorado arriba; cinturón dorado con gema
    cor = G.Pieza("lya_corpino", ["vestido", "oro", "cristal", "azul"],
                  [("Hips", 1.0), ("Spine", 1.0), ("Spine1", 1.0), ("Spine2", 0.8)], p=3)
    an = [(Vector((hip.x, hip.y, 0.99)), G.ADEL, 0.076, 0.104),
          (Vector((hip.x, hip.y, 1.06)), G.ADEL, 0.074, 0.098),
          (Vector((sp.x, sp.y, 1.14)), G.ADEL, 0.065, 0.083),
          (Vector((sp1.x, sp1.y, 1.22)), G.ADEL, 0.074, 0.093),
          (Vector((sp1.x, sp1.y, 1.262)), G.ADEL, 0.073, 0.104),
          (Vector((sp1.x, sp1.y, 1.272)), G.ADEL, 0.072, 0.104)]
    G.tubo(cor, an, segs=16, mat=lambda i, j: 1 if i == 4 else (3 if i == 1 else 0))
    G.tubo(cor, [(Vector((hip.x, hip.y, 1.045)), G.ADEL, 0.078, 0.101), (Vector((hip.x, hip.y, 1.07)), G.ADEL, 0.077, 0.099)],
           segs=16, mat=lambda i, j: 1)
    G.gema(cor, Vector((hip.x, hip.y - 0.080, 1.058)), G.ARR, G.ADEL, 0.012, 0.036, mat=2)
    G.gema(cor, Vector((hip.x, hip.y - 0.082, 1.005)), G.ARR, G.ADEL, 0.006, 0.030, mat=2)
    # colgante
    G.gema(cor, Vector((sp2.x, sp2.y - 0.072, 1.255)), G.ARR, G.ADEL, 0.006, 0.020, mat=2)
    for sx in (-1, 1):
        G.tubo(cor, [(Vector((sp2.x, sp2.y - 0.070, 1.268)), G.ADEL, 0.0016, 0.0016),
                     (Vector((sp2.x + sx * 0.036, sp2.y - 0.045, 1.335)), G.ADEL, 0.0016, 0.0016)], segs=4,
               mat=lambda i, j: 1)
    piezas.append(cor)

    # ------------------------------------------------------------ falda: corta delante, cola larga detrás
    piezas += _falda(H)

    # ------------------------------------------------------------ piernas, zapatos
    for lado, sx in (("Left", 1), ("Right", -1)):
        ul, lg, ft, tb = H.c(lado + "UpLeg"), H.c(lado + "Leg"), H.c(lado + "Foot"), H.c(lado + "ToeBase")
        pierna = G.Pieza("lya_pierna_" + lado, ["piel"], [("Hips", 0.5), (lado + "UpLeg", 1.0), (lado + "Leg", 1.0)], p=4)
        pts = [ul + Vector((sx * -0.02, 0, 0.03)), ul, ul.lerp(lg, 0.5), lg, lg.lerp(ft, 0.5), ft + Vector((0, 0, 0.01))]
        rad = [(0.056, 0.056), (0.058, 0.058), (0.048, 0.050), (0.038, 0.040), (0.034, 0.036), (0.026, 0.028)]
        G.tubo(pierna, G.cadena(pts, G.ADEL, rad, 2), segs=12)
        piezas.append(pierna)
        zap = G.Pieza("lya_zapato_" + lado, ["zapato", "oro", "cristal", "blanco"],
                      [(lado + "Leg", 0.6), (lado + "Foot", 1.4), (lado + "ToeBase", 1.0)], p=5)
        dirp = Vector((tb.x - ft.x, tb.y - ft.y, 0)).normalized()
        # zapato de tacón: el empeine sube hasta el tobillo; la suela inclinada (talón alto) hasta la punta
        tob = Vector((ft.x, ft.y, ft.z))
        talon = Vector((ft.x, ft.y, 0.075)) - dirp * 0.022
        punta = Vector((tb.x, tb.y, 0.022)) + dirp * 0.05
        an = [(tob + Vector((0, 0.004, 0.012)), G.ARR, 0.031, 0.031),
              (talon.lerp(tob, 0.4) + dirp * 0.012, G.ARR, 0.033, 0.034),
              (talon.lerp(punta, 0.45) + Vector((0, 0, 0.012)), G.ARR, 0.027, 0.034),
              (talon.lerp(punta, 0.78) + Vector((0, 0, -0.002)), G.ARR, 0.022, 0.032),
              (punta, G.ARR, 0.014, 0.024)]
        G.tubo(zap, an, segs=12, tapa1=True, abombar=0.5)
        # tacón
        G.tubo(zap, [(Vector((talon.x, talon.y + 0.006, 0.0)), G.ADEL, 0.010, 0.010),
                     (Vector((talon.x, talon.y + 0.006, 0.07)), G.ADEL, 0.016, 0.017)], segs=8, tapa0=True,
               mat=lambda i, j: 3)
        # tobillera dorada con cristal
        G.tubo(zap, [(tob + Vector((0, 0, 0.004)), G.ADEL, 0.030, 0.031), (tob + Vector((0, 0, 0.018)), G.ADEL, 0.030, 0.031)],
               segs=10, mat=lambda i, j: 1)
        G.gema(zap, tob + Vector((0, -0.033, 0.011)), G.ARR, G.ADEL, 0.008, 0.024, mat=2)
        G.gema(zap, talon.lerp(punta, 0.5) + Vector((0, 0, 0.034)), G.ADEL, G.ARR, 0.007, 0.022, mat=2)
        piezas.append(zap)

    # ------------------------------------------------------------ brazos (piel), manos y mangas acampanadas
    for lado, sx in (("Left", 1), ("Right", -1)):
        sh, ar, fa, hd = H.c(lado + "Shoulder"), H.c(lado + "Arm"), H.c(lado + "ForeArm"), H.c(lado + "Hand")
        brazo = G.Pieza("lya_brazo_" + lado, ["piel"],
                        [(lado + "Shoulder", 0.6), (lado + "Arm", 1.0), (lado + "ForeArm", 1.0), (lado + "Hand", 0.6)], p=4)
        pts = [ar - Vector((sx * 0.04, 0, 0)), ar, ar.lerp(fa, 0.5), fa, fa.lerp(hd, 0.5), hd]
        rad = [(0.040, 0.040), (0.036, 0.036), (0.031, 0.031), (0.027, 0.027), (0.024, 0.024), (0.021, 0.021)]
        G.tubo(brazo, G.cadena(pts, G.ADEL, rad, 2), segs=10)
        piezas.append(brazo)
        piezas.append(_mano(H, lado, sx))
        # manga suelta: del brazo (banda azul con lazo dorado) a más allá de la mano, abierta y acampanada
        punta = H.k(lado + "Hand")
        bone_p = "Bone_040" if lado == "Left" else "Bone_041"
        mg = G.Pieza("lya_manga_" + lado, ["manga", "azul", "oro"],
                     [(lado + "Arm", 0.8), (lado + "ForeArm", 1.0), (lado + "Hand", 0.8), (bone_p, 0.7)], p=3,
                     grosor=0.005, interior="forro")
        c0 = ar.lerp(fa, 0.55)
        ejes = [c0, c0.lerp(fa, 0.5), fa, fa.lerp(hd, 0.6), hd.lerp(punta, 0.3), hd.lerp(punta, 0.75) + Vector((0, 0, -0.01))]
        rads = [(0.036, 0.036), (0.040, 0.040), (0.046, 0.048), (0.056, 0.060), (0.066, 0.072), (0.072, 0.080)]
        an = []
        for c, (rx, ry) in zip(ejes, rads):
            an.append({"c": c + Vector((0, 0, -0.012 * (rx - 0.04) / 0.06)), "f": G.ADEL, "rx": rx, "ry": ry})
        nn = len(an)
        G.tubo(mg, an, segs=14, mat=lambda i, j, nn=nn: 1 if i == 0 else (2 if i == nn - 2 else 0))
        piezas.append(mg)

    # ------------------------------------------------------------ pelo y flores
    piezas.append(_pelo_piezas())
    piezas.append(_flores())
    return piezas


def _mano(H, lado, sx):
    """Mano de Lya: su esqueleto solo trae pulgar y corazón; los otros tres dedos van al lado del corazón y con sus
    pesos (se mueven con él, como en los v2), y el pulgar con el suyo."""
    hd = H.c(lado + "Hand")
    nud = H.c(lado + "HandMiddle1")
    eje = (nud - hd).normalized()
    m = G.Pieza("lya_mano_" + lado, ["piel", "oro"],
                [(lado + "Hand", 1.0)] + [(lado + "Hand" + d + str(i), 1.0) for d in ("Thumb", "Middle") for i in (1, 2, 3)],
                p=5)
    abajo = Vector((0, 0, -1))
    pal = [(hd - eje * 0.010, abajo, 0.015, 0.020), (hd.lerp(nud, 0.45), abajo, 0.016, 0.026),
           (nud - eje * 0.006, abajo, 0.014, 0.030), (nud + eje * 0.004, abajo, 0.011, 0.028)]
    G.tubo(m, pal, segs=10, tapa1=True, abombar=0.3)
    G.tubo(m, [(hd - eje * 0.034, abajo, 0.026, 0.027), (hd - eje * 0.020, abajo, 0.026, 0.027)], segs=10,
           mat=lambda i, j: 1)                                     # pulsera dorada
    med = [H.c(lado + "HandMiddle" + str(i)) for i in (1, 2, 3, 4)] + [H.k(lado + "HandMiddle4")]
    lat = Vector((0, -1, 0))                                        # hacia el pulgar (en la T, delante)
    for off, r, k in ((0.016, 0.0072, 0.92), (0.0, 0.0078, 1.0), (-0.015, 0.0072, 0.92), (-0.028, 0.0062, 0.78)):
        pts = [nud - eje * 0.004 + lat * off]
        for q in med[1:]:
            pts.append(nud + (q - nud) * k + lat * off)
        ra = [(r, r), (r, r), (r * 0.92, r * 0.92), (r * 0.85, r * 0.85), (r * 0.7, r * 0.7)]
        G.tubo(m, G.cadena(pts, abajo, ra, 1), segs=6, tapa1=True, abombar=0.6)
    th = [H.c(lado + "HandThumb" + str(i)) for i in (1, 2, 3, 4)] + [H.k(lado + "HandThumb4")]
    G.tubo(m, G.cadena(th, abajo, [(0.0085, 0.0085)] * 3 + [(0.0075, 0.0075), (0.006, 0.006)], 1), segs=6, tapa1=True,
           abombar=0.6)
    return m


def _falda(H):
    """Falda de vuelo: del talle al bajo, corta delante (medio muslo) y con cola detrás (casi al suelo)."""
    hip = H.c("Hips")
    pz = G.Pieza("lya_falda", ["vestido", "oro", "azul_hielo"],
                 [("Hips", 1.4), ("LeftUpLeg", 0.5), ("RightUpLeg", 0.5), ("Bone_008", 1.0), ("Bone_007", 1.0),
                  ("Bone_006", 1.0), ("Bone_005", 1.0)], p=2.6, grosor=0.006, interior="forro")
    bm = pz.bm
    na = 28
    nr = 10
    filas = []
    z0 = 1.04
    for i in range(nr + 1):
        s = i / nr
        fila = []
        for j in range(na):
            a = 2 * math.pi * j / na                     # 0 = delante
            atras = (1 - math.cos(a)) * 0.5               # 0 delante, 1 detrás
            z_bajo = 0.62 - 0.50 * atras ** 1.3           # delante 0,62 m, detrás 0,12 m
            z = z0 + (z_bajo - z0) * s
            r_x = 0.106 + (0.25 + 0.06 * atras) * s ** 0.8
            r_y = 0.082 + (0.20 + 0.14 * atras) * s ** 0.8
            # ondas suaves del vuelo
            onda = 1.0 + 0.05 * math.sin(a * 9) * s
            p = Vector((hip.x + math.sin(a) * r_x * onda, hip.y + 0.01 - math.cos(a) * r_y * onda + 0.03 * atras * s, z))
            v = bm.verts.new(p)
            fila.append(v)
        filas.append(fila)
    G._uv_filas(pz, list(reversed(filas)), [Vector((hip.x, hip.y, z0 - 0.4 * i / nr)) for i in range(nr, -1, -1)],
                cerrado=True)
    for i in range(nr):
        for j in range(na):
            j2 = (j + 1) % na
            f = bm.faces.new((filas[i][j], filas[i + 1][j], filas[i + 1][j2], filas[i][j2]))
            f.material_index = 0 if i < nr - 2 else (2 if i == nr - 2 else 1)
            if i == 0:
                f.material_index = 1
    return [pz]


# ------------------------------------------------------------------ pelo
def _u(theta, phi):
    t, p = math.radians(theta), math.radians(phi)
    return Vector((math.sin(t) * math.sin(p), -math.sin(t) * math.cos(p), math.cos(t)))


def _elip(u, k):
    C = CRANEO["c"]
    return C + Vector((u.x * CRANEO["rx"], u.y * CRANEO["ry"], u.z * CRANEO["rz"])) * k


def mechon_de(pz, t0, f0, t1, f1, ancho, grueso=0.016, k=1.10, levantar=0.10, segs=9, mas=0.0):
    u0, u1 = _u(t0, f0), _u(t1, f1)
    pts, nor = [], []
    for i in range(segs + 1):
        s = i / segs * (1.0 + mas)
        u = K._slerp(u0, u1, min(s, 1.0))
        if s > 1.0:
            u = (u1 + (u1 - K._slerp(u0, u1, 0.9)) * (s - 1.0) * 10).normalized()
        kk = k + levantar * (s ** 2.2) - 0.06 * (1 - s) ** 3
        pts.append(_elip(u, kk))
        nor.append(u)
    G.mechon_pts(pz, pts, nor, ancho, grueso, lados=5)


def melena(pz, rnd, f, largo, ancho, z_fin, ondas=2.5, abrir=0.0):
    """Mechón largo que baja por la espalda o los lados desde el casco hasta z_fin, con ondas."""
    u = _u(70, f)
    raiz = _elip(_u(40, f), 1.08)
    ini = _elip(u, 1.14)
    pts, nor = [raiz], [u]
    n = 12
    salida = Vector((u.x, u.y, 0)).normalized() if Vector((u.x, u.y, 0)).length > 1e-4 else Vector((0, 1, 0))
    for i in range(1, n + 1):
        s = i / n
        z = ini.z + (z_fin - ini.z) * s
        r = 1.0 + abrir * s
        lateral = Vector((-salida.y, salida.x, 0)) * math.sin(s * math.pi * ondas + f * 0.05) * 0.018 * s
        p = Vector((CRANEO["c"].x, CRANEO["c"].y, 0)) + Vector((ini.x - CRANEO["c"].x, ini.y - CRANEO["c"].y, 0)) * r \
            + salida * (0.02 * s + 0.05 * math.sin(s * math.pi) * 0.4) + lateral
        p.z = z
        pts.append(p)
        nor.append(salida)
    perfil = lambda s: (0.6 + 0.4 * math.sin(min(1.0, s / 0.25) * math.pi / 2)) * (1.0 - max(0.0, s - 0.7) / 0.3) ** 0.8
    G.mechon_pts(pz, pts, nor, ancho, 0.022, lados=5, perfil=perfil)


def _pelo_piezas():
    rnd = random.Random(11)
    j = lambda a: rnd.uniform(-a, a)
    pz = G.Pieza("lya_pelo", ["pelo"], [("Head", 1.0), ("Bone_018", 0.9), ("Bone_017", 0.9), ("Neck", 0.4),
                                         ("Spine2", 0.3)], p=3.0)
    C = CRANEO["c"]
    def casco(u):
        return Vector((u.x * 1.10, u.y * 1.09 + 0.02, u.z * 1.08 + 0.05))
    # el casquete se hace con el cráneo de Lya
    _casquete_lya(pz, casco)
    # flequillo suelto: mechones finos que se abren, uno a cada lado más largo enmarcando la cara
    for f1 in range(-60, 61, 15):
        mechon_de(pz, 6 + j(3), f1 * 0.3, 84 + abs(f1) * 0.12 + j(4), f1 + j(4), 0.040 + j(0.005), grueso=0.016,
                  k=1.12, levantar=0.05, segs=8)
    for sx in (-1, 1):
        mechon_de(pz, 20, sx * 60, 125, sx * 72, 0.040, grueso=0.016, k=1.10, levantar=0.10, mas=0.25)
    # coronilla: del remolino hacia los lados y atrás, lisa arriba
    for f1 in range(-180, 180, 20):
        mechon_de(pz, 12 + j(3), 180 + j(10), 62 + j(4), f1 + j(5), 0.06, grueso=0.02, k=1.15, levantar=0.06, segs=8)
    # melena larga: por detrás hasta la cadera y por los lados hasta el pecho, ondulada
    for f in range(100, 261, 16):
        melena(pz, rnd, f + j(4), 0, 0.055 + j(0.006), 1.02 + j(0.04), ondas=2.5 + j(0.5), abrir=0.25)
    for sx in (-1, 1):
        for f in (70, 86):
            melena(pz, rnd, sx * (f + j(3)), 0, 0.050, 1.20 + j(0.03), ondas=3.0, abrir=0.15)
    return pz


def _casquete_lya(pz, casco):
    import bmesh, bpy
    C = CRANEO["c"]
    tmp = G.Pieza("tmp", ["pelo"], [("Head", 1.0)])
    G.esfera(tmp, C, CRANEO["rx"], CRANEO["ry"], CRANEO["rz"], segs=28, anillos=16, deformar=casco)
    bm = tmp.bm
    quitar = []
    for v in bm.verts:
        u = v.co - C
        x, y, z = u.x / CRANEO["rx"], u.y / CRANEO["ry"], u.z / CRANEO["rz"]
        cara = y < -0.30 and z < 0.62 - 0.25 * abs(x)
        if cara or (z < -0.28 and y < 0.4) or z < -0.75:
            quitar.append(v)
    bmesh.ops.delete(bm, geom=quitar, context='VERTS')
    me_tmp = bpy.data.meshes.new("tmp_casco")
    bm.to_mesh(me_tmp)
    bm.free()
    pz.bm.from_mesh(me_tmp)
    bpy.data.meshes.remove(me_tmp)


def _flores():
    """Lirios blancos con centro dorado y lazo, a los dos lados de la cabeza (el izquierdo, mayor, con cintas)."""
    pz = G.Pieza("lya_flores", ["flor", "flor_centro", "blanco"], [("Head", 1.0)], p=4)
    for sx, esc in ((1, 1.5), (-1, 1.2)):
        c = _elip(_u(58, sx * 80), 1.17)
        fuera = (c - CRANEO["c"]).normalized()
        for k in range(5):
            a = 2 * math.pi * k / 5
            t, n, b = G.marco(fuera, G.ARR)
            d = (n * math.cos(a) + b * math.sin(a)).normalized()
            p0 = c + d * 0.004
            G.mechon(pz, p0, p0 + d * 0.02 * esc + fuera * 0.006, p0 + d * 0.036 * esc + fuera * 0.008,
                     p0 + d * 0.05 * esc + fuera * 0.002, 0.016 * esc, 0.004, fuera, segs=5, lados=5, mat=0)
        G.esfera(pz, c + fuera * 0.008, 0.009 * esc, 0.009 * esc, 0.009 * esc, segs=8, anillos=6, mat=1)
        if sx > 0:      # lazo con dos cintas que caen
            for dz, lado in ((-0.004, 1), (0.004, -1)):
                p0 = c + Vector((0, 0.02, -0.02))
                G.mechon(pz, p0, p0 + Vector((0.01, 0.02 * lado, -0.03)), p0 + Vector((0.012, 0.03 * lado, -0.07)),
                         p0 + Vector((0.01, 0.025 * lado, -0.11)), 0.012, 0.003, fuera, segs=6, lados=4, mat=2,
                         abultar=0.0)
    return pz
