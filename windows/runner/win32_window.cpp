#include "win32_window.h"
#include <dwmapi.h>
#include <windowsx.h>
#include <flutter_windows.h>
#include "resource.h"

namespace {
constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";
constexpr int kFlutterWindowDpiAware = 2;
int g_active_window_count = 0;
}

Win32Window::Win32Window() {}
Win32Window::~Win32Window() { Destroy(); }

bool Win32Window::Create(const std::wstring& title, const Point& origin, const Size& size) {
  Destroy();
  size_ = size;
  WNDCLASS window_class = RegisterWindowClass();
  hwnd_ = CreateWindow(window_class.lpszClassName, title.c_str(),
      WS_OVERLAPPEDWINDOW | WS_VISIBLE, origin.x, origin.y, size.width, size.height,
      nullptr, nullptr, window_class.hInstance, this);
  if (!hwnd_) return false;
  ++g_active_window_count;
  return true;
}

WNDCLASS Win32Window::RegisterWindowClass() {
  WNDCLASS wc = {};
  wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
  wc.lpszClassName = kWindowClassName;
  wc.style = CS_HREDRAW | CS_VREDRAW;
  wc.cbClsExtra = 0;
  wc.cbWndExtra = 0;
  wc.hInstance = GetModuleHandle(nullptr);
  wc.hIcon = LoadIcon(wc.hInstance, MAKEINTRESOURCE(IDI_APP_ICON));
  wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
  wc.lpszMenuName = nullptr;
  wc.lpfnWndProc = WndProc;
  RegisterClass(&wc);
  return wc;
}

void Win32Window::Destroy() {
  if (hwnd_) { DestroyWindow(hwnd_); hwnd_ = nullptr; --g_active_window_count; }
}

void Win32Window::SetQuitOnClose(bool quit) { quit_on_close_ = quit; }

void Win32Window::SetChildContent(HWND content) {
  child_content_ = content;
  SetParent(child_content_, hwnd_);
  RECT frame; GetClientRect(hwnd_, &frame);
  SetWindowPos(child_content_, nullptr, frame.left, frame.top,
      frame.right - frame.left, frame.bottom - frame.top, SWP_NOZORDER);
  ShowWindow(child_content_, SW_SHOW);
}

float Win32Window::GetDpiScale() {
  UINT dpi = GetDpiForWindow(hwnd_);
  return static_cast<float>(dpi) / 96.0f;
}

int Win32Window::GetDpiAwareWidth() const {
  UINT dpi = GetDpiForWindow(hwnd_);
  return MulDiv(size_.width, dpi, 96);
}

int Win32Window::GetDpiAwareHeight() const {
  UINT dpi = GetDpiForWindow(hwnd_);
  return MulDiv(size_.height, dpi, 96);
}

void Win32Window::OnDestroy() { if (quit_on_close_) PostQuitMessage(0); }

LRESULT CALLBACK Win32Window::WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
  if (msg == WM_NCCREATE) {
    auto* cs = reinterpret_cast<CREATESTRUCT*>(lParam);
    SetWindowLongPtr(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(cs->lpCreateParams));
    auto* that = static_cast<Win32Window*>(cs->lpCreateParams);
    that->hwnd_ = hwnd;
    RegisterTouchWindow(hwnd, 0);
    FlutterDesktopRegisterWindowProc(hwnd, FlutterDesktopWindowProc, that);
    FlutterDesktopMonitorWindow(hwnd, that);
  }
  auto* that = reinterpret_cast<Win32Window*>(GetWindowLongPtr(hwnd, GWLP_USERDATA));
  if (that) return that->HandleMessage(msg, wParam, lParam);
  return DefWindowProc(hwnd, msg, wParam, lParam);
}

LRESULT Win32Window::HandleMessage(UINT msg, WPARAM wParam, LPARAM lParam) {
  switch (msg) {
    case WM_SIZE: {
      RECT rect; GetClientRect(hwnd_, &rect);
      if (child_content_ != nullptr)
        SetWindowPos(child_content_, nullptr, rect.left, rect.top,
            rect.right - rect.left, rect.bottom - rect.top, SWP_NOZORDER);
      return 0;
    }
    case WM_DESTROY: OnDestroy(); return 0;
    case WM_CLOSE: Destroy(); return 0;
    default: return DefWindowProc(hwnd_, msg, wParam, lParam);
  }
}
