cmake_minimum_required(VERSION 3.29)

project(dpdk-exec)

find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBDPDK REQUIRED libdpdk)

add_executable(dpdk-exec main.cpp)

target_compile_options(dpdk-exec PRIVATE ${LIBDPDK_STATIC_CFLAGS})
target_link_libraries(dpdk-exec ${LIBDPDK_STATIC_LDFLAGS})
