; Patch for "Retro Music" by Fanatic2k
; stingray, 18.12.2020

; Fixes memory allocation, DMA wait in replayer, interrupt problems
; (VBI, replayer), tunes are now played properly on 68060.
; To do: fix file loading for 1.x machines

; V2.0 (final, hopefully), 19.12.2020
; - tunes are now loaded properly on 1.x machines
; - lots of blitter waits added
; - MACROS used to make the code more readable

; V2.1, 20.12.2020
; - set tempo routine in the replayer didn't work correctly as it
; checked if CIA resource was openend, fixed.


START	bra.w	Go

	dc.b	"Retro City Music Disk/Fanatic2k fix by StingRay/[S]carab^Scoopex.",10
	dc.b	"V2.1, 20.12.2020",10
	dc.b	10
	dc.b	"Get the source from my GitHub: https://github.com/MK1Roxxor/Patches/blob/main/RetroCity_Patch.s",10
	dc.b	10,0
	CNOP	0,2


Go	move.l	$4.w,a6
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

	lea	TAB(pc),a0
	moveq	#0,d7
.patch	movem.w	(a0,d7.w),d0/d1/d2
	tst.l	d0
	bmi.b	.done

	tst.l	d1
	beq.b	.opcode_only

	pea	(a0,d1.l)
	move.w	d2,(a4,d0.l)
	move.l	(a7)+,2(a4,d0.l)
	bra.b	.next

.opcode_only
	move.w	d2,(a4,d0.l)
	



.next	add.w	#3*2,d7

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


	;move.w	#$c008,$dff09a


	bsr	SaveOSInterrupts

	lea	OSDMA(pc),a0
	move.w	$dff002,(a0)
	lea	OSINT(pc),a0
	move.w	$dff01c,(a0)
	lea	OSADK(pc),a0
	move.w	$dff010,(a0)


	movem.l	(a7)+,d0-a6
	rts


CMD_JMP	= $4ef9
CMD_JSR	= $4eb9
CMD_NOP	= $4e71
CMD_RTS	= $4e75


PATCH_JSR	MACRO
		dc.w	\1,\2-TAB,CMD_JSR
		ENDM

PATCH_JMP	MACRO
		dc.w	\1,\2-TAB,CMD_JMP
		ENDM

PATCH_RTS	MACRO
		dc.w	\1,0,CMD_RTS
		ENDM
		

PATCH_SKIP	MACRO
		dc.w	\1,0,$6000+(\2-\1)-2
		ENDM

PATCH_NOP	MACRO
		dc.w	\1,0,CMD_NOP
		ENDM
		



TAB	PATCH_JSR	$30,KillSys
	PATCH_JSR	$4c0,.EnableVBI
	PATCH_RTS	$9f6
	
	; don't modify VBI code
	PATCH_SKIP	$4b8,$4c0


	; disable drive access (motor off)
	PATCH_RTS	$261a


	; fix file loader to work on 1.x machines
	PATCH_JMP	$25c2,LoadFile


	; fix DMA waits in replayer
	PATCH_JSR	$1752,.FixDMAWait
	PATCH_NOP	$1752+6
	PATCH_JSR	$1768,.FixDMAWait
	PATCH_NOP	$1768+6
	PATCH_JSR	$1e9c,.FixDMAWait
	PATCH_NOP	$1e9c+6
	PATCH_JSR	$1eb2,.FixDMAWait
	PATCH_NOP	$1eb2+6

	; fix blitter waits
	PATCH_JSR	$ee,.wblit1
	PATCH_NOP	$ee+6
	PATCH_JSR	$12e,.wblit1
	PATCH_NOP	$12e+6
	PATCH_JSR	$1d4,.wblit1
	PATCH_NOP	$1d4+6

	PATCH_JSR	$7f8,.wblit2

	PATCH_JSR	$b9a,.wblit3
	PATCH_NOP	$b9a+6
	
	PATCH_JSR	$c76,.wblit4

	PATCH_JSR	$c96,.wblit5
	PATCH_NOP	$c96+6
	PATCH_JSR	$cda,.wblit5
	PATCH_NOP	$cda+6
	PATCH_JSR	$df6,.wblit5
	PATCH_NOP	$df6+6
	PATCH_JSR	$ec0,.wblit5
	PATCH_NOP	$ec0+6
	PATCH_JSR	$f86,.wblit5
	PATCH_NOP	$f86+6

	PATCH_JSR	$d32,.wblit6
	PATCH_SKIP	$d32+6,$d3c
	PATCH_JSR	$d96,.wblit6
	PATCH_SKIP	$d96+6,$da0

	PATCH_JSR	$e50,.wblit7
	PATCH_NOP	$e50+6
	PATCH_JSR	$f1a,.wblit7
	PATCH_NOP	$f1a+6

	; skip the CIA resource check in mt_SetTempo
	PATCH_SKIP	$13f4,$13fc

	dc.w	-1,0,0


