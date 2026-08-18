# AGENTS.md — Reglas operativas para Codex/ChatGPT

## Lectura obligatoria
1. `docs/ssot/PROJECT_TRUTH.md`
2. `docs/ssot/FUNCTIONAL_SPEC.md`
3. `docs/ssot/METROLOGY_RULES.md`
4. `docs/ssot/DATA_MODEL.md`
5. `docs/ssot/API_CONTRACT.md`
6. `docs/ssot/SYNC_SPEC.md`
7. ADRs aplicables.

## Reglas
- `docs/ssot/` prevalece sobre prototipo/código previo.
- El prototipo legado es referencia funcional/visual, **no autoridad cuando contradice v9**.
- No rediseñar libremente UI; usar capturas.
- No integrar el simulador web a Flutter. **No eliminar LECTURA VISUAL**: es funcionalidad productiva para medidores reales y debe migrarse desde la lógica visual representada por el prototipo.
- No inventar endpoints de la API de hidrantes; inspeccionarla y consumirla read-only.
- Muestras cerradas son inmutables.
- Lógica metrológica fuera de widgets y cubierta por tests.
- Cambios de comportamiento/modelo/API requieren SSOT + CHANGELOG; decisiones relevantes requieren ADR.

## Calidad
- Flutter: `dart format`, `flutter analyze`, tests; sin lógica de negocio en widgets.
- Node: TypeScript strict, validación de inputs, sin `any` injustificado, tests.
- Código/identificadores en inglés; UI/documentación de producto en español.
- Todo cambio que modifique un procedimiento visible para el técnico debe revisar y, cuando corresponda, actualizar `app/assets/manual/manual_de_uso.md` en el mismo cambio.
