
.text
initialize:
addi $sp, $sp, -8
sw $s0, 0($sp) #save registers on stack
sw $s1, 4($sp)
blez $a1, error_initialize #if any of the input values are not > 0, return -1 in v0, v1
blez $a2, error_initialize

sb $a1, ($a0) #store num rows in first byte
addi $a0, $a0, 1 #go to next char
sb $a2, ($a0) #store num columns in 2nd byte
addi $a0, $a0, 1

li $s0, 0 #i=0
traverse_initialize:
li $s1, 0 #j = 0
add_char_initialize:
sb $a3, ($a0)
addi $s1, $s1, 1 #j++
addi $a0, $a0, 1 #next char
beq $s1, $a2, inc_traverse_initialize
j add_char_initialize
inc_traverse_initialize:
addi $s0, $s0, 1 #i++
beq $s0, $a1, traverse_initialize.done
j traverse_initialize

traverse_initialize.done:
move $v0, $a1 #set return values
move $v1, $a2
j end_initialize

error_initialize:
li $v0, -1
li $v1, -1
j end_initialize

end_initialize:
lw $s0, 0($sp) #restore registers
lw $s1, 4($sp)
addi $sp, $sp, 8
	jr $ra

load_game:
addi $sp, $sp, -16
sw $s0, 0($sp) #store registers
sw $s1, 4($sp)
sw $s2, 8($sp)
sw $s3, 12($sp)

move $s0, $a0 #address of gamestate
move $s1, $a1 #address of filename
li $s2, 0 #will count O's
li $s3, 0 #will count invalid chars (not . or O)

li $v0, 13 #open file
move $a0, $s1 #address of file str
li $a1, 0 #read only
li $a2, 0
syscall
blez $v0, error_load_game #if the wrong filename is put (error), v0 is negative
move $s1, $v0 #save file descriptor

addi $sp, $sp, -1 #save 1 byte for loaded char
move $t0, $sp
#reading the row numbers
li $v0, 14 #reading char 1
move $a0, $s1 #file descriptor
move $a1, $t0
li $a2, 1 #read 1 char at a time
syscall
lb $t1, ($t0) #now t1 will contain digit 1
addi $t1, $t1, -48 #get ascii number to actual numerical val
#blez $t1, error_load_game #if file has incorrect input
beqz $v0, error_load_game #if file is empty/error

move $t0, $sp #reset address to read next char
li $v0, 14 #reading char 2
move $a0, $s1 #file descriptor
move $a1, $t0
li $a2, 1 #read 1 char at a time
syscall #now t0 will contain next char
lb $t2, ($t0) #contains digit 2

li $t9, '\n'
beq $t2, $t9, single_digit_rows #if the second byte is newline, it's single digit number
addi $t2, $t2, -48 #get ascii number to actual numerical val
li $t9, 10 
mul $t1, $t1, $t9
add $t1, $t2, $t1 #(1st char * 10) + 2nd char
#if there are 2 digits, the next one is '\n' so read that to skip it
move $t0, $sp #reset address to read next char
li $v0, 14
move $a0, $s1 #file descriptor
move $a1, $t0 #store the char in t0, but it's newline anyway
li $a2, 1 #read 1 char at a time
syscall

single_digit_rows: #this means t1 has the number
sb $t1, ($s0) #store num rows in struct
addi $s0, $s0, 1 #next byte in struct to store into

read_column:
move $t0, $sp #reset address to read next char
li $v0, 14 #read char 1
move $a0, $s1 #file descriptor
move $a1, $t0 #store char in t0
li $a2, 1 #read 1 char at a time
syscall #t0 has the first char
lb $t1, ($t0) #t1 has 1st digit
addi $t1, $t1, -48

move $t0, $sp #reset address to read next char
li $v0, 14 #read char 2
move $a0, $s1 #file descriptor
move $a1, $t0 #store char in t0
li $a2, 1 #read 1 char at a time
syscall 
lb $t2, ($t0) #t2 has second char or '\n'
beq $t2, $t9, single_digit_columns #if 2nd char is newline then add single char to struct
addi $t2, $t2, -48 #get ascii number to actual numerical val
li $t9, 10
mul $t1, $t1, $t9
add $t1, $t1, $t2 #(1st char * 10) + 2nd char

#read out newline to skip it
move $t0, $sp #reset address to read next char
li $v0, 14
move $a0, $s1 #file descriptor
move $a1, $t0 #store the char in t0 addess, but it's newline anyway
li $a2, 1 #read 1 char at a time
syscall

single_digit_columns:
sb $t1, ($s0) #store num columns in struct
addi $s0, $s0, 1 #next byte in struct to store into

#now we read throughout file in loop
read_saved_game:
move $t0, $sp #reset address to read next char
li $v0, 14
move $a0, $s1
move $a1, $t0 #store char in t0
li $a2, 1 #read 1 char
syscall 
lb $t1, ($t0) #now t1 contains the char
blez $v0, read_saved_game.done #if error or end of file
li $t9, '\n'
beq $t1, $t9, read_saved_game #skip newline char and read the next
li $t9, '.'
beq $t1, $t9, add_period
li $t9, 'O'
beq $t1, $t9, increment_O_counter
bne $t1, $t9, increment_invalid_counter

increment_O_counter:
addi $s2, $s2, 1
j add_occupied

increment_invalid_counter:
addi $s3, $s3, 1
j add_occupied

add_period: #adds period to struct from t0
sb $t1, ($s0) 
addi $s0, $s0, 1
j read_saved_game

add_occupied: #adds an O to the struct
li $t1, 'O'
sb $t1, ($s0)
addi $s0, $s0, 1
j read_saved_game


read_saved_game.done: #now we close file
addi $sp, $sp, 1 #restore that 1 byte we used
li $v0, 16
move $a0, $s1 #file descriptor
syscall
move $v0, $s2 #return num of O's
move $v1, $s3 #return num of invalid chars
j end_load_game

error_load_game:
li $v0, -1
li $v1, -1
j end_load_game

end_load_game:
lw $s0, 0($sp) #restore registers
lw $s1, 4($sp)
lw $s2, 8($sp)
lw $s3, 12($sp)
addi $sp, $sp, 16
    jr $ra

get_slot:
addi $sp, $sp, -8
sw $s0, 0($sp) #store registers
sw $s1, 4($sp)

lb $t1, ($a0) #get num rows from struct
addi $a0, $a0, 1 #next get columns
lb $t2, ($a0) #num columns is here
addi $a0, $a0, 1 #go to the non-null terminated str

addi $t1, $t1, -1 #num rows - 1 
addi $t2, $t2, -1 #num cols - 1
bgt $a1, $t1, error_get_slot #if row is non in range, error
bgt $a2, $t2, error_get_slot #if col is not in range, error

#elem[a1][a2] = base_addr + elem_size*(a1*t2 + a2)
addi $t2, $t2, 1 #add 1 back to num cols get the correct math
mul $s0, $a1, $t2 #i*num_columns
add $s0, $s0, $a2 #(i*num_columns) + j and our element size is one so we dont need to multiply
add $s1, $a0, $s0 #base_addr + s0
lb $v0, ($s1) #gets the char at that spot
j end_get_slot

error_get_slot:
li $v0, -1 #returns -1

end_get_slot:
lw $s0, 0($sp) #restore registers
lw $s1, 4($sp)
addi $sp, $sp, 8
    jr $ra

set_slot:
addi $sp, $sp, -8
sw $s0, 0($sp) #store registers
sw $s1, 4($sp)

lb $t1, ($a0) #num rows
addi $a0, $a0, 1 #go to num_cols
lb $t2, ($a0), #num cols
addi $a0, $a0, 1 #go to the non-null terminated str

addi $t1, $t1, -1 #num rows - 1
addi $t2, $t2, -1 #num cols - 1
bgt $a1, $t1, error_set_slot #checks if rows input in range
bgt $a2, $t2, error_set_slot #checks if columns input in range

addi $t2, $t2, 1 #add 1 back to do the correct math
mul $s0, $a1, $t2 # i*num_columns
add $s0, $s0, $a2 #(i*num_columns) + j; we do not need to multiply bc we want 1 byte
add $s1, $a0, $s0 #base_addr + s0

sb $a3, ($s1)
move $v0, $a3 #set return val to input char
j end_set_slot

error_set_slot:
li $v0, -1

end_set_slot:
lw $s0, 0($sp) #restore registers
lw $s1, 4($sp)
addi $sp, $sp, 8
    jr $ra

rotate:
addi $sp, $sp, -20
sw $s0, 0($sp) #store registers
sw $s1, 4($sp)
sw $ra, 8($sp)
sw $s2, 12($sp)
sw $s3, 16($sp)

move $s0, $a0 #address of non rotated piece
move $s1, $a1 #number of rotations
move $s2, $a2 #address of new piece
move $s3, $s1 #return val

#we save the original piece onto the stack
addi $sp, $sp, -8
lb $t0, 0($s0) #num rows
sb $t0, 0($sp)
lb $t0, 1($s0) #num cols
sb $t0, 1($sp)
lb $t0, 2($s0) #slot1
sb $t0, 2($sp)
lb $t0, 3($s0) #slot 2
sb $t0, 3($sp)
lb $t0, 4($s0) #slot 3
sb $t0, 4($sp)
lb $t0, 5($s0) #slot4
sb $t0, 5($sp)
lb $t0, 6($s0) #slot 5
sb $t0, 6($sp)
lb $t0, 7($s0) #slot 6
sb $t0, 7($sp)

bltz $a1, error_rotate #if rotate < 0
beqz $a1, no_rotations #if input is 0, return as is
move $s0, $a0 #address of non rotated piece

lb $t1, ($s0) #get num rows
addi $s0, $s0, 1
lb $t2, ($s0) #num cols
move $s0, $a0
beq $t1, $t2, return_O_piece #both numbers are only the same for O piece
li $t9, 1
beq $t1, $t9, rotate_I_piece #if the row is 1, flip the I piece as many times as said
li $t9, 4
beq $t1, $t9, rotate_I_piece #if the row is 4, flip I piece

#this means t1 contains rows and t2 contains cols

li $t0, 4
div $s1, $t0
mfhi $s1 #once we divide num rotations by 4, we either rotate 0, 1, 2, or 3 times
move $a1, $s3
beqz $s1, no_rotations #if the remainder is 0, we copy over the contents

rotate_rest:
beqz $s1, rotate_rest.done #if rotations = 0, jump out loop
lb $t1, 0($s0) #get num rows
lb $t2, 1($s0) #num cols

#initialize the new piece with the row and nums
move $a0, $s2 #new piece
move $a1, $t2 #new num rows
move $a2, $t1 #new num cols
li $a3, '.' #will load up all periods in new piece
li $t9, 3
beq $a1, $t9, rotate_3_2 #rotates to the 3x2 piece, if not rotates to the 2x3 piece
jal initialize
#rotate byte 1
move $a0, $s0 #address of original piece
li $a1, 2 #row number
li $a2, 0 #col num
jal get_slot #gets [2][0] from original
move $a0, $s2 #address of new piece
li $a1, 0 #row num
li $a2, 0 #col num
move $a3, $v0 #char we put in
jal set_slot #sets [0][0] to [2][0] from original
#rotate byte 2
move $a0, $s0 #address of original piece
li $a1, 1 #row number
li $a2, 0 #col num
jal get_slot #gets [1][0] from original
move $a0, $s2 #address of new piece
li $a1, 0 #row num
li $a2, 1 #col num
move $a3, $v0 #char we put in
jal set_slot #sets [0][1] to [1][0] from original
#rotate byte 3
move $a0, $s0 #address of original piece
li $a1, 0 #row number
li $a2, 0 #col num
jal get_slot #gets [0][0] from original
move $a0, $s2 #address of new piece
li $a1, 0 #row num
li $a2, 2 #col num
move $a3, $v0 #char we put in
jal set_slot #sets [0][2] to [0][0] from original
#rotate byte 4
move $a0, $s0 #address of original piece
li $a1, 2 #row number
li $a2, 1 #col num
jal get_slot #gets [2][1] from original
move $a0, $s2 #address of new piece
li $a1, 1 #row num
li $a2, 0 #col num
move $a3, $v0 #char we put in
jal set_slot #sets [1][0] to [2][1] from original
#rotate byte 5
move $a0, $s0 #address of original piece
li $a1, 1 #row number
li $a2, 1 #col num
jal get_slot #gets [1][1] from original
move $a0, $s2 #address of new piece
li $a1, 1 #row num
li $a2, 1 #col num
move $a3, $v0 #char we put in
jal set_slot #sets [1][1] to [1][1] from original
#rotate byte 6
move $a0, $s0 #address of original piece
li $a1, 0 #row number
li $a2, 1 #col num
jal get_slot #gets [0][1] from original
move $a0, $s2 #address of new piece
li $a1, 1 #row num
li $a2, 2 #col num
move $a3, $v0 #char we put in
jal set_slot #sets [1][2] to [0][1] from original
j inc_rotate_rest

