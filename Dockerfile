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

# Manually install the ARC and RiscV toolchains
RUN wget https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/releases/download/arc-2016.09-release/arc_gnu_2016.09_prebuilt_uclibc_le_archs_linux_install.tar.gz
RUN tar -C /opt -xf arc_gnu_2016.09_prebuilt_uclibc_le_archs_linux_install.tar.gz
RUN wget https://github.com/PkmX/riscv-prebuilt-toolchains/releases/download/20180111/riscv32-unknown-elf-toolchain.tar.gz
RUN tar -C /opt -xf riscv32-unknown-elf-toolchain.tar.gz

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
RUN apt-get install -y lzop
RUN apt-get install -y flex bison
RUN apt-get install -y python-coverage

# Add user jenkins to the image
RUN adduser --quiet jenkins
RUN adduser jenkins dialout
RUN adduser jenkins plugdev

# Create the buildman config file
RUN /bin/echo -e "[toolchain]\nroot = /usr" > ~jenkins/.buildman
RUN /bin/echo -e "aarch64 = /opt/gcc-linaro-6.3.1-2017.02-x86_64_aarch64-linux-gnu" >> ~jenkins/.buildman
RUN /bin/echo -e "arm = /opt/gcc-linaro-6.3.1-2017.02-x86_64_arm-linux-gnueabihf" >> ~jenkins/.buildman
RUN /bin/echo -e "arc = /opt/arc_gnu_2016.09_prebuilt_uclibc_le_archs_linux_install" >> ~jenkins/.buildman
RUN /bin/echo -e "host = /usr" >> ~jenkins/.buildman
RUN /bin/echo -e "\n[toolchain-prefix]\nriscv = /opt/riscv32-unknown-elf/bin/riscv32-unknown-elf-" >> ~jenkins/.buildman;
RUN /bin/echo -e "\n[toolchain-alias]\nsh = sh4" >> ~jenkins/.buildman
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
RUN rm gcc-linaro-6.3.1-2017.02-x86_64_aarch64-linux-gnu.tar.xz
RUN rm gcc-linaro-6.3.1-2017.02-x86_64_arm-linux-gnueabihf.tar.xz
RUN rm arc_gnu_2016.09_prebuilt_uclibc_le_archs_linux_install.tar.gz
RUN rm riscv32-unknown-elf-toolchain.tar.gz
RUN apt-get clean
RUN rm -r sunxi-tools
RUN rm -r imx_usb_loader
RUN rm -r ykush

CMD ["/usr/sbin/sshd", "-D"]
