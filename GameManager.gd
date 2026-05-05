extends Node

var score: int = 0
var completed_steps: Array = []

func complete_step(step_number: int):
	if step_number not in completed_steps:
		completed_steps.append(step_number)
		score += 100
