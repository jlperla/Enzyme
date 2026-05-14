; RUN: if [ %llvmver -lt 16 ]; then %opt < %s %loadEnzyme -enzyme -S -enzyme-detect-readthrow=0 | FileCheck %s; fi
; RUN: %opt < %s %newLoadEnzyme -passes="enzyme" -enzyme-preopt=false -enzyme-detect-readthrow=0 -S | FileCheck %s

target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare dso_local void @__enzyme_fwddiff(...)

declare void @dgetrf_64_(i64*, i64*, double*, i64*, i64*, i64*)

define void @f(double* %A, i64* %ipiv) {
entry:
  %m = alloca i64, align 8
  %n = alloca i64, align 8
  %lda = alloca i64, align 8
  %info = alloca i64, align 8
  store i64 4, i64* %m, align 8
  store i64 4, i64* %n, align 8
  store i64 4, i64* %lda, align 8
  call void @dgetrf_64_(i64* %m, i64* %n, double* %A, i64* %lda, i64* %ipiv, i64* %info)
  ret void
}

define void @active(double* %A, double* %dA, i64* %ipiv) {
entry:
  call void (...) @__enzyme_fwddiff(void (double*, i64*)* @f, metadata !"enzyme_dup", double* %A, double* %dA, metadata !"enzyme_const", i64* %ipiv)
  ret void
}

; CHECK-LABEL: define internal void @fwddiffef
; CHECK: call void @llvm.trap
; CHECK: call void @dgetrf_64_
; CHECK: call void @dlacpy_64_
; CHECK: call void @dlaswp_64_
; CHECK: call void @dtrsm_64_
; CHECK: call void @dtrsm_64_
; CHECK: call void @dlacpy_64_
; CHECK: call void @dlascl_64_
; CHECK: call void @dtrmm_64_
; CHECK: call void @dlacpy_64_
; CHECK: call void @dlacpy_64_
; CHECK: call void @dtrmm_64_
; CHECK: call void @dlacpy_64_
; CHECK: ret void
