GO_DIR        := go
JAVA_DIR      := java
DATA_DIR      := data
GO_VERSIONS   := v1 v2 v3 v4 v6 v7 v10 v12 v17
JAVA_VERSIONS := v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 v13 v14 v15 v16 v17 v18
VERSION       ?= v1
THREADS       ?= 4
EXECS         ?= 20
MAX_THREADS   ?= 10
GOMAXPROCS    ?= $(shell nproc)

DEFAULT_JAVA_HOME := /usr/lib/jvm/java-25-latest
JAVA_HOME_v18 := /usr/lib/jvm/java-17-latest
CURRENT_JAVA_HOME = $(if $(JAVA_HOME_$(VERSION)),$(JAVA_HOME_$(VERSION)),$(DEFAULT_JAVA_HOME))

BENCH_FLAGS_GO := \
	-run=^$$ \
	-bench=Benchmark \
	-benchmem \
	-count=7

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
JAVA_GC_FLAGS_v11 :=
JAVA_GC_FLAGS_v12 :=
JAVA_GC_FLAGS_v13 :=
JAVA_GC_FLAGS_v14 :=
JAVA_GC_FLAGS_v15 :=
JAVA_GC_FLAGS_v16 :=
JAVA_GC_FLAGS_v17 := --enable-preview
JAVA_GC_FLAGS_v18 := --add-opens=java.base/java.lang=ALL-UNNAMED \
    --add-opens=java.base/java.lang.invoke=ALL-UNNAMED \
    --add-opens=java.base/java.lang.reflect=ALL-UNNAMED \
    --add-opens=java.base/java.io=ALL-UNNAMED \
    --add-opens=java.base/java.net=ALL-UNNAMED \
    --add-opens=java.base/java.nio=ALL-UNNAMED \
    --add-opens=java.base/java.util=ALL-UNNAMED \
    --add-opens=java.base/java.util.concurrent=ALL-UNNAMED \
    --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED \
    --add-opens=java.base/sun.nio.ch=ALL-UNNAMED \
    --add-opens=java.base/sun.nio.cs=ALL-UNNAMED \
    --add-opens=java.base/sun.security.action=ALL-UNNAMED \
    --add-opens=java.base/sun.util.calendar=ALL-UNNAMED \
    --add-opens=java.security.jgss/sun.security.krb5=ALL-UNNAMED

JAVA_GC_FLAGS := $(JAVA_GC_FLAGS_$(VERSION))

.PHONY: all help \
	create-data \
	clean-profile \
	run-go micro-go macro-go progression-go race-go profile-go profile-open macro-all-go \
	run-java micro-java macro-java progression-java macro-all-java \
	benchmark-all-go benchmark-all-java \
	progression-all-go progression-all-java

all: help

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
	@echo "make macro-java VERSION=v1 THREADS=8 EXECS=32"
	@echo "make progression-java VERSION=v1 MAX_THREADS=16"
	@echo "make race-java VERSION=v1"
	@echo "make profile-java VERSION=v1"
	@echo ""
	@echo "================== GLOBAL =================="
	@echo "make benchmark-all-go"
	@echo "make benchmark-all-java"
	@echo "make macro-all-go"
	@echo "make macro-all-java"
	@echo "make progression-all-go"
	@echo "make progression-all-java"
	@echo ""

# Python
create-data:
	@echo "Creating datasets..."
	cd $(DATA_DIR) && python3 main.py

# Clean
clean-profile:
	-@pkill -f "go tool pprof"
	-@pkill -f "go tool trace"

# GO
run-go:
	@echo "Running Go $(VERSION)..."
	cd $(GO_DIR) && \
	GOMAXPROCS=$(GOMAXPROCS) \
	go run ./$(VERSION)/

micro-go:
	@echo "Running Go microbenchmarks ($(VERSION))..."
	cd $(GO_DIR) && \
	GOMAXPROCS=$(GOMAXPROCS) \
	go test $(BENCH_FLAGS_GO) ./$(VERSION)/ \
	| tee $(VERSION)/microbenchmark.txt

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

