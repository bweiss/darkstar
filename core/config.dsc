/* $Id$ */
/*
 * config.dsc - Configuration interface
 * Copyright (c) 2002 Brian Weiss (except where noted)
 * See the 'COPYRIGHT' file for more information.
 */

/****** USER ALIASES ******/

alias config dset
alias dset (...) {config.set_routine dset $*}
alias fset (...) {config.set_routine fset $*}


/****** FUNCTIONS ******/

alias fparse  {eval return $cparse($(FORMAT.$0))}
alias fparse2 {eval return $(FORMAT.$0)}


/****** MODULE ALIASES ******/

/*
 * These aliases add config and format variables into the system.
 * They should only be called by modules at load time.
 *
 * The variable is "owned" by the calling module and will be automatically
 * removed when the module is unloaded. This ownership is transparent to
 * the user except that the variable(s) are removed with their module.
 */
alias config.add {config.add_variable config $*}
alias format.add {config.add_variable format $*}


/****** INTERNAL ALIASES ******/

/*
 * This handles the display and modification of both config and format
 * variables. It is the biggest and most complex part of this script.
 */
alias config.set_routine (type, variable, value)
{
	^local struct1,struct2
	
	/*
	 * Figure out what kind of variables we're dealing with.
	 */
	switch ($toupper($type))
	{
		(DSET) {
			^assign struct1 DSET
			^assign struct2 CONFIG
		}
		(FSET) {
			^assign struct1 FSET
			^assign struct2 FORMAT
		}
	}
	
	if (!variable)
	{
		/*
		 * No variable specified by user so we display everything.
		 */
		for var in ($aliasctl(assign match $struct1\.$struct2\.)) {
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
			for var in ($matches) {
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
				if (toupper($type) == [DSET]) {
					hook CONFIG $var2 $old_value
				}
			}\
			else if (value != [])
			{
				if (struct2 == [CONFIG] && DSET[BOOL][$var2])
				{
					switch ($tolower($value)) {
						(0) (1) (off) (on) {
							^assign $var $bool_to_num($value)
							xecho -s -b Value of $toupper($var2) set to $toupper($bool_to_onoff($value))
						}
						(*) {
							xecho -s -b Value must be either ON, OFF, 1, or 0
						}
					}
				}{
					^assign $var $value
					xecho -s -b Value of $toupper($var2) set to $value
				}

				/* Hook the changes so modules can act on it. */
				if (toupper($type) == [DSET]) {
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
}

/*
 * This is a modified version of shade's setcat. It handles the actual
 * displaying of config/format variables and their values. It should
 * be called by config.set_routine.
 */
alias config.setcat (var, void)
{
	@ :var2 = after(1 . $var)
	eval if \($var != []\)
	{
		if (FORMAT.SET) {
			if (before(. $var) == [CONFIG] && DSET[BOOL][$var2]) {
				xecho -s $fparse(SET $toupper($var2) $toupper($bool_to_onoff($($var))))
			} else {
				xecho -s $fparse(SET $toupper($var2) $($var))
			}
		}
	}{
		if (FORMAT.SET_NOVALUE) {
			xecho -s $fparse(SET_NOVALUE $toupper($var2))
		}
	}

	return
}

/*
 * This does the actual work involved in adding config and format
 * variables. It is an internal alias that should be called by the
 * config.add and format.add aliases.
 */
alias config.add_variable (type, ...)
{
	/* Determine which *SET structure we're using. */
	switch ($type)
	{
		(config) { @:struct = [DSET] }
		(format) { @:struct = [FSET] }
	}

	/* Determine which module is currently loading. */
	@:tmp = word(1 $loadinfo())
	if (match(*darkstar.irc $tmp)) {
		@:module = [core]
	} else {
		@:module = after(-1 / $before(-1 . $tmp))
	}

	if (!module) {
		xecho -b Error: $type\.add must be called at load time
		return
	}

	if (![$0]) {
		xecho -b Error: $type\.add: Not enough arguments \(Module: $module\)
		return
	}

	if (type == [config] && pattern($0* -boolean)) {
		^local variable $1
		^local value $2-
		^assign $struct\.BOOL.$variable 1
	} else {
		^local variable $0
		^local value $1-
	}

	if (DSET[$type][$variable]) {
		xecho -b Error: $type\.add: Duplicate config variable: $variable \(Module: $module\)
	} else {
		push $struct\.MODULES.$module $variable
		^assign $struct\.$type\.$variable 1
		^assign $type\.$variable $value
	}
}


/* EOF */