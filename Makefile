GO_DIR = go
JAVA_DIR = java
DATA_DIR = data
JMETER_EXE = jmeter
BENCH_FLAGS_GO = -run=^$$ -bench=^Benchmark -benchmem -count=6
THREADS ?= 4
EXECS ?= 20
GO_VERSIONS   = v1 v2 v3 v4 v6 v7 v10
JAVA_VERSIONS = v1 v2 v3 v4 v5 v6 v7 v8 v9 v10

.PHONY: all help create-data \
        run-go-v1    microbenchmark-go-v1    heisenbug-check-go-v1    profile-go-v1    saturation-go-v1     \
        run-go-v2    microbenchmark-go-v2    heisenbug-check-go-v2    profile-go-v2    saturation-go-v2     \
        run-go-v3    microbenchmark-go-v3    heisenbug-check-go-v3    profile-go-v3    saturation-go-v3     \
        run-go-v4    microbenchmark-go-v4    heisenbug-check-go-v4    profile-go-v4    saturation-go-v4     \
        run-go-v6    microbenchmark-go-v6    heisenbug-check-go-v6    profile-go-v6    saturation-go-v6     \
        run-go-v7    microbenchmark-go-v7    heisenbug-check-go-v7    profile-go-v7    saturation-go-v7     \
        run-go-v10   microbenchmark-go-v10   heisenbug-check-go-v10   profile-go-v10   saturation-go-v10    \
        run-java-v1  microbenchmark-java-v1  heisenbug-check-java-v1  profile-java-v1  saturation-java-v1   create-jar-java-v1  \
        run-java-v2  microbenchmark-java-v2  heisenbug-check-java-v2  profile-java-v2  saturation-java-v2   create-jar-java-v2  \
        run-java-v3  microbenchmark-java-v3  heisenbug-check-java-v3  profile-java-v3  saturation-java-v3   create-jar-java-v3  \
        run-java-v4  microbenchmark-java-v4  heisenbug-check-java-v4  profile-java-v4  saturation-java-v4   create-jar-java-v4  \
        run-java-v5  microbenchmark-java-v5  heisenbug-check-java-v5  profile-java-v5  saturation-java-v5   create-jar-java-v5  \
        run-java-v6  microbenchmark-java-v6  heisenbug-check-java-v6  profile-java-v6  saturation-java-v6   create-jar-java-v6  \
        run-java-v7  microbenchmark-java-v7  heisenbug-check-java-v7  profile-java-v7  saturation-java-v7   create-jar-java-v7  \
        run-java-v8  microbenchmark-java-v8  heisenbug-check-java-v8  profile-java-v8  saturation-java-v8   create-jar-java-v8  \
        run-java-v9  microbenchmark-java-v9  heisenbug-check-java-v9  profile-java-v9  saturation-java-v9   create-jar-java-v9  \
        run-java-v10 microbenchmark-java-v10 heisenbug-check-java-v10 profile-java-v10 saturation-java-v10  create-jar-java-v10 \
		benchmark-all-go benchmark-all-java benchmark-all \
		heisenbug-all-go heisenbug-all-java heisenbug-all \
		saturation-all-go saturation-all-java saturation-all
		

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
	@echo "  make heisenbug-check-java-vX   - Check heisenbug of VX in Java"
	@echo "  make profile-java-vX           - Profile of VX in Java"
	@echo "  make create-jar-java-vX        - Before saturation test of VX in Java"
	@echo "  make saturation-java-vX        - Saturation test of VX in Java"
	@echo "  make benchmark-all             - All Benchmark in Java and Go"
	@echo "  make benchmark-all-java        - All Benchmark in Java"
	@echo "  make benchmark-all-go          - All Benchmark in Go"
	@echo "  make heisenbug-all             - All Heisenbug check in Java and Go"
	@echo "  make heisenbug-all-java        - All Heisenbug check in Java"
	@echo "  make heisenbug-all-go          - All Heisenbug check in Go"
	@echo "  make saturation-all            - All Saturation test in Java and Go"
	@echo "  make saturation-all-java       - All Saturation test in Java"
	@echo "  make saturation-all-go         - All Saturation test in Go"

# 1. Python
create-data:
	@echo "Creating Data..."
	cd $(DATA_DIR) && python3 main.py

# 2. GO
clean-profile:
	-@pkill -f "go tool pprof"
	-@pkill -f "go tool trace"

