# Tolvanera, el espíritu de polvo que llega con la tormenta — PROTOTIPO V12 (12/11/2026, especialista de animaciones).
# Nombre y papel: docs/v12/NARRATIVA_DESIERTO.md §4 (propuesta, sin aprobar). Un remolino con dos brasas por ojos: nace
# con la tormenta, busca a quien no se ha puesto a cubierto y se deshace cuando amaina. Solo sale con tormenta; el Agua
# lo asienta (más daño) y el viento le cura. Geometría, esqueleto y clips hechos desde cero con este guion.
#
#   blender -b --factory-startup -P crear_tolvanera.py -- <raíz aethelgard> <carpeta de láminas>
#
# Escribe enemigos/tolvanera/tolvanera.glb y tolvanera_clips.json, y en la carpeta de láminas la lámina y las poses.
#
# Silueta (distinta de todo lo que hay): un embudo que se ensancha hacia arriba (1,95 m, más alto que los héroes),
# con una falda de arena a ras de suelo, un núcleo denso y una capa exterior de polvo; dos brasas rasgadas por ojos
# arriba, y piedrecitas, esquirlas de vidrio y un jirón de tela que giran a su alrededor. El giro del polvo lo hace el
# sombreado de Godot (UV cilíndricas: u alrededor, v de abajo arriba) y el de los escombros, el script: los clips solo
# doblan, estiran y encogen el embudo.
# Ejes (Blender): mira a -Y, Z arriba. En Godot mira a +Z.
#
# Esqueleto (11 huesos): raiz; base, medio, alto, cima (la columna del embudo; la escala de «base» lo encoge todo);
# ojos y brasa.L / brasa.R (hijos de «alto»; la escala de cada brasa es su brillo); escombros (hijo de «medio»: el anillo
# que el script hace girar); falda (hijo de raiz: la arena a ras de suelo).
# Superficies (las pone Godot por nombre, enemigos/tolvanera/tolvanera_3d.gd): «nucleo» y «polvo» (sombreado de polvo
# que gira, transparente), «falda» (lo mismo, a ras de suelo), «brasas» (emisivo) y «escombros» (atlas opaco).
#
# Clips (30 fps; en bucle: reposo y correr):
#   reposo (2 s)          gira sobre sí con un balanceo de peonza; las brasas parpadean
#   aviso_rafaga (0,8 s)  se encoge, se echa atrás y las brasas se avivan (y se queda así si no ataca enseguida)
#   rafaga (1,2 s)        se lanza 0,4 m hacia el objetivo abriendo la boca del embudo: IMPACTO 0,433 s (f14)
#   torbellino (1,6 s)    se estira alto y fino y se desploma en una ola de arena a su alrededor: IMPACTO 0,867 s (f27)
#   curarse_viento (1,33 s) absorbe el viento: crece y se aviva (el viento le cura)
#   agua_asienta (1,33 s) el Agua lo asienta: se aplasta, se hunde y se tambalea (el script lo oscurece como barro)
#   recibir_golpe (0,5 s), derrota (1,67 s: se deshilacha, las brasas suben y se apagan), entrada (1,2 s: nace de
#   un remolino pequeño), correr (0,67 s: avanza inclinado)
import bpy, sys, os, math, json
from mathutils import Vector, Euler

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(AQUI, "..", "..", "..", "personajes", "desierto", "fuentes_blender"))
import desierto_comun as C

argv = sys.argv[sys.argv.index("--") + 1:]
RAIZ, LAMINAS = argv[0], argv[1]
SALIDA = os.path.join(RAIZ, "enemigos", "tolvanera")

# perfil del embudo: (z, radio del núcleo)
PERFIL = [(0.0, 0.05), (0.18, 0.08), (0.45, 0.13), (0.75, 0.19), (1.05, 0.26), (1.35, 0.34), (1.60, 0.41),
          (1.80, 0.46), (1.95, 0.44)]
CADENA = [(0.0, "base"), (0.4, "base"), (0.55, "medio"), (0.95, "medio"), (1.1, "alto"), (1.45, "alto"),
          (1.6, "cima"), (2.0, "cima")]


