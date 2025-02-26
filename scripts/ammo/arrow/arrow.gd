extends Ammo


func _ready() -> void:
	dead()

func _on_area_entered(area: Hurtbox) -> void:
	area.take_damage(damage_type ,damage, knockback_direction, knockback_force)
	queue_free()

func _on_body_entered(body: TileMapLayer) -> void:
	fly_speed = 0
	body.add_child(self)
	collision_shape_2d.queue_free()
