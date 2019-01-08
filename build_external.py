from os import environ
from sys import argv
from contextlib import contextmanager
from build_common import *

DERIVED_FILES_DIR = environ['DERIVED_FILES_DIR']
BUILT_PRODUCTS_DIR = environ['BUILT_PRODUCTS_DIR']
FULL_PRODUCT_NAME = environ['FULL_PRODUCT_NAME']

MACOSX_VERSION_MIN = '10.10'
CFLAGS = f'-mmacosx-version-min={MACOSX_VERSION_MIN}'
CC = f'cc {CFLAGS}'
CXX = f'c++ {CFLAGS}'

SOURCES = {
    'unrar': {
        'url': 'https://www.rarlab.com/rar/unrarsrc-5.6.8.tar.gz',
    },
    'rar2fs': {
        'url': 'https://github.com/hasse69/rar2fs',
        'version': 'v1.27.1',
    },
    'libzip': {
        'url': 'https://github.com/nih-at/libzip',
        'version': 'rel-1-5-1',
        'cherry-pick': ['49b35508503812dbac5286d3f6dda53cdb7b7b59']
    },
    'fuse-zip': {
        'url': 'https://bitbucket.org/agalanin/fuse-zip',
        'version': '0.5.0'
    }
}

@contextmanager
def cloned(component, vcs = 'git'):
    url = SOURCES[component]['url']
    version = SOURCES[component]['version']
    rmrf(component)
    run(f'{vcs} clone "{url}" "{component}"')
    with cd(component):
        run(f'{vcs} checkout "{version}"')
        if 'cherry-pick' in SOURCES[component]:
            for commit in SOURCES[component]['cherry-pick']:
                run(f'{vcs} cherry-pick "{commit}"')
        yield

def build_libunrar():
    rmrf('unrar')
    run(f'curl -o - "{SOURCES["unrar"]["url"]}" | tar xvzf -')
    with cd('unrar'):
        make(f'lib CXX="{CXX}"')

def build_rar2fs():
    build_libunrar()
    with cloned('rar2fs'):
        run('autoreconf -f -i 2> /dev/null')
        run(f'ac_cv_func_utimensat=no CC="{CC}" CXX="{CXX}" ./configure --with-fuse=/usr/local/include/osxfuse --with-unrar=../unrar')
        make('rar2fs')

def build_libzip():
    with cloned('libzip'):
        run('mkdir build')
        with cd('build'):
            run(f'CC="{CC}" CXX="{CXX}" cmake -DBUILD_SHARED_LIBS=OFF ..')
            make()

def build_fusezip():
    build_libzip()
    with cloned('fuse-zip', 'hg'):
        DERIVED_FILES_DIR_E = DERIVED_FILES_DIR.replace(" ", "\ ")
        ZIPFLAGS=f'-I{DERIVED_FILES_DIR_E}/libzip/lib -I{DERIVED_FILES_DIR_E}/libzip/build'
        LIBS=f'-Llib -lfusezip \$(shell pkg-config fuse --libs) -L{DERIVED_FILES_DIR_E}/libzip/build/lib -lzip -lz -lbz2'
        make(f'ZIPFLAGS="{ZIPFLAGS}" LIBS="{LIBS}" CXX="{CXX} -std=c++11"')

def build_all():
    build_rar2fs()
    build_fusezip()

def copy_all():
    targetDir = f'{BUILT_PRODUCTS_DIR}/{FULL_PRODUCT_NAME}/Contents/Executables'
    run(f'mkdir -p "{targetDir}"')
    run(f'cp rar2fs/rar2fs "{targetDir}"')
    run(f'cp fuse-zip/fuse-zip "{targetDir}"')

if __name__ == '__main__':
    PATH = environ['PATH']
    HOME = environ['HOME']
    environ.clear()
    environ['PATH'] = PATH
    environ['HOME'] = HOME
    if len(argv) != 2:
        raise Exception('Wrong number of arguments')
    with cd(DERIVED_FILES_DIR):
        if argv[1] == 'build':
            build_all()
        elif argv[1] == 'copy':
            copy_all()
        else:
            raise Exception('Wrong arguments')

