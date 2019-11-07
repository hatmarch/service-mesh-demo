# NOTE: These commands configured per:
# https://access.redhat.com/documentation/en-us/net_core/2.2/html/getting_started_guide/gs_install_dotnet
dotnet publish -c $1 -r rhel.7-x64 --self-contained=false /p:MicrosoftNETPlatformLibrary=Microsoft.NETCore.App