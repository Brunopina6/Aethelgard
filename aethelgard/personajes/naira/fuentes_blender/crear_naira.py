# Naira, «la Astrónoma del Eclipse» (nombre provisional) — MODELO PROVISIONAL del concepto A («La Viajera del
# Eclipse»), con esqueleto y los clips mínimos de un mago. 12/11/2026, especialista de animaciones. Obra propia por
# guion (Blender 5.2.3), sin recursos externos. NO está enganchado al grupo ni al combate.
#
#   blender -b --factory-startup -P crear_naira.py -- <raíz aethelgard> <carpeta de láminas>
#
# Escribe:
#   personajes/naira/naira_provisional.glb        (malla, esqueleto de 23 huesos, 2 materiales y los 10 clips)
#   personajes/naira/naira_provisional_clips.json (duración, bucle e instante del impacto de cada clip)
#   <láminas>/naira_provisional.blend y una lámina con un fotograma clave de cada clip
#
# Clips (30 fps, «en el sitio»; en bucle: reposo, caminar, correr y concentracion; los demás acaban en el reposo,
# salvo victoria y derrota, que acaban en su pose):
#   reposo (4 s) · caminar (1 s) · correr (0,6 s) · ataque (1,2 s; impacto 0,40 s) · recibir_golpe (0,8 s) ·
#   victoria (2 s) · derrota (1,6 s) · lanzar_hechizo (1,5 s; impacto 0,87 s) · concentracion (2 s) ·
#   magia_poderosa (2,5 s; impacto 1,70 s)
# El astrolabio tiene hueso propio (hijo de la raíz): cuelga de la cadera y vuela delante de la mano al lanzar.
import bpy, sys, os, math, json
from mathutils import Vector

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
argv = sys.argv[sys.argv.index("--") + 1:]
RAIZ, LAMINAS = argv[0], argv[1]
sys.argv = [sys.argv[0], "--", RAIZ, LAMINAS, "-"]
import naira_conceptos as K   # noqa: E402
import naira_comun as N   # noqa: E402
from naira_comun import C   # noqa: E402

CARPETA = os.path.join(RAIZ, "personajes", "naira")
PI = math.pi
FPS = 30


def construir(esc):
    """El concepto A tal cual, con dos materiales (tela del atlas y brillo) en vez de cuatro: el latón queda pintado
    en el atlas (sin metal) y el disco del eclipse, en una muestra oscura del atlas. Menos llamadas de dibujo."""
    A = C.Atlas(1024, semilla=3)
    P = K.paleta(A, "A")
    A.muestra("eclipse_osc", (0.025, 0.025, 0.045), plano=True)
    N.dibujar_cara(A, P)
    img = A.guardar(os.path.join(LAMINAS, "naira_provisional_atlas.png"), "naira_atlas")
    M = C.Malla(A)
    K.concepto_A(M, P)
    uv_osc = A.uv_muestra("eclipse_osc", 0.5)
    # vértices sin peso (4 en el borde del abrigo): el exportador glTF les crearía un «neutral_bone»
    sueltos = [v for v in M.bm.verts if len(v[M.dv]) == 0]
    M.pesar(sueltos, N.pesos_tronco)
    print("NAIRA vertices sin peso corregidos:", len(sueltos))
    for f in M.bm.faces:
        if f.material_index == 3:
            for lp in f.loops:
                lp[M.uv].uv = uv_osc
        if f.material_index in (2, 3):
            f.material_index = 0
    ob = M.objeto("naira", esc.collection)
    m0 = C.material_atlas("naira_tela", img, rugoso=0.8)
    m1 = N.objeto_brillo("naira_brillo", K.BRILLO["A"], 2.5)
    for m in (m0, m1):
        m.use_backface_culling = True
        ob.data.materials.append(m)
    arm = C.crear_armadura("naira_esqueleto", N.huesos(K.HUESOS_EXTRA["A"]), esc.collection)
    C.enlazar(ob, arm)
    return ob, arm


# ------------------------------------------------------------------ poses

