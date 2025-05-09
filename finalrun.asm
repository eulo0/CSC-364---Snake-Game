######################################################################
# SNAKE!!!! #
######################################################################
# Programmed by Shane Shafferman and Eric Deas #
######################################################################
# Additions by Nathan Vanhoof, Elijah Palmer, and Anousith Keomaly
######################################################################
# This program requires the Keyboard and Display MMIO #
# and the Bitmap Display to be connected to MIPS. #
# #
# Bitmap Display Settings: #
# Unit Width: 8 #
# Unit Height: 8 #
# Display Width: 512 #
# Display Height: 512 #
# Base Address for Display: 0x10008000 ($gp) #
######################################################################
.data
#Game Core information
newLine: .asciiz "\n"

#Screen
screenWidth: .word 64
screenHeight: .word 64
#Colors
snakeColor: .word 0x0066cc # blue
backgroundColor:.word 0x000000 # black
borderColor: .word 0xff0000 # red (originally green)
fruitColor: .word 0xcc6611 # orange
# Colors for new fruits
fruitColorReverse: .word 0x800080  # Purple - reverses direction
fruitColorSpeed: .word 0x00ffff    # Cyan - increases speed
fruitColorBomb: .word 0x99ff99     # Light green - bomb kills snake
fruitColorLarge: .word 0xffff00    # yellow - large fruit
#score variable
score: .word 0
#stores how many points are recieved for eating a fruit
#increases as program gets harder
scoreGain: .word 10
#speed the snake moves at, increases as game progresses
gameSpeed: .word 200
#array to store the scores in which difficulty should increase
scoreMilestones: .word 100, 250, 500, 1000, 5000, 10000
scoreArrayPosition: .word 0
#end game message
lostMessage: .asciiz "You have died.... Your score was: "
replayMessage: .asciiz "Would you like to replay?"
#Snake Information
snakeHeadX: .word 31
snakeHeadY: .word 31
snakeTailX: .word 31
snakeTailY: .word 37
direction: .word 119 #initially moving up
tailDirection: .word 119
# direction variable
# 119 - moving up - W
# 115 - moving down - S
# 97 - moving left - A
# 100 - moving right - D
# numbers are selected due to ASCII characters
#this array stores the screen coordinates of a direction change
#once the tail hits a position in this array, its direction is changed
#this is used to have the tail follow the head correctly
directionChangeAddressArray: .word 0:100
#this stores the new direction for the tail to move once it hits
#an address in the above array
newDirectionChangeArray: .word 0:100
#stores the position of the end of the array (multiple of 4)
arrayPosition: .word 0
locationInArray: .word 0
#Fruit Information
fruitPositionX: .word 0
fruitPositionY: .word 0
fruitReverseX: .word 0
fruitReverseY: .word 0
fruitSpeedX: .word 0
fruitSpeedY: .word 0
fruitBombX: .word 0
fruitBombY: .word 0
fruitLargeX: .word 0
fruitLargeY: .word 0
scoreString: .asciiz "Current Score: "
clearString: .asciiz "\n\n\n\n\n\n\n\n\n\n\n\n\n"
fruitLastEaten: .word 0
fruitsInitialized: .word 0

.text
main:
######################################################
# Fill Screen to Black, for reset
######################################################
lw $a0, screenWidth
lw $a1, backgroundColor
mul $a2, $a0, $a0 #total number of pixels on screen
mul $a2, $a2, 4 #align addresses
add $a2, $a2, $gp #add base of gp
add $a0, $gp, $zero #loop counter
FillLoop:
beq $a0, $a2, Init
sw $a1, 0($a0) #store color
addiu $a0, $a0, 4 #increment counter
j FillLoop
######################################################
# Initialize Variables
######################################################
Init:
li $t0, 31
sw $t0, snakeHeadX
sw $t0, snakeHeadY
sw $t0, snakeTailX
li $t0, 37
sw $t0, snakeTailY
li $t0, 119
sw $t0, direction
sw $t0, tailDirection
li $t0, 10
sw $t0, scoreGain
li $t0, 200
sw $t0, gameSpeed
sw $zero, arrayPosition
sw $zero, locationInArray
sw $zero, scoreArrayPosition
sw $zero, score
li $t0, 1
sw $t0, fruitPositionX
sw $t0, fruitPositionY
sw $t0, fruitReverseX
sw $t0, fruitReverseY
sw $t0, fruitSpeedX
sw $t0, fruitSpeedY
sw $t0, fruitBombX
sw $t0, fruitBombY
sw $t0, fruitLargeX
sw $t0, fruitLargeY
ClearRegisters:
li $v0, 0
li $a0, 0
li $a1, 0
li $a2, 0
li $a3, 0
li $t0, 0
li $t1, 0
li $t2, 0
li $t3, 0
li $t4, 0
li $t5, 0
li $t6, 0
li $t7, 0
li $t8, 0
li $t9, 0
li $s0, 0
li $s1, 0
li $s2, 0
li $s3, 0
li $s4, 0
li $s5, 0
li $s6, 0
li $s7, 0
######################################################
# Draw Border
######################################################
DrawBorder:
li $t1, 0 #load Y coordinate for the left border
LeftLoop:
move $a1, $t1 #move y coordinate into $a1
li $a0, 0 # load x direction to 0, doesnt change
jal CoordinateToAddress #get screen coordinates
move $a0, $v0 # move screen coordinates into $a0
lw $a1, borderColor #move color code into $a1
jal DrawPixel #draw the color at the screen location
add $t1, $t1, 1 #increment y coordinate
bne $t1, 64, LeftLoop #loop through to draw entire left border
li $t1, 0 #load Y coordinate for right border
RightLoop:
move $a1, $t1 #move y coordinate into $a1
li $a0, 63 #set x coordinate to 63 (right side of screen)
jal CoordinateToAddress #convert to screen coordinates
move $a0, $v0 # move coordinates into $a0
lw $a1, borderColor #move color data into $a1
jal DrawPixel #draw color at screen coordinates
add $t1, $t1, 1 #increment y coordinate
bne $t1, 64, RightLoop #loop through to draw entire right border
li $t1, 0 #load X coordinate for top border
TopLoop:
move $a0, $t1 # move x coordinate into $a0
li $a1, 0 # set y coordinate to zero for top of screen
jal CoordinateToAddress #get screen coordinate
move $a0, $v0 # move screen coordinates to $a0
lw $a1, borderColor # store color data to $a1
jal DrawPixel #draw color at screen coordinates
add $t1, $t1, 1 #increment X position
bne $t1, 64, TopLoop #loop through to draw entire top border
li $t1, 0 #load X coordinate for bottom border
BottomLoop:
move $a0, $t1 # move x coordinate to $a0
li $a1, 63 # load Y coordinate for bottom of screen
jal CoordinateToAddress #get screen coordinates
move $a0, $v0 #move screen coordinates to $a0
lw $a1, borderColor #put color data into $a1
jal DrawPixel #draw color at screen position
add $t1, $t1, 1 #increment X coordinate
bne $t1, 64, BottomLoop # loop through to draw entire bottom border
######################################################
# Draw Initial Snake Position
######################################################
#draw snake head
lw $a0, snakeHeadX #load x coordinate
lw $a1, snakeHeadY #load y coordinate
jal CoordinateToAddress #get screen coordinates
move $a0, $v0 #copy coordinates to $a0
lw $a1, snakeColor #store color into $a1
jal DrawPixel #draw color at pixel
#draw middle portion
lw $a0, snakeHeadX #load x coordinate
lw $a1, snakeHeadY #load y coordinate
add $a1, $a1, 1
jal CoordinateToAddress #get screen coordinates
move $a0, $v0 #copy coordinates to $a0
lw $a1, snakeColor #store color into $a1
jal DrawPixel #draw color at pixel
#TEST 8 PIXELS
lw $a0, snakeHeadX #load x coordinate
lw $a1, snakeHeadY #load y coordinate
add $a1, $a1, 2
jal CoordinateToAddress #get screen coordinates
move $a0, $v0 #copy coordinates to $a0
lw $a1, snakeColor #store color into $a1
jal DrawPixel #draw color at pixel
lw $a0, snakeHeadX #load x coordinate
lw $a1, snakeHeadY #load y coordinate
add $a1, $a1, 3
jal CoordinateToAddress #get screen coordinates
move $a0, $v0 #copy coordinates to $a0
lw $a1, snakeColor #store color into $a1
jal DrawPixel #draw color at pixel
lw $a0, snakeHeadX #load x coordinate
lw $a1, snakeHeadY #load y coordinate
add $a1, $a1, 4
jal CoordinateToAddress #get screen coordinates
move $a0, $v0 #copy coordinates to $a0
lw $a1, snakeColor #store color into $a1
jal DrawPixel #draw color at pixel
lw $a0, snakeHeadX #load x coordinate
lw $a1, snakeHeadY #load y coordinate
add $a1, $a1, 5
jal CoordinateToAddress #get screen coordinates
move $a0, $v0 #copy coordinates to $a0
lw $a1, snakeColor #store color into $a1
jal DrawPixel #draw color at pixel
lw $a0, snakeHeadX #load x coordinate
lw $a1, snakeHeadY #load y coordinate
add $a1, $a1, 6
jal CoordinateToAddress #get screen coordinates
move $a0, $v0 #copy coordinates to $a0
lw $a1, snakeColor #store color into $a1
jal DrawPixel #draw color at pixel
#draw snake tail
lw $a0, snakeTailX #load x coordinate
lw $a1, snakeTailY #load y coordinate
jal CoordinateToAddress #get screen coordinates
move $a0, $v0 #copy coordinates to $a0
lw $a1, snakeColor #store color into $a1
jal SpawnFruit      # Create fruits once at game start
jal DrawFruit       # Draw them to screen
j InputCheck        # Start the game loop

