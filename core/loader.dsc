/* $Id$ */
/*
 * loader.dsc - Module loader
 *
 * Written by Brian Weiss
 * Copyright (c) 2002 Brian Weiss
 * See the 'COPYRIGHT' file for more information.
 */


alias loadedmods loadedmodules
alias loadedmodules (void)
{
	echo  #   Module           Version     Size(bytes)
	echo ----------------------------------------------
	for cnt from 0 to ${numitems(loaded_modules) - 1}
	{
		@ :num = cnt + 1
		@ :modname = getitem(loaded_modules $cnt)
		@ :item = finditem(modules $modname)
		@ :modver = getitem(module_versions $item)
		@ :modsize = fsize($getitem(module_files $item))
		echo  $[3]num $[16]modname [ $[7]modver ] [ $[-7]modsize ]
	}
	echo ----------------------------------------------
	xecho -b Loaded modules: $numitems(loaded_modules)
}

alias loadmod (modules)
{
	loader.build_modlist
	@ modules = loader.which_mods(modules $modules)

	if (!modules)
	{
		modlist
		^local mods $"Modules to load? (1 2-4 ...) "
		if (mods) {
			@ modules = loader.which_mods(modules $mods)
		}
	}

	for module in ($modules)
	{
		switch ($loader.load_module($module))
		{
			(0) {xecho -b Module [$module] has been loaded}
			(1) {xecho -b Error: No modules found}
			(2) {xecho -b Error: Module [$module] is already loaded}
			(3) {xecho -b Error: Module [$module] not found}
			(*) {xecho -b Error: Unknown}
		}
	}
}

alias listmods modlist
alias modules modlist
alias modlist (void)
{
	loader.build_modlist
	echo  #   Module           Version     Size(bytes) Loaded Auto-Load
	echo ---------------------------------------------------------------
	for cnt from 0 to ${numitems(modules) - 1}
	{
		@ :num = cnt + 1
		@ :file = getitem(module_files $cnt)
		@ :module = getitem(modules $cnt)
		@ :version = getitem(module_versions $cnt)
		@ :auto_load = common($module / $CONFIG.AUTO_LOAD_MODULES) ? [\(*\)] : [\( \)]
		@ :loaded = finditem(loaded_modules $module) > -1 ? [\(*\)] : [\( \)]
		echo  $[3]num $[16]module [ $[7]version ] [ $[-7]fsize($file) ]   $loaded     $auto_load
	}
	echo ---------------------------------------------------------------
	xecho -b Available modules: $numitems(modules), Loaded modules: $numitems(loaded_modules)
}

alias reloadmod (modules)
{
	if (!modules) {
		xecho -b Usage: /reloadmod <module> [module] ...
		return
	}

	for module in ($modules) {
		unloadmod $module
		loadmod $module
	}
}

alias unloadmod (modules)
{
	if (!modules)
	{
		loadedmodules
		^local mods $"Modules to unload? (1 2-4 ...) "
		if (mods) {
			@ :modules = loader.which_mods(loaded_modules $mods)
		}
	}{
		@ :modules = loader.which_mods(loaded_modules $modules)
	}

	for module in ($modules)
	{
		switch ($loader.unload_module($module))
		{
			(0) {xecho -b Module [$module] has been unloaded}
			(1) {xecho -b Error: No modules are currently loaded}
			(2) {xecho -b Error: Module [$module] is not loaded}
			(*) {xecho -b Error: Unknown}
		}
	}
}


/*
 * Stores available modules in two arrays, one for module names (modules)
 * and one for module filenames (module_files). It also reads a version tag
 * from the first line of the module and stores it in the module_versions
 * array.
 */
