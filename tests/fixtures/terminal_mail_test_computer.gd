extends StudioComputerUI
## Exercise terminal actions without changing scenes or the player's save.
var opened_cases: Array[String] = []

func _start_case(case_id: String) -> void:
	opened_cases.append(case_id)
