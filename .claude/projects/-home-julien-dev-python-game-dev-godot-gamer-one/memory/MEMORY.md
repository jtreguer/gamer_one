# Memory

## GDScript Gotchas
- `Color("#hex")` is NOT a valid compile-time constant in GDScript `const` declarations. Use `Color(r, g, b)` with float literals instead.
- `class_name` + `const` pattern is broken in Godot 4.6: other scripts cannot access constants from a class defined via `class_name` (e.g. `ColorPalette.MY_CONST` fails with "Cannot find member"). Affects both `@export` defaults AND runtime code. Workaround: inline all values directly. Keep palette file as reference only.
- When using the pattern `add_child(node)` then `node.setup(...)`, do NOT put initialization logic in `_ready()` that depends on setup params. `_ready()` fires during `add_child()` before `setup()` runs. Move all param-dependent init into `setup()` and access child nodes via `$Path` instead of `@onready`.
