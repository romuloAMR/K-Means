# DIRs
GO_DIR=go
JAVA_DIR=java
DATA_DIR=data

.PHONY: all help create-data run-go-v1 run-go-v2 run-java-v1 run-java-v2

help:
	@echo "Available commands:"
	@echo "  make create-data    - Runs code to create data"
	@echo "  make run-go-v1      - Runs the Serial version in Go"
	@echo "  make run-go-v2      - Runs the Parallel version in Go"
	@echo "  make run-java-v1    - Runs the Serial version in Java"
	@echo "  make run-java-v2    - Runs the Parallel version in Java"

# 1. Python
create-data:
	@echo "Creating Data"
	cd $(DATA_DIR) && python3 main.py

# 2. GO
run-go-v1:
	@echo "Run Go V1 (Serial)..."
	cd $(GO_DIR) && go run ./v1/main.go

run-go-v2:
	@echo "Run Go V2 (Parallel)..."
	cd $(GO_DIR) && go run ./v2/main.go

# 3. JAVA
run-java-v1:
	@echo "Run Java V1 (Serial)..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v1

run-java-v2:
	@echo "Run Java V2 (Parallel)..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v2
