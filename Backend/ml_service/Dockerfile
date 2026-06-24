FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py ./app.py
COPY models ./models

EXPOSE 8080

CMD ["sh", "-c", "exec gunicorn --workers 1 --threads 4 --timeout 120 --bind 0.0.0.0:${PORT:-8080} app:app"]
