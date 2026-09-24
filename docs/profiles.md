# Blueprint profiles

Profiles (also called blueprints) are the TUI choices when you run `blueprint install`. They share the same core harness and differ by **extra commands, skills, and templates**.

Canonical pack copy: [`assets-blueprint/docs/profiles.md`](https://github.com/krerapus/assets-blueprint/blob/master/docs/profiles.md).

```text
default
├── engineering  (+ optional --overlay gitlab)
└── product
```

| Profile | Best for | Extra vs `default` |
|---|---|---|
| **`default`** | Any repo / general use | `/start`, `/review`, safety + task-execution, memory templates, base skills |
| **`engineering`** | Day-to-day coding | `/commit`, `refactor-code`, review prompt, ADR; optional GitLab overlay |
| **`product`** | Early product / discovery | PRD + ADR templates (renamed from `startup`; alias still works) |

## Switch after install

```bash
blueprint switch product --target /path/to/repo
blueprint switch engineering --overlay gitlab --target /path/to/repo
```

Or in the interactive menu: **7) switch**. Runtimes and skill-mode come from `.agent-blueprint.yaml` unless you pass flags. `sync` / `update` keep the current profile.
