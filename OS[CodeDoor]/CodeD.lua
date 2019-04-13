os.loadAPI("System/API/windows")

--ПАРОЛЬ
local password = "12345"

--СКОЛЬКО БУДЕТ ОТКРЫТА ДВЕРЬ
local doorOpenTime = 5

--СКОЛЬКО БУДЕТ НАЖАТА КНОПКА
local buttonPressTime = 0.2

--ПЕРЕМЕННАЯ ТАЙМЕРА
local changePasswordTimer = nil

--РЕЖИМ РАБОТЫ ДИСПЛЕЯ
local mode = "default"

--СКРЫВАТЬ ЛИ ВВОДИМЫЙ ПАРОЛЬ
local hidePassword = "false"

--ОТСЮДА ИЗЛУЧАТЬ СИГНАЛ РЕДА, ЕСЛИ ПАРОЛЬ ВЕРЕН
local redstoneSide = "left"
--А ОТСЮДА, ЕСЛИ НЕ ВЕРЕН
local redstoneSideOnWrongPassword = "right"

--КНОПОЧКИ
local buttons = {
	{"1","2","3"},
	{"4","5","6"},
	{"7","8","9"},
	{"C","0","#"},
}

--МАССИВ ОБЪЕКТОВ
local Obj = {}

--МАССИВ СИМВОЛОВ, ВВЕДЕННЫХ С ПОМОЩЬЮ КНОПОК
local inputCode = {}

--ПОЛУЧЕНИЕ РАЗМЕРА МОНИТОРА
local xSize, ySize = term.getSize()

--ПОИСК ПЕРИФЕРИИ
local function findPeripheral(whatToFind)
  local PeriList = peripheral.getNames()
  for i=1,#PeriList do
    if peripheral.getType(PeriList[i]) == whatToFind then
      return PeriList[i]
    end
  end
end

