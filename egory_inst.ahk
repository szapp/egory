; mpress
;
; egory_inst.ahk
; Author: szapp
; http://github.com/szapp/egory
; GNU General Public License v3.0
;
#SingleInstance, ignore
#NoTrayIcon
#NoEnv

If not A_IsAdmin
{
	params := ""
	Run *RunAs %A_ScriptFullPath% /restart %params%, %A_WorkingDir%, UseErrorLevel
	Sleep, 2000 ; If the current instance is not replaced after two seconds, it probably failed
	MsgBox, 16, Initialization failed, The program could not be started. Please restart the application with administrative rights!
	ExitApp, 1 ; Exit current instance
}
Author := "szapp"
Version = 1.0.0.1
Projectname := "Egory"
FileGetSize, Projectsize, %A_ScriptFullPath%, K
EnvGet, ProgFiles, ProgramFiles(x86)
If !ProgFiles
	EnvGet, ProgFiles, ProgramFiles
EnvGet, usrProfile, USERPROFILE

SetRegView 32 ; Wow6432Node\
RegRead, startDir, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Egory, InstallLocation
startDir := InStr(FileExist(Trim(startDir, """\")), "D") ? Trim(startDir, """") : ProgFiles

FileSelectFolder, path, *%startDir%, 3, Select directory to install %Projectname%
If !path
	ExitApp, 111
If (path = ProgFiles)
	path .= "\Egory"
FileCreateDir, %path%
IfNotExist, %path%
{
	MsgBox, 16, Error - Egory, Directory could not be created. Setup could not finish properly.
	ExitApp, 112
}

Progress, M T A H55 W400 FM10 WM400, , Installing please stand by..., Installing Egory, Tahoma
Progress, 10

Progress, 25

FileInstall, bin\egory.exe, %path%\egory.exe, 1
FileInstall, bin\un-inst.exe, %path%\un-inst.exe, 1
FileInstall, bin\closedhand.cur, %path%\closedhand.cur, 1
FileInstall, bin\openhand.cur, %path%\openhand.cur, 1
IfNotExist, %path%\egory.exe
{
	MsgBox, 16, Error - Egory, Egory.exe could not be created. Setup could not finish properly.
	ExitApp, 113
}

Progress, 45

; Integrate into send-to
FileSetAttrib, -R, %usrProfile%\AppData\Roaming\Microsoft\Windows\SendTo\egory.lnk
FileDelete, %usrProfile%\AppData\Roaming\Microsoft\Windows\SendTo\egory.lnk
FileCreateShortcut, %path%\egory.exe, %usrProfile%\AppData\Roaming\Microsoft\Windows\SendTo\egory.lnk
if ErrorLevel
{
	MsgBox, 16, Shell entry error, Could not create entry in 'Send to...' context menu! Setup could not finish properly.
	ExitApp, 114
}

Progress, 90

; Register for uninstall
RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Egory
RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Egory, DisplayIcon, "%path%\egory.exe"
RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Egory, DisplayName, %Projectname%
RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Egory, DisplayVersion, %Version%
RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Egory, InstallLocation, "%path%"
RegWrite, REG_DWORD, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Egory, NoRepair, 1
RegWrite, REG_DWORD, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Egory, NoModify, 0
RegWrite, REG_DWORD, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Egory, EstimatedSize, %Projectsize%
RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Egory, UninstallString, "%path%\egory.exe" "-setup"
RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Egory, ModifyPath, "%path%\egory.exe" "-setup"
RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Egory, Publisher, %Author%

Progress, 100

FileSetAttrib, -RH, %A_DesktopCommon%\egory.lnk
FileDelete, %A_DesktopCommon%\egory.lnk
FileCreateShortcut, %path%\egory.exe, %A_DesktopCommon%\egory.lnk, , , egory, %path%\egory.exe, , 1

ToExit:
Run, %path%\egory.exe -setup, , UseErrorLevel, startedPID
WinWait, ahk_pid %startedPID%, , 4
ExitApp
