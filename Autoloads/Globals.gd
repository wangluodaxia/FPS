extends Node


@onready var game = get_tree().current_scene

var mouse_sensitivity := 0.002
var controller_sensitivity := 0.05
var zoom_sensitibity := 1.0
var invert_y_axis := false

enum WEAPONS { SLAPPER, PISTOL, SMG, RIFLE, SHOTGUN, SNIPER, GRENADE }
var weapons = [ load("res://Props/Weapons/Slapper/Slapper.tscn"),
				load("res://Props/Weapons/Pistol/Pistol.tscn"),
				load("res://Props/Weapons/SMG/SMG.tscn"),
				load("res://Props/Weapons/Rifle/Rifle.tscn"),
				load("res://Props/Weapons/Shotgun/Shotgun.tscn"),
				load("res://Props/Weapons/Sniper/Sniper.tscn")]
var WEAPON_NAMES = [ "Slapper", "Pistol", "SMG", "Rifle", "Shotgun", "Sniper", \
																	"Grenade" ]

enum PICK_UPS { WEAPON, AMMO, HEALTH }
enum HEALTHS { HEALTH_PACK, ARMOR }

enum BODY_SEGS { HEAD, TORSO, LIMB }


func invert_y_to_int() -> int:
	return (int(invert_y_axis) * 2) - 1
