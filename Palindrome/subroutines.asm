# This file contains any subroutines that is needed by palindrome.asm
	.data
	.include	"SysCalls.asm"
	.eqv		MAX_LENGTH	200		# max length of string
	.eqv		CASE_CONST	32		# difference between uppercase & lowercase in ASCII
	.eqv		SPACE_ALLOC	-204		# space allocation in stack accounting for MAXLENGTH & $ra size
	.eqv		SPACE_DEALLOC	204
	.eqv		addr_alloc	-4		# used for address allocation during pass by reference
	.eqv		addr_dealloc	4
	.globl		stripConvert
	.globl		verify

	.text
	
# Strips any char that is not alphanumeric in string and convert lowercase into uppercase when detected
stripConvert:
	addi		$sp, $sp, addr_alloc		# allocate space in stack for return address
	sw		$ra, ($sp)			# store return address
	la		$t0, ($a0)			# $t0 is a pointer to input string
	li		$s7, 0				# counter for duplicate string length
	
	li		$v0, SysAlloc			# allocate space for duplicate string
	li		$a0, MAX_LENGTH	
	syscall
	
	la		$s0, ($v0)			# $s0 will be pointer to start of duplicate string

# Start stripping the string	
strip:
	lb 		$t1, ($t0)			# get first char of input string
	beq		$t1, '\n', exitStripConvert	# if newline is reached, end of string is reached
	blt		$t1, '0', notAlnum 		# not alnum if ASCII value < '0'
	bgt		$t1, '9', isUpper  		# could be uppercase if ASCII value > '9'
	j		storeAlnum			# store num into duplicate string

# Check if char is uppercase	
isUpper:
	blt		$t1, 'A', notAlnum		# not uppercase if ASCII value <'A'
	bgt		$t1, 'Z', isLower		# could be lowercase if ASCII value > 'Z'
	j		storeAlnum			# store uppercase into duplicate string

# Check if char is lowercase	
isLower:
	blt		$t1, 'a', notAlnum		# not lowercase if ASCII value <'a'
	bgt		$t1, 'z', notAlnum		# not lowercase if ASCII value > 'z'
	jal		swapUpper			# swap lowercase into uppercase
	j		storeAlnum			# store uppercase into duplicate string

# Store char if it is alphanumeric	
storeAlnum:
	addi		$s7, $s7, 1			# increment duplicate string length by 1
	sb		$t1, ($v0)			# store alnum into duplicate string
	addi		$t0, $t0, 1			# go to next char of string
	addi		$v0, $v0, 1			# go to next byte in duplicate string
	j		strip				# repeat strip process

# Move onto next char if it is nonalphanumeric	
notAlnum:
	addi		$t0, $t0, 1			# go to next char of string
	j		strip				# repeat strip process

# Convert lowercase to uppercase
swapUpper:
	subi		$t1, $t1, CASE_CONST		# convert lowercase ASCII value to uppercase value
	jr		$ra

# Exit stripConvert when end of string is reached	
exitStripConvert:
	move		$v1, $s7			# return modified string length
	la		$v0,($s0)			# return modified string
	lw 		$ra,($sp)			# get return address from stack
	addi		$sp, $sp, addr_dealloc		# deallocate stack
	jr		$ra				# return to main

# Check if given modified string is a palindrome
verify:
	addi		$sp, $sp, SPACE_ALLOC		# Allocate stack space for modified string
	sw		$ra, 0($sp)			# Save return address
	la		$fp, 4($sp)			# Starting point to store modified string
	
	beqz		$a1, isPalindrome		# If string length reaches 0 or 1, given string is a palindrome
	beq		$a1, 1, isPalindrome
	
	lb		$s0, ($a0)			# Load first char of string
	add		$t0, $a0, $a1			# Set $t0 to end of string
	subi		$t0, $t0, 1
	lb		$s1, ($t0)			# Load last char of string
	
	beq		$s0, $s1, nextString		# If they have the same ASCII value, check next set of first and last char
	
	j		notPalindrome			# If first and last char do not match, return 0 for false
	
nextString:
	addi		$a0, $a0, 1			# Start copying from next char of string
	subi		$a1, $a1, 2			# Excluding first and last char, length of new string is now n-2
	beqz		$a1, isPalindrome		# If length of new string is 0, it means that it is a palindrome
	add		$t7, $zero, $zero		# $t7 is counter for writing new string into frame
	jal		stackframe			# Write new string into frame
	addi		$a0, $sp, 4			# Now $a0 refers to the first char of new string stored in frame
	jal		verify				# Now we go back and verify if the new string is a palindrome or not
	j		exitVerify			# Recursively exit palindrome verification
	
stackframe:
	addi		$t7, $t7, 1			# Increment whenever a character is written into frame
	lb		$t9,($a0)			# Load first char of new string
	sb		$t9,($fp)			# Store	first char of new string into frame
	addi		$a0, $a0, 1			# Move onto next char of new string
	addi		$fp, $fp, 1			# Move frame pointer to next memory address
	blt		$t7, $a1, stackframe		# If char stored is less than length of new string, keep going
	jr		$ra				# Return to nextString

exitVerify:
	lw		$ra, 0($sp)			# load return addresss
	addi		$sp, $sp, SPACE_DEALLOC		# deallocate stack
	la		$fp, ($sp)			# return frame pointer to same spot as stack pointer
	jr		$ra				# return to main

# Return 1 to $v0 if it is a palindrome
isPalindrome:
	li $v0,1
        j exitVerify
	
# Return 0 to $v0 if it is not a palindrome
notPalindrome:
	li $v0, 0
	j exitVerify
	
	

	
