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
        private static long _processed;
        private static readonly object WriteLock = new object();

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

            const string logFile = "test.log";
            File.Create(logFile).Close();
            Console.WriteLine("Starting...");
            WriteToLog(logFile, "Starting...\n");

            var workDir = Environment.CurrentDirectory;
            var allFilesEnum = Directory.EnumerateFiles(workDir, "*.xml",
                options.Subdirectories ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly);
            var allFiles = allFilesEnum.ToArray();
            Console.WriteLine($"Found {allFiles.Length} files.");
            WriteToLog(logFile, $"Found {allFiles.Length} files.\n");

            var pad = (int) Math.Floor(Math.Log10(allFiles.Length) + 1);
            var watch = new Stopwatch();
            watch.Start();
            var maxParallel = options.MaxParallel;
            Console.WriteLine($"Setting max parallelism to {maxParallel} threads");
            var paraOptions = new ParallelOptions {MaxDegreeOfParallelism = maxParallel};
            
            if (maxParallel > 1 && options.Subdirectories)
            {
                var currDir = workDir;
                ProcessDir(currDir,"", paraOptions, allFiles.Length, pad, logFile, atlasResults, mrResults, options, watch);                
            }
            else
            {
                Parallel.ForEach(allFiles, paraOptions,
                    (file, state, index) =>
                    {
                        ProcessTitle(file, allFiles.Length, index.ToString(), workDir, pad, logFile, atlasResults, mrResults, options, watch);
                    });
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
            WriteToLog(logFile,
                $"Atlas: {totalAtlas:N0} calls, {successAtlas:N0} successful, ({((double) successAtlas / totalAtlas):P1})\n");
            WriteToLog(logFile,
                $"MR   : {totalMR:N0} calls, {successMR:N0} successful, ({((double) successMR / totalMR):P1})\n");
            File.Copy(logFile, $"test-{DateTime.UtcNow:yyyy-MM-dd-HH-mm-ss}.log");
        }

        private static void ProcessDir(string currDir, string dirIndex, ParallelOptions paraOptions, long totalFiles, int pad, string logFile,
            List<TestResult> atlasResults, List<TestResult> mrResults, Options options, Stopwatch watch)
        {
            Console.WriteLine("Processing directory " + currDir);
            var dirFiles = Directory.EnumerateFiles(currDir, "*.xml").ToArray();
            for (var index = 0; index < dirFiles.Length; index++)
            {
                var file = dirFiles[index];
                ProcessTitle(file, totalFiles, $"{dirIndex}.{index}", currDir, pad, logFile, atlasResults, mrResults, options, watch);
            }

            
            var dirFolders = Directory.EnumerateDirectories(currDir).ToArray();

            Parallel.ForEach(dirFolders, paraOptions,
                (folder, state, index) =>
                {
                    ProcessDir(folder, dirIndex + "/" + index, paraOptions, totalFiles, pad, logFile, atlasResults, mrResults, options, watch);
                });
        }

        private static void ProcessTitle(string file, long totalFiles, string index, string workDir, int pad, string logFile,
            List<TestResult> atlasResults, List<TestResult> mrResults, Options options, Stopwatch watch)
        {
            var startTime = watch.ElapsedMilliseconds;
            var fileForLog = file.Remove(0, workDir.Length);
            var xml = File.ReadAllText(file, Encoding.UTF8);
            if (!IsValidXml(xml))
            {
                var testResult = new TestResult
                {
                    Success = false,
                    FailureReason = $"File {file} is not a valid XML"
                };
                Console.WriteLine($"{index} - {testResult.GetAsString()} - File:{fileForLog}");
                WriteToLog(logFile, $"{index} - Testing {fileForLog}\n" +
                                            $"{index} - {testResult.GetAsString()}\n");

                atlasResults.Add(testResult);
                mrResults.Add(testResult);
            }

            var ingestXML = BuildGPMSPayload(xml, fileForLog, options);

            var atlas = CallAtlas(ingestXML, options).GetAwaiter().GetResult();
            var mr = CallMetadata(ingestXML, options).GetAwaiter().GetResult();
            WriteToLog(logFile,
                $"{index} - Testing {fileForLog}\n" +
                $"{index} - AtlasCall - {atlas.GetAsString()}\n" +
                $"{index} - MRCall    - {mr.GetAsString()}\n");                

            atlasResults.Add(atlas);
            mrResults.Add(mr);
            var time = watch.ElapsedMilliseconds;
            _processed++;
            Console.WriteLine($"{index} " +
                              $"- {atlas.GetStatus()} - {mr.GetStatus()} " +
                              $"- Progress {_processed.ToString().PadLeft(pad)}/{totalFiles} ({((double) _processed / totalFiles):P1})- Took {(time - startTime):N0} ms " +
                              $"- Estimated time left: {TimeSpan.FromMilliseconds(((double) (time * totalFiles) / (_processed)) - time).TotalMinutes:N0} minutes aprox");
        }


        private static void WriteToLog(string logFile, string text)
        {
            lock (WriteLock)
            {
                File.AppendAllText(logFile, text);
            }
        }
        
        private static async Task<TestResult> CallMetadata(IngestXML xml, Options options)
        {
            var client = new HttpClient {BaseAddress = new Uri(options.Host)};
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
            var client = new HttpClient {BaseAddress = new Uri(options.Host)};

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