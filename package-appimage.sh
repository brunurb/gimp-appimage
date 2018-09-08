#! /bin/bash

FULL_BUNDLING=0

VER_SUFFIX="$1"
#VER_SUFFIX="-cce"

PREFIX=zyx

APP=gimp
LOWERAPP=${APP,,} 

# Move blacklisted files to a special folder
move_blacklisted()
{
  mkdir -p ./usr/lib-blacklisted
if [ x"$FULL_BUNDLING" = "x1" ]; then
  BLACKLISTED_FILES=$(cat $APPIMAGEBASE/AppImages/excludelist | sed '/^\s*$/d' | sed '/^#.*$/d')
else
  #BLACKLISTED_FILES=$(wget -q https://github.com/probonopd/AppImages/raw/master/excludelist -O - | sed '/^\s*$/d' | sed '/^#.*$/d')
  BLACKLISTED_FILES=$(cat "$APPIMAGEBASE/excludelist" | sed '/^\s*$/d' | sed '/^#.*$/d')
fi
  echo $BLACKLISTED_FILES
  for FILE in $BLACKLISTED_FILES ; do
    FOUND=$(find . -type f -name "${FILE}" 2>/dev/null)
    if [ ! -z "$FOUND" ] ; then
      echo "Deleting blacklisted ${FOUND}"
      rm -f "${FOUND}"
      #mv "${FOUND}" ./usr/lib-blacklisted
    fi
  done
}


fix_pango()
{
	test=$(which pango-querymodules)
	if [ x"$test" != "x" ]; then
    	version=$(pango-querymodules --version | tail -n 1 | tr -d " " | cut -d':' -f 2)
    	cat /$PREFIX/lib/pango/$version/modules.cache | sed "s|/$PREFIX/lib/pango/$version/modules/||g" > usr/lib/pango/$version/modules.cache
    fi
}


mkdir -p /work || exit 1
cd /work || exit 1
rm -rf appimage-helper-scripts
git clone https://github.com/aferrero2707/appimage-helper-scripts.git  || exit 1
cd appimage-helper-scripts || exit 1
# Source the script:
source ./functions.sh


mkdir -p /work/appimage
cd /work/appimage || exit 1
rm -rf $APP
WD=$(pwd)


cp /work/appimage-helper-scripts/excludelist ./excludelist
export APPIMAGEBASE="$(pwd)"

#cat_file_from_url https://github.com/probonopd/AppImages/raw/master/excludelist | sed '/^\s*$/d' | sed '/^#.*$/d' > blacklisted

export PATH=/$PREFIX/bin:$PATH
export LD_LIBRARY_PATH=/$PREFIX/lib64:/$PREFIX/lib:$LD_LIBRARY_PATH
export XDG_DATA_DIRS=/$PREFIX/share:$XDG_DATA_DIRS
export PKG_CONFIG_PATH=/$PREFIX/lib/pkgconfig:/$PREFIX/share/pkgconfig:$PKG_CONFIG_PATH


pwd

echo "Start copying prefix..."
rm -rf /work/appimage/$APP/$APP.AppDir
mkdir -p /work/appimage/$APP/$APP.AppDir
cd /work/appimage/$APP/$APP.AppDir
mkdir -p usr/bin




GIMP_PREFIX=$(pkg-config --variable=prefix gimp-2.0)
if [ x"${GIMP_PREFIX}" = "x" ]; then
	echo "Could not determine GIMP installation prefix, exiting."
	exit 1
fi
cp -a ${GIMP_PREFIX}/bin/gimp* usr/bin
gimp_exe_name=$(cat ${GIMP_PREFIX}/share/applications/gimp.desktop | grep "^Exec=" | cut -d"=" -f 2 | cut -d" " -f 1)
rm -f usr/bin/$LOWERAPP.bin
echo "mv usr/bin/${gimp_exe_name} usr/bin/$LOWERAPP.bin"
mv usr/bin/${gimp_exe_name} usr/bin/$LOWERAPP.bin




