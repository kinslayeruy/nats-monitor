using System;
using System.Linq;
using System.Text;
using NATS.Client;
using Newtonsoft.Json;

namespace NATSTest
{
    class Program
    {
        static void Main(string[] args)
        {
            var cf = new ConnectionFactory();

            var c = cf.CreateConnection("nats://events.service.owf-dev:4222");

            void EventHandler(object sender, MsgHandlerEventArgs e)
            {
                Console.WriteLine(e.Message.Subject);
                Console.WriteLine(format_json(Encoding.UTF8.GetString(e.Message.Data)));
            }

            var eventName = args != null && args.Any() ? args[0] : "deluxe.metadata-ingest.*";
            
            var sAsync = c.SubscribeAsync(eventName);
            sAsync.MessageHandler += EventHandler;
            sAsync.Start();
        }

        private static string format_json(string json)
        {
            dynamic parsedJson = JsonConvert.DeserializeObject(json);
            return JsonConvert.SerializeObject(parsedJson, Formatting.Indented);
        }
    }
}
