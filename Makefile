GO_DIR = go
JAVA_DIR = java
DATA_DIR = data
BENCH_FLAGS_GO = -bench=. -benchmem -cpu=1,4,8,16 -count=6

.PHONY: all help create-data \
        run-go-v1 microbenchmark-go-v1 heisenbug-check-go-v1 profile-go-v1\
		run-go-v2 microbenchmark-go-v2 heisenbug-check-go-v2 profile-go-v2\
        run-go-v3 microbenchmark-go-v3 heisenbug-check-go-v3 profile-go-v3\
		run-go-v4 microbenchmark-go-v4 heisenbug-check-go-v4 profile-go-v4\
        run-java-v1 \
		run-java-v2 \
		run-java-v3 \
		run-java-v4 \
		run-java-v5

all: help

help:
	@echo "Available commands:"
	@echo "  make create-data          	 	- Runs code to create data"
	@echo "  make run-go-v1            	 	- Runs the V1 in Go"
	@echo "  make run-go-v2      		 	- Runs the V2 in Go"
	@echo "  make run-go-v3      		 	- Runs the V3 in Go"
	@echo "  make run-go-v4      		 	- Runs the V4 in Go"
	@echo "  make microbenchmark-go-v1 	 	- Microbenchmark of V1 in Go"
	@echo "  make microbenchmark-go-v2 	 	- Microbenchmark of V2 in Go"
	@echo "  make microbenchmark-go-v3 	 	- Microbenchmark of V3 in Go"
	@echo "  make microbenchmark-go-v4 	 	- Microbenchmark of V4 in Go"
	@echo "  make heisenbug-check-go-v1  		- Check heisenbug of V1 in Go"
	@echo "  make heisenbug-check-go-v2  		- Check heisenbug of V2 in Go"
	@echo "  make heisenbug-check-go-v3  		- Check heisenbug of V3 in Go"
	@echo "  make heisenbug-check-go-v4  		- Check heisenbug of V4 in Go"
	@echo "  make profile-go-v1 		 	- Profile of V1 in Go (you need run Go V1  before)"
	@echo "  make profile-go-v2 		 	- Profile of V2 in Go (you need run Go V2  before)"
	@echo "  make profile-go-v3 		 	- Profile of V3 in Go (you need run Go V3  before)"
	@echo "  make profile-go-v4 		 	- Profile of V4 in Go (you need run Go V4  before)"
	@echo "  make run-java-v1    		 	- Runs the V1 in Java"
	@echo "  make run-java-v2    		 	- Runs the V2 in Java"
	@echo "  make run-java-v3    		 	- Runs the V3 in Java"
	@echo "  make run-java-v4    		 	- Runs the V4 in Java"
	@echo "  make run-java-v5    		 	- Runs the V5 in Java"

# 1. Python
create-data:
	@echo "Creating Data..."
	cd $(DATA_DIR) && python3 main.py

# 2. GO
clean-profile:
	-@pkill -f "go tool pprof"
	-@pkill -f "go tool trace"

run-go-v1:
	@echo "Run Go V1..."
	cd $(GO_DIR) && go run ./v1/

microbenchmark-go-v1:
	@echo "Microbenchmark Go V1..."
	cd $(GO_DIR) && \
	go test $(BENCH_FLAGS_GO) ./v1/ > results_v1.txt && \
	benchstat -format csv -col /cpu results_v1.txt > table_go_v1.csv

heisenbug-check-go-v1:
	@echo "Check Heisenbugs Go V1..."
	cd $(GO_DIR) && go test -c -race -o v1_stress.test ./v1/ && \
    timeout 15m stress ./v1_stress.test || true && \
    rm ./v1_stress.test

profile-go-v1:	clean-profile
	@echo "Opening profiles of CPU, Heap and Trace..."
	@nohup go tool pprof -http=:8080 go/v1/profile/cpu.prof > /dev/null 2>&1 &
	@nohup go tool pprof -http=:8081 go/v1/profile/heap.prof > /dev/null 2>&1 &
	@nohup go tool trace -http=:8082 go/v1/profile/trace.out > /dev/null 2>&1 &
	@echo "--------------------------------------------------------"
	@echo "Port 8080: CPU Profile (Most commonly used methods)"
	@echo "Port 8081: Heap Profile (Memory Usage/GC)"
	@echo "Port 8082: Trace (Thread containment and timeline)"
	@echo "--------------------------------------------------------"

