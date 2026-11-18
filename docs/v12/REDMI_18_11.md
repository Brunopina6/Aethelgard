# Redmi, 18/11 (19:19-20:02): APK de Auditoría del validado `3ff3c7b`

Todo lo de este documento está **medido en el Redmi**. Si algo viene del PC, se dice expresamente.

## Teléfono, APK y datos

- **Teléfono:** Redmi 25128RN17Y (REDMI A7 Pro), Mali-G57 (driver r54p1), MIUI OS3.0.9.0. Pantalla 1600×720; el juego
  dibuja 1280×720 con bandas laterales. Enchufado; batería 21 → 28 %, 31,1 → 31,7 °C.
- **APK:** `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261118-1271dd6-local.apk`.
  - 478,3 MB. SHA-256 `be31d5a16bc6f26132ee6033de9ae63c993cd2e36a7a49c1eb8edc16a44664e9`.
  - Paquete `com.aethelgard.auditoria`, versionCode 1022. Certificado de siempre (`3413edcd…7785f3`).
  - Compilación «TODO CORRECTO»: la partida del PC, `main` y `desarollo` quedaron sin cambios.
  - **Su juego es el del validado `3ff3c7b`:** `1271dd6` solo añade 16 líneas a `docs/v12/RETOMAR.md`, fuera del
    proyecto de Godot. El sufijo «-local» viene de una carpeta sin seguimiento del usuario
    (`personajes/nix/fbx/anterior_14_11/`).
- **Instalación:**
  - `adb install -r` lo bloqueó el control de seguridad de la sesión.
  - La APK se copió por USB a Descargas, con el SHA comprobado en el teléfono, y **la instaló el usuario** como
    actualización: de la v975 (`2afc6ed`, 16/11) a la v1022, sin desinstalar.
  - No se tocaron las otras apps de REBELUM (`juego`, `experimental`, `prueba3d`).
