extends Node

@onready var animation_tree: AnimationTree = $AnimationTree

@onready var move_state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")


func set_move_state(state_name: String) -> void:
	move_state_machine.travel(state_name)
