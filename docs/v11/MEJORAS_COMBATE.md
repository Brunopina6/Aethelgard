# V11 · Mejoras del combate (hito B)

Rama LOCAL `claude/rebelum-v11` (copia `D:\Aethelgard_v11`). Lo hecho en esta rama se marca con su commit. Todo está
**probado solo en el PC** (sin ventana, con datos aislados, y capturas con ventana). Nada se ha probado en el Redmi.

## 1. Por qué los combates se sienten iguales (análisis)

Medido en la huella del combate (`pruebas/referencias/huella_combate.txt`, 9 combates con semilla fija, 30 FPS):

| Combate | Duración | Turnos de héroe | Turnos de enemigo |
|---|---|---|---|
| E1, Kael solo contra Grimfang | 54 s | 8 | 4 |
| E2, Kael y Lya contra el grupo 2 | 48 s | 10 | 8 |
| E3, los tres contra dos Grimfang | 49 s | 9 | 2 |
| E8, Gorthor (jefe) | 74 s | 12 | 3 |
| E4, E5 y E9 (nivel 10) | 15-20 s | 3-4 | 0-1 |

- **Espera:** con un héroe, unos 6,8 s entre decisiones. Los enemigos actúan poco: E3 tiene 9 turnos del grupo y 2 de
  enemigo. El jugador casi siempre ataca a un rival que apenas responde.
- **Repetición:** las órdenes más usadas son «ataca a…», «defiende» y Agua o Cura. A nivel 10, una magia de área acaba
  el combate en 3 turnos.
- **Decisiones:** antes de la V11, ante un golpe anunciado solo había una respuesta útil: defender.
- **Información:** el objetivo se elegía tocando el dibujo y su nombre salía arriba a la izquierda; sin lista ni estado.
  La invocación se lanzaba sin decir cuál era ni qué hacía.
- **Lo que ya funcionaba y se conserva:** el ATB, las 12 magias, Esgrima, Embuir, la Armonía, Érebo, los patrones
  anunciados de Grimfang, el Slime y el Gólem (T-097), y los jefes Guardián y Coloso con sus fases.

**Causas principales:** el enemigo normal tiene una sola forma de amenazar y el jugador una sola de responder; y la
pantalla no ayuda a decidir (no dice qué le pasa a cada enemigo).

## 2. Hecho en la V11 (commit `4e1f734`)

### Panel de objetivos a la derecha
- Al elegir objetivo (ATACAR, MAGIA, artes, objetos, curas e invocación), a la derecha sale la lista:
  - nombre de cada enemigo; los repetidos llevan A, B…;
  - sus PV y una raya de vida;
  - lo que se sabe de él: prepara un golpe (y cómo cortarlo), en guardia, aturdido, quemado o congelado;
  - los derrotados, apagados con «Derrotado» y sin poder tocarlos.
- El apuntado lleva «▶» y un marco dorado, igual que la flecha sobre su dibujo.
- **Controles:**
  - tocar una fila apunta y soltar elige; el ratón apunta al pasar;
  - teclado y mando siguen igual (la lista sigue a la selección).
- Al curar o elegir aliado, la lista es de aliados.
- **Área:**
  - al marcar una magia o un arte que alcanza a todos, sale una flecha dorada sobre cada enemigo;
  - mientras se lanza, la lista dice «LE ALCANZA» y marca a todos con «◆».

### Lista de INVOCACIÓN
- INVOCACIÓN abre la lista de invocaciones. Hoy solo existe Érebo, y solo se lista lo que de verdad existe.
- La fila lleva su emblema, el coste (100 % de Armonía) y lo que hace: el texto de siempre, «Ladrón de Corazones».
- Si no se puede usar, sale apagada y dice por qué (por ejemplo, «Armonía al 50 %»).
- Al elegirla se toca al enemigo, como siempre. Atrás vuelve a la lista. Las reglas no cambian.

### Interrupción del golpe preparado (patrón táctico nuevo)
- Cuando Grimfang (Hachazo), el Slime (Rebote) o el Gólem de ámbar (Pisotón) preparan su golpe, hay dos respuestas:
  - **defender**, como antes;
  - **cargar contra él:** si el grupo le quita, de una vez o en varias, el **25 % de su vida máxima**, el golpe se corta
    («¡Interrumpido!»). Pierde además su turno siguiente («aturdido, recupera el aliento»).
