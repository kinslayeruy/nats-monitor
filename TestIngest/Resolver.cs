using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using DnsClient;
using DnsClient.Protocol;

namespace TestIngest
{
    public class Resolver
    {
        private readonly LookupClient _client = new LookupClient();
        private readonly List<string> _names = new List<string>();
        private const string RESOLV_FILE = "/etc/resolv.conf";

        public ServiceInfo[] NameServers
        {
            get
            {
                return _client.NameServers.Select(x => new ServiceInfo
                {
                    Hostname = "nameserver",
                    IP = x.Endpoint.Address.ToString(),
                    Port = x.Endpoint.Port
                }).ToArray();
            }
        }

        public string[] SearchNames => _names.ToArray();

        public ServiceInfoPool Query(string name, int defaultPort = 80)
        {
            if (string.IsNullOrEmpty(name))
                return new ServiceInfoPool(new ServiceInfo[0]);
            if (IsResolved(name))
            {
                var strArray = name.Split(':');
                return new ServiceInfoPool(new[]
                {
                    new ServiceInfo
                    {
                        Hostname = name,
                        IP = strArray[0],
                        Port = int.Parse(strArray[1])
                    }
                });
            }

            name = name.ToLower().Trim('.');
            var array = ReadResolvConf().Where(x => x.Key == "search").Select(x => x.Value).ToArray();
            if (array.Length == 0 || array.Any(x => name.EndsWith(x)))
                return new ServiceInfoPool(QueryInternal(name, defaultPort));
            foreach (var str in array)
            {
                var serviceInfoArray = QueryInternal($"{name}.{str}", defaultPort);
                if (serviceInfoArray.Length != 0)
                    return new ServiceInfoPool(serviceInfoArray);
            }

            return new ServiceInfoPool(new ServiceInfo[0]);
        }

        private bool IsResolved(string name)
        {
            return Regex.IsMatch(name, "\\d{1,3}.\\d{1,3}.\\d{1,3}.\\d{1,3}:\\d{1,5}\\b");
        }

        private ServiceInfo[] QueryInternal(string name, int defaultPort)
        {
            _names.Add(name);
            var response = _client.Query(name, QueryType.SRV);
            if (response.Answers.Any())
                return response.Answers.OfType<SrvRecord>().Select(x => new ServiceInfo
                {
                    Hostname = name,
                    IP = response.Additionals.OfType<ARecord>()
                             .FirstOrDefault(y => y.DomainName.Value == x.Target.Value)?.Address.ToString() ??
                         "unknown",
                    Port = (int) x.Port
                }).ToArray();
            response = _client.Query(name, QueryType.A);
            return response.Answers.OfType<ARecord>().Select(x => new ServiceInfo
            {
                Hostname = name,
                IP = x.Address.ToString(),
                Port = defaultPort
            }).ToArray();
        }

        private KeyValuePair<string, string>[] ReadResolvConf()
        {
            var keyValuePairList = new List<KeyValuePair<string, string>>();
            if (!File.Exists("/etc/resolv.conf"))
                return new KeyValuePair<string, string>[0];
            foreach (var readAllLine in File.ReadAllLines(RESOLV_FILE))
            {
                var separator = new char[1] {'#'};
                const int num = 1;
                var strArray = readAllLine.Split(separator, (StringSplitOptions) num).FirstOrDefault()
                    ?.Split(Array.Empty<char>());
                if (strArray != null && strArray.Length == 2)
                {
                    var lower = strArray[0].ToLower();
                    var str = strArray[1].ToLower().Trim('.');
                    keyValuePairList.Add(new KeyValuePair<string, string>(lower, str));
                }
            }

            return keyValuePairList.ToArray();
        }
    }
}