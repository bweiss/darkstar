/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * FUNCTIONS.DSC - Some useful functions for Darkstar/EPIC4
 * Author: Brian Weiss <brian@got.net> - 2001
 *
 * If you have any functions you feel are useful enough to be in this file,
 * feel free to email me.
 */

alias getstrftime (time, void)
{
	@ function_return = strftime($FORMAT.STRFTIME)
}

/*
 * Taken from the "guh" script distributed with EPIC4.
 * Written by Jeremy Nelson.
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

alias padleft (size, char, text)
{
	@ function_return = repeat(${size - strlen($text)} $char) ## text
}

alias padright (size, char, text)
{
	@ function_return = text ## repeat(${size - strlen($text)} $char)
}


/* bmw '01 */