- **El Slime encogido (en guardia):** los golpes físicos le hacen la mitad, pero **la magia le rompe la guardia**
  («¡Guardia rota!»). Es la ruptura de guardia, solo en este enemigo.
- **Los jefes** (Guardián, Coloso y Gorthor) no cambian: tienen sus propias mecánicas.
- La lista de objetivos lo explica: «⚠ Prepara un golpe: dale fuerte y lo cortas» o «⚠ Encogido: la magia rompe su
  guardia».
- **Por qué el 25 %:** con el grupo de tres, dos golpes o una magia bastan; con Kael solo cuesta más, y defender sigue
  valiendo. Sin medir todavía con jugadores: hay que mirarlo en el Redmi.

### Huella del combate
- Solo cambia E2: la magia de Lya rompe la guardia del Slime B, que recibe el daño entero, pierde el rebote y pasa el
  turno siguiente aturdido.
- Todo lo demás sale igual línea a línea, con los mismos resultados.
- La cabecera de la referencia lo explica.

### Técnica combinada: Filo Arcano (Kael + Lya)
- Está en MAGIA → pestaña **DÚO** de Kael, que sale solo si Lya va en el grupo.
- **Requisitos:** Lya en pie, con 8 PM y con al menos la mitad de su ATB. Si falta algo, sale apagada y dice qué
  («Lya aún no está lista (30 %)», «Lya necesita 8 PM», «Lya ha caído»).
- **Efecto:** Kael golpea con su ataque más el 60 % del Fuego de Lya, con las llamas de Embuir (quema). Cuenta como
  magia, así que rompe la guardia del Slime y suma para interrumpir.
- **Coste:** 8 PM de Lya y su turno (su ATB vuelve a cero). Así es una decisión: el golpe fuerte ahora, o dos turnos.
- **Presentación:** el gesto de lanzar de Lya, un destello de fuego en Kael, el sonido de Embuir, «¡Dúo!» sobre Lya y
  el golpe con llamas.
### Quiebra (Kael + Garon) y Barrera Rúnica (Lya + Garon)
- **Quiebra**, en la pestaña DÚO de Kael:
  - **requisitos:** Garon en pie y con la mitad de su ATB; Kael paga 6 PM;
  - **efecto:** los dos golpean a la vez (el ataque de Kael más el 80 % del de Garon). Es un golpe de ruptura: a
    Grimfang, al Slime o al Gólem que preparan su golpe **se lo corta siempre**, aunque tengan mucha vida, y les quita
    la guardia;
  - **coste:** 6 PM de Kael y el turno de Garon.
- **Barrera Rúnica**, en la pestaña DÚO de Lya:
  - **requisitos:** Garon en pie y con la mitad de su ATB; Lya paga 10 PM;
  - **efecto:** todo el grupo en pie recibe una coraza del 25 % de su vida máxima (la misma coraza que las artes de
    Escarcha, sin sumarse a otra mayor), con cristales de runas dorados;
  - es la respuesta al golpe anunciado a todos, el Pisotón del Gólem;
  - **coste:** 10 PM de Lya y el turno de Garon.
- Si algo falta, la fila sale apagada y dice qué («Garon aún no está listo (20 %)»).
- Commit de las dos: el que sigue a `fb2d91a` (ver `git log`).

## 3. Pruebas

- Batería completa en `4e1f734`: **105 superadas, 0 fallidas, 43 manuales y 0 no seguras**
  (`D:\REBELUM_diagnostico\pruebas\2026-11-11_011705`).
- `prueba_v11_combate` (nueva) comprueba:
  - el panel y el área;
  - la interrupción, la guardia rota y que los jefes no cambian;
  - la lista de invocación;
  - Filo Arcano, Quiebra y Barrera Rúnica.
- Batería completa en `fbab55c` (con el gremio): **106 superadas, 0 fallidas, 43 manuales y 0 no seguras**.
- Siguen pasando `prueba_patrones_enemigos`, `prueba_zarzalin_combate`, `prueba_hud_combate` y `prueba_combate_huella`
  (con la referencia nueva).
- `prueba_artes_combate`: con Lya en el grupo, Kael tiene una pestaña más, «DÚO». Es el único cambio en lo que espera,
  y la prueba lo explica.
