# Informe del especialista de narrativa

Cada entrega añade una sección con fecha y hora; las anteriores no se borran (ver `LEEME.md`).

## 2026-11-09, 00:25 — Fase 0 de T-089, T-090 y T-094, y preparación de T-086 (solo diseño)

**Encargo:** diseñar, sin tocar el juego, las ciudades (T-089), los sitios nuevos que explorar (T-090), los compañeros de
viaje (T-094) y la tabla de texto del prólogo y de Pastos Verdes para T-086. Decisiones vigentes: D-071, D-072, D-033.
Copia `D:\Aethelgard_narrativa`, rama `area-narrativa`, partiendo de `dddbddb`.

### 1. Archivos y commits
- Nuevo: `docs/diseno/ciudades_y_lugares.md` (el diseño completo).
- Nuevo: este informe, `docs/memory/agents/narrativa.md`.
- No se ha tocado ningún `.dtl`, `.dch`, script ni escena. Los commits se indican en la respuesta al coordinador.

### 2. Pruebas
- No se ha ejecutado Godot: en esta fase no tocaba.
- **Medido con scripts** (PowerShell, 2026-11-09, sobre `dddbddb`):
  - la longitud visible de las 44 frases del prólogo y de la misión de Pastos Verdes, y la de las frases propuestas;
  - el color de los píxeles de la captura del mapamundi del 08/11
    (`D:\REBELUM_diagnostico\mapamundi\2026-11-08\antes\2_mapa_entero_1a1.png`) en cada marcador nuevo: los cuatro caen en
    tierra y a 140 px o más de cualquier otro lugar. **Pendiente de comprobar en el juego.**

### 3. Evidencias
- Tabla de antes y después de las 44 frases, con la intención de cada una para animaciones:
  `docs/diseno/ciudades_y_lugares.md` §5.2. Cambian 6.
- Ciudades (Oakhaven, Sunken City y Arboleda Mítica), con trazado, posada, NPC, misiones, secretos, notas y dirección
  visual: §2.
- Ocho sitios nuevos, primero los de canon, con nivel, conexión en el mapa y restricciones de D-033: §3.
- Compañeros (Nyx, Brea y Nerea) y acompañantes ligeros (Pip y Lucero): §4.

### 4. Límites y propuestas pendientes de decisión
- Todo es propuesta [P] salvo lo marcado [C]. Las decisiones para el usuario están en §7 del documento (10, con
  recomendación; ninguna bloquea los pasos 1 a 4 del orden).
- **Riesgos técnicos encontrados en el código** (§1.3 del documento):
  - añadir lugares a `LUGARES` desplazaría el índice 10 de Pastos Verdes en el modo 3D (`mapa.gd:110`);
  - el generador del mapa colorea los biomas con todos los lugares (`mapa.gd:173-178`): crecer `LUGARES` sin crecer
    `ZONA_LUGAR` se sale del arreglo, y con él cambia el mapa;
  - un detalle de lore nuevo en un lugar de un acto vuelve a ocultar la página ya ganada (`progreso.gd:178-187`): se
    propone una lista `NOTAS` aparte, guardada en `lore_visto`;
  - el id de los cofres depende de la posición (`zona.gd:1761`): ids escritos en los sitios hechos a mano.
- Las posiciones de los marcadores se midieron en una captura, no en el juego.

### 5. Siguiente paso y cambios en archivos de otros
- **Siguiente paso:** cuando animaciones termine con los `.dtl`, aplicar la tabla de §5.2 (6 frases) y pasar
  `prueba_prologo`, `prueba_dialogo`, `prueba_dialogo_interfaz` y `prueba_ruta_alpha`.
- **Cambios que hacen falta en archivos de otros** (al aplicar la tabla):
  - `aethelgard/pruebas/prueba_prologo.gd:130`: de 9 a 11 frases (10 si solo se parte el primer globo);
  - opcional, `aethelgard/progreso.gd:45`: el texto del detalle `pastos_estela` (§5.3).
- **Para implementar las ciudades y los sitios:** el orden y los responsables están en §6 del documento.
