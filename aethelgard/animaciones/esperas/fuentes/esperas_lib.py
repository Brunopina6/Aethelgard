# Esperas de exploración (personalidad de los héroes), paso 2 de 3: biblioteca de pose para Blender 5.2 (sin
# complementos). La usan esperas.py (los clips) y los renders de comprobación.
#
# Idea: la pose se guarda como el GIRO de cada hueso en el espacio de la armadura más la posición de la cadera; las
# cabezas de los huesos salen por cinemática directa (fk). Así cada operación (girar un tramo del cuerpo, IK de brazo o
# de pierna, orientar un arma) es una cuenta, sin pasar por el depsgraph, y al final se pasa a las claves de Blender
# (matrix_basis) de una vez.
#
# La pose de partida es la del juego (pruebas/herramientas/capturar_reposo.gd): el reposo de exploración con sus gestos.
# El esqueleto de Godot y la armadura de Blender salen del mismo FBX; su relación (giro, escala y traslado) se calcula
# por Kabsch con las posiciones de reposo de los huesos, así que no depende de cómo importe los ejes cada programa.
import json, math
import bpy
from mathutils import Matrix, Vector, Quaternion

P = "mixamorig:"


def nombre_godot(n):
    return n.replace(":", "_")


# ---------------------------------------------------------------- Kabsch (con escala): Q ≈ s·R·P + t

def kabsch(P_, Q_):
    n = len(P_)
    cp = sum(P_, Vector()) / n
    cq = sum(Q_, Vector()) / n
    H = Matrix(((0.0,) * 3,) * 3)
    for p, q in zip(P_, Q_):
        a = p - cp; b = q - cq
        for i in range(3):
            for j in range(3):
                H[i][j] += a[i] * b[j]
    # SVD de 3×3 sin numpy: iteración polar (H = U S Vᵀ → R = V Uᵀ es el factor ortogonal de Hᵀ)
    A = H.transposed()
    R = A.copy()
    for _ in range(60):
        Ri = R.inverted_safe().transposed()
        R = (R + Ri) * 0.5
    if R.determinant() < 0:
        raise RuntimeError("Kabsch: reflexión")
    var_p = sum(((p - cp).length_squared for p in P_), 0.0)
    s = sum(((R @ (p - cp)).dot(q - cq) for p, q in zip(P_, Q_)), 0.0) / var_p
    t = cq - s * (R @ cp)
    err = max(((s * (R @ p) + t) - q).length for p, q in zip(P_, Q_))
    return s, R, t, err


# ---------------------------------------------------------------- el personaje

