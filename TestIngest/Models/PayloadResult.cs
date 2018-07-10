using System.Runtime.Serialization;
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;

namespace TestIngest.Models
{
    /// <summary>
    /// The result of the processing of a payload.
    /// </summary>
    [DataContract]
    public class PayloadResult
    {
        /// <inheritdoc />
        public PayloadResult()
        {
            TransformationDetails = new TransformationDetails();
            TransformationDetailsType = TransformationType.Unknown;
        }

        /// <summary>
        /// The Metadata Repository URN created
        /// </summary>
        [DataMember]
        public string MetadataRepositoryURN { get; set; }

        /// <summary>
        /// The Atlas URN created
        /// </summary>
        [DataMember]
        public AtlasIds AtlasURNs { get; set; }

        /// <summary>
        /// The Transformation details
        /// </summary>
        [DataMember]
        public TransformationDetails TransformationDetails { get; set; }

        /// <summary>
        /// The transformation type
        /// </summary>
        [DataMember]
        [JsonConverter(typeof(StringEnumConverter))]
        public TransformationType TransformationDetailsType { get; set; }

        /// <summary>
        /// The <see cref="PayloadStatus"/> of the process.
        /// </summary>
        [DataMember]
        [JsonConverter(typeof(StringEnumConverter))]
        public PayloadStatus Status { get; set; }

        /// <summary>
        /// The <see cref="PayloadAction"/> of the payload.
        /// </summary>
        [DataMember]
        [JsonConverter(typeof(StringEnumConverter))]
        public PayloadAction? Action { get; set; }

        /// <summary>
        /// The reason for failure (if any)
        /// </summary>
        [DataMember]
        public string FailureReason { get; set; }

        /// <summary>
        /// The error information (if any)
        /// </summary>
        [DataMember]
        public dynamic ErrorObject { get; set; }
    }
}