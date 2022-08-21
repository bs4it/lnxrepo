#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
detect_os () {
    # Define compatible distros
    distros=("debian-11" "ubuntu-20.04" "ol-8." "rhel-8.")
    kernel_minimal="5.4"
    # Get Release data
    source /etc/os-release
    os=$ID"-"$VERSION_ID
    kernel_major=`uname -r | cut -d "." -f 1`
    kernel_minor=`uname -r | cut -d "." -f 2`
    # Check if distro is within compatible list
    (for distro in "${distros[@]}"; do [[ "$os" == "$distro"* ]] && exit 0; done) && compatible_distro=1 || compatible_distro=0
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
    
    #if [ $compatible_distro == 1 ] && [ $compatible_kernel == 1 ]; then
    if [ $compatible_distro == 1 ]; then
            echo "This operating system is supported! :)"
        echo -e "Detected O.S. - \033[1;33m$os, \033[0mKernel \033[1;33m$kernel_major.$kernel_minor\033[0m   "
        # if [ $compatible_kernel == 0 ]; then
        #     echo -e "However your Kernel \033[1;33m$kernel_major.$kernel_minor\033[0m is not the best for using XFS. At least Kernel 5.4 is recommended."
        #     read -p "Press ENTER to continue."
        # fi
    else
        echo -e "\033[1;31mThis operating system is not supported! :( \033[0m"
        echo -e "\033[1;37mDetected O.S. - \033[1;33m$os, \033[1;37mKernel \033[1;33m$kernel_major.$kernel_minor\033[0m"
        echo -e ""
        echo -e "\033[1;37mThe following operating systems are supported:\033[0m"
        echo -e "\033[1;33mUbuntu Server 20.04\033[0m"
        echo -e "\033[1;33mDebian 11\033[0m"
        echo -e "\033[1;33mOracle Enterprise Linux 8\033[0m"
        echo -e "\033[1;33mRed Hat Enterprise Linux 8\033[0m"
        echo ""
        echo -e "\033[1;37mMinimum Kernel version: \033[1;33m$kernel_minimal\033[0m"
        read -p "Press ENTER to quit."
        exit 2
    fi

}
