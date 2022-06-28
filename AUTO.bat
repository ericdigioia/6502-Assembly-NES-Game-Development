@ECHO OFF
rem This batch file automatically compiles NES source code
rem using NESASM3 and runs the output NES binary file in FCEUX
rem The source file is also copied to a backup folder each compilation
rem Created by Eric Di Gioia - July 2020

rem Set working directory to directory of this script
CD /d "%~dp0"

rem Delete previous compiled NES file
DEL "infile.nes"

rem Compile source code into NES file
START /b /WAIT "" "NESASM3.EXE" infile.asm

rem Check if compilation was successful
IF EXIST "infile.nes" (

	rem Copy source file to backup folder to maintain backup of latest valid source code
	COPY /Y "infile.asm" "..\BACKUP"

	rem Run NES file in emulator if compilation was successful
	START "" "..\EMULATOR\fceux.exe" infile.nes
	
) ELSE (

	rem Leave window open to view errors if compilation failed
	PAUSE
	
)