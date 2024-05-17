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
	global MemcardPro_SimpleCommand
	global MemcardPro_InterCommandDelay


; VARIABLES
JOY_DELAY_COUNTER equ 170		; 170 * 3 instructions = 510 cycles


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

	; Add 1 to the string length to include a trailing 0
	; without passing that burdern to the caller
	; i.e. allow the developer to pass strlen(gameid)
	; (MCPro still accepts the unterminated packet but this is cleaner)
	addiu	a1,	1

	lui		t0, IOBASE
	
	li		v0, 0x1003					; TX Enable, joypad port select
	andi	a0, 1
	sll		a0, 13
	or		v0, a0						; Select port 2 if a0 is 1
	
	sh		v0, JOY_CTRL(t0)			; Set to Joypad control interface
	
	jal		MemCardPro_Wait
	li		a0, JOY_DELAY_COUNTER
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
	;li		a0, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bne		v0, 0xFF, .Lerror 			; If we do not get 0xFF (255d) back, branch
	addiu	v0, r0, 1					; Return a value of 1 [DELAY SLOT]
	
	; BYTE 1 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send the 'game ID start command' byte
	li		a0, 0x21					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		a0, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	; This response may be 0x00 or 0x08 (MCPro and regular cards)
	; Depending on when you do the ping, so we can accept both

	beqz	v0,	.Lvalidresponse			; We got the 0x00 ping response
	nop

	subiu	v0,	0x08					; We got the 0x08 ping response
	beqz	v0,	.Lvalidresponse
	nop

	b		.Lerror 					; If we do not get 0x00 back, branch
	addiu	v0, r0, 2					; Return a value of 2 [DELAY SLOT]

