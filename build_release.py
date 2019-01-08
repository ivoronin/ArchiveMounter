#!/usr/bin/env python3
from build_common import *
from os.path import realpath, dirname

SCRIPTPATH=dirname(realpath(__file__))
PROJECT='ArchiveMounter.xcodeproj'
SCHEME='ArchiveMounter'
CONFIGURATION='Release'
ARCHIVEPATH = f'ArchiveMounter.xcarchive'

if __name__ == '__main__':
    rmrf(ARCHIVEPATH)
    run(f'xcodebuild -project "{PROJECT}" -scheme "{SCHEME}" \
        -configuration "{CONFIGURATION}" -archivePath "{ARCHIVEPATH}" archive')
    with cd(f'{ARCHIVEPATH}/Products/Applications') as cwd:
        run(f'rm -f {cwd}/ArchiveMounter.zip')
        run(f'zip -r {cwd}/ArchiveMounter.zip "Archive Mounter.app"')
    run(f'./node_modules/.bin/create-dmg --overwrite "{ARCHIVEPATH}/Products/Applications/Archive Mounter.app"')
