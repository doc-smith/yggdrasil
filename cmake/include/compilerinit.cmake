SET(__no_paths_ NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_PATH NO_CMAKE_SYSTEM_PATH)

IF (NOT CMAKE_C_COMPILER OR NOT CMAKE_CXX_COMPILER)
    GET_FILENAME_COMPONENT(__cmake_incdir_ "${CMAKE_CURRENT_LIST_FILE}" PATH)
    INCLUDE("${__cmake_incdir_}/MakefileHelpers.cmake")
    INCLUDE("${__cmake_incdir_}/config.cmake")

    # This code will set C/CXX
    MESSAGE(STATUS "Will locate files with MY_GCC and MY_GPP set. Trying to find local.compiler.cmake...")
    SET(__incpath_
        ${CMAKE_SOURCE_DIR}/.. ${CMAKE_SOURCE_DIR}
        ${CMAKE_BINARY_DIR}/.. ${CMAKE_BINARY_DIR})
    INCLUDE_FROM(local.compiler.cmake ${__incpath_})
    IF (NOT MY_GCC OR NOT MY_GPP)
        MESSAGE(STATUS "Trying to find local.cmake...")
        INCLUDE_FROM(local.cmake ${__incpath_})
    ENDIF (NOT MY_GCC OR NOT MY_GPP)

    SET(ENVCC $ENV{CC})
    IF (CMAKE_C_COMPILER)
        SET(CC ${CMAKE_C_COMPILER})
    ELSEIF (MY_GCC)
        SET(CC ${MY_GCC})
    ELSEIF (ENVCC)
        SET(CC ${ENVCC})
    ELSEIF (NOT WIN32)
        FIND_PROGRAM(CC NAMES gcc45 gcc-4.5 gcc44 gcc-4.4 gcc43 gcc-4.3 PATHS ${__no_paths_})
    ENDIF (CMAKE_C_COMPILER)

    IF (CC)
        SET(CMAKE_C_COMPILER ${CC} CACHE FILEPATH "C compiler" FORCE)
        MESSAGE(STATUS "compilerinit: Using C compiler [${CMAKE_C_COMPILER}]")
    ENDIF (CC)

    SET(ENVCXX $ENV{CXX})
    IF (CMAKE_CXX_COMPILER)
        SET(CXX ${CMAKE_CXX_COMPILER})
    ELSEIF (MY_GPP)
        SET(CXX ${MY_GPP})
    ELSEIF (ENVCXX)
        SET(CXX ${ENVCXX})
    ELSEIF (NOT WIN32)
        FIND_PROGRAM(CXX NAMES g++45 g++-4.5 g++44 g++-4.4 g++43 g++-4.3 PATHS ${__no_paths_})
    ENDIF (CMAKE_CXX_COMPILER)

    IF (CXX)
        SET(CMAKE_CXX_COMPILER ${CXX} CACHE FILEPATH "C compiler" FORCE)
        MESSAGE(STATUS "compilerinit: Using C++ compiler [${CMAKE_CXX_COMPILER}]")
    ENDIF (CXX)

ENDIF (NOT CMAKE_C_COMPILER OR NOT CMAKE_CXX_COMPILER)
