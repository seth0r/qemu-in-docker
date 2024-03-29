#!/bin/bash

_term() {
    echo "Caught SIGTERM signal!"
    kill -TERM $children 2>/dev/null
}

trap _term SIGTERM

for i in `seq 3 -1 1`; do
    echo -ne "Starting in $i...   \r"
    sleep 1
done
echo "Starting...        "

if [ "$DIST" == "" -o "$HOSTNAME" == "" -o "$ROOT_PASSWORD" == "" ]; then
    echo "At least DIST, HOSTNAME and ROOT_PASSWORD has to be set."
    exit 1
fi

export DEBUG=${DEBUG:-0}
export BASEDIR=${BASEDIR:-/data}
export DISTDIR=${DISTDIR:-/dist}
export IMGNAME=${IMGNAME:-${HOSTNAME}_${DIST}.img}
export IMGFILE=${BASEDIR}/${IMGNAME}

export ISODIR="${BASEDIR}/iso"
mkdir -p "${ISODIR}"

export TMPDIR="${BASEDIR}/tmp"
mkdir -p "${TMPDIR}"
find "${TMPDIR}" -mindepth 1 -delete

if [ ! -f "${DISTDIR}/dist_${DIST}.sh" ]; then
    echo "Distribution ${DIST} not supported."
    exit 2
fi

source "${DISTDIR}/net.sh"
initnet
source "${DISTDIR}/ssh.sh"
genkeys

source "${DISTDIR}/src_general.sh"
source "${DISTDIR}/dist_${DIST}.sh"

set | grep "^NET_" > ${BASEDIR}/qemu.env
set | grep "^VM_" | sed 's/^VM_//' >> ${BASEDIR}/qemu.env

chmod 0777 "${BASEDIR}/"*

if [ ! -f "${IMGFILE}" ]; then
    resetknownhosts
    install || exit
    echo "Installation finished."
    sleep 10
    echo "Configuring system..."
    TARGETDIR=${TMPDIR}/target
    mkdir -p "${TARGETDIR}"
    tmount "${TARGETDIR}"
    
    basicconfig "${TARGETDIR}"

    touch "${TARGETDIR}/root/.inside_qemu"
    permitroot "${TARGETDIR}"
    copykeys "${TARGETDIR}/root/.ssh"

    source "${DISTDIR}/config.sh"

    umount "${TARGETDIR}"
    rmdir "${TARGETDIR}"
    echo "Configuration finished."
    sleep 10
fi
if [ -f ${IMGFILE} ]; then
    run
fi

wait $children
