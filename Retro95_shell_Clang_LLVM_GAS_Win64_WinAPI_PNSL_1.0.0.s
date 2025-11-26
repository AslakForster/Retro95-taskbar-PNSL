    # =========================================================
    # Retro95 taskbar — PNSL licensed
    # =========================================================
    # 
    # Clang/LLVM GAS Win64 (Intel syntax) assembly 
    # 
    # One-liner build command (copy & paste as-is):
    #   clang --target=x86_64-w64-mingw32 -x assembler -masm=intel -c retro95.s -o retro95.o && clang --target=x86_64-w64-mingw32 retro95.o -o retro95.exe -nostdlib -Wl,-e,_mainCRTStartup -Wl,--subsystem,windows -Wl,--gc-sections -Wl,--icf=all -Wl,-s -lkernel32 -luser32 -lgdi32 -lcomctl32 -lshell32 -ladvapi32
    #
    # =========================================================


.def    @feat.00;
    .scl    3;
    .type   0;
    .endef
    .globl  @feat.00
@feat.00 = 0
    .intel_syntax noprefix
    .file   "main.c"

    # ============================================
    #  Minimal entry point: _mainCRTStartup
    #  hInstance = GetModuleHandleW(NULL)
    #  exit code = RunApp(hInstance)
    # ============================================
    .def    _mainCRTStartup;
    .scl    2;
    .type   32;
    .endef
    .text
    .globl  _mainCRTStartup                    
_mainCRTStartup:                               
.seh_proc _mainCRTStartup
    sub     rsp, 40
    .seh_stackalloc 40
    .seh_endprologue

    xor     ecx, ecx                           
    call    qword ptr [rip + __imp_GetModuleHandleW]
    mov     rcx, rax                           
    call    RunApp                             
    mov     ecx, eax                           
    call    qword ptr [rip + __imp_ExitProcess]

    .seh_startepilogue
    add     rsp, 40
    .seh_endepilogue
    ret                                        
.seh_endproc

    # =========================================================
    # RunApp (original core app logic; takes HINSTANCE in rcx)
    # =========================================================
    .def    RunApp;
    .scl    3;
    .type   32;
    .endef
RunApp:                                         

.seh_proc RunApp

    push    r15
    .seh_pushreg r15
    push    r14
    .seh_pushreg r14
    push    rsi
    .seh_pushreg rsi
    push    rdi
    .seh_pushreg rdi
    push    rbp
    .seh_pushreg rbp
    push    rbx
    .seh_pushreg rbx
    sub     rsp, 296
    .seh_stackalloc 296
    movaps  xmmword ptr [rsp + 272], xmm6      
    .seh_savexmm xmm6, 272
    .seh_endprologue

    mov     rsi, rcx                           

    movabs  rax, 1095216660488
    lea     rcx, [rsp + 104]
    mov     qword ptr [rcx], rax
    call    qword ptr [rip + __imp_InitCommonControlsEx]

    xorps   xmm6, xmm6

    # Register main window class
    lea     rbx, [rsp + 112]
    movaps  xmmword ptr [rbx], xmm6
    movaps  xmmword ptr [rbx + 16], xmm6
    movaps  xmmword ptr [rbx + 48], xmm6
    movaps  xmmword ptr [rbx + 32], xmm6
    lea     rax, [rip + MainWndProc]
    mov     qword ptr [rbx + 8], rax           
    mov     qword ptr [rbx + 24], rsi          
    lea     rdi, [rip + .L.str]
    mov     qword ptr [rbx + 64], rdi          

    mov     r14, qword ptr [rip + __imp_LoadCursorW]
    mov     edx, 32512                         
    xor     ecx, ecx
    call    r14
    mov     qword ptr [rbx + 40], rax          
    and     qword ptr [rbx + 48], 0
    mov     dword ptr [rbx], 8                 
    mov     r15, qword ptr [rip + __imp_RegisterClassW]
    mov     rcx, rbx
    call    r15

    # Register start menu window class
    lea     rbx, [rsp + 192]
    movaps  xmmword ptr [rbx], xmm6
    movaps  xmmword ptr [rbx + 16], xmm6
    movaps  xmmword ptr [rbx + 48], xmm6
    movaps  xmmword ptr [rbx + 32], xmm6
    lea     rax, [rip + StartMenuWndProc]
    mov     qword ptr [rbx + 8], rax           
    mov     qword ptr [rbx + 24], rsi          
    lea     rax, [rip + .L.str.2]
    mov     qword ptr [rbx + 64], rax          
    mov     edx, 32512
    xor     ecx, ecx
    call    r14
    mov     qword ptr [rbx + 40], rax          
    and     qword ptr [rbx + 48], 0
    mov     rcx, rbx
    call    r15

    mov     r14, qword ptr [rip + __imp_GetSystemMetrics]
    xor     ecx, ecx
    call    r14
    mov     ebp, eax                           
    mov     ebx, 1
    mov     ecx, 1
    call    r14
    add     eax, -32                           # screen height - 32

    # Prepare CreateWindowExW for main window
    mov     qword ptr [rsp + 80], rsi          
    movups  xmmword ptr [rsp + 64], xmm6
    mov     dword ptr [rsp + 48], ebp          
    mov     dword ptr [rsp + 40], eax          
    and     qword ptr [rsp + 88], 0
    mov     dword ptr [rsp + 56], 32           
    and     dword ptr [rsp + 32], 0            

    lea     r8, [rip + .L.str.1]               
    mov     ecx, 128                           
    mov     rdx, rdi                           
    mov     r9d, -1879048192                   
    call    qword ptr [rip + __imp_CreateWindowExW]
    mov     qword ptr [rip + g_hwndMain], rax

    test    rax, rax
    je      .LRunApp_Exit

    # Message loop
    lea     rsi, [rsp + 112]                   
    mov     rdi, qword ptr [rip + __imp_GetMessageW]
    mov     rbx, qword ptr [rip + __imp_TranslateMessage]
    mov     r14, qword ptr [rip + __imp_DispatchMessageW]
.LRunApp_Loop:
    mov     rcx, rsi
    xor     edx, edx
    xor     r8d, r8d
    xor     r9d, r9d
    call    rdi                                
    test    eax, eax
    jle     .LRunApp_LeaveLoop
    mov     rcx, rsi
    call    rbx                                
    mov     rcx, rsi
    call    r14                                
    jmp     .LRunApp_Loop

.LRunApp_LeaveLoop:
    xor     ebx, ebx

.LRunApp_Exit:
    mov     eax, ebx
    movaps  xmm6, xmmword ptr [rsp + 272]      
    .seh_startepilogue
    add     rsp, 296
    pop     rbx
    pop     rbp
    pop     rdi
    pop     rsi
    pop     r14
    pop     r15
    .seh_endepilogue
    ret
.seh_endproc

    .def    MainWndProc;
    .scl    3;
    .type   32;
    .endef
MainWndProc:                                    

.seh_proc MainWndProc

    push    r15
    .seh_pushreg r15
    push    r14
    .seh_pushreg r14
    push    rsi
    .seh_pushreg rsi
    push    rdi
    .seh_pushreg rdi
    push    rbp
    .seh_pushreg rbp
    push    rbx
    .seh_pushreg rbx
    sub     rsp, 664
    .seh_stackalloc 664
    .seh_endprologue

    cmp     edx, 16                             # WM_CLOSE
    je      .LBB3_110

    mov     rbx, r9
    mov     r14, r8
    mov     rdi, rcx
    cmp     edx, 274                            # WM_SYSCOMMAND
    jne     .LBB3_3

    mov     eax, r14d
    and     eax, 65520
    cmp     eax, 61536                          
    je      .LBB3_110
.LBB3_3:
    mov     eax, dword ptr [rip + g_uShellHookMsg]
    test    eax, eax
    sete    cl
    cmp     edx, eax
    setne   al
    or      al, cl
    jne     .LBB3_7

    # Shell hook dispatch
    xor     esi, esi
    lea     rax, [r14 - 1]
    cmp     rax, 5
    ja      .LBB3_21

    lea     rcx, [rip + .LJTI3_0]
    movsxd  rax, dword ptr [rcx + 4*rax]
    add     rax, rcx
    jmp     rax

.LBB3_6:
    mov     rcx, rbx
    call    Taskbar_AddWindow
    jmp     .LBB3_110

.LBB3_7:
    cmp     edx, 512                            
    je      .LBB3_73

    cmp     edx, 2                              # WM_DESTROY
    je      .LBB3_40

    cmp     edx, 5                              # WM_SIZE
    je      .LBB3_76

    cmp     edx, 20                             # WM_ERASEBKGND
    je      .LBB3_64

    cmp     edx, 43                             # WM_DRAWITEM
    je      .LBB3_71

    cmp     edx, 78                             # WM_NOTIFY
    je      .LBB3_66

    cmp     edx, 273                            # WM_COMMAND
    je      .LBB3_35

    cmp     edx, 275                            # WM_TIMER
    je      .LBB3_56

    cmp     edx, 312                            # WM_CTLCOLORBTN
    je      .LBB3_55

    cmp     edx, 1                              # WM_CREATE
    jne     .LBB3_65

    cmp     qword ptr [rip + g_hDwmApi], 0
    jne     .LBB3_20

    lea     rcx, [rip + .L.str.7]               
    call    qword ptr [rip + __imp_LoadLibraryW]
    mov     qword ptr [rip + g_hDwmApi], rax
    test    rax, rax
    je      .LBB3_20

    lea     rdx, [rip + .L.str.8]               
    mov     rcx, rax
    call    qword ptr [rip + __imp_GetProcAddress]
    mov     qword ptr [rip + pDwmGetWindowAttribute], rax

