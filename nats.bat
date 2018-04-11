@echo off
IF "%1"=="-log" (
tailblazer nats.log
echo NATS Monitoring... %2 Logging to nats.log file.  Use Ctrl-C to exit
dotnet c:\tools\NATS\NATSTest.dll %2 > nats.log
) ELSE (
cls
echo NATS Monitoring... %1  Use Ctrl-C to exit
dotnet c:\tools\NATS\NATSTest.dll %1
)