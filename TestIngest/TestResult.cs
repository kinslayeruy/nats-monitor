using System.Diagnostics;
using Newtonsoft.Json;
using TestIngest.Models;

namespace TestIngest
{
    [DebuggerDisplay("Success: {Success} FailReason: {FailureReason}")]
    public class TestResult
    {
        public bool Success { get; set; }

        public bool Skipped { get; set; }

        public string FailureReason { get; set; }

        public MetadataIngestEvent Result { get; set; }

        public string GetAsString()
        {
            if (Skipped)
            {
                return "Skipped";
            }

            return GetStatus() + " " +
                   (!string.IsNullOrWhiteSpace(FailureReason) ? $"FailureReason: {FailureReason} " : "") +
                   (Result != null ? $"Result: {JsonConvert.SerializeObject(Result, Formatting.None)}" : "");
        }

        public string GetStatus()
        {
            if (Skipped)
            {
                return "Skipped!";
            }
            return Success ? "Success!" : "Failure!";
        }
    }
}