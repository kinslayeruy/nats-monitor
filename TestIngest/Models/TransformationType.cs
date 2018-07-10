namespace TestIngest.Models
{
    /// <summary>
    /// The type of the transformation
    /// </summary>
    public enum TransformationType
    {
        /// <summary>
        /// An atlas transformation.
        /// </summary>
        AtlasTransformation,

        /// <summary>
        /// A metadata repository transformation.
        /// </summary>
        MetadataRepositoryTransformation,

        /// <summary>
        /// Unknown transformation.
        /// </summary>
        Unknown
    }
}