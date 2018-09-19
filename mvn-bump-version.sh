#!/bin/bash

if [ ! -d "$1" ] || [ ! -f "$1/pom.xml" ]; then
	echo "You need to inform the pom.xml path"
	exit 1
fi

POM="$1/pom.xml"

CURRENT_VERSION=$(grep -m 1 -oE "<version>[0-9](\.[0-9])*\-SNAPSHOT</version>" "$POM" | awk 'match($0, /([0-9](\.[0-9]*-SNAPSHOT))/, ary) {print ary[0]}')
RELEASE_VERSION=$(grep -m 1 -oE "<version>[0-9](\.[0-9])*\-SNAPSHOT</version>" "$POM" | awk 'match($0, /([0-9](\.[0-9]*))/, ary) {print ary[0]}')
NEXT_VERSION=$(grep -m 1 -oE "<version>[0-9](\.[0-9])*\-SNAPSHOT</version>" "$POM" | awk 'match($0, /([0-9](\.[0-9]*))/, ary) {printf "%.1f%s", (ary[0] + 1.0), "-SNAPSHOT"}')

if [ "$2" == "-a" ] && [ ! -z "$3" ]; then
	echo "Append $3 in release version"
	RELEASE_VERSION=$3-$RELEASE_VERSION
fi

echo "Current version: $CURRENT_VERSION"
echo "Release version: $RELEASE_VERSION" 
echo "Next version: $NEXT_VERSION"

mvn clean -f $1
mvn versions:set -f $1 -DremoveSnapshot
mvn versions:set -f $1 -DnewVersion=$RELEASE_VERSION

(cd $1; git add pom.xml)
(cd $1; git commit -m "Release version $RELEASE_VERSION")
(cd $1; git tag $RELEASE_VERSION)
(cd $1; git push --tags)
mvn install -f $1
mvn versions:set -DnewVersion=$NEXT_VERSION -f $1
(cd $1; git add pom.xml)
(cd $1; git commit -m "New SNAPSHOT version $NEXT_VERSION")
(cd $1; git push)
rm $1/pom.xml.versionsBackup
