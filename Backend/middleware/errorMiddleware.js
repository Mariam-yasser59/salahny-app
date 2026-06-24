export const notFound = (req, _res, next) => {
  const error = new Error(`Route not found - ${req.originalUrl}`);
  error.statusCode = 404;
  next(error);
};

export const errorHandler = (error, _req, res, _next) => {
  const statusCode =
    error.statusCode ||
    (error.code === 'LIMIT_FILE_SIZE' ? 400 : 500);

  res.status(statusCode).json({
    success: false,
    message:
      error.code === 'LIMIT_FILE_SIZE'
        ? 'File must be 5 MB or smaller'
        : error.message || 'Internal server error',
    stack: process.env.NODE_ENV === 'production' ? undefined : error.stack,
  });
};
