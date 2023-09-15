# Assignment 6 of CS2340.005 by Wei Yuan Liew, 4/18/2023
# NetID: wxl220016
# Given a file, find the list of words in the file and its count

	.include	"SysCalls.asm"
	.data
	.eqv		BSIZE		512
	.eqv		FILE_READ	0
	.eqv		CASE_CONST	32		# difference between uppercase & lowercase in ASCII
	.eqv		WORD_NODE_CONST	16
	.eqv		LINE_NODE_CONST	8
	
fileBuffer:	
	.space		BSIZE
fileName:	
	.space		BSIZE
wordBuffer:
	.space		BSIZE
wordList:
	.word		0
prompt:	.asciiz		"Enter a file name: "
error:	.asciiz		"There was an error opening the file. Please try again. \n"
resultWord:	
	.asciiz		"Word: "
resultCount:
	.asciiz		"Count: "
resultLines:
	.asciiz		"Lines: "
newline:
	.asciiz		"\n"
space:
	.asciiz		"   "
	
	.text
# Start of code
main:
	# Prompts the user for a file to be read
	la		$a0, prompt
	li		$v0, SysPrintString
	syscall
	
	# Get the file name.
	la		$a0, fileName
	li		$a1, BSIZE
	li		$v0, SysReadString
	syscall

	# Remove the newline char from file name to facilitate file opening
	la		$t0, fileName

# Loops through the file name to check for newline
checkNewline:
	lb		$t1, 0($t0)
	beq		$t1, '\n', truncateNewline
	addi		$t0, $t0, 1
	j		checkNewline
	
# Replace the newline with null
truncateNewline:
	sb		$zero, ($t0)
	
	# Now open the file and check if file is opened successfully
	la		$a0, fileName
	li		$a1, FILE_READ
	li		$a2, 0
	li		$v0, SysOpenFile
	syscall
	
	# If file cannot be opened, print out error message
	bltz		$v0, printError
	
	# Else, start reading file into file buffer 
	# ($s0 contains file desc., $s1 contains line num., $s2 as word buffer, $t7 as word length count)
	move		$s0, $v0
	addi		$s1, $zero, 1			# line num. starts at 1
	la		$s2, wordBuffer			
	add		$t7, $zero, $zero

readFile:
	move		$a0, $s0
	la		$a1, fileBuffer
	li		$a2, BSIZE
	li		$v0, SysReadFile
	syscall
	
	# Print results when end of file is reached
	beqz		$v0, printResult
	
	# Else, keep track of bytes read and start iterating through the buffer 
	# ($t0 as byte count, $t1 as byte iterated, $t2 as temp pointer to buffer)
	move		$t0, $v0
	add		$t1, $zero, $zero
	la		$t2, fileBuffer			
	
readBuffer:
	addi		$t1, $t1, 1			# increment byte read
	bgt		$t1, $t0 , readFile		# if end of buffer is reached, read more from file
	lb		$t3, 0($t2)			# load a char into existence
	addi		$t2, $t2, 1			# move to next char
	
	# Determine what to do with the char
	beq		$t3, '\n', nextLine		# if given char is newline, go to next line
	blt		$t3, '0', storeWord		# else, check if the given char is alphanumeric or not
	bgt		$t3, '9', isUpper
	
# Check if char is uppercase	
isUpper:
	blt		$t3, 'A', storeWord		# not uppercase if ASCII value <'A'
	bgt		$t3, 'Z', isLower		# could be lowercase if ASCII value > 'Z'
	jal		swapLower			# swap uppercase into lowercase
	j		storeChar			# store lowercase into word buffer

# Check if char is lowercase	
isLower:
	blt		$t3, 'a', storeWord		# not lowercase if ASCII value <'a'
	bgt		$t3, 'z', storeWord		# not lowercase if ASCII value > 'z'
	j		storeChar			# store lowercase into word buffer
	
nextLine:
	addi		$s1, $s1, 1			# increment line count
	j 		readBuffer
	
