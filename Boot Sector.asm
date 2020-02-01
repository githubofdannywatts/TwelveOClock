[BITS 16]
[ORG 0x0000]

JMP BootMain

OEMLabel							DB	"        "
BytesPerSector						DW	512
SectorsPerCluster					DB	1
BootSectors							DW	1
NumberOfFATs						DB	2
RootFolderEntries					DW	224
TotalSectors						DW	2880
MediaDescriptor						DB	0xF0
SectorsPerFAT						DW	9
SectorsPerTrack						DW	18
Heads								DW	2
HiddenSectors						DD	0
LargeSectors						DD	0
DriveNumber							DW	0
DriveSignature						DB	41
SerialNumber						DD	0x00000000
VolumeLabel							DB	"           "
FileSystem							DB	"FAT12   "

BootMain:
	CLI
	
	MOV AX, 0x07C0
	MOV DS, AX
	MOV ES, AX
	MOV FS, AX
	MOV GS, AX
	
	MOV AX, 0x0000
	MOV SS, AX
	MOV SP, 0x7BFF
	
	STI
	
	MOV SI, BootingMessage
	CALL WriteString
	
LoadRootFolder:
	CalclateRootFolderSize:
		MOV CX, 0x0000
		MOV DX, 0x0000
		
		MOV AX, 32
		MUL WORD [RootFolderEntries]
		DIV WORD [BytesPerSector]
		XCHG AX, CX
	
	CalculateRootFolderLocation:
		MOV AL, BYTE [NumberOfFATs]
		MUL WORD [SectorsPerFAT]
		ADD AX, WORD [BootSectors]
		MOV WORD [DataStart], ax
		ADD WORD [DataStart], cx
		
	MOV BX, Buffer
	CALL LoadSectors
	
FindKernelEntry:
	MOV CX, WORD [RootFolderEntries]
	MOV DI, Buffer
	NextEntry:
		PUSH CX
		MOV CX, 11
		MOV SI, KernelFilename
		PUSH DI
		REP CMPSB
		POP DI
		JE FoundKernel
		POP CX
		ADD DI, 32
		LOOP NextEntry
		JMP KernelDoesntExist
		
KernelDoesntExist:
	MOV SI, KernelDoesntExistMessage
	CALL WriteString
	
	JMP $
	
FoundKernel:
	MOV DX, WORD [DI + 26]
	MOV WORD [ClusterToLoad], DX
	
	MOV AX, 0x0000
	MOV AL, BYTE [NumberOfFATs]
	MUL WORD [SectorsPerFAT]
	MOV CX, AX
	
	MOV AX, WORD [BootSectors]
	
	MOV BX, Buffer
	CALL LoadSectors
	
	MOV AX, 0x0050
	MOV ES, AX
	MOV BX, 0x0000
	PUSH BX
	
LoadKernel:
	MOV AX, WORD [ClusterToLoad]
	POP BX
	CALL HTStoLBA
	MOV CX, 0x0000
	MOV CL, BYTE [SectorsPerCluster]
	CALL LoadSectors
	PUSH BX
	
CalculateNextClusterInKernel:
	MOV AX, WORD [ClusterToLoad]
	MOV CX, AX
	MOV DX, AX
	SHR DX, 1
	ADD CX, DX
	MOV BX, Buffer
	ADD BX, CX
	MOV DX, WORD [BX]
	TEST AX, 1
	JNZ OddCluster
	
EvenCluster:
	AND DX, 0x0FFF
	JMP DoneComputingNextCluster
	
OddCluster:
	SHR DX, 0x0004
	
DoneComputingNextCluster:
	MOV WORD [ClusterToLoad], DX
	CMP DX, 0x0FF0
	JB LoadKernel
	
DoneLoadingKernel:
	JMP 0x0050:0x0000
	
HTStoLBA:
	SUB AX, 2
	MOV CX, 0x0000
	MOV CL, BYTE [SectorsPerCluster]
	MUL CX
	ADD AX, WORD [DataStart]
	RET
	
LBAtoHTS:
	PUSHA
	
	MOV DX, 0x0000
	DIV WORD [SectorsPerTrack]
	INC DL
	MOV [Sector], DL
	MOV DX, 0x0000
	DIV WORD [Heads]
	
	MOV BYTE [Head], DL
	MOV BYTE [Track], AL
	
	POPA
	
	MOV DH, [Head]
	MOV CH, [Track]
	MOV CL, [Sector]
	
	RET
	
	Head							DB	0x00
	Track							DB	0x00
	Sector							DB	0x00
	
LoadSectors:
	LoadSectorsInitialization:
		PUSHA
	LoadSector:
		MOV DI, 5
		NextAttempt:
			PUSH AX
			PUSH BX
			PUSH CX
			CALL LBAtoHTS
			MOV AH, 0x02
			MOV AL, 1
			INT 0x13
			JNC LoadedSector
			MOV AX, 0x0000
			INT 0x13
			DEC DI
			POP CX
			POP BX
			POP AX
			JNZ NextAttempt
			
			MOV SI, CannotReadFromDiskMessage
			CALL WriteString
			
			JMP $
			
		LoadedSector:
			POP CX
			POP BX
			POP AX
			ADD BX, WORD [BytesPerSector]
			INC AX
			LOOP LoadSector
	POPA
	RET

WriteString:
	WriteStringInitialization:
		PUSHA
		MOV AH, 0x0E
	NextCharacter:
		LODSB
		CMP AL, 0x00
		JE DoneWriting
		INT 0x10
		JMP NextCharacter
	DoneWriting:
		POPA
		RET
	
BootingMessage						DB	10, 13, "The computer is starting, please wait.", 0x00
ClusterToLoad						DW	0x0000
DataStart							DW	0x0000
CannotReadFromDiskMessage			DB	"Cannot read from the disk!", 0x00
KernelDoesntExistMessage			DB	10, 13, 10, 13, "KERNEL.SYS doesn't exist!", 0x00
KernelFilename						DB	"KERNEL  SYS"

Padding		TIMES (510 - ($ - $$))	DB	0x00
BootSignature						DW	0xAA55

Buffer: