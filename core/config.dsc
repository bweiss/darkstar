/* $Id$ */
/*
 * config.dsc - Configuration interface
 *
 * Written by Brian Weiss
 * Copyright © 2002 Brian Weiss
 * See the 'COPYRIGHT' file for more information.
 */


alias conf dset
alias config dset

alias dset (...)
{
	@ config.set_routine(dset $*)
}

alias fset (...)
{
	@ config.set_routine(fset $*)
}


alias fparse
{
	eval return $cparse($(FORMAT.$0))
}

alias fparse2
{
	eval return $(FORMAT.$0)
}


alias config.set_routine (type, variable, value)
{
	^local struct1,struct2
	
	/* Figure out what kind of variables we're dealing with. */
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
		/* No variable specified by user so display all. */
		for var in ($aliasctl(assign match $struct1\.$struct2\.))
		{
			@ :var = after(1 . $var)
			@ config.setcat($var)
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
			xecho -s -b \"$toupper($var)\" is ambiguous
			for var in ($matches)
			{
				@ :var = after(1 . $var)
				@ config.setcat($var)
			}
		}\
		else if (#matches == 1 || cur_value)
		{
			@ :var = after(1 . $word(0 $matches))
			@ :var2 = after(1 . $var)
			@ :old_value = aliasctl(assign get $var)

			/*
			 * If variable name is preceded by a "-" empty its value.
			 * Otherwise, if a new value is supplied by the user, set
			 * this to the variable's new value and we're done. 
			 * If no new value is specified, output the variable's
			 * current value.
			 */
			if (variable =~ [-%])
			{
				^assign -$var
				xecho -s -b Value of $toupper($var2) set to <EMPTY>

				/* Hook the changes so modules can act on it. */
				if (toupper($type) == [DSET])
				{
					hook CONFIG $var2 $old_value
				}
			}\
			else if (value != [])
			{
				if (struct2 == [CONFIG] && DSET[BOOL][$var2])
				{
					switch ($tolower($value))
					{
						(0) (1) (off) (on)
						{
							^assign $var $convert.onoff($value)
							xecho -s -b Value of $toupper($var2) set to $toupper($convert.num($value))
						}
						(*) {xecho -s -b Value must be either ON, OFF, 1, or 0}
					}
				}{
					^assign $var $value
					xecho -s -b Value of $toupper($var2) set to $value
				}

				/* Hook the changes so modules can act on it. */
				if (toupper($type) == [DSET])
				{
					hook CONFIG $var2 $old_value
				}
			}{
				/* No new value specified. Display current value. */
				@ config.setcat($var)
			}
		}{
			xecho -s -b No matches for \"$toupper($var)\" found
		}
	}

	return
}

/*
 * This is a modified version of shade's setcat.
 */
alias config.setcat (var, void)
{
	@ :var2 = after(1 . $var)
	eval if \($var != []\)
	{
		if (FORMAT[SET])
		{
			if (before(. $var) == [CONFIG] && DSET[BOOL][$var2])
			{
				xecho -s $fparse(SET $toupper($var2) $toupper($convert.num($($var))))
			}{
				xecho -s $fparse(SET $toupper($var2) $($var))
			}
		}
	}{
		if (FORMAT[SET_NOVALUE])
		{
			xecho -s $fparse(SET_NOVALUE $toupper($var2))
		}
	}

	return
}


/*
 * CONFIG.ADD [-boolean] <variable> [value]
 * Adds a config variable. This should be called by modules at load time.
 */
alias config.add
{
	^local variable,value
	@ :module = after(-1 / $before(-1 . $word(1 $loadinfo())))

	if (!module)
	{
		xecho -b Error: config.add: must be called at load time
		return
	}

	if (![$0])
	{
		xecho -b Error: config.add: Not enough arguments \(Module: $module\)
		return
	}

	if (pattern($0* -boolean))
	{
		^assign variable $1
		^assign value $2-
		^assign DSET.BOOL.$variable 1
	}{
		^assign variable $0
		^assign value $1-
	}

	if (DSET[CONFIG][$variable])
	{
		xecho -b Error: config.add: Duplicate config variable: $variable \(Module: $module\)
	}{
		@ push(DSET.MODULES.$module $variable)
		^assign DSET.CONFIG.$variable 1
		^assign CONFIG.$variable $value
	}
}

/*
 * FORMAT.ADD <variable> [value]
 * Addes a format variable.
 */
alias format.add (variable, value)
{
	@ :module = after(-1 / $before(-1 . $word(1 $loadinfo())))

	if (!module)
	{
		xecho -b Error: format.add: This command must be called at load time
		return
	}

	if (!variable)
	{
		xecho -b Error: format.add: Not enough arguments \(Module: $module\)
		return
	}

	if (FSET[FORMAT][$variable])
	{
		xecho -b Error: format.add: Duplicate format variable: $variable \(Module: $module\)
	}{
		@ push(FSET.MODULES.$module $variable)
		^assign FSET.FORMAT.$variable 1
		^assign FORMAT.$variable $value
	}
}


/* EOF */