# This Dockerfile is used to build an image containing basic stuff to be used as a Jenkins slave build node.
FROM ubuntu:16.04
MAINTAINER Tom Rini <trini@konsulko.com>
LABEL Description=" This image is for building U-Boot inside a container"

# Make sure apt is happy
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update

# Install a basic SSH server
RUN apt-get install -y openssh-server
RUN mkdir -p /var/run/sshd

# Install JDK 8 (latest edition) for Jenkins
RUN apt-get install -y --no-install-recommends default-jdk

# Install utilities
RUN apt-get install -y git
RUN apt-get install -y wget
RUN apt-get install -y build-essential

# Manually install the Linaro ARM/aarch64 toolchains
RUN wget http://releases.linaro.org/components/toolchain/binaries/6.3-2017.02/aarch64-linux-gnu/gcc-linaro-6.3.1-2017.02-x86_64_aarch64-linux-gnu.tar.xz
RUN wget http://releases.linaro.org/components/toolchain/binaries/6.3-2017.02/arm-linux-gnueabihf/gcc-linaro-6.3.1-2017.02-x86_64_arm-linux-gnueabihf.tar.xz
RUN tar -C /opt -xf gcc-linaro-6.3.1-2017.02-x86_64_aarch64-linux-gnu.tar.xz
RUN tar -C /opt -xf gcc-linaro-6.3.1-2017.02-x86_64_arm-linux-gnueabihf.tar.xz

# Install U-Boot build and test dependencies
RUN apt-get install -y python-dev
RUN apt-get install -y swig
RUN apt-get install -y python-pytest
RUN apt-get install -y libsdl1.2-dev
RUN apt-get install -y libssl-dev
RUN apt-get install -y bc
RUN apt-get install -y gdisk
RUN apt-get install -y device-tree-compiler
RUN apt-get install -y gcc-powerpc-linux-gnu gcc-mips-linux-gnu gcc-5-multilib
RUN apt-get install -y qemu-system-i386
RUN apt-get install -y qemu-system-mips
RUN apt-get install -y qemu-system-ppc
RUN apt-get install -y qemu-system-arm
RUN apt-get install -y dosfstools
RUN apt-get install -y e2fsprogs
RUN apt-get install -y sudo
RUN apt-get install -y iputils-ping
RUN apt-get install -y picocom
RUN apt-get install -y curl
RUN apt-get install -y libusb-1.0-0-dev
RUN apt-get install -y libudev-dev

# Add user jenkins to the image
RUN adduser --quiet jenkins
RUN adduser jenkins dialout
RUN adduser jenkins plugdev

# Create the buildman config file
RUN echo -e "[toolchain]\nroot = /usr" > ~jenkins/.buildman
RUN echo -e "aarch64 = /tmp/gcc-linaro-6.3.1-2017.02-x86_64_aarch64-linux-gnu" >> ~jenkins/.buildman
RUN echo -e "arm = /tmp/gcc-linaro-6.3.1-2017.02-x86_64_arm-linux-gnueabihf" >> ~jenkins/.buildman
RUN echo -e "arc = /tmp/arc_gnu_2016.09_prebuilt_uclibc_le_archs_linux_install" >> ~jenkins/.buildman
RUN echo -e "\n[toolchain-alias]\nsh = sh4\nopenrisc = or32" >> ~jenkins/.buildman

# Add user jenkins to sudoers with NOPASSWD
RUN echo "jenkins ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set password for the jenkins user (you may want to alter this).
RUN echo "jenkins:jenkins" | chpasswd

# Setting for sshd
RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd  

# Standard SSH port
EXPOSE 22

# build sunxi-tools for Allwinner targets
RUN git clone --depth=1 https://github.com/linux-sunxi/sunxi-tools sunxi-tools --branch v1.4
RUN cd sunxi-tools && make && make install && cd ..

# Build imx_usb_loader for i.MX6/7 based targets
RUN git clone --depth=1 https://github.com/boundarydevices/imx_usb_loader.git imx_usb_loader
RUN cd imx_usb_loader && make && make install && cd ..

# Build the ykush helpers
RUN git clone --depth=1 https://github.com/Yepkit/ykush.git ykush
RUN cd ykush && ./build.sh && ./install.sh && cd ..

# Clean up
RUN rm gcc-linaro-6.3.1-2017.02-x86_64_aarch64-linux-gnu.tar.xz
RUN rm gcc-linaro-6.3.1-2017.02-x86_64_arm-linux-gnueabihf.tar.xz
RUN apt-get clean
RUN rm -r sunxi-tools
RUN rm -r imx_usb_loader
RUN rm -r ykush

CMD ["/usr/sbin/sshd", "-D"]
