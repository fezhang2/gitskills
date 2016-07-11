#!/bin/bash
#test
# ----------------------------------------------------------------------
# History:
#  5-Oct-11 dwf  v0.01 first try
#                 - based on "rpmgen.cent53" from Quick Zhou 30-Sep-11
#  6-Oct-11 dwf  v0.02 handle filenames with embedded ' ' spaces [FAILED]
#  6-Oct-11 dwf  v0.03 handle filenames with embedded ' ' spaces
#  6-Oct-11 dwf  v0.04 fix "warning: File listed twice: " caused by directory names
#  7-Oct-11 quickz  v0.05 fix issue under Cygwin
#  18-Jan-12 jie    support to dependency define
# ----------------------------------------------------------------------
#[ex]<status>\s*[2-9]\d*\s*</status>
# This script creates an RPM image from a supplied directory 
# See Usage.

# dafunk comments 5-Oct-11 --------------------------------
# original script (rpmgen.cent53) from Quick Zhou 30-Sep-11
#	[-d Directory]
#	[-i InstallLocation]
#	[-v VersionNumber]
#	[-r ReleaseNumber]
#	[-s SpecFile]
#	[-f DependencyListFile]
#	[-g] - create spec file (only)
#              created in /var/tmp/rpmgen.XXXXXX/.PKG/[SpecFile]
#	[-h] - help
# Parameters - inputs
#   PLATFORM -- hardware type ex: "i386"
#  -d  RPMGEN_SRCDIR -- source dir (abs path), default pwd
#  -i  RPMGEN_INSTLOC -- install location, default RPMGEN_SRCDIR
#  -v  RPMGEN_VERSION -- version number, default "1"
#  -r  RPMGEN_RELEASE -- release number, default "1"
#  -s  RPMGEN_SPECFILE -- RPM spec file, default "" (null), will create
#  -p  PKG_NAME -- package name, default is current directory name
#END OF dafunk comments 5-Oct-11 --------------------------------

cleanup_tmp()
{
	_cleanup_save_dir=`pwd`
	cd /var/tmp
	echo "$0: Removing temporary directory at $RPMGEN_TMP...."
	rm -rf $RPMGEN_TMP
	cd $_cleanup_save_dir
}

catch_sigs()
{
	echo "$0 aborted"
	cleanup_tmp
	exit 1;
}

Usage()
{
cat << EndUsage
Usage: $0
	[-d Directory]
	[-i InstallLocation]
	[-v VersionNumber]
	[-r ReleaseNumber]
	[-s SpecFile]
	[-f DependencyListFile]
	[-g]
	[-h]

  Directory is where $0 can find the files to be packaged.

  InstallLocation is the default place to install files on the target system.
  Must be an absolute pathname!

  VersionNumber is a Version Number

  ReleaseNumber is a Release Number

  SpecFile is a hand-written Specfile.  The BuildRoot in this specfile
  will be changed appropriately.

  Use -g to just generate the spec file in SpecFile, and NOT generate
  any rpm image.

  Use -h to see this help message.
EndUsage
exit 1
}


# MAIN

RPMGEN_GENERATESPEC="0"

# Parse arguments

RPMGEN_ARGS=`getopt "hgd:i:v:r:s:p:f:" "$@"`
if [ $? != 0 ]; then
	echo "$0: Cannot understand arguments."
	Usage
fi

eval set -- "$RPMGEN_ARGS"

while true
do
	case "$1" in
		-d)	RPMGEN_SRCDIR="$2"
			shift; shift;;
		-i)	RPMGEN_INSTLOC="$2"
			shift; shift;;
		-v)	RPMGEN_VERSION="$2"
			shift; shift;;
		-r)	RPMGEN_RELEASE="$2"
			shift; shift;;
		-s)	RPMGEN_SPECFILE="$2"
			shift; shift;;
                -f)     RPMGEN_DEPENDENCYFILE="$2"
                        shift; shift;;
		-p)	RPMGEN_PKGNAME="$2"
			shift; shift;;
		-g)	RPMGEN_GENERATESPEC="1";
			shift;;
		-h)	Usage;;
		--)
			shift; break;;
		*)
			echo "$0: Invalid argument $1"
			Usage;;
	esac
