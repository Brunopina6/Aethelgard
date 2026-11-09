# Piezas de Oakhaven (T-089), además de la taberna (piezas.py): crematorio, árbol, Concejo y su pórtico con el tapiz,
# torre, ronda, mercado, plaza, grieta, Patio de las Velas, jardín de urnas, Puerta del Sur, botica, guardia y faroles.
# Mismo formato de ficha que piezas.py. Coordenadas en casillas del juego (x este, y SUR, z arriba).
import math, random
import numpy as np
import bpy, bmesh
from mathutils import Vector
import kit as K
from kit import caja, viga, cilindro, esfera, mat, V


def M():
    """Catálogo de materiales de la ciudad (paleta del diseño §2.1)."""
    return {
        "piedra": mat("piedra", "#8C847A", "#A39A8C", (0.62, 0.31), "#5A534C", 0.12, nombre="piedra_calida"),
        "piedra_gris": mat("piedra", "#8A877F", "#9E9A91", (0.7, 0.35), "#5C5954", 0.18, nombre="piedra_gris"),
        "zocalo": mat("piedra", "#7C756C", "#8F877C", (0.5, 0.25), "#4E4943", 0.25, nombre="zocalo"),
        "hueso": mat("piedra", "#D9D4C7", "#CDC7B8", (0.82, 0.41), "#9A9488", 0.05, nombre="hueso"),
        "hueso_liso": mat("liso", K.hexlin("#D4CEC0"), 0.85, nombre="hueso_liso"),
        "revoque": mat("revoque", "#D8C8A4", "#8F826B", nombre="revoque_cuervo"),
        "revoque_ocre": mat("revoque", "#D6B07E", "#8A6E4E", nombre="revoque_ocre"),
        "revoque_gris": mat("revoque", "#B9BBB6", "#787A74", nombre="revoque_gris"),
        "viga": mat("madera", "#6B3F2A", 0.35, nombre="viga"),
        "madera_clara": mat("madera", "#8A5A3A", 0.4, nombre="madera_clara"),
        "puerta": mat("madera", "#7A4A2E", 0.5, nombre="puerta_madera", escala_veta=(1.0, 1.0, 6.0)),
        "teja": mat("teja", "#A0583A", 0.24, nombre="teja_roja"),
        "pizarra": mat("pizarra", "#5E5F63", nombre="pizarra"),
        "hierro": mat("hierro", 0.65, nombre="hierro_oxidado"),
        "hierro_negro": mat("hierro", 0.2, nombre="hierro_negro"),
        "bronce": mat("liso", K.hexlin("#8C6A3A"), 0.38, 0.9, nombre="bronce"),
        "oro": mat("liso", K.hexlin("#C9A44A"), 0.3, 1.0, nombre="oro"),
        "ventana": mat("ventana", "#FFB45A", 1.7, nombre="ventana_calida"),
        "ventana_alta": mat("ventana", "#FFA94E", 1.25, nombre="ventana_calida_alta"),
        "ventana_verde": mat("ventana", "#C8D27A", 1.1, nombre="ventana_botica"),
        "vidrio_frio": mat("liso", K.hexlin("#26304A"), 0.12, nombre="vidrio_frio"),
        "farol": mat("luz", "#F2C86B", 3.5, nombre="farol_encendido"),
        "farol_apagado": mat("liso", K.hexlin("#3A3A36"), 0.3, nombre="farol_apagado"),
        "llama": mat("luz", "#FFC060", 7.0, nombre="llama"),
        "cera": mat("liso", K.hexlin("#EFE6D0"), 0.55, nombre="cera"),
        "contra": mat("madera", "#3E5B47", 0.2, nombre="contraventana_verde", escala_veta=(1, 1, 3)),
        "contra_azul": mat("madera", "#3E4F6B", 0.2, nombre="contraventana_azul", escala_veta=(1, 1, 3)),
        "contra_roja": mat("madera", "#7A3530", 0.2, nombre="contraventana_roja", escala_veta=(1, 1, 3)),
        "geranio": mat("liso", K.hexlin("#B8364A"), 0.7, nombre="geranio"),
        "rosa": mat("liso", K.hexlin("#E58FB0"), 0.7, nombre="flor_rosa"),
        "lavanda": mat("liso", K.hexlin("#8E7CC3"), 0.7, nombre="flor_lavanda"),
        "amarilla": mat("liso", K.hexlin("#E8C547"), 0.7, nombre="flor_amarilla"),
        "blanca": mat("liso", K.hexlin("#EDE8DA"), 0.7, nombre="flor_blanca"),
        "hoja": mat("liso", K.hexlin("#3F5E3A"), 0.8, nombre="hoja_maceta"),
        "hojas": mat("hojas", nombre="hojas_roble"),
        "hojas_dentro": mat("hojas", "#1E3324", "#2A4630", "#3F5E3A", nombre="hojas_dentro"),
        "hoja_roble": mat("hoja", "#2A4A2E", "#4A7040", "#7EA05A", nombre="hoja_roble"),
        "cipres": mat("hojas", "#1C2F24", "#28402F", "#3B5A45", nombre="cipres"),
        "seto": mat("hojas", "#2A4A2C", "#3A5E37", "#5A7E45", nombre="seto"),
        "corteza": mat("corteza", nombre="corteza"),
        "tela_roja": mat("tela", "#8E3B34", nombre="tela_roja", rayas="#D9C9A8"),
        "tela_verde": mat("tela", "#3E6B5C", nombre="tela_verde", rayas="#D9C9A8"),
        "tela_ocre": mat("tela", "#B8862F", nombre="tela_ocre", rayas="#E6D8B5"),
        "tela_azul": mat("tela", "#2F4E7A", nombre="tela_azul"),
        "tela_lisa": mat("tela", "#C9BBA0", nombre="tela_lisa"),
        "agua": mat("liso", K.hexlin("#33557A"), 0.03, nombre="agua"),
        "tierra": mat("liso", K.hexlin("#5B4A3A"), 0.95, nombre="tierra"),
        "grava": mat("piedra", "#8E8A82", "#A29D94", (0.18, 0.12), "#6C6862", 0.0, nombre="grava"),
        "manzana": mat("liso", K.hexlin("#A8322B"), 0.5, nombre="manzana"),
        "col": mat("liso", K.hexlin("#6E8F4E"), 0.6, nombre="col"),
        "pan": mat("liso", K.hexlin("#C08A4A"), 0.7, nombre="pan"),
        "calabaza": mat("liso", K.hexlin("#C86E2A"), 0.6, nombre="calabaza"),
        "cesta": mat("madera", "#9A7346", 0.6, nombre="cesta", escala_veta=(4, 4, 4)),
        "papel": mat("liso", K.hexlin("#E4D9BC"), 0.9, nombre="papel"),
        "saco": mat("tela", "#9C8A68", nombre="saco"),
    }


# ================================================================= ayudantes comunes

def farol_poste(x, y, m, alto=2.7, encendido=True, nombre="farol", potencia=45.0):
    """Farola de hierro con su farol arriba. Devuelve (partes, ancla del farol)."""
    p = []
    p.append(cilindro((x, y, 0.08), 0.16, 0.16, m["zocalo"], 12, nombre + "_base", r_arriba=0.12))
    p.append(cilindro((x, y, alto * 0.5), 0.045, alto, m["hierro_negro"], 10, nombre + "_poste"))
    zc = alto + 0.18
    vidrio = m["farol"] if encendido else m["farol_apagado"]
    p.append(caja(x - 0.13, y - 0.13, zc - 0.17, x + 0.13, y + 0.13, zc + 0.15, vidrio, nombre + "_vidrio"))
    for dx in (-0.14, 0.14):
        for dy in (-0.14, 0.14):
            p.append(caja(x + dx - 0.015, y + dy - 0.015, zc - 0.2, x + dx + 0.015, y + dy + 0.015, zc + 0.17, m["hierro_negro"], nombre + "_varilla"))
    p.append(cilindro((x, y, zc + 0.24), 0.21, 0.14, m["hierro_negro"], 4, nombre + "_tejadillo", r_arriba=0.02))
    p.append(caja(x - 0.16, y - 0.16, zc - 0.24, x + 0.16, y + 0.16, zc - 0.18, m["hierro_negro"], nombre + "_base_farol"))
    if encendido:
        K.luz_punto((x, y + 0.05, zc), K.FAROL, potencia, 0.07, nombre + "_luz")
    return p, (x, y, zc)


def flores_maceta(x0, x1, y, z, m, semilla, colores=("geranio", "rosa", "hoja")):
    p = []
    rnd = random.Random(semilla)
    n = max(3, int((x1 - x0) / 0.14))
    for i in range(n):
        fx = x0 + (i + 0.5) * (x1 - x0) / n
        p.append(esfera((fx, y + rnd.uniform(-0.06, 0.06), z + rnd.uniform(0, 0.08)), 0.08 + rnd.uniform(0, 0.04),
                        m[colores[rnd.randrange(len(colores))]], "flor", 2))
    return p


