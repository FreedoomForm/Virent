#include "window.h"
namespace virent { LRESULT Window::Proc(HWND h, UINT m, WPARAM w, LPARAM l) { return DefWindowProcW(h,m,w,l); } }
