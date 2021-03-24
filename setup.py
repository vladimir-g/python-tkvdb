import os
from setuptools import setup, find_packages, Extension


try:
    from Cython.Build import cythonize
except ImportError:
    cythonize = None

USE_CYTHON = bool(int(os.getenv("USE_CYTHON", 0))) and cythonize is not None

MODULES = (
    {'mod': 'tkvdb.errors', 'files': ["errors"]},
    {'mod': 'tkvdb.cursor', 'files': ["cursor"]},
    {'mod': 'tkvdb.iterators', 'files': ["iterators"]},
    {'mod': 'tkvdb.transaction', 'files': ["transaction"]},
    {'mod': 'tkvdb.db', 'files': ["db"]}
)


def get_modules():
    extensions = []
    ext = '.pyx' if USE_CYTHON else '.c'
    for module in MODULES:
        files = ['src/tkvdb/' + f + ext for f in module['files']]
        extensions.append(
            Extension(module['mod'], files + ['tkvdb/tkvdb.c'],
                      include_dirs=['tkvdb/']),
        )
    if USE_CYTHON:
        return cythonize(extensions,
                         include_path=['src/tkvdb'],
                         language_level = "3")
    return extensions


setup(
    name='python-tkvdb',
    version='0.1.0',
    author='Vladimir Gorbunov',
    author_email='vsg@suburban.me',
    license='ISC',
    packages=find_packages('src'),
    package_dir={'': 'src'},
    ext_modules=get_modules()    
)
