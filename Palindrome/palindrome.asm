# Assignment 4 of CS2340.005 by Wei Yuan Liew, 3/18/2023
# NetID: wxl220016
# Given a string, this program checks if it is a palindrome or not.

	.include	"SysCalls.asm"
	.data
	
# Constants
	.eqv		MAX_LENGTH	200
buffer:	.space		MAX_LENGTH
	
# Screen displays
prompt: .asciiz		"Enter a string: "
valid:	.asciiz		"Said string is a palindrome. \n"
invalid:
	.asciiz		"Said string is not a palindrome. \n"

# Start of code
	.text
	
main:
	# Asks user for a string
	la		$a0, prompt			
	li		$v0, SysPrintString
	syscall
	
	# Reads input from user
	li		$v0, SysReadString	
	la		$a0, buffer
	li		$a1, MAX_LENGTH		
	syscall
	
	# If first character is '\n', exit program
	lb		$t0, ($a0)
	beq		$t0, '\n', exit
	
# Else, check if given string is a palindrome
# Start by stripping of non-alphanumerics and convert 
# everything to upper case.
palindrome:
	jal		stripConvert		# strip nonalphanumerics and convert to uppercase
	la		$a0, ($v0)		# $a0 now has address of modified string
	move		$a1, $v1		# $a1 now has length of modified string
	jal		verify			# check if string in $a0 is palindrome or not
	beqz		$v0, notPalindrome	# if $v0 is 0, it is not a palindrome
	b		isPalindrome		# if $v0 is 1, it is a palindrome
	
# If given string is palindrome, print result and return for more input.
isPalindrome:
	la		$a0, valid
	li		$v0, SysPrintString
	syscall
	
	j 		main

# If given string is not palindrome, print result and return for more input.
notPalindrome:
	la		$a0, invalid
	li		$v0, SysPrintString
	syscall
	
	j		main

# Exit the program	
exit:
	li		$v0, SysExit
	syscall
	
