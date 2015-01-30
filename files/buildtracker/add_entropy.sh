#!/bin/bash

# $RANDOM returns a different random integer at each invocation.
# Range: 0 - 32767 (unsigned 16-bit integer).

if [ $# -lt 2 ]; then
    echo "$(tput bold)USAGE$(tput sgr0)"
    printf "\t$0 yes|no PACKAGE\n"
    echo "$(tput bold)DESCRIPTION$(tput sgr0)"
    printf "\tAdds random workorder tokens to ./.config.\n"
    echo
    exit 1
fi

PACKAGE=$2

if [ "$1" = "yes" ]; then
    echo "# entropy" >> .config

    # 20% chance
    p=$RANDOM
    let "p %= 10"
    if [ "$p" -le 1 ]; then
        echo "TSWO_INSTALL_TARGET_TO_TOOLCHAIN=y" >> .config
    fi

    # 10% chance
    p=$RANDOM
    let "p %= 10"
    if [ "$p" -le 0 ]; then
        echo "TSWO_BUILD_DEBUG_PACKAGES=y" >> .config
    fi

    # 50% chance
    p=$RANDOM
    let "p %= 10"
    if [ "$p" -le 4 ]; then
        echo "TSWO_gcc_USE_HARDFP=y" >> .config
    fi

    # 10% chance
    p=$RANDOM
    let "p %= 10"
    if [ "$p" -le 0 ]; then
        echo "TSWO_gcc_BUILD_FORTRAN=y" >> .config
    fi

    # 10% chance
    p=$RANDOM
    let "p %= 10"
    if [ "$p" -le 0 ]; then
        echo "TSWO_gcc_BUILD_CXX=n" >> .config
    fi

    # 10% chance
    p=$RANDOM
    let "p %= 10"
    if [ "$p" -le 0 ]; then
        echo "TSWO_TOOLCHAIN_ELF=y" >> .config
    fi

    # 25% chance of one of the following:
    p=$RANDOM
    let "p %= 4"
    if [ "$p" -eq 0 ]; then
        echo "TSWO_PACKAGE_AS_TGZ=y" >> .config
    elif [ "$p" -eq 1 ]; then
        echo "TSWO_PACKAGE_AS_DEB=y" >> .config
    elif [ "$p" -eq 2 ]; then
        echo "TSWO_PACKAGE_AS_RPM=y" >> .config
    elif [ "$p" -eq 3 ]; then
        echo "TSWO_PACKAGE_AS_IPK=y" >> .config
    fi

    echo "" >> .config

    # 50% chance of generating rdeps
    p=$RANDOM
    let "p %= 2"
    if [ "$p" -eq 0 ]; then
        # select and add random number of reverse deps using Jerry's algorithm
        echo "# reverse dependencies" >> .config
        chmod +x add_rdeps.pl
        ./add_rdeps.pl $PACKAGE
        echo "" >> .config
    fi
fi
