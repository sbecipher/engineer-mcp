FROM python:3.14-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

# Port mapping for Cloud Run
ENV PORT=8080
EXPOSE 8080

CMD ["python", "-m", "app.main"]