## V1
run-go-v1:
	@echo "Run Go V1..."
	cd $(GO_DIR) && go run ./v1/

microbenchmark-go-v1:
	@echo "Microbenchmark Go V1..."
	cd $(GO_DIR) && \
	go test $(BENCH_FLAGS_GO) ./v1/ | tee v1/results_v1.txt && \
	benchstat v1/results_v1.txt

heisenbug-check-go-v1:
	@echo "Check Heisenbugs Go V1..."
	cd $(GO_DIR) && go test -race -cpu=2,4,8 -count=10 -run=^$$ -bench=^Benchmark ./v1/... | tee v1/concurrency_v1.txt

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
	go test $(BENCH_FLAGS_GO) ./v2/ | tee v2/results_v2.txt && \
	benchstat v2/results_v2.txt

heisenbug-check-go-v2:
	@echo "Check Heisenbugs Go V2..."
	cd $(GO_DIR) && go test -race -cpu=2,4,8 -count=10 -run=^$$ -bench=^Benchmark ./v2/... | tee v2/concurrency_v2.txt

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
	go test $(BENCH_FLAGS_GO) ./v3/ | tee v3/results_v3.txt && \
	benchstat v3/results_v3.txt

heisenbug-check-go-v3:
	@echo "Check Heisenbugs Go V3..."
	cd $(GO_DIR) && go test -race -cpu=2,4,8 -count=10 -run=^$$ -bench=^Benchmark ./v3/... | tee v3/concurrency_v3.txt

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
	go test $(BENCH_FLAGS_GO) ./v4/ | tee v4/results_v4.txt && \
	benchstat v4/results_v4.txt

heisenbug-check-go-v4:
	@echo "Check Heisenbugs Go V4..."
	cd $(GO_DIR) && go test -race -cpu=2,4,8 -count=10 -run=^$$ -bench=^Benchmark ./v4/... | tee v4/concurrency_v4.txt

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
	go test $(BENCH_FLAGS_GO) ./v6/ | tee v6/results_v6.txt && \
	benchstat v6/results_v6.txt

heisenbug-check-go-v6:
	@echo "Check Heisenbugs Go V6..."
	cd $(GO_DIR) && go test -race -cpu=2,4,8 -count=10 -run=^$$ -bench=^Benchmark ./v6/... | tee v6/concurrency_v6.txt

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
	go test $(BENCH_FLAGS_GO) ./v7/ | tee v7/results_v7.txt && \
	benchstat v7/results_v7.txt

heisenbug-check-go-v7:
	@echo "Check Heisenbugs Go V7..."
	cd $(GO_DIR) && go test -race -cpu=2,4,8 -count=10 -run=^$$ -bench=^Benchmark ./v7/... | tee v7/concurrency_v7.txt

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
	go test $(BENCH_FLAGS_GO) ./v10/ | tee v10/results_v10.txt && \
	benchstat v10/results_v10.txt

heisenbug-check-go-v10:
	@echo "Check Heisenbugs Go V10..."
	cd $(GO_DIR) && go test -race -cpu=2,4,8 -count=10 -run=^$$ -bench=^Benchmark ./v10/... | tee v10/concurrency_v10.txt

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
	cd $(JAVA_DIR) && mvn clean package -pl v1  -Pjmh && \
	java -jar v1/target/benchmarks.jar | tee v1/results_v1.txt

profile-java-v1:
	@echo "Profile Java V1..."
	cd $(JAVA_DIR) && mkdir -p v1/target && mvn exec:exec -pl v1 -Dexec.executable="java" -Dexec.args="-XX:StartFlightRecording=disk=true,dumponexit=true,filename=target/kmeans-v1.jfr,settings=profile -classpath %classpath com.kmeans.Main"

heisenbug-check-java-v1:
	@echo "Concurrency Test Java V1..."
	cd $(JAVA_DIR) && echo "It's OK!" > v1/concurrency_v1.txt

create-jar-java-v1:
	@echo "Creating conventional JAR for Java V1..."
	cd $(JAVA_DIR) && mvn clean package -pl v1 -P app-exec

saturation-java-v1: create-jar-java-v1
	@echo "Running Saturation Test for Java V1..."
	$(JMETER_EXE) -n -t kmeans_test.jmx \
		-l $(JAVA_DIR)/v1/results_saturation_v1.jtl \
		-j $(JAVA_DIR)/v1/jmeter_v1.log \
		-Jjar_target=$(JAVA_DIR)/v1/target/v1.jar

