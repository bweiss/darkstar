/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * SAVE.DSC - Save /CONFIG and /FSET settings for Darkstar/EPIC4
 * Author: Brian Weiss <brian@epicsol.org> - 2001
 *
 * Last modified: 12/22/01 (bmw)
 */

/*
 * /SAVE [-d <directory>] [*|modules]
 * Saves all settings for specified module(s) to either $DS.SAVE_DIR or a
 * directory specified with the -d option. If no modules are specified,
 * "*" (ALL) is assumed and the settings for every currently loaded module
 * will be saved.
 */
alias save (args)
{
	^local modules,save_dir
	
	/*
	 * Find our save directory.
	 */
	switch ($word(0 $args))
	{
		(-d)
		{
			@ save_dir = twiddle($word(1 $args))
			@ args = restw(2 $args)
		}
		(*)
		{
			@ save_dir = twiddle($DS.SAVE_DIR)
		}
	}
	
	/*
	 * Find out what modules to save settings for.
	 */
	if (!args || word(0 $args) == [*])
	{
		/* Save everything! */
		@ push(modules core)
		for cnt from 0 to ${numitems(loaded_modules) - 1}
		{
			@ push(modules $getitem(loaded_modules $cnt))
		}
	}{
		/* Save only what's specified by user. */
		for module in ($args)
		{
			if (finditem(loaded_modules $module) > -1 || module == [core])
			{
				@ push(modules $module)
			}
		}
	}	

	/*
	 * Check our save directory and create it if necessary.
	 */
	if (fexist($save_dir) == -1)
	{
		xecho -b No save directory found. Creating [$save_dir] ...
		
		if (mkdir($save_dir) > 0)
		{
			xecho -b Error creating directory [$save_dir]
			xecho -b Aborting save...
			return
		}
	}

	xecho -b Saving settings to [$save_dir] ...

	/*
	 * Save our config settings (/DSET)
	 */
	for module in ($modules)
	{
		switch ($save.save_config($save_dir $module))
		{
			(0) {if (CONFIG[VERBOSE_SAVE]) {xecho -b Settings for [$module] saved to [$save_dir/$module\.sav]}}
			(*) {xecho -b Error saving settings for [$module]}
		}
	}

	/*
	 * Save our format settings (/FSET)
	 */
	@ :fmt_file = save.save_formats($save_dir $modules)

	if (fmt_file)
	{
		if (CONFIG[VERBOSE_SAVE]) {xecho -b Format settings saved to [$fmt_file]}
	}{
		xecho -b Error writing formats file [$fmt_file]
	}

	xecho -b Save completed [$strftime(%c)]
}

/*
 * save_config() - Saves config settings to specified directory. Takes a
 * directory and module name as arguments. Returns "0" if successful or "1"
 * if unsuccessful.
 */
alias save.save_config (save_dir, module, void)
{
	if (!save_dir || !module)
	{
		xecho -b save_config(): Not enough arguments.
		return 1
	}

	^local save_file $save_dir/$module\.sav

	@ unlink($save_file)
	@ :fd = open($save_file W)
		
	if (fd != -1)
	{
		@ write($fd ## Generated by Darkstar $DS.VERSION \($DS.INTERNAL_VERSION\): $strftime(%c))
			
		@ :variables = aliasctl(assign get DSET.MODULES.$module)

		for var in ($variables)
		{
			@ :value = aliasctl(assign get CONFIG.$var)

			if (value != [])
			{
				@ write($fd assign CONFIG.$var $value)
			}{
				@ write($fd assign -CONFIG.$var)
			}
		}
	}{
		return 1
	}

	@ close($fd)
	return 0
}

/*
 * save.save_formats() - Writes format settings to $DS.USER_DIR/themes/custom.dst.
 * Takes a list of modules as arguments. Returns the filename if successful
 * or "0" if unsuccessful.
 */
alias save.save_formats (modules)
{
	if (!modules)
	{
		xecho -b save_formats(): Not enough arguments.
		return 0
	}

	^local save_file $DS.USER_DIR/themes/custom.dst

	@ unlink($save_file)
	@ :fd = open($save_file W)

	if (fd != -1)
	{
		@ write($fd ## Generated by Darkstar $DS.VERSION \($DS.INTERNAL_VERSION\): $strftime(%c))
		@ write($fd  )
		@ write($fd  )
		@ write($fd status -q $DS.SBAR)
		@ write($fd )
		@ write($fd set BANNER $BANNER)
		@ write($fd  )

		for module in ($modules)
		{
			@ :variables = aliasctl(assign get FSET.MODULES.$module)

			if (variables)
			{
				@ write($fd # Module: $module)

				for var in ($variables)
				{
					@ :value = aliasctl(assign get FORMAT.$var)

					if (value != [])
					{
						@ write($fd fset $var $value)
					}{
						@ write($fd fset -$var)
					}
				}

				@ write($fd  )
			}
		}
	}{
		return 0
	}

	@ close($fd)
	return $save_file
}


/* bmw '01 */