def _textura_tapiz():
    """El tapiz de los reyes [C, progreso.gd]: la familia real en un paño viejo; entre el rey y la reina, el hueco
    donde estaba un niño, recortado a tijera (por ahí se ve la piedra). 192 × 160."""
    W, H = 192, 160
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    rnd = np.random.default_rng(7)
    px = np.zeros((H, W, 4), np.float32)
    base = np.array([0.46, 0.13, 0.17])
    trama = (np.sin(xx * 1.7) * 0.5 + 0.5) * 0.06 + (np.sin(yy * 1.9) * 0.5 + 0.5) * 0.05 + rnd.random((H, W)) * 0.05
    px[:, :, :3] = base[None, None, :] * (0.85 + trama[:, :, None])
    px[:, :, 3] = 1.0
    oro = np.array([0.79, 0.64, 0.29])
    borde = (xx < 9) | (xx > W - 10) | (yy < 9) | (yy > H - 22)
    px[borde, :3] = oro * (0.8 + 0.2 * np.sin((xx[borde] + yy[borde]) * 0.9)[:, None])
    filete = ((xx >= 11) & (xx <= 12)) | ((xx >= W - 13) & (xx <= W - 12)) | ((yy >= 11) & (yy <= 12)) | ((yy >= H - 25) & (yy <= H - 24))
    px[filete, :3] = [0.2, 0.08, 0.08]
    # flecos abajo
    flecos = (yy > H - 14) & ((xx.astype(int) % 6) < 3)
    px[(yy > H - 14) & ~flecos, 3] = 0.0
    px[flecos, :3] = oro * 0.85

    def figura(cx, color, corona=True):
        # túnica en campana, cabeza y corona
        t = (yy - 52) / 78.0
        tunica = (yy > 52) & (yy < 130) & (np.abs(xx - cx) < 9 + t * 16)
        px[tunica, :3] = np.array(color) * (0.85 + 0.15 * np.sin(xx[tunica] * 0.8)[:, None])
        cabeza = (xx - cx) ** 2 + (yy - 42) ** 2 < 9.5 ** 2
        px[cabeza, :3] = [0.86, 0.72, 0.55]
        if corona:
            c = (yy > 27) & (yy < 34) & (np.abs(xx - cx) < 9) & ((((xx - cx + 9) % 6) < 3) | (yy > 31))
            px[c, :3] = oro
        manto = (yy > 56) & (yy < 70) & (np.abs(xx - cx) < 14 + (yy - 56) * 0.6) & ~tunica
        px[manto, :3] = np.array(color) * 0.6

    figura(54, [0.2, 0.3, 0.55])                 # el rey
    figura(138, [0.22, 0.42, 0.3])               # la reina
    # el niño, recortado: un hueco irregular a tijera entre los dos (se ve la pared)
    borde_irreg = 4.0 * np.sin(yy * 0.55) + 3.0 * np.sin(yy * 1.3 + 1.0)
    hueco = (yy > 60) & (yy < 124) & (np.abs(xx - 96 - borde_irreg * 0.4) < 14 + borde_irreg * 0.5)
    hueco |= (xx - 96) ** 2 + (yy - 66) ** 2 < 12 ** 2
    px[hueco, 3] = 0.0
    hilos = (~hueco) & ((np.abs(xx - 96) < 17 + borde_irreg * 0.5) & (yy > 54) & (yy < 128))
    px[hilos, :3] *= 0.55                        # el borde del corte, deshilachado y oscuro
    # estrellas doradas y un roble bordado arriba
    for sx, sy in ((30, 26), (162, 26), (96, 24), (28, 120), (164, 120)):
        e = (np.abs(xx - sx) + np.abs(yy - sy)) < 5
        px[e, :3] = oro
    return px


def _textura_sello():
    """El sello del crematorio [C, progreso.gd]: placa de hierro con runas; un anillo dorado partido en el centro y
    marcas raspadas alrededor (los nombres que alguien borró). 128 × 128."""
    W = 128
    yy, xx = np.mgrid[0:W, 0:W].astype(np.float32)
    r = np.hypot(xx - 64, yy - 64)
    ang = np.arctan2(yy - 64, xx - 64)
    rnd = np.random.default_rng(3)
    px = np.zeros((W, W, 4), np.float32)
    placa = r < 60
    px[placa, :3] = [0.18, 0.17, 0.17]
    px[placa, 3] = 1.0
    px[placa, :3] += (rnd.random((int(placa.sum()), 1)) * 0.05).astype(np.float32)
    canto = (r > 55) & (r < 60)
    px[canto, :3] = [0.32, 0.22, 0.16]
    # runas alrededor (trazos cortos)
    runas = (r > 42) & (r < 52) & (np.sin(ang * 14) > 0.55) & (np.abs(np.sin(r * 0.9 + ang * 3)) > 0.3)
    px[runas, :3] = [0.45, 0.42, 0.38]
    # nombres raspados: arañazos claros sobre las runas
    for k in range(9):
        a0 = rnd.uniform(-math.pi, math.pi)
        d = np.abs(np.sin(ang - a0)) * r
        ras = (d < 1.4) & (r > 38) & (r < 54) & (np.cos(ang - a0) > 0)
        px[ras, :3] = [0.62, 0.6, 0.56]
    # anillo dorado partido (hueco arriba a la derecha)
    anillo = (r > 18) & (r < 27)
    corte = (np.abs(ang + 0.75) < 0.32)
    oro = np.array([0.86, 0.68, 0.3])
    px[anillo & ~corte, :3] = oro * (0.8 + 0.2 * np.cos(ang[anillo & ~corte] * 2)[:, None])
    return px


# ================================================================= crematorio

def crematorio():
    """Crematorio [C]: piedra hueso, pizarra, la chimenea alta con humo blanco y frío, ventanas altas sin luz y la
    puerta SELLADA con el sello rúnico del anillo partido (detalle oak_sello). El único sitio frío de la ciudad."""
    m = M()
    X0, X1, YN, YS = 62.0, 72.0, 7.0, 15.0
    ZA = 4.6
    p = []
    huecos = [(63.25, 63.95, 1.5, 3.7), (64.75, 65.45, 1.5, 3.7), (66.25, 67.75, 0.45, 3.3), (68.55, 69.25, 1.5, 3.7),
              (70.05, 70.75, 1.5, 3.7)]
    p += K.fachada(X0, X1, YS, 0.0, ZA, 0.45, m["hueso"], huecos, "crem_fachada")
    p.append(caja(X0, YN, 0.0, X1, YS - 0.45, ZA, m["hueso"], "crem_dentro"))
    p.append(caja(X0 - 0.12, YS - 0.4, 0.0, X1 + 0.12, YS + 0.12, 0.5, m["piedra_gris"], "crem_zocalo", 0.03))
    p.append(caja(X0 - 0.15, YS - 0.4, ZA - 0.3, X1 + 0.15, YS + 0.18, ZA, m["hueso_liso"], "crem_cornisa", 0.03))
    for bx in (62.0, 66.0, 68.0, 72.0):              # contrafuertes
        w = 0.5
        p.append(caja(bx - w * 0.5, YS - 0.2, 0.0, bx + w * 0.5, YS + 0.55, ZA - 0.6, m["hueso"], "contrafuerte", 0.03))
        p.append(viga((bx, YS + 0.55, ZA - 0.6), (bx, YS + 0.05, ZA - 0.15), 0.5, m["hueso_liso"], 0.5, "contrafuerte_remate"))
    for (a, b, za, zb) in huecos:
        if b - a < 1.0:                              # ventanas altas: vidrio frío y oscuro, con parteluz
            p.append(caja(a, YS - 0.32, za, b, YS - 0.3, zb, m["vidrio_frio"], "crem_vidrio"))
            p.append(caja((a + b) * 0.5 - 0.03, YS - 0.3, za, (a + b) * 0.5 + 0.03, YS - 0.26, zb, m["hierro_negro"], "crem_parteluz"))
            p.append(caja(a - 0.08, YS - 0.06, za - 0.14, b + 0.08, YS + 0.12, za, m["hueso_liso"], "crem_alfeizar", 0.01))
            p.append(K.semicirculo((a + b) * 0.5, YS + 0.012, zb, (b - a) * 0.5, 0.01, m["vidrio_frio"], "crem_arco"))
            p.append(K.semicirculo((a + b) * 0.5, YS + 0.006, zb, (b - a) * 0.5 + 0.09, 0.01, m["hueso_liso"], "crem_arco_marco"))
    # la puerta sellada: losa de piedra con flejes de hierro y el sello
    p.append(caja(66.25, YS - 0.3, 0.45, 67.75, YS - 0.18, 3.3, m["hueso_liso"], "puerta_losa", 0.02))
    for zz in (0.9, 1.9, 2.8):
        p.append(caja(66.2, YS - 0.18, zz, 67.8, YS - 0.12, zz + 0.1, m["hierro_negro"], "puerta_fleje"))
    p.append(K.semicirculo(67.0, YS + 0.012, 3.3, 0.75, 0.01, m["hueso_liso"], "puerta_arco"))
    p.append(K.semicirculo(67.0, YS + 0.006, 3.3, 0.88, 0.01, m["piedra_gris"], "puerta_arco_marco"))
    sello = K.m_imagen(K.imagen("sello", _textura_sello()), 0.5, "sello_mat")
    p.append(K.plano_imagen(66.6, 67.4, 1.45, 2.25, YS - 0.11, sello, "sello"))
    for k in range(3):                               # escalones
        p.append(caja(65.7 - k * 0.15, YS - 0.1, 0.0, 68.3 + k * 0.15, YS + 0.35 + k * 0.35, 0.45 - k * 0.15, m["piedra_gris"], "escalon", 0.02))
    # óculo sobre la puerta
    p.append(cilindro((67.0, YS - 0.35, 4.05), 0.42, 0.2, m["vidrio_frio"], 20, "oculo", eje='Y'))
    p.append(cilindro((67.0, YS - 0.2, 4.05), 0.5, 0.12, m["hueso_liso"], 20, "oculo_marco", eje='Y'))
    p += K.tejado_dos_aguas(X0, X1, YS, YN, ZA, 1.7, m["pizarra"], 0.3, 0.25, m["hierro_negro"], "crem_tejado")
    # la chimenea sale del faldón sur, al este: su humo tiene sitio para verse antes del borde del mapa
    chim, humo = K.chimenea(70.6, 12.4, 3.5, 4.3, 0.85, m["hueso"], m["piedra_gris"], "crem_chimenea")
    p += chim
    # urnas en hornacinas a los lados de la puerta
    for ux in (65.55, 68.45):
        p.append(caja(ux - 0.25, YS - 0.1, 2.35, ux + 0.25, YS + 0.12, 2.42, m["hueso_liso"], "repisa"))
    return {
        "rect": (62, 7, 10, 8),
        "capas": [{"nombre": "cuerpo", "objetos": p, "orden": YS, "tipo": "edificio"}],
        "suelo": True,
        "anclas": {"humo": humo, "puerta": (67.0, 15.5, 0.0), "sello": (67.0, YS, 1.85)},
        "efectos": [{"tipo": "humo", "ancla": "humo", "color": "frio", "alto": 4.2, "escala": 1.2}],
        "margen_suelo": (140, 24, 160, 120),
    }


# ================================================================= jardín de urnas

def _urna(x, y, m, s, rnd):
    p = []
    p.append(caja(x - 0.32, y - 0.32, 0.0, x + 0.32, y + 0.32, 0.55, m["hueso"], "pedestal", 0.03))
    alto = rnd.uniform(0.55, 0.75)
    u = cilindro((x, y, 0.55 + alto * 0.5), 0.2, alto, m["hueso_liso"], 16, "urna")
    bm = None
    md = u.modifiers.new("panza", 'SIMPLE_DEFORM')
    md.deform_method = 'TAPER'
    md.factor = -0.6
    p.append(u)
    p.append(esfera((x, y, 0.55 + alto + 0.05), 0.13, m["hueso_liso"], "tapa", 2, (1, 1, 0.6)))
    return p