## V2
run-java-v2:
	@echo "Run Java V2..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v2

microbenchmark-java-v2:
	@echo "Microbenchmark Java V2..."
	cd $(JAVA_DIR) && mvn clean package -pl v2 -Pjmh && \
	java -jar v2/target/benchmarks.jar | tee v2/results_v2.txt

profile-java-v2:
	@echo "Profile Java V2..."
	cd $(JAVA_DIR) && mkdir -p v2/target && mvn exec:exec -pl v2 -Dexec.executable="java" -Dexec.args="-XX:StartFlightRecording=disk=true,dumponexit=true,filename=target/kmeans-v2.jfr,settings=profile -classpath %classpath com.kmeans.Main"

heisenbug-check-java-v2:
	@echo "Concurrency Test Java V2..."
	cd $(JAVA_DIR) && mvn clean package -pl v2 -Pjcstress && \
	java -jar v2/target/jcstress-tests.jar -m quick | tee v2/concurrency_v2.txt && \
	rm -r *.bin.gz

create-jar-java-v2:
	@echo "Creating conventional JAR for Java V2..."
	cd $(JAVA_DIR) && mvn clean package -pl v2 -P app-exec

saturation-java-v2: create-jar-java-v2
	@echo "Running Saturation Test for Java V2..."
	$(JMETER_EXE) -n -t kmeans_test.jmx \
		-l $(JAVA_DIR)/v2/results_saturation_v2.jtl \
		-j $(JAVA_DIR)/v2/jmeter_v2.log \
		-Jjar_target=$(JAVA_DIR)/v2/target/v2.jar

## V3
run-java-v3:
	@echo "Run Java V3..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v3

microbenchmark-java-v3:
	@echo "Microbenchmark Java V3..."
	cd $(JAVA_DIR) && mvn clean package -pl v3 -Pjmh && \
	java -jar v3/target/benchmarks.jar | tee v3/results_v3.txt

profile-java-v3:
	@echo "Profile Java V3..."
	cd $(JAVA_DIR) && mkdir -p v3/target && mvn exec:exec -pl v3 -Dexec.executable="java" -Dexec.args="-XX:StartFlightRecording=disk=true,dumponexit=true,filename=target/kmeans-v3.jfr,settings=profile -classpath %classpath com.kmeans.Main"

heisenbug-check-java-v3:
	@echo "Concurrency Test Java V3..."
	cd $(JAVA_DIR) && mvn clean package -pl v3 -Pjcstress && \
	java -jar v3/target/jcstress-tests.jar -m quick | tee v3/concurrency_v3.txt && \
	rm -r *.bin.gz

create-jar-java-v3:
	@echo "Creating conventional JAR for Java V3..."
	cd $(JAVA_DIR) && mvn clean package -pl v3 -P app-exec

saturation-java-v3: create-jar-java-v3
	@echo "Running Saturation Test for Java V3..."
	$(JMETER_EXE) -n -t kmeans_test.jmx \
		-l $(JAVA_DIR)/v3/results_saturation_v3.jtl \
		-j $(JAVA_DIR)/v3/jmeter_v3.log \
		-Jjar_target=$(JAVA_DIR)/v3/target/v3.jar

## V4
run-java-v4:
	@echo "Run Java V4..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v4

microbenchmark-java-v4:
	@echo "Microbenchmark Java V4..."
	cd $(JAVA_DIR) && mvn clean package -pl v4 -Pjmh && \
	java -jar v4/target/benchmarks.jar | tee v4/results_v4.txt

profile-java-v4:
	@echo "Profile Java V4..."
	cd $(JAVA_DIR) && mkdir -p v4/target && mvn exec:exec -pl v4 -Dexec.executable="java" -Dexec.args="-XX:StartFlightRecording=disk=true,dumponexit=true,filename=target/kmeans-v4.jfr,settings=profile -classpath %classpath com.kmeans.Main"

heisenbug-check-java-v4:
	@echo "Concurrency Test Java V4..."
	cd $(JAVA_DIR) && mvn clean package -pl v4 -Pjcstress && \
	java -jar v4/target/jcstress-tests.jar -m quick | tee v4/concurrency_v4.txt && \
	rm -r *.bin.gz

