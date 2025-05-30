/*
 * Function: float32_multi
 * ------------------------
 * Performs multiplication of two 32-bit IEEE-754 floating-point numbers
 * passed in R0 and R1, and returns the result in R0.
 *
 * Parameters:
 *   R0 - First operand (float32 in IEEE-754 format)
 *   R1 - Second operand (float32 in IEEE-754 format)
 *
 * Returns:
 *   R0 - Result of multiplication (float in IEEE-754 format)
 *
 * Clobbers:
 *   R2, R3, R4, R5, R6 (used as temporary registers)
 */
.syntax unified
.thumb

.global float32_multi
float32_multi:
	// R0 - OP1, R1 - OP2
	MOV R4, #0
	MOV R6, LR
	ADR LR, second_case


	// SIGN DETECTION
	AND R2, R0, #0x80000000 // CLEARING 0TH - 30TH BIT IN OP1
	AND R3, R1, #0x80000000 // CLEARING 0TH - 30TH BIT IN OP2
	EOR R5, R2, R3 // SAVING A RESULT SIGN BIT INTO THE R5
	// R0 - OP1, R1 - OP2, R5 - SIGN VALUE

	// NaN DETECION
	LSL R2, R0, #1 // DELETING A SIGN BIT FROM OP1
	CMP R2, #0xFF800000 // COMPARING TO INF SHIFTED BY ONE TO THE LEFT
	IT EQ // IF EQUAL
	BEQ end // GO TO "end" SECTION
	LSL R2, R1, #1 // DELETING A SIGN BIT FORM OP2
	CMP R2, #0xFF800000 // COMPARING TO INF SHIFTED BY ONE TO THE LEFT
	ITT EQ // IF EQUAL
	MOVEQ R0, R1 // PUT R1 INSIDE THE R0
	BEQ end // GO TO "end" SECTION

	// INF OR 0 DETECTION
	MOV R2, R0 // PUT ARG1 OF detection FUNCTION INTO R2
	MOV R3, R1 // PUT ARG2 OF detection FUNCTION INTO R3
	detection:
	AND R2, R2, #0x7F800000 // CLEARING ALL BITS EXCEPT AN EXPONENT
	CMP R2, #0x7F800000 // COMPARING EXP1 WITH 255
	ITTT EQ // IF EXP = 255
	LDREQ R4, =0xFFC00000
	MOVEQ R0, #0x7F800000
	ADREQ LR, end
	LSL R3, R3, #1 // DELETING A SIGN BIT
	CMP R3, #0 // COMPARING TO 0
	ITT EQ // IF OPERAND = 0
	MOVEQ R0, R4 // PUT INTO R0 0 OR NaN
	BEQ end // GO TO "end" SECTION
	MOV PC, LR // GO TO "second_case" OR "end" SECTION


	second_case:
	MOV R2, R1 // PUT ARG1 OF detection FUNCTION INTO R2
	MOV R3, R0 // PUT ARG2 OF detection FUNCTION INTO R3
	BL detection // GO TO "detection" FUNCTION

	// OPERATIONS WITH EXPONENTS
	AND R2, R0, #0x7F800000 // LOAD EXP1 INTO THE R3
	AND R3, R1, #0x7F800000 // LOAD EXP2 INTO THE R4
	SUB R2, R2, #0x3F800000 // SUBTRACTING 127
	ADD R2, R2, R3 // ADDING THE EXPONENTS ( 2^epx1 * 2^exp2 = 2^(exp1 + exp2)
	CMP R2, #0x7F800000 // COMPARING WITH MAX VALUE
	IT LO // IF EXP < 255
	BLO mantissa // GO TO "mantissa" SECTION
	CMP R3, #0x3F800000	// COMPARING EXP2 WITH 127
	ITT LO // IF EXP2 < 127 // BYŁO TU WCZESNIEJ MI
	MOVLO R0, #0 // A RESULT = 0
	BLO end // GO TO "end" SECTION
	MOV R0, #0x7F800000 // A RESULT = +/-INF
	B end // GO TO "end" SECTION
	// R0 - OP1, R1 - OP2, R2 - THE RESULT EXPONENT, R5 - SIGN VALUE

	// OPERATIONS WITH MANTISSAS
	mantissa:
	AND R0, R0, #0xFFFFFF // CLEAR ALL BITS EXCEPT MANTISSA 1
	AND R1, R1, #0xFFFFFF // CLEAR ALL BITS EXCEPT MANTISSA 2
	ORR R0, R0, #0x800000 // ADDING THE HIDDEN '1' TO THE MANTISSA 1
	ORR R1, R1, #0x800000 // ADDING THE HIDDEN '1' TO THE MANTISSA 2
	// R0 - MANTISSA 1, R1 - MANTISSA 2, R2 - THE EXPONENT, R5 - SIGN VALUE

	// MULTIPLICATION
	UMULL R1, R0, R0, R1 // MULTIPLICATION WITH A 64 BITS RESULT
	TST R0, #0x8000 // CHECKING IF 48TH BIT WAS SET
	BEQ no_carry // IF NO GO TO "false"  SECTION
	LSL R0, R0, #8 // ALIGN THE MOST SIGN BIT TO THE 23RD BIT
	ADDS R1, R1, #0x00800000 // ROUNDING A RESULT
	IT CS // IF CARRY FLAG OCCURED
	ADDCS R0, R0, #0x100 // ADD 1 TO 5TH BIT
	ADD R0, R0, R1, LSR #24 // CONNECT A LOWER AND A HIGHER PART OF A RESULT
	ADD R2, #0x800000 // INCREASE AN EXPONENT BY 1
	CMP R2, #0x7F800000 // COMPARING WITH MAX VALUE
	IT LT // IF EXP < 255
	BLT check_carry_again // GO TO "check_carry_again" SECTION
	MOV R0, #0x7F800000 // A RESULT = +/-INF
	B end // GO TO "end" SECTION

	no_carry:
	LSL R0, R0, #9 // ALIGN THE MOST SIGN BIT TO THE 23RD BIT
	ADDS R1, R1, #0x00400000 // ROUNDING A RESULT
	IT CS // IF CARRY FLAG OCCURED
	ADDCS R0, R0, #0x200 // ADD 1 TO 6TH BIT
	ADD R0, R0, R1 , LSR #23 // CONNECT A LOWER AND A HIGHER PART OF A RESULT
	// THE R0 - THE MANTISSA RESULT, R2 - THE EXPONENT, R5 - SIGN VALUE

	// CHECKING THE VALUE ON A 25TH BIT (AFTER ROUNDING)
	check_carry_again:
	TST R0, #0x1000000 // CHECKING 25TH BIT WAS SET
	BEQ connecting // IF WAS NOT SET GO TO THE "last" SECTION
	ADD R0, R0, #1 // ROUNDING A RESULT
	LSR R0, R0, #1 // SHIFTING A RESULT BY 1 TO THE RIGHT
	ADD R2, #0x800000 // INCREASE AN EXPONENT BY 1
	CMP R2, #0x7F800000 // COMPARING WITH MAX VALUE
	IT LT // IF EXP < 255
	BLT connecting // GO TO "check_carry_again" SECTION
	MOV R0, #0x7F800000 // A RESULT = +/-INF
	B end // GO TO "end" SECTION

	connecting:
	BIC R0, #0x00800000 // CLEARING THE "HIDDEN 1"
	ADD R0, R0, R2 // CONNECTING AN EXPONENT WITH A MANTISSA
	//.align 2
	end:
	ORR R0, R0, R5 // SETTING A SIGN BIT
	MOV PC, R6 //