.LBB3_20:
    mov     rbx, qword ptr [rip + __imp_CreateSolidBrush]
    xor     esi, esi
    xor     ecx, ecx
    call    rbx
    mov     qword ptr [rip + g_hbrBg], rax
    mov     ecx, 1579032                        
    call    rbx
    mov     qword ptr [rip + g_hbrBtn], rax

    mov     rcx, rdi
    call    PositionTaskbarAndTiles
    call    UpdateClock

    lea     rcx, [rip + .L.str.3]               
    call    qword ptr [rip + __imp_RegisterWindowMessageW]
    mov     dword ptr [rip + g_uShellHookMsg], eax

    mov     rcx, rdi
    call    qword ptr [rip + __imp_RegisterShellHookWindow]

    lea     rcx, [rip + EnumInitProc]
    xor     edx, edx
    call    qword ptr [rip + __imp_EnumWindows]

    call    qword ptr [rip + __imp_GetForegroundWindow]
    mov     rcx, rax
    call    Taskbar_SetActive

    mov     edx, 2003
    mov     rcx, rdi
    mov     r8d, 250
    jmp     .LBB3_75

.LBB3_21:
    cmp     r14, 32772                          
    jne     .LBB3_111
.LBB3_22:
    mov     rcx, rbx
    call    Taskbar_SetActive
    jmp     .LBB3_110

.LBB3_23:
    mov     rcx, qword ptr [rip + g_hwndTaskToolbar]
    test    rcx, rcx
    sete    al
    test    rbx, rbx
    sete    dl
    xor     esi, esi
    or      dl, al
    jne     .LBB3_111

    mov     eax, dword ptr [rip + g_TaskButtonCount]
    test    eax, eax
    cmovle  eax, esi
    lea     r14, [rip + g_TaskButtons+16]
    xor     edi, edi
.LBB3_25:                                       # loop over task buttons
    cmp     rax, rdi
    je      .LBB3_111

    cmp     qword ptr [r14 - 16], rbx
    je      .LBB3_77

    inc     rdi
    add     r14, 16
    jmp     .LBB3_25

.LBB3_28:
    xor     esi, esi
    cmp     qword ptr [rip + g_hwndTaskToolbar], 0
    je      .LBB3_111

    mov     eax, dword ptr [rip + g_TaskButtonCount]
    test    eax, eax
    cmovle  eax, esi
    shl     rax, 4
    add     rax, 16
    lea     r14, [rip + g_TaskButtons]
    xor     ecx, ecx
.LBB3_30:
    lea     r15, [rcx + 16]
    cmp     rax, r15
    je      .LBB3_111

    cmp     qword ptr [rcx + r14], rbx
    mov     rcx, r15
    jne     .LBB3_30

    lea     rsi, [rsp + 144]
    mov     ecx, 128
    xor     eax, eax
    mov     rdi, rsi
    rep stosd es:[rdi], eax
    mov     rcx, rbx
    mov     rdx, rsi
    mov     r8d, 255
    call    qword ptr [rip + __imp_GetWindowTextW]
    test    eax, eax
    jg      .LBB3_34

    lea     rdx, [rip + .L.str.4]
    lea     rcx, [rsp + 144]
    mov     r8d, 256
    call    qword ptr [rip + __imp_lstrcpynW]
.LBB3_34:
    xorps   xmm0, xmm0
    lea     r9, [rsp + 96]
    movups  xmmword ptr [r9 + 24], xmm0
    movups  xmmword ptr [r9 + 8], xmm0
    and     qword ptr [r9 + 40], 0
    movabs  rax, 8589934640
    mov     qword ptr [r9], rax
    mov     qword ptr [r9 + 32], rsi
    mov     rcx, qword ptr [rip + g_hwndTaskToolbar]
    movsxd  r8, dword ptr [r15 + r14 - 8]
    mov     edx, 1088
    call    qword ptr [rip + __imp_SendMessageW]

    mov     rcx, qword ptr [rip + g_hwndTaskToolbar]
    xor     esi, esi
    xor     edx, edx
    mov     r8d, 1
    call    qword ptr [rip + __imp_InvalidateRect]
    jmp     .LBB3_111

.LBB3_35:
    cmp     r14w, 1100
    je      .LBB3_81

    movzx   eax, r14w
    cmp     eax, 1000
    jne     .LBB3_91

    mov     rcx, qword ptr [rip + g_hwndStartMenu]
    test    rcx, rcx
    je      .LBB3_99

    call    qword ptr [rip + __imp_IsWindow]
    test    eax, eax
    je      .LBB3_99

    call    CloseStartMenu
    jmp     .LBB3_110

.LBB3_40:
    # WM_DESTROY: cleanup
    mov     rsi, qword ptr [rip + __imp_KillTimer]
    mov     edx, 2001
    mov     rcx, rdi
    call    rsi
    mov     edx, 2002
    mov     rcx, rdi
    call    rsi
    mov     edx, 2003
    mov     rcx, rdi
    call    rsi

    cmp     dword ptr [rip + g_uShellHookMsg], 0
    je      .LBB3_42

    mov     rcx, rdi
    call    qword ptr [rip + __imp_DeregisterShellHookWindow]
.LBB3_42:
    mov     rcx, qword ptr [rip + g_hwndStartMenu]
    test    rcx, rcx
    je      .LBB3_44

    call    qword ptr [rip + __imp_DestroyWindow]
    and     qword ptr [rip + g_hwndStartMenu], 0
.LBB3_44:
    mov     rcx, qword ptr [rip + g_hwndTaskToolbar]
    test    rcx, rcx
    je      .LBB3_48

    mov     edx, 1048
    xor     r8d, r8d
    xor     r9d, r9d
    call    qword ptr [rip + __imp_SendMessageW]
    mov     esi, eax
    mov     rdi, qword ptr [rip + __imp_SendMessageW]
.LBB3_46:
    test    esi, esi
    jle     .LBB3_48

    dec     rsi
    mov     rcx, qword ptr [rip + g_hwndTaskToolbar]
    mov     edx, 1046
    mov     r8, rsi
    xor     r9d, r9d
    call    rdi
    jmp     .LBB3_46

.LBB3_48:
    lea     rdi, [rip + g_TaskButtons]
    mov     ecx, 2048
    xor     eax, eax

    rep     stosb   byte ptr es:[rdi], al

    and     dword ptr [rip + g_TaskButtonCount], 0

    mov     rcx, qword ptr [rip + g_hbrBg]
    test    rcx, rcx
    je      .LBB3_50

    call    qword ptr [rip + __imp_DeleteObject]
    and     qword ptr [rip + g_hbrBg], 0
.LBB3_50:
    mov     rcx, qword ptr [rip + g_hbrBtn]
    test    rcx, rcx
    je      .LBB3_52

    call    qword ptr [rip + __imp_DeleteObject]
    and     qword ptr [rip + g_hbrBtn], 0
.LBB3_52:
    mov     rcx, qword ptr [rip + g_hDwmApi]
    test    rcx, rcx
    je      .LBB3_54

    and     qword ptr [rip + pDwmGetWindowAttribute], 0
    call    qword ptr [rip + __imp_FreeLibrary]
    and     qword ptr [rip + g_hDwmApi], 0
.LBB3_54:
    xor     esi, esi
    xor     ecx, ecx
    call    qword ptr [rip + __imp_PostQuitMessage]
    jmp     .LBB3_111

.LBB3_55:
    mov     rcx, r14
    mov     edx, 1
    call    qword ptr [rip + __imp_SetBkMode]
    mov     rcx, r14
    mov     edx, 16777215
    call    qword ptr [rip + __imp_SetTextColor]
    mov     rsi, qword ptr [rip + g_hbrBg]
    jmp     .LBB3_111

.LBB3_56:
    cmp     r14, 2002
    je      .LBB3_84

    cmp     r14, 2001
    je      .LBB3_83

    xor     esi, esi
    cmp     r14, 2003
    jne     .LBB3_111

    test    byte ptr [rip + g_autoHidden], 1
    je      .LBB3_111

    lea     rsi, [rsp + 144]
    mov     rcx, rsi
    call    qword ptr [rip + __imp_GetCursorPos]
    mov     ecx, 1
    call    qword ptr [rip + __imp_GetSystemMetrics]
    dec     eax
    cmp     dword ptr [rsi + 4], eax
    jl      .LBB3_110

    cmp     qword ptr [rip + g_hwndMain], 0
    je      .LBB3_110

    test    byte ptr [rip + g_autoHidden], 1
    je      .LBB3_110

    mov     ecx, 1
    call    qword ptr [rip + __imp_GetSystemMetrics]
    mov     rcx, qword ptr [rip + g_hwndMain]
    lea     r9d, [rax - 32]
    and     dword ptr [rsp + 40], 0
    mov     dword ptr [rsp + 48], 81
    and     dword ptr [rsp + 32], 0
    mov     rdx, -1
    xor     r8d, r8d
    call    qword ptr [rip + __imp_SetWindowPos]
    mov     byte ptr [rip + g_autoHidden], 0
    jmp     .LBB3_110

