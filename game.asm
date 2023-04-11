#####################################################################
#
# CSCB58 Winter 2023 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Cheng Liang Huang, 1006480942, huan1996, williamc.huang@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 512
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 3
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. Health/score [2 marks]: Score in top left corner, health in top right
# 2. Fail condition [1 mark]: Levels can be failed if 0 hearts are reached.
# 3. Win condition [1 mark]: Player must complete all levels to win
# 4. Moving objects [2 marks]: Enemies patrol platforms and pickups hover.
# 5. Moving platforms [2 marks]: Some levels have moving platforms.
# 6. Different levels [2 marks]: The game has 3 levels total.
# 7. Pick-up effects [2 marks]: Coins, healthpack, umbrella, shield pickups.
# Link to video demonstration for final submission:
# https://youtu.be/CqhiZQwJpb0
# Are you OK with us sharing the video with people outside course staff?
# yes, and please share this project github link as well!
# https://github.com/What-Is-A-Username/grass-hopping
# Any additional information that the TA needs to know:
# 
#
#####################################################################

# Bitmap display starter code
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 512
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)

# Register allocation
# $s0 = screen state
# $s1 = player coord x
# $s2 = player coord y
# $s3 = player health
# $s4 = player points	
# $s5 = number of enemies active in level
# $s6 = number of pickups active in level
# $s7 = number of platforms active in level

.data 
enemies: 	.space 800  		# store data of hostile entities to player active in the present level
platforms: 	.space 1200  		# store data of platforms active in the level (12 bytes each)
pickups: 	.space 600 			# store data of pickups active in the level
velocity:	.word 0				# current vertical upward speed of player
spawn_locs_x: .word 1, 1, 55 	# spawn locations x-coords of levels 1, 2, 3, etc.
spawn_locs_y: .word 50, 35, 50 	# spawn locations y-coords
currentLevel: .word 0			# The number of the current level. 0 = first level
currentTick: .word 0			# current physics tick 
playerDirection: .byte 0 		# direction player is facing. 0 = right, 1 = forward, 2 left
spacer: 	.space 36000		# spacer padding to accommodate larger bitmap sizes
lessGravity: .word 0			# number of ticks of reduced gravity remaining
invincibility: .word 0			# number of ticks of invincibility remaining
pointsAtStart: .word 0, 0, 0	# points earned at the start of each level

# Player dir enum
.eqv 	PLAYER_DIR_RIGHT, 0		# enum value for playerDirection = player facing right
.eqv 	PLAYER_DIR_FRONT, 1		# enum value for playerDirection = player facing towards screen
.eqv 	PLAYER_DIR_LEFT, 2		# enum value for playerDirection = player facing left

# Struct sizes
.eqv 	PLATFORM_STRUCT_SIZE,  12 	# size of used to store platform info, in bytes
.eqv 	PICKUP_STRUCT_SIZE, 6 		# size of struct used to store pickup info, in bytes
.eqv 	ENEMY_STRUCT_SIZE, 8		# size of struct used to store enemy info, in bytes

# Gameplay
.eqv 	SLEEP_DURATION, 40			# time, in milliseconds, to sleep (40ms recommended)
.eqv 	JUMP_ACCEL, 15				# Initial jump acceleration
.eqv 	JUMP_DECEL, 12				# Amount of jump deceleration towards zero
.eqv 	POINTS_PER_ENEMY, 1	 		# The number of points given for enemy kills
.eqv 	POINTS_PER_COIN, 1			# The number of points given for each coin
.eqv 	HEALTH_PER_PACK, 1 			# The number of health points given for each health pack
.eqv	INVINCIBILITY_TICKS_PER_PACK, 500 # The number of ticks of invincibility granted for each invincibility pack
.eqv 	LESS_GRAVITY_TICKS_PER_PACK, 250	# The number of ticks of less gravity granted for each less gravity pack

.eqv 	PICKUP_TYPE_COIN, 1			# Value indicating a coin
.eqv 	PICKUP_TYPE_HEALTH, 2		# Value indicating a healthpack
.eqv 	PICKUP_TYPE_INVINCIBILITY, 3	# Value indicating invincibility effect
.eqv 	PICKUP_TYPE_LESS_GRAVITY, 4	# Value indicating less gravity effect
.eqv 	PICKUP_TYPE_INACTIVE, 11 	# Value indcating that pickup is no longer used

# Physics Update
.eqv 	ENEMY_MOVEMENT_TICK_DELAY, 5		# The number of ticks between enemy movement calculations; must be faster than platform tick delay
.eqv 	PLATFORM_MOVEMENT_TICK_DELAY, 10	# The number of ticks between platform movement calculations
.eqv 	GRAVITY_TICK_WHEN_LESS_GRAVITY, 7	# The number of ticks gravity is calculated for while less gravity effect is active
.eqv 	MAX_TICK_VALUE, 10000


# Graphics 
.eqv	BASE_ADDRESS, 0x10008000	# address of first bitmap pixel
.eqv	MEM_WORD_SIZE, 4			# size of bitmap pixels
.eqv  	MEM_VERT_OFFSET, 256		# the number of bytes separating pixel x,y with pixel x+1, y. Set to width * 4
.eqv	WIDTH, 64 					# Width of screen in units
.eqv 	WIDTH_INDEX, 63 			# Index of last unit on right side 
.eqv 	HEIGHT, 64					# Height of screen in units 
.eqv 	HEIGHT_INDEX, 63			# Index of last unit on bottom side
.eqv 	PLAYER_HEIGHT, 9			# Height of player in framebuffer units
.eqv 	PLAYER_WIDTH, 7				# Width of player in framebuffer units
.eqv 	PLATFORM_THICKNESS, 5		# Thickness of platform in framebuffer units
.eqv 	PICKUP_WIDTH, 5				# Width of pickups in framebuffer units
.eqv 	PICKUP_HEIGHT, 5			# Height of pickups in framebuffer units
.eqv 	ENEMY_WIDTH, 5				# Width of enemies in framebuffer units
.eqv 	ENEMY_HEIGHT, 5				# Height of enemies in framebuffer units

.eqv 	PLATFORM_GRASS_TOP, 0x419e44
.eqv 	PLATFORM_GRASS_UNDER, 0x466321
.eqv 	PLATFORM_DIRT, 0x9c5a3c
.eqv 	PLATFORM_ROCK, 0x635652


# Colors
.eqv	PLAYER_COLOR, 0x00ff00			# Color used for player
.eqv 	PLATFORM_COLOR, 0xff00ff		# Color used for platforms
.eqv 	BACKGROUND_COLOR, 0x000000		# Color used for empty background
.eqv 	SCORE_COLOR, 0x309fab			# Color used to write score digits
.eqv 	HEALTH_COLOR, 0xff0000			# Color used to write health digits
.eqv 	COIN_COLOR_1, 0xffae00			# Color used to draw inside of coins
.eqv 	COIN_COLOR_2, 0xbd8e0b			# Color used to draw outside of coins
.eqv 	HEALTHPACK_COLOR_1, 0xe8192b	# Color 1 used to draw health pack
.eqv 	HEALTHPACK_COLOR_2, 0xfafafa 	# Color 2 used to draw health pack
.eqv 	ENEMY_BODY_COLOR, 0x22b14d		# Color of body of enemies
.eqv 	ENEMY_EYES_COLOR, 0xfc2f3a		# Color of eyes of enemies
.eqv 	ENEMY_DARK_COLOR, 0x17632a		# Color of darker shade of enemies

# Controls 
.eqv	UP_KEY, 0x77 					# W
.eqv	DOWN_KEY, 0x73 					# S
.eqv	LEFT_KEY, 0x61 					# A
.eqv	RIGHT_KEY, 0x64 				# D
.eqv    RESET_KEY, 0x70 				# P
.eqv	SPACE_KEY, 0x20 				# SPACE
.eqv	KEY_ADDRESS, 0xffff0000 	# address used to retrieve key press information

.text

