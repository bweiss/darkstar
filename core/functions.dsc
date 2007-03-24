#
# $Id$
# functions.dsc - Miscellaneous functions
# Copyright (c) 2002-2005 Brian Weiss
# Copyright (c) 2005 David B. Kratter
# See the 'COPYRIGHT' file for more information.
#

addconfig -b TIMESTAMP 0;
addconfig    TIMESTAMP_FORMAT [%H:%M] ;

#
# Works just like the builtin $cparse() but outputs ANSI color
# codes instead of ^C color codes. This was written by |Rain|.
#
# WARNING! THIS FUNCTION IS PURE EVIL AND SHOULD NOT BE USED UNDER
# ANY CIRCUMSTANCES ;-)
#
alias ansicparse (...)
{
	@:tmp = cparse($*);
	@:tmp = sar(g/30/[30m/$tmp);
	@:tmp = sar(g/31/[0\;31m/$tmp);
	@:tmp = sar(g/32/[0\;32m/$tmp);
	@:tmp = sar(g/33/[0\;33m/$tmp);
	@:tmp = sar(g/34/[0\;34m/$tmp);
	@:tmp = sar(g/35/[0\;35m/$tmp);
	@:tmp = sar(g/36/[0\;36m/$tmp);
	@:tmp = sar(g/37/[0\;37m/$tmp);
	@:tmp = sar(g/40/[40m/$tmp);
	@:tmp = sar(g/41/[41m/$tmp);
	@:tmp = sar(g/42/[42m/$tmp);
	@:tmp = sar(g/43/[43m/$tmp);
	@:tmp = sar(g/44/[44m/$tmp);
	@:tmp = sar(g/45/[45m/$tmp);
	@:tmp = sar(g/46/[46m/$tmp);
	@:tmp = sar(g/47/[47m/$tmp);
	@:tmp = sar(g/50/[1\;30m/$tmp);
	@:tmp = sar(g/51/[1\;31m/$tmp);
	@:tmp = sar(g/52/[1\;32m/$tmp);
	@:tmp = sar(g/53/[1\;33m/$tmp);
	@:tmp = sar(g/54/[1\;34m/$tmp);
	@:tmp = sar(g/55/[1\;35m/$tmp);
	@:tmp = sar(g/56/[1\;36m/$tmp);
	@:tmp = sar(g/57/[1\;37m/$tmp);
	@:tmp = sar(g/-1/[0m/$tmp);
	@:tmp = sar(g//[0m/$tmp);
	@ function_return = tmp;
};

#
# Convert between 1/0 and ON/OFF.
# These are mostly used by /DSET.
#
alias bool2num (arg, void)
{
	switch ($toupper($arg))
	{
		(0) (OFF) {@ function_return = 0};
		(1) (ON)  {@ function_return = 1};
		(*)       {@ function_return = arg};
	};
};

alias bool2word (arg, void)      
{
	switch ($arg)
	{
		(0) (OFF) {@ function_return = [OFF]};
		(1) (ON)  {@ function_return = [ON]};
		(*)       {@ function_return = arg};
	};
};

#
# Special thanks to |Rain| and CrazyEddy for help optimizing the following
# channel user functions.
#
alias chhops (chan default "$C", void)
{
	@ function_return = strip(%+?. $pattern(\\%* $channel($chan)));
};

alias nochhops (chan default "$C", void)
{
	@ function_return = strip(@+?. $filter(\\%* $channel($chan)));
};

alias chvoices (chan default "$C", void)
{
	@ function_return = strip(@%+?. $pattern(?+* $channel($chan)));
};

alias nochvoices (chan default "$C", void)
{
	@ function_return = strip(@%?. $filter(?+* $channel($chan)));
};

alias chnormal (chan default "$C", void)
{
	@ function_return = strip(?. $pattern("\\[.. \\?. .\\? \\?\\?\\]*" $channel($chan)));
};

alias country (...)
{
	if (functioncall()) {
		@ function_return = tld($*);
	} else {
		tld $*;
	};
};

#
# This function converts an integer representing an arbitrary number
# of bytes into a more human readable form. It was taken from the
# mail script that was recently added to the EPIC4 distribution and
# placed in the public domain by its author, wd.
#
alias fmtfsize (bytes, void)
{
	^stack push set FLOATING_POINT_MATH;
	^set FLOATING_POINT_MATH ON;
	if (!bytes) {
		@ function_return = [0b];
	} else if (bytes < 1024) {
		@ function_return = [${bytes}b];
	} else if (bytes < 1048576) {
		@ function_return = [$trunc(2 ${bytes / 1024})kb];
	} else if (bytes < 1073741824) {
		@ function_return = [$trunc(2 ${bytes / 1048576})mb];
	} else if (bytes < 1099511627776) {
		@ function_return = [$trunc(2 ${bytes / 1073741824})gb];
	} else {
		@ function_return = [$trunc(2 ${bytes / 1099511627776})tb];
	};
	^stack pop set FLOATING_POINT_MATH;
};

alias fparse (...)
{
	eval return $cparse($(FORMAT.$0));
};

alias fparse2 (...)
{
	eval return $(FORMAT.$0);
};

#
# Retrieves the values of a list of item numbers and/or ranges of numbers
# (e.g. "3-7") from an array. The value of the offset argument will be added
# to each item number before its value is retrieved. This allows the real
# item numbers to be mapped to any range of numbers. All non-numeric words
# in the item list will also be returned.
#
alias getitems (array, offset, list)
{
	if (!getarrays($array) || !isnumber(b10 $offset) || !list)
		return;

	for word in ($list)
	{
		if (isnumber(b10 $word))
		{
			@ :word += offset;
			@ push(function_return $getitem($array $word));
		}
		else if (match(%-% $word) && isnumber(b10 $strip(- $word)))
		{
			for num in ($jot($split(- $word))) {
				@ :num += offset;
				@ push(function_return $getitem($array $num));
			};
		}{
			@ push(function_return $word);
		};
	};
};

alias getdsets (args default "*")
{
	for patt in ($args) {
		@ push(function_return $pattern($patt $sar(g/_DSET.//$aliasctl(assign match _DSET.))));
	};
};

alias getfsets (args default "*")
{
	for patt in ($args) {
		@ push(function_return $pattern($patt $sar(g/_FSET.//$aliasctl(assign match _FSET.))));
	};
};

#
# Determines whether someone is currently online. It returns the
# person's nick if they are online, or nothing if not.
# This was taken from the "guh" script distributed with EPIC.
# It was written by Jeremy Nelson <jnelson@epicsol.org>.
#
alias is_on (nick, void)
{
	if (!nick) {
		return;
	};
	stack push on 303;
	^on ^303 * {
		stack pop on 303;
		return $0;
	};
	wait for ison $nick;
};

alias isloaded (module, void)
{
	@ function_return = finditem(_loaded_modules $module) > -1 ? 1 : 0;
};

alias loadedmods (args default "*")
{
	for ii from 1 to $numitems(_loaded_modules) {
		@ push(:tmp $getitem(_loaded_modules ${ii-1}));
	};
	for patt in ($args) {
		@ push(function_return $pattern($patt $tmp));
	};
};

#
# $modinfo(<module> [a|f|v])
# Easy interface to the module information.
# Flags:    a - Returns filename and version.
#           f - Returns only the filename.
#           v - Returns only the version.
# If no flag is specified then 'a' is assumed.
#
alias modinfo (module, flag)
{
	if ((:item = finditem(_modules $module)) > -1)
	{
		switch ($tolower($flag))
		{
			(a) () {
				@ function_return = _MODULE.$module;
				@ push(function_return $_MODULE[$module][VERSION]);
			}
			(f) {
				@ function_return = _MODULE[$module];
			}
			(v) {
				@ function_return = _MODULE[$module][VERSION];
			}
		};
	};
};

alias mods (args default "*")
{
	for ii from 1 to $numitems(_modules) {
		@ push(:tmp $getitem(_modules ${ii-1}));
	};
	for patt in ($args) {
		@ push(function_return $pattern($patt $tmp)):
	};
};

#
# The original version of this function was taken from EPIC4-1.1.3 and
# was written by Jeremy Nelson. It has been modified to use $rand() to
# generate a unique process name, rather than a global variable that
# is incremented every time the function is called. -bmw
#
# Ok.  Here's the plan.
#
# $pipe(commands) will return the output from 'commands'.
#
alias pipe
{
	@ srand($time());
	@:desc = [pipe] ## rand(999999);
	^local retval;
	^on ^exec "$desc *" {
		bless;
		push retval $1-;
	};
	^exec -name $desc $*;
	^wait %$desc;
	^on exec -"$desc *";
	return $retval;
};
#hop '97

alias tld
{
	if ([$0])
	{
		if (functioncall())
		{
			@ function_return = TLD.$0 ? TLD.$0 : [unknown];
		}{
			@ :name = TLD.$0 ? TLD.$0 : [unknown];
			xecho -b Top-level domain "$0" is "$name";
		};
	};
};

alias ts (time default "$time()", void)
{
	if (CONFIG.TIMESTAMP) {
		@ function_return = strftime($time $CONFIG.TIMESTAMP_FORMAT);
	};
};

#
# Written by Jeremy Nelson in '93 and distributed
# with EPIC4 in the guh script.
#
# Takes a white space separated list of nicks and returns
# their userhosts. This differs from $userhost() in that it
# queries the server rather than trying to pull the userhosts
# from the client's cache.
#
alias uh
{
	^local blahblah;
	wait for {
		^userhost $* -cmd {
			bless;
			push blahblah $3@$4;
		};
	};
	return $blahblah;
};

alias visiblewins (void)
{
	for wref in ($winrefs())
	{
		if (winvisible($wref) > 0) {
			@ push(:ret $wref);
		};
	};
	@ function_return = revw($ret);
};

#
# Returns the names of all channels belonging to a specific window.
# If no window is specified the current window is used.
#
alias winchannels (win default "$winnum()", void)
{
	@ :serv = winserv($win);
	for chan in ($mychannels($serv))
	{
		xeval -s $serv {
			if (winchan($chan) == win) {
				@ push(function_return $chan);
			};
		};
	};
};

#
# The following functions were all pulled from the 'builtins' script
# that is included with EPIC5.
#
# Copyright (c) 2006 BlackJac@EFNet
#

# Only load these functions with EPIC5.
if (info(i) >= 1000) {

alias lastserver (void) {
	return $serverctl(last_server);
};

alias myservers (arg, void) {
	fe ($serverctl(omatch *)) mm {
		if (serverctl(get $mm connected)) {
			push :servers $mm;
		};
	};
	fe ($servers) nn {
		push function_return ${@arg ? nn : servername($nn)};
	};
};

alias notifywindows (void) {
	fe ($windowctl(refnums)) nn {
		if (windowctl(get $nn notified)) {
			push function_return $nn;
		};
	};
};

alias servergroup (refnum default "$serverctl(from_server)", void) {
	if (:group = serverctl(get $refnum group)) {
		return $group;
	};
	return <default>;
};

alias servername (refnum default "$serverctl(from_server)", void) {
	if (:name = serverctl(get $refnum itsname)) {
		return $name;
	};
	return <none>;
};

alias servernick (refnum default "$serverctl(from_server)", void) {
	return $serverctl(get $refnum nickname);
};

alias servernum (refnum default "$serverctl(from_server)", void) {
	if ((:num = serverctl(refnum $refnum)) >= -1) {
		return $num;
	};
	return -1;
};

alias serverourname (refnum default "$serverctl(from_server)", void) {
	if (:ourname = serverctl(get $refnum name)) {
		return $ourname;
	};
	return <none>;
};

alias servertype (refnum default "$serverctl(from_server)", void) {
	return $serverctl(get $refnum protocol);
};

alias servports (refnum default "$serverctl(from_server)", void) {
	return $serverctl(get $refnum port) $serverctl(get $refnum localport);
};

alias winbound (winnum default 0, void) {
	return $windowctl(get $windowctl(refnum $winnum) bind_channel);
};
  
alias wincursorline (winnum default 0, void) {
	if ((:cursorline = windowctl(get $windowctl(refnum $winnum) cursor)) > -1) {
		return $cursorline;
	};
	return -1;
};

alias winlevel (winnum default 0, void) {
	return $windowctl(get $windowctl(refnum $winnum) window_level);
};
  
alias winline (linenum, winnum default 0, void) {
	if ((:line = windowctl(get $windowctl(get refnum $winnum) line $linenum)) >= -1) {
		return $line;
	};
	return -1;
};

alias winnam (winnum default 0, void) {
	return $windowctl(get $windowctl(refnum $winnum) name);
};

alias winnicklist (winnum default 0, void) {
	return $windowctl(get $windowctl(refnum $winnum) nicklist);
};
  
alias winnum (winnum default 0, void) {
	if (:num = windowctl(get $windowctl(refnum $winnum) refnum)) {
		return $num;
	};
	return -1;
};

alias winquery (winnum default 0, void) {
	return $windowctl(get $windowctl(refnum $winnum) query);
};
  
alias winrefs (void) {
	return $windowctl(refnums);
};

alias winscrollbacksize (winnum default 0, void) {
	if ((:scrollbacksize = windowctl(get $windowctl(refnum $winnum) display_buffer_size)) > -1) {
		return $scrollbacksize;
	};
	return -1;
};

alias winserv (winnum default 0, void) {
	if ((:serv = windowctl(get $windowctl(refnum $winnum) server)) > -3) {
		return $serv;
	};
	return -1;
};

alias winsize (winnum default 0, void) {
	return $windowctl(get $windowctl(refnum $winnum) display_size);
};

alias winstatsize (winnum default 0, void) {
	if ((:statsize = windowctl(get $windowctl(refnum $winnum) double)) > -1) {
		return ${statsize + 1};
	};
	return -1;
};

alias winvisible (winnum default 0, void) {
	if ((:visible = windowctl(get $windowctl(refnum $winnum) visible)) > -1) {
		return $visible;
	};
	return -1;
};

};
