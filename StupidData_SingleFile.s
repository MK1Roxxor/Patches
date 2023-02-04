;
; This creates an executable of Vision's "Stupid Data" demo that
; can be run from CLI/shell.


DESTINATION_ADDRESS	= $28000

START	bra.b	Go	

	dc.b	"Stupid Data/Vision single-filed version",10
	dc.b	"Done by StingRay/Scarab^Scoopex on 04-Feb-2023",10,0
	CNOP	0,2


Go	move.w	#$7fff,d0
.Wait_For_VBL
	btst	#0,$dff005
	beq.b	.Wait_For_VBL

	move.w	d0,$dff09c		; acknowledge all pending interrupts
	move.w	d0,$dff09a		; disable interrupts
	move.w	#$07ff,$dff096		; disable all DMA channels

	lea	Demo_Binary(pc),a0
	lea	DESTINATION_ADDRESS,a1
	move.l	#Demo_Size/2,d7
.copy	move.l	(a0)+,(a1)+
	subq.l	#1,d7
	bne.b	.copy

	; Remove call to Forbid(), demo will crash if this is not
	; removed.
	move.l	#$4e714e71,$28000+$33834


	jmp	DESTINATION_ADDRESS

Demo_Binary	incbin	ram:2
Demo_Size	= *-Demo_Binary
