#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include "win32_window.h"
#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <memory>

class FlutterWindow : public Win32Window {
 public:
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  void OnCreate() override;
  void OnDestroy() override;

 private:
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  const flutter::DartProject project_;
};

#endif
