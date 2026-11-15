# Actividades futuras con identidad propia (16/11, PROPUESTA [P])

Encargo del usuario (15/11, noche): preparar el ENCAJE NARRATIVO de tres actividades, sin completar sus sistemas;
como mucho un ejemplo pequeño cuando el barrio y su misión principal funcionen. Todo es [P]: nada de esto es canon.
Restricciones comunes: nada de la niebla, el Sello, Érebo, el niño del tapiz ni aldeas perdidas (D-033, versión
neutra D-073; vetos de `pruebas/prueba_ciudad_datos.gd`); nadie sabe un secreto antes de descubrirlo; los PNJ
distinguen lo que SABEN, lo que han OÍDO y lo que CREEN (modelo del barrio, `BARRIO_OAKHAVEN_PLAN.md` §6); sin
cuentas atrás obligatorias; recompensas del catálogo real y una sola vez.

Se apoyan en sistemas que YA existen, para no abrir sistemas nuevos:
- el **Gremio de aventureros** (`gremio.gd`): contratos de tipo `derrotar`, `entregar` y `cumplir <condición>`, con
  reputación y rangos (Bronce, Plata, Oro), y **proyectos de reconstrucción** que cambian lugares;
- las **investigaciones** (`datos/investigaciones/*.tres`) y las **recetas** (`datos/recetas/*.tres`);
- las **misiones con pasos** de `encargos.gd` (patrón del cantero y de «Antes de que se enfríe»: estados bool en
  `mazmorras[...]`, `saltado_si`, fuera de orden, premio una vez);
- las **piezas examinables** y los **diálogos** con señales (`bar:`, `oak:`…).

## 1. Rastreadores — investigar antes de intervenir

**Idea.** Un encargo del Gremio no dice «mata 5 lobos»: dice «algo pasa en el camino de las carretas». El jugador
sigue SEÑALES, IDENTIFICA el problema y DECIDE cómo intervenir; a veces el problema no es un monstruo.

| | |
|---|---|
| **Inicio** | Un contrato «cumplir» del tablón del Gremio (rango Bronce) con un texto de aviso, no de objetivo: «Las carretas llegan con las lonas rasgadas. Averiguad por qué.» |
| **Lugares** | El camino de las carretas (mapamundi, «Tierras de Oakhaven»), el patio de caravanas del barrio (T1) y un rincón del Gran Bosque ya existente. Sin lugares nuevos. |
| **Personajes** | Brena (establo: ve los animales nerviosos), Tobías (porteador: ha OÍDO a los carreteros), un carretero de caravana (CREE que son lobos). |
| **Conocimiento** | Señales examinables: huellas, lonas rasgadas a una altura concreta, restos en el camino. Cada señal pone un estado `j_sabe_*`. Lo que dicen los PNJ queda como `oido`/`cree` en el Diario («Tobías se lo oyó a un carretero: …»). |
| **Decisión** | Con suficientes señales, tres salidas: (a) ahuyentar (combate con una criatura YA existente del bestiario, p. ej. una que se ponga en el camino), (b) cambiar la ruta de las carretas (hablar con el carretero: consecuencia en el barrio), (c) poner una protección (entregar un objeto ya existente). |
| **Consecuencia** | Reconocible al volver: las lonas llegan sanas; Brena deja de atar a Avena; según la decisión, el carretero comenta la ruta nueva o la caravana trae otra mercancía al puesto. |
| **Recompensa** | Reputación del Gremio y oro del contrato (como hoy). Una sola vez. |

Primer ejemplo posible (el más pequeño): un solo contrato «cumplir» con 3 señales y la decisión (a)/(b), reutilizando
criaturas y el sistema de contratos. **No implementado esta noche.**

## 2. Piezas Huérfanas — objetos con procedencia

**Idea.** Objetos rotos o incompletos que aparecen sueltos (en un taller, en una vivienda, en una caravana). No se
venden: se RECONSTRUYEN averiguando de dónde vienen, con pistas, y al completarse tienen una UTILIDAD definida.

