local composer = require("composer")
local scene = composer.newScene()
local testing_phase
local user

local screen_width = display.contentWidth
local screen_height = display.contentHeight
local center_x = display.contentCenterX
local center_y = display.contentCenterY

local view_login
local view_signup

local view_login_off_x = center_x
local view_login_off_y = -center_y

local background_icon_size = 15
local background_margin_bottom = 60

local button_width = 130
local button_height = 30
local button_margin_bottom = button_height + 10
local button_margin_right = button_margin_bottom
local button_corner_radius = 15
local button_label_font_size = 20

local shadow_shift_y = 10
local shadow_height = 35
local shadow_alpha = 0.7

local font = "happy-hell.ttf"--native.systemFont
local font_bold = "happy-hell.ttf"--native.systemFontBold
local font_size = 40

local view_corner_radius = 20
local view_margin_left = 15
local view_margin_top = 100--80 --30
local view_margin_vertical = view_margin_top * 2
local view_margin_horizontal = view_margin_left * 2
local view_alpha = 0.6

local checkbox_size = 15
local checkbox_height = 20 --15
local checkbox_corner_radius = 2
local checkbox_margin_left = 3
local checkbox_margin_right = 10
local checkbox_margin_horizontal = checkbox_margin_left + checkbox_margin_right
local checkbox_label_margin_horizontal = checkbox_margin_horizontal + 10

local gem_size = 3--5

local server_ip = "localhost"
local server_port = 80

local view_win

local view_end_game

local keyboard_characters = {
	{"q", "w", "e", "r", "t", "y", "u", "i", "o", "p"},
	{"a", "s", "d", "f", "g", "h", "j", "k", "l", "ñ"},
	{"z", "x", "c", "v", "b", "n", "m", "@", ".", "OK"}
}

local title = {
	text,
	label = "Press reload to update objects from server",
	x_pos = center_x,
	y_pos = -150,
}

local reload_button = {
	rect,
	text,
	text_label = "RELOAD",
	width = button_width,
	height = button_height,
	x_pos = center_x,
	y_pos = title.y_pos + button_margin_bottom
}

local buttons = {}
local texts = {}

local text_margin_right = 15
local text_margin_left = text_margin_right
local text_margin_horizontal = text_margin_right + text_margin_left
local text_margin_top = 15 --80
local text_font_size = 30

local initial_buttons_quantity = 5

local input_user

local keyboard

local button_next

local instructions_margin_top = 15
local instructions_margin_horizontal = 60
local instructions_text_margin_left = 10
local instructions_height = 45
local instructions_width = screen_width - instructions_margin_horizontal
local instructions_font_size = 20

local minigame = {}

local score

local win_notification = "Bien ahi!"
local win_code = "SKR 123"

local actual_minigame = false

-------------------------

Button = {}
Button.__index = Button

function Button:new(group, x, y, width, height, color, rounded, label, on_press)
	local shadow = {rect}
	local y_pos = y
	shadow.rect = display.newRoundedRect(group, center_x, y_pos + button_height / 2, width, shadow_height, button_corner_radius) -- previous to center_x: x (only)
	shadow.rect:setFillColor(0, 0, 0, shadow_alpha)

	shadow.rect.fill.effect = "filter.linearWipe"
	shadow.rect.fill.effect.direction = { 0, 1 }
	shadow.rect.fill.effect.smoothness = 0.8
	shadow.rect.fill.effect.progress = 0.4

	local rect = display.newRoundedRect(group, center_x, y_pos, width, height, 5)
	rect:setFillColor(color[1]/255, color[2]/255, color[3]/255)
	rect.fill.effect = "filter.brightness"

	local text = display.newText(group, label, center_x, y_pos, font_bold, button_label_font_size)

	local button = {
		shadow = shadow,
		rect = rect,
		text = text,
		y_pos = y_pos
	}

	local brighten = function(event)
		if event.phase == "began" then
			transition.to(rect.fill.effect, {intensity = 0.2, time = 250}) --0.3
		elseif event.phase == "ended" then
			transition.to(rect.fill.effect, {intensity = 0, time = 250})
		end
	end
	local expand_factor = 7
	local expandShadow = function(event)
		if event.phase == "began" then
			transition.to(shadow.rect.fill.effect, {progress = 0.5, time = 250}) --0.6
		elseif event.phase == "ended" then
			transition.to(shadow.rect.fill.effect, {progress = 0.4, time = 250})
		end
	end
	local onPress = function(event)
		brighten(event)
		expandShadow(event)
		on_press(event)
	end
	rect:addEventListener("touch", onPress)

	setmetatable(button, Button)
	return button
end

function Button:hide()
	transition.to(self.shadow.rect, {y = self.shadow.rect.y + screen_height/2, transition = easing.outQuad, time = 300})
	transition.to(self.rect, {y = self.rect.y + screen_height/2, transition = easing.outQuad, time = 300})
	transition.to(self.text, {y = self.text.y + screen_height/2, transition = easing.outQuad, time = 300})
end

function Button:show()
	transition.to(self.shadow.rect, {y = self.y_pos + button_height / 2, transition = easing.outQuad, time = 300})
	transition.to(self.rect, {y = self.y_pos, transition = easing.outQuad, time = 300})
	transition.to(self.text, {y = self.y_pos, transition = easing.outQuad, time = 300})
end

function Button:setPos(x, y)
	self.shadow.rect.x = x
	self.shadow.rect.y = y + button_height / 2
	self.rect.x = x
	self.rect.y = y
	self.text.x = x
	self.text.y = y
	self.text.size = 18
end

function Button:remove()
	display.remove(self.rect)
	self.rect = nil

	display.remove(self.text)
	self.text = nil

	self = nil
end


Background = {}
Background.__index = Background

function Background:new(color)
	local group = display.newGroup()
	local rect = display.newRect(group, center_x, center_y, screen_width, screen_height)
	rect:setFillColor(color[1]/255, color[2]/255, color[3]/255)

	local columns_number = math.ceil(screen_width / background_icon_size)
	local icons = {}
	for i = 1, columns_number do
		local first_row = 1
		local last_row = 12
		local icon_y_shift = 15
		if (i%2==0) then
			icon_y_shift = 0
		end
		icons[i] = {}
		for j = first_row, last_row do
			local x_pos = (i - 1) * 80
			local y_pos = background_margin_bottom * (j - 1) + icon_y_shift
			icons[i][j] = {x = x_pos, y = y_pos}
			icons[i][j].heart = display.newText(group, "<3", x_pos, y_pos, font_bold, font_size)
		end
	end

	local background = {
		group = group,
		rect = rect,
		icons = icons
	}
	setmetatable(background, Background)
	return background
end

function Background:remove()
	display.remove(self.rect)
	self.rect = nil

	for i = 1, #self.icons do
		for j = 1, #self.icons[i] do
			display.remove(self.icons[i][j].heart)
			self.icons[i][j] = nil
		end
	end

	self = nil
end

-----------------------

View = {}
View.__index = View

function View:new(color, hidden)
	local group = display.newGroup()
	local x_pos = center_x
	local y_pos = center_y
	local enabled = true
	local at_right = false
	if hidden then
		x_pos = x_pos + screen_width
	end
	local rect = display.newRoundedRect(group, x_pos, y_pos, screen_width - view_margin_horizontal, screen_height - view_margin_vertical, view_corner_radius)
	rect:setFillColor(color[1]/255, color[2]/255, color[3]/255, view_alpha)
	local view = {
		at_right = at_right,
		rect = rect,
		group = group,
		enabled = enabled
	}
	setmetatable(view, View)
	return view
end

function View:toLeft()
	self.at_right = false
	transition.to(self.group, {x = self.group.x - screen_width, transition = easing.outQuad, time = 300})
end

function View:toRight()
	if not self.at_right then
		transition.to(self.group, {x = self.group.x + screen_width, transition = easing.outQuad, time = 300})
		self.at_right = true
	end
end

function View:enable()
	self.enabled = true
end

function View:disable()
	self.enabled = false
end

function View:remove()
	display.remove(self.rect)
	self.rect = nil
	
	display.remove(self.group)
	self.group = nil

	self = nil
end

-------------------------

Input = {}
Input.__index = Input

local inputs = {focused_input = nil}

function Input:new(group, x, y, width, height, placeholder, mode_password)
	local text = ""
	local rect = display.newRect(group, x, y, width, height)
	local password = false
	if mode_password then
		password = true
	end
	rect:setFillColor(0)
	rect.anchorX = 0
	local underline = display.newRect(group, x, y + height/2, width, 5)
	underline:setFillColor(0.5)
	underline.anchorX = 0
	local highlighter = display.newRect(group, x, y + height/2, 0, 5)
	highlighter:setFillColor(76.5/255, 12.75/255, 216.75/255)
	highlighter.anchorX = 0
	local label = display.newText(group, placeholder, x, y, native.systemFont, 15)
	label:setFillColor(0.85)
	label.anchorX = 0
	rect.isVisible = false
	rect.isHitTestable = true
	local input = {
		rect = rect,
		underline = underline,
		highlighter = highlighter,
		label = label,
		text = text,
		placeholder = placeholder,
		password = password
	}
	table.insert(inputs, input)
	local id = #inputs
	local onPress = function()
		for i = 1, #inputs do
			transition.to(inputs[i].highlighter, {width = 0, time=80})
			inputs[i].label:setFillColor(0.85)
			if i ~= id then
				if inputs[i].label.text == "" then
					inputs[i].label.text = inputs[i].placeholder
				else
					inputs[i].text = inputs[i].label.text
				end
			end
		end
		if not keyboard.visible then
			keyboard:show()
		end
		inputs.focused_input = label
		transition.to(highlighter, {width = width, time=80})
		if text == "" then
			label.text = ""
			label:setFillColor(1)
		end
	end
	rect:addEventListener("tap", onPress)
	setmetatable(input, Input)
	return input
end

function Input:remove()
	display.remove(self.rect)
	self.rect = nil

	display.remove(self.text)
	self.text = nil

	self = nil
end

---------------------------

Keyboard = {}
Keyboard.__index = Keyboard

function Keyboard:new(characters)
	local y_shift = 100
	local key_size = screen_width/10-3--24
	local keys = {}
	local rows = #characters
	local visible = false
	for i = 1, rows do
		keys[i] = {}
		for j = 1, #characters[i] do
			keys[i][j] = {}
			local x_pos = (j-1) * (key_size + 3) + key_size/2
			local y_pos = center_y + 130 + i * (key_size + 3) + y_shift
			keys[i][j].rect = display.newRoundedRect(x_pos, y_pos, key_size, key_size, 3)
			keys[i][j].rect:setFillColor(0.9, 0.9, 0.9)
			keys[i][j].rect.alpha = 0
			keys[i][j].text = display.newText(characters[i][j], x_pos, y_pos, font, 15)
			keys[i][j].text:setFillColor(0, 0, 0)
			keys[i][j].text.alpha = 0
			local onPress = function(event)
				if event.phase == "began" then
					keys[i][j].rect:setFillColor(1)
					local character = characters[i][j]
					inputs.focused_input.text = inputs.focused_input.text..character
				elseif event.phase == "ended" then
					keys[i][j].rect:setFillColor(0.9)
				end
			end
			keys[i][j].rect:addEventListener("touch", onPress)
		end
	end
	local keyboard = {
		keys = keys,
		visible = false,
	}
	setmetatable(keyboard, Keyboard)
	return keyboard
end