######################################################
# Spawn Fruit
######################################################
SpawnFruit:
lw $t0, fruitLastEaten # Loads the last fruit 1=orange, 2=purple, etc
beq $t0, 1, SkipOrange # If last fruit orange, skip clearing orange's position
lw $a0, fruitPositionX # Load X position of orange into $a0
lw $a1, fruitPositionY # Load Y position of orange into $a1
jal ClearOldFruitPosition # Call to clear orange last drawn position

# Clears orange position
SkipOrange:
beq $t0, 2, SkipPurple # If last fruit pruple, skip clearing purple's position
lw $a0, fruitReverseX # Load X position of purple into $a0
lw $a1, fruitReverseY # Load Y position of purple into $a1
jal ClearOldFruitPosition # Call to clear purple last drawn position

# Clears purple position
SkipPurple:
beq $t0, 3, SkipCyan     # If last fruit cyan, skip clearing purple's position
lw $a0, fruitSpeedX      # Load X position of cyan into $a0
lw $a1, fruitSpeedY      # Load Y position of cyan into $a0
jal ClearOldFruitPosition # Call to clear cyan last drawn position

# Clears cyan position
SkipCyan:
lw $a0, fruitLargeX       # load X position of large into $a0
lw $a1, fruitLargeY       # load Y position of large into $a1
jal ClearOldFruitPosition # call to clear large fruit last drawn position
    
# Clears green position
lw $a0, fruitBombX # load X position of bomb fruit into $a0
lw $a1, fruitBombY # load Y position of bomb fruit into $a0
jal ClearOldFruitPosition
    
# clears large fruit top left position
lw $a0, fruitLargeX # Load X position of light green into $a0
lw $a1, fruitLargeY # Load Y position of light green into $a0
addi $a0, $a0, -1
addi $a1, $a1, -1
jal ClearOldFruitPosition # Call to clear light green last drawn position
    
# clears large fruit top middle position
lw $a0, fruitLargeX # Load X position of light green into $a0
lw $a1, fruitLargeY # Load Y position of light green into $a0
addi $a1, $a1, -1
jal ClearOldFruitPosition # Call to clear light green last drawn position
    
# clears large fruit top right position
lw $a0, fruitLargeX # Load X position of light green into $a0
lw $a1, fruitLargeY # Load Y position of light green into $a0
addi $a0, $a0, 1
addi $a1, $a1, -1
jal ClearOldFruitPosition # Call to clear light green last drawn position
    
# clears large fruit mid left position
lw $a0, fruitLargeX # Load X position of light green into $a0
lw $a1, fruitLargeY # Load Y position of light green into $a0
addi $a0, $a0, -1
jal ClearOldFruitPosition # Call to clear light green last drawn position
    
# clears large fruit midmid position
lw $a0, fruitLargeX # Load X position of light green into $a0
lw $a1, fruitLargeY # Load Y position of light green into $a0
jal ClearOldFruitPosition # Call to clear light green last drawn position
    
# clears large fruit mid right position
lw $a0, fruitLargeX # Load X position of light green into $a0
lw $a1, fruitLargeY # Load Y position of light green into $a0
addi $a0, $a0, 1
jal ClearOldFruitPosition # Call to clear light green last drawn position
    
# clears large fruit btm left position
lw $a0, fruitLargeX # Load X position of light green into $a0
lw $a1, fruitLargeY # Load Y position of light green into $a0
addi $a0, $a0, -1
addi $a1, $a1, 1
jal ClearOldFruitPosition # Call to clear light green last drawn position
    
# clears large fruit btm mid position
lw $a0, fruitLargeX # Load X position of light green into $a0
lw $a1, fruitLargeY # Load Y position of light green into $a0
addi $a1, $a1, 1
jal ClearOldFruitPosition # Call to clear light green last drawn position
    
# clears large fruit btm right position
lw $a0, fruitLargeX # Load X position of light green into $a0
lw $a1, fruitLargeY # Load Y position of light green into $a0
addi $a0, $a0, 1
addi $a1, $a1, 1
jal ClearOldFruitPosition # Call to clear light green last drawn position
    
la $t8, fruitsInitialized # fruits have been drawn once, set fruits initialized to 1
li $t7, 1 # this word label will be used when drawing fruits. we dont want to clear fruits...
sw $t7, 0($t8) #...the first time fruits are drawn (adding my large fruit was breaking things and this fixed it)
    
