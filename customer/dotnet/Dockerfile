FROM registry.access.redhat.com/dotnet/dotnet-22-runtime-rhel7

ARG config=Debug

ADD bin/${config}/netcoreapp2.2/rhel.7-x64/publish/. /app/

WORKDIR /app/

# Install vsdbg
USER root
RUN curl -sSL https://aka.ms/getvsdbgsh | /bin/sh /dev/stdin -v latest -l /vsdbg
USER default

EXPOSE 8080 10443

CMD ["scl", "enable", "rh-dotnet22", "--", "dotnet",  "customer.dll"]
