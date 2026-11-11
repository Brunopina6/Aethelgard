# Utilidades comunes de los personajes y criaturas del desierto (V12, prototipos del 12/11/2026, especialista de
# animaciones). Geometría procedural propia por partes, un atlas pintado por código, esqueleto con pesos calculados por
# parte, clips con claves en espacio de armadura, exportación a GLB y láminas de concepto. Ningún recurso descargado:
# obra propia del proyecto.
#
# Ejes (Blender): el personaje mira a -Y, Z arriba, su izquierda es +X (como Zarzalín y Bramavidrio). En Godot mira a +Z.
#
# Giros de las poses: cada valor es (ax, ay, az) en grados ALREDEDOR DE LOS EJES DE LA ARMADURA, aplicado sobre la pose
# de reposo del hueso (se convierte a espacio local con la orientación de reposo). Recordatorio:
#   hueso hacia arriba (columna, cuello):  +ax se inclina hacia delante;  +az gira hacia su izquierda (+X)
#   hueso hacia abajo (brazo, pierna):     -ax lo lleva hacia delante;    ay lo abre hacia un lado (-ay: hacia +X)
import bpy, bmesh, math, os, random
import numpy as np
from mathutils import Vector, Matrix, Quaternion, Euler

FPS = 30


# ================================================================== escena

def escena_vacia():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    esc = bpy.context.scene
    esc.render.fps = FPS
    return esc


# ================================================================== atlas pintado

class Atlas:
    """Imagen de TAM×TAM: arriba, una rejilla de 8×4 muestras de color con degradado vertical (abajo más oscuro, como
    una oclusión barata) y un grano suave; abajo, dos losetas de 256 (cara y detalle) que pinta cada personaje."""

    def __init__(self, tam=512, semilla=3):
        self.tam = tam
        self.img = np.zeros((tam, tam, 4), dtype=np.float32)
        self.img[..., 3] = 1.0
        self.muestras = {}
        self.rng = np.random.default_rng(semilla)
        self.celda = tam // 8

    def muestra(self, nombre, rgb, oscuro=0.80, claro=1.06, grano=0.025, plano=False):
        i = len(self.muestras)
        col, fila = i % 8, i // 8
        assert fila < 4, "atlas lleno"
        c = self.celda
        x0, y0 = col * c, self.tam - (fila + 1) * c          # filas de arriba hacia abajo (y = 0 abajo en Blender)
        t = np.linspace(0, 1, c)[:, None]
        f = np.ones((c, 1)) if plano else (oscuro + (claro - oscuro) * t)
        bloque = np.array(rgb, dtype=np.float32)[None, None, :] * f[:, :, None]
        if grano > 0 and not plano:
            bloque = bloque * (1.0 + self.rng.normal(0, grano, (c, c, 1)))
        self.img[y0:y0 + c, x0:x0 + c, :3] = np.clip(bloque, 0, 1)
        self.muestras[nombre] = (x0 / self.tam, y0 / self.tam, c / self.tam)
        return nombre

    def uv_muestra(self, nombre, t):
        x0, y0, c = self.muestras[nombre]
        m = 0.12
        return (x0 + 0.5 * c, y0 + c * (m + (1 - 2 * m) * min(max(t, 0.0), 1.0)))

    # losetas de abajo: «cara» (0..256 en x) y «detalle» (256..512)
    def loseta(self, cual):
        h = self.tam // 2
        x0 = 0 if cual == "cara" else h
        return x0, 0, h

    def uv_loseta(self, cual, u, v):
        x0, y0, h = self.loseta(cual)
        return ((x0 + u * h) / self.tam, (y0 + v * h) / self.tam)

    def guardar(self, ruta, nombre):
        im = bpy.data.images.new(nombre, self.tam, self.tam, alpha=False)
        im.pixels.foreach_set(self.img.ravel())
        im.filepath_raw = ruta
        im.file_format = 'PNG'
        im.save()
        return im


# --- dibujo con numpy sobre una loseta (coordenadas 0..1 de la loseta, y hacia arriba) -----------------------------

