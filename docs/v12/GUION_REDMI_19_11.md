# Guion del Redmi, 19/11 (APK de Auditoría del validado `9d1baef`)

Lo que hay que comprobar en el teléfono de lo hecho en el PC la tarde del 18/11. **Nada de esto está validado en
Android.**

- **APK:** `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261118-9d1baef-local.apk`, 478,3 MB, versionCode 1026,
  SHA-256 `6bdf79a84d8d5e15b0efadde2a515fa70a7c32d7c5fd7054bc4727e86738db60`, certificado `3413edcd…7785f3`, «TODO
  CORRECTO». Es el validado `9d1baef` (batería 200 · 0 · 116 · 0, etiqueta `validado/v12/20261118-222238`).
- **Orden:** como en `GUION_REDMI_18_11.md`: respaldo byte a byte de `files/` en una carpeta NUEVA
  (`D:\REBELUM_respaldos\2026-11-19_redmi_auditoria_antes_9d1baef`), copia por USB a Descargas con el SHA comprobado e
  instalación por el usuario (`adb install` lo bloquea el control de seguridad), y los mismos SHA tras instalar.

## Ciudad (arreglos tras `REDMI_18_11.md`)

1. **Esquinas con toques en diagonal** (`9d1baef`, RECORRIDO.md §11): en el Barrio Alto, junto a la casa del rellano 1,
   tocar en diagonal al otro lado de la esquina: Kael debe rodearla y llegar (el 18/11 se quedaba parado, `t02_diag_1/2`).
   Probar también tocar al otro lado de una casa entera: debe pararse ante ella, como antes.
2. **Fachada de lado** (`af3e1f9`, §10): Kael pegado a la casa del soportal sur de la Calle Mayor (el sitio de
   `t04_este_5`) y en el rellano 1: la casa debe aclararse y Kael verse entero.
3. **Rótulos «(en obras)»** cercanos: deben leerse enteros (en la plaza alta, tras la copa del árbol, y en el Barrio
   Alto), en bajo, medio y alto (CAL). Vigilar si alguno cercano se ve por encima de una casa que no toca y si en medio
   o alto cambian de golpe al cruzar los 10 m. Y si la primera vez hay un tirón al preparar ese dibujo.

## Derrotas de los héroes (pendiente de `REDMI_18_11.md`, punto 9)

El 18/11 no se pudieron ver: en el caso del Custodio, en unas 85 rondas no cayó ningún héroe. Ahora el banco tiene dos
casos solo para eso.

1. Entrar en el banco de pruebas (Auditoría). En «Protagonistas», arriba, elegir **Originales**.
2. Tocar **«Derrotas: los héroes empiezan casi sin vida»** y **no tocar nada**:
   - los héroes entran con 1 PV;
   - los tres slimes atacan enseguida y cada golpe derriba a uno: Kael, después Lya y después Garon;
   - al caer el último sale «Derrota...» y unos 2 s después se vuelve solo al banco.
3. Repetir con «Protagonistas» en **v2** y en **v3**.
4. Tocar **«Derrotas de Naira y Nix (casi sin vida)»**: caen Kael, Naira y Nix (prototipos que solo existen en el banco).
5. Al terminar, volver a dejar «Protagonistas» como estaba (el 18/11 estaba en **v3**). Este selector escribe en
   `ajustes.cfg`, igual que Ajustes.

Qué mirar en cada derrota (capturas o vídeo de la pantalla):
- Si el cuerpo queda medio enterrado: el borde de abajo cortado en recto contra la hierba.
  - En el PC, `DERROTA_SUELO_18_11.md` mide hundidos a Kael (cabeza, 0,13 m en originales) y a los v2 y v3 (sobre todo
    Garon v3, 0,56 m).
  - Lya original ya debería verse apoyada (`00a4bbd`, desplome a 0,3 m).
- Si el clip se corta: la vuelta al banco llega unos 2,4 s después de «Derrota...». La animación del último en caer es
  la que menos se ve. Si no da tiempo a verla, apuntarlo: no se ha cambiado la espera del combate.
- Que, tras la derrota, el banco abra normal y que otro caso (por ejemplo, «Nix en combate») empiece con la vida llena.

