![Logo](https://github.com/ivoronin/ArchiveMounter/raw/master/ArchiveMounter/Assets.xcassets/AppIcon.appiconset/appicon-128.png)

# Archive Mounter
**Archive Mounter** is a macOS application allowing to mount archive files as disk images.\
It currently supports **ZIP** and **RAR** archives.

[![Travis](https://travis-ci.org/ivoronin/ArchiveMounter.svg?branch=master)](https://travis-ci.org/ivoronin/ArchiveMounter)
[![HitCount](http://hits.dwyl.io/ivoronin/ArchiveMounter.svg)](http://hits.dwyl.io/ivoronin/ArchiveMounter)

# Screenshots
## Main window
<img src="https://raw.githubusercontent.com/ivoronin/ArchiveMounter/gh-pages/MainWindow.png" width="520" height="229"/>

## Manage volumes window
<img src="https://raw.githubusercontent.com/ivoronin/ArchiveMounter/gh-pages/VolumesWindow.png" width="800" height="400"/>

## Requirements
:exclamation:You should download and install latest version of [FUSE for macOS](https://osxfuse.github.io/) before using this application.

## Download
Latest stable release: [Archive.Mounter.1.3.1.dmg](https://github.com/ivoronin/ArchiveMounter/releases/download/v1.3.1/Archive.Mounter.1.3.1.dmg)

## Usage
You can run app directly and choose an archive to mount or use it from **Finder**'s `Open With` context menu.\
It is also possible to use Archive Mounter as a default app for opening archives (see [Apple KB article](https://support.apple.com/kb/ph25685)).

## Build requirements
 - Xcode
 - FUSE for macOS
 - autoconf
 - automake
 - cmake
 - mercurial
 - pkg-config
 - python@3
 - swiftlint
 - npm
