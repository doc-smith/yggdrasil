# First, remove per-session cached variables

GET_CMAKE_PROPERTY(vars CACHE_VARIABLES)
FOREACH(item ${vars})
    IF (item MATCHES "_(DEPEND|WEAK)NAME_(LIB|PROG)")
        SET(${item} "" CACHE INTERNAL "" FORCE)
    ENDIF (item MATCHES "_(DEPEND|WEAK)NAME_(LIB|PROG)")
ENDFOREACH(item ${vars})

# Some variables are set here (please find details at http://www.cmake.org/Wiki/CMake_Useful_Variables)
SET(CMAKE_SKIP_ASSEMBLY_SOURCE_RULES yes)
SET(CMAKE_SKIP_PREPROCESSED_SOURCE_RULES yes)
SET(CMAKE_SKIP_BUILD_RPATH yes)

cmake_minimum_required(VERSION 2.8.0)

IF (COMMAND cmake_policy)
    cmake_policy(SET CMP0002 OLD)
    cmake_policy(SET CMP0000 OLD)
    cmake_policy(SET CMP0005 OLD)
    cmake_policy(SET CMP0003 NEW)
    cmake_policy(SET CMP0026 OLD)
    cmake_policy(SET CMP0045 OLD)
ENDIF(COMMAND cmake_policy)

IF (NOT DEFINED DEBUG_MESSAGE_LEVEL AND DEFINED DML)
    SET(DEBUG_MESSAGE_LEVEL ${DML})
ENDIF (NOT DEFINED DEBUG_MESSAGE_LEVEL AND DEFINED DML)

IF (LINUX)
    SET(REALPATH readlink)
    SET(REALPATH_FLAGS -f)
ELSEIF (FREEBSD)
    SET(REALPATH realpath)
    SET(REALPATH_FLAGS)
ENDIF (LINUX)

SET(SAVE_TEMPS $ENV{SAVE_TEMPS})

IF (NOT SOURCE_ROOT)
    IF (0) #REALPATH)
        EXECUTE_PROCESS(COMMAND ${REALPATH} ${REALPATH_FLAGS} "${CMAKE_SOURCE_DIR}"
            OUTPUT_VARIABLE SOURCE_ROOT
            OUTPUT_STRIP_TRAILING_WHITESPACE)
        SET(CMAKE_CURRENT_SOURCE_DIR ${SOURCE_ROOT})
        SET(CMAKE_SOURCE_DIR ${SOURCE_ROOT})
    ELSE (0) #REALPATH)
        SET(SOURCE_ROOT "${CMAKE_SOURCE_DIR}")
    ENDIF (0) #REALPATH)
    SET(SOURCE_ROOT "${SOURCE_ROOT}" CACHE PATH "Arcadia sources root dir" FORCE)
ENDIF (NOT SOURCE_ROOT)

IF (NOT SOURCE_BUILD_ROOT)
    IF (0) #REALPATH)
        EXECUTE_PROCESS(COMMAND ${REALPATH} ${REALPATH_FLAGS} "${CMAKE_BINARY_DIR}"
            OUTPUT_VARIABLE SOURCE_BUILD_ROOT
            OUTPUT_STRIP_TRAILING_WHITESPACE)
        SET(CMAKE_CURRENT_BINARY_DIR ${SOURCE_BUILD_ROOT})
        SET(CMAKE_BINARY_DIR ${SOURCE_BUILD_ROOT})
    ELSE (0) #REALPATH)
        SET(SOURCE_BUILD_ROOT "${CMAKE_BINARY_DIR}")
    ENDIF (0) #REALPATH)
    SET(SOURCE_BUILD_ROOT "${SOURCE_BUILD_ROOT}" CACHE PATH "Arcadia binary root dir" FORCE)
ENDIF (NOT SOURCE_BUILD_ROOT)

GET_FILENAME_COMPONENT(__cmake_incdir_ "${CMAKE_CURRENT_LIST_FILE}" PATH)

# Here - only macros like SET_APPEND
INCLUDE(${__cmake_incdir_}/MakefileHelpers.cmake)
# Set OS_NAME and OS-specific variables
INCLUDE(${__cmake_incdir_}/config.cmake)

IF (DONT_USE_FOLDERS)
    SET_PROPERTY(GLOBAL PROPERTY USE_FOLDERS OFF)
ELSE (DONT_USE_FOLDERS)
    SET_PROPERTY(GLOBAL PROPERTY USE_FOLDERS ON)
ENDIF (DONT_USE_FOLDERS)

SET_PROPERTY(GLOBAL PROPERTY PREDEFINED_TARGETS_FOLDER "_CMakeTargets")

SET(TEST_SCRIPTS_DIR ${SOURCE_ROOT}/test)

