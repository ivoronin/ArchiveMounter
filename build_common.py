from os import system, chdir, getcwd
from os.path import expanduser
from contextlib import contextmanager

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

