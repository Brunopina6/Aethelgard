# Héroes v2 (fase B, V12): rig común para Kael, Lya y Garon.
#
# Los tres modelos de Meshy llevan el mismo esqueleto Mixamo (mismos nombres de hueso, pose de reposo en T), pero con
# proporciones distintas (cabezas chibi, brazos y piernas de largos distintos). Para que una sola biblioteca de clips
# sirva a los tres, una pose NO se escribe como giros locales de hueso (que dependen de cada esqueleto), sino como
# objetivos en el espacio del personaje:
#   - cadera: desplazamiento (m, escalado a la altura) y giros (inclinar, ladear, girar, en grados);
#   - columna, cuello y cabeza: giros en grados repartidos por la cadena;
#   - manos: posición respecto al hombro en largos de brazo, dirección del codo, de los dedos y de la palma, y cierre
#     de los dedos (IK de dos huesos);
#   - pies: apoyados donde están en la pose de reposo, salvo un desplazamiento (IK de dos huesos, con la rodilla
#     hacia delante); el pie y los dedos quedan paralelos al suelo salvo que se pida otra cosa.
# Luego se guarda la pose de cada hueso como clave (cuaternión; la cadera también posición).
#
# Ejes del mundo de Blender tras importar el FBX: el personaje mira a -Y, su derecha es -X y arriba es +Z.
import bpy, math
from mathutils import Vector, Matrix, Quaternion

P = "mixamorig:"
ADEL = Vector((0.0, -1.0, 0.0))
DER = Vector((-1.0, 0.0, 0.0))
ARR = Vector((0.0, 0.0, 1.0))
DEDOS = ["Thumb", "Index", "Middle", "Ring", "Pinky"]


def q_inclinar(g):      # g > 0: la parte de arriba va hacia delante
    return Quaternion(Vector((1, 0, 0)), math.radians(g))


def q_ladear(g):        # g > 0: la parte de arriba va hacia la derecha del personaje
    return Quaternion(ADEL, math.radians(g))


def q_girar(g):         # g > 0: gira hacia la derecha del personaje (visto desde arriba)
    return Quaternion(ARR, -math.radians(g))


def q_giros(v):
    # v = (inclinar, ladear, girar) en grados; se aplica primero el giro, luego ladear y luego inclinar
    v = tuple(v) + (0.0,) * (3 - len(v))
    return q_inclinar(v[0]) @ q_ladear(v[1]) @ q_girar(v[2])


def importar_fbx(ruta):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=ruta)
    arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
    mallas = [o for o in bpy.data.objects if o.type == 'MESH']
    return arm, mallas


