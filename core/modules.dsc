/* $Id$ */
/*
 * modules.dsc - DarkStar module management system
 * Copyright (c) 2002, 2003 Brian Weiss
 * See the 'COPYRIGHT' file for more information.
 */

/****** CONFIG/FORMAT VARIABLES ******/

addconfig    AUTO_LOAD_MODULES away channel dcc formats misc nickmgr nickcomp tabkey theme window
addconfig -b SAVE_ON_UNLOAD 0
addconfig -b LOAD_PROMPT 1

addformat MODLIST_FOOTER -------------------------------------------------------
addformat MODLIST_FOOTER1 $G Available modules: $numitems(modules), Loaded modules: $numitems(loaded_modules)
addformat MODLIST_FOOTER2
addformat MODLIST_HEADER #   Module           Version    Size  Loaded Auto-Load
addformat MODLIST_HEADER1 -------------------------------------------------------
addformat MODLIST_HEADER2
addformat MODLIST_MODULE  $[3]1 $[16]2 $[7]3 $[-7]4    ${[$5] ? [\[*\]] : [\[\ \]]}     ${[$6] ? [\[*\]] : [\[ \]]}


/****** USER ALIASES ******/

/*
 * /AUTOLOAD [[-a|-d] <module> ...] ...
 *
 * Interface to /DSET AUTO_LOAD_MODULES. The -a and -d options specify which
 * action to perform (add/delete). If neither is present then -a will be
 * assumed.
 */
alias autoload (args)
{
	^local action add
	^local modlist $CONFIG.AUTO_LOAD_MODULES

	if (!args) {
		dset AUTO_LOAD_MODULES
		return
	}

	while (:arg = shift(args))
	{
		switch ($arg)
		{
			(-a) { @ :action = [add]; }
			(-d) { @ :action = [delete]; }
			(*) {
				if (action == [add] && findw($arg $modlist) == -1) {
					@ push(:modlist $arg)
				} else if (action == [delete]) {
					@ :modlist = remw($arg $modlist)
				}
			}
		}
	}

	if (modlist != CONFIG.AUTO_LOAD_MODULES) {
		dset AUTO_LOAD_MODULES $modlist
	} else {
		dset AUTO_LOAD_MODULES
	}
}

