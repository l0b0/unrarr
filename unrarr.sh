#!/usr/bin/env bash
#
# NAME
#        unrarr.sh - UnRAR recursive
#
# SYNOPSIS
#        unrarr.sh [options] directory...
#
# DESCRIPTION
#        Unrar (and optionally delete) recursively in directories.
#
# OPTIONS
#        -d, --delete
#               Delete files after successfully uncompressing them
#
#        -v, --verbose
#               Verbose output
#
# EXAMPLE
#        ./unrarr.sh ~/downloads
#               Uncompress all RAR files in ~/downloads.
#
#        ./unrarr.sh --delete ~/archives
#               Uncompress all RAR files in ~/archives and delete them
#               afterwards.
#
# BUGS
#        https://github.com/l0b0/unrarr/issues
#
# COPYRIGHT AND LICENSE
#        Copyright (C) 2009, 2012 Victor Engmark
#
#        This program is free software: you can redistribute it and/or modify
#        it under the terms of the GNU General Public License as published by
#        the Free Software Foundation, either version 3 of the License, or
#        (at your option) any later version.
#
#        This program is distributed in the hope that it will be useful,
#        but WITHOUT ANY WARRANTY; without even the implied warranty of
#        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#        GNU General Public License for more details.
#
#        You should have received a copy of the GNU General Public License
#        along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
################################################################################

set -o errexit -o noclobber -o nounset -o pipefail

PATH="/usr/bin:/bin"
directory="$(dirname -- "$0")"

. "$directory"/shell-includes/error.sh
. "$directory"/shell-includes/usage.sh
. "$directory"/shell-includes/variables.sh
. "$directory"/shell-includes/verbose_echo.sh

# Custom errors
ex_no_such_dir=91

# Process parameters
params="$(getopt --options vd --longoptions verbose,delete --name "$script" -- "$@")" || usage $ex_usage

eval set -- "$params"
unset params

while true
do
    case $1 in
        -v|--verbose)
            verbose=1
            shift
            ;;
        -d|--delete)
            delete=1
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Not implemented: $1" >&2
            usage $ex_unknown
            ;;
    esac
done

verbose_echo "Running $script at $(date)."

if [ -z "${verbose-}" ]
then
    unrar_options='-inul'
fi

shopt -s extglob # For removal of multipart archives

# Unrar files
for dir
do
    verbose_echo "Processing directory: $dir"

    if [ ! -d "$dir" ]
    then
        error 'No such directory: '"$dir" $ex_no_such_dir
    fi

    while IFS= read -r -d '' -u 9 file
    do
        if [ ! -e "$file" ]
        then
            # Probably removed with multi-part archive
            echo "Skipping missing file: $file" >&2
            continue
        fi
        verbose_echo "Extracting $file"
        dirx="$(dirname -- "$file"; echo x)"
        cd -- "${dirx%$'\nx'}"
        rar x ${unrar_options-} -- "$file" || error "Failed when processing $file"
        if [ -n "${delete+defined}" ]
        then
            if [[ "$file" =~ .*\.part[0-9]*[0-9].rar ]]
            then
                # Standard multipart archive
                rm ${verbose+--verbose} -- "${file%%.part+([0-9]).rar}.part"+([0-9])".rar"
            else
                rm ${verbose+--verbose} -- "$file"
                if [ -e "${file%%.rar}".r00 ]
                then
                    # -vn multipart archive
                    rm ${verbose+--verbose} -- "${file%%.rar}.r"[0-9][0-9]
                fi
            fi
        fi
    done 9< <(find "$dir" -wholename "*.rar" -print0)
done

verbose_echo "Cleaning up."

# End
verbose_echo "${script} completed at $(date)."
exit $ex_ok
