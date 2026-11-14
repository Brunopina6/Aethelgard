# Refinado adaptativo de la cara y el cuello (Nix, 14/11): parte las aristas cuya mitad queda más lejos de la superficie
# de la ALTA y lleva el vértice nuevo al punto más cercano de la alta. Solo aristas con los dos triángulos dentro de la
# región (piel y cuello alto, sin pelo). Los pesos y las UV se interpolan (bmesh); después: máx. 4 huesos, normalizados.
import bmesh
import numpy as np
from mathutils import Vector


def refinar(me, arbol, region_v, presupuesto_tri, umbral=0.0012, largo_min=0.004, por_ronda=40, mover_max=0.006):
    """region_v: array bool por vértice (piel/cuello). Devuelve (nº de triángulos añadidos, array bool de la región
    ampliado a los vértices nuevos, desviación máxima antes y después)."""
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.verts.ensure_lookup_table()
    dl = bm.verts.layers.deform.active
    reg = set(i for i in np.nonzero(region_v)[0])
    añadidos = 0
    dev_ini = None
    rondas = 0
    while añadidos + 2 <= presupuesto_tri and rondas < 40:
        rondas += 1
        cand = []
        for e in bm.edges:
            v0, v1 = e.verts
            if v0.index not in reg or v1.index not in reg or len(e.link_faces) != 2:
                continue
            if any(len(f.verts) != 3 for f in e.link_faces):
                continue
            if not all(all(v.index in reg for v in f.verts) for f in e.link_faces):
                continue
            L = (v0.co - v1.co).length
            if L < largo_min:
                continue
            m = (v0.co + v1.co) * 0.5
            loc, nor, fi, d = arbol.find_nearest(m)
            if loc is None:
                continue
            cand.append((d, e, loc))
        if not cand:
            break
        cand.sort(key=lambda x: -x[0])
        if dev_ini is None:
            dev_ini = cand[0][0]
        if cand[0][0] < umbral:
            break
        hechas = 0
        tocadas = set()
        for d, e, loc in cand:
            if d < umbral or añadidos + 2 > presupuesto_tri or hechas >= por_ronda:
                break
            if not e.is_valid:
                continue
            caras = list(e.link_faces)
            if any(f in tocadas for f in caras):
                continue
            opuestos = [[v for v in f.verts if v not in e.verts][0] for f in caras]
            ne, nv = bmesh.utils.edge_split(e, e.verts[0], 0.5)
            mov = Vector(loc) - nv.co
            if mov.length > mover_max:
                mov = mov.normalized() * mover_max
            nv.co = nv.co + mov
            for f in list(nv.link_faces):
                op = [v for v in opuestos if v in f.verts]
                if len(f.verts) == 4 and op:
                    r = bmesh.utils.face_split(f, nv, op[0])
            # pesos: máx. 4 huesos, normalizados
            dv = nv[dl]
            items = sorted(dv.items(), key=lambda kv: -kv[1])[:4]
            s = sum(w for _, w in items) or 1.0
            dv.clear()
            for g, w in items:
                dv[g] = w / s
            bm.verts.index_update()
            reg.add(nv.index)
            añadidos += 2
            hechas += 1
            for f in nv.link_faces:
                tocadas.add(f)
        bm.faces.index_update()
        bm.edges.index_update()
        if hechas == 0:
            break
    # desviación final
    dev_fin = 0.0
    for e in bm.edges:
        v0, v1 = e.verts
        if v0.index in reg and v1.index in reg:
            loc, nor, fi, d = arbol.find_nearest((v0.co + v1.co) * 0.5)
            if loc is not None:
                dev_fin = max(dev_fin, d)
    nreg = np.zeros(len(bm.verts), bool)
    nreg[list(reg)] = True
    bm.to_mesh(me)
    bm.free()
    me.update()
    return añadidos, nreg, dev_ini or 0.0, dev_fin, rondas
