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
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
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

######## Constants
.eqv 	SCREEN_WIDTH	64	# units
.eqv 	SCREEN_HEIGHT	128	# units
.eqv    FRAME_DELAY     20

# gameplay settings
.eqv    JUMP_SEED   10
.eqv    MOVE_SPEED  2

# colours
.eqv    DITTO_COLOUR_1  0xD8A3E0
.eqv    DITTO_COLOUR_2  0xEDD0F2

.text
.macro pop_stack (%reg)
	lw %reg, 0($sp)
	addi $sp, $sp, 4
.end_macro

.macro push_stack (%reg)
	addi $sp, $sp, -4 
	sw %reg, 0($sp)
.end_macro

.globl main

main:


