/*
PNSL (Permissive Non-Sale License)
Copyright © 2025 Christopher Forster

Permission to use, copy, modify, and/or distribute this software for any purpose
without charging a fee specifically for the software itself is hereby granted,
provided that the above copyright notice and this permission notice appear in all copies.
You may not introduce more restrictions.

THIS SOFTWARE IS PROVIDED ‘AS IS’ AND WITHOUT ANY WARRANTIES. IN NO EVENT SHALL THE
COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT OR INDIRECT LOSSES OR DAMAGES
ARISING FROM THE USE OF THIS SOFTWARE.

Any binary or combined work that directly incorporates PNSL-licensed code is considered
a derivative work and must comply with this license. However, merely calling, linking to,
or interacting with unmodified, separately distributed PNSL-licensed code does not, by itself,
constitute a derivative work.
*/


#![windows_subsystem = "windows"]
#![allow(non_snake_case)]

use std::cell::UnsafeCell;
use std::ffi::OsStr;
use std::mem;
use std::os::windows::ffi::OsStrExt;
use std::ptr;
use std::thread_local;

use winapi::shared::basetsd::LONG_PTR;
use winapi::shared::minwindef::{
    BOOL, DWORD, FALSE, HINSTANCE, HMODULE, LPARAM, LRESULT, TRUE, UINT, WPARAM, WORD, MAKELONG,
};
use winapi::shared::windef::{HBRUSH, HDC, HGDIOBJ, HMENU, HWND, POINT, RECT};

use winapi::um::commctrl::*;
use winapi::um::handleapi::CloseHandle;
use winapi::um::libloaderapi::{FreeLibrary, GetModuleHandleW, GetProcAddress, LoadLibraryW};
use winapi::um::minwinbase::SYSTEMTIME;
use winapi::um::processthreadsapi::{GetCurrentProcess, GetCurrentThreadId, OpenProcessToken};
use winapi::um::securitybaseapi::AdjustTokenPrivileges;
use winapi::um::shellapi::ShellExecuteW;
use winapi::um::sysinfoapi::GetLocalTime;
use winapi::um::wingdi::*;
use winapi::um::winbase::LookupPrivilegeValueW;
use winapi::um::winnt::{
    SE_PRIVILEGE_ENABLED, TOKEN_ADJUST_PRIVILEGES, TOKEN_PRIVILEGES, TOKEN_QUERY,
};
use winapi::um::winuser::*;

// ---------- Basic typedefs ----------

type HRESULT = i32;

// ---------- Constants & IDs ----------

const ID_TILE_START: u32 = 1000;
const IDC_CLOCK: u32 = 1100;

const IDT_CLOCK: u32 = 2001;
const IDT_AUTOHIDE: u32 = 2002;
const IDT_AUTOSHOW: u32 = 2003;

// Start menu commands
const IDM_START_VOLUME: u32 = 4002;
const IDM_START_CONTROL: u32 = 4003;
const IDM_START_NOTEPAD: u32 = 4004;
const IDM_START_CMD: u32 = 4005;
const IDM_START_WEB: u32 = 4006;
const IDM_START_TASKMGR: u32 = 4007;
const IDM_START_SHUTDOWN: u32 = 4011;
const IDM_START_EXIT: u32 = 4012;

const MAX_TASK_BUTTONS: usize = 128;
const ID_TASKBTN_FIRST: i32 = 6000;
const BAR_H: i32 = 32;

// DWM attribute
const DWMWA_CLOAKED: DWORD = 14;

// ---------- Helper types ----------

#[derive(Copy, Clone)]
struct StartMenuItem {
    text: Option<&'static str>,
    id: u32,
    is_separator: bool,
}

#[derive(Copy, Clone)]
struct TaskBtn {
    hwnd: HWND,
    id_command: i32,
}

impl Default for TaskBtn {
    fn default() -> Self {
        TaskBtn {
            hwnd: ptr::null_mut(),
            id_command: 0,
        }
    }
}

// DWM dynamic loading
struct DwmApi {
    module: HMODULE,
    get_window_attribute:
        unsafe extern "system" fn(HWND, DWORD, *mut std::ffi::c_void, DWORD) -> HRESULT,
}

impl Drop for DwmApi {
    fn drop(&mut self) {
        unsafe {
            if !self.module.is_null() {
                FreeLibrary(self.module);
            }
        }
    }
}

// Start menu items
static START_MENU_ITEMS: &[StartMenuItem] = &[
    StartMenuItem {
        text: Some("Volume"),
        id: IDM_START_VOLUME,
        is_separator: false,
    },
    StartMenuItem {
        text: Some("Control Panel"),
        id: IDM_START_CONTROL,
        is_separator: false,
    },
    StartMenuItem {
        text: Some("Notepad"),
        id: IDM_START_NOTEPAD,
        is_separator: false,
    },
    StartMenuItem {
        text: Some("Command Prompt"),
        id: IDM_START_CMD,
        is_separator: false,
    },
    StartMenuItem {
        text: Some("Web Browser"),
        id: IDM_START_WEB,
        is_separator: false,
    },
    StartMenuItem {
        text: Some("Task Manager"),
        id: IDM_START_TASKMGR,
        is_separator: false,
    },
    StartMenuItem {
        text: None,
        id: 0,
        is_separator: true,
    },
    StartMenuItem {
        text: Some("Shut Down..."),
        id: IDM_START_SHUTDOWN,
        is_separator: false,
    },
    StartMenuItem {
        text: None,
        id: 0,
        is_separator: true,
    },
    StartMenuItem {
        text: Some("Exit Shell"),
        id: IDM_START_EXIT,
        is_separator: false,
    },
];

const START_MENU_LEN: usize = 10;

// ---------- AppState: all mutable state ----------

struct AppState {
    main_hwnd: HWND,
    tile_start_hwnd: HWND,
    clock_hwnd: HWND,
    task_toolbar_hwnd: HWND,
    start_menu_hwnd: HWND,
    start_item_hwnds: [HWND; START_MENU_LEN],

    task_buttons: [TaskBtn; MAX_TASK_BUTTONS],
    task_button_count: usize,

    bar_height: i32,
    auto_hidden: bool,
    clock_show_date: bool,
    shell_hook_msg: UINT,

    bg_brush: HBRUSH,
    btn_brush: HBRUSH,

    dwm: Option<DwmApi>,
}

impl AppState {
    fn new() -> Self {
        AppState {
            main_hwnd: ptr::null_mut(),
            tile_start_hwnd: ptr::null_mut(),
            clock_hwnd: ptr::null_mut(),
            task_toolbar_hwnd: ptr::null_mut(),
            start_menu_hwnd: ptr::null_mut(),
            start_item_hwnds: [ptr::null_mut(); START_MENU_LEN],

            task_buttons: [TaskBtn::default(); MAX_TASK_BUTTONS],
            task_button_count: 0,

            bar_height: BAR_H,
            auto_hidden: false,
            clock_show_date: false,
            shell_hook_msg: 0,
            bg_brush: ptr::null_mut(),
            btn_brush: ptr::null_mut(),
            dwm: None,
        }
    }

    unsafe fn init_dwm(&mut self) {
        if self.dwm.is_some() {
            return;
        }

        let dll_name = to_wstring("dwmapi.dll");
        let h = LoadLibraryW(dll_name.as_ptr());
        if h.is_null() {
            return;
        }

        let proc_name = b"DwmGetWindowAttribute\0";
        let proc = GetProcAddress(h, proc_name.as_ptr() as *const i8);
        if proc.is_null() {
            FreeLibrary(h);
            return;
        }

        let func: unsafe extern "system" fn(HWND, DWORD, *mut std::ffi::c_void, DWORD) -> HRESULT =
            mem::transmute(proc);
        self.dwm = Some(DwmApi {
            module: h,
            get_window_attribute: func,
        });
    }

    unsafe fn is_cloaked(&self, hwnd: HWND) -> bool {
        if let Some(ref api) = self.dwm {
            let mut cloaked: BOOL = FALSE;
            let hr = (api.get_window_attribute)(
                hwnd,
                DWMWA_CLOAKED,
                &mut cloaked as *mut _ as *mut std::ffi::c_void,
                mem::size_of::<BOOL>() as DWORD,
            );
            if hr >= 0 {
                return cloaked != 0;
            }
        }
        false
    }
}

// ---------- Global access: thread-local AppState ----------

thread_local! {
    static APP_STATE: UnsafeCell<AppState> = UnsafeCell::new(AppState::new());
}

fn with_app_state<F, R>(f: F) -> R
where
    F: FnOnce(&mut AppState) -> R,
{
    APP_STATE.with(|cell| unsafe { f(&mut *cell.get()) })
}

// ---------- Utility helpers ----------

fn to_wstring(s: &str) -> Vec<u16> {
    OsStr::new(s).encode_wide().chain(std::iter::once(0)).collect()
}

fn loword(v: usize) -> u16 {
    (v & 0xFFFF) as u16
}

fn hiword(v: usize) -> u16 {
    ((v >> 16) & 0xFFFF) as u16
}

fn rgb(r: u8, g: u8, b: u8) -> DWORD {
    (r as DWORD) | ((g as DWORD) << 8) | ((b as DWORD) << 16)
}

// ---------- Drawing helpers ----------

unsafe fn draw_dark_button(dis: *mut DRAWITEMSTRUCT, state: &AppState) {
    if (*dis).CtlType != ODT_BUTTON {
        return;
    }

    let hdc = (*dis).hDC;
    let rc: RECT = (*dis).rcItem;
    let pressed = ((*dis).itemState & ODS_SELECTED) != 0;
    let focus = ((*dis).itemState & ODS_FOCUS) != 0;

    let brush = if pressed { state.btn_brush } else { state.bg_brush };
    FillRect(hdc, &rc, brush);

    if pressed {
        let pen = CreatePen(PS_SOLID as i32, 1, rgb(120, 120, 120));
        if !pen.is_null() {
            let old_pen = SelectObject(hdc, pen as HGDIOBJ);
            let old_brush = SelectObject(hdc, GetStockObject(NULL_BRUSH as i32));
            Rectangle(hdc, rc.left, rc.top, rc.right, rc.bottom);
            SelectObject(hdc, old_brush);
            SelectObject(hdc, old_pen);
            DeleteObject(pen as HGDIOBJ);
        }
    }

    let mut text_buf: [u16; 256] = [0; 256];
    GetWindowTextW((*dis).hwndItem, text_buf.as_mut_ptr(), 255);

    SetBkMode(hdc, TRANSPARENT as i32);
    SetTextColor(hdc, rgb(255, 255, 255));

    let mut tr = rc;
    InflateRect(&mut tr, -6, -2);
    DrawTextW(
        hdc,
        text_buf.as_ptr(),
        -1,
        &mut tr,
        DT_CENTER | DT_VCENTER | DT_SINGLELINE | DT_END_ELLIPSIS,
    );

    if focus {
        let mut fr = rc;
        InflateRect(&mut fr, -4, -4);
        DrawFocusRect(hdc, &fr);
    }
}

unsafe fn on_toolbar_custom_draw(pcd: *mut NMCUSTOMDRAW, state: &AppState) -> LRESULT {
    match (*pcd).dwDrawStage {
        CDDS_PREPAINT => {
            let mut rc: RECT = mem::zeroed();
            GetClientRect((*pcd).hdr.hwndFrom, &mut rc);
            FillRect((*pcd).hdc, &rc, state.bg_brush);
            CDRF_NOTIFYITEMDRAW as LRESULT
        }
        CDDS_ITEMPREPAINT => {
            let checked = ((*pcd).uItemState & CDIS_CHECKED) != 0;
            let brush = if checked { state.btn_brush } else { state.bg_brush };
            FillRect((*pcd).hdc, &(*pcd).rc, brush);

            let mut text_buf: [u16; 256] = [0; 256];
            SendMessageW(
                (*pcd).hdr.hwndFrom,
                TB_GETBUTTONTEXTW,
                (*pcd).dwItemSpec,
                text_buf.as_mut_ptr() as LPARAM,
            );

            SetTextColor((*pcd).hdc, rgb(255, 255, 255));
            SetBkMode((*pcd).hdc, TRANSPARENT as i32);

            let mut tr = (*pcd).rc;
            InflateRect(&mut tr, -6, -2);
            DrawTextW(
                (*pcd).hdc,
                text_buf.as_ptr(),
                -1,
                &mut tr,
                DT_CENTER | DT_VCENTER | DT_SINGLELINE | DT_END_ELLIPSIS,
            );

            if checked {
                let pen = CreatePen(PS_SOLID as i32, 1, rgb(120, 120, 120));
                if !pen.is_null() {
                    let old_pen = SelectObject((*pcd).hdc, pen as HGDIOBJ);
                    let old_brush =
                        SelectObject((*pcd).hdc, GetStockObject(NULL_BRUSH as i32));
                    Rectangle(
                        (*pcd).hdc,
                        (*pcd).rc.left,
                        (*pcd).rc.top,
                        (*pcd).rc.right,
                        (*pcd).rc.bottom,
                    );
                    SelectObject((*pcd).hdc, old_brush);
                    SelectObject((*pcd).hdc, old_pen);
                    DeleteObject(pen as HGDIOBJ);
                }
            }

            CDRF_SKIPDEFAULT as LRESULT
        }
        _ => CDRF_DODEFAULT as LRESULT,
    }
}

// ---------- Auto-hide ----------

unsafe fn hide_bar(state: &mut AppState, hwnd: HWND) {
    if hwnd.is_null() || state.auto_hidden {
        return;
    }
    let screen_h = GetSystemMetrics(SM_CYSCREEN);
    let ok = SetWindowPos(
        hwnd,
        HWND_TOPMOST,
        0,
        screen_h,
        0,
        0,
        SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW,
    );
    if ok != 0 {
        state.auto_hidden = true;
    }
}

unsafe fn show_bar(state: &mut AppState, hwnd: HWND) {
    if hwnd.is_null() || !state.auto_hidden {
        return;
    }
    let screen_h = GetSystemMetrics(SM_CYSCREEN);
    let ok = SetWindowPos(
        hwnd,
        HWND_TOPMOST,
        0,
        screen_h - state.bar_height,
        0,
        0,
        SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW,
    );
    if ok != 0 {
        state.auto_hidden = false;
    }
}

// ---------- Start menu ----------

unsafe fn close_start_menu(state: &mut AppState) {
    if !state.start_menu_hwnd.is_null() && IsWindow(state.start_menu_hwnd) != 0 {
        DestroyWindow(state.start_menu_hwnd);
        state.start_menu_hwnd = ptr::null_mut();
    }
}

unsafe fn enable_shutdown_privilege() {
    let mut token = ptr::null_mut();
    if OpenProcessToken(
        GetCurrentProcess(),
        TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY,
        &mut token,
    ) == 0
    {
        return;
    }

    let name = to_wstring("SeShutdownPrivilege");
    let mut tp: TOKEN_PRIVILEGES = mem::zeroed();
    tp.PrivilegeCount = 1;

    if LookupPrivilegeValueW(ptr::null(), name.as_ptr(), &mut tp.Privileges[0].Luid) != 0 {
        tp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
        AdjustTokenPrivileges(
            token,
            FALSE,
            &mut tp,
            0,
            ptr::null_mut(),
            ptr::null_mut(),
        );
    }

    CloseHandle(token);
}

unsafe fn show_shutdown_dialog(owner: HWND) -> BOOL {
    let text = to_wstring(
        "Do you want to shut down the computer?\n\nYes = Power Off\nNo = Reboot\nCancel = Abort",
    );
    let caption = to_wstring("Shut Down");

    let r = MessageBoxW(
        owner,
        text.as_ptr(),
        caption.as_ptr(),
        MB_YESNOCANCEL | MB_ICONQUESTION | MB_TOPMOST,
    );

    if r == IDYES {
        enable_shutdown_privilege();
        ExitWindowsEx(EWX_POWEROFF, 0);
        TRUE
    } else if r == IDNO {
        enable_shutdown_privilege();
        ExitWindowsEx(EWX_REBOOT, 0);
        TRUE
    } else {
        FALSE
    }
}

unsafe fn shell_open(op: &str, target: &str) {
    let op_w = to_wstring(op);
    let target_w = to_wstring(target);
    let res = ShellExecuteW(
        ptr::null_mut(),
        op_w.as_ptr(),
        target_w.as_ptr(),
        ptr::null(),
        ptr::null(),
        SW_SHOWNORMAL,
    );
    if (res as isize) <= 32 {
        // silently ignore
    }
}

unsafe fn handle_start_menu_command(state: &mut AppState, owner: HWND, id: u32) {
    match id {
        IDM_START_VOLUME => shell_open("open", "sndvol.exe"),
        IDM_START_CONTROL => shell_open("open", "control.exe"),
        IDM_START_NOTEPAD => shell_open("open", "notepad.exe"),
        IDM_START_CMD => shell_open("open", "cmd.exe"),
        IDM_START_WEB => shell_open("open", "https://duckduckgo.com/"),
        IDM_START_TASKMGR => shell_open("open", "taskmgr.exe"),
        IDM_START_SHUTDOWN => {
            show_shutdown_dialog(owner);
        }
        IDM_START_EXIT => {
            if !state.main_hwnd.is_null() {
                DestroyWindow(state.main_hwnd);
            } else {
                PostQuitMessage(0);
            }
        }
        _ => {}
    }
}

fn compute_start_menu_height() -> i32 {
    let margin = 4;
    let item_h = 24;
    let item_spacing = 2;
    let sep_extra = 6;
    let mut height = margin * 2;
    let mut any_item = false;

    for item in START_MENU_ITEMS {
        if item.is_separator {
            height += sep_extra;
        } else {
            height += item_h + item_spacing;
            any_item = true;
        }
    }
    if any_item {
        height -= item_spacing;
    }
    height
}

unsafe fn create_start_menu_items(state: &mut AppState, hwnd_menu: HWND) {
    let mut rc: RECT = mem::zeroed();
    GetClientRect(hwnd_menu, &mut rc);

    let margin = 4;
    let item_h = 24;
    let item_spacing = 2;
    let sep_extra = 6;

    let width = (rc.right - rc.left) - margin * 2;
    let mut y = margin;

    for (i, item) in START_MENU_ITEMS.iter().enumerate() {
        if item.is_separator {
            y += sep_extra;
            continue;
        }
        let text = to_wstring(item.text.unwrap_or(""));
        let btn_class = to_wstring("BUTTON");

        let h_item = CreateWindowExW(
            0,
            btn_class.as_ptr(),
            text.as_ptr(),
            WS_CHILD | WS_VISIBLE | BS_OWNERDRAW,
            margin,
            y,
            width,
            item_h,
            hwnd_menu,
            item.id as HMENU,
            GetModuleHandleW(ptr::null()),
            ptr::null_mut(),
        );
        state.start_item_hwnds[i] = h_item;
        y += item_h + item_spacing;
    }
}

unsafe fn start_menu_wnd_proc_inner(
    state: &mut AppState,
    hwnd: HWND,
    msg: UINT,
    w_param: WPARAM,
    l_param: LPARAM,
) -> LRESULT {
    match msg {
        WM_CREATE => {
            create_start_menu_items(state, hwnd);
            SetForegroundWindow(hwnd);
            0
        }
        WM_ERASEBKGND => {
            let hdc = w_param as HDC;
            let mut rc: RECT = mem::zeroed();
            GetClientRect(hwnd, &mut rc);
            FillRect(hdc, &rc, state.bg_brush);
            1
        }
        WM_DRAWITEM => {
            let dis = l_param as *mut DRAWITEMSTRUCT;
            draw_dark_button(dis, state);
            TRUE as LRESULT
        }
        WM_COMMAND => {
            let id = loword(w_param as usize) as u32;
            let owner = GetParent(hwnd);
            handle_start_menu_command(state, owner, id);
            close_start_menu(state);
            0
        }
        WM_ACTIVATE => {
            if loword(w_param as usize) == WA_INACTIVE {
                let to = l_param as HWND;
                if to.is_null() || (to != hwnd && IsChild(hwnd, to) == 0) {
                    close_start_menu(state);
                }
            }
            0
        }
        WM_DESTROY => {
            if hwnd == state.start_menu_hwnd {
                state.start_menu_hwnd = ptr::null_mut();
            }
            0
        }
        _ => DefWindowProcW(hwnd, msg, w_param, l_param),
    }
}

unsafe fn show_start_menu(state: &mut AppState, main_hwnd: HWND) {
    if !state.start_menu_hwnd.is_null() && IsWindow(state.start_menu_hwnd) != 0 {
        close_start_menu(state);
        return;
    }

    if state.tile_start_hwnd.is_null() {
        return;
    }

    let mut rc_start: RECT = mem::zeroed();
    GetWindowRect(state.tile_start_hwnd, &mut rc_start);

    let menu_width = 260;
    let menu_height = compute_start_menu_height();

    let x = rc_start.left;
    let mut y = rc_start.top - menu_height;
    if y < 0 {
        y = rc_start.bottom;
    }

    let class_menu = to_wstring("Shell95StartMenu");

    let hwnd_menu = CreateWindowExW(
        WS_EX_TOOLWINDOW | WS_EX_TOPMOST,
        class_menu.as_ptr(),
        ptr::null(),
        WS_POPUP | WS_BORDER,
        x,
        y,
        menu_width,
        menu_height,
        main_hwnd,
        ptr::null_mut(),
        GetModuleHandleW(ptr::null()),
        ptr::null_mut(),
    );

    if !hwnd_menu.is_null() {
        state.start_menu_hwnd = hwnd_menu;
        ShowWindow(hwnd_menu, SW_SHOW);
        SetForegroundWindow(hwnd_menu);
    }
}

// ---------- Layout & clock ----------

