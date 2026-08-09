# ADR-002 — Conteo de vueltas de la aguja en el endpoint

- **Estado:** aceptada
- **Fecha:** 2026-08-08
- **Contexto:** la aguja ×0.01 m³ abarca 100 L por vuelta; las pruebas son 100–300 L (1–3 vueltas). En el prototipo, el cálculo del endpoint hacía `odómetro·1000 + aguja` sin contar vueltas, por lo que un avance de 200 L (2 vueltas exactas, misma posición de aguja) podía calcularse como 0 L. **La lectura automática de la aguja es confiable**; el defecto no era el reconocimiento sino la pérdida de vueltas.
- **Decisión:** el endpoint reconstruye el avance contando vueltas:
  `adv0 = (odoFinal−odoInicial)·1000 + (agujaFinal−agujaInicial); k = round((V_ref − adv0)/100); V_ind = adv0 + 100·k`.
  Alternativa preferida en la app nueva: capturar la **lectura completa en litros** de la foto (aguja auto como sugerencia editable), que hace innecesario el conteo. Ambos deben dar el mismo `V_ind`.
- **Alternativas:** confiar solo en la aguja (descartada: pierde vueltas); exigir odómetro con decimales (depende del medidor, dato por confirmar).
- **Consecuencias:** el resultado deja de depender de que la prueba sea < 100 L. Un sesgo constante de aguja sigue cancelándose en la diferencia. Cubrir con tests (caso 200 L exactos).
