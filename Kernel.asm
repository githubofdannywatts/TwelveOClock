[BITS 16]
[ORG 0x0000]

KernelMain:
	CLI
	
	MOV AX, 0x0050
	MOV DS, AX
	MOV ES, AX
	MOV FS, AX
	MOV GS, AX
	
	MOV AX, 0x7000
	MOV SS, AX
	MOV SP, 0xFFFF
	
	STI
	
	MOV SI, OperatingSystemInformationMessage
	CALL WriteString
	
	JMP $
	
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
		
%DEFINE	BuildDate						"Saturday, February 1st, 2020"
%DEFINE	Copyright						"Copyright (C) 2020 Danny Watts"
%DEFINE	Version							"1.0 (Alpha 1)"
OperatingSystemInformationMessage	DB	10, 13, 10, 13, "Twelve O'Clock ", Version, " (Built on ", BuildDate, ")", 10, 13, Copyright, 0x00