- Capturas en `D:\REBELUM_diagnostico\fase2\2026-11-11_v11_fotos_combate\fotos3`, con `pruebas/fotos_v11_combate.gd`:
  - el menú, el panel y un derrotado apagado;
  - el área y la invocación;
  - el aviso, el golpe interrumpido, la pestaña DÚO de Kael y de Lya, y la Barrera Rúnica puesta (carpeta `fotos4`).

## 4. Pendiente del combate (por orden)

1. En el Redmi:
   - que la lista se lea y se toque bien con el dedo;
   - si el 25 % es justo;
   - FPS con la lista abierta.
2. **Técnicas combinadas:** las tres están hechas (Filo Arcano, Quiebra y Barrera Rúnica). Falta una animación propia
   del golpe combinado; hoy reutilizan el golpe, el gesto de lanzar y las señales de las artes.
3. Enemigos con comportamientos nuevos (proteger a otro, invocar refuerzos, cambiar de resistencia). Sin hacer.
4. Variedad de encuentros (élite, emboscada, proteger, objetivo especial). Sin hacer.
5. Cámara e impactos de los golpes fuertes. Sin tocar en la V11: se conservan los de la V9 y la V10.

## 5. Enemigos de élite (variedad de encuentros)

- **Cuándo:** en los encuentros al azar con dos o más héroes, uno de cada seis (el 6.º, el 12.º…) trae un enemigo de
  élite. Se cuenta en la partida (`encuentros_azar`), sin tirar dados: el azar de siempre no cambia, las pruebas con
  semilla salen igual y no hay dos élites seguidos.
- **Quién:** el enemigo con más vida del grupo. Nunca en combates fijos ni con jefes, y nunca con Kael solo.
- **Cómo es:**
  - lleva «★» en el nombre y sus PV y su barra salen en dorado;
  - tiene un 60 % más de vida y un 20 % más de ataque;
  - prepara su golpe más a menudo (+20 %);
  - da el doble de experiencia y de monedas.
- **Lo que ve el jugador:** el cartel «¡Combate! Un enemigo de élite ★» y, en la lista de objetivos, «Élite: doble
  premio».
- **Pruebas:** `prueba_v11_combate`, apartado 7 (el sexto sí, el séptimo no, con Kael solo no). Siguen pasando
  `prueba_grupos_combate`, `prueba_zona3d`, `prueba_patrones_enemigos` y la huella del combate.

## 6. Revisión del 11/11 por la mañana (fase A de la orden siguiente)

- **Filo Arcano tumbó de un golpe al Slime de élite en el Redmi.** Medido en el PC (Kael y Lya a nivel 2, como en la
  partida del móvil):

  | Golpe | Daño |
  |---|---|
  | Ataque de Kael | 16-21 |
  | Fuego de Lya | 72-78 |
  | Filo Arcano sin crítico | 70-80 |
  | Filo Arcano con crítico (×1,6, 12 %) | 112-128 |

  - **Diagnóstico:** fue un crítico legítimo según el código, pero es un **fallo de equilibrio**. El crítico
    multiplicaba también la parte de magia de Lya, y la magia nunca es crítica.
  - **Arreglo:** Filo Arcano ya no hace crítico. La tirada se hace igual, para no mover el azar del resto del
    combate. Así queda en unos 75, menos que atacar con Kael y lanzar el Fuego de Lya por separado (unos 92), a
    cambio de hacerlo en un solo turno y romper guardias.
  - **Prueba:** 40 Filos seguidos nunca pasan del máximo sin crítico (80). Con el arreglo quitado, la prueba falla
    (126 de daño).
- **Élites, fallo intermitente encontrado:** si el sexto encuentro salía con un jefe (el Guardián), se perdía el élite.
  Ahora los grupos con jefe no cuentan, y la prueba lo comprueba (pasó 3 de 3).
- **Guardado:** el gremio y el récord de la taberna se escriben y se leen de un archivo de verdad (`prueba_gremio` y
  `prueba_taberna`), no solo en memoria.
- **Quiebra, Barrera Rúnica, interrupción y la lista de invocaciones:** se prueban en combates de verdad con datos
  fijos (`prueba_v11_combate`). En el móvil siguen sin probar.