.wblit1	bsr.b	.WaitBlit
	move.w	#$4c,$dff064
	rts

.wblit2	bsr.b	.WaitBlit
	move.w	#0,$dff064
	move.w	#0,$dff066
	rts

.wblit3	bsr.b	.WaitBlit
	move.w	#$14,$dff064
	rts

.wblit4	bsr.b	.WaitBlit
	move.l	a0,$dff050
	rts

.wblit5	bsr.b	.WaitBlit
	move.w	#0,$dff064
	rts

.wblit6	bsr.b	.WaitBlit
	move.l	#$ffffffff,$dff044
	rts

.wblit7	bsr.b	.WaitBlit
	move.w	#$76,$dff064
	rts

.WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts


.AckVBI	move.w	#$20,$dff09c
	move.w	#$20,$dff09c
	rte

.EnableVBI
	move.w	#$c020,$dff09a
	rts


.FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d0
.loop	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait
	dbf	d0,.loop
	movem.l	(a7)+,d0/d1
	rts


KillSys	movem.l	d0/a6,-(a7)
	lea	$dff000,a6			; base address
	move.w	#$7FFF,d0
	bsr	WaitRaster

	move.w	d0,$9A(a6)			; Disable Interrupts
	move.w	d0,$96(a6)			; Clear all DMA channels
	move.w	d0,$9C(a6)			; Clear all INT requests

	pea	NewVBI(pc)
	move.l	(a7)+,$6c.w

	bsr	SetCIAInt

	movem.l	(a7)+,d0/a6
	rts


OSDMA	dc.w	0
OSINT	dc.w	0
OSADK	dc.w	0

NewVBI	movem.l	d0-a6,-(a7)


	move.l	Base(pc),a0
	jsr	$78a(a0)

	movem.l	(a7)+,d0-a6
	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rte		


WaitRaster
.wait	btst	#0,$dff004+1
	beq.b	.wait
.wait2	btst	#0,$dff004+1
	bne.b	.wait2
	rts
	

LoadFile
	bsr	EnableOS

	move.l	$4.w,a6
	moveq	#0,d0
	lea	DOSName(pc),a1
	jsr	-408(a6)		; OpenLibrary()
	move.l	d0,d7
	beq.b	.noDOS


	; call original file loader
	move.l	Base(pc),a0
	jsr	$25d4(a0)


.noDOS	bsr	DisableOS
	rts



SaveOSInterrupts
	movem.l	a0/a1,-(a7)
	lea	$64.w,a0
	lea	OSInterrupts(pc),a1
	REPT	7
	move.l	(a0)+,(a1)+
	ENDR
	movem.l	(a7)+,a0/a1
	rts

RestoreOSInterrupts
	movem.l	a0/a1,-(a7)
	lea	$64.w,a1
	lea	OSInterrupts(pc),a0
	REPT	7
	move.l	(a0)+,(a1)+
	ENDR
	movem.l	(a7)+,a0/a1
	rts


SaveCurrentInterrupts
	movem.l	a0/a1,-(a7)
	lea	$64.w,a0
	lea	CurrentInterrupts(pc),a1
	REPT	7
	move.l	(a0)+,(a1)+
	ENDR
	movem.l	(a7)+,a0/a1
	rts

RestoreCurrentInterrupts
	movem.l	a0/a1,-(a7)
	lea	$64.w,a1
	lea	CurrentInterrupts(pc),a0
	REPT	7
	move.l	(a0)+,(a1)+
	ENDR
	movem.l	(a7)+,a0/a1
	rts

EnableOS
	bsr	SaveCurrentInterrupts
	bsr	RestoreOSInterrupts

	move.w	OSDMA(pc),d0
	or.w	#1<<15,d0
	move.w	d0,$dff096
	move.w	OSINT(pc),d0
	or.w	#1<<15|1<<14,d0
	move.w	d0,$dff09a
	move.w	OSADK(pc),d0
	or.w	#1<<15,d0
	move.w	d0,$dff09e

	rts

DisableOS
	bsr	RestoreCurrentInterrupts

	bsr	WaitRaster
	move.w	#$7fff,$dff09a
	move.w	#$7fff,$dff09c
	move.w	#$7fff,$dff096

	move.w	#$E020,$dff09a
	move.w	#$87c0,$dff096
	rts


OSInterrupts		ds.l	7
CurrentInterrupts	ds.l	7




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
