GO_DIR = go
JAVA_DIR = java
DATA_DIR = data
JMETER_EXE = jmeter
BENCH_FLAGS_GO = -run=^$$ -bench=^Benchmark -benchmem -count=6
THREADS ?= 4
EXECS ?= 20
MAX_THREADS ?= 8
GO_VERSIONS   = v1 v2 v3 v4 v6 v7 v10
JAVA_VERSIONS = v1 v2 v3 v4 v5 v6 v7 v8 v9 v10

.PHONY: all help create-data \
        run-go-v1    microbenchmark-go-v1    heisenbug-check-go-v1    profile-go-v1    saturation-go-v1    progression-go-v1 \
        run-go-v2    microbenchmark-go-v2    heisenbug-check-go-v2    profile-go-v2    saturation-go-v2    progression-go-v2 \
        run-go-v3    microbenchmark-go-v3    heisenbug-check-go-v3    profile-go-v3    saturation-go-v3    progression-go-v3 \
        run-go-v4    microbenchmark-go-v4    heisenbug-check-go-v4    profile-go-v4    saturation-go-v4    progression-go-v4 \
        run-go-v6    microbenchmark-go-v6    heisenbug-check-go-v6    profile-go-v6    saturation-go-v6    progression-go-v6 \
        run-go-v7    microbenchmark-go-v7    heisenbug-check-go-v7    profile-go-v7    saturation-go-v7    progression-go-v7 \
        run-go-v10   microbenchmark-go-v10   heisenbug-check-go-v10   profile-go-v10   saturation-go-v10   progression-go-v10 \
        run-java-v1  microbenchmark-java-v1  heisenbug-check-java-v1  profile-java-v1  saturation-java-v1  progression-java-v1 \
        run-java-v2  microbenchmark-java-v2  heisenbug-check-java-v2  profile-java-v2  saturation-java-v2  progression-java-v2 \
        run-java-v3  microbenchmark-java-v3  heisenbug-check-java-v3  profile-java-v3  saturation-java-v3  progression-java-v3 \
        run-java-v4  microbenchmark-java-v4  heisenbug-check-java-v4  profile-java-v4  saturation-java-v4  progression-java-v4 \
        run-java-v5  microbenchmark-java-v5  heisenbug-check-java-v5  profile-java-v5  saturation-java-v5  progression-java-v5 \
        run-java-v6  microbenchmark-java-v6  heisenbug-check-java-v6  profile-java-v6  saturation-java-v6  progression-java-v6 \
        run-java-v7  microbenchmark-java-v7  heisenbug-check-java-v7  profile-java-v7  saturation-java-v7  progression-java-v7 \
        run-java-v8  microbenchmark-java-v8  heisenbug-check-java-v8  profile-java-v8  saturation-java-v8  progression-java-v8 \
        run-java-v9  microbenchmark-java-v9  heisenbug-check-java-v9  profile-java-v9  saturation-java-v9  progression-java-v9 \
        run-java-v10 microbenchmark-java-v10 heisenbug-check-java-v10 profile-java-v10 saturation-java-v10 progression-java-v10 \
        benchmark-all-go benchmark-all-java benchmark-all \
        heisenbug-all-go heisenbug-all-java heisenbug-all \
        saturation-all-go saturation-all-java saturation-all \
        progression-all-go progression-all-java progression-all

all: help

help:
	@echo "Available commands:"
	@echo "  make create-data               - Runs code to create data"
	@echo "  make run-go-vX                 - Runs the VX in Go (where X in (1,2,3,4,6,7,10))"
	@echo "  make microbenchmark-go-vX      - Microbenchmark of VX in Go"
	@echo "  make heisenbug-check-go-vX     - Check heisenbug of VX in Go"
	@echo "  make profile-go-vX             - Profile of VX in Go"
	@echo "  make saturation-go-vX          - Saturation test of VX in Go"
	@echo "  make progression-go-vX         - Progression degradation test of VX in Go (MAX_THREADS=8)"
	@echo "  make run-java-vX               - Runs the VX in Java (where X in (1..10))"
	@echo "  make microbenchmark-java-vX    - Microbenchmark of VX in Java"
	@echo "  make heisenbug-check-java-vX   - Check heisenbug of VX in Java"
	@echo "  make profile-java-vX           - Profile of VX in Java"
	@echo "  make saturation-java-vX        - Saturation test of VX in Java"
	@echo "  make progression-java-vX       - Progression degradation test of VX in Java (MAX_THREADS=8)"
	@echo "  make benchmark-all             - All Benchmark in Java and Go"
	@echo "  make heisenbug-all             - All Heisenbug check in Java and Go"
	@echo "  make saturation-all            - All Saturation test in Java and Go"
	@echo "  make progression-all           - Run all progression degradation tests (Java and Go)"
	@echo "  make progression-all-go        - Run all progression degradation tests for Go"
	@echo "  make progression-all-java      - Run all progression degradation tests for Java"

