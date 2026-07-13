package com.kmeans;
import java.io.Serializable;

public class Point implements Serializable{
    private final float[] position;
    private final int dimension;

    public Point(float[] position) {
        if (position == null || position.length == 0) {
            throw new IllegalArgumentException("Position can't be null or empty.");
        }
        this.position = position.clone();
        this.dimension = position.length;
    }

    public Point(Point other) {
        this.position = other.position.clone();
        this.dimension = other.dimension;
    }

    public float sqDistanceTo(Point other) {
        if (this.dimension != other.getDimension()) {
            throw new IllegalArgumentException("The points must have the same dimension.");
        }
        float sum = 0;
        for (int i = 0; i < dimension; i++) {
            float diff = this.position[i] - other.getOnePosition(i);
            sum += diff * diff;
        }
        return sum;
    }

    public void accumulatedAdd(Point other) {
        if (this.dimension != other.getDimension()) {
            throw new IllegalArgumentException("Dimensions must match for addition.");
        }
        for (int i = 0; i < dimension; i++) {
            this.position[i] += other.getOnePosition(i);
        }
    }

    public void accumulatedDivide(float scalar) {
        if (scalar == 0) {
            throw new ArithmeticException("Division by zero.");
        }
        for (int i = 0; i < dimension; i++) {
            this.position[i] /= scalar;
        }
    }

    public float getOnePosition(int i) {
        if (i < 0 || i >= this.dimension) {
            throw new IllegalArgumentException("Index out of bounds.");
        }
        return position[i];
    }

    public float[] getCoordinates() {
        return position;
    }

    public int getDimension() {
        return dimension;
    }

    @Override
    public String toString() {
        return java.util.Arrays.toString(this.position);
    }
}
