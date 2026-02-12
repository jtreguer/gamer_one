class_name GameConfig
extends Resource

# --- 7.1 Planet & World ---
@export var planet_radius: float = 80.0
@export var initial_silo_count: int = 6
@export var rotation_speed: float = 0.15
@export var silo_hit_tolerance: float = 15.0
@export var silo_target_ratio: float = 0.6

# --- 7.2 Interceptor Missiles ---
@export var interceptor_speed: float = 400.0
@export var blast_radius: float = 40.0
@export var blast_expand_time: float = 0.3
@export var blast_hold_time: float = 0.2
@export var blast_fade_time: float = 0.2
@export var silo_reload_time: float = 1.5

# --- 7.3 Enemy Missiles ---
@export var enemy_speed_min_base: float = 80.0
@export var enemy_speed_max_base: float = 120.0
@export var enemy_speed_escalation: float = 8.0
@export var enemy_speed_max_escalation: float = 12.0
@export var enemy_speed_cap: float = 300.0
@export var initial_enemy_count: int = 6
@export var enemy_count_escalation: int = 2
@export var enemy_count_cap: int = 60
@export var spawn_margin: float = 20.0
@export var trail_lifetime: float = 5.0

# --- 7.4 MIRV ---
@export var mirv_start_wave: int = 5
@export var mirv_base_chance: float = 0.15
@export var mirv_chance_per_wave: float = 0.03
@export var mirv_chance_cap: float = 0.55
@export var mirv_split_dist_min: float = 150.0
@export var mirv_split_dist_max: float = 250.0
@export var mirv_min_warheads: int = 2
@export var mirv_max_warheads: int = 4
@export var mirv_warhead_spread: float = 0.52

# --- 7.5 Scoring & Upgrades ---
@export var points_enemy_kill: int = 100
@export var points_mirv_presplit: int = 250
@export var points_warhead_kill: int = 75
@export var wave_clear_bonus: int = 500
@export var silo_survival_bonus: int = 200
@export var accuracy_bonus_threshold: float = 0.8
@export var accuracy_bonus: int = 300
@export var silo_repair_cost_mult: int = 5000

# --- 7.6 Wave Timing ---
@export var wave_start_delay: float = 1.5
@export var burst_interval: float = 2.0
@export var spawn_interval: float = 0.3
