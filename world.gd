extends Node3D

# Set world variables; get the gravity from the project settings to be synced with RigidBody nodes:
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var dragBase = 0.10
var dragAir = 0.01

# Declare namespaces for tiles and preload: 
var tileCorner := preload("res://tiles/tile_corner.tscn")
var tileDeadEnd := preload("res://tiles/tile_deadend.tscn")
var tileFloor := preload("res://tiles/tile_floor.tscn")
var tileStairsDown := preload("res://tiles/tile_stairsdown.tscn")
var tileStairsUp := preload("res://tiles/tile_stairsup.tscn")
var tileTunnel := preload("res://tiles/tile_tunnel.tscn")
var tileWall := preload("res://tiles/tile_wall.tscn")

# Declare namespaces for enemies and preload:
var crelid := preload("res://crelid.tscn")

@export var numCreeps = 1
@export var corridorBuilders = 6												# number of builders to spawn
@export var buildLife= 100														# lifetime of each builder
@export var corridorC = 50.0													# variable to tune the probability curve for turns: higher c = longer halls
@export var tileRows = 51														# map dimension, in tiles
@export var tileCols = 51														# map dimension, in tiles
var tileDim = 8																	# standard size of each tile (in godot units)
var centerRow = floor(tileRows/2.0)												# index of center tile
var centerCol = floor(tileCols/2.0)												# index of center tile
var tileMap: Array 																# array in which map will be drawn
var tileList: Array
var spawners: Array

# Checks whether cell North of provided coords is part of the dungeon:
func _neighborN(row, col) -> bool:
	if row != 0 and tileMap[row-1][col] == "O":
		return true
	return false

# Checks whether cell East of provided coords is part of the dungeon:	
func _neighborE(row, col) -> bool:
	if col != tileCols - 1 and tileMap[row][col+1] == "O":
		return true
	return false

# Checks whether cell South of provided coords is part of the dungeon:
func _neighborS(row, col) -> bool:
	if row != tileRows - 1 and (tileMap[row+1][col] == "O" or tileMap[row+1][col] == "^"):
		return true
	return false

# Checks whether cell West of provided coords is part of the dungeon:
func _neighborW(row, col) -> bool:
	if col != 0 and tileMap[row][col-1] == "O":
		return true
	return false

# Draws the ASCII dungeon map in tileMap array:
func _drawMap():
	# First, fill the empty map with blank spaces:
	for i in tileRows:
		tileMap.append([])
		for j in tileCols:
			tileMap[i].append("_")

	# Place the starting staircase and surround with dungeon:
	tileMap[centerRow-1][centerCol-1] = "O"
	tileMap[centerRow-1][centerCol] = "O"
	tileMap[centerRow-1][centerCol+1] = "O"
	tileMap[centerRow][centerCol-1] = "O"
	tileMap[centerRow][centerCol] = "^"
	tileMap[centerRow][centerCol+1] = "O"
	tileMap[centerRow+1][centerCol-1] = "O"
	tileMap[centerRow+1][centerCol] = "O"
	tileMap[centerRow+1][centerCol+1] = "O"
	
	# For each builder, draw a line of dungeon tiles out from the starting landing:
	for n in corridorBuilders:
		var lifeTime = buildLife
		var i = centerRow - 1
		var j = centerCol
		var deltaI = 0
		var deltaJ = 0
		var nextI = i
		var nextJ = j
		#var c = 
		var sinceLastTurn = 0.0
		var turnRand = 0.0
		
		# Draw new tiles until the builder's "lifetime" is used up:
		while lifeTime > 0:
			if tileMap[i][j] == "_":
				tileMap[i][j] = "O"
				lifeTime -= 1
				sinceLastTurn += 1
				nextI = i + deltaI
				nextJ = j + deltaJ
			
			turnRand = randf()
			# Turn builder if a map edge is reached--or randomly, based on length since last turn:
			while (nextI == i and nextJ == j) or nextI < 0 or nextI >= tileRows or nextJ < 0 or nextJ >= tileCols or turnRand < sinceLastTurn / (sinceLastTurn + corridorC):
				turnRand = randf()
				sinceLastTurn = 0
				# Choose a new random direction:
				match randi_range(0,3):
					0:
						deltaI = 0
						deltaJ = 1
					1:
						deltaI = -1
						deltaJ = 0
					2:
						deltaI = 0
						deltaJ = -1
					3:
						deltaI = 1
						deltaJ = 0
				nextI = i + deltaI
				nextJ = j + deltaJ
			
			i = nextI
			j = nextJ

	for i in tileRows:
		print(" ".join(tileMap[i]))