function Keyboard:show()
	local y_shift = 100
	self.visible = true
	for i = 1, #self.keys do
		for j = 1, #self.keys[i] do
			transition.to(self.keys[i][j].rect, {alpha = 0.6, y = self.keys[i][j].rect.y - y_shift, time = 100})
			transition.to(self.keys[i][j].text, {alpha = 1, y = self.keys[i][j].text.y - y_shift, time = 100})
		end
	end
end
---------------------------

Checkbox = {}
Checkbox.__index = Checkbox

function Checkbox:new(group, x, y, label)
	local checked = false
	local rect = display.newRect(group, x + checkbox_size * 2 + checkbox_label_margin_horizontal, y, string.len(label) * checkbox_size, checkbox_height);
	rect.isVisible = false
	rect.anchoX = 0
	rect.isHitTestable = true
	local box = display.newRoundedRect(group, x + checkbox_margin_left, y, checkbox_size, checkbox_size, checkbox_corner_radius)
	box:setFillColor(0, 0, 0, 0)
	box.stroke = {0.2}
	box.strokeWidth = 2
	local line = display.newRect(group, x, y, 0, 4) --12
	line:setFillColor(76.5/255, 12.75/255, 216.75/255)
	line.rotation = 45
	local line2 = display.newRect(group, x+9, y-2, 0, 4) --20
	line2:setFillColor(76.5/255, 12.75/255, 216.75/255)
	line2.rotation = -55
	local onPress = function()
		local new_width = 12
		local new_width2 = 20
		local first_line = line
		local last_line = line2
		if checked then
			new_width = 0
			new_width2 = 0
			first_line, last_line = line2, line
		end
		local secondPart = function()
			transition.to(last_line, {width = new_width2, time=50})
			checked = not checked
		end
		transition.to(first_line, {width = new_width, time=50, onComplete=secondPart})
	end
	rect:addEventListener("tap", onPress)
	local label = display.newText(group, label, x + checkbox_size * 2 + checkbox_label_margin_horizontal, y - checkbox_size/7, native.systemFontBold, 15)
	local checkbox = {
		rect = rect,
		box = box,
		label = label,
		line = line,
		line2 = line2,
		checked = checked
	}
	setmetatable(checkbox, Checkbox)
	return checkbox
end

function Checkbox:remove()
	display.remove(self.rect)
	self.rect = nil

	display.remove(self.box)
	self.box = nil

	display.remove(self.label)
	self.label = nil

	self = nil
end

---------------------

Instructions = {}
Instructions.__index = Instructions

function Instructions:new(label)
	local y_pos = instructions_height + instructions_margin_top
	local hidden_y_pos = -y_pos
	local rect = display.newRect(center_x, hidden_y_pos, instructions_width, instructions_height)
	rect:setFillColor(190/255, 130/255, 90/255)
	local text = display.newText(label, rect.x + instructions_text_margin_left, rect.y, rect.width, rect.height, font, instructions_font_size)
	local instructions = {
		y_pos = y_pos,
		hidden_y_pos = hidden_y_pos,
		rect = rect,
		text = text
	}
	setmetatable(instructions, Instructions)
	return instructions
end

function Instructions:show()
	transition.to(self.rect, {y = self.y_pos, time = 250})
	transition.to(self.text, {y = self.y_pos, time = 250})
end

function Instructions:hide()
	transition.to(self.rect, {y = self.hidden_y_pos, time = 250})
	transition.to(self.text, {y = self.hidden_y_pos, time = 250})
end


----------------------

Scoreboard = {}
Scoreboard.__index = Scoreboard

function Scoreboard:new()
	local y_pos = screen_height - 100
	local hidden_y_pos = screen_height + 100
	local rect = display.newRoundedRect(center_x, hidden_y_pos, 160, 60, 10)
	rect:setFillColor(0.5, 0.6, 0.2, 0.8)
	local text = display.newEmbossedText("Puntos: 0", rect.x, rect.y, font, 20)
	local scoreboard = {
		total = 0,
		rect = rect,
		text = text,
		y_pos = y_pos,
		hidden_y_pos = hidden_y_pos
	}
	setmetatable(scoreboard, Scoreboard)
	return scoreboard
end

function Scoreboard:reset()
	self.total = 0
	self.text.text = "Puntos: 0"
end

function Scoreboard:set(score)
	self.text.text = "Puntos: "..score
	self.total = score
end

function Scoreboard:show()
	transition.to(self.rect, {y = self.y_pos, time = 250})
	transition.to(self.text, {y = self.y_pos, time = 250})
end

function Scoreboard:hide()
	transition.to(self.rect, {y = self.hidden_y_pos, time = 250})
	transition.to(self.text, {y = self.hidden_y_pos, time = 250})
end

