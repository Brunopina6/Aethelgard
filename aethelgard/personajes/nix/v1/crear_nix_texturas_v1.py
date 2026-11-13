# Nix (V12): UV del atlas y texturas horneadas con Cycles (sin imágenes de nadie: todo sale de nodos procedurales,
# de la geometría y de la oclusión). Lo usa crear_nix.py.
#
#   - UV: «detalle» (la que trae cada pieza: metros alrededor y a lo largo; sirve para pintar hebras, pliegues y vetas)
#     y «atlas» (proyección inteligente; la cabeza, el pelo y el sombrero con más resolución; islas empaquetadas).
#   - Color pintado (EMIT): color de la paleta con su luz y su sombra (degradados por altura), grano de tela o cuero,
#     hebras y anillo de brillo en el pelo, pliegues suaves en la falda y la capa, rubor en la piel, vetas en el asta,
#     brillo en los cantos del cobre, y la OCLUSIÓN (nodo de Cycles) multiplicada con la fuerza de cada material.
#   - Relieve (NORMAL, «de lo seleccionado a lo activo»): de una copia subdividida (dos niveles) a la malla del juego:
#     sombreado suave como el de un modelo de más polígonos, sin coste en el juego. Lo duro (copa facetada del
#     sombrero, disco, hierro, cristal) se hornea sin subdividir.
#   - Metal y rugosidad (EMIT): G = rugosidad, B = metal (como lo lee heroe_v2.gdshader / glTF).
# Se hornea a 2048 y se reduce a 1024 (antialias); los de 2048 quedan en las evidencias (perfil PC posible).
import math, os
import bpy, bmesh
import numpy as np
from mathutils import Vector

RES_HORNO = 2048
RES_JUEGO = 1024
ESCALA_ZONA = {"piel": 2.2, "pelo": 1.5, "pelo_plata": 1.5, "sombrero": 1.0, "sombrero_ala": 1.0,
               "sombrero_ala_baja": 0.8, "marfil": 1.1, "cobre": 1.1, "negro": 1.4, "cristal": 1.3, "medias": 0.6,
               "forro": 0.6, "asta": 0.6}
DUROS = {"sombrero", "negro", "hierro", "cristal"}


# ------------------------------------------------------------------ UV
def uv_atlas(ob):
    me = ob.data
    if me.uv_layers:
        me.uv_layers[0].name = "detalle"
    print("UV antes", [u.name for u in me.uv_layers])
    # caras degeneradas (área casi cero: puntas de mechón, polos) fuera antes de proyectar
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=1e-5)
    bm.to_mesh(me)
    bm.free()
    print("UV sin degeneradas", len(me.polygons))
    atl = me.uv_layers.new(name="atlas")
    me.uv_layers.active = atl
    bpy.context.view_layer.objects.active = ob
    for o in bpy.context.selected_objects:
        o.select_set(False)
    ob.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(58), island_margin=0.0, area_weight=0.0, correct_aspect=True,
                             scale_to_bounds=False)
    bpy.ops.object.mode_set(mode='OBJECT')
    print("UV proyectada")
    # más resolución donde se mira de cerca (cara, pelo) y menos en lo que casi no se ve (forros, medias)
    nombres = [m.name.replace("pal_", "") for m in me.materials]
    atl = me.uv_layers["atlas"]                      # (tras el modo edición, la referencia de antes ya no vale)
    uvd = atl.data
    for p in me.polygons:
        k = ESCALA_ZONA.get(nombres[p.material_index], 1.0)
        if k != 1.0:
            for li in p.loop_indices:
                uvd[li].uv = uvd[li].uv * k
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.select_all(action='SELECT')
    try:
        bpy.ops.uv.pack_islands(rotate=True, margin=0.004, shape_method='CONVEX')
    except TypeError:
        bpy.ops.uv.pack_islands(rotate=True, margin=0.004)
    print("UV empaquetada")
    bpy.ops.object.mode_set(mode='OBJECT')
    atl = me.uv_layers["atlas"]
    me.uv_layers.active = atl
    atl.active_render = True
    print("UV capas", [u.name for u in me.uv_layers], "activa", me.uv_layers.active.name if me.uv_layers.active else None)


