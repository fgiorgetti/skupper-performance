#!/bin/bash

SUFFIX=""
[[ -n "${1}" ]] && SUFFIX="-${1}"
dir="`date +%Y%m%d`${SUFFIX}"
bkpdir="archive/${dir}"
mkdir -p ${bkpdir}
cp charts.html ${bkpdir}
mv results/ ${bkpdir}
( cd archive; tar zcvf ${dir}.tar.gz ${dir} )