R = K.reposo("A")            # mano derecha en el cinturón (buscada: a 1,7 cm del objetivo)
RB = dict(R)                 # la base de los gestos que mueven el brazo derecho (afinados desde la mano suelta)
RB.update({"brazo.R": (-8, -5, -4), "antebrazo.R": (-50, 0, 26), "mano.R": (0, 0, -14)})
S = C.sumar


def B(d):
    return S(RB if "brazo.R" in d else R, d)


def ojos(p, cerrados):
    q = dict(p)
    q.update(N.CERRADOS if cerrados else N.ABIERTOS)
    return q


def mezcla(a, b, t):
    return C.mezclar_poses(a, b, t)


def flotar(desp=(0.0, -0.06, 0.20), giro=0.0, esc=1.7):
    """El astrolabio delante de la mano derecha, de cara (gira sobre su eje: «giro» en grados)."""
    return {"astrolabio@sobre_mano.R": desp, "astrolabio": (giro, 0, -90), "astrolabio@esc": (esc, esc, esc)}


def crear_clip(arm, nombre, claves):
    """Como desierto_comun.crear_clip, pero con naira_comun.poner (el astrolabio «sobre la mano»)."""
    if arm.animation_data is None:
        arm.animation_data_create()
    act = bpy.data.actions.new(nombre)
    act.use_fake_user = True
    arm.animation_data.action = act
    previo = {}
    for f, pose in claves:
        N.poner(arm, pose)
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
            k.interpolation = 'BEZIER'
            k.handle_left_type = k.handle_right_type = 'AUTO_CLAMPED'
        fc.update()
    arm.animation_data.action = None
    pista = arm.animation_data.nla_tracks.new()
    pista.name = nombre
    pista.strips.new(nombre, int(claves[0][0]), act)
    pista.mute = True
    return act


def paso(fase, amp_m=22, amp_b=14, rod=28, bote=0.014, incl=4, antebrazo=-12, giro=5):
    s, c = math.sin(fase), math.cos(fase)
    p = {"muslo.L": (-amp_m * s, -2, 0), "muslo.R": (amp_m * s, 2, 0),
         "pierna.L": (5 + rod * max(0.0, c) ** 1.3, 0, 0), "pierna.R": (5 + rod * max(0.0, -c) ** 1.3, 0, 0),
         "pie.L": (-6 * s, 0, 0), "pie.R": (6 * s, 0, 0),
         "brazo.L": (amp_b * s, 5, 0), "brazo.R": (-amp_b * s, -5, 0),
         "antebrazo.L": (antebrazo, 0, -4), "antebrazo.R": (antebrazo, 0, 4),
         "cadera": (0, 0, giro * s), "columna": (incl, 0, 0), "pecho": (0, 0, -giro * 0.8 * s),
         "cabeza": (-incl * 0.6, 0, giro * 0.2 * s),
         "raiz@loc": (0, 0, -bote * s * s), "astrolabio": (8 * math.sin(2 * fase), 0, 0)}
    return N.con_ojos(p)


