# Informe: la Garganta del Diablo en 3D

## 2026-11-09, 08:35 · Fases 0 y 1: diseño y maqueta jugable de la mazmorra

Especialista de gráficos, como diseñador de niveles 3D. Rama `area-garganta3d` desde `c74b872`, en
`D:\Aethelgard_garganta3d`. Diseño completo: `docs/diseno/garganta_3d.md`.

### 1. Qué se ha hecho

**El diseño en cinco líneas**
1. La mazmorra de la 2D, con las mismas piezas en el mismo orden, en una garganta que corre de sur a norte, por donde
   mira la cámara (que nunca gira). Los muros enmarcan la pantalla a los lados y nunca tapan a Kael.
2. Arriba (cornisa del oeste, y = 0): P1 entrada → P2 puentes colgantes → P3 puerta sellada → P4 arena de Gorthor.
   Abajo (cornisa del este, y = −8): P5 → P6 bajada al nido → P7 palanca → P8 grieta oculta.
3. Lo que cruza el abismo se ve de perfil: la escalera de la presa (P1 → P5), el ascensor (una cesta en un cable) y
   el levadizo que baja la palanca. El nido está en una repisa del abismo, bajo P6, y se ve brillar desde los puentes.
4. Paleta de mazmorra, distinta de Pastos Verdes: roca fría en capas, luz del cielo desde una rendija, rebote cálido,
   niebla azul que se vuelve ámbar al bajar, fuego en el camino y el anillo partido de bronce.
5. Cámara con zonas suaves: se asoma en los puentes, se acerca y mira más desde arriba en los pasos estrechos y se
   aleja en la arena.

**Qué se puede jugar ya** (con `-- 3d garganta3d`; sin el argumento, también en la APK experimental, sigue la 2D):
- todo el recorrido: del mapa a la entrada, encuentros con el ritmo de la 2D, los dos puentes colgantes, los pilares
  del anillo (detalle de lore), la escalera de la presa;
- el ascensor parado y la puerta sellada; la palanca, que baja el levadizo (la cámara lo mira caer), abre la puerta y
  enciende el ascensor (fundido a negro, como en la 2D);
- la bajada al nido con su combate fijo (el gólem de ámbar dormido) y el cofre raro;
- la arena con Gorthor esperando ante su trono y su combate de jefe; la grieta con el pilar del peregrino;
- dos altares de guardado, el guardado automático, la salida al mapa y el grupo (Lya y Garon) detrás de Kael.
- El progreso usa los identificadores de la 2D: una partida avanzada en la 2D vale en la 3D y al revés.

### 2. Archivos y commits

**Solo archivos nuevos y `modo3d.gd`:**
- `aethelgard/zonas3d/garganta_3d.gd` y `.tscn`: la región, que hereda de `prototipos/vista3d.gd`.
- `aethelgard/zonas3d/garganta/`:
  - `trazado.gd`: niveles, cornisas, piezas, zonas de cámara y equivalencias con la 2D;
  - `materiales.gd`: sombreados y texturas;
  - `roca.gd`: mallas de roca;
  - `escenario.gd`: roca, abismo y decorado;
  - `piezas.gd`: puentes, palanca, ascensor, levadizo, puerta, altares, cofre, nido, gólem y Gorthor.
- `aethelgard/modo3d.gd`: `REGIONES` con la Garganta, `EN_PRUEBAS`, `region_activa(_con)` y `escena_equivalente`.
- Pruebas nuevas: `pruebas/prueba_garganta3d.gd`, `pruebas/prueba_garganta3d_fotos.gd` y
  `pruebas/medir_garganta3d.gd`, más sus tres líneas al final de `pruebas/lista_pruebas.txt`.
- `docs/diseno/garganta_3d.md` y este informe.

**Commits:**
- `012bff7`: la escena;
- `27e3065`: `modo3d.gd`;
- `a2c8f37`: el pase visual y los lotes;
- `2ce1379`: las pruebas;
- y el de la documentación.

### 3. Pruebas

**`prueba_garganta3d`** (auto): SUPERADA en todas las pasadas desde el arreglo del levadizo (unos 16 s). Comprueba:
- 0: modo3d e identificadores;
- 1: entrada;
- 2: puentes y grupo;
- 3: pilares;
- 4: sin la palanca;
- 5: escalera;
- 6: palanca, levadizo en los dos sentidos, puerta y ascensor;
- 7: nido;
- 8: cofre;
- 9: Gorthor;
- 10: guardar y cargar;
- 11: salida y partida de la 2D;
- 12: la 2D terminada vista en la 3D.

El paso 11c avisa, sin fallar, de que `progreso.gd` aún no lleva a la 3D las partidas guardadas dentro de la 2D (§6).

**Dos errores que encontró la prueba y quedan arreglados:**
- El levadizo bajado no dejaba pasar a Kael en la bisagra: la cara del final de la caja inclinada quedaba a ras del
  suelo y el rayo la tomaba por una pendiente imposible. Ahora la cornisa sale un poco en la bisagra y hay dos umbrales
  planos.
- La puerta y la arena no se tocaban en el plano de por dónde se anda, y la escalera del nido acababa antes de su
  repisa. Se corrigió el trazado.

**`prueba_garganta3d_fotos`** (ventana): sin errores, 36 capturas (§4).

**`medir_garganta3d … conteo`**: SUPERADA en los tres perfiles (tabla en el diseño, §7).

