using Serilog.Context;

namespace Getir.MerchantPortal.Middleware;

public class SerilogEnrichMiddleware
{
	private readonly RequestDelegate _next;

	public SerilogEnrichMiddleware(RequestDelegate next)
	{
		_next = next;
	}

	public async Task Invoke(HttpContext context)
	{
		var userName = context.Session.GetString("UserName") ?? context.User.Identity?.Name ?? "anon";
		var merchantId = context.Session.GetString("MerchantId") ?? "-";
		using (LogContext.PushProperty("UserName", userName))
		using (LogContext.PushProperty("MerchantId", merchantId))
		{
			await _next(context);
		}
	}
}


