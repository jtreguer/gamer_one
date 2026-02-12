class_name MathUtils
extends RefCounted

## Check if a line segment from [param line_start] to [param line_end]
## intersects a circle at [param circle_center] with [param circle_radius].
static func line_intersects_circle(
	line_start: Vector2,
	line_end: Vector2,
	circle_center: Vector2,
	circle_radius: float
) -> bool:
	var d: Vector2 = line_end - line_start
	var f: Vector2 = line_start - circle_center

	var a: float = d.dot(d)
	var b: float = 2.0 * f.dot(d)
	var c: float = f.dot(f) - circle_radius * circle_radius

	var discriminant: float = b * b - 4.0 * a * c
	if discriminant < 0.0:
		return false

	discriminant = sqrt(discriminant)
	var t1: float = (-b - discriminant) / (2.0 * a)
	var t2: float = (-b + discriminant) / (2.0 * a)

	return (t1 >= 0.0 and t1 <= 1.0) or (t2 >= 0.0 and t2 <= 1.0)


## Return the shortest angular difference between two angles (handles wrap-around).
static func angle_diff(a: float, b: float) -> float:
	var diff: float = fmod(b - a + PI, TAU) - PI
	return absf(diff)


## Convert an angle to a point on a circle circumference.
static func angle_to_point(center: Vector2, radius: float, angle: float) -> Vector2:
	return center + Vector2(cos(angle), sin(angle)) * radius
