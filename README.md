# metal-api-pass-memory-buffer-array-as-an-argument
Metal API pass memory buffer array as an argument

<br />

Metal API中将memory buffer对象数组作为kernel的一个参数进行传递。

与OpenCL不同，由于Metal Shading Language不支持uintptr_t类型的数组作为kernel参数，因此我们这里只能蛋疼地将每一个缓存地址翻译为高32位与低32位两部分。然后在使用时，再把这两者拼接上。

