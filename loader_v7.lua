--[[
Growblox V7 - ByteNet & Controller Map
For Roblox Growblox (PlaceId 112863874972771), Delta Android.
READ-ONLY: no FireServer, no InvokeServer, no hooks, no packet replay,
no server modifications. Shows client-visible module names and counts incoming
RemoteEvent traffic; cannot decode ByteNet packets without packet definitions.
]]

local function start()
    local Players = game:GetService('Players')
    local RS = game:GetService('ReplicatedStorage')
    local UIS = game:GetService('UserInputService')
    local Workspace = game:GetService('Workspace')
    local me = Players.LocalPlayer
    assert(me, 'LocalPlayer not available')
    local pg = me:WaitForChild('PlayerGui', 12)
    assert(pg, 'PlayerGui not available')

    local env = _G
    pcall(function() if type(getgenv)=='function' then env=getgenv() end end)
    if type(env.GrowbloxV7)=='table' and type(env.GrowbloxV7.Destroy)=='function' then
        pcall(env.GrowbloxV7.Destroy)
    end
    local old=pg:FindFirstChild('GrowbloxV7PacketLab')
    if old then old:Destroy() end

    local alive=true
    local watching=false
    local listeners={}
    local watchConnections={}
    local report='GROWBLOX V7: Ready. Press SCAN MODULES or WATCH INCOMING.'

    local function connect(sig,fn)
        local c=sig:Connect(fn)
        listeners[#listeners+1]=c
        return c
    end
    local function make(class, props, parent)
        local x=Instance.new(class)
        for k,v in pairs(props) do x[k]=v end
        x.Parent=parent
        return x
    end
    local function rounded(obj, r)
        make('UICorner',{CornerRadius=UDim.new(0,r or 8)},obj)
        return obj
    end
    local c={bg=Color3.fromRGB(14,20,30),panel=Color3.fromRGB(25,36,51),btn=Color3.fromRGB(41,64,85),
      text=Color3.fromRGB(239,247,255),mint=Color3.fromRGB(43,218,160),dim=Color3.fromRGB(179,197,213),red=Color3.fromRGB(215,87,103)}
    local ui=make('ScreenGui',{Name='GrowbloxV7PacketLab',ResetOnSpawn=false,IgnoreGuiInset=false,
      DisplayOrder=30050,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},pg)
    local bubble=rounded(make('TextButton',{Text='GB7',Font=Enum.Font.GothamBold,TextSize=14,
      BackgroundColor3=c.mint,TextColor3=c.bg,BorderSizePixel=0,Size=UDim2.fromOffset(54,54),
      Position=UDim2.new(0,10,.32,0)},ui),27)
    local panel=rounded(make('Frame',{Name='Panel',Active=true,BackgroundColor3=c.bg,BorderSizePixel=0,
      Position=UDim2.new(0,73,.09,0),Size=UDim2.fromOffset(420,410)},ui),12)
    make('UIStroke',{Color=c.mint,Thickness=1,Transparency=.25},panel)
    local scale=make('UIScale',{Scale=1},panel)
    local function adjust()
        local camera=Workspace.CurrentCamera
        if camera then
            local vp=camera.ViewportSize
            scale.Scale=math.clamp(math.min((vp.X-85)/420,(vp.Y-60)/410),.50,1)
        end
    end
    adjust()
    connect(Workspace:GetPropertyChangedSignal('CurrentCamera'),adjust)

    local header=rounded(make('Frame',{BackgroundColor3=c.panel,BorderSizePixel=0,
      Size=UDim2.new(1,0,0,47),Active=true},panel),12)
    make('TextLabel',{BackgroundTransparency=1,Text='GROWBLOX V7 | PACKET LAB',Font=Enum.Font.GothamBold,
      TextColor3=c.text,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,
      Position=UDim2.fromOffset(11,0),Size=UDim2.new(1,-100,1,0)},header)
    local close=rounded(make('TextButton',{Text='X',Font=Enum.Font.GothamBold,TextSize=14,
      TextColor3=c.text,BackgroundColor3=c.red,BorderSizePixel=0,
      Position=UDim2.new(1,-44,0,9),Size=UDim2.fromOffset(33,29)},header),6)
    local mini=rounded(make('TextButton',{Text='–',Font=Enum.Font.GothamBold,TextSize=16,
      TextColor3=c.text,BackgroundColor3=c.btn,BorderSizePixel=0,
      Position=UDim2.new(1,-82,0,9),Size=UDim2.fromOffset(32,29)},header),6)
    local notice=make('TextLabel',{Text='Read-only. No packets are sent or modified.',BackgroundTransparency=1,
      TextColor3=c.dim,Font=Enum.Font.Code,TextWrapped=true,TextSize=11,
      TextXAlignment=Enum.TextXAlignment.Left,
      Position=UDim2.fromOffset(11,52),Size=UDim2.new(1,-22,0,29)},panel)
    local function status(s) if alive then notice.Text=tostring(s); print('[Growblox V7]',s) end end
    local function btn(text,x,width,callback)
        local b=rounded(make('TextButton',{Text=text,Font=Enum.Font.GothamSemibold,TextSize=11,
          TextWrapped=true,TextColor3=c.text,BackgroundColor3=c.btn,BorderSizePixel=0,
          Position=UDim2.new(x,5,0,87),Size=UDim2.new(width,-10,0,41)},panel),7)
        connect(b.MouseButton1Click,callback)
        return b
    end
    local instructions=make('TextLabel',{Text='WATCH 10s: 0-3 diam, 3-7 jalan kanan, 7-10 lompat.',
      TextSize=11,TextColor3=c.mint,Font=Enum.Font.Code,TextWrapped=true,
      BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,
      Position=UDim2.fromOffset(11,135),Size=UDim2.new(1,-22,0,27)},panel)
    local view=rounded(make('ScrollingFrame',{BackgroundColor3=c.panel,BorderSizePixel=0,
      Position=UDim2.fromOffset(10,168),Size=UDim2.new(1,-20,1,-180),
      CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
      ScrollBarThickness=4},panel),8)
    local label=make('TextLabel',{BackgroundTransparency=1,Font=Enum.Font.Code,TextSize=11,
      TextColor3=c.text,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
      TextYAlignment=Enum.TextYAlignment.Top,Position=UDim2.fromOffset(8,8),
      Size=UDim2.new(1,-18,0,0),AutomaticSize=Enum.AutomaticSize.Y,Text=report},view)
    local function setReport(s)
        report=tostring(s)
        env.GrowbloxV7Report=report
        if alive then label.Text=report:sub(1,26000); view.CanvasPosition=Vector2.new(0,0) end
        print('[Growblox V7 report]',report)
    end

    local function hasKeyword(s)
        s=string.lower(s)
        for _,p in ipairs({'net','packet','remote','control','move','input','state','player','tile','world','physics','collision','character','byte'}) do
            if string.find(s,p,1,true) then return true end
        end
        return false
    end
    local function fullname(obj)
        local ok,s=pcall(function() return obj:GetFullName() end)
        return ok and s or tostring(obj.Name)
    end
    local function scan()
        if watching then status('Finish WATCH first.');return end
        status('Scanning visible modules, events and shared values...')
        local rows={'=== GROWBLOX V7 - NETWORK / CONTROLLER MAP ===',
            'Player='..me.Name..' PlaceId='..tostring(game.PlaceId),
            'READ ONLY: names are not decoded packet definitions.',
            'GUI World: PlayerGui.GameGui.World.Camera',
            'Target: ReplicatedStorage.ByteNetReliable',
            ''}
        local remotes={}
        for _,inst in ipairs(RS:GetDescendants()) do
            if inst:IsA('RemoteEvent') or inst:IsA('UnreliableRemoteEvent') or inst:IsA('RemoteFunction') then
                remotes[#remotes+1]=inst.ClassName..' '..fullname(inst)
            end
        end
        table.sort(remotes)
        rows[#rows+1]='[NETWORK ENDPOINTS] ('..#remotes..')'
        for i=1,math.min(#remotes,70) do rows[#rows+1]=remotes[i] end
        if #remotes==0 then rows[#rows+1]='(none)' end
        rows[#rows+1]=''
        local mods={}
        local function scanModules(root)
            if not root then return end
            for _,inst in ipairs(root:GetDescendants()) do
                if inst:IsA('ModuleScript') and hasKeyword(inst.Name) then mods[#mods+1]=fullname(inst) end
            end
        end
        scanModules(RS)
        scanModules(me:FindFirstChild('PlayerScripts'))
        table.sort(mods)
        rows[#rows+1]='[POTENTIAL MODULES] ('..#mods..')'
        for i=1,math.min(#mods,90) do rows[#rows+1]=mods[i] end
        if #mods==0 then rows[#rows+1]='No matching visible ModuleScripts.' end
        rows[#rows+1]=''
        if type(getloadedmodules)=='function' then
            local ok,loaded=pcall(getloadedmodules)
            if ok and type(loaded)=='table' then
                local lm={}
                for _,m in ipairs(loaded) do
                    if typeof(m)=='Instance' and hasKeyword(m.Name) then lm[#lm+1]=fullname(m) end
                end
                table.sort(lm)
                rows[#rows+1]='[LOADED MODULES] ('..#lm..')'
                for i=1,math.min(#lm,65) do rows[#rows+1]=lm[i] end
                if #lm==0 then rows[#rows+1]='(none matching)' end
            else rows[#rows+1]='[LOADED MODULES] executor does not expose list' end
        else rows[#rows+1]='[LOADED MODULES] getloadedmodules unavailable' end
        rows[#rows+1]=''
        rows[#rows+1]='NOTE: V7 does not require unknown modules or access private server code.'
        setReport(table.concat(rows,'\n'))
        status('Scan finished; COPY REPORT.')
    end

    local function argInfo(val)
        local ty=typeof(val)
        if ty=='buffer' and type(buffer)=='table' then
            local ok,n=pcall(buffer.len,val)
            if not ok then return 'buffer(?)' end
            local hex={}
            for i=0,math.min(n,12)-1 do
                local okay,b=pcall(buffer.readu8,val,i)
                if not okay then break end
                hex[#hex+1]=string.format('%02X',b)
            end
            return 'buffer('..n..' bytes) prefix='..table.concat(hex,' ')
        elseif ty=='string' then return 'string('..#val..' chars)'
        elseif ty=='number' or ty=='boolean' then return ty..'='..tostring(val)
        elseif ty=='Instance' then return 'Instance '..fullname(val)
        else return ty end
    end
    local function stopWatchConnections()
        for _,con in ipairs(watchConnections) do pcall(function() con:Disconnect() end) end
        table.clear(watchConnections)
    end
    local function watch()
        if watching then status('WATCH already active.'); return end
        watching=true
        local endpoints={}
        for _,inst in ipairs(RS:GetDescendants()) do
            if inst:IsA('RemoteEvent') or inst:IsA('UnreliableRemoteEvent') then
                endpoints[#endpoints+1]=inst
            end
        end
        local phases={
          {name='IDLE',seconds=3,count=0,perRemote={},samples={}},
          {name='RIGHT',seconds=4,count=0,perRemote={},samples={}},
          {name='JUMP',seconds=3,count=0,perRemote={},samples={}}
        }
        local phaseIndex=1
        for _,ev in ipairs(endpoints) do
            local ok,listener=pcall(function()
                return ev.OnClientEvent:Connect(function(...)
                    if not watching or not alive then return end
                    local phase=phases[phaseIndex]
                    if not phase then return end
                    phase.count=phase.count+1
                    local name=ev.Name
                    phase.perRemote[name]=(phase.perRemote[name] or 0)+1
                    if #phase.samples<8 then
                        local args={...}
                        local details={}
                        for i=1,math.min(select('#',...),3) do details[#details+1]=argInfo(args[i]) end
                        phase.samples[#phase.samples+1]=name..': '..table.concat(details,' | ')
                    end
                end)
            end)
            if ok and listener then watchConnections[#watchConnections+1]=listener end
        end
        task.spawn(function()
            local ok,err=pcall(function()
                for i,phase in ipairs(phases) do
                    if not alive then break end
                    phaseIndex=i
                    status('WATCH '..phase.name..' '..phase.seconds..'s | '..#watchConnections..' listeners')
                    task.wait(phase.seconds)
                end
            end)
            watching=false
            stopWatchConnections()
            if not alive then return end
            if not ok then status('WATCH error: '..tostring(err));return end
            local lines={'=== GROWBLOX V7 - INCOMING BYTE NET WATCH ===',
              'Player='..me.Name..' PlaceId='..tostring(game.PlaceId),
              'Observed endpoints: '..#endpoints,
              'WARNING: INCOMING ONLY. Not a recording of FireServer/outgoing moves.',
              'No packet was sent, modified or replayed. Hex values are opaque bytes.',
              ''}
            for _,phase in ipairs(phases) do
                lines[#lines+1]='['..phase.name..' '..phase.seconds..'s] Incoming events='..phase.count
                local entries={}
                for name,n in pairs(phase.perRemote) do entries[#entries+1]={name,n} end
                table.sort(entries,function(a,b) return a[2]>b[2] end)
                for i=1,math.min(#entries,10) do
                    lines[#lines+1]='  '..entries[i][1]..' = '..entries[i][2]
                end
                for i=1,#phase.samples do lines[#lines+1]='  sample '..i..' '..phase.samples[i] end
                if phase.count==0 then lines[#lines+1]='  No incoming events in this phase.' end
                lines[#lines+1]=''
            end
            lines[#lines+1]='Interpretation: correlation does not identify packet type or prove authority.'
            lines[#lines+1]='Next: inspect actual packet definitions/controllers if available to client.'
            setReport(table.concat(lines,'\n'))
            status('WATCH completed. Press COPY REPORT.')
        end)
    end
    btn('SCAN MODULES',0,.36,scan)
    btn('WATCH INCOMING',.36,.38,watch)
    btn('COPY REPORT',.74,.26,function()
        local f=(type(setclipboard)=='function' and setclipboard)
          or (type(toclipboard)=='function' and toclipboard)
        if not f then status('Clipboard API unavailable. Read report or inspect console.');return end
        local ok,err=pcall(f,report)
        if ok then status('Report copied to clipboard.') else status('Copy failed: '..tostring(err)) end
    end)
    local dragStart, panelStart, moving
    connect(header.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            moving=input
            dragStart=input.Position
            panelStart=panel.Position
        end
    end)
    connect(UIS.InputChanged,function(input)
        if moving and (input==moving or input.UserInputType==Enum.UserInputType.MouseMovement) then
            local d=input.Position-dragStart
            panel.Position=UDim2.new(panelStart.X.Scale,panelStart.X.Offset+d.X,
                                     panelStart.Y.Scale,panelStart.Y.Offset+d.Y)
        end
    end)
    connect(UIS.InputEnded,function(input)
        if input==moving then moving=nil end
    end)
    connect(bubble.MouseButton1Click,function() panel.Visible=not panel.Visible end)
    connect(mini.MouseButton1Click,function() panel.Visible=false end)
    local function destroy()
        if not alive then return end
        alive=false
        watching=false
        stopWatchConnections()
        for _,conn in ipairs(listeners) do pcall(function() conn:Disconnect() end) end
        pcall(function() ui:Destroy() end)
    end
    env.GrowbloxV7={Destroy=destroy}
    connect(close.MouseButton1Click,destroy)
    if game.PlaceId~=112863874972771 then
        status('WARNING: Unexpected PlaceId '..tostring(game.PlaceId)..'.')
    else
        status('Ready. Scan modules or watch incoming traffic.')
    end
end

local ok,err=pcall(start)
if not ok then warn('[Growblox V7] startup error: '..tostring(err)) end