create-jar-java-v4:
	@echo "Creating conventional JAR for Java V4..."
	cd $(JAVA_DIR) && mvn clean package -pl v4 -P app-exec

saturation-java-v4: create-jar-java-v4
	@echo "Running Saturation Test for Java V4..."
	$(JMETER_EXE) -n -t kmeans_test.jmx \
		-l $(JAVA_DIR)/v4/results_saturation_v4.jtl \
		-j $(JAVA_DIR)/v4/jmeter_v4.log \
		-Jjar_target=$(JAVA_DIR)/v4/target/v4.jar

## V5
run-java-v5:
	@echo "Run Java V5..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v5

microbenchmark-java-v5:
	@echo "Microbenchmark Java V5..."
	cd $(JAVA_DIR) && mvn clean package -pl v5 -Pjmh && \
	java -jar v5/target/benchmarks.jar | tee v5/results_v5.txt

profile-java-v5:
	@echo "Profile Java V5..."
	cd $(JAVA_DIR) && mkdir -p v5/target && mvn exec:exec -pl v5 -Dexec.executable="java" -Dexec.args="-XX:StartFlightRecording=disk=true,dumponexit=true,filename=target/kmeans-v5.jfr,settings=profile -classpath %classpath com.kmeans.Main"

heisenbug-check-java-v5:
	@echo "Concurrency Test Java V5..."
	cd $(JAVA_DIR) && mvn clean package -pl v5 -Pjcstress && \
	java -jar v5/target/jcstress-tests.jar -m quick | tee v5/concurrency_v5.txt && \
	rm -r *.bin.gz

create-jar-java-v5:
	@echo "Creating conventional JAR for Java V5..."
	cd $(JAVA_DIR) && mvn clean package -pl v5 -P app-exec

saturation-java-v5: create-jar-java-v5
	@echo "Running Saturation Test for Java V5..."
	$(JMETER_EXE) -n -t kmeans_test.jmx \
		-l $(JAVA_DIR)/v5/results_saturation_v5.jtl \
		-j $(JAVA_DIR)/v5/jmeter_v5.log \
		-Jjar_target=$(JAVA_DIR)/v5/target/v5.jar

## V6
run-java-v6:
	@echo "Run Java V6..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v6

microbenchmark-java-v6:
	@echo "Microbenchmark Java V6..."
	cd $(JAVA_DIR) && mvn clean package -pl v6 -Pjmh && \
	java -jar v6/target/benchmarks.jar | tee v6/results_v6.txt

profile-java-v6:
	@echo "Profile Java V6..."
	cd $(JAVA_DIR) && mkdir -p v6/target && mvn exec:exec -pl v6 -Dexec.executable="java" -Dexec.args="-XX:StartFlightRecording=disk=true,dumponexit=true,filename=target/kmeans-v6.jfr,settings=profile -classpath %classpath com.kmeans.Main"

heisenbug-check-java-v6:
	@echo "Concurrency Test Java V6..."
	cd $(JAVA_DIR) && mvn clean package -pl v6 -Pjcstress && \
	java -jar v6/target/jcstress-tests.jar -m quick | tee v6/concurrency_v6.txt && \
	rm -r *.bin.gz

create-jar-java-v6:
	@echo "Creating conventional JAR for Java V6..."
	cd $(JAVA_DIR) && mvn clean package -pl v6 -P app-exec

saturation-java-v6: create-jar-java-v6
	@echo "Running Saturation Test for Java V6..."
	$(JMETER_EXE) -n -t kmeans_test.jmx \
		-l $(JAVA_DIR)/v6/results_saturation_v6.jtl \
		-j $(JAVA_DIR)/v6/jmeter_v6.log \
		-Jjar_target=$(JAVA_DIR)/v6/target/v6.jar

## V7
run-java-v7:
	@echo "Run Java V7..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v7

microbenchmark-java-v7:
	@echo "Microbenchmark Java V7..."
	cd $(JAVA_DIR) && mvn clean package -pl v7 -Pjmh && \
	java -jar v7/target/benchmarks.jar | tee v7/results_v7.txt

profile-java-v7:
	@echo "Profile Java V7..."
	cd $(JAVA_DIR) && mkdir -p v7/target && mvn exec:exec -pl v7 -Dexec.executable="java" -Dexec.args="-XX:StartFlightRecording=disk=true,dumponexit=true,filename=target/kmeans-v7.jfr,settings=profile -classpath %classpath com.kmeans.Main"

