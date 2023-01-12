#!/bin/bash

# This script will remove all already installed Nvidia Drivers (if present) and initiate a clan install of Nvidia Drivers and CUDA. 

### IMPORTANT ###
# The version of Graphic driver and CUDA must match the Driver installed on the host!
# The desired Graphic driver and CUDA version must be specified in the variables: NVIDAIA_VERSION_MAJOR, NVIDIA_VERSION_MINOR and CUDA_VERSION!
# The UBUNTU_VERSION_MAJOR variable must match the Ubuntu version the LXD Container is runningon!

# Vars
NVIDIA_VERSION_MAJOR=510
NVIDIA_VERSION_MINOR=73.08
NVIDIA_VERSION_FULL="$NVIDIA_VERSION_MAJOR"_"$NVIDIA_VERSION_MAJOR"."$NVIDIA_VERSION_MINOR"
NVIDIA_VERSION_SHORT="$NVIDIA_VERSION_MAJOR"."$NVIDIA_VERSION_MINOR"
UBUNTU_VERSION_MAJOR=18
CUDA_VERSION=11.6.0
INSTALL_PATH=$PWD/install-nvidia-driver

echo "############################################################################"
echo "=== Nvidia GPU Driver $NVIDIA_VERSION_SHORT and CUDA $CUDA_VERSION will now be installed ==="

echo "Checking if NVIDIA Drivers are already installed"

apt list --installed | grep nvidia

if [ $? -eq 0 ]; then
    echo "Removing already installed NVIDIA Drivers"
    apt-get remove --purge 'libnvidia-*' 'nvidia-*'
else
    echo "No NVIDIA Drivers were found"	
fi

echo "############################################################################"
echo "Trying to install Nvidia GPU Driver $NVIDIA_VERSION_SHORT from Ubuntu repository..."

apt update &> /dev/null
apt install nvidia-driver-$NVIDIA_VERSION_MAJOR-server=$NVIDIA_VERSION_SHORT-0ubuntu0.$UBUNTU_VERSION_MAJOR.04.1 -y &> /dev/null

NVIDIA_DRIVER_INSTALL_RESULT=$?

if [ $NVIDIA_DRIVER_INSTALL_RESULT -eq 0 ]; then
    echo "Installation of Nvidia GPU Driver $NVIDIA_VERSION_SHORT was succesfull!"
    # Install CUDA.
    echo "Installing CUDA $CUDA_VERSION..."
    wget -q http://developer.download.nvidia.com/compute/cuda/11.0.2/local_installers/cuda_11.0.2_450.51.05_linux.run -P $INSTALL_PATH
    sh $INSTALL_PATH/cuda_11.0.2_450.51.05_linux.run --silent --toolkit
    echo "export PATH="/usr/local/cuda-11.0/bin:$PATH"" >> /root/.bashrc
    echo "/usr/local/cuda-11.0/lib64" >> /etc/ld.so.conf && ldconfig
    echo "Installation of CUDA $CUDA_VERSION was succesfull!"
    echo "Installation of Nvidia GPU driver $NVIDIA_VERSION_SHORT and Cuda $CUDA_VERSION is now complate!"
