extends CharacterBody2D

var health: int = 3

func take_damage(amount):

	health -= amount
	print("Zombie hit! HP:", health)

	if health <= 0:
		die()

func die():
	print("Zombie dead")
	queue_free()
