class_name Companion extends CharacterBody2D

const SPEED = 300.0

enum State { IDLE, WALKING_TO_ITEM, WALKING_WITH_ITEM, WAITING }
var state : State = State.IDLE
#store target
#if no target -> use policy predictor

func init(num_targets : int, player : Node2D):
	pass

func _process_next():
	pass
