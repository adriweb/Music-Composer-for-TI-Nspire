-- Music Composer for TI-Nspire
-- Adriweb 2011
-- Version 0.5a

-- Visit   http://www.inspired-lua.org   for more information about TI-Nspire Lua programming !

-- final string syntax : table of "[Note][Octave][Length][Alteration]", for example : "C342"
-- with C the note, 3 for the 3rd octave (middle of keyboard I think ?), 4 for the eight-note length
-- (whole note is 1, half is 2, fourth is 3, sixteenth is 5), 2 for sharp (1 is flat, 0 is natural)

-- We are assuming it's all binary (2/4, 3/4, 4/4)
-- I'll do later for ternary.

-- TODO :
----------
-- ternary support
-- Other "screens" than menu and new music
-- loading
-- delete (backspacekey)
-- playMusic and playNote
-- better graphics
-- scrolling
-- toNbr() function


--------------- Globals etc.

gc = platform.gc()
needMenu = true
needHelp = false
tile = ""
creating = false
editing = false
possibleToEncode = false
currentNote = {x,y,octave,length,alteration,rank} -- see init() for default values
saveCurrentNote = {} -- will be a copy of the currentNote table (for the init() "bug" fix)
currentMusic = {} -- will be the list of encoded notes
notesLengths = { 180, 90, 45, 24, 12 } -- the width space between notes. same order as the notes lengths (1 to 5)
notesLengthsMusic = { 4, 2, 1, 0.5, 0.25 } -- the real duration of the notes (number of beats)

--------------- End Globals


--------------- BetterLuaAPI

