FROM mitmproxy/mitmproxy:latest
RUN apk upgrade -U --no-cache
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh
RUN adduser -Ds /bin/sh -u 1010 mitm
RUN mkdir -p /home/mitm/.mitmproxy
RUN chown -R mitm:mitm /home/mitm
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
CMD ["mitmdump"]
