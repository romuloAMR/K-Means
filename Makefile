GO_DIR = go
JAVA_DIR = java
DATA_DIR = data
BENCH_FLAGS_GO = -run=^$$ -bench=^Benchmark[a-zA-Z] -benchmem -count=6
THREADS ?= 4
EXECS ?= 20

.PHONY: all help create-data \
        run-go-v1    microbenchmark-go-v1    heisenbug-check-go-v1  profile-go-v1  saturation-go-v1\
        run-go-v2    microbenchmark-go-v2    heisenbug-check-go-v2  profile-go-v2  saturation-go-v2\
        run-go-v3    microbenchmark-go-v3    heisenbug-check-go-v3  profile-go-v3  saturation-go-v3\
        run-go-v4    microbenchmark-go-v4    heisenbug-check-go-v4  profile-go-v4  saturation-go-v4\
		run-go-v6    microbenchmark-go-v6    heisenbug-check-go-v6  profile-go-v6  saturation-go-v6\
		run-go-v7    microbenchmark-go-v7    heisenbug-check-go-v7  profile-go-v7  saturation-go-v7\
		run-go-v10   microbenchmark-go-v10   heisenbug-check-go-v10 profile-go-v10 saturation-go-v10\
        run-java-v1  microbenchmark-java-v1  profile-java-v1 \
        run-java-v2  microbenchmark-java-v2  profile-java-v2 \
        run-java-v3  microbenchmark-java-v3  profile-java-v3 \
        run-java-v4  microbenchmark-java-v4  profile-java-v4 \
        run-java-v5  microbenchmark-java-v5  profile-java-v5 \
        run-java-v6  microbenchmark-java-v6  profile-java-v6 \
        run-java-v7  microbenchmark-java-v7  profile-java-v7 \
        run-java-v8  microbenchmark-java-v8  profile-java-v8 \
        run-java-v9  microbenchmark-java-v9  profile-java-v9 \
        run-java-v10 microbenchmark-java-v10 profile-java-v10

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
	@echo "  make run-java-vX               - Runs the VX in Java (where X in (1,2,3,4,5,6,7,8,9,10))"
	@echo "  make microbenchmark-java-vX    - Microbenchmark of VX in Java"
	@echo "  make profile-java-vX           - Profile of VX in Java"

# 1. Python
create-data:
	@echo "Creating Data..."
	cd $(DATA_DIR) && python3 main.py

# 2. GO
## V1
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

## V2
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

## V3
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
## V4
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
## V6
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
## V7
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
## V10
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
## V1
run-java-v1:
	@echo "Run Java V1..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v1

microbenchmark-java-v1:
	@echo "Microbenchmark Java V1..."
	cd $(JAVA_DIR) && mvn clean package -pl v1
	java -jar $(JAVA_DIR)/v1/target/benchmarks.jar> resultados_v1.txt

profile-java-v1:
	@echo "Profile Java V1..."
	cd $(JAVA_DIR) && mkdir -p v1/target && mvn exec:exec -pl v1 -Dexec.executable="java" -Dexec.args="-XX:StartFlightRecording=disk=true,dumponexit=true,filename=target/kmeans-v1.jfr,settings=profile -classpath %classpath com.kmeans.Main"
## V2
run-java-v2:
	@echo "Run Java V2..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v2

microbenchmark-java-v2:
	@echo "Microbenchmark Java V2..."
	cd $(JAVA_DIR) && mvn clean package -pl v2
	java -jar $(JAVA_DIR)/v2/target/benchmarks.jar> resultados_v2.txt

profile-java-v2:
	@echo "Profile Java V2..."
	cd $(JAVA_DIR) && mkdir -p v2/target && mvn exec:exec -pl v2 -Dexec.executable="java" -Dexec.args="-XX:StartFlightRecording=disk=true,dumponexit=true,filename=target/kmeans-v2.jfr,settings=profile -classpath %classpath com.kmeans.Main"
## V3
run-java-v3:
	@echo "Run Java V3..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v3

microbenchmark-java-v3:
	@echo "Microbenchmark Java V3..."
	cd $(JAVA_DIR) && mvn clean package -pl v3
	java -jar $(JAVA_DIR)/v3/target/benchmarks.jar> resultados_v3.txt

profile-java-v3:
	@echo "Profile Java V3..."
	cd $(JAVA_DIR) && mkdir -p v3/target && mvn exec:exec -pl v3 -Dexec.executable="java" -Dexec.args="-XX:StartFlightRecording=disk=true,dumponexit=true,filename=target/kmeans-v3.jfr,settings=profile -classpath %classpath com.kmeans.Main"
## V4
run-java-v4:
	@echo "Run Java V4..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v4

microbenchmark-java-v4:
	@echo "Microbenchmark Java V4..."
	cd $(JAVA_DIR) && mvn clean package -pl v4
	java -jar $(JAVA_DIR)/v4/target/benchmarks.jar> resultados_v4.txt

