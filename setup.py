from setuptools import setup, find_packages


setup(
    name='python-tkvdb',
    version='0.1.0',
    author='Vladimir Gorbunov',
    author_email='vsg@suburban.me',
    license='ISC',
    packages=find_packages('src'),
    package_dir={'': 'src'}
)