unsafe fn position_taskbar_and_tiles(state: &mut AppState, hwnd: HWND) {
    let screen_w = GetSystemMetrics(SM_CXSCREEN);
    let screen_h = GetSystemMetrics(SM_CYSCREEN);
    let bar_h = BAR_H;
    state.bar_height = bar_h;

    let bar_y = if state.auto_hidden {
        screen_h
    } else {
        screen_h - bar_h
    };

    SetWindowPos(
        hwnd,
        HWND_TOPMOST,
        0,
        bar_y,
        screen_w,
        bar_h,
        SWP_SHOWWINDOW,
    );

    let margin = 4;
    let tile_h = bar_h - margin * 2;
    let mut x = margin;
    let y = margin;

    // Menu button
    if state.tile_start_hwnd.is_null() {
        let text = to_wstring("Menu");
        let btn_class = to_wstring("BUTTON");
        state.tile_start_hwnd = CreateWindowExW(
            0,
            btn_class.as_ptr(),
            text.as_ptr(),
            WS_CHILD | WS_VISIBLE | BS_OWNERDRAW,
            x,
            y,
            90,
            tile_h,
            hwnd,
            ID_TILE_START as HMENU,
            GetModuleHandleW(ptr::null()),
            ptr::null_mut(),
        );
    } else {
        MoveWindow(state.tile_start_hwnd, x, y, 90, tile_h, TRUE);
    }
    x += 90 + margin;

    // Taskbar toolbar
    let right_fixed = 90 + margin;
    let mut task_w = screen_w - x - right_fixed;
    if task_w < 120 {
        task_w = 120;
    }

    if state.task_toolbar_hwnd.is_null() {
        let class = to_wstring("ToolbarWindow32");
        state.task_toolbar_hwnd = CreateWindowExW(
            0,
            class.as_ptr(),
            ptr::null(),
            WS_CHILD
                | WS_VISIBLE
                | TBSTYLE_FLAT as u32
                | TBSTYLE_LIST as u32
                | CCS_NODIVIDER
                | CCS_NORESIZE,
            x,
            y,
            task_w,
            tile_h,
            hwnd,
            2 as HMENU,
            GetModuleHandleW(ptr::null()),
            ptr::null_mut(),
        );
        if !state.task_toolbar_hwnd.is_null() {
            SendMessageW(
                state.task_toolbar_hwnd,
                TB_BUTTONSTRUCTSIZE,
                mem::size_of::<TBBUTTON>() as WPARAM,
                0,
            );
            SendMessageW(state.task_toolbar_hwnd, TB_SETMAXTEXTROWS, 1, 0);
            SendMessageW(
                state.task_toolbar_hwnd,
                TB_SETEXTENDEDSTYLE,
                0,
                TBSTYLE_EX_DOUBLEBUFFER as LPARAM,
            );
        }
    } else {
        MoveWindow(state.task_toolbar_hwnd, x, y, task_w, tile_h, TRUE);
    }

    x += task_w;

    // Clock
    if state.clock_hwnd.is_null() {
        let static_class = to_wstring("STATIC");
        state.clock_hwnd = CreateWindowExW(
            0,
            static_class.as_ptr(),
            ptr::null(),
            WS_CHILD | WS_VISIBLE | SS_CENTER | SS_NOTIFY,
            x,
            y,
            90,
            tile_h,
            hwnd,
            IDC_CLOCK as HMENU,
            GetModuleHandleW(ptr::null()),
            ptr::null_mut(),
        );
        SetTimer(hwnd, IDT_CLOCK as usize, 1000, None);
    } else {
        MoveWindow(state.clock_hwnd, x, y, 90, tile_h, TRUE);
    }
}

unsafe fn update_clock(state: &AppState) {
    if state.clock_hwnd.is_null() || IsWindow(state.clock_hwnd) == 0 {
        return;
    }

    let mut st: SYSTEMTIME = mem::zeroed();
    GetLocalTime(&mut st);

    let mut buf: [u16; 16] = [0; 16];

    if !state.clock_show_date {
        // HH:MM
        let h = st.wHour;
        let m = st.wMinute;
        buf[0] = (b'0' + ((h / 10) % 10) as u8) as u16;
        buf[1] = (b'0' + (h % 10) as u8) as u16;
        buf[2] = ':' as u16;
        buf[3] = (b'0' + ((m / 10) % 10) as u8) as u16;
        buf[4] = (b'0' + (m % 10) as u8) as u16;
        buf[5] = 0;
    } else {
        // YYYY-MM-DD
        let y = st.wYear;
        let mo = st.wMonth;
        let d = st.wDay;
        buf[0] = (b'0' + ((y / 1000) % 10) as u8) as u16;
        buf[1] = (b'0' + ((y / 100) % 10) as u8) as u16;
        buf[2] = (b'0' + ((y / 10) % 10) as u8) as u16;
        buf[3] = (b'0' + (y % 10) as u8) as u16;
        buf[4] = '-' as u16;
        buf[5] = (b'0' + ((mo / 10) % 10) as u8) as u16;
        buf[6] = (b'0' + (mo % 10) as u8) as u16;
        buf[7] = '-' as u16;
        buf[8] = (b'0' + ((d / 10) % 10) as u8) as u16;
        buf[9] = (b'0' + (d % 10) as u8) as u16;
        buf[10] = 0;
    }

    SetWindowTextW(state.clock_hwnd, buf.as_ptr());
}

// ---------- Taskbar (window tracking) ----------

unsafe fn eq_ascii_utf16(buf: &[u16], s: &[u8]) -> bool {
    if buf.len() != s.len() {
        return false;
    }
    for (wc, &bc) in buf.iter().zip(s.iter()) {
        let c = (*wc as u8) as char;
        let sc = bc as char;
        if c.to_ascii_lowercase() != sc.to_ascii_lowercase() {
            return false;
        }
    }
    true
}

unsafe fn is_desktop_scaffolding(hwnd: HWND) -> bool {
    let mut cls_buf: [u16; 64] = [0; 64];
    let len = GetClassNameW(hwnd, cls_buf.as_mut_ptr(), 63);
    if len == 0 {
        return false;
    }
    let slice = &cls_buf[..len as usize];
    eq_ascii_utf16(slice, b"Progman") || eq_ascii_utf16(slice, b"WorkerW")
}

