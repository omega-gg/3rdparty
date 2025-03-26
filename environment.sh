#!/bin/sh
set -e

#--------------------------------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------------------------------
# environment

compiler_win="mingw"

qt="qt6"

mobile="simulator"

#--------------------------------------------------------------------------------------------------
# Functions
#--------------------------------------------------------------------------------------------------

replace()
{
    expression='s/'"$1"'=\"'"$2"'"/'"$1"'=\"'"$3"'"/g'

    apply $expression environment.sh

    apply $expression generate.sh
    apply $expression install.sh
    apply $expression snap.sh
}

apply()
{
    if [ $host = "macOS" ]; then

        sed -i "" $1 $2
    else
        sed -i $1 $2
    fi
}

#--------------------------------------------------------------------------------------------------

getOs()
{
    case `uname` in
    Darwin*) echo "macOS";;
    *)       echo "other";;
    esac
}

#--------------------------------------------------------------------------------------------------
# Syntax
#--------------------------------------------------------------------------------------------------

if [ $# != 1 ] \
   || \
   [ $1 != "mingw" -a $1 != "msvc" -a $1 != "qt4" -a $1 != "qt5" -a $1 != "qt6" -a \
     $1 != "simulator" -a $1 != "device" ]; then

    echo "Usage: environment <mingw | msvc"
    echo "                    qt4 | qt5 | qt6 |"
    echo "                    simulator | device>"

    exit 1
fi

#--------------------------------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------------------------------

host=$(getOs)

#--------------------------------------------------------------------------------------------------
# Replacements
#--------------------------------------------------------------------------------------------------

if [ $1 = "msvc" -o $1 = "mingw" ]; then

    replace compiler_win $compiler_win $1

elif [ $1 = "qt4" -o $1 = "qt5" -o $1 = "qt6" ]; then

    replace qt $qt $1
else
    replace mobile $mobile $1
fi
