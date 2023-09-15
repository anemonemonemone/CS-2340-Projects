# Assignment 3 of CS2340.005 by Wei Yuan Liew, 2/28/2023
# NetID: wxl220016
# Given an integer n, this program finds all the primes within that range

	.include	"SysCalls.asm"
	.data
	
# Screen displays
prompt:	.asciiz		"Enter an integer (3 <= n <= 160 000): "
error:	.asciiz		"Error, invalid input. Please try again. \n"
primes:	.asciiz		"The primes found up to n are: \n"
nl:	.asciiz		"\n"

# Start of code
	.text
main:	
	# Asks user for int in between 3 and 160 000
	la		$a0, prompt			
	li		$v0, SysPrintString
	syscall
	
	# Reads input from user
	li		$v0, SysReadInt			
	syscall
	
	# Check if user input is in between 3 and 160 000, if not print error message, else keep track of range & allocate memory
	blt		$v0, 3, printError		# if less than 3, print error
	bgt		$v0, 160000,printError		# if more than 160 000, print error
	move		$t0, $v0			# $t0 keeps track of the range
	j		memoryAlloc			# allocate emmory for valid input
	
# Tells user that input is not within range and loops back to input again.
printError:
	la		$a0, error			# prints error message
	li		$v0, SysPrintString
	syscall
	
	j  		main				# loops back and asks user for input again 

# Allocate desired bytes of memory for range specified 
memoryAlloc:
	# Calculate number of bytes needed, 
	# $t1 will be used to keep track the number of bytes allocated
	addi		$t1, $t0, 7			# round up the given integer to the next multiple of 8
	andi		$t1, $t1, -8			# set the last 3 bits to be 0 to round down to said multiple
	srl		$t1, $t1, 3			# divide the given integer by 8
	
	# Allocate the number of bytes
	li		$v0, SysAlloc
	move		$a0, $t1			# $t1 contains the number of bytes needed to be allocated
	syscall
	la 		$s0, ($v0)			# $s0 will be the register with address to allocated memory
	
	li		$t2, 0xff			# is used to set every bit in a byte to 1
	li		$t3, 0				# counter for how many bytes have been initialized
	la		$t4, ($s0)			# $t4 as a temp pointer towards allocated memory

# Initialize allocated memory with 1 at every single bit
initializeMemory:
	sb		$t2, ($t4)			# set 1st byte to 0xFF
	addi		$t3, $t3, 1			# move onto next byte of memory
	addi		$t4, $t4, 1
	blt		$t3, $t1, initializeMemory	# if next byte is still range, continue initialization

	li		$t5, 2				# counter for which prime factor to go through, starting from 2
	sll		$t6, $t5, 1			# multiply prime by 2 since we want to start at the 2nd multiple
	srl		$s1, $t0, 1			# indicator for when the algorithm stops running, which is when prime num hits n/2

# Start sieving through allocated bits for primes
sieve:
	blt		$t6, $t0, clearBit		# if prime multiple is within the range, clear the bit in its position
	j		nextPrime			# if prime multiple is outside of range, move to next prime

# flip bit if bit position is a not a prime	
clearBit:
	srl 		$t7, $t6, 3			# divide prime multiple by 8, determines which byte to load in
	andi		$t8, $t6, 7			# remainder of prime multiple from dividing 8, determines bit placement in byte
	
	li		$t9, 1				# bit mask
	sllv		$t9, $t9, $t8			# shifts bit to desired position to mask off
	
	la		$t4, ($s0)			# temp pointer to traverse through memory
	add		$t4, $t4, $t7			# move to desired byte of memory
	lb		$s3, ($t4)			# load memory
	and		$s4, $s3, $t9			# to prevent turning on already off bits, we create a new mask using AND
	
	xor		$s3, $s3, $s4			# masks off the desired bit
	sb		$s3, ($t4)			# store result into memory
	addu		$t6, $t6, $t5			# increment to the next prime multiple
	j		sieve				# repeat the process until prime multiple is out of range

# move onto to the next prime in list to find its multiples	
nextPrime:
	addi		$t5, $t5, 1			# increment prime counter, does not matter if it is not a prime
	sll		$t6, $t5, 1			# multiply prime by 2 since we want to start at the 2nd multiple
	blt		$t5, $s1, sieve			# if limit has not reached, keep sieving until limit is reached

	lb		$s3, ($s0)			# turn off bits 0 and 1 since 0 and 1 are not primes
	xor		$s3, $s3, 3			# 3 has a binary value of 0011 and is used to turn off said bits
	
	sb		$s3, ($s0)			# store value back into memory for ease of reading
	
	li		$t2, 0				# tracker for prime number
	li		$t3, 0				# counter for bit position within a byte itself
	la		$t4, ($s0)			# temp pointer to memory
	
	la		$a0, primes			# print out result prompt
	li		$v0,SysPrintString
	syscall
	
	lb		$s1, ($t4)			# load a byte of memory

# start looping through allocated memory to print out the prime bit positions	
result:
	andi		$s2, $s1, 1			# check if bit 0 is 1 or not, and $s2 is used as an indicator
	bne		$s2, 1,	nextBit			# if 1 does not exist at the bit position, move onto the next bit
	
	move		$a0, $t2			# print out the index where 1 is present
	li		$v0, SysPrintInt
	syscall
	
	la		$a0, nl				# print newline character
	li		$v0, SysPrintString
	syscall

# determine if next bit position is a prime or not
nextBit:	
	srl		$s1, $s1, 1			# shift next bit into position 0
	addi		$t2, $t2, 1			# increment the tracker
	addi		$t3, $t3, 1			# increment the bit position
	bge		$t3, 8, nextByte		# if bit position reached a byte, move onto next byte of menory		
	blt		$t2, $t0, result		# if tracker value is still smaller than given range n, keep on going
	j		exit

# move onto next byte of memory if all bits in a byte have been iterated	
nextByte:
	addi		$t4, $t4, 1			# move address to next byte
	lb		$s1, ($t4)			# load next byte of memory
	li		$t3, 0				# reset bit position to 0
	j result					# start over to check for 1 in bit 0 again

# exit the program	
exit:
	li		$v0, SysExit
	syscall
		
