/* $Id$ */
/*
 * functions.dsc - Miscellaneous functions
 *
 * Written by Brian Weiss
 * Copyright (c) 2002 Brian Weiss
 * See the 'COPYRIGHT' file for more information.
 */


/*
 * convert.num(0|1)
 * convert.onoff(off|on)
 * Convert between 0/1 and OFF/ON. These are mostly used by /DSET.
 * I would like to rename these to something better, so if anyone has
 * ideas, please email me.
 */ 
alias convert.num (arg, void)
{
	switch ($arg)
	{
		(0) {return off}
		(1) {return on}
		(*) {return $arg}
	}
}

alias convert.onoff (arg, void)
{
	switch ($tolower($arg))
	{
		(off) {return 0}
		(on) {return 1}
		(*) {return $arg}
	}
}

/*
 * Returns true if specified module is loaded.
 */
alias isloaded (module, void)
{
	if (finditem(loaded_modules $module) > -1)
	{
		return 1
	}{
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
	^on ^303 *
	{
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
	@ :item = finditem(modules $module)
	if (item > -1)
	{
		switch ($tolower($flag))
		{
			(a) ()
			{
				@ :retval = getitem(module_files $item)
				@ push(retval $getitem(module_version $item))
				@ function_return = retval
			}
			(f) { @ function_return = getitem(module_files $item) }
			(v) { @ function_return = getitem(module_version $item) }
		}
	}

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
	@ :desc = [pipe] ## rand(999999)
	^local retval

	^on ^exec "$desc *"
	{
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
 * Rounds a decimal number based on the first digit to the right of the
 * decimal point.
 */
alias round (num, void)
{
	@ :left = before(-1 . $num)
	@ :right = left(1 $after(-1 . $num))

	if (isnumber($left b10) && isnumber($right b10))
	{
		if (right > 4)
		{
			@ left++
		}

		@ function_return = left
	}

	return
}


/* EOF */