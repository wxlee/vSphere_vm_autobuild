# vSphere VM Auto-build

This tool is wrote by shell script based on bash and test on Debian7 64bit.

  - GNU bash, version 4.2.37(1)-release (x86_64-pc-linux-gnu)
  - vSphere ESXi Version 5.0.0 Build 469512
  - Debian GNU/Linux 7.9 (wheezy)

### Version
0.1


### Installation

You need install some packages for build iso:

```sh
# apt-get install debootstrap syslinux squashfs-tools genisoimage memtest86+ rsync
```

### How to use it

1. You need a image server with tarball you want to deploy
2. Clone this repository to your server and install packages needed
3. Copy config.ini.sample to config.ini and edit according your environment
3. Run main.sh with or without options

With options:
```sh
# ./main.sh -h
Use ./main.sh
-s: vSphere ip
-v: virtual machine ip
-n: vm name
```
Example:
Create vm named 'web' and set ip (192.168.1.1) on vSphere ESXi (10.10.10.10) 
```sh
# ./main.sh -s 10.10.10.10 -v 192.168.1.1 -n web
```

Without Options: According the setting on config.ini
```sh
# ./main.sh
```

### Todos

 - Hard Code: partition tables (200G)
 - Multi-thread concurrent build
 - Python wrapped

### Other Info
[Slides](https://docs.google.com/presentation/d/1_gdHZFmPc3iivoGIVRoMv8zC5PjkRooC3hacRhtHPu8/edit?usp=sharing)

License
----

MIT


