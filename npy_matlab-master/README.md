# npy_matlab

Code to read and write NumPy's NPY format (`.npy` files) in MATLAB.

This is experimental code and still work in progress. For example, this code:
- Only reads a subset of all possible NPY files, specifically N-D arrays of
  certain data types.
- Only writes little endian, fortran (column-major) ordering
- Only writes with NPY version number 1.0.
- Always outputs a shape according to matlab's convention, e.g. (10, 1)
  rather than (10,).

Feel free to open an issue and/or send a pull request for improving the
state of this project!

For the complete specification of the NPY format, see the [NumPy documentation](https://www.numpy.org/devdocs/reference/generated/numpy.lib.format.html).

## Installation

After downloading npy_matlab as a zip file or via git, just add the
npy_matlab directory to your MATLAB path:

## Usage example

```matlab
>> import npy_matlab.*
>> a = rand(5,4,3);
>> writeNPY(a, 'a.npy');
>> b = readNPY('a.npy');
>> sum(a(:)==b(:))
ans =

    60
```

## Tests

- Run tests in MATLAB: see `tests/test_readNPY.m` 
- Run tests in Python: see `tests/npy.ipynb` & `tests\test_npy_roundtrip.py`

## Memory mapping npy files

See `examples/exampleMemmap.m` for an example of how to memory map a `.npy` file in MATLAB, which is not trivial when the file uses C-ordering (i.e., row-major order) rather than Fortran-ordering (i.e., column-major ordering). MATLAB's memory mapping only supports Fortran-ordering, but Python's default is C-ordering so `.npy` files created with Python defaults are not straightforward to read in MATLAB.
