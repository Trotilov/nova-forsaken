-- NOVA FORSAKEN v0.6.0 BETA
-- Single-file, local only; does not download or execute third-party scripts.
-- Killer/survivor ESP is based on the user's working v0.2.
-- Generator / gear / minion detection is experimental and version-dependent.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
if not player then return end
local pg = player:WaitForChild("PlayerGui")
local env = (type(getgenv) == "function" and getgenv()) or _G
for _, key in ipairs({"NovaESPStop", "NovaV03Stop", "NovaShortStop"}) do
    if type(env[key]) == "function" then pcall(env[key]) end
end
for _, name in ipairs({"NOVA_MINI", "NOVA_ESP_V03", "NOVA_SHORT", "NOVA_ESP_031", "NOVA_ESP_040", "NOVA_ESP_050", "NOVA_ESP_060"}) do
    local prev = pg:FindFirstChild(name)
    if prev then prev:Destroy() end
end
local running = true
local categories = {
    {"kill", "Киллеры", Color3.fromRGB(255, 65, 95)},
    {"surv", "Выжившие", Color3.fromRGB(55, 235, 145)},
    {"gen", "Генераторы", Color3.fromRGB(255, 205, 65)},
    {"done", "Готовые", Color3.fromRGB(80, 150, 255)},
    {"fake", "Фейковые", Color3.fromRGB(200, 105, 255)},
    {"gear", "Шестерёнки", Color3.fromRGB(255, 155, 65)},
    {"npc", "Миньоны", Color3.fromRGB(255, 110, 185)}
}
local show, color = {}, {}
for _, item in ipairs(categories) do
    show[item[1]] = true
    color[item[1]] = item[3]
end
local palette = {
    Color3.fromRGB(255,65,95), Color3.fromRGB(255,160,55),
    Color3.fromRGB(255,215,65), Color3.fromRGB(55,235,145),
    Color3.fromRGB(55,205,255), Color3.fromRGB(80,150,255),
    Color3.fromRGB(195,105,255), Color3.fromRGB(255,110,185),
    Color3.fromRGB(255,255,255)
}
local labelsOn, distanceOn, transparency = true, true, 0.65
local liteMode, antiBlindOn = false, false
local refreshSteps, refreshIndex = {1, 2, 3}, 2
local questOn = true
-- Quest definitions and sync state are initialized in the new event view.
local function obj(class, parent, properties)
    local instance = Instance.new(class)
    for k, v in pairs(properties or {}) do instance[k] = v end
    instance.Parent = parent
    return instance
end
local function corners(frame, radius)
    obj("UICorner", frame, {CornerRadius=UDim.new(0, radius or 8)})
end

-- NOVA v0.5 redesigned tablet-friendly interface
local panelBg=Color3.fromRGB(15,19,30)
local surface=Color3.fromRGB(27,34,49)
local raised=Color3.fromRGB(36,45,63)
local violet=Color3.fromRGB(148,108,249)
local mint=Color3.fromRGB(78,215,182)
local muted=Color3.fromRGB(155,172,193)
local white=Color3.fromRGB(238,243,253)
local gui=obj("ScreenGui",pg,{
    Name="NOVA_ESP_060",ResetOnSpawn=false,IgnoreGuiInset=true,
    DisplayOrder=9999,ZIndexBehavior=Enum.ZIndexBehavior.Sibling
})
local win=obj("Frame",gui,{
    AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
    Size=UDim2.fromOffset(490,324),BackgroundColor3=panelBg,BorderSizePixel=0
})
corners(win,15)
obj("UIStroke",win,{Color=Color3.fromRGB(72,83,117),Thickness=1.2})
local header=obj("Frame",win,{
    Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,0,0,43),
    BackgroundTransparency=1,Active=true
})
obj("TextLabel",header,{
    Position=UDim2.fromOffset(16,0),Size=UDim2.fromOffset(240,43),
    Text="NOVA  /  0.6 BETA",Font=Enum.Font.GothamBold,TextSize=17,
    TextColor3=white,TextXAlignment=Enum.TextXAlignment.Left,
    BackgroundTransparency=1
})
obj("TextLabel",header,{
    Position=UDim2.new(1,-161,0,0),Size=UDim2.fromOffset(60,43),
    Text="NEO",Font=Enum.Font.GothamBold,TextSize=11,
    TextColor3=mint,BackgroundTransparency=1
})
local function square(parent,text,pos,bg)
    local b=obj("TextButton",parent,{
        Position=pos,Size=UDim2.fromOffset(34,30),
        BackgroundColor3=bg,BorderSizePixel=0,Text=text,
        TextColor3=white,Font=Enum.Font.GothamBold,TextSize=18
    })
    corners(b,8);return b
end
local mini=square(header,"−",UDim2.new(1,-84,0,6),raised)
local quit=square(header,"×",UDim2.new(1,-43,0,6),Color3.fromRGB(106,50,70))
local bubble=obj("TextButton",gui,{
    Position=UDim2.new(0,12,.45,0),Size=UDim2.fromOffset(48,48),
    BackgroundColor3=violet,Text="N",TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold,TextSize=22,Visible=false,BorderSizePixel=0
})
corners(bubble,13)
mini.MouseButton1Click:Connect(function() win.Visible=false;bubble.Visible=true end)
bubble.MouseButton1Click:Connect(function() bubble.Visible=false;win.Visible=true end)
local drag=false
local dragInput,dragPos,dragOrigin
header.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.Touch or
       input.UserInputType==Enum.UserInputType.MouseButton1 then
        drag=true;dragInput=input;dragPos=input.Position;dragOrigin=win.Position
        input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then drag=false end
        end)
    end
