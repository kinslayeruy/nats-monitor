using System.Runtime.Serialization;
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;

namespace TestIngest.Models
{
    /// <summary>
    /// A Metadata Ingest Event success / failure report
    /// </summary>
    [DataContract]
    public class MetadataIngestEvent
    {
        /// <summary>
        /// </summary>
        public MetadataIngestEvent()
        {
            PayloadResults = new PayloadResult[0];
        }

        /// <summary>
        /// The URN that the ONE Ingest Service generated for this file
        /// </summary>
        [DataMember]
        public string IngestURN { get; set; }

        /// <summary>
        /// The overall status, will only be Success if every Payload Result is Successfull
        /// </summary>
        [DataMember]
        [JsonConverter(typeof(StringEnumConverter))]
        public PayloadStatus OverallStatus { get; set; }

        /// <summary>
        /// The payload sent to the transformation
        /// </summary>
        [DataMember]
        public string Payload { get; set; }

        /// <summary>
        /// The payload processing results
        /// </summary>
        [DataMember]
        public PayloadResult[] PayloadResults { get; set; }
    }
}