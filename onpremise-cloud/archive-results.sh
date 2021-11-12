#!/bin/bash

SUFFIX=""
[[ -n "${1}" ]] && SUFFIX="-${1}"
dir="`date +%Y%m%d`${SUFFIX}"
[[ -z "${dir}" ]] && echo "unable to generate destination directory" && exit 1
bkpdir="archive/${dir}"
[[ -d ${bkpdir} ]] && echo "${bkpdir} already exists - use a different suffix" && exit 1
mkdir -p ${bkpdir}
cp charts.html ${bkpdir}
mv results/ ${bkpdir}
( cd archive; tar zcvf ${dir}.tar.gz ${dir} && rm -rf ${dir} )
