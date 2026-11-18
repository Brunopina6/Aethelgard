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

Lo que se sabe del PC (`prueba_banco_derrotas`, sin ventana, SUPERADA):
- Con originales, v2 y v3, y con Naira y Nix, los tres héroes llegan a 0 PV y ejecutan su `morir()`.
- Nadie abre su menú, sale «Derrota...» y se vuelve al banco.
- La partida de siempre no cambia.
- **No se ha visto con ventana ni en el teléfono.**

Érebo **no** tiene derrota que ver: nunca ejecuta `morir()` en el juego (`DERROTA_SUELO_18_11.md`).

## Al terminar

- Los mismos SHA de `files/` que tras instalar, sin restaurar nada automáticamente. Si algo cambió, decirlo.
- Resultados en `docs/v12/REDMI_19_11.md`, separando lo visto en el Redmi de lo medido en el PC.
