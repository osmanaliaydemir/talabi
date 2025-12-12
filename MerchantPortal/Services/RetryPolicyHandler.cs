using System.Net;

namespace Getir.MerchantPortal.Services;

public class RetryPolicyHandler : DelegatingHandler
{
	private static readonly HttpStatusCode[] TransientCodes = new[]
	{
		HttpStatusCode.RequestTimeout,
		HttpStatusCode.TooManyRequests,
		HttpStatusCode.BadGateway,
		HttpStatusCode.ServiceUnavailable,
		HttpStatusCode.GatewayTimeout
	};

	protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
	{
		var attempt = 0;
		var delay = 250; // ms
		while (true)
		{
			attempt++;
			try
			{
				var response = await base.SendAsync(request, cancellationToken);
				if (!IsTransient(response.StatusCode) || attempt >= 3)
					return response;
			}
			catch (HttpRequestException) when (attempt < 3)
			{
				// transient network error
			}
			catch (TaskCanceledException) when (attempt < 3)
			{
				// timeout
			}

			await Task.Delay(delay, cancellationToken);
			delay *= 2;
		}
	}

	private static bool IsTransient(HttpStatusCode code) => TransientCodes.Contains(code);
}