# ------------------------------------------------------------------ nodos
class Nodos:
    def __init__(self, mat):
        mat.use_nodes = True
        self.nt = mat.node_tree
        self.nt.nodes.clear()
        self.x = -1200

    def n(self, tipo, **kw):
        nd = self.nt.nodes.new(tipo)
        nd.location = (self.x, 0)
        self.x += 160
        for k, v in kw.items():
            if k.startswith("i_"):
                nd.inputs[int(k[2:]) if k[2:].isdigit() else k[2:]].default_value = v
            else:
                setattr(nd, k, v)
        return nd

    def l(self, a, b):
        self.nt.links.new(a, b)

    def val(self, v):
        nd = self.n("ShaderNodeValue")
        nd.outputs[0].default_value = v
        return nd.outputs[0]

    def rgb(self, c):
        nd = self.n("ShaderNodeRGB")
        nd.outputs[0].default_value = (*srgb_lineal(c), 1.0)
        return nd.outputs[0]

    def mezcla(self, a, b, f, modo='MIX'):
        nd = self.n("ShaderNodeMix", data_type='RGBA', blend_type=modo)
        self._ent(nd.inputs[0], f)
        self._ent(nd.inputs[6], a)
        self._ent(nd.inputs[7], b)
        return nd.outputs[2]

    def mat(self, a, b, op, clamp=False):
        nd = self.n("ShaderNodeMath", operation=op, use_clamp=clamp)
        self._ent(nd.inputs[0], a)
        self._ent(nd.inputs[1], b)
        return nd.outputs[0]

    def _ent(self, entrada, v):
        if isinstance(v, (int, float)):
            entrada.default_value = v
        elif isinstance(v, tuple):
            entrada.default_value = (*srgb_lineal(v), 1.0) if len(v) == 3 else v      # colores: de sRGB a lineal
        else:
            self.l(v, entrada)

    def rampa(self, f, a, b, desde=0.0, hasta=1.0):
        nd = self.n("ShaderNodeMapRange", clamp=True)
        self._ent(nd.inputs[0], f)
        nd.inputs[1].default_value = desde
        nd.inputs[2].default_value = hasta
        return self.mezcla(a, b, nd.outputs[0])

    def sep(self, v):
        nd = self.n("ShaderNodeSeparateXYZ")
        self._ent(nd.inputs[0], v)
        return nd.outputs

    def uv(self, nombre):
        nd = self.n("ShaderNodeUVMap", uv_map=nombre)
        return nd.outputs[0]

    def pos(self):
        return self.n("ShaderNodeNewGeometry").outputs["Position"]

    def normal(self):
        return self.n("ShaderNodeNewGeometry").outputs["Normal"]

    def ruido(self, vec, escala, detalle=2.0):
        nd = self.n("ShaderNodeTexNoise", noise_dimensions='3D')
        self._ent(nd.inputs["Vector"], vec)
        nd.inputs["Scale"].default_value = escala
        nd.inputs["Detail"].default_value = detalle
        return nd.outputs["Fac"]

    def ao(self, distancia=0.05, muestras=16):
        nd = self.n("ShaderNodeAmbientOcclusion", samples=muestras)
        nd.inputs["Distance"].default_value = distancia
        return nd.outputs["AO"]

    def emitir(self, color):
        em = self.n("ShaderNodeEmission")
        self._ent(em.inputs["Color"], color)
        out = self.n("ShaderNodeOutputMaterial")
        self.l(em.outputs[0], out.inputs["Surface"])
        return out


def srgb_lineal(c):
    return tuple((x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4) for x in c)


def _escala(c, k):
    return tuple(min(1.0, x * k) for x in c)


