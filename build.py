import os
import os.path
import argparse
import sys
import shutil
import grope
from pe_tools import parse_pe, IMAGE_DIRECTORY_ENTRY_RESOURCE
from pe_tools.rsrc import parse_pe_resources, pe_resources_prepack, parse_prelink_resources, KnownResourceTypes
from pe_tools.version_info import parse_version_info, VersionInfo

ver_str = "0.1.0"
windows_ver = "0, 1, 0, 0"
file_description = "Leading Brand DELTARUNE-type Software"

# Contains code from https://github.com/avast/pe_tools/blob/master/pe_tools/peresed.py

RT_VERSION = KnownResourceTypes.RT_VERSION

class _IdentityReplace:
    def __init__(self, val):
        self._val = val

    def __call__(self, s):
        return self._val

class Version:
    def __init__(self, s):
        s = s.strip("-beta")
        s = s.strip("-alpha")
        s = s.strip("-dev")
        parts = s.split(',')
        if len(parts) == 1:
            parts = parts[0].split('.')
        self._parts = [int(part.strip()) for part in parts]
        if not self._parts or len(self._parts) > 4 or any(part < 0 or part >= 2**16 for part in self._parts):
            raise ValueError('invalid version')

        while len(self._parts) < 4:
            self._parts.append(0)

    def get_ms_ls(self):
        ms = (self._parts[0] << 16) + self._parts[1]
        ls = (self._parts[2] << 16) + self._parts[3]
        return ms, ls

    def format(self):
        return ', '.join(str(part) for part in self._parts)

def setInfo(key, value):
    ver_data = None
    for name in resources.get(RT_VERSION, ()):
        for lang in resources[RT_VERSION][name]:
            if ver_data is not None:
                print('error: multiple manifest resources found', file=sys.stderr)
                return 4
            ver_data = resources[RT_VERSION][name][lang]
            ver_name = name
            ver_lang = lang
    
    if ver_data is None:
        ver_data = VersionInfo()
    
    params = {}
    params[key] = _IdentityReplace(value)
    
    vi = parse_version_info(ver_data)
    
    fvi = vi.get_fixed_info()
    if 'FileVersion' in params:
        ver = Version(params['FileVersion'](None))
        fvi.dwFileVersionMS, fvi.dwFileVersionLS = ver.get_ms_ls()
    if 'ProductVersion' in params:
        ver = Version(params['ProductVersion'](None))
        fvi.dwProductVersionMS, fvi.dwProductVersionLS = ver.get_ms_ls()
    vi.set_fixed_info(fvi)
    
    sfi = vi.string_file_info()
    for _, strings in sfi.items():
        for k, fn in params.items():
            val = fn(strings.get(k, ''))
            if val:
                strings[k] = val
            elif k in strings:
                del strings[k]
    vi.set_string_file_info(sfi)
    resources[RT_VERSION][ver_name][ver_lang] = vi.pack()


build_path = "build"
output_path = "output"
kristal_path = "Kristal"

try:
    os.makedirs(os.path.join(build_path, "executable"))
except FileExistsError:
    pass
try:
    os.makedirs(os.path.join(build_path, "kristal"))
except FileExistsError:
    pass
try:
    os.makedirs(output_path)
except FileExistsError:
    pass

def fatal(error):
    print(error)
    sys.exit(1)

parser = argparse.ArgumentParser(prog="kristal_build.py", description='Utility script to compile Kristal.')
parser.add_argument('--love', nargs=1, help='The path to the LÖVE folder (not the executable)')
parser.add_argument('--kristal', nargs=1, help='The path to the Kristal folder')

args = parser.parse_args()

if args.kristal:
    kristal_path = args.kristal[0]

print(f"Compiling Kristal...")

print("Reading Kristal version...")
try:
    with open(os.path.join(kristal_path, "VERSION"), "r") as file:
        ver_str = file.read()
        windows_ver = Version(ver_str).format()
except:
    pass

kristal_love_path = os.path.join(output_path, "kristal-"+ver_str+".love")

print("Copying engine files...")

ignorefiles = [
    ".github",
    ".git",
    ".vscode",
    "mods",
    "docs",
    "lib",
    "build"
]

try:
    for file in os.listdir(kristal_path):
        if not file in ignorefiles:
            if os.path.isfile(os.path.join(kristal_path, file)):
                shutil.copy(os.path.join(kristal_path, file), os.path.join(build_path, "kristal"))
            elif os.path.isdir(os.path.join(kristal_path, file)):
                shutil.copytree(os.path.join(kristal_path, file), os.path.join(build_path, "kristal", file))
except FileNotFoundError:
    fatal("Error: \"kristal\" folder missing! Please place a clean copy of Kristal's source code next to this script in a folder titled \"kristal\".")

