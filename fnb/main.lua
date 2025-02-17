--local function import(s)
--    return loadstring(game:HttpGet( ("https://raw.githubusercontent.com/TheLocalFurry/luau/main/%s.lua"):format(s) ))()
--end

loadstring(game:HttpGet("https://raw.githubusercontent.com/TheLocalFurry/luau/main/fnb/hooks.lua"))()
local Connections = loadstring(game:HttpGet("https://raw.githubusercontent.com/TheLocalFurry/luau/main/fnb/Connections.lua"))()
local Util = loadstring(game:HttpGet("https://raw.githubusercontent.com/TheLocalFurry/luau/main/fnb/util.lua"))()
local UwUware = loadstring(game:HttpGet("https://raw.githubusercontent.com/TheLocalFurry/luau/main/fnb/uwuware.lua"))()

local Flags = UwUware.flags
local Chances = {
    Marvelous = 100,
    Sick = 0,
    Good = 0,
    Ok = 0,
    Bad = 0,
    Miss = 0
}
local Offsets = {
    Marvelous = 0,
    Sick = 0.032,
    Good = 0.06,
    Ok = 0.11,
    Bad = 0.155,
    Miss = 1
}

local VirtualInputManager = (getvirtualinputmanager or game.GetService)(game, "VirtualInputManager")
local InputService = game:GetService "UserInputService"
local HttpService = game:GetService "HttpService"
local RunService = game:GetService "RunService"
local Players = game:GetService "Players"

local Client = Players.LocalPlayer
local PlayerGui = Client.PlayerGui

local set_identity = (syn and syn.set_thread_identity or setidentity or setthreadcontext)
local random = (meth and meth or math).random
local ipairs = ipairs
local pairs = pairs
local type = type

local get_signal_function, Roll do 
    get_signal_function = function(Signal, Target)
        local callback
        
        set_identity(2)
        for index, connection in ipairs( getconnections(Signal) ) do
            if getfenv(connection.Function).script == Target then
                callback = connection.Function
                break
            end 
        end
        set_identity(7)
        return callback;
    end
    
    Roll = function()
        local a, b = 0, 0
        for Judgement, v in pairs(Chances) do
            a += v
        end
        if (a < 1) then return Offsets.Marvelous end
        
        a = random(a)
        for Judgement, v in pairs(Chances) do 
            b += v
            
            if (b > a) then
                return Offsets[Judgement]
            end
        end
        
        return 0
    end
end

local MAIN = Connections:Open("MAIN")
local TEMP = Connections:Open("TEMP")


local function onChildAdded(Object)
    if (not Object) then return end
    if (tostring(Object) ~= "FNFEngine") then return end
    
    Object = Object:WaitForChild("Engine")
    TEMP:Clear()
    
    local convert
    local spawn = task.spawn
    local delay = task.delay
    
    local Begin = Enum.UserInputState.Begin
    local End = Enum.UserInputState.End
    
    local GimmickNotes
    local Chart = {}
    local IncomingNotes = {}
    
    local Song, SongData, SongOffset, PBSpeed
    local Stage = Object.Stage.Value
    local Side = Object.PlayerSide.Value
    
    local TimePast = Object.Config.TimePast
    
    while (not Stage.Config.Song.Value) do
        TimePast.Changed:Wait()
    end

    while not require(Object.Modules.Functions).notetypeconvert do
        TimePast.Changed:Wait()
    end
    
    local function Find(...)
        local tostring = tostring 
        local table_find = table.find
        
        for i,v in ipairs(Song:GetDescendants()) do
            if table_find({...}, tostring(v)) then
                return v
            end
        end
        
        for i,v in ipairs(Song.Parent:GetDescendants()) do
            if table_find({...}, tostring(v))  then
                return v
            end
        end
    end

    local gc = getgc(true)
    local rawget = rawget

    for i = 1, #gc do local v = gc[i]
        if type(v) == "table" and rawget(v, "song") then
            SongData = v
            break
        end
    end
    
    PBSpeed = Object.Config.PlaybackSpeed.Value
    Song = Stage.Config.Song.Value
    SongOffset = Find("Offset")
    SongData = Object.Events.GetLibraryChart:InvokeServer()
    convert = require(Object.Modules.Functions).notetypeconvert
    
    local Offset = Client.Input.Offset.Value + SongOffset.Value
    local PoisonNotes = Find("MultipleGimmickNotes", "GimmickNotes", "MineNotes")
    
    for _, connection in ipairs(getconnections(Object.Events.UserInput.OnClientEvent)) do 
        connection:Disable()
    end
    
    
    for Index, Note in ipairs(Util.parse( SongData )) do
        local Note_1 = Note[1]
        local Key, _, HellNote = convert(Note_1[2], Note_1[4])
        Key = type(Key) == "string" and Key or "|"
        
        local function add()
            Chart[#Chart + 1] = {
                Length = Note[1][3],
                At = Note[1][1] / PBSpeed - Offset,
                Key = Key:split"_"[1]
            }
        end
        
        local function close()
            add = function() end
        end
        
        --
    
        local mustHit
        
        if (not Key or Key:find"|") then close() end
        if type(Note[2]) ~= "table" then close() else
            mustHit = Note[2].mustHitSection
        end
        
        local Arrow = PoisonNotes and PoisonNotes:FindFirstChild(Key:split"_"[2] or Key:split"_"[1])
        Arrow = Arrow and require(Arrow.ModuleScript)
        
        if (_) then mustHit = not mustHit end
        if (mustHit and "R" or "L") ~= Side then close() end
        if HellNote and (Arrow and Arrow.Type == "OnHit" or PoisonNotes and PoisonNotes.Value == "OnHit") then close() end
        
        add()
    end
    
    for i,v in ipairs(Chart) do
        IncomingNotes[v.Key] = (IncomingNotes[v.Key] or {})
        if v.At > TimePast.Value * 1000 then 
            IncomingNotes[v.Key][#IncomingNotes[v.Key] + 1] = { v.At - 22.5, tonumber(v.Length) and (v.Length / 1000) or 0 }
        end
    end
    
    local len = 0 
    for i,v in pairs(IncomingNotes) do len += 1 end
    
    local inputFunction = get_signal_function(InputService.InputBegan, Object.Client)
    
    for Key, chart in pairs(IncomingNotes) do
        local input = Util.getKeycode(Key, len)
        local index = 1
        
        local function Check()
            local Arrow = chart[index]
            
            if Arrow and (Arrow[1] <= TimePast.Value * 1000) then
                index = index + 1
                
                if (not Flags.IsAnimeFan) then return end
                local Offset = Roll()
                if (Offset == 1) then return end
                
                if (Flags.FireDirectly) then 
                    set_identity(2)   
                     
                    delay(Offset, inputFunction, { KeyCode = input, UserInputState = Begin })
                    delay(Arrow[2] + Offset, inputFunction, { KeyCode = input, UserInputState = End })
                else
                    set_identity(7)
                    
                    delay(Offset, VirtualInputManager.SendKeyEvent, VirtualInputManager, true, input, false, nil)
                    delay(Arrow[2] + Offset, VirtualInputManager.SendKeyEvent, VirtualInputManager, false, input, false, nil)
                end
                
                spawn(Check)
            end
        end
        
        TEMP:Insert(RunService.RenderStepped, Check)
    end
end

MAIN:Insert(PlayerGui.ChildAdded, onChildAdded)
spawn(onChildAdded, PlayerGui:FindFirstChild"FNFEngine")

local Window = UwUware:CreateWindow "Friday Night Bloxxin'" do
    local Configuration = Window:AddFolder("Config") do 
        Configuration:AddSlider { text = "% Marvelous", min = 0, max = 100, value = Chances.Marvelous, callback = function(v) Chances.Marvelous = v end }
        Configuration:AddSlider { text = "% Sick", min = 0, max = 100, value = Chances.Sick, callback = function(v) Chances.Sick = v end }
        Configuration:AddSlider { text = "% Good", min = 0, max = 100, value = Chances.Good, callback = function(v) Chances.Good = v end }
        Configuration:AddSlider { text = "% Ok", min = 0, max = 100, value = Chances.Ok, callback = function(v) Chances.Ok = v end }
        Configuration:AddSlider { text = "% Bad", min = 0, max = 100, value = Chances.Bad, callback = function(v) Chances.Bad = v end }
        Configuration:AddSlider { text = "% Miss", min = 0, max = 100, value = Chances.Miss, callback = function(v) Chances.Miss = v end }
    end 
    
    Window:AddToggle { text = "Toggle Autoplayer", flag = "IsAnimeFan", state = true }
    Window:AddToggle { text = "Fire Signals Directly", flag = "FireDirectly", state = true }
    Window:AddBind { text = "Close GUI", key = Enum.KeyCode.Quote, callback = function() UwUware:Close() end }
    Window:AddButton({
        text = "Unload Script",
        callback = function()
            set_identity(7)
            Connections:Destroy()
            UwUware.base:Destroy()
        end
    })

    Window:AddButton {
        text = "Copy Discord Invite",
        callback = function()
            local code = game:HttpGet "https://stavratum.github.io/invite"
            local invite = "discord.gg" .. "/" .. code
            
            setclipboard(invite)
        end
    }
    
    UwUware:Init()
end

--

if Client.Input.Keybinds.R4.Value == ";" then
    game:GetService("ReplicatedStorage").Events.RemoteEvent:FireServer("Input", "Semicolon", "R4")
end
