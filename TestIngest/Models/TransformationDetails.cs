using System.Runtime.Serialization;

namespace TestIngest.Models
{
    /// <summary>
    /// A transformation details
    /// </summary>
    [DataContract]
    public class TransformationDetails
    {
        /// <summary>
        /// The used transformation id
        /// </summary>
        [DataMember]
        public string TransformId { get; set; }

        /// <summary>
        /// The transformation result
        /// </summary>
        [DataMember]
        public dynamic Result { get; set; }

        /// <summary>
        /// The group name
        /// </summary>
        [DataMember]
        public string GroupName { get; set; }

        /// <summary>
        /// A list of errors if any
        /// </summary>
        [DataMember]
        public string[] Errors { get; set; }
    }
}