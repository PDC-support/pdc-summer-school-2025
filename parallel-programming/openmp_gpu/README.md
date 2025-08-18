# About this exercise

The aim of this exercise is to give an introduction to programming GPUs using OpenMP.

The exercise consists of two parts. The goal of the first part is to give you   some familiarity to the OpenMP offloading syntax.

# Compiling the exercises

Load the correct offloading modules for Dardel, and compile the files as a usual OpenMP program

```bash
$ ml craype-accel-amd-gfx90a rocm
$ cc -fopenmp add3.c 
$ ftn -homp add3.f90
```

# Warmup

Start with the file `add3.(c/f90)` in the `intro` directory. Follow the lecture notes, familiarise yourself with the OpenMP target directives and try to compute the vector addition as fast as possible, using as few data transfers as possible. 

# Finite Volume solver

Once you understand the basics of OpenMP offloading, the next challenge is to convert an OpenMP code for CPUs to accelerators and compare the performance between both implementations. Further instructions can be found in the `shwater2d` directory.