.LBB3_64:
    lea     rsi, [rsp + 144]
    mov     rcx, rdi
    mov     rdx, rsi
    call    qword ptr [rip + __imp_GetClientRect]
    mov     r8, qword ptr [rip + g_hbrBg]
    mov     rcx, r14
    mov     rdx, rsi
    call    qword ptr [rip + __imp_FillRect]
    jmp     .LBB3_72

.LBB3_65:
    mov     rcx, rdi
    mov     r8, r14
    mov     r9, rbx
    .seh_startepilogue
    add     rsp, 664
    pop     rbx
    pop     rbp
    pop     rdi
    pop     rsi
    pop     r14
    pop     r15
    .seh_endepilogue
    rex64 jmp qword ptr [rip + __imp_DefWindowProcW] 

.LBB3_66:
    mov     rcx, qword ptr [rbx]
    cmp     rcx, qword ptr [rip + g_hwndTaskToolbar]
    jne     .LBB3_110

    cmp     dword ptr [rbx + 16], -12
    jne     .LBB3_110

    mov     eax, dword ptr [rbx + 24]
    cmp     eax, 65537
    je      .LBB3_112

    cmp     eax, 1
    jne     .LBB3_110

    lea     rsi, [rsp + 144]
    mov     rdx, rsi
    call    qword ptr [rip + __imp_GetClientRect]
    mov     rcx, qword ptr [rbx + 32]
    mov     r8, qword ptr [rip + g_hbrBg]
    mov     rdx, rsi
    call    qword ptr [rip + __imp_FillRect]
    mov     esi, 32
    jmp     .LBB3_111

.LBB3_71:
    mov     rcx, rbx
    call    DrawDarkButton
.LBB3_72:
    mov     esi, 1
    jmp     .LBB3_111

.LBB3_73:
    cmp     byte ptr [rip + g_autoHidden], 0
    jne     .LBB3_110

    xor     esi, esi
    mov     edx, 2002
    mov     rcx, rdi
    mov     r8d, 30000                          # Auto-hide taskbar 30000ms (30 seconds)
.LBB3_75:
    xor     r9d, r9d
    call    qword ptr [rip + __imp_SetTimer]
    jmp     .LBB3_111

.LBB3_76:
    mov     rcx, rdi
    call    PositionTaskbarAndTiles
    jmp     .LBB3_110

.LBB3_77:
    mov     edx, 1046
    mov     r8, rdi
    xor     r9d, r9d
    call    qword ptr [rip + __imp_SendMessageW]
    movsxd  rax, dword ptr [rip + g_TaskButtonCount]
    dec     rax
.LBB3_78:
    cmp     rdi, rax
    jge     .LBB3_80

    inc     rdi
    movaps  xmm0, xmmword ptr [r14]
    movaps  xmmword ptr [r14 - 16], xmm0
    add     r14, 16
    jmp     .LBB3_78

.LBB3_80:
    mov     dword ptr [rip + g_TaskButtonCount], eax
    jmp     .LBB3_110

.LBB3_81:
    shr     r14, 16
    test    r14w, r14w
    jne     .LBB3_110

    xor     eax, eax
    cmp     dword ptr [rip + g_clockShowDate], 0
    sete    al
    mov     dword ptr [rip + g_clockShowDate], eax
.LBB3_83:
    call    UpdateClock
    jmp     .LBB3_110

.LBB3_84:
    mov     edx, 2002
    mov     rcx, rdi
    call    qword ptr [rip + __imp_KillTimer]
    cmp     byte ptr [rip + g_autoHidden], 0
    jne     .LBB3_110

    lea     rsi, [rsp + 96]
    mov     rcx, rsi
    call    qword ptr [rip + __imp_GetCursorPos]
    lea     rbx, [rsp + 144]
    mov     rcx, rdi
    mov     rdx, rbx
    call    qword ptr [rip + __imp_GetWindowRect]
    mov     rdx, qword ptr [rsi]
    mov     rcx, rbx
    call    qword ptr [rip + __imp_PtInRect]
    test    eax, eax
    jne     .LBB3_110

    cmp     qword ptr [rip + g_hwndMain], 0
    je      .LBB3_89

    test    byte ptr [rip + g_autoHidden], 1
    jne     .LBB3_89

    mov     ecx, 1
    call    qword ptr [rip + __imp_GetSystemMetrics]
    mov     rcx, qword ptr [rip + g_hwndMain]
    and     dword ptr [rsp + 40], 0
    mov     dword ptr [rsp + 48], 81
    and     dword ptr [rsp + 32], 0
    mov     rdx, -1
    xor     r8d, r8d
    mov     r9d, eax
    call    qword ptr [rip + __imp_SetWindowPos]
    mov     byte ptr [rip + g_autoHidden], 1
.LBB3_89:
    mov     rcx, qword ptr [rip + g_hwndStartMenu]
    test    rcx, rcx
    je      .LBB3_110

    call    qword ptr [rip + __imp_DestroyWindow]
    and     qword ptr [rip + g_hwndStartMenu], 0
    jmp     .LBB3_110

.LBB3_91:
    lea     ecx, [rax - 6000]
    xor     esi, esi
    cmp     ecx, 127
    ja      .LBB3_111

    mov     ecx, dword ptr [rip + g_TaskButtonCount]
    test    ecx, ecx
    cmovle  ecx, esi
    shl     rcx, 4
    mov     r8, -16
    lea     rdx, [rip + g_TaskButtons]
.LBB3_93:
    lea     r9, [r8 + 16]
    cmp     rcx, r9
    je      .LBB3_111

    cmp     dword ptr [r8 + rdx + 24], eax
    mov     r8, r9
    jne     .LBB3_93

    mov     rsi, qword ptr [r9 + rdx]
    test    rsi, rsi
    je      .LBB3_110

    mov     rcx, rsi
    call    qword ptr [rip + __imp_IsWindow]
    test    eax, eax
    je      .LBB3_110

    mov     rcx, rsi
    call    qword ptr [rip + __imp_IsIconic]
    test    eax, eax
    je      .LBB3_115

    mov     rcx, rsi
    mov     edx, 9
    call    qword ptr [rip + __imp_ShowWindow]
    mov     rcx, rsi
    jmp     .LBB3_109

.LBB3_99:
    mov     rcx, qword ptr [rip + g_hwndTileStart]
    lea     rdx, [rsp + 144]
    call    qword ptr [rip + __imp_GetWindowRect]
    mov     eax, 8
    xor     ecx, ecx
    xor     edx, edx
.LBB3_100:
    mov     r8d, 6
    cmp     rdx, 6
    je      .LBB3_104

    cmp     rdx, 8
    je      .LBB3_104

    cmp     rdx, 10
    je      .LBB3_105

    mov     ecx, 1
    mov     r8d, 26
.LBB3_104:
    add     eax, r8d
    inc     rdx
    jmp     .LBB3_100

.LBB3_105:
    lea     edi, [rax - 2]
    test    ecx, ecx
    cmove   edi, eax
    mov     esi, dword ptr [rsp + 144]
    mov     ebx, dword ptr [rsp + 148]
    sub     ebx, edi
    jns     .LBB3_107

    mov     ebx, dword ptr [rsp + 156]
.LBB3_107:
    mov     r14, qword ptr [rip + g_hwndMain]
    xor     ecx, ecx
    call    qword ptr [rip + __imp_GetModuleHandleW]
    mov     qword ptr [rsp + 80], rax
    mov     qword ptr [rsp + 64], r14
    mov     dword ptr [rsp + 56], edi
    and     qword ptr [rsp + 88], 0
    mov     dword ptr [rsp + 40], ebx
    and     qword ptr [rsp + 72], 0
    mov     dword ptr [rsp + 32], esi
    mov     dword ptr [rsp + 48], 260
    lea     rdx, [rip + .L.str.2]
    lea     r8,  [rip + .L.str.1]
    mov     ecx, 136
    mov     r9d, -2139095040
    call    qword ptr [rip + __imp_CreateWindowExW]
    mov     qword ptr [rip + g_hwndStartMenu], rax
    test    rax, rax
    je      .LBB3_110

    mov     rcx, rax
    mov     edx, 5
    call    qword ptr [rip + __imp_ShowWindow]
    mov     rcx, qword ptr [rip + g_hwndStartMenu]
.LBB3_109:
    call    qword ptr [rip + __imp_SetForegroundWindow]
.LBB3_110:
    xor     esi, esi
.LBB3_111:
    mov     rax, rsi
    .seh_startepilogue
    add     rsp, 664
    pop     rbx
    pop     rbp
    pop     rdi
    pop     rsi
    pop     r14
    pop     r15
    .seh_endepilogue
    ret

