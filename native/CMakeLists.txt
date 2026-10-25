cmake_minimum_required(VERSION 3.22)
project(WaCaNative C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")   # static CRT: nothing extra to install

add_library(minhook STATIC
    third_party/minhook/src/buffer.c
    third_party/minhook/src/hook.c
    third_party/minhook/src/trampoline.c
    third_party/minhook/src/hde/hde64.c)
target_include_directories(minhook PUBLIC third_party/minhook/include)

add_library(WaCaNative SHARED
    WaCaNative/src/dllmain.cpp
    WaCaNative/src/input.cpp
    WaCaNative/src/text.cpp
    WaCaNative/src/ui.cpp
    WaCaNative/src/dev.cpp)
target_link_libraries(WaCaNative PRIVATE minhook)
target_compile_definitions(WaCaNative PRIVATE UNICODE _UNICODE WIN32_LEAN_AND_MEAN NOMINMAX)
set_target_properties(WaCaNative PROPERTIES OUTPUT_NAME main)
