# Esperas de exploración (personalidad de los héroes), paso 2 de 3: los clips, hechos en Blender 5.2 por script.
#   blender -b -P animaciones/esperas/fuentes/esperas.py -- <héroe> <fbx> <reposo_<héroe>.json> <salida.glb> [solo=<clip>]
# Parte de la pose del juego (pruebas/herramientas/capturar_reposo.gd), resuelve cada fotograma con los controles de
# las claves de abajo (tronco, IK de brazos y piernas con los pies fijos en el suelo, armas, dedos) y exporta un GLB con
# la armadura (y una malla mínima para que lleve piel) y una acción por clip. Godot lo pasa a los huesos del héroe con
# pruebas/herramientas/convertir_esperas.gd.
#
# Ejes de los controles: los del personaje (adelante, arriba, derecha), en metros de un personaje de 1,7 m.
#   cadera (a,u,d)            mueve la cadera; las piernas se corrigen con IK y los pies no se mueven del suelo
#   cadera_g, columna, columna1, pecho, cuello, cabeza, hombro_i/d, brazo_i/d_g, antebrazo_i/d_g:
#                             giros (guiñada a la izquierda +, cabeceo hacia delante +, alabeo hacia su derecha +)
#   mano_i/d (a,u,d) + mano_i/d_w   IK de la mano: posición respecto a su hombro, en los ejes del pecho (si el pecho
#                             gira, el objetivo gira con él); _w mezcla entre el brazo sin IK (0) y el objetivo (1)
#   codo_i/d (a,u,d)          hacia dónde se dobla el codo (ejes del pecho)
#   mano_i/d_g                giro de la mano después del IK
#   arma_i/d (a,u,d) + _w     dirección del arma de esa mano (ejes del pecho)
#   punta_i/d (a,d) + _w      apoya la punta del arma en el suelo hacia esa dirección horizontal (Garon)
#   mano_i_en_arma (m) + _w   la mano izquierda agarra el arma de la derecha a esa distancia de su empuñadura
#   dedos_i/d                 cierra los dedos (grados por falange)
#   pie_i/d (a,u,d), pie_i/d_g  mueve y gira un pie (para golpear el suelo con la punta)
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
from mathutils import Vector, Quaternion, Matrix
import esperas_lib as L

FPS = 30
CERO = (0.0, 0.0, 0.0)

# ---------------------------------------------------------------- armas (las de kael_3d.gd, maga_3d.gd y garon_3d.gd)
# «base»: dirección del arma en el reposo, en ejes del personaje, o «hueso» si se calcula como garon_3d.gd
# (_colocar_espada: del pulgar, perpendicular a la línea mano→dedo corazón). «largo»: de su anclaje a la punta.
ARMAS = {
    "Kael": {"Right": {"base": (-0.85, 0.5, 0.12), "largo": 0.9 * 1.45 * 1.0087, "anclaje": "palma"}},
    "Lya": {"Right": {"base": (0.15, 1.0, 0.0), "largo": 0.6154 * 1.05 * 0.9876, "anclaje": "palma"}},
    "Garon": {"Right": {"base": "hueso", "largo": 0.88 * 1.1 * 1.0978, "anclaje": "garon"},
              "Left": {"base": "hueso", "largo": 0.88 * 1.1 * 1.0978, "anclaje": "garon"}},
}

# ---------------------------------------------------------------- los clips
# Cada clip: (duración se toma de la última clave) [(segundos, {control: valor})]. Todo vuelve a 0 al final.

def v(a, u, d):
    return (a, u, d)


