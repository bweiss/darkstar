/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * SAVE.DSC - Save /CONFIG and /FSET settings for Darkstar/EPIC4
 * Author: Brian Weiss <brian@epicsol.org> - 2001
 */

alias save (savedir default "$DS.SAVE_DIR", void)
{
	if (fexist($savedir) == -1)
	{
		xecho -b No save directory found. Creating $savedir ...
		
		if (mkdir($savedir) > 0)
		{
			xecho -b Error creating directory [$savedir]
			xecho -b Aborting save...

			return
		}
	}

	xecho -b Saving all settings to [$savedir] ...

	@ :endcnt = numitems(loaded_modules)
	
	for cnt from 0 to $endcnt
	{
		^local module
		
		if (cnt == endcnt)
		{
			^assign module core
		}{
			@ module = getitem(loaded_modules $cnt)
		}

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

	xecho -b Save completed [$strftime(%c)]
}


/* bmw '01 */