class Rig:
    def __init__(self, arm):
        self.arm = arm
        self.pb = arm.pose.bones
        bpy.context.view_layer.objects.active = arm
        if arm.animation_data is not None:
            arm.animation_data.action = None
        for pb in self.pb:
            pb.rotation_mode = 'QUATERNION'
        self.reset()
        mw = arm.matrix_world
        self.mw = mw.copy()
        self.mwi = mw.inverted()
        self.rest = {}
        for b in arm.data.bones:
            m = mw @ b.matrix_local
            self.rest[b.name] = (m.to_translation(), mw @ b.tail_local, m.to_3x3().normalized())
        suelo = min(self.rest[P + n][0].z for n in ["LeftToeBase", "RightToeBase"])
        cima = self.rest[P + "HeadTop_End"][0].z
        self.altura = cima - suelo
        self.h = self.altura / 1.7                      # escala de las distancias de la biblioteca (escrita para 1,7 m)
        self.suelo = suelo
        self.largo_brazo = {}
        self.largo_pierna = {}
        self.palma_local = {}
        self.dedos_local = {}
        for lado in ["Left", "Right"]:
            a = self.rest[P + lado + "Arm"][0]; f = self.rest[P + lado + "ForeArm"][0]; m = self.rest[P + lado + "Hand"][0]
            self.largo_brazo[lado] = (f - a).length + (m - f).length
            u = self.rest[P + lado + "UpLeg"][0]; r = self.rest[P + lado + "Leg"][0]; p = self.rest[P + lado + "Foot"][0]
            self.largo_pierna[lado] = (r - u).length + (p - r).length
            R = self.rest[P + lado + "Hand"][2]
            # en la pose en T la palma mira abajo y los dedos hacia fuera
            self.palma_local[lado] = (R.inverted() @ Vector((0, 0, -1))).normalized()
            fuera = DER if lado == "Right" else -DER
            self.dedos_local[lado] = (R.inverted() @ fuera).normalized()
        self.cadera0 = self.rest[P + "Hips"][0].copy()
        # huesos de arma (crear_hueso_arma): su giro respecto a la mano en reposo
        self.arma_rel = {}
        for lado, n in [("Right", "arma_d"), ("Left", "arma_i")]:
            if n in self.rest:
                self.arma_rel[lado] = (self.rest[P + lado + "Hand"][2].inverted() @ self.rest[n][2]).normalized()
    # ------------------------------------------------------------------ básicos
    def reset(self):
        for pb in self.pb:
            pb.matrix_basis = Matrix.Identity(4)
        bpy.context.view_layer.update()

    def upd(self):
        bpy.context.view_layer.update()

    def tiene(self, n):
        return (P + n) in self.pb

    def R(self, n):
        return (self.mw @ self.pb[P + n].matrix).to_3x3().normalized()

    def cabeza(self, n):
        return self.mw @ self.pb[P + n].head

    def cola(self, n):
        return self.mw @ self.pb[P + n].tail

    def poner(self, nombre, R, cabeza=None, completo=False):
        pb = self.pb[nombre if completo else P + nombre]
        c = (self.mw @ pb.head) if cabeza is None else cabeza
        m = self.mwi @ (Matrix.Translation(c) @ R.to_4x4())
        pb.matrix = m
        self.upd()

    def girar_mundo(self, n, q):
        if not self.tiene(n):
            return
        self.poner(n, q.to_matrix() @ self.R(n))

    def apuntar(self, n, direccion, giro=0.0):
        R = self.R(n)
        y = R.col[1]
        q = y.rotation_difference(direccion.normalized())
        R2 = q.to_matrix() @ R
        if giro:
            R2 = Quaternion(R2.col[1], math.radians(giro)).to_matrix() @ R2
        self.poner(n, R2)

    # ------------------------------------------------------------------ IK de dos huesos
    def ik(self, h1, h2, objetivo, polo):
        a = self.cabeza(h1)
        l1 = (self.cola(h1) - a).length
        l2 = (self.cola(h2) - self.cabeza(h2)).length
        d = objetivo - a
        L = min(d.length, (l1 + l2) * 0.999)
        L = max(L, abs(l1 - l2) * 1.05 + 1e-4)
        d.normalize()
        cos_a = (l1 * l1 + L * L - l2 * l2) / (2 * l1 * L)
        ang = math.acos(max(-1.0, min(1.0, cos_a)))
        p = polo - d * polo.dot(d)
        if p.length < 1e-6:
            p = ADEL - d * ADEL.dot(d)
        p.normalize()
        codo = a + (d * math.cos(ang) + p * math.sin(ang)) * l1
        self.apuntar(h1, codo - a)
        self.apuntar(h2, (a + d * L) - codo)

    # ------------------------------------------------------------------ pose completa
    def aplicar(self, d):
        """d: descripción de la pose (ver biblioteca_clips.py). Deja el esqueleto en esa pose."""
        self.reset()
        h = self.h
        # cadera
        off = Vector(d.get("cadera", (0, 0, 0)))          # (adelante, arriba, derecha) en metros para 1,7 m
        pos = self.cadera0 + (ADEL * off[0] + ARR * off[1] + DER * off[2]) * h
        qc = q_giros(d.get("cadera_giro", (0, 0, 0)))
        self.poner("Hips", qc.to_matrix() @ self.R("Hips"), pos)
        # columna: el giro se reparte entre Spine, Spine1 y Spine2
        col = d.get("columna", (0, 0, 0))
        reparto = d.get("reparto_columna", (0.3, 0.35, 0.35))
        for n, f in zip(["Spine", "Spine1", "Spine2"], reparto):
            self.girar_mundo(n, q_giros(tuple(c * f for c in col) + (0,) * (3 - len(col))))
        self.girar_mundo("Neck", q_giros(d.get("cuello", (0, 0, 0))))
        self.girar_mundo("Head", q_giros(d.get("cabeza", (0, 0, 0))))
        # «mirada»: grados que mira hacia abajo respecto al horizonte, se incline como se incline el cuerpo
        if d.get("mirada") is not None:
            f = (self.R("Head") @ self.rest[P + "Head"][2].inverted()) @ ADEL
            abajo = math.degrees(math.asin(max(-1.0, min(1.0, -f.z / max(f.length, 1e-6)))))
            eje = ARR.cross(f)
            if eje.length > 1e-5:
                q = Quaternion(eje.normalized(), math.radians(d["mirada"] - abajo))
                self.girar_mundo("Neck", Quaternion(eje.normalized(), math.radians((d["mirada"] - abajo) * 0.35)))
                f2 = (self.R("Head") @ self.rest[P + "Head"][2].inverted()) @ ADEL
                abajo2 = math.degrees(math.asin(max(-1.0, min(1.0, -f2.z / max(f2.length, 1e-6)))))
                self.girar_mundo("Head", Quaternion(eje.normalized(), math.radians(d["mirada"] - abajo2)))
        # pecho: el marco donde se escriben las manos
        Rpecho = self.R("Spine2") @ self.rest[P + "Spine2"][2].inverted()
        # hombros (encoger: grados hacia arriba; adelantar: grados hacia delante)
        for lado, s in [("Left", "_i"), ("Right", "_d")]:
            fuera = DER if lado == "Right" else -DER
            e = d.get("hombro" + s, (0, 0))
            if e[0] or e[1]:
                eje_arriba = Rpecho @ ADEL                          # subir el hombro: gira sobre el eje adelante
                sgn = 1 if lado == "Left" else -1
                q = Quaternion(eje_arriba, math.radians(e[0]) * sgn) @ Quaternion(Rpecho @ ARR, math.radians(e[1]) * -sgn)
                self.girar_mundo(lado + "Shoulder", q)
        # brazos
        for lado, s in [("Left", "_i"), ("Right", "_d")]:
            m = d.get("mano" + s)
            if m is None:
                continue
            fuera = DER if lado == "Right" else -DER
            L = self.largo_brazo[lado]
            ref = m.get("ref", "pecho")
            v = Vector(m["pos"])                                     # (adelante, arriba, fuera)
            local = ADEL * v[0] + ARR * v[1] + fuera * v[2]
            if ref == "pecho":
                obj = self.cabeza(lado + "Arm") + (Rpecho @ local) * L
            elif ref == "cadera":
                Rc = self.R("Hips") @ self.rest[P + "Hips"][2].inverted()
                obj = self.cabeza("Hips") + (Rc @ local) * h
            else:                                                     # «mundo»: desde el centro de los pies, en m
                base = Vector((self.cadera0.x, self.cadera0.y, self.suelo))
                obj = base + local * h
            pv = Vector(m.get("codo", (-0.3, -1.0, 0.5)))
            polo = Rpecho @ (ADEL * pv[0] + ARR * pv[1] + fuera * pv[2])
            self.ik(lado + "Arm", lado + "ForeArm", obj, polo)
            # mano con arma: se orienta para que la hoja vaya hacia «hoja» con el filo hacia «filo» (hueso arma_*)
            if "hoja" in m and lado in self.arma_rel:
                Rm = Rpecho if m.get("marco_mano", ref) != "mundo" else Matrix.Identity(3)
                hv = m["hoja"]; fv = m.get("filo", (1, 0, 0))
                Y = (Rm @ (ADEL * hv[0] + ARR * hv[1] + fuera * hv[2])).normalized()
                X = Rm @ (ADEL * fv[0] + ARR * fv[1] + fuera * fv[2])
                X = (X - Y * X.dot(Y))
                if X.length < 1e-4:
                    X = Y.orthogonal()
                X.normalize()
                Ra = Matrix((X, Y, X.cross(Y))).transposed()
                self.poner(lado + "Hand", Ra @ self.arma_rel[lado].inverted())
                self.dedos(lado, m.get("cierre", 75), m.get("pulgar", None))
                continue
            # mano: dirección de los dedos y de la palma
            dd = m.get("dedos")
            pa = m.get("palma")
            Rm = Rpecho if m.get("marco_mano", ref) != "mundo" else Matrix.Identity(3)
            if dd is not None:
                dv = Rm @ (ADEL * dd[0] + ARR * dd[1] + fuera * dd[2])
            else:
                dv = self.cola(lado + "ForeArm") - self.cabeza(lado + "ForeArm")
            self.apuntar(lado + "Hand", dv)
            if pa is not None:
                pv2 = (Rm @ (ADEL * pa[0] + ARR * pa[1] + fuera * pa[2])).normalized()
                Rh = self.R(lado + "Hand")
                y = Rh.col[1]
                pal = Rh @ self.palma_local[lado]
                a1 = pal - y * pal.dot(y); b1 = pv2 - y * pv2.dot(y)
                if a1.length > 1e-5 and b1.length > 1e-5:
                    ang = a1.normalized().angle(b1.normalized())
                    if a1.cross(b1).dot(y) < 0:
                        ang = -ang
                    self.poner(lado + "Hand", Quaternion(y, ang).to_matrix() @ Rh)
            self.dedos(lado, m.get("cierre", 15), m.get("pulgar", None))
        # piernas: pies apoyados (o desplazados) y rodillas hacia delante
        for lado, s in [("Left", "_i"), ("Right", "_d")]:
            fuera = DER if lado == "Right" else -DER
            p = d.get("pie" + s, {})
            off = Vector(p.get("pos", (0, 0, 0)))
            pie0 = self.rest[P + lado + "Foot"][0]
            gp = p.get("giro", 0.0)                          # gira el pie (punta hacia fuera, grados)
            obj = pie0 + (ADEL * off[0] + ARR * off[1] + fuera * off[2]) * h
            rv = p.get("rodilla", (1.0, 0.0, 0.25))
            polo = ADEL * rv[0] + ARR * rv[1] + fuera * rv[2]
            if gp:
                polo = Quaternion(ARR, math.radians(gp) * (-1 if lado == "Right" else 1)) @ polo
            self.ik(lado + "UpLeg", lado + "Leg", obj, polo)
            # pie paralelo al suelo (como en reposo), con la punta girada y el talón levantado si se pide
            Rpie = self.rest[P + lado + "Foot"][2]
            q = Quaternion(ARR, math.radians(gp) * (-1 if lado == "Right" else 1))
            punta = p.get("punta", 0.0)                       # grados: > 0 levanta el talón (de puntillas)
            eje = q @ DER
            q2 = Quaternion(eje, -math.radians(punta))
            self.poner(lado + "Foot", (q2 @ q).to_matrix() @ Rpie)
            if self.tiene(lado + "ToeBase"):
                Rt = self.rest[P + lado + "ToeBase"][2]
                dob = p.get("dedos_pie", punta)               # los dedos siguen en el suelo al ponerse de puntillas
                q3 = Quaternion(eje, -math.radians(punta - dob))
                self.poner(lado + "ToeBase", (q3 @ q).to_matrix() @ Rt)
        # huesos extra (armas, pelo…): los pone quien los tenga
        for fn in d.get("_extra", []):
            fn(self)

    def dedos(self, lado, grados, pulgar=None):
        """Cierra los dedos «grados» por falange (0 = abiertos, 80 = puño). Gira sobre el eje lateral de la mano."""
        Rh = self.R(lado + "Hand")
        pal = (Rh @ self.palma_local[lado]).normalized()
        y = Rh.col[1].normalized()
        eje = y.cross(pal).normalized()                   # doblar hacia la palma
        if lado == "Left":
            eje = -eje
        for dn in DEDOS:
            g = grados if dn != "Thumb" else (pulgar if pulgar is not None else grados * 0.45)
            for i in range(1, 4):
                n = lado + "Hand" + dn + str(i)
                if not self.tiene(n):
                    continue
                if dn == "Thumb":
                    e2 = (self.R(n).col[1]).cross(pal).normalized()
                    if lado == "Left":
                        e2 = -e2
                    self.girar_mundo(n, Quaternion(e2, math.radians(g * (0.6 if i == 1 else 1.0))))
                else:
                    self.girar_mundo(n, Quaternion(eje, math.radians(g * (0.8 if i == 1 else 1.0))))

    # ------------------------------------------------------------------ claves
    def huesos_clave(self):
        return [pb for pb in self.pb]

    def clave(self, frame, solo=None):
        for pb in self.pb:
            if solo is not None and pb.name not in solo:
                continue
            pb.keyframe_insert("rotation_quaternion", frame=frame, group=pb.name)
            if pb.name == P + "Hips" or pb.name.startswith("arma"):
                pb.keyframe_insert("location", frame=frame, group=pb.name)