function scene:create(event)
	local background = Background:new({90, 200, 170}) --210, 90, 90
	score = Scoreboard:new()
	view_hb = View:new({170, 150, 100}, true) --100, 100, 100
	local testing_views = false
	local actual_view = view_hb
	local view_first_game
	local view_second_game
	local view_third_game
	local view_fourth_game
	local view_fifth_game
	local welcome = display.newEmbossedText(view_hb.group, "Feliz Cumple Bae", view_hb.rect.x, view_hb.rect.y, font_bold, font_size + 3)
	local music_rect = display.newRoundedRect(view_hb.group, center_x + screen_width, 20, screen_width - 70, 50, 10)
	music_rect:setFillColor(0.4, 0.4, 0.7, 0.7)
	local music_img = display.newImageRect(view_hb.group, "images/music.png", 32, 32)
	music_img.x = music_rect.x - music_rect.width/2 + 28
	music_img.y = music_rect.y
	local music_text = display.newText(view_hb.group, "fatruxi - First of the year", music_img.x + music_img.width * 3.2, music_img.y, font, 18)
	local music = audio.loadSound( "fotd.mpeg" )
	audio.play(music)
	welcome.rotation = -30

	local view_win = View:new({150, 100, 100}, true)
	local win_message_options = {
		text = "Bien ahi!\n\n	¡¡"..win_code.."¡¡\n\nEntregale este codigo a la persona sexy mas cercana",
		x = view_win.rect.x,
		y = view_win.rect.y / 1.8 + text_margin_top + (view_hb.rect.height * 1.3 - view_win.rect.height),
		width = view_win.rect.width - text_margin_horizontal,
		font = font_bold,
		fontSize = text_font_size,
		align = "left"
	}
	local win_message = display.newEmbossedText(win_message_options)
	view_win.group:insert(win_message)

	local view_first_message = View:new({200, 200, 200}, true)
	view_first_message.rect.height = view_first_message.rect.height * 0.7
	local first_message_options = {
		text = "Se que no vivimos en el pasado, pero nos gusta recordar lindas anecdotas...",
		x = view_first_message.rect.x,
		y = view_first_message.rect.y / 1.8 + text_margin_top + (view_hb.rect.height - view_first_message.rect.height),
		width = view_first_message.rect.width - text_margin_horizontal,
		font = font_bold,
		fontSize = text_font_size,
		align = "left"
	}
	local first_message = display.newEmbossedText(first_message_options)
	view_first_message.group:insert(first_message)

---------
	view_first_game = View:new({100, 100, 100}, true)
	view_first_game.rect.height = view_first_game.rect.height * 0.65
	local text_first_game_options = {
		text = "¿Te acordas cuando no teniamos tabaco, y me pediste que te echara nicotina liquida en el brazo?",
		x = view_first_game.rect.x,
		y = view_first_game.rect.y / 2 + text_margin_top + (view_hb.rect.height - view_first_game.rect.height),
		width = view_first_game.rect.width - text_margin_horizontal,
		font = font_bold,
		fontSize = text_font_size,
		align = "left"
	}
	local text_first_game = display.newEmbossedText(text_first_game_options)
	view_first_game.group:insert(text_first_game)

	instructions_first_game = Instructions:new("Acerta 3 veces al punto ro jo sin derramar")

	minigame[1] = {}
	minigame[1].images = display.newGroup()
	minigame[1].arm = display.newImageRect(minigame[1].images, "images/arm.png", screen_width, 200)
	minigame[1].arm.x = center_x
	minigame[1].arm.y = center_y
	minigame[1].dot = display.newCircle(minigame[1].images, minigame[1].arm.x, minigame[1].arm.y, 16) --18
	minigame[1].dot:setFillColor(240/255, 120/255, 120/255)
	local triangle_size = 30
	triangle_margin_bottom = triangle_size * 3
	minigame[1].triangle = display.newPolygon(minigame[1].images, 0, minigame[1].arm.y - triangle_margin_bottom, {
		minigame[1].arm.x - triangle_size/2, minigame[1].arm.y - triangle_size/2,
		minigame[1].arm.x + triangle_size/2, minigame[1].arm.y - triangle_size/2,
		minigame[1].arm.x, minigame[1].arm.y + triangle_size/2,		
	})
	minigame[1].triangle:setFillColor(0)
	minigame[1].triangle.rotation = 30
	minigame[1].images.alpha = 0
	minigame[1].triangle_animation_phase = 1
	minigame[1].drop = display.newCircle(minigame[1].images, minigame[1].triangle.x, minigame[1].triangle.y + 40, 10)
	minigame[1].drop:setFillColor(0.2, 0.2, 0.7)
	minigame[1].drop.alpha = 0
	minigame[1].won = false
	minigame[1].checkTarget = function()
		if (math.abs(minigame[1].drop.x - minigame[1].dot.x) < 15) then
			score:set(score.total + 1)
			if (score.total == 3) and not minigame[1].won then
				minigame[1].tap_rect:removeEventListener("tap", minigame[1].on_tap)
				minigame[1].won = true
				minigame[1].tap_rect.isHitTestable = false
				minigame[1].triangle_animation_phase = 0
				transition.to(minigame[1].images, {alpha = 0, time=350})
				instructions_first_game:hide()
				score:hide()
				score:reset()
				view_win:toLeft()
				actual_view = view_second_game
				button_next:show()
			end
		else
			score:reset()
		end
	end

	minigame[1].on_tap = function()
		minigame[1].drop.x = minigame[1].triangle.x
		minigame[1].drop.y = minigame[1].triangle.y
		transition.to(minigame[1].drop, {y = minigame[1].drop.y + 100, alpha = 0.6, time = 200, transition = easing.inOutQuad, onComplete = minigame[1].checkTarget})
	end
	minigame[1].tap_rect = display.newRect(center_x, center_y, screen_width, screen_height)
	minigame[1].tap_rect.isVisible = false
	minigame[1].tap_rect.isHitTestable = false
	minigame[1].triangle_animation = function()
		if minigame[1].triangle_animation_phase == 1 then
			minigame[1].triangle_animation_phase = 2
			transition.to(minigame[1].triangle, {x = minigame[1].triangle.x + screen_width - triangle_size, transition = easing.outInCubic, time = 500, onComplete = minigame[1].triangle_animation})
		elseif minigame[1].triangle_animation_phase == 2 then
			minigame[1].triangle_animation_phase = 1
			transition.to(minigame[1].triangle, {x = minigame[1].triangle.x - screen_width + triangle_size, transition = easing.inOutCubic, time = 500, onComplete = minigame[1].triangle_animation})
		end
	end
	minigame[1].tap_rect:addEventListener("tap", minigame[1].on_tap)
