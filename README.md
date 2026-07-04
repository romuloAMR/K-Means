# K-Means
Implementation and optimisation of the K-Means algorithm in Java and Go language.

## Version legend:
- **V1:** Full serial version of the algorithm (base)
- **V2:** Addition of Platform Threads, CSV segmentation for reading, and optimisation of data structures
- **V3:** Switching from Platform Threads to Virtual Threads
- **V4:** Switching from a virtual thread to a hybrid thread model
- **V5:** Use of *volatile*
- **V6:** Use of *mutex*
- **V7:** Use of *atomics*
- **V8:** Use of *Java Parallel GC*
- **V9:** Use of *Java ZGC*
- **v10:** Use of *Communication between threads*
- **v11:** Use of *Executors*

> [!NOTE]
> From version 1 to version 5, the code was designed in a Java-like format; Go simply replicated this, which may result in lower-than-expected performance

> [!NOTE]
> Go has no equivalent in the following versions: V5, V8, V9.

## Table Versions:

| Status             | Name                                             | Code               | Microbenchmark     | Macrobenchmark     | Heisenbugs Test    | Profile            |
| :---:              | :---                                             | :---:              | :---:              | :---:              | :---:              | :---:              |
| :construction:     | [Java v1](./java/v1/src/main/java/com/kmeans/)   | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| :construction:     | [Java v2](./java/v2/src/main/java/com/kmeans/)   | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| :construction:     | [Java v3](./java/v3/src/main/java/com/kmeans/)   | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| :construction:     | [Java v4](./java/v4/src/main/java/com/kmeans/)   | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| :construction:     | [Java v5](./java/v5/src/main/java/com/kmeans/)   | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| :construction:     | [Java v6](./java/v6/src/main/java/com/kmeans/)   | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| :construction:     | [Java v7](./java/v7/src/main/java/com/kmeans/)   | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| :construction:     | [Java v8](./java/v8/src/main/java/com/kmeans/)   | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| :construction:     | [Java v9](./java/v9/src/main/java/com/kmeans/)   | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| :construction:     | [Java v10](./java/v10/src/main/java/com/kmeans/) | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| :construction:     | [Java v11](./java/v11/src/main/java/com/kmeans/) | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| :construction:     | [Go v1](./go/v1/)                                | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| :construction:     | [Go v2](./go/v2/)                                | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| :construction:     | [Go v3](./go/v3/)                                | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| :construction:     | [Go v4](./go/v4/)                                | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| :construction:     | [Go v6](./go/v6/)                                | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| :construction:     | [Go v7](./go/v7/)                                | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| :construction:     | [Go v10](./go/v10/)                              | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |

## Prerequisites to Run:

> [!NOTE]
> You need to have Docker installed and set up DevContainer in your code editor (e.g. VS Code)

1- Clone the repository
```sh
git clone https://github.com/romuloAMR/K-Means.git
```
2- Go to the directory
```sh
cd K-Means
```
3- Reopen in Devcontainer


## Runs:
To run the programs, simply use `make` or `make help` to view the options and select the one you want like:
```sh
make run-java-v2
```
