-- NOVA FORSAKEN v0.4.0
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
for _, name in ipairs({"NOVA_MINI", "NOVA_ESP_V03", "NOVA_SHORT", "NOVA_ESP_031", "NOVA_ESP_040"}) do
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
local questOn, questTier, questProgress, questGoal = false, 1, 0, 1
local questText = "Впиши задание во вкладке ИВЕНТ"
local function obj(class, parent, properties)
    local instance = Instance.new(class)
    for k, v in pairs(properties or {}) do instance[k] = v end
    instance.Parent = parent
    return instance
end
local function corners(frame, radius)
    obj("UICorner", frame, {CornerRadius=UDim.new(0, radius or 8)})
end
local gui = obj("ScreenGui", pg, {
    Name = "NOVA_ESP_040", ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 9999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})
local win = obj("Frame", gui, {
    Size=UDim2.fromOffset(365, 320),
    Position=UDim2.new(0.5,-182,0.5,-160),
    BackgroundColor3=Color3.fromRGB(20,22,36), BorderSizePixel=0
})
corners(win, 12)
obj("UIStroke", win, {Color=Color3.fromRGB(117,81,190),Thickness=1.3})
local top = obj("Frame", win, {
    Size=UDim2.new(1,0,0,41), BackgroundTransparency=1
})
obj("TextLabel", top, {
    Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-105,1,0),
    BackgroundTransparency=1,Text="NOVA  /  ESP 0.4",
    TextColor3=Color3.fromRGB(222,197,255),
    Font=Enum.Font.GothamBold,TextSize=16,
    TextXAlignment=Enum.TextXAlignment.Left
})
local minimize = obj("TextButton", top, {
    Position=UDim2.new(1,-80,0,6),Size=UDim2.fromOffset(33,29),
    BackgroundColor3=Color3.fromRGB(50,54,80),BorderSizePixel=0,
    Text="–",TextColor3=Color3.new(1,1,1),TextSize=20
})
corners(minimize,6)
local quit = obj("TextButton", top, {
    Position=UDim2.new(1,-42,0,6),Size=UDim2.fromOffset(33,29),
    BackgroundColor3=Color3.fromRGB(129,49,76),BorderSizePixel=0,
    Text="×",TextColor3=Color3.new(1,1,1),TextSize=19
})
corners(quit,6)
local bubble = obj("TextButton",gui,{
    Size=UDim2.fromOffset(48,48),Position=UDim2.new(0,12,0.45,0),
    BackgroundColor3=Color3.fromRGB(111,72,195),BorderSizePixel=0,
    Text="N",TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold,TextSize=21,Visible=false
})
corners(bubble,12)
minimize.MouseButton1Click:Connect(function()
    win.Visible=false; bubble.Visible=true
end)
bubble.MouseButton1Click:Connect(function()
    win.Visible=true; bubble.Visible=false
end)

local drag, dragStart, winStart, inputObject = false, nil, nil, nil
top.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
        drag=true; inputObject=input; dragStart=input.Position; winStart=win.Position
        input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then drag=false end
        end)
    end
end)
local dragConnection = UIS.InputChanged:Connect(function(input)
    if drag and (input==inputObject or input.UserInputType==Enum.UserInputType.MouseMovement) then
        local delta=input.Position-dragStart
        win.Position=UDim2.new(winStart.X.Scale,winStart.X.Offset+delta.X,
            winStart.Y.Scale,winStart.Y.Offset+delta.Y)
    end
end)

