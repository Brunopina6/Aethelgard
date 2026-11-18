# Guion del Redmi, 19/11 (APK de Auditoría pendiente de compilar)

Lo que hay que comprobar en el teléfono de lo hecho en el PC la tarde del 18/11. **Nada de esto está validado en
Android.** La APK todavía no existe. Se compila desde el commit que lleve esto, con el mismo certificado y el mismo
procedimiento que la del 18/11 (`GUION_REDMI_18_11.md`, apartados «APK» y «Orden»: respaldo byte a byte antes, copia por
USB a Descargas e instalación por el usuario).

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