PYTHON_PREFIX=$(pkg-config --variable=prefix python)
PYTHON_LIBDIR=$(pkg-config --variable=libdir python)
PYTHON_VERSION=$(pkg-config --modversion python)
if [ x"${PYTHON_PREFIX}" = "x" ]; then
	echo "Could not determine PYTHON installation prefix, exiting."
	exit 1
fi
if [ x"${PYTHON_LIBDIR}" = "x" ]; then
	echo "Could not determine PYTHON library path, exiting."
	exit 1
fi
if [ x"${PYTHON_VERSION}" = "x" ]; then
	echo "Could not determine PYTHON version, exiting."
	exit 1
fi
cp -a "${PYTHON_PREFIX}/bin"/python* usr/bin || exit 1
rm -rf "usr/lib/python${PYTHON_VERSION}"
mkdir -p usr/lib
cp -a "${PYTHON_LIBDIR}/python${PYTHON_VERSION}" usr/lib || exit 1
PYGLIB_LIBDIR=$(pkg-config --variable=libdir pygobject-2.0)
if [ x"${PYGLIB_LIBDIR}" = "x" ]; then
	echo "Could not determine PYGOBJECT library path, exiting."
	exit 1
fi
cp -a "${PYGLIB_LIBDIR}"/libpyglib*.so* usr/lib



gssapilib=$(ldconfig -p | grep 'libgssapi_krb5.so.2 (libc6,x86-64)'| awk 'NR==1{print $NF}')
if [ x"$gssapilib" != "x" ]; then
	gssapilibdir=$(dirname "$gssapilib")
	cp -a "$gssapilibdir"/libgssapi_krb5*.so* usr/lib
fi


#mkdir -p usr/lib
cp -a /$PREFIX/lib usr
cp -a /$PREFIX/etc usr
cp -a /$PREFIX/share usr
echo "... prefix copy completed"


mkdir -p usr/share
cp -a /usr/share/mime usr/share

#get_apprun
#cp -a $WD/AppRun-gimp AppRun
cp -a /sources/AppRun-gimp2 AppRun
cp /work/appimage-helper-scripts/apprun-helper.sh ./apprun-helper.sh

# The original desktop file is a bit strange, hence we provide our own
cat > $LOWERAPP.desktop <<\EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=GIMP AppImage
GenericName=Image Editor
Comment=Create images and edit photographs
Exec=LOWERAPP %f
TryExec=LOWERAPP
Icon=LOWERAPP
Terminal=false
Categories=Graphics;2DGraphics;RasterGraphics;GTK;
StartupNotify=true
MimeType=image/bmp;image/g3fax;image/gif;image/x-fits;image/x-pcx;image/x-portable-anymap;image/x-portable-bitmap;image/x-portable-graymap;image/x-portable-pixmap;image/x-psd;image/x-sgi;image/x-tga;image/x-xbitmap;image/x-xwindowdump;image/x-xcf;image/x-compressed-xcf;image/x-gimp-gbr;image/x-gimp-pat;image/x-gimp-gih;image/tiff;image/jpeg;image/x-psp;image/png;image/x-icon;image/x-exr;image/svg+xml;image/x-wmf;image/jp2;image/jpeg2000;image/jpx;image/x-xcursor;image/x-3fr;image/x-adobe-dng;image/x-arw;image/x-bay;image/x-canon-cr2;image/x-canon-crw;image/x-cap;image/x-cr2;image/x-crw;image/x-dcr;image/x-dcraw;image/x-dcs;image/x-dng;image/x-drf;image/x-eip;image/x-erf;image/x-fff;image/x-fuji-raf;image/x-iiq;image/x-k25;image/x-kdc;image/x-mef;image/x-minolta-mrw;image/x-mos;image/x-mrw;image/x-nef;image/x-nikon-nef;image/x-nrw;image/x-olympus-orf;image/x-orf;image/x-panasonic-raw;image/x-pef;image/x-pentax-pef;image/x-ptx;image/x-pxn;image/x-r3d;image/x-raf;image/x-raw;image/x-rw2;image/x-rwl;image/x-rwz;image/x-sigma-x3f;image/x-sony-arw;image/x-sony-sr2;image/x-sony-srf;image/x-sr2;image/x-srf;image/x-x3f;
EOF
sed -i -e "s|LOWERAPP|$LOWERAPP|g" $LOWERAPP.desktop


