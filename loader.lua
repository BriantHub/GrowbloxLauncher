--[[
 Growblox Launcher V2.0 (Roblox / Delta Android)
 Entry point: run this Luau source directly or host as loader.lua on GitHub Raw.
 Target hint: Growblox by ExecutiveStudio (PlaceId 112863874972771).
 Local player utility only. Does not obtain admin rights or modify server data.
 If a game uses a custom 2D/avatar controller, character movement tools may not apply.
]]

local TAG = "[Growblox V2] "
local function log(msg)
    print(TAG .. tostring(msg))
end
local function warnLog(msg)
    warn(TAG .. tostring(msg))
end

local ok, err = xpcall(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local Lighting = game:GetService("Lighting")
    local Workspace = game:GetService("Workspace")
    local player = Players.LocalPlayer
    if not player then
        for _ = 1, 30 do
            task.wait(0.2)
            player = Players.LocalPlayer
            if player then break end
        end
    end
    if not player then error("LocalPlayer tidak tersedia. Masuk ke game dulu.") end
    local playerGui = player:WaitForChild("PlayerGui", 10)
    if not playerGui then error("PlayerGui tidak ditemukan sesudah 10 detik.") end

    local env = _G
    pcall(function() if type(getgenv) == "function" then env = getgenv() end end)
    if type(env.GrowbloxLauncherV2) == "table" and type(env.GrowbloxLauncherV2.Destroy) == "function" then
        pcall(env.GrowbloxLauncherV2.Destroy)
    end
    local old = playerGui:FindFirstChild("GrowbloxLauncherV2")
    if old then old:Destroy() end
    local oldPopup = playerGui:FindFirstChild("GrowbloxStartupTest")
    if oldPopup then oldPopup:Destroy() end

    local alive = true
    local connections = {}
    local visuals = {}
    local oldCollision = {}
    local originals = {}
    local flightForce
    local currentRoot
    local flyPad
    local elapsed = 0
    local espElapsed = 0
    local inspectMessage = "Ketuk INSPECT lalu sentuh suatu objek di map."
    local lastError = "Tidak ada error terdeteksi."
    local states = {
        fly = false, noclip = false, speed = false, jump = false,
        infjump = false, fullbright = false, esp = false, dev = false,
        flySpeed = 38, walkSpeed = 30, jumpPower = 80,
    }
    local hold = {left=false,right=false,up=false,down=false}
    local palettes = {
        bg=Color3.fromRGB(16,21,31), panel=Color3.fromRGB(26,35,50),
        control=Color3.fromRGB(43,56,73), active=Color3.fromRGB(55,219,164),
        txt=Color3.fromRGB(237,247,250),dim=Color3.fromRGB(164,181,198),
        danger=Color3.fromRGB(195,80,90),
    }
    local function bind(sig, fn)
        local conn=sig:Connect(fn)
        table.insert(connections,conn)
        return conn
    end
    local function create(class, props, parent)
        local obj=Instance.new(class)
        for k,v in pairs(props or {}) do obj[k]=v end
        obj.Parent=parent
        return obj
    end
    local function rounded(obj,radius)
        create("UICorner",{CornerRadius=UDim.new(0,radius or 9)},obj)
        return obj
    end
    local function getCharacter()
        local character=player.Character
        if not character then return nil,nil,nil end
        local hum=character:FindFirstChildOfClass("Humanoid")
        local root=character:FindFirstChild("HumanoidRootPart")
            or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
            or character.PrimaryPart or character:FindFirstChildWhichIsA("BasePart",true)
        if hum and not originals[hum] then
            originals[hum]={WalkSpeed=hum.WalkSpeed,JumpPower=hum.JumpPower,
                JumpHeight=hum.JumpHeight,UseJumpPower=hum.UseJumpPower,
                PlatformStand=hum.PlatformStand,AutoRotate=hum.AutoRotate}
        end
        return character,hum,root
    end
    local function status(message)
        lastError=tostring(message)
        log(lastError)
    end
    local lightDefaults={Brightness=Lighting.Brightness,ClockTime=Lighting.ClockTime,
        GlobalShadows=Lighting.GlobalShadows,Ambient=Lighting.Ambient,
        OutdoorAmbient=Lighting.OutdoorAmbient}
    local function setLight(on)
        if on then
            Lighting.Brightness=3
            Lighting.ClockTime=12
            Lighting.GlobalShadows=false
            Lighting.Ambient=Color3.fromRGB(190,190,190)
            Lighting.OutdoorAmbient=Color3.fromRGB(190,190,190)
        else
            for k,v in pairs(lightDefaults) do pcall(function() Lighting[k]=v end) end
        end
    end
    local function restoreCollisions()
        for part,v in pairs(oldCollision) do
            if part and part.Parent then pcall(function() part.CanCollide=v end) end
            oldCollision[part]=nil
        end
    end
    local function stopFlight()
        if flightForce then pcall(function() flightForce:Destroy() end) end
        flightForce=nil
        currentRoot=nil
        local _,hum=getCharacter()
        if hum and originals[hum] then
            pcall(function()
                hum.PlatformStand=originals[hum].PlatformStand
                hum.AutoRotate=originals[hum].AutoRotate
            end)
        end
        for key in pairs(hold) do hold[key]=false end
    end
    local function clearESP()
        for _,obj in pairs(visuals) do pcall(function() obj:Destroy() end) end
        table.clear(visuals)
    end
    local function resetHumanoidProperties()
        local _,hum=getCharacter()
        if hum and originals[hum] then
            local orig=originals[hum]
            pcall(function()
                if not states.speed then hum.WalkSpeed=orig.WalkSpeed end
                if not states.jump then
                    hum.UseJumpPower=orig.UseJumpPower
                    hum.JumpPower=orig.JumpPower
                    hum.JumpHeight=orig.JumpHeight
                end
            end)
        end
    end
    local function toggle(key,value)
        states[key]=value
        if key=="fly" and not value then stopFlight() end
        if key=="noclip" and not value then restoreCollisions() end
        if key=="fullbright" then pcall(setLight,value) end
        if key=="esp" and not value then clearESP() end
        if key=="speed" or key=="jump" then resetHumanoidProperties() end
        if key=="fly" and value then
            local _,_,root=getCharacter()
            if not root then status("Fly aktif, tapi BasePart karakter tidak ditemukan (mungkin controller 2D).") end
        end
    end

    -- PlayerGui is intentionally used instead of CoreGui/gethui for mobile visibility.
    local gui=create("ScreenGui",{
        Name="GrowbloxLauncherV2",ResetOnSpawn=false,IgnoreGuiInset=false,
        DisplayOrder=200000,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    },playerGui)
    local bubble=rounded(create("TextButton",{
        Name="OpenButton",Text="GB",Font=Enum.Font.GothamBlack,TextSize=18,
        TextColor3=palettes.bg,BackgroundColor3=palettes.active,BorderSizePixel=0,
        Position=UDim2.new(0,8,0.22,0),Size=UDim2.fromOffset(48,48),
        ZIndex=20,Visible=true,
    },gui),24)
    local main=rounded(create("Frame",{
        Name="Main",BackgroundColor3=palettes.bg,BorderSizePixel=0,
        Position=UDim2.new(0,61,0.13,0),Size=UDim2.fromOffset(302,382),
        Visible=true,Active=true,
    },gui),13)
    create("UIStroke",{Color=palettes.active,Transparency=.37,Thickness=1},main)
    local uiScale=create("UIScale",{Scale=1},main)
    local function resize()
        local cam=Workspace.CurrentCamera
        if cam then
            uiScale.Scale=math.min(1,math.max(.66,cam.ViewportSize.X/410))
        end
    end
    resize()
    local header=create("Frame",{
        BackgroundColor3=palettes.panel,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,47),Active=true,
    },main)
    rounded(header,13)
    create("TextLabel",{
        BackgroundTransparency=1,Text="GROWBLOX LAUNCHER  V2",
        Font=Enum.Font.GothamBold,TextSize=13,
        TextColor3=palettes.txt,TextXAlignment=Enum.TextXAlignment.Left,
        Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-88,1,0),
    },header)
    local minimize=rounded(create("TextButton",{
        Text="_",Font=Enum.Font.GothamBold,TextSize=19,
        TextColor3=palettes.txt,BackgroundColor3=palettes.control,
        Position=UDim2.new(1,-78,0,9),Size=UDim2.fromOffset(29,29),
    },header),6)
    local close=rounded(create("TextButton",{
        Text="X",Font=Enum.Font.GothamBold,TextSize=15,
        TextColor3=palettes.txt,BackgroundColor3=palettes.danger,
        Position=UDim2.new(1,-41,0,9),Size=UDim2.fromOffset(29,29),
    },header),6)
    create("TextLabel",{
        BackgroundTransparency=1,Text="Muncul = executor berjalan | tombol GB untuk buka/tutup",
        TextColor3=palettes.dim,TextSize=9,Font=Enum.Font.Gotham,
        Size=UDim2.new(1,-16,0,27),Position=UDim2.fromOffset(8,48),
    },main)
    local tabBar=create("Frame",{
        BackgroundTransparency=1,Position=UDim2.fromOffset(8,77),
        Size=UDim2.new(1,-16,0,35),
    },main)
    create("UIListLayout",{
        FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,5),
    },tabBar)
    local pages={}
    local tabs={}
    for i,name in ipairs({"Move","Visual","Dev"}) do
        local b=rounded(create("TextButton",{
            Text=name,Font=Enum.Font.GothamSemibold,TextSize=12,
            TextColor3=palettes.txt,BackgroundColor3=palettes.control,
            Size=UDim2.new(1/3,-4,1,0),LayoutOrder=i,
        },tabBar),7)
        local page=create("ScrollingFrame",{
            Name=name.."Page",BackgroundTransparency=1,BorderSizePixel=0,
            Position=UDim2.fromOffset(8,120),Size=UDim2.new(1,-16,1,-128),
            ScrollBarThickness=3,ScrollBarImageColor3=palettes.active,
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            CanvasSize=UDim2.fromOffset(0,0),Visible=false,
        },main)
        create("UIListLayout",{
            Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder,
            FillDirection=Enum.FillDirection.Vertical,
        },page)
        create("UIPadding",{
            PaddingTop=UDim.new(0,3),PaddingBottom=UDim.new(0,7),
            PaddingLeft=UDim.new(0,1),PaddingRight=UDim.new(0,4),
        },page)
        pages[name]=page
        tabs[name]=b
    end
    local function switchTab(name)
        for n,page in pairs(pages) do
            page.Visible=n==name
            tabs[n].BackgroundColor3=(n==name) and palettes.active or palettes.control
            tabs[n].TextColor3=(n==name) and palettes.bg or palettes.txt
        end
    end
    for name,button in pairs(tabs) do bind(button.MouseButton1Click,function() switchTab(name) end) end
    switchTab("Move")

    local refreshAll
    local toggleButtons={}
    local function label(page,text,height,mono)
        return create("TextLabel",{
            Text=text,BackgroundTransparency=1,TextColor3=palettes.dim,
            TextSize=11,Font=mono and Enum.Font.Code or Enum.Font.Gotham,
            TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
            TextYAlignment=Enum.TextYAlignment.Top,
            Size=UDim2.new(1,-8,0,height or 36),
        },page)
    end
    local function toggleRow(page,key,title,description)
        local outer=rounded(create("Frame",{
            BackgroundColor3=palettes.panel,BorderSizePixel=0,
            Size=UDim2.new(1,-5,0,51),
        },page),8)
        create("TextLabel",{
            Text=title,TextColor3=palettes.txt,
            Font=Enum.Font.GothamBold,TextSize=12,
            TextXAlignment=Enum.TextXAlignment.Left,
            BackgroundTransparency=1,
            Size=UDim2.new(1,-86,0,23),Position=UDim2.fromOffset(8,2),
        },outer)
        create("TextLabel",{
            Text=description,TextColor3=palettes.dim,Font=Enum.Font.Gotham,
            TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,
            BackgroundTransparency=1,
            Size=UDim2.new(1,-10,0,20),Position=UDim2.fromOffset(8,28),
        },outer)
        local button=rounded(create("TextButton",{
            Text="OFF",TextColor3=palettes.txt,Font=Enum.Font.GothamBold,
            TextSize=12,BackgroundColor3=palettes.control,
            Size=UDim2.fromOffset(64,29),Position=UDim2.new(1,-73,0,7),
        },outer),7)
        toggleButtons[key]=button
        bind(button.MouseButton1Click,function()
            toggle(key,not states[key])
            refreshAll()
        end)
    end
    refreshAll=function()
        for key,b in pairs(toggleButtons) do
            b.Text=states[key] and "ON" or "OFF"
            b.BackgroundColor3=states[key] and palettes.active or palettes.control
            b.TextColor3=states[key] and palettes.bg or palettes.txt
        end
    end
    local function numberRow(page,title,key,minValue,maxValue)
        local outer=rounded(create("Frame",{
            BackgroundColor3=palettes.panel,BorderSizePixel=0,
            Size=UDim2.new(1,-5,0,40),
        },page),7)
        create("TextLabel",{
            Text=title,TextColor3=palettes.txt,TextSize=12,
            Font=Enum.Font.Gotham,BackgroundTransparency=1,
            TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(1,-92,1,0),Position=UDim2.fromOffset(9,0),
        },outer)
        local input=rounded(create("TextBox",{
            Text=tostring(states[key]),ClearTextOnFocus=false,
            TextColor3=palettes.txt,TextSize=13,
            Font=Enum.Font.GothamBold,BackgroundColor3=palettes.control,
            Size=UDim2.fromOffset(72,28),Position=UDim2.new(1,-80,0,6),
        },outer),6)
        bind(input.FocusLost,function()
            local n=tonumber(input.Text)
            if n then states[key]=math.clamp(math.floor(n),minValue,maxValue) end
            input.Text=tostring(states[key])
        end)
    end
    local function action(page,title,fn)
        local btn=rounded(create("TextButton",{
            Text=title,TextSize=12,Font=Enum.Font.GothamSemibold,
            TextColor3=palettes.txt,BackgroundColor3=palettes.control,
            Size=UDim2.new(1,-5,0,37),
        },page),8)
        bind(btn.MouseButton1Click,function()
            local success,message=pcall(fn)
            if not success then status("Tombol "..title..": "..tostring(message)) end
        end)
        return btn
    end

    toggleRow(pages.Move,"fly","Mod Fly","Joystick + tombol arah pada HP")
    numberRow(pages.Move,"Fly speed","flySpeed",5,130)
    toggleRow(pages.Move,"noclip","No Clip","Collision karakter di sisi klien")
    toggleRow(pages.Move,"speed","Speed","Atur kecepatan berjalan")
    numberRow(pages.Move,"Walk speed","walkSpeed",8,100)
    toggleRow(pages.Move,"jump","High Jump","Mengubah kekuatan lompatan")
    numberRow(pages.Move,"Jump power","jumpPower",25,180)
    toggleRow(pages.Move,"infjump","Infinite Jump","Lompat lagi saat di udara")
    label(pages.Move,"Catatan: game 2D yang tidak memakai Humanoid/RootPart bisa membatasi Fly, Speed dan No Clip.",52)

    toggleRow(pages.Visual,"fullbright","Fullbright","Mencerahkan map (lokal)")
    toggleRow(pages.Visual,"esp","Player ESP","Highlight pemain yang ada di klien")
    label(pages.Visual,"Semua efek visual hanya terlihat di perangkatmu.",40)

    toggleRow(pages.Dev,"dev","Dev Mode","Statistik client dan inspector tile")
    local devInfo=label(pages.Dev,"Menunggu data karakter...",164,true)
    devInfo.TextColor3=palettes.txt
    local inspectLabel=label(pages.Dev,inspectMessage,105,true)
    inspectLabel.TextColor3=palettes.active
    local inspectionArmed=false
    action(pages.Dev,"INSPECT TILE / OBJEK",function()
        if not states.dev then toggle("dev",true) refreshAll() end
        inspectionArmed=true
        inspectMessage="Sentuh objek di luar panel untuk membaca detailnya."
        inspectLabel.Text=inspectMessage
    end)
    action(pages.Dev,"COPY DEBUG INFO",function()
        local info=devInfo.Text.."\n"..inspectLabel.Text.."\nStatus: "..lastError
        if type(setclipboard)=="function" then setclipboard(info)
        else status("Fungsi setclipboard tidak tersedia.") end
    end)
    local statusLabel=label(pages.Dev,"STATUS: "..lastError,65,true)
    action(pages.Dev,"RESET FITUR",function()
        for _,key in ipairs({"fly","noclip","speed","jump","infjump","fullbright","esp","dev"}) do
            toggle(key,false)
        end
        inspectionArmed=false
        refreshAll()
        status("Semua fitur direset.")
    end)

    flyPad=create("Frame",{
        Name="FlyControls",Visible=false,BackgroundTransparency=1,
        Position=UDim2.new(1,-185,1,-160),Size=UDim2.fromOffset(175,145),
    },gui)
    local function holdButton(text,x,y,key)
        local btn=rounded(create("TextButton",{
            Text=text,TextSize=16,Font=Enum.Font.GothamBold,
            TextColor3=palettes.txt,BackgroundColor3=palettes.panel,
            BackgroundTransparency=.07,BorderSizePixel=0,
            Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(53,42),
        },flyPad),10)
        bind(btn.InputBegan,function(input)
            if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
                hold[key]=true
            end
        end)
        bind(btn.InputEnded,function(input)
            if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
                hold[key]=false
            end
        end)
        bind(btn.MouseLeave,function() hold[key]=false end)
        return btn
    end
    holdButton("UP",60,0,"up")
    holdButton("<",3,48,"left")
    holdButton(">",117,48,"right")
    holdButton("DOWN",60,96,"down")

    local opened=true
    bind(bubble.MouseButton1Click,function()
        opened=not opened
        main.Visible=opened
    end)
    bind(minimize.MouseButton1Click,function()
        opened=false
        main.Visible=false
    end)
    -- Mobile title drag: link dragging to the specific pointer, not all touches.
    local dragInput, dragStart, initialPos
    bind(header.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
            dragInput=input
            dragStart=input.Position
            initialPos=main.Position
        end
    end)
    bind(UIS.InputChanged,function(input)
        if dragInput and dragStart and initialPos and
            (input==dragInput or (dragInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)) then
            local diff=input.Position-dragStart
            main.Position=UDim2.new(initialPos.X.Scale,initialPos.X.Offset+diff.X,
                initialPos.Y.Scale,initialPos.Y.Offset+diff.Y)
        end
    end)
    bind(UIS.InputEnded,function(input)
        if input==dragInput or (dragInput and dragInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1) then
            dragInput=nil
        end
    end)
    local function screenHit(pos,object)
        if not object or not object.Visible then return false end
        local a=object.AbsolutePosition
        local s=object.AbsoluteSize
        return pos.X>=a.X and pos.X<=a.X+s.X and pos.Y>=a.Y and pos.Y<=a.Y+s.Y
    end
    local function inspectAt(pos)
        local cam=Workspace.CurrentCamera
        if not cam then return "Camera belum tersedia." end
        local char=getCharacter()
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances=char and {char} or {}
        local ray=cam:ViewportPointToRay(pos.X,pos.Y)
        local hit=Workspace:Raycast(ray.Origin,ray.Direction*550,params)
        if not hit then return "Tidak ada 3D BasePart terdeteksi di titik itu. Tile mungkin berupa GUI 2D." end
        local obj=hit.Instance
        local p=hit.Position
        return string.format("PART: %s\nCLASS: %s\nPATH: %s\nXYZ: %.1f, %.1f, %.1f\nSIZE: %s",
            obj.Name,obj.ClassName,obj:GetFullName():sub(1,100),p.X,p.Y,p.Z,tostring(obj.Size))
    end
    bind(UIS.InputBegan,function(input,processed)
        if inspectionArmed and states.dev and not processed and
            (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1) then
            if not screenHit(input.Position,main) and not screenHit(input.Position,bubble) and not screenHit(input.Position,flyPad) then
                inspectionArmed=false
                local success,result=pcall(inspectAt,input.Position)
                inspectMessage=success and result or tostring(result)
                inspectLabel.Text=inspectMessage
            end
        end
        if processed then return end
        if input.KeyCode==Enum.KeyCode.F then toggle("fly",not states.fly) refreshAll() end
        if input.KeyCode==Enum.KeyCode.N then toggle("noclip",not states.noclip) refreshAll() end
        if input.KeyCode==Enum.KeyCode.Q then hold.up=true end
        if input.KeyCode==Enum.KeyCode.E then hold.down=true end
    end)
    bind(UIS.InputEnded,function(input)
        if input.KeyCode==Enum.KeyCode.Q then hold.up=false end
        if input.KeyCode==Enum.KeyCode.E then hold.down=false end
    end)
    bind(UIS.JumpRequest,function()
        if states.infjump then
            local _,hum=getCharacter()
            if hum and hum.Health>0 then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
        end
    end)

    local function updateDev()
        if not states.dev then
            devInfo.Text="Dev Mode OFF. Aktifkan untuk membaca game."
        else
            local char,hum,root=getCharacter()
            local coords=root and root.Position or Vector3.new(0,0,0)
            local ping="?"
            pcall(function() ping=tostring(math.floor(player:GetNetworkPing()*1000)).."ms" end)
            local controller = hum and "Humanoid" or (char and "Custom / tanpa Humanoid" or "Tidak ada Character")
            devInfo.Text=string.format("PLACE: %s\nUSER: %s\nPLAYERS: %d\nPING: %s\nCHARACTER: %s\nROOT: %s\nXYZ: %.1f / %.1f / %.1f\nFLY: %s | NOCLIP: %s",
                tostring(game.PlaceId),player.Name,#Players:GetPlayers(),ping,controller,
                root and root.Name or "NOT FOUND",coords.X,coords.Y,coords.Z,
                states.fly and "ON" or "OFF",states.noclip and "ON" or "OFF")
        end
        statusLabel.Text="STATUS: "..lastError:sub(1,180)
    end
    local function refreshESP()
        for _,other in ipairs(Players:GetPlayers()) do
            if other~=player then
                local char=other.Character
                if char then
                    if not visuals[other] or visuals[other].Parent~=char then
                        if visuals[other] then pcall(function() visuals[other]:Destroy() end) end
                        local highlight=Instance.new("Highlight")
                        highlight.Name="GrowbloxClientESP"
                        highlight.Adornee=char
                        highlight.FillColor=palettes.active
                        highlight.FillTransparency=.76
                        highlight.OutlineColor=Color3.new(1,1,1)
                        highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.Parent=char
                        visuals[other]=highlight
                    end
                elseif visuals[other] then
                    pcall(function() visuals[other]:Destroy() end)
                    visuals[other]=nil
                end
            end
        end
    end
    local function onStep(dt)
        if not alive then return end
        local char,hum,root=getCharacter()
        flyPad.Visible=states.fly
        if states.noclip and char then
            for _,part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if oldCollision[part]==nil then oldCollision[part]=part.CanCollide end
                    part.CanCollide=false
                end
            end
        end
        if states.fly and root then
            if flightForce and currentRoot~=root then stopFlight() states.fly=true end
            if not flightForce then
                flightForce=Instance.new("BodyVelocity")
                flightForce.Name="GrowbloxFlyClient"
                flightForce.MaxForce=Vector3.new(1e7,1e7,1e7)
                flightForce.P=10000
                flightForce.Velocity=Vector3.zero
                flightForce.Parent=root
                currentRoot=root
            end
            local camera=Workspace.CurrentCamera
            local right=camera and camera.CFrame.RightVector or Vector3.new(1,0,0)
            right=Vector3.new(right.X,0,right.Z)
            if right.Magnitude<.001 then right=Vector3.new(1,0,0) end
            local horizontal=(hold.right and 1 or 0)-(hold.left and 1 or 0)
            local vertical=(hold.up and 1 or 0)-(hold.down and 1 or 0)
            local m=hum and hum.MoveDirection or Vector3.zero
            local direction=m+right.Unit*horizontal+Vector3.new(0,vertical,0)
            if direction.Magnitude>1 then direction=direction.Unit end
            flightForce.Velocity=direction*states.flySpeed
            if hum then hum.PlatformStand=true end
        elseif flightForce then
            stopFlight()
        end
        elapsed=elapsed+dt
        espElapsed=espElapsed+dt
        if elapsed>=.35 then
            elapsed=0
            if hum then
                if states.speed then hum.WalkSpeed=states.walkSpeed end
                if states.jump then
                    hum.UseJumpPower=true
                    hum.JumpPower=states.jumpPower
                end
            end
            if states.fullbright then setLight(true) end
            updateDev()
        end
        if espElapsed>=1.5 then
            espElapsed=0
            if states.esp then pcall(refreshESP) end
        end
    end
    bind(RunService.Stepped,function(_,dt)
        local success,message=pcall(onStep,dt)
        if not success then
            if lastError~=tostring(message) then warnLog(message) end
            lastError=tostring(message)
        end
    end)
    bind(player.CharacterAdded,function()
        if flightForce then stopFlight() end
        restoreCollisions()
    end)

    local controller={}
    function controller.Destroy()
        if not alive then return end
        for _,key in ipairs({"fly","noclip","speed","jump","infjump","fullbright","esp","dev"}) do
            pcall(function() toggle(key,false) end)
        end
        alive=false
        stopFlight()
        restoreCollisions()
        clearESP()
        resetHumanoidProperties()
        for _,conn in ipairs(connections) do pcall(function() conn:Disconnect() end) end
        pcall(function() gui:Destroy() end)
        if env.GrowbloxLauncherV2==controller then env.GrowbloxLauncherV2=nil end
    end
    bind(close.MouseButton1Click,controller.Destroy)
    env.GrowbloxLauncherV2=controller
    refreshAll()
    status("GUI READY. Jika terlihat tombol GB, script berhasil dijalankan.")
    updateDev()
    log("Loaded. PlaceId="..tostring(game.PlaceId))
end, function(message)
    local plain = tostring(message)
    local traced = plain
    if type(debug)=="table" and type(debug.traceback)=="function" then
        local okTrace, result = pcall(debug.traceback,plain,2)
        if okTrace then traced=result end
    end
    return traced
end)
if not ok then
    warnLog(err)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",{
            Title="Growblox Launcher ERROR",Text=tostring(err):sub(1,160),Duration=15,
        })
    end)
end
