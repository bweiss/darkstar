/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * THEMES.DSC - Theme support for Darkstar/EPIC4
 * Author: Brian Weiss <brian@epicsol.org> - 2001
 *
 * Last modified: 10/15/01 (bmw)
 */

/*
 * /THEME [newtheme]
 * Changes the current theme. If [newtheme] is not specified the list of
 * available themes will be displayed and the user will be prompted to choose
 * one, either by name or number.
 */
alias theme (theme, void)
{
	/*
	 * Find available themes and dump them in the themes array.
	 */
	@ delarray(themes)

	for dir in ($DS.THEMES)
	{
		@ :dir = twiddle($dir)
		for file in ($glob($dir\/\*.dst))
		{
			@ :name = before(. $after(-1 / $file))
			@ setitem(themes $numitems(themes) $name $file)
		}
	}


	if (theme)
	{
		switch ($theme.change($theme))
		{
			(0) {xecho -b Error: Theme not found.}
			(1) {xecho -b Now using theme: $DS.THEME}
		}
	}{
		if (DS.THEME) xecho -b Current theme: $DS.THEME
		xecho -b Available themes:
		echo #   Theme
		for cnt from 0 to ${numitems(themes) - 1}
		{
			@ :num = cnt + 1
			echo $[3]num $word(1 $getitem(themes $cnt))
		}

		input "$INPUT_PROMPT\Which theme would you like to use? " if ([$0])
		{
			if (isnumber($0) && [$0] > 0 && [$0] <= numitems(themes))
			{
				switch ($theme.change($getitem(themes ${[$0] - 1})))
				{
					(0) {xecho -b Error: Theme not found.}
					(1) {xecho -b Now using theme: $DS.THEME}
				}
			} \
			elsif (matchitem(themes $0*) > -1)
			{
				switch ($theme.change($0))
				{
					(0) {xecho -b Error: Theme not found.}
					(1) {xecho -b Now using theme: $DS.THEME}
				}
			}{
				xecho -b Error: Invalid theme.
			}
		}
	}
}

alias theme.change (theme, void)
{
	@ :item = matchitem(themes $theme*)

	if (item > -1)
	{
		@ :theme_file = word(1 $getitem(themes $item))

		if (fexist($theme_file) == 1)
		{
			//load $theme_file
			^assign DS.THEME $theme
			return 1
		}
	}

	return 0
}


/* bmw '01 */