# DIRs
GO_DIR=go
JAVA_DIR=java
DATA_DIR=data

.PHONY: all help create-data run-go-v1 run-go-v2 run-java-v1 run-java-v2

help:
	@echo "Available commands:"
	@echo "  make create-data    - Runs code to create data"
	@echo "  make run-go-v1      - Runs the V1 in Go"
	@echo "  make run-go-v2      - Runs the V2 in Go"
	@echo "  make run-java-v1    - Runs the V1 in Java"
	@echo "  make run-java-v2    - Runs the V2 in Java"
	@echo "  make run-java-v3    - Runs the V3 in Java"
	@echo "  make run-java-v4    - Runs the V4 in Java"
	@echo "  make run-java-v5    - Runs the V5 in Java"

# 1. Python
create-data:
	@echo "Creating Data"
	cd $(DATA_DIR) && python3 main.py

# 2. GO
run-go-v1:
	@echo "Run Go V1..."
	cd $(GO_DIR) && go run ./v1/

run-go-v2:
	@echo "Run Go V2..."
	cd $(GO_DIR) && go run ./v2/

# 3. JAVA
run-java-v1:
	@echo "Run Java V1..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v1

run-java-v2:
	@echo "Run Java V2..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v2

run-java-v3:
	@echo "Run Java V3..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v3

run-java-v4:
	@echo "Run Java V4..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v4

run-java-v5:
	@echo "Run Java V5..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v5