En el caso **«Derrotas de Naira y Nix (casi sin vida)»** (paso 4), mirar además lo siguiente (medidas del PC en `DERROTA_SUELO_18_11.md`,
«Naira y Nix medidas el 19/11» y su revisión). Vale para esta APK `9d1baef` y para la próxima: `DERROTAS_19_11` solo
toca herramientas y `naira_3d.gd`, `nix_3d.gd` y `maga_3d.gd` no han cambiado desde `9d1baef`. Lo que sí cambió en
`combate.gd` (`PV_SLIMES_19_11` y su revisión) es la vida y la colocación de los slimes, así que lo que tapa el slime
puede no ser igual en las dos APK. Mejor con vídeo de la pantalla.
- **Naira** no se tumba: cae de rodillas en 1,6 s y se queda así.
  - El astrolabio queda delante de la rodilla. En el PC, casi la mitad está bajo el suelo (−0,10 m), pero se ve entero.
    Mirar si en el teléfono sale cortado en recto por abajo.
  - Lo mismo con los pies hacia los 0,8 s de la caída (−0,14 m, un instante; en el PC, a 0,80 y 0,83 s, enteros).
  - Si algo se corta, apuntar qué y en qué momento: hay un arreglo propuesto, sin hacer.
- **Nix** cae («derribo», 1,5 s) y se queda de rodillas con un leve bucle. En el PC no queda nada bajo el suelo.
  - Mirar que no flote (rodillas despegadas de la hierba) y que el bucle no dé saltos.
  - Ocupa el sitio de Garon, delante, y en el PC el slime más cercano le tapa parte de las piernas (la colocación de los
    slimes puede variar entre las dos APK). Apuntarlo si impide ver la caída.
- Si en Ajustes está encendida la **Nix del FBX** (`nix_fbx`, la de capucha, con su cetro), apuntar cuál se ve. Se
  midieron las dos. En la del FBX, de rodillas, un faldón trasero queda rígido y recto: apuntar si se ve.

Lo que se sabe del PC (`prueba_banco_derrotas`, sin ventana, SUPERADA):
- Con originales, v2 y v3, y con Naira y Nix, los tres héroes llegan a 0 PV y ejecutan su `morir()`.
- Nadie abre su menú, sale «Derrota...» y se vuelve al banco.
- La partida de siempre no cambia.
- **No se ha visto con ventana ni en el teléfono.**

Érebo **no** tiene derrota que ver: nunca ejecuta `morir()` en el juego (`DERROTA_SUELO_18_11.md`).

## Al terminar

- Los mismos SHA de `files/` que tras instalar, sin restaurar nada automáticamente. Si algo cambió, decirlo.
- Resultados en `docs/v12/REDMI_19_11.md`, separando lo visto en el Redmi de lo medido en el PC.

## Para la próxima APK (con `22856a0` y su revisión; NO para la APK `9d1baef` de arriba)

En la APK `9d1baef` de arriba, el punto 1 sigue igual: si se toca al otro lado de una casa entera, Kael se para ante ella.
En una APK hecha con `22856a0` y `CIUDAD_TOQUE_19_11_REVISION` (PC-16, `RECORRIDO.md` §12), Kael busca un rodeo corto:
- **Toques en tejados**, con Kael cerca y con Kael a 10-20 m:
  - la tienda al este de la plaza, desde su puerta (Calle del Mercado, `t04_este_6`), en el tejado y en su centro;
  - la casa alta del oeste de la plaza (`t03_plaza_4`);
  - una casa de la Calle del Mercado vista desde la otra acera.

  Kael debe ir a la fachada más cercana a lo tocado a la que llegue con un rodeo corto. No debe quedarse pegado a la pared
  donde la recta daba en ella.
- **Al otro lado de una casa entera**:
  - una casa pequeña con suelo alrededor (por ejemplo, `casa_pie` en el Cuervo, de 4×4 m): Kael debe rodearla y
    llegar;
  - una manzana grande: Kael debe acercarse lo que permita el rodeo corto, de su lado o doblando la esquina, sin
    atravesarla.
- **Velocidad en los rodeos**: Kael no debe frenar a paso de andar en las esquinas del rodeo, solo al final.
- **Coste**: con el panel RND abierto, mirar si al tocar sobre un edificio o al otro lado de una manzana hay un tirón (los
  ms por fotograma del momento del toque). En el PC el peor caso es ≤ 8,8 ms. En el Redmi no se ha medido: con el tope
  de tiempo, la búsqueda se corta antes y Kael puede llegar menos lejos que en el PC.
- **Derrotas de Naira y Nix**: lo mismo que en «Derrotas de los héroes», arriba (se mira en las dos APK).
