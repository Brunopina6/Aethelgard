# Poses de Lya para los retratos de diálogo (T-084, tanda 2). Todas parten del reposo de su retrato original lya.png:
# el clip quieto «_01a19663» (fotograma 20) con los brazos bajados como el gesto «reposo» del juego (gestos_3d.gd: el
# brazo hacia abajo, un poco adelante y afuera; el antebrazo adelante y abajo). Con la cámara girada +14° y 6° hacia
# abajo, la silueta coincide con la del original en un 98,4 % (buscar_lya: IoU).
# Ejes del mundo de Blender: el personaje mira a -Y; su derecha es -X; arriba, +Z. En el diálogo Lya está a la
# derecha de la pantalla y Kael a la izquierda: hacia Kael es hacia la derecha de Lya (-X).
import bpy, math, mathutils
from mathutils import Vector, Quaternion
import escena as E, pose as PO

ADELANTE = Vector((0, -1, 0)); DERECHA = Vector((-1, 0, 0)); ARRIBA = Vector((0, 0, 1))
# gestos_3d.gd, GESTOS["reposo"]: hueso → [dirección (adelante, arriba, derecha), ángulo máximo]
REPOSO_JUEGO = {"LeftArm": ((0.12, -1, -0.2), 80), "LeftForeArm": ((0.45, -1, 0.05), 80),
                "RightArm": ((0.12, -1, 0.2), 80), "RightForeArm": ((0.45, -1, -0.05), 80)}


def _dir(v):
    return (ADELANTE * v[0] + ARRIBA * v[1] + DERECHA * v[2]).normalized()


def brazos_reposo(arm):
    # lo mismo que hace el juego: cada hueso gira hacia su dirección, como mucho su ángulo máximo
    for h in ["LeftArm", "LeftForeArm", "RightArm", "RightForeArm"]:
        pb = arm.pose.bones[PO.P + h]
        R = PO.rot_mundo(arm, pb)
        actual = R.col[1].normalized()
        meta = _dir(REPOSO_JUEGO[h][0])
        ang = min(actual.angle(meta), math.radians(REPOSO_JUEGO[h][1]))
        eje = actual.cross(meta)
        if eje.length < 1e-6:
            continue
        PO.poner_rot_mundo(arm, pb, Quaternion(eje.normalized(), ang).to_matrix() @ R)


def base(arm):
    E.poner_clip(arm, '_01a19663', 20)
    E.congelar(arm)
    brazos_reposo(arm)


def reposo(arm):
    base(arm)


def puno(arm, lado, grados=75, pulgar=35):
    PO.curvar_dedos(arm, lado, grados, (1, 0, 0), pulgar=pulgar)


# Proporciones del modelo (medidas en Blender y en sus renders, metros): cadera 1,07; pecho ~1,15-1,22; articulación del
# hombro 1,26; barbilla ~1,31; boca ~1,35; ojos ~1,41 (ahí empieza el hueso Head: la cabeza es grande, de estilo anime);
# coronilla 1,70. Del hombro a la muñeca, 0,35 m; la mano (hueso Hand), 0,14. Delante del vestido es y < -0,22.
# Las manos del modelo no se cierran (los dedos no van pesados a sus huesos: solo hay pulgar y una cadena «Middle», y
# no deforman), así que sus gestos son con la mano abierta. Los objetivos se dan respecto a sus huesos.
def _pecho(arm):
    return PO.cabeza_mundo(arm, "Spine1")               # (x ~0, y -0,14, z 1,22): el centro del pecho


def _mano_hacia(arm, lado, punta, direccion, polo):
    # la punta de los dedos en «punta» y la mano apuntando a «direccion» (la muñeca, 0,14 m más atrás)
    d = Vector(direccion).normalized()
    PO.ik_brazo(arm, lado, punta - d * 0.14, polo)
    PO.apuntar(arm, lado + "Hand", d)


def preocupada(arm):
    # las manos cruzadas sobre el pecho, los codos abajo, la cabeza un poco baja y ladeada hacia Kael: preocupada por
    # lo que cuenta o por él
    base(arm)
    p = _pecho(arm)
    for lado, s, alto in (("Right", -1, 0.0), ("Left", 1, -0.015)):
        hombro = PO.cabeza_mundo(arm, lado + "Arm")
        objetivo = Vector((p.x + 0.025 * s, p.y - 0.13, p.z - 0.075 + alto))
        polo = hombro + Vector((0.12 * s, 0.12, -0.35))
        PO.ik_brazo(arm, lado, objetivo, polo)
        PO.apuntar(arm, lado + "Hand", ARRIBA * 0.55 + ADELANTE * 0.25 + DERECHA * (0.75 * s))
    PO.girar(arm, "Head", DERECHA, -6)
    PO.girar(arm, "Head", ADELANTE, 6)
    PO.girar(arm, "Spine2", DERECHA, -2)


def decidida(arm):
    # la mano derecha abierta sobre el pecho, como quien se compromete; el pecho fuera y la barbilla un poco arriba
    base(arm)
    p = _pecho(arm)
    hombro = PO.cabeza_mundo(arm, "RightArm")
    punta = Vector((p.x + 0.02, p.y - 0.115, p.z - 0.04))
    _mano_hacia(arm, "Right", punta, ARRIBA * 0.55 - DERECHA * 0.8 + ADELANTE * 0.1, hombro + Vector((-0.2, 0.05, -0.3)))
    PO.girar(arm, "Spine2", DERECHA, 3)
    PO.girar(arm, "Head", DERECHA, 5)
    PO.girar(arm, "Head", ADELANTE, 3)


def duda(arm):
    # la punta de los dedos en la barbilla (la muñeca delante del pecho y la mano subiendo hacia la cara), el otro
    # brazo cruzado por la cintura bajo el codo y la cabeza ladeada hacia Kael
    base(arm)
    cabeza = PO.cabeza_mundo(arm, "Head")
    hombro_d = PO.cabeza_mundo(arm, "RightArm")
    barbilla = Vector((cabeza.x - 0.025, cabeza.y - 0.115, cabeza.z - 0.105))
    _mano_hacia(arm, "Right", barbilla, ARRIBA * 0.85 - ADELANTE * 0.45 - DERECHA * 0.15,
                hombro_d + Vector((0.05, -0.15, -0.45)))
    hombro_i = PO.cabeza_mundo(arm, "LeftArm")
    sosten = Vector((cabeza.x - 0.01, -0.24, 1.03))
    PO.ik_brazo(arm, "Left", sosten, hombro_i + Vector((0.3, 0.0, -0.3)))
    PO.apuntar(arm, "LeftHand", DERECHA * 0.95 + ADELANTE * 0.25)
    PO.girar(arm, "Head", ADELANTE, 8)
    PO.girar(arm, "Head", DERECHA, -3)


# En el juego: reposo → lya_reposo.png, preocupada → lya_preocupada.png («inquieta» y «preocupada»), decidida →
# lya_decidida.png y duda → lya_duda.png; «control» es el reposo original re-renderizado (para el color).
POSES = {"control": base, "reposo": reposo, "preocupada": preocupada, "decidida": decidida, "duda": duda}
