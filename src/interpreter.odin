package main

import "core:mem"
import "core:fmt"

Instruction_Proc :: proc(using info: ^Instruction_Info)

Instruction_Info :: struct
{
  op:  u16,
  x:   u8,
  y:   u8,
  n:   u8,
  nn:  u8,
  nnn: u16,
}

table   := make(map[u8]Instruction_Proc)
table_0 := make(map[u8]Instruction_Proc)
table_8 := make(map[u8]Instruction_Proc)
table_e := make(map[u8]Instruction_Proc)
table_f := make(map[u8]Instruction_Proc)

table_init :: proc()
{
  for i in 0x0 ..= 0xE
  {
    table_0[u8(i)] = op_null
    table_8[u8(i)] = op_null
    table_e[u8(i)] = op_null
  }
  
  for i in 0x0 ..= 0x65
  {
    table_f[u8(i)] = op_null
  }

  table[0x0] = op_table_0
  {
    table_0[0xE0] = op_00E0
    table_0[0xEE] = op_00EE
  }

  table[0x1] = op_1NNN
  table[0x2] = op_2NNN
  table[0x3] = op_3XNN
  table[0x4] = op_4XNN
  table[0x5] = op_5XY0
  table[0x6] = op_6XNN
  table[0x7] = op_7XNN

  table[0x8] = op_table_8
  {
    table_8[0x0] = op_8XY0
    table_8[0x1] = op_8XY1
    table_8[0x2] = op_8XY2
    table_8[0x3] = op_8XY3
    table_8[0x4] = op_8XY4
    table_8[0x5] = op_8XY5
    table_8[0x6] = op_8XY6
    table_8[0x7] = op_8XY7
    table_8[0xE] = op_8XYE
  }

  table[0x9] = op_9XY0
  table[0xA] = op_ANNN
  table[0xB] = op_BNNN
  table[0xC] = op_CXNN
  table[0xD] = op_DXYN

  table[0xE] = op_table_e
  {
    table_e[0x9E] = op_EX9E
    table_e[0xA1] = op_EXA1
  }

  table[0xF] = op_table_f
  {
    table_f[0x07] = op_FX07
    table_f[0x0A] = op_FX0A
    table_f[0x15] = op_FX15
    table_f[0x18] = op_FX18
    table_f[0x1E] = op_FX1E
    table_f[0x29] = op_FX29
    table_f[0x33] = op_FX33
    table_f[0x55] = op_FX55
    table_f[0x65] = op_FX65
  }
}

decode :: proc(opcode: u16)
{
  info := Instruction_Info{}
  info.op  = opcode
  info.x   = u8((opcode & 0x0F00) >> 8)
  info.y   = u8((opcode & 0x00F0) >> 4)
  info.n   = u8 (opcode & 0x000F)
  info.nn  = u8 (opcode & 0x00FF)
  info.nnn = u16(opcode & 0x0FFF)

  // call opcode table procedure
  t := u8((opcode & 0xF000) >> 12)
  table[t](&info)
}

// MARK: TABLE 0
op_table_0 :: proc(using info: ^Instruction_Info)
{
  table_0[nn](info)
}

op_00E0 :: proc(using info: ^Instruction_Info)
{
  mem.zero(&state.display, DISPLAY_SIZE)
}

op_00EE :: proc(using info: ^Instruction_Info)
{
  using state

  pc = stack[sp]
  sp -= 1
}

// MARK: OP 1 - 7
op_1NNN :: proc(using info: ^Instruction_Info)
{
  using state

  pc = nnn
}

op_2NNN :: proc(using info: ^Instruction_Info)
{
  using state

  sp += 1
  stack[sp] = pc
  pc = nnn
}

op_3XNN :: proc(using info: ^Instruction_Info)
{
  using state

  if V[x] == nn
  {
    pc += 2
  }
}

op_4XNN :: proc(using info: ^Instruction_Info)
{
  using state

  if V[x] != nn
  {
    pc += 2
  }
}

op_5XY0 :: proc(using info: ^Instruction_Info)
{
  using state

  if V[x] == V[y]
  {
    pc += 2
  }
}

op_6XNN :: proc(using info: ^Instruction_Info)
{
  using state

  V[x] = nn
}

op_7XNN :: proc(using info: ^Instruction_Info)
{
  using state

  V[x] += nn
}

// MARK: TABLE 8
op_table_8 :: proc(using info: ^Instruction_Info)
{
  table_8[n](info)
}

op_8XY0 :: proc(using info: ^Instruction_Info)
{
  using state

  V[x] = V[y]
}

op_8XY1 :: proc(using info: ^Instruction_Info)
{
  using state

  V[x] |= V[y]
}

op_8XY2 :: proc(using info: ^Instruction_Info)
{
  using state

  V[x] &= V[y]
}

op_8XY3 :: proc(using info: ^Instruction_Info)
{
  using state

  V[x] ~= V[y]
}

op_8XY4 :: proc(using info: ^Instruction_Info)
{
  using state

  sum := V[x] + V[y]

  if sum > 255
  {
    V[0xF] = 1
  }
  else
  {
    V[0xF] = 0
  }

  V[x] = sum & 0xFF
}

