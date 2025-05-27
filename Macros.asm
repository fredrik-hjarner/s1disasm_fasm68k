; ---------------------------------------------------------------------------
; Align and pad
; input: length to align to, value to use as padding (default is 0)
; ---------------------------------------------------------------------------

macro	align a,_b
	; if (narg=1)
	match ,_b
	; dcb.b (a-($ % a))%a,0 ; TODO: Rely on `massage_epression` instead
	dcb.b (a-($ mod a)) mod a,0 ; TODO: Rely on `massage_epression` instead
	else
	; dcb.b (a-($ % a))%a,_b ; TODO: Rely on `massage_epression` instead
	dcb.b (a-($ mod a)) mod a,_b ; TODO: Rely on `massage_epression` instead
	; endc
	end match
	endm

; ---------------------------------------------------------------------------
; Set a VRAM address via the VDP control port.
; input: 16-bit VRAM address, control port (default is ($C00004).l)
; ---------------------------------------------------------------------------

macro	locVRAM loc,controlport
		; if (narg=1)
		match ,controlport
		move.l	#($40000000+((loc&$3FFF)<<16)+((loc&$C000)>>14)),(vdp_control_port).l
		else
		move.l	#($40000000+((loc&$3FFF)<<16)+((loc&$C000)>>14)),controlport
		; endc
		end match
		endm

; ---------------------------------------------------------------------------
; DMA copy data from 68K (ROM/RAM) to the VRAM
; input: source, length, destination
; ---------------------------------------------------------------------------

macro	writeVRAM source,length,destination
		lea	(vdp_control_port).l,a5
		move.l	#$94000000+(((length>>1)&$FF00)<<8)+$9300+((length>>1)&$FF),(a5)
		move.l	#$96000000+(((source>>1)&$FF00)<<8)+$9500+((source>>1)&$FF),(a5)
		move.w	#$9700+((((source>>1)&$FF0000)>>16)&$7F),(a5)
		move.w	#$4000+(destination&$3FFF),(a5)
		move.w	#$80+((destination&$C000)>>14),(v_vdp_buffer2).w
		move.w	(v_vdp_buffer2).w,(a5)
		endm

; ---------------------------------------------------------------------------
; DMA copy data from 68K (ROM/RAM) to the CRAM
; input: source, length, destination
; ---------------------------------------------------------------------------

macro	writeCRAM source,length,destination
		lea	(vdp_control_port).l,a5
		move.l	#$94000000+(((length>>1)&$FF00)<<8)+$9300+((length>>1)&$FF),(a5)
		move.l	#$96000000+(((source>>1)&$FF00)<<8)+$9500+((source>>1)&$FF),(a5)
		move.w	#$9700+((((source>>1)&$FF0000)>>16)&$7F),(a5)
		move.w	#$C000+(destination&$3FFF),(a5)
		move.w	#$80+((destination&$C000)>>14),(v_vdp_buffer2).w
		move.w	(v_vdp_buffer2).w,(a5)
		endm

; ---------------------------------------------------------------------------
; DMA fill VRAM with a value
; input: value, length, destination
; ---------------------------------------------------------------------------

macro	fillVRAM value,length,loc
		lea	(vdp_control_port).l,a5
		move.w	#$8F01,(a5)
		move.l	#$94000000+((length&$FF00)<<8)+$9300+(length&$FF),(a5)
		move.w	#$9780,(a5)
		move.l	#$40000080+((loc&$3FFF)<<16)+((loc&$C000)>>14),(a5)
		move.w	#value,(vdp_data_port).l
		endm

; ---------------------------------------------------------------------------
; Copy a tilemap from 68K (ROM/RAM) to the VRAM without using DMA
; input: source, destination, width [cells], height [cells]
; ---------------------------------------------------------------------------

macro	copyTilemap source,destination,width,height
		lea	(source).l,a1
		locVRAM	destination,d0
		moveq	#width,d1
		moveq	#height,d2
		bsr.w	TilemapToVRAM
		endm

; ---------------------------------------------------------------------------
; stop the Z80
; ---------------------------------------------------------------------------

macro	stopZ80
		move.w	#$100,(z80_bus_request).l
		endm

; ---------------------------------------------------------------------------
; wait for Z80 to stop
; ---------------------------------------------------------------------------

