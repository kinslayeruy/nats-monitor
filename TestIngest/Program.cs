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
using TestIngest.Models;

namespace TestIngest
{
    internal class Program
    {
        private static long _processed;
        private static readonly object WriteLock = new object();

        public static void Main(string[] args)
        {
            Console.WriteLine(@"Test Ingest Tool - v1.3");

            if (args.Any() && args[0] == "-?")
            {
                Console.WriteLine(Options.Help());
                Environment.Exit(0);
            }

            var options = new Options(args);

            var atlasResults = new List<TestResult>();
            var mrResults = new List<TestResult>();
            var linkResults = new List<TestResult>();

            const string logFile = "test.log";
            using (File.Create(logFile))
            {
                Debug.WriteLine("file created");
            }
            WriteToLog(logFile, "Starting...", true);

            var workDir = Environment.CurrentDirectory;
            var allFilesEnum = Directory.EnumerateFiles(workDir, "*.xml",
                options.Subdirectories ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly);
            var allFiles = allFilesEnum.ToArray();
            WriteToLog(logFile, $"Found {allFiles.Length} files.", true);

            var pad = (int) Math.Floor(Math.Log10(allFiles.Length) + 1);
            var watch = new Stopwatch();
            watch.Start();
            var maxParallel = options.MaxParallel;
            Console.WriteLine($"Setting max parallelism to {maxParallel} threads");
            var paraOptions = new ParallelOptions {MaxDegreeOfParallelism = maxParallel};
            
            if (maxParallel > 1 && options.Subdirectories)
            {
                var currDir = workDir;
                ProcessDir(currDir,"", paraOptions, allFiles.Length, pad, logFile, atlasResults, mrResults, linkResults, options, watch);                
            }
            else
            {
                Parallel.ForEach(allFiles, paraOptions,
                    (file, state, index) =>
                    {
                        ProcessTitle(file, allFiles.Length, index.ToString(), workDir, pad, logFile, atlasResults, mrResults, linkResults, options, watch);
                    });
            }

            var totalAtlas = atlasResults.Count;
            var successAtlas = atlasResults.Count(r => r.Success);
            var totalMR = mrResults.Count;
            var successMR = mrResults.Count(r => r.Success);
            var totalLink = linkResults.Count;
            var successLink = linkResults.Count(r => r.Success);
            
            Console.WriteLine(
                $"Finished {(totalAtlas + totalMR + totalLink):N0} calls, time taken {TimeSpan.FromMilliseconds(watch.ElapsedMilliseconds):g}");
            WriteToLog(logFile,
                $"Atlas: {totalAtlas:N0} calls, {successAtlas:N0} successful, ({((double) successAtlas / totalAtlas):P1})", true);
            WriteToLog(logFile,
                $"MR   : {totalMR:N0} calls, {successMR:N0} successful, ({((double) successMR / totalMR):P1})", true);
            WriteToLog(logFile,
                $"Link : {totalLink:N0} calls, {successLink:N0} successful, ({((double) successLink / totalLink):P1})",
                true);
            File.Copy(logFile, $"test-{DateTime.UtcNow:yyyy-MM-dd-HH-mm-ss}.log");
        }

        private static void ProcessDir(string currDir, string dirIndex, ParallelOptions paraOptions, long totalFiles, int pad, string logFile,
            List<TestResult> atlasResults, List<TestResult> mrResults, List<TestResult> linkResults, Options options, Stopwatch watch)
        {
            Console.WriteLine("Processing directory " + currDir);
            var dirFiles = Directory.EnumerateFiles(currDir, "*.xml").ToArray();
            for (var index = 0; index < dirFiles.Length; index++)
            {
                var file = dirFiles[index];
                ProcessTitle(file, totalFiles, $"{dirIndex}.{index}", currDir, pad, logFile, atlasResults, mrResults, linkResults, options, watch);
            }

            
            var dirFolders = Directory.EnumerateDirectories(currDir).ToArray();

            Parallel.ForEach(dirFolders, paraOptions,
                (folder, state, index) =>
                {
                    ProcessDir(folder, dirIndex + "/" + index, paraOptions, totalFiles, pad, logFile, atlasResults, mrResults, linkResults, options, watch);
                });
        }

        private static void ProcessTitle(string file, long totalFiles, string index, string workDir, int pad, string logFile,
            List<TestResult> atlasResults, List<TestResult> mrResults, List<TestResult> linkResults, Options options, Stopwatch watch)
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
                                            $"{index} - {testResult.GetAsString()}", false);

