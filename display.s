@display the value of switches on the 7-segment display
@check 'Show 32 switches' in the switches menù
@check 'Show 8 digits' in the seven-segment display menù
.arm
@devices
.equ switch, 0xff200040			@switches
.equ digits1, 0xff200020		@last four digits
.equ digits2, 0xff200030		@first four digits

@numbers codes, written in binary value
.equ zero, 0b00111111
.equ one, 0b00000110
.equ two, 0b01011011
.equ three, 0b01001111
.equ four, 0b01100110
.equ five, 0b01101101
.equ six, 0b01111101
.equ seven, 0b00000111
.equ eight, 0b01111111
.equ nine, 0b01101111
.equ hexa, 0b01110111
.equ hexb, 0b01111100
.equ hexc, 0b00111001
.equ hexd, 0b01011110
.equ hexe, 0b01111001
.equ hexf, 0b01110001

@datas
.bss
	store: .space 32 @8x4 byte
.data
	@pointer array
	numbers: .word zero, one, two, three, four, five, six, seven, eight, nine, hexa, hexb, hexc, hexd, hexe, hexf

@code section
.text
	.global _main
@registers usage:
@r0: value saved from switches
@r1: length of the switches memory section
@r2: counter
@r3: digit in position of the counter
@r4: output address
_main:
@set everything needed
	ldr r0, =switch		@load the switches address
	ldr r0, [r0]		@read the value
	mov r1, #28			@limit value	(32[max]-4[len of hex])
	mov r2, #0			@set counter to zero
	ldr r4, =store		@load the output address
_split:
@split in words
	mov r3, r0, lsr r2		@copy the value and shift to the right, get rid of right digits
	mov r3, r3, lsl r1		@shift to the left, get rid of left digits
	mov r3, r3, lsr r1		@shift to the right, easier for the display part
	str r3, [r4, r2]		@shift to desired registered
	add r2, #4				@move to the next cypher (4 bit shift)
	cmp r2, r1				@check if reached the last digit
	ble _split				@loop if false
	b _disp					@write all the cyphers

@registers usage:
@r0: stored value position
@r1: display offset
@r2: current value to print
@r3: return vector value
@r4: doubles the value of index (moves to the left the value in display)
@r6: save vector index to read
@r7: memory offset
@r8: status of the program (#0 store in first display, #1 store in second, #2 quit)
@r9: final output
@r10: display location
_disp:
@set everything needed
	ldr r0, =store		@load the address of the stored value
	ldr r10, =digits1	@load the first display
	mov r1, #0			@reset the index
	mov r9, #0			@reset the final output
	mov r8, #0			@reset the status
	mov r7, #0			@reset the memory offset
	ldr r6, =numbers	@load the vector address
_load:
@load the cyphers to display
	ldr r2, [r0, r7]			@read current digit and load
	ldr r3, [r6, r2, lsl #2]	@load the corresponding value
	mov r4, r1, lsl #1				@doubles the index
	add r9, r3, lsl r4			@sum the value to show
	mov r4, r1, lsr #1				@doubles the index
	add r1, #4					@shift the display index
	add r7, #4					@shift the memory index
	cmp r1, #0x10					@check if display is full, if true
	bne _load
	str r9, [r10]				@store and show the value
	ldr r10, =digits2 			@prepare second display
	mov r1, #0					@reset display offset
	add r8, #1					@increment the controller
	mov r9, #0					@reset the ouptput
	cmp r8, #2					@check status
	beq _end					@quit
	b _load						@else: loop