# JAVA
run-java:
	@echo "Running Java $(VERSION)..."
	cd $(JAVA_DIR) && \
	export JAVA_HOME=$(CURRENT_JAVA_HOME) && \
	MAVEN_OPTS="$(JAVA_GC_FLAGS)" \
	mvn compile exec:java \
	-pl $(VERSION)

micro-java:
	@echo "Running Java microbenchmarks ($(VERSION))..."
	cd $(JAVA_DIR) && \
	export JAVA_HOME=$(CURRENT_JAVA_HOME) && \
	mvn clean package -pl $(VERSION) -Pjmh && \
	$(CURRENT_JAVA_HOME)/bin/java $(JAVA_GC_FLAGS) \
	-jar $(VERSION)/target/benchmarks.jar \
	| tee $(VERSION)/microbenchmark.txt

race-java:
	@echo "Concurrency Test Java $(VERSION)..."
	cd $(JAVA_DIR) && \
	export JAVA_HOME=$(CURRENT_JAVA_HOME) && \
	mvn clean package -pl $(VERSION) -Pjcstress && \
	$(CURRENT_JAVA_HOME)/bin/java $(JAVA_GC_FLAGS) -jar $(VERSION)/target/jcstress-tests.jar -m quick \
	| tee $(VERSION)/race.txt && \
	find $(JAVA_DIR) -name "*.bin.gz" -delete