# 1. Python
create-data:
	@echo "Creating Data..."
	cd $(DATA_DIR) && python3 main.py

# 2. GO
clean-profile:
	-@pkill -f "go tool pprof"
	-@pkill -f "go tool trace"

define run_progression_go
	@rm -f $(GO_DIR)/$(1)/progression_$(1).txt
	@for t in $$(seq 1 $(MAX_THREADS)); do \
		echo "--------------------------------------------------"; \
		(cd $(GO_DIR) && go test -tags saturation -v ./$(1)/ -run=^TestMacroBenchmarkSaturation$$ -args -threads=$$t -execs=$$t) | tee -a $(GO_DIR)/$(1)/progression_$(1).txt; \
		sleep 2; \
	done
endef

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
	@nohup env GODEBUG=ipv6=0 go tool trace -http=127.0.0.1:8082 go/v1/profile/trace.out > /dev/null 2>&1 &

saturation-go-v1:
	@echo "Running Macro Saturation Test Go V1 (THREADS=$(THREADS), EXECS=$(EXECS))..."
	cd $(GO_DIR) && \
	go test -v -tags saturation -run=^TestMacroBenchmarkSaturation$$ ./v1/ -args -threads=$(THREADS) -execs=$(EXECS)

progression-go-v1:
	@echo "Starting Progression Test Go V1..."
	$(call run_progression_go,v1)

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
	@nohup env GODEBUG=ipv6=0 go tool trace -http=127.0.0.1:8082 go/v2/profile/trace.out > /dev/null 2>&1 &

saturation-go-v2:
	@echo "Running Macro Saturation Test Go V2 (THREADS=$(THREADS), EXECS=$(EXECS))..."
	cd $(GO_DIR) && \
	go test -v -tags saturation -run=^TestMacroBenchmarkSaturation$$ ./v2/ -args -threads=$(THREADS) -execs=$(EXECS)

progression-go-v2:
	@echo "Starting Progression Test Go V2..."
	$(call run_progression_go,v2)

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
	@nohup env GODEBUG=ipv6=0 go tool trace -http=127.0.0.1:8082 go/v3/profile/trace.out > /dev/null 2>&1 &

saturation-go-v3:
	@echo "Running Macro Saturation Test Go V3 (THREADS=$(THREADS), EXECS=$(EXECS))..."
	cd $(GO_DIR) && \
	go test -v -tags saturation -run=^TestMacroBenchmarkSaturation$$ ./v3/ -args -threads=$(THREADS) -execs=$(EXECS)

progression-go-v3:
	@echo "Starting Progression Test Go V3..."
	$(call run_progression_go,v3)

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
	@nohup env GODEBUG=ipv6=0 go tool trace -http=127.0.0.1:8082 go/v4/profile/trace.out > /dev/null 2>&1 &

saturation-go-v4:
	@echo "Running Macro Saturation Test Go V4 (THREADS=$(THREADS), EXECS=$(EXECS))..."
	cd $(GO_DIR) && \
	go test -v -tags saturation -run=^TestMacroBenchmarkSaturation$$ ./v4/ -args -threads=$(THREADS) -execs=$(EXECS)

progression-go-v4:
	@echo "Starting Progression Test Go V4..."
	$(call run_progression_go,v4)

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
	@nohup env GODEBUG=ipv6=0 go tool trace -http=127.0.0.1:8082 go/v6/profile/trace.out > /dev/null 2>&1 &

saturation-go-v6:
	@echo "Running Macro Saturation Test Go V6 (THREADS=$(THREADS), EXECS=$(EXECS))..."
	cd $(GO_DIR) && \
	go test -v -tags saturation -run=^TestMacroBenchmarkSaturation$$ ./v6/ -args -threads=$(THREADS) -execs=$(EXECS)

