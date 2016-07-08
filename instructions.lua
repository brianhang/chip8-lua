--[[
    This file implements the instructions for the emulator. More information
    about the instructions can be found here:
    http://devernay.free.fr/hacks/chip8/C8TECH10.HTM#3.1
--]]

local bit = bit32 or bit

-- How many bytes are used for each character in memory.
local FONT_HEIGHT = 5

-- The most significant bit for an 8 bit number.
local MSB = 0x80

-- Number of pixels for the width of a sprite.      
local SPRITE_W = 8

-- Number of opcodes to skip to get to the next instruction.
local NEXT_INSTR = 2

-- The number of bits for one hex digit.
local DIGIT = 4

-- The dimensions of the screen.
local DISPLAY_W = 64
local DISPLAY_H = 32

-- Number of digits in base 10.
local DECIMAL = 10

local instructions = {}

instructions[0x0000] = function(self, opcode)
    local address = bit.band(opcode, 0x0FFF)

    -- CLS
    if (address == 0x00E0) then
        for i = 0, (DISPLAY_W * DISPLAY_H) - 1 do
            self.display[i] = 0
        end
    -- RET
    elseif (address == 0x00EE) then
        self.SP = self.SP - 1
        
        return self.stack[self.SP]
    end
end

-- JP addr
instructions[0x1000] = function(self, opcode)
    return bit.band(opcode, 0x0FFF)
end

-- CALL addr
instructions[0x2000] = function(self, opcode)
    self.stack[self.SP] = self.PC
    self.SP = self.SP + 1
    
    return bit.band(opcode, 0x0FFF)
end

-- SE Vx, byte
instructions[0x3000] = function(self, opcode)
    local x = bit.rshift(bit.band(opcode, 0x0F00), DIGIT * 2)
    local value = bit.band(opcode, 0x00FF)
    
    if (self.V[x] == value) then
        return self.PC + NEXT_INSTR
    end
end

-- SNE Vx, byte
instructions[0x4000] = function(self, opcode)
    local x = bit.rshift(bit.band(opcode, 0x0F00), DIGIT * 2)
    local value = bit.band(opcode, 0x00FF)
    
    if (self.V[x] ~= value) then
        return self.PC + NEXT_INSTR
    end
end

-- SE Vx, Vy
instructions[0x5000] = function(self, opcode)
    local x = bit.rshift(bit.band(opcode, 0x0F00), DIGIT * 2)
    local y = bit.rshift(bit.band(opcode, 0x00F0), DIGIT)
    
    if (self.V[x] == self.V[y]) then
        return self.PC + NEXT_INSTR
    end
end

-- LD Vx, byte
instructions[0x6000] = function(self, opcode)
    local x = bit.rshift(bit.band(opcode, 0x0F00), DIGIT * 2)
    local value = bit.band(opcode, 0x00FF)
    
    self.V[x] = value
end

-- ADD Vx, byte
instructions[0x7000] = function(self, opcode)
    local x = bit.rshift(bit.band(opcode, 0x0F00), DIGIT * 2)
    local value = bit.band(opcode, 0x00FF)
    
    self.V[x] = (self.V[x] + value) % 0x100
end

instructions[0x8000] = function(self, opcode)
    local x = bit.rshift(bit.band(opcode, 0x0F00), DIGIT * 2)
    local y = bit.rshift(bit.band(opcode, 0x00F0), DIGIT)
    local op = bit.band(opcode, 0x000F)
    
    -- LD Vx, Vy    
    if (op == 0) then
        self.V[x] = self.V[y]
    -- OR Vx, Vy
    elseif (op == 1) then
        self.V[x] = bit.bor(self.V[x], self.V[y])
    -- AND Vx, Vy
    elseif (op == 2) then
        self.V[x] = bit.band(self.V[x], self.V[y])
    -- XOR Vx, Vy
    elseif (op == 3) then
        self.V[x] = bit.bxor(self.V[x], self.V[y])
    -- ADD Vx, Vy
    elseif (op == 4) then
        local sum = self.V[x] + self.V[y]
        
        self.V[0xF] = (sum > 0xFF) and 1 or 0
        self.V[x] = (self.V[x] + self.V[y]) % 0x100
    -- SUB Vx, Vy
    elseif (op == 5) then
        self.V[0xF] = (self.V[x] > self.V[y]) and 1 or 0
        self.V[x] = (self.V[x] - self.V[y]) % 0x100
    -- SHR Vx
    elseif (op == 6) then
        self.V[0xF] = bit.band(self.V[x], 0x1)
        self.V[x] = math.floor(self.V[x] / 2) % 0x100
    -- SUBN Vx, Vy
    elseif (op == 7) then
        self.V[0xF] = (self.V[y] > self.V[x]) and 1 or 0
        self.V[x] = (self.V[y] - self.V[x]) % 0x100
    -- SHL Vx
    elseif (op == 0xE) then
        self.V[0xF] = (bit.band(self.V[x], 0x80) == 0x80) and 1 or 0
        self.V[x] = math.floor(self.V[x] * 2) % 0x100
    end