class Lienzo:
    def __init__(self, atlas, cual):
        self.a = atlas
        self.x0, self.y0, self.h = atlas.loseta(cual)
        yy, xx = np.mgrid[0:self.h, 0:self.h]
        self.X = (xx + 0.5) / self.h
        self.Y = (yy + 0.5) / self.h

    def _mezcla(self, mascara, rgb, alfa=1.0):
        sub = self.a.img[self.y0:self.y0 + self.h, self.x0:self.x0 + self.h, :3]
        m = (np.clip(mascara, 0, 1) * alfa)[..., None]
        sub[...] = sub * (1 - m) + np.array(rgb, dtype=np.float32) * m

    def fondo(self, rgb, grano=0.0):
        sub = self.a.img[self.y0:self.y0 + self.h, self.x0:self.x0 + self.h, :3]
        sub[...] = np.array(rgb, dtype=np.float32)
        if grano:
            sub *= (1.0 + self.a.rng.normal(0, grano, (self.h, self.h, 1)))

    def elipse(self, cx, cy, rx, ry, rgb, alfa=1.0, giro=0.0, borde=1.2):
        c, s = math.cos(giro), math.sin(giro)
        dx, dy = self.X - cx, self.Y - cy
        u = (dx * c + dy * s) / rx
        v = (-dx * s + dy * c) / ry
        d = np.sqrt(u * u + v * v)
        px = borde / self.h / min(rx, ry)
        self._mezcla((1 - d) / px, rgb, alfa)

    def degradado_elipse(self, cx, cy, rx, ry, arriba, abajo, alfa=1.0):
        dx, dy = (self.X - cx) / rx, (self.Y - cy) / ry
        d = np.sqrt(dx * dx + dy * dy)
        t = np.clip((self.Y - (cy - ry)) / (2 * ry), 0, 1)[..., None]
        col = np.array(abajo, dtype=np.float32) * (1 - t) + np.array(arriba, dtype=np.float32) * t
        sub = self.a.img[self.y0:self.y0 + self.h, self.x0:self.x0 + self.h, :3]
        m = np.clip((1 - d) / (1.2 / self.h / min(rx, ry)), 0, 1)[..., None] * alfa
        sub[...] = sub * (1 - m) + col * m

    def linea(self, puntos, grosor, rgb, alfa=1.0, grosor_fin=None):
        g0 = grosor
        g1 = grosor if grosor_fin is None else grosor_fin
        n = len(puntos) - 1
        dist = np.full(self.X.shape, 9.0)
        for i in range(n):
            (ax, ay), (bx, by) = puntos[i], puntos[i + 1]
            vx, vy = bx - ax, by - ay
            l2 = vx * vx + vy * vy + 1e-9
            t = np.clip(((self.X - ax) * vx + (self.Y - ay) * vy) / l2, 0, 1)
            g = g0 + (g1 - g0) * ((i + t) / n)
            d = np.sqrt((self.X - ax - t * vx) ** 2 + (self.Y - ay - t * vy) ** 2) - g * 0.5
            dist = np.minimum(dist, d)
        self._mezcla(-dist * self.h / 1.2 + 0.5, rgb, alfa)

    def arco(self, cx, cy, rx, ry, a0, a1, grosor, rgb, alfa=1.0, n=24, grosor_fin=None):
        pts = [(cx + rx * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
                cy + ry * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]
        self.linea(pts, grosor, rgb, alfa, grosor_fin)

    def rect(self, x0, y0, x1, y1, rgb, alfa=1.0):
        m = ((self.X >= x0) & (self.X <= x1) & (self.Y >= y0) & (self.Y <= y1)).astype(np.float32)
        self._mezcla(m, rgb, alfa)


# ================================================================== malla por partes

class Malla:
    """Una sola malla (un material con el atlas, salvo las superficies extra que se pidan) construida por partes. Cada
    parte lleva su muestra de color (o su función de UV) y sus pesos de hueso."""

    def __init__(self, atlas, materiales=("piel",)):
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.verify()
        self.dv = self.bm.verts.layers.deform.verify()
        self.atlas = atlas
        self.huesos = []
        self.materiales = list(materiales)
        self.uv_tubo = {}

    def ih(self, hueso):
        if hueso not in self.huesos:
            self.huesos.append(hueso)
        return self.huesos.index(hueso)

    # --- primitivas: devuelven la lista de vértices nuevos -----------------------------------------------------
    def esfera(self, centro, radios, seg=(16, 10), giro=None):
        r = bmesh.ops.create_uvsphere(self.bm, u_segments=seg[0], v_segments=seg[1], radius=1.0)
        vs = r["verts"]
        M = Matrix.Translation(Vector(centro)) @ (giro.to_matrix().to_4x4() if giro else Matrix()) @ \
            Matrix.Diagonal((radios[0], radios[1], radios[2], 1.0))
        bmesh.ops.transform(self.bm, matrix=M, verts=vs)
        return vs

    def tubo(self, puntos, radios, lados=10, tapas=(True, True), ref=Vector((1, 0, 0)), giro_seccion=0.0,
             costura=False):
        """Tubo por una polilínea; radios: un número o (a, b) por punto (a en la dirección «ref»). Con «costura», sin
        tapas y con UV cilíndricas propias (u alrededor, v a lo largo): pintar(..., uvf="tubo")."""
        if costura:
            tapas = (False, False)
        pts = [Vector(p) for p in puntos]
        n = len(pts)
        anillos = []
        for i, p in enumerate(pts):
            t = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
            a = (Vector(ref) - t * Vector(ref).dot(t))
            if a.length < 1e-4:
                a = t.orthogonal()
            a.normalize()
            b = t.cross(a)
            r = radios[i]
            ra, rb = (r, r) if isinstance(r, (int, float)) else r
            anillo = []
            for k in range(lados + (1 if costura else 0)):
                ang = 2 * math.pi * k / lados + giro_seccion
                vv = self.bm.verts.new(p + a * (math.cos(ang) * ra) + b * (math.sin(ang) * rb))
                if costura:
                    self.uv_tubo[vv] = (k / lados, i / max(n - 1, 1))
                anillo.append(vv)
            anillos.append(anillo)
        nuevos = [v for an in anillos for v in an]
        for i in range(n - 1):
            for k in range(lados):
                k2 = (k + 1) if costura else (k + 1) % lados
                self.bm.faces.new((anillos[i][k], anillos[i][k2], anillos[i + 1][k2], anillos[i + 1][k]))
        for extremo, cerrar in ((0, tapas[0]), (n - 1, tapas[1])):
            if not cerrar:
                continue
            c = self.bm.verts.new(pts[extremo])
            nuevos.append(c)
            an = anillos[extremo]
            for k in range(lados):
                k2 = (k + 1) % lados
                f = (an[k2], an[k], c) if extremo == 0 else (an[k], an[k2], c)
                self.bm.faces.new(f)
        return nuevos

    def caja(self, centro, tam, giro=None):
        r = bmesh.ops.create_cube(self.bm, size=1.0)
        vs = r["verts"]
        M = Matrix.Translation(Vector(centro)) @ (giro.to_matrix().to_4x4() if giro else Matrix()) @ \
            Matrix.Diagonal((tam[0], tam[1], tam[2], 1.0))
        bmesh.ops.transform(self.bm, matrix=M, verts=vs)
        return vs

    def cono(self, base, punta, r_base, lados=6, r_punta=0.0, ref=Vector((1, 0, 0))):
        if r_punta <= 0:
            return self.tubo([base, punta], [r_base, 0.0001], lados, (True, False), ref)
        return self.tubo([base, punta], [r_base, r_punta], lados, (True, True), ref)

    # --- color, UV, pesos y material de lo recién creado ----------------------------------------------------------
    def pintar(self, vs, muestra=None, uvf=None, pesos=None, mat=0, liso=True, deform=None, quitar=None):
        vs = [v for v in vs if v.is_valid]
        if deform:
            for v in vs:
                v.co = Vector(deform(v.co.copy()))
        if quitar:
            fuera = [v for v in vs if quitar(v.co)]
            bmesh.ops.delete(self.bm, geom=fuera, context='VERTS')
            vs = [v for v in vs if v.is_valid]
        caras = {f for v in vs for f in v.link_faces}
        zs = [v.co.z for v in vs] or [0.0]
        z0, z1 = min(zs), max(zs)
        for f in caras:
            f.smooth = liso
            f.material_index = mat
            fc = f.calc_center_median()
            for lp in f.loops:
                co = lp.vert.co
                if uvf == "tubo":
                    lp[self.uv].uv = self.uv_tubo.get(lp.vert, (0.0, 0.0))
                elif uvf:
                    lp[self.uv].uv = uvf(co, fc)
                elif muestra:
                    lp[self.uv].uv = self.atlas.uv_muestra(muestra, (co.z - z0) / max(z1 - z0, 1e-4))
        self.pesar(vs, pesos)
        return vs

    def pesar(self, vs, pesos):
        if pesos is None:
            return
        for v in vs:
            if isinstance(pesos, str):
                w = {pesos: 1.0}
            elif callable(pesos):
                w = pesos(v.co)
            else:
                w = por_altura(v.co.z, pesos)
            d = v[self.dv]
            d.clear()
            tot = sum(w.values()) or 1.0
            for h, x in w.items():
                if x > 1e-4:
                    d[self.ih(h)] = x / tot

    def objeto(self, nombre, coleccion):
        me = bpy.data.meshes.new(nombre)
        self.bm.normal_update()
        self.bm.to_mesh(me)
        self.bm.free()
        ob = bpy.data.objects.new(nombre, me)
        coleccion.objects.link(ob)
        for h in self.huesos:
            ob.vertex_groups.new(name=h)
        return ob


def por_altura(z, cadena):
    """cadena: [(z, hueso), ...] de abajo arriba; mezcla lineal entre dos vecinos."""
    if z <= cadena[0][0]:
        return {cadena[0][1]: 1.0}
    for (za, ha), (zb, hb) in zip(cadena, cadena[1:]):
        if z <= zb:
            t = (z - za) / max(zb - za, 1e-6)
            t = t * t * (3 - 2 * t)
            return {ha: 1 - t, hb: t}
    return {cadena[-1][1]: 1.0}


def por_eje(a, b, cadena):
    """Pesos a lo largo del segmento a→b: cadena [(t, hueso)] con t de 0 (a) a 1 (b)."""
    a, b = Vector(a), Vector(b)
    eje = b - a
    l2 = eje.length_squared

    def f(co):
        t = (co - a).dot(eje) / l2
        return por_altura(t, cadena)
    return f


# ================================================================== materiales

def material_atlas(nombre, imagen, metal=0.0, rugoso=0.85, emision=None, alfa=None):
    m = bpy.data.materials.new(nombre)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    if imagen is not None:
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = imagen
        tex.interpolation = 'Linear'
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Metallic"].default_value = metal
    bsdf.inputs["Roughness"].default_value = rugoso
    if emision is not None:
        bsdf.inputs["Emission Color"].default_value = (*emision[:3], 1)
        bsdf.inputs["Emission Strength"].default_value = emision[3] if len(emision) > 3 else 1.0
    if alfa is not None:
        bsdf.inputs["Alpha"].default_value = alfa
        try:
            m.surface_render_method = 'BLENDED'
        except Exception:
            pass
    return m


def material_color(nombre, rgb, metal=0.0, rugoso=0.6, emision=None, alfa=None):
    m = material_atlas(nombre, None, metal, rugoso, emision, alfa)
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*rgb[:3], 1)
    return m


