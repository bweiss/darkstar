/* $Id$ */
/*
 * set.dsc - Modular set routines for DarkStar/EPIC4
 * Copyright (c) 2002, 2003 Brian Weiss (except where noted)
 * See the 'COPYRIGHT' file for more information.
 */

alias addconfig {_addsetvar CONFIG $*}
alias addformat {_addsetvar FORMAT $*}

alias config dset
alias format fset

alias dset (...) {_set CONFIG $*}
alias fset (...) {_set FORMAT $*}

/*
 * These aliases are deprecated. The new addconfig and addformat aliases
 * should be used instead.
 */
alias config.add addconfig
alias format.add addformat

/*
 * This does the actual work involved in adding config and format
 * variables. It is an internal alias that should be called by the
 * addconfig and addformat aliases.
 *
 * Data about each variable will be stored in several assign structures.
 *
 *  <type>.<var>            = value for <var> (may be empty)
 *  <type2>.<var>           = name of parent module
 *  _MODULE.<module>.<type> = list of <type> vars belonging to <module>
 *
 * <module> is the name of the calling module or "core" if there isn't one
 * <type> can be either "CONFIG" or "FORMAT"
 * <type2> can be either "_DSET" or "_FSET"
 *
 * A list of config variables that are boolean will also be stored in the
 * _boolcfgvars array.
 */
alias _addsetvar (type, ...)
{
	switch ($toupper($type))
	{
		(CONFIG) { ^local struct _DSET; }
		(FORMAT) { ^local struct _FSET; }
		(*) {
			echo Error: _addsetvar: Invalid type: $type
			return
		}
	}

	^local file $after(-1 / $word(1 $loadinfo()))
	if (file =~ [*.dsm]) {
		^local mod $before(-1 . $file)
	} else {
		^local mod core
	}

	if (![$0]) {
		echo Error: _addsetvar: Not enough arguments \(module: $mod\)
		return
	}

	if (match(CONFIG $type) && match($0 -b -bool -boolean))
	{
		^local variable $1
		^local value $2-
		@ setitem(_boolcfgvars $numitems(_boolcfgvars) $variable)
	}{
		^local variable $0
		^local value $1-
	}

	if (struct[$variable])
	{
		echo Error: _addsetvar: Duplicate $tolower($type) variable: $variable \(module: $mod\)
	}{
		@ push(_MODULE.$mod\.$type $variable)
		^assign $struct\.$variable $mod
		^assign $type\.$variable $value
	}
}

/*
 * This handles the display and modification of both config
 * and format variables.
 */
alias _set (type, variable, value)
{
	switch ($type)
	{
		(CONFIG) { ^local struct _DSET; }
		(FORMAT) { ^local struct _FSET; }
		(*) {
			echo Error: _set: Unknown type: $type
			return
		}
	}

	if (!variable)
	{
		for realvar in ($aliasctl(assign match $struct\.)) {
			_setcat $type\.$after(1 . $realvar)
		}
	}{
		^local var $strip(- $variable)
		^local bingo ${aliasctl(assign get $struct\.$var) ? 1 : 0}
		^local matches $aliasctl(assign match $struct\.$var)

		if (#matches > 1 && !bingo)
		{
			xecho -s $fparse(SET_AMBIGUOUS $toupper($var))
			for tmp in ($matches) {
				_setcat $type\.$after(1 . $tmp)
			}
		}\
		else if (bingo || #matches == 1)
		{
			^local var $after(1 . $word(0 $matches))
			^local realvar $type\.$var
			^local old_value $aliasctl(assign get $realvar)

			if (variable =~ [-%])
			{
				^assign -$realvar
				xecho -s $fparse(SET_CHANGE $toupper($var) <EMPTY>)
				/* Hook the changes so modules can act on it. */
				hook $type $var $old_value
			}\
			else if (value == [])
			{
				_setcat $realvar
			}\
			else
			{
				if (type == [CONFIG] && finditem(_boolcfgvars $var) > -1)
				{
					switch ($toupper($value))
					{
						(0) (1) (OFF) (ON) {
							^assign $realvar $bool2num($value)
							xecho -s $fparse(SET_CHANGE $toupper($var) $toupper($bool2word($value)))
						}
						(*) {
							xecho -b -s Value must be either ON, OFF, 1, or 0
						}
					}
				}{
					^assign $realvar $value
					xecho -s $fparse(SET_CHANGE $toupper($var) $value)
				}
				hook $type $var $old_value
			}
		}{
			xecho -b -s No matches for \"$toupper($var)\" found
		}
	}
}

/*
 * This is a modified version of shade's setcat. It handles the actual
 * displaying of config/format variables and their values. It should
 * be called by the _set alias.
 */
alias _setcat (realvar, void)
{
	@ :var = after(1 . $realvar)
	if ($realvar == [])
	{
		if (FORMAT.SET_NOVALUE) {
			xecho -s $fparse(SET_NOVALUE $toupper($var))
		}
	}{
		if (FORMAT.SET) {
			if (before(. $realvar) == [CONFIG] && finditem(_boolcfgvars $var) > -1) {
				xecho -s $fparse(SET $toupper($var) $toupper($bool2word($($realvar))))
			} else {
				xecho -s $fparse(SET $toupper($var) $($realvar))
			}
		}
	}
}


addformat SET $G Current value of $1 is $2-
addformat SET_AMBIGUOUS $G "$1" is ambiguous
addformat SET_CHANGE $G Value of $1 set to $2-
addformat SET_FOOTER
addformat SET_HEADER
addformat SET_NOVALUE $G No value for $1 has been set


