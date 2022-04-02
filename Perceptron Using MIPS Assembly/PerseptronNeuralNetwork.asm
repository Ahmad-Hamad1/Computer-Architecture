.data
	askFile: .asciiz "Enter the name of the file: "
	errorMsg: .asciiz "Error while openning or reading the file!!!"
	askInitialWeight: .asciiz "Enter the initial weights: "
	askMomentum: .asciiz "Enter the momentum: "
	askLearningRate: .asciiz "Enter the learning rate: "
	askThreshold: .asciiz "Enter the threshold: "
	askEpochs: .asciiz "Enter number of epochs: "
	printEpoch: .asciiz "Epoch: "
	printIteration: .asciiz "Iteration: "
	printError: .asciiz "The error is : "
	printWeights: .asciiz "The new weights are: "
	printThreshold: .asciiz "The new threshold is : "
	printLearningRate: .asciiz "The new learning rate is : "
	numberOfEpochs: .word 0x00000000
	threshold: .float 0.0
	learningRate: .float 0.0
	momentum: .float 0.0
	lastError: .float 0.0
	currentErro:.float 0.0
	num1: .float 1.04
	num2: .float 0.7
	num3: .float 1.05
	
	file: .space 200
	numberOfFeatures: .word 0x00000000
	numberOfClasses: .word 0x00000000
	numberOfRows: .word 0x00000000
	buffer: .space 1
	features: .word 0x00000000:4096
	weights: .float 0.0:4096
	oldWeightCorrections: .float 0.0:4096
	
.text
.globl main
main:
	la $a0, askFile
	jal printString
	la $a0, file
	li $a1, 200
	jal readString
	la $a0, file
	li $t0, 10  # ASCII value for enter.
	nextChar:  # This loop used to put a null at the end of the file name instead of new line.
		lb $t1, 0($a0)  # Gets the character from memory address stored at $a0.
		beq $t0, $t1, replace  # Check if the loop reached the enter then jumo to replace.
		addiu $a0, $a0, 1  # If not go to next character.
		j nextChar
	replace:
		li $t2, 0  # Store 0 (NULL) in $t2
		sb $t2, 0($a0)  # Overwrite the enter with a null.
	jal readFile
	# Reading initial weight.
	la $a0, askInitialWeight
	jal printString
	# jal readFloat
	# Copy the initial weight to be for all wieghts.
	lw $t0, numberOfFeatures
	la $t1, weights
	li $t2, 0
	copyInitialWeight:
		jal readFloat
		s.s $f0, 0($t1)
		addiu $t1, $t1, 4
		addiu $t2, $t2, 1
		blt $t2, $t0, copyInitialWeight
	# Read momentum.
	la $a0, askMomentum
	jal printString
	jal readFloat
	s.s $f0, momentum
	# Read learning rate.
	la $a0, askLearningRate
	jal printString
	jal readFloat
	s.s $f0, learningRate
	# Read threshold.
	la $a0, askThreshold
	jal printString
	jal readFloat
	s.s $f0, threshold
	# Read number of epochs.
	la $a0, askEpochs
	jal printString
	jal readInteger
	sw $v0, numberOfEpochs
	
	# Training.
	jal train	
		
j end

#function to read a floating number
readFloat:
	li $v0, 6
	syscall
	jr $ra

#function to print a floating number		
printFloat:
	li $v0, 2
	syscall
	jr $ra		

#function to read an integer number
readInteger:
	li $v0, 5
	syscall
	jr $ra

#function to print an integer number
printInteger:
	li $v0, 1
	syscall
	jr $ra

#function to read a string
readString:
	li $v0, 8
	syscall
	jr $ra
	
#function to print string			
printString:
	li $v0, 4
	syscall
	jr $ra
	
#function to print a new line
printNewLine:
	li $v0, 11
	li $a0, 13
	syscall
	li $v0, 11
	li $a0, 10
	syscall
	jr $ra
		
