#ifndef RUNNER_RUN_LOOP_H_
#define RUNNER_RUN_LOOP_H_
#include <windows.h>
class RunLoop {
 public:
  RunLoop();
  ~RunLoop();
  void Run();
 private:
  MSG msg_;
};
#endif
