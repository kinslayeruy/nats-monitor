using System.Runtime.Serialization;

namespace TestIngest.Models
{
    /// <summary>
    /// A link between metadata repository and atlas
    /// </summary>
    [DataContract]
    public class Link
    {
        /// <summary>
        /// The ingest URN.
        /// </summary>
        [DataMember(IsRequired = true)]
        public string IngestURN { get; set; }

        /// <summary>
        /// The metadata repository Id.
        /// </summary>
        [DataMember(IsRequired = true)]
        public string MetadataRepositoryId { get; set; }

        /// <summary>
        /// The atlas Ids.
        /// </summary>
        [DataMember(IsRequired = true)]
        public AtlasIds AtlasIds { get; set; }
    }
}