else
    echo "Nvidia Driver GPU $NVIDIA_VERSION_SHORT was not found in Ubuntu repository."
    echo "Installing Nvidia Driver $NVIDIA_VERSION_SHORT manually..."
    # Download Nvidia GPU Driver dependencies from Nvidia repository.
    mkdir -p $INSTALL_PATH

    nvidia_dependencies=(
	libnvidia-ifr1
        libnvidia-gl
        libnvidia-cfg1
        libnvidia-fbc1
        libnvidia-decode
        libnvidia-encode
        libnvidia-compute
        libnvidia-extra
        nvidia-dkms
        nvidia-kernel-source
        nvidia-kernel-common
        nvidia-compute-utils
        nvidia-utils
        xserver-xorg-video-nvidia
        nvidia-driver
    )

    for PACKAGE in ${nvidia_dependencies[@]}; do
        wget -q https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${UBUNTU_VERSION_MAJOR}04/x86_64/$PACKAGE-$NVIDIA_VERSION_FULL-0ubuntu1_amd64.deb -P $INSTALL_PATH
    done

    wget -q https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${UBUNTU_VERSION_MAJOR}04/x86_64/libnvidia-common-$NVIDIA_VERSION_FULL-0ubuntu1_all.deb -P $INSTALL_PATH

    # Install Nvidia GPU Driver.
    apt install -y -qq \
        libegl1 \
        libgles2 \
        libgbm1 \
        $INSTALL_PATH/libnvidia-common-$NVIDIA_VERSION_FULL-0ubuntu1_all.deb \
        $INSTALL_PATH/libnvidia-gl-$NVIDIA_VERSION_FULL-0ubuntu1_amd64.deb \
        $INSTALL_PATH/libnvidia-cfg1-$NVIDIA_VERSION_FULL-0ubuntu1_amd64.deb \
        $INSTALL_PATH/libnvidia-compute-$NVIDIA_VERSION_FULL-0ubuntu1_amd64.deb \
        $INSTALL_PATH/libnvidia-decode-$NVIDIA_VERSION_FULL-0ubuntu1_amd64.deb \
        $INSTALL_PATH/libnvidia-encode-$NVIDIA_VERSION_FULL-0ubuntu1_amd64.deb \
        $INSTALL_PATH/libnvidia-extra-$NVIDIA_VERSION_FULL-0ubuntu1_amd64.deb \
        $INSTALL_PATH/libnvidia-fbc1-$NVIDIA_VERSION_FULL-0ubuntu1_amd64.deb \
	$INSTALL_PATH/libnvidia-ifr1-$NVIDIA_VERSION_FULL-0ubuntu1_amd64.deb \
        $INSTALL_PATH/nvidia-compute-utils-$NVIDIA_VERSION_FULL-0ubuntu1_amd64.deb \
        $INSTALL_PATH/nvidia-kernel-source-$NVIDIA_VERSION_FULL-0ubuntu1_amd64.deb \
        $INSTALL_PATH/nvidia-kernel-common-$NVIDIA_VERSION_FULL-0ubuntu1_amd64.deb \
        $INSTALL_PATH/nvidia-dkms-$NVIDIA_VERSION_FULL-0ubuntu1_amd64.deb \
        $INSTALL_PATH/nvidia-utils-$NVIDIA_VERSION_FULL-0ubuntu1_amd64.deb \
        $INSTALL_PATH/xserver-xorg-video-nvidia-$NVIDIA_VERSION_FULL-0ubuntu1_amd64.deb \
        $INSTALL_PATH/nvidia-driver-$NVIDIA_VERSION_FULL-0ubuntu1_amd64.deb \
        &> $INSTALL_PATH/install.log

    # Verify the Nvidia GPU driver was installed successfully.
    nvidia-smi &> /dev/null

    NVIDIA_DRIVER_INSTALL_VERIFICATION=$?

    if [ $NVIDIA_DRIVER_INSTALL_VERIFICATION -eq 0 ]; then
        echo "Installation of Nvidia GPU Driver $NVIDIA_VERSION_SHORT was succesfull!"

        # Install CUDA.
        echo "Installing CUDA $CUDA_VERSION..."
        wget -q http://developer.download.nvidia.com/compute/cuda/11.0.2/local_installers/cuda_11.0.2_450.51.05_linux.run -P $INSTALL_PATH
        sh $INSTALL_PATH/cuda_11.0.2_450.51.05_linux.run --silent --toolkit
        echo "export PATH="/usr/local/cuda-11.0/bin:$PATH"" >> /root/.bashrc
        echo "/usr/local/cuda-11.0/lib64" >> /etc/ld.so.conf && ldconfig
        echo "Installation of CUDA $CUDA_VERSION was succesfull!"
        echo "Installation of Nvidia GPU driver $NVIDIA_VERSION_SHORT and Cuda $CUDA_VERSION is now complate!"

        # Remove nvidia-driver-install directory.
        rm -rf $INSTALL_PATH

        echo "Installation of Nvidia GPU driver $NVIDIA_VERSION_SHORT and CUDA $CUDA_VERSION is now complate!"

    else
        echo "Installation of Nvidia GPU Driver $NVIDIA_VERSION_SHORT has failed! Aborting installation."
    fi
fi

