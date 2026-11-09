# Kit de Blender para el arte de Oakhaven (T-089): materiales, piezas de construcción, la luz de la hora azul y la
# cámara 3/4 con la proyección exacta de la ciudad 2D del juego.
#
# COORDENADAS: todo se escribe en casillas del juego (1 casilla = 1 m = 64 px): x hacia el este, y hacia el SUR (como
# en Godot) y z hacia arriba. V(x, y, z) lo pasa a Blender (X = x, Y = -y, Z = z).
#
# PROYECCIÓN (la de zona.gd): el suelo se ve con casillas cuadradas de 64 × 64 px y lo que se alza sube en pantalla
# 64 px por metro (k = 1). Es una cámara ortográfica que mira al norte 45° hacia abajo y un píxel 1/sen 45° más alto
# que ancho (pixel_aspect_x = √2): un punto (x, y, z) cae en el píxel (64·x, 64·(y − z)) del mundo 2D. Así cada
# imagen se pega en su sitio sin reescalar, píxel a píxel.
import bpy, bmesh, math, random
from mathutils import Vector, Matrix, Euler

PX = 64                       # píxeles por casilla (y por metro)
PHI = math.radians(45.0)      # inclinación de la cámara (bajo la horizontal)
K = 1.0 / math.tan(PHI)       # cuánto sube en pantalla un metro de altura (en casillas)


def V(x, y, z=0.0):
    return Vector((x, -y, z))


def a_pantalla(p):
    """Punto de Blender → píxel del mundo 2D (x, y)."""
    return (p.x * PX, (-p.y - p.z * K) * PX)


def hexlin(h, f=1.0):
    h = h.lstrip('#')
    c = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    lin = [(v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4) * f for v in c]
    return (lin[0], lin[1], lin[2], 1.0)


# ================================================================= escena

COL = None


def escena_nueva():
    global COL
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    COL = sc.collection
    sc.render.engine = 'CYCLES'
    prefs = bpy.context.preferences.addons['cycles'].preferences
    try:
        prefs.compute_device_type = 'OPTIX'
        prefs.refresh_devices()
        for d in prefs.devices:
            d.use = d.type == 'OPTIX'
        sc.cycles.device = 'GPU'
    except Exception as e:
        print("Sin GPU para Cycles:", e)
        sc.cycles.device = 'CPU'
    sc.cycles.samples = 256
    sc.cycles.use_adaptive_sampling = True
    sc.cycles.adaptive_threshold = 0.015
    sc.cycles.use_denoising = True
    try:
        sc.cycles.denoiser = 'OPENIMAGEDENOISE'
    except Exception:
        pass
    sc.cycles.max_bounces = 6
    sc.cycles.diffuse_bounces = 3
    sc.cycles.glossy_bounces = 2
    sc.cycles.transparent_max_bounces = 8
    sc.cycles.caustics_reflective = False
    sc.cycles.caustics_refractive = False
    sc.cycles.blur_glossy = 1.0
    sc.cycles.filter_width = 1.15
    sc.render.film_transparent = True
    sc.view_settings.view_transform = 'Standard'
    sc.view_settings.look = 'None'
    sc.view_settings.exposure = 0.0
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGBA'
    sc.render.image_settings.color_depth = '8'
    sc.render.resolution_percentage = 100
    return sc


def coleccion():
    return COL


def enlazar(ob):
    COL.objects.link(ob)
    return ob


# ================================================================= nodos

def _n(nt, tipo, x=0, y=0, **props):
    n = nt.nodes.new(tipo)
    n.location = (x, y)
    for k, v in props.items():
        setattr(n, k, v)
    return n


def _s(sockets, nombre, tipo=None):
    """Socket por nombre (y tipo, para los nodos con varias entradas «A»)."""
    for s in sockets:
        if s.name == nombre and (tipo is None or s.type == tipo) and getattr(s, "enabled", True):
            return s
    for s in sockets:
        if s.name == nombre:
            return s
    raise KeyError(nombre)


def _l(nt, a, b):
    nt.links.new(a, b)


def _mezcla(nt, fac, a, b, modo='MIX', x=0, y=0):
    m = _n(nt, 'ShaderNodeMix', x, y)
    m.data_type = 'RGBA'
    m.blend_type = modo
    for val, nombre in ((fac, 'Factor'), (a, 'A'), (b, 'B')):
        sk = _s(m.inputs, nombre, 'VALUE' if nombre == 'Factor' else 'RGBA')
        if isinstance(val, (float, int)):
            sk.default_value = val
        elif isinstance(val, tuple):
            sk.default_value = val
        else:
            _l(nt, val, sk)
    return _s(m.outputs, 'Result', 'RGBA')


def _rampa(nt, fac, paradas, x=0, y=0):
    r = _n(nt, 'ShaderNodeValToRGB', x, y)
    els = r.color_ramp.elements
    while len(els) > 1:
        els.remove(els[-1])
    els[0].position = paradas[0][0]
    els[0].color = paradas[0][1]
    for pos, col in paradas[1:]:
        e = els.new(pos)
        e.color = col
    _l(nt, fac, r.inputs['Fac'])
    return r.outputs['Color']


def _math(nt, op, a, b=None, x=0, y=0, clamp=False):
    m = _n(nt, 'ShaderNodeMath', x, y)
    m.operation = op
    m.use_clamp = clamp
    for i, v in enumerate((a, b)):
        if v is None:
            continue
        if isinstance(v, (float, int)):
            m.inputs[i].default_value = v
        else:
            _l(nt, v, m.inputs[i])
    return m.outputs[0]


def _material(nombre):
    m = bpy.data.materials.new(nombre)
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = _n(nt, 'ShaderNodeOutputMaterial', 600, 0)
    bsdf = _n(nt, 'ShaderNodeBsdfPrincipled', 300, 0)
    _l(nt, bsdf.outputs['BSDF'], out.inputs['Surface'])
    return m, nt, bsdf


def _coord(nt, tipo='Object', escala=1.0, x=-900, y=0):
    tc = _n(nt, 'ShaderNodeTexCoord', x, y)
    if escala == 1.0:
        return tc.outputs[tipo]
    mp = _n(nt, 'ShaderNodeMapping', x + 200, y)
    _l(nt, tc.outputs[tipo], mp.inputs['Vector'])
    mp.inputs['Scale'].default_value = (escala, escala, escala) if not isinstance(escala, tuple) else escala
    return mp.outputs['Vector']


def _ruido(nt, vec, escala, detalle=4.0, rugosidad=0.55, x=-500, y=0):
    n = _n(nt, 'ShaderNodeTexNoise', x, y)
    _l(nt, vec, n.inputs['Vector'])
    n.inputs['Scale'].default_value = escala
    n.inputs['Detail'].default_value = detalle
    n.inputs['Roughness'].default_value = rugosidad
    return n.outputs['Fac']


def _bump(nt, alto, fuerza, distancia=0.02, normal=None, x=100, y=-300):
    b = _n(nt, 'ShaderNodeBump', x, y)
    b.inputs['Strength'].default_value = fuerza
    b.inputs['Distance'].default_value = distancia
    _l(nt, alto, b.inputs['Height'])
    if normal is not None:
        _l(nt, normal, b.inputs['Normal'])
    return b.outputs['Normal']


_MATS = {}


def mat(tipo, *args, **kw):
    """Material del catálogo, creado una vez."""
    clave = (tipo, args, tuple(sorted(kw.items())))
    if clave in _MATS:
        return _MATS[clave]
    m = CATALOGO[tipo](*args, **kw)
    _MATS[clave] = m
    return m


def _base(m, color, emision=0.0, rugosidad=0.85, metal=0.0):
    """Color plano de referencia del material (lo usa la exportación a GLB, que no entiende los nodos de textura)."""
    c = color if isinstance(color, (tuple, list)) else hexlin(color)
    m["color_base"] = [float(c[0]), float(c[1]), float(c[2]), 1.0]
    m["emision"] = float(emision)
    m["rugosidad"] = float(rugosidad)
    m["metal"] = float(metal)
    return m


def m_liso(color, rugosidad=0.8, metal=0.0, nombre="liso"):
    m, nt, b = _material(nombre)
    b.inputs['Base Color'].default_value = color if len(color) == 4 else hexlin(color)
    _base(m, color if len(color) == 4 else hexlin(color), 0.0, rugosidad, metal)
    b.inputs['Roughness'].default_value = rugosidad
    b.inputs['Metallic'].default_value = metal
    return m


def m_piedra(c1="#8C847A", c2="#A39A8C", bloque=(0.62, 0.31), mortero="#5E574F", musgo=0.0, nombre="piedra"):
    """Sillería: bloques con juntas, cada bloque de un tono, picado fino y algo de musgo arriba."""
    m, nt, b = _material(nombre)
    _base(m, c2, 0.0, 0.88)
    vec = _coord(nt, 'Object', 1.0)
    # coordenadas de la cara: (x+y, z) para que las juntas sigan en las dos caras verticales
    sep = _n(nt, 'ShaderNodeSeparateXYZ', -800, 200)
    _l(nt, vec, sep.inputs['Vector'])
    suma = _math(nt, 'ADD', sep.outputs['X'], sep.outputs['Y'], -650, 250)
    comb = _n(nt, 'ShaderNodeCombineXYZ', -500, 200)
    _l(nt, suma, comb.inputs['X'])
    _l(nt, sep.outputs['Z'], comb.inputs['Y'])
    # en las caras horizontales (adarve, cornisas, escalones) las juntas van en (x, y): si no, salen rayas
    geo_n = _n(nt, 'ShaderNodeNewGeometry', -900, 450)
    sep_n = _n(nt, 'ShaderNodeSeparateXYZ', -750, 450)
    _l(nt, geo_n.outputs['Normal'], sep_n.inputs['Vector'])
    horiz = _math(nt, 'GREATER_THAN', _math(nt, 'ABSOLUTE', sep_n.outputs['Z'], None, -600, 450), 0.6, -450, 450)
    plano = _n(nt, 'ShaderNodeCombineXYZ', -500, 350)
    _l(nt, sep.outputs['X'], plano.inputs['X'])
    _l(nt, sep.outputs['Y'], plano.inputs['Y'])
    mv = _n(nt, 'ShaderNodeMix', -380, 300)
    mv.data_type = 'VECTOR'
    _l(nt, horiz, _s(mv.inputs, 'Factor', 'VALUE'))
    _l(nt, comb.outputs['Vector'], _s(mv.inputs, 'A', 'VECTOR'))
    _l(nt, plano.outputs['Vector'], _s(mv.inputs, 'B', 'VECTOR'))
    br = _n(nt, 'ShaderNodeTexBrick', -300, 200)
    _l(nt, _s(mv.outputs, 'Result', 'VECTOR'), br.inputs['Vector'])
    br.inputs['Scale'].default_value = 1.0
    br.inputs['Brick Width'].default_value = bloque[0]
    br.inputs['Row Height'].default_value = bloque[1]
    br.inputs['Mortar Size'].default_value = 0.022
    br.inputs['Mortar Smooth'].default_value = 0.3
    br.inputs['Bias'].default_value = 0.0
    br.inputs['Color1'].default_value = hexlin(c1)
    br.inputs['Color2'].default_value = hexlin(c2)
    br.inputs['Mortar'].default_value = hexlin(mortero)
    br.offset = 0.5
    rn = _ruido(nt, vec, 9.0, 6.0, 0.6, -500, -200)
    col = _mezcla(nt, 0.25, br.outputs['Color'], hexlin(c1, 0.8), 'MULTIPLY', 0, 150)
    col = _mezcla(nt, _math(nt, 'MULTIPLY', rn, 0.5, -200, -150), col, hexlin(mortero), 'MIX', 120, 120)
    if musgo > 0:
        geo = _n(nt, 'ShaderNodeNewGeometry', -500, -450)
        sepn = _n(nt, 'ShaderNodeSeparateXYZ', -300, -450)
        _l(nt, geo.outputs['Normal'], sepn.inputs['Vector'])
        arriba = _math(nt, 'MULTIPLY', _math(nt, 'SUBTRACT', sepn.outputs['Z'], 0.35, -150, -450), 2.0, -50, -450, True)
        mus = _math(nt, 'MULTIPLY', arriba, _math(nt, 'GREATER_THAN', rn, 1.0 - musgo, -150, -550), 60, -500)
        col = _mezcla(nt, mus, col, hexlin("#3F5E3A"), 'MIX', 240, 60)
    _l(nt, col, b.inputs['Base Color'])
    alto = _math(nt, 'ADD', _math(nt, 'MULTIPLY', br.outputs['Fac'], -1.0, -100, -300), _math(nt, 'MULTIPLY', rn, 0.35, -100, -380), 0, -320)
    _l(nt, _bump(nt, alto, 0.45, 0.03), b.inputs['Normal'])
    b.inputs['Roughness'].default_value = 0.88
    return m


def m_revoque(color="#D6C7A6", sucio="#8F826B", nombre="revoque"):
    """Revoque de cal: manchas suaves, grano fino y algo de suciedad abajo."""
    m, nt, b = _material(nombre)
    _base(m, color, 0.0, 0.95)
    vec = _coord(nt, 'Object', 1.0)
    r1 = _ruido(nt, vec, 1.6, 5.0, 0.6, -500, 150)
    r2 = _ruido(nt, vec, 30.0, 3.0, 0.7, -500, -100)
    base = _rampa(nt, r1, [(0.35, hexlin(color, 0.86)), (0.65, hexlin(color, 1.0))], -250, 150)
    sep = _n(nt, 'ShaderNodeSeparateXYZ', -500, -350)
    tc = _n(nt, 'ShaderNodeTexCoord', -800, -350)
    _l(nt, tc.outputs['Generated'], sep.inputs['Vector'])
    abajo = _math(nt, 'SUBTRACT', 1.0, _math(nt, 'MULTIPLY', sep.outputs['Z'], 3.5, -350, -350), -200, -350, True)
    col = _mezcla(nt, _math(nt, 'MULTIPLY', abajo, 0.45, -80, -350), base, hexlin(sucio), 'MIX', 100, 50)
    _l(nt, col, b.inputs['Base Color'])
    _l(nt, _bump(nt, r2, 0.12, 0.01), b.inputs['Normal'])
    b.inputs['Roughness'].default_value = 0.95
    return m


def m_madera(color="#6B3F2A", veta=0.35, nombre="madera", escala_veta=(1.0, 1.0, 9.0)):
    m, nt, b = _material(nombre)
    _base(m, color, 0.0, 0.75)
    vec = _coord(nt, 'Object', escala_veta)
    w = _n(nt, 'ShaderNodeTexWave', -450, 100)
    _l(nt, vec, w.inputs['Vector'])
    w.wave_type = 'BANDS'
    w.bands_direction = 'Z'
    w.inputs['Scale'].default_value = 3.0
    w.inputs['Distortion'].default_value = 6.0
    w.inputs['Detail'].default_value = 3.0
    col = _rampa(nt, w.outputs['Fac'], [(0.0, hexlin(color, 0.72)), (1.0, hexlin(color, 1.08))], -200, 100)
    _l(nt, col, b.inputs['Base Color'])
    _l(nt, _bump(nt, w.outputs['Fac'], veta * 0.3, 0.01), b.inputs['Normal'])
    b.inputs['Roughness'].default_value = 0.75
    return m


