package com.kmeans;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.List;

public class CSVReader {

    private static final int SCALAR_FOR_WORKERS_READ = 1;
    private static final int ONE_MB = 1048576;
    private record Segment(long start, long size) {}
    private static class PaddedResult {
        final List<Point> points = new ArrayList<>();
        long p1, p2, p3, p4, p5, p6, p7, p8; 
    }

    private static List<Segment> getSegments(Path path) throws IOException {
        List<Segment> segments = new ArrayList<>();
        try (RandomAccessFile raf = new RandomAccessFile(path.toFile(), "r")) {
            long totalSize = raf.length();
            int cores = Runtime.getRuntime().availableProcessors() * SCALAR_FOR_WORKERS_READ;
            long targetSize = totalSize / cores;
            if (targetSize < ONE_MB) {
                targetSize = ONE_MB;
            }
            long currentPos = 0; 

            while (currentPos < totalSize) {
                long start = currentPos;
                long endCandidate = currentPos + targetSize;

                if (endCandidate >= totalSize) {
                    segments.add(new Segment(start, totalSize - start));
                    break;
                }

                raf.seek(endCandidate);
                long extraBytes = 0;
                while (true) {
                    int b = raf.read();
                    if (b == -1) {
                        break;
                    }
                    extraBytes++;
                    if (b == '\n') {
                        break;
                    }
                }

                long actualEnd = endCandidate + extraBytes;
                segments.add(new Segment(start, actualEnd - start));
                currentPos = actualEnd;
            }
        }
        return segments;
    }

    public static List<Point> loadPoints(Path path) throws Exception {
        List<Segment> segments = getSegments(path);
        int numSegments = segments.size();
        PaddedResult[] partialResults = new PaddedResult[numSegments];
        Thread[] threads = new Thread[numSegments];

        for (int i = 0; i < numSegments; i++) {
            final int index = i;
            Segment segment = segments.get(i);
            partialResults[index] = new PaddedResult();
        
            threads[i] = Thread.ofVirtual().start(() -> {
                List<Point> pointsPartition = partialResults[index].points;
                try (FileChannel ch = FileChannel.open(path, StandardOpenOption.READ)) {
                    ByteBuffer buffer = ch.map(FileChannel.MapMode.READ_ONLY, segment.start(), segment.size());
                
                    if (segment.start() == 0) {
                        while (buffer.hasRemaining() && buffer.get() != '\n');
                    }
                
                    ByteArrayOutputStream lineBuffer = new ByteArrayOutputStream();
                    while (buffer.hasRemaining()) {
                        byte b = buffer.get();
                        if (b == '\n') {
                            processLine(lineBuffer.toByteArray(), pointsPartition);
                            lineBuffer.reset();
                        } else if (b != '\r') {
                            lineBuffer.write(b);
                        }
                    }
                    if (lineBuffer.size() > 0) {
                        processLine(lineBuffer.toByteArray(), pointsPartition);
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            });
        }

        List<Point> points = new ArrayList<>();
        for (int i = 0; i < threads.length; i++) {
            if (threads[i] == null) continue;
            while (threads[i].isAlive()) {
                Thread.yield();
            }
            if (partialResults[i] != null && partialResults[i].points != null) {
                points.addAll(partialResults[i].points);
            }
        }

        return points;
    }

    private static void processLine(byte[] lineBytes, List<Point> pointsPartition) {
        String currentLine = new String(lineBytes).trim();
        if (currentLine.isEmpty()) {
            return;
        }

        try {
            String[] parts = currentLine.split(",");
            double[] coords = new double[parts.length];
            for (int i = 0; i < parts.length; i++) {
                coords[i] = Double.parseDouble(parts[i].trim());
            }
            pointsPartition.add(new Point(coords)); 
        } catch (NumberFormatException e) {}
    }
}
