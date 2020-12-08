FROM maartene/mission2mars:0.1.3
ENV ENVIRONMENT=production
ENTRYPOINT ./Run serve --hostname 0.0.0.0 --port 8080