class Personaje:
    def __init__(self, fbx, captura):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.fbx(filepath=fbx)
        self.arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
        self.mallas = [o for o in bpy.data.objects if o.type == 'MESH']
        self.arm.animation_data_clear()
        for a in list(bpy.data.actions):
            bpy.data.actions.remove(a)
        datos = json.load(open(captura, encoding="utf-8"))
        self.datos = datos
        self.huesos = [b.name for b in self.arm.data.bones]          # en orden: padres antes que hijos
        self.padre = {b.name: (b.parent.name if b.parent else None) for b in self.arm.data.bones}
        self.hijos = {n: [] for n in self.huesos}
        for n in self.huesos:
            if self.padre[n]:
                self.hijos[self.padre[n]].append(n)
        self.rest = {b.name: b.matrix_local.copy() for b in self.arm.data.bones}
        self.rest_rot = {n: m.to_3x3().normalized() for n, m in self.rest.items()}
        self.local_off = {}
        self.local_rot = {}
        for n in self.huesos:
            p = self.padre[n]
            L = (self.rest[p].inverted() @ self.rest[n]) if p else self.rest[n]
            self.local_off[n] = L.to_translation()
            self.local_rot[n] = L.to_3x3().normalized()
        g = {h["nombre"]: h for h in datos["huesos"]}
        comunes = [n for n in self.huesos if nombre_godot(n) in g]
        Pg = [Vector(g[nombre_godot(n)]["rest_pos"]) for n in comunes]
        Qb = [self.rest[n].to_translation() for n in comunes]
        self.s, self.R, self.t, err = kabsch(Pg, Qb)
        print("KABSCH %s: %d huesos, escala %.4f, error máx %.5f" % (datos["heroe"], len(comunes), self.s, err))
        self.RT = self.R.transposed()
        # ejes del personaje en el espacio de la armadura (gestos_3d.gd: adelante, arriba, derecha)
        self.A = (self.R @ Vector(datos["adelante"])).normalized()
        self.U = (self.R @ Vector(datos["arriba"])).normalized()
        self.D = (self.R @ Vector(datos["derecha"])).normalized()
        alto = (self.rest[P + "HeadTop_End"].to_translation() - self.rest[P + "LeftToeBase"].to_translation()).dot(self.U)
        self.k = alto / 1.65                     # metros «de personaje de 1,7 m» → unidades de la armadura
        # pose base: la del juego
        rot = {}
        for n in self.huesos:
            if nombre_godot(n) in g:
                h = g[nombre_godot(n)]
                qg = Quaternion((h["q"][3], h["q"][0], h["q"][1], h["q"][2])).to_matrix()
                rg = Quaternion((h["rest_q"][3], h["rest_q"][0], h["rest_q"][1], h["rest_q"][2])).to_matrix()
                delta = self.R @ (qg @ rg.transposed()) @ self.RT
                rot[n] = (delta @ self.rest_rot[n]).normalized()
            else:
                rot[n] = self.rest_rot[n].copy()
        hips = g[nombre_godot(P + "Hips")]
        raiz = self.s * (self.R @ Vector(hips["pos"])) + self.t
        self.base = Pose(self, rot, raiz)
        # comprobación: las cabezas por fk frente a las del juego
        cab = self.base.cabezas()
        e = max(((self.s * (self.R @ Vector(g[nombre_godot(n)]["pos"])) + self.t) - cab[n]).length for n in comunes)
        print("BASE %s: error máx de las cabezas %.5f (alto %.3f)" % (datos["heroe"], e, alto))

    def ch(self, v):
        # (adelante, arriba, derecha) del personaje → vector de la armadura
        return self.A * v[0] + self.U * v[1] + self.D * v[2]

    def descendientes(self, n):
        r = [n]
        for c in self.hijos[n]:
            r += self.descendientes(c)
        return r


