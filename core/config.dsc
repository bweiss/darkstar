/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * CONFIG.DSC - Configuration manager for Darkstar/EPIC4
 * Author: Brian Weiss <brian@got.net> - 2001
 */

alias conf dset

alias config dset

alias do_set (type, variable, value)
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
		@ :fsets = aliasctl(assign match $struct1\.$struct2\.)

		for var in ($fsets)
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
				^assign $var $value
				xecho -s -b Value of $toupper($var2) set to $value
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
	@ do_set(dset $*)
}

alias fset (...)
{
	@ do_set(fset $*)
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
		xecho -b $fparse(SET $toupper($var2) $($var))
	}{
		xecho -b $fparse(SET_NOVALUE $toupper($var2))
	}
	
	return
}


/* bmw '01 */