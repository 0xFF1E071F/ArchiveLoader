;=======================================================================
format PE GUI 4.0 at 0x10000000
entry  main
;=======================================================================       
include 'win32ax.inc'	 ;*    
include 'rc.inc'	
include 'macro.inc'	 
.data
_OPENFILENAME OPENFILENAME
;=======================================================================
    szFileName			   db 'S.T.A.L.K.E.R.: Shadow Of Chernobyl',0
    ProcessNotFound		   db 'process not found',0  
    PID 			   dd 0
    hProcess			   dd 0 
    RemoteThreadBaseAddress dd 0
    hInstance			   dd 0
    rSize			   dd 0
    rAlock			   dd 0
    Buff			   rb 250h

section '.code' code readable writable

main:
		invoke InitCommonControls
		invoke GetModuleHandle,0
		mov [hInstance],eax
		stdcall GetImageSize,eax
		mov [rSize],ecx
		invoke DialogBoxParam,[hInstance],D_MAIN,0,dlg_proc,0
		invoke ExitProcess,0
;=======================================================================
proc dlg_proc, hWnd, uMsg, wParam, lParam
push	ebx esi edi
		cmp [uMsg],WM_INITDIALOG
		je	.find_process
		cmp [uMsg],WM_COMMAND
		je	.wmcommand
		cmp [uMsg],WM_CLOSE
		je	.wmclose
		xor  eax,eax
		jmp .finish    
.wmcommand:
		cmp [wParam],B_OK 
		jne .exit_true
		stdcall GetOpenFile,[hInstance],[hWnd]
		test eax,eax
		je .process_not_found
.find_process:
		invoke FindWindow, NULL,szFileName
		or eax,eax
		je .process_not_found
		invoke GetWindowThreadProcessId,eax,PID
		invoke OpenProcess, PROCESS_ALL_ACCESS,NULL,[PID]
		mov [hProcess],eax
		test eax,eax
		je .process_not_found
		cmp dword[pathfile],0
		je	.exit_true
		invoke	VirtualAllocEx,[hProcess],0,[rSize],MEM_COMMIT+MEM_RESERVE,PAGE_EXECUTE_READWRITE
		mov	[RemoteThreadBaseAddress],eax
		test	eax,eax
		je	    .process_not_found
		invoke	VirtualAlloc,NULL,[rSize],MEM_COMMIT+MEM_RESERVE,PAGE_EXECUTE_READWRITE  
		mov	[rAlock],eax 
		test	eax,eax
		je	    .process_not_found
		invoke	RtlMoveMemory,[rAlock],[hInstance],[rSize]
		stdcall   RelocationImage,[hInstance],[rAlock],[RemoteThreadBaseAddress]
		mov	eax,[rAlock] 
		invoke	WriteProcessMemory,[hProcess],[RemoteThreadBaseAddress],[rAlock],[rSize],Buff
		lea	eax,[load_start]
		sub	eax,[hInstance]
		mov	ecx,[RemoteThreadBaseAddress]
		add	eax,ecx 
		invoke	CreateRemoteThread,[hProcess],0,0x100000,eax,[RemoteThreadBaseAddress],0,Buff  
		invoke	WaitForSingleObject,eax,1000h
		invoke	VirtualFreeEx,[hProcess],[RemoteThreadBaseAddress],0,MEM_RELEASE
		invoke	VirtualFree,[rAlock],0,MEM_RELEASE
		invoke	CloseHandle,[hProcess]
		invoke	SetDlgItemText,[hWnd],EDIT_1,pathfile
		jmp	.exit_true
.process_not_found:	    
		invoke SetDlgItemText,[hWnd],EDIT_1,ProcessNotFound
.exit_true:
		mov eax,TRUE  
		jmp .finish
.wmclose:			  
		invoke	EndDialog,[hWnd],0
.finish:					  
		pop edi esi ebx 		  
		ret 
endp




 
 
 