def jardin_urnas():
    """Jardín de urnas: urnas de piedra hueso sobre pedestales, en dos hileras con un paseo de grava, y cipreses."""
    m = M()
    rnd = random.Random(11)
    norte, sur = [], []
    for x in (57.8, 58.8, 60.2, 61.2):
        norte += _urna(x, 10.2, m, 0, rnd)
        sur += _urna(x, 12.6, m, 0, rnd)
    cipreses = []
    for (x, y) in ((57.4, 9.4), (61.6, 9.3)):
        c = cilindro((x, y, 1.6), 0.42, 3.2, m["cipres"], 14, "cipres", r_arriba=0.05)
        K.desplazar(c, 0.12, 0.4)
        K.suavizar(c, 1)
        cipreses.append(c)
        cipreses.append(cilindro((x, y, 0.2), 0.12, 0.4, m["corteza"], 8, "cipres_tronco"))
    return {
        "rect": (57, 9, 5, 5),
        "capas": [
            {"nombre": "fondo", "objetos": cipreses, "orden": 9.6, "tipo": "objeto"},
            {"nombre": "urnas_norte", "objetos": norte, "orden": 10.55, "tipo": "objeto"},
            {"nombre": "urnas_sur", "objetos": sur, "orden": 12.95, "tipo": "objeto"},
        ],
        "suelo": True,
        "anclas": {"paseo": (59.5, 11.5, 0.0)},
        "efectos": [],
        "choques": [{"centro": [59.5, 10.2], "tam": [4.2, 0.7]}, {"centro": [59.5, 12.6], "tam": [4.2, 0.7]},
                    {"centro": [57.4, 9.4], "tam": [0.8, 0.6]}, {"centro": [61.6, 9.3], "tam": [0.8, 0.6]}],
        "margen_suelo": (60, 20, 80, 60),
    }


# ================================================================= el Árbol Milenario

def _ramas(bm, capa, v0, d, largo, r0, r1, nivel, rnd, puntas, pasos=None):
    n = pasos or max(2, int(largo / 0.8))
    prev = v0
    for i in range(1, n + 1):
        t = i / n
        d = (d + Vector((rnd.uniform(-0.18, 0.18), rnd.uniform(-0.18, 0.18), rnd.uniform(-0.06, 0.1)))).normalized()
        co = prev.co + d * (largo / n)
        v = bm.verts.new(co)
        r = r0 + (r1 - r0) * t
        v[capa].radius = (r, r)
        bm.edges.new((prev, v))
        prev = v
        if nivel < 2 and i in (n // 2, n - 1) and rnd.random() < 0.85:
            lado = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), 0)).normalized()
            dd = (d * 0.6 + lado * 0.7 + Vector((0, 0, 0.35))).normalized()
            _ramas(bm, capa, v, dd, largo * 0.55, r * 0.8, max(0.05, r1 * 0.6), nivel + 1, rnd, puntas)
    puntas.append(prev.co.copy())


def _piel(nombre, construir, material, desplaza=0.0):
    me = bpy.data.meshes.new(nombre)
    bm = bmesh.new()
    capa = bm.verts.layers.skin.verify()
    construir(bm, capa)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(nombre, me)
    K.enlazar(ob)
    me.materials.append(material)
    ob.modifiers.new("piel", 'SKIN')
    sub = ob.modifiers.new("suave", 'SUBSURF')
    sub.levels = 2
    sub.render_levels = 2
    if desplaza > 0:
        K.desplazar(ob, desplaza, 0.35, 'CLOUDS', nombre + "_ruido")
    return ob


def _hoja_modelo():
    """Una hoja de roble estilizada (rombo alargado con nervio), lejos de la cámara: solo la usan las partículas."""
    m = M()
    bm = bmesh.new()
    # a lo largo de X: las partículas de pelo orientan su X por la normal, así la hoja sale de la copa
    pts = [(0.0, 0.0), (0.1, 0.09), (0.2, 0.06), (0.3, 0.0), (0.2, -0.06), (0.1, -0.09)]
    vs = [bm.verts.new((x, y, 0.0)) for (x, y) in pts]
    bm.faces.new(vs)
    ob = K._obj("hoja_modelo", bm, m["hoja_roble"])
    ob.location = (-500.0, 0.0, 0.0)
    return ob


def _cubrir_de_hojas(ob, hoja, n, semilla):
    md = ob.modifiers.new("hojas", 'PARTICLE_SYSTEM')
    ps = ob.particle_systems[-1]
    ps.seed = semilla
    s = ps.settings
    s.type = 'HAIR'
    s.count = n
    s.hair_length = 0.3
    s.emit_from = 'FACE'
    s.use_advanced_hair = True
    s.render_type = 'OBJECT'
    s.instance_object = hoja
    s.particle_size = 2.3
    s.size_random = 0.55
    s.use_rotations = True
    s.rotation_mode = 'NOR'
    s.rotation_factor_random = 0.7
    s.phase_factor_random = 2.0
    ob.show_instancer_for_render = True


def arbol():
    """El Árbol Milenario [C]: un roble enorme. Tronco con la base ensanchada, ramas maestras, una copa que sale por
    arriba de la ciudad (el borde del mapa la corta, como si no cupiera) y raíces que levantan el empedrado."""
    m = M()
    rnd = random.Random(1000)
    base = V(40.0, 7.2, 0.0)
    puntas = []

    def tronco(bm, capa):
        v0 = bm.verts.new(base)
        v0[capa].radius = (1.65, 1.65)
        v0[capa].use_root = True
        prev = v0
        for i, (dz, r) in enumerate(((1.2, 1.45), (2.4, 1.25), (3.4, 1.12))):
            v = bm.verts.new(base + Vector((0.08 * i, -0.06 * i, dz)))
            v[capa].radius = (r, r)
            bm.edges.new((prev, v))
            prev = v
        for k in range(6):
            az = math.radians(-60 + k * 52 + rnd.uniform(-12, 12))
            el = math.radians(rnd.uniform(28, 44))
            d = Vector((math.cos(az) * math.cos(el), math.sin(az) * math.cos(el) * 0.8 - 0.25, math.sin(el)))
            _ramas(bm, capa, prev, d.normalized(), rnd.uniform(5.0, 6.8), 0.8, 0.22, 0, rnd, puntas)

    tr = _piel("tronco", tronco, m["corteza"], 0.08)

    def raices(bm, capa):
        for k in range(11):
            az = math.radians(k * 33 + rnd.uniform(-10, 10))
            d = Vector((math.cos(az), math.sin(az) * 0.85, 0.0))
            r0 = rnd.uniform(0.38, 0.55)
            v = bm.verts.new(base + d * 1.25 + Vector((0, 0, 0.42)))
            v[capa].radius = (r0, r0)
            v[capa].use_root = True            # una raíz de la piel por cada isla (cada raíz es una isla)
            prev = v
            largo = rnd.uniform(4.0, 8.5) if d.y < 0.2 else rnd.uniform(3.0, 5.0)
            n = int(largo / 0.6)
            for i in range(1, n + 1):
                t = i / n
                d = (d + Vector((rnd.uniform(-0.25, 0.25), rnd.uniform(-0.25, 0.25), 0))).normalized()
                co = prev.co + d * (largo / n)
                co.z = max(-0.12, 0.42 * (1 - t) ** 1.6 + 0.06 * math.sin(i * 1.7))
                vv = bm.verts.new(co)
                rr = r0 + (0.07 - r0) * t
                vv[capa].radius = (rr, rr * 0.75)
                bm.edges.new((prev, vv))
                prev = vv

    rz = _piel("raices", raices, m["corteza"], 0.04)
    # el tocón de la raíz cortada (nota_oak_anillos) en (45, 10): anillos a la vista
    anillos_img = np.zeros((64, 64, 4), np.float32)
    yy, xx = np.mgrid[0:64, 0:64].astype(np.float32)
    rr = np.hypot(xx - 32, yy - 32)
    anillos_img[rr < 31, 3] = 1.0
    tono = 0.62 + 0.12 * np.sin(rr * 2.2)
    anillos_img[:, :, 0] = tono * 0.78
    anillos_img[:, :, 1] = tono * 0.6
    anillos_img[:, :, 2] = tono * 0.42
    negro = (rr > 7.5) & (rr < 9.5)                 # «uno, muy hondo, es negro como el carbón»
    anillos_img[negro, :3] = [0.07, 0.06, 0.06]
    corte = K.m_imagen(K.imagen("anillos", anillos_img), 0.8, "anillos_mat")
    toc = cilindro((45.0, 10.0, 0.25), 0.42, 0.5, m["corteza"], 20, "tocon")
    tapa = bpy.data.meshes.new("tocon_tapa")
    bmt = bmesh.new()
    r_ = bmesh.ops.create_circle(bmt, cap_ends=True, segments=20, radius=0.4)
    uv = bmt.loops.layers.uv.new()
    for f in bmt.faces:
        for lp in f.loops:
            lp[uv].uv = (lp.vert.co.x / 0.8 + 0.5, lp.vert.co.y / 0.8 + 0.5)
    bmt.to_mesh(tapa)
    bmt.free()
    tapa_ob = bpy.data.objects.new("tocon_tapa", tapa)
    K.enlazar(tapa_ob)
    tapa.materials.append(corte)
    tapa_ob.location = V(45.0, 10.0, 0.505)
    # la copa: bultos de hojas en las puntas de las ramas, cada uno cubierto de hojas sueltas (miles de hojas
    # pequeñas, cada una de un verde: así la copa tiene borde de hojas y no de bola)
    hoja = _hoja_modelo()
    copa = []
    vistas = set()
    for i, pt in enumerate(puntas):
        clave = (round(pt.x), round(pt.y), round(pt.z))
        if clave in vistas:
            continue
        vistas.add(clave)
        for k in range(4):
            c = pt + Vector((rnd.uniform(-1.3, 1.3), rnd.uniform(-1.3, 1.3), rnd.uniform(-0.4, 1.0)))
            r = rnd.uniform(1.0, 1.7)
            b = esfera((c.x, -c.y, c.z), r, m["hojas_dentro"], "hojas", 3, (1.0, 0.92, 0.85))
            K.desplazar(b, 0.45, 0.8, 'CLOUDS', "hojas_%d_%d" % (i, k))
            _cubrir_de_hojas(b, hoja, int(1700 * r * r), i * 7 + k)
            copa.append(b)    # farolillos colgados de las ramas bajas (la ciudadela de los faroles)
    farolillos = []
    anclas = {}
    for k, (x, y, z) in enumerate(((36.2, 9.6, 3.7), (43.6, 9.9, 3.9), (39.4, 10.6, 4.3))):
        farolillos.append(viga((x, y, z + 0.9), (x, y, z + 0.2), 0.012, m["hierro_negro"], 0.012, "cuerda"))
        farolillos.append(cilindro((x, y, z), 0.14, 0.32, m["farol"], 10, "farolillo"))
        farolillos.append(cilindro((x, y, z + 0.2), 0.16, 0.06, m["hierro_negro"], 10, "farolillo_tapa"))
        K.luz_punto((x, y, z - 0.05), K.FAROL, 22.0, 0.08, "farolillo_luz")
        anclas["farolillo_%d" % (k + 1)] = (x, y, z)
    # el reflejo cálido de la ciudad en la panza de la copa (los faroles de abajo)
    K.luz_area((40.0, 9.5, 2.2), (14.0, 6.0), K.hexlin("#FFB060"), 2600.0, "reflejo_ciudad", hacia=(0.0, 0.0, 1.0))
    anclas.update({"tronco": (40.0, 9.0, 0.0), "luciernagas": (40.0, 10.8, 0.6), "cofre_raices": (43.0, 3.5, 0.5),
                   "anillos": (45.0, 10.0, 0.5), "encina": (35.0, 10.0, 0.0)})
    return {
        "rect": (38, 5, 4, 4),
        "capas": [
            {"nombre": "raices", "objetos": [rz, toc, tapa_ob], "orden": None, "tipo": "objeto", "escala": 2},
            {"nombre": "cuerpo", "objetos": [tr] + farolillos, "orden": 9.0, "tipo": "edificio"},
            {"nombre": "copa", "objetos": copa, "orden": 9.02, "tipo": "edificio", "viento": 1.0},
        ],
        "suelo": True,
        "recorte_arriba": 0,
        "anclas": anclas,
        "efectos": [
            {"tipo": "luciernagas", "ancla": "luciernagas", "caja": [16.0, 5.0], "cantidad": 14},
            {"tipo": "halo", "ancla": "farolillo_1", "radio": 0.9, "fuerza": 0.45},
            {"tipo": "halo", "ancla": "farolillo_2", "radio": 0.9, "fuerza": 0.45},
            {"tipo": "halo", "ancla": "farolillo_3", "radio": 0.9, "fuerza": 0.45},
            {"tipo": "brillo", "ancla": "cofre_raices", "radio": 0.45, "fuerza": 0.9, "color": "oro",
             "estado_no": "cofre_raices_abierto", "delante": 4.0},
        ],
        "margen_suelo": (120, 20, 140, 120),
    }


