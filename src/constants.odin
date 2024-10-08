package main

import SDL "vendor:sdl2"

MEMORY_SIZE :: 4096
REGISTER_COUNT :: 16
STACK_DEPTH :: 12
DISPLAY_WIDTH :: 64
DISPLAY_HEIGHT :: 32
DISPLAY_SIZE :: DISPLAY_WIDTH * DISPLAY_HEIGHT
KEY_COUNT :: 16

START_ADDRESS :: 0x200
FONTSET_SIZE :: 80
FONTSET_START_ADDRESS :: 0x0

DISPLAY_SCALE :: 16
SCREEN_WIDTH :: DISPLAY_WIDTH * DISPLAY_SCALE
SCREEN_HEIGHT :: DISPLAY_HEIGHT * DISPLAY_SCALE

INSTRUCTIONS_PER_SECOND :: 500.0
TIME_PER_INSTRUCTION :: 1000.0 / INSTRUCTIONS_PER_SECOND

DEBUG_PRINT :: false
COLOR_DISPLAY :: 0x00FF00
COLOR_BACKGROUND :: 0x000000

FONTSET: [FONTSET_SIZE]u8 =
{
	0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
	0x20, 0x60, 0x20, 0x20, 0x70, // 1
	0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
	0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
	0x90, 0x90, 0xF0, 0x10, 0x10, // 4
	0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
	0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
	0xF0, 0x10, 0x20, 0x40, 0x40, // 7
	0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
	0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
	0xF0, 0x90, 0xF0, 0x90, 0x90, // A
	0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
	0xF0, 0x80, 0x80, 0x80, 0xF0, // C
	0xE0, 0x90, 0x90, 0x90, 0xE0, // D
	0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
	0xF0, 0x80, 0xF0, 0x80, 0x80  // F
}

KEYMAP: [KEY_COUNT]SDL.Keycode =
{
	.X,		 // 0
	.NUM1, // 1
	.NUM2, // 2
	.NUM3, // 3
	.Q,		 // 4
	.W,		 // 5
	.E,		 // 6
	.A,		 // 7
	.S,		 // 8
	.D,		 // 9
	.Z,		 // A
	.C,		 // B
	.NUM4, // C
	.R,		 // D
	.F,		 // E
	.V,		 // F
}