rotate_3_2: #makes a 2x3 piece to 3x2
jal initialize
#rotates byte 1
move $a0, $s0 #address of non rotated piece
li $a1, 1 #row number
li $a2, 0 #col number
jal get_slot #gets [1][0] from original
move $a0, $s2 #address of new piece
li $a1, 0 #row num
li $a2, 0 #col num
move $a3, $v0 #the char from previous
jal set_slot #puts from [1][0] to [0][0] of new piece
#rotates byte 2
move $a0, $s0 #address of non rotated piece
li $a1, 0 #row number
li $a2, 0 #col number
jal get_slot #gets [0][0] from original
move $a0, $s2 #address of new piece
li $a1, 0 #row num
li $a2, 1 #col num
move $a3, $v0 #the char from previous
jal set_slot #puts from [0][0] to [0][1] of new piece
#rotates byte 3
move $a0, $s0 #address of non rotated piece
li $a1, 1 #row number
li $a2, 1 #col number
jal get_slot #gets [1][1] from original
move $a0, $s2 #address of new piece
li $a1, 1 #row num
li $a2, 0 #col num
move $a3, $v0 #the char from previous
jal set_slot #puts from [1][1] to [1][0] of new piece
#rotates byte 4
move $a0, $s0 #address of non rotated piece
li $a1, 0 #row number
li $a2, 1 #col number
jal get_slot #gets [0][1] from original
move $a0, $s2 #address of new piece
li $a1, 1 #row num
li $a2, 1 #col num
move $a3, $v0 #the char from previous
jal set_slot #puts from [0][1] to [1][1] of new piece
#rotates byte 5
move $a0, $s0 #address of non rotated piece
li $a1, 1 #row number
li $a2, 2 #col number
jal get_slot #gets [1][2] from original
move $a0, $s2 #address of new piece
li $a1, 2 #row num
li $a2, 0 #col num
move $a3, $v0 #the char from previous
jal set_slot #puts from [1][2] to [2][0] of new piece
#rotates byte 6
move $a0, $s0 #address of non rotated piece
li $a1, 0 #row number
li $a2, 2 #col number
jal get_slot #gets [0][2] from original
move $a0, $s2 #address of new piece
li $a1, 2 #row num
li $a2, 1 #col num
move $a3, $v0 #the char from previous
jal set_slot #puts from [2][1] to [1][1] of new piece

inc_rotate_rest:
addi $s1, $s1, -1 #rotations--
li $t9, 8
store_in_original: #store the rotated struct in original if we rotate again
beqz $t9, store_in_original.done
lb $t1, ($s2)
sb $t1, ($s0)
addi $s2, $s2, 1 #next byte in rotated
addi $s0, $s0, 1#next byte in original
addi $t9, $t9, -1
j store_in_original
store_in_original.done:
addi $s2, $s2, -8 #go back to starting address
addi $s0, $s0, -8 #go back to starting address
j rotate_rest

rotate_rest.done:
move $v0, $s3 #number of rotations
j end_rotate

rotate_I_piece:
move $s0, $a0 #address of I piece
move $v0, $a1 #number of times we will rotate

swap_I_piece:
beqz $a1, swap_I_piece.done #when we finish swapping, for as many times, write them into Piece
move $t9, $t1 #temp = t1
move $t1, $t2 #t1 = t2
move $t2, $t9 #t2 = temp
addi $a1, $a1, -1 #rotations--
j swap_I_piece
swap_I_piece.done: #adds t1 and t2 to Piece
sb $t1, ($a2)
addi $a2, $a2, 1
sb $t2, ($a2)
addi $a2, $a2, 1
addi $s0, $s0, 2
li $t0, 6
copy_same_str_I:
beqz $t0, end_rotate
lb $t1, ($s0)
sb $t1, ($a2)
addi $s0, $s0, 1
addi $a2, $a2, 1
addi $t0, $t0, -1
j copy_same_str_I

return_O_piece:
move $v0, $a1 #rotated
li $t0, 8
copy_O_rotated:
beqz $t0, end_rotate
lb $t1, ($a0)
sb $t1, ($a2)
addi $a0, $a0, 1
addi $a2, $a2, 1
addi $t0, $t0, -1
j copy_O_rotated

no_rotations:
move $v0, $a1 #return rotations = 0
li $t0, 8
copy_original_no_rotations:
beqz $t0, end_rotate
lb $t1, ($a0)
sb $t1, ($a2)
addi $a0, $a0, 1
addi $a2, $a2, 1
addi $t0, $t0, -1
j copy_original_no_rotations

error_rotate:
li $v0, -1

end_rotate:
lb $t1, 0($sp)#get num rows we saved
sb $t1, 0($s0) #restore original gamepiece
lb $t1, 1($sp)#get num cols we saved
sb $t1, 1($s0)
lb $t1, 2($sp)#get slot1 we saved
sb $t1, 2($s0)
lb $t1, 3($sp)#get slot2 we saved
sb $t1, 3($s0)
lb $t1, 4($sp)#get slot3 we saved
sb $t1, 4($s0)
lb $t1, 5($sp)#get slot4 we saved
sb $t1, 5($s0)
lb $t1, 6($sp)#get slot 5 we saved
sb $t1, 6($s0)
lb $t1, 7($sp)#get slot6 we saved
sb $t1, 7($s0)
addi $sp, $sp, 8
lw $s0, 0($sp) #restore registers
lw $s1, 4($sp)
lw $ra, 8($sp)
lw $s2, 12($sp)
lw $s3, 16($sp)
addi $sp, $sp, 20
    jr $ra

count_overlaps:
addi $sp, $sp, -32
sw $s0, 0($sp) #store registers
sw $s1, 4($sp)
sw $s2, 8($sp)
sw $ra, 12($sp)
sw $s3, 16($sp)
sw $s4, 20($sp)
sw $s5, 24($sp)
sw $s6, 28($sp)

lb $t1, 0($a0) #num rows in gamestate
lb $t2, 1($a0) #num cols in gamestate
addi $t1, $t1, -1 #num rows - 1 in gamestate
addi $t2, $t2, -1 #num cols - 1 in gamestate
bgt $a1, $t1, error_count_overlaps #if input >= num rows, error
bltz $a1, error_count_overlaps
bltz $a2, error_count_overlaps
bgt $a2, $t2, error_count_overlaps #if input >= num cols, error

move $s0, $a0 #address of gamestate
move $s1, $a1 #num row of input
move $s2, $a2 #num col of input
move $s3, $a3 #address of gamepiece
li $s4, 0 #counter for overlapped pieces
li $s5, 0 #will contain char from gamestate
li $s6, 0 #will contain char from piece
lb $t1, 0($s3) #num row of piece
lb $t2, 1($s3) #num col of piece
li $t0, 3
beq $t0, $t1, check_overlap_3x2 #if t1 is a 3, this means we check a 3x2 piece
beq $t1, $t2, check_overlap_O #if row num == col num, it's an O piece
li $t0, 1
beq $t1, $t0, check_overlap_I #checks overlap in I piece
beq $t2, $t0, check_overlap_I #checks overlap in I piece


 #checks a 2x3 piece 
