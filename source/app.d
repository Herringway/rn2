import std.stdio;
import std.regex;
import std.getopt;
import std.file;
import std.array;
import std.path;

int main(string[] args)
{
	bool testing = false;
	bool verbose = false;
	bool ignoreCase = false;
	string directory = ".";
	bool recursive = false;
	void printUsage() {
		stderr.writefln(r"Usage: %s [options] matchpattern renamepattern

Options:
  --directory, -d: Set default directory
  --help,      -h: Print this help
  --ignorecase,-i: Regex is case insensitive
  --recursive, -r: Descend into child directories
  --test,      -t: Don't rename, only print what would happen
  --verbose,   -v: Print extra information

Match Pattern:
  See ECMAScript regular expression documentation for details.

Rename Pattern:
  $&: Entire match
  $1..$99: Submatches 1 to 99
  $`: Input preceding match
  $': Input following match
  $$: $ character", args[0]);
		throw new Exception(""); //thrown to safely exit program
	}
	try {
		getopt(args, std.getopt.config.bundling,
			   "test|t", &testing,
			   "verbose|v", &verbose,
			   "ignorecase|i", &ignoreCase,
			   "directory|d", &directory,
			   "recursive|r", &recursive,
			   "help|h", &printUsage);
		if (args.length < 3) {
			printUsage();
		}
	} catch (Exception) { return 1; }
	SpanMode recursion = SpanMode.shallow;
	if (recursive)
		recursion = SpanMode.depth;
	string flags = "g";
	if (ignoreCase)
		flags ~= "i";
	auto regex = regex(args[1], flags);
	foreach (file; array(dirEntries(directory, recursion))) {
		if (file.isDir())
			continue;
		auto match = matchFirst(baseName(file.name), regex);
		if (!match.empty) {
			string newName = buildPath(dirName(file.name), replaceFirst(baseName(file.name), regex, args[2]));
			if (verbose || testing)
				writefln("%s => %s", file.name, newName);
			if (testing)
				continue;
			rename(file.name, newName);
		}
	}
	return 0;
}