--УНИВЕРСАЛЬНАЯ ФУНКЦИЯ ДЛЯ ОТОБРАЖЕНИЯ ТЕКСТА ПО ЦЕНТРУ ЭКРАНА
local function centerText(how,coord,text,textColor,backColor)
	term.setTextColor(textColor)
	term.setBackgroundColor(backColor)
	if how == "xy" then
		term.setCursorPos(math.floor(xSize/2-#text/2),math.floor(ySize/2))
	elseif how == "x" then
		term.setCursorPos(math.floor(xSize/2-#text/2),coord)
	elseif how == "y" then
		term.setCursorPos(coord,math.floor(ySize/2))
	end
	term.write(text)
end

--ЧТЕНИЕ КОНФИГА
function configRead(pathToConfig,whatToRead)
	if not fs.exists(pathToConfig) then error("No such file") end
	local file = fs.open(pathToConfig,"r")
	while true do
		local line = file.readLine()
		if line ~= nil then 
			local key, value = string.match(line,"(.*)=(.*)")
			if value ~= nil and key == whatToRead then
				file.close()
				return value
			end
		else
			file.close()
			break
		end
	end
end

--ЗАПИСЬ В КОНФИГ
local function configWrite(pathToConfig,key,value)
	if not fs.exists(pathToConfig) then
		local file = fs.open(pathToConfig,"w")
		file.close()
	end

	local file = fs.open(pathToConfig,"r")
	local Massiv = {}
	
	local lineCounter = 1
	while true do
		local line = file.readLine()
		if line ~= nil then 
			Massiv[lineCounter] = line
		else
			file.close()
			break
		end
		lineCounter = lineCounter + 1
	end

	local success = false
	for i=1,#Massiv do
		local key1, value1 = string.match(Massiv[i],"(.*)=(.*)")
		if value1 ~= nil and key1 == key then
			Massiv[i] = key.."="..value
			success = true
		end
	end

	if success == false then Massiv[#Massiv+1] = key.."="..value end

	local file = fs.open(pathToConfig,"w")
	for i=1,#Massiv do
		file.writeLine(Massiv[i])
	end
	file.close()
end

--ОБЪЕКТЫ
local function newObj(name,x,y)
	Obj[name]={}
	Obj[name]["x"]=x
	Obj[name]["y"]=y
end

--ПРОСТАЯ ЗАЛИВКА ЭКРАНА ЦВЕТОМ
local function clearScreen(color)
	term.setBackgroundColor(color)
	term.clear()
end

--ПРОСТОЙ ТЕКСТ
local function usualText(x,y,text)
	term.setCursorPos(x,y)
	term.write(text)
end

--ОТРИСОВКА ВЕРХНЕЙ ШТУЧКИ
local function drawTab(textColor,backColor)
	term.setBackgroundColor(backColor)
	term.setTextColor(textColor)
	term.setCursorPos(2,1)
	term.clearLine()
	term.write("-----")

	for i=1,#inputCode do
		if hidePassword == "true" then
			usualText(i+1,1,"*")
		else
			usualText(i+1,1,inputCode[i])
		end
	end
end

--ОТРИСОВКА КОНКРЕТНОЙ КНОПКИ
local function drawButton(name,textColor,backColor)
	term.setBackgroundColor(backColor)
	term.setTextColor(textColor)
	usualText(Obj[name]["x"],Obj[name]["y"],name)
end


--ОТРИСОВКА ВСЕГО ИНТЕРФЕЙСА
local function gui()
	--ОЧИСТКА ЭКРАНА
	term.setCursorBlink(false)
	clearScreen(colors.white)
	term.setTextColor(colors.black)

	--ОТРИСОВКА КНОПОЧЕК
	for j=1,#buttons do
		for i=1,#buttons[j] do
			local xPos = i*2
			local yPos = 1+j
			usualText(xPos,yPos,buttons[j][i])
			newObj(buttons[j][i],xPos,yPos)
		end
	end

	--ОТРИСОВКА ВЕРХНЕЙ ШНЯГИ
	drawTab(colors.white,colors.black)
end

------------------------------CТАРТ ПРОГРАММЫ------------------------------------

if not term.isColor() then
	error("This program requires an advanced computer.")
end

--РИСУЕМ В КОМПЕ ХУЙНЮ
clearScreen(colors.white)
centerText("xy",0,"Program started.",colors.lightGray,colors.white)

--ПОДКЛЮЧЕНИЕ МОНИТОРА
local m = findPeripheral("monitor")
if m ~= nil then
	m = peripheral.wrap(m)
	if not m.isColor() then
		windows.error("This program works only with advanced monitor.")
		do return end
	end
	m.setTextScale(1)
	term.redirect(m)
else
	windows.error("This program requires advanced external monitor.")
	do return end
end

--ЧТЕНИЕ КОНФИГА
if fs.exists("System/CodeDoor.cfg") then
	password = configRead("System/CodeDoor.cfg","password")
	redstoneSide = configRead("System/CodeDoor.cfg","redstone side")
	redstoneSideOnWrongPassword = configRead("System/CodeDoor.cfg","redstone side on wrong password")
	doorOpenTime = configRead("System/CodeDoor.cfg","door open time")
	hidePassword = configRead("System/CodeDoor.cfg","hide password")
else
	configWrite("System/CodeDoor.cfg","password",password)
	configWrite("System/CodeDoor.cfg","redstone side",redstoneSide)
	configWrite("System/CodeDoor.cfg","redstone side on wrong password",redstoneSideOnWrongPassword)
	configWrite("System/CodeDoor.cfg","door open time",doorOpenTime)
	configWrite("System/CodeDoor.cfg","hide password",hidePassword)
end

--РИСУЕМ ВСЕ
gui()

--АНАЛИЗ КАСАНИЙ ЭКРАНА
while true do
	--ЗАКРЫВАЕМ ДВЕРЬ НА ВСЯКИЙ ПОЖАРНЫЙ
	rs.setOutput(redstoneSide,false)
	rs.setOutput(redstoneSideOnWrongPassword,false)

	local event,side,x,y = os.pullEvent()
	if event == "monitor_touch" then
		--ПЕРЕБОР ВСЕХ ЭЛЕМЕНТОВ МАССИВА ОБЪЕКТОВ
		for key,val in pairs(Obj) do
			--ПРОВЕРКА СОВПАДЕНИЯ КООРДИНАТ КАСАНИЯ И КООРДИНАТ ОБЪЕКТОВ
			if x==Obj[key]["x"] and y==Obj[key]["y"] then
				--РИСУЕМ НАЖАТУЮ КНОПОЧКУ
				drawButton(key,colors.white,colors.green)
				sleep(buttonPressTime)
				drawButton(key,colors.black,colors.white)

				--ПРОВЕРКА, ЧТО ЗА КЛАВИША НАЖАТА - ЦИФРА ИЛИ СИСТЕМНАЯ КЛАВИША
				if key == "C" then
					inputCode = {}
					if mode == "edit" then
						drawTab(colors.white,colors.orange)
					else
						drawTab(colors.white,colors.black)
					end

				elseif key == "#" then
					--СОВМЕЩЕНИЕ ВСЕХ ЭЛЕМЕНТОВ МАССИВА ВВОДА В ОДНУ СТРОКУ
					local inputPass = ""
					for i=1,#inputCode do
						inputPass = inputPass..inputCode[i]
					end

					--ПРОВЕРКА РЕЖИМА
					if mode == "edit" then
						--СМЕНА ПАРОЛЯ
						password = inputPass
						configWrite("System/CodeDoor.cfg","password",password)
						inputCode = {}
						term.setCursorPos(3,1)
						term.setBackgroundColor(colors.orange)
						term.clearLine()
						term.setTextColor(colors.white)
						term.write("Ok!")

						sleep(2)

						drawTab(colors.white,colors.black)
						mode = "default"
					else
						--СРАВНЕНИЕ ВВЕДЕННОГО ГОВНА С ПЕРЕМЕННОЙ ПАРОЛЯ
						if inputPass == password then
							drawTab(colors.white,colors.green)
							rs.setOutput(redstoneSide,true)
							rs.setOutput(redstoneSideOnWrongPassword,false)

							--СТАРТУЕМ ТАЙМЕР НА УКАЗАННОЕ ВРЕМЯ
							changePasswordTimer = os.startTimer(tonumber(doorOpenTime))
							while true do
								local event2,side2,x2,y2 = os.pullEvent()
								--ЕСЛИ НИЧЕГО НЕ НАЖАТО, ТО ВЫХОД ИЗ ЦИКЛА
								if event2 == "timer" then
									if side2 == changePasswordTimer then
										break
									end
								--ЕСЛИ НАЖАТА КЛАВИША "С", ТО ЗАПУСТИТЬ РЕЖИМ СМЕНЫ ПАРОЛЯ
								elseif event2 == "monitor_touch" then
									if x2==Obj["C"]["x"] and y2==Obj["C"]["y"] then
										drawButton("C",colors.white,colors.green)
										sleep(buttonPressTime)
										drawButton("C",colors.black,colors.white)
										mode = "edit"
										os.queueEvent("timer",changePasswordTimer)
									end
								end	
							end

							--ОЧИЩАЕМ ВВЕДЕННЫЙ ТЕКСТ И ЗАКРЫВАЕМ ДВЕРЬ
							inputCode = {}
							rs.setOutput(redstoneSide,false)

							--РИСУЕМ ВЕРХНЮЮ ШНЯГУ РАЗНОГО ЦВЕТА В ЗАВИСИМОСТИ ОТ РЕЖИМА
							if mode == "edit" then
								drawTab(colors.white,colors.orange)
							else
								drawTab(colors.white,colors.black)
							end
						--ЕСЛИ ВВЕДЕН НЕВЕРНЫЙ ПАРОЛЬ
						else
							drawTab(colors.white,colors.red)
							rs.setOutput(redstoneSide,false)
							rs.setOutput(redstoneSideOnWrongPassword,true)
							sleep(3)
							rs.setOutput(redstoneSideOnWrongPassword,false)
							inputCode = {}
							drawTab(colors.white,colors.black)
						end
					end
				--ЕСЛИ НАЖАТА ЛЮБАЯ ЦИФРА
				else
					if #inputCode < 5 then
						inputCode[#inputCode+1] = key
						if mode == "edit" then
							drawTab(colors.white,colors.orange)
						else
							drawTab(colors.white,colors.black)
						end
					end
				end
				--ВЫХОД ИЗ ЦИКЛА ПЕРЕБОРА ОБЪЕКТОВ
				break
			end
		end

	--ЕСЛИ НАЖАТА КЛАВИША ENTER
	elseif event == "key" and side == 28 then
		break
	end
end

clearScreen(colors.black)
term.setTextColor(colors.white)

term.redirect(term.native())

clearScreen(colors.black)
term.setTextColor(colors.white)
term.setCursorPos(1,1)