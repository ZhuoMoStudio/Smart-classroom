#include "run_loop.h"
RunLoop::RunLoop() {}
RunLoop::~RunLoop() {}
void RunLoop::Run() {
  while (GetMessage(&msg_, nullptr, 0, 0)) {
    TranslateMessage(&msg_);
    DispatchMessage(&msg_);
  }
}