macro	waitZ80
	.wait:	btst	#0,(z80_bus_request).l
		bne.s	.wait
		endm

; ---------------------------------------------------------------------------
; reset the Z80
; ---------------------------------------------------------------------------

macro	resetZ80
		move.w	#$100,(z80_reset).l
		endm

macro	resetZ80a
		move.w	#0,(z80_reset).l
		endm

; ---------------------------------------------------------------------------
; start the Z80
; ---------------------------------------------------------------------------

macro	startZ80
		move.w	#0,(z80_bus_request).l
		endm

; ---------------------------------------------------------------------------
; disable interrupts
; ---------------------------------------------------------------------------

macro	disable_ints
		move	#$2700,sr
		endm

; ---------------------------------------------------------------------------
; enable interrupts
; ---------------------------------------------------------------------------

macro	enable_ints
		move	#$2300,sr
		endm

; ---------------------------------------------------------------------------
; long conditional jumps
; ---------------------------------------------------------------------------

macro		jhi loc
		bls.s	.nojump
		jmp	loc
	.nojump:
		endm

macro		jcc loc
		bcs.s	.nojump
		jmp	loc
	.nojump:
		endm

macro		jhs loc
		jcc	loc
		endm

macro		jls loc
		bhi.s	.nojump
		jmp	loc
	.nojump:
		endm

macro		jcs loc
		bcc.s	.nojump
		jmp	loc
	.nojump:
		endm

macro		jlo loc
		jcs	loc
		endm

macro		jeq loc
		bne.s	.nojump
		jmp	loc
	.nojump:
		endm

macro		jne loc
		beq.s	.nojump
		jmp	loc
	.nojump:
		endm

macro		jgt loc
		ble.s	.nojump
		jmp	loc
	.nojump:
		endm

macro		jge loc
		blt.s	.nojump
		jmp	loc
	.nojump:
		endm

macro		jle loc
		bgt.s	.nojump
		jmp	loc
	.nojump:
		endm

macro		jlt loc
		bge.s	.nojump
		jmp	loc
	.nojump:
		endm

macro		jpl loc
		bmi.s	.nojump
		jmp	loc
	.nojump:
		endm

macro		jmi loc
		bpl.s	.nojump
		jmp	loc
	.nojump:
		endm

; ---------------------------------------------------------------------------
; check if object moves out of range
; input: location to jump to if out of range, x-axis pos (obX(a0) by default)
; ---------------------------------------------------------------------------

macro	out_of_range.w exit,pos
		local tmp
		; if (narg=2)
		match tmp, pos
		move.w	pos,d0		; get object position (if specified as not obX)
		else
		move.w	obX(a0),d0	; get object position
		; endc
		end match
		andi.w	#$FF80,d0	; round down to nearest $80
		move.w	(v_screenposx).w,d1 ; get screen position
		subi.w	#128,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0		; approx distance between object and screen
		cmpi.w	#128+320+192,d0
		; bhi.\0	exit
		bhi.w	exit
		endm

macro	out_of_range.s exit,pos
		local tmp
		; if (narg=2)
		match tmp, pos
		move.w	pos,d0		; get object position (if specified as not obX)
		else
		move.w	obX(a0),d0	; get object position
		; endc
		end match
		andi.w	#$FF80,d0	; round down to nearest $80
		move.w	(v_screenposx).w,d1 ; get screen position
		subi.w	#128,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0		; approx distance between object and screen
		cmpi.w	#128+320+192,d0
		; bhi.\0	exit
		bhi.s	exit
		endm

; ---------------------------------------------------------------------------
; bankswitch between SRAM and ROM
; (remember to enable SRAM in the header first!)
; ---------------------------------------------------------------------------

macro	gotoSRAM
		move.b	#1,($A130F1).l
		endm

macro	gotoROM
		move.b	#0,($A130F1).l
		endm

; ---------------------------------------------------------------------------
; compare the size of an index with ZoneCount constant
; (should be used immediately after the index)
; input: index address, element size
; ---------------------------------------------------------------------------

macro	zonewarning loc,elementsize
	.end:
		if (.end-loc)-(ZoneCount*elementsize)<>0
		inform 1,"Size of \loc ($%h) does not match ZoneCount ($\#ZoneCount).",(.end-loc)/elementsize
		endc
		endm
