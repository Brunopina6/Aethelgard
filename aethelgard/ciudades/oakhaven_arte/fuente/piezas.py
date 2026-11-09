# Las piezas de Oakhaven (T-089) en 3D, para hornearlas en 3/4 (kit.py). Cada función monta su pieza en la escena
# y devuelve su ficha:
#   "rect":   la huella en casillas (x, y, ancho, alto), la de ciudades/oakhaven.gd cuando es un lugar de canon
#   "capas":  [{"nombre", "objetos", "orden" (y de la casilla con la que se ordena frente a Kael), "tipo"}]
#             tipo «edificio» (tapa a Kael por detrás y se aclara a su alrededor), «objeto» (no se aclara) o
#             «letrero» (cuelga y se mece: lleva «pivote»)
#   "suelo":  True si lleva calcomanía de suelo (sombra y luz cálida en el empedrado)
#   "anclas": puntos con nombre (x, y, z) en casillas: humo, halos de farol, la puerta…
#   "efectos": [{"tipo": "humo"|"halo"|"luciernagas"|"velas"|"brillo", "ancla": nombre, ...}]
# Coordenadas: x al este, y al SUR, z arriba; 1 casilla = 1 m (kit.V).
import math, random
import kit as K
from kit import caja, viga, cilindro, esfera, mat

ROJO_GERANIO = K.hexlin("#B8364A")
ROSA_FLOR = K.hexlin("#E58FB0")
VERDE_HOJA = K.hexlin("#3F5E3A")


def _materiales_cuervo():
    return {
        "piedra": mat("piedra", "#8C847A", "#A39A8C", (0.62, 0.31), "#5A534C", 0.12, nombre="piedra_calida"),
        "zocalo": mat("piedra", "#7C756C", "#8F877C", (0.5, 0.25), "#4E4943", 0.25, nombre="zocalo"),
        "revoque": mat("revoque", "#D8C8A4", "#8F826B", nombre="revoque_cuervo"),
        "viga": mat("madera", "#6B3F2A", 0.35, nombre="viga"),
        "puerta": mat("madera", "#7A4A2E", 0.5, nombre="puerta_madera", escala_veta=(1.0, 1.0, 6.0)),
        "teja": mat("teja", "#A0583A", 0.24, nombre="teja_roja"),
        "hierro": mat("hierro", 0.65, nombre="hierro_oxidado"),
        "ventana": mat("ventana", "#FFB45A", 1.7, nombre="ventana_calida"),
        "ventana_alta": mat("ventana", "#FFA94E", 1.25, nombre="ventana_calida_alta"),
        "interior": mat("ventana", "#FF9C3E", 1.3, nombre="interior_taberna"),
        "farol": mat("luz", "#F2C86B", 3.5, nombre="farol_encendido"),
        "contra": mat("madera", "#3E5B47", 0.2, nombre="contraventana_verde", escala_veta=(1, 1, 3)),
        "geranio": mat("liso", ROJO_GERANIO, 0.7, nombre="geranio"),
        "rosa": mat("liso", ROSA_FLOR, 0.7, nombre="flor_rosa"),
        "hoja": mat("liso", VERDE_HOJA, 0.8, nombre="hoja_maceta"),
    }


def _farol_pared(x, y, z, m, nombre="farol_pared", potencia=60.0):
    """Farol de pared (brazo de hierro y caja de vidrio encendida). Devuelve las partes y el ancla del halo."""
    p = []
    p.append(viga((x, y, z + 0.32), (x, y + 0.32, z + 0.32), 0.035, m["hierro"], 0.035, nombre + "_brazo"))
    p.append(viga((x, y, z + 0.05), (x, y + 0.26, z + 0.30), 0.025, m["hierro"], 0.025, nombre + "_tirante"))
    p.append(caja(x - 0.12, y + 0.2, z - 0.05, x + 0.12, y + 0.44, z + 0.25, m["farol"], nombre + "_vidrio"))
    for dx in (-0.13, 0.13):
        for dy in (0.19, 0.45):
            p.append(caja(x + dx - 0.015, y + dy - 0.015, z - 0.08, x + dx + 0.015, y + dy + 0.015, z + 0.28, m["hierro"], nombre + "_varilla"))
    p.append(cilindro((x, y + 0.32, z + 0.33), 0.17, 0.1, m["hierro"], 4, nombre + "_tejadillo", r_arriba=0.02))
    p.append(caja(x - 0.14, y + 0.18, z - 0.1, x + 0.14, y + 0.46, z - 0.06, m["hierro"], nombre + "_base"))
    K.luz_punto((x, y + 0.32, z + 0.1), K.FAROL, potencia, 0.06, nombre + "_luz")
    return p, (x, y + 0.32, z + 0.1)