# ================================================================== esqueleto

def crear_armadura(nombre, huesos, coleccion):
    """huesos: [(nombre, cabeza, cola, padre)]. Roll: X local = +X de la armadura cuando se puede."""
    ad = bpy.data.armatures.new(nombre)
    arm = bpy.data.objects.new(nombre, ad)
    coleccion.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode='EDIT')
    for n, c, t, p in huesos:
        eb = ad.edit_bones.new(n)
        eb.head, eb.tail = Vector(c), Vector(t)
        y = (eb.tail - eb.head).normalized()
        z = Vector((1, 0, 0)).cross(y)
        eb.align_roll(z if z.length > 0.3 else Vector((0, 0, 1)))
        if p:
            eb.parent = ad.edit_bones[p]
        eb.use_deform = True
    bpy.ops.object.mode_set(mode='OBJECT')
    for pb in arm.pose.bones:
        pb.rotation_mode = 'QUATERNION'
    return arm


def enlazar(malla, arm):
    malla.parent = arm
    mod = malla.modifiers.new("esqueleto", 'ARMATURE')
    mod.object = arm


def _q_local(arm, hueso, giro_arm):
    """Giro dado en ejes de la armadura (grados XYZ) → cuaternión local del hueso sobre su reposo."""
    R = arm.data.bones[hueso].matrix_local.to_quaternion()
    Q = Euler([math.radians(a) for a in giro_arm], 'XYZ').to_quaternion()
    return R.inverted() @ Q @ R


