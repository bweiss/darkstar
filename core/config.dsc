/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * CONFIG.DSC - Configuration manager for Darkstar/EPIC4
 * Author: Brian Weiss <brian@epicsol.org> - 2001
 *
 * Last modified: 8/27/01 (bmw)
 */

alias conf dset

alias config dset

alias set_routine (type, variable, value)
{
	^local struct1,struct2
	
	/* Figure out what kind of variables we're dealing with */
	switch ($toupper($type))
	{
		(DSET)
		{
			^assign struct1 DSET
			^assign struct2 CONFIG
		}
		(FSET)
		{
			^assign struct1 FSET
			^assign struct2 FORMAT
		}
	}
	
	if (!variable)
	{
		/* No variable specified by user. Display all. */
		for var in ($aliasctl(assign match $struct1\.$struct2\.))
		{
			@ :var = after(1 . $var)
			@ setcat($var)
		}
	}{
		@ :var = strip(- $variable)
		@ :cur_value = aliasctl(assign get $struct1\.$struct2\.$var)
		@ :matches = aliasctl(assign match $struct1\.$struct2\.$var)
		
            /*
             * If the number of matches found is greater than 1, output the
             * values for all matching variables. If only 1 match is found,
             * we then have to figure out exactly what to do with that varable.
             */
		if (#matches > 1 && !cur_value)
		{
			xecho -b \"$toupper($var)\" is ambiguous
			for var in ($matches)
			{
				@ :var = after(1 . $var)
				@ setcat($var)
			}
		} \
		elsif (#matches == 1 || cur_value)
		{
			@ :var = after(1 . $word(0 $matches))
			@ :var2 = after(1 . $var)
			
			/*
			 * If variable name is preceded by a "-" empty its value.
			 * Otherwise, if a new value is supplied by the user, set
			 * this to the variables new value and we're done. 
			 * If no new value is specified, output the variable's
			 * current value.
			 */
			if (variable =~ [-%])
			{
				^assign -$var
				xecho -s -b Value of $toupper($var2) set to <EMPTY>
			} \
			elsif (value != [])
			{
				if (struct2 == [CONFIG] && aliasctl(assign get DSET.BOOL.$var2))
				{
					^assign $var $convert.onoff($value)
					xecho -s -b Value of $toupper($var2) set to $toupper($convert.num($value))
				}{
					^assign $var $value
					xecho -s -b Value of $toupper($var2) set to $value
				}
			} \
			elsif (value == [])
			{
				@ setcat($var)
			}
		}{
			xecho -b No matches for \"$toupper($var)\" found
		}
	}

	return
}

alias dset (...)
{
	@ set_routine(dset $*)
}

alias fset (...)
{
	@ set_routine(fset $*)
}

alias fparse
{
	eval return $cparse($(FORMAT.$0))
}

/*
 * This is a modified version of shade's setcat.
 */
alias setcat (var, void)
{
	@ :var2 = after(1 . $var)
	
	eval if \($var != []\)
	{
		if (before(. $var) == [CONFIG] && aliasctl(assign get DSET.BOOL.$var2))
		{
			xecho -b $fparse(SET $toupper($var2) $toupper($convert.num($($var))))
		}{
			xecho -b $fparse(SET $toupper($var2) $($var))
		}
	}{
		xecho -b $fparse(SET_NOVALUE $toupper($var2))
	}
	
	return
}


/* bmw '01 */