run-go-v2:
	@echo "Run Go V2..."
	cd $(GO_DIR) && go run ./v2/

microbenchmark-go-v2:
	@echo "Microbenchmark Go V2..."
	cd $(GO_DIR) && \
	go test $(BENCH_FLAGS_GO) ./v2/ > results_v2.txt && \
	benchstat -format csv -col /cpu results_v2.txt > table_go_v2.csv

heisenbug-check-go-v2:
	@echo "Check Heisenbugs Go V2..."
	cd $(GO_DIR) && go test -c -race -o v2_stress.test ./v2/ && \
    timeout 15m stress ./v2_stress.test || true && \
    rm ./v2_stress.test

profile-go-v2:	clean-profile
	@echo "Opening profiles of CPU, Heap and Trace..."
	@nohup go tool pprof -http=:8080 go/v2/profile/cpu.prof > /dev/null 2>&1 &
	@nohup go tool pprof -http=:8081 go/v2/profile/heap.prof > /dev/null 2>&1 &
	@nohup go tool trace -http=:8082 go/v2/profile/trace.out > /dev/null 2>&1 &
	@echo "--------------------------------------------------------"
	@echo "Port 8080: CPU Profile (Most commonly used methods)"
	@echo "Port 8081: Heap Profile (Memory Usage/GC)"
	@echo "Port 8082: Trace (Thread containment and timeline)"
	@echo "--------------------------------------------------------"

run-go-v3:
	@echo "Run Go V3..."
	cd $(GO_DIR) && go run ./v3/

microbenchmark-go-v3:
	@echo "Microbenchmark Go V3..."
	cd $(GO_DIR) && \
	go test $(BENCH_FLAGS_GO) ./v3/ > results_v3.txt && \
	benchstat -format csv -col /cpu results_v3.txt > table_go_v3.csv

heisenbug-check-go-v3:
	@echo "Check Heisenbugs Go V3..."
	cd $(GO_DIR) && go test -c -race -o v3_stress.test ./v3/ && \
    timeout 15m stress ./v3_stress.test || true && \
    rm ./v3_stress.test

profile-go-v3:	clean-profile
	@echo "Opening profiles of CPU, Heap and Trace..."
	@nohup go tool pprof -http=:8080 go/v3/profile/cpu.prof > /dev/null 2>&1 &
	@nohup go tool pprof -http=:8081 go/v3/profile/heap.prof > /dev/null 2>&1 &
	@nohup go tool trace -http=:8082 go/v3/profile/trace.out > /dev/null 2>&1 &
	@echo "--------------------------------------------------------"
	@echo "Port 8080: CPU Profile (Most commonly used methods)"
	@echo "Port 8081: Heap Profile (Memory Usage/GC)"
	@echo "Port 8082: Trace (Thread containment and timeline)"
	@echo "--------------------------------------------------------"

run-go-v4:
	@echo "Run Go V4..."
	cd $(GO_DIR) && go run ./v4/

microbenchmark-go-v4:
	@echo "Microbenchmark Go V4..."
	cd $(GO_DIR) && \
	go test $(BENCH_FLAGS_GO) ./v4/ > results_v4.txt && \
	benchstat -format csv -col /cpu results_v4.txt > table_go_v4.csv

heisenbug-check-go-v4:
	@echo "Check Heisenbugs Go V4..."
	cd $(GO_DIR) && go test -c -race -o v4_stress.test ./v4/ && \
    timeout 15m stress ./v4_stress.test || true && \
    rm ./v4_stress.test

profile-go-v4:	clean-profile
	@echo "Opening profiles of CPU, Heap and Trace..."
	@nohup go tool pprof -http=:8080 go/v4/profile/cpu.prof > /dev/null 2>&1 &
	@nohup go tool pprof -http=:8081 go/v4/profile/heap.prof > /dev/null 2>&1 &
	@nohup go tool trace -http=:8082 go/v4/profile/trace.out > /dev/null 2>&1 &
	@echo "--------------------------------------------------------"
	@echo "Port 8080: CPU Profile (Most commonly used methods)"
	@echo "Port 8081: Heap Profile (Memory Usage/GC)"
	@echo "Port 8082: Trace (Thread containment and timeline)"
	@echo "--------------------------------------------------------"

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
