/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * LOADER.DSC - Module loader for Darkstar/EPIC4
 * Author: Brian Weiss <brian@epicsol.org> - 2001
 */

alias build_modlist (void)
{
	@ delarray(modules)

	for fname in ($glob($DS.MODULE_DIR\/\*.dsm))
	{
		@ :module = before(. $after(-1 / $fname))
		@ setitem(modules $numitems(modules) $module)
	}

	return
}

alias display_loaded (void)
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

alias display_modlist (void)
{
	echo #   Module                     Size (bytes)  Loaded  Auto-Load
	@ :endcnt = numitems(modules) - 1
	for cnt from 0 to $endcnt
	{
		@ :num = cnt + 1
		@ :module = getitem(modules $cnt)
		@ :auto_load = common($module / $CONFIG.AUTO_LOAD_MODULES) ? [*] : []
		@ :loaded = finditem(loaded_modules $module) > -1 ? [*] : []
		echo $[3]num $[25]module $[-12]fsize($DS.MODULE_DIR/$module\.dsm)     $[8]loaded $[8]auto_load
	}
	xecho -b Type '/dset AUTO_LOAD' to modify the Auto-Load list
	xecho -b Type '/loadmod [module]' to load a module
	xecho -b Type '/unloadmod [module]' to unload a module

	return
}

alias listmods modlist

alias load_module (module, void)
{
	if (numitems(modules))
	{
		if (finditem(modules $module) > -1 && finditem(loaded_modules $module) < 0)
		{
			^local defaults_file $DS.DEFAULTS_DIR/$module\.def
			^local savefile $DS.SAVE_DIR/$module\.sav

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
						(config)
						{
							if (word(1 $line) == [lit])
							{
								@ variable = word(2 $line)
								@ value = restw(3 $line)
								
								^assign DSET.LIT.$variable 1
							}
							
							@ push(DSET.$module $variable)
							^assign DSET.CONFIG.$variable 1
							^assign CONFIG.$variable $value
						}
						(fset)
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
			load $DS.MODULE_DIR/$module\.dsm
			@ setitem(loaded_modules $numitems(loaded_modules) $module)

			return 1
		}
	}

	return 0
}


alias loadmod (module, void)
{
	if (module && !isnumber($module))
	{
		if (load_module($module))
		{
			xecho -b Module [$module] has been successfully loaded
		}{
			xecho -b Error loading module [$module]
		}
	}{
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
			for module in ($which_mods(load $mods))
			{
				if (load_module($module))
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
	@ build_modlist()
	@ display_modlist()
}

alias modules modlist

alias reloadmod (module, void)
{
	unloadmod $module
	loadmod $module
}

alias unload_module (module)
{
	if (numitems(loaded_modules))
	{
		@ :itm = finditem(loaded_modules $module)
		if (itm > -1)
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

			/* Remove all dset/fset variables */
			for var in ($DSET\.$module)
			{
				^assign -CONFIG.$var
				^assign -DSET.CONFIG.$var
				^assign -DSET.LIT.$var
			}
			
			for var in ($FSET\.$module)
			{
				^assign -FORMAT.$var
				^assign -DSET.FORMAT.$var
			}

			^assign -DSET.$module
			^assign -FSET.$module
			
			@ delitem(loaded_modules $itm)

			return 1
		}
	}

	return 0
}

alias unloadmod (module, void)
{
	if (module)
	{
		if (unload_module($module))
		{
			xecho -b Module [$module] has been successfully unloaded
		}{
			xecho -b Error unloading module [$module]
		}
	}{
		^local mods

		@ display_loaded()

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
			for module in ($which_mods(unload $mods))
			{
				if (unload_module($module))
				{
					xecho -b Module [$module] has been successfully unloaded
				}{
					xecho -b Error unloading module [$module]
				}
			}
		}
	}
}


alias which_mods (action, args)
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
						@ :itm = cnt - 1
						@ :module = getitem($array $itm)

						@ push(modlist $module)
					}
				}{
					xecho -b Illegal range specified!
				}
			}{
				if (modnum <= numitems($array))
				{
					@ :itm = modnum - 1
					@ :module = getitem($array $itm)

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
		return
	}
}


/* Find out what modules to load on startup */
if (CONFIG[AUTO_LOAD_MODULES])
{
	^local dont_suppress_motd

	/* Keep /lusers quiet while we list available modules */
	for hook in (250 251 252 254 255 265 266)
	{
		^on ^$hook ^"*"
	}

	if (SUPPRESS_SERVER_MOTD == [OFF])
	{
		^set SUPPRESS_SERVER_MOTD ON
		^assign dont_suppress_motd 1
	}

	modlist

	if (CONFIG[AUTO_LOAD_PROMPT])
	{
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
						if (load_module($module))
						{
							xecho -b Module [$module] has been loaded successfully
						}{
							xecho -b Error loading module [$module]
						}
					}
					xecho -b Auto-Load completed [$strftime(%c)]
				}
				(N) { # Do nuh-thing! }
				(*)
				{ 
					for module in ($which_mods(load $*))
					{
						if (load_module($module))
						{
							xecho -b Module [$module] has been successfully loaded
						}{
							xecho -b Error loading module [$module]
						}
					}
					xecho -b Load complete [$strftime(%c)]
				}
			}

			@ ugh = []
		}
	}{
		xecho -b Auto-Loading modules...
		for module in ($CONFIG.AUTO_LOAD_MODULES)
		{
			if (load_module($module))
			{
				xecho -b Module [$module] has been loaded successfully
			}{
				xecho -b Error loading module [$module]
			}
		}
		xecho -b Auto-Load completed [$strftime(%c)]
	}
	
	wait -cmd for hook in (250 251 252 254 255 265 266)
	{
		^on ^$hook -"*"
	}

	if (dont_suppress_motd)
	{
		^set SUPPRESS_SERVER_MOTD OFF
	}
}	


/* bmw '01 */