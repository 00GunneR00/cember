using Cember.Application.Common;

namespace Cember.Api.Middleware;

public class AppExceptionMiddleware(RequestDelegate next)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (NotFoundAppException ex)
        {
            await WriteProblemAsync(context, StatusCodes.Status404NotFound, ex.Message);
        }
        catch (ForbiddenAppException ex)
        {
            await WriteProblemAsync(context, StatusCodes.Status403Forbidden, ex.Message);
        }
        catch (ValidationAppException ex)
        {
            await WriteProblemAsync(context, StatusCodes.Status400BadRequest, ex.Message);
        }
    }

    private static async Task WriteProblemAsync(HttpContext context, int statusCode, string message)
    {
        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/problem+json";
        await context.Response.WriteAsJsonAsync(new { status = statusCode, message });
    }
}
