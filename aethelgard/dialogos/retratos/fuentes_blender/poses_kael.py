# Poses de Kael para los retratos de diálogo (todas parten del reposo del retrato original, fotograma 5 de «_01a19b86»).
# Ejes del mundo de Blender: el personaje mira a -Y; su derecha es -X; arriba, +Z.
import bpy, math
from mathutils import Vector, Matrix
import escena as E, pose as PO

ADELANTE = Vector((0, -1, 0)); DERECHA = Vector((-1, 0, 0)); ARRIBA = Vector((0, 0, 1))

def base(arm):
    E.poner_clip(arm, '_01a19b86', 5)
    E.congelar(arm)

def giro_pecho(arm):
    pb = arm.pose.bones[PO.P + "Spine2"]
    return PO.rot_mundo(arm, pb) @ PO.rest_mundo(arm, PO.P + "Spine2").inverted()

def doblar_codo(arm, lado, grados):
    # dobla el codo hacia delante (gira el antebrazo alrededor del eje lateral del codo)
    a = PO.cabeza_mundo(arm, lado + "Arm"); c = PO.cabeza_mundo(arm, lado + "ForeArm")
    eje = (c - a).cross(ADELANTE).normalized()
    s = 1 if lado == "Right" else -1
    PO.girar(arm, lado + "ForeArm", eje * s, grados)
    PO.girar(arm, lado + "Hand", eje * s, grados * 0.3)

def reposo(arm):
    base(arm)
    PO.espejo_brazo(arm, "Left", "Right", True, giro_pecho(arm))

def puno(arm, lado, grados=75, pulgar=35):
    PO.curvar_dedos(arm, lado, grados, (1, 0, 0), pulgar=pulgar)

def broma(arm):
    # el puño apoyado en la cadera, el codo hacia fuera; la cabeza un poco ladeada
    reposo(arm)
    hombro = PO.cabeza_mundo(arm, "RightArm")
    cadera = PO.cabeza_mundo(arm, "RightUpLeg")
    objetivo = Vector((cadera.x - 0.075, cadera.y + 0.01, cadera.z + 0.13))
    polo = hombro + DERECHA * 0.4 + Vector((0, 0.15, -0.05))
    PO.ik_brazo(arm, "Right", objetivo, polo)
    PO.apuntar(arm, "RightHand", ADELANTE * 0.35 + ARRIBA * -0.9 + DERECHA * -0.35)
    puno(arm, "Right", 70, 30)
    PO.girar(arm, "Head", ADELANTE, -7)
    PO.girar(arm, "Spine2", ADELANTE, 3)

def brazalete(arm):
    # levanta el antebrazo izquierdo delante del pecho y mira el brazalete
    reposo(arm)
    hombro = PO.cabeza_mundo(arm, "LeftArm")
    objetivo = hombro + Vector((-0.06, -0.17, -0.10))
    polo = hombro + Vector((0.25, 0.05, -0.25))
    PO.ik_brazo(arm, "Left", objetivo, polo)
    PO.apuntar(arm, "LeftHand", DERECHA * 0.9 + ADELANTE * 0.3 + ARRIBA * 0.1)
    PO.girar(arm, "Head", DERECHA, -14)
    PO.girar(arm, "Neck", ARRIBA, -8)

def decidido(arm):
    # el puño derecho cerrado delante del pecho (por debajo del hombro: nada de manos junto a la cabeza), el codo abajo
    reposo(arm)
    hombro = PO.cabeza_mundo(arm, "RightArm")
    objetivo = hombro + Vector((0.05, -0.15, -0.13))
    polo = hombro + Vector((-0.2, 0.05, -0.35))
    PO.ik_brazo(arm, "Right", objetivo, polo)
    PO.apuntar(arm, "RightHand", ARRIBA * 0.7 + ADELANTE * 0.6 + DERECHA * -0.2)
    puno(arm, "Right", 80, 40)
    PO.girar(arm, "Head", DERECHA, 4)
    PO.girar(arm, "Spine2", DERECHA, -2)

def sorpresa(arm):
    # un respingo: los antebrazos se levantan un poco con las manos abiertas y la cabeza va atrás
    reposo(arm)
    doblar_codo(arm, "Right", 45)
    doblar_codo(arm, "Left", 45)
    PO.curvar_dedos(arm, "Right", -12, (1, 0, 0), pulgar=0)
    PO.curvar_dedos(arm, "Left", -12, (1, 0, 0), pulgar=0)
    PO.girar(arm, "Head", DERECHA, 7)
    PO.girar(arm, "Spine2", DERECHA, 3)

# En el juego: broma → kael_mano_cadera.png (gesto «ligero») y decidido → kael_puno.png; «control» es el reposo original.
POSES = {"control": base, "reposo": reposo, "broma": broma, "brazalete": brazalete, "decidido": decidido, "sorpresa": sorpresa}