.Lvalidresponse

	; BYTE 2 -----------------------------------------------------------------
	;jal		MemCardPro_Exchng			; Send 'reserved'
	;li		a0, 0x00					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		a0, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	;bnez	v0, .Lerror		 			; If we do not get 0x00 back, branch
	;addiu	v0, r0, 3					; Return a value of 3 [DELAY SLOT]
	
	; BYTE 3 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send 'reserved'
	li		a0, 0x00					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		a0, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bnez	v0, .Lerror		 			; If we do not get 0x00 back, branch
	addiu	v0, r0, 3					; Return a value of 3 [DELAY SLOT]
	
	; BYTE 4 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send the 'string length'
	move	a0, a1						; copy a1 to a0 [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		a0, JOY_DELAY_COUNTER
	
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



; a0 = port number
; a1 = 0x22, 0x23, 0x24, or 0x24 to increment or decrement channels.
; a2 = expected response (0x27 for ping, 0x20 for channel/dir switches) 
MemcardPro_SimpleCommand:

	addiu	sp, -4
	sw		ra, 0(sp)

	lui		t0, IOBASE
	
	li		v0, 0x1003					; TX Enable, joypad port select
	andi	a0, 1
	sll		a0, 13
	or		v0, a0						; Select port 2 if a0 is 1
	
	sh		v0, JOY_CTRL(t0)			; Set to Joypad control interface
	
	jal		MemCardPro_Wait
	li		a0, JOY_DELAY_COUNTER
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
	;li		a0, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bne		v0, 0xFF, .Lerror 			; If we do not get 0xFF (255d) back, branch
	addiu	v0, r0, 1					; Return a value of 1 [DELAY SLOT]
	
	; BYTE 1 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send the 'next channel' byte
	move	a0, a1						; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		a0, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	; This response may be 0x00 or 0x08 (MCPro and regular cards)
	; Depending on when you do the ping, so we can accept both

	beqz	v0,	.Lvalidresponse			; We got the 0x00 ping response
	nop

	subiu	v0,	0x08					; We got the 0x08 ping response
	beqz	v0,	.Lvalidresponse
	nop

	b		.Lerror 					; If we do not get 0x00 back, branch
	addiu	v0, r0, 2					; Return a value of 2 [DELAY SLOT]

.Lvalidresponse
	
	; BYTE 2 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send 'reserved'
	li		a0, 0x00					; [DELAY SLOT]
	
	bnez	v0, .Lerror		 			; If we do not get 0x00 back, branch
	addiu	v0, r0, 3					; Return a value of 3 [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		a0, JOY_DELAY_COUNTER
	
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
	;li		a0, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	;bne		v0, 0x00, .Lerror 			; If we do not get 0x00 back, branch
	;addiu	v0, r0, 3					; Return a value of 3 [DELAY SLOT]
	
	; BYTE 4 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send the 'success' check
	li		a0, 0x00					; [DELAY SLOT]
	
	;jal		MemCardPro_Wait
	;li		a0, JOY_DELAY_COUNTER
	
	; return the result now (debugging)
	;b		.Lerror
	;nop
	
	bne		v0,	a2, .Lerror 			; If we do not get 0x20/0x27 back, branch
	addiu	v0, r0, 4					; Return a value of 4 [DELAY SLOT]
	
	; BYTE 5 -----------------------------------------------------------------
	jal		MemCardPro_Exchng			; Send the 'termination signal'
	; Load 0x01 into the high word, since it's the last byte in the sequence
	lui		a0, 0x01					; [DELAY SLOT]
		
	;jal		MemCardPro_Wait
	;li		a0, JOY_DELAY_COUNTER
	
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
;	2 = ping fail (no response from the MemCard Pro)
;	3 = reserve fail (reserved for future use (ignore this))
;	4 = card present fail (no card is present)
;	5 = termination signal fail (no termination signal detected)
MemCardPro_Ping:
	
	addiu	sp, -4
	sw		ra, 0(sp)
	
	li		a2, 0x27
	jal		MemcardPro_SimpleCommand
	li 		a1,	0x20
	
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
	
	li		a2, 0x20
	jal		MemcardPro_SimpleCommand
	li 		a1,	0x23
	
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

	li		a2, 0x20
	jal		MemcardPro_SimpleCommand
	li 		a1,	0x22
	
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
;	2 = next channel (failed to select the next card)
;	3 = reserve fail (reserved for future use (ignore this))
;	4 = success fail (device success flag check failed)
;	5 = termination signal fail (no termination signal detected)
MemCardPro_NextDIR:

	addiu	sp, -4
	sw		ra, 0(sp)

	li		a2, 0x20
	jal		MemcardPro_SimpleCommand
	li 		a1,	0x25
	
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
;	2 = previous channel (failed to select the previous card)
;	3 = reserve fail (reserved for future use (ignore this))
;	4 = success fail (device success flag check failed)
;	5 = termination signal fail (no termination signal detected)
MemCardPro_PrevDIR:
	addiu	sp, -4
	sw		ra, 0(sp)

	li		a2, 0x20
	jal		MemcardPro_SimpleCommand
	li 		a1,	0x24
	
	lw		ra, 0(sp)
	addiu	sp, 4
	jr		ra
	nop



; handler/processor
; a0 = byte to send
; a0 & 0x000010000 == final byte in the sequnce, do not wait for /ACK
MemCardPro_Exchng:

	addiu	sp, -4
	sw		ra, 0(sp)
		
	; We don't need to /ACK the final byte in a sequence
	; so we can return early if this bit is set.
	lui		t0, 0x01
	li		t1,	0x00
	and		t0,	a0,	t0
	beqz	t0,	.Lno_final_byte
	nop

	; It's the last byte in the sequence, so
	; set t1 for an early return
	li		t1,0x01

.Lno_final_byte	

	lui		t0, IOBASE

	sb		a0, JOY_TXRX(t0)
	nop

.Lsend_wait_exchg:
	lhu		v0, JOY_STAT(t0)
	nop
	andi	v0, 0x2 ; JOY_STAT value
	beqz	v0, .Lsend_wait_exchg
	nop

	; We've got a byte waiting in the RX buffer
	; But it's the last in the sequence, so 
	; We don't need to wait for an /ACK
	bnez	t1, .Ldone
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

	; Add a standard delay to pad us out to about 18us
	; Not strictly necessary, but it's not a noticable delay
	; and falls roughly in line with other implementations
	
	jal MemCardPro_Wait
	li		a0,0x70

	lw		ra, 0(sp)
	nop		
	addiu	sp, 4
	jr		ra
	nop



; simple delay loop (each instruction adds 1 cycle so a wait of 150 in t1 results in 500 cycles)
; a0 = delay
MemCardPro_Wait:
    addiu   a0, -1
    bgtz    a0, MemCardPro_Wait
    nop
	
    jr      ra
    nop



; No params, will wait long enough to do a ping followed by a 
; SendGameID on the same frame
; (with a lot of wiggle room; 2.5ms in this case)
; Where possible, just wait a frame instead.
MemcardPro_InterCommandDelay:

	addiu	sp, -4
	sw		ra, 0(sp)
	
	li 		a0, 0x7000
	jal		MemCardPro_Wait

	lw		ra, 0(sp)
	nop		
	addiu	sp, 4
	jr		ra
	nop


; includes
	include	'REGS.ASM'
