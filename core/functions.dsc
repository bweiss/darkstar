/* $Id$ */
/*
 * functions.dsc - Miscellaneous functions
 * Copyright (c) 2002 Brian Weiss (except where noted)
 * See the 'COPYRIGHT' file for more information.
 */

/*
 * Works just like the builtin $cparse() but outputs ANSI color
 * codes instead of ^C color codes. This was written by Ben Winslow.
 */
alias ansicparse {
	@:tmp = cparse($*)
	@:tmp = sar(g/30/[30m/$tmp)
	@:tmp = sar(g/31/[0\;31m/$tmp)
	@:tmp = sar(g/32/[0\;32m/$tmp)
	@:tmp = sar(g/33/[0\;33m/$tmp)
	@:tmp = sar(g/34/[0\;34m/$tmp)
	@:tmp = sar(g/35/[0\;35m/$tmp)
	@:tmp = sar(g/36/[0\;36m/$tmp)
	@:tmp = sar(g/37/[0\;37m/$tmp)
	@:tmp = sar(g/40/[40m/$tmp)
	@:tmp = sar(g/41/[41m/$tmp)
	@:tmp = sar(g/42/[42m/$tmp)
	@:tmp = sar(g/43/[43m/$tmp)
	@:tmp = sar(g/44/[44m/$tmp)
	@:tmp = sar(g/45/[45m/$tmp)
	@:tmp = sar(g/46/[46m/$tmp)
	@:tmp = sar(g/47/[47m/$tmp)
	@:tmp = sar(g/50/[1\;30m/$tmp)
	@:tmp = sar(g/51/[1\;31m/$tmp)
	@:tmp = sar(g/52/[1\;32m/$tmp)
	@:tmp = sar(g/53/[1\;33m/$tmp)
	@:tmp = sar(g/54/[1\;34m/$tmp)
	@:tmp = sar(g/55/[1\;35m/$tmp)
	@:tmp = sar(g/56/[1\;36m/$tmp)
	@:tmp = sar(g/57/[1\;37m/$tmp)
	@:tmp = sar(g/-1/[0m/$tmp)
	@:tmp = sar(g//[0m/$tmp)
	return $tmp
}

/*
 * Convert between 1/0 and ON/OFF.
 * These are mostly used by /DSET.
 */
alias bool_to_onoff (arg, void) {
	switch ($arg) {
		(0) {return OFF}
		(1) {return ON}
		(*) {return $arg}
	}
}

alias bool_to_num (arg, void) {
	switch ($toupper($arg)) {
		(OFF) {return 0}
		(ON)  {return 1}
		(*)   {return $arg}
	}
}

alias country tld

/*
 * This function converts an integer representing an arbitrary number
 * of bytes into a more human readable form. It was taken from the
 * mail script that was recently added to the EPIC4 distribution and
 * placed in the public domain by its author, wd.
 */
alias fmtfsize (bytes, void) {
	^stack push set FLOATING_POINT_MATH
	^set FLOATING_POINT_MATH ON
	if (!bytes) {
		@ function_return = [0b]
	} else if (bytes < 1024) {
		@ function_return = [${bytes}b]
	} else if (bytes < 1048576) {
		@ function_return = [$trunc(2 ${bytes / 1024})kb]
	} else if (bytes < 1073741824) {
		@ function_return = [$trunc(2 ${bytes / 1048576})mb]
	} else if (bytes < 1099511627776) {
		@ function_return = [$trunc(2 ${bytes / 1073741824})gb]
	} else {
		@ function_return = [$trunc(2 ${bytes / 1099511627776})tb]
	}
	^stack pop set FLOATING_POINT_MATH
}

alias isloaded (module, void) {
	return ${finditem(loaded_modules $module) > -1 ? 1 : 0}
}
	
/*
 * Determines whether someone is currently online. It returns the
 * person's nick if they are online, or nothing if not.
 *
 * This was taken from the "guh" script distributed with EPIC.
 * It was written by Jeremy Nelson <jnelson@epicsol.org>.
 */
alias is_on (nick, void) {
	stack push on 303
	^on ^303 * {
		stack pop on 303
		return $0
	}
	wait for ison $nick
}

/*
 * $modinfo(<module> [a|f|v])
 * Easy interface to the module information.
 * Flags:    a - Returns filename and version.
 *           f - Returns only the filename.
 *           v - Returns only the version.
 * If no flag is specified then 'a' is assumed.
 */
alias modinfo (module, flag) {
	if ((:item = finditem(modules $module)) > -1) {
		switch ($tolower($flag)) {
			(a) () {
				^local foo $getitem(module_files $item)
				push foo $getitem(module_versions $item)
				return $foo
			}
			(f) { return $getitem(module_files $item); }
			(v) { return $getitem(module_versions $item); }
		}
	}
	return
}

/*
 * The original version of this function was taken from EPIC4-1.1.3 and
 * was written by Jeremy Nelson. It has been modified to use $rand() to
 * generate a unique process name, rather than a global variable that
 * is incremented every time the function is called. The original comment
 * follows. -Brian
 */
/*
 * Ok.  Here's the plan.
 *
 * $pipe(commands) will return the output from 'commands'.
 */
alias pipe {
	@ srand($time())
	@:desc = [pipe] ## rand(999999)
	^local retval
	^on ^exec "$desc *" {
		bless
		push retval $1-
	}
	^exec -name $desc $*
	^wait %$desc
	^on exec -"$desc *"
	return $retval
}
#hop '97

/*
 * Returns the refnums of all established server connections.
 */
alias serverrefs (void) {
	^local ret
	for winref in ($winrefs()) {
		^local sref $winserv($winref)
		if (!match($sref $retval)) {
			push ret $sref
		}
	}
	return $ret
}

alias tld {
	if ([$0]) {
		if (functioncall()) {
			@ function_return = TLD.$0 ? TLD.$0 : [unknown]
		} else {
			@ :name = TLD.$0 ? TLD.$0 : [unknown]
			xecho -b Top-level domain "$0" is "$name"
		}
	}
}

/*
 * Written by Jeremy Nelson in '93 and distributed
 * with EPIC4 in the guh script.
 *
 * Takes a white space separated list of nicks and returns
 * their userhosts. This differs from $userhost() in that it
 * queries the server rather than trying to pull the userhosts
 * from the client's cache.
 */
alias uh {
	^local blahblah
	wait for {
		^userhost $* -cmd {
			bless
			push blahblah $3@$4
		}
	}
	return $blahblah
}


/* EOF */