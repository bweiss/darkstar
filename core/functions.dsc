/* $Id$ */
/*
 * functions.dsc - Miscellaneous functions
 *
 * Written by Brian Weiss (except where noted)
 * Copyright (c) 2002 Brian Weiss
 * See the 'COPYRIGHT' file for more information.
 */

/*
 * Works just like the builtin $cparse() but outputs ANSI color
 * codes instead of ^C color codes. This was written by Ben Winslow.
 */
alias ansicparse
{
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
 * convert.num(0|1)
 * convert.onoff(off|on)
 * Convert between 0/1 and OFF/ON. These are mostly used by /DSET.
 * I would like to rename these to something better, so if anyone has
 * ideas, please email me.
 */ 
alias convert.num (arg, void)
{
	switch ($arg) {
		(0) {return off}
		(1) {return on}
		(*) {return $arg}
	}
}

alias convert.onoff (arg, void)
{
	switch ($tolower($arg)) {
		(off) {return 0}
		(on)  {return 1}
		(*)   {return $arg}
	}
}

/*
 * Returns true if specified module is loaded.
 */
alias isloaded (module, void)
{
	if (finditem(loaded_modules $module) > -1) {
		return 1
	} else {
		return 0
	}
}
	
/*
 * Taken from the "guh" script written by Jeremy Nelson and distributed
 * with EPIC. Returns the person's nick if they are online, or nothing if not.
 */
alias is_on (nick, void)
{
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
alias modinfo (module, flag)
{
	@:item = finditem(modules $module)
	if (item > -1) {
		switch ($tolower($flag)) {
			(a) () {
				@:retval = getitem(module_files $item)
				push retval $getitem(module_versions $item)
				@ function_return = retval
			}
			(f) { @ function_return = getitem(module_files $item) }
			(v) { @ function_return = getitem(module_versions $item) }
		}
	}

	/* Module not found. Return nothing. */
	return
}

/*
 * Works like $pad() except that it pads on the left side.
 */
alias padleft (size, char, text)
{
	@ function_return = repeat(${size - strlen($text)} $char) ## text
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
alias pipe
{
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
alias serverrefs (void)
{
	^local retval
	for winref in ($winrefs()) {
		@:sref = winserv($winref)
		if (!match($sref $retval)) {
			push retval $sref
		}
	}

	@ function_return = retval
}


/* EOF */