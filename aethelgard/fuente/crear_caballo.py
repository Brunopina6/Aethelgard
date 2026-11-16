# Avena, la yegua del establo del BARRIO EXPERIMENTAL de Oakhaven (V12, 16/11, agente C). PROTOTIPO para enseñar al
# usuario, NO el definitivo (metodología de personajes: se conserva lo anterior y no se presenta como final). Obra propia
# por guion, sin recursos descargados ni Hunyuan3D: geometría por partes, atlas pintado por código, esqueleto propio y
# clips con claves, con la biblioteca de los NPC del desierto (personajes/desierto/fuentes_blender/desierto_comun.py),
# que se importa tal cual.
#
#   blender -b --factory-startup -P fuente/crear_caballo.py -- <raíz aethelgard> <carpeta de láminas>
#
# Escribe personajes/npc_v12/caballo/caballo.glb (+ caballo.json con triángulos y huesos) y, en la carpeta de láminas,
# caballo_lamina.png (tres vistas y los cuatro clips) para enseñarlo.
#
# Avena NO anda (está atada ante el establo): todos los clips son SIN desplazamiento.
#   reposo (4 s, bucle): respira, mueve la cola y la cabeza.   beber (3 s, bucle): cuello abajo, sorbos.
#   comer (3 s, bucle): cabeza baja, masca.                    sacudir (1,6 s): sacude la cabeza y la cola.
# Ejes de Blender: mira a -Y, Z arriba, su izquierda es +X. En Godot mira a +Z (barrio_vivo.gd la gira hacia el
# abrevadero). Presupuesto (plan §9): ≤ 5000 triángulos, ~16 huesos, atlas de 512.
import bpy, sys, os, math, json
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
RAIZ = argv[0]
LAMINAS = argv[1] if len(argv) > 1 else os.path.join(RAIZ, "..", "laminas")
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(RAIZ, "personajes", "desierto", "fuentes_blender"))
import desierto_comun as C

SALIDA = os.path.join(RAIZ, "personajes", "npc_v12", "caballo")
PRESUPUESTO = 5000

# Puntos (m): el lomo a 1,05 m (proporción chibi: los vecinos miden 1,5 m), la cabeza arriba a 1,7 m.
HUESOS = [
    ("raiz", (0, 0, 0), (0, 0, 0.2), None),
    ("cadera", (0, 0.45, 1.02), (0, 0.15, 1.06), "raiz"),
    ("columna", (0, 0.15, 1.06), (0, -0.28, 1.08), "cadera"),
    ("pecho", (0, -0.28, 1.08), (0, -0.52, 1.10), "columna"),
    ("cuello1", (0, -0.52, 1.16), (0, -0.70, 1.42), "pecho"),
    ("cuello2", (0, -0.70, 1.42), (0, -0.84, 1.64), "cuello1"),
    ("cabeza", (0, -0.84, 1.64), (0, -1.22, 1.48), "cuello2"),
    ("cola1", (0, 0.62, 1.04), (0, 0.78, 0.86), "cadera"),
    ("cola2", (0, 0.78, 0.86), (0, 0.84, 0.52), "cola1"),
]
for lado, x in (("L", 0.15), ("R", -0.15)):
    HUESOS += [("del1." + lado, (x, -0.42, 0.92), (x, -0.43, 0.50), "pecho"),
               ("del2." + lado, (x, -0.43, 0.50), (x, -0.45, 0.05), "del1." + lado),
               ("tra1." + lado, (x, 0.42, 0.92), (x, 0.47, 0.50), "cadera"),
               ("tra2." + lado, (x, 0.47, 0.50), (x, 0.43, 0.05), "tra1." + lado)]

COLORES = {"pelaje": (0.58, 0.38, 0.22), "pelaje_claro": (0.72, 0.52, 0.32), "crin": (0.90, 0.84, 0.66),
           "casco": (0.20, 0.15, 0.12), "hocico": (0.36, 0.24, 0.18), "ojo": (0.06, 0.05, 0.05),
           "cuero": (0.42, 0.24, 0.12), "metal": (0.70, 0.66, 0.58), "mancha": (0.95, 0.92, 0.86)}


def atlas():
    A = C.Atlas(512, semilla=77)
    for n, c in COLORES.items():
        A.muestra(n, c, oscuro=0.78 if n not in ("ojo", "metal") else 0.6, grano=0.03 if n.startswith("pelaje") else 0.015)
    return A