| | |
|---|---|
| **Inicio** | Al examinar la primera pieza (p. ej. una hebilla de arnés en el taller de Damián): «No es de aquí. ¿De quién será?». Aparece en el Diario como pieza huérfana. |
| **Lugares** | Barrio (taller, vivienda, establo), Oakhaven (mercado, herrería de Ferro — solo como lugar de consulta, sin cambiar a Ferro), Sunken City (el Ancla Seca, si se construye). |
| **Personajes** | Damián (SABE de madera y ruedas), Ferro (SABE de hierro; consulta), Odila (SABE de tela y costura), un mercader (CREE saber la procedencia y se equivoca: modo `cree`). |
| **Conocimiento** | Cada pieza tiene 2-3 PROCEDENCIAS posibles; las pistas descartan o confirman. Lo que dice cada oficio depende de su saber (un carpintero no sabe de metal). |
| **Consecuencia** | La pieza reconstruida vuelve a su dueño o a un uso: la hebilla completa el arnés de Avena (Brena puede pasear con ella al patio), una rueda pequeña vuelve al juguete de Nela, un farol de barco se cuelga en la Quilla. Cambio visible al volver. |
| **Recompensa** | La utilidad misma; a veces una receta o una investigación ya existentes (`datos/recetas`, `datos/investigaciones`) o un material del catálogo. Nunca un objeto nuevo inventado. |

Encaje técnico: una pieza huérfana es un ESTADO (no un objeto de inventario: `menus.gd` lo enseñaría y la tienda
podría venderlo; ver la galga del barrio) más una misión corta de `encargos.gd` con pasos «procedencia».

## 3. Feria de los Oficios — las consecuencias, a la vista

**Idea.** Un acontecimiento periódico en la plaza del barrio (T3) donde se VE lo que los trabajos y descubrimientos
del jugador han cambiado: puestos que existen o no según lo hecho, PNJ que comentan lo ocurrido y una pequeña
muestra de cada oficio.

| | |
|---|---|
| **Inicio** | Un aviso en la plaza y en el tablón cuando se cumplen ciertas condiciones (p. ej. «Antes de que se enfríe» terminada y al menos un contrato de Rastreadores). Sin fecha fija ni cuenta atrás: está mientras el jugador quiera. |
| **Lugares** | La plaza del mercado del barrio (T3) y el patio de talleres (T4). |
| **Personajes** | Maela (puesto del pan: más variedad si el reparto llegó), Damián (expone una rueda; si se reconstruyó una pieza huérfana, la enseña), Brena (pasea a Avena si el arnés está completo), Tobías, Odila y Nela; vecinos que COMENTAN lo que saben u oyeron. |
| **Conocimiento** | Los comentarios salen de los estados del jugador: quien estuvo presente SABE, quien no, lo ha OÍDO; nadie inventa lo que no pasó. |
| **Consecuencia** | Es en sí la consecuencia: el barrio muestra lo que el jugador hizo. Puede abrir un proyecto de reconstrucción del Gremio ya existente (p. ej. mejorar el patio). |
| **Recompensa** | Ninguna obligatoria. Un concurso opcional pequeño (adivinar, elegir) con un premio único del catálogo. |

Encaje técnico: un «programa» extra de las rutinas del barrio (`barrio_vivo.gd`: los PNJ cambian de puesto) y un
conjunto de frases condicionadas; los puestos se encienden por estados. Sin escenas nuevas.

## Orden propuesto y lo que queda para el usuario
1. Cuando el barrio y «Antes de que se enfríe» funcionen: el ejemplo pequeño de **Rastreadores** (un contrato, tres
   señales, dos decisiones), porque reutiliza el Gremio y una criatura ya hecha.
2. Después, una **Pieza Huérfana** (la hebilla del arnés), que conecta taller, establo y vivienda.
3. La **Feria** al final, cuando haya consecuencias que enseñar.

Decisiones [D] del usuario: los nombres (Rastreadores, Piezas Huérfanas, Feria de los Oficios, y los de los PNJ del
barrio), si el Gremio es el punto de entrada de los Rastreadores, y qué criatura del bestiario aparece en el camino.
