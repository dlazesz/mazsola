# Mazsola
This is the *Verb Argument Browser* or *Mazsola*
(meaning *raisin* in Hungarian),
a tool for investigating argument structure of verbs.

Check out the original Hungarian version @ http://corpus.nytud.hu/vab
which is accessible together with the Hungarian National Corpus.

Author: [Bálint Sass](http://www.nytud.hu/depts/corpus/Sass_Balint.html)

## Docker vesion

This is a simplified version to be able to easily deploy the original Mazsola based on HNC.

1. cd deploy
2. Put mazsola_adatbazis.txt compressed with gzip to data/hnc.mazsoladb.gz
3. docker build -t mazsola .
4. docker run -it --name mazsola_container --rm -p 8080:8080 mazsola
5. Go to: http://localhost:8080 use mazsola/mazsola to login

Available at https://hub.docker.com/r/dlazesz/mazsola or docker pull dlazesz/mazsola

Bonus debug server in perl: perl cgi-server.pl

## Requirements

- linux
- perl

## Installation

1. Set variables appropriately in `Makefile`.
2. `make deploy-no-db` to deploy the tool itself.
3. `make deploy-db` to deploy the sample corpora shipped with the tool.
4. That's it. :)

## Usage for your data

1. Put your data into `data` directory.
2. Edit config appropriately.
3. Do the steps listed at Installation.