heisenbug-check-java-v7:
	@echo "Concurrency Test Java V7..."
	cd $(JAVA_DIR) && mvn clean package -pl v7 -Pjcstress && \
	java -jar v7/target/jcstress-tests.jar -m quick | tee v7/concurrency_v7.txt && \
	rm -r *.bin.gz

create-jar-java-v7:
	@echo "Creating conventional JAR for Java V7..."
	cd $(JAVA_DIR) && mvn clean package -pl v7 -P app-exec

saturation-java-v7: create-jar-java-v7
	@echo "Running Saturation Test for Java V7..."
	$(JMETER_EXE) -n -t kmeans_test.jmx \
		-l $(JAVA_DIR)/v7/results_saturation_v7.jtl \
		-j $(JAVA_DIR)/v7/jmeter_v7.log \
		-Jjar_target=$(JAVA_DIR)/v7/target/v7.jar

## V8
run-java-v8:
	@echo "Run Java V8..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v8 -Dexec.vmArgs="-XX:+UseParallelGC"

microbenchmark-java-v8:
	@echo "Microbenchmark Java V8..."
	cd $(JAVA_DIR) && mvn clean package -pl v8 -Pjmh && \
	java -jar v8/target/benchmarks.jar -jvmArgs "-XX:+UseParallelGC" | tee v8/results_v8.txt

profile-java-v8:
	@echo "Profile Java V8..."
	cd $(JAVA_DIR) && mkdir -p v8/target && mvn exec:exec -pl v8 -Dexec.executable="java" -Dexec.args="-XX:+UseParallelGC -XX:StartFlightRecording=disk=true,dumponexit=true,filename=target/kmeans-v8.jfr,settings=profile -classpath %classpath com.kmeans.Main"

heisenbug-check-java-v8:
	@echo "Concurrency Test Java V8..."
	cd $(JAVA_DIR) && mvn clean package -pl v8 -Pjcstress && \
	java -jar v8/target/jcstress-tests.jar -m quick | tee v8/concurrency_v8.txt && \
	rm -r *.bin.gz

create-jar-java-v8:
	@echo "Creating conventional JAR for Java V8..."
	cd $(JAVA_DIR) && mvn clean package -pl v8 -P app-exec

saturation-java-v8: create-jar-java-v8
	@echo "Running Saturation Test for Java V8..."
	$(JMETER_EXE) -n -t kmeans_test.jmx \
		-l $(JAVA_DIR)/v8/results_saturation_v8.jtl \
		-j $(JAVA_DIR)/v8/jmeter_v8.log \
		-Jjar_target=$(JAVA_DIR)/v8/target/v8.jar \
		-Jvm_args="-XX:+UseParallelGC"

## V9
run-java-v9:
	@echo "Run Java V9..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v9 -Dexec.vmArgs="-XX:+UseZGC"

microbenchmark-java-v9:
	@echo "Microbenchmark Java V9..."
	cd $(JAVA_DIR) && mvn clean package -pl v9 -Pjmh && \
	java -jar v9/target/benchmarks.jar -jvmArgs "-XX:+UseZGC" | tee v9/results_v9.txt

profile-java-v9:
	@echo "Profile Java V9..."
	cd $(JAVA_DIR) && mkdir -p v9/target && mvn exec:exec -pl v9 -Dexec.executable="java" -Dexec.args="-XX:+UseZGC -XX:StartFlightRecording=disk=true,dumponexit=true,filename=target/kmeans-v9.jfr,settings=profile -classpath %classpath com.kmeans.Main"

heisenbug-check-java-v9:
	@echo "Concurrency Test Java V9..."
	cd $(JAVA_DIR) && mvn clean package -pl v9 -Pjcstress && \
	java -jar v9/target/jcstress-tests.jar -m quick | tee v9/concurrency_v9.txt && \
	rm -r *.bin.gz

create-jar-java-v9:
	@echo "Creating conventional JAR for Java V9..."
	cd $(JAVA_DIR) && mvn clean package -pl v9 -P app-exec