def clips(arm):
    info = {}
    # reposo: respira, cambia el peso, parpadea y el astrolabio se mece
    inhala = B({"pecho": (-1.5, 0, 0), "cuello": (1.0, 0, 0), "hombro.L": (0, 0, 2), "hombro.R": (0, 0, -2),
                   "astrolabio": (2, 0, 0)})
    peso = B({"cadera": (0, 1, 2), "columna": (0, -1, -1.5), "cabeza": (2, 2, -3), "raiz@loc": (-0.004, 0, 0),
                 "astrolabio": (-3, 0, 0)})
    inhala2 = S(peso, {"pecho": (-1.5, 0, 0), "cuello": (1.0, 0, 0)})
    claves = [(1, R), (30, inhala), (52, mezcla(inhala, peso, 0.73)),
              (54, ojos(mezcla(inhala, peso, 0.8), True)), (57, ojos(mezcla(inhala, peso, 0.9), False)),
              (60, peso), (90, inhala2), (121, R)]
    crear_clip(arm, "reposo", claves)
    info["reposo"] = {"duracion": 4.0, "bucle": True}
    # caminar y correr: un ciclo en el sitio
    crear_clip(arm, "caminar", [(1 + i * 30 / 8, paso(2 * PI * i / 8)) for i in range(9)])
    info["caminar"] = {"duracion": 1.0, "bucle": True}
    crear_clip(arm, "correr", [(1 + i * 18 / 8, paso(2 * PI * i / 8, 40, 28, 58, 0.03, 12, -70, 8))
                               for i in range(9)])
    info["correr"] = {"duracion": 0.6, "bucle": True}
    # ataque: el astrolabio sube a la mano, ella gira y lo empuja de un golpe de palma (impacto f13 = 0,40 s)
    atras = B({"pecho": (0, 0, 18), "columna": (0, 0, 6), "cabeza": (0, 0, -10),
                  "brazo.R": (24, -6, 0), "antebrazo.R": (-75, 0, 25), "mano.R": (0, 0, 0),
                  "muslo.R": (6, 0, 0), "raiz@loc": (0, 0.01, -0.01)})
    atras.update(flotar((0.04, -0.02, 0.06), 0, 1.2))
    golpe = B({"pecho": (-4, 0, -20), "columna": (-2, 0, -8), "cabeza": (-4, 0, 12),
                  "brazo.R": (-92, 8, 0), "antebrazo.R": (8, 0, 0), "mano.R": (45, 0, 0),
                  "brazo.L": (14, -14, 0), "muslo.R": (-16, 2, 0), "pierna.R": (14, 0, 0), "muslo.L": (10, 0, 0),
                  "raiz@loc": (0, -0.03, -0.02)})
    golpe.update({"pecho": (-4, 0, -11), "brazo.R": (-90, 40, 0), "antebrazo.R": (-20, 0, 80), "mano.R": (0, 0, 0)})
    golpe.update(flotar((0.0, -0.16, 0.0), 40, 1.6))
    sigue = dict(golpe)
    sigue.update(flotar((0.0, -0.20, 0.01), 70, 1.6))
    crear_clip(arm, "ataque", [(1, R), (9, atras), (13, golpe), (20, sigue), (28, mezcla(sigue, R, 0.6)), (37, R)])
    info["ataque"] = {"duracion": 1.2, "bucle": False, "impacto": 0.40}
    # recibir_golpe
    golpeada = B({"columna": (-12, 0, 5), "pecho": (-9, 0, 0), "cabeza": (-14, 0, -8),
                     "brazo.L": (-12, -14, 0), "brazo.R": (-12, 14, 0), "antebrazo.L": (-25, 0, 0),
                     "antebrazo.R": (-25, 0, 0), "raiz@loc": (0, 0.045, -0.012), "astrolabio": (-25, 0, 0)})
    crear_clip(arm, "recibir_golpe", [(1, R), (4, ojos(golpeada, True)), (8, ojos(golpeada, True)),
                                      (14, mezcla(golpeada, R, 0.55)), (25, R)])
    info["recibir_golpe"] = {"duracion": 0.8, "bucle": False, "impacto": 0.10}
    # victoria: hace girar el astrolabio sobre la palma y se queda mirándolo con media sonrisa (acaba en la pose)
    agacha = B({"columna": (6, 0, 0), "raiz@loc": (0, 0, -0.02), "pierna.L": (10, 0, 0), "pierna.R": (8, 0, 0),
                   "muslo.L": (-6, 0, 0), "muslo.R": (-5, 0, 0)})
    arriba = B({"columna": (-4, 0, -4), "pecho": (-4, 0, -6), "cabeza": (-12, 0, 10),
                   "brazo.R": (-125, 12, 0), "antebrazo.R": (-20, 0, 0), "mano.R": (-35, 0, 0),
                   "brazo.L": (6, -24, 0), "antebrazo.L": (-20, 0, 0)})
    a1, a2, a3 = dict(arriba), dict(arriba), dict(arriba)
    a1.update(flotar((0, -0.05, 0.16), 0, 1.5))
    a2.update(flotar((0, -0.05, 0.22), 120, 1.6))
    a3.update(flotar((0, -0.05, 0.22), 240, 1.6))
    fin = B({"columna": (0, 0, -6), "pecho": (-2, 0, -4), "cabeza": (2, -8, 14),
                "brazo.R": (-70, 6, 0), "antebrazo.R": (-55, 0, 25), "mano.R": (-40, 0, 0)})
    fin.update({"brazo.R": (-10, 0, 0), "antebrazo.R": (-110, 0, 0), "mano.R": (-30, 0, 0)})
    fin.update(flotar((-0.06, -0.04, 0.12), 360, 1.3))
    crear_clip(arm, "victoria", [(1, R), (10, agacha), (22, a1), (34, a2), (46, a3), (61, fin)])
    info["victoria"] = {"duracion": 2.0, "bucle": False}
    # derrota: se tambalea, cae de rodillas y se encorva (acaba en la pose; ojos cerrados)
    tambalea = S(golpeada, {"raiz@loc": (0, 0.02, -0.02)})
    dobla = B({"raiz@loc": (0, 0.02, -0.20), "muslo.L": (-45, 0, 0), "muslo.R": (-38, 0, 0),
                  "pierna.L": (85, 0, 0), "pierna.R": (78, 0, 0), "pie.L": (-30, 0, 0), "pie.R": (-30, 0, 0),
                  "columna": (14, 0, 0), "pecho": (8, 0, 0), "cabeza": (16, 0, 0),
                  "brazo.L": (-20, 8, 0), "brazo.R": (-20, -8, 0), "astrolabio": (30, 0, 0)})
    rodillas = {"raiz@loc": (0, 0.06, -0.375), "muslo.L": (-6, -4, 0), "muslo.R": (-4, 4, 0),
                "pierna.L": (92, 0, 0), "pierna.R": (92, 0, 0), "pie.L": (40, 0, 0), "pie.R": (40, 0, 0),
                "cadera": (6, 0, 0), "columna": (14, 0, 4), "pecho": (9, 0, 0), "cuello": (5, 0, 0),
                "cabeza": (14, 0, -6), "brazo.L": (-28, 12, 0), "antebrazo.L": (-10, 0, 0),
                "brazo.R": (-34, -10, 0), "antebrazo.R": (-14, 0, 0), "mano.L": (10, 0, 0), "mano.R": (10, 0, 0),
                "astrolabio": (80, 0, 0), "astrolabio@loc": (0.0, 0.04, -0.33)}
    crear_clip(arm, "derrota", [(1, R), (6, ojos(tambalea, True)), (20, ojos(dobla, True)),
                                (34, ojos(S(rodillas, {"columna": (-6, 0, 0)}), True)), (49, ojos(rodillas, True))])
    info["derrota"] = {"duracion": 1.6, "bucle": False}
    # lanzar_hechizo: lo alza sobre la mano y lo empuja hacia el enemigo (impacto f27 = 0,87 s)
    prepara = B({"columna": (4, 0, 6), "pecho": (2, 0, 8), "cabeza": (6, 0, -4), "raiz@loc": (0, 0, -0.015),
                    "brazo.R": (-30, -6, 0), "antebrazo.R": (-85, 0, 30), "mano.R": (0, 0, 0),
                    "pierna.L": (8, 0, 0), "pierna.R": (8, 0, 0)})
    prepara.update(flotar((0.05, -0.06, 0.06), 0, 1.2))
    alza = dict(K.hechizo("A"))
    alza.update(flotar((0.0, -0.06, 0.20), 90, 1.8))
    suelta = B({"cadera": (0, 0, -10), "columna": (-3, 0, -8), "pecho": (-4, 0, -10), "cabeza": (-4, 0, 10),
                   "brazo.R": (-88, 6, 0), "antebrazo.R": (2, 0, 0), "mano.R": (55, 0, 0),
                   "brazo.L": (16, -40, 0), "antebrazo.L": (-25, 0, 0),
                   "muslo.R": (-14, 4, -4), "pierna.R": (12, 0, 0), "muslo.L": (14, -6, 4), "pierna.L": (14, 0, 0),
                   "raiz@loc": (0, -0.02, -0.02)})
    suelta.update(flotar((0.0, -0.26, 0.02), 200, 2.0))
    sostiene = dict(suelta)
    sostiene.update(flotar((0.0, -0.24, 0.02), 260, 1.9))
    crear_clip(arm, "lanzar_hechizo", [(1, R), (10, prepara), (20, alza), (24, S(alza, {"cabeza": (-3, 0, 0)})),
                                       (27, suelta), (33, sostiene), (40, mezcla(sostiene, R, 0.6)), (46, R)])
    info["lanzar_hechizo"] = {"duracion": 1.5, "bucle": False, "impacto": 0.867}
    # concentracion: manos juntas delante del pecho, ojos cerrados y el astrolabio girando entre ellas (bucle)
    junta = B({"cabeza": (10, 0, 0), "columna": (2, 0, 0),
                  "brazo.L": (-40, 14, 0), "antebrazo.L": (-62, 0, -48), "mano.L": (0, 0, 0),
                  "brazo.R": (-40, -14, 0), "antebrazo.R": (-62, 0, 48), "mano.R": (0, 0, 0)})
    junta.update({"brazo.L": (20, 0, 0), "antebrazo.L": (-120, 0, -40), "brazo.R": (20, 0, 0),
                  "antebrazo.R": (-120, 0, 40), "mano.L": (0, 0, 0), "mano.R": (0, 0, 0)})   # manos a 1,5 cm del objetivo
    cl = []
    for i, g in enumerate((0, 120, 240, 360)):
        p = ojos(S(junta, {"pecho": (-1.2 * (i % 2), 0, 0)}), True)
        p.update(flotar((0.035, -0.11, 0.08), g, 1.5))
        cl.append((1 + i * 20, p))
    crear_clip(arm, "concentracion", cl)
    info["concentracion"] = {"duracion": 2.0, "bucle": True}
    # magia_poderosa: se recoge, sube los brazos con el astrolabio enorme sobre la cabeza y lo descarga
    # (impacto f52 = 1,70 s)
    recoge = B({"raiz@loc": (0, 0, -0.04), "columna": (10, 0, 0), "pecho": (6, 0, 0), "cabeza": (10, 0, 0),
                   "muslo.L": (-14, 0, 0), "muslo.R": (-14, 0, 0), "pierna.L": (24, 0, 0), "pierna.R": (24, 0, 0),
                   "pie.L": (-10, 0, 0), "pie.R": (-10, 0, 0),
                   "brazo.L": (22, -18, 0), "brazo.R": (22, 18, 0), "antebrazo.L": (-30, 0, 0),
                   "antebrazo.R": (-30, 0, 0)})
    recoge.update(flotar((0.12, -0.1, 0.0), 0, 1.4))
    alto = B({"raiz@loc": (0, 0, 0.025), "columna": (-6, 0, 0), "pecho": (-8, 0, 0), "cabeza": (-22, 0, 0),
                 "brazo.L": (-158, 18, 0), "brazo.R": (-158, -18, 0), "antebrazo.L": (0, 0, 0),   # en alto, +ay abre la izquierda
                 "antebrazo.R": (0, 0, 0), "mano.L": (0, 0, 0), "mano.R": (0, 0, 0),
                 "pie.L": (-14, 0, 0), "pie.R": (-14, 0, 0)})
    alto1, alto2 = dict(alto), dict(alto)
    alto1.update(flotar((0.24, 0.0, 0.22), 120, 2.4))
    alto2.update(flotar((0.24, 0.0, 0.26), 240, 2.6))
    descarga = B({"raiz@loc": (0, -0.03, -0.035), "columna": (8, 0, 0), "pecho": (6, 0, 0), "cabeza": (-6, 0, 0),
                     "brazo.L": (-78, -22, 0), "brazo.R": (-78, 22, 0), "antebrazo.L": (0, 0, 0),
                     "antebrazo.R": (0, 0, 0), "mano.L": (50, 0, 0), "mano.R": (50, 0, 0),
                     "muslo.R": (-18, 4, 0), "pierna.R": (16, 0, 0), "muslo.L": (14, -4, 0), "pierna.L": (16, 0, 0)})
    descarga.update(flotar((0.10, -0.38, 0.0), 360, 2.8))
    queda = dict(descarga)
    queda.update(flotar((0.10, -0.36, 0.0), 400, 2.5))
    crear_clip(arm, "magia_poderosa", [(1, R), (15, recoge), (32, alto1), (45, alto2), (52, descarga),
                                       (60, queda), (68, mezcla(queda, R, 0.6)), (76, R)])
    info["magia_poderosa"] = {"duracion": 2.5, "bucle": False, "impacto": 1.70}
    return info