# ================================================================= Casa del Concejo y su pórtico

def concejo():
    """Casa del Concejo: sillería, dos plantas con ventanas en arco, pizarra, un hastial central con el óculo y el
    roble de la ciudad, y el pórtico de columnas hacia la plaza con el tapiz de los reyes (detalle oak_tapiz)."""
    m = M()
    X0, X1, YN, YS = 43.0, 52.0, 16.0, 21.0
    Z1, Z2 = 3.4, 6.2
    cuerpo = []
    huecos = [(43.7, 44.6, 1.0, 2.6), (50.4, 51.3, 1.0, 2.6), (46.2, 47.8, 0.0, 2.7), (48.4, 49.3, 1.0, 2.6)]
    cuerpo += K.fachada(X0, X1, YS, 0.0, Z1, 0.35, m["piedra"], huecos, "conc_pb")
    huecos2 = [(43.8, 44.6, 4.0, 5.5), (45.2, 46.0, 4.0, 5.5), (47.1, 47.9, 4.0, 5.5), (49.0, 49.8, 4.0, 5.5), (50.4, 51.2, 4.0, 5.5)]
    cuerpo += K.fachada(X0, X1, YS, Z1, Z2, 0.35, m["piedra"], huecos2, "conc_pa")
    cuerpo.append(caja(X0, YN, 0.0, X1, YS - 0.35, Z2, m["piedra"], "conc_dentro"))
    cuerpo.append(caja(X0 - 0.1, YS - 0.3, Z1 - 0.12, X1 + 0.1, YS + 0.12, Z1 + 0.12, m["piedra_gris"], "conc_imposta", 0.02))
    cuerpo.append(caja(X0 - 0.15, YS - 0.3, Z2 - 0.25, X1 + 0.15, YS + 0.2, Z2, m["piedra_gris"], "conc_cornisa", 0.03))
    for (a, b, za, zb) in huecos + huecos2:
        if b - a < 1.2:
            cuerpo += K.ventana((a + b) * 0.5, YS, za, b - a, zb - za, m["viga"], m["ventana_alta"] if za > 3 else m["ventana"],
                                None, None, True, 0.22, "conc_v", luz=(K.CALIDA, 9.0 if za > 3 else 14.0))
            cuerpo.append(K.semicirculo((a + b) * 0.5, YS + 0.012, zb, (b - a) * 0.5, 0.01, m["ventana_alta"] if za > 3 else m["ventana"], "conc_arco"))
            cuerpo.append(K.semicirculo((a + b) * 0.5, YS + 0.006, zb, (b - a) * 0.5 + 0.1, 0.01, m["piedra_gris"], "conc_arco_marco"))
    cuerpo += K.puerta(47.0, YS, 1.6, 2.7, m["puerta"], m["hierro"], m["piedra_gris"], 0.0, None, 0.3, nombre="conc_puerta")
    cuerpo.append(K.semicirculo(47.0, YS + 0.012, 2.7, 0.8, 0.01, m["puerta"], "conc_arco_puerta"))
    cuerpo.append(K.semicirculo(47.0, YS + 0.006, 2.7, 0.96, 0.01, m["piedra_gris"], "conc_arco_puerta_marco"))
    # el tapiz de los reyes, en el muro del fondo del pórtico, a la izquierda de la puerta
    tapiz = K.m_imagen(K.imagen("tapiz", _textura_tapiz()), 0.95, "tapiz_mat")
    cuerpo.append(K.plano_imagen(44.85, 46.0, 0.7, 2.42, YS + 0.03, tapiz, "tapiz"))
    cuerpo.append(cilindro((45.42, YS + 0.06, 2.48), 0.025, 1.35, m["hierro_negro"], 8, "tapiz_vara", eje='X'))
    # hastial central con óculo y el roble de la ciudad
    GX0, GX1 = 45.6, 48.4
    cuerpo.append(K.hastial_muro(GX0, GX1, YS, Z2, 2.1, m["piedra"], 0.4, "conc_hastial"))
    cuerpo.append(cilindro((47.0, YS + 0.09, Z2 + 0.85), 0.4, 0.02, m["ventana_alta"], 20, "conc_oculo", eje='Y'))
    cuerpo.append(cilindro((47.0, YS + 0.05, Z2 + 0.85), 0.52, 0.05, m["piedra_gris"], 20, "conc_oculo_marco", eje='Y'))
    K.luz_punto((47.0, YS + 0.4, Z2 + 0.85), K.CALIDA, 6.0, 0.1, "oculo_luz")
    cuerpo += K.tejado_frontal(GX0, GX1, YS + 0.05, 17.4, Z2, 2.1, m["pizarra"], 0.3, "conc_tej_hastial")
    cuerpo += K.tejado_dos_aguas(X0, X1, YS, YN, Z2, 2.4, m["pizarra"], 0.35, 0.3, m["hierro_negro"], "conc_tejado")
    chim, humo = K.chimenea(44.2, 17.2, 6.0, 3.0, 0.55, m["piedra"], nombre="conc_chimenea")
    cuerpo += chim
    # estandartes a los lados de la puerta
    for bx in (45.95, 48.05):
        cuerpo.append(viga((bx, YS, 3.15), (bx, YS + 0.45, 3.15), 0.04, m["hierro_negro"], 0.04, "asta"))
        cuerpo.append(caja(bx - 0.3, YS + 0.38, 1.85, bx + 0.3, YS + 0.42, 3.1, m["tela_azul"], "estandarte"))
        cuerpo.append(caja(bx - 0.1, YS + 0.43, 2.35, bx + 0.1, YS + 0.45, 2.75, m["oro"], "estandarte_roble"))
    # pórtico: columnas y tejadillo sobre la franja pisable (y 21-23)
    portico = []
    YP = 22.85
    for cx in (43.35, 45.25, 47.0, 48.75, 50.65, 51.65):
        portico.append(cilindro((cx, YP, 1.45), 0.19, 2.9, m["hueso"], 16, "columna", r_arriba=0.16, bisel=0.0))
        portico.append(caja(cx - 0.27, YP - 0.27, 0.0, cx + 0.27, YP + 0.27, 0.22, m["piedra_gris"], "basa", 0.02))
        portico.append(caja(cx - 0.26, YP - 0.26, 2.9, cx + 0.26, YP + 0.26, 3.08, m["piedra_gris"], "capitel", 0.02))
    portico.append(caja(43.0, YP - 0.3, 3.08, 52.0, YP + 0.3, 3.42, m["piedra"], "arquitrabe", 0.02))
    portico += K.faldon(42.9, 52.1, YP + 0.42, 3.38, YS - 0.05, 4.1, m["pizarra"], 0.24, 0.05, "portico_tejado")
    farol_a, ancla_a = farol_colgado(46.12, 22.55, 2.5, m, "portico_farol_1")       # entre columnas
    farol_b, ancla_b = farol_colgado(49.7, 22.55, 2.5, m, "portico_farol_2")
    portico += farol_a + farol_b
    return {
        "rect": (43, 16, 9, 5),
        "capas": [
            {"nombre": "cuerpo", "objetos": cuerpo, "orden": YS, "tipo": "edificio"},
            {"nombre": "portico", "objetos": portico, "orden": YP + 0.2, "tipo": "edificio"},
        ],
        "suelo": True,
        "anclas": {"humo": humo, "puerta": (47.0, 21.6, 0.0), "tapiz": (45.5, 21.1, 1.6), "farol_portico_1": ancla_a,
                   "farol_portico_2": ancla_b},
        "efectos": [{"tipo": "humo", "ancla": "humo", "color": "calido", "alto": 2.6, "escala": 0.8},
                    {"tipo": "halo", "ancla": "farol_portico_1", "radio": 1.1, "fuerza": 0.45},
                    {"tipo": "halo", "ancla": "farol_portico_2", "radio": 1.1, "fuerza": 0.45}],
        "choques": [{"centro": [cx, YP], "tam": [0.5, 0.5]} for cx in (43.35, 45.25, 47.0, 48.75, 50.65, 51.65)],
        "margen_suelo": (140, 24, 160, 150),
    }


