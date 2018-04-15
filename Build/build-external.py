from os import system, chdir, getcwd, environ
from sys import stderr, argv
from os.path import realpath, dirname, expanduser
from contextlib import contextmanager

DERIVED_FILES_DIR = environ['DERIVED_FILES_DIR']
BUILT_PRODUCTS_DIR = environ['BUILT_PRODUCTS_DIR']
FULL_PRODUCT_NAME = environ['FULL_PRODUCT_NAME']

SOURCES = {
    'unrar': {
        'url': 'https://www.rarlab.com/rar/unrarsrc-5.6.2.tar.gz',
    },
    'rar2fs': {
        'url': 'https://github.com/hasse69/rar2fs',
        'version': 'v1.26.0',
        'cherry-pick': ['1d6bf47979d9d15a0d4cfc48ddaee5a8716e88a9']
    },
    'libzip': {
        'url': 'https://github.com/nih-at/libzip',
        'version': 'rel-1-5-0',
    },
    'fuse-zip': {
        'url': 'https://bitbucket.org/agalanin/fuse-zip',
        'version': '0.4.5'
    }
}

@contextmanager
def cd(newPath):
    savedPath = getcwd()
    chdir(expanduser(newPath))
    yield
    chdir(savedPath)

def run(command):
    rv = system(command)
    if(rv != 0):
        raise Exception(f'{command} exited with status {rv}')

def rmrf(dir):
    run(f'rm -rf "{dir}"')

def make(options = None):
    run('make') if options is None else run(f'make {options}')

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
        make('lib')

def build_rar2fs():
    build_libunrar()
    with cloned('rar2fs'):
        run('autoreconf -f -i 2> /dev/null')
        run('./configure --with-fuse=/usr/local/include/osxfuse --with-unrar=../unrar')
        make('rar2fs')

def build_libzip():
    with cloned('libzip'):
        run('mkdir build')
        with cd('build'):
            run('cmake -DBUILD_SHARED_LIBS=OFF ..')
            make()

def build_fusezip():
    build_libzip()
    with cloned('fuse-zip', 'hg'):
        DERIVED_FILES_DIR_E = DERIVED_FILES_DIR.replace(" ", "\ ")
        ZIPFLAGS=f'-I{DERIVED_FILES_DIR_E}/libzip/lib -I{DERIVED_FILES_DIR_E}/libzip/build'
        LIBS=f'-Llib -lfusezip \$(shell pkg-config fuse --libs) -L{DERIVED_FILES_DIR_E}/libzip/build/lib -lzip -lz -lbz2'
        make(f'ZIPFLAGS="{ZIPFLAGS}" LIBS="{LIBS}"')

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

