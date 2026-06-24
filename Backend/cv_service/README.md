# Salahny CV Verification Service

Small Flask service used by the Node backend through `CV_SERVICE_URL`.

## Endpoints

- `GET /health`
- `POST /verify-document`

`POST /verify-document` expects multipart form fields:

- `file`
- `role`: `driver` or `workshop`
- `documentType`: e.g. `driver_license`, `workshop_permit`

## Railway deployment

Create a new Railway service from this repository with root directory:

```text
Backend/cv_service
```

Railway will use the included `Dockerfile` / `railway.json`.

After Railway gives the service a public URL, set the backend service variable:

```env
CV_SERVICE_URL=https://your-cv-service.up.railway.app
```

Then redeploy the Node backend.
