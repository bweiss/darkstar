#
# $Id$ */
# set.dsc - Modular SET routines for DarkStar/EPIC4
# Copyright (c) 2002-2005 Brian Weiss
# See the 'COPYRIGHT' file for more information.
#

alias addconfig (...) {_addsetvar CONFIG $*};
alias addformat (...) {_addsetvar FORMAT $*};

alias config (...) {dset $*};
alias format (...) {fset $*};

alias dset (...) {_set CONFIG $*};
alias fset (...) {_set FORMAT $*};

# These aliases are deprecated. The new addconfig and addformat aliases
# should be used instead.
alias config.add (...) {addconfig $*};
alias format.add (...) {addformat $*};

#
# This does the actual work involved in adding config and format
# variables. It is an internal alias that should be called by the
# addconfig and addformat aliases.
#
# Data about each variable will be stored in several assign structures.
#
# <type>.<var>    = value for <var> (may be empty)
# <struct>.<var>  = <parentmod> <boolean>
#
# <type> can be either "CONFIG" or "FORMAT"
# <struct> can be either "_DSET" or "_FSET"
#
# The <boolean> flag is set for any config vars that were added
# with the -boolean option.
#
# The names of variables belonging to each module will also be stored
# in arrays named <struct>.<module> (e.g. _DSET.CHANNEL)
#
alias _addsetvar (type, ...)
{
	switch ($toupper($type))
	{
		(CONFIG) {^local struct _DSET}
		(FORMAT) {^local struct _FSET}
		(*) {
			echo Error: _addsetvar: Invalid type: $type;
			return;
		}
	};

	^local file $after(-1 / $word(1 $loadinfo()));
	if (file =~ [*.dsm]) {
		^local mod $before(-1 . $file);
	} else {
		^local mod core;
	};

	if (![$0]) {
		echo Error: _addsetvar: Not enough arguments \(module: $mod\);
		return;
	};

	if (match(CONFIG $type) && match($0 -b -bool -boolean))
	{
		^local variable $1;
		^local value $2-;
		^local bool 1;
	}{
		^local variable $0;
		^local value $1-;
	};

	if (struct[$variable])
	{
		echo Error: _addsetvar: Duplicate $tolower($type) variable: $variable \(module: $mod\);
	}{
		^assign $struct\.$variable $mod $bool;
		^assign $type\.$variable $value;
		@ setitem($struct\.$mod $numitems($struct\.$mod) $variable);
	};
};

#
# This attempts to mimic the builtin SET command. It allows the user
# to display and modify variables created with the addconfig/addformat
# aliases.
#
alias _set (type, variable, value)
{
	switch ($type)
	{
		(CONFIG) {^local struct _DSET}
		(FORMAT) {^local struct _FSET}
		(*) {
			echo Error: _set: Unknown type: $type;
			return;
		}
	};

	if (!variable)
	{
		if (FORMAT.SET_HEADER) {xecho -s $fparse(SET_HEADER ${type == [CONFIG] ? #getdsets() : #getfsets()})};
		for realvar in ($aliasctl(assign match $struct\.)) {
			_showset $type\.$after(1 . $realvar);
		};
		if (FORMAT.SET_FOOTER) {xecho -s $fparse(SET_FOOTER ${type == [CONFIG] ? #getdsets() : #getfsets()})};
	}{
		@ :var     = strip(- $variable);
		@ :bingo   = aliasctl(assign get $struct\.$var) ? 1 : 0;
		@ :bool    = word(1 $aliasctl(assign get $struct\.$var));
		@ :matches = aliasctl(assign match $struct\.$var);

		if (#matches > 1 && !bingo)
		{
			if (FORMAT.SET_HEADER)    {xecho -s $fparse(SET_HEADER ${type == [CONFIG] ? #getdsets($var*) : #getfsets($var*)})};
			if (FORMAT.SET_AMBIGUOUS) {xecho -s $fparse(SET_AMBIGUOUS $toupper($var))};
			for tmp in ($matches) {
				_showset $type\.$after(1 . $tmp);
			};
			if (FORMAT.SET_FOOTER)    {xecho -s $fparse(SET_FOOTER ${type == [CONFIG] ? #getdsets($var*) : #getfsets($var*)})};
		}
		else if (bingo || #matches == 1)
		{
			@ :var     = after(1 . $word(0 $matches));
			@ :realvar = [$type\.$var];
			@ :oldval  = aliasctl(assign get $realvar);

			if (variable =~ [-%])
			{
				^assign -$realvar;
				xecho -s $fparse(SET_CHANGE $toupper($var) <EMPTY>);
				# Hook the changes so modules can act on it.
				hook $type $var $oldval;
			}
			else if (value == [])
			{
				if (FORMAT.SET_HEADER) {xecho -s $fparse(SET_HEADER 1 $var)};
				_showset $realvar;
				if (FORMAT.SET_FOOTER) {xecho -s $fparse(SET_FOOTER 1 $var)};
			}
			else
			{
				if (bool)
				{
					switch ($toupper($value))
					{
						(0) (1) (OFF) (ON) {
							^assign $realvar $bool2num($value);
							xecho -s $fparse(SET_CHANGE $toupper($var) $toupper($bool2word($value)));
						}
						(*) {
							xecho -b -s Value must be either ON, OFF, 1, or 0;
						}
					};
				}{
					^assign $realvar $value;
					xecho -s $fparse(SET_CHANGE $toupper($var) $value);
				};
				hook $type $var $oldval;
			};
		}{
			xecho -b -s No matches for \"$toupper($var)\" found;
		};
	};
};

#
# This handles the displaying of config/format variables and their values.
# It should be called by the _set alias.
#
alias _showset (realvar, void)
{
	@ :var = after(1 . $realvar);

	switch ($realvar)
	{
		(CONFIG.*) {^local struct _DSET};
		(FORMAT.*) {^local struct _FSET};
	};

	# The '$' prefix here is intentional; it forces double expansion.
	if ($realvar == [])
	{
		if (FORMAT.SET_NOVALUE) {
			xecho -s $fparse(SET_NOVALUE $toupper($var));
		};
	}{
		if (FORMAT.SET)
		{
			if (word(1 $aliasctl(assign get $struct\.$var))) {
				xecho -s $fparse(SET $toupper($var) $toupper($bool2word($($realvar))));
			} else {
				xecho -s $fparse(SET $toupper($var) $($realvar));
			};
		};
	};
};


addformat SET $$G Current value of $$1 is $$2-;
addformat SET_AMBIGUOUS $$G "$$1" is ambiguous;
addformat SET_CHANGE $$G Value of $$1 set to $$2-;
addformat SET_FOOTER;
addformat SET_HEADER;
addformat SET_NOVALUE $$G No value for $$1 has been set;

