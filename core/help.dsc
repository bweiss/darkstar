#
# $Id$ */
# help.dsc - Help browser for DarkStar/EPIC4
# Copyright (c) 2002 Tyler Hall
# See the 'COPYRIGHT' file for more information.
#

alias dhelp (...)
{
	@ :old_path = HELP_PATH;
	^set HELP_PATH $twiddle($DS.HELP_DIR);
	if (@ && HELP_PROMPT == [OFF])
	{
		defer {
			^on ^help ^"*";
			//help;
			^on ^help -"*";
		};
	};
	//help $*;
	if (HELP_PROMPT == [ON]) {
		//help -wait;
	};
	^set HELP_PATH $old_path;
};