#check if the input slot is occupied
move $a0, $s0 #gamestate
move $a1, $s1 # row[I.row]
move $a2, $s2 # col[I.col]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #char from gamestate 
li $t0, 'O'
bne $s5, $t0, slot2_2x3 #if it is not Occupied, go on to next slot

move $a0, $s3 #game piece
li $a1, 0 #row 0
li $a2, 0 #col 0
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, slot2_2x3 #if it is not occupied, go on to next slot
addi $s4, $s4, 1 #increment overlap counter

slot2_2x3:
move $a0, $s0 #gamestate
move $a1, $s1 #row[I.row]
addi $a2, $s2, 1 #col[I.col + 1]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #get char from gamestate
li $t0, 'O'
bne $s5, $t0, slot3_2x3 #if is not occupied, skip to next slot

move $a0, $s3 #game piece
li $a1, 0 #row 0
li $a2, 1 #col 1
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, slot3_2x3 #if not O, skip to next slot
addi $s4, $s4, 1 #increment overlap counter

slot3_2x3:
move $a0, $s0 #gamestate
move $a1, $s1 #row[I.row]
addi $a2, $s2, 2 #col[I.col + 2]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #get char from gamestate
li $t0, 'O'
bne $s5, $t0, slot4_2x3 #if is not occupied, skip to next slot

move $a0, $s3 #game piece
li $a1, 0 #row 0
li $a2, 2 #col 2
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, slot4_2x3 #if not O, skip to next slot
addi $s4, $s4, 1 #increment overlap counter

slot4_2x3:
move $a0, $s0 #gamestate
addi $a1, $s1, 1 #row[I.row+1]
move $a2, $s2 #col[I.col]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #get char from gamestate
li $t0, 'O'
bne $s5, $t0, slot5_2x3 #if is not occupied, skip to next slot

move $a0, $s3 #game piece
li $a1, 1 #row 1
li $a2, 0 #col 0
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, slot5_2x3 #if not O, skip to next slot
addi $s4, $s4, 1 #increment overlap counter

slot5_2x3:
move $a0, $s0 #gamestate

addi $a1, $s1, 1 #row[I.row+1]
addi $a2, $s2, 1 #col[I.col+1]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #get char from gamestate
li $t0, 'O'
bne $s5, $t0, slot6_2x3 #if is not occupied, skip to next slot

move $a0, $s3 #game piece
li $a1, 1 #row 1
li $a2, 1 #col 1
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, slot6_2x3 #if not O, skip to next slot
addi $s4, $s4, 1 #increment overlap counter

slot6_2x3:
move $a0, $s0 #gamestate
addi $a1, $s1, 1 #row[I.row+1]
addi $a2, $s2, 2 #col[I.col+2]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #get char from gamestate
li $t0, 'O'
bne $s5, $t0, done_comparing #if not O, done comparing

move $a0, $s3 #game piece
li $a1, 1 #row 1
li $a2, 2 #col 2
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, done_comparing #if not O, done comparing
addi $s4, $s4, 1 #increment overlap counter
j done_comparing

check_overlap_3x2:
#check if the input slot is occupied
move $a0, $s0 #gamestate
move $a1, $s1 # row[I.row]
move $a2, $s2 # col[I.col]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #char from gamestate 
li $t0, 'O'
bne $s5, $t0, slot2_3x2 #if it is not Occupied, go on to next slot

move $a0, $s3 #game piece
li $a1, 0 #row 0
li $a2, 0 #col 0
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, slot2_3x2 #if it is not occupied, go on to next slot
addi $s4, $s4, 1 #increment overlap counter

slot2_3x2:
move $a0, $s0 #gamestate
move $a1, $s1 #row[I.row]
addi $a2, $s2, 1 #col[I.col + 1]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #get char from gamestate
li $t0, 'O'
bne $s5, $t0, slot3_3x2 #if is not occupied, skip to next slot

move $a0, $s3 #game piece
li $a1, 0 #row 0
li $a2, 1 #col 1
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, slot3_3x2 #if not O, skip to next slot
addi $s4, $s4, 1 #increment overlap counter

slot3_3x2:
move $a0, $s0 #gamestate
addi $a1, $s1, 1 #row[I.row+1]
move $a2, $s2 #col[I.col]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #get char from gamestate
li $t0, 'O'
bne $s5, $t0, slot4_3x2 #if is not occupied, skip to next slot

move $a0, $s3 #game piece
li $a1, 1 #row 1
li $a2, 0 #col 0
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, slot4_3x2 #if not O, skip to next slot
addi $s4, $s4, 1 #increment overlap counter

slot4_3x2:
move $a0, $s0 #gamestate
addi $a1, $s1, 1 #row[I.row+1]
addi $a2, $s2, 1 #col[I.col+1]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #get char from gamestate
li $t0, 'O'
bne $s5, $t0, slot5_3x2 #if is not occupied, skip to next slot

move $a0, $s3 #game piece
li $a1, 1 #row 1
li $a2, 1 #col 1
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, slot5_3x2 #if not O, skip to next slot
addi $s4, $s4, 1 #increment overlap counter

slot5_3x2:
move $a0, $s0 #gamestate
addi $a1, $s1, 2 #row[I.row+2]
move $a2, $s2 #col[I.col]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #get char from gamestate
li $t0, 'O'
bne $s5, $t0, slot6_3x2 #if is not occupied, skip to next slot

move $a0, $s3 #game piece
li $a1, 2 #row 2
li $a2, 0 #col 0
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, slot6_3x2 #if not O, skip to next slot
addi $s4, $s4, 1 #increment overlap counter

slot6_3x2:
move $a0, $s0 #gamestate
addi $a1, $s1, 2 #row[I.row+2]
addi $a2, $s2, 1 #col[I.col+1]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #get char from gamestate
li $t0, 'O'
bne $s5, $t0, done_comparing #if not O, done comparing

move $a0, $s3 #game piece
li $a1, 2 #row 2
li $a2, 1 #col 1
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, done_comparing #if not O, done comparing
addi $s4, $s4, 1 #increment overlap counter

done_comparing:
move $v0, $s4 #return how many overlaps we have
j end_count_overlaps

check_overlap_O:
#check if the input slot is occupied
move $a0, $s0 #gamestate
move $a1, $s1 # row[I.row]
move $a2, $s2 # col[I.col]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #char from gamestate 
li $t0, 'O'
bne $s5, $t0, slot2_O #if it is not Occupied, go on to next slot

move $a0, $s3 #game piece
li $a1, 0 #row 0
li $a2, 0 #col 0
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, slot2_O #if it is not occupied, go on to next slot
addi $s4, $s4, 1 #increment overlap counter

