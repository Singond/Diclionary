Building for Debian-based Distros
=================================

Building in a container
-----------------------
A Dockerfile is provided to enable building inside a container.
Run the following in the `pkg/debian` directory:
```sh
docker build -t diclionary-debian .
docker run -it --rm -v (pwd):/package diclionary-debian <debuild-args>
```
The `<debuild-args>` are arguments passed to the `debuild` command.
For example, use `-us -uc -S` to build only the source package.
The built files will appear in the `build` subdirectory.
