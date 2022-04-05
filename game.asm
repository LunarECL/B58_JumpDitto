#####################################################################
#
# CSCB58 Winter 2022 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Minseok(Joshua) Kim, 1007462684, kimmi264, minseokk.kim@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4 (update this as needed)
# - Unit height in pixels: 4 (update this as needed)
# - Display width in pixels: 256 (update this as needed)
# - Display height in pixels: 512 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3 (choose the one the applies)
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. Draw the level (Platforms), Draw the player character(Ditto), at least 2 additional objects(enemies)
# 2. Player can move, Platform collision and gravity, at least 3 different platforms, Collision with objects
# 3. Fail condition, Moving objects, Moving platforms, Shooting,
# ... (add more if necessary)
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes / no / yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################
.eqv    FRAME_BUFFER    0x10008000
.eqv 	INPUT_BUFFER	0xffff0000
.eqv 	PLATFORM_BUFFER	0x10007F10

######## Constants
.eqv 	SCREEN_WIDTH	64	# units
.eqv 	SCREEN_HEIGHT	128	# units
.eqv    FRAME_DELAY     30
.eqv    CLEAR_DELAY     1

# gameplay settings
.eqv    JUMP_SEED   10
.eqv    MOVE_SPEED  2

# colours
.eqv    DITTO_COLOUR_1  0xD8A3E0
.eqv    DITTO_COLOUR_2  0xEDD0F2
.eqv    DITTO_COLOUR_3  0x1c1c1c

.eqv	PLATFORM1_COLOUR	0x86DC3D

.eqv	ENEMY_COLOUR	0xfc2b78
.eqv	ENEMY_COLOUR1	0x00FFFF

.eqv	SHOOT_COLOUR	0xADD8E6

.data

.text
# if $a2 == 0 -> clear old map
#else draw new
.macro draw_undraw (%draw_label, %load_colours)
	beqz $a2, %load_colours
	move $t1, $zero
	move $t2, $zero	
	move $t3, $zero
	j %draw_label
.end_macro

# Takes x,y coordinates in $a0, $a1
# calculate the array adress and put $t0
.macro address_xy
	sll $a0, $a0, 2 #x*4
	sll $a1, $a1, 2 #y*4
	addi $t0, $a0, FRAME_BUFFER	# frame buffer + x offset -> $t0
	mul $t1, $a1, SCREEN_WIDTH	# y*width
	add $t0, $t1, $t0		# $t0 = $t1 + $t0
.end_macro

# pop from stack into register reg
.macro pop_stack (%reg)
	lw %reg, 0($sp)
	addi $sp, $sp, 4
.end_macro

# push onto stack
.macro push_stack (%reg)
	addi $sp, $sp, -4 
	sw %reg, 0($sp)
.end_macro

.globl main

#s0 = static_enemy_alive
#s1 = change_enemy_x
#s2 = enemy_x
#s4 = health
#s5 = change_height (default 0)
#s6 = x (0 < x < 48)
#s7 = y (0 < y < 114)
main:
	li $s4 3
main_again:
	li $s6 24
	li $s7 50
	li $s5 0
	li $s3 0
	li $s2 20
	li $s1 1
	li $s0 0
	jal clear_screen
	blez $s4, game_over
	addi $s4, $s4, -1
set_platform:
	li $t9 1 #i = 0
	la $t8, PLATFORM_BUFFER
	addi $a0, $s7, 32
	sw $s6, 0($t8) #x
	sw $a0, 4($t8) #y
	sw $zero, 8($t8) #type 0


	#for i < 10
set_platform_loop:
	bge $t9, 10, loop #if i>=15 end loop

	#random 0~42 (x)
	li $v0, 42
	li $a0, 0
	li $a1, 48
	syscall

	mul $t3, $t9, 12
	add $t4, $t8, $t3 #access first(x)
	 
	sw $a0, 0($t4) #x
	mul $a0, $t9, 11	

	sw $a0, 4($t4) #y
	
	li $a0, 1
	sw $a0, 8($t4) #type 0

	addi $t9, $t9, 1 #i++
	j set_platform_loop