def poner_pose(arm, pose):
    """pose: {hueso: (ax, ay, az)} y opcionales {hueso+'@loc': (x,y,z) en ejes de armadura} y {hueso+'@esc': (sx,sy,sz)}."""
    for pb in arm.pose.bones:
        pb.rotation_quaternion = Quaternion()
        pb.location = Vector()
        pb.scale = Vector((1, 1, 1))
    for k, val in pose.items():
        if k.endswith("@loc"):
            h = k[:-4]
            R = arm.data.bones[h].matrix_local.to_3x3()
            arm.pose.bones[h].location = R.inverted() @ Vector(val)
        elif k.endswith("@esc"):
            arm.pose.bones[k[:-4]].scale = Vector(val)
        else:
            arm.pose.bones[k].rotation_quaternion = _q_local(arm, k, val)


def mezclar_poses(a, b, t):
    out = {}
    for k in set(a) | set(b):
        va = a.get(k, (1, 1, 1) if k.endswith("@esc") else (0, 0, 0))
        vb = b.get(k, (1, 1, 1) if k.endswith("@esc") else (0, 0, 0))
        out[k] = tuple(x + (y - x) * t for x, y in zip(va, vb))
    return out


def sumar(*poses):
    out = {}
    for p in poses:
        for k, v in p.items():
            if k.endswith("@esc"):
                o = out.get(k, (1, 1, 1))
                out[k] = tuple(x * y for x, y in zip(o, v))
            else:
                o = out.get(k, (0, 0, 0))
                out[k] = tuple(x + y for x, y in zip(o, v))
    return out


