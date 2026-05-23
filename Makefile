GO_DIR = go
JAVA_DIR = java
DATA_DIR = data
BENCH_FLAGS_GO = -run=^$$ -bench=^Benchmark[a-zA-Z] -benchmem -count=6
THREADS ?= 4
EXECS ?= 20

.PHONY: all help create-data \
        run-go-v1 microbenchmark-go-v1 heisenbug-check-go-v1 profile-go-v1 saturation-go-v1\
        run-go-v2 microbenchmark-go-v2 heisenbug-check-go-v2 profile-go-v2 saturation-go-v2\
        run-go-v3 microbenchmark-go-v3 heisenbug-check-go-v3 profile-go-v3 saturation-go-v3\
        run-go-v4 microbenchmark-go-v4 heisenbug-check-go-v4 profile-go-v4 saturation-go-v4\
		run-go-v6 microbenchmark-go-v6 heisenbug-check-go-v6 profile-go-v6 saturation-go-v6\
		run-go-v7 microbenchmark-go-v7 heisenbug-check-go-v7 profile-go-v7 saturation-go-v7\
		run-go-v10 microbenchmark-go-v10 heisenbug-check-go-v10 profile-go-v10 saturation-go-v10\
        run-java-v1 \
        run-java-v2 \
        run-java-v3 \
        run-java-v4 \
        run-java-v5 \
        run-java-v6 \
        run-java-v7

all: help

help:
	@echo "Available commands:"
	@echo "  make create-data               - Runs code to create data"
	@echo "  make run-go-vX                 - Runs the VX in Go (where X in (1,2,3,4,6,7,10))"
	@echo "  make microbenchmark-go-vX      - Microbenchmark of VX in Go"
	@echo "  make heisenbug-check-go-vX     - Check heisenbug of VX in Go"
	@echo "  make profile-go-vX             - Profile of VX in Go"
	@echo "  make saturation-go-vX          - Saturation test of VX in Go"
	@echo "                                   Example: make saturation-go-v2 THREADS=8 EXECS=40"
	@echo "  make run-java-vX               - Runs the VX in Java (where X in (1,2,3,4,5,6,7))"

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
	benchstat results_v1.txt

heisenbug-check-go-v1:
	@echo "Check Heisenbugs Go V1..."
	cd $(GO_DIR) && go test -race -cpu=2,4,8 -count=10 -run=^Test ./v1/...

profile-go-v1:  clean-profile
	@echo "Opening profiles of CPU, Heap and Trace V1..."
	@nohup go tool pprof -http=:8080 go/v1/profile/cpu.prof > /dev/null 2>&1 &
	@nohup go tool pprof -http=:8081 go/v1/profile/heap.prof > /dev/null 2>&1 &
	@nohup go tool trace -http=:8082 go/v1/profile/trace.out > /dev/null 2>&1 &

saturation-go-v1:
	@echo "Running Macro Saturation Test Go V1 (THREADS=$(THREADS), EXECS=$(EXECS))..."
	cd $(GO_DIR) && \
	go test -v -tags saturation -run=^TestMacroBenchmarkSaturation$$ ./v1/ -args -threads=$(THREADS) -execs=$(EXECS)

run-go-v2:
	@echo "Run Go V2..."
	cd $(GO_DIR) && go run ./v2/

microbenchmark-go-v2:
	@echo "Microbenchmark Go V2..."
	cd $(GO_DIR) && \
	go test $(BENCH_FLAGS_GO) ./v2/ > results_v2.txt && \
	benchstat results_v2.txt

heisenbug-check-go-v2:
	@echo "Check Heisenbugs Go V2..."
	cd $(GO_DIR) && go test -race -cpu=2,4,8 -count=10 -run=^Test ./v2/...

profile-go-v2:  clean-profile
	@echo "Opening profiles of CPU, Heap and Trace V2..."
	@nohup go tool pprof -http=:8080 go/v2/profile/cpu.prof > /dev/null 2>&1 &
	@nohup go tool pprof -http=:8081 go/v2/profile/heap.prof > /dev/null 2>&1 &
	@nohup go tool trace -http=:8082 go/v2/profile/trace.out > /dev/null 2>&1 &

saturation-go-v2:
	@echo "Running Macro Saturation Test Go V2 (THREADS=$(THREADS), EXECS=$(EXECS))..."
	cd $(GO_DIR) && \
	go test -v -tags saturation -run=^TestMacroBenchmarkSaturation$$ ./v2/ -args -threads=$(THREADS) -execs=$(EXECS)

run-go-v3:
	@echo "Run Go V3..."
	cd $(GO_DIR) && go run ./v3/

microbenchmark-go-v3:
	@echo "Microbenchmark Go V3..."
	cd $(GO_DIR) && \
	go test $(BENCH_FLAGS_GO) ./v3/ > results_v3.txt && \
	benchstat results_v3.txt

heisenbug-check-go-v3:
	@echo "Check Heisenbugs Go V3..."
	cd $(GO_DIR) && go test -race -cpu=2,4,8 -count=10 -run=^Test ./v3/...

profile-go-v3:  clean-profile
	@echo "Opening profiles of CPU, Heap and Trace V3..."
	@nohup go tool pprof -http=:8080 go/v3/profile/cpu.prof > /dev/null 2>&1 &
	@nohup go tool pprof -http=:8081 go/v3/profile/heap.prof > /dev/null 2>&1 &
	@nohup go tool trace -http=:8082 go/v3/profile/trace.out > /dev/null 2>&1 &

