; ****************************************************************************
; *  Copyright (C) 2017 Updated by Matthew Marable <mmarable@oitibs.com>     *
; *                 																												 * 
; *  This program is free software; you can redistribute it and/or modify    *
; *  it under the terms of the GNU General Public License as published by    *
; *  the Free Software Foundation; either version 2 of the License, or       *
; *  any later version.                                                      *
; ****************************************************************************

!include "x64.nsh"
!include "MUI.nsh"

!define HOME "openvpn"
!define BIN "${HOME}\bin"

!define PRODUCT_NAME "OpenVPN"
!define PRODUCT_PUBLISHER "OpenIT Integrated Business Solutions"
!define OPENVPN_VERSION "2.4.5"

!define TAP "tap0901"
!define TAPDRV "${TAP}.sys"
!define TAPCAT "${TAP}.cat"

; Default OpenVPN Service registry settings
!define SERV_CONFIG_DIR "$INSTDIR\config"
!define SERV_CONFIG_EXT "ovpn"
!define SERV_EXE_PATH "$INSTDIR\bin\openvpn.exe"
!define SERV_LOG_DIR "$INSTDIR\log"
!define SERV_ADMIN_GROUP "OpenVPN Administrators"
!define SERV_PRIORITY "NORMAL_PRIORITY_CLASS"
!define SERV_LOG_APPEND "0"

;Configuration

  OutFile "posturecheck-openvpn-${OPENVPN_VERSION}-client-install-x64.exe"
  SetCompressor lzma
  ShowInstDetails show
  ShowUninstDetails show
  InstallDir "$PROGRAMFILES\${PRODUCT_NAME}"
  
;Modern UI Configuration

  Name "${PRODUCT_NAME} ${OPENVPN_VERSION}"

  !define MUI_COMPONENTSPAGE_SMALLDESC
  !define MUI_FINISHPAGE_NOAUTOCLOSE
  !define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
  !define MUI_ABORTWARNING
  !define MUI_ICON "${HOME}\openvpn.ico"
  !define MUI_UNICON "${HOME}\openvpn.ico"
  !define MUI_HEADERIMAGE
  !define MUI_UNFINISHPAGE_NOAUTOCLOSE

  !define MUI_WELCOMEPAGE_TITLE "Welcome to the ${PRODUCT_NAME} Setup"
  !define MUI_WELCOMEPAGE_TEXT "OpenVPN -  an Open Source VPN package by James Yonan.\r\n\r\nOpenVPN GUI v11.10 Icons - Created by Matthew Marable\r\n\r\nCustom Installer Created by Matthew Marable"
  !define MUI_COMPONENTSPAGE_TEXT_TOP "Select the components to install/upgrade.  Stop any OpenVPN or OpenVPN GUI processes or the OpenVPN service if it is running."

  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH
  
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES  
  !insertmacro MUI_UNPAGE_FINISH

;Languages

  !insertmacro MUI_LANGUAGE "English"
  
;Language Strings

  LangString DESC_SecOpenVPNUserSpace ${LANG_ENGLISH} "Install OpenVPN user-space components (openvpn.exe)"
  LangString DESC_SecService ${LANG_ENGLISH} "Install the OpenVPN Interactive Service (run without admin privileges)"
  LangString DESC_SecGUI ${LANG_ENGLISH} "Install OpenVPN GUI (A System tray application to control OpenVPN)"
  LangString DESC_SecGUIAuto ${LANG_ENGLISH} "Automatically start OpenVPN GUI at system startup"
  LangString DESC_SecTAP ${LANG_ENGLISH} "Install/Upgrade the TAP virtual device driver"

;Macros

!macro WriteRegStringIfUndef ROOT SUBKEY KEY VALUE
Push $R0
ReadRegStr $R0 "${ROOT}" "${SUBKEY}" "${KEY}"
StrCmp $R0 "" +1 +2
WriteRegStr "${ROOT}" "${SUBKEY}" "${KEY}" '${VALUE}'
Pop $R0
!macroend

;Installer Sections

!define SF_NOT_RO     0xFFFFFFEF

Section "OpenVPN User-Space Components" SecOpenVPNUserSpace

  SetOverwrite on
  SetOutPath "$INSTDIR\bin"
  
	File "${BIN}\openvpn.exe"
	File "${BIN}\liblzo2-2.dll"
	File "${BIN}\libssl-1_1-x64.dll"
	File "${BIN}\libcrypto-1_1-x64.dll"
	File "${BIN}\libpkcs11-helper-1.dll"
        File "${BIN}\openvpn_posturecheck.ps1"