CLIPS = {
    # ------------------------------------------------ Kael: impaciente y protector
    "Kael": {
        # Vigila: mira a la izquierda y a la derecha por encima del hombro, la mano libre en la cadera.
        "espera_vigilar": [
            (0.7, {"cadera": v(0, -0.004, -0.012), "pecho": v(8, 0, 0), "cuello": v(10, 0, 0), "cabeza": v(16, -4, -2),
                   "mano_i_w": 0.85, "mano_i": v(-0.03, -0.19, -0.09), "codo_i": v(-0.4, 0, -1)}),
            (1.6, {"pecho": v(10, 0, 0), "cuello": v(12, 0, 0), "cabeza": v(20, -3, -3), "mano_i_w": 0.85}),
            (2.4, {"cadera": v(0, -0.004, 0.012), "cadera_g": v(-4, 0, 0), "pecho": v(-12, 0, 0), "cuello": v(-14, 0, 0),
                   "cabeza": v(-24, -2, 3)}),
            (3.4, {"cadera_g": v(-5, 0, 0), "pecho": v(-14, 0, 0), "cuello": v(-16, 0, 0), "cabeza": v(-28, -1, 3),
                   "mano_i_w": 0.85}),
            (4.1, {"cadera": CERO, "cadera_g": CERO, "pecho": v(-2, 0, 0), "cuello": v(-3, 0, 0), "cabeza": v(-4, 3, 0),
                   "mano_i_w": 0.3}),
            (4.8, {}),
        ],
        # Comprueba la empuñadura: baja el sable del hombro y apoya la punta en el suelo, delante y a su derecha; lo
        # agarra también con la izquierda, lo gira para mirarle el filo y lo vuelve a subir al hombro por fuera.
        "espera_empunadura": [
            (0.9, {"mano_d_w": 1.0, "mano_d": v(0.10, -0.19, -0.05), "codo_d": v(-0.3, -0.2, 1),
                   "punta_d_w": 1.0, "punta_d": (0.55, 0.45), "cabeza": v(-10, 14, 0), "cuello": v(-4, 6, 0)}),
            (1.5, {"mano_i_w": 1.0, "mano_i_en_arma": -0.075, "mano_i_en_arma_w": 1.0, "codo_i": v(-0.2, -0.5, -1),
                   "dedos_i": 30.0, "cabeza": v(-12, 18, -2), "cadera": v(0, -0.01, 0.01)}),
            (2.3, {"punta_d": (0.62, 0.35), "mano_d_g": v(0, 0, 15), "cabeza": v(-16, 15, 3), "dedos_d": 12.0,
                   "mano_i_w": 1.0, "mano_i_en_arma_w": 1.0, "dedos_i": 40.0}),
            (3.0, {"punta_d": (0.5, 0.5), "mano_d_g": v(0, 0, -12), "cabeza": v(-8, 17, -3), "dedos_d": 0.0,
                   "mano_i_w": 1.0, "mano_i_en_arma_w": 1.0, "dedos_i": 30.0, "cadera": v(0, -0.01, 0.01)}),
            (3.6, {"mano_i_w": 0.0, "mano_i_en_arma_w": 0.0, "dedos_i": 0.0, "mano_d_g": CERO, "punta_d_w": 0.0,
                   "mano_d_w": 1.0, "mano_d": v(0.06, -0.08, 0.04), "arma_d_w": 1.0, "arma_d": v(0.2, 0.3, 1.0),
                   "cabeza": v(-4, 6, 0), "cadera": CERO}),
            (4.4, {"mano_d_w": 0.0, "arma_d_w": 0.0, "cabeza": v(2, -2, 0), "cuello": CERO}),
            (5.2, {}),
        ],
        # El brazalete: alza el antebrazo izquierdo, lo mira, gira la muñeca, cierra y abre el puño y sacude la mano.
        "espera_brazalete": [
            (0.8, {"mano_i_w": 1.0, "mano_i": v(0.17, -0.05, 0.05), "codo_i": v(-0.2, -1, -0.6),
                   "mano_i_g": v(0, 0, 25), "cabeza": v(16, 7, -4), "cuello": v(6, 3, 0), "pecho": v(4, 2, 0)}),
            (1.5, {"mano_i_g": v(0, 0, -25), "cabeza": v(18, 9, -6)}),
            (2.1, {"mano_i_g": v(0, 0, 20), "mano_i": v(0.18, -0.04, 0.04)}),
            (2.5, {"dedos_i": 70.0, "mano_i_g": v(0, 0, 5)}),
            (2.8, {"dedos_i": 5.0}),
            (3.1, {"dedos_i": 70.0}),
            (3.4, {"dedos_i": 0.0, "mano_i": v(0.13, -0.09, 0.03), "cabeza": v(8, 5, -2)}),
            (3.6, {"mano_i_w": 0.7, "mano_i_g": v(0, 25, 0)}),
            (3.75, {"mano_i_g": v(0, -20, 0)}),
            (3.9, {"mano_i_g": v(0, 20, 0), "mano_i_w": 0.4}),
            (4.1, {"mano_i_g": v(0, -10, 0), "cabeza": v(2, 0, 0), "mano_i_w": 0.1}),
            (4.8, {}),
        ],
        # Impaciencia: carga el peso en la pierna izquierda, golpea el suelo con la punta del pie y resopla.
        "espera_impaciencia": [
            (0.6, {"cadera": v(0, -0.006, -0.03), "cadera_g": v(0, 0, -3), "pecho": v(0, 0, 3), "cabeza": v(-6, -3, 4)}),
            (0.9, {"pie_d": v(0.0, 0.025, 0.0), "pie_d_g": v(0, -18, 0)}),
            (1.15, {"pie_d": v(0, 0.004, 0), "pie_d_g": v(0, -2, 0)}),
            (1.4, {"pie_d": v(0.0, 0.025, 0.0), "pie_d_g": v(0, -18, 0)}),
            (1.65, {"pie_d": v(0, 0.004, 0), "pie_d_g": v(0, -2, 0)}),
            (1.9, {"pie_d": v(0.0, 0.025, 0.0), "pie_d_g": v(0, -18, 0), "cabeza": v(-10, -5, 6)}),
            (2.15, {"pie_d": CERO, "pie_d_g": CERO}),
            (2.6, {"hombro_i": v(0, 0, 9), "hombro_d": v(0, 0, -9), "cabeza": v(-4, -8, 2), "pecho": v(0, -4, 2)}),
            (3.2, {"hombro_i": v(0, 0, -2), "hombro_d": v(0, 0, 2), "cabeza": v(0, 6, 0), "pecho": v(0, 2, 0),
                   "cadera": v(0, -0.004, -0.01)}),
            (4.2, {}),
        ],
    },
    # ------------------------------------------------ Lya: curiosa y cálida
    "Lya": {
        # Una flor: la ve, se agacha con el cetro apoyado a un lado, la roza con la mano izquierda y se levanta.
        "espera_flor": [
            (0.6, {"cabeza": v(14, 22, 6), "cuello": v(6, 8, 0), "pecho": v(4, 4, 0)}),
            (1.7, {"cadera": v(0.07, -0.30, 0.0), "columna": v(4, 14, 0), "pecho": v(6, 10, 0), "cabeza": v(10, 22, 10),
                   "arma_d_w": 1.0, "arma_d": v(0.25, 1.0, 0.45), "brazo_d_g": v(0, 0, 8)}),
            (2.3, {"mano_i_w": 1.0, "mano_i": v(0.31, -0.14, 0.02), "codo_i": v(0, -0.6, -1), "mano_i_g": v(0, 30, 0),
                   "cabeza": v(10, 24, 12)}),
            (3.0, {"mano_i": v(0.32, -0.17, 0.05), "cabeza": v(8, 22, -6)}),
            (3.6, {"mano_i": v(0.30, -0.14, 0.0), "cabeza": v(12, 20, 8)}),
            (4.1, {"mano_i_w": 0.0, "mano_i_g": CERO, "cabeza": v(6, 12, 4)}),
            (5.2, {"cadera": v(0, -0.004, 0), "columna": CERO, "pecho": CERO, "cabeza": v(2, -4, 4), "arma_d_w": 0.0,
                   "brazo_d_g": CERO}),
            (6.2, {}),
        ],
        # Juega con el cetro: lo cruza delante con las dos manos, lo inclina para mirar el loto y se mece.
        "espera_cetro": [
            (0.8, {"mano_d_w": 1.0, "mano_d": v(0.20, -0.20, -0.08), "codo_d": v(-0.2, -0.5, 1),
                   "arma_d_w": 1.0, "arma_d": v(0.2, 0.45, -1.0), "cabeza": v(0, 8, 0)}),
            (1.3, {"mano_i_w": 1.0, "mano_i_en_arma": 0.22, "mano_i_en_arma_w": 1.0, "codo_i": v(-0.2, -0.6, -1),
                   "arma_d": v(0.25, 0.55, -1.0)}),
            (2.1, {"arma_d": v(0.35, 1.0, -0.8), "cabeza": v(18, -4, -10), "cadera_g": v(0, 0, -3), "pecho": v(0, 0, -3), "cadera": v(0, -0.012, 0)}),
            (2.8, {"arma_d": v(0.3, 0.9, -0.9), "cabeza": v(16, 0, 8), "cadera_g": v(0, 0, 3), "pecho": v(0, 0, 3)}),
            (3.5, {"arma_d": v(0.35, 1.0, -0.8), "cabeza": v(18, -3, -8), "cadera_g": v(0, 0, -2), "pecho": v(0, 0, -2)}),
            (4.0, {"mano_i_w": 0.0, "mano_i_en_arma_w": 0.0, "arma_d": v(0.2, 1.0, -0.2), "cabeza": v(4, 2, 0),
                   "cadera_g": CERO, "pecho": CERO}),
            (4.8, {"mano_d_w": 0.0, "arma_d_w": 0.0}),
            (5.4, {}),
        ],
        # El pelo: se lo recoloca detrás de la oreja izquierda, ladeando la cabeza.
        "espera_pelo": [
            (0.7, {"mano_i_w": 1.0, "mano_i": v(0.07, 0.22, -0.01), "codo_i": v(0.5, -0.4, -1),
                   "mano_i_g": v(-20, -30, 0), "cabeza": v(-4, 2, 10), "cuello": v(0, 0, 4)}),
            (1.2, {"mano_i": v(0.02, 0.27, -0.03), "cabeza": v(-6, 0, 14)}),
            (1.7, {"mano_i": v(-0.03, 0.25, -0.05), "mano_i_g": v(-30, -10, 0), "cabeza": v(-6, -2, 12)}),
            (2.3, {"mano_i_w": 0.0, "mano_i_g": CERO, "cabeza": v(6, -3, 6), "cuello": CERO}),
            (3.0, {"cabeza": v(2, 0, 2)}),
            (3.6, {}),
        ],
    },
    # ------------------------------------------------ Garon: sólido y veterano
    "Garon": {
        # Rueda los hombros dos veces y estira el cuello a un lado y al otro.
        "espera_hombros": [
            (0.5, {"hombro_i": v(0, 0, 12), "hombro_d": v(0, 0, -12), "pecho": v(0, -3, 0)}),
            (0.9, {"hombro_i": v(-10, 0, 4), "hombro_d": v(10, 0, -4), "pecho": v(0, -5, 0)}),
            (1.3, {"hombro_i": v(0, 0, -4), "hombro_d": v(0, 0, 4), "pecho": v(0, 2, 0)}),
            (1.7, {"hombro_i": v(0, 0, 12), "hombro_d": v(0, 0, -12)}),
            (2.1, {"hombro_i": v(-10, 0, 4), "hombro_d": v(10, 0, -4), "pecho": v(0, -5, 0)}),
            (2.5, {"hombro_i": CERO, "hombro_d": CERO, "pecho": CERO, "cabeza": v(0, 4, 0)}),
            (3.0, {"cuello": v(0, 2, -10), "cabeza": v(-4, 4, -16)}),
            (3.5, {"cuello": v(0, 2, -10), "cabeza": v(-4, 4, -16)}),
            (4.1, {"cuello": v(0, 2, 10), "cabeza": v(4, 4, 16)}),
            (4.6, {"cuello": v(0, 2, 10), "cabeza": v(4, 4, 16)}),
            (5.4, {}),
        ],
        # Estira la espalda: baja las espadas a los lados, saca pecho, mira arriba y se inclina a un lado y al otro.
        "espera_espalda": [
            (0.9, {"cadera": v(0.03, -0.01, 0), "columna": v(0, -8, 0), "pecho": v(0, -10, 0), "cabeza": v(0, -14, 0),
                   "hombro_i": v(-8, 0, 0), "hombro_d": v(8, 0, 0),
                   "mano_d_w": 1.0, "mano_d": v(-0.02, -0.19, 0.05), "codo_d": v(-1, 0, 0.3),
                   "mano_i_w": 1.0, "mano_i": v(-0.02, -0.19, -0.05), "codo_i": v(-1, 0, -0.3),
                   "arma_d_w": 1.0, "arma_d": v(0.15, -1, 0.25), "arma_i_w": 1.0, "arma_i": v(0.15, -1, -0.25)}),
            (1.8, {"columna": v(0, -10, 0), "pecho": v(0, -12, 0), "cabeza": v(0, -18, 0)}),
            (2.5, {"columna": v(0, -2, 6), "pecho": v(0, -2, 6), "cabeza": v(0, -2, 4), "cadera": v(0.01, 0, -0.02)}),
            (3.2, {"columna": v(0, -2, -6), "pecho": v(0, -2, -6), "cabeza": v(0, -2, -4), "cadera": v(0.01, 0, 0.02)}),
            (3.9, {"columna": CERO, "pecho": CERO, "cabeza": v(0, 4, 0), "cadera": CERO, "hombro_i": CERO,
                   "hombro_d": CERO, "mano_d_w": 1.0, "mano_i_w": 1.0, "arma_d_w": 1.0, "arma_i_w": 1.0}),
            (4.8, {"mano_d_w": 0.0, "mano_i_w": 0.0, "arma_d_w": 0.0, "arma_i_w": 0.0}),
            (5.4, {}),
        ],
        # Se apoya en las espadas: las clava de punta en el suelo, delante y a los lados, y descansa el peso en ellas.
        "espera_apoyarse": [
            (1.0, {"mano_d_w": 1.0, "mano_d": v(0.12, -0.12, 0.03), "codo_d": v(-0.3, 0, 1),
                   "mano_i_w": 1.0, "mano_i": v(0.12, -0.12, -0.03), "codo_i": v(-0.3, 0, -1),
                   "punta_d_w": 1.0, "punta_d": (0.8, 0.5), "punta_i_w": 1.0, "punta_i": (0.8, -0.5),
                   "pecho": v(0, 6, 0), "cabeza": v(0, 4, 0)}),
            (1.6, {"cadera": v(0.02, -0.025, 0), "pecho": v(0, 9, 0), "columna": v(0, 4, 0), "cabeza": v(0, 2, 0),
                   "mano_d": v(0.13, -0.14, 0.03), "mano_i": v(0.13, -0.14, -0.03)}),
            (2.6, {"cadera": v(0.02, -0.03, 0), "pecho": v(0, 8, 0), "cabeza": v(6, 0, 0)}),
            (3.4, {"cadera": v(0.02, -0.028, 0), "pecho": v(0, 9, 0), "cabeza": v(-6, 2, 0)}),
            (4.2, {"cadera": v(0.0, -0.01, 0), "pecho": v(0, 4, 0), "cabeza": v(0, 0, 0), "mano_d_w": 1.0,
                   "mano_i_w": 1.0, "punta_d_w": 1.0, "punta_i_w": 1.0}),
            (5.0, {"mano_d_w": 0.0, "mano_i_w": 0.0, "punta_d_w": 0.0, "punta_i_w": 0.0, "pecho": CERO, "cadera": CERO}),
            (5.6, {}),
        ],
    },
}

