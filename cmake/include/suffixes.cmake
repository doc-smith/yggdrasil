SET(COMPILABLE_FILETYPES cpp c cxx cc h hpp hxx hh inc o def rc)

SET(SUFFIXES S cu)
foreach (__ext_ ${SUFFIXES})
    set(IS_SUFFIX.${__ext_} TRUE)
endforeach()

MACRO (BUILD_S_FILE srcfile dstfile)
    ADD_CUSTOM_COMMAND(
        OUTPUT ${dstfile}
        COMMAND ${CMAKE_C_COMPILER} -c ${srcfile} -o ${dstfile}
        MAIN_DEPENDENCY "${srcfile}"
        DEPENDS ${srcfile} ${ARGN}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Building ${dstfile} from ${srcfile} with ${CMAKE_C_COMPILER}"
    )
    SOURCE_GROUP("Custom Builds" FILES ${srcfile})
    SOURCE_GROUP("Generated" FILES ${dstfile})
    SRCS(${dstfile})
ENDMACRO (BUILD_S_FILE)

MACRO (BUILD_CUDA_FILE srcfile dstfile)
    SET(NVCC nvcc)
    #    SET(NVCCOPTS --compiler-options -fno-strict-aliasing -I. -I/usr/local/cuda/SDK/common/inc -I/usr/local/cuda/include -DUNIX -O3)
    ADD_CUSTOM_COMMAND(
        OUTPUT ${dstfile}
        COMMAND ${NVCC} ${NVCCOPTS} -c ${srcfile} -o ${dstfile}
        MAIN_DEPENDENCY "${srcfile}"
        DEPENDS ${srcfile} ${ARGN}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Building ${dstfile} from ${srcfile} with ${NVCC}"
    )
    SOURCE_GROUP("Custom Builds" FILES ${srcfile})
    SOURCE_GROUP("Generated" FILES ${dstfile})
    SRCS(${dstfile})
    #    CFLAGS(-fno-strict-aliasing -I/usr/local/cuda/SDK/common/inc -I/usr/local/cuda/include -DUNIX)
    SET_APPEND(DTMK_L -L/usr/local/cuda/lib -lcudart)
ENDMACRO (BUILD_CUDA_FILE)


MACRO (ADD_SRC_BUILDRULE ext srcfilename dstfilename_var)
    ENABLE(__isadded_)

    FOREACH (srcfile ${srcfilename} ${ARGN})
        GET_GLOBAL_DIRNAME(__srcitem_global_ "${srcfile}")
        DEBUGMESSAGE(2 "Checking ${__srcitem_global_}_PROPS[${${__srcitem_global_}_PROPS}]")
        SET(__src_DEPENDS_)
        IF (NOT "X${${__srcitem_global_}_PROPS}X" STREQUAL "XX")
            SET(__srcflag_name_)
            FOREACH(__srcflag_item_ ${${__srcitem_global_}_PROPS})
                IF (__srcflag_name_)
                    GET_SOURCE_FILE_PROPERTY(__srcfile_prop_ ${srcfile} ${__srcflag_name_})
                    IF (NOT __srcfile_prop_)
                        SET(__srcfile_prop_)
                    ENDIF (NOT __srcfile_prop_)
                    SET_APPEND(__srcfile_prop_ ${__srcflag_item_})
                    SET_SOURCE_FILES_PROPERTIES(${srcfilename} PROPERTIES
                        ${__srcflag_name_} "${__srcfile_prop_}")
                    IF (__srcflag_name_ STREQUAL "DEPENDS")
                        SET(__src_DEPENDS_ "${__src_DEPENDS_};${__srcfile_prop_}")
                    ENDIF (__srcflag_name_ STREQUAL "DEPENDS")
                    DEBUGMESSAGE(1 "ADD_SRC_BUILDRULE set ${__srcflag_name_} on ${srcfilename} with value[${__srcfile_prop_}]")
                    SET(__srcflag_name_)
                ELSE (__srcflag_name_)
                    SET(__srcflag_name_ ${__srcflag_item_})
                ENDIF (__srcflag_name_)
            ENDFOREACH(__srcflag_item_)
            IF (__src_DEPENDS_)
                SET(__src_DEPENDS_ DEPENDS ${__src_DEPENDS_})
                DEBUGMESSAGE(1 "------ __src_DEPENDS_ set to ${__src_DEPENDS_}")
            ENDIF (__src_DEPENDS_)
        ENDIF (NOT "X${${__srcitem_global_}_PROPS}X" STREQUAL "XX")
    ENDFOREACH ()

    IF ("${ext}" MATCHES "^.cpp$")
        # Nothing to do
    ELSEIF ("${ext}" MATCHES "^.S$")
        GET_FILENAME_COMPONENT(__S_path_ ${${dstfilename_var}} PATH)
        GET_FILENAME_COMPONENT(__S_namewe_ ${${dstfilename_var}} NAME_WE)
        SET(${dstfilename_var} ${__S_path_}/${__S_namewe_}.o)
        BUILD_S_FILE(${srcfilename} ${${dstfilename_var}} ${__src_DEPENDS_})
    ELSEIF ("${ext}" MATCHES "^.cu$")
        GET_FILENAME_COMPONENT(__S_path_ ${${dstfilename_var}} PATH)
        GET_FILENAME_COMPONENT(__S_namewe_ ${${dstfilename_var}} NAME_WE)
        SET(${dstfilename_var} ${__S_path_}/${__S_namewe_}.o)
        BUILD_CUDA_FILE(${srcfilename} ${${dstfilename_var}} ${__src_DEPENDS_})
    ELSE ("${ext}" MATCHES "^.cpp$")
        MESSAGE(SEND_ERROR "Error: Unknown extension. Don't know how to build ${srcfilename}")
        DISABLE(__isadded_)
    ENDIF ("${ext}" MATCHES "^.cpp$")
    IF (__isadded_)
        FOREACH (__flags_ COMPILE_FLAGS OBJECT_DEPENDS)
            GET_SOURCE_FILE_PROPERTY(__srccflags_ ${srcfilename} ${__flags_})
            IF (NOT "${${dstfilename_var}}" STREQUAL "${srcfilename}")
                GET_SOURCE_FILE_PROPERTY(__dstcflags_ ${${dstfilename_var}} ${__flags_})
            ENDIF (NOT "${${dstfilename_var}}" STREQUAL "${srcfilename}")
            IF (NOT __srccflags_)
                SET(__srccflags_)
            ENDIF (NOT __srccflags_)
            IF (NOT __dstcflags_)
                SET(__dstcflags_)
            ENDIF (NOT __dstcflags_)
            SET(__dstcflags_ ${__srccflags_} ${__dstcflags_})
            IF (__dstcflags_)
                SET_SOURCE_FILES_PROPERTIES(${${dstfilename_var}} PROPERTIES ${__flags_} "${__dstcflags_}")
                DEBUGMESSAGE(1, "------ ${${dstfilename_var}} PROPERTIES ${__flags_} ${__dstcflags_}")
            ENDIF (__dstcflags_)
            SET(__dstcflags_)
        ENDFOREACH (__flags_)
    ENDIF (__isadded_)
    DEBUGMESSAGE(1, "---- ADD_SRC_BUILDRULE: ${ext} ${srcfilename} ${${dstfilename_var}}")
ENDMACRO (ADD_SRC_BUILDRULE)