def crear_clip(arm, nombre, claves, interp='BEZIER'):
    """claves: [(fotograma, pose)] (el primero, 1). Una acción por clip; queda en una pista NLA silenciada."""
    if arm.animation_data is None:
        arm.animation_data_create()
    act = bpy.data.actions.new(nombre)
    act.use_fake_user = True
    arm.animation_data.action = act
    previo = {}
    for f, pose in claves:
        poner_pose(arm, pose)
        for pb in arm.pose.bones:
            q = pb.rotation_quaternion.copy()
            if pb.name in previo and previo[pb.name].dot(q) < 0:
                q.negate()
                pb.rotation_quaternion = q
            previo[pb.name] = q.copy()
            pb.keyframe_insert("rotation_quaternion", frame=f, group=pb.name)
            pb.keyframe_insert("location", frame=f, group=pb.name)
            pb.keyframe_insert("scale", frame=f, group=pb.name)
    try:
        curvas = act.fcurves
    except AttributeError:
        curvas = [fc for capa in act.layers for tira in capa.strips for cb in tira.channelbags for fc in cb.fcurves]
    for fc in curvas:
        for k in fc.keyframe_points:
            k.interpolation = interp
            k.handle_left_type = k.handle_right_type = 'AUTO_CLAMPED'
        fc.update()
    arm.animation_data.action = None
    pista = arm.animation_data.nla_tracks.new()
    pista.name = nombre
    pista.strips.new(nombre, int(claves[0][0]), act)
    pista.mute = True
    return act


# ================================================================== exportación

def exportar_glb(ruta):
    bpy.ops.export_scene.gltf(
        filepath=ruta, export_format='GLB', use_selection=False,
        export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=True,
        export_anim_slide_to_zero=True, export_def_bones=False, export_reset_pose_bones=True,
        export_optimize_animation_size=False, export_skins=True, export_yup=True, export_influence_nb=4,
        export_cameras=False, export_lights=False, export_materials='EXPORT', export_image_format='AUTO')


