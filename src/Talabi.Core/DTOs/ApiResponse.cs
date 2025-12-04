namespace Talabi.Core.DTOs;

public class ApiResponse<T>
{
    public bool Success { get; set; }
    public string? Message { get; set; }
    public T? Data { get; set; }
    public string? ErrorCode { get; set; }
    public List<string>? Errors { get; set; }

    public ApiResponse() { }

    public ApiResponse(T data, string? message = null)
    {
        Success = true;
        Data = data;
        Message = message;
    }

    public ApiResponse(string message, string? errorCode = null, List<string>? errors = null)
    {
        Success = false;
        Message = message;
        ErrorCode = errorCode;
        Errors = errors;
    }
}