;********************************************************************************************************************
load_start:
		invoke GetModuleHandle,xrCore
		mov [xrCore.dll],eax
		invoke GetModuleHandle,xrGame
		mov [xrGame.dll],eax
		invoke GetModuleFileName,[xrCore.dll],pathgamedata,pathgamedata.size
		or eax,eax
		je load_ret
		invoke StrStr,pathgamedata,bin
		or eax,eax
		je load_ret
		mov byte[eax],0
		invoke lstrcat,pathgamedata,gamedata 
		stdcall FindSignature,0x00400000,SIG_1,SIG_1.size,SIG_1
		or eax,eax
		je load_ret	 
		mov [LevelScan],eax
		stdcall FindSignature,0x00400000,SIG_2,SIG_2.size,SIG_2
		or eax,eax
		je load_ret
		add eax,2
		mov eax,[eax]
		mov eax,[eax]	
		mov [XR_3DA.pApp],eax
		stdcall FindSignature,[xrCore.dll],SIG_3,SIG_3.size,SIG_3
		or eax,eax
		je load_ret
		inc eax
		mov eax,[eax]
		mov eax,[eax]	 
		mov [xrCore.xr_FS],eax					      
		stdcall FindSignature,[xrCore.dll],SIG_4,SIG_4.size,SIG_4
		or eax,eax
		je load_ret	 
		mov [ProcessArchive],eax				  
		stdcall FindSignature,[xrCore.dll],SIG_5,SIG_5.size,SIG_5
		or eax,eax
		je load_ret	 
		mov [xrCore.msg],eax			 
		stdcall FindSignature,[xrGame.dll],SIG_6,SIG_6.size,SIG_6
		or eax,eax
		je load_ret	 
		mov [VisualLoadLevel],eax	     
	  ;------------------------------------------------------
		mov ecx,[xrCore.xr_FS]
		stdcall dword[ProcessArchive],pathfile,pathgamedata
		mov ecx,[XR_3DA.pApp]
		stdcall dword[LevelScan]
		stdcall dword[VisualLoadLevel]
		stdcall dword[xrCore.msg],level_loaded,pathfile
		add esp,4*2
	  ;------------------------------------------------------
load_ret:
	ret  
level_loaded db '--level loaded %s',0
      bin		     db 'bin',0
      gamedata		db 'gamedata',0
      xrGame		db 'xrGame.dll',0
      xrCore		db 'xrCore.dll',0
      xrCore.dll       dd 0
      xrGame.dll       dd 0
      LevelScan        dd 0
      XR_3DA.pApp      dd 0
      xrCore.xr_FS     dd 0
      ProcessArchive   dd 0
      xrCore.msg       dd 0
      VisualLoadLevel  dd 0
      pathfile		rb 500h
      pathgamedata     rb 500h
      SIG_1		db 0x51,0xA1,0x00,0x00,0x00,0x00,0x56,0x57,0x6A,0x0A,0x8B,0xF9,0x8B,0x08,0x68,0x00,0x00,0x00,0x00,0xFF,0x15,0x00,0x00,0x00,0x00,0x80,0x3D,0x00,0x00,0x00,0x00,0x00,0x8B,0xC8,0x89,0x4C,0x24,0x08;LevelScan   
      SIG_2		db 0x8B,0x0D,0x00,0x00,0x00,0x00,0x8B,0x91,0x30,0x01,0x00,0x00,0x83,0xEC,0x08,0xD9,0x5C,0x24,0x04,0xC7,0x42,0x14,0x02,0x00,0x00,0x00,0xA1,0x00,0x00,0x00,0x00,0xD9,0xEE,0x8B,0x88,0x30,0x01,0x00;LeveApp      
      SIG_3		db 0xA3,0x00,0x00,0x00,0x00,0xEB,0x06,0x89,0x2D,0x00,0x00,0x00,0x00,0x6A,0x10,0xB9,0x00,0x00,0x00,0x00,0xE8,0x6D,0x43,0x01,0x00,0x8B,0xF0,0x3B,0xF5,0x74,0x2E,0xC7,0x06,0x00,0x00,0x00,0x00,0xE8,0xAC,0xEC,0xFF,0xFF,0x89,0x46,0x08,0xC6,0x40,0x2D;xrCore.xr_FS   
      SIG_4		db 0x55,0x8B,0xEC,0x83,0xE4,0xF8,0x81,0xEC,0x44,0x0A,0x00,0x00,0x53,0x56,0x8B,0x75,0x08,0x57,0x8B,0xD9,0x8B,0x0D,0x00,0x00,0x00,0x00,0x56,0x89,0x5C,0x24,0x20,0xE8,0x2C,0xF0,0x00,0x00,0x8B,0xF8,0x85,0xFF,0x89,0x7C,0x24,0x20,0x74,0x03,0x83,0x07;ProcessArchive  
      SIG_5		db 0x81,0xEC,0x00,0x04,0x00,0x00,0x8B,0x8C,0x24,0x04,0x04,0x00,0x00,0x8D,0x84,0x24,0x08,0x04,0x00,0x00,0x50,0x51,0x8D,0x54,0x24,0x08,0x68,0xFF,0x03,0x00,0x00,0x52,0xFF,0x15,0x00,0x00,0x00,0x00,0x83,0xC4,0x10,0x85,0xC0,0xC6,0x84,0x24,0xFF,0x03;xrCore.msg
      SIG_6		db 0x55,0x8B,0xEC,0x83,0xE4,0xF8,0x8B,0x0D,0x00,0x00,0x00,0x00,0x8B,0x09,0x81,0xEC,0xB8,0x04,0x00,0x00,0x53,0x55,0x56,0x57,0x68,0x00,0x00,0x00,0x00,0x68,0x00,0x00,0x00,0x00,0x8D,0x84,0x24,0xC0,0x00,0x00,0x00,0x50,0xFF,0x15,0x00,0x00,0x00,0x00;xrGame.dll+426080  
