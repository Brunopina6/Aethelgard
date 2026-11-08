# Informe del especialista de combate

Rama `area-combate`, copia `D:\Aethelgard_combate`. Cada entrega añade una sección; no se borran las anteriores.

## 2026-11-09, 00:25 · Fase 0 de T-091, T-092 y T-093 (solo diseño)

**Encargo:** diseñar, sin tocar código ni ejecutar Godot, las magias nuevas (T-091), los accesorios y las armas
especiales (T-092) y los enemigos nuevos (T-093), según D-071 y D-072.

**1. Archivos y commits** (base `dddbddb`):
- `docs/diseno/combate_ampliaciones.md` (nuevo): el diseño completo. Commit `4911e50`.
- `docs/memory/agents/combate.md` (este informe, nuevo): commit siguiente.
- Ningún archivo de código tocado.

**2. Pruebas:** ninguna. Es una fase de diseño y el encargo pedía no ejecutar Godot.

**3. Evidencias:**
- **Observado en el código** de `dddbddb`: las líneas se citan en el documento.
- **Ganchos de sonido** mirados en `area-sonido` @ `1359386` (`Sonido.efecto`, `Sonido.golpe`), sin integrar todavía.
- **Memoria contrastada** el 09/11 a las 00:05: la rama remota `memoria-desarrollo` (`19982f0`) es igual que la copia
  local.

**4. Hallazgos que condicionan el diseño** (observado en el código):
- **El sistema de equipo ya existe:** 7 ranuras, 6 armas y 16 protecciones. Frostfang ya es un arma especial
  (congela). Por eso se añade una ranura y no un sistema nuevo.
- **El menú de magia no admite una quinta familia:** Lya ya llena las 4 filas que caben sobre el bloque del grupo
  (y = 562 con tres héroes). Por eso, una pestaña con icono por familia nueva.
- **Nadie revive en combate,** pero los tres modelos 3D tienen `revivir()` sin usar.
- **La personalidad «apoyo»** (chamán) existe y no la usa ningún enemigo.
- **Encuentros:** los mismos 5 grupos en todo el mundo. Los enemigos no tienen debilidades ni botín.
- **El Templo Sumergido** usa el estilo «llanura» (nivel 2): sus enemigos huirían casi siempre por «zona limpia».
- **Riesgos de código:**
  - poner el ATB a 100 a mano deja a un héroe sin turno (no vuelve a la cola);
  - un héroe que muere con la barra llena se queda sin turno al revivir si no se le vacía;
  - `_golpe_visual` con «Fuego» encendería una quemadura en un héroe que nadie apagaría;
  - un id de equipo desconocido rompe los menús (`menus.gd:283`, `inventario.gd:162`).

**5. Límites:**
- Nada comprobado ejecutando: las cifras son de partida y la geometría del menú sale de las constantes.
- El determinismo de la prueba de huella (C0) está pendiente de comprobar.
- Las licencias del limo y de las tiras del Hollín están sin registrar.
- Algunos lugares de los secretos dependen de T-089 y T-090.

**6. Siguiente paso propuesto:**
- **C0** (semilla y huella del combate) y después **M1** (familias y Compás del Alba). Orden completo en el documento,
  §6.
- **Decisiones para el usuario,** en §7: el menú por pestañas, las debilidades contra los enemigos nuevos, el
  aprendizaje por nivel o por tomos, P1 «Guardia a tiempo»…

**7. Cambios que necesito en archivos de otros** (§8 del documento):
- **`sonido.gd`:** el catálogo de efectos nuevos; sin usar el generador aleatorio global durante el combate.
- **`material_arma.gd`:** `tinte` y `color_brillo` opcionales.
- **`goblin_3d.gd`:** la variante con bastón y la señal «antes del golpe».
- **Mundo** (`zona.gd`, `garganta.gd`, `isla.gd`, `zonas3d/`): cofres que llamen a `Recompensas.dar(id)`.
- **`fondo_combate.gd`:** fondo «templo».
- **`diario.gd`:** fichas nuevas.
- **`carga.gd`:** precargar las tres escenas nuevas de `vfx/`.
- **`docs/recursos.md`:** la procedencia del limo y del Hollín.
