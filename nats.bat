@echo off
IF "%1" == "ingest" (
    echo deluxe.metadata-ingest.progress
    echo deluxe.metadata-ingest.payload
	goto exit
)

IF "%1" == "repo" (
    echo deluxe.metadata-repository.created
    echo deluxe.metadata-repository.updated
    echo deluxe.metadata-repository.deleted
	goto exit
) 

cls
echo NATS Monitoring... Use Ctrl-C to exit
dotnet c:\tools\NATS\NATSTest.dll %1


:exit