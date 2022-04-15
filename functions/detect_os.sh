#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
detect_os () {
    # Define compatible distros
    distros=("debian-11" "ubuntu-20.04" "ol-8.4")
    kernel_minimal="5.4"
    # Get Release data
    source /etc/os-release
    os=$ID"-"$VERSION_ID
    kernel_major=`uname -r | cut -d "." -f 1`
    kernel_minor=`uname -r | cut -d "." -f 2`
    # Check if distro is within compatible list
    (for distro in "${distros[@]}"; do [[ "$distro" == "$os" ]] && exit 0; done) && compatible_distro=1 || compatible_distro=0
    # Check if kernel is at least 5.4
    if [ $kernel_major -ge $(echo $kernel_minimal | cut -d "." -f 1) ] && [ $kernel_minor -ge $(echo $kernel_minimal | cut -d "." -f 2) ]; then
        compatible_kernel=1
    else
        compatible_kernel=0
    fi
    if [ -f "/etc/debian_version" ]; then
        os_family="debian"
    elif [ -f "/etc/redhat-release" ]; then
        os_family="redhat"
    fi
    if [ $compatible_distro == 1 ] && [ $compatible_kernel == 1 ]; then
            echo "This operating system is supported! :)"
        echo "Sistema detectado - $os, Kernel $kernel_major.$kernel_minor"
    else
        echo "This operating system is not supported! :( "
        echo "Detected O.S. - $os, Kernel $kernel_major.$kernel_minor"
        echo ""
        echo "The following operating systems are supported:"
        echo "Ubuntu Server 20.04"
        echo "Debian 11"
        echo "Oracle Enterprise Linux 8"
        echo ""
        echo "Minimum Kernel version: $kernel_minimal"
        exit 2
    fi

}
