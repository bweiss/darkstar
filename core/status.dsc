/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * STATUS.DSC - Statbar manager for Darkstar/EPIC4
 * Author: Brian Weiss <brian@epicsol.org> - 2001
 *
 * Last modified: 8/30/01 (bmw)
 */

alias sbar status
alias statbar status

/*
 * /STATUS [statbarname]
 * Scans $DS.STATUS_DIR for statbar files and changes to [statbar]
 * if it exists. If no statbar is specified, the list of available choices
 * will be displayed and the user will be prompted to choose one. Either
 * literal statbar names or a number corresponding to the desired statbar
 * will be accepted.
 */
alias status (sbar, void)
{
	^local sfiles

	/*
	 * Build our list of available statbars and store them in $sfiles.
	 * Directories are ignored.
	 */
	for file in ($glob($DS.STATUS_DIR\/\*))
	{
		@ :lastc = mid(${strlen($file) - 1} 1 $file)

		unless (lastc == [/])
		{
			@ push(sfiles $after(-1 / $file))
		}
	}

	if (sbar && match($sbar $sfiles))
	{
		@ change_status($sbar)
	}{
		^local cnt 1

		xecho -b Available status bars:
		for file in ($sfiles)
		{
			xecho -b [$[-3]cnt] $file
			@ cnt++
		}

		@ STATUS.SFILES = sfiles

		input "Which status bar would you like to use? "
		{
			if (isdigit($0) && [$0] > 0 && [$0] <= #STATUS.SFILES)
			{
				@ change_status($word(${[$0] - 1} $STATUS.SFILES))
			} \
			elsif (match($0 $STATUS.SFILES))
			{
				@ change_status($0)
			}

			^assign -STATUS.SFILES
		}
	}
}

/*
 * change_status() - Everything involved with actually changing the status.
 * Takes a filename as its only argument. Must be a valid file in
 * $DS.STATUS_DIR.
 */
alias change_status (file, void)
{
	if (file)
	{
		load $DS.STATUS_DIR/$file
		parsekey refresh_screen
		xecho -b Now using status: $file
		return 1
	}{
		return 0
	}
}


/* bmw '01 */