.drawStartMenu:
	jal clearScreen
	li $t1, 0x17632a
	li $t2, 0xffc20e
	li $t3, 0xed1c24
	li $t4, 0x116324
	li $t5, 0x22b14c
	li $t6, 0x12732e
	li $t7, 0x464646
	li $t8, 0x9c5a3c
	li $v0, BASE_ADDRESS
	li $t0, MEM_VERT_OFFSET
	mul $t0, $t0, 7
	add $v0, $v0, $t0
	sw $t4, 60($v0)
	sw $t4, 68($v0)
	sw $t4, 192($v0)
	sw $t4, 200($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t4, 52($v0)
	sw $t4, 56($v0)
	sw $t4, 60($v0)
	sw $t4, 64($v0)
	sw $t4, 68($v0)
	sw $t4, 184($v0)
	sw $t4, 188($v0)
	sw $t4, 192($v0)
	sw $t4, 196($v0)
	sw $t4, 200($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t4, 52($v0)
	sw $t5, 56($v0)
	sw $t3, 60($v0)
	sw $t5, 64($v0)
	sw $t3, 68($v0)
	sw $t3, 184($v0)
	sw $t5, 188($v0)
	sw $t3, 192($v0)
	sw $t5, 196($v0)
	sw $t1, 200($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t4, 52($v0)
	sw $t5, 56($v0)
	sw $t5, 60($v0)
	sw $t5, 64($v0)
	sw $t5, 68($v0)
	sw $t5, 184($v0)
	sw $t5, 188($v0)
	sw $t5, 192($v0)
	sw $t5, 196($v0)
	sw $t1, 200($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t4, 56($v0)
	sw $t4, 64($v0)
	sw $t4, 188($v0)
	sw $t4, 196($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t5, 52($v0)
	sw $t5, 56($v0)
	sw $t5, 60($v0)
	sw $t5, 64($v0)
	sw $t5, 68($v0)
	sw $t5, 72($v0)
	sw $t5, 76($v0)
	sw $t5, 80($v0)
	sw $t5, 84($v0)
	sw $t5, 88($v0)
	sw $t5, 92($v0)
	sw $t5, 96($v0)
	sw $t5, 100($v0)
	sw $t5, 104($v0)
	sw $t5, 108($v0)
	sw $t5, 112($v0)
	sw $t5, 116($v0)
	sw $t5, 120($v0)
	sw $t5, 124($v0)
	sw $t5, 128($v0)
	sw $t5, 132($v0)
	sw $t5, 136($v0)
	sw $t5, 140($v0)
	sw $t5, 144($v0)
	sw $t5, 148($v0)
	sw $t5, 152($v0)
	sw $t5, 156($v0)
	sw $t5, 160($v0)
	sw $t5, 164($v0)
	sw $t5, 168($v0)
	sw $t5, 172($v0)
	sw $t5, 176($v0)
	sw $t5, 180($v0)
	sw $t5, 184($v0)
	sw $t5, 188($v0)
	sw $t5, 192($v0)
	sw $t5, 196($v0)
	sw $t5, 200($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t5, 52($v0)
	sw $t5, 56($v0)
	sw $t6, 60($v0)
	sw $t6, 64($v0)
	sw $t6, 68($v0)
	sw $t6, 72($v0)
	sw $t5, 76($v0)
	sw $t5, 80($v0)
	sw $t6, 84($v0)
	sw $t6, 88($v0)
	sw $t6, 92($v0)
	sw $t6, 96($v0)
	sw $t5, 100($v0)
	sw $t5, 104($v0)
	sw $t6, 108($v0)
	sw $t6, 112($v0)
	sw $t6, 116($v0)
	sw $t6, 120($v0)
	sw $t5, 124($v0)
	sw $t5, 128($v0)
	sw $t6, 132($v0)
	sw $t6, 136($v0)
	sw $t6, 140($v0)
	sw $t6, 144($v0)
	sw $t5, 148($v0)
	sw $t5, 152($v0)
	sw $t6, 156($v0)
	sw $t6, 160($v0)
	sw $t6, 164($v0)
	sw $t6, 168($v0)
	sw $t5, 172($v0)
	sw $t5, 176($v0)
	sw $t6, 180($v0)
	sw $t6, 184($v0)
	sw $t6, 188($v0)
	sw $t6, 192($v0)
	sw $t5, 196($v0)
	sw $t5, 200($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t6, 52($v0)
	sw $t6, 56($v0)
	sw $t8, 60($v0)
	sw $t6, 64($v0)
	sw $t8, 68($v0)
	sw $t8, 72($v0)
	sw $t6, 76($v0)
	sw $t6, 80($v0)
	sw $t8, 84($v0)
	sw $t6, 88($v0)
	sw $t8, 92($v0)
	sw $t8, 96($v0)
	sw $t6, 100($v0)
	sw $t6, 104($v0)
	sw $t8, 108($v0)
	sw $t6, 112($v0)
	sw $t8, 116($v0)
	sw $t8, 120($v0)
	sw $t6, 124($v0)
	sw $t6, 128($v0)
	sw $t8, 132($v0)
	sw $t6, 136($v0)
	sw $t8, 140($v0)
	sw $t8, 144($v0)
	sw $t6, 148($v0)
	sw $t6, 152($v0)
	sw $t8, 156($v0)
	sw $t6, 160($v0)
	sw $t8, 164($v0)
	sw $t8, 168($v0)
	sw $t6, 172($v0)
	sw $t6, 176($v0)
	sw $t8, 180($v0)
	sw $t6, 184($v0)
	sw $t8, 188($v0)
	sw $t8, 192($v0)
	sw $t6, 196($v0)
	sw $t6, 200($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t8, 52($v0)
	sw $t8, 56($v0)
	sw $t8, 60($v0)
	sw $t8, 64($v0)
	sw $t8, 68($v0)
	sw $t8, 72($v0)
	sw $t8, 76($v0)
	sw $t8, 80($v0)
	sw $t8, 84($v0)
	sw $t8, 88($v0)
	sw $t8, 92($v0)
	sw $t8, 96($v0)
	sw $t8, 100($v0)
	sw $t8, 104($v0)
	sw $t8, 108($v0)
	sw $t8, 112($v0)
	sw $t8, 116($v0)
	sw $t8, 120($v0)
	sw $t8, 124($v0)
	sw $t8, 128($v0)
	sw $t8, 132($v0)
	sw $t8, 136($v0)
	sw $t8, 140($v0)
	sw $t8, 144($v0)
	sw $t8, 148($v0)
	sw $t8, 152($v0)
	sw $t8, 156($v0)
	sw $t8, 160($v0)
	sw $t8, 164($v0)
	sw $t8, 168($v0)
	sw $t8, 172($v0)
	sw $t8, 176($v0)
	sw $t8, 180($v0)
	sw $t8, 184($v0)
	sw $t8, 188($v0)
	sw $t8, 192($v0)
	sw $t8, 196($v0)
	sw $t8, 200($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t7, 52($v0)
	sw $t7, 56($v0)
	sw $t7, 60($v0)
	sw $t7, 64($v0)
	sw $t7, 68($v0)
	sw $t7, 72($v0)
	sw $t7, 76($v0)
	sw $t7, 80($v0)
	sw $t7, 84($v0)
	sw $t7, 88($v0)
	sw $t7, 92($v0)
	sw $t7, 96($v0)
	sw $t7, 100($v0)
	sw $t7, 104($v0)
	sw $t7, 108($v0)
	sw $t7, 112($v0)
	sw $t7, 116($v0)
	sw $t7, 120($v0)
	sw $t7, 124($v0)
	sw $t7, 128($v0)
	sw $t7, 132($v0)
	sw $t7, 136($v0)
	sw $t7, 140($v0)
	sw $t7, 144($v0)
	sw $t7, 148($v0)
	sw $t7, 152($v0)
	sw $t7, 156($v0)
	sw $t7, 160($v0)
	sw $t7, 164($v0)
	sw $t7, 168($v0)
	sw $t7, 172($v0)
	sw $t7, 176($v0)
	sw $t7, 180($v0)
	sw $t7, 184($v0)
	sw $t7, 188($v0)
	sw $t7, 192($v0)
	sw $t7, 196($v0)
	sw $t7, 200($v0)
	li $t0, MEM_VERT_OFFSET
	mul $t0, $t0, 2
	add $v0, $v0, $t0
	sw $t2, 56($v0)
	sw $t2, 60($v0)
	sw $t2, 64($v0)
	sw $t2, 72($v0)
	sw $t2, 76($v0)
	sw $t2, 92($v0)
	sw $t2, 104($v0)
	sw $t2, 108($v0)
	sw $t2, 112($v0)
	sw $t2, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 56($v0)
	sw $t2, 72($v0)
	sw $t2, 80($v0)
	sw $t2, 88($v0)
	sw $t2, 96($v0)
	sw $t2, 104($v0)
	sw $t2, 120($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 56($v0)
	sw $t2, 64($v0)
	sw $t2, 72($v0)
	sw $t2, 76($v0)
	sw $t2, 88($v0)
	sw $t2, 96($v0)
	sw $t2, 108($v0)
	sw $t2, 124($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 56($v0)
	sw $t2, 64($v0)
	sw $t2, 72($v0)
	sw $t2, 80($v0)
	sw $t2, 88($v0)
	sw $t2, 92($v0)
	sw $t2, 96($v0)
	sw $t2, 112($v0)
	sw $t2, 128($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 56($v0)
	sw $t2, 64($v0)
	sw $t2, 72($v0)
	sw $t2, 80($v0)
	sw $t2, 88($v0)
	sw $t2, 96($v0)
	sw $t2, 112($v0)
	sw $t2, 128($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 56($v0)
	sw $t2, 60($v0)
	sw $t2, 64($v0)
	sw $t2, 72($v0)
	sw $t2, 80($v0)
	sw $t2, 88($v0)
	sw $t2, 96($v0)
	sw $t2, 104($v0)
	sw $t2, 108($v0)
	sw $t2, 112($v0)
	sw $t2, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	li $t0, MEM_VERT_OFFSET
	mul $t0, $t0, 3
	add $v0, $v0, $t0
	sw $t2, 88($v0)
	sw $t2, 96($v0)
	sw $t2, 104($v0)
	sw $t2, 108($v0)
	sw $t2, 112($v0)
	sw $t2, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 136($v0)
	sw $t2, 140($v0)
	sw $t2, 144($v0)
	sw $t2, 152($v0)
	sw $t2, 156($v0)
	sw $t2, 160($v0)
	sw $t2, 168($v0)
	sw $t2, 180($v0)
	sw $t2, 188($v0)
	sw $t2, 192($v0)
	sw $t2, 196($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 88($v0)
	sw $t2, 96($v0)
	sw $t2, 104($v0)
	sw $t2, 112($v0)
	sw $t2, 120($v0)
	sw $t2, 128($v0)
	sw $t2, 136($v0)
	sw $t2, 144($v0)
	sw $t2, 156($v0)
	sw $t2, 168($v0)
	sw $t2, 172($v0)
	sw $t2, 180($v0)
	sw $t2, 188($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 88($v0)
	sw $t2, 92($v0)
	sw $t2, 96($v0)
	sw $t2, 104($v0)
	sw $t2, 112($v0)
	sw $t2, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 136($v0)
	sw $t2, 140($v0)
	sw $t2, 144($v0)
	sw $t2, 156($v0)
	sw $t2, 168($v0)
	sw $t2, 172($v0)
	sw $t2, 180($v0)
	sw $t2, 188($v0)
	sw $t2, 196($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 88($v0)
	sw $t2, 96($v0)
	sw $t2, 104($v0)
	sw $t2, 112($v0)
	sw $t2, 120($v0)
	sw $t2, 136($v0)
	sw $t2, 156($v0)
	sw $t2, 168($v0)
	sw $t2, 176($v0)
	sw $t2, 180($v0)
	sw $t2, 188($v0)
	sw $t2, 196($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 88($v0)
	sw $t2, 96($v0)
	sw $t2, 104($v0)
	sw $t2, 112($v0)
	sw $t2, 120($v0)
	sw $t2, 136($v0)
	sw $t2, 156($v0)
	sw $t2, 168($v0)
	sw $t2, 176($v0)
	sw $t2, 180($v0)
	sw $t2, 188($v0)
	sw $t2, 196($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 88($v0)
	sw $t2, 96($v0)
	sw $t2, 104($v0)
	sw $t2, 108($v0)
	sw $t2, 112($v0)
	sw $t2, 120($v0)
	sw $t2, 136($v0)
	sw $t2, 152($v0)
	sw $t2, 156($v0)
	sw $t2, 160($v0)
	sw $t2, 168($v0)
	sw $t2, 180($v0)
	sw $t2, 188($v0)
	sw $t2, 192($v0)
	sw $t2, 196($v0)
	li $t0, MEM_VERT_OFFSET
	mul $t0, $t0, 6
	add $v0, $v0, $t0
	sw $t7, 24($v0)
	sw $t7, 28($v0)
	sw $t7, 32($v0)
	sw $t7, 44($v0)
	sw $t7, 48($v0)
	sw $t7, 52($v0)
	sw $t7, 64($v0)
	sw $t7, 68($v0)
	sw $t7, 72($v0)
	sw $t7, 76($v0)
	sw $t7, 88($v0)
	sw $t7, 92($v0)
	sw $t7, 96($v0)
	sw $t7, 108($v0)
	sw $t7, 112($v0)
	sw $t7, 116($v0)
	sw $t7, 136($v0)
	sw $t7, 140($v0)
	sw $t7, 144($v0)
	sw $t7, 152($v0)
	sw $t7, 156($v0)
	sw $t7, 160($v0)
	sw $t7, 176($v0)
	sw $t7, 180($v0)
	sw $t7, 196($v0)
	sw $t7, 200($v0)
	sw $t7, 212($v0)
	sw $t7, 216($v0)
	sw $t7, 220($v0)
	sw $t7, 224($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t7, 24($v0)
	sw $t7, 36($v0)
	sw $t7, 44($v0)
	sw $t7, 56($v0)
	sw $t7, 64($v0)
	sw $t7, 84($v0)
	sw $t7, 104($v0)
	sw $t7, 132($v0)
	sw $t7, 152($v0)
	sw $t7, 164($v0)
	sw $t7, 172($v0)
	sw $t7, 184($v0)
	sw $t7, 192($v0)
	sw $t7, 204($v0)
	sw $t7, 212($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t7, 24($v0)
	sw $t7, 28($v0)
	sw $t7, 32($v0)
	sw $t7, 44($v0)
	sw $t7, 48($v0)
	sw $t7, 52($v0)
	sw $t7, 64($v0)
	sw $t7, 68($v0)
	sw $t7, 72($v0)
	sw $t7, 88($v0)
	sw $t7, 92($v0)
	sw $t7, 108($v0)
	sw $t7, 112($v0)
	sw $t7, 136($v0)
	sw $t7, 140($v0)
	sw $t7, 152($v0)
	sw $t7, 156($v0)
	sw $t7, 160($v0)
	sw $t7, 172($v0)
	sw $t7, 176($v0)
	sw $t7, 180($v0)
	sw $t7, 184($v0)
	sw $t7, 192($v0)
	sw $t7, 212($v0)
	sw $t7, 216($v0)
	sw $t7, 220($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t7, 24($v0)
	sw $t7, 44($v0)
	sw $t7, 52($v0)
	sw $t7, 64($v0)
	sw $t7, 96($v0)
	sw $t7, 116($v0)
	sw $t7, 144($v0)
	sw $t7, 152($v0)
	sw $t7, 172($v0)
	sw $t7, 184($v0)
	sw $t7, 192($v0)
	sw $t7, 204($v0)
	sw $t7, 212($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t7, 24($v0)
	sw $t7, 44($v0)
	sw $t7, 56($v0)
	sw $t7, 64($v0)
	sw $t7, 68($v0)
	sw $t7, 72($v0)
	sw $t7, 76($v0)
	sw $t7, 84($v0)
	sw $t7, 88($v0)
	sw $t7, 92($v0)
	sw $t7, 104($v0)
	sw $t7, 108($v0)
	sw $t7, 112($v0)
	sw $t7, 132($v0)
	sw $t7, 136($v0)
	sw $t7, 140($v0)
	sw $t7, 152($v0)
	sw $t7, 172($v0)
	sw $t7, 184($v0)
	sw $t7, 196($v0)
	sw $t7, 200($v0)
	sw $t7, 212($v0)
	sw $t7, 216($v0)
	sw $t7, 220($v0)
	sw $t7, 224($v0)
	li $t0, MEM_VERT_OFFSET
	mul $t0, $t0, 2
	add $v0, $v0, $t0
	sw $t7, 48($v0)
	sw $t7, 52($v0)
	sw $t7, 56($v0)
	sw $t7, 60($v0)
	sw $t7, 64($v0)
	sw $t7, 76($v0)
	sw $t7, 80($v0)
	sw $t7, 104($v0)
	sw $t7, 108($v0)
	sw $t7, 112($v0)
	sw $t7, 120($v0)
	sw $t7, 124($v0)
	sw $t7, 128($v0)
	sw $t7, 132($v0)
	sw $t7, 136($v0)
	sw $t7, 148($v0)
	sw $t7, 152($v0)
	sw $t7, 164($v0)
	sw $t7, 168($v0)
	sw $t7, 172($v0)
	sw $t7, 184($v0)
	sw $t7, 188($v0)
	sw $t7, 192($v0)
	sw $t7, 196($v0)
	sw $t7, 200($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t7, 56($v0)
	sw $t7, 72($v0)
	sw $t7, 84($v0)
	sw $t7, 100($v0)
	sw $t7, 128($v0)
	sw $t7, 144($v0)
	sw $t7, 156($v0)
	sw $t7, 164($v0)
	sw $t7, 176($v0)
	sw $t7, 192($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t7, 56($v0)
	sw $t7, 72($v0)
	sw $t7, 84($v0)
	sw $t7, 104($v0)
	sw $t7, 108($v0)
	sw $t7, 128($v0)
	sw $t7, 144($v0)
	sw $t7, 148($v0)
	sw $t7, 152($v0)
	sw $t7, 156($v0)
	sw $t7, 164($v0)
	sw $t7, 168($v0)
	sw $t7, 172($v0)
	sw $t7, 192($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t7, 56($v0)
	sw $t7, 72($v0)
	sw $t7, 84($v0)
	sw $t7, 112($v0)
	sw $t7, 128($v0)
	sw $t7, 144($v0)
	sw $t7, 156($v0)
	sw $t7, 164($v0)
	sw $t7, 172($v0)
	sw $t7, 192($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t7, 56($v0)
	sw $t7, 76($v0)
	sw $t7, 80($v0)
	sw $t7, 100($v0)
	sw $t7, 104($v0)
	sw $t7, 108($v0)
	sw $t7, 128($v0)
	sw $t7, 144($v0)
	sw $t7, 156($v0)
	sw $t7, 164($v0)
	sw $t7, 176($v0)
	sw $t7, 192($v0)
	li $t0, MEM_VERT_OFFSET
	mul $t0, $t0, 7
	add $v0, $v0, $t0
	sw $t4, 20($v0)
	sw $t4, 28($v0)
	sw $t4, 44($v0)
	sw $t4, 52($v0)
	sw $t4, 68($v0)
	sw $t4, 76($v0)
	sw $t4, 188($v0)
	sw $t4, 196($v0)
	sw $t4, 212($v0)
	sw $t4, 220($v0)
	sw $t4, 236($v0)
	sw $t4, 244($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t4, 12($v0)
	sw $t4, 16($v0)
	sw $t4, 20($v0)
	sw $t4, 24($v0)
	sw $t4, 28($v0)
	sw $t4, 36($v0)
	sw $t4, 40($v0)
	sw $t4, 44($v0)
	sw $t4, 48($v0)
	sw $t4, 52($v0)
	sw $t4, 60($v0)
	sw $t4, 64($v0)
	sw $t4, 68($v0)
	sw $t4, 72($v0)
	sw $t4, 76($v0)
	sw $t4, 180($v0)
	sw $t4, 184($v0)
	sw $t4, 188($v0)
	sw $t4, 192($v0)
	sw $t4, 196($v0)
	sw $t4, 204($v0)
	sw $t4, 208($v0)
	sw $t4, 212($v0)
	sw $t4, 216($v0)
	sw $t4, 220($v0)
	sw $t4, 228($v0)
	sw $t4, 232($v0)
	sw $t4, 236($v0)
	sw $t4, 240($v0)
	sw $t4, 244($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t4, 12($v0)
	sw $t5, 16($v0)
	sw $t3, 20($v0)
	sw $t5, 24($v0)
	sw $t3, 28($v0)
	sw $t4, 36($v0)
	sw $t5, 40($v0)
	sw $t3, 44($v0)
	sw $t5, 48($v0)
	sw $t3, 52($v0)
	sw $t4, 60($v0)
	sw $t5, 64($v0)
	sw $t3, 68($v0)
	sw $t5, 72($v0)
	sw $t3, 76($v0)
	sw $t3, 180($v0)
	sw $t5, 184($v0)
	sw $t3, 188($v0)
	sw $t5, 192($v0)
	sw $t1, 196($v0)
	sw $t3, 204($v0)
	sw $t5, 208($v0)
	sw $t3, 212($v0)
	sw $t5, 216($v0)
	sw $t1, 220($v0)
	sw $t3, 228($v0)
	sw $t5, 232($v0)
	sw $t3, 236($v0)
	sw $t5, 240($v0)
	sw $t1, 244($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t4, 12($v0)
	sw $t5, 16($v0)
	sw $t5, 20($v0)
	sw $t5, 24($v0)
	sw $t5, 28($v0)
	sw $t4, 36($v0)
	sw $t5, 40($v0)
	sw $t5, 44($v0)
	sw $t5, 48($v0)
	sw $t5, 52($v0)
	sw $t4, 60($v0)
	sw $t5, 64($v0)
	sw $t5, 68($v0)
	sw $t5, 72($v0)
	sw $t5, 76($v0)
	sw $t5, 180($v0)
	sw $t5, 184($v0)
	sw $t5, 188($v0)
	sw $t5, 192($v0)
	sw $t1, 196($v0)
	sw $t5, 204($v0)
	sw $t5, 208($v0)
	sw $t5, 212($v0)
	sw $t5, 216($v0)
	sw $t1, 220($v0)
	sw $t5, 228($v0)
	sw $t5, 232($v0)
	sw $t5, 236($v0)
	sw $t5, 240($v0)
	sw $t1, 244($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t4, 16($v0)
	sw $t4, 24($v0)
	sw $t4, 40($v0)
	sw $t4, 48($v0)
	sw $t4, 64($v0)
	sw $t4, 72($v0)
	sw $t4, 184($v0)
	sw $t4, 192($v0)
	sw $t4, 208($v0)
	sw $t4, 216($v0)
	sw $t4, 232($v0)
	sw $t4, 240($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t5, 0($v0)
	sw $t5, 4($v0)
	sw $t5, 8($v0)
	sw $t5, 12($v0)
	sw $t5, 16($v0)
	sw $t5, 20($v0)
	sw $t5, 24($v0)
	sw $t5, 28($v0)
	sw $t5, 32($v0)
	sw $t5, 36($v0)
	sw $t5, 40($v0)
	sw $t5, 44($v0)
	sw $t5, 48($v0)
	sw $t5, 52($v0)
	sw $t5, 56($v0)
	sw $t5, 60($v0)
	sw $t5, 64($v0)
	sw $t5, 68($v0)
	sw $t5, 72($v0)
	sw $t5, 76($v0)
	sw $t5, 80($v0)
	sw $t5, 84($v0)
	sw $t5, 88($v0)
	sw $t5, 92($v0)
	sw $t5, 96($v0)
	sw $t5, 100($v0)
	sw $t5, 104($v0)
	sw $t5, 108($v0)
	sw $t5, 112($v0)
	sw $t5, 116($v0)
	sw $t5, 120($v0)
	sw $t5, 124($v0)
	sw $t5, 128($v0)
	sw $t5, 132($v0)
	sw $t5, 136($v0)
	sw $t5, 140($v0)
	sw $t5, 144($v0)
	sw $t5, 148($v0)
	sw $t5, 152($v0)
	sw $t5, 156($v0)
	sw $t5, 160($v0)
	sw $t5, 164($v0)
	sw $t5, 168($v0)
	sw $t5, 172($v0)
	sw $t5, 176($v0)
	sw $t5, 180($v0)
	sw $t5, 184($v0)
	sw $t5, 188($v0)
	sw $t5, 192($v0)
	sw $t5, 196($v0)
	sw $t5, 200($v0)
	sw $t5, 204($v0)
	sw $t5, 208($v0)
	sw $t5, 212($v0)
	sw $t5, 216($v0)
	sw $t5, 220($v0)
	sw $t5, 224($v0)
	sw $t5, 228($v0)
	sw $t5, 232($v0)
	sw $t5, 236($v0)
	sw $t5, 240($v0)
	sw $t5, 244($v0)
	sw $t5, 248($v0)
	sw $t5, 252($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t5, 0($v0)
	sw $t5, 4($v0)
	sw $t6, 8($v0)
	sw $t6, 12($v0)
	sw $t6, 16($v0)
	sw $t6, 20($v0)
	sw $t5, 24($v0)
	sw $t5, 28($v0)
	sw $t6, 32($v0)
	sw $t6, 36($v0)
	sw $t6, 40($v0)
	sw $t6, 44($v0)
	sw $t5, 48($v0)
	sw $t5, 52($v0)
	sw $t6, 56($v0)
	sw $t6, 60($v0)
	sw $t6, 64($v0)
	sw $t6, 68($v0)
	sw $t5, 72($v0)
	sw $t5, 76($v0)
	sw $t6, 80($v0)
	sw $t6, 84($v0)
	sw $t6, 88($v0)
	sw $t6, 92($v0)
	sw $t5, 96($v0)
	sw $t5, 100($v0)
	sw $t6, 104($v0)
	sw $t6, 108($v0)
	sw $t6, 112($v0)
	sw $t6, 116($v0)
	sw $t5, 120($v0)
	sw $t5, 124($v0)
	sw $t6, 128($v0)
	sw $t6, 132($v0)
	sw $t6, 136($v0)
	sw $t6, 140($v0)
	sw $t5, 144($v0)
	sw $t5, 148($v0)
	sw $t6, 152($v0)
	sw $t6, 156($v0)
	sw $t6, 160($v0)
	sw $t6, 164($v0)
	sw $t5, 168($v0)
	sw $t5, 172($v0)
	sw $t6, 176($v0)
	sw $t6, 180($v0)
	sw $t6, 184($v0)
	sw $t6, 188($v0)
	sw $t5, 192($v0)
	sw $t5, 196($v0)
	sw $t6, 200($v0)
	sw $t6, 204($v0)
	sw $t6, 208($v0)
	sw $t6, 212($v0)
	sw $t5, 216($v0)
	sw $t5, 220($v0)
	sw $t6, 224($v0)
	sw $t6, 228($v0)
	sw $t6, 232($v0)
	sw $t6, 236($v0)
	sw $t5, 240($v0)
	sw $t5, 244($v0)
	sw $t6, 248($v0)
	sw $t6, 252($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t6, 0($v0)
	sw $t6, 4($v0)
	sw $t8, 8($v0)
	sw $t6, 12($v0)
	sw $t8, 16($v0)
	sw $t8, 20($v0)
	sw $t6, 24($v0)
	sw $t6, 28($v0)
	sw $t8, 32($v0)
	sw $t6, 36($v0)
	sw $t8, 40($v0)
	sw $t8, 44($v0)
	sw $t6, 48($v0)
	sw $t6, 52($v0)
	sw $t8, 56($v0)
	sw $t6, 60($v0)
	sw $t8, 64($v0)
	sw $t8, 68($v0)
	sw $t6, 72($v0)
	sw $t6, 76($v0)
	sw $t8, 80($v0)
	sw $t6, 84($v0)
	sw $t8, 88($v0)
	sw $t8, 92($v0)
	sw $t6, 96($v0)
	sw $t6, 100($v0)
	sw $t8, 104($v0)
	sw $t6, 108($v0)
	sw $t8, 112($v0)
	sw $t8, 116($v0)
	sw $t6, 120($v0)
	sw $t6, 124($v0)
	sw $t8, 128($v0)
	sw $t6, 132($v0)
	sw $t8, 136($v0)
	sw $t8, 140($v0)
	sw $t6, 144($v0)
	sw $t6, 148($v0)
	sw $t8, 152($v0)
	sw $t6, 156($v0)
	sw $t8, 160($v0)
	sw $t8, 164($v0)
	sw $t6, 168($v0)
	sw $t6, 172($v0)
	sw $t8, 176($v0)
	sw $t6, 180($v0)
	sw $t8, 184($v0)
	sw $t8, 188($v0)
	sw $t6, 192($v0)
	sw $t6, 196($v0)
	sw $t8, 200($v0)
	sw $t6, 204($v0)
	sw $t8, 208($v0)
	sw $t8, 212($v0)
	sw $t6, 216($v0)
	sw $t6, 220($v0)
	sw $t8, 224($v0)
	sw $t6, 228($v0)
	sw $t8, 232($v0)
	sw $t8, 236($v0)
	sw $t6, 240($v0)
	sw $t6, 244($v0)
	sw $t8, 248($v0)
	sw $t6, 252($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t8, 0($v0)
	sw $t8, 4($v0)
	sw $t8, 8($v0)
	sw $t8, 12($v0)
	sw $t8, 16($v0)
	sw $t8, 20($v0)
	sw $t8, 24($v0)
	sw $t8, 28($v0)
	sw $t8, 32($v0)
	sw $t8, 36($v0)
	sw $t8, 40($v0)
	sw $t8, 44($v0)
	sw $t8, 48($v0)
	sw $t8, 52($v0)
	sw $t8, 56($v0)
	sw $t8, 60($v0)
	sw $t8, 64($v0)
	sw $t8, 68($v0)
	sw $t8, 72($v0)
	sw $t8, 76($v0)
	sw $t8, 80($v0)
	sw $t8, 84($v0)
	sw $t8, 88($v0)
	sw $t8, 92($v0)
	sw $t8, 96($v0)
	sw $t8, 100($v0)
	sw $t8, 104($v0)
	sw $t8, 108($v0)
	sw $t8, 112($v0)
	sw $t8, 116($v0)
	sw $t8, 120($v0)
	sw $t8, 124($v0)
	sw $t8, 128($v0)
	sw $t8, 132($v0)
	sw $t8, 136($v0)
	sw $t8, 140($v0)
	sw $t8, 144($v0)
	sw $t8, 148($v0)
	sw $t8, 152($v0)
	sw $t8, 156($v0)
	sw $t8, 160($v0)
	sw $t8, 164($v0)
	sw $t8, 168($v0)
	sw $t8, 172($v0)
	sw $t8, 176($v0)
	sw $t8, 180($v0)
	sw $t8, 184($v0)
	sw $t8, 188($v0)
	sw $t8, 192($v0)
	sw $t8, 196($v0)
	sw $t8, 200($v0)
	sw $t8, 204($v0)
	sw $t8, 208($v0)
	sw $t8, 212($v0)
	sw $t8, 216($v0)
	sw $t8, 220($v0)
	sw $t8, 224($v0)
	sw $t8, 228($v0)
	sw $t8, 232($v0)
	sw $t8, 236($v0)
	sw $t8, 240($v0)
	sw $t8, 244($v0)
	sw $t8, 248($v0)
	sw $t8, 252($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t7, 0($v0)
	sw $t7, 4($v0)
	sw $t7, 8($v0)
	sw $t7, 12($v0)
	sw $t7, 16($v0)
	sw $t7, 20($v0)
	sw $t7, 24($v0)
	sw $t7, 28($v0)
	sw $t7, 32($v0)
	sw $t7, 36($v0)
	sw $t7, 40($v0)
	sw $t7, 44($v0)
	sw $t7, 48($v0)
	sw $t7, 52($v0)
	sw $t7, 56($v0)
	sw $t7, 60($v0)
	sw $t7, 64($v0)
	sw $t7, 68($v0)
	sw $t7, 72($v0)
	sw $t7, 76($v0)
	sw $t7, 80($v0)
	sw $t7, 84($v0)
	sw $t7, 88($v0)
	sw $t7, 92($v0)
	sw $t7, 96($v0)
	sw $t7, 100($v0)
	sw $t7, 104($v0)
	sw $t7, 108($v0)
	sw $t7, 112($v0)
	sw $t7, 116($v0)
	sw $t7, 120($v0)
	sw $t7, 124($v0)
	sw $t7, 128($v0)
	sw $t7, 132($v0)
	sw $t7, 136($v0)
	sw $t7, 140($v0)
	sw $t7, 144($v0)
	sw $t7, 148($v0)
	sw $t7, 152($v0)
	sw $t7, 156($v0)
	sw $t7, 160($v0)
	sw $t7, 164($v0)
	sw $t7, 168($v0)
	sw $t7, 172($v0)
	sw $t7, 176($v0)
	sw $t7, 180($v0)
	sw $t7, 184($v0)
	sw $t7, 188($v0)
	sw $t7, 192($v0)
	sw $t7, 196($v0)
	sw $t7, 200($v0)
	sw $t7, 204($v0)
	sw $t7, 208($v0)
	sw $t7, 212($v0)
	sw $t7, 216($v0)
	sw $t7, 220($v0)
	sw $t7, 224($v0)
	sw $t7, 228($v0)
	sw $t7, 232($v0)
	sw $t7, 236($v0)
	sw $t7, 240($v0)
	sw $t7, 244($v0)
	sw $t7, 248($v0)
	sw $t7, 252($v0)


.startMenu:
	startMenu_loop:
		li $t0, KEY_ADDRESS
		lw $t1, 0($t0)          # retrieve whether key is pressed
		beq $t1, 0, startMenu_continue     # if no key is pressed, skip key press logic 
		lw $t2, 4($t0) 		# get key press
		beq $t2, SPACE_KEY, main	# if A pressed, jump to moveLeft
	startMenu_continue:
		li $v0, 32		# set syscall to sleep
		li $a0, SLEEP_DURATION  # set sleep duration to default screen refresh delay
		syscall

		j startMenu_loop

main: 	
	la $t0, currentLevel
	sw $zero, 0($t0)
	# Program main loop
	j resetLevel

level_one: 
	la $t1, pointsAtStart
	lw $s4, 0($t1)

	la $t1, currentLevel
	li $t0, 0
	sw $t0, 0($t1)		# set current level counter to 0
	# set level counter
	addi $s7, $zero, 11  # set number of platforms in level
	# initialize platforms
	addi $t0, $zero, 0  # index
	addi $t1, $zero, 0  # initial x
	addi $t2, $zero, 0  # final x
	addi $t3, $zero, 0  # current x
	addi $t4, $zero, 38 # length
	addi $t5, $zero, 59 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	addi $t0, $zero, 1  # index
	addi $t1, $zero, 38  # initial x
	addi $t2, $zero, 38  # final x
	addi $t3, $zero, 38  # current x
	addi $t4, $zero, 26 # length
	addi $t5, $zero, 59 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	addi $t0, $zero, 2  # index
	addi $t1, $zero, 0  # initial x
	addi $t2, $zero, 0  # final x
	addi $t3, $zero, 0  # current x
	addi $t4, $zero, 18 # length
	addi $t5, $zero, 44 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	addi $t0, $zero, 3  # index
	addi $t1, $zero, 0  # initial x
	addi $t2, $zero, 0  # final x
	addi $t3, $zero, 0  # current x
	addi $t4, $zero, 10 # length
	addi $t5, $zero, 29 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	addi $t0, $zero, 4  # index
	addi $t1, $zero, 12  # initial x
	addi $t2, $zero, 12  # final x
	addi $t3, $zero, 12  # current x
	addi $t4, $zero, 31 # length
	addi $t5, $zero, 14 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	addi $t0, $zero, 5  # index
	addi $t1, $zero, 29  # initial x
	addi $t2, $zero, 29  # final x
	addi $t3, $zero, 29  # current x
	addi $t4, $zero, 11 # length
	addi $t5, $zero, 44 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	addi $t0, $zero, 6  # index
	addi $t1, $zero, 51  # initial x
	addi $t2, $zero, 51  # final x
	addi $t3, $zero, 51  # current x
	addi $t4, $zero, 13 # length
	addi $t5, $zero, 44 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	addi $t0, $zero, 7  # index
	addi $t1, $zero, 26  # initial x
	addi $t2, $zero, 26  # final x
	addi $t3, $zero, 26  # current x
	addi $t4, $zero, 3 # length
	addi $t5, $zero, 23 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	addi $t0, $zero, 8  # index
	addi $t1, $zero, 26  # initial x
	addi $t2, $zero, 26  # final x
	addi $t3, $zero, 26  # current x
	addi $t4, $zero, 3 # length
	addi $t5, $zero, 32 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	addi $t0, $zero, 9  # index
	addi $t1, $zero, 26  # initial x
	addi $t2, $zero, 26  # final x
	addi $t3, $zero, 26  # current x
	addi $t4, $zero, 3 # length
	addi $t5, $zero, 41 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	addi $t0, $zero, 10  # index
	addi $t1, $zero, 26  # initial x
	addi $t2, $zero, 26  # final x
	addi $t3, $zero, 26  # current x
	addi $t4, $zero, 3 # length
	addi $t5, $zero, 50 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	
	addi $s6, $zero, 5  # set number of pickups in level
	# initialize each pickup
	addi $t0, $zero, 0  # index
	addi $t1, $zero, 1 # x-coord
	addi $t2, $zero, 38 # y-coord
	addi $t3, $zero, PICKUP_TYPE_COIN  # pickup effect
	jal initPickup
	addi $t0, $zero, 1  # index
	addi $t1, $zero, 31 # x-coord
	addi $t2, $zero, 53 # y-coord
	addi $t3, $zero, PICKUP_TYPE_COIN  # pickup effect
	jal initPickup
	addi $t0, $zero, 2  # index
	addi $t1, $zero, 32 # x-coord
	addi $t2, $zero, 38 # y-coord
	addi $t3, $zero, PICKUP_TYPE_HEALTH  # pickup effect
	jal initPickup
	addi $t0, $zero, 3  # index
	addi $t1, $zero, 19 # x-coord
	addi $t2, $zero, 22 # y-coord
	addi $t3, $zero, PICKUP_TYPE_INVINCIBILITY  # pickup effect
	jal initPickup
	addi $t0, $zero, 4  # index
	addi $t1, $zero, 56 # x-coord
	addi $t2, $zero, 38 # y-coord
	addi $t3, $zero, PICKUP_TYPE_LESS_GRAVITY  # pickup effect
	jal initPickup

	addi $s5, $zero, 2
	# initialize each enemy
	li $t0, 0	# index
	li $t1, 1	# index of platform patrolled
	li $t2, 0	# start index of enemy within platform
	li $t3, 0 	# movement behavior (0 = moving, 2 = stationary)
	li $t4, 1 	# behavior when defeated (0 = already defeated)
	jal initEnemy
	li $t0, 1	# index
	li $t1, 4	# index of platform patrolled
	li $t2, 0	# start index of enemy within platform
	li $t3, 0 	# movement behavior (0 = moving, 2 = stationary)
	li $t4, 1 	# behavior when defeated (0 = already defeated)
	jal initEnemy

	j startGame

level_two:

	la $t1, pointsAtStart
	lw $s4, 4($t1)

	la $t1, currentLevel
	li $t0, 1
	sw $t0, 0($t1)		# set current level counter to 0
	# set level counter

	addi $s7, $zero, 15  # set number of platforms in level
	# initialize platforms
	addi $t0, $zero, 0  # index
	addi $t1, $zero, 0  # initial x
	addi $t2, $zero, 0  # final x
	addi $t3, $zero, 0  # current x
	addi $t4, $zero, 16 # length
	addi $t5, $zero, 59 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	# enemy patrolled
	addi $t0, $zero, 1  # index
	addi $t1, $zero, 16 # initial x
	addi $t2, $zero, 16 # final x
	addi $t3, $zero, 16 # current x
	addi $t4, $zero, 13 # length
	addi $t5, $zero, 59 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	# enemy patrolled
	addi $t0, $zero, 2  # index
	addi $t1, $zero, 31 # initial x
	addi $t2, $zero, 31 # final x
	addi $t3, $zero, 31 # current x
	addi $t4, $zero, 12 # length
	addi $t5, $zero, 59 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	# enemy patrolled
	addi $t0, $zero, 3  # index
	addi $t1, $zero, 45 # initial x
	addi $t2, $zero, 45 # final x
	addi $t3, $zero, 45 # current x
	addi $t4, $zero, 17 # length
	addi $t5, $zero, 59 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	# platform moving (left side)
	addi $t0, $zero, 4  # index
	addi $t1, $zero, 13 # initial x
	addi $t2, $zero, 25 # final x
	addi $t3, $zero, 25 # current x
	addi $t4, $zero, 7 # length
	addi $t5, $zero, 44 # y coord
	addi $t6, $zero, 1  # movement direction, 2 = stationary
	jal initPlatform
	# moving platform (right)
	addi $t0, $zero, 5  # index
	addi $t1, $zero, 33 # initial x
	addi $t2, $zero, 45 # final x
	addi $t3, $zero, 33 # current x
	addi $t4, $zero, 7 # length
	addi $t5, $zero, 44 # y coord
	addi $t6, $zero, 0  # movement direction, 2 = stationary
	jal initPlatform
	addi $t0, $zero, 6  # index
	addi $t1, $zero, 0 # initial x
	addi $t2, $zero, 0 # final x
	addi $t3, $zero, 0 # current x
	addi $t4, $zero, 12 # length
	addi $t5, $zero, 44 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	addi $t0, $zero, 7  # index
	addi $t1, $zero, 56 # initial x
	addi $t2, $zero, 56 # final x
	addi $t3, $zero, 56 # current x
	addi $t4, $zero, 8 # length
	addi $t5, $zero, 36 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	addi $t0, $zero, 8  # index
	addi $t1, $zero, 0 # initial x
	addi $t2, $zero, 0 # final x
	addi $t3, $zero, 0 # current x
	addi $t4, $zero, 16 # length
	addi $t5, $zero, 24 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	# enemy top left
	addi $t0, $zero, 9  # index
	addi $t1, $zero, 13 # initial x
	addi $t2, $zero, 13 # final x
	addi $t3, $zero, 13 # current x
	addi $t4, $zero, 12 # length
	addi $t5, $zero, 24 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	# enemy top right
	addi $t0, $zero, 10  # index
	addi $t1, $zero, 28 # initial x
	addi $t2, $zero, 28 # final x
	addi $t3, $zero, 28 # current x
	addi $t4, $zero, 13 # length
	addi $t5, $zero, 24 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	addi $t0, $zero, 11  # index
	addi $t1, $zero, 16 # initial x
	addi $t2, $zero, 16 # final x
	addi $t3, $zero, 16 # current x
	addi $t4, $zero, 19 # length
	addi $t5, $zero, 12 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	addi $t0, $zero, 12  # index
	addi $t1, $zero, 29 # initial x
	addi $t2, $zero, 29 # final x
	addi $t3, $zero, 29 # current x
	addi $t4, $zero, 2 # length
	addi $t5, $zero, 59 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	addi $t0, $zero, 13  # index
	addi $t1, $zero, 43 # initial x
	addi $t2, $zero, 43 # final x
	addi $t3, $zero, 43 # current x
	addi $t4, $zero, 2 # length
	addi $t5, $zero, 59 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	addi $t0, $zero, 14  # index
	addi $t1, $zero, 62 # initial x
	addi $t2, $zero, 62 # final x
	addi $t3, $zero, 62 # current x
	addi $t4, $zero, 2 # length
	addi $t5, $zero, 59 # y coord
	addi $t6, $zero, 2  # movement direction, 2 = stationary
	jal initPlatform
	
	addi $s6, $zero, 6  # set number of pickups in level
	# initialize each pickup
	addi $t0, $zero, 0  # index
	addi $t1, $zero, 25 # x-coord
	addi $t2, $zero, 38 # y-coord
	addi $t3, $zero, PICKUP_TYPE_COIN  # pickup effect
	jal initPickup
	addi $t0, $zero, 1  # index
	addi $t1, $zero, 44 # x-coord
	addi $t2, $zero, 38 # y-coord
	addi $t3, $zero, PICKUP_TYPE_COIN  # pickup effect
	jal initPickup
	addi $t0, $zero, 2  # index
	addi $t1, $zero, 2 # x-coord
	addi $t2, $zero, 18 # y-coord
	addi $t3, $zero, PICKUP_TYPE_COIN  # pickup effect
	jal initPickup
	addi $t0, $zero, 3  # index
	addi $t1, $zero, 58 # x-coord
	addi $t2, $zero, 30 # y-coord
	addi $t3, $zero, PICKUP_TYPE_HEALTH  # pickup effect
	jal initPickup
	addi $t0, $zero, 4  # index
	addi $t1, $zero, 58 # x-coord
	addi $t2, $zero, 11 # y-coord
	addi $t3, $zero, PICKUP_TYPE_LESS_GRAVITY  # pickup effect
	jal initPickup
	addi $t0, $zero, 5  # index
	addi $t1, $zero, 2 # x-coord
	addi $t2, $zero, 53 # y-coord
	addi $t3, $zero, PICKUP_TYPE_INVINCIBILITY  # pickup effect
	jal initPickup

	addi $s5, $zero, 5
	# initialize each enemy
	li $t0, 0	# index
	li $t1, 1	# index of platform patrolled
	li $t2, 0	# start index of enemy within platform
	li $t3, 0 	# movement behavior (0 = moving, 2 = stationary)
	li $t4, 1 	# behavior when defeated (0 = already defeated)
	jal initEnemy
	li $t0, 1	# index
	li $t1, 2	# index of platform patrolled
	li $t2, 0	# start index of enemy within platform
	li $t3, 0 	# movement behavior (0 = moving, 2 = stationary)
	li $t4, 1 	# behavior when defeated (0 = already defeated)
	jal initEnemy
	li $t0, 2	# index
	li $t1, 3	# index of platform patrolled
	li $t2, 0	# start index of enemy within platform
	li $t3, 0 	# movement behavior (0 = moving, 2 = stationary)
	li $t4, 1 	# behavior when defeated (0 = already defeated)
	jal initEnemy
	li $t0, 3	# index
	li $t1, 9	# index of platform patrolled
	li $t2, 0	# start index of enemy within platform
	li $t3, 0 	# movement behavior (0 = moving, 2 = stationary)
	li $t4, 1 	# behavior when defeated (0 = already defeated)
	jal initEnemy
	li $t0, 4	# index
	li $t1, 10	# index of platform patrolled
	li $t2, 0	# start index of enemy within platform
	li $t3, 0 	# movement behavior (0 = moving, 2 = stationary)
	li $t4, 1 	# behavior when defeated (0 = already defeated)
	jal initEnemy

	j startGame

level_three:
	la $t1, pointsAtStart	# reset points
	lw $s4, 8($t1)

	la $t1, currentLevel
	li $t0, 2
	sw $t0, 0($t1)		# set current level counter to 0
	# set level counter
	addi $s7, $zero, 9  # set number of platforms in level
	# initialize platforms
	addi $t0, $zero, 0  # index
	addi $t1, $zero, 0  # initial x
	addi $t2, $zero, 0  # final x
	addi $t3, $zero, 0  # current x
	addi $t4, $zero, 9 # length
	addi $t5, $zero, 59 # y coord
	addi $t6, $zero, 2  # movement direction
	jal initPlatform
	# enemy patrolled bottom
	addi $t0, $zero, 1  # index
	addi $t1, $zero, 9  # initial x
	addi $t2, $zero, 9  # final x
	addi $t3, $zero, 9  # current x
	addi $t4, $zero, 43 # length
	addi $t5, $zero, 59 # y coord
	addi $t6, $zero, 2  # movement direction
	jal initPlatform
	# bottom right
	addi $t0, $zero, 2  # index
	addi $t1, $zero, 51  # initial x
	addi $t2, $zero, 51  # final x
	addi $t3, $zero, 51  # current x
	addi $t4, $zero, 13 # length
	addi $t5, $zero, 59 # y coord
	addi $t6, $zero, 2  # movement direction
	jal initPlatform
	# blocker
	addi $t0, $zero, 3  # index
	addi $t1, $zero, 8  # initial x
	addi $t2, $zero, 8  # final x
	addi $t3, $zero, 8  # current x
	addi $t4, $zero, 3 # length
	addi $t5, $zero, 43 # y coord
	addi $t6, $zero, 2  # movement direction
	jal initPlatform
	# moving platform bottom
	addi $t0, $zero, 3  # index
	addi $t1, $zero, 26  # initial x
	addi $t2, $zero, 39  # final x
	addi $t3, $zero, 39  # current x
	addi $t4, $zero, 17 # length
	addi $t5, $zero, 43 # y coord
	addi $t6, $zero, 1  # movement direction
	jal initPlatform
	addi $t0, $zero, 4  # index
	addi $t1, $zero, 8  # initial x
	addi $t2, $zero, 8  # final x
	addi $t3, $zero, 8  # current x
	addi $t4, $zero, 16 # length
	addi $t5, $zero, 34 # y coord
	addi $t6, $zero, 2  # movement direction
	jal initPlatform
	# below hp pack
	addi $t0, $zero, 5  # index
	addi $t1, $zero, 8  # initial x
	addi $t2, $zero, 8  # final x
	addi $t3, $zero, 8  # current x
	addi $t4, $zero, 3 # length
	addi $t5, $zero, 23 # y coord
	addi $t6, $zero, 2  # movement direction
	jal initPlatform
	# top moving platform
	addi $t0, $zero, 6  # index
	addi $t1, $zero, 19  # initial x
	addi $t2, $zero, 36  # final x
	addi $t3, $zero, 19  # current x
	addi $t4, $zero, 15 # length
	addi $t5, $zero, 19 # y coord
	addi $t6, $zero, 0  # movement direction
	jal initPlatform
	# top blocker
	addi $t0, $zero, 7  # index
	addi $t1, $zero, 47  # initial x
	addi $t2, $zero, 47  # final x
	addi $t3, $zero, 47  # current x
	addi $t4, $zero, 2 # length
	addi $t5, $zero, 1 # y coord
	addi $t6, $zero, 2  # movement direction
	jal initPlatform
	# top blocker
	addi $t0, $zero, 8  # index
	addi $t1, $zero, 8  # initial x
	addi $t2, $zero, 8  # final x
	addi $t3, $zero, 8  # current x
	addi $t4, $zero, 2 # length
	addi $t5, $zero, 43 # y coord
	addi $t6, $zero, 2  # movement direction
	jal initPlatform
	
	addi $s6, $zero, 7  # set number of pickups in level
	# initialize each pickup
	addi $t0, $zero, 0  # index
	addi $t1, $zero, 1 # x-coord
	addi $t2, $zero, 26 # y-coord
	addi $t3, $zero, PICKUP_TYPE_COIN  # pickup effect
	jal initPickup
	addi $t0, $zero, 1  # index
	addi $t1, $zero, 41 # x-coord
	addi $t2, $zero, 3 # y-coord
	addi $t3, $zero, PICKUP_TYPE_COIN  # pickup effect
	jal initPickup
	addi $t0, $zero, 2  # index
	addi $t1, $zero, 57 # x-coord
	addi $t2, $zero, 11 # y-coord
	addi $t3, $zero, PICKUP_TYPE_COIN  # pickup effect
	jal initPickup
	addi $t0, $zero, 3  # index
	addi $t1, $zero, 57 # x-coord
	addi $t2, $zero, 26 # y-coord
	addi $t3, $zero, PICKUP_TYPE_COIN  # pickup effect
	jal initPickup
	addi $t0, $zero, 4  # index
	addi $t1, $zero, 14 # x-coord
	addi $t2, $zero, 43 # y-coord
	addi $t3, $zero, PICKUP_TYPE_HEALTH  # pickup effect
	jal initPickup
	addi $t0, $zero, 5  # index
	addi $t1, $zero, 5 # x-coord
	addi $t2, $zero, 13 # y-coord
	addi $t3, $zero, PICKUP_TYPE_INVINCIBILITY  # pickup effect
	jal initPickup
	addi $t0, $zero, 6  # index
	addi $t1, $zero, 34 # x-coord
	addi $t2, $zero, 27 # y-coord
	addi $t3, $zero, PICKUP_TYPE_INVINCIBILITY  # pickup effect
	jal initPickup

	addi $s5, $zero, 3
	# initialize each enemy
	li $t0, 0	# index
	li $t1, 1	# index of platform patrolled
	li $t2, 0	# start index of enemy within platform
	li $t3, 0 	# movement behavior (0 = moving, 2 = stationary)
	li $t4, 1 	# behavior when defeated (0 = already defeated)
	jal initEnemy
	li $t0, 1	# index
	li $t1, 0	# index of platform patrolled
	li $t2, 0	# start index of enemy within platform
	li $t3, 0 	# movement behavior (0 = moving, 2 = stationary)
	li $t4, 1 	# behavior when defeated (0 = already defeated)
	jal initEnemy
	li $t0, 2	# index
	li $t1, 6	# index of platform patrolled
	li $t2, 0	# start index of enemy within platform
	li $t3, 0 	# movement behavior (0 = moving, 2 = stationary)
	li $t4, 1 	# behavior when defeated (0 = already defeated)
	jal initEnemy

	j startGame

	
startGame:
	jal updateScoreDisplay	# write score
	jal updateHealthDisplay # write health
	li $a0, 0
	jal drawPlatforms		# draw platforms completely
	
mainLoop:	
	li $t0, KEY_ADDRESS 	# set $t0 to be address of key press data
	lw $t1, 0($t0)          # retrieve whether key is pressed
	beq $t1, 0, afterKeyPress     # if no key is pressed, skip key press logic 
	lw $t2, 4($t0) 		# get key press
	beq $t2, LEFT_KEY, moveLeft	# if A pressed, jump to moveLeft
	beq $t2, UP_KEY, moveUp		# if W is pressed, jump to moveUp
	beq $t2, RIGHT_KEY, moveRight	# if D is pressed, jump to moveRight
	beq $t2, RESET_KEY, resetLevel 	# if reset is pressed, reset game
	afterKeyPress:
		# calculate velocity and gravity
		la $t0, velocity		# load current velocity
		lw $t1, 0($t0)
		beq $t1, 0, calculateGravity	# if player doesn't have velocity, calculate gravity instead
		# calculate how far player can jump
		beqz $t1, endJumpLoop		# if zero velocity, skip jumping
		jal removePlayer
		add $t3, $zero, $zero 		# start by assuming no jump is poss
	startJumpLoop:
		ble $s2, 1, endJumpLoop 	# stop if reached top of screen

		move $a0, $s1 
		sub $a1, $s2, 1 
					
		# save variables to stack before function call
		jal isPlatform		# check if unit above is a platform
		
		bne $v0, $zero, endJumpLoop	# if unit above is platform, stop jump
		addi $t3, $t3, 1		# increment counter
		sub $s2, $s2, 1			# move player up by a unit
		blt $t3, $t1, startJumpLoop	# iterate again if more units to jump
	endJumpLoop:	
		# sub $s2, $s2, $t1		# make the player jump
		subi $t1, $t1, JUMP_DECEL	# add deceleration
		bgtz $t1, updateVelocity 	# update movement as long as velocity above zero
		move $t1, $zero			# if velocity < 0, set = 0
	updateVelocity:
		sw $t1, 0($t0)
		j afterMovement
	
	calculateGravity:
		addi $a1, $s2, PLAYER_HEIGHT		# calculate y-coord of player's feet
		bge $a1, HEIGHT_INDEX, afterMovement 	# if player is already at bottom, skip gravity
		
		la $t0, lessGravity 	# load the number of less gravity effect ticks active
		lw $t1, 0($t0)
		
		bgtz $t1, skipResetLessGravity		# if effect ticks > 0, don't bother resetting
			sw $zero, 0($t0)						# reset to zero if ticks <= 0
			j skipLessGravity						# don't consider the effect this tick
		skipResetLessGravity:						# case if ticks >= 0
			beq $t1, $zero, skipLessGravity			# ignore effect if ticks == 0
			li $t0, GRAVITY_TICK_WHEN_LESS_GRAVITY 	# load delay to account for when applying less gravity effect		
			div $t1, $t0 
			mfhi $t1 								# retrieve remainder
			bne $t1, $zero, afterMovement			# if remainder != 0, skip gravity calculation

		skipLessGravity:

		move $a0, $s1				# prepare x-coord as argument		
		
		add $a1, $s2, 1			# check if area below is platform
		jal isPlatform			
		bne $v0, 0, afterMovement 	# skip gravity calculation if standing on platform
		addi $s2, $s2, 1		# move player down due to gravity
		jal removePlayerTop
	afterMovement:
		# update player location

	move $t0, $zero
	displacePlayerLoop:
		move $a0, $s1
		move $a1, $s2
		jal isPlatform
		beq $v0, $zero, finishDisplacingPlayer # if player not clipping, break the loop
		jal removePlayer
		addi $s2, $s2, 1 # attempt to move player down
		li $t0, 1
		j displacePlayerLoop
	
	finishDisplacingPlayer:
	
	la $t0, currentTick # load clock tick
	lw $t1, 0($t0)
	addi $t1, $t1, 1 # increment clock tick
	blt $t1, MAX_TICK_VALUE, saveClockTick # if tick is still below max, skip reseting it to zero
	move $t1, $zero
	saveClockTick:
	sw $t1, 0($t0)		# save clock tick

	la $t0, invincibility
	lw $t1, 0($t0) 
	subi $t1, $t1, 1
	bgtz $t1, mainLoop_skipResetInvincibility
	move $t1, $zero
	mainLoop_skipResetInvincibility:
	sw $t1, 0($t0)

	la $t0, lessGravity
	lw $t1, 0($t0) 
	subi $t1, $t1, 1
	bgtz $t1, mainLoop_skipResetLessGravity
	move $t1, $zero
	mainLoop_skipResetLessGravity:
	sw $t1, 0($t0)
	
	li $a0, 1
	jal drawPlatforms

	jal drawPlayer	

	jal updateScoreDisplay	# draw score at top

	jal updateHealthDisplay	# draw health at top

	la $t3, currentLevel	# load current level
	lw $t3, 0($t3)
	li $a0, 30
	li $a1, 1 
	addi $a2, $t3, 1		
	li $a3, 0x177a33		# draw level number at top
	jal drawDigit	

	# erase and redraw objects on screen
	
	jal checkPickups # check pickups colisions

	jal checkLevelComplete	# check if player has won the level (all coins cleared)
	
	jal drawPickups	# erase and redraw pickups on screen

	jal drawEnemies # draw enemies 

	jal checkLevelFail # check if player has lost (zero health)

	move $a0, $s1 # check if currently clipping into enemy
	move $a1, $s2 
	jal checkEnemies
	beq $v0, 1, finishCheckingEnemies # don't check further if already clipped enemy

	finishCheckingEnemies:

	# check if player is in contact with enemies

	# sleep until next iteration
	li $v0, 32		# set syscall to sleep
	li $a0, SLEEP_DURATION  # set sleep duration to default screen refresh delay
	syscall
	
	j mainLoop
	
	li $v0, 10 # exit program
	syscall
		
# Return the address to print to, using the values stored in $a0, $a1
calculateAddress:	

	# save vars
	addi $sp, $sp, -16
	sw $t0, 0($sp)
	sw $t2, 4($sp)
	sw $t3, 8($sp)
	sw $a0, 12($sp)
	
	li $t0, BASE_ADDRESS		# initialize base address
	mul $t2, $a0, MEM_WORD_SIZE 	# calculate x offset from x coord
	add $t0, $t0, $t2 		# add x offset
	mul $t3, $a1, MEM_VERT_OFFSET	# calculate y offset from y coord
	add $v0, $t0, $t3		# add y offset
	
	# retrieve vars	
	lw $t0, 0($sp)
	lw $t2, 4($sp)
	lw $t3, 8($sp)
	lw $a0, 12($sp)
	addi $sp, $sp, 16
	
	jr $ra				# return from calculateCoord

removePlayerTop: 

	addi $sp, $sp, -16
	sw $t1, 0($sp)
	sw $t2, 4($sp)
	sw $t3, 8($sp)
	sw $ra, 12($sp)

	move $a0, $s1 			# pass x coord as args
	move $a1, $s2			# pass y coord as args
	jal calculateAddress		# calculate address
	
	li $t1, BACKGROUND_COLOR
	move $t3, $v0
	blez $a1, removePlayerTop_return

	subi $t3, $t3, MEM_VERT_OFFSET
	sw $t1, 0($t3)
	sw $t1, 4($t3)
	sw $t1, 8($t3)
	sw $t1, 12($t3)
	sw $t1, 16($t3)
	sw $t1, 20($t3)
	sw $t1, 24($t3)
	
	removePlayerTop_return:
	lw $t1, 0($sp)
	lw $t2, 4($sp)
	lw $t3, 8($sp)
	lw $ra, 12($sp)
	addi $sp, $sp, 16
	
	jr $ra
	
removePlayerLeft:
	addi $sp, $sp, -16
	sw $t1, 0($sp)
	sw $t2, 4($sp)
	sw $t3, 8($sp)
	sw $ra, 12($sp)

	move $a0, $s1 			# pass x coord as args
	move $a1, $s2			# pass y coord as args
	jal calculateAddress		# calculate address
	
	li $t1, BACKGROUND_COLOR
	move $t3, $v0

	blez $s1, removePlayerLeft_return
	sw $t1, -4($t3)
	addi $t3, $t3, MEM_VERT_OFFSET
	sw $t1, -4($t3)
	addi $t3, $t3, MEM_VERT_OFFSET
	sw $t1, -4($t3)
	addi $t3, $t3, MEM_VERT_OFFSET
	sw $t1, -4($t3)
	addi $t3, $t3, MEM_VERT_OFFSET
	sw $t1, -4($t3)
	addi $t3, $t3, MEM_VERT_OFFSET
	sw $t1, -4($t3)
	addi $t3, $t3, MEM_VERT_OFFSET
	sw $t1, -4($t3)
	addi $t3, $t3, MEM_VERT_OFFSET
	sw $t1, -4($t3)
	addi $t3, $t3, MEM_VERT_OFFSET
	sw $t1, -4($t3)
	
	removePlayerLeft_return:
	lw $t1, 0($sp)
	lw $t2, 4($sp)
	lw $t3, 8($sp)
	lw $ra, 12($sp)
	addi $sp, $sp, 16
	
	jr $ra
	
removePlayerRight:
	addi $sp, $sp, -16
	sw $t1, 0($sp)
	sw $t2, 4($sp)
	sw $t3, 8($sp)
	sw $ra, 12($sp)

	move $a0, $s1 			# pass x coord as args
	move $a1, $s2			# pass y coord as args
	jal calculateAddress		# calculate address
	
	li $t1, BACKGROUND_COLOR
	move $t3, $v0

	bge $s1, WIDTH_INDEX, removePlayerRight_return
	sw $t1, 28($t3)
	addi $t3, $t3, MEM_VERT_OFFSET
	sw $t1, 28($t3)
	addi $t3, $t3, MEM_VERT_OFFSET
	sw $t1, 28($t3)
	addi $t3, $t3, MEM_VERT_OFFSET
	sw $t1, 28($t3)
	addi $t3, $t3, MEM_VERT_OFFSET
	sw $t1, 28($t3)
	addi $t3, $t3, MEM_VERT_OFFSET
	sw $t1, 28($t3)
	addi $t3, $t3, MEM_VERT_OFFSET
	sw $t1, 28($t3)
	addi $t3, $t3, MEM_VERT_OFFSET
	sw $t1, 28($t3)
	addi $t3, $t3, MEM_VERT_OFFSET
	sw $t1, 28($t3)
	
	removePlayerRight_return:
	lw $t1, 0($sp)
	lw $t2, 4($sp)
	lw $t3, 8($sp)
	lw $ra, 12($sp)
	addi $sp, $sp, 16
	
	jr $ra

removePlayer:	# paint over the player to erase it

	addi $sp, $sp, -20
	sw $a0, 0($sp)
	sw $a1, 4($sp)
	sw $t1, 8($sp)
	sw $t2, 12($sp)
	sw $ra, 16($sp)

	move $a0, $s1 			# pass x coord as args
	move $a1, $s2			# pass y coord as args
	jal calculateAddress		# calculate address
	li $t1, BACKGROUND_COLOR 	# $t1 stores background color
	
	li $t2, PLAYER_HEIGHT
	removePlayerLoop:
		sw $t1, 0($v0)
		sw $t1, 4($v0)
		sw $t1, 8($v0)
		sw $t1, 12($v0)
		sw $t1, 16($v0)
		sw $t1, 20($v0)
		sw $t1, 24($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		subi $t2, $t2, 1
		bgtz $t2, removePlayerLoop

	lw $a0, 0($sp)
	lw $a1, 4($sp)
	lw $t1, 8($sp)
	lw $t2, 12($sp)
	lw $ra, 16($sp)
	addi $sp, $sp, 20
	
	jr $ra

drawPlayer:		# draw player character
	addi $sp, $sp, -44
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $t3, 12($sp)
	sw $t4, 16($sp)
	sw $t5, 20($sp)
	sw $t6, 24($sp)
	sw $t7, 28($sp)
	sw $t8, 32($sp)
	sw $t9, 36($sp)
	sw $ra, 40($sp)

	move $a0, $s1 			# pass x coord as args
	move $a1, $s2			# pass y coord as args
	jal calculateAddress		# calculate address

	la $t1, playerDirection
	lb $t1, 0($t1) 
	beq $t1, PLAYER_DIR_RIGHT, drawPlayerRight
	beq $t1, PLAYER_DIR_FRONT, drawPlayerFront
	beq $t1, PLAYER_DIR_LEFT, drawPlayerLeft

	drawPlayerRight:

	li $t1, 0x3f51b5
	li $t3, 0x613d24 # brown
	li $t4, 0xe0ac69 # skin color
	li $t5, 0xe53935 # red
	li $t6, 0x795548 # brown
	li $t7, 0xd32f2f # dark red

	la $t8, lessGravity
	lw $t8, 0($t8)
	blez $t8, drawPlayerRight_useNormalColor # if no less gravity effect, use normal color
	li $t8, 0xed1c23 # backpack red 
	li $t2, 0xe83740 # pants red
	j drawPlayerRight_continue 
	drawPlayerRight_useNormalColor:
	li $t8, 0x009688 # backpack blue
	li $t2, 0x607d8b # pants blue
	drawPlayerRight_continue:


	li $t9, 0x090300
	sw $t9, 0($v0)
	sw $zero, 4($v0)
	sw $t5, 8($v0)
	sw $t5, 12($v0)
	sw $t5, 16($v0)
	sw $t5, 20($v0)
	sw $t9, 24($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t9, 0($v0)
	sw $zero, 4($v0)
	sw $t7, 8($v0)
	sw $t7, 12($v0)
	sw $t7, 16($v0)
	sw $t7, 20($v0)
	sw $t7, 24($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $zero, 0($v0)
	sw $t3, 4($v0)
	sw $t4, 8($v0)
	sw $t6, 12($v0)
	sw $t4, 16($v0)
	sw $t6, 20($v0)
	sw $zero, 24($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $zero, 0($v0)
	sw $t8, 4($v0)
	sw $t4, 8($v0)
	sw $t4, 12($v0)
	sw $t4, 16($v0)
	sw $t4, 20($v0)
	sw $zero, 24($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t8, 0($v0)
	sw $t8, 4($v0)
	sw $t1, 8($v0)
	sw $t1, 12($v0)
	sw $t1, 16($v0)
	sw $t1, 20($v0)
	sw $zero, 24($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t8, 0($v0)
	sw $t8, 4($v0)
	sw $t4, 8($v0)
	sw $t1, 12($v0)
	sw $t1, 16($v0)
	sw $t1, 20($v0)
	sw $t4, 24($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t8, 0($v0)
	sw $t8, 4($v0)
	sw $t4, 8($v0)
	sw $t1, 12($v0)
	sw $t1, 16($v0)
	sw $t1, 20($v0)
	sw $t4, 24($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $zero, 0($v0)
	sw $t2, 4($v0)
	sw $t2, 8($v0)
	sw $zero, 12($v0)
	sw $t2, 16($v0)
	sw $t2, 20($v0)
	sw $zero, 24($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t9, 0($v0)
	sw $t2, 4($v0)
	sw $t2, 8($v0)
	sw $zero, 12($v0)
	sw $t2, 16($v0)
	sw $t2, 20($v0)
	sw $t9, 24($v0)

	j drawPlayerFinish

	drawPlayerLeft:

	li $t1, 0xe0ac69
    li $t2, 0x009688
    li $t3, 0x090300
    li $t4, 0x795548
    li $t5, 0xd32f2f
    li $t6, 0x607d8b
    li $t7, 0xe53935
    li $t8, 0x3f51b5
    li $t9, 0x613d24

	la $t6, lessGravity
	lw $t6, 0($t6)
	blez $t6, drawPlayerLeft_useNormalColor # if no less gravity effect, use normal color
	li $t2, 0xed1c23 # backpack red 
	li $t6, 0xe83740 # pants red
	j drawPlayerLeft_continue 
	drawPlayerLeft_useNormalColor:
	li $t2, 0x009688 # backpack blue
	li $t6, 0x607d8b # pants blue
	drawPlayerLeft_continue:

    sw $t3, 0($v0)
    sw $t7, 4($v0)
    sw $t7, 8($v0)
    sw $t7, 12($v0)
    sw $t7, 16($v0)
    sw $zero, 20($v0)
    sw $t3, 24($v0)
    addi $v0, $v0, MEM_VERT_OFFSET
    sw $t5, 0($v0)
    sw $t5, 4($v0)
    sw $t5, 8($v0)
    sw $t5, 12($v0)
    sw $t5, 16($v0)
    sw $zero, 20($v0)
    sw $t3, 24($v0)
    addi $v0, $v0, MEM_VERT_OFFSET
    sw $zero, 0($v0)
    sw $t4, 4($v0)
    sw $t1, 8($v0)
    sw $t4, 12($v0)
    sw $t1, 16($v0)
    sw $t9, 20($v0)
    sw $zero, 24($v0)
    addi $v0, $v0, MEM_VERT_OFFSET
    sw $zero, 0($v0)
    sw $t1, 4($v0)
    sw $t1, 8($v0)
    sw $t1, 12($v0)
    sw $t1, 16($v0)
    sw $t2, 20($v0)
    sw $zero, 24($v0)
    addi $v0, $v0, MEM_VERT_OFFSET
    sw $zero, 0($v0)
    sw $t8, 4($v0)
    sw $t8, 8($v0)
    sw $t8, 12($v0)
    sw $t8, 16($v0)
    sw $t2, 20($v0)
    sw $t2, 24($v0)
    addi $v0, $v0, MEM_VERT_OFFSET
    sw $t1, 0($v0)
    sw $t8, 4($v0)
    sw $t8, 8($v0)
    sw $t8, 12($v0)
    sw $t1, 16($v0)
    sw $t2, 20($v0)
    sw $t2, 24($v0)
    addi $v0, $v0, MEM_VERT_OFFSET
    sw $t1, 0($v0)
    sw $t8, 4($v0)
    sw $t8, 8($v0)
    sw $t8, 12($v0)
    sw $t1, 16($v0)
    sw $t2, 20($v0)
    sw $t2, 24($v0)
    addi $v0, $v0, MEM_VERT_OFFSET
    sw $zero, 0($v0)
    sw $t6, 4($v0)
    sw $t6, 8($v0)
    sw $zero, 12($v0)
    sw $t6, 16($v0)
    sw $t6, 20($v0)
    sw $zero, 24($v0)
    addi $v0, $v0, MEM_VERT_OFFSET
    sw $t3, 0($v0)
    sw $t6, 4($v0)
    sw $t6, 8($v0)
    sw $zero, 12($v0)
    sw $t6, 16($v0)
    sw $t6, 20($v0)
    sw $t3, 24($v0)


	j drawPlayerFinish
	
	drawPlayerFront:
    li $t2, 0x090300
    li $t3, 0xd32f2f
    li $t4, 0x795548
    li $t5, 0x9c5a3c
    li $t7, 0xe0ac69
    li $t8, 0x3f51b5
    li $t9, 0xe53935

	la $t6, lessGravity
	lw $t6, 0($t6)
	blez $t6, drawPlayerFront_useNormalColor # if no less gravity effect, use normal color
	li $t6, 0xed1c23 # backpack red 
	li $t1, 0xe83740 # pants red
	j drawPlayerFront_continue 
	drawPlayerFront_useNormalColor:
	li $t6, 0x009688 # backpack blue
	li $t1, 0x607d8b # pants blue
	drawPlayerFront_continue:

    sw $t2, 0($v0)
    sw $t9, 4($v0)
    sw $t9, 8($v0)
    sw $t9, 12($v0)
    sw $t9, 16($v0)
    sw $t9, 20($v0)
    sw $t2, 24($v0)
    addi $v0, $v0, MEM_VERT_OFFSET
    sw $t2, 0($v0)
    sw $t3, 4($v0)
    sw $t3, 8($v0)
    sw $t3, 12($v0)
    sw $t3, 16($v0)
    sw $t3, 20($v0)
    sw $zero, 24($v0)
    addi $v0, $v0, MEM_VERT_OFFSET
    sw $zero, 0($v0)
    sw $t7, 4($v0)
    sw $t4, 8($v0)
    sw $t7, 12($v0)
    sw $t4, 16($v0)
    sw $t7, 20($v0)
    sw $zero, 24($v0)
    addi $v0, $v0, MEM_VERT_OFFSET
    sw $zero, 0($v0)
    sw $t7, 4($v0)
    sw $t7, 8($v0)
    sw $t7, 12($v0)
    sw $t7, 16($v0)
    sw $t7, 20($v0)
    sw $zero, 24($v0)
    addi $v0, $v0, MEM_VERT_OFFSET
    sw $t6, 0($v0)
    sw $t8, 4($v0)
    sw $t8, 8($v0)
    sw $t8, 12($v0)
    sw $t8, 16($v0)
    sw $t8, 20($v0)
    sw $t6, 24($v0)
    addi $v0, $v0, MEM_VERT_OFFSET
    sw $t6, 0($v0)
    sw $t7, 4($v0)
    sw $t8, 8($v0)
    sw $t8, 12($v0)
    sw $t8, 16($v0)
    sw $t7, 20($v0)
    sw $t6, 24($v0)
    addi $v0, $v0, MEM_VERT_OFFSET
    sw $t6, 0($v0)
    sw $t7, 4($v0)
    sw $t8, 8($v0)
    sw $t8, 12($v0)
    sw $t8, 16($v0)
    sw $t7, 20($v0)
    sw $t6, 24($v0)
    addi $v0, $v0, MEM_VERT_OFFSET
    sw $zero, 0($v0)
    sw $t1, 4($v0)
    sw $t1, 8($v0)
    sw $zero, 12($v0)
    sw $t1, 16($v0)
    sw $t1, 20($v0)
    sw $zero, 24($v0)
    addi $v0, $v0, MEM_VERT_OFFSET
    sw $t2, 0($v0)
    sw $t1, 4($v0)
    sw $t1, 8($v0)
    sw $zero, 12($v0)
    sw $t1, 16($v0)
    sw $t1, 20($v0)
    sw $t2, 24($v0)

	j drawPlayerFinish

	drawPlayerFinish:

	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $t3, 12($sp)
	lw $t4, 16($sp)
	lw $t5, 20($sp)
	lw $t6, 24($sp)
	lw $t7, 28($sp)
	lw $t8, 32($sp)
	lw $t9, 36($sp)
	lw $ra, 40($sp)
	addi $sp, $sp, 44

	jr $ra				# return from drawPlayer
	
# PICKUP LOGIC
initPickup: # initialize platform info for memory at index $t0, containing data in $t1-$t3
	la $t9, pickups 
	mul $t0, $t0, PICKUP_STRUCT_SIZE
	add $t0, $t9, $t0 
	sh $t1, 0($t0) # set x coordinate
	sh $t2, 2($t0) # set y coordinate
	sb $t3, 4($t0) # set effect / status
	sb $zero, 5($t0)
	jr $ra

drawSinglePickup: # draw the pickup stored at address $a0 from the screen
	
	addi $sp, $sp, -28
	sw $t0, 0($sp)
	sw $t1, 4($sp) 
	sw $t2, 8($sp) 
	sw $t3, 12($sp) 
	sw $t4, 16($sp) 
	sw $ra, 20($sp)
	sw $a0, 24($sp)
	
	# get address to draw pickup
	lw $t1, 24($sp)
	lh $a0, 0($t1) # load x coord
	lh $a1, 2($t1) # load y coord

	lb $t2, 5($t1) # load hover offset
	
	beq $t2, $zero, hover0
	beq $t2, 1, hover0  
	beq $t2, 2, hover1
	beq $t2, 3, hover2
	beq $t2, 4, hover2 
	beq $t2, 5, hover3
	li $t4, 1		# set flag to clear pixels above
	move $t2, $zero
	hover0: # no hover 
		addi $t2, $t2, 1 
		li $t4, 1		# set flag to clear pixels above
		j afterPickupHover
	hover1: # 1 unit above
		subi $a1, $a1, 1
		addi $t2, $t2, 1 
		li $t4, -1		# set flag to clear pixels below
		j afterPickupHover
	hover2: # 2 units above
		subi $a1, $a1, 2
		addi $t2, $t2, 1 
		li $t4, -1		# set flag to clear pixels below
		j afterPickupHover
	hover3:
		subi $a1, $a1, 1
		addi $t2, $t2, 1 
		li $t4, 1		# set flag to clear pixels above
		j afterPickupHover
	
	afterPickupHover:
	sb $t2, 5($t1) 

	jal calculateAddress 
	lw $a0, 24($sp)

	bne $t4, 1, skipClearingCoinAbove			# if we don't need to clear the row above the pickup, skip the next code block
		subi $v0, $v0, MEM_VERT_OFFSET # clear row above
		li $t3, BACKGROUND_COLOR
		sw $t3, 0($v0)
		sw $t3, 4($v0)	 	
		sw $t3, 8($v0)
		sw $t3, 12($v0)
		sw $t3, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		# draw 5x5 coin starting from top left corner
	skipClearingCoinAbove:

	lb $t1, 4($a0)	# load type 
	beq $t1, $zero, drawSinglePickupReturn # skip drawing if pickup empty 
	beq $t1, PICKUP_TYPE_COIN, drawCoin 		# if type == 1, draw coin
	beq $t1, PICKUP_TYPE_HEALTH, drawHealthPack 	# draw +1 health pack
	beq $t1, PICKUP_TYPE_INVINCIBILITY, drawInvincibility	# draw icon for invincibility effect
	beq $t1, PICKUP_TYPE_LESS_GRAVITY, drawLessGravity 	# draw icon for less gravity effect
	j erasePickup	# erase pickup if picked up
	
	drawCoin:
		li $t1, COIN_COLOR_1 # get colors
		li $t2, COIN_COLOR_2 
		li $t3, BACKGROUND_COLOR
		sw $t3, 0($v0)
		sw $t2, 4($v0)	 	
		sw $t2, 8($v0)
		sw $t2, 12($v0)
		sw $t3, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t2, 0($v0)
		sw $t1, 4($v0)	 	
		sw $t1, 8($v0)
		sw $t1, 12($v0)
		sw $t2, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t2, 0($v0)
		sw $t1, 4($v0)	 	
		sw $t1, 8($v0)
		sw $t1, 12($v0)
		sw $t2, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t2, 0($v0)
		sw $t1, 4($v0)	 	
		sw $t1, 8($v0)
		sw $t1, 12($v0)
		sw $t2, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t3, 0($v0)
		sw $t2, 4($v0)	 	
		sw $t2, 8($v0)
		sw $t2, 12($v0)
		sw $t3, 16($v0)
		
		j drawSinglePickupReturn
	drawHealthPack:
		li $t1, HEALTHPACK_COLOR_1 #red
		li $t2, HEALTHPACK_COLOR_2 #white
		li $t3, BACKGROUND_COLOR

		# draw 5x5 health pack starting from top left corner
		sw $t3, 0($v0)
		sw $t1, 4($v0)	 	
		sw $t1, 8($v0)
		sw $t1, 12($v0)
		sw $t3, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t1, 0($v0)
		sw $t1, 4($v0)	 	
		sw $t2, 8($v0)
		sw $t1, 12($v0)
		sw $t1, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t1, 0($v0)
		sw $t2, 4($v0)	 	
		sw $t2, 8($v0)
		sw $t2, 12($v0)
		sw $t1, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t1, 0($v0)
		sw $t1, 4($v0)	 	
		sw $t2, 8($v0)
		sw $t1, 12($v0)
		sw $t1, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t3, 0($v0)
		sw $t1, 4($v0)	 	
		sw $t1, 8($v0)
		sw $t1, 12($v0)
		sw $t3, 16($v0)
		
		j drawSinglePickupReturn 

	drawInvincibility:
		li $t1, 0x4d6df3
		li $t2, 0x00b7ef
		li $t3, BACKGROUND_COLOR
		sw $t1, 0($v0)
		sw $t3, 4($v0)
		sw $t3, 8($v0)
		sw $t3, 12($v0)
		sw $t1, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t2, 0($v0)
		sw $t1, 4($v0)
		sw $t2, 8($v0)
		sw $t1, 12($v0)
		sw $t2, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t1, 0($v0)
		sw $t2, 4($v0)
		sw $t1, 8($v0)
		sw $t2, 12($v0)
		sw $t1, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t2, 0($v0)
		sw $t1, 4($v0)
		sw $t2, 8($v0)
		sw $t1, 12($v0)
		sw $t2, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t3, 0($v0)
		sw $t2, 4($v0)
		sw $t1, 8($v0)
		sw $t2, 12($v0)
		sw $t3, 16($v0)
		j drawSinglePickupReturn

	drawLessGravity:
		li $t1, 0xff2453
		li $t2, 0x464646
		li $t3, BACKGROUND_COLOR
		sw $t3, 0($v0)
		sw $t1, 4($v0)
		sw $t1, 8($v0)
		sw $t1, 12($v0)
		sw $t3, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t1, 0($v0)
		sw $t1, 4($v0)
		sw $t1, 8($v0)
		sw $t1, 12($v0)
		sw $t1, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t3, 0($v0)
		sw $t3, 4($v0)
		sw $t2, 8($v0)
		sw $t3, 12($v0)
		sw $t3, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t3, 0($v0)
		sw $t3, 4($v0)
		sw $t2, 8($v0)
		sw $t3, 12($v0)
		sw $t3, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t3, 0($v0)
		sw $t3, 4($v0)
		sw $t3, 8($v0)
		sw $t2, 12($v0)
		sw $t3, 16($v0)
		j drawSinglePickupReturn

	erasePickup:
		li $t1, BACKGROUND_COLOR 
		subi $v0, $v0, MEM_VERT_OFFSET
		sw $t1, 0($v0)
		sw $t1, 4($v0)	 	
		sw $t1, 8($v0)
		sw $t1, 12($v0)
		sw $t1, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		# draw 5x5 coin starting from top left corner
		sw $t1, 0($v0)
		sw $t1, 4($v0)	 	
		sw $t1, 8($v0)
		sw $t1, 12($v0)
		sw $t1, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t1, 0($v0)
		sw $t1, 4($v0)	 	
		sw $t1, 8($v0)
		sw $t1, 12($v0)
		sw $t1, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t1, 0($v0)
		sw $t1, 4($v0)	 	
		sw $t1, 8($v0)
		sw $t1, 12($v0)
		sw $t1, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t1, 0($v0)
		sw $t1, 4($v0)	 	
		sw $t1, 8($v0)
		sw $t1, 12($v0)
		sw $t1, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t1, 0($v0)
		sw $t1, 4($v0)	 	
		sw $t1, 8($v0)
		sw $t1, 12($v0)
		sw $t1, 16($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t1, 0($v0)
		sw $t1, 4($v0)	 	
		sw $t1, 8($v0)
		sw $t1, 12($v0)
		sw $t1, 16($v0)
		j drawSinglePickupReturn

	drawSinglePickupReturn:

	bne $t4, -1, skipClearingCoinBelow		# if we don't need to clear the row below the coin, skip the next code block
		addi $v0, $v0, MEM_VERT_OFFSET
		li $t3, BACKGROUND_COLOR
		sw $t3, 0($v0)
		sw $t3, 4($v0)	 	
		sw $t3, 8($v0)
		sw $t3, 12($v0)
		sw $t3, 16($v0)
	skipClearingCoinBelow:

	lw $t0, 0($sp)
	lw $t1, 4($sp) 
	lw $t2, 8($sp) 
	lw $t3, 12($sp) 
	lw $t4, 16($sp) 
	lw $ra, 20($sp)
	lw $a0, 24($sp)
	addi $sp, $sp, 28

	jr $ra
	
drawPickups:
	# save registers to be used
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $t8, 4($sp)
	sw $t9, 8($sp)
	
	move $t8, $s6 	# get number of pickups to draw
	la $t9, pickups # get address of first element
	beq $t8, $zero, drawPickupLoopEnd # skip loop if no elements
	drawPickupLoop: # start of loop
		lb $a0, 4($t9)	# load type 
		bge $a0, 10, drawPickupLoopContinue # skip redrawing empty pickups
		move $a0, $t9
		jal drawSinglePickup
		drawPickupLoopContinue:
			subi $t8, $t8, 1
			addi $t9, $t9, PICKUP_STRUCT_SIZE
			bgt $t8, $zero, drawPickupLoop # iterate if remaining pickups to draw
		
	drawPickupLoopEnd: # break/end of loop
	# restore registers
	lw $ra, 0($sp)
	lw $t8, 4($sp)
	lw $t9, 8($sp)
	addi $sp, $sp, 12
	
	jr $ra
	
checkPickups: # check if player location is currently over pickup, and make effect if it is 
	# save variables
	addi $sp, $sp, -28
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $t3, 12($sp)
	sw $t7, 16($sp)
	sw $t8, 20($sp)
	sw $ra, 24($sp)
	
	move $t8, $s6			# load number of pickups into $t0
	la $t7, pickups		# load the address of the array
	beq $t8, $zero, checkPickupReturn
	checkPickupLoop:
		lh $t0, 0($t7)		# load x coord of pickup
		lh $t1, 2($t7)		# load y coord of pickup
		
		lb $t3, 5($t7) # load hover offset
	
		# account for pickup hovering
		beq $t3, $zero, checkPickupAfterHover
		beq $t3, 1, checkPickupAfterHover  
		beq $t3, 2, checkPickupHover1
		beq $t3, 3, checkPickupHover2
		beq $t3, 4, checkPickupHover2 
		beq $t3, 5, checkPickupHover1
		checkPickupHover1: # no hover 
			subi $t1, $t1, 1 
			j checkPickupAfterHover
		checkPickupHover2: # 2 units above
			subi $t1, $t1, 2
	
		checkPickupAfterHover:
		
		# a1 = player corner 
		# x-coord: if player left > platform right, skip
		add $t3, $t0, PICKUP_WIDTH # calculate pickup right x
		subi $t3, $t3, 1
		bgt $s1, $t3, checkPickupIterate
		
		# x-coord if platform left > player left
		addi $t3, $s1, PLAYER_WIDTH
		subi $t3, $t3, 1
		bgt $t0, $t3, checkPickupIterate
		
		# y-coord if player right < platform left
		addi $t3, $s2, PLAYER_HEIGHT 
		subi $t3, $t3, 1 
		blt $t3, $t1, checkPickupIterate 
		
		# y-coord if platform right < player left
		addi $t3, $t1, PICKUP_HEIGHT
		subi $t3, $t3, 1
		blt $t3, $s2, checkPickupIterate
		
		# else, we found overlap
		lb $t2, 4($t7)		# load type of pickup
		beq $t2, PICKUP_TYPE_COIN, checkPickupCoinEffect
		beq $t2, PICKUP_TYPE_HEALTH, checkPickupHealthEffect
		beq $t2, PICKUP_TYPE_INVINCIBILITY, checkPickupInvincibilityEffect 
		beq $t2, PICKUP_TYPE_LESS_GRAVITY, checkPickupLessGravityEffect
		j checkPickupIterate
		checkPickupCoinEffect:
			addi $s4, $s4, POINTS_PER_COIN  # add points to player
			li $t2, PICKUP_TYPE_INACTIVE # invalidate pickup
			sb $t2, 4($t7)
			jal updateScoreDisplay
			move $a0, $t7
			jal drawSinglePickup
			j checkPickupIterate
		checkPickupHealthEffect:
			addi $s3, $s3, HEALTH_PER_PACK # add health points to player
			li $t2, PICKUP_TYPE_INACTIVE # invalidate pickup
			sb $t2, 4($t7)
			jal updateHealthDisplay
			move $a0, $t7
			jal drawSinglePickup
			j checkPickupIterate
		checkPickupInvincibilityEffect:
			li $t2, INVINCIBILITY_TICKS_PER_PACK
			la $t3, invincibility
			sw $t2, 0($t3)					# give player invincibility
			li $t2, PICKUP_TYPE_INACTIVE 	# invalidate pickup
			sb $t2, 4($t7)
			move $a0, $t7		
			jal drawSinglePickup			# erase from screen
			j checkPickupIterate

		checkPickupLessGravityEffect:
			li $t2, LESS_GRAVITY_TICKS_PER_PACK
			la $t3, lessGravity
			sw $t2, 0($t3)					# give player invincibility
			li $t2, PICKUP_TYPE_INACTIVE 	# invalidate pickup
			sb $t2, 4($t7)
			move $a0, $t7
			jal drawSinglePickup			# erase from screen
			j checkPickupIterate
	checkPickupIterate:
		addi $t7, $t7, PICKUP_STRUCT_SIZE
		subi $t8, $t8, 1
		bgt $t8, $zero, checkPickupLoop
	move $v0, $zero
	checkPickupReturn:
	# restore vars
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $t3, 12($sp)
	lw $t7, 16($sp)
	lw $t8, 20($sp)
	lw $ra, 24($sp)
	addi $sp, $sp, 28
		
	jr $ra
	

# ENEMY LOGIC
initEnemy: # initialize enemy info into memory at index $t0, with data in $t0 - $t4

	la $t9, enemies # get addr of first element
	mul $t0, $t0, ENEMY_STRUCT_SIZE
	add $t0, $t0, $t9 # get addr of desired index

	la $t9, platforms
	mul $t1, $t1, PLATFORM_STRUCT_SIZE
	add $t1, $t1, $t9
	sw $t1, 0($t0) 	# addr of platform patrolled
	sh $t2, 4($t0)	# current coord of enemy within platform
	sb $t3, 6($t0) 	# movement behavior (0 = moving, 2 = stationary)
	sb $t4, 7($t0) 	# behavior when defeated (0 = already defeated)

	jr $ra

checkEnemies: # check if ($a0, $a1) collides with enemy
	# save variables
	addi $sp, $sp, -28
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $t3, 12($sp)
	sw $t7, 16($sp)
	sw $t8, 20($sp)
	sw $ra, 24($sp)
	
	move $t8, $s5			# load number of enemies into $t8
	la $t7, enemies			# load the address of the array
	beq $t8, $zero, checkEnemyReturn
	checkEnemyLoop:
		lb $t0, 7($t7)    # check type
		beq $t0, $zero, checkEnemyIterate # ignore dead enemies
		
		lw $t0, 0($t7)		# load address of platform
		lh $t1, 8($t0) 		# load y coord of platform 
		lh $t0, 4($t0)		# load x coord of platform
		
		subi $t1, $t1, ENEMY_HEIGHT 	# account for enemy height
		lh $t3, 4($t7)		# load current offset position
		add $t0, $t0, $t3			# account for movement of enemy
		
		# compare player coords ($a0, $a1) with enemy coords ($t0, $t1)
		# x-coord: if player left > enemy right, skip
		addi $t3, $t0, ENEMY_WIDTH # calculate enemy right x
		subi $t3, $t3, 1
		bgt $a0, $t3, checkEnemyIterate 
		
		# x-coord if enemy left > player right
		addi $t3, $a0, PLAYER_WIDTH
		subi $t3, $t3, 1
		bgt $t0, $t3, checkEnemyIterate
		
		# y-coord if player right < platform left
		addi $t3, $a1, PLAYER_HEIGHT 
		subi $t3, $t3, 1 
		blt $t3, $t1, checkEnemyIterate 
		
		# y-coord if platform right < player left
		addi $t3, $t1, ENEMY_HEIGHT
		subi $t3, $t3, 1
		blt $t3, $a1, checkEnemyIterate

		# collision! 
		li $v0, 1 
		la $t1, invincibility 
		lw $t1, 0($t1) 
		blez $t1, killPlayer # if not invincible/protected, harm player
		# else, kill the enemy
		killEnemy:
			sb $zero, 7($t7) # set type to 0 
			addi $s4, $s4, POINTS_PER_ENEMY # add points to player for kills
			move $a0, $t7

			la $t1, invincibility
			sw $zero, 0($t1)		# reset invincibility to zero

			jal drawSingleEnemy # redraw to hide it 
			jal updateScoreDisplay # update display
			j checkEnemyReturn
		killPlayer:
			# harm player
			subi $s3, $s3, 1 	# subtract health by one 
			jal updateHealthDisplay	# update display
			jal removePlayer
			la $t3, currentLevel	# load current level
			lw $t3, 0($t3)
			mul $t3, $t3, 4
			la $t2, spawn_locs_x	# load addr of spawn array
			add $t2, $t2, $t3 		# calculate addr of coord
			lw $s1, 0($t2)			# set player x coord to level spawn location
			
			la $t2, spawn_locs_y	# load addr of spawn array
			add $t2, $t2, $t3 		# calculate addr of coord
			lw $s2, 0($t2)			# set player y coord to level spawn location

			la $t1, invincibility
			sw $zero, 0($t1)		# reset invincibility to zero

			la $t1, lessGravity
			sw $zero, 0($t1)		# reset lessGravity to zero

			j checkEnemyReturn

	checkEnemyIterate:
		addi $t7, $t7, ENEMY_STRUCT_SIZE
		subi $t8, $t8, 1
		bgt $t8, $zero, checkEnemyLoop
	move $v0, $zero
	
	checkEnemyReturn:
	# restore vars
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $t3, 12($sp)
	lw $t7, 16($sp)
	lw $t8, 20($sp)
	lw $ra, 24($sp)
	addi $sp, $sp, 28
		
	jr $ra

drawSingleEnemy: # draw a single enemy, stored at addr $a0
	# save registers used
	addi $sp, $sp, -36
	sw $t0, 0($sp)
	sw $t1, 4($sp) 
	sw $t2, 8($sp) 
	sw $t3, 12($sp) 
	sw $t4, 16($sp)
	sw $t5, 20($sp)
	sw $t6, 24($sp)
	sw $a0, 28($sp) 
	sw $ra, 32($sp)

	move $t3, $a0

	lw $t1, 0($t3)	# load index of platform this enemy is on 
	lh $a0, 4($t3) # get location of enemy on platform
	lh $a1, 8($t1) # get y-coord of platform
	lh $t0, 4($t1) # get x-coord of platform 
	
	lb $t6, 6($t3) # get enemy movement type 
	
	beq $t6, 2, endEnemyMovement # if movement type is stationary, skip movement calculations
	
	la $t5, currentTick
	lw $t5, 0($t5) 		# load the current tick
	li $t4, ENEMY_MOVEMENT_TICK_DELAY
	div $t5, $t4 		# divide current tick by tick delay
	mfhi $t5
	bne $t5, $zero, endEnemyMovement # skip movement logic if not on tick

	beq $t6, 1, moveEnemyLeftCheck
	beq $t6, 0, moveEnemyRightCheck
	j endEnemyMovement
	moveEnemyRightCheck:
		lh $t4, 6($t1) # load platform length
		subi $t4, $t4, ENEMY_WIDTH # calculate furthest index to move to
		bge $a0, $t4, moveEnemyLeft # if enemy at right edge, move left
		moveEnemyRight:
			addi $a0, $a0, 1 # move enemy one right
			sh $a0, 4($t3)	# save new location
			sb $zero, 6($t3) # set enemy to point right 
		j endEnemyMovement
	moveEnemyLeftCheck:
		ble $a0, $zero, moveEnemyRight # if enemy on left edge, move right
		moveEnemyLeft:
			subi $a0, $a0, 1 # move enemy one left 
			sh $a0, 4($t3) # save new location
			li $t6, 1 
			sb $t6, 6($t3) # set enemy to point left
		j endEnemyMovement
		
	endEnemyMovement:	
	add $a0, $t0, $a0 # account for offset
	subi $a1, $a1, ENEMY_HEIGHT	# calculate top left corner of enemy
	jal calculateAddress # calculate address to draw to

	lb $t4, 7($t3) # get enemy type 
	# branch based on enemy type
	beq $t4, 0, drawEmptyEnemy
	beq $t4, 1, drawNormalEnemy

	j drawSingleEnemyReturn  # else, don't do anything
	drawEmptyEnemy:
		# draw over the space
		li $t1, BACKGROUND_COLOR
		sw $t1, -4($v0)
		sw $t1, 0($v0)
		sw $t1, 4($v0)
		sw $t1, 8($v0)
		sw $t1, 12($v0)
		sw $t1, 16($v0)
		sw $t1, 20($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t1, -4($v0)
		sw $t1, 0($v0)
		sw $t1, 4($v0)
		sw $t1, 8($v0)
		sw $t1, 12($v0)
		sw $t1, 16($v0)
		sw $t1, 20($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t1, -4($v0)
		sw $t1, 0($v0)
		sw $t1, 4($v0)
		sw $t1, 8($v0)
		sw $t1, 12($v0)
		sw $t1, 16($v0)
		sw $t1, 20($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t1, -4($v0)
		sw $t1, 0($v0)
		sw $t1, 4($v0)
		sw $t1, 8($v0)
		sw $t1, 12($v0)
		sw $t1, 16($v0)
		sw $t1, 20($v0)
		addi $v0, $v0, MEM_VERT_OFFSET
		sw $t1, -4($v0)
		sw $t1, 0($v0)
		sw $t1, 4($v0)
		sw $t1, 8($v0)
		sw $t1, 12($v0)
		sw $t1, 16($v0)
		sw $t1, 20($v0)
		j drawSingleEnemyReturn
	drawNormalEnemy:
		lb $t4, 6($t3) # get enemy movement type
		beq $t4, 1, drawNormalEnemyLeft
			# else, draw right facing enemy
			li $t1, ENEMY_BODY_COLOR
			li $t2, ENEMY_EYES_COLOR
			li $t4, ENEMY_DARK_COLOR
			li $t3, BACKGROUND_COLOR
			sw $t3, -8($v0)
			sw $t3, -4($v0)
			sw $t3, 0($v0)
			sw $t3, 4($v0)
			sw $t4, 8($v0)
			sw $t3, 12($v0)
			sw $t4, 16($v0)
			addi $v0, $v0, MEM_VERT_OFFSET
			sw $t3, -8($v0)
			sw $t3, -4($v0)
			sw $t4, 0($v0)
			sw $t4, 4($v0)
			sw $t4, 8($v0)
			sw $t4, 12($v0)
			sw $t4, 16($v0)
			addi $v0, $v0, MEM_VERT_OFFSET
			sw $t3, -8($v0)
			sw $t3, -4($v0)
			sw $t4, 0($v0)
			sw $t1, 4($v0)
			sw $t2, 8($v0)
			sw $t1, 12($v0)
			sw $t2, 16($v0)
			addi $v0, $v0, MEM_VERT_OFFSET
			sw $t3, -8($v0)
			sw $t3, -4($v0)
			sw $t4, 0($v0)
			sw $t1, 4($v0)
			sw $t1, 8($v0)
			sw $t1, 12($v0)
			sw $t1, 16($v0)
			addi $v0, $v0, MEM_VERT_OFFSET
			sw $t3, -8($v0)
			sw $t3, -4($v0)
			sw $t3, 0($v0)
			sw $t4, 4($v0)
			sw $t3, 8($v0)
			sw $t4, 12($v0)
			sw $t3, 16($v0)
			j drawSingleEnemyReturn
		drawNormalEnemyLeft:
			# draw left facing enemy
			li $t1, ENEMY_BODY_COLOR
			li $t2, ENEMY_EYES_COLOR
			li $t4, ENEMY_DARK_COLOR
			li $t3, BACKGROUND_COLOR
			sw $t4, 0($v0)
			sw $t3, 4($v0)
			sw $t4, 8($v0)
			sw $t3, 12($v0)
			sw $t3, 16($v0)
			sw $t3, 20($v0)
			sw $t3, 24($v0)
			addi $v0, $v0, MEM_VERT_OFFSET
			sw $t4, 0($v0)
			sw $t4, 4($v0)
			sw $t4, 8($v0)
			sw $t4, 12($v0)
			sw $t4, 16($v0)
			sw $t3, 20($v0)
			sw $t3, 24($v0)
			addi $v0, $v0, MEM_VERT_OFFSET
			sw $t2, 0($v0)
			sw $t1, 4($v0)
			sw $t2, 8($v0)
			sw $t1, 12($v0)
			sw $t4, 16($v0)
			sw $t3, 20($v0)
			sw $t3, 24($v0)
			addi $v0, $v0, MEM_VERT_OFFSET
			sw $t1, 0($v0)
			sw $t1, 4($v0)
			sw $t1, 8($v0)
			sw $t1, 12($v0)
			sw $t4, 16($v0)
			sw $t3, 20($v0)
			sw $t3, 24($v0)
			addi $v0, $v0, MEM_VERT_OFFSET
			sw $t3, 0($v0)
			sw $t4, 4($v0)
			sw $t3, 8($v0)
			sw $t4, 12($v0)
			sw $t3, 16($v0)
			sw $t3, 20($v0)
			sw $t3, 24($v0)
			j drawSingleEnemyReturn
	drawSingleEnemyReturn:
	# restore registers used
	lw $t0, 0($sp)
	lw $t1, 4($sp) 
	lw $t2, 8($sp) 
	lw $t3, 12($sp) 
	lw $t4, 16($sp)
	lw $t5, 20($sp)
	lw $t6, 24($sp)
	lw $a0, 28($sp) 
	lw $ra, 32($sp)
	addi $sp, $sp, 36

	jr $ra

drawEnemies: # update and draw enemy locations
	# save registers used 
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $t8, 4($sp)
	sw $t9, 8($sp)
	
	move $t8, $s5 	# get number of enemies to draw
	beq $t8, $zero, drawEnemiesLoopEnd # skip loop if no elements
	la $t9, enemies # get address of first element
	drawEnemiesLoop: # start of loop
		lb $a0, 7($t9)	# load type 
		beq $a0, 0, drawEnemiesLoopContinue # skip drawing enemies that are defeated
		move $a0, $t9
		jal drawSingleEnemy
		drawEnemiesLoopContinue:
			subi $t8, $t8, 1
			addi $t9, $t9, ENEMY_STRUCT_SIZE
			bgt $t8, $zero, drawEnemiesLoop # iterate if remaining pickups to draw
		
	drawEnemiesLoopEnd: # break/end of loop
	# restore registers
	lw $ra, 0($sp)
	lw $t8, 4($sp)
	lw $t9, 8($sp)
	addi $sp, $sp, 12
	
	jr $ra

# PLATFORM LOGIC
initPlatform: # initialize platform info for memory at index $t0, containing data in $t1-$t6
	la $t9, platforms
	mul $t0, $t0, PLATFORM_STRUCT_SIZE # get memory offset based on element, with 12 bytes per element
	add $t0, $t9, $t0 # calculate memory location of index
	
	sh $t1, 0($t0) # set initial left x coord of platform
	sh $t2, 2($t0) # set final left x coord
	sh $t3, 4($t0) # set current x coord of platform
	sh $t4, 6($t0) # set length of platform
	sh $t5, 8($t0) # set y coord
	sb $t6, 10($t0) # set movement direction (0 = towards end, 1 = towards beginning)
	
	jr $ra
	
isPlatform: # Is ($a0, $a1) a platform? Set v0 to 1 if yes, 0 otherwise.

	# save variables
	addi $sp, $sp, -24
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $t3, 12($sp)
	sw $t7, 16($sp)
	sw $t8, 20($sp)
	
	move $t8, $s7			# load number of platforms into $t0
	la $t7, platforms		# load the address of the array
	standingOnPlatformLoop:
		lh $t0, 4($t7)		# load x coord of platform
		lh $t1, 8($t7)		# load y coord of platform
		lh $t2, 6($t7)		# load length of platform
		
		# a1 = player corner 
		# x-coord: if player left > platform right, skip
		add $t3, $t0, $t2 # calculate platform right x
		subi $t3, $t3, 1
		bgt $a0, $t3, standingOnPlatformLoopIterate 
		
		# x-coord if platform left > player left
		addi $t3, $a0, PLAYER_WIDTH
		subi $t3, $t3, 1
		bgt $t0, $t3, standingOnPlatformLoopIterate
		
		# y-coord if player right < platform left
		addi $t3, $a1, PLAYER_HEIGHT 
		subi $t3, $t3, 1 
		blt $t3, $t1, standingOnPlatformLoopIterate 
		
		# y-coord if platform right < player left
		addi $t3, $t1, PLATFORM_THICKNESS
		subi $t3, $t3, 1
		blt $t3, $a1, standingOnPlatformLoopIterate
		
		addi $v0, $zero, 1 # else, we found overlap
		
		# restore vars	
		lw $t0, 0($sp)
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		lw $t3, 12($sp)
		lw $t7, 16($sp)
		lw $t8, 20($sp)
		addi $sp, $sp, -24
		
		jr $ra 			# stop looking

	standingOnPlatformLoopIterate:
		addi $t7, $t7, PLATFORM_STRUCT_SIZE
		subi $t8, $t8, 1
		bgt $t8, $zero, standingOnPlatformLoop
	move $v0, $zero
	
	# restore vars
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $t3, 12($sp)
	lw $t7, 16($sp)
	lw $t8, 20($sp)
	addi $sp, $sp, 24
		
	jr $ra
	
drawPlatforms: # draw platforms. If $a0 == 1, draw the delta and not the full platform
	# save temp variables
	addi $sp, $sp, -36
	sw $t0, 0($sp)
	sw $t2, 4($sp)
	sw $t3, 8($sp)
	sw $t5, 12($sp)
	sw $t6, 16($sp)
	sw $t7, 20($sp)
	sw $t8, 24($sp)
	sw $t9, 28($sp)
	sw $ra, 32($sp)
		
	move $t8, $s7			# load number of platforms into $t0
	la $t7, platforms		# load the address of the array
	drawPlatformsLoop:
		lh $a0, 4($t7)		# pass x coord as args
		lh $a1, 8($t7)		# pass y coord as args

		la $t2, currentTick
		lw $t3, 0($t2) 
		li $t6, PLATFORM_MOVEMENT_TICK_DELAY
		div $t3, $t6
		mfhi $t3
		bne $t3, $zero, drawPlatformsIgnoreMovement # ignore movement if tick is not multiple of platform ticks
	
		lh $t3, 2($t7) # load rightmost x coord
		lh $t2, 0($t7) # load leftmost x coord
		beq $t3, $t2, drawPlatformsIgnoreMovement # check edge case where leftmost == rightmost
		# calculate platform movement
		lb $t2, 10($t7)		# load the current movement direction of platform
		beq $t2, 1, movePlatformLeft # if movement == 1, move platform leftwards
		beq $t2, 0, movePlatformRight # if movement == 0, move platform rightwards
		
		drawPlatformsIgnoreMovement:
			jal calculateAddress
			beq $a0, 1, drawPlatformsLoopIterate # if argument is to optimize drawing, then skip stationary platforms
			j drawPlatformToScreen # if movement type is stationary, skip logic

		movePlatformRight:
			lh $t3, 2($t7) # load rightmost x coord
			lh $t2, 0($t7) # load leftmost x coord
			beq $t3, $t2, drawPlatformToScreen # check edge case where leftmost == rightmost
			bge $a0, $t3, movePlatformLeft # if current x >= rightmost x, then move left
			addi $a0, $a0, 1 # move platform right 1
			sh $a0, 4($t7)
			li $t3, 0
			sb $t3, 10($t7) # ensure stored movement direction is towards the right

			jal calculateAddress # calculate address of top left 
			ble $a0, $zero, drawPlatformToScreen # if top left is already zero, don't bother clearing left
			subi $t5, $v0, 4
			
			li $t6, PLATFORM_THICKNESS
			li $t3, BACKGROUND_COLOR
			clearMovingPlatformLeftLoop:
				sw $t3, 0($t5)
				subi $t6, $t6, 1
				addi $t5, $t5, MEM_VERT_OFFSET
				bgtz $t6, clearMovingPlatformLeftLoop # loop if remaining pixels to clear

			j drawPlatformToScreen
			
		movePlatformLeft:
			lh $t3, 2($t7) # load rightmost x coord
			lh $t2, 0($t7) # load leftmost x coord
			beq $t3, $t2, drawPlatformToScreen # check edge case where leftmost == rightmost
			ble $a0, $t2, movePlatformRight # if current x <= leftmost x, then move right
			subi $a0, $a0, 1 # move platform left 1
			sh $a0, 4($t7)
			li $t3, 1
			sb $t3, 10($t7) # ensure stored movement direction is towards the left

			jal calculateAddress
			
			lh $t3, 6($t7) # load length
			lh $t0, 4($t7) # load current x coord
			# check if the square to the right is not offscreen
			add $t0, $t3, $t0  # calculate right most index
			bgt $t0, WIDTH_INDEX, drawPlatformToScreen # if index is off screen, skip clearing right

			mul $t3, $t3, 4 	# multiply length by pixel size
			add $t3, $t3, $v0 	# add to address
			li $t6, PLATFORM_THICKNESS
			li $t5, BACKGROUND_COLOR
			clearMovingPlatformRightLoop: # loop to clear the pixels directly to the right of the platform, to support movement left
				sw $t5, 0($t3)
				subi $t6, $t6, 1
				addi $t3, $t3, MEM_VERT_OFFSET
				bgtz $t6, clearMovingPlatformRightLoop # loop if remaining pixels to clear

			j drawPlatformToScreen
			
		drawPlatformToScreen: # important: keep $v0 = calculated pixel address
			lb $t5, 10($t7)		# load the current movement direction of platform
			lh $t2, 6($t7) 		# load length 
			drawPlatformLength:
				move $t5, $v0
				li $t6, 6
				div $t2, $t6 
				mfhi $t6
						

				beq $t6, $zero, drawPlatform_segment1
				beq $t6, 1, drawPlatform_segment1
				beq $t6, 2, drawPlatform_segment2
				beq $t6, 3, drawPlatform_segment2
				beq $t6, 4, drawPlatform_segment3
				beq $t6, 5, drawPlatform_segment2

				drawPlatform_segment1:	
					li $t6, PLATFORM_GRASS_TOP # grass top color
					sw $t6, 0($t5)
					addi $t5, $t5, MEM_VERT_OFFSET
					sw $t6, 0($t5)
					li $t6, PLATFORM_GRASS_UNDER # grass underside color
					addi $t5, $t5, MEM_VERT_OFFSET
					sw $t6, 0($t5)
					li $t6, PLATFORM_DIRT # dirt color
					addi $t5, $t5, MEM_VERT_OFFSET
					sw $t6, 0($t5)
					li $t6, PLATFORM_ROCK
					addi $t5, $t5, MEM_VERT_OFFSET
					sw $t6, 0($t5)
					j drawPlatform_afterDrawingSegment

				drawPlatform_segment2:
					li $t6, PLATFORM_GRASS_TOP # grass top color
					sw $t6, 0($t5)
					li $t6, PLATFORM_GRASS_UNDER # grass underside color
					addi $t5, $t5, MEM_VERT_OFFSET
					sw $t6, 0($t5)
					li $t6, PLATFORM_DIRT # dirt color
					addi $t5, $t5, MEM_VERT_OFFSET
					sw $t6, 0($t5)
					addi $t5, $t5, MEM_VERT_OFFSET
					sw $t6, 0($t5)
					li $t6, PLATFORM_ROCK
					addi $t5, $t5, MEM_VERT_OFFSET
					sw $t6, 0($t5)
					j drawPlatform_afterDrawingSegment

				drawPlatform_segment3:
					li $t6, PLATFORM_GRASS_TOP # grass top color
					sw $t6, 0($t5)
					li $t6, PLATFORM_GRASS_UNDER # grass underside color
					addi $t5, $t5, MEM_VERT_OFFSET
					sw $t6, 0($t5)
					addi $t5, $t5, MEM_VERT_OFFSET
					sw $t6, 0($t5)
					li $t6, PLATFORM_DIRT # dirt color
					addi $t5, $t5, MEM_VERT_OFFSET
					sw $t6, 0($t5)
					li $t6, PLATFORM_ROCK
					addi $t5, $t5, MEM_VERT_OFFSET
					sw $t6, 0($t5)

				drawPlatform_afterDrawingSegment:	
				subi $t2, $t2, 1 # decrement length 
				addi $v0, $v0, 4 # move to next pixel
				bgt $t2, $zero, drawPlatformLength # iterate again if length remaining	


		drawPlatformsLoopIterate:	
			addi $t7, $t7, PLATFORM_STRUCT_SIZE # increment address within platforms
			subi $t8, $t8, 1 # decrement number of platforms remaining
			bgt $t8, $zero, drawPlatformsLoop # iterate again if platforms remain
		
		# li $v0, 1       	# load system call code for printing integer (1)
		# move $a0, $t0   	# move the value in $t0 to $a0 argument register
		# syscall
	# retrieve stored vars
	lw $t0, 0($sp)
	lw $t2, 4($sp)
	lw $t3, 8($sp)
	lw $t5, 12($sp)
	lw $t6, 16($sp)
	lw $t7, 20($sp)
	lw $t8, 24($sp)
	lw $t9, 28($sp)
	lw $ra, 32($sp)
	addi $sp, $sp, 36
	
	jr $ra 

# Clear the screen 
clearScreen: 
	# t1 = number of units, t0 = current address, t2 = loop variable, t3 = background fill color
	li $t1, WIDTH
	mul $t1, $t1, HEIGHT		# calculate # of units to fill
	addi $t2, $zero, 0 # loop index variable
	li $t0, BASE_ADDRESS
	li $t3, BACKGROUND_COLOR
	clearScreenLoop:
	sw $t3, 0($t0)
	addi $t0, $t0, MEM_WORD_SIZE
	addi $t2, $t2, 1
	blt $t2, $t1, clearScreenLoop
	jr $ra
	
moveRight: 
	li $t0, WIDTH
	subi $t0, $t0, PLAYER_WIDTH

	bge $s1, $t0, afterKeyPress # prevent going off right side
	add $a0, $s1, 1
	move $a1, $s2
	jal isPlatform
	bne $v0, $zero, afterKeyPress 	# prevent from running into platform
	addi $s1, $s1, 1		# move x coord right by 1
	jal removePlayerLeft		# update left pixels

	addi $sp, $sp, -8
	lw $t0, 0($sp)
	lw $t1, 4($sp)

	la $t0, playerDirection
	li $t1, PLAYER_DIR_RIGHT	
	sb $t1, 0($t0)	# set player to face right

	sw $t0, 0($sp)
	sw $t1, 4($sp)
	addi $sp, $sp, 8

	j afterKeyPress
moveLeft:   # attempt to move player right 1 square (no args)

	ble $s1, 0, afterKeyPress 		# prevent going off left side
	sub $a0, $s1, 1
	move $a1, $s2
	jal isPlatform
	bne $v0, $zero, afterKeyPress 	# prevent from running into platform
	subi $s1, $s1, 1		# move x coord left by 1
	jal removePlayerRight		# update right pixels

	addi $sp, $sp, -8
	lw $t0, 0($sp)
	lw $t1, 4($sp)

	la $t0, playerDirection
	li $t1, PLAYER_DIR_LEFT
	sb $t1, 0($t0)	# set player to face left
	
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	addi $sp, $sp, 8

	j afterKeyPress 
moveUp:	# attempt to make player jump (no args)
	move $a0, $s1 
	add $a1, $s2, 1
	jal isPlatform			# check if standing on platform
	beq $v0, $zero, afterKeyPress	# prevent jumping if not on platform
	la $t0, velocity 		# load velocity
	lw $t1, 0($t0)			# load current velocity
	bgt $t1, 0, afterKeyPress	# prevent jump if velocity already greater than zero
	
	li $t1, JUMP_ACCEL		# accelerate player to simulate jump
	sw $t1, 0($t0)			# update current velocity

	addi $sp, $sp, -8
	lw $t0, 0($sp)
	lw $t1, 4($sp)

	la $t0, playerDirection
	li $t1, PLAYER_DIR_FRONT
	sb $t1, 0($t0)	# set player to face forward
	
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	addi $sp, $sp, 8

	j afterKeyPress

# DISPLAY LOGIC
updateHealthDisplay:
	addi $sp, $sp, -12 	# save vars
	sw $ra, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)

	move $t9, $ra # save old return address
	
	# Draw heart
	li $a0, WIDTH		# draw top corner 1 unit from top
	li $a1, 1
	subi $a0, $a0, 6	# draw top corner of heart 6 units from the right side
	jal calculateAddress	# calculate memory address of top corner

	la $t1, invincibility
	lw $t1, 0($t1)	
	blez $t1, updateHealthDisplay_useNormalColors  # set colors based in invincibility status
		li $t1, 0x00b7ef	# load colors
		j updateHealthDisplay_afterSetColors
	updateHealthDisplay_useNormalColors:
		li $t1, HEALTH_COLOR	# load colors
	updateHealthDisplay_afterSetColors:
	li $t2, BACKGROUND_COLOR # load colors
	# draw heart icon
	sw $t1, 0($v0)
	sw $t1, 4($v0)
	sw $t2, 8($v0)
	sw $t1, 12($v0)
	sw $t1, 16($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t1, 0($v0)
	sw $t1, 4($v0)
	sw $t1, 8($v0)
	sw $t1, 12($v0)
	sw $t1, 16($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t1, 0($v0)
	sw $t1, 4($v0)
	sw $t1, 8($v0)
	sw $t1, 12($v0)
	sw $t1, 16($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 0($v0)
	sw $t1, 4($v0)
	sw $t1, 8($v0)
	sw $t1, 12($v0)
	sw $t2, 16($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 0($v0)
	sw $t2, 4($v0)
	sw $t1, 8($v0)
	sw $t2, 12($v0)
	sw $t2, 16($v0)
	
	# Draw ones digit of health
	li $a0, WIDTH
	subi $a0, $a0, 11
	li $a1, 1
	li $t0, 10
	div $s3, $t0
	mfhi $a2
	move $a3, $t1
	jal drawDigit
	
	lw $ra, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	addi $sp, $sp, 12
	
	jr $ra 

updateScoreDisplay:
	addi $sp, $sp, -8 	# save return address
	sw $ra, 0($sp)
	sw $t0, 4($sp)
	
	li $a0, 6 # show digit at ($a0, $a1)
	li $a1, 1
	li $a3, SCORE_COLOR
	li $a2, 10  	# calculate remainder after div by 10
	div $s4, $a2	
	mfhi $a2
	jal drawDigit 
	
	li $a0, 1 # show digit at ($a0, $a1)
	li $a1, 1
	li $a3, SCORE_COLOR
	li $a2, 100  	# get remainder after div by 100
	div $s4, $a2	
	mfhi $a2
	li $t0, 10 	# divide by 10 to get tens digit in quotient
	div $a2, $t0
	mflo $a2
	jal drawDigit 
	
	lw $ra, 0($sp)
	lw $t0, 4($sp)
	addi $sp, $sp, 8
	jr $ra

drawDigit: # at the specified coordinate ($a0, $a1) draw the digit $a2 using color $a3
	move $t2, $ra	# save old ra to return this function
	jal calculateAddress
	move $t0, $v0 # use $t0 to track coord we are printing to
	addi $t1, $zero, 0x212121 # color for empty pixels
	
	beq $a2, 1, drawOne 
	beq $a2, 2, drawTwo 
	beq $a2, 3, drawThree
	beq $a2, 4, drawFour
	beq $a2, 5, drawFive
	beq $a2, 6, drawSix
	beq $a2, 7, drawSeven
	beq $a2, 8, drawEight
	beq $a2, 9, drawNine
	drawZero:
	sw $a3, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $t1, 4($t0) 
	sw $t1, 8($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $a3, 12($t0)
	jr $t2
	drawOne:
	sw $t1, 0($t0)
	sw $t1, 4($t0) 
	sw $t1, 8($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $t1, 4($t0) 
	sw $t1, 8($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $t1, 4($t0) 
	sw $t1, 8($t0)
	sw $a3, 12($t0)
	jr $t2
	drawTwo:
	sw $a3, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $a3, 12($t0)
	jr $t2
	drawThree:
	sw $a3, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $t1, 12($t0)
	jr $t2
	drawFour:
	sw $a3, 0($t0)
	sw $t1, 4($t0) 
	sw $t1, 8($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $t1, 4($t0) 
	sw $t1, 8($t0)
	sw $a3, 12($t0)
	jr $t2
	drawFive:
	sw $a3, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $t1, 12($t0)
	jr $t2
	drawSix:
	sw $t1, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $t1, 12($t0)
	jr $t2
	drawSeven:
	sw $a3, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $t1, 4($t0) 
	sw $t1, 8($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $t1, 4($t0) 
	sw $t1, 8($t0)
	sw $a3, 12($t0)
	jr $t2
	drawEight:
	sw $t1, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $t1, 12($t0)
	jr $t2
	drawNine:
	sw $t1, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $a3, 0($t0)
	sw $a3, 12($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t1, 0($t0)
	sw $a3, 4($t0) 
	sw $a3, 8($t0)
	sw $t1, 12($t0)
	jr $t2

# LEVEL LOGIC

resetLevel:	
	jal clearScreen

	addi $s0, $zero, 0     # set screen state to default 
	addi $s1, $zero, 0     # set starting x coordinate of player 
	addi $s2, $zero, 0     # set starting y coordinate of player
	addi $s3, $zero, 3     # set starting health
	addi $s4, $zero, 0     # set starting points 
 	addi $s5, $zero, 0     # set number of enemies active
	addi $s6, $zero, 0     # set number of platforms active 
	addi $s7, $zero, 0     # set number of pickups active
	la $t0, velocity
	sw $zero, 0($t0)  	# set zero velocity
	# check for keyboard input		

	la $t3, currentLevel	# load current level
	lw $t3, 0($t3)
	bge $t3, 3, resetLevel_showWinSceen

	mul $t3, $t3, 4
	la $t2, spawn_locs_x	# load addr of spawn array
	add $t2, $t2, $t3 		# calculate addr of coord
	lw $s1, 0($t2)			# set player x coord to level spawn location
	
	la $t2, spawn_locs_y	# load addr of spawn array
	add $t2, $t2, $t3 		# calculate addr of coord
	lw $s2, 0($t2)			# set player y coord to level spawn location

	la $t3, lessGravity 	# reset ticks of decreased gravity
	sw $zero, 0($t3)

	la $t3, invincibility	# reset ticks of invincibility remaining
	sw $zero, 0($t3)

	la $t3, currentLevel	# load current level
	lw $t3, 0($t3)
	bge $t3, 3, resetLevel_showWinSceen

	beq $t3, 0, level_one # TODO: change label to reenable level 1
	beq $t3, 1, level_two
	beq $t3, 2, level_three

	resetLevel_showWinSceen:
	jal drawWinScreen 
	j waitUntilSpace

checkLevelComplete: # check if the current level is complete (all coins collected). If complete, initialize the next level

	addi $sp, $sp, -16
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $ra, 12($sp)

	la $t0, pickups
	move $t1, $s6 
	checkLevelCompleteLoop:
		lb $t2, 4($t0) # load type of pickup 
		beq $t2, PICKUP_TYPE_COIN, checkLevelCompleteFoundCoin # break if found coin not picked up yet
		subi $t1, $t1, 1 # decrement coins
		addi $t0, $t0, PICKUP_STRUCT_SIZE # increment address 
		bgtz $t1, checkLevelCompleteLoop # if remaining pickups to consider, iterate

	# no coins!
	la $t0, currentLevel 
	lw $t1, 0($t0) # load level number 
	addi $t1, $t1, 1

	la $t2, pointsAtStart
	sw $t1, 0($t0) # save new level number
	beq $t1, 1, checkLevelComplete_saveLevel1Score
	beq $t1, 2, checkLevelComplete_saveLevel2Score 
	checkLevelComplete_saveLevel1Score:
	sw $s4, 4($t2)
	checkLevelComplete_saveLevel2Score:
	sw $s4, 8($t2)

	skipSavingScore:

	bge $t1, 3, checkLevelComplete_win
	
	jal drawLevelClearedScreen

	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $ra, 12($sp)
	addi $sp, $sp, 16

	j waitUntilSpace		

	checkLevelComplete_win:

	la $t2, pointsAtStart
	sw $zero, 0($t2)
	sw $zero, 4($t2)
	sw $zero, 8($t2)

	jal drawWinScreen
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $ra, 12($sp)
	addi $sp, $sp, 16

	j waitUntilSpace		# return from function by entering a loop
		
	checkLevelCompleteFoundCoin: # jump here if there are remaining coins

	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $ra, 12($sp)
	addi $sp, $sp, 16
	jr $ra 

checkLevelFail: # Show the level failure screen if the player's health is zero
	
	blez $s3, checkLevel_showFailScreen # if hp == 0, draw fail screen
	jr $ra # else, return to normal gameplay

	checkLevel_showFailScreen:

	addi $sp, $sp, -4 # Save old $ra to the stack
	sw $ra, 0($sp)
	jal clearScreen

	li $a0, 48 # write ones digit of score
	li $a1, 33
	li $a3, SCORE_COLOR
	li $a2, 10  	# calculate remainder after div by 10
	div $s4, $a2	
	mfhi $a2
	jal drawDigit 
	
	li $a0, 43 # write tens digit of score
	li $a1, 33
	li $a3, SCORE_COLOR
	li $a2, 100  	# get remainder after div by 100
	div $s4, $a2	
	mfhi $a2
	li $t0, 10 	# divide by 10 to get tens digit in quotient
	div $a2, $t0
	mflo $a2
	jal drawDigit 

	li $t1, 0x00b7ef
li $t2, 0x7a1414
li $t3, 0xffc30e
li $t4, 0xad2d2d
li $t5, 0x941818
li $t6, 0xe53935
li $v0, BASE_ADDRESS
li $t0, MEM_VERT_OFFSET
mul $t0, $t0, 3
add $v0, $v0, $t0
sw $t2, 12($v0)
sw $t2, 16($v0)
sw $t2, 20($v0)
sw $t2, 24($v0)
sw $t2, 28($v0)
sw $t2, 32($v0)
sw $t2, 36($v0)
sw $t2, 40($v0)
sw $t2, 44($v0)
sw $t2, 48($v0)
sw $t2, 52($v0)
sw $t2, 56($v0)
sw $t2, 60($v0)
sw $t2, 64($v0)
sw $t2, 68($v0)
sw $t2, 72($v0)
sw $t2, 76($v0)
sw $t2, 80($v0)
sw $t2, 84($v0)
sw $t2, 88($v0)
sw $t2, 92($v0)
sw $t2, 96($v0)
sw $t2, 100($v0)
sw $t2, 104($v0)
sw $t2, 108($v0)
sw $t2, 112($v0)
sw $t2, 116($v0)
sw $t2, 120($v0)
sw $t2, 124($v0)
sw $t2, 128($v0)
sw $t2, 132($v0)
sw $t2, 136($v0)
sw $t2, 140($v0)
sw $t2, 144($v0)
sw $t2, 148($v0)
sw $t2, 152($v0)
sw $t2, 156($v0)
sw $t2, 160($v0)
sw $t2, 164($v0)
sw $t2, 168($v0)
sw $t2, 172($v0)
sw $t2, 176($v0)
sw $t2, 180($v0)
sw $t2, 184($v0)
sw $t2, 188($v0)
sw $t2, 192($v0)
sw $t2, 196($v0)
sw $t2, 200($v0)
sw $t2, 204($v0)
sw $t2, 208($v0)
sw $t2, 212($v0)
sw $t2, 216($v0)
sw $t2, 220($v0)
sw $t2, 224($v0)
sw $t2, 228($v0)
sw $t2, 232($v0)
sw $t2, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t5, 16($v0)
sw $t5, 20($v0)
sw $t5, 24($v0)
sw $t5, 28($v0)
sw $t5, 32($v0)
sw $t5, 36($v0)
sw $t5, 40($v0)
sw $t5, 44($v0)
sw $t5, 48($v0)
sw $t5, 52($v0)
sw $t5, 56($v0)
sw $t5, 60($v0)
sw $t5, 64($v0)
sw $t5, 68($v0)
sw $t5, 72($v0)
sw $t5, 76($v0)
sw $t5, 80($v0)
sw $t5, 84($v0)
sw $t5, 88($v0)
sw $t5, 92($v0)
sw $t5, 96($v0)
sw $t5, 100($v0)
sw $t5, 104($v0)
sw $t5, 108($v0)
sw $t5, 112($v0)
sw $t5, 116($v0)
sw $t5, 120($v0)
sw $t5, 124($v0)
sw $t5, 128($v0)
sw $t5, 132($v0)
sw $t5, 136($v0)
sw $t5, 140($v0)
sw $t5, 144($v0)
sw $t5, 148($v0)
sw $t5, 152($v0)
sw $t5, 156($v0)
sw $t5, 160($v0)
sw $t5, 164($v0)
sw $t5, 168($v0)
sw $t5, 172($v0)
sw $t5, 176($v0)
sw $t5, 180($v0)
sw $t5, 184($v0)
sw $t5, 188($v0)
sw $t5, 192($v0)
sw $t5, 196($v0)
sw $t5, 200($v0)
sw $t5, 204($v0)
sw $t5, 208($v0)
sw $t5, 212($v0)
sw $t5, 216($v0)
sw $t5, 220($v0)
sw $t5, 224($v0)
sw $t5, 228($v0)
sw $t5, 232($v0)
sw $t5, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t5, 16($v0)
sw $t4, 20($v0)
sw $t4, 24($v0)
sw $t4, 28($v0)
sw $t4, 32($v0)
sw $t4, 36($v0)
sw $t4, 40($v0)
sw $t4, 44($v0)
sw $t4, 48($v0)
sw $t4, 52($v0)
sw $t4, 56($v0)
sw $t4, 60($v0)
sw $t4, 64($v0)
sw $t4, 68($v0)
sw $t4, 72($v0)
sw $t4, 76($v0)
sw $t4, 80($v0)
sw $t4, 84($v0)
sw $t4, 88($v0)
sw $t4, 92($v0)
sw $t4, 96($v0)
sw $t4, 100($v0)
sw $t4, 104($v0)
sw $t4, 108($v0)
sw $t4, 112($v0)
sw $t4, 116($v0)
sw $t4, 120($v0)
sw $t4, 124($v0)
sw $t4, 128($v0)
sw $t4, 132($v0)
sw $t4, 136($v0)
sw $t4, 140($v0)
sw $t4, 144($v0)
sw $t4, 148($v0)
sw $t4, 152($v0)
sw $t4, 156($v0)
sw $t4, 160($v0)
sw $t4, 164($v0)
sw $t4, 168($v0)
sw $t4, 172($v0)
sw $t4, 176($v0)
sw $t4, 180($v0)
sw $t4, 184($v0)
sw $t4, 188($v0)
sw $t4, 192($v0)
sw $t4, 196($v0)
sw $t4, 200($v0)
sw $t4, 204($v0)
sw $t4, 208($v0)
sw $t4, 212($v0)
sw $t4, 216($v0)
sw $t4, 220($v0)
sw $t4, 224($v0)
sw $t4, 228($v0)
sw $t4, 232($v0)
sw $t5, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t5, 16($v0)
sw $t4, 20($v0)
sw $t4, 232($v0)
sw $t5, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t5, 16($v0)
sw $t4, 20($v0)
sw $t4, 232($v0)
sw $t5, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t5, 16($v0)
sw $t4, 20($v0)
sw $t6, 76($v0)
sw $t6, 96($v0)
sw $t6, 100($v0)
sw $t6, 104($v0)
sw $t6, 108($v0)
sw $t6, 116($v0)
sw $t6, 132($v0)
sw $t6, 140($v0)
sw $t6, 144($v0)
sw $t6, 148($v0)
sw $t6, 152($v0)
sw $t6, 160($v0)
sw $t4, 232($v0)
sw $t5, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t5, 16($v0)
sw $t4, 20($v0)
sw $t6, 76($v0)
sw $t6, 96($v0)
sw $t6, 116($v0)
sw $t6, 132($v0)
sw $t6, 140($v0)
sw $t6, 160($v0)
sw $t4, 232($v0)
sw $t5, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t5, 16($v0)
sw $t4, 20($v0)
sw $t6, 76($v0)
sw $t6, 96($v0)
sw $t6, 100($v0)
sw $t6, 104($v0)
sw $t6, 120($v0)
sw $t6, 128($v0)
sw $t6, 140($v0)
sw $t6, 144($v0)
sw $t6, 148($v0)
sw $t6, 160($v0)
sw $t4, 232($v0)
sw $t5, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t5, 16($v0)
sw $t4, 20($v0)
sw $t6, 76($v0)
sw $t6, 96($v0)
sw $t6, 120($v0)
sw $t6, 128($v0)
sw $t6, 140($v0)
sw $t6, 160($v0)
sw $t4, 232($v0)
sw $t5, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t5, 16($v0)
sw $t4, 20($v0)
sw $t6, 76($v0)
sw $t6, 80($v0)
sw $t6, 84($v0)
sw $t6, 88($v0)
sw $t6, 96($v0)
sw $t6, 100($v0)
sw $t6, 104($v0)
sw $t6, 108($v0)
sw $t6, 124($v0)
sw $t6, 140($v0)
sw $t6, 144($v0)
sw $t6, 148($v0)
sw $t6, 152($v0)
sw $t6, 160($v0)
sw $t6, 164($v0)
sw $t6, 168($v0)
sw $t6, 172($v0)
sw $t4, 232($v0)
sw $t5, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t5, 16($v0)
sw $t4, 20($v0)
sw $t4, 232($v0)
sw $t5, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t5, 16($v0)
sw $t4, 20($v0)
sw $t6, 68($v0)
sw $t6, 72($v0)
sw $t6, 76($v0)
sw $t6, 80($v0)
sw $t6, 92($v0)
sw $t6, 96($v0)
sw $t6, 108($v0)
sw $t6, 112($v0)
sw $t6, 116($v0)
sw $t6, 124($v0)
sw $t6, 144($v0)
sw $t6, 148($v0)
sw $t6, 152($v0)
sw $t6, 156($v0)
sw $t6, 164($v0)
sw $t6, 168($v0)
sw $t6, 172($v0)
sw $t4, 232($v0)
sw $t5, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t5, 16($v0)
sw $t4, 20($v0)
sw $t6, 68($v0)
sw $t6, 88($v0)
sw $t6, 100($v0)
sw $t6, 112($v0)
sw $t6, 124($v0)
sw $t6, 144($v0)
sw $t6, 164($v0)
sw $t6, 176($v0)
sw $t4, 232($v0)
sw $t5, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t5, 16($v0)
sw $t4, 20($v0)
sw $t6, 68($v0)
sw $t6, 72($v0)
sw $t6, 76($v0)
sw $t6, 88($v0)
sw $t6, 92($v0)
sw $t6, 96($v0)
sw $t6, 100($v0)
sw $t6, 112($v0)
sw $t6, 124($v0)
sw $t6, 144($v0)
sw $t6, 148($v0)
sw $t6, 152($v0)
sw $t6, 164($v0)
sw $t6, 176($v0)
sw $t4, 232($v0)
sw $t5, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t5, 16($v0)
sw $t4, 20($v0)
sw $t6, 68($v0)
sw $t6, 88($v0)
sw $t6, 100($v0)
sw $t6, 112($v0)
sw $t6, 124($v0)
sw $t6, 144($v0)
sw $t6, 164($v0)
sw $t6, 176($v0)
sw $t4, 232($v0)
sw $t5, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t5, 16($v0)
sw $t4, 20($v0)
sw $t6, 68($v0)
sw $t6, 88($v0)
sw $t6, 100($v0)
sw $t6, 108($v0)
sw $t6, 112($v0)
sw $t6, 116($v0)
sw $t6, 124($v0)
sw $t6, 128($v0)
sw $t6, 132($v0)
sw $t6, 136($v0)
sw $t6, 144($v0)
sw $t6, 148($v0)
sw $t6, 152($v0)
sw $t6, 156($v0)
sw $t6, 164($v0)
sw $t6, 168($v0)
sw $t6, 172($v0)
sw $t4, 232($v0)
sw $t5, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t5, 16($v0)
sw $t4, 20($v0)
sw $t4, 232($v0)
sw $t5, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t5, 16($v0)
sw $t4, 20($v0)
sw $t4, 232($v0)
sw $t5, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t5, 16($v0)
sw $t4, 20($v0)
sw $t4, 232($v0)
sw $t5, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t5, 16($v0)
sw $t4, 20($v0)
sw $t4, 24($v0)
sw $t4, 28($v0)
sw $t4, 32($v0)
sw $t4, 36($v0)
sw $t4, 40($v0)
sw $t4, 44($v0)
sw $t4, 48($v0)
sw $t4, 52($v0)
sw $t4, 56($v0)
sw $t4, 60($v0)
sw $t4, 64($v0)
sw $t4, 68($v0)
sw $t4, 72($v0)
sw $t4, 76($v0)
sw $t4, 80($v0)
sw $t4, 84($v0)
sw $t4, 88($v0)
sw $t4, 92($v0)
sw $t4, 96($v0)
sw $t4, 100($v0)
sw $t4, 104($v0)
sw $t4, 108($v0)
sw $t4, 112($v0)
sw $t4, 116($v0)
sw $t4, 120($v0)
sw $t4, 124($v0)
sw $t4, 128($v0)
sw $t4, 132($v0)
sw $t4, 136($v0)
sw $t4, 140($v0)
sw $t4, 144($v0)
sw $t4, 148($v0)
sw $t4, 152($v0)
sw $t4, 156($v0)
sw $t4, 160($v0)
sw $t4, 164($v0)
sw $t4, 168($v0)
sw $t4, 172($v0)
sw $t4, 176($v0)
sw $t4, 180($v0)
sw $t4, 184($v0)
sw $t4, 188($v0)
sw $t4, 192($v0)
sw $t4, 196($v0)
sw $t4, 200($v0)
sw $t4, 204($v0)
sw $t4, 208($v0)
sw $t4, 212($v0)
sw $t4, 216($v0)
sw $t4, 220($v0)
sw $t4, 224($v0)
sw $t4, 228($v0)
sw $t4, 232($v0)
sw $t5, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t5, 16($v0)
sw $t5, 20($v0)
sw $t5, 24($v0)
sw $t5, 28($v0)
sw $t5, 32($v0)
sw $t5, 36($v0)
sw $t5, 40($v0)
sw $t5, 44($v0)
sw $t5, 48($v0)
sw $t5, 52($v0)
sw $t5, 56($v0)
sw $t5, 60($v0)
sw $t5, 64($v0)
sw $t5, 68($v0)
sw $t5, 72($v0)
sw $t5, 76($v0)
sw $t5, 80($v0)
sw $t5, 84($v0)
sw $t5, 88($v0)
sw $t5, 92($v0)
sw $t5, 96($v0)
sw $t5, 100($v0)
sw $t5, 104($v0)
sw $t5, 108($v0)
sw $t5, 112($v0)
sw $t5, 116($v0)
sw $t5, 120($v0)
sw $t5, 124($v0)
sw $t5, 128($v0)
sw $t5, 132($v0)
sw $t5, 136($v0)
sw $t5, 140($v0)
sw $t5, 144($v0)
sw $t5, 148($v0)
sw $t5, 152($v0)
sw $t5, 156($v0)
sw $t5, 160($v0)
sw $t5, 164($v0)
sw $t5, 168($v0)
sw $t5, 172($v0)
sw $t5, 176($v0)
sw $t5, 180($v0)
sw $t5, 184($v0)
sw $t5, 188($v0)
sw $t5, 192($v0)
sw $t5, 196($v0)
sw $t5, 200($v0)
sw $t5, 204($v0)
sw $t5, 208($v0)
sw $t5, 212($v0)
sw $t5, 216($v0)
sw $t5, 220($v0)
sw $t5, 224($v0)
sw $t5, 228($v0)
sw $t5, 232($v0)
sw $t5, 236($v0)
sw $t2, 240($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t2, 12($v0)
sw $t2, 16($v0)
sw $t2, 20($v0)
sw $t2, 24($v0)
sw $t2, 28($v0)
sw $t2, 32($v0)
sw $t2, 36($v0)
sw $t2, 40($v0)
sw $t2, 44($v0)
sw $t2, 48($v0)
sw $t2, 52($v0)
sw $t2, 56($v0)
sw $t2, 60($v0)
sw $t2, 64($v0)
sw $t2, 68($v0)
sw $t2, 72($v0)
sw $t2, 76($v0)
sw $t2, 80($v0)
sw $t2, 84($v0)
sw $t2, 88($v0)
sw $t2, 92($v0)
sw $t2, 96($v0)
sw $t2, 100($v0)
sw $t2, 104($v0)
sw $t2, 108($v0)
sw $t2, 112($v0)
sw $t2, 116($v0)
sw $t2, 120($v0)
sw $t2, 124($v0)
sw $t2, 128($v0)
sw $t2, 132($v0)
sw $t2, 136($v0)
sw $t2, 140($v0)
sw $t2, 144($v0)
sw $t2, 148($v0)
sw $t2, 152($v0)
sw $t2, 156($v0)
sw $t2, 160($v0)
sw $t2, 164($v0)
sw $t2, 168($v0)
sw $t2, 172($v0)
sw $t2, 176($v0)
sw $t2, 180($v0)
sw $t2, 184($v0)
sw $t2, 188($v0)
sw $t2, 192($v0)
sw $t2, 196($v0)
sw $t2, 200($v0)
sw $t2, 204($v0)
sw $t2, 208($v0)
sw $t2, 212($v0)
sw $t2, 216($v0)
sw $t2, 220($v0)
sw $t2, 224($v0)
sw $t2, 228($v0)
sw $t2, 232($v0)
sw $t2, 236($v0)
sw $t2, 240($v0)
li $t0, MEM_VERT_OFFSET
mul $t0, $t0, 11
add $v0, $v0, $t0
sw $t1, 44($v0)
sw $t1, 48($v0)
sw $t1, 52($v0)
sw $t1, 64($v0)
sw $t1, 68($v0)
sw $t1, 84($v0)
sw $t1, 88($v0)
sw $t1, 100($v0)
sw $t1, 104($v0)
sw $t1, 108($v0)
sw $t1, 120($v0)
sw $t1, 124($v0)
sw $t1, 128($v0)
sw $t1, 132($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t1, 40($v0)
sw $t1, 60($v0)
sw $t1, 72($v0)
sw $t1, 80($v0)
sw $t1, 92($v0)
sw $t1, 100($v0)
sw $t1, 112($v0)
sw $t1, 120($v0)
sw $t1, 144($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t1, 44($v0)
sw $t1, 48($v0)
sw $t1, 60($v0)
sw $t1, 80($v0)
sw $t1, 92($v0)
sw $t1, 100($v0)
sw $t1, 104($v0)
sw $t1, 108($v0)
sw $t1, 120($v0)
sw $t1, 124($v0)
sw $t1, 128($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t1, 52($v0)
sw $t1, 60($v0)
sw $t1, 72($v0)
sw $t1, 80($v0)
sw $t1, 92($v0)
sw $t1, 100($v0)
sw $t1, 108($v0)
sw $t1, 120($v0)
sw $t1, 144($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t1, 40($v0)
sw $t1, 44($v0)
sw $t1, 48($v0)
sw $t1, 64($v0)
sw $t1, 68($v0)
sw $t1, 84($v0)
sw $t1, 88($v0)
sw $t1, 100($v0)
sw $t1, 112($v0)
sw $t1, 120($v0)
sw $t1, 124($v0)
sw $t1, 128($v0)
sw $t1, 132($v0)
li $t0, MEM_VERT_OFFSET
mul $t0, $t0, 12
add $v0, $v0, $t0
sw $t3, 24($v0)
sw $t3, 28($v0)
sw $t3, 32($v0)
sw $t3, 44($v0)
sw $t3, 48($v0)
sw $t3, 52($v0)
sw $t3, 64($v0)
sw $t3, 68($v0)
sw $t3, 72($v0)
sw $t3, 76($v0)
sw $t3, 88($v0)
sw $t3, 92($v0)
sw $t3, 96($v0)
sw $t3, 108($v0)
sw $t3, 112($v0)
sw $t3, 116($v0)
sw $t3, 136($v0)
sw $t3, 140($v0)
sw $t3, 144($v0)
sw $t3, 152($v0)
sw $t3, 156($v0)
sw $t3, 160($v0)
sw $t3, 176($v0)
sw $t3, 180($v0)
sw $t3, 196($v0)
sw $t3, 200($v0)
sw $t3, 212($v0)
sw $t3, 216($v0)
sw $t3, 220($v0)
sw $t3, 224($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t3, 24($v0)
sw $t3, 36($v0)
sw $t3, 44($v0)
sw $t3, 56($v0)
sw $t3, 64($v0)
sw $t3, 84($v0)
sw $t3, 104($v0)
sw $t3, 132($v0)
sw $t3, 152($v0)
sw $t3, 164($v0)
sw $t3, 172($v0)
sw $t3, 184($v0)
sw $t3, 192($v0)
sw $t3, 204($v0)
sw $t3, 212($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t3, 24($v0)
sw $t3, 28($v0)
sw $t3, 32($v0)
sw $t3, 44($v0)
sw $t3, 48($v0)
sw $t3, 52($v0)
sw $t3, 64($v0)
sw $t3, 68($v0)
sw $t3, 72($v0)
sw $t3, 88($v0)
sw $t3, 92($v0)
sw $t3, 108($v0)
sw $t3, 112($v0)
sw $t3, 136($v0)
sw $t3, 140($v0)
sw $t3, 152($v0)
sw $t3, 156($v0)
sw $t3, 160($v0)
sw $t3, 172($v0)
sw $t3, 176($v0)
sw $t3, 180($v0)
sw $t3, 184($v0)
sw $t3, 192($v0)
sw $t3, 212($v0)
sw $t3, 216($v0)
sw $t3, 220($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t3, 24($v0)
sw $t3, 44($v0)
sw $t3, 52($v0)
sw $t3, 64($v0)
sw $t3, 96($v0)
sw $t3, 116($v0)
sw $t3, 144($v0)
sw $t3, 152($v0)
sw $t3, 172($v0)
sw $t3, 184($v0)
sw $t3, 192($v0)
sw $t3, 204($v0)
sw $t3, 212($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t3, 24($v0)
sw $t3, 44($v0)
sw $t3, 56($v0)
sw $t3, 64($v0)
sw $t3, 68($v0)
sw $t3, 72($v0)
sw $t3, 76($v0)
sw $t3, 84($v0)
sw $t3, 88($v0)
sw $t3, 92($v0)
sw $t3, 104($v0)
sw $t3, 108($v0)
sw $t3, 112($v0)
sw $t3, 132($v0)
sw $t3, 136($v0)
sw $t3, 140($v0)
sw $t3, 152($v0)
sw $t3, 172($v0)
sw $t3, 184($v0)
sw $t3, 196($v0)
sw $t3, 200($v0)
sw $t3, 212($v0)
sw $t3, 216($v0)
sw $t3, 220($v0)
sw $t3, 224($v0)
li $t0, MEM_VERT_OFFSET
mul $t0, $t0, 2
add $v0, $v0, $t0
sw $t3, 24($v0)
sw $t3, 28($v0)
sw $t3, 32($v0)
sw $t3, 36($v0)
sw $t3, 40($v0)
sw $t3, 52($v0)
sw $t3, 56($v0)
sw $t3, 80($v0)
sw $t3, 84($v0)
sw $t3, 100($v0)
sw $t3, 104($v0)
sw $t3, 116($v0)
sw $t3, 128($v0)
sw $t3, 136($v0)
sw $t3, 140($v0)
sw $t3, 144($v0)
sw $t3, 148($v0)
sw $t3, 152($v0)
sw $t3, 160($v0)
sw $t3, 164($v0)
sw $t3, 168($v0)
sw $t3, 176($v0)
sw $t3, 188($v0)
sw $t3, 196($v0)
sw $t3, 208($v0)
sw $t3, 216($v0)
sw $t3, 220($v0)
sw $t3, 224($v0)
sw $t3, 228($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t3, 32($v0)
sw $t3, 48($v0)
sw $t3, 60($v0)
sw $t3, 76($v0)
sw $t3, 88($v0)
sw $t3, 96($v0)
sw $t3, 108($v0)
sw $t3, 116($v0)
sw $t3, 120($v0)
sw $t3, 128($v0)
sw $t3, 144($v0)
sw $t3, 164($v0)
sw $t3, 176($v0)
sw $t3, 180($v0)
sw $t3, 188($v0)
sw $t3, 196($v0)
sw $t3, 208($v0)
sw $t3, 216($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t3, 32($v0)
sw $t3, 48($v0)
sw $t3, 60($v0)
sw $t3, 76($v0)
sw $t3, 96($v0)
sw $t3, 108($v0)
sw $t3, 116($v0)
sw $t3, 124($v0)
sw $t3, 128($v0)
sw $t3, 144($v0)
sw $t3, 164($v0)
sw $t3, 176($v0)
sw $t3, 184($v0)
sw $t3, 188($v0)
sw $t3, 196($v0)
sw $t3, 208($v0)
sw $t3, 216($v0)
sw $t3, 220($v0)
sw $t3, 224($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t3, 32($v0)
sw $t3, 48($v0)
sw $t3, 60($v0)
sw $t3, 76($v0)
sw $t3, 88($v0)
sw $t3, 96($v0)
sw $t3, 108($v0)
sw $t3, 116($v0)
sw $t3, 128($v0)
sw $t3, 144($v0)
sw $t3, 164($v0)
sw $t3, 176($v0)
sw $t3, 188($v0)
sw $t3, 196($v0)
sw $t3, 208($v0)
sw $t3, 216($v0)
addi $v0, $v0, MEM_VERT_OFFSET
sw $t3, 32($v0)
sw $t3, 52($v0)
sw $t3, 56($v0)
sw $t3, 80($v0)
sw $t3, 84($v0)
sw $t3, 100($v0)
sw $t3, 104($v0)
sw $t3, 116($v0)
sw $t3, 128($v0)
sw $t3, 144($v0)
sw $t3, 160($v0)
sw $t3, 164($v0)
sw $t3, 168($v0)
sw $t3, 176($v0)
sw $t3, 188($v0)
sw $t3, 200($v0)
sw $t3, 204($v0)
sw $t3, 216($v0)
sw $t3, 220($v0)
sw $t3, 224($v0)
sw $t3, 228($v0)

	lw $ra, 0($sp)
	addi $sp, $sp, 4


	checkLevelFail_loop:
		li $t0, KEY_ADDRESS
		lw $t1, 0($t0)          # retrieve whether key is pressed
		beq $t1, 0, checkLevelFail_continue     # if no key is pressed, continue loop
		lw $t2, 4($t0) 		# get key press
		beq $t2, RESET_KEY, checkLevelFail_reset	# if reset pressed, reset
		beq $t2, SPACE_KEY, checkLevelFail_reset	# if SPACE pressed, reset
		j checkLevelFail_continue # else, continue waiting

		checkLevelFail_reset:
		j resetLevel		# reset level if space pressed

		checkLevelFail_continue:
			li $v0, 32		# set syscall to sleep
			li $a0, SLEEP_DURATION  # set sleep duration to default screen refresh delay
			syscall
			j checkLevelFail_loop

	j resetLevel

waitUntilSpace: # dummy logic loop that waits for SPACE or P to be pressed.
	
	waitUntilSpaceLoop:
		li $t0, KEY_ADDRESS
		lw $t1, 0($t0)          # retrieve whether key is pressed
		beq $t1, 0, waitUntilSpace_delay     # if no key is pressed, skip key press logic 
		lw $t2, 4($t0) 		# get key press
		beq $t2, SPACE_KEY, waitUntilSpace_space	# if A pressed, jump to moveLeft
		beq $t2, RESET_KEY, waitUntilSpace_reset
		j waitUntilSpace_delay		

		waitUntilSpace_space: # if space pressed
		la $t0, currentLevel 
		lw $t1, 0($t0) # load level number 
		bge $t1, 3, waitUntilSpace_delay # if already on win screen, ignore input
		j resetLevel

		waitUntilSpace_reset: # if P key pressed, reset to last complete level 
		la $t0, currentLevel 
		lw $t1, 0($t0) # load level number 
		bge $t1, 3, waitUntilSpace_reset_winScreen # do special logic if on win screen

		subi $t1, $t1, 1	# decrement the level
		sw $t1, 0($t0)
		j resetLevel 		# restart the last level

		waitUntilSpace_reset_winScreen:
			la $t0, currentLevel 
			sw $zero, 0($t0)	# reset to first level
			j resetLevel 
		

		waitUntilSpace_delay:
		li $v0, 32		# set syscall to sleep
		li $a0, SLEEP_DURATION  # set sleep duration to default screen refresh delay
		syscall

		j waitUntilSpaceLoop

drawLevelClearedScreen:
	addi $sp, $sp, -44
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $t3, 12($sp)
	sw $t4, 16($sp)
	sw $t5, 20($sp)
	sw $t6, 24($sp)
	sw $t7, 28($sp)
	sw $t8, 32($sp)
	sw $t9, 36($sp)
	sw $ra, 40($sp)

	jal clearScreen
	lw $ra, 40($sp)

	li $t2, 0x10401d
	li $t3, 0x22b14c
	li $t4, 0xffc20e
	li $t5, 0x155226
	li $t0, BASE_ADDRESS
	li $t1, MEM_VERT_OFFSET
	mul $t1, $t1, 11
	add $t0, $t0, $t1
	sw $t2, 20($t0)
	sw $t2, 24($t0)
	sw $t2, 28($t0)
	sw $t2, 32($t0)
	sw $t2, 36($t0)
	sw $t2, 40($t0)
	sw $t2, 44($t0)
	sw $t2, 48($t0)
	sw $t2, 52($t0)
	sw $t2, 56($t0)
	sw $t2, 60($t0)
	sw $t2, 64($t0)
	sw $t2, 68($t0)
	sw $t2, 72($t0)
	sw $t2, 76($t0)
	sw $t2, 80($t0)
	sw $t2, 84($t0)
	sw $t2, 88($t0)
	sw $t2, 92($t0)
	sw $t2, 96($t0)
	sw $t2, 100($t0)
	sw $t2, 104($t0)
	sw $t2, 108($t0)
	sw $t2, 112($t0)
	sw $t2, 116($t0)
	sw $t2, 120($t0)
	sw $t2, 124($t0)
	sw $t2, 128($t0)
	sw $t2, 132($t0)
	sw $t2, 136($t0)
	sw $t2, 140($t0)
	sw $t2, 144($t0)
	sw $t2, 148($t0)
	sw $t2, 152($t0)
	sw $t2, 156($t0)
	sw $t2, 160($t0)
	sw $t2, 164($t0)
	sw $t2, 168($t0)
	sw $t2, 172($t0)
	sw $t2, 176($t0)
	sw $t2, 180($t0)
	sw $t2, 184($t0)
	sw $t2, 188($t0)
	sw $t2, 192($t0)
	sw $t2, 196($t0)
	sw $t2, 200($t0)
	sw $t2, 204($t0)
	sw $t2, 208($t0)
	sw $t2, 212($t0)
	sw $t2, 216($t0)
	sw $t2, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t2, 20($t0)
	sw $t5, 24($t0)
	sw $t5, 28($t0)
	sw $t5, 32($t0)
	sw $t5, 36($t0)
	sw $t5, 40($t0)
	sw $t5, 44($t0)
	sw $t5, 48($t0)
	sw $t5, 52($t0)
	sw $t5, 56($t0)
	sw $t5, 60($t0)
	sw $t5, 64($t0)
	sw $t5, 68($t0)
	sw $t5, 72($t0)
	sw $t5, 76($t0)
	sw $t5, 80($t0)
	sw $t5, 84($t0)
	sw $t5, 88($t0)
	sw $t5, 92($t0)
	sw $t5, 96($t0)
	sw $t5, 100($t0)
	sw $t5, 104($t0)
	sw $t5, 108($t0)
	sw $t5, 112($t0)
	sw $t5, 116($t0)
	sw $t5, 120($t0)
	sw $t5, 124($t0)
	sw $t5, 128($t0)
	sw $t5, 132($t0)
	sw $t5, 136($t0)
	sw $t5, 140($t0)
	sw $t5, 144($t0)
	sw $t5, 148($t0)
	sw $t5, 152($t0)
	sw $t5, 156($t0)
	sw $t5, 160($t0)
	sw $t5, 164($t0)
	sw $t5, 168($t0)
	sw $t5, 172($t0)
	sw $t5, 176($t0)
	sw $t5, 180($t0)
	sw $t5, 184($t0)
	sw $t5, 188($t0)
	sw $t5, 192($t0)
	sw $t5, 196($t0)
	sw $t5, 200($t0)
	sw $t5, 204($t0)
	sw $t5, 208($t0)
	sw $t5, 212($t0)
	sw $t5, 216($t0)
	sw $t2, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t2, 20($t0)
	sw $t5, 24($t0)
	sw $t3, 28($t0)
	sw $t3, 32($t0)
	sw $t3, 36($t0)
	sw $t3, 40($t0)
	sw $t3, 44($t0)
	sw $t3, 48($t0)
	sw $t3, 52($t0)
	sw $t3, 56($t0)
	sw $t3, 60($t0)
	sw $t3, 64($t0)
	sw $t3, 68($t0)
	sw $t3, 72($t0)
	sw $t3, 76($t0)
	sw $t3, 80($t0)
	sw $t3, 84($t0)
	sw $t3, 88($t0)
	sw $t3, 92($t0)
	sw $t3, 96($t0)
	sw $t3, 100($t0)
	sw $t3, 104($t0)
	sw $t3, 108($t0)
	sw $t3, 112($t0)
	sw $t3, 116($t0)
	sw $t3, 120($t0)
	sw $t3, 124($t0)
	sw $t3, 128($t0)
	sw $t3, 132($t0)
	sw $t3, 136($t0)
	sw $t3, 140($t0)
	sw $t3, 144($t0)
	sw $t3, 148($t0)
	sw $t3, 152($t0)
	sw $t3, 156($t0)
	sw $t3, 160($t0)
	sw $t3, 164($t0)
	sw $t3, 168($t0)
	sw $t3, 172($t0)
	sw $t3, 176($t0)
	sw $t3, 180($t0)
	sw $t3, 184($t0)
	sw $t3, 188($t0)
	sw $t3, 192($t0)
	sw $t3, 196($t0)
	sw $t3, 200($t0)
	sw $t3, 204($t0)
	sw $t3, 208($t0)
	sw $t3, 212($t0)
	sw $t5, 216($t0)
	sw $t2, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t2, 20($t0)
	sw $t5, 24($t0)
	sw $t3, 28($t0)
	sw $t3, 212($t0)
	sw $t5, 216($t0)
	sw $t2, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t2, 20($t0)
	sw $t5, 24($t0)
	sw $t3, 28($t0)
	sw $t3, 212($t0)
	sw $t5, 216($t0)
	sw $t2, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t2, 20($t0)
	sw $t5, 24($t0)
	sw $t3, 28($t0)
	sw $t3, 40($t0)
	sw $t3, 60($t0)
	sw $t3, 64($t0)
	sw $t3, 68($t0)
	sw $t3, 72($t0)
	sw $t3, 80($t0)
	sw $t3, 96($t0)
	sw $t3, 104($t0)
	sw $t3, 108($t0)
	sw $t3, 112($t0)
	sw $t3, 116($t0)
	sw $t3, 124($t0)
	sw $t3, 212($t0)
	sw $t5, 216($t0)
	sw $t2, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t2, 20($t0)
	sw $t5, 24($t0)
	sw $t3, 28($t0)
	sw $t3, 40($t0)
	sw $t3, 60($t0)
	sw $t3, 80($t0)
	sw $t3, 96($t0)
	sw $t3, 104($t0)
	sw $t3, 124($t0)
	sw $t3, 212($t0)
	sw $t5, 216($t0)
	sw $t2, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t2, 20($t0)
	sw $t5, 24($t0)
	sw $t3, 28($t0)
	sw $t3, 40($t0)
	sw $t3, 60($t0)
	sw $t3, 64($t0)
	sw $t3, 68($t0)
	sw $t3, 84($t0)
	sw $t3, 92($t0)
	sw $t3, 104($t0)
	sw $t3, 108($t0)
	sw $t3, 112($t0)
	sw $t3, 124($t0)
	sw $t3, 212($t0)
	sw $t5, 216($t0)
	sw $t2, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t2, 20($t0)
	sw $t5, 24($t0)
	sw $t3, 28($t0)
	sw $t3, 40($t0)
	sw $t3, 60($t0)
	sw $t3, 84($t0)
	sw $t3, 92($t0)
	sw $t3, 104($t0)
	sw $t3, 124($t0)
	sw $t3, 212($t0)
	sw $t5, 216($t0)
	sw $t2, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t2, 20($t0)
	sw $t5, 24($t0)
	sw $t3, 28($t0)
	sw $t3, 40($t0)
	sw $t3, 44($t0)
	sw $t3, 48($t0)
	sw $t3, 52($t0)
	sw $t3, 60($t0)
	sw $t3, 64($t0)
	sw $t3, 68($t0)
	sw $t3, 72($t0)
	sw $t3, 88($t0)
	sw $t3, 104($t0)
	sw $t3, 108($t0)
	sw $t3, 112($t0)
	sw $t3, 116($t0)
	sw $t3, 124($t0)
	sw $t3, 128($t0)
	sw $t3, 132($t0)
	sw $t3, 136($t0)
	sw $t3, 212($t0)
	sw $t5, 216($t0)
	sw $t2, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t2, 20($t0)
	sw $t5, 24($t0)
	sw $t3, 28($t0)
	sw $t3, 212($t0)
	sw $t5, 216($t0)
	sw $t2, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t2, 20($t0)
	sw $t5, 24($t0)
	sw $t3, 28($t0)
	sw $t3, 44($t0)
	sw $t3, 48($t0)
	sw $t3, 60($t0)
	sw $t3, 80($t0)
	sw $t3, 84($t0)
	sw $t3, 88($t0)
	sw $t3, 92($t0)
	sw $t3, 104($t0)
	sw $t3, 108($t0)
	sw $t3, 120($t0)
	sw $t3, 124($t0)
	sw $t3, 128($t0)
	sw $t3, 140($t0)
	sw $t3, 144($t0)
	sw $t3, 148($t0)
	sw $t3, 152($t0)
	sw $t3, 160($t0)
	sw $t3, 164($t0)
	sw $t3, 168($t0)
	sw $t3, 184($t0)
	sw $t3, 200($t0)
	sw $t3, 212($t0)
	sw $t5, 216($t0)
	sw $t2, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t2, 20($t0)
	sw $t5, 24($t0)
	sw $t3, 28($t0)
	sw $t3, 40($t0)
	sw $t3, 52($t0)
	sw $t3, 60($t0)
	sw $t3, 80($t0)
	sw $t3, 100($t0)
	sw $t3, 112($t0)
	sw $t3, 120($t0)
	sw $t3, 132($t0)
	sw $t3, 140($t0)
	sw $t3, 160($t0)
	sw $t3, 172($t0)
	sw $t3, 184($t0)
	sw $t3, 200($t0)
	sw $t3, 212($t0)
	sw $t5, 216($t0)
	sw $t2, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t2, 20($t0)
	sw $t5, 24($t0)
	sw $t3, 28($t0)
	sw $t3, 40($t0)
	sw $t3, 60($t0)
	sw $t3, 80($t0)
	sw $t3, 84($t0)
	sw $t3, 88($t0)
	sw $t3, 100($t0)
	sw $t3, 104($t0)
	sw $t3, 108($t0)
	sw $t3, 112($t0)
	sw $t3, 120($t0)
	sw $t3, 124($t0)
	sw $t3, 128($t0)
	sw $t3, 140($t0)
	sw $t3, 144($t0)
	sw $t3, 148($t0)
	sw $t3, 160($t0)
	sw $t3, 172($t0)
	sw $t3, 184($t0)
	sw $t3, 200($t0)
	sw $t3, 212($t0)
	sw $t5, 216($t0)
	sw $t2, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t2, 20($t0)
	sw $t5, 24($t0)
	sw $t3, 28($t0)
	sw $t3, 40($t0)
	sw $t3, 52($t0)
	sw $t3, 60($t0)
	sw $t3, 80($t0)
	sw $t3, 100($t0)
	sw $t3, 112($t0)
	sw $t3, 120($t0)
	sw $t3, 128($t0)
	sw $t3, 140($t0)
	sw $t3, 160($t0)
	sw $t3, 172($t0)
	sw $t3, 212($t0)
	sw $t5, 216($t0)
	sw $t2, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t2, 20($t0)
	sw $t5, 24($t0)
	sw $t3, 28($t0)
	sw $t3, 44($t0)
	sw $t3, 48($t0)
	sw $t3, 60($t0)
	sw $t3, 64($t0)
	sw $t3, 68($t0)
	sw $t3, 72($t0)
	sw $t3, 80($t0)
	sw $t3, 84($t0)
	sw $t3, 88($t0)
	sw $t3, 92($t0)
	sw $t3, 100($t0)
	sw $t3, 112($t0)
	sw $t3, 120($t0)
	sw $t3, 132($t0)
	sw $t3, 140($t0)
	sw $t3, 144($t0)
	sw $t3, 148($t0)
	sw $t3, 152($t0)
	sw $t3, 160($t0)
	sw $t3, 164($t0)
	sw $t3, 168($t0)
	sw $t3, 184($t0)
	sw $t3, 200($t0)
	sw $t3, 212($t0)
	sw $t5, 216($t0)
	sw $t2, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t2, 20($t0)
	sw $t5, 24($t0)
	sw $t3, 28($t0)
	sw $t3, 212($t0)
	sw $t5, 216($t0)
	sw $t2, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t2, 20($t0)
	sw $t5, 24($t0)
	sw $t3, 28($t0)
	sw $t3, 212($t0)
	sw $t5, 216($t0)
	sw $t2, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t2, 20($t0)
	sw $t5, 24($t0)
	sw $t3, 28($t0)
	sw $t3, 32($t0)
	sw $t3, 36($t0)
	sw $t3, 40($t0)
	sw $t3, 44($t0)
	sw $t3, 48($t0)
	sw $t3, 52($t0)
	sw $t3, 56($t0)
	sw $t3, 60($t0)
	sw $t3, 64($t0)
	sw $t3, 68($t0)
	sw $t3, 72($t0)
	sw $t3, 76($t0)
	sw $t3, 80($t0)
	sw $t3, 84($t0)
	sw $t3, 88($t0)
	sw $t3, 92($t0)
	sw $t3, 96($t0)
	sw $t3, 100($t0)
	sw $t3, 104($t0)
	sw $t3, 108($t0)
	sw $t3, 112($t0)
	sw $t3, 116($t0)
	sw $t3, 120($t0)
	sw $t3, 124($t0)
	sw $t3, 128($t0)
	sw $t3, 132($t0)
	sw $t3, 136($t0)
	sw $t3, 140($t0)
	sw $t3, 144($t0)
	sw $t3, 148($t0)
	sw $t3, 152($t0)
	sw $t3, 156($t0)
	sw $t3, 160($t0)
	sw $t3, 164($t0)
	sw $t3, 168($t0)
	sw $t3, 172($t0)
	sw $t3, 176($t0)
	sw $t3, 180($t0)
	sw $t3, 184($t0)
	sw $t3, 188($t0)
	sw $t3, 192($t0)
	sw $t3, 196($t0)
	sw $t3, 200($t0)
	sw $t3, 204($t0)
	sw $t3, 208($t0)
	sw $t3, 212($t0)
	sw $t5, 216($t0)
	sw $t2, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t2, 20($t0)
	sw $t5, 24($t0)
	sw $t5, 28($t0)
	sw $t5, 32($t0)
	sw $t5, 36($t0)
	sw $t5, 40($t0)
	sw $t5, 44($t0)
	sw $t5, 48($t0)
	sw $t5, 52($t0)
	sw $t5, 56($t0)
	sw $t5, 60($t0)
	sw $t5, 64($t0)
	sw $t5, 68($t0)
	sw $t5, 72($t0)
	sw $t5, 76($t0)
	sw $t5, 80($t0)
	sw $t5, 84($t0)
	sw $t5, 88($t0)
	sw $t5, 92($t0)
	sw $t5, 96($t0)
	sw $t5, 100($t0)
	sw $t5, 104($t0)
	sw $t5, 108($t0)
	sw $t5, 112($t0)
	sw $t5, 116($t0)
	sw $t5, 120($t0)
	sw $t5, 124($t0)
	sw $t5, 128($t0)
	sw $t5, 132($t0)
	sw $t5, 136($t0)
	sw $t5, 140($t0)
	sw $t5, 144($t0)
	sw $t5, 148($t0)
	sw $t5, 152($t0)
	sw $t5, 156($t0)
	sw $t5, 160($t0)
	sw $t5, 164($t0)
	sw $t5, 168($t0)
	sw $t5, 172($t0)
	sw $t5, 176($t0)
	sw $t5, 180($t0)
	sw $t5, 184($t0)
	sw $t5, 188($t0)
	sw $t5, 192($t0)
	sw $t5, 196($t0)
	sw $t5, 200($t0)
	sw $t5, 204($t0)
	sw $t5, 208($t0)
	sw $t5, 212($t0)
	sw $t5, 216($t0)
	sw $t2, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t2, 20($t0)
	sw $t2, 24($t0)
	sw $t2, 28($t0)
	sw $t2, 32($t0)
	sw $t2, 36($t0)
	sw $t2, 40($t0)
	sw $t2, 44($t0)
	sw $t2, 48($t0)
	sw $t2, 52($t0)
	sw $t2, 56($t0)
	sw $t2, 60($t0)
	sw $t2, 64($t0)
	sw $t2, 68($t0)
	sw $t2, 72($t0)
	sw $t2, 76($t0)
	sw $t2, 80($t0)
	sw $t2, 84($t0)
	sw $t2, 88($t0)
	sw $t2, 92($t0)
	sw $t2, 96($t0)
	sw $t2, 100($t0)
	sw $t2, 104($t0)
	sw $t2, 108($t0)
	sw $t2, 112($t0)
	sw $t2, 116($t0)
	sw $t2, 120($t0)
	sw $t2, 124($t0)
	sw $t2, 128($t0)
	sw $t2, 132($t0)
	sw $t2, 136($t0)
	sw $t2, 140($t0)
	sw $t2, 144($t0)
	sw $t2, 148($t0)
	sw $t2, 152($t0)
	sw $t2, 156($t0)
	sw $t2, 160($t0)
	sw $t2, 164($t0)
	sw $t2, 168($t0)
	sw $t2, 172($t0)
	sw $t2, 176($t0)
	sw $t2, 180($t0)
	sw $t2, 184($t0)
	sw $t2, 188($t0)
	sw $t2, 192($t0)
	sw $t2, 196($t0)
	sw $t2, 200($t0)
	sw $t2, 204($t0)
	sw $t2, 208($t0)
	sw $t2, 212($t0)
	sw $t2, 216($t0)
	sw $t2, 220($t0)
	li $t1, MEM_VERT_OFFSET
	mul $t1, $t1, 13
	add $t0, $t0, $t1
	sw $t4, 20($t0)
	sw $t4, 24($t0)
	sw $t4, 28($t0)
	sw $t4, 40($t0)
	sw $t4, 44($t0)
	sw $t4, 48($t0)
	sw $t4, 60($t0)
	sw $t4, 64($t0)
	sw $t4, 68($t0)
	sw $t4, 72($t0)
	sw $t4, 84($t0)
	sw $t4, 88($t0)
	sw $t4, 92($t0)
	sw $t4, 104($t0)
	sw $t4, 108($t0)
	sw $t4, 112($t0)
	sw $t4, 132($t0)
	sw $t4, 136($t0)
	sw $t4, 140($t0)
	sw $t4, 148($t0)
	sw $t4, 152($t0)
	sw $t4, 156($t0)
	sw $t4, 172($t0)
	sw $t4, 176($t0)
	sw $t4, 192($t0)
	sw $t4, 196($t0)
	sw $t4, 208($t0)
	sw $t4, 212($t0)
	sw $t4, 216($t0)
	sw $t4, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t4, 20($t0)
	sw $t4, 32($t0)
	sw $t4, 40($t0)
	sw $t4, 52($t0)
	sw $t4, 60($t0)
	sw $t4, 80($t0)
	sw $t4, 100($t0)
	sw $t4, 128($t0)
	sw $t4, 148($t0)
	sw $t4, 160($t0)
	sw $t4, 168($t0)
	sw $t4, 180($t0)
	sw $t4, 188($t0)
	sw $t4, 200($t0)
	sw $t4, 208($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t4, 20($t0)
	sw $t4, 24($t0)
	sw $t4, 28($t0)
	sw $t4, 40($t0)
	sw $t4, 44($t0)
	sw $t4, 48($t0)
	sw $t4, 60($t0)
	sw $t4, 64($t0)
	sw $t4, 68($t0)
	sw $t4, 84($t0)
	sw $t4, 88($t0)
	sw $t4, 104($t0)
	sw $t4, 108($t0)
	sw $t4, 132($t0)
	sw $t4, 136($t0)
	sw $t4, 148($t0)
	sw $t4, 152($t0)
	sw $t4, 156($t0)
	sw $t4, 168($t0)
	sw $t4, 172($t0)
	sw $t4, 176($t0)
	sw $t4, 180($t0)
	sw $t4, 188($t0)
	sw $t4, 208($t0)
	sw $t4, 212($t0)
	sw $t4, 216($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t4, 20($t0)
	sw $t4, 40($t0)
	sw $t4, 48($t0)
	sw $t4, 60($t0)
	sw $t4, 92($t0)
	sw $t4, 112($t0)
	sw $t4, 140($t0)
	sw $t4, 148($t0)
	sw $t4, 168($t0)
	sw $t4, 180($t0)
	sw $t4, 188($t0)
	sw $t4, 200($t0)
	sw $t4, 208($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t4, 20($t0)
	sw $t4, 40($t0)
	sw $t4, 52($t0)
	sw $t4, 60($t0)
	sw $t4, 64($t0)
	sw $t4, 68($t0)
	sw $t4, 72($t0)
	sw $t4, 80($t0)
	sw $t4, 84($t0)
	sw $t4, 88($t0)
	sw $t4, 100($t0)
	sw $t4, 104($t0)
	sw $t4, 108($t0)
	sw $t4, 128($t0)
	sw $t4, 132($t0)
	sw $t4, 136($t0)
	sw $t4, 148($t0)
	sw $t4, 168($t0)
	sw $t4, 180($t0)
	sw $t4, 192($t0)
	sw $t4, 196($t0)
	sw $t4, 208($t0)
	sw $t4, 212($t0)
	sw $t4, 216($t0)
	sw $t4, 220($t0)
	li $t1, MEM_VERT_OFFSET
	mul $t1, $t1, 2
	add $t0, $t0, $t1
	sw $t4, 20($t0)
	sw $t4, 24($t0)
	sw $t4, 28($t0)
	sw $t4, 32($t0)
	sw $t4, 36($t0)
	sw $t4, 48($t0)
	sw $t4, 52($t0)
	sw $t4, 76($t0)
	sw $t4, 80($t0)
	sw $t4, 96($t0)
	sw $t4, 100($t0)
	sw $t4, 112($t0)
	sw $t4, 124($t0)
	sw $t4, 132($t0)
	sw $t4, 136($t0)
	sw $t4, 140($t0)
	sw $t4, 144($t0)
	sw $t4, 148($t0)
	sw $t4, 156($t0)
	sw $t4, 160($t0)
	sw $t4, 164($t0)
	sw $t4, 172($t0)
	sw $t4, 184($t0)
	sw $t4, 192($t0)
	sw $t4, 204($t0)
	sw $t4, 212($t0)
	sw $t4, 216($t0)
	sw $t4, 220($t0)
	sw $t4, 224($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t4, 28($t0)
	sw $t4, 44($t0)
	sw $t4, 56($t0)
	sw $t4, 72($t0)
	sw $t4, 84($t0)
	sw $t4, 92($t0)
	sw $t4, 104($t0)
	sw $t4, 112($t0)
	sw $t4, 116($t0)
	sw $t4, 124($t0)
	sw $t4, 140($t0)
	sw $t4, 160($t0)
	sw $t4, 172($t0)
	sw $t4, 176($t0)
	sw $t4, 184($t0)
	sw $t4, 192($t0)
	sw $t4, 204($t0)
	sw $t4, 212($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t4, 28($t0)
	sw $t4, 44($t0)
	sw $t4, 56($t0)
	sw $t4, 72($t0)
	sw $t4, 92($t0)
	sw $t4, 104($t0)
	sw $t4, 112($t0)
	sw $t4, 120($t0)
	sw $t4, 124($t0)
	sw $t4, 140($t0)
	sw $t4, 160($t0)
	sw $t4, 172($t0)
	sw $t4, 180($t0)
	sw $t4, 184($t0)
	sw $t4, 192($t0)
	sw $t4, 204($t0)
	sw $t4, 212($t0)
	sw $t4, 216($t0)
	sw $t4, 220($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t4, 28($t0)
	sw $t4, 44($t0)
	sw $t4, 56($t0)
	sw $t4, 72($t0)
	sw $t4, 84($t0)
	sw $t4, 92($t0)
	sw $t4, 104($t0)
	sw $t4, 112($t0)
	sw $t4, 124($t0)
	sw $t4, 140($t0)
	sw $t4, 160($t0)
	sw $t4, 172($t0)
	sw $t4, 184($t0)
	sw $t4, 192($t0)
	sw $t4, 204($t0)
	sw $t4, 212($t0)
	addi $t0, $t0, MEM_VERT_OFFSET
	sw $t4, 28($t0)
	sw $t4, 48($t0)
	sw $t4, 52($t0)
	sw $t4, 76($t0)
	sw $t4, 80($t0)
	sw $t4, 96($t0)
	sw $t4, 100($t0)
	sw $t4, 112($t0)
	sw $t4, 124($t0)
	sw $t4, 140($t0)
	sw $t4, 156($t0)
	sw $t4, 160($t0)
	sw $t4, 164($t0)
	sw $t4, 172($t0)
	sw $t4, 184($t0)
	sw $t4, 196($t0)
	sw $t4, 200($t0)
	sw $t4, 212($t0)
	sw $t4, 216($t0)
	sw $t4, 220($t0)
	sw $t4, 224($t0)

	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $t3, 12($sp)
	lw $t4, 16($sp)
	lw $t5, 20($sp)
	lw $t6, 24($sp)
	lw $t7, 28($sp)
	lw $t8, 32($sp)
	lw $t9, 36($sp)
	lw $ra, 40($sp)
	addi $sp, $sp, 44
	
	j waitUntilSpace

drawWinScreen:

	addi $sp, $sp, -44
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $t3, 12($sp)
	sw $t4, 16($sp)
	sw $t5, 20($sp)
	sw $t6, 24($sp)
	sw $t7, 28($sp)
	sw $t8, 32($sp)
	sw $t9, 36($sp)
	sw $ra, 40($sp)

	jal clearScreen
	
	li $a0, 50 # write ones digit of score
	li $a1, 41
	li $a3, SCORE_COLOR
	li $a2, 10  	# calculate remainder after div by 10
	div $s4, $a2	
	mfhi $a2
	jal drawDigit 
	
	li $a0, 45 # write tens digit of score
	li $a1, 41
	li $a3, SCORE_COLOR
	li $a2, 100  	# get remainder after div by 100
	div $s4, $a2	
	mfhi $a2
	li $t0, 10 	# divide by 10 to get tens digit in quotient
	div $a2, $t0
	mflo $a2
	jal drawDigit 

	lw $ra, 40($sp)

	li $t1, 0xd19d0c
	li $t2, 0xffc20e
	li $t3, 0xffd670
	li $t4, 0x464646
	li $t5, 0x00b7ef
	li $v0, BASE_ADDRESS
	li $t0, MEM_VERT_OFFSET
	mul $t0, $t0, 8
	add $v0, $v0, $t0
	sw $t2, 52($v0)
	sw $t2, 68($v0)
	sw $t2, 76($v0)
	sw $t2, 80($v0)
	sw $t2, 84($v0)
	sw $t2, 96($v0)
	sw $t2, 100($v0)
	sw $t2, 112($v0)
	sw $t2, 116($v0)
	sw $t2, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 140($v0)
	sw $t2, 144($v0)
	sw $t2, 156($v0)
	sw $t2, 160($v0)
	sw $t2, 164($v0)
	sw $t2, 176($v0)
	sw $t2, 192($v0)
	sw $t2, 204($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 52($v0)
	sw $t2, 68($v0)
	sw $t2, 80($v0)
	sw $t2, 92($v0)
	sw $t2, 104($v0)
	sw $t2, 120($v0)
	sw $t2, 136($v0)
	sw $t2, 148($v0)
	sw $t2, 156($v0)
	sw $t2, 168($v0)
	sw $t2, 176($v0)
	sw $t2, 192($v0)
	sw $t2, 204($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 56($v0)
	sw $t2, 64($v0)
	sw $t2, 80($v0)
	sw $t2, 92($v0)
	sw $t2, 120($v0)
	sw $t2, 136($v0)
	sw $t2, 148($v0)
	sw $t2, 156($v0)
	sw $t2, 160($v0)
	sw $t2, 164($v0)
	sw $t2, 180($v0)
	sw $t2, 184($v0)
	sw $t2, 188($v0)
	sw $t2, 204($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 56($v0)
	sw $t2, 64($v0)
	sw $t2, 80($v0)
	sw $t2, 92($v0)
	sw $t2, 104($v0)
	sw $t2, 120($v0)
	sw $t2, 136($v0)
	sw $t2, 148($v0)
	sw $t2, 156($v0)
	sw $t2, 164($v0)
	sw $t2, 184($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 60($v0)
	sw $t2, 76($v0)
	sw $t2, 80($v0)
	sw $t2, 84($v0)
	sw $t2, 96($v0)
	sw $t2, 100($v0)
	sw $t2, 120($v0)
	sw $t2, 140($v0)
	sw $t2, 144($v0)
	sw $t2, 156($v0)
	sw $t2, 168($v0)
	sw $t2, 184($v0)
	sw $t2, 204($v0)
	li $t0, MEM_VERT_OFFSET
	mul $t0, $t0, 4
	add $v0, $v0, $t0
	sw $t1, 116($v0)
	sw $t1, 120($v0)
	sw $t1, 124($v0)
	sw $t1, 128($v0)
	sw $t1, 132($v0)
	sw $t1, 136($v0)
	sw $t1, 140($v0)
	sw $t1, 144($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t1, 112($v0)
	sw $t1, 116($v0)
	sw $t2, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t2, 136($v0)
	sw $t3, 140($v0)
	sw $t2, 144($v0)
	sw $t1, 148($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t1, 104($v0)
	sw $t1, 108($v0)
	sw $t1, 112($v0)
	sw $t1, 116($v0)
	sw $t2, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t2, 136($v0)
	sw $t3, 140($v0)
	sw $t2, 144($v0)
	sw $t1, 148($v0)
	sw $t2, 152($v0)
	sw $t3, 156($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t1, 100($v0)
	sw $t1, 104($v0)
	sw $t2, 108($v0)
	sw $t2, 112($v0)
	sw $t1, 116($v0)
	sw $t2, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t2, 136($v0)
	sw $t3, 140($v0)
	sw $t2, 144($v0)
	sw $t1, 148($v0)
	sw $t2, 152($v0)
	sw $t2, 156($v0)
	sw $t3, 160($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t1, 100($v0)
	sw $t2, 104($v0)
	sw $t1, 116($v0)
	sw $t2, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t2, 136($v0)
	sw $t3, 140($v0)
	sw $t2, 144($v0)
	sw $t2, 156($v0)
	sw $t3, 160($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t1, 100($v0)
	sw $t1, 116($v0)
	sw $t2, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t2, 136($v0)
	sw $t3, 140($v0)
	sw $t2, 144($v0)
	sw $t2, 160($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t1, 100($v0)
	sw $t1, 116($v0)
	sw $t2, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t3, 136($v0)
	sw $t2, 140($v0)
	sw $t2, 144($v0)
	sw $t2, 160($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t1, 100($v0)
	sw $t2, 104($v0)
	sw $t1, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t3, 136($v0)
	sw $t2, 140($v0)
	sw $t2, 156($v0)
	sw $t2, 160($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t1, 100($v0)
	sw $t2, 104($v0)
	sw $t1, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t3, 136($v0)
	sw $t2, 140($v0)
	sw $t2, 156($v0)
	sw $t2, 160($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t1, 100($v0)
	sw $t2, 104($v0)
	sw $t1, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t3, 136($v0)
	sw $t2, 140($v0)
	sw $t2, 156($v0)
	sw $t2, 160($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t1, 104($v0)
	sw $t1, 108($v0)
	sw $t2, 112($v0)
	sw $t2, 116($v0)
	sw $t2, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t3, 136($v0)
	sw $t2, 140($v0)
	sw $t2, 144($v0)
	sw $t2, 148($v0)
	sw $t2, 152($v0)
	sw $t2, 156($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t1, 112($v0)
	sw $t1, 116($v0)
	sw $t1, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t3, 136($v0)
	sw $t2, 140($v0)
	sw $t2, 144($v0)
	sw $t2, 148($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t1, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t2, 136($v0)
	sw $t2, 140($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t1, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t2, 136($v0)
	sw $t2, 140($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t1, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t3, 136($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t1, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t3, 136($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t1, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t3, 136($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t1, 116($v0)
	sw $t1, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t2, 136($v0)
	sw $t2, 140($v0)
	sw $t2, 144($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t1, 112($v0)
	sw $t2, 116($v0)
	sw $t2, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t2, 136($v0)
	sw $t2, 140($v0)
	sw $t2, 144($v0)
	sw $t2, 148($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t4, 108($v0)
	sw $t4, 112($v0)
	sw $t4, 116($v0)
	sw $t4, 120($v0)
	sw $t4, 124($v0)
	sw $t4, 128($v0)
	sw $t4, 132($v0)
	sw $t4, 136($v0)
	sw $t4, 140($v0)
	sw $t4, 144($v0)
	sw $t4, 148($v0)
	sw $t4, 152($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t4, 108($v0)
	sw $t4, 112($v0)
	sw $t2, 116($v0)
	sw $t2, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t2, 136($v0)
	sw $t2, 140($v0)
	sw $t2, 144($v0)
	sw $t4, 148($v0)
	sw $t4, 152($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t4, 108($v0)
	sw $t4, 112($v0)
	sw $t2, 116($v0)
	sw $t2, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t2, 136($v0)
	sw $t2, 140($v0)
	sw $t2, 144($v0)
	sw $t4, 148($v0)
	sw $t4, 152($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t4, 108($v0)
	sw $t4, 112($v0)
	sw $t2, 116($v0)
	sw $t2, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t2, 136($v0)
	sw $t2, 140($v0)
	sw $t2, 144($v0)
	sw $t4, 148($v0)
	sw $t4, 152($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t4, 108($v0)
	sw $t4, 112($v0)
	sw $t4, 116($v0)
	sw $t4, 120($v0)
	sw $t4, 124($v0)
	sw $t4, 128($v0)
	sw $t4, 132($v0)
	sw $t4, 136($v0)
	sw $t4, 140($v0)
	sw $t4, 144($v0)
	sw $t4, 148($v0)
	sw $t4, 152($v0)
	li $t0, MEM_VERT_OFFSET
	mul $t0, $t0, 4
	add $v0, $v0, $t0
	sw $t5, 44($v0)
	sw $t5, 48($v0)
	sw $t5, 52($v0)
	sw $t5, 64($v0)
	sw $t5, 68($v0)
	sw $t5, 84($v0)
	sw $t5, 88($v0)
	sw $t5, 100($v0)
	sw $t5, 104($v0)
	sw $t5, 108($v0)
	sw $t5, 120($v0)
	sw $t5, 124($v0)
	sw $t5, 128($v0)
	sw $t5, 132($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t5, 40($v0)
	sw $t5, 60($v0)
	sw $t5, 72($v0)
	sw $t5, 80($v0)
	sw $t5, 92($v0)
	sw $t5, 100($v0)
	sw $t5, 112($v0)
	sw $t5, 120($v0)
	sw $t5, 152($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t5, 44($v0)
	sw $t5, 48($v0)
	sw $t5, 60($v0)
	sw $t5, 80($v0)
	sw $t5, 92($v0)
	sw $t5, 100($v0)
	sw $t5, 104($v0)
	sw $t5, 108($v0)
	sw $t5, 120($v0)
	sw $t5, 124($v0)
	sw $t5, 128($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t5, 52($v0)
	sw $t5, 60($v0)
	sw $t5, 72($v0)
	sw $t5, 80($v0)
	sw $t5, 92($v0)
	sw $t5, 100($v0)
	sw $t5, 108($v0)
	sw $t5, 120($v0)
	sw $t5, 152($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t5, 40($v0)
	sw $t5, 44($v0)
	sw $t5, 48($v0)
	sw $t5, 64($v0)
	sw $t5, 68($v0)
	sw $t5, 84($v0)
	sw $t5, 88($v0)
	sw $t5, 100($v0)
	sw $t5, 112($v0)
	sw $t5, 120($v0)
	sw $t5, 124($v0)
	sw $t5, 128($v0)
	sw $t5, 132($v0)
	li $t0, MEM_VERT_OFFSET
	mul $t0, $t0, 3
	add $v0, $v0, $t0
	sw $t2, 40($v0)
	sw $t2, 44($v0)
	sw $t2, 48($v0)
	sw $t2, 60($v0)
	sw $t2, 64($v0)
	sw $t2, 68($v0)
	sw $t2, 80($v0)
	sw $t2, 84($v0)
	sw $t2, 88($v0)
	sw $t2, 92($v0)
	sw $t2, 104($v0)
	sw $t2, 108($v0)
	sw $t2, 112($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t2, 148($v0)
	sw $t2, 152($v0)
	sw $t2, 156($v0)
	sw $t2, 176($v0)
	sw $t2, 180($v0)
	sw $t2, 184($v0)
	sw $t2, 188($v0)
	sw $t2, 192($v0)
	sw $t2, 204($v0)
	sw $t2, 208($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 40($v0)
	sw $t2, 52($v0)
	sw $t2, 60($v0)
	sw $t2, 72($v0)
	sw $t2, 80($v0)
	sw $t2, 100($v0)
	sw $t2, 120($v0)
	sw $t2, 148($v0)
	sw $t2, 160($v0)
	sw $t2, 184($v0)
	sw $t2, 200($v0)
	sw $t2, 212($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 40($v0)
	sw $t2, 44($v0)
	sw $t2, 48($v0)
	sw $t2, 60($v0)
	sw $t2, 64($v0)
	sw $t2, 68($v0)
	sw $t2, 80($v0)
	sw $t2, 84($v0)
	sw $t2, 88($v0)
	sw $t2, 104($v0)
	sw $t2, 108($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 148($v0)
	sw $t2, 152($v0)
	sw $t2, 156($v0)
	sw $t2, 184($v0)
	sw $t2, 200($v0)
	sw $t2, 212($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 40($v0)
	sw $t2, 60($v0)
	sw $t2, 68($v0)
	sw $t2, 80($v0)
	sw $t2, 112($v0)
	sw $t2, 132($v0)
	sw $t2, 148($v0)
	sw $t2, 184($v0)
	sw $t2, 200($v0)
	sw $t2, 212($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 40($v0)
	sw $t2, 60($v0)
	sw $t2, 72($v0)
	sw $t2, 80($v0)
	sw $t2, 84($v0)
	sw $t2, 88($v0)
	sw $t2, 92($v0)
	sw $t2, 100($v0)
	sw $t2, 104($v0)
	sw $t2, 108($v0)
	sw $t2, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 148($v0)
	sw $t2, 184($v0)
	sw $t2, 204($v0)
	sw $t2, 208($v0)
	li $t0, MEM_VERT_OFFSET
	mul $t0, $t0, 2
	add $v0, $v0, $t0
	sw $t2, 56($v0)
	sw $t2, 60($v0)
	sw $t2, 64($v0)
	sw $t2, 76($v0)
	sw $t2, 80($v0)
	sw $t2, 84($v0)
	sw $t2, 88($v0)
	sw $t2, 100($v0)
	sw $t2, 104($v0)
	sw $t2, 108($v0)
	sw $t2, 116($v0)
	sw $t2, 120($v0)
	sw $t2, 124($v0)
	sw $t2, 128($v0)
	sw $t2, 132($v0)
	sw $t2, 144($v0)
	sw $t2, 148($v0)
	sw $t2, 160($v0)
	sw $t2, 164($v0)
	sw $t2, 168($v0)
	sw $t2, 180($v0)
	sw $t2, 184($v0)
	sw $t2, 188($v0)
	sw $t2, 192($v0)
	sw $t2, 196($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 56($v0)
	sw $t2, 68($v0)
	sw $t2, 76($v0)
	sw $t2, 96($v0)
	sw $t2, 124($v0)
	sw $t2, 140($v0)
	sw $t2, 152($v0)
	sw $t2, 160($v0)
	sw $t2, 172($v0)
	sw $t2, 188($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 56($v0)
	sw $t2, 60($v0)
	sw $t2, 64($v0)
	sw $t2, 76($v0)
	sw $t2, 80($v0)
	sw $t2, 84($v0)
	sw $t2, 100($v0)
	sw $t2, 104($v0)
	sw $t2, 124($v0)
	sw $t2, 140($v0)
	sw $t2, 144($v0)
	sw $t2, 148($v0)
	sw $t2, 152($v0)
	sw $t2, 160($v0)
	sw $t2, 164($v0)
	sw $t2, 168($v0)
	sw $t2, 188($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 56($v0)
	sw $t2, 64($v0)
	sw $t2, 76($v0)
	sw $t2, 108($v0)
	sw $t2, 124($v0)
	sw $t2, 140($v0)
	sw $t2, 152($v0)
	sw $t2, 160($v0)
	sw $t2, 168($v0)
	sw $t2, 188($v0)
	addi $v0, $v0, MEM_VERT_OFFSET
	sw $t2, 56($v0)
	sw $t2, 68($v0)
	sw $t2, 76($v0)
	sw $t2, 80($v0)
	sw $t2, 84($v0)
	sw $t2, 88($v0)
	sw $t2, 96($v0)
	sw $t2, 100($v0)
	sw $t2, 104($v0)
	sw $t2, 124($v0)
	sw $t2, 140($v0)
	sw $t2, 152($v0)
	sw $t2, 160($v0)
	sw $t2, 172($v0)
	sw $t2, 188($v0)

	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $t3, 12($sp)
	lw $t4, 16($sp)
	lw $t5, 20($sp)
	lw $t6, 24($sp)
	lw $t7, 28($sp)
	lw $t8, 32($sp)
	lw $t9, 36($sp)
	lw $ra, 40($sp)
	addi $sp, $sp, 44

	jr $ra