**Batería completa** (09/11, 08:25, en `2ce1379`, aislada): SUPERADAS 40 · FALLIDAS 0 · MANUALES 25 · NO SEGURAS 0.
- Es la lista de `c74b872` más mis tres líneas; ningún fallo nuevo.
- `partida.save` real y carpeta real de datos: sin cambios.
- El aviso «proyecto: CAMBIADO» es este informe, que escribí mientras corría la batería.
- Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-09_082518\resumen.md`.

### 4. Evidencias

**Capturas con ventana a 1280 × 720,** en los perfiles bajo y alto (PC; no es el Redmi), 36 PNG en
`D:\REBELUM_diagnostico\garganta3d\2026-11-09\2026-11-09_083307\prueba_garganta3d_fotos\`:
- Sitios: entrada, puente colgante (con el nido brillando abajo), islote y pilares, levadizo y puerta, puerta sellada,
  escalera de la presa, cornisa baja y ascensor, bajada al nido, nido, palanca, levadizo cayendo (tres momentos),
  arena de Gorthor y grieta.
- Además: una vista de lejos, desde el puente hacia el nido, y el plano desde arriba.
- **Hoja de contactos** (columnas bajo y alto): `D:\REBELUM_diagnostico\garganta3d\2026-11-09\hoja_contactos.jpg`.
- La pasada anterior, `2026-11-09_082322`, se queda: es igual salvo la arena, que allí se tomó un poco antes y no se veía
  a Gorthor.

**Conteo por perfil** (PC, sin ventana, la escena entera):

| Perfil | Roca (triángulos) | Todas las mallas (triángulos) | Nodos de malla | Transparentes | Luces reales |
|---|---|---|---|---|---|
| bajo | 39 500 | 192 200 | 173 | 40 | 0 |
| medio | 62 800 | 216 000 | 181 | 43 | 0 |
| alto | 106 200 | 259 800 | 188 | 46 | 6 |

Los nodos de malla eran 243, 251 y 258 antes de juntar por material las piezas fijas, sin cambiar lo que se ve.

### 5. Límites

- **No he medido tiempos por fotograma** (lo pide el coordinador). Los FPS que salen en las capturas no valen como
  medida: había otros Godot abiertos y no hay tope fijo. El guion de medida está listo:
  `pruebas/medir_garganta3d.gd`, un proceso por perfil, con ventana.
- **No se ha probado en el Redmi.** El presupuesto del Mali es una estimación (diseño, §7).
- **El sonido no se ha oído.** Los efectos de la 2D están enganchados en los mismos sucesos. El sonido 3D (oyente,
  pasos, cascada, viento) queda indicado para el especialista de sonido, y el ambiente de `musica.gd` sale en
  silencio para esta escena hasta el cambio pedido.
- **Partidas guardadas dentro de la Garganta 2D:** hasta que `progreso.gd` use `modo3d.escena_equivalente`, cargarlas
  abre la 2D aunque la 3D esté activa. Entrar desde el mapa y volver de un combate ya llevan a la 3D.
- **El ascensor es un fundido,** como en la 2D. La cesta cruzando el abismo con Kael dentro queda para después.
- **Gorthor espera en reposo:** no hay animación de levantarse.
- **No hay `.uid` de los scripts nuevos:** los creará el editor al abrir el proyecto.
- **El aspecto lo he revisado yo en las capturas.** Falta el juicio del usuario sobre la orientación de la garganta y
  la paleta.

### 6. Cambios que pido en archivos de otros

**`progreso.gd`, en `restaurar()`:** después de `var escena: String = d.get("escena_guardada", MAPA)`, añadir:

```gdscript
	var en_3d: String = load("res://modo3d.gd").escena_equivalente(escena)   # mazmorra 2D con versión 3D en uso
	if en_3d != "":
		escena = en_3d
```

**`musica.gd`, en `contexto_de()`:** que `"res://zonas3d/garganta_3d.tscn"` vaya con `"res://garganta.tscn"`
(«mazmorra»); y en `pruebas/prueba_musica.gd`, la escena en su tabla de contextos.

**Sonido** (especialista de sonido), en `garganta_3d.gd`, `_sonido_3d`:
- `Sonido.oyente_3d(kael, cam)`;
- `Sonido.pasos_3d` con «madera» en los puentes colgantes, el levadizo y las estaciones, y «piedra» en lo demás;
- la cascada (`fuente_3d`);
- el viento del abismo.

**`docs/memory/agents/LEEME.md`:** una fila para este informe (`garganta3d.md`, rama `area-garganta3d`).

**`docs/recursos.md`:** no hace falta fila nueva: no hay recursos de fuera. Todo se genera por código o ya estaba en
el proyecto (guardián, goblin, personajes).

### 7. Siguiente paso

1. **Medir** en el hueco del coordinador con `medir_garganta3d` (PC y Redmi). Si el perfil bajo no llega a 30 FPS,
   ajustar con antes y después; lo preparado está en el diseño, §7.
2. **Que el usuario mire** la hoja de contactos y decida la orientación y la paleta.
3. **Activarla por defecto,** cuando supere las pruebas y la medida: quitar la línea de `EN_PRUEBAS` en `modo3d.gd`,
   con los cambios de `progreso.gd` y `musica.gd`.
4. **Pulido:** el viaje animado del ascensor, Gorthor levantándose y más vida (murciélagos en la grieta, polvo que cae
   de los puentes).
