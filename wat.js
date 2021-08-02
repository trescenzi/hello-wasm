const memory = new WebAssembly.Memory({initial:1});

const importObject = {
  console: {
    logNumber: function(arg) {
      console.log(arg);
    },
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
    wasmObj = obj.instance.exports;
    window.wasmObj = wasmObj;
});
