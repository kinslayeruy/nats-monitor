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
        private const string URL = "nats://events.service.owf-dev:4222";
        
        public static void Main(string[] args)
        {
            if (args == null || !args.Any())
            {
                Console.WriteLine("Need argument!");
                Environment.Exit(1);
            }
            var eventName = args[0];

            var scf = new StanConnectionFactory();
            var options = StanOptions.GetDefaultOptions();

            options.NatsURL = URL;
            var stanConnection = scf.CreateConnection("events-streaming", Guid.NewGuid().ToString(), options);

            var subOptions = StanSubscriptionOptions.GetDefaultOptions();
            subOptions.DurableName = "NatsTest";

            Console.WriteLine($"Starting connection to {eventName} at {URL}");
            using (var sub = stanConnection.Subscribe(eventName, subOptions, (sender, handlerArgs) =>
            {
                Console.WriteLine(handlerArgs.Message.Subject);
                Console.WriteLine(format_json(Encoding.UTF8.GetString(handlerArgs.Message.Data)));
            }))
            {
                while (true)
                {
                    Thread.Sleep(200);

                    if (!Console.KeyAvailable)
                    {
                        continue;
                    }
                    var key = Console.ReadKey(true);
                    if (key.Modifiers.HasFlag(ConsoleModifiers.Control) && key.Key == ConsoleKey.S)
                    {
                        sub.Close();
                        Console.WriteLine("Exiting application...");
                        Environment.Exit(0);
                    }
                }
            }
        }
        
        private static string format_json(string json)
        {
            dynamic parsedJson = JsonConvert.DeserializeObject(json);
            return JsonConvert.SerializeObject(parsedJson, Formatting.Indented);
        }
    }
}