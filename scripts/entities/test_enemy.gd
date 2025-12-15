extends CharacterBody2D

enum EnemyState {
	IDLE,
	PATROL,
	CHANNELING,
	ATTACK
}

@export var enemy_state : EnemyState

const SPEED = 200.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		print(get_gravity())
		velocity.y += get_gravity().y * delta
	
	move_and_slide()
	match enemy_state:
		EnemyState.IDLE:
			velocity.x = 0.0
		EnemyState.PATROL:
			patrol()
		EnemyState.CHANNELING:
			pass
		EnemyState.ATTACK:
			pass
			
func patrol():
	if not is_on_wall():
		velocity.x = SPEED
	else:
		velocity.x = velocity.x * -1
