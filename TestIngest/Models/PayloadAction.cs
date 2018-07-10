namespace TestIngest.Models
{
    /// <summary>
    /// A payload action type.
    /// </summary>
    public enum PayloadAction
    {
        /// <summary>
        /// The record was not processed.
        /// </summary>
        None,

        /// <summary>
        /// A record was created by this payload
        /// </summary>
        Created,

        /// <summary>
        /// A record was updated by this payload
        /// </summary>
        Updated,

        /// <summary>
        /// A record was skipped by this payload (not created nor updated)
        /// </summary>
        Skipped
    }
}