op_8XY5 :: proc(using info: ^Instruction_Info)
{
  using state

  if V[x] > V[y]
  {
    V[0xF] = 1
  }
  else
  {
    V[0xF] = 0
  }

  V[x] -= V[y]
}

op_8XY6 :: proc(using info: ^Instruction_Info)
{
  using state

	// least significant bit
	V[0xF] = (V[x] & 0x1)
	V[x] >>= 1
}

op_8XY7 :: proc(using info: ^Instruction_Info)
{
  using state

  if V[y] >= V[x]
  {
    V[0xF] = 1
  }
  else
  {
    V[0xF] = 0
  }

  V[x] = V[y] - V[x]
}

op_8XYE :: proc(using info: ^Instruction_Info)
{
  using state

	// most significant bit
	V[0xF] = (V[x] & 0x80) >> 7
	V[x] <<= 1
}

// MARK: OP 9 - D
op_9XY0 :: proc(using info: ^Instruction_Info)
{
  using state

  if V[x] != V[y]
  {
    pc += 2
  }
}

op_ANNN :: proc(using info: ^Instruction_Info)
{
  using state

  I = nnn
}

op_BNNN :: proc(using info: ^Instruction_Info)
{
  using state

  pc = nnn + u16(V[0x0])
}

op_CXNN :: proc(using info: ^Instruction_Info)
{
  using state

  V[x] = rand_byte() & nn
}

op_DXYN :: proc(using info: ^Instruction_Info)
{
  // draw sprite
  using state

  sprite_x  := V[x] % DISPLAY_WIDTH
  sprite_y  := V[y] % DISPLAY_HEIGHT

  SPRITE_HEIGHT :: 8

  // reset collision bit
  V[0xF] = 0

  for row in 0 ..< n
  {
    pixel_y := sprite_y + row
    if pixel_y >= DISPLAY_HEIGHT
    {
      break
    }

    sprite_row := memory[I + u16(row)]

    for col in 0 ..< SPRITE_HEIGHT
    {
      pixel_x := sprite_x + u8(col)
      if pixel_x >= DISPLAY_WIDTH
      {
        break
      }

      pixel_idx := u16(pixel_y) * DISPLAY_WIDTH + u16(pixel_x)

      swap_pixel := bool((sprite_row >> (7 - u8(col))) & 1)
      pixel_on := display[pixel_idx]

      if swap_pixel
      {
        if pixel_on
        {
          display[pixel_idx] = false
          V[0xF] = 0x1
        }
        else
        {
          display[pixel_idx] = true
        }
        draw_flag = true
      }
    }
  }
}

// MARK: TABLE E
op_table_e :: proc(using info: ^Instruction_Info)
{
  table_e[nn](info)
}

op_EX9E :: proc(using info: ^Instruction_Info)
{
  using state

  if is_key_down(V[x])
  {
    pc += 2
  }
}

op_EXA1 :: proc(using info: ^Instruction_Info)
{
  using state

  if !is_key_down(V[x])
  {
    pc += 2
  }
}

// MARK: TABLE F
op_table_f :: proc(using info: ^Instruction_Info)
{
  table_f[nn](info)
}

op_FX07 :: proc(using info: ^Instruction_Info)
{
  using state

  V[x] = delay_timer
}

op_FX0A :: proc(using info: ^Instruction_Info)
{
  using state

  keypress := false

  for i in 0 ..< KEY_COUNT
  {
    if is_key_down(auto_cast i)
    {
      V[x] = auto_cast i
      keypress = true
      break
    }
  }

  if !keypress
  {
    // execute the same instruction again if no keypress
    pc -= 2
  }
}

op_FX15 :: proc(using info: ^Instruction_Info)
{
  using state

  delay_timer = V[x]
}

op_FX18 :: proc(using info: ^Instruction_Info)
{
  using state

  sound_timer = V[x]
}

op_FX1E :: proc(using info: ^Instruction_Info)
{
  using state

  I += cast(u16) V[x]
}

op_FX29 :: proc(using info: ^Instruction_Info)
{
  using state

  FONTSET_HEIGHT :: 5
  I = FONTSET_START_ADDRESS + FONTSET_HEIGHT * u16(V[x])
}

op_FX33 :: proc(using info: ^Instruction_Info)
{
  using state

  memory[I + 0] = V[x] / 100
  memory[I + 1] = (V[x] / 10) % 10
  memory[I + 2] = (V[x] % 100) % 10
}

op_FX55 :: proc(using info: ^Instruction_Info)
{
  using state

  for i in 0 ..= x
  {
    memory[I + u16(i)] = V[i]
  }
}

op_FX65 :: proc(using info: ^Instruction_Info)
{
  using state

  for i in 0 ..= x
  {
    V[i] = memory[I + u16(i)]
  }
}

// MARK: OPCODES
op_null :: proc(using info: ^Instruction_Info)
{
  fmt.printfln("invalid opcode %X", info.op)
}
