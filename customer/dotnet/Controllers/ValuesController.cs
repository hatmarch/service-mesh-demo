using System;
using Microsoft.AspNetCore.Mvc;
using System.Net;
using System.Net.Http;

namespace dotnet.Controllers
{
    [Route("/")]
    public class ValuesController : Controller
    {
        const string url = "http://recommendation:8080/";
        const string responseStringFormat = "Customer {0} => {1}\n";

        static HttpClient client = new HttpClient();

        private string callPreference()
        {
            string response = "unknown";
            using (var task = client.GetStringAsync(url))
            {
                response = task.Result;
            }

            return response;
        }

        // GET api/values
        [HttpGet]
        public IActionResult Get()
        {
            HttpStatusCode code = HttpStatusCode.OK;

            var messageOverride = System.Environment.GetEnvironmentVariable("MESSAGE_OVERRIDE");
            Console.WriteLine("MESSAGE_OVERRIDE is {0}", messageOverride == null ? "not existent" : messageOverride);

            string hostname = Dns.GetHostName();
            string preferenceResponse = "<unknown>";
            if (messageOverride != null)
            {
                preferenceResponse = messageOverride;
            }
            else
            {
                try
                {
                    preferenceResponse = callPreference();
                }
                catch (Exception e)
                {
                    Console.WriteLine("Error calling preference service: {0}", e.Message);
                    code = HttpStatusCode.ServiceUnavailable;
                }
            }

            return StatusCode((int)code, String.Format(responseStringFormat, hostname, preferenceResponse));
        }
    }
}