SectionEnd

Section "OpenVPN Interactive Service" SecService

  SetOverwrite on
  SetOutPath "$INSTDIR\bin"
  
	File "${BIN}\openvpnserv.exe"
	File "${BIN}\openvpnserv2.exe"

SectionEnd


Section "OpenVPN GUI Client" SecGUI

  SetOverwrite on
  SetOutPath "$INSTDIR\bin"
  
  File "${BIN}\openvpn-gui.exe"
	
  SetOutPath "$INSTDIR\config"
  ;File "${HOME}\config\Office.ovpn"
  
  CreateDirectory "$INSTDIR\log"
  CreateDirectory "$INSTDIR\config"

SectionEnd

Section "OpenVPN GUI Auto Start" SecGUIAuto

SectionEnd

Section "TAP Virtual Ethernet Adapter" SecTAP

  SetOverwrite on

  FileWrite $R0 "REM Add a new TAP virtual ethernet adapter$\r$\n"
  FileWrite $R0 '"$INSTDIR\bin\devcon.exe" install "$INSTDIR\driver\OemVista.inf" ${TAP}$\r$\n'
  FileWrite $R0 "PAUSE$\r$\n"
  FileClose $R0

  FileWrite $R0 "ECHO WARNING: this script will delete ALL TAP virtual adapters (use the device manager to delete adapters one at a time)$\r$\n"
  FileWrite $R0 "PAUSE$\r$\n"
  FileWrite $R0 '"$INSTDIR\bin\devcon.exe" remove ${TAP}$\r$\n'
  FileWrite $R0 "PAUSE$\r$\n"
  FileClose $R0

	DetailPrint "We are running on a 64-bit system."
	SetOutPath "$INSTDIR\bin"
	File "${BIN}\devcon.exe"
	SetOutPath "$INSTDIR\driver"
	File "${HOME}\driver\${TAPDRV}"
	File "${HOME}\driver\${TAPCAT}"
	IntOp $R0 $R0 & ${SF_SELECTED}
	IntCmp $R0 ${SF_SELECTED} "" nohiddentap64 nohiddentap64

  nohiddentap64:
  File "${HOME}\driver\OemVista.inf"
  goto end

  end:

SectionEnd

;Post-install section