def huesos():
    return [("raiz", (0, 0, 0), (0, 0, 0.1), None),
            ("falda", (0, 0, 0), (0, 0, 0.08), "raiz"),
            ("base", (0, 0, 0), (0, 0, 0.45), "raiz"),
            ("medio", (0, 0, 0.45), (0, 0, 1.0), "base"),
            ("alto", (0, 0, 1.0), (0, 0, 1.5), "medio"),
            ("cima", (0, 0, 1.5), (0, 0, 1.98), "alto"),
            ("escombros", (0, 0, 0.95), (0, 0, 1.05), "medio"),
            ("ojos", (0, -0.30, 1.42), (0, -0.36, 1.42), "alto"),
            ("brasa.L", (0.085, -0.33, 1.44), (0.085, -0.38, 1.44), "ojos"),
            ("brasa.R", (-0.085, -0.33, 1.44), (-0.085, -0.38, 1.44), "ojos")]


def paleta(A):
    A.muestra("arena", (0.80, 0.66, 0.44))
    A.muestra("piedra", (0.52, 0.44, 0.36), oscuro=0.7, claro=1.2)
    A.muestra("vidrio", (0.75, 0.88, 0.80), oscuro=0.8, claro=1.15)
    A.muestra("tela", (0.62, 0.28, 0.22))
    A.muestra("brasa", (1.0, 0.55, 0.18), plano=True)


def construir(M):
    pts = [Vector((0, 0, z)) for z, r in PERFIL]
    # núcleo (denso) y polvo (exterior, más ancho y con la boca abierta hacia fuera)
    M.pintar(M.tubo(pts, [r for z, r in PERFIL], 18, costura=True), uvf="tubo", pesos=CADENA, mat=0)
    ext = [Vector((0, 0, z)) for z, r in PERFIL] + [Vector((0, 0, 2.02))]
    rext = [r * 1.45 + 0.04 for z, r in PERFIL] + [0.72]
    M.pintar(M.tubo(ext, rext, 20, costura=True), uvf="tubo", pesos=CADENA, mat=1,
             deform=lambda co: co + Vector((0.04 * math.sin(co.z * 5.0), 0.04 * math.cos(co.z * 4.0), 0)))
    # falda de arena a ras de suelo
    M.pintar(M.tubo([Vector((0, 0, 0.30)), Vector((0, 0, 0.10)), Vector((0, 0, 0.02))], [0.16, 0.42, 0.78], 20,
                    costura=True), uvf="tubo", pesos="falda", mat=2)
    # brasas: dos rasgaduras de fuego inclinadas (enfadadas hacia dentro)
    for s, l in (("L", 1), ("R", -1)):
        M.pintar(M.esfera((0.09 * l, -0.34, 1.44), (0.075, 0.03, 0.038), (10, 6), giro=Euler((0, 0.38 * l, 0))),
                 "brasa", pesos="brasa." + s, mat=3)
    # escombros que giran: piedras, esquirlas de vidrio y un jirón de tela
    import random
    rnd = random.Random(4)
    for k in range(9):
        a = 2 * math.pi * k / 9 + rnd.uniform(-0.2, 0.2)
        r = rnd.uniform(0.55, 0.75)
        z = rnd.uniform(0.55, 1.55)
        p = Vector((r * math.cos(a), r * math.sin(a), z))
        tipo = k % 3
        if tipo == 0:
            vs = M.esfera(p, (0.045, 0.035, 0.03), (6, 4), giro=Euler((rnd.random(), rnd.random(), rnd.random())))
            M.pintar(vs, "piedra", pesos="escombros", mat=4, liso=False)
        elif tipo == 1:
            vs = M.cono(p, p + Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(0.5, 1))).normalized() * 0.11,
                        0.025, 4)
            M.pintar(vs, "vidrio", pesos="escombros", mat=4, liso=False)
        else:
            t = Vector((-math.sin(a), math.cos(a), 0)) * 0.14
            vs = M.tubo([p, p + t * 0.5 + Vector((0, 0, 0.03)), p + t], [(0.035, 0.004), (0.03, 0.004), (0.02, 0.004)],
                        4, ref=Vector((0, 0, 1)))
            M.pintar(vs, "tela", pesos="escombros", mat=4, liso=False)