end)
local dragConnection=UIS.InputChanged:Connect(function(input)
    if drag and (input==dragInput or input.UserInputType==Enum.UserInputType.MouseMovement) then
        local d=input.Position-dragPos
        win.Position=UDim2.new(dragOrigin.X.Scale,dragOrigin.X.Offset+d.X,
            dragOrigin.Y.Scale,dragOrigin.Y.Offset+d.Y)
    end
end)
local sidebar=obj("Frame",win,{
    Position=UDim2.fromOffset(9,47),Size=UDim2.fromOffset(106,236),
    BackgroundColor3=Color3.fromRGB(21,27,40),BorderSizePixel=0
})
corners(sidebar,9)
local nav, pages={},{}
local navOrder={{"esp","ESP"},{"combat","БОЙ"},{"puzzles","ПАЗЛЫ"},{"event","ИВЕНТ"},{"settings","ОПЦИИ"}}
for i,item in ipairs(navOrder) do
    local key,title=item[1],item[2]
    local b=obj("TextButton",sidebar,{
        Position=UDim2.fromOffset(7,8+(i-1)*43),Size=UDim2.fromOffset(92,37),
        BackgroundColor3=surface,BorderSizePixel=0,Text=title,
        TextColor3=muted,TextSize=13,Font=Enum.Font.GothamBold
    })
    corners(b,8);nav[key]=b
    local scroll=obj("ScrollingFrame",win,{
        Position=UDim2.fromOffset(123,47),Size=UDim2.new(1,-133,1,-95),
        CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=3,
        BackgroundTransparency=1,BorderSizePixel=0,Visible=key=="esp",
        ScrollingDirection=Enum.ScrollingDirection.Y
    })
    local layout=obj("UIListLayout",scroll,{
        Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder
    })
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if scroll.Parent then scroll.CanvasSize=UDim2.fromOffset(0,layout.AbsoluteContentSize.Y+12) end
    end)
    pages[key]=scroll
    b.MouseButton1Click:Connect(function()
        for n,page in pairs(pages) do
            page.Visible=(n==key)
            nav[n].BackgroundColor3=(n==key) and Color3.fromRGB(73,55,122) or surface
            nav[n].TextColor3=(n==key) and white or muted
        end
    end)
end
nav.esp.BackgroundColor3=Color3.fromRGB(73,55,122)
nav.esp.TextColor3=white

local function line(parent,text,height,color,size)
    return obj("TextLabel",parent,{
        Size=UDim2.new(1,-7,0,height or 25),BackgroundTransparency=1,
        Text=text,TextColor3=color or muted,Font=Enum.Font.Gotham,
        TextSize=size or 12,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left
    })
end
local function button(parent,text,height)
    local b=obj("TextButton",parent,{
        Size=UDim2.new(1,-7,0,height or 35),BackgroundColor3=raised,
        BorderSizePixel=0,Text=text,TextColor3=white,
        Font=Enum.Font.GothamMedium,TextSize=12
    })
    corners(b,8);return b
end
local function hex(c)
    return string.format("#%02X%02X%02X", math.floor(c.R*255+.5),
        math.floor(c.G*255+.5),math.floor(c.B*255+.5))
end
local function fromHex(v)
    local s=tostring(v):gsub("#",""):gsub("%s","")
    if not s:match("^%x%x%x%x%x%x$") then return nil end
    return Color3.fromRGB(tonumber(s:sub(1,2),16),
        tonumber(s:sub(3,4),16),tonumber(s:sub(5,6),16))
end

line(pages.esp,"ПОДСВЕТКА  ·  цвет справа",28,mint,12)
for _,info in ipairs(categories) do
    local id,name=info[1],info[2]
    local row=obj("Frame",pages.esp,{
        Size=UDim2.new(1,-7,0,42),
        BackgroundColor3=surface,BorderSizePixel=0
    })
    corners(row,9)
    local toggle=obj("TextButton",row,{
        Position=UDim2.fromOffset(5,5),Size=UDim2.new(1,-150,0,32),
        BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,
        TextColor3=white,Font=Enum.Font.GothamMedium,TextSize=12
    })
    local swatch=obj("TextButton",row,{
        Position=UDim2.new(1,-126,0,7),Size=UDim2.fromOffset(27,27),
        BorderSizePixel=0,BackgroundColor3=color[id],Text=""
    })
    corners(swatch,6)
    local entry=obj("TextBox",row,{
        Position=UDim2.new(1,-94,0,7),Size=UDim2.fromOffset(86,27),
        BackgroundColor3=raised,BorderSizePixel=0,
        Text=hex(color[id]),ClearTextOnFocus=false,
        Font=Enum.Font.Code,TextSize=11,TextColor3=white
    })
    corners(entry,6)
    local function draw()
        toggle.Text=(show[id] and "●  " or "○  ")..name
        toggle.TextColor3=(show[id] and white or muted)
    end
    draw()
    toggle.MouseButton1Click:Connect(function()show[id]=not show[id];draw()end)
    local index=0
    swatch.MouseButton1Click:Connect(function()
        index=index%#palette+1;color[id]=palette[index]
        swatch.BackgroundColor3=color[id];entry.Text=hex(color[id])
    end)
    entry.FocusLost:Connect(function()
        color[id]=fromHex(entry.Text) or color[id]
        swatch.BackgroundColor3=color[id];entry.Text=hex(color[id])
    end)
end
line(pages.esp,"● нажми, чтобы отключить  ·  цветной квадрат меняет оттенок",34,muted,11)

local function optionToggle(title,get,set)
    local b=button(pages.settings,"")
    local function draw()b.Text=title.."  :  "..(get() and "ВКЛ" or "ВЫКЛ")end
    draw()
    b.MouseButton1Click:Connect(function()set(not get());draw()end)
    return b
end
line(pages.settings,"ПРОИЗВОДИТЕЛЬНОСТЬ",27,mint,12)
optionToggle("Lite ESP",function()return liteMode end,function(v)liteMode=v end)
optionToggle("Названия",function()return labelsOn end,function(v)labelsOn=v end)
optionToggle("Дистанция",function()return distanceOn end,function(v)distanceOn=v end)
local speedBtn=button(pages.settings,"")
local function speedText()speedBtn.Text="Обновление ESP  /  "..refreshSteps[refreshIndex].." сек."end
speedText()
speedBtn.MouseButton1Click:Connect(function()
    refreshIndex=refreshIndex%#refreshSteps+1;speedText()
end)
local fillBtn=button(pages.settings,"")
local function fillText()fillBtn.Text="Прозрачность заливки  /  "..math.floor(transparency*100).."%"
end
fillText()
fillBtn.MouseButton1Click:Connect(function()
    transparency=transparency+.15
    if transparency>.95 then transparency=.2 end
    fillText()
end)
line(pages.settings,"ВИЗУАЛЬНЫЕ ЭФФЕКТЫ",29,mint,12)
optionToggle("Anti Blind",function()return antiBlindOn end,function(v)antiBlindOn=v end)
line(pages.settings,"Фейки определяются только по видимым клиенту признакам.",45,muted,11)

