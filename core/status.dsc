/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * STATUS.DSC - Statbar manager for Darkstar/EPIC4
 * Author: Brian Weiss <brian@epicsol.org> - 2001
 *
 * Last modified: 10/11/01 (bmw)
 */

alias sbar status
alias statbar status

/*
 * /STATUS [statbarname] [verbosity]
 * Scans $DS.STATUS_DIR for statbar files and changes to [statbar]
 * if it exists. If no statbar is specified, the list of available choices
 * will be displayed and the user will be prompted to choose one. Either
 * literal statbar names or a number corresponding to the desired statbar
 * will be accepted. The [verbosity] argument determines whether or not
 * we echo a message to the screen notifying the user of the status change.
 * This was mostly added so that themes could change statbars quietly.
 */
alias status (sbar, verbosity default "1", void)
{
	/*
	 * Build our list of available statbars and store them in $sfiles.
	 * Directories are ignored.
	 */
	@ delarray(status)

	for dir in ($DS.STATUS)
	{
		@ :dir = twiddle($dir)
		for file in ($glob($dir\/\*))
		{
			@ :lastc = mid(${strlen($file) - 1} 1 $file)
			unless (lastc == [/])
			{
				@ :name = after(-1 / $file)
				@ setitem(status $numitems(status) $name $file)
			}
		}
	}

	if (sbar && !isnumber($sbar))
	{
		@ :item = matchitem(status $sbar*)
		@ :file = word(1 $getitem(status $item))
		@ status.change($file $verbosity)
	} \
	elsif (isnumber($sbar) && sbar > 0 && sbar <= numitems(status))
	{
		@ :item = sbar - 1
		@ :file = word(1 $getitem(status $item))
		@ status.change($file $verbosity)
	}{
		xecho -b Available status bars:
		for cnt from 0 to ${numitems(status) - 1}
		{
			@ :num = cnt + 1
			echo $[3]num $word(1 $getitem(status $cnt))
		}

		input "$INPUT_PROMPT\Which status bar would you like to use? "
		{
			if (isnumber($0) && [$0] > 0 && [$0] <= numitems(status))
			{
				@ :item = [$0] - 1
				@ :file = word(1 $getitem(status $item))
				@ status.change($file $verbosity)
			} \
			elsif (matchitem(status $0*))
			{
				@ :file = word(1 $getitem(status $matchitem(status $0*)))
				@ status.change($file $verbosity)
			}
		}
	}
}

/*
 * status.change() - Everything involved with actually changing the status.
 * Takes a filename as its only argument.
 */
alias status.change (file, verbosity, void)
{
	if (fexist($file) == 1)
	{
		load $file
		parsekey refresh_screen

		if (verbosity)
		{
			xecho -b Now using status: $after(-1 / $file)
		}

		return 1
	}{
		return 0
	}
}


/* bmw '01 */