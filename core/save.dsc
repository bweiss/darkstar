/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * SAVE.DSC - Save /CONFIG and /FSET settings for Darkstar/EPIC4
 * Author: Brian Weiss <brian@epicsol.org> - 2001
 */

alias save (args)
{
	^local abort
	
	/* Find our save directory */
	^local savedir
	
	switch ($word(0 $args))
	{
		(-d)
		{
			@ savedir = $twiddle($word(1 $args))
			@ args = restw(2 $args)
		}
		(*)
		{
			@ savedir = CONFIG[SAVE_DIRECTORY]
		}
	}
	
	/* Find out what modules to save settings for */
	if (word(0 $args) == [*] ^^ !args)
	{
		/* Save everything! */
		@ push(modules core)
		for cnt from 0 to ${$numitems(loaded_modules) - 1}
		{
			@ push(modules $getitem(loaded_modules $cnt))
		}
	}{
		/* Save only what's specified by user */
		for module in ($args)
		{
			if (finditem(loaded_modules $module) ^^ module == [core])
			{
				@ push(modules $module)
			}{
				xecho -b SAVE: ERROR - $module is not loaded.
			}
		}
	}	

	for module in ($modules)
	{
		@ save_settings($savedir $module)
	}
		
	/* Find our save directory */
	^local savedir

	switch ($word(0 $args))
	{
		(-d)
		{
			@ savedir = $twiddle($word(1 $args))
			@ args = restw(2 $args)
		}
		(*)
		{
			@ savedir = CONFIG[SAVE_DIRECTORY]
		}
	}
                                                                                                                                                            
	/* Create our save directory if it does not already exist */
	if (fexist($savedir) == -1)
	{
		xecho -b No save directory found. Creating $savedir ...
		
		if (mkdir($savedir) > 0)
		{
			xecho -b Error creating directory [$savedir]
			xecho -b Aborting save...

			^assign abort 1
		}
	}

	unless (abort)
	{
		xecho -b Saving settings to [$savedir] ...
		
		for module in ($modules)
		{
			@ save_settings($savedir $module)
		}

		xecho -b Save completed [$strftime(%c)]
	}
}


alias save_settings(savedir, module, void)
{
	^local savefile $savedir/$module\.sav

	if (fexist($savefile) == 1)
	{
		@ unlink($savefile)
	}
		
	@ :fd = open($savefile W)
		
	if (fd != -1)
	{
		@ write($fd ## Last save: $strftime(%c))
			
		eval for var in \(\$$aliasctl(assign match DSET.$module)\)
		{
			@ :value = aliasctl(assign get CONFIG.$var)

			if (value != [])
			{
				@ write($fd assign CONFIG.$var $value)
			}{
				@ write($fd assign -CONFIG.$var)
			}
		}
			
		eval for var in \(\$$aliasctl(assign match FSET.$module)\)
		{
			@ :value = aliasctl(assign get FORMAT.$var)
			
			if (value != [])
			{
				@ write($fd assign FORMAT.$var $value)
			}{
				@ write($fd assign -FORMAT.$var)
			}
		}
			
		if (CONFIG[VERBOSE_SAVE])
		{
			xecho -b Settings for [$module] saved to [$savefile]
		}
	}{
		xecho -b Error opening savefile [$savefile]
	}

	@ close($fd)
}


/* bmw '01 */