done

if [ $# != 0 ]; then
	echo "$0: Ignoring extra arguments: $*"
	Usage
fi

# Set defaults for arguments that are not already defined
RPMGEN_SRCDIR=${RPMGEN_SRCDIR:-`pwd`}
RPMGEN_INSTLOC=${RPMGEN_INSTLOC:-`cd $RPMGEN_SRCDIR; pwd`}
RPMGEN_VERSION=${RPMGEN_VERSION:-"1"}
RPMGEN_RELEASE=${RPMGEN_RELEASE:-"1"}
RPMGEN_SPECFILE=${RPMGEN_SPECFILE:-""}
RPMGEN_PKGNAME=${RPMGEN_PKGNAME:-`basename $RPMGEN_SRCDIR`}

PKG_NAME=`echo ${RPMGEN_SRCDIR}|sed -e 's/.*\///g'`;
PLATFORM=`uname -i`
if [ "x$PLATFORM" = "x" -o "x$PLATFORM" = "xunknown" ]; then
	PLATFORM="i386"
fi
RPMHOME="redhat"
OS=`uname -o`
if [ "x$OS" = "xCygwin" ]; then
	RPMHOME="rpm"
fi

if [ "x${RPMGEN_DEPENDENCYFILE}" == 'x' ]; then
    RPMGEN_REQUIRES=''
else
    RPMGEN_REQUIRES=$(cat ${RPMGEN_DEPENDENCYFILE} 2>/dev/null)
fi

# Validate arguments

if [ ! -d $RPMGEN_SRCDIR ]; then
	echo "$0: Cannot find directory: $RPMGEN_SRCDIR"
	exit 1
fi

if [ -e $RPMGEN_SRCDIR/.PKG ]; then
	echo "$0: Cannot handle a directory ($RPMGEN_SRCDIR) that contains .PKG"
	exit 1
fi

if [ $RPMGEN_GENERATESPEC = "1" ]; then
	if [ "x$RPMGEN_SPECFILE" = "x" ]; then
		echo "$0: When using -g, you must specify a SpecFile"
		Usage
	fi

	if [ -e $RPMGEN_SPECFILE ]; then
		echo "$0: A -g will not overwrite an existing SpecFile, $RPMGEN_SPECFILE"
		Usage
	fi
else
	if [ "x$RPMGEN_SPECFILE" != "x" ]; then
		if [ ! -f $RPMGEN_SPECFILE ]; then
			echo "$0: Cannot find SpecFile $RPMGEN_SPECFILE"
			exit 1
		fi
	fi
fi

if expr substr $RPMGEN_INSTLOC 1 1 != "/" > /dev/null; then
	echo "$0: InstallLocation must be an ABSOLUTE path (start with /)"
	Usage
fi

# Summarize arguments for user
echo "$0: Create RPM image from directory $RPMGEN_SRCDIR"
echo "$0: Installation directory will be $RPMGEN_INSTLOC"
if [ "x$RPMGEN_SPECFILE" != "x" ]; then
	echo "$0: Using specfile: $RPMGEN_SPECFILE"
else
	echo "$0: Using default SpecFile"
fi
echo "$0: Version: $RPMGEN_VERSION"
echo "$0: Release: $RPMGEN_RELEASE"
echo "$0: Package Name: $RPMGEN_PKGNAME"

RPMGEN_TMP=`mktemp -q /var/tmp/rpmgen.XXXXXX`
if [ $? -ne 0 ]
then
	echo "$0: Cannot create temporary directory"
	exit 1
fi

#
# From this point on, we have state that requires cleanup!
#
_origdir=`pwd`
trap catch_sigs 1 2 3

rm -rf $RPMGEN_TMP
mkdir -p $RPMGEN_TMP
chmod 0755 $RPMGEN_TMP
mkdir $RPMGEN_TMP/.PKG
mkdir $RPMGEN_TMP/FILES
echo "echo $0: Using temporary working directory: $RPMGEN_TMP"

# Now, set up the tree that we'd like to RPM'ize
echo "$0: Create prototype tree...."
mkdir -p ${RPMGEN_TMP}/FILES/${RPMGEN_INSTLOC}
(cd $RPMGEN_SRCDIR; tar cf - .) | (cd $RPMGEN_TMP/FILES/$RPMGEN_INSTLOC; tar xpf -)
if [ $? -ne 0 ]; then
	echo "$0: Could not copy files from $RPMGEN_SRCDIR to $RPMGEN_TMP"
	exit 1
fi

cd ${RPMGEN_TMP}/FILES/${RPMGEN_INSTLOC};
##next: original find
## find . -print | egrep -v '^.$' > $RPMGEN_TMP/.PKG/filelist
##next: try to fix filenames with spaces using "\ " -- did NOT work
##find . -print | egrep -v '^.$' | sed -e 's/ /\\ /g' > $RPMGEN_TMP/.PKG/filelist
##next: remove "warning: File listed twice: " caused by directory names
find . ! -type d -print | egrep -v '^.$' > $RPMGEN_TMP/.PKG/filelist
if [ ! -s $RPMGEN_TMP/.PKG/filelist ]; then
	echo "$0: Empty file list!  Aborting."
	exit 1
fi

echo date=`date` > $RPMGEN_TMP/.PKG/PKGINFO
echo hostname=`hostname` >> $RPMGEN_TMP/.PKG/PKGINFO
echo HOME=$HOME >> $RPMGEN_TMP/.PKG/PKGINFO
echo FROM=$RPMGEN_SRCDIR >> $RPMGEN_TMP/.PKG/PKGINFO
echo pwd=$_origdir >> $RPMGEN_TMP/.PKG/PKGINFO
id >> $RPMGEN_TMP/.PKG/PKGINFO
echo >> $RPMGEN_TMP/.PKG/PKGINFO

# Set up a SPEC file for RPM
cd $RPMGEN_TMP/.PKG
echo RPMGEN_SPECFILE=$RPMGEN_SPECFILE
echo RPMGEN_GENERATESPEC=$RPMGEN_GENERATESPEC
if [ "X$RPMGEN_SPECFILE" != "X" -a $RPMGEN_GENERATESPEC != "1" ]; then
	cat $RPMGEN_SPECFILE | sed -e "s,^BuildRoot: .*,BuildRoot: $RPMGEN_TMP/FILES," > specfile
else
	cat << EndSpec > specfile
Summary: rpmgen-generated image
Name: $RPMGEN_PKGNAME
Version: $RPMGEN_VERSION
Release: $RPMGEN_RELEASE
License: Cisco Software License 1.0
URL:     http://www.cisco.com/
Group: Applications/Communications
Source: NoSource
Patch: NoPatches
BuildRoot:  $RPMGEN_TMP/FILES
Prefix: $RPMGEN_INSTLOC
AutoReqProv: no
#Requires: $RPMGEN_REQUIRES
%define _unpackaged_files_terminate_build 0
%define __prelink_undo_cmd %{nil}
%description
Packaging information:
`cat $RPMGEN_TMP/.PKG/PKGINFO`
%prep
%build
%install
mkdir -p %{buildroot}
if [ %{buildroot} = $RPMGEN_TMP/FILES ]; then
    echo "files in buildroot is already exist"
else
    cp -rf $RPMGEN_TMP/FILES/* %{buildroot}/ >/dev/null 2>&1
fi
%clean
%files
%defattr(-,root,root)
`cat $RPMGEN_TMP/.PKG/filelist | sed -e "s,^\./,$RPMGEN_INSTLOC/," -e 's,^,",' -e 's,$,",'`
%pre
%post
test -f ${RPMGEN_INSTLOC}/bin/setup.sh && sh ${RPMGEN_INSTLOC}/bin/setup.sh ${RPMGEN_VERSION}
%preun
%changelog
EndSpec
fi

if [ $RPMGEN_GENERATESPEC = "1" ]; then
	cp specfile $RPMGEN_SPECFILE
	echo "$0: Created SpecFile at"
	echo $RPMGEN_SPECFILE
	exit 0
fi

# Force RPM to use our RPMGEN_TMP directory rather than /usr/src/redhat.
# YUCH!
echo "$0:current directory[`pwd`]"
mkdir  BUILD 
mkdir RPMS
mkdir RPMS/$PLATFORM
mkdir SOURCES
mkdir SPECS
mkdir SRPMS
echo '%_topdir' $RPMGEN_TMP/.PKG > .rpmmacros
cp /usr/lib/rpm/rpmrc .
_MACROLINE=`grep '^macrofiles' rpmrc`
#echo $_MACROLINE:./.rpmmacros >> rpmrc
echo $_MACROLINE:`pwd`/.rpmmacros >> rpmrc

# Don't let rpm strip our binaries.  There's got to be a better
# way to do this, but it's not obvious.
# (See /usr/lib/rpm/brp-strip)
mkdir STRIPJUNK
echo > STRIPJUNK/strip
chmod +x STRIPJUNK/strip
PATH="`pwd`/STRIPJUNK:$PATH"

echo "$0: Constructing RPM file.  This may take several minutes!"

if [ "x$OS" = "xCygwin" ]; then
    RPMGEN_OUTFILE="$RPMGEN_PKGNAME-${RPMGEN_VERSION}-${RPMGEN_RELEASE}.cygwin.$PLATFORM.rpm"
else
    RPMGEN_OUTFILE="$RPMGEN_PKGNAME-${RPMGEN_VERSION}-${RPMGEN_RELEASE}-centos6.3_32.rpm"
    if [ $PLATFORM == 'x86_64' ]; then
        RPMGEN_OUTFILE="$RPMGEN_PKGNAME-${RPMGEN_VERSION}-${RPMGEN_RELEASE}-centos6.3_64.rpm"
    fi
fi
if [ "x$OS" = "xCygwin" ]; then
	rpmbuild -bb --target i386-redhat-linux -timecheck 0  --rcfile ./rpmrc specfile  
	cd $_origdir
	mv -f $RPMGEN_TMP/.PKG/RPMS/i386/$RPMGEN_PKGNAME-${RPMGEN_VERSION}-${RPMGEN_RELEASE}.cygwin.$PLATFORM.rpm .
else
	rpmbuild -bb -timecheck 0  --macros ./.rpmmacros --buildroot $RPMGEN_TMP/FILES --rcfile ./rpmrc specfile  
	cd $_origdir
	#mv -f /usr/src/$RPMHOME/RPMS/$PLATFORM/$RPMGEN_PKGNAME-${RPMGEN_VERSION}-${RPMGEN_RELEASE}.$PLATFORM.rpm .
	mv -f /usr/src/$RPMHOME/RPMS/$PLATFORM/$RPMGEN_PKGNAME-${RPMGEN_VERSION}-${RPMGEN_RELEASE}.$PLATFORM.rpm ./${RPMGEN_OUTFILE}
fi
mv_return_value=$?



if [ $mv_return_value -ne 0 ]
then
	echo "$0: Cannot generate RPM image.  Something has gone wrong."
	exit 1
else
	echo "$0: The RPM image of $RPMGEN_SRCDIR is at"
	echo "`pwd`/$RPMGEN_OUTFILE"
fi

cleanup_tmp
exit 0
