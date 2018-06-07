using System.Linq;

namespace TestIngest
{
    public class Options
    {
        public bool Subdirectories { get; private set; }
        public bool DoNotHidePayload { get; private set; }
        public bool Alphas { get; private set; }
        public ServiceInfoPool Hosts { get; private set; }

        public Options(string [] args)
        {
            Hosts = new ServiceInfoPool(new[]
                {new ServiceInfo {Hostname = "localhost", IP = "127.0.0.1", Port = 5000}});
            ParseArgs(args);
        }

        public static string Help()
        {
            return "Usage: \n" +
                   "\t-?\t\tShow this help\n\n" +
                   "\t-s\t\tSearches subdirectories for files\n\n" +
                   "\t-p\t\tDoes not hide the payload from the results.\n\n" +
                   "\t\t\tThis option will make all messages bigger and harder to read\n\n" +
                   "\t-a\t\tSets payloads as alphas instead of GPMS\n\n" +
                   "\t-h: hostname\tSets the hostname \n(default http://localhost:5000)\n";
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

            var hostname = args.SkipWhile(a => a != "-h").Skip(1).FirstOrDefault();
            if (!string.IsNullOrWhiteSpace(hostname))
            {
                var serviceInfos = new Resolver().Query(hostname);
                Hosts = serviceInfos;                
            }
        }
    }
}