# deleting a large fruit can delete the snake head, so redraw only the snake head
lw $a0, snakeHeadX # Load purple X
lw $a1, snakeHeadY # Load purple Y
jal CoordinateToAddress # Convert the X and Y to coordinates
move $a0, $v0 # Move address to $a0
lw $a1, snakeColor # Load color for snake
jal DrawPixel # Draw snake head
    
# Prints the score
li $v0, 4 # Print string 
la $a0, clearString # Load address of clearString
syscall # Print syscall
la $a0, scoreString # Load score
syscall # Print score
    
li $v0, 1 # Print integer syscall
lw $a0, score # Load current score to $a0
syscall # Print score
    
# Spawn large fruit
li $v0, 42 # Random number syscall
li $a1, 60 # Upperbound
syscall # Generate number
addiu $a0, $a0, 2 #Offset by 2
sw $a0, fruitLargeX # Store large X
syscall # Generate another random number 
addiu $a0, $a0, 2 #Offset by 2
sw $a0, fruitLargeY # Store large Y

# Spawn orange fruit
li $v0, 42 # Random number syscall
li $a1, 62 # Upperbound
syscall # Generate number
addiu $a0, $a0, 1 #Offset by 1
sw $a0, fruitPositionX # Store orange X
syscall # Generate another random number 
addiu $a0, $a0, 1 #Offset by 1
sw $a0, fruitPositionY # Store orange Y

# Spawn purple fruit
li $v0, 42 # Random number syscall
li $a1, 62 # Upperbound
syscall # Generate number
addiu $a0, $a0, 1 #Offset by 1
sw $a0, fruitReverseX # Store purple X
syscall # Generate another random number 
addiu $a0, $a0, 1 #Offset by 1
sw $a0, fruitReverseY # Store purple Y

# Spawn cyan fruit
li $v0, 42 # Random number syscall
li $a1, 62 # Upperbound
syscall # Generate number
addiu $a0, $a0, 1 #Offset by 1
sw $a0, fruitSpeedX # Store cyan X
syscall # Generate another random number 
addiu $a0, $a0, 1 #Offset by 1
sw $a0, fruitSpeedY # Store cyan Y

# Spawn bomb fruit
li $v0, 42 # Random number syscall
li $a1, 62 # Upperbound
syscall # Generate number
addiu $a0, $a0, 1 #Offset by 1
sw $a0, fruitBombX # Store light green X
syscall # Generate another random number 
addiu $a0, $a0, 1 #Offset by 1
sw $a0, fruitBombY # Store light green Y

jal IncreaseDifficulty # Call function to increase game difficulty 
j InputCheck # Jump to input

# Clears the old fruits position
ClearOldFruitPosition:
move $t9, $ra # Save return address into $t9
add $t0, $a0, $0 # Copy X coordinate 
add $t1, $a1, $0 # Copy Y coordinate
jal CoordinateToAddress # Convert X Y to coordinate 
move $a0, $v0 # Move made coordinate for drawing pixel
la $t8, fruitsInitialized # dont clear fruits if game just started; it will delete part of the border
lw $t8, 0($t8) # no reason to draw black onto anything on our first fruit spawn, so...
beq $t8, 1, DoClear # only clear if border wasnt just initialized
jr $t9 # Return to $ra stored at $t9

# this label does the clearing
DoClear:
lw $a1, backgroundColor # Load background color to erase fruit
jal DrawPixel # Draw pixel at (X,Y)
jr $t9 # Return to $ra stored at $t9

######################################################
# Check for Direction Change
######################################################
InputCheck:
lw $a0, gameSpeed
jal Pause
lw $t7, direction

#get the coordinates for direction change if needed
lw $a0, snakeHeadX
lw $a1, snakeHeadY
jal CoordinateToAddress
move $a2, $v0

#get the input from the keyboard
li $t0, 0xffff0000
lw $t1, ($t0)
andi $t1, $t1, 0x0001
beqz $t1, SelectDrawDirection

lw $a1, 4($t0) #store direction based on input
lw $a0, direction
jal CheckDirection
beqz $v0, SelectDrawDirection
sw $a1, direction
move $t7, $a1

DirectionCheck:
lw $a0, direction # load current direction into #a0
jal CheckDirection #check to see if the direction is valid
beqz $v0, InputCheck #if input is not valid, get new input
sw $a1, direction #store the new direction if valid
lw $t7, direction #store the direction into $t7
######################################################
# Update Snake Head position
######################################################
SelectDrawDirection:
#check to see which direction to draw
beq $t7, 119, DrawUpLoop
beq $t7, 115, DrawDownLoop
beq $t7, 97, DrawLeftLoop
beq $t7, 100, DrawRightLoop
#jump back to get input if an unsupported key was pressed
j InputCheck
DrawUpLoop:
#check for collision before moving to next pixel
lw $a0, snakeHeadX
lw $a1, snakeHeadY
lw $a2, direction
jal CheckGameEndingCollision
#draw head in new position, move Y position up
lw $t0, snakeHeadX
lw $t1, snakeHeadY
addiu $t1, $t1, -1
add $a0, $t0, $zero
add $a1, $t1, $zero
jal CoordinateToAddress
add $a0, $v0, $zero
lw $a1, snakeColor
jal DrawPixel
sw $t1, snakeHeadY
j UpdateTailPosition #head updated, update tail
DrawDownLoop:
#check for collision before moving to next pixel
lw $a0, snakeHeadX
lw $a1, snakeHeadY
lw $a2, direction
jal CheckGameEndingCollision
#draw head in new position, move Y position down
lw $t0, snakeHeadX
lw $t1, snakeHeadY
addiu $t1, $t1, 1
add $a0, $t0, $zero
add $a1, $t1, $zero
jal CoordinateToAddress
add $a0, $v0, $zero
lw $a1, snakeColor
jal DrawPixel
sw $t1, snakeHeadY
j UpdateTailPosition #head updated, update tail
DrawLeftLoop:
#check for collision before moving to next pixel
lw $a0, snakeHeadX
lw $a1, snakeHeadY
lw $a2, direction
jal CheckGameEndingCollision
#draw head in new position, move X position left
lw $t0, snakeHeadX
lw $t1, snakeHeadY
addiu $t0, $t0, -1
add $a0, $t0, $zero
add $a1, $t1, $zero
jal CoordinateToAddress
add $a0, $v0, $zero
lw $a1, snakeColor
jal DrawPixel
sw $t0, snakeHeadX
j UpdateTailPosition #head updated, update tail
DrawRightLoop:
#check for collision before moving to next pixel
lw $a0, snakeHeadX
lw $a1, snakeHeadY
lw $a2, direction
jal CheckGameEndingCollision
#draw head in new position, move X position right
lw $t0, snakeHeadX
lw $t1, snakeHeadY
addiu $t0, $t0, 1
add $a0, $t0, $zero
add $a1, $t1, $zero
jal CoordinateToAddress
add $a0, $v0, $zero
lw $a1, snakeColor
jal DrawPixel
sw $t0, snakeHeadX
j UpdateTailPosition #head updated, update tail