profile-java-v4:
	@echo "Profile Java V4..."
	cd $(JAVA_DIR) && mkdir -p v4/target && mvn exec:exec -pl v4 -Dexec.executable="java" -Dexec.args="-XX:StartFlightRecording=disk=true,dumponexit=true,filename=target/kmeans-v4.jfr,settings=profile -classpath %classpath com.kmeans.Main"
## V5
run-java-v5:
	@echo "Run Java V5..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v5

microbenchmark-java-v5:
	@echo "Microbenchmark Java V5..."
	cd $(JAVA_DIR) && mvn clean package -pl v5
	java -jar $(JAVA_DIR)/v5/target/benchmarks.jar> resultados_v5.txt

profile-java-v5:
	@echo "Profile Java V5..."
	cd $(JAVA_DIR) && mkdir -p v5/target && mvn exec:exec -pl v5 -Dexec.executable="java" -Dexec.args="-XX:StartFlightRecording=disk=true,dumponexit=true,filename=target/kmeans-v5.jfr,settings=profile -classpath %classpath com.kmeans.Main"
## V6
run-java-v6:
	@echo "Run Java V6..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v6

microbenchmark-java-v6:
	@echo "Microbenchmark Java V6..."
	cd $(JAVA_DIR) && mvn clean package -pl v6
	java -jar $(JAVA_DIR)/v6/target/benchmarks.jar> resultados_v6.txt

profile-java-v6:
	@echo "Profile Java V6..."
	cd $(JAVA_DIR) && mkdir -p v6/target && mvn exec:exec -pl v6 -Dexec.executable="java" -Dexec.args="-XX:StartFlightRecording=disk=true,dumponexit=true,filename=target/kmeans-v6.jfr,settings=profile -classpath %classpath com.kmeans.Main"
## V7
run-java-v7:
	@echo "Run Java V7..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v7

microbenchmark-java-v7:
	@echo "Microbenchmark Java V7..."
	cd $(JAVA_DIR) && mvn clean package -pl v7
	java -jar $(JAVA_DIR)/v7/target/benchmarks.jar> resultados_v7.txt

profile-java-v7:
	@echo "Profile Java V7..."
	cd $(JAVA_DIR) && mkdir -p v7/target && mvn exec:exec -pl v7 -Dexec.executable="java" -Dexec.args="-XX:StartFlightRecording=disk=true,dumponexit=true,filename=target/kmeans-v7.jfr,settings=profile -classpath %classpath com.kmeans.Main"
## V8
run-java-v8:
	@echo "Run Java V8..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v8 -Dexec.vmArgs="-XX:+UseParallelGC"

microbenchmark-java-v8:
	@echo "Microbenchmark Java V8..."
	cd $(JAVA_DIR) && mvn clean package -pl v8
	java -jar $(JAVA_DIR)/v8/target/benchmarks.jar> resultados_v8.txt

profile-java-v8:
	@echo "Profile Java V8..."
	cd $(JAVA_DIR) && mkdir -p v8/target && mvn exec:exec -pl v8 -Dexec.executable="java" -Dexec.args="-XX:+UseParallelGC -XX:StartFlightRecording=disk=true,dumponexit=true,filename=target/kmeans-v8.jfr,settings=profile -classpath %classpath com.kmeans.Main"
## V9
run-java-v9:
	@echo "Run Java V9..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v9 -Dexec.vmArgs="-XX:+UseZGC"

microbenchmark-java-v9:
	@echo "Microbenchmark Java V9..."
	cd $(JAVA_DIR) && mvn clean package -pl v9
	java -jar $(JAVA_DIR)/v9/target/benchmarks.jar> resultados_v9.txt

profile-java-v9:
	@echo "Profile Java V9..."
	cd $(JAVA_DIR) && mkdir -p v9/target && mvn exec:exec -pl v9 -Dexec.executable="java" -Dexec.args="-XX:+UseZGC -XX:StartFlightRecording=disk=true,dumponexit=true,filename=target/kmeans-v9.jfr,settings=profile -classpath %classpath com.kmeans.Main"
## V10
run-java-v10:
	@echo "Run Java V10..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v10

microbenchmark-java-v10:
	@echo "Microbenchmark Java V10..."
	cd $(JAVA_DIR) && mvn clean package -pl v10
	java -jar $(JAVA_DIR)/v10/target/benchmarks.jar> resultados_v10.txt

profile-java-v10:
	@echo "Profile Java V10..."
	cd $(JAVA_DIR) && mkdir -p v10/target && mvn exec:exec -pl v10 -Dexec.executable="java" -Dexec.args="-XX:StartFlightRecording=disk=true,dumponexit=true,filename=target/kmeans-v10.jfr,settings=profile -classpath %classpath com.kmeans.Main"