.LBB3_112:
    mov     bpl, byte ptr [rbx + 64]
    lea     rdx, [rbx + 40]
    test    bpl, 8
    mov     rcx, qword ptr [rbx + 32]
    lea     rax, [rip + g_hbrBtn]
    lea     r8, [rip + g_hbrBg]
    cmovne  r8, rax
    mov     r8, qword ptr [r8]
    call    qword ptr [rip + __imp_FillRect]

    lea     rsi, [rsp + 144]
    mov     ecx, 128
    xor     eax, eax
    mov     rdi, rsi
    rep stosd es:[rdi], eax

    mov     rcx, qword ptr [rbx]
    mov     r8, qword ptr [rbx + 56]
    mov     edx, 1099
    mov     r9, rsi
    call    qword ptr [rip + __imp_SendMessageW]

    mov     rcx, qword ptr [rbx + 32]
    mov     edx, 16777215
    call    qword ptr [rip + __imp_SetTextColor]
    mov     rcx, qword ptr [rbx + 32]
    mov     edx, 1
    call    qword ptr [rip + __imp_SetBkMode]

    movups  xmm0, xmmword ptr [rbx + 40]
    lea     rdi, [rsp + 96]
    movaps  xmmword ptr [rdi], xmm0
    mov     rcx, rdi
    mov     edx, -6
    mov     r8d, -2
    call    qword ptr [rip + __imp_InflateRect]

    mov     rcx, qword ptr [rbx + 32]
    mov     dword ptr [rsp + 32], 32805
    mov     rdx, rsi
    mov     r8d, -1
    mov     r9, rdi
    call    qword ptr [rip + __imp_DrawTextW]

    test    bpl, 8
    je      .LBB3_114

    xor     ecx, 0
    mov     edx, 1
    mov     r8d, 7895160
    call    qword ptr [rip + __imp_CreatePen]
    mov     rsi, rax
    mov     rcx, qword ptr [rbx + 32]
    mov     r15, qword ptr [rip + __imp_SelectObject]
    mov     rdx, rax
    call    r15
    mov     rdi, rax

    mov     r14, qword ptr [rbx + 32]
    mov     ecx, 5
    call    qword ptr [rip + __imp_GetStockObject]
    mov     rcx, r14
    mov     rdx, rax
    call    r15

    mov     rcx, qword ptr [rbx + 32]
    mov     edx, dword ptr [rbx + 40]
    mov     r8d, dword ptr [rbx + 44]
    mov     r9d, dword ptr [rbx + 48]
    mov     eax, dword ptr [rbx + 52]
    mov     dword ptr [rsp + 32], eax
    call    qword ptr [rip + __imp_Rectangle]

    mov     rcx, qword ptr [rbx + 32]
    mov     rdx, rdi
    call    r15
    mov     rcx, rsi
    call    qword ptr [rip + __imp_DeleteObject]
.LBB3_114:
    mov     esi, 4
    jmp     .LBB3_111

.LBB3_115:
    call    qword ptr [rip + __imp_GetForegroundWindow]
    cmp     rax, rsi
    je      .LBB3_118

    mov     rcx, rsi
    xor     edx, edx
    call    qword ptr [rip + __imp_GetWindowThreadProcessId]
    mov     edi, eax
    call    qword ptr [rip + __imp_GetCurrentThreadId]
    mov     ebx, eax
    mov     ecx, -1
    call    qword ptr [rip + __imp_AllowSetForegroundWindow]
    test    edi, edi
    sete    al
    cmp     edi, ebx
    sete    cl
    or      cl, al
    je      .LBB3_119

    mov     rcx, rsi
    call    qword ptr [rip + __imp_SetForegroundWindow]
    mov     rcx, rsi
    call    qword ptr [rip + __imp_BringWindowToTop]
    mov     rcx, rsi
    call    qword ptr [rip + __imp_SetFocus]
    jmp     .LBB3_110

.LBB3_118:
    mov     rcx, rsi
    mov     edx, 6
    call    qword ptr [rip + __imp_ShowWindow]
    jmp     .LBB3_110

.LBB3_119:
    mov     r14, qword ptr [rip + __imp_AttachThreadInput]
    mov     ecx, ebx
    mov     edx, edi
    mov     r8d, 1
    call    r14

    mov     rcx, rsi
    call    qword ptr [rip + __imp_SetForegroundWindow]
    mov     rcx, rsi
    call    qword ptr [rip + __imp_BringWindowToTop]
    mov     rcx, rsi
    call    qword ptr [rip + __imp_SetFocus]

    xor     esi, esi
    mov     ecx, ebx
    mov     edx, edi
    xor     r8d, r8d
    call    r14
    jmp     .LBB3_111

    .section    .rdata,"dr"
    .p2align    2, 0x0
.LJTI3_0:
    .long   .LBB3_6-.LJTI3_0
    .long   .LBB3_23-.LJTI3_0
    .long   .LBB3_111-.LJTI3_0
    .long   .LBB3_22-.LJTI3_0
    .long   .LBB3_111-.LJTI3_0
    .long   .LBB3_28-.LJTI3_0
    .text
    .seh_endproc

    # =========================================================
    # StartMenuWndProc 
    # =========================================================
    .def    StartMenuWndProc;
    .scl    3;
    .type   32;
    .endef
StartMenuWndProc:                               

.seh_proc StartMenuWndProc

    push    r15
    .seh_pushreg r15
    push    r14
    .seh_pushreg r14
    push    r13
    .seh_pushreg r13
    push    r12
    .seh_pushreg r12
    push    rsi
    .seh_pushreg rsi
    push    rdi
    .seh_pushreg rdi
    push    rbp
    .seh_pushreg rbp
    push    rbx
    .seh_pushreg rbx
    sub     rsp, 120
    .seh_stackalloc 120
    .seh_endprologue

    mov     rdi, r8
    cmp     edx, 273                            
    je      .LBB4_13

    mov     rsi, rcx
    cmp     edx, 2                              
    je      .LBB4_38

    cmp     edx, 6                              
    je      .LBB4_33

    cmp     edx, 20                             
    je      .LBB4_41

    cmp     edx, 43                             
    je      .LBB4_12

    cmp     edx, 1                              
    jne     .LBB4_40

    # ----------------------------------
    # WM_CREATE: build start menu items
    # ----------------------------------
    lea     rdi, [rsp + 104]
    mov     rcx, rsi
    mov     rdx, rdi
    call    qword ptr [rip + __imp_GetClientRect]
    mov     ebp, dword ptr [rdi + 8]
    sub     ebp, dword ptr [rdi]
    add     ebp, -8
    mov     r14d, 4
    xor     r15d, r15d
    lea     r12, [rip + g_startMenuItems]
    lea     rdi, [rip + g_startItemWnds]
.LBB4_7:
    cmp     r15, 80
    je      .LBB4_11

    mov     eax, 6
    cmp     dword ptr [r12 + 2*r15 + 12], 0
    jne     .LBB4_10

    lea     rax, [r15 + r15]
    mov     rbx, qword ptr [rax + r12]          
    movsxd  r13, dword ptr [r12 + 2*r15 + 8]    
    xor     ecx, ecx
    call    qword ptr [rip + __imp_GetModuleHandleW]
    mov     qword ptr [rsp + 80], rax
    mov     qword ptr [rsp + 72], r13
    mov     qword ptr [rsp + 64], rsi
    and     qword ptr [rsp + 88], 0
    mov     dword ptr [rsp + 48], ebp
    mov     dword ptr [rsp + 40], r14d
    mov     dword ptr [rsp + 56], 24
    mov     dword ptr [rsp + 32], 4
    xor     ecx, ecx
    lea     rdx, [rip + .L.str.9]               
    mov     r8, rbx
    mov     r9d, 1342177291
    call    qword ptr [rip + __imp_CreateWindowExW]
    mov     qword ptr [r15 + rdi], rax
    mov     eax, 26
.LBB4_10:
    add     r14d, eax
    add     r15, 8
    jmp     .LBB4_7

.LBB4_33:
    test    di, di
    jne     .LBB4_34

    test    r9, r9
    je      .LBB4_32

    cmp     rsi, r9
    je      .LBB4_34

    mov     rcx, rsi
    mov     rdx, r9
    call    qword ptr [rip + __imp_IsChild]
    test    eax, eax
    je      .LBB4_32
    jmp     .LBB4_34

.LBB4_12:
    mov     rcx, r9
    call    DrawDarkButton
    jmp     .LBB4_42

.LBB4_41:
    lea     rbx, [rsp + 104]
    mov     rcx, rsi
    mov     rdx, rbx
    call    qword ptr [rip + __imp_GetClientRect]
    mov     r8, qword ptr [rip + g_hbrBg]
    mov     rcx, rdi
    mov     rdx, rbx
    call    qword ptr [rip + __imp_FillRect]
.LBB4_42:
    mov     eax, 1
    jmp     .LBB4_43

.LBB4_40:
    mov     rcx, rsi
    mov     r8, rdi
    .seh_startepilogue
    add     rsp, 120
    pop     rbx
    pop     rbp
    pop     rdi
    pop     rsi
    pop     r12
    pop     r13
    pop     r14
    pop     r15
    .seh_endprologue
    rex64 jmp    qword ptr [rip + __imp_DefWindowProcW] 

.LBB4_11:
    mov     rcx, rsi
    call    qword ptr [rip + __imp_SetForegroundWindow]
    jmp     .LBB4_34

.LBB4_38:
    # =============================================
    # WM_DESTROY 
    # =============================================
    cmp     rsi, qword ptr [rip + g_hwndStartMenu]
    jne     .LBB4_34

    and     qword ptr [rip + g_hwndStartMenu], 0

    lea     rbx, [rip + g_startItemWnds]        
    mov     ecx, 10                             
    xor     r14, r14                            