######################################################
# Update Snake Tail Position
######################################################
UpdateTailPosition:
lw $t2, tailDirection
#branch based on which direction tail is moving
beq $t2, 119, MoveTailUp
beq $t2, 115, MoveTailDown
beq $t2, 97, MoveTailLeft
beq $t2, 100, MoveTailRight
MoveTailUp:
#get the screen coordinates of the next direction change
lw $t8, locationInArray
la $t0, directionChangeAddressArray #get direction change coordinate
add $t0, $t0, $t8
lw $t9, 0($t0)
lw $a0, snakeTailX #get snake tail position
lw $a1, snakeTailY
#if the index is out of bounds, set back to zero
beq $s1, 1, IncreaseLengthUp #branch if length should be increased
addiu $a1, $a1, -1 #change tail position if no length change
sw $a1, snakeTailY
IncreaseLengthUp:
li $s1, 0 #set flag back to false
jal CoordinateToAddress
add $a0, $v0, $zero
bne $t9, $a0, DrawTailUp #change direction if needed
la $t3, newDirectionChangeArray #update direction
add $t3, $t3, $t8
lw $t9, 0($t3)
sw $t9, tailDirection
addiu $t8,$t8,4
#if the index is out of bounds, set back to zero
bne $t8, 396, StoreLocationUp
li $t8, 0
StoreLocationUp:
sw $t8, locationInArray
DrawTailUp:
lw $a1, snakeColor
jal DrawPixel
#erase behind the snake
lw $t0, snakeTailX
lw $t1, snakeTailY
addiu $t1, $t1, 1
add $a0, $t0, $zero
add $a1, $t1, $zero
jal CoordinateToAddress
add $a0, $v0, $zero
lw $a1, backgroundColor
jal DrawPixel
j  DrawFruit #finished updating snake, update fruit
MoveTailDown:
#get the screen coordinates of the next direction change
lw $t8, locationInArray
la $t0, directionChangeAddressArray #get direction change coordinate
add $t0, $t0, $t8
lw $t9, 0($t0)
lw $a0, snakeTailX #get snake tail position
lw $a1, snakeTailY
beq $s1, 1, IncreaseLengthDown #branch if length should be increased
addiu $a1, $a1, 1 #change tail position if no length change
sw $a1, snakeTailY
IncreaseLengthDown:
li $s1, 0 #set flag back to false
jal CoordinateToAddress
add $a0, $v0, $zero
bne $t9, $a0, DrawTailDown #change direction if needed
la $t3, newDirectionChangeArray #update direction
add $t3, $t3, $t8
lw $t9, 0($t3)
sw $t9, tailDirection
addiu $t8,$t8,4
#if the index is out of bounds, set back to zero
bne $t8, 396, StoreLocationDown
li $t8, 0
StoreLocationDown:
sw $t8, locationInArray
DrawTailDown:
lw $a1, snakeColor
jal DrawPixel
#erase behind the snake
lw $t0, snakeTailX
lw $t1, snakeTailY
addiu $t1, $t1, -1
add $a0, $t0, $zero
add $a1, $t1, $zero
jal CoordinateToAddress
add $a0, $v0, $zero
lw $a1, backgroundColor
jal DrawPixel
j  DrawFruit #finished updating snake, update fruit
MoveTailLeft:
#update the tail position when moving left
lw $t8, locationInArray
la $t0, directionChangeAddressArray #get direction change coordinate
add $t0, $t0, $t8
lw $t9, 0($t0)
lw $a0, snakeTailX #get snake tail position
lw $a1, snakeTailY
beq $s1, 1, IncreaseLengthLeft #branch if length should be increased
addiu $a0, $a0, -1 #change tail position if no length change
sw $a0, snakeTailX
IncreaseLengthLeft:
li $s1, 0 #set flag back to false
jal CoordinateToAddress
add $a0, $v0, $zero
bne $t9, $a0, DrawTailLeft #change direction if needed
la $t3, newDirectionChangeArray #update direction
add $t3, $t3, $t8
lw $t9, 0($t3)
sw $t9, tailDirection
addiu $t8,$t8,4
#if the index is out of bounds, set back to zero
bne $t8, 396, StoreLocationLeft
li $t8, 0
StoreLocationLeft:
sw $t8, locationInArray
DrawTailLeft:
lw $a1, snakeColor
jal DrawPixel
#erase behind the snake
lw $t0, snakeTailX
lw $t1, snakeTailY
addiu $t0, $t0, 1
add $a0, $t0, $zero
add $a1, $t1, $zero
jal CoordinateToAddress
add $a0, $v0, $zero
lw $a1, backgroundColor
jal DrawPixel
j  DrawFruit #finished updating snake, update fruit
MoveTailRight:
#get the screen coordinates of the next direction change
lw $t8, locationInArray
#get the base address of the coordinate array
la $t0, directionChangeAddressArray
#go to the correct index of array
add $t0, $t0, $t8
#get the data from the array
lw $t9, 0($t0)
#get current tail position
lw $a0, snakeTailX
lw $a1, snakeTailY
#if the length needs to be increased
#do not change coordinates
beq $s1, 1, IncreaseLengthRight
#change tail position
addiu $a0, $a0, 1
#store new tail position
sw $a0, snakeTailX
IncreaseLengthRight:
li $s1, 0 #set flag back to false
#get screen coordinates
jal CoordinateToAddress
#store coordinates in $a0
add $a0, $v0, $zero
#if the coordinates is a position change
#continue drawing tail in same direction
bne $t9, $a0, DrawTailRight
#get the base address of the direction change array
la $t3, newDirectionChangeArray
#move to correct index in array
add $t3, $t3, $t8
#get data from array
lw $t9, 0($t3)
#store new direction
sw $t9, tailDirection
#increment position in array
addiu $t8,$t8,4
#if the index is out of bounds, set back to zero
bne $t8, 396, StoreLocationRight
li $t8, 0
StoreLocationRight:
sw $t8, locationInArray
DrawTailRight:
lw $a1, snakeColor
jal DrawPixel
#erase behind the snake
lw $t0, snakeTailX
lw $t1, snakeTailY
addiu $t0, $t0, -1
add $a0, $t0, $zero
add $a1, $t1, $zero
jal CoordinateToAddress
add $a0, $v0, $zero
lw $a1, backgroundColor
jal DrawPixel
j  DrawFruit #finished updating snake, update fruit
######################################################
# Draw Fruit
######################################################
DrawFruit:
# Save head coordinates
lw $t8, snakeHeadX
lw $t9, snakeHeadY

# checks collision with fruits
move $a0, $t8 # Move HeadX position to $t8
move $a1, $t9 # Move HeadY position to $t9

# checks collision for orange fruit
lw $t0, fruitPositionX  # load orange fruit X
lw $t1, fruitPositionY  # load orange fruit Y
jal CheckFruitCollision # Check if snake head is on orange fruit
li $s5, 1
beq $v0, 1, AddLength # If collide, go to AddLength

# checks collision for green fruit
lw $t0, fruitBombX # Load light green fruit X
lw $t1, fruitBombY # Load light green fruit X
jal CheckFruitCollision # Check if snake head is on light green fruit
beq $v0, 1, DoExplosion # If collide, go to DoExplosion

# checks collision for purple fruit
lw $t0, fruitReverseX # Load pruple fruit X
lw $t1, fruitReverseY # Load pruple fruit Y
jal CheckFruitCollision # Check if snake head is on purple fruit
li $s5, 2
beq $v0, 1, DoReverse # If collide, go to DoReverse

