# Olmeca Script - новый ЯП

## lab 1
### Отчет находится в папке lab1

Запуск:

```sh
$ cd lab1/
$ flex tokens.l
$ cc lex.yy.c
$ ./a.out
```
Далее неободимо указать путь к  файлу

Файлы для тестов находятся в папке tests/

##
## lab 2
### Отчет находится в папке lab2

Запуск:

```sh
$ cd lab2/
$ make; make clean
$ ./olmeca "путь до тестируемого файла без кавычек"
```
Пример:
```sh
$ ./olmeca tests/prog.olm
```
Файлы для тестов находятся в папке tests/