.LBB4_cleanup_loop:
    cmp     r14, 10
    jge     .LBB4_34

    mov     r15, qword ptr [rbx + r14*8]        
    test    r15, r15
    je      .LBB4_cleanup_next

    mov     rcx, r15
    call    qword ptr [rip + __imp_DestroyWindow]

    mov     qword ptr [rbx + r14*8], 0

.LBB4_cleanup_next:
    inc     r14
    jmp     .LBB4_cleanup_loop

.LBB4_13:
    movzx   eax, di
    add     eax, -4002
    cmp     eax, 10
    ja      .LBB4_32

    lea     rcx, [rip + .LJTI4_0]
    movsxd  rax, dword ptr [rcx + 4*rax]
    add     rax, rcx
    jmp     rax

.LBB4_15:
    and     qword ptr [rsp + 32], 0
    mov     dword ptr [rsp + 40], 1
    lea     rdx, [rip + .L.str.21]
    lea     r8,  [rip + .L.str.22]
    jmp     .LBB4_16

.LBB4_21:
    and     qword ptr [rsp + 32], 0
    mov     dword ptr [rsp + 40], 1
    lea     rdx, [rip + .L.str.21]
    lea     r8,  [rip + .L.str.27]
    jmp     .LBB4_16

.LBB4_17:
    and     qword ptr [rsp + 32], 0
    mov     dword ptr [rsp + 40], 1
    lea     rdx, [rip + .L.str.21]
    lea     r8,  [rip + .L.str.23]
    jmp     .LBB4_16

.LBB4_22:
    mov     rcx, qword ptr [rip + g_hwndMain]
    lea     rdx, [rip + .L.str.28]
    lea     r8,  [rip + .L.str.29]
    mov     r9d, 262179
    call    qword ptr [rip + __imp_MessageBoxW]
    cmp     eax, 6
    je      .LBB4_23

    cmp     eax, 7
    jne     .LBB4_32

    mov     esi, 2
    jmp     .LBB4_26

.LBB4_31:
    xor     ecx, ecx
    call    qword ptr [rip + __imp_PostQuitMessage]
    jmp     .LBB4_32

.LBB4_18:
    and     qword ptr [rsp + 32], 0
    mov     dword ptr [rsp + 40], 1
    lea     rdx, [rip + .L.str.21]
    lea     r8,  [rip + .L.str.24]
    jmp     .LBB4_16

.LBB4_19:
    and     qword ptr [rsp + 32], 0
    mov     dword ptr [rsp + 40], 1
    lea     rdx, [rip + .L.str.21]
    lea     r8,  [rip + .L.str.25]
    jmp     .LBB4_16

.LBB4_20:
    and     qword ptr [rsp + 32], 0
    mov     dword ptr [rsp + 40], 1
    lea     rdx, [rip + .L.str.21]
    lea     r8,  [rip + .L.str.26]
.LBB4_16:
    xor     ecx, ecx
    xor     r9d, r9d
    call    qword ptr [rip + __imp_ShellExecuteW]
.LBB4_32:
    call    CloseStartMenu
.LBB4_34:
    xor     eax, eax
.LBB4_43:
    .seh_startepilogue
    add     rsp, 120
    pop     rbx
    pop     rbp
    pop     rdi
    pop     rsi
    pop     r12
    pop     r13
    pop     r14
    pop     r15
    .seh_endepilogue
    ret

.LBB4_23:
    mov     esi, 8
.LBB4_26:
    call    qword ptr [rip + __imp_GetCurrentProcess]
    lea     r8, [rsp + 96]
    mov     rcx, rax
    mov     edx, 40
    call    qword ptr [rip + __imp_OpenProcessToken]
    test    eax, eax
    je      .LBB4_30

    lea     r8, [rsp + 108]
    lea     rdx, [rip + .L.str.30]
    xor     ecx, ecx
    call    qword ptr [rip + __imp_LookupPrivilegeValueW]
    test    eax, eax
    je      .LBB4_29

    lea     r8, [rsp + 104]
    mov     dword ptr [r8], 1
    mov     dword ptr [r8 + 12], 2
    mov     rcx, qword ptr [rsp + 96]
    xorps   xmm0, xmm0
    movups  xmmword ptr [rsp + 32], xmm0
    xor     edx, edx
    xor     r9d, r9d
    call    qword ptr [rip + __imp_AdjustTokenPrivileges]
.LBB4_29:
    mov     rcx, qword ptr [rsp + 96]
    call    qword ptr [rip + __imp_CloseHandle]
.LBB4_30:
    mov     ecx, esi
    xor     edx, edx
    call    qword ptr [rip + __imp_ExitWindowsEx]
    jmp     .LBB4_32

    .section    .rdata,"dr"
    .p2align    2, 0x0
.LJTI4_0:
    .long   .LBB4_15-.LJTI4_0
    .long   .LBB4_17-.LJTI4_0
    .long   .LBB4_18-.LJTI4_0
    .long   .LBB4_19-.LJTI4_0
    .long   .LBB4_20-.LJTI4_0
    .long   .LBB4_21-.LJTI4_0
    .long   .LBB4_32-.LJTI4_0
    .long   .LBB4_32-.LJTI4_0
    .long   .LBB4_32-.LJTI4_0
    .long   .LBB4_22-.LJTI4_0
    .long   .LBB4_31-.LJTI4_0
    .text
    .seh_endproc

    .def    Taskbar_AddWindow;
    .scl    3;
    .type   32;
    .endef
Taskbar_AddWindow:                              

.seh_proc Taskbar_AddWindow

    push    rsi
    .seh_pushreg rsi
    push    rdi
    .seh_pushreg rdi
    push    rbx
    .seh_pushreg rbx
    sub     rsp, 576
    .seh_stackalloc 576
    .seh_endprologue

    cmp     qword ptr [rip + g_hwndTaskToolbar], 0
    je      .LBB5_21

    mov     rsi, rcx
    call    qword ptr [rip + __imp_IsWindow]
    test    eax, eax
    je      .LBB5_21

    mov     rcx, rsi
    call    qword ptr [rip + __imp_IsWindowVisible]
    test    eax, eax
    je      .LBB5_21

    cmp     rsi, qword ptr [rip + g_hwndMain]
    je      .LBB5_21

    cmp     rsi, qword ptr [rip + g_hwndStartMenu]
    je      .LBB5_21

    xorps   xmm0, xmm0
    lea     rdi, [rsp + 64]
    movaps  xmmword ptr [rdi + 112], xmm0
    movaps  xmmword ptr [rdi + 96], xmm0
    movaps  xmmword ptr [rdi + 80], xmm0
    movaps  xmmword ptr [rdi + 64], xmm0
    movaps  xmmword ptr [rdi + 48], xmm0
    movaps  xmmword ptr [rdi + 32], xmm0
    movaps  xmmword ptr [rdi + 16], xmm0
    movaps  xmmword ptr [rdi], xmm0

    mov     rcx, rsi
    mov     rdx, rdi
    mov     r8d, 63
    call    qword ptr [rip + __imp_GetClassNameW]

    lea     rdx, [rip + .L.str.5]
    mov     rcx, rdi
    call    qword ptr [rip + __imp_lstrcmpiW]
    test    eax, eax
    je      .LBB5_21

    lea     rdx, [rip + .L.str.6]
    lea     rcx, [rsp + 64]
    call    qword ptr [rip + __imp_lstrcmpiW]
    test    eax, eax
    je      .LBB5_21

    mov     rax, qword ptr [rip + pDwmGetWindowAttribute]
    test    rax, rax
    je      .LBB5_10

    lea     r8, [rsp + 64]
    and     dword ptr [r8], 0
    mov     rcx, rsi
    mov     edx, 14
    mov     r9d, 4
    call    rax
    test    eax, eax
    js      .LBB5_10

    cmp     dword ptr [rsp + 64], 0
    jne     .LBB5_21

.LBB5_10:
    mov     rcx, rsi
    mov     edx, 2
    call    qword ptr [rip + __imp_GetAncestor]
    cmp     rax, rsi
    jne     .LBB5_21

    mov     rcx, rsi
    mov     edx, 4
    call    qword ptr [rip + __imp_GetWindow]
    test    rax, rax
    jne     .LBB5_21

    mov     rcx, rsi
    mov     edx, -20
    call    qword ptr [rip + __imp_GetWindowLongPtrW]
    test    al, al
    js      .LBB5_21

    lea     rdx, [rsp + 64]
    and     dword ptr [rdx], 0
    mov     rcx, rsi
    mov     r8d, 2
    call    qword ptr [rip + __imp_GetWindowTextW]
    test    eax, eax
    je      .LBB5_21

    movsxd  rax, dword ptr [rip + g_TaskButtonCount]
    xor     r8d, r8d
    test    eax, eax
    mov     ecx, 0
    cmovg   ecx, eax
    lea     rdx, [rip + g_TaskButtons]
.LBB5_15:
    mov     r9, r8
    cmp     rcx, r8
    je      .LBB5_17

    lea     r8, [r9 + 1]
    cmp     qword ptr [rdx], rsi
    lea     rdx, [rdx + 16]
    jne     .LBB5_15