# checks collision for cyan fruit
lw $t0, fruitSpeedX # Load cyan fruit X
lw $t1, fruitSpeedY # Load cyan fruit X
jal CheckFruitCollision # Check if snake head is on cyan fruit
li $s5, 3
beq $v0, 1, DoSpeed # If collide, go to DoSpeed

# checks collision for large fruit
lw $t0, fruitLargeX # load large fruit x
lw $t1, fruitLargeY # load large fruit y
jal CheckLargeFruitCollision # check if snake head is within large fruit bounds
li $s5, 4
beq $v0, 1, DoLarge # if collide, go to do large

# draw orange
lw $a0, fruitPositionX # Load orange X
lw $a1, fruitPositionY # Load orange Y
jal CoordinateToAddress # Convert the X and Y to coordinates
move $a0, $v0 # Move address to $a0
lw $a1, fruitColor # Load color for orange
jal DrawPixel # Draw orange pixel

# draw purple
lw $a0, fruitReverseX # Load purple X
lw $a1, fruitReverseY # Load purple Y
jal CoordinateToAddress # Convert the X and Y to coordinates
move $a0, $v0 # Move address to $a0
lw $a1, fruitColorReverse # Load color for purple
jal DrawPixel # Draw purple pixel

# draw cyan
lw $a0, fruitSpeedX # Load cyan X
lw $a1, fruitSpeedY # Load cyan Y
jal CoordinateToAddress # Convert the X and Y to coordinates
move $a0, $v0 # Move address to $a0
lw $a1, fruitColorSpeed # Load color for cyan
jal DrawPixel # Draw cyan pixel

# draw bomb
lw $a0, fruitBombX # Load light green X
lw $a1, fruitBombY # Load light green Y
jal CoordinateToAddress # Convert the X and Y to coordinates
move $a0, $v0 # Move address to $a0
lw $a1, fruitColorBomb # Load color for light green
jal DrawPixel # Draw light green pixel

# topleft pixel large fruit
lw $a0, fruitLargeX # load large x
lw $a1, fruitLargeY # load large y
addi $a0, $a0, -1
addi $a1, $a1, -1
jal CoordinateToAddress
move $a0, $v0
lw $a1, fruitColorLarge
jal DrawPixel

# topmid pixel large fruit
lw $a0, fruitLargeX # load large x
lw $a1, fruitLargeY # load large y
addi $a1, $a1, -1
jal CoordinateToAddress
move $a0, $v0
lw $a1, fruitColorLarge
jal DrawPixel

# topright pixel large fruit
lw $a0, fruitLargeX # load large x
lw $a1, fruitLargeY # load large y
addi $a0, $a0, 1
addi $a1, $a1, -1
jal CoordinateToAddress
move $a0, $v0
lw $a1, fruitColorLarge
jal DrawPixel

# midleft pixel large fruit
lw $a0, fruitLargeX # load large x
lw $a1, fruitLargeY # load large y
addi $a0, $a0, -1
jal CoordinateToAddress
move $a0, $v0
lw $a1, fruitColorLarge
jal DrawPixel

# midmid pixel large fruit
lw $a0, fruitLargeX # load large x
lw $a1, fruitLargeY # load large y
jal CoordinateToAddress
move $a0, $v0
lw $a1, fruitColorLarge
jal DrawPixel

# midright pixel large fruit
lw $a0, fruitLargeX # load large x
lw $a1, fruitLargeY # load large y
addi $a0, $a0, 1
jal CoordinateToAddress
move $a0, $v0
lw $a1, fruitColorLarge
jal DrawPixel

# btmleft pixel large fruit
lw $a0, fruitLargeX # load large x
lw $a1, fruitLargeY # load large y
addi $a0, $a0, -1
addi $a1, $a1, 1
jal CoordinateToAddress
move $a0, $v0
lw $a1, fruitColorLarge
jal DrawPixel

# btmmid pixel large fruit
lw $a0, fruitLargeX # load large x
lw $a1, fruitLargeY # load large y
addi $a1, $a1, 1
jal CoordinateToAddress
move $a0, $v0
lw $a1, fruitColorLarge
jal DrawPixel

# btmright pixel large fruit
lw $a0, fruitLargeX # load large x
lw $a1, fruitLargeY # load large y
addi $a0, $a0, 1    
addi $a1, $a1, 1
jal CoordinateToAddress
move $a0, $v0
lw $a1, fruitColorLarge
jal DrawPixel

# loop back into game
j InputCheck

AddLength:
li $s1, 1
# generates a random int in hex color range for the snake upon eating a fruit
rng_snake_color:
li $v0, 42             # syscall for random integer range
li $a1, 0xFFFFFF       # upper bound of hex colors (white)
syscall                # gen rand int in hex range
sw $a0, snakeColor     # save randomized color as current snake color

sw $s5, fruitLastEaten # store the value of $s5 to fruitLastEaten
jal SpawnFruit	       # call the SpawnFruit routine
j InputCheck           # jump to InputCheck

# Purple fruit logic for random direction
DoReverse:
# Try UP (119)
lw $t2, direction         # current direction
li $t3, 115               # down (invalid if we're going up)
beq $t2, 119, SkipUp      # skip if already going up
beq $t2, $t3, SkipUp      # skip if opposite of up
lw $a0, snakeHeadX 	  # Load snake head x
lw $a1, snakeHeadY	  # Load snake head y
addiu $a1, $a1, -1        # simulate moving up
jal CoordinateToAddress   # Convert coordinates to screen address
lw $t4, 0($v0)            # color at that location
lw $t5, snakeColor	  # Load snake color
lw $t6, borderColor	  # Load border color
beq $t4, $t5, SkipUp 	  # Skip if collision with snake
beq $t4, $t6, SkipUp	  # Skip if collision with border
li $t2, 119               # set new direction to up
j SetDirection            # jump to SetDirection

# Checks if going up
SkipUp:
# Try RIGHT (100)
li $t3, 97 		  # Opposite is left
beq $t2, 100, SkipRight	  # Skip if going right
beq $t2, $t3, SkipRight   # Skip if opposite
lw $a0, snakeHeadX	  # Load snake head x
lw $a1, snakeHeadY	  # Load snake head y
addiu $a0, $a0, 1         # Simulate right
jal CoordinateToAddress   # Convert coordinates to screen address
lw $t4, 0($v0)		  # Load pixel color
beq $t4, $t5, SkipRight   # Skip if collision with snake
beq $t4, $t6, SkipRight   # Skip if collision with border
li $t2, 100		  # Set right
j SetDirection            # jump to SetDirection

# Checks if going right
SkipRight:
# Try DOWN (115)	 
li $t3, 119		  # Opposite is up
beq $t2, 115, SkipDown	  # Skip if already down
beq $t2, $t3, SkipDown	  # Skip if opposite
lw $a0, snakeHeadX	  # Load snake head x
lw $a1, snakeHeadY	  # Load snake head y
addiu $a1, $a1, 1	  # Simulate down
jal CoordinateToAddress   # Convert coordinates to screen address
lw $t4, 0($v0)		  # Load pixel color
beq $t4, $t5, SkipDown	  # Skip if collision with snake
beq $t4, $t6, SkipDown    # Skip if collision with border
li $t2, 115		  # Set down
j SetDirection            # jump to SetDirection