                atlasResults.Add(testResult);
                mrResults.Add(testResult);
                linkResults.Add(testResult);
            }

            var ingestXML = BuildGPMSPayload(xml, fileForLog, options);
            var atlas = options.SkipAtlas
                ? new TestResult {Skipped = true}
                : CallAtlas(ingestXML, options).GetAwaiter().GetResult();
            var mr = options.SkipMetadata
                ? new TestResult {Skipped = true}
                : CallMetadata(ingestXML, options).GetAwaiter().GetResult();
            var link = options.SkipLinking
                ? new[] {new TestResult {Skipped = true}}
                : CallLink(ingestXML, atlas, mr, options).GetAwaiter().GetResult().ToArray();
            

            var linkStatus = string.Join(", ", link.Select(l => l.GetAsString()));

            WriteToLog(logFile,
                $"{index} - Testing {fileForLog}\n" +
                (options.SkipAtlas ? "" : $"{index} - AtlasCall - {atlas.GetAsString()}\n") +
                (options.SkipMetadata ? "" :  $"{index} - MRCall    - {mr.GetAsString()}\n") +
                (options.SkipLinking ? "" : $"{index} - LinkCalls - {linkStatus}"), false);

            atlasResults.Add(atlas);
            mrResults.Add(mr);
            linkResults.AddRange(link);

            var time = watch.ElapsedMilliseconds;
            _processed++;
            var status = (!options.SkipAtlas ? $"- {atlas.GetStatus()}" : "") +
                         (!options.SkipMetadata ? $"- {mr.GetStatus()}" : "") +
                         (!options.SkipLinking ? $"- {linkStatus}" : "") +
                         "\n";
            Console.WriteLine($"{index} " +
                              status +
                              $"- Progress {_processed.ToString().PadLeft(pad)}/{totalFiles} ({((double) _processed / totalFiles):P1})- Took {(time - startTime):N0} ms " +
                              $"- Estimated time left: {TimeSpan.FromMilliseconds(((double) (time * totalFiles) / (_processed)) - time).TotalMinutes:N0} minutes aprox");
        }


        private static void WriteToLog(string logFile, string text, bool withConsole)
        {
            lock (WriteLock)
            {
                if (withConsole) Console.WriteLine(text);
                File.AppendAllText(logFile, text + "\n");
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
                        Result = JsonConvert.DeserializeObject<MetadataIngestEvent>(content)
                    };
                }

                var mie = JsonConvert.DeserializeObject<MetadataIngestEvent>(content);
                if (mie.OverallStatus == PayloadStatus.Success)
                {
                    return new TestResult
                    {
                        Success = true,
                        FailureReason = null,
                        Result = mie
                    };
                }

                return new TestResult
                {
                    Success = false,
                    FailureReason = mie.PayloadResults
                        .FirstOrDefault(f => !string.IsNullOrWhiteSpace(f.FailureReason))?.FailureReason,
                    Result = mie
                };
            }
            catch (Exception ex)
            {
                return new TestResult
                {
                    Success = false,
                    FailureReason = $"Call to MR ingest failed {ex.Message}"                    
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
                        Result = JsonConvert.DeserializeObject<MetadataIngestEvent>(content)
                    };
                }

                var mie = JsonConvert.DeserializeObject<MetadataIngestEvent>(content);
                if (mie.OverallStatus == PayloadStatus.Success)
                {
                    return new TestResult
                    {
                        Success = true,
                        FailureReason = null,
                        Result = mie
                    };
                }

                return new TestResult
                {
                    Success = false,
                    FailureReason = mie.PayloadResults
                        .FirstOrDefault(f => !string.IsNullOrWhiteSpace(f.FailureReason))?.FailureReason,
                    Result = mie
                };
            }
            catch (Exception ex)
            {
                return new TestResult
                {
                    Success = false,
                    FailureReason = $"Call to Atlas ingest failed {ex.Message}"
                };
            }
        }

        private static async Task<IEnumerable<TestResult>> CallLink(IngestXML xml, TestResult atlasResult, TestResult mrResult, Options options)
        {
            if (!atlasResult.Success)
            {
                return new[] {new TestResult
                {
                    Success = false,
                    FailureReason = atlasResult.FailureReason
                }};
            }

            var client = new HttpClient { BaseAddress = new Uri(options.Host) };
            var results = new List<TestResult>();
            if (mrResult?.Result != null && atlasResult?.Result != null)
            {
                foreach (var payloadResult in mrResult.Result.PayloadResults)
                {
                    if (payloadResult.Status == PayloadStatus.Failure)
                    {
                        results.Add(new TestResult {Success = false, FailureReason = payloadResult.FailureReason});
                        continue;
                    }

                    if (payloadResult.Action == PayloadAction.Skipped)
                    {
                        results.Add(new TestResult {Success = true});
                        continue;
                    }

                    var link = new Link
                    {
                        IngestURN = xml.IngestURN,
                        AtlasIds = atlasResult.Result.PayloadResults.First().AtlasURNs,
                        MetadataRepositoryId = payloadResult.MetadataRepositoryURN
                    };

                    var response = await client.PostAsync(
                        "v1/ingest/link" + (options.DoNotHidePayload ? "" : "?verbosity=HidePayload"),
                        new StringContent(JsonConvert.SerializeObject(link), Encoding.UTF8,
                            "application/json"));
                    if (response.IsSuccessStatusCode)
                    {
                        results.Add(new TestResult
                        {
                            Success = true
                        });
                    }
                }
            }
            else
            {
                results.Add(new TestResult
                {
                    Success = false,
                    FailureReason = "No results in Metadata or Atlas Results"                    
                });
            }

            return results;

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