# ------------------------------------------------------------------ color pintado por material
def nodos_color(mat, nombre, base, tipo, C):
    """C: centro del cráneo (Vector) para el pelo y la piel."""
    N = Nodos(mat)
    P = N.pos()
    px, py, pz = N.sep(P)
    det = N.uv("detalle")
    du, dv, _ = N.sep(det)
    col_osc = _escala(base, 0.70)
    col_cla = _escala(base, 1.18)
    if tipo == "pelo":
        # hebras: bandas finas a lo ancho del mechón (u) con algo de ruido; anillo de brillo alrededor de la cabeza
        hebra = N.n("ShaderNodeTexWave", wave_type='BANDS', bands_direction='X', wave_profile='SIN')
        vec = N.n("ShaderNodeCombineXYZ")
        N.l(N.mat(du, 1.0, 'MULTIPLY'), vec.inputs[0])
        N.l(N.mat(dv, 0.15, 'MULTIPLY'), vec.inputs[1])
        N.l(vec.outputs[0], hebra.inputs["Vector"])
        hebra.inputs["Scale"].default_value = 140.0
        hebra.inputs["Distortion"].default_value = 3.0
        hebra.inputs["Detail"].default_value = 2.0
        c = N.rampa(pz, col_osc, base, C.z - 0.20, C.z + 0.05)
        alt = N.mat(pz, C.z + 0.10, 'SUBTRACT')
        anillo = N.mat(N.mat(alt, 0.035, 'DIVIDE'), 2.0, 'POWER')
        anillo = N.mat(1.0, N.mat(anillo, 1.0, 'MINIMUM'), 'SUBTRACT')
        brillo = _escala(base, 1.9) if base[0] < 0.5 else _escala(base, 1.15)
        c = N.mezcla(c, brillo, N.mat(anillo, N.mat(hebra.outputs[1], 0.75, 'MULTIPLY'), 'MULTIPLY'))
        c = N.mezcla(c, _escala(base, 0.6), N.mat(N.mat(1.0, hebra.outputs[1], 'SUBTRACT'), 0.35, 'MULTIPLY'))
        fuerza_ao = 0.75
    elif tipo == "piel":
        c = N.rampa(pz, _escala(base, 0.93), base, C.z - 0.35, C.z + 0.1)
        # rubor en las mejillas (dos manchas suaves bajo los ojos)
        for sx in (-1, 1):
            d = N.n("ShaderNodeVectorMath", operation='DISTANCE')
            N._ent(d.inputs[0], P)
            d.inputs[1].default_value = (C.x + sx * 0.095, C.y - 0.150, C.z - 0.085)
            k = N.mat(1.0, N.mat(d.outputs["Value"], 0.040, 'DIVIDE'), 'SUBTRACT')
            k = N.mat(N.mat(k, 0.0, 'MAXIMUM'), 0.55, 'MULTIPLY')
            c = N.mezcla(c, (0.98, 0.62, 0.62), k)
        fuerza_ao = 0.55
    elif tipo == "cuero":
        r = N.ruido(P, 90.0, 4.0)
        c = N.rampa(pz, col_osc, col_cla, 0.0, 1.6)
        c = N.mezcla(c, _escala(base, 0.82), N.mat(r, 0.5, 'MULTIPLY'))
        # vetas del asta / arrugas del cuero a lo largo
        veta = N.n("ShaderNodeTexWave", wave_type='BANDS', bands_direction='X')
        vec = N.n("ShaderNodeCombineXYZ")
        N.l(du, vec.inputs[0]); N.l(N.mat(dv, 0.05, 'MULTIPLY'), vec.inputs[1])
        N.l(vec.outputs[0], veta.inputs["Vector"])
        veta.inputs["Scale"].default_value = 70.0
        veta.inputs["Distortion"].default_value = 6.0
        c = N.mezcla(c, _escala(base, 0.85), N.mat(veta.outputs[1], 0.25, 'MULTIPLY'))
        fuerza_ao = 0.7
    elif tipo == "metal":
        # cobre y hierro: brillo en los cantos (normal hacia arriba-adelante), grano y bordes más claros
        nx, ny, nz = N.sep(N.normal())
        luz = N.mat(N.mat(nz, 0.6, 'MULTIPLY'), N.mat(ny, -0.4, 'MULTIPLY'), 'ADD')
        c = N.rampa(luz, col_osc, _escala(base, 1.45), -0.6, 0.9)
        c = N.mezcla(c, _escala(base, 0.75), N.mat(N.ruido(P, 160.0, 3.0), 0.35, 'MULTIPLY'))
        fuerza_ao = 0.6
    elif tipo == "cristal":
        nx, ny, nz = N.sep(N.normal())
        c = N.rampa(nz, _escala(base, 0.65), _escala(base, 1.3), -0.8, 0.9)
        fuerza_ao = 0.2
    else:   # tela
        r = N.ruido(P, 260.0, 3.0)                                   # grano fino
        rr = N.ruido(P, 18.0, 2.0)                                    # manchas suaves del tinte
        c = N.rampa(pz, col_osc, col_cla, 0.25, 1.45)
        c = N.mezcla(c, _escala(base, 0.88), N.mat(r, 0.22, 'MULTIPLY'))
        c = N.mezcla(c, _escala(base, 1.08), N.mat(rr, 0.25, 'MULTIPLY'))
        if nombre in ("abrigo", "forro", "lavanda"):
            # pliegues suaves a lo largo (u: alrededor de la pieza)
            pl = N.n("ShaderNodeTexWave", wave_type='BANDS', bands_direction='X')
            vec = N.n("ShaderNodeCombineXYZ")
            N.l(du, vec.inputs[0]); N.l(N.mat(dv, 0.2, 'MULTIPLY'), vec.inputs[1])
            N.l(vec.outputs[0], pl.inputs["Vector"])
            pl.inputs["Scale"].default_value = 9.0
            pl.inputs["Distortion"].default_value = 1.5
            c = N.mezcla(c, _escala(base, 0.80), N.mat(pl.outputs[1], 0.28, 'MULTIPLY'))
        fuerza_ao = 0.8
    ao = N.ao(0.06 if tipo != "piel" else 0.05, 16)
    k = N.mat(1.0, N.mat(N.mat(1.0, ao, 'SUBTRACT'), fuerza_ao, 'MULTIPLY'), 'SUBTRACT')
    c = N.mezcla((0.0, 0.0, 0.0), c, k)
    N.emitir(c)