-- The first 15 portrait quests are short summaries, not invented progress.
local questData={
    {goal=200,who="NOOB",task="Пробеги 200 studs во время погони под Bloxy Cola",keys={"noob","bloxy"}},
    {goal=5,who="SHEDLETSKY",task="5 раз оглуши киллера, пока он преследует другого",keys={"shedletsky","stun"}},
    {goal=5,who="ELLIOT",task="5 раз исцели пиццей выжившего с HP ниже 50%",keys={"elliot","heal"}},
    {goal=6,who="SLASHER",task="6 убийств с помощью Decapitation",keys={"slasher","decap"}},
    {goal=120,who="CHANCE",task="Увеличь максимальное HP на 120 через Reroll",keys={"chance","reroll"}},
    {goal=55,who="BUILDERMAN",task="Нанеси 55 урона недавно установленными турелями",keys={"builderman","turret"}},
    {goal=5,who="C00LKIDD",task="5 убийств через Walkspeed Override или ожог",keys={"c00lkidd","walkspeed"}},
    {goal=3,who="DUSEKKAR",task="3 раза задень выжившего и киллера Plasma Beam",keys={"dusekkar","plasma"}},
    {goal=40,who="GUEST 1337",task="Получи суммарно 40 дополнительного HP через Block",keys={"guest 1337","block"}},
    {goal=3,who="NOSFERATU",task="3 раза атакуй другого выжившего в течение 10 секунд после Hunter's Feast",keys={"nosferatu","hunter"}},
    {goal=24,who="VEERONICA",task="Продержи 24 секунды эффект после прохода сквозь киллера в фазе",keys={"veeronica","phase"}},
    {goal=3,who="ОБЩАЯ",task="3 раза оглуши киллера с расстояния более 30 studs",keys={"30","studs"}},
    {goal=10,who="JANE DOE",task="10 попаданий полностью заряженным Crystal Pitch",keys={"jane doe","crystal"}},
    {goal=45,who="JOHN DOE",task="45 секунд бонуса скорости от Corrupted Energy и Digital Footprint",keys={"john doe","corrupted"}},
    {goal=180,who="DUSEKKAR",task="Поглоти 180 урона щитами Spawn Protection",keys={"dusekkar","spawn protection"}}
}
local eventAuto=true
local questVerified=false
local questProgressKnown=false
local questProgress=0
local questGoal=0
local questText=""
local questTier=1
local eventState="Открой Forsakeween-пасс один раз для синхронизации"
local function selectTier(t,verified)
    if t<1 then t=1 end
    if t>#questData then t=#questData end
    if t~=questTier then questProgressKnown=false end
    questTier=t
    questVerified=verified
    local q=questData[t]
    questText=q.task
    questGoal=q.goal
end
local hud=obj("Frame",gui,{
    Position=UDim2.new(0,12,.13,0),
    Size=UDim2.fromOffset(322,93),
    BackgroundColor3=panelBg,BorderSizePixel=0,Visible=questOn
})
corners(hud,11)
obj("UIStroke",hud,{Color=Color3.fromRGB(95,75,148),Thickness=1.1})
local hudTitle=obj("TextLabel",hud,{
    Position=UDim2.fromOffset(12,5),Size=UDim2.fromOffset(272,22),
    BackgroundTransparency=1,Text="FORSAKEWEEN",
    TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.GothamBold,
    TextColor3=mint,TextSize=13
})
local hudClose=square(hud,"×",UDim2.new(1,-31,0,5),raised)
hudClose.Size=UDim2.fromOffset(25,24)
hudClose.TextSize=15
local hudText=obj("TextLabel",hud,{
    Position=UDim2.fromOffset(12,27),Size=UDim2.new(1,-24,0,44),
    BackgroundTransparency=1,TextColor3=white,TextSize=12,
    Font=Enum.Font.Gotham,TextWrapped=true,
    TextXAlignment=Enum.TextXAlignment.Left
})
local trackBg=obj("Frame",hud,{
    Position=UDim2.fromOffset(12,77),Size=UDim2.new(1,-24,0,6),
    BackgroundColor3=raised,BorderSizePixel=0
})
corners(trackBg,5)
local trackFill=obj("Frame",trackBg,{
    Size=UDim2.fromScale(0,1),BackgroundColor3=mint,BorderSizePixel=0
})
corners(trackFill,5)
local dragHud=false
local hudInput,hudStart,hudOrigin
hud.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
        dragHud=true;hudInput=input;hudStart=input.Position;hudOrigin=hud.Position
        input.Changed:Connect(function()if input.UserInputState==Enum.UserInputState.End then dragHud=false end end)
    end
end)
local hudDragConn=UIS.InputChanged:Connect(function(input)
    if dragHud and (input==hudInput or input.UserInputType==Enum.UserInputType.MouseMovement) then
        local d=input.Position-hudStart
        hud.Position=UDim2.new(hudOrigin.X.Scale,hudOrigin.X.Offset+d.X,
            hudOrigin.Y.Scale,hudOrigin.Y.Offset+d.Y)
    end
end)

local eventInfo=line(pages.event,"АВТО-СИНХРОНИЗАЦИЯ",31,mint,13)
local eventMode=button(pages.event,"")
local eventHUD=button(pages.event,"")
local eventMessage=line(pages.event,"",46,muted,11)
local tierRow=obj("Frame",pages.event,{
    Size=UDim2.new(1,-7,0,42),BackgroundColor3=surface,BorderSizePixel=0
})
corners(tierRow,8)
local prev=obj("TextButton",tierRow,{
    Position=UDim2.fromOffset(5,5),Size=UDim2.fromOffset(46,32),
    Text="−",BackgroundColor3=raised,TextColor3=white,
    Font=Enum.Font.GothamBold,TextSize=20,BorderSizePixel=0
})
corners(prev,7)
local tierText=obj("TextLabel",tierRow,{
    Position=UDim2.fromOffset(55,0),Size=UDim2.new(1,-110,1,0),
    BackgroundTransparency=1,TextColor3=white,
    Font=Enum.Font.GothamBold,TextSize=14
})
local nextBtn=obj("TextButton",tierRow,{
    Position=UDim2.new(1,-51,0,5),Size=UDim2.fromOffset(46,32),
    Text="+",BackgroundColor3=raised,TextColor3=white,
    Font=Enum.Font.GothamBold,TextSize=19,BorderSizePixel=0
})
corners(nextBtn,7)
local taskLabel=line(pages.event,"",79,white,12)
local syncBtn=button(pages.event,"Считать данные из пасса")
local reportBtn=button(pages.event,"Скопировать диагностику пасса")
line(pages.event,"Задания 1–15 уже встроены. Прогресс показывается только если игра передала точное значение.",60,muted,11)
local function drawQuest()
    eventMode.Text="Режим  /  "..(eventAuto and "АВТО" or "ВЫБОР ТИРА")
    eventHUD.Text="Панель в раунде  /  "..(questOn and "ПОКАЗЫВАТЬ" or "СКРЫТЬ")
    eventMessage.Text=eventState
    tierText.Text="ТИР "..(questVerified and tostring(questTier) or (eventAuto and "?" or tostring(questTier)))
    if questVerified or not eventAuto then
        taskLabel.Text="["..questData[questTier].who.."] "..questText
        hudText.Text=questText
        local progress=questProgressKnown and (tostring(questProgress).." / "..questGoal)
           or ("— / "..questGoal)
        hudTitle.Text="FORSAKEWEEN  •  ТИР "..questTier.."  "..progress
    else
        taskLabel.Text="Открой окно ивентового пасса в лобби. NOVA попробует найти текущий тир и прогресс."
        hudText.Text="Открой Forsakeween-пасс, чтобы получить задание"
        hudTitle.Text="FORSAKEWEEN  •  ОЖИДАНИЕ"
    end
    trackFill.Size=UDim2.fromScale((questProgressKnown and questGoal>0) and
        math.clamp(questProgress/questGoal,0,1) or 0,1)
    hud.Visible=questOn