# Checks if going down
SkipDown:
# Try LEFT (97)
li $t3, 100		 # Opposite is right
beq $t2, 97, AddLength  # Skip if already left
beq $t2, $t3, AddLength # Skip if opposite
lw $a0, snakeHeadX	 # Load snake head x
lw $a1, snakeHeadY	 # Load snake head y
addiu $a0, $a0, -1       # Simulate left
jal CoordinateToAddress  # Convert coordinates to screen address
lw $t4, 0($v0)		 # Load pixel color
beq $t4, $t5, AddLength # Skip if collision with snake
beq $t4, $t6, AddLength # Skip if collision with border
li $t2, 97		# Set left

# Sets the direction
SetDirection:
sw $t2, direction	# Store new direction
move $t7, $t2		# Update working regester

# Stores the direction
StoreNewDir:
    # Get head coordinates *before* direction changes
    lw $a0, snakeHeadX # Load snake head x
    lw $a1, snakeHeadY # Load snake head y
    jal CoordinateToAddress
    move $a2, $v0            # $a2 is current head address

    li $a0, 0                # Temporarily dummy current direction (not used)
    move $a1, $t2            # $a1 = new direction we want to force
    li $v0, 1                # Force acceptability
    # MANUALLY insert turn into arrays instead of calling CheckDirection
    lw $t4, arrayPosition # Load array index
    la $t2, directionChangeAddressArray # Load base address for position
    la $t3, newDirectionChangeArray # Load base address for new direction
    add $t2, $t2, $t4        # Index into array
    add $t3, $t3, $t4
    sw $a2, 0($t2)           # store coordinate
    sw $a1, 0($t3)           # store new direction
    addiu $t4, $t4, 4
    bne $t4, 396, SkipReset
    li $t4, 0

# Saves index    
SkipReset:
sw $t4, arrayPosition # Save updated array index
# Now apply the new direction
sw $a1, direction # Stores direction
move $t7, $a1 # Update register
j AddLength # If done go to AddLength

# Cyan fruit speed increase logic
DoSpeed:
lw $t3, gameSpeed       # Load current game speed
addiu $t3, $t3, -30     # Decrease by 30
slti $t4, $t3, 50       # Set $t4 to 1 if new speed is less than 50
beq $t4, 1, SetMinSpeed # If too fast, go to minimum
sw $t3, gameSpeed       # If not, store new speed
j AddLength             # jump to AddLength

# Sets Minimum length
SetMinSpeed:
li $t3, 50        # Set minimum allowed game speed
sw $t3, gameSpeed # Store it as the gameSpeed value
j AddLength       # jump to AddLength

# Large Fruit logic
DoLarge:
#update the score again; large fruit gives extra points
lw $t5, score
lw $t6, scoreGain
add $t5, $t5, $t6
add $t5, $t5, $t6
add $t5, $t5, $t6
sw $t5, score
# play sound again to let the player know they got more points
li $v0, 31
li $a0, 79
li $a1, 150
li $a2, 7
li $a3, 127
syscall
li $a0, 96
li $a1, 250
li $a2, 7
li $a3, 127
syscall
j AddLength

# Explosion animation logic. Plays whenever the snake dies (bomb or colliding with itself/border)
DoExplosion:
li $t0, 0xFFFFFF        # white color for explosion
lw $t9, backgroundColor # background color (so we can get rid of the explosion effect each frame)
lw $t1, snakeHeadX      # the x coordinate where the center of the explosion is happening
lw $t2, snakeHeadY      # the y coordinate where the center of the explosion is happening
li $t3, 1               # current iteration which we use as offsets for the explosion pixels
    
ExplosionLoop:
beq $t3, 4, Exit        # exit the loop if the current iteration is the fourth
li $t4, -1              # load -1 at $t4 
mul $t5, $t3, $t4       # multiply the current offset by -1 to get the negative current offset
        
# Drawing the Top Left Pixel
add $a0, $t1, $t5       # calculate the x value of the top left pixel
add $a1, $t2, $t3       # calculate the y value of the top left pixel
jal IsValidCoord        # check to see if the x and y values are valid coordinates
move $s4, $v0           # set the flag if the top left pixel is a valid coord by moving the result to $s4
beqz $v0, skipTopLeft   # skip drawing the top left pixel if its not a valid coordinate
jal CoordinateToAddress # convert the coordinate to its address
move $s0, $v0           # save the coordinate to $s0
move $a0, $v0           # move the address we want to draw to $a0
move $a1, $t0           # move the explosion color to $a1
jal DrawPixel           # draw the pixel

skipTopLeft:
# Drawing the Top Right Pixel
add $a0, $t1, $t3       # calculate the x value of the top right pixel
add $a1, $t2, $t3       # calculate the y value of the top right pixel
jal IsValidCoord        # check to see if the x and y values are valid coordinates
move $s5, $v0           # set the flag if the top right pixel is a valid coord by moving the result to $s5
beqz $v0, SkipTopRight  # skip drawing the top left pixel if its not a valid coordinate
jal CoordinateToAddress # convert the coordinate to its address
move $s1, $v0           # save the coordinate to $s1
move $a0, $v0           # move the address we want to draw to $a0
move $a1, $t0           # move the explosion color to $a1
jal DrawPixel           # draw the pixel

SkipTopRight:
# Drawing the Bottom Left Pixel
add $a0, $t1, $t5       # calculate the x value of the bottom left pixel
add $a1, $t2, $t5       # calculate the y value of the bottom left pixel
jal IsValidCoord        # check to see if the x and y values are valid coordinates
move $s6, $v0           # set the flag if the bottom left pixel is a valid coord by moving the result to $s6
beqz $v0, SkipBottomLeft # skip drawing the bottom left pixel if its not a valid coordinate
jal CoordinateToAddress # convert the coordinate to its address
move $s2, $v0           # save the coordinate to $s2
move $a0, $v0           # move the address we want to draw to $a0
move $a1, $t0           # move the explosion color to $a1
jal DrawPixel           # draw the pixel

SkipBottomLeft:
# Drawing the Bottom Right Pixel
add $a0, $t1, $t3       # calculate the x value of the bottom right pixel
add $a1, $t2, $t5       # calculate the y value of the bottom right pixel
jal IsValidCoord        # check to see if the x and y values are valid coordinates
move $s7, $v0           # set the flag if the bottom right pixel is a valid coord by moving the result to $s7
beqz $v0, SkipBottomRight  # skip drawing the bottom left pixel if its not a valid coordinate
jal CoordinateToAddress # convert the coordinate to its address
move $s3, $v0           # save the coordinate to $s3
move $a0, $v0           # move the address we want to draw to $a0
move $a1, $t0           # move the explosion color to $a1
jal DrawPixel           # draw the pixel

SkipBottomRight:
# Here we are pausing to show the explosion effect before erasing the effect 
li $a0, 500             # load in 500 at $a0
jal Pause               # call the Pause subroutine
move $a1, $t9           # load the background color at $t9
    
