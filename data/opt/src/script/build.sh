#!/bin/bash

DIR_INSTALL=/opt/pgmodeler
DIR_POSTGRESQL=/opt/postgresql
DIR_SRC=/opt/src
DIR_SRC_PGMODELER=${DIR_SRC}/pgmodeler
PATH=/opt/mxe/usr/bin:${PATH}
TOOLCHAIN=x86_64-w64-mingw32.shared

function clone_source() {
     cd ${DIR_SRC}

     git clone https://github.com/pgmodeler/pgmodeler.git
}

function clone_plugin_source() {
     cd ${DIR_SRC_PGMODELER}

     git clone https://github.com/pgmodeler/plugins.git
}

function checkout_version() {
     cd ${DIR_SRC_PGMODELER}

     local tags_file=$(mktemp)
     local latest_tag=$(git describe --tags $(git rev-list --tags --max-count=1))

     git tag >${tags_file}

     if [[ "${1}" =~ $(echo ^\($(paste -sd'|' ${tags_file})\)$) ]]; then
          git checkout tags/${1} -b master
     else
          git checkout tags/latest_tag -b master
     fi
}

function checkout_latest_branch() {
     cd ${DIR_SRC_PGMODELER}

     local latest_branch=$(git for-each-ref --format='%(refname:lstrip=3)' --sort=-creatordate --count 1)

     git checkout latest_branch
}

function build() {
     local dir_mxe=/opt/mxe
     local dir_mxe_toolchain=${dir_mxe}/usr/${TOOLCHAIN}
     local dir_qt=${dir_mxe_toolchain}/qt5
     local dir_plugins=${dir_qt}/plugins
     local dir_plugins_install=${DIR_INSTALL}/qtplugins
     local objdump=${dir_mxe}/usr/bin/${TOOLCHAIN}-objdump

     cd ${DIR_SRC_PGMODELER}

     # Replace some bits that are only relevant when building ON Windows.

     sed -i pgmodeler.pri -e 's/^.*wingetdate.*$/ BUILDNUM=$$system("date \x27+%Y%m%d\x27")/' pgmodeler.pri

     # Build pgModeler.

     ${TOOLCHAIN}-qmake-qt5 -r PREFIX=${DIR_INSTALL} PGSQL_INC=${DIR_POSTGRESQL}/include \
          PGSQL_LIB=${DIR_POSTGRESQL}/lib/libpq.dll XML_INC=${dir_mxe_toolchain}/include/libxml2 \
          XML_LIB=${dir_mxe_toolchain}/bin/libxml2-2.dll
     make
     make install
     rm ${DIR_INSTALL}/*.a

     # Copy dependencies.

     cd ${DIR_SRC}/pydeployqt

     ./deploy.py --build=${DIR_INSTALL} --objdump=${objdump} ${DIR_INSTALL}/pgmodeler.exe
     ./deploy.py --build=${DIR_INSTALL} --objdump=${objdump} ${DIR_INSTALL}/pgmodeler-ch.exe
     ./deploy.py --build=${DIR_INSTALL} --objdump=${objdump} ${DIR_INSTALL}/pgmodeler-cli.exe

     cp ${dir_qt}/bin/Qt5Network.dll ${DIR_INSTALL}
     cp ${dir_qt}/bin/Qt5PrintSupport.dll ${DIR_INSTALL}
     cp ${dir_qt}/bin/Qt5Svg.dll ${DIR_INSTALL}
     cp ${dir_mxe_toolchain}/bin/libcrypto-1_1-x64.dll ${DIR_INSTALL}
     cp ${dir_mxe_toolchain}/bin/liblzma-5.dll ${DIR_INSTALL}
     cp ${dir_mxe_toolchain}/bin/libssl-1_1-x64.dll ${DIR_INSTALL}
     cp ${dir_mxe_toolchain}/bin/libxml2-2.dll ${DIR_INSTALL}
     cp ${DIR_POSTGRESQL}/lib/libpq.dll ${DIR_INSTALL}

     # Add QT configuration.

     echo -e "[Paths]\nPrefix=.\nPlugins=qtplugins\nLibraries=." >${DIR_INSTALL}/qt.conf

     # Copy QT plugins.

     mkdir -p ${dir_plugins_install}/platforms

     cp -R ${dir_plugins}/imageformats ${dir_plugins_install}
     cp ${dir_plugins}/platforms/qwindows.dll ${dir_plugins_install}/platforms
     cp -R ${dir_plugins}/printsupport ${dir_plugins_install}
}

echo "Cloning latest source for pgmodeler ..."
clone_source

if [ "${1}" == "windeploy.sh" ]; then
     echo "Building using windeploy.sh..."
     cd ${DIR_SRC_PGMODELER}

     if [ "${2}" == "plugins" ]; then
          echo "Cloning latest source for plugins ..."
          clone_plugin_source
     fi

     chmod +x ./windeploy.sh
     sh ./windeploy.sh

     exit 0
fi

if [ "${1}" == "latest" ]; then
     echo "Checkout latest alpha/beta tag ..."
     checkout_latest_branch
else
     echo "Checkout custom tag (if provided) ..."
     checkout_version ${1}
fi

if [ "${2}" == "plugins" ]; then
     echo "Cloning latest source for plugins ..."
     clone_plugin_source
fi

echo 'Building using src/script/build.sh ...'
build
