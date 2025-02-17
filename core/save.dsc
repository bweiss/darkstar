#
# $Id$ */
# save.dsc - Save DarkStar settings
# Copyright (c) 2003, 2004 Brian Weiss
# See the 'COPYRIGHT' file for more information.
#

#
# /SAVE [-d <directory>] [-c|-f] [*|modules]
#
# Saves all settings for specified module(s) to either $DS.SAVE_DIR or a
# directory specified with the -d option. If no modules are specified,
# "*" (ALL) is assumed and the settings for every currently loaded module
# will be saved. If either the -c or -f options are specified only
# config or format settings will be saved.
#
# Note: "core" is a valid module name, representing anything added by
# the core scripts.
#
alias save (args)
{
	^local modules;
	^local option,optopt,optarg;
	^local savedir $twiddle($DS.SAVE_DIR);

	while (option = getopt(optopt optarg "cd:f" $args))
	{
		switch ($option)
		{
			(c) { @ :write_cfg_only = 1; @ :write_fmt_only = 0; }
			(d) { @ :savedir = twiddle($optarg); }
			(f) { @ :write_fmt_only = 1; @ :write_cfg_only = 0; }
			(!) { xecho -b -s SAVE: Invalid option "$optopt"; }
			(-) { xecho -b -s SAVE: Missing argument for option "$optopt"; }
		};
	};
	@ :args = optarg ? optarg : [*];

	if (word(0 $args) == [*])
	{
		@ :modules = [core];
		for ii from 0 to ${numitems(_loaded_modules) - 1} {
			@ push(modules $getitem(_loaded_modules $ii));
		};
	}{
		while (:mod = shift(args))
		{
			if (mod == [core] || finditem(_loaded_modules $mod) > -1) {
				@ push(modules $mod);
			} else {
				xecho -b -s SAVE: Module $mod is not loaded;
			};
		};
	};

	xecho -b -s Saving ${write_cfg_only ? [config ] : write_fmt_only ? [format ] : []}settings to $savedir: $modules;

	for mod in ($modules)
	{
		@ :savefile = savedir ## [/] ## mod;
		if (fexist($savefile) == 1) {
			@ unlink($savefile);
		};

		if ((:fd = open($savefile W)) == -1)
		{
			xecho -b -s SAVE: Unable to write $savefile;
			continue;
		}{
			_save.write_header $fd $mod;

			if (write_cfg_only) {
				_save.write_config_vars $fd $mod;
			} else if (write_fmt_only) {
				_save.write_format_vars $fd $mod;
			} else {
				_save.write_config_vars $fd $mod;
				_save.write_format_vars $fd $mod;
			};

			# Allow modules to create their own save aliases
			if (aliasctl(alias exists $mod\._save)) {
				$mod\._save $fd;
			};

			@ write($fd );
			@ close($fd);
		};
	};

	xecho -b -s Save complete [$strftime(%a %b %d %T %Z %Y)];
};


alias _save.write_header (fd, mod, void)
{
	if (!mod)
		return;

	@ write($fd # Generated by DarkStar $DS.VERSION \($DS.INTERNAL_VERSION\) [$DS.CORE_ID]);
	@ write($fd # Date: $strftime(%a %b %d %T %Z %Y));
	@ write($fd # Module: $mod);
	@ write($fd # Version: $modinfo($mod v));
	@ write($fd );
};

alias _save.write_config_vars (fd, mod, void)
{
	if (!mod)
		return;

	for ii from 0 to ${numitems(_DSET.$mod) - 1}
	{
		@ :var   = getitem(_DSET.$mod $ii);
		@ :value = aliasctl(assign get CONFIG.$var);

		if (value != []) {
			@ write($fd assign CONFIG.$var $value);
		} else {
			@ write($fd assign -CONFIG.$var);
		};
	};
	@ write($fd );
};

alias _save.write_format_vars (fd, mod, void)
{
	if (!mod)
		return;

	for ii from 0 to ${numitems(_FSET.$mod) - 1}
	{
		@ :var   = getitem(_FSET.$mod $ii);
		@ :value = aliasctl(assign get FORMAT.$var);

		if (value != []) {
			@ write($fd assign FORMAT.$var $value);
		} else {
			@ write($fd assign -FORMAT.$var);
		};
	};
	@ write($fd );
};

