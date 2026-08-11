# Stage 4.2 — Notas de calibración visual

Se preserva una fotografía por Evidence y START → INTERMEDIATE según `ExpectedEvidencePlan` → FINAL. No se agregan pasos productivos ni se modifica Stage 1/2, DB, contratos o checksum.

## Cambios

- Pantalla `Calibración visual · DEBUG`, solo bajo `kDebugMode`, que usa cámara y pipeline productivos, acepta valores reales y emite JSON diagnóstico.
- Candidatos OCR y conteo de píxeles rojos en la propuesta, sin persistir derivados ni alterar Evidence.
- Crop de dial cuadrado en píxeles desde geometría relativa.
- Centro físico refinado localmente; mapping metrológico independiente; wrap ±2°.
- OCR derivado conserva color; ROI debug ceñido; original intacto.
- El parser ya no auto-selecciona candidatos ambiguos.
- Regresiones para crop cuadrado, dial descentrado/no cuadrado y ambigüedad OCR.

Se evaluó y rechazó PCA al demostrar físicamente sesgo por estructuras rojas. No se implementó perspectiva ni OpenCV porque el corpus frontal no lo justificó. No se implementó Stage 5.