unsafe fn is_task_window(state: &AppState, hwnd: HWND) -> bool {
    if IsWindow(hwnd) == 0 || IsWindowVisible(hwnd) == 0 {
        return false;
    }
    if hwnd == state.main_hwnd || hwnd == state.start_menu_hwnd {
        return false;
    }
    if is_desktop_scaffolding(hwnd) {
        return false;
    }
    if state.is_cloaked(hwnd) {
        return false;
    }

    if GetAncestor(hwnd, GA_ROOT) != hwnd {
        return false;
    }
    if !GetWindow(hwnd, GW_OWNER).is_null() {
        return false;
    }

    let ex = GetWindowLongPtrW(hwnd, GWL_EXSTYLE) as LONG_PTR;
    if (ex as i32 & WS_EX_TOOLWINDOW as i32) != 0 {
        return false;
    }

    let mut title_buf: [u16; 2] = [0; 2];
    if GetWindowTextW(hwnd, title_buf.as_mut_ptr(), 2) == 0 {
        return false;
    }

    true
}

unsafe fn taskbar_update_title(state: &AppState, hwnd: HWND) {
    if state.task_toolbar_hwnd.is_null() {
        return;
    }
    for i in 0..state.task_button_count {
        let btn = &state.task_buttons[i];
        if btn.hwnd == hwnd {
            let mut new_title: [u16; 256] = [0; 256];
            let len = GetWindowTextW(hwnd, new_title.as_mut_ptr(), 255);
            if len <= 0 {
                let untitled = to_wstring("(Untitled)");
                for (dst, src) in new_title.iter_mut().zip(untitled.iter()) {
                    *dst = *src;
                }
            }

            let mut tbbi: TBBUTTONINFOW = mem::zeroed();
            tbbi.cbSize = mem::size_of::<TBBUTTONINFOW>() as u32;
            tbbi.dwMask = TBIF_TEXT;
            tbbi.pszText = new_title.as_mut_ptr();

            SendMessageW(
                state.task_toolbar_hwnd,
                TB_SETBUTTONINFOW,
                btn.id_command as WPARAM,
                &mut tbbi as *mut _ as LPARAM,
            );
            InvalidateRect(state.task_toolbar_hwnd, ptr::null(), TRUE);
            break;
        }
    }
}

unsafe fn taskbar_find_window_by_id(state: &AppState, id_cmd: i32) -> HWND {
    for i in 0..state.task_button_count {
        let btn = &state.task_buttons[i];
        if btn.id_command == id_cmd {
            return btn.hwnd;
        }
    }
    ptr::null_mut()
}

unsafe fn taskbar_clear(state: &mut AppState) {
    if !state.task_toolbar_hwnd.is_null() {
        let count =
            SendMessageW(state.task_toolbar_hwnd, TB_BUTTONCOUNT, 0, 0) as i32;
        for i in (0..count).rev() {
            SendMessageW(
                state.task_toolbar_hwnd,
                TB_DELETEBUTTON,
                i as WPARAM,
                0,
            );
        }
    }
    state.task_button_count = 0;
}

unsafe fn taskbar_add_window(state: &mut AppState, hwnd: HWND) {
    if state.task_toolbar_hwnd.is_null() || !is_task_window(state, hwnd) {
        return;
    }

    for i in 0..state.task_button_count {
        if state.task_buttons[i].hwnd == hwnd {
            return;
        }
    }
    if state.task_button_count >= MAX_TASK_BUTTONS {
        return;
    }

    let mut title: [u16; 256] = [0; 256];
    let len = GetWindowTextW(hwnd, title.as_mut_ptr(), 255);
    if len <= 0 {
        let untitled = to_wstring("(Untitled)");
        for (dst, src) in title.iter_mut().zip(untitled.iter()) {
            *dst = *src;
        }
    }

    let id_cmd = ID_TASKBTN_FIRST + state.task_button_count as i32;
    let i_string = SendMessageW(
        state.task_toolbar_hwnd,
        TB_ADDSTRINGW,
        0,
        title.as_mut_ptr() as LPARAM,
    );

    let mut tb: TBBUTTON = mem::zeroed();
    tb.iBitmap = I_IMAGENONE;
    tb.idCommand = id_cmd;
    tb.fsState = TBSTATE_ENABLED as u8;
    tb.fsStyle = (BTNS_BUTTON | BTNS_SHOWTEXT | BTNS_NOPREFIX) as u8;
    tb.iString = i_string as isize;

    SendMessageW(
        state.task_toolbar_hwnd,
        TB_ADDBUTTONSW,
        1,
        &mut tb as *mut _ as LPARAM,
    );

    let idx = state.task_button_count;
    state.task_buttons[idx] = TaskBtn {
        hwnd,
        id_command: id_cmd,
    };
    state.task_button_count += 1;
}

unsafe fn taskbar_remove_window(state: &mut AppState, hwnd: HWND) {
    if state.task_toolbar_hwnd.is_null() || hwnd.is_null() {
        return;
    }

    let mut idx: Option<usize> = None;
    for i in 0..state.task_button_count {
        if state.task_buttons[i].hwnd == hwnd {
            idx = Some(i);
            break;
        }
    }
    let idx = match idx {
        Some(i) => i,
        None => return,
    };

    SendMessageW(
        state.task_toolbar_hwnd,
        TB_DELETEBUTTON,
        idx as WPARAM,
        0,
    );

    for j in idx..(state.task_button_count - 1) {
        state.task_buttons[j] = state.task_buttons[j + 1];
    }
    state.task_button_count -= 1;
}

unsafe fn taskbar_set_active(state: &mut AppState, hwnd: HWND) {
    if state.task_toolbar_hwnd.is_null() {
        return;
    }

    for i in 0..state.task_button_count {
        let btn = &state.task_buttons[i];
        let state_bits = if btn.hwnd == hwnd {
            (TBSTATE_ENABLED | TBSTATE_CHECKED) as u8
        } else {
            TBSTATE_ENABLED as u8
        };
        SendMessageW(
            state.task_toolbar_hwnd,
            TB_SETSTATE,
            btn.id_command as WPARAM,
            MAKELONG(state_bits as WORD, 0) as LPARAM,
        );
    }
    InvalidateRect(state.task_toolbar_hwnd, ptr::null(), TRUE);
}

