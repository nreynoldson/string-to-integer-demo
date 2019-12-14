TITLE Program06A     (Program06A.asm)

; Author: Nicole Reynoldson
; Last Modified: 12/2/19
; OSU email address: reynolni@oregonstate.edu
; Course number/section: CS_271_400_F2019
; Project Number: 6A           Due Date: 12/8/19
; Description: This is a test program that demonstrates the functionality of two low-level I/O procedures.
;			   The test program itself will accept integers from the user, store them in an array, display 
;			   the list, the sum and the average. The readVal procedure converts the user input from a string
;			   of characters to an integer value while the writeVal procedure does the opposite. Only signed
;			   or unsigned integer values are accepted.



INCLUDE Irvine32.inc

SIZE_LIMIT = 32	; Maximum number of characters allowed for string input
MAX_NUMS = 10		; Max number of characters accepted as input
MAX = 57			; ASCII value for the number 9
MIN = 48			; ASCII value for the number 0
SIGN = 45			; ASCII value for the '-' sign

;------------------------------------------------------------------------------
; getString MACRO
; Description: Gets and stores a string from the user using Irvines ReadString
;			   procedure
; Recieves: address of a string buffer for writing to, address of a memory
;			location to hold the number of characters entered by the user
;------------------------------------------------------------------------------
getString		MACRO	bufferLoc, sizeLoc
	pushad
	mov		ecx, SIZE_LIMIT
	mov		edx, bufferLoc
	call	readString
	mov		esi, sizeLoc
	mov		[esi], eax
	popad
ENDM


;------------------------------------------------------------------------------
; displayString MACRO
; Description: Prints a string of characters to the screen using Irvines 
;			   writeString procedure.
; Recieves: address of a string variable to display
;------------------------------------------------------------------------------
displayString		MACRO	bufferAddr
	push	edx
	mov		edx, bufferAddr
	call	writeString
	pop		edx
ENDM


.data
programTitle		BYTE		"Program 6A: Low-level I/O Procedures", 0
programmerName		BYTE		10, "Written by: Nicole Reynoldson", 10, 0
extraCredit			BYTE		10, "**EC 1: Displays the line numbers and a running total of user numbers."
					BYTE		10, "**EC 2: Program handles signed integer input.", 0
dashedLines			BYTE		10, 80 DUP("-"), 0
instructions		BYTE		10, "This program will take integer values from the user, display the list of numbers"
					BYTE		10, "with the sum and average. Each value must be small enough to fit inside a 32 bit"
					BYTE		10, "register. Please provide 10 integer values.", 10, 0

intPrompt			BYTE		"Integer value: ", 0
numArray			SDWORD		MAX_NUMS DUP(?)
arraysize			DWORD		MAX_NUMS

errorMsg			BYTE		"ERROR: Integer not entered or value too large. Try again.", 0
valDisplayMsg		BYTE		10, "You entered the following values: ", 0

comma				BYTE		", ", 0
bracket				BYTE		") ", 0

sumMsg				BYTE		10, "The sum of values entered: ", 0
averageMsg			BYTE		10, "Rounded average of values entered: ", 0
exitMsg				BYTE		10, 10, "Thank you. Now exiting program." , 0
totalMsg			BYTE		"    Running total: ", 0


.code
main proc
	call	introduction

	push	OFFSET numArray
	push	arraySize
	call	fillArray

	push	OFFSET numArray
	push	arraySize
	call	displayArray

	push	OFFSET numArray
	push	arraySize
	call	arrayCalculations

	call	goodBye

	exit
main ENDP

;------------------------------------------------------------------------------
; Introduction
; Description: Displays general program information and instructions
; Recieves: N/A
; Returns: N/A
; Preconditions: N/A
; Postconditions: Displays instructions, program title and programmer name to 
;				  the screen
; Registers changed: None
;------------------------------------------------------------------------------
introduction PROC

	displayString	OFFSET	programTitle
	displayString	OFFSET	programmerName
	displayString	OFFSET	extraCredit
	displayString	OFFSET	dashedLines
	displayString	OFFSET	instructions
	call	CrLF

	ret
introduction ENDP
		
;------------------------------------------------------------------------------
; readVal
; Description: Accepts a string of digits from the user and converts to a 
;			   32 bit integer value. Only signed values that fit within a 32bit
;			   register will be accepted.
; Recieves: the address of the memory location where the converted integer is to
;			be stored
; Returns: an integer value to the address pushed on the stack as a parameter
;		   ZF is set if an integer has been stored. ZF clear if the input was
;		   not valid.
; Preconditions: N/A
; Postconditions: Prompt is displayed to the screen, error message displayed if
;				  input is not valid.
; Registers changed: None
;------------------------------------------------------------------------------
readVal PROC
	push	ebp
	mov		ebp, esp

	pushad

	; Create space for a string buffer to accept user input
	sub		esp, 36

	; EDI used to hold the effective address for string size
	; ESI used to hold effective address for string
	lea		edi, [ebp - 36]
	lea		esi, [ebp - 68]

	; Prompt user for an integer
	displayString	OFFSET intPrompt

	; Get a string and store in buffer parameter
	getString		esi, edi

	; Initialize count to number of characters
	mov		ecx, [edi]

	; Use edx to keep track of the front of the string for determining signed/unsigned
	mov		edx, esi

	; Point ESI to the end of the user string
	add		esi, ecx
	dec		esi

	; If the first character of the string is '-' then negative value has been entered
	; decrement ecx to only process characters that come after the sign
	mov		al, [edx]
	cmp		al, SIGN
	jne		positive1
	dec		ecx

positive1:
	; ebx holds count for correct place value
	; edi holds the running sum for converted integer
	mov		ebx, 1
	mov		edi, 0

	push	edx
	std

stringLoop:
	mov		eax, 0
	lodsb
	
	; Reject any strings when an alphabetic character is found
	push	eax
	call	validate
	jnz		error2

	; Convert from ASCII value to decimal, multiply by correct place value,
	; add to total integer value
	sub		al, MIN
	mul		ebx
	cmp		edx, 0
	jnz		error2

	add		edi, eax
	jo		error2
	jc		error2
	

	; Increment the next place value (by multiple of 10)
	mov		eax, ebx
	mov		ebx, 10
	mul		ebx
	jc		error2
	mov		ebx, eax

	loop	stringLoop

	pop		edx

	; If the input is a negative value, find the two's complement
	mov		al, [edx]
	cmp		al, SIGN
	jne		positive2

	mov		eax, -1
	sub		eax, edi
	add		eax, 1
	jmp		negativeRead


positive2:
	; Return the integer to memory referenced
	mov		eax, edi
negativeRead:
	mov		esi, [ebp + 8]
	mov		[esi], eax

	; Set zero flag if an integer has been successfully stored
	test	eax, 0
	jmp		endReadVal

error2:
	pop		edx
;error1:
	displayString	OFFSET errorMsg
	call	CrLF
	; Clear the zero flag if the integer is not valid
	or		eax, 1
	
endReadVal:
	; Save flags so that correct ZF can be returned from procedure
	lahf
	add		esp, 36
	sahf
	
	popad
	pop		ebp
	ret		4
readVal ENDP

;------------------------------------------------------------------------------
; validate
; Description: Changes the ZF depending on whether an integer is within the 
;			   specified 
; Recieves: an integer by value on the stack
; Returns: no values, sets or clears ZF
; Preconditions: MIN and MAX global constants set prior, value must not exceed
;				 32 bits register.
; Postconditions: ZF set if integer is valid, ZF cleared if integer is invalid
; Registers changed: None
;------------------------------------------------------------------------------
validate PROC
	push	ebp
	mov		ebp, esp
	push	eax

	mov		eax, [ebp + 8]

	; Check that value is below upper range
	cmp		eax, MAX
	jg		notValid

	cmp		eax, MIN
	jl		notValid
	
	; set zero flag if the integer is valid, EAX unchanged
	test	eax, 0
	jmp		endValidate

notValid:
	; Clear the zero flag if the integer is not valid
	or		eax, 1
endValidate:
	pop		eax
	pop		ebp

	ret		4
validate ENDP

;------------------------------------------------------------------------------
; writeVal
; Description: Converts an integer value to a string of integers for output and
;			   displays to the screen
; Recieves: the integer value to be converted to a string
; Returns: N/A
; Preconditions: Integer value must be 32 bits or less
; Postconditions: Value is displayed to the screen as a string
; Registers changed: None
;------------------------------------------------------------------------------
writeVal PROC
	push	ebp
	mov		ebp, esp
	
	; Make space for converted string buffer
	sub		esp, 32
	pushad

	
	; Isolate the leftmost bit of the integer to determine the sign
	mov		eax, [ebp + 8]
	mov		ebx, 10000000h
	mov		edx, 0
	div		ebx

	; If the value is negative, take the twos complement
	mov		ebx, 0Fh
	
	push	eax
	push	ebx
	cmp		eax, ebx
	jne		positiveWrite

	mov		ebx, [ebp + 8]
	mov		eax, 0FFFFFFFFh
	sub		eax, ebx
	add		eax, 1
	jmp		negative1

positiveWrite:
	; If positive, use the raw integer value
	mov		eax, [ebp + 8]
negative1:
	; Save the two's complement if calculated
	push	eax
	mov		ecx, 0
	mov		ebx, 10

	; Determine the digit count for the integer
findSize:
	mov		edx, 0
	div		ebx

	inc		ecx
	
	cmp		eax, 0
	jg		findSize


	; EDI points to the memory on the stack where the string will be placed
	lea		edi, [ebp - 4]

	mov		ebx, 10
	
	; Fill in the array from back to front, beginning with null character
	std
	mov		eax, 0
	stosb	

	pop			eax

writeLoop:
	; Get the rightmost digit by continually dividing by 10
	mov		edx, 0
	div		ebx

	; Convert to ASCII value and store in the string
	add		edx, MIN

	push	eax
	mov		al, dl
	stosb
	pop		eax

	cmp		eax, 0
	jg		writeLoop

	pop		ebx
	pop		eax

	; If the value is negative, add a negative sign to the string
	cmp		eax, ebx
	jne		positiveWrite2

	mov		al, SIGN
	stosb

	inc		ecx
positiveWrite2:
	; Get the address of the beginning of the string and display
	lea		edi, [ebp - 4]
	sub		edi, ecx
	displayString	edi

	popad
	add		esp, 32
	pop		ebp
	ret		4
writeVal ENDP

;------------------------------------------------------------------------------
; fillArray
; Description: Fills an array with 32bit integers input by the user. Displays
;			   the line number and a running total of the valid inputs.
; Recieves: The offset of the array and the arraysize by value
; Returns: Valid user input integers to the array referenced.
; Preconditions: N/A
; Postconditions: Fills the array with 32 bit integer values.
; Registers changed: None
;------------------------------------------------------------------------------
; ebp + 12 = array
; ebp + 8 = arraysize

fillArray	PROC
	push	ebp
	mov		ebp, esp
	push	eax
	push	edi
	push	ecx

	; EDI used to reference the array memory
	mov		edi, [ebp + 12]
	
	; ECX used to hold the line count
	; EAX used to contain the running total
	mov		ecx, 1
	mov		eax, 0

fillLoop:
	cmp		ecx, [ebp + 8]
	jg		endFill

	; Repeat a line when readVal returns that no integers have been stored
getValLoop:
	push	ecx
	call	writeVal

	displayString	OFFSET bracket

	push	edi
	call	readVal
	jnz		getValLoop

	; Update line count, running total and next array element
	inc		ecx
	add		eax, [edi]

	add		edi, 4

	displayString	OFFSET totalMsg
	push	eax
	call	WriteVal
	call	CrLF

	jmp		fillLoop

endFill:

	pop		ecx
	pop		edi
	pop		eax
	

	pop		ebp
	ret		8
fillArray	ENDP

;------------------------------------------------------------------------------
; displayArray
; Description: Displays the elements of an array passed in as arguments.
; Recieves: The offset of an array to display and the size of the array on the
;			stack.
; Returns: N/A
; Preconditions: N/A
; Postconditions: Displays a prompt before displaying the integers entered 
;				  each separated by a comma
; Registers changed: None
;------------------------------------------------------------------------------
; ebp + 12 = array
; ebp + 8 = arraysize
displayArray PROC
	push	ebp
	mov		ebp, esp
	push	ecx
	push	edi
	
	mov		ecx, [ebp + 8]
	mov		edi, [ebp + 12]

	displayString	OFFSET valDisplayMsg

displayLoop:
	 push	[edi]
	 call	WriteVal

	 ; If last element of the array, don't follow by a comma
	 cmp	ecx, 1
	 je		noComma

	 displayString	OFFSET comma

noComma:
	 add	edi, 4
	 loop	displayLoop

	pop		edi
	pop		ecx

	pop		ebp
	ret		8
displayArray ENDP

;------------------------------------------------------------------------------
; arrayCalculations
; Description: Calculates the sum and the average of an array of 32 bit integers
;			   and displays the values to the screen
; Recieves: The offset of an array of integers and the size of the array on the
;			stack.
; Returns: N/A
; Preconditions: Array must be filled prior to calling, values must be 32 bit
;				 integers or less.
; Postconditions: Displays the sum and rounded average to the screen.
; Registers changed: None
;------------------------------------------------------------------------------
; ebp + 12 = array
; ebp + 8 = arraysize
arrayCalculations PROC
	push	ebp
	mov		ebp, esp
	pushad

	; ECX holds the arraysize and is used as loop counter
	; EDI points to the array, EAX acts as sum accumulator
	mov		ecx, [ebp + 8]
	mov		edi, [ebp + 12]

	mov		eax, 0

sumLoop:
	 mov	ebx, [edi]
	 add	eax, ebx

	 add	edi, 4
	 loop	sumLoop

	displayString	OFFSET sumMsg
	push	eax
	call	WriteVal
	
	; Calculate the average
	mov		ebx, [ebp + 8]
	cdq
	idiv		ebx

	displayString	OFFSET averageMsg
	push	eax
	call	WriteVal

	popad
	pop		ebp
	ret		8
arrayCalculations ENDP

;------------------------------------------------------------------------------
; goodBye
; Description: Displays a farewell message to the user at program exit
; Recieves: N/A
; Returns: N/A
; Preconditions: N/A
; Postconditions: Farewell message displayed to screen
; Registers changed: None
;------------------------------------------------------------------------------
goodbye PROC
	displayString	OFFSET exitMsg
	call	CrLF
	ret
goodbye ENDP

END main