define run_jmeter
	cd $(JAVA_DIR) && \
	export JAVA_HOME=$(CURRENT_JAVA_HOME) && \
	mvn clean package -pl $(VERSION) -P app-exec && \
	mkdir -p $(VERSION) && \
	mkdir -p /opt/apache-jmeter-5.6.3/lib/ext && \
	rm -f /opt/apache-jmeter-5.6.3/lib/ext/v*.jar && \
	cp $(VERSION)/target/*.jar /opt/apache-jmeter-5.6.3/lib/ext/ && \
	echo 'export JAVA_HOME="$(CURRENT_JAVA_HOME)"' > /opt/apache-jmeter-5.6.3/bin/setenv.sh && \
	echo 'export HEAP="-Xms16g -Xmx16g"' >> /opt/apache-jmeter-5.6.3/bin/setenv.sh && \
	echo 'export GC_ALGO="-XX:+UseG1GC"' >> /opt/apache-jmeter-5.6.3/bin/setenv.sh && \
	echo 'export JVM_ARGS="$(JAVA_GC_FLAGS)"' >> /opt/apache-jmeter-5.6.3/bin/setenv.sh && \
	chmod +x /opt/apache-jmeter-5.6.3/bin/setenv.sh && \
	/opt/apache-jmeter-5.6.3/bin/jmeter.sh \
		-Djava.awt.headless=true \
		-n \
		-t ../kmeans_test.jmx \
		-Jusuarios=$(THREADS) \
		-Jexecs=$(EXECS) \
		-Jjmeter.save.saveservice.output_format=csv \
		-Jjmeter.save.saveservice.print_field_names=true \
		-l $(VERSION)/results.jtl
endef

macro-java:
	@echo "Running Java macrobenchmark ($(VERSION)) com JDK $(CURRENT_JAVA_HOME)..."
	$(call run_jmeter)

progression-java:
	@echo "Running Java progression benchmark ($(VERSION))..."

	@mkdir -p $(JAVA_DIR)/$(VERSION)

	@echo "threads,total_time_sec,throughput_exec_per_sec,avg_latency_ms" \
		> $(JAVA_DIR)/$(VERSION)/progression.csv

	@rm -f $(JAVA_DIR)/$(VERSION)/results.jtl

	@HEADER_WRITTEN=0; \
	for t in $$(seq 1 $(MAX_THREADS)); do \
		echo "======================================"; \
		echo "THREADS=$$t"; \
		$(MAKE) macro-java VERSION=$(VERSION) THREADS=$$t EXECS=$$t; \
		JTL="$(JAVA_DIR)/$(VERSION)/results.jtl"; \
		\
		cp $$JTL /tmp/current_jmeter.jtl; \
		\
		if [ $$HEADER_WRITTEN -eq 0 ]; then \
			cat /tmp/current_jmeter.jtl >> $(JAVA_DIR)/$(VERSION)/all_results.jtl; \
			HEADER_WRITTEN=1; \
		else \
			tail -n +2 /tmp/current_jmeter.jtl >> $(JAVA_DIR)/$(VERSION)/all_results.jtl; \
		fi; \
        \
		AVG=$$(awk -F',' 'NR>1 {sum+=$$2; n++} END {if(n>0) print sum/n; else print 0}' /tmp/current_jmeter.jtl); \
		COUNT=$$(awk -F',' 'NR>1 {n++} END {print n}' /tmp/current_jmeter.jtl); \
		TOTAL_MS=$$(awk -F',' '\
			NR==2 {min=$$1} \
			NR>1 {max=$$1 + $$2} \
			END {print max-min}' /tmp/current_jmeter.jtl); \
		THROUGHPUT=$$(awk "BEGIN {if($$TOTAL_MS>0) print ($$COUNT*1000)/$$TOTAL_MS; else print 0}"); \
		TOTAL_SEC=$$(awk "BEGIN {print $$TOTAL_MS/1000}"); \
		echo "$$t,$$TOTAL_SEC,$$THROUGHPUT,$$AVG" \
			>> $(JAVA_DIR)/$(VERSION)/progression.csv; \
		sleep 2; \
	done

profile-java:
	@echo "Generating Standalone Java profile ($(VERSION))..."
	@mkdir -p $(JAVA_DIR)/$(VERSION)/profile
	cd $(JAVA_DIR) && \
	export JAVA_HOME=$(CURRENT_JAVA_HOME) && \
	MAVEN_OPTS="$(JAVA_GC_FLAGS) -XX:StartFlightRecording=filename=$(VERSION)/profile/profile.jfr,settings=profile,dumponexit=true" \
	mvn compile exec:java \
	-pl $(VERSION)

# GLOBAL - GO
benchmark-all-go:
	@for v in $(GO_VERSIONS); do \
		echo "======================================"; \
		echo "GO MICRO $$v"; \
		$(MAKE) micro-go VERSION=$$v; \
		sleep 5; \
	done

macro-all-go:
	@for v in $(GO_VERSIONS); do \
		echo "======================================"; \
		echo "GO MACRO $$v"; \
		$(MAKE) macro-go VERSION=$$v THREADS=$(THREADS) EXECS=$(EXECS); \
		sleep 10; \
	done

progression-all-go:
	@for v in $(GO_VERSIONS); do \
		echo "======================================"; \
		echo "GO PROGRESSION $$v"; \
		$(MAKE) progression-go VERSION=$$v MAX_THREADS=$(MAX_THREADS) EXECS=$(EXECS); \
		sleep 10; \
	done

# GLOBAL - JAVA
benchmark-all-java:
	@for v in $(JAVA_VERSIONS); do \
		echo "======================================"; \
		echo "JAVA MICRO $$v"; \
		$(MAKE) micro-java VERSION=$$v; \
		sleep 5; \
	done

macro-all-java:
	@for v in $(JAVA_VERSIONS); do \
		echo "======================================"; \
		echo "JAVA MACRO $$v"; \
		$(MAKE) macro-java VERSION=$$v THREADS=$(THREADS) EXECS=$(EXECS); \
		sleep 10; \
	done

progression-all-java:
	@for v in $(JAVA_VERSIONS); do \
		echo "======================================"; \
		echo "JAVA PROGRESSION $$v"; \
		$(MAKE) progression-java VERSION=$$v MAX_THREADS=$(MAX_THREADS); \
		sleep 10; \
	done
