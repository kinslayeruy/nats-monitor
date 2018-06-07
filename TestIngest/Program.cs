using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Xml;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace TestIngest
{
    internal class Program
    {
        public static void Main(string[] args)
        {
            if (args.Any() && args[0] == "-?")
            {
                Console.WriteLine(Options.Help());
                Environment.Exit(0);
            }

            var options = new Options(args);

            var atlasResults = new List<TestResult>();
            var mrResults = new List<TestResult>();

            var logFile = $"test.log";
            File.Create(logFile).Close();
            Console.WriteLine($"Starting...");
            File.AppendAllText(logFile, "Starting...\n");

            var workDir = Environment.CurrentDirectory;
            var allFilesEnum = Directory.EnumerateFiles(workDir, "*.xml",
                options.Subdirectories ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly);
            var allFiles = allFilesEnum.ToArray();
            Console.WriteLine($"Found {allFiles.Length} files.");
            File.AppendAllText(logFile, $"Found {allFiles.Length} files.\n");

            var pad = (int) Math.Floor(Math.Log10(allFiles.Length) + 1);
            var watch = new Stopwatch();
            watch.Start();
            long fullTime = 0;
            for (var index = 0; index < allFiles.Length; index++)
            {
                var file = allFiles[index];
                var fileForLog = file.Remove(0, workDir.Length);
                Console.WriteLine($"{index.ToString().PadLeft(pad, '0')} - Testing {fileForLog}");
                File.AppendAllText(logFile, $"{index.ToString().PadLeft(pad, '0')} - Testing {fileForLog}\n");

                var xml = File.ReadAllText(file, Encoding.UTF8);
                if (!IsValidXml(xml))
                {
                    var testResult = new TestResult
                    {
                        Success = false,
                        FailureReason = $"File {file} is not a valid XML"
                    };
                    Console.WriteLine($"{index.ToString().PadLeft(pad, '0')} - {testResult.GetAsString()}");
                    File.AppendAllText(logFile, $"{index.ToString().PadLeft(pad, '0')} - {testResult.GetAsString()}\n");
                    atlasResults.Add(testResult);
                    mrResults.Add(testResult);
                }

                var ingestXML = BuildGPMSPayload(xml, fileForLog, options);

                var atlas = CallAtlas(ingestXML, options).GetAwaiter().GetResult();
                File.AppendAllText(logFile,
                    $"{index.ToString().PadLeft(pad, '0')} - AtlasCall - {atlas.GetAsString()}\n");

                var mr = CallMetadata(ingestXML, options).GetAwaiter().GetResult();
                File.AppendAllText(logFile, $"{index.ToString().PadLeft(pad, '0')} - MRCall    - {mr.GetAsString()}\n");

                atlasResults.Add(atlas);
                mrResults.Add(mr);
                var time = watch.ElapsedMilliseconds;
                Console.WriteLine($"{index.ToString().PadLeft(pad, '0')}/{allFiles.Length} " +
                                  $"- {atlas.GetStatus()} - {mr.GetStatus()} " +
                                  $"- Took {(time - fullTime):N0} ms " +
                                  $"- Estimated time left: {TimeSpan.FromMilliseconds(((double) (time * allFiles.Length) / (index + 1))):g} ms");
                fullTime = time;
            }

            var totalAtlas = atlasResults.Count;
            var successAtlas = atlasResults.Count(r => r.Success);
            var totalMR = mrResults.Count;
            var successMR = mrResults.Count(r => r.Success);
            Console.WriteLine(
                $"Finished {(totalAtlas + totalMR):N0} calls, time taken {TimeSpan.FromMilliseconds(watch.ElapsedMilliseconds):g}");
            Console.WriteLine(
                $"Atlas: {totalAtlas:N0} calls, {successAtlas:N0} successful, ({((double) successAtlas / totalAtlas):P1})");
            Console.WriteLine(
                $"MR   : {totalMR:N0} calls, {successMR:N0} successful, ({((double) successMR / totalMR):P1})");
            File.AppendAllText(logFile,
                $"Atlas: {totalAtlas:N0} calls, {successAtlas:N0} successful, ({((double) successAtlas / totalAtlas):P1})\n");
            File.AppendAllText(logFile,
                $"MR   : {totalMR:N0} calls, {successMR:N0} successful, ({((double) successMR / totalMR):P1})\n");
            File.Copy(logFile, $"test-{DateTime.UtcNow:yyyy-MM-dd-HH-mm-ss}.log");
        }


        private static async Task<TestResult> CallMetadata(IngestXML xml, Options options)
        {
            var client = new HttpClient {BaseAddress = new Uri(options.Hosts.PickOneRandom().GetUrl())};
            try
            {
                var response = await client.PostAsync(
                    "v1/ingest/metadata" + (options.DoNotHidePayload ? "" : "?verbosity=HidePayload"),
                    new StringContent(JsonConvert.SerializeObject(xml), Encoding.UTF8,
                        "application/json"));

                string content = null;
                if (response.Content != null)
                {
                    content = await response.Content.ReadAsStringAsync();
                }

                if (!response.IsSuccessStatusCode)
                {
                    return new TestResult
                    {
                        Success = false,
                        FailureReason = $"Call to MR ingest failed {response.StatusCode} - {response.ReasonPhrase}",
                        Result = content
                    };
                }

                var json = JsonConvert.DeserializeObject<dynamic>(content);
                if (json.overallStatus == "Success")
                {
                    return new TestResult
                    {
                        Success = true,
                        FailureReason = null,
                        Result = content
                    };
                }

                return new TestResult
                {
                    Success = false,
                    FailureReason = ((JArray) json.payloadResults)
                        .FirstOrDefault(f => !string.IsNullOrWhiteSpace(f.Value<string>("failureReason")))
                        ?.Value<string>("failureReason"),
                    Result = content
                };
            }
            catch (Exception ex)
            {
                return new TestResult
                {
                    Success = false,
                    FailureReason = $"Call to MR ingest failed {ex.Message}",
                    Result = ex.ToString()
                };
            }
        }

        private static async Task<TestResult> CallAtlas(IngestXML xml, Options options)
        {
            var client = new HttpClient {BaseAddress = new Uri(options.Hosts.PickOneRandom().GetUrl())};

            try
            {
                var response = await client.PostAsync(
                    "v1/ingest/atlas" + (options.DoNotHidePayload ? "" : "?verbosity=HidePayload"),
                    new StringContent(JsonConvert.SerializeObject(xml), Encoding.UTF8,
                        "application/json"));

                string content = null;
                if (response.Content != null)
                {
                    content = await response.Content.ReadAsStringAsync();
                }

                if (!response.IsSuccessStatusCode)
                {
                    return new TestResult
                    {
                        Success = false,
                        FailureReason = $"Call to Atlas ingest failed {response.StatusCode} - {response.ReasonPhrase}",
                        Result = content
                    };
                }

                var json = JsonConvert.DeserializeObject<dynamic>(content);
                if (json.overallStatus == "Success")
                {
                    return new TestResult
                    {
                        Success = true,
                        FailureReason = null,
                        Result = content
                    };
                }

                return new TestResult
                {
                    Success = false,
                    FailureReason = ((JArray) json.payloadResults)
                        .FirstOrDefault(f => !string.IsNullOrWhiteSpace(f.Value<string>("failureReason")))
                        ?.Value<string>("failureReason"),
                    Result = content
                };
            }
            catch (Exception ex)
            {
                return new TestResult
                {
                    Success = false,
                    FailureReason = $"Call to Atlas ingest failed {ex.Message}",
                    Result = ex.ToString()
                };
            }
        }

        private static IngestXML BuildGPMSPayload(string xml, string fileName, Options options)
        {
            return new IngestXML
            {
                IngestURN = fileName,
                ProviderInputFormat = options.Alphas ? ProviderInputFormat.SonyAlpha : ProviderInputFormat.SonyGPMS,
                Data = Convert.ToBase64String(Encoding.UTF8.GetBytes(xml))
            };
        }


        private static bool IsValidXml(string xmlString)
        {
            var tagsWithData = new Regex("<\\w+>[^<]+</\\w+>");

            //Light checking
            if (string.IsNullOrEmpty(xmlString) || tagsWithData.IsMatch(xmlString) == false)
            {
                return false;
            }

            try
            {
                var xmlDocument = new XmlDocument();
                xmlDocument.LoadXml(xmlString);
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }
    }
}