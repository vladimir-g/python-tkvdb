import os
from setuptools import setup, Extension


try:
    from Cython.Build import cythonize
except ImportError:
    cythonize = None

USE_CYTHON = bool(int(os.getenv("USE_CYTHON", 0))) and cythonize is not None

MODULES = (
    {'mod': 'tkvdb.errors', 'files': ["errors"]},
    {'mod': 'tkvdb.params', 'files': ["params"]},
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


readme = os.path.join(os.path.dirname(__file__), 'README.md')
with open(readme, 'r', encoding='utf-8') as f:
    long_description = f.read()

setup(
    name='python-tkvdb',
    version='0.2.2',
    author='Vladimir Gorbunov',
    author_email='vsg@suburban.me',
    url='https://github.com/vladimir-g/python-tkvdb/',
    description='Cython wrapper for tkvdb radix trie key-value database',
    long_description=long_description,
    long_description_content_type="text/markdown",
    license='ISC',
    packages=['tkvdb'],
    package_dir={'': 'src'},
    ext_modules=get_modules(),
    zip_safe=False,
    package_data = {
        'tkvdb': ['*.pxd']
    },
    python_requires=">=3.5",
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Topic :: Database',
        'Topic :: Database :: Database Engines/Servers',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: ISC License (ISCL)',
        'Operating System :: OS Independent',
        'Programming Language :: C',
        'Programming Language :: Cython',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
    ]
)