slot2_O :
move $a0, $s0 #gamestate
move $a1, $s1 #row[I.row]
li $t1, 1
add $a2, $s2, $t1 #col[I.col + 1]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #get char from gamestate
li $t0, 'O'
bne $s5, $t0, slot3_O #if is not occupied, skip to next slot

move $a0, $s3 #game piece
li $a1, 0 #row 0
li $a2, 1 #col 1
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, slot3_O #if not O, skip to next slot
addi $s4, $s4, 1 #increment overlap counter

slot3_O:
move $a0, $s0 #gamestate
li $t1, 1
add $a1, $s1, $t1 #row[I.row+1]
move $a2, $s2 #col[I.col]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #get char from gamestate
li $t0, 'O'
bne $s5, $t0, slot4_O #if is not occupied, skip to next slot

move $a0, $s3 #game piece
li $a1, 1 #row 1
li $a2, 0 #col 0
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, slot4_O #if not O, skip to next slot
addi $s4, $s4, 1 #increment overlap counter

slot4_O:
move $a0, $s0 #gamestate
li $t1, 1
add $a1, $s1, $t1 #row[I.row+1]
add $a2, $s2, $t1 #col[I.col+1]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #get char from gamestate
li $t0, 'O'
bne $s5, $t0, done_comparing #if not O, done comparing

move $a0, $s3 #game piece
li $a1, 1 #row 1
li $a2, 1 #col 1
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, done_comparing #if not O, done comparing
addi $s4, $s4, 1 #increment overlap counter
j done_comparing
check_overlap_I:
li $t0, 1
lb $t1, ($s3) #get num row from I piece
beq $t0, $t1, check_I_1x4 #if the row for I piece is 1, we check 1x4 orientation, else check 4x1
#check if the input slot is occupied
#4x1
move $a0, $s0 #gamestate
move $a1, $s1 # row[I.row]
move $a2, $s2 # col[I.col]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #char from gamestate 
li $t0, 'O'
bne $s5, $t0, slot2_I #if it is not Occupied, go on to next slot

move $a0, $s3 #game piece
li $a1, 0 #row 0
li $a2, 0 #col 0
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, slot2_I #if it is not occupied, go on to next slot
addi $s4, $s4, 1 #increment overlap counter

slot2_I:
move $a0, $s0 #gamestate
addi $a1, $s1, 1 #row[I.row+1]
move $a2, $s2 #col[I.col]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #get char from gamestate
li $t0, 'O'
bne $s5, $t0, slot3_I #if is not occupied, skip to next slot

move $a0, $s3 #game piece
li $a1, 1 #row 1
li $a2, 0 #col 0
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, slot3_I #if not O, skip to next slot
addi $s4, $s4, 1 #increment overlap counter

slot3_I:
move $a0, $s0 #gamestate
addi $a1, $s1, 2 #row[I.row+2]
move $a2, $s2 #col[I.col]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #get char from gamestate
li $t0, 'O'
bne $s5, $t0, slot4_I #if is not occupied, skip to next slot

move $a0, $s3 #game piece
li $a1, 2 #row 2
li $a2, 0 #col 0
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, slot4_I #if not O, skip to next slot
addi $s4, $s4, 1 #increment overlap counter

slot4_I:
move $a0, $s0 #gamestate
addi $a1, $s1, 3 #row[I.row+3]
move $a2, $s2 #col[I.col]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #get char from gamestate
li $t0, 'O'
bne $s5, $t0, done_comparing #if not O, done comparing

move $a0, $s3 #game piece
li $a1, 3 #row 3
li $a2, 0 #col 0
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, done_comparing #if not O, done comparing
addi $s4, $s4, 1 #increment overlap counter
j done_comparing #jump tp end after done comparing
check_I_1x4:
#check if the input slot is occupied
move $a0, $s0 #gamestate
move $a1, $s1 # row[I.row]
move $a2, $s2 # col[I.col]
jal get_slot
move $s5, $v0 #char from gamestate 
li $t0, 'O'
bne $s5, $t0, slot2_I_1x4 #if it is not Occupied, go on to next slot

move $a0, $s3 #game piece
li $a1, 0 #row 0
li $a2, 0 #col 0
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, slot2_I_1x4 #if it is not occupied, go on to next slot
addi $s4, $s4, 1 #increment overlap counter

slot2_I_1x4:
move $a0, $s0 #gamestate
move $a1, $s1 #row[I.row]
li $t1, 1
add $a2, $s2, $t1 #col[I.col + 1]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #get char from gamestate
li $t0, 'O'
bne $s5, $t0, slot3_I_1x4 #if is not occupied, skip to next slot

move $a0, $s3 #game piece
li $a1, 0 #row 0
li $a2, 1 #col 1
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, slot3_I_1x4 #if not O, skip to next slot
addi $s4, $s4, 1 #increment overlap counter

slot3_I_1x4:
move $a0, $s0 #gamestate
move $a1, $s1 #row[I.row]
li $t1, 2
add $a2, $s2, $t1 #col[I.col + 2]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #get char from gamestate
li $t0, 'O'
bne $s5, $t0, slot4_I_1x4 #if is not occupied, skip to next slot

move $a0, $s3 #game piece
li $a1, 0 #row 0
li $a2, 2 #col 2
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, slot4_I_1x4 #if not O, skip to next slot
addi $s4, $s4, 1 #increment overlap counter

slot4_I_1x4:
move $a0, $s0 #gamestate
move $a1, $s1 #row[I.row]
li $t1, 3
add $a2, $s2, $t1 #col[I.col + 3]
jal get_slot
bltz $v0, error_count_overlaps #if out of bounds, return error
move $s5, $v0 #get char from gamestate
li $t0, 'O'
bne $s5, $t0, done_comparing #if is not occupied, skip to end

move $a0, $s3 #game piece
li $a1, 0 #row 0
li $a2, 3 #col 3
jal get_slot
move $s6, $v0
li $t0, 'O'
bne $s6, $t0, done_comparing #if not O, skip to end
addi $s4, $s4, 1 #increment overlap counter
j done_comparing
error_count_overlaps:
li $v0, -1 #returns -1

end_count_overlaps:
lw $s0, 0($sp) #restore registers
lw $s1, 4($sp)
lw $s2, 8($sp)
lw $ra, 12($sp)
lw $s3, 16($sp)
lw $s4, 20($sp)
lw $s5, 24($sp)
lw $s6, 28($sp)
addi $sp, $sp, 32
	jr $ra

drop_piece:
lw $t0, 0($sp) #load the address of rotated piece*
addi $sp, $sp, -32
sw $s0, 0($sp) #store registers
sw $s1, 4($sp)
sw $s2, 8($sp)
sw $s3, 12($sp)
sw $s4, 16($sp)
sw $ra, 20($sp)
sw $s5, 24($sp)
sw $s6, 28($sp)