IF (NOT WIN32)
    SET(PLATFORM_SUPPORTS_SYMLINKS yes)
    ENABLE(USE_WEAK_DEPENDS) # It should be enabled in build platforms with many-projects-at-once building capability
ELSE (NOT WIN32)
    # Force vcproj generator not to include CMakeLists.txt and its custom rules into the project
    SET_IF_NOTSET(CMAKE_SUPPRESS_REGENERATION yes)
    # To set IDE folder for an arbitrary project please define <project name>_IDE_FOLDER variable.
    # For example, SET(gperf_IDE_FOLDER "tools/build")
    DEFAULT(CMAKE_DEFAULT_IDE_FOLDER "<curdir>")
ENDIF (NOT WIN32)

INCLUDE(${__cmake_incdir_}/buildrules.cmake)
INCLUDE_FROM(local.cmake ${SOURCE_ROOT}/.. ${SOURCE_ROOT} ${SOURCE_BUILD_ROOT}/.. ${SOURCE_BUILD_ROOT})
INCLUDE(${__cmake_incdir_}/deps.cmake)
DEFAULT (CALC_CMAKE_DEPS true)

MACRO (ON_CMAKE_START)
    IF (COMMAND ON_CMAKE_START_HOOK)
        ON_CMAKE_START_HOOK()
    ENDIF (COMMAND ON_CMAKE_START_HOOK)
    IF (CALC_CMAKE_DEPS)
        CMAKE_DEPS_INIT()
    ENDIF (CALC_CMAKE_DEPS)
ENDMACRO (ON_CMAKE_START)
# for symmetry
ON_CMAKE_START()

MACRO (ON_CMAKE_FINISH)
    IF (COMMAND ON_CMAKE_FINISH_HOOK)
        ON_CMAKE_FINISH_HOOK()
    ENDIF (COMMAND ON_CMAKE_FINISH_HOOK)
    IF (CALC_CMAKE_DEPS)
        CMAKE_DEPS_FINISH()
    ENDIF (CALC_CMAKE_DEPS)
ENDMACRO (ON_CMAKE_FINISH)


# Check that TMPDIR points to writable directory
SET(__tmpdir_ $ENV{TMPDIR})
IF (__tmpdir_)
    IF (NOT EXISTS ${__tmpdir_})
        MESSAGE(SEND_ERROR "TMPDIR env-variable is set (\"${__tmpdir_}\") but directory doesn't exist")
    ENDIF (NOT EXISTS ${__tmpdir_})
ENDIF (__tmpdir_)

SET_IF_NOTSET(LINK_STATIC_LIBS yes)
SET_IF_NOTSET(CHECK_TARGETPROPERTIES)

DEFAULT(UT_SUFFIX _ut)
IF (WIN32)
    DEFAULT(UT_PERDIR no)
ELSE (WIN32)
    DEFAULT(UT_PERDIR yes)
ENDIF (WIN32)

SET(__USE_GENERATED_BYK_ $ENV{USE_GENERATED_BYK})
IF ("X${__USE_GENERATED_BYK_}X" STREQUAL "XX")
    DEFAULT(USE_GENERATED_BYK yes)
ELSE ("X${__USE_GENERATED_BYK_}X" STREQUAL "XX")
    DEFAULT(USE_GENERATED_BYK $ENV{USE_GENERATED_BYK})
ENDIF ("X${__USE_GENERATED_BYK_}X" STREQUAL "XX")

SET($ENV{LC_ALL} "C")

IF (WIN32)
    SET(EXECUTABLE_OUTPUT_PATH ${SOURCE_BUILD_ROOT}/bin)
    SET(LIBRARY_OUTPUT_PATH    ${EXECUTABLE_OUTPUT_PATH})
ELSE (WIN32)
    SET(EXESYMLINK_DIR ${SOURCE_BUILD_ROOT}/bin)
    SET(LIBSYMLINK_DIR ${SOURCE_BUILD_ROOT}/lib)
ENDIF (WIN32)

IF (NO_UT_EXCLUDE_FROM_ALL)
    SET(UT_EXCLUDE_FROM_ALL "")
ELSE (NO_UT_EXCLUDE_FROM_ALL)
    SET(UT_EXCLUDE_FROM_ALL "EXCLUDE_FROM_ALL")
ENDIF (NO_UT_EXCLUDE_FROM_ALL)

# End of global build variables list

INCLUDE(${__cmake_incdir_}/tools.cmake)
INCLUDE(${__cmake_incdir_}/suffixes.cmake)

# Macro - get varname from ENV
MACRO(GETVAR_FROM_ENV)
    FOREACH (varname ${ARGN})
        IF (NOT DEFINED ${varname})
            SET(${varname} $ENV{${varname}})
        ENDIF (NOT DEFINED ${varname})
        DEBUGMESSAGE(1, "${varname}=${${varname}}")
    ENDFOREACH (varname)
ENDMACRO(GETVAR_FROM_ENV)

# Get some vars from ENV
GETVAR_FROM_ENV(MAKE_CHECK MAKE_ONLY USE_DISTCC USE_TIME COMPILER_PREFIX NOSTRIP)

IF (NOT MAKE_CHECK)
    MESSAGE(STATUS "MAKE_CHECK is negative")
ENDIF (NOT MAKE_CHECK)

IF (MAKE_RELEASE OR DEFINED release)
    SET(CMAKE_BUILD_TYPE Release)
ELSEIF (MAKE_COVERAGE OR DEFINED coverage)
    SET(CMAKE_BUILD_TYPE Coverage)
ELSEIF (MAKE_COVERAGE OR DEFINED profile)
    SET(CMAKE_BUILD_TYPE Profile)
ELSEIF (MAKE_VALGRIND OR DEFINED valgrind)
    SET(CMAKE_BUILD_TYPE Valgrind)
ELSEIF (DEFINED debug)
    SET(CMAKE_BUILD_TYPE Debug)
ELSE (MAKE_RELEASE OR DEFINED release)
    # Leaving CMAKE_BUILD_TYPE intact
ENDIF (MAKE_RELEASE OR DEFINED release)

# Default build type - DEBUG
IF (NOT WIN32 AND NOT CMAKE_BUILD_TYPE)
    SET(CMAKE_BUILD_TYPE Debug)
ENDIF (NOT WIN32 AND NOT CMAKE_BUILD_TYPE)

IF (NOT "X${CMAKE_BUILD_TYPE}X" STREQUAL "XX")
    # Enable MAKE_<config> to simplify checks
    STRING(TOUPPER "${CMAKE_BUILD_TYPE}" __upcase_)
    ENABLE(MAKE_${__upcase_})
ENDIF (NOT "X${CMAKE_BUILD_TYPE}X" STREQUAL "XX")

MACRO (CACHE_VAR __cached_varname_ __argn_varname_ varname type descr)
    IF (DEFINED ${varname})
        SET(${__cached_varname_} "${${__cached_varname_}} ${varname}[${${varname}}]")
        SET(${varname} "${${varname}}" CACHE ${type} "${descr}" FORCE)
        DEBUGMESSAGE(1, "Caching ${varname}[${${varname}}]")
    ENDIF (DEFINED ${varname})
    SET(${__argn_varname_} ${ARGN})
ENDMACRO (CACHE_VAR varname type string)

MACRO (CACHE_VARS)
    SET(__cached_)
    SET(__vars_ ${ARGN})
    WHILE(NOT "X${__vars_}X" STREQUAL "XX")
        CACHE_VAR(__cached_ __vars_ ${__vars_})
    ENDWHILE(NOT "X${__vars_}X" STREQUAL "XX")
    IF (__cached_)
        MESSAGE(STATUS "Cached:${__cached_}")
    ENDIF (__cached_)
ENDMACRO (CACHE_VARS)

SET(METALIBRARY_NAME CMakeLists.lib)
SET(METALIB_LIST "")

# Save CMAKE_BUILD_TYPE, MAKE_CHECK etc.
CACHE_VARS(
    MAKE_ONLY STRING "Used to strip buildtree. May contain zero or more paths relative to SOURCE_ROOT"
    MAKE_CHECK BOOL "Excludes projects with positive NOCHECK"
    CMAKE_BUILD_TYPE STRING "Build type (Release, Debug, Valgrind, Profile, Coverage)"
    USE_CCACHE BOOL "Adds 'ccache' prefix to c/c++ compiler line"
    USE_DISTCC BOOL "Adds 'distcc' prefix to c/c++ compiler line"
    USE_TIME BOOL "Adds 'time' prefix to c/c++ compiler line"
    COMPILER_PREFIX STRING "Adds arbitrary prefix to c/c++ compiler line"
)

# processed_dirs.txt holds all processed directories
SET(PROCESSED_DIRS_FILE ${SOURCE_BUILD_ROOT}/processed_dirs.txt)
FILE(WRITE "${PROCESSED_DIRS_FILE}" "Empty\n")
SET(PROCESSED_TARGETS_FILE ${SOURCE_BUILD_ROOT}/processed_targets.txt)
FILE(WRITE "${PROCESSED_TARGETS_FILE}" "Empty\n")

