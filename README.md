Diclionary
==========
A command-line interface for selected online dictionaries.

This project is currently in development.

Installation
============
Prebuilt packages are hosted at the OpenSUSE Build Service.
You will need to add an appropriate repository to your package manager
configuration before you can install these packages.

Debian/Ubuntu
-------------
Select an appropriate repository from
<https://download.opensuse.org/repositories/home:/singon:/diclionary/>
and add it to your system along with the `Release.key` contained in it.
For example, on Ubuntu 20.04:
```
sudo echo 'deb https://download.opensuse.org/repositories/home:/singon:/diclionary/xUbuntu_20.04/ /' >> /etc/apt/sources.list
curl -fsSL https://download.opensuse.org/repositories/home:/singon:/diclionary/xUbuntu_20.04/Release.key | sudo apt-key add -
sudo apt update
sudo apt install diclionary
```

From Source
-----------
You need to have the Crystal compiler available on your system.
Refer to <https://crystal-lang.org/install/> for installation instructions.

Once Crystal is installed, run `make install` in the project root to install
Diclionary into your system. The default installation prefix is `/usr/local`.
This can be changed by setting the `PREFIX` environment variable.

Usage
=====
```sh
dicl <word>...
```

Supported Dictionaries
======================
This is a list of dictionaries which can be searched with the current version:
  - Slovník spisovného jazyka českého <https://ssjc.ujc.cas.cz> (Czech)
