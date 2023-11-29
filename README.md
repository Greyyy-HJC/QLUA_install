# QLUA_install
Repo to install the QLUA software for Lattice QCD.



# Step by step installation of QLUA

## 0. Prerequisites

First, the host machine should have NVIDIA GPU and the driver should be installed. Second, we would like to use Docker to build a clean environment to install QLUA. So the host machine should have Docker (or Podman) installed. Third, to use GPU in the container, we need to install nvidia-container-toolkit and modify some settings. The following steps are the prerequisites.

- 1. Install NVIDIA driver, check with the following command.
```bash
    nvidia-smi
```
- 2. Install nvidia-container-toolkit, check with the following command.
```bash
    which nvidia-container-toolkit
``` 

- 3. Check if the host machine has the directory file /usr/share/containers/oci/hooks.d/oci-nvidia-hook.json. If it doesn't exist, use the following command to create it.
```bash
    Content=`cat << 'EOF'
    {
        "version": "1.0.0",
        "hook": {
            "path": "/usr/bin/nvidia-container-toolkit",
            "args": ["nvidia-container-toolkit", "prestart"],
            "env": [
                "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
            ]
        },
        "when": {
            "always": true,
            "commands": [".*"]
        },
        "stages": ["prestart"]
    }
    EOF`
    
    HookFile=/usr/share/containers/oci/hooks.d/oci-nvidia-hook.json
    sudo mkdir -p `dirname $HookFile`
    sudo echo "$Content" > $HookFile
```

- 4. Modify the configuration to allow users to execute and modify CUDA containers with regular user privileges.
```bash
    sudo sed -i 's/^#no-cgroups = false/no-cgroups = true/;' /etc/nvidia-container-runtime/config.toml
```


## 1. Get basic environment with Docker
We will use Docker (or Podman) to build a clean environment to install QLUA.

### 1.1 Get the basic environment
```bash
    docker pull nvidia/cuda:11.2.2-devel-ubuntu20.04
```

### 1.2 Build a image with necessary packages
Run the following command in the same directory as the [Dockerfile](/Dockerfile).
```bash
    docker build -t qlua_env .
```

### 1.3 Run the image
Build a container (qlua_container) with the image (qlua_env) we defined and run it.
```bash
    docker run --name qlua_container --security-opt=label=disable --hooks-dir=/usr/share/containers/oci/hooks.d/ --runtime=nvidia --rm -it qlua_env
```

Then a bash shell will be opened in the container. We can install the QLUA in this shell. Check the nvidia driver and GPU with the following command.
```bash
    nvidia-smi
```

## 2. Download packages

### 2.1 Download build2
Here we need to firstly forbid SSL verify, because the mit git source is not trusted.
```bash
    git config --global http.sslVerify false
    git clone --recursive https://usqcd.lns.mit.edu/git/LHPC/Public/build2.git
```

Go to the build2 directory and checkout the version we need.
```bash
    cd build2
    git checkout quda-dev
    git submodule update
```

### 2.2 Download QUDA and update the submodule
```bash
    cd parts/quda/tree
    git remote add mit-gitweb https://urldefense.com/v3/__https:/usqcd.lns.mit.edu/git/LHPC/Public/alien-libs/quda.git
    git fetch mit-gitweb
    cd ../../../
    git submodule update
```

### 2.3 Check the version of submodules
In this step, we need to check the version of submodules. If the version is not the same as the one we need, we need to checkout the correct version.

Go to the directory of [check_hash.sh](/check_hash.sh) and [submodule_hash_ls.txt](/submodule_hash_ls.txt), run the following command.
```bash
    bash check_hash.sh
```

### 2.4 Modify some files
In this step, we need to modify some files to make sure the installation can be done successfully.

- 1. In the file "build2/parts/quda/tree/CMakeLists.txt", change the line 237 and 238 to the following.
```
set(EIGEN_URL https://gitlab.com/libeigen/eigen/-/archive/${EIGEN_VERSION}/eigen-${EIGEN_VERSION}.tar.bz2)

set(EIGEN_SHA 685adf14bd8e9c015b78097c1dc22f2f01343756f196acdc76a678e1ae352e11)
```

- 2. In the file "build2/parts/quda/tree/include/thrust_helper.cuh", add the following line at the beginning (abou line 20) of the file.
```
#define THRUST_IGNORE_CUB_VERSION_CHECK
```

- 3. In the config file [moonway.gpu.omp](/moonway.gpu.omp), change the line 2 "PREFIX" to the directory you want to install QLUA; change the line 38 "CUDA.root" to the directory of CUDA. The directory of CUDA can be found by the following command.
```bash
    which nvcc
```

Besides, you are supposed to check the setting of "XCC", "YCC", "XCXX" and "XFC" in the config file [moonway.gpu.omp](/moonway.gpu.omp). The way to check is write a simple C and CPP file and compile them with the setting of "XCC", "YCC", "XCXX" and "XFC". If the compilation is successful, then the setting is correct.

Move the modified config file to the directory "build2/configs/".
```bash
    cp moonway.gpu.omp build2/configs/moonway.gpu.omp
```

- 4. Add environment variables "CUDA_HOME" to the file "~/.bashrc" in the home directory.
```bash
    export CUDA_HOME=/usr/local/cuda
```
The directory of CUDA can be found by the following command.
```bash
    which nvcc
```

## 3. Compile all modules
```bash
    cd build2
    make -j 8 TARGET=moonway.gpu.omp
```

The compilation will take a long time and maybe need to make few times. You can modify "which parts to build" in the config file to separate the compilation into several parts.

### 3.1 Add environment variables
Find the directory of libquda.so by the following command.
```bash
    find / -name libquda.so 2>/dev/null
```
Add it to the environment variables in "~/.bashrc".
```bash
    export LD_LIBRARY_PATH=/path/to/quda/lib:$LD_LIBRARY_PATH
```

## 4. Test QLUA
Find the executable "qlua" file in the directory "build2/parts/qlua/tree", run it should get the following output.
```
QLUA component versions:
       qlua: +53e3ca9370a99dd4660f250978938d082584d97a
        lua: f676f113bbb6a4c7d57f05ed6d4efe5adad5dc20
        qdp: b9e3fbcfd90024246e4258f3dc6c61b297cfbee5
        aff: 4eaef4640d697c3bafe550f53521bb00ff6e0650
       hdf5: a0fef093c451d235e63292af1c367693b4002bcf
       quda: +55aee2e5ef4424e79ba84b0cc7447dea66b065ef
     clover: 3b35622925296cbe506316411daeedbe60495d7f
    twisted: 9887268e66d40d109eaac5a19fd0cbe19591f5cf
       mdwf: 7565b395990049792302e320a19d074e286d1c03
     extras: included
        gsl: 5c90e2d93009f6f4a9b7843949faf1754033489f
      cblas: -L/root/qlua/lapack/lib -llapacke -llapack -lcblas -lrefblas 
     qopqdp: 57c3151741809f04918ec52c609ba2dc5ce8eab1
        sfc: 2cfccb6d9a07e53662e2478c20853dfb2342641c
        qa0: e147c66f9a404a692bcefcf5b3a9328833728ab9
        qmp: e85867db7e6f68e7fe5bbfcb64a24348f21b8ee9
        qla: 91ce106eea9cd9ff674f8780fb81aed1d46cdb10
        qio: 3d5e075a7fe0894728c4935b789a13fd84ff9d19
     colors: 2 3 N
```