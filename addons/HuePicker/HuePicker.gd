tool
extends Control

signal color_changed(color)
signal Hue_Selected(color)

export(Color) var color : Color setget color_changed

onready var hue_circle = $HueCircle
onready var indicator_bg = $HueCircle/indicator_rgba/bg
onready var indicator = $HueCircle/indicator_rgba
onready var circle_rect = $HueCircle/indicator_rgba/ColorRect
onready var indicator_h  = $HueCircle/indicator_h

var isReady : bool = false


func _ready() -> void:
#	print ("Setting up HuePicker.. %s" % color)
	if color == null:
		color = ColorN('white')
	isReady = true
	

	yield(get_tree(),'idle_frame')
	hue_circle.set_hue(color.h)
	hue_circle.reposition_hue_indicator()
	reposition_hue_indicator()
	_on_HuePicker_color_changed(color)

	set_meta("_editor_icon", preload("res://addons/HuePicker/icon.png"))

func color_changed(value : Color) -> void:
	color = value
	
	#TODO: This line is so we know to update the hue spinner if a property
	#is set from within the Godot editor. Will cause problems for downstream
	#Plugins, so try to figure out a way to determine that we're SPECIFICALLY
	#editing this property from the Inspector, somehow.  Hack!!!
	if Engine.editor_hint == true and $Hue_Circle != null: 
		hue_circle.set_hue(value.h)
	
	emit_signal('color_changed', value)
	
func reposition_hue_indicator() -> void:
	
	var midR = min(hue_circle.rect_size.x, hue_circle.rect_size.y) * 0.45
	var ihx  = midR*cos(hue_circle.saved_h * 2*PI) + hue_circle.rect_size.x/2 - indicator_h.rect_size.x/2
	var ihy  = midR*sin(hue_circle.saved_h * 2*PI) + hue_circle.rect_size.y/2 - indicator_h.rect_size.y/2

	hue_circle.reposition_hue_indicator()

	hue_circle.get_node("indicator_h").set_rotation(hue_circle.saved_h * 2*PI + PI/2)
	indicator_h.rect_position = Vector2(ihx,ihy)

func _on_HuePicker_resized() -> void:
	var short_edge = min(rect_size.x, rect_size.y)
	var chunk = Vector2(short_edge,short_edge)
	
	indicator.rect_size = chunk / 8
	indicator_bg.position = chunk / 16
	indicator_bg.scale = chunk / 256
	indicator.rect_position.x = rect_size.x/2 - short_edge/2
	indicator.rect_position.y = rect_size.y/2 + short_edge/2 - indicator.rect_size.y
	
	
	reposition_hue_indicator()

#Color change handler.
func _on_HuePicker_color_changed(color : Color) -> int:
	if isReady == false or color == null:  
		print("HuePicker:  Warning, attempting to change color before control is ready")
		return  -1

	circle_rect.color = color
	hue_circle.get_node("ColorRect/SatVal").material.set_shader_param("hue", hue_circle.saved_h)
	reposition_hue_indicator()
	#Reposition SatVal indicator
	hue_circle.get_node("ColorRect/indicator_sv").position = Vector2(color.s, 1-color.v) * hue_circle.get_node("ColorRect").rect_size
	emit_signal("Hue_Selected", color)
	return 0

#For the Popup color picker.
func _on_ColorPicker_color_changed(color : Color) -> void:
	#	#Prevent from accidentally resetting the internal hue if color's out of range
	var c = Color(color.r, color.g, color.b, 1)
	if c != ColorN('black', 1) and c != ColorN('white', 1) and c.s !=0:
		hue_circle.set_hue(self.color.h)

	self.color = color
	hue_circle.reposition_hue_indicator()