unsafe fn taskbar_activate_window(hwnd: HWND) {
    if hwnd.is_null() || IsWindow(hwnd) == 0 {
        return;
    }

    if IsIconic(hwnd) != 0 {
        ShowWindow(hwnd, SW_RESTORE);
        SetForegroundWindow(hwnd);
        return;
    }

    let fore = GetForegroundWindow();
    if fore == hwnd {
        ShowWindow(hwnd, SW_MINIMIZE);
        return;
    }

    let mut target_pid: DWORD = 0;
    let target_tid = GetWindowThreadProcessId(hwnd, &mut target_pid);
    let self_tid = GetCurrentThreadId();

    AllowSetForegroundWindow(ASFW_ANY);

    if target_tid != 0 && target_tid != self_tid {
        AttachThreadInput(self_tid, target_tid, TRUE);
        SetForegroundWindow(hwnd);
        BringWindowToTop(hwnd);
        SetFocus(hwnd);
        AttachThreadInput(self_tid, target_tid, FALSE);
    } else {
        SetForegroundWindow(hwnd);
        BringWindowToTop(hwnd);
        SetFocus(hwnd);
    }
}

unsafe extern "system" fn enum_init_proc(hwnd: HWND, _l_param: LPARAM) -> BOOL {
    with_app_state(|state| {
        taskbar_add_window(state, hwnd);
    });
    TRUE
}

// ---------- Main window procedure ----------

unsafe fn main_wnd_proc_inner(
    state: &mut AppState,
    hwnd: HWND,
    msg: UINT,
    w_param: WPARAM,
    l_param: LPARAM,
) -> LRESULT {
    // Prevent closing via system menu
    if (msg == WM_SYSCOMMAND && (w_param as u32 & 0xFFF0) == (SC_CLOSE as u32))
        || msg == WM_CLOSE
    {
        return 0;
    }

    // Shell hook messages
    if state.shell_hook_msg != 0 && msg == state.shell_hook_msg {
        match w_param as i32 {
            HSHELL_WINDOWCREATED => taskbar_add_window(state, l_param as HWND),
            HSHELL_WINDOWDESTROYED => taskbar_remove_window(state, l_param as HWND),
            HSHELL_WINDOWACTIVATED | HSHELL_RUDEAPPACTIVATED => {
                taskbar_set_active(state, l_param as HWND)
            }
            HSHELL_REDRAW => taskbar_update_title(state, l_param as HWND),
            _ => {}
        }
        return 0;
    }

    match msg {
        WM_CREATE => {
            state.main_hwnd = hwnd;
            state.init_dwm();
            state.bg_brush = CreateSolidBrush(rgb(0, 0, 0));
            state.btn_brush = CreateSolidBrush(rgb(24, 24, 24));
            position_taskbar_and_tiles(state, hwnd);
            update_clock(state);
            let shell_str = to_wstring("SHELLHOOK");
            state.shell_hook_msg = RegisterWindowMessageW(shell_str.as_ptr());
            RegisterShellHookWindow(hwnd);
            EnumWindows(Some(enum_init_proc), 0);
            taskbar_set_active(state, GetForegroundWindow());
            SetTimer(hwnd, IDT_AUTOSHOW as usize, 250, None);
            0
        }
        WM_ERASEBKGND => {
            let hdc = w_param as HDC;
            let mut rc: RECT = mem::zeroed();
            GetClientRect(hwnd, &mut rc);
            FillRect(hdc, &rc, state.bg_brush);
            1
        }
        WM_CTLCOLORSTATIC => {
            let hdc = w_param as HDC;
            SetBkMode(hdc, TRANSPARENT as i32);
            SetTextColor(hdc, rgb(255, 255, 255));
            state.bg_brush as LRESULT
        }
        WM_SIZE => {
            position_taskbar_and_tiles(state, hwnd);
            0
        }
        WM_MOUSEMOVE => {
            if !state.auto_hidden {
                // 30 seconds auto-hide delay
                SetTimer(hwnd, IDT_AUTOHIDE as usize, 30_000, None);
            }
            0
        }
        WM_TIMER => {
            match w_param as u32 {
                IDT_CLOCK => {
                    update_clock(state);
                }
                IDT_AUTOHIDE => {
                    KillTimer(hwnd, IDT_AUTOHIDE as usize);
                    if !state.auto_hidden {
                        let mut pt: POINT = mem::zeroed();
                        GetCursorPos(&mut pt);
                        let mut rc_bar: RECT = mem::zeroed();
                        GetWindowRect(hwnd, &mut rc_bar);
                        if PtInRect(&rc_bar, pt) == 0 {
                            hide_bar(state, hwnd);
                            if !state.start_menu_hwnd.is_null() {
                                DestroyWindow(state.start_menu_hwnd);
                                state.start_menu_hwnd = ptr::null_mut();
                            }
                        }
                    }
                }
                IDT_AUTOSHOW => {
                    if state.auto_hidden {
                        let mut pt: POINT = mem::zeroed();
                        GetCursorPos(&mut pt);
                        let screen_h = GetSystemMetrics(SM_CYSCREEN);
                        if pt.y >= screen_h - 1 {
                            show_bar(state, hwnd);
                        }
                    }
                }
                _ => {}
            }
            0
        }
        WM_COMMAND => {
            let id = loword(w_param as usize) as u32;
            let notif = hiword(w_param as usize) as u16;

            if id == ID_TILE_START {
                show_start_menu(state, hwnd);
            } else if id == IDC_CLOCK && notif == STN_CLICKED as u16 {
                state.clock_show_date = !state.clock_show_date;
                update_clock(state);
            } else if id >= ID_TASKBTN_FIRST as u32
                && id < (ID_TASKBTN_FIRST as u32 + MAX_TASK_BUTTONS as u32)
            {
                let hw = taskbar_find_window_by_id(state, id as i32);
                if !hw.is_null() {
                    taskbar_activate_window(hw);
                }
            }
            0
        }
        WM_NOTIFY => {
            let hdr = l_param as *mut NMHDR;
            if !hdr.is_null()
                && (*hdr).hwndFrom == state.task_toolbar_hwnd
                && (*hdr).code == NM_CUSTOMDRAW
            {
                return on_toolbar_custom_draw(l_param as *mut NMCUSTOMDRAW, state);
            }
            0
        }
        WM_DRAWITEM => {
            let dis = l_param as *mut DRAWITEMSTRUCT;
            draw_dark_button(dis, state);
            TRUE as LRESULT
        }
        WM_DESTROY => {
            KillTimer(hwnd, IDT_CLOCK as usize);
            KillTimer(hwnd, IDT_AUTOHIDE as usize);
            KillTimer(hwnd, IDT_AUTOSHOW as usize);
            if state.shell_hook_msg != 0 {
                DeregisterShellHookWindow(hwnd);
            }
            if !state.start_menu_hwnd.is_null() {
                DestroyWindow(state.start_menu_hwnd);
                state.start_menu_hwnd = ptr::null_mut();
            }
            taskbar_clear(state);
            if !state.bg_brush.is_null() {
                DeleteObject(state.bg_brush as HGDIOBJ);
                state.bg_brush = ptr::null_mut();
            }
            if !state.btn_brush.is_null() {
                DeleteObject(state.btn_brush as HGDIOBJ);
                state.btn_brush = ptr::null_mut();
            }
            state.dwm = None; // drop DwmApi if loaded
            PostQuitMessage(0);
            0
        }
        _ => DefWindowProcW(hwnd, msg, w_param, l_param),
    }
}