alias loadmod (modules)
{
	stack push set INPUT_PROMPT

	if (!modules)
	{
		modlist
		^local modules $"Enter modules to load: "
		if (modules == []) {
			return
		}
	}{
		/* modlist takes care of this if there are no modules */
		_build_modlist
	}

	if (modules == [*])
	{
		@ :modules = []
		for ii from 0 to ${numitems(_modules) - 1} {
			@ push(:modules $getitem(_modules $ii))
		}
	}{   
		@ :modules = getitems(_modules -1 $modules)
	}

	for module in ($modules)
	{
		^local modver $modinfo($module v)

		if (#modules > 1) {
			^set INPUT_PROMPT Loading modules [$pad($#modules . $progress)] \($module $modver\)
		}

		if (!(:retcode = _load_module($module)))
		{
			/* Module loaded successfully */
			@ :progress #= [*]
			@ push(:pass $module)
		}{
			/* Module failed to load */
			@ :progress #= [x]
			switch ($retcode)
			{
				(1) { echo Error: _load_module: Not enough arguments; }
				(2) { xecho -b Module is already loaded: $module; }
				(3) { xecho -b Module not found: $module; }
			}
		}

		if (#modules > 1) {
			^set INPUT_PROMPT Loading modules [$pad($#modules . $progress)] \($module $modver\)
		}
	}

	if (#pass == 1) {
		xecho -b Loaded module: $pass $modinfo($pass v)
	} else if (pass) {
		xecho -b Loaded $#pass modules: $pass
	}

	stack pop set INPUT_PROMPT
}

alias listmods modlist

alias modules modlist

alias modlist (void)
{
	_build_modlist

	for var in (MODLIST_HEADER MODLIST_HEADER1 MODLIST_HEADER2) {
		if (FORMAT[$var]) {
			echo $fparse($var)
		}
	}

	for cnt from 0 to ${numitems(_modules) - 1}
	{
		@ :num = cnt + 1
		@ :module = getitem(_modules $cnt)
		@ :file = _MODULE.$module
		@ :version = _MODULE[$module][VERSION] ? _MODULE[$module][VERSION] : [-]
		@ :auto_load = match($module $CONFIG.AUTO_LOAD_MODULES) ? 1 : 0
		@ :loaded = finditem(_loaded_modules $module) > -1 ? 1 : 0
		if (FORMAT.MODLIST_MODULE) {
			echo $fparse(MODLIST_MODULE $num $module $version $fsize($file) $loaded $auto_load)
		}
	}

	for var in (MODLIST_FOOTER MODLIST_FOOTER1 MODLIST_FOOTER2) {
		if (FORMAT[$var]) {
			echo $fparse($var)
		}
	}

	/*
	 * Attempt to purge the auto-load list of modules that don't exist.
	 */
	for mod in ($CONFIG.AUTO_LOAD_MODULES) {
		if (finditem(_modules $mod) < 0) {
			^local ask $'Remove unknown module "$mod" from the auto-load list? '
			if (ask == [y]) {
				@ CONFIG.AUTO_LOAD_MODULES = remw($mod $CONFIG.AUTO_LOAD_MODULES)
				xecho -b Removed $mod from the auto-load list
			}
		}
	}
}

alias reloadmod (modules)
{
	if (!modules)
	{
		xecho -b Usage: /RELOADMOD <module> ...
		return
	}

	unloadmod $modules
	loadmod $modules
}

alias unloadmod (modules)
{
	stack push set INPUT_PROMPT

	if (!modules)
	{
		echo #   Module
		for ii from 1 to $numitems(_loaded_modules) {
			echo $[3]ii $getitem(_loaded_modules ${ii-1})
		}
		^local modules $"Enter modules to unload: "
		if (modules == []) {
			return
		}
	}

	if (modules == [*])
	{
		@ :modules = []
		for ii from 0 to ${numitems(_loaded_modules) - 1} {
			@ push(:modules $getitem(_loaded_modules $ii))
		}
	}{
		@ :modules = getitems(_loaded_modules -1 $modules)
	}

	for module in ($modules)
	{
		if (#modules > 1) {
			^set INPUT_PROMPT Unloading modules [$pad($#modules . $progress)] \($module\)
		}

		if (CONFIG.SAVE_ON_UNLOAD) {
			^save $module
		}

		if (!(:retcode = _unload_module($module)))
		{
			/* Module unloaded successfully */
			@ :progress #= [*]
			@ push(:pass $module)
		}{
			/* Module could not be unloaded */
			@ :progress #= [x]
			switch ($retcode)
			{
				(1) { echo Error: _unload_module: Not enough arguments; }
				(2) { xecho -b Module is not loaded: $module; }
			}
		}

		if (#modules > 1) {
			^set INPUT_PROMPT Unloading modules [$pad($#modules . $progress)] \($module\)
		}
	}

	if (#pass == 1) {
		xecho -b Unloaded module: $pass
	} else {
		xecho -b Unloaded $#pass modules: $pass
	}

	stack pop set INPUT_PROMPT
}


/****** INTERNAL ALIASES ******/

alias _build_modlist (void)
{
	for dir in ($DS.MODULE_DIRS) {
		_scan_module_dir $dir
	}
}

/*
 * Loads a module and its save file.
 * Returns 0 on success and > 0 on failure.
 */
alias _load_module (module, void)
{
	if (!module) { return 1; }

	if (finditem(_loaded_modules $module) > -1) {
		/* Module is already loaded */
		return 2
	}

	if (finditem(_modules $module) < 0) {
		/* Module not found */
		return 3
	}

	^assign MODULE.LOADING $module

	load $_MODULE[$module]

	if (fexist($DS.SAVE_DIR/$module) == 1) {
		^load $DS.SAVE_DIR/$module
	}

	@ setitem(_loaded_modules $numitems(_loaded_modules) $module)

	/* Hook the event so other modules can act on it */
	hook LOADMOD $module

	^assign -MODULE.LOADING
	return 0
}

/*
 * Scans <dir> for modules and sets up all the internal variables
 * necessary to make the module available. The top line of the file
 * will be read in and parsed for a version string.
 */
alias _scan_module_dir (dir, void)
{
	if (!dir) {
		echo Error: _scan_module_dir: Not enough arguments
		return
	}

	@ :dir = twiddle($dir)
	for file in ($glob($dir\/\*.dsm))
	{
		@ :name = before(-1 . $after(-1 / $file))

		/*
		 * Restrict module names.
		 */
		@ :pass  = chr($jot($ascii(AZ)))
		@ :pass #= chr($jot($ascii(az)))
		@ :pass #= chr($jot($ascii(09)))
		if (strip($pass $name)) {
			echo Error: _scan_module_dir: Illegal module name: $name
			return
		}
		if (rmatch($name _* core ds module config format)) {
			echo Error: _scan_module_dir: The module name '$name' is reserved
			return
		}

		/*
		 * Grab the module's header from the top of the file and parse it.
		 */
		if ((:fd = open($file R)) != -1)
		{
			@ :header = read($fd)
			if (:index = match(*version $header)) {
				/* $match() counts from 1 and $word() counts from 0 */
				^assign _MODULE[$name][VERSION] $word($index $header)
			}
			@ close($fd)
		}

		^assign _MODULE.$name $file
    
		if ((:item = finditem(_modules $name)) > -1) {
			@ delitem(_modules $item)
		}
		@ setitem(_modules $numitems(_modules) $name)
	}
}

/*
 * Unloads a module and cleans up after it.
 * Returns 0 on success and > 0 on failure.
 */
alias _unload_module (module, void)
{
	if (!module) {
		return 1
	}

	@ :item = finditem(_loaded_modules $module)
	if (item < 0) {
		/* Module is not loaded */
		return 2
	}

	^assign MODULE.UNLOADING $module

	/*
	 * Execute module's cleanup queue and purge all assign,
	 * alias, and array structures that belong to this module.
	 */
	queue -do cleanup.$module
	purge $module
	purgealias $module
	for array in ($getarrays($module\.*)) { @ delarray($array); }

	/*
	 * Remove all metadata for this module.
	 */
	for var in ($_DSET.MODULE[$module])
	{
		^assign -CONFIG.$var
		purge _DSET.$var
	}
	for var in ($_FSET[MODULE][$module])
	{
		^assign -FORMAT.$var
		purge -_FSET.$var
	}
	^assign -_DSET.MODULE.$module
	^assign -_FSET.MODULE.$module
	purge _MODINFO.$module
	@ delitem(_loaded_modules $item)

	hook UNLOADMOD $module

	^assign -MODULE.UNLOADING
	return 0
}


/****** STARTUP ******/

defer
{
	if (CONFIG.LOAD_PROMPT)
	{
		modlist

		@ :holdslider = windowctl(GET $winnum() HOLD_SLIDER)
		@ :holdmode   = windowctl(GET $winnum() HOLDING_DISTANCE) > -1 ? [ON] : [OFF]
		^window hold_slider 0
		^window hold_mode on

		^local ask $"Enter modules to load ('a' for auto-load, '*' for all): "
		switch ($ask)
		{
			(a) {
				if (CONFIG.AUTO_LOAD_MODULES) {
					loadmod $CONFIG.AUTO_LOAD_MODULES
				} else {
					xecho -b No modules on the auto-load list
					xecho -b Type /AUTOLOAD or /DSET AUTO_LOAD_MODULES to add a module
				}
			}
			(\\*) {
				for ii from 1 to $numitems(_modules) {
					@ push(:mods $getitem(_modules ${ii-1}))
				}
				loadmod $mods
			}
			(*) {
				@ :mods = getitems(_modules -1 $ask)
				if (mods) {
					loadmod $mods
				}
			}
		}

		^window hold_slider $holdslider
		^window hold_mode $holdmode
	}\
	else if (CONFIG.AUTO_LOAD_MODULES)
	{
		xecho -b Loading all modules on the auto-load list...
		loadmod $CONFIG.AUTO_LOAD_MODULES
	}
}


/* EOF */