local tabs=obj("Frame",win,{
    Position=UDim2.fromOffset(9,44),Size=UDim2.new(1,-18,0,31),BackgroundTransparency=1
})
local pageButtons,pages={},{}
for i,item in ipairs({{"esp","ESP"},{"colors","ЦВЕТА"},{"settings","ОПЦИИ"},{"event","ИВЕНТ"}}) do
    local key,title=item[1],item[2]
    local b=obj("TextButton",tabs,{
        Size=UDim2.new(1/4,-6,1,0),Position=UDim2.new((i-1)/4,3,0,0),
        BackgroundColor3=Color3.fromRGB(47,53,77),BorderSizePixel=0,
        Text=title,Font=Enum.Font.GothamBold,TextSize=12,
        TextColor3=Color3.new(1,1,1)
    })
    corners(b,6)
    pageButtons[key]=b
    local scroll=obj("ScrollingFrame",win,{
        Position=UDim2.fromOffset(11,81),Size=UDim2.new(1,-22,1,-130),
        ScrollBarThickness=4,CanvasSize=UDim2.fromOffset(0,0),
        BackgroundTransparency=1,BorderSizePixel=0,Visible=key=="esp"
    })
    pages[key]=scroll
    local layout=obj("UIListLayout",scroll,{
        Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder
    })
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize=UDim2.fromOffset(0,layout.AbsoluteContentSize.Y+10)
    end)
    b.MouseButton1Click:Connect(function()
        for id,p in pairs(pages) do
            p.Visible=(id==key)
            pageButtons[id].BackgroundColor3=(id==key)
                and Color3.fromRGB(104,68,180) or Color3.fromRGB(47,53,77)
        end
    end)
end
pageButtons.esp.BackgroundColor3=Color3.fromRGB(104,68,180)
local function line(parent,text,height)
    return obj("TextLabel",parent,{
        Size=UDim2.new(1,-8,0,height or 26),BackgroundTransparency=1,
        Text=text,TextColor3=Color3.fromRGB(216,218,238),
        Font=Enum.Font.Gotham,TextSize=12,TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left
    })
end
local function button(parent,text)
    local b=obj("TextButton",parent,{
        Size=UDim2.new(1,-8,0,32),BackgroundColor3=Color3.fromRGB(51,60,83),
        BorderSizePixel=0,Text=text,TextColor3=Color3.new(1,1,1),
        Font=Enum.Font.GothamMedium,TextSize=12
    })
    corners(b,6)
    return b
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
line(pages.esp,"Включай категории по отдельности. Всё работает локально.",29)
for _,info in ipairs(categories) do
    local id,name=info[1],info[2]
    local b=button(pages.esp,"")
    local function draw()
        b.Text=(show[id] and "●  ВКЛ   " or "○  ВЫКЛ  ")..name
        b.BackgroundColor3=show[id] and Color3.fromRGB(45,81,74)
            or Color3.fromRGB(54,54,75)
    end
    draw()
    b.MouseButton1Click:Connect(function() show[id]=not show[id];draw() end)
end
line(pages.colors,"Квадрат меняет цвет; HEX справа — точный оттенок.",32)
for _,info in ipairs(categories) do
    local id,name=info[1],info[2]
    local r=obj("Frame",pages.colors,{
        Size=UDim2.new(1,-8,0,36),BorderSizePixel=0,
        BackgroundColor3=Color3.fromRGB(35,39,59)
    })
    corners(r,6)
    obj("TextLabel",r,{
        Size=UDim2.new(1,-117,1,0),Position=UDim2.fromOffset(8,0),
        BackgroundTransparency=1,Text=name,TextXAlignment=Enum.TextXAlignment.Left,
        TextColor3=Color3.new(1,1,1),TextSize=12,Font=Enum.Font.Gotham
    })
    local swatch=obj("TextButton",r,{
        Position=UDim2.new(1,-110,0,6),Size=UDim2.fromOffset(24,24),
        BackgroundColor3=color[id],BorderSizePixel=0,Text=""
    })
    corners(swatch,4)
    local entry=obj("TextBox",r,{
        Position=UDim2.new(1,-81,0,5),Size=UDim2.fromOffset(75,26),
        BackgroundColor3=Color3.fromRGB(59,63,84),BorderSizePixel=0,
        Text=hex(color[id]),ClearTextOnFocus=false,
        TextColor3=Color3.new(1,1,1),Font=Enum.Font.Code,TextSize=12
    })
    corners(entry,4)
    local index=0
    swatch.MouseButton1Click:Connect(function()
        index=index%#palette+1
        color[id]=palette[index]
        swatch.BackgroundColor3=color[id]
        entry.Text=hex(color[id])
    end)
    entry.FocusLost:Connect(function()
        color[id]=fromHex(entry.Text) or color[id]
        swatch.BackgroundColor3=color[id]
        entry.Text=hex(color[id])
    end)
