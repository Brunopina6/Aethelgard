# Láminas de presentación de la familia de NPC chibi (V12, especialista de mundo 3D y NPC). Lee los GLB que exporta
# crear_npc_chibi.py (lo mismo que recibe Godot) y les pone el atlas de cada persona.
#
#   blender -b --factory-startup -P fuente/render_npc_chibi.py -- <raíz aethelgard> <carpeta de láminas> [familia|clips|cara] [oficios]
#
# Escribe <láminas>/familia.png (todas las personas de frente y de 3/4, con Kael a escala), clips_<oficio>.png (reposo,
# caminar, tarea, hablar y saludar, en un fotograma representativo) y caras.png (primeros planos).
import bpy, sys, os, math, json
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
RAIZ, LAMINAS = argv[0], argv[1]
QUE = argv[2] if len(argv) > 2 else "familia"
SOLO = argv[3].split(",") if len(argv) > 3 and argv[3] else []
sys.dont_write_bytecode = True          # sin __pycache__ en la carpeta de otra área
sys.path.insert(0, os.path.join(RAIZ, "personajes", "desierto", "fuentes_blender"))
import desierto_comun as C

NPC = os.path.join(RAIZ, "personajes", "npc_v12")
G = 300                      # fotograma global de la lámina (cada copia lleva su clip desplazado por NLA)


def oficios():
    r = []
    for n in sorted(os.listdir(NPC)):
        if n != "v1" and os.path.isfile(os.path.join(NPC, n, n + ".glb")) and (not SOLO or n in SOLO):
            r.append(n)
    return r


def importar(oficio, raiz=None):
    raiz = raiz or NPC
    antes_o, antes_a = set(bpy.data.objects), set(bpy.data.actions)
    bpy.ops.import_scene.gltf(filepath=os.path.join(raiz, oficio, oficio + ".glb"))
    nuevos = [o for o in bpy.data.objects if o not in antes_o]
    acciones = {}
    for a in bpy.data.actions:
        if a not in antes_a:
            base = a.name.split(".")[0]
            for clip in ("reposo", "caminar", "correr", "hablar", "saludar", "tarea"):
                if base.startswith(clip):
                    acciones[clip] = a
    arm = next(o for o in nuevos if o.type == 'ARMATURE')
    malla = next(o for o in nuevos if o.type == 'MESH' and o.parent == arm)   # el importador añade una «Icosphere» para los huesos
    for o in nuevos:
        o.hide_render = True
        o.hide_viewport = True
    datos = json.load(open(os.path.join(raiz, oficio, oficio + ".json"), encoding="utf-8"))
    return arm, malla, acciones, datos


def material_persona(malla, oficio, persona, raiz=None):
    raiz = raiz or NPC
    m = malla.data.materials[0].copy()
    m.name = "m_" + persona + ("_v1" if raiz != NPC else "")
    img = bpy.data.images.load(os.path.join(raiz, oficio, persona + ".png"), check_existing=False)
    for n in m.node_tree.nodes:
        if n.type == 'TEX_IMAGE':
            n.image = img
    return m


def copia(arm, malla, mat, accion, fotograma, pos, giro):
    a2 = arm.copy()
    bpy.context.scene.collection.objects.link(a2)
    a2.animation_data_clear()
    a2.animation_data_create()
    m2 = malla.copy()
    m2.data = malla.data.copy()
    bpy.context.scene.collection.objects.link(m2)
    m2.data.materials.clear()
    m2.data.materials.append(mat)
    m2.parent = a2
    for md in m2.modifiers:
        if md.type == 'ARMATURE':
            md.object = a2
    a2.hide_render = m2.hide_render = False
    a2.hide_viewport = m2.hide_viewport = False
    pista = a2.animation_data.nla_tracks.new()
    tira = pista.strips.new(accion.name, int(G - fotograma + 1), accion)
    try:
        if len(accion.slots):
            tira.action_slot = accion.slots[0]
    except AttributeError:
        pass
    tira.extrapolation = 'HOLD'
    a2.location = pos
    a2.rotation_mode = 'XYZ'
    a2.rotation_euler = (0, 0, math.radians(giro))
    return a2


def escena(ancho, alto, fondo=(0.90, 0.88, 0.84)):
    esc = C.escena_vacia()
    C.preparar_render(esc, ancho, alto, fondo=fondo)
    for nom, energia, rot, color in (("sol", 3.0, (50, 8, 35), (1.0, 0.95, 0.86)),
                                     ("relleno", 1.3, (70, 0, -120), (0.78, 0.85, 1.0)),
                                     ("contra", 2.2, (120, 0, 200), (1.0, 0.88, 0.7))):
        l = bpy.data.lights.new(nom, 'SUN')
        l.energy, l.color = energia, color
        o = bpy.data.objects.new(nom, l)
        esc.collection.objects.link(o)
        o.rotation_euler = [math.radians(a) for a in rot]
    C.suelo(esc, color=(0.80, 0.78, 0.72), tam=60)
    return esc


def nombre_bonito(p):
    return p.replace("_", " ")


