/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * THEMES.DSC - Theme support for Darkstar/EPIC4
 * Author: Brian Weiss <brian@epicsol.org> - 2001
 *
 * Last modified: 12/29/01 (bmw)
 *
 * This script uses serial number 1 for all ON hooks.
 */

/*
 * /THEME [newtheme]
 * Changes the current theme. If [newtheme] is not specified the list of
 * available themes will be displayed and the user will be prompted to choose
 * one, either by name or number.
 */
alias theme (theme, void)
{
	@ themes.buildlist()

	/*
	 * Create a temporary alias that will call the actual change() function.
	 * This helps with the /input stuff.
	 */
	^alias _change_theme (theme, void)
	{
		switch ($themes.change($theme))
		{
			(0) {xecho -b Now using theme: $DS.THEME}
			(1) {xecho -b ERROR: Invalid theme [$theme]}
			(2) {xecho -b ERROR: Theme directory not found}
			(*) {xecho -b ERROR: Unknown}
		}

		defer ^alias -_change_theme
	}

	/* Find the name of the desired theme and execute _change_theme. */
	if (!theme)
	{
		@ themes.display()
		input "$INPUT_PROMPT\Which theme would you like to use? " if ([$0])
		{
			if (isnumber($0) && [$0] > 0 && [$0] <= numitems(themes))
			{
				_change_theme $getitem(themes ${[$0] - 1})
			}{
				_change_theme $0
			}
		}
	} \
	elsif (isnumber($theme))
	{
		if (theme > 0 && theme <= numitems(themes))
		{
			@ :item = theme - 1
			_change_theme $getitem(theme $item)
		}
	}{
		_change_theme $theme
	}
}

/*
 * themes.buildlist() - Scans the theme directories and stores available themes
 * in two arrays. One for theme names (themes) and one for theme files
 * (theme_files). Does not take any arguments. Returns nothing.
 */
alias themes.buildlist (void)
{
	@ delarray(themes)
	@ delarray(theme_files)

	for dir in ($DS.THEME_DIR)
	{
		@ :dir = twiddle($dir)
		if (fexist($dir) == 1)
		{
			for t_dir in ($glob($dir\/\*))
			{
				@ :name = after(-1 / $before(-1 / $t_dir))
				if (finditem(themes $name) > -1)
				{
					xecho -b themes.buildlist(): Duplicate theme name: $name
				}{
					@ :t_file = t_dir ## name ## [.dst]
					if (fexist($t_file) == 1)
					{
						@ setitem(themes $numitems(themes) $name)
						@ setitem(theme_files $numitems(theme_files) $t_dir)
					}
				}
			}
		}
	}

	return
}

/*
 * themes.change() - Attempts to change the current theme. Takes a theme
 * name as its only argument. Returns "0" if successful, "1" if not.
 */
alias themes.change (theme, void)
{
	@ :item = finditem(themes $theme)
	if (item > -1)
	{
		@ :dir = getitem(theme_files $item)
		if (fexist($dir) == 1)
		{
			@ :t_file = dir ## theme ## [.dst]
			load $t_file

			for cnt from 0 to ${numitems(loaded_modules) - 1}
			{
				@ :module = getitem(loaded_modules $cnt)
				@ :file = dir ## module
				if (fexist($file) == 1)
				{
					load $file
				}
			}

			^assign DS.THEME $theme
			^assign CONFIG.THEME $theme
			return 0
		}

		return 2
	}

	return 1
}

/*
 * themes.display() - Displays the current list of themes. Takes no arguments
 * and returns nothing.
 */
alias themes.display (void)
{
	xecho -b Current theme: $DS.THEME
	xecho -b Available themes:
	echo #   Theme
	for cnt from 0 to ${numitems(themes) - 1}
	{
		@ :num = cnt + 1
		echo $[3]num $getitem(themes $cnt)
	}

	return
}


/*
 * Change themes on /DSET THEME.
 */
on #-hook 1 "CONFIG THEME *"
{
	if ([$2] != DS[THEME])
	{
		/* If our theme change fails, set THEME back to previous value. */
		if (themes.change($CONFIG.THEME))
		{
			xecho -b Invalid theme.
			xecho -b Value of THEME set back to $DS.THEME
			dset THEME $DS.THEME
		}
	}
}


eval theme $CONFIG.THEME


/* bmw '01 */