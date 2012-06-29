--[[
    Touchscreen Notepad for COWON D2
	Version 0.1
	
	© 2010 Neris Ereptoris (www.neris.ws)

]]--

require "actions"
require "buttons"



local POOLING_TIME = rb.HZ / 10

-- White style
--local DEFAULT_COLOR = rb.lcd_rgbpack(0, 0, 0)
--local BORDER_COLOR = rb.lcd_rgbpack(230, 230, 230)
--local BACKGROUND_COLOR = rb.lcd_rgbpack(255, 255, 255)

-- Black style
local DEFAULT_COLOR = rb.lcd_rgbpack(235, 235, 235)
local BORDER_COLOR = rb.lcd_rgbpack(50, 50, 50)
local BACKGROUND_COLOR = rb.lcd_rgbpack(0, 0, 0)


local KEYBOADR_X_OFFSET = 5
local KEYBOADR_Y_OFFSET = 110

local buffer = { {} }
local buttons = {}

local current_layout = "en" -- en, ru, compose
local current_layout_mode = "normal" -- shifted, normal

local layouts = {
	["en"] = {
		["normal"] = {
			{ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" },
			{ "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]" },
			{ "a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'" },
			{ "z", "x", "c", "v", "b", "n", "m", ",", ".", "/", "\\" },
		},
		["shifted"] = {
			{ "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "_", "+" },
			{ "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "{", "}" },
			{ "A", "S", "D", "F", "G", "H", "J", "K", "L", ":", "\"" },
			{ "Z", "X", "C", "V", "B", "N", "M", "<", ">", "?", "|" },
		}
	},
	
	["ru"] = {
		["normal"] = {
			{ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" },
			{ "й", "ц", "у", "к", "е", "н", "г", "ш", "щ", "з", "х", "ъ" },
			{ "ф", "ы", "в", "а", "п", "р", "о", "л", "д", "ж", "э" },
			{ "я", "ч", "с", "м", "и", "т", "ь", "б", "ю", ".", "\\" },
		},
		["shifted"] = {
			{ "!", "\"", "№", ";", "%", ":", "?", "*", "(", ")", "_", "+" },
			{ "Й", "Ц", "У", "К", "Е", "Н", "Г", "Ш", "Щ", "З", "Х", "Ъ" },
			{ "Ф", "Ы", "В", "А", "П", "Р", "О", "Л", "Д", "Ж", "Э" },
			{ "Я", "Ч", "С", "М", "И", "Т", "Ь", "Б", "Ю", ",", "/" },
		}
	},
	
	["compose"] = {
		["normal"] = {
			{ "¹", "²", "³", "$", "‰", "↑", nil, "∞", "←", "→", "—", "≠" },
			{ nil, nil, "€", "®", "™", "ѣ", "ѵ", "і", "ѳ", "′", "[", "]" },
			{ "≈", "§", "°", "£", "¥", nil, "„", "“", "”", "‘", "’" },
			{ nil, "×", "©", "↓", nil, nil, "−", "«", "»", "…", nil },
		},
		["shifted"] = {
			{ "ё", "Ё", "`", "~", nil, "½", "¼", "¾" },
			{ "́", "¨", "¯", "±", "·", "÷", "¤", "ſ", "ñ", "¢" },
			{ "À", "Ã", "Â", "Å", "Æ", "È", "Ê", "Ô", "Õ", "Ù", "Û" },
			{ "à", "ã", "â", "å", "æ", "è", "ê", "ô", "õ", "ù", "û" },
		}
	},
}

function table.copy(t)
  local u = { }
  for k, v in pairs(t) do u[k] = v end
  return setmetatable(u, getmetatable(t))
end



local Cursor = {
	x = 1,
	y = 1
}

local Button = {
	x = 0,
	y = 0,
	width = 25,
	height = 25,
	label = ""
}

function Button:new(o)
    local o = o or {}
	
    if not o.width and o.label and string.len(o.label) > 3 then
		o.width = rb.font_getstringsize(o.label, rb.FONT_UI) + 15
    end
	
	o.x = o.x + KEYBOADR_X_OFFSET
	o.y = o.y + KEYBOADR_Y_OFFSET
	
    setmetatable(o, self)
    self.__index = self
	
    return o
end


function Button:draw()
	-- Draw button border
	rb.lcd_set_foreground(BORDER_COLOR)
	rb.lcd_drawrect(self.x, self.y, self.width, self.height)
	
	-- Draw button label
	rb.lcd_set_foreground(DEFAULT_COLOR)
	rb.lcd_putsxy(self.x + 8, self.y + 3, self.label)
end


function Button:isPressed(x, y)
    return x > self.x and x < self.x + self.width and
           y > self.y and y < self.y + self.height
end




function drawUI()
	buttons = {}
    rb.lcd_clear_display()
	
	-- Draw screen background
	rb.lcd_set_foreground(BACKGROUND_COLOR)
	rb.lcd_fillrect(0, 0, rb.LCD_WIDTH, rb.LCD_HEIGHT)
	
	-- Restore colors
	rb.lcd_set_background(BACKGROUND_COLOR)
	rb.lcd_set_foreground(DEFAULT_COLOR)
	
	-- Create main buttons
	buttons["Return"] = Button:new({ label = "Return", x = Button.width * 11, y = Button.height * 2 })
	buttons["Shift"] = Button:new({ label = "Shift", x = Button.width * 11, y = Button.height * 3 })
	buttons["ru"] = Button:new({ label = "ru", x = 0, y = Button.height * 4, width = 30 })
	buttons["en"] = Button:new({ label = "en", x = 30, y = Button.height * 4, width = 30 })
	buttons["Compose"] = Button:new({ label = "#?", x = 60, y = Button.height * 4, width = 30 })
	buttons[" "] = Button:new({ label = " ", x = 90, y = Button.height * 4, width = 100 })
	buttons["Backspace"] = Button:new({ label = "←Back", x = 190, y = Button.height * 4, width = 60 })
	
	-- Create layout buttons
	for row_num, row in ipairs(layouts[current_layout][current_layout_mode]) do
		for index, label in pairs(row) do
			if label ~= nil then
				buttons[label] = Button:new({
					label = label,
					x = Button.width * (index - 1),
					y = Button.height * (row_num - 1)
				})
			end
		end
	end
	
	-- Draw all buttons
	for _, btn in pairs(buttons) do
		btn:draw()
	end
end



function showBuffer()
	-- Clear previous data
	rb.lcd_set_foreground(BACKGROUND_COLOR)
	rb.lcd_fillrect(0, 0, rb.LCD_WIDTH, KEYBOADR_Y_OFFSET)
	
	rb.lcd_set_foreground(DEFAULT_COLOR)
	
	
	for row_num,row in ipairs(buffer) do
		local new_row
		if row_num == Cursor.y then
			new_row = table.copy(row)
			table.insert(new_row, Cursor.x, "|")
		else
			new_row = row
		end
		
		rb.lcd_putsxy(2, 5 + (row_num - 1) * 15, table.concat(new_row))
	end
end


function redrawScreen()
	drawUI()
	showBuffer()
end


function showMenu()
	rb.touchscreen_set_mode(rb.TOUCHSCREEN_BUTTON)
	local menu_idx = rb.do_menu("D2 Notepad", {"Save As...", "Back"}) + 1
	
	
	if menu_idx == -1 then
		
	elseif menu_idx == 1 then
		local file_name = rb.kbd_input("/" .. os.date("%Y-%m-%d") .. ".txt", true)
		local fd = assert(io.open(file_name, "w"))
		
		for k,row in ipairs(buffer) do
			assert(fd:write( table.concat(row) .. "\n"))
		end
		
		fd:close()
	
	else
		
	end
	
	
	redrawScreen()
	rb.lcd_update()
	rb.sleep( rb.HZ * 1)
	rb.touchscreen_set_mode(rb.TOUCHSCREEN_POINT)
end



rb.touchscreen_set_mode(rb.TOUCHSCREEN_POINT)
redrawScreen()

while true do
	
	local action = rb.get_action(rb.contexts.CONTEXT_KEYBOARD, 0)
	
	-- Exit app
    if(action == rb.actions.ACTION_STD_CANCEL) then
        break
    
	-- Menu
    elseif(action == rb.actions.ACTION_KBD_PAGE_FLIP) then
        showMenu()
    
	-- Move cursor left
    elseif(action == rb.actions.ACTION_KBD_CURSOR_LEFT) then
        if Cursor.x > 1 then
			Cursor.x = Cursor.x - 1
		elseif Cursor.y > 1 then
			Cursor.y = Cursor.y - 1
			Cursor.x = table.getn(buffer[Cursor.y]) + 1
		end
		showBuffer()
    
	-- Move cursor right
    elseif(action == rb.actions.ACTION_KBD_CURSOR_RIGHT) then
		if Cursor.x > table.getn(buffer[Cursor.y]) then
			if table.getn(buffer) > Cursor.y then
				Cursor.x = 1
				Cursor.y = Cursor.y + 1
			end
		else
			Cursor.x = Cursor.x + 1
		end
		showBuffer()
	
	-- Touchscreen activated
	elseif action == rb.actions.ACTION_TOUCHSCREEN then
		local t_result, t_x, t_y = rb.action_get_touchscreen_press()
		local touchscreen_released = bit.band(t_result, rb.buttons.BUTTON_REL) == rb.buttons.BUTTON_REL
		
		for _, btn in pairs(buttons) do
			if btn:isPressed(t_x, t_y) then
				
				if touchscreen_released then
				
					-- Shift
					if btn.label == "Shift" then
						if current_layout_mode == "normal" then
							current_layout_mode = "shifted"
						else
							current_layout_mode = "normal"
						end
						redrawScreen()
					
					
					-- Russian layout
					elseif btn.label == "ru" then
						current_layout = "ru"
						redrawScreen()
					
					
					-- English layout
					elseif btn.label == "en" then
						current_layout = "en"
						redrawScreen()
					
					
					-- Compose layout
					elseif btn.label == "#?" then
						current_layout = "compose"
						redrawScreen()
					
					
					-- Return
					elseif btn.label == "Return" then
						table.insert(buffer, {})
						Cursor.y = Cursor.y + 1
						Cursor.x = 1
						showBuffer()
					
					
					-- Backspace
					elseif btn.label == "←Back" then
						if Cursor.y ~= 1 and table.getn(buffer[Cursor.y]) == 0 then
							table.remove(buffer, Cursor.y)
							Cursor.y = Cursor.y - 1
							Cursor.x = table.getn(buffer[Cursor.y]) + 1
						else
							if Cursor.x > 1 then
								table.remove(buffer[Cursor.y], Cursor.x - 1)
								Cursor.x = Cursor.x - 1
							end
						end
						showBuffer()
					
					
					-- Enter character
					else
						table.insert(buffer[Cursor.y], Cursor.x, btn.label)
						Cursor.x = Cursor.x + 1
						showBuffer()
					end
				
				-- Holding
				else
					-- Highlight key
					rb.lcd_putsxy(120, 40, string.format("[  %s  ]       ", btn.label))
					
				end
			end
		end
	
	-- Unknown action
	else
		--rb.lcd_putsxy(120, 40, string.format("[  %s  ]       ", action))
		showBuffer()
	end
	
	rb.lcd_update()
	rb.sleep(POOLING_TIME)
end




