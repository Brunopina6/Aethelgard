# La estatua sin brazo de las Cumbres de Ciclópea (V12, especialista de mundo, 13/11): pieza propia para el detalle
# «ciclopea_estatua» (progreso.gd: «Un caballero de piedra sin brazo izquierdo. Mira hacia el pico.»). Obra propia, por
# guion: geometría por partes con color por vértice (piedra gastada, líquenes, escarcha y nieve), sin texturas.
#
#   blender -b --factory-startup -P fuente/crear_estatua_ciclopea.py -- <raíz aethelgard> <carpeta de láminas>
#
# Escribe zonas3d/ciclopea/modelos/estatua.glb (Godot genera los LOD al importar) y <láminas>/estatua_lamina.png.
# Ejes de Blender: la estatua mira a −Y (en Godot, a +Z; la escena la gira hacia el norte, el pico), Z arriba.
# Un caballero de proporciones heroicas sobre su peana: yelmo cerrado alzado hacia el pico, capa que cae por detrás,
# la mano derecha sobre el pomo de la espada clavada delante; el hombro izquierdo, roto: un muñón de piedra quebrada.
import bpy, bmesh, sys, os, math, random
from mathutils import Vector, Matrix, Euler, noise

argv = sys.argv[sys.argv.index("--") + 1:]
RAIZ, LAMINAS = argv[0], argv[1]
SALIDA = os.path.join(RAIZ, "zonas3d", "ciclopea", "modelos")
random.seed(3)

PIEDRA = (0.56, 0.57, 0.60)
PIEDRA_OSC = (0.36, 0.37, 0.41)
LIQUEN = (0.55, 0.58, 0.44)
OCRE = (0.62, 0.52, 0.36)
NIEVE = (0.93, 0.96, 1.0)
HIELO = (0.72, 0.84, 0.95)

bpy.ops.wm.read_factory_settings(use_empty=True)
bm = bmesh.new()
col_capa = bm.loops.layers.float_color.new("Col")


def _transformar(vs, M):
    bmesh.ops.transform(bm, matrix=M, verts=vs)


def caja(centro, tam, giro=(0, 0, 0)):
    r = bmesh.ops.create_cube(bm, size=1.0)
    _transformar(r["verts"], Matrix.Translation(Vector(centro)) @ Euler(giro).to_matrix().to_4x4() @
                 Matrix.Diagonal((tam[0], tam[1], tam[2], 1)))
    return r["verts"]


def cilindro(a, b, r0, r1, lados=10):
    a, b = Vector(a), Vector(b)
    eje = b - a
    r = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=lados, radius1=r0, radius2=r1, depth=eje.length)
    rot = Vector((0, 0, 1)).rotation_difference(eje.normalized()).to_matrix().to_4x4()
    _transformar(r["verts"], Matrix.Translation((a + b) * 0.5) @ rot)
    return r["verts"]


def esfera(centro, radios, seg=(12, 8), giro=(0, 0, 0)):
    r = bmesh.ops.create_uvsphere(bm, u_segments=seg[0], v_segments=seg[1], radius=1.0)
    _transformar(r["verts"], Matrix.Translation(Vector(centro)) @ Euler(giro).to_matrix().to_4x4() @
                 Matrix.Diagonal((radios[0], radios[1], radios[2], 1)))
    return r["verts"]


def gastar(vs, fuerza=0.012, escala=6.0):
    """Piedra gastada por el viento: desplaza un poco cada vértice con ruido."""
    for v in vs:
        n = noise.noise(v.co * escala)
        v.co += v.co.normalized() * 0 + Vector((n, noise.noise(v.co * escala + Vector((5, 1, 2)))
                                               , noise.noise(v.co * escala + Vector((1, 7, 3))))) * fuerza