loop:
	# check for key input and handle it if necessary
	li $t9, INPUT_BUFFER 
	lw $t8, 0($t9)
	bne $t8, 1, loop_no_input
	lw $a0, 4($t9) 			# this assumes $t9 is set to 0xfff0000 from before
	jal handle_input
loop_no_input:
	# draw ditto at possibly updated coordinates
	jal change_height
	move $a0, $s6		# move x into param 1
	move $a1, $s7		# move y into param 2
	move $a2, $zero		# move False into param 3: undraw
	jal draw_ditto
	jal set_enemy
	jal draw_static_enemy
	jal loop_draw_platform
	jal pause
	j loop

######## Functions - call these with jal

change_height:
	move $a0, $s6		# move x into param 1
	move $a1, $s7		# move y into param 2
	li $a2, 2		# move True into param 3: undraw
	push_stack ($ra)
	jal draw_ditto
	addi $s5, $s5, 1
	add $s7, $s7, $s5
	bgt $s7, 113, change_height_check_1
	#check move up platform
	blt $s7, 40, loop_platform
change_height_1:
	pop_stack ($ra)
	jr $ra

change_height_check_1:
	j main_again


loop_platform:
	li $t9 0 #i = 0
	la $t8, PLATFORM_BUFFER

platform_loop:
	bge $t9, 10, change_height_1 #if i>=8 end loop
	addi $s7, $zero, 40 #y = 40

	mul $t3, $t9, 12
	add $t4, $t8, $t3 #access first(x)

	lw $a0, 0($t4) #platform[i].x
	lw $a1, 4($t4) #platform[i].y
	
	push_stack($ra)
	li $a2, 1
	jal draw_platform1
	pop_stack($ra)

	lw $a0, 0($t4) #platform[i].x
	lw $a1, 4($t4) #platform[i].y
	lw $a2, 8($t4) #platform[i].type
	beq $a2, 1, platform_move

platform_loop_1:

	sub $a1, $a1, $s5


	li $t7, 128

	ble $a1, $t7, platform_loop_next
	#random 0~42 (x)
	li $v0, 42
	li $a0, 0
	li $a1, 48
	syscall

	li $a1, 0

platform_loop_next:
	#update
	sw $a0, 0($t4) #platform[i].x
	sw $a1, 4($t4) #platform[i].y

	addi $t9, $t9, 1 #i++
	j platform_loop

platform_move:
	addi $a0, $a0, 1
	beq $a0, 113, change_platform_move_1
	j platform_loop_1

change_platform_move_1:
	li $a0, 0
	j platform_loop_1

game_over:
	jal pause
	#Check until P pressed
	li $a0, 25
	li $a1, 50
	li $a2, 0
	jal draw_ditto
	li $t9, INPUT_BUFFER 
	lw $t8, 0($t9)
	bne $t8, 1, game_over
	lw $t8, 4($t9)
	beq $t8, 0x70, main
	j game_over	#keep looping

# Clear the screen. No params.
clear_screen:
	li $t2, 0
	li $t1, SCREEN_WIDTH
	mul $t1, $t1, SCREEN_HEIGHT
	sll $t1, $t1, 2
	li $t0, FRAME_BUFFER	# load start address into $t0
	addi $t1, $t1, FRAME_BUFFER	# load final address into $t1
clear_screen_loop:
	addi $t2, $t2, 1
	sw $zero, 0($t0)		# clear pixel
	addi $t0, $t0, 4
	push_stack ($ra)
	jal over_pause
	pop_stack ($ra)
	ble $t0, $t1, clear_screen_loop
	jr $ra
# pause
pause:
	li $a0, FRAME_DELAY
	li $v0, 32
	syscall
	jr $ra
# pause
over_pause:
	li $t3, 10
	div $t2, $t3
	mfhi $t2
	bnez $t2 over_pause_end
	li $a0, CLEAR_DELAY
	li $v0, 32
	syscall
	jr $ra
over_pause_end:
	jr $ra