def nodos_orm(mat, tipo, nombre):
    rug = {"pelo": 0.45, "piel": 0.7, "cuero": 0.55, "metal": 0.35, "cristal": 0.15, "tela": 0.85}[tipo]
    met = 1.0 if tipo == "metal" and nombre != "negro" else 0.0
    if nombre == "negro":
        rug = 0.3
    N = Nodos(mat)
    r = N.ruido(N.pos(), 120.0, 3.0)
    g = N.mat(rug - 0.05, N.mat(r, 0.1, 'MULTIPLY'), 'ADD')
    cmb = N.n("ShaderNodeCombineXYZ")
    cmb.inputs[0].default_value = 1.0
    N.l(g, cmb.inputs[1])
    cmb.inputs[2].default_value = met
    N.emitir(cmb.outputs[0])


# ------------------------------------------------------------------ horneado
def _imagen(nombre, res, color=True):
    img = bpy.data.images.get(nombre)
    if img is not None:
        bpy.data.images.remove(img)
    img = bpy.data.images.new(nombre, res, res, alpha=False, float_buffer=not color)
    img.colorspace_settings.name = 'sRGB' if color else 'Non-Color'
    return img


def _poner_destino(ob, img):
    for m in ob.data.materials:
        nt = m.node_tree
        nd = nt.nodes.get("destino") or nt.nodes.new("ShaderNodeTexImage")
        nd.name = "destino"
        nd.image = img
        nt.nodes.active = nd


def _preparar_cycles(muestras):
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.device = 'CPU'
    sc.cycles.samples = muestras
    sc.cycles.use_denoising = False
    sc.render.bake.margin = 12
    sc.render.bake.margin_type = 'EXTEND'
    return sc


def hornear(ob, D, C, evid):
    """Hornea color, metal/rugosidad y relieve del objeto «ob» (todas las piezas unidas, UV «atlas»).
    Devuelve las rutas de las imágenes (1024) y deja a ob con su material final (Principled con las tres)."""
    me = ob.data
    nombres = [m.name.replace("pal_", "") for m in me.materials]
    # --- materiales de horneado (uno por material de la paleta)
    originales = list(me.materials)
    mats_color, mats_orm = [], []
    for n in nombres:
        cbase, tipo = D.MATERIALES[n]
        mc = bpy.data.materials.new("hc_" + n)
        nodos_color(mc, n, D.COL[cbase], tipo, C)
        mats_color.append(mc)
        mo = bpy.data.materials.new("ho_" + n)
        nodos_orm(mo, tipo, n)
        mats_orm.append(mo)
    # lo que no es el cuerpo (la cara, que flota 1,6 mm sobre la cabeza) no debe dar sombra en el horneado
    ocultos = [o for o in bpy.context.scene.objects if o.type == 'MESH' and o is not ob and not o.hide_render]
    for o in ocultos:
        o.hide_render = True
    sc = _preparar_cycles(24)
    for o in bpy.context.selected_objects:
        o.select_set(False)
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    rutas = {}
    # 1) color
    for i, m in enumerate(mats_color):
        me.materials[i] = m
    img_c = _imagen("nix_color", RES_HORNO, True)
    _poner_destino(ob, img_c)
    bpy.ops.object.bake(type='EMIT')
    rutas["color"] = _guardar(img_c, os.path.join(evid, "nix_color_2048.png"))
    # 2) metal / rugosidad
    sc.cycles.samples = 4
    for i, m in enumerate(mats_orm):
        me.materials[i] = m
    img_o = _imagen("nix_orm", RES_HORNO, False)
    _poner_destino(ob, img_o)
    bpy.ops.object.bake(type='EMIT')
    rutas["orm"] = _guardar(img_o, os.path.join(evid, "nix_orm_2048.png"))
    # 3) relieve: de una copia subdividida (lo blando) a la malla del juego
    alto = _copia_subdividida(ob, nombres)
    img_n = _imagen("nix_normal", RES_HORNO, False)
    _poner_destino(ob, img_n)
    sc.cycles.samples = 4
    sc.render.bake.use_selected_to_active = True
    sc.render.bake.cage_extrusion = 0.012
    sc.render.bake.max_ray_distance = 0.03
    sc.render.bake.normal_space = 'TANGENT'
    for o in bpy.context.selected_objects:
        o.select_set(False)
    for a in alto:
        a.select_set(True)
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.bake(type='NORMAL')
    sc.render.bake.use_selected_to_active = False
    rutas["normal"] = _guardar(img_n, os.path.join(evid, "nix_normal_2048.png"))
    for a in alto:
        me2 = a.data
        bpy.data.objects.remove(a, do_unlink=True)
        bpy.data.meshes.remove(me2)
    for i, m in enumerate(originales):
        me.materials[i] = m
    for o in ocultos:
        o.hide_render = False
    return rutas


