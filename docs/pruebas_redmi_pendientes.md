# Pruebas pendientes en el Redmi

Registro de lo que **solo se puede comprobar en el teléfono** (REDMI A7 Pro, Mali-G57). Desde el 09/11 el usuario está
fuera de casa: no se usa el Redmi (ni ADB ni copias) hasta que vuelva. Todo lo de esta lista está **pendiente de
verificar**; nada está medido en el móvil. Cuando se pruebe, se anota la fecha, la APK (versionCode) y el resultado.

Cómo usarla: instalar la última APK de prueba (`com.aethelgard.experimental`, no toca la app estable), seguir la ruta de
sus notas y marcar cada fila.

## Rendimiento (medir, nunca suponer)

| Id | Qué medir | Dónde | Cómo | Origen |
|---|---|---|---|---|
| R-01 | FPS y tirones de Pastos Verdes 3D, perfil bajo y alto, con grupo | Pastos Verdes 3D | banco GRUPO (botón), 60 s | T-021, T-022, T-023 |
| R-02 | Tirones de la primera vez y caché de sombreados; tiempos de carga | Pastos Verdes 3D, diálogos | entrar dos veces y comparar | T-023 |
| R-03 | Mapamundi pintado: FPS al desplazar y memoria | mapa | `pruebas/medir_mapamundi.ps1` en PC; en el Redmi, a ojo y con el contador | T-085 |
| R-04 | Garganta del Diablo 3D: FPS en la entrada, la cornisa y el puente | Ajustes → Garganta 3D | contador de FPS, perfil bajo y alto | T-095, T-102 |
| R-05 | Oakhaven hecha a mano con su arte: FPS y memoria | Oakhaven | contador de FPS | T-089, T-103 |
| R-06 | Combate con HUD nuevo (barras de PM, señas de las artes) y Zarzalín 3D | combate en Pastos Verdes | contador de FPS durante un arte | T-099, T-097 |
| R-07 | Esperas con personalidad de los héroes (coste de las animaciones) | Pastos Verdes 3D, quieto 10 s | contador de FPS | animaciones, 09/11 |

## Sonido (una prueba muda no demuestra cómo se oye)

| Id | Qué escuchar | Origen |
|---|---|---|
| S-01 | Ambientes: cortes del bucle y volumen frente a la música | sonido t1–t3 |
| S-02 | Que cada nivel de volumen de Ajustes se note y al 100 % suene como antes | sonido t2 |
| S-03 | Río 2D, voces de enemigos y eco de la Garganta | sonido t2–t3 |
| S-04 | Efectos de las seis bestias y de las artes nuevas | sonido t3–t4 |

## Lectura, controles y presentación

| Id | Qué mirar | Origen |
|---|---|---|
| L-01 | Prólogo y primer diálogo: cámara, texto legible, gestos y la mano de Kael | T-081 |
| L-02 | Cajas de texto nuevas (Oakhaven, comentarios de los héroes) sin cortes | narrativa |
| L-03 | HUD de combate: barras de PM y motivos legibles en pantalla pequeña | T-099 |
| L-04 | Controles táctiles en exploración 3D, Garganta y Oakhaven; teclado y mando reales | T-025 |
| L-05 | Icono y pantalla de carga REBELUM | T-098 |

## Partidas

| Id | Qué comprobar | Origen |
|---|---|---|
| P-01 | Una partida antigua del móvil abre bien (Oakhaven nueva, Garganta 2D/3D) | `progreso.restaurar()` |
| P-02 | Guardar y volver tras cerrar la app a la fuerza | T-076 |
