# Casas de Oakhaven (T-089): el constructor de casas (también lo usan la botica y el cuerpo de guardia) y el juego de
# casas de relleno, una por huella (casa_<ancho>x<fondo>), dibujadas en (0, 0) y puestas donde diga el relleno.
# Una misma imagen sirve para varias casas iguales (se dibujan juntas y no gastan memoria de más).
import math, random
import kit as K
from kit import caja, viga, cilindro, esfera


def casa(x0, y0, W, D, estilo, semilla=1, nombre="casa"):
    """Casa de una o dos plantas que mira al sur (fachada en y0 + D). estilo: pb y pa (materiales de cada planta),
    entramado (vigas en la planta alta, con vuelo), tejado (teja o pizarra), contra (contraventanas), pisos (1 o 2),
    frontal (hastial a la calle), puerta_x, vidrio, chimeneas (cuántas)."""
    import piezas_ciudad as C
    m = C.M()
    rnd = random.Random(semilla)
    X0, X1, YN, YS = x0, x0 + W, y0, y0 + D
    pisos = estilo.get("pisos", 2)
    Z1 = 2.9
    Z2 = Z1 + (2.5 if pisos == 2 else 0.0)
    vuelo = 0.25 if (estilo.get("entramado") and pisos == 2) else 0.0
    vidrio = m[estilo.get("vidrio", "ventana")]
    contra = m[estilo.get("contra", "contra")]
    flores = (m["geranio"], m["rosa"], m["hoja"]) if rnd.random() < 0.5 else (m["lavanda"], m["blanca"], m["hoja"])
    p = []
    # ---- planta baja
    px_ = estilo.get("puerta_x", X0 + (1.1 if W <= 4 else 1.4 + rnd.uniform(0, W - 3.2)))
    huecos = [(px_ - 0.55, px_ + 0.55, 0.0, 2.25)]
    xs = []
    x = X0 + 0.9
    while x < X1 - 0.6:
        if abs(x - px_) > 1.25:
            xs.append(x)
            x += 1.5
        else:
            x += 0.5
    for xv in xs:
        huecos.append((xv - 0.45, xv + 0.45, 0.95, 2.15))
    p += K.fachada(X0, X1, YS, 0.0, Z1, 0.3, m[estilo["pb"]], huecos, nombre + "_pb")
    p.append(caja(X0, YN, 0.0, X1, YS - 0.3, Z1, m[estilo["pb"]], nombre + "_pb_dentro"))
    if estilo["pb"] in ("revoque", "revoque_ocre", "revoque_gris"):
        p.append(caja(X0 - 0.03, YS - 0.05, 0.0, X1 + 0.03, YS + 0.06, 0.4, m["zocalo"], nombre + "_zocalo", 0.02))
    encendidas = 0
    for (a, b, za, zb) in huecos[1:]:
        luz = rnd.random() < 0.75
        encendidas += 1 if luz else 0
        if luz:
            p += K.ventana((a + b) * 0.5, YS, za, b - a, zb - za, m["viga"], vidrio, contra, None, True, 0.18,
                           nombre + "_v", luz=(K.CALIDA, 14.0))
        else:
            p += _ventana_cerrada((a + b) * 0.5, YS, za, b - a, zb - za, m, contra, nombre + "_vc")
    p += K.puerta(px_, YS, 1.1, 2.25, m["puerta"], m["hierro"], m["viga"], 0.0, None, 0.16, nombre=nombre + "_puerta")
    p.append(caja(px_ - 0.75, YS - 0.05, 0.0, px_ + 0.75, YS + 0.3, 0.12, m["zocalo"], nombre + "_escalon", 0.02))
    anclas = {"puerta": (px_, YS + 0.5, 0.0)}
    efectos = []
    if rnd.random() < 0.55:
        import piezas as P
        fa, ancla = P._farol_pared(px_ + 0.85, YS, 2.0, m, nombre + "_farol", 30.0)
        p += fa
        anclas["farol"] = ancla
        efectos.append({"tipo": "halo", "ancla": "farol", "radio": 1.1, "fuerza": 0.45})
    # ---- planta alta
    YS2 = YS + vuelo
    if pisos == 2:
        if vuelo > 0:
            p.append(caja(X0 - 0.03, YS - 0.1, Z1 - 0.2, X1 + 0.03, YS2, Z1, m["viga"], nombre + "_viga_vuelo", 0.012))
        n = max(2, int(W / 1.45))
        h2 = []
        for i in range(n):
            cx = X0 + (i + 0.5) * W / n
            h2.append((cx - 0.38, cx + 0.38, Z1 + 0.5, Z1 + 1.6))
        mat_pa = m[estilo.get("pa", estilo["pb"])]
        p += K.fachada(X0, X1, YS2, Z1, Z2, 0.25, mat_pa, h2, nombre + "_pa")
        p.append(caja(X0, YN, Z1, X1, YS2 - 0.25, Z2, mat_pa, nombre + "_pa_dentro"))
        if estilo.get("entramado"):
            p += K.entramado(X0, X1, YS2, Z1, Z2, h2, m["viga"], 0.15, 0.05, 1.1, True, nombre + "_ent")
        for (a, b, za, zb) in h2:
            if rnd.random() < 0.7:
                p += K.ventana((a + b) * 0.5, YS2, za, b - a, zb - za, m["viga"], m["ventana_alta"], contra,
                               flores if rnd.random() < 0.6 else None, True, 0.12, nombre + "_va", luz=(K.CALIDA, 6.0))
            else:
                p += _ventana_cerrada((a + b) * 0.5, YS2, za, b - a, zb - za, m, contra, nombre + "_vac")
    # ---- tejado
    tej = m[estilo.get("tejado", "teja")]
    alto = 0.4 * D if not estilo.get("frontal") else 0.45 * W
    if estilo.get("frontal"):
        p.append(K.hastial_muro(X0, X1, YS2, Z2, alto, m[estilo.get("pa", estilo["pb"])], 0.25, nombre + "_hastial"))
        if estilo.get("entramado"):
            for lado in (-1, 1):
                a = ((X0 + X1) * 0.5, YS2 + 0.03, Z2 + alto - 0.05)
                b = (X0 + 0.1 if lado < 0 else X1 - 0.1, YS2 + 0.03, Z2 + 0.1)
                p.append(viga(a, b, 0.14, m["viga"], 0.05, nombre + "_hastial_viga"))
            p.append(caja(X0, YS2, Z2, X1, YS2 + 0.05, Z2 + 0.15, m["viga"], nombre + "_hastial_solera", 0.01))
        p += K.ventana((X0 + X1) * 0.5, YS2, Z2 + 0.45, 0.5, 0.6, m["viga"], m["ventana_alta"], None, None, False, 0.1,
                       nombre + "_buhardilla", luz=(K.CALIDA, 3.0), rejilla=2)
        p += K.tejado_frontal(X0, X1, YS2 + 0.02, YN - 0.1, Z2, alto, tej, 0.3, nombre + "_tejado", madera=m["viga"])
    else:
        p += K.tejado_dos_aguas(X0, X1, YS2, YN, Z2, alto, tej, 0.32, 0.25, None, nombre + "_tejado")
    # ---- chimeneas
    for k in range(estilo.get("chimeneas", 1)):
        cx = X0 + (0.8 + rnd.uniform(0, W - 1.6) if W > 2 else W * 0.5)
        cy = YN + D * 0.3
        chim, humo = K.chimenea(cx, cy, Z2 - 0.5, alto + 1.5, 0.5, m["piedra"], nombre="%s_chimenea%d" % (nombre, k))
        p += chim
        anclas["humo%d" % k] = humo
        efectos.append({"tipo": "humo", "ancla": "humo%d" % k, "color": "calido", "alto": 2.4, "escala": 0.75})
    return {
        "rect": (int(x0), int(y0), W, D),
        "capas": [{"nombre": "cuerpo", "objetos": p, "orden": YS, "tipo": "edificio"}],
        "suelo": True,
        "anclas": anclas,
        "efectos": efectos,
        "choques": [],
        "margen_suelo": (120, 24, 140, 130),
    }