load_end:
;******************************************************************************************************************** 













;********************************************************************************************************************
proc GetOpenFile,_hInstance,_HwnD
locals
_FILTR_FILE  db  "xdb",0,"*.xdb*",NULL
endl
     lea eax,[_OPENFILENAME]
     invoke RtlZeroMemory,eax,sizeof.OPENFILENAME
     invoke RtlZeroMemory,pathfile,pathfile.size
     lea  eax,[_OPENFILENAME]
     mov edx,[_hInstance]
     mov [eax+OPENFILENAME.hInstance],edx
     mov edx,[_HwnD]
     mov [eax+OPENFILENAME.hwndOwner],edx
     lea  eax,[_OPENFILENAME]
     mov  [eax+OPENFILENAME.lStructSize],sizeof.OPENFILENAME
     mov  [eax+OPENFILENAME.hwndOwner],edx
     mov  [eax+OPENFILENAME.nFilterIndex],0
     mov  [eax+OPENFILENAME.nMaxFile],500h
     mov  [eax+OPENFILENAME.lpstrFile],pathfile
     lea  ecx,[_FILTR_FILE]
     mov  [eax+OPENFILENAME.lpstrFilter],ecx
     mov  [eax+OPENFILENAME.Flags],OFN_LONGNAMES+OFN_EXPLORER+OFN_FILEMUSTEXIST+OFN_PATHMUSTEXIST+OFN_HIDEREADONLY
     lea  eax,[_OPENFILENAME]
     invoke GetOpenFileName,eax
     ret
endp
;********************************************************************************************************************  


;********************************************************************************************************************
proc FindSignature,rModule,sData,sSize,sMask
locals
     addrbase dd 0
     basesize dd 0
     memalock dd 0
     IpNumberOfBytesWtitten dd 0
endl	  
		push   ebx ecx edx esi edi
		xor    esi,esi
		mov    eax,[rModule]
		mov    [addrbase],eax
		add    eax,[eax+3Ch]
		mov    eax,[eax+50h]
		mov    [basesize],eax
		invoke VirtualAlloc,0,[basesize],MEM_COMMIT+MEM_RESERVE,PAGE_EXECUTE_READWRITE
		mov    [memalock],eax
		or     eax,eax
		je     .signature_not_found
		invoke ReadProcessMemory,-1,[addrbase],[memalock],[basesize],addr IpNumberOfBytesWtitten 
		or     eax,eax
		je     .signature_not_found
		stdcall scanmem,[memalock],[basesize],[sData],[sSize],[sMask]
		or	eax,eax
		je	.signature_not_found
		mov	esi,[memalock]
		sub	eax,esi
		mov	esi,[addrbase]
		add	esi,eax
		invoke	VirtualFree,[memalock],0,MEM_RELEASE
.signature_not_found:
		mov eax,esi
.find_signature_ret:
		pop  edi esi edx ecx ebx
		ret
endp
;********************************************************************************************************************




;******************************************************************************************************************** 
proc scanmem SRCdata:dword, SRCsize:dword, PTRdata:dword,PTRsize:dword, MSKdata:dword
  ; ---------------------------------------------
