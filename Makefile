# =========================================================
# K-Means Benchmark Framework
# =========================================================

GO_DIR        := go
JAVA_DIR      := java
DATA_DIR      := data

GO_VERSIONS   := v1 v2 v3 v4 v6 v7 v10
JAVA_VERSIONS := v1 v2 v3 v4 v5 v6 v7 v8 v9 v10

VERSION       ?= v1

THREADS       ?= 4
EXECS         ?= 20
MAX_THREADS   ?= 10

GOMAXPROCS    ?= $(shell nproc)

BENCH_FLAGS_GO := \
	-run=^$$ \
	-bench=Benchmark \
	-benchmem \
	-count=5

JAVA_GC_FLAGS_v1  :=
JAVA_GC_FLAGS_v2  :=
JAVA_GC_FLAGS_v3  :=
JAVA_GC_FLAGS_v4  :=
JAVA_GC_FLAGS_v5  :=
JAVA_GC_FLAGS_v6  :=
JAVA_GC_FLAGS_v7  :=
JAVA_GC_FLAGS_v8  := -XX:+UseParallelGC -Xlog:gc
JAVA_GC_FLAGS_v9  := -XX:+UseZGC -Xlog:gc
JAVA_GC_FLAGS_v10 :=
JAVA_GC_FLAGS := $(JAVA_GC_FLAGS_$(VERSION))

# =========================================================
# PHONY
# =========================================================

.PHONY: all help \
	create-data \
	clean-profile \
	run-go micro-go macro-go progression-go race-go profile-go profile-open macro-all-go \
	run-java micro-java macro-java progression-java macro-all-java \
	benchmark-all-go benchmark-all-java \
	progression-all-go progression-all-java

all: help

# =========================================================
# HELP
# =========================================================

help:
	@echo ""
	@echo "==================== GO ===================="
	@echo "make run-go VERSION=v1"
	@echo "make micro-go VERSION=v1"
	@echo "make macro-go VERSION=v1 THREADS=8 EXECS=32"
	@echo "make progression-go VERSION=v1 MAX_THREADS=16 EXECS=64"
	@echo "make race-go VERSION=v1"
	@echo "make profile-go VERSION=v1"
	@echo "make profile-open VERSION=v1"
	@echo ""
	@echo "=================== JAVA ==================="
	@echo "make run-java VERSION=v1"
	@echo "make micro-java VERSION=v1"
	@echo "make macro-java VERSION=v1 THREADS=8"
	@echo "make progression-java VERSION=v1 MAX_THREADS=16"
	@echo ""
	@echo "================== GLOBAL =================="
	@echo "make benchmark-all-go"
	@echo "make benchmark-all-java"
	@echo "make macro-all-go"
	@echo "make macro-all-java"
	@echo "make progression-all-go"
	@echo "make progression-all-java"
	@echo ""

# =========================================================
# DATASET
# =========================================================

create-data:
	@echo "Creating datasets..."
	cd $(DATA_DIR) && python3 main.py

# =========================================================
# CLEAN
# =========================================================

clean-profile:
	-@pkill -f "go tool pprof"
	-@pkill -f "go tool trace"

# =========================================================
# GO
# =========================================================

run-go:
	@echo "Running Go $(VERSION)..."
	cd $(GO_DIR) && \
	GOMAXPROCS=$(GOMAXPROCS) \
	go run ./$(VERSION)/

# ---------------------------------------------------------

micro-go:
	@echo "Running Go microbenchmarks ($(VERSION))..."
	cd $(GO_DIR) && \
	GOMAXPROCS=$(GOMAXPROCS) \
	go test $(BENCH_FLAGS_GO) ./$(VERSION)/ \
	| tee $(VERSION)/microbenchmark.txt

# ---------------------------------------------------------

race-go:
	@echo "Running Go race detector ($(VERSION))..."
	cd $(GO_DIR) && \
	GOMAXPROCS=$(GOMAXPROCS) \
	go test \
	-race \
	-cpu=2,4,8 \
	-count=10 \
	-run=^$$ \
	-bench=Benchmark \
	./$(VERSION)/ \
	| tee $(VERSION)/race.txt

# ---------------------------------------------------------

macro-go:
	@echo "Running Go macrobenchmark ($(VERSION))..."
	cd $(GO_DIR) && \
	GOMAXPROCS=$(GOMAXPROCS) \
	go test \
	-timeout=0 \
	-v \
	-tags saturation \
	-run=^TestMacroBenchmarkSaturation$$ \
	./$(VERSION)/ \
	-args \
	-threads=$(THREADS) \
	-execs=$(EXECS)

# ---------------------------------------------------------

progression-go:
	@echo "Running Go progression benchmark ($(VERSION))..."

	@echo "threads,total_time_sec,throughput_exec_per_sec,avg_latency_ms" \
		> $(GO_DIR)/$(VERSION)/progression.csv

	@for t in $$(seq 1 $(MAX_THREADS)); do \
		echo "======================================"; \
		echo "USERS/THREADS=$$t"; \
		(cd $(GO_DIR) && \
		GOMAXPROCS=$(GOMAXPROCS) \
		go test \
			-timeout=0 \
			-v \
			-tags saturation \
			-run=^TestMacroBenchmarkSaturation$$ \
			./$(VERSION)/ \
			-args \
			-threads=$$t \
			-execs=$$t) \
		| grep CSV_RESULT | cut -d',' -f2- \
		>> $(GO_DIR)/$(VERSION)/progression.csv; \
		sleep 2; \
	done

# ---------------------------------------------------------