# Copy Qt5 plugins
QT5PLUGINDIR=$(pkg-config --variable=plugindir Qt5)
if [ x"$QT5PLUGINDIR" != "x" ]; then
  mkdir -p ./usr/lib/qt5/plugins
  cp -a "$QT5PLUGINDIR"/* ./usr/lib/qt5/plugins
fi

# manually copy libssl, as it seems not to be picked by the copy_deps function
cp -L /lib/x86_64-linux-gnu/libssl.so.1.0.0 ./usr/lib

# Copy in the indirect dependencies
# Three runs to ensure we catch indirect ones
copy_deps2 ; echo "copy_deps 1"; echo ""
copy_deps2 ; echo "copy_deps 2"; echo ""
copy_deps2 ; echo "copy_deps 3"; echo ""

#exit

#cp -a $PREFIX/lib/* usr/lib
#cp -a $PREFIX/lib64/* usr/lib
#cp -L $PREFIX/lib/*.so* usr/lib
#cp -L $PREFIX/lib64/*.so* usr/lib
#rm -rf $PREFIX

#cp -a ./lib/x86_64-linux-gnu/*.* ./usr/lib; rm -rf ./lib/x86_64-linux-gnu
#cp -a ./lib/*.* ./usr/lib; rm -rf ./lib;
#cp -a ./lib64/*.* ./usr/lib; rm -rf ./lib64;
#cp -a ./usr/lib64/*.* ./usr/lib; rm -rf ./usr/lib64;
#cp -a ./usr/lib/x86_64-linux-gnu/*.* ./usr/lib; rm -rf ./usr/lib/x86_64-linux-gnu;
#cp -a ./$PREFIX/lib/x86_64-linux-gnu/*.* ./usr/lib; rm -rf ./$PREFIX/lib/x86_64-linux-gnu;
#cp -a ./$PREFIX/lib/*.* ./usr/lib; rm -rf ./$PREFIX/lib;

#exit

(cd usr && mkdir -p lib64 && cd lib64 && rm -rf python${PYTHON_VERSION} && ln -s ../lib/python${PYTHON_VERSION} .) || exit 1
ls -l usr/lib64


ls usr/lib
move_lib
echo "After move_lib"
ls usr/lib

#delete_blacklisted
delete_blacklisted2
#move_blacklisted

#cp -a /$PREFIX/lib/libatk-bridge* usr/lib
#cp -a /$PREFIX/lib/libatspi.* usr/lib

#cp -a ../../appimage-exec-wrapper/exec.so usr/lib

#if [ ! -e ../../work/sources/mypaint ]; then
#    git clone https://github.com/mypaint/mypaint.git ../../work/sources/mypaint
#else
#    (cd ../../work/sources/mypaint && git pull origin master)
#fi
#mkdir -p usr/share/mypaint/brushes
#for brush in classic deevad experimental kaerhon_v1 ramon tanda; do
#    cp -r ../../work/sources/mypaint/brushes/$brush usr/share/mypaint/brushes
#done




########################################################################
# Copy libstdc++.so.6 and libgomp.so.1 into the AppImage
# They will be used if they are newer than those of the host
# system in which the AppImage will be executed
########################################################################

stdcxxlib=$(ldconfig -p | grep 'libstdc++.so.6 (libc6,x86-64)'| awk 'NR==1{print $NF}')
echo "stdcxxlib: $stdcxxlib"
if [ x"$stdcxxlib" != "x" ]; then
    mkdir -p usr/optional/libstdc++
	cp -L "$stdcxxlib" usr/optional/libstdc++
fi

gomplib=$(ldconfig -p | grep 'libgomp.so.1 (libc6,x86-64)'| awk 'NR==1{print $NF}')
echo "gomplib: $gomplib"
if [ x"$gomplib" != "x" ]; then
    mkdir -p usr/optional/libstdc++
	cp -L "$gomplib" usr/optional/libstdc++
fi



echo "Fixing pango modules cache"
fix_pango

#GTK_BINARY_VERSION=$(pkg-config --variable=gtk_binary_version gtk+-2.0)
#gtk-query-immodules-2.0 > /$PREFIX/lib/gtk-2.0/${GTK_BINARY_VERSION}/immodules.cache
#gtk-query-immodules-2.0-64 > /$PREFIX/lib/gtk-2.0/immodules.cache


GDK_PIXBUF_BINARYDIR=$(pkg-config --variable=gdk_pixbuf_binarydir gdk-pixbuf-2.0)
mkdir -p usr/lib/gdk-pixbuf-2.0
cp -a "${GDK_PIXBUF_BINARYDIR}"/loaders* usr/lib/gdk-pixbuf-2.0
#sed -i -e "s|/$PREFIX/lib/gdk-pixbuf-2.0/2.10.0/loaders/||g" usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
sed -i -e "s|$GDK_PIXBUF_BINARYDIR/loaders|LOADERSDIR|g" usr/lib/gdk-pixbuf-2.0/loaders.cache


# Copy the theme engines
mkdir -p usr/lib/gtk-2.0
GTK_LIBDIR=$(pkg-config --variable=libdir gtk+-2.0)
GTK_BINARY_VERSION=$(pkg-config --variable=gtk_binary_version gtk+-2.0)
cp -a "${GTK_LIBDIR}/gtk-2.0/${GTK_BINARY_VERSION}"/* usr/lib/gtk-2.0

#exit




#echo "Patching absolute paths"
# patch_usr
# Patching only the executable files seems not to be enough for darktable
#find usr/ -type f -exec sed -i -e "s|/$PREFIX|././|g" {} \;
#find usr/ -type f -exec sed -i -e "s|/usr|././|g" {} \;

# patch for using system-supplied python interpreter
cp /$PREFIX/lib/gimp/2.0/interpreters/pygimp.interp usr/lib/gimp/2.0/interpreters/pygimp.interp
#sed -i -e "s|/$PREFIX|/tmp/.gimp-appimage|g" usr/lib/gimp/2.0/interpreters/pygimp.interp
#sed -i -e "s|/usr|/tmp/.gimp-appimage|g" usr/lib/gimp/2.0/interpreters/pygimp.interp
#exit

# The fonts configuration should not be patched, copy back original one
#cp /$PREFIX/etc/fonts/fonts.conf usr/etc/fonts/fonts.conf
mkdir -p usr/share
cp -a /$PREFIX/share/fontconfig usr/share
cp /$PREFIX/etc/fonts/fonts.conf usr/share/fontconfig/fonts.conf
(cd usr/share/fontconfig && rm -f conf.d && ln -s conf.avail conf.d)


# The gimp icons should not be patched, copy back original one
cp -a /$PREFIX/share/gimp/2.0/icons usr/share/gimp/2.0

find ./usr/share/icons -path *256* -name gimp.png -exec cp {} $LOWERAPP.png  \; || true
find ./usr/share/icons -path *512* -name gimp.png -exec cp {} $LOWERAPP.png  \; || true


# Workaround for:
# GLib-GIO-ERROR **: Settings schema 'org.gtk.Settings.FileChooser' is not installed
# when trying to use the file open dialog
# AppRun exports usr/share/glib-2.0/schemas/ which might be hurting us here
#( mkdir -p usr/share/glib-2.0/schemas/ ; cd usr/share/glib-2.0/schemas/ ; ln -s /usr/share/glib-2.0/schemas/gschemas.compiled . )

# Workaround for:
# ImportError: /usr/lib/x86_64-linux-gnu/libgdk-x11-2.0.so.0: undefined symbol: XRRGetMonitors
cp $(ldconfig -p | grep libgdk-x11-2.0.so.0 | cut -d ">" -f 2 | xargs) ./usr/lib/
cp $(ldconfig -p | grep libgtk-x11-2.0.so.0 | cut -d ">" -f 2 | xargs) ./usr/lib/

appdir=$(pwd)
echo "appdir: $appdir"

pwd
(cd /work && rm -rf appimage-exec-wrapper && cp -a /sources/appimage-exec-wrapper appimage-exec-wrapper && cd appimage-exec-wrapper && make && cp -a exec.so $appdir/usr/lib/exec_wrapper.so) || exit 1
(cd /work/appimage-helper-scripts/appimage-exec-wrapper2 && make && cp -a exec.so $appdir/usr/lib/exec_wrapper2.so) || exit 1
#read dummy


# Package BABL/GEGL/GIMP header and pkg-config files, 
# so that the AppImage can be used to compile plug-ins
mkdir "$appdir/usr/include"
mkdir "$appdir/usr/lib/pkgconfig"
for dir in babl gegl gimp; do
  cp -a "/$AIPREFIX/include/${dir}-"* "$appdir/usr/include"
  cp -a "/$AIPREFIX/lib/pkgconfig/${dir}-"*.pc "$appdir/usr/lib/pkgconfig"
done
#tar czvf $appdir/usr/include.tgz /$AIPREFIX/include
#for dir in lib lib64 share; do
#  mkdir -p "$appdir/usr/$dir/pkgconfig" || exit 1
#  cp -a "/$AIPREFIX/$dir/pkgconfig"/*.pc "$appdir/usr/$dir/pkgconfig"
#done

# Strip binaries.
strip_binaries()
{
  chmod u+w -R "$appdir"
  {
    find $appdir/usr/bin/ -type f -name "gimp*" -print0
    find $appdir/usr/bin/ -type f -name "python*" -print0
    find "$appdir" -type f -regex '.*\.so\(\.[0-9.]+\)?$' -print0
  } | xargs -0 --no-run-if-empty --verbose -n1 strip
}

strip_binaries



#VER1=$(pkg-config --modversion gimp-2.0)-test
#VER1=$(pkg-config --modversion gimp-2.0)-$(date +%Y%m%d)
echo "GIMP_GIT_TAG = \"$GIMP_GIT_TAG\""
if [ x"$GIMP_GIT_TAG" = "x" ]; then
	VER1=git-$(pkg-config --modversion gimp-2.0)${VER_SUFFIX}-$(date +%Y%m%d)
else
	VER1=release-$(pkg-config --modversion gimp-2.0)${VER_SUFFIX}
fi
if [ x"$FULL_BUNDLING" = "x1" ]; then
    VER1="${VER1}-full"
fi
GLIBC_NEEDED=$(glibc_needed)
#VERSION=$VER1.glibc$GLIBC_NEEDED
VERSION=$VER1
echo $VERSION

get_desktopintegration $LOWERAPP
#cp -a ../../$LOWERAPP.wrapper ./usr/bin/$LOWERAPP.wrapper
#cp -a ../../desktopintegration ./usr/bin/$LOWERAPP.wrapper
#chmod a+x ./usr/bin/$LOWERAPP.wrapper
#sed -i -e "s|Exec=$LOWERAPP|Exec=$LOWERAPP.wrapper|g" $LOWERAPP.desktop

#exit

# Go out of AppImage
cd ..

echo "Building AppImage..."
pwd

export ARCH="x86_64"
export NO_GLIBC_VERSION=true
export DOCKER_BUILD=true
#generate_appimage
generate_type2_appimage

mkdir -p /sources/out
cp -a ../out/GIMP_AppImage-${VERSION}-${ARCH}.AppImage /sources/out