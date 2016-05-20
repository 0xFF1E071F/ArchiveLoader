section '.idata' import data readable writeable

  library kernel32,'kernel32.dll',\
          user32,'user32.dll',\
          shell32,'shell32.dll',\
          comctl32,'comctl32.dll',\
          comdlg32,'comdlg32.dll'

  import kernel32,\
         CloseHandle,'CloseHandle',\
         CreateRemoteThread,'CreateRemoteThread',\
         ExitProcess,'ExitProcess',\
         GetModuleFileName,'GetModuleFileNameA',\
         GetModuleHandle,'GetModuleHandleA',\
         OpenProcess,'OpenProcess',\
         ReadProcessMemory,'ReadProcessMemory',\
         RtlMoveMemory,'RtlMoveMemory',\
         RtlZeroMemory,'RtlZeroMemory',\
         VirtualAlloc,'VirtualAlloc',\
         VirtualAllocEx,'VirtualAllocEx',\
         VirtualFree,'VirtualFree',\
         VirtualFreeEx,'VirtualFreeEx',\
         WaitForSingleObject,'WaitForSingleObject',\
         WriteProcessMemory,'WriteProcessMemory',\
         lstrcat,'lstrcatA'

  import user32,\
         DialogBoxParam,'DialogBoxParamA',\
         EndDialog,'EndDialog',\
         FindWindow,'FindWindowA',\
         GetWindowThreadProcessId,'GetWindowThreadProcessId',\
         SetDlgItemText,'SetDlgItemTextA'

  import shell32,\
         StrStr,'StrStrA'

  import comctl32,\
         InitCommonControls,'InitCommonControls'

  import comdlg32,\
         GetOpenFileName,'GetOpenFileNameA'