---------

	view_second_game = View:new({100, 100, 100}, true)
	view_second_game.rect.height = view_second_game.rect.height * 0.65
	local text_second_game_options = {
		text = "¿Te acordas cuando nos perdimos 4 horas en el Recoleta Mall, buscando los banios re locos?",
		x = view_second_game.rect.x,
		y = view_second_game.rect.y / 2 + text_margin_top + (view_hb.rect.height - view_second_game.rect.height),
		width = view_second_game.rect.width - text_margin_horizontal,
		font = font_bold,
		fontSize = text_font_size,
		align = "left"
	}
	local text_second_game = display.newEmbossedText(text_second_game_options)
	view_second_game.group:insert(text_second_game)

	instructions_second_game = Instructions:new("Hace que lleguen al piso del banio antes de que se hagan las 10 am")

	minigame[2] = {}
	minigame[2].images = display.newGroup()
	minigame[2].stairs = display.newImageRect(minigame[2].images, "images/stairs.png", screen_width + 50, 275)
	minigame[2].stairs.x = center_x
	minigame[2].stairs.y = center_y
	minigame[2].toilet_sign = display.newImageRect(minigame[2].images, "images/toilet_sign.png", 60, 40)
	minigame[2].toilet_sign.x = view_margin_left * 2.5 + view_margin_left
	minigame[2].toilet_sign.y = minigame[2].stairs.y * 0.5
	minigame[2].toilet_sign.rotation = -17
	minigame[2].girl = display.newImageRect(minigame[2].images, "images/girl.png", 55, 50) --28 35 | 55 50
	minigame[2].girl.x = minigame[2].stairs.x * 1.5 + 55
	minigame[2].girl.y = minigame[2].stairs.y * 1.5 - 13
	minigame[2].girl.rotation = 10
	minigame[2].guy = display.newImageRect(minigame[2].images, "images/guy.png", 35, 40) --35 40
	minigame[2].guy.x = minigame[2].stairs.x * 1.5 + 5
	minigame[2].guy.y = minigame[2].stairs.y * 1.5
	minigame[2].guy.rotation = 10
	minigame[2].images.alpha = 0
	minigame[2].tap_count = 0
	minigame[2].won = false
	minigame[2].on_tap = function()
		minigame[2].girl.x = minigame[2].girl.x - 2
		minigame[2].girl.y = minigame[2].girl.y - 3
		minigame[2].girl.rotation = minigame[2].girl.rotation * (-1)
		minigame[2].guy.x = minigame[2].guy.x - 2
		minigame[2].guy.y = minigame[2].guy.y - 3
		minigame[2].guy.rotation = minigame[2].guy.rotation * (-1)
		minigame[2].tap_count = minigame[2].tap_count + 1
		local tap_count = math.abs(minigame[2].tap_count/10)
		local rounded_tap_count = math.floor(tap_count)
		if rounded_tap_count > 0 then
			if not (score.text.text == "Piso: "..rounded_tap_count) then
				score.text.text = "Piso: "..rounded_tap_count
			end
		end
		local tc = 8.2
		if testing_views then
			tc = 0.5
		end
		if tap_count == tc and not minigame[2].won then
			minigame[2].won = true
			minigame[2].tap_rect:removeEventListener("tap", minigame[2].on_tap)
			minigame[2].tap_rect.isHitTestable = false
			minigame[2].clock_hour = 0
			transition.to(minigame[2].images, {alpha = 0, time=350})
			instructions_second_game:hide()
			score:hide()
			score:reset()
			win_message.text = "Nuevo codigo!\n\n	¡¡BAE 411¡¡\n\nPensaste bien... mas regalos!!"
			view_win:toLeft()
			actual_minigame = false
			actual_view = view_third_game
			button_next:show()
		end
	end
	minigame[2].time_rect = display.newRect(minigame[2].images, center_x, screen_height - font_size, screen_width, font_size * 1.3)
	minigame[2].time_rect:setFillColor(1, 1, 1, 0.5)
	minigame[2].time_text = display.newEmbossedText(minigame[2].images, "1 A.M.", center_x, screen_height - font_size, font, font_size)
	minigame[2].tap_rect = display.newRect(center_x, center_y, screen_width, screen_height)
	minigame[2].tap_rect.isVisible = false
	minigame[2].tap_rect.isHitTestable = false
	minigame[2].tap_rect:addEventListener("tap", minigame[2].on_tap)
	minigame[2].clock_hour = 1
	minigame[2].clock_animation = function()
		if minigame[2].clock_hour > 0 then
			if minigame[2].clock_hour < 12 then
				minigame[2].clock_hour = minigame[2].clock_hour + 1
				minigame[2].time_text:setFillColor(1, 1 - (minigame[2].clock_hour - 1) * 0.04, 1 - (minigame[2].clock_hour - 1) * 0.08)
			else
				score.text.text = "Piso: PB"
				minigame[2].tap_count = 0
				minigame[2].clock_hour = 1
				minigame[2].girl.x = minigame[2].stairs.x * 1.5 + 55
				minigame[2].girl.y = minigame[2].stairs.y * 1.5 - 13
				minigame[2].guy.x = minigame[2].stairs.x * 1.5 + 5
				minigame[2].guy.y = minigame[2].stairs.y * 1.5
				minigame[2].time_text:setFillColor(1)
			end
			minigame[2].time_text.text = minigame[2].clock_hour.." A.M."
			minigame[2].clock_timer = timer.performWithDelay(800, minigame[2].clock_animation)
		end
	end
	minigame[2].clock_animation()
