; mpress
;
; egory.ahk
; Author: szapp
; http://github.com/szapp/egory
; GNU General Public License v3.0
;
#SingleInstance, ignore ; Only one instance allowed
#NoEnv ; Do not need environment variables
EnvGet, ProgFiles, ProgramFiles(x86)
If !ProgFiles
	EnvGet, ProgFiles, ProgramFiles
EnvGet, UsrProfile, UserProfile
If !UsrProfile
		UsrProfile := A_MyDocuments
SetTitleMatchMode 2 ; Needed?
SetKeyDelay, 0
SetBatchLines -1 ; More priority
CoordMode, Mouse, Screen ; Mouse position; see MouseGetPosFix()

Menu, Tray, Icon
Menu, Tray, Icon, %A_ScriptFullPath%
Menu, Tray, NoStandard
Menu, Tray, Add, Exit, Exi
Menu, Tray, NoDefault

; Ini files
FileCreateDir, %A_AppData%\egory
inifile := A_AppData "\egory\config.ini"
ctgryfile := A_AppData "\egory\tags.ini"
log := A_AppData "\egory\log.cfg"
FileAppend, , %inifile%
FileAppend, , %ctgryfile% ; Make sure tag list file exists
FileAppend, , %log% ; Make sure tag list file exists
IniRead, fileExtExcl, %inifile%, config, fileExtExcl, 0
fileExtExcl := fileExtExcl ? fileExtExcl : "sfk,sfk0,sfk1,sfk2,sfk3,sfk4,sfk5,db,ini,jpeg,jpg,png,gif,tiff,txt"
IniWrite, %fileExtExcl%, %inifile%, config, fileExtExcl

filelist := ""
If (%0% = "-setup")
	setupGUI = 1 ; Set to 1 first, later it is increased to 2
Else {
	Loop, %0% { ; Retrieve input parameters
		If FileExist(%A_Index%)
			If !Instr("," fileExtExcl, "," SubStr(%A_Index%, InStr(%A_Index%, ".", , 0)+1))
			OR InStr(FileExist(%A_Index%), "D")
				filelist .= %A_Index% "|"
	}
	Sort, filelist, U D| \ ; Sort filelist
	If filelist
		filelist := RTrim("""" StrReplace(filelist, "|", """ """), """")
}

OnMessage(0x0200, "WM_MOUSEMOVE") ; Window messages
OnMessage(0x0201, "WM_LBUTTONDOWN")
OnMessage(0x0202, "WM_BUTTONUP")
OnMessage(0x0204, "WM_RBUTTONDOWN")
OnMessage(0x0205, "WM_BUTTONUP")

;##################################################################################***
;##################################################################################***
;  LOAD / CHECK CONFIGURATION VARIABLES
;##################################################################################***
;##################################################################################***


; Remaining (most) ini config extractions and corrections
IniRead, guiTGX, %inifile%, windowpos, guiTGX, 0
IniRead, guiTGY, %inifile%, windowpos, guiTGY, 0
IniRead, guiPX, %inifile%, windowpos, guiPX, 0
IniRead, guiPY, %inifile%, windowpos, guiPY, 0
IniRead, vlcPvwX, %inifile%, windowpos, vlcPvwX, 0
IniRead, vlcPvwY, %inifile%, windowpos, vlcPvwY, 0
IniRead, vlcPvwW, %inifile%, windowpos, vlcPvwW, 0
IniRead, vlcPvwH, %inifile%, windowpos, vlcPvwH, 0
SysGet, Coords, MonitorWorkArea
guiTGW := 260
guiTGX := (guiTGX > CoordsRight OR !guiTGX ? (CoordsRight-guiTGW)-50 : guiTGX)
guiTGY := (guiTGY > CoordsBottom OR !guiTGY ? CoordsBottom//8 : guiTGY)
guiPX := (guiPX > CoordsRight OR !guiPX ? "Center" : guiPX)
guiPY := (guiPY > CoordsBottom OR !guiPY ? "Center" : guiPY)
vlcPvwX := (vlcPvwX > CoordsRight OR !vlcPvwX ? "" : vlcPvwX)
vlcPvwY := (vlcPvwY > CoordsBottom OR !vlcPvwY ? "" : vlcPvwY)
vlcPvwW := (vlcPvwW > A_ScreenWidth OR !vlcPvwW ? "" : vlcPvwW)
vlcPvwH := (vlcPvwH > A_ScreenHeight OR !vlcPvwH ? "" : vlcPvwH)
IniWrite, %guiTGX%, %inifile%, windowpos, guiTGX
IniWrite, %guiTGY%, %inifile%, windowpos, guiTGY
IniWrite, %guiPX%, %inifile%, windowpos, guiPX
IniWrite, %guiPY%, %inifile%, windowpos, guiPY
IniWrite, %vlcPvwX%, %inifile%, windowpos, vlcPvwX
IniWrite, %vlcPvwY%, %inifile%, windowpos, vlcPvwY
IniWrite, %vlcPvwW%, %inifile%, windowpos, vlcPvwW
IniWrite, %vlcPvwH%, %inifile%, windowpos, vlcPvwH
; Get other configuration
IniRead, vlcPath, %inifile%, config, vlcPath, 0
IniRead, ffmpegPath, %inifile%, config, ffmpegPath, 0
IniRead, recDir, %inifile%, config, recDir, 0
IniRead, archive, %inifile%, config, archive, 0
IniRead, archiveDir, %inifile%, config, archiveDir, 0
IniRead, recycle, %inifile%, config, recycle, true ; Whether to recylce or delete permanently
IniRead, previewDir, %inifile%, config, previewDir, 0
IniRead, filePrefixA, %inifile%, config, filePrefixA, 0
IniRead, startPlaying, %inifile%, config, startPlaying, true ; Autoplay media files when launched from parameters
IniRead, lastCtgry, %inifile%, config, lastCtgry, 0
;----------------------------------------------------------------------------------***
;  CheckEntries: Check configuration
;----------------------------------------------------------------------------------***
CheckEntries:
needIniUpdate := ""
vlcPath := Trim(StrReplace(vlcPath, "/", "\"), "\")
If !vlcPath OR !FileExist(vlcPath "\vlc.exe") {
	vlcPath := ""
	SetRegView 32 ; Wow6432Node\
	RegRead, vlcPath, HKEY_LOCAL_MACHINE, SOFTWARE\VideoLAN\VLC, InstallDir
	If !vlcPath {
		SetRegView 64 ; NOT Wow6432Node\
		RegRead, vlcPath, HKEY_LOCAL_MACHINE, SOFTWARE\VideoLAN\VLC, InstallDir
	}
	If !vlcPath OR !InStr(FileExist(vlcPath), "D") {
		vlcPath := ""
		needIniUpdate .= "vlcPath|"
	}
}
ffmpegPath := Trim(StrReplace(ffmpegPath, "/", "\"), "\")
If !ffmpegPath OR !FileExist(ffmpegPath "\bin\ffmpeg.exe") {
	ffmpegPath := ""
	needIniUpdate .= "ffmpegPath|"
}
; FFMPEG IN PATH?! NO ABOVE IS ALTERNATIVE
; Run, ffmpeg.exe, , Hide UseErrorLevel
; If ErrorLevel {
; 	If ffmpegPath {
; 		ffmpegPath := Trim(StrReplace(ffmpegPath, "/", "\"), "\")
; 		If FileExist(ffmpegPath "\bin\ffmpeg.exe") {
; 			SplitPath, ffmpegPath, , , , , cname
; 			Run *RunAs %ComSpec% /C %cname% & cd %ffmpeg% & SETX PATH "`%PATH`%;%ffmpegPath%\bin" /M, , UseErrorLevel
; 			If ErrorLevel
; 			{
; 				MsgBox, Error, Directory of ffmpeg could not be integrated into path ; Make fancy
; 				needIniUpdate .= "ffmpegPath|"
; 			} Else {
; 				MsgBox, Info, Please log out of your current session of Windows to apply system changes
; 				GoSub, Exi
; 			}
; 		} Else {
; 			ffmpegPath := ""
; 			needIniUpdate .= "ffmpegPath|"
; 		}
; 	} Else {
; 		ffmpegPath := ""
; 		needIniUpdate .= "ffmpegPath|"
; 	}
; }
previewDir := Trim(StrReplace(previewDir, "/", "\"), "\")
If !previewDir OR !InStr(FileExist(previewDir), "D") {
	previewDir := A_Temp
	needIniUpdate .= "previewDir|"
}
If (filePrefixA = -1)
	filePrefixA := ""
Else {
	cname := ""
	Loop, Parse, filePrefixA, , !,?.;:#'"*^°~`\´|/{[]}()üäö<>ß
		cname .= A_LoopField
	If (cname != filePrefixA) {
		filePrefixA := cname ? cname : "yyyy-MM-dd_HHmm"
		needIniUpdate .= "filePrefixA|"
	}
	If !cname {
		filePrefixA := cname ? cname : "yyyy-MM-dd_HHmm"
		needIniUpdate .= "filePrefixA|"
	}
}
If !archive
	archiveDir := "archive"
If archive {
	archiveDir := Trim(StrReplace(archiveDir, "/", "\"), "\")
	If !archiveDir {
		archiveDir := "archive"
		needIniUpdate .= "archiveDir|"
	}
	Else If !InStr(FileExist(archiveDir), "D") {
		If (SubStr(archiveDir, 2, 2) = ":\") { ; Absolute path
			FileCreateDir, %archiveDir%
			If ErrorLevel {
				archiveDir := UsrProfile "\Videos\archive"
				needIniUpdate .= "archiveDir|"
			}
		} Else { ; Relative path
			cname := ""
			Loop, Parse, archiveDir, , !,?.;:#'"*^°~`\´|/{[]}()üäö<>ß
				cname .= A_LoopField
			If (cname != archiveDir) {
				archiveDir := cname ? cname : "archive"
				needIniUpdate .= "archiveDir|"
			}
		}
	}
}
recDir := Trim(StrReplace(recDir, "/", "\"), "\")
If !recDir {
	recDir := UsrProfile "\Videos"
	needIniUpdate .= "recDir|"
} Else If !InStr(FileExist(recDir), "D") {
	FileCreateDir, %recDir%
	If ErrorLevel {
		recDir := UsrProfile "\Videos"
		needIniUpdate .= "recDir|"
	}
}
If needIniUpdate OR (setupGUI = 1)
{
	Gui, Setup:-DPIScale +HwndSetupHWND
	Gui, Setup:Margin, 3, 3
	Gui, Setup:Font, s8 Tahoma
	Gui, Setup:Add, Groupbox, xm+5 ym+5 w400 h255, Configuration
	Gui, Setup:Add, Groupbox, xm+5 y+10 w400 h85, After processing...
	Gui, Setup:Add, Groupbox, xm+5 y+10 w400 h80, Help
	; vlcPath
	Gui, Setup:Add, Text, % " ym+30 xm+18 " (!InStr(needIniUpdate, "vlcPath") ? "" : "cRed"), Path to VLC media player directory
	TT_vlcPath := "Installation directory of VLC Media Player`ne.g. '" ProgFiles "\VLC\VLC Media Player'"
	Gui, Setup:Add, Edit, y+3 xp-1 w193 vvlcPath, %vlcPath%
	Gui, Setup:Add, Button, yp-1 x+0 w92 vvlcPathBtn gSetupButtonBrowse -wrap, Browse...
	Gui, Setup:Add, Button, yp x+0 w92 vDLvlcPath -wrap, Download
	; ffmpegPath
	Gui, Setup:Add, Text, % " y+3 xm+18 " (!InStr(needIniUpdate, "ffmpegPath") ? "" : "cRed"), Path to ffmpeg directory
	TT_ffmpegPath := "Installation directory of ffmpeg (without '\bin')`ne.g. '" ProgFiles "\ffmpeg'"
	Gui, Setup:Add, Edit, y+3 xp-1 w193 vffmpegPath, %ffmpegPath%
	Gui, Setup:Add, Button, yp-1 x+0 w92 vffmpegPathBtn gSetupButtonBrowse -wrap, Browse...
	Gui, Setup:Add, Button, yp x+0 w92 vDLffmpegPath -wrap, Download
	; previewDir
	Gui, Setup:Add, Text, % " y+3 xm+18 " (!InStr(needIniUpdate, "previewDir") ? "" : "cRed"), Path to temporary directory for preview files
	TT_previewDir := "Temporary files will be stored there and erased after every session`ne.g. '" A_Temp "'"
	Gui, Setup:Add, Edit, y+3 xp-1 w285 vpreviewDir, %previewDir%
	Gui, Setup:Add, Button, yp-1 x+0 w92 vpreviewDirBtn gSetupButtonBrowse -wrap, Browse...
	; recDir
	Gui, Setup:Add, Text, % " y+3 xm+18 " (!InStr(needIniUpdate, "recDir") ? "" : "cRed"), Path to media category directories
	TT_recDir := "Parent directory in which category directories (or directory shortcuts) are located`ne.g. '" UsrProfile "\My Videos' will offer all immediate sub-directories and links to directories found in '..\My Videos' as categories"
	Gui, Setup:Add, Edit, y+3 xp-1 w285 vrecDir, %recDir%
	Gui, Setup:Add, Button, yp-1 x+0 w92 vrecDirBtn gSetupButtonBrowse -wrap, Browse...
	; filePrefixA
	Gui, Setup:Add, Text, % " y+3 xm+18 " (!InStr(needIniUpdate, "filePrefixA") ? "" : "cRed"), File prefix for cut clips
	TT_filePrefixA := "File name prefix for all clips that are being cut`nThe prefix is followed by the clip tags separated by '_'`nCertain letters denote date and time of processed file (click '?')`ne.g. 'yyyy-MM-dd_HHmm' renders '2015-01-01_1723_tag1_tag2.mp4'"
	Gui, Setup:Add, Edit, y+3 xp-1 w355 vfilePrefixA, %filePrefixA%
	Gui, Setup:Font, bold
	Gui, Setup:Add, Button, yp-1 x+0 w20 gfilePrefixABtn vfilePrefixABtn -wrap, ?
	Gui, Setup:Font, norm
	; startPlaying
	Gui, Setup:Add, Checkbox, % " y+8 xm+18 vstartPlaying " (if startPlaying ? "Checked" : "-Checked"), Auto-play media in VLC when launching from 'Send to'
	TT_startPlaying := "Egory can be started with selected media files by the 'Send to' option in the Windows Explorer's context menu. Have these files start playing automatically or not"
	; recycle
	Gui, Setup:Add, Radio, % " y+37 xm+18 Group gSetupDeleteRadio varchive " (if archive ? "Checked" : "-Checked"), Archive processed file
	Gui, Setup:Add, Radio, % " x+14 gSetupDeleteRadio vdelete " (if archive ? "-Checked" : "Checked"), Delete processed file
	Gui, Setup:Add, Checkbox, % " x+4 vrecycle " (if archive ? "Disabled" : "-Disabled") " " (if recycle ? "Checked" : "-Checked"), Move to recycle bin
	TT_delete1 := TT_delete2 := recyle := "When a media file is done being processed, it can either be archived, moved to the recycle bin or erased completely. Before performing such an action egory will always ask! Leaving the file untouched is always an option"
	; archiveDir1
	Gui, Setup:Add, Text, % " y+8 xm+18 " (!InStr(needIniUpdate, "archiveDir") ? "" : "cRed"), Path to archive directory
	TT_archiveDir := "Absolute path for global archive directory or relative path for each processing media file individually`ne.g. specifiying 'archive' will move 'C:\file.mp4' to 'C:\archive\' and 'C:\test\example.mov' to 'C:\test\archive\'. Note the option above"
	Gui, Setup:Add, Edit, % " y+3 xp-1 w285 varchiveDir " (if archive ? "-Disabled" : "Disabled"), %archiveDir%
	Gui, Setup:Add, Button, % " yp-1 x+0 w92 varchiveDirBtn " (if archive ? "-Disabled" : "Disabled") " gSetupButtonBrowse -wrap", Browse...
	; Information
	Gui, Setup:Add, Text, xm+18 y+35 w375 r4 vinfoText Disabled
	; View categories and edit tags
	Gui, Setup:Add, Button, xm+5 y+20 w112 gSetupEditTags vEditTags -wrap, View and edit tags
	TT_EditTags := "View and edit the configuration file, listing all previously used video tags for all categories. Tags can be erased (from the tag window) here."
	; Buttons
	Gui, Setup:Font, bold
	Gui, Setup:Add, Button, x+4 w72 vUninst -wrap, Uninstall
	TT_Uninst := "Completely uninstall egory. Tag lists and configuration will be kept and can be manually erased from '" A_AppData "\egory'"
	Gui, Setup:Font, norm
	Gui, Setup:Add, Button, x+25 w92 Default -wrap, OK
	Gui, Setup:Add, Button, x+4 w92 -wrap, &Cancel
	Gui, Setup:Show, w416 xcenter ycenter, Egory Setup
	;
	GuiControl, Setup:Focus, % SubStr(needIniUpdate, 1, InStr(needIniUpdate, "|")-1) ; Focus on first error
	Return
} ; When every loaded value is ok
loadFilters() ; Load filters from ini
loadCategories() ; Load categories from recDir
IniWrite, %vlcPath%, %inifile%, config, vlcPath
IniWrite, %ffmpegPath%, %inifile%, config, ffmpegPath
IniWrite, %recDir%, %inifile%, config, recDir
IniWrite, %archive%, %inifile%, config, archive
IniWrite, %archiveDir%, %inifile%, config, archiveDir
IniWrite, %recycle%, %inifile%, config, recycle
IniWrite, %previewDir%, %inifile%, config, previewDir
IniWrite, % (!filePrefixA ? -1 : filePrefixA), %inifile%, config, filePrefixA
IniWrite, %startPlaying%, %inifile%, config, startPlaying
IniWrite, %lastCtgry%, %inifile%, config, lastCtgry
If setupGUI ; Only started program for setting it up
	GoSub, Exi

;##################################################################################***
;##################################################################################***
;  AUTO-EXECUTIVE SECTION
;##################################################################################***
;##################################################################################***

vlcPath := vlcPath "\vlc.exe" ; Append executable
ffmpegPath := ffmpegPath "\bin\ffmpeg.exe"
SysGet, SM_CYSIZEFRAME, 33 ; Window border width (vertical)
SysGet, SM_CXSIZEFRAME, 32 ; Window border width (horizontal)
guiTLctrlMW = 15 ; Movable control min width
guiTLctrlH  = 17 ; Movable control height
guiTLspBTWsp = 5 ; Distance between both movable areas
guiTGmrgnX = 5 ; Tag GUI margins
guiTGmrgnY = 2
guiTGtagH := A_ScreenHeight//2
guiTGH := guiTGtagH+120 ; Width was already specified above
guiTLmrgnX = 60 ; Timeline GUI margins
guiTLmrgnY = 1
guiTLspaceX := guiTLmrgnX ; X pos of spaces in which movable
guiTLspaceW := A_ScreenWidth-(2*guiTLspaceX)+3 ; Width of spaces in which movable
guiTLspace1Y := guiTLmrgnY+2 ; First space in which movable Y pos
guiTLspaceH := guiTLctrlH ; +6 ; Space in which movable height
guiTLspace2Y := guiTLspace1Y+guiTLctrlH-2+guiTLspBTWsp ; Second space in which movable Y pos
guiTLctrl1Y := guiTLspace1Y ; Control position Y (always the same)
guiTLctrl2Y := guiTLspace2Y ; Similar for second slot
guiTLPbtnW := 35
guiTLH := 2*guiTLmrgnY+guiTLspaceH*2+guiTLspBTWsp+2
guiTLctrlNum := 0 ; Initial number of movable controls
gll := guiTLspaceX ; Global move/resize limits (Timeline)
glr := guiTLspaceW+guiTLspaceX
fullSprev = 0 ; Fullscreen
ctrlAct = 0
reshpFlag := false ; reshpFlag determines whether/which control is selected
ctrlPrefix := "Crtl" ; These controls can be moved
ctrlEdgeL := [[]] ; Control properties
ctrlEdgeR := [[]] ; Slot, x position
ctrlRmvd := [] ; List of removed controls
ctrlTags := [[[]]] ; List of tags stored for a each control [1]: category [2]: tag list [3]: filter list
ctrlTagWnd = 0 ; Control in charge of tag GUI
ctrlColors := ["fa7699", "76cdfa", "a8fa76", "fad676", "ba76fa"] ; red, blue, green, yellow, purple (can be easily extended)
filePrefixA := filePrefixA ? Trim(filePrefixA, "_") "_" : "file_" ; If no prefix (like datetime) is set, use "file"
previewDir .= "\egory"
playingID = 0 ; VLC playlist item. If zero nothing is being played. Status = stopped
hCursM:=DllCall("LoadCursorFromFile", "Str", A_ScriptDir "\openhand.cur") ; Cursor M: move hover
hCursG:=DllCall("LoadCursorFromFile", "Str", A_ScriptDir "\closedhand.cur") ; Cursor G: move grabbed
hCursS:=DllCall("LoadCursor", "UInt", 0, "Int", 32644) ; Cursor S: resize hover & grabbed
hCursX:=DllCall("LoadCursor", "UInt", 0, "Int", 32648) ; Cursor X: remove

; Depending settings and initialization
VLCparams := filelist "--no-fullscreen " (startPlaying ? "--playlist-autostart" : "--no-playlist-autostart") " --recursive=none --no-one-instance --no-one-instance-when-started-from-file --no-qt-system-tray --no-playlist-enqueue --ignore-filetypes=""" fileExtExcl """ --no-loop --no-repeat --no-random --qt-fs-controller --mouse-hide-timeout=2147483647 --qt-fs-opacity=0.80 --no-qt-recentplay --qt-name-in-title --no-qt-video-autoresize --video-filter=croppadd --croppadd-paddbottom=" 2*guiTLmrgnY+guiTLspaceH*2-3
If (!pid := VLCHTTP3_Start(vlcPath, VLCparams))
	GoSub, Exi ; Error Message
WinWait, ahk_pid %pid%
If (!ID := WinExist("ahk_pid " pid))
	GoSub, Exi ; Error Message
OnExit, Exi

; Timeline GUI @GUIs
WinGetPos, vlcX, vlcY, vlcW, vlcH, ahk_id %ID%
guiTLX := vlcX+SM_CXSIZEFRAME
guiTLW := vlcW-2*SM_CXSIZEFRAME
guiTLY := vlcY+vlcH-SM_CYSIZEFRAME-51-guiTLH ; GUI Y position; DPI multiplier NOT needed in VLC: *(A_ScreenDPI*1/96)
Gui, Timeline:-DPIScale +HwndTimelineHWND +E0x8000000 +LastFound -Caption +ToolWindow ; Counter GUI scaling, dont activate on click
Gui, Timeline:Font, s8 bold Tahoma
Gui, Timeline:Margin, %guiTLmrgnX%, %guiTLmrgnY%
Gui, Timeline:Color, f0f0f0
Gui, Timeline:-Theme
Gui, Timeline:+Owner%ID%
Gui, Timeline:Add, Text, % " x" guiTLspaceX-2 " y" guiTLspace1Y-2 " h" guiTLspaceH*2+guiTLspBTWsp+5 " 0x11 vvert1"
Gui, Timeline:Add, Text, % " x" guiTLspaceX+guiTLspaceW+1 " y" guiTLspace1Y-2 " h" guiTLspaceH*2+guiTLspBTWsp+5 " 0x11 vvert2"
Gui, Timeline:Add, Text, % " x" guiTLspaceX-1 " y" guiTLspace1Y-2 " w" guiTLspaceW+4 " 0x10 vhorz1"
Gui, Timeline:Add, Text, % " x" guiTLspaceX-1 " y" ceil(guiTLspace2Y-guiTLspBTWsp/2) " w" guiTLspaceW+4 " 0x10 vhorz2"
Gui, Timeline:Add, Text, % " x" guiTLspaceX-1 " y" guiTLspace2Y+guiTLspaceH+1 " w" guiTLspaceW+4 " 0x10 vhorz3"
Gui, Timeline:Add, Button, % " x" guiTLW-guiTLmrgnX+(guiTLmrgnX-guiTLPbtnW)/2 " y" guiTLspace1Y+guiTLspBTWsp+2 " w" guiTLPbtnW " vPbtn gStartProcessing", CUT
Gui, Timeline:Font, norm
Gui, Timeline:Show, x%guiTLX% y%guiTLY% w%guiTLW% h%guiTLH% Hide, Highlights Timeline ; Show GUI offscreen, to retrieve height

; Tag GUI
Gui, Tag:-DPIScale +HwndTagHWND +LastFound +ToolWindow +Delimiter| ; Counter GUI scaling
Gui, Tag:Margin, %guiTGmrgnX%, %guiTGmrgnY%
Gui, Tag:Font, s9 Tahoma
Gui, Tag:Color, Default
Gui, Tag:+Owner%ID%
Gui, Tag:Add, DropDownList, y8 w250 gtagCategory vtagCategory -Wrap +AltSubmit, % categoriesGUI()
Gui, Tag:Add, ListBox, y+4 0x8 h%guiTGtagH% w250 vtaglist gtaglist 0x1000 -Wrap, % taglistGUI() ; 0x8: Multiselect, 0x1000: Vertical scrollbar, -E0x200: No Edge?
Gui, Tag:Add, Edit, section y+5 w190 vaddTag gcheckInput Limit25 -Wrap -WantReturn +HwndAddTagHWND
Gui, Tag:Add, Button, yp-2 x+2 w59 Default, Add Tag
Gui, Tag:Font, bold s19
Gui, Tag:Add, Button, xm y+1 w28 h28 gTagButtonRefresh, % chr(8634)
Gui, Tag:Font, norm s9
Gui, Tag:Add, Text, x+5 yp+1 w217 h28 Disabled Right vinfo
Gui, Tag:Add, Text, 0x10 xm+1 w253 h1
Gui, Tag:Add, Button, xm y+2 w62 section, &Hide
Gui, Tag:Add, Button, x+2 ys w62 gTagButtonFilters vfilterBtn, % "&Filters " chr(9660)
Gui, Tag:Add, ListBox, xm+1 y+2 0x8 h67 w249 vfilterlist gfilterlist 0x100 0x1000 -Wrap Hidden Checked, % filtersGUI()
Gui, Tag:Show, % " y" A_ScreenHeight+100 " w" guiTGW " h" guiTGH, %A_Space% ; Create off-screen for further adjustments
WinSet, Transparent, 190, ahk_id %TagHWND% ; Turn entire GUI apprx. half transparent
Gui, Tag:Show, y%guiTGY% x%guiTGX% Hide

; Processing GUI
Gui, Process:-DPIScale +LastFound +HwndProcessHWND ; GUI options (style)
Gui, Process:Font, s8 Tahoma
Gui, Process:Margin, 3, 3
Gui, Process:Color, Default
Gui, Process:+Owner%ID%
Gui, Process:Add, GroupBox, xm+6 y6 w285 h50
Gui, Process:Add, Text, yp+13 w70 xp+5 -Wrap Section, Snipping clips:
Gui, Process:Add, Text, x+4 w172 -Wrap Left vprcfilename, File names
Gui, Process:Add, Text, x+4 w25 Right vcprcnt, 0`%
Gui, Process:Add, Progress, xs w275 h13 -Smooth Range0-100 vprgr1, 0 ; Progressbar 1 (part)
Gui, Process:Add, GroupBox, xm+6 w285 h87
Gui, Process:Add, Text, yp+13 xp+5 Section w135, Elapsed time
Gui, Process:Add, Text, x+4 w135 Right vetime, % FormatSeconds(0)
Gui, Process:Add, Text, y+3 xs w150 Section vpartnum, Snipping clip # 1 of 1
Gui, Process:Add, Text, xm+8 y+2 w284 0x10
Gui, Process:Add, Text, xs ys+20 w135, Processed
Gui, Process:Add, Text, x+4 w135 Right vaprcnt, 0`%
Gui, Process:Add, Progress, xs w275 h13 -Smooth Range0-100 vprgr2, 0 ; Progressbar 2 (overall)
Gui, Process:Add, Button, xm+6 y+15 w140 h23 Section gPfirstButton vfirstButton
Gui, Process:Add, Button, xp yp w140 h23 gPthirdButton vthirdButton
Gui, Process:Add, Button, xm+101 yp w92 h23 gPsecondButton vsecondButton
Gui, Process:Show, % " x" guiPX " y" A_ScreenHeight+100 " w304 h180", Processing Highlights ; Create off-screen for further adjustments
WinSet, Transparent, 190, ahk_id %ProcessHWND% ; Turn entire GUI apprx. half transparent
Gui, Process:Show, y%guiPY% Hide

;----------------------------------------------------------------------------------***
;  Everything is set up
;----------------------------------------------------------------------------------***

; Set Timers
SetTimer, MonitorBehaviorOff, 25
SetTimer, MonitorBehavior, 500
SetTimer, MonitorWinMove, 50
SetTimer, MonitorMouse, 10
; Set Hotkeys
Hotkey, IfWinActive, ahk_id %ID%
Hotkey, ^s, toggleACTTagGUI
Hotkey, IfWinActive, ahk_id %TimelineHWND%
Hotkey, ^s, toggleACTTagGUI
Hotkey, IfWinActive, ahk_id %TagHWND%
Hotkey, ^s, toggleACTTagGUI
Hotkey, IfWinActive, ahk_id %ID%
Hotkey, ^a, toggleVISTagGui
Hotkey, IfWinActive, ahk_id %TimelineHWND%
Hotkey, ^a, toggleVISTagGui
Hotkey, IfWinActive, ahk_id %TagHWND%
Hotkey, ^a, toggleVISTagGui
Return
;----------------------------------------------------------------------------------***
;  End of auto-executive section
;----------------------------------------------------------------------------------***


;##################################################################################***
;##################################################################################***
;  SUB-ROUTINES
;##################################################################################***
;##################################################################################***


;----------------------------------------------------------------------------------***
;  SetupButtonCancel: Setup GUI Close/Exit
;----------------------------------------------------------------------------------***
SetupButtonCancel:
SetupGuiClose:
SetupGuiEscape:
GoSub, Exi
Return
;----------------------------------------------------------------------------------***
;  SetupButtonOK: Setup GUI submit
;----------------------------------------------------------------------------------***
SetupButtonOK:
Gui, Setup:Submit
Gui, Setup:Destroy
filePrefixA := !filePrefixA ? -1 : filePrefixA
setupGUI = 2
GoSub, CheckEntries
Return
;----------------------------------------------------------------------------------***
;  SetupButtonUninstall: Launches external un-inst.exe
;----------------------------------------------------------------------------------***
SetupButtonUninstall:
Gui, Setup:+OwnDialogs
IfNotExist, %A_ScriptDir%\un-inst.exe
	MsgBox, 16, Error - Egory, Uninstallation executable could not be found. Try reinstalling the application.
Else {
	Run, %A_ScriptDir%\un-inst.exe, %A_ScriptDir%, UseErrorLevel
	GoSub, Exi
}
Return
;----------------------------------------------------------------------------------***
;  SetupButtonDownload: Setup GUI download applications
;----------------------------------------------------------------------------------***
SetupButtonDownload:
Gui, Setup:+OwnDialogs
Run, % (SubStr(A_GuiControl, 3) = "vlcPath") ? "http://www.videolan.org/#download" : "http://www.ffmpeg.org/download.html"
If ErrorLevel
	MsgBox, 48, Warning - Egory, Default web browser could not be started.
Return
;----------------------------------------------------------------------------------***
;  SetupButtonBrowse: Setup GUI directory browser
;----------------------------------------------------------------------------------***
SetupButtonBrowse:
tmpPath := SubStr(A_GuiControl, 1, -3)
tmpPath := InStr(FileExist(%tmpPath%), "D") ? %tmpPath% : ProgFiles
FileSelectFolder, tmpPath, *%tmpPath% , 0, Please select directory
If tmpPath
	GuiControl, Setup:, % SubStr(A_GuiControl, 1, -3), %tmpPath%
tmpPath := ""
Return
;----------------------------------------------------------------------------------***
;  SetupDeleteRadio: Setup GUI radio button disable switching
;----------------------------------------------------------------------------------***
SetupDeleteRadio:
GuiControlGet, archive, Setup:
If archive {
	GuiControl, Setup:Enable, archiveDir
	GuiControl, Setup:Enable, archiveDirBtn
	GuiControl, Setup:Disable, recycle

}
Else {
	GuiControl, Setup:Disable, archiveDir
	GuiControl, Setup:Disable, archiveDirBtn
	GuiControl, Setup:Enable, recycle
}
Return
;----------------------------------------------------------------------------------***
;  SetupEditTags: Setup GUI tag list file
;----------------------------------------------------------------------------------***
SetupEditTags:
Gui, Setup:+OwnDialogs
Run, %ctgryfile%, , UseErrorLevel
If ErrorLevel
	MsgBox, 48, Warning - Egory, Tag list file could not be accessed.
Return
;----------------------------------------------------------------------------------***
;  filePrefixABtn: Setup GUI file prefix format help
;----------------------------------------------------------------------------------***
filePrefixABtn:
; Gui, Setup:+OwnDialogs
GuiControl, Setup:Disable, filePrefixABtn
MsgBox, 64, Time formating,
(
Date Format
d `tDay of the month without leading zero (1 - 31)
dd `tDay of the month with leading zero (01 - 31)
ddd`tAbbreviated name for the day of the week (e.g. Mon)
dddd`tFull name for the day of the week (e.g. Monday)
M `tMonth without leading zero (1 - 12)
MM `tMonth with leading zero (01 - 12)
MMM`tAbbreviated month name (e.g. Jan)
MMMM`tFull month name (e.g. January)
y `tYear without century, without leading zero (0 - 99)
yy `tYear without century, with leading zero (00 - 99)
yyyy`tYear with century (e.g. 2005)`n
Time Format
h  `tHours without leading zero, 12-hour format (1 - 12)
hh `tHours with leading zero, 12-hour format (01 - 12)
H  `tHours without leading zero, 24-hour format (0 - 23)
HH `tHours with leading zero, 24-hour format (00 - 23)
m  `tMinutes without leading zero (0 - 59)
mm `tMinutes with leading zero (00 - 59)
s  `tSeconds without leading zero (0 - 59)
ss `tSeconds with leading zero (00 - 59)
t  `tSingle character time marker (e.g. A or P)
tt `tMulti-character time marker  (e.g. AM or PM)
)
GuiControl, Setup:Enable, filePrefixABtn
Return
;----------------------------------------------------------------------------------***
;  CTRL+Q Quit
;----------------------------------------------------------------------------------***
~^Q::
If WinActive("ahk_id " TimelineHWND)
OR WinActive("ahk_id " TagHWND)
	GoSub, Exi
Return
;----------------------------------------------------------------------------------***
;  RetnFrmProc: Re-enable controls
;----------------------------------------------------------------------------------***
RetnFrmProc:
WinGetPos, guiPX, guiPY, , , ahk_id %ProcessHWND%
Gui, Process:Hide ; Store X and Y
Gui, Timeline:-Disabled
Gui, Tag:-Disabled
WinSet, Enable, , ahk_id %ID%
SetTimer, MonitorWinMove, On
GuiControl, Process:Hide, secondButton
GuiControl, Process:-Default, firstButton
GuiControl, Process:, firstButton, &Hide
GuiControl, Process:Move, firstButton, w140
GuiControl, Process:, thirdButton, Cancel
GuiControlGet, spos, Process:Pos, firstButton
GuiControl, Process:Move, thirdButton, % " w140 x" sposx+sposw+4
WinActivate, ahk_id %ID%
Return
;----------------------------------------------------------------------------------***
;  CTRL+Enter: Start processing
;----------------------------------------------------------------------------------***
~^Enter::
~^NumpadEnter::
DetectHiddenWindows, Off ; Force to not detect hidden windows
If !(WinActive("ahk_id " ID)
OR WinActive("ahk_id " TimelineHWND)
OR WinActive("ahk_id " TagHWND))
OR WinExist("ahk_id " ProcessHWND)
	Return
StartProcessing:
If !playingID
	Return
Gui, Timeline:+Disabled
Gui, Tag:+Disabled
WinSet, Disable, , ahk_id %ID%
SetTimer, MonitorWinMove, Off

processList := []
Loop, %guiTLctrlNum%
	If !ctrlRmvd[A_Index]
		processList.Push([A_Index, ""])
If !processList.maxIndex()
{
	Gui, Timeline:+OwnDialogs
	MsgBox, 64, Note - Egory, No marked tracks to process.
	Gui, Timeline:-Disabled
	Gui, Tag:-Disabled
	WinSet, Enable, , ahk_id %ID%
	SetTimer, MonitorWinMove, On
	WinActivate, ahk_id %ID%
	Return
}
GuiControl, Process:Hide, secondButton
GuiControl, Process:-Default, firstButton
GuiControl, Process:, firstButton, &Hide
GuiControl, Process:Move, firstButton, w140
GuiControl, Process:, thirdButton, Cancel
GuiControlGet, spos, Process:Pos, firstButton
GuiControl, Process:Move, thirdButton, % " w140 x" sposx+sposw+4
Gui, Process:Show
WinRestore, ahk_id %ProcessHWND%
WinActivate, ahk_id %ProcessHWND%
Gui, Process:+OwnDialogs
If (VLCHTTP3_State() = "playing")
	VLCHTTP3_Pause()
FileDelete, %previewDir%\*
elapsedtime = 0
stopProc = 0
GoSub, timer
SetTimer, timer, 1000
stp2 := 50//processList.maxIndex()
GuiControl, Process:, prgr2, %stp2%
GuiControl, Process:, aprcnt, % stp2 "`%"
stp2 *= 2
FileCreateDir, %previewDir%
If ErrorLevel {
	MsgBox, 48, Warning - Egory, The temporary directory '%previewDir%' could not be created.
	GoSub, ProcessGuiEscape
	Return
}
lim2 := (stp2 >= 100) ? 99 : stp2
SetTimer, stepup2, 1100
Loop, % processList.maxIndex() {
	If stopProc
		Break
	lim2 := Round(A_Index*stp2)
	lim2 := (lim2 >= 100) ? 99 : lim2
	GuiControl, Process:, partnum, % "Snipping clip # " A_Index " of " processList.maxIndex()
	GuiControl, Process:, prgr1, 0
	GuiControl, Process:, cprcnt, 0`%
	SetTimer, stepup1, 200
	GuiControl, Process:, prcfilename, % StrLen(ctrlTags[processList[A_Index, 1], 2]) > 16 ? SubStr(ctrlTags[processList[A_Index, 1], 2], 1, 15) ".." : ctrlTags[processList[A_Index, 1], 2]
	processList[A_Index, 2] := ProcessFile(processList[A_Index, 1])
	GuiControl, Process:, prgr1, 100
	GuiControl, Process:, cprcnt, 100`%
	GuiControl, Process:, prgr2, %lim2%
	GuiControl, Process:, aprcnt, % lim2 "`%"
}
If !stopProc
	SoundPlay, *64
SetTimer, stepup1, Off
SetTimer, stepup2, Off
GuiControl, Process:, prgr2, 100
GuiControl, Process:, aprcnt, 100`%
SetTimer, timer, Off
GuiControl, Process:, firstButton, &Accept
GuiControl, Process:+Default, firstButton
GuiControl, Process:, thirdButton, Revise (ESC)
GuiControl, Process:Move, firstButton, w92
GuiControl, Process:Move, thirdButton, w92 x200
GuiControl, Process:, secondButton, &Preview
GuiControl, Process:Show, secondButton
Return
;----------------------------------------------------------------------------------***
;  Cancel/Revise Processing GUI
;----------------------------------------------------------------------------------***
PthirdButton:
ProcessGuiClose:
ProcessGuiEscape:
stopProc = 1
If ffmuid {
	DetectHiddenWindows, On
	ControlSend, , q, ahk_pid %ffmuid%
	WinClose, ahk_pid %ffmuid%
	ffmuid = 0
}
If vlcuid {
	DetectHiddenWindows, Off
	IfWinExist, ahk_pid %vlcuid%
		WinGetPos, vlcPvwX, vlcPvwY, vlcPvwW, vlcPvwH, ahk_pid %vlcuid%
	WinClose, ahk_pid %vlcuid%
	Process, Close, %vlcuid%
	vlcuid = 0
	WinActivate, ahk_id %ProcessHWND%
	Gui, Process:+Owner%ID%
	GuiControl, Process:, secondButton, &Preview
}
FileDelete, %previewDir%\*
GoSub, RetnFrmProc
Return
;----------------------------------------------------------------------------------***
;  Hide/Accept Processing GUI
;----------------------------------------------------------------------------------***
PfirstButton:
GuiControlGet, nametmp, , %A_GuiControl%
If InStr(nametmp, "Hide") {
	Gui, Process:Show, minimize
	Return
}
Gui, Process:+OwnDialogs
If vlcuid {
	DetectHiddenWindows, Off
	IfWinExist, ahk_pid %vlcuid%
		WinGetPos, vlcPvwX, vlcPvwY, vlcPvwW, vlcPvwH, ahk_pid %vlcuid%
	WinClose, ahk_pid %vlcuid%
	Process, Close, %vlcuid%
	vlcuid = 0
	WinActivate, ahk_id %ProcessHWND%
	Gui, Process:+Owner%ID%
	GuiControl, Process:, secondButton, &Preview
}
elapsedtime = 0
SetTimer, timer, 1000
stp2 := 50//processList.maxIndex()
GuiControl, Process:, prgr1, 0
GuiControl, Process:Disabled, prgr1
GuiControl, Process:, prgr2, %stp2%
GuiControl, Process:, aprcnt, % stp2 "`%"
stp2 *= 2
Loop, % processList.maxIndex() {
	lim2 := Round(A_Index*stp2)
	SetTimer, stepup2, 1000
	AcceptFile(processList[A_Index, 1], processList[A_Index, 2])
	GuiControl, Process:, prgr2, %lim2%
	GuiControl, Process:, aprcnt, % lim2 "`%"
}
SetTimer, stepup2, Off
GuiControl, Process:, prgr2, 100
GuiControl, Process:, aprcnt, 100`%
SetTimer, timer, Off
FileDelete, %previewDir%\*
Loop % ctrlTags.maxIndex() {
	GuiControl, Timeline:Hide, %ctrlPrefix%%A_Index%
	GuiControl, Timeline:Disable, %ctrlPrefix%%A_Index%
	ctrlRmvd[A_Index] := true
	ctrlEdgeL[A_Index] := []
	ctrlEdgeR[A_Index] := []
	Gui, Tag:Hide
}
NextInPL()
Sleep, 100
GoSub, RetnFrmProc
Return
;----------------------------------------------------------------------------------***
;  Preview/Stop Processing
;----------------------------------------------------------------------------------***
PsecondButton:
If !vlcuid {
	Gui, Process:+OwnDialogs
	Run, %vlcPath% --no-one-instance --no-one-instance-when-started-from-file --no-playlist-enqueue --no-qt-system-tray --no-loop --no-repeat --no-random --recursive=none --playlist-autostart --no-fullscreen --no-qt-video-autoresize --qt-minimal-view --autoscale --video-title-show --video-title-position=4 --video-title-timeout=2147483647 --video-title="Egory Clip Preview" --embedded-video "%previewDir%" --play-and-exit, , , vlcuid ; Title not working bc of embedding, needed for size/position check see below
	SetTimer, waitforVLC, -1
	GuiControl, Process:, secondButton, Sto&p
	GuiControl, Process:Focus, secondButton
	Return
}
DetectHiddenWindows, Off
IfWinExist, ahk_pid %vlcuid%
	WinGetPos, vlcPvwX, vlcPvwY, vlcPvwW, vlcPvwH, ahk_pid %vlcuid%
WinClose, ahk_pid %vlcuid%
Process, Close, %vlcuid%
vlcuid = 0
Gui, Process:+Owner%ID%
GuiControl, Process:, secondButton, &Preview
GuiControl, Process:Focus, firstButton
WinActivate, ahk_id %ProcessHWND%
Return
;----------------------------------------------------------------------------------***
;  waitforVLC: When preview VLC is done return
;----------------------------------------------------------------------------------***
waitforVLC:
While !vlcuid
	Continue
IfWinNotExist, ahk_pid %vlcuid%
	WinWait, ahk_pid %vlcuid%
Gui, % "Process:+Owner" WinExist("ahk_pid " vlcuid)
WinMove, ahk_pid %vlcuid%, , %vlcPvwX%, %vlcPvwY%, %vlcPvwW%, %vlcPvwH%
Hotkey, IfWinActive, ahk_pid %vlcuid%
Hotkey, ^q, PsecondButton
Hotkey, IfWinActive, ahk_pid %vlcuid%
Hotkey, ^w, PsecondButton
Hotkey, IfWinActive, ahk_pid %vlcuid%
Hotkey, !F4, PsecondButton
Hotkey, IfWinActive, ahk_pid %vlcuid%
Hotkey, Esc, PsecondButton
Hotkey, IfWinActive, ahk_pid %vlcuid%
Hotkey, s, PsecondButton
WinActivate, ahk_id %ProcessHWND%
WinWaitClose, ahk_pid %vlcuid%
If vlcuid {
	vlcuid = 0
	Gui, Process:+Owner%ID%
	GuiControl, Process:, secondButton, &Preview
	GuiControl, Process:Focus, firstButton
	WinActivate, ahk_id %ProcessHWND%
}
Return
;----------------------------------------------------------------------------------***
;  stepup1: Step increase first progress bar (Process GUI)
;----------------------------------------------------------------------------------***
stepup1:
GuiControlGet, prgr1, Process:
If (prgr1 >= 90)
	GuiControl, Process:, cprcnt, %prgr1%`%
Else {
	GuiControl, Process:, cprcnt, % prgr1++ "`%"
	GuiControl, Process:, prgr1, +1
}
Return
;----------------------------------------------------------------------------------***
;  stepup2: Step increase second progress bar (Process GUI)
;----------------------------------------------------------------------------------***
stepup2:
GuiControlGet, prgr2, Process:
If (prgr2 >= lim2)
	GuiControl, Process:, aprcnt, %prgr2%`%
Else {
	GuiControl, Process:, aprcnt, % prgr2++ "`%"
	GuiControl, Process:, prgr2, +1
}
Return
;----------------------------------------------------------------------------------***
;  timer: Elapsed timer for Processing GUI
;----------------------------------------------------------------------------------***
timer:
GuiControl, Process:, etime, % FormatSeconds(elapsedtime++)
Return
;----------------------------------------------------------------------------------***
;  TagButtonRefresh
;----------------------------------------------------------------------------------***
TagButtonRefresh:
loadFilters() ; Load filters from ini
loadCategories() ; Load categories from recDir
GuiControl, Tag:, tagCategory, % "|" categoriesGUI()
GuiControl, Tag:, taglist, % "|" taglistGUI(ctrlTagWnd ? ctrlTags[ctrlTagWnd, 2] : "")
GuiControl, Tag:, filterlist, % "|" filtersGUI(ctrlTagWnd ? ctrlTags[ctrlTagWnd, 3] : "")
GoSub, taglist ; Update control taglist in case items got deleted
GoSub, filterlist
Return
;----------------------------------------------------------------------------------***
;  TagButtonFilters
;----------------------------------------------------------------------------------***
TagButtonFilters:
If (showFilters := !showFilters) {
	Gui, Tag:Show, % "h " guiTGH+70
	GuiControl, Tag:, filterBtn, % "&Filters " chr(9650)
	GuiControl, Tag:Show, filterlist
} Else {
	Gui, Tag:Show, % "h " guiTGH
	GuiControl, Tag:, filterBtn, % "&Filters " chr(9660)
	GuiControl, Tag:Hide, filterlist
}
Return
;----------------------------------------------------------------------------------***
;  TagButtonAddTag: Add tag
;----------------------------------------------------------------------------------***
TagButtonAddTag:
If (!newtag := checkInput()) {
	GuiControl, Tag:Focus, addTag
	Return
}
GuiControlGet, taglist, Tag:
If ctrlTagWnd ; Store tag list in selected control
	ctrlTags[ctrlTagWnd, 2] := StrReplace((taglist ? taglist "|" : "") newtag, "|", "_")
GuiControlGet, tagCategory, Tag:
IniWrite, % taglistGUI() newtag, %ctgryfile%, categories, % categories[tagCategory, 2]
GuiControl, Tag:, taglist, % "|" taglistGUI(ctrlTags[ctrlTagWnd, 2])
GuiControl, Tag:, addTag,
UpdateControlText(ctrlTagWnd)
Return
;----------------------------------------------------------------------------------***
;  tagCategory: Load tag categories
;----------------------------------------------------------------------------------***
tagCategory:
GuiControlGet, tagCategory, Tag:
lastCtgry := categories[tagCategory, 2]
If ctrlTagWnd { ; Store category # in selected control
	ctrlTags[ctrlTagWnd, 1] := tagCategory
	ctrlTags[ctrlTagWnd, 2] := ""
}
GuiControl, Tag:, taglist, % "|" taglistGUI()
UpdateControlText(ctrlTagWnd)
Return
;----------------------------------------------------------------------------------***
;  taglist: Update control tag list
;----------------------------------------------------------------------------------***
taglist:
GuiControlGet, taglist, Tag:
GuiControlGet, tagCategory, Tag:
lastCtgry := categories[tagCategory, 2]
If ctrlTagWnd ; Store tag list in selected control
	ctrlTags[ctrlTagWnd, 2] := StrReplace(taglist, "|", "_")
UpdateControlText(ctrlTagWnd)
Return
;----------------------------------------------------------------------------------***
;  filterlist: Update filter list of track (not control)
;----------------------------------------------------------------------------------***
filterlist:
GuiControlGet, filterlist, Tag:
If ctrlTagWnd
	ctrlTags[ctrlTagWnd, 3] := filterlist
Return
;----------------------------------------------------------------------------------***
;  RemoveLabelTip: Clean Tooltip
;----------------------------------------------------------------------------------***
RemoveLabelTip:
GuiControl, Tag:, info,
Return
;----------------------------------------------------------------------------------***
;  Hide Tag GUI closing the window
;----------------------------------------------------------------------------------***
TagGuiClose:
TagGuiEscape:
TagButtonHide:
WinGetPos, guiTGX, guiTGY, , , ahk_id %TagHWND%
Gui, Tag:Hide
Return
;----------------------------------------------------------------------------------***
;  Toggle visibility of Tag GUI when pressig CTRL+A
;----------------------------------------------------------------------------------***
toggleVISTagGui:
DetectHiddenWindows Off ; Force to not detect hidden windows
If !WinExist("ahk_id " TimelineHWND)
	Return
If !WinExist("ahk_id " TagHWND) {
	Gui, Tag:Show
	WinActivate, ahk_id %TagHWND%
	ControlSend, , {Tab}, ahk_id %TagHWND%
} Else {
	GoSub, TagGuiClose
}
Return
;----------------------------------------------------------------------------------***
;  Toggle activation of Tag GUI when pressig CTRL+S
;----------------------------------------------------------------------------------***
toggleACTTagGUI:
DetectHiddenWindows Off ; Force to not detect hidden windows
If !WinExist("ahk_id " TimelineHWND)
	Return
IfWinActive, ahk_id %TagHWND%
	WinActivate, ahk_id %ID%
Else {
	Gui, Tag:Show
	WinActivate, ahk_id %TagHWND%
	ControlSend, , {Tab}, ahk_id %TagHWND%
}
Return
;----------------------------------------------------------------------------------***
;  updateTL: Updates the VLC timeline
;----------------------------------------------------------------------------------***
updateTL:
VLCHTTP3_SetPos(Round((tl-guiTLspaceX)*sRatio)) ; Set video to the 'reshape' position
Return
;----------------------------------------------------------------------------------***
;  MonitorBehaviorOff: Check whether VLC was closed
;----------------------------------------------------------------------------------***
MonitorBehaviorOff:
Gui, Timeline:+OwnDialogs
If !VLCHTTP3_Exist() { ; Exit
	GoSub, Exi
	SetTimer, MonitorBehavior, Off
	SetTimer, MonitorWinMove, Off
	SetTimer, MonitorBehaviorOff, Off
}
Return
;----------------------------------------------------------------------------------***
;  MonitorMouse: Check whether action is necessary
;----------------------------------------------------------------------------------***
MonitorMouse:
If (GetKeyState("LButton") OR GetKeyState("RButton") OR reshpFlag OR (ctrlAct != 0)) AND !timrDis {
	timrDis = 1
	SetTimer, MonitorBehavior, Off
} Else If !GetKeyState("LButton") AND !GetKeyState("RButton") AND !reshpFlag AND (ctrlAct = 0) AND timrDis {
	timrDis = 0
	SetTimer, MonitorBehavior, On
}
Return
;----------------------------------------------------------------------------------***
;  MonitorBehavior: Check whether action is necessary
;----------------------------------------------------------------------------------***
MonitorBehavior:
If !WinActive("ahk_id " TimelineHWND) ; Window not maximized or timeline not active
	SetCursor() ; Restore system cursor
playingID := VLCHTTP3_CurrentPlayListID()
If GetKeyState("LButton") OR GetKeyState("RButton") OR reshpFlag OR (ctrlAct != 0)
	Return
If (playingID != playingIDprev) { ; Checking whether playing item changed (getkeystate bug fix)
	If !playingID {
		goon++ ; Goon will prevent premature erasing of marked tracks: Only act when it happed twice in a row
		If (goon > 1)
			Gui, Timeline:Hide
	}
	Else { ; Set up for new file
		goon = 0
		If playingIDprev AND (playingIDprev != "done") {
			If (VLCHTTP3_State() = "playing")
				VLCHTTP3_Pause()
			Gui, Timeline:+OwnDialogs
			MsgBox, 36, Start processing, The previous media file was not processed. Start processing?
			WinActivate, ahk_id %ID%
			IfMsgBox, Yes
			{
				processList := []
				Loop, %guiTLctrlNum%
					If !ctrlRmvd[A_Index]
						processList.Push([A_Index, ""])
				If processList.maxIndex() {
					GoSub, StartProcessing
					VLCHTTP3_PlaylistPlayID(playingIDprev) ; Go back to the media file in question
					If (VLCHTTP3_State() = "playing")
						VLCHTTP3_Pause()
					Return ; Further treatment relayed to 'StartProcessing' label
				}
				Else {
					MsgBox, 64, Note - Egory, No marked tracks to process.
					NextInPL(playingIDprev) ; Treat previous file
				}
			} Else
				NextInPL(playingIDprev) ; Treat processed file
		}
		file := VLCHTTP3_NowPlayingFilePath() ; Retrieve file name that's playing in VLC
		SplitPath, file, , fileDirectory, ext, filename
		fileEnd := VLCHTTP3_LengthUF() ; Length in seconds
		sRatio := fileEnd/guiTLspaceW  ; Length / width of free area
		filePrefix := ""
		FileGetTime, cname, %file%, C
		FormatTime, filePrefix, %cname%, %filePrefixA%
		filePrefix := !filePrefix ? "file_" : filePrefix
		Gui, Timeline:Show
		WinActivate, ahk_id %ID%
		If (VLCHTTP3_State() = "paused")
			VLCHTTP3_Play()
	}
	If playingID OR (goon > 1) {
		goon = 0
		Loop, %guiTLctrlNum% {
			GuiControl, Timeline:Disable, %ctrlPrefix%%A_Index%
			GuiControl, Timeline:Hide, %ctrlPrefix%%A_Index%
			ctrlRmvd[A_Index] := true
			ctrlEdgeL[A_Index] := []
			ctrlEdgeR[A_Index] := []
		}
		playingIDprev := playingID
	}
} Else If playingID {
	goon = 0
	If (VLCHTTP3_State() = "playing") {
		remnTime := VLCHTTP3_RemainingUT()
	 	If remnTime AND (remnTime <= 2) { ; Prevent media file to finish playing (EOF) without saving
			Sleep, 25 ; Fix for some other VLCHTTP3 call happening at the same time in another routine. (Don't erase)
			If (VLCHTTP3_State() = "playing")
				VLCHTTP3_Pause()
			Gui, Timeline:+OwnDialogs
			MsgBox, 36, Egory: Start processing, Reached end of media file. Start processing?
			WinActivate, ahk_id %ID%
			IfMsgBox, Yes
			{
				processList := []
				Loop, %guiTLctrlNum%
					If !ctrlRmvd[A_Index]
						processList.Push([A_Index, ""])
				If processList.maxIndex() {
					GoSub, StartProcessing
					If (VLCHTTP3_State() = "playing")
						VLCHTTP3_Pause()
					Return ; Further treatment relayed to 'StartProcessing' label
				}
				Else {
					MsgBox, 64, Note - Egory, No marked tracks to process.
					NextInPL()
					WinActivate, ahk_id %ID%
				}
			} Else {
				MsgBox, 292, Egory: Next file, Done with this file? (Continue to next media file?)
				IfMsgBox, Yes
					NextInPL()
				WinActivate, ahk_id %ID%
			}
		}
	}
}
Return
;----------------------------------------------------------------------------------***
;  MonitorWinMove: Check whether VLC was moved or resized
;----------------------------------------------------------------------------------***
MonitorWinMove:
WinGet, ismin, MinMax, ahk_id %ID%
If (ismin = -1) ; Ignore if VLC is minimized or processessing
	Return
WinGetPos, vlcX, vlcY, vlcW, vlcH, ahk_id %ID%
IDwininfo := API_GetWindowInfo(ID)
brdsX := IDwininfo.XBorders
brdsY := IDwininfo.YBorders
WinGet, fullS, Style, ahk_id %ID% ; Check whether in fullscreen by style
fullS := (fullS = 0x96090000) ? 1 : 0 ; Still minor bug (won't fix), when coming from fullscreen to F11 screen
If (vlcX != vlcXprev) OR (vlcY != vlcYprev) OR (vlcW != vlcWprev) OR (vlcH != vlcHprev)
OR (brdsX != brdsXprev) OR (brdsY != brdsYprev) OR  (fullS != fullSprev) { ; If window changed
	guiTLX := vlcX+(brdsX ? SM_CXSIZEFRAME : 0)
	If !fullS ; Different cases for Y position
		guiTLY := vlcY+vlcH-(brdsY ? SM_CYSIZEFRAME : 0)-51-guiTLH ; GUI X position (see above in GUI creation)
	Else
		guiTLY := A_ScreenHeight-64-guiTLH ; GUI X position if fullscreen
	If (vlcW != vlcWprev) OR (brdsX != brdsXprev) { ; Changes in window width
		guiTLW := vlcW-2*(brdsX ? SM_CXSIZEFRAME : 0) ; Update guiTLW
		guiTLspaceWratio := guiTLspaceW/(guiTLW-(2*guiTLspaceX)+3) ; Width old/new ratio
		guiTLspaceW := guiTLW-(2*guiTLspaceX)+3 ; Update guiTLspaceW
		glr := guiTLspaceW+guiTLspaceX ; Global move/resize limits (only right boundary needed)
		GuiControl, Timeline:Move, vert1, % " x" guiTLspaceX-2 ; Update fixed controls (track edges) W + X
		GuiControl, Timeline:Move, vert2, % " x" guiTLspaceX+guiTLspaceW+1
		GuiControl, Timeline:Move, horz1, % " x" guiTLspaceX-1 " w" guiTLspaceW+4
		GuiControl, Timeline:Move, horz2, % " x" guiTLspaceX-1 " w" guiTLspaceW+4
		GuiControl, Timeline:Move, horz3, % " x" guiTLspaceX-1 " w" guiTLspaceW+4
		GuiControl, Timeline:Move, Pbtn,  % " x" guiTLW-guiTLmrgnX+(guiTLmrgnX-guiTLPbtnW)/2 " y" guiTLspace1Y+guiTLspBTWsp+2 " w" guiTLPbtnW
		sRatio := fileEnd/guiTLspaceW ; Update sRatio
		Loop, %guiTLctrlNum% { ; Update edges
			If ctrlRmvd[A_Index]
				Continue
			slt := ctrlEdgeR[A_Index, 1] ? "1" : "2"
			ctrlEdgeL[A_Index, slt] := Round((ctrlEdgeL[A_Index, slt]-guiTLspaceX)/guiTLspaceWratio)+guiTLspaceX
			ctrlEdgeR[A_Index, slt] := Round((ctrlEdgeR[A_Index, slt]-guiTLspaceX)/guiTLspaceWratio)+guiTLspaceX
			GuiControlGet, cpos, Timeline:Pos, %ctrlPrefix%%A_Index%
			cposX := Round((cposX-guiTLspaceX)/guiTLspaceWratio)+guiTLspaceX ; Update control positions by sRatio
			cposW := Round(cposW)/guiTLspaceWratio
			GuiControl, Timeline:Move, %ctrlPrefix%%A_Index%, x%cposX% w%cposW%
		}
	}
	If (fullS != fullSprev) { ; Change Timeline GUI Y position if switched to/from fullscreen
		If (fullSprev := !fullSprev) {
			WinSet, Transparent, 204, ahk_id %TimelineHWND% ; 80% transparent
			MouseMove, 1, 0, 0, R ; Have the controls show up (does this actually help/work?)
		} Else
			WinSet, Transparent, 255, ahk_id %TimelineHWND% ; Not transparent
	}
	; ToolTip, Win changed: X%guiTLX% Y%guiTLY% W%guiTLW%
	WinMove, ahk_id %TimelineHWND%, , %guiTLX%, %guiTLY%, %guiTLW% ; Move/Resize timeline GUI
	vlcXprev := vlcX, vlcYprev := vlcY, vlcWprev := vlcW
	vlcHprev := vlcH, brdsXprev := brdsX, brdsYprev := brdsY ; Update last position in variables
}
Return

;----------------------------------------------------------------------------------***
;  Btn: User pressed control
;----------------------------------------------------------------------------------***
Btn: ; When any button control is pressed
ctrlName := (A_GuiControl ? SubStr(A_GuiControl, StrLen(ctrlPrefix)+1) : ctrlAct)
If !ctrlName
	Return
lastCtgry := categories[ctrlTags[ctrlName, 1], 2]
GuiControl, Tag:, tagCategory, % "|" categoriesGUI()
GuiControl, Tag:, taglist, % "|" taglistGUI(ctrlTags[ctrlName, 2])
GuiControl, Tag:, filterlist, % "|" filtersGUI(ctrlTags[ctrlName, 3])
; GuiControl, Tag:Focus, taglist ; Disable?
DetectHiddenWindows Off ; Force to not detect hidden windows
If !WinExist("ahk_id " TagHWND)
	Gui, Tag:Show
WinActivate, ahk_id %ID% ; Rather focus the tag list
Return
;----------------------------------------------------------------------------------***
;  Timeline GUI coloring
;----------------------------------------------------------------------------------***
TimelineGuiSize:
If (A_EventInfo != 1)
	WinSet, ReDraw, , ahk_id %TimelineHWND%
;	Loop, %guiTLctrlNum%
;		If !ctrlRmvd[A_Index]
;			UpdateControlText(A_Index) ; Helps?
Return
;----------------------------------------------------------------------------------***
;  Exi: ExitApp routine
;----------------------------------------------------------------------------------***
TimelineGuiEscape: ; End script if GUI is closed
TimelineGuiClose:
Exi:
Suspend, On ; Prevent other calls
SetTimer, MonitorBehavior, Off
SetTimer, MonitorBehaviorOff, Off
DetectHiddenWindows, Off
If WinExist("ahk_id " ProcessHWND)
	WinGetPos, guiPX, guiPY, , , ahk_id %ProcessHWND%
If WinExist("ahk_id " TagHWND)
	WinGetPos, guiTGX, guiTGY, , , ahk_id %TagHWND%
DetectHiddenWindows, On
If vlcuid {
	DetectHiddenWindows, Off
	IfWinExist, ahk_pid %vlcuid%
		WinGetPos, vlcPvwX, vlcPvwY, vlcPvwW, vlcPvwH, ahk_pid %vlcuid%
	WinClose, ahk_pid %vlcuid%
	Process, Close, %vlcuid%
}
If ffmuid {
	ControlSend, , q, ahk_pid %ffmuid%
	WinClose, ahk_pid %ffmuid%
}
Gui, Timeline:Destroy
Gui, Tag:Destroy
VLCHTTP3_Close()
Gui, Process:Destroy
If lastCtgry
	IniWrite, %lastCtgry%, %inifile%, config, lastCtgry
If vlcPvwX {
	IniWrite, %vlcPvwX%, %inifile%, windowpos, vlcPvwX
	IniWrite, %vlcPvwY%, %inifile%, windowpos, vlcPvwY
	IniWrite, %vlcPvwW%, %inifile%, windowpos, vlcPvwW
	IniWrite, %vlcPvwH%, %inifile%, windowpos, vlcPvwH
}
IniWrite, %guiTGX%, %inifile%, windowpos, guiTGX
IniWrite, %guiTGY%, %inifile%, windowpos, guiTGY
IniWrite, %guiPX%, %inifile%, windowpos, guiPX
IniWrite, %guiPY%, %inifile%, windowpos, guiPY
CtlColors.Free()
SetCursor()
Process, Close, %pid%
ExitApp
Return
;----------------------------------------------------------------------------------***
;  AddButton: Adds movable control
;----------------------------------------------------------------------------------***
AddButton: ; Routine for creating a button
m := MouseGetPosFix()
mouDWNx := m[1]
mouDWNy := m[2]
If (!slt := MouseSlot(mouDWNy))
	Return
btnSY := (slt = 1) ? guiTLctrl1Y : guiTLctrl2Y
cx := mouDWNx ; -guiTLctrlMW+5 ; Do not move left but right!
GetLimits(0, mouDWNx+1, mouDWNx-1, slt)
If (lr-cx < guiTLctrlMW) OR (ll > cx) {
	ctrlAct = 0 ; Won't fit (due to limits)
	Return
}
mouDWNx := cx+guiTLctrlMW-3
MouseGetPos, mx, my
mx += guiTLctrlMW-3
MouseMove, %mx%, %my%, 0
guiTLctrlNum++
GuiControlGet, tagCategory, Tag:
ctrlTags[guiTLctrlNum, 1] := tagCategory
ctrlTags[guiTLctrlNum, 3] := guiTGdfltfilterList
Gui, Timeline:Add, Text, x%cx% y%btnSY% w%guiTLctrlMW% h%guiTLctrlH% v%ctrlPrefix%%guiTLctrlNum% gBtn -Wrap +HWNDbutton%guiTLctrlNum% +Border
UpdateControlText(guiTLctrlNum)
ctrlEdgeL[guiTLctrlNum, slt] := cx
ctrlEdgeR[guiTLctrlNum, slt] := cx+guiTLctrlMW
ctrlTagWnd := guiTLctrlNum
ctrlAct := guiTLctrlNum
Return
;----------------------------------------------------------------------------------***
;  RemoveButton: Deletes a movable control
;----------------------------------------------------------------------------------***
RemoveButton: ; Routine for removing a button
GuiControl, Timeline:Hide, %A_GuiControl%
GuiControl, Timeline:Disable, %A_GuiControl%
delCtrl := SubStr(A_GuiControl, StrLen(ctrlPrefix)+1)
ctrlRmvd[delCtrl] := true
ctrlEdgeL[delCtrl] := []
ctrlEdgeR[delCtrl] := []
Return


;##################################################################################***
;##################################################################################***
;  FUNCTIONS
;##################################################################################***
;##################################################################################***


;----------------------------------------------------------------------------------***
;  NextInPL: Move to next media file in playlist
;----------------------------------------------------------------------------------***
NextInPL(vlcplaylistID = 0) {
	global file, archive, archiveDir, filename, ext, fileDirectory, playingIDprev
	MsgBox, 36, Egory: Treat processed file, % (archive ? "Archive" : "Delete") " current (processed) media file?`n'" filename "." ext "'"
	If !vlcplaylistID {
		vlcplaylistID := VLCHTTP3_CurrentPlayListID()
		VLCHTTP3_PlayListNext()
		playingIDprev := "done" ; Prevent NextInPL to be called right again
		VLCHTTP3_Pause()
	} Else
		playingIDprev := "done" ; Prevent NextInPL to be called right again
	afPath := VLCHTTP3_PlayListFilePathID(vlcplaylistID) ; Retrieving actual filename/path
	SplitPath, afPath, , , afExt, afName
	VLCHTTP3_PlaylistDeleteID(vlcplaylistID) ; Remove last item (by ID)
	IfMsgBox, Yes
	{
		If archive {
			cname := (SubStr(archiveDir, 2, 2) = ":\") ? archiveDir : fileDirectory "\archive" ; Absolute or relative path
			FileCreateDir, %cname%
			If ErrorLevel
				MsgBox, 48, Warning - Egory, Archive directory '%cname%' could not be created. File will remain in current location.
			Else {
				Sleep, 200
				FileMove, %afPath%, %cname%, 0
				If ErrorLevel {
					FormatTime, tmptime, , yyMMddHHmmss
					FileMove, %afPath%, % cname  "\" afName "_" tmptime "." afExt
					If ErrorLevel {
						debug1 := VLCHTTP3_PlayList()
						MsgBox, 48, Warning - Egory, % "File could not be moved to archive. File will remain in current location.`n`nDebug info:`ncurrent file '" afPath "'`ndestination '" cname "'`nalt. destination '" cname  "\" afName "_" tmptime "." afExt "'`nplaylist info`n" debug1
					}
				}
			}
		} Else {
			FileSetAttrib, -RH, %afPath%
			If recycle
				FileRecycle, %afPath%
			Else
				FileDelete, %afPath%
			IfExist, %afPath%
			{
				debug1 := VLCHTTP3_PlayList()
				MsgBox, 48, Warning - Egory, % "File could not be " (recycle ? "recycled" : "deleted") ". File will remain in current location.`n`nDebug info:`ncurrent file '" afPath "'`nplaylist info`n" debug1
			}
		}
	}
}
;----------------------------------------------------------------------------------***
;  AcceptFile: Move files from preview directory to target destinations
;----------------------------------------------------------------------------------***
AcceptFile(idx, filepath) {
	global categories, ctrlTags
	FileMove, %filepath%, % categories[ctrlTags[idx, 1], 1] "\" , 0
	If ErrorLevel { ; File already exists
		SplitPath, filepath, , , ext1, filepure
		Loop { ; Try appending increasing numbers to filename
			If FileExist(categories[ctrlTags[idx, 1], 1] "\" filepure "_" SubStr("0" A_Index, -1) "." ext1)
				Continue
			FileMove, %filepath%, % categories[ctrlTags[idx, 1], 1] "\" filepure "_" SubStr("0" A_Index, -1) "." ext1 , 0
			If ErrorLevel
				Continue
			Break
		}
	}
}
;----------------------------------------------------------------------------------***
;  ProcessFile: Cutting and saving highlights
;----------------------------------------------------------------------------------***
ProcessFile(idx) {
	global categories, ctrlTags, ctrlEdgeL, ctrlEdgeR, previewDir, guiTLspaceX, ffmpegPath, file, ext, sRatio, filePrefix, ffmuid, stopProc, filters, log
	basename := previewDir "\" (ctrlTags[idx, 2] ? filePrefix ctrlTags[idx, 2] : Trim(filePrefix, "_"))
	out := basename "." ext
	SS := Round((ctrlEdgeL[idx, (ctrlEdgeL[idx, 1] ? 1 : 2)]-guiTLspaceX)*sRatio+0.0, 3) ; Start pos in sec
	T := Round((ctrlEdgeR[idx, (ctrlEdgeR[idx, 1] ? 1 : 2)]-guiTLspaceX)*sRatio-SS+0.0, 3) ; End pos in sec
	IfExist, %out%
	{ ; File already exists
		Loop { ; Try appending increasing numbers to filename
			IfNotExist, % basename "_" SubStr("0" A_Index, -1) "." ext
			{
				out := basename "_" SubStr("0" A_Index, -1) "." ext ; Leading zero
				Break
			}
		}
	}
	; Load filter graph
	cfltr := ""
	filtersTotalV = 0
	filtersTotalA = 0
	Loop, Parse, % ctrlTags[idx, 3], |
	{
		If !A_LoopField
			Continue
		found = 0
		Loop, % filters.maxIndex() ; Get filter graph from filter name
			If (A_LoopField = filters[A_Index, 1]) {
				cfltr .= filters[A_Index, 2] ";"
				found = 1
				Break
			}
		If !found
			Continue
		; Treat video track (replace in and out specifiers)
		count1 = 0
		If !filtersTotalV
			cfltr := StrReplace(cfltr, "[inV]", "[0:v]", count1)
		Else
			cfltr := StrReplace(cfltr, "[inV]", "[midV" filtersTotalV "]", count1)
		cfltr := StrReplace(cfltr, "[outV]", "[midV" filtersTotalV+1 "]", count2)
		If count1 OR count2
			filtersTotalV++
		; Treat audio track (replace in and out specifiers)
		count1 = 0
		If !filtersTotalA
			cfltr := StrReplace(cfltr, "[inA]", "[0:a]", count1)
		Else
			cfltr := StrReplace(cfltr, "[inA]", "[midA" filtersTotalA "]", count1)
		cfltr := StrReplace(cfltr, "[outA]", "[midA" filtersTotalA+1 "]", count2)
		If count1 OR count2
			filtersTotalA++
	}
	cfltr := StrReplace(cfltr, "[midV" filtersTotalV "]", "[outV]") ; Change last specifiers (= output)
	cfltr := StrReplace(cfltr, "[midA" filtersTotalA "]", "[outA]") ; For audio also
	cfltr := Trim(cfltr, ";")
	params := "-ss " SS (cfltr ? " -t " T : "") " -i """ file """ " (!cfltr ? "-t " T " " : "") (!filtersTotalV ? "-c:v copy -map v " : "-map [outV] ") (!filtersTotalA ? "-c:a copy -map a " : "-map [outA] ") (cfltr ? "-filter_complex """ cfltr """ " : "") "-shortest " """" out """"
	If !stopProc {
		RunWait, %ffmpegPath% %params%, , Hide UseErrorLevel, ffmuid
		FormatTime, datetime, A_Now, yy-MM-dd HH:mm:ss ; Current time
		FileAppend, %datetime% ---- %ffmpegPath% %params%`n, %log%
	}
	If ErrorLevel and !stopProc {
		Gui, Process:+OwnDialogs
		MsgBox, 16, Error - Egory, Clip could not be cut and converted.`n`nDebug info: %ffmpegPath% %params%
		Return, 0
	}
	ffmuid = 0
	Return, (FileExist(out) ? out : 0)
}
;----------------------------------------------------------------------------------***
;  UpdateControlText: Update movable control texts
;----------------------------------------------------------------------------------***
UpdateControlText(ctrlTagWnd) {
	global ctrlPrefix, ctrlTags, categories, ctrlColors
	If ctrlTagWnd {
		GuiControl, Timeline:, %ctrlPrefix%%ctrlTagWnd%, % (ctrlTags[ctrlTagWnd, 1] ? " [" categories[ctrlTags[ctrlTagWnd, 1], 2] "] " : " ") ctrlTags[ctrlTagWnd, 2]
		If CtlColors.IsAttached(button%ctrlTagWnd%)
			CtlColors.Change(button%ctrlTagWnd%, ctrlTags[ctrlTagWnd, 1] ? (ctrlColors[Mod(ctrlTags[ctrlTagWnd, 1], ctrlColors.maxIndex())+1]) : ctrlColors[1], "000000")
		Else
			CtlColors.Attach(button%ctrlTagWnd%, ctrlTags[ctrlTagWnd, 1] ? (ctrlColors[Mod(ctrlTags[ctrlTagWnd, 1], ctrlColors.maxIndex())+1]) : ctrlColors[1], "000000")
	}
}
;----------------------------------------------------------------------------------***
;  checkInput: Realtime correction of user input (Add tag)
;----------------------------------------------------------------------------------***
checkInput() {
	GuiControlGet, addTag, Tag:
	If (addTag = correction)
		Return, 0
	correction := ""
	Loop, Parse, addTag, , !, ,?._;:#'"*^°~+=&`%$§-`\´|/{[]}()<>
		correction .= A_LoopField
	GuiControlGet, addTag, Tag:Pos
	If (correction != addTag) {
		SoundPlay, *-1
		GuiControl, Tag:, info, The tag includes illegal characters.`nIt may only consist of letters and digits.
		SetTimer, RemoveLabelTip, -4000
		GuiControl, Tag:, addTag, %correctioN%
		Send, {End}
		Return, 0
	}
	GuiControl, Tag:,
	If !addTag
		Return, 0
	If addTag in % StrReplace(taglistGUI(), "|", ",")
	{
		GuiControl, Tag:, info, This tag already exists.
		SetTimer, RemoveLabelTip, -4000
		Return, 0
	}
	Return, %addTag%
}
;----------------------------------------------------------------------------------***
;  categoriesGUI: Returns category list for GUI with selected category
;----------------------------------------------------------------------------------***
categoriesGUI() {
	global guiTGcategories, lastCtgry
	Return, LTrim(StrReplace(guiTGcategories, "|" lastCtgry "|", "|" lastCtgry "||"), "|")
}
;----------------------------------------------------------------------------------***
;  loadCategories: Load categories from directories in recDir
;----------------------------------------------------------------------------------***
loadCategories() {
	global categories, recDir, lastCtgry, guiTGcategories
	categories := [] ; Stores descriptions and paths of categories (directories)
	Loop, %recDir%\*.*, 1
		If (A_LoopFileExt = "lnk") && !InStr(FileExist(A_LoopFileLongPath), "H") { ; Search file tree for directories and directory links
			; Check if target is directory (and add to list)
			FileGetShortcut, %A_LoopFileLongPath%, target
			If (InStr(FileExist(target), "D")) {
				categories.Push([Trim(target, "\"), Trim(SubStr(A_LoopFileName, 1, -4) , "\")])
				If (lastCtgry = Trim(SubStr(A_LoopFileName, 1, -4) , "\"))
					ctrgyfound = 1
			}
		} Else If InStr(FileExist(A_LoopFileLongPath), "D") && !InStr(FileExist(A_LoopFileLongPath), "H") {
			categories.Push([A_LoopFileLongPath, A_LoopFileName])
			If (lastCtgry = A_LoopFileName)
					ctrgyfound = 1
		}
	If !categories.maxIndex() {
		FileCreateDir, %recDir%\SampleDirectory
		If ErrorLevel {
			MsgBox, 16, Error - Egory, Failed to create directory.`nEgory will now terminate
			GoSub, Exi
		}
		categories.Push([recDir "\SampleDirectory", SampleDirectory])
	}
	If !ctrgyfound
		lastCtgry := categories[1, 2]
	guiTGcategories := "|"
	Loop, % categories.maxIndex()
		guiTGcategories .= categories[A_Index, 2] . "|"
}
;----------------------------------------------------------------------------------***
;  taglistGUI: Returns tag list for GUI with selected tags
;----------------------------------------------------------------------------------***
taglistGUI(retrTaglist = "") {
	global ctgryfile, lastCtgry
	If !lastCtgry
		Return, "|"
	IniRead, tmpTaglist, %ctgryfile%, categories, %lastCtgry%, %A_Space%
	tmpTaglist := Trim(tmpTaglist, "|")
	Sort, tmpTaglist, U D| ; Sort alphabetically
	tmpTaglist := "|" tmpTaglist "|"
	Loop, Parse, retrTaglist, _
		If !A_LoopField
			Continue
		Else If InStr(tmpTaglist, "|" A_LoopField "|")
			tmpTaglist := StrReplace(tmpTaglist, "|" A_LoopField "|", "|" A_LoopField "||")
	If (tmpTaglist = "||")
		tmpTaglist := "|"
	Return, LTrim(tmpTaglist, "|")
}
;----------------------------------------------------------------------------------***
;  filtersGUI: Returns filter list for GUI with selected filters
;----------------------------------------------------------------------------------***
filtersGUI(retrFilterlist = "") {
	global guiTGfilterList
	tmpFilterlist := guiTGfilterList
	Loop, Parse, retrFilterlist, |
		If !A_LoopField
			Continue
		Else If InStr(tmpFilterlist, "|" A_LoopField "|")
			tmpFilterlist := StrReplace(tmpFilterlist, "|" A_LoopField "|", "|" A_LoopField "||")
	If (tmpFilterlist = "||")
		tmpFilterlist := "|"
	Return, LTrim(tmpFilterlist, "|")
}
;----------------------------------------------------------------------------------***
;  loadFilters: Load filter graphs from ini config file
;----------------------------------------------------------------------------------***
loadFilters() {
	global ctgryfile, guiTGfilterList, guiTGdfltfilterList, filters
	guiTGfilterList := "" ; Stores only descriptsion for Tag GUI
	filters := [] ; Stores descriptions and settings of filters
	Loop { ; Iterate through all filters in ini
		IniRead, cname, %ctgryfile%, filter%A_Index%, name, 0
		If !cname
			Break
		IniRead, cfltr, %ctgryfile%, filter%A_Index%, filtergraph, 0
		If !cfltr
			Break
		filters.Push([cname, cfltr])
		guiTGfilterList .= cname "|"
		IniRead, cfltr, %ctgryfile%, filter%A_Index%, default, 0
		If cfltr ; If activated by default, add to default filter list
			guiTGdfltfilterList .= cname "|"
	}
	If guiTGfilterList ; If there are filters specified
		guiTGfilterList := "|" Trim(guiTGfilterList, "|") "|"
	If guiTGdfltfilterList
		guiTGdfltfilterList := "|" Trim(guiTGdfltfilterList, "|") "|"
}
;----------------------------------------------------------------------------------***
;  SetCursor: System cursor to not update with every mouse movement (only for S, G)
;----------------------------------------------------------------------------------***
SetCursor(crs = 0) {
	global hCursM, hCursG, hCursS, hCursX, curCurs
	If (crs = curCus)
		Return
	If crs not in M,G,S,X
	{
		If !curCurs
			Return
		curCurs := 0
		SPI_SETCURSORS := 0x57
		DllCall("SystemParametersInfo", "UInt", SPI_SETCURSORS, "UInt", 0, "UInt", 0, "UInt", 0)
		Return
	}
	Cursors = 32512,32513,32514,32515,32516,32640,32641,32642,32643,32644,32645,32646,32648,32649,32650,32651
	curCurs := crs
	crs := hCurs%crs%
	Loop, Parse, Cursors, `,
		DllCall("SetSystemCursor", "UInt", crs, "Int", A_Loopfield)
	Return
}
;----------------------------------------------------------------------------------***
;  MouseGetPosFix: Fix for MouseGetPos for correct coords when window not active
;----------------------------------------------------------------------------------***
MouseGetPosFix(x = 0, y = 0) { ; Arguments currently not used see a few lines below
	global TimelineHWND
	MouseGetPos, mx, my
	WinGetPos, winX, winY, , , ahk_id %TimelineHWND% ; Gui position With(!) border
	If x AND y ; Not used, but for moving the mouse by script
		MouseMove, x+winX, y+winY, 0
	Return, [mx-winX, my-winY]
}
;----------------------------------------------------------------------------------***
;  MouseSlot: Retrieve slot which is below mouse
;----------------------------------------------------------------------------------***
MouseSlot(mouDWNy) {
	global guiTLctrl1Y, guiTLctrl2Y, guiTLctrlH
	If (mouDWNy > guiTLctrl1Y) AND (mouDWNy < guiTLctrl1Y+guiTLctrlH-1) ; Mouse over first slot
		ret = 1
	Else If (mouDWNy > guiTLctrl2Y) AND (mouDWNy < guiTLctrl2Y+guiTLctrlH-1) ; Mouse over second slot
		ret = 2
	Return, %ret%
}
;----------------------------------------------------------------------------------***
;  GetLimits: Assign movement limits from neighbouring controls and global limits
;----------------------------------------------------------------------------------***
GetLimits(ctrl = 0, cl = 0, cr = 0, slt = 0) { ; Respective control if exists or client coords
	global reshpFlag, ctrlEdgeL, ctrlEdgeR, ctrlRmvd, gll, glr, ll, lr
	If reshpFlag ; Should never be called when reshpFlag is active, but before
		Return
	If ctrl { ; Set current coordinates to check for spacial (horizontal) limits
		slt := ctrlEdgeR[ctrl, 1] ? "1" : "2"
		cl := ctrlEdgeL[ctrl, slt]
		cr := ctrlEdgeR[ctrl, slt]
	}
	ll := gll ; Set global limits (outer most limits)
	lr := glr
	Loop % ctrlEdgeL.maxIndex()
	{ ; Check for local limits, e.g. adjacent controls
		If (A_Index = ctrl) OR ctrlRmvd[A_Index] OR !ctrlEdgeL[A_Index, slt]
			Continue
		If (ctrlEdgeL[A_Index, slt] < lr) AND (ctrlEdgeL[A_Index, slt] > cr)
			lr := ctrlEdgeL[A_Index, slt]-1
		If (ctrlEdgeR[A_Index, slt] > ll) AND (ctrlEdgeR[A_Index, slt] < cl)
			ll := ctrlEdgeR[A_Index, slt]+1
	}
}
;----------------------------------------------------------------------------------***
;  StopReshape: Called when the reshaping of a control is stopped
;----------------------------------------------------------------------------------***
StopReshape() {
	global reshpFlag, ctrlPrefix, ctrlAct, ctrlEdgeL, ctrlEdgeR, ctrlColors, ctrlTags
	If !reshpFlag ; Should never be called when reshpFlag is active, because no reshaping is active
		Return
	If ctrlAct
		GoSub, Btn
	GuiControlGet, cn, Timeline:Pos, %ctrlPrefix%%reshpFlag%
	GuiControlGet, ctrlName, Timeline:Name, %ctrlPrefix%%reshpFlag%
	slt := ctrlEdgeR[reshpFlag, 1] ? "1" : "2"
	ctrlEdgeL[reshpFlag, slt] := cnx ; Store new postion
	ctrlEdgeR[reshpFlag, slt] := cnx+cnw ; And width for limits
	UpdateControlText(reshpFlag)
	reshpFlag := false ; No reshaping active anymore
	restrMouse(0) ; Free mouse movement
	ctrlAct = 0 ; No control is in the process of being created
	SetCursor()
}
;----------------------------------------------------------------------------------***
;  WM_BUTTONUP: Let go of left and right mouse button
;----------------------------------------------------------------------------------***
WM_BUTTONUP() {
	global reshpFlag, ID
	If reshpFlag ; If a control was being reshaped stop and apply changes
		StopReshape()
	SetCursor() ; Reset system cursor
	restrMouse(0) ; Free mouse movement
	If (A_Gui = "Timeline") AND (A_GuiControl != "Pbtn")
		WinActivate, ahk_id %ID% ; Activate VLC when letting go of mouse button (change that?)
}
;----------------------------------------------------------------------------------***
;  WM_LBUTTONDOWN: Left mouse button down (resize, move, no effect)
;----------------------------------------------------------------------------------***
WM_LBUTTONDOWN() {
	global reshpFlag, ctrlPrefix, deltaX, deltaW, hCursS, hCursG, act, gll, glr, guiTLctrl1Y, guiTLspaceW, guiTLctrlH, guiTLctrlMW, guiTLctrlNum, mouDWNx, mouDWNy, ctrlAct, ctrlTagWnd, guiTLX
	If reshpFlag { ; Should never be called when reshpFlag is active, because it implies that LBUTTON is already held pressed
		StopReshape()
		Return
	}
	If (A_Gui != "Timeline")
		Return
	If A_GuiControl not contains %ctrlPrefix%
	{
		If ctrlAct ; If a new control is in the process of being created, do not trigger creating another
			Return
		m := MouseGetPosFix()
		mouDWNx := m[1]
		mouDWNy := m[2]
		If (mouDWNx >= gll) AND (mouDWNx <= gll+guiTLspaceW-guiTLctrlMW) ; If condition had gll+cx+guiTLctrlMW-3, but its created right from mouse pos!
		AND MouseSlot(mouDWNy) { ; If mouse is in appropriate area trigger creating a new control
			ctrlAct = -1
			GoSub, AddButton ; Create new control
			While, (ctrlAct = -1) ; Wait for control creation
			{}
			If !ctrlAct ; If control was not created, stop
				Return
			act = rsize ; Otherwise tie mouse to resize event
			; MouseMove, %mouDWNx%, %mouDWNy%, 0
			GuiControlGet, btnDWN, Timeline:Pos, %ctrlPrefix%%ctrlAct%
			deltaX := mouDWNx-btnDWNx
			deltaW := btnDWNw
			GetLimits(ctrlAct)
			MouseGetPos, , mouDWNy
			restrMouse(1, guiTLX+gll, mouDWNy, guiTLX+glr, mouDWNy) ; Limit mouse movement
			reshpFlag := ctrlAct
			If (VLCHTTP3_State() = "playing")
				VLCHTTP3_Pause()
			SetCursor("S") ; DllCall("SetSystemCursor", "UInt", hCursS)
		}
	} Else { ; Mouse is over reshapable control
		mouDWNx := MouseGetPosFix()[1]
		GuiControlGet, btnDWN, Timeline:Pos, %A_GuiControl%
		GuiControlGet, ctrlName, Timeline:Name, %A_GuiControl%
		deltaX := mouDWNx-btnDWNx
		deltaW := btnDWNw
		GetLimits(SubStr(ctrlName, StrLen(ctrlPrefix)+1)) ; Retrieve nearest spacial limits
		MouseGetPos, , mouDWNy
		restrMouse(1, guiTLX+gll, mouDWNy, guiTLX+glr, mouDWNy) ; Limit mouse movement
		reshpFlag := SubStr(ctrlName, StrLen(ctrlPrefix)+1) ; Set reshpFlag to control, signaling its reshaping
		ctrlTagWnd := SubStr(ctrlName, StrLen(ctrlPrefix)+1)
		If (VLCHTTP3_State() = "playing")
			VLCHTTP3_Pause()
		If (act = "move") ; Set appropriat cursor
			DllCall("SetCursor", "UInt", hCursG)
		Else If (act = "lsize") OR (act = "rsize")
			SetCursor("S") ; DllCall("SetCursor", "UInt", hCursS)
	}
}
;----------------------------------------------------------------------------------***
;  WM_RBUTTONDOWN: Right mouse button down (delete, no effect)
;----------------------------------------------------------------------------------***
WM_RBUTTONDOWN() {
	global reshpFlag, ctrlPrefix, hCursX, TimelineHWND, gll, glr, guiTLX
	If (A_Gui != "Timeline") OR reshpFlag ; Should never be called when reshpFlag is active, because reshaping is in progress
		Return
	WinGetPos, , y1, , y2, ahk_id %TimelineHWND%
	y2 += y1
	restrMouse(1, guiTLX+gll, y1, guiTLX+glr, y2) ; Limit mouse movement
	; DllCall("SetSystemCursor", UInt, hCursX, Int, 32512)
	SetCursor("X")
	If A_GuiControl contains %ctrlPrefix%
		GoSub, RemoveButton ; Remove erasable control
}
;----------------------------------------------------------------------------------***
;  WM_MOUSEMOVE: Mouse movement
;----------------------------------------------------------------------------------***
WM_MOUSEMOVE() {
	global reshpFlag, ctrlPrefix, ll, lr, guiTLctrlMW, deltaX, deltaY, deltaW, hCursM, hCursG, hCursS, act, ctrlAct, tl, ID, prevSetup
	; If (A_Gui = "Timeline") AND !WinActive("ahk_id " ID)
	; 	WinActivate, ahk_id %ID%
	If (A_Gui = "Setup") {
		If A_GuiControl in vlcPath,ffmpegPath,recDir,previewDir,filePrefixA,archiveDir,startPlaying,delete1,delete2,recyle,EditTags,Uninst
		{
			If (prevSetup != A_GuiControl) {
				GuiControlGet, pos, Setup:Pos, %A_GuiControl%
				posx += 3, posy += 48
				GuiControl, Setup:, infoText, % TT_%A_GuiControl%
				prevSetup := A_GuiControl
			}
		} Else {
			GuiControl, Setup:, infoText
			prevSetup := ""
		}
		Return
	}
	mx := MouseGetPosFix()[1]
	If reshpFlag { ; If reshpFlag is set, use that control
		GuiControlGet, cn, Timeline:Pos, %ctrlPrefix%%reshpFlag%
		GuiControlGet, ctrlName, Timeline:Name, %ctrlPrefix%%reshpFlag%
	} Else { ; If reshpFlag is not set, get control currently below mouse
		GuiControlGet, cn, Timeline:Pos, %A_GuiControl%
		GuiControlGet, ctrlName, Timeline:Name, %A_GuiControl%
		If (ctrlAct > 0) {
			GuiControlGet, cn, Timeline:Pos, %ctrlPrefix%%ctrlAct%
			GuiControlGet, ctrlName, Timeline:Name, %ctrlPrefix%%ctrlAct%
		}
	} ; Set cursor (part 1)
	; If GetKeyState("RButton")
		; DllCall("SetCursor", "UInt", hCursX)
	; Else If (act = "rsize") OR (act = "lsize")
		; DllCall("SetCursor", "UInt", hCursS)
	If !GetKeyState("RButton") AND !GetKeyState("LButton")
		SetCursor()
	; Cases
	If ctrlName not contains %ctrlPrefix%
	{ ; No movable control selected: return
		act := ""
		StopReshape()
		Return
	}
	If !reshpFlag { ; If nothing is being dragged
		If GetKeyState("RButton") { ; If removing is active
			GoSub, RemoveButton ; Delete selected control
			Return
		} ; Set modify label 'act' (move or resize left/right)
		If (cnx+9 > mx) {
			act = lsize
			DllCall("SetCursor", "UInt", hCursS)
		}
		Else If !cny
			act := "" ; Cursor not actually on button, but is recognized as it was
		Else If (cnx-5+cnw < mx) { ; Mouse must be on window!
			act = rsize
			DllCall("SetCursor", "UInt", hCursS)
		}
		Else {
			act = move
			DllCall("SetCursor", "UInt", hCursM)
		}
	} Else { ; (reshpFlag > 0) Resize/move control
		If !GetKeyState("LButton") { ; If mouse button no longer down, stop
			StopReshape() ; Fixes issues when mouse leaves GUI
			Return
		}
		tl := mx ; Change tl for video position, see below
		mx -= deltaX
		If (act = "move") { ; Move (move only)
			DllCall("SetCursor", "UInt", hCursG)
			cnx := (mx+cnw > lr) ? lr-cnw : mx
			cnx := (cnx <= ll) ? ll : cnx
		}
		Else if (act = "lsize") { ; Resize from left side (move and resize)
			If (mx <= ll)
			 	mx := ll ; Restrict resize to the left side
			diffX := cnx-mx ; Diff between mouse and prev pos
			If (cnw+diffX <= guiTLctrlMW) { ; Restrict minimum control width
				cnx := cnx+cnw-guiTLctrlMW
				cnw := guiTLctrlMW
			} Else { ; Prepare new width/position
				cnx := mx
				cnw := cnw+diffX
			}
			tl := cnx ; Change tl for video position, see below
		} Else if (act = "rsize") { ; Resize from right side (resize only)
			cnw := (mx+deltaW > lr) ? lr-cnx : mx-cnx+deltaW
			cnw := (cnw <= guiTLctrlMW) ? guiTLctrlMW : cnw
			tl := cnx+cnw ; Change tl for video position, see below
		} ; Apply changes onto control (MoveDraw causes too much flickering)
		GuiControl, Timeline:Move, %ctrlName%, x%cnx% w%cnw%
		SetTimer, updateTL, -1 ; Update VLC's timeline position according to tl
	}
}
;----------------------------------------------------------------------------------***
;  ClipCursor: Block mouse movement
;----------------------------------------------------------------------------------***
restrMouse(enabl, x1=0, y1=0, x2=1, y2=1) {
	VarSetCapacity(R,16,0), NumPut(x1,&R+0), NumPut(y1,&R+4), NumPut(x2,&R+8), NumPut(y2,&R+12)
	Return enabl ? DllCall("ClipCursor", UInt, &R) : DllCall("ClipCursor", UInt, NULL)
}
;----------------------------------------------------------------------------------***
;  VLCHTTP3
;----------------------------------------------------------------------------------***
#Include include\VLCHTTP3.ahk
;----------------------------------------------------------------------------------***
;  ClassCtlColors
;----------------------------------------------------------------------------------***
#Include include\Class_CtlColors.ahk
;----------------------------------------------------------------------------------***
;  API_GetWindowInfo
;----------------------------------------------------------------------------------***
#Include include\API_GetWindowInfo.ahk
