#include "flutter_window.h"
#include <optional>

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

void FlutterWindow::OnCreate() {
  Win32Window::OnCreate();
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      GetDpiAwareWidth(), GetDpiAwareHeight(), project_);
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  flutter_controller_->engine()->SetNextFrameCallback([&]() { Show(); });
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_->ForceRedraw();
    flutter_controller_ = nullptr;
  }
  Win32Window::OnDestroy();
}