# Now we are getting rid of the explosion effect
beqz $s4, SkipEraseTopLeft   # skips erasing the top left if the flag says its an invalid coordinate 
move $a0, $s0                # move the top left coordinate to $a0
jal DrawPixel                # draw that pixel with the background color 

SkipEraseTopLeft:
beqz $s5, SkipEraseTopRight  # skips erasing the top right if the flag says its an invalid coordinate 
move $a0, $s1                # move the top left coordinate to $a0
jal DrawPixel                # draw that pixel with the background color 

SkipEraseTopRight:
beqz $s6, SkipEraseBottomLeft   # skips erasing the bottom left if the flag says its an invalid coordinate 
move $a0, $s2                   # move the top left coordinate to $a0
jal DrawPixel                   # draw that pixel with the background color 

SkipEraseBottomLeft:
beqz $s7, SkipEraseBottomRight   # skips erasing the bottom right if the flag says its an invalid coordinate 
move $a0, $s3                    # move the top left coordinate to $a0
jal DrawPixel                    # draw that pixel with the background color 
    
SkipEraseBottomRight:
addi $t3, $t3, 1       # increment the offset counter by 1
j ExplosionLoop        # repeat the loop

##################################################################
# IsValidCoord
# $a0 - x coordinate of the particle
# $a1 - y coordinate of the particle
##################################################################
# returns $v0:
# 0 - is not within the bounds of the borders
# 1 - is within the bounds of the borders
##################################################################
IsValidCoord:
blt $a0, 0, IsNotValidCoord   # branches to IsNotValidCoord if x coordinate is less than the left border
bgt $a0, 62, IsNotValidCoord  # branches to IsNotValidCoord if x coordinate is more than the right border
blt $a1, 0, IsNotValidCoord   # branches to IsNotValidCoord if y coordinate is less than the top border
bgt $a1, 62, IsNotValidCoord  # branches to IsNotValidCoord if y coordinate is more than the bottom border
li $v0, 1                     # load in 1 at $v0 to indicate that the coordinate is within bounds
jr $ra                        # jump back from where the subroutine is called

# this is a helper label to the one above
IsNotValidCoord:
li $v0, 0                    # load in 0 at $v0 to indicate that the coordinate is not within bounds
jr $ra      


##################################################################
#CoordinatesToAddress Function
# $a0 -> x coordinate
# $a1 -> y coordinate
##################################################################
# returns $v0 -> the address of the coordinates for bitmap display
##################################################################
CoordinateToAddress:
lw $v0, screenWidth #Store screen width into $v0
mul $v0, $v0, $a1 #multiply by y position
add $v0, $v0, $a0 #add the x position
mul $v0, $v0, 4 #multiply by 4
add $v0, $v0, $gp #add global pointerfrom bitmap display
jr $ra # return $v0
##################################################################
#Draw Function
# $a0 -> Address position to draw at
# $a1 -> Color the pixel should be drawn
##################################################################
# no return value
##################################################################
DrawPixel:
sw $a1, ($a0) #fill the coordinate with specified color
jr $ra #return
##################################################################
# Check Acceptable Direction
# $a0 - current direction
# $a1 - input
# $a2 - coordinates of direction change if acceptable
##################################################################
# return $v0 = 0 - direction unacceptable
# $v0 = 1 - direction is acceptable
##################################################################
CheckDirection:
beq $a0, $a1, Same #if the input is the same as current direction
#continue moving in the direction
beq $a0, 119, checkIsDownPressed #if moving up, check to see if down is pressed
beq $a0, 115, checkIsUpPressed #if moving down, check to see if up is pressed
beq $a0, 97, checkIsRightPressed #if moving left, check to see if right is pressed
beq $a0, 100, checkIsLeftPressed #if moving right, check to see if left is pressed
j DirectionCheckFinished # if input is incorrect, get new input
checkIsDownPressed:
beq $a1, 115, unacceptable #if down is pressed while moving up
#prevent snake from moving into itself
j acceptable
checkIsUpPressed:
beq $a1, 119, unacceptable #if up is pressed while moving down
#prevent snake from moving into itself
j acceptable
checkIsRightPressed:
beq $a1, 100, unacceptable #if right is pressed while moving left
#prevent snake from moving into itself
j acceptable
checkIsLeftPressed:
beq $a1, 97, unacceptable #if left is pressed while moving right
#prevent snake from moving into itself
j acceptable
acceptable:
li $v0, 1
beq $a1, 119, storeUpDirection #store the location of up direction change
beq $a1, 115, storeDownDirection #store the location of down direction change
beq $a1, 97, storeLeftDirection #store the location of left direction change
beq $a1, 100, storeRightDirection #store the location of right direction change
j DirectionCheckFinished
storeUpDirection:
lw $t4, arrayPosition #get the array index
la $t2, directionChangeAddressArray #get the address for the coordinate for direction change
la $t3, newDirectionChangeArray #get address for new direction
add $t2, $t2, $t4 #add the index to the base
add $t3, $t3, $t4
sw $a2, 0($t2) #store the coordinates in that index
li $t5, 119
sw $t5, 0($t3) #store the direction in that index
addiu $t4, $t4, 4 #increment the array index
#if the array will go out of bounds, start it back at 0
bne $t4, 396, UpStop
li $t4, 0
UpStop:
sw $t4, arrayPosition
j DirectionCheckFinished
storeDownDirection:
lw $t4, arrayPosition #get the array index
la $t2, directionChangeAddressArray #get the address for the coordinate for direction change
la $t3, newDirectionChangeArray #get address for new direction
add $t2, $t2, $t4 #add the index to the base
add $t3, $t3, $t4
sw $a2, 0($t2) #store the coordinates in that index
li $t5, 115
sw $t5, 0($t3) #store the direction in that index
addiu $t4, $t4, 4 #increment the array index
#if the array will go out of bounds, start it back at 0
bne $t4, 396, DownStop
li $t4, 0
DownStop:
sw $t4, arrayPosition
j DirectionCheckFinished
storeLeftDirection:
lw $t4, arrayPosition #get the array index
la $t2, directionChangeAddressArray #get the address for the coordinate for direction change
la $t3, newDirectionChangeArray #get address for new direction
add $t2, $t2, $t4 #add the index to the base
add $t3, $t3, $t4
sw $a2, 0($t2) #store the coordinates in that index
li $t5, 97
sw $t5, 0($t3) #store the direction in that index
addiu $t4, $t4, 4 #increment the array index
#if the array will go out of bounds, start it back at 0
bne $t4, 396, LeftStop
li $t4, 0
LeftStop:
sw $t4, arrayPosition
j DirectionCheckFinished
storeRightDirection:
lw $t4, arrayPosition #get the array index
la $t2, directionChangeAddressArray #get the address for the coordinate for direction change
la $t3, newDirectionChangeArray #get address for new direction
add $t2, $t2, $t4 #add the index to the base
add $t3, $t3, $t4
sw $a2, 0($t2) #store the coordinates in that index
li $t5, 100
sw $t5, 0($t3) #store the direction in that index
addiu $t4, $t4, 4 #increment the array index
#if the array will go out of bounds, start it back at 0
bne $t4, 396, RightStop
li $t4, 0
RightStop:
#store array position
sw $t4, arrayPosition
j DirectionCheckFinished
unacceptable:
li $v0, 0 #direction is not acceptable
j DirectionCheckFinished
Same:
li $v0, 1
DirectionCheckFinished:
jr $ra
##################################################################
# Pause Function
# $a0 - amount to pause
##################################################################
# no return values
##################################################################
Pause:
li $v0, 32 #syscall value for sleep
syscall
jr $ra
##################################################################
# Check Fruit Collision
# $a0 - snakeHeadPositionX
# $a1 - snakeHeadPositionY
##################################################################
# returns $v0:
# 0 - does not hit fruit
# 1 - does hit fruit
##################################################################
CheckLargeFruitCollision:
add $v0, $zero, $zero # default to no collision