def m_teja(c="#A0583A", variacion=0.22, nombre="teja", ancho_teja=0.24):
    """Teja árabe: cada hilera es un objeto; aquí, las tejas de la hilera (surcos y tono por teja)."""
    m, nt, b = _material(nombre)
    _base(m, c, 0.0, 0.7)
    tc = _n(nt, 'ShaderNodeTexCoord', -1000, 0)
    oi = _n(nt, 'ShaderNodeObjectInfo', -1000, -250)
    sep = _n(nt, 'ShaderNodeSeparateXYZ', -800, 0)
    _l(nt, tc.outputs['Object'], sep.inputs['Vector'])
    u = _math(nt, 'DIVIDE', _math(nt, 'ADD', sep.outputs['X'], _math(nt, 'MULTIPLY', oi.outputs['Random'], 7.3, -800, -250), -650, 0), ancho_teja, -500, 0)
    fr = _math(nt, 'FRACT', u, None, -350, 0)
    # perfil de teja curva: claro en el lomo, oscuro en la canal
    lomo = _math(nt, 'SINE', _math(nt, 'MULTIPLY', fr, math.pi, -200, 0), None, -50, 0)
    idx = _math(nt, 'FLOOR', u, None, -350, -150)
    h = _n(nt, 'ShaderNodeTexWhiteNoise', -200, -150)
    h.noise_dimensions = '2D'
    comb = _n(nt, 'ShaderNodeCombineXYZ', -300, -250)
    _l(nt, idx, comb.inputs['X'])
    _l(nt, oi.outputs['Random'], comb.inputs['Y'])
    _l(nt, comb.outputs['Vector'], h.inputs['Vector'])
    tono = _rampa(nt, h.outputs['Value'], [(0.0, hexlin(c, 1.0 - variacion)), (0.5, hexlin(c, 1.0)), (1.0, hexlin(c, 1.0 + variacion * 0.7))], 0, -150)
    # manchas grandes (posición en el mundo): unas zonas más tostadas, otras con verdín
    geo = _n(nt, 'ShaderNodeNewGeometry', -700, -450)
    grande = _ruido(nt, geo.outputs['Position'], 0.45, 3.0, 0.5, -450, -450)
    fino = _ruido(nt, geo.outputs['Position'], 6.0, 4.0, 0.6, -450, -600)
    col = _mezcla(nt, _math(nt, 'MULTIPLY', _math(nt, 'SUBTRACT', 1.0, lomo, 100, 100), 0.45, 200, 100), tono, hexlin("#2A1A16"), 'MIX', 350, 0)
    tostado = _math(nt, 'MULTIPLY', _math(nt, 'SUBTRACT', grande, 0.5, -250, -450), 0.9, -100, -450)
    col = _mezcla(nt, _math(nt, 'ABSOLUTE', tostado, None, 50, -450), col,
                  hexlin(c, 0.62), 'MIX', 420, -200)
    verdin = _math(nt, 'MULTIPLY', _math(nt, 'GREATER_THAN', _math(nt, 'ADD', grande, _math(nt, 'MULTIPLY', fino, 0.35, -250, -600), -100, -600), 0.93, 50, -600), 0.55, 200, -600)
    col = _mezcla(nt, verdin, col, hexlin("#59664A"), 'MIX', 520, -300)
    _l(nt, col, b.inputs['Base Color'])
    _l(nt, _bump(nt, lomo, 0.6, 0.03), b.inputs['Normal'])
    b.inputs['Roughness'].default_value = 0.7
    return m


def m_pizarra(c="#4A5468", nombre="pizarra"):
    return m_teja(c, 0.18, nombre, 0.20)


def m_hierro(oxido=0.6, nombre="hierro"):
    m, nt, b = _material(nombre)
    _base(m, "#3A2E28" if oxido > 0.4 else "#2B2724", 0.0, 0.62, 0.55)
    vec = _coord(nt, 'Object', 1.0)
    r = _ruido(nt, vec, 18.0, 6.0, 0.65)
    fac = _rampa(nt, r, [(0.5 - oxido * 0.3, (0, 0, 0, 1)), (0.62, (1, 1, 1, 1))], -250, 0)
    col = _mezcla(nt, fac, hexlin("#2B2724"), hexlin("#7A3B1E"), 'MIX', 0, 100)
    _l(nt, col, b.inputs['Base Color'])
    b.inputs['Metallic'].default_value = 0.55
    b.inputs['Roughness'].default_value = 0.62
    _l(nt, _bump(nt, r, 0.4, 0.004), b.inputs['Normal'])
    return m


def m_luz(color="#FFB45A", fuerza=6.0, nombre="luz"):
    """Superficie que emite (vidrio de ventana con luz, llama, farol encendido)."""
    m = bpy.data.materials.new(nombre)
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = _n(nt, 'ShaderNodeOutputMaterial', 400, 0)
    em = _n(nt, 'ShaderNodeEmission', 200, 0)
    em.inputs['Color'].default_value = hexlin(color)
    em.inputs['Strength'].default_value = fuerza
    _l(nt, em.outputs['Emission'], out.inputs['Surface'])
    _base(m, color, fuerza)
    return m


def m_ventana(color="#FFB45A", fuerza=5.0, nombre="ventana"):
    """Vidrio con luz cálida: más intensa en el centro, con un velo y reflejo del cielo arriba."""
    m = bpy.data.materials.new(nombre)
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = _n(nt, 'ShaderNodeOutputMaterial', 600, 0)
    tc = _n(nt, 'ShaderNodeTexCoord', -700, 0)
    sep = _n(nt, 'ShaderNodeSeparateXYZ', -500, 0)
    _l(nt, tc.outputs['Generated'], sep.inputs['Vector'])
    # gradiente vertical: abajo más luz (como una lámpara dentro)
    g = _math(nt, 'SUBTRACT', 1.0, sep.outputs['Z'], -300, 0)
    col = _rampa(nt, g, [(0.0, hexlin(color, 0.55)), (0.6, hexlin(color, 1.0)), (1.0, hexlin("#FFD9A0", 1.0))], -100, 0)
    em = _n(nt, 'ShaderNodeEmission', 200, 0)
    _l(nt, col, em.inputs['Color'])
    em.inputs['Strength'].default_value = fuerza
    _l(nt, em.outputs['Emission'], out.inputs['Surface'])
    _base(m, color, fuerza)
    return m


def m_hojas(c1="#2E4A2C", c2="#3F5E3A", c3="#6E8F4E", nombre="hojas"):
    m, nt, b = _material(nombre)
    _base(m, c2, 0.0, 0.8)
    vec = _coord(nt, 'Object', 1.0)
    vor = _n(nt, 'ShaderNodeTexVoronoi', -500, 0)
    _l(nt, vec, vor.inputs['Vector'])
    vor.inputs['Scale'].default_value = 7.0
    vor.feature = 'F1'
    r = _ruido(nt, vec, 1.2, 4.0, 0.6, -500, -250)
    geo = _n(nt, 'ShaderNodeNewGeometry', -700, -400)
    sepn = _n(nt, 'ShaderNodeSeparateXYZ', -500, -450)
    _l(nt, geo.outputs['Normal'], sepn.inputs['Vector'])
    arriba = _math(nt, 'MULTIPLY', _math(nt, 'ADD', sepn.outputs['Z'], 0.3, -350, -450), 0.8, -200, -450, True)
    t = _math(nt, 'ADD', _math(nt, 'MULTIPLY', r, 0.6, -300, -250), _math(nt, 'MULTIPLY', arriba, 0.5, -100, -400), -100, -250)
    col = _rampa(nt, t, [(0.25, hexlin(c1)), (0.55, hexlin(c2)), (0.85, hexlin(c3))], 50, -200)
    col = _mezcla(nt, _math(nt, 'MULTIPLY', vor.outputs['Distance'], 0.5, -250, 0), col, hexlin(c1, 0.6), 'MIX', 250, -50)
    _l(nt, col, b.inputs['Base Color'])
    _l(nt, _bump(nt, vor.outputs['Distance'], 0.7, 0.05), b.inputs['Normal'])
    b.inputs['Roughness'].default_value = 0.8
    try:
        b.inputs['Subsurface Weight'].default_value = 0.15
        b.inputs['Subsurface Radius'].default_value = (0.2, 0.3, 0.1)
    except Exception:
        pass
    return m


