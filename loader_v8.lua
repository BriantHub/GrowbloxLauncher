--[[
GrowBlox V8 | Controller Inspector (Delta Android)
PlaceId: 112863874972771
Read-only diagnostic: lists exports of ALREADY LOADED client modules and
movement-related local ValueBase/attributes. NO FireServer, InvokeServer,
remote replays, hooks, getgc scans, or server changes.
]]

local function main()
    local Players = game:GetService('Players')
    local RS = game:GetService('ReplicatedStorage')
    local UIS = game:GetService('UserInputService')
    local WS = game:GetService('Workspace')
    local lp = Players.LocalPlayer
    assert(lp, 'LocalPlayer unavailable')
    local pg = lp:WaitForChild('PlayerGui', 15)
    assert(pg, 'PlayerGui unavailable')

    local env = _G
    pcall(function()
        if type(getgenv) == 'function' then env = getgenv() end
    end)
    if type(env.GrowBloxV8) == 'table' and type(env.GrowBloxV8.Close) == 'function' then
        pcall(env.GrowBloxV8.Close)
    end
    local old = pg:FindFirstChild('GBV8_Inspector')
    if old then old:Destroy() end

    local alive = true
    local connections = {}
    local report = 'GROWBLOX V8: Tekan SCAN EXPORTS, kemudian SCAN STATE.'
    local function conn(signal, fn)
        local c = signal:Connect(fn)
        connections[#connections+1] = c
        return c
    end
    local function mk(cls, props, par)
        local ins = Instance.new(cls)
        for k,v in pairs(props) do ins[k] = v end
        ins.Parent = par
        return ins
    end
    local function corner(ins, radius)
        mk('UICorner', {CornerRadius=UDim.new(0,radius or 8)}, ins)
        return ins
    end
    local bg = Color3.fromRGB(17,22,34)
    local panelColor = Color3.fromRGB(30,41,56)
    local accent = Color3.fromRGB(58,211,173)
    local white = Color3.fromRGB(230,242,247)
    local gui = mk('ScreenGui', {
        Name='GBV8_Inspector', DisplayOrder=31000,
        ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    }, pg)
    local ball = corner(mk('TextButton', {
        Text='GB8', Font=Enum.Font.GothamBold, TextSize=14,
        BackgroundColor3=accent, TextColor3=bg, BorderSizePixel=0,
        Size=UDim2.fromOffset(50,50), Position=UDim2.new(0,9,.30,0)
    }, gui), 25)
    local root = corner(mk('Frame', {
        Name='Window', BackgroundColor3=bg, BorderSizePixel=0, Active=true,
        Position=UDim2.new(0,68,.075,0), Size=UDim2.fromOffset(400,400)
    }, gui), 10)
    mk('UIStroke',{Color=accent,Thickness=1,Transparency=.2},root)
    local scale = mk('UIScale',{Scale=1},root)
    local function adapt()
        local cam = WS.CurrentCamera
        if cam then
            local viewport=cam.ViewportSize
            scale.Scale = math.clamp(math.min((viewport.X-78)/400,(viewport.Y-55)/400),.52,1)
        end
    end
    adapt()
    conn(WS:GetPropertyChangedSignal('CurrentCamera'), adapt)
    local head = corner(mk('Frame', {
        BackgroundColor3=panelColor, BorderSizePixel=0, Active=true,
        Size=UDim2.new(1,0,0,44)
    },root),10)
    mk('TextLabel', {
        Text='GROWBLOX V8  |  CONTROLLER INSPECTOR',Font=Enum.Font.GothamBold,
        TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,
        BackgroundTransparency=1,TextColor3=white,
        Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-95,1,0)
    },head)
    local close = corner(mk('TextButton', {
        Text='X',Font=Enum.Font.GothamBold,TextSize=14,
        TextColor3=white,BackgroundColor3=Color3.fromRGB(177,64,78),
        BorderSizePixel=0,Position=UDim2.new(1,-38,0,8),Size=UDim2.fromOffset(30,28)
    },head),6)
    local mini = corner(mk('TextButton', {
        Text='–',Font=Enum.Font.GothamBold,TextSize=14,
        TextColor3=white,BackgroundColor3=panelColor,
        BorderSizePixel=0,Position=UDim2.new(1,-75,0,8),Size=UDim2.fromOffset(30,28)
    },head),6)
    local statusText = mk('TextLabel', {
        Text='READ ONLY. Tidak mengirim packet.',Font=Enum.Font.Code,TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,
        TextColor3=accent,BackgroundTransparency=1,
        Position=UDim2.fromOffset(9,47),Size=UDim2.new(1,-18,0,31)
    },root)
    local view = corner(mk('ScrollingFrame', {
        BackgroundColor3=panelColor,BorderSizePixel=0,
        Position=UDim2.fromOffset(8,133),Size=UDim2.new(1,-16,1,-141),
        CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollBarThickness=4
    },root),7)
    local textLabel = mk('TextLabel', {
        Text=report,BackgroundTransparency=1,
        TextColor3=white,Font=Enum.Font.Code,TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
        TextWrapped=true,Position=UDim2.fromOffset(8,8),
        Size=UDim2.new(1,-16,0,0),AutomaticSize=Enum.AutomaticSize.Y
    },view)
    local function status(s)
        if alive then statusText.Text=tostring(s) end
    end
    local function show(str)
        report=tostring(str)
        env.GrowBloxV8Report=report
        if alive then
            textLabel.Text=report:sub(1,30000)
            view.CanvasPosition=Vector2.new(0,0)
        end
        print('[GrowBlox V8 REPORT]',report)
    end
    local function button(label, frac, fracWidth, callback)
        local b=corner(mk('TextButton', {
            Text=label,Font=Enum.Font.GothamSemibold,TextSize=11,
            TextWrapped=true,TextColor3=white,BackgroundColor3=panelColor,
            BorderSizePixel=0,Position=UDim2.new(frac,5,0,85),
            Size=UDim2.new(fracWidth,-10,0,39)
        },root),6)
        conn(b.MouseButton1Click,callback)
        return b
    end
    local function hasWord(s, words)
        s=string.lower(s)
        for _,word in ipairs(words) do
            if string.find(s,word,1,true) then return true end
        end
        return false
    end
    local keywords={'move','walk','speed','position','velocity','gravity','jump','collision',
                    'noclip','fly','state','player','world','camera','controller','tile','physics'}
    local function objectName(inst)
        local ok, name = pcall(function() return inst:GetFullName() end)
        return ok and name or tostring(inst.Name)
    end
    local targets = {
        {'Shared.Net', function() return RS:FindFirstChild('Shared') and RS.Shared:FindFirstChild('Net') end},
        {'GameGui.MobileControls',function()
            local gg=pg:FindFirstChild('GameGui')
            return gg and gg:FindFirstChild('MobileControls')
        end},
        {'ByteNet.packetIDs',function()
            local b=RS:FindFirstChild('ByteNet')
            local n=b and b:FindFirstChild('namespaces')
            return n and n:FindFirstChild('packetIDs')
        end},
    }
    local function scanExports()
        status('Membaca export dari modul yang SUDAH loaded...')
        local rows={'=== GROWBLOX V8 - MODULE EXPORT STRUCTURE ===',
            'Player='..lp.Name..' PlaceId='..tostring(game.PlaceId),
            'READ ONLY: module exports are not server permission.',
            'Only already-loaded modules are considered.',
            'Key names and types only; NO network functions are called.',''}
        local loadedSet={}
        local getLoadedOK=false
        if type(getloadedmodules)=='function' then
            local ok,result=pcall(getloadedmodules)
            if ok and type(result)=='table' then
                getLoadedOK=true
                for _,module in ipairs(result) do loadedSet[module]=true end
            end
        end
        if not getLoadedOK then
            rows[#rows+1]='getloadedmodules unavailable: export scan skipped to avoid loading unknown modules.'
        end
        local count=0
        local function traverse(value, label, depth, visited)
            if count>=140 then return end
            local ty=typeof(value)
            rows[#rows+1]=string.rep(' ',math.min(depth,4)*2)..label..' : '..ty
            count=count+1
            if ty~='table' or depth>=3 or visited[value] then return end
            visited[value]=true
            local keys={}
            for key in pairs(value) do
                local keytype=typeof(key)
                if keytype=='string' or keytype=='number' then keys[#keys+1]=key end
            end
            table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
            local limit=math.min(#keys,45)
            for i=1,limit do
                if count>=140 then break end
                local key=keys[i]
                local ok,child=pcall(function() return value[key] end)
                if ok then traverse(child,tostring(key),depth+1,visited) end
            end
            if #keys>limit then rows[#rows+1]='  ... '..(#keys-limit)..' more keys (omitted)' end
        end
        for _,target in ipairs(targets) do
            local label,lookup=target[1],target[2]
            local found,mod=pcall(lookup)
            rows[#rows+1]='['..label..']'
            if not found or not mod or not mod:IsA('ModuleScript') then
                rows[#rows+1]='Module not visible'
            elseif not getLoadedOK then
                rows[#rows+1]='SKIPPED (loaded-module API not available)'
            elseif not loadedSet[mod] then
                rows[#rows+1]='SKIPPED (module not previously loaded)'
            else
                local ok,exports=pcall(require,mod)
                if ok then
                    traverse(exports,'EXPORT',0,{})
                else
                    rows[#rows+1]='require cached module failed: '..tostring(exports):sub(1,140)
                end
            end
            rows[#rows+1]=''
        end
        rows[#rows+1]='Note: table keys alone do not identify actual server movement authority.'
        show(table.concat(rows,'\n'))
        status('Export scan selesai. COPY REPORT.')
    end

    local function scanState()
        status('Memeriksa GUI, ValueBase, dan Attributes...')
        local rows={'=== GROWBLOX V8 - LOCAL MOVEMENT STATE ===',
            'PlaceId='..tostring(game.PlaceId),
            'GUI positions use SCREEN PIXELS, not world coordinates.',''}
        local camera=pg:FindFirstChild('GameGui')
        camera=camera and camera:FindFirstChild('World')
        camera=camera and camera:FindFirstChild('Camera')
        local function guiInfo(inst)
            if not inst then return end
            rows[#rows+1]='['..objectName(inst)..']'
            if inst:IsA('GuiObject') then
                rows[#rows+1]='  Position='..tostring(inst.Position)
                rows[#rows+1]='  AbsolutePosition='..tostring(inst.AbsolutePosition)
                rows[#rows+1]='  AbsoluteSize='..tostring(inst.AbsoluteSize)
            end
        end
        guiInfo(camera)
        if camera then
            guiInfo(camera:FindFirstChild('Tiles'))
            guiInfo(camera:FindFirstChild('PlayerView'))
        else rows[#rows+1]='GameGui.World.Camera NOT FOUND' end
        rows[#rows+1]=''
        local candidates={lp,pg}
        for _,obj in ipairs({pg:FindFirstChild('GameGui') or false, lp:FindFirstChild('PlayerScripts') or false, RS:FindFirstChild('Shared') or false}) do
            if obj then candidates[#candidates+1]=obj end
        end
        local seen={}
        local results=0
        local attributes=0
        for _,parent in ipairs(candidates) do
            if parent then
                local list={parent}
                for _,desc in ipairs(parent:GetDescendants()) do list[#list+1]=desc end
                for _,obj in ipairs(list) do
                    if not seen[obj] then
                        seen[obj]=true
                        if obj:IsA('ValueBase') and hasWord(obj.Name,keywords) then
                            results=results+1
                            if results<=70 then
                                local ok,val=pcall(function() return obj.Value end)
                                rows[#rows+1]='VALUE '..objectName(obj)..' = '..(ok and tostring(val) or 'unreadable')
                            end
                        end
                        local ok,attrs=pcall(function() return obj:GetAttributes() end)
                        if ok then
                            for key,val in pairs(attrs) do
                                if hasWord(key,keywords) then
                                    attributes=attributes+1
                                    if attributes<=65 then
                                        local display
                                        if typeof(val)=='string' or typeof(val)=='number' or typeof(val)=='boolean'
                                           or typeof(val)=='Vector2' or typeof(val)=='Vector3' then
                                            display=tostring(val):sub(1,100)
                                        else display='<'..typeof(val)..'>' end
                                        rows[#rows+1]='ATTR '..objectName(obj)..'.'..key..' = '..display
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        rows[#rows+1]=''
        rows[#rows+1]='Matching ValueBase: '..results..' | Attributes: '..attributes
        rows[#rows+1]='No remote events fired. No state was changed.'
        show(table.concat(rows,'\n'))
        status('State scan selesai. COPY REPORT.')
    end
    button('SCAN EXPORTS',0,.37,scanExports)
    button('SCAN STATE',.37,.34,scanState)
    button('COPY REPORT',.71,.29,function()
        local clipboard
        if type(setclipboard)=='function' then clipboard=setclipboard
        elseif type(toclipboard)=='function' then clipboard=toclipboard end
        if not clipboard then status('Clipboard tidak tersedia. Cek console.');return end
        local ok,err=pcall(clipboard,report)
        if ok then status('Laporan tersalin.') else status('Gagal copy: '..tostring(err)) end
    end)

    local dragging,dragStart,frameStart
    conn(head.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.Touch or
           input.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=input
            dragStart=input.Position
            frameStart=root.Position
        end
    end)
    conn(UIS.InputChanged,function(input)
        if dragging and (input==dragging or input.UserInputType==Enum.UserInputType.MouseMovement) then
            local d=input.Position-dragStart
            root.Position=UDim2.new(frameStart.X.Scale,frameStart.X.Offset+d.X,
                                   frameStart.Y.Scale,frameStart.Y.Offset+d.Y)
        end
    end)
    conn(UIS.InputEnded,function(input)
        if input==dragging then dragging=nil end
    end)
    conn(ball.MouseButton1Click,function() root.Visible=not root.Visible end)
    conn(mini.MouseButton1Click,function() root.Visible=false end)
    local function destroy()
        if not alive then return end
        alive=false
        for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
        pcall(function() gui:Destroy() end)
    end
    env.GrowBloxV8={Close=destroy}
    conn(close.MouseButton1Click,destroy)
    if game.PlaceId ~= 112863874972771 then
        status('WARNING: This is not the known GrowBlox PlaceId.')
    else
        status('Ready. SCAN EXPORTS dulu, lalu COPY REPORT.')
    end
end

local ok,err=pcall(main)
if not ok then warn('[GrowBlox V8] Startup failed: '..tostring(err)) end
