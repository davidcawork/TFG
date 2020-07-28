# XDP implementation

In this directory you will find the implementation of all the use cases developed with XDP. For the compilation of all of them we have provided a Makefile that will generate all the necessary executables to test each use case. In addition, a copy of the libbpf library has been added, which is used by most xdp programs to carry out functions external to XDP (although most XDP programs end up using these functions called _helpers_, it would not be surprising if they are incorporated natively into XDP in the future).

An installation script has been left to provide all the necessary dependencies to carry out the use cases with XDP. 
