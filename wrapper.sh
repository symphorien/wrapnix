#!/bin/bash
set -e
export LANG=C

info () {
	echo "$@" >&2
}

warn () {
	info warning: "$@"
}

die () {
	info error: "$@"
	exit 1
}

{ who | grep -v $(whoami) ; } && die "other users";

prefix=/tmp/wrapnix
if [ -e $prefix ]; then
	if ! [ -d $prefix -a -O $prefix ] ; then
		die "The default prefix $prefix is not usable (permissions ?)"
	fi
else
	rm -rf ~/.nix-profile
	mkdir -p $prefix || die "cannot create $prefix"
fi

chmod 700 $prefix
cd $prefix

if ! [ -x proot-x86_64 ]; then
	wget https://github.com/proot-me/proot-static-build/raw/master/static/proot-x86_64 -o proot >&2
	chmod +x proot-x86_64
fi

[ -d nix ] || mkdir nix

if ! [ -f install ]; then
	wget https://nixos.org/nix/install >&2
fi

here=$(dirname $(readlink -f $0))
export NIX_CONF_DIR=$here

exec ./proot-x86_64 -b ./nix:/nix bash -c '
profile=/nix/var/nix/profiles/per-user/$(whoami)
if ! [ -d $profile ]; then
	mkdir -p $profile
	bash ./install >&2
fi
export PATH=
.  ~/.nix-profile/etc/profile.d/nix.sh
cd
echo Running $SSH_ORIGINAL_COMMAND >&2
exec /usr/bin/nice -n 15 /bin/bash -c "$SSH_ORIGINAL_COMMAND"
'

