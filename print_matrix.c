#include <stdio.h>
#include <stdlib.h>
#include <time.h>

static inline void _print_hex(FILE *fp, int x, int bwidth) {
    int n = (bwidth + 3) >> 2;
    int v;
    for (int i = n - 1; i >= 0; i--) {
        v = (x >> (i << 2)) & 0xf;
        if (v == 0) fprintf(fp, "0");
        else fprintf(fp, "%x", v);
    }
}

int main(void) {

    srand(time(NULL));

    int M = 128;
    int K = 128;
    int N = 128;

    // Device configuration under the test
    int num_pe_rows = 32;
    int num_pe_cols = 32;
    int bwidth = 8;
    int maxval = (1 << bwidth) - 1;

    // Matrices
    int **A = (int **)malloc(sizeof(int*)*M);
    for (int i = 0; i < M; i++) A[i] = (int *)malloc(sizeof(int)*K);
    int **A_T = (int **)malloc(sizeof(int*)*K);
    for (int i = 0; i < N; i++) A_T[i] = (int *)malloc(sizeof(int)*M);
    int **B = (int **)malloc(sizeof(int*)*K);
    for (int i = 0; i < K; i++) B[i] = (int *)malloc(sizeof(int)*N);
    int **C = (int **)malloc(sizeof(int*)*M);
    for (int i = 0; i < M; i++) C[i] = (int *)malloc(sizeof(int)*N);

    // generate matrix A (size: M x K)
    int entry;
    for (int r = 0; r < M; r++) {
        for (int c = 0; c < K; c++) {
            entry = rand() % maxval;
            A[r][c] = entry;
            A_T[c][r] = entry;
            entry = rand() % maxval;
        }
    }

    // generate matrix B (size: K x N)
    for (int r = 0; r < K; r++) {
        for (int c = 0; c < N; c++) {
            entry = rand() % maxval;
            B[r][c] = entry;
        }
    }

    // generate matrix C (size: M x N)
    int acc;
    for (int r = 0; r < M; r++) {
        for (int c = 0; c < N; c++) {
            acc = 0;
            for (int k = 0; k < K; k++) {
                acc += A[r][k] * B[k][c];
            }
            C[r][c] = acc;
        }
    }

    // print matrices
    FILE *fp_mat1 = fopen("matrix1.hex", "w");
    FILE *fp_mat2 = fopen("matrix2.hex", "w");
    FILE *fp_ans = fopen("answer.hex", "w");

    // print matrix A
    for (int r = 0; r < M; r++) {
        for (int c = 0; c < K; c++) {
            _print_hex(fp_mat1, A_T[r][c], bwidth);
            if (c % num_pe_rows == num_pe_rows-1) fprintf(fp_mat1, "\n");
        }
    }   fprintf(fp_mat1, "\n");

    // print matrix B
    for (int r = 0; r < K; r++) {
        for (int c = 0; c < N; c++) {
            _print_hex(fp_mat2, B[r][c], bwidth);
            if (c % num_pe_cols == num_pe_cols-1) fprintf(fp_mat2, "\n");
        }
    }   fprintf(fp_mat2, "\n");

    // print the answer
    for (int r = 0; r < M; r++) {
        for (int c = 0; c < N; c++) {
            _print_hex(fp_ans, C[r][c], bwidth<<2);
            if (c % num_pe_cols == num_pe_cols-1) fprintf(fp_ans, "\n");
        }
    }   fprintf(fp_ans, "\n");

    fclose(fp_mat1);
    fclose(fp_mat2);
    fclose(fp_ans);
    
    // free
    free(A);
    free(B);
    free(C);

    return 0;
}