unsafe extern "system" fn main_wnd_proc(
    hwnd: HWND,
    msg: UINT,
    w_param: WPARAM,
    l_param: LPARAM,
) -> LRESULT {
    with_app_state(|state| main_wnd_proc_inner(state, hwnd, msg, w_param, l_param))
}

unsafe extern "system" fn start_menu_wnd_proc(
    hwnd: HWND,
    msg: UINT,
    w_param: WPARAM,
    l_param: LPARAM,
) -> LRESULT {
    with_app_state(|state| start_menu_wnd_proc_inner(state, hwnd, msg, w_param, l_param))
}

// ---------- Class registration & run ----------

unsafe fn register_all_classes(h_inst: HINSTANCE) {
    // Main window class
    let main_name = to_wstring("Shell95TilesMainWnd");
    let mut wc: WNDCLASSW = mem::zeroed();
    wc.lpfnWndProc = Some(main_wnd_proc);
    wc.hInstance = h_inst;
    wc.lpszClassName = main_name.as_ptr();
    wc.hCursor = LoadCursorW(ptr::null_mut(), IDC_ARROW);
    wc.hbrBackground = ptr::null_mut();
    wc.style = CS_DBLCLKS;
    RegisterClassW(&wc);

    // Start menu class
    let menu_name = to_wstring("Shell95StartMenu");
    let mut wc_menu: WNDCLASSW = mem::zeroed();
    wc_menu.lpfnWndProc = Some(start_menu_wnd_proc);
    wc_menu.hInstance = h_inst;
    wc_menu.lpszClassName = menu_name.as_ptr();
    wc_menu.hCursor = LoadCursorW(ptr::null_mut(), IDC_ARROW);
    wc_menu.hbrBackground = ptr::null_mut();
    RegisterClassW(&wc_menu);
}

unsafe fn run_app(h_inst: HINSTANCE) -> i32 {
    let mut icc: INITCOMMONCONTROLSEX = mem::zeroed();
    icc.dwSize = mem::size_of::<INITCOMMONCONTROLSEX>() as DWORD;
    icc.dwICC = ICC_WIN95_CLASSES;
    InitCommonControlsEx(&icc);

    register_all_classes(h_inst);

    let screen_w = GetSystemMetrics(SM_CXSCREEN);
    let screen_h = GetSystemMetrics(SM_CYSCREEN);

    let class_name = to_wstring("Shell95TilesMainWnd");

    let hwnd_main = CreateWindowExW(
        WS_EX_TOOLWINDOW,
        class_name.as_ptr(),
        ptr::null(),
        WS_POPUP | WS_VISIBLE,
        0,
        screen_h - BAR_H,
        screen_w,
        BAR_H,
        ptr::null_mut(),
        ptr::null_mut(),
        h_inst,
        ptr::null_mut(),
    );

    if hwnd_main.is_null() {
        let msg_w = to_wstring("Failed to create main window");
        let caption_w = to_wstring("retro95_shell_rust");
        MessageBoxW(
            ptr::null_mut(),
            msg_w.as_ptr(),
            caption_w.as_ptr(),
            MB_OK | MB_ICONERROR,
        );
        return 1;
    }

    with_app_state(|state| {
        state.main_hwnd = hwnd_main;
    });

    let mut msg: MSG = mem::zeroed();
    while GetMessageW(&mut msg, ptr::null_mut(), 0, 0) > 0 {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }

    msg.wParam as i32
}

fn main() {
    unsafe {
        let h_inst = GetModuleHandleW(ptr::null());
        let code = run_app(h_inst);
        std::process::exit(code);
    }
}
