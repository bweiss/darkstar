/* $Id$ */
/*
 * loader.dsc - DarkStar module loader
 * Copyright (c) 2002 Brian Weiss
 * See the 'COPYRIGHT' file for more information.
 */

/****** USER ALIASES ******/

alias loadmod (modules)
{
	^local pass
	^local progress
	@:oldprompt = INPUT_PROMPT
	@:verbose = CONFIG.LOADMODULE_VERBOSE

	loader.build_modlist

	if (!modules) {
		modlist
		^local modules $"Modules to load? (1 2-4 ...) "
		if (modules == []) {
			return
		}
	}

	@:modules = loader.which_mods(modules $modules)

	for module in ($modules)
	{
		@:retcode = loader.load_module($module)
		if (!retcode) {
			/* Module loaded successfully */
			if (verbose) {
				@:modver = modinfo($module v)
				xecho -b Loaded module: $module ${modver != [-] ? modver : []}
			} else {
				@:progress = progress ## [.]
				push pass $module
				^set INPUT_PROMPT Loading modules [$[$#modules]progress] \($module $modinfo($module v)\)
			}
		} else {
			/* Module failed to load */
			@:progress = progress ## [x]
			switch ($retcode) {
				(1) {echo Error: No modules found}
				(2) {echo Error: Module is already loaded \($module\)}
				(3) {echo Error: Module not found: $module}
				(*) {echo Error: Unknown \(module: $module\)}
			}
		}
	}

	if (!verbose) {
		if (oldprompt == []) {
			^set -INPUT_PROMPT
		} else {
			^set INPUT_PROMPT $oldprompt
		}
		xecho -b Loaded $#pass module${#pass == 1 ? [] : [s]}${#pass > 0 ? [ \($pass\)] : []}
	}
}

alias listmods modlist
alias modules modlist
alias modlist (void)
{
	loader.build_modlist

	for var in (MODLIST_HEADER MODLIST_HEADER1 MODLIST_HEADER2) {
		if (FORMAT[$var]) {
			echo $fparse($var)
		}
	}

	for cnt from 0 to ${numitems(modules) - 1}
	{
		@:num = cnt + 1
		@:file = getitem(module_files $cnt)
		@:module = getitem(modules $cnt)
		@:version = getitem(module_versions $cnt)
		@:auto_load = match($module $CONFIG.AUTO_LOAD_MODULES) ? 1 : 0
		@:loaded = finditem(loaded_modules $module) > -1 ? 1 : 0

		if (FORMAT.MODLIST_MODULE) {
			echo $fparse(MODLIST_MODULE $num $module $version $fsize($file) $loaded $auto_load)
		}
	}

	for var in (MODLIST_FOOTER MODLIST_FOOTER1 MODLIST_FOOTER2) {
		if (FORMAT[$var]) {
			echo $fparse($var)
		}
	}
}

alias reloadmod (modules)
{
	if (!modules) {
		xecho -b Usage: /RELOADMOD <module> ...
		return
	}
	unloadmod $modules
	loadmod $modules
}

alias unloadmod (modules)
{
	^local pass
	^local progress
	@:oldprompt = INPUT_PROMPT
	@:verbose = CONFIG.LOADMODULE_VERBOSE

	if (!modules) {
		echo #   Module
		for cnt from 0 to ${numitems(loaded_modules) - 1} {
			@:num = cnt + 1
			echo $[3]num $getitem(loaded_modules $cnt)
		}
		^local modules $"Modules to unload? (1 2-4 ...) "
		if (modules == []) {
			return
		}
	}

	@:modules = loader.which_mods(loaded_modules $modules)

	for module in ($modules)
	{
		if (CONFIG.AUTO_SAVE_ON_UNLOAD) {
			^save $module
		}

		@:retcode = loader.unload_module($module)
		if (!retcode) {
			/* Module unloaded successfully */
			if (verbose) {
				xecho -b Unloaded module: $module
			} else {
				@:progress = progress ## [.]
				push pass $module
				^set INPUT_PROMPT Unloading modules [$[$#modules]progress] \($module $modinfo($module v)\)
			}
		} else {
			/* Module could not be unloaded */
			@:progress = progress ## [x]
			switch ($retcode) {
				(1) {echo Error: No modules are currently loaded}
				(2) {echo Error: Module is not loaded \($module\)}
				(*) {echo Error: Unknown \(module: $module\)}
			}
		}
	}

	if (!verbose) {
		if (oldprompt == []) {
			^set -INPUT_PROMPT
		} else {
			^set INPUT_PROMPT $oldprompt
		}
		xecho -b Unloaded $#pass module${#pass == 1 ? [] : [s]}${#pass > 0 ? [ \($pass\)] : []}
	}
}


/****** MODULE ALIASES ******/

/*
 * Handles module dependencies.
 * This is meant to be called by a module at load time.
 */
alias module.dep (depmods)
{
	@:module = after(-1 / $before(-1 . $word(1 $loadinfo())))

	if (!module) {
		echo Error: module.dep: This command must be called at load time
		return
	}

	if (!depmods) {
		echo Error: module.dep: Not enough arguments \(module: $module\)
		return
	}

	for depmod in ($depmods)
	{
		if (finditem(loaded_modules $depmod) < 0)
		{
			if (finditem(modules $depmod) > -1)
			{
				if (CONFIG.AUTO_LOAD_DEPENDENCIES)
				{
					xecho -b Module $module depends on $depmod - Auto-loading...
					loadmod $depmod
				}{
					^local tmp $'Module $module depends on $depmod - Load it now? [Yn] '
					if (tmp == []) {
						@:tmp = [Y]
					}
					switch ($toupper($left(1 $tmp))) {
						(Y) {loadmod $depmod}
						(*) {xecho -b Skipping dependency $depmod - Module may not work properly}
					}
				}
			}{
				xecho -b Warning: Unable to load dependency: Module not found: $depmod
			}
		}
	}
}

/*
 * This allows modules to force saved settings to be loaded before the module
 * is finished loading. Very useful for events happening at module load time
 * that depend on certain config settings. This should not be used until
 * after adding your config and format variables via {config|format}.add.
 */
alias module.load_saved_settings (void)
{
	@:module = after(-1 / $before(-1 . $word(1 $loadinfo())))
	if (module) {
		@:save_file = DS.SAVE_DIR ## [/] ## module ## [.sav]
		if (fexist($save_file) == 1) {
			^load $save_file
		}
	}
}


/****** INTERNAL ALIASES ******/

/*
 * This scans the module directories and compiles a list of modules.
 * Data about each module is stored in the three arrays: modules,
 * module_files, and module_versions. The module's version is grabbed
 * from the top line of the file and must be in the form of
 * "#version <versionstr>". If no version is specified, '-' will be used.
 */
alias loader.build_modlist (void)
{
	@ delarray(modules)
	@ delarray(module_files)
	@ delarray(module_versions)

	for dir in ($DS.MODULE_DIR)
	{
		@:dir = twiddle($dir)
		for file in ($glob($dir\/\*.dsm))
		{
			@:name = before(-1 . $after(-1 / $file))

			if (tolower($name) == [core]) {
				echo Error: loader.build_modlist: The name "core" is reserved
				return
			}

			/* Get the module's version */
			@:fd = open($file R)
			@:line = read($fd)
			@ close($fd)
			if (match(#version $line)) {
				@:ver = word(1 $line)
			} else {
				@:ver = [-]
			}

			/* If a module with the same name already exists, remove it
			   so that the new module overrides the old. */
			@:item = matchitem(modules $name)
			if (item > -1) {
				@ delitem(modules $item)
				@ delitem(module_files $item)
				@ delitem(module_versions $item)
			}

			@ setitem(modules $numitems(modules) $name)
			@ setitem(module_files $numitems(module_files) $file)
			@ setitem(module_versions $numitems(module_versions) $ver)
		}
	}
}

/*
 * Loads a module including theme and saved settings.
 * Returns 0 on success, and > 0 on failure.
 */
alias loader.load_module (module, void)
{
	if (!numitems(modules)) {
		/* No modules found */
		return 1
	}

	/* Remove the extension if necessary */
	if (match(%.% $module)) {
		@:module = before(-1 . $module)
	}

	if (finditem(loaded_modules $module) > -1) {
		/* Module already loaded */
		return 2
	}

	@:item = finditem(modules $module)
	if (item > -1)
	{
		@:file = getitem(module_files $item)
		@:save_file = DS.SAVE_DIR ## [/] ## module ## [.sav]
		@:theme_file = getitem(theme_dirs $finditem(themes $DS.THEME)) ## module

		load $file

		if (fexist($save_file) == 1) {
			load $save_file
		}

		if (fexist($theme_file) == 1) {
			load $theme_file
		}

		@ setitem(loaded_modules $numitems(loaded_modules) $module)

		/* Hook the event so other modules can act on it */
		hook LOADMOD $module

		return 0
	}

	/* No such module */
	return 3
}

/*
 * Unloads a module and cleans up after it.
 * Returns 0 on success, and > 0 on failure.
 */
alias loader.unload_module (module, void)
{
	if (!numitems(loaded_modules)) {
		/* No modules are loaded */
		return 1
	}

	/* Remove the extension if necessary */
	if (match(%.% $module)) {
		@:module = before(-1 . $module)
	}

	@:item = finditem(loaded_modules $module)
	if (item > -1)
	{
		/* Execute cleanup queue for module */
		queue -do cleanup.$module

		/* Get rid of any global aliases/variables obviously
		   associated with this module */
		purge $module
		purgealias $module

		/* Get rid of any arrays obviously associated with this module */
		for array in ($pattern($module\.* $getarrays())) {
			@ delarray($array)
		}

		/* Remove all config and format variables */
		for var in ($DSET.MODULES[$module]) {
			^assign -CONFIG.$var
			^assign -DSET.CONFIG.$var
			^assign -DSET.BOOL.$var
		}
		for var in ($FSET.MODULES[$module]) {
			^assign -FORMAT.$var
			^assign -FSET.FORMAT.$var
		}

		^assign -DSET.MODULES.$module
		^assign -FSET.MODULES.$module
			
		/* Remove any info lines for this module */
		purge MODINFO[$module]

		@ delitem(loaded_modules $item)

		/* Hook event so other modules can act on it */
		hook UNLOADMOD $module

		return 0
	}

	/* Module is not loaded */
	return 2
}

/*
 * Converts any number, or range of numbers, to its module equivalent. It can
 * be passed any combination of module names, numbers, and ranges of numbers
 * and returns only module names.
 */
alias loader.which_mods (array, args)
{
	^local modules

	for tmp in ($args)
	{
		if (isnumber($strip(- $tmp)))
		{
			if (match(%-% $tmp))
			{
				@:startmod = before(- $tmp)
				@:endmod = after(- $tmp)
				if (startmod < endmod && startmod < numitems($array) && endmod <= numitems($array)) {
					for cnt from $startmod to $endmod {
						@:item = cnt - 1
						push modules $getitem($array $item)
					}
				} else {
					echo Error: loader.which_mods\(\): Illegal range specified
				}
			}{
				if (tmp <= numitems($array)) {
					@:item = tmp - 1
					push modules $getitem($array $item)
				} else {
					echo Error: loader.which_mods\(\): Module not found: $tmp
				}
			}
		}{
			push modules $tmp
		}
	}

	@ function_return = modules
}


/****** STARTUP ******/

/*
 * Load some modules at startup, if desired.
 */
if (CONFIG.AUTO_LOAD_PROMPT)
{
	^local modules

	/* Keep things quiet while we list available modules */
	for hook in (250 251 252 254 255 265 266) {
		^on ^$hook ^"*"
	}

	^stack push set SUPPRESS_SERVER_MOTD
	^set SUPPRESS_SERVER_MOTD ON

	modlist
	^local mods $"Modules to load? ([A]uto / [N]one / 1 2-4 ...) [A] "
	if (mods == []) {
		@:mods = [A]
	}

	switch ($toupper($mods)) {
		(N) {#}
		(A) {@:modules = CONFIG.AUTO_LOAD_MODULES}
		(*) {@:modules = loader.which_mods(modules $mods)}
	}
	
	/* Cleanup after ourselves */
	wait -cmd for hook in (250 251 252 254 255 265 266) {
		^on ^$hook -"*"
	}

	^stack pop set SUPPRESS_SERVER_MOTD

	/* Load the modules */
	if (modules) {
		loadmod $modules
	}
}\
else if (CONFIG.AUTO_LOAD_MODULES)
{
	loadmod $CONFIG.AUTO_LOAD_MODULES
}


/* EOF */