def familia():
    lista = oficios()
    personas = []
    esc = escena(2600, 1300)
    cargados = {o: importar(o) for o in lista}
    for o in lista:
        arm, malla, acc, datos = cargados[o]
        for p in datos["personas"]:
            personas.append((o, p))
    n = len(personas)
    fila = math.ceil(n / 2)
    sep = 1.05
    for i, (o, p) in enumerate(personas):
        arm, malla, acc, datos = cargados[o]
        f, c = divmod(i, fila)
        x = (c - (fila - 1) / 2) * sep
        y = f * 3.4
        copia(arm, malla, material_persona(malla, o, p), acc["reposo"], 1, (x, y, 0), -18)
        C.texto(esc, nombre_bonito(p), (x, y - 0.5, 0.02), 0.075, giro=(60, 0, 0))
    C.importar_kael(RAIZ, 1.7, ((fila / 2 + 0.6) * sep, 0, 0), -18)
    C.texto(esc, "Kael 1,7 m", ((fila / 2 + 0.6) * sep, -0.5, 0.02), 0.075, giro=(60, 0, 0))
    esc.frame_set(G)
    cam = C.camara(esc, (0.3, 1.8, 0.8), 30, 0, 30, orto=fila * sep + 1.8)
    esc.render.filepath = os.path.join(LAMINAS, "familia.png")
    bpy.ops.render.render(write_still=True)


FOTOGRAMAS = {"reposo": 1, "caminar": 1, "correr": 5, "hablar": 22, "saludar": 17}
TAREA_F = {"martillar": 14, "pregonar": 14, "remover": 20, "vigilar": 20, "cavar": 22, "recoger": 18,
           "estirar": 24, "echar_grano": 26, "jugar": 16, "ajustar": 14, "barrer": 12}


def clips():
    for o in oficios():
        esc = escena(2200, 700)
        arm, malla, acc, datos = importar(o)
        mat = material_persona(malla, o, datos["personas"][0])
        cols = ["reposo", "caminar", "tarea", "hablar", "saludar"] + (["correr"] if "correr" in acc else [])
        for i, c in enumerate(cols):
            x = (i - (len(cols) - 1) / 2) * 1.2
            f = TAREA_F.get(datos["tarea"], 20) if c == "tarea" else FOTOGRAMAS[c]
            copia(arm, malla, mat, acc[c], f, (x, 0, 0), -35)
            C.texto(esc, c if c != "tarea" else datos["tarea"], (x, -0.5, 0.02), 0.09, giro=(60, 0, 0))
        esc.frame_set(G)
        C.camara(esc, (0, 0, 0.75), 30, 0, 14, orto=len(cols) * 1.2 + 0.4)
        esc.render.filepath = os.path.join(LAMINAS, "clips_%s.png" % o)
        bpy.ops.render.render(write_still=True)


def caras():
    lista = oficios()
    esc = escena(2400, 1000)
    cargados = {o: importar(o) for o in lista}
    personas = [(o, p) for o in lista for p in cargados[o][3]["personas"]]
    fila = math.ceil(len(personas) / 2)
    for i, (o, p) in enumerate(personas):
        arm, malla, acc, datos = cargados[o]
        f, c = divmod(i, fila)
        x = (c - (fila - 1) / 2) * 0.75
        z_cab = datos["alto"] - 0.3
        a2 = copia(arm, malla, material_persona(malla, o, p), acc["reposo"], 1, (x, -f * 3.0, -z_cab - f * 0.95), 0)
    esc.frame_set(G)
    C.camara(esc, (0, 0, -0.45), 30, 0, 2, orto=fila * 0.75 + 0.2)
    for o in esc.objects:
        if o.name.startswith("Plane"):
            o.hide_render = True
    esc.render.filepath = os.path.join(LAMINAS, "caras.png")
    bpy.ops.render.render(write_still=True)


def comparar():
    """V2: antes (v1, a la izquierda de cada pareja) y después (v2), la primera persona de cada oficio, con Kael."""
    lista = oficios()
    esc = escena(2800, 1400)
    v1 = os.path.join(NPC, "v1")
    fila = math.ceil(len(lista) / 2)
    for i, o in enumerate(lista):
        f, c = divmod(i, fila)
        x0 = (c - (fila - 1) / 2) * 2.0
        y = f * 3.4
        for k, raiz in enumerate((v1, NPC)):
            arm, malla, acc, datos = importar(o, raiz)
            p = datos["personas"][0]
            copia(arm, malla, material_persona(malla, o, p, raiz), acc["reposo"], 1, (x0 - 0.42 + 0.84 * k, y, 0), -18)
        C.texto(esc, o + "  v1 | v2", (x0, y - 0.5, 0.02), 0.075, giro=(60, 0, 0))
    C.importar_kael(RAIZ, 1.7, ((fila / 2 + 0.3) * 2.0, 0, 0), -18)
    C.texto(esc, "Kael 1,7 m", ((fila / 2 + 0.3) * 2.0, -0.5, 0.02), 0.075, giro=(60, 0, 0))
    esc.frame_set(G)
    C.camara(esc, (0.6, 1.8, 0.8), 30, 0, 30, orto=fila * 2.0 + 2.0)
    esc.render.filepath = os.path.join(LAMINAS, "comparar_v1_v2.png")
    bpy.ops.render.render(write_still=True)


def primer_plano():
    """V2: Kael y cuatro de la familia de cerca (v1 detrás en gris no: solo la v2), a la altura de los ojos."""
    esc = escena(2400, 1100)
    sel = [o for o in ["guardia", "campesina", "nino", "anciano", "herrero"] if o in oficios()]
    for i, o in enumerate(sel):
        arm, malla, acc, datos = importar(o)
        copia(arm, malla, material_persona(malla, o, datos["personas"][0]), acc["reposo"], 1, ((i - 2.5) * 0.85, 0, 0), -15)
    C.importar_kael(RAIZ, 1.7, (2.5 * 0.85, 0, 0), -15)
    esc.frame_set(G)
    C.camara(esc, (0, 0, 0.95), 30, 0, 4, orto=5.4)
    esc.render.filepath = os.path.join(LAMINAS, "primer_plano_v2.png")
    bpy.ops.render.render(write_still=True)


{"familia": familia, "clips": clips, "cara": caras, "comparar": comparar, "cerca": primer_plano}[QUE]()
print("HECHO", QUE)