# check to see if x is greater than position-1
addi $t0, $t0, -1
blt, $a0, $t0, CollisionFailureType1

# check to see if x is less than position+1
addi $t0, $t0, 2
bgt, $a0, $t0, CollisionFailureType2

# x is within the bounds of the large fruit. reset $t0 back to where it should be then check y
addi $t0, $t0, -1

# check to see if y is greater than position-1
addi $t1, $t1, -1
blt, $a1, $t1, CollisionFailureType3

# check to see if y is less than position+1
addi $t1, $t1, 2
bgt, $a1, $t1, CollisionFailureType4

# we now know there was a collision. reset $t1 back to where it should be then continue
addi $t1, $t1, -1
j YEqualFruit

CollisionFailureType1: # x is less than bounds, undo math done on $t0
addi $t0, $t0, 2 # set to x+1, next instruction will reset back to x+0
CollisionFailureType2: # x is greater than bounds, undo math done to $t0
addi $t0, $t0, -1 # reset $t0 back to x+0
j ExitCollisionCheck # since collision failed, exit

CollisionFailureType3: # y is less than bounds, undo math done on $t1
addi $t1, $t1, 2 # set to y+1, next instruction will reset back to y+0
CollisionFailureType4: # y is greater than bounds, undo math done to $t1
addi $t1, $t1, -1 # reset $t1 back to y+0
j ExitCollisionCheck # since collision failed, exit

CheckFruitCollision:
#set $v0 to zero, to default to no collision
add $v0, $zero, $zero
#check first to see if x is equal
beq $a0, $t0, XEqualFruit
#if not equal end function
j ExitCollisionCheck

XEqualFruit:
#check to see if the y is equal
beq $a1, $t1, YEqualFruit
#if not eqaul end function
j ExitCollisionCheck

YEqualFruit:
#update the score as fruit has been eaten
lw $t5, score
lw $t6, scoreGain
add $t5, $t5, $t6
sw $t5, score
# play sound to signify score update
li $v0, 31
li $a0, 79
li $a1, 150
li $a2, 7
li $a3, 127
syscall
li $a0, 96
li $a1, 250
li $a2, 7
li $a3, 127
syscall
li $v0, 1 #set return value to 1 for collision
ExitCollisionCheck:
jr $ra
##################################################################
# Check Snake Body Collision
# $a0 - snakeHeadPositionX
# $a1 - snakeHeadPositionY
# $a2 - snakeHeadDirection
##################################################################
# returns $v0:
# 0 - does not hit body
# 1 - does hit body
##################################################################
CheckGameEndingCollision:
#save head coordinates
add $s3, $a0, $zero
add $s4, $a1, $zero
#save return address
sw $ra, 0($sp)
beq $a2, 119, CheckUp
beq $a2, 115, CheckDown
beq $a2, 97, CheckLeft
beq $a2, 100, CheckRight
j BodyCollisionDone #for error?
CheckUp:
#look above the current position
addiu $a1, $a1, -1
jal CoordinateToAddress
#get color at screen address
lw $t1, 0($v0)
#add $s6, $t1, $zero
lw $t2, snakeColor
lw $t3, borderColor
beq $t1, $t2, DoExplosion #If colors are equal - YOU LOST!
beq $t1, $t3, DoExplosion #If you hit the border - YOU LOST!
j BodyCollisionDone # if not, leave function
CheckDown:
#look below the current position
addiu $a1, $a1, 1
jal CoordinateToAddress
#get color at screen address
lw $t1, 0($v0)
#add $s6, $t1, $zero
lw $t2, snakeColor
lw $t3, borderColor
beq $t1, $t2, DoExplosion #If colors are equal - YOU LOST!
beq $t1, $t3, DoExplosion #If you hit the border - YOU LOST!
j BodyCollisionDone # if not, leave function
CheckLeft:
#look to the left of the current position
addiu $a0, $a0, -1
jal CoordinateToAddress
#get color at screen address
lw $t1, 0($v0)
#add $s6, $t1, $zero
lw $t2, snakeColor
lw $t3, borderColor
beq $t1, $t2, DoExplosion #If colors are equal - YOU LOST!
beq $t1, $t3, DoExplosion #If you hit the border - YOU LOST!
j BodyCollisionDone # if not, leave function
CheckRight:
#look to the right of the current position
addiu $a0, $a0, 1
jal CoordinateToAddress
#get color at screen address
lw $t1, 0($v0)
#add $s6, $t1, $zero
lw $t2, snakeColor
lw $t3, borderColor
beq $t1, $t2, DoExplosion #If colors are equal - YOU LOST!
beq $t1, $t3, DoExplosion #If you hit the border - YOU LOST!
j BodyCollisionDone # if not, leave function
BodyCollisionDone:
lw $ra, 0($sp) #restore return address
jr $ra
##################################################################
# Increase Difficulty Function
# no parameters
##################################################################
# no return values
##################################################################
IncreaseDifficulty:
lw $t0, score #get the player's score
la $t1, scoreMilestones #get the milestones base address
lw $t2, scoreArrayPosition #get the array position
add $t1, $t1, $t2 #move to position in array
lw $t3, 0($t1) #get the value at the array index
#if the player score is not equal to the current milestone
#DoExplosion the function, if they are equal increase difficulty
bne $t3, $t0, FinishedDiff
#increase the index for the milestones array
addiu $t2, $t2, 4
#store new position
sw $t2, scoreArrayPosition
#load the scoreGain variable to increase the
#points awarded for eating fruit
lw $t0, scoreGain
#multiply gain by 2
sll $t0, $t0, 1
#load the game speed
lw $t1, gameSpeed
#subtract 25 from the move speed
addiu $t1, $t1, -25
#store new speed
sw $t1, gameSpeed
FinishedDiff:
jr $ra
Exit:
#play a sound tune to signify game over
li $v0, 31
li $a0, 28
li $a1, 250
li $a2, 32
li $a3, 127
syscall
li $a0, 33
li $a1, 250
li $a2, 32
li $a3, 127
syscall
li $a0, 47
li $a1, 1000
li $a2, 32
li $a3, 127
syscall
li $v0, 56 #syscall value for dialog
la $a0, lostMessage #get message
lw $a1, score #get score
syscall
li $v0, 50 #syscall for yes/no dialog
la $a0, replayMessage #get message
syscall
beqz $a0, main#jump back to start of program
#end program
li $v0, 10
syscall