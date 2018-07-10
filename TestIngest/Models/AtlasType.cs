using System.Runtime.Serialization;

namespace TestIngest.Models
{
    /// <summary>
    /// The Type of 
    /// </summary>
    [DataContract]
    public enum AtlasType
    {
        /// <summary>
        /// An Unknown Atlas Type (should never occur)
        /// </summary>
        Unknown,

        /// <summary>
        /// A feature or movie
        /// </summary>
        [DataMember]
        Feature,

        /// <summary>
        /// A series
        /// </summary>
        [DataMember]
        Series,

        /// <summary>
        /// A season
        /// </summary>
        [DataMember]
        Season,

        /// <summary>
        /// An episode
        /// </summary>
        [DataMember]
        Episode,

        /// <summary>
        /// A version (will need more processing to get if it's a <see cref="FeatureVersion"/> or a <see cref="EpisodeVersion"/>
        /// </summary>
        [IgnoreDataMember]
        Version,

        /// <summary>
        /// A feature version
        /// </summary>
        [DataMember]
        FeatureVersion,

        /// <summary>
        /// An episode version
        /// </summary>
        [DataMember]
        EpisodeVersion,

        /// <summary>
        /// An asset (will need more processing to get if it's a <see cref="FeatureAsset"/> or a <see cref="EpisodeAsset"/>
        /// </summary>        
        [IgnoreDataMember]
        Asset,

        /// <summary>
        /// A feature verision asset
        /// </summary>
        [DataMember]
        FeatureAsset,

        /// <summary>
        /// An episode verision asset
        /// </summary>
        EpisodeAsset,

    }
}