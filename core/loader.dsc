/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * LOADER.DSC - Module loader for Darkstar/EPIC4
 * Author: Brian Weiss <brian@epicsol.org> - 2001
 *
 * Last modified: 1/14/02 (bmw)
 */


alias listmods modlist
alias loadedmods loadedmodules
alias modules modlist


alias loadedmodules (void)
{
	echo #   Module
	for cnt from 0 to ${numitems(loaded_modules) - 1}
	{
		@ :num = cnt + 1
		echo $[3]num $getitem(loaded_modules $cnt)
	}
}

alias loadmod (modules)
{
	loader.build_modlist
	@ modules = loader.which_mods(modules $modules)

	if (!modules)
	{
		modlist
		^local mods $"Modules to load? (1 2-4 ...) "
		if (mods)
		{
			@ modules = loader.which_mods(modules $mods)
		}
	}

	for module in ($modules)
	{
		switch ($loader.load_module($module))
		{
			(0) {xecho -b Module [$module] has been loaded}
			(1) {xecho -b ERROR: No modules found}
			(2) {xecho -b ERROR: Module [$module] is already loaded}
			(3) {xecho -b ERROR: Module [$module] not found}
			(*) {xecho -b ERROR: Unknown}
		}
	}
}

alias modlist (void)
{
	loader.build_modlist

	echo #   Module                     Size (bytes)  Loaded  Auto-Load
	for cnt from 0 to ${numitems(modules) - 1}
	{
		@ :num = cnt + 1
		@ :file = getitem(module_files $cnt)
		@ :module = getitem(modules $cnt)
		@ :auto_load = common($module / $CONFIG.AUTO_LOAD_MODULES) ? [*] : []
		@ :loaded = finditem(loaded_modules $module) > -1 ? [*] : []
		echo $[3]num $[25]module $[-12]fsize($file)     $[8]loaded $[8]auto_load
	}
	xecho -b Type '/dset AUTO_LOAD_MODULES' to modify the Auto-Load list
	xecho -b Type '/loadmod [<module> ...]' to load a module
	xecho -b Type '/unloadmod [<module> ...]' to unload a module
}

alias reloadmod (module, void)
{
	unloadmod $module
	loadmod $module
}

alias unloadmod (modules)
{
	if (!modules)
	{
		loadedmodules
		^local mods $"Modules to unload? (1 2-4 ...) "
		if (mods)
		{
			@ modules = loader.which_mods(loaded_modules $mods)
		}
	}{
		@ modules = loader.which_mods(loaded_modules $modules)
	}

	for module in ($modules)
	{
		switch ($loader.unload_module($module))
		{
			(0) {xecho -b Module [$module] has been unloaded}
			(1) {xecho -b ERROR: No modules are currently loaded}
			(2) {xecho -b ERROR: Module [$module] is not loaded}
			(*) {xecho -b ERROR: Unknown}
		}
	}
}


alias loader.build_modlist (void)
{
	@ delarray(modules)
	@ delarray(module_files)

	for dir in ($DS.MODULE_DIR)
	{
		@ :dir = twiddle($dir)
		for file in ($glob($dir\/\*.dsm))
		{
			@ :name = before(-1 . $after(-1 / $file))
			@ setitem(modules $numitems(modules) $name)
			@ setitem(module_files $numitems(module_files) $file)
		}
	}
}

alias loader.dependency (depmods)
{
	@ :module = LOADER.PENDING_MODULE

	if (!depmods)
	{
		echo loader.dependency: Not enough arguments \(Module: $module\)
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
					if (tmp == []) ^assign tmp Y

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
 * that depend on certain config settings.
 */
alias loader.get_saved_settings (void)
{
	@ :module = LOADER[PENDING_MODULE]
	^local save_file $DS.SAVE_DIR/$module\.sav

	if (fexist($save_file) == 1)
	{
		^load $save_file
	}
}

alias loader.load_module (module, void)
{
	if (!numitems(modules))
	{
		/* No modules found. */
		return 1
	}

	/* Remove the extension if necessary. */
	if (before(-1 . $module))
	{
		@ module = before(-1 . $module)
	}

	if (finditem(loaded_modules $module) > -1)
	{
		/* Module already loaded. */
		return 2
	}

	@ :item = finditem(modules $module)

	if (item > -1)
	{
		@ :file = getitem(module_files $item)
		^local save_file $DS.SAVE_DIR/$module\.sav
		@ :theme_file = getitem(theme_dirs $finditem(themes $DS.THEME)) ## module

		/* Load the actual module. */
		^assign LOADER.PENDING_MODULE $module
		load $file
		^assign -LOADER.PENDING_MODULE

		/* Load the save file. */
		if (fexist($save_file) == 1)
		{
			load $save_file
		}

		/* Load the theme file for this module. */
		if (fexist($theme_file) == 1)
		{
			load $theme_file
		}

		/* Add module to loaded_modules array and exit. */
		@ setitem(loaded_modules $numitems(loaded_modules) $module)
		return 0
	}

	/* No such module. */
	return 3
}


alias loader.unload_module (module, void)
{
	if (!numitems(loaded_modules))
	{
		/* No modules are loaded. */
		return 1
	}

	/* Remove the extension if necessary. */
	if (before(-1 . $module))
	{
		@ module = before(-1 . $module)
	}

	@ :item = finditem(loaded_modules $module)
	if (item > -1)
	{
		/* Execute cleanup queue for module. */
		queue -do cleanup.$module

		/* Get rid of any global aliases/variables obviously
		   related to this module. */
		for alias in ($aliasctl(alias match $module\.))
		{
			^alias -$alias
		}
			
		for var in ($aliasctl(assign match $module\.))
		{
			^assign -$var
		}

		/* Remove all config and format variables. */
		for var in ($DSET.MODULES[$module])
		{
			^assign -CONFIG.$var
			^assign -DSET.CONFIG.$var
			^assign -DSET.BOOL.$var
		}
			
		for var in ($FSET.MODULES[$module])
		{
			^assign -FORMAT.$var
			^assign -FSET.FORMAT.$var
		}

		^assign -DSET.MODULES.$module
		^assign -FSET.MODULES.$module
			
		/* Remove from loaded_modules array and exit. */
		@ delitem(loaded_modules $item)
		return 0
	}

	/* Module is not loaded. */
	return 2
}


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


if (CONFIG[AUTO_LOAD_PROMPT])
{
	^local mods,modules

	/* Keep things quiet while we list available modules. */
	for hook in (250 251 252 254 255 265 266)
	{
		^on ^$hook ^"*"
	}

	^stack push set SUPPRESS_SERVER_MOTD
	^set SUPPRESS_SERVER_MOTD ON

	/* Prompt user. */
	modlist
	^assign mods $"Modules to load? ([A]uto / [N]one / 1 2-4 ...) [A] "
	if (mods == []) {^assign mods A}

	switch ($toupper($mods))
	{
		(N) {#}
		(A) {@ modules = CONFIG[AUTO_LOAD_MODULES]}
		(*) {@ modules = loader.which_mods(modules $mods)}
	}
	
	/* Cleanup after ourselves. */
	wait -cmd for hook in (250 251 252 254 255 265 266)
	{
		^on ^$hook -"*"
	}

	^stack pop set SUPPRESS_SERVER_MOTD

	/* Load the modules. */
	if (modules)
	{
		loadmod $modules
	}
} \
elsif (CONFIG[AUTO_LOAD_MODULES])
{
	loadmod $CONFIG.AUTO_LOAD_MODULES
}


/* bmw '01 */