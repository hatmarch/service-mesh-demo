#!/bin/bash

# This shows how all the environment variables need to be set to get kestrel to run 
# https with the secrets certificate
docker run -it -p 50000:10443 -p 50001:8080 \
    -e ASPNETCORE_URLS="https://*:10443;http://*:8080" \
    -e ASPNETCORE_HTTPS_PORT=10443 \
    -v /Users/marc.hildenbrand/Documents/Development/istio-tutorial/secrets:/secrets \
    -e ASPNETCORE_Kestrel__Certificates__Default__Password=atodemo \
    -e ASPNETCORE_Kestrel__Certificates__Default__Path=/secrets/certificate.pfx \
    mhildema/customer-dotnet:latest
