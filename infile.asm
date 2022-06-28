;MAIN FILE TO BE COMPILED WITH NESASM3.EXE
;Notepad++: to compile in NESASM3 and run in FCEUX debugger, use Alt+Z
;Created by Eric Di Gioia - July 2020

	;iNES header (NROM-128)
	.inesprg 1   ; 1x 16KB bank of PRG code
	.ineschr 1   ; 1x 8KB bank of CHR data
	.inesmap 0   ; mapper 0 = NROM, no bank swapping
	.inesmir 1   ; background mirroring
	
;////////////////////////////////////////////////////

;{ NES HARDWARE REGISTER AND MEMORY DEFINITIONS

	;Registers (memory mapped to CPU)
PPUCTRL		.EQU	$2000
PPUMASK		.EQU	$2001
PPUSTATUS	.EQU	$2002
OAMADDR		.EQU	$2003
OAMDATA		.EQU	$2004
PPUSCROLL	.EQU	$2005
PPUADDR		.EQU	$2006
PPUDATA		.EQU	$2007
OAMDMA		.EQU	$4014

JOYPAD1		.EQU	$4016
JOYPAD2		.EQU	$4017

	;PPU Palette Index
PPU_palette	.EQU	$3F00	;Palette data inside PPU VRAM

	;Sprites
OAM			.EQU	$0200	;OAM data to be sent to PPU from RAM via DMA every vblank
SpriteY		.EQU	$0200
SpriteTile	.EQU	$0201
SpriteAttr	.EQU	$0202
SpriteX		.EQU	$0203

	;Background
Nametable0	.EQU	$2000	;PPU VRAM addresses for nametables
Nametable1	.EQU	$2400
Nametable2	.EQU	$2800
Nametable3	.EQU	$2C00
AttrTable0	.EQU	$23C0
AttrTable1	.EQU	$27C0
AttrTable2	.EQU	$2BC0
AttrTable3	.EQU	$2FC0

;}

;{ RAM VARIABLE DECLARATIONS
	.rsset $0000
buttons		.rs	1	;A B SEL STRT UP DWN LFT RGT
NamePtrLo	.rs 1	;Pointer to background data to assist loading into nametable
NamePtrHi	.rs 1
;}

;////////////////////////////////////////////////////

	;PRG-ROM bank (First 8K)
	.bank 0
	.org $C000
	
RESET:;{	;RESET VECTOR (called upon reset)
	
	Initializations:;{
		SEI			;Disable IRQs
		CLD			;Clear decimal mode (not available on NES)
		LDX #$40
		STX $4017	;Disable APU IRQ
		LDX #$FF
		TXS			;Initialize stack
		INX			; x = 0
		STX PPUCTRL	;disable NMI
		STX PPUMASK	;disable rendering
		STX $4010	;disable DMC IRQs
	;}
	
	vblankwait1:;{
		bit PPUSTATUS
		bpl vblankwait1
	;}

	clearmemory:;{
		sta $000,x ;zero-page
		sta $100,x ;stack
		sta $200,x ;OAM
		sta $300,x ;sound variables
		sta $400,x ;other memory (slower than zero-page)
		sta $500,x
		sta $600,x
		sta $700,x
		inx
		bne clearmemory
	;}

	vblankwait2:;{
		bit PPUSTATUS
		bpl vblankwait2
	;}
		
	LoadPaletteData:;{
		LDA PPUSTATUS	;read PPU status register to reset latch and be able to write to PPU address
		LDA #HIGH(PPU_palette)
		STA PPUADDR
		LDA #LOW(PPU_palette)
		STA PPUADDR
		LDX #$00
		LoadPaletteDataLoop:	;load palette data into VRAM palette indexes
			LDA PaletteData, x
			STA PPUDATA
			INX
			CPX #$20
			BNE LoadPaletteDataLoop
	;}
	
	LoadSpriteData:;{
		LDX #$00
		LoadSpriteDataLoop:
			LDA SpriteData, x
			STA OAM, x
			INX
			CPX #$10
			BNE LoadSpriteDataLoop
	;}
	
	LoadBackgroundData:;{
		LDA PPUSTATUS	;reset PPU address latch
		LDA #HIGH(Nametable0)
		STA PPUADDR
		LDA #LOW(Nametable0)
		STA PPUADDR
		
		LDA #LOW(BackgroundData) ;Assign background data pointer
		STA NamePtrLo
		LDA #HIGH(BackgroundData)
		STA NamePtrHi
		
		LDX #$04 ;4 cycles for full nametable (Nametable size = $400)
		LDY #$00
		LoadBackgroundDataLoop:
			LDA [NamePtrLo], y
			STA PPUDATA
			INY ; $00 - $FF
			BNE LoadBackgroundDataLoop
			INC NamePtrHi ;Add $0100 to address pointed to by NamePtr
			DEX
			BNE LoadBackgroundDataLoop
			
		LDA #HIGH(BackgroundData)
		STA NamePtrHi	;Reset NamePtr to beginning of background data
		
	;}
	
	LoadAttributeData:;{
		LDA PPUSTATUS	;reset PPU address latch
		LDA #HIGH(AttrTable0)
		STA PPUADDR
		LDA #LOW(AttrTable0)
		STA PPUADDR
		LDX #$00
		LoadAttributeDataLoop:
			LDA AttributeTableData, x
			STA PPUDATA
			INX
			CPX #$08
			BNE LoadAttributeDataLoop
	;}
	
	EnableNMIandSprites:;{
		LDA #%10010000
		STA PPUCTRL		;enable NMI, assign pattern table 0 to sprites, 1 to background
		LDA #%00011110
		STA PPUMASK		;enable sprites, background, hide clipping
	;}
	
;}