def farol_colgado(x, y, z, m, nombre="farol_colgado", potencia=30.0):
    p = [viga((x, y, z + 0.75), (x, y, z + 0.28), 0.015, m["hierro_negro"], 0.015, nombre + "_cadena")]
    p.append(caja(x - 0.12, y - 0.12, z - 0.16, x + 0.12, y + 0.12, z + 0.16, m["farol"], nombre + "_vidrio"))
    p.append(cilindro((x, y, z + 0.24), 0.18, 0.12, m["hierro_negro"], 4, nombre + "_tejadillo", r_arriba=0.03))
    p.append(caja(x - 0.14, y - 0.14, z - 0.22, x + 0.14, y + 0.14, z - 0.16, m["hierro_negro"], nombre + "_base"))
    K.luz_punto((x, y + 0.02, z), K.FAROL, potencia, 0.06, nombre + "_luz")
    return p, (x, y, z)


# ================================================================= Torre de la Campana

def torre():
    """Torre de la Campana: fuste de sillería, campanario abierto con la campana de bronce, chapitel de pizarra con
    veleta, puerta al pie con farol (pieza oak_torre) y saeteras."""
    m = M()
    X0, X1, YN, YS = 72.0, 76.0, 38.0, 42.0
    ZF, ZC = 8.0, 10.6
    p = []
    huecos = [(73.45, 74.55, 0.0, 2.3), (73.75, 74.25, 4.0, 5.1), (73.75, 74.25, 6.2, 7.2)]
    p += K.fachada(X0, X1, YS, 0.0, ZF, 0.5, m["piedra"], huecos, "torre_fuste")
    p.append(caja(X0, YN, 0.0, X1, YS - 0.5, ZF, m["piedra"], "torre_dentro"))
    p.append(caja(X0 - 0.15, YS - 0.4, 0.0, X1 + 0.15, YS + 0.15, 0.6, m["zocalo"], "torre_zocalo", 0.03))
    for zz in (ZF - 0.25, 3.3):
        p.append(caja(X0 - 0.12, YS - 0.4, zz, X1 + 0.12, YS + 0.14, zz + 0.25, m["piedra_gris"], "torre_imposta", 0.02))
    for (a, b, za, zb) in huecos[1:]:
        p.append(caja(a, YS - 0.42, za, b, YS - 0.4, zb, m["ventana_alta"], "saetera"))
        K.luz_punto(((a + b) * 0.5, YS + 0.2, (za + zb) * 0.5), K.CALIDA, 2.5, 0.05, "saetera_luz")
    p += K.puerta(74.0, YS, 1.1, 2.3, m["puerta"], m["hierro"], m["piedra_gris"], 0.0, None, 0.35, nombre="torre_puerta")
    p.append(K.semicirculo(74.0, YS + 0.012, 2.3, 0.55, 0.01, m["puerta"], "torre_arco"))
    p.append(K.semicirculo(74.0, YS + 0.006, 2.3, 0.7, 0.01, m["piedra_gris"], "torre_arco_marco"))
    fa, ancla_f = _farol_de_pared(72.95, YS, 2.0, m)
    p += fa
    # campanario: cuatro pilares y la campana
    for (px_, py_) in ((X0 + 0.3, YS - 0.3), (X1 - 0.3, YS - 0.3), (X0 + 0.3, YN + 0.3), (X1 - 0.3, YN + 0.3)):
        p.append(caja(px_ - 0.3, py_ - 0.3, ZF, px_ + 0.3, py_ + 0.3, ZC, m["piedra"], "pilar", 0.02))
    p.append(caja(X0 - 0.1, YN - 0.1, ZF, X1 + 0.1, YS + 0.1, ZF + 0.3, m["piedra_gris"], "suelo_campanario", 0.02))
    p.append(caja(X0 + 0.25, YS - 0.35, ZF + 0.3, X1 - 0.25, YS - 0.25, ZF + 0.55, m["piedra"], "antepecho"))
    p.append(caja(X0 - 0.12, YN - 0.12, ZC, X1 + 0.12, YS + 0.12, ZC + 0.3, m["piedra_gris"], "cornisa_campanario", 0.02))
    camp = cilindro((74.0, 40.6, ZF + 1.45), 0.75, 1.3, m["bronce"], 24, "campana", r_arriba=0.42)
    p.append(camp)
    p.append(esfera((74.0, 40.6, ZF + 2.1), 0.22, m["bronce"], "campana_corona", 2))
    p.append(caja(72.5, 39.9, ZF + 2.15, 75.5, 40.1, ZF + 2.3, m["viga"], "yugo"))
    K.luz_punto((74.0, 40.6, ZF + 0.6), K.CALIDA, 14.0, 0.2, "campanario_luz")
    # chapitel de pizarra (pirámide) y veleta
    bm = bmesh.new()
    vs = [bm.verts.new(V(X0 - 0.35, YN - 0.35, ZC + 0.3)), bm.verts.new(V(X1 + 0.35, YN - 0.35, ZC + 0.3)),
          bm.verts.new(V(X1 + 0.35, YS + 0.35, ZC + 0.3)), bm.verts.new(V(X0 - 0.35, YS + 0.35, ZC + 0.3)),
          bm.verts.new(V(74.0, 40.0, ZC + 3.4))]
    for f in ((0, 1, 4), (1, 2, 4), (2, 3, 4), (3, 0, 4), (3, 2, 1, 0)):
        bm.faces.new([vs[i] for i in f])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    chapitel = K._obj("chapitel", bm, m["pizarra"])
    p.append(chapitel)
    # hileras de pizarra en la cara sur del chapitel (las que se ven)
    for i in range(10):
        t = i / 10.0
        zz = ZC + 0.32 + t * 3.0
        semi = (2.35) * (1 - t * 0.98)
        ys = 40.0 + semi
        p.append(viga((74.0 - semi, ys + 0.03, zz), (74.0 + semi, ys + 0.03, zz), 0.07, m["pizarra"], 0.05, "hilera"))
    p.append(cilindro((74.0, 40.0, ZC + 3.9), 0.03, 1.1, m["hierro_negro"], 8, "veleta_vara"))
    gallo = K.poligono_extruido([(0.0, 0.0), (0.3, 0.05), (0.42, 0.25), (0.3, 0.32), (0.22, 0.2), (0.0, 0.18), (-0.3, 0.3), (-0.22, 0.05)],
                                0.02, m["hierro_negro"], "veleta")
    gallo.location = V(74.0, 40.0, ZC + 4.25)
    p.append(gallo)
    return {
        "rect": (72, 38, 4, 4),
        "capas": [{"nombre": "cuerpo", "objetos": p, "orden": YS, "tipo": "edificio"}],
        "suelo": True,
        "anclas": {"puerta": (74.0, 42.6, 0.0), "farol_puerta": ancla_f, "campana": (74.0, 40.0, ZF + 1.4)},
        "efectos": [{"tipo": "halo", "ancla": "farol_puerta", "radio": 1.2, "fuerza": 0.5},
                    {"tipo": "halo", "ancla": "campana", "radio": 1.6, "fuerza": 0.22, "parpadeo": 0.3}],
        "margen_suelo": (130, 24, 150, 150),
    }


def _farol_de_pared(x, y, z, m):
    import piezas as P
    return P._farol_pared(x, y, z, m, "farol_torre", 35.0)


# ================================================================= Ronda de la muralla este

def ronda():
    """Ronda de la muralla este (en alto: solo se llega desde la torre). El adarve se ve justo sobre su franja de
    casillas (76-78) con el parapeto almenado al este; el muro baja por el sur. Tres faroles apagados en el
    parapeto (oak_farol_1..3): encendidos son una capa aparte (estado «farol_n»)."""
    m = M()
    H = 3.2                                    # altura del adarve
    # el adarve está en alto: para que se vea sobre su franja (y 28-42), su planta va H casillas más al sur
    def y_(y):
        return y + H * K.K
    p = []
    p.append(caja(76.0, y_(28.0), 0.0, 79.0, y_(42.0), H, m["piedra_gris"], "muro", 0.02))
    p.append(caja(76.0, y_(28.0), H - 0.02, 78.0, y_(42.0), H + 0.04, m["piedra"], "adarve", 0.01))
    # parapeto almenado al este (x 78-79) y pretil bajo al oeste
    p.append(caja(78.0, y_(28.0), H, 79.0, y_(42.0), H + 0.75, m["piedra"], "parapeto", 0.02))
    yy = 28.3
    while yy < 41.8:
        p.append(caja(78.05, y_(yy), H + 0.75, 78.95, y_(yy + 0.7), H + 1.3, m["piedra"], "almena", 0.02))
        yy += 1.4
    p.append(caja(75.85, y_(28.0), H, 76.15, y_(42.0), H + 0.45, m["piedra_gris"], "pretil", 0.02))
    # remate sur: el muro baja hasta el suelo (se ve su cara sur)
    p.append(caja(75.8, y_(41.6), 0.0, 79.2, y_(42.25), H + 0.2, m["piedra_gris"], "muro_sur", 0.02))
    for k, yv in enumerate((31.5, 34.5, 38.5)):
        p.append(caja(78.25, y_(yv) - 0.15, H + 0.75, 78.45, y_(yv) + 0.15, H + 2.0, m["hierro_negro"], "farol_mastil_%d" % (k + 1)))
    apagados = []
    encendidos = []
    anclas = {}
    for k, yv in enumerate((31.5, 34.5, 38.5)):
        x, yb, z = 78.35, y_(yv), H + 2.15
        partes_off = [caja(x - 0.16, yb - 0.16, z - 0.2, x + 0.16, yb + 0.16, z + 0.18, m["farol_apagado"], "farol_off"),
                      cilindro((x, yb, z + 0.27), 0.22, 0.13, m["hierro_negro"], 4, "farol_tejadillo", r_arriba=0.03)]
        apagados.append(partes_off)
        partes_on = [caja(x - 0.16, yb - 0.16, z - 0.2, x + 0.16, yb + 0.16, z + 0.18, m["farol"], "farol_on")]
        encendidos.append(partes_on)
        anclas["farol_%d" % (k + 1)] = (x, yb, z)
    cuerpo = p + [o for g in apagados for o in g]
    # ordena con su borde de arriba (como el suelo): quien sube a la ronda (y 28-42) se dibuja encima del adarve. A
    # pie de calle no hay nada que tapar: al oeste la huella de la torre y casas, al este el borde del mapa.
    capas = [{"nombre": "cuerpo", "objetos": cuerpo, "orden": 28.0, "tipo": "objeto"}]
    for k in range(3):
        capas.append({"nombre": "farol_%d_on" % (k + 1), "objetos": encendidos[k], "orden": 28.02, "tipo": "objeto",
                      "estado": "farol_%d" % (k + 1)})
    anclas.update({"subida": (76.5, 41.5, 0.0), "cofre": (76.5, 28.5, 0.0)})
    efectos = [{"tipo": "halo", "ancla": "farol_%d" % (k + 1), "radio": 1.4, "fuerza": 0.55, "estado": "farol_%d" % (k + 1),
                "delante": 6.0} for k in range(3)]
    return {
        "rect": (76, 28, 2, 14),
        "capas": capas,
        "suelo": True,
        "anclas": anclas,
        "efectos": efectos,
        "margen_suelo": (120, 24, 120, 100),
    }