def triangulos(ob):
    me = ob.data
    return sum(len(p.vertices) - 2 for p in me.polygons)


# ================================================================== láminas (render)

def preparar_render(esc, ancho=1600, alto=1000, fondo=(0.93, 0.89, 0.80), muestras=32):
    esc.render.engine = 'BLENDER_EEVEE'
    try:
        esc.eevee.taa_render_samples = muestras
    except Exception:
        pass
    esc.render.resolution_x, esc.render.resolution_y = ancho, alto
    esc.render.film_transparent = False
    esc.view_settings.view_transform = 'Standard'
    w = bpy.data.worlds.new("cielo")
    esc.world = w
    w.use_nodes = True
    bg = w.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (*fondo, 1)
    bg.inputs[1].default_value = 0.55
    return w


def luces_desierto(esc):
    """Sol cálido alto (como el Mar de Cristal), relleno frío y contraluz: la misma para todas las láminas."""
    hechas = []
    for nom, energia, rot, color in (("sol", 3.2, (50, 8, 35), (1.0, 0.93, 0.80)),
                                     ("relleno", 1.2, (70, 0, -120), (0.75, 0.85, 1.0)),
                                     ("contra", 2.5, (120, 0, 200), (1.0, 0.85, 0.65))):
        l = bpy.data.lights.new(nom, 'SUN')
        l.energy = energia
        l.color = color
        try:
            l.angle = math.radians(4)
        except Exception:
            pass
        o = bpy.data.objects.new(nom, l)
        esc.collection.objects.link(o)
        o.rotation_euler = [math.radians(a) for a in rot]
        hechas.append(o)
    return hechas


def camara(esc, objetivo, distancia, azimut, elevacion, orto=None, lente=50):
    cam = bpy.data.cameras.new("cam")
    if orto:
        cam.type = 'ORTHO'
        cam.ortho_scale = orto
    else:
        cam.lens = lente
    oc = bpy.data.objects.new("cam", cam)
    esc.collection.objects.link(oc)
    esc.camera = oc
    apuntar(oc, objetivo, distancia, azimut, elevacion)
    return oc


def apuntar(oc, objetivo, distancia, azimut, elevacion):
    """azimut 0: desde delante (-Y); 90: desde su izquierda (+X)."""
    az, el = math.radians(azimut), math.radians(elevacion)
    d = Vector((math.sin(az) * math.cos(el), -math.cos(az) * math.cos(el), math.sin(el)))
    oc.location = Vector(objetivo) + d * distancia
    oc.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()


def texto(esc, cadena, pos, tam=0.12, color=(0.12, 0.10, 0.08), giro=(90, 0, 0)):
    cu = bpy.data.curves.new("txt", 'FONT')
    cu.body = cadena
    cu.size = tam
    cu.align_x = 'CENTER'
    ob = bpy.data.objects.new("txt", cu)
    esc.collection.objects.link(ob)
    ob.location = pos
    ob.rotation_euler = [math.radians(a) for a in giro]
    m = material_color("txt_" + str(len(bpy.data.materials)), color, emision=(*color, 1.0))
    cu.materials.append(m)
    return ob


def suelo(esc, color=(0.86, 0.76, 0.58), tam=40):
    bpy.ops.mesh.primitive_plane_add(size=tam)
    p = bpy.context.active_object
    p.data.materials.append(material_color("suelo", color, rugoso=0.95))
    return p


def silueta_de(ob, esc):
    """Copia del objeto (con su esqueleto, si lo tiene) en negro mate: para la columna de siluetas."""
    m = bpy.data.materials.get("negro_silueta") or material_color("negro_silueta", (0.02, 0.02, 0.025),
                                                                     rugoso=1.0)
    c = ob.copy()
    c.data = ob.data.copy()
    esc.collection.objects.link(c)
    c.data.materials.clear()
    c.data.materials.append(m)
    for p in c.data.polygons:
        p.material_index = 0
    return c