# ------------------------------------------------------------------ poses

def B(t=0.0, a=4.0):
    """El reposo en la fase t (radianes): balanceo de peonza que recorre la columna."""
    return {"base": (a * 0.4 * math.sin(t), a * 0.4 * math.cos(t), 0),
            "medio": (a * math.sin(t + 0.6), a * math.cos(t + 0.6), 0),
            "alto": (a * math.sin(t + 1.2), a * math.cos(t + 1.2), 0),
            "cima": (a * 0.6 * math.sin(t + 1.8), a * 0.6 * math.cos(t + 1.8), 0),
            "cima@esc": (1 + 0.04 * math.sin(2 * t), 1 + 0.04 * math.sin(2 * t), 1),
            "brasa.L@esc": (1, 1, 1 + 0.15 * math.sin(3 * t)), "brasa.R@esc": (1, 1, 1 + 0.15 * math.sin(3 * t + 1))}


def esc(k):
    return (k, k, k)


def clips(arm):
    info = {}
    R0 = B(0)
    C.crear_clip(arm, "reposo", [(f, B(2 * math.pi * (f - 1) / 60)) for f in range(1, 62, 5)])
    info["reposo"] = {"duracion": 2.0, "bucle": True}
    # aviso de ráfaga: se encoge, se echa atrás, las brasas se avivan
    enc = C.sumar(R0, {"medio": (-10, 0, 0), "alto": (-12, 0, 0), "cima": (-8, 0, 0), "cima@esc": (0.8, 0.8, 1.0),
                       "base@esc": (0.95, 0.95, 0.92), "brasa.L@esc": esc(1.5), "brasa.R@esc": esc(1.5)})
    C.crear_clip(arm, "aviso_rafaga", [(1, R0), (10, enc), (16, C.sumar(enc, {"medio": (-2, 0, 0)})), (25, enc)])
    info["aviso_rafaga"] = {"duracion": 24 / 30, "aviso": 9 / 30}
    # ráfaga: se lanza hacia el objetivo abriendo la boca (impacto f14)
    lanza = C.sumar(R0, {"raiz@loc": (0, -0.40, 0), "base": (10, 0, 0), "medio": (16, 0, 0), "alto": (22, 0, 0),
                         "cima": (18, 0, 0), "cima@esc": (1.35, 1.35, 1.1), "brasa.L@esc": esc(1.4),
                         "brasa.R@esc": esc(1.4)})
    C.crear_clip(arm, "rafaga", [(1, enc), (8, C.sumar(enc, {"medio": (-6, 0, 0)})), (14, lanza),
                                 (20, C.sumar(lanza, {"alto": (-6, 0, 0)})), (30, C.sumar(R0, {"raiz@loc": (0, -0.1, 0)})),
                                 (37, R0)])
    info["rafaga"] = {"duracion": 36 / 30, "impacto": 13 / 30, "alcance_m": 0.40, "desde_aviso": True}
    # torbellino: alto y fino, y se desploma en una ola de arena (impacto f27)
    alto = C.sumar(R0, {"base@esc": (0.7, 0.7, 1.22), "cima@esc": (0.8, 0.8, 1.1), "brasa.L@esc": esc(1.3),
                        "brasa.R@esc": esc(1.3), "falda@esc": (0.6, 0.6, 1.0)})
    ola = C.sumar(R0, {"base@esc": (1.5, 1.5, 0.62), "falda@esc": (2.6, 2.6, 1.6), "cima@esc": (1.3, 1.3, 1.0),
                       "medio": (6, 0, 0)})
    claves = [(1, R0)]
    for i, f in enumerate(range(6, 22, 3)):
        claves.append((f, C.sumar(alto, B(i * 1.5, 7))))
    claves += [(27, ola), (34, C.sumar(ola, {"base@esc": (0.85, 0.85, 1.3)})), (49, R0)]
    C.crear_clip(arm, "torbellino", claves)
    info["torbellino"] = {"duracion": 48 / 30, "impacto": 26 / 30, "area": "todos"}
    # curarse con el viento: crece y se aviva
    crece = C.sumar(R0, {"base@esc": esc(1.15), "brasa.L@esc": esc(1.5), "brasa.R@esc": esc(1.5),
                         "cima@esc": (1.2, 1.2, 1.0), "falda@esc": esc(1.3)})
    C.crear_clip(arm, "curarse_viento", [(1, R0), (12, C.sumar(R0, {"base@esc": (0.9, 0.9, 0.95)})), (24, crece),
                                         (32, C.sumar(crece, {"medio": (3, 3, 0)})), (41, R0)])
    info["curarse_viento"] = {"duracion": 40 / 30, "curacion": 22 / 30}
    # agua: se asienta (aplastado, hundido, tambaleante) y se recompone a medias
    plano = C.sumar(R0, {"base@esc": (1.25, 1.25, 0.55), "cima@esc": (0.85, 0.85, 1), "medio": (8, -6, 0),
                         "alto": (10, 8, 0), "brasa.L@esc": (0.8, 0.8, 0.5), "brasa.R@esc": (0.8, 0.8, 0.5),
                         "falda@esc": (1.3, 1.3, 0.6)})
    C.crear_clip(arm, "agua_asienta", [(1, R0), (5, plano), (14, C.sumar(plano, {"medio": (-12, 10, 0)})),
                                       (24, C.sumar(plano, {"medio": (6, -8, 0)})), (41, R0)])
    info["agua_asienta"] = {"duracion": 40 / 30, "barro": [4 / 30, 30 / 30]}
    golpe = C.sumar(R0, {"medio": (-10, 6, 0), "alto": (-14, 8, 0), "raiz@loc": (0, 0.06, 0), "cima@esc": (0.9, 0.9, 1)})
    C.crear_clip(arm, "recibir_golpe", [(1, R0), (4, golpe), (9, C.sumar(golpe, {"medio": (14, -10, 0)})), (16, R0)])
    info["recibir_golpe"] = {"duracion": 15 / 30}
    # derrota: se deshilacha y se tumba; las brasas suben y se apagan
    abre = C.sumar(R0, {"base@esc": (1.6, 1.6, 0.7), "cima@esc": (1.4, 1.4, 1), "brasa.L@esc": esc(1.3),
                        "brasa.R@esc": esc(1.3), "ojos@loc": (0, 0, 0.15)})
    fin = {"base@esc": (2.2, 2.2, 0.04), "falda@esc": (2.0, 2.0, 0.2), "ojos@loc": (0, 0, 0.9),
           "brasa.L@esc": esc(0.01), "brasa.R@esc": esc(0.01)}
    C.crear_clip(arm, "derrota", [(1, R0), (12, abre), (30, C.mezclar_poses(abre, fin, 0.6)), (50, fin)])
    info["derrota"] = {"duracion": 49 / 30}
    # entrada: nace de un remolino pequeño
    nace = {"base@esc": (0.15, 0.15, 0.08), "falda@esc": (0.3, 0.3, 0.3), "brasa.L@esc": esc(0.01),
            "brasa.R@esc": esc(0.01)}
    C.crear_clip(arm, "entrada", [(1, nace), (12, C.sumar(B(1.0, 8), {"base@esc": (0.5, 0.5, 0.7)})),
                                  (24, C.sumar(B(2.0, 6), {"base@esc": (1.05, 1.05, 1.05), "brasa.L@esc": esc(1.4),
                                                           "brasa.R@esc": esc(1.4)})), (37, R0)])
    info["entrada"] = {"duracion": 36 / 30}
    C.crear_clip(arm, "correr", [(f, C.sumar(B(2 * math.pi * (f - 1) / 20, 3), {"base": (8, 0, 0), "medio": (6, 0, 0),
                                                                                "alto": (4, 0, 0)}))
                                 for f in range(1, 22, 5)])
    info["correr"] = {"duracion": 20 / 30, "bucle": True}
    return info


POSES_LAMINA = [("aviso_rafaga", 12, ""), ("rafaga", 14, ""), ("torbellino", 18, ""), ("torbellino", 27, ""),
                ("agua_asienta", 6, ""), ("curarse_viento", 24, ""), ("derrota", 30, "")]


def material_polvo(nombre, color, alfa, escala_v=2.0):
    """Solo para las láminas de Blender (en el juego lo pinta el sombreado de Godot): vetas de ruido en las UV."""
    m = C.material_color(nombre, color, rugoso=1.0)
    m.surface_render_method = 'BLENDED'
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    uv = nt.nodes.new("ShaderNodeTexCoord")
    mp = nt.nodes.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (6.0, escala_v, 1.0)
    ruido = nt.nodes.new("ShaderNodeTexNoise")
    ruido.inputs["Scale"].default_value = 3.0
    ruido.inputs["Detail"].default_value = 4.0
    rampa = nt.nodes.new("ShaderNodeValToRGB")
    rampa.color_ramp.elements[0].position = 0.35
    rampa.color_ramp.elements[1].position = 0.75
    mul = nt.nodes.new("ShaderNodeMath")
    mul.operation = 'MULTIPLY'
    mul.inputs[1].default_value = alfa
    nt.links.new(uv.outputs["UV"], mp.inputs["Vector"])
    nt.links.new(mp.outputs["Vector"], ruido.inputs["Vector"])
    nt.links.new(ruido.outputs["Fac"], rampa.inputs["Fac"])
    nt.links.new(rampa.outputs["Color"], mul.inputs[0])
    nt.links.new(mul.outputs["Value"], bsdf.inputs["Alpha"])
    return m


