-- GrowBlox Launcher V11 - Action Lab + Movement Compatibility (Delta, Android)
-- PlaceId 112863874972771. Only explicit, user-initiated ordinary operations.
-- Never calls AdminRemotes, DisableAntiCheat, GodMode, or arbitrary remotes.
-- Client send success is NOT proof of server acceptance.
local function start()
    local Players = game:GetService('Players')
    local RS = game:GetService('ReplicatedStorage')
    local UIS = game:GetService('UserInputService')
    local RunService = game:GetService('RunService')
    local Lighting = game:GetService('Lighting')
    local HttpService = game:GetService('HttpService')
    local workspaceService = game:GetService('Workspace')
    local lp = Players.LocalPlayer
    assert(lp, 'LocalPlayer tidak tersedia')
    local pg = lp:WaitForChild('PlayerGui', 12)
    assert(pg, 'PlayerGui tidak tersedia')
    local env = _G
    pcall(function() if type(getgenv) == 'function' then env = getgenv() end end)
    if type(env.GrowBloxV11) == 'table' and type(env.GrowBloxV11.Close) == 'function' then
        pcall(env.GrowBloxV11.Close)
    end
    -- Replace an older launcher cleanly; don't stack interfaces or heartbeat hooks.
    if type(env.GrowBloxV10) == 'table' and type(env.GrowBloxV10.Close) == 'function' then
        pcall(env.GrowBloxV10.Close)
    end
    local previousGui = pg:FindFirstChild('GB_V10_Lab')
    if previousGui then pcall(function() previousGui:Destroy() end) end
    local old = pg:FindFirstChild('GB_V11_Lab')
    if old then old:Destroy() end
    local alive, busy = true, false
    local conns = {}
    local statusText, opInfo, outputText, runButton, authBox, inputBox
    local opButtons = {}
    local lastCall = -1e9
    local opNames = {'CycleItem','BuyItem','DoorPass','ConvertLock'}
    local opStates = {}
    local selected, prepared, preparedPayload = 'CycleItem', nil, nil
    local shortMessage = 'Tekan SCAN. Tidak ada packet dikirim saat scan.'
    local movementNote = 'Belum diuji'
    local localFeatures = {fullbright=false, hideWeather=false, speed=false, noclip=false, fly=false}
    local brightnessOld = nil
    local weatherOld = {}
    local collisionOld = {}
    local originalSpeed = nil
    local flyUp, flyDown = false, false
    local upButton, downButton
    local screen

    local function conn(sig, fn)
        local c = sig:Connect(fn)
        conns[#conns+1] = c
        return c
    end
    local function mk(class, props, parent)
        local inst = Instance.new(class)
        for k, v in pairs(props or {}) do inst[k] = v end
        if parent then inst.Parent = parent end
        return inst
    end
    local function rounded(inst, radius)
        mk('UICorner', {CornerRadius=UDim.new(0, radius or 8)}, inst)
        return inst
    end
    local ink = Color3.fromRGB(229,238,244)
    local muted = Color3.fromRGB(166,188,199)
    local bg = Color3.fromRGB(16,23,35)
    local panel = Color3.fromRGB(32,43,59)
    local accent = Color3.fromRGB(49,205,166)
    local warning = Color3.fromRGB(242,190,104)
    local function setStatus(message)
        shortMessage = tostring(message)
        if alive and statusText then statusText.Text = shortMessage end
    end
    screen = mk('ScreenGui', {
        Name='GB_V11_Lab', ResetOnSpawn=false, DisplayOrder=32000,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    }, pg)
    local ball = rounded(mk('TextButton',{
        Text='GB11',Font=Enum.Font.GothamBold,TextSize=13,
        TextColor3=bg,BackgroundColor3=accent,BorderSizePixel=0,
        Size=UDim2.fromOffset(52,52),Position=UDim2.new(0,8,.32,0)
    }, screen), 26)
    -- Main panel: user-controlled UI scale with mobile-safe bounds.
    local BASE_W, BASE_H = 406, 464
    local root = rounded(mk('Frame',{
        BackgroundColor3=bg,BorderSizePixel=0,Active=true,
        Position=UDim2.fromOffset(64,24),Size=UDim2.fromOffset(BASE_W,BASE_H)
    }, screen), 10)
    mk('UIStroke',{Color=accent,Thickness=1,Transparency=.25},root)
    local scale = mk('UIScale',{Scale=1},root)
    local scaleIndicator
    local function viewport()
        local camera = workspaceService.CurrentCamera
        return camera and camera.ViewportSize or Vector2.new(720,600)
    end
    local function allowedMaxScale()
        local v = viewport()
        return math.max(0.45,math.min(1.50,(v.X-12)/BASE_W,(v.Y-12)/BASE_H))
    end
    local function keepOnScreen()
        local v=viewport()
        local maxX=math.max(6,v.X-BASE_W*scale.Scale-6)
        local maxY=math.max(6,v.Y-BASE_H*scale.Scale-6)
        local x=math.clamp(root.Position.X.Offset,6,maxX)
        local y=math.clamp(root.Position.Y.Offset,6,maxY)
        root.Position=UDim2.fromOffset(math.floor(x+0.5),math.floor(y+0.5))
    end
    local function setMenuScale(nextScale, quiet)
        if not alive then return end
        local maximum=allowedMaxScale()
        local minimum=math.min(0.50,maximum)
        scale.Scale=math.floor(math.clamp(nextScale,minimum,maximum)*100+0.5)/100
        keepOnScreen()
        local pct=math.floor(scale.Scale*100+0.5)
        if scaleIndicator then scaleIndicator.Text=pct..'%' end
        if not quiet then env.GrowBloxMenuScale=scale.Scale end
        if not quiet then setStatus('Ukuran menu: '..pct..'%. Geser pojok kanan bawah untuk resize.') end
    end
    local function autoFitMenu(quiet)
        local v=viewport()
        local target=math.min(1,(v.X-86)/BASE_W,(v.Y-44)/BASE_H)
        setMenuScale(target,quiet)
    end
    local savedScale=tonumber(env.GrowBloxMenuScale)
    if savedScale then setMenuScale(savedScale,true) else autoFitMenu(true) end

    local head = rounded(mk('Frame',{
        BackgroundColor3=panel,BorderSizePixel=0,Active=true,
        Size=UDim2.new(1,0,0,42)
    },root),9)
    mk('TextLabel',{
        BackgroundTransparency=1,Text='GROWBLOX V11 | MENU',
        TextColor3=ink,Font=Enum.Font.GothamBold,TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,
        Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-199,1,0)
    },head)
    local smaller=rounded(mk('TextButton',{
        Text='-',Font=Enum.Font.GothamBold,TextSize=19,
        TextColor3=ink,BackgroundColor3=bg,BorderSizePixel=0,
        Position=UDim2.new(1,-181,0,7),Size=UDim2.fromOffset(28,28)
    },head),5)
    local bigger=rounded(mk('TextButton',{
        Text='+',Font=Enum.Font.GothamBold,TextSize=19,
        TextColor3=ink,BackgroundColor3=bg,BorderSizePixel=0,
        Position=UDim2.new(1,-148,0,7),Size=UDim2.fromOffset(28,28)
    },head),5)
    scaleIndicator=rounded(mk('TextButton',{
        Text='AUTO',Font=Enum.Font.GothamBold,TextSize=11,
        TextColor3=accent,BackgroundColor3=bg,BorderSizePixel=0,
        Position=UDim2.new(1,-115,0,7),Size=UDim2.fromOffset(45,28)
    },head),5)
    local mini=rounded(mk('TextButton',{
        Text='_',Font=Enum.Font.GothamBold,TextSize=15,
        TextColor3=ink,BackgroundColor3=bg,BorderSizePixel=0,
        Position=UDim2.new(1,-66,0,7),Size=UDim2.fromOffset(28,28)
    },head),5)
    local close=rounded(mk('TextButton',{
        Text='X',Font=Enum.Font.GothamBold,TextSize=14,
        TextColor3=ink,BackgroundColor3=Color3.fromRGB(155,61,74),
        BorderSizePixel=0,Position=UDim2.new(1,-33,0,7),Size=UDim2.fromOffset(28,28)
    },head),5)
    scaleIndicator.Text=math.floor(scale.Scale*100+0.5)..'%'
    conn(smaller.MouseButton1Click,function() setMenuScale(scale.Scale-.08) end)
    conn(bigger.MouseButton1Click,function() setMenuScale(scale.Scale+.08) end)
    conn(scaleIndicator.MouseButton1Click,function()
        autoFitMenu(false)
        setStatus('Ukuran otomatis sesuai layar HP. +/- untuk ubah ukuran.')
    end)
    local watchedCamera
    local function bindCamera()
        local camera=workspaceService.CurrentCamera
        if camera and camera~=watchedCamera then
            watchedCamera=camera
            conn(camera:GetPropertyChangedSignal('ViewportSize'),function()
                if not alive or workspaceService.CurrentCamera~=camera then return end
                setMenuScale(scale.Scale,true)
            end)
        end
        setMenuScale(scale.Scale,true)
    end
    conn(workspaceService:GetPropertyChangedSignal('CurrentCamera'),bindCamera)
    bindCamera()
    local tabBar=mk('Frame',{
        BackgroundTransparency=1,Position=UDim2.fromOffset(6,46),Size=UDim2.new(1,-12,0,36)
    },root)
    local tabs={}
    local pages={}
    local function makeTab(label,index)
        local button=rounded(mk('TextButton',{
            Text=label,Font=Enum.Font.GothamBold,TextSize=12,
            BackgroundColor3=panel,TextColor3=ink,BorderSizePixel=0,
            Position=UDim2.new((index-1)/3,3,0,0),
            Size=UDim2.new(1/3,-6,1,0)
        },tabBar),6)
        tabs[index]=button
    end
    makeTab('WORLD',1);makeTab('MOVEMENT',2);makeTab('REPORT',3)
    statusText=mk('TextLabel',{
        Text=shortMessage,TextColor3=accent,Font=Enum.Font.Code,
        TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
        BackgroundTransparency=1,TextSize=11,
        Position=UDim2.fromOffset(10,86),Size=UDim2.new(1,-20,0,38)
    },root)
    for i=1,3 do
        local pgview=rounded(mk('ScrollingFrame',{
            BackgroundColor3=panel,BorderSizePixel=0,
            Position=UDim2.fromOffset(8,128),Size=UDim2.new(1,-16,1,-137),
            ScrollBarThickness=3,CanvasSize=UDim2.fromOffset(0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=i==1
        },root),7)
        mk('UIPadding',{
            PaddingTop=UDim.new(0,9),PaddingLeft=UDim.new(0,9),
            PaddingRight=UDim.new(0,9),PaddingBottom=UDim.new(0,10)
        },pgview)
        mk('UIListLayout',{
            FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder,
            HorizontalAlignment=Enum.HorizontalAlignment.Center,Padding=UDim.new(0,8)
        },pgview)
        pages[i]=pgview
    end
    local function showTab(i)
        for j=1,3 do
            pages[j].Visible=j==i
            tabs[j].BackgroundColor3=j==i and Color3.fromRGB(41,120,107) or panel
        end
    end
    for i=1,3 do conn(tabs[i].MouseButton1Click,function() showTab(i) end) end
    local function line(parent,value,height,color)
        return mk('TextLabel',{
            Text=value,BackgroundTransparency=1,TextColor3=color or muted,
            Font=Enum.Font.Code,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,
            TextYAlignment=Enum.TextYAlignment.Center,TextWrapped=true,
            Size=UDim2.new(1,-5,0,height or 37)
        },parent)
    end
    local function btn(parent,label,callback)
        local button=rounded(mk('TextButton',{
            Text=label,TextWrapped=true,TextColor3=ink,
            Font=Enum.Font.GothamSemibold,TextSize=12,
            BackgroundColor3=Color3.fromRGB(49,66,84),BorderSizePixel=0,
            Size=UDim2.new(1,-5,0,38)
        },parent),6)
        conn(button.MouseButton1Click,function()
            if not alive then return end
            local ok,e=pcall(callback)
            if not ok then setStatus('ERROR: '..tostring(e):sub(1,125)) end
        end)
        return button
    end
    local function edit(parent,placeholder,initial)
        return rounded(mk('TextBox',{
            Text=initial or '',PlaceholderText=placeholder,ClearTextOnFocus=false,
            TextColor3=ink,PlaceholderColor3=muted,
            Font=Enum.Font.Code,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,
            BackgroundColor3=bg,BorderSizePixel=0,
            Size=UDim2.new(1,-5,0,39)
        },parent),6)
    end

    local function getCachedNet()
        local shared=RS:FindFirstChild('Shared')
        local mod=shared and shared:FindFirstChild('Net')
        if not mod or not mod:IsA('ModuleScript') then return nil,'Shared.Net hilang' end
        if type(getloadedmodules)~='function' then return nil,'Delta tidak menyediakan getloadedmodules' end
        local ok,loaded=pcall(getloadedmodules)
        if not ok or type(loaded)~='table' then return nil,'Tidak dapat membaca daftar loaded modules' end
        local found=false
        for _,item in ipairs(loaded) do
            if item==mod then found=true; break end
        end
        if not found then return nil,'Shared.Net belum dimuat klien' end
        local good,exports=pcall(require,mod)
        if not good or type(exports)~='table' then return nil,'Exports Shared.Net tidak dapat dibaca' end
        return exports,nil
    end
    local function scanOperations()
        local net,err=getCachedNet()
        for _,name in ipairs(opNames) do
            local info={status='ABSENT',note='Tidak ada export',call=nil,effect=false,attempts=0}
            local saved=opStates[name]
            if saved then
                info.attempts=saved.attempts or 0
                info.effect=saved.effect or false
            end
            if not net then
                info.status='UNKNOWN';info.note=err
            elseif type(net.CALLS)~='table' then
                info.status='UNKNOWN';info.note='CALLS tidak terbaca'
            else
                local call=rawget(net.CALLS,name)
                if type(call)=='table' and type(rawget(call,'send'))=='function' then
                    info.status='FOUND';info.call=rawget(call,'send')
                    info.note='send() tersedia; format argumen/izin server belum diketahui'
                    if saved and saved.status=='SENT' then info.status='SENT' end
                    if info.effect then info.status='CONFIRMED' end
                end
            end
            opStates[name]=info
        end
        return net~=nil,err
    end
    local function getOpState(name)
        return (opStates[name] and opStates[name].status) or 'NOT SCANNED'
    end
    local function refreshButtons()
        for _,name in ipairs(opNames) do
            local b=opButtons[name]
            if b then
                b.Text=(selected==name and '● ' or '○ ')..name..'   ['..getOpState(name)..']'
                b.BackgroundColor3=selected==name and Color3.fromRGB(41,120,107) or Color3.fromRGB(49,66,84)
            end
        end
        if opInfo then
            local state=opStates[selected]
            opInfo.Text='Pilihan: '..selected..' | '..getOpState(selected)..'\n'..(state and state.note or 'Tekan SCAN dahulu')
        end
        if inputBox then
            inputBox.Visible=selected~='CycleItem'
        end
        if authBox then authBox.Visible=selected=='ConvertLock' end
        if runButton then runButton.Text=prepared and 'KIRIM SEKALI (konfirmasi)' or 'SIAPKAN AKSI' end
    end

    -- WORLD actions: no sends occur during scans or reports.
    line(pages[1],'4 operasi biasa dari Shared.Net.CALLS. Tidak memakai admin remotes.',35,ink)
    btn(pages[1],'SCAN 4 OPERASI (READ ONLY)',function()
        local ok,err=scanOperations();refreshButtons()
        setStatus(ok and 'Scan selesai. Status FOUND bukan berarti berhasil.' or 'Scan belum berhasil: '..tostring(err))
    end)
    for _,name in ipairs(opNames) do
        opButtons[name]=btn(pages[1],name..' [NOT SCANNED]',function()
            selected=name;prepared=nil;preparedPayload=nil
            if inputBox then inputBox.Text='' end
            if authBox then authBox.Text='' end
            refreshButtons();setStatus(name..' dipilih. Scan, lalu masukkan argumen sesuai game.')
        end)
    end
    opInfo=line(pages[1],'Pilih operasi, lalu SCAN.',51,warning)
    line(pages[1],'Untuk BuyItem / DoorPass / ConvertLock, isi SATU argumen JSON yang sesuai API game. Contoh bentuk data (BELUM diverifikasi): {"id":123}',66)
    inputBox=edit(pages[1],'JSON argumen, misal {"id":123}','')
    authBox=edit(pages[1],'Ketik OWN untuk lock milikmu sendiri','')
    line(pages[1],'CycleItem diuji tanpa argumen. Membeli item mungkin memakai mata uang. DoorPass hanya pintu yang kamu berhak akses. ConvertLock hanya lock milikmu.',76)
    local function sendSelected()
        if busy then setStatus('Ada operasi yang masih berlangsung.');return end
        if game.PlaceId~=112863874972771 then
            setStatus('Ditolak: ini bukan PlaceId GrowBlox yang diketahui.');return
        end
        local state=opStates[selected]
        if not state or type(state.call)~='function' then
            setStatus('Operasi belum FOUND. Tekan SCAN dahulu.');return
        end
        local payload,raw='NO-ARGS',''
        if selected~='CycleItem' then
            raw=inputBox.Text or ''
            if #raw<2 or #raw>600 then setStatus('Isi JSON valid (2-600 karakter) dahulu.');return end
            local ok,decoded=pcall(function() return HttpService:JSONDecode(raw) end)
            if not ok or type(decoded)~='table' then
                setStatus('JSON harus berupa objek / array. Bukan string mentah.');return
            end
            payload=decoded
        end
        if selected=='ConvertLock' and authBox.Text~='OWN' then
            setStatus('ConvertLock hanya untuk lock milikmu: ketik OWN.');return
        end
        if os.clock()-lastCall<3 then setStatus('Jeda minimal 3 detik antar panggilan.');return end
        if prepared~=selected or preparedPayload~=raw then
            prepared=selected;preparedPayload=raw
            runButton.Text='KIRIM SEKALI (konfirmasi)'
            setStatus('Siap: '..selected..'. Tekan lagi untuk satu percobaan. Tidak ada retry otomatis.')
            return
        end
        prepared=nil;preparedPayload=nil;runButton.Text='SIAPKAN AKSI'
        busy=true;lastCall=os.clock()
        local method=state.call
        local ok,res
        if selected=='CycleItem' then
            ok,res=pcall(function() return method() end)
        else
            ok,res=pcall(function() return method(payload) end)
        end
        busy=false
        state.attempts=(state.attempts or 0)+1
        if ok then
            state.status='SENT';state.note='Fungsi selesai tanpa error; tidak ada bukti server menerima. Return type='..typeof(res)
            setStatus(selected..': client call OK. Cek efek nyata di game!')
        else
            state.status='ERROR';state.note=tostring(res):sub(1,140)
            setStatus(selected..': ERROR - '..state.note)
        end
        refreshButtons()
    end
    runButton=btn(pages[1],'SIAPKAN AKSI',sendSelected)
    btn(pages[1],'SAYA LIHAT EFEKNYA DI GAME',function()
        local state=opStates[selected]
        if state and (state.status=='SENT' or state.status=='CONFIRMED') then
            state.effect=true;state.status='CONFIRMED'
            state.note='Efek dikonfirmasi pengguna, bukan ACK server otomatis.'
            refreshButtons();setStatus(selected..': efek dikonfirmasi manual.')
        else
            setStatus('Kirim aksi dahulu sebelum menandai efek terkonfirmasi.')
        end
    end)
    line(pages[1],'CATATAN: nama fungsi tidak mengungkap schema. JSON yang salah bisa ditolak server. Tidak ada mode bypass izin, spam, brute force, atau panggilan admin.',74,warning)

    -- Movement diagnostics and native-character fallback. GrowBlox 2D usually has no Humanoid.
    line(pages[2],'GrowBlox memakai GUI 2D. Fly/No Clip nyata membutuhkan controller posisi & collision yang bisa diakses, bukan geser tile.',65,ink)
    local characterInfo=line(pages[2],'Belum scan movement.',88)
    local function charParts()
        local character=lp.Character
        if not character then return nil,nil,nil end
        return character,character:FindFirstChildOfClass('Humanoid'),character:FindFirstChild('HumanoidRootPart')
    end
    local function worldRefs()
        local gg=pg:FindFirstChild('GameGui')
        local w=gg and gg:FindFirstChild('World')
        local c=w and w:FindFirstChild('Camera')
        return w,c,c and c:FindFirstChild('Tiles'),c and c:FindFirstChild('PlayerView')
    end
    local function scanMove()
        local _,h,rootPart=charParts()
        local w,c,t,p=worldRefs()
        local wr=RS:FindFirstChild('WorldRemotes')
        local gg=pg:FindFirstChild('GameGui')
        local mobile=gg and gg:FindFirstChild('MobileControls')
        local moveTo=wr and wr:FindFirstChild('MoveTo')
        local setSpeed=wr and wr:FindFirstChild('SetWalkSpeed')
        characterInfo.Text=('2D: World=%s Camera=%s Tiles=%s PlayerView=%s\n3D: Humanoid=%s Root=%s\nMobileControls=%s | MoveTo=%s | SetWalkSpeed=%s (read-only)'):
            format(tostring(w~=nil),tostring(c~=nil),tostring(t~=nil),tostring(p~=nil),tostring(h~=nil),tostring(rootPart~=nil),tostring(mobile~=nil),tostring(moveTo~=nil),tostring(setSpeed~=nil))
        if h and rootPart then
            movementNote='Native 3D movement tersedia. Mode fallback dapat diuji, server mungkin menolak.'
        elseif t and p then
            movementNote='2D renderer FOUND, tapi movement/collision controller belum ditemukan. Fly/No Clip native unavailable.'
        else
            movementNote='Tidak menemukan controller karakter yang dapat digunakan.'
        end
        setStatus(movementNote)
    end
    btn(pages[2],'SCAN MOVE / COLLISION',scanMove)
    btn(pages[2],'WATCH TILES 4 DETIK (BERJALAN)',function()
        if busy then setStatus('Tes lain sedang berjalan.');return end
        local _,_,tiles=worldRefs()
        if not tiles or not tiles:IsA('GuiObject') then setStatus('Camera.Tiles tidak ditemukan.');return end
        busy=true
        setStatus('Jalankan karakter sekarang selama 4 detik...')
        task.spawn(function()
            local first=tiles.Position
            local minX,maxX,minY,maxY=first.X.Offset,first.X.Offset,first.Y.Offset,first.Y.Offset
            local endPosition=first
            for i=1,20 do
                if not alive or tiles.Parent==nil then break end
                task.wait(.2)
                endPosition=tiles.Position
                minX=math.min(minX,endPosition.X.Offset);maxX=math.max(maxX,endPosition.X.Offset)
                minY=math.min(minY,endPosition.Y.Offset);maxY=math.max(maxY,endPosition.Y.Offset)
            end
            busy=false
            movementNote=string.format('Tiles screen pixels: dX=%d dY=%d rangeX=%d rangeY=%d. Kamera/render saja.',
                endPosition.X.Offset-first.X.Offset,endPosition.Y.Offset-first.Y.Offset,maxX-minX,maxY-minY)
            setStatus(movementNote)
        end)
    end)
    local function disableNoClip()
        localFeatures.noclip=false
        for part,was in pairs(collisionOld) do
            if part and part.Parent then pcall(function() part.CanCollide=was end) end
        end
        collisionOld={}
    end
    local function toggleNoClip()
        if localFeatures.noclip then
            disableNoClip();setStatus('No Clip native OFF.');return
        end
        local character,h,r=charParts()
        if not character or not h or not r then
            setStatus('No Clip: UNSUPPORTED. GrowBlox 2D tidak memiliki Humanoid+Root.');return
        end
        localFeatures.noclip=true
        for _,obj in ipairs(character:GetDescendants()) do
            if obj:IsA('BasePart') and collisionOld[obj]==nil then collisionOld[obj]=obj.CanCollide end
        end
        setStatus('No Clip native ON (lokal saja, server bisa membatalkan).')
    end
    btn(pages[2],'NO CLIP: TOGGLE (NATIVE ONLY)',toggleNoClip)
    local function stopFly()
        localFeatures.fly=false;flyUp=false;flyDown=false
        if upButton then upButton.Visible=false end
        if downButton then downButton.Visible=false end
        local _,h,r=charParts()
        if r then pcall(function() r.AssemblyLinearVelocity=Vector3.zero end) end
        if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
    end
    local function toggleFly()
        if localFeatures.fly then stopFly();setStatus('Fly native OFF.');return end
        local _,h,r=charParts()
        if not h or not r then
            setStatus('Fly: UNSUPPORTED pada renderer GUI 2D GrowBlox. Butuh movement controller asli.');return
        end
        localFeatures.fly=true
        if upButton then upButton.Visible=true end
        if downButton then downButton.Visible=true end
        setStatus('Fly native ON. Joystick arah, tombol UP/DOWN. Server dapat membatalkan.')
    end
    btn(pages[2],'FLY: TOGGLE (NATIVE ONLY)',toggleFly)
    btn(pages[2],'SPEED 24: TOGGLE (NATIVE ONLY)',function()
        local _,h=charParts()
        if not h then setStatus('Speed: UNSUPPORTED. Humanoid tidak ditemukan.');return end
        if not localFeatures.speed then
            originalSpeed=h.WalkSpeed;h.WalkSpeed=24;localFeatures.speed=true
            setStatus('Speed lokal 24; cek apakah server menerima.')
        else
            h.WalkSpeed=originalSpeed or 16;localFeatures.speed=false
            setStatus('Speed dikembalikan.')
        end
    end)
    line(pages[2],'Fitur di atas TIDAK menebak packet MoveTo/SetWalkSpeed. Tidak ada RemoteEvent dikirim untuk gerakan.',55,warning)
    upButton=rounded(mk('TextButton',{
        Text='UP',TextColor3=ink,BackgroundColor3=Color3.fromRGB(41,120,107),
        Font=Enum.Font.GothamBold,TextSize=14,Visible=false,
        Size=UDim2.fromOffset(65,43),Position=UDim2.new(1,-77,.62,0)
    },screen),6)
    downButton=rounded(mk('TextButton',{
        Text='DOWN',TextColor3=ink,BackgroundColor3=Color3.fromRGB(41,120,107),
        Font=Enum.Font.GothamBold,TextSize=13,Visible=false,
        Size=UDim2.fromOffset(65,43),Position=UDim2.new(1,-77,.62,48)
    },screen),6)
    local function bindHold(button,isUp)
        conn(button.InputBegan,function(input)
            if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
                if isUp then flyUp=true else flyDown=true end
            end
        end)
        conn(button.InputEnded,function(input)
            if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
                if isUp then flyUp=false else flyDown=false end
            end
        end)
    end
    bindHold(upButton,true);bindHold(downButton,false)
    conn(RunService.Heartbeat,function()
        if not alive then return end
        if localFeatures.noclip then
            local character=lp.Character
            if character then
                for _,part in ipairs(character:GetDescendants()) do
                    if part:IsA('BasePart') then
                        if collisionOld[part]==nil then collisionOld[part]=part.CanCollide end
                        part.CanCollide=false
                    end
                end
            end
        end
        if localFeatures.fly then
            local _,humanoid,rootPart=charParts()
            if not humanoid or not rootPart then stopFly();return end
            local d=humanoid.MoveDirection
            local y=(flyUp and 1 or 0)-(flyDown and 1 or 0)
            pcall(function()
                humanoid:ChangeState(Enum.HumanoidStateType.Physics)
                rootPart.AssemblyLinearVelocity=Vector3.new(d.X*27,y*27,d.Z*27)
            end)
        end
    end)

    -- Display-only features: testable client changes, not world cheating.
    local function setFullbright(on)
        if on and not brightnessOld then
            brightnessOld={Brightness=Lighting.Brightness,ClockTime=Lighting.ClockTime,
                GlobalShadows=Lighting.GlobalShadows,Ambient=Lighting.Ambient}
        end
        if on then
            Lighting.Brightness=3;Lighting.ClockTime=14;Lighting.GlobalShadows=false
            Lighting.Ambient=Color3.fromRGB(180,180,180)
        elseif brightnessOld then
            for k,v in pairs(brightnessOld) do pcall(function() Lighting[k]=v end) end
            brightnessOld=nil
        end
        localFeatures.fullbright=on
    end
    local function setWeather(on)
        local world=worldRefs()
        if not world then return false end
        local found=0
        for _,name in ipairs({'WeatherFront','WeatherBack','WorldFxLayer'}) do
            local obj=world:FindFirstChild(name)
            if obj and obj:IsA('GuiObject') then
                if on then
                    if weatherOld[obj]==nil then weatherOld[obj]=obj.Visible end
                    obj.Visible=false
                elseif weatherOld[obj]~=nil then
                    obj.Visible=weatherOld[obj];weatherOld[obj]=nil
                end
                found=found+1
            end
        end
        localFeatures.hideWeather=on and found>0
        return found>0
    end
    btn(pages[2],'FULLBRIGHT (VISUAL) ON / OFF',function()
        setFullbright(not localFeatures.fullbright)
        setStatus('Fullbright LOCAL '..(localFeatures.fullbright and 'ON (terlihat jika lighting dipakai)' or 'OFF'))
    end)
    btn(pages[2],'HIDE WEATHER/FX (VISUAL) ON / OFF',function()
        local ok=setWeather(not localFeatures.hideWeather)
        setStatus(ok and ('Hide Weather/FX LOCAL '..(localFeatures.hideWeather and 'ON' or 'OFF')) or 'Weather GUI tidak ditemukan')
    end)

    -- Small report to avoid lag when sharing it.
    line(pages[3],'RESIZE: tombol - dan + di header, sentuh angka % untuk AUTO. Tarik sudut kanan bawah untuk ukuran bebas. Tombol _ menyembunyikan menu, GB11 membukanya.',67,accent)
    line(pages[3],'Laporan ringkas, tanpa JSON input, password, payload, atau log ratusan objek.',45,ink)
    outputText=line(pages[3],'Belum ada laporan.',275,ink)
    outputText.Size=UDim2.new(1,-5,0,0)
    outputText.AutomaticSize=Enum.AutomaticSize.Y
    local currentReport=''
    local function buildReport()
        local _,h,r=charParts()
        local _,c,t,p=worldRefs()
        local wr=RS:FindFirstChild('WorldRemotes')
        local toRemote=wr and wr:FindFirstChild('MoveTo')
        local speedRemote=wr and wr:FindFirstChild('SetWalkSpeed')
        local entries={
            '=== GROWBLOX V11 SHORT REPORT ===',
            'PlaceId='..tostring(game.PlaceId),
            'Net: '..tostring((function() local net=getCachedNet();return net~=nil end)()),
            'World: Camera='..tostring(c~=nil)..' Tiles='..tostring(t~=nil)..' PlayerView='..tostring(p~=nil),
            'Native movement: Humanoid='..tostring(h~=nil)..' Root='..tostring(r~=nil),
            'Movement remote names (NOT called): MoveTo='..tostring(toRemote~=nil)..' SetWalkSpeed='..tostring(speedRemote~=nil),
            'Movement: '..movementNote:sub(1,160),
            'Menu size: '..math.floor(scale.Scale*100+0.5)..'%',
            'V10 historical (user-reported): BuyItem=confirmed, CycleItem=sent, ConvertLock=sent, DoorPass=found.',
        }
        for _,name in ipairs(opNames) do
            local item=opStates[name]
            entries[#entries+1]=name..': '..getOpState(name)..' | tries='..tostring(item and item.attempts or 0)
                ..' | visible='..tostring(item and item.effect or false)
                ..' | '..(item and item.note or 'not scanned'):sub(1,90)
        end
        entries[#entries+1]='Visual: fullbright='..tostring(localFeatures.fullbright)..' weatherHidden='..tostring(localFeatures.hideWeather)
        entries[#entries+1]='SENT does not prove server accepted. CONFIRMED = user-observed only.'
        return table.concat(entries,'\n')
    end
    local function refreshReport()
        currentReport=buildReport()
        outputText.Text=currentReport
        setStatus('Report singkat siap ('..tostring(#currentReport)..' karakter).')
    end
    btn(pages[3],'REFRESH SHORT REPORT',refreshReport)
    btn(pages[3],'COPY SHORT REPORT',function()
        refreshReport()
        local clip=type(setclipboard)=='function' and setclipboard or (type(toclipboard)=='function' and toclipboard or nil)
        if not clip then setStatus('Clipboard Delta tidak tersedia.');return end
        local ok,e=pcall(clip,currentReport)
        setStatus(ok and 'Short report tersalin. Tempel di chat.' or ('Copy error: '..tostring(e)))
    end)
    line(pages[3],'FOUND = fungsi ada. SENT = tidak error lokal. CONFIRMED = kamu melihat efeknya. ERROR = pemanggilan gagal. UNKNOWN = tidak bisa dibaca.',70)

    -- Mobile drag, free resize (corner handle), minimize and open via GB11.
    local handle=rounded(mk('TextButton',{
        Name='ResizeHandle',Text='↘',TextColor3=accent,
        BackgroundColor3=Color3.fromRGB(35,55,70),BorderSizePixel=0,
        Font=Enum.Font.GothamBold,TextSize=17,Active=true,
        Position=UDim2.new(1,-31,1,-31),Size=UDim2.fromOffset(28,28),
        ZIndex=20
    },root),6)
    local dragging,initialTouch,initialPosition
    local sizing,startTouch,startScale
    local function isPrimary(input)
        return input.UserInputType==Enum.UserInputType.Touch
            or input.UserInputType==Enum.UserInputType.MouseButton1
    end
    conn(head.InputBegan,function(input)
        if not isPrimary(input) then return end
        -- The right side contains resize/minimize/close buttons; never drag from them.
        local controlStart=head.AbsolutePosition.X+head.AbsoluteSize.X-(183*scale.Scale)
        if input.Position.X>=controlStart then return end
        if sizing then return end
        dragging=input
        initialTouch=input.Position
        initialPosition=root.Position
    end)
    conn(handle.InputBegan,function(input)
        if not isPrimary(input) or dragging then return end
        sizing=input
        startTouch=input.Position
        startScale=scale.Scale
    end)
    conn(UIS.InputChanged,function(input)
        if dragging and (input==dragging or
           (dragging.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)) then
            local d=input.Position-initialTouch
            root.Position=UDim2.fromOffset(initialPosition.X.Offset+d.X,initialPosition.Y.Offset+d.Y)
            keepOnScreen()
        end
        if sizing and (input==sizing or
           (sizing.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)) then
            local d=input.Position-startTouch
            local changeX=d.X/BASE_W
            local changeY=d.Y/BASE_H
            -- Use the dominant drag axis, so resizing also works with a one-axis swipe.
            local change=math.abs(changeX)>=math.abs(changeY) and changeX or changeY
            setMenuScale(startScale+change,true)
        end
    end)
    conn(UIS.InputEnded,function(input)
        if dragging and (input==dragging or
            (dragging.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1)) then
            dragging=nil
        end
        if sizing and (input==sizing or
            (sizing.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1)) then
            sizing=nil
            env.GrowBloxMenuScale=scale.Scale
            setStatus('Ukuran menu disimpan selama GUI ini aktif: '..math.floor(scale.Scale*100+0.5)..'%.')
        end
    end)
    conn(ball.MouseButton1Click,function()
        root.Visible=not root.Visible
        if root.Visible then keepOnScreen() end
    end)
    conn(mini.MouseButton1Click,function() root.Visible=false end)
    local function cleanup()
        if not alive then return end
        alive=false
        stopFly();disableNoClip();setFullbright(false);setWeather(false)
        local _,hum=charParts()
        if hum and originalSpeed then pcall(function() hum.WalkSpeed=originalSpeed end) end
        for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        pcall(function() screen:Destroy() end)
    end
    env.GrowBloxV11={Close=cleanup}
    conn(close.MouseButton1Click,cleanup)
    scanOperations();refreshButtons();scanMove();showTab(1)
    if game.PlaceId~=112863874972771 then
        setStatus('PERINGATAN: PlaceId bukan GrowBlox. Pengiriman dinonaktifkan.')
    else
        setStatus('V11 READY. +/- untuk resize, tarik pojok ↘, atau tekan _ untuk sembunyikan.')
    end
end
local ok,err=pcall(start)
if not ok then warn('[GrowBlox V11] Startup error: '..tostring(err)) end
