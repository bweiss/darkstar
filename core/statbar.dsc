/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * STATBAR.DSC - Statbar manager for Darkstar/EPIC4
 * Author: Brian Weiss <brian@got.net> - 2001
 */

alias sbar statbar

alias statbar (num, void)
{
	@ :statbar_files = glob($DS.STATBAR_DIR\/\statbar.*)

	if (isnumber($num))
	{
		if (num && num <= #statbar_files)
		{
			load $DS.STATBAR_DIR/statbar.$num
			parsekey refresh_screen
			xecho -b Now using status bar [$num]
		}{
			xecho -b Usage: /statbar <1-$#statbar_files>
		}
	}{
		xecho -b Usage: /statbar <1-$#statbar_files>
	}
}

if (CONFIG[DEFAULT_STATUS])
{
	statbar $CONFIG.DEFAULT_STATUS
}


/* bmw '01 */