# params: $a0: key input, $s6: ditto X, $s7: ditto Y
handle_input:
	beq $a0, 0x61, ditto_left
	beq $a0, 0x64, ditto_right
	beq $a0, 0x65, ditto_shoot
	beq $a0, 0x70, main	
	jr $ra
ditto_left:
	blt $s6, 1, handle_input_return	# if ditto at left edge
	push_stack ($ra)	# save return address pointer
	# undraw at current position
	jal change_height
	addi $s6, $s6, -4
	pop_stack ($ra)
	jr $ra
ditto_right:
	bge $s6, 48, handle_input_return	# if ditto hit right
	push_stack ($ra)	# save return address pointer
	# undraw at current position
	jal change_height
	addi $s6, $s6, 4	# update global coords
	pop_stack ($ra)
	jr $ra
ditto_shoot:
	push_stack ($ra)
	jal shooting
	pop_stack ($ra)
handle_input_return:
	jr $ra
# draw the ditto at the specified coordinates
# if $a2 != 0, draw background pixels instead
# params: $a0: x, $a1: y, $a2: undraw
draw_ditto:
	address_xy
	draw_undraw (draw_ditto_draw, draw_ditto_colours)
draw_ditto_colours:
	li $t1, DITTO_COLOUR_1
	li $t2, DITTO_COLOUR_2
	li $t3, DITTO_COLOUR_3
