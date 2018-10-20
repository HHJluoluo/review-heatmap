#!/bin/bash
#
# Description: Generate PyQt forms from QtDesigner project files
# Usage: build_ui.sh <project_prefix> <anki_version>
# Dependencies: pyuic4 pyuic5 pyrcc4 pyrcc5
#
# Copyright: (c) 2017-2018 Glutanimate <https://glutanimate.com/>
#            (c) 2016 Damien Elmes <http://ichi2.net/contact.html>
# License: GNU AGPLv3 <https://www.gnu.org/licenses/agpl.html>

shopt -s nullglob

project_prefix="$1"
anki_version="$2"
src_folder="src/${project_prefix}"

declare -A qt_versions_by_anki
qt_versions_by_anki[anki20]="4"
qt_versions_by_anki[anki21]="5"

declare -A pyuic_opts
pyuic_opts[4]=""
pyuic_opts[5]="--from-imports"

if [[ -z "$project_prefix" ]]; then
    echo "Please supply a project prefix."
    exit 1
fi

if [[ -z "$anki_version" ]]; then
    echo "Please specify the anki version."
    exit 1
fi

if [[ ! -d "$src_folder" ]]; then
    echo "Source folder not found."
    exit 1
fi

if [[ ! -d "designer" ]]; then
    echo "No QT designer folder found (PWD: $PWD). Skipping UI build."
    exit 0
fi

if [[ -z "$(find designer -name '*.ui')" ]]; then
    echo "No designer files found. Skipping UI build."
    exit 0
fi

function build_for_anki_version () {

    anki_version="$1"
    qt_version="${qt_versions_by_anki[$anki_version]}"

    if [[ -z "$qt_version" ]]; then
        echo "Invalid anki version. Supported versions: ${!qt_versions_by_anki[@]}"
        exit 1
    fi

    pyuic_exec="pyuic${qt_version}"
    pyrcc_exec="pyrcc${qt_version}"
    form_dir="${src_folder}/dialogs/forms/${anki_version}"
    if ! type "$pyuic_exec" >/dev/null 2>&1; then
        echo "${pyuic_exec} not found. Skipping generation."
        return 0
    fi
    if ! type "$pyrcc_exec" >/dev/null 2>&1; then
        echo "${pyrcc_exec} not found. Skipping generation."
        return 0
    fi
    rm -rf "$form_dir"
    mkdir -p "${form_dir}"
    init_file="${form_dir}/__init__.py"
    echo "Writing init file for ${form_dir}..."
    echo "# This file was auto-generated by build_ui.sh. Don't edit." > "${init_file}"
    echo "Building forms.."
    for i in designer/*.ui; do
        name="${i##*/}"
        base="${name%.*}"
        outfile="$form_dir/${base}.py"
        echo "Generating ${outfile}"
        "$pyuic_exec" ${pyuic_opts[$qt_version]} "$i" -o "${outfile}"
    done
    echo "Building resources.."
    for i in designer/*.qrc; do
        name="${i##*/}"
        base="${name%.*}"
        outfile="$form_dir/${base}_rc.py"
        echo "Generating ${outfile}"
        "$pyrcc_exec" "$i" -o "${outfile}"
    done
}

# Main

build_for_anki_version "${anki_version}"

echo "Done."
