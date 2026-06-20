cmake_minimum_required(VERSION 3.14)
project(smart_classroom LANGUAGES CXX)

set(BINARY_NAME "smart_classroom")
cmake_policy(SET CMP0063 NEW)
set(CMAKE_CXX_STANDARD 17)

add_subdirectory(${FLUTTER_MANAGED_DIR})

find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

add_executable(${BINARY_NAME}
  "flutter/generated_plugin_registrant.cc"
  "runner/main.cpp"
  "runner/flutter_window.cpp"
  "runner/run_loop.cpp"
  "runner/utils.cpp"
  "runner/win32_window.cpp"
)

apply_standard_settings(${BINARY_NAME})
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app PkgConfig::GTK)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

set_target_properties(${BINARY_NAME} PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/runner"
  WIN32_EXECUTABLE TRUE
)

set(CPACK_GENERATOR ZIP)
set(CPACK_PACKAGE_NAME "smart_classroom")
set(CPACK_PACKAGE_VERSION "1.0.0")
include(CPack)

install(DIRECTORY "${CMAKE_BINARY_DIR}/runner/"
  DESTINATION "data"
  FILES_MATCHING
  PATTERN "*.dll"
  PATTERN "*.so"
  PATTERN "*_plugin.*"
  PATTERN "*.dylib"
)

install(DIRECTORY "${CMAKE_BINARY_DIR}/flutter/"
  DESTINATION "data/flutter"
  FILES_MATCHING
  PATTERN "icudtl.dat"
)

install(FILES "${CMAKE_BINARY_DIR}/runner/${BINARY_NAME}.exe"
  DESTINATION ".")