print("Making .zip file...")
shutil.make_archive(os.path.join(build_path, "kristal"), 'zip', os.path.join(build_path, "kristal"))

print("Removing copied files...")
shutil.rmtree(os.path.join(build_path, "kristal"))

print("Renaming .zip to .love and moving it to the output folder...")
shutil.move(os.path.join(build_path, "kristal.zip"), kristal_love_path)

love2d_path = None

if args.love:
    love2d_path = args.love[0]
    print("Using supplied LÖVE path...")
    if os.path.isfile(os.path.join(love2d_path, "love.exe")):
        print("LÖVE found!")
    else:
        fatal("Error: LÖVE not found at passed directory")
else:
    print("Finding LÖVE...")
    print("Checking PATH...")
    path_var = os.getenv('PATH')
    if path_var is None:
        fatal("Error: PATH not found! Please specify the path to LÖVE with --love.")
    for path in path_var.split(";"):
        if path == "":
            continue
        if os.path.isfile(os.path.join(path, "love.exe")):
            love2d_path = path
            print(f"LÖVE found: {path}")
            break
    else:
        fatal("Error: LÖVE not found! Please specify the path to LÖVE with --love.")

# Search PATH

print("Compiling into exe...")
try:
    with open(os.path.join(love2d_path, "love.exe"), "rb") as file1, open(kristal_love_path, "rb") as file2, open(os.path.join(build_path, "kristal_noicon.exe"), "wb") as output:
        output.write(file1.read())
        output.write(file2.read())
except FileNotFoundError:
    fatal("Error: LÖVE or Kristal not found!")

print("Patching in custom icon...")

fin = open(os.path.join(build_path, "kristal_noicon.exe"), 'rb')
pe = parse_pe(grope.wrap_io(fin))
resources = pe.parse_resources()

try:
    res_fin = open(os.path.join(kristal_path, "icon.res"), 'rb')
except FileNotFoundError:
    fatal("Error: icon.res not found! To compile one yourself, run \"rc icon.rc\" in a Visual Studio developer console.")

r = parse_prelink_resources(grope.wrap_io(res_fin))
for resource_type in r:
    for name in r[resource_type]:
        for lang in r[resource_type][name]:
            resources.setdefault(resource_type, {}).setdefault(name, {})[lang] = r[resource_type][name][lang]

print("Patching in custom information...")
setInfo("FileVersion", windows_ver)
setInfo("ProductVersion", windows_ver)
setInfo("FileDescription", file_description)
setInfo("InternalName", "Kristal")
setInfo("LegalCopyright", "Copyright © 2023 Kristal Team")
setInfo("OriginalFilename", "kristal.exe")
setInfo("ProductName", "Kristal")


prepacked = pe_resources_prepack(resources)
addr = pe.resize_directory(IMAGE_DIRECTORY_ENTRY_RESOURCE, prepacked.size)
pe.set_directory(IMAGE_DIRECTORY_ENTRY_RESOURCE, prepacked.pack(addr))

print("Writing new file...")

with open(os.path.join(build_path, "executable", "kristal.exe"), 'wb') as fout:
    grope.dump(pe.to_blob(), fout)


res_fin.close()
fin.close()

print("Copying files...")




copyfiles = [
    "SDL2.dll",
    "OpenAL32.dll",
    "license.txt",
    "love.dll",
    "lua51.dll",
    "mpg123.dll",
    "msvcp120.dll",
    "msvcr120.dll",
]

for file in copyfiles:
    shutil.copy(os.path.join(love2d_path, file), os.path.join(build_path, "executable"))

print("Copying libraries...")

for file in os.listdir(os.path.join(kristal_path, "lib")):
    shutil.copy(os.path.join(kristal_path, "lib", file), os.path.join(build_path, "executable"))

print("Zipping built file...")
shutil.make_archive(os.path.join(output_path, "kristal-"+ver_str+"-win"), 'zip', os.path.join(build_path, "executable"))

print("Packaging example mod...")

try:
    os.makedirs(os.path.join(build_path, "example"))
except FileExistsError:
    pass

shutil.copytree(os.path.join(kristal_path, "mod_template", "assets"), os.path.join(build_path, "example", "assets"))
shutil.copytree(os.path.join(kristal_path, "mod_template", "scripts"), os.path.join(build_path, "example", "scripts"))
shutil.copy(os.path.join(kristal_path, "mods", "example", "mod.json"), os.path.join(build_path, "example", "mod.json"))
shutil.copy(os.path.join(kristal_path, "mod_template", "mod.lua"), os.path.join(build_path, "example", "mod.lua"))

shutil.make_archive(os.path.join(output_path, "example-mod"), 'zip', os.path.join(build_path, "example"))

print("Done!")
print("Generated files:")
print("> kristal-"+ver_str+".love")
print("> kristal-"+ver_str+".zip")
print("> example-mod.zip")