# ================================================================= Mercado

def _puesto(x0, x1, y_fondo, y_frente, tela, m, rnd, nombre):
    p = []
    zt = 2.35
    for (px_, py_) in ((x0 + 0.1, y_frente - 0.1), (x1 - 0.1, y_frente - 0.1), (x0 + 0.1, y_fondo + 0.1), (x1 - 0.1, y_fondo + 0.1)):
        p.append(caja(px_ - 0.06, py_ - 0.06, 0.0, px_ + 0.06, py_ + 0.06, zt + (0.35 if py_ < y_frente - 0.5 else 0.0), m["madera_clara"], nombre + "_poste"))
    # mostrador
    p.append(caja(x0 + 0.05, y_frente - 0.75, 0.0, x1 - 0.05, y_frente - 0.05, 0.85, m["madera_clara"], nombre + "_mostrador", 0.02))
    # toldo a rayas (inclinado hacia la calle)
    p += K.faldon(x0 - 0.15, x1 + 0.15, y_frente + 0.45, zt - 0.1, y_fondo, zt + 0.35, tela, 0.5, 0.03, nombre + "_toldo", 1.02)
    # género: cestas y frutas
    n = int((x1 - x0) / 0.55)
    for i in range(n):
        cx = x0 + 0.35 + i * (x1 - x0 - 0.7) / max(1, n - 1)
        p.append(cilindro((cx, y_frente - 0.4, 0.95), 0.22, 0.2, m["cesta"], 12, nombre + "_cesta"))
        cosa = rnd.choice(["manzana", "col", "pan", "calabaza", "lavanda"])
        for k in range(5):
            p.append(esfera((cx + rnd.uniform(-0.12, 0.12), y_frente - 0.4 + rnd.uniform(-0.1, 0.1), 1.08 + rnd.uniform(0, 0.08)),
                            0.07 if cosa != "calabaza" else 0.11, m[cosa], nombre + "_genero", 2))
    # cajas y sacos a los lados
    p.append(caja(x1 - 0.05, y_frente - 0.6, 0.0, x1 + 0.55, y_frente - 0.05, 0.45, m["madera_clara"], nombre + "_caja", 0.02))
    p.append(esfera((x0 - 0.3, y_frente - 0.3, 0.3), 0.32, m["saco"], nombre + "_saco", 2, (1, 1, 1.15)))
    return p


def mercado():
    """El mercado: tres puestos con toldos a rayas, género en cestas, cajas y sacos, y una guirnalda de farolillos."""
    m = M()
    rnd = random.Random(5)
    puestos = []
    telas = [m["tela_roja"], m["tela_verde"], m["tela_ocre"]]
    tramos = [(48.6, 51.6), (52.9, 55.9), (57.2, 59.9)]
    capas = []
    anclas = {}
    for i, (a, b) in enumerate(tramos):
        partes = _puesto(a, b, 27.15, 28.9, telas[i], m, rnd, "puesto%d" % i)
        capas.append({"nombre": "puesto_%d" % (i + 1), "objetos": partes, "orden": 28.95, "tipo": "objeto"})
    # guirnalda de farolillos entre los puestos (cuelga a 2,7 m)
    guirnalda = []
    pts = [(48.6, 28.8, 2.6), (51.6, 28.8, 2.6), (52.9, 28.8, 2.6), (55.9, 28.8, 2.6), (57.2, 28.8, 2.6), (59.9, 28.8, 2.6)]
    for (x0, y0, z0), (x1, y1, z1) in zip(pts[:-1], pts[1:]):
        nseg = 6
        prev = (x0, y0, z0)
        for k in range(1, nseg + 1):
            t = k / nseg
            pt = (x0 + (x1 - x0) * t, y0, z0 - 0.35 * math.sin(math.pi * t))
            guirnalda.append(viga(prev, pt, 0.012, m["hierro_negro"], 0.012, "cuerda"))
            if k < nseg and k % 2 == 1:
                guirnalda.append(esfera(pt, 0.07, m["farol"], "bombilla", 2))
                K.luz_punto((pt[0], pt[1] + 0.05, pt[2] - 0.1), K.FAROL, 3.0, 0.05, "bombilla_luz")
            prev = pt
    capas.append({"nombre": "guirnalda", "objetos": guirnalda, "orden": 29.0, "tipo": "objeto"})
    anclas["tienda"] = (54.0, 30.0, 0.0)
    return {
        "rect": (48, 27, 12, 5),
        "capas": capas,
        "suelo": True,
        "anclas": anclas,
        "efectos": [],
        "choques": [{"centro": [(a + b) * 0.5, 28.0], "tam": [b - a + 0.4, 1.8]} for (a, b) in tramos],
        "margen_suelo": (90, 20, 110, 90),
    }


# ================================================================= Plaza del Tapiz: fuente, tablón y puesto de flores

def plaza():
    m = M()
    rnd = random.Random(21)
    capas = []
    # la fuente (centro 40, 26): pilón octogonal, agua, columna con la bellota y el roble
    f = []
    f.append(cilindro((40.0, 26.0, 0.25), 1.7, 0.5, m["piedra_gris"], 8, "pilon", bisel=0.03))
    f.append(cilindro((40.0, 26.0, 0.55), 1.78, 0.14, m["piedra"], 8, "pilon_borde", bisel=0.02))
    f.append(cilindro((40.0, 26.0, 0.64), 1.56, 0.04, m["agua"], 24, "agua"))      # llena hasta el borde: se ve
    f.append(cilindro((40.0, 26.0, 1.1), 0.25, 1.4, m["piedra"], 12, "columna", bisel=0.02))
    f.append(cilindro((40.0, 26.0, 1.85), 0.62, 0.14, m["piedra_gris"], 12, "taza", bisel=0.03))
    f.append(esfera((40.0, 26.0, 2.25), 0.3, m["bronce"], "bellota", 3, (1, 1, 1.25)))
    f.append(cilindro((40.0, 26.0, 2.55), 0.32, 0.14, m["bronce"], 14, "cupula_bellota"))
    for k in range(4):
        a = k * math.pi * 0.5 + math.pi * 0.25
        f.append(viga((40.0 + math.cos(a) * 0.5, 26.0 + math.sin(a) * 0.5, 1.8), (40.0 + math.cos(a) * 1.0, 26.0 + math.sin(a) * 1.0, 0.6),
                      0.03, m["agua"], 0.03, "chorro"))
    capas.append({"nombre": "fuente", "objetos": f, "orden": 27.2, "tipo": "objeto"})
    # tablón de anuncios (nota_oak_bando en 36, 29)
    t = []
    for dx in (-0.65, 0.65):
        t.append(caja(36.0 + dx - 0.07, 28.75, 0.0, 36.0 + dx + 0.07, 28.89, 2.1, m["viga"], "tablon_poste"))
    t.append(caja(35.3, 28.8, 0.9, 36.7, 28.86, 1.95, m["madera_clara"], "tablon", 0.01))
    t += K.faldon(35.15, 36.85, 29.1, 2.05, 28.55, 2.3, m["teja"], 0.18, 0.04, "tablon_tejadillo")
    for (px_, pz, w, h) in ((35.55, 1.6, 0.34, 0.26), (36.0, 1.45, 0.38, 0.4), (36.45, 1.62, 0.3, 0.24), (35.7, 1.1, 0.3, 0.3), (36.35, 1.05, 0.34, 0.28)):
        t.append(caja(px_ - w * 0.5, 28.86, pz - h * 0.5, px_ + w * 0.5, 28.88, pz + h * 0.5, m["papel"], "anuncio"))
    capas.append({"nombre": "tablon", "objetos": t, "orden": 28.95, "tipo": "objeto"})
    # puesto de flores de Rosa (ella está en 44, 29): carretilla con cubos de flores detrás
    fl = []
    fl.append(caja(43.2, 27.75, 0.35, 44.8, 28.45, 0.75, m["madera_clara"], "carro", 0.02))
    for wx in (43.35, 44.65):
        fl.append(cilindro((wx, 28.5, 0.35), 0.35, 0.08, m["viga"], 16, "rueda", eje='X'))
    for i, col in enumerate(("geranio", "amarilla", "lavanda", "blanca", "rosa")):
        cx = 43.45 + i * 0.32
        fl.append(cilindro((cx, 28.1, 0.95), 0.13, 0.4, m["hierro"], 12, "cubo"))
        for k in range(6):
            fl.append(esfera((cx + rnd.uniform(-0.1, 0.1), 28.1 + rnd.uniform(-0.1, 0.1), 1.2 + rnd.uniform(0, 0.15)), 0.06, m[col], "flor", 2))
    fl.append(viga((43.2, 28.1, 0.6), (42.6, 28.4, 0.75), 0.05, m["viga"], 0.05, "varal"))
    capas.append({"nombre": "flores", "objetos": fl, "orden": 28.6, "tipo": "objeto"})
    return {
        "rect": (35, 21, 11, 10),
        "capas": capas,
        "suelo": True,
        "anclas": {"fuente": (40.0, 26.0, 2.3), "tablon": (36.0, 28.9, 1.4), "flores": (44.0, 28.1, 1.0)},
        "efectos": [],
        "choques": [{"centro": [40.0, 26.0], "tam": [3.4, 3.0]}, {"centro": [36.0, 28.8], "tam": [1.5, 0.3]},
                    {"centro": [44.0, 28.1], "tam": [1.7, 0.8]}],
        "margen_suelo": (60, 20, 60, 60),
    }


# ================================================================= barriles del patio del Cuervo

