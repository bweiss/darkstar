/* $Id$ */
/*
 * themes.dsc - Change themes
 * Copyright (c) 2002 Brian Weiss
 * See the 'COPYRIGHT' file for more information.
 */

/****** USER ALIASES ******/

/*
 * /THEME [newtheme]
 * Changes the current theme. If [newtheme] is not specified the list of
 * available themes will be displayed and the user will be prompted to
 * choose one, either by name or number.
 */
alias theme (theme, void) {
	themes.buildlist
	if (!theme) {
		themes.display
		^local theme $"Which theme would you like to use? "
		if (!theme) {
			return
		}
	}
	if (isnumber($theme) && theme > 0 && theme <= numitems(themes)) {
		@ :item = theme - 1
		@ :theme = getitem(themes $item)
	}
	switch ($themes.change($theme)) {
		(0) { xecho -b Now using theme: $DS.THEME; }
		(1) { echo Error: themes.change\(\): Not enough arguments; }
		(2) { echo Error: themes.change\(\): Theme not found: $theme; }
		(3) { echo Error: themes.change\(\): Master theme file not found; }
		(*) { echo Error: themes.change\(\): Unknown; }
	}
}


/****** INTERNAL ALIASES ******/

/*
 * Scans the theme directories and stores available themes in two arrays,
 * one for theme names (themes) and one for theme directories (theme_dirs).
 */
alias themes.buildlist (void) {
	@ delarray(themes)
	@ delarray(theme_dirs)
	for dir in ($DS.THEME_DIR) {
		^local dir $twiddle($dir)
		if (fexist($dir) == 1) {
			for tdir in ($glob($dir\/\*)) {
				^local name $after(-1 / $before(-1 / $tdir))
				if ((:item = finditem(themes $name)) > -1) {
					@ delitem(themes $item)
					@ delitem(theme_dirs $item)
				}
				if (fexist($tdir/main.dst) == 1) {
					@ setitem(themes $numitems(themes) $name)
					@ setitem(theme_dirs $numitems(theme_dirs) $tdir)
				}
			}
		}
	}
}

/*
 * Attempts to change the current theme.
 * Returns 0 if successful or > 0 if not.
 */
alias themes.change (theme, void) {
	if (!theme) {
		/* Not enough arguments */
		return 1
	}
	if ((:t_item = finditem(themes $theme)) > -1) {
		^local dir $getitem(theme_dirs $t_item)
		^local master_file $dir/main.dst
		if (fexist($master_file) == 1) {
			load $master_file
			for cnt from 0 to ${numitems(loaded_modules) - 1} {
				^local module $getitem(loaded_modules $cnt)
				^local file $dir/$module
				if (fexist($file) == 1) {
					load $file
				}
			}
			@ DS.THEME = theme
			@ CONFIG.THEME = theme
			return 0
		}
		/* Master theme file not found */
		return 3
	}
	/* Theme not found */
	return 2
}

alias themes.display (void) {
	themes.buildlist
	xecho -b Current theme: $DS.THEME
	xecho -b Available themes:
	for cnt from 0 to ${numitems(themes) - 1} {
		@ :num = cnt + 1
		echo $[3]num $getitem(themes $cnt)
	}
}


/****** ON HOOKS ******/

/*
 * Change themes on /DSET THEME
 */
on #-hook 1 "CONFIG THEME *" {
	if (ascii($CONFIG.THEME) != ascii($2)) {
		if (themes.change($CONFIG.THEME)) {
			xecho -b Invalid theme: $CONFIG.THEME
			^assign CONFIG.THEME $2
			xecho -b Value of THEME set to $2
		}
	}
}


/****** STARTUP ******/

eval theme $CONFIG.THEME


/* EOF */