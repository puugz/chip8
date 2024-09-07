package main

import "core:fmt"
import "core:math/rand"
import "core:mem"
import "core:os"
import "core:time"
import SDL "vendor:sdl2"

State :: struct
{
	// chip-8
	memory:           [MEMORY_SIZE]u8,
	pc:               u16,
	I:                u16,
	V:                [REGISTER_COUNT]u8,
	stack:            [STACK_DEPTH]u16,
	sp:               u8,
	sound_timer:      u8,
	delay_timer:      u8,
	display:          [DISPLAY_SIZE]bool,
	draw_flag:        bool,
	keypad:           [KEY_COUNT]bool,

	// instructions per second
	last_cycle_ticks: u32,
}

state := State{}

main :: proc() 
{
	using state
	rand.reset(auto_cast time.now()._nsec)

	// init SDL
	assert(SDL.Init(SDL.INIT_VIDEO) == 0, SDL.GetErrorString())
	defer SDL.Quit()

	// make window
	window := SDL.CreateWindow(
		"chip-8 emulator",
		SDL.WINDOWPOS_CENTERED,
		SDL.WINDOWPOS_CENTERED,
		SCREEN_WIDTH,
		SCREEN_HEIGHT,
		SDL.WINDOW_SHOWN,
	)
	assert(window != nil, SDL.GetErrorString())
	defer SDL.DestroyWindow(window)

	// set vsync
	// when !FRAMERATE_LIMIT do SDL.SetHint(SDL.HINT_RENDER_VSYNC, "1")

	// make renderer
	renderer := SDL.CreateRenderer(window, -1, SDL.RENDERER_ACCELERATED)
	assert(renderer != nil, SDL.GetErrorString())
	defer SDL.DestroyRenderer(renderer)

	texture := SDL.CreateTexture(renderer, .ARGB8888, .STATIC, SCREEN_WIDTH, SCREEN_HEIGHT)
	defer SDL.DestroyTexture(texture)

	chip8_buffer := SDL.CreateRGBSurface(0, DISPLAY_WIDTH, DISPLAY_HEIGHT, 32, 0, 0, 0, 0)
	screen_buffer := SDL.CreateRGBSurface(0, SCREEN_WIDTH, SCREEN_HEIGHT, 32, 0, 0, 0, 0)

	cpu_init()
	cpu_load_rom("roms/BRIX")

	table_init()

	for
	{
		event: SDL.Event
		for SDL.PollEvent(&event)
		{
			if handle_event(event) do return
		}

		current := SDL.GetTicks()
		elapsed := current - last_cycle_ticks

		if elapsed > TIME_PER_INSTRUCTION
		{
			cpu_cycle()
			last_cycle_ticks = SDL.GetTicks()
		}

		if draw_flag
		{
			draw_flag = false
			draw_screen(renderer, texture, chip8_buffer, screen_buffer)
		}
	}
}

cpu_init :: proc()
{
	using state

	pc = START_ADDRESS
	I = 0
	sp = 0

	// load font into memory
	for i in 0 ..< FONTSET_SIZE
	{
		memory[FONTSET_START_ADDRESS + i] = FONTSET[i]
	}
}

cpu_cycle :: proc()
{
	using state

	// fetch opcode & advance program counter
	opcode := u16(memory[pc]) << 8 | u16(memory[pc + 1])
	pc += 2

	decode(opcode)

	// update timers
	if delay_timer > 0 do delay_timer -= 1

	if sound_timer > 0 do sound_timer -= 1
	if sound_timer == 1 do fmt.println("*beep*")
}

rand_byte :: proc() -> u8
{
	return auto_cast rand.int31_max(255)
}

cpu_load_rom :: proc(filename: string)
{
	using state

	f, ferr := os.open(filename)
	if ferr != 0
	{
		fmt.panicf("error: could not open file %s", filename)
	}

	defer os.close(f)
	buffer, rerr := os.read_entire_file_from_handle_or_err(f)

	if rerr != 0
	{
		fmt.panicf("error: could not read file %s", filename)
	}

	// defer free(buffer)

	for i in 0 ..< len(buffer)
	{
		memory[START_ADDRESS + i] = buffer[i]
	}
}

handle_event :: proc(event: SDL.Event) -> bool
{
	using state

	#partial switch event.type 
	{
	case .QUIT:
		{
			return true
		}
	case .KEYDOWN:
		{
			if event.key.keysym.scancode == SDL.SCANCODE_ESCAPE
			{
				return true
			}

			for i in 0 ..< KEY_COUNT
			{
				if event.key.keysym.sym == KEYMAP[i]
				{
					keypad[i] = true
					break
				}
			}
		}
	case .KEYUP:
		{
			for i in 0 ..< KEY_COUNT
			{
				if event.key.keysym.sym == KEYMAP[i]
				{
					keypad[i] = false
					break
				}
			}
		}
	case .DROPFILE:
		{
			file_path := event.drop.file

			// reset memory & load dropped rom file
			state = {}
			cpu_init()
			cpu_load_rom(string(file_path))

			SDL.free(&file_path)
		}
	}

	return false
}

draw_screen :: proc(renderer: ^SDL.Renderer, texture: ^SDL.Texture, chip8_buffer, screen_buffer: ^SDL.Surface)
{
	using state

	SDL.LockSurface(chip8_buffer)
	pixels := cast([^]u32)chip8_buffer.pixels

	for i in 0 ..< DISPLAY_SIZE
	{
		if display[i]
		{
			pixels[i] = COLOR_DISPLAY
		}
		else
		{
			pixels[i] = COLOR_BACKGROUND
		}
	}

	SDL.UnlockSurface(chip8_buffer)

	SDL.BlitScaled(chip8_buffer, nil, screen_buffer, nil)
	SDL.UpdateTexture(texture, nil, screen_buffer.pixels, screen_buffer.pitch)
	SDL.RenderClear(renderer)
	SDL.RenderCopy(renderer, texture, nil, nil)
	SDL.RenderPresent(renderer)
}

is_key_down :: proc(key: u8) -> bool
{
	using state
	return keypad[key]
}