draw_ditto_draw:
	sw $t3, 20($t0)
	sw $t3, 24($t0)
	
	sw $t3, 272($t0)
	sw $t2, 276($t0)
	sw $t2, 280($t0)
	sw $t3, 284($t0)
	sw $t3, 296($t0)
	sw $t3, 300($t0)

	sw $t3, 516($t0)
	sw $t3, 520($t0)
	sw $t3, 524($t0)
	sw $t3, 528($t0)
	sw $t2, 532($t0)
	sw $t2, 536($t0)
	sw $t2, 540($t0)
	sw $t3, 544($t0)
	sw $t3, 548($t0)
	sw $t2, 552($t0)
	sw $t2, 556($t0)
	sw $t3, 560($t0)

	sw $t3, 768($t0)
	sw $t2, 772($t0)
	sw $t1, 776($t0)
	sw $t3, 780($t0)
	sw $t2, 784($t0)
	sw $t3, 788($t0)
	sw $t2, 792($t0)
	sw $t2, 796($t0)
	sw $t1, 800($t0)
	sw $t1, 804($t0)
	sw $t2, 808($t0)
	sw $t2, 812($t0)
	sw $t1, 816($t0)
	sw $t3, 820($t0)

	sw $t3, 1024($t0)
	sw $t2, 1028($t0)
	sw $t2, 1032($t0)
	sw $t2, 1036($t0)
	sw $t2, 1040($t0)
	sw $t2, 1044($t0)
	sw $t2, 1048($t0)
	sw $t2, 1052($t0)
	sw $t2, 1056($t0)
	sw $t3, 1060($t0)
	sw $t2, 1064($t0)
	sw $t2, 1068($t0)
	sw $t2, 1072($t0)
	sw $t3, 1076($t0)

	sw $t3, 1280($t0)
	sw $t1, 1284($t0)
	sw $t2, 1288($t0)
	sw $t2, 1292($t0)
	sw $t3, 1296($t0)
	sw $t3, 1300($t0)
	sw $t2, 1304($t0)
	sw $t2, 1308($t0)
	sw $t2, 1312($t0)
	sw $t2, 1316($t0)
	sw $t2, 1320($t0)
	sw $t2, 1324($t0)
	sw $t2, 1328($t0)
	sw $t2, 1332($t0)
	sw $t3, 1336($t0)

	sw $t3 1536($t0)
	sw $t3 1540($t0)
	sw $t1 1544($t0)
	sw $t2 1548($t0)
	sw $t2 1552($t0)
	sw $t2 1556($t0)
	sw $t3 1560($t0)
	sw $t3 1564($t0)
	sw $t3 1568($t0)
	sw $t3 1572($t0)
	sw $t2 1576($t0)
	sw $t2 1580($t0)
	sw $t2 1584($t0)
	sw $t2 1588($t0)
	sw $t3 1592($t0)

	sw $t3 1796($t0)
	sw $t1 1800($t0)
	sw $t2 1804($t0)
	sw $t2 1808($t0)
	sw $t2 1812($t0)
	sw $t2 1816($t0)
	sw $t2 1820($t0)
	sw $t2 1824($t0)
	sw $t2 1828($t0)
	sw $t2 1832($t0)
	sw $t2 1836($t0)
	sw $t2 1840($t0)
	sw $t2 1844($t0)
	sw $t3 1848($t0)

	sw $t3 2048($t0)
	sw $t1 2052($t0)
	sw $t1 2056($t0)
	sw $t2 2060($t0)
	sw $t2 2064($t0)
	sw $t2 2068($t0)
	sw $t2 2072($t0)
	sw $t2 2076($t0)
	sw $t2 2080($t0)
	sw $t2 2084($t0)
	sw $t3 2088($t0)
	sw $t2 2092($t0)
	sw $t2 2096($t0)
	sw $t2 2100($t0)
	sw $t2 2104($t0)
	sw $t3 2108($t0)
	
	sw $t3 2304($t0)
	sw $t1 2308($t0)
	sw $t1 2312($t0)
	sw $t1 2316($t0)
	sw $t2 2320($t0)
	sw $t2 2324($t0)
	sw $t2 2328($t0)
	sw $t2 2332($t0)
	sw $t2 2336($t0)
	sw $t2 2340($t0)
	sw $t2 2344($t0)
	sw $t3 2348($t0)
	sw $t3 2352($t0)
	sw $t2 2356($t0)
	sw $t1 2360($t0)
	sw $t3 2364($t0)

	sw $t3 2560($t0)
	sw $t1 2564($t0)
	sw $t1 2568($t0)
	sw $t1 2572($t0)
	sw $t1 2576($t0)
	sw $t2 2580($t0)
	sw $t2 2584($t0)
	sw $t2 2588($t0)
	sw $t1 2592($t0)
	sw $t1 2596($t0)
	sw $t1 2600($t0)
	sw $t2 2604($t0)
	sw $t2 2608($t0)
	sw $t1 2612($t0)
	sw $t1 2616($t0)
	sw $t3 2620($t0)

	sw $t3 2820($t0)
	sw $t1 2824($t0)
	sw $t1 2828($t0)
	sw $t1 2832($t0)
	sw $t1 2836($t0)
	sw $t1 2840($t0)
	sw $t1 2844($t0)
	sw $t1 2848($t0)
	sw $t1 2852($t0)
	sw $t1 2856($t0)
	sw $t1 2860($t0)
	sw $t1 2864($t0)
	sw $t1 2868($t0)
	sw $t1 2872($t0)
	sw $t3 2876($t0)

	sw $t3 3080($t0)
	sw $t3 3084($t0)
	sw $t1 3088($t0)
	sw $t1 3092($t0)
	sw $t1 3096($t0)
	sw $t1 3100($t0)
	sw $t3 3104($t0)
	sw $t3 3108($t0)
	sw $t1 3112($t0)
	sw $t1 3116($t0)
	sw $t1 3120($t0)
	sw $t1 3124($t0)
	sw $t3 3128($t0)

	sw $t3 3344($t0)
	sw $t3 3348($t0)
	sw $t3 3352($t0)
	sw $t3 3356($t0)
	sw $t3 3368($t0)
	sw $t3 3372($t0)
	sw $t3 3376($t0)
	sw $t3 3380($t0)
	jr $ra

loop_draw_platform:
	li $t9 0 #i = 0
	la $t8, PLATFORM_BUFFER

	push_stack ($ra)
	#for i < 10

platform_draw_loop:
	bge $t9, 10, platform_draw_loop_end #if i>=15 end loop
	
	mul $t3, $t9, 12
	add $t4, $t8, $t3 #access first(x)

	lw $a0, 0($t4)
	lw $a1, 4($t4)
	li $a2, 0

	addi $t5, $s6, 3
	#bge $t5, $a0 stap_platform_1
#platform_draw_loop1:
	
	jal draw_platform1

	addi $t9, $t9, 1 #i++
	j platform_draw_loop
platform_draw_loop_end:
	pop_stack ($ra)
	jr $ra

draw_platform1:
	address_xy
	draw_undraw (draw_platform1_draw, draw_platform1_colours)
draw_platform1_colours:
	li $t1, PLATFORM1_COLOUR
draw_platform1_draw:
	push_stack ($ra)
	lw $t5, 0($t0)
	jal draw_platform1_draw_loop_check
	sw $t1, 0($t0)
	lw $t5, 4($t0)
	jal draw_platform1_draw_loop_check
	sw $t1, 4($t0)
	lw $t5, 8($t0)
	jal draw_platform1_draw_loop_check
	sw $t1, 8($t0)
	lw $t5, 12($t0)
	jal draw_platform1_draw_loop_check
	sw $t1, 12($t0)
	lw $t5, 16($t0)
	jal draw_platform1_draw_loop_check
	sw $t1, 16($t0)
	lw $t5, 20($t0)
	jal draw_platform1_draw_loop_check
	sw $t1, 20($t0)
	lw $t5, 24($t0)
	jal draw_platform1_draw_loop_check
	sw $t1, 24($t0)
	lw $t5, 28($t0)
	jal draw_platform1_draw_loop_check
	sw $t1, 28($t0)
	lw $t5, 32($t0)
	jal draw_platform1_draw_loop_check
	sw $t1, 32($t0)
	lw $t5, 36($t0)
	jal draw_platform1_draw_loop_check
	sw $t1, 36($t0)
	lw $t5, 40($t0)
	jal draw_platform1_draw_loop_check
	sw $t1, 40($t0)
	lw $t5, 44($t0)
	jal draw_platform1_draw_loop_check
	sw $t1, 44($t0)
	lw $t5, 48($t0)
	jal draw_platform1_draw_loop_check
	sw $t1, 48($t0)
	lw $t5, 52($t0)
	jal draw_platform1_draw_loop_check
	sw $t1, 52($t0)
	lw $t5, 56($t0)
	jal draw_platform1_draw_loop_check
	sw $t1, 56($t0)
	pop_stack ($ra)
	j draw_platform1_draw_loop_end
draw_platform1_draw_loop_check:
	la $t6, DITTO_COLOUR_3
	bne $t5, $t6, draw_platform1_draw_loop_end
	blez $s5, draw_platform1_draw_loop_end
	li $s5, -10
	pop_stack ($ra)
	jr $ra

draw_platform1_draw_loop_end:
	jr $ra

draw_enemy:
	address_xy
	draw_undraw (draw_enemy_draw, draw_enemy_colours)
draw_enemy_colours:
	li $t1, ENEMY_COLOUR
	li $t2, ENEMY_COLOUR1
