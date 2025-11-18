import sys.FileSystem;
import sys.io.File;
import haxe.Json;

/**
 * Represents the configuration structure for the HMM tool, containing an array of library dependencies.
 */
typedef HmmConfig =
{
	dependencies:Array<LibraryConfig>
}

/**
 * Represents the configuration for a single library, including its name, type, version, directory, reference, and URL.
 */
typedef LibraryConfig =
{
	name:String,
	type:String,
	?version:String,
	?dir:String,
	?ref:String,
	?url:String
}

/**
 * The Main class is designed specifically for use with GitHub Actions.
 * Its purpose is to install libraries specified in a configuration file (`haxelibs.json`)
 * without their dependencies.
 */
class Main
{
	/**
	 * The main function is the entry point of the program.
	 * It checks for the existence of the `.haxelib` directory, creating it if it does not exist.
	 * Then it reads the `haxelibs.json` configuration file, parses it, and installs each library
	 * according to its specified type, using the appropriate commands while skipping dependencies.
	 */
	public static function main():Void
	{
		// Ensure the .haxelib directory exists
		if (!FileSystem.exists('.haxelib'))
			runCommand(['haxelib', 'newrepo', '--quiet', '--never']);

		// Read and parse the hmm.json configuration file
		final config:HmmConfig = Json.parse(File.getContent('./haxelibs.json'));

		// Options to run with the commands
		final options:Array<String> = ['--quiet', '--never', '--skip-dependencies'];

		// Iterate over each library dependency in the configuration
		for (lib in config.dependencies)
		{
			switch (lib.type)
			{
				case 'haxelib':
					// Prepare the haxelib install command arguments
					final args:Array<String> = ['haxelib', 'install'];

					args.push(lib.name);

					if (lib.version != null)
						args.push(lib.version);

					// Execute the haxelib install command
					runCommand(args.concat(options));
				case 'git':
					// Prepare the haxelib git command arguments
					final args:Array<String> = ['haxelib', 'git'];

					args.push(lib.name);
					args.push(lib.url);

					if (lib.ref != null)
						args.push(lib.ref);

					// Execute the haxelib git command
					runCommand(args.concat(options));
			}
		}

		// List installed haxelib packages
		runCommand(['haxelib', 'list']);
	}

	/**
	 * Executes a system command with the provided arguments.
	 * @param args The command and its arguments to be executed.
	 */
	public static function runCommand(args:Array<String>):Void
	{
		final command:String = args.join(' ');

		if (command != AnsiColors.yellow(command))
			Sys.println(AnsiColors.yellow(command));

		Sys.command(args.shift(), args);
	}
}

/**
 * Utility class for applying ANSI color codes to strings for terminal output.
 * @see https://github.com/andywhite37/hmm/blob/master/src/hmm/utils/AnsiColors.hx
 */
class AnsiColors
{
	/**
	 * Colors the input string red.
	 * @param input The input string.
	 * @return The colored string.
	 */
	public static inline function red(input:String):String
	{
		return color(input, Red);
	}

	/**
	 * Colors the input string green.
	 * @param input The input string.
	 * @return The colored string.
	 */
	public static inline function green(input:String):String
	{
		return color(input, Green);
	}

	/**
	 * Colors the input string yellow.
	 * @param input The input string.
	 * @return The colored string.
	 */
	public static inline function yellow(input:String):String
	{
		return color(input, Yellow);
	}

	/**
	 * Colors the input string blue.
	 * @param input The input string.
	 * @return The colored string.
	 */
	public static inline function blue(input:String):String
	{
		return color(input, Blue);
	}

	/**
	 * Colors the input string magenta.
	 * @param input The input string.
	 * @return The colored string.
	 */
	public static inline function magenta(input:String):String
	{
		return color(input, Magenta);
	}

	/**
	 * Colors the input string cyan.
	 * @param input The input string.
	 * @return The colored string.
	 */
	public static inline function cyan(input:String):String
	{
		return color(input, Cyan);
	}

	/**
	 * Colors the input string gray.
	 * @param input The input string.
	 * @return The colored string.
	 */
	public static inline function gray(input:String):String
	{
		return color(input, Gray);
	}

	/**
	 * Colors the input string white.
	 * @param input The input string.
	 * @return The colored string.
	 */
	public static inline function white(input:String):String
	{
		return color(input, White);
	}

	/**
	 * Removes any color from the input string.
	 * @param input The input string.
	 * @return The uncolored string.
	 */
	public static inline function none(input:String):String
	{
		return color(input, None);
	}

	/**
	 * Applies the specified ANSI color code to the input string.
	 * @param input The input string.
	 * @param ansiColor The ANSI color code.
	 * @return The colored string.
	 */
	public static inline function color(input:String, ansiColor:AnsiColor):String
	{
		return #if sys '$ansiColor$input${AnsiColor.None}' #else input #end;
	}
}

/**
 * Enum abstract representing ANSI color codes.
 */
enum abstract AnsiColor(String) from String to String
{
	var Black = '\033[0;30m';
	var Red = '\033[0;31m';
	var Green = '\033[0;32m';
	var Yellow = '\033[0;33m';
	var Blue = '\033[0;34m';
	var Magenta = '\033[0;35m';
	var Cyan = '\033[0;36m';
	var Gray = '\033[0;37m';
	var White = '\033[1;37m';
	var None = '\033[0;0m';
}