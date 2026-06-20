#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_
#include <windows.h>
#include <functional>
#include <string>

class Win32Window {
 public:
  struct Point { int x, y; Point(int x, int y) : x(x), y(y) {} };
  struct Size { int width, height; Size(int w, int h) : width(w), height(h) {} };

  Win32Window();
  virtual ~Win32Window();

  bool Create(const std::wstring& title, const Point& origin, const Size& size);
  void Destroy();
  void SetQuitOnClose(bool quit);
  void SetChildContent(HWND content);
  HWND GetHandle() const { return hwnd_; }
  float GetDpiScale();

 protected:
  virtual void OnCreate() {}
  virtual void OnDestroy();

  int GetDpiAwareWidth() const;
  int GetDpiAwareHeight() const;

 private:
  HWND hwnd_ = nullptr;
  HWND child_content_ = nullptr;
  bool quit_on_close_ = false;
  Size size_ = Size(1280, 720);

  static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);
  LRESULT HandleMessage(UINT msg, WPARAM wParam, LPARAM lParam);
};
#endif
