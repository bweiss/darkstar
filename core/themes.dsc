/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * THEMES.DSC - Theme support for Darkstar/EPIC4
 * Author: Brian Weiss <brian@epicsol.org> - 2001
 *
 * Last modified: 12/21/01 (bmw)
 *
 * This script uses serial number 1 for ALL /on hooks.
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

	if (theme)
	{
		switch ($theme.change($theme))
		{
			(0) {xecho -b Now using theme: $DS.THEME}
			(*) {xecho -b Error: Theme not found.}
		}
	}{
		if (DS.THEME) xecho -b Current theme: $DS.THEME
		xecho -b Available themes:
		echo #   Theme
		for cnt from 0 to ${numitems(themes) - 1}
		{
			@ :num = cnt + 1
			echo $[3]num $getitem(themes $cnt)
		}

		input "$INPUT_PROMPT\Which theme would you like to use? " if ([$0])
		{
			if (isnumber($0) && [$0] > 0 && [$0] <= numitems(themes))
			{
				switch ($theme.change($getitem(themes ${[$0] - 1})))
				{
					(0) {xecho -b Now using theme: $DS.THEME}
					(*) {xecho -b Error: Theme not found.}
				}
			} \
			elsif (finditem(themes $0) > -1)
			{
				switch ($theme.change($0))
				{
					(0) {xecho -b Now using theme: $DS.THEME}
					(*) {xecho -b Error: Theme not found.}
				}
			}{
				xecho -b Error: Invalid theme.
			}
		}
	}
}

/*
 * theme.buildlist() - Scans the theme directories and stores available themes
 * in two arrays. One for theme names (themes) and one for theme files
 * (theme_files). Does not take any arguments. Returns "1" if successful, and
 * "0" if not.
 */
alias themes.buildlist (void)
{
	@ delarray(themes)
	@ delarray(theme_files)

	for dir in ($DS.THEMES)
	{
		@ :dir = twiddle($dir)

		if (fexist($dir) == 1)
		{
			for file in ($glob($dir\/\*.dst))
			{
				@ :name = before(. $after(-1 / $file))

				if (finditem(themes $name) > -1)
				{
					xecho -b themes.buildlist(): Duplicate theme name: $name
				}{
					@ setitem(themes $numitems(themes) $name)
					@ setitem(theme_files $numitems(theme_files) $file)
				}
			}
		}
	}

	return
}

/*
 * themes.change() - Attempts to change the current theme. Takes a theme
 * name as its only argument. Returns "1" if successful, "0" if not.
 */
alias theme.change (theme, void)
{
	@ :item = finditem(themes $theme)

	if (item > -1)
	{
		@ :file = getitem(theme_files $item)

		if (fexist($file) == 1)
		{
			//load $file
			^assign DS.THEME $theme
			^assign CONFIG.THEME $theme
			return 0
		}
	}

	return 1
}


/*
 * Change themes on /DSET THEME.
 */
on #-hook 1 "CONFIG THEME %"
{
	if ([$2] != DS[THEME])
	{
		/* If our theme change fails, set THEME back to previous value. */
		if (theme.change($CONFIG.THEME))
		{
			xecho -b Invalid theme.
			xecho -b Value of THEME set back to $DS.THEME
			dset THEME $DS.THEME
		}
	}
}


/* bmw '01 */