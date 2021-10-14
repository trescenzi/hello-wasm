# Hello WASM

This simple repository is an introduction to WASM at a low level through the
WAT(web assembly text) format. The WAT format expresses programs as a stack
machine via [S-expressions](https://en.wikipedia.org/wiki/S-expression). If you
know a lisp it'll look familiar to you, if not it might look a bit strange. The
most basic way to look at it is top down. Most expressions place information
onto the stack, function calls pop their number of arguments off of the stack.
If you're on a unix based machine the command `dc` is a good example of how this
works with math: `echo "2 2 + p" | dc`. This says:

- Push 2
- Push 2
- "execute" + (pops the top two and adds them)
- print the stack

The final result is `4` printed to the command line.

## Add in WAT

To get started let's look at what a simple add function would look like:

### Web Assembly 

```WAT
(module
  (func $add (param $x i32) (param $y i32) (result i32)
        local.get $x
        local.get $y
        i32.add)
  (export "add" (func $add)))
```

All WASM is grouped into modules, and modules have exports which are exposed to
the Javascript runtime when the module is executed. Functions are defined with
the `func` keyword and have `param`s, `local`s(more on that later), and
`result`(if the function has a return value aka there's something left on the
stack after they are done executing).

Breaking this function down we have:
`func $add (param $x i32) (param $y i32) (result i32)`

This defines a function named `add` with two 32 bit integer parameters, `x` and
`y`, as well as declaring that it returns a 32 bit integer.

Its body starts by pushing both of its parameters onto the stack:
```WAT
  local.get $x
  local.get $y
```

It then uses `i32.add` to pop the top two stack values and replace them with
their sum. This sum is the result of the function.

Finally we export `$add` to Javascript as `add`.

### JavaScript 

The related Javascript looks like:

```JavaScript
WebAssembly.instantiateStreaming(fetch('/add.wasm'))
  .then(obj => {
    console.log(obj.instance.exports.add(2,2));
});
```

## Logging in WASM

Once we can call WASM function from Javascript we might want to call Javascript functions from within WASM.

### Web Assembly 

```WAT
(module
  (import "console" "logNumber" (func $logNumber (param i32)))
  (func $addAndLog (param $x i32) (param $y i32)
        local.get $x
        local.get $y
        call $add
        call $logNumber)
  (export "addAndLog" (func $addAndLog)))
```

In order to do this we need to `import` just as we might in a Javascript module.

`(import "console" "logNumber" (func $logNumber (param i32)))`

`import` statements describe an object path where they will find their import.
In this statement `"console" "logNumber"` will correspond to a Javascript object
that looks like `{console: {logNumber: function}}`. Finally the statement
describes a function definition which is named `$logNumber` and takes a single
32 bit integer parameter and doesn't have a return value.

Now that we've imported a function we can use it:
```WAT
(func $addAndLog (param $x i32) (param $y i32)
      local.get $x
      local.get $y
      i32.add
      call $logNumber)
```

This function is almost identical to `$add` however it doesn't have a `result`
and it calls `$logNumber`. Again we push both `$x` and `$y` onto the stack, add
them, then we call our exported function with that result.

### JavaScript

```JavaScript
const importObject = {
  console: {
    logNumber: function(arg) {
      console.log(arg);
    },
  }
};

WebAssembly.instantiateStreaming(fetch('/addAndLog.wasm'), importObject)
  .then(obj => {
    obj.instance.exports.addAndLog(2,2);
});
```

Here we see that we have to pass in the `importObject` that corresponds to what
we defined in `WAT`. Aside from that the only other difference is we don't have
to call `console.log` with our result because we're already doing that in WASM.

## Fibonacci in WASM

Now that we can add numbers and log their results we can implement a
Fibonacci sequence calculator that prints it in order.

### Web Assembly

```WAT
(module
  (import "console" "logNumber" (func $logNumber (param i32)))
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
  (export "fib" (func $fib)))
```

We create two separate function here. One which we export which allows users to
specify how many numbers they'd like to have printed, and a second which we call
recursively to calculate the Fibonacci numbers.

```WAT
  (func $fib (param $length i32)
        i32.const 1
        i32.const 1
        local.get $length
        call $recursiveFib)
```

This first function takes a single 32 bit integer which specifies how many
numbers in the flow to calculate. It prints the first two digits, `1 1` and then
sets up the recursive call by pushing the parameters for it onto the stack.

The second function introduces a few new concepts. The first is `local`. This
defines a variable accessible within the function for storing a certain type.
You define it with `(local $result i32)` and use it with `local.set` or
`local.get`.

```WAT
  local.get $a
  local.get $b
  i32.add
  local.set $result
  local.get $result
  call $logNumber
```

The first half of the function begins by adding the two numbers in the sequence
together then storing it in `$result`. At this point the stack is now empty, so
we have to grab that value before printing it.

```
  (if (i32.ne (local.get $length) (i32.const 0))
    (then
      local.get $b
      local.get $result
      local.get $length
      i32.const 1
      i32.sub
      call $recursiveFib)))
```

The second half of the function determines the base case of the function. We use
`if` and `i32.ne`(not equal) to determine if we've gotten to the end of our
list. If we haven't we push `$b` and `$result` onto the stack to be the first
two parameters of this function and then push `$length` and subtract `1` from
it. Finally we recursively call the function.

### JavaScript

```JavaScript
const importObject = {
  console: {
    logNumber: function(arg) {
      console.log(arg);
    },
  }
};

WebAssembly.instantiateStreaming(fetch('/fib.wasm'), importObject)
  .then(obj => {
    obj.instance.exports.fib(5);
});
```

The JavaScript portion is basically the same as we've seen before. Instead of
adding though we're calling the `fib` function.

## Strings

At this point we've touched on most of the capabilities of the WAT stack machine
but we still have yet to print `Hello World`. This is where begin to see even
more clearly why WASM is more of a compile target than a language you might want
to write whole programs in. At the most basic level WASM only has
numeric types: `i32`, `i64`, `f32`, and `f64`. Additionally there are also tables (indexable "arrays" of function pointers), 
memories(expandable byte arrays), and value types(can be a reference or a number) however we won't be going into
those in this example.

Because there is no string primitive, strings are simply contiguous groups of
memory with characters being encoded in utf8. In order to store those groups
however we must allocate it in JavaScript and provide that allocated memory to
the WASM runtime.

### Web Assembly

```WAT
(module
  (import "console" "logString" (func $logString (param i32)))
  (import "js" "logMemory" (memory 1))
  (data (i32.const 0) "hello WASM\00")
  (func $helloWASM
        i32.const 0
        call $logString)
  (export "helloWasm" (func $helloWASM)))
```

The WAT here is actually rather simple compared to the Fibonacci computation.
There are two new concepts though. First we import memory instead of a function: `(import "js" "logMemory" (memory 1))`. This memory is defined as 1 page(64KB).
We then use the `data` keyword to store a string there(technically it gets
compiled by `wat2wasm` into utf8 bytes) starting at position 0 in our memory and
ending with a null.

### JavaScript

The JavaScript portion of the string usage is where it gets a bit more complex.

```JavaScript
const memory = new WebAssembly.Memory({initial:1});

const importObject = {
  console: {
    logString: function(offset) {
      const bytes = new Uint8Array(memory.buffer, offset);
      const bytesWithString = bytes.slice(0, bytes.findIndex(x => x === 0));
      const string = new TextDecoder('utf8').decode(bytesWithString);
      console.log(string);
    }
  },
  js: {
    logMemory: memory,
  }
};

let wasmObj = {};
WebAssembly.instantiateStreaming(fetch('/hello.wasm'), importObject)
  .then(obj => {
    obj.instance.exports.helloWasm();
});
```

First we must instantiate a page of memory with `WebAssembly.Memory`. We then
pass this information into the WASM Runtime along with our `logString` function
which is where most of the interesting work happens.

```JavaScript
logString: function(offset) {
  const bytes = new Uint8Array(memory.buffer, offset);
  const bytesWithString = bytes.slice(0, bytes.findIndex(x => x === 0));
  const string = new TextDecoder('utf8').decode(bytesWithString);
  console.log(string);
}
```

We start by creating a `Uint8Array` out of the memory we passed into the WASM
Runtime. The array begins at the offset. While we could specify an end, since we
null terminated the array we instead use `slice` and `findIndex` to cut the
array down to just the size of the string that was placed into memory by WASM.
Finally we use `TextDecoder` to decode that array into a string before logging
it.

## Moving forward

The string implementation starts to really show why WASM is a compilation target and
not just a language people might write. There's a lot of overhead to just write
a constant string and when you start passing strings back and forth it gets way
more complicated.

### Implementations in different languages

- [Rust](https://rustwasm.github.io/book/)
- [C#/Blazor](https://dotnet.microsoft.com/apps/aspnet/web-apps/blazor)
- [C++](https://developer.mozilla.org/en-US/docs/WebAssembly/C_to_wasm)
