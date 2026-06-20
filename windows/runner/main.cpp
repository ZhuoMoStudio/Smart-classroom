#include "flutter_window.h"
#include "run_loop.h"
#include "utils.h"
#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  ::AttachConsole(ATTACH_PARENT_PROCESS);
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");
  project.set_dart_entrypoint_arguments({});

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"灵动课堂", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  RunLoop run_loop;
  run_loop.Run();

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
