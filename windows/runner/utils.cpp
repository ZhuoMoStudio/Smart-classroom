#include "utils.h"
#include <iostream>
#include <windows.h>
void CreateAndAttachConsole() {
  if (::AllocConsole()) {
    FILE *unused;
    if (freopen_s(&unused, "CONOUT$", "w", stdout)) {}
    if (freopen_s(&unused, "CONOUT$", "w", stderr)) {}
    std::ios::sync_with_stdio();
  }
}
std::vector<std::string> GetCommandLineArguments() {
  int argc; LPWSTR *argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) return {};
  std::vector<std::string> result;
  for (int i = 0; i < argc; i++) {
    int len = ::WideCharToMultiByte(CP_UTF8, 0, argv[i], -1, nullptr, 0, nullptr, nullptr);
    std::string arg(len, 0);
    ::WideCharToMultiByte(CP_UTF8, 0, argv[i], -1, &arg[0], len, nullptr, nullptr);
    arg.pop_back();
    result.push_back(arg);
  }
  ::LocalFree(argv);
  return result;
}