def patio_cuervo():
    m = M()
    p = []
    for (x, y, z, tumb) in ((10.9, 28.0, 0.0, False), (11.7, 28.0, 0.0, False), (11.3, 28.0, 0.9, False), (13.6, 28.2, 0.0, True),
                            (12.2, 29.0, 0.0, False)):
        p += K.barril((x, y, z), m["madera_clara"], m["hierro_negro"], 0.9, 0.34, "barril", tumb)
    p.append(caja(13.0, 29.6, 0.0, 14.2, 30.5, 0.6, m["madera_clara"], "caja", 0.02))
    p.append(caja(13.2, 29.75, 0.6, 14.0, 30.35, 1.05, m["madera_clara"], "caja2", 0.02))
    p.append(esfera((10.8, 30.2, 0.32), 0.34, m["saco"], "saco", 2, (1, 1, 1.1)))
    return {
        "rect": (10, 27, 5, 4),
        "capas": [{"nombre": "barriles", "objetos": p, "orden": 30.6, "tipo": "objeto"}],
        "suelo": True,
        "anclas": {"barril": (12.0, 29.0, 0.9)},
        "efectos": [],
        "choques": [{"centro": [11.3, 28.0], "tam": [1.6, 0.8]}, {"centro": [13.6, 28.2], "tam": [1.0, 0.8]},
                    {"centro": [12.2, 29.0], "tam": [0.8, 0.8]}, {"centro": [13.6, 30.05], "tam": [1.2, 0.9]}],
        "margen_suelo": (40, 20, 60, 50),
    }


# ================================================================= la grieta del callejón

def grieta():
    """El muro del fondo del callejón con la grieta (pieza oak_grieta): de lejos solo se ve luz de velas por la raja."""
    m = M()
    p = []
    YS = 36.0
    p += K.fachada(20.0, 27.0, YS, 0.0, 3.1, 0.6, m["piedra"], [(23.3, 23.7, 0.0, 2.2)], "muro_grieta")
    p.append(caja(23.38, YS - 0.9, 0.0, 23.62, YS - 0.6, 2.1, m["llama"], "grieta_luz"))
    K.luz_punto((23.5, YS - 0.15, 0.9), K.hexlin("#FFB060"), 14.0, 0.05, "grieta_vela")
    # hiedra por el muro
    rnd = random.Random(4)
    for k in range(26):
        x = rnd.uniform(20.2, 26.8)
        if 23.1 < x < 23.9:
            continue
        p.append(esfera((x, YS + 0.05, rnd.uniform(1.6, 3.1)), rnd.uniform(0.14, 0.28), m["seto"], "hiedra", 2))
    p.append(caja(19.9, YS - 0.65, 3.1, 27.1, YS + 0.08, 3.28, m["piedra_gris"], "albardilla", 0.02))
    return {
        "rect": (23, 35, 1, 1),
        "capas": [{"nombre": "cuerpo", "objetos": p, "orden": YS, "tipo": "edificio"}],
        "suelo": True,
        "anclas": {"grieta": (23.5, 35.5, 0.0), "luz": (23.5, YS, 1.1)},
        "efectos": [{"tipo": "halo", "ancla": "luz", "radio": 0.8, "fuerza": 0.5, "color": "vela"}],
        "margen_suelo": (40, 20, 40, 60),
    }


# ================================================================= Patio de las Velas

def patio_velas():
    """Patio de las Velas (rincón escondido): un altar pequeño con el anillo partido grabado y velas recién
    encendidas (nota_oak_velas), flores secas y hiedra. Solo luz de velas."""
    m = M()
    rnd = random.Random(9)
    p = []
    ax, ay = 25.5, 37.6
    p.append(caja(ax - 0.75, ay - 0.45, 0.0, ax + 0.75, ay + 0.45, 0.9, m["piedra"], "altar", 0.03))
    p.append(caja(ax - 0.85, ay - 0.52, 0.9, ax + 0.85, ay + 0.52, 1.02, m["piedra_gris"], "altar_losa", 0.02))
    anillo = cilindro((ax, ay + 0.46, 0.5), 0.24, 0.03, m["oro"], 24, "anillo", eje='Y')
    hueco = cilindro((ax, ay + 0.46, 0.5), 0.17, 0.1, m["oro"], 24, "anillo_hueco", eje='Y')
    b = anillo.modifiers.new("hueco", 'BOOLEAN')
    b.operation = 'DIFFERENCE'
    b.object = hueco
    hueco.hide_render = True
    corte = caja(ax + 0.08, ay + 0.38, 0.6, ax + 0.2, ay + 0.55, 0.78, m["oro"], "anillo_corte")
    b2 = anillo.modifiers.new("corte", 'BOOLEAN')
    b2.operation = 'DIFFERENCE'
    b2.object = corte
    corte.hide_render = True
    p.append(anillo)
    anclas = {}
    velas = [(ax - 0.6, ay - 0.2, 1.02), (ax - 0.35, ay + 0.25, 1.02), (ax + 0.1, ay - 0.3, 1.02), (ax + 0.45, ay + 0.2, 1.02),
             (ax + 0.65, ay - 0.15, 1.02), (ax - 1.0, ay + 0.6, 0.0), (ax + 1.05, ay + 0.55, 0.0), (ax - 1.25, ay + 0.15, 0.0),
             (ax + 1.3, ay - 0.1, 0.0)]
    for k, (x, y, z) in enumerate(velas):
        h = rnd.uniform(0.15, 0.32)
        p.append(cilindro((x, y, z + h * 0.5), 0.045, h, m["cera"], 10, "vela"))
        p.append(esfera((x, y, z + h + 0.05), 0.03, m["llama"], "llama", 2, (1, 1, 1.8)))
        K.luz_punto((x, y + 0.05, z + h + 0.1), K.hexlin("#FFB060"), 4.0, 0.03, "vela_luz")
    anclas["velas"] = (ax, ay + 0.2, 1.2)
    anclas["velas_suelo"] = (ax, ay + 0.6, 0.2)
    for k in range(10):
        p.append(esfera((ax + rnd.uniform(-0.9, 0.9), ay + 0.62 + rnd.uniform(-0.05, 0.1), 0.05), 0.07, m[rnd.choice(["lavanda", "blanca", "rosa"])], "flor_seca", 2))
    return {
        "rect": (19, 36, 9, 4),
        "capas": [{"nombre": "altar", "objetos": p, "orden": ay + 0.55, "tipo": "objeto"}],
        "suelo": True,
        "anclas": anclas,
        "efectos": [{"tipo": "halo", "ancla": "velas", "radio": 1.5, "fuerza": 0.5, "color": "vela"},
                    {"tipo": "halo", "ancla": "velas_suelo", "radio": 1.2, "fuerza": 0.35, "color": "vela"}],
        "choques": [{"centro": [ax, ay], "tam": [1.6, 0.9]}],
        "margen_suelo": (60, 20, 60, 60),
    }


# ================================================================= Puerta del Sur

def puerta_sur():
    """Puerta del Sur: dos torreones redondos con chapitel de pizarra y el arco con el rastrillo levantado."""
    m = M()
    capas = []
    anclas = {}
    for lado, cx, fx in (("oeste", 36.0, 37.6), ("este", 45.0, 43.4)):
        torre_ = []
        torre_.append(cilindro((cx, 53.4, 2.9), 1.35, 5.8, m["piedra"], 24, "torreon"))
        torre_.append(cilindro((cx, 53.4, 5.95), 1.5, 0.3, m["piedra_gris"], 24, "torreon_cornisa"))
        torre_.append(cilindro((cx, 53.4, 7.35), 1.6, 2.5, m["pizarra"], 24, "torreon_chapitel", r_arriba=0.05))
        torre_.append(caja(cx - 0.18, 54.7, 2.6, cx + 0.18, 54.8, 3.6, m["ventana_alta"], "saetera"))
        K.luz_punto((cx, 55.2, 3.1), K.CALIDA, 3.0, 0.05, "saetera_luz")
        fa, ancla = farol_colgado(fx, 55.1, 2.9, m, "puerta_farol_" + lado, 35.0)
        torre_ += fa
        anclas["farol_" + lado] = ancla
        # cada torreón, su imagen (juntos serían una imagen con un hueco enorme en medio)
        capas.append({"nombre": "torre_" + lado, "objetos": torre_, "orden": 54.8, "tipo": "edificio"})
    arco = []
    arco.append(caja(37.0, 52.6, 3.5, 44.0, 54.6, 5.3, m["piedra"], "arco_muro", 0.02))
    arco.append(caja(36.9, 52.5, 5.3, 44.1, 54.7, 5.55, m["piedra_gris"], "arco_cornisa", 0.02))
    yy = 36.95
    while yy < 44.0:
        arco.append(caja(yy, 54.0, 5.55, yy + 0.6, 54.65, 6.05, m["piedra"], "almena", 0.02))
        yy += 1.05
    for k in range(9):                               # rastrillo levantado (puntas abajo)
        x = 37.5 + k * 0.75
        arco.append(caja(x - 0.04, 54.35, 3.3, x + 0.04, 54.45, 5.0, m["hierro_negro"], "rastrillo"))
        arco.append(cilindro((x, 54.4, 3.22), 0.05, 0.16, m["hierro_negro"], 6, "punta", r_arriba=0.0))
    for zz in (3.75, 4.4):
        arco.append(caja(37.4, 54.33, zz, 43.6, 54.47, zz + 0.07, m["hierro_negro"], "rastrillo_h"))
    arco.append(caja(39.9, 54.62, 4.2, 41.1, 54.68, 5.1, m["tela_azul"], "escudo"))
    arco.append(caja(40.3, 54.69, 4.45, 40.7, 54.71, 4.85, m["oro"], "escudo_roble"))
    capas.append({"nombre": "arco", "objetos": arco, "orden": 55.95, "tipo": "edificio"})
    return {
        "rect": (37, 51, 7, 5),
        "capas": capas,
        "suelo": True,
        "anclas": dict(anclas, salida=(40.5, 55.5, 0.0)),
        "efectos": [{"tipo": "halo", "ancla": "farol_oeste", "radio": 1.2, "fuerza": 0.5},
                    {"tipo": "halo", "ancla": "farol_este", "radio": 1.2, "fuerza": 0.5}],
        "choques": [{"centro": [36.0, 53.4], "tam": [2.4, 2.0]}, {"centro": [45.0, 53.4], "tam": [2.4, 2.0]}],
        "margen_suelo": (90, 20, 90, 10),
    }


# ================================================================= Botica y guardia (edificios pequeños)

