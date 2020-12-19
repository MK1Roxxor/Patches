; Patch for "Retro Music" by Fanatic2k
; stingray, 18.12.2020

; Fixes memory allocation, DMA wait in replayer, interrupt problems
; (VBI, replayer), tunes are now played properly on 68060.
; To do: fix file loading for 1.x machines

START	move.l	$4.w,a6
	lea	DOSName(pc),a1
	moveq	#0,d0
	jsr	-552(a6)	; OpenLibrary()
	tst.l	d0
	beq.b	.error

	move.l	d0,a6
	pea	Name(pc)
	move.l	(a7)+,d1
	jsr	-150(a6)	; LoadSeg()
	tst.l	d0
	beq.b	.error

	lsl.l	#2,d0
	addq.w	#4,d0
	move.l	d0,a0

;.RMB	move.w	#$f00,$dff180
;	btst	#2,$dff016
;	bne.b	.RMB

	; patch titanics decruncher
	pea	PatchDecruncher(pc)
	move.w	#$4eb9,$230-$24(a0)
	move.l	(a7)+,$230-$24+2(a0)

	; run demo
	jmp	(a0)



.error	moveq	#10,d0
	rts



PatchDecruncher
	add.l	a4,a4
	add.l	a4,a4
	addq.w	#4,a4


	; patch demo code (a4 must remain untrashed!)
	movem.l	d0-a6,-(a7)


	lea	Base(pc),a0
	move.l	a4,(a0)

	lea	.TAB(pc),a0
	moveq	#0,d7
.patch	movem.l	(a0,d7.w),d0/d1/d2
	tst.l	d0
	beq.b	.done

	tst.l	d1
	beq.b	.opcode_only

	pea	(a0,d1.l)
	move.w	d2,(a4,d0.l)
	move.l	(a7)+,2(a4,d0.l)
	bra.b	.next

.opcode_only
	move.w	d2,(a4,d0.l)
	



.next	add.w	#3*4,d7

	bra.b	.patch

.done

	; allocate memory for largest module
	move.l	#160000,d0
	moveq	#2,d1
	jsr	-198(a6)
	tst.l	d0
	beq.b	.noMem

	move.l	d0,$472+2(a4)
	move.l	d0,$546+2(a4)
	move.l	d0,$25fe+2(a4)
.noMem

	movem.l	(a7)+,d0-a6
	rts


.TAB	dc.l	$9f6,.AckVBI-.TAB,$4ef9
	dc.l	$4b8,0,$6000+$4c0-$4b8-2

	dc.l	$1752,.FixDMAWait-.TAB,$4eb9
	dc.l	$1752+6,0,$4e71
	dc.l	$1768,.FixDMAWait-.TAB,$4eb9
	dc.l	$1768+6,0,$4e71
	dc.l	$1e9c,.FixDMAWait-.TAB,$4eb9
	dc.l	$1e9c+6,0,$4e71
	dc.l	$1eb2,.FixDMAWait-.TAB,$4eb9
	dc.l	$1eb2+6,0,$4e71

	dc.l	$12d8,SetCIAInt-.TAB,$4ef9

	dc.l	0,0,0


.AckVBI	move.w	#$20,$dff09c
	move.w	#$20,$dff09c
	rte

.FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d0
.loop	move.b	$dff006,d1
	cmp.b	$dff006,d1
	beq.b	.loop
	dbf	d0,.loop
	movem.l	(a7)+,d0/d1
	rts


SetCIAInt
	lea	$dff000,a6
	lea	$bfd000,a0

	move.w	#$2000,d0
	move.w	d0,$9a(a6)
	move.w	d0,$9c(a6)
	

	move.b	#$7f,$d00(a0)
	move.b	#$10,$e00(a0)
	move.b	#$10,$f00(a0)
	move.b	#$82,$d00(a0)


	move.l	#1773447,d0 		; PAL


	move.l	Base(pc),a1
	move.l	d0,$144e(a1)

	divu.w	#125,d0
	move.b	d0,$400(a0)
	lsr.w	#8,d0
	move.b	d0,$500(a0)
	

	lea	NewLev6(pc),a1
	move.l	a1,$78.w

	move.b	#$83,$d00(a0)
	move.b	#$11,$e00(a0)
	move	#$e000,$9a(a6)
	rts	


NewLev6	movem.l	d0-a6,-(a7)

	tst.b	$bfdd00

	move.l	Base(pc),a0
	jsr	$1510(a0)
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c

	movem.l	(a7)+,d0-a6
	rte


Base	dc.l	0

DOSName	dc.b	"dos.library",0
Name	dc.b	"intro",0