end
local nameBtn=button(pages.settings,"")
local distanceBtn=button(pages.settings,"")
local fillBtn=button(pages.settings,"")
local liteBtn=button(pages.settings,"")
local speedBtn=button(pages.settings,"")
local blindBtn=button(pages.settings,"")
local function redrawSettings()
    nameBtn.Text="Названия: "..(labelsOn and "ВКЛ" or "ВЫКЛ")
    distanceBtn.Text="Расстояние: "..(distanceOn and "ВКЛ" or "ВЫКЛ")
    fillBtn.Text="Заливка: "..tostring(math.floor((1-transparency)*100+.5)).."%"
    liteBtn.Text="Lite ESP: "..(liteMode and "ВКЛ (без подписей)" or "ВЫКЛ")
    speedBtn.Text="Проверка ESP: раз в "..tostring(refreshSteps[refreshIndex]).." сек."
    blindBtn.Text="Anti Blind: "..(antiBlindOn and "ВКЛ" or "ВЫКЛ")
end
redrawSettings()
nameBtn.MouseButton1Click:Connect(function() labelsOn=not labelsOn;redrawSettings() end)
distanceBtn.MouseButton1Click:Connect(function() distanceOn=not distanceOn;redrawSettings() end)
fillBtn.MouseButton1Click:Connect(function()
    transparency=transparency-.15
    if transparency<.2 then transparency=.95 end
    redrawSettings()
end)
liteBtn.MouseButton1Click:Connect(function() liteMode=not liteMode;redrawSettings() end)
speedBtn.MouseButton1Click:Connect(function()
    refreshIndex=refreshIndex%#refreshSteps+1;redrawSettings()
end)
blindBtn.MouseButton1Click:Connect(function() antiBlindOn=not antiBlindOn;redrawSettings() end)
line(pages.settings,"Lite скрывает подписи и расстояния. Anti Blind отключает доступные клиенту эффекты размытия и ослепления.",66)
line(pages.settings,"Фейковые генераторы определяются только по признакам, доступным клиенту; распознавание может быть неполным.",65)

-- Manual event tracker: no claims about reading the pass automatically.
local hud=obj("Frame",gui,{
    Position=UDim2.new(0,12,0.14,0),Size=UDim2.fromOffset(310,104),
    BackgroundColor3=Color3.fromRGB(25,21,42),BorderSizePixel=0,Visible=false
})
corners(hud,10)
obj("UIStroke",hud,{Color=Color3.fromRGB(156,98,204),Thickness=1})
local hudTitle=obj("TextLabel",hud,{
    Position=UDim2.fromOffset(10,5),Size=UDim2.new(1,-20,0,24),
    BackgroundTransparency=1,TextColor3=Color3.fromRGB(235,191,255),
    Text="FORSAKEWEEN",Font=Enum.Font.GothamBold,TextSize=14,
    TextXAlignment=Enum.TextXAlignment.Left
})
local hudQuest=obj("TextLabel",hud,{
    Position=UDim2.fromOffset(10,29),Size=UDim2.new(1,-20,0,49),
    BackgroundTransparency=1,TextColor3=Color3.fromRGB(239,238,255),
    TextWrapped=true,Font=Enum.Font.Gotham,TextSize=12,
    TextXAlignment=Enum.TextXAlignment.Left
})
local hudProgress=obj("TextLabel",hud,{
    Position=UDim2.fromOffset(10,80),Size=UDim2.new(1,-20,0,20),
    BackgroundTransparency=1,TextColor3=Color3.fromRGB(195,210,255),
    Font=Enum.Font.GothamMedium,TextSize=12,
    TextXAlignment=Enum.TextXAlignment.Left
})
local function redrawQuest()
    hud.Visible=questOn
    hudTitle.Text="FORSAKEWEEN | ТИР "..questTier.." [ручной]"
    hudQuest.Text=questText
    hudProgress.Text="ПРОГРЕСС: "..questProgress.." / "..questGoal