def botica():
    import casas
    m = M()
    ficha = casas.casa(33.0, 35.0, 5, 5, {"pb": "revoque", "pa": "revoque", "entramado": True, "tejado": "teja",
                                           "contra": "contra", "pisos": 2, "puerta_x": 36.0, "vidrio": "ventana_verde"},
                       semilla=77, nombre="botica")
    # el letrero del mortero colgando junto a la puerta
    YS = 40.0
    bx = 34.6
    p = ficha["capas"][0]["objetos"]
    p.append(viga((bx, YS + 0.3, 3.2), (bx, YS + 1.0, 3.2), 0.04, m["hierro_negro"], 0.04, "brazo_letrero"))
    letrero = [caja(bx - 0.3, YS + 0.78, 2.45, bx + 0.3, YS + 0.82, 3.05, m["madera_clara"], "tabla", 0.01),
               cilindro((bx, YS + 0.85, 2.7), 0.13, 0.22, m["hueso_liso"], 12, "mortero", r_arriba=0.17),
               viga((bx - 0.05, YS + 0.85, 2.75), (bx + 0.15, YS + 0.85, 2.98), 0.03, m["madera_clara"], 0.03, "mano")]
    for o in letrero:
        o.visible_shadow = False
    ficha["capas"].append({"nombre": "letrero", "objetos": letrero, "orden": YS + 0.8, "tipo": "letrero",
                           "pivote": (bx, YS + 0.8, 3.15)})
    # manojos de hierbas colgando del alero
    for k in range(5):
        x = 33.6 + k * 0.9
        p.append(viga((x, YS + 0.3, 3.0), (x, YS + 0.3, 2.65), 0.01, m["hierro_negro"], 0.01, "hilo"))
        p.append(cilindro((x, YS + 0.3, 2.5), 0.07, 0.3, m["seto"], 8, "manojo", r_arriba=0.02))
    ficha["rect"] = (33, 35, 5, 5)
    return ficha


def guardia():
    """Cuerpo de guardia: piedra y pizarra, estandarte, brasero en la puerta del patio; el soportal con el libro de
    guardia (nota) y la valla del patio de los requisados."""
    import casas
    m = M()
    ficha = casas.casa(44.0, 45.0, 5, 4, {"pb": "piedra_gris", "pa": "piedra_gris", "entramado": False, "tejado": "pizarra",
                                           "contra": "contra_roja", "pisos": 2, "puerta_x": 46.5}, semilla=31, nombre="guardia")
    cuerpo = ficha["capas"][0]["objetos"]
    YS = 49.0
    cuerpo.append(viga((48.4, YS, 4.6), (48.4, YS + 0.6, 4.6), 0.04, m["hierro_negro"], 0.04, "asta"))
    cuerpo.append(caja(48.1, YS + 0.55, 3.2, 48.7, YS + 0.6, 4.55, m["tela_azul"], "estandarte"))
    cuerpo.append(caja(48.3, YS + 0.61, 3.7, 48.5, YS + 0.63, 4.1, m["oro"], "estandarte_roble"))
    # soportal (x 41-44, y 45-49): postes, tejadillo y el atril con el libro
    sop = []
    for (px_, py_) in ((41.15, 48.85), (42.6, 48.85), (41.15, 45.3)):
        sop.append(caja(px_ - 0.09, py_ - 0.09, 0.0, px_ + 0.09, py_ + 0.09, 2.7, m["viga"], "poste", 0.01))
    sop.append(caja(41.0, 48.75, 2.6, 44.0, 48.95, 2.8, m["viga"], "carrera"))
    sop += K.faldon(40.8, 44.05, 49.15, 2.75, 45.0, 3.35, m["pizarra"], 0.24, 0.05, "soportal_tejado")
    sop.append(caja(42.25, 46.3, 0.0, 42.75, 46.7, 1.0, m["madera_clara"], "atril", 0.02))
    sop.append(caja(42.15, 46.25, 1.0, 42.85, 46.75, 1.06, m["papel"], "libro", 0.01))
    fa, ancla_f = farol_colgado(42.6, 48.6, 2.25, m, "soportal_farol", 28.0)
    sop += fa
    ficha["capas"].append({"nombre": "soportal", "objetos": sop, "orden": 49.0, "tipo": "edificio"})
    # patio: valla al sur y al este, brasero, cajas de requisados
    pat = []
    for k in range(11):
        x = 44.2 + k * 0.48
        pat.append(caja(x - 0.05, 52.85, 0.0, x + 0.05, 52.95, 1.0, m["madera_clara"], "estaca"))
    pat.append(caja(44.1, 52.86, 0.75, 49.0, 52.94, 0.85, m["madera_clara"], "travesano"))
    pat.append(caja(44.1, 52.86, 0.3, 49.0, 52.94, 0.4, m["madera_clara"], "travesano"))
    pat.append(cilindro((45.2, 49.9, 0.55), 0.3, 0.25, m["hierro_negro"], 12, "brasero", r_arriba=0.38))
    pat.append(cilindro((45.2, 49.9, 0.25), 0.06, 0.5, m["hierro_negro"], 8, "brasero_pie"))
    pat.append(esfera((45.2, 49.9, 0.72), 0.22, m["llama"], "brasas", 2, (1, 1, 0.4)))
    K.luz_punto((45.2, 50.0, 1.0), K.hexlin("#FF9040"), 40.0, 0.15, "brasero_luz")
    pat.append(caja(47.6, 50.2, 0.0, 48.6, 50.9, 0.6, m["madera_clara"], "caja_requisada", 0.02))
    pat.append(esfera((48.8, 51.6, 0.3), 0.32, m["saco"], "saco", 2))
    ficha["capas"].append({"nombre": "patio", "objetos": pat, "orden": 52.95, "tipo": "objeto"})
    ficha["anclas"].update({"brasero": (45.2, 49.9, 0.9), "libro": (42.5, 46.5, 1.0), "farol_soportal": ancla_f})
    ficha["efectos"] += [{"tipo": "halo", "ancla": "brasero", "radio": 1.3, "fuerza": 0.55, "color": "vela"},
                         {"tipo": "halo", "ancla": "farol_soportal", "radio": 1.1, "fuerza": 0.45}]
    ficha["choques"] = [{"centro": [45.2, 49.9], "tam": [0.8, 0.6]}, {"centro": [48.1, 50.55], "tam": [1.1, 0.8]}]
    ficha["rect"] = (44, 45, 5, 4)
    ficha["margen_suelo"] = (220, 24, 140, 150)
    return ficha


# ================================================================= subida de la colina

def subida_colina():
    """La escalera de piedra de la Calle del Mercado a la colina del crematorio (se pisa: va bajo Kael), con bordillos."""
    m = M()
    p = []
    n = 9
    for k in range(n):
        y0 = 19.0 + k * 6.0 / n
        y1 = y0 + 6.0 / n
        p.append(caja(64.08, y0, 0.0, 65.92, y1 - 0.08, 0.12, m["piedra_gris"], "peldano", 0.015))
        p.append(caja(64.08, y1 - 0.08, 0.0, 65.92, y1, 0.05, m["zocalo"], "tabica"))
    for x in (64.0, 65.86):
        p.append(caja(x, 19.0, 0.0, x + 0.14, 25.0, 0.2, m["piedra"], "bordillo", 0.02))
    return {
        "rect": (64, 19, 2, 6),
        "capas": [{"nombre": "escalera", "objetos": p, "orden": None, "tipo": "objeto"}],
        "suelo": False,
        "anclas": {"arriba": (65.0, 19.3, 0.0), "abajo": (65.0, 24.7, 0.0)},
        "efectos": [],
        "margen_suelo": (20, 10, 20, 20),
    }


# ================================================================= farola suelta

def farol():
    m = M()
    p, ancla = farol_poste(0.5, 0.5, m)
    return {
        "rect": (0, 0, 1, 1),
        "capas": [{"nombre": "farola", "objetos": p, "orden": 0.62, "tipo": "objeto"}],
        "suelo": True,
        "anclas": {"farol": ancla},
        "efectos": [{"tipo": "halo", "ancla": "farol", "radio": 1.3, "fuerza": 0.5, "delante": 0.5}],
        "choques": [{"centro": [0.5, 0.5], "tam": [0.35, 0.3]}],
        "margen_suelo": (110, 10, 110, 110),
    }


def ropa_tendida():
    """Ropa tendida entre dos postes (3 casillas): camisas, una sábana y calcetines; se mece en el juego."""
    m = M()
    rnd = random.Random(13)
    postes = [caja(0.05, 0.4, 0.0, 0.17, 0.52, 2.6, m["viga"], "poste"), caja(2.83, 0.4, 0.0, 2.95, 0.52, 2.6, m["viga"], "poste")]
    ropa = []
    prev = (0.11, 0.46, 2.45)
    for k in range(1, 13):
        t = k / 12
        pt = (0.11 + 2.78 * t, 0.46, 2.45 - 0.25 * math.sin(math.pi * t))
        ropa.append(viga(prev, pt, 0.01, m["hierro_negro"], 0.01, "cuerda"))
        prev = pt
    for (x, w, h, tela) in ((0.45, 0.42, 0.55, "tela_azul"), (1.05, 0.62, 0.8, "tela_lisa"), (1.85, 0.4, 0.5, "tela_roja"),
                            (2.4, 0.22, 0.3, "tela_ocre")):
        zc = 2.45 - 0.25 * math.sin(math.pi * (x + w * 0.5 - 0.11) / 2.78)
        ropa.append(caja(x, 0.44, zc - h, x + w, 0.48, zc, m[tela], "prenda", 0.01))
    return {
        "rect": (0, 0, 3, 1),
        "capas": [{"nombre": "postes", "objetos": postes, "orden": 0.6, "tipo": "objeto"},
                  {"nombre": "ropa", "objetos": ropa, "orden": 0.62, "tipo": "letrero", "pivote": (1.5, 0.46, 2.45)}],
        "suelo": True,
        "anclas": {},
        "efectos": [],
        "choques": [{"centro": [0.11, 0.46], "tam": [0.2, 0.2]}, {"centro": [2.89, 0.46], "tam": [0.2, 0.2]}],
        "margen_suelo": (50, 10, 70, 50),
    }


PIEZAS = {
    "crematorio": crematorio,
    "jardin_urnas": jardin_urnas,
    "arbol": arbol,
    "concejo": concejo,
    "torre": torre,
    "ronda": ronda,
    "mercado": mercado,
    "plaza": plaza,
    "patio_cuervo": patio_cuervo,
    "grieta": grieta,
    "patio_velas": patio_velas,
    "puerta_sur": puerta_sur,
    "botica": botica,
    "guardia": guardia,
    "subida_colina": subida_colina,
    "farol": farol,
    "ropa_tendida": ropa_tendida,
}
