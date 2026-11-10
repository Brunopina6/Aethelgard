# RENDIMIENTO — medidas y propuesta (fase 5)

## Medidas reales en el Redmi (09/11, por ADB, con SurfaceFlinger; APK v336 y v365)

| Dónde | FPS | p95 del fotograma | Nota |
|---|---|---|---|
| Pastos Verdes 3D, perfil bajo | 30,0-30,1 (tope 30) | 33,7-34,0 ms | estable |
| Pastos Verdes 3D, perfil medio | 27,1 | 42,2 ms | no estable; con escala 0,8 + una sombra: 30,3 y 34,1 ms |
| Pastos Verdes 3D, perfil alto | 10,2 (tope 60) | 118 ms | no viable en este móvil |
| Combate | 59,9 (tope 60) | 17,0 ms | un fotograma de 50 ms al primer golpe |
| Mapamundi y Oakhaven 2D | 30,0 (tope 30) | 33,7 ms | estables |
| Garganta 3D, perfil bajo | 59,9 | 17,0 ms | va a 60: no aplica el tope de 30 del perfil bajo (incoherencia, ver abajo) |
| Arranque hasta el menú | — | — | 58 s la primera vez (compila sombreadores), 25-26 s después |
| Memoria de la app (Garganta 3D) | — | — | 881 MB PSS, de ellos 460 MB de GL |

## Medidas en el PC (10/11, `pruebas/medir_precarga.gd`, sin ventana)

La pantalla de carga precarga con `Recursos.listar()` todo `res://` salvo `addons`, `para_meshy`, `.godot`, `decorado`,
`texturas`, `isla` y `carga.tscn`, y lo **retiene en memoria toda la partida** (grupo «comun»).

| Carpeta | Archivos | MB importados | s cargándolos (PC) |
|---|---|---|---|
| (raíz: modelos y texturas de los personajes, Érebo, música de combate) | 164 | 172,1 | 1,75 |
| vegetacion_prueba (no va en la APK) | 42 | 30,2 | 0,09 |
| enemigos (Zarzalín, Cencerrante) | 16 | 24,1 | 0,07 |
| audio | 268 | 15,4 | 0,31 |
| personajes | 80 | 9,0 | 0,08 |
| zonas3d | 23 | 6,3 | 0,71 |
| ciudades | 79 | 4,0 | 0,30 |
| resto | 88 | 15,9 | 0,48 |
| **Total** | **760** | **277,1** | **3,8** |

En el Redmi la misma lista (679 archivos en la APK) tardó 12,7 s según el propio juego.

## Lo ya optimizado (09/11, en `integracion-experimental`, medido)

- Érebo: sin las seis copias de su textura: crear a Érebo, de 0,81-1,06 s a 0,23-0,31 s (PC); −16 MB de vídeo.
- Garon y goblin: normales, rugosidad y metal comprimidos para la GPU: carga de 0,26 a 0,13 s; −11 MB de vídeo cada uno;
  imagen idéntica al píxel.
- APK: de 279,6 a 262 MB. Memoria en Pastos Verdes (Redmi): de 512 a 365 MB.

## Propuesta (no aplicada en esta sesión: no se puede demostrar segura sin el Redmi)

1. **Precarga por zonas:** sacar de la precarga del arranque lo que solo usa una región (`zonas3d/`, `ciudades/`, los
   bucles de `audio/` de cada sitio) y cargarlo detrás del fundido a negro al entrar (`Recursos.cambiar_escena` ya carga
   en segundo plano). Beneficio esperado: arranque más corto y menos memoria fuera de esas regiones. Riesgo: tirones la
   primera vez que se entra (la precarga se hizo para evitarlos, T-023). **Hay que medirlo en el Redmi antes y después.**
2. **Tope de FPS coherente:** la Garganta 3D no aplica el tope de 30 del perfil bajo (va a 60: más batería y calor).
   Lo lleva el especialista de rendimiento (rama `area-rendimiento`); no se toca aquí para no pisarlo.
3. **Música de combate:** no cargarla al arrancar sino al empezar el combate (6,6 MB; propuesta de sonido, aprobada el
   09/11, en la rama `area-sonido`).