---------

	view_third_game = View:new({100, 100, 100}, true)
	view_third_game.rect.height = view_third_game.rect.height * 0.65
	local text_third_game_options = {
		text = "¿Te acordas cuando me pediste que me quedara en tu casa, en la puerta de Belgrano?",
		x = view_third_game.rect.x,
		y = view_third_game.rect.y / 2 + text_margin_top + (view_hb.rect.height - view_third_game.rect.height),
		width = view_third_game.rect.width - text_margin_horizontal,
		font = font_bold,
		fontSize = text_font_size,
		align = "left"
	}
	local text_third_game = display.newEmbossedText(text_third_game_options)
	view_third_game.group:insert(text_third_game)
	instructions_third_game = Instructions:new("Convence a Napo de que se quede")
	minigame[3] = {}
	minigame[3].images = display.newGroup()
	minigame[3].dialog = display.newRect(minigame[3].images, center_x, 140, screen_width, 70)
	minigame[3].dialog:setFillColor(0.8, 0.8, 0.8, 0.6)
	minigame[3].text = display.newEmbossedText(minigame[3].images, "Llegamos... me despido!", minigame[3].dialog.x + 15, minigame[3].dialog.y, font, 20)
	minigame[3].guy_face = display.newImageRect(minigame[3].images,"images/guy-face.png", 60, 60)
	minigame[3].guy_face.x = 50
	minigame[3].guy_face.y = 140
	minigame[3].images.alpha = 0
	minigame[3].button = {}
	minigame[3].question = 1
	minigame[3].answer = 1
	minigame[3].won = false
	minigame[3].button_on_press = function(event, id)
		if (event.phase == "ended") then
			if (id == minigame[3].answer) then
				minigame[3].question = minigame[3].question + 1
				score:set(score.total + 1)
				if (minigame[3].question == 2) then
					minigame[3].text.text = "Hay que dormir, es tarde!"
					minigame[3].button[1].text.text = "Hoy hay eclipse asi que da igual"
					minigame[3].button[2].text.text = "Pues yo no duermo xD"
					minigame[3].button[3].text.text = "Viejo chot*"
					minigame[3].button[4].text.text = "No es tarde, mas bien es temprano"
					minigame[3].answer = 4
				elseif (minigame[3].question == 3) then
					minigame[3].text.text = "Y si tus padres dicen algo?"
					minigame[3].button[1].text.text = "Me la sud*n je"
					minigame[3].button[2].text.text = "Estan durmiendoo"
					minigame[3].button[3].text.text = "Ehmm, no hablan espaniol"
					minigame[3].button[4].text.text = "Dire que sos el electricista"
					minigame[3].answer = 2
				elseif (minigame[3].question == 4) then
					minigame[3].text.text = "No eran estrictos??"
					minigame[3].button[1].text.text = "Llorar"
					minigame[3].button[2].text.text = "Chinga tu madre"
					minigame[3].button[3].text.text = "Nuuuu"
					minigame[3].button[4].text.text = "Correr"
					minigame[3].answer = 1
				elseif (minigame[3].question == 5) then
					minigame[3].text.text = "Vale, puede que me quede..."
					minigame[3].button[1].text.text = "Ok, me cago asi que canto pri el banio"
					minigame[3].button[2].text.text = "Mochi estara contenta de morderte"
					minigame[3].button[3].text.text = "Subamos! tengo coca y play 4"
					minigame[3].button[4].text.text = "Cuidado el paco digo lejia de la escalera"
					minigame[3].answer = 3
				else
					if not minigame[3].won then
						minigame[3].won = true
						transition.to(minigame[3].images, {alpha = 0, time=350})
						instructions_third_game:hide()
						score:hide()
						score:reset()
						win_message.text = "Ganaste de vuelta!\n\n	¡¡NAP 088¡¡\n\nYa sabes a quien pasarle el codigo"
						view_win:toLeft()
						actual_minigame = false
						actual_view = view_fourth_game
						button_next:show()
					end
				end
			else
				score:reset()
				minigame[3].question = 1
				minigame[3].answer = 1
				minigame[3].text.text = "Llegamos... me despido!"
				minigame[3].button[1].text.text = "Quedate!"
				minigame[3].button[2].text.text = "Vale, a dormir"
				minigame[3].button[3].text.text = "Me pica una oreja lol"
				minigame[3].button[4].text.text = "Wingardium leviosa"
			end
		end
	end
	minigame[3].button[1] = Button:new(minigame[3].images, center_x - button_width, center_y - button_height - button_margin_bottom, button_width * 1.8, button_height, {220, 85, 167}, true, "Quedate!", function(event) minigame[3].button_on_press(event, 1) end)
	minigame[3].button[1]:setPos(center_x, center_y - button_height)
	minigame[3].button[2] = Button:new(minigame[3].images, center_x + button_width, center_y - button_height - button_margin_bottom, button_width * 1.8, button_height, {220, 85, 167}, true, "Vale, a dormir", function(event) minigame[3].button_on_press(event, 2) end)
	minigame[3].button[2]:setPos(center_x, center_y + button_margin_bottom * 0.25)
	minigame[3].button[3] = Button:new(minigame[3].images, center_x - button_width, center_y + button_height + button_margin_bottom, button_width * 1.8, button_height, {220, 85, 167}, true, "Me pica una oreja lol", function(event) minigame[3].button_on_press(event, 3) end)
	minigame[3].button[3]:setPos(center_x, center_y + button_height + button_margin_bottom * 0.5)
	minigame[3].button[4] = Button:new(minigame[3].images, center_x + button_width, center_y + button_height + button_margin_bottom, button_width * 1.8, button_height, {220, 85, 167}, true, "Wingardium leviosa", function(event) minigame[3].button_on_press(event, 4) end)
	minigame[3].button[4]:setPos(center_x, center_y + button_height * 2 + button_margin_bottom * 0.75)