def main():
    esc_ = C.escena_vacia()
    A = C.Atlas(256, semilla=9)
    A.celda = 32
    paleta(A)
    os.makedirs(SALIDA, exist_ok=True)
    img = A.guardar(os.path.join(SALIDA, "tolvanera_atlas.png"), "tolvanera_atlas")
    M = C.Malla(A, ("nucleo", "polvo", "falda", "brasas", "escombros"))
    construir(M)
    ob = M.objeto("tolvanera_malla", esc_.collection)
    for m in (material_polvo("nucleo", (0.78, 0.62, 0.42), 1.0, 2.5), material_polvo("polvo", (0.86, 0.74, 0.55), 0.55),
              material_polvo("falda", (0.84, 0.72, 0.52), 0.7, 1.0),
              C.material_atlas("brasas", img, emision=(1.0, 0.45, 0.12, 6.0)),
              C.material_atlas("escombros", img, rugoso=0.6)):
        ob.data.materials.append(m)
    arm = C.crear_armadura("tolvanera", huesos(), esc_.collection)
    C.enlazar(ob, arm)
    info = clips(arm)
    tris = C.triangulos(ob)
    info["_modelo"] = {"triangulos": tris, "huesos": len(arm.data.bones), "atlas": 256,
                       "superficies": ["nucleo", "polvo", "falda", "brasas", "escombros"]}
    print("CRIATURA tolvanera triangulos", tris, "huesos", len(arm.data.bones))
    C.exportar_glb(os.path.join(SALIDA, "tolvanera.glb"))
    with open(os.path.join(SALIDA, "tolvanera_clips.json"), "w", encoding="utf-8") as f:
        json.dump(info, f, indent=1, ensure_ascii=False)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(LAMINAS, "tolvanera.blend"))
    cam, xs = C.lamina_criatura(esc_, arm, ob, RAIZ, os.path.join(LAMINAS, "tolvanera_lamina.png"),
                                "Tolvanera  ·  PROTOTIPO V12  ·  %d triángulos, 5 superficies (polvo en Godot)" % tris,
                                sep=1.9, giros=(0, -35), alto_cam=1.0, orto=9.0)
    cam.data.ortho_scale = 3.0
    esc_.render.resolution_x, esc_.render.resolution_y = 700, 800
    for i, (clip, f, _t) in enumerate(POSES_LAMINA):
        C.accion(arm, clip)
        esc_.frame_set(f)
        C.apuntar(cam, (xs[1], 0, 1.0), 12, -30, 10)
        esc_.render.filepath = os.path.join(LAMINAS, "tolvanera_pose%d_%s_f%d.png" % (i, clip, f))
        bpy.ops.render.render(write_still=True)


main()
