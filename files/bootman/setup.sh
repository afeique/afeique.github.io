#!/bin/bash

set -o noclobber

if [[ $EUID -ne 0 ]]; then
    echo -e "error: script must be run as root\n" 1>&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "$(tput bold)USAGE$(tput sgr0)"
    echo -e "\t$0 BOARD KERNEL_IMAGE RFS_TARBALL [DEVICETREE_BLOB]\n"
    echo "$(tput bold)DESCRIPTION$(tput sgr0)"
    echo -e "\tCopies kernel image, RFS tarball, and optional devicetree to barn using NFS mounted directories. Inflates RFS tarball and then modifies barn symlinks to point to new kernel image and RFS directory.\n"
    echo
    exit 1
fi

BOARD=$1
KERNEL=$2
KERNEL_PATH=$(dirname $KERNEL)
KERNEL_FILENAME=$(basename $KERNEL)

# ensure kernel image exists
if [ ! -e $KERNEL ]; then
    echo -e "error: kernel image not found.\n"
    exit 1
fi

# ensure kernel image has nonzero size
if [ ! -s $KERNEL ]; then
    echo -e "error: kernel image is zero bytes.\n"
    exit 1
fi

RFS_TARBALL=$3
RFS_TARBALL_PATH=$(dirname $RFS_TARBALL)
RFS_TARBALL_FILENAME=$(basename $RFS_TARBALL)

# ensure rfs tarball exists
if [ ! -e $RFS_TARBALL ]; then
    echo -e "error: rfs tarball not found.\n"
    exit 1
fi

# ensure rfs tarball has nonzero size
if [ ! -s $RFS_TARBALL ]; then
    echo -e "error: rfs tarball is zero bytes.\n"
    exit 1
fi

DATE=date '+%Y%m%d_%H.%M.%S'
BARN_DIR=/mnt/barn01

BARN_KERNEL_SERV=$BARN_DIR/tftpboot
BARN_KERNEL_DIR=$BARN_KERNEL_SERV/$BOARD
BARN_KERNEL_FILENAME=bootman-image
BARN_KERNEL=$BARN_KERNEL_DIR/$BARN_KERNEL_FILENAME
BARN_ABS_KERNEL_PATH=/tftpboot/$BOARD/$BARN_KERNEL_FILENAME
BARN_KERNEL_SYM=$BARN_KERNEL_SERV/kernel_$BOARD

BARN_RFS_SERV=$BARN_DIR/data/boards/$BOARD
BARN_RFS_DIRNAME=bootman-rfs
BARN_RFS=$BARN_RFS_SERV/$BARN_RFS_DIRNAME
BARN_RFS_TARBALL=$BARN_RFS_SERV/$RFS_TARBALL_FILENAME
BARN_ABS_RFS_PATH=/data/boards/$BOARD/$BARN_RFS_DIRNAME
BARN_RFS_SYM=$BARN_RFS_SERV/rfs

DEVICETREE=$4
DEVICETREE_PATH=
DEVICETREE_FILENAME=
BARN_DEVICETREE=
if [ -n "$4" ]; then
    DEVICETREE_PATH=$(dirname $DEVICETREE)
    DEVICETREE_FILENAME=$(basename $DEVICETREE)
    BARN_DEVICETREE=$BARN_KERNEL_DIR/$DEVICETREE_FILE
fi

# make barn kernel dir if it doesn't exist
mkdir -p $BARN_KERNEL_DIR
if [ "$?" != "0" ]; then
    echo -e "error: unable to create directory BARN_KERNEL_DIR: $BARN_KERNEL_DIR\n"
    exit 40 # mkdir failed
fi

cp $KERNEL $BARN_KERNEL
if [ "$?" != "0" ]; then
    echo -e "error: unable to copy kernel to BARN_KERNEL_DIR: $BARN_KERNEL_DIR\n"
    exit 35 # cp failed
fi

# remove the old barn rfs dir
rm -rf $BARN_RFS

# remake barn rfs dir
mkdir -p $BARN_RFS
if [ "$?" != "0" ]; then
    echo -e "error: unable to create directory BARN_RFS: $BARN_RFS\n"
    exit 40 # mkdir failed
fi

# extract rfs tarball to barn rfs dir

# extract the contents of the tarball into the new bootman dir
tar -xf $RFS_TARBALL -C $BARN_RFS
if [ "$?" != "0" ]; then
    echo -e "error: problem extracting rfs tarball to BARN_RFS: $BARN_RFS\n"
    exit 70 # extract failed
fi

# update kernel symlink
rm $BARN_KERNEL_SYM
ln -s $BARN_ABS_KERNEL_PATH $BARN_KERNEL_SYM
if [ "$?" != "0" ]; then
    echo -e "error: problem creating kernel symlink: $BARN_KERNEL_SYM -> $BARN_ABS_KERNEL_PATH\n"
    exit 25 # symlink failed
fi

# update rfs symlink
rm $BARN_RFS_SYM
ln -s $BARN_ABS_RFS_PATH $BARN_RFS_SYM
if [ "$?" != "0" ]; then
    echo -e "error: problem extracting rfs symlink: $BARN_RFS_SYM -> $BARN_ABS_RFS_PATH\n"
    exit 25 # symlink failed
fi

if [ -n "$DEVICETREE" ]; then
    cp $DEVICETREE $BARN_DEVICETREE
    if [ "$?" != "0" ]; then
        echo -e "error: unable to copy device tree blob to BARN_DEVICETREE: $BARN_DEVICETREE\n"
        exit 35 # cp failed
    fi
fi
