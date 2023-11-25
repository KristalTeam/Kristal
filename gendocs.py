import os
import os.path
import argparse
import sys
import re
import json

docs = {
    "api": {
        "classes": {}
    }
}

kristal_path = "Kristal"

def fatal(error):
    print(error)
    sys.exit(1)

def get_file_from_require(name):
    # src.engine.tweaks -> src/engine/tweaks.lua
    return name.replace(".", "/") + ".lua"

def readfile(base_path, name):

    className = None

    filename = get_file_from_require(name)
    print(f"Reading {filename}...")
    with open(os.path.join(base_path, filename), "r") as file:
        lines = file.readlines()
        index = 0
        desc = ""
        while index < len(lines):
            index += 1
            line = lines[index - 1].strip()

            # check if it matches `CLASS = require("PATH")`
            match = re.match(r"([A-Za-z_]+)\s*=\s*(?:(?:require)|(?:libRequire)|(?:modRequire))\(\"([a-zA-Z0-9_\.]+)\"\)", line)
            if match:
                print(f"> Found class {match.group(1)}")
                readfile(base_path, match.group(2))
                continue

            # check if it matches `require("PATH")`
            match = re.match(r"(?:(?:require)|(?:libRequire)|(?:modRequire))\(\"([a-zA-Z0-9_\.]+)\"\)", line)
            if match:
                print(f"> Found require {match.group(1)}")
                readfile(base_path, match.group(1))
                continue

            # check for `---@class CLASS : PARENT` where `: PARENT` is optional
            match = re.match(r"---@class ([A-Za-z_]+)(?:\s*:\s*([A-Za-z_]+))?", line)
            if match:
                className = match.group(1)
                print(f"> Found class {match.group(1)}")
                docs["api"]["classes"][match.group(1)] = {
                    "name": match.group(1),
                    "description": desc.strip(),
                    "extends": match.group(2),
                    "methods": {},
                    "fields": {}
                }
                desc = ""
                continue

            # check for `---@field NAME TYPE DESCRIPTION`
            match = re.match(r"---@field[^\S\n]+([A-Za-z_]+)[^\S\n]+([A-Za-z_|]+)[^\S\n]*(.*)", line)
            if match:
                fieldName = match.group(1)
                print(f"> Found field {fieldName}")
                docs["api"]["classes"][className] = docs["api"]["classes"].get(className, {
                    "name": className,
                    "extends": None,
                    "methods": {},
                    "fields": {},
                    "description": ""
                })

                docs["api"]["classes"][className]["fields"][fieldName] = {
                    "name": fieldName,
                    "type": match.group(2),
                    "description": match.group(3) or desc.strip()
                }
                desc = ""
                # is there `---| OPTION` on the next line?
                match = re.match(r"---\| (.*)", lines[index].strip())
                while match:
                    # yep! That's an option we can use for this field
                    print(f"> Found option {match.group(1)}")
                    docs["api"]["classes"][className]["fields"][fieldName]["options"] = docs["api"]["classes"][className]["fields"][fieldName].get("options", [])
                    docs["api"]["classes"][className]["fields"][fieldName]["options"].append(match.group(1))
                    index += 1
                    match = re.match(r"---\| (.*)", lines[index].strip())
            
            # check for `--- COMMENT`
            match = re.match(r"--- (.*)", line)
            if match:
                # yep! That's a comment we can use for this field
                print(f"> Found comment {match.group(1)}")
                desc += match.group(1) + "\n"
                continue

parser = argparse.ArgumentParser(prog="gendocs.py", description='Utility script to generate documentation from Kristal\'s source code.')
parser.add_argument('--kristal', nargs=1, help='The path to the Kristal folder')

args = parser.parse_args()

if args.kristal:
    kristal_path = args.kristal[0]

print(f"Generating docs...")

print("Reading Kristal version...")
try:
    with open(os.path.join(kristal_path, "VERSION"), "r") as file:
        ver_str = file.read()
        docs["version"] = ver_str
except:
    pass

print("Reading files...")

readfile(kristal_path, "main")

with open("docs.json", "w") as file:
    file.write(json.dumps(docs, indent=4))

print("Done!")
print("Generated files:")
print("> docs.json")