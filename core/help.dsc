/* $Id$ */
/*
 * help.dsc - Help browser for DarkStar/EPIC4
 * Copyright (c) 2002 Tyler Hall
 * Copyright (c) 2003 Brian Weiss
 * See the 'COPYRIGHT' file for more information.
 */

alias dhelp (...)
{
	@ :old_path = HELP_PATH
	^set HELP_PATH $twiddle($DS.HELP_DIR)
	if (@ && HELP_PROMPT == [OFF])
	{
		defer {
			^on ^help ^"*"
			//help
			^on ^help -"*"
		}
	}
	//help $*
	if (HELP_PROMPT == [ON]) {
		//help -wait
	}
	^set HELP_PATH $old_path
}

alias mhelp (module, topic, void)
{
	if (!module) {
		xecho -b Usage: /MHELP <module> [topic]
		return
	}

	stack push set INDENT
	^set INDENT OFF

	if (!topic)
	{
		if (aliasctl(alias exists $module\._help))
		{
			xecho -b Help for $module module:
			$module\._help
			foreach -$module\._help tmp {
				@ push(:topics $tmp)
			}
			if (topics) {
				xecho -b Help topics for $module module:
				fe ($tolower($topics)) aa bb cc dd ee {
					echo $[12]aa $[12]bb $[12]cc $[12]dd $[12]ee
				}
			}
		}{
			xecho -b No help for $module module
		}
	}{
		if (aliasctl(alias exists $module\._help.$topic))
		{
			xecho -b Help for $module\($topic\):
			$module\._help.$topic
		}{
			xecho -b No help for $module\($topic\)
		}
	}

	stack pop set INDENT
}


/* EOF */