# Builds the dungeon by spawning and placing tiles based on the drawn map:
func _buildDungeon():
	#var tileList = []
	var xMax = tileDim * centerCol
	var zMax = tileDim * centerRow
	
	for i in tileRows:
		for j in tileCols:
			var neighbors = [_neighborE(i,j), _neighborN(i,j), _neighborW(i,j), _neighborS(i,j)]
			var placeX = xMax - tileDim * j
			var placeZ = zMax - tileDim * i
			var spawnAt = Vector3(placeX, 0.0, placeZ)
			if tileMap[i][j] == "^":
				tileList.append(tileStairsUp.instantiate())
				add_child(tileList.back())
				tileList.back().position = Vector3(placeX, 0.0, placeZ)
			elif tileMap[i][j] == "O":
				match neighbors:
					[false, false, false, false]:
						pass
					[false, false, false, true]:
						tileList.append(tileDeadEnd.instantiate())
						tileList.back().basis.x = tileList.back().basis.x.rotated(Vector3.UP, PI)
						tileList.back().basis.z = tileList.back().basis.z.rotated(Vector3.UP, PI)
						add_child(tileList.back())
						tileList.back().position = spawnAt
						spawners.append(tileList.back().get_child(5))
						tileList.back().get_child(5).position = spawnAt
					[false, false, true, false]:
						tileList.append(tileDeadEnd.instantiate())
						tileList.back().basis.x = tileList.back().basis.x.rotated(Vector3.UP, PI/2.0)
						tileList.back().basis.z = tileList.back().basis.z.rotated(Vector3.UP, PI/2.0)
						add_child(tileList.back())
						tileList.back().position = spawnAt
						spawners.append(tileList.back().get_child(5))
						tileList.back().get_child(5).position = spawnAt
					[false, false, true, true]:
						tileList.append(tileCorner.instantiate())
						tileList.back().basis.x = tileList.back().basis.x.rotated(Vector3.UP, PI/2.0)
						tileList.back().basis.z = tileList.back().basis.z.rotated(Vector3.UP, PI/2.0)
						add_child(tileList.back())
						tileList.back().position = spawnAt
					[false, true, false, false]:
						tileList.append(tileDeadEnd.instantiate())
						add_child(tileList.back())
						tileList.back().position = spawnAt
						spawners.append(tileList.back().get_child(5))
						tileList.back().get_child(5).position = spawnAt
					[false, true, false, true]:
						tileList.append(tileTunnel.instantiate())
						add_child(tileList.back())
						tileList.back().position = spawnAt
					[false, true, true, false]:
						tileList.append(tileCorner.instantiate())
						add_child(tileList.back())
						tileList.back().position = spawnAt
					[false, true, true, true]:
						tileList.append(tileWall.instantiate())
						tileList.back().basis.x = tileList.back().basis.x.rotated(Vector3.UP, PI/2.0)
						tileList.back().basis.z = tileList.back().basis.z.rotated(Vector3.UP, PI/2.0)
						add_child(tileList.back())
						tileList.back().position = spawnAt
					[true, false, false, false]:
						tileList.append(tileDeadEnd.instantiate())
						tileList.back().basis.x = tileList.back().basis.x.rotated(Vector3.UP, -PI/2.0)
						tileList.back().basis.z = tileList.back().basis.z.rotated(Vector3.UP, -PI/2.0)
						add_child(tileList.back())
						tileList.back().position = spawnAt
						spawners.append(tileList.back().get_child(5))
						tileList.back().get_child(5).position = spawnAt
					[true, false, false, true]:
						tileList.append(tileCorner.instantiate())
						tileList.back().basis.x = tileList.back().basis.x.rotated(Vector3.UP, PI)
						tileList.back().basis.z = tileList.back().basis.z.rotated(Vector3.UP, PI)
						add_child(tileList.back())
						tileList.back().position = spawnAt
					[true, false, true, false]:
						tileList.append(tileTunnel.instantiate())
						tileList.back().basis.x = tileList.back().basis.x.rotated(Vector3.UP, PI/2.0)
						tileList.back().basis.z = tileList.back().basis.z.rotated(Vector3.UP, PI/2.0)
						add_child(tileList.back())
						tileList.back().position = spawnAt
					[true, false, true, true]:
						tileList.append(tileWall.instantiate())
						tileList.back().basis.x = tileList.back().basis.x.rotated(Vector3.UP, PI)
						tileList.back().basis.z = tileList.back().basis.z.rotated(Vector3.UP, PI)
						add_child(tileList.back())
						tileList.back().position = spawnAt
					[true, true, false, false]:
						tileList.append(tileCorner.instantiate())
						tileList.back().basis.x = tileList.back().basis.x.rotated(Vector3.UP, -PI/2.0)
						tileList.back().basis.z = tileList.back().basis.z.rotated(Vector3.UP, -PI/2.0)
						add_child(tileList.back())
						tileList.back().position = spawnAt
					[true, true, false, true]:
						tileList.append(tileWall.instantiate())
						tileList.back().basis.x = tileList.back().basis.x.rotated(Vector3.UP, -PI/2.0)
						tileList.back().basis.z = tileList.back().basis.z.rotated(Vector3.UP, -PI/2.0)
						add_child(tileList.back())
						tileList.back().position = spawnAt
					[true, true, true, false]:
						if i < tileRows - 1 and tileMap[i+1][j] == "^":
							tileList.append(tileFloor.instantiate())
						else:
							tileList.append(tileWall.instantiate())
						add_child(tileList.back())
						tileList.back().position = spawnAt
					[true, true, true, true]:
						tileList.append(tileFloor.instantiate())
						add_child(tileList.back())
						tileList.back().position = spawnAt


# Called when the node enters the scene tree for the first time.
func _ready():
	_drawMap()
	_buildDungeon()
	for i in numCreeps:
		var spawn = spawners[randi() % spawners.size()]
		var creep = crelid.instantiate()
		add_child(creep)
		creep.position = spawn.position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

