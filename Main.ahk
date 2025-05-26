; IGNITE FIRES Grow a Garden Macro [COSMETIC UPDATE]

#SingleInstance, Force
#NoEnv
SetWorkingDir %A_ScriptDir%
#WinActivateForce
SetMouseDelay, -1 
SetWinDelay, -1
SetControlDelay, -1
SetBatchLines, -1   

; globals

global webhookURL
global discordUserID
global PingSelected

global cycleCount := 0

global currentItem := ""

global currentHour
global currentMinute
global currentSecond

global msgBoxCooldown := 0

global gearseedAutoActive := 0
global eggAutoActive  := 0
global cosmeticAutoActive := 0

global actionQueue := []

settingsFile := A_ScriptDir "\settings.ini"

; unused

global selectedResolution

global scrollCounts_1080p, scrollCounts_1440p_100, scrollCounts_1440p_125
scrollCounts_1080p :=       [2, 4, 6, 8, 9, 11, 13, 14, 16, 18, 20, 21, 23, 25, 26, 28, 29, 31]
scrollCounts_1440p_100 :=   [3, 5, 8, 10, 13, 15, 17, 20, 22, 24, 27, 30, 31, 34, 36, 38, 40, 42]
scrollCounts_1440p_125 :=   [3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 25, 27, 29, 30, 31, 32]

global gearScroll_1080p, toolScroll_1440p_100, toolScroll_1440p_125
gearScroll_1080p     := [1, 2, 4, 6, 8, 9, 11, 13]
gearScroll_1440p_100 := [2, 3, 6, 8, 10, 13, 15, 17]
gearScroll_1440p_125 := [1, 3, 4, 6, 8, 9, 12, 12]

; webhook functions and donate link opener

SendDiscordMessage(webhookURL, message) {

    ; if (!checkValidWebhook(webhookURL)) {
    ;     return
    ; }

    FormatTime, messageTime, , hh:mm:ss tt
    fullMessage := "[" . messageTime . "] " . message

    json := "{""content"": """ . fullMessage . """}"
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")

    try {
        whr.Open("POST", webhookURL, false)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.Send(json)
        whr.WaitForResponse()
        status := whr.Status

        if (status != 200 && status != 204) {
            return
        }
    } catch {
        return
    }

}

checkValidWebhook(url, msg := 0) {

    global webhookURL
    global settingsFile

    isValid := 0
    
    if (url = "" || !InStr(url, "discord.com/api")) {
        isValid := 0
        if (msg) {
            MsgBox, 0, Message, Invalid Webhook
            IniRead, savedWebhook, %settingsFile%, Main, User Webhook,
            GuiControl,, webhookURL
        }
        return false
    }

    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", url, false)
        whr.Send()
        whr.WaitForResponse()
        status := whr.Status
        if (status = 200 || status = 204) {
            isValid = 1
        }
    } catch {
        isValid = 0
    }

    if (msg) {
        if (isValid && webhookURL != "") {
            IniWrite, %webhookURL%, %settingsFile%, Main, User Webhook
            MsgBox, 0, Message, Webhook Saved Successfully
        }
        else if (!isValid && webhookURL != "") {
            MsgBox, 0, Message, Invalid Webhook
            IniRead, savedWebhook, %settingsFile%, Main, User Webhook,
            GuiControl,, webhookURL, %savedWebhook%
        }
        else {
            return (isValid)
        }
    }

    return (isValid)

}

showPopupMessage(msgText := "nil", duration := 2000) {

    static popupID := 99

    ; get main GUI position and size
    WinGetPos, guiX, guiY, guiW, guiH, A

    innerX := 20
    innerY := 35
    innerW := 200
    innerH := 50
    winW := 200
    winH := 50
    x := guiX + (guiW - winW) // 2 - 40
    y := guiY + (guiH - winH) // 2

    if (!msgBoxCooldown) {
        msgBoxCooldown = 1
        Gui, %popupID%:Destroy
        Gui, %popupID%:+AlwaysOnTop -Caption +ToolWindow +Border
        Gui, %popupID%:Color, FFFFFF
        Gui, %popupID%:Font, s10 cBlack, Segoe UI
        Gui, %popupID%:Add, Text, x%innerX% y%innerY% w%innerW% h%innerH% BackgroundWhite Center cBlack, %msgText%
        Gui, %popupID%:Show, x%x% y%y% NoActivate
        SetTimer, HidePopupMessage, -%duration%
        Sleep, 2200
        msgBoxCooldown = 0
    }

}

DonateResponder(ctrlName) {


    if (ctrlName = "Donate100")
        Run, https://www.roblox.com/game-pass/918079841/100-Robux
    else if (ctrlName = "Donate500")
        Run, https://www.roblox.com/game-pass/918074808/500-Robux
    else if (ctrlName = "Donate1000")
        Run, https://www.roblox.com/game-pass/1011942964/1000-Robux
    else if (ctrlName = "Donate2500")
        Run, https://www.roblox.com/game-pass/1233576774/2500-Robux
    else if (ctrlName = "Donate10000")
        Run, https://www.roblox.com/game-pass/1012182735/10000-Robux
    else
        return

}

; mouse functions

SafeMoveRelative(xRatio, yRatio) {

    if WinExist("ahk_exe RobloxPlayerBeta.exe") {
        WinGetPos, winX, winY, winW, winH, ahk_exe RobloxPlayerBeta.exe
        moveX := winX + Round(xRatio * winW)
        moveY := winY + Round(yRatio * winH)
        MouseMove, %moveX%, %moveY%
    }

}

SafeClickRelative(xRatio, yRatio) {

    if WinExist("ahk_exe RobloxPlayerBeta.exe") {
        WinGetPos, winX, winY, winW, winH, ahk_exe RobloxPlayerBeta.exe
        clickX := winX + Round(xRatio * winW)
        clickY := winY + Round(yRatio * winH)
        Click, %clickX%, %clickY%
    }

}

getMouseCoord(axis) {

    CoordMode, Mouse, Screen
    MouseGetPos, x, y
    if (axis = "x")
        return x
    else if (axis = "y")
        return y
    else
        return ""  ; error

}


; directional sequence encoder/executor
; if you're going to modify the calls to this make sure you know what you're doing (ui navigation has some odd behaviours)

uiUniversal(order := 0, exitUi := 1, continuous := 0, spam := 0, spamCount := 30) {

    global FastMode

    If (!order) {
        return
    }

    if (!continuous) {
        Send, \
        Sleep, 50
    }   

    ; right = 1, left = 2, up = 3, down = 4, enter = 0, fastmodedelay = 5, delay = 6
    Loop, Parse, order 
    {
        if (A_LoopField = "1") {
            repeatKey("Right", 1)
        }
        else if (A_LoopField = "2") {
            repeatKey("Left", 1)
        }
        else if (A_LoopField = "3") {
            repeatKey("Up", 1)
        }        
        else if (A_LoopField = "4") {
            repeatKey("Down", 1)
        }  
        else if (A_LoopField = "0") {
            repeatKey("Enter", spam ? spamCount : 1, spam ? 10 : 0)
        }       
        else if (A_LoopField = "5") {
            Sleep, 100
        } 
        else if (A_LoopField = "6" && !FastMode) {
            Sleep, 50
        }     
    }

    if (exitUi) {
        Sleep, 50
        Send, \
    }

    return

}

repeatKey(key := "nil", count := 0, delay := 30) {

    if (key = "nil") {
        return
    }

    Loop, %count% {
        Send {%key%}
        Sleep, %delay%
    }

}

; color detectors

quickDetectEgg(buyColor, variation := 10, x1Ratio := 0.0, y1Ratio := 0.0, x2Ratio := 1.0, y2Ratio := 1.0) {

    global selectedEggItems
    global currentItem

    eggsCompleted := 0
    isSelected := 0

    eggColorMap := Object()
    eggColorMap["Common Egg"]    := "0xFFFFFF"
    eggColorMap["Uncommon Egg"]  := "0x81A7D3"
    eggColorMap["Rare Egg"]      := "0xBB5421"
    eggColorMap["Legendary Egg"] := "0x2D78A3"
    eggColorMap["Mythical Egg"]  := "0x00CCFF"
    eggColorMap["Bug Egg"]       := "0x86FFD5"

    Loop, 5 {
        for rarity, color in eggColorMap {
            currentItem := rarity
            isSelected := 0

            for i, selected in selectedEggItems {
                if (selected = rarity) {
                    isSelected := 1
                    break
                }
            }

            ; check for the egg on screen, if its selected it gets bought
            if (simpleDetect(color, variation, 0.41, 0.32, 0.54, 0.38)) {
                if (isSelected) {
                    quickDetect(buyColor, 0, 5, 0.4, 0.60, 0.65, 0.70, 0, 1)
                    eggsCompleted = 1
                    break
                } else {
                    if (simpleDetect(buyColor, variation, 0.40, 0.60, 0.65, 0.70)) {
                        ToolTip, % currentItem . "`nIn Stock, Not Selected"
                        SetTimer, HideTooltip, -1500
                        SendDiscordMessage(webhookURL, currentItem . " In Stock, Not Selected")
                    }
                    else {
                        ToolTip, % currentItem . "`nNot In Stock, Not Selected"
                        SetTimer, HideTooltip, -1500
                        SendDiscordMessage(webhookURL, currentItem . " Not In Stock, Not Selected")
                    }
                    uiUniversal(61616056, 1, 1)
                    eggsCompleted = 1
                    break
                }
            }    
        }
        ; failsafe
        if (eggsCompleted) {
            return
        }
        Sleep, 1500
    }

    ToolTip, Error In Detection
    SetTimer, HideTooltip, -1500
    if (PingSelected) {
        SendDiscordMessage(webhookURL, "Failed To Detect Any Egg [Error] <@" . discordUserID . ">")
    }
    else {
        SendDiscordMessage(webhookURL, "Failed To Detect Any Egg [Error]")
    }

}

simpleDetect(colorInBGR, variation, x1Ratio := 0.0, y1Ratio := 0.0, x2Ratio := 1.0, y2Ratio := 1.0) {

    CoordMode, Pixel, Screen
    CoordMode, Mouse, Screen

    ; limit search to specified area
	WinGetPos, winX, winY, winW, winH, ahk_exe RobloxPlayerBeta.exe

    x1 := winX + Round(x1Ratio * winW)
    y1 := winY + Round(y1Ratio * winH)
    x2 := winX + Round(x2Ratio * winW)
    y2 := winY + Round(y2Ratio * winH)

    PixelSearch, FoundX, FoundY, x1, y1, x2, y2, colorInBGR, variation, Fast
    if (ErrorLevel = 0) {
        return true
    }

}

quickDetect(color1, color2, variation := 10, x1Ratio := 0.0, y1Ratio := 0.0, x2Ratio := 1.0, y2Ratio := 1.0, item := 1, egg := 0) {

    CoordMode, Pixel, Screen
    CoordMode, Mouse, Screen

    stock := 0
    eggDetected := 0

    global currentItem
    
    ; change to whatever you want to be pinged for
    pingItems := ["Bamboo Seed", "Coconut Seed", "Cactus Seed", "Dragon Fruit Seed", "Mango Seed", "Grape Seed", "Mushroom Seed", "Pepper Seed"
                , "Cacao Seed", "Beanstalk Seed"
                , "Basic Sprinkler", "Advanced Sprinkler", "Godly Sprinkler", "Lightning Rod", "Master Sprinkler"
                , "Rare Egg", "Legendary Egg", "Mythical Egg", "Bug Egg"]

	ping := false

    if (PingSelected) {
        for i, pingitem in pingItems {
            if (pingitem = currentItem) {
                ping := true
                break
            }
        }
    }

    ; limit search to specified area
	WinGetPos, winX, winY, winW, winH, ahk_exe RobloxPlayerBeta.exe

    x1 := winX + Round(x1Ratio * winW)
    y1 := winY + Round(y1Ratio * winH)
    x2 := winX + Round(x2Ratio * winW)
    y2 := winY + Round(y2Ratio * winH)

    ; for seeds/gears checks if either color is there (buy button)
    if (item) {
        for index, color in [color1, color2] {
            PixelSearch, FoundX, FoundY, x1, y1, x2, y2, %color%, variation, Fast RGB
            if (ErrorLevel = 0) {
                stock := 1
                ToolTip, %currentItem% `nIn Stock
                SetTimer, HideTooltip, -1500 
                Sleep, 250
                if (ping)
                    SendDiscordMessage(webhookURL, "Bought " . currentItem . ". <@" . discordUserID . ">")
                else
                    SendDiscordMessage(webhookURL, "Bought " . currentItem . ".")
                uiUniversal(506, 0, 1, 1)
                Sleep, 50
            }
        }
    }

    ; for eggs
    if (egg) {
        PixelSearch, FoundX, FoundY, x1, y1, x2, y2, color1, variation, Fast RGB
        if (ErrorLevel = 0) {
            stock := 1
            ToolTip, %currentItem% `nIn Stock
            SetTimer, HideTooltip, -1500  
            uiUniversal(50606, 1, 1)
            Sleep, 50
            if (ping)
                SendDiscordMessage(webhookURL, "Bought " . currentItem . ". <@" . discordUserID . ">")
            else
                SendDiscordMessage(webhookURL, "Bought " . currentItem . ".")
        }
        if (!stock) {
            uiUniversal(61616056, 1, 1)
            SendDiscordMessage(webhookURL, currentItem . " Not In Stock.")  
        }
    }

    Sleep, 100

    if (!stock) {
        ToolTip, %currentItem% `nNot In Stock
        SetTimer, HideTooltip, -1500
        ; SendDiscordMessage(webhookURL, currentItem . " Not In Stock.")  
    }

}

; item arrays

seedItems := ["Carrot Seed", "Strawberry Seed", "Blueberry Seed", "Orange Tulip"
             , "Tomato Seed", "Corn Seed", "Daffodil Seed", "Watermelon Seed"
             , "Pumpkin Seed", "Apple Seed", "Bamboo Seed", "Coconut Seed"
             , "Cactus Seed", "Dragon Fruit Seed", "Mango Seed", "Grape Seed"
             , "Mushroom Seed", "Pepper Seed", "Cacao Seed", "Beanstalk Seed"] ;

gearItems := ["Watering Can", "Trowel", "Recall Wrench", "Basic Sprinkler", "Advanced Sprinkler"
             , "Godly Sprinkler", "Lightning Rod", "Master Sprinkler", "Favorite Tool", "Harvest Tool"]

eggItems := ["Common Egg", "Uncommon Egg", "Rare Egg", "Legendary Egg", "Mythical Egg"
             , "Bug Egg"]

moonItems   := ["Blood Moon Crate", "Night Egg", "Night Seed Pack", "Crimson Vine Seed"
               , "Moon Melon Seed", "Star Caller", "Blood Kiwi", "Blood Hedgehog"
               , "Blood Owl"]

TwilightItems   := ["Night Egg", "Night Seed Pack",  "Twilight Crate", "Star Caller"
               , "Moon Cat", "Celestiberry Seed", "Moon Mango Seed"]

cosmeticItems := ["Cosmetic 1", "Cosmetic 2", "Cosmetic 3", "Cosmetic 4", "Cosmetic 5"
             , "Cosmetic 6",  "Cosmetic 7", "Cosmetic 8", "Cosmetic 9"]

settingsFile := A_ScriptDir "\settings.ini"

started := 0

IniRead, FirstRun, %settingsFile%, Settings, FirstRun, 1
if (FirstRun)
    Gosub, ShowWelcome
else
    Gosub, ShowGui
return

ShowWelcome:
    Gui, 99: Destroy
    Gui, 99: +AlwaysOnTop -Resize +ToolWindow
    Gui, 99: Margin, 10, 10
    Gui, 99: Add, Picture, x10 y0 w768 h432, %A_ScriptDir%\Images\welcome.png
    Gui, 99: Add, Button, x240 y+10 w300 h40 gContinue, Continue
    Gui, 99: Show, w788 h492 Center, IGNITE FIRES Grow a Garden Macro [COSMETIC UPDATE]
return

Continue:
    Gui, 99: Destroy
IniWrite, 0, %settingsFile%, Settings, FirstRun
    Gosub, ShowGui
return

GetRobloxWindows(ByRef idArray) {
    WinGet, rawCount, List, ahk_exe RobloxPlayerBeta.exe
    Loop, % rawCount {
        idArray.Push(rawCount%A_Index%) 
    }
}



UseAltsCheck:
    Gui, Submit, NoHide
    if (UseAlts) {
        warningText =
        (
Only use this feature if you've got alts and know what you are doing!
        )
        MsgBox, 48, BE CAREFUL!!, %warningText%
    }
    Gosub, UpdateSettingColor
    Gosub, SaveSettings
return



Gosub, ShowGui

; main ui

ShowGui:

    Gui, Destroy
    Gui, +Resize +MinimizeBox +SysMenu
    Gui, Margin, 10, 10
    Gui, Color, 0x202020
    Gui, Font, s9 cWhite, Segoe UI
    Gui, Add, Tab, x10 y10 w500 h400 vMyTab, Seeds|Gears|Eggs|Twilight|Cosmetics|Settings|Donate|Credits

    Gui, Tab, 1
    Gui, Font, s9 cWhite Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 c90EE90, Seed Shop Items
    IniRead, SelectAllSeeds, %settingsFile%, Seed, SelectAllSeeds, 0
    Gui, Add, Checkbox, % "x50 y90 vSelectAllSeeds gHandleSelectAll c90EE90 " . (SelectAllSeeds ? "Checked" : ""), Select All Seeds
    Loop, % seedItems.Length() {
        IniRead, sVal, %settingsFile%, Seed, Item%A_Index%, 0
        if (A_Index > 18) {
            col := 350
            idx := A_Index - 19
            yBase := 125
        }
        else if (A_Index > 9) {
            col := 200
            idx := A_Index - 10
            yBase := 125
        }
        else {
            col := 50
            idx := A_Index
            yBase := 100
        }
        y := yBase + (idx * 25)
        Gui, Add, Checkbox, % "x" col " y" y " vSeedItem" A_Index " gHandleSelectAll cWhite " . (sVal ? "Checked" : ""), % seedItems[A_Index]
    }

    Gui, Tab, 2
    Gui, Font, s9 cWhite Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 c87CEEB, Gear Shop Items
    IniRead, SelectAllGears, %settingsFile%, Gear, SelectAllGears, 0
    Gui, Add, Checkbox, % "x50 y90 vSelectAllGears gHandleSelectAll c87CEEB " . (SelectAllGears ? "Checked" : ""), Select All Gears
    Loop, % gearItems.Length() {
        IniRead, gVal, %settingsFile%, Gear, Item%A_Index%, 0
        if (A_Index > 9) {
            col := 200
            idx := A_Index - 10
            yBase := 125
        }
        else {
            col := 50
            idx := A_Index
            yBase := 100
        }
        y := yBase + (idx * 25)
        Gui, Add, Checkbox, % "x" col " y" y " vGearItem" A_Index " gHandleSelectAll cWhite " . (gVal ? "Checked" : ""), % gearItems[A_Index]
    }

    Gui, Tab, 3
    Gui, Font, s9 cWhite Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 cFFB875, Egg Shop
    IniRead, SelectAllEggs, %settingsFile%, Egg, SelectAllEggs, 0
    Gui, Add, Checkbox, % "x50 y90 vSelectAllEggs gHandleSelectAll cFFB875 " . (SelectAllEggs ? "Checked" : ""), Select All Eggs
    Loop, % eggItems.Length() {
        IniRead, eVal, %settingsFile%, Egg, Item%A_Index%, 0
        y := 125 + (A_Index - 1) * 25
        Gui, Add, Checkbox, % "x50 y" y " vEggItem" A_Index " gHandleSelectAll cWhite " . (eVal ? "Checked" : ""), % eggItems[A_Index]
    }


    Gui, Tab, 4
    Gui, Add, GroupBox, x23 y50 w475 h340 c895070, Twilight Shop Items
    IniRead, SelectAllTwilightItems, %settingsFile%, Twilight, SelectAllTwilightItems, 0
    Gui, Add, Checkbox, % "x50 y90 vSelectAllTwilightItems gHandleSelectAll c895070 " . (SelectAllTwilightItems ? "Checked" : ""), Select All Twilight Shop Items
    Loop, % twilightItems.Length() {
        IniRead, gVal, %settingsFile%, Twilight, Item%A_Index%, 0
        if (A_Index > 9) {
            col := 200
            idx := A_Index - 10
            yBase := 125
        }
        else {
            col := 50
            idx := A_Index
            yBase := 100
        }
        y := yBase + (idx * 25)
        Gui, Add, Checkbox, % "x" col " y" y " vTwilightItem" A_Index " gHandleSelectAll cWhite " . (gVal ? "Checked" : ""), % twilightItems[A_Index]
    }


    Gui, Tab, 5
    Gui, Font, s9 cWhite Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 cD41551, Cosmetic Shop
    IniRead, BuyAllCosmetics, %settingsFile%, Cosmetic, BuyAllCosmetics, 0
    Gui, Add, Checkbox, % "x50 y90 vBuyAllCosmetics cD41551 " . (BuyAllCosmetics ? "Checked" : ""), Buy All Cosmetics

    Gui, Tab, 6
    Gui, Font, s9 cWhite Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 cD3D3D3, Settings


    IniRead, PingSelected, %settingsFile%, Main, PingSelected, 0
    pingColor := PingSelected ? "c90EE90" : "cD3D3D3"
    Gui, Add, Checkbox, % "x50 y150 vPingSelected gUpdateSettingColor " . pingColor . (PingSelected ? " Checked" : ""), Discord Item Pings
    
    IniRead, AutoAlign, %settingsFile%, Main, AutoAlign, 0
    autoColor := AutoAlign ? "c90EE90" : "cD3D3D3"
    Gui, Add, Checkbox, % "x50 y175 vAutoAlign gUpdateSettingColor " . autoColor . (AutoAlign ? " Checked" : ""), Auto-Align

    IniRead, FastMode, %settingsFile%, Main, FastMode, 0
    fastColor := FastMode ? "c90EE90" : "cD3D3D3"
    Gui, Add, Checkbox, % "x50 y200 vFastMode gUpdateSettingColor " . fastColor . (FastMode ? " Checked" : ""), Fast Mode

    IniRead, UseAlts, %settingsFile%, Main, UseAlts, 0
    AltsColor := UseAlts ? "c90EE90" : "cD3D3D3"
    Gui, Add, Checkbox, % "x50 y225 vUseAlts gUseAltsCheck " . AltsColor . (UseAlts ? " Checked" : ""), Use Alts

    Gui, Font, s9 cD3D3D3, Segoe UI
    Gui, Add, Text, x50 y90, Webhook URL:
    Gui, Font, s8 cBlack, Segoe UI
    IniRead, savedWebhook, %settingsFile%, Main, User Webhook
    if (savedWebhook = "ERROR") {
        savedWebhook := ""
    }
    Gui, Add, Edit, x140 y90 w250 h18 vwebhookURL +BackgroundFFFFFF, %savedWebhook%
    Gui, Font, s8 cWhite, Segoe UI
    Gui, Add, Button, x400 y90 w85 h18 gDisplayWebhookValidity Background202020, Save Webhook

    Gui, Font, s9 cD3D3D3, Segoe UI
    Gui, Add, Text, x50 y115, Discord User ID:
    Gui, Font, s8 cBlack, Segoe UI
    IniRead, savedUserID, %settingsFile%, Main, Discord UserID
    if (savedUserID = "ERROR") {
        savedUserID := ""
    }
    Gui, Add, Edit, x140 y115 w250 h18 vdiscordUserID +BackgroundFFFFFF, %savedUserID%
    Gui, Font, s8 cWhite, Segoe UI
    Gui, Add, Button, x400 y115 w85 h18 gUpdateUserID Background202020, Save UserID

    Gui, Add, Button, x400 y140 w85 h18 gClearSaves Background202020, Clear Saves

    Gui, Font, s10 cWhite Bold, Segoe UI
    Gui, Add, Button, x50 y335 w150 h40 gStartScan Background202020, Start Macro (F5)
    Gui, Add, Button, x320 y335 w150 h40 gQuit Background202020, Stop Macro (F7)

       Gui, Tab, 7
    Gui, Font, s9 cWhite Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 cD7A9E3, Donate

    Gui, Font, s8 cD7A9E3 Bold, Segoe UI
    Gui, Add, Button, x37  y80 w80 h25 gDonate vDonate100  BackgroundF0F0F0,  100 Robux
    Gui, Add, Button, x127 y80 w80 h25 gDonate vDonate500  BackgroundF0F0F0,  500 Robux
    Gui, Add, Button, x217 y80 w80 h25 gDonate vDonate1000 BackgroundF0F0F0, 1000 Robux
    Gui, Add, Button, x307 y80 w80 h25 gDonate vDonate2500 BackgroundF0F0F0, 2500 Robux
    Gui, Add, Button, x397 y80 w80 h25 gDonate vDonate10000 BackgroundF0F0F0,10000 Robux

    Gui, Add, Text, x60 y120 w400 +Center, Top Donators:

    Gui, Font, s9 cWhite, Segoe UI
    ; Row 1
    Gui, Add, Picture, x80  y140 w24 h24, %A_ScriptDir%\Images\avatars\KeoniHater666.png
    Gui, Add, Text,    x110 y150 w200 h24, KeoniHater666
    Gui, Add, Text,    x350 y150 w100 h24 +Right, 2000
    ; Row 2
    Gui, Add, Picture, x80  y170 w24 h24, %A_ScriptDir%\Images\avatars\peanut1268a.png
    Gui, Add, Text,    x110 y180 w200 h24, peanut1268a
    Gui, Add, Text,    x350 y180 w100 h24 +Right, 1100
    ; Row 3
    Gui, Add, Picture, x80  y200 w24 h24, %A_ScriptDir%\Images\avatars\BarlosWithaB.png
    Gui, Add, Text,    x110 y210 w200 h24, BarlosWithaB
    Gui, Add, Text,    x350 y210 w100 h24 +Right, 1000
    ; Row 4
    Gui, Add, Picture, x80  y230 w24 h24, %A_ScriptDir%\Images\avatars\KanniiCom.png
    Gui, Add, Text,    x110 y240 w200 h24, KanniiCom
    Gui, Add, Text,    x350 y240 w100 h24 +Right, 500
    ; Row 5
    Gui, Add, Picture, x80  y260 w24 h24, %A_ScriptDir%\Images\avatars\Whatdidhesayyyy_bruh.png
    Gui, Add, Text,    x110 y270 w200 h24, Whatdidhesayyyy_bruh
    Gui, Add, Text,    x350 y270 w100 h24 +Right, 500
    ; Row 6
    Gui, Add, Picture, x80  y290 w24 h24, %A_ScriptDir%\Images\avatars\Jake_XvY.png
    Gui, Add, Text,    x110 y300 w200 h24, Jake_XvY
    Gui, Add, Text,    x350 y300 w100 h24 +Right, 200
    ; Row 7
    Gui, Add, Picture, x80  y320 w24 h24, %A_ScriptDir%\Images\avatars\Not_Ausstinn.png
    Gui, Add, Text,    x110 y330 w200 h24, Not_Ausstinn
    Gui, Add, Text,    x350 y330 w100 h24 +Right, 100
    ; Row 8
    Gui, Add, Picture, x80  y350 w24 h24, %A_ScriptDir%\Images\avatars\ballidriptip.png
    Gui, Add, Text,    x110 y360 w200 h24, ballidriptip
    Gui, Add, Text,    x350 y360 w100 h24 +Right, 100

    Gui, Tab, 8
    ; Match other tabs: full-size group box
    Gui, Font, s9 cWhite, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 cD3D3D3, Credits

    Gui, Add, Picture, x40 y70 w48 h48, % mainDir "Images\\IgniteFires.png"
    Gui, Font, s10 cWhite Bold, Segoe UI
    Gui, Add, Text, x100 y70 w200 h24, Ignite Fires
    Gui, Font, s8 cFFC0CB Italic, Segoe UI
    Gui, Add, Text, x100 y96 w200 h16, Macro Creator
    Gui, Font, s8 cWhite, Segoe UI
    Gui, Add, Text, x40 y130 w200 h40, This started as a small project that turned into a side quest...

    Gui, Add, Picture, x240 y70 w48 h48, % mainDir "Images\\Real.png"
    Gui, Font, s10 cWhite Bold, Segoe UI
    Gui, Add, Text, x300 y70 w180 h24, Sima
    Gui, Font, s8 cWhite, Segoe UI
    Gui, Add, Text, x300 y96 w180 h40, Greatly helped to modify the macro to make it better and more consistent.

    Gui, Font, s9 cWhite Bold, Segoe UI
    Gui, Add, Text, x40 y200 w200 h20, Extra Resources:
    Gui, Font, s8 cD3D3D3 Underline, Segoe UI
    Gui, Add, Link, x40 y224 w300 h16, Join the <a href="https://discord.gg/tVET6AjqPv">Discord Server</a>!
    Gui, Add, Link, x40 y264 w300 h16, Subscribe my <a href="https://www.youtube.com/@ignitefiress">channel</a> on Youtube!
  





    Gui, Show, w520 h425, IGNITE FIRES Grow a Garden Macro [COSMETIC UPDATE]

Return

; ui handlers

DisplayWebhookValidity:
    
    Gui, Submit, NoHide

    checkValidWebhook(webhookURL, 1)

Return

UpdateUserID:

    Gui, Submit, NoHide

    if (discordUserID != "") {
        IniWrite, %discordUserID%, %settingsFile%, Main, Discord UserID
        MsgBox, 0, Message, Discord UserID Saved
    }

Return

ClearSaves:

    IniWrite, %A_Space%, %settingsFile%, Main, User Webhook
    IniWrite, %A_Space%, %settingsFile%, Main, Discord UserID

    IniRead, savedWebhook, %settingsFile%, Main, User Webhook
    IniRead, savedUserID, %settingsFile%, Main, Discord UserID

    GuiControl,, webhookURL, %savedWebhook% 
    GuiControl,, discordUserID, %savedUserID% 

    MsgBox, 0, Message, Webhook and User Id Cleared

Return

UpdateResolution:

    Gui, Submit, NoHide

    IniWrite, %selectedResolution%, %settingsFile%, Main, Resolution

return

HandleSelectAll:

    Gui, Submit, NoHide

    if (SubStr(A_GuiControl, 1, 9) = "SelectAll") {
        group := SubStr(A_GuiControl, 10)  ; seeds, eggs, gears
        controlVar := A_GuiControl
        Loop {
            item := group . "Item" . A_Index
            if (!IsSet(%item%))
                break
            GuiControl,, %item%, % %controlVar%
        }
    }
    else if (RegExMatch(A_GuiControl, "^(Seed|Egg|Gear|Twilight)Item\d+$", m)) {
        group := m1  ; seed, egg, gear
        if (!%A_GuiControl%)
            GuiControl,, SelectAll%group%s, 0
    }

    if (A_GuiControl = "SelectAllSeeds") {
        Loop, % seedItems.Length()
            GuiControl,, SeedItem%A_Index%, % SelectAllSeeds
            Gosub, SaveSettings
    }
    else if (A_GuiControl = "SelectAllEggs") {
        Loop, % eggItems.Length()
            GuiControl,, EggItem%A_Index%, % SelectAllEggs
            Gosub, SaveSettings
    }
    else if (A_GuiControl = "SelectAllGears") {
        Loop, % gearItems.Length()
            GuiControl,, GearItem%A_Index%, % SelectAllGears
            Gosub, SaveSettings
    }
else if (A_GuiControl = "SelectAllTwilightItems") {
    Loop, % twilightItems.Length()
        GuiControl,, TwilightItem%A_Index%, % SelectAllTwilightItems
    Gosub, SaveSettings
}


return

UpdateSettingColor:
    Gui, Submit, NoHide

    ;— existing three controls —
    autoColor := "+c" . (AutoAlign     ? "90EE90" : "D3D3D3")
    GuiControl, %autoColor%,     AutoAlign
    GuiControl, +Redraw,         AutoAlign

    fastColor := "+c" . (FastMode      ? "90EE90" : "D3D3D3")
    GuiControl, %fastColor%,     FastMode
    GuiControl, +Redraw,         FastMode

    pingColor := "+c" . (PingSelected  ? "90EE90" : "D3D3D3")
    GuiControl, %pingColor%,     PingSelected
    GuiControl, +Redraw,         PingSelected

    altsColor := "+c" . (UseAlts      ? "90EE90" : "cD3D3D3")
    GuiControl, %altsColor%,     UseAlts
    GuiControl, +Redraw,         UseAlts
return


Donate:

    DonateResponder(A_GuiControl)
    
Return

HideTooltip:

    ToolTip

return

HidePopupMessage:

    Gui, 99:Destroy

Return

GetScrollCountRes(index, mode := "seed") {

    global scrollCounts_1080p, scrollCounts_1440p_100, scrollCounts_1440p_125
    global gearScroll_1080p, gearScroll_1440p_100, gearScroll_1440p_125

    if (mode = "seed") {
        arr1 := scrollCounts_1080p
        arr2 := scrollCounts_1440p_100
        arr3 := scrollCounts_1440p_125
    } else if (mode = "gear") {
        arr1 := gearScroll_1080p
        arr2 := gearScroll_1440p_100
        arr3 := gearScroll_1440p_125
    }

    arr := (selectedResolution = 1) ? arr1
        : (selectedResolution = 2) ? arr2
        : (selectedResolution = 3) ? arr3
        : []

    loopCount := arr.HasKey(index) ? arr[index] : 0

    return loopCount
}

; item selection

UpdateSelectedItems:
    Gui, Submit, NoHide
    selectedSeedItems := []
    Loop, % seedItems.Length() {
        if (SeedItem%A_Index%)
            selectedSeedItems.Push(seedItems[A_Index])
    }
    selectedGearItems := []
    Loop, % gearItems.Length() {
        if (GearItem%A_Index%)
            selectedGearItems.Push(gearItems[A_Index])
    }
    selectedEggItems := []
    Loop, % eggItems.Length() {
        if (eggItem%A_Index%)
            selectedEggItems.Push(eggItems[A_Index])
    }
    selectedTwilightItems := []
    Loop, % twilightItems.Length()
        if (TwilightItem%A_Index%)
            selectedTwilightItems.Push(twilightItems[A_Index])
Return

GetSelectedItems() {
    result := ""
    if (selectedSeedItems.Length()) {
        result .= "Seed Items:`n"
        for _, name in selectedSeedItems
            result .= "  - " name "`n"
    }
    if (selectedGearItems.Length()) {
        result .= "Gear Items:`n"
        for _, name in selectedGearItems
            result .= "  - " name "`n"
    }
    if (selectedEggItems.Length()) {
        result .= "Egg Items:`n"
        for _, name in selectedEggItems
            result .= "  - " name "`n"
    }
    if (selectedTwilightItems.Length()) {
        result .= "Twilight Items:`n"
        for _, name in selectedTwilightItems
            result .= "  - " name "`n"
    }
    return result
}

; macro starting

StartScan:
    
    Gui, Submit, NoHide

if (UseAlts) {
    global windowIDs
    windowIDs := []
    GetRobloxWindows(windowIDs)
}

    global lastGearSeedMinute := -1
    global lastEggShopMinute := -1
    global lastCosmeticShopMinute := -1
    global lastCosmeticShopHour   := -1 
    global lastTwilightMinute  := -1

    currentSection := "StartScan"
    started := 1

    SendDiscordMessage(webhookURL, "Macro started.")

    spamBuffer := 0

    Gui, Submit, NoHide
    
    Gosub, UpdateSelectedItems
    itemsText := GetSelectedItems()

    ToolTip, Starting macro
    SetTimer, HideTooltip, -1500

    Sleep, 500


       if (UseAlts) {
    for index, winID in windowIDs {
        WinActivate, ahk_id %winID%
        WinWaitActive, ahk_id %winID%,, 2
    if (AutoAlign) {
        GoSub, cameraChange
        Sleep, 100
        Gosub, zoomAlignment
        Sleep, 100
        GoSub, cameraAlignment
        Sleep, 100
        Gosub, characterAlignment
        Sleep, 100
        Gosub, cameraChange
    }
    else {
        Gosub, zoomAlignment
    }
    }
    }
    else {
    if (AutoAlign) {
        GoSub, cameraChange
        Sleep, 100
        Gosub, zoomAlignment
        Sleep, 100
        GoSub, cameraAlignment
        Sleep, 100
        Gosub, characterAlignment
        Sleep, 100
        Gosub, cameraChange
    }
    else {
        Gosub, zoomAlignment
    }
    } 



    Sleep, 500

        SetTimer, UpdateTime, 1000

        actionQueue.Push("BuyGearSeed")
        gearseedAutoActive := 1
        SetTimer, AutoBuyGearSeed, 1000 ; checks every second if it should queue

        actionQueue.Push("BuyEggShop")
        eggAutoActive := 1
        SetTimer, AutoBuyEggShop, 1000 ; checks every second if it should queue

        actionQueue.Push("BuyCosmeticShop")
        cosmeticAutoActive := 1
        SetTimer, AutoBuyCosmeticShop, 1000 ; checks every second if it should queue

        twilightAutoActive := 1
        SetTimer, AutoBuyTwilightShop, 1000


    while (started) {
        if ( actionQueue.Length() ) {
            ToolTip  
            next := actionQueue.RemoveAt(1)
            Gosub, % next
	        spamBuffer := 0
            Sleep, 500
        } else {
            ToolTip, Waiting For Next Cycle
            if (!spamBuffer) {
                cycleCount++
                SendDiscordMessage(webhookURL, "[**CYCLE " . cycleCount . " COMPLETED**]")
                spamBuffer := 1
   	        }
            Sleep, 500
        }
    }

Return

; action queues

UpdateTime:

    FormatTime, currentHour,, hh
    FormatTime, currentMinute,, mm
    FormatTime, currentSecond,, ss

    currentHour := currentHour + 0
    currentMinute := currentMinute + 0
    currentSecond := currentSecond + 0

Return

AutoBuyGearSeed:

    ; queues if its not the first cycle and the time is a multiple of 5
    if (cycleCount > 0 && Mod(currentMinute, 5) = 0 && currentMinute != lastGearSeedMinute) {
        lastGearSeedMinute := currentMinute
        SetTimer, PushBuyGearSeed, -10000
    }

Return



PushBuyGearSeed: 

    actionQueue.Push("BuyGearSeed")

Return

BuyGearSeed:

    currentSection := "BuyGearSeed"


if (selectedSeedItems.Length()) {
       if (UseAlts) {
    for index, winID in windowIDs {
        WinActivate, ahk_id %winID%
        WinWaitActive, ahk_id %winID%,, 2
        Gosub, SeedShopPath
    }
    }
    else {
        Gosub, SeedShopPath
    } 
} 

if (selectedGearItems.Length()) {
       if (UseAlts) {
    for index, winID in windowIDs {
        WinActivate, ahk_id %winID%
        WinWaitActive, ahk_id %winID%,, 2
        Gosub, GearShopPath
    }
    }
    else {
        Gosub, GearShopPath
    } 
} 


Return



AutoBuyTwilightShop:

    if (cycleCount>0 && Mod(currentMinute,60)=0 && currentMinute!=lastTwilightMinute) {
        lastTwilightMinute := currentMinute
        SetTimer, PushBuyTwilightShop, -10000
    }

Return

PushBuyTwilightShop:
    actionQueue.Push("BuyTwilightShop")
Return

BuyTwilightShop:
    currentSection := "BuyTwilightShop"

if (selectedTwilightItems.Length()) {
       if (UseAlts) {
    for index, winID in windowIDs {
        WinActivate, ahk_id %winID%
        WinWaitActive, ahk_id %winID%,, 2
        Gosub, TwilightShopPath
    }
    }
    else {
        Gosub, TwilightShopPath
    } 
} 

Return

AutoBuyEggShop:

    if (cycleCount > 0 && Mod(currentMinute, 30) = 0 && currentMinute != lastEggShopMinute) {
        lastEggShopMinute := currentMinute
        SetTimer, PushBuyEggShop, -10000
    }

Return


PushBuyEggShop: 

    actionQueue.Push("BuyEggShop")

Return

BuyEggShop:

    currentSection := "BuyEggShop"


if (selectedEggItems.Length()) {
       if (UseAlts) {
    for index, winID in windowIDs {
        WinActivate, ahk_id %winID%
        WinWaitActive, ahk_id %winID%,, 2
        Gosub, EggShopPath
    }
    }
    else {
        Gosub, EggShopPath
    } 
} 

Return


AutoBuyCosmeticShop:
    ; every 4 hours, on the hour (00 minute), but only once per hour
    if ( cycleCount > 0
      && currentMinute = 0
      && Mod(currentHour, 4) = 0
      && currentHour != lastCosmeticShopHour )
    {
        lastCosmeticShopHour := currentHour
        SetTimer, PushBuyCosmeticShop, -10000
    }
Return



PushBuyCosmeticShop: 

    actionQueue.Push("BuyCosmeticShop")

Return

BuyCosmeticShop:

    currentSection := "BuyCosmeticShop"
    if (BuyAllCosmetics) {
        Gosub, CosmeticShopPath
    } 

Return

; alignment labels

cameraChange:

    ; changes camera mode to follow and can be called again to reverse it (0123, 0->3, 3->0)
    Send, {Escape}
    Sleep, 500
    Send, {Tab}
    Sleep, 400
    Send {Down}
    Sleep, 100
    repeatKey("Right", 2)
    Sleep, 100
    Send {Escape}

Return

cameraAlignment:

    ; puts character in overhead view
    Click, Right, Down
    Sleep, 200
    SafeMoveRelative(0.5, 0.5)
    Sleep, 200
    MouseMove, 0, 800, [, 1, 1] 
    Sleep, 200
    Click, Right, Up

Return

zoomAlignment:

    ; sets correct player zoom
    SafeMoveRelative(0.5, 0.5)
    Sleep, 100

    Loop, 40 {
        Send, {WheelUp}
        Sleep, 20
    }

    Sleep, 200

    Loop, 6 {
        Send, {WheelDown}
        Sleep, 20
    }

Return

characterAlignment:

    ; aligns character through spam tping and using the follow camera mode
    Send, \
    Sleep, 10
    repeatKey("Right", 3)
    Loop, 8 {
    Send, {Enter}
    Sleep, 10
    repeatKey("Right", 2)
    Sleep, 10
    Send, {Enter}
    Sleep, 10
    repeatKey("Left", 2)
    }
    Sleep, 10
    Send, \

    ToolTip, Alignment complete
    SetTimer, HideTooltip, -2500

Return

; buying paths

EggShopPath:

    WinActivate, ahk_exe RobloxPlayerBeta.exe
    Sleep, 100
    uiUniversal("61616161606")
    Sleep, 100
    Send {2}
    Sleep, % fastmode ? 100 : 1000
    SafeClickRelative(0.5, 0.5)
    SendDiscordMessage(webhookURL, "**[EGG CYCLE]**")
    Sleep, 800
    ; egg 1 sequence
    Send, {w Down}
    Sleep, 1800
    Send {w Up}
    Sleep, % fastmode ? 500 : 1000
    Send {e}
    Sleep, 100
    uiUniversal("61616161646", 0, 0)
    Sleep, 100
    quickDetectEgg(0x26EE26, 15, 0.41, 0.65, 0.52, 0.70)
    Sleep, 800
    ; egg 2 sequence
    Send, {w down}
    Sleep, 200
    Send, {w up}
    Sleep, % fastmode ? 100 : 1000
    Send {e}
    Sleep, 100
    uiUniversal("61616161646", 0, 0)
    Sleep, 100
    quickDetectEgg(0x26EE26, 15, 0.41, 0.65, 0.52, 0.70)
    Sleep, 800
    ; egg 3 sequence
    Send, {w down}
    Sleep, 200
    Send, {w up}
    Sleep, % fastmode ? 100 : 1000
    Send, {e}
    Sleep, 200
    uiUniversal("61616161646", 0, 0)
    Sleep, 100
    quickDetectEgg(0x26EE26, 15, 0.41, 0.65, 0.52, 0.70)
    Sleep, 300
    uiUniversal("61616161606")
    Sleep, 100
    SendDiscordMessage(webhookURL, "**[EGGS COMPLETED]**")

Return

SeedShopPath:

    seedsCompleted := 0

    WinActivate, ahk_exe RobloxPlayerBeta.exe
    Sleep, 100
    uiUniversal("616161616062606")
    Sleep, % fastmode ? 100 : 1000
    Send {e}
    SendDiscordMessage(webhookURL, "**[SEED CYCLE]**")
    Sleep, % fastmode ? 2500 : 5000
    ; checks for the shop opening up to 5 times to ensure it doesn't fail
    Loop, 5 {
        if (simpleDetect(0x00CCFF, 10, 0.54, 0.20, 0.65, 0.325)) {
            ToolTip, Seed Shop Opened
            SetTimer, HideTooltip, -1500
            ; SendDiscordMessage(webhookURL, "Seed Shop Open Detected [Try #" . A_Index . "] <@" . discordUserID . ">")
            SendDiscordMessage(webhookURL, "Seed Shop Opened.")
            Sleep, 200
            uiUniversal("636363616164646363636361616464606056", 0)
            Sleep, 100
            for index, item in selectedSeedItems {
                currentItem := selectedSeedItems[A_Index]
                ;SendDiscordMessage(webhookURL, "Checking For " . currentItem . " Stock.")
                label := StrReplace(item, " ", "")
                Gosub, %label%
                Sleep, 100
            }
            SendDiscordMessage(webhookURL, "Seed Shop Closed.")
            seedsCompleted = 1
        }
        if (seedsCompleted) {
            break
        }
        Sleep, 2000
    }   

    if (seedsCompleted) {
        Sleep, 500
        uiUniversal("646363606362606", 1, 1)
    }
    else {
        if (PingSelected) {
            SendDiscordMessage(webhookURL, "Failed To Detect Seed Shop Opening [Error] <@" . discordUserID . ">")
        }
        else {
            SendDiscordMessage(webhookURL, "Failed To Detect Seed Shop Opening [Error]")
        }
        ; failsafe
        uiUniversal("63636362626263616161616363636262626361616161606564616056")
    }

    SendDiscordMessage(webhookURL, "**[SEEDS COMPLETED]**")

Return

GearShopPath:

    gearsCompleted := 0

    WinActivate, ahk_exe RobloxPlayerBeta.exe
    Sleep, 100
    uiUniversal("61616161606")
    Sleep, % fastmode ? 100 : 500
    Send {2}
    Sleep, % fastmode ? 100 : 500
    SafeClickRelative(0.5, 0.5)
    Sleep, % fastmode ? 1200 : 2500
    Send {e}
    Sleep, % fastmode ? 1500 : 5000
    uiUniversal("616161616164606")
    SendDiscordMessage(webhookURL, "**[GEAR CYCLE]**")
    Sleep, % fastmode ? 2500 : 5000
    ; checks for the shop opening up to 5 times to ensure it doesn't fail
    Loop, 5 {
        if (simpleDetect(0x00CCFF, 10, 0.54, 0.20, 0.65, 0.325)) {
            ToolTip, Gear Shop Opened
            SetTimer, HideTooltip, -1500
            ; SendDiscordMessage(webhookURL, "Gear Shop Open Detected [Try #" . A_Index . "] <@" . discordUserID . ">")
            SendDiscordMessage(webhookURL, "Gear Shop Opened.")
            Sleep, 200
            uiUniversal("636363616164646363636361616464606056", 0)
            Sleep, 100
            for index, item in selectedGearItems {
                label := StrReplace(item, " ", "")
                currentItem := selectedGearItems[A_Index]
                ; SendDiscordMessage(webhookURL, "Checking For " . currentItem . " Stock.")
                Gosub, %label%
                Sleep, 100
            }
            SendDiscordMessage(webhookURL, "Gear Shop Closed.")
            gearsCompleted = 1
        }
        if (gearsCompleted) {
            break
        }
        Sleep, 2000
    }

    if (gearsCompleted) {
        Sleep, 500
        uiUniversal("646363606362606", 1, 1)
    }
    else {
        if (PingSelected) {
            SendDiscordMessage(webhookURL, "Failed To Detect Gear Shop Opening [Error] <@" . discordUserID . ">")
        }
        else {
           SendDiscordMessage(webhookURL, "Failed To Detect Gear Shop Opening [Error]") 
        }
        ; failsafe
        uiUniversal("63636362626263616161616363636262626361616161606564616056")
    }

    SendDiscordMessage(webhookURL, "**[GEARS COMPLETED]**")

Return

CosmeticShopPath:


    cosmeticsCompleted := 0

    WinActivate, ahk_exe RobloxPlayerBeta.exe
    Sleep, 100
    uiUniversal("61616161606")
    Sleep, % fastmode ? 100 : 500
    Send {2}
    Sleep, % fastmode ? 100 : 500
    SafeClickRelative(0.5, 0.5)
    Sleep, % fastmode ? 800 : 1000
    Send, {w Down}
    Sleep, 900
    Send {w Up}
    Sleep, % fastmode ? 100 : 1000
    Send {e}
    Sleep, % fastmode ? 2500 : 5000
    SendDiscordMessage(webhookURL, "**[COSMETIC CYCLE]**")
    ; checks for the shop opening up to 5 times to ensure it doesn't fail
    Loop, 5 {
        if (simpleDetect(0x00CCFF, 10, 0.61, 0.182, 0.764, 0.259)) {
            ToolTip, Cosmetic Shop Opened
            SetTimer, HideTooltip, -1500
            ; SendDiscordMessage(webhookURL, "Cosmetic Shop Open Detected [Try #" . A_Index . "] <@" . discordUserID . ">")
            SendDiscordMessage(webhookURL, "Cosmetic Shop Opened.")
            Sleep, 200
            for index, item in cosmeticItems {
                label := StrReplace(item, " ", "")
                currentItem := cosmeticItems[A_Index]
                Gosub, %label%
                if (PingSelected) {
                    SendDiscordMessage(webhookURL, "Bought " . currentItem . ". <@" . discordUserID . ">")  
                }
                else {
                    SendDiscordMessage(webhookURL, "Bought " . currentItem . ".")
                }
                Sleep, 100
            }
            SendDiscordMessage(webhookURL, "Cosmetic Shop Closed.")
            cosmeticsCompleted = 1
        }
        if (cosmeticsCompleted) {
            break
        }
        Sleep, 2000
    }

    if (cosmeticsCompleted) {
        Sleep, 500
        uiUniversal("6161616161646165606362606")
    }
    else {
        if (PingSelected) {
            SendDiscordMessage(webhookURL, "Failed To Detect Cosmetic Shop Opening [Error] <@" . discordUserID . ">")
        }
        else {
           SendDiscordMessage(webhookURL, "Failed To Detect Cosmetic Shop Opening [Error]") 
        }
        ; failsafe
        uiUniversal("61616161646161616365606")
        Sleep, 50
        uiUniversal("11110")
    }

    SendDiscordMessage(webhookURL, "**[COSMETICS COMPLETED]**")

Return



TwilightShopPath:

    twilightCompleted := 0

    WinActivate, ahk_exe RobloxPlayerBeta.exe
    Sleep, 100
    uiUniversal("616161616062606")
    Sleep, % fastmode ? 200 : 1000
    Send, {d down}
    Sleep, 6000
    Send, {d up}
    Sleep, % fastmode ? 100 : 1000
    Send, {w down}
    Sleep, 800
    Send, {w up}
    Sleep, % fastmode ? 100 : 1000
    Send, {d down}
    Sleep, 3000
    Send, {d up}
    Sleep, % fastmode ? 100 : 1000
    Send {e}
    SendDiscordMessage(webhookURL, "**[TWILIGHT CYCLE]**")
    Sleep, % fastmode ? 2500 : 5000
    ; checks for the shop opening up to 5 times to ensure it doesn't fail
    Loop, 5 {
        if (simpleDetect(0xAF8E5D, 10, 0.54, 0.20, 0.65, 0.325)) {
            ToolTip, Twilight Shop Opened
            SetTimer, HideTooltip, -1500
            ; SendDiscordMessage(webhookURL, "Twilight Shop Open Detected [Try #" . A_Index . "] <@" . discordUserID . ">")
            SendDiscordMessage(webhookURL, "Twilight Shop Opened.")
            Sleep, 200
            uiUniversal("636363636161646463636363616164606056", 0)
            Sleep, 100
            for index, item in selectedTwilightItems {
                currentItem := selectedTwilightItems[A_Index]
                ;SendDiscordMessage(webhookURL, "Checking For " . currentItem . " Stock.")
                label := StrReplace(item, " ", "")
                Gosub, %label%
                Sleep, 100
            }
            SendDiscordMessage(webhookURL, "Twilight Shop Closed.")
            twilightCompleted = 1
        }
        if (twilightCompleted) {
            break
        }
        Sleep, 2000
    }   

    if (twilightCompleted) {
        Sleep, 500
        uiUniversal("646363606362606", 1, 1)
    }
    else {
        if (PingSelected) {
            SendDiscordMessage(webhookURL, "Failed To Detect Twilight Shop Opening [Error] <@" . discordUserID . ">")
        }
        else {
            SendDiscordMessage(webhookURL, "Failed To Detect Twilight Shop Opening [Error]")
        }
        ; failsafe
        uiUniversal("63636362626263616161616363636262626361616161606561646056")
    }

    SendDiscordMessage(webhookURL, "**[TWILIGHT COMPLETED]**")

Return





; item labels (seeds-20, gears-10, cosmetics-9)

; seeds
CarrotSeed:
    Sleep, 50
    uiUniversal("0646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("3606", 0, 1)
    Sleep, 50
Return

StrawberrySeed:
    Sleep, 50
    uiUniversal("460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("360636", 0, 1)
    Sleep, 50
return

BlueberrySeed:
    Sleep, 50
    uiUniversal("46460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("36063636", 0, 1)
    Sleep, 50
return

OrangeTulip:
    Sleep, 50
    uiUniversal("4646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("3606363636", 0, 1)
    Sleep, 50
return

TomatoSeed:
    Sleep, 50
    uiUniversal("464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("360636363636", 0, 1)
    Sleep, 50
return

CornSeed:
    Sleep, 50
    uiUniversal("46464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("36063636363636", 0, 1)
    Sleep, 50
return

DaffodilSeed:
    Sleep, 50
    uiUniversal("4646464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("3606363636363636", 0, 1)
    Sleep, 50
return

WatermelonSeed:
    Sleep, 50
    uiUniversal("464646464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("360636363636363636", 0, 1)
    Sleep, 50
return

PumpkinSeed:
    Sleep, 50
    uiUniversal("4646464646464646064", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("36063636363636363636", 0, 1)
    Sleep, 50
return

AppleSeed:
    Sleep, 50
    uiUniversal("4646464646464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("3606363636363636363636", 0, 1)
    Sleep, 50
return

BambooSeed:
    Sleep, 50
    uiUniversal("464646464646464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("360636363636363636363636", 0, 1)
    Sleep, 50
return

CoconutSeed:
    Sleep, 50
    uiUniversal("46464646464646464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("36063636363636363636363636", 0, 1)
    Sleep, 50
return

CactusSeed:
    Sleep, 50
    uiUniversal("4646464646464646464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("3606363636363636363636363636", 0, 1)
    Sleep, 50
return

DragonFruitSeed:
    Sleep, 50
    uiUniversal("46464646464646464646464646064", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("360636363636363636363636363636", 0, 1)
    Sleep, 50
return

MangoSeed:
    Sleep, 50
    uiUniversal("46464646464646464646464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("36063636363636363636363636363636", 0, 1)
    Sleep, 50
return

GrapeSeed:
    Sleep, 50
    uiUniversal("4646464646464646464646464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("3606363636363636363636363636363636", 0, 1)
    Sleep, 50
return

MushroomSeed:
    Sleep, 50
    uiUniversal("464646464646464646464646464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("360636363636363636363636363636363636", 0, 1)
    Sleep, 50
return

PepperSeed:
    Sleep, 50
    uiUniversal("46464646464646464646464646464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("36063636363636363636363636363636363636", 0, 1)
    Sleep, 50
return

CacaoSeed:
    Sleep, 50
    uiUniversal("4646464646464646464646464646464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("3606363636363636363636363636363636363636", 0, 1)
    Sleep, 50
return

BeanstalkSeed:
    Sleep, 50
    uiUniversal("464646464646464646464646464646464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("360636363636363636363636363636363636363636", 0, 1)
    Sleep, 50
return

; gears
WateringCan:
    Sleep, 50
    uiUniversal("0646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("3606", 0, 1)
    Sleep, 50
Return

Trowel:
    Sleep, 50
    uiUniversal("460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("360636", 0, 1)
    Sleep, 50
return

RecallWrench:
    Sleep, 50
    uiUniversal("46460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("36063636", 0, 1)
    Sleep, 50
return

BasicSprinkler:
    Sleep, 50
    uiUniversal("4646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("3606363636", 0, 1)
    Sleep, 50
return

AdvancedSprinkler:
    Sleep, 50
    uiUniversal("464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("360636363636", 0, 1)
    Sleep, 50
return

GodlySprinkler:
    Sleep, 50
    uiUniversal("46464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("36063636363636", 0, 1)
    Sleep, 50
return

LightningRod:
    Sleep, 50
    uiUniversal("4646464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("3606363636363636", 0, 1)
    Sleep, 50
return

MasterSprinkler:
    Sleep, 50
    uiUniversal("464646464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("360636363636363636", 0, 1)
    Sleep, 50
return

FavoriteTool:
    Sleep, 50
    uiUniversal("46464646464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("36063636363636363636", 0, 1)
    Sleep, 50
return

HarvestTool:
    Sleep, 50
    uiUniversal("4646464646464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("3606363636363636363636", 0, 1)
    Sleep, 50
return

;cosmetics
Cosmetic1:

    Sleep, 50
    Loop, 5 {
        uiUniversal("161616161646465606")
        Sleep, % fastmode ? 50 : 200
    }

Return

Cosmetic2:

    Sleep, 50
    Loop, 5 {
        uiUniversal("1616161616464626265606")
        Sleep, % fastmode ? 50 : 200
    }

Return

Cosmetic3:

    Sleep, 50
    Loop, 5 {
        uiUniversal("16161616164646262626265606")
        Sleep, % fastmode ? 50 : 200
    }

Return

Cosmetic4:

    Sleep, 50
    Loop, 5 {
        uiUniversal("1616161616464626262626465606")
        Sleep, % fastmode ? 50 : 200
    }

Return

Cosmetic5:

    Sleep, 50
    Loop, 5 {
        uiUniversal("161616161646462626262646165606")
        Sleep, % fastmode ? 50 : 200
    }

Return

Cosmetic6:

    Sleep, 50
    Loop, 5 {
        uiUniversal("16161616164646262626264616165606")
        Sleep, % fastmode ? 50 : 200
    }

Return

Cosmetic7:

    Sleep, 50
    Loop, 5 {
        uiUniversal("1616161616464626262626461616165606")
        Sleep, % fastmode ? 50 : 200
    }

Return

Cosmetic8:

    Sleep, 50
    Loop, 5 {
        uiUniversal("161616161646462626262646161616165606")
        Sleep, % fastmode ? 50 : 200
    }

Return

Cosmetic9:

    Sleep, 50
    Loop, 5 {
        uiUniversal("16161616164646262626264616161616165606")
        Sleep, % fastmode ? 50 : 200
    }

Return

;twilight
NightEgg:
    Sleep, 50
    uiUniversal("0646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("3606", 0, 1)
    Sleep, 50
Return

NightSeedPack:
    Sleep, 50
    uiUniversal("460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("360636", 0, 1)
    Sleep, 50
return

TwilightCrate:
    Sleep, 50
    uiUniversal("46460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("36063636", 0, 1)
    Sleep, 50
return

StarCaller:
    Sleep, 50
    uiUniversal("4646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("3606363636", 0, 1)
    Sleep, 50
return

MoonCat:
    Sleep, 50
    uiUniversal("464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("360636363636", 0, 1)
    Sleep, 50
return

CelestiberrySeed:
    Sleep, 50
    uiUniversal("46464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("36063636363636", 0, 1)
    Sleep, 50
return

MoonMangoSeed:
    Sleep, 50
    uiUniversal("4646464646460646", 0, 1)
    Sleep, 50
    quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8208)
    Sleep, 50
    uiUniversal("3606363636363636", 0, 1)
    Sleep, 50
return


; save settings and start/exit

SaveSettings:

    Gui, Submit, NoHide

    ; — now write them out —
    Loop, % eggItems.Length()
        IniWrite, % (eggItem%A_Index% ? 1 : 0), %settingsFile%, Egg, Item%A_Index%

    Loop, % gearItems.Length()
        IniWrite, % (GearItem%A_Index% ? 1 : 0), %settingsFile%, Gear, Item%A_Index%

    Loop, % seedItems.Length()
        IniWrite, % (SeedItem%A_Index% ? 1 : 0), %settingsFile%, Seed, Item%A_Index%

Loop, % twilightItems.Length()
    IniWrite, % (TwilightItem%A_Index% ? 1 : 0), %settingsFile%, Twilight, Item%A_Index%


    IniWrite, %AutoAlign%, %settingsFile%, Main, AutoAlign
    IniWrite, %FirstRun%, %settingsFile%, Main, FirstRun
    IniWrite, %FastMode%, %settingsFile%, Main, FastMode
    IniWrite, %UseAlts%, %settingsFile%, Main, UseAlts
    IniWrite, %PingSelected%, %settingsFile%, Main, PingSelected
    IniWrite, %BuyAllCosmetics%, %settingsFile%, Cosmetic, BuyAllCosmetics
    IniWrite, %SelectAllEggs%, %settingsFile%, Egg, SelectAllEggs
    IniWrite, %SelectAllSeeds%, %settingsFile%, Seed, SelectAllSeeds
    IniWrite, %SelectAllGears%, %settingsFile%, Gear, SelectAllGears
    IniWrite, % SelectAllTwilightItems, %settingsFile%, Twilight, SelectAllTwilightItems

Return

StopMacro(terminate := 1) {

    Gui, Submit, NoHide
    Sleep, 50
    started := 0
    Gosub, SaveSettings
    Gui, Destroy
    if (terminate)
        ExitApp

}

PauseMacro(terminate := 1) {

    Gui, Submit, NoHide
    Sleep, 50
    started := 0
    Gosub, SaveSettings

}

; pressing x on window closes macro 
GuiClose:

    GuiEscape:
    StopMacro(1)

return

; pressing f7 button reloads
Quit:

    PauseMacro(1)
    SendDiscordMessage(webhookURL, "Macro reloaded.")
    Reload ; ahk built in reload

return

; f7 reloads
F7::

    PauseMacro(1)
    SendDiscordMessage(webhookURL, "Macro reloaded.")
    Reload ; ahk built in reload

return

; f5 starts scan
F5::Gosub, StartScan



#MaxThreadsPerHotkey, 2