def _silueta_cuervo():
    """Perfil de un cuervo posado, mirando a la derecha (metros; origen en las patas), en sentido antihorario."""
    return [(0.0, 0.0), (0.07, 0.07), (0.13, 0.16), (0.17, 0.26), (0.19, 0.33), (0.23, 0.37), (0.38, 0.40),
            (0.27, 0.425), (0.25, 0.45), (0.19, 0.47), (0.13, 0.455), (0.09, 0.41), (0.03, 0.36), (-0.09, 0.31),
            (-0.21, 0.25), (-0.35, 0.18), (-0.53, 0.11), (-0.51, 0.065), (-0.34, 0.095), (-0.20, 0.075),
            (-0.09, 0.05), (-0.03, 0.02)]

def taberna():
    """La Taberna del Cuervo Oxidado (posada): planta baja de piedra, alto con entramado y vuelo sobre la calle,
    hastial sobre la puerta, chimenea con humo, puerta entreabierta con la luz de dentro y el cuervo de hierro."""
    m = _materiales_cuervo()
    X0, X1, YN, YS = 11.0, 21.0, 19.0, 25.0
    Z1 = 3.0           # alto de la planta baja
    Z2 = 5.5           # alero
    VUELO = 0.35       # el piso de arriba sale sobre la calle
    cuerpo = []
    # --- planta baja: piedra con huecos
    huecos_pb = [(11.75, 12.85, 0.9, 2.2), (13.75, 14.85, 0.9, 2.2), (15.95, 17.25, 0.0, 2.35),
                 (18.15, 19.25, 0.9, 2.2), (19.95, 20.55, 1.1, 2.0)]
    cuerpo += K.fachada(X0, X1, YS, 0.0, Z1, 0.32, m["piedra"], huecos_pb, "pb")
    cuerpo.append(caja(X0, YN, 0.0, X1, YS - 0.32, Z1, m["piedra"], "pb_dentro"))
    for (a, b) in ((X0 - 0.04, 15.95), (17.25, X1 + 0.04)):
        cuerpo.append(caja(a, YS - 0.05, 0.0, b, YS + 0.07, 0.45, m["zocalo"], "zocalo", 0.02))
    for (cx, w) in ((12.3, 1.1), (14.3, 1.1), (18.7, 1.1)):
        cuerpo += K.ventana(cx, YS, 0.9, w, 1.3, m["viga"], m["ventana"], None, None, True, 0.2, "v_pb",
                            luz=(K.CALIDA, 22.0))
    cuerpo += K.ventana(20.25, YS, 1.1, 0.6, 0.9, m["viga"], m["ventana"], None, None, True, 0.2, "v_pb_chica",
                        luz=(K.CALIDA, 8.0))
    cuerpo += K.puerta(16.6, YS, 1.3, 2.35, m["puerta"], m["hierro"], m["viga"], abierta=0.55, interior=m["interior"],
                       hundida=0.22, nombre="puerta", luz=(K.CALIDA, 60.0))
    # escalón de piedra en la puerta
    cuerpo.append(caja(15.8, YS - 0.05, 0.0, 17.4, YS + 0.32, 0.12, m["zocalo"], "escalon", 0.02))
    # --- vuelo del piso alto: viga y canecillos
    cuerpo.append(caja(X0 - 0.05, YS - 0.1, Z1 - 0.22, X1 + 0.05, YS + VUELO, Z1, m["viga"], "viga_vuelo", 0.015))
    for cx in (11.2, 13.0, 15.0, 16.6, 18.2, 20.0, 20.8):
        cuerpo.append(caja(cx - 0.09, YS - 0.02, Z1 - 0.62, cx + 0.09, YS + VUELO - 0.02, Z1 - 0.22, m["viga"], "canecillo", 0.02))
    # --- piso alto: entramado y revoque
    YS2 = YS + VUELO
    huecos_pa = [(11.7, 12.5, 3.55, 4.65), (13.5, 14.3, 3.55, 4.65), (15.45, 16.25, 3.55, 4.75), (16.95, 17.75, 3.55, 4.75),
                 (18.8, 19.6, 3.55, 4.65), (20.05, 20.65, 3.7, 4.5)]
    cuerpo += K.fachada(X0, X1, YS2, Z1, Z2, 0.25, m["revoque"], huecos_pa, "pa")
    cuerpo.append(caja(X0, YN, Z1, X1, YS2 - 0.25, Z2, m["revoque"], "pa_dentro"))
    cuerpo += K.entramado(X0, X1, YS2, Z1, Z2, huecos_pa, m["viga"], 0.16, 0.05, 1.1, True, "ent_pa")
    flores = (m["geranio"], m["rosa"], m["hoja"])
    for (a, b, za, zb) in huecos_pa:
        w = b - a
        cuerpo += K.ventana((a + b) * 0.5, YS2, za, w, zb - za, m["viga"], m["ventana_alta"], m["contra"] if w > 0.7 else None,
                            flores if w > 0.7 else None, False, 0.12, "v_pa", luz=(K.CALIDA, 6.0), rejilla=3)
    # --- hastial sobre la puerta (el piso alto sube en un triángulo con su tejado propio)
    GX0, GX1 = 15.0, 18.2
    GZ = 1.9
    cuerpo.append(K.hastial_muro(GX0, GX1, YS2, Z2, GZ, m["revoque"], 0.3, "hastial"))
    cuerpo += K.entramado(GX0, GX1, YS2, Z2, Z2 + 0.18, [], m["viga"], 0.16, 0.05, 9.0, False, "ent_hastial")
    for lado in (-1, 1):
        a = ((GX0 + GX1) * 0.5, YS2 + 0.03, Z2 + GZ - 0.05)
        b = (GX0 + 0.1 if lado < 0 else GX1 - 0.1, YS2 + 0.03, Z2 + 0.1)
        cuerpo.append(viga(a, b, 0.15, m["viga"], 0.05, "hastial_viga"))
    cuerpo.append(viga(((GX0 + GX1) * 0.5, YS2 + 0.03, Z2 + 0.15), ((GX0 + GX1) * 0.5, YS2 + 0.03, Z2 + GZ - 0.1), 0.14, m["viga"], 0.05, "hastial_pendolon"))
    cuerpo += K.ventana((GX0 + GX1) * 0.5 - 0.45, YS2, Z2 + 0.35, 0.42, 0.62, m["viga"], m["ventana_alta"], None, None, False, 0.1, "v_hastial",
                        luz=(K.CALIDA, 6.0), rejilla=2)
    cuerpo += K.ventana((GX0 + GX1) * 0.5 + 0.45, YS2, Z2 + 0.35, 0.42, 0.62, m["viga"], m["ventana_alta"], None, None, False, 0.1, "v_hastial",
                        luz=(K.CALIDA, 6.0), rejilla=2)
    cuerpo += K.tejado_frontal(GX0, GX1, YS2 + 0.02, 21.6, Z2, GZ, m["teja"], 0.32, "tej_hastial", madera=m["viga"])
    # --- tejado principal
    cuerpo += K.tejado_dos_aguas(X0, X1, YS2, YN, Z2, 2.1, m["teja"], 0.38, 0.3, None, "tejado")
    # buhardilla con luz al este
    cuerpo += K.fachada(19.2, 20.0, 24.2, 6.2, 7.15, 0.5, m["revoque"], [(19.35, 19.85, 6.45, 6.95)], "buhardilla")
    cuerpo.append(caja(19.2, 22.6, 6.2, 20.0, 23.7, 7.15, m["revoque"], "buhardilla_dentro"))
    cuerpo += K.ventana(19.6, 24.2, 6.45, 0.5, 0.5, m["viga"], m["ventana_alta"], None, None, False, 0.1, "v_buhardilla",
                        luz=(K.CALIDA, 5.0))
    cuerpo += K.tejado_frontal(19.15, 20.05, 24.25, 22.6, 7.1, 0.45, m["teja"], 0.1, "tej_buhardilla")
    # chimenea de piedra (el humo sale de su boca)
    chim, humo = K.chimenea(12.25, 21.1, 5.0, 4.35, 0.62, m["piedra"])
    cuerpo += chim
    chim2, humo2 = K.chimenea(20.3, 20.4, 6.0, 2.6, 0.42, m["piedra"], nombre="chimenea_chica")
    cuerpo += chim2
    # --- tejadillo sobre la puerta
    cuerpo += K.faldon(15.55, 17.65, YS + 0.82, 2.72, YS - 0.05, 3.0, m["teja"], 0.2, 0.05, "tejadillo")
    for cx in (15.7, 17.5):
        cuerpo.append(viga((cx, YS, 2.4), (cx, YS + 0.7, 2.72), 0.06, m["viga"], 0.06, "tornapunta"))
    # --- farol junto a la puerta
    farol, ancla_farol = _farol_pared(15.4, YS, 2.15, m, "farol_puerta", 40.0)
    cuerpo += farol
    # --- el cuervo de hierro: brazo en el piso alto y la chapa colgando
    bx, bz = 13.0, 3.55
    cuerpo.append(viga((bx, YS2, bz), (bx, YS2 + 0.85, bz), 0.05, m["hierro"], 0.05, "brazo_letrero"))
    cuerpo.append(viga((bx, YS2, bz - 0.45), (bx, YS2 + 0.6, bz - 0.02), 0.03, m["hierro"], 0.03, "tirante_letrero"))
    cuerpo.append(esfera((bx, YS2 + 0.88, bz), 0.04, m["hierro"], "remate_letrero", 2))
    piv = (bx, YS2 + 0.7, bz - 0.03)
    letrero = []
    for dx in (-0.22, 0.22):
        letrero.append(viga((bx + dx * 0.25, piv[1], piv[2]), (bx + dx, piv[1], piv[2] - 0.28), 0.012, m["hierro"], 0.012, "cadena"))
    aro = cilindro((bx, piv[1], piv[2] - 0.7), 0.42, 0.04, m["hierro"], 32, "aro", eje='Y')
    hueco = cilindro((bx, piv[1], piv[2] - 0.7), 0.37, 0.2, m["hierro"], 32, "aro_hueco", eje='Y')
    b = aro.modifiers.new("hueco", 'BOOLEAN')
    b.operation = 'DIFFERENCE'
    b.object = hueco
    hueco.hide_render = True
    hueco.hide_viewport = True
    letrero.append(aro)
    letrero.append(caja(bx - 0.36, piv[1] - 0.02, piv[2] - 0.82, bx + 0.36, piv[1] + 0.02, piv[2] - 0.78, m["hierro"], "percha"))
    cuervo = K.poligono_extruido(_silueta_cuervo(), 0.035, m["hierro"], "cuervo")
    cuervo.location = K.V(bx - 0.05, piv[1], piv[2] - 0.78)
    letrero.append(cuervo)
    for o in letrero:
        o.visible_shadow = False        # se mece en el juego: su sombra fija quedaría mal
    return {
        "rect": (11, 19, 10, 6),
        "capas": [
            {"nombre": "cuerpo", "objetos": cuerpo, "orden": YS, "tipo": "edificio"},
            {"nombre": "letrero", "objetos": letrero, "orden": YS2 + 0.75, "tipo": "letrero", "pivote": piv},
        ],
        "suelo": True,
        "anclas": {"humo": humo, "humo_chica": humo2, "farol_puerta": ancla_farol, "puerta": (16.6, YS + 0.4, 0.0),
                   "letrero": piv},
        "efectos": [
            {"tipo": "humo", "ancla": "humo", "color": "calido", "alto": 3.2},
            {"tipo": "humo", "ancla": "humo_chica", "color": "calido", "alto": 2.2, "escala": 0.6},
            {"tipo": "halo", "ancla": "farol_puerta", "radio": 1.3},
        ],
    }



import piezas_ciudad as C
import casas as CASAS

PIEZAS = {
    "taberna": taberna,
}
PIEZAS.update(C.PIEZAS)
PIEZAS.update(CASAS.PIEZAS)