# Puts given char into word buffer
storeChar:
	addi		$t7, $t7, 1			# increment word length by 1
	sb		$t3, 0($s2)			# store char into word buffer
	addi		$s2, $s2, 1			# move onto the next spot of word buffer
	add		$t3, $zero, $zero
	j		readBuffer			# return to readBuffer for the next char
	
# Convert uppercase to lowercase
swapLower:
	addi		$t3, $t3, CASE_CONST		# convert uppercase ASCII value to lowercase value
	jr		$ra
	
# Store preexisting word in word buffer and move onto next char if its nonalphanumeric, with the exception of '-'
storeWord:
	beq		$t3, '-', storeChar		# continue storing char if its '-'
	
	beqz		$t7, readBuffer			# if word length is empty, continue reading from buffer
	
	lw 		$s4, wordList			# $s4 as temp pointer to word list
	la		$s5, wordBuffer			# $s5 as temp pointer to word buffer
	
	beqz		$s4, addWord			# if no node is created yet, skip findWord process and create a node
	
findWord:
	# First retrive the pointer to the next node, store a pointer to start of node for future node traversals
	lw		$t4, 0($s4)			# $t4 has the next pointer of current word node
	move		$t9, $s4			# $t9 for future use
	
	# Move to the word section of node
	addi		$s4, $s4, WORD_NODE_CONST	
	add		$t8, $zero, $zero		# $t8 to keep track of loaded word length
	
	# Check if current word node has the correct word
checkWord:
	lb		$t5, 0($s4)			# Load first char of wordNode
	lb		$t6, 0($s5)			# Load first char of wordBuffer
	bne		$t5, $t6, nextWord		# If they are not the same, go to the next word stored
	addi		$s4, $s4, 1			# Else, load in next char
	addi		$s5, $s5, 1
	addi		$t8, $t8, 1			# increment loaded word length
	beq		$t7, $t8, addCount		# if word found, increase word count
	
nextWord:
	beq		$t4, $zero, addWord		# if end of list is reached, add word into list	
	move		$s4, $t4			# set current node pointer to next node
	j		findWord
	
addWord:
	li		$v0, SysAlloc
	move		$a0, $t7			# allocate word length + WORD_NODE_CONST byte of memory
	addi		$a0, $a0, WORD_NODE_CONST
	syscall
	
	move		$s7, $v0			# $s7 now has the addr. to allocated memory
	
	addi		$t8, $zero, 1			# initialize word's count to be 1
	sw		$t8, 4($s7)
	
	li		$v0, SysAlloc			# make a node for the lines where the word is found
	addi		$a0, $zero, LINE_NODE_CONST
	syscall
	
	sw		$s1, 4($v0)			# store the line num. into created node
	sw		$v0, 8($s7)			# store addr. of created node into word node
	
	sw		$t7, 12($s7)			# store length of word
	
	add		$t8, $zero, $zero		# start storing the given word into the node, $t8 as word length counter
	addi		$t9, $s7, WORD_NODE_CONST	
	la		$s5, wordBuffer			# $s5 as temp pointer to word buffer
	
storeCharNode:
	lb		$s6, 0($s5)
	sb		$s6, 0($t9)			# store a char into the node
	addi		$t9, $t9, 1			# moves to next byte in node
	addi		$s5, $s5, 1			# moves to next char of word
	addi		$t8, $t8, 1			# increment word length
	bne		$t8, $t7, storeCharNode		# while length is not reached, keep going
	
	# Check if a node exists yet, if not, create the list
	lw		$s3, wordList
	beqz		$s3, createList
	
	# If it does exist, loop to the end of list, create node and add onto the list
findNode:
	lw		$t4, 0($s3)			# load pointer of next node
	beqz		$t4, addNode			# if it points to null, add on the node
	move		$s3, $t4			# move to the next node
	j		findNode			# repeat process
	
addNode:
	sw		$s7, 0($s3)			# store pointer of created node
	j		resetWordBuffer			# reset word buffer then read more from file buffer

createList:
	sw		$s7, wordList			# store address of first node into wordList
	j		resetWordBuffer			# reset word buffer then read more from file buffer
	
addCount:
	lw		$t8, 4($t9)			# load the current count num. of the word
	addi		$t8, $t8, 1			# increment it by 1
	sw		$t8, 4($t9)			# store it back into the node
	lw		$t8, 8($t9)			# fetch the list for the line num.
	
findLine:
	lw		$t4, 0($t8)			# load next pointer of lineNode
	
	lw		$t9, 4($t8)			# load the line num
	beq		$s1, $t9, resetWordBuffer	# if line num. already exists, dont store it
	
	# Check if there's a next node, if no, add on the new line num.
	beqz		$t4, addLine
	
	# Otherwise, move onto next node for checking
	move		$t8, $t4
	j		findLine
	
addLine:
	li		$v0, SysAlloc			# make a node for the lines where the word is found
	addi		$a0, $zero, LINE_NODE_CONST
	syscall
	
	sw		$s1, 4($v0)			# store the line num. into created node
	sw		$v0, 0($t8)			# store addr. of created node into line node
	
	j		resetWordBuffer			
	
# Resets the word buffer before it reads more from the file buffer
resetWordBuffer:
	la		$s2, wordBuffer			# $s2 as temp pointer to wordBuffer
	li		$t9, 0				# $t9 as a counter towards wordBuffer
	
# Sets each byte in wordBuffer to 0 as long as the length of word stored has not been reached
clearBuffer:
	sb		$zero, 0($s2)
	addi		$t9, $t9 ,1
	bne		$t9, $t7, clearBuffer
	
	la		$s2, wordBuffer			# reset $s2 to the start of word buffer
	add		$t7, $zero, $zero		# reset word length count to 0 again
	j		readBuffer			# read more from buffer

# Prints out the word counts after going through the file
printResult:
	# Close the file before printing anything
	move		$a0, $s0
	li		$v0, SysCloseFile
	syscall
	
	lw		$s0, wordList

# Start iterating through the wordList and print out its corresponding fields
printList:
	lw		$t0, 0($s0)
	lw		$t1, 4($s0)
	lw		$t2, 8($s0)
	lw		$t3, 12($s0)
	addi		$s0, $s0, WORD_NODE_CONST
	
	# Prints out the word
	la		$a0, resultWord
	li		$v0, SysPrintString
	syscall

	add		$t4, $zero, $zero
printWord:
	lb 		$a0, 0($s0)
	li		$v0, SysPrintChar
	syscall
	
	addi		$t4, $t4, 1
	bne		$t4, $t3, printWord
			
	la		$a0, newline
	li		$v0, SysPrintString
	syscall
	
	# Prints out the word count
	la		$a0, resultCount
	li		$v0, SysPrintString
	syscall
	
	move		$a0, $t1
	li		$v0, SysPrintInt
	syscall
			
	la		$a0, newline
	li		$v0, SysPrintString
	syscall
	
	# Prints out the line numbers
	la		$a0, resultLines
	li		$v0, SysPrintString
	syscall
	
printLine:
	lw		$t4, 0($t2)	# loads in the next node's pointer
	lw		$t5, 4($t2)	# loads in the first line num.
	
	move		$a0, $t5
	li		$v0, SysPrintInt
	syscall
			
	la		$a0, space
	li		$v0, SysPrintString
	syscall
	
	move		$t2, $t4		# if next node's pointer isn't null, keep printing
	bnez		$t2, printLine
	
	la		$a0, newline
	li		$v0, SysPrintString
	syscall
	
	la		$a0, newline
	li		$v0, SysPrintString
	syscall
	
	beqz		$t0, exitProgram
	move		$s0, $t0
	j		printList
	
# Exit the program
exitProgram:
	li		$v0, SysExit
	syscall
	
# Tells user error occured during file opening and have them try again
printError:
	la		$a0, error
	li		$v0, SysPrintString
	syscall
	
	j		main