; ѕроцедура поиска строки в блоке пам€ти
; (C) ManHunter / PCL
; ---------------------------------------------
; SRCdata - блок пам€ти в котором выполн€етс€ поиск
; SRCsize - размер блока в котором выполн€етс€ поиск
; PTRdata - строка дл€ поиска
; PTRsize - длина строки дл€ поиска
; MSKdata - бинарна€ маска дл€ поиска или 0 если не используетс€
;
; ¬озврат: EAX = offset найденной строки
;	   EAX = 0 если ничего не найдено
; ---------------------------------------------
	push	esi edi ebx ecx edx
 
	; ƒлина паттерна больше длины данных?
	mov	eax,[PTRsize]
	cmp	eax,[SRCsize]
	; ƒа, возврат -1
	ja	.scanmem_not_found
 
	mov	esi,[SRCdata]
	mov	edi,[PTRdata]
	mov	edx,[MSKdata]
	mov	ebx,esi
	add	ebx,[SRCsize]
	sub	ebx,[PTRsize]
.scanmem_loop:
	xor	ecx,ecx
.scanmem_test_char:
	or	edx,edx
	jz	.scanmem_no_mask
	cmp	byte [edx+ecx],0
	jz	.scanmem_char_equal
 
.scanmem_no_mask:
	mov	al,[esi+ecx]
	cmp	al,[edi+ecx]
	jne	.scanmem_next_pattern
.scanmem_char_equal:
	inc	ecx
	cmp	ecx,[PTRsize]
	jb	.scanmem_test_char
	jmp	.scanmem_found
.scanmem_next_pattern:
	inc	esi
	cmp	esi,ebx
	jbe	.scanmem_loop
 
.scanmem_not_found:
	; —трока не найдена
	xor esi,esi
 
.scanmem_found:
	; —трока найдена
	mov	eax,esi
 
.scanmem_ret:
	pop    edx ecx ebx edi esi
 
	ret
endp
;******************************************************************************************************************** 
 
 

 
 
;***************************************************************************************************************
proc RelocationImage,rModule,rAlock,rGame
 
       push  esi edi ebx ecx edx

       mov   esi,[rModule]
       add   esi,[esi+3Ch]	  ;PE
       mov   esi,[esi+0xA0]	  ;RelocationTableAdress
       add   esi,[rAlock]	  ;ALLOCK ADDR
       mov   ebx,[rGame]	  ;Game ALockADDR
       sub   ebx,[rModule]	  ;BASE MODULE

       cmp   dword  [esi],00
       je    end_ex
loop_ex:
       mov   edx,[esi+04]
       lea   eax,[esi+04]
       mov   [rModule],eax
       cmp   edx,08
       jb    loop_ex_ex
       add   edx,-08
       shr   edx,1
       je    loop_ex_ex
       xor   ecx,ecx
movzx_ex:
       movzx eax,word  [esi+ecx*2+08]
       test  eax,eax
       je    loop_ex_inc
       and   eax,0xFFF
       add   eax,[esi]
       add   eax,[rAlock]
       add   [eax],ebx
loop_ex_inc:
       inc   ecx
       cmp   ecx,edx
       jb    movzx_ex
       mov   eax,[rModule]
loop_ex_ex:
       add   esi,[eax]
       cmp   dword[esi],00
jne loop_ex

end_ex:
       pop   edx ecx ebx edi esi
       ret
endp
;*************************************************************************************************************** 
 
 
 
 
 
;********************************************************************************************************************
proc GetImageSize,rModule
     mov ecx,[rModule]
     add ecx,[ecx+3Ch] 
     mov ecx,[ecx+50h] 
	ret
endp
;********************************************************************************************************************
 


;=======================================================================
include 'idata.inc'
;=======================================================================
section '.rsrc' resource data readable
;-----------------------------------------------------------------------
  directory RT_DIALOG,dialogs,\
	    RT_MANIFEST,manifest,\
	    RT_BITMAP,bitmaps,\
	    RT_ICON,icons,\
	    RT_GROUP_ICON,group_icons	  
	
	
	
  resource  manifest,\
		 1,LANG_NEUTRAL,winxp
  resource  bitmaps,\
		 IDC_IMAGE,LANG_NEUTRAL,pict
  resource  icons,\
		   5,LANG_NEUTRAL,icon_data
  resource  group_icons,\
		   17,LANG_NEUTRAL,main_icon


  
resdata winxp
	    file 'winxpstyle2.xml'
endres	


bitmap pict,'bitmap.bmp'
icon main_icon,icon_data,'_1.ico'

;-----------------------------------------------------------------------
include "dialogs.tab" ;*
;-----------------------------------------------------------------------
include "dialogs.dat" ;*
;=======================================================================
;---------------------------------------------------------------------------------------------------------------------------
section '.reloc' fixups data readable writable discardable	  