def construir():
    esc = C.escena_vacia()
    os.makedirs(SALIDA, exist_ok=True)
    A = atlas()
    os.makedirs(LAMINAS, exist_ok=True)
    img = A.guardar(os.path.join(LAMINAS, "caballo_atlas.png"), "caballo_atlas")   # (va dentro del GLB)
    arm = C.crear_armadura("caballo", HUESOS, esc.collection)
    M = C.Malla(A)
    tronco = C.por_eje((0, 0.7, 1.05), (0, -0.62, 1.10), [(0.0, "cadera"), (0.35, "cadera"), (0.6, "columna"), (0.9, "pecho")])
    # cuerpo: barril, grupa y pecho
    M.pintar(M.esfera((0, 0.03, 1.02), (0.25, 0.62, 0.27), (18, 12)), "pelaje", pesos=tronco)
    M.pintar(M.esfera((0, 0.44, 1.05), (0.25, 0.30, 0.27), (14, 10)), "pelaje", pesos=tronco)
    M.pintar(M.esfera((0, -0.40, 1.02), (0.24, 0.26, 0.28), (14, 10)), "pelaje", pesos=tronco)
    M.pintar(M.esfera((0, 0.0, 0.86), (0.21, 0.5, 0.12), (14, 8)), "pelaje_claro", pesos=tronco)    # vientre más claro
    # cuello y cabeza
    cuello = C.por_eje((0, -0.50, 1.10), (0, -0.86, 1.70), [(0.0, "pecho"), (0.25, "cuello1"), (0.7, "cuello2"), (1.0, "cabeza")])
    M.pintar(M.tubo([Vector((0, -0.48, 1.08)), Vector((0, -0.62, 1.30)), Vector((0, -0.76, 1.52)), Vector((0, -0.86, 1.68))],
                    [(0.16, 0.20), (0.13, 0.16), (0.11, 0.13), (0.10, 0.11)], 12), "pelaje", pesos=cuello)
    M.pintar(M.tubo([Vector((0, -0.82, 1.70)), Vector((0, -1.00, 1.62)), Vector((0, -1.18, 1.50)), Vector((0, -1.26, 1.45))],
                    [(0.10, 0.12), (0.09, 0.10), (0.075, 0.08), (0.07, 0.07)], 12), "pelaje", pesos="cabeza")
    M.pintar(M.esfera((0, -1.25, 1.45), (0.075, 0.085, 0.075), (12, 8)), "hocico", pesos="cabeza")
    M.pintar(M.esfera((0, -1.06, 1.66), (0.03, 0.10, 0.02), (8, 6)), "mancha", pesos="cabeza")        # lucero en la frente
    for x in (0.07, -0.07):
        M.pintar(M.cono(Vector((x, -0.84, 1.76)), Vector((x * 1.2, -0.80, 1.92)), 0.035, 6), "pelaje", pesos="cabeza")
        M.pintar(M.esfera((x * 1.25, -1.0, 1.64), (0.018, 0.026, 0.024), (8, 6)), "ojo", pesos="cabeza")
    # cabezada (sin montura ni silla: solo la cabezada con su anilla, como el que está atado)
    M.pintar(M.tubo([Vector((0, -1.14, 1.47)), Vector((0, -1.16, 1.53))], [(0.085, 0.09), (0.085, 0.09)], 12), "cuero", pesos="cabeza")
    M.pintar(M.tubo([Vector((0, -0.90, 1.58)), Vector((0, -0.92, 1.66))], [(0.105, 0.11), (0.105, 0.11)], 12), "cuero", pesos="cabeza")
    M.pintar(M.esfera((0, -1.2, 1.42), (0.025, 0.025, 0.025), (8, 6)), "metal", pesos="cabeza")
    # crin y cola
    M.pintar(M.tubo([Vector((0, -0.46, 1.26)), Vector((0, -0.60, 1.46)), Vector((0, -0.74, 1.66)), Vector((0, -0.82, 1.80))],
                    [(0.035, 0.07), (0.04, 0.08), (0.035, 0.07), (0.02, 0.04)], 8), "crin", pesos=cuello)
    M.pintar(M.tubo([Vector((0, 0.66, 1.07)), Vector((0, 0.78, 0.90)), Vector((0, 0.84, 0.70)), Vector((0, 0.85, 0.48))],
                    [0.05, 0.075, 0.07, 0.035], 10), "crin",
             pesos=C.por_eje((0, 0.66, 1.07), (0, 0.85, 0.48), [(0.0, "cola1"), (0.45, "cola1"), (0.7, "cola2")]))
    # patas: muslo, caña y casco
    for lado, x in (("L", 0.15), ("R", -0.15)):
        for d, y0, y1 in (("del", -0.42, -0.45), ("tra", 0.44, 0.43)):
            a = Vector((x, y0, 0.95))
            b = Vector((x, (y0 + y1) / 2 + (0.03 if d == "tra" else 0), 0.50))
            c = Vector((x, y1, 0.10))
            M.pintar(M.tubo([a, (a + b) * 0.5, b], [0.10, 0.085, 0.06], 10), "pelaje",
                     pesos=C.por_eje(a, b, [(0.0, d + "1." + lado), (0.8, d + "1." + lado), (1.0, d + "2." + lado)]))
            M.pintar(M.tubo([b, c], [0.055, 0.045], 10), "pelaje", pesos=d + "2." + lado)
            M.pintar(M.tubo([c + Vector((0, 0, 0.02)), c + Vector((0, 0, -0.10))], [0.058, 0.064], 10), "casco",
                     pesos=d + "2." + lado)
    ob = M.objeto("caballo_malla", esc.collection)
    ob.data.materials.append(C.material_atlas("caballo", img, rugoso=0.8))
    C.enlazar(ob, arm)
    clips(arm)
    tris = C.triangulos(ob)
    datos = {"triangulos": tris, "vertices": len(ob.data.vertices), "huesos": len(arm.data.bones),
             "clips": ["reposo", "beber", "comer", "sacudir"], "prototipo": True}
    print("CABALLO", json.dumps(datos))
    if tris > PRESUPUESTO:
        print("FUERA DE PRESUPUESTO", tris)
    C.exportar_glb(os.path.join(SALIDA, "caballo.glb"))
    with open(os.path.join(SALIDA, "caballo.json"), "w", encoding="utf-8") as f:
        json.dump(datos, f, ensure_ascii=False, indent=1)
    return esc, ob, arm


