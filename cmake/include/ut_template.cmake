PROGRAM(@UT_PRJNAME@${UT_SUFFIX})
SRCS(
    ${SOURCE_ROOT}/yggdrasil/contrib/gtest/src/gtest_main.cc
    @UT_SRCS@
)

SRCDIR (
    yggdrasil/contrib/gtest/include
)

PEERDIR(
    yggdrasil/contrib/gtest
)

DEBUGMESSAGE(3 "-- unittest: [@UT_PRJNAME @${UT_SUFFIX}], srcs: ${SRCS}")

CFLAGS(@CFLAGS@)
CXXFLAGS(@CXXFLAGS@)
SET(DTMK_I @DTMK_I@)
@UT_PERDIR_PEERDIR@
@UT_DEPENDS@

IF (UT_EXCLUDE_FROM_ALL)
    EXCLUDE_FROM_ALL()
ENDIF (UT_EXCLUDE_FROM_ALL)

ADD_DEPENDENCIES(all_ut @UT_PRJNAME@${UT_SUFFIX})

END()
