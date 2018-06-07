namespace TestIngest
{
    public class TestResult
    {
        public bool Success { get; set; }

        public string FailureReason { private get; set; }

        public string Result { private get; set; }

        public string GetAsString()
        {
            return GetStatus() + " " +
                   (!string.IsNullOrWhiteSpace(FailureReason) ? $"FailureReason: {FailureReason} " : "") +
                   (!string.IsNullOrWhiteSpace(Result) ? $"Result: {Result}" : "");
        }

        public string GetStatus()
        {
            return Success ? "Success!" : "Failure!";
        }
    }
}