saturation-go-v3:
	@echo "Running Macro Saturation Test Go V3 (THREADS=$(THREADS), EXECS=$(EXECS))..."
	cd $(GO_DIR) && \
	go test -v -tags saturation -run=^TestMacroBenchmarkSaturation$$ ./v3/ -args -threads=$(THREADS) -execs=$(EXECS)

run-go-v4:
	@echo "Run Go V4..."
	cd $(GO_DIR) && go run ./v4/

microbenchmark-go-v4:
	@echo "Microbenchmark Go V4..."
	cd $(GO_DIR) && \
	go test $(BENCH_FLAGS_GO) ./v4/ > results_v4.txt && \
	benchstat results_v4.txt

heisenbug-check-go-v4:
	@echo "Check Heisenbugs Go V4..."
	cd $(GO_DIR) && go test -race -cpu=2,4,8 -count=10 -run=^Test ./v4/...

profile-go-v4:  clean-profile
	@echo "Opening profiles of CPU, Heap and Trace V4..."
	@nohup go tool pprof -http=:8080 go/v4/profile/cpu.prof > /dev/null 2>&1 &
	@nohup go tool pprof -http=:8081 go/v4/profile/heap.prof > /dev/null 2>&1 &
	@nohup go tool trace -http=:8082 go/v4/profile/trace.out > /dev/null 2>&1 &

saturation-go-v4:
	@echo "Running Macro Saturation Test Go V4 (THREADS=$(THREADS), EXECS=$(EXECS))..."
	cd $(GO_DIR) && \
	go test -v -tags saturation -run=^TestMacroBenchmarkSaturation$$ ./v4/ -args -threads=$(THREADS) -execs=$(EXECS)

run-go-v6:
	@echo "Run Go V6..."
	cd $(GO_DIR) && go run ./v6/

microbenchmark-go-v6:
	@echo "Microbenchmark Go V6..."
	cd $(GO_DIR) && \
	go test $(BENCH_FLAGS_GO) ./v6/ > results_v6.txt && \
	benchstat results_v6.txt

heisenbug-check-go-v6:
	@echo "Check Heisenbugs Go V6..."
	cd $(GO_DIR) && go test -race -cpu=2,4,8 -count=10 -run=^Test ./v6/...

profile-go-v6:  clean-profile
	@echo "Opening profiles of CPU, Heap and Trace V6..."
	@nohup go tool pprof -http=:8080 go/v6/profile/cpu.prof > /dev/null 2>&1 &
	@nohup go tool pprof -http=:8081 go/v6/profile/heap.prof > /dev/null 2>&1 &
	@nohup go tool trace -http=:8082 go/v6/profile/trace.out > /dev/null 2>&1 &

saturation-go-v6:
	@echo "Running Macro Saturation Test Go V6 (THREADS=$(THREADS), EXECS=$(EXECS))..."
	cd $(GO_DIR) && \
	go test -v -tags saturation -run=^TestMacroBenchmarkSaturation$$ ./v6/ -args -threads=$(THREADS) -execs=$(EXECS)

run-go-v7:
	@echo "Run Go V7..."
	cd $(GO_DIR) && go run ./v7/

microbenchmark-go-v7:
	@echo "Microbenchmark Go V7..."
	cd $(GO_DIR) && \
	go test $(BENCH_FLAGS_GO) ./v7/ > results_v7.txt && \
	benchstat results_v7.txt

heisenbug-check-go-v7:
	@echo "Check Heisenbugs Go V7..."
	cd $(GO_DIR) && go test -race -cpu=2,4,8 -count=10 -run=^Test ./v7/...

profile-go-v7:  clean-profile
	@echo "Opening profiles of CPU, Heap and Trace V7..."
	@nohup go tool pprof -http=:8080 go/v7/profile/cpu.prof > /dev/null 2>&1 &
	@nohup go tool pprof -http=:8081 go/v7/profile/heap.prof > /dev/null 2>&1 &
	@nohup go tool trace -http=:8082 go/v7/profile/trace.out > /dev/null 2>&1 &

saturation-go-v7:
	@echo "Running Macro Saturation Test Go V7 (THREADS=$(THREADS), EXECS=$(EXECS))..."
	cd $(GO_DIR) && \
	go test -v -tags saturation -run=^TestMacroBenchmarkSaturation$$ ./v7/ -args -threads=$(THREADS) -execs=$(EXECS)

run-go-v10:
	@echo "Run Go V10..."
	cd $(GO_DIR) && go run ./v10/

microbenchmark-go-v10:
	@echo "Microbenchmark Go V10..."
	cd $(GO_DIR) && \
	go test $(BENCH_FLAGS_GO) ./v10/ > results_v10.txt && \
	benchstat results_v10.txt

heisenbug-check-go-v10:
	@echo "Check Heisenbugs Go V10..."
	cd $(GO_DIR) && go test -race -cpu=2,4,8 -count=10 -run=^Test ./v10/...

profile-go-v10:  clean-profile
	@echo "Opening profiles of CPU, Heap and Trace V10..."
	@nohup go tool pprof -http=:8080 go/v10/profile/cpu.prof > /dev/null 2>&1 &
	@nohup go tool pprof -http=:8081 go/v10/profile/heap.prof > /dev/null 2>&1 &
	@nohup go tool trace -http=:8082 go/v10/profile/trace.out > /dev/null 2>&1 &

saturation-go-v10:
	@echo "Running Macro Saturation Test Go V10 (THREADS=$(THREADS), EXECS=$(EXECS))..."
	cd $(GO_DIR) && \
	go test -v -tags saturation -run=^TestMacroBenchmarkSaturation$$ ./v10/ -args -threads=$(THREADS) -execs=$(EXECS)

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

run-java-v6:
	@echo "Run Java V6..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v6

run-java-v7:
	@echo "Run Java V7..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v7