class Pose:
    def __init__(self, pj, rot, raiz):
        self.pj = pj
        self.rot = {k: v.copy() for k, v in rot.items()}
        self.raiz = raiz.copy()
        self._cab = None

    def copia(self):
        return Pose(self.pj, self.rot, self.raiz)

    def cabezas(self):
        if self._cab is None:
            pj = self.pj
            c = {}
            for n in pj.huesos:
                p = pj.padre[n]
                c[n] = self.raiz.copy() if p is None else c[p] + self.rot[p] @ pj.local_off[n]
            self._cab = c
        return self._cab

    def cab(self, n):
        return self.cabezas()[P + n if not n.startswith(P) and P + n in self.pj.rest else n]

    def h(self, n):
        return P + n if (P + n) in self.pj.rest else n

    # gira el hueso «n» y todo lo que cuelga de él (alrededor de su cabeza) con la matriz de giro G
    def girar(self, n, G):
        n = self.h(n)
        for d in self.pj.descendientes(n):
            self.rot[d] = (G @ self.rot[d]).normalized()
        self._cab = None

    # giro en ejes del personaje: guiñada (izquierda +), cabeceo (adelante +), alabeo (hacia su derecha +)
    def girar_ejes(self, n, guinada=0.0, cabeceo=0.0, alabeo=0.0):
        pj = self.pj
        G = Matrix.Identity(3)
        if cabeceo:
            G = Quaternion(-pj.D, math.radians(cabeceo)).to_matrix() @ G
        if alabeo:
            G = Quaternion(pj.A, math.radians(alabeo)).to_matrix() @ G
        if guinada:
            G = Quaternion(pj.U, math.radians(guinada)).to_matrix() @ G
        if G != Matrix.Identity(3):
            self.girar(n, G)

    # orienta el tramo n→hijo hacia «dir» con el giro mínimo (más un giro «vuelta» sobre el propio hueso)
    def apuntar(self, n, hijo, dir, vuelta=0.0, peso=1.0):
        c = self.cabezas()
        actual = (c[self.h(hijo)] - c[self.h(n)]).normalized()
        meta = dir.normalized()
        q = actual.rotation_difference(meta)
        if peso < 1.0:
            q = Quaternion().slerp(q, peso)
        G = q.to_matrix()
        if vuelta:
            G = Quaternion(meta, math.radians(vuelta)).to_matrix() @ G
        self.girar(n, G)

    # mueve la cadera (en metros de personaje de 1,7 m, ejes del personaje)
    def mover_cadera(self, v):
        self.raiz = self.raiz + self.pj.ch(v) * self.pj.k
        self._cab = None

    # IK de dos huesos: la punta (cabeza de «fin») en «obj» y la articulación hacia «polo» (direcciones de la armadura)
    def ik(self, sup, med, fin, obj, polo):
        c = self.cabezas()
        a = c[self.h(sup)]; b = c[self.h(med)]; e = c[self.h(fin)]
        l1 = (b - a).length; l2 = (e - b).length
        d = obj - a
        L = min(max(d.length, abs(l1 - l2) * 1.001 + 1e-6), (l1 + l2) * 0.999999)
        d = d.normalized()
        cos_a = (l1 * l1 + L * L - l2 * l2) / (2 * l1 * L)
        ang = math.acos(max(-1.0, min(1.0, cos_a)))
        pp = polo - d * polo.dot(d)
        if pp.length < 1e-6:
            pp = (b - a) - d * (b - a).dot(d)
        pp = pp.normalized()
        codo = a + (d * math.cos(ang) + pp * math.sin(ang)) * l1
        self.apuntar(sup, med, codo - a)
        self.apuntar(med, fin, (a + d * L) - codo)

    # dirección de un arma rígida en la mano: la que tenía en la pose base, girada como ha girado la mano
    def dir_arma(self, mano, dir_base):
        pj = self.pj
        m = self.h(mano)
        return (self.rot[m] @ pj.base.rot[m].transposed() @ dir_base).normalized()

    # gira la mano (y sus dedos) para que el arma apunte a «dir»
    def orientar_arma(self, mano, dir_base, dir, peso=1.0):
        actual = self.dir_arma(mano, dir_base)
        q = actual.rotation_difference(dir.normalized())
        if peso < 1.0:
            q = Quaternion().slerp(q, peso)
        self.girar(mano, q.to_matrix())

    # dobla las tres falanges de los dedos alrededor del eje lateral de la mano (grados por falange)
    def curvar_dedos(self, lado, grados, pulgar=None):
        pj = self.pj
        eje = pj.D * (-1 if lado == "Right" else 1)
        for d in ["Index", "Middle", "Ring", "Pinky", "Thumb"]:
            g = (pulgar if pulgar is not None else grados * 0.5) if d == "Thumb" else grados
            if not g:
                continue
            for i in (1, 2, 3):
                n = P + lado + "Hand" + d + str(i)
                if n in pj.rest:
                    eje_l = self.rot[n] @ Vector((1, 0, 0))          # el eje X local del hueso: su bisagra
                    self.girar(n, Quaternion(eje_l, math.radians(g)).to_matrix())

    # matrices locales de Blender (matrix_basis) de cada hueso
    def bases(self):
        pj = self.pj
        r = {}
        for n in pj.huesos:
            p = pj.padre[n]
            if p is None:
                rot_l = pj.rest_rot[n].transposed() @ self.rot[n]
                loc = pj.rest_rot[n].transposed() @ (self.raiz - pj.rest[n].to_translation())
            else:
                rot_l = (self.rot[p] @ pj.local_rot[n]).transposed() @ self.rot[n]
                loc = Vector()
            r[n] = (rot_l.to_quaternion().normalized(), loc)
        return r

    def aplicar(self):
        pj = self.pj
        for n, (q, loc) in self.bases().items():
            pb = pj.arm.pose.bones[n]
            pb.rotation_mode = 'QUATERNION'
            pb.rotation_quaternion = q
            pb.location = loc
        bpy.context.view_layer.update()

    def claves(self, f, anterior=None):
        pj = self.pj
        for n, (q, loc) in self.bases().items():
            pb = pj.arm.pose.bones[n]
            pb.rotation_mode = 'QUATERNION'
            if anterior is not None and anterior.get(n) is not None and anterior[n].dot(q) < 0:
                q = -q                                   # sin saltos de signo entre claves (el cuaternión más cercano)
            pb.rotation_quaternion = q
            pb.keyframe_insert("rotation_quaternion", frame=f)
            if pj.padre[n] is None:
                pb.location = loc
                pb.keyframe_insert("location", frame=f)
            if anterior is not None:
                anterior[n] = q


