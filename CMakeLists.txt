cmake_minimum_required(VERSION 3.28)

project(
  dpdk-exec
  VERSION 1.0
  LANGUAGES CXX
)

set_property(GLOBAL PROPERTY C_STANDARD 23)

list(PREPEND CMAKE_MODULE_PATH "${dpdk-exec_SOURCE_DIR}/cmake")
include(try_add_nixpkg)
include(CPM)

CPMAddPackage(
  NAME stdexec
  GITHUB_REPOSITORY NVIDIA/stdexec
  GIT_TAG main

  OPTIONS
    "STDEXEC_BUILD_EXAMPLES OFF"
    "STDEXEC_BUILD_TESTS OFF"
)


set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

add_compile_options(-Wall -Wextra -pedantic # -Werror stdexec is broken and fails compile due to lib warnings
    -Wno-unused-variable
)


set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fuse-ld=lld")
if (CMAKE_BUILD_TYPE MATCHES Debug) 
    message("building with sanatizers...")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=undefined")
    add_compile_options(-fno-omit-frame-pointer)
endif()

add_subdirectory(include)

find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBDPDK REQUIRED libdpdk)
