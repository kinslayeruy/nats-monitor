using System;
using System.Linq;
using System.Text;
using System.Threading;
using Newtonsoft.Json;
using STAN.Client;

namespace NATSMonitor
{
    internal class Program
    {
        private const string URL = "nats://nats.service.owf-dev:4222";
        private static string _eventName;
        private static int _eventCount;

        public static void Main(string[] args)
        {
            Console.WriteLine($"NATS Monitor Tool - v1.1");

            if (args == null || !args.Any())
            {
                Console.WriteLine("Need argument!");
                Environment.Exit(1);
            }

            
            _eventName = args[0];

            var scf = new StanConnectionFactory();
            var options = StanOptions.GetDefaultOptions();

            options.NatsURL = URL;
            var clientId = Environment.MachineName;
            var stanConnection = scf.CreateConnection("events-streaming",
                $"{clientId}-{Guid.NewGuid()}",
                options);

            var subOptions = StanSubscriptionOptions.GetDefaultOptions();
            subOptions.DurableName = Environment.MachineName;
            subOptions.StartAt(DateTime.UtcNow.AddMinutes(-1));

            Console.WriteLine($"Starting connection to {_eventName} at {URL}");
            using (var sub = stanConnection.Subscribe(_eventName, subOptions, (sender, handlerArgs) =>
            {
                WriteToConsole(format_json(Encoding.UTF8.GetString(handlerArgs.Message.Data)));
                _eventCount++;
            }))
            {
                while (true)
                {
                    Thread.Sleep(1000);

                    if (!Console.KeyAvailable)
                    {
                        continue;
                    }

                    var key = Console.ReadKey(true);
                    if (key.Modifiers.HasFlag(ConsoleModifiers.Control) && key.Key == ConsoleKey.S)
                    {
                        sub.Close();
                        WriteToConsole("Exiting application...");
                        Environment.Exit(0);
                    }
                }
            }
        }

        private static void WriteToConsole(string text)
        {
            //Write Header
            Console.Clear();
            Console.WriteLine($"Event {_eventCount} for {_eventName}");
            Console.WriteLine(text);
        }

        private static string format_json(string json)
        {
            dynamic parsedJson = JsonConvert.DeserializeObject(json);
            return JsonConvert.SerializeObject(parsedJson, Formatting.Indented);
        }
    }
}