Section -post

  SectionGetFlags ${SecTAP} $R0
  IntOp $R0 $R0 & ${SF_SELECTED}
  IntCmp $R0 ${SF_SELECTED} "" notap notap
    IntOp $5 0 & 0
    nsExec::ExecToStack '"$INSTDIR\bin\devcon.exe" hwids ${TAP}'
    Pop $R0 
    IntOp $5 $5 | $R0
    DetailPrint "devcon hwids returned: $R0"

    Push "${TAP}"
    Pop $R0

    IntCmp $5 0 "" tapinstall_check_error tapinstall_check_error
    IntCmp $R0 -1 tapinstall

 tapinstall:
    DetailPrint "TAP REMOVE OLD TAP"
    nsExec::ExecToLog '"$INSTDIR\bin\devcon.exe" remove TAP'
    Pop $R0 
    DetailPrint "devcon remove TAP returned: $R0"
    nsExec::ExecToLog '"$INSTDIR\bin\devcon.exe" remove TAPDEV'
    Pop $R0 
    DetailPrint "devcon remove TAPDEV returned: $R0"

    DetailPrint "TAP INSTALL (${TAP})"
    nsExec::ExecToLog '"$INSTDIR\bin\devcon.exe" install "$INSTDIR\driver\OemVista.inf" ${TAP}'
    Pop $R0 
    IntOp $5 $5 | $R0
    DetailPrint "devcon install returned: $R0"

 tapinstall_check_error:
    DetailPrint "devcon cumulative status: $5"
    IntCmp $5 0 notap
    MessageBox MB_OK "An error occurred installing the TAP device driver."

 notap:

  ; Store install folder in registry
  WriteRegStr HKLM SOFTWARE\OpenVPN "" $INSTDIR

  ; install interactive service if requested
  SectionGetFlags ${SecService} $R0
  IntOp $R0 $R0 & ${SF_SELECTED}
  IntCmp $R0 ${SF_SELECTED} "" noserv noserv

	; set registry parameters for openvpnserv	
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\OpenVPN" "config_dir"  			"${SERV_CONFIG_DIR}"
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\OpenVPN" "config_ext"  			"${SERV_CONFIG_EXT}"
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\OpenVPN" "exe_path"    			"${SERV_EXE_PATH}"
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\OpenVPN" "log_dir"     			"${SERV_LOG_DIR}"
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\OpenVPN" "ovpn_admin_group" 		"${SERV_ADMIN_GROUP}"
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\OpenVPN" "priority"    			"${SERV_PRIORITY}"
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\OpenVPN" "log_append"  			"${SERV_LOG_APPEND}"

	; install openvpnserv as a service
	DetailPrint "Previous Service REMOVE (if exists)"
	nsExec::ExecToLog '"$INSTDIR\bin\openvpnserv.exe" -remove'
	nsExec::ExecToLog '"$INSTDIR\bin\openvpnserv2.exe" -remove'
	Pop $R0 # return value/error/timeout
	
	DetailPrint "Service INSTALL"
	nsExec::ExecToLog '"$INSTDIR\bin\openvpnserv.exe" -install'
	nsExec::ExecToLog '"$INSTDIR\bin\openvpnserv2.exe" -install'
	ReadEnvStr $R0 COMSPEC
	nsExec::ExecToLog '"$R0" /c "$SYSDIR\sc.exe" start OpenVPNServiceInteractive >nul'
	Pop $R1
	${If} "$R1" == "0"
		DetailPrint "Started OpenVPNServiceInteractive"
	${Else}
		DetailPrint "WARNING: $\"sc.exe start OpenVPNServiceInteractive$\" failed with return value of $R1"
	${EndIf}	

 noserv:
  ; AutoStart OpenVPN GUI if requested
  SectionGetFlags ${SecGUIAuto} $R0
  IntOp $R0 $R0 & ${SF_SELECTED}
  IntCmp $R0 ${SF_SELECTED} "" nogui nogui
	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "openvpn-gui"  "$INSTDIR\bin\openvpn-gui.exe"

 nogui:
  ; Store icon
  SetOverwrite on
  SetOutPath $INSTDIR
  File "${HOME}\openvpn.ico"

  ; Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  ; Show up in Add/Remove programs
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenVPN" "DisplayName" "OpenVPN ${OPENVPN_VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "DisplayIcon" "$INSTDIR\openvpn.ico"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "DisplayVersion" "${OPENVPN_VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "Publisher" "${PRODUCT_PUBLISHER}"
  WriteRegExpandStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenVPN" "UninstallString" "$INSTDIR\Uninstall.exe"

SectionEnd

;--------------------------------
;Descriptions

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecOpenVPNUserSpace} $(DESC_SecOpenVPNUserSpace)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecService} $(DESC_SecService)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecGUI} $(DESC_SecGUI)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecGUIAuto} $(DESC_SecGUIAuto)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecTAP} $(DESC_SecTAP)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

Function .onInit
	SetRegView 64
	StrCpy $INSTDIR "$PROGRAMFILES64\${PRODUCT_NAME}"
  ClearErrors
  UserInfo::GetName
  IfErrors ok
  Pop $R0
  UserInfo::GetAccountType
  Pop $R1
  StrCmp $R1 "Admin" ok
    Messagebox MB_OK "Administrator privileges required to install OpenVPN [$R0/$R1]"
    Abort
  ok:

  Push $R0
  ReadRegStr $R0 HKLM SOFTWARE\OpenVPN-GUI ""
  StrCmp $R0 "" goon

    Messagebox MB_YESNO "It seems the package ${PRODUCT_NAME} (OpenVPN GUI) is already installed.$\r$\nWe recommend you to uninstall it in the standard way before proceeding. Continue installing?" IDYES goon
    Abort

  goon:
  Pop $R0

  Push $R0
  Push $R1
  FindWindow $R0 "openvpn-gui"
  IntCmp $R0 0 donerun

    Messagebox MB_YESNO|MB_ICONEXCLAMATION "OpenVPN GUI is currently running.$\r$\nUntil you terminate it, all files that belong to it cannot be updated.$\r$\nShall this program be killed now? If true, all existing connections will be closed." IDNO donerun

    SendMessage $R0 ${WM_DESTROY} 0 0 $R1 /TIMEOUT=7000
    IntCmp $R1 0 donerun

		Messagebox MB_OK|MB_ICONEXCLAMATION "Trouble terminating OpenVPN GUI, please close it and then click OK."

  donerun:
  Pop $R1
  Pop $R0

FunctionEnd

