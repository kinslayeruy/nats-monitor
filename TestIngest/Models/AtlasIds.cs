using System;
using System.Diagnostics;
using System.Runtime.Serialization;
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;

namespace TestIngest.Models
{
    /// <summary>
    /// Atlas Ids
    /// </summary>
    [DataContract]
    [DebuggerDisplay("{GetComposedId()}")]
    public class AtlasIds
    {
        /// <summary>
        /// The feature Id (for types feature and version)
        /// </summary>
        [DataMember]
        public string FeatureId { get; set; }

        /// <summary>
        /// The series Id (for types series, season, episode and version)
        /// </summary>
        [DataMember]
        public string SeriesId { get; set; }

        /// <summary>
        /// The season Id (for types season, episode and version)
        /// </summary>
        [DataMember]
        public string SeasonId { get; set; }

        /// <summary>
        /// The episode Id (for types episode and version)
        /// </summary>
        [DataMember]
        public string EpisodeId { get; set; }

        /// <summary>
        /// The version Id (for type version)
        /// </summary>
        [DataMember]
        public string VersionId { get; set; }

        /// <summary>
        /// The version Id (for type version)
        /// </summary>
        [DataMember]
        public string AssetId { get; set; }

        /// <summary>
        /// The atlas type.
        /// </summary>
        [DataMember]
        [JsonConverter(typeof(StringEnumConverter))]
        public AtlasType AtlasType { get; set; }

        /// <summary>
        /// Returns the top level id for the object. (Feature id if feature type, episode id if episode type, etc)
        /// </summary>
        public string GetRecordId()
        {
            switch (AtlasType)
            {
                case AtlasType.Feature:
                    return FeatureId;
                case AtlasType.Series:
                    return SeriesId;
                case AtlasType.Season:
                    return SeasonId;
                case AtlasType.Episode:
                    return EpisodeId;
                case AtlasType.Version:
                case AtlasType.FeatureVersion:
                case AtlasType.EpisodeVersion:
                    return VersionId;
                case AtlasType.Asset:
                case AtlasType.FeatureAsset:
                case AtlasType.EpisodeAsset:
                    return AssetId;
                case AtlasType.Unknown:
                    return null;
                default:
                    throw new ArgumentOutOfRangeException();
            }
        }

        /// <summary>
        /// Get's an Id based on the type.
        /// </summary>
        public string GetComposedId()
        {
            switch (AtlasType)
            {
                case AtlasType.Feature:
                    return $"Fea:{FeatureId}";
                case AtlasType.Series:
                    return $"Ser:{SeriesId}";
                case AtlasType.Season:
                    return $"Ser:{SeriesId}|Sea:{SeasonId}";
                case AtlasType.Episode:
                    return $"Ser:{SeriesId}|Sea:{SeasonId}|Epi:{EpisodeId}";
                case AtlasType.FeatureVersion:
                    return $"Fea:{FeatureId}|Ver:{VersionId}";
                case AtlasType.FeatureAsset:
                    return $"Fea:{FeatureId}|Ver:{VersionId}|Ase:{AssetId}";
                case AtlasType.EpisodeVersion:
                    return $"Ser:{SeriesId}|Sea:{SeasonId}|Epi:{EpisodeId}|Ver:{VersionId}";
                case AtlasType.EpisodeAsset:
                    return $"Ser:{SeriesId}|Sea:{SeasonId}|Epi:{EpisodeId}|Ver:{VersionId}|Ase:{AssetId}";
                case AtlasType.Unknown:
                    return "Unknown type";
                default:
                    throw new ArgumentOutOfRangeException();
            }
        }

        /// <summary>
        /// Checks if the values contained in this instance are valid.
        /// </summary>
        public (bool result, string validationMessage) IsValid()
        {
            switch (AtlasType)
            {
                case AtlasType.Feature:
                    return !string.IsNullOrWhiteSpace(FeatureId)
                        ? (true, null)
                        : (false, "Feature type requires FeatureId.");
                case AtlasType.Series:
                    return !string.IsNullOrWhiteSpace(SeriesId)
                        ? (true, null)
                        : (false, "Series type requires SeriesId.");
                case AtlasType.Season:
                    return !string.IsNullOrWhiteSpace(SeriesId) && !string.IsNullOrWhiteSpace(SeasonId)
                        ? (true, null)
                        : (false, "Season type requires SeriesId and SeasonId.");
                case AtlasType.Episode:
                    return !string.IsNullOrWhiteSpace(SeriesId) && !string.IsNullOrWhiteSpace(SeasonId) &&
                           !string.IsNullOrWhiteSpace(EpisodeId)
                        ? (true, null)
                        : (false, "Episode type requires SeriesId, SeasonId and EpisodeId.");
                case AtlasType.Version:
                    return (false, "Version type is only for internal use.");
                case AtlasType.FeatureVersion:
                    return !string.IsNullOrWhiteSpace(FeatureId) && !string.IsNullOrWhiteSpace(VersionId) ? (true, null) :
                        (false, "FeatureVersion type requires FeatureId and VersionId.");
                case AtlasType.EpisodeVersion:
                    return !string.IsNullOrWhiteSpace(SeriesId) && !string.IsNullOrWhiteSpace(SeasonId) &&
                           !string.IsNullOrWhiteSpace(EpisodeId) && !string.IsNullOrWhiteSpace(VersionId) ? (true, null) :
                        (false, "EpisodeVersion type requires SeriesId, SeasonId, EpisodeId and VersionId.");
                case AtlasType.Asset:
                    return (false, "Asset type is only for internal use.");
                case AtlasType.FeatureAsset:
                    return !string.IsNullOrWhiteSpace(FeatureId) && !string.IsNullOrWhiteSpace(VersionId) &&
                           !string.IsNullOrWhiteSpace(AssetId) ? (true, null) :
                        (false, "FeatureAsset type requires FeatureId, VersionId and AssetId.");
                case AtlasType.EpisodeAsset:
                    return !string.IsNullOrWhiteSpace(SeriesId) && !string.IsNullOrWhiteSpace(SeasonId) &&
                           !string.IsNullOrWhiteSpace(EpisodeId) && !string.IsNullOrWhiteSpace(VersionId) &&
                           !string.IsNullOrWhiteSpace(AssetId) ? (true, null) :
                        (false, "EpisodeAsset type requires SeriesId, SeasonId, EpisodeId, VersionId and AssetId.");
                case AtlasType.Unknown:
                    return (false, "Unkown type is not a valid value.");
                default:
                    throw new ArgumentOutOfRangeException();
            }
        }
    }
}