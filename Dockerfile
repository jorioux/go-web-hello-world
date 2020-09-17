FROM golang:latest

COPY *.go .

EXPOSE 8081

CMD ["go","run","helloworld.go"]