.LBB5_17:
    cmp     r9, rax
    setl    cl
    cmp     eax, 127
    setg    al
    or      al, cl
    jne     .LBB5_21

    lea     rdx, [rsp + 64]
    mov     ecx, 128
    xor     eax, eax
    mov     rdi, rdx
    rep stosd es:[rdi], eax

    mov     rcx, rsi
    mov     r8d, 255
    call    qword ptr [rip + __imp_GetWindowTextW]
    test    eax, eax
    jg      .LBB5_20

    lea     rdx, [rip + .L.str.4]
    lea     rcx, [rsp + 64]
    mov     r8d, 256
    call    qword ptr [rip + __imp_lstrcpynW]
.LBB5_20:
    mov     edi, 6000
    add     edi, dword ptr [rip + g_TaskButtonCount]

    mov     rcx, qword ptr [rip + g_hwndTaskToolbar]
    mov     rbx, qword ptr [rip + __imp_SendMessageW]
    lea     r9, [rsp + 64]
    mov     edx, 1101                            
    xor     r8d, r8d
    call    rbx

    xorps   xmm0, xmm0
    lea     r9, [rsp + 32]
    movups  xmmword ptr [r9 + 8], xmm0
    mov     dword ptr [r9], -2                   
    mov     dword ptr [r9 + 4], edi              
    mov     word ptr [r9 + 8], 24580             
    mov     qword ptr [r9 + 24], rax             

    mov     rcx, qword ptr [rip + g_hwndTaskToolbar]
    mov     r8d, 1
    mov     edx, 1092                            
    call    rbx

    movsxd  rax, dword ptr [rip + g_TaskButtonCount]
    lea     ecx, [rax + 1]
    shl     rax, 4
    lea     rdx, [rip + g_TaskButtons]
    mov     qword ptr [rax + rdx], rsi           
    mov     dword ptr [rax + rdx + 8], edi       
    mov     dword ptr [rip + g_TaskButtonCount], ecx
.LBB5_21:
    .seh_startepilogue
    add     rsp, 576
    pop     rbx
    pop     rdi
    pop     rsi
    .seh_endepilogue
    ret
.seh_endproc

    .def    Taskbar_SetActive;
    .scl    3;
    .type   32;
    .endef
Taskbar_SetActive:                              

.seh_proc Taskbar_SetActive

    push    r14
    .seh_pushreg r14
    push    rsi
    .seh_pushreg rsi
    push    rdi
    .seh_pushreg rdi
    push    rbx
    .seh_pushreg rbx
    sub     rsp, 40
    .seh_stackalloc 40
    .seh_endprologue

    cmp     qword ptr [rip + g_hwndTaskToolbar], 0
    je      .LBB6_4

    mov     rsi, rcx
    lea     rdi, [rip + g_TaskButtons+8]
    xor     ebx, ebx
    mov     r14, qword ptr [rip + __imp_SendMessageW]
.LBB6_2:
    movsxd  rax, dword ptr [rip + g_TaskButtonCount]
    cmp     rbx, rax
    jge     .LBB6_5

    xor     r9d, r9d
    cmp     qword ptr [rdi - 8], rsi
    sete    r9b
    or      r9, 4
    mov     rcx, qword ptr [rip + g_hwndTaskToolbar]
    movsxd  r8, dword ptr [rdi]
    mov     edx, 1041
    call    r14
    inc     rbx
    add     rdi, 16
    jmp     .LBB6_2

.LBB6_5:
    mov     rcx, qword ptr [rip + g_hwndTaskToolbar]
    xor     edx, edx
    mov     r8d, 1
    .seh_startepilogue
    add     rsp, 40
    pop     rbx
    pop     rdi
    pop     rsi
    pop     r14
    .seh_endepilogue
    rex64 jmp qword ptr [rip + __imp_InvalidateRect] 

.LBB6_4:
    .seh_startepilogue
    add     rsp, 40
    pop     rbx
    pop     rdi
    pop     rsi
    pop     r14
    .seh_endepilogue
    ret
.seh_endproc

    .def    PositionTaskbarAndTiles;
    .scl    3;
    .type   32;
    .endef
PositionTaskbarAndTiles:                        

.seh_proc PositionTaskbarAndTiles

    push    rsi
    .seh_pushreg rsi
    push    rdi
    .seh_pushreg rdi
    push    rbx
    .seh_pushreg rbx
    sub     rsp, 96
    .seh_stackalloc 96
    .seh_endprologue

    mov     rsi, rcx
    mov     rdi, qword ptr [rip + __imp_GetSystemMetrics]

    xor     ecx, ecx
    call    rdi
    mov     ebx, eax                            

    mov     ecx, 1
    call    rdi
    lea     r9d, [rax - 32]
    cmp     byte ptr [rip + g_autoHidden], 0
    cmovne  r9d, eax

    mov     dword ptr [rsp + 32], ebx
    mov     dword ptr [rsp + 48], 64
    mov     dword ptr [rsp + 40], 32
    mov     rcx, rsi
    mov     rdx, -1
    xor     r8d, r8d
    call    qword ptr [rip + __imp_SetWindowPos]

    mov     rcx, qword ptr [rip + g_hwndTileStart]
    test    rcx, rcx
    je      .LBB7_1

    mov     dword ptr [rsp + 40], 1
    mov     dword ptr [rsp + 32], 24
    mov     edx, 4
    mov     r8d, 4
    mov     r9d, 90
    call    qword ptr [rip + __imp_MoveWindow]
    jmp     .LBB7_3

.LBB7_1:
    xor     ecx, ecx
    call    qword ptr [rip + __imp_GetModuleHandleW]
    mov     qword ptr [rsp + 80], rax
    mov     qword ptr [rsp + 64], rsi
    mov     eax, 4
    mov     dword ptr [rsp + 40], eax
    mov     dword ptr [rsp + 32], eax
    and     qword ptr [rsp + 88], 0
    mov     qword ptr [rsp + 72], 1000
    mov     dword ptr [rsp + 56], 24
    mov     dword ptr [rsp + 48], 90
    lea     rdx, [rip + .L.str.9]
    lea     r8,  [rip + .L.str.10]
    xor     ecx, ecx
    mov     r9d, 1342177291
    call    qword ptr [rip + __imp_CreateWindowExW]
    mov     qword ptr [rip + g_hwndTileStart], rax

.LBB7_3:
    cmp     ebx, 313
    mov     edi, 312
    cmovge  edi, ebx
    lea     ebx, [rdi - 192]

    mov     rcx, qword ptr [rip + g_hwndTaskToolbar]
    test    rcx, rcx
    je      .LBB7_4

    mov     dword ptr [rsp + 40], 1
    mov     dword ptr [rsp + 32], 24
    mov     edx, 98
    mov     r8d, 4
    mov     r9d, ebx
    call    qword ptr [rip + __imp_MoveWindow]
    jmp     .LBB7_7

.LBB7_4:
    xor     ecx, ecx
    call    qword ptr [rip + __imp_GetModuleHandleW]
    mov     qword ptr [rsp + 80], rax
    mov     qword ptr [rsp + 64], rsi
    mov     dword ptr [rsp + 48], ebx
    and     qword ptr [rsp + 88], 0
    mov     qword ptr [rsp + 72], 2
    mov     dword ptr [rsp + 56], 24
    mov     dword ptr [rsp + 40], 4
    mov     dword ptr [rsp + 32], 98
    lea     rdx, [rip + .L.str.11]
    xor     ecx, ecx
    xor     r8d, r8d
    mov     r9d, 1342183492
    call    qword ptr [rip + __imp_CreateWindowExW]
    mov     qword ptr [rip + g_hwndTaskToolbar], rax
    test    rax, rax
    je      .LBB7_7

    mov     rbx, qword ptr [rip + __imp_SendMessageW]
    mov     r8d, 32
    mov     rcx, rax
    mov     edx, 1054
    xor     r9d, r9d
    call    rbx

    mov     rcx, qword ptr [rip + g_hwndTaskToolbar]
    mov     r8d, 1
    mov     edx, 1084
    xor     r9d, r9d
    call    rbx

    mov     rcx, qword ptr [rip + g_hwndTaskToolbar]
    mov     r9d, 128
    mov     edx, 1108
    xor     r8d, r8d
    call    rbx

.LBB7_7:
    add     edi, -94
    mov     rcx, qword ptr [rip + g_hwndClock]
    test    rcx, rcx
    je      .LBB7_9

    mov     dword ptr [rsp + 40], 1
    mov     dword ptr [rsp + 32], 24
    mov     edx, edi
    mov     r8d, 4
    mov     r9d, 90
    call    qword ptr [rip + __imp_MoveWindow]
    .seh_startepilogue
    add     rsp, 96
    pop     rbx
    pop     rdi
    pop     rsi
    .seh_endepilogue
    ret

.LBB7_9:
    xor     ecx, ecx
    call    qword ptr [rip + __imp_GetModuleHandleW]
    mov     qword ptr [rsp + 80], rax
    and     qword ptr [rsp + 88], 0
    mov     qword ptr [rsp + 64], rsi
    mov     dword ptr [rsp + 32], edi
    mov     qword ptr [rsp + 72], 1100
    mov     dword ptr [rsp + 56], 24
    mov     dword ptr [rsp + 48], 90
    mov     dword ptr [rsp + 40], 4
    lea     rdx, [rip + .L.str.12]
    lea     r8,  [rip + .L.str.1]
    xor     ecx, ecx
    mov     r9d, 1342177537
    call    qword ptr [rip + __imp_CreateWindowExW]
    mov     qword ptr [rip + g_hwndClock], rax

    mov     edx, 2001
    mov     rcx, rsi
    mov     r8d, 1000
    xor     r9d, r9d
    .seh_startepilogue
    add     rsp, 96
    pop     rbx
    pop     rdi
    pop     rsi
    .seh_endepilogue
    rex64 jmp qword ptr [rip + __imp_SetTimer] 