NEUTROS = {}

LADOS = (("Left", "i"), ("Right", "d"))


# ---------------------------------------------------------------- resolver un fotograma

class Resolutor:
    def __init__(self, pj, heroe):
        self.pj = pj
        self.heroe = heroe
        b = pj.base
        c = b.cabezas()
        self.c0 = {k: x.copy() for k, x in c.items()}
        self.suelo = min(c[b.h(n)].dot(pj.U) for n in ("LeftToe_End", "RightToe_End", "LeftToeBase", "RightToeBase")
                         if b.h(n) in c) - 0.02 * pj.k
        # polos de las rodillas en la pose base
        self.polo_pierna = {}
        for lado, s in LADOS:
            a = c[b.h(lado + "UpLeg")]; m = c[b.h(lado + "Leg")]; e = c[b.h(lado + "Foot")]
            d = (e - a).normalized()
            pp = (m - a) - d * (m - a).dot(d)
            self.polo_pierna[lado] = pp.normalized() if pp.length > 1e-6 else pj.A
        # direcciones de las armas en la pose base
        self.armas = {}
        for lado, conf in ARMAS.get(heroe, {}).items():
            if conf["base"] == "hueso":
                db = self.dir_hueso(b, lado)
            else:
                db = pj.ch(conf["base"]).normalized()
            self.armas[lado] = dict(conf, dir0=db)

    def anclaje(self, p, lado):
        conf = self.armas[lado]
        c = p.cabezas()
        mano = c[p.h(lado + "Hand")]; medio = c[p.h(lado + "HandMiddle1")]
        if conf["anclaje"] == "garon":
            return mano.lerp(medio, 0.75)
        return (mano + medio) * 0.5

    def dir_hueso(self, p, lado):
        c = p.cabezas()
        mano = c[p.h(lado + "Hand")]; medio = c[p.h(lado + "HandMiddle1")]
        filo = medio - mano
        if p.h(lado + "HandIndex1") in c and p.h(lado + "HandPinky1") in c:
            hoja = c[p.h(lado + "HandIndex1")] - c[p.h(lado + "HandPinky1")]
        else:
            pul = c[p.h(lado + "HandThumb1")] - mano
            f = filo.normalized()
            hoja = pul - f * pul.dot(f)
        return hoja.normalized()

    def dir_arma(self, p, lado):
        return p.dir_arma(lado + "Hand", self.armas[lado]["dir0"])

    def pose(self, cv, t):
        pj = self.pj
        p = pj.base.copia()
        val = lambda n, d=CERO: cv.valor(n, t, d)
        # 1. cadera y tronco
        p.mover_cadera(val("cadera"))
        p.girar_ejes("Hips", *val("cadera_g"))
        for hueso, ctrl in (("Spine", "columna"), ("Spine1", "columna1"), ("Spine2", "pecho"), ("Neck", "cuello"),
                            ("Head", "cabeza")):
            g = val(ctrl)
            if any(g):
                p.girar_ejes(hueso, *g)
        Rc = p.rot[p.h("Spine2")] @ pj.base.rot[p.h("Spine2")].transposed()
        # 2. hombros y brazos sin IK
        for lado, s in LADOS:
            for hueso, ctrl in ((lado + "Shoulder", "hombro_" + s), (lado + "Arm", "brazo_" + s + "_g"),
                                (lado + "ForeArm", "antebrazo_" + s + "_g")):
                g = val(ctrl)
                if any(g):
                    p.girar_ejes(hueso, *g)
        # 3. brazos con IK, manos y armas (primero la derecha: la izquierda puede agarrar su arma)
        for lado, s in (("Right", "d"), ("Left", "i")):
            w = val("mano_%s_w" % s, 0.0)
            if w > 0.001:
                c = p.cabezas()
                hombro = c[p.h(lado + "Arm")]; codo = c[p.h(lado + "ForeArm")]; mano = c[p.h(lado + "Hand")]
                obj = hombro + Rc @ pj.ch(val("mano_" + s)) * pj.k
                if s == "i" and val("mano_i_en_arma_w", 0.0) > 0.001 and "Right" in self.armas:
                    we = val("mano_i_en_arma_w", 0.0)
                    agarre = self.anclaje(p, "Right") + self.dir_arma(p, "Right") * val("mano_i_en_arma", 0.0) * pj.k
                    # la muñeca queda un poco antes del agarre (la palma está entre la muñeca y el dedo corazón)
                    palma = (c[p.h("LeftHandMiddle1")] - mano) * 0.5
                    obj = obj.lerp(agarre - palma, we)
                obj = mano.lerp(obj, w)
                dl = (mano - hombro).normalized()
                polo = (codo - hombro) - dl * (codo - hombro).dot(dl)
                if "codo_" + s in cv.canales:
                    pc = Rc @ pj.ch(val("codo_" + s)).normalized()
                    polo = polo.normalized().lerp(pc, min(w, 1.0)) if polo.length > 1e-6 else pc
                p.ik(lado + "Arm", lado + "ForeArm", lado + "Hand", obj, polo)
            g = val("mano_%s_g" % s)
            if any(g):
                p.girar_ejes(lado + "Hand", *g)
            if lado in self.armas:
                wa = val("arma_%s_w" % s, 0.0)
                if wa > 0.001:
                    p.orientar_arma(lado + "Hand", self.armas[lado]["dir0"], Rc @ pj.ch(val("arma_" + s)), wa)
                wp = val("punta_%s_w" % s, 0.0)
                if wp > 0.001:
                    a_, d_ = val("punta_" + s, (0.0, 0.0))
                    hz = (pj.A * a_ + pj.D * d_).normalized()
                    anc = self.anclaje(p, lado)
                    alto = anc.dot(pj.U) - self.suelo
                    lt = self.armas[lado]["largo"] * pj.k
                    ca = min(1.0, max(0.0, alto / lt))
                    meta = hz * math.sqrt(max(0.0, 1 - ca * ca)) - pj.U * ca
                    p.orientar_arma(lado + "Hand", self.armas[lado]["dir0"], meta, wp)
            dd = val("dedos_" + s, 0.0)
            if abs(dd) > 0.01:
                p.curvar_dedos(lado, dd)
        # 4. piernas: los pies, donde estaban (más su desplazamiento) y con su giro
        for lado, s in LADOS:
            obj = self.c0[p.h(lado + "Foot")] + pj.ch(val("pie_" + s)) * pj.k
            p.ik(lado + "UpLeg", lado + "Leg", lado + "Foot", obj, self.polo_pierna[lado])
            pie = p.h(lado + "Foot")
            p.girar(pie, (pj.base.rot[pie] @ p.rot[pie].transposed()))
            g = val("pie_%s_g" % s)
            if any(g):
                p.girar_ejes(lado + "Foot", *g)
        return p


