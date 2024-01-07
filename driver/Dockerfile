FROM python:3.11.4

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY driver.py .

ENTRYPOINT ["python", "-u", "driver.py", "/app/config/config.yaml"]
