#!/bin/sh
#
# NAME
#    unrarr.sh - UnRAR recursive
#
# SYNOPSIS
#    unrarr.sh [options] directory...
#
# OPTIONS
#    -d,--delete    Delete files after successfully uncompressing them
#    -v             Verbose output
#
# EXAMPLE
#    ./unrarr.sh ~/downloads
#
#    Uncompress all RAR files in ~/downloads
#
# DESCRIPTION
#    Unrar (and optionally delete) recursively in directories.
#
# BUGS
#    Email bugs to victor dot engmark at gmail dot com. Please include the
#    output of running this script in verbose mode (-v).
#
# COPYRIGHT AND LICENSE
#    Copyright (C) 2009 Victor Engmark
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
################################################################################

# Output error message
error()
{
    test -t 1 && {
		tput setf 4
		echo "$1" >&2
		tput setf 7
	} || echo "$1" >&2
    if [ -z "$2" ]
    then
        exit $EX_UNKNOWN
    else
        exit $2
    fi
}

verbose_echo()
{
    if [ $verbose ]
    then
        echo "$*"
    fi
}

usage()
{
    error "Usage: ${cmdname} [-v|--verbose] [-d|--delete] directory..." $EX_USAGE
}

# Check if a path is an existing directory
directory_exists()
{
    if [ -d $1 ]
    then
        echo 1
    fi
}

# Use for mandatory directory checks
# $2 is the (optional) error message
require_directory()
{
    if [ ! $(directory_exists $1) ]
    then
        error "No such directory '${1}'
$2" $EX_NO_SUCH_DIR
    fi
}

# Check if an executable exists on the path
executable_exists()
{
    if [ "$(which $1 2>/dev/null)" ]
    then
        echo 1
    fi
}

# Make sure an executable is available
# $2 is the optional error message
require_executable()
{
    if [ ! $(executable_exists $1) ]
    then
        error "No such executable '${1}'
$2" $EX_NO_SUCH_EXEC
    fi
}

# Make a random temporary directory for intermediary storage
create_temp()
{
    temp_dir=`mktemp -t -d ${cmdname}.XXXXXXXXXX` || error "Couldn't create temporary directory" $EX_CANTCREAT
    verbose_echo "Created temporary directory ${temp_dir}"
}

ifs_original="$IFS" # Reset when done
IFS="
" # Make sure paths with spaces don't make any trouble when looping
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
params=`getopt --options vd --longoptions verbose,delete --name $cmdname -- "$@"`
if [ $? != 0 ]
then
    usage
fi

eval set -- "$params"

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
        --) shift
            break
            ;;
        *)
            usage
            ;;
    esac
done

dirs=$*

# Check for dirs
if [ -z "$dirs" ]
then
    verbose_echo "No directories in output"
    usage
fi

verbose_echo "Running $cmdname at `date`."

# Unrar files
for dir in $dirs
do
    verbose_echo "Processing directory $dir"

    require_directory $dir

    for file in `find $dir -wholename "*.rar"`
    do
        verbose_echo "Extracting $file"
        rar x "$file" "`dirname $file`" || error "Failed when processing $file"
        if [ $delete ]
        then
            verbose_echo "Deleting $file"
            rm "$file"
        fi
    done
done

verbose_echo "Cleaning up."
IFS="$ifs_original"

# End
verbose_echo "${cmdname} completed at `date`."
exit $EX_OK