# ---------------------------------------------------------------- hornear, comprobar y exportar

def hornear(pj, heroe, nombre, claves):
    cv = L.Curvas(claves, NEUTROS)
    res = Resolutor(pj, heroe)
    n = int(round(cv.duracion * FPS))
    arm = pj.arm
    arm.animation_data_create()
    act = bpy.data.actions.new(nombre)
    act.use_fake_user = True
    arm.animation_data.action = act
    anterior = {}
    peor_pie = 0.0
    peor_ext = 0.0
    for f in range(n + 1):
        p = res.pose(cv, f / FPS)
        p.claves(f, anterior)
        c = p.cabezas()
        for lado, s in LADOS:
            obj = res.c0[p.h(lado + "Foot")] + pj.ch(cv.valor("pie_" + s, f / FPS, CERO)) * pj.k
            peor_pie = max(peor_pie, (c[p.h(lado + "Foot")] - obj).length)
    # el primer y el último fotograma son la pose base: la mezcla con el reposo del juego es limpia
    b = pj.base.bases()
    p0 = res.pose(cv, 0.0).bases()
    pn = res.pose(cv, n / FPS).bases()
    for k in b:
        peor_ext = max(peor_ext, b[k][0].rotation_difference(p0[k][0]).angle, b[k][0].rotation_difference(pn[k][0]).angle)
    for fc in _fcurves(act):
        for kp in fc.keyframe_points:
            kp.interpolation = 'LINEAR'                  # cada fotograma ya está resuelto
    print("CLIP %s %s: %d fotogramas (%.2f s); pie fuera de su sitio como mucho %.4f; extremos frente a la base %.3f°"
          % (heroe, nombre, n + 1, n / FPS, peor_pie, math.degrees(peor_ext)))
    return act


