--[[
 Growblox Launcher V5 | Movement Correlation Lab
 For Roblox Growblox (PlaceId 112863874972771)
 Delta Android: upload this single self-contained file to GitHub as loader_v5.lua.

 This version correlates tile/camera offsets with player movement
 rather than assuming a Humanoid / HumanoidRootPart. It DOES NOT claim
 to provide genuine flight/noclip until a movement controller is identified.
 Does not call FireServer, InvokeServer, hook outbound traffic or alter server data.
]]
local TAG = '[Growblox V5] '
local function log(s) print(TAG .. tostring(s)) end
local ok, err = xpcall(function()
    local Players = game:GetService('Players')
    local UIS = game:GetService('UserInputService')
    local RS = game:GetService('ReplicatedStorage')
    local WS = game:GetService('Workspace')
    local player = Players.LocalPlayer
    assert(player, 'LocalPlayer not ready')
    local pg = player:WaitForChild('PlayerGui', 15)
    assert(pg, 'PlayerGui not ready')

    local env = _G
    pcall(function() if type(getgenv) == 'function' then env = getgenv() end end)
    for _, key in ipairs({'GrowbloxLauncherV2', 'GrowbloxLauncherV3', 'GrowbloxLauncherV4', 'GrowbloxLauncherV5'}) do
        local prev = env[key]
        if type(prev)=='table' and type(prev.Destroy)=='function' then
            pcall(prev.Destroy)
        end
        local old = pg:FindFirstChild(key)
        if old then pcall(function() old:Destroy() end) end
    end

    local alive = true
    local connections = {}
    local uiOriginals = {}
    local strokes = {}
    local statusText = 'V5 aktif: pemindai pergerakan kamera dan tile 2D Growblox.'
    local report = 'Tekan WATCH MOVE, diam sebentar, berjalan ke KANAN, lalu lompat saat diberi aba-aba.'
    local armed = false
    local busy = false
    local lastTap = nil

    local function connect(signal, fn)
        local c = signal:Connect(fn)
        table.insert(connections, c)
        return c
    end
    local function node(class, props, parent)
        local n = Instance.new(class)
        for k, v in pairs(props or {}) do n[k] = v end
        n.Parent = parent
        return n
    end
    local function rounded(o, r)
        node('UICorner', {CornerRadius=UDim.new(0, r or 8)}, o)
        return o
    end
    local function path(o)
        if not o then return 'nil' end
        local okp, result = pcall(function() return o:GetFullName() end)
        return okp and tostring(result):sub(1,190) or tostring(o.Name)
    end
    local function getWorld()
        local gameGui=pg:FindFirstChild('GameGui')
        local world=gameGui and gameGui:FindFirstChild('World')
        local cam=world and world:FindFirstChild('Camera')
        local view=cam and cam:FindFirstChild('PlayerView')
        local tiles=cam and cam:FindFirstChild('Tiles')
        return gameGui,world,cam,view,tiles
    end
    local palette={bg=Color3.fromRGB(13,20,31),panel=Color3.fromRGB(29,43,58),btn=Color3.fromRGB(46,63,80),
        accent=Color3.fromRGB(42,221,170),white=Color3.fromRGB(242,248,251),muted=Color3.fromRGB(186,199,208),bad=Color3.fromRGB(212,91,99)}

    local gui=node('ScreenGui',{Name='GrowbloxLauncherV5',ResetOnSpawn=false,DisplayOrder=30000,
        IgnoreGuiInset=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},pg)
    local badge=rounded(node('TextButton',{Name='Badge',Text='GB5',Font=Enum.Font.GothamBold,TextSize=14,
        TextColor3=palette.bg,BackgroundColor3=palette.accent,BorderSizePixel=0,
        Position=UDim2.new(0,10,.30,0),Size=UDim2.fromOffset(54,54),ZIndex=100},gui),27)
    local panel=rounded(node('Frame',{Name='Panel',Position=UDim2.new(0,70,.08,0),Size=UDim2.fromOffset(380,434),
        BackgroundColor3=palette.bg,BorderSizePixel=0,Active=true},gui),12)
    node('UIStroke',{Color=palette.accent,Thickness=1,Transparency=.35},panel)
    local scale=node('UIScale',{Scale=1},panel)
    local function updateScale()
        local camera=WS.CurrentCamera
        if camera then scale.Scale=math.clamp((camera.ViewportSize.X-85)/410,.57,1) end
    end
    updateScale()
    local head=rounded(node('Frame',{Name='Header',Size=UDim2.new(1,0,0,42),BackgroundColor3=palette.panel,
        BorderSizePixel=0,Active=true},panel),12)
    node('TextLabel',{Text='GROWBLOX MOVEMENT LAB V5',Font=Enum.Font.GothamBold,TextSize=14,
        TextColor3=palette.white,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,
        Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-114,1,0)},head)
    local minimize=rounded(node('TextButton',{Text='_',Font=Enum.Font.GothamBold,TextSize=17,
        TextColor3=palette.white,BackgroundColor3=palette.btn,Position=UDim2.new(1,-83,0,7),Size=UDim2.fromOffset(32,28)},head),7)
    local exit=rounded(node('TextButton',{Text='X',Font=Enum.Font.GothamBold,TextSize=14,
        TextColor3=palette.white,BackgroundColor3=palette.bad,Position=UDim2.new(1,-44,0,7),Size=UDim2.fromOffset(32,28)},head),7)
    local info=node('TextLabel',{Text=statusText,TextWrapped=true,Font=Enum.Font.Code,TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,
        BackgroundTransparency=1,TextColor3=palette.muted,
        Position=UDim2.fromOffset(10,44),Size=UDim2.new(1,-20,0,37)},panel)
    local function status(s)
        statusText=tostring(s)
        info.Text=statusText
        log(s)
    end

    local tabs={}
    local pages={}
    for i, name in ipairs({'DETECT','VISUAL'}) do
        local b=rounded(node('TextButton',{Text=name,Font=Enum.Font.GothamBold,TextSize=12,
            TextColor3=palette.white,BackgroundColor3=palette.btn,
            Position=UDim2.new((i-1)*.5,5,0,86),Size=UDim2.new(.5,-10,0,34)},panel),7)
        tabs[name]=b
        pages[name]=node('Frame',{Name=name,BackgroundTransparency=1,Visible=false,
            Position=UDim2.fromOffset(10,126),Size=UDim2.new(1,-20,1,-136)},panel)
    end
    local function showPage(name)
        for k,p in pairs(pages) do
            p.Visible=(name==k)
            tabs[k].BackgroundColor3=(name==k) and palette.accent or palette.btn
            tabs[k].TextColor3=(name==k) and palette.bg or palette.white
        end
    end
    for name, b in pairs(tabs) do connect(b.MouseButton1Click, function() showPage(name) end) end
    showPage('DETECT')

    local function button(parent, text, x,y,w,h,fn)
        local b=rounded(node('TextButton',{Text=text,Font=Enum.Font.GothamSemibold,TextSize=12,
            TextColor3=palette.white,BackgroundColor3=palette.btn,TextWrapped=true,
            Position=UDim2.new(x,0,0,y),Size=UDim2.new(w,-5,0,h),BorderSizePixel=0},parent),7)
        if fn then connect(b.MouseButton1Click,fn) end
        return b
    end
    local detect=pages.DETECT
    local reportFrame=rounded(node('ScrollingFrame',{Name='ReportScroll',BackgroundColor3=palette.panel,BorderSizePixel=0,
        Position=UDim2.fromOffset(0,92),Size=UDim2.new(1,0,1,-92),AutomaticCanvasSize=Enum.AutomaticSize.Y,
        CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=3},detect),8)
    local reportLabel=node('TextLabel',{Text=report,Font=Enum.Font.Code,TextSize=11,TextColor3=palette.white,
        TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
        BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,
        Position=UDim2.fromOffset(7,6),Size=UDim2.new(1,-16,0,0)},reportFrame)
    local function paint(s)
        report=tostring(s)
        reportLabel.Text=report:sub(1,24000)
        env.GrowbloxV5Report=report
    end
    local function details(o)
        if not o then return '(missing)' end
        local out={o.ClassName..' '..path(o)}
        if o:IsA('GuiObject') then
            out[#out+1]='  Position: '..tostring(o.Position)..' | Absolute: '..tostring(o.AbsolutePosition)
            out[#out+1]='  Size: '..tostring(o.Size)..' | Absolute: '..tostring(o.AbsoluteSize)
            out[#out+1]='  Visible: '..tostring(o.Visible)..' | ZIndex: '..tostring(o.ZIndex)
            if o:IsA('ImageLabel') or o:IsA('ImageButton') then
                out[#out+1]='  Image: '..tostring(o.Image):sub(1,90)
            end
        elseif o:IsA('ValueBase') then
            pcall(function() out[#out+1]='  Value: '..tostring(o.Value) end)
        end
        local okA, attrs=pcall(function() return o:GetAttributes() end)
        if okA then
            local pairsList={}
            for k,v in pairs(attrs) do pairsList[#pairsList+1]=tostring(k)..'='..tostring(v) end
            table.sort(pairsList)
            if #pairsList>0 then out[#out+1]='  Attr: '..table.concat(pairsList,', '):sub(1,250) end
        end
        return table.concat(out,'\n')
    end
    local function scan2D()
        if busy then status('Pekerjaan lain masih aktif.'); return end
        busy=true
        status('Memeriksa GUI dunia Growblox...')
        local okS, errorS=pcall(function()
            local gg,world,cam,view,tiles=getWorld()
            local lines={
                '=== GROWBLOX V5 - SCAN 2D ===',
                'PlaceId: '..tostring(game.PlaceId),
                'LocalPlayer: '..tostring(player.Name),
                'Character 3D: '..(player.Character and path(player.Character) or 'nil'),
                '=== WORLD ROOTS ===',
                details(gg),details(world),details(cam),details(view),details(tiles),
                '=== CAMERA DIRECT CHILDREN ==='
            }
            if cam then
                for i,o in ipairs(cam:GetChildren()) do
                    if i>45 then lines[#lines+1]='... more omitted'; break end
                    lines[#lines+1]=o.Name..' : '..o.ClassName..' ('..#o:GetChildren()..' direct children)'
                end
            end
            lines[#lines+1]='=== PLAYERVIEW DESCENDANTS (depth <= 5) ==='
            if view then
                local q={{view,0}}
                local idx=1
                local n=0
                while idx<=#q and n<170 do
                    local item=q[idx]; idx=idx+1
                    local obj,depth=item[1],item[2]
                    if depth>0 then
                        lines[#lines+1]=string.rep('  ',depth)..obj.Name..' ['..obj.ClassName..']'
                        if obj:IsA('GuiObject') then
                            lines[#lines+1]=string.rep('  ',depth)..'  xy='..tostring(obj.AbsolutePosition)..' size='..tostring(obj.AbsoluteSize)
                        elseif obj:IsA('ValueBase') then
                            pcall(function() lines[#lines+1]='  VALUE='..tostring(obj.Value) end)
                        end
                        n=n+1
                    end
                    if depth<5 then
                        for _,child in ipairs(obj:GetChildren()) do q[#q+1]={child,depth+1} end
                    end
                end
                lines[#lines+1]='Listed: '..n
            end
            lines[#lines+1]='=== POSSIBLE CLIENT CONTROLLERS (names only) ==='
            local counts=0
            local d=pg:GetDescendants()
            for _,o in ipairs(d) do
                if o~=gui and not o:IsDescendantOf(gui) and (o:IsA('LocalScript') or o:IsA('ModuleScript')) then
                    if counts<35 then lines[#lines+1]=path(o) end
                    counts=counts+1
                end
            end
            lines[#lines+1]='Visible Local/ModuleScripts: '..counts..' (source not read)'
            lines[#lines+1]='=== NETWORK OBJECTS (names only) ==='
            local count=0
            for _,o in ipairs(RS:GetDescendants()) do
                if o:IsA('RemoteEvent') or o:IsA('RemoteFunction') or o:IsA('UnreliableRemoteEvent') then
                    count=count+1
                    if count<=25 then lines[#lines+1]=o.ClassName..': '..path(o) end
                end
            end
            lines[#lines+1]='Total: '..count
            lines[#lines+1]='\nNext: WATCH MOVE: IDLE 2s -> WALK RIGHT 4s -> JUMP 3s.'
            paint(table.concat(lines,'\n'))
            status('SCAN 2D selesai. Jalankan WATCH MOVE.')
        end)
        if not okS then status('SCAN ERROR: '..tostring(errorS)); paint(report..'\nERROR: '..tostring(errorS)) end
        busy=false
    end

    -- V5 focused tracker: limb sprites intentionally excluded.
    local function findTargets()
        local result,seen={},{ }
        local gg,world,cam,view,tiles=getWorld()
        local function add(o,label)
            if o and not seen[o] then
                seen[o]=true
                result[#result+1]={obj=o,label=label or path(o)}
            end
        end
        add(player,'LocalPlayer')
        add(gg,'GameGui')
        add(world,'World')
        add(cam,'Camera')
        add(view,'PlayerView')
        add(tiles,'Tiles')
        if world then
            add(world:FindFirstChild('Backdrop'),'Backdrop')
            add(world:FindFirstChild('WorldFxLayer'),'WorldFxLayer')
        end
        if cam then
            add(cam:FindFirstChild('PlayerShadow'),'PlayerShadow')
            add(cam:FindFirstChild('Crack'),'Crack')
            for _,o in ipairs(cam:GetChildren()) do
                add(o,'Camera/'..o.Name)
            end
        end
        if view then
            local playerSprite=view:FindFirstChild('Player')
            add(playerSprite,'PlayerView/Player')
            if playerSprite then
                add(playerSprite:FindFirstChild('FacingLeft'),'PlayerView/Player/FacingLeft')
                add(playerSprite:FindFirstChild('FacingRight'),'PlayerView/Player/FacingRight')
                for _,o in ipairs(playerSprite:GetChildren()) do
                    if o:IsA('ValueBase') then add(o,'PlayerValue/'..o.Name) end
                end
            end
        end
        if tiles then
            local i=0
            for _,o in ipairs(tiles:GetDescendants()) do
                if o:IsA('ImageLabel') or o:IsA('ImageButton') then
                    i=i+1
                    if i>55 then break end
                    add(o,'TILE#'..i..'/'..o.Name)
                end
            end
        end
        local n=0
        for _,o in ipairs(player:GetDescendants()) do
            if n>=100 then break end
            if o:IsA('ValueBase') and not o:IsDescendantOf(gui) then
                add(o,'VALUE/'..path(o))
                n=n+1
            end
        end
        local selected=0
        for _,o in ipairs(RS:GetDescendants()) do
            if selected>=30 then break end
            if o:IsA('ValueBase') and string.find(string.lower(o.Name),'pos',1,true) then
                add(o,'RS_VALUE/'..path(o)); selected=selected+1
            end
        end
        return result,tiles
    end
    local function numericSample(o)
        if not o or not o.Parent then return nil end
        local p={}
        if o:IsA('GuiObject') then
            local a=o.AbsolutePosition
            local q=o.Position
            p.AbsX=a.X; p.AbsY=a.Y
            p.OffX=q.X.Offset; p.OffY=q.Y.Offset
            p.ScaleX=q.X.Scale; p.ScaleY=q.Y.Scale
        elseif o:IsA('ValueBase') then
            local okV,v=pcall(function() return o.Value end)
            if okV then
                if type(v)=='number' then p.Value=v
                elseif typeof(v)=='Vector2' then p.ValueX=v.X;p.ValueY=v.Y
                elseif typeof(v)=='Vector3' then p.ValueX=v.X;p.ValueY=v.Y;p.ValueZ=v.Z end
            end
        end
        local okA,attrs=pcall(function() return o:GetAttributes() end)
        if okA then
            for k,v in pairs(attrs) do
                local nm=string.lower(k)
                local candidate=nm:find('pos',1,true) or nm:find('coord',1,true) or
                    nm:find('x',1,true) or nm:find('y',1,true) or nm:find('velocity',1,true)
                if candidate then
                    if type(v)=='number' then p['@'..k]=v
                    elseif typeof(v)=='Vector2' then p['@'..k..'.X']=v.X;p['@'..k..'.Y']=v.Y
                    elseif typeof(v)=='Vector3' then
                        p['@'..k..'.X']=v.X;p['@'..k..'.Y']=v.Y;p['@'..k..'.Z']=v.Z
                    end
                end
            end
        end
        return p
    end
    local function watchMovement()
        if busy then status('Pekerjaan lain masih aktif.'); return end
        busy=true
        local targets,tiles=findTargets()
        local track={IDLE={},RIGHT={},JUMP={}}
        local phases={{'IDLE',2.0},{'RIGHT',4.2},{'JUMP',3.2}}
        local oldPanel=panel.Visible
        panel.Visible=false
        local oldBadge=badge.Text
        local stageBanner=rounded(node('TextLabel',{
            Name='MovementPrompt',Font=Enum.Font.GothamBold,TextSize=18,
            TextColor3=palette.bg,BackgroundColor3=palette.accent,
            TextWrapped=true,Size=UDim2.new(0,325,0,40),
            Position=UDim2.new(.5,-162,0,70),ZIndex=120,
            Text='START',BorderSizePixel=0},gui),8)
        local function takeReading(bucket)
            for i,e in ipairs(targets) do
                local p=numericSample(e.obj)
                if p then
                    for k,v in pairs(p) do
                        local key=tostring(i)..'|'..k
                        local rec=bucket[key]
                        if not rec then
                            bucket[key]={label=e.label,property=k,initial=v,last=v,min=v,max=v,count=1}
                        else
                            rec.last=v
                            rec.min=math.min(rec.min,v)
                            rec.max=math.max(rec.max,v)
                            rec.count=rec.count+1
                        end
                    end
                end
            end
        end
        local beforeTiles={}
        local afterTiles={}
        local function snapshotTileObjects(dest)
            if not tiles then return end
            local cnt=0
            for _,o in ipairs(tiles:GetDescendants()) do
                if o:IsA('ImageLabel') or o:IsA('ImageButton') then
                    dest[o]=true; cnt=cnt+1
                    if cnt>=600 then break end
                end
            end
        end
        local okW,errW=pcall(function()
            snapshotTileObjects(beforeTiles)
            for _,phase in ipairs(phases) do
                local label,duration=phase[1],phase[2]
                badge.Text=label=='IDLE' and 'IDLE' or (label=='RIGHT' and 'RIGHT' or 'JUMP')
                stageBanner.Text=(label=='IDLE' and 'DIAM - jangan gerak') or
                    (label=='RIGHT' and 'JALAN KE KANAN ->') or 'LOMPAT BERULANG'
                status('WATCH '..label..': '..duration..' detik')
                local bucket=track[label]
                local started=os.clock()
                repeat
                    takeReading(bucket)
                    task.wait(.16)
                until not alive or (os.clock()-started)>=duration
            end
            snapshotTileObjects(afterTiles)
            local newborn,deleted=0,0
            for o in pairs(afterTiles) do if not beforeTiles[o] then newborn=newborn+1 end end
            for o in pairs(beforeTiles) do if not afterTiles[o] then deleted=deleted+1 end end
            local candidates={}
            for key,r in pairs(track.RIGHT) do
                local idle=track.IDLE[key]
                local jump=track.JUMP[key]
                local rightRange=r.max-r.min
                local idleRange=idle and idle.max-idle.min or 0
                local jumpRange=jump and jump.max-jump.min or 0
                local net=r.last-r.initial
                local effect=math.max(0,rightRange-idleRange)
                if effect>0.20 or math.abs(net)>0.20 then
                    local priority=effect
                    if r.label:find('TILE#',1,true) then priority=priority+5 end
                    if r.label:find('Camera',1,true) or r.label=='Tiles' or r.label=='World' then priority=priority+4 end
                    if r.label:find('Value',1,true) or r.label:find('VALUE/',1,true) then priority=priority+3 end
                    candidates[#candidates+1]={r=r,range=rightRange,idle=idleRange,jump=jumpRange,net=net,priority=priority}
                end
            end
            table.sort(candidates,function(a,b)
                if a.priority==b.priority then return a.r.label<b.r.label end
                return a.priority>b.priority
            end)
            local lines={
                '=== GROWBLOX V5 - CORRELATED MOVEMENT ===',
                'Player: '..tostring(player.Name)..' | PlaceId: '..tostring(game.PlaceId),
                'Phases: IDLE 2.0s -> RIGHT 4.2s -> JUMP 3.2s',
                'Movement recorded from GUI/Value snapshots only. Not server positions.',
                'Tracked stable objects: '..#targets,
                'Tile render objects: before='..(function()local n=0;for _ in pairs(beforeTiles) do n=n+1 end;return n end)()..', after='..(function()local n=0;for _ in pairs(afterTiles) do n=n+1 end;return n end)(),
                'New tiles: '..newborn..' | Gone tiles: '..deleted,
                'Candidates with movement beyond idle: '..#candidates,
                '=== TOP MOVEMENT CORRELATIONS ==='
            }
            for i=1,math.min(#candidates,45) do
                local c=candidates[i]
                lines[#lines+1]=string.format('%02d %s | %s | RIGHT NET=%.2f RANGE=%.2f | IDLE RANGE=%.2f | JUMP RANGE=%.2f',
                    i,c.r.label,c.r.property,c.net,c.range,c.idle,c.jump)
            end
            if #candidates==0 then
                lines[#lines+1]='No qualifying position/value movement found. Game may use private Lua state and redraw tiles.'
            end
            lines[#lines+1]='NOTE: Moving tile images or camera does NOT prove game-coordinate control. No server packets were sent.'
            paint(table.concat(lines,'\n'))
            status('WATCH selesai, COPY REPORT untuk dikirim.')
        end)
        if stageBanner and stageBanner.Parent then stageBanner:Destroy() end
        badge.Text=oldBadge
        if alive then panel.Visible=oldPanel end
        if not okW then status('WATCH ERROR: '..tostring(errW));paint(report..'\nERROR: '..tostring(errW)) end
        busy=false
    end
    button(detect,'SCAN 2D',0,0,.5,35,function() task.spawn(scan2D) end)
    button(detect,'WATCH MOVE 9s',.5,0,.5,35,function() task.spawn(watchMovement) end)
    button(detect,'INSPECT TAP',0,43,.5,35,function()
        armed=true
        panel.Visible=false
        status('Inspect aktif. Ketuk tepat pada karakter, bukan langit/tanah kosong.')
    end)
    button(detect,'COPY REPORT',.5,43,.5,35,function()
        local exported=report
        if type(setclipboard)=='function' then
            local okClip=pcall(setclipboard,exported)
            if okClip then status('Laporan disalin, tempel di chat.'); return end
        end
        if type(writefile)=='function' then
            local saved=pcall(writefile,'Growblox_V5_Report.txt',exported)
            if saved then status('Laporan tersimpan di Growblox_V5_Report.txt'); return end
        end
        status('Clipboard tidak tersedia; report dicetak ke console.')
        log(exported)
    end)

    -- Visual utilities target named 2D layers found in the user's inspect report.
    local visual=pages.VISUAL
    local function setVisible(target, hide)
        if not target or not target:IsA('GuiObject') then return 0 end
        if hide then
            if uiOriginals[target]==nil then uiOriginals[target]=target.Visible end
            target.Visible=false
        else
            if uiOriginals[target]~=nil then target.Visible=uiOriginals[target];uiOriginals[target]=nil end
        end
        return 1
    end
    local weatherOff=false
    local weatherBtn
    weatherBtn=button(visual,'HIDE WEATHER OFF',0,0,1,37,function()
        local gg,world=getWorld()
        if not world then status('World tidak ditemukan.');return end
        weatherOff=not weatherOff
        local count=0
        for _,n in ipairs({'WeatherFront','WeatherBack'}) do
            count=count+setVisible(world:FindFirstChild(n),weatherOff)
        end
        count=count+setVisible(gg and gg:FindFirstChild('WorldFxLayer'),weatherOff)
        weatherBtn.Text=weatherOff and 'HIDE WEATHER ON' or 'HIDE WEATHER OFF'
        status('2D Weather/FX layer '..(weatherOff and 'hidden' or 'restored')..' ('..count..' layer).')
    end)
    local outlined=false
    local tileBtn
    tileBtn=button(visual,'TILE OUTLINE OFF',0,47,1,37,function()
        outlined=not outlined
        local _,_,_,_,tiles=getWorld()
        if outlined then
            if not tiles then status('Tiles container tidak ditemukan.');outlined=false;return end
            local n=0
            for _,o in ipairs(tiles:GetDescendants()) do
                if n>=160 then break end
                if o:IsA('ImageLabel') or o:IsA('ImageButton') then
                    local stroke=Instance.new('UIStroke')
                    stroke.Name='GB5TileDebugOutline'
                    stroke.Color=palette.accent
                    stroke.Transparency=.45
                    stroke.Thickness=1
                    stroke.Parent=o
                    strokes[#strokes+1]=stroke
                    n=n+1
                end
            end
            status('Garis 2D ditambahkan ke '..n..' elemen tile (visual lokal).')
        else
            for _,s in ipairs(strokes) do pcall(function() s:Destroy() end) end
            strokes={}
            status('Garis tile dimatikan.')
        end
        tileBtn.Text=outlined and 'TILE OUTLINE ON' or 'TILE OUTLINE OFF'
    end)
    local hudOff=false
    local hudBtn
    hudBtn=button(visual,'HIDE SIDE HUD OFF',0,94,1,37,function()
        hudOff=not hudOff
        local targets={}
        local m=pg:FindFirstChild('MenuGui')
        if m then targets[#targets+1]=m:FindFirstChild('SideButtons') end
        local c=pg:FindFirstChild('ChatGui')
        if c then targets[#targets+1]=c:FindFirstChild('HUD') end
        local n=0
        for _,v in ipairs(targets) do n=n+setVisible(v,hudOff) end
        hudBtn.Text=hudOff and 'HIDE SIDE HUD ON' or 'HIDE SIDE HUD OFF'
        status('Side HUD '..(hudOff and 'hidden' or 'restored')..' ('..n..' layers).')
    end)
    node('TextLabel',{Text='Fitur VISUAL mengubah tampilan lokal Growblox, bukan posisi atau data server.\n\nFly/No Clip asli belum tersedia: GrowBlox tidak mengekspos Humanoid dan koordinat dunia dari laporan saat ini. Gunakan WATCH MOVE untuk membandingkan posisi saat diam dan berjalan. Isi laporan bukan koordinat server.',
        Font=Enum.Font.Code,TextSize=11,TextWrapped=true,TextColor3=palette.muted,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
        BackgroundTransparency=1,Position=UDim2.fromOffset(3,152),Size=UDim2.new(1,-6,0,138)},visual)

    local dragInput,dragStart,dragPos
    connect(head.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
            dragInput=input; dragStart=input.Position; dragPos=panel.Position
        end
    end)
    connect(UIS.InputChanged,function(input)
        if dragInput and dragStart and dragPos and
           (input==dragInput or (dragInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)) then
            local delta=input.Position-dragStart
            panel.Position=UDim2.new(dragPos.X.Scale,dragPos.X.Offset+delta.X,dragPos.Y.Scale,dragPos.Y.Offset+delta.Y)
        end
    end)
    connect(UIS.InputEnded,function(input) if input==dragInput then dragInput=nil end end)
    connect(badge.MouseButton1Click,function() panel.Visible=not panel.Visible end)
    connect(minimize.MouseButton1Click,function() panel.Visible=false end)
    local function close()
        if not alive then return end
        alive=false
        for o,vis in pairs(uiOriginals) do pcall(function() if o.Parent then o.Visible=vis end end) end
        for _,o in ipairs(strokes) do pcall(function() o:Destroy() end) end
        for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
        pcall(function() gui:Destroy() end)
        env.GrowbloxLauncherV5=nil
    end
    connect(exit.MouseButton1Click,close)
    connect(UIS.InputBegan,function(input, processed)
        if not alive or not armed then return end
        if input.UserInputType~=Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        local p=input.Position
        if p.X>=badge.AbsolutePosition.X and p.X<=badge.AbsolutePosition.X+badge.AbsoluteSize.X and
           p.Y>=badge.AbsolutePosition.Y and p.Y<=badge.AbsolutePosition.Y+badge.AbsoluteSize.Y then return end
        armed=false
        task.spawn(function()
            local lines={'=== GROWBLOX V5 - TOUCH INSPECT ===','Touch screen XY: '..tostring(p),
                'Important: tap sprite center for character info; tapping sky only identifies backdrop frames.',
                '=== TOP GUI OBJECTS AT TOUCH ==='}
            local s,objects=pcall(function() return pg:GetGuiObjectsAtPosition(p.X,p.Y) end)
            if s and type(objects)=='table' then
                local count=0
                for _,o in ipairs(objects) do
                    if not o:IsDescendantOf(gui) then
                        count=count+1
                        lines[#lines+1]=details(o)
                        if count>=12 then break end
                    end
                end
                if count==0 then lines[#lines+1]='No underlying GuiObjects.' end
            else lines[#lines+1]='GetGuiObjectsAtPosition unavailable.' end
            local _,_,_,view,tiles=getWorld()
            lines[#lines+1]='=== PLAYER VIEW ==='
            lines[#lines+1]=details(view)
            lines[#lines+1]='=== TILES CONTAINER ==='
            lines[#lines+1]=details(tiles)
            paint(table.concat(lines,'\n'))
            panel.Visible=true
            showPage('DETECT')
            status('Inspect selesai. COPY REPORT untuk dikirim.')
        end)
    end)
    env.GrowbloxLauncherV5={Destroy=close,Scan=scan2D,Watch=watchMovement}
    status('V5 siap. WATCH MOVE menganalisis tile dan kamera saat bergerak.')
    task.spawn(scan2D)
end, function(e)
    if debug and debug.traceback then return debug.traceback(tostring(e)) end
    return tostring(e)
end)
if not ok then warn(TAG..'STARTUP ERROR: '..tostring(err)) end
