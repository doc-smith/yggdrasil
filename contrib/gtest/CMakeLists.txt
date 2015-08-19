LIBRARY()

# basically, arguments of the SRCDIR macro will be appended to the list of include dirs
SRCDIR (
    yggdrasil/contrib/gtest/src
    yggdrasil/contrib/gtest/include
)

SRCS (
    gtest-all.cc
)

END()