def crear_hueso_arma(arm, lado, nombre, agarre_abajo=0.018):
    """Hueso «arma_d» / «arma_i», hijo de la mano: cabeza en el centro del puño, eje Y = hoja (hacia el lado del pulgar)
    y eje X = filo (hacia donde apuntan los dedos estirados). No deforma. El juego coloca el arma en él."""
    bpy.context.view_layer.objects.active = arm
    for o in bpy.context.selected_objects:
        o.select_set(False)
    arm.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    eb = arm.data.edit_bones
    mano = eb[P + lado + "Hand"]
    medio = eb.get(P + lado + "HandMiddle1")
    centro = (mano.head + medio.head) * 0.5 if medio is not None else mano.head + (mano.tail - mano.head) * 0.5
    mwi3 = arm.matrix_world.to_3x3().inverted()
    hoja = (mwi3 @ ADEL).normalized()                                 # en T: el pulgar mira adelante
    filo = (mwi3 @ (DER if lado == "Right" else -DER)).normalized()  # y los dedos, hacia fuera
    abajo = (mwi3 @ Vector((0, 0, -1))).normalized()                  # la palma mira abajo: el puño queda debajo
    alto = (arm.data.bones[P + "HeadTop_End"].head_local - arm.data.bones[P + "Hips"].head_local).length
    b = eb.new(nombre)
    b.head = centro + abajo * agarre_abajo * alto
    b.tail = b.head + hoja * 0.08 * alto
    b.align_roll(filo.cross(hoja))
    b.parent = mano
    b.use_connect = False
    b.use_deform = False
    bpy.ops.object.mode_set(mode='OBJECT')
