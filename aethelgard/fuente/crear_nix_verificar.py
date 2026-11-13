# Nix (V12): crea sus acciones (clips) en una armadura y comprueba que el BASTÓN no atraviesa el SOMBRERO en ningún
# clip (la especificación pide verificar sombrero contra bastón en victoria, derrota y ritual). Lo usa
# crear_nix_final.py; también se puede lanzar suelto sobre un .blend del modelo para iterar las poses:
#
#   blender -b <nix_modelo.blend o nix.blend> -P fuente/crear_nix_verificar.py -- <raíz aethelgard>
#
# Cómo se mide: en 16 instantes de cada clip se evalúan las mallas con la armadura; cada arista del bastón se lanza
# como rayo contra los triángulos del sombrero (BVH): un choque = el bastón lo atraviesa. Se informa también la
# distancia mínima de los vértices del bastón al sombrero.
import sys, os
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree


def crear_acciones(arm, clips, RC, BC):
    """Una acción por clip (claves por IK con rig_comun.Rig). Devuelve info {nombre: duracion, bucle, eventos}."""
    rig = RC.Rig(arm)
    info = {}
    if arm.animation_data is None:
        arm.animation_data_create()
    for c in clips:
        viejo = bpy.data.actions.get(c["nombre"])
        if viejo is not None:
            bpy.data.actions.remove(viejo)
        act = bpy.data.actions.new(c["nombre"])
        act.use_fake_user = True
        arm.animation_data.action = act
        previo = {}
        for t, d in c["claves"]:
            rig.aplicar(d)
            for pb in rig.pb:
                q = pb.rotation_quaternion.copy()
                if pb.name in previo and q.dot(previo[pb.name]) < 0:
                    pb.rotation_quaternion = -q
                previo[pb.name] = pb.rotation_quaternion.copy()
            rig.clave(t * BC.FPS)
        info[c["nombre"]] = {"duracion": round(c["dur"], 4), "bucle": c["bucle"],
                             "eventos": {k: round(v, 4) for k, v in c["eventos"].items()}}
    arm.animation_data.action = None
    rig.reset()
    return info, rig


def _vertices_de(ob, deps, piezas):
    """Coordenadas evaluadas (mundo) e índices de vértice por pieza («pieza» del atributo, o el objeto suelto)."""
    oe = ob.evaluated_get(deps)
    me = oe.to_mesh()
    mw = oe.matrix_world
    co = [mw @ v.co for v in me.vertices]
    tris = [tuple(t.vertices) for t in me.loop_triangles] if me.loop_triangles else None
    if tris is None:
        me.calc_loop_triangles()
        tris = [tuple(t.vertices) for t in me.loop_triangles]
    aristas = [tuple(e.vertices) for e in me.edges]
    pieza = None
    if "pieza" in me.attributes:
        pieza = [d.value for d in me.attributes["pieza"].data]
    oe.to_mesh_clear()
    return co, tris, aristas, pieza


def comprobar(arm, objetos, clips, fps=30, muestras=16, nombres_pieza=None):
    """objetos: o bien {"sombrero": ob, "baston": ob} (piezas sueltas) o bien {"cuerpo": ob} con el atributo «pieza»
    y nombres_pieza (lista de nombres por índice). Devuelve {clip: {"choques": n, "minima": m, "peor_t": t}}."""
    sc = bpy.context.scene
    res = {}
    for c in clips:
        act = bpy.data.actions[c["nombre"]]
        arm.animation_data.action = act
        try:
            arm.animation_data.action_slot = act.slots[0]
        except Exception:
            pass
        choques, minima, peor = 0, 9.0, 0.0
        for i in range(muestras):
            t = c["dur"] * i / (muestras - 1)
            sc.frame_set(int(round(t * fps)))
            deps = bpy.context.evaluated_depsgraph_get()
            if "cuerpo" in objetos:
                co, tris, aristas, pieza = _vertices_de(objetos["cuerpo"], deps, None)
                i_s = nombres_pieza.index("nix_sombrero")
                i_b = nombres_pieza.index("nix_baston")
                tri_s = [t for t in tris if pieza[t[0]] == i_s]
                ar_b = [e for e in aristas if pieza[e[0]] == i_b]
                pts_s = co
                pts_b = co
            else:
                pts_s, tri_s, _, _ = _vertices_de(objetos["sombrero"], deps, None)
                pts_b, _, ar_b, _ = _vertices_de(objetos["baston"], deps, None)
            bvh = BVHTree.FromPolygons(pts_s, tri_s)
            n = 0
            for a, b in ar_b:
                p, q = pts_b[a], pts_b[b]
                d = q - p
                L = d.length
                if L < 1e-6:
                    continue
                hit = bvh.ray_cast(p, d / L, L)
                if hit[0] is not None:
                    n += 1
            vb = set(v for e in ar_b for v in e)
            for v in vb:
                r = bvh.find_nearest(pts_b[v])
                if r[0] is not None and r[3] < minima:
                    minima = r[3]
            if n > choques:
                choques, peor = n, t
        res[c["nombre"]] = {"choques": choques, "minima": round(minima, 4), "peor_t": round(peor, 2)}
    arm.animation_data.action = None
    return res


if __name__ == "__main__" and "--" in sys.argv:
    argv = sys.argv[sys.argv.index("--") + 1:]
    RAIZ = argv[0]
    sys.dont_write_bytecode = True
    sys.path.insert(0, os.path.join(RAIZ, "fuente"))
    sys.path.insert(1, os.path.join(RAIZ, "personajes", "heroes_v3", "fuentes_blender"))
    sys.path.insert(2, os.path.join(RAIZ, "personajes", "heroes_v2", "fuentes_blender"))
    import rig_comun as RC
    import biblioteca_clips as BC
    import crear_nix_clips as NC
    arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
    clips = NC.clips_de()
    crear_acciones(arm, clips, RC, BC)
    if "nix_sombrero" in bpy.data.objects:
        obj = {"sombrero": bpy.data.objects["nix_sombrero"], "baston": bpy.data.objects["nix_baston"]}
        nombres = None
    else:
        cu = bpy.data.objects["cuerpo_nix"]
        obj = {"cuerpo": cu}
        nombres = list(cu["piezas"])
    r = comprobar(arm, obj, clips, nombres_pieza=nombres)
    for k, v in r.items():
        print("CHOQUE %-18s choques %3d  mínima %.3f m  peor en %.2f s" % (k, v["choques"], v["minima"], v["peor_t"]))