def pintar(vs, base, nieve_arriba=0.0, liso=True):
    """Color por esquina: la piedra con manchas de liquen y ocre, más oscura abajo y en los huecos; nieve donde la cara
    mira hacia arriba (nieve_arriba: lo que cubre, 0-1)."""
    caras = {f for v in vs for f in v.link_faces}
    for f in caras:
        f.smooth = liso
        f.normal_update()
        for lp in f.loops:
            p = lp.vert.co
            n1 = noise.noise(p * 3.1) * 0.5 + 0.5
            n2 = noise.noise(p * 9.0 + Vector((3, 3, 3))) * 0.5 + 0.5
            c = Vector(base)
            c = c.lerp(Vector(PIEDRA_OSC), max(0.0, 0.55 - p.z / 4.0) * 0.5 + (1.0 - n2) * 0.18)
            if n1 > 0.68:
                c = c.lerp(Vector(LIQUEN), (n1 - 0.68) * 2.2)
            if n2 > 0.85:
                c = c.lerp(Vector(OCRE), (n2 - 0.85) * 3.0)
            arriba = f.normal.z
            if nieve_arriba > 0.0 and arriba > 0.45:
                k = min(1.0, (arriba - 0.45) * 2.4) * nieve_arriba * (0.75 + 0.25 * n1)
                c = c.lerp(Vector(NIEVE), k)
            elif arriba < -0.2:
                c = c * 0.82                                  # lo de abajo, en sombra
            lp[col_capa] = (c.x, c.y, c.z, 1.0)


def pintar_color(vs, rgb, liso=True):
    for f in {f for v in vs for f in v.link_faces}:
        f.smooth = liso
        for lp in f.loops:
            lp[col_capa] = (*rgb, 1.0)


# ------------------------------------------------------------------ la peana
H0 = 0.0
vs = caja((0, 0, 0.16), (1.5, 1.5, 0.32))
gastar(vs, 0.02, 3.0)
pintar(vs, PIEDRA_OSC, 0.9, liso=False)
vs = caja((0, 0, 0.47), (1.22, 1.22, 0.3))
gastar(vs, 0.015, 3.0)
pintar(vs, PIEDRA, 1.0, liso=False)
vs = caja((0, 0, 0.66), (1.32, 1.32, 0.08))                    # la cornisa
pintar(vs, PIEDRA, 1.0, liso=False)
for k in range(4):                                              # nieve amontonada en las esquinas de abajo
    a = k * math.pi / 2 + math.pi / 4
    vs = esfera((math.cos(a) * 0.82, math.sin(a) * 0.82, 0.08), (0.28, 0.24, 0.14), (8, 5))
    pintar_color(vs, NIEVE)
# una placa con el anillo partido grabado, al frente (−Y), gastada
vs = caja((0, -0.615, 0.46), (0.5, 0.02, 0.2))
pintar(vs, PIEDRA_OSC, 0.0, liso=False)
for k in range(10):
    a = math.radians(30 + k * 30)
    if 3 <= k <= 4:
        continue                                                # el anillo, partido
    vs = caja((math.cos(a) * 0.07, -0.628, 0.46 + math.sin(a) * 0.07), (0.035, 0.01, 0.018), (0, a, 0))
    pintar_color(vs, (0.30, 0.31, 0.34))

TOP = 0.70                                                      # la figura empieza aquí
# ------------------------------------------------------------------ piernas y sabatones (de frente, algo abiertas)
for l in (1, -1):
    x = 0.17 * l
    vs = cilindro((x, 0.02, TOP + 0.05), (x * 1.05, 0.0, TOP + 0.55), 0.11, 0.12, 10)     # grebas
    gastar(vs)
    pintar(vs, PIEDRA, 0.2)
    vs = esfera((x * 1.05, -0.06, TOP + 0.58), (0.09, 0.07, 0.08), (8, 6))              # rodillera
    pintar(vs, PIEDRA, 0.5)
    vs = cilindro((x * 1.05, 0.0, TOP + 0.58), (x * 1.1, 0.01, TOP + 1.05), 0.12, 0.14, 10)  # muslos
    gastar(vs)
    pintar(vs, PIEDRA, 0.2)
    vs = esfera((x, -0.08, TOP + 0.06), (0.11, 0.2, 0.07), (10, 6))                     # sabatón
    pintar(vs, PIEDRA, 0.8)
