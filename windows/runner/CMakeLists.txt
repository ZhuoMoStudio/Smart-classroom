cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "flutter_window.h"
  "main.cpp"
  "run_loop.cpp"
  "run_loop.h"
  "utils.cpp"
  "utils.h"
  "win32_window.cpp"
  "win32_window.h"
  "${CMAKE_SOURCE_DIR}/flutter/generated_plugin_registrant.cc"
  "Runner.rc"
)

target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

set_target_properties(${BINARY_NAME} PROPERTIES
  WIN32_EXECUTABLE TRUE
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)
