#!/usr/bin/env bash
#
# NAME
#        unrarr.sh - UnRAR recursive
#
# SYNOPSIS
#        unrarr.sh [options] directory...
#
# OPTIONS
#        -d, --delete
#               Delete files after successfully uncompressing them
#
#        -v
#               Verbose output
#
# EXAMPLE
#        ./unrarr.sh ~/downloads
#
#        Uncompress all RAR files in ~/downloads
#
# DESCRIPTION
#        Unrar (and optionally delete) recursively in directories.
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

# Output error message
error() {
    test -t 1 && {
        tput setf 4
        echo "$1" >&2
        tput setf 7
    } || echo "$1" >&2
    exit ${2-$EX_UNKNOWN}
}

verbose_echo() {
    if [ -n "${verbose+defined}" ]
    then
        echo "$*"
    fi
}

usage()
{
    error "Usage: ${cmdname} [-v|--verbose] [-d|--delete] directory..." $EX_USAGE
}

PATH="/usr/bin:/bin"
cmdname=$(basename $0)
directory=$(dirname $0)

# Exit codes from /usr/include/sysexits.h, as recommended by
# http://www.faqs.org/docs/abs/HTML/exitcodes.html
EX_OK=0           # successful termination
EX_USAGE=64       # command line usage error
EX_DATAERR=65     # data format error
EX_NOINPUT=66     # cannot open input
EX_NOUSER=67      # addressee unknown
EX_NOHOST=68      # host name unknown
EX_UNAVAILABLE=69 # service unavailable
EX_SOFTWARE=70    # internal software error
EX_OSERR=71       # system error (e.g., can't fork)
EX_OSFILE=72      # critical OS file missing
EX_CANTCREAT=73   # can't create (user) output file
EX_IOERR=74       # input/output error
EX_TEMPFAIL=75    # temp failure; user is invited to retry
EX_PROTOCOL=76    # remote error in protocol
EX_NOPERM=77      # permission denied
EX_CONFIG=78      # configuration error

# Custom errors
EX_UNKNOWN=1
EX_NO_SUCH_DIR=91
EX_NO_SUCH_EXEC=92

# Process parameters
params="$(getopt --options vd --longoptions verbose,delete --name $cmdname -- "$@")" || usage

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
            usage
            ;;
    esac
done

# Check for dirs
if [ $# -eq 0 ]
then
    verbose_echo "No directories in output"
    usage
fi

verbose_echo "Running $cmdname at `date`."

# Unrar files
for dir
do
    verbose_echo "Processing directory $dir"

    if [ ! -d "$dir" ]
    then
        error 'No such directory: '"$dir" $EX_NO_SUCH_DIR
    fi

    while IFS= read -r -d '' -u 9 file
    do
        verbose_echo "Extracting $file"
        dirx="$(dirname -- "$file"; echo x)"
        cd -- "${dirx%$'\nx'}"
        rar x -- "$file" || error "Failed when processing $file"
        if [ -n "${delete+defined}" ]
        then
            verbose_echo "Deleting $file"
            rm -- "$file"
        fi
    done 9< <(find "$dir" -wholename "*.rar" -print0)
done

verbose_echo "Cleaning up."

# End
verbose_echo "${cmdname} completed at `date`."
exit $EX_OK