move $s0, $a0 #address of gamestate
move $s1, $a1 #col we want to insert slot1 of piece into
move $s2, $a2 #address of non-rotated piece
move $s3, $a3 #num rotations
move $s4, $t0 #address of rotated piece
bltz $s1, error2

lb $s5, 0($a0) #the number of rows in the gamestate
addi $s5, $s5, -1 #num rows in gamestate - 1
lb $t1, 1($s0) #num col of gamestate
addi $t1, $t1, -1 #num col -1 in gamestate
bgt $s1, $t1, error2 #if col >= num cols in gamestate

move $a0, $s2 #address non-rotated
move $a1, $s3 #num rotations
move $a2, $s4 #address rotated
jal rotate #this rotates the piece we will try to drop into gamefield
bltz $v0, error2 #if error on rotations, error -2, else rotation is valid

li $s6, 0
check_piece_fits:
move $a0, $s0 #gamestate
move $a1, $s6 #row
move $a2, $s1 #col
move $a3, $s4 #piece
jal count_overlaps
bgtz $v0, add_previous_row
bltz $v0, check_poking_from_bottom #pokes out
addi $s6, $s6, 1
beq $s6, $s5, check_overlap_bottom #if we reach bottom
j check_piece_fits

check_poking_from_bottom: #if pokes out from bottom
addi $s6, $s6, -1 #previous row
move $a0, $s0 #gamestate
move $a1, $s6 #row
move $a2, $s1 #col
move $a3, $s4 #piece
jal count_overlaps
bltz $v0, error3 #pokes out
beqz $v0, store_new_piece #if no overlap, store piece
bgtz $v0, error1

check_overlap_bottom:
move $a0, $s0 #gamestate
move $a1, $s6 #row
move $a2, $s1 #col
move $a3, $s4 #piece
jal count_overlaps
beqz $v0, store_new_piece

add_previous_row:
addi $s6, $s6, -1 #previous row
bltz $s6, error1 #if < 0, cannot fit on gamepiece

store_new_piece:#stores the pieces in gamestate
lb $t1, 0($s4) #num rows in dropped piece
lb $t2, 1($s4) #num cols in dropped piece
beq $t1, $t2, add_O_to_game #if row and col are the same, O
li $t0, 1
beq $t1, $t0, drop_1x4_I #if I-piece is 1x4
beq $t2, $t0, drop_4x1_I #if I-piece is 4x1
li $t0, 3
beq $t1, $t0, drop_3x2 #if row is 3
beq $t2, $t0, drop_2x3 #if col is 3

drop_1x4_I:
#byte1
move $a0, $s4 #1x4 I piece
li $a1, 0 #row 0 of piece
li $a2, 0 #col 0 of piece
jal get_slot
move $a0, $s0 #gamestate
move $a1, $s6 #row in gamestate
move $a2, $s1 #col in gamestate
move $a3, $v0 #char from piece
jal set_slot
#byte 2
move $a0, $s4 #1x4 I piece
li $a1, 0 #row 0 of piece
li $a2, 1 #col 1 of piece
jal get_slot
move $a0, $s0 #gamestate
move $a1, $s6 #row in gamestate
addi $a2, $s1, 1 #col+1 in gamestate
move $a3, $v0 #char from piece
jal set_slot
#byte3
move $a0, $s4 #1x4 I piece
li $a1, 0 #row 0 of piece
li $a2, 2 #col 2 of piece
jal get_slot
move $a0, $s0 #gamestate
move $a1, $s6 #row in gamestate
addi $a2, $s1, 2 #col+2 in gamestate
move $a3, $v0 #char from piece
jal set_slot
#byte4
move $a0, $s4 #1x4 I piece
li $a1, 0 #row 0 of piece
li $a2, 3 #col 3 of piece
jal get_slot
move $a0, $s0 #gamestate
move $a1, $s6 #row in gamestate
addi $a2, $s1, 3 #col+3 in gamestate
move $a3, $v0 #char from piece
jal set_slot
j successful_drop

drop_4x1_I:
#byte1
move $a0, $s4 #4x1 I piece
li $a1, 0 #row 0 of piece
li $a2, 0 #col 0 of piece
jal get_slot
move $a0, $s0 #gamestate
move $a1, $s6 #row in gamestate
move $a2, $s1 #col in gamestate
move $a3, $v0 #char from piece
jal set_slot
#byte 2
move $a0, $s4 #address of rotated piece
li $a1, 1 #row 1 of piece
li $a2, 0 #col 0 of piece
jal get_slot
move $a0, $s0 #gamestate
addi $a1, $s6, 1 #row+1 in gamestate
move $a2, $s1 #col in gamestate
move $a3, $v0 #char from piece
jal set_slot
#byte3
move $a0, $s4 #address of rotated piece
li $a1, 2 #row 2 of piece
li $a2, 0 #col 0 of piece
jal get_slot
move $a0, $s0 #gamestate
addi $a1, $s6, 2 #row+2 in gamestate
move $a2, $s1 #col in gamestate
move $a3, $v0 #char from piece
jal set_slot
#byte 4
move $a0, $s4 #address of rotated piece
li $a1, 3 #row 3 of piece
li $a2, 0 #col 0 of piece
jal get_slot
move $a0, $s0 #gamestate
addi $a1, $s6, 3 #row+3 in gamestate
move $a2, $s1 #col in gamestate
move $a3, $v0 #char from piece
jal set_slot
j successful_drop

add_O_to_game:
#byte1
move $a0, $s4 #O-piece
li $a1, 0 #row 0 of piece
li $a2, 0 #col 0 of piece
jal get_slot
move $a0, $s0 #gamestate
move $a1, $s6 #row in gamestate
move $a2, $s1 #col in gamestate
move $a3, $v0 #char from gamepiece
jal set_slot 
#byte2
move $a0, $s4 #O-piece
li $a1, 0 #row 0 of piece
li $a2, 1 #col 1 of piece
jal get_slot
move $a0, $s0 #gamestate
move $a1, $s6 #row in gamestate
addi $a2, $s1, 1 #col+1 in gamestate
move $a3, $v0 #char from gamepiece
jal set_slot 
#byte3
move $a0, $s4 #O-piece
li $a1, 1 #row 1 of piece
li $a2, 0 #col 0 of piece
jal get_slot
move $a0, $s0 #gamestate
addi $a1, $s6, 1 #row+1 in gamestate
move $a2, $s1 #col in gamestate
move $a3, $v0 #char from gamepiece
jal set_slot 
#byte 4
move $a0, $s4 #O-piece
li $a1, 1 #row 1 of piece
li $a2, 1 #col 1 of piece
jal get_slot
move $a0, $s0 #gamestate
addi $a1, $s6, 1 #row+1 in gamestate
addi $a2, $s1, 1 #col+1 in gamestate
move $a3, $v0 #char from gamepiece
jal set_slot 
j successful_drop

