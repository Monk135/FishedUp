extends Node2D

func _ready():
	Wwise.register_game_obj(self, self.name)
	Wwise.set_2d_position(self, get_global_transform())
	Wwise.post_event_id(AK.Events.Music_Start, self)
	
