"""Builds the player UE4SS package from source with UE4SS's own packager (tools/buildscripts/release.py).

  python tools/ue4ss_release.py <RE-UE4SS checkout> <dir with the built UE4SS.dll + dwmapi.dll> <output dir>

UE4SS's rolling "experimental-latest" GitHub release replaces its zips, so the exact build the mod is tested with
can't be downloaded later. The release workflow builds UE4SS at the pinned commit anyway (the native DLL links it);
this runs the release half of UE4SS's packager on that build - the same files, settings and mod list as their
UE4SS_<version>.zip - and extracts it into <output dir> (what tools/package.ps1 copies from)."""
import glob
import importlib.util
import os
import shutil
import sys
import zipfile

src, built, out = (os.path.abspath(a) for a in sys.argv[1:4])
for dll in ("UE4SS.dll", "dwmapi.dll"):
    # the packager finds them by walking its own checkout
    shutil.copy(os.path.join(built, dll), os.path.join(src, dll))

spec = importlib.util.spec_from_file_location("ue4ss_release", os.path.join(src, "tools", "buildscripts", "release.py"))
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)

os.chdir(src)
shutil.rmtree("release", ignore_errors=True)
os.mkdir("release")
handler = release.ReleaseHandler(is_dev_release=False, is_experimental=True, release_output="release")
handler.make_staging_dirs()
handler.package_release()
handler.cleanup()

zips = glob.glob(os.path.join(src, "release", "UE4SS_*.zip"))
if len(zips) != 1:
    sys.exit(f"expected one UE4SS_*.zip, found {zips}")
os.makedirs(out, exist_ok=True)
with zipfile.ZipFile(zips[0]) as z:
    z.extractall(out)
for dll in ("UE4SS.dll", "dwmapi.dll"):
    os.remove(os.path.join(src, dll))
print(f"UE4SS package {os.path.basename(zips[0])} -> {out}")
