# 6502-Assembly-NES-Game-Development
![Designed for Nintendo Entertainment System 6502 CPU][console-version]

Just messing around with programming a Nintendo Entertainment System / Famicom game from scratch in 6502 assembly.
Note that this is an unfinished, archived project of mine from 2019/2020.
For my development environment, I used [NotePad++](https://notepad-plus-plus.org/) with a custom hotkey to run my AUTO.bat script which would create a backup of my code, compile the source, and launch the compiled software from an NES emulator in debug mode. For my compiler/assembler, I used [NES ASM v3.1](https://github.com/camsaul/nesasm).

## Source Code

The source code is located in the infile.asm and the mario.chr files.
The mario.chr is what is known as the character ROM and contains all graphical data to be used in the game.
The infile.asm is what is known as the program ROM, and contains everything else. It is written entirely in 6502 assembly language.

## Compiled ROM

The fully compiled software is infile.nes and can be run on either an emulator or real Nintendo hardware (both tested).

![screenshot](/collisionRoomPreview_July2020.png?raw=true "July 2020 object collision test room")

## Omissions

You may notice that CHR viewer and 6502 compiler tools that are referenced in my AUTO.bat compile/test/archive script are missing here. That is because those tools are not my creation so I did not upload them to my repo.

## Special Thanks

I would like to give special thanks to [nerdynights](https://taywee.github.io/NerdyNights/) for their extensive knowledge sharing on the subject.
Also a special thanks to Lance A. Leventhal for his great 1979 book "6502 Assembly Language Programming"!

[console-version]: https://img.shields.io/badge/NES-6502-lightgrey
