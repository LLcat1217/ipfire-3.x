#!/bin/bash

DISTDIR=/usr/portage/distfiles
PN=debugedit

set -e

echo "Getting updated index"
rm -f index.html
wget -q http://rpm5.org/

PV=$(sed -n '/Production:/{n;s:.*RPM ::;s:<.*::;p;q}' index.html)
PV=5.3.5
echo "Latest upstream version: ${PV}"
rm -f index.html

P="${PN}-${PV}"
A=${P}.tar.gz

echo "Fetching latest rpm tarball"
r=rpm-${PV}
wget -nv http://rpm5.org/files/rpm/rpm-${PV%.*}/${r}.tar.gz

echo "Unpacking ${r}"
rm -rf ${r}
tar xf ${r}.tar.gz

echo "Creating ${P}"
rm -rf ${P}
mkdir ${P}
cp Makefile ${r}/tools/{hashtab.?,debugedit.c} ${P}/
pushd ${P} >/dev/null
more=true
while ${more} ; do
	more=false
	for h in $(grep '#include' *.[ch] | awk '{print $NF}' | sed 's:[<>"]::g') ; do
		[[ ${h} == */* ]] && continue
		rh=$(find ../${r} -name ${h##*/})
		if [[ -n ${rh} ]] && [[ ! -e ${rh##*/} ]] ; then
			# don't copy glibc includes
			if ! grep -qs 'This file is part of the GNU C Library' ${rh} ; then
				cp ${rh} ./
				more=true
			fi
		fi
	done
done
popd >/dev/null
tar zcf ${A} ${P}

echo "Testing build"
pushd ${P} >/dev/null
make -s
popd >/dev/null

echo "Cleaning up"
rm -rf ${P} ${r}
du -b ${A}
