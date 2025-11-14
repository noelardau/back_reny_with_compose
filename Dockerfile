FROM golang:1.25.4

WORKDIR /app

# Copie go mod
COPY go.mod go.sum ./
RUN go mod tidy

# Copie le code
COPY . .

# Compile (optionnel, mais recommandé)
# RUN go build -o main .
EXPOSE 3000

# Lance
CMD ["go", "run", "main.go"]