drop_3x2:
#byte1
move $a0, $s4 #3x2-piece
li $a1, 0 #row 0 of piece
li $a2, 0 #col 0 of piece
jal get_slot
li $t0, '.'
beq $v0, $t0, byte2_3x2
move $a0, $s0 #gamestate
move $a1, $s6 #row in gamestate
move $a2, $s1 #col in gamestate
move $a3, $v0 #char from gamepiece
jal set_slot 
byte2_3x2:
move $a0, $s4 #3x2-piece
li $a1, 0 #row 0 of piece
li $a2, 1 #col 1 of piece
jal get_slot
li $t0, '.'
beq $v0, $t0, byte3_3x2
move $a0, $s0 #gamestate
move $a1, $s6 #row in gamestate
addi $a2, $s1, 1 #col+1 in gamestate
move $a3, $v0 #char from gamepiece
jal set_slot 
byte3_3x2:
move $a0, $s4 #3x2-piece
li $a1, 1 #row 1 of piece
li $a2, 0 #col 0 of piece
jal get_slot
li $t0, '.'
beq $v0, $t0, byte4_3x2
move $a0, $s0 #gamestate
addi $a1, $s6, 1 #row+1 in gamestate
move $a2, $s1 #col in gamestate
move $a3, $v0 #char from gamepiece
jal set_slot 
byte4_3x2:
move $a0, $s4 #3x2-piece
li $a1, 1 #row 1 of piece
li $a2, 1 #col 1 of piece
jal get_slot
li $t0, '.'
beq $v0, $t0, byte5_3x2
move $a0, $s0 #gamestate
addi $a1, $s6, 1 #row+1 in gamestate
addi $a2, $s1, 1 #col+1 in gamestate
move $a3, $v0 #char from gamepiece
jal set_slot 
byte5_3x2:
move $a0, $s4 #3x2-piece
li $a1, 2 #row 2 of piece
li $a2, 0 #col 0 of piece
jal get_slot
li $t0, '.'
beq $v0, $t0, byte6_3x2
move $a0, $s0 #gamestate
addi $a1, $s6, 2 #row+2 in gamestate
move $a2, $s1 #col in gamestate
move $a3, $v0 #char from gamepiece
jal set_slot 
byte6_3x2:
move $a0, $s4 #3x2-piece
li $a1, 2 #row 2 of piece
li $a2, 1 #col 1 of piece
jal get_slot
li $t0, '.'
beq $v0, $t0, successful_drop
move $a0, $s0 #gamestate
addi $a1, $s6, 2 #row+2 in gamestate
addi $a2, $s1, 1 #col+1 in gamestate
move $a3, $v0 #char from gamepiece
jal set_slot 
j successful_drop

drop_2x3:
#byte1
move $a0, $s4 #2x3-piece
li $a1, 0 #row 0 of piece
li $a2, 0 #col 0 of piece
jal get_slot
li $t0, '.'
beq $v0, $t0, byte2_2x3
move $a0, $s0 #gamestate
move $a1, $s6 #row in gamestate
move $a2, $s1 #col in gamestate
move $a3, $v0 #char from gamepiece
jal set_slot
byte2_2x3:
move $a0, $s4 #2x3-piece
li $a1, 0 #row 0 of piece
li $a2, 1 #col 1 of piece
jal get_slot
li $t0, '.'
beq $v0, $t0, byte3_2x3
move $a0, $s0 #gamestate
move $a1, $s6 #row in gamestate
addi $a2, $s1, 1 #col+1 in gamestate
move $a3, $v0 #char from gamepiece
jal set_slot
byte3_2x3:
move $a0, $s4 #2x3-piece
li $a1, 0 #row 0 of piece
li $a2, 2 #col 2 of piece
jal get_slot
li $t0, '.'
beq $v0, $t0, byte4_2x3
move $a0, $s0 #gamestate
move $a1, $s6 #row in gamestate
addi $a2, $s1, 2 #col+2 in gamestate
move $a3, $v0 #char from gamepiece
jal set_slot
byte4_2x3:
move $a0, $s4 #2x3-piece
li $a1, 1 #row 1 of piece
li $a2, 0 #col 0 of piece
jal get_slot
li $t0, '.'
beq $v0, $t0, byte5_2x3
move $a0, $s0 #gamestate
addi $a1, $s6, 1 #row+1 in gamestate
move $a2, $s1 #col in gamestate
move $a3, $v0 #char from gamepiece
jal set_slot
byte5_2x3:
move $a0, $s4 #2x3-piece
li $a1, 1 #row 1 of piece
li $a2, 1 #col 1 of piece
jal get_slot
li $t0, '.'
beq $v0, $t0, byte6_2x3
move $a0, $s0 #gamestate
addi $a1, $s6, 1 #row+1 in gamestate
addi $a2, $s1, 1 #col+1 in gamestate
move $a3, $v0 #char from gamepiece
jal set_slot
byte6_2x3:
move $a0, $s4 #2x3-piece
li $a1, 1 #row 1 of piece
li $a2, 2 #col 2 of piece
jal get_slot
li $t0, '.'
beq $v0, $t0, successful_drop
move $a0, $s0 #gamestate
addi $a1, $s6, 1 #row+1 in gamestate
addi $a2, $s1, 2 #col+2 in gamestate
move $a3, $v0 #char from gamepiece
jal set_slot
j successful_drop

successful_drop:
move $v0, $s6
j end_drop_piece

error1:#if piece doesn't fit on field
li $v0, -1
j end_drop_piece

error3: #if the piece pokes out
li $v0, -3
j end_drop_piece

error2:#return -2 error
li $v0, -2 

end_drop_piece:
lw $s0, 0($sp) #restore registers
lw $s1, 4($sp)
lw $s2, 8($sp)
lw $s3, 12($sp)
lw $s4, 16($sp)
lw $ra, 20($sp)
lw $s5, 24($sp)
lw $s6, 28($sp)
addi $sp, $sp, 32
	jr $ra

check_row_clear:
addi $sp, $sp, -28
sw $s0, 0($sp) #store registers
sw $s1, 4($sp)
sw $ra, 8($sp)
sw $s2, 12($sp)
sw $s3, 16($sp)
sw $s4, 20($sp)
sw $s5, 24($sp)

