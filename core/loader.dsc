/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * LOADER.DSC - Module loader for Darkstar/EPIC4
 * Author: Brian Weiss <brian@epicsol.org> - 2001
 *
 * Last modified: 12/21/01 (bmw)
 */


alias listmods modlist
alias modules modlist


alias loadmod (module, void)
{
	if (module && !isnumber($module))
	{
		@ loader.build_modlist()

		if (loader.load_module($module))
		{
			xecho -b Module [$module] has been successfully loaded
		}{
			xecho -b Error loading module [$module]
		}
	}{
		if (isnumber($module))
		{
			@ loader.build_modlist()

			if (module > 0 && module <= numitems(modules))
			{
				@ :item = module - 1
				@ :mod = getitem(modules $item)

				if (loader.load_module($mod))
				{
					xecho -b Module [$mod] has been successfully loaded
				}{
					xecho -b Error loading module [$mod]
				}
			}

			return
		}


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

		unless (tolower(mods) == [q])
		{
			for module in ($loader.which_mods(load $mods))
			{
				if (loader.load_module($module))
				{
					xecho -b Module [$module] has been successfully loaded
				}{
					xecho -b Error loading module [$module]
				}
			}
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

alias unloadmod (module, void)
{
	if (module)
	{
		if (loader.unload_module($module))
		{
			xecho -b Module [$module] has been successfully unloaded
		}{
			xecho -b Error unloading module [$module]
		}
	}{
		if (isnumber($module))
		{
			if (module > 0 && module <= numitems(loaded_modules))
			{
				@ :item = module - 1
				@ :mod = getitem(modules $item)

				if (loader.load_module($mod))
				{
					xecho -b Module [$mod] has been successfully loade
				}{
					xecho -b Error loading module [$mod]
				}
			}

			return
		}

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

		unless (tolower(mods) == [q])
		{
			for module in ($loader.which_mods(unload $mods))
			{
				if (loader.unload_module($module))
				{
					xecho -b Module [$module] has been successfully unloaded
				}{
					xecho -b Error unloading module [$module]
				}
			}
		}
	}
}


alias loader.build_modlist (void)
{
	@ delarray(modules)
	@ delarray(module_files)

	for dir in ($DS.MODULES)
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


alias loader.display_loaded (void)
{
	echo #   Module
	@ :endcnt = numitems(loaded_modules) - 1
	for cnt from 0 to $endcnt
	{
		@ :num = cnt + 1
		echo $[3]num $getitem(loaded_modules $cnt)
	}

	return
}

alias loader.display_modlist (void)
{
	echo #   Module                     Size (bytes)  Loaded  Auto-Load
	@ :endcnt = numitems(modules) - 1
	for cnt from 0 to $endcnt
	{
		@ :num = cnt + 1
		@ :file = getitem(module_files $cnt)
		@ :module = getitem(modules $cnt)
		@ :auto_load = common($module / $CONFIG.AUTO_LOAD_MODULES) ? [*] : []
		@ :loaded = finditem(loaded_modules $module) > -1 ? [*] : []
		echo $[3]num $[25]module $[-12]fsize($file)     $[8]loaded $[8]auto_load
	}
	xecho -b Type '/dset AUTO_LOAD' to modify the Auto-Load list
	xecho -b Type '/loadmod [module]' to load a module
	xecho -b Type '/unloadmod [module]' to unload a module

	return
}


alias loader.load_module (module, void)
{
	if (before(-1 . $module))
	{
		@ module = before(-1 . $module)
	}

	if (numitems(modules))
	{
		@ :file = getitem(module_files $finditem(modules $module)))

		if (finditem(modules $module) > -1 && finditem(loaded_modules $module) < 0)
		{
			@ :dir = before(-1 / $before(-1 / $file))
			^local defaults_file $dir/def/$module\.def
			^local savefile $DS.SAVE/$module\.sav

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
						(dset)
						(config)
						{
							if (word(1 $line) == [bool])
							{
								@ variable = word(2 $line)
								@ value = restw(3 $line)
								
								^assign DSET.BOOL.$variable 1
							}
							
							@ push(DSET.$module $variable)
							^assign DSET.CONFIG.$variable 1
							^assign CONFIG.$variable $value
						}

						(fset)
						(format)
						{
							@ push(FSET.$module $variable)
							^assign FSET.FORMAT.$variable 1
							^assign FORMAT.$variable $value
						}
					}
				}
			}
			
			@ close($fd)
					
			/* Load saved settings */
			if (fexist($savefile) == 1)
			{
				load $savefile
			}

			/* Load the bugger */
			load $file
			@ setitem(loaded_modules $numitems(loaded_modules) $module)

			return 1
		}
	}

	return 0
}


