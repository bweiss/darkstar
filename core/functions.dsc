/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * FUNCTIONS.DSC - Some useful functions for Darkstar/EPIC4
 * Author: Brian Weiss <brian@epicsol.org> - 2001
 *
 * Last modified: 1/15/02 (bmw)
 *
 * If you have any functions you feel are useful enough to be in this file,
 * feel free to email me.
 */

/*
 * convert.num(0|1)
 * convert.onoff(off|on)
 * Convert between 0/1 and OFF/ON. These are mostly used by /dset.
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
 * isloaded(module)
 * Returns true if specified module is loaded. I mostly added this for the
 * convenience of module writers.
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
 * is_on(nick)
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
 * padleft(size, char, text string)
 * Works like $pad() except that it pads on the left side.
 */
alias padleft (size, char, text)
{
	@ function_return = repeat(${size - strlen($text)} $char) ## text
}

/*
 * round(num)
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


/* bmw '01 */