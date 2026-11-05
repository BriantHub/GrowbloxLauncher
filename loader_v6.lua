--[[
 Growblox Launcher V6 - 2D Camera & Movement Lab
 Target PlaceId: 112863874972771 (Growblox / ExecutiveStudio)
 Android / Delta: paste this file directly OR upload as loader_v6.lua to GitHub.

 Diagnostic only: tracks public instances, GUI properties and numeric values.
 No outgoing network calls, no packet hooks, no simulated fly/noclip and no server edits.
]]

local TAG = '[Growblox V6] '
local function say(s) print(TAG .. tostring(s)) end

local function startup()
    local Players = game:GetService('Players')
    local UIS = game:GetService('UserInputService')
    local RunService = game:GetService('RunService')
    local Workspace = game:GetService('Workspace')
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local player = Players.LocalPlayer
    assert(player, 'LocalPlayer not ready')
    local pg = player:WaitForChild('PlayerGui', 15)
    assert(pg, 'PlayerGui not found')

    local env = _G
    pcall(function() if type(getgenv) == 'function' then env = getgenv() end end)
    for _, n in ipairs({'GrowbloxLauncherV2','GrowbloxLauncherV3','GrowbloxLauncherV4','GrowbloxLauncherV5','GrowbloxLauncherV6'}) do
        local prior = env[n]
        if type(prior) == 'table' and type(prior.Destroy) == 'function' then
            pcall(prior.Destroy)
        end
        local old = pg:FindFirstChild(n)
        if old then pcall(function() old:Destroy() end) end
    end

    local alive, watching = true, false
    local conns = {}
    local function on(sig, fn)
        local c = sig:Connect(fn)
        conns[#conns + 1] = c
        return c
    end
    local function make(cls, props, parent)
        local obj = Instance.new(cls)
        for k, v in pairs(props or {}) do obj[k] = v end
        obj.Parent = parent
        return obj
    end
    local function corner(obj, rad)
        make('UICorner', {CornerRadius = UDim.new(0, rad or 8)}, obj)
        return obj
    end
    local function full(obj)
        if not obj then return '(missing)' end
        local ok, s = pcall(function() return obj:GetFullName() end)
        return ok and tostring(s) or obj.Name
    end
    local function roots()
        local gg = pg:FindFirstChild('GameGui')
        local world = gg and gg:FindFirstChild('World')
        local camera = world and world:FindFirstChild('Camera')
        local view = camera and camera:FindFirstChild('PlayerView')
        local tiles = camera and camera:FindFirstChild('Tiles')
        return gg, world, camera, view, tiles
    end
    local color = {
        bg=Color3.fromRGB(13,20,31), block=Color3.fromRGB(25,39,54), button=Color3.fromRGB(43,65,84),
        ink=Color3.fromRGB(242,247,252), mute=Color3.fromRGB(187,204,215), mint=Color3.fromRGB(41,221,169),
        warn=Color3.fromRGB(225,88,106)
    }
    local ui = make('ScreenGui', {Name='GrowbloxLauncherV6',DisplayOrder=30020,
        ResetOnSpawn=false,IgnoreGuiInset=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, pg)
    local toggle = corner(make('TextButton',{Name='Toggle',Text='GB6',Font=Enum.Font.GothamBold,
        TextSize=13,TextColor3=color.bg,BackgroundColor3=color.mint,BorderSizePixel=0,
        Position=UDim2.new(0,8,.28,0),Size=UDim2.fromOffset(55,55)},ui),28)
    local panel=corner(make('Frame',{Name='Panel',BackgroundColor3=color.bg,BorderSizePixel=0,
        Position=UDim2.new(0,70,.09,0),Size=UDim2.fromOffset(391,445),Active=true},ui),12)
    make('UIStroke',{Color=color.mint,Thickness=1,Transparency=.3},panel)
    local scale=make('UIScale',{Scale=1},panel)
    local function rescale()
        local cam=Workspace.CurrentCamera
        if cam then scale.Scale=math.clamp((cam.ViewportSize.X-88)/400,.56,1) end
    end
    rescale()
    on(Workspace:GetPropertyChangedSignal('CurrentCamera'),rescale)
    local head=corner(make('Frame',{Name='Header',Size=UDim2.new(1,0,0,46),BackgroundColor3=color.block,
        BorderSizePixel=0,Active=true},panel),12)
    make('TextLabel',{Text='GROWBLOX 2D LAB  V6',BackgroundTransparency=1,Font=Enum.Font.GothamBold,
        TextColor3=color.ink,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-94,1,0),Position=UDim2.fromOffset(12,0)},head)
    local close=corner(make('TextButton',{Text='X',Font=Enum.Font.GothamBold,TextSize=13,
        TextColor3=color.ink,BackgroundColor3=color.warn,Position=UDim2.new(1,-43,0,9),
        Size=UDim2.fromOffset(31,28),BorderSizePixel=0},head),6)
    local mini=corner(make('TextButton',{Text='_',Font=Enum.Font.GothamBold,TextSize=18,
        TextColor3=color.ink,BackgroundColor3=color.button,Position=UDim2.new(1,-80,0,9),
        Size=UDim2.fromOffset(31,28),BorderSizePixel=0},head),6)
    local notice=make('TextLabel',{Text='Ready. Periksa struktur, lalu WATCH 4 PHASES.',Font=Enum.Font.Code,
        TextColor3=color.mute,TextSize=11,TextWrapped=true,BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,
        Position=UDim2.fromOffset(11,48),Size=UDim2.new(1,-22,0,38)},panel)
    local function status(s)
        notice.Text=tostring(s)
        say(s)
    end
    local function button(text, x,y, w, fn)
        local b=corner(make('TextButton',{Text=text,TextWrapped=true,Font=Enum.Font.GothamSemibold,
            TextSize=12,TextColor3=color.ink,BackgroundColor3=color.button,BorderSizePixel=0,
            Position=UDim2.new(x,0,0,y),Size=UDim2.new(w,-7,0,38)},panel),7)
        on(b.MouseButton1Click,fn)
        return b
    end
    local output=corner(make('ScrollingFrame',{Name='Report',BackgroundColor3=color.block,
        BorderSizePixel=0,Position=UDim2.fromOffset(10,180),Size=UDim2.new(1,-20,1,-192),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=4,CanvasSize=UDim2.fromOffset(0,0)},panel),8)
    local label=make('TextLabel',{Name='Text',BackgroundTransparency=1,
        Text='Press SCAN ROOTS first, then WATCH 4 PHASES. This version measures camera + tile motion separately.',
        Font=Enum.Font.Code,TextSize=11,TextColor3=color.ink,TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
        Position=UDim2.fromOffset(8,6),Size=UDim2.new(1,-18,0,0),AutomaticSize=Enum.AutomaticSize.Y},output)
    local report=label.Text
    local function setReport(s)
        report=tostring(s)
        label.Text=report:sub(1,28000)
        env.GrowbloxV6Report=report
        output.CanvasPosition=Vector2.new(0,0)
    end
    local function metrics(obj)
        if not obj or not obj.Parent then return nil end
        local m={}
        if obj:IsA('GuiObject') then
            local a,p=obj.AbsolutePosition,obj.Position
            m.AbsX=a.X;m.AbsY=a.Y
            m.OffX=p.X.Offset;m.OffY=p.Y.Offset
            m.ScaleX=p.X.Scale;m.ScaleY=p.Y.Scale
        elseif obj:IsA('ValueBase') then
            local ok,v=pcall(function() return obj.Value end)
            if ok then
                if type(v)=='number' then m.Value=v
                elseif typeof(v)=='Vector2' then m.ValX=v.X;m.ValY=v.Y
                elseif typeof(v)=='Vector3' then m.ValX=v.X;m.ValY=v.Y;m.ValZ=v.Z end
            end
        end
        local ok,attrs=pcall(function() return obj:GetAttributes() end)
        if ok and type(attrs)=='table' then
            for k,v in pairs(attrs) do
                local name=string.lower(tostring(k))
                if name:find('pos',1,true) or name:find('coord',1,true) or
                   name:find('velo',1,true) or name=='x' or name=='y' or name=='z' or
                   name:find('camera',1,true) then
                    if type(v)=='number' then m['@'..k]=v
                    elseif typeof(v)=='Vector2' then m['@'..k..'X']=v.X;m['@'..k..'Y']=v.Y
                    elseif typeof(v)=='Vector3' then m['@'..k..'X']=v.X;m['@'..k..'Y']=v.Y;m['@'..k..'Z']=v.Z end
                end
            end
        end
        return m
    end
    local function scan()
        if watching then status('WATCH masih aktif.'); return end
        local gg,world,camera,view,tiles=roots()
        local lines={'=== GROWBLOX V6 - STRUCTURE ===',
            'Player='..player.Name..' PlaceId='..tostring(game.PlaceId),
            'Character='..(player.Character and full(player.Character) or '(none)'),
            'GUI World='..full(world),'Camera='..full(camera),'PlayerView='..full(view),'Tiles='..full(tiles)}
        local function row(n,obj)
            if not obj then return end
            local s=n..' ['..obj.ClassName..']'
            if obj:IsA('GuiObject') then
                s=s..' P='..tostring(obj.Position)..' AP='..tostring(obj.AbsolutePosition)..' AS='..tostring(obj.AbsoluteSize)
            end
            local attrs=obj:GetAttributes()
            local ks={}
            for k in pairs(attrs) do ks[#ks+1]=k end
            table.sort(ks)
            if #ks>0 then
                s=s..' ATTRS '
                for i=1,math.min(7,#ks) do local k=ks[i];s=s..tostring(k)..'='..tostring(attrs[k])..';' end
            end
            lines[#lines+1]=s
        end
        row('World',world);row('Camera',camera);row('PlayerView',view);row('Tiles',tiles)
        if camera then
            lines[#lines+1]='=== CAMERA CHILDREN ==='
            for i,obj in ipairs(camera:GetChildren()) do
                if i>35 then break end
                row(obj.Name,obj)
            end
        end
        if view then
            local spr=view:FindFirstChild('Player')
            row('Sprite/Player',spr)
            if spr then
                for _,obj in ipairs(spr:GetChildren()) do
                    if obj:IsA('ValueBase') then row('PlayerValue/'..obj.Name,obj) end
                end
            end
        end
        local tcount=0
        if tiles then
            lines[#lines+1]='=== FIRST TILE RENDERS ==='
            for _,obj in ipairs(tiles:GetDescendants()) do
                if obj:IsA('ImageLabel') or obj:IsA('ImageButton') then
                    tcount=tcount+1
                    if tcount<=4 then row('Tile#'..tcount,obj) end
                end
            end
        end
        lines[#lines+1]='Tile ImageLabel/ImageButton count='..tcount
        lines[#lines+1]='=== NUMERIC VALUEBASE CANDIDATES ==='
        local vcount=0
        for _,obj in ipairs(player:GetDescendants()) do
            if obj:IsA('ValueBase') and not obj:IsDescendantOf(ui) then
                vcount=vcount+1
                if vcount<=35 then
                    local ok,val=pcall(function() return obj.Value end)
                    lines[#lines+1]=full(obj)..'='..(ok and tostring(val) or '(unknown)')
                end
            end
        end
        lines[#lines+1]='Player numeric/value objects found='..vcount
        lines[#lines+1]='=== GAME NETWORK (names, no packets) ==='
        local count=0
        for _,obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA('RemoteEvent') or obj:IsA('RemoteFunction') or obj:IsA('UnreliableRemoteEvent') then
                count=count+1
                if count<=20 then lines[#lines+1]=full(obj)..' ['..obj.ClassName..']' end
            end
        end
        lines[#lines+1]='Remote objects='..count
        lines[#lines+1]='Note: visible GUI states are NOT authoritative server coordinates.'
        setReport(table.concat(lines,'\n'))
        status('SCAN ROOTS selesai. Jalankan WATCH 4 PHASES.')
    end

    local function gather()
        local entries,seen={},{ }
        local gg,world,camera,view,tiles=roots()
        local function add(o,n,kind)
            if o and not seen[o] then
                seen[o]=true
                entries[#entries+1]={obj=o,label=n or full(o),kind=kind or 'ROOT'}
            end
        end
        add(player,'LocalPlayer','VALUE')
        add(gg,'GameGui');add(world,'World');add(camera,'Camera');add(view,'PlayerView');add(tiles,'Tiles')
        if world then
            add(world:FindFirstChild('Backdrop'),'Backdrop')
            add(world:FindFirstChild('WeatherFront'),'WeatherFront')
            add(world:FindFirstChild('WeatherBack'),'WeatherBack')
        end
        if camera then
            add(camera:FindFirstChild('PlayerShadow'),'PlayerShadow')
            for _,o in ipairs(camera:GetChildren()) do add(o,'Camera/'..o.Name) end
        end
        if view then
            local spr=view:FindFirstChild('Player')
            add(spr,'PlayerView/Player')
            if spr then
                add(spr:FindFirstChild('FacingLeft'),'Sprite/FacingLeft')
                add(spr:FindFirstChild('FacingRight'),'Sprite/FacingRight')
            end
        end
        local tileCount=0
        if tiles then
            for _,o in ipairs(tiles:GetDescendants()) do
                if o:IsA('ImageLabel') or o:IsA('ImageButton') then
                    tileCount=tileCount+1
                    if tileCount<=4 then
                        add(o,'TILE/'..tileCount,'TILE')
                        local ancestor=o.Parent
                        local depth=1
                        while ancestor and ancestor~=tiles and depth<=5 do
                            if ancestor:IsA('GuiObject') then
                                add(ancestor,'TILE_PARENT/'..depth..'/'..ancestor.Name,'ROOT')
                            end
                            ancestor=ancestor.Parent;depth=depth+1
                        end
                    end
                end
            end
        end
        local vals=0
        for _,o in ipairs(player:GetDescendants()) do
            if o:IsA('ValueBase') and not o:IsDescendantOf(ui) then
                add(o,'VALUE/'..full(o),'VALUE')
                vals=vals+1
                if vals>=100 then break end
            end
        end
        local rsvals=0
        for _,o in ipairs(ReplicatedStorage:GetDescendants()) do
            if o:IsA('ValueBase') then
                local low=string.lower(o.Name)
                if low:find('pos',1,true) or low:find('coord',1,true) or low:find('camera',1,true) or low:find('velocity',1,true) then
                    add(o,'RS_VALUE/'..full(o),'VALUE')
                    rsvals=rsvals+1
                    if rsvals>=30 then break end
                end
            end
        end
        return entries, tileCount
    end

    local function watch()
        if watching then status('Pengamatan masih berjalan.');return end
        watching=true
        local entries, tileCount=gather()
        local phases={{'IDLE',2},{'RIGHT',3},{'LEFT',3},{'JUMP',3.5}}
        local collected={}
        local previousVisible=panel.Visible
        panel.Visible=false
        local prompt=corner(make('TextLabel',{Name='Phase',Position=UDim2.new(.5,-185,0,73),
            Size=UDim2.fromOffset(370,48),BackgroundColor3=color.mint,TextColor3=color.bg,
            Font=Enum.Font.GothamBold,TextSize=17,TextWrapped=true,Text='PREPARING',ZIndex=90,
            BorderSizePixel=0},ui),9)
        local function snap(bucket)
            for i,t in ipairs(entries) do
                local m=metrics(t.obj)
                if m then
                    for k,v in pairs(m) do
                        local key=i..':'..k
                        local c=bucket[key]
                        if not c then
                            bucket[key]={item=t,prop=k,first=v,last=v,lo=v,hi=v,samples=1}
                        else
                            c.last=v;c.lo=math.min(c.lo,v);c.hi=math.max(c.hi,v);c.samples=c.samples+1
                        end
                    end
                end
            end
        end
        local success,reason=xpcall(function()
            for _,phase in ipairs(phases) do
                local name,duration=phase[1],phase[2]
                prompt.Text=({IDLE='1/4 DIAM - jangan bergerak',RIGHT='2/4 BERJALAN KE KANAN',
                    LEFT='3/4 BERJALAN KE KIRI',JUMP='4/4 LOMPAT BERULANG'})[name]
                local bucket={}
                collected[name]=bucket
                local t0=os.clock()
                repeat
                    snap(bucket)
                    task.wait(.12)
                until not alive or os.clock()-t0>=duration
                if not alive then break end
            end
            if not alive then return end
            local lines={
                '=== GROWBLOX V6 - DIRECTIONAL CAMERA ANALYSIS ===',
                'PlaceId='..tostring(game.PlaceId)..' Player='..player.Name,
                'PHASES IDLE 2s -> RIGHT 3s -> LEFT 3s -> JUMP 3.5s',
                'Tracked objects='..#entries..' | tile ImageLabels='..tileCount,
                'Units of AbsX/AbsY are SCREEN PIXELS. Not server/world position.',
                'NET = last - first, RANGE = high - low within a phase.',
                '=== PRIORITY OBJECT CHANGES ==='
            }
            local keys={}
            for key,r in pairs(collected.IDLE or {}) do keys[key]=r end
            for _,group in pairs(collected) do
                for key,r in pairs(group) do if not keys[key] then keys[key]=r end end
            end
            local ranked={}
            for key,base in pairs(keys) do
                local p={}
                local signal=0
                for _,phase in ipairs(phases) do
                    local r=collected[phase[1]] and collected[phase[1]][key]
                    if r then
                        p[phase[1]]={net=r.last-r.first,range=r.hi-r.lo}
                        if phase[1]~='IDLE' then signal=math.max(signal,r.hi-r.lo,math.abs(r.last-r.first)) end
                    end
                end
                if signal>.3 then
                    local name=base.item.label
                    local pr=signal
                    if base.item.kind=='VALUE' then pr=pr+10000 end
                    if base.item.kind=='ROOT' then pr=pr+5000 end
                    if name=='Camera' or name=='Tiles' or name=='World' or name=='PlayerView' then pr=pr+1500 end
                    if base.prop=='OffX' or base.prop=='OffY' then pr=pr+20 end
                    if base.item.kind=='TILE' then pr=pr+3 end
                    ranked[#ranked+1]={name=name,property=base.prop,score=pr,phases=p,kind=base.item.kind}
                end
            end
            table.sort(ranked,function(a,b)
                if a.score==b.score then return a.name<b.name end
                return a.score>b.score
            end)
            local num=0
            local tileStats={}
            for _,entry in ipairs(ranked) do
                if entry.kind=='TILE' and (entry.property=='AbsX' or entry.property=='AbsY') then
                    if not tileStats[entry.property] then tileStats[entry.property]=entry end
                else
                    if num<38 then
                        num=num+1
                        local seg={}
                        for _,p in ipairs({'IDLE','RIGHT','LEFT','JUMP'}) do
                            local s=entry.phases[p]
                            seg[#seg+1]=p..'='..(s and string.format('%.1f/%.1f',s.net,s.range) or '-')
                        end
                        lines[#lines+1]=string.format('%02d %s | %s | %s',num,entry.name,entry.property,table.concat(seg,' '))
                    end
                end
            end
            for _,prop in ipairs({'AbsX','AbsY'}) do
                local e=tileStats[prop]
                if e then
                    local function fmt(name)
                        local x=e.phases[name]
                        return x and string.format('NET %.1f, RANGE %.1f',x.net,x.range) or '-'
                    end
                    lines[#lines+1]='=== REFERENCE TILE '..prop..' ==='
                    for _,p in ipairs({'IDLE','RIGHT','LEFT','JUMP'}) do lines[#lines+1]=p..': '..fmt(p) end
                end
            end
            if num==0 then lines[#lines+1]='No root/value changed beyond 0.3; movement may exist only in private Lua controller state.' end
            lines[#lines+1]='=== HOW TO INTERPRET ==='
            lines[#lines+1]='If tile AbsX RIGHT<0 and LEFT>0, horizontal camera scroll is confirmed.'
            lines[#lines+1]='If tile AbsY changes on JUMP, a vertical camera follow effect exists.'
            lines[#lines+1]='If only tile pixels change but no Value/Root Position changes, check game controller code; screen pixels cannot drive real fly/noclip.'
            lines[#lines+1]='No outgoing packets sent. This report does not identify server authority or collision functions.'
            setReport(table.concat(lines,'\n'))
            status('WATCH selesai: klik COPY REPORT lalu kirim hasilnya.')
        end,debug.traceback)
        if prompt and prompt.Parent then prompt:Destroy() end
        if alive then panel.Visible=previousVisible end
        watching=false
        if not success then status('WATCH ERROR: '..tostring(reason));setReport(report..'\nWATCH ERROR: '..tostring(reason)) end
    end
    button('SCAN ROOTS',.03,94,.46,function() task.spawn(scan) end)
    button('WATCH 4 PHASES',.52,94,.46,function() task.spawn(watch) end)
    button('COPY REPORT',.03,140,.46,function()
        if type(setclipboard)=='function' then
            local ok=pcall(setclipboard,report)
            if ok then status('Report copied. Paste into chat.');return end
        end
        if type(writefile)=='function' then
            local ok=pcall(writefile,'Growblox_V6_Report.txt',report)
            if ok then status('Saved Growblox_V6_Report.txt');return end
        end
        print(report)
        status('Clipboard unavailable; report printed to console.')
    end)
    button('RESET REPORT',.52,140,.46,function()
        if watching then status('WATCH aktif, tunggu sampai selesai.');return end
        setReport('Laporan dikosongkan. Jalankan WATCH 4 PHASES.')
    end)

    -- Mobile-friendly drag header (touch or mouse). Does not affect in-game controls.
    local moving=false
    local dragOrigin=nil
    local startPosition=nil
    local dragInput=nil
    on(head.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
            moving=true;dragOrigin=input.Position;startPosition=panel.Position
            on(input.Changed,function() if input.UserInputState==Enum.UserInputState.End then moving=false end end)
        end
    end)
    on(head.InputChanged,function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement then dragInput=input end
    end)
    on(UIS.InputChanged,function(input)
        if moving and (input==dragInput or input.UserInputType==Enum.UserInputType.MouseMovement) and dragOrigin then
            local d=input.Position-dragOrigin
            panel.Position=UDim2.new(startPosition.X.Scale,startPosition.X.Offset+d.X,
                startPosition.Y.Scale,startPosition.Y.Offset+d.Y)
        end
    end)
    on(toggle.MouseButton1Click,function() panel.Visible=not panel.Visible end)
    on(mini.MouseButton1Click,function() panel.Visible=false end)
    local function destroy()
        if not alive then return end
        alive=false
        for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        if ui then pcall(function() ui:Destroy() end) end
        if env.GrowbloxLauncherV6 then env.GrowbloxLauncherV6=nil end
    end
    on(close.MouseButton1Click,destroy)
    env.GrowbloxLauncherV6={Destroy=destroy,Version='6.0',GetReport=function()return report end}
    status('V6 loaded. World Camera and tile correlation tools ready.')
end

local ok,err=xpcall(startup,debug.traceback)
if not ok then
    warn(TAG .. tostring(err))
    pcall(function()
        game:GetService('StarterGui'):SetCore('SendNotification',
            {Title='Growblox V6 error',Text=tostring(err):sub(1,160),Duration=9})
    end)
end