saturation-java-v9: create-jar-java-v9
	@echo "Running Saturation Test for Java V9..."
	$(JMETER_EXE) -n -t kmeans_test.jmx \
		-l $(JAVA_DIR)/v9/results_saturation_v9.jtl \
		-j $(JAVA_DIR)/v9/jmeter_v9.log \
		-Jjar_target=$(JAVA_DIR)/v9/target/v9.jar \
		-Jvm_args="-XX:+UseZGC"

## V10
run-java-v10:
	@echo "Run Java V10..."
	cd $(JAVA_DIR) && mvn compile exec:java -pl v10

microbenchmark-java-v10:
	@echo "Microbenchmark Java V10..."
	cd $(JAVA_DIR) && mvn clean package -pl v10 -Pjmh && \
	java -jar v10/target/benchmarks.jar | tee v10/results_v10.txt

profile-java-v10:
	@echo "Profile Java V10..."
	cd $(JAVA_DIR) && mkdir -p v10/target && mvn exec:exec -pl v10 -Dexec.executable="java" -Dexec.args="-XX:StartFlightRecording=disk=true,dumponexit=true,filename=target/kmeans-v10.jfr,settings=profile -classpath %classpath com.kmeans.Main"

heisenbug-check-java-v10:
	@echo "Concurrency Test Java V10..."
	cd $(JAVA_DIR) && mvn clean package -pl v10 -Pjcstress && \
	java -jar v10/target/jcstress-tests.jar -m quick | tee v10/concurrency_v10.txt && \
	rm -r *.bin.gz

create-jar-java-v10:
	@echo "Creating conventional JAR for Java V10..."
	cd $(JAVA_DIR) && mvn clean package -pl v10 -P app-exec

saturation-java-v10: create-jar-java-v10
	@echo "Running Saturation Test for Java V10..."
	$(JMETER_EXE) -n -t kmeans_test.jmx \
		-l $(JAVA_DIR)/v10/results_saturation_v10.jtl \
		-j $(JAVA_DIR)/v10/jmeter_v10.log \
		-Jjar_target=$(JAVA_DIR)/v10/target/v10.jar

# Link
benchmark-all-go:
	@echo "Starting all Go microbenchmarks with 10s intervals..."
	@for v in $(GO_VERSIONS); do \
		echo "--------------------------------------------------"; \
		$(MAKE) microbenchmark-go-$$v; \
		echo "Waiting 10 seconds for system cooldown..."; \
		sleep 10; \
	done

benchmark-all-java:
	@echo "Starting all Java microbenchmarks with 10s intervals..."
	@for v in $(JAVA_VERSIONS); do \
		echo "--------------------------------------------------"; \
		$(MAKE) microbenchmark-java-$$v; \
		echo "Waiting 10 seconds for system cooldown..."; \
		sleep 10; \
	done

benchmark-all: benchmark-all-java benchmark-all-go
	@echo "All microbenchmarks (Go and Java) have been completed!"

heisenbug-all-go:
	@echo "Starting all Go heisenbug checks with 10s intervals..."
	@for v in $(GO_VERSIONS); do \
		echo "--------------------------------------------------"; \
		$(MAKE) heisenbug-check-go-$$v; \
		echo "Waiting 10 seconds for system cooldown..."; \
		sleep 10; \
	done

heisenbug-all-java:
	@echo "Starting all Java heisenbug checks with 10s intervals..."
	@for v in $(JAVA_VERSIONS); do \
		echo "--------------------------------------------------"; \
		$(MAKE) heisenbug-check-java-$$v; \
		echo "Waiting 10 seconds for system cooldown..."; \
		sleep 10; \
	done

heisenbug-all: heisenbug-all-go heisenbug-all-java
	@echo "All heisenbug checks (Go and Java) have been completed!"

saturation-all-go:
	@echo "Starting all Go saturation tests..."
	@for v in $(GO_VERSIONS); do \
		echo "--------------------------------------------------"; \
		$(MAKE) saturation-go-$$v; \
		echo "Waiting 10 seconds for system/CPU cooldown..."; \
		sleep 10; \
	done

saturation-all-java:
	@echo "Starting all Java saturation tests..."
	@for v in $(JAVA_VERSIONS); do \
		echo "--------------------------------------------------"; \
		$(MAKE) saturation-java-$$v; \
		echo "Waiting 10 seconds for system/CPU cooldown..."; \
		sleep 10; \
	done

saturation-all: saturation-all-go saturation-all-java
	@echo "All saturation test (Go and Java) have been completed!"
