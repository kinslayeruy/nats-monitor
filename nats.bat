@echo off
IF "%1"=="-log" (
tailblazer nats.log
echo NATS Monitoring... Logging to nats.log file.  Use Ctrl-C to exit
dotnet c:\tools\NATS\NATSTest.dll %2 > nats.log
) ELSE (
cls
echo NATS Monitoring...  Use Ctrl-C to exit
dotnet c:\tools\NATS\NATSTest.dll %1
)