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

# Manually install the kernel.org "Crosstool" based toolchains for gcc-7.3
RUN wget https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/7.3.0/x86_64-gcc-7.3.0-nolibc_aarch64-linux.tar.xz
RUN tar -C /opt -xf x86_64-gcc-7.3.0-nolibc_aarch64-linux.tar.xz
RUN wget https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/7.3.0/x86_64-gcc-7.3.0-nolibc_arm-linux-gnueabi.tar.xz
RUN tar -C /opt -xf x86_64-gcc-7.3.0-nolibc_arm-linux-gnueabi.tar.xz
RUN wget https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/7.3.0/x86_64-gcc-7.3.0-nolibc_m68k-linux.tar.xz
RUN tar -C /opt -xf x86_64-gcc-7.3.0-nolibc_m68k-linux.tar.xz
RUN wget https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/7.3.0/x86_64-gcc-7.3.0-nolibc_mips-linux.tar.xz
RUN tar -C /opt -xf x86_64-gcc-7.3.0-nolibc_mips-linux.tar.xz
RUN wget https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/7.3.0/x86_64-gcc-7.3.0-nolibc_powerpc-linux.tar.xz
RUN tar -C /opt -xf x86_64-gcc-7.3.0-nolibc_powerpc-linux.tar.xz
RUN wget https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/7.3.0/x86_64-gcc-7.3.0-nolibc_riscv64-linux.tar.xz
RUN tar -C /opt -xf x86_64-gcc-7.3.0-nolibc_riscv64-linux.tar.xz
RUN wget https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/7.3.0/x86_64-gcc-7.3.0-nolibc_sh4-linux.tar.xz
RUN tar -C /opt -xf x86_64-gcc-7.3.0-nolibc_sh4-linux.tar.xz
RUN wget https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/7.3.0/x86_64-gcc-7.3.0-nolibc_x86_64-linux.tar.xz
RUN tar -C /opt -xf x86_64-gcc-7.3.0-nolibc_x86_64-linux.tar.xz
RUN wget https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/7.3.0/x86_64-gcc-7.3.0-nolibc_xtensa-linux.tar.xz
RUN tar -C /opt -xf x86_64-gcc-7.3.0-nolibc_xtensa-linux.tar.xz

# Manually install the ARC toolchain
RUN wget https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/releases/download/arc-2017.09-release/arc_gnu_2017.09_prebuilt_uclibc_le_archs_linux_install.tar.gz
RUN tar -C /opt -xf arc_gnu_2017.09_prebuilt_uclibc_le_archs_linux_install.tar.gz

# Install U-Boot build and test dependencies
RUN apt-get install -y python-dev
RUN apt-get install -y swig
RUN apt-get install -y python-pytest
RUN apt-get install -y python-pip
RUN apt-get install -y virtualenv
RUN apt-get install -y libsdl1.2-dev
RUN apt-get install -y libssl-dev
RUN apt-get install -y bc
RUN apt-get install -y gdisk
RUN apt-get install -y device-tree-compiler
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
RUN apt-get install -y lzop
RUN apt-get install -y liblz4-tool
RUN apt-get install -y flex bison
RUN apt-get install -y python-coverage

# Add required libraries for the kernel.org toolchains
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:ubuntu-toolchain-r/test -y
RUN apt-get update -q
RUN apt-get install -y libisl15

# Add user jenkins to the image
RUN adduser --quiet jenkins
RUN adduser jenkins dialout
RUN adduser jenkins plugdev

# Create the buildman config file
RUN /bin/echo -e "[toolchain]\nroot = /usr" > ~jenkins/.buildman
RUN /bin/echo -e "kernelorg = /opt/gcc-7.3.0-nolibc/*" >> ~jenkins/.buildman
RUN /bin/echo -e "arc = /opt/arc_gnu_2017.09_prebuilt_uclibc_le_archs_linux_install" >> ~jenkins/.buildman
RUN /bin/echo -e "\n[toolchain-alias]\nsh = sh4" >> ~jenkins/.buildman
RUN /bin/echo -e "\nriscv = riscv64" >> ~jenkins/.buildman
RUN /bin/echo -e "\nsandbox = x86_64" >> ~jenkins/.buildman
RUN chown jenkins:jenkins ~jenkins/.buildman

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
RUN rm x86_64-gcc-7.3.0-nolibc_*.tar.xz
RUN rm arc_gnu_2017.09_prebuilt_uclibc_le_archs_linux_install.tar.gz
RUN apt-get clean
RUN rm -r sunxi-tools
RUN rm -r imx_usb_loader
RUN rm -r ykush

CMD ["/usr/sbin/sshd", "-D"]