#function to read the file
readFile:
	#openening the file
	la $a0, file # moving the file name.
	li $a1, 0 # For Reading.
	li $v0, 13 # moving the system call code to open the file.
	syscall
	move $a0, $v0 # saving the file descriptor.
	bltz $a0, error # humping to the error section if an error ocurred while openning the file.
	# Reading the file.
	xor $s0, $s0, $s0  # Used to count number of rows.
	xor $t1, $t1, $t1
	li $t4, -1  # Flag to check if there is a number or its just two consecutive commas.
	la $t2, features
	loop:
		li $v0, 14
		la $a1, buffer            # reading a character
		li $a2, 1
		syscall
		beqz $v0, exit # ending the read operation if we reach to the end of the file.
		xor $t0, $t0, $t0
		lb $t0, buffer # moving the read character to t0 register. 
		beq $t0, 10, enterOrComma
		beq $t0, 13, enterOrComma    # cheacking if we reach an enter or a comma or a carriage return.
		beq $t0, 44, enterOrComma
		li $t4, 1
		subiu $t0, $t0, 48
		move $t3, $t1
		sll $t1, $t1, 1          # adding the read digit to our number.
		sll $t3, $t3, 3
		addu $t1, $t1, $t3
		addu $t1, $t1, $t0
		j loop
	enterOrComma:
		beq $t4, -1, loop # chaeking the flag that indicates if we have already read a new digit and returting back to loop if not.
		beqz $s0, featuresNumber # checking if we are at the first line and jumping to number of features section if so.
		beq $s0, 1, classesNumber # checking if we are at the second line and jumping to number of classes section if so.
		sw $t1, 0($t2) # if we aren't at the first or the second lines, so we are reading the features now so we store it
		addiu $t2, $t2, 4 # moving the pointer to the next address in the array features (note that every elemnt takes 4 bytes)
		beq $t0, 13, nextLinePrep # moving to the next line.
		addiu $s0, $s0, 1 # adding a new line to our lines counter.
		xor $t1, $t1, $t1 # clearing the register in which we are storing the read number in.
		li $t4, -1 # returing the flag to its initial value in order to start again
		j loop # returning back to the loop.
		featuresNumber:
			sw $t1, numberOfFeatures   # saving the number of features to our variable.
			j nextLinePrep
		classesNumber:
			sw $t1, numberOfClasses   # saving the number of classes to our variable.
			
		nextLinePrep: # moving forward to read the next line.
			addiu $s0, $s0, 1
			li $v0, 14  # To read the \n at the end of each line.
			syscall
			li $t4, -1  # returing the flag to its initial value in order to start again.
			xor $t1, $t1, $t1 # clearing the register in which we are storing the read number in.
		j loop  # returning back to the loop.
	error:
		li $v0, 4
		la $a0, errorMsg  # priting an error message if any occurs.
		syscall
		j end
	exit:
		subiu $t0, $s0, 2  # subtracting 2 from the number of raws to get the exact number of training lines.
		sw $t0, numberOfRows  # storing the number of training lines.
		jr $ra  # returning back to the main.
		

