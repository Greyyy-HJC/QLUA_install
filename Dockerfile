FROM nvidia/cuda:11.2.2-devel-ubuntu20.04

# Time zone
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install GCC 9.2
RUN apt-get update && apt-get install -y gcc-9 g++-9 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 100 \
    --slave /usr/bin/g++ g++ /usr/bin/g++-9

# Install OpenMPI with CUDA support
RUN apt-get install -y openmpi-bin libopenmpi-dev

# Install CMake
RUN apt-get install -y cmake

# Install Python
RUN apt-get update && apt-get install -y python3.8 python3-pip

# Install vim, git and wget
RUN apt-get update && apt-get install -y vim git wget

# Install torch
RUN pip3 install torch