function copyTable(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

function deepcopy(t) -- This function recursively copies a table's contents, and ensures that metatables are preserved. That is, it will correctly clone a pure Lua object.
	if type(t) ~= 'table' then return t end
	local mt = getmetatable(t)
	local res = {}
	for k,v in pairs(t) do
		if type(v) == 'table' then
		v = deepcopy(v)
		end
	res[k] = v
	end
	setmetatable(res,mt)
	return res
end -- from http://snippets.luacode.org/snippets/Deep_copy_of_a_Lua_Table_2

function test(arg)
	if type(arg) == "boolean" then
		if arg == true then
			return 1
		elseif arg == false then
			return 0
		end
	else
		print("error in test() call - not a bool")
	end
end

function toNbr(str)
	if (tostring(tonumber(str)) == "nil") then return -99 else return tonumber(str) end
	-- to redo with regexp in string.gmatch
end

function refresh()
	platform.window:invalidate()
end

function pww()
	return platform.window:width()
end

function pwh()
	return platform.window:height()
end

function drawPoint(x, y)
	platform.gc():fillRect(x, y, 1, 1)
end

function drawCircle(x, y, diameter)
	platform.gc():drawArc(x - diameter/2, y - diameter/2, diameter,diameter,0,360)
end

function drawFilledCircle(x, y, diameter)
	platform.gc():fillArc(x - diameter/2, y - diameter/2, diameter,diameter,0,360)
end

function drawCenteredString(str)
	platform.gc():drawString(str, (pww() - platform.gc():getStringWidth(str)) / 2, pwh() / 2, "middle")
end

function setColor(theColor)
	theColor = string.lower(theColor)
	platform.gc():setColorRGB(0,0,0) -- set black as default is nothing else valid is found
	if theColor == "blue" then platform.gc():setColorRGB(0,0,255)
	elseif theColor == "gray" or theColor == "grey" then platform.gc():setColorRGB(127,127,127)
	elseif theColor == "green" then platform.gc():setColorRGB(0,128,0)
	elseif theColor == "orange" then platform.gc():setColorRGB(255,165,0)
	elseif theColor == "red" then platform.gc():setColorRGB(255,0,0)
	elseif theColor == "white" then platform.gc():setColorRGB(255,255,255)
	elseif theColor == "yellow" then platform.gc():setColorRGB(255,255,0)
	end	
end

function verticalBar(x)
	platform.gc():drawLine(x,1,x,platform.window:height())
end

function horizontalBar(y)
	platform.gc():drawLine(1,y,platform.window:width(),y)
end

function drawSquare(x,y,l)
	platform.gc():drawPolyLine({(x-l/2),(y-l/2), (x+l/2),(y-l/2), (x+l/2),(y+l/2), (x-l/2),(y+l/2), (x-l/2),(y-l/2)})
end

function drawRoundRect(x,y,width,height,radius)
	x = x-width/2  -- let the center of the square be the origin (x coord)
	y = y-height/2 -- same for y coord
	if radius > height/2 then radius = height/2 end -- avoid drawing cool but unexpected shapes. This will draw a circle (max radius)
	platform.gc():drawLine(x + radius, y, x + width - (radius), y);
	platform.gc():drawArc(x + width - (radius*2), y + height - (radius*2), radius*2, radius*2, 270, 90);
	platform.gc():drawLine(x + width, y + radius, x + width, y + height - (radius));
	platform.gc():drawArc(x + width - (radius*2), y, radius*2, radius*2,0,90);
	platform.gc():drawLine(x + width - (radius), y + height, x + radius, y + height);
	platform.gc():drawArc(x, y, radius*2, radius*2, 90, 90);
	platform.gc():drawLine(x, y + height - (radius), x, y + radius);
	platform.gc():drawArc(x, y + height - (radius*2), radius*2, radius*2, 180, 90);
end

function fillRoundRect(x,y,wd,ht,radius)  -- wd = width and ht = height -- renders badly when transparency (alpha) is not at maximum >< will re-code later
	if radius > ht/2 then radius = ht/2 end -- avoid drawing cool but unexpected shapes. This will draw a circle (max radius)
    platform.gc():fillPolygon({(x-wd/2),(y-ht/2+radius), (x+wd/2),(y-ht/2+radius), (x+wd/2),(y+ht/2-radius), (x-wd/2),(y+ht/2-radius), (x-wd/2),(y-ht/2+radius)})
    platform.gc():fillPolygon({(x-wd/2-radius+1),(y-ht/2), (x+wd/2-radius+1),(y-ht/2), (x+wd/2-radius+1),(y+ht/2), (x-wd/2+radius),(y+ht/2), (x-wd/2+radius),(y-ht/2)})
    x = x-wd/2  -- let the center of the square be the origin (x coord)
	y = y-ht/2 -- same
	platform.gc():fillArc(x + wd - (radius*2), y + ht - (radius*2), radius*2, radius*2, 1, -91);
    platform.gc():fillArc(x + wd - (radius*2), y, radius*2, radius*2,-2,91);
    platform.gc():fillArc(x, y, radius*2, radius*2, 85, 95);
    platform.gc():fillArc(x, y + ht - (radius*2), radius*2, radius*2, 180, 95);
end

function drawLinearGradient(r1,g1,b1,r2,g2,b2)
 	-- not sure if it's a good idea...
end

---------------  End of BetterLuaAPI


function on.paint(gc)
	setColor("black")
	gc:drawString(" mem=" .. tostring(math.ceil(collectgarbage("count")*1.024)) .. " kbytes", 200, 182, "top")
	gc:drawString(" Music Composer - Adriweb 2011",64,0,"top")
		
	if needMenu then
		menu(gc)
	elseif needHelp then
		help(gc)
	else
		drawMain(gc,0)
	end
end

function on.help()
	-- todo
	print("I'm in the help frame")
	needHelp = true
	refresh()
end

function on.escapeKey()
	saveAlert()
	needMenu = true
	refresh()
end

function on.arrowKey(key)
	if key == "down" then
		if currentNote.y < 128 then currentNote.y = currentNote.y + 6 end
		if currentNote.y == 92 then currentNote.octave = currentNote.octave - 1 end
	elseif key == "up" then
		if currentNote.y > 62 then currentNote.y = currentNote.y - 6 end
		if currentNote.y == 86 then currentNote.octave = currentNote.octave + 1 end
	end
	print("--currentNote.x = ",currentNote.x)
	print("--currentNote.y = ",currentNote.y)
	refresh()
end

function on.charIn(ch)
	if editing then
		if (toNbr(ch) > 0 and toNbr(ch) < 6) then currentNote.length = toNbr(ch) end
		if ch == "*" then
			if currentNote.octave > 2 then currentNote.octave = currentNote.octave - 1 end
		end
		if ch == "/" then
			if currentNote.octave < 5 then currentNote.octave = currentNote.octave + 1 end
		end
		if ch == "-" then
			if currentNote.alteration > 0 then currentNote.alteration = currentNote.alteration - 1 end
		end
		if ch == "+" then
			if currentNote.alteration < 2 then currentNote.alteration = currentNote.alteration + 1 end
		end
	elseif needMenu then
		if (toNbr(ch) > 0 and toNbr(ch) < 4) then needMenu = false end
		if ch == "1" then newMusic(gc) end
		if ch == "2" then loadMusic(gc) end
		if ch == "3" then settings(gc) end
	end
	refresh()
end

function on.enterKey() -- a lot to do here ? -- to finish
	if editing then
		if possibleToEncode then
			local where
			if currentNote.rank >= #currentMusic then where = "end" end
			insertEncodedNote(encode(noteFromY(currentNote.y),currentNote.octave,currentNote.length,currentNote.alteration),where)
			currentNote.x = currentNote.x + notesLengths[currentNote.length]
		end
	end
end

function on.timer()
	-- what for ? no idea right now
end

function on.save()
	saveMusic(platform.gc())
end

function on.destroy()
	saveMusic(platform.gc())
end

function on.backspaceKey()
	--todo
	-- delete the note in the currentMusic, at rank currentNote.rank, then refresh with drawExistingNotes()
end

---------------  End of events


---------------  Functions

function menu(gc)
	
	editing = false
	print("i'm in the menu")

	local xmax,ymax

	xmax = pww()
	ymax = pwh()
	
	setColor("black")
	gc:fillRect(xmax/5, ymax/5,3*xmax/5,3*ymax/5)
	
	gc:setColorRGB(200,200,200)
	gc:fillRect(xmax/5+1, ymax/5+1,3*xmax/5-2,3*ymax/5-2)
	
	gc:setColorRGB(0,0,0)
	gc:drawString("Choose Action : ",xmax*0.5-44,48,"top")
		
	makeButton(gc,"1.  New Music",xmax*0.5,88)
	makeButton(gc,"2.  Open Existing",xmax*0.5,115)
	makeButton(gc,"3.  Settings...",xmax*0.5,142)
	
	gc:setColorRGB(100,100,100)
	tmpstr = "(?) or Ctrl-? to show help"
	gc:drawString(tmpstr,0.5*(pww()-gc:getStringWidth(tmpstr)),190,"top")

	tmpstr = "Esc to go to this Menu"
	gc:drawString(tmpstr,0.5*(pww()-gc:getStringWidth(tmpstr)),175,"top")
	
end

function help(gc)
	-- todo
	print("I'm in help")
end

function loadMusic(gc)
	-- todo
	print("loading music")
	init()
	-- faire qqchose du genre currentMusic = var.recall(blablabla) ; drawMain(gc) --
end

function saveMusic(gc)
	-- todo
	print("Saving")
	for i,v in ipairs(currentMusic) do print(i,v) end
	var.store("Music"..tostring(#currentMusic),currentMusic) -- saves as an external math variable.
	-- a changer pour inclure le titre dans le nom
end

function playMusic(gc)
	-- todo
	-- with jimbauwens' routines...
end

function playNote(encodedNote) -- encodedNote = string with full syntax (see top)
	-- todo
	-- also with Jimbauwens' routines...
end

function settings(gc)
	-- todo
	print("I'm in the settings")
end

function newMusic(gc)
	print("New Music...")
	init()
	creating = true
	-- todo properly (input boxes etc.)
	print("  getting settings...")
	--title = var.recallstr("newtitle")
	title = "Essai" -- line to delete - debug only !
	print("  settings are : ","title = ",title)
	creating = false
	drawMain(gc,1)
end

function init()
	print("  **init called**")
	currentNote.x = 70
	currentNote.y = 92
	currentNote.octave = 3
	currentNote.alteration = 0
	currentNote.length = 3 -- 5 = double-croche, 4 = croche, 3 = noire, 2 = blanche, 1 = ronde
	currentNote.rank = 1
end

function drawMain(gc,status)
	local tmpStr
	print("I'm in the main thing")
	drawBackground(gc)
	
	editing = true
	
	-- TODO : draw la clé de sol
	
	if status == 0 then
		saveCurrentNote = copyTable(currentNote) -- voir 2 lignes apres
		drawExistingNotes(gc)
		currentNote = copyTable(saveCurrentNote) -- pour éviter le problème du init dans le drawExistingNotes
	else -- if load
		init()
		currentMusic = {}
	end
	
	possibleToEncode = checkIfEncodingPossible()
	if possibleToEncode then
		drawNote(gc,currentNote.length,currentNote.x,currentNote.y,1,"preview")
	end
	
	if currentNote.alteration == 1 then
		tmpStr = "flat"
	elseif currentNote.alteration == 2 then
		tmpStr = "sharp"
	else
		tmpStr = "natural"
	end
	gc:drawString("Current Note Octave : " .. currentNote.octave,18,165,"top")
	gc:drawString("Current Note Alteration : " .. tmpStr,18,180,"top")
	
	drawSquare(currentNote.x+6,145, 2) -- show which note is currently being edited
	
	refresh()
	print("  end drawMain (refreshed)")
	print("  Current Note Octave : " .. currentNote.octave)
end

function drawBackground(gc)
	print("  drawing the background")
	
	local h
	
	-- Drawing the measure etc.
	for h=1,5 do
		gc:drawLine(52,56+h*12,294,56+h*12)
	end
	
	-- Drawing the notes length template
	for h=1,5 do
		gc:drawRect(18,20+h*22,16,22)
		gc:drawString(tostring(h),8,19+h*22,"top")
		drawNote(gc,h,21,36-6*test(h<3)+h*22,0.5,"")
	end

	print("  done template")
	
	-- highlights the currently chosen note length
	setColor("red")
	gc:drawRect(19,21+currentNote.length*22,14,20)
	setColor("black")
	
end

function drawExistingNotes(gc)
	currentNote.rank = 1
	if #currentMusic > 0 then
		init()
		print("  drawing existing...")
		for i,v in ipairs(currentMusic) do
			currentNote.y = YFromNote(string.sub(v,1,1),tonumber(string.sub(v,2,2)))
			currentNote.octave = tonumber(string.sub(v,2,2))
			currentNote.length = tonumber(string.sub(v,3,3))
			currentNote.alteration = tonumber(string.sub(v,4,4))
			drawNote(gc,currentNote.length,currentNote.x, currentNote.y,1,"done")
			currentNote.x = currentNote.x + notesLengths[currentNote.length] + test(currentNote.length > 4)*12
			currentNote.rank = currentNote.rank + 1
		end
	end
end

function checkIfEncodingPossible()
	--todo
	return true -- debug only, to delete after
end

function saveAlert()
	-- todo
	-- popup sking whether to save or not
end

function noteFromY(ycoord)
	if (ycoord == 128 or ycoord == 86) then return "C" end
	if (ycoord == 122 or ycoord == 80) then return "D" end
	if (ycoord == 116 or ycoord == 74) then return "E" end
	if (ycoord == 110 or ycoord == 68) then return "F" end
	if (ycoord == 104 or ycoord == 62) then return "G" end
	if ycoord == 98 then return "A" end
	if ycoord == 92 then return "B" end
end

function YFromNote(note,octave)
	if note == "C" then
		if octave <= 3 then return 128 else return 86 end
	end
	if note == "D" then
		if octave <= 3 then return 122 else return 80 end
	end
	if note == "E" then
		if octave <= 3 then return 116 else return 74 end
	end
	if note == "F" then
		if octave <= 3 then return 110 else return 68 end
	end
	if note == "G" then
		if octave <= 3 then return 104 else return 62 end
	end
	if note == "A" then return 98 end
	if note == "B" then return 92 end
end

function makeButton(gc,string,x,y)
	gc:setColorRGB(150,150,150)
	drawRoundRect(x,y,140,20,5)
	gc:setColorRGB(50,50,50)
	fillRoundRect(x,y,139,18,5)
	gc:setColorRGB(255,255,255)
	gc:drawString(string,x-gc:getStringWidth(string)*0.5,y-12,"top")
end

function encode(noteName,octave,length,alteration)
	return noteName .. tostring(octave) .. tostring(length) .. tostring(alteration) -- encode using the syntax
end

function insertEncodedNote(encodedNote,where)
	if where == "end" then
		table.insert(currentMusic,encodedNote) -- adds the new note to the table
	end
end

function drawNote(gc,notelen,x,y,scale,state)
	if state == "preview" then setColor("grey") else setColor("black") end

	drawCircle(x+6*scale,y,scale*12) -- le rond de la note
	
	if notelen ~= 1 then
		gc:drawLine(x+test(y>90)*12*scale,y,x+test(y>90)*12*scale,y-test(y>90)*30*scale+test(y<90)*30*scale) -- queue de la note
		if notelen > 2 then
			drawFilledCircle(x+6*scale,y,12*scale) -- le rond rempli de la note
		end
	end
	
--	if currentNote.y > 
-- faire le trait pour upper et lower
	
	if notelen > 3 then
		gc:drawArc(x-8*scale+test(y>90)*12*scale,y-test(y>90)*30*scale+test(y<90)*10*scale,scale*18,scale*20,0,90-180*test(y<90))
		if notelen == 5 then
			gc:drawArc(x-8*scale+test(y>90)*12*scale,y-test(y>90)*20*scale,scale*18,scale*20,0,90-180*test(y<90))
		end
	end
	
	setColor("black")
end

---------------  End of Functions
