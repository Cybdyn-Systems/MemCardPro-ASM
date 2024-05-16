;=======================================================================================
; ASMPSX (SDevTC) Version 2.57
; Copyright (C) 1988-1997 S.N. Systems Software Limited.
;---------------------------------------------------------------------------------------
; Copyright (C) 2021-2024 Cybdyn Systems. All Rights Reserved.
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
; http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
;=======================================================================================

	; link this in the 'text' section
	section .text
	
	; assembler options can be found by typing "ASMPSX" into a command prompt
	; w+ = print warnings
	; l. = make '.' the local label character (+ or - not required)
	; c+ = case sensitivity
	opt w+,l.,c+
	
	; function prototypes
	global MemCardPro_Ping
	global MemCardPro_SendGameID
	global MemCardPro_PrevCH
	global MemCardPro_NextCH
	global MemCardPro_PrevDIR	; TODO (DOESN'T WORK ON THE MEMCARD PRO FIRMWARE YET)
	global MemCardPro_NextDIR	; TODO (DOESN'T WORK ON THE MEMCARD PRO FIRMWARE YET)
	global MemCardPro_Wait
	global MemCardPro_Exchng


; VARIABLES
JOY_DELAY_COUNTER equ 170		; 170 * 3 instructions = 510 cycles


; arguments:
;	a0 (port number)
;
; return values:
;	0 = no error (MemCard Pro detected)
;	1 = bus select fail (no memory card device detected)
;	2 = ping fail (no response from the MemCard Pro)
;	3 = reserve fail (reserved for future use (ignore this))
;	4 = card present fail (no card is present)
;	5 = termination signal fail (no termination signal detected)
MemCardPro_Ping:
	addiu	sp, -4
	sw		ra, 0(sp)

	lui		t0, IOBASE
	
	li		v0, 0x1003					; TX Enable, joypad port select
	andi	a0, 1
	sll		a0, 13
	or		v0, a0						; Select port 2 if a0 is 1
	
	sh		v0, JOY_CTRL(t0)			; Set to Joypad control interface
	
	jal		MemCardPro_Wait				; Delay for analog pads (needs to be tested)
	li		t1, JOY_DELAY_COUNTER
.Lread_empty_fifo_write:				; Flush the RX FIFO just in case
	lbu		v1, JOY_TXRX(t0)
	lhu		v0, JOY_STAT(t0)
	nop
	andi	v0, 0x2
	bnez	v0, .Lread_empty_fifo_write
	nop
	
	lhu		v1, JOY_CTRL(t0)
	nop
	or		v1, 0x10
	sh		v1, JOY_CTRL(t0)
	
	; BYTE 0 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send the 'bus select' byte
	li		a0, 0x81					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bne		v0, 0xFF, .Lerror 			; If we do not get 0xFF (255d) back, branch
	addiu	v0, r0, 1					; Return a value of 1 [DELAY SLOT]
	
	; BYTE 1 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send the 'ping command'
	li		a0, 0x20					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bnez	v0, .Lerror 				; If we do not get 0x00 back, branch
	addiu	v0, r0, 2					; Return a value of 2 [DELAY SLOT]
	
	; BYTE 2 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send 'reserved'
	li		a0, 0x00					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bnez	v0, .Lerror 				; If we do not get 0x00 back, branch
	addiu	v0, r0, 3					; Return a value of 3 [DELAY SLOT]
	
	; BYTE 3 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send 'reserved'
	li		a0, 0x00					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bnez	v0, .Lerror 				; If we do not get 0x00 back, branch
	addiu	v0, r0, 3					; Return a value of 3 [DELAY SLOT]
	
	; BYTE 4 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send 'card present'
	li		a0, 0x00					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bne		v0, 0x27, .Lerror 			; If we do not get 0x27 back, branch
	addiu	v0, r0, 4					; Return a value of 4 [DELAY SLOT]
	
	; BYTE 5 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send the 'termination signal'
	li		a0, 0x00					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bne		v0, 0xFF, .Lerror 			; If we do not get 0xFF back, branch
	addiu	v0, r0, 5					; Return a value of 5 [DELAY SLOT]
	; ------------------------------------------------------------------------
	
	addiu	v0, r0, 0					; No errors (return a value of 0)
.Lerror
	sb		r0, JOY_TXRX(t0)			; Get the end byte
	nop
	
	sh		r0, JOY_CTRL(t0)			; Apparently required

	lw		ra, 0(sp)
	addiu	sp, 4
	jr		ra
	nop


; arguments:
;	a0 (port number)
;	a1 (string length)
;	a2 (string data (251 bytes maximum))
;
; return values:
;	0 = no error (MemCard Pro detected)
;	1 = bus select fail (no memory card device detected)
;	2 = game ID command start (failed to send the game ID command)
;	3 = reserve fail (reserved for future use (ignore this))
;	4 = string length fail (failed to send the string length)
;	5 = data transmission fail (failed to get the previous byte)
MemCardPro_SendGameID:
	addiu	sp, -4
	sw		ra, 0(sp)

	lui		t0, IOBASE
	
	li		v0, 0x1003					; TX Enable, joypad port select
	andi	a0, 1
	sll		a0, 13
	or		v0, a0						; Select port 2 if a0 is 1
	
	sh		v0, JOY_CTRL(t0)			; Set to Joypad control interface
	
	jal		MemCardPro_Wait
	li		t1, JOY_DELAY_COUNTER
.Lread_empty_fifo_write:				; Flush the RX FIFO just in case
	lbu		v1, JOY_TXRX(t0)
	lhu		v0, JOY_STAT(t0)
	nop
	andi	v0, 0x2
	bnez	v0, .Lread_empty_fifo_write
	nop
	
	lhu		v1, JOY_CTRL(t0)
	nop
	or		v1, 0x10
	sh		v1, JOY_CTRL(t0)
	
	; BYTE 0 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send the 'bus select' byte
	li		a0, 0x81					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bne		v0, 0xFF, .Lerror 			; If we do not get 0xFF (255d) back, branch
	addiu	v0, r0, 1					; Return a value of 1 [DELAY SLOT]
	
	; BYTE 1 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send the 'game ID start command' byte
	li		a0, 0x21					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bnez	v0, .Lerror		 			; If we do not get 0x00 back, branch
	addiu	v0, r0, 2					; Return a value of 2 [DELAY SLOT]
	
	; BYTE 2 -----------------------------------------------------------------
	;jal		MemCardPro_Exchng			; Send 'reserved'
	;li		a0, 0x00					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	;bnez	v0, .Lerror		 			; If we do not get 0x00 back, branch
	;addiu	v0, r0, 3					; Return a value of 3 [DELAY SLOT]
	
	; BYTE 3 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send 'reserved'
	li		a0, 0x00					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bnez	v0, .Lerror		 			; If we do not get 0x00 back, branch
	addiu	v0, r0, 3					; Return a value of 3 [DELAY SLOT]
	
	; BYTE 4 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send the 'string length'
	move	a0, a1						; copy a1 to a0 [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bnez	v0, .Lerror		 			; If we do not get 0x00 back, branch
	addiu	v0, r0, 4					; Return a value of 4 [DELAY SLOT]
	
	; BYTE 5 -----------------------------------------------------------------
.strloop:
	lbu		a0, 0(a2)					; get the byte from the string
	jal		MemCardPro_Exchng			; send the 'string data' itself
	subiu	a1, 1						; decrement remaining bytes [DELAY SLOT]
	
	bnez	a1, .strloop				; repeat the loop until all the bytes are sent
	addiu	a2, 1						; advance the string address [DELAY SLOT]
	; ------------------------------------------------------------------------
	
	addiu	v0, r0, 0					; No errors (return a value of 0)
.Lerror
	sb		r0, JOY_TXRX(t0)			; Get the end byte
	nop
	
	sh		r0, JOY_CTRL(t0)			; Apparently required

	lw		ra, 0(sp)
	addiu	sp, 4
	jr		ra
	nop


; arguments:
;	a0 (port number)
;
; return values:
;	0 = no error (MemCard Pro detected)
;	1 = bus select fail (no memory card device detected)
;	2 = previous channel (failed to select the previous channel)
;	3 = reserve fail (reserved for future use (ignore this))
;	4 = success fail (device success flag check failed)
;	5 = termination signal fail (no termination signal detected)
MemCardPro_PrevCH:
	addiu	sp, -4
	sw		ra, 0(sp)

	lui		t0, IOBASE
	
	li		v0, 0x1003					; TX Enable, joypad port select
	andi	a0, 1
	sll		a0, 13
	or		v0, a0						; Select port 2 if a0 is 1
	
	sh		v0, JOY_CTRL(t0)			; Set to Joypad control interface
	
	jal		MemCardPro_Wait
	li		t1, JOY_DELAY_COUNTER
.Lread_empty_fifo_write:				; Flush the RX FIFO just in case
	lbu		v1, JOY_TXRX(t0)
	lhu		v0, JOY_STAT(t0)
	nop
	andi	v0, 0x2
	bnez	v0, .Lread_empty_fifo_write
	nop
	
	lhu		v1, JOY_CTRL(t0)
	nop
	or		v1, 0x10
	sh		v1, JOY_CTRL(t0)
	
	; BYTE 0 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send the 'bus select' byte
	li		a0, 0x81					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bne		v0, 0xFF, .Lerror 			; If we do not get 0xFF (255d) back, branch
	addiu	v0, r0, 1					; Return a value of 1 [DELAY SLOT]
	
	; BYTE 1 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send the 'previous channel' byte
	li		a0, 0x22					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bne		v0, 0x00, .Lerror 			; If we do not get 0x00 back, branch
	addiu	v0, r0, 2					; Return a value of 2 [DELAY SLOT]
	
	; BYTE 2 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send 'reserved'
	li		a0, 0x00					; [DELAY SLOT]
	
	bnez	v0, .Lerror		 			; If we do not get 0x00 back, branch
	addiu	v0, r0, 3					; Return a value of 3 [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	;bne		v0, 0x00, .Lerror 			; If we do not get 0x00 back, branch
	;addiu	v0, r0, 3					; Return a value of 3 [DELAY SLOT]

	; BYTE 3 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send 'reserved'
	li		a0, 0x00					; [DELAY SLOT]
	
	bnez	v0, .Lerror		 			; If we do not get 0x00 back, branch
	addiu	v0, r0, 3					; Return a value of 3 [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	;bne		v0, 0x00, .Lerror 			; If we do not get 0x00 back, branch
	;addiu	v0, r0, 3					; Return a value of 3 [DELAY SLOT]
	
	; BYTE 4 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send the 'success' check
	li		a0, 0x00					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bne		v0, 0x20, .Lerror 			; If we do not get 0x27 back, branch
	addiu	v0, r0, 4					; Return a value of 4 [DELAY SLOT]
	
	; BYTE 5 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send the 'termination signal'
	li		a0, 0x00					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bne		v0, 0xFF, .Lerror 			; If we do not get 0xFF back, branch
	addiu	v0, r0, 5					; Return a value of 5 [DELAY SLOT]
	; ------------------------------------------------------------------------
	
	addiu	v0, r0, 0					; No errors (return a value of 0)
.Lerror
	sb		r0, JOY_TXRX(t0)			; Get the end byte
	nop
	
	sh		r0, JOY_CTRL(t0)			; Apparently required

	lw		ra, 0(sp)
	addiu	sp, 4
	jr		ra
	nop

	
; arguments:
;	a0 (port number)
;
; return values:
;	0 = no error (MemCard Pro detected)
;	1 = bus select fail (no memory card device detected)
;	2 = next channel (failed to select the next channel)
;	3 = reserve fail (reserved for future use (ignore this))
;	4 = success fail (device success flag check failed)
;	5 = termination signal fail (no termination signal detected)
MemCardPro_NextCH:
	addiu	sp, -4
	sw		ra, 0(sp)

	lui		t0, IOBASE
	
	li		v0, 0x1003					; TX Enable, joypad port select
	andi	a0, 1
	sll		a0, 13
	or		v0, a0						; Select port 2 if a0 is 1
	
	sh		v0, JOY_CTRL(t0)			; Set to Joypad control interface
	
	jal		MemCardPro_Wait
	li		t1, JOY_DELAY_COUNTER
.Lread_empty_fifo_write:				; Flush the RX FIFO just in case
	lbu		v1, JOY_TXRX(t0)
	lhu		v0, JOY_STAT(t0)
	nop
	andi	v0, 0x2
	bnez	v0, .Lread_empty_fifo_write
	nop
	
	lhu		v1, JOY_CTRL(t0)
	nop
	or		v1, 0x10
	sh		v1, JOY_CTRL(t0)
	
	; BYTE 0 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send the 'bus select' byte
	li		a0, 0x81					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bne		v0, 0xFF, .Lerror 			; If we do not get 0xFF (255d) back, branch
	addiu	v0, r0, 1					; Return a value of 1 [DELAY SLOT]
	
	; BYTE 1 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send the 'next channel' byte
	li		a0, 0x23					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bne		v0, 0x00, .Lerror 			; If we do not get 0x00 back, branch
	addiu	v0, r0, 2					; Return a value of 2 [DELAY SLOT]
	
	; BYTE 2 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send 'reserved'
	li		a0, 0x00					; [DELAY SLOT]
	
	bnez	v0, .Lerror		 			; If we do not get 0x00 back, branch
	addiu	v0, r0, 3					; Return a value of 3 [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	;bne		v0, 0x00, .Lerror 			; If we do not get 0x00 back, branch
	;addiu	v0, r0, 3					; Return a value of 3 [DELAY SLOT]

	; BYTE 3 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send 'reserved'
	li		a0, 0x00					; [DELAY SLOT]
	
	bnez	v0, .Lerror		 			; If we do not get 0x00 back, branch
	addiu	v0, r0, 3					; Return a value of 3 [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	;bne		v0, 0x00, .Lerror 			; If we do not get 0x00 back, branch
	;addiu	v0, r0, 3					; Return a value of 3 [DELAY SLOT]
	
	; BYTE 4 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send the 'success' check
	li		a0, 0x00					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bne		v0, 0x20, .Lerror 			; If we do not get 0x27 back, branch
	addiu	v0, r0, 4					; Return a value of 4 [DELAY SLOT]
	
	; BYTE 5 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send the 'termination signal'
	li		a0, 0x00					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		t1, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bne		v0, 0xFF, .Lerror 			; If we do not get 0xFF back, branch
	addiu	v0, r0, 5					; Return a value of 5 [DELAY SLOT]
	; ------------------------------------------------------------------------
	
	addiu	v0, r0, 0					; No errors (return a value of 0)
.Lerror
	sb		r0, JOY_TXRX(t0)			; Get the end byte
	nop
	
	sh		r0, JOY_CTRL(t0)			; Apparently required

	lw		ra, 0(sp)
	addiu	sp, 4
	jr		ra
	nop


; handler/processor
MemCardPro_Exchng:
	lui		t0, IOBASE
	
	sb		a0, JOY_TXRX(t0)
	nop
.Lsend_wait_exchg:
	lhu		v0, JOY_STAT(t0)
	nop
	andi	v0, 0x4 ; JOY_STAT value
	beqz	v0, .Lsend_wait_exchg
	nop
	
	lui		a0, 0xBFC0
	move	v1, r0 ; set v1 to zero
.Lwait_ack_exchg:
	bgt		v1, 4500, .Ltimeout ; ACK delay (4500 * 7 instructions = 31,500 cycles)
	nop
	lhu		v0, JOY_STAT(t0)
	lw		r0, 4(a0)
	lw		r0, 0(a0)
	andi	v0, 0x202
	bne		v0, 0x202, .Lwait_ack_exchg
	addiu	v1, 1
	
	b		.Ldone
	nop
.Ltimeout:
	lbu		v0, JOY_TXRX(t0)
	nop
	b		.Lexit_exchg
	;ori		v0, 0x100				; Add 0x100 (used as a timeout flag on bit 8 of the v0 register. we could use andi and mask it, but we'll just nop it)
	nop
.Ldone:
	lhu		v1, JOY_CTRL(t0)
	lbu		v0, JOY_TXRX(t0)
	or		v1, 0x10
	sh		v1, JOY_CTRL(t0)
.Lexit_exchg:
	jr		ra
	nop


; simple delay loop (each instruction adds 1 cycle so a wait of 150 in t1 results in 500 cycles)
MemCardPro_Wait:
    addiu   t1, -1
    bgtz    t1, MemCardPro_Wait
    nop
	
    jr      ra
    nop


; includes
	include	'REGS.ASM'