draw_enemy_draw:
	lw $t6, 0($t0)
	beq $t6 DITTO_COLOUR_1, check_collision
	beq $t6 DITTO_COLOUR_2, check_collision
	beq $t6 DITTO_COLOUR_3, check_collision
	sw $t1, 0($t0)
	lw $t6, 4($t0)
	beq $t6 DITTO_COLOUR_1, check_collision
	beq $t6 DITTO_COLOUR_2, check_collision
	beq $t6 DITTO_COLOUR_3, check_collision
	sw $t1, 4($t0)
	lw $t6, 8($t0)
	beq $t6 DITTO_COLOUR_1, check_collision
	beq $t6 DITTO_COLOUR_2, check_collision
	beq $t6 DITTO_COLOUR_3, check_collision
	sw $t1, 8($t0)
	lw $t6, 256($t0)
	beq $t6 DITTO_COLOUR_1, check_collision
	beq $t6 DITTO_COLOUR_2, check_collision
	beq $t6 DITTO_COLOUR_3, check_collision
	sw $t1, 256($t0)
	lw $t6, 260($t0)
	beq $t6 DITTO_COLOUR_1, check_collision
	beq $t6 DITTO_COLOUR_2, check_collision
	beq $t6 DITTO_COLOUR_3, check_collision
	sw $t1, 260($t0)
	lw $t6, 264($t0)
	beq $t6 DITTO_COLOUR_1, check_collision
	beq $t6 DITTO_COLOUR_2, check_collision
	beq $t6 DITTO_COLOUR_3, check_collision
	sw $t1, 264($t0)
	lw $t6, 512($t0)
	beq $t6 DITTO_COLOUR_1, check_collision
	beq $t6 DITTO_COLOUR_2, check_collision
	beq $t6 DITTO_COLOUR_3, check_collision
	sw $t1, 512($t0)
	lw $t6, 516($t0)
	beq $t6 DITTO_COLOUR_1, check_collision
	beq $t6 DITTO_COLOUR_2, check_collision
	beq $t6 DITTO_COLOUR_3, check_collision
	sw $t1, 516($t0)
	lw $t6, 520($t0)
	beq $t6 DITTO_COLOUR_1, check_collision
	beq $t6 DITTO_COLOUR_2, check_collision
	beq $t6 DITTO_COLOUR_3, check_collision
	sw $t1, 520($t0)
	jr $ra

set_enemy:
	bgt $s2, -10, set_pass_enemy
	jr $ra
set_pass_enemy:
	push_stack ($ra)
	#clear enemy
	move $a0, $s2
	move $a1, $s3
	li $a2, 1
	jal draw_enemy

	#check at end
	move $a0, $s2
	move $a1, $s3
	beqz $a0, change_enemy_x
	beq $a0, 125, change_enemy_x
set_enemy_1:
	#set x of enemy
	add $a0, $s2, $s1
	#check move
	ble $s7, 40, set_enemy_2
	j enemy_update
set_enemy_2:
	#move down
	sub $a1, $a1, $s5
	li $t7, 128
	#check below end
	ble $a1, $t7, enemy_update

	#random 0~42 (x)
	li $v0, 42
	li $a0, 0
	li $a1, 48
	syscall

	li $a1, 0

	j enemy_update
change_enemy_x:
	#change direction
	mul $s1, $s1, -1
	j set_enemy_1

enemy_update:
	#redraw
	move $s2, $a0
	move $s3, $a1
	li $a2, 0
	jal draw_enemy
	pop_stack($ra)
	jr $ra

check_collision:
	pop_stack ($ra)
	j main_again

draw_static_enemy:
	beqz $s0, set_pass_statc_enemy
	jr $ra
set_pass_statc_enemy:
	li $a0, 10
	li $a1, 70
	address_xy
	li $t2, ENEMY_COLOUR1
	lw $t6, 1024($t0)
	beq $t6 DITTO_COLOUR_1, check_collision
	beq $t6 DITTO_COLOUR_2, check_collision
	beq $t6 DITTO_COLOUR_3, check_collision
	sw $t2, 1024($t0)
	lw $t6, 1028($t0)
	beq $t6 DITTO_COLOUR_1, check_collision
	beq $t6 DITTO_COLOUR_2, check_collision
	beq $t6 DITTO_COLOUR_3, check_collision
	sw $t2, 1028($t0)
	lw $t6, 1032($t0)
	beq $t6 DITTO_COLOUR_1, check_collision
	beq $t6 DITTO_COLOUR_2, check_collision
	beq $t6 DITTO_COLOUR_3, check_collision
	sw $t2, 1032($t0)
	lw $t6, 1280($t0)
	beq $t6 DITTO_COLOUR_1, check_collision
	beq $t6 DITTO_COLOUR_2, check_collision
	beq $t6 DITTO_COLOUR_3, check_collision
	sw $t2, 1280($t0)
	lw $t6, 1284($t0)
	beq $t6 DITTO_COLOUR_1, check_collision
	beq $t6 DITTO_COLOUR_2, check_collision
	beq $t6 DITTO_COLOUR_3, check_collision
	sw $t2, 1284($t0)
	lw $t6, 1288($t0)
	beq $t6 DITTO_COLOUR_1, check_collision
	beq $t6 DITTO_COLOUR_2, check_collision
	beq $t6 DITTO_COLOUR_3, check_collision
	sw $t2, 1288($t0)
	lw $t6, 1536($t0)
	beq $t6 DITTO_COLOUR_1, check_collision
	beq $t6 DITTO_COLOUR_2, check_collision
	beq $t6 DITTO_COLOUR_3, check_collision
	sw $t2, 1536($t0)
	lw $t6, 1540($t0)
	beq $t6 DITTO_COLOUR_1, check_collision
	beq $t6 DITTO_COLOUR_2, check_collision
	beq $t6 DITTO_COLOUR_3, check_collision
	sw $t2, 1540($t0)
	lw $t6, 1544($t0)
	beq $t6 DITTO_COLOUR_1, check_collision
	beq $t6 DITTO_COLOUR_2, check_collision
	beq $t6 DITTO_COLOUR_3, check_collision
	sw $t2, 1544($t0)
	jr $ra