# faldón de láminas (tassets) con pliegues
vs = cilindro((0, 0.0, TOP + 0.82), (0, 0.0, TOP + 1.22), 0.34, 0.27, 16)
for v in vs:
    a = math.atan2(v.co.y, v.co.x)
    k = 1.0 + 0.06 * math.sin(a * 8.0) * max(0.0, (TOP + 1.22 - v.co.z) / 0.4)
    v.co.x *= k
    v.co.y *= k
pintar(vs, PIEDRA, 0.5)
# ------------------------------------------------------------------ tronco con peto y cinturón
vs = esfera((0, 0.0, TOP + 1.52), (0.34, 0.24, 0.42), (14, 10))
gastar(vs, 0.008)
pintar(vs, PIEDRA, 0.6)
vs = cilindro((0, 0, TOP + 1.18), (0, 0, TOP + 1.25), 0.3, 0.3, 14)
pintar(vs, PIEDRA_OSC, 0.4)
vs = caja((0, -0.27, TOP + 1.22), (0.12, 0.04, 0.09))        # hebilla
pintar(vs, PIEDRA_OSC, 0.6, liso=False)
# el emblema del peto: un ala en relieve
for k in range(5):
    vs = caja((0.02 * k - 0.04, -0.235, TOP + 1.6 - 0.04 * k), (0.12 - 0.02 * k, 0.02, 0.03), (0, 0, 0.3))
    pintar(vs, PIEDRA, 0.2, liso=False)
# ------------------------------------------------------------------ hombros: el derecho entero, el izquierdo roto
HOMBRO = TOP + 1.82
vs = esfera((-0.4, 0.0, HOMBRO), (0.2, 0.2, 0.15), (12, 8))   # hombrera derecha (la derecha de la figura es −X)
gastar(vs)
pintar(vs, PIEDRA, 1.0)
vs = esfera((-0.44, 0.0, HOMBRO + 0.11), (0.14, 0.14, 0.05), (10, 5))   # nieve en la hombrera
pintar_color(vs, NIEVE)
# el izquierdo: la hombrera partida y el muñón quebrado (aristas vivas, sin suavizar)
vs = esfera((0.38, 0.0, HOMBRO - 0.02), (0.17, 0.18, 0.12), (10, 7))
for v in vs:
    if v.co.x > 0.45:
        v.co.x = 0.45 + (v.co.x - 0.45) * 0.2 + random.uniform(-0.02, 0.02)   # cortada en seco
pintar(vs, PIEDRA, 0.8, liso=False)
vs = cilindro((0.43, 0, HOMBRO - 0.06), (0.52, -0.01, HOMBRO - 0.2), 0.085, 0.09, 7)    # el muñón
for v in vs:
    if v.co.z < HOMBRO - 0.17:
        v.co += Vector((random.uniform(-0.03, 0.03), random.uniform(-0.03, 0.03), random.uniform(-0.05, 0.03)))
pintar(vs, PIEDRA_OSC, 0.0, liso=False)
vs = esfera((0.5, -0.01, HOMBRO - 0.21), (0.08, 0.08, 0.035), (7, 4))   # la cara de la rotura, más clara
pintar_color(vs, (0.70, 0.70, 0.70), liso=False)
# ------------------------------------------------------------------ el brazo derecho con la mano en el pomo
codo = Vector((-0.46, -0.12, TOP + 1.38))
mano = Vector((-0.14, -0.42, TOP + 1.12))
vs = cilindro((-0.42, 0.0, HOMBRO - 0.05), codo, 0.09, 0.085, 9)
pintar(vs, PIEDRA, 0.3)
vs = esfera(codo, (0.085, 0.085, 0.085), (8, 6))
pintar(vs, PIEDRA, 0.3)
vs = cilindro(codo, mano, 0.08, 0.075, 9)
pintar(vs, PIEDRA, 0.3)
vs = esfera(mano + Vector((0.0, 0.0, 0.02)), (0.085, 0.075, 0.07), (9, 6))           # guantelete
pintar(vs, PIEDRA, 0.6)
# ------------------------------------------------------------------ la espada clavada delante, la punta en la peana
pomo = Vector((-0.14, -0.42, TOP + 1.04))
vs = esfera(pomo, (0.05, 0.05, 0.05), (8, 6))
pintar(vs, PIEDRA, 0.6)
vs = cilindro(pomo, pomo + Vector((0, 0, -0.2)), 0.03, 0.03, 7)        # empuñadura
pintar(vs, PIEDRA_OSC, 0.0)
vs = caja(pomo + Vector((0, 0, -0.22)), (0.4, 0.06, 0.05))           # cruz
pintar(vs, PIEDRA, 1.0, liso=False)
hoja = cilindro(pomo + Vector((0, 0, -0.24)), Vector((-0.14, -0.42, TOP - 0.02)), 0.055, 0.012, 4)
for v in hoja:
    v.co.y = -0.42 + (v.co.y + 0.42) * 0.3                              # hoja plana