end

-- SNE Vx, Vy
instructions[0x9000] = function(self, opcode)
    local x = bit.rshift(bit.band(opcode, 0x0F00), DIGIT * 2)
    local y = bit.rshift(bit.band(opcode, 0x00F0), DIGIT)
    
    if (self.V[x] ~= self.V[y]) then
        return self.PC + NEXT_INSTR
    end
end

-- LD I, addr
instructions[0xA000] = function(self, opcode)
    self.I = bit.band(opcode, 0x0FFF)
end

-- JP V0, addr
instructions[0xB000] = function(self, opcode)
    local address = bit.band(opcode, 0x0FFF)

    return address + self.V[0]
end

-- RND Vx, byte
instructions[0xC000] = function(self, opcode)
    local index = bit.rshift(bit.band(opcode, 0x0F00), DIGIT * 2)
    local constant = bit.band(opcode, 0x00FF)
    
    self.V[index] = bit.band(math.random(0, 255), constant)
end

-- DRW Vx, Vy, nibble
instructions[0xD000] = function(self, opcode)
    local originX = bit.rshift(bit.band(opcode, 0x0F00), DIGIT * 2)
    local originY = bit.rshift(bit.band(opcode, 0x00F0), DIGIT)
    local height = bit.band(opcode, 0x000F)
    local data = 0x0000
    local value = 0
    local position = 0
    
    self.V[0xF] = 0

    for y = 0, height - 1 do
        data = self.memory[self.I + y]

        for x = 0, SPRITE_W - 1 do
            if (bit.band(data, bit.rshift(MSB, x)) > 0) then
                position = ((self.V[originX] + x) % DISPLAY_W)
                           + (((self.V[originY] + y) % DISPLAY_H) * DISPLAY_W)

                value = self.display[position]
                
                if (value == 1) then
                    self.V[0xF] = 1
                end
                
                self.display[position] = bit.bxor(value, 1)
            end
        end
    end
end


instructions[0xE000] = function(self, opcode)
    local x = bit.rshift(bit.band(opcode, 0x0F00), DIGIT * 2)
    local op = bit.band(opcode, 0x00FF)
    
    -- SKP Vx
    if (op == 0x9E and self.keyboard[self.V[x]]) then
        return self.PC + NEXT_INSTR
    -- SKPN Vx
    elseif (op == 0xA1 and not self.keyboard[self.V[x]]) then
        return self.PC + NEXT_INSTR
    end
end

instructions[0xF000] = function(self, opcode)
    local x = bit.rshift(bit.band(opcode, 0x0F00), DIGIT * 2)
    local op = bit.band(opcode, 0x00FF)

    -- LD Vx, DT    
    if (op == 0x07) then
        self.V[x] = self.DT
    -- LD Vx, K
    elseif (op == 0x0A) then
        local oldSetKeyDown = self.setKeyDown
        
        -- Pause the program.
        self.running = false
        
        -- Keep the program paused until a key press.
        self.setKeyDown = function(self, key, down)
            if (down) then
                -- Store the pressed key.
                self.V[x] = key
                
                -- Restart the program.
                self.setKeyDown = oldSetKeyDown
                self.running = true
            end
        end
    -- LD DT, Vx
    elseif (op == 0x15) then
        self.DT = self.V[x]
    -- LD ST, Vx
    elseif (op == 0x18) then
        self.ST = self.V[x]
    -- ADD I, Vx
    elseif (op == 0x1E) then
        self.I = self.I + self.V[x]
    -- LD F, Vx
    elseif (op == 0x29) then
        self.I = self.V[x] * FONT_HEIGHT
    -- LD B, Vx
    elseif (op == 0x33) then
        local value = self.V[x]
        
        local ones = value % DECIMAL
        value = math.floor(value / DECIMAL)
        
        local tens = value % DECIMAL
        value = math.floor(value / DECIMAL)
        
        local hundreds = value % DECIMAL
        
        self.memory[self.I] = hundreds
        self.memory[self.I + 1] = tens
        self.memory[self.I + 2] = ones
    -- LD [I], Vx
    elseif (op == 0x55) then
        for i = 0, x do
            self.memory[self.I + i] = self.V[i]
        end
    -- LD Vx, [I]
    elseif (op == 0x65) then
        for i = 0, x do
            self.V[i] = self.memory[self.I + i]
        end
    end
end

return instructions