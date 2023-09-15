# Assignment 5 of CS2340.005 by Wei Yuan Liew, 3/27/2023
# NetID: wxl220016
# Given n doubles, this program stores it into an array, sorts it, and prints it out.

	.include 	"SysCalls.asm"
	.data
	.eqv		MAX_SIZE	800	# 8 bytes per double & max 100 float
	.eqv		DOUBLE_SIZE	8
array:	.space		MAX_SIZE
prompt:	.asciiz		"Enter a double: "
sorted_msg:
	.asciiz		"Sorted list: "
count_msg:
	.asciiz		"Count of doubles entered: "
sum_msg:
	.asciiz		"Sum of doubles: "
avg_msg:
	.asciiz		"Average of doubles: "
nl:
	.asciiz		"\n"

# Start of code
	.text
	
main:	
	# Initialize the array, size counter, and max size constant
	la		$t0, array		# $t0 as address of array
	move		$s0, $zero		# $s0 as input count
	mtc1		$zero, $f2		# $f2 is set to 0 for input comparison
	cvt.d.w		$f2, $f2
	jal		input			# gets input from user, $a0 now contains array length
	jal 		sort			# passes in $a0 as array length and bubble sort the doubles
	jal		result			# passes in $a0 as array length and print results
	j 		exit			# exits the program
	
input:	
	# Prompts user for a double
	la		$a0, prompt
	li		$v0, SysPrintString
	syscall
	
	# Takes in double from user
	li		$v0, SysReadDouble
	syscall
	
	# Keeps asking for input while 0 has not been entered
	c.eq.d		$f0, $f2		
	bc1t		exit_input		# exits and return to main
	
	# Adds given double into array
	sdc1		$f0, ($t0)		# stores double into array
	addi		$t0, $t0, DOUBLE_SIZE	# move onto next memory address
	addi		$s0, $s0, 1		# increment input count
	b		input
	
exit_input:
	move		$a0, $s0		# $a0 now contains the length of array
	jr		$ra			# return to main

sort:
	la		$t0, array		# $t0 as addr. of 1st double
	sub		$t1, $a0, 1		# $t1 as counter for outer loop
	li		$t2, 0			# $t2 as swap flag
	li		$t3, 0			# $t3 as outer loop index
	move		$t6, $t1		# $t6 as inner loop counter

sort_outer:
	li		$t4, 0			# $t4 as inner loop index
	addi		$t5, $t0, DOUBLE_SIZE	# $t5 as addr. of 2nd double
	
sort_inner:
	l.d		$f0, ($t0)		# load current double
	l.d		$f2, ($t5)		# load next double
	c.le.d		$f0, $f2		# if current <= next, move to next double
	bc1t		next_double
	
	# swap sequence if current > next
	s.d		$f2, ($t0)
	s.d		$f0, ($t5)
	li		$t2, 1			# set swap flag as true
	
next_double:
	addi		$t4, $t4, 1		# increment inner loop index
	addi		$t0, $t0, DOUBLE_SIZE	# move to next double
	addi		$t5, $t5, DOUBLE_SIZE	# move to double next to next
	blt		$t4, $t6, sort_inner	# if inner loop not finished, continue

	# if no swaps were made, exit sorting algorithm and return to main
	beqz		$t2, exit_sort
	
	# increment outer loop and start next iteration of inner loop
	addi		$t3, $t3, 1		# increment outer loop index
	li		$t2, 0			# reset swap flag
	subi		$t6, $t6, 1		# new counter for inner loop counter
	la		$t0, array		# move array pointer back to 1st element
	blt		$t3, $t1, sort_outer	# repeat inner loop for how long the array is -1 times
	b		exit_sort		# if end of array is reached, exit sorting algorithm
	
exit_sort:
	jr		$ra			# return to main

# Prints out sorted array, sum, and average	
result:
	la		$t0, array		# $t0 now contains address of array
	mtc1.d		$zero, $f0		# $f0 as sum accumulator
	move		$t1, $a0		# $t1 now holds the array length
	add		$t2, $t2, $zero		# counter for array index	
	
	la		$a0, sorted_msg		# displays sorted array prompt 
	li		$v0, SysPrintString
	syscall
	
	la		$a0, nl
	li		$v0, SysPrintString
	syscall
	
# Start printing the sorted array
result_print:
	l.d		$f12, ($t0)		# load first double into register and print
	li		$v0, SysPrintDouble
	syscall
	
	la		$a0, nl
	li		$v0, SysPrintString
	syscall
	
	add.d		$f0, $f0, $f12		# increment the sum
	addi		$t0, $t0, DOUBLE_SIZE	# move onto next double
	addi		$t2, $t2, 1		# increment to next index
	
	blt		$t2, $t1, result_print	# repeat until end of list is reached

# Prints out sum of doubles	
sum:
	la		$a0, sum_msg		# display sum prompt
	li		$v0, SysPrintString
	syscall
	
	mov.d		$f12, $f0		# load value of accumulator into memory and print
	li		$v0, SysPrintDouble
	syscall
	
	la		$a0, nl
	li		$v0, SysPrintString
	syscall
	
# Prints average of given doubles
avg:	
	mtc1		$t1, $f2		# load input count into $f2 and convert for float division
	cvt.d.w		$f2, $f2
	div.d		$f12, $f0, $f2		# divide accumulator by input count for average
	
	la		$a0, avg_msg		# display average prompt
	li		$v0, SysPrintString
	syscall
	
	li		$v0, SysPrintDouble	# print out average
	syscall
	
	jr		$ra			# return to main 
	
# Exit the program
exit:
	li		$v0, SysExit
	syscall		