end
eventMode.MouseButton1Click:Connect(function()
    eventAuto=not eventAuto
    if not eventAuto then
        questVerified=false
        questProgressKnown=false
        selectTier(questTier,false)
        eventState="Выбор тира: используйте − и +. Прогресс не придумываем."
    else
        questVerified=false
        questProgressKnown=false
        eventState="Открой Forsakeween-пасс для автосинхронизации"
    end
    drawQuest()
end)
eventHUD.MouseButton1Click:Connect(function() questOn=not questOn;drawQuest()end)
hudClose.MouseButton1Click:Connect(function()questOn=false;drawQuest()end)
local function manualTier(diff)
    eventAuto=false
    selectTier(math.clamp(questTier+diff,1,#questData),false)
    questProgressKnown=false
    eventState="Тир выбран вручную; счётчик из игры недоступен"
    drawQuest()
end
prev.MouseButton1Click:Connect(function()manualTier(-1)end)
nextBtn.MouseButton1Click:Connect(function()manualTier(1)end)
local function isEventGui(node)
    local p=node
    local depth=0
    while p and p~=pg and depth<10 do
        local n=p.Name:lower()
        if n:find("forsake",1,true) or n:find("halloween",1,true) or
           n:find("battlepass",1,true) or n:find("battle_pass",1,true) or
           n:find("eventquest",1,true) or n:find("eventpass",1,true) then
            return true
        end
        p=p.Parent;depth=depth+1
    end
    return false
end
local lastReport="Диагностика ещё не собрана"
local function syncEvent()
    if not eventAuto then return end
    local labels={}
    local samples={}
    for _,el in ipairs(pg:GetDescendants()) do
        if (el:IsA("TextLabel") or el:IsA("TextButton")) and
           not el:IsDescendantOf(gui) and isEventGui(el) then
            local txt=tostring(el.Text or "")
            if txt~="" then
                labels[#labels+1]={object=el,text=txt,lower=txt:lower()}
                if #samples<50 then samples[#samples+1]=el.Name..": "..txt:sub(1,100) end
            end
        end
    end
    lastReport="Forsakeween labels: "..#labels.."\n"..table.concat(samples,"\n")
    if #labels==0 then
        eventState="Данные не найдены. Открой Forsakeween-пасс в лобби."
        drawQuest()
        return
    end
    local tierFromCurrent=nil
    local matches={}
    for _,item in ipairs(labels) do
        local text=item.lower
        if text:find("current",1,true) or text:find("active",1,true) or
           text:find("текущ",1,true) then
            local n=text:match("tier%s*#?%s*(%d+)") or
                text:match("тир%s*#?%s*(%d+)")
            if n and tonumber(n) and tonumber(n)<=#questData then
                tierFromCurrent=tonumber(n)
            end
        end
        for tier,q in ipairs(questData) do
            local found=true
            for _,word in ipairs(q.keys) do
                if not text:find(word,1,true) then found=false;break end
            end
            if found and #text>20 then matches[tier]=item end
        end
    end
    local uniqueTier,matchCount=nil,0
    for k in pairs(matches) do uniqueTier=k;matchCount=matchCount+1 end
    local chosen=tierFromCurrent or (matchCount==1 and uniqueTier or nil)
    if not chosen then
        eventState="Пасс найден, но текущую задачу определить не удалось."
        drawQuest()
        return
    end
    if chosen~=questTier or not questVerified then
        selectTier(chosen,true)
        questProgressKnown=false
    end
    local expected=questGoal
    local picked=nil
    local match=matches[chosen]
    if match then
        local parent=match.object.Parent
        for _,item in ipairs(labels) do
            if item.object==match.object or
               (parent and (item.object.Parent==parent or item.object.Parent==parent.Parent)) then
                local a,b=item.text:match("(%d+)%s*/%s*(%d+)")
                if a and tonumber(b)==expected and tonumber(a)<=expected then
                    picked=tonumber(a)
                    break
                end
            end
        end
    end
    if picked~=nil then
        questProgress=picked
        questProgressKnown=true
        eventState="Синхронизировано с интерфейсом пасса"
    else
        questProgressKnown=false
        eventState="Тир найден, точный прогресс пока недоступен"
    end
    drawQuest()
end
syncBtn.MouseButton1Click:Connect(function()
    local ok,err=pcall(syncEvent)
    if not ok then eventState="Ошибка чтения: "..tostring(err):sub(1,45);drawQuest() end
end)
reportBtn.MouseButton1Click:Connect(function()
    if type(setclipboard)=="function" then
        local ok=pcall(setclipboard,lastReport)
        eventState=ok and "Диагностика скопирована" or "Не удалось скопировать"
    else
        eventState="Копирование недоступно в NEO"
    end
    drawQuest()
end)
selectTier(questTier,false)
drawQuest()
task.spawn(function()
    while running do
        if eventAuto then pcall(syncEvent) end
        task.wait(5)
    end
end)
local status=obj("TextLabel",win,{
    Position=UDim2.new(0,122,1,-36),Size=UDim2.new(1,-131,0,25),
    BackgroundColor3=surface,BorderSizePixel=0,
    Text="ESP: ищем объекты...",TextColor3=muted,
    Font=Enum.Font.Gotham,TextSize=11,TextWrapped=true
})
corners(status,7)

local markers={}
local function clear(model)
    local mark=markers[model]
    if mark then
        if mark.highlight then mark.highlight:Destroy() end
        if mark.billboard then mark.billboard:Destroy() end
        markers[model]=nil
    end
end
local function rootPart(model)
    if model:IsA("BasePart") then return model end
    if not model:IsA("Model") then return nil end
    for _,name in ipairs({"HumanoidRootPart","Main","Root","RootPart"}) do
        local part=model:FindFirstChild(name,true)
        if part and part:IsA("BasePart") then return part end
    end
    return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart",true)
end
local function truth(model,key)
    if model:GetAttribute(key)==true then return true end
    local child=model:FindFirstChild(key,true)
    return child and child:IsA("BoolValue") and child.Value==true
end
local function generatorKind(model)
    local name=model.Name:lower()
    if name:find("fake",1,true) or name:find("decoy",1,true)
       or truth(model,"Fake") or truth(model,"IsFake")
       or truth(model,"IsDecoy") or truth(model,"Hallucination")
       or truth(model,"NoliFake") or truth(model,"IsIllusion") then
        return "fake"
    end
    if truth(model,"Completed") or truth(model,"IsCompleted")
       or truth(model,"Finished") or truth(model,"Complete") then return "done" end
    local barUI=model:FindFirstChild("BarUI",true)
    local bar=barUI and barUI:FindFirstChild("Bar",true)
    if bar and bar:IsA("GuiObject") and bar.Size.X.Scale>=.995 then return "done" end
    local p=model:FindFirstChild("Progress",true)
    local val=nil
    if p and (p:IsA("NumberValue") or p:IsA("IntValue")) then val=p.Value end
    if val==nil then val=model:GetAttribute("Progress") end
    if type(val)=="number" and (val>=100 or val==1) then return "done" end
    return "gen"
end
local function isNpc(model)
    local n=model.Name:lower()
    return n=="pizzadeliveryrig" or n:find("minion",1,true)
       or n:find("zombie",1,true) or n:find("undead",1,true)
       or n:find("rotten",1,true)
end
local restoreVisuals
local mapCacheSource, mapCacheTime, mapCache = nil, 0, {}
local function cachedMapModels(source)
    local now=os.clock()
    if mapCacheSource~=source or now-mapCacheTime>4 then
        mapCacheSource, mapCacheTime=source, now
        local fresh={}
        if source then
            for _,model in ipairs(source:GetDescendants()) do
                if model:IsA("Model") then
                    local n=model.Name:lower()
                    if n=="generator" or n:find("fakegenerator",1,true)
                       or n=="gear" or isNpc(model) then
                        fresh[#fresh+1]=model
                    end
                end
            end
        end
        mapCache=fresh
    end
    return mapCache
end
local function scan()
    local found,counts={},{}
    local function add(model,id,text)
        if not show[id] or not model or not model.Parent then return end
        local part=rootPart(model)
        if not part then return end
        found[model]={id=id,name=text,part=part}
        counts[id]=(counts[id] or 0)+1
    end
    -- Same structure as the working NOVA v0.2.
    local folder=workspace:FindFirstChild("Players")
    if folder then
        for _,info in ipairs({{"Killers","kill"},{"Survivors","surv"}}) do
            local group=folder:FindFirstChild(info[1])
            if group then
                for _,model in ipairs(group:GetChildren()) do
                    if model:IsA("Model") and model~=player.Character then
                        local hum=model:FindFirstChildOfClass("Humanoid")
                        if not hum or hum.Health>0 then add(model,info[2],model.Name) end
                    end
                end
            end
        end
    end
    local map=workspace:FindFirstChild("Map")
    local ingame=map and map:FindFirstChild("Ingame")
    local gameMap=ingame and ingame:FindFirstChild("Map")
    local source=ingame or map
    if source then
        for _,model in ipairs(cachedMapModels(source)) do
            if model:IsA("Model") and model:IsDescendantOf(source) then
                local n=model.Name:lower()
                if (n=="generator" or n:find("fakegenerator",1,true))
                   and model:FindFirstChild("Main") then
                    local id=generatorKind(model)
                    add(model,id,id=="done" and "ГОТОВ" or
                        id=="fake" and "ФЕЙК" or "ГЕНЕРАТОР")
                elseif n=="gear" and model:FindFirstChild("Root") then
                    add(model,"gear","ШЕСТЕРЁНКА")
                elseif isNpc(model) and not Players:GetPlayerFromCharacter(model) then
                    add(model,"npc","МИНЬОН")
                end
            end
        end
    end
    for model,info in pairs(found) do
        local mark=markers[model]
        if not mark then
            local h=obj("Highlight",gui,{
                Name="NovaHighlight",Adornee=model,
                DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,
                OutlineTransparency=0,FillTransparency=transparency
            })
            local billboard=obj("BillboardGui",gui,{
                Name="NovaLabel",Adornee=info.part,AlwaysOnTop=true,
                Size=UDim2.fromOffset(180,34),
                StudsOffsetWorldSpace=Vector3.new(0,3,0),MaxDistance=1400
            })
            local t=obj("TextLabel",billboard,{
                Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
                TextColor3=color[info.id],Font=Enum.Font.GothamBold,
                TextSize=13,TextStrokeColor3=Color3.new(0,0,0),
                TextStrokeTransparency=.15
            })
            mark={highlight=h,billboard=billboard,text=t}
            markers[model]=mark
        end
        mark.highlight.Adornee=model
        mark.highlight.FillColor=color[info.id]
        mark.highlight.OutlineColor=color[info.id]
        mark.highlight.FillTransparency=transparency
        mark.highlight.Enabled=true
        mark.billboard.Adornee=info.part
        mark.billboard.Enabled=labelsOn and not liteMode
        mark.text.TextColor3=color[info.id]
        local text=info.name
        if distanceOn and labelsOn and not liteMode then
            local myRoot=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if myRoot then
                text=text.." ["..math.floor((myRoot.Position-info.part.Position).Magnitude).." st]"
            end
        end
        mark.text.Text=text
    end
    for model in pairs(markers) do
        if not found[model] or not model.Parent then clear(model) end
    end
    status.Text="K:"..(counts.kill or 0).." S:"..(counts.surv or 0)
        .." G:"..(counts.gen or 0).." ✓:"..(counts.done or 0)
        .." ?:"..(counts.fake or 0).." ⚙:"..(counts.gear or 0)
        .." NPC:"..(counts.npc or 0)
        ..(source and "  | КАРТА OK" or "  | КАРТА НЕ НАЙДЕНА")
end
local function stop()
    if not running then return end
    running=false
    if restoreVisuals then restoreVisuals() end
    if dragConnection then dragConnection:Disconnect() end
    if hudDragConn then hudDragConn:Disconnect() end
    for model in pairs(markers) do clear(model) end
    gui:Destroy()
end
env.NovaESPStop=stop
quit.MouseButton1Click:Connect(stop)
task.spawn(function()
    while running do
        local ok,err=pcall(scan)
        if not ok then
            warn("[NOVA 0.5] ",err)
            if status.Parent then status.Text="ОШИБКА: "..tostring(err):sub(1,100) end
        end
        task.wait(refreshSteps[refreshIndex])
    end
end)

-- Client-only visual suppressor, with reversible original Enabled state.
local suppressed={}
restoreVisuals=function()
    for inst,oldState in pairs(suppressed) do
        if inst and inst.Parent then
            pcall(function() inst.Enabled=oldState end)
        end
        suppressed[inst]=nil
    end
end
local function suppressVisuals()
    if not antiBlindOn then restoreVisuals(); return end
    for _,container in ipairs({Lighting,workspace.CurrentCamera or Lighting}) do
        for _,inst in ipairs(container:GetDescendants()) do
            local named=inst.Name:lower()
            if inst:IsA("BlurEffect") or
                (inst:IsA("ColorCorrectionEffect") and
                (named:find("blind",1,true) or named:find("flash",1,true))) then
                if suppressed[inst]==nil then suppressed[inst]=inst.Enabled end
                if inst.Enabled then inst.Enabled=false end
            end
        end
    end
end
task.spawn(function()
    while running do
        local ok,err=pcall(suppressVisuals)
        if not ok then warn("[NOVA] Anti Blind: ",err) end
        task.wait(2)
    end
end)
print("[NOVA] ESP v0.6 base started")


-- EXPERIMENTAL LAB. Failures here must not disable the working ESP.
local okLab, labError=pcall(function()
    local RunService=game:GetService("RunService")
    local VirtualInputManager=game:GetService("VirtualInputManager")
    local ReplicatedStorage=game:GetService("ReplicatedStorage")
    local combat={block=false,punch=false,blockRange=10,blockMode="animation",blockDelay=0.08,
        noli=false,noliSmooth=.10,hook=false,hookDelay=.15,
        clock=false,genAssist=false}
    local feedback=line(pages.combat,"Статус: ожидаем персонажа",44,muted,11)
    line(pages.combat,"GUEST 1337  /  ЭКСПЕРИМЕНТ",28,mint,12)
    local function labToggle(parent,title,key)
        local b=button(parent,"")
        local function draw()
            b.Text=(combat[key] and "●  " or "○  ")..title
            b.BackgroundColor3=combat[key] and Color3.fromRGB(50,86,82) or raised
        end
        draw()
        b.MouseButton1Click:Connect(function()combat[key]=not combat[key];draw()end)
        return b
    end
    labToggle(pages.combat,"Auto Block", "block")
    labToggle(pages.combat,"Auto Punch после парирования","punch")
    local mode=button(pages.combat,"")
    local function drawMode()
        mode.Text="Блок: "..(combat.blockMode=="animation" and "по атаке" or "по дистанции")
    end
    drawMode()
    mode.MouseButton1Click:Connect(function()
        combat.blockMode=combat.blockMode=="animation" and "distance" or "animation"
        drawMode()
    end)
    local radius=button(pages.combat,"")
    local function drawRadius()radius.Text="Дистанция блока: "..combat.blockRange.." studs  (нажми)" end
    drawRadius()
    radius.MouseButton1Click:Connect(function()
        combat.blockRange=combat.blockRange+2
        if combat.blockRange>18 then combat.blockRange=6 end
        drawRadius()
    end)
    local delay=button(pages.combat,"")
    local function drawDelay()delay.Text="Задержка блока: "..math.floor(combat.blockDelay*1000).." мс" end
    drawDelay()
    delay.MouseButton1Click:Connect(function()
        combat.blockDelay=combat.blockDelay+.04
        if combat.blockDelay>.24 then combat.blockDelay=0 end
        drawDelay()
    end)
    line(pages.combat,"NOLI  /  ЭКСПЕРИМЕНТ",30,mint,12)
    labToggle(pages.combat,"Помощь камерой при Void Rush","noli")
    local smoothing=button(pages.combat,"")
    local function drawSmooth()
        smoothing.Text="Плавность наведения: "..math.floor(combat.noliSmooth*100).." %"
    end
    drawSmooth()
    smoothing.MouseButton1Click:Connect(function()
        combat.noliSmooth=combat.noliSmooth+.05
        if combat.noliSmooth>.30 then combat.noliSmooth=.05 end
        drawSmooth()
    end)
    line(pages.combat,"NOSFERATU  /  ЭКСПЕРИМЕНТ",30,mint,12)
    labToggle(pages.combat,"Auto Bloodhook QTE","hook")
    local hookSpeed=button(pages.combat,"")
    local function drawHook()hookSpeed.Text="Интервал правильных нажатий: "..math.floor(combat.hookDelay*1000).." мс"end
    drawHook()
    hookSpeed.MouseButton1Click:Connect(function()
        combat.hookDelay=combat.hookDelay+.05
        if combat.hookDelay>.30 then combat.hookDelay=.10 end
        drawHook()
    end)
    line(pages.combat,"GUEST 666  /  ТАЙМЕР",30,mint,12)
    labToggle(pages.combat,"Показывать время во время Blood Hunt","clock")
    local combatState=line(pages.combat,"Автоматизация выключена по умолчанию. Сначала проверяй распознавание.",67,muted,11)

    -- Read-only puzzle detection; no guessed remotes or fake success.
    line(pages.puzzles,"ГЕНЕРАТОРЫ  /  ДИАГНОСТИКА",30,mint,12)
    local puzzleState=line(pages.puzzles,"Открой загадку на генераторе для определения её типа.",66,white,12)
    labToggle(pages.puzzles,"Отслеживать открытые загадки","genAssist")
    local puzzleScan=button(pages.puzzles,"Найти открытую головоломку")
    local puzzleCopy=button(pages.puzzles,"Скопировать описание интерфейса")
    line(pages.puzzles,"Dot/Blob, Gears и Locks определяются по доступному GUI. Автопрохождение требует точных игровых событий; оно пока НЕ включено.",85,muted,11)
    local puzzleReport=""
    local function visible(g)
        local p=g
        while p and p~=pg do
            if p:IsA("ScreenGui") and not p.Enabled then return false end
            if p:IsA("GuiObject") and not p.Visible then return false end
            p=p.Parent
        end
        return true
    end
    local function puzzleSnapshot()
        local found={}
        local hints={dot=0,blob=0,gear=0,lock=0}
        for _,v in ipairs(pg:GetDescendants()) do
            if not v:IsDescendantOf(gui) and
                (v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("Frame")) then
                local n=v.Name:lower()
                local t=(v:IsA("TextLabel") or v:IsA("TextButton")) and v.Text:lower() or ""
                local path=v:GetFullName():lower()
                if (n:find("puzzle") or n:find("generator") or n:find("numberlink")
                    or n:find("gear") or n:find("lock") or n:find("minigame")
                    or path:find("puzzle") or t:find("connect the")
                    or t:find("lockpick") or t:find("spin the")) and visible(v) then
                    local id=n.." "..t
                    if id:find("dot") or id:find("numberlink") or id:find("wire") then hints.dot=hints.dot+1 end
                    if id:find("blob") then hints.blob=hints.blob+1 end
                    if id:find("gear") then hints.gear=hints.gear+1 end
                    if id:find("lock") then hints.lock=hints.lock+1 end
                    if #found<80 then
                        found[#found+1]=v.Name.." ("..v.ClassName..") "..t:sub(1,80)
                    end
                end
            end
        end
        local best="не определён"
        for _,k in ipairs({"dot","blob","gear","lock"}) do
            if hints[k]>0 then best=({dot="Dot Numberlink",blob="Blob Numberlink",gear="Gears",lock="Pop the Lock"})[k] end
        end
        puzzleReport="NOVA puzzle UI | PlaceId="..game.PlaceId..
            "\nDetected="..best.."\n"..table.concat(found,"\n")
        puzzleState.Text="Тип: "..best.." | элементов: "..#found
    end
    puzzleScan.MouseButton1Click:Connect(function()
        local ok,err=pcall(puzzleSnapshot)
        if not ok then puzzleState.Text="Ошибка диагностики: "..tostring(err):sub(1,80) end
    end)
    puzzleCopy.MouseButton1Click:Connect(function()
        if type(setclipboard)=="function" then
            local ok=pcall(setclipboard,puzzleReport)
            puzzleState.Text=ok and "Данные скопированы" or "Не удалось скопировать"
        else
            puzzleState.Text="Буфер обмена недоступен; открой консоль NEO"
            print(puzzleReport)
        end
    end)

    -- The local actor is the in-round model, not necessarily Player.Character.Name.
    local function actor()
        local groups=workspace:FindFirstChild("Players")
        for _,role in ipairs({"Survivors","Killers"}) do
            local f=groups and groups:FindFirstChild(role)
            if f then
                for _,model in ipairs(f:GetChildren()) do
                    if model==player.Character or Players:GetPlayerFromCharacter(model)==player then
                        local name=tostring(model:GetAttribute("ActorDisplayName")
                            or model:GetAttribute("ActorName")
                            or model:GetAttribute("CharacterName")
                            or player:GetAttribute("CharacterName")
                            or model.Name):lower()
                        return model,role,name
                    end
                end
            end
        end
        return nil,nil,"нет персонажа в раунде"
    end
    local function root(model)
        return model and model:FindFirstChild("HumanoidRootPart")
    end
    local function nearest(group,from)
        local f=workspace:FindFirstChild("Players")
        f=f and f:FindFirstChild(group)
        local best,distance=nil,math.huge
        if not f or not from then return best,distance end
        for _,m in ipairs(f:GetChildren()) do
            if m:IsA("Model") and m~=player.Character then
                local r=root(m)
                local h=m:FindFirstChildOfClass("Humanoid")
                if r and (not h or h.Health>0) then
                    local d=(r.Position-from.Position).Magnitude
                    if d<distance then distance=d;best=m end
                end
            end
        end
        return best,distance
    end
    local function anim(model,patterns)
        local hum=model and model:FindFirstChildOfClass("Humanoid")
        local animator=hum and hum:FindFirstChildOfClass("Animator")
        if not animator then return false end
        for _,track in ipairs(animator:GetPlayingAnimationTracks()) do
            local a=track.Animation
            local n=a and a.Name:lower() or ""
            for _,pattern in ipairs(patterns) do
                if n:find(pattern,1,true) then return true end
            end
        end
        return false
    end
    local function clientFlag(model,keys)
        if not model then return false end
        for _,key in ipairs(keys) do
            if model:GetAttribute(key)==true then return true end
            local v=model:FindFirstChild(key,true)
            if v and v:IsA("BoolValue") and v.Value then return true end
        end
        return false
    end
    local function keyInput(key)
        local ok=pcall(function()
            VirtualInputManager:SendKeyEvent(true,key,false,game)
            task.wait(.03)
            VirtualInputManager:SendKeyEvent(false,key,false,game)
        end)
        return ok
    end
    local function abilityClick(ability,key)
        local target=nil
        for _,v in ipairs(pg:GetDescendants()) do
            if v:IsA("GuiButton") and not v:IsDescendantOf(gui) and visible(v) then
                local title=v:IsA("TextButton") and v.Text:lower() or ""
                local n=v.Name:lower()
                if n==ability:lower() or title==ability:lower() then
                    target=v;break
                end
            end
        end
        if target then
            local pos=target.AbsolutePosition+target.AbsoluteSize/2
            local ok=pcall(function()
                VirtualInputManager:SendMouseButtonEvent(pos.X,pos.Y,0,true,game,0)
                task.wait(.02)
                VirtualInputManager:SendMouseButtonEvent(pos.X,pos.Y,0,false,game,0)
            end)
            if ok then return true end
        end
        return keyInput(key)
    end
    local lastBlock=-100,lastPunch=-100,lastHook=-100
    local blockIssuedAt=-100
    local lastSuccess=false
    local waitingBlockAt=nil
    local lastAction="Готово"
    local keymap={
        A=Enum.KeyCode.A,B=Enum.KeyCode.B,C=Enum.KeyCode.C,
        D=Enum.KeyCode.D,E=Enum.KeyCode.E,F=Enum.KeyCode.F,
        Q=Enum.KeyCode.Q,R=Enum.KeyCode.R,S=Enum.KeyCode.S,
        W=Enum.KeyCode.W,X=Enum.KeyCode.X,Y=Enum.KeyCode.Y,
        Z=Enum.KeyCode.Z,SPACE=Enum.KeyCode.Space
    }
    -- Only use the displayed QTE key; random input is penalized by the game.
    local function hookPrompt()
        for _,v in ipairs(pg:GetDescendants()) do
            if v:IsA("TextLabel") and not v:IsDescendantOf(gui) and visible(v) then
                local parent=v
                local tagged=false
                for i=1,5 do
                    parent=parent.Parent
                    if not parent or parent==pg then break end
                    local n=parent.Name:lower()
                    if n:find("bloodhook") or n:find("blood_hook") or
                        n:find("quicktime") or n:find("qte") or n:find("actioncommand") then
                        tagged=true;break
                    end
                end
                if tagged then
                    local txt=v.Text:upper():gsub("%s+"," ")
                    local key=txt:match("^%s*%[?([A-Z])%]?%s*$")
                        or txt:match("PRESS%s+([A-Z])")
                        or txt:match("%[([A-Z])%]")
                    if txt:find("SPACE",1,true) then key="SPACE" end
                    if key and keymap[key] then return key end
                end
            end
        end
        return nil
    end
    -- Blood Hunt timer: exact value when replicated, otherwise estimated at half speed.
    local clockHud=obj("Frame",gui,{
        Position=UDim2.new(.5,-94,0,12),Size=UDim2.fromOffset(188,35),
        BackgroundColor3=panelBg,BorderSizePixel=0,Visible=false
    })
    corners(clockHud,9)
    local clockText=obj("TextLabel",clockHud,{
        Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
        Text="BLOOD HUNT  •  —",TextColor3=white,
        Font=Enum.Font.GothamBold,TextSize=12
    })
    local clockBase=nil
    local clockAt=0
    local clockExact=false
    local hunt=false
    local function parseTime(text)
        local mm,ss=tostring(text):match("(%d+)%s*:%s*(%d%d)")
        if not mm or not ss or tonumber(ss)>59 then return nil end
        return tonumber(mm)*60+tonumber(ss)
    end
    local function getRoundTime()
        for _,container in ipairs({workspace,ReplicatedStorage}) do
            local grp=container:FindFirstChild("Game") or
                container:FindFirstChild("GameStats") or
                container:FindFirstChild("Round")
            if grp then
                for _,key in ipairs({"RoundTime","RoundTimer","TimeRemaining","TimeLeft"}) do
                    local val=grp:FindFirstChild(key)
                    if val and (val:IsA("NumberValue") or val:IsA("IntValue")) then
                        return math.max(0,tonumber(val.Value) or 0),true
                    end
                end
            end
        end
        local best=nil
        for _,v in ipairs(pg:GetDescendants()) do
            if v:IsA("TextLabel") and not v:IsDescendantOf(gui) and visible(v) then
                local id=(v.Name.." "..v.Parent.Name):lower()
                if id:find("timer") or id:find("round") or id:find("timeleft") then
                    local seconds=parseTime(v.Text)
                    if seconds and seconds<=1800 then
                        best=seconds;break
                    end
                end
            end
        end
        return best,false
    end
    local function huntActive()
        local f=workspace:FindFirstChild("Players")
        local killers=f and f:FindFirstChild("Killers")
        if not killers then return false end
        for _,m in ipairs(killers:GetChildren()) do
            local id=(m.Name.." "..tostring(m:GetAttribute("ActorName") or "")):lower()
            if id:find("guest666") or id:find("guest 666") then
                if clientFlag(m,{"BloodHunt","IsBloodHunt","BloodHuntActive","Hunting"}) or
                    anim(m,{"bloodhunt"}) then return true end
                for _,guiEl in ipairs(pg:GetDescendants()) do
                    if guiEl:IsA("TextLabel") and visible(guiEl) and not guiEl:IsDescendantOf(gui) then
                        local t=guiEl.Text:upper()
                        if t:find("HI:DE",1,true) or t=="RUN" then return true end
                    end
                end
            end
        end
        return false
    end
    local function clockTick()
        if not combat.clock then clockHud.Visible=false;return end
        local observed,exact=getRoundTime()
        local currentlyHunting=huntActive()
        if observed~=nil then
            clockBase=observed
            clockAt=os.clock()
            clockExact=exact
        end
        if not currentlyHunting then
            clockHud.Visible=false
            hunt=false
            return
        end
        hunt=true
        clockHud.Visible=true
        if clockBase then
            local value=clockBase
            if not clockExact then value=math.max(0,value-(os.clock()-clockAt)*.5) end
            local seconds=math.floor(value+0.5)
            clockText.Text=(clockExact and "BLOOD HUNT  " or "BLOOD HUNT  ≈")..
                string.format("%02d:%02d",math.floor(seconds/60),seconds%60)
        else
            clockText.Text="BLOOD HUNT  •  НЕТ ВРЕМЕНИ"
        end
    end
    task.spawn(function()
        local previousCharacter=""
        while running do
            local success,err=pcall(function()
                local model,role,name=actor()
                if name~=previousCharacter then previousCharacter=name; lastSuccess=false end
                feedback.Text="Персонаж: "..name.." | "..(role or "лобби")
                local now=os.clock()
                if role=="Survivors" and name:find("guest") and name:find("1337") then
                    local r=root(model)
                    local killer,d=nearest("Killers",r)
                    if combat.block and killer and d<=combat.blockRange then
                        local theirRoot=root(killer)
                        local facing=theirRoot and
                            theirRoot.CFrame.LookVector:Dot((r.Position-theirRoot.Position).Unit)>.12
                        local hitting=anim(killer,{"attack","slash","stab","swing","punch","m1"})
                        local action=(combat.blockMode=="distance" or hitting)
                        if facing and action and now-lastBlock>27.3 and not waitingBlockAt then
                            waitingBlockAt=now+combat.blockDelay
                        end
                    end
                    if waitingBlockAt and now>=waitingBlockAt then
                        waitingBlockAt=nil
                        if abilityClick("Block",Enum.KeyCode.Q) then
                            lastBlock=now;blockIssuedAt=now;lastAction="BLOCK отправлен"
                        end
                    end
                    local parry=clientFlag(model,{"BlockSuccess","SuccessfulBlock",
                        "SuccessBlock","ParryWindow","Parried"}) or
                        anim(model,{"blocksuccess","parry"})
                    if not parry and now-blockIssuedAt<1.4 then
                        for _,v in ipairs(model:GetDescendants()) do
                            if v:IsA("Sound") and v.IsPlaying and
                                (v.Name:lower():find("blocksuccess",1,true) or
                                 v.Name:lower():find("parry",1,true)) then
                                parry=true;break
                            end
                        end
                    end
                    if combat.punch and parry and not lastSuccess and
                        now-lastBlock<1.5 and now-lastPunch>1.5 then
                        if abilityClick("Punch",Enum.KeyCode.R) then
                            lastPunch=now;lastAction="PARRY PUNCH отправлен"
                        end
                    end
                    lastSuccess=parry
                else
                    waitingBlockAt=nil
                    lastSuccess=false
                end
                if combat.hook and role=="Killers" and name:find("nosferatu") then
                    local key=hookPrompt()
                    if key and now-lastHook>combat.hookDelay then
                        if keyInput(keymap[key]) then
                            lastHook=now;lastAction="BLOODHOOK: "..key
                        end
                    end
                end
                if combat.noli and role=="Killers" and name:find("noli") and
                    (clientFlag(model,{"VoidRushing","UsingVoidRush","IsVoidRushing"})
                    or anim(model,{"voidrush","void rush"})) then
                    local cam=workspace.CurrentCamera
                    local r=root(model)
                    local target,d=nearest("Survivors",r)
                    local t=target and root(target)
                    if cam and t and d<75 then
                        local desired=CFrame.lookAt(cam.CFrame.Position,t.Position)
                        cam.CFrame=cam.CFrame:Lerp(desired,combat.noliSmooth)
                        lastAction="VOID RUSH: камера → цель"
                    end
                end
                combatState.Text=lastAction
                clockTick()
            end)
            if not success then combatState.Text="LAB ошибка: "..tostring(err):sub(1,75) end
            task.wait(.10)
        end
    end)
    task.spawn(function()
        while running do
            if combat.genAssist then pcall(puzzleSnapshot) end
            task.wait(2)
        end
    end)
end)
if not okLab then warn("[NOVA 0.6 experimental]",labError) end