Function .onSelChange
  Push $0

  ;Check if Section OpenVPN GUI is selected.
  SectionGetFlags ${SecGUI} $0
  IntOp $0 $0 & ${SF_SELECTED}
  IntCmp $0 ${SF_SELECTED} "" noautogui noautogui

  ;GUI was selected so set GUIAuto to Not-ReadOnly.
  SectionGetFlags ${SecGUIAuto} $0
  IntOp $0 $0 & ${SF_NOT_RO}
  SectionSetFlags ${SecGUIAuto} $0
  goto CheckTAP

  noautogui:
  SectionSetFlags ${SecGUIAuto} ${SF_RO}


  CheckTAP:
  ;Check if Section Install-TAP is selected.
  SectionGetFlags ${SecTAP} $0
  IntOp $0 $0 & ${SF_SELECTED}
  IntCmp $0 ${SF_SELECTED} "" notap notap

  ;TAP was selected so set TAPHidden to Not-ReadOnly.
  IntOp $0 $0 & ${SF_NOT_RO}
  goto end

  notap:

  end:
  Pop $0

FunctionEnd

Function .onInstSuccess
  IfFileExists "$INSTDIR\bin\openvpn-gui.exe" "" nogui
    ExecShell open "$INSTDIR\bin\openvpn-gui.exe"
  nogui:

FunctionEnd

;Uninstaller Section

Function un.onInit
	SetRegView 64
	StrCpy $INSTDIR "$PROGRAMFILES64\${PRODUCT_NAME}"
  ClearErrors
  UserInfo::GetName
  IfErrors ok
  Pop $R0
  UserInfo::GetAccountType
  Pop $R1
  StrCmp $R1 "Admin" ok
    Messagebox MB_OK "Administrator privileges required to uninstall OpenVPN [$R0/$R1]"
    Abort
  ok:
  Push $R0
  Push $R1
  FindWindow $R0 "openvpn-gui"
  IntCmp $R0 0 donerun
    Messagebox MB_YESNO|MB_ICONEXCLAMATION "OpenVPN GUI is currently running.$\r$\nUntil you terminate it, all files that belong to it cannot be removed.$\r$\nShall this program be killed now? If true, all existing connections will be closed." IDNO donerun

    SendMessage $R0 ${WM_DESTROY} 0 0 $R1 /TIMEOUT=7000
    IntCmp $R1 0 donerun
		Messagebox MB_OK|MB_ICONEXCLAMATION "Trouble terminating OpenVPN GUI, please close it and then click OK."

  donerun:
  Pop $R1
  Pop $R0

FunctionEnd

Section "Uninstall"

	DetailPrint "Removing OpenVPN Services..."
	nsExec::ExecToLog '"$INSTDIR\bin\openvpnserv.exe" -remove'
	nsExec::ExecToLog '"$INSTDIR\bin\openvpnserv2.exe" -remove'
	Pop $R0 
	
  Sleep 3000

  DetailPrint "Removing TAP Virtual Adapter..."
  nsExec::ExecToLog '"$INSTDIR\bin\devcon.exe" remove ${TAP}'
  Pop $R0 

  Push "$INSTDIR\bin"

  Delete "$INSTDIR\bin\devcon.exe"
  Delete "$INSTDIR\bin\openvpn.exe"
  Delete "$INSTDIR\bin\openvpnserv.exe"
  Delete "$INSTDIR\bin\openvpnserv2.exe"
  Delete "$INSTDIR\bin\openvpnserv2.InstallLog"
  Delete "$INSTDIR\bin\openvpnserv2.InstallState"
  Delete "$INSTDIR\bin\openvpn-gui.exe"
  Delete "$INSTDIR\bin\libeay32.dll"
	Delete "$INSTDIR\bin\ssleay32.dll"
  Delete "$INSTDIR\bin\liblzo2-2.dll"
  Delete "$INSTDIR\bin\libssl-1_1-x64.dll"
	Delete "$INSTDIR\bin\libcrypto-1_1-x64.dll"
  Delete "$INSTDIR\bin\libpkcs11-helper-1.dll"
  Delete "$INSTDIR\driver\OemVista.inf"
  Delete "$INSTDIR\driver\${TAPDRV}"
  Delete "$INSTDIR\driver\${TAPCAT}"
	Delete "$INSTDIR\log\*.log"
  Delete "$INSTDIR\openvpn.ico"
  Delete "$INSTDIR\Uninstall.exe"

  RMDir "$INSTDIR\bin"
  RMDir "$INSTDIR\driver"
  RMDir "$INSTDIR\log"
  RMDir "$INSTDIR"

  DeleteRegKey 		HKLM SOFTWARE\OpenVPN
  DeleteRegKey 		HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenVPN"
  DeleteRegValue 	HKLM "Software\Microsoft\Windows\CurrentVersion\Run" "openvpn-gui"

SectionEnd
