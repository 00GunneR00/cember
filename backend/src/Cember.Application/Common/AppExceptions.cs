namespace Cember.Application.Common;

public class NotFoundAppException(string message) : Exception(message);

public class ForbiddenAppException(string message) : Exception(message);

public class ValidationAppException(string message) : Exception(message);