def importar_kael(raiz, alto=1.7, pos=(0, 0, 0), giro_z=0.0, fotograma=1):
    """Kael (kael.fbx del juego) como muñeco a escala: normalizado a 1,7 m como en maga_3d.gd, en su reposo."""
    antes = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=os.path.join(raiz, "kael.fbx"))
    nuevos = [o for o in bpy.data.objects if o not in antes]
    arm = next((o for o in nuevos if o.type == 'ARMATURE'), None)
    if arm and arm.animation_data:
        idle = next((a for a in bpy.data.actions if "01a19b86" in a.name), None)
        arm.animation_data.action = idle
    bpy.context.scene.frame_set(fotograma)
    bpy.context.view_layer.update()
    mallas = [o for o in nuevos if o.type == 'MESH']
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []
    for o in mallas:
        ev = o.evaluated_get(dg)
        me = ev.to_mesh()
        pts += [o.matrix_world @ v.co for v in me.vertices]
        ev.to_mesh_clear()
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    s = alto / (hi.z - lo.z)
    vac = bpy.data.objects.new("kael_escala", None)
    bpy.context.scene.collection.objects.link(vac)
    for o in nuevos:
        if o.parent is None:
            o.parent = vac
            o.matrix_parent_inverse = Matrix.Translation(-Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z)))
    vac.scale = (s, s, s)
    vac.location = pos
    vac.rotation_euler = (0, 0, math.radians(giro_z))
    return vac, nuevos


def lamina_criatura(esc, arm, ob, raiz, ruta, titulo, sep=2.2, giros=(0, -40, -90), alto_cam=0.7, orto=7.0,
                    clip="reposo", fotograma=1):
    """Lámina: silueta de perfil | 3/4 | perfil (y los giros que se pidan) | Kael a escala, con rótulos."""
    preparar_render(esc, 2000, 1000)
    luces_desierto(esc)
    suelo(esc)
    n = len(giros) + 2
    xs = [(i - (n - 1) / 2) * sep for i in range(n)]
    copias = []
    for i, (x, giro) in enumerate([(xs[0], -90)] + [(xs[k + 1], g) for k, g in enumerate(giros)]):
        if i == 1:
            a2, m2 = arm, ob
        else:
            a2 = arm.copy()
            esc.collection.objects.link(a2)
            a2.animation_data_clear()
            a2.animation_data_create()
            m2 = silueta_de(ob, esc) if i == 0 else ob.copy()
            if i:
                esc.collection.objects.link(m2)
            m2.parent = a2
            m2.modifiers["esqueleto"].object = a2
            for h in ob.children:
                pass
        if arm.animation_data and clip in bpy.data.actions:
            accion(a2, clip)
        a2.location = (x, 0, 0)
        a2.rotation_euler = (0, 0, math.radians(giro))
        copias.append(a2)
    importar_kael(raiz, 1.7, (xs[-1], 0, 0))
    rot = ["silueta (perfil)"] + ["%d°" % abs(g) if g not in (0, -90) else ("frente" if g == 0 else "perfil")
                                  for g in giros] + ["Kael (1,7 m)"]
    for x, t in zip(xs, rot):
        texto(esc, t, (x, 0.0, 2.0), 0.12)
    texto(esc, titulo, (0, 0.5, 2.35), 0.14)
    esc.frame_set(fotograma)
    cam = camara(esc, (0, 0, alto_cam), 16, 0, 8, orto=orto)
    esc.render.filepath = ruta
    bpy.ops.render.render(write_still=True)
    for o in esc.objects:
        if o.name.startswith("txt"):
            o.hide_render = True
    for c in copias[:1] + copias[2:]:
        c.hide_render = True
        for h in c.children:
            h.hide_render = True
    return cam, xs


def accion(ob, nombre):
    """Asigna una acción a un objeto con su ranura (Blender 5: sin ranura, la acción no anima a una copia)."""
    if ob.animation_data is None:
        ob.animation_data_create()
    act = bpy.data.actions[nombre]
    ob.animation_data.action = act
    try:
        if ob.animation_data.action_slot is None and len(act.slots):
            ob.animation_data.action_slot = act.slots[0]
    except AttributeError:
        pass
