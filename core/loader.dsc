/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * LOADER.DSC - Module loader for Darkstar/EPIC4
 * Author: Brian Weiss <brian@epicsol.org> - 2001
 *
 * Last modified: 1/2/02 (bmw)
 */


alias listmods modlist
alias loadedmods loadedmodules
alias modules modlist


alias loadedmodules (void)
{
	@ loader.display_loaded()
}

alias loadmod (modules)
{
	@ loader.build_modlist()
	@ modules = loader.which_mods(modules $modules)

	if (!modules)
	{
		^local mods
		modlist

		while (!mods)
		{
			^assign mods $"Modules to load? (1 2-4 ...) "
			if (mods == [])
			{
				^assign mods q
			}
		}

		unless (tolower($mods) == [q])
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
	@ loader.build_modlist()
	@ loader.display_modlist()
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
		^local mods
		@ loader.display_loaded()

		while (!mods)
		{
			^assign mods $"Modules to unload? (1 2-4 ...) "
			if (mods == [])
			{
				^assign mods q
			}
		}

		unless (tolower($mods) == [q])
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

	return
}

alias loader.dependency (module, depmods)
{
	if (!module || !depmods)
	{
		echo loader.dependency(): Not enough arguments.
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
					^local tmp
					while (!tmp)
					{
						^assign tmp $"$INPUT_PROMPT Module [$module] depends on [$depmod] - Load it now? [Yn] "
						if (tmp == [])
						{
							^assign tmp Y
						}
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

	return
}

alias loader.display_loaded (void)
{
	echo #   Module
	for cnt from 0 to ${numitems(loaded_modules) - 1}
	{
		@ :num = cnt + 1
		echo $[3]num $getitem(loaded_modules $cnt)
	}

	return
}

alias loader.display_modlist (void)
{
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

	return
}


alias loader.load_module (module, void)
{
	/* Make sure there are modules available */
	if (!numitems(modules))
	{
		return 1
	}

	/* Remove the extension if necessary */
	if (before(-1 . $module))
	{
		@ module = before(-1 . $module)
	}

	/* Make sure module isn't already loaded */
	if (finditem(loaded_modules $module) > -1)
	{
		return 2
	}

	@ :item = finditem(modules $module)

	if (item > -1)
	{
		@ :file = getitem(module_files $item)
		@ :dir = before(-1 / $before(-1 / $file))
		^local defaults_file $dir/def/$module\.def
		^local save_file $DS.SAVE_DIR/$module\.sav

		if (fexist($defaults_file) == 1)
		{
			/* Read default settings and setup the needed variables
			   for the modular dset/fset */
			@ :fd = open($defaults_file R)
			
			while (!eof($fd))
			{
				@ :line = read($fd)
				@ :type = word(0 $line)
				@ :variable = word(1 $line)
				@ :value = restw(2 $line)

				switch ($type)
				{
					(dep)
					{
						@ loader.dependency($module $restw(1 $line))
					}

					(dset)
					(config)
					{
						if (word(1 $line) == [bool])
						{
							@ variable = word(2 $line)
							@ value = restw(3 $line)

							^assign DSET.BOOL.$variable 1
						}

						if (aliasctl(assign get DSET.CONFIG.$variable))
						{
							xecho -b loader.load_module(): Duplicate config variable: $variable
						}{
							@ push(DSET.MODULES.$module $variable)
							^assign DSET.CONFIG.$variable 1
							^assign CONFIG.$variable $value
						}
					}

					(fset)
					(format)
					{
						if (aliasctl(assign get FSET.FORMAT.$variable))
						{
							xecho -b loader.load_module(): Duplicate format variable: $variable
						}{
							@ push(FSET.MODULES.$module $variable)
							^assign FSET.FORMAT.$variable 1
							^assign FORMAT.$variable $value
						}
					}

					(*) { # Do nothing. }
				}
			}
		}
			
		@ close($fd)
					
		/* Load saved settings */
		if (fexist($save_file) == 1)
		{
			load $save_file
		}

		/* Load the bugger */
		load $file
		@ setitem(loaded_modules $numitems(loaded_modules) $module)

		/* Load theme file for this module */
		@ :t_file = getitem(theme_files $finditem(themes $DS.THEME)) ## module
		if (fexist($t_file) == 1)
		{
			load $t_file
		}

		return 0
	}

	/* No such module */
	return 3
}


alias loader.unload_module (module, void)
{
	/* Make sure we have modules loaded */
	if (!numitems(loaded_modules))
	{
		return 1
	}

	/* Remove the extension if necessary */
	if (before(-1 . $module))
	{
		@ module = before(-1 . $module)
	}

	@ :item = finditem(loaded_modules $module)

	if (item > -1)
	{
		/* Execute cleanup queue for module */
		queue -do cleanup.$module

		/* Get rid of any global aliases/variables obviously
		   related to this module */
		for alias in ($aliasctl(alias match $module\.))
		{
			^alias -$alias
		}
			
		for var in ($aliasctl(assign match $module\.))
		{
			^assign -$var
		}

		/* Remove all config and format variables */
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
			
		/* Remove from loaded_modules array */
		@ delitem(loaded_modules $item)

		return 0
	}

	/* Module is not loaded */
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

	/* Keep things quiet while we list available modules */
	for hook in (250 251 252 254 255 265 266)
	{
		^on ^$hook ^"*"
	}

	^stack push set SUPPRESS_SERVER_MOTD
	^set SUPPRESS_SERVER_MOTD ON

	/* Prompt user */
	modlist
	while (!mods)
	{
		^assign mods $"Modules to load? ([A]uto / [N]one / 1 2-4 ...) [A] "
		if (mods == [])
		{
			^assign mods A
		}
	}

	switch ($toupper($mods))
	{
		(N) {#}
		(A) {@ modules = CONFIG[AUTO_LOAD_MODULES]}
		(*) {@ modules = loader.which_mods(modules $mods)}
	}
	
	/* Cleanup after ourselves */
	wait -cmd for hook in (250 251 252 254 255 265 266)
	{
		^on ^$hook -"*"
	}

	^stack pop set SUPPRESS_SERVER_MOTD

	/* Load the modules */
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