- **Respaldo previo:** `D:\REBELUM_respaldos\2026-11-18_redmi_auditoria_antes_validado_3ff3c7b\` (carpeta nueva).
  - Contiene `files_completo.tar` (712 archivos de `files/`), los 9 archivos sueltos y los SHA del teléfono.
  - El tar extraído en el PC da los mismos 712 SHA que el teléfono.
  - Tras instalar, `files/` era idéntico al respaldo: instalar no tocó los datos.
- **Pruebas:** todas en el banco de pruebas, con la partida aislada `banco_pruebas.save`.
  - `partida_exp.save` no se abrió.
  - Toques reales con `adb shell input tap`.
  - `dumpsys SurfaceFlinger --timestats` de la capa del juego, puesto a cero en cada tramo.
  - `dumpsys meminfo`: TOTAL PSS.
- **Registros y capturas:** `D:\REBELUM_diagnostico\redmi_18_11\` (358 archivos). Las hojas `comparativa_16_vs_18.png`,
  `problemas_18_11.png`, `combates_18_11.png`, `hoja_perfiles.png`, `hoja_recarga.png` y `hoja_*.png` se hicieron con
  Blender.

## Al terminar (20:02): datos de Auditoría

| Archivo | Respaldo → final |
|---|---|
| `partida_exp.save` y `.bak` | `567c7323…` → **igual** |
| `ajustes.cfg` | `002a6989…` → **igual** (ver nota) |
| `calidad.log`, `respaldo_antes_de_corromper.save`, `partida_exp.save.danada`, `banco_pastos_verdes_3d.csv` | **iguales** |
| `banco_pruebas.save` y `.bak` | **cambiados** (partida aislada del banco) |
| `shader_cache/SceneShaderGLES3/` | **2 archivos nuevos** (caché del motor) |

- **Nota sobre `ajustes.cfg`:** para ver las derrotas se pusieron un rato los protagonistas «Originales»; antes de
  terminar se volvió a «v3» desde el banco. La «Calidad 3D» la había dejado fija el botón CAL, que solo dura la sesión, y
  se devolvió a «Regulador normal».
- **Restaurado por archivo: nada.** La partida y los ajustes no cambiaron. `banco_pruebas.save` es la partida aislada
  del banco, que se rehace desde su base cada vez que se entra, así que no se sobrescribió con la copia antigua. La caché
  de sombreadores la gestiona el motor.
- La app quedó en segundo plano (botón de inicio), dentro del banco, como estaba antes de la sesión.

## Arranque

- **Carga terminada en 15,1 s** (1016 archivos, 0 fallos). La fase de sombreadores tardó 1 811 ms; era el primer
  arranque tras instalar.
- **0 errores `Parameter "material" is null`**, con los «Protagonistas v3» activos. El 16/11 salían 12 en este mismo
  punto. **Queda comprobado en el Redmi** el arreglo del PC del 17/11 (`MATERIAL_NULL_17_11.md`).
- PSS: portada 874 MB, banco 852 MB.

## Ciudad de Oakhaven (maqueta), regulador normal

El regulador eligió el perfil bajo, escalón 0, 3D ×0,75 (1200×540).

### Índice espacial (punto 10 del encargo)

- Logcat: `[ciudad] índice del plano: 9689 casillas en 140.3 ms`. En el PC tarda 37 ms: aquí es 3,8 veces más.
- **No produce un tirón aparte al jugar.** Se crea una sola vez por proceso (es estático), durante la carga de la
  escena: 0,39 s después de la línea `[calidad]` de la escena.
  - **1.ª entrada** (con índice), primeros 14 s: 2 fotogramas de ≥ 1 s (la carga) y 1 de 66 ms; el resto, a 33 ms.
  - **2.ª entrada** (sin índice): 1 fotograma de 550 ms y ninguno de ≥ 1 s.
  - **3.ª y 4.ª entradas:** 1 fotograma de 250-300 ms cada una.
- Lo que añade el índice va **dentro de la pausa de la primera carga**, que ya se nota de por sí. Esa pausa también la
  alargan otras cosas que se cargan la primera vez, y esta medida no las separa.
- La opción de crear el índice en un hilo (MEDIDAS_PC.md §7.7) solo acortaría esa primera carga unos 0,14 s. **No es
  urgente.**

### Recorrido, esquinas, obstáculos y seguimiento (punto 6)

| Tramo | Fotogramas | FPS | Histograma | PSS |
|---|---|---|---|---|
| Puerta del Sur → Plaza → escalinata → Barrio Alto (6 toques al norte) | 740 | 30,3 | 33 ms = 676, 50 = 12, 86/102/118 = 1 | 898 MB |
| Toques en diagonal hacia esquinas (Barrio Alto) | 719 | 30,0 | 33 = 674, 50 = 10, 400 = 1 (cambio de escena) | 887 |
| Plaza: entrar y rodear por el oeste y el este (9 toques) | 1 104 | 30,3 | 33 = 1 043, 50 = 8, 66 = 2, 118 = 1 | 887 |
| Plaza hacia el este, la Calle del Mercado (10 toques) | 1 178 | 30,4 | 33 = 1 109, 50 = 15 | 1 023 (con originales) |

- **La fuente ya no corta el camino.** Con toques rectos al norte, Kael la rodea solo y sube la escalinata
  (`t01_norte_4.png` y `t01_norte_5.png`). El 16/11 había que rodearla a mano.
- **El grupo sigue a Kael** en fila por la Calle Mayor, la plaza, la escalinata y el Barrio Alto, y en grupo al
  pararse: Lya detrás y Garon cerrando. En ninguna captura queda nadie atrás ni dentro de un bloque.
- **Kael se para en las esquinas con toques en diagonal.** En el Barrio Alto, con dos toques hacia arriba a la derecha,
  se queda quieto contra la esquina de una casa (`t02_diag_1.png` y `t02_diag_2.png`, iguales). **Es el atasco ya
  conocido del PC** (RECORRIDO.md), ahora visto en el teléfono. Sigue sin arreglar.
- **Al tocar sobre un edificio, Kael se queda pegado a la pared** y no busca la entrada ni rodea. Pasa al oeste de la
  plaza (`t03_plaza_4/5`), al este (`t03_plaza_7/8`) y en la Calle del Mercado (`t04_este_3…10`). Para llegar a la Calle
  de los Oficios hay que tocar el hueco de la calle, no el edificio. No se llegó a Oficios, Ribera, Terrazas, Pasajes ni
  Cuervo: **esos sectores siguen sin andar en el Redmi.**
- **Error del método, no del juego:** un toque en (250, 120) cayó sobre el botón «Volver al banco». Los toques de
  prueba deben evitar la franja de botones de arriba a la izquierda.

### Visibilidad: pilares, fuente y rótulos (punto 8)

- **Rótulos de sector gigantes:** **arreglado en el Redmi.** El 16/11 «Plaza del Tapiz y Gran Mercado (maqueta)» y
  «Barrio Alto de las Raíces (maqueta)» ocupaban media pantalla; hoy no aparecen en esos sitios. Solo se ven los rótulos
  pequeños de las puertas, a menos de 10 m (`comparativa_16_vs_18.png`, filas 1 y 3; sitios parecidos, no el mismo punto
  exacto).
- **Aclarado:** las casas y soportales que quedan entre la cámara y Kael se vuelven translúcidos, con su rótulo
  (`t03_plaza_7.png`). Al pie y en lo alto de la escalinata Kael se ve entero (`comparativa_16_vs_18.png`, fila 2). El
  16/11, en un sitio parecido, lo tapaba medio el canto de un parterre.
- **Pilares finos:** en lo andado hoy ningún pilar tapó a Kael. No se repitió el punto exacto de la lonja del 16/11
  (`t07_norte`), así que ese caso concreto no está re-medido.
- **Problemas nuevos:**
  1. **Un muro tapa media figura de Kael** al este de la plaza, junto a la Calle del Mercado (`t04_este_5.png`). El
     soportal de delante sí se aclara, pero el muro de la casa de la derecha no, y corta a Kael por la mitad.
  2. **Los rótulos de puerta quedan cortados** por la geometría que tienen delante: «Casa (en obras)» detrás del bloque
     del árbol en todos los perfiles (`hoja_perfiles.png`) y detrás del muro (`t04_este_5.png`). En el Barrio Alto se
     lee «…sa (en obras)».

### Perfiles en la plaza (punto 7)

Mismo tramo de 6 toques (norte, norte, sur, sur, norte, sur) en cada caso. El botón CAL deja el perfil fijo para la
sesión; el regulador normal está apagado mientras tanto.

| Perfil | 3D | Fotogramas | FPS | Histograma | PSS |
|---|---|---|---|---|---|
| Regulador normal (bajo, escalón 0) | ×0,75 (1200×540) | 711 | **30,4** | 33 = 669, 50 = 5, 66 = 1, 102 = 1 | 900 MB |
| Medio fijo | ×0,80 (1280×576) | 704 | **30,4** | 33 = 660, 50 = 10 | 984 MB |
| Alto fijo | ×1,00 (1600×720) | 769 | **33,0** | 16 = 127, 33 = 612, 50 = 9 | 998 MB |
| Bajo fijo | ×0,75 | 704 | **30,4** | 33 = 680, 50 = 2 | 955 MB |

- **Bajo y medio sostienen 30 FPS**, con casi todos los fotogramas a 33 ms. **Alto no llega a 60:** 33 FPS de media,
  igual que el 16/11. Su PSS (998 MB) pasa del tope de 950 MB.
- **Lo que se ve** (`hoja_perfiles.png`):
  - bajo, sin sombras;
  - medio, con sombras suaves;
  - alto, con sombras de borde dentado («dientes de sierra») en la pared de la izquierda.
- Al cambiar de perfil con CAL la memoria no vuelve a la de partida: 900 MB antes, 955 MB en bajo después de pasar por
  medio y alto.

### Guardar y recargar, y memoria (punto 7)

- **«Guardar y recargar»:** el grupo reaparece en el mismo sitio (`hoja_recarga.png`). La recarga tiene 1 fotograma de
  300 ms y otro de 86 ms. PSS 937 MB.
- **Dos ciclos banco → ciudad → banco:** 930 → 938 → 937 → 935 MB. **Sin fuga.** El 16/11 tampoco la había.
- La memoria sí sube al pasar por escenas distintas, como el 16/11:

  | Momento | PSS |
  |---|---|
  | Banco al empezar | 852 MB |
  | Ciudad | 929 MB |
  | Combate de Nix | 983 MB |
  | Érebo | 997 MB |
  | **Custodio** | **1 045 MB** |
  | Ciudad al final (con los originales) | **1 044 MB** |

  Es de un solo proceso tras más de 40 minutos y muchas escenas. Los dos valores en negrita pasan del tope de 950 MB.
  Sigue PENDIENTE separar caché de fuga.

### Tiempos de carga

| Momento | Tiempo |
|---|---|
| Arranque | 15,1 s |
| 1.ª entrada en la ciudad | 2 fotogramas de ≥ 1 s |
| Entradas siguientes | 250-550 ms |
| Entrada al combate | 1 fotograma de ≥ 1 s |
| Vuelta al banco | 350-400 ms |

### Respuesta táctil (punto 7)

- Todos los toques se registraron a la primera:
  - en la ciudad, salvo los que cayeron en un botón de la interfaz;
  - en los menús de combate (Atacar, Magia, Invocación, Objeto, Huir);
  - en las listas de enemigos y aliados;
  - en los selectores del banco.
- En los submenús de magia, el primer toque abre la ficha del hechizo y el segundo elige el objetivo. Es el diseño, no
  un fallo.
- **No se ha medido la latencia en milisegundos:** haría falta grabar la pantalla y analizar fotograma a fotograma.

## Combate, Nix, Érebo y derrotas (punto 9)

Los combates del banco son de prueba: aislados y con la vida de los enemigos multiplicada.

- **Nix desde el FBX:**
  - El combate va a 58 FPS (tope de 60; 1 192 fotogramas, 1 de ≥ 1 s al entrar).
  - Canaliza «Ascuas de Nácar» (30 de daño), deja el sello y el turno sigue (`hoja_nix_canalizar.png`).
  - Kael ataca bien y el enemigo reacciona encogiéndose (`hoja_nix_ataque.png`).
  - Detalle visual: los tres slimes se solapan y sus etiquetas «PV 408/408» se pisan (`garon_menu.png`).
- **Érebo** (orbe experimental, invocación «Vídeo»):
  - Lya invoca en su primer turno con la Armonía llena.
  - El vídeo se ve entero y el enemigo cae (`hoja_erebo.png`).
  - 25 s con 58 FPS de media; el peor fotograma, 150 ms. PSS 997 MB.
- **Custodio de Porcelana** (vida ×8), con los protagonistas «Originales»:
  - Va a 54-56 FPS (6 750-9 640 fotogramas por tramo, el peor de 700 ms una vez).
  - Victoria: el Custodio se desploma y se desvanece, los héroes celebran (Kael con la espada en alto) y se vuelve al
    banco (`hoja_victoria.png`).
- **Derrotas de los héroes: NO vistas en el Redmi.** En unas 85 rondas el Custodio casi no actuó: Kael lo congela en
  cada golpe (Frostfang, D-017). Lya bajó hasta 10/146 PV, pero ningún héroe cayó.
  - El arreglo de la caída de la Lya original (`00a4bbd`, a 0,3 m) y lo medido de Naira y Nix siguen **solo medidos en
    el PC** (`DERROTA_SUELO_18_11.md`).
  - Para verlas en el teléfono haría falta un caso de banco que empiece con un héroe casi sin vida, o sin Frostfang.
- **Érebo derrotado** (su caída hereda el cambio de `maga_3d.gd`): ni medido en el PC ni visto en el Redmi.

## Resumen: qué queda validado en el Redmi y qué no

**Validado hoy en el Redmi:**
- La APK del validado arranca sin errores de material.
- La ciudad va a 30 FPS en bajo, medio y el regulador normal.
- El índice espacial (140 ms) va dentro de la primera carga, sin tirón aparte.
- La fuente se rodea sola.
- El grupo sigue a Kael.
- Los rótulos gigantes desaparecieron y el aclarado funciona.
- «Guardar y recargar» deja al grupo en su sitio.
- La memoria no crece en los ciclos de la ciudad.
- Nix canaliza en combate.
- La invocación de Érebo en vídeo se ve entera.
- La victoria contra el Custodio.

**Problemas encontrados:**
1. Kael se para en las esquinas con toques en diagonal (conocido del PC).
2. Al tocar sobre un edificio, Kael se queda en la pared y no busca camino.
3. Un muro sin aclarar tapa media figura de Kael en la Calle del Mercado.
4. Los rótulos de puerta quedan cortados por la geometría.
5. El perfil alto: 33 FPS, 998 MB y sombras dentadas.
6. Después de muchas escenas, la memoria llega a 1 045 MB (combate del Custodio) y 1 044 MB (ciudad).
7. Las etiquetas de PV de los slimes se solapan.

**Sin validar en el Redmi:**
- las derrotas de los héroes (Lya, Naira, Nix y Érebo);
- los sectores Oficios, Ribera, Terrazas, Pasajes y Cuervo;
- los interiores;
- la latencia táctil en milisegundos;
- el punto exacto del pilar de la lonja del 16/11.
