#!/bin/bash

IMAGE=$1
VERSION=$2

if [ "x$IMAGE" == "x" ] || [ "x$VERSION" == "x" ]; then
    echo "Usage: $0 IMAGE_PATH VERSION"
    exit 1
fi

echo "Importing $IMAGE..."
echo "Expected imported image namse are:"
echo -e "\tceosimage:$VERSION"
echo -e "\tceosimage:GNS3"

# cEOS-4.21.0F and newer, replace <version> by the cEOS version:
echo "Remove previous images if any"
docker rmi ceosimage:GNS3
docker rmi ceosimage:$VERSION
echo "Import a new one"
docker import $IMAGE ceosimage:$VERSION
docker images
sleep 3
echo "rm /etc/systemd/system/getty.target.wants/getty@tty1.service" | \
docker run --name=ceos-container -e CEOS=1 -e container=docker -e EOS_PLATFORM=ceoslab -e SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1 -e ETBA=1 -e INTFTYPE=eth -i ceosimage:$VERSION sh
docker ps -a
sleep 3
echo "Committing"
docker commit --change='CMD ["/sbin/init"]' --change='VOLUME /mnt/flash' ceos-container ceosimage:GNS3
sleep 3
echo "rm temporrary container"
docker rm ceos-container

echo ""
echo ""
echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
echo "Go to cEOS template setting in GNS3"
echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
echo ""
echo "# Put to start command:" 
echo "/sbin/init --privileged /sbin/init systemd.setenv=INTFTYPE=eth systemd.setenv=ETBA=1 systemd.setenv=SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1 systemd.setenv=CEOS=1 systemd.setenv=EOS_PLATFORM=ceoslab systemd.setenv=container=docker"
echo ""
echo "# Put to Env variables:"
echo "CEOS=1
container=docker
EOS_PLATFORM=ceoslab
SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1
ETBA=1
INTFTYPE=eth
MGMT_INTF=eth0"
echo ""
echo "Source: https://arista.my.site.com/AristaCommunity/s/article/veos-ceos-gns3-labs"