lb $s0, 0($a0) #get num rows in gamestate
addi $s0, $s0, -1 #num rows - 1 in gamestate
bgt $a1, $s0, error_check_row_clear #if input > numrows-1 in gamepiece, error
bltz $a1, error_check_row_clear
lb $s1, 1($a0) #get num cols in gamestate
addi $s1, $s1, -1 #numcols - 1 in gamestate
move $s3, $a1 #input row
move $s4, $a0 #address of gamestate
li $s5, 0 #column counter
traverse_row:
#check the first column of the row from input
move $a0, $s4 #gamestate
move $a1, $s3 #row from input
move $a2, $s5 #column
jal get_slot
li $t0, 'O'
bne $v0, $t0, cannot_clear_row
beq $s1, $s5, clear_out_row #if last col is also O, we clear it out
addi $s5, $s5, 1 #next col
j traverse_row

clear_out_row:
li $s5, 0 #reset col counter
replace_row:
move $a0, $s4 #gamestate
addi $a1, $s3, -1 #[row-1] from input
move $a2, $s5 #column
jal get_slot
move $a0, $s4 #gamestate
move $a1, $s3 #[row] from input
move $a2, $s5 #col in gamestate
move $a3, $v0 #char from previous row
jal set_slot
addi $s5, $s5, 1 #next col
bgt $s5, $s1, replace_row.done
j replace_row

replace_row.done:
addi $s3, $s3, -1 #input row -1
bltz $s3, reset_row0 #if we finished, add 0's to first row
j clear_out_row

reset_row0:
li $s5, 0 #col counter
clear_row0:
move $a0, $s4 #address of gamestate
li $a1, 0 #row 0
move $a2, $s5 #col
li $a3, '.' #adding .'s to first row
jal set_slot
addi $s5, $s5, 1
bgt $s5, $s1, row_is_cleared
j clear_row0

row_is_cleared:
li $v0, 1
j end_check_row_clear

cannot_clear_row:
li $v0, 0
j end_check_row_clear

error_check_row_clear:
li $v0 , -1

end_check_row_clear:
lw $s0, 0($sp) #restore registers
lw $s1, 4($sp)
lw $ra, 8($sp)
lw $s2, 12($sp)
lw $s3, 16($sp)
lw $s4, 20($sp)
lw $s5, 24($sp)
addi $sp, $sp, 28
	jr $ra

simulate_game:
lw $t0, 0($sp) #num pieces dropped
lw $t1, 4($sp) #address of pieces[]
addi $sp, $sp, -36
sw $s0, 0($sp) #store registers
sw $s1, 4($sp)
sw $s2, 8($sp)
sw $s3, 12($sp)
sw $s4, 16($sp)
sw $s5, 20($sp)
sw $s6, 24($sp)
sw $ra, 28($sp)
sw $s7, 32($sp)

move $s0, $a0 #gamestate
move $s1, $a2 #moves
move $s2, $a3 #rotated
move $s3, $t0 #pieces to drop
move $s4, $t1 #pieces[]

jal load_game
bltz $v0, error_simulate
bltz $v1, error_simulate

move $t0, $s1 #moves
li $s7, 0
moves_length:
lb $t1, ($t0)
beqz $t1, moves_length.done
addi $s7, $s7, 1
addi $t0, $t0, 4
j moves_length

moves_length.done:
li $s5, 0 #successful drops
li $s6, 0 #score

sim_iteration:
lb $t1, ($s1)
li $t9, 'T'
beq $t1, $t9, get_t_piece
li $t9, 'J'
beq $t1, $t9, get_j_piece
li $t9, 'Z'
beq $t1, $t9, get_z_piece
li $t9, 'O'
beq $t1, $t9, get_o_piece
li $t9, 'S'
beq $t1, $t9, get_s_piece
li $t9, 'L'
beq $t1, $t9, get_l_piece
li $t9, 'I'
beq $t1, $t9, get_i_piece

get_t_piece:
move $a2, $s4
j got_piece
get_j_piece:
addi $a2, $s4, 8
j got_piece
get_z_piece:
addi $a2, $s4, 16
j got_piece
get_o_piece:
addi $a2, $s4, 24
j got_piece
get_s_piece:
addi $a2, $s4, 32
j got_piece
get_l_piece:
addi $a2, $s4, 40
j got_piece
get_i_piece:
addi $a2, $s4, 48

got_piece:
addi $s1, $s1, 1
lb $t0, ($s1) #rotations
addi $t0, $t0, -48
addi $s1, $s1, 1
lb $t1, ($s1) #dig1 col
addi $t1, $t1, -48
li $t9, 10
mul $t1, $t1, $t9
addi $s1, $s1, 1
lb $t2, ($s1) #dig2col
addi $s1, $s1, 1
addi $t2, $t2, -48
add $t1, $t1, $t2 #cols

move $a0, $s0
move $a1, $t1
#a2 is loaded
move $a3, $t0
addi $sp, $sp, -4
sw $s2, 0($sp)
jal drop_piece
addi $sp, $sp, 4

li $t9, -1
beq $v0, $t9, game_over_true
blt $v0, $t9, inc_sim_iteration
addi $s5, $s5, 1 #successful drop

lb $t9, 1($s0) #rows in game
li $t8, 0
clear_lines:
move $a0, $s0
move $a1, $t9
addi $sp, $sp, -8
sw $t9, 0($sp)
sw $t8, 4($sp)
jal check_row_clear
lw $t9, 0($sp)
lw $t8, 4($sp)
addi $sp, $sp, 8
blez $v0, inc_clear_lines
addi $t8, $t8, 1
inc_clear_lines:
addi $t9, $t9, -1
bgtz $t9, clear_lines

count_score:
li $t0, 1
beq $t0, $t8, add_40
li $t0, 2
beq $t0, $t8, add_100
li $t0, 3
beq $t0, $t8, add_300
li $t0, 4
beq $t0, $t8, add_1200
beqz $t8, inc_sim_iteration

add_40:
addi $s6, $s6, 40
j inc_sim_iteration
add_100:
addi $s6, $s6, 100
j inc_sim_iteration
add_300:
addi $s6, $s6, 300
j inc_sim_iteration
add_1200:
addi $s6, $s6, 1200
j inc_sim_iteration

game_over_true:
li $s2, -1
inc_sim_iteration:
addi $s7, $s7, -1
bltz $s2, sim.done
bge $s5, $s3, sim.done
beqz $s7, sim.done
j sim_iteration

sim.done:
move $v0, $s5
move $v1, $s6
j end_simulate_game
error_simulate:
li $v0, 0
li $v1, 0
end_simulate_game:
lw $s0, 0($sp) #restore registers
lw $s1, 4($sp)
lw $s2, 8($sp)
lw $s3, 12($sp)
lw $s4, 16($sp)
lw $s5, 20($sp)
lw $s6, 24($sp)
lw $ra, 28($sp)
lw $s7, 32($sp)
addi $sp, $sp, 36
	jr $ra

#################### DO NOT CREATE A .data SECTION ####################
#################### DO NOT CREATE A .data SECTION ####################
#################### DO NOT CREATE A .data SECTION ####################
