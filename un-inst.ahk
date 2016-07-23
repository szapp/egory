; mpress
;
; un-inst.ahk
; Author: szapp
; http://github.com/szapp/egory
; GNU General Public License v3.0
;
#SingleInstance, ignore
#NoTrayIcon
#NoEnv
SetWorkingDir, %A_ScriptDir%
if not A_IsAdmin
{
	params := ""
	Run *RunAs %A_ScriptFullPath% /restart %params%, %A_ScriptDir%, UseErrorLevel
	Sleep, 2000 ; If the current instance is not replaced after two seconds, it probably failed
	MsgBox, 16, Initialization failed, The program could not be started. Please restart the application with administrative rights!
	ExitApp, 1 ; Exit current instance
}
EnvGet, usrProfile, USERPROFILE
SplitPath, A_ScriptDir, DirName
MsgBox, 36, Uninstalling 'Egory', You are about to uninstall 'Egory' with all its features and components.`n`nDo you wish to continue?
IfMsgBox, no
	ExitApp, 2

filelist := "closedhand.cur`nopenhand.cur`negory.exe"
filenum = 3
SysGet, Coords, MonitorWorkArea
resx := CoordsRight-308
resy := CoordsBottom-98
Progress, B2 H90 W300 X%resx% Y%resy% C01 FM12 WM500 R0-%filenum% FS8 FM10, Erasing files...`n%A_Space%, Uninstalling,, ; Tahoma
Loop, Parse, filelist, `n
{
	Progress, %A_Index%, Erasing files...`n%A_LoopField%
	if !A_LoopField || !FileExist(A_LoopField)
		continue
	FileSetAttrib, -R, %A_LoopField%, 1
	if (InStr(FileExist(A_LoopField), "D"))
		FileRemoveDir, %A_LoopField%, 0
	else
	{
		FileDelete, %A_LoopField%
		if ErrorLevel
			failed .= A_LoopField . "`n"
	}
}
Progress, %filenum%, Done
Sleep, 2000
if failed
	MsgBox, 64, Uninstallation complete, The following files could not be erased successfully:`n`n%failed%
else
	MsgBox, 64, Unistallation complete, Uninstallation complete. All files were erased successfully.

Loop, %A_Desktop%\*.lnk
{
	FileGetShortcut, %A_LoopFileLongPath%, lnktarget
	if InStr(lnktarget, A_ScriptDir)
	{
		FileSetAttrib, -R, %A_LoopFileLongPath%
		FileDelete, %A_LoopFileLongPath%
	}
}
Loop, %A_DesktopCommon%\*.lnk
{
	FileGetShortcut, %A_LoopFileLongPath%, lnktarget
	if InStr(lnktarget, A_ScriptDir)
	{
		FileSetAttrib, -R, %A_LoopFileLongPath%
		FileDelete, %A_LoopFileLongPath%
	}
}

; Erase send-to entry
FileSetAttrib, -R, %usrProfile%\AppData\Roaming\Microsoft\Windows\SendTo\egory.lnk
FileDelete, %usrProfile%\AppData\Roaming\Microsoft\Windows\SendTo\egory.lnk

SetRegView 32 ; Wow6432Node\
RegDelete, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Egory

SplitPath, A_ScriptDir, , nUp
for Item in ComObjCreate("Shell.Application").Windows ;// loop through the ShellWindows Collection
{
	sDir := SubStr(UriEncode(Item.LocationURL), 9)
	StringReplace, sDir, sDir,/,\, All
	if (InStr(sDir, A_ScriptDir))
	{
		StringReplace, nUp, nUp,\,/, All
		Item.Navigate("file:///" nUp)
	}
}
FileSetAttrib, -R, $RarSFX_0@filelist.cfg
FileSetAttrib, -R, %A_ScriptFullPath%
FileDelete, $RarSFX_0@filelist.cfg
del_com := "ping 127.0.0.1 -n 2 > nul`ndel /Q """ . A_ScriptFullPath . """`nrmdir /Q """ A_ScriptDir """"
FileDelete, %A_Temp%\delsetup.bat
FileAppend, %del_com%, %A_Temp%\delsetup.bat
Run, %A_Temp%\delsetup.bat, %A_Temp%, Hide UseErrorlevel
ExitApp, (failed ? 6 : 0)

; ##############################################################

UriEncode(Uri, full = 0) ; For identifying shell window locations
{
    oSC := ComObjCreate("ScriptControl")
    oSC.Language := "JScript"
    Script := "var Encoded = decodeURIComponent(""" . Uri . """)"
    oSC.ExecuteStatement(Script)
    encoded := oSC.Eval("Encoded")
    Return encoded
}