pintar(hoja, PIEDRA, 0.2, liso=False)
# ------------------------------------------------------------------ cuello, yelmo alzado hacia el pico y cimera
ALZA = Euler((math.radians(-14), 0, 0))                                # la cabeza, mirando arriba (el pico)
cuello = Vector((0, 0.0, TOP + 1.95))
vs = cilindro(cuello, cuello + Vector((0, 0, 0.12)), 0.11, 0.1, 10)
pintar(vs, PIEDRA, 0.2)
centro_yelmo = cuello + Vector((0, 0.0, 0.26))


def alzar(vs):
    for v in vs:
        v.co = centro_yelmo + ALZA.to_matrix() @ (v.co - centro_yelmo)


vs = esfera(centro_yelmo, (0.17, 0.19, 0.22), (14, 10))
alzar(vs)
gastar(vs, 0.006)
pintar(vs, PIEDRA, 1.0)
vs = caja(centro_yelmo + Vector((0, -0.17, 0.02)), (0.2, 0.04, 0.025))     # la ranura de la visera, oscura
alzar(vs)
pintar_color(vs, (0.16, 0.17, 0.2), liso=False)
vs = caja(centro_yelmo + Vector((0, -0.17, -0.06)), (0.03, 0.04, 0.12))    # el nasal
alzar(vs)
pintar(vs, PIEDRA, 0.0, liso=False)
cresta = []
for k in range(7):                                                         # la cimera: una cresta de piedra rota
    a = math.radians(-60 + k * 22)
    if k == 5:
        continue                                                           # un trozo que falta
    p = centro_yelmo + Vector((0, math.sin(a) * 0.2, math.cos(a) * 0.23 + 0.02))
    cresta += caja(p, (0.035, 0.07, 0.07), (a, 0, 0))
alzar(cresta)
pintar(cresta, PIEDRA, 1.0, liso=False)
# ------------------------------------------------------------------ la capa: cae por la espalda hasta las pantorrillas
filas = []
for i, z in enumerate((HOMBRO + 0.05, TOP + 1.5, TOP + 1.1, TOP + 0.7, TOP + 0.32)):
    t = i / 4.0
    fila = []
    for j in range(11):
        a = math.radians(-110 + j * 22)
        r = 0.36 + t * 0.14
        pli = 1.0 + 0.07 * t * math.sin(j * math.pi / 2.0)
        fila.append(bm.verts.new((math.sin(a) * r * pli, math.cos(a) * r * 0.72 * pli + 0.06, z)))
    filas.append(fila)
for a_, b_ in zip(filas, filas[1:]):
    for j in range(10):
        bm.faces.new((a_[j + 1], b_[j + 1], b_[j], a_[j]))
capa = [v for f in filas for v in f]
pintar(capa, PIEDRA, 0.4)
copia = [[bm.verts.new(v.co.copy()) for v in f] for f in filas]                # la cara de dentro
for a_, b_ in zip(copia, copia[1:]):
    for j in range(10):
        bm.faces.new((a_[j], b_[j], b_[j + 1], a_[j + 1]))
