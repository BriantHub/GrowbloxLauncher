--[[
 Growblox Launcher V3 -- Diagnostic / compatible features
 PlaceId 112863874972771 | Delta / Roblox (client)
 This is a SELF-CONTAINED loader. Upload as loader.lua to GitHub.
 Observes public client-side instances. Does not send/spoof remote calls.
 Fly, Noclip, Speed and Jump only activate when a compatible, clearly
 identified character or controller exists. Never pretends they work.
]]
local TAG = "[GB V3] "
local function say(s) print(TAG .. tostring(s)) end
local okStart, startError = xpcall(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local Lighting = game:GetService("Lighting")
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local player = Players.LocalPlayer
    if not player then error("LocalPlayer nil. Jalankan setelah masuk world.") end
    local pg = player:WaitForChild("PlayerGui", 12)
    if not pg then error("PlayerGui nil") end

    local env = _G
    pcall(function() if type(getgenv) == "function" then env = getgenv() end end)
    for _,key in ipairs({"GrowbloxLauncherV2", "GrowbloxLauncherV3"}) do
        local previous = env[key]
        if type(previous) == "table" and type(previous.Destroy) == "function" then
            pcall(previous.Destroy)
        end
    end
    for _,name in ipairs({"GrowbloxLauncherV2", "GrowbloxLauncherV3"}) do
        local old = pg:FindFirstChild(name)
        if old then old:Destroy() end
    end

    local live = true
    local cons = {}
    local inboundCons = {}
    local inboundEvents = {}
    local eventsCount = 0
    local originalParts = {}
    local oldEffects = {}
    local originalHum = {}
    local originalJump = {}
    local originalController = {}
    local flyForce = nil
    local flyRoot = nil
    local recognizedRoot = nil
    local recognizedModel = nil
    local recognizedConfidence = ""
    local lastReport = "Tekan SCAN GAME untuk membaca struktur Growblox."
    local currentStatus = "V3 siap. Tidak ada packet yang dikirim."
    local scanBusy = false
    local states = {fly=false,noclip=false,speed=false,jump=false,bright=false,lowfx=false,grid=false,listen=false}
    local hold = {l=false,r=false,u=false,d=false}
    local palette = {
        base=Color3.fromRGB(13,19,30), panel=Color3.fromRGB(27,39,54),
        button=Color3.fromRGB(43,58,77), green=Color3.fromRGB(35,212,163),
        text=Color3.fromRGB(244,250,255), soft=Color3.fromRGB(180,199,210),
        bad=Color3.fromRGB(218,106,103)
    }
    local function on(signal,callback)
        local c = signal:Connect(callback)
        table.insert(cons,c)
        return c
    end
    local function new(class,properties,parent)
        local o = Instance.new(class)
        for k,v in pairs(properties or {}) do o[k] = v end
        o.Parent = parent
        return o
    end
    local function corner(part,r)
        new("UICorner",{CornerRadius=UDim.new(0,r or 9)},part)
        return part
    end
    local function briefPath(o)
        if not o then return "nil" end
        local success, path = pcall(function() return o:GetFullName() end)
        if success then return tostring(path):sub(1,180) end
        return tostring(o.Name)
    end
    local function lower(x) return string.lower(tostring(x or "")) end
    local function status(text)
        currentStatus = tostring(text)
        say(currentStatus)
    end
    local function getRootFromChar(char)
        if not char then return nil end
        return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
            or char:FindFirstChildWhichIsA("BasePart",true)
    end
    local function detectPlayerRoot()
        local character = player.Character
        if character and character.Parent then
            local root = getRootFromChar(character)
            if root then return character,root,"Player.Character (pasti)" end
        end
        -- Look ONLY for strong local-player identity matches, avoiding unrelated map parts.
        local userName, displayName = lower(player.Name), lower(player.DisplayName)
        local probable = {}
        local queue = {Workspace}
        local head = 1
        while head <= #queue and head <= 4500 do
            local obj=queue[head]
            head=head+1
            for _,child in ipairs(obj:GetChildren()) do
                if #queue < 4500 then queue[#queue+1]=child end
                if child:IsA("Model") or child:IsA("BasePart") then
                    local name = lower(child.Name)
                    local score=0
                    if name == userName or name == displayName then score=100 end
                    if name:find(userName,1,true) or name:find(displayName,1,true) then
                        score=math.max(score,70)
                    end
                    local a=nil
                    pcall(function() a=child:GetAttribute("UserId") end)
                    if a == player.UserId or tostring(a) == tostring(player.UserId) then score=120 end
                    if score >= 70 then
                        local model = child:IsA("Model") and child or child:FindFirstAncestorOfClass("Model")
                        local root = model and getRootFromChar(model) or (child:IsA("BasePart") and child or nil)
                        if root then
                            probable[#probable+1]={score=score,model=model,root=root}
                        end
                    end
                end
            end
            if head % 400 == 0 then task.wait() end
        end
        table.sort(probable,function(a,b) return a.score>b.score end)
        if probable[1] then
            local p=probable[1]
            return p.model,p.root,"Nama/UserId lokal (indikasi)"
        end
        return nil,nil,"Karakter khusus belum teridentifikasi"
    end

    local gui=new("ScreenGui",{
        Name="GrowbloxLauncherV3",ResetOnSpawn=false,DisplayOrder=30000,
        IgnoreGuiInset=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    },pg)
    local openButton=corner(new("TextButton",{
        Name="GBCircle",Text="GB3",Font=Enum.Font.GothamBold,TextSize=14,
        BackgroundColor3=palette.green,TextColor3=palette.base,BorderSizePixel=0,
        Position=UDim2.new(0,12,.26,0),Size=UDim2.fromOffset(54,54),ZIndex=30
    },gui),27)
    local main=corner(new("Frame",{
        Name="Panel",Position=UDim2.new(0,70,.10,0),Size=UDim2.fromOffset(340,395),
        BackgroundColor3=palette.base,BorderSizePixel=0,Active=true
    },gui),12)
    new("UIStroke",{Color=palette.green,Thickness=1,Transparency=.3},main)
    local scale = new("UIScale",{Scale=1},main)
    local function resize()
        local cam=Workspace.CurrentCamera
        if cam then scale.Scale=math.clamp(cam.ViewportSize.X/465,.64,1) end
    end
    resize()
    local header=new("Frame",{Name="DragTitle",Size=UDim2.new(1,0,0,42),
        BackgroundColor3=palette.panel,BorderSizePixel=0,Active=true},main)
    corner(header,12)
    new("TextLabel",{Text="GROWBLOX V3 | ENGINE SCAN",BackgroundTransparency=1,
        TextColor3=palette.text,TextSize=13,Font=Enum.Font.GothamBold,
        Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-105,1,0),
        TextXAlignment=Enum.TextXAlignment.Left},header)
    local minimize=corner(new("TextButton",{Text="—",BackgroundColor3=palette.button,
        TextColor3=palette.text,TextSize=19,Position=UDim2.new(1,-80,0,7),
        Size=UDim2.fromOffset(32,28)},header),6)
    local close=corner(new("TextButton",{Text="X",BackgroundColor3=palette.bad,
        TextColor3=palette.text,TextSize=14,Position=UDim2.new(1,-42,0,7),
        Size=UDim2.fromOffset(32,28)},header),6)
    local statusLabel=new("TextLabel",{BackgroundTransparency=1,Text="",TextWrapped=true,
        TextYAlignment=Enum.TextYAlignment.Center,TextXAlignment=Enum.TextXAlignment.Left,
        Font=Enum.Font.Code,TextSize=10,TextColor3=palette.soft,
        Position=UDim2.fromOffset(10,44),Size=UDim2.new(1,-20,0,34)},main)
    local bar=new("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(8,80),
        Size=UDim2.new(1,-16,0,34)},main)
    new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
        SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5)},bar)
    local pages,tabs={},{}
    for i,name in ipairs({"SCAN","MOVE","VISUAL"}) do
        local b=corner(new("TextButton",{Text=name,BackgroundColor3=palette.button,
            TextColor3=palette.text,Font=Enum.Font.GothamSemibold,TextSize=12,
            LayoutOrder=i,Size=UDim2.new(1/3,-4,1,0)},bar),7)
        local page=new("Frame",{Name=name,Position=UDim2.fromOffset(9,121),
            Size=UDim2.new(1,-18,1,-128),BackgroundTransparency=1,Visible=false},main)
        pages[name]=page
        tabs[name]=b
    end
    local function showTab(name)
        for k,p in pairs(pages) do
            p.Visible=(k==name)
            tabs[k].BackgroundColor3=(k==name) and palette.green or palette.button
            tabs[k].TextColor3=(k==name) and palette.base or palette.text
        end
    end
    for name,b in pairs(tabs) do on(b.MouseButton1Click,function() showTab(name) end) end
    showTab("SCAN")
    local function btn(parent,text,x,y,w,h,action)
        local b=corner(new("TextButton",{Text=text,Font=Enum.Font.GothamMedium,TextSize=11,
            TextColor3=palette.text,BackgroundColor3=palette.button,
            Position=UDim2.new(x,0,0,y),Size=UDim2.new(w,-5,0,h),
            BorderSizePixel=0,TextWrapped=true},parent),8)
        if action then on(b.MouseButton1Click,action) end
        return b
    end
    local scanPage=pages.SCAN
    local reportBox=new("ScrollingFrame",{Name="Report",BackgroundColor3=palette.panel,
        BorderSizePixel=0,ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,
        CanvasSize=UDim2.fromOffset(0,0),Position=UDim2.new(0,0,0,91),
        Size=UDim2.new(1,0,1,-94)},scanPage)
    corner(reportBox,8)
    local reportLabel=new("TextLabel",{Text=lastReport,Font=Enum.Font.Code,
        TextSize=11,TextColor3=palette.text,BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
        TextWrapped=true,AutomaticSize=Enum.AutomaticSize.Y,
        Position=UDim2.fromOffset(8,7),Size=UDim2.new(1,-18,0,0)},reportBox)
    local function paintReport(s)
        lastReport=tostring(s)
        reportLabel.Text=lastReport:sub(1,18000)
    end

    local scanButton,copyButton,inspectButton,listenButton
    local inspectArmed=false
    local listenRemoteLimit=35
    local function setupListener(events)
        for _,c in ipairs(inboundCons) do pcall(function() c:Disconnect() end) end
        table.clear(inboundCons)
        table.clear(inboundEvents)
        eventsCount=0
        if not states.listen then return end
        local n=0
        for _,obj in ipairs(events) do
            if n>=listenRemoteLimit then break end
            if obj:IsA("RemoteEvent") then
                local ok,c=pcall(function()
                    return obj.OnClientEvent:Connect(function(...)
                        if not states.listen or not live then return end
                        eventsCount=eventsCount+1
                        inboundEvents[briefPath(obj)]=(inboundEvents[briefPath(obj)] or 0)+1
                    end)
                end)
                if ok and c then
                    inboundCons[#inboundCons+1]=c
                    n=n+1
                end
            end
        end
        status("Monitor IN aktif ("..n.." event); hanya nama dan jumlah, bukan isi packet.")
    end
    local function safeChildrenTree(root,limit,onObject)
        local q={root}
        local head=1
        while head<=#q and head<=limit do
            local o=q[head]
            head=head+1
            if o~=root then onObject(o) end
            local children=o:GetChildren()
            for _,v in ipairs(children) do
                if #q<limit then q[#q+1]=v end
            end
            if head % 450==0 then task.wait() end
        end
        return math.min(head-1,limit)
    end
    local function runScan()
        if scanBusy then return end
        scanBusy=true
        scanButton.Text="SCANNING..."
        local success,errorMessage=pcall(function()
            local lines={}
            local function add(s) lines[#lines+1]=s end
            add("=== GROWBLOX V3 - GAME SCAN ===")
            add("PLACE: "..tostring(game.PlaceId))
            add("WORLD: "..tostring(game.Name))
            add("PLAYER: "..tostring(player.Name).." / DISPLAY: "..tostring(player.DisplayName))
            local cam=Workspace.CurrentCamera
            add("CAMERA: "..(cam and tostring(cam.CameraType) or "nil"))
            add("CAMERA SUBJECT: "..(cam and briefPath(cam.CameraSubject) or "nil"))
            add("PLAYER.CHARACTER: "..briefPath(player.Character))
            local c,root,conf=detectPlayerRoot()
            recognizedRoot,recognizedModel,recognizedConfidence = root,c,conf
            add("ROOT FOUND: "..briefPath(root))
            add("MODEL: "..briefPath(c))
            add("IDENTITY: "..conf)
            if root then
                add("ROOT ANCHORED: "..tostring(root.Anchored).." | COLLIDE: "..tostring(root.CanCollide))
                add("ROOT XYZ: "..tostring(root.Position))
            end
            add("\n[PLAYER ATTRIBUTES] (names only)")
            local attr=player:GetAttributes()
            local ak={}
            for k in pairs(attr) do ak[#ak+1]=tostring(k) end
            table.sort(ak)
            add(#ak>0 and table.concat(ak,", ") or "(none)")
            add("\n[WORKSPACE ROOT CHILDREN]")
            local wc=Workspace:GetChildren()
            for i=1,math.min(30,#wc) do
                add(wc[i].Name.." : "..wc[i].ClassName)
            end
            add("\n[PLAYERGUI ROOT CHILDREN]")
            local gs=pg:GetChildren()
            for i=1,math.min(30,#gs) do
                if gs[i]~=gui then add(gs[i].Name.." : "..gs[i].ClassName) end
            end
            local matches={}
            local candidateWords={"player","char","avatar","sprite","world","tile","move","control","position","camera","physic","render"}
            local uName, dName=lower(player.Name),lower(player.DisplayName)
            local guiCount=safeChildrenTree(pg,3200,function(o)
                if o:IsDescendantOf(gui) then return end
                local n=lower(o.Name)
                local matching=false
                for _,kw in ipairs(candidateWords) do
                    if n:find(kw,1,true) then matching=true;break end
                end
                if o:IsA("TextLabel") or o:IsA("TextButton") then
                    local t=lower(o.Text)
                    if #t<70 and ((#uName>0 and t:find(uName,1,true)) or (#dName>0 and t:find(dName,1,true))) then
                        matching=true
                    end
                end
                if matching and #matches<40 then
                    local extra=""
                    if o:IsA("GuiObject") then
                        extra=" [xy="..tostring(o.AbsolutePosition)..", size="..tostring(o.AbsoluteSize).."]"
                    end
                    matches[#matches+1]=o.ClassName.." | "..briefPath(o)..extra
                end
            end)
            add("\n[2D GUI MATCHES] scanned="..guiCount)
            for i=1,#matches do add(matches[i]) end
            if #matches==0 then add("No likely named GUI found") end
            local values={}
            local gameObjects=safeChildrenTree(Workspace,4800,function(o)
                if #values>=35 then return end
                if o:IsA("Model") or o:IsA("BillboardGui") or o:IsA("SurfaceGui")
                    or o:IsA("Vector2Value") or o:IsA("Vector3Value") then
                    local n=lower(o.Name)
                    local useful=n:find("player",1,true) or n:find("avatar",1,true)
                        or n:find("sprite",1,true) or n:find("character",1,true)
                        or n:find("pos",1,true) or n:find("tile",1,true)
                        or n:find(uName,1,true) or n:find(dName,1,true)
                    if useful then values[#values+1]=o.ClassName.." | "..briefPath(o) end
                end
            end)
            add("\n[WORKSPACE CANDIDATES] scanned="..gameObjects)
            for _,v in ipairs(values) do add(v) end
            if #values==0 then add("No named world candidate found") end
            add("\n[REPLICATED REMOTES] (names only)")
            local remotes={}
            safeChildrenTree(ReplicatedStorage,3000,function(o)
                if o:IsA("RemoteEvent") or o:IsA("RemoteFunction") or o:IsA("UnreliableRemoteEvent") then
                    remotes[#remotes+1]=o
                end
            end)
            add("COUNT: "..#remotes)
            for i=1,math.min(50,#remotes) do
                add(remotes[i].ClassName.." | "..briefPath(remotes[i]))
            end
            if #remotes>50 then add("(truncated)") end
            if states.listen then setupListener(remotes) end
            add("\n[FEATURE SUPPORT]")
            if root and root:IsA("BasePart") then
                add("FLY/NOCLIP: experimental, local-only, server may reset")
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                local cm = c and c:FindFirstChildOfClass("ControllerManager")
                add("HUMANOID: "..tostring(hum~=nil).." | CONTROLLER: "..tostring(cm~=nil))
            else
                add("FLY/NOCLIP/SPEED/JUMP: unsupported until real avatar is identified")
            end
            add("FULLBRIGHT / LOW FX / SCREEN GRID: visual client-side")
            add("\nUse INSPECT TAP then tap your own sprite and a tile.")
            add("IN monitor shows inbound RemoteEvents only; no server payload or outgoing packet interception.")
            local report=table.concat(lines,"\n")
            paintReport(report)
            env.GrowbloxV3Report=report
            status("Scan selesai. Root: "..(root and root.Name or "NOT FOUND").." | Remotes: "..#remotes)
        end)
        if not success then
            status("Scan ERROR: "..tostring(errorMessage))
            paintReport(lastReport.."\nSCAN ERROR: "..tostring(errorMessage))
        end
        scanButton.Text="SCAN GAME"
        scanBusy=false
    end
    scanButton=btn(scanPage,"SCAN GAME",0,0,.50,33,function() task.spawn(runScan) end)
    copyButton=btn(scanPage,"COPY REPORT",.50,0,.50,33,function()
        local copied=false
        local export=lastReport
        if eventsCount>0 and env.GrowbloxV3InboundReport then
            export=export.."\n\n"..tostring(env.GrowbloxV3InboundReport)
        end
        if type(setclipboard)=="function" then
            copied=pcall(setclipboard,export)
        end
        if copied then
            status("Report disalin ke clipboard HP. Paste di ChatGPT.")
        elseif type(writefile)=="function" then
            local wrote=pcall(writefile,"Growblox_V3_Report.txt",export)
            status(wrote and "Report disimpan: Growblox_V3_Report.txt (folder Delta)." or "Clipboard/file unavailable; lihat report di panel.")
        else
            status("Clipboard tidak didukung; screenshot halaman SCAN dan kirim.")
            say(lastReport)
        end
    end)
    inspectButton=btn(scanPage,"INSPECT TAP",0,42,.50,33,function()
        inspectArmed=true
        status("Sekarang sentuh karakter / tile di luar panel. Akan melihat GUI + 3D hit.")
    end)
    listenButton=btn(scanPage,"IN MONITOR OFF",.50,42,.50,33,function()
        states.listen=not states.listen
        listenButton.Text=states.listen and "IN MONITOR ON" or "IN MONITOR OFF"
        if states.listen then
            task.spawn(runScan)
        else
            setupListener({})
            status("Monitor IN dimatikan.")
        end
    end)

    local move=pages.MOVE
    local moveInfo=new("TextLabel",{BackgroundColor3=palette.panel,Text="Scan untuk mendeteksi controller.",
        Font=Enum.Font.Code,TextSize=10,TextColor3=palette.text,TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
        Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,0,0,64)},move)
    corner(moveInfo,6)
    local function restoreNoclip()
        for part,was in pairs(originalParts) do
            if part and part.Parent then pcall(function() part.CanCollide=was end) end
            originalParts[part]=nil
        end
    end
    local function stopFly()
        if flyForce then pcall(function() flyForce:Destroy() end) end
        flyForce=nil
        flyRoot=nil
        for k in pairs(hold) do hold[k]=false end
    end
    local flightPad=new("Frame",{BackgroundColor3=palette.panel,BackgroundTransparency=.09,
        Position=UDim2.new(0,0,1,-63),Size=UDim2.new(1,0,0,61),Visible=false},move)
    corner(flightPad,8)
    local function touchDir(key,txt,x)
        local b=corner(new("TextButton",{Text=txt,Font=Enum.Font.GothamBold,
            TextSize=18,TextColor3=palette.text,BackgroundColor3=palette.button,
            Position=UDim2.new(x,0,0,6),Size=UDim2.new(.25,-5,0,48)},flightPad),7)
        on(b.InputBegan,function(input)
            if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
                hold[key]=true
            end
        end)
        on(b.InputEnded,function(input)
            if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
                hold[key]=false
            end
        end)
    end
    touchDir("l","<",0)
    touchDir("r",">",.25)
    touchDir("u","UP",.50)
    touchDir("d","DOWN",.75)
    local function getSupportedRoot()
        if recognizedRoot and recognizedRoot.Parent then return recognizedModel,recognizedRoot end
        local model,root,conf=detectPlayerRoot()
        recognizedModel,recognizedRoot,recognizedConfidence=model,root,conf
        return model,root
    end
    local function humanOrController(model)
        if not model then return nil,nil end
        return model:FindFirstChildOfClass("Humanoid"),model:FindFirstChildOfClass("ControllerManager")
    end
    local actions={}
    local function toggleMotion(key)
        if states[key] then
            states[key]=false
            if key=="fly" then stopFly();flightPad.Visible=false end
            if key=="noclip" then restoreNoclip() end
            if key=="speed" then
                for hum,old in pairs(originalHum) do
                    if hum.Parent then pcall(function() hum.WalkSpeed=old end) end
                end
                for cm,old in pairs(originalController) do
                    if cm.Parent then pcall(function() cm.BaseMoveSpeed=old end) end
                end
            end
            if key=="jump" then
                for hum,old in pairs(originalJump) do
                    if hum.Parent then
                        pcall(function() hum.UseJumpPower=old.use;hum.JumpPower=old.power end)
                    end
                end
            end
            status(string.upper(key).." OFF")
            return
        end
        local model,root=getSupportedRoot()
        if not root then
            status(string.upper(key).." TIDAK DIDUKUNG: karakter Growblox tidak ditemukan. SCAN dahulu.")
            return
        end
        local hum,cm=humanOrController(model)
        if key=="noclip" and not model then
            status("NOCLIP belum kompatibel: model karakter belum ditemukan.")
            return
        end
        if key=="speed" and not hum and not cm then
            status("SPEED tidak tersedia: Humanoid/ControllerManager tidak ada.")
            return
        end
        if key=="jump" and not hum then
            status("JUMP tidak tersedia: Humanoid tidak ada.")
            return
        end
        if key=="fly" and root.Anchored then
            status("FLY belum kompatibel: root Anchored=true; controller game mengendalikan posisi.")
            return
        end
        states[key]=true
        if key=="fly" then flightPad.Visible=true end
        status(string.upper(key).." ON (eksperimen lokal, bisa dibatalkan server).")
    end
    actions.fly=btn(move,"FLY OFF",0,74,.5,35,function() toggleMotion("fly") end)
    actions.noclip=btn(move,"NOCLIP OFF",.50,74,.5,35,function() toggleMotion("noclip") end)
    actions.speed=btn(move,"SPEED OFF",0,118,.5,35,function() toggleMotion("speed") end)
    actions.jump=btn(move,"HIGH JUMP OFF",.5,118,.5,35,function() toggleMotion("jump") end)
    local help=new("TextLabel",{BackgroundTransparency=1,Font=Enum.Font.Code,
        TextSize=10,TextWrapped=true,TextColor3=palette.soft,
        Text="Gerak memerlukan objek dunia milik karakter. Jika tidak ditemukan, fitur tidak akan ON palsu. Deteksi bukan bypass server.",
        Position=UDim2.fromOffset(0,168),Size=UDim2.new(1,0,0,72)},move)
    local visual=pages.VISUAL
    local baselineLight={Brightness=Lighting.Brightness,ClockTime=Lighting.ClockTime,
        GlobalShadows=Lighting.GlobalShadows,Ambient=Lighting.Ambient,
        OutdoorAmbient=Lighting.OutdoorAmbient}
    local function fullbright(onValue)
        if onValue then
            pcall(function()
                Lighting.Brightness=4
                Lighting.ClockTime=12
                Lighting.GlobalShadows=false
                Lighting.Ambient=Color3.new(1,1,1)
                Lighting.OutdoorAmbient=Color3.new(1,1,1)
            end)
        else
            for k,v in pairs(baselineLight) do pcall(function() Lighting[k]=v end) end
        end
    end
    local function lowEffects(onValue)
        if onValue then
            safeChildrenTree(Workspace,3500,function(o)
                if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Beam") then
                    if oldEffects[o]==nil then oldEffects[o]=o.Enabled end
                    o.Enabled=false
                end
            end)
            for _,o in ipairs(Lighting:GetChildren()) do
                if o:IsA("BloomEffect") or o:IsA("DepthOfFieldEffect") or o:IsA("SunRaysEffect") then
                    if oldEffects[o]==nil then oldEffects[o]=o.Enabled end
                    o.Enabled=false
                end
            end
        else
            for obj,value in pairs(oldEffects) do
                if obj.Parent then pcall(function() obj.Enabled=value end) end
                oldEffects[obj]=nil
            end
        end
    end
    local gridLayer=new("Frame",{Name="ScreenGrid",BackgroundTransparency=1,
        Size=UDim2.fromScale(1,1),Visible=false,ZIndex=0},gui)
    -- Only a screen-coordinate grid. Not a world tile grid!
    for i=1,20 do
        local ln=new("Frame",{BackgroundColor3=palette.green,BackgroundTransparency=.76,
            BorderSizePixel=0,Position=UDim2.new(i/20,0,0,0),
            Size=UDim2.new(0,1,1,0)},gridLayer)
    end
    for i=1,12 do
        new("Frame",{BackgroundColor3=palette.green,BackgroundTransparency=.76,
            BorderSizePixel=0,Position=UDim2.new(0,0,i/12,0),
            Size=UDim2.new(1,0,0,1)},gridLayer)
    end
    local bBright,bLowFx,bGrid
    bBright=btn(visual,"FULLBRIGHT OFF",0,0,1,38,function()
        states.bright=not states.bright
        fullbright(states.bright)
        bBright.Text=states.bright and "FULLBRIGHT ON" or "FULLBRIGHT OFF"
        status("Fullbright "..(states.bright and "ON" or "OFF")..". Hanya berpengaruh pada lighting 3D.")
    end)
    bLowFx=btn(visual,"LOW FX OFF",0,46,1,38,function()
        states.lowfx=not states.lowfx
        task.spawn(function()
            lowEffects(states.lowfx)
            status("Low FX "..(states.lowfx and "ON" or "OFF")..". Particle/Trail yang terlihat di client.")
        end)
        bLowFx.Text=states.lowfx and "LOW FX ON" or "LOW FX OFF"
    end)
    bGrid=btn(visual,"SCREEN GRID OFF",0,92,1,38,function()
        states.grid=not states.grid
        gridLayer.Visible=states.grid
        bGrid.Text=states.grid and "SCREEN GRID ON" or "SCREEN GRID OFF"
        status("Screen grid adalah garis layar, bukan koordinat tile world.")
    end)
    new("TextLabel",{BackgroundTransparency=1,Font=Enum.Font.Code,TextWrapped=true,
        TextColor3=palette.soft,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Top,
        Text="Fitur Visual bekerja di sisi client. Map Growblox bisa memakai GUI/texture sehingga Fullbright tidak mengubah warnanya.\n\nV3 tidak mengklaim bisa memodifikasi data server.",
        Position=UDim2.fromOffset(0,155),Size=UDim2.new(1,0,0,105)},visual)

    local drag,dragStart,panelStart
    on(header.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=input;dragStart=input.Position;panelStart=main.Position
        end
    end)
    on(UIS.InputChanged,function(input)
        if drag and dragStart and panelStart and
           (input==drag or (drag.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)) then
            local d=input.Position-dragStart
            main.Position=UDim2.new(panelStart.X.Scale,panelStart.X.Offset+d.X,
                panelStart.Y.Scale,panelStart.Y.Offset+d.Y)
        end
    end)
    on(UIS.InputEnded,function(input)
        if drag==input then drag=nil end
    end)
    on(openButton.MouseButton1Click,function() main.Visible=not main.Visible end)
    on(minimize.MouseButton1Click,function() main.Visible=false end)

    local function containsScreen(o,x,y)
        if not o or not o.Visible then return false end
        local p,s=o.AbsolutePosition,o.AbsoluteSize
        return x>=p.X and y>=p.Y and x<=p.X+s.X and y<=p.Y+s.Y
    end
    on(UIS.InputBegan,function(input)
        if inspectArmed and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then
            local p=input.Position
            if not containsScreen(main,p.X,p.Y) and not containsScreen(openButton,p.X,p.Y) then
                inspectArmed=false
                task.spawn(function()
                    local lines={"=== TOUCH INSPECT ===","XY: "..tostring(p),"[GUI LAYERS]"}
                    local ok,objs=pcall(function() return pg:GetGuiObjectsAtPosition(p.X,p.Y) end)
                    if ok and type(objs)=="table" then
                        local count=0
                        for _,obj in ipairs(objs) do
                            if obj~=gridLayer and not obj:IsDescendantOf(gui) then
                                lines[#lines+1]=obj.ClassName.." "..briefPath(obj)
                                count=count+1
                                if count>=16 then break end
                            end
                        end
                        if count==0 then lines[#lines+1]="No underlying ScreenGui object." end
                    else
                        lines[#lines+1]="GUI query unsupported: "..tostring(objs)
                    end
                    local camera=Workspace.CurrentCamera
                    if camera then
                        local ray=camera:ViewportPointToRay(p.X,p.Y)
                        local success,hit=pcall(function() return Workspace:Raycast(ray.Origin,ray.Direction*600) end)
                        lines[#lines+1]="[3D RAYCAST]"
                        if success and hit then
                            lines[#lines+1]=hit.Instance.ClassName.." "..briefPath(hit.Instance)
                            lines[#lines+1]="POSITION: "..tostring(hit.Position)
                        else lines[#lines+1]="No BasePart hit / GUI-rendered world" end
                    end
                    lines[#lines+1]="\nTap your own sprite, then one ground tile; copy both results if needed."
                    local res=table.concat(lines,"\n")
                    paintReport(res)
                    env.GrowbloxV3Report=res
                    showTab("SCAN")
                    status("Inspect selesai. COPY REPORT atau screenshot.")
                end)
            end
        end
    end)
    local timer=0
    on(RunService.Heartbeat,function(dt)
        if not live then return end
        timer=timer+dt
        if states.noclip and recognizedModel then
            if recognizedModel.Parent then
                for _,part in ipairs(recognizedModel:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if originalParts[part]==nil then originalParts[part]=part.CanCollide end
                        part.CanCollide=false
                    end
                end
            else states.noclip=false;restoreNoclip() end
        end
        if states.fly and recognizedRoot and recognizedRoot.Parent then
            if recognizedRoot.Anchored then
                states.fly=false;stopFly();flightPad.Visible=false
                status("Fly berhenti: karakter anchored oleh controller game.")
            else
                if flyRoot~=recognizedRoot then
                    stopFly()
                    flyRoot=recognizedRoot
                    flyForce=Instance.new("BodyVelocity")
                    flyForce.Name="GrowbloxV3FlyClient"
                    flyForce.MaxForce=Vector3.new(1e6,1e6,1e6)
                    flyForce.P=9000
                    flyForce.Parent=recognizedRoot
                end
                local horizontal=(hold.r and 1 or 0)-(hold.l and 1 or 0)
                local vertical=(hold.u and 1 or 0)-(hold.d and 1 or 0)
                local direction=Vector3.new(horizontal,vertical,0)
                if direction.Magnitude>1 then direction=direction.Unit end
                flyForce.Velocity=direction*28
            end
        end
        if states.speed and recognizedModel then
            local hum,cm=humanOrController(recognizedModel)
            if hum then
                if originalHum[hum]==nil then originalHum[hum]=hum.WalkSpeed end
                hum.WalkSpeed=30
            elseif cm then
                if originalController[cm]==nil then originalController[cm]=cm.BaseMoveSpeed end
                cm.BaseMoveSpeed=30
            end
        end
        if states.jump and recognizedModel then
            local hum=recognizedModel:FindFirstChildOfClass("Humanoid")
            if hum then
                if originalJump[hum]==nil then
                    originalJump[hum]={use=hum.UseJumpPower,power=hum.JumpPower}
                end
                hum.UseJumpPower=true
                hum.JumpPower=85
            end
        end
        if timer>0.5 then
            timer=0
            statusLabel.Text=currentStatus:sub(1,143)..(states.listen and (" | IN:"..eventsCount) or "")
            if pages.MOVE.Visible then
                local root=recognizedRoot
                moveInfo.Text="ROOT: "..(root and briefPath(root) or "NOT FOUND")..
                    "\nDETECT: "..recognizedConfidence..
                    "\nXYZ: "..(root and tostring(root.Position) or "unknown")
            end
            for _,key in ipairs({"fly","noclip","speed","jump"}) do
                local b=actions[key]
                if b then
                    local name=key=="jump" and "HIGH JUMP" or string.upper(key)
                    b.Text=name..(states[key] and " ON" or " OFF")
                    b.BackgroundColor3=states[key] and palette.green or palette.button
                    b.TextColor3=states[key] and palette.base or palette.text
                end
            end
            if states.listen and eventsCount>0 then
                local s={}
                for path,count in pairs(inboundEvents) do s[#s+1]={name=path,count=count} end
                table.sort(s,function(a,b) return a.count>b.count end)
                local summary={"INCOMING REMOTE EVENTS: "..eventsCount}
                for i=1,math.min(#s,15) do
                    summary[#summary+1]=tostring(s[i].count).."x "..s[i].name
                end
                -- Keep the scan report intact; expose counters via a separate global.
                env.GrowbloxV3InboundReport=table.concat(summary,"\n")
            end
        end
    end)
    on(Workspace:GetPropertyChangedSignal("CurrentCamera"),resize)
    local controller={}
    function controller.Destroy()
        if not live then return end
        live=false
        states.listen=false
        setupListener({})
        stopFly()
        restoreNoclip()
        fullbright(false)
        lowEffects(false)
        for hum,old in pairs(originalHum) do
            if hum and hum.Parent then pcall(function() hum.WalkSpeed=old end) end
        end
        for hum,old in pairs(originalJump) do
            if hum and hum.Parent then
                pcall(function() hum.UseJumpPower=old.use;hum.JumpPower=old.power end)
            end
        end
        for cm,old in pairs(originalController) do
            if cm and cm.Parent then pcall(function() cm.BaseMoveSpeed=old end) end
        end
        for _,c in ipairs(cons) do pcall(function() c:Disconnect() end) end
        gui:Destroy()
        if env.GrowbloxLauncherV3==controller then env.GrowbloxLauncherV3=nil end
    end
    on(close.MouseButton1Click,controller.Destroy)
    env.GrowbloxLauncherV3=controller
    statusLabel.Text=currentStatus
    say("Loaded GrowbloxV3 | "..game.PlaceId)
    task.defer(runScan)
end,function(e)
    if debug and type(debug.traceback)=="function" then
        return debug.traceback(tostring(e),2)
    end
    return tostring(e)
end)
if not okStart then
    warn(TAG..tostring(startError))
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{
        Title="GB V3 ERROR",Text=tostring(startError):sub(1,200),Duration=12
    }) end)
end