progression-go-v6:
	@echo "Starting Progression Test Go V6..."
	$(call run_progression_go,v6)

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
	@nohup env GODEBUG=ipv6=0 go tool trace -http=127.0.0.1:8082 go/v7/profile/trace.out > /dev/null 2>&1 &

saturation-go-v7:
	@echo "Running Macro Saturation Test Go V7 (THREADS=$(THREADS), EXECS=$(EXECS))..."
	cd $(GO_DIR) && \
	go test -v -tags saturation -run=^TestMacroBenchmarkSaturation$$ ./v7/ -args -threads=$(THREADS) -execs=$(EXECS)

progression-go-v7:
	@echo "Starting Progression Test Go V7..."
	$(call run_progression_go,v7)

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
	@nohup env GODEBUG=ipv6=0 go tool trace -http=127.0.0.1:8082 go/v10/profile/trace.out > /dev/null 2>&1 &

saturation-go-v10:
	@echo "Running Macro Saturation Test Go V10 (THREADS=$(THREADS), EXECS=$(EXECS))..."
	cd $(GO_DIR) && \
	go test -v -tags saturation -run=^TestMacroBenchmarkSaturation$$ ./v10/ -args -threads=$(THREADS) -execs=$(EXECS)

progression-go-v10:
	@echo "Starting Progression Test Go V10..."
	$(call run_progression_go,v10)