def m_corteza(c="#4E3E33", nombre="corteza"):
    m, nt, b = _material(nombre)
    _base(m, c, 0.0, 0.92)
    vec = _coord(nt, 'Object', (2.5, 2.5, 0.5))
    vor = _n(nt, 'ShaderNodeTexVoronoi', -500, 100)
    _l(nt, vec, vor.inputs['Vector'])
    vor.inputs['Scale'].default_value = 4.0
    vor.feature = 'DISTANCE_TO_EDGE'
    r = _ruido(nt, _coord(nt, 'Object', 1.0, -900, -300), 3.0, 6.0, 0.6, -500, -200)
    col = _rampa(nt, vor.outputs['Distance'], [(0.0, hexlin(c, 0.45)), (0.12, hexlin(c, 0.85)), (0.5, hexlin(c, 1.15))], -250, 100)
    col = _mezcla(nt, _math(nt, 'GREATER_THAN', r, 0.62, -250, -200), col, hexlin("#56703F"), 'MIX', 0, 0)
    _l(nt, col, b.inputs['Base Color'])
    _l(nt, _bump(nt, vor.outputs['Distance'], 0.9, 0.06), b.inputs['Normal'])
    b.inputs['Roughness'].default_value = 0.92
    return m


def m_tela(c="#8E3B34", nombre="tela", rayas=None):
    m, nt, b = _material(nombre)
    _base(m, c, 0.0, 0.9)
    if rayas:
        vec = _coord(nt, 'Object', 1.0)
        sep = _n(nt, 'ShaderNodeSeparateXYZ', -700, 0)
        _l(nt, vec, sep.inputs['Vector'])
        u = _math(nt, 'FRACT', _math(nt, 'DIVIDE', sep.outputs['X'], 0.5, -550, 0), None, -400, 0)
        f = _math(nt, 'GREATER_THAN', u, 0.5, -250, 0)
        col = _mezcla(nt, f, hexlin(c), hexlin(rayas), 'MIX', 0, 0)
        _l(nt, col, b.inputs['Base Color'])
    else:
        b.inputs['Base Color'].default_value = hexlin(c)
    b.inputs['Roughness'].default_value = 0.9
    try:
        b.inputs['Sheen Weight'].default_value = 0.4
    except Exception:
        pass
    return m


def m_hoja(c1="#2C4A2E", c2="#466B3C", c3="#7E9C55", nombre="hoja"):
    """Hoja suelta (partículas de la copa): cada hoja, un verde distinto (Object Info → aleatorio)."""
    m, nt, b = _material(nombre)
    _base(m, c2, 0.0, 0.65)
    oi = _n(nt, 'ShaderNodeObjectInfo', -600, 0)
    col = _rampa(nt, oi.outputs['Random'], [(0.0, hexlin(c1)), (0.55, hexlin(c2)), (1.0, hexlin(c3))], -300, 0)
    _l(nt, col, b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = 0.6
    return m


CATALOGO = {
    "liso": m_liso, "piedra": m_piedra, "revoque": m_revoque, "madera": m_madera, "teja": m_teja,
    "pizarra": m_pizarra, "hierro": m_hierro, "luz": m_luz, "ventana": m_ventana, "hojas": m_hojas,
    "corteza": m_corteza, "tela": m_tela, "hoja": m_hoja,
}


# ================================================================= geometría

def _obj(nombre, bm, material):
    me = bpy.data.meshes.new(nombre)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(nombre, me)
    enlazar(ob)
    if material is not None:
        me.materials.append(material)
    return ob


def biselar(ob, ancho=0.02, segmentos=2):
    md = ob.modifiers.new("bisel", 'BEVEL')
    md.width = ancho
    md.segments = segmentos
    md.limit_method = 'ANGLE'
    return ob


def caja(x0, y0, z0, x1, y1, z1, material, nombre="caja", bisel=0.0):
    """Caja alineada en casillas del juego: x0 < x1 (oeste → este), y0 < y1 (norte → sur), z0 < z1."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    c = V((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5)
    s = Vector((abs(x1 - x0), abs(y1 - y0), abs(z1 - z0)))
    for v in bm.verts:
        v.co = Vector((v.co.x * s.x, v.co.y * s.y, v.co.z * s.z)) + c
    ob = _obj(nombre, bm, material)
    if bisel > 0:
        biselar(ob, bisel)
    return ob


def caja_centro(c, tam, material, rot=(0, 0, 0), nombre="caja", bisel=0.0):
    """Caja de tamaño tam=(ancho x, fondo y, alto z) centrada en c (casillas), girada rot (grados, ejes de Blender)."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * tam[0], v.co.y * tam[1], v.co.z * tam[2]))
    ob = _obj(nombre, bm, material)
    ob.location = V(*c)
    ob.rotation_euler = Euler([math.radians(a) for a in rot])
    if bisel > 0:
        biselar(ob, bisel)
    return ob


def viga(a, b, grosor, material, fondo=None, nombre="viga"):
    """Viga recta de a a b (casillas del juego), sección grosor × fondo."""
    pa, pb = V(*a), V(*b)
    d = pb - pa
    L = d.length
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    f = fondo if fondo is not None else grosor
    for v in bm.verts:
        v.co = Vector((v.co.x * grosor, v.co.y * f, v.co.z * L))
    ob = _obj(nombre, bm, material)
    ob.location = (pa + pb) * 0.5
    ob.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
    return ob


def cilindro(c, r, alto, material, segs=20, nombre="cilindro", r_arriba=None, eje='Z', bisel=0.0):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r,
                          radius2=r if r_arriba is None else r_arriba, depth=alto)
    ob = _obj(nombre, bm, material)
    ob.location = V(*c)
    if eje == 'X':
        ob.rotation_euler = (0, math.radians(90), 0)
    elif eje == 'Y':
        ob.rotation_euler = (math.radians(90), 0, 0)
    if bisel > 0:
        biselar(ob, bisel)
    return ob


def esfera(c, r, material, nombre="esfera", subdiv=3, escala=(1, 1, 1)):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=r)
    ob = _obj(nombre, bm, material)
    ob.location = V(*c)
    ob.scale = escala
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def poligono_extruido(puntos, grosor, material, nombre="silueta"):
    """Silueta plana (puntos (u, v) en metros, en el plano XZ) extruida grosor en Y. Origen en (0, 0)."""
    bm = bmesh.new()
    vs = [bm.verts.new((u, 0.0, v)) for (u, v) in puntos]
    cara = bm.faces.new(vs)
    r = bmesh.ops.extrude_face_region(bm, geom=[cara])
    nuevos = [e for e in r['geom'] if isinstance(e, bmesh.types.BMVert)]
    for v in nuevos:
        v.co.y += grosor
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    for v in bm.verts:
        v.co.y -= grosor * 0.5
    return _obj(nombre, bm, material)


