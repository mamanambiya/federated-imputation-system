FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1
ENV PIP_TIMEOUT=300

WORKDIR /app

# Copy requirements and install with extended timeout and retries
COPY requirements.txt .
RUN pip install --timeout=300 --retries=5 --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org -r requirements.txt

# Copy the Django project
COPY . .

# Create necessary directories
RUN mkdir -p static media uploads

EXPOSE 8000

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"] 