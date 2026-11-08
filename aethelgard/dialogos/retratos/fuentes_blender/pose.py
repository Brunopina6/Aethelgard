# Herramientas de pose para el esqueleto Mixamo de Meshy: espejo de un brazo, IK de mano con polo, giros y dedos.
import bpy, math, mathutils
from mathutils import Matrix, Vector, Quaternion

P = "mixamorig:"
DEDOS = ["Thumb", "Index", "Middle", "Ring", "Pinky"]
S = Matrix.Diagonal((-1.0, 1.0, 1.0))

def actualizar():
    bpy.context.view_layer.update()

def rot_mundo(arm, pb):
    return (arm.matrix_world @ pb.matrix).to_3x3().normalized()

def rest_mundo(arm, nombre):
    b = arm.data.bones[nombre]
    return (arm.matrix_world.to_3x3() @ b.matrix_local.to_3x3()).normalized()

def poner_rot_mundo(arm, pb, R):
    # cambia solo la orientación del hueso (la cabeza se queda donde la pone su padre)
    mw3 = arm.matrix_world.to_3x3()
    cabeza = pb.matrix.to_translation()
    Ra = (mw3.inverted() @ R).normalized()
    pb.matrix = Matrix.Translation(cabeza) @ Ra.to_4x4()
    actualizar()

def flip_local(arm, izq, der):
    # S_b tal que rest_der ≈ S · rest_izq · S_b, redondeada a la matriz de signos más cercana
    Rl = rest_mundo(arm, izq); Rr = rest_mundo(arm, der)
    Sb = (S @ Rl).inverted() @ Rr
    D = Matrix.Diagonal(tuple(1.0 if Sb[i][i] >= 0 else -1.0 for i in range(3)))
    return D, Sb

def cadena_brazo(lado, dedos=True):
    n = [P + lado + "Shoulder", P + lado + "Arm", P + lado + "ForeArm", P + lado + "Hand"]
    if dedos:
        for d in DEDOS:
            for i in range(1, 4):
                n.append(P + lado + "Hand" + d + str(i))
    return n

def espejo_brazo(arm, origen="Left", destino="Right", dedos=True, giro_cuerpo=None):
    # copia la pose de un brazo en el otro, como en un espejo respecto al plano medio del cuerpo
    # (giro_cuerpo: matriz 3x3 del pecho; el espejo se hace en su sistema para que el brazo siga al torso)
    G = giro_cuerpo if giro_cuerpo is not None else Matrix.Identity(3)
    Sg = G @ S @ G.inverted()
    for n_o, n_d in zip(cadena_brazo(origen, dedos), cadena_brazo(destino, dedos)):
        if n_o not in arm.pose.bones or n_d not in arm.pose.bones:
            continue
        D, _ = flip_local(arm, n_o, n_d)
        Ro = rot_mundo(arm, arm.pose.bones[n_o])
        Rd = Sg @ Ro @ D
        poner_rot_mundo(arm, arm.pose.bones[n_d], Rd)

def girar(arm, nombre, eje, grados):
    # gira el hueso alrededor de un eje del mundo (pasa por su cabeza)
    pb = arm.pose.bones[P + nombre]
    R = rot_mundo(arm, pb)
    q = Quaternion(Vector(eje).normalized(), math.radians(grados))
    poner_rot_mundo(arm, pb, q.to_matrix() @ R)

def girar_local(arm, nombre, eje_local, grados):
    pb = arm.pose.bones[P + nombre]
    R = rot_mundo(arm, pb)
    eje = R @ Vector(eje_local)
    q = Quaternion(eje.normalized(), math.radians(grados))
    poner_rot_mundo(arm, pb, q.to_matrix() @ R)

def apuntar(arm, nombre, direccion, giro=0.0):
    # orienta el eje Y del hueso hacia «direccion» (mundo) con el giro mínimo; «giro» = vuelta extra sobre el hueso
    pb = arm.pose.bones[P + nombre]
    R = rot_mundo(arm, pb)
    y = R.col[1]
    q = y.rotation_difference(Vector(direccion).normalized())
    R2 = q.to_matrix() @ R
    if giro:
        R2 = Quaternion(R2.col[1], math.radians(giro)).to_matrix() @ R2
    poner_rot_mundo(arm, pb, R2)

def cabeza_mundo(arm, nombre):
    return arm.matrix_world @ arm.pose.bones[P + nombre].head

def cola_mundo(arm, nombre):
    return arm.matrix_world @ arm.pose.bones[P + nombre].tail

def ik_brazo(arm, lado, objetivo, polo):
    # brazo de dos huesos: el codo hacia «polo», la muñeca en «objetivo» (todo en el mundo)
    a = cabeza_mundo(arm, lado + "Arm")
    l1 = (cola_mundo(arm, lado + "Arm") - a).length
    l2 = (cola_mundo(arm, lado + "ForeArm") - cabeza_mundo(arm, lado + "ForeArm")).length
    t = Vector(objetivo)
    d = t - a
    L = min(d.length, (l1 + l2) * 0.999)
    d = d.normalized()
    # ángulo en el hombro (ley de los cosenos)
    cos_a = (l1 * l1 + L * L - l2 * l2) / (2 * l1 * L)
    ang = math.acos(max(-1.0, min(1.0, cos_a)))
    p = Vector(polo) - a
    p_perp = (p - d * p.dot(d)).normalized()
    codo = a + (d * math.cos(ang) + p_perp * math.sin(ang)) * l1
    apuntar(arm, lado + "Arm", codo - a)
    apuntar(arm, lado + "ForeArm", (a + d * L) - codo)
    return codo

def curvar_dedos(arm, lado, grados, eje_local=(1, 0, 0), pulgar=None, dedos=None):
    for d in (dedos or DEDOS):
        g = pulgar if (d == "Thumb" and pulgar is not None) else grados
        for i in range(1, 4):
            n = lado + "Hand" + d + str(i)
            if P + n in arm.pose.bones:
                girar_local(arm, n, eje_local, g)