# 3. JAVA
define run_jmeter_java
	cd $(JAVA_DIR) && mvn clean package -pl $(1) -P app-exec
	mkdir -p /opt/apache-jmeter-5.6.3/lib/ext
	cp $(JAVA_DIR)/$(1)/target/*.jar /opt/apache-jmeter-5.6.3/lib/ext/
	rm -f $(JAVA_DIR)/$(1)/results_saturation_$(1).jtl
	/opt/apache-jmeter-5.6.3/bin/jmeter.sh -Djava.awt.headless=true -n -t kmeans_test.jmx -Jusuarios=$(THREADS) -l $(JAVA_DIR)/$(1)/results_saturation_$(1).jtl
endef

define run_progression_java
	@cd $(JAVA_DIR) && mvn clean package -pl $(1) -P app-exec > /dev/null 2>&1
	@mkdir -p /opt/apache-jmeter-5.6.3/lib/ext
	@rm -f /opt/apache-jmeter-5.6.3/lib/ext/v*.jar
	@rm -f /opt/apache-jmeter-5.6.3/lib/ext/*SNAPSHOT.jar
	@cp $(JAVA_DIR)/$(1)/target/*.jar /opt/apache-jmeter-5.6.3/lib/ext/
	@echo "Threads,Time_MS" | tee $(JAVA_DIR)/$(1)/progression_$(1).txt
	@for t in $$(seq 1 $(MAX_THREADS)); do \
		rm -f $(JAVA_DIR)/$(1)/results_saturation_$(1).jtl; \
		START_TIME=$$(python3 -c 'import time; print(int(time.time() * 1000))'); \
		/opt/apache-jmeter-5.6.3/bin/jmeter.sh -Djava.awt.headless=true -n -t kmeans_test.jmx -Jusuarios=$$t -l $(JAVA_DIR)/$(1)/results_saturation_$(1).jtl > /dev/null 2>&1; \
		END_TIME=$$(python3 -c 'import time; print(int(time.time() * 1000))'); \
		ELAPSED=$$((END_TIME - START_TIME)); \
		echo "$$t,$$ELAPSED" | tee -a $(JAVA_DIR)/$(1)/progression_$(1).txt; \
		sleep 2; \
	done
endef

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
	cd $(JAVA_DIR) && mvn clean package -pl v1 -Pjmh
	cd $(JAVA_DIR)/v1 && java -XX:StartFlightRecording=disk=true,dumponexit=true,filename=/workspaces/K-Means/kmeans-v1.jfr,settings=profile \
	-cp target/benchmarks.jar com.kmeans.Main

heisenbug-check-java-v1:
	@echo "Concurrency Test Java V1..."
	cd $(JAVA_DIR) && echo "It's OK!" > v1/concurrency_v1.txt

saturation-java-v1:
	$(call run_jmeter_java,v1)

progression-java-v1:
	@echo "Starting Progression Test Java V1..."
	$(call run_progression_java,v1)

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
	cd $(JAVA_DIR) && mvn clean package -pl v2 -Pjmh
	cd $(JAVA_DIR)/v2 && java -XX:StartFlightRecording=disk=true,dumponexit=true,filename=/workspaces/K-Means/kmeans-v2.jfr,settings=profile \
	-cp target/benchmarks.jar com.kmeans.Main

heisenbug-check-java-v2:
	@echo "Concurrency Test Java V2..."
	cd $(JAVA_DIR) && mvn clean package -pl v2 -Pjcstress && \
	java -jar v2/target/jcstress-tests.jar -m quick | tee v2/concurrency_v2.txt && \
	rm -r *.bin.gz

saturation-java-v2:
	$(call run_jmeter_java,v2)

progression-java-v2:
	@echo "Starting Progression Test Java V2..."
	$(call run_progression_java,v2)

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
	cd $(JAVA_DIR) && mvn clean package -pl v3 -Pjmh
	cd $(JAVA_DIR)/v3 && java -XX:StartFlightRecording=disk=true,dumponexit=true,filename=/workspaces/K-Means/kmeans-v3.jfr,settings=profile \
	-cp target/benchmarks.jar com.kmeans.Main

heisenbug-check-java-v3:
	@echo "Concurrency Test Java V3..."
	cd $(JAVA_DIR) && mvn clean package -pl v3 -Pjcstress && \
	java -jar v3/target/jcstress-tests.jar -m quick | tee v3/concurrency_v3.txt && \
	rm -r *.bin.gz

saturation-java-v3:
	$(call run_jmeter_java,v3)

progression-java-v3:
	@echo "Starting Progression Test Java V3..."
	$(call run_progression_java,v3)

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
	cd $(JAVA_DIR) && mvn clean package -pl v4 -Pjmh
	cd $(JAVA_DIR)/v4 && java -XX:StartFlightRecording=disk=true,dumponexit=true,filename=/workspaces/K-Means/kmeans-v4.jfr,settings=profile \
	-cp target/benchmarks.jar com.kmeans.Main

heisenbug-check-java-v4:
	@echo "Concurrency Test Java V4..."
	cd $(JAVA_DIR) && mvn clean package -pl v4 -Pjcstress && \
	java -jar v4/target/jcstress-tests.jar -m quick | tee v4/concurrency_v4.txt && \
	rm -r *.bin.gz

saturation-java-v4:
	$(call run_jmeter_java,v4)

progression-java-v4:
	@echo "Starting Progression Test Java V4..."
	$(call run_progression_java,v4)

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
	cd $(JAVA_DIR) && mvn clean package -pl v5 -Pjmh
	cd $(JAVA_DIR)/v5 && java -XX:StartFlightRecording=disk=true,dumponexit=true,filename=/workspaces/K-Means/kmeans-v5.jfr,settings=profile \
	-cp target/benchmarks.jar com.kmeans.Main

heisenbug-check-java-v5:
	@echo "Concurrency Test Java V5..."
	cd $(JAVA_DIR) && mvn clean package -pl v5 -Pjcstress && \
	java -jar v5/target/jcstress-tests.jar -m quick | tee v5/concurrency_v5.txt && \
	rm -r *.bin.gz

saturation-java-v5:
	$(call run_jmeter_java,v5)

progression-java-v5:
	@echo "Starting Progression Test Java V5..."
	$(call run_progression_java,v5)

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
	cd $(JAVA_DIR) && mvn clean package -pl v6 -Pjmh
	cd $(JAVA_DIR)/v6 && java -XX:StartFlightRecording=disk=true,dumponexit=true,filename=/workspaces/K-Means/kmeans-v6.jfr,settings=profile \
	-cp target/benchmarks.jar com.kmeans.Main

heisenbug-check-java-v6:
	@echo "Concurrency Test Java V6..."
	cd $(JAVA_DIR) && mvn clean package -pl v6 -Pjcstress && \
	java -jar v6/target/jcstress-tests.jar -m quick | tee v6/concurrency_v6.txt && \
	rm -r *.bin.gz

saturation-java-v6:
	$(call run_jmeter_java,v6)

progression-java-v6:
	@echo "Starting Progression Test Java V6..."
	$(call run_progression_java,v6)

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
	cd $(JAVA_DIR) && mvn clean package -pl v7 -Pjmh
	cd $(JAVA_DIR)/v7 && java -XX:StartFlightRecording=disk=true,dumponexit=true,filename=/workspaces/K-Means/kmeans-v7.jfr,settings=profile \
	-cp target/benchmarks.jar com.kmeans.Main

heisenbug-check-java-v7:
	@echo "Concurrency Test Java V7..."
	cd $(JAVA_DIR) && mvn clean package -pl v7 -Pjcstress && \
	java -jar v7/target/jcstress-tests.jar -m quick | tee v7/concurrency_v7.txt && \
	rm -r *.bin.gz

saturation-java-v7:
	$(call run_jmeter_java,v7)

progression-java-v7:
	@echo "Starting Progression Test Java V7..."
	$(call run_progression_java,v7)

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
	cd $(JAVA_DIR) && mvn clean package -pl v8 -Pjmh
	cd $(JAVA_DIR)/v8 && java -XX:StartFlightRecording=disk=true,dumponexit=true,filename=/workspaces/K-Means/kmeans-v8.jfr,settings=profile \
	-cp target/benchmarks.jar com.kmeans.Main

heisenbug-check-java-v8:
	@echo "Concurrency Test Java V8..."
	cd $(JAVA_DIR) && mvn clean package -pl v8 -Pjcstress && \
	java -jar v8/target/jcstress-tests.jar -m quick | tee v8/concurrency_v8.txt && \
	rm -r *.bin.gz

saturation-java-v8:
	$(call run_jmeter_java,v8)

progression-java-v8:
	@echo "Starting Progression Test Java V8..."
	$(call run_progression_java,v8)

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
	cd $(JAVA_DIR) && mvn clean package -pl v9 -Pjmh
	cd $(JAVA_DIR)/v9 && java -XX:StartFlightRecording=disk=true,dumponexit=true,filename=/workspaces/K-Means/kmeans-v9.jfr,settings=profile \
	-cp target/benchmarks.jar com.kmeans.Main

heisenbug-check-java-v9:
	@echo "Concurrency Test Java V9..."
	cd $(JAVA_DIR) && mvn clean package -pl v9 -Pjcstress && \
	java -jar v9/target/jcstress-tests.jar -m quick | tee v9/concurrency_v9.txt && \
	rm -r *.bin.gz

saturation-java-v9:
	$(call run_jmeter_java,v9)

progression-java-v9:
	@echo "Starting Progression Test Java V9..."
	$(call run_progression_java,v9)

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
	cd $(JAVA_DIR) && mvn clean package -pl v10 -Pjmh
	cd $(JAVA_DIR)/v10 && java -XX:StartFlightRecording=disk=true,dumponexit=true,filename=/workspaces/K-Means/kmeans-v10.jfr,settings=profile \
	-cp target/benchmarks.jar com.kmeans.Main

heisenbug-check-java-v10:
	@echo "Concurrency Test Java V10..."
	cd $(JAVA_DIR) && mvn clean package -pl v10 -Pjcstress && \
	java -jar v10/target/jcstress-tests.jar -m quick | tee v10/concurrency_v10.txt && \
	rm -r *.bin.gz

saturation-java-v10:
	$(call run_jmeter_java,v10)

progression-java-v10:
	@echo "Starting Progression Test Java V10..."
	$(call run_progression_java,v10)


# Shortcuts / Batch Runs
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

progression-all-go:
	@echo "Starting a series of progress tests in Go..."
	@for v in $(GO_VERSIONS); do \
		echo "=================================================="; \
		$(MAKE) progression-go-$$v; \
		echo "Waiting 10 seconds for the CPU to cool down..."; \
		sleep 10; \
	done

progression-all-java:
	@echo "Starting a series of progress tests in Java..."
	@for v in $(JAVA_VERSIONS); do \
		echo "=================================================="; \
		$(MAKE) progression-java-$$v; \
		echo "Waiting 10 seconds for the CPU to cool down..."; \
		sleep 10; \
	done

progression-all: progression-all-go progression-all-java
	@echo "All progressive degradation tests have been successfully completed!"
