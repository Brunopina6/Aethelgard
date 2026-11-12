# Encargo del usuario: Humbaba, el Corazón del Bosque Muerto (12/11/2026)

**Estado:** en cola. Se empieza en cuanto termine el Bramavidrio v4.

- **Referencia visual del usuario:** `D:\REBELUM_diagnostico\v12\referencias\humbaba_referencia_usuario.webp`
  (SHA-256 `8b6c183aa4fda0ccb5313042e801061b2efae489003dd1cfe64488b1544b881a`). La aportó el usuario como referencia y
  su licencia no está registrada.
- **El usuario pide** trabajar sin pedirle permiso; el Redmi estará desconectado.
- **Humbaba es más grande que los protagonistas:** de 10 a 14 m de altura aparente.

## Decisiones del coordinador

- **Herramientas:** Blender por guion (ver la memoria del método). **No usar Hunyuan3D**, instalado en Descargas: su
  licencia excluye la Unión Europea, el Reino Unido y Corea del Sur, y el usuario está en Europa.
- **No sustituye al Guardián del Bosque** de Pastos Verdes («El bosque que no recuerda», `combate_bosque.gd`). Es un jefe
  nuevo.
- **Sitio propuesto:** el Gran Bosque Verde. Allí el texto del mapa promete un santuario y el Núcleo de la Naturaleza
  que no existen todavía.
- **Va APAGADO** (interruptor) hasta que el usuario lo vea: no se cambian el canon ni los encuentros normales.
- **El combate es ATB** (`combate.gd`), con el patrón de los jefes con módulo propio (`combate_bramavidrio.gd`,
  `combate_coloso.gd`). No se crea otro sistema.

## Resumen fiel del encargo

1. **Diseño** (respetar la referencia sin rediseñarla ni simplificarla de más):
   - coloso de raíces retorcidas, troncos petrificados y madera maldita;
   - cabeza-tronco con corona de ramas y un único gran ojo turquesa en la frente;
   - boca oscura que se abre para rugir;
   - núcleo turquesa en el pecho;
   - brazos largos, gruesos y asimétricos, con manos enormes de dedos y garras de madera;
   - piernas de raíces entrelazadas;
   - musgo, lianas y raíces colgantes;
   - bastón ancestral separado, equipado como arma;
   - paleta de madera oscura, verdes desaturados y magia turquesa.
2. **Blender:** si solo hay imágenes, reconstruir la geometría (primero un blockout) **sin decir que hay rig hasta que
   lo haya**. Componentes por separado: cuerpo, cabeza y mandíbula, brazos y manos, piernas y pies, corona, raíces
   móviles, musgo y adornos, bastón y núcleo. Topología deformable solo en las articulaciones.
3. **Rig:**
   - **Base:** humanoide adaptado, con raíz, pelvis, 3 tramos de columna, pecho, 2 de cuello, cabeza, mandíbula,
     hombros, brazo, antebrazo, muñeca, palma, dedos simplificados, muslo, pierna, tobillo y pie. IK en piernas, IK/FK
     en brazos y un control del ojo.
   - **Corona:** ramas agrupadas en pocos conjuntos; solo las grandes con hueso.
   - **Raíces:** de 4 a 6 cadenas de 2 o 3 tramos.
   - **Garras:** que abran, cierren, agarren, aplasten y señalen.
   - **Bastón:** separado y con anclaje en la mano.
   - **Exportación:** rig limpio y sin simulaciones en tiempo de ejecución; de 60 a 90 huesos deformantes, y cualquier
     aumento se justifica.
4. **Animaciones**, como acciones separadas, con preparación, golpe y recuperación cuando proceda: `idle`, `idle_angry`,
   `walk`, `turn_left` y `turn_right`, `roar`, `hit_light`, `hit_heavy`, `stagger`, `phase_transition`, `death`, y las de
   cada ataque.
5. **Ataques:**

| N.º | Ataque | Qué hace |
|---|---|---|
| 1 | Puño del Bosque Primordial | Daño físico en área, esquivable fuera de la zona marcada |
| 2 | Raíces Devoradoras | Raíces bajo los objetivos, como objetos aparte en Godot; daño e inmovilización |
| 3 | Aliento de la Putrefacción | Cono de esporas con partículas eficientes; daño progresivo o corrupción |
| 4 | Guadaña de Raíces | Pieza o efecto en el antebrazo; barrido horizontal |
| 5 | El Ojo del Juicio | Preparación visible y rayo desde un marcador en el ojo |
| 6 | Llamada de los Condenados | Clava el bastón e invoca con el sistema de aparición de siempre, con un tope |
| 7 | Abrazo de la Muerte | Agarre con daño y una oportunidad de liberarse |

6. **Fases** (umbrales ajustables):

| Fase | Vida | Qué cambia |
|---|---|---|
| 1. El Guardián Despierta | 100-70 % | Usa el Puño, las Raíces Devoradoras y la Guadaña; su punto débil es el núcleo |
| 2. El Bosque Enfermo | 70-35 % | El núcleo se agrieta y se vuelve verde enfermizo; añade el Aliento, el Ojo del Juicio y la Llamada; tiene animación de transformación |
| 3. Corazón del Abismo | 35-0 % | Rompe su armadura y el núcleo queda expuesto; añade combinados y el definitivo, «Réquiem del Bosque Eterno» |

   El Réquiem: hunde los brazos, el núcleo brilla, las raíces cubren la arena, brotan troncos, estalla una onda y queda
   vulnerable. Lleva una señal clara antes de la explosión y se hace con objetos y efectos independientes.
7. **Godot:** cada ataque con identificador, animación, preparación visual, evento exacto de impacto, daño configurable,
   objetivos, efectos y sonido, estados opcionales, recuperación, fases en que puede usarlo y forma de contrarrestarlo.
   El daño **no** depende solo de lo que dure la animación. Una máquina de estados controla animaciones, habilidades,
   fases, interrupciones y muerte.
8. **Android:** el objetivo son 30 FPS. LOD, triángulos medidos, texturas comprimidas, emisión por material, partículas
   con límite, sin física en la vegetación, menos huesos activos en lo secundario, colisiones simples, perfiles bajo y
   medio y recursos liberados al acabar. **No dar el rendimiento por bueno sin medirlo en el teléfono.**
9. **Exportación y pruebas:** GLB, revisando orientación, escala, jerarquía, pesos, materiales, animaciones, bastón,
   marcadores, que no sobren huesos y transiciones. Por orden: estático, rig, animaciones y mecánicas.
10. **Etapas:**
    1. auditoría y diseño del esqueleto;
    2. malla, rig y deformaciones;
    3. animaciones básicas y primeras pruebas en Godot;
    4. ataques y efectos;
    5. tres fases;
    6. integración, rendimiento y errores.

    Primero, un prototipo con rig y tres animaciones. No se cierra ninguna etapa sin comprobar sus resultados.