train:
	
	addiu $sp, $sp, -4  # Allocate one word on stack.
	sw $ra, 0($sp)  # Save return addres on stack.
	
	la $a2, features
	xor $t0, $t0, $t0  # Used to count number of epochs.
	lw $t1, numberOfFeatures
	lw $s0, numberOfRows
	la $s2, features  # To be used when updating weights.
	
	nextEpoch:
	
		li $t7,0
		mtc1 $t7,$f31
		cvt.s.w $f31,$f31
		
		la $a0, printEpoch
		jal printString
		move $a0, $t0
		jal printInteger
		jal printNewLine
		
		la $a2, features
		la $s2, features  # To be used when updating weights.
		xor $s1, $s1, $s1 # To count number of features that are done in each epoch.
		nextRow:
			la $a0, weights
			xor $t2, $t2, $t2  # To count features (columns).
			xor $t3, $t3, $t3
			mtc1 $t3, $f0
			cvt.s.w $f0, $f0
			nextFeature:
				lw $t3, 0($a2)  # Get the feature.
				mtc1 $t3, $f1
				cvt.s.w $f1, $f1
				l.s $f2, 0($a0)  # Get the weight.
				mul.s $f3, $f1, $f2
				add.s $f0, $f0, $f3
			
				addiu $a0, $a0, 4
				addiu $a2, $a2, 4
				addiu $t2, $t2, 1
				addiu $s1, $s1, 1
				blt $t2, $t1, nextFeature  # If there is still features in current row then jump to nextFeature.
			lw $t3, 0($a2)  # Get the class.
			addiu $s1, $s1, 1
			addiu $a2, $a2, 4
			l.s $f1, threshold
			sub.s $f0, $f0, $f1
			
			xor $t4, $t4, $t4
			mtc1 $t4, $f2
			cvt.s.w $f2, $f2
			c.lt.s $f0, $f2
			bc1t lessThanThreshold
			li $t4, 1 # Make calss equal to 1.
			j next
			lessThanThreshold:
				li $t4, 0  # Make class equal to 0.
			next:
			sub $t5, $t3, $t4  # Calculate the error.
			# Covert the error to float.
			mtc1 $t5, $f3
			cvt.s.w $f3, $f3  # $f3 contains the error after converstion to float.
			la $a0, printError
			jal printString
			mov.s $f12, $f3
			jal printFloat
			jal printNewLine
			mul.s $f3,$f3,$f3
			add.s $f31,$f31,$f3
			# Updating the threshold.
			li $t7, -1
			mtc1 $t7, $f7
			cvt.s.w $f7, $f7
			l.s $f8, learningRate
			mul.s $f7, $f7, $f8
			mul.s $f7, $f7, $f3
			l.s $f8, threshold
			add.s $f8, $f8, $f7  # New threshold is in $f8.
			s.s $f8, threshold
			# Printing the new threshold.
			la $a0, printThreshold
			jal printString
			mov.s $f12, $f8
			jal printFloat
			jal printNewLine
			# --------------------
			la $a0, printIteration
			jal printString
			
			jal printNewLine
			la $a0, printWeights
			jal printString
			jal printNewLine
			# Calculate new wieght corrections & update weights.
			xor $s3, $s3, $s3
			la $a0, weights
			la $a1, oldWeightCorrections
			l.s $f7, momentum
			l.s $f8, learningRate
			nextWeight:
				l.s $f9, 0($a1)  # get old weight correction from memory.
				mul.s $f9, $f9, $f7  # Multiply with the momentum.
				lw $t7, 0($s2)  # Get the feature
				mtc1 $t7, $f10
				cvt.s.w $f10, $f10  # $f10 contains the feature after conversion to float.
				mul.s $f10, $f10, $f8
				mul.s $f10, $f10, $f3  # Multiply with the error.
				add.s $f9, $f9, $f10  # $f9 contains the new weight correction.
				s.s $f9, 0($a1)  # Store the new weight correction as old for next iteration.
				addiu $a1, $a1, 4  # For next iteration.
				# Update the weight.
				l.s $f11, 0($a0)  # Get old weight from memory.
				add.s $f11, $f11, $f9  # New weight.
				s.s $f11, 0($a0)  # Store the new weight.
				addiu $a0, $a0, 4  # For next iteration.
				
				# Here to print the new values.
				move $s4, $a0
				mov.s $f12, $f11
				jal printFloat
				jal printNewLine
				move $a0, $s4
				# Prepare for next iteration.
				addiu $s3, $s3, 1
				addiu $s2, $s2, 4  # For next iteration.
				blt $s3, $t1, nextWeight
				
			addiu $s2, $s2, 4  # To ignore the class.
			blt $s1, $s0, nextRow
			beq $t0,0,firstEpoch
			#updating the learning rate
			la $t9,lastError
			lwc1 $f30,0($t9)
			la $t9,num1
			lwc1 $f29,0($t9)
			sub.s $f31,$f31,$f29
			c.le.s $f30,$f31
			bc1f no_decrease
			la $t9,num2
			lwc1 $f28,0($t9)
			la $t9,learningRate 
			lwc1 $f27,0($t9)
			mul.s $f27,$f27,$f28
			swc1 $f27,0($t9)
			j firstEpoch
			no_decrease:
			add.s $f31,$f31,$f29
			c.le.s $f31,$f30
			bc1f firstEpoch
			la $t9,num3
			lwc1 $f28,0($t9)
			la $t9,learningRate 
			lwc1 $f27,0($t9)
			mul.s $f27,$f27,$f28
			swc1 $f27,0($t9)	
		firstEpoch:
		la $t9,lastError
		swc1 $f31,0($t9)
		la $a0, printLearningRate
		jal printString
		la $t9,learningRate 
		lwc1 $f12,0($t9)
		jal printFloat	
		jal printNewLine
		addiu $t0, $t0, 1
		
		lw $s3, numberOfEpochs
		blt $t0, $s3, nextEpoch
		
	lw $ra, 0($sp)  # Get return address from the stack.
	addiu $sp, $sp, 4
	jr $ra


end:	
li $v0, 10
syscall