.seh_endproc

    .def    UpdateClock;
    .scl    3;
    .type   32;
    .endef
UpdateClock:                                    

.seh_proc UpdateClock

    sub     rsp, 88
    .seh_stackalloc 88
    .seh_endprologue

    mov     rcx, qword ptr [rip + g_hwndClock]
    test    rcx, rcx
    je      .LBB8_6

    call    qword ptr [rip + __imp_IsWindow]
    test    eax, eax
    je      .LBB8_6

    lea     rcx, [rsp + 32]
    call    qword ptr [rip + __imp_GetLocalTime]
    cmp     dword ptr [rip + g_clockShowDate], 0
    je      .LBB8_3

    movzx   ecx, word ptr [rsp + 32]
    movzx   r9d, word ptr [rsp + 34]
    mov     r8w, 1000
    mov     eax, ecx
    xor     edx, edx
    div     r8w
    movzx   eax, al
    mov     dl, 10
    div     dl
    movzx   eax, ah
    or      al, 48
    movzx   eax, al
    mov     word ptr [rsp + 48], ax
    mov     r8w, 100
    mov     eax, ecx
    xor     edx, edx
    div     r8w
    mov     r11w, 10
    xor     edx, edx
    div     r11w
    or      edx, 48
    mov     word ptr [rsp + 50], dx

    mov     eax, ecx
    xor     edx, edx
    div     r11w
    xor     edx, edx
    div     r11w
    mov     r8d, edx
    mov     eax, r9d
    xor     edx, edx
    div     r11w
    mov     r10d, edx
    xor     edx, edx
    div     r11w
    mov     r9d, edx
    or      r10d, 48
    mov     word ptr [rsp + 60], r10w
    mov     word ptr [rsp + 62], 45
    movzx   eax, word ptr [rsp + 38]
    xor     edx, edx
    div     r11w
    mov     r10d, edx
    or      r8d, 48
    or      r9d, 48
    xor     edx, edx
    div     r11w
    or      edx, 48
    mov     word ptr [rsp + 64], dx
    or      r10d, 48
    mov     word ptr [rsp + 66], r10w
    and     word ptr [rsp + 68], 0
    mov     r10w, 45
    jmp     .LBB8_5

.LBB8_3:
    movzx   eax, word ptr [rsp + 40]
    movzx   ecx, word ptr [rsp + 42]
    mov     r9w, 10
    xor     edx, edx
    div     r9w
    mov     r8d, edx
    xor     edx, edx
    div     r9w
    or      edx, 48
    mov     word ptr [rsp + 48], dx
    or      r8d, 48
    mov     word ptr [rsp + 50], r8w

    mov     eax, ecx
    xor     edx, edx
    div     r9w
    mov     ecx, eax
    mov     r10d, edx
    xor     r9d, r9d
    or      r10d, 48
    mov     r8w, 58
.LBB8_5:
    mov     r11w, 10
    mov     eax, ecx
    xor     edx, edx
    div     r11w
    or      edx, 48
    lea     rax, [rsp + 48]
    mov     word ptr [rax + 4], r8w
    mov     word ptr [rax + 6], dx
    mov     word ptr [rax + 8], r10w
    mov     word ptr [rax + 10], r9w

    mov     rcx, qword ptr [rip + g_hwndClock]
    mov     rdx, rax
    call    qword ptr [rip + __imp_SetWindowTextW]
.LBB8_6:
    .seh_startepilogue
    add     rsp, 88
    .seh_endprologue
    ret
.seh_endproc

    .def    EnumInitProc;
    .scl    3;
    .type   32;
    .endef
EnumInitProc:                                   

.seh_proc EnumInitProc

    sub     rsp, 40
    .seh_stackalloc 40
    .seh_endprologue
    call    Taskbar_AddWindow
    mov     eax, 1
    .seh_startepilogue
    add     rsp, 40
    .seh_endprologue
    ret
.seh_endproc

    .def    DrawDarkButton;
    .scl    3;
    .type   32;
    .endef
DrawDarkButton:                                 

.seh_proc DrawDarkButton

    push    r15
    .seh_pushreg r15
    push    r14
    .seh_pushreg r14
    push    rsi
    .seh_pushreg rsi
    push    rdi
    .seh_pushreg rdi
    push    rbp
    .seh_pushreg rbp
    push    rbx
    .seh_pushreg rbx
    sub     rsp, 616
    .seh_stackalloc 616
    .seh_endprologue

    cmp     dword ptr [rcx], 4
    jne     .LBB10_5

    mov     rbx, rcx
    mov     rsi, qword ptr [rcx + 32]
    movups  xmm0, xmmword ptr [rcx + 40]
    lea     rdx, [rsp + 48]
    movaps  xmmword ptr [rdx], xmm0
    mov     ebp, dword ptr [rcx + 16]
    test    bpl, 1
    lea     rax, [rip + g_hbrBtn]
    lea     rcx, [rip + g_hbrBg]
    cmovne  rcx, rax
    mov     r8, qword ptr [rcx]
    mov     rcx, rsi
    call    qword ptr [rip + __imp_FillRect]

    test    bpl, 1
    je      .LBB10_3

    xor     ecx, ecx
    mov     edx, 1
    mov     r8d, 7895160
    call    qword ptr [rip + __imp_CreatePen]
    mov     rdi, rax
    mov     r15, qword ptr [rip + __imp_SelectObject]
    mov     rcx, rsi
    mov     rdx, rax
    call    r15
    mov     r14, rax

    mov     ecx, 5
    call    qword ptr [rip + __imp_GetStockObject]
    mov     rcx, rsi
    mov     rdx, rax
    call    r15

    mov     edx, dword ptr [rsp + 48]
    mov     r8d, dword ptr [rsp + 52]
    mov     r9d, dword ptr [rsp + 56]
    mov     eax, dword ptr [rsp + 60]
    mov     dword ptr [rsp + 32], eax
    mov     rcx, rsi
    call    qword ptr [rip + __imp_Rectangle]

    mov     rcx, rsi
    mov     rdx, r14
    call    r15
    mov     rcx, rdi
    call    qword ptr [rip + __imp_DeleteObject]
.LBB10_3:
    lea     r14, [rsp + 96]
    mov     ecx, 128
    xor     eax, eax
    mov     rdi, r14
    rep stosd es:[rdi], eax

    mov     rcx, qword ptr [rbx + 24]
    mov     rdx, r14
    mov     r8d, 255
    call    qword ptr [rip + __imp_GetWindowTextW]

    mov     rcx, rsi
    mov     edx, 1
    call    qword ptr [rip + __imp_SetBkMode]
    mov     rcx, rsi
    mov     edx, 16777215
    call    qword ptr [rip + __imp_SetTextColor]

    movaps  xmm0, xmmword ptr [rsp + 48]
    lea     rdi, [rsp + 80]
    movaps  xmmword ptr [rdi], xmm0
    mov     rcx, rdi
    mov     edx, -6
    mov     r8d, -2
    call    qword ptr [rip + __imp_InflateRect]

    mov     dword ptr [rsp + 32], 32805
    mov     rcx, rsi
    mov     rdx, r14
    mov     r8d, -1
    mov     r9, rdi
    call    qword ptr [rip + __imp_DrawTextW]

    test    bpl, 16
    je      .LBB10_5

    movaps  xmm0, xmmword ptr [rsp + 48]
    lea     rdi, [rsp + 64]
    movaps  xmmword ptr [rdi], xmm0
    mov     rcx, rdi
    mov     edx, -4
    mov     r8d, -4
    call    qword ptr [rip + __imp_InflateRect]

    mov     rcx, rsi
    mov     rdx, rdi
    call    qword ptr [rip + __imp_DrawFocusRect]
.LBB10_5:
    .seh_startepilogue
    add     rsp, 616
    pop     rbx
    pop     rbp
    pop     rdi
    pop     rsi
    pop     r14
    pop     r15
    .seh_endprologue
    ret
.seh_endproc

    .def    CloseStartMenu;
    .scl    3;
    .type   32;
    .endef
CloseStartMenu:                                 

.seh_proc CloseStartMenu

    sub     rsp, 40
    .seh_stackalloc 40
    .seh_endprologue
    mov     rcx, qword ptr [rip + g_hwndStartMenu]
    test    rcx, rcx
    je      .LBB11_3

    call    qword ptr [rip + __imp_IsWindow]
    test    eax, eax
    je      .LBB11_3

    mov     rcx, qword ptr [rip + g_hwndStartMenu]
    call    qword ptr [rip + __imp_DestroyWindow]
    and     qword ptr [rip + g_hwndStartMenu], 0
.LBB11_3:
    .seh_startepilogue
    add     rsp, 40
    .seh_endprologue
    ret
.seh_endproc

    .section    .rdata,"dr"
    .p2align    1, 0x0                          