---------
	view_fourth_game = View:new({100, 100, 100}, true)
	view_fourth_game.rect.height = view_fourth_game.rect.height * 0.5
	local text_fourth_game_options = {
		text = "¿Te acordas cuando haciamos tours por los telos de capital?",
		x = view_fourth_game.rect.x,
		y = view_fourth_game.rect.y / 2.4 + (view_hb.rect.height - view_fourth_game.rect.height),
		width = view_fourth_game.rect.width - text_margin_horizontal,
		font = font_bold,
		fontSize = text_font_size,
		align = "left"
	}
	local text_fourth_game = display.newEmbossedText(text_fourth_game_options)
	view_fourth_game.group:insert(text_fourth_game)
	instructions_fourth_game = Instructions:new("Recorre los telos sin salir del camino y sin levantar el dedo")
	minigame[4] = {}
	minigame[4].images = display.newGroup()
	minigame[4].caba = display.newImageRect(minigame[4].images, "images/caba.png", 250, 250)
	minigame[4].caba.x = center_x
	minigame[4].caba.y = center_y
	minigame[4].road = {}
	minigame[4].road[1] = display.newRect(minigame[4].images, center_x, center_y - 50, 100, 25)
	minigame[4].road[1]:setFillColor(0.6)
	minigame[4].road[2] = display.newRect(minigame[4].images, center_x - minigame[4].road[1].width/2, center_y, 100, 20)
	minigame[4].road[2].rotation = 90
	minigame[4].road[2]:setFillColor(0.6)
	minigame[4].road[3] = display.newRect(minigame[4].images, center_x, center_y + minigame[4].road[2].height * 2, 100, 25)
	minigame[4].road[3]:setFillColor(0.6)
	minigame[4].dot = {}
	minigame[4].dot[1] = display.newCircle(minigame[4].images, center_x - minigame[4].road[1].width/2.3, center_y - 50, 15)
	minigame[4].dot[1]:setFillColor(0.8, 0.4, 0.4)
	minigame[4].dot[2] = display.newCircle(minigame[4].images, center_x - minigame[4].road[1].width/2.3, center_y + minigame[4].road[2].height * 2.2, 15)
	minigame[4].dot[2]:setFillColor(0.8, 0.4, 0.4)
	minigame[4].dot[3] = display.newCircle(minigame[4].images, center_x + minigame[4].road[1].width/2.3, center_y + minigame[4].road[2].height * 2.2, 15)
	minigame[4].dot[3]:setFillColor(0.8, 0.4, 0.4)
	minigame[4].guy_running = display.newImageRect(minigame[4].images, "images/guy-running.png", 25, 25)
	minigame[4].guy_running.x = minigame[4].road[1].x + minigame[4].road[1].width / 2 + 30
	minigame[4].guy_running.y = minigame[4].road[1].y
	minigame[4].girl_running = display.newImageRect(minigame[4].images, "images/girl-running.png", 25, 25)
	minigame[4].girl_running.x = minigame[4].road[1].x + minigame[4].road[1].width / 2
	minigame[4].girl_running.y = minigame[4].road[1].y
	minigame[4].images.alpha = 0
	minigame[4].won = false
	minigame[4].onRoadTouch = function(event)
		if event.phase == "moved" or event.phase == "began" then
			transition.to(minigame[4].girl_running, {x = event.x, y = event.y, time = 100})
			transition.to(minigame[4].guy_running, {x = event.x + 30, y = event.y, time = 100})
			if ((minigame[4].girl_running.x > minigame[4].dot[3].x - 10) and
				(minigame[4].girl_running.x < minigame[4].dot[3].x + 10) and
				(minigame[4].girl_running.y > minigame[4].dot[3].y - 10) and
				(minigame[4].girl_running.y < minigame[4].dot[3].y + 10)) then
				if not minigame[4].won then
					minigame[4].won = true
					transition.to(minigame[4].images, {alpha = 0, time=350})
					instructions_fourth_game:hide()
					win_message.text = "On fire!\n\n	¡¡OMG 666¡¡\n\nSiguen los regalos iujuuu ¡¡¡¡¡"
					view_win:toLeft()
					actual_minigame = false
					actual_view = view_fifth_game
					button_next:show()
				end
			end
		else
			transition.to(minigame[4].girl_running, {x = minigame[4].road[1].x + minigame[4].road[1].width / 2, y = minigame[4].road[1].y, time = 100})
			transition.to(minigame[4].guy_running, {x = minigame[4].road[1].x + minigame[4].road[1].width / 2 + 30, y = minigame[4].road[1].y, time = 100})
		end
	end
	for i = 1, 3 do
		minigame[4].road[i]:addEventListener("touch", minigame[4].onRoadTouch)
	end
	---------
	view_fifth_game = View:new({100, 100, 100}, true)
	view_fifth_game.rect.height = view_fifth_game.rect.height * 0.5
	local text_fifth_game_options = {
		text = "¿Te acordas de las partidas de te jo en Sanber?",
		x = view_fifth_game.rect.x,
		y = view_fifth_game.rect.y / 2.4 + (view_hb.rect.height - view_fifth_game.rect.height),
		width = view_fifth_game.rect.width - text_margin_horizontal,
		font = font_bold,
		fontSize = text_font_size,
		align = "left"
	}
	local text_fifth_game = display.newEmbossedText(text_fifth_game_options)
	view_fifth_game.group:insert(text_fifth_game)
	instructions_fifth_game = Instructions:new("Elegi el mejor lugar para colocar al wachin")
	minigame[5] = {}
	minigame[5].images = display.newGroup()
	local emitterParams = {
		startColorAlpha = 1,
		startParticleSizeVariance = 53.47,
		startColorGreen = 0.3031555,
		yCoordFlipped = -1,
		blendFuncSource = 770,
		rotatePerSecondVariance = 153.95,
		particleLifespan = 0.7237,
		tangentialAcceleration = -144.74,
		finishColorBlue = 0,
		finishColorGreen = 1,
		blendFuncDestination = 1,
		startParticleSize = 50.95,
		startColorRed = 0,
		textureFileName = "images/particle.jpg",
		startColorVarianceAlpha = 1,
		maxParticles = 256,
		finishParticleSize = 64,
		duration = -1,
		finishColorRed = 1,
		maxRadiusVariance = 72.63,
		finishParticleSizeVariance = 64,
		gravityy = 5,
		speedVariance = 90.79,
		tangentialAccelVariance = -92.11,
		angleVariance = -142.62,
		angle = -244.11
	}
	minigame[5].emitter = display.newEmitter( emitterParams )
	minigame[5].emitter:stop()
	minigame[5].rect = display.newRoundedRect(minigame[5].images, center_x, center_y, 200, 250, 15)
	minigame[5].rect:setFillColor(0.6, 0.6, 0.9, 0.8)
	minigame[5].images.alpha = 0
	minigame[5].redEmitter = function(event)
		minigame[5].emitter.x = event.x
		minigame[5].emitter.y = event.y
		minigame[5].emitter.finishColorBlue = 0
		minigame[5].emitter.finishColorGreen = 0
		minigame[5].emitter.startColorRed = 1
		minigame[5].emitter:start()
	end
	minigame[5].greenEmitter = function(event)
		minigame[5].emitter.x = event.x
		minigame[5].emitter.y = event.y
		minigame[5].emitter.finishColorBlue = 0
		minigame[5].emitter.finishColorGreen = 1
		minigame[5].emitter.startColorRed = 0
		minigame[5].emitter:start()
		transition.to(minigame[5].images, {alpha = 0, time=350})
		instructions_fifth_game:hide()
		win_message.text = "Perfecto!\n\n	¡¡SON 420¡¡\n\nLast but not least... vas a convidarme, no?"
		minigame[5].rect_final = display.newRect(center_x, 0,screen_width, 220)
		minigame[5].rect_final:setFillColor(0.5, 0.5, 0.5, 0.7)
		minigame[5].text1 = display.newEmbossedText("Perfecto!", center_x, 10, font, 22)
		minigame[5].text2 = display.newEmbossedText("¡¡SON 420¡¡", center_x, 30, font, 22)
		minigame[5].text3 = display.newEmbossedText("Last but not least... vas a convidarme, no?", center_x, 50, font, 21)
		minigame[5].text4 = display.newEmbossedText("Te amo mucho Fati, espero lo disfrutes", center_x, 90, font, 22)
		transition.to(view_win.group, {x = center_x, time=350})
		transition.to(view_win.group, {y = center_y, time=350})
		print(view_win.group.x)
		--actual_minigame = false
		actual_view = view_win
		--button_next:show()
	end
	minigame[5].mountain = display.newImageRect(minigame[5].images, "images/mountain.jpg", 100, 70)
	minigame[5].mountain.x = center_x
	minigame[5].mountain.y = center_y - 75
	minigame[5].street = display.newImageRect(minigame[5].images, "images/street.jpg", 100, 70)
	minigame[5].street.x = center_x
	minigame[5].street.y = center_y
	minigame[5].beach = display.newImageRect(minigame[5].images, "images/beach.jpg", 100, 70)
	minigame[5].beach.x = center_x
	minigame[5].beach.y = center_y + 75
	minigame[5].mountain:addEventListener("tap", minigame[5].redEmitter)
	minigame[5].street:addEventListener("tap", minigame[5].redEmitter)
	minigame[5].beach:addEventListener("tap", minigame[5].greenEmitter)
	---------
	actual_minigame = false
	local buttonNextPress = function(event)
		if (event.phase == "ended") then
			--if not actual_view == view_end_game then
				actual_view:toLeft()
			--end
			if actual_view == view_hb then
				if testing_views then --ONLY FOR DEV/TESTING PHASE
					actual_view = view_fifth_game
				else
					actual_view = view_first_message
				end
				actual_view:toLeft()
			elseif actual_view == view_first_message then
				actual_view = view_first_game
				actual_view:toLeft()
			elseif actual_view == view_first_game then
				--actual_view = view_second_game
				instructions_first_game:show()
				score:show()
				minigame[1].triangle_animation()
				minigame[1].tap_rect.isHitTestable = true
				button_next:hide()
				transition.to(minigame[1].images, {alpha = 1, time=350})
			elseif actual_view == view_second_game then
				if not testing_views then
					view_win:toRight()
				end
				if actual_minigame then
					instructions_second_game:show()
					score.text.text = "Piso: PB"
					score:show()
					button_next:hide()
					transition.to(minigame[2].images, {alpha = 1, time=350})
					minigame[2].tap_rect.isHitTestable = true
				end
				actual_minigame = true
			elseif actual_view == view_third_game then
				if not testing_views then
				end
				if actual_minigame then
					instructions_third_game:show()
					score:reset()
					score:show()
					button_next:hide()
					transition.to(minigame[3].images, {alpha = 1, time=350})
				else
					view_win:toRight()
					actual_view:toLeft()
					actual_minigame = true
				end
			elseif actual_view == view_fourth_game then
				if not testing_views then
				end
				if actual_minigame then
					instructions_fourth_game:show()
					button_next:hide()
					transition.to(minigame[4].images, {alpha = 1, time=350})
				else
					view_win:toRight()
					actual_view:toLeft()
					actual_minigame = true
				end
			elseif actual_view == view_fifth_game then
				if not testing_views then
				end
				if actual_minigame then
					instructions_fifth_game:show()
					button_next:hide()
					transition.to(minigame[5].images, {alpha = 1, time=350})
				else
					view_win:toRight()
					actual_view:toLeft()
					actual_minigame = true
				end
			else
				--view_win:toLeft()
			end
		end
	end
	button_next = Button:new(background.group, screen_width - button_width - button_margin_right, screen_height - button_height - button_margin_bottom, button_width, button_height, {200, 170, 90}, true, "CONTINUAR", buttonNextPress)
	view_hb:toLeft()
end

function scene:show(event)
	--
end

function scene:hide(event)
	--
end

function scene:destroy(event)
	--
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene