/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * STATUS.DSC - Statbar manager for Darkstar/EPIC4
 * Author: Brian Weiss <brian@epicsol.org> - 2001
 *
 * Last modified: 12/29/01 (bmw)
 */

alias sbar status
alias statbar status

/*
 * /STATUS [-q] [statbarname]
 * Attempts to change the current status bar. If [statbarname] is not specified
 * the user will be prompted to choose one from a list. The 'q' option tells
 * /status to be silent about the change. This was mostly added so that themes
 * could change statbars quietly.
 */
alias status (args)
{
	^local sbar,quiet

	/* Check for quiet option. */
	if (left(1 $word(0 $args)) == [-])
	{
		@ sbar = word(1 $args)
		if (word(0 $args) == [-q])
		{
			^assign quiet 1
		}
	}{
		@ sbar = args
	}

	@ status.buildlist()

	/*
	 * Create a temporary alias that will call the actual change() function.
	 * This helps with the /input stuff.
	 */
	^alias _change_status (sbar, quiet, void)
	{
		switch ($status.change($sbar))
		{
			(0) {if (!quiet) {xecho -b Now using status: $sbar}}
			(*) {xecho -b Unable to load status [$sbar]}
		}

		defer ^alias -_change_status
	}

	/* Find the name of the desired statbar and execute _change_status. */
	if (!sbar)
	{
		@ status.display()
		input "$INPUT_PROMPT\Which status bar would you like to use? " if ([$0])
		{
			if (isnumber($0) && [$0] > 0 && [$0] <= numitems(status))
			{
				@ :item = [$0] - 1
				_change_status $getitem(status $item)
			}{
				_change_status $0
			}
		}
	} \
	elsif (isnumber($sbar))
	{
		if (sbar > 0 && sbar <= numitems(status))
		{
			@ :item = sbar - 1
			_change_status $getitem(status $item) $quiet
		}
	}{
		_change_status $sbar $quiet
	}
}


/*
 * status.buildlist() - Scans the status directories and dumps all available
 * statbars into an array containing the name (status) and an array containing
 * the complete filename (status_files). Returns nothing.
 */
alias status.buildlist (void)
{
	@ delarray(status)
	@ delarray(status_files)

	for dir in ($DS.STATUS_DIR)
	{
		@ :dir = twiddle($dir)
		if (fexist($dir) == 1)
		{
			for file in ($glob($dir\/\*))
			{
				@ :lastc = mid(${strlen($file) - 1} 1 $file)
				unless (lastc == [/])
				{
					@ :name = after(-1 / $file)
					@ setitem(status $numitems(status) $name)
					@ setitem(status_files $numitems(status_files) $file)
				}
			}
		}
	}

	return
}

/*
 * status.change() - Everything involved with actually changing the status.
 * Takes a status name as its only argument. Returns "0" if successful,
 * "1" if not.
 */
alias status.change (sbar, void)
{
	@ :item = finditem(status $sbar)
	if (item > -1)
	{
		@ :file = getitem(status_files $item)
		if (fexist($file) == 1)
		{
			load $file
			parsekey refresh_screen
			^assign DS.SBAR $after(-1 / $file)

			return 0
		}
	}

	return 1
}

/*
 * status.display() - Displays the current list of status bars. Takes no
 * arguments and returns nothing.
 */
alias status.display (void)
{
	xecho -b Available status bars:
	for cnt from 0 to ${numitems(status) - 1}
	{
		@ :name = getitem(status $cnt)
		@ :num = cnt + 1
		echo $[3]num $name
	}

	return
}


/* bmw '01 */