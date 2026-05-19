extends Node3D

# 1. 定義 Enum，方便在代碼與 Inspector 中閱讀
enum PlayerType {
	TUTORIAL,
	NO_IK,
	LEG_IK,
	FOOT_ROTATION
}

# 2. 建立對照表 (Dictionary)，將 Enum 對應到實際的 tscn 路徑
const PLAYER_PATHS = {
	PlayerType.NO_IK: "res://main/player/player_no_ik/player.tscn",
	PlayerType.LEG_IK: "res://main/player/player_leg_ik/player_leg_ik.tscn",
	PlayerType.FOOT_ROTATION: "res://main/player/player_foot_rotation/player_foot_rotation.tscn",
	PlayerType.TUTORIAL: "res://main/player/player_for_tutorial/player_for_tutorial.tscn"
}

# 3. 導出變數到 Inspector，讓你可以用下拉選單選擇
@export var current_player_type: PlayerType = PlayerType.TUTORIAL

# 4. 或者是設定一個生成位置（非必要，但建議在 Main 裡放一個 Marker3D 當出生點）
@export var spawn_point: Marker3D

var current_player_instance: Node3D = null

func _ready() -> void:
	spawn_player(current_player_type)


# 主生成函數
func spawn_player(type: PlayerType) -> void:
	# 如果場上已經有舊的角色，先清除掉（方便之後做運行中切換）
	if is_instance_valid(current_player_instance):
		current_player_instance.queue_free()
	
	# 取得對應的路徑
	var path = PLAYER_PATHS[type]
	
	# 載入並實例化 tscn
	var player_scene = load(path)
	if player_scene:
		current_player_instance = player_scene.instantiate() as Node3D
		
		# 將角色加進場景樹
		add_child(current_player_instance)
		
		# 設定初始位置
		if spawn_point:
			current_player_instance.global_position = spawn_point.global_position
		else:
			current_player_instance.global_position = Vector3.ZERO
			
		print("Spawning player: ", PlayerType.keys()[type])
	else:
		push_error("Not able to spawn: " + path)
