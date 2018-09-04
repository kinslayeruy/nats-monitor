using System.Linq;
using System.Runtime.InteropServices;

namespace TestIngest
{
    public class Options
    {
        public bool Subdirectories { get; private set; }
        public bool DoNotHidePayload { get; private set; }
        public bool Alphas { get; private set; }
        public string Host { get; private set; }
        public int MaxParallel { get; private set; }

        public bool SkipMetadata { get; private set; }
        public bool SkipAtlas { get; private set; }
        public bool SkipLinking { get; private set; }


        public Options(string [] args)
        {
            Host = "http://localhost:5000";
            MaxParallel = 1;
            ParseArgs(args);
        }

        public static string Help()
        {
            return "Usage: \n" +
                   "\t-?\t\tShow this help\n\n" +
                   "\t-s\t\tSearches sub-directories for files\n\n" +
                   "\t-p\t\tDoes not hide the payload from the results.\n\n" +
                   "\t\t\tThis option will make all messages bigger and harder to read\n\n" +
                   "\t-a\t\tSets payloads as alphas instead of GPMS\n\n" +
                   "\t-h hostname\tSets the hostname \n(default http://localhost:5000)\n" +
                   "\t-m maxParallel\tSets the max parallel threads to run (default 1)\n" +
                   "\t-sm\t\tSkips metadata ingest\n" +
                   "\t-sa\t\tSkips atlas ingest\n" +
                   "\t-sl\t\tSkips linking";
        }

        private void ParseArgs(string[] args)
        {
            if (args.Contains("-s"))
            {
                Subdirectories = true;
            }

            if (args.Contains("-p"))
            {
                DoNotHidePayload = true;
            }

            if (args.Contains("-a"))
            {
                Alphas = true;
            }

            if (args.Contains("-m"))
            {
                var max = args.SkipWhile(a => a != "-m").Skip(1).FirstOrDefault();
                if (!string.IsNullOrWhiteSpace(max) && int.TryParse(max, out var maxPara))
                {
                    MaxParallel = maxPara;
                }
            }

            if (args.Contains("-h"))
            {
                var hostname = args.SkipWhile(a => a != "-h").Skip(1).FirstOrDefault();
                if (!string.IsNullOrWhiteSpace(hostname))
                {
                    Host = $"http://{hostname}";
                }
            }

            if (args.Contains("-sa"))
            {
                SkipAtlas = true;
            }

            if (args.Contains("-sm"))
            {
                SkipMetadata = true;
            }

            if (args.Contains("-sl") || SkipMetadata || SkipAtlas)
            {
                SkipLinking = true;
            }
        }
    }
}