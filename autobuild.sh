#!/bin/sh

releasever="$1"
./build $releasever

testcontainer=$(buildah from "centos-stream-${releasever}-test")

if buildah run $testcontainer -- /usr/lib/rpm/rpmdb_verify /var/lib/rpm/Packages | grep -q 'succeeded'; then
        echo "rpmdb is sane"
else
        echo "rpmdb not sane"
	exit 1
fi

buildah run $testcontainer -- cat /etc/os-release

buildah rm "$testcontainer"

cat /etc/os-release
#buildah run $testcontainer -- /usr/lib/rpm/rpmdb_verify -q /var/lib/rpm/Packages

#buildah run $testcontainer -- echo $?