def clips(arm):
    R = {}
    resp = {"columna": (1.5, 0, 0), "pecho": (-1.0, 0, 0), "cuello1": (-2, 0, 0)}
    cola_i = {"cola1": (0, 0, 12), "cola2": (0, 0, 10)}
    cola_d = {"cola1": (0, 0, -12), "cola2": (0, 0, -10)}
    C.crear_clip(arm, "reposo", [(1, R), (30, C.sumar(R, resp, cola_i)), (55, C.sumar(R, {"cabeza": (-6, 0, 8)})),
                                 (80, C.sumar(R, resp, cola_d)), (100, C.sumar(R, {"cuello1": (4, 0, -4)})), (121, R)])
    baja = {"cuello1": (72, 0, 0), "cuello2": (34, 0, 0), "cabeza": (26, 0, 0), "del1.L": (-4, 0, 0), "del1.R": (-4, 0, 0)}
    sorbo = C.sumar(baja, {"cabeza": (6, 0, 0)})
    C.crear_clip(arm, "beber", [(1, baja), (20, sorbo), (32, baja), (52, sorbo), (64, C.sumar(baja, cola_i)), (91, baja)])
    come = {"cuello1": (62, 0, 0), "cuello2": (28, 0, 6), "cabeza": (20, 0, 0)}
    masca = C.sumar(come, {"cabeza": (-5, 0, -4)})
    C.crear_clip(arm, "comer", [(1, come), (12, masca), (24, come), (36, masca), (48, C.sumar(come, cola_d)), (60, masca),
                                (91, come)])
    a = {"cuello2": (0, 0, 14), "cabeza": (0, 0, 22), "cola1": (0, 0, 16)}
    b = {"cuello2": (0, 0, -14), "cabeza": (0, 0, -22), "cola1": (0, 0, -16)}
    C.crear_clip(arm, "sacudir", [(1, R), (8, a), (16, b), (24, a), (32, b), (49, R)])


def lamina(esc, ob, arm):
    """Tres vistas en reposo y una por clip, para enseñarlo (prototipo)."""
    C.preparar_render(esc, 1600, 900, fondo=(0.90, 0.86, 0.78), muestras=24)
    C.luces_desierto(esc)
    C.suelo(esc, color=(0.70, 0.62, 0.48))
    cam = C.camara(esc, (0, 0, 0.95), 4.6, 35, 12, lente=50)
    os.makedirs(LAMINAS, exist_ok=True)
    salidas = []
    for nombre, az, clip, f in (("tres_cuartos", 35, "reposo", 1), ("perfil", 90, "reposo", 1), ("frente", 0, "reposo", 1),
                                ("beber", 70, "beber", 20), ("comer", 70, "comer", 12), ("sacudir", 20, "sacudir", 8)):
        for p in arm.animation_data.nla_tracks:
            p.mute = p.name != clip
        esc.frame_set(f)
        C.apuntar(cam, (0, -0.1, 0.95), 4.6, az, 12)
        ruta = os.path.join(LAMINAS, "caballo_%s.png" % nombre)
        esc.render.filepath = ruta
        bpy.ops.render.render(write_still=True)
        salidas.append(ruta)
    print("LAMINAS", json.dumps(salidas))


esc, ob, arm = construir()
lamina(esc, ob, arm)
print("HECHO")