def _fcurves(act):
    if hasattr(act, "fcurves") and len(act.fcurves):
        return list(act.fcurves)
    r = []
    for capa in getattr(act, "layers", []):
        for tira in capa.strips:
            for cb in tira.channelbags:
                r += list(cb.fcurves)
    return r


def malla_minima(pj):
    # el GLB solo lleva la animación: una malla de un triángulo pegada a la cadera hace que lleve la piel (los huesos)
    for m in pj.mallas:
        bpy.data.objects.remove(m, do_unlink=True)
    me = bpy.data.meshes.new("piel")
    me.from_pydata([(0, 0, 0), (0.01, 0, 0), (0, 0.01, 0)], [], [(0, 1, 2)])
    ob = bpy.data.objects.new("piel", me)
    bpy.context.scene.collection.objects.link(ob)
    ob.parent = pj.arm
    vg = ob.vertex_groups.new(name=L.P + "Hips")
    vg.add([0, 1, 2], 1.0, 'REPLACE')
    mod = ob.modifiers.new("Armature", 'ARMATURE')
    mod.object = pj.arm


def exportar(ruta):
    props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
    op = dict(filepath=ruta, export_format='GLB', export_animations=True, export_force_sampling=True,
              export_animation_mode='ACTIONS', export_materials='NONE', export_yup=True)
    if "export_optimize_animation_size" in props:
        op["export_optimize_animation_size"] = False
    if "export_def_bones" in props:
        op["export_def_bones"] = False
    if "export_anim_slide_to_zero" in props:
        op["export_anim_slide_to_zero"] = True
    bpy.ops.export_scene.gltf(**op)
    print("GLB", ruta, os.path.getsize(ruta))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    heroe, fbx, captura, salida = argv[:4]
    solo = None
    for a in argv[4:]:
        if a.startswith("solo="):
            solo = a[5:]
    bpy.context.scene.render.fps = FPS
    pj = L.Personaje(fbx, captura)
    acciones = []
    for nombre, claves in CLIPS[heroe].items():
        if solo and nombre != solo:
            continue
        acciones.append(hornear(pj, heroe, nombre, claves))
    pj.arm.animation_data.action = None
    pj.base.aplicar()
    malla_minima(pj)
    exportar(salida)


if __name__ == "__main__":
    main()
