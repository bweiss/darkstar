/* $Id$ */
/*
 * config.dsc - Configuration interface
 * Copyright (c) 2002 Brian Weiss (except where noted)
 * See the 'COPYRIGHT' file for more information.
 */

/****** USER ALIASES ******/

alias config dset
alias dset (...) {config.set_routine CONFIG $*}
alias fset (...) {config.set_routine FORMAT $*}


/****** FUNCTIONS ******/

alias fparse  {eval return $cparse($(FORMAT.$0))}
alias fparse2 {eval return $(FORMAT.$0)}


/****** MODULE ALIASES ******/

/*
 * These aliases add config and format variables into the system.
 * They should only be called by modules at load time.
 *
 * The variable is "owned" by the calling module and will be automatically
 * removed when the module is unloaded.
 */
alias config.add {config.add_variable CONFIG $*}
alias format.add {config.add_variable FORMAT $*}


/****** INTERNAL ALIASES ******/

/*
 * This handles the display and modification of both config and format
 * variables. It is the biggest and most complex part of this script.
 */
alias config.set_routine (type, variable, value) {
	switch ($toupper($type)) {
		(CONFIG) { ^local struct DSET; }
		(FORMAT) { ^local struct FSET; }
		(*) {
			echo Error: config.set_routine: Unknown type: $type
			return
		}
	}
	if (!variable) {
		/* No variable specified by user so we display everything */
		for var in ($aliasctl(assign match $struct\.$type\.)) {
			^local var $after(1 . $var)
			config.setcat $var
		}
	} else {
		^local var $strip(- $variable)
		^local active $aliasctl(assign get $struct\.$type\.$var)
		^local matches $aliasctl(assign match $struct\.$type\.$var)
		/*
		 * If the number of matches found is greater than 1, output the
		 * values for all matching variables. If only 1 match is found,
		 * we then have to figure out exactly what to do with that variable.
		 */
		if (#matches > 1 && !active) {
			xecho -s -b \"$toupper($var)\" is ambiguous
			for var in ($matches) {
				^local var $after(1 . $var)
				config.setcat $var
			}
		} else if (#matches == 1 || active) {
			^local var $after(1 . $word(0 $matches))
			^local var2 $after(1 . $var)
			^local old_value $aliasctl(assign get $var)
			/*
			 * If variable name is preceded by a "-" empty its value.
			 * Otherwise, if a new value is supplied by the user, set
			 * this to the variable's new value and we're done. 
			 * If no new value is specified, output the variable's
			 * current value.
			 */
			if (variable =~ [-%]) {
				^assign -$var
				xecho -s -b Value of $toupper($var2) set to <EMPTY>
				/* Hook the changes so modules can act on it. */
				if (type == [CONFIG]) {
					hook CONFIG $var2 $old_value
				}
			} else if (value != []) {
				if (type == [CONFIG] && DSET[BOOL][$var2]) {
					switch ($toupper($value)) {
						(0) (1) (OFF) (ON) {
							^assign $var $bool_to_num($value)
							xecho -s -b Value of $toupper($var2) set to $toupper($bool_to_onoff($value))
						}
						(*) { xecho -s -b Value must be either ON, OFF, 1, or 0; }
					}
				} else {
					^assign $var $value
					xecho -s -b Value of $toupper($var2) set to $value
				}
				if (type == [CONFIG]) {
					hook CONFIG $var2 $old_value
				}
			} else {
				/* No new value specified. Display current value. */
				config.setcat $var
			}
		} else {
			xecho -s -b No matches for \"$toupper($var)\" found
		}
	}
}

/*
 * This is a modified version of shade's setcat. It handles the actual
 * displaying of config/format variables and their values. It should
 * be called by the config.set_routine alias.
 */
alias config.setcat (var, void) {
	^local var2 $after(1 . $var)
	eval if \($var != []\) {
		if (FORMAT.SET) {
			if (before(. $var) == [CONFIG] && DSET[BOOL][$var2]) {
				xecho -s $fparse(SET $toupper($var2) $toupper($bool_to_onoff($($var))))
			} else {
				xecho -s $fparse(SET $toupper($var2) $($var))
			}
		}
	} else {
		if (FORMAT.SET_NOVALUE) {
			xecho -s $fparse(SET_NOVALUE $toupper($var2))
		}
	}
}

/*
 * This does the actual work involved in adding config and format
 * variables. It is an internal alias that should be called by the
 * config.add and format.add aliases.
 */
alias config.add_variable (type, ...) {
	switch ($toupper($type)) {
		(CONFIG) { ^local struct DSET; }
		(FORMAT) { ^local struct FSET; }
		(*) {
			echo Error: config.add_variable: Invalid type: $type
			return
		}
	}
	^local foo $word(1 $loadinfo())
	if (match(*config.dsc $foo)) {
		^local module core
	} else {
		^local module $after(-1 / $before(-1 . $foo))
	}
	if (!module) {
		echo Error: $type\.ADD must be called at load time
		return
	}
	if (![$0]) {
		echo Error: $type\.ADD: Not enough arguments \(Module: $module\)
		return
	}
	if (match(CONFIG $type) && pattern($0* -boolean)) {
		^local variable $1
		^local value $2-
		^assign $struct\.BOOL.$variable 1
	} else {
		^local variable $0
		^local value $1-
	}
	if (aliasctl(assign match $struct\.$type\.$variable)) {
		echo Error: $type\.ADD: Duplicate $tolower($type) variable: $variable \(Module: $module\)
	} else {
		push $struct\.MODULES.$module $variable
		^assign $struct\.$type\.$variable 1
		^assign $type\.$variable $value
	}
}


/****** STARTUP ******/

/*
 * Add all the config and format variables that are part of the core.
 */
config.add -b AUTO_LOAD_DEPENDENCIES 1
config.add    AUTO_LOAD_MODULES away channel dcc misc names nickmgr nickcomp relay tabkey window
config.add -b AUTO_LOAD_PROMPT 1
config.add -b AUTO_SAVE_ON_UNLOAD 0
config.add -b LOADMODULE_VERBOSE 0
config.add -b SAVE_VERBOSE 0
config.add    THEME epic4

format.add MODLIST_FOOTER -------------------------------------------------------
format.add MODLIST_FOOTER1 $G Available modules: $numitems(modules), Loaded modules: $numitems(loaded_modules)
format.add MODLIST_FOOTER2
format.add MODLIST_HEADER #   Module           Version    Size  Loaded Auto-Load
format.add MODLIST_HEADER1 -------------------------------------------------------
format.add MODLIST_HEADER2
format.add MODLIST_MODULE  $[3]1 $[16]2 $[7]3 $[-7]4    ${[$5] ? [\[*\]] : [\[\ \]]}     ${[$6] ? [\[*\]] : [\[ \]]}
format.add SET $G Current value of $1 is $2-
format.add SET_NOVALUE $G No value for $1 has been set



/* EOF */