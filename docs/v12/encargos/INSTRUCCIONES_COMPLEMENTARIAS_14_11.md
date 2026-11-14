# Instrucciones complementarias del usuario (14/11/2026, pegadas junto al encargo coordinador; texto literal)

> Según el propio texto, complementan el prompt de expansión del mundo y prevalecen sobre él cuando hay contradicciones.
> Diferencias con el encargo coordinador registradas en `FASES_ENCARGO_COORDINADOR.md` (apartado «Decisiones»).

Claude, las siguientes instrucciones complementan el prompt de expansión del mundo y prevalecen cuando haya contradicciones.
Trabaja automáticamente durante la sesión disponible, sin preguntarme por decisiones técnicas rutinarias ni para pasar de tarea. Dejaré el PC encendido y conectaré el móvil por la mañana.
Lee completos el prompt de expansión, PROMPT_GENERAL_AETHELGARD_CLAUDE.md, el catálogo JSON, los documentos de héroes/enemigos/armas y las referencias adjuntas. Inspecciona el proyecto real antes de modificarlo.
Si falta un archivo o una decisión importante, registra qué bloquea, conserva el comportamiento actual y continúa con trabajo independiente. No inventes su contenido ni detengas toda la sesión.
PRIORIDADES

1. Inspeccionar, conservar cambios pendientes y crear un punto de recuperación.
2. Corregir bloqueos que impidan trabajar o probar.
3. Integrar el orbe experimental de Érebo.
4. Preparar Nix desde su FBX y solucionar la capa de Garon.
5. Aplicar correctamente los permisos de los héroes.
6. Continuar la experiencia jugable de Oakhaven y Pastos Verdes y las demás entregas del prompt de expansión.

NIX YA SE ENTREGA EN 3D
Adjuntaré a Nix en FBX. Aprovecha ese modelo: no la reconstruyas desde cero si sirve.
Inspecciona mallas, materiales, esqueleto y vestuario. Completa lo necesario de rig, pesos, animaciones y vestido, conservando rostro, identidad y referencias actuales.
Mantén capucha, pelo gris recogido, mechón superior y dos delanteros, ojos violetas con fuego interior, negro/púrpura, bordados dorados y medias con motivos dorados asimétricos.
Conserva el emblema de espalda según la referencia: Ojo de Horus integrado en una estrella de seis puntas. Sin sombrero ni recuperación de la melena larga descartada.
Prepara cuerpo y ropa como piezas separadas con un rig compatible. Anima mechones, faldones y emisión durante canalización; comprueba interrupciones y limpieza de efectos.
CAPA DE GARON
Su capa está separada y presenta problemas. Diagnostica y repara anclaje, escala, orientación, rig y pesos.
Si no es reparable razonablemente, queda autorizado crear otra igual o parecida, conservando silueta, colores y detalles. Guarda la original.
Debe permanecer independiente del cuerpo, correctamente sujeta a los hombros y con movimiento al caminar, girar, detenerse y atacar. No la fusiones al torso como un bloque rígido. Evita penetraciones y comprueba las variantes de Garon utilizadas.
REGLAS DE HÉROES

* Solo Lya invoca.
* Garon usa armas dobles, sin magia; el par tiene un único bloque de estadísticas y pasivas.
* Kael utiliza Ataque rúnico y pierde Magia e Invocación en menús, atajos y permisos de ejecución.
* Nix utiliza magia negra y no invoca.

Conserva partidas antiguas y adapta sus referencias sin perder progreso. Respeta la formación máxima existente.
PAQUETE DE PRODUCCIÓN
Desarrolla por pilotos y lotes verificables las 90 habilidades, diez enemigos comunes, cuatro criaturas FBX y 32 conjuntos equipables especificados.
Son especificaciones, no implementaciones terminadas. Diferencia common_e01…common_e10 de meshy_e01…meshy_e04.
Completa modelo, rig, animación, mecánica, integración y pruebas antes de declarar terminado cada elemento.
ÉREBO EXPERIMENTAL
Traslada el prototipo de partículas nativas del laboratorio:

* Conserva íntegra la invocación original.
* Opción experimental de Auditoría, apagada por defecto.
* Espiral sincronizada con el agarre del orbe.
* Partículas violetas, negras y plateadas, absorción y onda al contacto.
* Sin tapar protagonistas ni alterar daño o reglas.
* Comparación activado/desactivado en el mismo combate.
* Pruebas de sincronización, estabilidad, repetición y rendimiento.

No instales Pixelpart, Terrain3D ni otros complementos externos.
Autorizo subir únicamente esta integración comprobada, sus pruebas y documentación a claude/rebelum-v12, con recuperación previa. Sin force push ni merge con main. El resto queda local salvo autorización expresa vigente.
RENDIMIENTO Y VALIDACIÓN
Mantén las matas recortadas del Gran Bosque apagadas. No actives globalmente los mipmaps hasta confirmar resultados y estabilidad visual.
Esta noche prepara las pruebas y la APK de Auditoría si es posible; no instales ni manipules datos del teléfono.
Por la mañana verifica expresamente:

* Protagonistas v2 y v3 de pie durante el reposo.
* NPC de Oakhaven sin bloquear a Kael.
* Érebo, Nix, capa de Garon y nuevos efectos en el dispositivo real.

Separa resultados de PC y Android. No declares pruebas que no hayas ejecutado.
ENTREGA
Entrega archivos reales, commits, recuperación, pruebas, capturas, métricas y pendientes. Mantén una matriz de lo diseñado, modelado, rigueado, animado, integrado y validado.
Guarda continuidad antes de agotar contexto o capacidad. No prometas seguir trabajando automáticamente con la sesión cerrada.
Empieza a ejecutar tras inspeccionar; no te quedes únicamente en el plan.