alias loader.unload_module (module)
{
	if (numitems(loaded_modules))
	{
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
			for var in ($DSET[$module])
			{
				^assign -CONFIG.$var
				^assign -DSET.CONFIG.$var
				^assign -DSET.BOOL.$var
			}
			
			for var in ($FSET[$module])
			{
				^assign -FORMAT.$var
				^assign -FSET.FORMAT.$var
			}

			^assign -DSET.$module
			^assign -FSET.$module
			
			/* Remove from loaded_modules array */
			@ delitem(loaded_modules $item)

			return 1
		}
	}

	return 0
}


alias loader.which_mods (action, args)
{
	if (args && isnumber($strip(- $args)))
	{
		^local modlist
		@ :array = action == [load] ? [modules] : [loaded_modules]

		for modnum in ($args)
		{
			if (match(%-% $modnum))
			{
				@ :startmod = before(- $modnum)
				@ :endmod = after(- $modnum)

				if (startmod < endmod && startmod < numitems($array) && endmod <= numitems($array))
				{
					for cnt from $startmod to $endmod
					{
						@ :item = cnt - 1
						@ :module = getitem($array $item)

						@ push(modlist $module)
					}
				}{
					xecho -b Illegal range specified!
				}
			}{
				if (modnum <= numitems($array))
				{
					@ :item = modnum - 1
					@ :module = getitem($array $item)

					@ push(modlist $module)
				}{
					xecho -b No such module [$modnum]
				}
			}
		}

		@ function_return = modlist
	}{
		if ([$0])
		{
			xecho -b \"$*\" is not valid
		}
	}

	return
}


/*
 * Find out what modules to load on startup.
 */
if (CONFIG[AUTO_LOAD_MODULES])
{
	/*
	 * Keep things quiet while we list available modules.
	 */
	for hook in (250 251 252 254 255 265 266)
	{
		^on ^$hook ^"*"
	}

	^stack push set SUPPRESS_SERVER_MOTD
	^set SUPPRESS_SERVER_MOTD ON

	/*
	 * Prompt user or go ahead and load everything on the auto-load list.
	 */
	if (CONFIG[AUTO_LOAD_PROMPT])
	{
		modlist

		input "Modules to load? ([A]uto / [N]one / 1 2-4 ...) [A] "
		{
			if ([$0] == [])
			{
				^assign ugh A
			}{
				^assign ugh $0
			}

			switch ($toupper($ugh))
			{
				(A)
				{
					xecho -b Auto-Loading modules...
					for module in ($CONFIG.AUTO_LOAD_MODULES)
					{
						if (loader.load_module($module))
						{
							xecho -b Module [$module] has been loaded successfully
						}{
							xecho -b Error loading module [$module]
						}
					}
					xecho -b Auto-Load completed [$strftime(%c)]

					theme $CONFIG.THEME
				}

				(N)
				{
					theme $CONFIG.THEME
				}

				(*)
				{ 
					for module in ($loader.which_mods(load $*))
					{
						if (loader.load_module($module))
						{
							xecho -b Module [$module] has been successfully loaded
						}{
							xecho -b Error loading module [$module]
						}
					}
					xecho -b Load complete [$strftime(%c)]

					theme $CONFIG.THEME
				}
			}

			@ ugh = []
		}
	}{
		@ loader.build_modlist()

		xecho -b Auto-Loading modules...
		for module in ($CONFIG.AUTO_LOAD_MODULES)
		{
			if (loader.load_module($module))
			{
				xecho -b Module [$module] has been loaded successfully
			}{
				xecho -b Error loading module [$module]
			}
		}
		xecho -b Auto-Load completed [$strftime(%c)]

		theme $CONFIG.THEME
	}
	
	/*
	 * Cleanup after ourselves.
	 */
	wait -cmd for hook in (250 251 252 254 255 265 266)
	{
		^on ^$hook -"*"
	}

	^stack pop set SUPPRESS_SERVER_MOTD
}	


/* bmw '01 */