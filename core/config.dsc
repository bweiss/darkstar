/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * CONFIG.DSC - Configuration manager for Darkstar/EPIC4
 * Author: Brian Weiss <brian@epicsol.org> - 2001
 */

alias conf dset

alias config dset

alias set_routine (type, variable, value)
{
	^local struct1,struct2
	
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
		for var in ($aliasctl(assign match $struct1\.$struct2\.))
		{
			@ :var = after(1 . $var)
			@ setcat($var)
		}
	}{
		@ :var = strip(- $variable)
		@ :cur_value = aliasctl(assign get $struct1\.$struct2\.$var)
		@ :matches = aliasctl(assign match $struct1\.$struct2\.$var)
		
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
			
			if (variable =~ [-%])
			{
				^assign -$var
				xecho -s -b Value of $toupper($var2) set to <EMPTY>
			} \
			elsif (value != [])
			{
				if (struct2 == [CONFIG] && aliasctl(assign get DSET.LIT.$var2))
				{
					^assign $var $value
					xecho -s -b Value of $toupper($var2) set to $value
				}{
					^assign $var $booltonum($value)
					xecho -s -b Value of $toupper($var2) set to $toupper($numtobool($value))
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

/* Functions */

alias fparse
{
	eval return $cparse($(FORMAT.$0))
}

alias setcat (var, void)
{
	@ :var2 = after(1 . $var)
	
	eval if \($var != []\)
	{
		if (before(. $var) == [CONFIG] && aliasctl(assign get DSET.LIT.$var2))
		{
			xecho -b $fparse(SET $toupper($var2) $($var))
		}{
			xecho -b $fparse(SET $toupper($var2) $toupper($numtobool($($var))))
		}
	}{
		xecho -b $fparse(SET_NOVALUE $toupper($var2))
	}
	
	return
}


/* bmw '01 */