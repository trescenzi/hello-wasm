(module
  (import "console" "logNumber" (func $logNumber (param i32)))
  (import "console" "logString" (func $logString (param i32)))
  (import "js" "logMemory" (memory 1))
  (func $add (param $x i32) (param $y i32) (result i32)
        local.get $x
        local.get $y
        i32.add)
  (func $addAndLog (param $x i32) (param $y i32)
        local.get $x
        local.get $y
        call $add
        call $logNumber)
  (func $fib (param $length i32)
        i32.const 1
        call $logNumber
        i32.const 1
        call $logNumber
        i32.const 1
        i32.const 1
        local.get $length
        call $recursiveFib)
  (func $recursiveFib (param $a i32) (param $b i32) (param $length i32) (local $result i32)
        local.get $a
        local.get $b
        i32.add
        local.set $result
        local.get $result
        call $logNumber
        (if (i32.ne (local.get $length) (i32.const 0))
          (then
            local.get $b
            local.get $result
            local.get $length
            i32.const 1
            i32.sub
            call $recursiveFib)))
  (data (i32.const 0) "hello WASM\00")
  (func $helloWASM
        i32.const 0
        call $logString)
  (export "add" (func $add))
  (export "addAndLog" (func $addAndLog))
  (export "fib" (func $fib))
  (export "helloWasm" (func $helloWASM)))
