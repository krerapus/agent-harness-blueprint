# ANTI-PATTERNS.md

High-confidence operational safety memory. Keep entries concise and actionable.

## Destructive Operations Without Confirmation
- Do not run destructive filesystem, Git, database, infrastructure, or credential operations without explicit user confirmation.
- Examples include `rm -rf`, force push, hard reset, production migrations, irreversible SQL, infrastructure deletion, credential rotation, and mass refactors with unclear blast radius.

## Memory Layer Pollution
- Do not store reflections, lessons, or generalized knowledge in `RUN_LOG.md`; it is telemetry only.
- Do not append endlessly to `HOTCACHE.md`; replace stale operational state.
- Do not promote every `LEARNING.md` observation into a skill or rule without human consolidation.

## Blind Automation
- Do not execute commit/push/merge playbooks against protected branches without explicit confirmation.
- Do not treat forge-specific tokens or CLI installs as always available; run `agent doctor` or equivalent checks first.