pintar([v for f in copia for v in f], PIEDRA_OSC, 0.0)
# ------------------------------------------------------------------ carámbanos en el borde de la cornisa (cara norte)
for k in range(9):
    x = -0.55 + k * 0.135 + random.uniform(-0.02, 0.02)
    largo = random.uniform(0.06, 0.16)
    vs = cilindro((x, 0.66, 0.62), (x, 0.66, 0.62 - largo), 0.018, 0.002, 4)
    pintar_color(vs, HIELO)

# ------------------------------------------------------------------ malla, material y exportación
me = bpy.data.meshes.new("estatua")
bm.normal_update()
bm.to_mesh(me)
bm.free()
ob = bpy.data.objects.new("estatua", me)
bpy.context.scene.collection.objects.link(ob)
for ca in [c.name for c in me.color_attributes if c.name != "Col"]:            # solo «Col» (si no, COLOR_0 sale blanco)
    me.color_attributes.remove(me.color_attributes[ca])
print("ESTATUA colores", [c.name for c in me.color_attributes])
me.color_attributes.active_color = me.color_attributes["Col"]
me.color_attributes.render_color_index = me.color_attributes.active_color_index
mat = bpy.data.materials.new("piedra_estatua")
mat.use_nodes = True
nt = mat.node_tree
attr = nt.nodes.new("ShaderNodeVertexColor")
attr.layer_name = "Col"
nt.links.new(attr.outputs["Color"], nt.nodes["Principled BSDF"].inputs["Base Color"])
nt.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.92
me.materials.append(mat)
tris = sum(len(p.vertices) - 2 for p in me.polygons)
print("ESTATUA triangulos", tris, "vertices", len(me.vertices))
os.makedirs(SALIDA, exist_ok=True)
opciones = dict(filepath=os.path.join(SALIDA, "estatua.glb"), export_format='GLB', use_selection=False,
                export_animations=False, export_yup=True, export_cameras=False, export_lights=False,
                export_materials='EXPORT')
props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
if "export_vertex_color" in props:
    opciones["export_vertex_color"] = 'NAME'                     # «Col» como COLOR_0 (con ACTIVE, Blender 5.2 lo dejaba de COLOR_1)
    opciones["export_vertex_color_name"] = "Col"
    opciones["export_all_vertex_colors"] = False
elif "export_colors" in props:
    opciones["export_colors"] = True
bpy.ops.export_scene.gltf(**opciones)

# ------------------------------------------------------------------ lámina: frente, 3/4, perfil y espalda, con Kael
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(RAIZ, "personajes", "desierto", "fuentes_blender"))
import desierto_comun as C
esc = bpy.context.scene
C.preparar_render(esc, 2200, 1000, fondo=(0.80, 0.85, 0.92))
for nom, energia, rot, color in (("sol", 3.0, (55, 10, 145), (0.95, 0.97, 1.0)), ("relleno", 1.2, (70, 0, -40), (0.75, 0.82, 1.0))):
    l = bpy.data.lights.new(nom, 'SUN')
    l.energy, l.color = energia, color
    o = bpy.data.objects.new(nom, l)
    esc.collection.objects.link(o)
    o.rotation_euler = [math.radians(a) for a in rot]
C.suelo(esc, color=(0.90, 0.93, 0.98), tam=40)
xs = [-4.2, -1.6, 1.0, 3.4]
for x, giro in zip(xs, (0, -40, -90, 180)):
    c = ob.copy()
    esc.collection.objects.link(c)
    c.location = (x, 0, 0)
    c.rotation_euler = (0, 0, math.radians(giro))
ob.hide_render = True
C.importar_kael(RAIZ, 1.7, (5.6, 0, 0))
cam = C.camara(esc, (0.7, 0, 1.5), 30, 0, 8, orto=12.5)
esc.render.filepath = os.path.join(LAMINAS, "estatua_lamina.png")
bpy.ops.render.render(write_still=True)
print("HECHO estatua", tris)
