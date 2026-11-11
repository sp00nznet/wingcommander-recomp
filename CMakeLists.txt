# Wing Commander and Wing Commander II (DOS), statically recompiled.
#
# Two executables, wingcommander and wingcommander2, each built only if its lifted C exists -- run
# `py tools/lift.py wc1` first. The lifted C is generated from your own copy of the game and is
# never committed; see README.
#
#   cmake -B build -G "Visual Studio 17 2022" -A x64
#   cmake --build build --config Release
#
# Linux and macOS (gcc or clang, SDL2 for the window, sound and pad):
#   cmake -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build
cmake_minimum_required(VERSION 3.20)
project(wingcommander C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
option(BSTONE_TRACE "record lifted calls and enable BSTONE_WATCH (slow)" OFF)

# pcrecomp supplies the CPU model (runtime/recomp16/cpu.h) and codeblob.h the lifted C uses.
set(PCRECOMP_HOME "$ENV{PCRECOMP_HOME}" CACHE PATH "pcrecomp checkout")
if(NOT PCRECOMP_HOME)
    foreach(cand ../pcrecomp-dos16-wc ../pcrecomp ../pcrecomp-main)
        if(EXISTS "${CMAKE_SOURCE_DIR}/${cand}/runtime/recomp16/codeblob.h")
            get_filename_component(PCRECOMP_HOME "${CMAKE_SOURCE_DIR}/${cand}" ABSOLUTE)
            break()
        endif()
    endforeach()
endif()
if(NOT EXISTS "${PCRECOMP_HOME}/runtime/recomp16/codeblob.h")
    message(FATAL_ERROR "pcrecomp not found: set PCRECOMP_HOME to a checkout of https://github.com/sp00nznet/pcrecomp")
endif()

if(MSVC)
    add_compile_options(/W1 /wd4996 /wd4244 /wd4146 /wd4102 /wd4101 /wd4267 /wd4018 /wd4305 /bigobj)
    add_compile_definitions(_CRT_SECURE_NO_WARNINGS)
    add_link_options(/STACK:16777216)   # lifted call chains are deep
    set(HOST_LIBS user32 gdi32 winmm)
else()
    if(NOT CMAKE_BUILD_TYPE)
        set(CMAKE_BUILD_TYPE Release)
    endif()
    # 16-bit arithmetic wraps, and the lifted C aliases freely
    add_compile_options(-w -fwrapv -fno-strict-aliasing)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(SDL2 REQUIRED IMPORTED_TARGET sdl2)
    set(HOST_LIBS PkgConfig::SDL2 m)
    if(APPLE)
        add_link_options(-Wl,-stack_size,0x1000000)   # lifted call chains are deep
    endif()
endif()

add_library(ymfm STATIC
    third_party/ymfm/ymfm_opl.cpp third_party/ymfm/ymfm_adpcm.cpp third_party/ymfm/ymfm_pcm.cpp)
target_include_directories(ymfm PUBLIC third_party/ymfm)

set(RUNTIME src/main.c src/machine.c src/dos.c src/vga.c src/audio.c src/x87.c
            src/host.c src/hires.c src/opl.cpp)

foreach(game wc1 wc2)
    if(game STREQUAL "wc1")
        set(exe wingcommander)
    else()
        set(exe wingcommander2)
    endif()
    set(gen "${CMAKE_SOURCE_DIR}/work/${game}/gen")
    if(EXISTS "${gen}/recomp_dispatch.c")
        file(GLOB lifted CONFIGURE_DEPENDS "${gen}/*.c")
        add_executable(${exe} WIN32 ${RUNTIME} ${lifted})
        target_include_directories(${exe} PRIVATE src "${gen}" "${PCRECOMP_HOME}/runtime")
        target_link_libraries(${exe} PRIVATE ymfm ${HOST_LIBS})
        if(BSTONE_TRACE)
            target_compile_definitions(${exe} PRIVATE RECOMP_TRACE BSTONE_DEBUG)
            if(MSVC)
                target_compile_options(${exe} PRIVATE /Zi /Oy-)
                target_link_options(${exe} PRIVATE /DEBUG)
            endif()
        endif()
        if(MSVC)
            # a console subsystem exe that still opens a window: stdout stays useful
            set_target_properties(${exe} PROPERTIES WIN32_EXECUTABLE OFF)
        endif()
    else()
        message(STATUS "${exe}: no lifted code in work/${game}/gen -- run tools/lift.py ${game}")
    endif()
endforeach()

# The hardware models on their own, no game data needed: what CI runs.
add_executable(selftest tests/selftest.c src/vga.c src/x87.c src/audio.c src/opl.cpp)
target_include_directories(selftest PRIVATE src "${PCRECOMP_HOME}/runtime")
target_link_libraries(selftest PRIVATE ymfm $<$<NOT:$<BOOL:${WIN32}>>:m>)
target_compile_definitions(selftest PRIVATE BSTONE_SELFTEST)
