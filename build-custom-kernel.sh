#! /bin/bash

command -v realpath >/dev/null 2>&1 || function realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

SOURCEDIR="$(dirname $(realpath $0))"
WORKDIR="$(mktemp -d)"

pushd "$WORKDIR" > /dev/null

# download Photon sources:
echo -n "Downloading sources ($WORKDIR)..."
curl -L https://github.com/vmware/photon/archive/master.tar.gz -o photon.tar.gz -s > /dev/null
echo "done"

# extract sources:
echo -n "Extracting sources..."
tar xf photon.tar.gz
mv photon-master photon
echo "done"

# Patch kernel
echo -n "Patching kernel SPEC..."
pushd photon > /dev/null
for PATCH in $(find "$SOURCEDIR/patches/linux-spec" -type f -name *.patch | sort); do
	echo "\tpatching $PATCH"
	patch --no-backup-if-mismatch -p0 --fuzz=0 -i $PATCH
done
popd > /dev/null
echo "done"

# Patch build script
echo -n "Patching build script..."
pushd photon > /dev/null
for PATCH in $(find "$SOURCEDIR/patches/build-script" -type f -name *.patch | sort); do
	echo "\tpatching $PATCH"
	patch --no-backup-if-mismatch -p0 --fuzz=0 -i $PATCH
done
popd > /dev/null
echo "done"

# Build RPM
photon/tools/scripts/build_spec.sh photon/SPECS/linux/linux-esx.spec

# Move output to sources
echo -n "Copying RPMs..."
mv photon/SPECS/linux/stage "$SOURCEDIR"
echo "done"

popd > /dev/null

# Clean up tmp files
echo -n "Cleaning up temporary files..."
rm -rf $WORKDIR
echo "done"