# ---------------------------------------------------------------- curvas de control (Hermite monótona por componente)

def _hermite(ts, vs, t):
    n = len(ts)
    if t <= ts[0]:
        return vs[0]
    if t >= ts[-1]:
        return vs[-1]
    # pendientes de Fritsch-Carlson: pasa por las claves sin pasarse ni detenerse en las intermedias
    d = [(vs[i + 1] - vs[i]) / (ts[i + 1] - ts[i]) for i in range(n - 1)]
    m = [0.0] * n
    for i in range(1, n - 1):
        if d[i - 1] * d[i] <= 0:
            m[i] = 0.0
        else:
            w1 = 2 * (ts[i + 1] - ts[i]) + (ts[i] - ts[i - 1])
            w2 = (ts[i + 1] - ts[i]) + 2 * (ts[i] - ts[i - 1])
            m[i] = (w1 + w2) / (w1 / d[i - 1] + w2 / d[i])
    # extremos con pendiente 0: sale y llega a la pose de reposo con suavidad
    for i in range(n - 1):
        if ts[i] <= t <= ts[i + 1]:
            h = ts[i + 1] - ts[i]
            u = (t - ts[i]) / h
            h00 = 2 * u ** 3 - 3 * u ** 2 + 1; h10 = u ** 3 - 2 * u ** 2 + u
            h01 = -2 * u ** 3 + 3 * u ** 2; h11 = u ** 3 - u ** 2
            return h00 * vs[i] + h10 * h * m[i] + h01 * vs[i + 1] + h11 * h * m[i + 1]
    return vs[-1]


class Curvas:
    # claves: [(segundos, {control: valor}), ...]; un control vale 0 (o su neutro) en el primero y el último
    def __init__(self, claves, neutros):
        self.canales = {}
        dur = claves[-1][0]
        self.duracion = dur
        nombres = set()
        for t, c in claves:
            nombres |= set(c.keys())
        for nombre in nombres:
            ejemplo = next(c[nombre] for t, c in claves if nombre in c)
            cero = tuple(0.0 for _ in ejemplo) if isinstance(ejemplo, (tuple, list)) else 0.0
            neutro = neutros.get(nombre, cero)
            pts = [(0.0, neutro)]
            for t, c in claves:
                if nombre in c:
                    pts = [p for p in pts if abs(p[0] - t) > 1e-6] + [(t, c[nombre])]
            pts.sort(key=lambda p: p[0])
            if pts[-1][0] < dur - 1e-6:
                pts.append((dur, neutro))
            self.canales[nombre] = pts

    def valor(self, nombre, t, neutro=0.0):
        if nombre not in self.canales:
            return neutro
        pts = self.canales[nombre]
        ts = [p[0] for p in pts]
        v0 = pts[0][1]
        if isinstance(v0, (tuple, list)):
            return tuple(_hermite(ts, [p[1][i] for p in pts], t) for i in range(len(v0)))
        return _hermite(ts, [p[1] for p in pts], t)