profile-go:
	@echo "Generating Go profiles ($(VERSION))..."

	mkdir -p $(GO_DIR)/$(VERSION)/profile

	cd $(GO_DIR) && \
	GOMAXPROCS=$(GOMAXPROCS) \
	go test \
		-run=^$$ \
		-bench=BenchmarkFullPipeline \
		-benchtime=1x \
		-cpuprofile=$(VERSION)/profile/cpu.prof \
		-memprofile=$(VERSION)/profile/heap.prof \
		-trace=$(VERSION)/profile/trace.out \
		./$(VERSION)/

# ---------------------------------------------------------

profile-open: clean-profile profile-go
	@echo "Opening CPU profile..."
	@nohup go tool pprof \
		-http=:8080 \
		go/$(VERSION)/profile/cpu.prof \
		> /dev/null 2>&1 &

	@echo "Opening Heap profile..."
	@nohup go tool pprof \
		-http=:8081 \
		go/$(VERSION)/profile/heap.prof \
		> /dev/null 2>&1 &

	@echo "Opening Trace..."
	@nohup env GODEBUG=ipv6=0 \
		go tool trace \
		-http=127.0.0.1:8082 \
		go/$(VERSION)/profile/trace.out \
		> /dev/null 2>&1 &

# =========================================================
# JAVA
# =========================================================

run-java:
	@echo "Running Java $(VERSION)..."
	cd $(JAVA_DIR) && \
	mvn compile exec:java \
	-pl $(VERSION) \
	-Dexec.jvmArgs="$(JAVA_GC_FLAGS)"

# ---------------------------------------------------------

micro-java:
	@echo "Running Java microbenchmarks ($(VERSION))..."
	cd $(JAVA_DIR) && \
	mvn clean package -pl $(VERSION) -Pjmh && \
	java $(JAVA_GC_FLAGS) \
	-jar $(VERSION)/target/benchmarks.jar \
	| tee $(VERSION)/microbenchmark.txt

# ---------------------------------------------------------

define run_jmeter
	cd $(JAVA_DIR) && \
	mvn clean package -pl $(VERSION) -P app-exec

	mkdir -p /opt/apache-jmeter-5.6.3/lib/ext

	cp $(JAVA_DIR)/$(VERSION)/target/*.jar \
		/opt/apache-jmeter-5.6.3/lib/ext/

	rm -f $(JAVA_DIR)/$(VERSION)/results.jtl

	/opt/apache-jmeter-5.6.3/bin/jmeter.sh \
		-Djava.awt.headless=true \
		-n \
		-t kmeans_test.jmx \
		-Jusuarios=$(THREADS) \
		-JjvmArgs="$(JAVA_GC_FLAGS)" \
		-l $(JAVA_DIR)/$(VERSION)/results.jtl
endef

# ---------------------------------------------------------

macro-java:
	@echo "Running Java macrobenchmark ($(VERSION))..."
	$(call run_jmeter)

# ---------------------------------------------------------

progression-java:
	@echo "Running Java progression benchmark ($(VERSION))..."

	@echo "threads,time_ms" \
		> $(JAVA_DIR)/$(VERSION)/progression.csv

	@for t in $$(seq 1 $(MAX_THREADS)); do \
		echo "======================================"; \
		echo "THREADS=$$t"; \
		START=$$(date +%s%3N); \
		$(MAKE) macro-java VERSION=$(VERSION) THREADS=$$t; \
		END=$$(date +%s%3N); \
		ELAPSED=$$((END - START)); \
		echo "$$t,$$ELAPSED" \
			>> $(JAVA_DIR)/$(VERSION)/progression.csv; \
		sleep 2; \
	done

# =========================================================
# GLOBAL - GO
# =========================================================

benchmark-all-go:
	@for v in $(GO_VERSIONS); do \
		echo "======================================"; \
		echo "GO MICRO $$v"; \
		$(MAKE) micro-go VERSION=$$v; \
		sleep 5; \
	done

# ---------------------------------------------------------

macro-all-go:
	@for v in $(GO_VERSIONS); do \
		echo "======================================"; \
		echo "GO MACRO $$v"; \
		$(MAKE) macro-go VERSION=$$v THREADS=$(THREADS) EXECS=$(EXECS); \
		sleep 10; \
	done

# ---------------------------------------------------------

progression-all-go:
	@for v in $(GO_VERSIONS); do \
		echo "======================================"; \
		echo "GO PROGRESSION $$v"; \
		$(MAKE) progression-go VERSION=$$v MAX_THREADS=$(MAX_THREADS) EXECS=$(EXECS); \
		sleep 10; \
	done

# =========================================================
# GLOBAL - JAVA
# =========================================================

benchmark-all-java:
	@for v in $(JAVA_VERSIONS); do \
		echo "======================================"; \
		echo "JAVA MICRO $$v"; \
		$(MAKE) micro-java VERSION=$$v; \
		sleep 5; \
	done

# ---------------------------------------------------------

macro-all-java:
	@for v in $(JAVA_VERSIONS); do \
		echo "======================================"; \
		echo "JAVA MACRO $$v"; \
		$(MAKE) macro-java VERSION=$$v THREADS=$(THREADS); \
		sleep 10; \
	done

# ---------------------------------------------------------

progression-all-java:
	@for v in $(JAVA_VERSIONS); do \
		echo "======================================"; \
		echo "JAVA PROGRESSION $$v"; \
		$(MAKE) progression-java VERSION=$$v MAX_THREADS=$(MAX_THREADS); \
		sleep 10; \
	done