def _ventana_cerrada(cx, y, z0, ancho, alto, m, contra, nombre):
    """Ventana con las contraventanas cerradas (sin luz)."""
    p = []
    g = 0.08
    p.append(caja(cx - ancho * 0.5 - g, y - 0.02, z0 + alto, cx + ancho * 0.5 + g, y + 0.05, z0 + alto + g * 1.3, m["viga"], nombre + "_m3", 0.008))
    p.append(caja(cx - ancho * 0.5 - g * 1.6, y - 0.04, z0 - g * 1.2, cx + ancho * 0.5 + g * 1.6, y + 0.14, z0, m["viga"], nombre + "_alfeizar", 0.01))
    for lado in (-1, 1):
        x_a = cx - ancho * 0.5 if lado < 0 else cx
        p.append(caja(x_a + 0.005, y - 0.05, z0, x_a + ancho * 0.5 - 0.005, y + 0.02, z0 + alto, contra, nombre + "_hoja", 0.01))
        for k in range(3):
            zz = z0 + alto * (0.15 + 0.3 * k)
            p.append(caja(x_a + 0.03, y + 0.02, zz, x_a + ancho * 0.5 - 0.03, y + 0.035, zz + 0.04, m["viga"], nombre + "_liston"))
    return p


ESTILOS = {
    "casa_4x4": {"pb": "revoque", "pa": "revoque", "entramado": True, "tejado": "teja", "contra": "contra", "frontal": True},
    "casa_5x4": {"pb": "piedra", "pa": "revoque_ocre", "entramado": True, "tejado": "teja", "contra": "contra_azul"},
    "casa_6x4": {"pb": "revoque", "pa": "revoque", "entramado": True, "tejado": "teja", "contra": "contra_roja", "chimeneas": 2},
    "casa_4x5": {"pb": "piedra_gris", "pa": "piedra_gris", "entramado": False, "tejado": "pizarra", "contra": "contra_azul", "frontal": True},
    "casa_5x5": {"pb": "revoque_gris", "pa": "revoque_gris", "entramado": True, "tejado": "pizarra", "contra": "contra"},
    "casa_6x5": {"pb": "piedra", "pa": "revoque", "entramado": True, "tejado": "teja", "contra": "contra"},
    "casa_3x4": {"pb": "revoque_ocre", "pa": "revoque_ocre", "entramado": True, "tejado": "teja", "contra": "contra_roja", "frontal": True},
}


def _hacer(clave, semilla):
    w, d = (int(v) for v in clave[5:].split("x"))
    return lambda: casa(0.0, 0.0, w, d, ESTILOS[clave], semilla, clave)


PIEZAS = {clave: _hacer(clave, 100 + i * 7) for i, clave in enumerate(ESTILOS)}
