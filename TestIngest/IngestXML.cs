using System.Runtime.Serialization;
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;

namespace TestIngest
{
    [DataContract]
    public class IngestXML
    {
        [DataMember]
        public string IngestURN { get; set; }

        [DataMember]
        [JsonConverter(typeof(StringEnumConverter))]
        public ProviderInputFormat ProviderInputFormat { get; set; }
        
        [DataMember]
        public string Data { get; set; }
    }
}