.L.str:
    .short  83
    .short  104
    .short  101
    .short  108
    .short  108
    .short  57
    .short  53
    .short  84
    .short  105
    .short  108
    .short  101
    .short  115
    .short  77
    .short  97
    .short  105
    .short  110
    .short  87
    .short  110
    .short  100
    .short  0

    .p2align    1, 0x0                          
.L.str.1:
    .zero   2

    .lcomm  g_hwndMain,8,8

    .p2align    1, 0x0                          
.L.str.2:
    .short  83
    .short  104
    .short  101
    .short  108
    .short  108
    .short  57
    .short  53
    .short  83
    .short  116
    .short  97
    .short  114
    .short  116
    .short  77
    .short  101
    .short  110
    .short  117
    .short  0

    .lcomm  g_uShellHookMsg,4,4
    .lcomm  g_hbrBg,8,8
    .lcomm  g_hbrBtn,8,8

    .p2align    1, 0x0                          
.L.str.3:
    .short  83
    .short  72
    .short  69
    .short  76
    .short  76
    .short  72
    .short  79
    .short  79
    .short  75
    .short  0

    .lcomm  g_autoHidden,1,4
    .lcomm  g_hwndStartMenu,8,8
    .lcomm  g_clockShowDate,4,4
    .lcomm  g_hwndTaskToolbar,8,8
    .lcomm  g_hDwmApi,8,8
    .lcomm  pDwmGetWindowAttribute,8,8
    .lcomm  g_TaskButtonCount,4,4
    .lcomm  g_TaskButtons,2048,16

    .p2align    1, 0x0                          
.L.str.4:
    .short  40
    .short  85
    .short  110
    .short  116
    .short  105
    .short  116
    .short  108
    .short  101
    .short  100
    .short  41
    .short  0

    .p2align    1, 0x0                          
.L.str.5:
    .short  80
    .short  114
    .short  111
    .short  103
    .short  109
    .short  97
    .short  110
    .short  0

    .p2align    1, 0x0                          
.L.str.6:
    .short  87
    .short  111
    .short  114
    .short  107
    .short  101
    .short  114
    .short  87
    .short  0

    .p2align    1, 0x0                          
.L.str.7:
    .short  100
    .short  119
    .short  109
    .short  97
    .short  112
    .short  105
    .short  46
    .short  100
    .short  108
    .short  108
    .short  0

.L.str.8:                                       
    .asciz  "DwmGetWindowAttribute"

    .lcomm  g_hwndTileStart,8,8

    .p2align    1, 0x0                          
.L.str.9:
    .short  66
    .short  85
    .short  84
    .short  84
    .short  79
    .short  78
    .short  0

    .p2align    1, 0x0                          
.L.str.10:
    .short  77
    .short  101
    .short  110
    .short  117
    .short  0

    .p2align    1, 0x0                          
.L.str.11:
    .short  84
    .short  111
    .short  111
    .short  108
    .short  98
    .short  97
    .short  114
    .short  87
    .short  105
    .short  110
    .short  100
    .short  111
    .short  119
    .short  51
    .short  50
    .short  0

    .lcomm  g_hwndClock,8,8

    .p2align    1, 0x0                          
.L.str.12:
    .short  83
    .short  84
    .short  65
    .short  84
    .short  73
    .short  67
    .short  0

    .p2align    4, 0x0                          
g_startMenuItems:
    .quad   .L.str.13
    .long   4002
    .long   0
    .quad   .L.str.14
    .long   4003
    .long   0
    .quad   .L.str.15
    .long   4004
    .long   0
    .quad   .L.str.16
    .long   4005
    .long   0
    .quad   .L.str.17
    .long   4006
    .long   0
    .quad   .L.str.18
    .long   4007
    .long   0
    .quad   0
    .long   0
    .long   1
    .quad   .L.str.19
    .long   4011
    .long   0
    .quad   0
    .long   0
    .long   1
    .quad   .L.str.20
    .long   4012
    .long   0

    .p2align    1, 0x0                          
.L.str.13:
    .short  86
    .short  111
    .short  108
    .short  117
    .short  109
    .short  101
    .short  0

    .p2align    1, 0x0                          
.L.str.14:
    .short  67
    .short  111
    .short  110
    .short  116
    .short  114
    .short  111
    .short  108
    .short  32
    .short  80
    .short  97
    .short  110
    .short  101
    .short  108
    .short  0

    .p2align    1, 0x0                          
.L.str.15:
    .short  78
    .short  111
    .short  116
    .short  101
    .short  112
    .short  97
    .short  100
    .short  0

    .p2align    1, 0x0                          
.L.str.16:
    .short  67
    .short  111
    .short  109
    .short  109
    .short  97
    .short  110
    .short  100
    .short  32
    .short  80
    .short  114
    .short  111
    .short  109
    .short  112
    .short  116
    .short  0

    .p2align    1, 0x0                          
.L.str.17:
    .short  87
    .short  101
    .short  98
    .short  32
    .short  66
    .short  114
    .short  111
    .short  119
    .short  115
    .short  101
    .short  114
    .short  0

    .p2align    1, 0x0                          
.L.str.18:
    .short  84
    .short  97
    .short  115
    .short  107
    .short  32
    .short  77
    .short  97
    .short  110
    .short  97
    .short  103
    .short  101
    .short  114
    .short  0

    .p2align    1, 0x0                          
.L.str.19:
    .short  83
    .short  104
    .short  117
    .short  116
    .short  32
    .short  68
    .short  111
    .short  119
    .short  110
    .short  46
    .short  46
    .short  46
    .short  0

    .p2align    1, 0x0                          
.L.str.20:
    .short  69
    .short  120
    .short  105
    .short  116
    .short  32
    .short  83
    .short  104
    .short  101
    .short  108
    .short  108
    .short  0

    .lcomm  g_startItemWnds,80,16

    .p2align    1, 0x0                          
.L.str.21:
    .short  111
    .short  112
    .short  101
    .short  110
    .short  0

    .p2align    1, 0x0                          
.L.str.22:
    .short  115
    .short  110
    .short  100
    .short  118
    .short  111
    .short  108
    .short  46
    .short  101
    .short  120
    .short  101
    .short  0

    .p2align    1, 0x0                          
.L.str.23:
    .short  99
    .short  111
    .short  110
    .short  116
    .short  114
    .short  111
    .short  108
    .short  46
    .short  101
    .short  120
    .short  101
    .short  0

    .p2align    1, 0x0                          
.L.str.24:
    .short  110
    .short  111
    .short  116
    .short  101
    .short  112
    .short  97
    .short  100
    .short  46
    .short  101
    .short  120
    .short  101
    .short  0

    .p2align    1, 0x0                          
.L.str.25:
    .short  99
    .short  109
    .short  100
    .short  46
    .short  101
    .short  120
    .short  101
    .short  0

    .p2align    1, 0x0                          
.L.str.26:
    .short  104
    .short  116
    .short  116
    .short  112
    .short  115
    .short  58
    .short  47
    .short  47
    .short  100
    .short  117
    .short  99
    .short  107
    .short  100
    .short  117
    .short  99
    .short  107
    .short  103
    .short  111
    .short  46
    .short  99
    .short  111
    .short  109
    .short  47
    .short  0

    .p2align    1, 0x0                          
.L.str.27:
    .short  116
    .short  97
    .short  115
    .short  107
    .short  109
    .short  103
    .short  114
    .short  46
    .short  101
    .short  120
    .short  101
    .short  0

    .p2align    1, 0x0                          
.L.str.28:
    .short  68
    .short  111
    .short  32
    .short  121
    .short  111
    .short  117
    .short  32
    .short  119
    .short  97
    .short  110
    .short  116
    .short  32
    .short  116
    .short  111
    .short  32
    .short  115
    .short  104
    .short  117
    .short  116
    .short  32
    .short  100
    .short  111
    .short  119
    .short  110
    .short  32
    .short  116
    .short  104
    .short  101
    .short  32
    .short  99
    .short  111
    .short  109
    .short  112
    .short  117
    .short  116
    .short  101
    .short  114
    .short  63
    .short  10
    .short  10
    .short  89
    .short  101
    .short  115
    .short  32
    .short  61
    .short  32
    .short  80
    .short  111
    .short  119
    .short  101
    .short  114
    .short  32
    .short  79
    .short  102
    .short  102
    .short  10
    .short  78
    .short  111
    .short  32
    .short  61
    .short  32
    .short  82
    .short  101
    .short  98
    .short  111
    .short  111
    .short  116
    .short  10
    .short  67
    .short  97
    .short  110
    .short  99
    .short  101
    .short  108
    .short  32
    .short  61
    .short  32
    .short  65
    .short  98
    .short  111
    .short  114
    .short  116
    .short  0

    .p2align    1, 0x0                          
.L.str.29:
    .short  83
    .short  104
    .short  117
    .short  116
    .short  32
    .short  68
    .short  111
    .short  119
    .short  110
    .short  0

    .p2align    1, 0x0                          
.L.str.30:
    .short  83
    .short  101
    .short  83
    .short  104
    .short  117
    .short  116
    .short  100
    .short  111
    .short  119
    .short  110
    .short  80
    .short  114
    .short  105
    .short  118
    .short  105
    .short  108
    .short  101
    .short  103
    .short  101
    .short  0