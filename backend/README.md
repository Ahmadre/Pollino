# Pollino Backend

## Spring Boot + MongoDB Backend API

### Architecture
- **Spring Boot 3.3** with Java 21
- **MongoDB** as document database
- **Spring Security** with API key auth and rate limiting
- **Scheduled cleanup** for expired polls (replaces pollino-cleanup container)

### Building
```bash
./mvnw clean package
```

### Running locally
```bash
./mvnw spring-boot:run
```

### Configuration
See `src/main/resources/application.yml` for all configuration options.
Key environment variables:
- `MONGODB_URI` - MongoDB connection string
- `API_KEY` - API key for protected endpoints
- `CORS_ALLOWED_ORIGINS` - Allowed CORS origins
- `CLEANUP_CRON` - Cron expression for cleanup schedule
