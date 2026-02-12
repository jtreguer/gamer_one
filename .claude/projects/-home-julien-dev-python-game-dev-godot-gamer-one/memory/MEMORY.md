# Memory

## GDScript Gotchas
- `Color("#hex")` is NOT a valid compile-time constant in GDScript `const` declarations. Use `Color(r, g, b)` with float literals instead. The string constructor requires runtime parsing.
- `@export` default values cannot reference constants from other classes (e.g. `@export var c: Color = MyClass.MY_CONST`). Use inline literals for @export defaults. Class constants work fine in runtime code (_draw, _process, etc.).