MAIN:;{		;MAIN LOOP (infinite game loop)
	Forever:
	JMP Forever
;}



NMI:;{		;NMI VECTOR (called every vblank)
	
	PushCPURegisters:;{
		PHA			;Push A to stack
		TXA
		PHA			;Push X to stack
		TYA
		PHA			;Push Y to stack
	;}
	
	TransferOAM:;{
		LDA #LOW(OAM)	;OAM RAM address low byte ($00)
		STA OAMADDR
		LDA #HIGH(OAM)	;OAM RAM address high byte ($02)
		STA OAMDMA	;begin DMA transfer of sprite OAM starting at address $0200 (CPU RAM to PPU VRAM)
	;}
	
	ReadController:;{
	
		;BIT		7	6	5		4		3	2		1		0
		;BUTTON		A	B	SELECT	START	UP	DOWN	LEFT	RIGHT
	
		LDA #$01	; A = 1
		STA JOYPAD1 ;poll buttons
		STA buttons ;"flag" to be shifted out to carry to break controller read loop
		LSR A		; A = 0
		STA JOYPAD1	;end poll, latch buttons
		ReadLoop:
			LDA JOYPAD1 	;Load button into A
			AND #%00000011	;Mask off D0 and D1
			CMP #$01		;set carry if button is pressed (Standard P1 or EXP controller)
			ROL buttons		;shift button bit in from carry
			BCC ReadLoop	;continue until initial bit flag is shifted out into carry
	;}

	Debug:;{	;TEMPORARY
	
		MoveCharacter:;{
			ReadUp:
				LDA buttons
				AND #%00001000
				BEQ ReadDown
					LDX	#$00
					MoveUpLoop:
					DEC SpriteY, x
					INX
					INX
					INX
					INX
					CPX #$10	;stop when all 4 sprites are moved
					BNE MoveUpLoop
			ReadDown:
				LDA buttons
				AND #%00000100
				BEQ ReadLeft
					LDX	#$00
					MoveDownLoop:
					INC SpriteY, x
					INX
					INX
					INX
					INX
					CPX #$10	;stop when all 4 sprites are moved
					BNE MoveDownLoop
			ReadLeft:
				LDA buttons
				AND #%00000010
				BEQ ReadRight
					LDX	#$00
					MoveLeftLoop:
					DEC SpriteX, x
					INX
					INX
					INX
					INX
					CPX #$10	;stop when all 4 sprites are moved
					BNE MoveLeftLoop
			ReadRight:
				LDA buttons
				AND #%00000001
				BEQ ReadDone
					LDX	#$00
					MoveRightLoop:
					INC SpriteX, x
					INX
					INX
					INX
					INX
					CPX #$10	;stop when all 4 sprites are moved
					BNE MoveRightLoop
			ReadDone:
		;}
		
	;}

	PPUcleanup:;{	;Needed?

	;}

	PullCPURegisters:;{
		PLA			;Pull Y from stack
		TAY
		PLA			;Pull X from stack
		TAX
		PLA			;Pull A from stack
		RTI
	;}
	
;}
	
;////////////////////////////////////////////////////

	;PRG-ROM bank (Second 8K)
	.bank 1
	.org $E000
	
PaletteData:
  .db $22,$29,$1A,$0F,  $22,$36,$17,$0F,  $22,$30,$21,$0F,  $22,$27,$17,$0F   ;;background palette
  .db $22,$1C,$15,$14,  $22,$02,$38,$3C,  $22,$1C,$15,$14,  $22,$02,$38,$3C   ;;sprite palette
  
SpriteData:
     ;vert tile attr horiz
  .db $80, $32, $00, $80   ;sprite 0
  .db $80, $33, $00, $88   ;sprite 1
  .db $88, $34, $00, $80   ;sprite 2
  .db $88, $35, $00, $88   ;sprite 3

BackgroundData:
  .incbin "CollisionTest.nam"
	
AttributeTableData:
  .db %00000000, %00010000, %0010000, %00010000, %00000000, %00000000, %00000000, %00110000
	
	.org $FFFA
	.dw NMI
	.dw RESET
	.dw 0


;////////////////////////////////////////////////////

	;CHR-ROM bank (8K)
	.bank 2
	.org $0000
	.incbin "mario.chr"
