import setuptools

with open("README.md", "r") as fh:
    long_description = fh.read()

setuptools.setup(
    name="git-test",
    version="0.1.0",
    author="Sergey Bronnikov",
    author_email="estetus@gmail.com",
    description="Run automated tests against a range of Git commits and keep track of the results ",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/ligurio/git-test",
    packages=setuptools.find_packages(),
    classifiers=[
        "License :: OSI Approved :: GNU General Public License v2 (GPLv2)",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Topic :: Software Development :: Testing",
        "Topic :: Software Development :: Version Control :: Git",
    ],
    python_requires='>=3.6',
)
