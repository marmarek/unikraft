#!/bin/sh -ex
NAME="xenplat"

#TODO: we assume that we're building for X86_64, which we shouldn't do

prefix=${1:-$PREFIX}
if [ "$prefix" = "" ]; then
    prefix=`opam config var prefix`
fi
DESTINC=${prefix}/include/${NAME}
DESTLIB=${prefix}/lib/${NAME}
mkdir -p ${DESTINC} ${DESTLIB}

# xenplat
ar rcs libxenplat.a build/libxenplat/*.o
cp libxenplat.a ${DESTLIB}/libxenplat.a

# ukalloc
ar rcs libukalloc.a build/libukalloc/*.o
cp libukalloc.a ${DESTLIB}/libukalloc.a

# scheduler
ar rcs libsched.a build/libsched/*.o
ar rcs libschedcoop.a build/libschedcoop/*.o
cp libsched.a ${DESTLIB}/libsched.a
cp libschedcoop.a ${DESTLIB}/libschedcoop.a

# xen headers
UNIKRAFT_MISC=unikraft-misc-includes
mkdir -p ${DESTINC}/plat/xen/include
mkdir -p ${DESTINC}/${UNIKRAFT_MISC}
cp build/include/uk/_config.h ${DESTINC}/_config.h
cp -r plat/xen/include ${DESTINC}/plat/xen/
UNIKRAFT_MISC_INCLUDES="inttypes.h limits.h stdint.h"
for f in ${UNIKRAFT_MISC_INCLUDES}; do
    cp lib/nolibc/include/${f} ${DESTINC}/${UNIKRAFT_MISC}/${f}
done
cp -r include/uk ${DESTINC}/uk
cp -r lib/ukalloc/include/uk ${DESTINC}/uk
cp -r lib/uksched/include/uk ${DESTINC}/uk
cp -r lib/ukschedcoop/include/uk ${DESTINC}/uk

ARCH_CFLAGS="-m64 -mno-red-zone -fno-reorder-blocks -fno-asynchronous-unwind-tables"
# super portable, no problem (uh, TODO)
GCC_INSTALL=$(LANG=c gcc -print-search-dirs | sed -n -e 's/install: \(.*\)/\1/p')

# pkg-config
libname=lib${NAME}
sed \
  -e "s/@ARCH_LDFLAGS@/${ARCH_LDFLAGS}/g" \
  -e "s/@ARCH_CFLAGS@/${ARCH_CFLAGS}/g" \
  -e "s!@GCC_INSTALL@!${GCC_INSTALL}!g" \
  ${libname}.pc.in > ${libname}.pc
mkdir -p ${prefix}/lib/pkgconfig
cp ${libname}.pc ${prefix}/lib/pkgconfig/${libname}.pc
