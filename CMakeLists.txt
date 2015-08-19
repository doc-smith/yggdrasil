CMAKE_MINIMUM_REQUIRED(VERSION 2.6 FATAL_ERROR)
CMAKE_POLICY(VERSION 2.6.0)

SET(SOURCE_ROOT ${CMAKE_CURRENT_SOURCE_DIR})

INCLUDE(${CMAKE_SOURCE_DIR}/cmake/include/global.cmake NO_POLICY_SCOPE)


SET(ROOT_PROJECTS
    test_project
)


IF (MAKE_ONLY)
    SET(__to_make_)
    FOREACH(__item_ ${MAKE_ONLY})
        IF ("${__item_}" STREQUAL "all")
            SET_APPEND(__to_make_ ${ROOT_PROJECTS})
        ELSE ("${__item_}" STREQUAL "all")
            IF (NOT EXISTS ${ARCADIA_ROOT}/${__item_})
                MESSAGE(SEND_ERROR "Directory \"${__item_}\" (listed in MAKE_ONLY) does not exist.")
            ELSE (NOT EXISTS ${ARCADIA_ROOT}/${__item_})
                SET_APPEND(__to_make_ ${__item_})
            ENDIF (NOT EXISTS ${ARCADIA_ROOT}/${__item_})
        ENDIF ("${__item_}" STREQUAL "all")
    ENDFOREACH(__item_ ${MAKE_ONLY})
    IF (__to_make_)
        SUBDIR(${__to_make_})
    ENDIF (__to_make_)
ELSE (MAKE_ONLY)
    SUBDIR(
        ${ROOT_PROJECTS}
    )
ENDIF (MAKE_ONLY)


INCLUDE(${CMAKE_SOURCE_DIR}/cmake/include/dtmk.cmake)