end
local questToggle=button(pages.event,"")
local questTierLabel=line(pages.event,"Текущий тир: 1",26)
local questPrev=button(pages.event,"Предыдущий тир -1")
local questNext=button(pages.event,"Следующий тир +1")
line(pages.event,"Задание и прогресс пока вводятся вручную — игра может не предоставлять их клиенту.",44)
line(pages.event,"Текст задания:",22)
local questInput=obj("TextBox",pages.event,{
    Size=UDim2.new(1,-8,0,65),BackgroundColor3=Color3.fromRGB(49,47,74),
    BorderSizePixel=0,Text=questText,MultiLine=true,TextWrapped=true,
    ClearTextOnFocus=false,TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.Gotham,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left
})
corners(questInput,6)
line(pages.event,"Сколько нужно выполнить (например, 5):",25)
local goalInput=obj("TextBox",pages.event,{
    Size=UDim2.new(1,-8,0,33),BackgroundColor3=Color3.fromRGB(49,47,74),
    BorderSizePixel=0,Text="1",ClearTextOnFocus=false,
    TextColor3=Color3.new(1,1,1),Font=Enum.Font.Gotham,TextSize=12
})
corners(goalInput,6)
local questMinus=button(pages.event,"Прогресс -1")
local questPlus=button(pages.event,"Прогресс +1")
local function refreshQuestButtons()
    questToggle.Text="Показывать HUD: "..(questOn and "ВКЛ" or "ВЫКЛ")
    questTierLabel.Text="Текущий тир: "..questTier
    redrawQuest()
end
questToggle.MouseButton1Click:Connect(function() questOn=not questOn;refreshQuestButtons() end)
questPrev.MouseButton1Click:Connect(function()
    questTier=math.max(1,questTier-1);questProgress=0;refreshQuestButtons()
end)
questNext.MouseButton1Click:Connect(function()
    questTier=questTier+1;questProgress=0;refreshQuestButtons()
end)
questInput.FocusLost:Connect(function()
    questText=questInput.Text:sub(1,220);redrawQuest()
end)
goalInput.FocusLost:Connect(function()
    questGoal=math.clamp(tonumber(goalInput.Text) or questGoal,1,9999)
    questGoal=math.floor(questGoal)
    questProgress=math.min(questProgress,questGoal)
    goalInput.Text=tostring(questGoal)
    redrawQuest()
end)
questMinus.MouseButton1Click:Connect(function()
    questProgress=math.max(0,questProgress-1);redrawQuest()
end)
questPlus.MouseButton1Click:Connect(function()
    questProgress=math.min(questGoal,questProgress+1);redrawQuest()
end)
refreshQuestButtons()

local status=obj("TextLabel",win,{
    Position=UDim2.new(0,10,1,-44),Size=UDim2.new(1,-20,0,38),
    BackgroundColor3=Color3.fromRGB(30,34,51),BorderSizePixel=0,
    Text="ESP: сканирование...",TextColor3=Color3.fromRGB(232,218,255),
    Font=Enum.Font.Gotham,TextSize=11,TextWrapped=true
})
corners(status,6)

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
    for model in pairs(markers) do clear(model) end
    gui:Destroy()
end
env.NovaESPStop=stop
quit.MouseButton1Click:Connect(stop)
task.spawn(function()
    while running do
        local ok,err=pcall(scan)
        if not ok then
            warn("[NOVA 0.3.1] ",err)
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
print("[NOVA] ESP v0.4 started")