def semicirculo(cx, y, zc, r, grosor, material, nombre="arco"):
    """Medio disco (la mitad de arriba) en una fachada que mira al sur: el remate de un hueco en arco."""
    pts = [(r * math.cos(math.pi * i / 24.0), r * math.sin(math.pi * i / 24.0)) for i in range(25)]
    ob = poligono_extruido(pts, grosor, material, nombre)
    ob.location = V(cx, y, zc)
    return ob


def suavizar(ob, niveles=1):
    md = ob.modifiers.new("sub", 'SUBSURF')
    md.levels = niveles
    md.render_levels = niveles
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def desplazar(ob, fuerza=0.15, escala=1.2, tipo='CLOUDS', nombre_tex="ruido"):
    tex = bpy.data.textures.new(nombre_tex, type=tipo)
    try:
        tex.noise_scale = escala
    except Exception:
        pass
    md = ob.modifiers.new("desplaza", 'DISPLACE')
    md.texture = tex
    md.strength = fuerza
    md.texture_coords = 'GLOBAL'
    return ob


# ---------------------------------------------------------------- tejados

def faldon(x0, x1, y_alero, z_alero, y_cumbre, z_cumbre, material, fila=0.27, grosor=0.06, nombre="faldon",
           solape=1.3):
    """Faldón de tejado hecho de hileras de teja (cada hilera, un objeto: sombras de verdad entre hileras).
    El alero y la cumbrera van en casillas del juego (y crece hacia el sur). Vale hacia el sur y hacia el norte."""
    a = Vector((0.0, -y_alero, z_alero))
    b = Vector((0.0, -y_cumbre, z_cumbre))
    d = b - a
    L = d.length
    n = max(1, int(math.ceil(L / fila)))
    paso = L / n
    dirn = d / L
    alfa = math.atan2(dirn.z, dirn.y)              # giro en X que lleva el eje Y local a la pendiente
    signo = 1.0 if dirn.y > 0 else -1.0
    normal = Vector((0.0, -dirn.z, dirn.y)) * signo  # hacia fuera (arriba)
    largo = abs(x1 - x0)
    hileras = []
    for i in range(n):
        c = a + dirn * (i * paso + paso * solape * 0.5) + normal * (grosor * 0.5)
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1.0)
        for v in bm.verts:
            v.co = Vector((v.co.x * largo, v.co.y * paso * solape, v.co.z * grosor))
        ob = _obj("%s_%d" % (nombre, i), bm, material)
        ob.location = Vector(((x0 + x1) * 0.5, c.y, c.z))
        # algo menos empinada que el faldón: el borde de abajo de cada hilera asoma sobre la de debajo
        ob.rotation_euler = (alfa - signo * math.radians(2.5), 0, 0)
        hileras.append(ob)
    return hileras


def tejado_dos_aguas(x0, x1, y_sur, y_norte, z_alero, alto, material, vuelo=0.35, vuelo_lat=0.3, cumbrera=None,
                     nombre="tejado"):
    """Tejado a dos aguas con la cumbrera de este a oeste (paralela a la fachada sur)."""
    ym = (y_sur + y_norte) * 0.5
    zc = z_alero + alto
    pend = alto / max(0.01, (y_sur - ym))
    ys = y_sur + vuelo
    zs = z_alero - vuelo * pend
    yn = y_norte - vuelo
    zn = z_alero - vuelo * pend
    partes = []
    partes += faldon(x0 - vuelo_lat, x1 + vuelo_lat, ys, zs, ym, zc, material, nombre=nombre + "_s")
    partes += faldon(x0 - vuelo_lat, x1 + vuelo_lat, yn, zn, ym, zc, material, nombre=nombre + "_n")
    mc = cumbrera if cumbrera is not None else material
    cb = cilindro((0, ym, zc + 0.02), 0.11, (x1 - x0) + 2 * vuelo_lat + 0.1, mc, 10, nombre + "_cumbrera", eje='X')
    cb.location.x = (x0 + x1) * 0.5
    partes.append(cb)
    return partes


def tejado_frontal(x0, x1, y_sur, y_norte, z_alero, alto, material, vuelo=0.3, nombre="hastial", madera=None):
    """Tejado a dos aguas con la cumbrera de norte a sur: el hastial (triángulo) mira a la calle."""
    xm = (x0 + x1) * 0.5
    zc = z_alero + alto
    semi = (x1 - x0) * 0.5 + vuelo
    L = math.hypot(semi, alto * (semi / ((x1 - x0) * 0.5)))
    pend = math.atan2(alto, (x1 - x0) * 0.5)
    partes = []
    largo = (y_sur - y_norte) + 2 * vuelo
    n = max(2, int(math.ceil(L / 0.27)))
    for lado in (-1, 1):
        for i in range(n):
            t = (i + 0.5) / n
            d = semi * (1 - t)
            px = xm + lado * d
            pz = zc - math.tan(pend) * d + 0.04
            bm = bmesh.new()
            bmesh.ops.create_cube(bm, size=1.0)
            # la hilera con su largo en X local (como en los faldones): así las canales de la teja bajan por la
            # pendiente; luego se gira 90° para que la hilera vaya de norte a sur
            for v in bm.verts:
                v.co = Vector((v.co.x * largo, v.co.y * (L / n) * 1.35, v.co.z * 0.06))
            ob = _obj("%s_%d_%d" % (nombre, lado, i), bm, material)
            ob.location = V(px, (y_sur + y_norte) * 0.5, pz)
            ob.rotation_euler = (pend - math.radians(2.5), 0, lado * math.radians(90))
            partes.append(ob)
    cb = cilindro((xm, (y_sur + y_norte) * 0.5, zc + 0.05), 0.11, largo + 0.1, material, 10, nombre + "_cumbrera", eje='Y')
    partes.append(cb)
    if madera is not None:   # tablas del alero en el hastial
        for lado in (-1, 1):
            a = (xm, y_sur + vuelo + 0.02, zc + 0.05)
            b = (xm + lado * semi, y_sur + vuelo + 0.02, zc - math.tan(pend) * semi)
            partes.append(viga(a, b, 0.16, madera, 0.06, nombre + "_tabla"))
    return partes


def hastial_muro(x0, x1, y, z_base, alto, material, grosor=0.25, nombre="hastial_muro"):
    """El triángulo de muro bajo un tejado frontal."""
    bm = bmesh.new()
    xm = (x0 + x1) * 0.5
    pts = [(x0, z_base), (x1, z_base), (xm, z_base + alto)]
    vs = [bm.verts.new((px, -y, pz)) for (px, pz) in pts]
    cara = bm.faces.new(vs)
    r = bmesh.ops.extrude_face_region(bm, geom=[cara])
    for e in r['geom']:
        if isinstance(e, bmesh.types.BMVert):
            e.co.y += grosor
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return _obj(nombre, bm, material)


# ---------------------------------------------------------------- huecos y adornos

def fachada(x0, x1, y, z0, z1, grosor, material, huecos=(), nombre="fachada"):
    """Muro que mira al sur (su cara en y; el grosor hacia el norte) con huecos [(xa, xb, za, zb)]: se hace con
    piezas alrededor de los huecos, que quedan abiertos de verdad (la ventana se hunde y su mocheta hace sombra)."""
    xs = sorted(set([x0, x1] + [h[0] for h in huecos] + [h[1] for h in huecos]))
    zs = sorted(set([z0, z1] + [h[2] for h in huecos] + [h[3] for h in huecos]))
    partes = []
    for i in range(len(xs) - 1):
        j = 0
        while j < len(zs) - 1:
            cx = (xs[i] + xs[i + 1]) * 0.5
            dentro = lambda zz: any(h[0] < cx < h[1] and h[2] < zz < h[3] for h in huecos)
            if dentro((zs[j] + zs[j + 1]) * 0.5):
                j += 1
                continue
            k = j
            while k + 1 < len(zs) - 1 and not dentro((zs[k + 1] + zs[k + 2]) * 0.5):
                k += 1
            partes.append(caja(xs[i], y - grosor, zs[j], xs[i + 1], y, zs[k + 1], material, nombre))
            j = k + 1
    return partes


def entramado(x0, x1, y, z0, z1, huecos, madera, grosor=0.17, saliente=0.05, paso_max=1.25, diagonales=True,
              nombre="entramado"):
    """Vigas de madera sobre una fachada que mira al sur: solera, carrera, postes en las esquinas y a los lados de
    cada hueco, travesaños de antepecho y dintel, y cruces en los paños ciegos (simétricas respecto al centro)."""
    p = []
    g = grosor
    yb = y + saliente
    p.append(caja(x0, y, z0, x1, yb, z0 + g, madera, nombre + "_solera", 0.012))
    p.append(caja(x0, y, z1 - g, x1, yb, z1, madera, nombre + "_carrera", 0.012))
    postes = {round(x0 + g * 0.5, 3), round(x1 - g * 0.5, 3)}
    for h in huecos:
        postes.add(round(h[0] - g * 0.5, 3))
        postes.add(round(h[1] + g * 0.5, 3))
    postes = sorted(postes)
    llenos = []
    for a, b in zip(postes[:-1], postes[1:]):
        hueco = any(h[0] < (a + b) * 0.5 < h[1] for h in huecos)
        if not hueco and b - a > paso_max:
            n = int(math.ceil((b - a) / paso_max))
            for k in range(1, n):
                llenos.append(a + (b - a) * k / n)
    postes = sorted(postes + llenos)
    for px_ in postes:
        p.append(caja(px_ - g * 0.5, y, z0 + g, px_ + g * 0.5, yb, z1 - g, madera, nombre + "_poste", 0.012))
    centro = (x0 + x1) * 0.5
    for a, b in zip(postes[:-1], postes[1:]):
        m = (a + b) * 0.5
        hs = [h for h in huecos if h[0] < m < h[1]]
        if hs:
            h = hs[0]
            if h[2] > z0 + g * 1.5:      # antepecho
                p.append(caja(a + g * 0.5, y, h[2] - g, b - g * 0.5, yb, h[2], madera, nombre + "_antepecho", 0.01))
            if h[3] < z1 - g * 1.5:      # dintel
                p.append(caja(a + g * 0.5, y, h[3], b - g * 0.5, yb, h[3] + g, madera, nombre + "_dintel", 0.01))
        elif diagonales and b - a > 0.45:
            if m < centro:
                p.append(viga((a + g * 0.4, y + saliente * 0.5, z0 + g), (b - g * 0.4, y + saliente * 0.5, z1 - g), g * 0.9, madera, saliente, nombre + "_cruz"))
            else:
                p.append(viga((a + g * 0.4, y + saliente * 0.5, z1 - g), (b - g * 0.4, y + saliente * 0.5, z0 + g), g * 0.9, madera, saliente, nombre + "_cruz"))
    return p


def ventana(cx, y, z0, ancho, alto, madera, vidrio, contraventanas=None, macetas=None, cruz=True, hundida=0.14,
            nombre="ventana", luz=None, saliente=0.05, rejilla=0):
    """Ventana en el hueco de una fachada que mira al sur (y = cara de la fachada): vidrio hundido, marco, alféizar,
    contraventanas abiertas, jardinera con flores y una luz de área que sale hacia la calle (luz=(color, vatios))."""
    p = []
    x0, x1 = cx - ancho * 0.5, cx + ancho * 0.5
    g = 0.08
    yv = y - hundida
    p.append(caja(x0, yv - 0.03, z0, x1, yv, z0 + alto, vidrio, nombre + "_vidrio"))
    p.append(caja(x0 - g, y - 0.02, z0 - 0.02, x0, y + saliente, z0 + alto + 0.02, madera, nombre + "_m1", 0.008))
    p.append(caja(x1, y - 0.02, z0 - 0.02, x1 + g, y + saliente, z0 + alto + 0.02, madera, nombre + "_m2", 0.008))
    p.append(caja(x0 - g, y - 0.02, z0 + alto, x1 + g, y + saliente, z0 + alto + g * 1.3, madera, nombre + "_m3", 0.008))
    p.append(caja(x0 - g * 1.8, y - 0.04, z0 - g * 1.2, x1 + g * 1.8, y + saliente + 0.11, z0, madera, nombre + "_alfeizar", 0.01))
    if cruz:
        p.append(caja(cx - 0.022, yv, z0, cx + 0.022, yv + 0.035, z0 + alto, madera, nombre + "_parteluz"))
        p.append(caja(x0, yv, z0 + alto * 0.58 - 0.022, x1, yv + 0.035, z0 + alto * 0.58 + 0.022, madera, nombre + "_travesano"))
    for k in range(rejilla):                         # emplomado en rombos (ventanas pequeñas de arriba)
        t = (k + 1) / (rejilla + 1)
        p.append(viga((x0 + ancho * t, yv + 0.02, z0), (x0, yv + 0.02, z0 + alto * t), 0.012, madera, 0.02, nombre + "_plomo"))
        p.append(viga((x1 - ancho * t, yv + 0.02, z0), (x1, yv + 0.02, z0 + alto * t), 0.012, madera, 0.02, nombre + "_plomo"))
    if contraventanas is not None:
        for lado in (-1, 1):
            bx = (x0 - g - ancho * 0.5) if lado < 0 else (x1 + g)
            p.append(caja(bx, y + 0.0, z0 - 0.02, bx + ancho * 0.5, y + 0.045, z0 + alto + 0.02, contraventanas, nombre + "_hoja", 0.012))
            for k in range(2):
                zz = z0 + alto * (0.25 + 0.42 * k)
                p.append(caja(bx + 0.03, y + 0.045, zz, bx + ancho * 0.5 - 0.03, y + 0.06, zz + 0.035, madera, nombre + "_liston"))
    if macetas is not None:
        p.append(caja(x0 - 0.06, y + 0.02, z0 - g * 1.2 - 0.2, x1 + 0.06, y + 0.28, z0 - g * 1.2, madera, nombre + "_jardinera", 0.012))
        rnd = random.Random(int(cx * 1000 + z0 * 10))
        n = max(4, int(ancho / 0.13))
        for i in range(n):
            fx = x0 + (i + 0.5) * (ancho + 0.12) / n - 0.06
            p.append(esfera((fx, y + 0.15 + rnd.uniform(-0.05, 0.05), z0 - g * 1.2 + 0.02 + rnd.uniform(0, 0.08)),
                            0.085 + rnd.uniform(0, 0.035), macetas[0] if rnd.random() < 0.55 else macetas[1], nombre + "_flor", 2))
            if rnd.random() < 0.5:
                p.append(esfera((fx + rnd.uniform(-0.05, 0.05), y + 0.24, z0 - g * 1.2 - 0.06), 0.07, macetas[2] if len(macetas) > 2 else macetas[0], nombre + "_hoja", 2))
    if luz is not None:
        luz_area((cx, yv + 0.06, z0 + alto * 0.5), (ancho * 0.9, alto * 0.9), luz[0], luz[1], nombre + "_luz", hacia='S')
        # un poco de esa luz en el muro de alrededor y en el alféizar (lo que hace acogedora una fachada de noche)
        luz_punto((cx, y + 0.42, z0 + alto * 0.35), luz[0], luz[1] * 0.3, 0.12, nombre + "_brillo")
    return p


def puerta(cx, y, ancho, alto, madera, herraje, marco=None, abierta=0.0, interior=None, hundida=0.16, z0=0.0,
           nombre="puerta", luz=None):
    """Puerta de tablas en el hueco de una fachada que mira al sur. Con abierta > 0, la hoja gira hacia dentro y se ve
    el interior (un plano que emite: la taberna encendida); luz=(color, vatios) echa esa luz a la calle."""
    p = []
    x0, x1 = cx - ancho * 0.5, cx + ancho * 0.5
    mc = marco if marco is not None else madera
    g = 0.13
    yp = y - hundida
    p.append(caja(x0 - g, y - 0.02, z0, x0, y + 0.08, z0 + alto + g, mc, nombre + "_jamba1", 0.012))
    p.append(caja(x1, y - 0.02, z0, x1 + g, y + 0.08, z0 + alto + g, mc, nombre + "_jamba2", 0.012))
    p.append(caja(x0 - g * 1.5, y - 0.02, z0 + alto, x1 + g * 1.5, y + 0.12, z0 + alto + g * 1.6, mc, nombre + "_dintel", 0.012))
    if interior is not None:
        p.append(caja(x0 - 0.05, yp - 0.9, z0, x1 + 0.05, yp - 0.86, z0 + alto, interior, nombre + "_interior"))
    tablas = max(3, int(ancho / 0.17))
    w = ancho / tablas
    hojas = []
    for i in range(tablas):
        hojas.append(caja(i * w + 0.005, -0.045, 0.02, (i + 1) * w - 0.005, 0.0, alto - 0.02, madera, nombre + "_tabla", 0.004))
    for zz in (alto * 0.18, alto * 0.74):
        hojas.append(caja(0.03, 0.0, zz, ancho - 0.03, 0.025, zz + 0.07, herraje, nombre + "_bisagra"))
    piv = V(x0, yp, z0)
    ang = math.radians(75.0 * abierta)               # hacia dentro (norte), girando sobre la jamba oeste
    for h in hojas:
        h.location = piv
        h.rotation_euler = (0, 0, ang)
        p.append(h)
    if abierta == 0:
        p.append(cilindro((x1 - 0.15, yp + 0.05, z0 + alto * 0.48), 0.035, 0.05, herraje, 10, nombre + "_aldaba", eje='Y'))
    if luz is not None:
        luz_area((cx, yp - 0.3, z0 + alto * 0.55), (ancho * 0.8, alto * 0.8), luz[0], luz[1], nombre + "_luz", hacia='S')
    return p


def chimenea(cx, cy, z0, alto, ancho, material, sombrero=None, nombre="chimenea"):
    """Chimenea de piedra; devuelve (partes, punto de salida del humo en casillas del juego)."""
    p = [caja(cx - ancho * 0.5, cy - ancho * 0.5, z0, cx + ancho * 0.5, cy + ancho * 0.5, z0 + alto, material, nombre, 0.02)]
    s = sombrero if sombrero is not None else material
    p.append(caja(cx - ancho * 0.6, cy - ancho * 0.6, z0 + alto, cx + ancho * 0.6, cy + ancho * 0.6, z0 + alto + 0.12, s, nombre + "_remate", 0.02))
    p.append(caja(cx - ancho * 0.3, cy - ancho * 0.3, z0 + alto + 0.12, cx + ancho * 0.3, cy + ancho * 0.3, z0 + alto + 0.13, mat("liso", (0.01, 0.01, 0.01, 1), 1.0, nombre="hollin"), nombre + "_boca"))
    return p, (cx, cy, z0 + alto + 0.15)


def barril(c, material_madera, material_aro, alto=0.9, r=0.34, nombre="barril", tumbado=False):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=18, radius1=r, radius2=r, depth=alto)
    for v in bm.verts:
        k = 1.0 - (2.0 * v.co.z / alto) ** 2
        f = 1.0 + 0.13 * max(0.0, k)
        v.co.x *= f
        v.co.y *= f
    ob = _obj(nombre, bm, material_madera)
    for p in ob.data.polygons:
        p.use_smooth = True
    partes = [ob]
    for zz in (-0.36, -0.12, 0.12, 0.36):
        k = 1.0 - (2.0 * zz) ** 2
        rr = r * (1.0 + 0.13 * max(0.0, k)) + 0.012
        a = cilindro((0, 0, 0), rr, 0.05, material_aro, 18, nombre + "_aro")
        a.location = Vector((0, 0, zz * alto / 0.9))
        a.parent = ob
        partes.append(a)
    if tumbado:
        ob.rotation_euler = (0, math.radians(90), 0)
        ob.location = V(c[0], c[1], c[2] + r)
    else:
        ob.location = V(c[0], c[1], c[2] + alto * 0.5)
    return partes


# ================================================================= luz

LUCES_CIELO = []
LUCES_PRACTICAS = []


def luz_punto(c, color, potencia, radio=0.08, nombre="luz", practica=True):
    ld = bpy.data.lights.new(nombre, 'POINT')
    ld.color = color[:3] if len(color) >= 3 else color
    ld.energy = potencia
    ld.shadow_soft_size = radio
    ob = bpy.data.objects.new(nombre, ld)
    enlazar(ob)
    ob.location = V(*c)
    ob.visible_camera = False
    ob.visible_glossy = False
    (LUCES_PRACTICAS if practica else LUCES_CIELO).append(ob)
    return ob


def luz_area(c, tam, color, potencia, nombre="luz_area", hacia='S', practica=True):
    ld = bpy.data.lights.new(nombre, 'AREA')
    ld.shape = 'RECTANGLE'
    ld.size = tam[0]
    ld.size_y = tam[1]
    ld.color = color[:3]
    ld.energy = potencia
    ob = bpy.data.objects.new(nombre, ld)
    enlazar(ob)
    ob.location = V(*c)
    # la luz de área emite hacia su -Z local
    dirs = {'S': Vector((0, -1, 0)), 'N': Vector((0, 1, 0)), 'ABAJO': Vector((0, 0, -1)), 'E': Vector((1, 0, 0)),
            'O': Vector((-1, 0, 0))}
    d = dirs[hacia] if isinstance(hacia, str) else Vector(hacia)
    ob.rotation_euler = (-d).to_track_quat('Z', 'Y').to_euler()
    ob.visible_camera = False
    ob.visible_glossy = False
    (LUCES_PRACTICAS if practica else LUCES_CIELO).append(ob)
    return ob


def imagen(nombre, px):
    """Imagen de Blender (empaquetada) desde un arreglo numpy (alto, ancho, 4) con valores sRGB 0..1, fila 0 arriba."""
    import numpy as np
    h, w = px.shape[:2]
    im = bpy.data.images.new(nombre, w, h, alpha=True)
    im.pixels[:] = np.clip(px[::-1], 0, 1).astype(np.float32).ravel()
    im.pack()
    return im


def m_imagen(im, rugosidad=0.9, nombre="imagen", emision=0.0, interpolacion='Linear'):
    """Material con una imagen (color y alfa: lo transparente se ve a través)."""
    m, nt, b = _material(nombre)
    tx = _n(nt, 'ShaderNodeTexImage', -300, 0)
    tx.image = im
    tx.interpolation = interpolacion
    _l(nt, tx.outputs['Color'], b.inputs['Base Color'])
    _l(nt, tx.outputs['Alpha'], b.inputs['Alpha'])
    b.inputs['Roughness'].default_value = rugosidad
    if emision > 0:
        _l(nt, tx.outputs['Color'], b.inputs['Emission Color'])
        b.inputs['Emission Strength'].default_value = emision
    return m


def plano_imagen(x0, x1, z0, z1, y, material, nombre="plano"):
    """Plano vertical que mira al sur (y = su cara), con UV de 0 a 1."""
    bm = bmesh.new()
    vs = [bm.verts.new(V(x0, y, z0)), bm.verts.new(V(x1, y, z0)), bm.verts.new(V(x1, y, z1)), bm.verts.new(V(x0, y, z1))]
    cara = bm.faces.new(vs)
    uv = bm.loops.layers.uv.new()
    for lp, co in zip(cara.loops, ((0, 0), (1, 0), (1, 1), (0, 1))):
        lp[uv].uv = co
    ob = _obj(nombre, bm, material)
    if ob.data.polygons[0].normal.y > 0:
        ob.data.flip_normals()
    return ob


CALIDA = hexlin("#FFB45A")
FAROL = hexlin("#F2C86B")


def cielo_hora_azul(fuerza=1.5, clave=0.85, centro=(40.0, 28.0)):
    """La hora azul: cielo índigo arriba y azul pizarra en el horizonte, un resto de rosa al oeste (el sol acaba de
    ponerse) y una luz grande y suave del oeste que modela las formas. Nada de sol directo."""
    sc = bpy.context.scene
    w = bpy.data.worlds.new("hora_azul")
    sc.world = w
    w.use_nodes = True
    nt = w.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = _n(nt, 'ShaderNodeOutputWorld', 600, 0)
    bg = _n(nt, 'ShaderNodeBackground', 400, 0)
    tc = _n(nt, 'ShaderNodeTexCoord', -800, 0)
    sep = _n(nt, 'ShaderNodeSeparateXYZ', -600, 0)
    _l(nt, tc.outputs['Generated'], sep.inputs['Vector'])
    alto = _math(nt, 'MAXIMUM', sep.outputs['Z'], 0.0, -400, 100)
    col = _rampa(nt, alto, [(0.0, hexlin("#7E86B8")), (0.18, hexlin("#4A5A8C")), (0.55, hexlin("#2A3366")),
                           (1.0, hexlin("#1D1B4D"))], -200, 100)
    # resto de rosa al oeste (x < 0), solo cerca del horizonte
    oeste = _math(nt, 'MULTIPLY', _math(nt, 'MAXIMUM', _math(nt, 'MULTIPLY', sep.outputs['X'], -1.0, -400, -100), 0.0, -250, -100),
                  _math(nt, 'SUBTRACT', 1.0, _math(nt, 'MULTIPLY', alto, 3.0, -400, -250), -250, -250, True), -100, -150)
    col = _mezcla(nt, _math(nt, 'MULTIPLY', oeste, 0.55, 0, -150), col, hexlin("#C98E9A"), 'MIX', 150, 50)
    # el suelo que rodea (para los rebotes): oscuro y algo cálido
    bajo = _math(nt, 'LESS_THAN', sep.outputs['Z'], 0.0, -400, 250)
    col = _mezcla(nt, bajo, col, hexlin("#2B2A33"), 'MIX', 280, 150)
    _l(nt, col, bg.inputs['Color'])
    bg.inputs['Strength'].default_value = fuerza
    _l(nt, bg.outputs['Background'], out.inputs['Surface'])
    # clave: un gran rectángulo de cielo claro al oeste-suroeste, bajo (ilumina las fachadas sur desde la izquierda
    # y las sombras caen hacia el noreste, detrás de cada pieza)
    pos = (centro[0] - 70.0, centro[1] + 28.0, 42.0)
    d = (V(*centro, 0.0) - V(*pos)).normalized()
    luz_area(pos, (60, 40), hexlin("#AFB7E6"), 1.4e5 * clave, "cielo_oeste", hacia=(d.x, d.y, d.z), practica=False)
    return w


def apagar_cielo(si):
    """Para la pasada de luz en el suelo: solo las luces prácticas (ventanas, faroles, velas)."""
    sc = bpy.context.scene
    bg = [n for n in sc.world.node_tree.nodes if n.type == 'BACKGROUND'][0]
    if si:
        bg["fuerza_guardada"] = bg.inputs['Strength'].default_value
        bg.inputs['Strength'].default_value = 0.0
    else:
        bg.inputs['Strength'].default_value = bg.get("fuerza_guardada", 1.0)
    for l in LUCES_CIELO:
        l.hide_render = si


# ================================================================= cámara y horneado

def objetos_malla():
    return [o for o in bpy.context.scene.objects if o.type == 'MESH']


def marco_pantalla(objetos, margen=6):
    """Rectángulo (x0, y0, x1, y1) en píxeles del mundo 2D que cubre los objetos (con margen), en enteros."""
    deps = bpy.context.evaluated_depsgraph_get()
    xs, ys = [], []
    for ob in objetos:
        ev = ob.evaluated_get(deps)
        for c in ev.bound_box:
            p = ev.matrix_world @ Vector(c)
            sx, sy = a_pantalla(p)
            xs.append(sx)
            ys.append(sy)
    return (int(math.floor(min(xs))) - margen, int(math.floor(min(ys))) - margen,
            int(math.ceil(max(xs))) + margen, int(math.ceil(max(ys))) + margen)


def poner_camara(marco):
    """Cámara para que el píxel (i, j) de la imagen sea el píxel (x0 + i, y0 + j) del mundo 2D."""
    sc = bpy.context.scene
    x0, y0, x1, y1 = marco
    w, h = x1 - x0, y1 - y0
    cam = sc.camera
    if cam is None:
        cd = bpy.data.cameras.new("cam")
        cam = bpy.data.objects.new("cam", cd)
        enlazar(cam)
        sc.camera = cam
    cd = cam.data
    cd.type = 'ORTHO'
    cd.sensor_fit = 'HORIZONTAL'
    cd.ortho_scale = w / PX
    cd.clip_start = 0.1
    cd.clip_end = 400.0
    cd.shift_x = 0.0
    cd.shift_y = 0.0
    sc.render.resolution_x = w
    sc.render.resolution_y = h
    sc.render.pixel_aspect_x = 1.0 / math.sin(PHI)
    sc.render.pixel_aspect_y = 1.0
    # el centro de la imagen es el punto del suelo (z = 0) que cae en el centro del marco
    cx = (x0 + x1) * 0.5 / PX
    cy = (y0 + y1) * 0.5 / PX
    vista = Vector((0.0, math.cos(PHI), -math.sin(PHI)))
    cam.location = V(cx, cy, 0.0) - vista * 150.0
    cam.rotation_euler = (math.pi * 0.5 - PHI, 0.0, 0.0)
    return cam


def suelo_bajo(marco, z=0.0, nombre="suelo"):
    """Plano del suelo que cubre todo el marco (para rebotes, sombra y luz en el suelo)."""
    x0, y0, x1, y1 = marco
    # el marco en pantalla, llevado al suelo (z = 0): y del mundo = y de pantalla
    gx0, gx1 = x0 / PX - 2, x1 / PX + 2
    gy0, gy1 = y0 / PX - 2, y1 / PX + 30
    bm = bmesh.new()
    for (px_, py_) in ((gx0, gy0), (gx1, gy0), (gx1, gy1), (gx0, gy1)):
        bm.verts.new((px_, -py_, z))
    bm.faces.new(bm.verts)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    ob = _obj(nombre, bm, None)
    if ob.data.polygons[0].normal.z < 0:
        ob.data.flip_normals()
    return ob
