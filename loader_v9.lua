--[[
GrowBlox V9 | Complete Network Index (Delta Android)
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
    if type(env.GrowBloxV9) == 'table' and type(env.GrowBloxV9.Close) == 'function' then
        pcall(env.GrowBloxV9.Close)
    end
    local old = pg:FindFirstChild('GBV9_Inspector')
    if old then old:Destroy() end

    local alive = true
    local connections = {}
    local report = 'GROWBLOX V9: Tekan SCAN CALLS atau SCAN ASK.'
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
        Name='GBV9_Inspector', DisplayOrder=31000,
        ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    }, pg)
    local ball = corner(mk('TextButton', {
        Text='GB9', Font=Enum.Font.GothamBold, TextSize=14,
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
        Text='GROWBLOX V9  |  NETWORK INDEX',Font=Enum.Font.GothamBold,
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
        env.GrowBloxV9Report=report
        if alive then
            textLabel.Text=report:sub(1,30000)
            view.CanvasPosition=Vector2.new(0,0)
        end
        print('[GrowBlox V9 REPORT]',report)
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
    -- Read-only: only inspect a module that Delta reports is already loaded.
    -- No remote calls, getgc hooks, packet sends, or source decompilation.
    local function cachedNet()
        if type(getloadedmodules) ~= 'function' then
            return nil,'Delta does not expose getloadedmodules().'
        end
        local ok,loaded=pcall(getloadedmodules)
        if not ok or type(loaded)~='table' then
            return nil,'Could not read loaded-module list.'
        end
        local shared=RS:FindFirstChild('Shared')
        local mod=shared and shared:FindFirstChild('Net')
        if not mod or not mod:IsA('ModuleScript') then
            return nil,'Shared.Net was not found.'
        end
        local previouslyLoaded=false
        for _,entry in ipairs(loaded) do
            if entry==mod then previouslyLoaded=true;break end
        end
        if not previouslyLoaded then
            return nil,'Shared.Net is not loaded; scanner will not load it.'
        end
        local success,exports=pcall(require,mod)
        if not success or type(exports)~='table' then
            return nil,'Cached Shared.Net export not accessible.'
        end
        return exports,nil
    end
    local function keysOf(tbl)
        local result={}
        if type(tbl)~='table' then return result end
        for k in pairs(tbl) do
            if type(k)=='string' or type(k)=='number' then
                result[#result+1]=k
            end
        end
        table.sort(result,function(x,y)
            if type(x)=='number' and type(y)=='number' then return x<y end
            return tostring(x)<tostring(y)
        end)
        return result
    end
    local function redact(value)
        if type(value)~='string' then return '('..typeof(value)..')' end
        -- Only show reasonably short route-like names, not arbitrary payloads/secrets.
        if #value>70 then return '[hidden: long string]' end
        local lower=string.lower(value)
        if lower:find('token',1,true) or lower:find('secret',1,true) or
           lower:find('password',1,true) or lower:find('api_key',1,true) or
           lower:find('authorization',1,true) then return '[hidden: sensitive-looking]' end
        if not value:match('^[%w_%.%-%/: ]+$') then return '[hidden: non-route string]' end
        return value
    end
    local function scanCalls()
        status('Mengindeks seluruh CALLS, tidak memanggil fungsi...')
        local rows={
            '=== GROWBLOX V9 - COMPLETE CALLS INDEX ===',
            'PlaceId='..tostring(game.PlaceId),
            'READ ONLY. No send(), out(), back(), FireServer() or hooks.',
            'This is a client-side export inventory, not server permissions.',
            ''
        }
        local net,err=cachedNet()
        if not net then
            rows[#rows+1]='ERROR: '..tostring(err)
        elseif type(net.CALLS)~='table' then
            rows[#rows+1]='Shared.Net.CALLS not a table.'
        else
            local keys=keysOf(net.CALLS)
            rows[#rows+1]='Total CALLS='..tostring(#keys)
            for _,key in ipairs(keys) do
                local entry=rawget(net.CALLS,key)
                local meta={}
                if type(entry)=='table' then
                    for _,field in ipairs({'ask','reply','fn','send','out','back','args','forever'}) do
                        local val=rawget(entry,field)
                        if val~=nil then meta[#meta+1]=field..':'..typeof(val) end
                    end
                end
                rows[#rows+1]=tostring(key)..' {'..table.concat(meta,', ')..'}'
            end
        end
        rows[#rows+1]=''
        rows[#rows+1]='Function names/types do not reveal argument schemas or movement authority.'
        show(table.concat(rows,'\n'))
        status('CALLS selesai. COPY REPORT.')
    end
    local function scanAsks()
        status('Mengindeks ASK route names tanpa network calls...')
        local rows={
            '=== GROWBLOX V9 - ASK ROUTE INDEX ===',
            'PlaceId='..tostring(game.PlaceId),
            'READ ONLY. Short route-like strings only; others hidden.',
            ''
        }
        local net,err=cachedNet()
        if not net then
            rows[#rows+1]='ERROR: '..tostring(err)
        elseif type(net.ASK)~='table' then
            rows[#rows+1]='Shared.Net.ASK not a table.'
        else
            local keys=keysOf(net.ASK)
            rows[#rows+1]='Total ASK keys='..tostring(#keys)
            for _,key in ipairs(keys) do
                rows[#rows+1]=tostring(key)..' = '..redact(rawget(net.ASK,key))
            end
        end
        rows[#rows+1]=''
        rows[#rows+1]='No packet payloads are decoded or transmitted.'
        show(table.concat(rows,'\n'))
        status('ASK selesai. COPY REPORT.')
    end
    button('SCAN CALLS',0,.37,scanCalls)
    button('SCAN ASK',.37,.34,scanAsks)
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
    env.GrowBloxV9={Close=destroy}
    conn(close.MouseButton1Click,destroy)
    if game.PlaceId ~= 112863874972771 then
        status('WARNING: This is not the known GrowBlox PlaceId.')
    else
        status('Ready. SCAN CALLS / SCAN ASK, lalu COPY REPORT.')
    end
end

local ok,err=pcall(main)
if not ok then warn('[GrowBlox V9] Startup failed: '..tostring(err)) end