# init some files
# The first file holds <target name> <source path> <target file name> for all targets
SET(__filenames_
    TARGET_LIST_FILENAME target.list
    EXCLTARGET_LIST_FILENAME excl_target.list
    TEST_LIST_FILENAME test.list
    TEST_DART_TMP_FILENAME __test.dart.tmp
    TEST_DART_FILENAME test.dart
    UNITTEST_LIST_FILENAME unittest.list
)

SET(__filename_)
FOREACH (__item_ ${__filenames_})
    IF (DEFINED __filename_)
        SET_IF_NOTSET(${__filename_} "${SOURCE_BUILD_ROOT}/${__item_}")
        FILE(WRITE "${${__filename_}}" "")
        SET(__filename_)
    ELSE ()
        SET(__filename_ "${__item_}")
    ENDIF ()
ENDFOREACH ()

FILE(WRITE "${TEST_DART_TMP_FILENAME}"
    "=============================================================\n")


# c/c++ flags, compilers, etc.

IF (COMPILER_PREFIX)
    SET(CMAKE_CXX_COMPILE_OBJECT "${COMPILER_PREFIX} ${CMAKE_CXX_COMPILE_OBJECT}")
    SET(CMAKE_C_COMPILE_OBJECT "${COMPILER_PREFIX} ${CMAKE_C_COMPILE_OBJECT}")
    DEBUGMESSAGE(1, "COMPILER_PREFIX=${COMPILER_PREFIX}")
ENDIF (COMPILER_PREFIX)

IF (USE_DISTCC)
    IF (USE_CCACHE)
        SET(CMAKE_CXX_COMPILE_OBJECT "CCACHE_PREFIX=distcc ${CMAKE_CXX_COMPILE_OBJECT}")
        SET(CMAKE_C_COMPILE_OBJECT   "CCACHE_PREFIX=distcc ${CMAKE_C_COMPILE_OBJECT}")
        DEBUGMESSAGE(1, "USE_DISTCC: set distcc as ccache prefix")
    ELSE (USE_CCACHE)
        SET(CMAKE_CXX_COMPILE_OBJECT "distcc ${CMAKE_CXX_COMPILE_OBJECT}")
        SET(CMAKE_C_COMPILE_OBJECT   "distcc ${CMAKE_C_COMPILE_OBJECT}")
        DEBUGMESSAGE(1, "USE_DISTCC: set distcc as compiler prefix")
    ENDIF (USE_CCACHE)

    DEBUGMESSAGE(1, "USE_DISTCC=${USE_DISTCC}")
ENDIF (USE_DISTCC)

IF (USE_TIME)
    SET(__time_compile_logfile_ ${SOURCE_BUILD_ROOT}/time.compile.log)
    SET(__time_link_logfile_    ${SOURCE_BUILD_ROOT}/time.link.log)
    DEFAULT(TIME "/usr/bin/time")
    FOREACH(__i_ CMAKE_C_COMPILE_OBJECT CMAKE_CXX_COMPILE_OBJECT)
        SET(${__i_} "${TIME} -ap -o ${__time_compile_logfile_} ${${__i_}}")
    ENDFOREACH(__i_)
    FOREACH(__i_ CMAKE_C_LINK_EXECUTABLE CMAKE_CXX_LINK_EXECUTABLE CMAKE_C_CREATE_SHARED_LIBRARY CMAKE_CXX_CREATE_SHARED_LIBRARY)
        SET(${__i_} "${TIME} -ap -o ${__time_link_logfile_} ${${__i_}}")
    ENDFOREACH(__i_)
    DEBUGMESSAGE(1, "USE_TIME=${USE_TIME}")
ENDIF (USE_TIME)

IF (NOT DEFINED PRINTCURPROJSTACK)
    IF ("${DEBUG_MESSAGE_LEVEL}" GREATER "0")
        SET(PRINTCURPROJSTACK yes CACHE INTERNAL "")
    ELSE ("${DEBUG_MESSAGE_LEVEL}" GREATER "0")
        SET(PRINTCURPROJSTACK no)
    ENDIF ("${DEBUG_MESSAGE_LEVEL}" GREATER "0")
ENDIF (NOT DEFINED PRINTCURPROJSTACK)

ADD_CUSTOM_TARGET(all_ut)
SET_PROPERTY(TARGET "all_ut" PROPERTY FOLDER "_CMakeTargets")

# Use cmake exclusion list, optional
DEFAULT(EXCLUDE_PROJECTS "")
IF (EXISTS ${SOURCE_BUILD_ROOT}/exclude.cmake)
    FILE(STRINGS ${SOURCE_BUILD_ROOT}/exclude.cmake EXCLUDE_PROJECTS)
ENDIF (EXISTS ${SOURCE_BUILD_ROOT}/exclude.cmake)
DEBUGMESSAGE(1 "exclude list: ${EXCLUDE_PROJECTS}")


