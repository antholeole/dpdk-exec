# https://gitlab.kitware.com/cmake/cmake/-/issues/23357: if you explicitly include
# a directory that is implicitly includeded, it is _not_ included. this is because
# they don't want to break order-dependent headers. This doesn't work for us, because
# the nix shell implicitly includes it but vsc*de doesn't so the cmake plugin can't 
# find it. Remove the found gbenchmark path from the implicit includes so we can 
# instead explicitly include it.
# it should be in the devshell or the drv or else it won't find.
function(try_add_nixpkg FILENAME)
    find_path(FOUND_DEP NAMES ${FILENAME} PATHS ENV CMAKE_PREFIX_PATH)
    if (FOUND_DEP)
        list(REMOVE_ITEM CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES ${FOUND_DEP})
        include_directories(PRIVATE ${FOUND_DEP})
    endif()
endfunction()