def lamina(esc, ob, arm, tris, info):
    N.preparar(esc, 2600, 1150)
    N.luces_estudio(esc)
    C.suelo(esc, color=(0.86, 0.84, 0.80))
    elegidos = [("reposo", 1), ("caminar", 8), ("correr", 6), ("ataque", 13), ("recibir_golpe", 6),
                ("victoria", 61), ("derrota", 49), ("lanzar_hechizo", 27), ("concentracion", 11),
                ("magia_poderosa", 40)]
    xs = [(i - 4.5) * 0.78 for i in range(10)]
    ob.hide_render = True
    for x, (clip, f) in zip(xs, elegidos):
        a2 = arm.copy()
        esc.collection.objects.link(a2)
        a2.animation_data_clear()
        m2 = ob.copy()
        esc.collection.objects.link(m2)
        m2.hide_render = False
        m2.parent = a2
        m2.modifiers["esqueleto"].object = a2
        C.accion(a2, clip)
        a2.location = (x, 0, 0)
        a2.rotation_euler = (0, 0, math.radians(-25))
        C.texto(esc, "%s · f%d" % (clip, f), (x, 0.0, 1.95), 0.062)
        a2["fotograma"] = f
    C.texto(esc, "Naira (concepto A) · MODELO PROVISIONAL · %d triángulos, %d huesos, 2 materiales, atlas 1024 · "
            "un fotograma clave por clip" % (tris, len(arm.data.bones)), (0, 0.4, 2.25), 0.09)
    C.camara(esc, (0, 0, 1.0), 16, 0, 5, orto=8.2)
    # cada copia en su fotograma: se hornea con la acción y un desfase de la tira NLA no hace falta; se ajusta el
    # fotograma de la escena por copia renderizando a la vez (todas comparten fotograma), así que se usan acciones
    # con el fotograma deseado copiado al 1
    for o in [o for o in esc.objects if o.type == 'ARMATURE' and "fotograma" in o.keys()]:
        act = o.animation_data.action
        esc.frame_set(int(o["fotograma"]))
        poses = {pb.name: (pb.location.copy(), pb.rotation_quaternion.copy(), pb.scale.copy()) for pb in o.pose.bones}
        o.animation_data.action = None
        for pb in o.pose.bones:
            pb.location, pb.rotation_quaternion, pb.scale = poses[pb.name]
    esc.render.filepath = os.path.join(LAMINAS, "naira_provisional_clips.png")
    bpy.ops.render.render(write_still=True)


def main():
    esc = C.escena_vacia()
    esc.render.fps = FPS
    ob, arm = construir(esc)
    info = clips(arm)
    tris = C.triangulos(ob)
    for o in esc.objects:
        o.select_set(False)
    arm.animation_data.action = None
    for pb in arm.pose.bones:
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.location = (0, 0, 0)
        pb.scale = (1, 1, 1)
    os.makedirs(CARPETA, exist_ok=True)
    C.exportar_glb(os.path.join(CARPETA, "naira_provisional.glb"))
    datos = {"PROVISIONAL": True, "nombre": "Naira (provisional), concepto A «La Viajera del Eclipse»",
             "altura_m": N.ALTO, "triangulos": tris, "huesos": len(arm.data.bones), "fps": FPS, "clips": info}
    with open(os.path.join(CARPETA, "naira_provisional_clips.json"), "w", encoding="utf-8") as f:
        json.dump(datos, f, ensure_ascii=False, indent=1)
    print("NAIRA triangulos", tris, "huesos", len(arm.data.bones), "clips", list(info))
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(LAMINAS, "naira_provisional.blend"))
    lamina(esc, ob, arm, tris, info)


main()