draw_shooting:
	address_xy
	draw_undraw (draw_shooting_1, draw_shooting_colour)
draw_shooting_colour:
	li $t1, SHOOT_COLOUR
draw_shooting_1:
	push_stack ($ra)
	lw $t5, 0($t0)
	jal draw_shoot_check
	sw $t1, 0($t0)
	lw $t5, 4($t0)
	jal draw_shoot_check
	sw $t1, 4($t0)
	lw $t5, 8($t0)
	jal draw_shoot_check
	sw $t1, 8($t0)
	lw $t5, 12($t0)
	jal draw_shoot_check
	sw $t1, 12($t0)
	lw $t5, 16($t0)
	jal draw_shoot_check
	sw $t1, 16($t0)
	lw $t5, 20($t0)
	jal draw_shoot_check
	sw $t1, 20($t0)
	lw $t5, 24($t0)
	jal draw_shoot_check
	sw $t1, 24($t0)
	lw $t5, 28($t0)
	jal draw_shoot_check
	sw $t1, 28($t0)
	lw $t5, 32($t0)
	jal draw_shoot_check
	sw $t1, 32($t0)
	lw $t5, 36($t0)
	jal draw_shoot_check
	sw $t1, 36($t0)
	lw $t5, 40($t0)
	jal draw_shoot_check
	sw $t1, 40($t0)
	lw $t5, 44($t0)
	jal draw_shoot_check
	sw $t1, 44($t0)
	lw $t5, 48($t0)
	jal draw_shoot_check
	sw $t1, 48($t0)
	lw $t5, 52($t0)
	jal draw_shoot_check
	sw $t1, 52($t0)
	lw $t5, 56($t0)
	jal draw_shoot_check
	sw $t1, 56($t0)
	pop_stack ($ra)
	jr $ra
draw_shoot_check:
	la $t6, ENEMY_COLOUR
	la $t7, ENEMY_COLOUR1
	bne $t5, $t6, draw_shoot_check_1
	li $s2, -10
draw_shoot_check_1:	
	bne $t5, $t7, draw_shoot_check_2
	li $s0, 1
draw_shoot_check_2:
	jr $ra


draw_shooting_loop_1:
	push_stack ($ra)
	
draw_shooting_loop_2:
	move $a0, $t8
	move $a1, $t9
	beq $a1, 0, draw_shooting_loop_2_end
	jal draw_shooting
	addi $t9, $t9, -1
	j draw_shooting_loop_2

draw_shooting_loop_2_end:
	pop_stack($ra)
	jr $ra
shooting:
	push_stack ($ra)
	move $t8, $s6
	move $t9, $s7
	li $a2, 0
	jal draw_shooting_loop_1
	jal shoot_pause
	move $t8, $s6
	move $t9, $s7
	li $a2, 2
	jal draw_shooting_loop_1
	pop_stack ($ra)
	jr $ra

shoot_pause:
	li $a0, 500
	li $v0, 32
	syscall
	jr $ra


# draw_gameover:
# 	address_xy
# 	li $t1, DITTO_COLOUR_1