alias loader.build_modlist (void)
{
	@ delarray(modules)
	@ delarray(module_files)
	@ delarray(module_versions)

	for dir in ($DS.MODULE_DIR)
	{
		@ :dir = twiddle($dir)
		for file in ($glob($dir\/\*.dsm))
		{
			@ :name = before(-1 . $after(-1 / $file))

			/* Get module version. */
			@ :fd = open($file R)
			@ :line = read($fd)
			@ close($fd)
			if (match(#version $line)) {
				@ :ver = word(1 $line)
			}{
				@ :ver = [-]
			}

			@ :item = matchitem(modules $name)
			if (item > -1) {
				@ delitem(modules $item)
				@ delitem(module_files $item)
				@ delitem(module_versions $item)
			}

			if (tolower($name) == [core]) {
				xecho -b Error: loader.build_modlist: The "core" module name is reserved
			} else {
				@ setitem(modules $numitems(modules) $name)
				@ setitem(module_files $numitems(module_files) $file)
				@ setitem(module_versions $numitems(module_versions) $ver)
			}
		}
	}
}

/*
 * Loads a module including theme and saved settings. Returns 0 on success,
 * and > 0 on failure.
 */
alias loader.load_module (module, void)
{
	if (!numitems(modules)) {
		/* No modules found. */
		return 1
	}

	/* Remove the extension if necessary. */
	if (match(%.% $module)) {
		@ :module = before(-1 . $module)
	}

	if (finditem(loaded_modules $module) > -1) {
		/* Module already loaded. */
		return 2
	}

	@ :item = finditem(modules $module)

	if (item > -1)
	{
		@ :file = getitem(module_files $item)
		@ :save_file = DS.SAVE_DIR ## [/] ## module ## [.sav]
		@ :theme_file = getitem(theme_dirs $finditem(themes $DS.THEME)) ## module

		/* Load the actual module. */
		load $file

		/* Load the save file. */
		if (fexist($save_file) == 1) {
			load $save_file
		}

		/* Load the theme file for this module. */
		if (fexist($theme_file) == 1) {
			load $theme_file
		}

		/* Add module to loaded_modules array. */
		@ setitem(loaded_modules $numitems(loaded_modules) $module)

		/* Hook the event so other modules can act on it. */
		hook LOADMOD $module

		return 0
	}

	/* No such module. */
	return 3
}

/*
 * Unloads a module and cleans up after it. Returns 0 on success,
 * and > 0 on failure.
 */
alias loader.unload_module (module, void)
{
	if (!numitems(loaded_modules)) {
		/* No modules are loaded. */
		return 1
	}

	/* Remove the extension if necessary. */
	if (match(%.% $module)) {
		@ :module = before(-1 . $module)
	}

	@ :item = finditem(loaded_modules $module)

	if (item > -1)
	{
		/* Execute cleanup queue for module. */
		queue -do cleanup.$module

		/* Get rid of any global aliases/variables obviously
		   related to this module. */
		purge $module
		purgealias $module

		/* Remove all config and format variables. */
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
			
		/* Remove any info lines for this module. */
		purge MODINFO[$module]

		/* Remove from loaded_modules array. */
		@ delitem(loaded_modules $item)

		/* Hook event so other modules can act on it. */
		hook UNLOADMOD $module

		return 0
	}

	/* Module is not loaded. */
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
				@ :startmod = before(- $tmp)
				@ :endmod = after(- $tmp)
				if (startmod < endmod && startmod < numitems($array) && endmod <= numitems($array))
				{
					for cnt from $startmod to $endmod
					{
						@ :item = cnt - 1
						push modules $getitem($array $item)
					}
				}{
					xecho -b loader.which_mods(): Illegal range specified!
				}
			}{
				if (tmp <= numitems($array))
				{
					@ :item = tmp - 1
					push modules $getitem($array $item)
				}{
					xecho -b loader.which_mods(): Module not found [$tmp]
				}
			}
		}{
			push modules $tmp
		}
	}

	@ function_return = modules
}


/*
 * Commands intended for use by modules but not necessarily limited to that
 * (loader.unload_mod calls module.rminfo).
 */

/*
 * Handle module dependencies. This is meant to be called at module load time.
 */
alias module.dep (depmods)
{
	@ :module = after(-1 / $before(-1 . $word(1 $loadinfo())))

	if (!module) {
		echo Error: module.dep: This command must be called at load time
		return
	}

	if (!depmods) {
		echo Error: module.dep: Not enough arguments \(Module: $module\)
		return
	}

	for depmod in ($depmods)
	{
		if (finditem(loaded_modules $depmod) < 0)
		{
			if (finditem(modules $depmod) > -1)
			{
				if (CONFIG[AUTO_LOAD_DEPENDENCIES])
				{
					xecho -b Module [$module] depends on [$depmod]. Auto-loading...
					loadmod $depmod
				}{
					^local tmp $"Module [$module] depends on [$depmod] - Load it now? [Yn] "
					if (tmp == []) {
						^assign tmp Y
					}

					switch ($toupper($left(1 $tmp)))
					{
						(Y) {loadmod $depmod}
						(*) {xecho -b Skipping dependency [$depmod]. Module may not work properly.}
					}
				}
			}{
				xecho -b Warning: Unable to load dependency. Module [$depmod] not found.
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
	@ :module = after(-1 / $before(-1 . $word(1 $loadinfo())))
	if (module) {
		@ :save_file = DS.SAVE_DIR ## [/] ## module ## [.sav]
		if (fexist($save_file) == 1) {
			^load $save_file
		}
	}
}


/*
 * Load some modules at startup, if desired.
 */
if (CONFIG.AUTO_LOAD_PROMPT)
{
	^local modules

	/* Keep things quiet while we list available modules. */
	for hook in (250 251 252 254 255 265 266) {
		^on ^$hook ^"*"
	}

	^stack push set SUPPRESS_SERVER_MOTD
	^set SUPPRESS_SERVER_MOTD ON

	modlist
	^local mods $"Modules to load? ([A]uto / [N]one / 1 2-4 ...) [A] "
	if (mods == []) {
		@ :mods = [A]
	}

	switch ($toupper($mods))
	{
		(N) {#}
		(A) {@ modules = CONFIG.AUTO_LOAD_MODULES}
		(*) {@ modules = loader.which_mods(modules $mods)}
	}
	
	/* Cleanup after ourselves. */
	wait -cmd for hook in (250 251 252 254 255 265 266) {
		^on ^$hook -"*"
	}

	^stack pop set SUPPRESS_SERVER_MOTD

	/* Load the modules. */
	if (modules) {
		loadmod $modules
	}
}\
else if (CONFIG[AUTO_LOAD_MODULES])
{
	loadmod $CONFIG.AUTO_LOAD_MODULES
}


/* EOF */