def _copia_subdividida(ob, nombres):
    """Copia sin armadura: lo blando con dos niveles de subdivisión; lo duro, tal cual (otro objeto)."""
    blando = ob.copy()
    blando.data = ob.data.copy()
    bpy.context.scene.collection.objects.link(blando)
    for md in list(blando.modifiers):
        blando.modifiers.remove(md)
    duro = blando.copy()
    duro.data = blando.data.copy()
    bpy.context.scene.collection.objects.link(duro)
    for o, quitar_duro in ((blando, True), (duro, False)):
        bm = bmesh.new()
        bm.from_mesh(o.data)
        fuera = [f for f in bm.faces if (nombres[f.material_index] in DUROS) == quitar_duro]
        bmesh.ops.delete(bm, geom=fuera, context='FACES')
        bm.to_mesh(o.data)
        bm.free()
    sd = blando.modifiers.new("sub", 'SUBSURF')
    sd.levels = 2
    sd.render_levels = 2
    sd.boundary_smooth = 'PRESERVE_CORNERS'
    for p in blando.data.polygons:
        p.use_smooth = True
    return [blando, duro]


def _guardar(img, ruta):
    img.filepath_raw = ruta
    img.file_format = 'PNG'
    img.save()
    return ruta


def reducir(ruta_2048, ruta_1024, es_color=True):
    """2048 → 1024 (media de 2×2) y guardado en PNG."""
    img = bpy.data.images.load(ruta_2048, check_existing=False)
    if not es_color:
        img.colorspace_settings.name = 'Non-Color'
    w, h = img.size
    a = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    b = a.reshape(h // 2, 2, w // 2, 2, 4).mean(axis=(1, 3))
    out = bpy.data.images.new(os.path.basename(ruta_1024), w // 2, h // 2, alpha=False, float_buffer=False)
    out.colorspace_settings.name = 'sRGB' if es_color else 'Non-Color'
    out.pixels[:] = b.ravel()
    out.filepath_raw = ruta_1024
    out.file_format = 'PNG'
    out.save()
    bpy.data.images.remove(img)
    return out


def material_final(ob, img_color, img_orm, img_normal):
    """Un material para todo el cuerpo: Principled con color, metal/rugosidad (G/B) y relieve. Exporta a glTF tal cual."""
    m = bpy.data.materials.new("nix_cuerpo")
    m.use_nodes = True
    nt = m.node_tree
    bs = nt.nodes["Principled BSDF"]
    uv = nt.nodes.new("ShaderNodeUVMap"); uv.uv_map = "atlas"
    tc = nt.nodes.new("ShaderNodeTexImage"); tc.image = img_color
    to = nt.nodes.new("ShaderNodeTexImage"); to.image = img_orm
    tn = nt.nodes.new("ShaderNodeTexImage"); tn.image = img_normal
    img_orm.colorspace_settings.name = 'Non-Color'
    img_normal.colorspace_settings.name = 'Non-Color'
    for t in (tc, to, tn):
        nt.links.new(uv.outputs[0], t.inputs["Vector"])
    nt.links.new(tc.outputs["Color"], bs.inputs["Base Color"])
    sp = nt.nodes.new("ShaderNodeSeparateColor")
    nt.links.new(to.outputs["Color"], sp.inputs[0])
    nt.links.new(sp.outputs[1], bs.inputs["Roughness"])
    nt.links.new(sp.outputs[2], bs.inputs["Metallic"])
    nm = nt.nodes.new("ShaderNodeNormalMap"); nm.uv_map = "atlas"
    nt.links.new(tn.outputs["Color"], nm.inputs["Color"])
    nt.links.new(nm.outputs["Normal"], bs.inputs["Normal"])
    ob.data.materials.clear()
    ob.data.materials.append(m)
    # la UV de detalle no va al juego
    if "detalle" in ob.data.uv_layers:
        ob.data.uv_layers.remove(ob.data.uv_layers["detalle"])
    return m
