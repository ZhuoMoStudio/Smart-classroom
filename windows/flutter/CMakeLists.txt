cmake_minimum_required(VERSION 3.14)
set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")
include("${EPHEMERAL_DIR}/generated_config.cmake" OPTIONAL)

add_subdirectory(${FLUTTER_MANAGED_DIR})
